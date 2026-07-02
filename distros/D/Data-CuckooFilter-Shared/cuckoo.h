/*
 * cuckoo.h -- Shared-memory Cuckoo filter for Linux
 *
 * Approximate set membership WITH delete: tells you whether an item is
 * "definitely not" or "probably" in the set, in a fixed amount of memory, with
 * a tiny false-positive rate -- and unlike a Bloom filter it supports removal.
 * Each item is hashed once (XXH3-128); a 16-bit fingerprint plus two candidate
 * buckets (partial-key cuckoo hashing) drive a bucketed open-addressed table of
 * CF_SLOTS fingerprint slots per bucket. The table lives in a shared mapping so
 * several processes share one filter; a write-preferring futex rwlock with
 * reader-slot dead-process recovery guards mutation. The filter has a bounded
 * capacity: add returns false (a true no-op) when the table is full.
 *
 * Layout: Header -> reader_slots[1024] -> slots[num_buckets * CF_SLOTS]
 */

#ifndef CUCKOO_H
#define CUCKOO_H

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
#error "cuckoo.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define CF_MAGIC        0x4B4F4F43U  /* "COOK" (little-endian) */
#define CF_VERSION      1
#define CF_ERR_BUFLEN   256
#define CF_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#define CF_SLOTS        4            /* fingerprint slots per bucket */
#define CF_MAX_KICKS    500          /* cuckoo eviction bound before declaring the table full */
#define CF_MIN_BUCKETS  2            /* floor on the bucket count (power of two) */
#define CF_MAX_BUCKETS  0x4000000000ULL /* 2^38 buckets cap (2^38*4*2 = 2 TiB slot array) */

#define CF_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, CF_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} CfReaderSlot;

struct CfHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t _pad0;                   /* 8  */
    uint32_t _pad1;                   /* 12 */
    uint64_t num_buckets;             /* 16  bucket count (power of two) */
    uint64_t bucket_mask;             /* 24  num_buckets - 1 (bucket index mask) */
    uint64_t capacity;                /* 32  configured item capacity (for stats) */
    uint64_t count;                   /* 40  live fingerprint count (maintained on add/remove) */
    uint64_t rng_state;               /* 48  xorshift64 state for eviction victim choice */
    uint64_t total_size;              /* 56 */
    uint64_t reader_slots_off;        /* 64 */
    uint64_t slots_off;               /* 72 */
    uint32_t rwlock;                  /* 80 */
    uint32_t rwlock_waiters;          /* 84 */
    uint32_t rwlock_writers_waiting;  /* 88 */
    uint32_t _pad2;                   /* 92 */
    uint64_t stat_ops;                /* 96 */
    uint8_t  _pad[152];               /* 104..255 */
};
typedef struct CfHeader CfHeader;

