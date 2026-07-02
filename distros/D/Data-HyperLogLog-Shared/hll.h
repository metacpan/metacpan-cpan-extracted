/*
 * hll.h -- Shared-memory HyperLogLog cardinality estimator for Linux
 *
 * Estimates the number of distinct items seen (probabilistic distinct-count)
 * using a fixed array of m = 2^precision single-byte registers. Each item is
 * hashed (XXH3); the top `precision` bits pick a register, the position of the
 * first set bit in the rest updates that register with a running maximum. The
 * register array lives in a shared mapping so several processes share one
 * estimator; a write-preferring futex rwlock with reader-slot dead-process
 * recovery guards mutation. Two estimators of equal precision can be merged
 * (register-wise max).
 *
 * Layout: Header -> reader_slots[1024] -> regs[m]
 */

#ifndef HLL_H
#define HLL_H

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <limits.h>
#include <signal.h>
#include <stdio.h>
#include <math.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <linux/futex.h>
#include <pthread.h>

#define XXH_INLINE_ALL
#include "xxhash.h"

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "hll.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define HLL_MAGIC        0x474C4C48U  /* "HLLG" (little-endian) */
#define HLL_VERSION      1
#define HLL_ERR_BUFLEN   256
#define HLL_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#define HLL_MIN_PRECISION 4           /* m = 16  registers */
#define HLL_MAX_PRECISION 18          /* m = 262144 registers (256 KB) */

#define HLL_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, HLL_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

/* ================================================================
 * Structs
 * ================================================================ */

/* Per-process slot for dead-process recovery.  Each shared rwlock counter
 * (the main rwlock-reader count, rwlock_waiters, rwlock_writers_waiting)
 * is mirrored here so a wrlock timeout can attribute and reverse a dead
 * process's contribution instead of waiting for the slow per-op timeout
 * drain. */
typedef struct {
    uint32_t pid;            /* 0 = unclaimed */
    uint32_t subcount;       /* in-flight rdlock acquisitions for this process */
    uint32_t waiters_parked; /* contribution to hdr->rwlock_waiters         */
    uint32_t writers_parked; /* contribution to hdr->rwlock_writers_waiting */
} HllReaderSlot;

struct HllHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t precision;               /* 8   register-index bit count */
    uint32_t m;                       /* 12  register count (= 1 << precision) */
    uint32_t _pad0;                   /* 16 */
    uint32_t _pad1;                   /* 20 */
    uint64_t total_size;              /* 24 */
    uint64_t reader_slots_off;        /* 32 */
    uint64_t regs_off;                /* 40 */
    uint32_t rwlock;                  /* 48 */
    uint32_t rwlock_waiters;          /* 52 */
    uint32_t rwlock_writers_waiting;  /* 56 */
    uint32_t _pad2;                   /* 60 */
    uint64_t stat_ops;                /* 64 */
    uint8_t  _pad[184];               /* 72..255 */
};
typedef struct HllHeader HllHeader;

