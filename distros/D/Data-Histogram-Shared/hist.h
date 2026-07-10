/*
 * hist.h -- Shared-memory HdrHistogram for Linux
 *
 * A High Dynamic Range histogram: records integer values across a very wide
 * range and answers percentile / min / max / mean queries within a fixed,
 * configurable relative error. Values are bucketed logarithmically (one bucket
 * per power of two of magnitude) and linearly within each bucket (a fixed
 * number of sub-buckets per power of two), so a constant number of significant
 * figures is preserved across the whole range. The counts array lives in a
 * shared mapping so several processes share one histogram; a write-preferring
 * futex rwlock with reader-slot dead-process recovery guards mutation. Two
 * histograms of equal geometry can be merged (cellwise add -> combined stream).
 *
 * Layout: Header -> reader_slots[1024] -> counts[counts_len]  (each int64_t)
 */

#ifndef HIST_H
#define HIST_H

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

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "hist.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define HIST_MAGIC        0x54534948U  /* "HIST" (little-endian) */
#define HIST_VERSION      1
#define HIST_ERR_BUFLEN   256
#ifndef HIST_READER_SLOTS
#define HIST_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
#define HIST_MIN_SIG      1            /* significant figures range */
#define HIST_MAX_SIG      5

#define HIST_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, HIST_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} HistReaderSlot;

struct HistHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t _pad0;                   /* 8 */
    uint32_t _pad1;                   /* 12 */

    /* ---- configuration ---- */
    int64_t  lowest;                  /* 16  lowest trackable value (>= 1)      */
    int64_t  highest;                 /* 24  highest trackable value            */
    int32_t  sig_figs;                /* 32  significant figures, [1,5]         */
    int32_t  unit_magnitude;          /* 36  floor(log2(lowest))                */

    /* ---- derived geometry ---- */
    int32_t  sub_bucket_count_magnitude;       /* 40 */
    int32_t  sub_bucket_half_count_magnitude;  /* 44 */
    int32_t  sub_bucket_count;                 /* 48 */
    int32_t  sub_bucket_half_count;            /* 52 */
    int64_t  sub_bucket_mask;                  /* 56 */
    int32_t  bucket_count;                     /* 64 */
    int32_t  _pad2;                            /* 68 */
    int64_t  counts_len;                       /* 72  number of int64 counts    */

    /* ---- recorded data ---- */
    int64_t  total_count;             /* 80  sum of all recorded counts         */
    int64_t  min_value;               /* 88  min recorded value (INT64_MAX init)*/
    int64_t  max_value;               /* 96  max recorded value (0 init)        */

    /* ---- offsets / size ---- */
    uint64_t total_size;              /* 104 */
    uint64_t reader_slots_off;        /* 112 */
    uint64_t counts_off;              /* 120 */

    /* ---- lock + stats ---- */
    uint32_t rwlock;                  /* 128 */
    uint32_t rwlock_waiters;          /* 132 */
    uint32_t rwlock_writers_waiting;  /* 136 */
    uint32_t slotless_readers;  /* live readers holding the lock with no reader-slot (was padding) */
    uint64_t stat_ops;                /* 144 */
    uint8_t  _pad[104];               /* 152..255 */
};
typedef struct HistHeader HistHeader;

