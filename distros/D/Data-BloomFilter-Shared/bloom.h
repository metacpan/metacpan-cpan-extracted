/*
 * bloom.h -- Shared-memory Bloom filter for Linux
 *
 * Probabilistic set membership: tells you whether an item is "definitely not"
 * or "probably" in the set, in a fixed amount of memory, with a tunable false-
 * positive rate and no false negatives. Each item is hashed once (XXH3-128);
 * the two 64-bit halves drive k probe bits (Kirsch-Mitzenmacher double hashing)
 * into a power-of-two bit array. The bit array lives in a shared mapping so
 * several processes share one filter; a write-preferring futex rwlock with
 * reader-slot dead-process recovery guards mutation. Two filters of equal
 * geometry can be merged (bitwise OR -> union of memberships).
 *
 * Layout: Header -> reader_slots[1024] -> bits[m_bits/8]
 */

#ifndef BLOOM_H
#define BLOOM_H

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
#error "bloom.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define BF_MAGIC        0x4D4F4F42U  /* "BOOM" (little-endian) */
#define BF_VERSION      1
#define BF_ERR_BUFLEN   256
#define BF_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#define BF_MIN_BITS     64           /* floor on the bit array size (power of two) */
#define BF_MAX_BITS     0x4000000000ULL /* 2^38 bits = 32 GiB bit array cap */
#define BF_MIN_K        1
#define BF_MAX_K        32

#define BF_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, BF_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} BfReaderSlot;

struct BfHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t k;                       /* 8   number of hash probes per item */
    uint32_t _pad0;                   /* 12 */
    uint64_t m_bits;                  /* 16  bit array size in bits (power of two) */
    uint64_t m_mask;                  /* 24  m_bits - 1 (probe index mask) */
    uint64_t capacity;                /* 32  configured item capacity n (for stats) */
    double   fp_rate;                 /* 40  configured target false-positive rate (for stats) */
    uint64_t total_size;              /* 48 */
    uint64_t reader_slots_off;        /* 56 */
    uint64_t bits_off;                /* 64 */
    uint32_t rwlock;                  /* 72 */
    uint32_t rwlock_waiters;          /* 76 */
    uint32_t rwlock_writers_waiting;  /* 80 */
    uint32_t _pad1;                   /* 84 */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct BfHeader BfHeader;

