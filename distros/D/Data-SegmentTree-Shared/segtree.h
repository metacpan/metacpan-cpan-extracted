/*
 * segtree.h -- Shared-memory segment tree for Linux
 *
 * Range queries with range updates over a fixed array of n signed-integer
 * positions: add a delta to every element of a range in O(log n), and query the
 * sum, minimum, or maximum of any range in O(log n).  A perfect binary tree with
 * lazy propagation carries each node's sum/min/max plus a pending range-add; the
 * tree lives in a shared mapping so several processes update and query one array.
 * A write-preferring futex rwlock with reader-slot dead-process recovery guards
 * mutation; queries never mutate, so they take only the read lock.
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> nodes[2*next_pow2(n)]
 */

#ifndef ST_H
#define ST_H

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
#error "segtree.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define ST_MAGIC        0x54474553  /* SegmentTree */
#define ST_VERSION      3            /* 3: added the occupancy bitmap region (layout change) */
#define ST_ERR_BUFLEN   256
#ifndef ST_READER_SLOTS
#define ST_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these ST_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all ST_READER_SLOTS. */
#define ST_OCC_WORDS    (((ST_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define ST_OCC_BYTES    ((uint64_t)ST_OCC_WORDS * 8)      /* 128 bytes */
#define ST_MIN_N        1
#define ST_MAX_N        0x1000000ULL     /* 2^24 positions cap */
#define ST_IDENTITY_MIN INT64_MAX        /* min identity (padding leaves / empty range) */
#define ST_IDENTITY_MAX INT64_MIN        /* max identity */

/* StNode.flags bits (weighted with the assign lazy + product-overflow marker) */
#define ST_F_HAS_ASSIGN 0x1U             /* node has a pending range-assign (lazy) */
#define ST_F_PROD_OVF   0x2U             /* node's product overflowed int64 (unusable) */

#define ST_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, ST_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} StReaderSlot;

struct StHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t add_used;                /* 8  set once any range_add runs -> gcd/product gated off */
    uint32_t _pad1;                   /* 12 */
    uint64_t n;                       /* 16  number of positions (leaves in use) */
    uint64_t size;                    /* 24  next_pow2(n): leaves in the padded tree */
    uint64_t nodes_off;               /* 32  offset of the node array (2*size StNodes) */
    uint64_t total_size;              /* 40 */
    uint64_t reader_slots_off;        /* 48 */
    uint32_t wlock;                   /* 56  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 60  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 64  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;   /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 72 */
    uint8_t  _pad[176];               /* 80..255 */
};
typedef struct StHeader StHeader;

_Static_assert(sizeof(StHeader) == 256, "StHeader must be 256 bytes");

/* One segment-tree node: the sum/min/max/gcd/product aggregate of its covered
 * range, plus pending lazies -- a "range add" delta (lazy) and/or a "range
 * assign" value (assign, active when flags has ST_F_HAS_ASSIGN).  A node's own
 * aggregate already includes its own lazies; only its children are stale by them.
 * gcd/product are exact only while no range_add has ever run (see add_used); an
 * assigned node stores product as c^cnt, or sets ST_F_PROD_OVF if that overflows. */
typedef struct {
    int64_t  sum;
    int64_t  min;
    int64_t  max;
    int64_t  gcd;      /* gcd of |values| in the range (0 identity); valid iff !add_used */
    int64_t  prod;     /* product of the range (1 identity); unusable if ST_F_PROD_OVF */
    int64_t  lazy;     /* pending range-add delta (used only when !ST_F_HAS_ASSIGN) */
    int64_t  assign;   /* pending range-assign value (used when ST_F_HAS_ASSIGN) */
    uint64_t flags;    /* ST_F_HAS_ASSIGN | ST_F_PROD_OVF */
} StNode;
_Static_assert(sizeof(StNode) == 64, "StNode must be 64 bytes");

/* ---- Process-local handle ---- */

typedef struct StHandle {
    StHeader     *hdr;
    StReaderSlot *reader_slots;  /* ST_READER_SLOTS entries */
    uint64_t     *occ;           /* ST_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      nodes_off;     /* validated, cached: never re-read from the peer-writable header */
    uint64_t      n;             /* cached number of positions */
    uint64_t      size;          /* cached next_pow2(n) */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* st_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} StHandle;

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

