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
 * Readers take the publication gate before advancing head/tail.
 *
 * Futex blocking when empty or full.
 */

#ifndef DEQUE_H
#define DEQUE_H

#include <stddef.h>
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

#define DEQ_MAGIC       0x44455133U  /* "DEQ3" -- generation-qualified wake hints */
#define DEQ_VERSION     3
#define DEQ_ERR_BUFLEN  (PATH_MAX + 256)

#ifndef DEQ_WAIT_INTERRUPTED
#define DEQ_WAIT_INTERRUPTED() 0
#endif

/* A slot must stay stuck this long before recovery. */
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
    uint32_t push_wait_hint;   /* registration generation + active bit */
    uint32_t pop_wait_hint;
    uint8_t  _pad0[8];

    uint64_t cursor;           /* 64: (head<<32)|tail */
    uint32_t waiters_push;     /* 72 */
    uint32_t waiters_pop;      /* 76 */
    uint64_t stat_pushes;      /* 80 */
    uint64_t stat_pops;        /* 88 */
    uint64_t stat_waits;       /* 96 */
    uint64_t stat_timeouts;    /* 104 */
    uint32_t push_wake_seq;    /* 112: futex word for pushers */
    uint32_t pop_wake_seq;     /* 116: futex word for poppers */
    uint64_t stat_recoveries;  /* 120: recovery of abandoned/stuck slots (WRITING, READING, or EMPTY) */
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

static inline uint64_t *deq_ctl_at(DeqHandle *h, uint32_t idx) {
    return &h->ctl[idx];
}

