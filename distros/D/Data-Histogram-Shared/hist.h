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
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> counts[counts_len]  (each int64_t)
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
#define HIST_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define HIST_ERR_BUFLEN   256
#ifndef HIST_READER_SLOTS
#define HIST_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these HIST_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all HIST_READER_SLOTS. */
#define HIST_OCC_WORDS   (((HIST_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define HIST_OCC_BYTES   ((uint64_t)HIST_OCC_WORDS * 8)      /* 128 bytes */
#define HIST_MIN_SIG      1            /* significant figures range */
#define HIST_MAX_SIG      5

#define HIST_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, HIST_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
    uint32_t wlock;                   /* 128  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 132  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 136  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* live readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 144 */
    uint8_t  sealed;                  /* 152  0 = mutable, 1 = frozen (read-only; lock-free reads) */
    uint8_t  _pad[103];               /* 153..255 */
};
typedef struct HistHeader HistHeader;

_Static_assert(sizeof(HistHeader) == 256, "HistHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct HistHandle {
    HistHeader     *hdr;
    HistReaderSlot *reader_slots;  /* HIST_READER_SLOTS entries */
    uint64_t       *occ;           /* HIST_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void           *base;          /* mmap base */
    size_t          mmap_size;
    uint64_t        counts_off;    /* validated counts offset, cached: never re-read from the peer-writable header */
    char           *path;          /* backing file path (strdup'd) */
    int             backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t        my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t        cached_pid;    /* getpid() cached at last slot claim */
    uint32_t        cached_fork_gen; /* hist_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
    int      readonly;      /* 1 = frozen O_RDONLY/PROT_READ view: lock-free reads, mutation croaks */
} HistHandle;

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

#define HIST_RWLOCK_SPIN_LIMIT 32
#define HIST_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void hist_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define HIST_RWLOCK_WRITER_BIT 0x80000000U
#define HIST_RWLOCK_PID_MASK   0x7FFFFFFFU
#define HIST_RWLOCK_WR(pid)    (HIST_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & HIST_RWLOCK_PID_MASK))

/* A zombie (dead but not yet reaped) still answers kill(pid,0) as alive, so a
 * process that crashed while holding the lock and lingers unreaped would never
 * be recovered.  Treat /proc/<pid>/stat state 'Z' as dead.  Linux-only (as is
 * this module); if /proc is unreadable we fall back to "alive" (safe: we never
 * force-recover a possibly-live holder). */
