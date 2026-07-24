/*
 * buf_generic.h -- Macro-template for shared-memory typed buffers.
 *
 * Before including, define:
 *   BUF_PREFIX         -- function prefix (e.g., buf_i64)
 *   BUF_ELEM_TYPE      -- C element type (e.g., int64_t)
 *   BUF_VARIANT_ID     -- unique integer for header validation
 *   BUF_ELEM_SIZE      -- sizeof(BUF_ELEM_TYPE) or fixed string length
 *
 * Optional:
 *   BUF_HAS_COUNTERS   -- generate incr/decr/cas (integer types only)
 *   BUF_IS_FLOAT       -- element is float/double (affects SV conversion)
 *   BUF_IS_FIXEDSTR    -- element is fixed-length char array
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
#define BUF_VERSION     3            /* v3: added occupancy bitmap region (layout change) */
#define BUF_ERR_BUFLEN  256
#define BUF_READER_SLOTS 1024         /* per-process reader-counter mirror */

/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these BUF_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all BUF_READER_SLOTS. */
#define BUF_OCC_WORDS   (((BUF_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define BUF_OCC_BYTES   ((uint64_t)BUF_OCC_WORDS * 8)      /* 128 bytes */

/* ---- Per-process reader-slot table (in shared memory) ----
 * In the reader-slots-only rwlock a reader's ENTIRE contribution to the shared
 * lock is `rdepth` in its OWN slot -- there is no separate shared reader counter
 * to fall out of sync with it -- so a dead reader's contribution is exactly this
 * one word, which a draining writer neutralises by clearing the slot's pid (the
 * scan then ignores the slot).  No orphaned counter can exist, so there is no
 * quiescent force-reset and sustained readers cannot starve a writer.
 * _rsv1/_rsv2 are kept only to preserve the 16-byte slot size across the
 * already-released builds. */
typedef struct {
    uint32_t pid;      /* owning PID, 0 = free */
    uint32_t rdepth;   /* read-locks THIS process currently holds (recursion-safe) */
    uint32_t _rsv1;    /* reserved (was waiters_parked); unused, kept for layout size */
    uint32_t _rsv2;    /* reserved (was writers_parked); unused, kept for layout size */
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
    uint32_t wlock;           /* 68: WRITER word ONLY: 0 (free) or 0x80000000|pid.  NOT a reader count. */
    uint32_t rwait;           /* 72: parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t stat_recoveries; /* 76 */
    uint32_t drain_seq;       /* 80: futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth; /* 84: readers holding with no reader-slot (documented residual) */
    uint64_t _reserved1[5];   /* 88-127 */
} BufHeader;

BUF_STATIC_ASSERT(sizeof(BufHeader) == 128, "BufHeader must be exactly 128 bytes (2 cache lines)");

/* ---- Process-local handle ---- */