_Static_assert(sizeof(HistHeader) == 256, "HistHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct HistHandle {
    HistHeader     *hdr;
    HistReaderSlot *reader_slots;  /* HIST_READER_SLOTS entries */
    void           *base;          /* mmap base */
    size_t          mmap_size;
    uint64_t        counts_off;    /* validated counts offset, cached: never re-read from the peer-writable header */
    char           *path;          /* backing file path (strdup'd) */
    int             backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t        my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t        cached_pid;    /* getpid() cached at last slot claim */
    uint32_t        cached_fork_gen; /* hist_fork_gen value at last slot claim */
    uint32_t slotless_held; /* rwlock read-locks held with no reader-slot */
} HistHandle;

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define HIST_RWLOCK_SPIN_LIMIT 32
#define HIST_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void hist_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define HIST_RWLOCK_WRITER_BIT 0x80000000U
#define HIST_RWLOCK_PID_MASK   0x7FFFFFFFU
#define HIST_RWLOCK_WR(pid)    (HIST_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & HIST_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
static inline int hist_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void hist_recover_stale_lock(HistHandle *h, uint32_t observed_rwlock) {
    HistHeader *hdr = h->hdr;
    uint32_t mypid = HIST_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec hist_lock_timeout = { HIST_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t hist_fork_gen = 1;
static pthread_once_t hist_atfork_once = PTHREAD_ONCE_INIT;
static void hist_on_fork_child(void) {
    __atomic_add_fetch(&hist_fork_gen, 1, __ATOMIC_RELAXED);
}
static void hist_atfork_init(void) {
    pthread_atfork(NULL, NULL, hist_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void hist_claim_reader_slot(HistHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&hist_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&hist_atfork_once, hist_atfork_init);
    /* Re-read after pthread_once: hist_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&hist_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % HIST_READER_SLOTS;
    for (uint32_t i = 0; i < HIST_READER_SLOTS; i++) {
        uint32_t s = (start + i) % HIST_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and hist_recover_dead_readers won't drain them
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
static inline void hist_atomic_sub_cap(uint32_t *p, uint32_t sub) {
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
 * state.  hist_claim_reader_slot zeros all three on every claim, so
 * leaving stale values is harmless. */
static inline void hist_drain_dead_slot(HistHandle *h, uint32_t i, uint32_t pid) {
    HistHeader *hdr = h->hdr;
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
    if (wp)    hist_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) hist_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
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
static inline void hist_recover_dead_readers(HistHandle *h) {
    if (!h->reader_slots) return;
    HistHeader *hdr = h->hdr;
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
    for (uint32_t i = 0; i < HIST_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (hist_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        hist_drain_dead_slot(h, i, pid);
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
    /* A live reader with no slot (table was full) is invisible to the scan
     * above but still holds a +1 in the lock word; never force-reset under it. */
    if (__atomic_load_n(&hdr->slotless_readers, __ATOMIC_RELAXED) > 0)
        any_live_reader = 1;
    if (found_dead_reader && !any_live_reader) {
        /* ACQUIRE: a late reader's subcount++ (before its rwlock CAS) is then visible below. */
        uint32_t cur = __atomic_load_n(&hdr->rwlock, __ATOMIC_ACQUIRE);
        int drain_ok = 1;   /* keep dead slots if the reset doesn't fire */
        if (cur > 0 && cur < HIST_RWLOCK_WRITER_BIT) {
            /* Re-scan for a live reader (fail-safe: only suppresses a reset). */
            int live_now = __atomic_load_n(&hdr->slotless_readers, __ATOMIC_RELAXED) > 0;
            for (uint32_t i = 0; !live_now && i < HIST_READER_SLOTS; i++) {
                uint32_t p = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (p && hist_pid_alive(p) &&
                    __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED) > 0)
                    live_now = 1;
            }
            if (live_now) {
                drain_ok = 0;
            } else if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            } else {
                drain_ok = 0;   /* rwlock changed under us -- shares may still be live */
            }
        }
        if (drain_ok) {
            for (uint32_t i = 0; i < HIST_READER_SLOTS; i++) {
                uint32_t p = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (p == 0 || hist_pid_alive(p)) continue;
                hist_drain_dead_slot(h, i, p);
            }
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters.  Called from rdlock and wrlock ETIMEDOUT
 * branches -- identical recovery logic in both. */
static inline void hist_recover_after_timeout(HistHandle *h) {
    HistHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= HIST_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & HIST_RWLOCK_PID_MASK;
        if (!hist_pid_alive(pid))
            hist_recover_stale_lock(h, val);
    } else {
        hist_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution.  Kept paired to make
 * accidental drift between global and per-slot counts impossible. */
static inline void hist_park_reader(HistHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void hist_unpark_reader(HistHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void hist_park_writer(HistHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void hist_unpark_writer(HistHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

/* Reader accounting: a reader mirrors its +1 in the lock word so dead-reader
 * recovery can see it. A slotted reader uses its slot subcount; a reader that
 * could not claim a slot (table full) uses the global hdr->slotless_readers,
 * so recovery's force-reset never fires out from under it. leave() peels
 * slotless first so a later slot claim cannot misattribute the decrement. */
static inline void hist_reader_enter(HistHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_readers, 1, __ATOMIC_RELAXED);
        h->slotless_held++;
    }
}
static inline void hist_reader_leave(HistHandle *h) {
    if (h->slotless_held > 0) {
        h->slotless_held--;
        __atomic_sub_fetch(&h->hdr->slotless_readers, 1, __ATOMIC_RELAXED);
    } else if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    }
}

static inline void hist_rwlock_rdlock(HistHandle *h) {
    hist_claim_reader_slot(h);
    HistHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    /* Claim subcount BEFORE bumping the shared rwlock counter.  This way
     * a concurrent writer-side recovery scan that sees our PID alive with
     * subcount > 0 will (correctly) defer force-reset, even while we are
     * still spinning trying to win the rwlock CAS.  Without this, a reader
     * killed between rwlock CAS-success and subcount++ would let recovery
     * force-reset rwlock to 0 underneath us, causing a UINT32_MAX wrap on
     * our eventual rdunlock dec. */
    hist_reader_enter(h);
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Write-preferring: when lock is free (cur==0) and writers are
         * waiting, yield to let the writer acquire. When readers are
         * already active (cur>=1), new readers may join freely. */
        if (cur > 0 && cur < HIST_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < HIST_RWLOCK_SPIN_LIMIT, 1)) {
            hist_rwlock_spin_pause();
            continue;
        }
        hist_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= HIST_RWLOCK_WRITER_BIT ||
            (cur == 0 && __atomic_load_n(writers_waiting, __ATOMIC_RELAXED))) {
            /* park on a free lock only to yield to a waiting writer; with no
             * writer, re-loop and acquire -- else nobody would ever wake us. */
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &hist_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                hist_unpark_reader(h);
                hist_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        hist_unpark_reader(h);
        spin = 0;
    }
}

static inline void hist_rwlock_rdunlock(HistHandle *h) {
    HistHeader *hdr = h->hdr;
    /* Release the shared counter BEFORE dropping our subcount so that
     * "any live PID with subcount > 0" is a reliable in-flight indicator
     * for the writer-side recovery scan.  Inverting these would create a
     * window where we still own a unit of rwlock but our slot subcount is
     * 0, letting recovery force-reset rwlock underneath us. */
    uint32_t after = __atomic_sub_fetch(&hdr->rwlock, 1, __ATOMIC_RELEASE);
    hist_reader_leave(h);
    if (after == 0 && __atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void hist_rwlock_wrlock(HistHandle *h) {
    hist_claim_reader_slot(h);  /* refresh cached_pid across fork */
    HistHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = HIST_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < HIST_RWLOCK_SPIN_LIMIT, 1)) {
            hist_rwlock_spin_pause();
            continue;
        }
        hist_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &hist_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                hist_unpark_writer(h);
                hist_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        hist_unpark_writer(h);
        spin = 0;
    }
}

static inline void hist_rwlock_wrunlock(HistHandle *h) {
    HistHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> counts[counts_len]  (int64_t)
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets. */
typedef struct { uint64_t reader_slots, counts; } HistLayout;

static inline HistLayout hist_layout(void) {
    HistLayout L;
    L.reader_slots = sizeof(HistHeader);
    L.counts       = L.reader_slots + (uint64_t)HIST_READER_SLOTS * sizeof(HistReaderSlot);
    L.counts       = (L.counts + 7) & ~(uint64_t)7;   /* 8-byte align the counts array (int64_t words) */
    return L;
}

static inline uint64_t hist_total_size(int64_t counts_len) {
    HistLayout L = hist_layout();
    return L.counts + (uint64_t)counts_len * sizeof(int64_t);   /* counts_len int64_t cells */
}

static inline int64_t *hist_counts(HistHandle *h) {
    return (int64_t *)((char *)h->base + h->counts_off);
}

/* ---- Layer B: at-use bounds for attacker-controlled file-stored values ----
 * The backing file is mmap'd MAP_SHARED, so a local peer with write access can
 * mutate counts_off / counts_len live, AFTER the open-time header validation.
 * Anchor every counts[] index/length on the process-local mmap_size (kept in
 * our PRIVATE handle, not the shared segment, hence trustworthy).  For a valid
 * histogram counts_off == the layout constant and counts_off + counts_len*8 ==
 * mmap_size, so all clamps below are never-taken branches in normal use. */

/* int64 count cells that actually fit in our mapping given (untrusted) counts_off. */
static inline int64_t hist_counts_capacity(HistHandle *h) {
    uint64_t off = h->counts_off;
    if (off > (uint64_t)h->mmap_size) return 0;             /* wild offset: nothing fits */
    return (int64_t)(((uint64_t)h->mmap_size - off) / sizeof(int64_t));
}

/* counts_len clamped to what fits (also rejects a negative/huge stored len). */
static inline int64_t hist_counts_len_safe(HistHandle *h) {
    int64_t cap = hist_counts_capacity(h);
    int64_t len = h->hdr->counts_len;
    return (len < 0 || len > cap) ? cap : len;
}

/* ================================================================
 * HdrHistogram geometry -- canonical formulas (see HdrHistogram_c).
 * All derived fields are computed once here and stored in the header.
 * ================================================================ */

typedef struct {
    int64_t lowest;
    int64_t highest;
    int32_t sig_figs;
    int32_t unit_magnitude;
    int32_t sub_bucket_count_magnitude;
    int32_t sub_bucket_half_count_magnitude;
    int32_t sub_bucket_count;
    int32_t sub_bucket_half_count;
    int64_t sub_bucket_mask;
    int32_t bucket_count;
    int64_t counts_len;
} HistGeometry;

/* Validate args + compute the full geometry.  Single source of truth: the XS
 * layer does NOT duplicate these range checks. */
static int hist_validate_create_args(int64_t lowest, int64_t highest, int32_t sig_figs,
                                     HistGeometry *g, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (lowest < 1) { HIST_ERR("lowest must be >= 1"); return 0; }
    if (highest < 2 * lowest) { HIST_ERR("highest must be >= 2 * lowest"); return 0; }
    if (sig_figs < HIST_MIN_SIG || sig_figs > HIST_MAX_SIG) {
        HIST_ERR("sig_figs must be between %d and %d", HIST_MIN_SIG, HIST_MAX_SIG); return 0;
    }

    int32_t unit_magnitude = (int32_t)floor(log2((double)lowest));
    int32_t sbc_magnitude  = (int32_t)ceil(log2(2.0 * pow(10.0, (double)sig_figs)));
    if (sbc_magnitude < 1) sbc_magnitude = 1;
    int32_t shc_magnitude  = sbc_magnitude - 1;
    if (unit_magnitude + shc_magnitude > 61) {
        HIST_ERR("lowest too large for sig_figs (unit_magnitude %d + sub_bucket_half_count_magnitude %d exceeds 61)", unit_magnitude, shc_magnitude);
        return 0;
    }
    int32_t sub_bucket_count      = (int32_t)(1 << sbc_magnitude);
    int32_t sub_bucket_half_count = sub_bucket_count / 2;
    int64_t sub_bucket_mask       = ((int64_t)sub_bucket_count - 1) << unit_magnitude;

    /* bucket_count: smallest count of buckets covering 'highest' */
    int64_t smallest_untrackable = (int64_t)sub_bucket_count << unit_magnitude;
    int32_t bucket_count = 1;
    while (smallest_untrackable <= highest) {
        if (smallest_untrackable > (INT64_MAX / 2)) { bucket_count++; break; }
        smallest_untrackable <<= 1;
        bucket_count++;
    }
    int64_t counts_len = (int64_t)(bucket_count + 1) * sub_bucket_half_count;

    g->lowest                          = lowest;
    g->highest                         = highest;
    g->sig_figs                        = sig_figs;
    g->unit_magnitude                  = unit_magnitude;
    g->sub_bucket_count_magnitude      = sbc_magnitude;
    g->sub_bucket_half_count_magnitude = shc_magnitude;
    g->sub_bucket_count                = sub_bucket_count;
    g->sub_bucket_half_count           = sub_bucket_half_count;
    g->sub_bucket_mask                 = sub_bucket_mask;
    g->bucket_count                    = bucket_count;
    g->counts_len                      = counts_len;
    return 1;
}

static inline void hist_init_header(void *base, const HistGeometry *g, uint64_t total_size) {
    HistLayout L = hist_layout();
    HistHeader *hdr = (HistHeader *)base;
    /* Explicitly zero the header + reader-slot region (lock-recovery state);
       the counts array relies on the fresh mapping being OS zero-filled. */
    memset(base, 0, (size_t)L.counts);
    hdr->magic            = HIST_MAGIC;
    hdr->version          = HIST_VERSION;
    hdr->lowest           = g->lowest;
    hdr->highest          = g->highest;
    hdr->sig_figs         = g->sig_figs;
    hdr->unit_magnitude   = g->unit_magnitude;
    hdr->sub_bucket_count_magnitude      = g->sub_bucket_count_magnitude;
    hdr->sub_bucket_half_count_magnitude = g->sub_bucket_half_count_magnitude;
    hdr->sub_bucket_count                = g->sub_bucket_count;
    hdr->sub_bucket_half_count           = g->sub_bucket_half_count;
    hdr->sub_bucket_mask                 = g->sub_bucket_mask;
    hdr->bucket_count                    = g->bucket_count;
    hdr->counts_len                      = g->counts_len;
    hdr->total_count      = 0;
    hdr->min_value        = INT64_MAX;
    hdr->max_value        = 0;
    hdr->total_size       = total_size;
    hdr->reader_slots_off = L.reader_slots;
    hdr->counts_off       = L.counts;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline HistHandle *hist_setup(void *base, size_t map_size,
                                     const char *path, int backing_fd) {
    HistHeader *hdr = (HistHeader *)base;
    HistHandle *h = (HistHandle *)calloc(1, sizeof(HistHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (HistReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
    h->mmap_size    = map_size;
    h->counts_off   = hdr->counts_off;   /* validated at open (== L.counts); cache so the bound and the pointer use one value */
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by hist_create reopen and hist_open_fd).
 * Stored geometry wins on reopen; we re-derive it from lowest/highest/sig_figs
 * and require every cached field to match, then require total_size == the size
 * the geometry implies and == the actual file size. */
static inline int hist_validate_header(const HistHeader *hdr, uint64_t file_size) {
    if (hdr->magic != HIST_MAGIC) return 0;
    if (hdr->version != HIST_VERSION) return 0;
    if (hdr->sig_figs < HIST_MIN_SIG || hdr->sig_figs > HIST_MAX_SIG) return 0;
    if (hdr->lowest < 1) return 0;
    if (hdr->highest < 2 * hdr->lowest) return 0;

    HistGeometry g;
    if (!hist_validate_create_args(hdr->lowest, hdr->highest, hdr->sig_figs, &g, NULL))
        return 0;
    if (hdr->unit_magnitude                  != g.unit_magnitude) return 0;
    if (hdr->sub_bucket_count_magnitude      != g.sub_bucket_count_magnitude) return 0;
    if (hdr->sub_bucket_half_count_magnitude != g.sub_bucket_half_count_magnitude) return 0;
    if (hdr->sub_bucket_count                != g.sub_bucket_count) return 0;
    if (hdr->sub_bucket_half_count           != g.sub_bucket_half_count) return 0;
    if (hdr->sub_bucket_mask                 != g.sub_bucket_mask) return 0;
    if (hdr->bucket_count                    != g.bucket_count) return 0;
    if (hdr->counts_len                      != g.counts_len) return 0;

    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != hist_total_size(hdr->counts_len)) return 0;
    HistLayout L = hist_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->counts_off != L.counts) return 0;
    return 1;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at mode,
 * default 0600), or attach an existing file (O_RDWR|O_NOFOLLOW, no O_CREAT). */
static int hist_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { HIST_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        HIST_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    HIST_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static HistHandle *hist_create(const char *path, int64_t lowest, int64_t highest,
                               int32_t sig_figs, mode_t mode, char *errbuf) {
    HistGeometry g;
    if (!hist_validate_create_args(lowest, highest, sig_figs, &g, errbuf)) return NULL;

    uint64_t total = hist_total_size(g.counts_len);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { HIST_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = hist_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { HIST_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { HIST_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(HistHeader)) {
            HIST_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            HIST_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { HIST_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!hist_validate_header((HistHeader *)base, (uint64_t)st.st_size)) {
                HIST_ERR("invalid histogram file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return hist_setup(base, map_size, path, -1);
        }
    }
    hist_init_header(base, &g, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return hist_setup(base, map_size, path, -1);
}

static HistHandle *hist_create_memfd(const char *name, int64_t lowest, int64_t highest,
                                     int32_t sig_figs, char *errbuf) {
    HistGeometry g;
    if (!hist_validate_create_args(lowest, highest, sig_figs, &g, errbuf)) return NULL;

    uint64_t total = hist_total_size(g.counts_len);
    int fd = memfd_create(name ? name : "hist", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { HIST_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        HIST_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { HIST_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    hist_init_header(base, &g, total);
    return hist_setup(base, (size_t)total, NULL, fd);
}

static HistHandle *hist_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { HIST_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(HistHeader)) { HIST_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { HIST_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!hist_validate_header((HistHeader *)base, (uint64_t)st.st_size)) {
        HIST_ERR("invalid histogram table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { HIST_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return hist_setup(base, ms, NULL, myfd);
}

static void hist_destroy(HistHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a lock is still held (subcount>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&hist_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].subcount, __ATOMIC_ACQUIRE) == 0) {
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int hist_msync(HistHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * HdrHistogram index helpers (lock-free; pure functions of geometry)
 *
 * value | sub_bucket_mask is always >= 1 (sub_bucket_mask >= 1 since
 * sub_bucket_count >= 2 and unit_magnitude >= 0), so __builtin_clzll is
 * never called with 0.
 * ================================================================ */

static inline int32_t hist_bucket_index(HistHandle *h, int64_t v) {
    return (int32_t)((64 - __builtin_clzll((uint64_t)(v | h->hdr->sub_bucket_mask)))
                     - h->hdr->unit_magnitude - (h->hdr->sub_bucket_half_count_magnitude + 1));
}

static inline int32_t hist_sub_bucket_index(HistHandle *h, int64_t v, int32_t bi) {
    return (int32_t)((uint64_t)v >> (bi + h->hdr->unit_magnitude));
}

static inline int64_t hist_counts_index(HistHandle *h, int32_t bi, int32_t sbi) {
    return ((int64_t)(bi + 1) << h->hdr->sub_bucket_half_count_magnitude)
           + (sbi - h->hdr->sub_bucket_half_count);
}

static inline int64_t hist_counts_index_for(HistHandle *h, int64_t v) {
    int32_t bi  = hist_bucket_index(h, v);
    int32_t sbi = hist_sub_bucket_index(h, v, bi);
    return hist_counts_index(h, bi, sbi);
}

/* reverse: lowest value stored at counts[index] */
static inline int64_t hist_value_at_index(HistHandle *h, int64_t index) {
    int32_t bi  = (int32_t)(index >> h->hdr->sub_bucket_half_count_magnitude) - 1;
    int32_t sbi = (int32_t)(index & (h->hdr->sub_bucket_half_count - 1)) + h->hdr->sub_bucket_half_count;
    if (bi < 0) { sbi -= h->hdr->sub_bucket_half_count; bi = 0; }
    return (int64_t)sbi << (bi + h->hdr->unit_magnitude);
}

static inline int64_t hist_size_of_equiv_range(HistHandle *h, int64_t v) {
    int32_t bi  = hist_bucket_index(h, v);
    int32_t sbi = hist_sub_bucket_index(h, v, bi);
    int32_t adj = (sbi >= h->hdr->sub_bucket_count) ? bi + 1 : bi;
    return (int64_t)1 << (h->hdr->unit_magnitude + adj);
}

static inline int64_t hist_lowest_equiv(HistHandle *h, int64_t v) {
    return hist_value_at_index(h, hist_counts_index_for(h, v));
}

static inline int64_t hist_highest_equiv(HistHandle *h, int64_t v) {
    return hist_lowest_equiv(h, v) + hist_size_of_equiv_range(h, v) - 1;
}

static inline int64_t hist_median_equiv(HistHandle *h, int64_t v) {
    return hist_lowest_equiv(h, v) + (hist_size_of_equiv_range(h, v) >> 1);
}

/* Non-locking index resolver for the XS range-check before taking the lock.
 * Returns the counts index for v, or -1 if v falls outside the trackable
 * range (idx < 0 or idx >= counts_len).  v must be >= 0. */
static inline int64_t hist_index_for(HistHandle *h, int64_t v) {
    if (v > h->hdr->highest) return -1;   /* documented croak contract: reject
                                           * values above highest that the last
                                           * bucket's pow2 span would else absorb */
    int32_t bi = hist_bucket_index(h, v);
    if (bi < 0 || bi >= h->hdr->bucket_count) return -1;
    int32_t sbi = hist_sub_bucket_index(h, v, bi);
    int64_t idx = hist_counts_index(h, bi, sbi);
    if (idx < 0 || idx >= h->hdr->counts_len) return -1;
    return idx;
}

/* ================================================================
 * HdrHistogram operations (callers hold the lock)
 * ================================================================ */

/* Record `count` occurrences of `value`.  The XS caller has ALREADY range-
 * checked 0 <= value <= highest and idx < counts_len before locking. */
static void hist_record_locked(HistHandle *h, int64_t value, int64_t count) {
    int64_t idx = hist_counts_index_for(h, value);
    if (idx < 0 || idx >= hist_counts_capacity(h)) return;  /* Layer B: reject OOB idx (untrusted geometry) */
    int64_t *counts = hist_counts(h);
    counts[idx] += count;
    h->hdr->total_count += count;
    if (count != 0) {   /* record(value, 0) records nothing -> no phantom min/max */
        if (value < h->hdr->min_value) h->hdr->min_value = value;
        if (value > h->hdr->max_value) h->hdr->max_value = value;
    }
}

/* Highest equivalent value at or below which `p` percent of recorded values
 * lie.  Returns 0 for an empty histogram. */
static int64_t hist_value_at_percentile_locked(HistHandle *h, double p) {
    int64_t total = h->hdr->total_count;
    if (total == 0) return 0;
    int64_t want = (int64_t)ceil((p / 100.0) * (double)total);
    if (want < 1) want = 1;
    if (want > total) want = total;
    int64_t *counts = hist_counts(h);
    int64_t running = 0;
    int64_t len = hist_counts_len_safe(h);     /* Layer B: never read past our mapping */
    for (int64_t idx = 0; idx < len; idx++) {
        if (!counts[idx]) continue;            /* skip empty cells (sparse); a 0 cell can never be the first to reach want */
        running += counts[idx];
        if (running >= want)
            return hist_highest_equiv(h, hist_value_at_index(h, idx));
    }
    return 0;
}

/* Arithmetic mean of all recorded values (using each bucket's median-equivalent
 * value as the representative).  Returns 0.0 for an empty histogram. */
static double hist_mean_locked(HistHandle *h) {
    int64_t total = h->hdr->total_count;
    if (total == 0) return 0.0;
    int64_t *counts = hist_counts(h);
    int64_t len = hist_counts_len_safe(h);     /* Layer B: never read past our mapping */
    double sum = 0.0;
    for (int64_t idx = 0; idx < len; idx++) {
        int64_t c = counts[idx];
        if (c)
            sum += (double)c * (double)hist_median_equiv(h, hist_value_at_index(h, idx));
    }
    return sum / (double)total;
}

/* merge src counts into dst (caller guarantees equal geometry); cellwise add,
 * saturating at INT64_MAX on overflow (caller holds dst's write lock) */
static void hist_merge_counts(int64_t *dst, const int64_t *src, int64_t counts_len) {
    for (int64_t i = 0; i < counts_len; i++) {
        if (src[i] <= 0) continue;                                    /* counts are non-negative; skip empty cells */
        if (dst[i] > INT64_MAX - src[i]) dst[i] = INT64_MAX;          /* saturate */
        else dst[i] += src[i];
    }
}

/* reset all counts to 0; reset total/min/max (caller holds the write lock) */
static inline void hist_reset_locked(HistHandle *h) {
    int64_t len = hist_counts_len_safe(h);     /* Layer B: never zero past our mapping */
    memset(hist_counts(h), 0, (size_t)((uint64_t)len * sizeof(int64_t)));
    h->hdr->total_count = 0;
    h->hdr->min_value   = INT64_MAX;
    h->hdr->max_value   = 0;
}

#endif /* HIST_H */
