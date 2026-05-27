/*
 * buf_generic.h — Macro-template for shared-memory typed buffers.
 *
 * Before including, define:
 *   BUF_PREFIX         — function prefix (e.g., buf_i64)
 *   BUF_ELEM_TYPE      — C element type (e.g., int64_t)
 *   BUF_VARIANT_ID     — unique integer for header validation
 *   BUF_ELEM_SIZE      — sizeof(BUF_ELEM_TYPE) or fixed string length
 *
 * Optional:
 *   BUF_HAS_COUNTERS   — generate incr/decr/cas (integer types only)
 *   BUF_IS_FLOAT       — element is float/double (affects SV conversion)
 *   BUF_IS_FIXEDSTR    — element is fixed-length char array
 */

/* ================================================================
 * Part 1: Shared definitions (included once)
 * ================================================================ */

#ifndef BUF_DEFS_H
#define BUF_DEFS_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <limits.h>
#include <signal.h>
#include <errno.h>
#include <linux/futex.h>
#include <sys/eventfd.h>
#include <pthread.h>

/* ---- Constants ---- */

#define BUF_MAGIC       0x42554631U  /* "BUF1" */
#define BUF_VERSION     2            /* v2: reader-slot table for dead-reader rwlock recovery */
#define BUF_ERR_BUFLEN  256
#define BUF_READER_SLOTS 1024         /* per-process reader-counter mirror */

/* ---- Per-process reader-slot table (in shared memory) ----
 * Mirrors each process's contribution to the global rwlock counters so a
 * dead reader's contribution can be reclaimed on writer-lock timeout. */
typedef struct {
    uint32_t pid;             /* owning PID, 0 = free */
    uint32_t subcount;        /* this process's rwlock reader contribution */
    uint32_t waiters_parked;  /* this process's contribution to rwlock_waiters */
    uint32_t writers_parked;  /* this process's contribution to rwlock_writers_waiting */
} BufReaderSlot;

/* ---- Shared memory header (128 bytes, 2 cache lines, in mmap) ---- */

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#define BUF_STATIC_ASSERT(cond, msg) _Static_assert(cond, msg)
#else
#define BUF_STATIC_ASSERT(cond, msg)
#endif

typedef struct {
    /* ---- Cache line 0 (0-63): immutable after create ---- */
    uint32_t magic;           /* 0 */
    uint32_t version;         /* 4 */
    uint32_t variant_id;      /* 8 */
    uint32_t elem_size;       /* 12 */
    uint64_t capacity;        /* 16: number of elements */
    uint64_t total_size;      /* 24: total mmap size */
    uint64_t data_off;        /* 32: offset to data array */
    uint64_t reader_slots_off;/* 40: offset to BufReaderSlot[BUF_READER_SLOTS] */
    uint8_t  _reserved0[16];  /* 48-63 */

    /* ---- Cache line 1 (64-127): seqlock + rwlock + mutable state ---- */
    uint32_t seq;             /* 64: seqlock counter, odd = writer active */
    uint32_t rwlock;          /* 68: 0=unlocked, readers=1..0x7FFFFFFF, writer=0x80000000|pid */
    uint32_t rwlock_waiters;  /* 72: wake-target counter (readers+writers) */
    uint32_t stat_recoveries; /* 76 */
    uint32_t rwlock_writers_waiting; /* 80: reader yield signal (writers only) */
    uint32_t _pad2;           /* 84 */
    uint64_t _reserved1[5];   /* 88-127 */
} BufHeader;

BUF_STATIC_ASSERT(sizeof(BufHeader) == 128, "BufHeader must be exactly 128 bytes (2 cache lines)");

/* ---- Process-local handle ---- */

typedef struct {
    BufHeader *hdr;
    void      *data;         /* pointer to element array in mmap */
    BufReaderSlot *reader_slots; /* in mmap, BUF_READER_SLOTS entries */
    size_t     mmap_size;
    char      *path;         /* backing file path (strdup'd, NULL for anon) */
    int        fd;           /* kept open for memfd, -1 otherwise */
    int        efd;          /* eventfd for notifications, -1 if none */
    uint32_t   my_slot_idx;  /* UINT32_MAX = unclaimed; per-process slot index */
    uint32_t   cached_pid;   /* getpid() at claim time */
    uint32_t   cached_fork_gen; /* fork-generation at claim time */
    uint8_t    wr_locked;    /* process-local: 1 if lock_wr is held */
    uint8_t    efd_owned;    /* 1 if we created the eventfd (close on destroy) */
} BufHandle;

/* ---- Futex-based read-write lock ---- */

#define BUF_RWLOCK_SPIN_LIMIT 32
#define BUF_LOCK_TIMEOUT_SEC  2

static inline void buf_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

#define BUF_RWLOCK_WRITER_BIT 0x80000000U
#define BUF_RWLOCK_PID_MASK   0x7FFFFFFFU
#define BUF_RWLOCK_WR(pid)    (BUF_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & BUF_RWLOCK_PID_MASK))

