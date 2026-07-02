/*
 * cms.h -- Shared-memory Count-Min sketch for Linux
 *
 * Approximate frequency estimation over a stream in fixed memory. Each item is
 * hashed once (XXH3-128); the two 64-bit halves drive one column per row
 * (d-row double hashing) into a d x w counter matrix (w a power of two). add
 * increments the d cells; estimate returns the minimum of the d cells, which
 * never underestimates the true count and overestimates by at most epsilon*total
 * with probability >= 1-delta. The matrix lives in a shared mapping so several
 * processes share one sketch; a write-preferring futex rwlock with reader-slot
 * dead-process recovery guards mutation. Two sketches of equal geometry can be
 * merged (cellwise add -> sum of streams).
 *
 * Layout: Header -> reader_slots[1024] -> counters[d * w]
 */

#ifndef CMS_H
#define CMS_H

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
#error "cms.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define CMS_MAGIC        0x534D4F43U  /* "COMS" (little-endian) */
#define CMS_VERSION      1
#define CMS_ERR_BUFLEN   256
#define CMS_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#define CMS_MIN_W        2            /* floor on the column count (power of two) */
#define CMS_MAX_W        0x100000000ULL /* 2^32 columns cap */
#define CMS_MIN_D        1
#define CMS_MAX_D        32

#define CMS_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, CMS_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} CmsReaderSlot;

struct CmsHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t d;                       /* 8   rows (hash functions), in [1,32] */
    uint32_t _pad0;                   /* 12 */
    uint64_t w;                       /* 16  columns (power of two) */
    uint64_t mask;                    /* 24  w - 1 (column index mask) */
    uint64_t total;                   /* 32  sum of all increments (for stats) */
    uint64_t total_size;              /* 40 */
    uint64_t reader_slots_off;        /* 48 */
    uint64_t counters_off;            /* 56 */
    uint32_t rwlock;                  /* 64 */
    uint32_t rwlock_waiters;          /* 68 */
    uint32_t rwlock_writers_waiting;  /* 72 */
    uint32_t _pad1;                   /* 76 */
    uint64_t stat_ops;                /* 80 */
    uint8_t  _pad[168];               /* 88..255 */
};
typedef struct CmsHeader CmsHeader;

