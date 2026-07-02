/*
 * dsu.h -- Shared-memory union-find (disjoint-set) for Linux
 *
 * Maintains a partition of a fixed universe of N integer elements (0..N-1)
 * into disjoint sets. union(a,b) merges the two sets containing a and b;
 * find(x) returns the canonical representative (root) of x's set; connected
 * tests whether two elements are in the same set. Path compression (path
 * halving) on find plus union by size give near-constant amortized time per
 * operation. The parent/size arrays live in a shared mapping so several
 * processes share one structure; a write-preferring futex rwlock with
 * reader-slot dead-process recovery guards mutation.
 *
 * NOTE: find / connected / set_size perform path compression -- they MUTATE
 * the structure -- so every accessor that calls dsu_find acquires the WRITE
 * lock. Only num_sets / capacity are true read-only operations.
 *
 * Layout: Header -> reader_slots[1024] -> parent[n] (uint32) -> size[n] (uint32)
 */

#ifndef DSU_H
#define DSU_H

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
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <linux/futex.h>
#include <pthread.h>

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "dsu.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define DSU_MAGIC        0x55534444U  /* "DDSU" (little-endian) */
#define DSU_VERSION      1
#define DSU_ERR_BUFLEN   256
#define DSU_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#define DSU_MAX_N        (1u << 31)   /* 2.1B elements: keeps n*8 well within size_t and size[] sums within uint32 */

#define DSU_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, DSU_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} DsuReaderSlot;

struct DsuHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t _pad0;                   /* 8 */
    uint32_t _pad1;                   /* 12 */

    /* ---- configuration / partition state ---- */
    uint32_t n;                       /* 16  number of elements = capacity     */
    uint32_t num_sets;                /* 20  current count of disjoint sets     */
    uint32_t _pad2;                   /* 24 */
    uint32_t _pad3;                   /* 28 */

    /* ---- offsets / size ---- */
    uint64_t total_size;              /* 32 */
    uint64_t reader_slots_off;        /* 40 */
    uint64_t parent_off;              /* 48 */
    uint64_t size_off;                /* 56 */

    /* ---- lock + stats ---- */
    uint32_t rwlock;                  /* 64 */
    uint32_t rwlock_waiters;          /* 68 */
    uint32_t rwlock_writers_waiting;  /* 72 */
    uint32_t _pad4;                   /* 76 */
    uint64_t stat_ops;                /* 80 */
    uint8_t  _pad[168];               /* 88..255 */
};
typedef struct DsuHeader DsuHeader;