static inline int buf_pid_alive(uint32_t pid) {
    if (pid == 0) return 1;
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* ---- Per-process slot lifecycle (dead-reader recovery) ----
 * Each process claims one BufReaderSlot lazily on first lock op so that
 * its contribution to the shared rwlock counter can be reclaimed by other
 * processes if it dies (SIGKILL'd worker no longer pins the counter). */
static uint32_t buf_fork_gen = 0;
static pthread_once_t buf_atfork_once = PTHREAD_ONCE_INIT;
static void buf_on_fork_child(void) {
    __atomic_add_fetch(&buf_fork_gen, 1, __ATOMIC_RELAXED);
}
static void buf_atfork_init(void) {
    pthread_atfork(NULL, NULL, buf_on_fork_child);
}

static inline void buf_claim_reader_slot(BufHandle *h) {
    if (!h->reader_slots) return;
    pthread_once(&buf_atfork_once, buf_atfork_init);
    uint32_t cur_gen = __atomic_load_n(&buf_fork_gen, __ATOMIC_RELAXED);
    if (h->cached_fork_gen != cur_gen) {
        h->cached_fork_gen = cur_gen;
        h->my_slot_idx = UINT32_MAX;
    }
    if (h->my_slot_idx != UINT32_MAX) return;
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    uint32_t start = now_pid % BUF_READER_SLOTS;
    for (uint32_t i = 0; i < BUF_READER_SLOTS; i++) {
        uint32_t s = (start + i) % BUF_READER_SLOTS;
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
static inline void buf_atomic_sub_cap(uint32_t *p, uint32_t sub) {
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
static inline int buf_drain_dead_slot(BufHandle *h, uint32_t i, uint32_t pid) {
    BufHeader *hdr = h->hdr;
    uint32_t expected = pid;
    if (!__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return 0;
    uint32_t wp    = __atomic_load_n(&h->reader_slots[i].waiters_parked, __ATOMIC_RELAXED);
    uint32_t writp = __atomic_load_n(&h->reader_slots[i].writers_parked, __ATOMIC_RELAXED);
    int drained = 0;
    if (wp)    { buf_atomic_sub_cap(&hdr->rwlock_waiters, wp); drained = 1; }
    if (writp) { buf_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp); drained = 1; }
    /* Don't zero slot fields — buf_claim_reader_slot zeros them on the
     * next claim; zeroing here can race a new claimant's increments. */
    return drained;
}

static inline void buf_recover_dead_readers(BufHandle *h) {
    if (!h->reader_slots) return;
    BufHeader *hdr = h->hdr;
    int any_live_reader = 0;
    int found_dead_reader = 0;
    int any_recovery = 0;

    /* Pass 1: scan; classify; immediate-wipe dead slots with sc==0 (no
     * rwlock contribution to lose). Defer wiping dead-with-sc>0 slots
     * until force-reset can fire — otherwise we'd lose the only record
     * of the orphan rwlock contribution while a live reader is present. */
    for (uint32_t i = 0; i < BUF_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (buf_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        if (buf_drain_dead_slot(h, i, pid)) any_recovery = 1;
    }

    /* Pass 2: only if force-reset will fire.  Issue the rwlock CAS first
     * to keep the race window with new readers narrow, then wipe the
     * deferred dead slots. */
    if (found_dead_reader && !any_live_reader) {
        uint32_t cur = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
        if (cur > 0 && cur < BUF_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                any_recovery = 1;
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            }
        }
        for (uint32_t i = 0; i < BUF_READER_SLOTS; i++) {
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            if (pid == 0) continue;
            if (buf_pid_alive(pid)) continue;
            if (buf_drain_dead_slot(h, i, pid)) any_recovery = 1;
        }
    }
    if (any_recovery)
        __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
}

/* Park/unpark helpers — keep global rwlock_waiters/writers_waiting and
 * per-slot mirror counters in sync so recovery can drain them. */
static inline void buf_park_reader(BufHandle *h) {
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void buf_unpark_reader(BufHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void buf_park_writer(BufHandle *h) {
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}
static inline void buf_unpark_writer(BufHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void buf_recover_stale_lock(BufHeader *hdr, uint32_t observed_rwlock) {
    uint32_t mypid = BUF_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    uint32_t seq = __atomic_load_n(&hdr->seq, __ATOMIC_ACQUIRE);
    if (seq & 1)
        __atomic_store_n(&hdr->seq, seq + 1, __ATOMIC_RELEASE);
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec buf_lock_timeout = { BUF_LOCK_TIMEOUT_SEC, 0 };

/* Recovery dispatcher: if a writer is dead, force-reset the lock word;
 * otherwise scan reader slots for dead readers and drain their stuck
 * contributions to the rwlock and waiter counters.  Reload the lock
 * value here (rather than trusting a stale snapshot from the futex
 * caller) so that (a) a writer that died after our futex_wait started
 * is detected on the same timeout, and (b) phantom waiter/writers_waiting
 * contributions left by a dead parked writer are drained even when the
 * lock word itself is now 0. */
static inline void buf_recover_after_timeout(BufHandle *h) {
    BufHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= BUF_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & BUF_RWLOCK_PID_MASK;
        if (!buf_pid_alive(pid))
            buf_recover_stale_lock(hdr, val);
    } else {
        buf_recover_dead_readers(h);
    }
}

static inline void buf_rwlock_rdlock(BufHandle *h) {
    BufHeader *hdr = h->hdr;
    buf_claim_reader_slot(h);
    uint32_t *lock = &hdr->rwlock;
    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    /* Bump per-process subcount BEFORE attempting the rwlock CAS so a
     * concurrent recovery scan sees us as a live in-flight reader. */
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur > 0 && cur < BUF_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < BUF_RWLOCK_SPIN_LIMIT, 1)) {
            buf_spin_pause();
            continue;
        }
        buf_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur >= BUF_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &buf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                buf_unpark_reader(h);
                buf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        buf_unpark_reader(h);
        spin = 0;
    }
}

static inline void buf_rwlock_rdunlock(BufHandle *h) {
    /* Decrement rwlock BEFORE subcount: a concurrent recovery scan that
     * sees subcount > 0 with our (live) PID will (correctly) treat us as
     * an in-flight reader and skip force-reset. */
    uint32_t prev = __atomic_sub_fetch(&h->hdr->rwlock, 1, __ATOMIC_RELEASE);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    if (prev == 0 && __atomic_load_n(&h->hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &h->hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void buf_rwlock_wrlock(BufHandle *h) {
    BufHeader *hdr = h->hdr;
    buf_claim_reader_slot(h);
    uint32_t *lock = &hdr->rwlock;
    uint32_t mypid = BUF_RWLOCK_WR((uint32_t)getpid());
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < BUF_RWLOCK_SPIN_LIMIT, 1)) {
            buf_spin_pause();
            continue;
        }
        buf_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &buf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                buf_unpark_writer(h);
                buf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        buf_unpark_writer(h);
        spin = 0;
    }
}

static inline void buf_rwlock_wrunlock(BufHandle *h) {
    __atomic_store_n(&h->hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&h->hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &h->hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ---- Seqlock ---- */

static inline uint32_t buf_seqlock_read_begin(BufHeader *hdr) {
    int spin = 0;
    for (;;) {
        uint32_t s = __atomic_load_n(&hdr->seq, __ATOMIC_ACQUIRE);
        if (__builtin_expect((s & 1) == 0, 1)) return s;
        if (__builtin_expect(spin < 100000, 1)) {
            buf_spin_pause();
            spin++;
            continue;
        }
        uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
        if (val >= BUF_RWLOCK_WRITER_BIT) {
            uint32_t pid = val & BUF_RWLOCK_PID_MASK;
            if (!buf_pid_alive(pid)) {
                buf_recover_stale_lock(hdr, val);
                spin = 0;
                continue;
            }
        }
        struct timespec ts = {0, 1000000};
        nanosleep(&ts, NULL);
        spin = 0;
    }
}

static inline int buf_seqlock_read_retry(uint32_t *seq, uint32_t start) {
    return __atomic_load_n(seq, __ATOMIC_ACQUIRE) != start;
}

static inline void buf_seqlock_write_begin(uint32_t *seq) {
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);
}

static inline void buf_seqlock_write_end(uint32_t *seq) {
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);
}

/* ---- mmap create/open ---- */

static BufHandle *buf_create_map(const char *path, uint64_t capacity,
                                  uint32_t elem_size, uint32_t variant_id,
                                  char *errbuf) {
    errbuf[0] = '\0';
    int created = 0;
    int fd = open(path, O_RDWR | O_CREAT | O_EXCL, 0666);
    if (fd >= 0) {
        created = 1;
    } else if (errno == EEXIST) {
        fd = open(path, O_RDWR);
    }
    if (fd < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "open(%s): %s", path, strerror(errno));
        return NULL;
    }

    /* Lock file for init race prevention */
    if (flock(fd, LOCK_EX) < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "flock(%s): %s", path, strerror(errno));
        close(fd);
        return NULL;
    }

    uint64_t reader_slots_off = sizeof(BufHeader); /* 128 */
    uint64_t reader_slots_size = (uint64_t)BUF_READER_SLOTS * sizeof(BufReaderSlot);
    uint64_t data_off = reader_slots_off + reader_slots_size; /* cache-aligned */
    if (elem_size > 0 && capacity > (UINT64_MAX - data_off) / elem_size) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "buffer size overflow");
        flock(fd, LOCK_UN);
        close(fd);
        return NULL;
    }
    uint64_t total_size = data_off + capacity * elem_size;

    struct stat st;
    if (fstat(fd, &st) < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fstat(%s): %s", path, strerror(errno));
        flock(fd, LOCK_UN);
        close(fd);
        return NULL;
    }

    if (!created && st.st_size > 0 && (uint64_t)st.st_size < sizeof(BufHeader)) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "%s: file too small (%lld)", path, (long long)st.st_size);
        flock(fd, LOCK_UN); close(fd); return NULL;
    }
    if (created || st.st_size == 0) {
        if (ftruncate(fd, (off_t)total_size) < 0) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "ftruncate(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN);
            close(fd);
            return NULL;
        }
    }

    /* Re-stat after possible truncate */
    if (fstat(fd, &st) < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fstat(%s): %s", path, strerror(errno));
        flock(fd, LOCK_UN);
        close(fd);
        return NULL;
    }

    void *base = mmap(NULL, (size_t)st.st_size, PROT_READ | PROT_WRITE,
                       MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "mmap(%s): %s", path, strerror(errno));
        flock(fd, LOCK_UN);
        close(fd);
        return NULL;
    }

    BufHeader *hdr = (BufHeader *)base;

    if (created || hdr->magic == 0) {
        /* Initialize header */
        memset(hdr, 0, sizeof(BufHeader));
        hdr->magic = BUF_MAGIC;
        hdr->version = BUF_VERSION;
        hdr->variant_id = variant_id;
        hdr->elem_size = elem_size;
        hdr->capacity = capacity;
        hdr->total_size = (uint64_t)st.st_size;
        hdr->data_off = data_off;
        hdr->reader_slots_off = reader_slots_off;
        /* Zero reader_slots + data area */
        memset((char *)base + reader_slots_off, 0,
               (size_t)(reader_slots_size + capacity * elem_size));
        __atomic_thread_fence(__ATOMIC_RELEASE);
    } else {
        /* Validate existing header */
        if (hdr->magic != BUF_MAGIC) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: bad magic (0x%08x)", path, hdr->magic);
            goto fail;
        }
        if (hdr->version != BUF_VERSION) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: version mismatch (%u != %u)",
                     path, hdr->version, BUF_VERSION);
            goto fail;
        }
        if (hdr->variant_id != variant_id) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: variant mismatch (%u != %u)",
                     path, hdr->variant_id, variant_id);
            goto fail;
        }
        if (hdr->elem_size != elem_size) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: elem_size mismatch (%u != %u)",
                     path, hdr->elem_size, elem_size);
            goto fail;
        }
        if (hdr->elem_size == 0 ||
            hdr->reader_slots_off < sizeof(BufHeader) ||
            hdr->reader_slots_off + reader_slots_size > (uint64_t)st.st_size ||
            hdr->data_off < hdr->reader_slots_off + reader_slots_size ||
            hdr->data_off >= (uint64_t)st.st_size ||
            hdr->capacity > ((uint64_t)st.st_size - hdr->data_off) / hdr->elem_size) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: corrupt header (data doesn't fit in file)", path);
            goto fail;
        }
    }

    flock(fd, LOCK_UN);
    close(fd);

    BufHandle *h = (BufHandle *)calloc(1, sizeof(BufHandle));
    if (!h) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "calloc: out of memory");
        munmap(base, (size_t)st.st_size);
        return NULL;
    }
    h->hdr = hdr;
    h->data = (char *)base + hdr->data_off;
    h->reader_slots = (BufReaderSlot *)((char *)base + hdr->reader_slots_off);
    h->my_slot_idx = UINT32_MAX;
    h->mmap_size = (size_t)st.st_size;
    h->path = strdup(path);
    h->fd = -1;
    h->efd = -1;
    return h;

