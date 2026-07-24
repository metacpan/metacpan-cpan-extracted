/*
 * intervaltree.h -- Shared-memory interval tree for Linux
 *
 * A set of integer intervals [lo, hi] with fast overlap queries: which stored
 * intervals contain a point (stabbing), or overlap a query range.  Backed by an
 * augmented balanced BST -- keyed by the low endpoint, each node carrying the
 * maximum high endpoint of its subtree so a query prunes subtrees that end
 * before it.  Intervals are appended in O(1) and the balanced tree is bulk-built
 * on the first query after any insert (so query recursion stays O(log n) deep
 * regardless of insertion order).  The intervals and tree live in a shared
 * mapping so several processes build and query one index; a write-preferring
 * futex rwlock with reader-slot dead-process recovery guards mutation, and
 * queries take only the read lock once the tree is built.
 *
 * Layout: Header -> reader_slots[1024] -> nodes[capacity] -> build_idx[capacity]
 */

#ifndef IT_H
#define IT_H

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
#error "intervaltree.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define IT_MAGIC        0x52545649  /* IntervalTree */
#define IT_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define IT_ERR_BUFLEN   256
#ifndef IT_READER_SLOTS
#define IT_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these IT_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all IT_READER_SLOTS. */
#define IT_OCC_WORDS    (((IT_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define IT_OCC_BYTES    ((uint64_t)IT_OCC_WORDS * 8)      /* 128 bytes */
#define IT_MIN_CAP      1
#define IT_MAX_CAP      0x1000000U        /* 2^24 intervals cap (index fits uint32, < IT_NIL) */
#define IT_NIL          0xFFFFFFFFU       /* empty child / root sentinel */
/* A balanced bulk-built tree over <= 2^24 intervals is <= ~25 deep; this cap is
 * a runaway guard so a Layer-B-corrupted link chain (a cycle, or a degenerate
 * chain of valid indices) cannot recurse a query into a stack overflow. */
#define IT_MAX_DEPTH    96

#define IT_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, IT_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} ItReaderSlot;

struct ItHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t capacity;                /* 8   max intervals */
    uint32_t _pad0;                   /* 12 */
    uint64_t count;                   /* 16  intervals inserted */
    uint32_t root;                    /* 24  root node index, or IT_NIL when empty */
    uint32_t dirty;                   /* 28  1 if the tree needs a (re)build before querying */
    uint64_t nodes_off;               /* 32  offset of the node array */
    uint64_t idx_off;                 /* 40  offset of the build scratch (capacity uint32) */
    uint64_t total_size;              /* 48 */
    uint64_t reader_slots_off;        /* 56 */
    uint32_t wlock;                   /* 64  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 68  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 72  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 80 */
    uint8_t  _pad[168];               /* 88..255 */
};
typedef struct ItHeader ItHeader;

_Static_assert(sizeof(ItHeader) == 256, "ItHeader must be 256 bytes");

/* One interval node: [lo, hi] with a user payload id, plus max_hi = the maximum
 * hi endpoint over this node's whole subtree (the augmentation that lets a query
 * prune subtrees that cannot reach the query point/range).  A balanced BST keyed
 * by lo; left/right are child indices (IT_NIL for none). */
typedef struct {
    int64_t  lo, hi;
    int64_t  max_hi;
    uint64_t payload;
    uint32_t left, right;
} ItNode;
_Static_assert(sizeof(ItNode) == 40, "ItNode must be 40 bytes");

/* ---- Process-local handle ---- */

typedef struct ItHandle {
    ItHeader     *hdr;
    ItReaderSlot *reader_slots;  /* IT_READER_SLOTS entries */
    uint64_t     *occ;           /* IT_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      nodes_off;     /* validated offsets, cached: never re-read from the peer-writable header */
    uint64_t      idx_off;
    uint32_t      capacity;      /* cached */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* it_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} ItHandle;

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

