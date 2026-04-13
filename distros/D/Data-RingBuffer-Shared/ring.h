/*
 * ring.h -- Shared-memory fixed-size ring buffer for Linux
 *
 * Lock-free circular buffer: writes overwrite oldest when full.
 * Readers access by relative position (0=latest) or absolute sequence.
 * No consumer tracking — data persists until overwritten.
 *
 * Unlike Queue (consumed on read) or PubSub (subscription tracking),
 * RingBuffer is a simple overwriting circular window.
 */

#ifndef RING_H
#define RING_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <linux/futex.h>
#include <sys/eventfd.h>

#define RING_MAGIC       0x524E4731U  /* "RNG1" */
#define RING_VERSION     1
#define RING_ERR_BUFLEN  256

#define RING_VAR_INT  0
#define RING_VAR_F64  1

/* ================================================================
 * Header (128 bytes)
 * ================================================================ */

typedef struct {
    uint32_t magic;
    uint32_t version;
    uint32_t elem_size;
    uint32_t variant_id;
    uint64_t capacity;
    uint64_t total_size;
    uint64_t data_off;
    uint8_t  _pad0[24];

    uint64_t head;             /* 64: monotonic write cursor (next write position) */
    uint64_t count;            /* 72: total writes (for overwrite detection) */
    uint32_t waiters;          /* 80: blocked on new data */
    uint32_t _pad1;            /* 84 */
    uint64_t stat_writes;      /* 88 */
    uint64_t stat_overwrites;  /* 96 */
    uint8_t  _pad2[24];        /* 104-127 */
} RingHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(RingHeader) == 128, "RingHeader must be 128 bytes");
#endif

typedef struct {
    RingHeader *hdr;
    uint8_t    *data;
    size_t      mmap_size;
    uint32_t    elem_size;
    char       *path;
    int         notify_fd;
    int         backing_fd;
} RingHandle;

/* ================================================================
 * Slot access
 * ================================================================ */

static inline uint8_t *ring_slot(RingHandle *h, uint64_t seq) {
    return h->data + (seq % h->hdr->capacity) * h->elem_size;
}

/* ================================================================
 * Write — overwrites oldest when full, always succeeds
 * ================================================================ */

static inline uint64_t ring_write(RingHandle *h, const void *val, uint32_t vlen) {
    RingHeader *hdr = h->hdr;
    /* CAS to claim a slot */
    uint64_t pos;
    for (;;) {
        pos = __atomic_load_n(&hdr->head, __ATOMIC_RELAXED);
        if (__atomic_compare_exchange_n(&hdr->head, &pos, pos + 1,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
            break;
    }
    /* Write data */
    uint32_t sz = h->elem_size;
    uint32_t cp = vlen < sz ? vlen : sz;
    memcpy(ring_slot(h, pos), val, cp);
    if (cp < sz) memset(ring_slot(h, pos) + cp, 0, sz - cp);
    __atomic_thread_fence(__ATOMIC_RELEASE);

    /* Track overwrites */
    uint64_t cnt = __atomic_add_fetch(&hdr->count, 1, __ATOMIC_RELEASE);
    if (cnt > hdr->capacity)
        __atomic_add_fetch(&hdr->stat_overwrites, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&hdr->stat_writes, 1, __ATOMIC_RELAXED);

    /* Wake readers */
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->count, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);

    return pos;
}

/* ================================================================
 * Read — by relative position (0=latest) or absolute sequence
 * ================================================================ */

/* Read the nth most recent value (0=latest, 1=previous, ...).
 * Returns 1 on success, 0 if n >= available entries. */
static inline int ring_read_latest(RingHandle *h, uint32_t n, void *out) {
    uint64_t head = __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);
    if (head == 0) return 0;
    uint64_t avail = head < h->hdr->capacity ? head : h->hdr->capacity;
    if (n >= avail) return 0;
    uint64_t seq = head - 1 - n;
    memcpy(out, ring_slot(h, seq), h->elem_size);
    return 1;
}

/* Read by absolute sequence number. Returns 1 if still in buffer. */
static inline int ring_read_seq(RingHandle *h, uint64_t seq, void *out) {
    uint64_t head = __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);
    if (seq >= head) return 0;  /* not yet written */
    uint64_t oldest = (head > h->hdr->capacity) ? head - h->hdr->capacity : 0;
    if (seq < oldest) return 0;  /* already overwritten */
    memcpy(out, ring_slot(h, seq), h->elem_size);
    return 1;
}

/* ================================================================
 * Status
 * ================================================================ */

static inline uint64_t ring_head(RingHandle *h) {
    return __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);
}

static inline uint64_t ring_size(RingHandle *h) {
    uint64_t head = __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);
    return head < h->hdr->capacity ? head : h->hdr->capacity;
}

/* ================================================================
 * Wait — block until new data arrives
 * ================================================================ */

static inline void ring_make_deadline(double t, struct timespec *dl) {
    clock_gettime(CLOCK_MONOTONIC, dl);
    dl->tv_sec += (time_t)t;
    dl->tv_nsec += (long)((t - (double)(time_t)t) * 1e9);
    if (dl->tv_nsec >= 1000000000L) { dl->tv_sec++; dl->tv_nsec -= 1000000000L; }
}