fail:
    munmap(base, (size_t)st.st_size);
    flock(fd, LOCK_UN);
    close(fd);
    return NULL;
}

/* ---- Anonymous mmap (no file, fork-only sharing) ---- */

static BufHandle *buf_create_anon(uint64_t capacity, uint32_t elem_size,
                                   uint32_t variant_id, char *errbuf) {
    errbuf[0] = '\0';
    uint64_t reader_slots_off = sizeof(BufHeader);
    uint64_t reader_slots_size = (uint64_t)BUF_READER_SLOTS * sizeof(BufReaderSlot);
    uint64_t data_off = reader_slots_off + reader_slots_size;
    if (elem_size > 0 && capacity > (UINT64_MAX - data_off) / elem_size) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "buffer size overflow");
        return NULL;
    }
    uint64_t total_size = data_off + capacity * elem_size;

    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE,
                       MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (base == MAP_FAILED) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "mmap(anon): %s", strerror(errno));
        return NULL;
    }

    BufHeader *hdr = (BufHeader *)base;
    memset(hdr, 0, sizeof(BufHeader));
    hdr->magic = BUF_MAGIC;
    hdr->version = BUF_VERSION;
    hdr->variant_id = variant_id;
    hdr->elem_size = elem_size;
    hdr->capacity = capacity;
    hdr->total_size = total_size;
    hdr->data_off = data_off;
    hdr->reader_slots_off = reader_slots_off;
    /* MAP_ANONYMOUS already zero-fills reader_slots and data. */

    BufHandle *h = (BufHandle *)calloc(1, sizeof(BufHandle));
    if (!h) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "calloc: out of memory");
        munmap(base, (size_t)total_size);
        return NULL;
    }
    h->hdr = hdr;
    h->data = (char *)base + data_off;
    h->reader_slots = (BufReaderSlot *)((char *)base + reader_slots_off);
    h->my_slot_idx = UINT32_MAX;
    h->mmap_size = (size_t)total_size;
    h->path = NULL;
    h->fd = -1;
    h->efd = -1;
    return h;
}