#define ST_RWLOCK_SPIN_LIMIT 32
#define ST_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void st_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define ST_RWLOCK_WRITER_BIT 0x80000000U
#define ST_RWLOCK_PID_MASK   0x7FFFFFFFU
#define ST_RWLOCK_WR(pid)    (ST_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & ST_RWLOCK_PID_MASK))

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
static inline int st_pid_is_zombie(uint32_t pid) {
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
static inline int st_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !st_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void st_recover_stale_lock(StHandle *h, uint32_t observed_wlock) {
    StHeader *hdr = h->hdr;
    uint32_t mypid = ST_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec st_lock_timeout = { ST_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t st_fork_gen = 1;
static pthread_once_t st_atfork_once = PTHREAD_ONCE_INIT;
static void st_on_fork_child(void) {
    __atomic_add_fetch(&st_fork_gen, 1, __ATOMIC_RELAXED);
}
static void st_atfork_init(void) {
    pthread_atfork(NULL, NULL, st_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void st_occ_set(StHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void st_occ_clear(StHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so that
 * fork()'d children pick up their own slot lazily instead of sharing the
 * parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void st_claim_reader_slot(StHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&st_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&st_atfork_once, st_atfork_init);
    /* Re-read after pthread_once: st_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&st_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % ST_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < ST_READER_SLOTS; i++) {
        uint32_t s = (start + i) % ST_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            st_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < ST_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || st_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            st_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void st_recover_after_timeout(StHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= ST_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & ST_RWLOCK_PID_MASK;
        if (!st_pid_alive(pid))
            st_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void st_park(StHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void st_unpark(StHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void st_rdepth_inc(StHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void st_rdepth_dec(StHandle *h) {
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
static inline void st_reader_wake_drain(StHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void st_rwlock_rdlock(StHandle *h) {
    st_claim_reader_slot(h);
    StHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            st_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            st_rdepth_dec(h);
            st_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= ST_RWLOCK_WRITER_BIT &&
            !st_pid_alive(cur & ST_RWLOCK_PID_MASK)) {
            st_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < ST_RWLOCK_SPIN_LIMIT, 1)) {
            st_rwlock_spin_pause();
            continue;
        }
        st_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &st_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                st_unpark(h);
                st_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        st_unpark(h);
        spin = 0;
    }
}

static inline void st_rwlock_rdunlock(StHandle *h) {
    st_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    st_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void st_rwlock_wrlock(StHandle *h) {
    st_claim_reader_slot(h);  /* refresh cached_pid across fork */
    StHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = ST_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= ST_RWLOCK_WRITER_BIT &&
            !st_pid_alive(expected & ST_RWLOCK_PID_MASK)) {
            st_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < ST_RWLOCK_SPIN_LIMIT, 1)) {
            st_rwlock_spin_pause();
            continue;
        }
        st_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &st_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                st_unpark(h);
                st_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        st_unpark(h);
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
         * this scan, so no held slot is skipped).  O(ST_OCC_WORDS + live readers)
         * instead of O(ST_READER_SLOTS). */
        for (uint32_t w = 0; w < ST_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!st_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &st_lock_timeout, NULL, 0);
    }
}

static inline void st_rwlock_wrunlock(StHandle *h) {
    StHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> nodes[2*next_pow2(n)]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets.
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> nodes[2*size] (1-indexed, node 0 unused) */
typedef struct { uint64_t reader_slots, occ, nodes, total; } StLayout;

/* round v up to the next power of two (64-bit), with a floor of 1 */
static inline uint64_t st_next_pow2_u64(uint64_t v) {
    if (v <= 1) return 1;
    return 1ULL << (64 - __builtin_clzll(v - 1));
}

static inline StLayout st_layout_for(uint64_t size) {
    StLayout L;
    L.reader_slots = sizeof(StHeader);
    L.occ          = L.reader_slots + (uint64_t)ST_READER_SLOTS * sizeof(StReaderSlot);
    L.nodes        = L.occ + ST_OCC_BYTES;
    L.nodes        = (L.nodes + 7) & ~(uint64_t)7;
    L.total        = L.nodes + 2ULL * size * sizeof(StNode);   /* nodes 0 .. 2*size-1 */
    return L;
}

static inline uint64_t st_total_size(uint64_t size) {
    return st_layout_for(size).total;
}

static inline void st_init_header(void *base, uint64_t n, uint64_t size, uint64_t total) {
    StLayout L = st_layout_for(size);
    StHeader *hdr = (StHeader *)base;
    /* Zero the whole region: every node's sum/min/max/lazy = 0, so all n
       positions read as 0.  Padding leaves (n..size-1) stay 0 too -- no query
       ever covers a padding-containing node (queries clamp to [0, n-1]), so
       their aggregates never surface. */
    memset(base, 0, (size_t)L.total);
    hdr->magic            = ST_MAGIC;
    hdr->version          = ST_VERSION;
    hdr->n                = n;
    hdr->size             = size;
    hdr->nodes_off        = L.nodes;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline StNode *st_nodes(StHandle *h) {
    return (StNode *)((char *)h->base + h->nodes_off);
}

/* Layer B trusted bound: the number of nodes guaranteed to lie within the real
 * mapping.  Derived from the process-local mmap_size (fixed at attach, not
 * peer-writable) and the SAME nodes_off the accessor uses, so a corrupt
 * hdr->size can never drive a node access outside the mapping.  Equals 2*size
 * for a valid tree. */
static inline uint64_t st_nodes_max(StHandle *h) {
    if (h->nodes_off >= h->mmap_size) return 0;
    return (h->mmap_size - h->nodes_off) / sizeof(StNode);
}

static inline StHandle *st_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    StHeader *hdr = (StHeader *)base;
    StHandle *h = (StHandle *)calloc(1, sizeof(StHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (StReaderSlot *)((uint8_t *)base + sizeof(StHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + st_layout_for(0).occ);  /* trusted layout offset (occ offset is size-independent, not from peer-writable header) */
    /* single validated read of each geometry field, cached process-locally */
    h->nodes_off    = hdr->nodes_off;
    h->n            = hdr->n;
    h->size         = hdr->size;
    h->mmap_size    = map_size;
    /* Layer B: if the mapping cannot hold 2*size nodes the header lied about its
       size; clamp the cached tree size to what actually fits. */
    {
        uint64_t fit = st_nodes_max(h) / 2;
        if (h->size > fit) { h->size = fit; if (h->n > h->size) h->n = h->size; }
    }
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by st_create reopen and st_open_fd). */
static inline int st_validate_header(const StHeader *hdr, uint64_t file_size) {
    if (hdr->magic != ST_MAGIC) return 0;
    if (hdr->version != ST_VERSION) return 0;
    if (__atomic_load_n(&hdr->add_used, __ATOMIC_RELAXED) > 1) return 0;
    if (hdr->n < ST_MIN_N || hdr->n > ST_MAX_N) return 0;
    if (hdr->size != st_next_pow2_u64(hdr->n)) return 0;
    if (hdr->size == 0 || (hdr->size & (hdr->size - 1)) != 0) return 0;   /* power of two */
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != st_total_size(hdr->size)) return 0;
    StLayout L = st_layout_for(hdr->size);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->nodes_off != L.nodes) return 0;
    return 1;
}

/* validate the requested number of positions n */
static int st_validate_args(uint64_t n, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (n < ST_MIN_N || n > ST_MAX_N) { ST_ERR("number of positions must be between 1 and 2^24"); return 0; }
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via st_validate_header. */
static int st_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { ST_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        ST_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    ST_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static StHandle *st_create(const char *path, uint64_t n, mode_t mode, char *errbuf) {
    if (!st_validate_args(n, errbuf)) return NULL;

    uint64_t size = st_next_pow2_u64(n);
    uint64_t total = st_total_size(size);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { ST_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = st_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { ST_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { ST_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(StHeader)) {
            ST_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            ST_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            ST_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { ST_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!st_validate_header((StHeader *)base, (uint64_t)st.st_size)) {
                ST_ERR("invalid segment-tree file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return st_setup(base, map_size, path, -1);
        }
    }
    st_init_header(base, n, size, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return st_setup(base, map_size, path, -1);
}

static StHandle *st_create_memfd(const char *name, uint64_t n, char *errbuf) {
    if (!st_validate_args(n, errbuf)) return NULL;

    uint64_t size = st_next_pow2_u64(n);
    uint64_t total = st_total_size(size);
    int fd = memfd_create(name ? name : "segtree", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { ST_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        ST_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { ST_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    st_init_header(base, n, size, total);
    return st_setup(base, (size_t)total, NULL, fd);
}

static StHandle *st_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { ST_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(StHeader)) { ST_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { ST_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!st_validate_header((StHeader *)base, (uint64_t)st.st_size)) {
        ST_ERR("invalid segment-tree table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { ST_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return st_setup(base, ms, NULL, myfd);
}

static void st_destroy(StHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&st_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        st_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int st_msync(StHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Segment-tree operations (callers hold the lock)
 *
 * A perfect binary tree over `size` = next_pow2(n) leaves; node 1 is the root
 * covering [0, size-1], node v has children 2v and 2v+1.  Positions n..size-1
 * are padding leaves that no query ever covers (queries are clamped to
 * [0, n-1]).  Each node keeps its subtree's sum/min/max plus a pending "range
 * add" delta (lazy) already reflected in its own aggregate but not yet in its
 * children's.  Range-add pushes lazy down on the way to recompute; queries never
 * mutate -- they carry the ancestors' un-pushed lazy as `pending` and shift each
 * covered node's aggregate by it.  All node indices come from the recursion
 * (never from shared memory), so the st_setup size-clamp alone keeps every access
 * inside the mapping.
 * ================================================================ */

/* gcd of |a|,|b| (INT64_MIN-safe); 0 is the identity, so gcd(0,x) == |x| */
static inline int64_t st_gcd2(int64_t a, int64_t b) {
    uint64_t x = a < 0 ? (uint64_t)(-(a + 1)) + 1 : (uint64_t)a;
    uint64_t y = b < 0 ? (uint64_t)(-(b + 1)) + 1 : (uint64_t)b;
    while (y) { uint64_t t = x % y; x = y; y = t; }
    return (int64_t)x;                          /* |gcd| <= max(|a|,|b|) <= INT64_MAX+1; fits when a|b != 0 */
}
/* base^exp with signed-overflow detection; returns 1 on overflow, else 0 with *out set */
static inline int st_ipow_ovf(int64_t base, uint64_t exp, int64_t *out) {
    int64_t result = 1, b = base;
    while (exp) {
        if (exp & 1) { if (__builtin_mul_overflow(result, b, &result)) return 1; }
        exp >>= 1;
        if (exp) { if (__builtin_mul_overflow(b, b, &b)) return 1; }
    }
    *out = result;
    return 0;
}
/* recompute node nd's product/overflow flag from children a,b.  A range holds a
 * zero exactly when prod==0 && !PROD_OVF (on overflow prod is zeroed but flagged);
 * a zero collapses the parent product to 0 regardless of a sibling's overflow. */
static inline void st_combine_prod(StNode *nd, const StNode *a, const StNode *b) {
    int azero = !(a->flags & ST_F_PROD_OVF) && a->prod == 0;
    int bzero = !(b->flags & ST_F_PROD_OVF) && b->prod == 0;
    if (azero || bzero) { nd->prod = 0; nd->flags &= ~ST_F_PROD_OVF; return; }
    if ((a->flags & ST_F_PROD_OVF) || (b->flags & ST_F_PROD_OVF) ||
        __builtin_mul_overflow(a->prod, b->prod, &nd->prod)) {
        nd->flags |= ST_F_PROD_OVF;
        nd->prod   = 0;
    } else {
        nd->flags &= ~ST_F_PROD_OVF;
    }
}

/* apply a pending range-add of +delta to a node covering `cnt` leaves.  Maintains
 * sum/min/max only; gcd/product are not add-maintainable (gated by add_used). */
static inline void st_apply_add(StNode *nd, int64_t delta, uint64_t cnt) {
    nd->sum += delta * (int64_t)cnt;
    nd->min += delta;
    nd->max += delta;
    if (nd->flags & ST_F_HAS_ASSIGN) nd->assign += delta;   /* fold into the pending assign */
    else                             nd->lazy   += delta;
}

/* apply a pending range-assign of value `c` to a node covering `cnt` leaves --
 * a uniform range, so every aggregate is exact. */
static inline void st_apply_assign(StNode *nd, int64_t c, uint64_t cnt) {
    nd->sum    = c * (int64_t)cnt;
    nd->min    = c;
    nd->max    = c;
    nd->gcd    = st_gcd2(c, 0);                 /* |c| */
    nd->lazy   = 0;
    nd->assign = c;
    nd->flags  = (nd->flags & ~ST_F_PROD_OVF) | ST_F_HAS_ASSIGN;
    { int64_t p; if (st_ipow_ovf(c, cnt, &p)) nd->flags |= ST_F_PROD_OVF; else nd->prod = p; }
}

/* push node v's pending lazy (assign or add) down to both children */
static inline void st_pushdown(StNode *nodes, uint64_t v, uint64_t lcnt, uint64_t rcnt) {
    StNode *nd = &nodes[v];
    if (nd->flags & ST_F_HAS_ASSIGN) {
        st_apply_assign(&nodes[2*v],     nd->assign, lcnt);
        st_apply_assign(&nodes[2*v + 1], nd->assign, rcnt);
        nd->flags &= ~ST_F_HAS_ASSIGN;
        nd->assign = 0;
    } else if (nd->lazy) {
        st_apply_add(&nodes[2*v],     nd->lazy, lcnt);
        st_apply_add(&nodes[2*v + 1], nd->lazy, rcnt);
        nd->lazy = 0;
    }
}

/* recompute node v's aggregate from its two (freshly updated) children */
static inline void st_pull(StNode *nodes, uint64_t v) {
    StNode *nd = &nodes[v], *a = &nodes[2*v], *b = &nodes[2*v + 1];
    nd->sum = a->sum + b->sum;
    nd->min = a->min < b->min ? a->min : b->min;
    nd->max = a->max > b->max ? a->max : b->max;
    nd->gcd = st_gcd2(a->gcd, b->gcd);
    st_combine_prod(nd, a, b);
}

/* range-add delta to [l,r] within node v covering [lo,hi] (caller holds wrlock) */
static void st_range_add_rec(StNode *nodes, uint64_t v, uint64_t lo, uint64_t hi,
                             uint64_t l, uint64_t r, int64_t delta) {
    if (r < lo || hi < l) return;                              /* disjoint */
    if (l <= lo && hi <= r) { st_apply_add(&nodes[v], delta, hi - lo + 1); return; }
    uint64_t mid = lo + (hi - lo) / 2;
    st_pushdown(nodes, v, mid - lo + 1, hi - mid);
    st_range_add_rec(nodes, 2*v,     lo,      mid, l, r, delta);
    st_range_add_rec(nodes, 2*v + 1, mid + 1, hi,  l, r, delta);
    st_pull(nodes, v);
}

/* range-assign value c to [l,r] within node v covering [lo,hi] (caller holds wrlock) */
static void st_range_assign_rec(StNode *nodes, uint64_t v, uint64_t lo, uint64_t hi,
                                uint64_t l, uint64_t r, int64_t c) {
    if (r < lo || hi < l) return;                              /* disjoint */
    if (l <= lo && hi <= r) { st_apply_assign(&nodes[v], c, hi - lo + 1); return; }
    uint64_t mid = lo + (hi - lo) / 2;
    st_pushdown(nodes, v, mid - lo + 1, hi - mid);
    st_range_assign_rec(nodes, 2*v,     lo,      mid, l, r, c);
    st_range_assign_rec(nodes, 2*v + 1, mid + 1, hi,  l, r, c);
    st_pull(nodes, v);
}

/* Read-only query carry.  Applying a covered node's stored aggregate under the
 * ancestors' un-pushed lazies gives value = (asg ? av : stored) + ad.  A node's
 * un-pushed lazy applies to its children, so SHALLOWER lazies are applied LATER
 * (outermost): the SHALLOWEST assign on the path wins (av), adds ABOVE it still
 * apply on top (ad), and everything DEEPER than that assign is wiped by it.
 * Hence: adopt an assign / accumulate an add only while no assign has been seen. */
typedef struct { int asg; int64_t av; int64_t ad; } StCarry;

static inline StCarry st_carry_descend(StCarry c, const StNode *nd) {
    if (c.asg) return c;                                          /* outer assign already fixed the value */
    if (nd->flags & ST_F_HAS_ASSIGN) { c.asg = 1; c.av = nd->assign; }
    else if (nd->lazy)               { c.ad += nd->lazy; }
    return c;
}

/* accumulate sum/min/max over [l,r] (read-only; caller holds a lock) */
static void st_query_rec(StNode *nodes, uint64_t v, uint64_t lo, uint64_t hi,
                         uint64_t l, uint64_t r, StCarry c,
                         int64_t *sum, int64_t *mn, int64_t *mx) {
    if (r < lo || hi < l) return;                             /* disjoint -> identity */
    if (l <= lo && hi <= r) {                                 /* covered */
        uint64_t cnt = hi - lo + 1;
        int64_t s, nmin, nmax;
        if (c.asg) { int64_t val = c.av + c.ad; s = val * (int64_t)cnt; nmin = nmax = val; }
        else       { s = nodes[v].sum + c.ad * (int64_t)cnt;
                     nmin = nodes[v].min + c.ad; nmax = nodes[v].max + c.ad; }
        *sum += s;
        if (nmin < *mn) *mn = nmin;
        if (nmax > *mx) *mx = nmax;
        return;
    }
    uint64_t mid = lo + (hi - lo) / 2;
    StCarry cc = st_carry_descend(c, &nodes[v]);
    st_query_rec(nodes, 2*v,     lo,      mid, l, r, cc, sum, mn, mx);
    st_query_rec(nodes, 2*v + 1, mid + 1, hi,  l, r, cc, sum, mn, mx);
}

/* accumulate gcd over [l,r] into *g (read-only; only called with add_used == 0,
 * so no add lazy exists and the carry is assign-only) */
static void st_gcd_rec(StNode *nodes, uint64_t v, uint64_t lo, uint64_t hi,
                       uint64_t l, uint64_t r, StCarry c, int64_t *g) {
    if (r < lo || hi < l) return;
    if (l <= lo && hi <= r) {
        int64_t ng = c.asg ? st_gcd2(c.av, 0) : nodes[v].gcd;
        *g = st_gcd2(*g, ng);
        return;
    }
    uint64_t mid = lo + (hi - lo) / 2;
    StCarry cc = st_carry_descend(c, &nodes[v]);
    st_gcd_rec(nodes, 2*v,     lo,      mid, l, r, cc, g);
    st_gcd_rec(nodes, 2*v + 1, mid + 1, hi,  l, r, cc, g);
}

/* multiply product over [l,r] into *p.  Sets *hasz if the range contains a zero
 * (then the product is 0, whatever any sibling overflow says) and *ovf on a real
 * int64 overflow with no zero.  Does NOT short-circuit on *ovf -- a later zero
 * must still be able to force the result to 0. */
static void st_prod_rec(StNode *nodes, uint64_t v, uint64_t lo, uint64_t hi,
                        uint64_t l, uint64_t r, StCarry c, int64_t *p, int *ovf, int *hasz) {
    if (*hasz || r < lo || hi < l) return;    /* a zero already forces the product to 0 */
    if (l <= lo && hi <= r) {                  /* covered */
        int64_t np;
        if (c.asg) {
            if (c.av == 0) { *hasz = 1; return; }               /* assigned zero -> product 0 */
            if (st_ipow_ovf(c.av, hi - lo + 1, &np)) { *ovf = 1; return; }
        } else {
            const StNode *nd = &nodes[v];
            if (!(nd->flags & ST_F_PROD_OVF) && nd->prod == 0) { *hasz = 1; return; }  /* range has a zero */
            if (nd->flags & ST_F_PROD_OVF) { *ovf = 1; return; }
            np = nd->prod;
        }
        if (__builtin_mul_overflow(*p, np, p)) *ovf = 1;
        return;
    }
    uint64_t mid = lo + (hi - lo) / 2;
    StCarry cc = st_carry_descend(c, &nodes[v]);
    st_prod_rec(nodes, 2*v,     lo,      mid, l, r, cc, p, ovf, hasz);
    st_prod_rec(nodes, 2*v + 1, mid + 1, hi,  l, r, cc, p, ovf, hasz);
}

/* clamp a caller range to [0, n-1]; returns 0 if it is empty/out of range */
static inline int st_clamp_range(StHandle *h, uint64_t *l, uint64_t *r) {
    if (h->n == 0 || h->size == 0) return 0;
    if (*l >= h->n) return 0;
    if (*r >= h->n) *r = h->n - 1;
    return *l <= *r;
}

/* add delta to every position in [l,r] (caller holds the write lock).  This
 * permanently gates off the gcd/product monoids (add_used = 1). */
static void st_range_add_locked(StHandle *h, uint64_t l, uint64_t r, int64_t delta) {
    if (!st_clamp_range(h, &l, &r)) return;
    h->hdr->add_used = 1;
    st_range_add_rec(st_nodes(h), 1, 0, h->size - 1, l, r, delta);
}

/* assign value c to every position in [l,r] (caller holds the write lock) */
static void st_range_assign_locked(StHandle *h, uint64_t l, uint64_t r, int64_t c) {
    if (!st_clamp_range(h, &l, &r)) return;
    st_range_assign_rec(st_nodes(h), 1, 0, h->size - 1, l, r, c);
}

/* sum/min/max over [l,r] into *sum/*mn/*mx (caller holds a lock) */
static void st_query_locked(StHandle *h, uint64_t l, uint64_t r,
                            int64_t *sum, int64_t *mn, int64_t *mx) {
    *sum = 0; *mn = ST_IDENTITY_MIN; *mx = ST_IDENTITY_MAX;
    if (!st_clamp_range(h, &l, &r)) return;
    StCarry c = { 0, 0, 0 };
    st_query_rec(st_nodes(h), 1, 0, h->size - 1, l, r, c, sum, mn, mx);
}

/* gcd over [l,r] (caller holds a lock and has checked add_used == 0) */
static int64_t st_gcd_locked(StHandle *h, uint64_t l, uint64_t r) {
    int64_t g = 0;
    if (!st_clamp_range(h, &l, &r)) return 0;
    StCarry c = { 0, 0, 0 };
    st_gcd_rec(st_nodes(h), 1, 0, h->size - 1, l, r, c, &g);
    return g;
}

/* product over [l,r]; returns 0 with *ovf=1 on overflow, else the product with
 * *ovf=0 (empty range -> 1).  Caller holds a lock and has checked add_used == 0. */
static int64_t st_prod_locked(StHandle *h, uint64_t l, uint64_t r, int *ovf) {
    int64_t p = 1;
    int hasz = 0;
    *ovf = 0;
    if (!st_clamp_range(h, &l, &r)) return 1;
    StCarry c = { 0, 0, 0 };
    st_prod_rec(st_nodes(h), 1, 0, h->size - 1, l, r, c, &p, ovf, &hasz);
    if (hasz) { *ovf = 0; return 0; }           /* a zero anywhere -> product 0, never an overflow */
    return *ovf ? 0 : p;
}

/* value at position i (caller holds a lock); 0 if out of range */
static int64_t st_get_locked(StHandle *h, uint64_t i) {
    int64_t s, mn, mx;
    st_query_locked(h, i, i, &s, &mn, &mx);
    return s;
}

/* set position i to val (caller holds the write lock).  Uses assign, not add, so
 * the gcd/product monoids stay valid across point updates. */
static void st_set_locked(StHandle *h, uint64_t i, int64_t val) {
    if (h->n == 0 || i >= h->n) return;
    st_range_assign_rec(st_nodes(h), 1, 0, h->size - 1, i, i, val);
}

/* reset every position to 0 (caller holds the write lock) */
static inline void st_clear_locked(StHandle *h) {
    StNode *nodes = st_nodes(h);
    uint64_t node_count = 2 * h->size;
    uint64_t nmax = st_nodes_max(h);    /* Layer B: clamp to the mapping */
    if (node_count > nmax) node_count = nmax;
    memset(nodes, 0, (size_t)(node_count * sizeof(StNode)));   /* every aggregate + lazy = 0 */
    h->hdr->add_used = 0;               /* a cleared tree is gcd/product-capable again */
}

#endif /* ST_H */
