/*
 * sortedset.h -- Shared-memory sorted set (ZSET) for Linux
 *
 * int64 members ordered by a double score on an order-statistics B+tree (keyed
 * by the total order (score, member); per-child subtree counts give O(log n)
 * rank; doubly-linked leaves give sequential range scans), plus a member->score
 * open-addressed hash index for O(1) lookup by member. Nodes and index slots
 * live in fixed pools. A write-preferring futex rwlock with reader-slot
 * dead-process recovery guards mutations.
 *
 * Layout: Header -> reader_slots[1024] -> member_index -> node_pool
 */

#ifndef SORTEDSET_H
#define SORTEDSET_H

#include <stdint.h>
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

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "sortedset.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define SS_MAGIC        0x53534554U  /* "SSET" */
#define SS_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define SS_NONE         UINT32_MAX
#define SS_ERR_BUFLEN   256
#ifndef SS_READER_SLOTS
#define SS_READER_SLOTS 1024  /* max concurrent reader processes for dead-process recovery */
#endif

/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these SS_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all SS_READER_SLOTS. */
#define SS_OCC_WORDS   (((SS_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define SS_OCC_BYTES   ((uint64_t)SS_OCC_WORDS * 8)      /* 128 bytes */

#define SS_ORDER 16              /* B+tree fanout: max children / max leaf entries */
#define SS_MIN   (SS_ORDER / 2)  /* min children/entries except the root */

#define SS_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, SS_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

/* ================================================================
 * Structs
 * ================================================================ */

/* B+tree node (one pool, one size). Leaf (is_leaf=1): up to SS_ORDER
   (score,member) entries in key order, doubly-linked via next/prev. Internal:
   up to SS_ORDER children with SS_ORDER-1 separators (scores/members) and
   per-child subtree entry counts (order-statistics, for rank). Parallel arrays
   so the in-node binary search scans packed scores. Free nodes thread the
   free-list through `parent`. */
/* arrays are SS_ORDER+1 to hold the transient overflow during a split */
typedef struct {
    uint16_t num;                    /* leaf: #entries; internal: #children */
    uint8_t  is_leaf;
    uint8_t  _pad;
    uint32_t parent;                 /* SS_NONE for root; free-list link when free */
    uint32_t next, prev;             /* leaf sibling links (SS_NONE at the ends) */
    double   scores[SS_ORDER + 1];   /* leaf entries / internal separators (num-1 used) */
    int64_t  members[SS_ORDER + 1];
    uint32_t children[SS_ORDER + 1]; /* internal child node idx */
    uint32_t counts[SS_ORDER + 1];   /* internal per-child subtree entry counts */
} SsNode;

/* member -> score open-addressed hash index slot (backward-shift delete) */
typedef struct {
    int64_t member;
    double  score;
    uint8_t state;                 /* 0 empty, 1 occupied */
} SsIdxSlot;

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
} SsReaderSlot;

struct SsHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t max_entries;             /* 8   entry capacity */
    uint32_t node_capacity;           /* 12  node-pool size */
    uint32_t index_slots;             /* 16  member-index slots (power of two) */
    uint32_t count;                   /* 20  live entries */
    uint64_t total_size;              /* 24 */
    uint64_t reader_slots_off;        /* 32 */
    uint64_t index_off;               /* 40 */
    uint64_t nodes_off;               /* 48 */
    uint32_t root;                    /* 56  root node idx (SS_NONE if empty) */
    uint32_t height;                  /* 60  tree height (0 = empty) */
    uint32_t leftmost;                /* 64  leftmost leaf idx */
    uint32_t rightmost;               /* 68  rightmost leaf idx */
    uint32_t node_free_head;          /* 72 */
    uint32_t wlock;                   /* 76  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 80  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 84  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint64_t stat_ops;                /* 88 */
    uint32_t slotless_rdepth;         /* 96: readers holding with no reader-slot (documented residual) */
    uint8_t  _pad[156];               /* 100..255 */
};
typedef struct SsHeader SsHeader;

_Static_assert(sizeof(SsHeader) == 256, "SsHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct SsHandle {
    SsHeader     *hdr;
    SsReaderSlot *reader_slots;  /* SS_READER_SLOTS entries */
    uint64_t     *occ;           /* SS_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    SsIdxSlot    *index;         /* member -> score */
    SsNode       *nodes;         /* B+tree node pool */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           notify_fd;
    int           backing_fd;    /* memfd fd to close on destroy, -1 otherwise */
    uint32_t      node_capacity; /* cached-at-attach node-pool size (trusted geometry; validated) */
    uint32_t      index_slots;   /* cached-at-attach member-index slot count (trusted, pow2) */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* ss_fork_gen value at last slot claim */
    uint32_t slotless_held; /* rwlock read-locks held with no reader-slot */
} SsHandle;

/* ================================================================
 * Helpers
 * ================================================================ */

static inline uint32_t ss_next_pow2(uint32_t v) {
    if (v < 2) return 1;
    return 1u << (32 - __builtin_clz(v - 1));
}

/* member hash: splitmix64 finalizer (good avalanche for int64 keys) */
static inline uint64_t ss_hash_member(int64_t m) {
    uint64_t x = (uint64_t)m + 0x9E3779B97F4A7C15ULL;
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ULL;
    x = (x ^ (x >> 27)) * 0x94D049BB133111EBULL;
    return x ^ (x >> 31);
}

/* total order on (score, member): -1 / 0 / +1 */
static inline int ss_key_cmp(double sa, int64_t ma, double sb, int64_t mb) {
    if (sa < sb) return -1;
    if (sa > sb) return  1;
    return (ma < mb) ? -1 : (ma > mb) ? 1 : 0;
}

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