_Static_assert(sizeof(CmsHeader) == 256, "CmsHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct CmsHandle {
    CmsHeader     *hdr;
    CmsReaderSlot *reader_slots;  /* CMS_READER_SLOTS entries */
    void          *base;          /* mmap base */
    size_t         mmap_size;
    char          *path;          /* backing file path (strdup'd) */
    int            backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t       my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;    /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* cms_fork_gen value at last slot claim */
} CmsHandle;

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define CMS_RWLOCK_SPIN_LIMIT 32
#define CMS_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void cms_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define CMS_RWLOCK_WRITER_BIT 0x80000000U
#define CMS_RWLOCK_PID_MASK   0x7FFFFFFFU
#define CMS_RWLOCK_WR(pid)    (CMS_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & CMS_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
static inline int cms_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void cms_recover_stale_lock(CmsHandle *h, uint32_t observed_rwlock) {
    CmsHeader *hdr = h->hdr;
    uint32_t mypid = CMS_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec cms_lock_timeout = { CMS_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t cms_fork_gen = 1;
static pthread_once_t cms_atfork_once = PTHREAD_ONCE_INIT;
static void cms_on_fork_child(void) {
    __atomic_add_fetch(&cms_fork_gen, 1, __ATOMIC_RELAXED);
}
static void cms_atfork_init(void) {
    pthread_atfork(NULL, NULL, cms_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void cms_claim_reader_slot(CmsHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&cms_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&cms_atfork_once, cms_atfork_init);
    /* Re-read after pthread_once: cms_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&cms_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % CMS_READER_SLOTS;
    for (uint32_t i = 0; i < CMS_READER_SLOTS; i++) {
        uint32_t s = (start + i) % CMS_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and cms_recover_dead_readers won't drain them
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
static inline void cms_atomic_sub_cap(uint32_t *p, uint32_t sub) {
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
 * state.  cms_claim_reader_slot zeros all three on every claim, so
 * leaving stale values is harmless. */
static inline void cms_drain_dead_slot(CmsHandle *h, uint32_t i, uint32_t pid) {
    CmsHeader *hdr = h->hdr;
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
    if (wp)    cms_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) cms_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
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
static inline void cms_recover_dead_readers(CmsHandle *h) {
    if (!h->reader_slots) return;
    CmsHeader *hdr = h->hdr;
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
    for (uint32_t i = 0; i < CMS_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (cms_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        cms_drain_dead_slot(h, i, pid);
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
        if (cur > 0 && cur < CMS_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            }
        }
        for (uint32_t i = 0; i < CMS_READER_SLOTS; i++) {
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            if (pid == 0 || cms_pid_alive(pid)) continue;
            cms_drain_dead_slot(h, i, pid);
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters.  Called from rdlock and wrlock ETIMEDOUT
 * branches -- identical recovery logic in both. */
static inline void cms_recover_after_timeout(CmsHandle *h) {
    CmsHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= CMS_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & CMS_RWLOCK_PID_MASK;
        if (!cms_pid_alive(pid))
            cms_recover_stale_lock(h, val);
    } else {
        cms_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution.  Kept paired to make
 * accidental drift between global and per-slot counts impossible. */
static inline void cms_park_reader(CmsHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void cms_unpark_reader(CmsHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void cms_park_writer(CmsHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void cms_unpark_writer(CmsHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void cms_rwlock_rdlock(CmsHandle *h) {
    cms_claim_reader_slot(h);
    CmsHeader *hdr = h->hdr;
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
        if (cur > 0 && cur < CMS_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < CMS_RWLOCK_SPIN_LIMIT, 1)) {
            cms_rwlock_spin_pause();
            continue;
        }
        cms_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= CMS_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &cms_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                cms_unpark_reader(h);
                cms_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        cms_unpark_reader(h);
        spin = 0;
    }
}

static inline void cms_rwlock_rdunlock(CmsHandle *h) {
    CmsHeader *hdr = h->hdr;
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

static inline void cms_rwlock_wrlock(CmsHandle *h) {
    cms_claim_reader_slot(h);  /* refresh cached_pid across fork */
    CmsHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = CMS_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < CMS_RWLOCK_SPIN_LIMIT, 1)) {
            cms_rwlock_spin_pause();
            continue;
        }
        cms_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &cms_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                cms_unpark_writer(h);
                cms_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        cms_unpark_writer(h);
        spin = 0;
    }
}

static inline void cms_rwlock_wrunlock(CmsHandle *h) {
    CmsHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> counters[d * w]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets. */
typedef struct { uint64_t reader_slots, counters; } CmsLayout;

static inline CmsLayout cms_layout(void) {
    CmsLayout L;
    L.reader_slots = sizeof(CmsHeader);
    L.counters     = L.reader_slots + (uint64_t)CMS_READER_SLOTS * sizeof(CmsReaderSlot);
    L.counters     = (L.counters + 7) & ~(uint64_t)7;   /* 8-byte align the counter matrix (uint64_t words) */
    return L;
}

static inline uint64_t cms_total_size(uint64_t w, uint32_t d) {
    CmsLayout L = cms_layout();
    return L.counters + (uint64_t)d * w * sizeof(uint64_t);   /* d*w uint64_t cells */
}

/* round v up to the next power of two (64-bit), with a floor of CMS_MIN_W */
static inline uint64_t cms_next_pow2_u64(uint64_t v) {
    if (v <= CMS_MIN_W) return CMS_MIN_W;
    return 1ULL << (64 - __builtin_clzll(v - 1));
}

static inline void cms_init_header(void *base, uint64_t w, uint32_t d,
                                   uint64_t total_size) {
    CmsLayout L = cms_layout();
    CmsHeader *hdr = (CmsHeader *)base;
    /* Explicitly zero the header + reader-slot region (lock-recovery state);
       the counter matrix relies on the fresh mapping being OS zero-filled. */
    memset(base, 0, (size_t)L.counters);
    hdr->magic            = CMS_MAGIC;
    hdr->version          = CMS_VERSION;
    hdr->d                = d;
    hdr->w                = w;
    hdr->mask             = w - 1;
    hdr->total            = 0;
    hdr->total_size       = total_size;
    hdr->reader_slots_off = L.reader_slots;
    hdr->counters_off     = L.counters;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint64_t *cms_counters(CmsHandle *h) {
    return (uint64_t *)((char *)h->base + h->hdr->counters_off);
}

static inline CmsHandle *cms_setup(void *base, size_t map_size,
                                   const char *path, int backing_fd) {
    CmsHeader *hdr = (CmsHeader *)base;
    CmsHandle *h = (CmsHandle *)calloc(1, sizeof(CmsHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (CmsReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by cms_create reopen and cms_open_fd). */
static inline int cms_validate_header(const CmsHeader *hdr, uint64_t file_size) {
    if (hdr->magic != CMS_MAGIC) return 0;
    if (hdr->version != CMS_VERSION) return 0;
    if (hdr->d < CMS_MIN_D || hdr->d > CMS_MAX_D) return 0;
    if (hdr->w < CMS_MIN_W || hdr->w > CMS_MAX_W) return 0;
    if ((hdr->w & (hdr->w - 1)) != 0) return 0;             /* power of two */
    if (hdr->mask != hdr->w - 1) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != cms_total_size(hdr->w, hdr->d)) return 0;
    CmsLayout L = cms_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->counters_off != L.counters) return 0;
    return 1;
}

/* validate args + compute the geometry (w, d).
 *   w = next_pow2(ceil(M_E / epsilon)), floor CMS_MIN_W, cap CMS_MAX_W
 *   d = ceil(log(1 / delta)) clamped to [1, 32] */
static int cms_validate_create_args(double epsilon, double delta,
                                    uint64_t *w_out, uint32_t *d_out, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (!(epsilon > 0.0 && epsilon < 1.0)) { CMS_ERR("epsilon must be between 0 and 1 (exclusive)"); return 0; }
    if (!(delta > 0.0 && delta < 1.0))     { CMS_ERR("delta must be between 0 and 1 (exclusive)"); return 0; }

    /* w = next_pow2(ceil(e / epsilon)), floor CMS_MIN_W. Reject (don't silently
       clamp) an epsilon so small the column count would exceed the cap, else the
       achieved error bound would be worse than requested (and the mapping huge). */
    double w_opt_d = ceil(M_E / epsilon);
    if (w_opt_d > (double)CMS_MAX_W) { CMS_ERR("epsilon too small for the column cap"); return 0; }
    uint64_t w = cms_next_pow2_u64((uint64_t)w_opt_d);

    /* d = ceil(log(1/delta)) clamped to [1, 32] */
    double d_d = ceil(log(1.0 / delta));
    long dl = (long)d_d;
    if (dl < CMS_MIN_D) dl = CMS_MIN_D;
    if (dl > CMS_MAX_D) dl = CMS_MAX_D;
    uint32_t d = (uint32_t)dl;

    *w_out = w;
    *d_out = d;
    return 1;
}

static CmsHandle *cms_create(const char *path, double epsilon, double delta, char *errbuf) {
    uint64_t w;
    uint32_t d;
    if (!cms_validate_create_args(epsilon, delta, &w, &d, errbuf)) return NULL;

    uint64_t total = cms_total_size(w, d);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { CMS_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { CMS_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { CMS_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { CMS_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(CmsHeader)) {
            CMS_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            CMS_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { CMS_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!cms_validate_header((CmsHeader *)base, (uint64_t)st.st_size)) {
                CMS_ERR("invalid Count-Min sketch file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return cms_setup(base, map_size, path, -1);
        }
    }
    cms_init_header(base, w, d, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return cms_setup(base, map_size, path, -1);
}

static CmsHandle *cms_create_memfd(const char *name, double epsilon, double delta, char *errbuf) {
    uint64_t w;
    uint32_t d;
    if (!cms_validate_create_args(epsilon, delta, &w, &d, errbuf)) return NULL;

    uint64_t total = cms_total_size(w, d);
    int fd = memfd_create(name ? name : "cms", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { CMS_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        CMS_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { CMS_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    cms_init_header(base, w, d, total);
    return cms_setup(base, (size_t)total, NULL, fd);
}

static CmsHandle *cms_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { CMS_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(CmsHeader)) { CMS_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { CMS_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!cms_validate_header((CmsHeader *)base, (uint64_t)st.st_size)) {
        CMS_ERR("invalid Count-Min sketch table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { CMS_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return cms_setup(base, ms, NULL, myfd);
}

static void cms_destroy(CmsHandle *h) {
    if (!h) return;
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int cms_msync(CmsHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Count-Min sketch operations (callers hold the lock) -- d-row double
 * hashing: one XXH3-128 hash drives all d row probes.
 * Row r's column = (h1 + r*h2) & mask.
 * ================================================================ */

static inline void cms_indices(const void *item, size_t len,
                               uint64_t *h1, uint64_t *h2) {
    XXH128_hash_t hh = XXH3_128bits(item, len);
    *h1 = hh.low64;
    *h2 = hh.high64 | 1ULL;   /* force odd so the d row columns spread over the pow2 matrix */
}

/* add n to each of the d cells; bump total by n (caller holds the write lock) */
static void cms_add_locked(CmsHandle *h, const void *item, size_t len, uint64_t n) {
    uint64_t h1, h2;
    cms_indices(item, len, &h1, &h2);
    uint64_t w = h->hdr->w;
    uint64_t mask = h->hdr->mask;
    uint32_t d = h->hdr->d;
    uint64_t *counters = cms_counters(h);
    for (uint32_t r = 0; r < d; r++) {
        uint64_t c = (h1 + (uint64_t)r * h2) & mask;
        counters[(uint64_t)r * w + c] += n;
    }
    h->hdr->total += n;
}

/* return the minimum of the d cells -- the Count-Min estimate, which never
 * underestimates the true count (caller holds a lock) */
static uint64_t cms_estimate_locked(CmsHandle *h, const void *item, size_t len) {
    uint64_t h1, h2;
    cms_indices(item, len, &h1, &h2);
    uint64_t w = h->hdr->w;
    uint64_t mask = h->hdr->mask;
    uint32_t d = h->hdr->d;
    uint64_t *counters = cms_counters(h);
    uint64_t m = UINT64_MAX;
    for (uint32_t r = 0; r < d; r++) {
        uint64_t c = (h1 + (uint64_t)r * h2) & mask;
        uint64_t v = counters[(uint64_t)r * w + c];
        if (v < m) m = v;
    }
    return m;
}

/* merge src cells into dst (caller guarantees equal w and d); cellwise add,
 * saturating at UINT64_MAX on overflow (caller holds dst's write lock) */
static void cms_merge_counters(uint64_t *dst, const uint64_t *src, uint64_t cells) {
    for (uint64_t i = 0; i < cells; i++) {
        if (dst[i] > UINT64_MAX - src[i]) dst[i] = UINT64_MAX;
        else dst[i] += src[i];
    }
}

/* reset all counters to 0 and total to 0 (caller holds the write lock) */
static inline void cms_clear_locked(CmsHandle *h) {
    uint64_t cells = (uint64_t)h->hdr->d * h->hdr->w;
    memset(cms_counters(h), 0, (size_t)(cells * sizeof(uint64_t)));
    h->hdr->total = 0;
}

#endif /* CMS_H */