/* ---- memfd (named anonymous, shareable via fd passing) ---- */

static BufHandle *buf_create_memfd(const char *name, uint64_t capacity,
                                    uint32_t elem_size, uint32_t variant_id,
                                    char *errbuf) {
    errbuf[0] = '\0';
    uint64_t reader_slots_off = sizeof(BufHeader);
    uint64_t reader_slots_size = (uint64_t)BUF_READER_SLOTS * sizeof(BufReaderSlot);
    uint64_t data_off = reader_slots_off + reader_slots_size;
    if (elem_size > 0 && capacity > (UINT64_MAX - data_off) / elem_size) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "buffer size overflow");
        return NULL;
    }
    uint64_t total_size = data_off + capacity * elem_size;

    int fd = (int)syscall(SYS_memfd_create, name, MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "memfd_create: %s", strerror(errno));
        return NULL;
    }
    if (ftruncate(fd, (off_t)total_size) < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "ftruncate(memfd): %s", strerror(errno));
        close(fd);
        return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);

    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE,
                       MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "mmap(memfd): %s", strerror(errno));
        close(fd);
        return NULL;
    }

    BufHeader *hdr = (BufHeader *)base;
    memset(hdr, 0, sizeof(BufHeader));
    hdr->magic = BUF_MAGIC;
    hdr->version = BUF_VERSION;
    hdr->variant_id = variant_id;
    hdr->elem_size = elem_size;
    hdr->capacity = capacity;
    hdr->total_size = total_size;
    hdr->data_off = data_off;
    hdr->reader_slots_off = reader_slots_off;

    BufHandle *h = (BufHandle *)calloc(1, sizeof(BufHandle));
    if (!h) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "calloc: out of memory");
        munmap(base, (size_t)total_size);
        close(fd);
        return NULL;
    }
    h->hdr = hdr;
    h->data = (char *)base + data_off;
    h->reader_slots = (BufReaderSlot *)((char *)base + reader_slots_off);
    h->my_slot_idx = UINT32_MAX;
    h->mmap_size = (size_t)total_size;
    h->path = NULL;
    h->fd = fd;
    h->efd = -1;
    return h;
}

