/*
 * deque.h -- Fixed-size shared-memory double-ended queue for Linux
 *
 * Ring buffer with CAS-based push/pop at both ends.
 * Futex blocking when empty or full.
 *
 * Head and tail are monotonic uint64_t. Size = tail - head (unsigned).
 * Slot index = cursor % capacity.
 */

#ifndef DEQUE_H
#define DEQUE_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <limits.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <linux/futex.h>
#include <sys/eventfd.h>

#define DEQ_MAGIC       0x44455131U  /* "DEQ1" */
#define DEQ_VERSION     1
#define DEQ_ERR_BUFLEN  256

#define DEQ_VAR_INT   0
#define DEQ_VAR_STR   1

typedef struct {
    uint32_t magic;
    uint32_t version;
    uint32_t elem_size;
    uint32_t variant_id;
    uint64_t capacity;
    uint64_t total_size;
    uint64_t data_off;
    uint8_t  _pad0[24];

    uint64_t head;             /* 64: consumer side (monotonic) */
    uint64_t tail;             /* 72: producer side (monotonic) */
    uint32_t waiters_push;     /* 80 */
    uint32_t waiters_pop;      /* 84 */
    uint64_t stat_pushes;      /* 88 */
    uint64_t stat_pops;        /* 96 */
    uint64_t stat_waits;       /* 104 */
    uint64_t stat_timeouts;    /* 112 */
    uint8_t  _pad1[8];         /* 120-127 */
} DeqHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(DeqHeader) == 128, "DeqHeader must be 128 bytes");
#endif

typedef struct {
    DeqHeader *hdr;
    uint8_t   *data;
    size_t     mmap_size;
    uint32_t   elem_size;
    char      *path;
    int        notify_fd;
    int        backing_fd;
} DeqHandle;

/* ================================================================ */

static inline void deq_make_deadline(double t, struct timespec *dl) {
    clock_gettime(CLOCK_MONOTONIC, dl);
    dl->tv_sec += (time_t)t;
    dl->tv_nsec += (long)((t - (double)(time_t)t) * 1e9);
    if (dl->tv_nsec >= 1000000000L) { dl->tv_sec++; dl->tv_nsec -= 1000000000L; }
}

static inline int deq_remaining(const struct timespec *dl, struct timespec *rem) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    rem->tv_sec = dl->tv_sec - now.tv_sec;
    rem->tv_nsec = dl->tv_nsec - now.tv_nsec;
    if (rem->tv_nsec < 0) { rem->tv_sec--; rem->tv_nsec += 1000000000L; }
    return rem->tv_sec >= 0;
}

static inline uint8_t *deq_slot(DeqHandle *h, uint64_t idx) {
    return h->data + (idx % h->hdr->capacity) * h->elem_size;
}

static inline uint64_t deq_size(DeqHandle *h) {
    uint64_t t = __atomic_load_n(&h->hdr->tail, __ATOMIC_ACQUIRE);
    uint64_t hd = __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);
    return t - hd;
}

/* ================================================================
 * Push back (tail++)
 * ================================================================ */