typedef struct {
    BufHeader *hdr;
    void      *data;         /* pointer to element array in mmap */
    BufReaderSlot *reader_slots; /* in mmap, BUF_READER_SLOTS entries */
    uint64_t      *occ;          /* BUF_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    uint64_t   capacity;     /* cached at attach: immutable geometry (peer can't grow it live) */
    uint32_t   elem_size;    /* cached at attach: immutable geometry */
    size_t     mmap_size;
    char      *path;         /* backing file path (strdup'd, NULL for anon) */
    int        fd;           /* kept open for memfd, -1 otherwise */
    int        efd;          /* eventfd for notifications, -1 if none */
    uint32_t   my_slot_idx;  /* UINT32_MAX = unclaimed; per-process slot index */
    uint32_t   cached_pid;   /* getpid() at claim time */
    uint32_t   cached_fork_gen; /* fork-generation at claim time */
    uint8_t    wr_locked;    /* process-local: 1 if lock_wr is held */
    uint32_t   rd_held;      /* read locks THIS handle holds (rdepth is per-process,
                              * shared by every handle, so it cannot be used to tell
                              * how much of it belongs to this handle at close time) */
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

/* Futex-based write-preferring read-write lock (reader-slots-only) with
 * dead-process recovery.  The reader count is NOT stored in a shared counter; it
 * is DISTRIBUTED across per-process reader slots: each slot's `rdepth` is that
 * process's entire contribution.  A reader publishes its presence in its own slot
 * then re-checks the writer word; a writer publishes the writer word then scans
 * every slot until all live readers' rdepth reach 0.  Sequentially-consistent
 * store+load on each side (a Dekker handshake) gives mutual exclusion.  A crashed
 * reader is recovered by clearing its one slot (CAS pid->0) -- no second counter
 * to strand, no orphaned +1, no quiescent force-reset -- so sustained read
 * traffic can never starve a writer.  Write-preference is inherent in the gate
 * (new readers see wlock!=0 and yield). */

/* A zombie (dead but not yet reaped) still answers kill(pid,0) as alive, so a
 * process that crashed while holding the lock and lingers unreaped would never
 * be recovered.  Treat /proc/<pid>/stat state 'Z' as dead.  Linux-only (as is
 * this module); if /proc is unreadable we fall back to "alive" (safe: we never
 * force-recover a possibly-live holder). */
static inline int buf_pid_is_zombie(uint32_t pid) {
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
static inline int buf_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !buf_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
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

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void buf_occ_set(BufHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void buf_occ_clear(BufHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
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
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < BUF_READER_SLOTS; i++) {
        uint32_t s = (start + i) % BUF_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            buf_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < BUF_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || buf_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            buf_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = i;
            return;
        }
    }
    /* Table full -- leave my_slot_idx = UINT32_MAX so this handle takes the
     * slotless path (lock still works; recovery of THIS reader's death is the
     * documented slotless limitation). */
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void buf_park(BufHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void buf_unpark(BufHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void buf_rdepth_inc(BufHandle *h) {
    h->rd_held++;                      /* process-local: what THIS handle owes */
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    else
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
}
static inline void buf_rdepth_dec(BufHandle *h) {
    if (h->rd_held) h->rd_held--;
    if (h->my_slot_idx == UINT32_MAX)
        __atomic_sub_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_RELEASE);
    else
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_RELEASE);
}

/* Wake a writer that may be draining readers (it waits on drain_seq).  Called
 * after every rdepth decrement so a released read lock lets the writer re-scan
 * promptly instead of waiting out its timeout. */
static inline void buf_reader_wake_drain(BufHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void buf_recover_stale_lock(BufHeader *hdr, uint32_t observed_wlock) {
    uint32_t mypid = BUF_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    uint32_t seq = __atomic_load_n(&hdr->seq, __ATOMIC_ACQUIRE);
    if (seq & 1)
        __atomic_store_n(&hdr->seq, seq + 1, __ATOMIC_RELEASE);
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec buf_lock_timeout = { BUF_LOCK_TIMEOUT_SEC, 0 };

/* Inspect the writer word after a futex-wait timeout.  If a dead writer holds
 * it, force-recover.  Dead READERS need no action here: only a writer that owns
 * wlock drains readers, and it clears dead readers inline in its own scan. */
static inline void buf_recover_after_timeout(BufHandle *h) {
    BufHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
    if (val >= BUF_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & BUF_RWLOCK_PID_MASK;
        if (!buf_pid_alive(pid))
            buf_recover_stale_lock(hdr, val);
    }
}

static inline void buf_rwlock_rdlock(BufHandle *h) {
    BufHeader *hdr = h->hdr;
    buf_claim_reader_slot(h);
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            buf_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                        /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            buf_rdepth_dec(h);
            buf_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= BUF_RWLOCK_WRITER_BIT &&
            !buf_pid_alive(cur & BUF_RWLOCK_PID_MASK)) {
            buf_recover_stale_lock(hdr, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < BUF_RWLOCK_SPIN_LIMIT, 1)) {
            buf_spin_pause();
            continue;
        }
        buf_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &buf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                buf_unpark(h);
                buf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        buf_unpark(h);
        spin = 0;
    }
}

static inline void buf_rwlock_rdunlock(BufHandle *h) {
    buf_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    buf_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void buf_rwlock_wrlock(BufHandle *h) {
    BufHeader *hdr = h->hdr;
    buf_claim_reader_slot(h);
    uint32_t mypid = BUF_RWLOCK_WR((uint32_t)getpid());
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= BUF_RWLOCK_WRITER_BIT &&
            !buf_pid_alive(expected & BUF_RWLOCK_PID_MASK)) {
            buf_recover_stale_lock(hdr, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < BUF_RWLOCK_SPIN_LIMIT, 1)) {
            buf_spin_pause();
            continue;
        }
        buf_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &buf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                buf_unpark(h);
                buf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        buf_unpark(h);
        spin = 0;
    }
    /* Phase 2: we own wlock, so no NEW reader can join (they see wlock!=0 and
     * yield).  Drain the readers that were already holding when we won the CAS.
     * The SEQ_CST CAS above + the SEQ_CST rdepth loads below are the writer side
     * of the Dekker handshake. */
    for (;;) {
        uint32_t v = __atomic_load_n(&hdr->drain_seq, __ATOMIC_RELAXED);  /* snapshot BEFORE scan */
        int busy = 0;
        /* Visit only OCCUPIED slots via the occupancy bitmap (SEQ_CST: a committed
         * reader's bit -- set in claim, before its rdepth++ -- is ordered before
         * this scan, so no held slot is skipped).  O(BUF_OCC_WORDS + live readers)
         * instead of O(BUF_READER_SLOTS). */
        for (uint32_t w = 0; w < BUF_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!buf_pid_alive(pid)) {
                    /* Dead reader: drop its pid so the slot no longer counts.  Leave
                     * the occ bit set (harmless -- a later scan hits pid==0 and skips,
                     * a re-claim re-sets it) to avoid racing a concurrent claimant. */
                    uint32_t ep = pid;
                    if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &ep, 0,
                            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                        __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
                    continue;
                }
                busy = 1;                                   /* live reader still holding */
            }
        }
        /* A live slotless reader keeps us waiting; a crashed slotless reader that
         * cannot be attributed to a pid is the documented slotless limitation. */
        if (__atomic_load_n(&hdr->slotless_rdepth, __ATOMIC_SEQ_CST) != 0)
            busy = 1;
        if (!busy)
            return;                                    /* exclusive: wlock held + every rdepth 0 */
        /* Wait for a reader to release (drain_seq bump) or time out to re-scan
         * (which reclaims any newly-dead slotted reader). */
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &buf_lock_timeout, NULL, 0);
    }
}