/* ---- Open from fd (received via SCM_RIGHTS or dup) ---- */

static BufHandle *buf_open_fd(int fd, uint32_t elem_size, uint32_t variant_id,
                               char *errbuf) {
    errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fstat(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }
    if ((uint64_t)st.st_size < sizeof(BufHeader)) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: file too small for header", fd);
        return NULL;
    }

    void *base = mmap(NULL, (size_t)st.st_size, PROT_READ | PROT_WRITE,
                       MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "mmap(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    BufHeader *hdr = (BufHeader *)base;
    if (hdr->magic != BUF_MAGIC) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: bad magic (0x%08x)", fd, hdr->magic);
        goto fail;
    }
    if (hdr->version != BUF_VERSION) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: version mismatch (%u != %u)",
                 fd, hdr->version, BUF_VERSION);
        goto fail;
    }
    if (hdr->variant_id != variant_id) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: variant mismatch (%u != %u)",
                 fd, hdr->variant_id, variant_id);
        goto fail;
    }
    if (hdr->elem_size != elem_size) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: elem_size mismatch (%u != %u)",
                 fd, hdr->elem_size, elem_size);
        goto fail;
    }
    uint64_t reader_slots_size = (uint64_t)BUF_READER_SLOTS * sizeof(BufReaderSlot);
    if (hdr->elem_size == 0 ||
        hdr->reader_slots_off < sizeof(BufHeader) ||
        hdr->reader_slots_off + reader_slots_size > (uint64_t)st.st_size ||
        hdr->data_off < hdr->reader_slots_off + reader_slots_size ||
        hdr->total_size != (uint64_t)st.st_size ||
        hdr->capacity > ((uint64_t)st.st_size - hdr->data_off) / hdr->elem_size) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: corrupt header", fd);
        goto fail;
    }

    {
        int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
        if (myfd < 0) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "fcntl(F_DUPFD_CLOEXEC, fd=%d): %s",
                     fd, strerror(errno));
            munmap(base, (size_t)st.st_size);
            return NULL;
        }
        BufHandle *h = (BufHandle *)calloc(1, sizeof(BufHandle));
        if (!h) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "calloc: out of memory");
            close(myfd);
            munmap(base, (size_t)st.st_size);
            return NULL;
        }
        h->hdr = hdr;
        h->data = (char *)base + hdr->data_off;
        h->reader_slots = (BufReaderSlot *)((char *)base + hdr->reader_slots_off);
        h->my_slot_idx = UINT32_MAX;
        h->mmap_size = (size_t)st.st_size;
        h->path = NULL;
        h->fd = myfd;
        h->efd = -1;
        return h;
    }

fail:
    munmap(base, (size_t)st.st_size);
    return NULL;
}

/* ---- msync ---- */

static inline int buf_msync(BufHandle *h) {
    if (!h || !h->hdr) return 0;
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

/* ---- Eventfd integration (opt-in notifications) ---- */

static int buf_create_eventfd(BufHandle *h) {
    if (h->efd >= 0) return h->efd;
    int efd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->efd = efd;
    h->efd_owned = 1;
    return efd;
}

static void buf_attach_eventfd(BufHandle *h, int efd) {
    if (h->efd >= 0 && h->efd_owned) close(h->efd);
    h->efd = efd;
    h->efd_owned = 0;
}

static int buf_notify(BufHandle *h) {
    if (h->efd < 0) return 0;
    uint64_t val = 1;
    return write(h->efd, &val, sizeof(val)) == sizeof(val);
}

static int64_t buf_wait_notify(BufHandle *h) {
    if (h->efd < 0) return -1;
    uint64_t val = 0;
    if (read(h->efd, &val, sizeof(val)) != sizeof(val)) return -1;
    return (int64_t)val;
}

static void buf_close_map(BufHandle *h) {
    if (!h) return;
    /* Release reader slot — only if we still own it AND no fork has happened
     * since we claimed it.  A forked child that inherits the handle but never
     * acquired the lock itself must NOT clear the parent's slot. */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&buf_fork_gen, __ATOMIC_RELAXED)) {
        uint32_t expected = h->cached_pid;
        /* CAS pid → 0; do NOT clear subcount/wp/writp — between the CAS and
         * a follow-up store, a new process could claim the slot, and our
         * store would clobber its state.  buf_claim_reader_slot zeros all
         * mirror fields on every claim, so leaving stale values is safe. */
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->efd >= 0 && h->efd_owned) close(h->efd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    if (h->fd >= 0) close(h->fd);
    if (h->path) free(h->path);
    free(h);
}

