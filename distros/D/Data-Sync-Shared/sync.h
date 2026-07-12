/*
 * sync.h -- Shared-memory synchronization primitives for Linux
 *
 * Five primitives:
 *   Semaphore — bounded counter (CAS-based, cross-process resource limiting)
 *   Barrier   — N processes rendezvous at a point before proceeding
 *   RWLock    — reader-writer lock for external resources
 *   Condvar   — condition variable with futex wait/signal/broadcast
 *   Once      — one-time initialization gate (like pthread_once)
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
#define SYNC_VERSION      2  /* v2: per-process reader-slot table for RWLock dead-reader recovery */

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

/* ================================================================
 * Per-process reader-slot table (for RWLock dead-reader recovery)
 *
 * Allocated only when type == SYNC_TYPE_RWLOCK (Option A).
 * Mirrors each process's contribution to the global rwlock counters so a
 * SIGKILL'd reader's stuck reader-count contribution can be reclaimed.
 * ~16KB per RWLock (1024 slots * 16 bytes); zero overhead for other types.
 * ================================================================ */

typedef struct {
    uint32_t pid;             /* owning PID, 0 = free */
    uint32_t subcount;        /* this process's rwlock reader contribution */
    uint32_t waiters_parked;  /* this process's contribution to hdr->waiters */
    uint32_t writers_parked;  /* this process's contribution to rwlock_writers_waiting */
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
    uint32_t slotless_readers;/* 32: RWLock live readers holding the lock with NO reader-slot
                                     (claimed when the slot table was full). Keeps dead-reader
                                     recovery from force-resetting the lock word out from under
                                     them. Defaults to 0, so images from before this field (was padding) stay compatible. */
    uint8_t  _pad0[28];      /* 36-63 */

    /* ---- Cache line 1 (64-127): mutable state ---- */

    /* Semaphore: value = current count, waiters = blocked acquirers */
    /* Barrier: value = arrived count, waiters = blocked at barrier,
                generation = increments each time barrier trips */
    /* RWLock: value = rwlock word (0=free, N=N readers, 0x80000000|pid=writer),
               waiters = blocked lockers */
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
    uint32_t rwlock_writers_waiting; /* 124: RWLock write-preferring yield signal
                                             (writers only, not readers) */
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

static inline int sync_pid_alive(uint32_t pid) {
    if (pid == 0) return 1;
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Convert timeout in seconds (double) to absolute deadline */
static inline void sync_make_deadline(double timeout, struct timespec *deadline) {
    clock_gettime(CLOCK_MONOTONIC, deadline);
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
 * RWLock helpers (for SYNC_TYPE_RWLOCK)
 *
 * value == 0:                  unlocked
 * value  1..0x7FFFFFFF:        N active readers
 * value  0x80000000 | pid:     write-locked by pid
 * ================================================================ */

#define SYNC_RWLOCK_WRITER_BIT 0x80000000U
#define SYNC_RWLOCK_PID_MASK   0x7FFFFFFFU
#define SYNC_RWLOCK_WR(pid)    (SYNC_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & SYNC_RWLOCK_PID_MASK))

static inline int sync_rwlock_try_rdlock(SyncHandle *h);
static inline int sync_rwlock_try_wrlock(SyncHandle *h);

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
 * Each process claims one SyncReaderSlot lazily on first rwlock op so that
 * its contribution to the shared reader-count can be reclaimed by other
 * processes if it dies (SIGKILL'd reader no longer pins the counter).
 * Only relevant for SYNC_TYPE_RWLOCK; non-RWLock primitives leave
 * h->reader_slots == NULL and these helpers become no-ops. */
static uint32_t sync_fork_gen = 0;
static pthread_once_t sync_atfork_once = PTHREAD_ONCE_INIT;
static void sync_on_fork_child(void) {
    __atomic_add_fetch(&sync_fork_gen, 1, __ATOMIC_RELAXED);
}
static void sync_atfork_init(void) {
    pthread_atfork(NULL, NULL, sync_on_fork_child);
}

static inline void sync_claim_reader_slot(SyncHandle *h) {
    if (!h->reader_slots) return;
    pthread_once(&sync_atfork_once, sync_atfork_init);
    uint32_t cur_gen = __atomic_load_n(&sync_fork_gen, __ATOMIC_RELAXED);
    if (h->cached_fork_gen != cur_gen) {
        if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
        h->cached_fork_gen = cur_gen;
        h->my_slot_idx = UINT32_MAX;
    }
    if (h->my_slot_idx != UINT32_MAX) return;
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    uint32_t start = now_pid % SYNC_READER_SLOTS;
    for (uint32_t i = 0; i < SYNC_READER_SLOTS; i++) {
        uint32_t s = (start + i) % SYNC_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[s].subcount, 0, __ATOMIC_RELAXED);
            __atomic_store_n(&h->reader_slots[s].waiters_parked, 0, __ATOMIC_RELAXED);
            __atomic_store_n(&h->reader_slots[s].writers_parked, 0, __ATOMIC_RELAXED);
            h->my_slot_idx = s;
            return;
        }
    }
    /* Slot table full — silently skip tracking; recovery falls back to
     * the slow per-op timeout drain. */
}

/* Atomically subtract `sub` from a counter, capped at 0 (never underflows). */
static inline void sync_atomic_sub_cap(uint32_t *p, uint32_t sub) {
    if (!sub) return;
    uint32_t cur = __atomic_load_n(p, __ATOMIC_RELAXED);
    for (;;) {
        uint32_t want = (cur > sub) ? cur - sub : 0;
        if (__atomic_compare_exchange_n(p, &cur, want,
                1, __ATOMIC_RELAXED, __ATOMIC_RELAXED))
            return;
    }
}

/* Try to claim a dead slot (CAS pid → 0) and drain its parked-waiter
 * contributions to the global counters. Returns 1 if drained, 0 if lost
 * the CAS race or had no contributions. ACQ_REL syncs us with the dead
 * process's RELAXED stores to mirror fields on weakly-ordered archs. */
static inline int sync_drain_dead_slot(SyncHandle *h, uint32_t i, uint32_t pid) {
    SyncHeader *hdr = h->hdr;
    uint32_t expected = pid;
    if (!__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return 0;
    uint32_t wp    = __atomic_load_n(&h->reader_slots[i].waiters_parked, __ATOMIC_RELAXED);
    uint32_t writp = __atomic_load_n(&h->reader_slots[i].writers_parked, __ATOMIC_RELAXED);
    int drained = 0;
    if (wp)    { sync_atomic_sub_cap(&hdr->waiters, wp); drained = 1; }
    if (writp) { sync_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp); drained = 1; }
    /* Don't zero slot fields — sync_claim_reader_slot zeros them on the
     * next claim; zeroing here can race a new claimant's increments. */
    return drained;
}

static inline void sync_recover_dead_readers(SyncHandle *h) {
    if (!h->reader_slots) return;
    SyncHeader *hdr = h->hdr;
    int any_live_reader = 0;
    int found_dead_reader = 0;
    int any_recovery = 0;

    /* Pass 1: scan; classify; immediate-wipe dead slots with sc==0 (no
     * rwlock contribution to lose). Defer wiping dead-with-sc>0 slots
     * until force-reset can fire — otherwise we'd lose the only record
     * of the orphan rwlock contribution while a live reader is present. */
    for (uint32_t i = 0; i < SYNC_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (sync_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        if (sync_drain_dead_slot(h, i, pid)) any_recovery = 1;
    }

    /* A live reader that could not claim a slot (table was full) is invisible
     * to the scan above, yet still holds a +1 in the lock word. Treat any
     * such slotless reader as a live reader so force-reset never zeroes the
     * lock out from under it (which would let a writer in -> writer-exclusion
     * violation). It is mirrored in hdr->slotless_readers exactly as slotted
     * readers are mirrored via their slot subcount. */
    if (__atomic_load_n(&hdr->slotless_readers, __ATOMIC_RELAXED) > 0)
        any_live_reader = 1;

    /* Pass 2: only if force-reset will fire.  Issue the rwlock CAS first
     * to keep the race window with new readers narrow, then wipe the
     * deferred dead slots. */
    if (found_dead_reader && !any_live_reader) {
        /* ACQUIRE: a late reader's subcount++ (before its value CAS) is then visible below. */
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_ACQUIRE);
        int drain_ok = 1;   /* keep dead slots if the reset doesn't fire */
        if (cur > 0 && cur < SYNC_RWLOCK_WRITER_BIT) {
            /* Re-scan for a live reader (fail-safe: only suppresses a reset). */
            int live_now = __atomic_load_n(&hdr->slotless_readers, __ATOMIC_RELAXED) > 0;
            for (uint32_t i = 0; !live_now && i < SYNC_READER_SLOTS; i++) {
                uint32_t p = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (p && sync_pid_alive(p) &&
                    __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED) > 0)
                    live_now = 1;
            }
            if (live_now) {
                drain_ok = 0;
            } else if (__atomic_compare_exchange_n(&hdr->value, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                any_recovery = 1;
                /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
                __atomic_thread_fence(__ATOMIC_SEQ_CST);
                if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            } else {
                drain_ok = 0;   /* value changed under us -- shares may still be live */
            }
        }
        if (drain_ok) {
            for (uint32_t i = 0; i < SYNC_READER_SLOTS; i++) {
                uint32_t p = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (p == 0 || sync_pid_alive(p)) continue;
                if (sync_drain_dead_slot(h, i, p)) any_recovery = 1;
            }
        }
    }
    if (any_recovery)
        __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
}

/* Park/unpark helpers — keep global hdr->waiters/rwlock_writers_waiting
 * and per-slot mirror counters in sync so recovery can drain them. */
static inline void sync_park_reader(SyncHandle *h) {
    __atomic_add_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void sync_unpark_reader(SyncHandle *h) {
    __atomic_sub_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void sync_park_writer(SyncHandle *h) {
    __atomic_add_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}
static inline void sync_unpark_writer(SyncHandle *h) {
    __atomic_sub_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

/* Recovery dispatcher: if a writer is dead, force-reset the lock word;
 * otherwise scan reader slots for dead readers and drain their stuck
 * contributions to the rwlock and waiter counters.  Reload the lock
 * value here (rather than trusting a stale snapshot from the futex
 * caller) so that (a) a writer that died after our futex_wait started
 * is detected on the same timeout, and (b) phantom waiter/writers_waiting
 * contributions left by a dead parked writer are drained even when the
 * lock word itself is now 0. */
static inline void sync_recover_after_timeout(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
    if (val >= SYNC_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & SYNC_RWLOCK_PID_MASK;
        if (!sync_pid_alive(pid))
            sync_recover_stale_rwlock(hdr, val);
    } else {
        sync_recover_dead_readers(h);
    }
}

/* ---- Reader accounting (slot subcount, or global slotless count) ----
 * A reader mirrors its +1 in the lock word so dead-reader recovery can see
 * it. A slotted reader uses its reader-slot subcount; a reader that could not
 * claim a slot (table full) uses the global hdr->slotless_readers instead, so
 * recovery's force-reset never fires out from under it. enter() is called
 * BEFORE the lock CAS (in-flight visibility); abort() undoes it when the
 * acquire fails; leave() undoes it on unlock, peeling slotless first so a
 * later slot claim cannot misattribute the decrement. */
static inline void sync_reader_enter(SyncHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_readers, 1, __ATOMIC_RELAXED);
        h->slotless_held++;
    }
}
static inline void sync_reader_abort(SyncHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    } else {
        __atomic_sub_fetch(&h->hdr->slotless_readers, 1, __ATOMIC_RELAXED);
        h->slotless_held--;
    }
}
static inline void sync_reader_leave(SyncHandle *h) {
    if (h->slotless_held > 0) {
        h->slotless_held--;
        __atomic_sub_fetch(&h->hdr->slotless_readers, 1, __ATOMIC_RELAXED);
    } else if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    }
}

static inline void sync_rwlock_rdlock(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    sync_claim_reader_slot(h);
    uint32_t *lock = &hdr->value;
    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    /* Mirror our reader contribution BEFORE the rwlock CAS so a concurrent
     * recovery scan sees us as a live in-flight reader (slotted or slotless). */
    sync_reader_enter(h);
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Write-preferring: yield to parked writers when lock is free. */
        if (cur > 0 && cur < SYNC_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        sync_park_reader(h);
        /* StoreLoad: publish our parked-waiter registration before re-reading
         * the lock word (weak-memory lost-wakeup guard). */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR yielding to parked writers (cur==0) */
        if (cur >= SYNC_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &sync_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                sync_unpark_reader(h);
                if (cur >= SYNC_RWLOCK_WRITER_BIT) {
                    sync_recover_after_timeout(h);
                } else {
                    /* Yielding to writers timed out — optimistically drop one
                     * writers_waiting to recover from potentially-crashed
                     * parked writer. A live writer just re-increments. */
                    uint32_t wc = __atomic_load_n(writers_waiting, __ATOMIC_RELAXED);
                    while (wc > 0 && !__atomic_compare_exchange_n(
                            writers_waiting, &wc, wc - 1,
                            1, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {}
                    /* Also opportunistically reap dead-reader slot mirrors
                     * (some other reader holds the lock but may be dead). */
                    sync_recover_dead_readers(h);
                }
                spin = 0;
                continue;
            }
        }
        sync_unpark_reader(h);
        spin = 0;
    }
}

/* Timed rdlock: returns 1 on success, 0 on timeout. timeout<0 = infinite.
 * No try-lock fast-path: would bypass write-preference when cur==0 &&
 * writers_waiting > 0. Main loop's first iteration handles the uncontended
 * case at ~same cost.
 *
 * Uses the same slot-claim + park-reader pattern as the regular rdlock,
 * with user-timeout ETIMEDOUT short-circuiting to return 0 (after we drop
 * any claimed subcount). Per-iteration futex waits are capped at
 * SYNC_LOCK_TIMEOUT_SEC so the global recovery scan runs periodically. */
static inline int sync_rwlock_rdlock_timed(SyncHandle *h, double timeout) {
    if (timeout == 0) {
        return sync_rwlock_try_rdlock(h);
    }

    SyncHeader *hdr = h->hdr;
    sync_claim_reader_slot(h);
    uint32_t *lock = &hdr->value;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);

    /* Register as an in-flight reader (slotted subcount or slotless) BEFORE the
     * rwlock CAS so a concurrent recovery scan sees us as live. */
    sync_reader_enter(h);

    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur > 0 && cur < SYNC_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                return 1;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                return 1;
        }
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        sync_park_reader(h);
        /* StoreLoad: publish our parked-waiter registration before re-reading
         * the lock word (weak-memory lost-wakeup guard). */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur >= SYNC_RWLOCK_WRITER_BIT || cur == 0) {
            struct timespec *pts = NULL;
            int capped = 0;
            /* Cap wait at SYNC_LOCK_TIMEOUT_SEC so stale-holder recovery
             * runs periodically even with a user-supplied deadline. */
            if (has_deadline) {
                if (!sync_remaining_time(&deadline, &remaining)) {
                    sync_unpark_reader(h);
                    sync_reader_abort(h);
                    return 0;
                }
                if (remaining.tv_sec >= SYNC_LOCK_TIMEOUT_SEC) {
                    pts = (struct timespec *)&sync_lock_timeout;
                    capped = 1;
                } else {
                    pts = &remaining;
                }
            } else {
                pts = (struct timespec *)&sync_lock_timeout;
                capped = 1;
            }
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur, pts, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                sync_unpark_reader(h);
                /* If timeout matches the global lock-timeout cap (not the
                 * user's deadline), run the recovery scan; otherwise it's
                 * the user's deadline expiring and we should return 0. */
                if (!capped) {
                    sync_reader_abort(h);
                    return 0;
                }
                if (cur >= SYNC_RWLOCK_WRITER_BIT) {
                    sync_recover_after_timeout(h);
                } else {
                    /* Yielding to writer timed out — drop one writers_waiting
                     * to recover from a potentially-crashed parked writer. */
                    uint32_t wc = __atomic_load_n(writers_waiting, __ATOMIC_RELAXED);
                    while (wc > 0 && !__atomic_compare_exchange_n(
                            writers_waiting, &wc, wc - 1,
                            1, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {}
                    sync_recover_dead_readers(h);
                }
                spin = 0;
                continue;
            }
        }
        sync_unpark_reader(h);
        spin = 0;
    }
}