#define SS_RWLOCK_SPIN_LIMIT 32
#define SS_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void ss_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define SS_RWLOCK_WRITER_BIT 0x80000000U
#define SS_RWLOCK_PID_MASK   0x7FFFFFFFU
#define SS_RWLOCK_WR(pid)    (SS_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & SS_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
/* A zombie (dead but not yet reaped) still answers kill(pid,0) as alive, so a
 * process that crashed while holding the lock and lingers unreaped would never
 * be recovered.  Treat /proc/<pid>/stat state 'Z' as dead.  Linux-only (as is
 * this module); if /proc is unreadable we fall back to "alive" (safe: we never
 * force-recover a possibly-live holder). */
static inline int ss_pid_is_zombie(uint32_t pid) {
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
static inline int ss_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !ss_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void ss_recover_stale_lock(SsHandle *h, uint32_t observed_wlock) {
    SsHeader *hdr = h->hdr;
    uint32_t mypid = SS_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec ss_lock_timeout = { SS_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t ss_fork_gen = 1;
static pthread_once_t ss_atfork_once = PTHREAD_ONCE_INIT;
static void ss_on_fork_child(void) {
    __atomic_add_fetch(&ss_fork_gen, 1, __ATOMIC_RELAXED);
}
static void ss_atfork_init(void) {
    pthread_atfork(NULL, NULL, ss_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void ss_occ_set(SsHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void ss_occ_clear(SsHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void ss_claim_reader_slot(SsHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&ss_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&ss_atfork_once, ss_atfork_init);
    /* Re-read after pthread_once: ss_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&ss_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % SS_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < SS_READER_SLOTS; i++) {
        uint32_t s = (start + i) % SS_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            ss_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < SS_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || ss_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            ss_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void ss_recover_after_timeout(SsHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= SS_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & SS_RWLOCK_PID_MASK;
        if (!ss_pid_alive(pid))
            ss_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void ss_park(SsHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void ss_unpark(SsHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void ss_rdepth_inc(SsHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void ss_rdepth_dec(SsHandle *h) {
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
static inline void ss_reader_wake_drain(SsHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void ss_rwlock_rdlock(SsHandle *h) {
    ss_claim_reader_slot(h);
    SsHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            ss_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            ss_rdepth_dec(h);
            ss_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= SS_RWLOCK_WRITER_BIT &&
            !ss_pid_alive(cur & SS_RWLOCK_PID_MASK)) {
            ss_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < SS_RWLOCK_SPIN_LIMIT, 1)) {
            ss_rwlock_spin_pause();
            continue;
        }
        ss_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &ss_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                ss_unpark(h);
                ss_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        ss_unpark(h);
        spin = 0;
    }
}

static inline void ss_rwlock_rdunlock(SsHandle *h) {
    ss_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    ss_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void ss_rwlock_wrlock(SsHandle *h) {
    ss_claim_reader_slot(h);  /* refresh cached_pid across fork */
    SsHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = SS_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= SS_RWLOCK_WRITER_BIT &&
            !ss_pid_alive(expected & SS_RWLOCK_PID_MASK)) {
            ss_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < SS_RWLOCK_SPIN_LIMIT, 1)) {
            ss_rwlock_spin_pause();
            continue;
        }
        ss_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &ss_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                ss_unpark(h);
                ss_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        ss_unpark(h);
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
         * this scan, so no held slot is skipped).  O(SS_OCC_WORDS + live readers)
         * instead of O(SS_READER_SLOTS). */
        for (uint32_t w = 0; w < SS_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!ss_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &ss_lock_timeout, NULL, 0);
    }
}

static inline void ss_rwlock_wrunlock(SsHandle *h) {
    SsHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> member_index -> node_pool
 * ================================================================ */

/* Largest max_entries accepted at create time. 2^30 keeps the index-slot
 * power-of-two rounding (ss_next_pow2) and every byte offset well within
 * range, and is far beyond any realistic shared-memory map. */
#define SS_MAX_CAPACITY 0x40000000u

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> member_index -> node_pool. */
typedef struct { uint64_t reader_slots, occ, index, nodes; } SsLayout;

static inline SsLayout ss_layout(uint32_t index_slots) {
    SsLayout L;
    L.reader_slots = sizeof(SsHeader);
    L.occ          = L.reader_slots + (uint64_t)SS_READER_SLOTS * sizeof(SsReaderSlot);
    L.index        = L.occ + SS_OCC_BYTES;
    L.nodes        = L.index + (uint64_t)index_slots * sizeof(SsIdxSlot);
    L.nodes        = (L.nodes + 7) & ~(uint64_t)7;   /* 8-byte align the node pool */
    return L;
}

static inline uint64_t ss_total_size(uint32_t index_slots, uint32_t node_capacity) {
    SsLayout L = ss_layout(index_slots);
    return L.nodes + (uint64_t)node_capacity * sizeof(SsNode);
}

static inline void ss_init_header(void *base, uint32_t max_entries, uint32_t index_slots,
                                  uint32_t node_capacity, uint64_t total) {
    SsLayout L = ss_layout(index_slots);
    SsHeader *hdr = (SsHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic            = SS_MAGIC;
    hdr->version          = SS_VERSION;
    hdr->max_entries      = max_entries;
    hdr->node_capacity    = node_capacity;
    hdr->index_slots      = index_slots;
    hdr->count            = 0;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->index_off        = L.index;
    hdr->nodes_off        = L.nodes;
    hdr->root             = SS_NONE;   /* empty tree */
    hdr->height           = 0;
    hdr->leftmost         = SS_NONE;
    hdr->rightmost        = SS_NONE;

    /* Thread the node free-list through `parent`. */
    SsNode *nodes = (SsNode *)((uint8_t *)base + L.nodes);
    for (uint32_t i = 0; i < node_capacity; i++)
        nodes[i].parent = (i + 1 < node_capacity) ? (i + 1) : SS_NONE;
    hdr->node_free_head = 0;
    /* index region left zeroed: every slot empty (state == 0). */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline SsHandle *ss_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    SsHeader *hdr = (SsHeader *)base;
    SsHandle *h = (SsHandle *)calloc(1, sizeof(SsHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->reader_slots = (SsReaderSlot *)((uint8_t *)base + sizeof(SsHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + ss_layout(hdr->index_slots).occ);  /* trusted layout offset */
    h->index        = (SsIdxSlot *)((uint8_t *)base + hdr->index_off);
    h->nodes        = (SsNode *)((uint8_t *)base + hdr->nodes_off);
    /* Cache the fixed pool geometry now (validated at create/attach): a
     * lock-violating peer that later corrupts these header fields must not be
     * able to loosen index masks, node-index bounds, or clear/validate loops. */
    h->node_capacity = hdr->node_capacity;
    h->index_slots   = hdr->index_slots;
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->notify_fd    = -1;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by ss_create reopen and ss_open_fd). */
static inline int ss_validate_header(const SsHeader *hdr, uint64_t file_size) {
    if (hdr->magic != SS_MAGIC) return 0;
    if (hdr->version != SS_VERSION) return 0;
    if (hdr->max_entries == 0 || hdr->max_entries >= SS_MAX_CAPACITY) return 0;
    if (hdr->index_slots == 0 || (hdr->index_slots & (hdr->index_slots - 1)) != 0) return 0; /* pow2 */
    if (hdr->node_capacity == 0) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != ss_total_size(hdr->index_slots, hdr->node_capacity)) return 0;
    SsLayout L = ss_layout(hdr->index_slots);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->index_off        != L.index)        return 0;
    if (hdr->nodes_off        != L.nodes)        return 0;
    if (hdr->count > hdr->max_entries) return 0;
    if (hdr->root != SS_NONE && hdr->root >= hdr->node_capacity) return 0;
    if (hdr->root == SS_NONE && hdr->count != 0) return 0;
    return 1;
}


/* validate max_entries and compute the index-slot count + node-pool capacity
   (shared by ss_create + ss_create_memfd) */
static int ss_validate_create_args(uint32_t max_entries, uint32_t *index_slots,
                                   uint32_t *node_capacity, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (max_entries == 0) { SS_ERR("max_entries must be > 0"); return 0; }
    /* must be strictly < SS_MAX_CAPACITY: at exactly 2^30 the index cap below makes
       index_slots == max_entries (load factor 1.0), so ss_idx_find never finds an
       empty slot on an absent lookup when full and spins forever under the lock. */
    if (max_entries >= SS_MAX_CAPACITY) { SS_ERR("max_entries too large (max %u)", SS_MAX_CAPACITY - 1); return 0; }
    uint64_t want = (uint64_t)max_entries * 10 / 7 + 1;        /* index load factor ~0.7 */
    if (want > SS_MAX_CAPACITY) want = SS_MAX_CAPACITY;
    *index_slots   = ss_next_pow2((uint32_t)want);
    *node_capacity = (uint32_t)((uint64_t)max_entries / (SS_MIN - 1) + 64); /* worst-case fill + slack */
    return 1;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at mode,
 * default 0600), or attach an existing file (O_RDWR|O_NOFOLLOW, no O_CREAT). */
static int ss_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { SS_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        SS_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    SS_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static SsHandle *ss_create(const char *path, uint32_t max_entries, mode_t mode, char *errbuf) {
    uint32_t index_slots, node_capacity;
    if (!ss_validate_create_args(max_entries, &index_slots, &node_capacity, errbuf)) return NULL;

    uint64_t total = ss_total_size(index_slots, node_capacity);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { SS_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = ss_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { SS_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { SS_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(SsHeader)) {
            SS_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            SS_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            SS_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { SS_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!ss_validate_header((SsHeader *)base, (uint64_t)st.st_size)) {
                SS_ERR("invalid sorted-set file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return ss_setup(base, map_size, path, -1);
        }
    }
    ss_init_header(base, max_entries, index_slots, node_capacity, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return ss_setup(base, map_size, path, -1);
}

static SsHandle *ss_create_memfd(const char *name, uint32_t max_entries, char *errbuf) {
    uint32_t index_slots, node_capacity;
    if (!ss_validate_create_args(max_entries, &index_slots, &node_capacity, errbuf)) return NULL;

    uint64_t total = ss_total_size(index_slots, node_capacity);
    int fd = memfd_create(name ? name : "sortedset", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { SS_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        SS_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { SS_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    ss_init_header(base, max_entries, index_slots, node_capacity, total);
    return ss_setup(base, (size_t)total, NULL, fd);
}

static SsHandle *ss_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { SS_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(SsHeader)) { SS_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { SS_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!ss_validate_header((SsHeader *)base, (uint64_t)st.st_size)) {
        SS_ERR("invalid sorted-set"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { SS_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return ss_setup(base, ms, NULL, myfd);
}

static void ss_destroy(SsHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&ss_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        ss_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int ss_msync(SsHandle *h) {
    if (!h || !h->hdr) return 0;
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

static int ss_create_eventfd(SsHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    int efd = eventfd(0, EFD_NONBLOCK|EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd;
    return efd;
}

static int ss_notify(SsHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t v = 1;
    return write(h->notify_fd, &v, sizeof(v)) == sizeof(v);
}

static int64_t ss_eventfd_consume(SsHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t v = 0;
    if (read(h->notify_fd, &v, sizeof(v)) != sizeof(v)) return -1;
    return (int64_t)v;
}

/* ================================================================
 * Sorted set: node pool, member index, B+tree (callers hold the lock)
 * ================================================================ */

/* reset to the empty set (caller holds the write lock) */
static inline void ss_clear_locked(SsHandle *h) {
    SsHeader *hdr = h->hdr;
    hdr->count     = 0;
    hdr->root      = SS_NONE;
    hdr->height    = 0;
    hdr->leftmost  = SS_NONE;
    hdr->rightmost = SS_NONE;
    for (uint32_t i = 0; i < h->node_capacity; i++)
        h->nodes[i].parent = (i + 1 < h->node_capacity) ? (i + 1) : SS_NONE;
    hdr->node_free_head = 0;
    memset(h->index, 0, (size_t)h->index_slots * sizeof(SsIdxSlot));
}

/* ---- node pool ---- */
static inline uint32_t ss_node_alloc(SsHandle *h) {
    uint32_t idx = h->hdr->node_free_head;
    if (idx == SS_NONE || idx >= h->node_capacity) return SS_NONE;   /* Layer B: empty or corrupt free-list head */
    h->hdr->node_free_head = h->nodes[idx].parent;
    return idx;
}
/* Layer B: the free list head and links live in peer-writable shared memory, so
 * ss_node_alloc can legitimately return SS_NONE (exhausted OR corrupt). The
 * write paths cannot unwind a half-done split, so callers must confirm the
 * worst case is available BEFORE mutating anything -- otherwise a split would
 * write through &h->nodes[SS_NONE], far outside the mapping.
 * Walks at most `need` links, so a corrupt free list containing a cycle is
 * bounded here too. */
static inline int ss_nodes_available(const SsHandle *h, uint32_t need) {
    uint32_t idx = h->hdr->node_free_head;
    for (uint32_t i = 0; i < need; i++) {
        if (idx == SS_NONE || idx >= h->node_capacity) return 0;
        idx = h->nodes[idx].parent;
    }
    return 1;
}

/* An insert splits at most once per level and may add a new root. */
static inline int ss_add_has_headroom(const SsHandle *h) {
    return ss_nodes_available(h, h->hdr->height + 2);
}

static inline void ss_node_free(SsHandle *h, uint32_t idx) {
    h->nodes[idx].parent = h->hdr->node_free_head;
    h->hdr->node_free_head = idx;
}

/* node indices stored in the mmap (children[], leftmost,
 * rightmost, leaf next/prev, free-list links) are attacker-controlled -- a
 * local peer can write the backing file. Bound every such index against the
 * node pool before using it to dereference h->nodes[]. A predictable
 * never-taken branch for valid data; on a bad index the caller stops/skips
 * instead of trapping. */
static inline int ss_node_ok(const SsHandle *h, uint32_t idx) {
    return idx < h->node_capacity;   /* cached geometry, not peer-writable header */
}

/* ---- member -> score index (open addressing, linear probe) ---- */
/* returns the slot of `member` (if present) or the first empty slot for it;
   *found (optional, may be NULL) says which.  Returns SS_NONE with *found == 0
   when every slot reads occupied and `member` is absent.  Create-time sizing
   keeps the load factor <= 0.7, so an all-occupied table means a lock-violating
   peer has scribbled over the state bytes -- but the probe must still be
   bounded by the table size: an unbounded one spins forever while holding the
   lock, hanging every process that shares the segment. */
static inline uint32_t ss_idx_find(SsHandle *h, int64_t member, int *found) {
    uint32_t mask = h->index_slots - 1;   /* cached geometry, not peer-writable header */
    uint32_t i = (uint32_t)(ss_hash_member(member) & mask);
    for (uint32_t probe = 0; probe < h->index_slots; probe++) {
        if (!h->index[i].state) { if (found) *found = 0; return i; }
        if (h->index[i].member == member) { if (found) *found = 1; return i; }
        i = (i + 1) & mask;
    }
    if (found) *found = 0;
    return SS_NONE;   /* corrupt full table */
}
static inline int ss_idx_get(SsHandle *h, int64_t member, double *score) {
    int f; uint32_t i = ss_idx_find(h, member, &f);
    if (f) { *score = h->index[i].score; return 1; }
    return 0;
}
/* returns 0 when the (corrupt) index has no free slot for an absent member --
   the caller must fail the operation instead of clobbering an arbitrary slot */
static inline int ss_idx_set(SsHandle *h, int64_t member, double score) {
    uint32_t i = ss_idx_find(h, member, NULL);
    if (i == SS_NONE) return 0;
    h->index[i].member = member;
    h->index[i].score  = score;
    h->index[i].state  = 1;
    return 1;
}

/* ---- B+tree ---- */
static inline uint32_t ss_node_total(const SsNode *nd) {
    if (nd->is_leaf) return nd->num;
    uint32_t t = 0;
    for (int i = 0; i < nd->num; i++) t += nd->counts[i];
    return t;
}

/* child index in an internal node whose subtree would hold (score,member) */
static inline int ss_child_index(const SsNode *nd, double score, int64_t member) {
    int lo = 0, hi = nd->num - 1;
    while (lo < hi) {
        int mid = (lo + hi) / 2;
        if (ss_key_cmp(score, member, nd->scores[mid], nd->members[mid]) < 0) hi = mid;
        else lo = mid + 1;
    }
    return lo;
}

typedef struct { int split; uint32_t rnode; double rscore; int64_t rmember; } SsSplit;

/* insert (score,member) into subtree nidx (member known absent); on overflow
   split and return the new right node + separator to promote; maintains counts */
static SsSplit ss_insert_rec(SsHandle *h, uint32_t nidx, double score, int64_t member) {
    SsNode *nd = &h->nodes[nidx];
    SsSplit r = { 0, SS_NONE, 0.0, 0 };
    if (nd->is_leaf) {
        int pos = 0;
        while (pos < nd->num && ss_key_cmp(nd->scores[pos], nd->members[pos], score, member) < 0) pos++;
        for (int i = nd->num; i > pos; i--) { nd->scores[i] = nd->scores[i-1]; nd->members[i] = nd->members[i-1]; }
        nd->scores[pos] = score; nd->members[pos] = member; nd->num++;
        if (nd->num <= SS_ORDER) return r;
        uint32_t ridx = ss_node_alloc(h);
        SsNode *rn = &h->nodes[ridx];
        rn->is_leaf = 1; rn->parent = nd->parent;
        int mid = nd->num / 2, rc = nd->num - mid;
        for (int i = 0; i < rc; i++) { rn->scores[i] = nd->scores[mid+i]; rn->members[i] = nd->members[mid+i]; }
        rn->num = (uint16_t)rc; nd->num = (uint16_t)mid;
        rn->next = nd->next; rn->prev = nidx;
        if (nd->next == SS_NONE) h->hdr->rightmost = ridx;
        else if (ss_node_ok(h, nd->next)) h->nodes[nd->next].prev = ridx;
        /* corrupt next link: skip the backlink fix rather than a wild write */
        nd->next = ridx;
        r.split = 1; r.rnode = ridx; r.rscore = rn->scores[0]; r.rmember = rn->members[0];
        return r;
    }
    int c = ss_child_index(nd, score, member);
    uint32_t cidx = nd->children[c];
    if (!ss_node_ok(h, cidx)) return r;   /* Layer B: corrupt child index -- stop instead of a wild descent */
    SsSplit cr = ss_insert_rec(h, cidx, score, member);
    if (!cr.split) { nd->counts[c]++; return r; }
    for (int i = nd->num; i > c + 1; i--) { nd->children[i] = nd->children[i-1]; nd->counts[i] = nd->counts[i-1]; }
    for (int i = nd->num - 1; i > c; i--) { nd->scores[i] = nd->scores[i-1]; nd->members[i] = nd->members[i-1]; }
    nd->scores[c] = cr.rscore; nd->members[c] = cr.rmember;
    nd->children[c+1] = cr.rnode; h->nodes[cr.rnode].parent = nidx;
    nd->num++;
    nd->counts[c]   = ss_node_total(&h->nodes[cidx]);
    nd->counts[c+1] = ss_node_total(&h->nodes[cr.rnode]);
    if (nd->num <= SS_ORDER) return r;
    uint32_t ridx = ss_node_alloc(h);
    SsNode *rn = &h->nodes[ridx];
    rn->is_leaf = 0; rn->parent = nd->parent;
    int midc = nd->num / 2, rch = nd->num - midc;
    for (int i = 0; i < rch; i++) {
        rn->children[i] = nd->children[midc+i];
        rn->counts[i]   = nd->counts[midc+i];
        if (ss_node_ok(h, rn->children[i])) h->nodes[rn->children[i]].parent = ridx;   /* skip a corrupt child index */
    }
    for (int i = 0; i < rch - 1; i++) { rn->scores[i] = nd->scores[midc+i]; rn->members[i] = nd->members[midc+i]; }
    rn->num = (uint16_t)rch;
    double up_s = nd->scores[midc-1]; int64_t up_m = nd->members[midc-1];
    nd->num = (uint16_t)midc;
    r.split = 1; r.rnode = ridx; r.rscore = up_s; r.rmember = up_m;
    return r;
}

static void ss_tree_add(SsHandle *h, double score, int64_t member) {
    SsHeader *hdr = h->hdr;
    if (hdr->root == SS_NONE) {
        uint32_t l = ss_node_alloc(h);
        SsNode *nd = &h->nodes[l];
        nd->is_leaf = 1; nd->parent = SS_NONE; nd->next = SS_NONE; nd->prev = SS_NONE;
        nd->num = 1; nd->scores[0] = score; nd->members[0] = member;
        hdr->root = l; hdr->leftmost = l; hdr->rightmost = l; hdr->height = 1;
        hdr->count++;
        return;
    }
    if (!ss_node_ok(h, hdr->root)) return;   /* Layer B: corrupt root index -- refuse the descent */
    SsSplit r = ss_insert_rec(h, hdr->root, score, member);
    if (r.split) {
        uint32_t nr = ss_node_alloc(h);
        SsNode *root = &h->nodes[nr];
        root->is_leaf = 0; root->parent = SS_NONE; root->num = 2;
        root->children[0] = hdr->root; root->children[1] = r.rnode;
        root->scores[0] = r.rscore; root->members[0] = r.rmember;
        root->counts[0] = ss_node_total(&h->nodes[hdr->root]);
        root->counts[1] = ss_node_total(&h->nodes[r.rnode]);
        h->nodes[hdr->root].parent = nr;
        h->nodes[r.rnode].parent = nr;
        hdr->root = nr; hdr->height++;
    }
    hdr->count++;
}

/* index backward-shift deletion (keeps probe sequences contiguous) */
static void ss_idx_del(SsHandle *h, int64_t member) {
    uint32_t mask = h->index_slots - 1;   /* cached geometry, not peer-writable header */
    int f; uint32_t i = ss_idx_find(h, member, &f);
    if (!f) return;
    uint32_t j = i;
    /* bounded by the table size: the shift scan stops at the first empty slot,
       but a corrupt all-occupied table has none and must not spin forever
       under the lock */
    for (uint32_t probe = 0; probe < h->index_slots; probe++) {
        j = (j + 1) & mask;
        if (!h->index[j].state) break;
        uint32_t k = (uint32_t)(ss_hash_member(h->index[j].member) & mask);
        int in = (i < j) ? (i < k && k <= j) : (k > i || k <= j);  /* k in (i, j] ? */
        if (!in) { h->index[i] = h->index[j]; i = j; }
    }
    h->index[i].state = 0;
}

/* merge children[c] and children[c+1] of pidx into children[c]; frees the right
   node and pulls separator c down (for internal nodes) */
static void ss_merge(SsHandle *h, uint32_t pidx, int c) {
    SsNode *p = &h->nodes[pidx];
    uint32_t lidx = p->children[c], ridx = p->children[c+1];
    if (!ss_node_ok(h, lidx) || !ss_node_ok(h, ridx)) return;   /* Layer B: corrupt child index */
    SsNode *ln = &h->nodes[lidx], *rn = &h->nodes[ridx];
    if (ln->is_leaf) {
        for (int i = 0; i < rn->num; i++) { ln->scores[ln->num+i] = rn->scores[i]; ln->members[ln->num+i] = rn->members[i]; }
        ln->next = rn->next;
        if (rn->next == SS_NONE) h->hdr->rightmost = lidx;
        else if (ss_node_ok(h, rn->next)) h->nodes[rn->next].prev = lidx;
        /* corrupt next link: skip the backlink fix rather than a wild write */
        ln->num = (uint16_t)(ln->num + rn->num);
    } else {
        ln->scores[ln->num-1] = p->scores[c]; ln->members[ln->num-1] = p->members[c];   /* pull separator down */
        for (int i = 0; i < rn->num; i++) { ln->children[ln->num+i] = rn->children[i]; ln->counts[ln->num+i] = rn->counts[i]; if (ss_node_ok(h, rn->children[i])) h->nodes[rn->children[i]].parent = lidx; }
        for (int i = 0; i < rn->num - 1; i++) { ln->scores[ln->num+i] = rn->scores[i]; ln->members[ln->num+i] = rn->members[i]; }
        ln->num = (uint16_t)(ln->num + rn->num);
    }
    p->counts[c] += p->counts[c+1];
    for (int i = c+1; i+1 < p->num; i++) { p->children[i] = p->children[i+1]; p->counts[i] = p->counts[i+1]; }
    for (int i = c;   i+1 < p->num-1; i++) { p->scores[i] = p->scores[i+1]; p->members[i] = p->members[i+1]; }
    p->num--;
    ss_node_free(h, ridx);
}

/* fix an underflow in children[c] of pidx by borrowing from a sibling or merging */
static void ss_fix_underflow(SsHandle *h, uint32_t pidx, int c) {
    SsNode *p = &h->nodes[pidx];
    uint32_t cidx = p->children[c];
    if (!ss_node_ok(h, cidx)) return;   /* Layer B: corrupt child index */
    SsNode *cn = &h->nodes[cidx];
    if (c > 0) {
        uint32_t lidx = p->children[c-1];
        if (!ss_node_ok(h, lidx)) return;   /* Layer B: corrupt sibling index */
        SsNode *ln = &h->nodes[lidx];
        if (ln->num > SS_MIN) {                       /* borrow from left */
            if (cn->is_leaf) {
                for (int i = cn->num; i > 0; i--) { cn->scores[i] = cn->scores[i-1]; cn->members[i] = cn->members[i-1]; }
                cn->scores[0] = ln->scores[ln->num-1]; cn->members[0] = ln->members[ln->num-1];
                cn->num++; ln->num--;
                p->scores[c-1] = cn->scores[0]; p->members[c-1] = cn->members[0];
                p->counts[c-1]--; p->counts[c]++;
            } else {
                uint32_t moved = ln->counts[ln->num-1];
                for (int i = cn->num; i > 0; i--) { cn->children[i] = cn->children[i-1]; cn->counts[i] = cn->counts[i-1]; }
                for (int i = cn->num-1; i > 0; i--) { cn->scores[i] = cn->scores[i-1]; cn->members[i] = cn->members[i-1]; }
                cn->scores[0] = p->scores[c-1]; cn->members[0] = p->members[c-1];
                cn->children[0] = ln->children[ln->num-1]; cn->counts[0] = moved;
                if (ss_node_ok(h, cn->children[0])) h->nodes[cn->children[0]].parent = cidx;   /* skip a corrupt borrowed child */
                cn->num++;
                p->scores[c-1] = ln->scores[ln->num-2]; p->members[c-1] = ln->members[ln->num-2];
                ln->num--;
                p->counts[c-1] -= moved; p->counts[c] += moved;
            }
            return;
        }
    }
    if (c < p->num - 1) {
        uint32_t ridx = p->children[c+1];
        if (!ss_node_ok(h, ridx)) return;   /* Layer B: corrupt sibling index */
        SsNode *rn = &h->nodes[ridx];
        if (rn->num > SS_MIN) {                       /* borrow from right */
            if (cn->is_leaf) {
                cn->scores[cn->num] = rn->scores[0]; cn->members[cn->num] = rn->members[0]; cn->num++;
                for (int i = 0; i+1 < rn->num; i++) { rn->scores[i] = rn->scores[i+1]; rn->members[i] = rn->members[i+1]; }
                rn->num--;
                p->scores[c] = rn->scores[0]; p->members[c] = rn->members[0];
                p->counts[c]++; p->counts[c+1]--;
            } else {
                uint32_t moved = rn->counts[0];
                cn->scores[cn->num-1] = p->scores[c]; cn->members[cn->num-1] = p->members[c];
                cn->children[cn->num] = rn->children[0]; cn->counts[cn->num] = moved;
                if (ss_node_ok(h, cn->children[cn->num])) h->nodes[cn->children[cn->num]].parent = cidx;   /* skip a corrupt borrowed child */
                cn->num++;
                p->scores[c] = rn->scores[0]; p->members[c] = rn->members[0];
                for (int i = 0; i+1 < rn->num; i++) { rn->children[i] = rn->children[i+1]; rn->counts[i] = rn->counts[i+1]; }
                for (int i = 0; i+1 < rn->num-1; i++) { rn->scores[i] = rn->scores[i+1]; rn->members[i] = rn->members[i+1]; }
                rn->num--;
                p->counts[c] += moved; p->counts[c+1] -= moved;
            }
            return;
        }
    }
    ss_merge(h, pidx, (c > 0) ? c - 1 : c);           /* merge with a sibling */
}

/* delete (score,member) from subtree nidx (known present); decrement counts;
   return 1 if nidx now underflows (num < SS_MIN) */
static int ss_delete_rec(SsHandle *h, uint32_t nidx, double score, int64_t member) {
    SsNode *nd = &h->nodes[nidx];
    if (nd->is_leaf) {
        int pos = 0;
        while (pos < nd->num && ss_key_cmp(nd->scores[pos], nd->members[pos], score, member) != 0) pos++;
        for (int i = pos; i+1 < nd->num; i++) { nd->scores[i] = nd->scores[i+1]; nd->members[i] = nd->members[i+1]; }
        nd->num--;
        return nd->num < SS_MIN;
    }
    int c = ss_child_index(nd, score, member);
    uint32_t cidx = nd->children[c];
    if (!ss_node_ok(h, cidx)) return 0;   /* Layer B: corrupt child index -- stop, report no underflow */
    int under = ss_delete_rec(h, cidx, score, member);
    nd->counts[c]--;
    if (under) ss_fix_underflow(h, nidx, c);
    return nd->num < SS_MIN;
}

static void ss_tree_del(SsHandle *h, double score, int64_t member) {
    SsHeader *hdr = h->hdr;
    if (hdr->root == SS_NONE || hdr->root >= h->node_capacity) return;   /* Layer B: empty or corrupt root -> no-op */
    ss_delete_rec(h, hdr->root, score, member);
    SsNode *root = &h->nodes[hdr->root];
    if (root->is_leaf) {
        if (root->num == 0) {
            ss_node_free(h, hdr->root);
            hdr->root = SS_NONE; hdr->leftmost = SS_NONE; hdr->rightmost = SS_NONE; hdr->height = 0;
        }
    } else if (root->num == 1) {
        uint32_t child = root->children[0];
        ss_node_free(h, hdr->root);
        if (ss_node_ok(h, child)) {
            hdr->root = child; h->nodes[child].parent = SS_NONE; hdr->height--;
        } else {
            /* Layer B: corrupt child index -- drop the tree rather than point
               the root outside the node pool */
            hdr->root = SS_NONE; hdr->leftmost = SS_NONE; hdr->rightmost = SS_NONE; hdr->height = 0;
        }
    }
    hdr->count--;
}

/* add: 1 (new), 0 (existing -- score updated if changed), -1 (full) */
static int ss_add_locked(SsHandle *h, int64_t member, double score) {
    double old;
    if (ss_idx_get(h, member, &old)) {
        if (old != score) {
            /* re-insert: check headroom BEFORE the delete, so a refusal leaves
               the set untouched rather than dropping the member */
            if (!ss_add_has_headroom(h)) return -1;
            ss_tree_del(h, old, member); ss_tree_add(h, score, member); ss_idx_set(h, member, score);
        }
        return 0;
    }
    if (h->hdr->count >= h->hdr->max_entries) return -1;
    if (!ss_add_has_headroom(h)) return -1;
    ss_tree_add(h, score, member);
    if (!ss_idx_set(h, member, score)) return -1;   /* corrupt full index: fail the add */
    return 1;
}

/* remove: 1 if removed, 0 if absent */
static int ss_remove_locked(SsHandle *h, int64_t member) {
    double old;
    if (!ss_idx_get(h, member, &old)) return 0;
    ss_tree_del(h, old, member);
    ss_idx_del(h, member);
    return 1;
}

/* incr by delta. *out = new score. returns 1 (created), 0 (updated), -1 (full),
   -2 (result is NaN) */
static int ss_incr_locked(SsHandle *h, int64_t member, double delta, double *out) {
    double old;
    if (ss_idx_get(h, member, &old)) {
        double ns = old + delta; *out = ns;
        if (ns != ns) return -2;
        if (ns != old) {
            if (!ss_add_has_headroom(h)) return -1;
            ss_tree_del(h, old, member); ss_tree_add(h, ns, member); ss_idx_set(h, member, ns);
        }
        return 0;
    }
    if (h->hdr->count >= h->hdr->max_entries) return -1;
    *out = delta;
    if (delta != delta) return -2;
    if (!ss_add_has_headroom(h)) return -1;
    ss_tree_add(h, delta, member);
    if (!ss_idx_set(h, member, delta)) return -1;   /* corrupt full index: fail the incr */
    return 1;
}

/* pop the min (max=0) or max (max=1): 0 if empty, else 1 with *m,*s */
static int ss_pop_locked(SsHandle *h, int max, int64_t *m, double *s) {
    if (h->hdr->root == SS_NONE) return 0;
    uint32_t li = max ? h->hdr->rightmost : h->hdr->leftmost;
    if (!ss_node_ok(h, li)) return 0;                 /* corrupt leftmost/rightmost */
    SsNode *nd = &h->nodes[li];
    int pos = max ? nd->num - 1 : 0;
    *m = nd->members[pos]; *s = nd->scores[pos];
    ss_tree_del(h, *s, *m);
    ss_idx_del(h, *m);
    return 1;
}

/* ---- structural validator (debug / tests) ---- */
static long ss_check_rec(SsHandle *h, uint32_t nidx, int depth, int is_root,
                         double *ps, int64_t *pm, int *hp, int *leaf_depth) {
    if (!ss_node_ok(h, nidx)) return -1;              /* corrupt child index */
    SsNode *nd = &h->nodes[nidx];
    if (nd->num < 1 || nd->num > SS_ORDER) return -1;
    if (!is_root && nd->num < SS_MIN) return -1;
    if (nd->is_leaf) {
        if (*leaf_depth < 0) *leaf_depth = depth;
        else if (*leaf_depth != depth) return -1;
        for (int i = 0; i < nd->num; i++) {
            if (*hp && ss_key_cmp(*ps, *pm, nd->scores[i], nd->members[i]) >= 0) return -1;
            *ps = nd->scores[i]; *pm = nd->members[i]; *hp = 1;
        }
        return nd->num;
    }
    long total = 0;
    for (int i = 0; i < nd->num; i++) {
        long c = ss_check_rec(h, nd->children[i], depth + 1, 0, ps, pm, hp, leaf_depth);
        if (c < 0 || (uint32_t)c != nd->counts[i]) return -1;
        total += c;
    }
    return total;
}
static int ss_validate_tree(SsHandle *h) {
    SsHeader *hdr = h->hdr;
    if (hdr->root == SS_NONE) return hdr->count == 0 && hdr->leftmost == SS_NONE;
    double ps = 0; int64_t pm = 0; int hp = 0, ld = -1;
    long total = ss_check_rec(h, hdr->root, 0, 1, &ps, &pm, &hp, &ld);
    if (total < 0 || (uint32_t)total != hdr->count) return 0;
    /* leaf links == in-order, and reach rightmost */
    uint32_t leaf = hdr->leftmost; double ls = 0; int64_t lm = 0; int lh = 0; uint32_t seen = 0;
    while (leaf != SS_NONE) {
        if (!ss_node_ok(h, leaf)) return 0;           /* corrupt leaf-link index */
        SsNode *nd = &h->nodes[leaf];
        if (!nd->is_leaf) return 0;
        for (int i = 0; i < nd->num; i++) {
            if (lh && ss_key_cmp(ls, lm, nd->scores[i], nd->members[i]) >= 0) return 0;
            ls = nd->scores[i]; lm = nd->members[i]; lh = 1; seen++;
        }
        if (nd->next == SS_NONE && leaf != hdr->rightmost) return 0;
        leaf = nd->next;
    }
    if (seen != hdr->count) return 0;
    /* index population == count */
    uint32_t icount = 0;
    for (uint32_t i = 0; i < h->index_slots; i++) if (h->index[i].state) icount++;   /* cached geometry */
    return icount == hdr->count;
}

/* ---- order-statistics queries (read paths; caller holds the read lock) ---- */

/* number of entries strictly less than (score, member) -- the rank of the key */
static uint32_t ss_rank_of(SsHandle *h, double score, int64_t member) {
    uint32_t n = h->hdr->root, rank = 0;
    while (ss_node_ok(h, n) && !h->nodes[n].is_leaf) {
        SsNode *nd = &h->nodes[n];
        int c = ss_child_index(nd, score, member);
        for (int i = 0; i < c; i++) rank += nd->counts[i];
        n = nd->children[c];
    }
    if (!ss_node_ok(h, n)) return rank;               /* corrupt child index: stop */
    SsNode *nd = &h->nodes[n];
    int pos = 0;
    while (pos < nd->num && ss_key_cmp(nd->scores[pos], nd->members[pos], score, member) < 0) pos++;
    return rank + (uint32_t)pos;
}

/* entry at 0-based rank r (r < count); returns leaf idx and sets *pos */
static uint32_t ss_at_rank(SsHandle *h, uint32_t r, int *pos) {
    uint32_t n = h->hdr->root;
    while (ss_node_ok(h, n) && !h->nodes[n].is_leaf) {
        SsNode *nd = &h->nodes[n];
        int c = 0;
        while (c < nd->num && r >= nd->counts[c]) { r -= nd->counts[c]; c++; }
        n = nd->children[c];
    }
    *pos = (int)r;
    return ss_node_ok(h, n) ? n : SS_NONE;            /* corrupt child index -> SS_NONE */
}

/* number of entries with score in [min, max] (inclusive). *lo_out (optional, may
   be NULL) receives #{score < min} -- the rank of the first in-range entry -- so
   range_by_score can reuse it instead of recomputing ss_rank_of(min, ...). */
static uint32_t ss_count_in_score(SsHandle *h, double min, double max, uint32_t *lo_out) {
    if (h->hdr->root == SS_NONE || !(min <= max)) { if (lo_out) *lo_out = 0; return 0; }
    uint32_t lo = ss_rank_of(h, min, INT64_MIN);   /* #{score < min} */
    if (lo_out) *lo_out = lo;
    uint32_t hi = ss_rank_of(h, max, INT64_MAX);   /* #{key < (max, INT64_MAX)} */
    double sc;
    if (ss_idx_get(h, INT64_MAX, &sc) && sc == max) hi++;   /* + the (max, INT64_MAX) entry itself */
    return hi - lo;
}

/* result collector: parallel member/score arrays */
typedef struct { int64_t *members; double *scores; size_t n, cap; } ss_rcollect_t;
static int ss_rcollect_push(ss_rcollect_t *c, int64_t m, double s) {
    if (c->n == c->cap) {
        size_t nc = c->cap ? c->cap * 2 : 64;
        int64_t *nm = (int64_t *)realloc(c->members, nc * sizeof(int64_t));
        if (!nm) return 0; c->members = nm;
        double *ns = (double *)realloc(c->scores, nc * sizeof(double));
        if (!ns) return 0; c->scores = ns;
        c->cap = nc;
    }
    c->members[c->n] = m; c->scores[c->n] = s; c->n++;
    return 1;
}

/* collect `len` entries starting at rank `start` (in order, or reversed). The
   caller has clamped [start, start+len) within [0, count]. Returns 0 on OOM. */
static int ss_collect_range(SsHandle *h, uint32_t start, uint32_t len, int reverse, ss_rcollect_t *c) {
    if (len == 0 || h->hdr->root == SS_NONE) return 1;
    int pos;
    uint32_t leaf = ss_at_rank(h, reverse ? (start + len - 1) : start, &pos);
    uint32_t got = 0;
    if (!reverse) {
        while (leaf != SS_NONE && ss_node_ok(h, leaf) && got < len) {
            SsNode *nd = &h->nodes[leaf];
            for (; pos < nd->num && got < len; pos++, got++)
                if (!ss_rcollect_push(c, nd->members[pos], nd->scores[pos])) return 0;
            leaf = nd->next; pos = 0;
        }
    } else {
        while (leaf != SS_NONE && ss_node_ok(h, leaf) && got < len) {
            SsNode *nd = &h->nodes[leaf];
            for (; pos >= 0 && got < len; pos--, got++)
                if (!ss_rcollect_push(c, nd->members[pos], nd->scores[pos])) return 0;
            leaf = nd->prev;
            if (leaf != SS_NONE && ss_node_ok(h, leaf)) pos = h->nodes[leaf].num - 1;
        }
    }
    return 1;
}

#endif /* SORTEDSET_H */