static inline void buf_rwlock_wrunlock(BufHandle *h) {
    __atomic_store_n(&h->hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&h->hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &h->hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
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
        uint32_t val = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
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
    /* Acquire FENCE (LoadLoad): the section's data loads must retire before we
     * re-read seq; a plain acquire load is the wrong direction (ARM64 torn read). */
    __atomic_thread_fence(__ATOMIC_ACQUIRE);
    return __atomic_load_n(seq, __ATOMIC_RELAXED) != start;
}

static inline void buf_seqlock_write_begin(uint32_t *seq) {
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);  /* seq becomes odd */
    /* StoreStore: publish the odd seq before the section's data writes, else an
     * ARM64 reader could see an even seq with half-written data (Linux smp_wmb). */
    __atomic_thread_fence(__ATOMIC_RELEASE);
}

static inline void buf_seqlock_write_end(uint32_t *seq) {
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);
}

/* ---- mmap create/open ---- */

/* Race-safe create-or-attach with restrictive perms + symlink refusal.
 * The backing file is created 0600 by default (see file_mode); a local peer
 * cannot pre-create it as a symlink (O_NOFOLLOW) nor open a wider-permissioned
 * copy.  Sets *created=1 iff this call won the O_EXCL race and made the file. */
static int buf_secure_open(const char *path, mode_t file_mode, int *created, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, file_mode);
        if (fd >= 0) { (void)fchmod(fd, file_mode); *created = 1; return fd; }  /* exact mode: umask narrowed the create */
        if (errno != EEXIST) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "create(%s): %s", path, strerror(errno));
            return -1;
        }
        fd = open(path, O_RDWR | O_NOFOLLOW | O_CLOEXEC);
        if (fd >= 0) { *created = 0; return fd; }
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        snprintf(errbuf, BUF_ERR_BUFLEN, "open(%s): %s", path, strerror(errno));
        return -1;
    }
    snprintf(errbuf, BUF_ERR_BUFLEN, "open(%s): create/attach kept racing", path);
    return -1;
}

