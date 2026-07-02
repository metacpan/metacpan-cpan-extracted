/*
 * sortedset.h -- Shared-memory sorted set (ZSET) for Linux
 *
 * int64 members ordered by a double score on an order-statistics B+tree (keyed
 * by the total order (score, member); per-child subtree counts give O(log n)
 * rank; doubly-linked leaves give sequential range scans), plus a member->score
 * open-addressed hash index for O(1) lookup by member. Nodes and index slots
 * live in fixed pools. A write-preferring futex rwlock with reader-slot
 * dead-process recovery guards mutations.
 *
 * Layout: Header -> reader_slots[1024] -> member_index -> node_pool
 */

#ifndef SORTEDSET_H
#define SORTEDSET_H

#include <stdint.h>
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
#include <pthread.h>

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "sortedset.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define SS_MAGIC        0x53534554U  /* "SSET" */
#define SS_VERSION      1
#define SS_NONE         UINT32_MAX
#define SS_ERR_BUFLEN   256
#define SS_READER_SLOTS 1024  /* max concurrent reader processes for dead-process recovery */

#define SS_ORDER 16              /* B+tree fanout: max children / max leaf entries */
#define SS_MIN   (SS_ORDER / 2)  /* min children/entries except the root */

#define SS_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, SS_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

/* ================================================================
 * Structs
 * ================================================================ */

/* B+tree node (one pool, one size). Leaf (is_leaf=1): up to SS_ORDER
   (score,member) entries in key order, doubly-linked via next/prev. Internal:
   up to SS_ORDER children with SS_ORDER-1 separators (scores/members) and
   per-child subtree entry counts (order-statistics, for rank). Parallel arrays
   so the in-node binary search scans packed scores. Free nodes thread the
   free-list through `parent`. */
/* arrays are SS_ORDER+1 to hold the transient overflow during a split */
typedef struct {
    uint16_t num;                    /* leaf: #entries; internal: #children */
    uint8_t  is_leaf;
    uint8_t  _pad;
    uint32_t parent;                 /* SS_NONE for root; free-list link when free */
    uint32_t next, prev;             /* leaf sibling links (SS_NONE at the ends) */
    double   scores[SS_ORDER + 1];   /* leaf entries / internal separators (num-1 used) */
    int64_t  members[SS_ORDER + 1];
    uint32_t children[SS_ORDER + 1]; /* internal child node idx */
    uint32_t counts[SS_ORDER + 1];   /* internal per-child subtree entry counts */
} SsNode;

/* member -> score open-addressed hash index slot (backward-shift delete) */
typedef struct {
    int64_t member;
    double  score;
    uint8_t state;                 /* 0 empty, 1 occupied */
} SsIdxSlot;

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
} SsReaderSlot;

struct SsHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t max_entries;             /* 8   entry capacity */
    uint32_t node_capacity;           /* 12  node-pool size */
    uint32_t index_slots;             /* 16  member-index slots (power of two) */
    uint32_t count;                   /* 20  live entries */
    uint64_t total_size;              /* 24 */
    uint64_t reader_slots_off;        /* 32 */
    uint64_t index_off;               /* 40 */
    uint64_t nodes_off;               /* 48 */
    uint32_t root;                    /* 56  root node idx (SS_NONE if empty) */
    uint32_t height;                  /* 60  tree height (0 = empty) */
    uint32_t leftmost;                /* 64  leftmost leaf idx */
    uint32_t rightmost;               /* 68  rightmost leaf idx */
    uint32_t node_free_head;          /* 72 */
    uint32_t rwlock;                  /* 76 */
    uint32_t rwlock_waiters;          /* 80 */
    uint32_t rwlock_writers_waiting;  /* 84 */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct SsHeader SsHeader;

_Static_assert(sizeof(SsHeader) == 256, "SsHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct SsHandle {
    SsHeader     *hdr;
    SsReaderSlot *reader_slots;  /* SS_READER_SLOTS entries */
    SsIdxSlot    *index;         /* member -> score */
    SsNode       *nodes;         /* B+tree node pool */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           notify_fd;
    int           backing_fd;    /* memfd fd to close on destroy, -1 otherwise */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* ss_fork_gen value at last slot claim */
} SsHandle;

/* ================================================================
 * Helpers
 * ================================================================ */

static inline uint32_t ss_next_pow2(uint32_t v) {
    if (v < 2) return 1;
    return 1u << (32 - __builtin_clz(v - 1));
}

/* member hash: splitmix64 finalizer (good avalanche for int64 keys) */
static inline uint64_t ss_hash_member(int64_t m) {
    uint64_t x = (uint64_t)m + 0x9E3779B97F4A7C15ULL;
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ULL;
    x = (x ^ (x >> 27)) * 0x94D049BB133111EBULL;
    return x ^ (x >> 31);
}

