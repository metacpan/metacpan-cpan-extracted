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
                if (!graph_pid_alive(pid) &&
                    __atomic_compare_exchange_n(&hdr->mutex, &cur, 0,
                            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                    /* Recovered — wake one waiter so it can proceed. */
                    syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
                }
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
        uint64_t word = __atomic_load_n(&bm[w], __ATOMIC_RELAXED);
        if (word == ~(uint64_t)0) continue;
        int bit = __builtin_ctzll(~word);
        uint32_t idx = w * 64 + bit;
        if (idx >= max) return -1;
        __atomic_fetch_or(&bm[w], (uint64_t)1 << bit, __ATOMIC_RELEASE);
        return (int32_t)idx;
    }
    return -1;
}

static inline void graph_bit_free(uint64_t *bm, uint32_t idx) {
    __atomic_fetch_and(&bm[idx / 64], ~((uint64_t)1 << (idx % 64)), __ATOMIC_RELEASE);
}

/* ================================================================
 * Graph operations (must hold mutex)
 * ================================================================ */

static inline int32_t graph_add_node_locked(GraphHandle *h, int64_t data) {
    int32_t idx = graph_bit_alloc(h->node_bitmap, h->node_bwords, h->hdr->max_nodes);
    if (idx < 0) return -1;
    h->node_data[idx] = data;
    h->node_heads[idx] = GRAPH_NONE;
    __atomic_fetch_add(&h->hdr->node_count, 1, __ATOMIC_RELAXED);
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
    __atomic_fetch_add(&h->hdr->edge_count, 1, __ATOMIC_RELAXED);
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
        __atomic_fetch_sub(&h->hdr->edge_count, 1, __ATOMIC_RELAXED);
        eidx = next;
    }
    h->node_heads[node] = GRAPH_NONE;
    graph_bit_free(h->node_bitmap, node);
    __atomic_fetch_sub(&h->hdr->node_count, 1, __ATOMIC_RELAXED);
    return 1;
}

/* Like remove_node_locked, but also splices every other node's adjacency
 * list to drop edges pointing TO `node` (incoming edges). O(N+E). */
static inline int graph_remove_node_full_locked(GraphHandle *h, uint32_t node) {
    if (node >= h->hdr->max_nodes) return 0;
    if (!graph_bit_set(h->node_bitmap, node)) return 0;
    uint32_t max_n = h->hdr->max_nodes;
    for (uint32_t src = 0; src < max_n; src++) {
        if (src == node) continue;
        if (!graph_bit_set(h->node_bitmap, src)) continue;
        uint32_t *slot = &h->node_heads[src];
        uint32_t eidx = *slot;
        while (eidx != GRAPH_NONE) {
            uint32_t next = h->edges[eidx].next;
            if (h->edges[eidx].dst == node) {
                *slot = next;
                graph_bit_free(h->edge_bitmap, eidx);
                __atomic_fetch_sub(&h->hdr->edge_count, 1, __ATOMIC_RELAXED);
            } else {
                slot = &h->edges[eidx].next;
            }
            eidx = next;
        }
    }
    return graph_remove_node_locked(h, node);
}

/* ================================================================
 * Public API (lock + operation + unlock)
 * ================================================================ */

static inline int32_t graph_add_node(GraphHandle *h, int64_t data) {
    graph_mutex_lock(h->hdr);
    int32_t r = graph_add_node_locked(h, data);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    graph_mutex_unlock(h->hdr);
    return r;
}

static inline int graph_add_edge(GraphHandle *h, uint32_t src, uint32_t dst, int64_t weight) {
    graph_mutex_lock(h->hdr);
    int r = graph_add_edge_locked(h, src, dst, weight);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    graph_mutex_unlock(h->hdr);
    return r;
}

static inline int graph_remove_node(GraphHandle *h, uint32_t node) {
    graph_mutex_lock(h->hdr);
    int r = graph_remove_node_locked(h, node);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    graph_mutex_unlock(h->hdr);
    return r;
}

static inline int graph_remove_node_full(GraphHandle *h, uint32_t node) {
    graph_mutex_lock(h->hdr);
    int r = graph_remove_node_full_locked(h, node);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    graph_mutex_unlock(h->hdr);
    return r;
}

static inline int graph_has_node(GraphHandle *h, uint32_t node) {
    if (node >= h->hdr->max_nodes) return 0;
    return graph_bit_set(h->node_bitmap, node);
}

