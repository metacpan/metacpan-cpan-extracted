/*
 * sphash.h -- Shared-memory spatial hash index for Linux
 *
 * Unbounded sparse spatial hash. Points are bucketed by integer cell
 * coordinates (floor(pos / cell_size)); cells map to hash buckets via XXH3.
 * Entries live in a fixed pool allocated from a free-list, chained into
 * per-bucket singly/doubly linked lists. A write-preferring futex rwlock
 * with reader-slot dead-process recovery guards mutations.
 *
 * Entry:  double pos[3]; int64_t value; uint32_t next, prev
 * Layout: Header -> reader_slots[1024] -> buckets -> bitmap -> entries
 */

#ifndef SPHASH_H
#define SPHASH_H

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
#include <pthread.h>
#include <math.h>

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "sphash.h: requires little-endian architecture"
#endif

#define XXH_INLINE_ALL
#include "xxhash.h"

/* ================================================================
 * Constants
 * ================================================================ */

#define SPH_MAGIC        0x53504831U  /* "SPH1" */
#define SPH_VERSION      1
#define SPH_NONE         UINT32_MAX
#define SPH_ERR_BUFLEN   256
#define SPH_READER_SLOTS 1024  /* max concurrent reader processes for dead-process recovery */

#define SPH_MAX_QUERY_CELLS (1u << 26)   /* ~67M cell ceiling per query; raise + rebuild if you genuinely need larger regions */
/* query function return codes */
#define SPH_Q_OK      1
#define SPH_Q_OOM     0
#define SPH_Q_TOOBIG (-1)

#define SPH_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, SPH_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

/* ================================================================
 * Structs
 * ================================================================ */

typedef struct {
    double   pos[3];   /* 0  */
    int64_t  value;    /* 24 */
    double   radius;   /* 32  per-entry interaction radius (0 = point) */
    uint32_t next;     /* 40 */
    uint32_t prev;     /* 44 */
} SpatialEntry;        /* 48 */

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
} SphReaderSlot;

struct SphHeader {
    uint32_t magic, version;          /* 0,4  */
    uint32_t max_entries, num_buckets;/* 8,12 */
    double   cell_size;               /* 16   */
    uint32_t count;                   /* 24   */
    uint32_t free_head;               /* 28   */
    uint64_t total_size;              /* 32   */
    uint64_t reader_slots_off;        /* 40   */
    uint64_t buckets_off;             /* 48   */
    uint64_t bitmap_off;              /* 56   */
    uint64_t entries_off;             /* 64   */
    uint32_t rwlock;                  /* 72   */
    uint32_t rwlock_waiters;          /* 76   */
    uint32_t rwlock_writers_waiting;  /* 80   */
    uint32_t _pad0;                   /* 84   */
    uint64_t stat_ops;                /* 88   */
    double   world[3];                /* 96   toroidal wrap extents per axis (0 = no wrap) */
    uint32_t flags;                   /* 120  bit0 = SPH_FLAG_WRAP */
    uint32_t _pad0b;                  /* 124  */
    double   sphere_radius;           /* 128  body radius for geo methods (0 = geo disabled) */
    uint8_t  _pad1[120];              /* 136..255 */
};
typedef struct SphHeader SphHeader;

#define SPH_FLAG_WRAP 1u

_Static_assert(sizeof(SpatialEntry) == 48, "SpatialEntry must be 48 bytes");
_Static_assert(sizeof(SphHeader) == 256, "SphHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct SpatialHandle {
    SphHeader     *hdr;
    SphReaderSlot *reader_slots; /* SPH_READER_SLOTS entries */
    uint32_t      *buckets;
    uint64_t      *bitmap;
    SpatialEntry  *entries;
    uint32_t       bitmap_words;
    size_t         mmap_size;
    char          *path;        /* backing file path (strdup'd) */
    int            notify_fd;
    int            backing_fd;  /* memfd fd to close on destroy, -1 otherwise */
    uint32_t       my_slot_idx;  /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;   /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* sph_fork_gen value at last slot claim */
    double         world[3];        /* cached wrap extents (0 = no wrap on axis) */
    int64_t        wrap_cells[3];   /* ceil(world/cell) per axis, 0 = no wrap */
    int            wrap;            /* nonzero if any axis wraps */
} SpatialHandle;

/* ================================================================
 * Hashing + cell helpers
 * ================================================================ */

static inline uint32_t sph_next_pow2(uint32_t v) {
    if (v < 2) return 1;
    return 1u << (32 - __builtin_clz(v - 1));
}
/* Largest magnitude a cell index may take. Clamping to +/-2^62 keeps cells far
 * inside int64 range, so the cell-box and knn-shell loops -- which expand from
 * center +/- g over a span already capped at SPH_MAX_QUERY_CELLS -- can never
 * overflow int64. 2^62 is far beyond any coordinate a double represents exactly
 * (2^53), so nothing reachable is lost. */
#define SPH_CELL_LIMIT ((int64_t)1 << 62)

/* Floor one coordinate to its integer cell. Defined for every double: NaN/Inf
 * map to cell 0, and the result is clamped to +/-SPH_CELL_LIMIT, both to avoid
 * the UB of converting an out-of-range double to int64_t and to bound the
 * query loops (see SPH_CELL_LIMIT). */
static inline int64_t sph_floor_cell(double v, double cs) {
    double d = floor(v / cs);
    if (!isfinite(d)) return 0;
    if (d >=  (double)SPH_CELL_LIMIT) return  SPH_CELL_LIMIT;
    if (d <= -(double)SPH_CELL_LIMIT) return -SPH_CELL_LIMIT;
    return (int64_t)d;
}
/* positive modulo of a cell index into [0, n); n <= 0 means "no wrap on this axis" */
static inline int64_t sph_wrap_cell(int64_t c, int64_t n) {
    if (n <= 0) return c;
    int64_t m = c % n;
    return m < 0 ? m + n : m;
}
/* shortest per-axis separation; with wrap, the minimum-image (toroidal) distance */
static inline double sph_axis_delta(double a, double b, double world) {
    double d = fabs(a - b);
    return (world > 0.0 && d > world * 0.5) ? world - d : d;
}
/* raw integer cell of a position (no wrap) -- used for box-corner span math */
static inline void sph_cell_raw(const SpatialHandle *h, const double pos[3], int64_t cell[3]) {
    double cs = h->hdr->cell_size;
    cell[0] = sph_floor_cell(pos[0], cs);
    cell[1] = sph_floor_cell(pos[1], cs);
    cell[2] = sph_floor_cell(pos[2], cs);
}
/* storage cell: the raw cell wrapped into [0,nx) per axis when toroidal, so a
   point near x=0 and one near x=world land in adjacent cells (0 and nx-1) */