_Static_assert(sizeof(BfHeader) == 256, "BfHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct BfHandle {
    BfHeader     *hdr;
    BfReaderSlot *reader_slots;  /* BF_READER_SLOTS entries */
    void         *base;          /* mmap base */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* bf_fork_gen value at last slot claim */
} BfHandle;

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define BF_RWLOCK_SPIN_LIMIT 32
#define BF_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void bf_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define BF_RWLOCK_WRITER_BIT 0x80000000U
#define BF_RWLOCK_PID_MASK   0x7FFFFFFFU
#define BF_RWLOCK_WR(pid)    (BF_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & BF_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
static inline int bf_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void bf_recover_stale_lock(BfHandle *h, uint32_t observed_rwlock) {
    BfHeader *hdr = h->hdr;
    uint32_t mypid = BF_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec bf_lock_timeout = { BF_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t bf_fork_gen = 1;
static pthread_once_t bf_atfork_once = PTHREAD_ONCE_INIT;
static void bf_on_fork_child(void) {
    __atomic_add_fetch(&bf_fork_gen, 1, __ATOMIC_RELAXED);
}
static void bf_atfork_init(void) {
    pthread_atfork(NULL, NULL, bf_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void bf_claim_reader_slot(BfHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&bf_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&bf_atfork_once, bf_atfork_init);
    /* Re-read after pthread_once: bf_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&bf_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % BF_READER_SLOTS;
    for (uint32_t i = 0; i < BF_READER_SLOTS; i++) {
        uint32_t s = (start + i) % BF_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and bf_recover_dead_readers won't drain them
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
static inline void bf_atomic_sub_cap(uint32_t *p, uint32_t sub) {
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
 * state.  bf_claim_reader_slot zeros all three on every claim, so
 * leaving stale values is harmless. */
static inline void bf_drain_dead_slot(BfHandle *h, uint32_t i, uint32_t pid) {
    BfHeader *hdr = h->hdr;
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
    if (wp)    bf_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) bf_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
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
static inline void bf_recover_dead_readers(BfHandle *h) {
    if (!h->reader_slots) return;
    BfHeader *hdr = h->hdr;
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
    for (uint32_t i = 0; i < BF_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (bf_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        bf_drain_dead_slot(h, i, pid);
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
        if (cur > 0 && cur < BF_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            }
        }
        for (uint32_t i = 0; i < BF_READER_SLOTS; i++) {
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            if (pid == 0 || bf_pid_alive(pid)) continue;
            bf_drain_dead_slot(h, i, pid);
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters.  Called from rdlock and wrlock ETIMEDOUT
 * branches -- identical recovery logic in both. */
static inline void bf_recover_after_timeout(BfHandle *h) {
    BfHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= BF_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & BF_RWLOCK_PID_MASK;
        if (!bf_pid_alive(pid))
            bf_recover_stale_lock(h, val);
    } else {
        bf_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution.  Kept paired to make
 * accidental drift between global and per-slot counts impossible. */
static inline void bf_park_reader(BfHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void bf_unpark_reader(BfHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void bf_park_writer(BfHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void bf_unpark_writer(BfHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void bf_rwlock_rdlock(BfHandle *h) {
    bf_claim_reader_slot(h);
    BfHeader *hdr = h->hdr;
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
        if (cur > 0 && cur < BF_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < BF_RWLOCK_SPIN_LIMIT, 1)) {
            bf_rwlock_spin_pause();
            continue;
        }
        bf_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= BF_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &bf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                bf_unpark_reader(h);
                bf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        bf_unpark_reader(h);
        spin = 0;
    }
}

static inline void bf_rwlock_rdunlock(BfHandle *h) {
    BfHeader *hdr = h->hdr;
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

static inline void bf_rwlock_wrlock(BfHandle *h) {
    bf_claim_reader_slot(h);  /* refresh cached_pid across fork */
    BfHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = BF_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < BF_RWLOCK_SPIN_LIMIT, 1)) {
            bf_rwlock_spin_pause();
            continue;
        }
        bf_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &bf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                bf_unpark_writer(h);
                bf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        bf_unpark_writer(h);
        spin = 0;
    }
}

static inline void bf_rwlock_wrunlock(BfHandle *h) {
    BfHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> bits[m_bits/8]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets. */
typedef struct { uint64_t reader_slots, bits; } BfLayout;

static inline BfLayout bf_layout(void) {
    BfLayout L;
    L.reader_slots = sizeof(BfHeader);
    L.bits         = L.reader_slots + (uint64_t)BF_READER_SLOTS * sizeof(BfReaderSlot);
    L.bits         = (L.bits + 7) & ~(uint64_t)7;   /* 8-byte align the bit array (uint64_t words) */
    return L;
}

static inline uint64_t bf_total_size(uint64_t m_bits) {
    BfLayout L = bf_layout();
    return L.bits + (m_bits / 8);   /* m_bits is a power of two >= 64 -> exact bytes */
}

/* round v up to the next power of two (64-bit), with a floor of BF_MIN_BITS */
static inline uint64_t bf_next_pow2_u64(uint64_t v) {
    if (v <= BF_MIN_BITS) return BF_MIN_BITS;
    return 1ULL << (64 - __builtin_clzll(v - 1));
}

static inline void bf_init_header(void *base, uint32_t k, uint64_t m_bits,
                                  uint64_t capacity, double fp_rate, uint64_t total) {
    BfLayout L = bf_layout();
    BfHeader *hdr = (BfHeader *)base;
    /* Explicitly zero the header + reader-slot region (lock-recovery state, like
       hll.h); the bit array relies on the fresh mapping being OS zero-filled. */
    memset(base, 0, (size_t)L.bits);
    hdr->magic            = BF_MAGIC;
    hdr->version          = BF_VERSION;
    hdr->k                = k;
    hdr->m_bits           = m_bits;
    hdr->m_mask           = m_bits - 1;
    hdr->capacity         = capacity;
    hdr->fp_rate          = fp_rate;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->bits_off         = L.bits;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint64_t *bf_bits(BfHandle *h) {
    return (uint64_t *)((char *)h->base + h->hdr->bits_off);
}

static inline BfHandle *bf_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    BfHeader *hdr = (BfHeader *)base;
    BfHandle *h = (BfHandle *)calloc(1, sizeof(BfHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (BfReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by bf_create reopen and bf_open_fd). */
static inline int bf_validate_header(const BfHeader *hdr, uint64_t file_size) {
    if (hdr->magic != BF_MAGIC) return 0;
    if (hdr->version != BF_VERSION) return 0;
    if (hdr->k < BF_MIN_K || hdr->k > BF_MAX_K) return 0;
    if (hdr->m_bits < BF_MIN_BITS || hdr->m_bits > BF_MAX_BITS) return 0;
    if ((hdr->m_bits & (hdr->m_bits - 1)) != 0) return 0;        /* power of two */
    if (hdr->m_mask != hdr->m_bits - 1) return 0;
    if (hdr->capacity == 0) return 0;
    if (!(hdr->fp_rate > 0.0 && hdr->fp_rate < 1.0)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != bf_total_size(hdr->m_bits)) return 0;
    BfLayout L = bf_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->bits_off != L.bits) return 0;
    return 1;
}

/* validate args + compute the geometry (k, m_bits) */
static int bf_validate_create_args(uint64_t capacity, double fp_rate,
                                   uint32_t *k_out, uint64_t *m_bits_out, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity < 1) { BF_ERR("capacity must be >= 1"); return 0; }
    if (!(fp_rate > 0.0 && fp_rate < 1.0)) { BF_ERR("fp_rate must be between 0 and 1 (exclusive)"); return 0; }

    /* k = round(-log2(fp_rate)) clamped to [1, 32] */
    long kl = lround(-log2(fp_rate));
    if (kl < BF_MIN_K) kl = BF_MIN_K;
    if (kl > BF_MAX_K) kl = BF_MAX_K;
    uint32_t k = (uint32_t)kl;

    /* m_opt = ceil(capacity * k / ln2); reject if it would exceed the bit-array
     * cap (otherwise the filter would be silently undersized -> fp_rate broken);
     * m_bits = next_pow2(m_opt), floor BF_MIN_BITS. */
    double m_opt_d = ceil((double)capacity * (double)k / M_LN2);
    if (m_opt_d > (double)BF_MAX_BITS) { BF_ERR("capacity too large for the bit-array cap"); return 0; }
    uint64_t m_bits = bf_next_pow2_u64((uint64_t)m_opt_d);

    *k_out = k;
    *m_bits_out = m_bits;
    return 1;
}

static BfHandle *bf_create(const char *path, uint64_t capacity, double fp_rate, char *errbuf) {
    uint32_t k;
    uint64_t m_bits;
    if (!bf_validate_create_args(capacity, fp_rate, &k, &m_bits, errbuf)) return NULL;

    uint64_t total = bf_total_size(m_bits);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { BF_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { BF_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { BF_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { BF_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(BfHeader)) {
            BF_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            BF_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { BF_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!bf_validate_header((BfHeader *)base, (uint64_t)st.st_size)) {
                BF_ERR("invalid Bloom filter file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return bf_setup(base, map_size, path, -1);
        }
    }
    bf_init_header(base, k, m_bits, capacity, fp_rate, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return bf_setup(base, map_size, path, -1);
}

static BfHandle *bf_create_memfd(const char *name, uint64_t capacity, double fp_rate, char *errbuf) {
    uint32_t k;
    uint64_t m_bits;
    if (!bf_validate_create_args(capacity, fp_rate, &k, &m_bits, errbuf)) return NULL;

    uint64_t total = bf_total_size(m_bits);
    int fd = memfd_create(name ? name : "bloom", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { BF_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        BF_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { BF_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    bf_init_header(base, k, m_bits, capacity, fp_rate, total);
    return bf_setup(base, (size_t)total, NULL, fd);
}

static BfHandle *bf_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { BF_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(BfHeader)) { BF_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { BF_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!bf_validate_header((BfHeader *)base, (uint64_t)st.st_size)) {
        BF_ERR("invalid Bloom filter table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { BF_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return bf_setup(base, ms, NULL, myfd);
}

static void bf_destroy(BfHandle *h) {
    if (!h) return;
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int bf_msync(BfHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Bloom filter operations (callers hold the lock) -- double hashing
 * (Kirsch-Mitzenmacher): one XXH3-128 hash drives all k probes.
 * ================================================================ */

static inline void bf_indices(BfHandle *h, const void *item, size_t len,
                              uint64_t *h1, uint64_t *h2) {
    (void)h;
    XXH128_hash_t hh = XXH3_128bits(item, len);
    *h1 = hh.low64;
    *h2 = hh.high64 | 1ULL;   /* force odd so the k probes spread over the pow2 table */
}

/* set k bits; return 1 if the item was probably NEW (at least one bit was 0), else 0 */
static int bf_add_locked(BfHandle *h, const void *item, size_t len) {
    uint64_t h1, h2;
    bf_indices(h, item, len, &h1, &h2);
    uint64_t mask = h->hdr->m_mask;
    uint32_t k = h->hdr->k;
    uint64_t *bits = bf_bits(h);
    int was_new = 0;
    for (uint32_t i = 0; i < k; i++) {
        uint64_t idx = (h1 + (uint64_t)i * h2) & mask;
        uint64_t word = idx >> 6;
        uint64_t bit  = 1ULL << (idx & 63);
        if (!(bits[word] & bit)) { bits[word] |= bit; was_new = 1; }
    }
    return was_new;
}

/* return 1 if ALL k bits are set (probably present), else 0 */
static int bf_contains_locked(BfHandle *h, const void *item, size_t len) {
    uint64_t h1, h2;
    bf_indices(h, item, len, &h1, &h2);
    uint64_t mask = h->hdr->m_mask;
    uint32_t k = h->hdr->k;
    uint64_t *bits = bf_bits(h);
    for (uint32_t i = 0; i < k; i++) {
        uint64_t idx = (h1 + (uint64_t)i * h2) & mask;
        uint64_t word = idx >> 6;
        uint64_t bit  = 1ULL << (idx & 63);
        if (!(bits[word] & bit)) return 0;
    }
    return 1;
}

/* count set bits across the whole array (caller holds a lock) */
static uint64_t bf_popcount_locked(BfHandle *h) {
    uint64_t *bits = bf_bits(h);
    uint64_t words = h->hdr->m_bits / 64;
    uint64_t n = 0;
    for (uint64_t i = 0; i < words; i++)
        n += (uint64_t)__builtin_popcountll(bits[i]);
    return n;
}

/* estimate the number of distinct items added, from a pre-computed popcount X.
   n_est = -(m/k) * ln(1 - X/m); saturated -> capacity. (caller holds a lock) */
static uint64_t bf_count_from_popcount(BfHandle *h, uint64_t X) {
    uint64_t m_bits = h->hdr->m_bits;
    uint32_t k = h->hdr->k;
    if (X >= m_bits) return h->hdr->capacity;     /* saturated */
    double n_est = -((double)m_bits / (double)k) * log(1.0 - (double)X / (double)m_bits);
    if (n_est < 0.0) n_est = 0.0;
    return (uint64_t)(n_est + 0.5);
}

/* estimate the number of distinct items added (popcounts the array). (caller holds a lock) */
static uint64_t bf_count_locked(BfHandle *h) {
    return bf_count_from_popcount(h, bf_popcount_locked(h));
}

/* merge src words into dst (caller guarantees equal m_bits); bitwise OR */
static void bf_merge_words(BfHandle *dst, const uint64_t *src_words) {
    uint64_t *bits = bf_bits(dst);
    uint64_t words = dst->hdr->m_bits / 64;
    for (uint64_t i = 0; i < words; i++)
        bits[i] |= src_words[i];
}

/* reset all bits to 0 (caller holds the write lock) */
static inline void bf_clear_locked(BfHandle *h) {
    memset(bf_bits(h), 0, (size_t)(h->hdr->m_bits / 8));
}

#endif /* BLOOM_H */