#endif /* BUF_DEFS_H */


/* ================================================================
 * Part 2: Per-variant functions (instantiated per include)
 * ================================================================ */

#ifndef BUF_PREFIX
#error "BUF_PREFIX must be defined before including buf_generic.h"
#endif

#define BUF_PASTE2(a, b) a##_##b
#define BUF_PASTE(a, b)  BUF_PASTE2(a, b)
#define BUF_FN(name)     BUF_PASTE(BUF_PREFIX, name)

/* ---- Create ---- */

#ifdef BUF_IS_FIXEDSTR
static BufHandle *BUF_FN(create)(const char *path, uint64_t capacity,
                                  uint32_t str_len, char *errbuf) {
    if (str_len == 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "str_len must be > 0");
        return NULL;
    }
    return buf_create_map(path, capacity, str_len, BUF_VARIANT_ID, errbuf);
}
#else
static BufHandle *BUF_FN(create)(const char *path, uint64_t capacity, char *errbuf) {
    return buf_create_map(path, capacity, BUF_ELEM_SIZE, BUF_VARIANT_ID, errbuf);
}
#endif

/* ---- Create anonymous ---- */

#ifdef BUF_IS_FIXEDSTR
static BufHandle *BUF_FN(create_anon)(uint64_t capacity, uint32_t str_len, char *errbuf) {
    if (str_len == 0) { snprintf(errbuf, BUF_ERR_BUFLEN, "str_len must be > 0"); return NULL; }
    return buf_create_anon(capacity, str_len, BUF_VARIANT_ID, errbuf);
}
static BufHandle *BUF_FN(create_memfd)(const char *name, uint64_t capacity, uint32_t str_len, char *errbuf) {
    if (str_len == 0) { snprintf(errbuf, BUF_ERR_BUFLEN, "str_len must be > 0"); return NULL; }
    return buf_create_memfd(name, capacity, str_len, BUF_VARIANT_ID, errbuf);
}
static BufHandle *BUF_FN(open_fd)(int fd, uint32_t str_len, char *errbuf) {
    if (str_len == 0) { snprintf(errbuf, BUF_ERR_BUFLEN, "str_len must be > 0"); return NULL; }
    return buf_open_fd(fd, str_len, BUF_VARIANT_ID, errbuf);
}
#else
static BufHandle *BUF_FN(create_anon)(uint64_t capacity, char *errbuf) {
    return buf_create_anon(capacity, BUF_ELEM_SIZE, BUF_VARIANT_ID, errbuf);
}
static BufHandle *BUF_FN(create_memfd)(const char *name, uint64_t capacity, char *errbuf) {
    return buf_create_memfd(name, capacity, BUF_ELEM_SIZE, BUF_VARIANT_ID, errbuf);
}
static BufHandle *BUF_FN(open_fd)(int fd, char *errbuf) {
    return buf_open_fd(fd, BUF_ELEM_SIZE, BUF_VARIANT_ID, errbuf);
}
#endif

/* ---- Raw byte access (for packed binary interop) ---- */

static int BUF_FN(get_raw)(BufHandle *h, uint64_t byte_off, uint64_t nbytes, void *out) {
    uint64_t data_size = h->hdr->capacity * (uint64_t)h->hdr->elem_size;
    if (nbytes > data_size || byte_off > data_size - nbytes) return 0;
    char *data = (char *)h->data;
    if (h->wr_locked) {
        memcpy(out, data + byte_off, (size_t)nbytes);
    } else {
        uint32_t seq_start;
        do {
            seq_start = buf_seqlock_read_begin(h->hdr);
            memcpy(out, data + byte_off, (size_t)nbytes);
        } while (buf_seqlock_read_retry(&h->hdr->seq, seq_start));
    }
    return 1;
}

static int BUF_FN(set_raw)(BufHandle *h, uint64_t byte_off, uint64_t nbytes, const void *in) {
    uint64_t data_size = h->hdr->capacity * (uint64_t)h->hdr->elem_size;
    if (nbytes > data_size || byte_off > data_size - nbytes) return 0;
    char *data = (char *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(h); buf_seqlock_write_begin(&h->hdr->seq); }
    memcpy(data + byte_off, in, (size_t)nbytes);
    if (!nested) { buf_seqlock_write_end(&h->hdr->seq); buf_rwlock_wrunlock(h); }
    return 1;
}