_Static_assert(sizeof(HllHeader) == 256, "HllHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct HllHandle {
    HllHeader     *hdr;
    HllReaderSlot *reader_slots;  /* HLL_READER_SLOTS entries */
    void          *base;          /* mmap base */
    size_t         mmap_size;
    char          *path;          /* backing file path (strdup'd) */
    int            backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t       my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;    /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* hll_fork_gen value at last slot claim */
} HllHandle;

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define HLL_RWLOCK_SPIN_LIMIT 32
#define HLL_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void hll_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define HLL_RWLOCK_WRITER_BIT 0x80000000U
#define HLL_RWLOCK_PID_MASK   0x7FFFFFFFU
#define HLL_RWLOCK_WR(pid)    (HLL_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & HLL_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
static inline int hll_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void hll_recover_stale_lock(HllHandle *h, uint32_t observed_rwlock) {
    HllHeader *hdr = h->hdr;
    uint32_t mypid = HLL_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec hll_lock_timeout = { HLL_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t hll_fork_gen = 1;
static pthread_once_t hll_atfork_once = PTHREAD_ONCE_INIT;
static void hll_on_fork_child(void) {
    __atomic_add_fetch(&hll_fork_gen, 1, __ATOMIC_RELAXED);
}
static void hll_atfork_init(void) {
    pthread_atfork(NULL, NULL, hll_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void hll_claim_reader_slot(HllHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&hll_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&hll_atfork_once, hll_atfork_init);
    /* Re-read after pthread_once: hll_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&hll_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % HLL_READER_SLOTS;
    for (uint32_t i = 0; i < HLL_READER_SLOTS; i++) {
        uint32_t s = (start + i) % HLL_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and hll_recover_dead_readers won't drain them
             * once we own the slot (the CAS expects the dead PID). */
            __atomic_store_n(&h->reader_slots[s].subcount, 0, __ATOMIC_RELAXED);
            __atomic_store_n(&h->reader_slots[s].waiters_parked, 0, __ATOMIC_RELAXED);
            __atomic_store_n(&h->reader_slots[s].writers_parked, 0, __ATOMIC_RELAXED);
            h->my_slot_idx = s;
            return;
        }
    }
    /* Table full -- leave my_slot_idx = UINT32_MAX so we silently skip
     * tracking for this handle (lock still works; just no recovery). */
}

/* Atomically subtract `sub` from a counter, capped at 0 (never underflows). */
static inline void hll_atomic_sub_cap(uint32_t *p, uint32_t sub) {
    if (!sub) return;
    uint32_t cur = __atomic_load_n(p, __ATOMIC_RELAXED);
    for (;;) {
        uint32_t want = (cur > sub) ? cur - sub : 0;
        if (__atomic_compare_exchange_n(p, &cur, want,
                1, __ATOMIC_RELAXED, __ATOMIC_RELAXED))
            return;
    }
}

/* Try to claim a dead slot (CAS pid -> 0) and drain its parked-waiter
 * contributions back to the global counters.  A no-op if the slot was stolen
 * by another recoverer or had no waiter contribution to drain.
 *
 * Note: subcount/waiters_parked/writers_parked are NOT zeroed here.
 * Between our CAS and a follow-up store, a new process could claim the
 * slot and start populating these fields -- our stores would clobber its
 * state.  hll_claim_reader_slot zeros all three on every claim, so
 * leaving stale values is harmless. */
static inline void hll_drain_dead_slot(HllHandle *h, uint32_t i, uint32_t pid) {
    HllHeader *hdr = h->hdr;
    uint32_t expected = pid;
    /* ACQ_REL on success: RELEASE publishes pid=0 to other observers;
     * ACQUIRE syncs us with prior writes from the dead process to
     * waiters_parked/writers_parked.  On weakly-ordered archs (aarch64)
     * a plain RELAXED load before the CAS could miss those writes;
     * loading them after the CAS keeps them inside the acquire window. */
    if (!__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    uint32_t wp    = __atomic_load_n(&h->reader_slots[i].waiters_parked, __ATOMIC_RELAXED);
    uint32_t writp = __atomic_load_n(&h->reader_slots[i].writers_parked, __ATOMIC_RELAXED);
    if (wp)    hll_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) hll_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
}

/* Scan reader slots for dead-process recovery.
 *
 * For each dead PID with non-zero contributions to the shared rwlock,
 * rwlock_waiters, or rwlock_writers_waiting counters, drain its share back
 * out so live processes don't have to wait for the slow per-op timeout
 * decrement to drain it for them.
 *
 * For the main rwlock counter we use the "no live reader holds -> force-
 * reset to 0" trick (precise) because per-process attribution of the
 * subcount is racy across the inc-counter-then-inc-subcount window. */
static inline void hll_recover_dead_readers(HllHandle *h) {
    if (!h->reader_slots) return;
    HllHeader *hdr = h->hdr;
    int any_live_reader = 0;
    int found_dead_reader = 0;

    /* Pass 1: classify slots.  Slots with dead pid and sc == 0 (no rwlock
     * contribution to lose) are wiped immediately to free the slot for
     * future claimants and drain any orphan parked-waiter counters.  Slots
     * with dead pid and sc > 0 are left intact in this pass: if force-
     * reset cannot fire (because a live reader is concurrently present),
     * wiping the dead slot would lose the only record of its orphan
     * rwlock contribution and strand writers permanently once the live
     * reader releases. */
    for (uint32_t i = 0; i < HLL_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (hll_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        hll_drain_dead_slot(h, i, pid);
    }

    /* Pass 2: only if force-reset will fire.  Issue the rwlock force-
     * reset CAS FIRST, while the window since pass 1's last scan is
     * still narrow (a handful of instructions, as in the original
     * single-pass code).  A new reader that started rdlock between
     * pass 1's scan and the CAS will either:
     *   (a) have already CAS'd rwlock from cur to cur+1 -- our CAS then
     *       fails (cur mismatched), recovery yields and a future
     *       cycle retries; or
     *   (b) be still in the subcount-bump phase -- our CAS sees the
     *       stale cur and resets to 0; the new reader's subsequent CAS
     *       rwlock(0 -> 1) succeeds cleanly.
     * Only after the CAS resolves do we wipe the deferred dead slots,
     * keeping that work outside the race-sensitive window. */
    if (found_dead_reader && !any_live_reader) {
        uint32_t cur = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
        if (cur > 0 && cur < HLL_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            }
        }
        for (uint32_t i = 0; i < HLL_READER_SLOTS; i++) {
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            if (pid == 0 || hll_pid_alive(pid)) continue;
            hll_drain_dead_slot(h, i, pid);
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters.  Called from rdlock and wrlock ETIMEDOUT
 * branches -- identical recovery logic in both. */
static inline void hll_recover_after_timeout(HllHandle *h) {
    HllHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= HLL_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & HLL_RWLOCK_PID_MASK;
        if (!hll_pid_alive(pid))
            hll_recover_stale_lock(h, val);
    } else {
        hll_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution.  Kept paired to make
 * accidental drift between global and per-slot counts impossible. */
static inline void hll_park_reader(HllHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void hll_unpark_reader(HllHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void hll_park_writer(HllHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void hll_unpark_writer(HllHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void hll_rwlock_rdlock(HllHandle *h) {
    hll_claim_reader_slot(h);
    HllHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    /* Claim subcount BEFORE bumping the shared rwlock counter.  This way
     * a concurrent writer-side recovery scan that sees our PID alive with
     * subcount > 0 will (correctly) defer force-reset, even while we are
     * still spinning trying to win the rwlock CAS.  Without this, a reader
     * killed between rwlock CAS-success and subcount++ would let recovery
     * force-reset rwlock to 0 underneath us, causing a UINT32_MAX wrap on
     * our eventual rdunlock dec. */
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Write-preferring: when lock is free (cur==0) and writers are
         * waiting, yield to let the writer acquire. When readers are
         * already active (cur>=1), new readers may join freely. */
        if (cur > 0 && cur < HLL_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < HLL_RWLOCK_SPIN_LIMIT, 1)) {
            hll_rwlock_spin_pause();
            continue;
        }
        hll_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= HLL_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &hll_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                hll_unpark_reader(h);
                hll_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        hll_unpark_reader(h);
        spin = 0;
    }
}

static inline void hll_rwlock_rdunlock(HllHandle *h) {
    HllHeader *hdr = h->hdr;
    /* Release the shared counter BEFORE dropping our subcount so that
     * "any live PID with subcount > 0" is a reliable in-flight indicator
     * for the writer-side recovery scan.  Inverting these would create a
     * window where we still own a unit of rwlock but our slot subcount is
     * 0, letting recovery force-reset rwlock underneath us. */
    uint32_t after = __atomic_sub_fetch(&hdr->rwlock, 1, __ATOMIC_RELEASE);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    if (after == 0 && __atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void hll_rwlock_wrlock(HllHandle *h) {
    hll_claim_reader_slot(h);  /* refresh cached_pid across fork */
    HllHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = HLL_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < HLL_RWLOCK_SPIN_LIMIT, 1)) {
            hll_rwlock_spin_pause();
            continue;
        }
        hll_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &hll_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                hll_unpark_writer(h);
                hll_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        hll_unpark_writer(h);
        spin = 0;
    }
}

static inline void hll_rwlock_wrunlock(HllHandle *h) {
    HllHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> regs[m]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets. */
typedef struct { uint64_t reader_slots, regs; } HllLayout;

static inline HllLayout hll_layout(void) {
    HllLayout L;
    L.reader_slots = sizeof(HllHeader);
    L.regs         = L.reader_slots + (uint64_t)HLL_READER_SLOTS * sizeof(HllReaderSlot);
    L.regs         = (L.regs + 7) & ~(uint64_t)7;   /* 8-byte align the register array */
    return L;
}

static inline uint64_t hll_total_size(uint32_t m) {
    HllLayout L = hll_layout();
    return L.regs + (uint64_t)m;
}

static inline void hll_init_header(void *base, uint32_t precision, uint32_t m, uint64_t total) {
    HllLayout L = hll_layout();
    HllHeader *hdr = (HllHeader *)base;
    /* Explicitly zero the header + reader-slot region (lock-recovery state, like
       intern.h); the register array relies on the fresh mapping being OS zero-filled. */
    memset(base, 0, (size_t)L.regs);
    hdr->magic            = HLL_MAGIC;
    hdr->version          = HLL_VERSION;
    hdr->precision        = precision;
    hdr->m                = m;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->regs_off         = L.regs;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint8_t *hll_regs(HllHandle *h) {
    return (uint8_t *)((char *)h->base + h->hdr->regs_off);
}

static inline HllHandle *hll_setup(void *base, size_t map_size,
                                   const char *path, int backing_fd) {
    HllHeader *hdr = (HllHeader *)base;
    HllHandle *h = (HllHandle *)calloc(1, sizeof(HllHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (HllReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by hll_create reopen and hll_open_fd). */
static inline int hll_validate_header(const HllHeader *hdr, uint64_t file_size) {
    if (hdr->magic != HLL_MAGIC) return 0;
    if (hdr->version != HLL_VERSION) return 0;
    if (hdr->precision < HLL_MIN_PRECISION || hdr->precision > HLL_MAX_PRECISION) return 0;
    if (hdr->m != (1u << hdr->precision)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != hll_total_size(hdr->m)) return 0;
    HllLayout L = hll_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->regs_off != L.regs) return 0;
    return 1;
}

/* validate the precision argument */
static int hll_validate_create_args(uint32_t precision, uint32_t *m_out, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (precision < HLL_MIN_PRECISION || precision > HLL_MAX_PRECISION) {
        HLL_ERR("precision must be between %d and %d", HLL_MIN_PRECISION, HLL_MAX_PRECISION);
        return 0;
    }
    *m_out = 1u << precision;
    return 1;
}

static HllHandle *hll_create(const char *path, uint32_t precision, char *errbuf) {
    uint32_t m;
    if (!hll_validate_create_args(precision, &m, errbuf)) return NULL;

    uint64_t total = hll_total_size(m);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { HLL_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { HLL_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { HLL_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { HLL_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(HllHeader)) {
            HLL_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            HLL_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { HLL_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!hll_validate_header((HllHeader *)base, (uint64_t)st.st_size)) {
                HLL_ERR("invalid HyperLogLog file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return hll_setup(base, map_size, path, -1);
        }
    }
    hll_init_header(base, precision, m, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return hll_setup(base, map_size, path, -1);
}

static HllHandle *hll_create_memfd(const char *name, uint32_t precision, char *errbuf) {
    uint32_t m;
    if (!hll_validate_create_args(precision, &m, errbuf)) return NULL;

    uint64_t total = hll_total_size(m);
    int fd = memfd_create(name ? name : "hll", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { HLL_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        HLL_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { HLL_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    hll_init_header(base, precision, m, total);
    return hll_setup(base, (size_t)total, NULL, fd);
}

static HllHandle *hll_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { HLL_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(HllHeader)) { HLL_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { HLL_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!hll_validate_header((HllHeader *)base, (uint64_t)st.st_size)) {
        HLL_ERR("invalid HyperLogLog table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { HLL_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return hll_setup(base, ms, NULL, myfd);
}

static void hll_destroy(HllHandle *h) {
    if (!h) return;
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int hll_msync(HllHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * HyperLogLog operations (callers hold the lock)
 * ================================================================ */

/* add one item; returns 1 if a register increased, else 0 */
static int hll_add_locked(HllHandle *h, const void *item, size_t len) {
    uint64_t x = XXH3_64bits(item, len);
    uint32_t p = h->hdr->precision;
    uint32_t idx = (uint32_t)(x >> (64 - p));           /* top p bits = register index */
    uint64_t rest = (x << p) | (1ULL << (p - 1));       /* guard bit so clz terminates */
    uint8_t  rho  = (uint8_t)(__builtin_clzll(rest) + 1);
    uint8_t *regs = hll_regs(h);
    if (regs[idx] < rho) { regs[idx] = rho; return 1; }
    return 0;
}

/* estimate; returns a double */
static double hll_count_locked(HllHandle *h) {
    uint32_t m = h->hdr->m;
    uint8_t *regs = hll_regs(h);
    double sum = 0.0;
    uint32_t V = 0;
    for (uint32_t j = 0; j < m; j++) {
        sum += ldexp(1.0, -(int)regs[j]);
        V += (regs[j] == 0);
    }
    double alpha;
    if      (m == 16) alpha = 0.673;
    else if (m == 32) alpha = 0.697;
    else if (m == 64) alpha = 0.709;
    else              alpha = 0.7213 / (1.0 + 1.079 / (double)m);
    double E = alpha * (double)m * (double)m / sum;
    if (E <= 2.5 * (double)m && V > 0)
        E = (double)m * log((double)m / (double)V);  /* linear counting (small range) */
    return E;
}

/* merge src registers into dst (caller guarantees equal m); register-wise max */
static void hll_merge_regs(HllHandle *dst, const uint8_t *src_regs) {
    uint32_t m = dst->hdr->m;
    uint8_t *regs = hll_regs(dst);
    for (uint32_t j = 0; j < m; j++)
        if (src_regs[j] > regs[j]) regs[j] = src_regs[j];
}

/* reset all registers to 0 (caller holds the write lock) */
static inline void hll_clear_locked(HllHandle *h) {
    memset(hll_regs(h), 0, (size_t)h->hdr->m);
}

#endif /* HLL_H */