/* total order on (score, member): -1 / 0 / +1 */
static inline int ss_key_cmp(double sa, int64_t ma, double sb, int64_t mb) {
    if (sa < sb) return -1;
    if (sa > sb) return  1;
    return (ma < mb) ? -1 : (ma > mb) ? 1 : 0;
}

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define SS_RWLOCK_SPIN_LIMIT 32
#define SS_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void ss_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define SS_RWLOCK_WRITER_BIT 0x80000000U
#define SS_RWLOCK_PID_MASK   0x7FFFFFFFU
#define SS_RWLOCK_WR(pid)    (SS_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & SS_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
static inline int ss_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void ss_recover_stale_lock(SsHandle *h, uint32_t observed_rwlock) {
    SsHeader *hdr = h->hdr;
    uint32_t mypid = SS_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec ss_lock_timeout = { SS_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t ss_fork_gen = 1;
static pthread_once_t ss_atfork_once = PTHREAD_ONCE_INIT;
static void ss_on_fork_child(void) {
    __atomic_add_fetch(&ss_fork_gen, 1, __ATOMIC_RELAXED);
}
static void ss_atfork_init(void) {
    pthread_atfork(NULL, NULL, ss_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void ss_claim_reader_slot(SsHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&ss_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&ss_atfork_once, ss_atfork_init);
    /* Re-read after pthread_once: ss_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&ss_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % SS_READER_SLOTS;
    for (uint32_t i = 0; i < SS_READER_SLOTS; i++) {
        uint32_t s = (start + i) % SS_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and ss_recover_dead_readers won't drain them
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
static inline void ss_atomic_sub_cap(uint32_t *p, uint32_t sub) {
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
 * state.  ss_claim_reader_slot zeros all three on every claim, so
 * leaving stale values is harmless. */
static inline void ss_drain_dead_slot(SsHandle *h, uint32_t i, uint32_t pid) {
    SsHeader *hdr = h->hdr;
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
    if (wp)    ss_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) ss_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
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
static inline void ss_recover_dead_readers(SsHandle *h) {
    if (!h->reader_slots) return;
    SsHeader *hdr = h->hdr;
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
    for (uint32_t i = 0; i < SS_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (ss_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        ss_drain_dead_slot(h, i, pid);
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
        if (cur > 0 && cur < SS_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            }
        }
        for (uint32_t i = 0; i < SS_READER_SLOTS; i++) {
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            if (pid == 0 || ss_pid_alive(pid)) continue;
            ss_drain_dead_slot(h, i, pid);
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters.  Called from rdlock and wrlock ETIMEDOUT
 * branches -- identical recovery logic in both. */
static inline void ss_recover_after_timeout(SsHandle *h) {
    SsHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= SS_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & SS_RWLOCK_PID_MASK;
        if (!ss_pid_alive(pid))
            ss_recover_stale_lock(h, val);
    } else {
        ss_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution.  Kept paired to make
 * accidental drift between global and per-slot counts impossible. */
static inline void ss_park_reader(SsHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void ss_unpark_reader(SsHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void ss_park_writer(SsHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void ss_unpark_writer(SsHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void ss_rwlock_rdlock(SsHandle *h) {
    ss_claim_reader_slot(h);
    SsHeader *hdr = h->hdr;
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
        if (cur > 0 && cur < SS_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < SS_RWLOCK_SPIN_LIMIT, 1)) {
            ss_rwlock_spin_pause();
            continue;
        }
        ss_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= SS_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &ss_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                ss_unpark_reader(h);
                ss_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        ss_unpark_reader(h);
        spin = 0;
    }
}

static inline void ss_rwlock_rdunlock(SsHandle *h) {
    SsHeader *hdr = h->hdr;
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

static inline void ss_rwlock_wrlock(SsHandle *h) {
    ss_claim_reader_slot(h);  /* refresh cached_pid across fork */
    SsHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = SS_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < SS_RWLOCK_SPIN_LIMIT, 1)) {
            ss_rwlock_spin_pause();
            continue;
        }
        ss_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &ss_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                ss_unpark_writer(h);
                ss_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        ss_unpark_writer(h);
        spin = 0;
    }
}

static inline void ss_rwlock_wrunlock(SsHandle *h) {
    SsHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> member_index -> node_pool
 * ================================================================ */

/* Largest max_entries accepted at create time. 2^30 keeps the index-slot
 * power-of-two rounding (ss_next_pow2) and every byte offset well within
 * range, and is far beyond any realistic shared-memory map. */
#define SS_MAX_CAPACITY 0x40000000u

/* Single source of truth for the mmap region layout offsets. */
typedef struct { uint64_t reader_slots, index, nodes; } SsLayout;

static inline SsLayout ss_layout(uint32_t index_slots) {
    SsLayout L;
    L.reader_slots = sizeof(SsHeader);
    L.index        = L.reader_slots + (uint64_t)SS_READER_SLOTS * sizeof(SsReaderSlot);
    L.nodes        = L.index + (uint64_t)index_slots * sizeof(SsIdxSlot);
    L.nodes        = (L.nodes + 7) & ~(uint64_t)7;   /* 8-byte align the node pool */
    return L;
}

static inline uint64_t ss_total_size(uint32_t index_slots, uint32_t node_capacity) {
    SsLayout L = ss_layout(index_slots);
    return L.nodes + (uint64_t)node_capacity * sizeof(SsNode);
}

static inline void ss_init_header(void *base, uint32_t max_entries, uint32_t index_slots,
                                  uint32_t node_capacity, uint64_t total) {
    SsLayout L = ss_layout(index_slots);
    SsHeader *hdr = (SsHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic            = SS_MAGIC;
    hdr->version          = SS_VERSION;
    hdr->max_entries      = max_entries;
    hdr->node_capacity    = node_capacity;
    hdr->index_slots      = index_slots;
    hdr->count            = 0;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->index_off        = L.index;
    hdr->nodes_off        = L.nodes;
    hdr->root             = SS_NONE;   /* empty tree */
    hdr->height           = 0;
    hdr->leftmost         = SS_NONE;
    hdr->rightmost        = SS_NONE;

    /* Thread the node free-list through `parent`. */
    SsNode *nodes = (SsNode *)((uint8_t *)base + L.nodes);
    for (uint32_t i = 0; i < node_capacity; i++)
        nodes[i].parent = (i + 1 < node_capacity) ? (i + 1) : SS_NONE;
    hdr->node_free_head = 0;
    /* index region left zeroed: every slot empty (state == 0). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline SsHandle *ss_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    SsHeader *hdr = (SsHeader *)base;
    SsHandle *h = (SsHandle *)calloc(1, sizeof(SsHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->reader_slots = (SsReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
    h->index        = (SsIdxSlot *)((uint8_t *)base + hdr->index_off);
    h->nodes        = (SsNode *)((uint8_t *)base + hdr->nodes_off);
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->notify_fd    = -1;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by ss_create reopen and ss_open_fd). */
static inline int ss_validate_header(const SsHeader *hdr, uint64_t file_size) {
    if (hdr->magic != SS_MAGIC) return 0;
    if (hdr->version != SS_VERSION) return 0;
    if (hdr->max_entries == 0 || hdr->max_entries > SS_MAX_CAPACITY) return 0;
    if (hdr->index_slots == 0 || (hdr->index_slots & (hdr->index_slots - 1)) != 0) return 0; /* pow2 */
    if (hdr->node_capacity == 0) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != ss_total_size(hdr->index_slots, hdr->node_capacity)) return 0;
    SsLayout L = ss_layout(hdr->index_slots);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->index_off        != L.index)        return 0;
    if (hdr->nodes_off        != L.nodes)        return 0;
    if (hdr->count > hdr->max_entries) return 0;
    if (hdr->root != SS_NONE && hdr->root >= hdr->node_capacity) return 0;
    if (hdr->root == SS_NONE && hdr->count != 0) return 0;
    return 1;
}


/* validate max_entries and compute the index-slot count + node-pool capacity
   (shared by ss_create + ss_create_memfd) */
static int ss_validate_create_args(uint32_t max_entries, uint32_t *index_slots,
                                   uint32_t *node_capacity, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (max_entries == 0) { SS_ERR("max_entries must be > 0"); return 0; }
    if (max_entries > SS_MAX_CAPACITY) { SS_ERR("max_entries too large (max %u)", SS_MAX_CAPACITY); return 0; }
    uint64_t want = (uint64_t)max_entries * 10 / 7 + 1;        /* index load factor ~0.7 */
    if (want > SS_MAX_CAPACITY) want = SS_MAX_CAPACITY;
    *index_slots   = ss_next_pow2((uint32_t)want);
    *node_capacity = (uint32_t)((uint64_t)max_entries / (SS_MIN - 1) + 64); /* worst-case fill + slack */
    return 1;
}

static SsHandle *ss_create(const char *path, uint32_t max_entries, char *errbuf) {
    uint32_t index_slots, node_capacity;
    if (!ss_validate_create_args(max_entries, &index_slots, &node_capacity, errbuf)) return NULL;

    uint64_t total = ss_total_size(index_slots, node_capacity);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { SS_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { SS_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { SS_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { SS_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(SsHeader)) {
            SS_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            SS_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { SS_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!ss_validate_header((SsHeader *)base, (uint64_t)st.st_size)) {
                SS_ERR("invalid sorted-set file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return ss_setup(base, map_size, path, -1);
        }
    }
    ss_init_header(base, max_entries, index_slots, node_capacity, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return ss_setup(base, map_size, path, -1);
}

static SsHandle *ss_create_memfd(const char *name, uint32_t max_entries, char *errbuf) {
    uint32_t index_slots, node_capacity;
    if (!ss_validate_create_args(max_entries, &index_slots, &node_capacity, errbuf)) return NULL;

    uint64_t total = ss_total_size(index_slots, node_capacity);
    int fd = memfd_create(name ? name : "sortedset", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { SS_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        SS_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { SS_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    ss_init_header(base, max_entries, index_slots, node_capacity, total);
    return ss_setup(base, (size_t)total, NULL, fd);
}

static SsHandle *ss_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { SS_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(SsHeader)) { SS_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { SS_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!ss_validate_header((SsHeader *)base, (uint64_t)st.st_size)) {
        SS_ERR("invalid sorted-set"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { SS_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return ss_setup(base, ms, NULL, myfd);
}

static void ss_destroy(SsHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int ss_msync(SsHandle *h) {
    if (!h || !h->hdr) return 0;
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

static int ss_create_eventfd(SsHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    int efd = eventfd(0, EFD_NONBLOCK|EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd;
    return efd;
}

static int ss_notify(SsHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t v = 1;
    return write(h->notify_fd, &v, sizeof(v)) == sizeof(v);
}

static int64_t ss_eventfd_consume(SsHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t v = 0;
    if (read(h->notify_fd, &v, sizeof(v)) != sizeof(v)) return -1;
    return (int64_t)v;
}

/* ================================================================
 * Sorted set: node pool, member index, B+tree (callers hold the lock)
 * ================================================================ */

/* reset to the empty set (caller holds the write lock) */
static inline void ss_clear_locked(SsHandle *h) {
    SsHeader *hdr = h->hdr;
    hdr->count     = 0;
    hdr->root      = SS_NONE;
    hdr->height    = 0;
    hdr->leftmost  = SS_NONE;
    hdr->rightmost = SS_NONE;
    for (uint32_t i = 0; i < hdr->node_capacity; i++)
        h->nodes[i].parent = (i + 1 < hdr->node_capacity) ? (i + 1) : SS_NONE;
    hdr->node_free_head = 0;
    memset(h->index, 0, (size_t)hdr->index_slots * sizeof(SsIdxSlot));
}

/* ---- node pool ---- */
static inline uint32_t ss_node_alloc(SsHandle *h) {
    uint32_t idx = h->hdr->node_free_head;
    if (idx == SS_NONE) return SS_NONE;
    h->hdr->node_free_head = h->nodes[idx].parent;
    return idx;
}
static inline void ss_node_free(SsHandle *h, uint32_t idx) {
    h->nodes[idx].parent = h->hdr->node_free_head;
    h->hdr->node_free_head = idx;
}

/* ---- member -> score index (open addressing, linear probe) ---- */
/* returns the slot of `member` (if present) or the first empty slot for it;
   *found (optional, may be NULL) says which */
static inline uint32_t ss_idx_find(SsHandle *h, int64_t member, int *found) {
    uint32_t mask = h->hdr->index_slots - 1;
    uint32_t i = (uint32_t)(ss_hash_member(member) & mask);
    while (h->index[i].state) {
        if (h->index[i].member == member) { if (found) *found = 1; return i; }
        i = (i + 1) & mask;
    }
    if (found) *found = 0;
    return i;
}
static inline int ss_idx_get(SsHandle *h, int64_t member, double *score) {
    int f; uint32_t i = ss_idx_find(h, member, &f);
    if (f) { *score = h->index[i].score; return 1; }
    return 0;
}
static inline void ss_idx_set(SsHandle *h, int64_t member, double score) {
    uint32_t i = ss_idx_find(h, member, NULL);
    h->index[i].member = member;
    h->index[i].score  = score;
    h->index[i].state  = 1;
}

/* ---- B+tree ---- */
static inline uint32_t ss_node_total(const SsNode *nd) {
    if (nd->is_leaf) return nd->num;
    uint32_t t = 0;
    for (int i = 0; i < nd->num; i++) t += nd->counts[i];
    return t;
}

/* child index in an internal node whose subtree would hold (score,member) */
static inline int ss_child_index(const SsNode *nd, double score, int64_t member) {
    int lo = 0, hi = nd->num - 1;
    while (lo < hi) {
        int mid = (lo + hi) / 2;
        if (ss_key_cmp(score, member, nd->scores[mid], nd->members[mid]) < 0) hi = mid;
        else lo = mid + 1;
    }
    return lo;
}

typedef struct { int split; uint32_t rnode; double rscore; int64_t rmember; } SsSplit;

/* insert (score,member) into subtree nidx (member known absent); on overflow
   split and return the new right node + separator to promote; maintains counts */
static SsSplit ss_insert_rec(SsHandle *h, uint32_t nidx, double score, int64_t member) {
    SsNode *nd = &h->nodes[nidx];
    SsSplit r = { 0, SS_NONE, 0.0, 0 };
    if (nd->is_leaf) {
        int pos = 0;
        while (pos < nd->num && ss_key_cmp(nd->scores[pos], nd->members[pos], score, member) < 0) pos++;
        for (int i = nd->num; i > pos; i--) { nd->scores[i] = nd->scores[i-1]; nd->members[i] = nd->members[i-1]; }
        nd->scores[pos] = score; nd->members[pos] = member; nd->num++;
        if (nd->num <= SS_ORDER) return r;
        uint32_t ridx = ss_node_alloc(h);
        SsNode *rn = &h->nodes[ridx];
        rn->is_leaf = 1; rn->parent = nd->parent;
        int mid = nd->num / 2, rc = nd->num - mid;
        for (int i = 0; i < rc; i++) { rn->scores[i] = nd->scores[mid+i]; rn->members[i] = nd->members[mid+i]; }
        rn->num = (uint16_t)rc; nd->num = (uint16_t)mid;
        rn->next = nd->next; rn->prev = nidx;
        if (nd->next != SS_NONE) h->nodes[nd->next].prev = ridx; else h->hdr->rightmost = ridx;
        nd->next = ridx;
        r.split = 1; r.rnode = ridx; r.rscore = rn->scores[0]; r.rmember = rn->members[0];
        return r;
    }
    int c = ss_child_index(nd, score, member);
    SsSplit cr = ss_insert_rec(h, nd->children[c], score, member);
    if (!cr.split) { nd->counts[c]++; return r; }
    for (int i = nd->num; i > c + 1; i--) { nd->children[i] = nd->children[i-1]; nd->counts[i] = nd->counts[i-1]; }
    for (int i = nd->num - 1; i > c; i--) { nd->scores[i] = nd->scores[i-1]; nd->members[i] = nd->members[i-1]; }
    nd->scores[c] = cr.rscore; nd->members[c] = cr.rmember;
    nd->children[c+1] = cr.rnode; h->nodes[cr.rnode].parent = nidx;
    nd->num++;
    nd->counts[c]   = ss_node_total(&h->nodes[nd->children[c]]);
    nd->counts[c+1] = ss_node_total(&h->nodes[cr.rnode]);
    if (nd->num <= SS_ORDER) return r;
    uint32_t ridx = ss_node_alloc(h);
    SsNode *rn = &h->nodes[ridx];
    rn->is_leaf = 0; rn->parent = nd->parent;
    int midc = nd->num / 2, rch = nd->num - midc;
    for (int i = 0; i < rch; i++) {
        rn->children[i] = nd->children[midc+i];
        rn->counts[i]   = nd->counts[midc+i];
        h->nodes[rn->children[i]].parent = ridx;
    }
    for (int i = 0; i < rch - 1; i++) { rn->scores[i] = nd->scores[midc+i]; rn->members[i] = nd->members[midc+i]; }
    rn->num = (uint16_t)rch;
    double up_s = nd->scores[midc-1]; int64_t up_m = nd->members[midc-1];
    nd->num = (uint16_t)midc;
    r.split = 1; r.rnode = ridx; r.rscore = up_s; r.rmember = up_m;
    return r;
}

static void ss_tree_add(SsHandle *h, double score, int64_t member) {
    SsHeader *hdr = h->hdr;
    if (hdr->root == SS_NONE) {
        uint32_t l = ss_node_alloc(h);
        SsNode *nd = &h->nodes[l];
        nd->is_leaf = 1; nd->parent = SS_NONE; nd->next = SS_NONE; nd->prev = SS_NONE;
        nd->num = 1; nd->scores[0] = score; nd->members[0] = member;
        hdr->root = l; hdr->leftmost = l; hdr->rightmost = l; hdr->height = 1;
        hdr->count++;
        return;
    }
    SsSplit r = ss_insert_rec(h, hdr->root, score, member);
    if (r.split) {
        uint32_t nr = ss_node_alloc(h);
        SsNode *root = &h->nodes[nr];
        root->is_leaf = 0; root->parent = SS_NONE; root->num = 2;
        root->children[0] = hdr->root; root->children[1] = r.rnode;
        root->scores[0] = r.rscore; root->members[0] = r.rmember;
        root->counts[0] = ss_node_total(&h->nodes[hdr->root]);
        root->counts[1] = ss_node_total(&h->nodes[r.rnode]);
        h->nodes[hdr->root].parent = nr;
        h->nodes[r.rnode].parent = nr;
        hdr->root = nr; hdr->height++;
    }
    hdr->count++;
}

/* index backward-shift deletion (keeps probe sequences contiguous) */
static void ss_idx_del(SsHandle *h, int64_t member) {
    uint32_t mask = h->hdr->index_slots - 1;
    int f; uint32_t i = ss_idx_find(h, member, &f);
    if (!f) return;
    uint32_t j = i;
    for (;;) {
        j = (j + 1) & mask;
        if (!h->index[j].state) break;
        uint32_t k = (uint32_t)(ss_hash_member(h->index[j].member) & mask);
        int in = (i < j) ? (i < k && k <= j) : (k > i || k <= j);  /* k in (i, j] ? */
        if (!in) { h->index[i] = h->index[j]; i = j; }
    }
    h->index[i].state = 0;
}

/* merge children[c] and children[c+1] of pidx into children[c]; frees the right
   node and pulls separator c down (for internal nodes) */
static void ss_merge(SsHandle *h, uint32_t pidx, int c) {
    SsNode *p = &h->nodes[pidx];
    uint32_t lidx = p->children[c], ridx = p->children[c+1];
    SsNode *ln = &h->nodes[lidx], *rn = &h->nodes[ridx];
    if (ln->is_leaf) {
        for (int i = 0; i < rn->num; i++) { ln->scores[ln->num+i] = rn->scores[i]; ln->members[ln->num+i] = rn->members[i]; }
        ln->next = rn->next;
        if (rn->next != SS_NONE) h->nodes[rn->next].prev = lidx; else h->hdr->rightmost = lidx;
        ln->num = (uint16_t)(ln->num + rn->num);
    } else {
        ln->scores[ln->num-1] = p->scores[c]; ln->members[ln->num-1] = p->members[c];   /* pull separator down */
        for (int i = 0; i < rn->num; i++) { ln->children[ln->num+i] = rn->children[i]; ln->counts[ln->num+i] = rn->counts[i]; h->nodes[rn->children[i]].parent = lidx; }
        for (int i = 0; i < rn->num - 1; i++) { ln->scores[ln->num+i] = rn->scores[i]; ln->members[ln->num+i] = rn->members[i]; }
        ln->num = (uint16_t)(ln->num + rn->num);
    }
    p->counts[c] += p->counts[c+1];
    for (int i = c+1; i+1 < p->num; i++) { p->children[i] = p->children[i+1]; p->counts[i] = p->counts[i+1]; }
    for (int i = c;   i+1 < p->num-1; i++) { p->scores[i] = p->scores[i+1]; p->members[i] = p->members[i+1]; }
    p->num--;
    ss_node_free(h, ridx);
}

/* fix an underflow in children[c] of pidx by borrowing from a sibling or merging */
static void ss_fix_underflow(SsHandle *h, uint32_t pidx, int c) {
    SsNode *p = &h->nodes[pidx];
    uint32_t cidx = p->children[c];
    SsNode *cn = &h->nodes[cidx];
    if (c > 0) {
        uint32_t lidx = p->children[c-1]; SsNode *ln = &h->nodes[lidx];
        if (ln->num > SS_MIN) {                       /* borrow from left */
            if (cn->is_leaf) {
                for (int i = cn->num; i > 0; i--) { cn->scores[i] = cn->scores[i-1]; cn->members[i] = cn->members[i-1]; }
                cn->scores[0] = ln->scores[ln->num-1]; cn->members[0] = ln->members[ln->num-1];
                cn->num++; ln->num--;
                p->scores[c-1] = cn->scores[0]; p->members[c-1] = cn->members[0];
                p->counts[c-1]--; p->counts[c]++;
            } else {
                uint32_t moved = ln->counts[ln->num-1];
                for (int i = cn->num; i > 0; i--) { cn->children[i] = cn->children[i-1]; cn->counts[i] = cn->counts[i-1]; }
                for (int i = cn->num-1; i > 0; i--) { cn->scores[i] = cn->scores[i-1]; cn->members[i] = cn->members[i-1]; }
                cn->scores[0] = p->scores[c-1]; cn->members[0] = p->members[c-1];
                cn->children[0] = ln->children[ln->num-1]; cn->counts[0] = moved;
                h->nodes[cn->children[0]].parent = cidx;
                cn->num++;
                p->scores[c-1] = ln->scores[ln->num-2]; p->members[c-1] = ln->members[ln->num-2];
                ln->num--;
                p->counts[c-1] -= moved; p->counts[c] += moved;
            }
            return;
        }
    }
    if (c < p->num - 1) {
        uint32_t ridx = p->children[c+1]; SsNode *rn = &h->nodes[ridx];
        if (rn->num > SS_MIN) {                       /* borrow from right */
            if (cn->is_leaf) {
                cn->scores[cn->num] = rn->scores[0]; cn->members[cn->num] = rn->members[0]; cn->num++;
                for (int i = 0; i+1 < rn->num; i++) { rn->scores[i] = rn->scores[i+1]; rn->members[i] = rn->members[i+1]; }
                rn->num--;
                p->scores[c] = rn->scores[0]; p->members[c] = rn->members[0];
                p->counts[c]++; p->counts[c+1]--;
            } else {
                uint32_t moved = rn->counts[0];
                cn->scores[cn->num-1] = p->scores[c]; cn->members[cn->num-1] = p->members[c];
                cn->children[cn->num] = rn->children[0]; cn->counts[cn->num] = moved;
                h->nodes[cn->children[cn->num]].parent = cidx;
                cn->num++;
                p->scores[c] = rn->scores[0]; p->members[c] = rn->members[0];
                for (int i = 0; i+1 < rn->num; i++) { rn->children[i] = rn->children[i+1]; rn->counts[i] = rn->counts[i+1]; }
                for (int i = 0; i+1 < rn->num-1; i++) { rn->scores[i] = rn->scores[i+1]; rn->members[i] = rn->members[i+1]; }
                rn->num--;
                p->counts[c] += moved; p->counts[c+1] -= moved;
            }
            return;
        }
    }
    ss_merge(h, pidx, (c > 0) ? c - 1 : c);           /* merge with a sibling */
}

/* delete (score,member) from subtree nidx (known present); decrement counts;
   return 1 if nidx now underflows (num < SS_MIN) */
static int ss_delete_rec(SsHandle *h, uint32_t nidx, double score, int64_t member) {
    SsNode *nd = &h->nodes[nidx];
    if (nd->is_leaf) {
        int pos = 0;
        while (pos < nd->num && ss_key_cmp(nd->scores[pos], nd->members[pos], score, member) != 0) pos++;
        for (int i = pos; i+1 < nd->num; i++) { nd->scores[i] = nd->scores[i+1]; nd->members[i] = nd->members[i+1]; }
        nd->num--;
        return nd->num < SS_MIN;
    }
    int c = ss_child_index(nd, score, member);
    int under = ss_delete_rec(h, nd->children[c], score, member);
    nd->counts[c]--;
    if (under) ss_fix_underflow(h, nidx, c);
    return nd->num < SS_MIN;
}

static void ss_tree_del(SsHandle *h, double score, int64_t member) {
    SsHeader *hdr = h->hdr;
    ss_delete_rec(h, hdr->root, score, member);
    SsNode *root = &h->nodes[hdr->root];
    if (root->is_leaf) {
        if (root->num == 0) {
            ss_node_free(h, hdr->root);
            hdr->root = SS_NONE; hdr->leftmost = SS_NONE; hdr->rightmost = SS_NONE; hdr->height = 0;
        }
    } else if (root->num == 1) {
        uint32_t child = root->children[0];
        ss_node_free(h, hdr->root);
        hdr->root = child; h->nodes[child].parent = SS_NONE; hdr->height--;
    }
    hdr->count--;
}

/* add: 1 (new), 0 (existing -- score updated if changed), -1 (full) */
static int ss_add_locked(SsHandle *h, int64_t member, double score) {
    double old;
    if (ss_idx_get(h, member, &old)) {
        if (old != score) { ss_tree_del(h, old, member); ss_tree_add(h, score, member); ss_idx_set(h, member, score); }
        return 0;
    }
    if (h->hdr->count >= h->hdr->max_entries) return -1;
    ss_tree_add(h, score, member);
    ss_idx_set(h, member, score);
    return 1;
}

/* remove: 1 if removed, 0 if absent */
static int ss_remove_locked(SsHandle *h, int64_t member) {
    double old;
    if (!ss_idx_get(h, member, &old)) return 0;
    ss_tree_del(h, old, member);
    ss_idx_del(h, member);
    return 1;
}

/* incr by delta. *out = new score. returns 1 (created), 0 (updated), -1 (full),
   -2 (result is NaN) */
static int ss_incr_locked(SsHandle *h, int64_t member, double delta, double *out) {
    double old;
    if (ss_idx_get(h, member, &old)) {
        double ns = old + delta; *out = ns;
        if (ns != ns) return -2;
        if (ns != old) { ss_tree_del(h, old, member); ss_tree_add(h, ns, member); ss_idx_set(h, member, ns); }
        return 0;
    }
    if (h->hdr->count >= h->hdr->max_entries) return -1;
    *out = delta;
    if (delta != delta) return -2;
    ss_tree_add(h, delta, member); ss_idx_set(h, member, delta);
    return 1;
}

/* pop the min (max=0) or max (max=1): 0 if empty, else 1 with *m,*s */
static int ss_pop_locked(SsHandle *h, int max, int64_t *m, double *s) {
    if (h->hdr->root == SS_NONE) return 0;
    SsNode *nd = &h->nodes[max ? h->hdr->rightmost : h->hdr->leftmost];
    int pos = max ? nd->num - 1 : 0;
    *m = nd->members[pos]; *s = nd->scores[pos];
    ss_tree_del(h, *s, *m);
    ss_idx_del(h, *m);
    return 1;
}

/* ---- structural validator (debug / tests) ---- */
static long ss_check_rec(SsHandle *h, uint32_t nidx, int depth, int is_root,
                         double *ps, int64_t *pm, int *hp, int *leaf_depth) {
    SsNode *nd = &h->nodes[nidx];
    if (nd->num < 1 || nd->num > SS_ORDER) return -1;
    if (!is_root && nd->num < SS_MIN) return -1;
    if (nd->is_leaf) {
        if (*leaf_depth < 0) *leaf_depth = depth;
        else if (*leaf_depth != depth) return -1;
        for (int i = 0; i < nd->num; i++) {
            if (*hp && ss_key_cmp(*ps, *pm, nd->scores[i], nd->members[i]) >= 0) return -1;
            *ps = nd->scores[i]; *pm = nd->members[i]; *hp = 1;
        }
        return nd->num;
    }
    long total = 0;
    for (int i = 0; i < nd->num; i++) {
        long c = ss_check_rec(h, nd->children[i], depth + 1, 0, ps, pm, hp, leaf_depth);
        if (c < 0 || (uint32_t)c != nd->counts[i]) return -1;
        total += c;
    }
    return total;
}
static int ss_validate_tree(SsHandle *h) {
    SsHeader *hdr = h->hdr;
    if (hdr->root == SS_NONE) return hdr->count == 0 && hdr->leftmost == SS_NONE;
    double ps = 0; int64_t pm = 0; int hp = 0, ld = -1;
    long total = ss_check_rec(h, hdr->root, 0, 1, &ps, &pm, &hp, &ld);
    if (total < 0 || (uint32_t)total != hdr->count) return 0;
    /* leaf links == in-order, and reach rightmost */
    uint32_t leaf = hdr->leftmost; double ls = 0; int64_t lm = 0; int lh = 0; uint32_t seen = 0;
    while (leaf != SS_NONE) {
        SsNode *nd = &h->nodes[leaf];
        if (!nd->is_leaf) return 0;
        for (int i = 0; i < nd->num; i++) {
            if (lh && ss_key_cmp(ls, lm, nd->scores[i], nd->members[i]) >= 0) return 0;
            ls = nd->scores[i]; lm = nd->members[i]; lh = 1; seen++;
        }
        if (nd->next == SS_NONE && leaf != hdr->rightmost) return 0;
        leaf = nd->next;
    }
    if (seen != hdr->count) return 0;
    /* index population == count */
    uint32_t icount = 0;
    for (uint32_t i = 0; i < hdr->index_slots; i++) if (h->index[i].state) icount++;
    return icount == hdr->count;
}

/* ---- order-statistics queries (read paths; caller holds the read lock) ---- */

/* number of entries strictly less than (score, member) -- the rank of the key */
static uint32_t ss_rank_of(SsHandle *h, double score, int64_t member) {
    uint32_t n = h->hdr->root, rank = 0;
    while (!h->nodes[n].is_leaf) {
        SsNode *nd = &h->nodes[n];
        int c = ss_child_index(nd, score, member);
        for (int i = 0; i < c; i++) rank += nd->counts[i];
        n = nd->children[c];
    }
    SsNode *nd = &h->nodes[n];
    int pos = 0;
    while (pos < nd->num && ss_key_cmp(nd->scores[pos], nd->members[pos], score, member) < 0) pos++;
    return rank + (uint32_t)pos;
}

/* entry at 0-based rank r (r < count); returns leaf idx and sets *pos */
static uint32_t ss_at_rank(SsHandle *h, uint32_t r, int *pos) {
    uint32_t n = h->hdr->root;
    while (!h->nodes[n].is_leaf) {
        SsNode *nd = &h->nodes[n];
        int c = 0;
        while (c < nd->num && r >= nd->counts[c]) { r -= nd->counts[c]; c++; }
        n = nd->children[c];
    }
    *pos = (int)r;
    return n;
}

/* number of entries with score in [min, max] (inclusive). *lo_out (optional, may
   be NULL) receives #{score < min} -- the rank of the first in-range entry -- so
   range_by_score can reuse it instead of recomputing ss_rank_of(min, ...). */
static uint32_t ss_count_in_score(SsHandle *h, double min, double max, uint32_t *lo_out) {
    if (h->hdr->root == SS_NONE || !(min <= max)) { if (lo_out) *lo_out = 0; return 0; }
    uint32_t lo = ss_rank_of(h, min, INT64_MIN);   /* #{score < min} */
    if (lo_out) *lo_out = lo;
    uint32_t hi = ss_rank_of(h, max, INT64_MAX);   /* #{key < (max, INT64_MAX)} */
    double sc;
    if (ss_idx_get(h, INT64_MAX, &sc) && sc == max) hi++;   /* + the (max, INT64_MAX) entry itself */
    return hi - lo;
}

/* result collector: parallel member/score arrays */
typedef struct { int64_t *members; double *scores; size_t n, cap; } ss_rcollect_t;
static int ss_rcollect_push(ss_rcollect_t *c, int64_t m, double s) {
    if (c->n == c->cap) {
        size_t nc = c->cap ? c->cap * 2 : 64;
        int64_t *nm = (int64_t *)realloc(c->members, nc * sizeof(int64_t));
        if (!nm) return 0; c->members = nm;
        double *ns = (double *)realloc(c->scores, nc * sizeof(double));
        if (!ns) return 0; c->scores = ns;
        c->cap = nc;
    }
    c->members[c->n] = m; c->scores[c->n] = s; c->n++;
    return 1;
}

/* collect `len` entries starting at rank `start` (in order, or reversed). The
   caller has clamped [start, start+len) within [0, count]. Returns 0 on OOM. */
static int ss_collect_range(SsHandle *h, uint32_t start, uint32_t len, int reverse, ss_rcollect_t *c) {
    if (len == 0 || h->hdr->root == SS_NONE) return 1;
    int pos;
    uint32_t leaf = ss_at_rank(h, reverse ? (start + len - 1) : start, &pos);
    uint32_t got = 0;
    if (!reverse) {
        while (leaf != SS_NONE && got < len) {
            SsNode *nd = &h->nodes[leaf];
            for (; pos < nd->num && got < len; pos++, got++)
                if (!ss_rcollect_push(c, nd->members[pos], nd->scores[pos])) return 0;
            leaf = nd->next; pos = 0;
        }
    } else {
        while (leaf != SS_NONE && got < len) {
            SsNode *nd = &h->nodes[leaf];
            for (; pos >= 0 && got < len; pos--, got++)
                if (!ss_rcollect_push(c, nd->members[pos], nd->scores[pos])) return 0;
            leaf = nd->prev;
            if (leaf != SS_NONE) pos = h->nodes[leaf].num - 1;
        }
    }
    return 1;
}

#endif /* SORTEDSET_H */