_Static_assert(sizeof(CfHeader) == 256, "CfHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct CfHandle {
    CfHeader     *hdr;
    CfReaderSlot *reader_slots;  /* CF_READER_SLOTS entries */
    void         *base;          /* mmap base */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* cf_fork_gen value at last slot claim */
} CfHandle;

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define CF_RWLOCK_SPIN_LIMIT 32
#define CF_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void cf_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define CF_RWLOCK_WRITER_BIT 0x80000000U
#define CF_RWLOCK_PID_MASK   0x7FFFFFFFU
#define CF_RWLOCK_WR(pid)    (CF_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & CF_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
static inline int cf_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void cf_recover_stale_lock(CfHandle *h, uint32_t observed_rwlock) {
    CfHeader *hdr = h->hdr;
    uint32_t mypid = CF_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec cf_lock_timeout = { CF_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t cf_fork_gen = 1;
static pthread_once_t cf_atfork_once = PTHREAD_ONCE_INIT;
static void cf_on_fork_child(void) {
    __atomic_add_fetch(&cf_fork_gen, 1, __ATOMIC_RELAXED);
}
static void cf_atfork_init(void) {
    pthread_atfork(NULL, NULL, cf_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void cf_claim_reader_slot(CfHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&cf_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&cf_atfork_once, cf_atfork_init);
    /* Re-read after pthread_once: cf_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&cf_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % CF_READER_SLOTS;
    for (uint32_t i = 0; i < CF_READER_SLOTS; i++) {
        uint32_t s = (start + i) % CF_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and cf_recover_dead_readers won't drain them
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
static inline void cf_atomic_sub_cap(uint32_t *p, uint32_t sub) {
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
 * state.  cf_claim_reader_slot zeros all three on every claim, so
 * leaving stale values is harmless. */
static inline void cf_drain_dead_slot(CfHandle *h, uint32_t i, uint32_t pid) {
    CfHeader *hdr = h->hdr;
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
    if (wp)    cf_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) cf_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
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
static inline void cf_recover_dead_readers(CfHandle *h) {
    if (!h->reader_slots) return;
    CfHeader *hdr = h->hdr;
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
    for (uint32_t i = 0; i < CF_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (cf_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        cf_drain_dead_slot(h, i, pid);
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
        if (cur > 0 && cur < CF_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            }
        }
        for (uint32_t i = 0; i < CF_READER_SLOTS; i++) {
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            if (pid == 0 || cf_pid_alive(pid)) continue;
            cf_drain_dead_slot(h, i, pid);
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters.  Called from rdlock and wrlock ETIMEDOUT
 * branches -- identical recovery logic in both. */
static inline void cf_recover_after_timeout(CfHandle *h) {
    CfHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= CF_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & CF_RWLOCK_PID_MASK;
        if (!cf_pid_alive(pid))
            cf_recover_stale_lock(h, val);
    } else {
        cf_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution.  Kept paired to make
 * accidental drift between global and per-slot counts impossible. */
static inline void cf_park_reader(CfHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void cf_unpark_reader(CfHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void cf_park_writer(CfHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void cf_unpark_writer(CfHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void cf_rwlock_rdlock(CfHandle *h) {
    cf_claim_reader_slot(h);
    CfHeader *hdr = h->hdr;
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
        if (cur > 0 && cur < CF_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < CF_RWLOCK_SPIN_LIMIT, 1)) {
            cf_rwlock_spin_pause();
            continue;
        }
        cf_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= CF_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &cf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                cf_unpark_reader(h);
                cf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        cf_unpark_reader(h);
        spin = 0;
    }
}

static inline void cf_rwlock_rdunlock(CfHandle *h) {
    CfHeader *hdr = h->hdr;
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

static inline void cf_rwlock_wrlock(CfHandle *h) {
    cf_claim_reader_slot(h);  /* refresh cached_pid across fork */
    CfHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = CF_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < CF_RWLOCK_SPIN_LIMIT, 1)) {
            cf_rwlock_spin_pause();
            continue;
        }
        cf_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &cf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                cf_unpark_writer(h);
                cf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        cf_unpark_writer(h);
        spin = 0;
    }
}

static inline void cf_rwlock_wrunlock(CfHandle *h) {
    CfHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> slots[num_buckets * CF_SLOTS]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets. */
typedef struct { uint64_t reader_slots, slots; } CfLayout;

static inline CfLayout cf_layout(void) {
    CfLayout L;
    L.reader_slots = sizeof(CfHeader);
    L.slots        = L.reader_slots + (uint64_t)CF_READER_SLOTS * sizeof(CfReaderSlot);
    L.slots        = (L.slots + 7) & ~(uint64_t)7;   /* 8-byte align the slot array */
    return L;
}

static inline uint64_t cf_total_size(uint64_t num_buckets) {
    CfLayout L = cf_layout();
    /* num_buckets * CF_SLOTS uint16_t fingerprint slots */
    return L.slots + num_buckets * (uint64_t)CF_SLOTS * sizeof(uint16_t);
}

/* round v up to the next power of two (64-bit), with a floor of CF_MIN_BUCKETS */
static inline uint64_t cf_next_pow2_u64(uint64_t v) {
    if (v <= CF_MIN_BUCKETS) return CF_MIN_BUCKETS;
    return 1ULL << (64 - __builtin_clzll(v - 1));
}

static inline void cf_init_header(void *base, uint64_t num_buckets,
                                  uint64_t capacity, uint64_t total) {
    CfLayout L = cf_layout();
    CfHeader *hdr = (CfHeader *)base;
    /* Zero the header + reader-slot region (lock-recovery state); the slot
       array relies on the fresh mapping being OS zero-filled (0 = empty slot). */
    memset(base, 0, (size_t)L.slots);
    hdr->magic            = CF_MAGIC;
    hdr->version          = CF_VERSION;
    hdr->num_buckets      = num_buckets;
    hdr->bucket_mask      = num_buckets - 1;
    hdr->capacity         = capacity;
    hdr->count            = 0;
    /* Deterministic, non-zero seed for the eviction-victim RNG. */
    hdr->rng_state        = 0x9e3779b97f4a7c15ULL ^ (capacity * 0x2545F4914F6CDD1DULL);
    if (hdr->rng_state == 0) hdr->rng_state = 1;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->slots_off        = L.slots;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint16_t *cf_slots(CfHandle *h) {
    return (uint16_t *)((char *)h->base + h->hdr->slots_off);
}

static inline CfHandle *cf_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    CfHeader *hdr = (CfHeader *)base;
    CfHandle *h = (CfHandle *)calloc(1, sizeof(CfHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (CfReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by cf_create reopen and cf_open_fd). */
static inline int cf_validate_header(const CfHeader *hdr, uint64_t file_size) {
    if (hdr->magic != CF_MAGIC) return 0;
    if (hdr->version != CF_VERSION) return 0;
    if (hdr->num_buckets < CF_MIN_BUCKETS || hdr->num_buckets > CF_MAX_BUCKETS) return 0;
    if ((hdr->num_buckets & (hdr->num_buckets - 1)) != 0) return 0;   /* power of two */
    if (hdr->bucket_mask != hdr->num_buckets - 1) return 0;
    if (hdr->capacity == 0) return 0;
    if (hdr->rng_state == 0) return 0;
    if (hdr->count > hdr->num_buckets * (uint64_t)CF_SLOTS) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != cf_total_size(hdr->num_buckets)) return 0;
    CfLayout L = cf_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->slots_off != L.slots) return 0;
    return 1;
}

/* validate args + compute the geometry (num_buckets) */
static int cf_validate_create_args(uint64_t capacity,
                                   uint64_t *num_buckets_out, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity < 1) { CF_ERR("capacity must be >= 1"); return 0; }

    /* Size for the target load factor: num_buckets =
       next_pow2(ceil(capacity / CF_SLOTS / 0.95)), floor CF_MIN_BUCKETS.
       Reject (don't silently cap) a capacity that would exceed the bucket cap,
       else the filter would be undersized and overflow at the requested load. */
    double want_d = ceil((double)capacity / (double)CF_SLOTS / 0.95);
    if (want_d > (double)CF_MAX_BUCKETS) { CF_ERR("capacity too large for the bucket cap"); return 0; }
    uint64_t num_buckets = cf_next_pow2_u64((uint64_t)want_d);   /* next_pow2 floors at CF_MIN_BUCKETS */

    *num_buckets_out = num_buckets;
    return 1;
}

static CfHandle *cf_create(const char *path, uint64_t capacity, char *errbuf) {
    uint64_t num_buckets;
    if (!cf_validate_create_args(capacity, &num_buckets, errbuf)) return NULL;

    uint64_t total = cf_total_size(num_buckets);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { CF_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { CF_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { CF_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { CF_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(CfHeader)) {
            CF_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            CF_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { CF_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!cf_validate_header((CfHeader *)base, (uint64_t)st.st_size)) {
                CF_ERR("invalid Cuckoo filter file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return cf_setup(base, map_size, path, -1);
        }
    }
    cf_init_header(base, num_buckets, capacity, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return cf_setup(base, map_size, path, -1);
}

static CfHandle *cf_create_memfd(const char *name, uint64_t capacity, char *errbuf) {
    uint64_t num_buckets;
    if (!cf_validate_create_args(capacity, &num_buckets, errbuf)) return NULL;

    uint64_t total = cf_total_size(num_buckets);
    int fd = memfd_create(name ? name : "cuckoo", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { CF_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        CF_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { CF_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    cf_init_header(base, num_buckets, capacity, total);
    return cf_setup(base, (size_t)total, NULL, fd);
}

static CfHandle *cf_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { CF_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(CfHeader)) { CF_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { CF_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!cf_validate_header((CfHeader *)base, (uint64_t)st.st_size)) {
        CF_ERR("invalid Cuckoo filter table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { CF_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return cf_setup(base, ms, NULL, myfd);
}

static void cf_destroy(CfHandle *h) {
    if (!h) return;
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int cf_msync(CfHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Cuckoo filter operations (callers hold the lock)
 *
 * Partial-key cuckoo hashing from a single XXH3-128 hash: a 16-bit non-zero
 * fingerprint plus two candidate buckets i1 and i2 = alt(i1, fp), where alt is
 * an XOR-based involution so alt(alt(i,fp),fp) == i and i1 != i2.
 * ================================================================ */

/* xorshift64 victim-choice RNG; advances and stores hdr->rng_state.
 * Called only under the write lock. */
static inline uint64_t cf_rng_next(CfHandle *h) {
    uint64_t x = h->hdr->rng_state;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    h->hdr->rng_state = x;
    return x;
}

/* Spread a 16-bit fingerprint's bits across 64 bits (good integer mix). */
static inline uint64_t cf_fp_mix(uint16_t fp) {
    return (uint64_t)fp * 0x9e3779b97f4a7c15ULL;   /* golden-ratio mix; full 64 bits */
}

/* Alternate bucket for (i, fp): involutive XOR displacement masked to the
 * table. fh is forced non-zero so the alternate is always a different bucket
 * (i1 != i2). Since num_buckets is a power of two and fh < num_buckets,
 * i ^ fh stays < num_buckets, and alt(alt(i,fp),fp) == i. */
static inline uint64_t cf_alt(CfHandle *h, uint64_t i, uint16_t fp) {
    uint64_t mask = h->hdr->bucket_mask;
    uint64_t fh = cf_fp_mix(fp) & mask;
    if (fh == 0) fh = 1;
    return (i ^ fh) & mask;
}

/* pointer to bucket i's CF_SLOTS fingerprint slots */
static inline uint16_t *cf_bucket(CfHandle *h, uint64_t i) {
    return cf_slots(h) + i * (uint64_t)CF_SLOTS;
}

/* slot index of fp in bucket i, or -1 if absent */
static inline int cf_bucket_find(CfHandle *h, uint64_t i, uint16_t fp) {
    uint16_t *b = cf_bucket(h, i);
    for (int j = 0; j < CF_SLOTS; j++)
        if (b[j] == fp) return j;
    return -1;
}

/* place fp in a free (0) slot of bucket i: return 1 if placed, 0 if full */
static inline int cf_bucket_insert(CfHandle *h, uint64_t i, uint16_t fp) {
    uint16_t *b = cf_bucket(h, i);
    for (int j = 0; j < CF_SLOTS; j++) {
        if (b[j] == 0) { b[j] = fp; return 1; }
    }
    return 0;
}

/* derive the fingerprint and the two candidate buckets for (item,len) */
static inline void cf_hash(CfHandle *h, const void *item, size_t len,
                           uint16_t *fp_out, uint64_t *i1_out, uint64_t *i2_out) {
    XXH128_hash_t hh = XXH3_128bits(item, len);
    uint16_t fp = (uint16_t)(hh.high64 & 0xFFFF);
    if (fp == 0) fp = 1;                       /* 0 means empty slot; never use it */
    uint64_t i1 = (uint64_t)(hh.low64 & h->hdr->bucket_mask);
    *fp_out = fp;
    *i1_out = i1;
    *i2_out = cf_alt(h, i1, fp);
}

/* Add (item,len). Returns 1 on success, 0 if the table is full.
 *
 * ATOMIC: a failed add is a true no-op (the table is byte-identical to before),
 * so a failed add can never introduce a false negative -- every fingerprint
 * that was present stays present. The eviction path records every swap and
 * rolls them back in reverse if CF_MAX_KICKS is exhausted. */
static int cf_add_locked(CfHandle *h, const void *item, size_t len) {
    uint16_t fp;
    uint64_t i1, i2;
    cf_hash(h, item, len, &fp, &i1, &i2);

    if (cf_bucket_insert(h, i1, fp) || cf_bucket_insert(h, i2, fp)) {
        h->hdr->count++;
        return 1;
    }

    /* Both candidate buckets are full -> cuckoo eviction with a recorded
     * path so an exhausted run can be rolled back to a byte-identical state. */
    uint64_t path_i[CF_MAX_KICKS];
    uint8_t  path_j[CF_MAX_KICKS];
    uint64_t i = (cf_rng_next(h) & 1) ? i1 : i2;
    uint16_t carried = fp;
    for (int n = 0; n < CF_MAX_KICKS; n++) {
        uint8_t j = (uint8_t)(cf_rng_next(h) % CF_SLOTS);
        path_i[n] = i;
        path_j[n] = j;
        uint16_t tmp = cf_bucket(h, i)[j];      /* swap carried into slot j */
        cf_bucket(h, i)[j] = carried;
        carried = tmp;
        i = cf_alt(h, i, carried);              /* follow the evicted fingerprint */
        if (cf_bucket_insert(h, i, carried)) {  /* free slot in the new bucket? */
            h->hdr->count++;
            return 1;                           /* placed -> committed */
        }
    }
    /* Exhausted: roll back every swap in reverse so the table is unchanged.
     * After undoing step 0, carried == fp and nothing was modified. */
    for (int n = CF_MAX_KICKS - 1; n >= 0; n--) {
        uint16_t tmp = cf_bucket(h, path_i[n])[path_j[n]];
        cf_bucket(h, path_i[n])[path_j[n]] = carried;
        carried = tmp;
    }
    return 0;   /* full; NO state change */
}

/* return 1 if (item,len) is probably present, else 0 (definitely absent) */
static int cf_contains_locked(CfHandle *h, const void *item, size_t len) {
    uint16_t fp;
    uint64_t i1, i2;
    cf_hash(h, item, len, &fp, &i1, &i2);
    return cf_bucket_find(h, i1, fp) >= 0 || cf_bucket_find(h, i2, fp) >= 0;
}

/* remove ONE matching fingerprint of (item,len): clear the slot, return 1 if
 * found, else 0. Removing an item that was never added (or one whose 16-bit
 * fingerprint collides with a present item) can delete the wrong fingerprint --
 * standard cuckoo-filter caveat; only remove items you added. */
static int cf_remove_locked(CfHandle *h, const void *item, size_t len) {
    uint16_t fp;
    uint64_t i1, i2;
    cf_hash(h, item, len, &fp, &i1, &i2);
    int j = cf_bucket_find(h, i1, fp);
    if (j >= 0) { cf_bucket(h, i1)[j] = 0; h->hdr->count--; return 1; }
    j = cf_bucket_find(h, i2, fp);
    if (j >= 0) { cf_bucket(h, i2)[j] = 0; h->hdr->count--; return 1; }
    return 0;
}

/* reset all slots to 0, count = 0 (caller holds the write lock) */
static inline void cf_clear_locked(CfHandle *h) {
    memset(cf_slots(h), 0, (size_t)(h->hdr->num_buckets * (uint64_t)CF_SLOTS * sizeof(uint16_t)));
    h->hdr->count = 0;
}

#endif /* CUCKOO_H */
