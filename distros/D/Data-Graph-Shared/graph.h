/*
 * graph.h -- Shared-memory directed weighted graph for Linux
 *
 * Nodes allocated from a bitmap pool. Edges stored as adjacency lists
 * in a separate edge pool. Mutex-protected mutations.
 *
 * Node: int64_t data
 * Edge: uint32_t dst, int64_t weight, uint32_t next (linked list)
 */

#ifndef GRAPH_H
#define GRAPH_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <limits.h>
#include <signal.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <linux/futex.h>
#include <sys/eventfd.h>

#define GRAPH_MAGIC       0x47525031U  /* "GRP1" */
#define GRAPH_VERSION     1
#define GRAPH_ERR_BUFLEN  256
#define GRAPH_NONE        UINT32_MAX

#define GRAPH_MUTEX_BIT   0x80000000U
#define GRAPH_MUTEX_PID   0x7FFFFFFFU

/* ================================================================
 * Layout
 *
 * Header (128 bytes)
 * Node data:  max_nodes * sizeof(int64_t)    — node values
 * Node heads: max_nodes * sizeof(uint32_t)   — first-edge index per node
 * Node bitmap: ceil(max_nodes/64) * 8        — allocation bitmap
 * Edges:      max_edges * sizeof(GraphEdge)  — edge pool
 * Edge bitmap: ceil(max_edges/64) * 8        — edge allocation bitmap
 * ================================================================ */

typedef struct {
    uint32_t dst;
    uint32_t next;      /* index of next edge in adjacency list, GRAPH_NONE = end */
    int64_t  weight;
} GraphEdge;

typedef struct {
    uint32_t magic;
    uint32_t version;
    uint32_t max_nodes;
    uint32_t max_edges;
    uint64_t total_size;
    uint64_t node_data_off;
    uint64_t node_heads_off;
    uint64_t node_bitmap_off;
    uint64_t edge_data_off;
    uint64_t edge_bitmap_off;

    uint32_t node_count;       /* 64 */
    uint32_t edge_count;       /* 68 */
    uint32_t mutex;            /* 72 */
    uint32_t mutex_waiters;    /* 76 */
    uint64_t stat_ops;         /* 80 */
    uint8_t  _pad1[40];        /* 88-127 */
} GraphHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(GraphHeader) == 128, "GraphHeader must be 128 bytes");
#endif

typedef struct {
    GraphHeader *hdr;
    int64_t     *node_data;
    uint32_t    *node_heads;
    uint64_t    *node_bitmap;
    GraphEdge   *edges;
    uint64_t    *edge_bitmap;
    uint32_t     node_bwords;
    uint32_t     edge_bwords;
    size_t       mmap_size;
    char        *path;
    int          notify_fd;
    int          backing_fd;
} GraphHandle;

/* ================================================================
 * Mutex (same pattern as Heap)
 * ================================================================ */

static const struct timespec graph_lock_timeout = { 2, 0 };