/* Caller must hold graph_mutex and have verified node is live via bitmap. */
static inline uint32_t graph_degree(GraphHandle *h, uint32_t node) {
    if (node >= h->hdr->max_nodes) return 0;
    uint32_t count = 0;
    uint32_t eidx = h->node_heads[node];
    while (eidx != GRAPH_NONE) {
        count++;
        eidx = h->edges[eidx].next;
    }
    return count;
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define GRAPH_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, GRAPH_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static inline uint64_t graph_total_size(uint32_t max_nodes, uint32_t max_edges) {
    uint32_t nb = (max_nodes + 63) / 64;
    uint32_t eb = (max_edges + 63) / 64;
    uint64_t node_data_off   = sizeof(GraphHeader);
    uint64_t node_heads_off  = node_data_off + (uint64_t)max_nodes * sizeof(int64_t);
    uint64_t node_bitmap_off = node_heads_off + (uint64_t)max_nodes * sizeof(uint32_t);
    uint64_t edge_data_off   = node_bitmap_off + (uint64_t)nb * 8;
    uint64_t edge_bitmap_off = edge_data_off + (uint64_t)max_edges * sizeof(GraphEdge);
    return edge_bitmap_off + (uint64_t)eb * 8;
}

static inline void graph_init_header(void *base, uint32_t max_nodes, uint32_t max_edges,
                                      uint64_t total) {
    uint32_t nb = (max_nodes + 63) / 64;
    uint64_t node_data_off   = sizeof(GraphHeader);
    uint64_t node_heads_off  = node_data_off + (uint64_t)max_nodes * sizeof(int64_t);
    uint64_t node_bitmap_off = node_heads_off + (uint64_t)max_nodes * sizeof(uint32_t);
    uint64_t edge_data_off   = node_bitmap_off + (uint64_t)nb * 8;
    uint64_t edge_bitmap_off = edge_data_off + (uint64_t)max_edges * sizeof(GraphEdge);

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
    uint32_t *heads = (uint32_t *)((uint8_t *)base + node_heads_off);
    for (uint32_t i = 0; i < max_nodes; i++) heads[i] = GRAPH_NONE;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline GraphHandle *graph_setup(void *base, size_t map_size,
                                        const char *path, int backing_fd) {
    GraphHeader *hdr = (GraphHeader *)base;
    GraphHandle *h = (GraphHandle *)calloc(1, sizeof(GraphHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
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
    h->backing_fd   = backing_fd;
    return h;
}

/* Validate a mapped header (shared by graph_create reopen and graph_open_fd). */
static inline int graph_validate_header(const GraphHeader *hdr, uint64_t file_size) {
    if (hdr->magic != GRAPH_MAGIC) return 0;
    if (hdr->version != GRAPH_VERSION) return 0;
    if (hdr->max_nodes == 0 || hdr->max_edges == 0) return 0;
    if (hdr->max_nodes > 0x7FFFFFFFu || hdr->max_edges > 0x7FFFFFFFu) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != graph_total_size(hdr->max_nodes, hdr->max_edges)) return 0;

    uint32_t nb = (hdr->max_nodes + 63) / 64;
    uint64_t exp_node_data   = sizeof(GraphHeader);
    uint64_t exp_node_heads  = exp_node_data  + (uint64_t)hdr->max_nodes * sizeof(int64_t);
    uint64_t exp_node_bitmap = exp_node_heads + (uint64_t)hdr->max_nodes * sizeof(uint32_t);
    uint64_t exp_edge_data   = exp_node_bitmap + (uint64_t)nb * 8;
    uint64_t exp_edge_bitmap = exp_edge_data   + (uint64_t)hdr->max_edges * sizeof(GraphEdge);
    if (hdr->node_data_off   != exp_node_data)   return 0;
    if (hdr->node_heads_off  != exp_node_heads)  return 0;
    if (hdr->node_bitmap_off != exp_node_bitmap) return 0;
    if (hdr->edge_data_off   != exp_edge_data)   return 0;
    if (hdr->edge_bitmap_off != exp_edge_bitmap) return 0;
    return 1;
}

static GraphHandle *graph_create(const char *path, uint32_t max_nodes, uint32_t max_edges,
                                  char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (max_nodes == 0) { GRAPH_ERR("max_nodes must be > 0"); return NULL; }
    if (max_edges == 0) { GRAPH_ERR("max_edges must be > 0"); return NULL; }
    if (max_nodes > UINT32_MAX - 63) { GRAPH_ERR("max_nodes too large"); return NULL; }
    if (max_edges > UINT32_MAX - 63) { GRAPH_ERR("max_edges too large"); return NULL; }

    uint64_t total = graph_total_size(max_nodes, max_edges);
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
        if (!is_new && (uint64_t)st.st_size < sizeof(GraphHeader)) {
            GRAPH_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            GRAPH_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { GRAPH_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!graph_validate_header((GraphHeader *)base, (uint64_t)st.st_size)) {
                GRAPH_ERR("invalid graph file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return graph_setup(base, map_size, path, -1);
        }
    }
    graph_init_header(base, max_nodes, max_edges, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return graph_setup(base, map_size, path, -1);
}

static GraphHandle *graph_create_memfd(const char *name, uint32_t max_nodes, uint32_t max_edges,
                                        char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (max_nodes == 0) { GRAPH_ERR("max_nodes must be > 0"); return NULL; }
    if (max_edges == 0) { GRAPH_ERR("max_edges must be > 0"); return NULL; }
    if (max_nodes > UINT32_MAX - 63 || max_edges > UINT32_MAX - 63) {
        GRAPH_ERR("max_nodes/max_edges too large"); return NULL;
    }
    uint64_t total = graph_total_size(max_nodes, max_edges);
    int fd = memfd_create(name ? name : "graph", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { GRAPH_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        GRAPH_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { GRAPH_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    graph_init_header(base, max_nodes, max_edges, total);
    return graph_setup(base, (size_t)total, NULL, fd);
}

static GraphHandle *graph_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { GRAPH_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(GraphHeader)) { GRAPH_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { GRAPH_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!graph_validate_header((GraphHeader *)base, (uint64_t)st.st_size)) {
        GRAPH_ERR("invalid graph"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { GRAPH_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return graph_setup(base, ms, NULL, myfd);
}

static void graph_destroy(GraphHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int graph_msync(GraphHandle *h) {
    if (!h || !h->hdr) return 0;
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

static int graph_create_eventfd(GraphHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    int efd = eventfd(0, EFD_NONBLOCK|EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd;
    return efd;
}

static int graph_notify(GraphHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t v = 1;
    return write(h->notify_fd, &v, sizeof(v)) == sizeof(v);
}

static int64_t graph_eventfd_consume(GraphHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t v = 0;
    if (read(h->notify_fd, &v, sizeof(v)) != sizeof(v)) return -1;
    return (int64_t)v;
}

#endif /* GRAPH_H */
