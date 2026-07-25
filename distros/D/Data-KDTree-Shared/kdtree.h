/*
 * kdtree.h -- Shared-memory k-d tree for Linux
 *
 * Spatial index over points in up to 16 dimensions: nearest-neighbour,
 * k-nearest, axis-aligned box (range), and radius (ball) queries.  Points are
 * appended in O(1) and a balanced tree is bulk-built by median split on the
 * first query after any insert, so query recursion stays O(log n) deep
 * regardless of insertion order.  The points and tree live in a shared mapping
 * so several processes build and query one index; a write-preferring futex
 * rwlock with reader-slot dead-process recovery guards mutation, and queries
 * take only the read lock once the tree is built.
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> nodes[capacity] -> build_idx[capacity]
 */

#ifndef KD_H
#define KD_H

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
#error "kdtree.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define KD_MAGIC        0x5254444B  /* KDTree */
#define KD_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define KD_ERR_BUFLEN   256
#ifndef KD_READER_SLOTS
#define KD_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these KD_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all KD_READER_SLOTS. */
#define KD_OCC_WORDS    (((KD_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define KD_OCC_BYTES    ((uint64_t)KD_OCC_WORDS * 8)      /* 128 bytes */
#define KD_MIN_DIMS     1
#define KD_MAX_DIMS     16               /* max spatial dimensions */
#define KD_MIN_CAP      1
#define KD_MAX_CAP      0x1000000U        /* 2^24 points cap (index fits uint32, < KD_NIL) */
#define KD_NIL          0xFFFFFFFFU       /* empty child / root sentinel */
/* A balanced bulk-built tree over <= 2^24 points is <= ~25 deep; this cap is a
 * runaway guard so a Layer-B-corrupted link chain (a cycle, or a degenerate
 * chain of valid indices) cannot recurse a query into a stack overflow. */
#define KD_MAX_DEPTH    96

#define KD_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, KD_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} KdReaderSlot;

struct KdHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t dims;                    /* 8   number of spatial dimensions */
    uint32_t capacity;                /* 12  max points */
    uint64_t count;                   /* 16  points inserted */
    uint32_t root;                    /* 24  root node index, or KD_NIL when empty */
    uint32_t dirty;                   /* 28  1 if the tree needs a (re)build before querying */
    uint64_t node_stride;             /* 32  bytes per node (dims*8 + 16) */
    uint64_t nodes_off;               /* 40  offset of the node array */
    uint64_t idx_off;                 /* 48  offset of the build scratch (capacity uint32) */
    uint64_t total_size;              /* 56 */
    uint64_t reader_slots_off;        /* 64 */
    uint32_t wlock;                   /* 72  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 76  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 80  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct KdHeader KdHeader;

_Static_assert(sizeof(KdHeader) == 256, "KdHeader must be 256 bytes");

/* Node layout (variable, stride = dims*8 + 16, always 8-aligned):
 *   [dims doubles: coords][uint64 payload id][uint32 left][uint32 right]      */

/* ---- Process-local handle ---- */

typedef struct KdHandle {
    KdHeader     *hdr;
    KdReaderSlot *reader_slots;  /* KD_READER_SLOTS entries */
    uint64_t     *occ;           /* KD_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      nodes_off;     /* validated store offsets, cached: never re-read from the peer-writable header */
    uint64_t      idx_off;
    uint64_t      node_stride;   /* cached */
    uint32_t      dims;          /* cached */
    uint32_t      capacity;      /* cached */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* kd_fork_gen value at last slot claim */
    uint32_t slotless_held; /* rwlock read-locks held with no reader-slot */
} KdHandle;

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