static inline int ring_remaining(const struct timespec *dl, struct timespec *rem) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    rem->tv_sec = dl->tv_sec - now.tv_sec;
    rem->tv_nsec = dl->tv_nsec - now.tv_nsec;
    if (rem->tv_nsec < 0) { rem->tv_sec--; rem->tv_nsec += 1000000000L; }
    return rem->tv_sec >= 0;
}

static inline int ring_wait(RingHandle *h, uint64_t expected_count, double timeout) {
    if (__atomic_load_n(&h->hdr->count, __ATOMIC_ACQUIRE) != expected_count) return 1;
    if (timeout == 0) return 0;

    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) ring_make_deadline(timeout, &dl);

    for (;;) {
        __atomic_add_fetch(&h->hdr->waiters, 1, __ATOMIC_RELEASE);
        uint64_t cur = __atomic_load_n(&h->hdr->count, __ATOMIC_ACQUIRE);
        if (cur == expected_count) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!ring_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &h->hdr->count, FUTEX_WAIT,
                    (uint32_t)(cur & 0xFFFFFFFF), pts, NULL, 0);
        }
        __atomic_sub_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
        if (__atomic_load_n(&h->hdr->count, __ATOMIC_ACQUIRE) != expected_count) return 1;
        if (has_dl && !ring_remaining(&dl, &rem)) return 0;
    }
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define RING_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, RING_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static inline void ring_init_header(void *base, uint64_t total,
                                     uint32_t elem_size, uint32_t variant_id,
                                     uint64_t capacity) {
    RingHeader *hdr = (RingHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic      = RING_MAGIC;
    hdr->version    = RING_VERSION;
    hdr->elem_size  = elem_size;
    hdr->variant_id = variant_id;
    hdr->capacity   = capacity;
    hdr->total_size = total;
    hdr->data_off   = sizeof(RingHeader);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline RingHandle *ring_setup(void *base, size_t ms, const char *path, int bfd) {
    RingHeader *hdr = (RingHeader *)base;
    RingHandle *h = (RingHandle *)calloc(1, sizeof(RingHandle));
    if (!h) { munmap(base, ms); return NULL; }
    h->hdr = hdr;
    h->data = (uint8_t *)base + hdr->data_off;
    h->mmap_size = ms;
    h->elem_size = hdr->elem_size;
    h->path = path ? strdup(path) : NULL;
    h->notify_fd = -1;
    h->backing_fd = bfd;
    return h;
}

static RingHandle *ring_create(const char *path, uint64_t capacity,
                                uint32_t elem_size, uint32_t variant_id,
                                char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { RING_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { RING_ERR("elem_size must be > 0"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(RingHeader)) / elem_size) {
        RING_ERR("capacity * elem_size overflow"); return NULL;
    }

    uint64_t total = sizeof(RingHeader) + capacity * elem_size;
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { RING_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { RING_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { RING_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { RING_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            RING_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { RING_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            RingHeader *hdr = (RingHeader *)base;
            if (hdr->magic != RING_MAGIC || hdr->version != RING_VERSION ||
                hdr->variant_id != variant_id ||
                hdr->total_size != (uint64_t)st.st_size) {
                RING_ERR("invalid ring file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return ring_setup(base, map_size, path, -1);
        }
    }
    ring_init_header(base, total, elem_size, variant_id, capacity);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return ring_setup(base, map_size, path, -1);
}

static RingHandle *ring_create_memfd(const char *name, uint64_t capacity,
                                      uint32_t elem_size, uint32_t variant_id,
                                      char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { RING_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { RING_ERR("elem_size must be > 0"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(RingHeader)) / elem_size) {
        RING_ERR("capacity * elem_size overflow"); return NULL;
    }
    uint64_t total = sizeof(RingHeader) + capacity * elem_size;
    int fd = memfd_create(name ? name : "ring", MFD_CLOEXEC);
    if (fd < 0) { RING_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) { RING_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL; }
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { RING_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    ring_init_header(base, total, elem_size, variant_id, capacity);
    return ring_setup(base, (size_t)total, NULL, fd);
}

static RingHandle *ring_open_fd(int fd, uint32_t variant_id, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { RING_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(RingHeader)) { RING_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { RING_ERR("mmap: %s", strerror(errno)); return NULL; }
    RingHeader *hdr = (RingHeader *)base;
    if (hdr->magic != RING_MAGIC || hdr->version != RING_VERSION ||
        hdr->variant_id != variant_id ||
        hdr->total_size != (uint64_t)st.st_size) {
        RING_ERR("invalid ring"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { RING_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return ring_setup(base, ms, NULL, myfd);
}

static void ring_destroy(RingHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

static void ring_clear(RingHandle *h) {
    __atomic_store_n(&h->hdr->head, 0, __ATOMIC_RELEASE);
    __atomic_store_n(&h->hdr->count, 0, __ATOMIC_RELEASE);
}

static int ring_create_eventfd(RingHandle *h) {
    if (h->notify_fd >= 0) close(h->notify_fd);
    int efd = eventfd(0, EFD_NONBLOCK|EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd; return efd;
}
static int ring_notify(RingHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t v = 1; return write(h->notify_fd, &v, sizeof(v)) == sizeof(v);
}
static int64_t ring_eventfd_consume(RingHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t v = 0;
    if (read(h->notify_fd, &v, sizeof(v)) != sizeof(v)) return -1;
    return (int64_t)v;
}
static void ring_msync(RingHandle *h) { msync(h->hdr, h->mmap_size, MS_SYNC); }

#endif /* RING_H */
