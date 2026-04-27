/*
 * deque.h -- Fixed-size shared-memory double-ended queue for Linux
 *
 * Ring buffer with CAS-based push/pop at both ends, plus a per-slot
 * publication state machine for MPMC safety:
 *
 *   EMPTY  -> WRITING  (pusher claims slot)
 *   WRITING-> FILLED   (pusher publishes value)
 *   FILLED -> READING  (popper claims slot)
 *   READING-> EMPTY    (popper releases, generation bumps)
 *
 * The slot's ctl word encodes (generation << 2) | state_bits, and
 * transitions are made via CAS. Head/tail still serialize the POSITION
 * handout; the per-slot state machine serializes the VALUE handoff.
 * A consumer that wins the head/tail CAS always waits for the matching
 * publisher's transition to FILLED before reading.
 *
 * Futex blocking when empty or full.
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

#define DEQ_MAGIC       0x44455132U  /* "DEQ2" — v2 layout (per-slot ctl) */
#define DEQ_VERSION     2
#define DEQ_ERR_BUFLEN  256

#define DEQ_VAR_INT   0
#define DEQ_VAR_STR   1

/* Slot state (low 2 bits of ctl word). Upper 62 bits = generation. */
#define DEQ_SLOT_EMPTY    0u
#define DEQ_SLOT_WRITING  1u
#define DEQ_SLOT_FILLED   2u
#define DEQ_SLOT_READING  3u
#define DEQ_SLOT_STATE_MASK  3u
#define DEQ_SLOT_STATE(c)    ((uint32_t)((c) & DEQ_SLOT_STATE_MASK))
#define DEQ_SLOT_GEN(c)      ((c) >> 2)

/* Combined cursor: upper 32 bits = head, lower 32 bits = tail. A single
 * 64-bit CAS atomically updates both ends, so push_front vs push_back (or
 * pop_front vs pop_back) cannot both succeed when they share a boundary
 * slot. Capacity is bounded by 2^31 elements. Head and tail wrap mod 2^32
 * after 4B ops; size = (tail - head) treated as uint32.
 */
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

    uint64_t cursor;           /* 64: (head<<32)|tail */
    uint32_t waiters_push;     /* 72 */
    uint32_t waiters_pop;      /* 76 */
    uint64_t stat_pushes;      /* 80 */
    uint64_t stat_pops;        /* 88 */
    uint64_t stat_waits;       /* 96 */
    uint64_t stat_timeouts;    /* 104 */
    uint32_t push_wake_seq;    /* 112: bumped by every pop, futex word for pushers */
    uint32_t pop_wake_seq;     /* 116: bumped by every push, futex word for poppers */
    uint8_t  _pad1[8];         /* 120-127 */
} DeqHeader;

#define DEQ_CURSOR(head, tail)  (((uint64_t)(head) << 32) | (uint32_t)(tail))
#define DEQ_CURSOR_HEAD(c)      ((uint32_t)((c) >> 32))
#define DEQ_CURSOR_TAIL(c)      ((uint32_t)(c))
#define DEQ_CURSOR_SIZE(c)      ((uint32_t)(DEQ_CURSOR_TAIL(c) - DEQ_CURSOR_HEAD(c)))

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(DeqHeader) == 128, "DeqHeader must be 128 bytes");
#endif

typedef struct {
    DeqHeader *hdr;
    uint8_t   *data;
    uint64_t  *ctl;            /* per-slot state+generation word */
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

static inline uint8_t *deq_slot(DeqHandle *h, uint32_t idx) {
    return h->data + (idx % (uint32_t)h->hdr->capacity) * h->elem_size;
}

static inline uint32_t deq_size(DeqHandle *h) {
    uint64_t c = __atomic_load_n(&h->hdr->cursor, __ATOMIC_ACQUIRE);
    return DEQ_CURSOR_SIZE(c);
}

static inline void deq_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#endif
}

/* --- per-slot state machine helpers ---
 * Claim a slot for writing: spin CAS until we observe EMPTY and can mark
 * WRITING. Returns the generation that was observed, for the matching
 * publish.  Caller holds the position CAS so at most one pusher targets
 * this slot, but a pending popper from the previous cycle may still be
 * finishing; the spin is bounded by that popper's READING -> EMPTY store.
 */