/* try_rdlock: bump subcount up-front so concurrent recovery scans see us
 * as live in-flight; revert on CAS failure. Cheap and keeps recovery
 * accounting consistent. */
static inline int sync_rwlock_try_rdlock(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    sync_claim_reader_slot(h);
    sync_reader_enter(h);
    uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
    if (cur >= SYNC_RWLOCK_WRITER_BIT) {
        sync_reader_abort(h);
        return 0;
    }
    if (__atomic_compare_exchange_n(&hdr->value, &cur, cur + 1,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return 1;
    sync_reader_abort(h);
    return 0;
}

static inline void sync_rwlock_rdunlock(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    /* Decrement rwlock BEFORE subcount: a concurrent recovery scan that
     * sees subcount > 0 with our (live) PID will (correctly) treat us as
     * an in-flight reader and skip force-reset. */
    uint32_t prev = __atomic_sub_fetch(&hdr->value, 1, __ATOMIC_RELEASE);
    sync_reader_leave(h);
    /* StoreLoad: publish the reader-count decrement before reading waiters
     * (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (prev == 0 && __atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void sync_rwlock_wrlock(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    sync_claim_reader_slot(h);
    uint32_t *lock = &hdr->value;
    uint32_t mypid = SYNC_RWLOCK_WR((uint32_t)getpid());
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        sync_park_writer(h);
        /* StoreLoad: see the rdlock park path (weak-memory lost-wakeup guard). */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &sync_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                sync_unpark_writer(h);
                sync_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        sync_unpark_writer(h);
        spin = 0;
    }
}

/* Timed wrlock: returns 1 on success, 0 on timeout. timeout<0 = infinite. */
static inline int sync_rwlock_wrlock_timed(SyncHandle *h, double timeout) {
    if (sync_rwlock_try_wrlock(h)) return 1;
    if (timeout == 0) return 0;

    SyncHeader *hdr = h->hdr;
    sync_claim_reader_slot(h);
    uint32_t *lock = &hdr->value;
    uint32_t mypid = SYNC_RWLOCK_WR((uint32_t)getpid());
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);

    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return 1;
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        sync_park_writer(h);
        /* StoreLoad: see the rdlock park path (weak-memory lost-wakeup guard). */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            struct timespec *pts = NULL;
            int capped = 0;
            /* Cap wait at SYNC_LOCK_TIMEOUT_SEC so stale-holder recovery
             * runs periodically even with a user-supplied deadline. */
            if (has_deadline) {
                if (!sync_remaining_time(&deadline, &remaining)) {
                    sync_unpark_writer(h);
                    return 0;
                }
                if (remaining.tv_sec >= SYNC_LOCK_TIMEOUT_SEC) {
                    pts = (struct timespec *)&sync_lock_timeout;
                    capped = 1;
                } else {
                    pts = &remaining;
                }
            } else {
                pts = (struct timespec *)&sync_lock_timeout;
                capped = 1;
            }
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur, pts, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                sync_unpark_writer(h);
                if (!capped) return 0;  /* user deadline expired */
                sync_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        sync_unpark_writer(h);
        spin = 0;
    }
}

