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

#define DEQ_MAGIC       0x44455132U  /* "DEQ2" -- v2 layout (per-slot ctl) */
#define DEQ_VERSION     2
#define DEQ_ERR_BUFLEN  256

/* Drain-time recovery: how long to wait for a slot stuck in WRITING before
 * declaring its pusher dead and force-skipping. Matches the slot-stuck
 * recovery timeout used in sister Data-*-Shared modules (e.g. Stack). */
#define DEQ_DRAIN_RECOVERY_SEC  2

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
    uint64_t stat_recoveries;  /* 120: drain-time recovery of stuck slots (WRITING or EMPTY) */
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
    uint32_t   capacity;       /* cached-at-attach ring size (fixed geometry) */
    char      *path;
    int        notify_fd;
    int        backing_fd;
} DeqHandle;

/* ================================================================ */

static inline void deq_make_deadline(double t, struct timespec *dl) {
    clock_gettime(CLOCK_MONOTONIC, dl);
    if (!(t < 1e9)) t = 1e9; /* clamp Inf/NaN/huge: avoid UB (time_t) cast -> instant spurious timeout */
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
    return h->data + (size_t)(idx % h->capacity) * h->elem_size;
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
/* Bounded wait for `want`, with abandoned-slot recovery.
 *
 * A peer that died between claiming a slot and publishing/releasing it leaves
 * it stuck in WRITING (crashed pusher) or READING (crashed popper); a drain
 * that force-recovered a slot can likewise orphan a later publish. An unbounded
 * spin here wedges EVERY process using the deque, forever, at 100% CPU.
 * deq_drain already bounds its own wait for exactly this reason; the push/pop
 * fast paths must do the same or one SIGKILL is a permanent cluster-wide DoS.
 *
 * Returns 1 with *out_gen set when the slot was claimed in state `want`;
 * 0 when the slot was abandoned and force-reclaimed to EMPTY@(gen+1).
 *
 * Same false-positive caveat as deq_drain: ctl encodes no PID, so a live peer
 * stalled past the deadline is indistinguishable from a dead one; its later
 * publish is a CAS against the old generation, so it no-ops rather than
 * resurrecting a phantom slot. The claim->publish gap is a sub-microsecond
 * memcpy, many orders of magnitude below the deadline. */
static inline int deq_slot_wait_state(uint64_t *ctl_word, uint32_t want,
                                      uint64_t *out_gen) {
    struct timespec dl;
    int dl_set = 0;
    uint32_t spins = 0;
    for (;;) {
        uint64_t c = __atomic_load_n(ctl_word, __ATOMIC_ACQUIRE);
        if (DEQ_SLOT_STATE(c) == want) {
            uint32_t next = (want == DEQ_SLOT_EMPTY) ? DEQ_SLOT_WRITING : DEQ_SLOT_READING;
            uint64_t nc = (DEQ_SLOT_GEN(c) << 2) | next;
            if (__atomic_compare_exchange_n(ctl_word, &c, nc,
                    0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
                *out_gen = DEQ_SLOT_GEN(c);
                return 1;
            }
            continue;
        }
        deq_spin_pause();
        if ((++spins & 0x3F) == 0) {
            if (!dl_set) { deq_make_deadline((double)DEQ_DRAIN_RECOVERY_SEC, &dl); dl_set = 1; }
            struct timespec rem;
            if (!deq_remaining(&dl, &rem)) {
                uint64_t nc = ((DEQ_SLOT_GEN(c) + 1) << 2) | DEQ_SLOT_EMPTY;
                if (__atomic_compare_exchange_n(ctl_word, &c, nc,
                        0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                    return 0;
                continue;   /* CAS lost: state advanced concurrently -- re-observe */
            }
            struct timespec ts = { 0, 100000L }; /* 100us */
            nanosleep(&ts, NULL);
        }
    }
}

static inline uint64_t deq_slot_claim_write(uint64_t *ctl_word) {
    uint64_t gen;
    /* On recovery the slot is EMPTY at the bumped gen: retry and take it. */
    while (!deq_slot_wait_state(ctl_word, DEQ_SLOT_EMPTY, &gen)) { }
    return gen;
}

/* Publish written value: WRITING@gen -> FILLED@gen. Implemented as CAS
 * (not a plain store) so that if deq_drain force-recovered the slot mid-
 * write -- bumping it to EMPTY@(gen+1) -- this publish is a no-op rather
 * than clobbering the recovered state back to FILLED@gen. That would
 * leave a phantom FILLED at a stale gen which the next pusher's
 * deq_slot_claim_write (waits on EMPTY) could never advance past,
 * deadlocking that slot forever. The caller's cursor CAS was already
 * committed, so on lost-race the value is silently dropped -- matching
 * the documented drain-recovery semantics. */
static inline void deq_slot_publish(uint64_t *ctl_word, uint64_t gen) {
    uint64_t expected = (gen << 2) | DEQ_SLOT_WRITING;
    uint64_t desired  = (gen << 2) | DEQ_SLOT_FILLED;
    (void)__atomic_compare_exchange_n(ctl_word, &expected, desired,
            0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
}

/* Claim a slot for reading: spin CAS until we observe FILLED and mark READING. */
/* Returns 1 and sets *out_gen on success; 0 if the slot was abandoned by a
 * crashed pusher and has been force-reclaimed (no value to read). */
static inline int deq_slot_claim_read(uint64_t *ctl_word, uint64_t *out_gen) {
    return deq_slot_wait_state(ctl_word, DEQ_SLOT_FILLED, out_gen);
}

/* Release slot after read: READING@gen -> EMPTY@gen+1, via CAS not a blind
 * store (a drain force-recovery may have reused the slot; mirror publish-CAS). */
static inline void deq_slot_release(uint64_t *ctl_word, uint64_t gen) {
    uint64_t expected = (gen << 2) | DEQ_SLOT_READING;
    uint64_t desired  = ((gen + 1) << 2) | DEQ_SLOT_EMPTY;
    __atomic_compare_exchange_n(ctl_word, &expected, desired,
            0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
}

/* ================================================================
 * Push back (tail++)
 * ================================================================ */

static inline int deq_try_push_back(DeqHandle *h, const void *val, uint32_t vlen) {
    DeqHeader *hdr = h->hdr;
    uint32_t cap = h->capacity;   /* cached-at-attach geometry, not live hdr */
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
            /* StoreLoad: publish our slot/cursor change before reading waiters. */
            __atomic_thread_fence(__ATOMIC_SEQ_CST);
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
    uint32_t cap = h->capacity;   /* cached-at-attach geometry, not live hdr */
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
            /* StoreLoad: publish our slot/cursor change before reading waiters. */
            __atomic_thread_fence(__ATOMIC_SEQ_CST);
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
    uint32_t cap = h->capacity;   /* cached-at-attach geometry, not live hdr */
    for (;;) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        if ((uint32_t)(t - hd) == 0) return 0;
        uint64_t nc = DEQ_CURSOR(hd + 1, t);
        if (__atomic_compare_exchange_n(&hdr->cursor, &c, nc,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint32_t idx = hd % cap;
            uint64_t gen;
            if (!deq_slot_claim_read(&h->ctl[idx], &gen)) {
                /* Slot was abandoned by a crashed pusher and reclaimed: that
                 * value never existed. The cursor already advanced, so retry
                 * at the next position rather than reporting the deque empty
                 * while entries remain. Terminates: each pass consumes one. */
                continue;
            }
            memcpy(out, deq_slot(h, hd), h->elem_size);
            deq_slot_release(&h->ctl[idx], gen);
            __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
            /* StoreLoad: publish our slot/cursor change before reading waiters. */
            __atomic_thread_fence(__ATOMIC_SEQ_CST);
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
    uint32_t cap = h->capacity;   /* cached-at-attach geometry, not live hdr */
    for (;;) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        if ((uint32_t)(t - hd) == 0) return 0;
        uint64_t nc = DEQ_CURSOR(hd, t - 1);
        if (__atomic_compare_exchange_n(&hdr->cursor, &c, nc,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint32_t idx = (t - 1) % cap;
            uint64_t gen;
            if (!deq_slot_claim_read(&h->ctl[idx], &gen)) {
                /* Abandoned slot reclaimed (see deq_try_pop_front): retry at
                 * the next position instead of reporting the deque empty. */
                continue;
            }
            memcpy(out, deq_slot(h, t - 1), h->elem_size);
            deq_slot_release(&h->ctl[idx], gen);
            __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
            /* StoreLoad: publish our slot/cursor change before reading waiters. */
            __atomic_thread_fence(__ATOMIC_SEQ_CST);
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

    uint32_t cap = h->capacity;   /* cached-at-attach geometry, not live hdr */
    for (;;) {
        uint32_t wseq = __atomic_load_n(&hdr->push_wake_seq, __ATOMIC_ACQUIRE);
        __atomic_add_fetch(&hdr->waiters_push, 1, __ATOMIC_RELEASE);
        /* StoreLoad: publish waiters++ before re-reading the cursor, so a
         * concurrent waker can't read waiters==0 while we read a stale cursor. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
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
        /* StoreLoad: publish waiters++ before re-reading the cursor, so a
         * concurrent waker can't read waiters==0 while we read a stale cursor. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
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

/* Layout offsets -- data array first, then 8-byte-aligned ctl array. */
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
    memset(base, 0, (size_t)total);  /* zeroes data + ctl -> all slots EMPTY, gen=0 */
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

/* Layout fields are passed in by the caller -- either from a validated
 * header snapshot or locally computed -- never re-read from the live
 * mapping, which a hostile peer could rewrite between validation and
 * here (double-fetch TOCTOU). */
static inline DeqHandle *deq_setup(void *base, size_t ms, const char *path, int bfd,
                                    uint64_t data_off, uint64_t ctl_off,
                                    uint32_t elem_size, uint64_t capacity) {
    DeqHandle *h = (DeqHandle *)calloc(1, sizeof(DeqHandle));
    if (!h) { munmap(base, ms); if (bfd >= 0) close(bfd); return NULL; }
    h->hdr = (DeqHeader *)base;
    h->data = (uint8_t *)base + data_off;
    h->ctl  = (uint64_t *)((uint8_t *)base + ctl_off);
    h->mmap_size = ms;
    h->elem_size = elem_size;
    h->capacity  = (uint32_t)capacity;   /* validated <= 2^31 at attach; fixed geometry */
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
    if (hdr->capacity > 0x80000000u) return 0;
    if (hdr->capacity & (hdr->capacity - 1)) return 0;   /* capacity must be a power of two (slot map is idx % capacity) */
    /* Variant-specific elem_size sanity: prevents buffer overflows in the
     * XS push paths if a corrupted/tampered file claims an impossibly-small
     * elem_size (e.g. < 4 for a Str variant where push writes a 4-byte
     * length prefix). */
    if (expected_variant == DEQ_VAR_INT && hdr->elem_size != sizeof(int64_t))
        return 0;
    if (expected_variant == DEQ_VAR_STR && hdr->elem_size < sizeof(uint32_t) + 1)
        return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->data_off != sizeof(DeqHeader)) return 0;
    if (hdr->ctl_off != deq_ctl_offset(hdr->elem_size, hdr->capacity)) return 0;
    if (hdr->total_size != deq_total_size(hdr->elem_size, hdr->capacity)) return 0;
    return 1;
}

/* Ring slots map via idx % capacity on a free-running 32-bit index; that tiles the
   2^32 index space correctly only when capacity divides 2^32, i.e. is a power of two,
   so a non-power-of-2 request would collide slots across the 2^32 wrap seam. Round up. */
static inline uint64_t deq_next_pow2(uint64_t n) {
    if (n <= 1) return 1;
    n--; n |= n >> 1; n |= n >> 2; n |= n >> 4; n |= n >> 8; n |= n >> 16; n |= n >> 32;
    return n + 1;
}

/* Securely obtain a fd for the path-based backing store. Either create it fresh
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents. */
static int deq_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { DEQ_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        DEQ_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    DEQ_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static DeqHandle *deq_create(const char *path, uint64_t capacity,
                              uint32_t elem_size, uint32_t variant_id,
                              mode_t mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { DEQ_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { DEQ_ERR("elem_size must be > 0"); return NULL; }
    capacity = deq_next_pow2(capacity);
    if (capacity == 0 || capacity > 0x80000000u) {
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
        fd = deq_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
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
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            DEQ_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            DEQ_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { DEQ_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            DeqHeader snap;  /* single fetch: validate + setup use one copy */
            memcpy(&snap, base, sizeof snap);
            if (!deq_validate_header(&snap, (uint64_t)st.st_size, variant_id)) {
                DEQ_ERR("invalid deque file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return deq_setup(base, map_size, path, -1,
                             snap.data_off, snap.ctl_off, snap.elem_size, snap.capacity);
        }
    }
    deq_init_header(base, total, elem_size, variant_id, capacity);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return deq_setup(base, map_size, path, -1,
                     sizeof(DeqHeader), deq_ctl_offset(elem_size, capacity),
                     elem_size, capacity);
}

static DeqHandle *deq_create_memfd(const char *name, uint64_t capacity,
                                    uint32_t elem_size, uint32_t variant_id,
                                    char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { DEQ_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { DEQ_ERR("elem_size must be > 0"); return NULL; }
    capacity = deq_next_pow2(capacity);
    if (capacity == 0 || capacity > 0x80000000u) {
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
    return deq_setup(base, (size_t)total, NULL, fd,
                     sizeof(DeqHeader), deq_ctl_offset(elem_size, capacity),
                     elem_size, capacity);
}

static DeqHandle *deq_open_fd(int fd, uint32_t variant_id, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { DEQ_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(DeqHeader)) { DEQ_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { DEQ_ERR("mmap: %s", strerror(errno)); return NULL; }
    DeqHeader snap;  /* single fetch: validate + setup use one copy */
    memcpy(&snap, base, sizeof snap);
    if (!deq_validate_header(&snap, (uint64_t)st.st_size, variant_id)) {
        DEQ_ERR("invalid deque"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { DEQ_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return deq_setup(base, ms, NULL, myfd,
                     snap.data_off, snap.ctl_off, snap.elem_size, snap.capacity);
}

static void deq_destroy(DeqHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

/* NOT concurrency-safe -- use drain() for concurrent scenarios */
static void deq_clear(DeqHandle *h) {
    __atomic_store_n(&h->hdr->cursor, 0, __ATOMIC_RELEASE);
    /* Reset all slot ctl to {EMPTY, gen=0}. Safe only when no concurrent
     * push/pop -- which is the documented contract of clear(). */
    memset(h->ctl, 0, (size_t)h->capacity * sizeof(uint64_t));
    /* clear() frees the entire deque at once -- wake all waiters so they
     * can re-evaluate state, not just one. */
    /* StoreLoad: publish our slot/cursor change before reading waiters. */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&h->hdr->waiters_push, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&h->hdr->push_wake_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->push_wake_seq, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    }
    /* StoreLoad: publish our slot/cursor change before reading waiters. */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&h->hdr->waiters_pop, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&h->hdr->pop_wake_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->pop_wake_seq, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    }
}

/* Concurrency-safe drain: CAS cursor to advance head to tail, then release
 * each drained slot through the state machine so future pushes can reuse.
 *
 * Crash-recovery: a pusher that won the cursor CAS but died (SIGKILL/crash)
 * before completing its write leaves its slot stuck in a non-FILLED state.
 * Two distinct stall windows:
 *   1. cursor CAS done, claim_write not yet succeeded -- slot is still in
 *      EMPTY@gen (or briefly READING@gen if a prior popper is finishing).
 *   2. claim_write done, publish not yet done -- slot is WRITING@gen.
 * In either case plain deq_slot_claim_read would spin forever. We bound the
 * per-slot wait to ~2s; on timeout we CAS the current state -> EMPTY@(gen+1)
 * so the slot is reclaimed. The lock-free design doesn't track per-slot
 * owner PID so we cannot distinguish "dead writer" from "live but extremely
 * slow writer"; a 2s threshold is far longer than any legitimate slot fill.
 * A falsely-recovered live writer's late deq_slot_publish is a CAS keyed on
 * the original gen, so it observes the bump and silently no-ops rather than
 * resurrecting a phantom FILLED slot. */
static inline uint32_t deq_drain(DeqHandle *h) {
    DeqHeader *hdr = h->hdr;
    uint32_t cap = h->capacity;   /* cached-at-attach geometry, not live hdr */
    /* Snapshot how many items are present at entry.  We drain at most this many:
     * concurrent pops may take some, and pushes that arrive after entry are left
     * for the next call. */
    uint64_t c0 = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
    uint32_t target = (uint32_t)(DEQ_CURSOR_TAIL(c0) - DEQ_CURSOR_HEAD(c0));
    uint32_t drained = 0;
    /* Reclaim ONE head slot per iteration (not bulk-advance-then-walk): never
     * expose a freed slot for a wrapping push to reuse before we reclaim it --
     * that raced drain/pop/push on a reused slot (gen-agnostic claim_read). */
    while (drained < target) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        if ((uint32_t)(t - hd) == 0) break;     /* emptied by a concurrent consumer */
        uint64_t nc = DEQ_CURSOR(hd + 1, t);
        if (!__atomic_compare_exchange_n(&hdr->cursor, &c, nc,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
            continue;                            /* lost the CAS -- re-read + retry */
        /* We now exclusively own item hd's slot.  Reclaim it, with the same
         * bounded recovery the old drain used for a dead/slow writer's slot. */
        uint32_t idx = hd % cap;
        uint64_t *ctl_word = &h->ctl[idx];
        int recovered = 0, dl_set = 0;
        uint32_t spins = 0;
        struct timespec dl;
        for (;;) {
            uint64_t cw = __atomic_load_n(ctl_word, __ATOMIC_ACQUIRE);
            if (DEQ_SLOT_STATE(cw) == DEQ_SLOT_FILLED) {
                uint64_t nw = (DEQ_SLOT_GEN(cw) << 2) | DEQ_SLOT_READING;
                if (__atomic_compare_exchange_n(ctl_word, &cw, nw,
                        0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
                    deq_slot_release(ctl_word, DEQ_SLOT_GEN(cw));
                    break;
                }
                continue;
            }
            /* Non-FILLED: hot-spin, then short sleeps; on timeout force the slot
             * to EMPTY@(gen+1) (a dead/stalled writer left it WRITING). */
            deq_spin_pause();
            if ((++spins & 0x3F) == 0) {
                if (!dl_set) { deq_make_deadline((double)DEQ_DRAIN_RECOVERY_SEC, &dl); dl_set = 1; }
                struct timespec rem;
                if (!deq_remaining(&dl, &rem)) {
                    uint64_t nw = ((DEQ_SLOT_GEN(cw) + 1) << 2) | DEQ_SLOT_EMPTY;
                    if (__atomic_compare_exchange_n(ctl_word, &cw, nw,
                            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) { recovered = 1; break; }
                    continue;   /* CAS lost: state advanced concurrently -- re-observe */
                }
                struct timespec ts = { 0, 100000L }; /* 100us */
                nanosleep(&ts, NULL);
            }
        }
        if (recovered) __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
        drained++;
    }
    if (drained > 0) {
        /* StoreLoad: publish our slot/cursor changes before reading waiters. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        if (__atomic_load_n(&hdr->waiters_push, __ATOMIC_RELAXED) > 0) {
            __atomic_add_fetch(&hdr->push_wake_seq, 1, __ATOMIC_RELEASE);
            syscall(SYS_futex, &hdr->push_wake_seq, FUTEX_WAKE,
                    drained < INT_MAX ? (int)drained : INT_MAX, NULL, NULL, 0);
        }
    }
    return drained;
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