/* ---- Clear (zero entire buffer) ---- */

static void BUF_FN(clear)(BufHandle *h) {
    BufHeader *hdr = h->hdr;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(h); buf_seqlock_write_begin(&hdr->seq); }
    memset(h->data, 0, (size_t)(hdr->capacity * hdr->elem_size));
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(h); }
}

/* ---- Single-element atomic get (lock-free for numeric types) ---- */

#ifdef BUF_IS_FIXEDSTR

static int BUF_FN(get)(BufHandle *h, uint64_t idx, char *out, uint32_t *out_len) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = hdr->elem_size;
    if (idx >= hdr->capacity) return 0;
    char *data = (char *)h->data;
    if (h->wr_locked) {
        memcpy(out, data + idx * esz, esz);
    } else {
        uint32_t seq_start;
        do {
            seq_start = buf_seqlock_read_begin(hdr);
            memcpy(out, data + idx * esz, esz);
        } while (buf_seqlock_read_retry(&hdr->seq, seq_start));
    }
    uint32_t len = esz;
    while (len > 0 && out[len - 1] == '\0') len--;
    *out_len = len;
    return 1;
}

static int BUF_FN(set)(BufHandle *h, uint64_t idx, const char *val, uint32_t len) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = hdr->elem_size;
    if (idx >= hdr->capacity) return 0;
    char *data = (char *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(h); buf_seqlock_write_begin(&hdr->seq); }
    memset(data + idx * esz, 0, esz);
    uint32_t copy_len = len < esz ? len : esz;
    memcpy(data + idx * esz, val, copy_len);
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(h); }
    return 1;
}

#elif defined(BUF_IS_FLOAT)

/* Float/double: GCC __atomic builtins don't support FP types.
 * Use same-sized integer atomic load/store + memcpy for lock-free access. */

#if BUF_ELEM_SIZE == 4
typedef uint32_t BUF_PASTE(BUF_PREFIX, _uint_t);
#elif BUF_ELEM_SIZE == 8
typedef uint64_t BUF_PASTE(BUF_PREFIX, _uint_t);
#else
#error "BUF_IS_FLOAT requires BUF_ELEM_SIZE of 4 or 8"
#endif

static int BUF_FN(get)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE *out) {
    BufHeader *hdr = h->hdr;
    if (idx >= hdr->capacity) return 0;
    typedef BUF_PASTE(BUF_PREFIX, _uint_t) uint_t;
    uint_t *idata = (uint_t *)h->data;
    uint_t tmp = __atomic_load_n(&idata[idx], __ATOMIC_RELAXED);
    memcpy(out, &tmp, sizeof(BUF_ELEM_TYPE));
    return 1;
}

static int BUF_FN(set)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE val) {
    BufHeader *hdr = h->hdr;
    if (idx >= hdr->capacity) return 0;
    typedef BUF_PASTE(BUF_PREFIX, _uint_t) uint_t;
    uint_t *idata = (uint_t *)h->data;
    uint_t tmp;
    memcpy(&tmp, &val, sizeof(BUF_ELEM_TYPE));
    __atomic_store_n(&idata[idx], tmp, __ATOMIC_RELAXED);
    return 1;
}

#else /* integer types */

static int BUF_FN(get)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE *out) {
    BufHeader *hdr = h->hdr;
    if (idx >= hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    *out = __atomic_load_n(&data[idx], __ATOMIC_RELAXED);
    return 1;
}

static int BUF_FN(set)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE val) {
    BufHeader *hdr = h->hdr;
    if (idx >= hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    __atomic_store_n(&data[idx], val, __ATOMIC_RELAXED);
    return 1;
}

#endif /* BUF_IS_FIXEDSTR */

/* ---- Bulk operations (seqlock-guarded) ---- */

#ifdef BUF_IS_FIXEDSTR

static int BUF_FN(get_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              void *out) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = hdr->elem_size;
    if (count > hdr->capacity || from > hdr->capacity - count) return 0;
    char *data = (char *)h->data;
    if (h->wr_locked) {
        memcpy(out, data + from * esz, count * esz);
    } else {
        uint32_t seq_start;
        do {
            seq_start = buf_seqlock_read_begin(hdr);
            memcpy(out, data + from * esz, count * esz);
        } while (buf_seqlock_read_retry(&hdr->seq, seq_start));
    }
    return 1;
}

static int BUF_FN(set_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              const void *in) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = hdr->elem_size;
    if (count > hdr->capacity || from > hdr->capacity - count) return 0;
    char *data = (char *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(h); buf_seqlock_write_begin(&hdr->seq); }
    memcpy(data + from * esz, in, count * esz);
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(h); }
    return 1;
}

#else /* numeric */

static int BUF_FN(get_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              BUF_ELEM_TYPE *out) {
    BufHeader *hdr = h->hdr;
    if (count > hdr->capacity || from > hdr->capacity - count) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    if (h->wr_locked) {
        memcpy(out, &data[from], count * sizeof(BUF_ELEM_TYPE));
    } else {
        uint32_t seq_start;
        do {
            seq_start = buf_seqlock_read_begin(hdr);
            memcpy(out, &data[from], count * sizeof(BUF_ELEM_TYPE));
        } while (buf_seqlock_read_retry(&hdr->seq, seq_start));
    }
    return 1;
}