static inline int sync_rwlock_try_wrlock(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    uint32_t expected = 0;
    uint32_t mypid = SYNC_RWLOCK_WR((uint32_t)getpid());
    return __atomic_compare_exchange_n(&hdr->value, &expected, mypid,
                0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED);
}

static inline void sync_rwlock_wrunlock(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* Downgrade: atomically convert wrlock to rdlock (writer -> 1 reader).
 * Also accounts the post-downgrade reader contribution on our slot so a
 * subsequent SIGKILL leaves a recoverable subcount, not an orphan. */
static inline void sync_rwlock_downgrade(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    sync_claim_reader_slot(h);
    sync_reader_enter(h);
    __atomic_store_n(&hdr->value, 1, __ATOMIC_RELEASE);
    /* StoreLoad: publish the state change before reading the waiter count (weak-memory lost-wakeup guard). */
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
        /* Last to arrive — trip the barrier. CAS preserves broken bit invariant. */
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

    /* Not last — wait for generation to change or broken bit to appear */
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
                 * clear, only gen changed — our cohort tripped → return 0.
                 * If CAS fails with BROKEN_BIT set, current state is
                 * broken (whether by us, another waiter, or trip+re-break)
                 * → return -1, matching the non-timeout path. */
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
 *   [0..127]                : SyncHeader
 *   [128..128+SLOTS_SIZE-1] : SyncReaderSlot[SYNC_READER_SLOTS]  (RWLock only)
 *
 * Non-RWLock primitives keep total_size = sizeof(SyncHeader) (Option A:
 * pay-for-what-you-use, ~16KB only when needed).
 * ================================================================ */

#define SYNC_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, SYNC_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static inline uint64_t sync_layout_total_size(uint32_t type) {
    uint64_t sz = sizeof(SyncHeader);
    if (type == SYNC_TYPE_RWLOCK)
        sz += (uint64_t)SYNC_READER_SLOTS * sizeof(SyncReaderSlot);
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
        /* MAP_ANONYMOUS already zero-fills reader_slots region. */
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
                /* reader_slots_off must point to a valid region inside the file. */
                uint64_t need = sizeof(SyncHeader) +
                                (uint64_t)SYNC_READER_SLOTS * sizeof(SyncReaderSlot);
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
        memset(base, 0, (size_t)total_size);  /* zero header + reader_slots region */
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
    h->reader_slots = (rso > 0 && rso <= (uint64_t)map_size &&
                       (uint64_t)map_size - rso >= need_slots &&
                       (rso & (uint64_t)(_Alignof(SyncReaderSlot) - 1)) == 0)
        ? (SyncReaderSlot *)((char *)base + rso)
        : NULL;
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
    memset(hdr, 0, (size_t)total_size);  /* zero header + reader_slots region */
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
    h->reader_slots = (slots_off > 0)
        ? (SyncReaderSlot *)((char *)base + slots_off)
        : NULL;
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
                        (uint64_t)SYNC_READER_SLOTS * sizeof(SyncReaderSlot);
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
    h->reader_slots = (rso > 0 && rso <= (uint64_t)map_size &&
                       (uint64_t)map_size - rso >= need_slots &&
                       (rso & (uint64_t)(_Alignof(SyncReaderSlot) - 1)) == 0)
        ? (SyncReaderSlot *)((char *)base + rso)
        : NULL;
    }
    h->my_slot_idx  = UINT32_MAX;

    return h;
}

static void sync_destroy(SyncHandle *h) {
    if (!h) return;
    /* Release reader slot — only if we still own it AND no fork has happened
     * since we claimed it. A forked child that inherits the handle but never
     * acquired the lock itself must NOT clear the parent's slot. */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&sync_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].subcount, __ATOMIC_ACQUIRE) == 0) {
        /* subcount==0: a still-held lock's slot must survive for recovery */
        uint32_t expected = h->cached_pid;
        /* CAS pid -> 0; do NOT clear subcount/wp/writp — between the CAS and
         * a follow-up store, a new process could claim the slot, and our
         * store would clobber its state. sync_claim_reader_slot zeros all
         * mirror fields on every claim, so leaving stale values is safe. */
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
