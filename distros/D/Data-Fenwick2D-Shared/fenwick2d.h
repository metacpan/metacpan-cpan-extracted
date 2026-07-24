/*
 * fenwick2d.h -- Shared-memory 2-D Fenwick tree (binary indexed tree) for Linux
 *
 * A fixed rows x cols grid of signed int64 cells supporting O(log rows*log cols)
 * point update and rectangle-sum query: add a delta at cell (x,y), ask the sum
 * over the origin rectangle [1..x]x[1..y] or any axis-aligned rectangle.  The
 * grid lives in a shared mapping so several processes update and query one
 * structure; a write-preferring futex rwlock with reader-slot dead-process
 * recovery guards mutation.
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> grid[(rows+1)*(cols+1) int64]
 *         (row-major, 1-indexed; row 0 and col 0 unused)
 */

#ifndef F2D_H
#define F2D_H

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
#error "fenwick2d.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define F2D_MAGIC        0x42443246U  /* Fenwick2D */
#define F2D_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define F2D_ERR_BUFLEN   256
#ifndef F2D_READER_SLOTS
#define F2D_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these F2D_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all F2D_READER_SLOTS. */
#define F2D_OCC_WORDS   (((F2D_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define F2D_OCC_BYTES   ((uint64_t)F2D_OCC_WORDS * 8)      /* 128 bytes */
#define F2D_MIN_DIM      1
#define F2D_MAX_DIM      0x1000000ULL   /* 2^24 per side; grid is (rows+1)*(cols+1) int64 */

#define F2D_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, F2D_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

/* ================================================================
 * Structs
 * ================================================================ */

/* Per-process slot for dead-process recovery.  In the reader-slots-only rwlock a
 * reader's ENTIRE contribution to the shared lock is `rdepth` in its OWN slot --
 * there is no separate shared reader counter to fall out of sync with it -- so a
 * dead reader's contribution is exactly this one word, which a draining writer
 * neutralises by clearing the slot's pid (the scan then ignores the slot).  No
 * orphaned counter can exist, so there is no quiescent force-reset and sustained
 * readers cannot starve a writer.  _rsv1/_rsv2 are kept only to preserve the
 * 16-byte slot size across the already-released builds. */
typedef struct {
    uint32_t pid;      /* 0 = unclaimed */
    uint32_t rdepth;   /* read-locks THIS process currently holds (recursion-safe) */
    uint32_t _rsv1;    /* reserved (was waiters_parked); unused, kept for layout size */
    uint32_t _rsv2;    /* reserved (was writers_parked); unused, kept for layout size */
} F2dReaderSlot;

struct F2dHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t _pad0;                   /* 8 */
    uint32_t _pad1;                   /* 12 */
    uint64_t rows;                    /* 16  grid rows (1..rows), 1-indexed */
    uint64_t cols;                    /* 24  grid cols (1..cols), 1-indexed */
    uint64_t total_size;              /* 32 */
    uint64_t reader_slots_off;        /* 40 */
    uint64_t tree_off;                /* 48  (rows+1)*(cols+1) int64 grid, row-major */
    uint32_t wlock;                   /* 56  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 60  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 64  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 72 */
    uint8_t  _pad[176];               /* 80..255 */
};
typedef struct F2dHeader F2dHeader;

_Static_assert(sizeof(F2dHeader) == 256, "F2dHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct F2dHandle {
    F2dHeader     *hdr;
    F2dReaderSlot *reader_slots;  /* F2D_READER_SLOTS entries */
    uint64_t      *occ;          /* F2D_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      tree_off;      /* validated tree-array offset, cached: never re-read from the peer-writable header */
    uint64_t      rows;          /* cached grid rows */
    uint64_t      cols;          /* cached grid cols */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* f2d_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} F2dHandle;

