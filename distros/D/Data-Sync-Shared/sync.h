/*
 * sync.h -- Shared-memory synchronization primitives for Linux
 *
 * Five primitives:
 *   Semaphore -- bounded counter (CAS-based, cross-process resource limiting)
 *   Barrier   -- N processes rendezvous at a point before proceeding
 *   RWLock    -- reader-writer lock for external resources
 *   Condvar   -- condition variable with futex wait/signal/broadcast
 *   Once      -- one-time initialization gate (like pthread_once)
 *
 * All use file-backed mmap(MAP_SHARED) for cross-process sharing,
 * futex for blocking wait, and PID-based stale lock recovery.
 */

#ifndef SYNC_H
#define SYNC_H

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

/* ================================================================
 * Constants
 * ================================================================ */

#define SYNC_MAGIC        0x53594E31U  /* "SYN1" */
#define SYNC_VERSION      3  /* v3: on-disk format adds the RWLock reader-slot occupancy bitmap (layout change) */

/* Primitive type IDs */
#define SYNC_TYPE_SEMAPHORE  0
#define SYNC_TYPE_BARRIER    1
#define SYNC_TYPE_RWLOCK     2
#define SYNC_TYPE_CONDVAR    3
#define SYNC_TYPE_ONCE       4

#define SYNC_ERR_BUFLEN      256
#define SYNC_SPIN_LIMIT      32
#define SYNC_LOCK_TIMEOUT_SEC 2
#ifndef SYNC_READER_SLOTS
#define SYNC_READER_SLOTS    1024  /* per-process reader-counter mirror for RWLock */
#endif

/* Occupancy bitmap (RWLock only): one bit per reader slot, set when a process
 * claims its slot and cleared on clean release.  A draining writer scans these
 * SYNC_OCC_WORDS words to visit only OCCUPIED slots (O(words + live readers))
 * instead of all SYNC_READER_SLOTS.  Stored right after the reader-slot table. */
#define SYNC_OCC_WORDS   (((SYNC_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define SYNC_OCC_BYTES   ((uint64_t)SYNC_OCC_WORDS * 8)      /* 128 bytes */

/* ================================================================
 * Per-process reader-slot table (for RWLock dead-reader recovery)
 *
 * Allocated only when type == SYNC_TYPE_RWLOCK (Option A).
 * ~16KB per RWLock (1024 slots * 16 bytes); zero overhead for other types.
 *
 * In the reader-slots-only rwlock a reader's ENTIRE contribution to the shared
 * lock is `rdepth` in its OWN slot -- there is no separate shared reader counter
 * to fall out of sync with it -- so a dead reader's contribution is exactly this
 * one word, which a draining writer neutralises by clearing the slot's pid (the
 * scan then ignores the slot).  No orphaned counter can exist, so there is no
 * quiescent force-reset and sustained readers cannot starve a writer.  _rsv1/
 * _rsv2 are kept only to preserve the 16-byte slot size across released builds.
 * ================================================================ */

typedef struct {
    uint32_t pid;      /* owning PID, 0 = free */
    uint32_t rdepth;   /* read-locks THIS process currently holds (recursion-safe) */
    uint32_t _rsv1;    /* reserved (was waiters_parked); unused, kept for layout size */
    uint32_t _rsv2;    /* reserved (was writers_parked); unused, kept for layout size */
} SyncReaderSlot;

/* ================================================================
 * Header (128 bytes = 2 cache lines, lives at start of mmap)
 * ================================================================ */

typedef struct {
    /* ---- Cache line 0 (0-63): immutable after create ---- */
    uint32_t magic;          /* 0 */
    uint32_t version;        /* 4 */
    uint32_t type;           /* 8: SYNC_TYPE_* */
    uint32_t param;          /* 12: type-specific (sem max, barrier count, etc.) */
    uint64_t total_size;     /* 16: mmap size */
    uint64_t reader_slots_off;/* 24: offset of SyncReaderSlot[SYNC_READER_SLOTS], 0 if not allocated (non-RWLock primitives) */
    uint32_t slotless_rdepth; /* 32: RWLock live readers holding the lock with NO reader-slot
                                     (claimed when the slot table was full). A draining writer
                                     cannot attribute these to a pid, so it waits them out (the
                                     documented slotless residual). Defaults to 0, so images from
                                     before this field (was padding) stay compatible. */
    uint8_t  _pad0[28];      /* 36-63 */

    /* ---- Cache line 1 (64-127): mutable state ---- */

    /* Semaphore: value = current count, waiters = blocked acquirers */
    /* Barrier: value = arrived count, waiters = blocked at barrier,
                generation = increments each time barrier trips */
    /* RWLock: value = WRITER word only (0=free, 0x80000000|pid=writer; readers
               are NOT counted here -- each holds rdepth in its own reader-slot),
               waiters = parked lockers (readers+writers) hint on the value futex */
    /* Condvar: value = signal counter (futex word), waiters = blocked waiters,
                mutex = associated mutex for predicate protection */
    /* Once: value = state (0=INIT, 1=RUNNING|pid, 2=DONE),
             waiters = blocked on completion */

    uint32_t value;          /* 64: primary state word (futex target) */
    uint32_t waiters;        /* 68: waiter count */
    uint32_t generation;     /* 72: barrier generation / condvar epoch */
    uint32_t mutex;          /* 76: condvar mutex (0 or PID|0x80000000) */
    uint32_t mutex_waiters;  /* 80: condvar mutex waiter count */
    uint32_t stat_recoveries;/* 84 */
    uint64_t stat_acquires;  /* 88 */
    uint64_t stat_releases;  /* 96 */
    uint64_t stat_waits;     /* 104 */
    uint64_t stat_timeouts;  /* 112 */
    uint32_t stat_signals;   /* 120 */
    uint32_t drain_seq;      /* 124: RWLock futex a releasing reader bumps to wake a
                                     writer draining readers in wrlock Phase 2 */
} SyncHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(SyncHeader) == 128, "SyncHeader must be 128 bytes");
#endif

/* ================================================================
 * Process-local handle
 * ================================================================ */

typedef struct {
    SyncHeader *hdr;
    size_t      mmap_size;
    char       *path;
    int         notify_fd;   /* eventfd, -1 if disabled */
    int         backing_fd;  /* memfd fd, -1 for file-backed/anonymous */
    SyncReaderSlot *reader_slots; /* in mmap, SYNC_READER_SLOTS entries; NULL if not RWLock */
    uint64_t   *occ;         /* in mmap, SYNC_OCC_WORDS-word reader-slot occupancy bitmap; NULL if not RWLock (set alongside reader_slots) */
    uint32_t    my_slot_idx; /* UINT32_MAX = unclaimed; per-process slot index */
    uint32_t    cached_pid;  /* getpid() at claim time */
    uint32_t    cached_fork_gen; /* fork-generation at claim time */
    uint32_t    slotless_held; /* rwlock read-locks this handle holds without a reader-slot */
} SyncHandle;

/* ================================================================
 * Utility
 * ================================================================ */

static inline void sync_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* A zombie (dead but not yet reaped) still answers kill(pid,0) as alive, so a
 * process that crashed while holding the lock and lingers unreaped would never
 * be recovered.  Treat /proc/<pid>/stat state 'Z' as dead.  Linux-only (as is
 * this module); if /proc is unreadable we fall back to "alive" (safe: we never
 * force-recover a possibly-live holder). */