static BufHandle *buf_create_map(const char *path, uint64_t capacity,
                                  uint32_t elem_size, uint32_t variant_id,
                                  mode_t file_mode, char *errbuf) {
    errbuf[0] = '\0';
    int created = 0;
    int fd = buf_secure_open(path, file_mode, &created, errbuf);
    if (fd < 0) {
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
    uint64_t occ_off = reader_slots_off + reader_slots_size;     /* occupancy bitmap */
    uint64_t data_off = occ_off + BUF_OCC_BYTES; /* cache-aligned */
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
    if (!created && st.st_size == 0 && (st.st_uid != geteuid() || fchmod(fd, file_mode) < 0)) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "%s: refusing to initialize file not owned by us", path);
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
        /* A pre-existing but uninitialized file (magic==0, not created by us) may
         * be smaller than the region we are about to zero; a hostile peer could
         * pre-create an undersized file to drive the init memset out of bounds. */
        if (!created && (uint64_t)st.st_size < total_size) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: file too small to initialize", path);
            goto fail;
        }
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
        /* Zero reader_slots + occ bitmap + data area */
        memset((char *)base + reader_slots_off, 0,
               (size_t)(reader_slots_size + BUF_OCC_BYTES + capacity * elem_size));
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
            hdr->reader_slots_off > (uint64_t)st.st_size ||
            hdr->reader_slots_off + reader_slots_size > (uint64_t)st.st_size ||
            hdr->data_off < hdr->reader_slots_off + reader_slots_size ||
            hdr->data_off > (uint64_t)st.st_size ||
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
    h->reader_slots = (BufReaderSlot *)((char *)base + sizeof(BufHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ = (uint64_t *)((char *)base + sizeof(BufHeader) + reader_slots_size);  /* trusted layout offset */
    h->capacity = hdr->capacity;    /* cache validated geometry; peer can't grow it under us */
    h->elem_size = hdr->elem_size;
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
    uint64_t occ_off = reader_slots_off + reader_slots_size;
    uint64_t data_off = occ_off + BUF_OCC_BYTES;
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
    /* MAP_ANONYMOUS already zero-fills reader_slots, occ bitmap and data. */

    BufHandle *h = (BufHandle *)calloc(1, sizeof(BufHandle));
    if (!h) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "calloc: out of memory");
        munmap(base, (size_t)total_size);
        return NULL;
    }
    h->hdr = hdr;
    h->data = (char *)base + data_off;
    h->reader_slots = (BufReaderSlot *)((char *)base + reader_slots_off);
    h->occ = (uint64_t *)((char *)base + occ_off);
    h->capacity = hdr->capacity;    /* cache validated geometry */
    h->elem_size = hdr->elem_size;
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
    uint64_t occ_off = reader_slots_off + reader_slots_size;
    uint64_t data_off = occ_off + BUF_OCC_BYTES;
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
    h->occ = (uint64_t *)((char *)base + occ_off);
    h->capacity = hdr->capacity;    /* cache validated geometry */
    h->elem_size = hdr->elem_size;
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
        hdr->reader_slots_off > (uint64_t)st.st_size ||
        hdr->reader_slots_off + reader_slots_size > (uint64_t)st.st_size ||
        hdr->data_off < hdr->reader_slots_off + reader_slots_size ||
        hdr->data_off > (uint64_t)st.st_size ||
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
        h->reader_slots = (BufReaderSlot *)((char *)base + sizeof(BufHeader));  /* trusted layout, not the peer-writable header offset */
        h->occ = (uint64_t *)((char *)base + sizeof(BufHeader) + reader_slots_size);  /* trusted layout offset */
        h->capacity = hdr->capacity;    /* cache validated geometry */
        h->elem_size = hdr->elem_size;
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
    /* Release any lock this handle still holds BEFORE freeing it. Destroying a
     * handle mid-lock (e.g. `$b->lock_rd; undef $b;`) otherwise pins the reader
     * slot with a LIVE pid and rdepth > 0, or leaves wlock set to a live pid --
     * and because that pid is alive, dead-owner recovery never fires, so every
     * other process starves until this one exits. rdepth is per-process and
     * shared by all handles, so we can only drop what THIS handle owes. */
    if (h->hdr) {
        /* Release only locks THIS process took.  A forked child inherits
         * rd_held/wr_locked verbatim, but those holds were published by the
         * parent (its slot rdepth, its pid in wlock): dropping them here
         * would unlock the parent's live critical section.  Same owner test
         * as the slot-release guard below; cached_pid/cached_fork_gen are
         * recorded by buf_claim_reader_slot, which every lock op runs, so a
         * nonzero rd_held/wr_locked implies they are set. */
        uint32_t cur_gen = __atomic_load_n(&buf_fork_gen, __ATOMIC_RELAXED);
        if (h->cached_pid && h->cached_pid == (uint32_t)getpid() &&
            h->cached_fork_gen == cur_gen) {
            while (h->rd_held > 0) buf_rwlock_rdunlock(h);   /* decrements rd_held */
            /* Mirror unlock_wr exactly: end the seqlock section BEFORE
             * dropping wlock.  wrunlock alone leaves seq odd forever, and
             * every seqlock bulk reader then spins in its slow path with no
             * recovery (wlock == 0, so stale-writer recovery never fires). */
            if (h->wr_locked) {
                buf_seqlock_write_end(&h->hdr->seq);
                buf_rwlock_wrunlock(h);
                h->wr_locked = 0;
            }
        }
    }
    /* Release reader slot -- only if we still own it AND no fork has happened
     * since we claimed it.  A forked child that inherits the handle but never
     * acquired the lock itself must NOT clear the parent's slot. */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&buf_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* rdepth==0: a still-held read lock's slot must survive for recovery */
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        buf_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        /* CAS pid -> 0; do NOT clear rdepth -- between the CAS and a follow-up
         * store, a new process could claim the slot, and our store would clobber
         * its state.  buf_claim_reader_slot zeros rdepth on every claim, so
         * leaving a stale value is safe. */
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
                                  uint32_t str_len, mode_t file_mode, char *errbuf) {
    if (str_len == 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "str_len must be > 0");
        return NULL;
    }
    return buf_create_map(path, capacity, str_len, BUF_VARIANT_ID, file_mode, errbuf);
}
#else
static BufHandle *BUF_FN(create)(const char *path, uint64_t capacity, mode_t file_mode, char *errbuf) {
    return buf_create_map(path, capacity, BUF_ELEM_SIZE, BUF_VARIANT_ID, file_mode, errbuf);
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

/* Byte-span validity WITHOUT allocating.  The XS get_raw does newSV(nbytes) and
   writes a NUL at [nbytes] BEFORE this copy is called; a pathological nbytes
   (e.g. ~0) makes newSV's internal nbytes+1 integer-overflow to a tiny buffer,
   then the NUL write lands out of bounds.  The XS calls this first to reject
   such args before allocating. */
static int BUF_FN(raw_in_bounds)(BufHandle *h, uint64_t byte_off, uint64_t nbytes) {
    uint64_t data_size = h->capacity * (uint64_t)h->elem_size;
    return nbytes <= data_size && byte_off <= data_size - nbytes;
}

static int BUF_FN(get_raw)(BufHandle *h, uint64_t byte_off, uint64_t nbytes, void *out) {
    uint64_t data_size = h->capacity * (uint64_t)h->elem_size;
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
    uint64_t data_size = h->capacity * (uint64_t)h->elem_size;
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
    memset(h->data, 0, (size_t)((uint64_t)h->capacity * h->elem_size));
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(h); }
}