static inline int graph_pid_alive(uint32_t pid) {
    if (pid == 0) return 1;
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

static inline void graph_mutex_lock(GraphHeader *hdr) {
    uint32_t mypid = GRAPH_MUTEX_BIT | ((uint32_t)getpid() & GRAPH_MUTEX_PID);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->mutex, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (spin < 32) {
#if defined(__x86_64__) || defined(__i386__)
            __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
            __asm__ volatile("yield" ::: "memory");
#endif
            continue;
        }
        __atomic_add_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        uint32_t cur = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->mutex, FUTEX_WAIT, cur,
                              &graph_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT && cur >= GRAPH_MUTEX_BIT) {
                uint32_t pid = cur & GRAPH_MUTEX_PID;
                if (!graph_pid_alive(pid))
                    __atomic_compare_exchange_n(&hdr->mutex, &cur, 0,
                            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
            }
        }
        __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline void graph_mutex_unlock(GraphHeader *hdr) {
    __atomic_store_n(&hdr->mutex, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
}

/* ================================================================
 * Bitmap helpers
 * ================================================================ */

static inline int graph_bit_set(uint64_t *bm, uint32_t idx) {
    uint64_t word = __atomic_load_n(&bm[idx / 64], __ATOMIC_ACQUIRE);
    return (word >> (idx % 64)) & 1;
}

static inline int32_t graph_bit_alloc(uint64_t *bm, uint32_t bwords, uint32_t max) {
    for (uint32_t w = 0; w < bwords; w++) {
        uint64_t word = bm[w];
        if (word == ~(uint64_t)0) continue;
        int bit = __builtin_ctzll(~word);
        uint32_t idx = w * 64 + bit;
        if (idx >= max) return -1;
        bm[w] |= (uint64_t)1 << bit;
        return (int32_t)idx;
    }
    return -1;
}

static inline void graph_bit_free(uint64_t *bm, uint32_t idx) {
    bm[idx / 64] &= ~((uint64_t)1 << (idx % 64));
}

/* ================================================================
 * Graph operations (must hold mutex)
 * ================================================================ */

static inline int32_t graph_add_node_locked(GraphHandle *h, int64_t data) {
    int32_t idx = graph_bit_alloc(h->node_bitmap, h->node_bwords, h->hdr->max_nodes);
    if (idx < 0) return -1;
    h->node_data[idx] = data;
    h->node_heads[idx] = GRAPH_NONE;
    h->hdr->node_count++;
    return idx;
}

static inline int graph_add_edge_locked(GraphHandle *h, uint32_t src, uint32_t dst, int64_t weight) {
    if (src >= h->hdr->max_nodes || dst >= h->hdr->max_nodes) return 0;
    if (!graph_bit_set(h->node_bitmap, src) || !graph_bit_set(h->node_bitmap, dst))
        return 0;
    int32_t eidx = graph_bit_alloc(h->edge_bitmap, h->edge_bwords, h->hdr->max_edges);
    if (eidx < 0) return 0;
    h->edges[eidx].dst = dst;
    h->edges[eidx].weight = weight;
    h->edges[eidx].next = h->node_heads[src];
    h->node_heads[src] = (uint32_t)eidx;
    h->hdr->edge_count++;
    return 1;
}

static inline int graph_remove_node_locked(GraphHandle *h, uint32_t node) {
    if (node >= h->hdr->max_nodes) return 0;
    if (!graph_bit_set(h->node_bitmap, node)) return 0;
    /* free all outgoing edges */
    uint32_t eidx = h->node_heads[node];
    while (eidx != GRAPH_NONE) {
        uint32_t next = h->edges[eidx].next;
        graph_bit_free(h->edge_bitmap, eidx);
        h->hdr->edge_count--;
        eidx = next;
    }
    h->node_heads[node] = GRAPH_NONE;
    graph_bit_free(h->node_bitmap, node);
    h->hdr->node_count--;
    return 1;
}

/* ================================================================
 * Public API (lock + operation + unlock)
 * ================================================================ */

static inline int32_t graph_add_node(GraphHandle *h, int64_t data) {
    graph_mutex_lock(h->hdr);
    int32_t r = graph_add_node_locked(h, data);
    h->hdr->stat_ops++;
    graph_mutex_unlock(h->hdr);
    return r;
}

static inline int graph_add_edge(GraphHandle *h, uint32_t src, uint32_t dst, int64_t weight) {
    graph_mutex_lock(h->hdr);
    int r = graph_add_edge_locked(h, src, dst, weight);
    h->hdr->stat_ops++;
    graph_mutex_unlock(h->hdr);
    return r;
}

static inline int graph_remove_node(GraphHandle *h, uint32_t node) {
    graph_mutex_lock(h->hdr);
    int r = graph_remove_node_locked(h, node);
    h->hdr->stat_ops++;
    graph_mutex_unlock(h->hdr);
    return r;
}

static inline int graph_has_node(GraphHandle *h, uint32_t node) {
    if (node >= h->hdr->max_nodes) return 0;
    return graph_bit_set(h->node_bitmap, node);
}

static inline int64_t graph_node_data(GraphHandle *h, uint32_t node) {
    return h->node_data[node];
}

static inline void graph_set_node_data(GraphHandle *h, uint32_t node, int64_t data) {
    graph_mutex_lock(h->hdr);
    h->node_data[node] = data;
    graph_mutex_unlock(h->hdr);
}

/* Returns count of neighbors written to out_dst/out_weight (up to max_out).
 * Call with out_dst=NULL to just count. */
static inline uint32_t graph_neighbors(GraphHandle *h, uint32_t node,
                                        uint32_t *out_dst, int64_t *out_weight,
                                        uint32_t max_out) {
    uint32_t count = 0;
    uint32_t eidx = h->node_heads[node];
    while (eidx != GRAPH_NONE) {
        if (out_dst && count < max_out) {
            out_dst[count] = h->edges[eidx].dst;
            out_weight[count] = h->edges[eidx].weight;
        }
        count++;
        eidx = h->edges[eidx].next;
    }
    return count;
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define GRAPH_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, GRAPH_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static GraphHandle *graph_create(const char *path, uint32_t max_nodes, uint32_t max_edges,
                                  char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (max_nodes == 0) { GRAPH_ERR("max_nodes must be > 0"); return NULL; }
    if (max_edges == 0) { GRAPH_ERR("max_edges must be > 0"); return NULL; }
    if (max_nodes > UINT32_MAX - 63) { GRAPH_ERR("max_nodes too large"); return NULL; }
    if (max_edges > UINT32_MAX - 63) { GRAPH_ERR("max_edges too large"); return NULL; }

    uint32_t nb = (max_nodes + 63) / 64;
    uint32_t eb = (max_edges + 63) / 64;

    uint64_t node_data_off   = sizeof(GraphHeader);
    uint64_t node_heads_off  = node_data_off + (uint64_t)max_nodes * sizeof(int64_t);
    uint64_t node_bitmap_off = node_heads_off + (uint64_t)max_nodes * sizeof(uint32_t);
    uint64_t edge_data_off   = node_bitmap_off + (uint64_t)nb * 8;
    uint64_t edge_bitmap_off = edge_data_off + (uint64_t)max_edges * sizeof(GraphEdge);
    uint64_t total           = edge_bitmap_off + (uint64_t)eb * 8;

    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { GRAPH_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { GRAPH_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { GRAPH_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { GRAPH_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            GRAPH_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { GRAPH_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            GraphHeader *hdr = (GraphHeader *)base;
            if (hdr->magic != GRAPH_MAGIC || hdr->version != GRAPH_VERSION ||
                hdr->total_size != (uint64_t)st.st_size) {
                GRAPH_ERR("invalid graph file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            goto setup;
        }
    }

    {
        GraphHeader *hdr = (GraphHeader *)base;
        memset(base, 0, (size_t)total);
        hdr->magic           = GRAPH_MAGIC;
        hdr->version         = GRAPH_VERSION;
        hdr->max_nodes       = max_nodes;
        hdr->max_edges       = max_edges;
        hdr->total_size      = total;
        hdr->node_data_off   = node_data_off;
        hdr->node_heads_off  = node_heads_off;
        hdr->node_bitmap_off = node_bitmap_off;
        hdr->edge_data_off   = edge_data_off;
        hdr->edge_bitmap_off = edge_bitmap_off;
        /* init all node heads to GRAPH_NONE */
        uint32_t *heads = (uint32_t *)((uint8_t *)base + node_heads_off);
        for (uint32_t i = 0; i < max_nodes; i++) heads[i] = GRAPH_NONE;
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
    }
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }

setup:;
    {
        GraphHeader *hdr = (GraphHeader *)base;
        GraphHandle *h = (GraphHandle *)calloc(1, sizeof(GraphHandle));
        if (!h) { munmap(base, map_size); return NULL; }
        h->hdr          = hdr;
        h->node_data    = (int64_t *)((uint8_t *)base + hdr->node_data_off);
        h->node_heads   = (uint32_t *)((uint8_t *)base + hdr->node_heads_off);
        h->node_bitmap  = (uint64_t *)((uint8_t *)base + hdr->node_bitmap_off);
        h->edges        = (GraphEdge *)((uint8_t *)base + hdr->edge_data_off);
        h->edge_bitmap  = (uint64_t *)((uint8_t *)base + hdr->edge_bitmap_off);
        h->node_bwords  = (hdr->max_nodes + 63) / 64;
        h->edge_bwords  = (hdr->max_edges + 63) / 64;
        h->mmap_size    = map_size;
        h->path         = path ? strdup(path) : NULL;
        h->notify_fd    = -1;
        h->backing_fd   = -1;
        return h;
    }
}

static void graph_destroy(GraphHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

#endif /* GRAPH_H */