static inline int sync_pid_is_zombie(uint32_t pid) {
    char path[32], buf[256];
    snprintf(path, sizeof(path), "/proc/%u/stat", (unsigned)pid);
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return 0;
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    if (n <= 0) return 0;
    buf[n] = '\0';
    /* "pid (comm) state ..."; comm may contain ')', so scan to the last one. */
    char *rp = strrchr(buf, ')');
    if (!rp || rp + 2 >= buf + n) return 0;   /* need ") X" within the bytes read */
    return rp[1] == ' ' && rp[2] == 'Z';
}
static inline int sync_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !sync_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Convert timeout in seconds (double) to absolute deadline */
static inline void sync_make_deadline(double timeout, struct timespec *deadline) {
    clock_gettime(CLOCK_MONOTONIC, deadline);
    if (!(timeout < 1e9)) timeout = 1e9; /* clamp Inf/NaN/huge: avoid UB (time_t) cast -> instant spurious timeout */
    deadline->tv_sec += (time_t)timeout;
    deadline->tv_nsec += (long)((timeout - (double)(time_t)timeout) * 1e9);
    if (deadline->tv_nsec >= 1000000000L) {
        deadline->tv_sec++;
        deadline->tv_nsec -= 1000000000L;
    }
}

/* Compute remaining timespec from absolute deadline. Returns 0 if deadline passed. */
static inline int sync_remaining_time(const struct timespec *deadline,
                                       struct timespec *remaining) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    remaining->tv_sec = deadline->tv_sec - now.tv_sec;
    remaining->tv_nsec = deadline->tv_nsec - now.tv_nsec;
    if (remaining->tv_nsec < 0) {
        remaining->tv_sec--;
        remaining->tv_nsec += 1000000000L;
    }
    return remaining->tv_sec >= 0;
}

/* ================================================================
 * Mutex helpers (for Condvar's internal mutex)
 * ================================================================ */

#define SYNC_MUTEX_WRITER_BIT 0x80000000U
#define SYNC_MUTEX_PID_MASK   0x7FFFFFFFU
#define SYNC_MUTEX_VAL(pid)   (SYNC_MUTEX_WRITER_BIT | ((uint32_t)(pid) & SYNC_MUTEX_PID_MASK))

static const struct timespec sync_lock_timeout = { SYNC_LOCK_TIMEOUT_SEC, 0 };

