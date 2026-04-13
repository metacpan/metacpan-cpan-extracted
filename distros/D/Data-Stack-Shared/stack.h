/*
 * stack.h -- Fixed-size shared-memory LIFO stack for Linux
 *
 * CAS-based lock-free push/pop on atomic top index.
 * Futex blocking when empty (pop) or full (push).
 *
 * Variants: Int (int64_t), Str (length-prefixed)
 */

#ifndef STACK_H
#define STACK_H

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

#define STK_MAGIC       0x53544B31U  /* "STK1" */
#define STK_VERSION     1
#define STK_ERR_BUFLEN  256

#define STK_VAR_INT   0
#define STK_VAR_STR   1

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

    uint32_t top;              /* 64: next free index (0=empty, capacity=full) */
    uint32_t waiters_push;     /* 68 */
    uint32_t waiters_pop;      /* 72 */
    uint32_t _pad1;            /* 76 */
    uint64_t stat_pushes;      /* 80 */
    uint64_t stat_pops;        /* 88 */
    uint64_t stat_waits;       /* 96 */
    uint64_t stat_timeouts;    /* 104 */
    uint8_t  _pad2[16];        /* 112-127 */
} StkHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(StkHeader) == 128, "StkHeader must be 128 bytes");
#endif

typedef struct {
    StkHeader *hdr;
    uint8_t   *data;
    size_t     mmap_size;
    uint32_t   elem_size;      /* cached from header at open time */
    char      *path;
    int        notify_fd;
    int        backing_fd;
} StkHandle;

/* ================================================================
 * Utility
 * ================================================================ */

static inline void stk_make_deadline(double timeout, struct timespec *dl) {
    clock_gettime(CLOCK_MONOTONIC, dl);
    dl->tv_sec += (time_t)timeout;
    dl->tv_nsec += (long)((timeout - (double)(time_t)timeout) * 1e9);
    if (dl->tv_nsec >= 1000000000L) { dl->tv_sec++; dl->tv_nsec -= 1000000000L; }
}

static inline int stk_remaining(const struct timespec *dl, struct timespec *rem) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    rem->tv_sec = dl->tv_sec - now.tv_sec;
    rem->tv_nsec = dl->tv_nsec - now.tv_nsec;
    if (rem->tv_nsec < 0) { rem->tv_sec--; rem->tv_nsec += 1000000000L; }
    return rem->tv_sec >= 0;
}

static inline uint8_t *stk_slot(StkHandle *h, uint32_t idx) {
    return h->data + (uint64_t)idx * h->elem_size;
}

/* ================================================================
 * Push (LIFO top++)
 * ================================================================ */

static inline int stk_try_push(StkHandle *h, const void *val, uint32_t vlen) {
    StkHeader *hdr = h->hdr;
    for (;;) {
        uint32_t t = __atomic_load_n(&hdr->top, __ATOMIC_RELAXED);
        if (t >= (uint32_t)hdr->capacity) return 0;
        if (__atomic_compare_exchange_n(&hdr->top, &t, t + 1,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint32_t sz = h->elem_size;
            uint32_t cp = vlen < sz ? vlen : sz;
            memcpy(stk_slot(h, t), val, cp);
            if (cp < sz) memset(stk_slot(h, t) + cp, 0, sz - cp);
            __atomic_thread_fence(__ATOMIC_RELEASE);
            __atomic_add_fetch(&hdr->stat_pushes, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_pop, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->top, FUTEX_WAKE, 1, NULL, NULL, 0);
            return 1;
        }
    }
}

static inline int stk_push(StkHandle *h, const void *val, uint32_t vlen, double timeout) {
    if (stk_try_push(h, val, vlen)) return 1;
    if (timeout == 0) return 0;

    StkHeader *hdr = h->hdr;
    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) stk_make_deadline(timeout, &dl);
    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        __atomic_add_fetch(&hdr->waiters_push, 1, __ATOMIC_RELEASE);
        uint32_t t = __atomic_load_n(&hdr->top, __ATOMIC_ACQUIRE);
        if (t >= (uint32_t)hdr->capacity) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!stk_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&hdr->waiters_push, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &hdr->top, FUTEX_WAIT, t, pts, NULL, 0);
        }
        __atomic_sub_fetch(&hdr->waiters_push, 1, __ATOMIC_RELAXED);
        if (stk_try_push(h, val, vlen)) return 1;
        if (has_dl && !stk_remaining(&dl, &rem)) {
            __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }
}