static int BUF_FN(set_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              const BUF_ELEM_TYPE *in) {
    BufHeader *hdr = h->hdr;
    if (count > hdr->capacity || from > hdr->capacity - count) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(h); buf_seqlock_write_begin(&hdr->seq); }
    memcpy(&data[from], in, count * sizeof(BUF_ELEM_TYPE));
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(h); }
    return 1;
}

#endif /* BUF_IS_FIXEDSTR */

/* ---- Fill ---- */

#ifdef BUF_IS_FIXEDSTR

static void BUF_FN(fill)(BufHandle *h, const char *val, uint32_t len) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = hdr->elem_size;
    char *data = (char *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(h); buf_seqlock_write_begin(&hdr->seq); }
    uint32_t copy_len = len < esz ? len : esz;
    memset(data, 0, (size_t)hdr->capacity * esz);
    for (uint64_t i = 0; i < hdr->capacity; i++)
        memcpy(data + i * esz, val, copy_len);
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(h); }
}

#else

static void BUF_FN(fill)(BufHandle *h, BUF_ELEM_TYPE val) {
    BufHeader *hdr = h->hdr;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(h); buf_seqlock_write_begin(&hdr->seq); }
    for (uint64_t i = 0; i < hdr->capacity; i++)
        data[i] = val;
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(h); }
}

#endif

/* ---- Atomic operations (integer types only) ---- */

#ifdef BUF_HAS_COUNTERS

static BUF_ELEM_TYPE BUF_FN(incr)(BufHandle *h, uint64_t idx) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_add_fetch(&data[idx], 1, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(decr)(BufHandle *h, uint64_t idx) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_sub_fetch(&data[idx], 1, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(add)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE delta) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_add_fetch(&data[idx], delta, __ATOMIC_RELAXED);
}

static int BUF_FN(cas)(BufHandle *h, uint64_t idx,
                        BUF_ELEM_TYPE expected, BUF_ELEM_TYPE desired) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_compare_exchange_n(&data[idx], &expected, desired,
                                        0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(cmpxchg)(BufHandle *h, uint64_t idx,
                                       BUF_ELEM_TYPE expected, BUF_ELEM_TYPE desired) {
    if (idx >= h->hdr->capacity) return expected;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    __atomic_compare_exchange_n(&data[idx], &expected, desired,
                                0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
    return expected; /* on failure, expected is updated to the current value */
}

static BUF_ELEM_TYPE BUF_FN(atomic_and)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE mask) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_and_fetch(&data[idx], mask, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(atomic_or)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE mask) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_or_fetch(&data[idx], mask, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(atomic_xor)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE mask) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_xor_fetch(&data[idx], mask, __ATOMIC_RELAXED);
}

static int BUF_FN(add_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              const BUF_ELEM_TYPE *deltas) {
    if (count > h->hdr->capacity || from > h->hdr->capacity - count) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    for (uint64_t i = 0; i < count; i++)
        __atomic_add_fetch(&data[from + i], deltas[i], __ATOMIC_RELAXED);
    return 1;
}

#endif /* BUF_HAS_COUNTERS */

/* ---- Diagnostics ---- */

static inline uint64_t BUF_FN(capacity)(BufHandle *h) {
    return h->hdr->capacity;
}

static inline uint64_t BUF_FN(mmap_size)(BufHandle *h) {
    return (uint64_t)h->mmap_size;
}

static inline uint32_t BUF_FN(elem_size)(BufHandle *h) {
    return h->hdr->elem_size;
}

/* ---- Raw pointer access (for passing to external C/XS code) ---- */

static inline void *BUF_FN(ptr)(BufHandle *h) {
    return h->data;
}

static inline void *BUF_FN(ptr_at)(BufHandle *h, uint64_t idx) {
    if (idx >= h->hdr->capacity) return NULL;
    return (char *)h->data + idx * h->hdr->elem_size;
}

/* ---- Explicit locking for batch operations ---- */

static inline void BUF_FN(lock_wr)(BufHandle *h) {
    buf_rwlock_wrlock(h);
    buf_seqlock_write_begin(&h->hdr->seq);
    h->wr_locked = 1;
}

static inline void BUF_FN(unlock_wr)(BufHandle *h) {
    h->wr_locked = 0;
    buf_seqlock_write_end(&h->hdr->seq);
    buf_rwlock_wrunlock(h);
}

static inline void BUF_FN(lock_rd)(BufHandle *h) {
    buf_rwlock_rdlock(h);
}

static inline void BUF_FN(unlock_rd)(BufHandle *h) {
    buf_rwlock_rdunlock(h);
}

/* ---- Cleanup ---- */

#undef BUF_PASTE2
#undef BUF_PASTE
#undef BUF_FN
#undef BUF_PREFIX
#undef BUF_ELEM_TYPE
#undef BUF_ELEM_SIZE
#undef BUF_VARIANT_ID
#ifdef BUF_HAS_COUNTERS
#undef BUF_HAS_COUNTERS
#endif
#ifdef BUF_IS_FLOAT
#undef BUF_IS_FLOAT
#endif
#ifdef BUF_IS_FIXEDSTR
#undef BUF_IS_FIXEDSTR
#endif