static inline void sync_recover_stale_mutex(SyncHeader *hdr, uint32_t observed) {
    if (!__atomic_compare_exchange_n(&hdr->mutex, &observed, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
}

static inline void sync_mutex_lock(SyncHeader *hdr) {
    uint32_t mypid = SYNC_MUTEX_VAL((uint32_t)getpid());
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->mutex, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        __atomic_add_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        /* StoreLoad: publish mutex_waiters++ before re-reading mutex, so an
         * unlocker sees our registration or we see the unlock (cur==0 -> retry). */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        uint32_t cur = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->mutex, FUTEX_WAIT, cur,
                              &sync_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
                uint32_t val = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
                if (val >= SYNC_MUTEX_WRITER_BIT) {
                    uint32_t pid = val & SYNC_MUTEX_PID_MASK;
                    if (!sync_pid_alive(pid))
                        sync_recover_stale_mutex(hdr, val);
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline void sync_mutex_unlock(SyncHeader *hdr) {
    __atomic_store_n(&hdr->mutex, 0, __ATOMIC_RELEASE);
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
}

/* ================================================================
 * Futex-based write-preferring read-write lock (reader-slots-only)
 * for SYNC_TYPE_RWLOCK, with dead-process recovery
 *
 * value == 0:                 unlocked (no writer)
 * value == 0x80000000 | pid:  write-locked by pid
 *
 * The reader count is NOT stored in `value`.  It is DISTRIBUTED across
 * per-process reader slots: each slot's `rdepth` is that process's entire
 * contribution to the lock.  A reader publishes its presence in its own slot and
 * then re-checks `value`; a writer publishes `value` and then scans every slot
 * until all live readers' rdepth reach 0.  Sequentially-consistent store+load on
 * each side (a Dekker handshake) gives mutual exclusion.
 *
 * Because a reader's whole contribution is ONE atomic word owned by ONE process,
 * a crashed reader is recovered by clearing that one slot (CAS its pid to 0) --
 * no second counter to strand, no orphaned +1, no quiescent force-reset.  A
 * reader killed anywhere in rdlock/rdunlock leaves at most `rdepth>0` in its dead
 * slot, which the draining writer clears directly, so sustained read traffic can
 * never starve a writer.  Write-preference is inherent in the gate (new readers
 * see value!=0 and yield).
 * ================================================================ */

#define SYNC_RWLOCK_WRITER_BIT 0x80000000U
#define SYNC_RWLOCK_PID_MASK   0x7FFFFFFFU
#define SYNC_RWLOCK_WR(pid)    (SYNC_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & SYNC_RWLOCK_PID_MASK))

static inline int sync_rwlock_try_rdlock(SyncHandle *h);
static inline int sync_rwlock_try_wrlock(SyncHandle *h);

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * A single CAS observed->0 wins the recovery race (a loser's CAS just fails);
 * this module has no extra shared lock state to repair.  Bumps stat_recoveries
 * and wakes any lockers parked on the value futex. */
static inline void sync_recover_stale_rwlock(SyncHeader *hdr, uint32_t observed) {
    if (!__atomic_compare_exchange_n(&hdr->value, &observed, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ---- Per-process reader-slot lifecycle (dead-reader recovery) ----
 * Each process claims one SyncReaderSlot lazily on first rwlock op so that a
 * SIGKILL'd reader's rdepth contribution can be neutralised by a draining
 * writer.  Only relevant for SYNC_TYPE_RWLOCK; non-RWLock primitives leave
 * h->reader_slots == NULL and this helper is a no-op. */
static uint32_t sync_fork_gen = 0;
static pthread_once_t sync_atfork_once = PTHREAD_ONCE_INIT;
static void sync_on_fork_child(void) {
    __atomic_add_fetch(&sync_fork_gen, 1, __ATOMIC_RELAXED);
}
static void sync_atfork_init(void) {
    pthread_atfork(NULL, NULL, sync_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before that slot's rdepth can go
 * non-zero (the bit is set in claim, which precedes any rdlock's rdepth++),
 * letting a writer's SEQ_CST bitmap scan never miss a slot a committed reader
 * holds.  Callers guarantee h->occ != NULL (it is set alongside h->reader_slots,
 * and every call site is under an `if (h->reader_slots)` guard). */
static inline void sync_occ_set(SyncHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void sync_occ_clear(SyncHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

static inline void sync_claim_reader_slot(SyncHandle *h) {
    if (!h->reader_slots) return;
    pthread_once(&sync_atfork_once, sync_atfork_init);
    uint32_t cur_gen = __atomic_load_n(&sync_fork_gen, __ATOMIC_RELAXED);
    if (h->cached_fork_gen != cur_gen) {
        h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
        h->cached_fork_gen = cur_gen;
        h->my_slot_idx = UINT32_MAX;
    }
    if (h->my_slot_idx != UINT32_MAX) return;
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    uint32_t start = now_pid % SYNC_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < SYNC_READER_SLOTS; i++) {
        uint32_t s = (start + i) % SYNC_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            sync_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < SYNC_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || sync_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            sync_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = i;
            return;
        }
    }
    /* Table full -- leave my_slot_idx = UINT32_MAX so this handle takes the
     * slotless path (lock still works; recovery of THIS reader's death is the
     * documented slotless limitation). */
}

/* Inspect the writer word after a futex-wait timeout.  If a dead writer holds
 * it, force-recover.  Dead READERS need no action here: only a writer that owns
 * `value` drains readers, and it clears dead readers inline in its own scan. */
static inline void sync_recover_after_timeout(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
    if (val >= SYNC_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & SYNC_RWLOCK_PID_MASK;
        if (!sync_pid_alive(pid))
            sync_recover_stale_rwlock(hdr, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring `value`) wait on the value futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves waiters over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void sync_park(SyncHandle *h) {
    __atomic_add_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
}
static inline void sync_unpark(SyncHandle *h) {
    __atomic_sub_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the value re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST value-store + rdepth-scan.  dec() peels slotless first so
 * a slot claimed mid-hold cannot misattribute the decrement. */
static inline void sync_rdepth_inc(SyncHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void sync_rdepth_dec(SyncHandle *h) {
    if (h->slotless_held > 0) {
        h->slotless_held--;
        __atomic_sub_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_RELEASE);
    } else if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_RELEASE);
    }
}

/* Wake a writer that may be draining readers (it waits on drain_seq).  Called
 * after every rdepth decrement so a released read lock lets the writer re-scan
 * promptly instead of waiting out its timeout. */
static inline void sync_reader_wake_drain(SyncHandle *h) {
    if (__atomic_load_n(&h->hdr->value, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

/* Give-up path for the timed/try readers: retract our published rdepth and wake
 * a draining writer so it re-scans without our contribution. */
static inline void sync_reader_abort(SyncHandle *h) {
    sync_rdepth_dec(h);
    sync_reader_wake_drain(h);
}

/* Writer-side scan of all reader slots: reclaim any dead reader (CAS its pid to
 * 0) and report whether a LIVE reader still holds (rdepth>0), including the
 * slotless residual.  Shared by wrlock Phase 2, try_wrlock, and wrlock_timed. */
static inline int sync_rwlock_readers_busy(SyncHandle *h) {
    int busy = 0;
    if (h->reader_slots) {
        /* Visit only OCCUPIED slots via the occupancy bitmap (SEQ_CST: a committed
         * reader's bit -- set in claim, before its rdepth++ -- is ordered before
         * this scan, so no held slot is skipped).  O(SYNC_OCC_WORDS + live readers)
         * instead of O(SYNC_READER_SLOTS). */
        for (uint32_t w = 0; w < SYNC_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                      /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                 /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                /* no live owner -- stale rdepth, ignore */
                if (!sync_pid_alive(pid)) {
                    /* Dead reader: clear its pid so the slot no longer counts (its
                     * whole contribution WAS this slot).  Leave the occ bit SET
                     * (harmless -- a later scan hits pid==0 and skips, a re-claim
                     * re-sets it) to avoid racing a concurrent claimant.  rdepth is
                     * left stale but is now ignored (pid==0) and zeroed by the next
                     * claimant.  Count it as a recovery (gated on the CAS so it is
                     * tallied exactly once). */
                    uint32_t ep = pid;
                    if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &ep, 0,
                            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                        __atomic_add_fetch(&h->hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
                    continue;
                }
                busy = 1;                              /* live reader still holding */
            }
        }
    }
    /* A live slotless reader keeps us waiting; a crashed slotless reader that
     * cannot be attributed to a pid is the documented slotless limitation. */
    if (__atomic_load_n(&h->hdr->slotless_rdepth, __ATOMIC_SEQ_CST) != 0)
        busy = 1;
    return busy;
}

static inline void sync_rwlock_rdlock(SyncHandle *h) {
    sync_claim_reader_slot(h);
    SyncHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check value.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST value CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            sync_rdepth_inc(h);
            if (__atomic_load_n(&hdr->value, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            sync_reader_abort(h);             /* retract rdepth + wake the draining writer */
            spin = 0;
            continue;
        }
        /* value != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= SYNC_RWLOCK_WRITER_BIT &&
            !sync_pid_alive(cur & SYNC_RWLOCK_PID_MASK)) {
            sync_recover_stale_rwlock(hdr, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        sync_park(h);
        /* StoreLoad: publish our parked registration before re-reading value
         * (weak-memory lost-wakeup guard). */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->value, FUTEX_WAIT, cur,
                              &sync_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                sync_unpark(h);
                sync_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        sync_unpark(h);
        spin = 0;
    }
}

static inline void sync_rwlock_rdunlock(SyncHandle *h) {
    sync_rdepth_dec(h);                /* RELEASE: drop our entire contribution */
    sync_reader_wake_drain(h);         /* if a writer is draining, wake it to re-scan */
}

/* try_rdlock: one-shot, non-blocking.  Returns 1 on success, 0 on failure. */
static inline int sync_rwlock_try_rdlock(SyncHandle *h) {
    sync_claim_reader_slot(h);
    SyncHeader *hdr = h->hdr;
    uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_ACQUIRE);
    if (cur != 0) {
        /* A writer holds or is acquiring.  Recover once if it is dead, re-read. */
        if (cur >= SYNC_RWLOCK_WRITER_BIT &&
            !sync_pid_alive(cur & SYNC_RWLOCK_PID_MASK)) {
            sync_recover_stale_rwlock(hdr, cur);
            cur = __atomic_load_n(&hdr->value, __ATOMIC_ACQUIRE);
        }
        if (cur != 0) return 0;
    }
    sync_rdepth_inc(h);
    if (__atomic_load_n(&hdr->value, __ATOMIC_SEQ_CST) != 0) {
        /* A writer appeared during our publish -- yield (write-preferring). */
        sync_reader_abort(h);
        return 0;
    }
    return 1;
}

/* Timed rdlock: returns 1 on success, 0 on timeout.  timeout<0 = infinite,
 * timeout==0 = one-shot try.  Same optimistic gate as sync_rwlock_rdlock; the
 * gate FUTEX_WAIT is bounded by an absolute deadline computed from `timeout`.
 * On give-up we hold NOTHING (every 0-return has already retracted rdepth). */
static inline int sync_rwlock_rdlock_timed(SyncHandle *h, double timeout) {
    if (timeout == 0) return sync_rwlock_try_rdlock(h);
    sync_claim_reader_slot(h);
    SyncHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistic publish + Dekker re-check (see sync_rwlock_rdlock). */
            sync_rdepth_inc(h);
            if (__atomic_load_n(&hdr->value, __ATOMIC_SEQ_CST) == 0)
                return 1;
            sync_reader_abort(h);      /* retract rdepth + wake the draining writer */
            if (has_deadline && !sync_remaining_time(&deadline, &remaining))
                return 0;              /* deadline passed; we hold nothing */
            spin = 0;
            continue;
        }
        if (cur >= SYNC_RWLOCK_WRITER_BIT &&
            !sync_pid_alive(cur & SYNC_RWLOCK_PID_MASK)) {
            sync_recover_stale_rwlock(hdr, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        sync_park(h);
        /* StoreLoad: publish our parked registration before re-reading value. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        if (cur != 0) {
            /* Cap the wait at SYNC_LOCK_TIMEOUT_SEC so stale-holder recovery runs
             * periodically even with a longer user deadline. */
            struct timespec *pts = (struct timespec *)&sync_lock_timeout;
            int capped = 1;
            if (has_deadline) {
                if (!sync_remaining_time(&deadline, &remaining)) {
                    sync_unpark(h);
                    return 0;          /* deadline passed; nothing held */
                }
                if (remaining.tv_sec < SYNC_LOCK_TIMEOUT_SEC) { pts = &remaining; capped = 0; }
            }
            long rc = syscall(SYS_futex, &hdr->value, FUTEX_WAIT, cur, pts, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                sync_unpark(h);
                if (!capped) return 0; /* user deadline expired; nothing held */
                sync_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        sync_unpark(h);
        spin = 0;
    }
}

static inline void sync_rwlock_wrlock(SyncHandle *h) {
    sync_claim_reader_slot(h);   /* refresh cached_pid + own a slot across fork */
    SyncHeader *hdr = h->hdr;
    /* Encode PID in the value word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = SYNC_RWLOCK_WR((uint32_t)getpid());
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->value, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current value.  Recover a dead writer. */
        if (expected >= SYNC_RWLOCK_WRITER_BIT &&
            !sync_pid_alive(expected & SYNC_RWLOCK_PID_MASK)) {
            sync_recover_stale_rwlock(hdr, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        sync_park(h);
        /* StoreLoad: see the rdlock park path (weak-memory lost-wakeup guard). */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->value, FUTEX_WAIT, cur,
                              &sync_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                sync_unpark(h);
                sync_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        sync_unpark(h);
        spin = 0;
    }
    /* Phase 2: we own `value`, so no NEW reader can join (they see value!=0 and
     * yield).  Drain the readers that were already holding when we won the CAS.
     * The SEQ_CST CAS above + the SEQ_CST rdepth loads below are the writer side
     * of the Dekker handshake. */
    for (;;) {
        uint32_t v = __atomic_load_n(&hdr->drain_seq, __ATOMIC_RELAXED);  /* snapshot BEFORE scan */
        if (!sync_rwlock_readers_busy(h))
            return;                                    /* exclusive: value held + every rdepth 0 */
        /* Wait for a reader to release (drain_seq bump) or time out to re-scan
         * (which reclaims any newly-dead slotted reader). */
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &sync_lock_timeout, NULL, 0);
    }
}

static inline void sync_rwlock_wrunlock(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* try_wrlock: one-shot.  Returns 1 iff we obtain exclusive ownership, 0
 * otherwise.  A try must NOT wait for readers to drain. */
static inline int sync_rwlock_try_wrlock(SyncHandle *h) {
    sync_claim_reader_slot(h);
    SyncHeader *hdr = h->hdr;
    uint32_t mypid = SYNC_RWLOCK_WR((uint32_t)getpid());
    uint32_t expected = 0;
    if (!__atomic_compare_exchange_n(&hdr->value, &expected, mypid,
            0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED)) {
        /* Contended.  Recover a dead writer and retry once; else fail. */
        if (expected >= SYNC_RWLOCK_WRITER_BIT &&
            !sync_pid_alive(expected & SYNC_RWLOCK_PID_MASK)) {
            sync_recover_stale_rwlock(hdr, expected);
            expected = 0;
            if (!__atomic_compare_exchange_n(&hdr->value, &expected, mypid,
                    0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
                return 0;
        } else {
            return 0;
        }
    }
    /* We hold `value`.  Dekker: our SEQ_CST CAS + the SEQ_CST rdepth loads in the
     * scan cannot both miss a reader whose SEQ_CST publish + value re-check ran. */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (sync_rwlock_readers_busy(h)) {
        /* Readers still hold -- release the writer word and fail (no waiting). */
        __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
            syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
        return 0;
    }
    return 1;   /* exclusive: value held + every rdepth 0 */
}

/* Timed wrlock: returns 1 on success, 0 on timeout.  timeout<0 = infinite,
 * timeout==0 = one-shot try.  BOTH the Phase-1 value acquire and the Phase-2
 * drain wait are bounded by an absolute deadline; on a Phase-2 give-up we own
 * `value` and MUST release it before returning 0. */
static inline int sync_rwlock_wrlock_timed(SyncHandle *h, double timeout) {
    if (timeout == 0) return sync_rwlock_try_wrlock(h);
    sync_claim_reader_slot(h);
    SyncHeader *hdr = h->hdr;
    uint32_t mypid = SYNC_RWLOCK_WR((uint32_t)getpid());
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);
    /* Phase 1: acquire the writer word, bounded by the deadline. */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->value, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        if (expected >= SYNC_RWLOCK_WRITER_BIT &&
            !sync_pid_alive(expected & SYNC_RWLOCK_PID_MASK)) {
            sync_recover_stale_rwlock(hdr, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        sync_park(h);
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        if (cur != 0) {
            struct timespec *pts = (struct timespec *)&sync_lock_timeout;
            int capped = 1;
            if (has_deadline) {
                if (!sync_remaining_time(&deadline, &remaining)) {
                    sync_unpark(h);
                    return 0;          /* deadline passed; no lock held */
                }
                if (remaining.tv_sec < SYNC_LOCK_TIMEOUT_SEC) { pts = &remaining; capped = 0; }
            }
            long rc = syscall(SYS_futex, &hdr->value, FUTEX_WAIT, cur, pts, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                sync_unpark(h);
                if (!capped) return 0; /* user deadline expired; no lock held */
                sync_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        sync_unpark(h);
        spin = 0;
    }
    /* Phase 2: we own `value`; drain existing readers, bounded by the deadline.
     * On a deadline give-up we must release the writer word we hold. */
    for (;;) {
        uint32_t v = __atomic_load_n(&hdr->drain_seq, __ATOMIC_RELAXED);
        if (!sync_rwlock_readers_busy(h))
            return 1;                                  /* exclusive */
        struct timespec *pts = (struct timespec *)&sync_lock_timeout;
        if (has_deadline) {
            if (!sync_remaining_time(&deadline, &remaining)) {
                /* Deadline hit while draining -- release the value word we own. */
                __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
                __atomic_thread_fence(__ATOMIC_SEQ_CST);
                if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
                return 0;
            }
            if (remaining.tv_sec < SYNC_LOCK_TIMEOUT_SEC) pts = &remaining;
        }
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, pts, NULL, 0);
    }
}

/* Downgrade: convert a held write lock (value == WRITER|pid) to a read lock.
 * Publish our reader rdepth FIRST (SEQ_CST) so a writer that later CASes `value`
 * sees our rdepth in its drain scan, THEN release the writer word. */
static inline void sync_rwlock_downgrade(SyncHandle *h) {
    sync_claim_reader_slot(h);
    SyncHeader *hdr = h->hdr;
    sync_rdepth_inc(h);                            /* publish as a reader before releasing */
    __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
    /* StoreLoad: publish the release before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Semaphore operations
 *
 * value = current count (0..param where param=max)
 * CAS-based acquire/release, futex wait when 0
 * ================================================================ */

static inline int sync_sem_try_acquire(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    for (;;) {
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        if (cur == 0) return 0;
        if (__atomic_compare_exchange_n(&hdr->value, &cur, cur - 1,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_add_fetch(&hdr->stat_acquires, 1, __ATOMIC_RELAXED);
            return 1;
        }
    }
}

static inline int sync_sem_try_acquire_n(SyncHandle *h, uint32_t n) {
    if (n == 0) return 1;
    SyncHeader *hdr = h->hdr;
    for (;;) {
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        if (cur < n) return 0;
        if (__atomic_compare_exchange_n(&hdr->value, &cur, cur - n,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_add_fetch(&hdr->stat_acquires, 1, __ATOMIC_RELAXED);
            return 1;
        }
    }
}

static inline int sync_sem_acquire_n(SyncHandle *h, uint32_t n, double timeout) {
    if (n == 0) return 1;
    if (sync_sem_try_acquire_n(h, n)) return 1;
    if (timeout == 0) return 0;

    SyncHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);

    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        if (cur >= n) {
            if (__atomic_compare_exchange_n(&hdr->value, &cur, cur - n,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
                __atomic_add_fetch(&hdr->stat_acquires, 1, __ATOMIC_RELAXED);
                return 1;
            }
            continue;
        }

        __atomic_add_fetch(&hdr->waiters, 1, __ATOMIC_RELEASE);

        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!sync_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELEASE);
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                return 0;
            }
            pts = &remaining;
        }

        syscall(SYS_futex, &hdr->value, FUTEX_WAIT, cur, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELEASE);

        if (sync_sem_try_acquire_n(h, n)) return 1;

        if (has_deadline) {
            if (!sync_remaining_time(&deadline, &remaining)) {
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                return 0;
            }
        }
    }
}

static inline int sync_sem_acquire(SyncHandle *h, double timeout) {
    if (sync_sem_try_acquire(h)) return 1;
    if (timeout == 0) return 0;

    SyncHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);

    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        if (cur > 0) {
            if (__atomic_compare_exchange_n(&hdr->value, &cur, cur - 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
                __atomic_add_fetch(&hdr->stat_acquires, 1, __ATOMIC_RELAXED);
                return 1;
            }
            continue;
        }

        __atomic_add_fetch(&hdr->waiters, 1, __ATOMIC_RELEASE);

        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!sync_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELEASE);
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                return 0;
            }
            pts = &remaining;
        }

        syscall(SYS_futex, &hdr->value, FUTEX_WAIT, 0, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELEASE);

        /* Retry acquire after wakeup */
        if (sync_sem_try_acquire(h)) return 1;

        if (has_deadline) {
            if (!sync_remaining_time(&deadline, &remaining)) {
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                return 0;
            }
        }
    }
}

static inline void sync_sem_release(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    uint32_t max_val = hdr->param;
    for (;;) {
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        uint32_t next = cur + 1;
        if (next > max_val) next = max_val;  /* clamp at max */
        if (__atomic_compare_exchange_n(&hdr->value, &cur, next,
                1, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
            __atomic_add_fetch(&hdr->stat_releases, 1, __ATOMIC_RELAXED);
            /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
            __atomic_thread_fence(__ATOMIC_SEQ_CST);
            if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->value, FUTEX_WAKE, 1, NULL, NULL, 0);
            return;
        }
    }
}

static inline void sync_sem_release_n(SyncHandle *h, uint32_t n) {
    if (n == 0) return;
    SyncHeader *hdr = h->hdr;
    uint32_t max_val = hdr->param;
    for (;;) {
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        uint32_t next = (n > max_val - cur) ? max_val : cur + n;
        if (__atomic_compare_exchange_n(&hdr->value, &cur, next,
                1, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
            __atomic_add_fetch(&hdr->stat_releases, 1, __ATOMIC_RELAXED);
            /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
            __atomic_thread_fence(__ATOMIC_SEQ_CST);
            if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0) {
                uint32_t wake = n < (uint32_t)INT_MAX ? n : INT_MAX;
                syscall(SYS_futex, &hdr->value, FUTEX_WAKE, wake, NULL, NULL, 0);
            }
            return;
        }
    }
}

/* Drain: acquire all available permits at once, return count acquired */
static inline uint32_t sync_sem_drain(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    uint32_t cur = __atomic_exchange_n(&hdr->value, 0, __ATOMIC_ACQUIRE);
    if (cur == 0) return 0;
    __atomic_add_fetch(&hdr->stat_acquires, 1, __ATOMIC_RELAXED);
    return cur;
}

static inline uint32_t sync_sem_value(SyncHandle *h) {
    return __atomic_load_n(&h->hdr->value, __ATOMIC_RELAXED);
}

/* ================================================================
 * Barrier operations
 *
 * param = number of parties
 * value = arrived count (0..param)
 * generation = bit 31: "broken" flag (set on timeout)
 *              bits 0..30: generation counter (bumped each trip/reset)
 *
 * Timeout breaks the barrier permanently; all waiters return -1 and all
 * future wait() calls also return -1 until sync_barrier_reset() is called.
 * This mirrors pthread_barrier "broken" semantics and avoids the race where
 * a timed-out waiter's reset raced with new-generation arrivals.
 * ================================================================ */

#define SYNC_BARRIER_BROKEN_BIT 0x80000000U
#define SYNC_BARRIER_GEN_MASK   0x7FFFFFFFU

static inline int sync_barrier_wait(SyncHandle *h, double timeout) {
    SyncHeader *hdr = h->hdr;
    uint32_t parties = hdr->param;

    if (timeout == 0) return -1;  /* non-blocking probe: can't rendezvous instantly */

    uint32_t gen_raw = __atomic_load_n(&hdr->generation, __ATOMIC_ACQUIRE);
    if (gen_raw & SYNC_BARRIER_BROKEN_BIT) return -1;  /* already broken */

    uint32_t arrived = __atomic_add_fetch(&hdr->value, 1, __ATOMIC_ACQ_REL);

    if (arrived == parties) {
        /* Last to arrive -- trip the barrier. CAS preserves broken bit invariant. */
        __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
        for (;;) {
            uint32_t old_g = __atomic_load_n(&hdr->generation, __ATOMIC_RELAXED);
            if (old_g & SYNC_BARRIER_BROKEN_BIT) {
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
                __atomic_thread_fence(__ATOMIC_SEQ_CST);
                if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->generation, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
                return -1;
            }
            uint32_t new_g = (old_g + 1) & SYNC_BARRIER_GEN_MASK;
            if (__atomic_compare_exchange_n(&hdr->generation, &old_g, new_g,
                    0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                break;
        }
        __atomic_add_fetch(&hdr->stat_releases, 1, __ATOMIC_RELAXED);
        /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
            syscall(SYS_futex, &hdr->generation, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
        return 1;  /* leader */
    }

    /* Not last -- wait for generation to change or broken bit to appear */
    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);

    for (;;) {
        uint32_t cur_raw = __atomic_load_n(&hdr->generation, __ATOMIC_ACQUIRE);
        if (cur_raw & SYNC_BARRIER_BROKEN_BIT) return -1;  /* broken */
        if (cur_raw != gen_raw) return 0;  /* barrier tripped */

        __atomic_add_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);

        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!sync_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);
                /* Try to break the barrier. If CAS fails with BROKEN_BIT
                 * clear, only gen changed -- our cohort tripped -> return 0.
                 * If CAS fails with BROKEN_BIT set, current state is
                 * broken (whether by us, another waiter, or trip+re-break)
                 * -> return -1, matching the non-timeout path. */
                uint32_t g = gen_raw;
                if (!__atomic_compare_exchange_n(&hdr->generation, &g,
                        gen_raw | SYNC_BARRIER_BROKEN_BIT,
                        0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)
                    && !(g & SYNC_BARRIER_BROKEN_BIT)) {
                    return 0;
                }
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                syscall(SYS_futex, &hdr->generation, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
                return -1;
            }
            pts = &remaining;
        }

        syscall(SYS_futex, &hdr->generation, FUTEX_WAIT, gen_raw, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);
    }
}

static inline uint32_t sync_barrier_generation(SyncHandle *h) {
    return __atomic_load_n(&h->hdr->generation, __ATOMIC_RELAXED) & SYNC_BARRIER_GEN_MASK;
}

static inline uint32_t sync_barrier_arrived(SyncHandle *h) {
    return __atomic_load_n(&h->hdr->value, __ATOMIC_RELAXED);
}

static inline int sync_barrier_is_broken(SyncHandle *h) {
    return (__atomic_load_n(&h->hdr->generation, __ATOMIC_RELAXED)
            & SYNC_BARRIER_BROKEN_BIT) != 0;
}

static inline void sync_barrier_reset(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
    /* Bump gen and clear broken bit in one CAS */
    for (;;) {
        uint32_t old_g = __atomic_load_n(&hdr->generation, __ATOMIC_RELAXED);
        uint32_t new_g = ((old_g & SYNC_BARRIER_GEN_MASK) + 1) & SYNC_BARRIER_GEN_MASK;
        if (__atomic_compare_exchange_n(&hdr->generation, &old_g, new_g,
                0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
            break;
    }
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->generation, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Condvar operations
 *
 * Uses the internal mutex (hdr->mutex) to protect the predicate.
 * value = signal counter (futex word)
 * generation = broadcast epoch
 * ================================================================ */

static inline void sync_condvar_lock(SyncHandle *h) {
    sync_mutex_lock(h->hdr);
    __atomic_add_fetch(&h->hdr->stat_acquires, 1, __ATOMIC_RELAXED);
}

static inline void sync_condvar_unlock(SyncHandle *h) {
    sync_mutex_unlock(h->hdr);
    __atomic_add_fetch(&h->hdr->stat_releases, 1, __ATOMIC_RELAXED);
}

static inline int sync_condvar_try_lock(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    uint32_t mypid = SYNC_MUTEX_VAL((uint32_t)getpid());
    uint32_t expected = 0;
    if (__atomic_compare_exchange_n(&hdr->mutex, &expected, mypid,
            0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
        __atomic_add_fetch(&hdr->stat_acquires, 1, __ATOMIC_RELAXED);
        return 1;
    }
    return 0;
}

/* Wait: atomically unlock mutex, wait on futex, re-lock mutex.
 * Returns 1 on signal/broadcast, 0 on timeout. */
static inline int sync_condvar_wait(SyncHandle *h, double timeout) {
    SyncHeader *hdr = h->hdr;

    if (timeout == 0) return 0;  /* non-blocking: no wait */

    uint32_t seq = __atomic_load_n(&hdr->value, __ATOMIC_ACQUIRE);

    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    sync_mutex_unlock(hdr);

    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);

    int signaled = 0;
    for (;;) {
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_ACQUIRE);
        if (cur != seq) { signaled = 1; break; }

        __atomic_add_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);

        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!sync_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                break;
            }
            pts = &remaining;
        }

        long rc = syscall(SYS_futex, &hdr->value, FUTEX_WAIT, seq, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);

        cur = __atomic_load_n(&hdr->value, __ATOMIC_ACQUIRE);
        if (cur != seq) { signaled = 1; break; }

        if (rc == -1 && errno == ETIMEDOUT && has_deadline) {
            __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
            break;
        }
    }

    sync_mutex_lock(hdr);
    __atomic_add_fetch(&hdr->stat_acquires, 1, __ATOMIC_RELAXED);
    return signaled;
}

static inline void sync_condvar_signal(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    __atomic_add_fetch(&hdr->value, 1, __ATOMIC_RELEASE);
    __atomic_add_fetch(&hdr->stat_signals, 1, __ATOMIC_RELAXED);
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, 1, NULL, NULL, 0);
}

static inline void sync_condvar_broadcast(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    __atomic_add_fetch(&hdr->value, 1, __ATOMIC_RELEASE);
    __atomic_add_fetch(&hdr->stat_signals, 1, __ATOMIC_RELAXED);
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Once operations
 *
 * value states: 0=INIT, (SYNC_MUTEX_WRITER_BIT|pid)=RUNNING, 1=DONE
 * ================================================================ */

#define SYNC_ONCE_INIT    0
#define SYNC_ONCE_DONE    1
/* RUNNING = SYNC_MUTEX_WRITER_BIT | pid */

static inline int sync_once_is_done(SyncHandle *h) {
    return __atomic_load_n(&h->hdr->value, __ATOMIC_ACQUIRE) == SYNC_ONCE_DONE;
}

/* Try to become the initializer. Returns:
 *   1 = you are the initializer, call once_done() when finished
 *   0 = already done
 *  -1 = another process is initializing (wait with once_wait) */
static inline int sync_once_try(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    uint32_t mypid = SYNC_MUTEX_VAL((uint32_t)getpid());

    uint32_t expected = SYNC_ONCE_INIT;
    if (__atomic_compare_exchange_n(&hdr->value, &expected, mypid,
            0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
        __atomic_add_fetch(&hdr->stat_acquires, 1, __ATOMIC_RELAXED);
        return 1;
    }
    if (expected == SYNC_ONCE_DONE) return 0;
    return -1;
}

/* Call/wait combo: try to become initializer, or wait for completion.
 * Returns 1 if caller is the initializer, 0 if already done or waited. */
static inline int sync_once_enter(SyncHandle *h, double timeout) {
    SyncHeader *hdr = h->hdr;

    /* Non-blocking probe: just try, don't wait */
    int r = sync_once_try(h);
    if (r == 1) return 1;
    if (r == 0) return 0;
    if (timeout == 0) return 0;

    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);

    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        r = sync_once_try(h);
        if (r == 1) return 1;   /* caller is initializer */
        if (r == 0) return 0;   /* already done */

        /* r == -1: someone else is running. Wait or detect stale. */
        uint32_t val = __atomic_load_n(&hdr->value, __ATOMIC_ACQUIRE);
        if (val == SYNC_ONCE_DONE) return 0;
        if (val == SYNC_ONCE_INIT) continue;  /* race: was reset, retry */

        /* Check stale initializer */
        if (val >= SYNC_MUTEX_WRITER_BIT) {
            uint32_t pid = val & SYNC_MUTEX_PID_MASK;
            if (!sync_pid_alive(pid)) {
                if (__atomic_compare_exchange_n(&hdr->value, &val, SYNC_ONCE_INIT,
                        0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
                    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
                    __atomic_thread_fence(__ATOMIC_SEQ_CST);
                    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
                        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
                }
                continue;
            }
        }

        __atomic_add_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);

        /* Always cap at SYNC_LOCK_TIMEOUT_SEC so stale-initializer recovery
         * runs periodically even when the caller specifies infinite timeout. */
        struct timespec *pts = (struct timespec *)&sync_lock_timeout;
        if (has_deadline) {
            if (!sync_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                return 0;
            }
            if (remaining.tv_sec < SYNC_LOCK_TIMEOUT_SEC)
                pts = &remaining;
        }

        syscall(SYS_futex, &hdr->value, FUTEX_WAIT, val, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);
    }
}

static inline void sync_once_done(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->value, SYNC_ONCE_DONE, __ATOMIC_RELEASE);
    __atomic_add_fetch(&hdr->stat_releases, 1, __ATOMIC_RELAXED);
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void sync_once_reset(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->value, SYNC_ONCE_INIT, __ATOMIC_RELEASE);
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Create / Open / Close
 *
 * Layout:
 *   [0..127]                          : SyncHeader
 *   [128 .. 128+SLOTS_SIZE-1]         : SyncReaderSlot[SYNC_READER_SLOTS]  (RWLock only)
 *   [128+SLOTS_SIZE .. +OCC_BYTES-1]  : occupancy bitmap, SYNC_OCC_WORDS words (RWLock only)
 *
 * Non-RWLock primitives keep total_size = sizeof(SyncHeader) (Option A:
 * pay-for-what-you-use, ~16KB only when needed).
 * ================================================================ */

#define SYNC_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, SYNC_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static inline uint64_t sync_layout_total_size(uint32_t type) {
    uint64_t sz = sizeof(SyncHeader);
    if (type == SYNC_TYPE_RWLOCK)
        sz += (uint64_t)SYNC_READER_SLOTS * sizeof(SyncReaderSlot) + SYNC_OCC_BYTES;
    return sz;
}

static inline uint64_t sync_layout_slots_off(uint32_t type) {
    return (type == SYNC_TYPE_RWLOCK) ? sizeof(SyncHeader) : 0;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at mode,
 * default 0600), or attach an existing file (O_RDWR|O_NOFOLLOW, no O_CREAT). */
static int sync_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { SYNC_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        SYNC_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    SYNC_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static SyncHandle *sync_create(const char *path, uint32_t type, uint32_t param,
                                uint32_t initial, mode_t mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    if (type > SYNC_TYPE_ONCE) { SYNC_ERR("unknown type %u", type); return NULL; }
    if (type == SYNC_TYPE_SEMAPHORE && param == 0) { SYNC_ERR("semaphore max must be > 0"); return NULL; }
    if (type == SYNC_TYPE_SEMAPHORE && initial > param) { SYNC_ERR("initial (%u) > max (%u)", initial, param); return NULL; }
    if (type == SYNC_TYPE_BARRIER && param < 2) { SYNC_ERR("barrier count must be >= 2"); return NULL; }

    uint64_t total_size = sync_layout_total_size(type);
    uint64_t slots_off  = sync_layout_slots_off(type);
    int anonymous = (path == NULL);
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE,
                     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) {
            SYNC_ERR("mmap(anonymous): %s", strerror(errno));
            return NULL;
        }
        SyncHeader *hdr = (SyncHeader *)base;
        memset(hdr, 0, sizeof(SyncHeader));
        hdr->magic            = SYNC_MAGIC;
        hdr->version          = SYNC_VERSION;
        hdr->type             = type;
        hdr->param            = param;
        hdr->total_size       = total_size;
        hdr->reader_slots_off = slots_off;
        if (type == SYNC_TYPE_SEMAPHORE)
            hdr->value = initial;
        /* MAP_ANONYMOUS already zero-fills the reader_slots + occ region. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        goto setup_handle;
    } else {
        int fd = sync_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;

        if (flock(fd, LOCK_EX) < 0) {
            SYNC_ERR("flock(%s): %s", path, strerror(errno));
            close(fd); return NULL;
        }

        struct stat st;
        if (fstat(fd, &st) < 0) {
            SYNC_ERR("fstat(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        int is_new = (st.st_size == 0);

        if (!is_new && (uint64_t)st.st_size < sizeof(SyncHeader)) {
            SYNC_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            SYNC_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new) {
            if (ftruncate(fd, (off_t)total_size) < 0) {
                SYNC_ERR("ftruncate(%s): %s", path, strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
        }

        map_size = is_new ? (size_t)total_size : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            SYNC_ERR("mmap(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        SyncHeader *hdr = (SyncHeader *)base;

        if (!is_new) {
            int valid = (hdr->magic == SYNC_MAGIC &&
                         hdr->version == SYNC_VERSION &&
                         hdr->type == type &&
                         hdr->total_size == (uint64_t)st.st_size);
            if (valid && type == SYNC_TYPE_RWLOCK) {
                /* reader_slots_off must point to a valid region, and the file must
                 * hold the slot table AND the occupancy bitmap that follows it. */
                uint64_t need = sizeof(SyncHeader) +
                                (uint64_t)SYNC_READER_SLOTS * sizeof(SyncReaderSlot) +
                                SYNC_OCC_BYTES;
                if (hdr->reader_slots_off != sizeof(SyncHeader) ||
                    (uint64_t)st.st_size < need)
                    valid = 0;
            }
            if (!valid) {
                SYNC_ERR("%s: invalid or incompatible sync file", path);
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN);
            close(fd);
            goto setup_handle;
        }

        /* Initialize while holding the flock */
        memset(base, 0, (size_t)total_size);  /* zero header + reader_slots + occ region */
        hdr->magic            = SYNC_MAGIC;
        hdr->version          = SYNC_VERSION;
        hdr->type             = type;
        hdr->param            = param;
        hdr->total_size       = total_size;
        hdr->reader_slots_off = slots_off;
        if (type == SYNC_TYPE_SEMAPHORE)
            hdr->value = initial;
        __atomic_thread_fence(__ATOMIC_SEQ_CST);

        flock(fd, LOCK_UN);
        close(fd);
    }  /* end file-backed */

setup_handle:;
    {
    SyncHeader *hdr = (SyncHeader *)base;
    SyncHandle *h = (SyncHandle *)calloc(1, sizeof(SyncHandle));
    if (!h) { munmap(base, map_size); return NULL; }

    h->hdr          = hdr;
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->notify_fd    = -1;
    h->backing_fd   = -1;
    /* Layer B: reader_slots_off is read from the (attacker-writable) mmap image
     * and used as a pointer offset; bound it against the mapping size so a
     * poisoned offset yields NULL instead of an out-of-bounds pointer. Valid
     * images use 0 (non-RWLock) or sizeof(SyncHeader) (RWLock), both in range. */
    {
    uint64_t rso = hdr->reader_slots_off;
    uint64_t need_slots = (uint64_t)SYNC_READER_SLOTS * sizeof(SyncReaderSlot);
    if (rso > 0 && rso <= (uint64_t)map_size &&
        (uint64_t)map_size - rso >= need_slots &&
        (rso & (uint64_t)(_Alignof(SyncReaderSlot) - 1)) == 0) {
        h->reader_slots = (SyncReaderSlot *)((char *)base + rso);
        /* Occupancy bitmap follows the slot table; bound it within the mapping
         * too.  On a poisoned or short map NULL BOTH -- occ is used only under an
         * `if (h->reader_slots)` guard, so the two must be non-NULL together. */
        uint64_t occ_off = rso + need_slots;
        if (occ_off <= (uint64_t)map_size &&
            (uint64_t)map_size - occ_off >= SYNC_OCC_BYTES) {
            h->occ = (uint64_t *)((char *)base + occ_off);
        } else {
            h->reader_slots = NULL;
            h->occ = NULL;
        }
    } else {
        h->reader_slots = NULL;
        h->occ = NULL;
    }
    }
    h->my_slot_idx  = UINT32_MAX;

    return h;
    }
}

static SyncHandle *sync_create_memfd(const char *name, uint32_t type,
                                      uint32_t param, uint32_t initial,
                                      char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    if (type > SYNC_TYPE_ONCE) { SYNC_ERR("unknown type %u", type); return NULL; }
    if (type == SYNC_TYPE_SEMAPHORE && param == 0) { SYNC_ERR("semaphore max must be > 0"); return NULL; }
    if (type == SYNC_TYPE_SEMAPHORE && initial > param) { SYNC_ERR("initial (%u) > max (%u)", initial, param); return NULL; }
    if (type == SYNC_TYPE_BARRIER && param < 2) { SYNC_ERR("barrier count must be >= 2"); return NULL; }

    uint64_t total_size = sync_layout_total_size(type);
    uint64_t slots_off  = sync_layout_slots_off(type);

    int fd = memfd_create(name ? name : "sync", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { SYNC_ERR("memfd_create: %s", strerror(errno)); return NULL; }

    if (ftruncate(fd, (off_t)total_size) < 0) {
        SYNC_ERR("ftruncate(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);

    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        SYNC_ERR("mmap(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }

    SyncHeader *hdr = (SyncHeader *)base;
    memset(hdr, 0, (size_t)total_size);  /* zero header + reader_slots + occ region */
    hdr->magic            = SYNC_MAGIC;
    hdr->version          = SYNC_VERSION;
    hdr->type             = type;
    hdr->param            = param;
    hdr->total_size       = total_size;
    hdr->reader_slots_off = slots_off;

    if (type == SYNC_TYPE_SEMAPHORE)
        hdr->value = initial;

    __atomic_thread_fence(__ATOMIC_SEQ_CST);

    SyncHandle *h = (SyncHandle *)calloc(1, sizeof(SyncHandle));
    if (!h) { munmap(base, (size_t)total_size); close(fd); return NULL; }

    h->hdr          = hdr;
    h->mmap_size    = (size_t)total_size;
    h->path         = NULL;
    h->notify_fd    = -1;
    h->backing_fd   = fd;
    if (slots_off > 0) {
        h->reader_slots = (SyncReaderSlot *)((char *)base + slots_off);
        /* Occupancy bitmap follows the slot table (total_size, and the sealed
         * memfd mapping, both cover it -- trusted create, so no bound check). */
        h->occ = (uint64_t *)((char *)base + slots_off +
                              (uint64_t)SYNC_READER_SLOTS * sizeof(SyncReaderSlot));
    } else {
        h->reader_slots = NULL;
        h->occ = NULL;
    }
    h->my_slot_idx  = UINT32_MAX;

    return h;
}

static SyncHandle *sync_open_fd(int fd, uint32_t type, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    struct stat st;
    if (fstat(fd, &st) < 0) {
        SYNC_ERR("fstat(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    if ((uint64_t)st.st_size < sizeof(SyncHeader)) {
        SYNC_ERR("fd %d: too small (%lld)", fd, (long long)st.st_size);
        return NULL;
    }

    size_t map_size = (size_t)st.st_size;
    void *base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        SYNC_ERR("mmap(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    SyncHeader *hdr = (SyncHeader *)base;
    int valid = (hdr->magic == SYNC_MAGIC &&
                 hdr->version == SYNC_VERSION &&
                 hdr->type == type &&
                 hdr->total_size == (uint64_t)st.st_size);
    if (valid && type == SYNC_TYPE_RWLOCK) {
        uint64_t need = sizeof(SyncHeader) +
                        (uint64_t)SYNC_READER_SLOTS * sizeof(SyncReaderSlot) +
                        SYNC_OCC_BYTES;
        if (hdr->reader_slots_off != sizeof(SyncHeader) ||
            (uint64_t)st.st_size < need)
            valid = 0;
    }
    if (!valid) {
        SYNC_ERR("fd %d: invalid or incompatible sync", fd);
        munmap(base, map_size);
        return NULL;
    }

    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) {
        SYNC_ERR("fcntl(F_DUPFD_CLOEXEC): %s", strerror(errno));
        munmap(base, map_size);
        return NULL;
    }

    SyncHandle *h = (SyncHandle *)calloc(1, sizeof(SyncHandle));
    if (!h) { munmap(base, map_size); close(myfd); return NULL; }

    h->hdr          = hdr;
    h->mmap_size    = map_size;
    h->path         = NULL;
    h->notify_fd    = -1;
    h->backing_fd   = myfd;
    /* Layer B: bound the mmap-supplied reader_slots_off against the mapping
     * size before using it as a pointer offset (see sync_create). */
    {
    uint64_t rso = hdr->reader_slots_off;
    uint64_t need_slots = (uint64_t)SYNC_READER_SLOTS * sizeof(SyncReaderSlot);
    if (rso > 0 && rso <= (uint64_t)map_size &&
        (uint64_t)map_size - rso >= need_slots &&
        (rso & (uint64_t)(_Alignof(SyncReaderSlot) - 1)) == 0) {
        h->reader_slots = (SyncReaderSlot *)((char *)base + rso);
        /* Occupancy bitmap follows the slot table; bound it within the mapping
         * too.  On a poisoned or short map NULL BOTH -- occ is used only under an
         * `if (h->reader_slots)` guard, so the two must be non-NULL together. */
        uint64_t occ_off = rso + need_slots;
        if (occ_off <= (uint64_t)map_size &&
            (uint64_t)map_size - occ_off >= SYNC_OCC_BYTES) {
            h->occ = (uint64_t *)((char *)base + occ_off);
        } else {
            h->reader_slots = NULL;
            h->occ = NULL;
        }
    } else {
        h->reader_slots = NULL;
        h->occ = NULL;
    }
    }
    h->my_slot_idx  = UINT32_MAX;

    return h;
}

static void sync_destroy(SyncHandle *h) {
    if (!h) return;
    /* Release reader slot -- only if we still own it AND no fork has happened
     * since we claimed it. A forked child that inherits the handle but never
     * acquired the lock itself must NOT clear the parent's slot. */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&sync_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* rdepth==0: a still-held read lock's slot must survive for recovery */
        /* Clear our occ bit BEFORE releasing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        sync_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        /* CAS pid -> 0; do NOT clear rdepth -- between the CAS and a follow-up
         * store, a new process could claim the slot, and our store would clobber
         * its state. sync_claim_reader_slot zeros rdepth on every claim, so
         * leaving a stale value is safe. */
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

/* ================================================================
 * Eventfd integration
 * ================================================================ */

static int sync_create_eventfd(SyncHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    int efd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd;
    return efd;
}

static int sync_notify(SyncHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t val = 1;
    return write(h->notify_fd, &val, sizeof(val)) == sizeof(val);
}

static int64_t sync_eventfd_consume(SyncHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t val = 0;
    if (read(h->notify_fd, &val, sizeof(val)) != sizeof(val)) return -1;
    return (int64_t)val;
}

/* ================================================================
 * Misc
 * ================================================================ */

static int sync_msync(SyncHandle *h) {
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

#endif /* SYNC_H */