static inline void sph_cell_of(const SpatialHandle *h, const double pos[3], int64_t cell[3]) {
    sph_cell_raw(h, pos, cell);
    if (h->wrap) {
        cell[0] = sph_wrap_cell(cell[0], h->wrap_cells[0]);
        cell[1] = sph_wrap_cell(cell[1], h->wrap_cells[1]);
        cell[2] = sph_wrap_cell(cell[2], h->wrap_cells[2]);
    }
}
static inline uint32_t sph_bucket_of_cell(const SpatialHandle *h, const int64_t cell[3]) {
    return (uint32_t)(XXH3_64bits(cell, 3 * sizeof(int64_t)) & (h->hdr->num_buckets - 1));
}
static inline int sph_cell_eq(const int64_t a[3], const int64_t b[3]) {
    return a[0] == b[0] && a[1] == b[1] && a[2] == b[2];
}

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define SPH_RWLOCK_SPIN_LIMIT 32
#define SPH_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void sph_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define SPH_RWLOCK_WRITER_BIT 0x80000000U
#define SPH_RWLOCK_PID_MASK   0x7FFFFFFFU
#define SPH_RWLOCK_WR(pid)    (SPH_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & SPH_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
static inline int sph_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void sph_recover_stale_lock(SpatialHandle *h, uint32_t observed_rwlock) {
    SphHeader *hdr = h->hdr;
    uint32_t mypid = SPH_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec sph_lock_timeout = { SPH_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t sph_fork_gen = 1;
static pthread_once_t sph_atfork_once = PTHREAD_ONCE_INIT;
static void sph_on_fork_child(void) {
    __atomic_add_fetch(&sph_fork_gen, 1, __ATOMIC_RELAXED);
}
static void sph_atfork_init(void) {
    pthread_atfork(NULL, NULL, sph_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void sph_claim_reader_slot(SpatialHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&sph_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&sph_atfork_once, sph_atfork_init);
    /* Re-read after pthread_once: sph_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&sph_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % SPH_READER_SLOTS;
    for (uint32_t i = 0; i < SPH_READER_SLOTS; i++) {
        uint32_t s = (start + i) % SPH_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and sph_recover_dead_readers won't drain them
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
static inline void sph_atomic_sub_cap(uint32_t *p, uint32_t sub) {
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
 * state.  sph_claim_reader_slot zeros all three on every claim, so
 * leaving stale values is harmless. */
static inline void sph_drain_dead_slot(SpatialHandle *h, uint32_t i, uint32_t pid) {
    SphHeader *hdr = h->hdr;
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
    if (wp)    sph_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) sph_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
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
static inline void sph_recover_dead_readers(SpatialHandle *h) {
    if (!h->reader_slots) return;
    SphHeader *hdr = h->hdr;
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
    for (uint32_t i = 0; i < SPH_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (sph_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        sph_drain_dead_slot(h, i, pid);
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
        if (cur > 0 && cur < SPH_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            }
        }
        for (uint32_t i = 0; i < SPH_READER_SLOTS; i++) {
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            if (pid == 0 || sph_pid_alive(pid)) continue;
            sph_drain_dead_slot(h, i, pid);
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters.  Called from rdlock and wrlock ETIMEDOUT
 * branches -- identical recovery logic in both. */
static inline void sph_recover_after_timeout(SpatialHandle *h) {
    SphHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= SPH_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & SPH_RWLOCK_PID_MASK;
        if (!sph_pid_alive(pid))
            sph_recover_stale_lock(h, val);
    } else {
        sph_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution.  Kept paired to make
 * accidental drift between global and per-slot counts impossible. */
static inline void sph_park_reader(SpatialHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void sph_unpark_reader(SpatialHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void sph_park_writer(SpatialHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void sph_unpark_writer(SpatialHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void sph_rwlock_rdlock(SpatialHandle *h) {
    sph_claim_reader_slot(h);
    SphHeader *hdr = h->hdr;
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
        if (cur > 0 && cur < SPH_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < SPH_RWLOCK_SPIN_LIMIT, 1)) {
            sph_rwlock_spin_pause();
            continue;
        }
        sph_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= SPH_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &sph_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                sph_unpark_reader(h);
                sph_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        sph_unpark_reader(h);
        spin = 0;
    }
}

static inline void sph_rwlock_rdunlock(SpatialHandle *h) {
    SphHeader *hdr = h->hdr;
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

static inline void sph_rwlock_wrlock(SpatialHandle *h) {
    sph_claim_reader_slot(h);  /* refresh cached_pid across fork */
    SphHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = SPH_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < SPH_RWLOCK_SPIN_LIMIT, 1)) {
            sph_rwlock_spin_pause();
            continue;
        }
        sph_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &sph_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                sph_unpark_writer(h);
                sph_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        sph_unpark_writer(h);
        spin = 0;
    }
}

static inline void sph_rwlock_wrunlock(SpatialHandle *h) {
    SphHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> buckets -> bitmap -> entries
 * ================================================================ */

/* Largest max_entries / num_buckets accepted at create time. 2^30 keeps the
 * power-of-two rounding (sph_next_pow2) and every byte offset well within
 * range, and is far beyond any realistic shared-memory map. */
#define SPH_MAX_CAPACITY 0x40000000u

/* Single source of truth for the mmap region layout offsets. */
typedef struct { uint64_t reader_slots, buckets, bitmap, entries; } SphLayout;

static inline SphLayout sph_layout(uint32_t max_entries, uint32_t num_buckets) {
    uint32_t bw = (max_entries + 63) / 64;
    SphLayout L;
    L.reader_slots = sizeof(SphHeader);
    L.buckets      = L.reader_slots + (uint64_t)SPH_READER_SLOTS * sizeof(SphReaderSlot);
    L.bitmap       = L.buckets + (uint64_t)num_buckets * sizeof(uint32_t);
    L.bitmap       = (L.bitmap + 7) & ~(uint64_t)7;   /* 8-byte align: bitmap is uint64[] and entries (doubles) follow it */
    L.entries      = L.bitmap + (uint64_t)bw * sizeof(uint64_t);
    return L;
}

static inline uint64_t sph_total_size(uint32_t max_entries, uint32_t num_buckets) {
    SphLayout L = sph_layout(max_entries, num_buckets);
    return L.entries + (uint64_t)max_entries * sizeof(SpatialEntry);
}

static inline void sph_init_header(void *base, uint32_t max_entries, uint32_t num_buckets,
                                    double cell_size, const double world[3], double sphere_radius, uint64_t total) {
    SphLayout L = sph_layout(max_entries, num_buckets);

    SphHeader *hdr = (SphHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic            = SPH_MAGIC;
    hdr->version          = SPH_VERSION;
    hdr->max_entries      = max_entries;
    hdr->num_buckets      = num_buckets;
    hdr->cell_size        = cell_size;
    /* toroidal wrap extents: any axis > 0 enables wrap */
    int wrap = 0;
    for (int i = 0; i < 3; i++) {
        double w = world ? world[i] : 0.0;
        hdr->world[i] = w;
        if (w > 0.0) wrap = 1;
    }
    hdr->flags = wrap ? SPH_FLAG_WRAP : 0;
    hdr->sphere_radius = sphere_radius;   /* caller validated finite and >= 0 */
    hdr->count            = 0;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->buckets_off      = L.buckets;
    hdr->bitmap_off       = L.bitmap;
    hdr->entries_off      = L.entries;

    /* Set every bucket head to SPH_NONE (empty). */
    uint32_t *buckets = (uint32_t *)((uint8_t *)base + L.buckets);
    for (uint32_t i = 0; i < num_buckets; i++) buckets[i] = SPH_NONE;

    /* Thread the free-list through the entries pool. */
    SpatialEntry *entries = (SpatialEntry *)((uint8_t *)base + L.entries);
    for (uint32_t i = 0; i < max_entries; i++)
        entries[i].next = (i + 1 < max_entries) ? (i + 1) : SPH_NONE;
    hdr->free_head = 0;   /* max_entries >= 1 (validated at create) */

    /* Alloc bitmap left zeroed (all entries free). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline SpatialHandle *sph_setup(void *base, size_t map_size,
                                        const char *path, int backing_fd) {
    SphHeader *hdr = (SphHeader *)base;
    SpatialHandle *h = (SpatialHandle *)calloc(1, sizeof(SpatialHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->reader_slots = (SphReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
    h->buckets      = (uint32_t *)((uint8_t *)base + hdr->buckets_off);
    h->bitmap       = (uint64_t *)((uint8_t *)base + hdr->bitmap_off);
    h->entries      = (SpatialEntry *)((uint8_t *)base + hdr->entries_off);
    h->bitmap_words = (hdr->max_entries + 63) / 64;
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->notify_fd    = -1;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    h->wrap = (hdr->flags & SPH_FLAG_WRAP) ? 1 : 0;
    for (int i = 0; i < 3; i++) {
        h->world[i]      = h->wrap ? hdr->world[i] : 0.0;
        h->wrap_cells[i] = (h->wrap && hdr->world[i] > 0.0)
            ? (int64_t)floor(hdr->world[i] / hdr->cell_size + 0.5) : 0;   /* exact: extent is a multiple */
    }
    return h;
}

/* Validate a mapped header (shared by sph_create reopen and sph_open_fd). */
static inline int sph_validate_header(const SphHeader *hdr, uint64_t file_size) {
    if (hdr->magic != SPH_MAGIC) return 0;
    if (hdr->version != SPH_VERSION) return 0;
    if (hdr->max_entries == 0 || hdr->num_buckets == 0) return 0;
    if (hdr->max_entries > SPH_MAX_CAPACITY || hdr->num_buckets > SPH_MAX_CAPACITY) return 0;
    if ((hdr->num_buckets & (hdr->num_buckets - 1)) != 0) return 0; /* power of two */
    if (!(hdr->cell_size > 0) || !isfinite(hdr->cell_size)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != sph_total_size(hdr->max_entries, hdr->num_buckets)) return 0;

    SphLayout L = sph_layout(hdr->max_entries, hdr->num_buckets);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->buckets_off      != L.buckets)      return 0;
    if (hdr->bitmap_off       != L.bitmap)       return 0;
    if (hdr->entries_off      != L.entries)      return 0;
    if (hdr->flags & ~SPH_FLAG_WRAP) return 0;                  /* no unknown flags */
    {   int w = 0;
        for (int i = 0; i < 3; i++) {
            if (!isfinite(hdr->world[i]) || hdr->world[i] < 0.0) return 0;
            if (hdr->world[i] > 0.0) { w = 1;
                double nx = floor(hdr->world[i] / hdr->cell_size + 0.5);
                if (nx < 1.0 || fabs(nx * hdr->cell_size - hdr->world[i]) > 1e-9 * hdr->world[i]) return 0;
            }
        }
        if (((hdr->flags & SPH_FLAG_WRAP) ? 1 : 0) != w) return 0;  /* flag must match extents */
    }
    if (!isfinite(hdr->sphere_radius) || hdr->sphere_radius < 0.0) return 0;
    if (hdr->sphere_radius > 0.0 && (hdr->flags & SPH_FLAG_WRAP)) return 0;   /* sphere and wrap are mutually exclusive */
    return 1;
}

/* Validate optional wrap extents against cell_size (world may be NULL); each
   wrapped axis must be a positive multiple of cell_size so cells tile exactly. */
static inline int sph_validate_world(const double *world, double cell_size, char *errbuf) {
    if (!world) return 1;
    for (int i = 0; i < 3; i++) {
        if (!(world[i] >= 0.0) || !isfinite(world[i])) { SPH_ERR("world extent must be finite and >= 0"); return 0; }
        if (world[i] > 0.0) {
            double nx = floor(world[i] / cell_size + 0.5);
            if (nx < 1.0 || fabs(nx * cell_size - world[i]) > 1e-9 * world[i]) {
                SPH_ERR("wrap extent must be a positive multiple of cell_size"); return 0;
            }
        }
    }
    return 1;
}

/* ================================================================
 * Geo helpers (lat/lon/alt <-> xyz); R = body radius (hdr->sphere_radius).
 * Angles in radians: lat in [-pi/2, pi/2], lon in (-pi, pi].
 * ================================================================ */
static inline void sph_geo_to_xyz(double R, double lat, double lon, double alt, double out[3]) {
    double r = R + alt;
    double cl = cos(lat);
    out[0] = r * cl * cos(lon);
    out[1] = r * cl * sin(lon);
    out[2] = r * sin(lat);
}
static inline void sph_geo_of_xyz(double R, const double in[3], double *lat, double *lon, double *alt) {
    double r = sqrt(in[0]*in[0] + in[1]*in[1] + in[2]*in[2]);
    double s = (r > 0.0) ? in[2] / r : 0.0;
    if (s > 1.0) s = 1.0; else if (s < -1.0) s = -1.0;   /* guard asin domain vs rounding */
    *lat = asin(s);
    *lon = atan2(in[1], in[0]);   /* 0 at the poles */
    *alt = r - R;
}

/* ================================================================
 * Cube-sphere cell IDs (stateless; a tiny S2-like scheme).
 * Equal-angle (tangent-warp) projection of a direction onto one of 6 cube
 * faces, row-major i,j at a level. Packed id: level(5) face(3) i(24) j(24).
 * Faces: 0=+X 1=-X 2=+Y 3=-Y 4=+Z 5=-Z. Per face the major axis carries the
 * sign and the other two coords are (s,t); reconstruction is d=(face basis).
 * ================================================================ */
#define SPH_CUBE_MAX_LEVEL 24
#define SPH_PI_4 0.78539816339744830961   /* pi/4 */

static inline int      sph_cube_level(uint64_t id) { return (int)((id >> 51) & 0x1Fu); }
static inline int      sph_cube_face (uint64_t id) { return (int)((id >> 48) & 0x7u);  }

/* well-formed id: no stray high bits, level <= MAX, face < 6, i,j < 2^level */
static inline int sph_cube_valid(uint64_t id) {
    if (id >> 56) return 0;
    int level = sph_cube_level(id);
    if (level > SPH_CUBE_MAX_LEVEL) return 0;
    if (sph_cube_face(id) > 5) return 0;
    uint64_t N = (uint64_t)1 << level;
    uint64_t i = (id >> 24) & 0xFFFFFFu, j = id & 0xFFFFFFu;
    return (i < N && j < N);
}

/* direction (need not be unit) -> cell id at level [0, SPH_CUBE_MAX_LEVEL] */
static inline uint64_t sph_cube_cell(const double dir[3], int level) {
    double x = dir[0], y = dir[1], z = dir[2];
    double ax = fabs(x), ay = fabs(y), az = fabs(z);
    int face; double mag, s, t;
    if (ax >= ay && ax >= az) { mag = ax; face = (x >= 0) ? 0 : 1; s = y / mag; t = z / mag; }
    else if (ay >= az)        { mag = ay; face = (y >= 0) ? 2 : 3; s = x / mag; t = z / mag; }
    else                      { mag = az; face = (z >= 0) ? 4 : 5; s = x / mag; t = y / mag; }
    double u = atan(s) / SPH_PI_4;          /* equal-angle warp to [-1,1] */
    double v = atan(t) / SPH_PI_4;
    if (!isfinite(u)) u = 0.0;              /* dir==0 -> s,t NaN; keep defined */
    if (!isfinite(v)) v = 0.0;
    int64_t N = (int64_t)1 << level;
    int64_t i = (int64_t)floor((u + 1.0) * 0.5 * (double)N);
    int64_t j = (int64_t)floor((v + 1.0) * 0.5 * (double)N);
    if (i < 0) i = 0; else if (i >= N) i = N - 1;
    if (j < 0) j = 0; else if (j >= N) j = N - 1;
    return ((uint64_t)level << 51) | ((uint64_t)face << 48)
         | ((uint64_t)i << 24) | (uint64_t)j;
}

/* reconstruct a face-basis direction from (face, s, t): the major axis carries
   the face sign, the two minor coords are (s, t). Inverse of the face/s/t split
   in sph_cube_cell; shared by sph_cube_center and sph_cube_neighbors. */
static inline void sph_face_dir(int face, double s, double t, double d[3]) {
    switch (face) {
        case 0: d[0]= 1; d[1]= s; d[2]= t; break;
        case 1: d[0]=-1; d[1]= s; d[2]= t; break;
        case 2: d[0]= s; d[1]= 1; d[2]= t; break;
        case 3: d[0]= s; d[1]=-1; d[2]= t; break;
        case 4: d[0]= s; d[1]= t; d[2]= 1; break;
        default: d[0]= s; d[1]= t; d[2]=-1; break;
    }
}

/* cell id -> its centre as a unit direction */
static inline void sph_cube_center(uint64_t id, double out[3]) {
    int level = sph_cube_level(id), face = sph_cube_face(id);
    int64_t N = (int64_t)1 << level;
    int64_t i = (int64_t)((id >> 24) & 0xFFFFFFu), j = (int64_t)(id & 0xFFFFFFu);
    double u = ((double)i + 0.5) / (double)N * 2.0 - 1.0;
    double v = ((double)j + 0.5) / (double)N * 2.0 - 1.0;
    double s = tan(u * SPH_PI_4), t = tan(v * SPH_PI_4);
    double d[3];
    sph_face_dir(face, s, t, d);
    double n = sqrt(d[0]*d[0] + d[1]*d[1] + d[2]*d[2]);
    out[0] = d[0]/n; out[1] = d[1]/n; out[2] = d[2]/n;
}

/* parent at level-1 (returns 0 at level 0); children at level+1 (0 at MAX) */
static inline int sph_cube_parent(uint64_t id, uint64_t *out) {
    int level = sph_cube_level(id);
    if (level == 0) return 0;
    int64_t i = (int64_t)((id >> 24) & 0xFFFFFFu), j = (int64_t)(id & 0xFFFFFFu);
    *out = ((uint64_t)(level - 1) << 51) | ((uint64_t)sph_cube_face(id) << 48)
         | ((uint64_t)(i >> 1) << 24) | (uint64_t)(j >> 1);
    return 1;
}
static inline int sph_cube_children(uint64_t id, uint64_t out[4]) {
    int level = sph_cube_level(id);
    if (level >= SPH_CUBE_MAX_LEVEL) return 0;
    uint64_t face = (uint64_t)sph_cube_face(id);
    int64_t i = (int64_t)((id >> 24) & 0xFFFFFFu), j = (int64_t)(id & 0xFFFFFFu);
    int k = 0;
    for (int di = 0; di < 2; di++) for (int dj = 0; dj < 2; dj++)
        out[k++] = ((uint64_t)(level + 1) << 51) | (face << 48)
                 | ((uint64_t)(2*i + di) << 24) | (uint64_t)(2*j + dj);
    return 1;
}

/* 4 edge-adjacent neighbors (seam-aware) by perturb-and-reproject: step one
   cell width from the centre along +-u / +-v in THIS face's basis, rebuild the
   direction (|coord| may exceed 1, crossing to the adjacent face), and re-run
   sph_cube_cell. The major-axis flip handles the seam + orientation; a full
   cell-width step lands at the neighbour's centre, so it is rounding-robust. */
static inline void sph_cube_neighbors(uint64_t id, uint64_t out[4]) {
    int level = sph_cube_level(id), face = sph_cube_face(id);
    int64_t N = (int64_t)1 << level;
    int64_t i = (int64_t)((id >> 24) & 0xFFFFFFu), j = (int64_t)(id & 0xFFFFFFu);
    double uc = ((double)i + 0.5) / (double)N * 2.0 - 1.0;
    double vc = ((double)j + 0.5) / (double)N * 2.0 - 1.0;
    double step = 2.0 / (double)N;
    static const double du[4] = { +1.0, -1.0,  0.0,  0.0 };
    static const double dv[4] = {  0.0,  0.0, +1.0, -1.0 };
    for (int k = 0; k < 4; k++) {
        double s = tan((uc + du[k]*step) * SPH_PI_4);
        double t = tan((vc + dv[k]*step) * SPH_PI_4);
        double d[3];
        sph_face_dir(face, s, t, d);
        out[k] = sph_cube_cell(d, level);
    }
}

/* validate + normalize create() args (shared by sph_create + sph_create_memfd);
   on success rounds *num_buckets up to a power of two */
static int sph_validate_create_args(uint32_t max_entries, uint32_t *num_buckets,
                                    double cell_size, const double *world,
                                    double sphere_radius, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (!(cell_size > 0) || !isfinite(cell_size)) { SPH_ERR("cell_size must be a finite number > 0"); return 0; }
    if (max_entries == 0) { SPH_ERR("max_entries must be > 0"); return 0; }
    if (!sph_validate_world(world, cell_size, errbuf)) return 0;
    if (!(sphere_radius >= 0.0) || !isfinite(sphere_radius)) { SPH_ERR("sphere radius must be finite and >= 0"); return 0; }
    if (sphere_radius > 0.0 && world && (world[0] > 0.0 || world[1] > 0.0 || world[2] > 0.0)) { SPH_ERR("sphere and wrap are mutually exclusive"); return 0; }
    if (max_entries > SPH_MAX_CAPACITY) { SPH_ERR("max_entries too large (max %u)", SPH_MAX_CAPACITY); return 0; }
    if (*num_buckets > SPH_MAX_CAPACITY) { SPH_ERR("num_buckets too large (max %u)", SPH_MAX_CAPACITY); return 0; }
    *num_buckets = sph_next_pow2(*num_buckets == 0 ? max_entries : *num_buckets);
    return 1;
}

static SpatialHandle *sph_create(const char *path, uint32_t max_entries,
                                  uint32_t num_buckets, double cell_size,
                                  const double *world, double sphere_radius, char *errbuf) {
    if (!sph_validate_create_args(max_entries, &num_buckets, cell_size, world, sphere_radius, errbuf)) return NULL;

    uint64_t total = sph_total_size(max_entries, num_buckets);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { SPH_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { SPH_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { SPH_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { SPH_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(SphHeader)) {
            SPH_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            SPH_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { SPH_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!sph_validate_header((SphHeader *)base, (uint64_t)st.st_size)) {
                SPH_ERR("invalid spatial hash file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return sph_setup(base, map_size, path, -1);
        }
    }
    sph_init_header(base, max_entries, num_buckets, cell_size, world, sphere_radius, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return sph_setup(base, map_size, path, -1);
}

static SpatialHandle *sph_create_memfd(const char *name, uint32_t max_entries,
                                        uint32_t num_buckets, double cell_size,
                                        const double *world, double sphere_radius, char *errbuf) {
    if (!sph_validate_create_args(max_entries, &num_buckets, cell_size, world, sphere_radius, errbuf)) return NULL;

    uint64_t total = sph_total_size(max_entries, num_buckets);
    int fd = memfd_create(name ? name : "sphash", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { SPH_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        SPH_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { SPH_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    sph_init_header(base, max_entries, num_buckets, cell_size, world, sphere_radius, total);
    return sph_setup(base, (size_t)total, NULL, fd);
}

static SpatialHandle *sph_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { SPH_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(SphHeader)) { SPH_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { SPH_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!sph_validate_header((SphHeader *)base, (uint64_t)st.st_size)) {
        SPH_ERR("invalid spatial hash"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { SPH_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return sph_setup(base, ms, NULL, myfd);
}

static void sph_destroy(SpatialHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int sph_msync(SpatialHandle *h) {
    if (!h || !h->hdr) return 0;
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

static int sph_create_eventfd(SpatialHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    int efd = eventfd(0, EFD_NONBLOCK|EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd;
    return efd;
}

static int sph_notify(SpatialHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t v = 1;
    return write(h->notify_fd, &v, sizeof(v)) == sizeof(v);
}

static int64_t sph_eventfd_consume(SpatialHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t v = 0;
    if (read(h->notify_fd, &v, sizeof(v)) != sizeof(v)) return -1;
    return (int64_t)v;
}

/* ================================================================
 * Slot pool: alloc / free / liveness
 * ================================================================ */

static inline int sph_is_live(const SpatialHandle *h, uint32_t idx) {
    if (idx >= h->hdr->max_entries) return 0;
    uint64_t w = h->bitmap[idx / 64];
    return (w >> (idx % 64)) & 1;
}

static inline uint32_t sph_alloc_slot(SpatialHandle *h) {
    uint32_t idx = h->hdr->free_head;
    if (idx == SPH_NONE) return SPH_NONE;
    h->hdr->free_head = h->entries[idx].next;       /* pop free-list */
    h->bitmap[idx / 64] |= (uint64_t)1 << (idx % 64);
    h->entries[idx].next = SPH_NONE;
    h->entries[idx].prev = SPH_NONE;
    return idx;
}

static inline void sph_free_slot(SpatialHandle *h, uint32_t idx) {
    h->bitmap[idx / 64] &= ~((uint64_t)1 << (idx % 64));
    h->entries[idx].next = h->hdr->free_head;        /* push free-list */
    h->hdr->free_head = idx;
}

/* ================================================================
 * Bucket chain: link / unlink (callers hold write lock)
 * ================================================================ */

static inline void sph_bucket_link(SpatialHandle *h, uint32_t idx) {
    int64_t cell[3]; sph_cell_of(h, h->entries[idx].pos, cell);
    uint32_t b = sph_bucket_of_cell(h, cell);
    uint32_t head = h->buckets[b];
    h->entries[idx].prev = SPH_NONE;
    h->entries[idx].next = head;
    if (head != SPH_NONE) h->entries[head].prev = idx;
    h->buckets[b] = idx;
}

static inline void sph_bucket_unlink(SpatialHandle *h, uint32_t idx) {
    int64_t cell[3]; sph_cell_of(h, h->entries[idx].pos, cell);
    uint32_t b = sph_bucket_of_cell(h, cell);
    uint32_t p = h->entries[idx].prev, n = h->entries[idx].next;
    if (p != SPH_NONE) h->entries[p].next = n; else h->buckets[b] = n;
    if (n != SPH_NONE) h->entries[n].prev = p;
}

/* ================================================================
 * Mutation ops (callers hold write lock)
 * ================================================================ */

static inline uint32_t sph_insert_locked(SpatialHandle *h, double x, double y, double z,
                                          int64_t value, double radius) {
    uint32_t idx = sph_alloc_slot(h);
    if (idx == SPH_NONE) return SPH_NONE;
    h->entries[idx].pos[0] = x; h->entries[idx].pos[1] = y; h->entries[idx].pos[2] = z;
    h->entries[idx].value = value;
    h->entries[idx].radius = radius;
    sph_bucket_link(h, idx);
    h->hdr->count++;
    return idx;
}

static inline int sph_remove_locked(SpatialHandle *h, uint32_t idx) {
    if (!sph_is_live(h, idx)) return 0;
    sph_bucket_unlink(h, idx);
    sph_free_slot(h, idx);
    h->hdr->count--;
    return 1;
}

static inline int sph_move_locked(SpatialHandle *h, uint32_t idx, double x, double y, double z) {
    if (!sph_is_live(h, idx)) return 0;
    int64_t oc[3], nc[3];
    sph_cell_of(h, h->entries[idx].pos, oc);
    double np[3] = { x, y, z }; sph_cell_of(h, np, nc);
    if (sph_cell_eq(oc, nc)) {                 /* same cell: just rewrite pos */
        h->entries[idx].pos[0] = x; h->entries[idx].pos[1] = y; h->entries[idx].pos[2] = z;
        return 1;
    }
    sph_bucket_unlink(h, idx);                 /* unlink uses OLD pos */
    h->entries[idx].pos[0] = x; h->entries[idx].pos[1] = y; h->entries[idx].pos[2] = z;
    sph_bucket_link(h, idx);                   /* link uses NEW pos */
    return 1;
}

/* ================================================================
 * Region query: collector + walk helpers
 * ================================================================ */

typedef struct { int64_t *vals; size_t n, cap; } sph_collect_t;

static int sph_collect_push(sph_collect_t *c, int64_t v) {
    if (c->n == c->cap) {
        size_t nc = c->cap ? c->cap * 2 : 64;
        int64_t *nv = (int64_t *)realloc(c->vals, nc * sizeof(int64_t));
        if (!nv) return 0;
        c->vals = nv; c->cap = nc;
    }
    c->vals[c->n++] = v;
    return 1;
}

/* squared distance from a to b over `dims` axes; minimum-image when toroidal */
static inline double sph_dist2_w(const double world[3], const double a[3], const double b[3], int dims) {
    double dx = sph_axis_delta(a[0], b[0], world[0]);
    double dy = sph_axis_delta(a[1], b[1], world[1]);
    double d = dx*dx + dy*dy;
    if (dims == 3) { double dz = sph_axis_delta(a[2], b[2], world[2]); d += dz*dz; }
    return d;
}
static inline double sph_dist2(const SpatialHandle *h, const double a[3], const double b[3], int dims) {
    return sph_dist2_w(h->world, a, b, dims);
}

/* Walk one cell C's bucket chain; for each entry whose recomputed cell == C
   and which passes `accept`, push its value. Returns 1 ok, 0 OOM. */
static int sph_walk_cell(SpatialHandle *h, const int64_t C[3], sph_collect_t *out,
                         int (*accept)(const double pos[3], void *ctx), void *ctx) {
    uint32_t b = sph_bucket_of_cell(h, C);
    for (uint32_t idx = h->buckets[b]; idx != SPH_NONE; idx = h->entries[idx].next) {
        int64_t ec[3]; sph_cell_of(h, h->entries[idx].pos, ec);
        if (!sph_cell_eq(ec, C)) continue;                 /* collision / dedup guard */
        if (accept && !accept(h->entries[idx].pos, ctx)) continue;
        if (!sph_collect_push(out, h->entries[idx].value)) return 0;
    }
    return 1;
}

static int sph_query_cell(SpatialHandle *h, const double p[3], int dims, sph_collect_t *out) {
    double pp[3] = { p[0], p[1], dims == 3 ? p[2] : 0.0 };
    int64_t C[3]; sph_cell_of(h, pp, C);
    return sph_walk_cell(h, C, out, NULL, NULL);
}

struct sph_box  { double lo[3], hi[3]; int dims; };
struct sph_disk { double c[3]; double r2; int dims; const double *world; };

static int sph_accept_box(const double pos[3], void *ctx) {
    struct sph_box *q = (struct sph_box *)ctx;
    if (pos[0] < q->lo[0] || pos[0] > q->hi[0]) return 0;
    if (pos[1] < q->lo[1] || pos[1] > q->hi[1]) return 0;
    if (q->dims == 3 && (pos[2] < q->lo[2] || pos[2] > q->hi[2])) return 0;
    return 1;
}
static int sph_accept_disk(const double pos[3], void *ctx) {
    struct sph_disk *q = (struct sph_disk *)ctx;
    return sph_dist2_w(q->world, pos, q->c, q->dims) <= q->r2;
}

/* enumerate the inclusive cell box [lo..hi] (per axis), z fixed to its single
   cell when dims==2, walking each cell with `accept`. */
static int sph_enum_cellbox(SpatialHandle *h, const double lo[3], const double hi[3],
                            int dims, sph_collect_t *out,
                            int (*accept)(const double[3], void *), void *ctx) {
    int64_t cl[3], ch[3];
    sph_cell_raw(h, lo, cl); sph_cell_raw(h, hi, ch);   /* raw corners for span math */
    int64_t cnt[3] = { 1, 1, 1 };
    uint64_t cells = 1;
    for (int i = 0; i < dims; i++) {
        if (ch[i] < cl[i]) return SPH_Q_OK;                        /* empty box */
        uint64_t span = (uint64_t)ch[i] - (uint64_t)cl[i] + 1;     /* exact, since ch>=cl */
        if (h->wrap_cells[i] > 0 && span > (uint64_t)h->wrap_cells[i])
            span = (uint64_t)h->wrap_cells[i];                     /* whole ring, each cell once */
        if (span >= (uint64_t)SPH_MAX_QUERY_CELLS) return SPH_Q_TOOBIG;
        if (cells > (uint64_t)SPH_MAX_QUERY_CELLS / span) return SPH_Q_TOOBIG;
        cells *= span; cnt[i] = (int64_t)span;
    }
    int64_t C[3];
    for (int64_t i0 = 0; i0 < cnt[0]; i0++) {
        C[0] = h->wrap ? sph_wrap_cell(cl[0] + i0, h->wrap_cells[0]) : cl[0] + i0;
        for (int64_t i1 = 0; i1 < cnt[1]; i1++) {
            C[1] = h->wrap ? sph_wrap_cell(cl[1] + i1, h->wrap_cells[1]) : cl[1] + i1;
            if (dims == 3) {
                for (int64_t i2 = 0; i2 < cnt[2]; i2++) {
                    C[2] = h->wrap ? sph_wrap_cell(cl[2] + i2, h->wrap_cells[2]) : cl[2] + i2;
                    if (!sph_walk_cell(h, C, out, accept, ctx)) return SPH_Q_OOM;
                }
            } else {
                C[2] = 0;
                if (!sph_walk_cell(h, C, out, accept, ctx)) return SPH_Q_OOM;
            }
        }
    }
    return SPH_Q_OK;
}

static int sph_query_aabb(SpatialHandle *h, const double lo[3], const double hi[3],
                          int dims, sph_collect_t *out) {
    struct sph_box q = { { lo[0], lo[1], dims==3?lo[2]:0 }, { hi[0], hi[1], dims==3?hi[2]:0 }, dims };
    return sph_enum_cellbox(h, q.lo, q.hi, dims, out, sph_accept_box, &q);
}

static int sph_query_radius(SpatialHandle *h, const double c[3], double r, int dims, sph_collect_t *out) {
    struct sph_disk q = { { c[0], c[1], dims==3?c[2]:0 }, r*r, dims, h->world };
    double lo[3] = { c[0]-r, c[1]-r, (dims==3?c[2]-r:0) };
    double hi[3] = { c[0]+r, c[1]+r, (dims==3?c[2]+r:0) };
    return sph_enum_cellbox(h, lo, hi, dims, out, sph_accept_disk, &q);
}

/* ================================================================
 * k-nearest-neighbour query
 * ================================================================ */

/* Candidate kept during the search: squared distance + value. */
typedef struct { double d2; int64_t val; } sph_cand_t;

/* Bounded keep-k: maintain a max-heap of size k keyed by d2 so the worst is
   at [0]. Insert only if better than current worst once full. */
static void sph_heap_offer(sph_cand_t *heap, uint32_t *n, uint32_t k, double d2, int64_t val) {
    if (*n < k) {
        uint32_t i = (*n)++;                    /* sift up */
        heap[i].d2 = d2; heap[i].val = val;
        while (i) { uint32_t p = (i-1)/2; if (heap[p].d2 >= heap[i].d2) break;
            sph_cand_t t = heap[p]; heap[p] = heap[i]; heap[i] = t; i = p; }
    } else if (k && d2 < heap[0].d2) {
        heap[0].d2 = d2; heap[0].val = val;     /* replace worst, sift down */
        uint32_t i = 0;
        for (;;) { uint32_t l=2*i+1, r=2*i+2, m=i;
            if (l<k && heap[l].d2>heap[m].d2) m=l;
            if (r<k && heap[r].d2>heap[m].d2) m=r;
            if (m==i) break; sph_cand_t t=heap[m]; heap[m]=heap[i]; heap[i]=t; i=m; }
    }
}
static int sph_cmp_d2(const void *a, const void *b) {
    double x = ((const sph_cand_t*)a)->d2, y = ((const sph_cand_t*)b)->d2;
    return (x < y) ? -1 : (x > y) ? 1 : 0;
}
/* Walk a single cell, offering live entries (cell-guarded) to the heap.
   Returns the number of live, cell-matched entries examined in this cell, so
   the caller can terminate once every live entry has been seen (not by a cell
   count, which is unbounded since coords are continuous). */
static uint32_t sph_knn_walk(SpatialHandle *h, const int64_t C[3], const double c[3],
                             int dims, sph_cand_t *heap, uint32_t *n, uint32_t k) {
    uint32_t b = sph_bucket_of_cell(h, C);
    uint32_t walked = 0;
    for (uint32_t idx = h->buckets[b]; idx != SPH_NONE; idx = h->entries[idx].next) {
        int64_t ec[3]; sph_cell_of(h, h->entries[idx].pos, ec);
        if (!sph_cell_eq(ec, C)) continue;
        walked++;
        sph_heap_offer(heap, n, k, sph_dist2(h, h->entries[idx].pos, c, dims), h->entries[idx].value);
    }
    return walked;
}
static int sph_query_knn(SpatialHandle *h, const double c[3], uint32_t k, int dims, sph_collect_t *out) {
    double cc[3] = { c[0], c[1], dims==3 ? c[2] : 0 };
    uint32_t total = h->hdr->count;
    if (k > total) k = total;          /* can never return more than exist */
    if (k == 0) return 1;              /* empty hash (or k clamped to 0): empty result */
    sph_cand_t *heap = (sph_cand_t *)malloc((size_t)k * sizeof(sph_cand_t));
    if (!heap) return 0;
    uint32_t n = 0;                    /* candidates currently in the heap */

    if (h->wrap) {
        /* Toroidal: expanding shells would re-visit wrapped cells and double-offer
           the same entry to the heap.  The world is bounded, so scan every live
           entry once with the min-image distance -- O(max_entries), fine for a torus. */
        uint32_t me = h->hdr->max_entries;
        for (uint32_t idx = 0; idx < me; idx++)
            if (sph_is_live(h, idx))
                sph_heap_offer(heap, &n, k, sph_dist2(h, h->entries[idx].pos, cc, dims),
                               h->entries[idx].value);
    } else {
    int64_t center[3]; sph_cell_of(h, cc, center);
    double cs = h->hdr->cell_size;
    /* Termination is by how many live entries we have EXAMINED, not by a cell
       count: cell distance is unbounded (continuous coords), so a far point can
       sit arbitrarily many shells out. Snapshot the population; once seen==total
       every live entry has been visited and nothing remains to find. */
    uint32_t seen = 0;                 /* live, cell-matched entries examined */
    uint64_t cells_visited = 0;
    /* g < INT32_MAX is only a corruption guard against a bogus count; the real
       terminators below (have-k bound, or seen>=total) end the loop normally. */
    for (int64_t g = 0; g < INT32_MAX; g++) {
        /* Enumerate the Chebyshev shell at distance g -- its SURFACE only, not
           the full (2g+1)^d box, so per-shell work is O(g) in 2D / O(g^2) in 3D.
           cells_visited counts every cell walked, so the cap bounds real work. */
#define SPH_KNN_PROCESS(CX, CY, CZ) do {                                  \
            if (++cells_visited > (uint64_t)SPH_MAX_QUERY_CELLS) {        \
                free(heap); return SPH_Q_TOOBIG;                          \
            }                                                             \
            int64_t C_[3] = { (CX), (CY), (CZ) };                         \
            seen += sph_knn_walk(h, C_, cc, dims, heap, &n, k);           \
        } while (0)
        int64_t cx = center[0], cy = center[1], cz = center[2];
        if (g == 0) {
            SPH_KNN_PROCESS(cx, cy, cz);
        } else if (dims == 2) {
            for (int64_t dx = -g; dx <= g; dx++) {            /* top + bottom rows */
                SPH_KNN_PROCESS(cx + dx, cy - g, cz);
                SPH_KNN_PROCESS(cx + dx, cy + g, cz);
            }
            for (int64_t dy = -g + 1; dy <= g - 1; dy++) {    /* left + right cols */
                SPH_KNN_PROCESS(cx - g, cy + dy, cz);
                SPH_KNN_PROCESS(cx + g, cy + dy, cz);
            }
        } else {
            for (int64_t dz = -g; dz <= g; dz += 2 * g) {     /* two z caps (full faces) */
                for (int64_t dx = -g; dx <= g; dx++)
                    for (int64_t dy = -g; dy <= g; dy++)
                        SPH_KNN_PROCESS(cx + dx, cy + dy, cz + dz);
            }
            for (int64_t dz = -g + 1; dz <= g - 1; dz++) {    /* middle layers: xy perimeter */
                for (int64_t dx = -g; dx <= g; dx++) {
                    SPH_KNN_PROCESS(cx + dx, cy - g, cz + dz);
                    SPH_KNN_PROCESS(cx + dx, cy + g, cz + dz);
                }
                for (int64_t dy = -g + 1; dy <= g - 1; dy++) {
                    SPH_KNN_PROCESS(cx - g, cy + dy, cz + dz);
                    SPH_KNN_PROCESS(cx + g, cy + dy, cz + dz);
                }
            }
        }
#undef SPH_KNN_PROCESS
        /* stop once full and the next shell cannot contain anything closer:
           min distance from the query point to shell g+1 is g*cell_size. */
        if (n >= k) { double bound = (double)g * cs; if (bound*bound >= heap[0].d2) break; }
        /* stop once every live entry has been examined: nothing left to find. */
        if (seen >= total) break;
    }
    }   /* end !wrap */
    qsort(heap, n, sizeof(sph_cand_t), sph_cmp_d2);    /* nearest-first */
    for (uint32_t i = 0; i < n; i++)
        if (!sph_collect_push(out, heap[i].val)) { free(heap); return 0; }
    free(heap);
    return 1;
}

/* ================================================================
 * Collision-pair emitters (callers hold the read lock)
 * ================================================================ */

/* emit returns 1 to continue, 0 to abort (collector OOM). */
typedef int (*sph_pair_cb)(int64_t va, int64_t vb, void *ctx);

static int sph_pair_to_collect(int64_t va, int64_t vb, void *ctx) {
    sph_collect_t *c = (sph_collect_t *)ctx;
    return sph_collect_push(c, va) && sph_collect_push(c, vb);
}

/* Emit every unordered pair once. fixed_r >= 0: pairs with min-image centre
   distance < fixed_r. fixed_r < 0: collision mode -- distance < radius_a+radius_b.
   Enumeration/distance are 3D when any entry has a non-zero z (entries are
   bucketed by their full 3D cell) or the world wraps in z, else 2D.
   Returns SPH_Q_OK / OOM / TOOBIG. */
static int sph_pairs(SpatialHandle *h, double fixed_r, sph_pair_cb emit, void *ctx) {
    double cs = h->hdr->cell_size;
    uint32_t me = h->hdr->max_entries;
    int collide = (fixed_r < 0.0);
    /* one pass: largest radius (collision reach) + whether any entry is 3D, so the
       enumeration covers the real z-cell range rather than only z-cell 0 */
    double maxr = 0.0; int has3d = 0;
    for (uint32_t i = 0; i < me; i++) {
        if (!sph_is_live(h, i)) continue;
        if (collide && h->entries[i].radius > maxr) maxr = h->entries[i].radius;
        if (h->entries[i].pos[2] != 0.0) has3d = 1;
    }
    if (collide) { if (maxr <= 0.0) return SPH_Q_OK; }  /* no radii -> points never collide */
    else if (!(fixed_r > 0.0)) return SPH_Q_OK;         /* non-positive radius -> nothing */
    int dims = (h->world[2] > 0.0 || has3d) ? 3 : 2;
    for (uint32_t a = 0; a < me; a++) {
        if (!sph_is_live(h, a)) continue;
        const double *pa = h->entries[a].pos;
        double ra = h->entries[a].radius;
        double reach_d = ceil((collide ? (ra + maxr) : fixed_r) / cs);
        /* defensive: the API validates radii, but a corrupt stored radius could make this
           NaN, which would slip past the cap check below (NaN >= X is false) into the cast */
        if (!(reach_d >= 0)) reach_d = 0;
        if (reach_d >= (double)SPH_MAX_QUERY_CELLS) return SPH_Q_TOOBIG;  /* avoid int64 overflow */
        int64_t reach = (int64_t)reach_d;
        int64_t ac[3]; sph_cell_raw(h, pa, ac);
        int64_t cnt[3] = { 1, 1, 1 };
        uint64_t cells = 1;
        for (int i = 0; i < dims; i++) {
            uint64_t span = (uint64_t)(2 * reach + 1);
            if (h->wrap_cells[i] > 0 && span > (uint64_t)h->wrap_cells[i]) span = (uint64_t)h->wrap_cells[i];
            if (span >= (uint64_t)SPH_MAX_QUERY_CELLS) return SPH_Q_TOOBIG;
            if (cells > (uint64_t)SPH_MAX_QUERY_CELLS / span) return SPH_Q_TOOBIG;
            cells *= span; cnt[i] = (int64_t)span;
        }
        int64_t b0 = ac[0]-reach, b1 = ac[1]-reach, b2 = ac[2]-reach;
        for (int64_t i0 = 0; i0 < cnt[0]; i0++) {
            int64_t C0 = h->wrap ? sph_wrap_cell(b0+i0, h->wrap_cells[0]) : b0+i0;
            for (int64_t i1 = 0; i1 < cnt[1]; i1++) {
                int64_t C1 = h->wrap ? sph_wrap_cell(b1+i1, h->wrap_cells[1]) : b1+i1;
                for (int64_t i2 = 0; i2 < cnt[2]; i2++) {   /* cnt[2]==1 when dims==2 */
                    int64_t C2 = (dims == 3) ? (h->wrap ? sph_wrap_cell(b2+i2, h->wrap_cells[2]) : b2+i2) : 0;
                    int64_t C[3] = { C0, C1, C2 };
                    uint32_t bkt = sph_bucket_of_cell(h, C);
                    for (uint32_t idx = h->buckets[bkt]; idx != SPH_NONE; idx = h->entries[idx].next) {
                        if (idx <= a) continue;                  /* unordered: emit each pair once */
                        int64_t ec[3]; sph_cell_of(h, h->entries[idx].pos, ec);
                        if (!sph_cell_eq(ec, C)) continue;       /* hash-collision guard */
                        double thr = collide ? (ra + h->entries[idx].radius) : fixed_r;
                        if (sph_dist2(h, pa, h->entries[idx].pos, dims) < thr*thr)
                            if (!emit(h->entries[a].value, h->entries[idx].value, ctx)) return SPH_Q_OOM;
                    }
                }
            }
        }
    }
    return SPH_Q_OK;
}

/* ================================================================
 * Lifecycle helpers: clear, chain stats
 * ================================================================ */

static void sph_clear_locked(SpatialHandle *h) {
    uint32_t me = h->hdr->max_entries, nb = h->hdr->num_buckets;
    for (uint32_t b = 0; b < nb; b++) h->buckets[b] = SPH_NONE;
    memset(h->bitmap, 0, (size_t)h->bitmap_words * sizeof(uint64_t));
    for (uint32_t i = 0; i < me; i++) h->entries[i].next = (i+1 < me) ? i+1 : SPH_NONE;
    h->hdr->free_head = 0;   /* max_entries >= 1 (validated at create) */
    h->hdr->count = 0;
}
static void sph_chain_stats(SpatialHandle *h, uint32_t *occupied, uint32_t *max_chain,
                            uint32_t *max_cell) {
    uint32_t occ = 0, mx = 0, mxc = 0, nb = h->hdr->num_buckets;
    for (uint32_t b = 0; b < nb; b++) {
        uint32_t len = 0;
        for (uint32_t idx = h->buckets[b]; idx != SPH_NONE; idx = h->entries[idx].next) {
            len++;
            /* per-cell occupancy: count chain entries sharing idx's cell (entries of
               one cell always hash to one bucket, so a cell is a subset of a chain) */
            int64_t ci[3]; sph_cell_of(h, h->entries[idx].pos, ci);
            uint32_t cc = 0;
            for (uint32_t j = h->buckets[b]; j != SPH_NONE; j = h->entries[j].next) {
                int64_t cj[3]; sph_cell_of(h, h->entries[j].pos, cj);
                if (sph_cell_eq(ci, cj)) cc++;
            }
            if (cc > mxc) mxc = cc;
        }
        if (len) { occ++; if (len > mx) mx = len; }
    }
    *occupied = occ; *max_chain = mx; *max_cell = mxc;
}

#endif /* SPHASH_H */