static inline int deq_try_push_back(DeqHandle *h, const void *val, uint32_t vlen) {
    DeqHeader *hdr = h->hdr;
    for (;;) {
        uint64_t t = __atomic_load_n(&hdr->tail, __ATOMIC_RELAXED);
        uint64_t hd = __atomic_load_n(&hdr->head, __ATOMIC_ACQUIRE);
        if (t - hd >= hdr->capacity) return 0;
        if (__atomic_compare_exchange_n(&hdr->tail, &t, t + 1,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint32_t sz = h->elem_size;
            uint32_t cp = vlen < sz ? vlen : sz;
            memcpy(deq_slot(h, t), val, cp);
            if (cp < sz) memset(deq_slot(h, t) + cp, 0, sz - cp);
            __atomic_thread_fence(__ATOMIC_RELEASE);
            __atomic_add_fetch(&hdr->stat_pushes, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_pop, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->tail, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            return 1;
        }
    }
}

/* ================================================================
 * Push front (head--)
 * ================================================================ */

static inline int deq_try_push_front(DeqHandle *h, const void *val, uint32_t vlen) {
    DeqHeader *hdr = h->hdr;
    for (;;) {
        uint64_t t = __atomic_load_n(&hdr->tail, __ATOMIC_ACQUIRE);
        uint64_t hd = __atomic_load_n(&hdr->head, __ATOMIC_RELAXED);
        if (t - hd >= hdr->capacity) return 0;
        uint64_t new_hd = hd - 1;
        if (__atomic_compare_exchange_n(&hdr->head, &hd, new_hd,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint32_t sz = h->elem_size;
            uint32_t cp = vlen < sz ? vlen : sz;
            memcpy(deq_slot(h, new_hd), val, cp);
            if (cp < sz) memset(deq_slot(h, new_hd) + cp, 0, sz - cp);
            __atomic_thread_fence(__ATOMIC_RELEASE);
            __atomic_add_fetch(&hdr->stat_pushes, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_pop, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->tail, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            return 1;
        }
    }
}

/* ================================================================
 * Pop front (head++)
 * ================================================================ */

static inline int deq_try_pop_front(DeqHandle *h, void *out) {
    DeqHeader *hdr = h->hdr;
    for (;;) {
        uint64_t hd = __atomic_load_n(&hdr->head, __ATOMIC_RELAXED);
        uint64_t t = __atomic_load_n(&hdr->tail, __ATOMIC_ACQUIRE);
        if (t - hd == 0) return 0;
        if (__atomic_compare_exchange_n(&hdr->head, &hd, hd + 1,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            memcpy(out, deq_slot(h, hd), h->elem_size);
            __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->head, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            return 1;
        }
    }
}

/* ================================================================
 * Pop back (tail--)
 * ================================================================ */

static inline int deq_try_pop_back(DeqHandle *h, void *out) {
    DeqHeader *hdr = h->hdr;
    for (;;) {
        uint64_t t = __atomic_load_n(&hdr->tail, __ATOMIC_RELAXED);
        uint64_t hd = __atomic_load_n(&hdr->head, __ATOMIC_ACQUIRE);
        if (t - hd == 0) return 0;
        if (__atomic_compare_exchange_n(&hdr->tail, &t, t - 1,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            memcpy(out, deq_slot(h, t - 1), h->elem_size);
            __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->head, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            return 1;
        }
    }
}

/* ================================================================
 * Blocking push/pop
 * ================================================================ */

static inline int deq_push_wait(DeqHandle *h, const void *val, uint32_t vlen,
                                 int front, double timeout) {
    int (*try_fn)(DeqHandle*, const void*, uint32_t) =
        front ? deq_try_push_front : deq_try_push_back;
    if (try_fn(h, val, vlen)) return 1;
    if (timeout == 0) return 0;

    DeqHeader *hdr = h->hdr;
    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) deq_make_deadline(timeout, &dl);
    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        __atomic_add_fetch(&hdr->waiters_push, 1, __ATOMIC_RELEASE);
        uint64_t hd = __atomic_load_n(&hdr->head, __ATOMIC_ACQUIRE);
        uint64_t t = __atomic_load_n(&hdr->tail, __ATOMIC_ACQUIRE);
        if (t - hd >= hdr->capacity) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!deq_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&hdr->waiters_push, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &hdr->head, FUTEX_WAIT,
                    (uint32_t)(hd & 0xFFFFFFFF), pts, NULL, 0);
        }
        __atomic_sub_fetch(&hdr->waiters_push, 1, __ATOMIC_RELAXED);
        if (try_fn(h, val, vlen)) return 1;
        if (has_dl && !deq_remaining(&dl, &rem)) {
            __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }
}

static inline int deq_pop_wait(DeqHandle *h, void *out, int back, double timeout) {
    int (*try_fn)(DeqHandle*, void*) =
        back ? deq_try_pop_back : deq_try_pop_front;
    if (try_fn(h, out)) return 1;
    if (timeout == 0) return 0;

    DeqHeader *hdr = h->hdr;
    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) deq_make_deadline(timeout, &dl);
    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        __atomic_add_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELEASE);
        uint64_t t = __atomic_load_n(&hdr->tail, __ATOMIC_ACQUIRE);
        uint64_t hd = __atomic_load_n(&hdr->head, __ATOMIC_ACQUIRE);
        if (t - hd == 0) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!deq_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &hdr->tail, FUTEX_WAIT,
                    (uint32_t)(t & 0xFFFFFFFF), pts, NULL, 0);
        }
        __atomic_sub_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELAXED);
        if (try_fn(h, out)) return 1;
        if (has_dl && !deq_remaining(&dl, &rem)) {
            __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define DEQ_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, DEQ_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static inline void deq_init_header(void *base, uint64_t total,
                                    uint32_t elem_size, uint32_t variant_id,
                                    uint64_t capacity) {
    DeqHeader *hdr = (DeqHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic      = DEQ_MAGIC;
    hdr->version    = DEQ_VERSION;
    hdr->elem_size  = elem_size;
    hdr->variant_id = variant_id;
    hdr->capacity   = capacity;
    hdr->total_size = total;
    hdr->data_off   = sizeof(DeqHeader);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline DeqHandle *deq_setup(void *base, size_t ms, const char *path, int bfd) {
    DeqHeader *hdr = (DeqHeader *)base;
    DeqHandle *h = (DeqHandle *)calloc(1, sizeof(DeqHandle));
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

static DeqHandle *deq_create(const char *path, uint64_t capacity,
                              uint32_t elem_size, uint32_t variant_id,
                              char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { DEQ_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { DEQ_ERR("elem_size must be > 0"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(DeqHeader)) / elem_size) {
        DEQ_ERR("capacity * elem_size overflow"); return NULL;
    }

    uint64_t total = sizeof(DeqHeader) + capacity * elem_size;
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { DEQ_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { DEQ_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { DEQ_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) {
            DEQ_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        int is_new = (st.st_size == 0);
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            DEQ_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { DEQ_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            DeqHeader *hdr = (DeqHeader *)base;
            if (hdr->magic != DEQ_MAGIC || hdr->version != DEQ_VERSION ||
                hdr->variant_id != variant_id ||
                hdr->total_size != (uint64_t)st.st_size) {
                DEQ_ERR("invalid deque file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return deq_setup(base, map_size, path, -1);
        }
    }
    deq_init_header(base, total, elem_size, variant_id, capacity);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return deq_setup(base, map_size, path, -1);
}

static DeqHandle *deq_create_memfd(const char *name, uint64_t capacity,
                                    uint32_t elem_size, uint32_t variant_id,
                                    char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { DEQ_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { DEQ_ERR("elem_size must be > 0"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(DeqHeader)) / elem_size) {
        DEQ_ERR("capacity * elem_size overflow"); return NULL;
    }
    uint64_t total = sizeof(DeqHeader) + capacity * elem_size;
    int fd = memfd_create(name ? name : "deque", MFD_CLOEXEC);
    if (fd < 0) { DEQ_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) { DEQ_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL; }
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { DEQ_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    deq_init_header(base, total, elem_size, variant_id, capacity);
    return deq_setup(base, (size_t)total, NULL, fd);
}

static DeqHandle *deq_open_fd(int fd, uint32_t variant_id, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { DEQ_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(DeqHeader)) { DEQ_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { DEQ_ERR("mmap: %s", strerror(errno)); return NULL; }
    DeqHeader *hdr = (DeqHeader *)base;
    if (hdr->magic != DEQ_MAGIC || hdr->version != DEQ_VERSION ||
        hdr->variant_id != variant_id ||
        hdr->total_size != (uint64_t)st.st_size) {
        DEQ_ERR("invalid deque"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { DEQ_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return deq_setup(base, ms, NULL, myfd);
}

static void deq_destroy(DeqHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

/* NOT concurrency-safe — use drain() for concurrent scenarios */
static void deq_clear(DeqHandle *h) {
    __atomic_store_n(&h->hdr->head, 0, __ATOMIC_RELEASE);
    __atomic_store_n(&h->hdr->tail, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&h->hdr->waiters_push, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &h->hdr->head, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    if (__atomic_load_n(&h->hdr->waiters_pop, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &h->hdr->tail, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* Concurrency-safe drain: CAS head to current tail, returns count drained */
static inline uint64_t deq_drain(DeqHandle *h) {
    DeqHeader *hdr = h->hdr;
    for (;;) {
        uint64_t hd = __atomic_load_n(&hdr->head, __ATOMIC_RELAXED);
        uint64_t t = __atomic_load_n(&hdr->tail, __ATOMIC_ACQUIRE);
        uint64_t count = t - hd;
        if (count == 0) return 0;
        if (__atomic_compare_exchange_n(&hdr->head, &hd, t,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->head, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            return count;
        }
    }
}

static int deq_create_eventfd(DeqHandle *h) {
    if (h->notify_fd >= 0) close(h->notify_fd);
    int efd = eventfd(0, EFD_NONBLOCK|EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd; return efd;
}
static int deq_notify(DeqHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t v = 1; return write(h->notify_fd, &v, sizeof(v)) == sizeof(v);
}
static int64_t deq_eventfd_consume(DeqHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t v = 0;
    if (read(h->notify_fd, &v, sizeof(v)) != sizeof(v)) return -1;
    return (int64_t)v;
}
static void deq_msync(DeqHandle *h) { msync(h->hdr, h->mmap_size, MS_SYNC); }

#endif /* DEQUE_H */