/* ================================================================
 * Pop (LIFO top--) — read slot BEFORE CAS to avoid race with pusher
 * ================================================================ */

static inline int stk_try_pop(StkHandle *h, void *out) {
    StkHeader *hdr = h->hdr;
    for (;;) {
        uint32_t t = __atomic_load_n(&hdr->top, __ATOMIC_ACQUIRE);
        if (t == 0) return 0;
        if (__atomic_compare_exchange_n(&hdr->top, &t, t - 1,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            /* Read-after-CAS avoids ABA (read-before-CAS can return
             * stale data when the slot is recycled). Under extreme
             * contention a concurrent push can race on the same slot;
             * this is a known limitation of lock-free array stacks. */
            memcpy(out, stk_slot(h, t - 1), h->elem_size);
            __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->top, FUTEX_WAKE, 1, NULL, NULL, 0);
            return 1;
        }
    }
}

static inline int stk_pop(StkHandle *h, void *out, double timeout) {
    if (stk_try_pop(h, out)) return 1;
    if (timeout == 0) return 0;

    StkHeader *hdr = h->hdr;
    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) stk_make_deadline(timeout, &dl);
    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        __atomic_add_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELEASE);
        uint32_t t = __atomic_load_n(&hdr->top, __ATOMIC_ACQUIRE);
        if (t == 0) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!stk_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &hdr->top, FUTEX_WAIT, 0, pts, NULL, 0);
        }
        __atomic_sub_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELAXED);
        if (stk_try_pop(h, out)) return 1;
        if (has_dl && !stk_remaining(&dl, &rem)) {
            __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }
}

/* ================================================================
 * Peek / Status
 * ================================================================ */

static inline int stk_peek(StkHandle *h, void *out) {
    uint32_t t = __atomic_load_n(&h->hdr->top, __ATOMIC_ACQUIRE);
    if (t == 0) return 0;
    memcpy(out, stk_slot(h, t - 1), h->elem_size);
    return 1;
}