static inline void deq_copy(void *dst, const void *src, uint32_t size) {
    if (size == sizeof(uint64_t)) memcpy(dst, src, sizeof(uint64_t));
    else memcpy(dst, src, size);
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

static inline void deq_after_rmw_fence(void) {
#if defined(__x86_64__) || defined(__i386__)
    /* The preceding locked RMW already supplies the CPU fence. */
    __asm__ volatile("" ::: "memory");
#else
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
#endif
}

static inline void deq_waiter_enter(uint32_t *count, uint32_t *hint) {
    __atomic_add_fetch(count, 1, __ATOMIC_RELEASE);
    uint32_t c = __atomic_load_n(hint, __ATOMIC_RELAXED);
    while (!__atomic_compare_exchange_n(hint, &c, (c + 2u) | 1u,
            1, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {}
}

static inline void deq_waiter_leave(uint32_t *count, uint32_t *hint) {
    uint32_t c = __atomic_load_n(hint, __ATOMIC_RELAXED);
    if (__atomic_sub_fetch(count, 1, __ATOMIC_RELAXED) == 0)
        __atomic_compare_exchange_n(hint, &c, c & ~1u,
                0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
}

static void deq_wake_slow(DeqHeader *hdr, int push, int n, uint32_t c) {
    uint32_t *hint = push ? &hdr->push_wait_hint : &hdr->pop_wait_hint;
    uint32_t *seq = push ? &hdr->push_wake_seq : &hdr->pop_wake_seq;
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);
    /* Forget dead waiters only if nobody registered during the wake. */
    if (syscall(SYS_futex, seq, FUTEX_WAKE, n, NULL, NULL, 0) == 0)
        __atomic_compare_exchange_n(hint, &c, c & ~1u,
                0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
}

static inline void deq_wake(DeqHeader *hdr, int push, int n) {
    uint32_t c = __atomic_load_n(push ? &hdr->push_wait_hint : &hdr->pop_wait_hint,
                                  __ATOMIC_RELAXED);
    if (c & 1u) deq_wake_slow(hdr, push, n, c);
}

/* Readers reserve BEFORE moving the cursor, so the position cannot be reused
 * while an earlier reader is descheduled. Writers claim after the cursor CAS. */
static uint64_t deq_slot_reserve_slow(DeqHandle *__restrict h, uint64_t *ctl_word, uint64_t cursor,
                                      uint32_t want) {
    struct timespec dl;
    int dl_set = 0;
    uint32_t spins = 0;
    uint64_t waiting_ctl = UINT64_MAX;
    for (;;) {
        if (want == DEQ_SLOT_FILLED
            && __atomic_load_n(&h->hdr->cursor, __ATOMIC_ACQUIRE) != cursor) return 0;
        uint64_t c = __atomic_load_n(ctl_word, __ATOMIC_ACQUIRE);
        if (c != waiting_ctl) { waiting_ctl = c; dl_set = 0; }
        if (DEQ_SLOT_STATE(c) == want) {
            uint64_t nc = c | 1u;
            if (__atomic_compare_exchange_n(ctl_word, &c, nc,
                    0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
                return c;
            }
            continue;
        }
        deq_spin_pause();
        if ((++spins & 0x3F) == 0) {
            if (!dl_set) { deq_make_deadline((double)DEQ_DRAIN_RECOVERY_SEC, &dl); dl_set = 1; }
            struct timespec rem;
            if (!deq_remaining(&dl, &rem)) {
                uint64_t nc = ((DEQ_SLOT_GEN(c) + 1) << 2) | (want | 1u);
                if (__atomic_compare_exchange_n(ctl_word, &c, nc,
                        0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                    __atomic_add_fetch(&h->hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
                    return nc;
                }
            }
            struct timespec ts = { 0, 100000L };
            nanosleep(&ts, NULL);
        }
    }
}

/* Reads return FILLED@gen, READING@gen on recovery, or 0 to retry. */
static inline uint64_t deq_slot_reserve(DeqHandle *__restrict h, uint64_t *ctl_word, uint64_t cursor,
                                        uint32_t want) {
    for (uint32_t spins = 0; spins < 8; spins++) {
        uint64_t c = __atomic_load_n(ctl_word, __ATOMIC_ACQUIRE);
        if (DEQ_SLOT_STATE(c) == want) {
            uint64_t nc = c | 1u;
            if (__atomic_compare_exchange_n(ctl_word, &c, nc,
                    0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
                return c;
            }
        }
        if (want == DEQ_SLOT_FILLED
            && __atomic_load_n(&h->hdr->cursor, __ATOMIC_ACQUIRE) != cursor) return 0;
    }
    return deq_slot_reserve_slow(h, ctl_word, cursor, want);
}

static inline void deq_slot_cancel(uint64_t *ctl_word, uint64_t reserved) {
    uint64_t expected = reserved | DEQ_SLOT_READING;
    uint64_t restored = DEQ_SLOT_STATE(reserved) == DEQ_SLOT_FILLED
        ? reserved : reserved & ~(uint64_t)DEQ_SLOT_STATE_MASK;
    __atomic_compare_exchange_n(ctl_word, &expected, restored,
            0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
}

/* Keep the reservation when only the opposite boundary moved. */
static inline int deq_cursor_commit(DeqHandle *__restrict h, uint64_t c, int front) {
    uint32_t boundary = front ? DEQ_CURSOR_HEAD(c) : DEQ_CURSOR_TAIL(c);
    c = __atomic_load_n(&h->hdr->cursor, __ATOMIC_ACQUIRE);
    while ((front ? DEQ_CURSOR_HEAD(c) : DEQ_CURSOR_TAIL(c)) == boundary
           && DEQ_CURSOR_SIZE(c) != 0) {
        uint64_t nc = front
            ? DEQ_CURSOR(boundary + 1u, DEQ_CURSOR_TAIL(c))
            : DEQ_CURSOR(DEQ_CURSOR_HEAD(c), boundary - 1u);
        if (__atomic_compare_exchange_n(&h->hdr->cursor, &c, nc,
                0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) return 1;
    }
    return 0;
}

/* A late publish cannot resurrect a generation replaced by recovery. */
static inline void deq_slot_publish(uint64_t *ctl_word, uint64_t gen) {
    uint64_t expected = (gen << 2) | DEQ_SLOT_WRITING;
    uint64_t desired  = (gen << 2) | DEQ_SLOT_FILLED;
    (void)__atomic_compare_exchange_n(ctl_word, &expected, desired,
            0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
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

static inline int deq_try_push_back(DeqHandle *__restrict h, const void *val, uint32_t vlen) {
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
            uint32_t idx = t & (cap - 1);
            uint64_t *ctl_word = deq_ctl_at(h, idx);
            uint64_t gen = DEQ_SLOT_GEN(deq_slot_reserve(h, ctl_word, 0, DEQ_SLOT_EMPTY));
            deq_copy((h->data + (size_t)idx * sz), val, cp);
            if (cp < sz) memset((h->data + (size_t)idx * sz) + cp, 0, sz - cp);
            deq_slot_publish(ctl_word, gen);
            __atomic_add_fetch(&hdr->stat_pushes, 1, __ATOMIC_RELAXED);
            /* StoreLoad: publish our slot/cursor change before reading waiters. */
            deq_after_rmw_fence();
            deq_wake(hdr, 0, 1);
            return 1;
        }
    }
}

/* ================================================================
 * Push front (head--)
 * ================================================================ */

static inline int deq_try_push_front(DeqHandle *__restrict h, const void *val, uint32_t vlen) {
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
            uint32_t idx = new_hd & (cap - 1);
            uint64_t *ctl_word = deq_ctl_at(h, idx);
            uint64_t gen = DEQ_SLOT_GEN(deq_slot_reserve(h, ctl_word, 0, DEQ_SLOT_EMPTY));
            deq_copy((h->data + (size_t)idx * sz), val, cp);
            if (cp < sz) memset((h->data + (size_t)idx * sz) + cp, 0, sz - cp);
            deq_slot_publish(ctl_word, gen);
            __atomic_add_fetch(&hdr->stat_pushes, 1, __ATOMIC_RELAXED);
            /* StoreLoad: publish our slot/cursor change before reading waiters. */
            deq_after_rmw_fence();
            deq_wake(hdr, 0, 1);
            return 1;
        }
    }
}

/* ================================================================
 * Pop front (head++)
 * ================================================================ */

static inline int deq_try_pop_front(DeqHandle *__restrict h, void *out) {
    DeqHeader *hdr = h->hdr;
    uint32_t sz = h->elem_size;
    uint32_t cap = h->capacity;   /* cached-at-attach geometry, not live hdr */
    for (;;) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        if ((uint32_t)(t - hd) == 0) return 0;
        uint32_t idx = hd & (cap - 1);
        uint64_t *ctl_word = deq_ctl_at(h, idx);
        uint64_t reserved = deq_slot_reserve(h, ctl_word, c, DEQ_SLOT_FILLED);
        if (!reserved) continue;
        if (deq_cursor_commit(h, c, 1)) {
            uint64_t gen = DEQ_SLOT_GEN(reserved);
            if (DEQ_SLOT_STATE(reserved) == DEQ_SLOT_READING) {
                deq_slot_release(ctl_word, gen);
                /* Recovery advanced the cursor and freed space. */
                deq_after_rmw_fence();
                deq_wake(hdr, 1, 1);
                continue;
            }
            deq_copy(out, (h->data + (size_t)idx * sz), sz);
            deq_slot_release(ctl_word, gen);
            __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
            /* StoreLoad: publish our slot/cursor change before reading waiters. */
            deq_after_rmw_fence();
            deq_wake(hdr, 1, 1);
            return 1;
        }
        deq_slot_cancel(ctl_word, reserved);
    }
}

/* ================================================================
 * Pop back (tail--)
 * ================================================================ */

static inline int deq_try_pop_back(DeqHandle *__restrict h, void *out) {
    DeqHeader *hdr = h->hdr;
    uint32_t sz = h->elem_size;
    uint32_t cap = h->capacity;   /* cached-at-attach geometry, not live hdr */
    for (;;) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        if ((uint32_t)(t - hd) == 0) return 0;
        uint32_t idx = (t - 1) & (cap - 1);
        uint64_t *ctl_word = deq_ctl_at(h, idx);
        uint64_t reserved = deq_slot_reserve(h, ctl_word, c, DEQ_SLOT_FILLED);
        if (!reserved) continue;
        if (deq_cursor_commit(h, c, 0)) {
            uint64_t gen = DEQ_SLOT_GEN(reserved);
            if (DEQ_SLOT_STATE(reserved) == DEQ_SLOT_READING) {
                deq_slot_release(ctl_word, gen);
                /* Abandoned slot reclaimed (see deq_try_pop_front). */
                deq_after_rmw_fence();
                deq_wake(hdr, 1, 1);
                continue;
            }
            deq_copy(out, (h->data + (size_t)idx * sz), sz);
            deq_slot_release(ctl_word, gen);
            __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
            /* StoreLoad: publish our slot/cursor change before reading waiters. */
            deq_after_rmw_fence();
            deq_wake(hdr, 1, 1);
            return 1;
        }
        deq_slot_cancel(ctl_word, reserved);
    }
}

/* ================================================================
 * Blocking push/pop
 * ================================================================ */

static int deq_push_wait_slow(DeqHandle *h, const void *val, uint32_t vlen,
                              int front, double timeout) {
    int (*try_fn)(DeqHandle*, const void*, uint32_t) =
        front ? deq_try_push_front : deq_try_push_back;
    DeqHeader *hdr = h->hdr;
    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) deq_make_deadline(timeout, &dl);
    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    uint32_t cap = h->capacity;   /* cached-at-attach geometry, not live hdr */
    for (;;) {
        if (DEQ_WAIT_INTERRUPTED()) {
            deq_wake(hdr, 1, 1);
            errno = EINTR;
            return -1;
        }
        uint32_t wseq = __atomic_load_n(&hdr->push_wake_seq, __ATOMIC_ACQUIRE);
        deq_waiter_enter(&hdr->waiters_push, &hdr->push_wait_hint);
        /* StoreLoad: publish waiters++ before re-reading the cursor, so a
         * concurrent waker can't read waiters==0 while we read a stale cursor. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        if (DEQ_CURSOR_SIZE(c) >= cap) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!deq_remaining(&dl, &rem)) {
                    deq_waiter_leave(&hdr->waiters_push, &hdr->push_wait_hint);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
#ifdef DEQ_WAIT_POLL_NS
            struct timespec tick = { 0, DEQ_WAIT_POLL_NS };
            if (!pts || pts->tv_sec > 0 || pts->tv_nsec > DEQ_WAIT_POLL_NS) pts = &tick;
#endif
            syscall(SYS_futex, &hdr->push_wake_seq, FUTEX_WAIT, wseq, pts, NULL, 0);
        }
        deq_waiter_leave(&hdr->waiters_push, &hdr->push_wait_hint);
        if (DEQ_WAIT_INTERRUPTED()) {
            deq_wake(hdr, 1, 1);
            errno = EINTR;
            return -1;
        }
        if (try_fn(h, val, vlen)) return 1;
        if (has_dl && !deq_remaining(&dl, &rem)) {
            __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }
}

static int deq_pop_wait_slow(DeqHandle *h, void *out, int back, double timeout) {
    int (*try_fn)(DeqHandle*, void*) =
        back ? deq_try_pop_back : deq_try_pop_front;
    DeqHeader *hdr = h->hdr;
    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) deq_make_deadline(timeout, &dl);
    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        if (DEQ_WAIT_INTERRUPTED()) {
            deq_wake(hdr, 0, 1);
            errno = EINTR;
            return -1;
        }
        uint32_t wseq = __atomic_load_n(&hdr->pop_wake_seq, __ATOMIC_ACQUIRE);
        deq_waiter_enter(&hdr->waiters_pop, &hdr->pop_wait_hint);
        /* StoreLoad: publish waiters++ before re-reading the cursor, so a
         * concurrent waker can't read waiters==0 while we read a stale cursor. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        if (DEQ_CURSOR_SIZE(c) == 0) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!deq_remaining(&dl, &rem)) {
                    deq_waiter_leave(&hdr->waiters_pop, &hdr->pop_wait_hint);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
#ifdef DEQ_WAIT_POLL_NS
            struct timespec tick = { 0, DEQ_WAIT_POLL_NS };
            if (!pts || pts->tv_sec > 0 || pts->tv_nsec > DEQ_WAIT_POLL_NS) pts = &tick;
#endif
            syscall(SYS_futex, &hdr->pop_wake_seq, FUTEX_WAIT, wseq, pts, NULL, 0);
        }
        deq_waiter_leave(&hdr->waiters_pop, &hdr->pop_wait_hint);
        if (DEQ_WAIT_INTERRUPTED()) {
            deq_wake(hdr, 0, 1);
            errno = EINTR;
            return -1;
        }
        if (try_fn(h, out)) return 1;
        if (has_dl && !deq_remaining(&dl, &rem)) {
            __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }
}

static inline int deq_push_wait(DeqHandle *h, const void *val, uint32_t vlen,
                                 int front, double timeout) {
    if (front ? deq_try_push_front(h, val, vlen) : deq_try_push_back(h, val, vlen)) return 1;
    if (timeout == 0) return 0;
    return deq_push_wait_slow(h, val, vlen, front, timeout);
}

static inline int deq_pop_wait(DeqHandle *h, void *out, int back, double timeout) {
    if (back ? deq_try_pop_back(h, out) : deq_try_pop_front(h, out)) return 1;
    if (timeout == 0) return 0;
    return deq_pop_wait_slow(h, out, back, timeout);
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
    hdr->version    = DEQ_VERSION;
    hdr->elem_size  = elem_size;
    hdr->variant_id = variant_id;
    hdr->capacity   = capacity;
    hdr->total_size = total;
    hdr->data_off   = sizeof(DeqHeader);
    hdr->ctl_off    = deq_ctl_offset(elem_size, capacity);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    /* Publish magic LAST, as a release store: it is the commit point, so a
       creator killed before it leaves magic==0 and never a file mistaken for
       a valid one.  A kill during the field stores leaves one to remove by
       hand. */
    __atomic_store_n(&hdr->magic, DEQ_MAGIC, __ATOMIC_RELEASE);

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
    if (path && !h->path) {
        munmap(base, ms);
        if (bfd >= 0) close(bfd);
        free(h);
        return NULL;
    }
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

/* True iff the whole file is zero -- what an abandoned mid-init
   creator leaves.  Lets recovery re-init only a provably-empty file, never
   one that merely starts with a zero word.  Cold path, so a byte scan is
   fine.  Read, not mapped: a read fault on a tmpfs hole allocates the page. */
static int deq_file_is_zero(int fd, uint64_t size) {
    char buf[16384];
    for (uint64_t off = 0; off < size; ) {
        ssize_t n = pread(fd, buf, size - off < sizeof buf ? (size_t)(size - off) : sizeof buf, (off_t)off);
        if (n <= 0) return 0;
        for (ssize_t i = 0; i < n; i++) if (buf[i]) return 0;
        off += (uint64_t)n;
    }
    return 1;
}

/* A sparse segment would SIGBUS at the first write the filesystem cannot back. */
static int deq_reserve(int fd, uint64_t size) {
    const char *sp = getenv("DATA_DEQUE_SHARED_SPARSE");
    if (sp && *sp && strcmp(sp, "0")) return 0;
    /* Before Linux 6.11 tmpfs gives up at any pending signal and undoes the allocation, so a
     * periodic one could keep it from ever completing; SIGSTOP cannot be blocked. */
    sigset_t all, old;
    sigfillset(&all);
    sigprocmask(SIG_BLOCK, &all, &old);
    int e;
    do e = posix_fallocate(fd, 0, (off_t)size); while (e == EINTR);
    sigprocmask(SIG_SETMASK, &old, NULL);
    if (e == 0 || e == EOPNOTSUPP || e == EINVAL) return 0;
    errno = e;
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
        if (is_new && deq_reserve(fd, total) < 0) {
            DEQ_ERR("%s: cannot reserve %llu bytes: %s", path, (unsigned long long)total, strerror(errno));
            if (ftruncate(fd, 0) < 0) { /* best effort */ }
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            DEQ_ERR("mmap: %s", strerror(errno));
            if (is_new && ftruncate(fd, 0) < 0) { /* best effort */ }
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (!is_new) {
            DeqHeader snap;  /* single fetch: validate + setup use one copy */
            memcpy(&snap, base, sizeof snap);
            if (!deq_validate_header(&snap, (uint64_t)st.st_size, variant_id)) {
                /* Recover an abandoned mid-init file: a creator killed
                 * between the ftruncate and the header init leaves a
                 * full-size, all-zero (magic==0) file that would brick every
                 * future open of this path.  Re-initialize ONLY when it is
                 * exactly our size, still uninitialized, and owned by us;
                 * anything else still errors.  Reads snap.magic, the snapshot
                 * already fetched, rather than `base` again -- the same
                 * single-fetch TOCTOU avoidance used above. */
                if (snap.magic == 0 && (uint64_t)st.st_size == total
                    && st.st_uid == geteuid() && deq_file_is_zero(fd, map_size)) {
                    if (fchmod(fd, mode) < 0) {
                        DEQ_ERR("%s: fchmod: %s", path, strerror(errno));
                        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                    }
                    if (deq_reserve(fd, total) < 0) {
                        DEQ_ERR("%s: cannot reserve %llu bytes: %s", path, (unsigned long long)total, strerror(errno));
                        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                    }
                    deq_init_header(base, total, elem_size, variant_id, capacity);
                    flock(fd, LOCK_UN); close(fd);
                    return deq_setup(base, map_size, path, -1,
                                     sizeof(DeqHeader), deq_ctl_offset(elem_size, capacity),
                                     elem_size, capacity);
                }
                if (snap.magic == 0 && (uint64_t)st.st_size == total
                    && st.st_uid == geteuid()) {
                    DEQ_ERR("%s: incomplete deque file left by an interrupted create; remove it and retry", path);
                    munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                }
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
    if (deq_reserve(fd, total) < 0) {
        DEQ_ERR("memfd: cannot reserve %llu bytes: %s", (unsigned long long)total, strerror(errno));
        close(fd); return NULL;
    }
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
    /* before mmap: a creator may truncate the file until it has set magic */
    uint32_t magic;
    if (pread(fd, &magic, sizeof magic, offsetof(DeqHeader, magic)) != (ssize_t)sizeof magic || magic != DEQ_MAGIC) {
        DEQ_ERR("invalid deque"); return NULL;
    }
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
    deq_wake(h->hdr, 1, INT_MAX);
    /* StoreLoad: publish our slot/cursor change before reading waiters. */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    deq_wake(h->hdr, 0, INT_MAX);
}

/* Drain at most the entry size, reserving each slot before advancing head.
 * Abandoned slots use the same bounded recovery as push/pop. */
static inline uint32_t deq_drain(DeqHandle *h) {
    DeqHeader *hdr = h->hdr;
    uint32_t cap = h->capacity;   /* cached-at-attach geometry, not live hdr */
    /* Bound the work even if producers keep adding items. */
    uint64_t c0 = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
    uint32_t target = (uint32_t)(DEQ_CURSOR_TAIL(c0) - DEQ_CURSOR_HEAD(c0));
    uint32_t drained = 0;
    while (drained < target) {
        uint64_t c = __atomic_load_n(&hdr->cursor, __ATOMIC_ACQUIRE);
        uint32_t hd = DEQ_CURSOR_HEAD(c), t = DEQ_CURSOR_TAIL(c);
        if ((uint32_t)(t - hd) == 0) break;     /* emptied by a concurrent consumer */
        uint32_t idx = hd & (cap - 1);
        uint64_t *ctl_word = deq_ctl_at(h, idx);
        uint64_t reserved = deq_slot_reserve(h, ctl_word, c, DEQ_SLOT_FILLED);
        if (!reserved) continue;
        if (!deq_cursor_commit(h, c, 1)) {
            deq_slot_cancel(ctl_word, reserved);
            continue;
        }
        deq_slot_release(ctl_word, DEQ_SLOT_GEN(reserved));
        drained++;
    }
    if (drained > 0) {
        /* StoreLoad: publish our slot/cursor changes before reading waiters. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        deq_wake(hdr, 1, drained < INT_MAX ? (int)drained : INT_MAX);
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
