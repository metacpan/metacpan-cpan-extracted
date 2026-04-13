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

/* ================================================================
 * Constants
 * ================================================================ */

#define SYNC_MAGIC        0x53594E31U  /* "SYN1" */
#define SYNC_VERSION      1

/* Primitive type IDs */
#define SYNC_TYPE_SEMAPHORE  0
#define SYNC_TYPE_BARRIER    1
#define SYNC_TYPE_RWLOCK     2
#define SYNC_TYPE_CONDVAR    3
#define SYNC_TYPE_ONCE       4

#define SYNC_ERR_BUFLEN      256
#define SYNC_SPIN_LIMIT      32
#define SYNC_LOCK_TIMEOUT_SEC 2

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
    uint8_t  _pad0[40];      /* 24-63 */

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
    uint8_t  _pad1[4];       /* 124-127 */
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
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
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

static inline int sync_rwlock_try_rdlock(SyncHeader *hdr);
static inline int sync_rwlock_try_wrlock(SyncHeader *hdr);

static inline void sync_recover_stale_rwlock(SyncHeader *hdr, uint32_t observed) {
    if (!__atomic_compare_exchange_n(&hdr->value, &observed, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void sync_rwlock_rdlock(SyncHeader *hdr) {
    uint32_t *lock = &hdr->value;
    uint32_t *w = &hdr->waiters;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur < SYNC_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        __atomic_add_fetch(w, 1, __ATOMIC_RELAXED);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur >= SYNC_RWLOCK_WRITER_BIT) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &sync_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(w, 1, __ATOMIC_RELAXED);
                uint32_t val = __atomic_load_n(lock, __ATOMIC_RELAXED);
                if (val >= SYNC_RWLOCK_WRITER_BIT) {
                    uint32_t pid = val & SYNC_RWLOCK_PID_MASK;
                    if (!sync_pid_alive(pid))
                        sync_recover_stale_rwlock(hdr, val);
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(w, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

/* Timed rdlock: returns 1 on success, 0 on timeout. timeout<0 = infinite. */
static inline int sync_rwlock_rdlock_timed(SyncHeader *hdr, double timeout) {
    if (sync_rwlock_try_rdlock(hdr)) return 1;
    if (timeout == 0) return 0;

    uint32_t *lock = &hdr->value;
    uint32_t *w = &hdr->waiters;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);

    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur < SYNC_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return 1;
        }
        if (__builtin_expect(spin < SYNC_SPIN_LIMIT, 1)) {
            sync_spin_pause();
            continue;
        }
        __atomic_add_fetch(w, 1, __ATOMIC_RELAXED);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur >= SYNC_RWLOCK_WRITER_BIT) {
            struct timespec *pts = NULL;
            if (has_deadline) {
                if (!sync_remaining_time(&deadline, &remaining)) {
                    __atomic_sub_fetch(w, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &remaining;
            } else {
                pts = (struct timespec *)&sync_lock_timeout;
            }
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur, pts, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(w, 1, __ATOMIC_RELAXED);
                if (!has_deadline) {
                    uint32_t val = __atomic_load_n(lock, __ATOMIC_RELAXED);
                    if (val >= SYNC_RWLOCK_WRITER_BIT) {
                        uint32_t pid = val & SYNC_RWLOCK_PID_MASK;
                        if (!sync_pid_alive(pid))
                            sync_recover_stale_rwlock(hdr, val);
                    }
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(w, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline int sync_rwlock_try_rdlock(SyncHeader *hdr) {
    uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
    if (cur >= SYNC_RWLOCK_WRITER_BIT) return 0;
    return __atomic_compare_exchange_n(&hdr->value, &cur, cur + 1,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED);
}

static inline void sync_rwlock_rdunlock(SyncHeader *hdr) {
    uint32_t prev = __atomic_sub_fetch(&hdr->value, 1, __ATOMIC_RELEASE);
    if (prev == 0 && __atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void sync_rwlock_wrlock(SyncHeader *hdr) {
    uint32_t *lock = &hdr->value;
    uint32_t *w = &hdr->waiters;
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
        __atomic_add_fetch(w, 1, __ATOMIC_RELAXED);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &sync_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(w, 1, __ATOMIC_RELAXED);
                uint32_t val = __atomic_load_n(lock, __ATOMIC_RELAXED);
                if (val >= SYNC_RWLOCK_WRITER_BIT) {
                    uint32_t pid = val & SYNC_RWLOCK_PID_MASK;
                    if (!sync_pid_alive(pid))
                        sync_recover_stale_rwlock(hdr, val);
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(w, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

/* Timed wrlock: returns 1 on success, 0 on timeout. timeout<0 = infinite. */
static inline int sync_rwlock_wrlock_timed(SyncHeader *hdr, double timeout) {
    if (sync_rwlock_try_wrlock(hdr)) return 1;
    if (timeout == 0) return 0;

    uint32_t *lock = &hdr->value;
    uint32_t *w = &hdr->waiters;
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
        __atomic_add_fetch(w, 1, __ATOMIC_RELAXED);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            struct timespec *pts = NULL;
            if (has_deadline) {
                if (!sync_remaining_time(&deadline, &remaining)) {
                    __atomic_sub_fetch(w, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &remaining;
            } else {
                pts = (struct timespec *)&sync_lock_timeout;
            }
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur, pts, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(w, 1, __ATOMIC_RELAXED);
                if (!has_deadline) {
                    uint32_t val = __atomic_load_n(lock, __ATOMIC_RELAXED);
                    if (val >= SYNC_RWLOCK_WRITER_BIT) {
                        uint32_t pid = val & SYNC_RWLOCK_PID_MASK;
                        if (!sync_pid_alive(pid))
                            sync_recover_stale_rwlock(hdr, val);
                    }
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(w, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline int sync_rwlock_try_wrlock(SyncHeader *hdr) {
    uint32_t expected = 0;
    uint32_t mypid = SYNC_RWLOCK_WR((uint32_t)getpid());
    return __atomic_compare_exchange_n(&hdr->value, &expected, mypid,
                0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED);
}

static inline void sync_rwlock_wrunlock(SyncHeader *hdr) {
    __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* Downgrade: atomically convert wrlock to rdlock (writer -> 1 reader) */
static inline void sync_rwlock_downgrade(SyncHeader *hdr) {
    __atomic_store_n(&hdr->value, 1, __ATOMIC_RELEASE);
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
    for (;;) {
        uint32_t cur = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
        if (cur == 0) return 0;
        if (__atomic_compare_exchange_n(&hdr->value, &cur, 0,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_add_fetch(&hdr->stat_acquires, 1, __ATOMIC_RELAXED);
            return cur;
        }
    }
}

static inline uint32_t sync_sem_value(SyncHandle *h) {
    return __atomic_load_n(&h->hdr->value, __ATOMIC_RELAXED);
}

/* ================================================================
 * Barrier operations
 *
 * param = number of parties
 * value = arrived count (0..param)
 * generation = increments each time barrier trips
 * ================================================================ */

static inline int sync_barrier_wait(SyncHandle *h, double timeout) {
    SyncHeader *hdr = h->hdr;
    uint32_t parties = hdr->param;

    if (timeout == 0) return -1;  /* non-blocking probe: can't rendezvous instantly */

    uint32_t gen = __atomic_load_n(&hdr->generation, __ATOMIC_ACQUIRE);
    uint32_t arrived = __atomic_add_fetch(&hdr->value, 1, __ATOMIC_ACQ_REL);

    if (arrived == parties) {
        /* Last to arrive — trip the barrier */
        __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
        __atomic_add_fetch(&hdr->generation, 1, __ATOMIC_RELEASE);
        __atomic_add_fetch(&hdr->stat_releases, 1, __ATOMIC_RELAXED);
        /* Wake all waiters */
        if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
            syscall(SYS_futex, &hdr->generation, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
        return 1;  /* leader */
    }

    /* Not last — wait for generation to change */
    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) sync_make_deadline(timeout, &deadline);

    for (;;) {
        uint32_t cur_gen = __atomic_load_n(&hdr->generation, __ATOMIC_ACQUIRE);
        if (cur_gen != gen) return 0;  /* barrier tripped */

        __atomic_add_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);

        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!sync_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                /* Break the barrier — reset arrived before bumping
                 * generation so new arrivals see value=0. CAS on
                 * generation ensures only one process does the reset. */
                __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
                uint32_t cur_g = gen;
                if (__atomic_compare_exchange_n(&hdr->generation, &cur_g,
                        gen + 1, 0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                    syscall(SYS_futex, &hdr->generation, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
                }
                return -1;  /* timeout */
            }
            pts = &remaining;
        }

        syscall(SYS_futex, &hdr->generation, FUTEX_WAIT, gen, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);
    }
}

static inline uint32_t sync_barrier_generation(SyncHandle *h) {
    return __atomic_load_n(&h->hdr->generation, __ATOMIC_RELAXED);
}

static inline uint32_t sync_barrier_arrived(SyncHandle *h) {
    return __atomic_load_n(&h->hdr->value, __ATOMIC_RELAXED);
}

static inline void sync_barrier_reset(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->value, 0, __ATOMIC_RELEASE);
    __atomic_add_fetch(&hdr->generation, 1, __ATOMIC_RELEASE);
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
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, 1, NULL, NULL, 0);
}

static inline void sync_condvar_broadcast(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    __atomic_add_fetch(&hdr->value, 1, __ATOMIC_RELEASE);
    __atomic_add_fetch(&hdr->stat_signals, 1, __ATOMIC_RELAXED);
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
                    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
                        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
                }
                continue;
            }
        }

        __atomic_add_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);

        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!sync_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                return 0;
            }
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
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void sync_once_reset(SyncHandle *h) {
    SyncHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->value, SYNC_ONCE_INIT, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->value, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define SYNC_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, SYNC_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static SyncHandle *sync_create(const char *path, uint32_t type, uint32_t param,
                                uint32_t initial, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    if (type > SYNC_TYPE_ONCE) { SYNC_ERR("unknown type %u", type); return NULL; }
    if (type == SYNC_TYPE_SEMAPHORE && param == 0) { SYNC_ERR("semaphore max must be > 0"); return NULL; }
    if (type == SYNC_TYPE_SEMAPHORE && initial > param) { SYNC_ERR("initial (%u) > max (%u)", initial, param); return NULL; }
    if (type == SYNC_TYPE_BARRIER && param < 2) { SYNC_ERR("barrier count must be >= 2"); return NULL; }

    uint64_t total_size = sizeof(SyncHeader);
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
        hdr->magic      = SYNC_MAGIC;
        hdr->version    = SYNC_VERSION;
        hdr->type       = type;
        hdr->param      = param;
        hdr->total_size = total_size;
        if (type == SYNC_TYPE_SEMAPHORE)
            hdr->value = initial;
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        goto setup_handle;
    } else {
        int fd = open(path, O_RDWR | O_CREAT, 0666);
        if (fd < 0) { SYNC_ERR("open(%s): %s", path, strerror(errno)); return NULL; }

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
            if (!valid) {
                SYNC_ERR("%s: invalid or incompatible sync file", path);
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN);
            close(fd);
            goto setup_handle;
        }

        /* Initialize while holding the flock */
        memset(base, 0, sizeof(SyncHeader));
        hdr->magic      = SYNC_MAGIC;
        hdr->version    = SYNC_VERSION;
        hdr->type       = type;
        hdr->param      = param;
        hdr->total_size = total_size;
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

    h->hdr        = hdr;
    h->mmap_size  = map_size;
    h->path       = path ? strdup(path) : NULL;
    h->notify_fd  = -1;
    h->backing_fd = -1;

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

    uint64_t total_size = sizeof(SyncHeader);

    int fd = memfd_create(name ? name : "sync", MFD_CLOEXEC);
    if (fd < 0) { SYNC_ERR("memfd_create: %s", strerror(errno)); return NULL; }

    if (ftruncate(fd, (off_t)total_size) < 0) {
        SYNC_ERR("ftruncate(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }

    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        SYNC_ERR("mmap(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }

    SyncHeader *hdr = (SyncHeader *)base;
    memset(hdr, 0, sizeof(SyncHeader));
    hdr->magic      = SYNC_MAGIC;
    hdr->version    = SYNC_VERSION;
    hdr->type       = type;
    hdr->param      = param;
    hdr->total_size = total_size;

    if (type == SYNC_TYPE_SEMAPHORE)
        hdr->value = initial;

    __atomic_thread_fence(__ATOMIC_SEQ_CST);

    SyncHandle *h = (SyncHandle *)calloc(1, sizeof(SyncHandle));
    if (!h) { munmap(base, (size_t)total_size); close(fd); return NULL; }

    h->hdr        = hdr;
    h->mmap_size  = (size_t)total_size;
    h->path       = NULL;
    h->notify_fd  = -1;
    h->backing_fd = fd;

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

    h->hdr        = hdr;
    h->mmap_size  = map_size;
    h->path       = NULL;
    h->notify_fd  = -1;
    h->backing_fd = myfd;

    return h;
}

static void sync_destroy(SyncHandle *h) {
    if (!h) return;
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
    if (h->notify_fd >= 0) close(h->notify_fd);
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

static void sync_msync(SyncHandle *h) {
    msync(h->hdr, h->mmap_size, MS_SYNC);
}

#endif /* SYNC_H */