static inline uint32_t stk_size(StkHandle *h) {
    return __atomic_load_n(&h->hdr->top, __ATOMIC_RELAXED);
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define STK_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, STK_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static inline void stk_init_header(void *base, uint64_t total,
                                    uint32_t elem_size, uint32_t variant_id,
                                    uint64_t capacity) {
    StkHeader *hdr = (StkHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic      = STK_MAGIC;
    hdr->version    = STK_VERSION;
    hdr->elem_size  = elem_size;
    hdr->variant_id = variant_id;
    hdr->capacity   = capacity;
    hdr->total_size = total;
    hdr->data_off   = sizeof(StkHeader);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline StkHandle *stk_setup(void *base, size_t msize,
                                    const char *path, int bfd) {
    StkHeader *hdr = (StkHeader *)base;
    StkHandle *h = (StkHandle *)calloc(1, sizeof(StkHandle));
    if (!h) { munmap(base, msize); return NULL; }
    h->hdr        = hdr;
    h->data       = (uint8_t *)base + hdr->data_off;
    h->mmap_size  = msize;
    h->elem_size  = hdr->elem_size;  /* cached — safe from shared-mem tampering */
    h->path       = path ? strdup(path) : NULL;
    h->notify_fd  = -1;
    h->backing_fd = bfd;
    return h;
}

static StkHandle *stk_create(const char *path, uint64_t capacity,
                              uint32_t elem_size, uint32_t variant_id,
                              char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { STK_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { STK_ERR("elem_size must be > 0"); return NULL; }
    if (elem_size > 0 && capacity > (UINT64_MAX - sizeof(StkHeader)) / elem_size) {
        STK_ERR("capacity * elem_size overflow"); return NULL;
    }

    uint64_t total = sizeof(StkHeader) + capacity * elem_size;
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE,
                     MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { STK_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { STK_ERR("open(%s): %s", path, strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { STK_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }

        struct stat st;
        if (fstat(fd, &st) < 0) {
            STK_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        int is_new = (st.st_size == 0);

        if (is_new) {
            if (ftruncate(fd, (off_t)total) < 0) {
                STK_ERR("ftruncate: %s", strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { STK_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }

        if (!is_new) {
            StkHeader *hdr = (StkHeader *)base;
            if (hdr->magic != STK_MAGIC || hdr->version != STK_VERSION ||
                hdr->variant_id != variant_id ||
                hdr->total_size != (uint64_t)st.st_size) {
                STK_ERR("invalid or incompatible stack file");
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return stk_setup(base, map_size, path, -1);
        }
    }

    stk_init_header(base, total, elem_size, variant_id, capacity);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return stk_setup(base, map_size, path, -1);
}

static StkHandle *stk_create_memfd(const char *name, uint64_t capacity,
                                    uint32_t elem_size, uint32_t variant_id,
                                    char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { STK_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { STK_ERR("elem_size must be > 0"); return NULL; }
    if (elem_size > 0 && capacity > (UINT64_MAX - sizeof(StkHeader)) / elem_size) {
        STK_ERR("capacity * elem_size overflow"); return NULL;
    }

    uint64_t total = sizeof(StkHeader) + capacity * elem_size;
    int fd = memfd_create(name ? name : "stack", MFD_CLOEXEC);
    if (fd < 0) { STK_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) { STK_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL; }
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { STK_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    stk_init_header(base, total, elem_size, variant_id, capacity);
    return stk_setup(base, (size_t)total, NULL, fd);
}

static StkHandle *stk_open_fd(int fd, uint32_t variant_id, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { STK_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(StkHeader)) { STK_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { STK_ERR("mmap: %s", strerror(errno)); return NULL; }
    StkHeader *hdr = (StkHeader *)base;
    if (hdr->magic != STK_MAGIC || hdr->version != STK_VERSION ||
        hdr->variant_id != variant_id ||
        hdr->total_size != (uint64_t)st.st_size) {
        STK_ERR("invalid stack"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { STK_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return stk_setup(base, ms, NULL, myfd);
}

static void stk_destroy(StkHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

/* NOT concurrency-safe — use drain() for concurrent scenarios */
static void stk_clear(StkHandle *h) {
    __atomic_store_n(&h->hdr->top, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&h->hdr->waiters_push, __ATOMIC_RELAXED) > 0 ||
        __atomic_load_n(&h->hdr->waiters_pop, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &h->hdr->top, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* Concurrency-safe drain: CAS top to 0, returns count drained */
static inline uint32_t stk_drain(StkHandle *h) {
    StkHeader *hdr = h->hdr;
    for (;;) {
        uint32_t t = __atomic_load_n(&hdr->top, __ATOMIC_RELAXED);
        if (t == 0) return 0;
        if (__atomic_compare_exchange_n(&hdr->top, &t, 0,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->top, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            return t;
        }
    }
}

/* eventfd */
static int stk_create_eventfd(StkHandle *h) {
    if (h->notify_fd >= 0) close(h->notify_fd);
    int efd = eventfd(0, EFD_NONBLOCK|EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd;
    return efd;
}
static int stk_notify(StkHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t v = 1;
    return write(h->notify_fd, &v, sizeof(v)) == sizeof(v);
}
static int64_t stk_eventfd_consume(StkHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t v = 0;
    if (read(h->notify_fd, &v, sizeof(v)) != sizeof(v)) return -1;
    return (int64_t)v;
}
static void stk_msync(StkHandle *h) { msync(h->hdr, h->mmap_size, MS_SYNC); }

#endif /* STACK_H */