/* ---- Single-element atomic get (lock-free for numeric types) ---- */

#ifdef BUF_IS_FIXEDSTR

static int BUF_FN(get)(BufHandle *h, uint64_t idx, char *out, uint32_t *out_len) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = h->elem_size;
    if (idx >= h->capacity) return 0;
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
    uint32_t esz = h->elem_size;
    if (idx >= h->capacity) return 0;
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
    if (idx >= h->capacity) return 0;
    typedef BUF_PASTE(BUF_PREFIX, _uint_t) uint_t;
    uint_t *idata = (uint_t *)h->data;
    uint_t tmp = __atomic_load_n(&idata[idx], __ATOMIC_RELAXED);
    memcpy(out, &tmp, sizeof(BUF_ELEM_TYPE));
    return 1;
}

static int BUF_FN(set)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE val) {
    if (idx >= h->capacity) return 0;
    typedef BUF_PASTE(BUF_PREFIX, _uint_t) uint_t;
    uint_t *idata = (uint_t *)h->data;
    uint_t tmp;
    memcpy(&tmp, &val, sizeof(BUF_ELEM_TYPE));
    __atomic_store_n(&idata[idx], tmp, __ATOMIC_RELAXED);
    return 1;
}

#else /* integer types */

static int BUF_FN(get)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE *out) {
    if (idx >= h->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    *out = __atomic_load_n(&data[idx], __ATOMIC_RELAXED);
    return 1;
}

static int BUF_FN(set)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE val) {
    if (idx >= h->capacity) return 0;
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
    uint32_t esz = h->elem_size;
    if (count > h->capacity || from > h->capacity - count) return 0;
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
    uint32_t esz = h->elem_size;
    if (count > h->capacity || from > h->capacity - count) return 0;
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
    if (count > h->capacity || from > h->capacity - count) return 0;
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
    if (count > h->capacity || from > h->capacity - count) return 0;
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
    uint32_t esz = h->elem_size;
    char *data = (char *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(h); buf_seqlock_write_begin(&hdr->seq); }
    uint32_t copy_len = len < esz ? len : esz;
    memset(data, 0, (size_t)h->capacity * esz);
    for (uint64_t i = 0; i < h->capacity; i++)
        memcpy(data + i * esz, val, copy_len);
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(h); }
}

