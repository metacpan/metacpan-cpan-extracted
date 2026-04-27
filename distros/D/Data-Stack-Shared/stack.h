/*
 * stack.h -- Fixed-size shared-memory LIFO stack for Linux
 *
 * CAS-based position handout (top) with per-slot publication state
 * machine (EMPTY -> WRITING -> FILLED -> READING -> EMPTY, generation
 * bumped on release). The state machine closes the race between a
 * position CAS and the corresponding slot write/read under MPMC.
 * Futex blocking via push/pop_wake_seq when empty (pop) or full (push).
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

#define STK_MAGIC       0x53544B32U  /* "STK2" — v2 layout (per-slot ctl) */
#define STK_VERSION     2
#define STK_ERR_BUFLEN  256

#define STK_VAR_INT   0
#define STK_VAR_STR   1

/* Slot state (low 2 bits of ctl word). Upper 62 bits = generation. */
#define STK_SLOT_EMPTY    0u
#define STK_SLOT_WRITING  1u
#define STK_SLOT_FILLED   2u
#define STK_SLOT_READING  3u
#define STK_SLOT_STATE_MASK  3u
#define STK_SLOT_STATE(c)    ((uint32_t)((c) & STK_SLOT_STATE_MASK))
#define STK_SLOT_GEN(c)      ((c) >> 2)

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
    uint64_t ctl_off;          /* offset to per-slot ctl array */
    uint8_t  _pad0[16];

    uint32_t top;              /* 64: next free index (0=empty, capacity=full) */
    uint32_t waiters_push;     /* 68 */
    uint32_t waiters_pop;      /* 72 */
    uint32_t push_wake_seq;    /* 76: bumped by every pop, futex word for pushers */
    uint32_t pop_wake_seq;     /* 80: bumped by every push, futex word for poppers */
    uint32_t _pad1;            /* 84 */
    uint64_t stat_pushes;      /* 88 */
    uint64_t stat_pops;        /* 96 */
    uint64_t stat_waits;       /* 104 */
    uint64_t stat_timeouts;    /* 112 */
    uint8_t  _pad2[8];         /* 120-127 */
} StkHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(StkHeader) == 128, "StkHeader must be 128 bytes");
#endif

typedef struct {
    StkHeader *hdr;
    uint8_t   *data;
    uint64_t  *ctl;            /* per-slot state+generation word */
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

static inline void stk_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#endif
}