#define KD_RWLOCK_SPIN_LIMIT 32
#define KD_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void kd_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define KD_RWLOCK_WRITER_BIT 0x80000000U
#define KD_RWLOCK_PID_MASK   0x7FFFFFFFU
#define KD_RWLOCK_WR(pid)    (KD_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & KD_RWLOCK_PID_MASK))

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
static inline int kd_pid_is_zombie(uint32_t pid) {
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
static inline int kd_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !kd_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void kd_recover_stale_lock(KdHandle *h, uint32_t observed_wlock) {
    KdHeader *hdr = h->hdr;
    uint32_t mypid = KD_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec kd_lock_timeout = { KD_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t kd_fork_gen = 1;
static pthread_once_t kd_atfork_once = PTHREAD_ONCE_INIT;
static void kd_on_fork_child(void) {
    __atomic_add_fetch(&kd_fork_gen, 1, __ATOMIC_RELAXED);
}
static void kd_atfork_init(void) {
    pthread_atfork(NULL, NULL, kd_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void kd_occ_set(KdHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void kd_occ_clear(KdHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so that
 * fork()'d children pick up their own slot lazily instead of sharing the
 * parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void kd_claim_reader_slot(KdHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&kd_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&kd_atfork_once, kd_atfork_init);
    /* Re-read after pthread_once: kd_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&kd_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % KD_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < KD_READER_SLOTS; i++) {
        uint32_t s = (start + i) % KD_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            kd_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < KD_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || kd_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            kd_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void kd_recover_after_timeout(KdHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= KD_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & KD_RWLOCK_PID_MASK;
        if (!kd_pid_alive(pid))
            kd_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void kd_park(KdHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void kd_unpark(KdHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void kd_rdepth_inc(KdHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void kd_rdepth_dec(KdHandle *h) {
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
static inline void kd_reader_wake_drain(KdHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void kd_rwlock_rdlock(KdHandle *h) {
    kd_claim_reader_slot(h);
    KdHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            kd_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            kd_rdepth_dec(h);
            kd_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= KD_RWLOCK_WRITER_BIT &&
            !kd_pid_alive(cur & KD_RWLOCK_PID_MASK)) {
            kd_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < KD_RWLOCK_SPIN_LIMIT, 1)) {
            kd_rwlock_spin_pause();
            continue;
        }
        kd_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &kd_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                kd_unpark(h);
                kd_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        kd_unpark(h);
        spin = 0;
    }
}

static inline void kd_rwlock_rdunlock(KdHandle *h) {
    kd_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    kd_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void kd_rwlock_wrlock(KdHandle *h) {
    kd_claim_reader_slot(h);  /* refresh cached_pid across fork */
    KdHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = KD_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= KD_RWLOCK_WRITER_BIT &&
            !kd_pid_alive(expected & KD_RWLOCK_PID_MASK)) {
            kd_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < KD_RWLOCK_SPIN_LIMIT, 1)) {
            kd_rwlock_spin_pause();
            continue;
        }
        kd_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &kd_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                kd_unpark(h);
                kd_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        kd_unpark(h);
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
         * this scan, so no held slot is skipped).  O(KD_OCC_WORDS + live readers)
         * instead of O(KD_READER_SLOTS). */
        for (uint32_t w = 0; w < KD_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!kd_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &kd_lock_timeout, NULL, 0);
    }
}

static inline void kd_rwlock_wrunlock(KdHandle *h) {
    KdHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> nodes[capacity] -> build_idx[capacity]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets.
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> nodes[capacity] -> build_idx[capacity] */
typedef struct { uint64_t reader_slots, occ, nodes, idx, total; } KdLayout;

static inline uint64_t kd_stride(uint32_t dims) {
    return (uint64_t)dims * sizeof(double) + 2 * sizeof(uint32_t) + sizeof(uint64_t);  /* coords + left/right + payload */
}

static inline KdLayout kd_layout_for(uint32_t dims, uint32_t capacity) {
    KdLayout L;
    uint64_t stride = kd_stride(dims);
    L.reader_slots = sizeof(KdHeader);
    L.occ          = L.reader_slots + (uint64_t)KD_READER_SLOTS * sizeof(KdReaderSlot);
    L.nodes        = L.occ + KD_OCC_BYTES;
    L.nodes        = (L.nodes + 7) & ~(uint64_t)7;
    L.idx          = L.nodes + (uint64_t)capacity * stride;
    L.idx          = (L.idx + 7) & ~(uint64_t)7;
    L.total        = L.idx + (uint64_t)capacity * sizeof(uint32_t);
    return L;
}

static inline uint64_t kd_total_size(uint32_t dims, uint32_t capacity) {
    return kd_layout_for(dims, capacity).total;
}

static inline void kd_init_header(void *base, uint32_t dims, uint32_t capacity, uint64_t total) {
    KdLayout L = kd_layout_for(dims, capacity);
    KdHeader *hdr = (KdHeader *)base;
    memset(base, 0, (size_t)L.nodes);   /* header + reader slots; node data is written on add */
    hdr->magic            = KD_MAGIC;
    hdr->version          = KD_VERSION;
    hdr->dims             = dims;
    hdr->capacity         = capacity;
    hdr->count            = 0;
    hdr->root             = KD_NIL;
    hdr->dirty            = 0;
    hdr->node_stride      = kd_stride(dims);
    hdr->nodes_off        = L.nodes;
    hdr->idx_off          = L.idx;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* ---- node accessors ---- */
static inline char    *kd_node(KdHandle *h, uint64_t i) { return (char *)h->base + h->nodes_off + i * h->node_stride; }
static inline double  *kd_coords(KdHandle *h, uint64_t i) { return (double *)kd_node(h, i); }
static inline uint64_t *kd_payload(KdHandle *h, uint64_t i) { return (uint64_t *)(kd_node(h, i) + (uint64_t)h->dims * sizeof(double)); }
static inline uint32_t *kd_left(KdHandle *h, uint64_t i)  { return (uint32_t *)(kd_node(h, i) + (uint64_t)h->dims * sizeof(double) + sizeof(uint64_t)); }
static inline uint32_t *kd_right(KdHandle *h, uint64_t i) { return (uint32_t *)(kd_node(h, i) + (uint64_t)h->dims * sizeof(double) + sizeof(uint64_t) + sizeof(uint32_t)); }
static inline uint32_t *kd_idx(KdHandle *h) { return (uint32_t *)((char *)h->base + h->idx_off); }

/* Layer B trusted bound: number of nodes guaranteed within the real mapping.
 * Equals capacity for a valid tree; every child index read from shared memory is
 * checked against it so a corrupt link can never drive an access out of bounds. */
static inline uint64_t kd_nodes_max(KdHandle *h) {
    if (h->nodes_off >= h->mmap_size || h->node_stride == 0) return 0;
    return (h->mmap_size - h->nodes_off) / h->node_stride;
}
#define KD_NODE_OK(h, i) ((uint32_t)(i) != KD_NIL && (uint64_t)(i) < (uint64_t)(h)->capacity)

static inline KdHandle *kd_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    KdHeader *hdr = (KdHeader *)base;
    KdHandle *h = (KdHandle *)calloc(1, sizeof(KdHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (KdReaderSlot *)((uint8_t *)base + sizeof(KdHeader));  /* trusted layout, not the peer-writable header offset */
    /* occ sits at a FIXED offset (header + reader_slots[]), independent of
     * dims/capacity, so compute it from trusted constants, not the peer header. */
    h->occ          = (uint64_t *)((uint8_t *)base + sizeof(KdHeader)
                                   + (uint64_t)KD_READER_SLOTS * sizeof(KdReaderSlot));
    h->nodes_off    = hdr->nodes_off;   /* single validated read of each geometry field */
    h->nodes_off    = hdr->nodes_off;   /* single validated read of each geometry field */
    h->idx_off      = hdr->idx_off;
    h->node_stride  = hdr->node_stride;
    h->dims         = hdr->dims;
    h->capacity     = hdr->capacity;
    h->mmap_size    = map_size;
    /* Layer B: clamp the cached capacity to the number of nodes that actually fit */
    {
        uint64_t fit = kd_nodes_max(h);
        if ((uint64_t)h->capacity > fit) h->capacity = (uint32_t)fit;
    }
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by kd_create reopen and kd_open_fd). */
static inline int kd_validate_header(const KdHeader *hdr, uint64_t file_size) {
    if (hdr->magic != KD_MAGIC) return 0;
    if (hdr->version != KD_VERSION) return 0;
    if (hdr->dims < KD_MIN_DIMS || hdr->dims > KD_MAX_DIMS) return 0;
    if (hdr->capacity < KD_MIN_CAP || hdr->capacity > KD_MAX_CAP) return 0;
    if (hdr->count > hdr->capacity) return 0;
    if (hdr->node_stride != kd_stride(hdr->dims)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != kd_total_size(hdr->dims, hdr->capacity)) return 0;
    KdLayout L = kd_layout_for(hdr->dims, hdr->capacity);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->nodes_off != L.nodes) return 0;
    if (hdr->idx_off != L.idx) return 0;
    return 1;
}

/* validate the requested dims + capacity */
static int kd_validate_args(uint64_t dims, uint64_t capacity, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (dims < KD_MIN_DIMS || dims > KD_MAX_DIMS) { KD_ERR("dims must be between 1 and 16"); return 0; }
    if (capacity < KD_MIN_CAP || capacity > KD_MAX_CAP) { KD_ERR("capacity must be between 1 and 2^24"); return 0; }
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via kd_validate_header. */
static int kd_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { KD_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        KD_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    KD_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static KdHandle *kd_create(const char *path, uint64_t dims, uint64_t capacity, mode_t mode, char *errbuf) {
    if (!kd_validate_args(dims, capacity, errbuf)) return NULL;

    uint64_t total = kd_total_size((uint32_t)dims, (uint32_t)capacity);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { KD_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = kd_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { KD_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { KD_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(KdHeader)) {
            KD_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            KD_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            KD_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { KD_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!kd_validate_header((KdHeader *)base, (uint64_t)st.st_size)) {
                KD_ERR("invalid k-d tree file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return kd_setup(base, map_size, path, -1);
        }
    }
    kd_init_header(base, (uint32_t)dims, (uint32_t)capacity, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return kd_setup(base, map_size, path, -1);
}

static KdHandle *kd_create_memfd(const char *name, uint64_t dims, uint64_t capacity, char *errbuf) {
    if (!kd_validate_args(dims, capacity, errbuf)) return NULL;

    uint64_t total = kd_total_size((uint32_t)dims, (uint32_t)capacity);
    int fd = memfd_create(name ? name : "kdtree", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { KD_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        KD_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { KD_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    kd_init_header(base, (uint32_t)dims, (uint32_t)capacity, total);
    return kd_setup(base, (size_t)total, NULL, fd);
}

static KdHandle *kd_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { KD_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(KdHeader)) { KD_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { KD_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!kd_validate_header((KdHeader *)base, (uint64_t)st.st_size)) {
        KD_ERR("invalid k-d tree table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { KD_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return kd_setup(base, ms, NULL, myfd);
}

static void kd_destroy(KdHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&kd_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        kd_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int kd_msync(KdHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * k-d tree operations (callers hold the lock)
 *
 * Points are appended O(1) and marked dirty; a balanced tree is bulk-built by
 * median split on the first query after any insert, so query recursion is
 * O(log n) deep whatever the insertion order.  Nearest / k-nearest use a bounded
 * max-heap with plane-distance pruning; range and radius prune by the splitting
 * plane.  Every child index read from shared memory is bounds-checked.
 * ================================================================ */

/* squared Euclidean distance from node `node`'s coords to query point q */
static inline double kd_dist2_to(KdHandle *h, uint64_t node, const double *q) {
    double *c = kd_coords(h, node);
    double s = 0.0;
    for (uint32_t d = 0; d < h->dims; d++) { double diff = c[d] - q[d]; s += diff * diff; }
    return s;
}

/* append a point; returns its slot index, or -1 if the tree is full.  Marks the
 * tree dirty so the next query rebuilds a balanced tree.  (caller holds wrlock) */
static int64_t kd_add_locked(KdHandle *h, const double *coords, uint64_t payload) {
    uint64_t slot = h->hdr->count;
    if (slot >= h->capacity) return -1;                   /* full */
    double *c = kd_coords(h, slot);
    for (uint32_t d = 0; d < h->dims; d++) c[d] = coords[d];
    *kd_payload(h, slot) = payload;
    *kd_left(h, slot)    = KD_NIL;
    *kd_right(h, slot)   = KD_NIL;
    h->hdr->count = slot + 1;
    h->hdr->dirty = 1;
    return (int64_t)slot;
}

/* ---- balanced bulk build (median split on a cycling axis) ---- */
typedef struct { KdHandle *h; uint32_t axis; } KdCmpCtx;

static int kd_cmp_axis(const void *pa, const void *pb, void *arg) {
    KdCmpCtx *ctx = (KdCmpCtx *)arg;
    uint32_t a = *(const uint32_t *)pa, b = *(const uint32_t *)pb;
    double va = kd_coords(ctx->h, a)[ctx->axis];
    double vb = kd_coords(ctx->h, b)[ctx->axis];
    if (va < vb) return -1;
    if (va > vb) return  1;
    return (a < b) ? -1 : (a > b ? 1 : 0);                /* stable tiebreak */
}

static uint32_t kd_build_rec(KdHandle *h, uint32_t *idx, int64_t lo, int64_t hi, uint32_t depth) {
    if (lo > hi) return KD_NIL;
    KdCmpCtx ctx = { h, depth % h->dims };
    qsort_r(idx + lo, (size_t)(hi - lo + 1), sizeof(uint32_t), kd_cmp_axis, &ctx);
    int64_t mid = lo + (hi - lo) / 2;
    uint32_t node = idx[mid];
    *kd_left(h, node)  = kd_build_rec(h, idx, lo, mid - 1, depth + 1);
    *kd_right(h, node) = kd_build_rec(h, idx, mid + 1, hi, depth + 1);
    return node;
}

/* (re)build a balanced tree over all inserted points (caller holds wrlock) */
static void kd_build_locked(KdHandle *h) {
    uint64_t n = h->hdr->count;
    if (n > h->capacity) n = h->capacity;                 /* Layer B */
    if (n == 0) { h->hdr->root = KD_NIL; h->hdr->dirty = 0; return; }
    uint32_t *idx = kd_idx(h);                             /* scratch region inside the mapping */
    for (uint64_t i = 0; i < n; i++) idx[i] = (uint32_t)i;
    h->hdr->root = kd_build_rec(h, idx, 0, (int64_t)n - 1, 0);
    h->hdr->dirty = 0;
}

/* ---- k-nearest search via a bounded max-heap of the m best (farthest at 0) ---- */
typedef struct { uint64_t id; double dist2; } KdRes;

static void kd_heap_offer(KdRes *heap, uint64_t *cnt, uint64_t m, uint64_t id, double d2) {
    if (*cnt < m) {                                        /* grow the heap */
        uint64_t i = (*cnt)++;
        heap[i].id = id; heap[i].dist2 = d2;
        while (i > 0) { uint64_t p = (i - 1) / 2;
            if (heap[p].dist2 >= heap[i].dist2) break;
            KdRes t = heap[p]; heap[p] = heap[i]; heap[i] = t; i = p; }
    } else if (m > 0 && d2 < heap[0].dist2) {              /* replace the current farthest */
        heap[0].id = id; heap[0].dist2 = d2;
        uint64_t i = 0;
        for (;;) { uint64_t l = 2*i+1, r = 2*i+2, big = i;
            if (l < m && heap[l].dist2 > heap[big].dist2) big = l;
            if (r < m && heap[r].dist2 > heap[big].dist2) big = r;
            if (big == i) break;
            KdRes t = heap[big]; heap[big] = heap[i]; heap[i] = t; i = big; }
    }
}

static void kd_knn_rec(KdHandle *h, uint32_t node, const double *q, uint32_t depth,
                       KdRes *heap, uint64_t *cnt, uint64_t m, uint64_t *budget) {
    if (!KD_NODE_OK(h, node) || depth > KD_MAX_DEPTH) return;   /* Layer B: bound recursion depth */
    if (*budget == 0) return; (*budget)--;   /* runaway guard: bound total work, not just depth (a corrupt cyclic/diamond tree) */
    kd_heap_offer(heap, cnt, m, *kd_payload(h, node), kd_dist2_to(h, node, q));
    uint32_t axis = depth % h->dims;
    double diff = q[axis] - kd_coords(h, node)[axis];
    uint32_t near = (diff < 0) ? *kd_left(h, node)  : *kd_right(h, node);
    uint32_t far  = (diff < 0) ? *kd_right(h, node) : *kd_left(h, node);
    kd_knn_rec(h, near, q, depth + 1, heap, cnt, m, budget);
    if (*cnt < m || diff * diff < heap[0].dist2)          /* the far side may hold a closer point */
        kd_knn_rec(h, far, q, depth + 1, heap, cnt, m, budget);
}

/* fill up to m nearest points to q into heap[]; returns the number found.
 * heap must have room for m entries.  (caller holds a query lock) */
static uint64_t kd_knn_locked(KdHandle *h, const double *q, uint64_t m, KdRes *heap) {
    uint64_t cnt = 0, budget = 2 * (uint64_t)h->capacity + 1;   /* a valid tree visits each node once */
    if (m == 0) return 0;
    kd_knn_rec(h, h->hdr->root, q, 0, heap, &cnt, m, &budget);
    return cnt;
}

/* ---- axis-aligned box (range) search ---- */
static void kd_range_rec(KdHandle *h, uint32_t node, const double *lo, const double *hi,
                         uint32_t depth, uint64_t *out, uint64_t *cnt, uint64_t cap, uint64_t *budget) {
    if (!KD_NODE_OK(h, node) || depth > KD_MAX_DEPTH) return;   /* Layer B: bound recursion depth */
    if (*budget == 0) return; (*budget)--;   /* runaway guard: bound total work, not just depth */
    double *c = kd_coords(h, node);
    int inside = 1;
    for (uint32_t d = 0; d < h->dims; d++) if (c[d] < lo[d] || c[d] > hi[d]) { inside = 0; break; }
    if (inside && *cnt < cap) out[(*cnt)++] = *kd_payload(h, node);
    uint32_t axis = depth % h->dims;
    if (lo[axis] <= c[axis]) kd_range_rec(h, *kd_left(h, node),  lo, hi, depth + 1, out, cnt, cap, budget);
    if (hi[axis] >= c[axis]) kd_range_rec(h, *kd_right(h, node), lo, hi, depth + 1, out, cnt, cap, budget);
}

static uint64_t kd_range_locked(KdHandle *h, const double *lo, const double *hi,
                                uint64_t *out, uint64_t cap) {
    uint64_t cnt = 0, budget = 2 * (uint64_t)h->capacity + 1;   /* a valid tree visits each node once */
    kd_range_rec(h, h->hdr->root, lo, hi, 0, out, &cnt, cap, &budget);
    return cnt;
}

/* ---- radius (ball) search ---- */
static void kd_radius_rec(KdHandle *h, uint32_t node, const double *q, double r, double r2,
                          uint32_t depth, KdRes *out, uint64_t *cnt, uint64_t cap, uint64_t *budget) {
    if (!KD_NODE_OK(h, node) || depth > KD_MAX_DEPTH) return;   /* Layer B: bound recursion depth */
    if (*budget == 0) return; (*budget)--;   /* runaway guard: bound total work, not just depth */
    double d2 = kd_dist2_to(h, node, q);
    if (d2 <= r2 && *cnt < cap) { out[*cnt].id = *kd_payload(h, node); out[*cnt].dist2 = d2; (*cnt)++; }
    uint32_t axis = depth % h->dims;
    double c = kd_coords(h, node)[axis];
    if (q[axis] - r <= c) kd_radius_rec(h, *kd_left(h, node),  q, r, r2, depth + 1, out, cnt, cap, budget);
    if (q[axis] + r >= c) kd_radius_rec(h, *kd_right(h, node), q, r, r2, depth + 1, out, cnt, cap, budget);
}

static uint64_t kd_radius_locked(KdHandle *h, const double *q, double r,
                                 KdRes *out, uint64_t cap) {
    uint64_t cnt = 0, budget = 2 * (uint64_t)h->capacity + 1;   /* a valid tree visits each node once */
    kd_radius_rec(h, h->hdr->root, q, r, r * r, 0, out, &cnt, cap, &budget);
    return cnt;
}

/* reset to an empty tree (caller holds the write lock) */
static inline void kd_clear_locked(KdHandle *h) {
    h->hdr->count = 0;
    h->hdr->root  = KD_NIL;
    h->hdr->dirty = 0;
}

#endif /* KD_H */
