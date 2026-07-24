/*
 * ddsketch.h -- Shared-memory DDSketch quantile sketch for Linux
 *
 * Relative-error quantiles: estimates any quantile of a distribution to within a
 * configured relative accuracy alpha, in a fixed amount of memory, using the
 * DDSketch algorithm. Each value falls into a logarithmic bucket key =
 * ceil(log_gamma(|v|)) with gamma = (1+alpha)/(1-alpha), so a bucket's
 * representative value is within alpha of every value it holds; the counts live
 * in a shared mapping so several processes feed one sketch. A write-preferring
 * futex rwlock with reader-slot dead-process recovery guards mutation. Two
 * sketches of the same (alpha, num_buckets) layout merge by an element-wise sum
 * of their bucket counts.
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> neg[num_buckets] -> pos[num_buckets]
 */

#ifndef DD_H
#define DD_H

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
#error "ddsketch.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define DD_MAGIC        0x4B534444  /* DDSketch */
#define DD_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define DD_ERR_BUFLEN   256
#ifndef DD_READER_SLOTS
#define DD_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these DD_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all DD_READER_SLOTS. */
#define DD_OCC_WORDS   (((DD_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define DD_OCC_BYTES   ((uint64_t)DD_OCC_WORDS * 8)      /* 128 bytes */
#define DD_MIN_BUCKETS  8
#define DD_MAX_BUCKETS  0x1000000U    /* 2^24 buckets per store */
#define DD_MIN_ALPHA    1e-6
#define DD_MAX_ALPHA    0.5

#define DD_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, DD_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} DdReaderSlot;

struct DdHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t num_buckets;             /* 8   buckets per store (positive and negative each) */
    uint32_t bias;                    /* 12  slot = key + bias (bias = num_buckets/2) */
    double   gamma;                   /* 16  log base (1+alpha)/(1-alpha) */
    double   inv_ln_gamma;            /* 24  1/ln(gamma), for key = ceil(ln|v| * inv_ln_gamma) */
    double   alpha;                   /* 32  configured relative accuracy */
    uint64_t total_count;             /* 40  total values inserted */
    uint64_t zero_count;              /* 48  count of exact-zero values */
    double   sum;                     /* 56  sum of all values (for mean) */
    double   min_value;               /* 64  smallest value inserted (+inf when empty) */
    double   max_value;               /* 72  largest value inserted (-inf when empty) */
    uint64_t neg_off;                 /* 80  offset of the negative-value store */
    uint64_t pos_off;                 /* 88  offset of the positive-value store */
    uint64_t total_size;              /* 96 */
    uint64_t reader_slots_off;        /* 104 */
    uint32_t wlock;                   /* 112  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 116  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 120  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 128 */
    uint8_t  _pad[120];               /* 136..255 */
};
typedef struct DdHeader DdHeader;

_Static_assert(sizeof(DdHeader) == 256, "DdHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct DdHandle {
    DdHeader     *hdr;
    DdReaderSlot *reader_slots;  /* DD_READER_SLOTS entries */
    uint64_t     *occ;           /* DD_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      neg_off;       /* validated store offsets, cached: never re-read from the peer-writable header */
    uint64_t      pos_off;
    uint32_t      num_buckets;   /* cached */
    uint32_t      bias;          /* cached */
    double        gamma;         /* cached */
    double        inv_ln_gamma;  /* cached */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* dd_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} DdHandle;

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