_Static_assert(sizeof(DsuHeader) == 256, "DsuHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct DsuHandle {
    DsuHeader     *hdr;
    DsuReaderSlot *reader_slots;  /* DSU_READER_SLOTS entries */
    void          *base;          /* mmap base */
    size_t         mmap_size;
    char          *path;          /* backing file path (strdup'd) */
    int            backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t       my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;    /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* dsu_fork_gen value at last slot claim */
} DsuHandle;

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define DSU_RWLOCK_SPIN_LIMIT 32
#define DSU_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void dsu_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define DSU_RWLOCK_WRITER_BIT 0x80000000U
#define DSU_RWLOCK_PID_MASK   0x7FFFFFFFU
#define DSU_RWLOCK_WR(pid)    (DSU_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & DSU_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
static inline int dsu_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void dsu_recover_stale_lock(DsuHandle *h, uint32_t observed_rwlock) {
    DsuHeader *hdr = h->hdr;
    uint32_t mypid = DSU_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec dsu_lock_timeout = { DSU_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t dsu_fork_gen = 1;
static pthread_once_t dsu_atfork_once = PTHREAD_ONCE_INIT;
static void dsu_on_fork_child(void) {
    __atomic_add_fetch(&dsu_fork_gen, 1, __ATOMIC_RELAXED);
}
static void dsu_atfork_init(void) {
    pthread_atfork(NULL, NULL, dsu_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void dsu_claim_reader_slot(DsuHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&dsu_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&dsu_atfork_once, dsu_atfork_init);
    /* Re-read after pthread_once: dsu_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&dsu_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % DSU_READER_SLOTS;
    for (uint32_t i = 0; i < DSU_READER_SLOTS; i++) {
        uint32_t s = (start + i) % DSU_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and dsu_recover_dead_readers won't drain them
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
static inline void dsu_atomic_sub_cap(uint32_t *p, uint32_t sub) {
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
 * state.  dsu_claim_reader_slot zeros all three on every claim, so
 * leaving stale values is harmless. */
static inline void dsu_drain_dead_slot(DsuHandle *h, uint32_t i, uint32_t pid) {
    DsuHeader *hdr = h->hdr;
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
    if (wp)    dsu_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) dsu_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
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
static inline void dsu_recover_dead_readers(DsuHandle *h) {
    if (!h->reader_slots) return;
    DsuHeader *hdr = h->hdr;
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
    for (uint32_t i = 0; i < DSU_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (dsu_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        dsu_drain_dead_slot(h, i, pid);
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
        if (cur > 0 && cur < DSU_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            }
        }
        for (uint32_t i = 0; i < DSU_READER_SLOTS; i++) {
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            if (pid == 0 || dsu_pid_alive(pid)) continue;
            dsu_drain_dead_slot(h, i, pid);
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters.  Called from rdlock and wrlock ETIMEDOUT
 * branches -- identical recovery logic in both. */
static inline void dsu_recover_after_timeout(DsuHandle *h) {
    DsuHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= DSU_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & DSU_RWLOCK_PID_MASK;
        if (!dsu_pid_alive(pid))
            dsu_recover_stale_lock(h, val);
    } else {
        dsu_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution.  Kept paired to make
 * accidental drift between global and per-slot counts impossible. */
static inline void dsu_park_reader(DsuHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void dsu_unpark_reader(DsuHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void dsu_park_writer(DsuHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void dsu_unpark_writer(DsuHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void dsu_rwlock_rdlock(DsuHandle *h) {
    dsu_claim_reader_slot(h);
    DsuHeader *hdr = h->hdr;
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
        if (cur > 0 && cur < DSU_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < DSU_RWLOCK_SPIN_LIMIT, 1)) {
            dsu_rwlock_spin_pause();
            continue;
        }
        dsu_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= DSU_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &dsu_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                dsu_unpark_reader(h);
                dsu_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        dsu_unpark_reader(h);
        spin = 0;
    }
}

static inline void dsu_rwlock_rdunlock(DsuHandle *h) {
    DsuHeader *hdr = h->hdr;
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

static inline void dsu_rwlock_wrlock(DsuHandle *h) {
    dsu_claim_reader_slot(h);  /* refresh cached_pid across fork */
    DsuHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = DSU_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < DSU_RWLOCK_SPIN_LIMIT, 1)) {
            dsu_rwlock_spin_pause();
            continue;
        }
        dsu_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &dsu_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                dsu_unpark_writer(h);
                dsu_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        dsu_unpark_writer(h);
        spin = 0;
    }
}

static inline void dsu_rwlock_wrunlock(DsuHandle *h) {
    DsuHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> parent[n] (uint32) -> size[n] (uint32)
 * Both arrays are 4-byte words; the reader-slot region is a multiple of 4
 * bytes, so parent_off and size_off are naturally 4-byte aligned.
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets. */
typedef struct { uint64_t reader_slots, parent, size; } DsuLayout;

static inline DsuLayout dsu_layout(uint32_t n) {
    DsuLayout L;
    L.reader_slots = sizeof(DsuHeader);
    L.parent       = L.reader_slots + (uint64_t)DSU_READER_SLOTS * sizeof(DsuReaderSlot);
    L.size         = L.parent + (uint64_t)n * sizeof(uint32_t);
    return L;
}

static inline uint64_t dsu_total_size(uint32_t n) {
    DsuLayout L = dsu_layout(n);
    return L.size + (uint64_t)n * sizeof(uint32_t);   /* parent[n] + size[n] */
}

static inline uint32_t *dsu_parent(DsuHandle *h) {
    return (uint32_t *)((char *)h->base + h->hdr->parent_off);
}

static inline uint32_t *dsu_size(DsuHandle *h) {
    return (uint32_t *)((char *)h->base + h->hdr->size_off);
}

/* ================================================================
 * Union-find core (callers hold the WRITE lock -- find compresses)
 * ================================================================ */

/* Find the root of x with path halving (every other node on the path is
 * relinked to its grandparent).  MUTATING -- the caller must hold the write
 * lock.  x must already be range-checked (< n) by the XS layer. */
static inline uint32_t dsu_find(DsuHandle *h, uint32_t x) {
    uint32_t *p = dsu_parent(h);
    while (p[x] != x) {
        p[x] = p[p[x]];   /* path halving */
        x = p[x];
    }
    return x;
}

/* Union the sets containing a and b by size (the larger-sized root wins, so
 * the tree stays shallow).  Returns 1 if the two were in different sets and
 * are now merged, 0 if they were already in the same set.  Caller holds the
 * write lock; a and b are range-checked. */
static inline int dsu_union_locked(DsuHandle *h, uint32_t a, uint32_t b) {
    uint32_t ra = dsu_find(h, a), rb = dsu_find(h, b);
    if (ra == rb) return 0;
    uint32_t *p  = dsu_parent(h);
    uint32_t *sz = dsu_size(h);
    if (sz[ra] < sz[rb]) { uint32_t t = ra; ra = rb; rb = t; }
    p[rb] = ra;
    sz[ra] += sz[rb];
    h->hdr->num_sets--;
    return 1;
}

/* Whether a and b are in the same set (mutates via path compression). */
static inline int dsu_connected_locked(DsuHandle *h, uint32_t a, uint32_t b) {
    return dsu_find(h, a) == dsu_find(h, b);
}

/* Size of the set containing x (mutates via path compression). */
static inline uint32_t dsu_set_size_locked(DsuHandle *h, uint32_t x) {
    return dsu_size(h)[dsu_find(h, x)];
}

/* Reset to all singletons: parent[i]=i, size[i]=1, num_sets=n.
 * Caller holds the write lock. */
static inline void dsu_reset_locked(DsuHandle *h) {
    uint32_t *p = dsu_parent(h);
    uint32_t *sz = dsu_size(h);
    uint32_t n = h->hdr->n;
    for (uint32_t i = 0; i < n; i++) { p[i] = i; sz[i] = 1; }
    h->hdr->num_sets = n;
}

/* ================================================================
 * Validate args + header init / setup / open / destroy
 * ================================================================ */

/* Validate create args.  Single source of truth: the XS layer does NOT
 * duplicate this range check. */
static int dsu_validate_create_args(uint64_t n, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (n < 1) { DSU_ERR("n must be >= 1"); return 0; }
    if (n > DSU_MAX_N) { DSU_ERR("n must be <= %u", (unsigned)DSU_MAX_N); return 0; }
    return 1;
}

static inline void dsu_init_header(void *base, uint32_t n, uint64_t total_size) {
    DsuLayout L = dsu_layout(n);
    DsuHeader *hdr = (DsuHeader *)base;
    /* Explicitly zero the header + reader-slot region (lock-recovery state);
       the parent/size arrays are initialized explicitly below. */
    memset(base, 0, (size_t)L.parent);
    hdr->magic            = DSU_MAGIC;
    hdr->version          = DSU_VERSION;
    hdr->n                = n;
    hdr->num_sets         = n;
    hdr->total_size       = total_size;
    hdr->reader_slots_off = L.reader_slots;
    hdr->parent_off       = L.parent;
    hdr->size_off         = L.size;
    {
        uint32_t *p  = (uint32_t *)((char *)base + L.parent);
        uint32_t *sz = (uint32_t *)((char *)base + L.size);
        for (uint32_t i = 0; i < n; i++) { p[i] = i; sz[i] = 1; }
    }
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline DsuHandle *dsu_setup(void *base, size_t map_size,
                                   const char *path, int backing_fd) {
    DsuHeader *hdr = (DsuHeader *)base;
    DsuHandle *h = (DsuHandle *)calloc(1, sizeof(DsuHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (DsuReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by dsu_create reopen and dsu_open_fd).
 * Stored n wins on reopen; require total_size == the size n implies and ==
 * the actual file size, and all offsets to match the canonical layout. */
static inline int dsu_validate_header(const DsuHeader *hdr, uint64_t file_size) {
    if (hdr->magic != DSU_MAGIC) return 0;
    if (hdr->version != DSU_VERSION) return 0;
    if (hdr->n < 1 || hdr->n > DSU_MAX_N) return 0;
    if (hdr->num_sets < 1 || hdr->num_sets > hdr->n) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != dsu_total_size(hdr->n)) return 0;
    DsuLayout L = dsu_layout(hdr->n);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->parent_off != L.parent) return 0;
    if (hdr->size_off != L.size) return 0;
    return 1;
}

static DsuHandle *dsu_create(const char *path, uint64_t n_in, char *errbuf) {
    if (!dsu_validate_create_args(n_in, errbuf)) return NULL;
    uint32_t n = (uint32_t)n_in;

    uint64_t total = dsu_total_size(n);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { DSU_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { DSU_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { DSU_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { DSU_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(DsuHeader)) {
            DSU_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            DSU_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { DSU_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!dsu_validate_header((DsuHeader *)base, (uint64_t)st.st_size)) {
                DSU_ERR("invalid disjoint-set file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return dsu_setup(base, map_size, path, -1);
        }
    }
    dsu_init_header(base, n, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return dsu_setup(base, map_size, path, -1);
}

static DsuHandle *dsu_create_memfd(const char *name, uint64_t n_in, char *errbuf) {
    if (!dsu_validate_create_args(n_in, errbuf)) return NULL;
    uint32_t n = (uint32_t)n_in;

    uint64_t total = dsu_total_size(n);
    int fd = memfd_create(name ? name : "dsu", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { DSU_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        DSU_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { DSU_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    dsu_init_header(base, n, total);
    return dsu_setup(base, (size_t)total, NULL, fd);
}

static DsuHandle *dsu_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { DSU_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(DsuHeader)) { DSU_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { DSU_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!dsu_validate_header((DsuHeader *)base, (uint64_t)st.st_size)) {
        DSU_ERR("invalid disjoint-set table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { DSU_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return dsu_setup(base, ms, NULL, myfd);
}

static void dsu_destroy(DsuHandle *h) {
    if (!h) return;
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int dsu_msync(DsuHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

#endif /* DSU_H */