/* ================================================================
 * Futex-based write-preferring read-write lock (reader-slots-only)
 * with dead-process recovery
 *
 * The reader count is NOT stored in a shared counter.  It is DISTRIBUTED across
 * per-process reader slots: each slot's `rdepth` is that process's entire
 * contribution to the lock.  A reader publishes its presence in its own slot and
 * then re-checks the writer word; a writer publishes the writer word and then
 * scans every slot until all live readers' rdepth reach 0.  Sequentially-
 * consistent store+load on each side (a Dekker handshake) gives mutual exclusion.
 *
 * Because a reader's whole contribution is ONE atomic word owned by ONE process,
 * a crashed reader is recovered by clearing that one slot (CAS its pid to 0) --
 * there is no second counter to strand, no orphaned +1, and therefore no
 * quiescent force-reset.  A reader killed anywhere in rdlock/rdunlock leaves at
 * most `rdepth>0` in its dead slot, which the draining writer clears directly, so
 * sustained read traffic can never starve a writer.  Write-preference is inherent
 * in the gate (new readers see wlock!=0 and yield), so there is no reader-count
 * yield hack.
 * ================================================================ */

#define F2D_RWLOCK_SPIN_LIMIT 32
#define F2D_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void f2d_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define F2D_RWLOCK_WRITER_BIT 0x80000000U
#define F2D_RWLOCK_PID_MASK   0x7FFFFFFFU
#define F2D_RWLOCK_WR(pid)    (F2D_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & F2D_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's rdepth is not reclaimed until the
 * recycled process exits. Robust detection would require a per-slot
 * process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
/* A zombie (dead but not yet reaped) still answers kill(pid,0) as alive, so a
 * process that crashed while holding the lock and lingers unreaped would never
 * be recovered.  Treat /proc/<pid>/stat state 'Z' as dead.  Linux-only (as is
 * this module); if /proc is unreadable we fall back to "alive" (safe: we never
 * force-recover a possibly-live holder). */