/* Slot state machine — same pattern as Data::Deque::Shared. */
static inline uint64_t stk_slot_claim_write(uint64_t *ctl_word) {
    for (;;) {
        uint64_t c = __atomic_load_n(ctl_word, __ATOMIC_ACQUIRE);
        if (STK_SLOT_STATE(c) == STK_SLOT_EMPTY) {
            uint64_t nc = (STK_SLOT_GEN(c) << 2) | STK_SLOT_WRITING;
            if (__atomic_compare_exchange_n(ctl_word, &c, nc,
                    0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return STK_SLOT_GEN(c);
        }
        stk_spin_pause();
    }
}

static inline void stk_slot_publish(uint64_t *ctl_word, uint64_t gen) {
    __atomic_store_n(ctl_word, (gen << 2) | STK_SLOT_FILLED, __ATOMIC_RELEASE);
}

static inline uint64_t stk_slot_claim_read(uint64_t *ctl_word) {
    for (;;) {
        uint64_t c = __atomic_load_n(ctl_word, __ATOMIC_ACQUIRE);
        if (STK_SLOT_STATE(c) == STK_SLOT_FILLED) {
            uint64_t nc = (STK_SLOT_GEN(c) << 2) | STK_SLOT_READING;
            if (__atomic_compare_exchange_n(ctl_word, &c, nc,
                    0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return STK_SLOT_GEN(c);
        }
        stk_spin_pause();
    }
}

static inline void stk_slot_release(uint64_t *ctl_word, uint64_t gen) {
    __atomic_store_n(ctl_word, ((gen + 1) << 2) | STK_SLOT_EMPTY, __ATOMIC_RELEASE);
}

/* ================================================================
 * Push (LIFO top++)
 * ================================================================ */

static inline int stk_try_push(StkHandle *h, const void *val, uint32_t vlen) {
    StkHeader *hdr = h->hdr;
    uint32_t cap = (uint32_t)hdr->capacity;
    for (;;) {
        uint32_t t = __atomic_load_n(&hdr->top, __ATOMIC_RELAXED);
        if (t >= cap) return 0;
        if (__atomic_compare_exchange_n(&hdr->top, &t, t + 1,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint32_t sz = h->elem_size;
            uint32_t cp = vlen < sz ? vlen : sz;
            uint64_t gen = stk_slot_claim_write(&h->ctl[t]);
            memcpy(stk_slot(h, t), val, cp);
            if (cp < sz) memset(stk_slot(h, t) + cp, 0, sz - cp);
            stk_slot_publish(&h->ctl[t], gen);
            __atomic_add_fetch(&hdr->stat_pushes, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_pop, __ATOMIC_RELAXED) > 0) {
                __atomic_add_fetch(&hdr->pop_wake_seq, 1, __ATOMIC_RELEASE);
                syscall(SYS_futex, &hdr->pop_wake_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
            }
            return 1;
        }
    }
}

static inline int stk_push(StkHandle *h, const void *val, uint32_t vlen, double timeout) {
    if (stk_try_push(h, val, vlen)) return 1;
    if (timeout == 0) return 0;

    StkHeader *hdr = h->hdr;
    uint32_t cap = (uint32_t)hdr->capacity;
    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) stk_make_deadline(timeout, &dl);
    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        uint32_t wseq = __atomic_load_n(&hdr->push_wake_seq, __ATOMIC_ACQUIRE);
        __atomic_add_fetch(&hdr->waiters_push, 1, __ATOMIC_RELEASE);
        uint32_t t = __atomic_load_n(&hdr->top, __ATOMIC_ACQUIRE);
        if (t >= cap) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!stk_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&hdr->waiters_push, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &hdr->push_wake_seq, FUTEX_WAIT, wseq, pts, NULL, 0);
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
 * Pop (LIFO top--)
 * ================================================================ */

static inline int stk_try_pop(StkHandle *h, void *out) {
    StkHeader *hdr = h->hdr;
    for (;;) {
        uint32_t t = __atomic_load_n(&hdr->top, __ATOMIC_ACQUIRE);
        if (t == 0) return 0;
        if (__atomic_compare_exchange_n(&hdr->top, &t, t - 1,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint64_t gen = stk_slot_claim_read(&h->ctl[t - 1]);
            memcpy(out, stk_slot(h, t - 1), h->elem_size);
            stk_slot_release(&h->ctl[t - 1], gen);
            __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0) {
                __atomic_add_fetch(&hdr->push_wake_seq, 1, __ATOMIC_RELEASE);
                syscall(SYS_futex, &hdr->push_wake_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
            }
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
        uint32_t wseq = __atomic_load_n(&hdr->pop_wake_seq, __ATOMIC_ACQUIRE);
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
            syscall(SYS_futex, &hdr->pop_wake_seq, FUTEX_WAIT, wseq, pts, NULL, 0);
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

/* Best-effort peek: seqlock-style retry against slot ctl. Returns 0 if
 * empty OR if the top is mutating concurrently after the retry budget.
 * Under no contention this is a single load. */
static inline int stk_peek(StkHandle *h, void *out) {
    for (int tries = 0; tries < 64; tries++) {
        uint32_t t = __atomic_load_n(&h->hdr->top, __ATOMIC_ACQUIRE);
        if (t == 0) return 0;
        uint64_t c1 = __atomic_load_n(&h->ctl[t - 1], __ATOMIC_ACQUIRE);
        if (STK_SLOT_STATE(c1) != STK_SLOT_FILLED) {
            stk_spin_pause();
            continue;
        }
        memcpy(out, stk_slot(h, t - 1), h->elem_size);
        uint64_t c2 = __atomic_load_n(&h->ctl[t - 1], __ATOMIC_ACQUIRE);
        uint32_t t2 = __atomic_load_n(&h->hdr->top, __ATOMIC_ACQUIRE);
        if (c1 == c2 && t == t2) return 1;
    }
    return 0;
}

static inline uint32_t stk_size(StkHandle *h) {
    return __atomic_load_n(&h->hdr->top, __ATOMIC_RELAXED);
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define STK_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, STK_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static inline uint64_t stk_ctl_offset(uint32_t elem_size, uint64_t capacity) {
    uint64_t data_end = sizeof(StkHeader) + capacity * elem_size;
    return (data_end + 7u) & ~(uint64_t)7u;
}

static inline uint64_t stk_total_size(uint32_t elem_size, uint64_t capacity) {
    return stk_ctl_offset(elem_size, capacity) + capacity * sizeof(uint64_t);
}

static inline void stk_init_header(void *base, uint64_t total,
                                    uint32_t elem_size, uint32_t variant_id,
                                    uint64_t capacity) {
    StkHeader *hdr = (StkHeader *)base;
    memset(base, 0, (size_t)total);  /* zeroes ctl array → all slots EMPTY, gen=0 */
    hdr->magic      = STK_MAGIC;
    hdr->version    = STK_VERSION;
    hdr->elem_size  = elem_size;
    hdr->variant_id = variant_id;
    hdr->capacity   = capacity;
    hdr->total_size = total;
    hdr->data_off   = sizeof(StkHeader);
    hdr->ctl_off    = stk_ctl_offset(elem_size, capacity);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline StkHandle *stk_setup(void *base, size_t msize,
                                    const char *path, int bfd) {
    StkHeader *hdr = (StkHeader *)base;
    StkHandle *h = (StkHandle *)calloc(1, sizeof(StkHandle));
    if (!h) { munmap(base, msize); return NULL; }
    h->hdr        = hdr;
    h->data       = (uint8_t *)base + hdr->data_off;
    h->ctl        = (uint64_t *)((uint8_t *)base + hdr->ctl_off);
    h->mmap_size  = msize;
    h->elem_size  = hdr->elem_size;  /* cached — safe from shared-mem tampering */
    h->path       = path ? strdup(path) : NULL;
    h->notify_fd  = -1;
    h->backing_fd = bfd;
    return h;
}

/* Validate a mapped header (shared by stk_create reopen and stk_open_fd). */
static inline int stk_validate_header(const StkHeader *hdr, uint64_t file_size,
                                       uint32_t expected_variant) {
    if (hdr->magic != STK_MAGIC) return 0;
    if (hdr->version != STK_VERSION) return 0;
    if (hdr->variant_id != expected_variant) return 0;
    if (hdr->elem_size == 0 || hdr->capacity == 0) return 0;
    if (hdr->capacity > 0x7FFFFFFFu) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->data_off != sizeof(StkHeader)) return 0;
    if (hdr->ctl_off != stk_ctl_offset(hdr->elem_size, hdr->capacity)) return 0;
    if (hdr->total_size != stk_total_size(hdr->elem_size, hdr->capacity)) return 0;
    return 1;
}

static StkHandle *stk_create(const char *path, uint64_t capacity,
                              uint32_t elem_size, uint32_t variant_id,
                              char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { STK_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { STK_ERR("elem_size must be > 0"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(StkHeader) - 16) / (elem_size + sizeof(uint64_t))) {
        STK_ERR("capacity * elem_size overflow"); return NULL;
    }

    uint64_t total = stk_total_size(elem_size, capacity);
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
        if (!is_new && (uint64_t)st.st_size < sizeof(StkHeader)) {
            STK_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

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
            if (!stk_validate_header((StkHeader *)base, (uint64_t)st.st_size, variant_id)) {
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
    if (capacity > (UINT64_MAX - sizeof(StkHeader) - 16) / (elem_size + sizeof(uint64_t))) {
        STK_ERR("capacity * elem_size overflow"); return NULL;
    }

    uint64_t total = stk_total_size(elem_size, capacity);
    int fd = memfd_create(name ? name : "stack", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { STK_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) { STK_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL; }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
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
    if (!stk_validate_header((StkHeader *)base, (uint64_t)st.st_size, variant_id)) {
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
    memset(h->ctl, 0, (size_t)h->hdr->capacity * sizeof(uint64_t));
    /* clear() frees the entire stack at once — wake all waiters. */
    if (__atomic_load_n(&h->hdr->waiters_push, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&h->hdr->push_wake_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->push_wake_seq, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    }
    if (__atomic_load_n(&h->hdr->waiters_pop, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&h->hdr->pop_wake_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->pop_wake_seq, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    }
}

/* Concurrency-safe drain: atomically swap top to 0, then release each
 * drained slot through the state machine. Returns count drained. */
static inline uint32_t stk_drain(StkHandle *h) {
    StkHeader *hdr = h->hdr;
    uint32_t t = __atomic_exchange_n(&hdr->top, 0, __ATOMIC_ACQ_REL);
    if (t == 0) return 0;
    for (uint32_t i = 0; i < t; i++) {
        uint64_t gen = stk_slot_claim_read(&h->ctl[i]);
        stk_slot_release(&h->ctl[i], gen);
    }
    /* drain freed `t` slots at once — wake up to that many. */
    if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->push_wake_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->push_wake_seq, FUTEX_WAKE,
                t < INT_MAX ? (int)t : INT_MAX, NULL, NULL, 0);
    }
    return t;
}

/* eventfd */
static int stk_create_eventfd(StkHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
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
static int stk_msync(StkHandle *h) { return msync(h->hdr, h->mmap_size, MS_SYNC); }

#endif /* STACK_H */