#define IT_RWLOCK_SPIN_LIMIT 32
#define IT_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void it_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define IT_RWLOCK_WRITER_BIT 0x80000000U
#define IT_RWLOCK_PID_MASK   0x7FFFFFFFU
#define IT_RWLOCK_WR(pid)    (IT_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & IT_RWLOCK_PID_MASK))

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
static inline int it_pid_is_zombie(uint32_t pid) {
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
static inline int it_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !it_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void it_recover_stale_lock(ItHandle *h, uint32_t observed_wlock) {
    ItHeader *hdr = h->hdr;
    uint32_t mypid = IT_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec it_lock_timeout = { IT_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t it_fork_gen = 1;
static pthread_once_t it_atfork_once = PTHREAD_ONCE_INIT;
static void it_on_fork_child(void) {
    __atomic_add_fetch(&it_fork_gen, 1, __ATOMIC_RELAXED);
}
static void it_atfork_init(void) {
    pthread_atfork(NULL, NULL, it_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void it_occ_set(ItHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void it_occ_clear(ItHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

static inline void it_claim_reader_slot(ItHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&it_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&it_atfork_once, it_atfork_init);
    /* Re-read after pthread_once: it_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&it_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % IT_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < IT_READER_SLOTS; i++) {
        uint32_t s = (start + i) % IT_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            it_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < IT_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || it_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            it_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void it_recover_after_timeout(ItHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= IT_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & IT_RWLOCK_PID_MASK;
        if (!it_pid_alive(pid))
            it_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void it_park(ItHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void it_unpark(ItHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void it_rdepth_inc(ItHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void it_rdepth_dec(ItHandle *h) {
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
static inline void it_reader_wake_drain(ItHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void it_rwlock_rdlock(ItHandle *h) {
    it_claim_reader_slot(h);
    ItHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            it_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            it_rdepth_dec(h);
            it_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= IT_RWLOCK_WRITER_BIT &&
            !it_pid_alive(cur & IT_RWLOCK_PID_MASK)) {
            it_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < IT_RWLOCK_SPIN_LIMIT, 1)) {
            it_rwlock_spin_pause();
            continue;
        }
        it_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &it_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                it_unpark(h);
                it_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        it_unpark(h);
        spin = 0;
    }
}

static inline void it_rwlock_rdunlock(ItHandle *h) {
    it_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    it_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void it_rwlock_wrlock(ItHandle *h) {
    it_claim_reader_slot(h);  /* refresh cached_pid across fork */
    ItHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = IT_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= IT_RWLOCK_WRITER_BIT &&
            !it_pid_alive(expected & IT_RWLOCK_PID_MASK)) {
            it_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < IT_RWLOCK_SPIN_LIMIT, 1)) {
            it_rwlock_spin_pause();
            continue;
        }
        it_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &it_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                it_unpark(h);
                it_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        it_unpark(h);
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
         * this scan, so no held slot is skipped).  O(IT_OCC_WORDS + live readers)
         * instead of O(IT_READER_SLOTS). */
        for (uint32_t w = 0; w < IT_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!it_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &it_lock_timeout, NULL, 0);
    }
}

static inline void it_rwlock_wrunlock(ItHandle *h) {
    ItHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> nodes[capacity] -> build_idx[capacity]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets.
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> nodes[capacity] -> build_idx[capacity] */
typedef struct { uint64_t reader_slots, occ, nodes, idx, total; } ItLayout;

static inline ItLayout it_layout_for(uint32_t capacity) {
    ItLayout L;
    L.reader_slots = sizeof(ItHeader);
    L.occ          = L.reader_slots + (uint64_t)IT_READER_SLOTS * sizeof(ItReaderSlot);
    L.nodes        = L.occ + IT_OCC_BYTES;
    L.nodes        = (L.nodes + 7) & ~(uint64_t)7;
    L.idx          = L.nodes + (uint64_t)capacity * sizeof(ItNode);
    L.idx          = (L.idx + 7) & ~(uint64_t)7;
    L.total        = L.idx + (uint64_t)capacity * sizeof(uint32_t);
    return L;
}

static inline uint64_t it_total_size(uint32_t capacity) {
    return it_layout_for(capacity).total;
}

static inline void it_init_header(void *base, uint32_t capacity, uint64_t total) {
    ItLayout L = it_layout_for(capacity);
    ItHeader *hdr = (ItHeader *)base;
    memset(base, 0, (size_t)L.nodes);   /* header + reader slots; node data is written on add */
    hdr->magic            = IT_MAGIC;
    hdr->version          = IT_VERSION;
    hdr->capacity         = capacity;
    hdr->count            = 0;
    hdr->root             = IT_NIL;
    hdr->dirty            = 0;
    hdr->nodes_off        = L.nodes;
    hdr->idx_off          = L.idx;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* ---- accessors ---- */
static inline ItNode  *it_node(ItHandle *h, uint64_t i) { return (ItNode *)((char *)h->base + h->nodes_off) + i; }
static inline uint32_t *it_idx(ItHandle *h) { return (uint32_t *)((char *)h->base + h->idx_off); }

/* Layer B trusted bound: number of nodes guaranteed within the real mapping.
 * Equals capacity for a valid tree; every child index read from shared memory is
 * checked against it so a corrupt link can never drive an access out of bounds. */
static inline uint64_t it_nodes_max(ItHandle *h) {
    if (h->nodes_off >= h->mmap_size) return 0;
    return (h->mmap_size - h->nodes_off) / sizeof(ItNode);
}
#define IT_NODE_OK(h, i) ((uint32_t)(i) != IT_NIL && (uint64_t)(i) < (uint64_t)(h)->capacity)

static inline ItHandle *it_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    ItHeader *hdr = (ItHeader *)base;
    ItHandle *h = (ItHandle *)calloc(1, sizeof(ItHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (ItReaderSlot *)((uint8_t *)base + sizeof(ItHeader));  /* trusted layout, not the peer-writable header offset */
    /* Snapshot the geometry ONCE and re-verify it against the mapping, then
     * derive every offset from the TRUSTED computed layout instead of the
     * peer-writable header fields: a writer can flip capacity/idx_off in the
     * window between it_validate_header and here, and idx_off is otherwise
     * never range-checked (it_build_locked writes capacity*4 bytes at it_idx). */
    {
        uint32_t cap = __atomic_load_n(&hdr->capacity, __ATOMIC_ACQUIRE);
        if (cap < IT_MIN_CAP || cap > IT_MAX_CAP ||
            it_total_size(cap) != (uint64_t)map_size) {
            munmap(base, map_size);
            if (backing_fd >= 0) close(backing_fd);
            free(h);
            return NULL;
        }
        ItLayout L = it_layout_for(cap);
        h->occ       = (uint64_t *)((uint8_t *)base + L.occ);
        h->nodes_off = L.nodes;
        h->idx_off   = L.idx;
        h->capacity  = cap;
    }
    h->mmap_size    = map_size;
    /* Layer B: clamp the cached capacity to the number of nodes that actually fit */
    {
        uint64_t fit = it_nodes_max(h);
        if ((uint64_t)h->capacity > fit) h->capacity = (uint32_t)fit;
    }
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by it_create reopen and it_open_fd). */
static inline int it_validate_header(const ItHeader *hdr, uint64_t file_size) {
    if (hdr->magic != IT_MAGIC) return 0;
    if (hdr->version != IT_VERSION) return 0;
    if (hdr->capacity < IT_MIN_CAP || hdr->capacity > IT_MAX_CAP) return 0;
    if (hdr->count > hdr->capacity) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != it_total_size(hdr->capacity)) return 0;
    ItLayout L = it_layout_for(hdr->capacity);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->nodes_off != L.nodes) return 0;
    if (hdr->idx_off != L.idx) return 0;
    return 1;
}

/* validate the requested capacity */
static int it_validate_args(uint64_t capacity, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity < IT_MIN_CAP || capacity > IT_MAX_CAP) { IT_ERR("capacity must be between 1 and 2^24"); return 0; }
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via it_validate_header. */
static int it_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { IT_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        IT_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    IT_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static ItHandle *it_create(const char *path, uint64_t capacity, mode_t mode, char *errbuf) {
    if (!it_validate_args(capacity, errbuf)) return NULL;

    uint64_t total = it_total_size((uint32_t)capacity);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { IT_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = it_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { IT_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { IT_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(ItHeader)) {
            IT_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            IT_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            IT_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { IT_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!it_validate_header((ItHeader *)base, (uint64_t)st.st_size)) {
                IT_ERR("invalid interval tree file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return it_setup(base, map_size, path, -1);
        }
    }
    it_init_header(base, (uint32_t)capacity, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return it_setup(base, map_size, path, -1);
}

static ItHandle *it_create_memfd(const char *name, uint64_t capacity, char *errbuf) {
    if (!it_validate_args(capacity, errbuf)) return NULL;

    uint64_t total = it_total_size((uint32_t)capacity);
    int fd = memfd_create(name ? name : "intervaltree", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { IT_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        IT_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { IT_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    it_init_header(base, (uint32_t)capacity, total);
    return it_setup(base, (size_t)total, NULL, fd);
}

static ItHandle *it_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { IT_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(ItHeader)) { IT_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { IT_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!it_validate_header((ItHeader *)base, (uint64_t)st.st_size)) {
        IT_ERR("invalid interval tree table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { IT_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return it_setup(base, ms, NULL, myfd);
}

static void it_destroy(ItHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&it_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        it_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int it_msync(ItHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Interval-tree operations (callers hold the lock)
 *
 * Intervals are appended O(1) and marked dirty; a balanced BST keyed by the low
 * endpoint is bulk-built on the first query after any insert (sorted once by lo,
 * then median-split), so query recursion is O(log n) deep whatever the insertion
 * order.  Each node carries max_hi = the maximum hi endpoint over its whole
 * subtree, so a query can prune a subtree whose intervals all end before it.
 * Every child index read from shared memory is bounds-checked.
 * ================================================================ */

/* one snapshotted matching interval, for a query result */
typedef struct { uint64_t id; int64_t lo, hi; } ItRes;

/* append an interval [lo,hi] with a payload id; returns its slot, or -1 if the
 * tree is full.  Marks the tree dirty so the next query rebuilds.  (caller holds wrlock) */
static int64_t it_add_locked(ItHandle *h, int64_t lo, int64_t hi, uint64_t payload) {
    uint64_t slot = h->hdr->count;
    if (slot >= h->capacity) return -1;                   /* full */
    ItNode *nd = it_node(h, slot);
    nd->lo = lo; nd->hi = hi; nd->max_hi = hi; nd->payload = payload;
    nd->left = IT_NIL; nd->right = IT_NIL;
    h->hdr->count = slot + 1;
    h->hdr->dirty = 1;
    return (int64_t)slot;
}

/* ---- balanced bulk build (sort once by lo, median split, augment max_hi) ---- */
static int it_cmp_lo(const void *pa, const void *pb, void *arg) {
    ItHandle *h = (ItHandle *)arg;
    uint32_t a = *(const uint32_t *)pa, b = *(const uint32_t *)pb;
    int64_t la = it_node(h, a)->lo, lb = it_node(h, b)->lo;
    if (la < lb) return -1;
    if (la > lb) return  1;
    return (a < b) ? -1 : (a > b ? 1 : 0);                /* stable tiebreak */
}

/* build a balanced subtree over the already-lo-sorted idx[lo..hi]; returns the
 * subtree root and sets its max_hi from its own hi and its children's max_hi. */
static uint32_t it_build_rec(ItHandle *h, uint32_t *idx, int64_t lo, int64_t hi) {
    if (lo > hi) return IT_NIL;
    int64_t mid = lo + (hi - lo) / 2;
    uint32_t node = idx[mid];
    uint32_t l = it_build_rec(h, idx, lo, mid - 1);
    uint32_t r = it_build_rec(h, idx, mid + 1, hi);
    ItNode *nd = it_node(h, node);
    nd->left = l; nd->right = r;
    int64_t mx = nd->hi;
    if (l != IT_NIL && it_node(h, l)->max_hi > mx) mx = it_node(h, l)->max_hi;
    if (r != IT_NIL && it_node(h, r)->max_hi > mx) mx = it_node(h, r)->max_hi;
    nd->max_hi = mx;
    return node;
}

/* (re)build a balanced tree over all inserted intervals (caller holds wrlock) */
static void it_build_locked(ItHandle *h) {
    uint64_t n = h->hdr->count;
    if (n > h->capacity) n = h->capacity;                 /* Layer B */
    if (n == 0) { h->hdr->root = IT_NIL; h->hdr->dirty = 0; return; }
    uint32_t *idx = it_idx(h);                             /* scratch region inside the mapping */
    for (uint64_t i = 0; i < n; i++) idx[i] = (uint32_t)i;
    qsort_r(idx, (size_t)n, sizeof(uint32_t), it_cmp_lo, h);   /* sort by lo once (subranges stay sorted) */
    h->hdr->root = it_build_rec(h, idx, 0, (int64_t)n - 1);
    h->hdr->dirty = 0;
}

/* ---- overlap query: collect intervals [lo,hi] intersecting [ql,qh] (a point
 * stab is ql==qh).  Overlap iff lo <= qh && hi >= ql. ---- */
static void it_overlaps_rec(ItHandle *h, uint32_t node, int64_t ql, int64_t qh, uint32_t depth,
                            ItRes *out, uint64_t *cnt, uint64_t cap, uint64_t *budget) {
    if (!IT_NODE_OK(h, node) || depth > IT_MAX_DEPTH) return;   /* Layer B: bounds + recursion depth */
    if (*budget == 0) return;    /* runaway guard: a corrupt tree (cycle/diamond of valid indices)
                                  * can revisit a node exponentially; the depth cap bounds stack
                                  * depth but not total work.  A valid tree makes <= 2n+1 calls, so
                                  * this budget never trips on legitimate data. */
    (*budget)--;
    ItNode *nd = it_node(h, node);
    if (nd->max_hi < ql) return;                          /* whole subtree ends before ql -> prune */
    it_overlaps_rec(h, nd->left, ql, qh, depth + 1, out, cnt, cap, budget);   /* left subtree may overlap */
    if (nd->lo <= qh && nd->hi >= ql && *cnt < cap) {     /* this interval overlaps [ql,qh] */
        out[*cnt].id = nd->payload; out[*cnt].lo = nd->lo; out[*cnt].hi = nd->hi; (*cnt)++;
    }
    if (nd->lo <= qh)                                     /* right lo's >= node.lo; skip if node.lo > qh */
        it_overlaps_rec(h, nd->right, ql, qh, depth + 1, out, cnt, cap, budget);
}

static uint64_t it_overlaps_locked(ItHandle *h, int64_t ql, int64_t qh, ItRes *out, uint64_t cap) {
    uint64_t cnt = 0;
    uint64_t budget = 2 * (uint64_t)h->capacity + 1;   /* valid tree visits each node once (<=2n+1 calls) */
    it_overlaps_rec(h, h->hdr->root, ql, qh, 0, out, &cnt, cap, &budget);
    return cnt;
}

/* reset to an empty tree (caller holds the write lock) */
static inline void it_clear_locked(ItHandle *h) {
    h->hdr->count = 0;
    h->hdr->root  = IT_NIL;
    h->hdr->dirty = 0;
}

#endif /* IT_H */