static inline int f2d_pid_is_zombie(uint32_t pid) {
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
static inline int f2d_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !f2d_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void f2d_recover_stale_lock(F2dHandle *h, uint32_t observed_wlock) {
    F2dHeader *hdr = h->hdr;
    uint32_t mypid = F2D_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec f2d_lock_timeout = { F2D_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t f2d_fork_gen = 1;
static pthread_once_t f2d_atfork_once = PTHREAD_ONCE_INIT;
static void f2d_on_fork_child(void) {
    __atomic_add_fetch(&f2d_fork_gen, 1, __ATOMIC_RELAXED);
}
static void f2d_atfork_init(void) {
    pthread_atfork(NULL, NULL, f2d_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void f2d_occ_set(F2dHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void f2d_occ_clear(F2dHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so that
 * fork()'d children pick up their own slot lazily instead of sharing the
 * parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void f2d_claim_reader_slot(F2dHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&f2d_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&f2d_atfork_once, f2d_atfork_init);
    /* Re-read after pthread_once: f2d_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&f2d_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % F2D_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < F2D_READER_SLOTS; i++) {
        uint32_t s = (start + i) % F2D_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            f2d_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < F2D_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || f2d_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            f2d_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
 * wlock drains readers, and it clears dead readers inline in its own scan. */
static inline void f2d_recover_after_timeout(F2dHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= F2D_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & F2D_RWLOCK_PID_MASK;
        if (!f2d_pid_alive(pid))
            f2d_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void f2d_park(F2dHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void f2d_unpark(F2dHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void f2d_rdepth_inc(F2dHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void f2d_rdepth_dec(F2dHandle *h) {
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
static inline void f2d_reader_wake_drain(F2dHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void f2d_rwlock_rdlock(F2dHandle *h) {
    f2d_claim_reader_slot(h);
    F2dHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            f2d_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            f2d_rdepth_dec(h);
            f2d_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= F2D_RWLOCK_WRITER_BIT &&
            !f2d_pid_alive(cur & F2D_RWLOCK_PID_MASK)) {
            f2d_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < F2D_RWLOCK_SPIN_LIMIT, 1)) {
            f2d_rwlock_spin_pause();
            continue;
        }
        f2d_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &f2d_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                f2d_unpark(h);
                f2d_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        f2d_unpark(h);
        spin = 0;
    }
}

static inline void f2d_rwlock_rdunlock(F2dHandle *h) {
    f2d_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    f2d_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void f2d_rwlock_wrlock(F2dHandle *h) {
    f2d_claim_reader_slot(h);  /* refresh cached_pid across fork */
    F2dHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = F2D_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= F2D_RWLOCK_WRITER_BIT &&
            !f2d_pid_alive(expected & F2D_RWLOCK_PID_MASK)) {
            f2d_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < F2D_RWLOCK_SPIN_LIMIT, 1)) {
            f2d_rwlock_spin_pause();
            continue;
        }
        f2d_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &f2d_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                f2d_unpark(h);
                f2d_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        f2d_unpark(h);
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
         * this scan, so no held slot is skipped).  O(F2D_OCC_WORDS + live readers)
         * instead of O(F2D_READER_SLOTS). */
        for (uint32_t w = 0; w < F2D_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!f2d_pid_alive(pid)) {
                    /* Dead reader: drop its pid so the slot no longer counts.  Leave
                     * the occ bit set (harmless -- a later scan hits pid==0 and skips,
                     * a re-claim re-sets it) to avoid racing a concurrent claimant. */
                    uint32_t ep = pid;
                    __atomic_compare_exchange_n(&h->reader_slots[i].pid, &ep, 0,
                            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &f2d_lock_timeout, NULL, 0);
    }
}

static inline void f2d_rwlock_wrunlock(F2dHandle *h) {
    F2dHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> grid[(rows+1)*(cols+1) int64]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> grid. */
typedef struct { uint64_t reader_slots, occ, tree; } F2dLayout;

static inline F2dLayout f2d_layout(void) {
    F2dLayout L;
    L.reader_slots = sizeof(F2dHeader);
    L.occ          = L.reader_slots + (uint64_t)F2D_READER_SLOTS * sizeof(F2dReaderSlot);
    L.tree         = L.occ + F2D_OCC_BYTES;
    L.tree         = (L.tree + 7) & ~(uint64_t)7;   /* 8-byte align the int64 tree array */
    return L;
}

/* the grid is 1-indexed row-major: (rows+1)*(cols+1) int64 slots, row/col 0 unused */
static inline uint64_t f2d_total_size(uint64_t rows, uint64_t cols) {
    F2dLayout L = f2d_layout();
    return L.tree + (rows + 1) * (cols + 1) * sizeof(int64_t);
}

static inline void f2d_init_header(void *base, uint64_t rows, uint64_t cols, uint64_t total) {
    F2dLayout L = f2d_layout();
    F2dHeader *hdr = (F2dHeader *)base;
    /* Zero the header + reader-slot region; the grid relies on the fresh mapping
       being OS zero-filled (every prefix sum starts at 0). */
    memset(base, 0, (size_t)L.tree);
    hdr->magic            = F2D_MAGIC;
    hdr->version          = F2D_VERSION;
    hdr->rows             = rows;
    hdr->cols             = cols;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->tree_off         = L.tree;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline int64_t *f2d_tree(F2dHandle *h) {
    return (int64_t *)((char *)h->base + h->tree_off);
}

/* Layer B trusted bound: number of int64 tree slots guaranteed within the real
 * mapping.  Derived from the process-local mmap_size (fixed at attach, not
 * peer-writable) and the SAME tree_off f2d_tree() uses, so a peer that corrupts
 * hdr->rows / hdr->cols / tree_off after attach-time validation can never drive
 * an access outside the mapping.  Equals (rows+1)*(cols+1) for a valid grid. */
static inline uint64_t f2d_tree_slots_max(F2dHandle *h) {
    uint64_t off = h->tree_off;
    if (off >= h->mmap_size) return 0;
    return (h->mmap_size - off) / sizeof(int64_t);
}

static inline F2dHandle *f2d_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    F2dHeader *hdr = (F2dHeader *)base;
    F2dHandle *h = (F2dHandle *)calloc(1, sizeof(F2dHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (F2dReaderSlot *)((uint8_t *)base + sizeof(F2dHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + f2d_layout().occ);        /* trusted layout offset */
    h->tree_off     = hdr->tree_off;   /* single validated read; bound and pointer stay consistent */
    h->rows         = hdr->rows;
    h->cols         = hdr->cols;
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by f2d_create reopen and f2d_open_fd). */
static inline int f2d_validate_header(const F2dHeader *hdr, uint64_t file_size) {
    if (hdr->magic != F2D_MAGIC) return 0;
    if (hdr->version != F2D_VERSION) return 0;
    if (hdr->rows < F2D_MIN_DIM || hdr->rows > F2D_MAX_DIM) return 0;
    if (hdr->cols < F2D_MIN_DIM || hdr->cols > F2D_MAX_DIM) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != f2d_total_size(hdr->rows, hdr->cols)) return 0;
    F2dLayout L = f2d_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->tree_off != L.tree) return 0;
    return 1;
}

/* validate the requested grid dimensions (rows, cols) */
static int f2d_validate_args(uint64_t rows, uint64_t cols, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (rows < F2D_MIN_DIM || rows > F2D_MAX_DIM) { F2D_ERR("rows must be between 1 and 2^24"); return 0; }
    if (cols < F2D_MIN_DIM || cols > F2D_MAX_DIM) { F2D_ERR("cols must be between 1 and 2^24"); return 0; }
    if ((cols + 1) > (UINT64_MAX / 8) / (rows + 1)) { F2D_ERR("rows * cols too large for the grid"); return 0; }
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via f2d_validate_header. */
static int f2d_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { F2D_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        F2D_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    F2D_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static F2dHandle *f2d_create(const char *path, uint64_t rows, uint64_t cols, mode_t mode, char *errbuf) {
    if (!f2d_validate_args(rows, cols, errbuf)) return NULL;

    uint64_t total = f2d_total_size(rows, cols);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { F2D_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = f2d_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { F2D_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { F2D_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(F2dHeader)) {
            F2D_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            F2D_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            F2D_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { F2D_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!f2d_validate_header((F2dHeader *)base, (uint64_t)st.st_size)) {
                F2D_ERR("invalid Fenwick2D tree file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return f2d_setup(base, map_size, path, -1);
        }
    }
    f2d_init_header(base, rows, cols, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return f2d_setup(base, map_size, path, -1);
}

static F2dHandle *f2d_create_memfd(const char *name, uint64_t rows, uint64_t cols, char *errbuf) {
    if (!f2d_validate_args(rows, cols, errbuf)) return NULL;

    uint64_t total = f2d_total_size(rows, cols);
    int fd = memfd_create(name ? name : "fenwick2d", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { F2D_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        F2D_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { F2D_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    f2d_init_header(base, rows, cols, total);
    return f2d_setup(base, (size_t)total, NULL, fd);
}

static F2dHandle *f2d_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { F2D_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(F2dHeader)) { F2D_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { F2D_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!f2d_validate_header((F2dHeader *)base, (uint64_t)st.st_size)) {
        F2D_ERR("invalid Fenwick2D tree table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { F2D_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return f2d_setup(base, ms, NULL, myfd);
}

static void f2d_destroy(F2dHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&f2d_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        f2d_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int f2d_msync(F2dHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * 2-D Fenwick tree (binary indexed tree) operations -- callers hold the lock.
 * 1-indexed row-major grid; along each axis a BIT node x covers (x-lowbit(x), x],
 * lowbit(x) = x & -x.  Values are signed int64 (deltas may be negative).
 * ================================================================ */

static inline uint64_t f2d_lowbit(uint64_t x) { return x & (~x + 1ULL); }

/* flat row-major index of grid cell (i,j) in the (rows+1)x(cols+1) array */
static inline uint64_t f2d_idx(uint64_t i, uint64_t j, uint64_t cols) {
    return i * (cols + 1) + j;
}
/* highest 1-based (row, col) safely inside the mapping.  cols is used as-is (a
 * corrupt-large cols is caught by the per-access flat bound below); rows is
 * clamped so (rows+1) full rows of stride (cols+1) fit -- Layer B. */
static inline void f2d_dims(F2dHandle *h, uint64_t *rmax, uint64_t *cmax) {
    uint64_t stride = h->cols + 1;
    uint64_t smax   = f2d_tree_slots_max(h);
    uint64_t fit1   = stride ? smax / stride : 0;    /* whole (rows+1) that fit */
    uint64_t maxr   = fit1 ? fit1 - 1 : 0;
    *rmax = h->rows < maxr ? h->rows : maxr;
    *cmax = h->cols;
}

/* add delta at grid cell (x,y) (1-based); caller holds the write lock */
static void f2d_update_locked(F2dHandle *h, uint64_t x, uint64_t y, int64_t delta) {
    int64_t *tree = f2d_tree(h);
    uint64_t rmax, cmax; f2d_dims(h, &rmax, &cmax);
    uint64_t smax = f2d_tree_slots_max(h);
    for (uint64_t i = x; i >= 1 && i <= rmax; i += f2d_lowbit(i))
        for (uint64_t j = y; j >= 1 && j <= cmax; j += f2d_lowbit(j)) {
            uint64_t f = f2d_idx(i, j, cmax);
            if (f < smax) tree[f] += delta;          /* Layer B: bulletproof flat bound */
        }
}

/* prefix sum over the rectangle [1..x] x [1..y] (1-based; x or y == 0 -> 0) */
static int64_t f2d_prefix_locked(F2dHandle *h, uint64_t x, uint64_t y) {
    const int64_t *tree = f2d_tree(h);
    uint64_t rmax, cmax; f2d_dims(h, &rmax, &cmax);
    uint64_t smax = f2d_tree_slots_max(h);
    if (x > rmax) x = rmax;
    if (y > cmax) y = cmax;
    int64_t s = 0;
    for (uint64_t i = x; i > 0; i -= f2d_lowbit(i))
        for (uint64_t j = y; j > 0; j -= f2d_lowbit(j)) {
            uint64_t f = f2d_idx(i, j, cmax);
            if (f < smax) s += tree[f];
        }
    return s;
}

/* sum over the inclusive rectangle [x1..x2] x [y1..y2] (1-based) via inclusion-exclusion */
static int64_t f2d_rect_locked(F2dHandle *h, uint64_t x1, uint64_t y1, uint64_t x2, uint64_t y2) {
    return f2d_prefix_locked(h, x2,     y2)
         - f2d_prefix_locked(h, x1 - 1, y2)
         - f2d_prefix_locked(h, x2,     y1 - 1)
         + f2d_prefix_locked(h, x1 - 1, y1 - 1);
}

/* value at cell (x,y) == the 1x1 rectangle sum */
static int64_t f2d_point_locked(F2dHandle *h, uint64_t x, uint64_t y) {
    return f2d_rect_locked(h, x, y, x, y);
}

/* reset the whole grid to 0 (caller holds the write lock) */
static inline void f2d_clear_locked(F2dHandle *h) {
    uint64_t slots = (h->rows + 1) * (h->cols + 1);
    uint64_t slots_max = f2d_tree_slots_max(h);      /* Layer B: clamp memset to the mapping */
    if (slots > slots_max) slots = slots_max;
    memset(f2d_tree(h), 0, (size_t)(slots * sizeof(int64_t)));
}

#endif /* F2D_H */