#define DD_RWLOCK_SPIN_LIMIT 32
#define DD_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void dd_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define DD_RWLOCK_WRITER_BIT 0x80000000U
#define DD_RWLOCK_PID_MASK   0x7FFFFFFFU
#define DD_RWLOCK_WR(pid)    (DD_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & DD_RWLOCK_PID_MASK))

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
static inline int dd_pid_is_zombie(uint32_t pid) {
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
static inline int dd_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !dd_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void dd_recover_stale_lock(DdHandle *h, uint32_t observed_wlock) {
    DdHeader *hdr = h->hdr;
    uint32_t mypid = DD_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec dd_lock_timeout = { DD_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t dd_fork_gen = 1;
static pthread_once_t dd_atfork_once = PTHREAD_ONCE_INIT;
static void dd_on_fork_child(void) {
    __atomic_add_fetch(&dd_fork_gen, 1, __ATOMIC_RELAXED);
}
static void dd_atfork_init(void) {
    pthread_atfork(NULL, NULL, dd_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void dd_occ_set(DdHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void dd_occ_clear(DdHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void dd_claim_reader_slot(DdHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&dd_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&dd_atfork_once, dd_atfork_init);
    /* Re-read after pthread_once: dd_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&dd_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % DD_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < DD_READER_SLOTS; i++) {
        uint32_t s = (start + i) % DD_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            dd_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < DD_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || dd_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            dd_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void dd_recover_after_timeout(DdHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= DD_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & DD_RWLOCK_PID_MASK;
        if (!dd_pid_alive(pid))
            dd_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void dd_park(DdHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void dd_unpark(DdHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void dd_rdepth_inc(DdHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void dd_rdepth_dec(DdHandle *h) {
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
static inline void dd_reader_wake_drain(DdHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void dd_rwlock_rdlock(DdHandle *h) {
    dd_claim_reader_slot(h);
    DdHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            dd_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            dd_rdepth_dec(h);
            dd_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= DD_RWLOCK_WRITER_BIT &&
            !dd_pid_alive(cur & DD_RWLOCK_PID_MASK)) {
            dd_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < DD_RWLOCK_SPIN_LIMIT, 1)) {
            dd_rwlock_spin_pause();
            continue;
        }
        dd_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &dd_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                dd_unpark(h);
                dd_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        dd_unpark(h);
        spin = 0;
    }
}

static inline void dd_rwlock_rdunlock(DdHandle *h) {
    dd_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    dd_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void dd_rwlock_wrlock(DdHandle *h) {
    dd_claim_reader_slot(h);  /* refresh cached_pid across fork */
    DdHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = DD_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= DD_RWLOCK_WRITER_BIT &&
            !dd_pid_alive(expected & DD_RWLOCK_PID_MASK)) {
            dd_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < DD_RWLOCK_SPIN_LIMIT, 1)) {
            dd_rwlock_spin_pause();
            continue;
        }
        dd_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &dd_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                dd_unpark(h);
                dd_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        dd_unpark(h);
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
         * this scan, so no held slot is skipped).  O(DD_OCC_WORDS + live readers)
         * instead of O(DD_READER_SLOTS). */
        for (uint32_t w = 0; w < DD_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!dd_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &dd_lock_timeout, NULL, 0);
    }
}

static inline void dd_rwlock_wrunlock(DdHandle *h) {
    DdHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> neg[num_buckets] -> pos[num_buckets]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets.
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> neg[num_buckets] -> pos[num_buckets] */
typedef struct { uint64_t reader_slots, occ, neg, pos, total; } DdLayout;

static inline DdLayout dd_layout_for(uint32_t num_buckets) {
    DdLayout L;
    L.reader_slots = sizeof(DdHeader);
    L.occ          = L.reader_slots + (uint64_t)DD_READER_SLOTS * sizeof(DdReaderSlot);
    L.neg          = L.occ + DD_OCC_BYTES;
    L.neg          = (L.neg + 7) & ~(uint64_t)7;   /* 8-byte align the count arrays */
    L.pos          = L.neg + (uint64_t)num_buckets * sizeof(uint64_t);
    L.total        = L.pos + (uint64_t)num_buckets * sizeof(uint64_t);
    return L;
}

static inline uint64_t dd_total_size(uint32_t num_buckets) {
    return dd_layout_for(num_buckets).total;
}

static inline void dd_init_header(void *base, uint32_t num_buckets, double alpha, uint64_t total) {
    DdLayout L = dd_layout_for(num_buckets);
    DdHeader *hdr = (DdHeader *)base;
    memset(base, 0, (size_t)L.total);   /* zero header + reader slots + both count stores */
    double gamma = (1.0 + alpha) / (1.0 - alpha);
    hdr->magic            = DD_MAGIC;
    hdr->version          = DD_VERSION;
    hdr->num_buckets      = num_buckets;
    hdr->bias             = num_buckets / 2;
    hdr->gamma            = gamma;
    hdr->inv_ln_gamma     = 1.0 / log(gamma);
    hdr->alpha            = alpha;
    hdr->total_count      = 0;
    hdr->zero_count       = 0;
    hdr->sum              = 0.0;
    hdr->min_value        = INFINITY;
    hdr->max_value        = -INFINITY;
    hdr->neg_off          = L.neg;
    hdr->pos_off          = L.pos;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint64_t *dd_neg(DdHandle *h) { return (uint64_t *)((char *)h->base + h->neg_off); }
static inline uint64_t *dd_pos(DdHandle *h) { return (uint64_t *)((char *)h->base + h->pos_off); }

/* Layer B trusted bound: the number of bucket counters guaranteed to lie within
 * the real mapping for the store at `off`.  Derived from the process-local
 * mmap_size (fixed at attach, not peer-writable) and the SAME cached offset the
 * accessors use, so a corrupt hdr->num_buckets can never drive a store access
 * outside the mapping.  Equals num_buckets for a valid sketch. */
static inline uint64_t dd_store_max(DdHandle *h, uint64_t off) {
    if (off >= h->mmap_size) return 0;
    return (h->mmap_size - off) / sizeof(uint64_t);
}

static inline DdHandle *dd_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    DdHeader *hdr = (DdHeader *)base;
    DdHandle *h = (DdHandle *)calloc(1, sizeof(DdHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (DdReaderSlot *)((uint8_t *)base + sizeof(DdHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + dd_layout_for(0).occ);  /* trusted layout offset (occ offset is num_buckets-independent) */
    /* single validated read of each geometry field; cached so the bound and the
       pointers/arithmetic it feeds stay consistent even under later peer corruption */
    h->neg_off      = hdr->neg_off;
    h->pos_off      = hdr->pos_off;
    h->num_buckets  = hdr->num_buckets;
    h->bias         = hdr->bias;
    /* Derive gamma / inv_ln_gamma from the validated alpha rather than trusting
       the stored copies: validate_header bounds alpha to [DD_MIN_ALPHA,
       DD_MAX_ALPHA], so these are always finite and in range, whereas a corrupt
       stored inv_ln_gamma (NaN/wild) would make the key computation's double->
       int64 cast undefined behaviour. */
    h->gamma        = (1.0 + hdr->alpha) / (1.0 - hdr->alpha);
    h->inv_ln_gamma = 1.0 / log(h->gamma);
    h->mmap_size    = map_size;
    /* Layer B: if the mapping cannot hold `num_buckets` in each store, clamp the
       cached count to what actually fits (pos is the last, tightest region). */
    {
        uint64_t nfit = dd_store_max(h, h->neg_off);
        uint64_t pfit = dd_store_max(h, h->pos_off);
        uint64_t fit  = nfit < pfit ? nfit : pfit;
        if ((uint64_t)h->num_buckets > fit) h->num_buckets = (uint32_t)fit;
    }
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by dd_create reopen and dd_open_fd). */
static inline int dd_validate_header(const DdHeader *hdr, uint64_t file_size) {
    if (hdr->magic != DD_MAGIC) return 0;
    if (hdr->version != DD_VERSION) return 0;
    if (hdr->num_buckets < DD_MIN_BUCKETS || hdr->num_buckets > DD_MAX_BUCKETS) return 0;
    if (hdr->bias != hdr->num_buckets / 2) return 0;
    if (!(hdr->alpha >= DD_MIN_ALPHA && hdr->alpha <= DD_MAX_ALPHA)) return 0;  /* same bounds as create; rejects NaN */
    if (!(hdr->gamma > 1.0)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != dd_total_size(hdr->num_buckets)) return 0;
    DdLayout L = dd_layout_for(hdr->num_buckets);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->neg_off != L.neg) return 0;
    if (hdr->pos_off != L.pos) return 0;
    return 1;
}

/* validate the requested relative accuracy + bucket count */
static int dd_validate_args(double alpha, uint64_t num_buckets, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (!(alpha >= DD_MIN_ALPHA && alpha <= DD_MAX_ALPHA))
        { DD_ERR("alpha (relative accuracy) must be between 1e-6 and 0.5"); return 0; }
    if (num_buckets < DD_MIN_BUCKETS || num_buckets > DD_MAX_BUCKETS)
        { DD_ERR("num_buckets must be between 8 and 2^24"); return 0; }
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via dd_validate_header. */
static int dd_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { DD_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        DD_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    DD_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static DdHandle *dd_create(const char *path, double alpha, uint64_t num_buckets, mode_t mode, char *errbuf) {
    if (!dd_validate_args(alpha, num_buckets, errbuf)) return NULL;

    uint64_t total = dd_total_size((uint32_t)num_buckets);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { DD_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = dd_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { DD_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { DD_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(DdHeader)) {
            DD_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            DD_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            DD_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { DD_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!dd_validate_header((DdHeader *)base, (uint64_t)st.st_size)) {
                DD_ERR("invalid DDSketch file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return dd_setup(base, map_size, path, -1);
        }
    }
    dd_init_header(base, (uint32_t)num_buckets, alpha, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return dd_setup(base, map_size, path, -1);
}

static DdHandle *dd_create_memfd(const char *name, double alpha, uint64_t num_buckets, char *errbuf) {
    if (!dd_validate_args(alpha, num_buckets, errbuf)) return NULL;

    uint64_t total = dd_total_size((uint32_t)num_buckets);
    int fd = memfd_create(name ? name : "ddsketch", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { DD_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        DD_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { DD_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    dd_init_header(base, (uint32_t)num_buckets, alpha, total);
    return dd_setup(base, (size_t)total, NULL, fd);
}

static DdHandle *dd_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { DD_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(DdHeader)) { DD_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { DD_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!dd_validate_header((DdHeader *)base, (uint64_t)st.st_size)) {
        DD_ERR("invalid DDSketch table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { DD_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return dd_setup(base, ms, NULL, myfd);
}

static void dd_destroy(DdHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&dd_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        dd_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int dd_msync(DdHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * DDSketch operations (callers hold the lock)
 *
 * A value v != 0 maps to a logarithmic bucket key = ceil(log_gamma(|v|)); each
 * bucket [gamma^(k-1), gamma^k) collects a count, so a bucket's representative
 * value is within relative error alpha of every value it holds.  Positive and
 * negative magnitudes use separate stores; exact zeros use a dedicated counter.
 * The bucket key is mapped to a fixed centred window slot = key + bias (bias =
 * num_buckets/2); keys past either end collapse into the extreme bucket, which
 * bounds memory while keeping every sketch of the same (alpha, num_buckets)
 * layout mergeable by a plain element-wise sum.
 * ================================================================ */

/* representative value of positive bucket key k: 2*gamma^k/(gamma+1), the value
 * whose relative distance to every point in the bucket is at most alpha */
static inline double dd_value_of_key(DdHandle *h, int64_t key) {
    return 2.0 * pow(h->gamma, (double)key) / (h->gamma + 1.0);
}

/* map a bucket key to a store slot in the fixed centred window, collapsing keys
 * past either end into the extreme bucket. */
static inline uint64_t dd_slot_of_key(DdHandle *h, int64_t key) {
    int64_t s = key + (int64_t)h->bias;
    if (s < 0) return 0;
    if ((uint64_t)s >= (uint64_t)h->num_buckets) return h->num_buckets ? h->num_buckets - 1 : 0;
    return (uint64_t)s;
}

/* insert one finite value (caller holds the write lock; caller has rejected NaN/Inf) */
static void dd_insert_locked(DdHandle *h, double v, uint64_t count) {
    DdHeader *hdr = h->hdr;
    hdr->total_count += count;
    hdr->sum += v * (double)count;
    if (v < hdr->min_value) hdr->min_value = v;
    if (v > hdr->max_value) hdr->max_value = v;
    if (v == 0.0) { hdr->zero_count += count; return; }
    if (h->num_buckets == 0) return;                         /* Layer B: unusable mapping */
    double mag = v > 0 ? v : -v;
    int64_t key = (int64_t)ceil(log(mag) * h->inv_ln_gamma);
    uint64_t slot = dd_slot_of_key(h, key);
    uint64_t *store = (v > 0) ? dd_pos(h) : dd_neg(h);
    store[slot] += count;
}

/* value at 0-based rank `rank` (typically q*(count-1)), walking buckets from
 * most-negative to most-positive; *found set to 1 when a bucket is returned.
 * (caller holds a lock) */
static double dd_value_at_rank(DdHandle *h, double rank, int *found) {
    uint64_t nb = h->num_buckets;
    uint64_t cum = 0;
    *found = 1;
    /* negative store: larger key = more negative value, so walk high slot -> low */
    uint64_t *neg = dd_neg(h);
    for (uint64_t i = nb; i-- > 0; ) {
        cum += neg[i];
        if ((double)cum > rank) {
            int64_t key = (int64_t)i - (int64_t)h->bias;
            return -dd_value_of_key(h, key);
        }
    }
    /* exact zeros */
    cum += h->hdr->zero_count;
    if ((double)cum > rank) return 0.0;
    /* positive store: low slot -> high */
    uint64_t *pos = dd_pos(h);
    for (uint64_t i = 0; i < nb; i++) {
        cum += pos[i];
        if ((double)cum > rank) {
            int64_t key = (int64_t)i - (int64_t)h->bias;
            return dd_value_of_key(h, key);
        }
    }
    *found = 0;                                              /* rank beyond total (empty) */
    return 0.0;
}

/* merge another sketch's stores into this one (caller guarantees equal geometry).
 * src_neg/src_pos are snapshots of length src_nb. */
static void dd_merge_locked(DdHandle *dst, const uint64_t *src_neg, const uint64_t *src_pos,
                            uint64_t src_nb, uint64_t src_total, uint64_t src_zero,
                            double src_sum, double src_min, double src_max) {
    uint64_t nb = dst->num_buckets;
    if (nb > src_nb) nb = src_nb;                            /* Layer B: clamp to both buffers */
    uint64_t *neg = dd_neg(dst), *pos = dd_pos(dst);
    for (uint64_t i = 0; i < nb; i++) { neg[i] += src_neg[i]; pos[i] += src_pos[i]; }
    dst->hdr->total_count += src_total;
    dst->hdr->zero_count  += src_zero;
    dst->hdr->sum         += src_sum;
    if (src_min < dst->hdr->min_value) dst->hdr->min_value = src_min;
    if (src_max > dst->hdr->max_value) dst->hdr->max_value = src_max;
}

/* reset to an empty sketch (caller holds the write lock) */
static inline void dd_clear_locked(DdHandle *h) {
    DdHeader *hdr = h->hdr;
    uint64_t nb = h->num_buckets;
    uint64_t nfit = dd_store_max(h, h->neg_off);            /* Layer B: clamp memset to the mapping */
    uint64_t pfit = dd_store_max(h, h->pos_off);
    memset(dd_neg(h), 0, (size_t)((nb < nfit ? nb : nfit) * sizeof(uint64_t)));
    memset(dd_pos(h), 0, (size_t)((nb < pfit ? nb : pfit) * sizeof(uint64_t)));
    hdr->total_count = 0;
    hdr->zero_count  = 0;
    hdr->sum         = 0.0;
    hdr->min_value   = INFINITY;
    hdr->max_value   = -INFINITY;
}

#endif /* DD_H */