static inline int hist_pid_is_zombie(uint32_t pid) {
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
/* 1 if alive or unknown, 0 if definitely dead.  Cannot detect PID reuse: a
 * recycled PID reports "alive" and the slot is not reclaimed until that
 * process exits.  See "Crash Safety" in the POD. */
static inline int hist_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !hist_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void hist_recover_stale_lock(HistHandle *h, uint32_t observed_wlock) {
    HistHeader *hdr = h->hdr;
    uint32_t mypid = HIST_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec hist_lock_timeout = { HIST_LOCK_TIMEOUT_SEC, 0 };

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void hist_occ_set(HistHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void hist_occ_clear(HistHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

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
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < HIST_READER_SLOTS; i++) {
        uint32_t s = (start + i) % HIST_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            hist_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it. */
    for (uint32_t i = 0; i < HIST_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || hist_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            hist_occ_set(h, i);
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
static inline void hist_recover_after_timeout(HistHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= HIST_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & HIST_RWLOCK_PID_MASK;
        if (!hist_pid_alive(pid))
            hist_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void hist_park(HistHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void hist_unpark(HistHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void hist_rdepth_inc(HistHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void hist_rdepth_dec(HistHandle *h) {
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
static inline void hist_reader_wake_drain(HistHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void hist_rwlock_rdlock(HistHandle *h) {
    hist_claim_reader_slot(h);
    HistHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            hist_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            hist_rdepth_dec(h);
            hist_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= HIST_RWLOCK_WRITER_BIT &&
            !hist_pid_alive(cur & HIST_RWLOCK_PID_MASK)) {
            hist_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < HIST_RWLOCK_SPIN_LIMIT, 1)) {
            hist_rwlock_spin_pause();
            continue;
        }
        hist_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &hist_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                hist_unpark(h);
                hist_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        hist_unpark(h);
        spin = 0;
    }
}

static inline void hist_rwlock_rdunlock(HistHandle *h) {
    hist_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    hist_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void hist_rwlock_wrlock(HistHandle *h) {
    hist_claim_reader_slot(h);  /* refresh cached_pid across fork */
    HistHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = HIST_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= HIST_RWLOCK_WRITER_BIT &&
            !hist_pid_alive(expected & HIST_RWLOCK_PID_MASK)) {
            hist_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < HIST_RWLOCK_SPIN_LIMIT, 1)) {
            hist_rwlock_spin_pause();
            continue;
        }
        hist_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &hist_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                hist_unpark(h);
                hist_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        hist_unpark(h);
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
         * this scan, so no held slot is skipped).  O(HIST_OCC_WORDS + live readers)
         * instead of O(HIST_READER_SLOTS). */
        for (uint32_t w = 0; w < HIST_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!hist_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &hist_lock_timeout, NULL, 0);
    }
}

static inline void hist_rwlock_wrunlock(HistHandle *h) {
    HistHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> counts[counts_len]  (int64_t)
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> counts[]. */
typedef struct { uint64_t reader_slots, occ, counts; } HistLayout;

static inline HistLayout hist_layout(void) {
    HistLayout L;
    L.reader_slots = sizeof(HistHeader);
    L.occ          = L.reader_slots + (uint64_t)HIST_READER_SLOTS * sizeof(HistReaderSlot);
    L.counts       = L.occ + HIST_OCC_BYTES;
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
    /* Publish magic LAST, as a release store: it is the commit point, so a
       creator killed before it leaves magic==0 and never a file mistaken for
       a valid one.  A kill during the field stores leaves one to remove by
       hand. */
    __atomic_store_n(&hdr->magic, HIST_MAGIC, __ATOMIC_RELEASE);
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
    h->reader_slots = (HistReaderSlot *)((uint8_t *)base + sizeof(HistHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + hist_layout().occ);         /* trusted layout offset */
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

/* True iff the whole mapped region is zero -- what an abandoned mid-init
   creator leaves.  Lets recovery re-init only a provably-empty file, never
   one that merely starts with a zero word.  Cold path, so a byte scan is
   fine. */
static inline int hist_region_is_zero(const void *p, size_t n) {
    const unsigned char *b = (const unsigned char *)p;
    for (size_t i = 0; i < n; i++) if (b[i]) return 0;
    return 1;
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
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            HIST_ERR("%s: refusing to initialize file not owned by us", path);
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
                /* Recover an abandoned mid-init file: a creator killed
                 * between the ftruncate and the header init leaves a
                 * full-size, all-zero (magic==0) file that would brick every
                 * future open of this path.  Re-initialize ONLY when it is
                 * exactly our size, still uninitialized, and owned by us;
                 * anything else still errors. */
                if (((HistHeader *)base)->magic == 0 && (uint64_t)st.st_size == total
                    && st.st_uid == geteuid() && hist_region_is_zero(base, map_size)) {
                    if (fchmod(fd, mode) < 0) {
                        HIST_ERR("%s: fchmod: %s", path, strerror(errno));
                        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                    }
                    hist_init_header(base, &g, total);
                    flock(fd, LOCK_UN); close(fd);
                    return hist_setup(base, map_size, path, -1);
                }
                if (((HistHeader *)base)->magic == 0 && (uint64_t)st.st_size == total
                    && st.st_uid == geteuid()) {
                    HIST_ERR("%s: incomplete histogram file left by an interrupted create; remove it and retry", path);
                    munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                }
                HIST_ERR("invalid histogram file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            if (((HistHeader *)base)->sealed) {
                HIST_ERR("%s is frozen (read-only); open it with new_readonly", path);
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
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
    if (((HistHeader *)base)->sealed) {
        HIST_ERR("this histogram is frozen (read-only); open it with new_readonly");
        munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { HIST_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return hist_setup(base, ms, NULL, myfd);
}

static void hist_destroy(HistHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&hist_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        hist_occ_clear(h, h->my_slot_idx);
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

/* Open a FROZEN (sealed) file read-only: O_RDONLY + PROT_READ, no lock ever.
 * A sealed file is immutable and no read path writes the mapping, so queries
 * take no reader-slot / rwlock traffic and any number of processes can share
 * one PROT_READ mapping (same architecture; the magic rejects a wrong-endian
 * file). */
static HistHandle *hist_open_readonly(const char *path, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    int fd = open(path, O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    if (fd < 0) { HIST_ERR("open %s: %s", path, strerror(errno)); return NULL; }
    struct stat st;
    if (fstat(fd, &st) < 0) { HIST_ERR("fstat %s: %s", path, strerror(errno)); close(fd); return NULL; }
    if ((uint64_t)st.st_size < sizeof(HistHeader)) { HIST_ERR("%s: file too small", path); close(fd); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ, MAP_SHARED, fd, 0);
    close(fd);   /* the mapping keeps the file; a read-only view needs no fd (no msync/ftruncate) */
    if (base == MAP_FAILED) { HIST_ERR("mmap %s: %s", path, strerror(errno)); return NULL; }
    if (!hist_validate_header((HistHeader *)base, (uint64_t)st.st_size)) {
        HIST_ERR("%s: invalid histogram file", path); munmap(base, ms); return NULL;
    }
    if (!((HistHeader *)base)->sealed) {
        HIST_ERR("%s is not frozen: call ->freeze on the producer before opening read-only", path);
        munmap(base, ms); return NULL;
    }
    HistHandle *h = hist_setup(base, ms, path, -1);   /* munmaps on OOM */
    if (!h) { HIST_ERR("out of memory"); return NULL; }
    h->readonly = 1;
    return h;
}

/* Seal a histogram: make it permanently immutable so it can be shipped and
 * opened read-only.  Takes the write lock so no record/record_many/merge/
 * reset is in flight, publishes the seal, then flushes it (file/memfd-
 * backed).  Afterwards every mutator croaks and a read-write reopen is
 * refused. */
static int hist_freeze(HistHandle *h) {
    hist_rwlock_wrlock(h);
    h->hdr->sealed = 1;
    hist_rwlock_wrunlock(h);
    if (h->path || h->backing_fd >= 0) return hist_msync(h);  /* durability for file/memfd-backed */
    return 0;   /* anonymous: the seal lives in shared memory (visible to forks); nothing to flush */
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