#else

static void BUF_FN(fill)(BufHandle *h, BUF_ELEM_TYPE val) {
    BufHeader *hdr = h->hdr;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(h); buf_seqlock_write_begin(&hdr->seq); }
    for (uint64_t i = 0; i < h->capacity; i++)
        data[i] = val;
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(h); }
}

#endif

/* ---- Atomic operations (integer types only) ---- */

#ifdef BUF_HAS_COUNTERS

static BUF_ELEM_TYPE BUF_FN(incr)(BufHandle *h, uint64_t idx) {
    if (idx >= h->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_add_fetch(&data[idx], 1, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(decr)(BufHandle *h, uint64_t idx) {
    if (idx >= h->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_sub_fetch(&data[idx], 1, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(add)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE delta) {
    if (idx >= h->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_add_fetch(&data[idx], delta, __ATOMIC_RELAXED);
}

static int BUF_FN(cas)(BufHandle *h, uint64_t idx,
                        BUF_ELEM_TYPE expected, BUF_ELEM_TYPE desired) {
    if (idx >= h->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_compare_exchange_n(&data[idx], &expected, desired,
                                        0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(cmpxchg)(BufHandle *h, uint64_t idx,
                                       BUF_ELEM_TYPE expected, BUF_ELEM_TYPE desired) {
    if (idx >= h->capacity) return expected;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    __atomic_compare_exchange_n(&data[idx], &expected, desired,
                                0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
    return expected; /* on failure, expected is updated to the current value */
}

static BUF_ELEM_TYPE BUF_FN(atomic_and)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE mask) {
    if (idx >= h->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_and_fetch(&data[idx], mask, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(atomic_or)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE mask) {
    if (idx >= h->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_or_fetch(&data[idx], mask, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(atomic_xor)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE mask) {
    if (idx >= h->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_xor_fetch(&data[idx], mask, __ATOMIC_RELAXED);
}

static int BUF_FN(add_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              const BUF_ELEM_TYPE *deltas) {
    if (count > h->capacity || from > h->capacity - count) return 0;
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
    if (idx >= h->capacity) return NULL;
    return (char *)h->data + idx * h->elem_size;
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