static inline uint64_t deq_slot_claim_write(uint64_t *ctl_word) {
    for (;;) {
        uint64_t c = __atomic_load_n(ctl_word, __ATOMIC_ACQUIRE);
        if (DEQ_SLOT_STATE(c) == DEQ_SLOT_EMPTY) {
            uint64_t nc = (DEQ_SLOT_GEN(c) << 2) | DEQ_SLOT_WRITING;
            if (__atomic_compare_exchange_n(ctl_word, &c, nc,
                    0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return DEQ_SLOT_GEN(c);
        }
        deq_spin_pause();
    }
}

/* Publish written value: WRITING -> FILLED at same generation. */
static inline void deq_slot_publish(uint64_t *ctl_word, uint64_t gen) {
    __atomic_store_n(ctl_word, (gen << 2) | DEQ_SLOT_FILLED, __ATOMIC_RELEASE);
}

/* Claim a slot for reading: spin CAS until we observe FILLED and mark READING. */
static inline uint64_t deq_slot_claim_read(uint64_t *ctl_word) {
    for (;;) {
        uint64_t c = __atomic_load_n(ctl_word, __ATOMIC_ACQUIRE);
        if (DEQ_SLOT_STATE(c) == DEQ_SLOT_FILLED) {
            uint64_t nc = (DEQ_SLOT_GEN(c) << 2) | DEQ_SLOT_READING;
            if (__atomic_compare_exchange_n(ctl_word, &c, nc,
                    0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return DEQ_SLOT_GEN(c);
        }
        deq_spin_pause();
    }
}

/* Release slot after read: READING -> EMPTY with gen+1. */
static inline void deq_slot_release(uint64_t *ctl_word, uint64_t gen) {
    __atomic_store_n(ctl_word, ((gen + 1) << 2) | DEQ_SLOT_EMPTY, __ATOMIC_RELEASE);
}

/* ================================================================
 * Push back (tail++)
 * ================================================================ */

static inline int deq_try_push_back(DeqHandle *h, const void *val, uint32_t vlen) {
    DeqHeader *hdr = h->hdr;
    uint32_t cap = (uint32_t)hdr->capacity;
    for (;;) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        if ((uint32_t)(t - hd) >= cap) return 0;
        uint64_t nc = DEQ_CURSOR(hd, t + 1);
        if (__atomic_compare_exchange_n(&hdr->cursor, &c, nc,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint32_t sz = h->elem_size;
            uint32_t cp = vlen < sz ? vlen : sz;
            uint32_t idx = t % cap;
            uint64_t gen = deq_slot_claim_write(&h->ctl[idx]);
            memcpy(deq_slot(h, t), val, cp);
            if (cp < sz) memset(deq_slot(h, t) + cp, 0, sz - cp);
            deq_slot_publish(&h->ctl[idx], gen);
            __atomic_add_fetch(&hdr->stat_pushes, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_pop, __ATOMIC_RELAXED) > 0) {
                __atomic_add_fetch(&hdr->pop_wake_seq, 1, __ATOMIC_RELEASE);
                syscall(SYS_futex, &hdr->pop_wake_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
            }
            return 1;
        }
    }
}

/* ================================================================
 * Push front (head--)
 * ================================================================ */

static inline int deq_try_push_front(DeqHandle *h, const void *val, uint32_t vlen) {
    DeqHeader *hdr = h->hdr;
    uint32_t cap = (uint32_t)hdr->capacity;
    for (;;) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        if ((uint32_t)(t - hd) >= cap) return 0;
        uint32_t new_hd = hd - 1;
        uint64_t nc = DEQ_CURSOR(new_hd, t);
        if (__atomic_compare_exchange_n(&hdr->cursor, &c, nc,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint32_t sz = h->elem_size;
            uint32_t cp = vlen < sz ? vlen : sz;
            uint32_t idx = new_hd % cap;
            uint64_t gen = deq_slot_claim_write(&h->ctl[idx]);
            memcpy(deq_slot(h, new_hd), val, cp);
            if (cp < sz) memset(deq_slot(h, new_hd) + cp, 0, sz - cp);
            deq_slot_publish(&h->ctl[idx], gen);
            __atomic_add_fetch(&hdr->stat_pushes, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_pop, __ATOMIC_RELAXED) > 0) {
                __atomic_add_fetch(&hdr->pop_wake_seq, 1, __ATOMIC_RELEASE);
                syscall(SYS_futex, &hdr->pop_wake_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
            }
            return 1;
        }
    }
}

/* ================================================================
 * Pop front (head++)
 * ================================================================ */

static inline int deq_try_pop_front(DeqHandle *h, void *out) {
    DeqHeader *hdr = h->hdr;
    uint32_t cap = (uint32_t)hdr->capacity;
    for (;;) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        if ((uint32_t)(t - hd) == 0) return 0;
        uint64_t nc = DEQ_CURSOR(hd + 1, t);
        if (__atomic_compare_exchange_n(&hdr->cursor, &c, nc,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint32_t idx = hd % cap;
            uint64_t gen = deq_slot_claim_read(&h->ctl[idx]);
            memcpy(out, deq_slot(h, hd), h->elem_size);
            deq_slot_release(&h->ctl[idx], gen);
            __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0) {
                __atomic_add_fetch(&hdr->push_wake_seq, 1, __ATOMIC_RELEASE);
                syscall(SYS_futex, &hdr->push_wake_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
            }
            return 1;
        }
    }
}

/* ================================================================
 * Pop back (tail--)
 * ================================================================ */

static inline int deq_try_pop_back(DeqHandle *h, void *out) {
    DeqHeader *hdr = h->hdr;
    uint32_t cap = (uint32_t)hdr->capacity;
    for (;;) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        if ((uint32_t)(t - hd) == 0) return 0;
        uint64_t nc = DEQ_CURSOR(hd, t - 1);
        if (__atomic_compare_exchange_n(&hdr->cursor, &c, nc,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint32_t idx = (t - 1) % cap;
            uint64_t gen = deq_slot_claim_read(&h->ctl[idx]);
            memcpy(out, deq_slot(h, t - 1), h->elem_size);
            deq_slot_release(&h->ctl[idx], gen);
            __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0) {
                __atomic_add_fetch(&hdr->push_wake_seq, 1, __ATOMIC_RELEASE);
                syscall(SYS_futex, &hdr->push_wake_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
            }
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

    uint32_t cap = (uint32_t)hdr->capacity;
    for (;;) {
        uint32_t wseq = __atomic_load_n(&hdr->push_wake_seq, __ATOMIC_ACQUIRE);
        __atomic_add_fetch(&hdr->waiters_push, 1, __ATOMIC_RELEASE);
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        if (DEQ_CURSOR_SIZE(c) >= cap) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!deq_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&hdr->waiters_push, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &hdr->push_wake_seq, FUTEX_WAIT, wseq, pts, NULL, 0);
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
        uint32_t wseq = __atomic_load_n(&hdr->pop_wake_seq, __ATOMIC_ACQUIRE);
        __atomic_add_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELEASE);
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        if (DEQ_CURSOR_SIZE(c) == 0) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!deq_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &hdr->pop_wake_seq, FUTEX_WAIT, wseq, pts, NULL, 0);
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

/* Layout offsets — data array first, then 8-byte-aligned ctl array. */
static inline uint64_t deq_ctl_offset(uint32_t elem_size, uint64_t capacity) {
    uint64_t data_end = sizeof(DeqHeader) + capacity * elem_size;
    return (data_end + 7u) & ~(uint64_t)7u;
}

static inline uint64_t deq_total_size(uint32_t elem_size, uint64_t capacity) {
    return deq_ctl_offset(elem_size, capacity) + capacity * sizeof(uint64_t);
}

static inline void deq_init_header(void *base, uint64_t total,
                                    uint32_t elem_size, uint32_t variant_id,
                                    uint64_t capacity) {
    DeqHeader *hdr = (DeqHeader *)base;
    memset(base, 0, (size_t)total);  /* zeroes data + ctl → all slots EMPTY, gen=0 */
    hdr->magic      = DEQ_MAGIC;
    hdr->version    = DEQ_VERSION;
    hdr->elem_size  = elem_size;
    hdr->variant_id = variant_id;
    hdr->capacity   = capacity;
    hdr->total_size = total;
    hdr->data_off   = sizeof(DeqHeader);
    hdr->ctl_off    = deq_ctl_offset(elem_size, capacity);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline DeqHandle *deq_setup(void *base, size_t ms, const char *path, int bfd) {
    DeqHeader *hdr = (DeqHeader *)base;
    DeqHandle *h = (DeqHandle *)calloc(1, sizeof(DeqHandle));
    if (!h) { munmap(base, ms); return NULL; }
    h->hdr = hdr;
    h->data = (uint8_t *)base + hdr->data_off;
    h->ctl  = (uint64_t *)((uint8_t *)base + hdr->ctl_off);
    h->mmap_size = ms;
    h->elem_size = hdr->elem_size;
    h->path = path ? strdup(path) : NULL;
    h->notify_fd = -1;
    h->backing_fd = bfd;
    return h;
}

/* Validate a mapped header (shared by deq_create reopen and deq_open_fd). */
static inline int deq_validate_header(const DeqHeader *hdr, uint64_t file_size,
                                       uint32_t expected_variant) {
    if (hdr->magic != DEQ_MAGIC) return 0;
    if (hdr->version != DEQ_VERSION) return 0;
    if (hdr->variant_id != expected_variant) return 0;
    if (hdr->elem_size == 0 || hdr->capacity == 0) return 0;
    if (hdr->capacity > 0x7FFFFFFFu) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->data_off != sizeof(DeqHeader)) return 0;
    if (hdr->ctl_off != deq_ctl_offset(hdr->elem_size, hdr->capacity)) return 0;
    if (hdr->total_size != deq_total_size(hdr->elem_size, hdr->capacity)) return 0;
    return 1;
}

static DeqHandle *deq_create(const char *path, uint64_t capacity,
                              uint32_t elem_size, uint32_t variant_id,
                              char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { DEQ_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { DEQ_ERR("elem_size must be > 0"); return NULL; }
    if (capacity > 0x7FFFFFFFu) {
        DEQ_ERR("capacity must be <= 2^31 (32-bit cursor halves)"); return NULL;
    }

    uint64_t total = deq_total_size(elem_size, capacity);
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
        if (!is_new && (uint64_t)st.st_size < sizeof(DeqHeader)) {
            DEQ_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            DEQ_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { DEQ_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!deq_validate_header((DeqHeader *)base, (uint64_t)st.st_size, variant_id)) {
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
    if (capacity > 0x7FFFFFFFu) {
        DEQ_ERR("capacity must be <= 2^31 (32-bit cursor halves)"); return NULL;
    }
    uint64_t total = deq_total_size(elem_size, capacity);
    int fd = memfd_create(name ? name : "deque", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { DEQ_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) { DEQ_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL; }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
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
    if (!deq_validate_header((DeqHeader *)base, (uint64_t)st.st_size, variant_id)) {
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
    __atomic_store_n(&h->hdr->cursor, 0, __ATOMIC_RELEASE);
    /* Reset all slot ctl to {EMPTY, gen=0}. Safe only when no concurrent
     * push/pop — which is the documented contract of clear(). */
    memset(h->ctl, 0, (size_t)h->hdr->capacity * sizeof(uint64_t));
    /* clear() frees the entire deque at once — wake all waiters so they
     * can re-evaluate state, not just one. */
    if (__atomic_load_n(&h->hdr->waiters_push, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&h->hdr->push_wake_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->push_wake_seq, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    }
    if (__atomic_load_n(&h->hdr->waiters_pop, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&h->hdr->pop_wake_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->pop_wake_seq, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    }
}

/* Concurrency-safe drain: CAS cursor to advance head to tail, then release
 * each drained slot through the state machine so future pushes can reuse. */
static inline uint32_t deq_drain(DeqHandle *h) {
    DeqHeader *hdr = h->hdr;
    uint32_t cap = (uint32_t)hdr->capacity;
    for (;;) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        uint32_t count = (uint32_t)(t - hd);
        if (count == 0) return 0;
        uint64_t nc = DEQ_CURSOR(t, t);
        if (__atomic_compare_exchange_n(&hdr->cursor, &c, nc,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            for (uint32_t i = 0; i < count; i++) {
                uint32_t idx = (hd + i) % cap;
                uint64_t gen = deq_slot_claim_read(&h->ctl[idx]);
                deq_slot_release(&h->ctl[idx], gen);
            }
            /* drain freed `count` slots at once — wake up to that many. */
            if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0) {
                __atomic_add_fetch(&hdr->push_wake_seq, 1, __ATOMIC_RELEASE);
                syscall(SYS_futex, &hdr->push_wake_seq, FUTEX_WAKE,
                        (int)count, NULL, NULL, 0);
            }
            return count;
        }
    }
}

static int deq_create_eventfd(DeqHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
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
static int deq_msync(DeqHandle *h) { return msync(h->hdr, h->mmap_size, MS_SYNC); }

#endif /* DEQUE_H */
