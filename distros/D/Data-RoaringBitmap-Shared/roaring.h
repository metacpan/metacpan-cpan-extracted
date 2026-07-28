/*
 * roaring.h -- Shared-memory Roaring bitmap (compressed uint32 set) for Linux
 *
 * A Roaring bitmap is a compressed set of 32-bit unsigned integers. The 32-bit
 * space is split into 65536 buckets keyed by the high 16 bits; each bucket holds
 * the low 16 bits of its members in one of two container kinds, chosen by
 * density:
 *
 *   - array container : a SORTED ascending uint16 array (good when the bucket is
 *                       sparse, <= 4096 elements).
 *   - bitmap container: a 65536-bit bitmap (good when the bucket is dense).
 *
 * A bucket starts as an array and is converted to a bitmap once it would exceed
 * RB_ARRAY_MAX (4096) elements. Both kinds occupy one fixed 8192-byte slot
 * (4096 * sizeof(uint16) == 1024 * sizeof(uint64) == 8192), drawn from a slot
 * pool with a freelist, so several processes share one bitmap in a shared
 * mapping. A write-preferring futex rwlock with reader-slot dead-process
 * recovery guards mutation.
 *
 * contains / cardinality / min / max / to_array are pure reads under the READ
 * lock; add / remove / clear / union / intersect take the WRITE lock.
 *
 * v1 scope: array + bitmap containers (no run containers); union and intersect
 * only (no xor / andnot yet); bitmap containers are NOT down-converted to arrays
 * on removal.
 *
 * Layout: Header -> reader_slots[1024] -> occ_bitmap -> bucket_table[65536] -> container_pool[container_cap]
 */

#ifndef ROARING_H
#define ROARING_H

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
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <sys/random.h>
#include <linux/futex.h>
#include <pthread.h>

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "roaring.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define RB_MAGIC          0x474E5252U  /* "RRNG" (little-endian) */
#define RB_VERSION        2   /* 2: added the occupancy bitmap region (layout change) */
#define RB_ERR_BUFLEN     256
#define RB_READER_SLOTS   1024         /* max concurrent reader processes for dead-process recovery */

/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these RB_OCC_WORDS words to visit only
 * OCCUPIED slots (O(words + live readers)) instead of all RB_READER_SLOTS. */
#define RB_OCC_WORDS      (((RB_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define RB_OCC_BYTES      ((uint64_t)RB_OCC_WORDS * 8)      /* 128 bytes */
#define RB_NUM_BUCKETS    65536u       /* one bucket per high-16 value */
#define RB_CONTAINER_BYTES 8192u       /* 4096*2 == 1024*8: array and bitmap share this size */
#define RB_ARRAY_MAX      4096u        /* convert array -> bitmap when an array would exceed this */
#define RB_MAX_CONTAINERS (1u << 20)   /* container-pool ceiling; slot index 0 is the NULL sentinel */

/* Container types (stored in bucket_table[hi].type) */
#define RB_TYPE_NONE   0u
#define RB_TYPE_ARRAY  1u
#define RB_TYPE_BITMAP 2u

#define RB_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, RB_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

/* ================================================================
 * Structs
 * ================================================================ */

/* Direct-indexed bucket entry, one per high-16 value.  container_off == 0 means
 * the bucket is empty (slot index 0 is the reserved NULL sentinel, never a real
 * container).  When non-empty, container_off is the 1-based slot index into the
 * container pool and `type` selects the interpretation of that slot. */
typedef struct {
    uint32_t container_off;   /* 1-based slot index; 0 == empty bucket */
    uint32_t cardinality;     /* number of members in this bucket (1..65536) */
    uint32_t type;            /* RB_TYPE_NONE / RB_TYPE_ARRAY / RB_TYPE_BITMAP */
    uint32_t _pad;            /* pad to 16 bytes for clean alignment */
} RbBucket;

_Static_assert(sizeof(RbBucket) == 16, "RbBucket must be 16 bytes");

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
} RbReaderSlot;

struct RbHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t container_cap;           /* 8   container-pool capacity (slots, incl. NULL sentinel) */
    uint32_t container_used;          /* 12  1-based high-water of slots allocated since creation/last clear (slot 0 reserved) */
    uint32_t free_head;               /* 16  freelist head (slot index, 0 == empty) */
    uint32_t free_count;              /* 20  number of slots on the freelist (O(1) capacity check) */
    uint64_t bitmap_id;               /* 24  per-bitmap identity (random, set once at create, never 0);
                                       *      orders set-op lock acquisition consistently across processes */
    uint64_t cardinality;             /* 32  TOTAL elements across all buckets */
    uint64_t total_size;              /* 40 */
    uint64_t reader_slots_off;        /* 48 */
    uint64_t bucket_table_off;        /* 56 */
    uint64_t container_pool_off;      /* 64 */
    uint32_t wlock;                   /* 72  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 76  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 80  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* 84  readers holding with no reader-slot (documented residual); also aligns stat_ops */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad1[160];              /* 96..255 */
};
typedef struct RbHeader RbHeader;

_Static_assert(sizeof(RbHeader) == 256, "RbHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct RbHandle {
    RbHeader     *hdr;
    RbReaderSlot *reader_slots;   /* RB_READER_SLOTS entries */
    uint64_t     *occ;            /* RB_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    RbBucket     *bucket_table;   /* cached from trusted layout, not the peer-writable header offset */
    uint8_t      *pool;           /* cached container-pool base (trusted layout) */
    void         *base;           /* mmap base */
    size_t        mmap_size;
    char         *path;           /* backing file path (strdup'd) */
    int           backing_fd;     /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      container_cap;  /* cached fixed geometry, validated in range at attach */
    uint32_t      my_slot_idx;    /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;     /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen;/* rb_fork_gen value at last slot claim */
    uint32_t      slotless_held;  /* read-locks this process holds with no reader-slot */
} RbHandle;

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

#define RB_RWLOCK_SPIN_LIMIT 32
#define RB_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void rb_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define RB_RWLOCK_WRITER_BIT 0x80000000U
#define RB_RWLOCK_PID_MASK   0x7FFFFFFFU
#define RB_RWLOCK_WR(pid)    (RB_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & RB_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Documented under "Crash Safety". */
/* A zombie (dead but not yet reaped) still answers kill(pid,0) as alive, so a
 * process that crashed while holding the lock and lingers unreaped would never
 * be recovered.  Treat /proc/<pid>/stat state 'Z' as dead.  Linux-only (as is
 * this module); if /proc is unreadable we fall back to "alive" (safe: we never
 * force-recover a possibly-live holder). */
static inline int rb_pid_is_zombie(uint32_t pid) {
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
static inline int rb_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !rb_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void rb_recover_stale_lock(RbHandle *h, uint32_t observed_wlock) {
    RbHeader *hdr = h->hdr;
    uint32_t mypid = RB_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec rb_lock_timeout = { RB_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t rb_fork_gen = 1;
static pthread_once_t rb_atfork_once = PTHREAD_ONCE_INIT;
static void rb_on_fork_child(void) {
    __atomic_add_fetch(&rb_fork_gen, 1, __ATOMIC_RELAXED);
}
static void rb_atfork_init(void) {
    pthread_atfork(NULL, NULL, rb_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void rb_occ_set(RbHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void rb_occ_clear(RbHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
/* Ensure this process owns a reader slot.  Called from the lock helpers so that
 * fork()'d children pick up their own slot lazily instead of sharing the
 * parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void rb_claim_reader_slot(RbHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&rb_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&rb_atfork_once, rb_atfork_init);
    /* Re-read after pthread_once: rb_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&rb_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % RB_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < RB_READER_SLOTS; i++) {
        uint32_t s = (start + i) % RB_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            rb_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < RB_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || rb_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            rb_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void rb_recover_after_timeout(RbHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= RB_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & RB_RWLOCK_PID_MASK;
        if (!rb_pid_alive(pid))
            rb_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void rb_park(RbHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void rb_unpark(RbHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void rb_rdepth_inc(RbHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void rb_rdepth_dec(RbHandle *h) {
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
static inline void rb_reader_wake_drain(RbHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void rb_rwlock_rdlock(RbHandle *h) {
    rb_claim_reader_slot(h);
    RbHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            rb_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            rb_rdepth_dec(h);
            rb_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= RB_RWLOCK_WRITER_BIT &&
            !rb_pid_alive(cur & RB_RWLOCK_PID_MASK)) {
            rb_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < RB_RWLOCK_SPIN_LIMIT, 1)) {
            rb_rwlock_spin_pause();
            continue;
        }
        rb_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &rb_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                rb_unpark(h);
                rb_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        rb_unpark(h);
        spin = 0;
    }
}

static inline void rb_rwlock_rdunlock(RbHandle *h) {
    rb_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    rb_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void rb_rwlock_wrlock(RbHandle *h) {
    rb_claim_reader_slot(h);  /* refresh cached_pid across fork */
    RbHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = RB_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= RB_RWLOCK_WRITER_BIT &&
            !rb_pid_alive(expected & RB_RWLOCK_PID_MASK)) {
            rb_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < RB_RWLOCK_SPIN_LIMIT, 1)) {
            rb_rwlock_spin_pause();
            continue;
        }
        rb_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &rb_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                rb_unpark(h);
                rb_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        rb_unpark(h);
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
         * this scan, so no held slot is skipped).  O(RB_OCC_WORDS + live readers)
         * instead of O(RB_READER_SLOTS). */
        for (uint32_t w = 0; w < RB_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!rb_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &rb_lock_timeout, NULL, 0);
    }
}

static inline void rb_rwlock_wrunlock(RbHandle *h) {
    RbHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + bucket-table / container-pool accessors
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> bucket_table[65536] -> container_pool
 * RbReaderSlot is 16 bytes and RbBucket is 16 bytes, and the occ bitmap is 128
 * bytes (16 * uint64), so every region begins on a 16-byte boundary; container
 * slots are 8192 bytes (8-byte aligned for the uint64 bitmap interpretation).
 * ================================================================ */

typedef struct { uint64_t reader_slots, occ, bucket_table, container_pool; } RbLayout;

static inline RbLayout rb_layout(void) {
    RbLayout L;
    L.reader_slots   = sizeof(RbHeader);
    L.occ            = L.reader_slots + (uint64_t)RB_READER_SLOTS * sizeof(RbReaderSlot);
    L.bucket_table   = L.occ + RB_OCC_BYTES;
    L.container_pool = L.bucket_table + (uint64_t)RB_NUM_BUCKETS * sizeof(RbBucket);
    return L;
}

static inline uint64_t rb_total_size(uint32_t container_cap) {
    RbLayout L = rb_layout();
    return L.container_pool + (uint64_t)container_cap * RB_CONTAINER_BYTES;
}

/* bucket_table / container-pool base pointers come from the cached trusted
 * layout, NOT the peer-writable header offsets: a lock-violating peer that
 * corrupts hdr->bucket_table_off / hdr->container_pool_off after we attached
 * would otherwise redirect every bucket/slot access to a wild pointer. */
static inline RbBucket *rb_buckets(RbHandle *h) {
    return h->bucket_table;
}
static inline uint8_t *rb_pool(RbHandle *h) {
    return h->pool;
}
/* Base pointer of container slot `i` (1-based; i==0 is the NULL sentinel).
 * `i` originates from a bucket's file-stored container_off, which a local peer
 * can corrupt to an out-of-range slot; clamp to the reserved sentinel (0) so the
 * returned pointer always lands inside the container pool.  The clamp bound is
 * the cached container_cap (fixed geometry validated at attach and sizing the
 * mmap), never the live peer-writable hdr->container_cap. */
static inline void *rb_slot(RbHandle *h, uint32_t i) {
    if (i >= h->container_cap) i = 0;
    return (void *)(rb_pool(h) + (size_t)i * RB_CONTAINER_BYTES);
}
/* An array container holds at most RB_ARRAY_MAX entries in its fixed-size slot;
 * a corrupt file could store a larger cardinality and drive a search or scan
 * past the slot.  Clamp the file-stored count to the physical slot capacity. */
static inline uint32_t rb_array_card(const RbBucket *bt) {
    return bt->cardinality > RB_ARRAY_MAX ? RB_ARRAY_MAX : bt->cardinality;
}
static inline uint16_t *rb_array(RbHandle *h, uint32_t i) {
    return (uint16_t *)rb_slot(h, i);
}
static inline uint64_t *rb_bitmap(RbHandle *h, uint32_t i) {
    return (uint64_t *)rb_slot(h, i);
}

/* ================================================================
 * Container-slot allocation (freelist).  Callers hold the WRITE lock.
 * ================================================================ */

/* Number of container slots available to satisfy future allocations:
 * fresh high-water headroom plus returned slots on the freelist. */
static inline uint32_t rb_avail_slots(RbHandle *h) {
    RbHeader *hdr = h->hdr;
    return (hdr->container_cap - hdr->container_used) + hdr->free_count;
}

/* Allocate one container slot.  Returns a 1-based slot index, or 0 if the pool
 * is exhausted.  The returned slot is fully zeroed.  Pops the freelist first
 * (the freelist threads through the first 4 bytes of each freed slot), else
 * bumps the high-water mark. */
static inline uint32_t rb_alloc_slot(RbHandle *h) {
    RbHeader *hdr = h->hdr;
    uint32_t idx;
    if (hdr->free_head) {
        idx = hdr->free_head;
        hdr->free_head = *(uint32_t *)rb_slot(h, idx);   /* next free slot */
        hdr->free_count--;
    } else if (hdr->container_used < hdr->container_cap) {
        idx = hdr->container_used++;
    } else {
        return 0;
    }
    memset(rb_slot(h, idx), 0, RB_CONTAINER_BYTES);
    return idx;
}

/* Return a container slot to the freelist. */
static inline void rb_free_slot(RbHandle *h, uint32_t i) {
    RbHeader *hdr = h->hdr;
    *(uint32_t *)rb_slot(h, i) = hdr->free_head;
    hdr->free_head = i;
    hdr->free_count++;
}

/* ================================================================
 * Bit / popcount helpers
 * ================================================================ */

static inline uint64_t rb_popcount_bitmap(const uint64_t *bits) {
    uint64_t c = 0;
    for (uint32_t w = 0; w < 1024; w++) c += (uint64_t)__builtin_popcountll(bits[w]);
    return c;
}

/* Binary search for `lo` in a sorted uint16 array of `card` entries.  Returns
 * 1 and sets *pos to the index if found; returns 0 and sets *pos to the
 * insertion point (lower bound) if absent. */
static inline int rb_array_search(const uint16_t *vals, uint32_t card, uint16_t lo, uint32_t *pos) {
    uint32_t lo_i = 0, hi_i = card;
    while (lo_i < hi_i) {
        uint32_t mid = lo_i + ((hi_i - lo_i) >> 1);
        if (vals[mid] < lo) lo_i = mid + 1;
        else hi_i = mid;
    }
    *pos = lo_i;
    return (lo_i < card && vals[lo_i] == lo);
}

/* ================================================================
 * Single-bitmap operations.  Callers hold the WRITE lock (mutators) or the
 * READ lock (rb_contains_locked).
 * ================================================================ */

/* Convert bucket `hi`'s array container to a bitmap, in place (same slot).
 * The slot is reinterpreted, so the array values are copied to a C-stack temp
 * first.  The array is at most RB_ARRAY_MAX entries (a full array container). */
static inline void rb_array_to_bitmap(RbHandle *h, uint32_t hi) {
    RbBucket *bt = &rb_buckets(h)[hi];
    uint32_t card = rb_array_card(bt);
    uint16_t tmp[RB_ARRAY_MAX];
    uint16_t *vals = rb_array(h, bt->container_off);
    memcpy(tmp, vals, (size_t)card * sizeof(uint16_t));
    uint64_t *bits = rb_bitmap(h, bt->container_off);
    memset(bits, 0, RB_CONTAINER_BYTES);
    for (uint32_t i = 0; i < card; i++) {
        uint16_t lo = tmp[i];
        bits[lo >> 6] |= (uint64_t)1 << (lo & 63);
    }
    bt->type = RB_TYPE_BITMAP;
}

/* Add x to the set.  Returns 1 if newly added, 0 if already present.  The
 * caller has verified (under the lock) that a free slot exists when the target
 * bucket is currently empty. */
static inline int rb_add_locked(RbHandle *h, uint32_t x) {
    uint32_t hi = x >> 16;
    uint16_t lo = (uint16_t)(x & 0xffff);
    RbBucket *bt = &rb_buckets(h)[hi];

    if (bt->type == RB_TYPE_NONE) {
        uint32_t s = rb_alloc_slot(h);              /* guaranteed available by caller */
        bt->container_off = s;
        bt->type = RB_TYPE_ARRAY;
        bt->cardinality = 1;
        rb_array(h, s)[0] = lo;
        h->hdr->cardinality++;
        return 1;
    }
    if (bt->type == RB_TYPE_ARRAY) {
        uint16_t *vals = rb_array(h, bt->container_off);
        uint32_t pos;
        if (rb_array_search(vals, rb_array_card(bt), lo, &pos)) return 0;
        /* A full array container (RB_ARRAY_MAX entries) cannot hold one more
         * value without overflowing its fixed-size slot; promote it to a
         * bitmap FIRST, then set the bit.  (The new value is genuinely absent,
         * confirmed above, so this always grows the set.) */
        if (bt->cardinality >= RB_ARRAY_MAX) {
            rb_array_to_bitmap(h, hi);
            uint64_t *bits = rb_bitmap(h, bt->container_off);
            bits[lo >> 6] |= (uint64_t)1 << (lo & 63);
            bt->cardinality++;
            h->hdr->cardinality++;
            return 1;
        }
        memmove(&vals[pos + 1], &vals[pos], (size_t)(bt->cardinality - pos) * sizeof(uint16_t));
        vals[pos] = lo;
        bt->cardinality++;
        h->hdr->cardinality++;
        return 1;
    }
    /* bitmap */
    {
        uint64_t *bits = rb_bitmap(h, bt->container_off);
        uint32_t w = lo >> 6;
        uint64_t b = (uint64_t)1 << (lo & 63);
        if (bits[w] & b) return 0;
        bits[w] |= b;
        bt->cardinality++;
        h->hdr->cardinality++;
        return 1;
    }
}

/* Membership test.  Read-only. */
static inline int rb_contains_locked(RbHandle *h, uint32_t x) {
    uint32_t hi = x >> 16;
    uint16_t lo = (uint16_t)(x & 0xffff);
    RbBucket *bt = &rb_buckets(h)[hi];
    if (bt->type == RB_TYPE_NONE) return 0;
    if (bt->type == RB_TYPE_ARRAY) {
        uint32_t pos;
        return rb_array_search(rb_array(h, bt->container_off), rb_array_card(bt), lo, &pos);
    }
    {
        uint64_t *bits = rb_bitmap(h, bt->container_off);
        return (bits[lo >> 6] >> (lo & 63)) & 1;
    }
}

/* Remove x from the set.  Returns 1 if removed, 0 if absent.  Frees the slot
 * (and clears the bucket) when the last element of a bucket is removed.  v1
 * does NOT down-convert a bitmap to an array. */
static inline int rb_remove_locked(RbHandle *h, uint32_t x) {
    uint32_t hi = x >> 16;
    uint16_t lo = (uint16_t)(x & 0xffff);
    RbBucket *bt = &rb_buckets(h)[hi];
    if (bt->type == RB_TYPE_NONE) return 0;
    if (bt->type == RB_TYPE_ARRAY) {
        uint16_t *vals = rb_array(h, bt->container_off);
        uint32_t card = rb_array_card(bt);
        uint32_t pos;
        if (!rb_array_search(vals, card, lo, &pos)) return 0;
        memmove(&vals[pos], &vals[pos + 1], (size_t)(card - pos - 1) * sizeof(uint16_t));
        bt->cardinality--;
        h->hdr->cardinality--;
        if (bt->cardinality == 0) {
            rb_free_slot(h, bt->container_off);
            bt->container_off = 0;
            bt->type = RB_TYPE_NONE;
        }
        return 1;
    }
    {
        uint64_t *bits = rb_bitmap(h, bt->container_off);
        uint32_t w = lo >> 6;
        uint64_t b = (uint64_t)1 << (lo & 63);
        if (!(bits[w] & b)) return 0;
        bits[w] &= ~b;
        bt->cardinality--;
        h->hdr->cardinality--;
        if (bt->cardinality == 0) {
            rb_free_slot(h, bt->container_off);
            bt->container_off = 0;
            bt->type = RB_TYPE_NONE;
        }
        return 1;
    }
}

/* Reset to empty: free every container, zero the bucket table, reset the pool.
 * Caller holds the write lock. */
static inline void rb_clear_locked(RbHandle *h) {
    RbHeader *hdr = h->hdr;
    RbBucket *bt = rb_buckets(h);
    memset(bt, 0, (size_t)RB_NUM_BUCKETS * sizeof(RbBucket));
    hdr->container_used = 1;   /* slot 0 reserved */
    hdr->free_head = 0;
    hdr->free_count = 0;
    hdr->cardinality = 0;
}

/* Smallest set element.  Returns 1 and sets *out, else 0 (empty set). */
static inline int rb_min_locked(RbHandle *h, uint32_t *out) {
    RbBucket *bt = rb_buckets(h);
    for (uint32_t hi = 0; hi < RB_NUM_BUCKETS; hi++) {
        if (bt[hi].type == RB_TYPE_NONE) continue;
        if (bt[hi].type == RB_TYPE_ARRAY) {
            if (rb_array_card(&bt[hi]) == 0) continue;   /* corrupt: an array container with 0 entries */
            *out = (hi << 16) | rb_array(h, bt[hi].container_off)[0];
            return 1;
        }
        {
            uint64_t *bits = rb_bitmap(h, bt[hi].container_off);
            for (uint32_t w = 0; w < 1024; w++) {
                if (bits[w]) {
                    uint32_t lo = (w << 6) + (uint32_t)__builtin_ctzll(bits[w]);
                    *out = (hi << 16) | lo;
                    return 1;
                }
            }
        }
    }
    return 0;
}

/* Largest set element.  Returns 1 and sets *out, else 0 (empty set). */
static inline int rb_max_locked(RbHandle *h, uint32_t *out) {
    RbBucket *bt = rb_buckets(h);
    for (uint32_t hi = RB_NUM_BUCKETS; hi-- > 0; ) {
        if (bt[hi].type == RB_TYPE_NONE) continue;
        if (bt[hi].type == RB_TYPE_ARRAY) {
            uint32_t c = rb_array_card(&bt[hi]);
            if (c == 0) continue;   /* corrupt: an array container with 0 entries */
            *out = (hi << 16) | rb_array(h, bt[hi].container_off)[c - 1];
            return 1;
        }
        {
            uint64_t *bits = rb_bitmap(h, bt[hi].container_off);
            for (uint32_t w = 1024; w-- > 0; ) {
                if (bits[w]) {
                    uint32_t lo = (w << 6) + (63 - (uint32_t)__builtin_clzll(bits[w]));
                    *out = (hi << 16) | lo;
                    return 1;
                }
            }
        }
    }
    return 0;
}

/* Count the number of non-empty buckets (for stats).  Read-only. */
static inline uint32_t rb_buckets_used(RbHandle *h) {
    RbBucket *bt = rb_buckets(h);
    uint32_t n = 0;
    for (uint32_t hi = 0; hi < RB_NUM_BUCKETS; hi++)
        if (bt[hi].type != RB_TYPE_NONE) n++;
    return n;
}

/* ================================================================
 * In-place set operations.  Callers hold a's WRITE lock and b's READ lock
 * (acquired in a globally-consistent order keyed on the shared-memory
 * bitmap_id to avoid cross-process deadlock).  a and b are guaranteed to be
 * DISTINCT underlying bitmaps (the same-bitmap case -- whether o==h or merely
 * o->hdr->bitmap_id == h->hdr->bitmap_id -- is a no-op handled by the caller).
 * ================================================================ */

/* a |= b for a single bucket where a's container is a bitmap.  Reads b's
 * container of either kind; returns the new popcount. */
static inline uint32_t rb_or_into_bitmap(uint64_t *abits, RbHandle *b, const RbBucket *bbt) {
    if (bbt->type == RB_TYPE_ARRAY) {
        const uint16_t *bv = rb_array(b, bbt->container_off);
        uint32_t bc = rb_array_card(bbt);
        for (uint32_t i = 0; i < bc; i++) {
            uint16_t lo = bv[i];
            abits[lo >> 6] |= (uint64_t)1 << (lo & 63);
        }
    } else { /* bitmap */
        const uint64_t *bb = rb_bitmap(b, bbt->container_off);
        for (uint32_t w = 0; w < 1024; w++) abits[w] |= bb[w];
    }
    return (uint32_t)rb_popcount_bitmap(abits);
}

/* Pre-count how many NEW container slots a |= b will need: one per bucket that
 * b occupies and a does not.  Caller holds both locks. */
static inline uint32_t rb_union_new_slots_needed(RbHandle *a, RbHandle *b) {
    RbBucket *abt = rb_buckets(a);
    RbBucket *bbt = rb_buckets(b);
    uint32_t need = 0;
    for (uint32_t hi = 0; hi < RB_NUM_BUCKETS; hi++) {
        if (bbt[hi].type != RB_TYPE_NONE && abt[hi].type == RB_TYPE_NONE) need++;
    }
    return need;
}

/* Recompute the total cardinality from the per-bucket cards (after a set op). */
static inline void rb_recompute_cardinality(RbHandle *a, RbBucket *abt) {
    uint64_t total = 0;
    for (uint32_t hi = 0; hi < RB_NUM_BUCKETS; hi++)
        if (abt[hi].type != RB_TYPE_NONE) total += abt[hi].cardinality;
    a->hdr->cardinality = total;
}

/* a |= b.  Caller has verified rb_avail_slots(a) >= rb_union_new_slots_needed.
 * Every bucket combination is handled in place. */
static inline void rb_union_locked(RbHandle *a, RbHandle *b) {
    RbBucket *abt = rb_buckets(a);
    RbBucket *bbt = rb_buckets(b);
    for (uint32_t hi = 0; hi < RB_NUM_BUCKETS; hi++) {
        if (bbt[hi].type == RB_TYPE_NONE) continue;

        if (abt[hi].type == RB_TYPE_NONE) {
            /* a lacks this bucket -> copy b's container wholesale. */
            uint32_t s = rb_alloc_slot(a);          /* guaranteed available */
            memcpy(rb_slot(a, s), rb_slot(b, bbt[hi].container_off), RB_CONTAINER_BYTES);
            abt[hi].container_off = s;
            abt[hi].type = bbt[hi].type;
            abt[hi].cardinality = bbt[hi].cardinality;
            continue;
        }

        if (abt[hi].type == RB_TYPE_ARRAY && bbt[hi].type == RB_TYPE_ARRAY) {
            /* array | array -> merge sorted, dedup, into a C-stack temp. */
            uint16_t tmp[2 * RB_ARRAY_MAX];
            uint16_t *av = rb_array(a, abt[hi].container_off);
            const uint16_t *bv = rb_array(b, bbt[hi].container_off);
            uint32_t ai = 0, bi = 0, n = 0;
            uint32_t ac = rb_array_card(&abt[hi]), bc = rb_array_card(&bbt[hi]);
            while (ai < ac && bi < bc) {
                uint16_t x = av[ai], y = bv[bi];
                if (x < y) { tmp[n++] = x; ai++; }
                else if (x > y) { tmp[n++] = y; bi++; }
                else { tmp[n++] = x; ai++; bi++; }
            }
            while (ai < ac) tmp[n++] = av[ai++];
            while (bi < bc) tmp[n++] = bv[bi++];
            if (n <= RB_ARRAY_MAX) {
                memcpy(av, tmp, (size_t)n * sizeof(uint16_t));
                abt[hi].cardinality = n;
            } else {
                uint64_t *bits = rb_bitmap(a, abt[hi].container_off);
                memset(bits, 0, RB_CONTAINER_BYTES);
                for (uint32_t i = 0; i < n; i++) bits[tmp[i] >> 6] |= (uint64_t)1 << (tmp[i] & 63);
                abt[hi].type = RB_TYPE_BITMAP;
                abt[hi].cardinality = n;
            }
            continue;
        }

        if (abt[hi].type == RB_TYPE_ARRAY && bbt[hi].type == RB_TYPE_BITMAP) {
            /* array(a) | bitmap(b): copy b's bitmap into a, then OR a's old
             * array values back in.  Snapshot a's array first (slot reused). */
            uint16_t tmp[RB_ARRAY_MAX];
            uint16_t *av = rb_array(a, abt[hi].container_off);
            uint32_t ac = rb_array_card(&abt[hi]);
            memcpy(tmp, av, (size_t)ac * sizeof(uint16_t));
            uint64_t *abits = rb_bitmap(a, abt[hi].container_off);
            memcpy(abits, rb_bitmap(b, bbt[hi].container_off), RB_CONTAINER_BYTES);
            for (uint32_t i = 0; i < ac; i++) abits[tmp[i] >> 6] |= (uint64_t)1 << (tmp[i] & 63);
            abt[hi].type = RB_TYPE_BITMAP;
            abt[hi].cardinality = (uint32_t)rb_popcount_bitmap(abits);
            continue;
        }

        /* bitmap(a) | array(b)  and  bitmap(a) | bitmap(b) */
        {
            uint64_t *abits = rb_bitmap(a, abt[hi].container_off);
            abt[hi].cardinality = rb_or_into_bitmap(abits, b, &bbt[hi]);
        }
    }

    rb_recompute_cardinality(a, abt);
}

/* a &= b.  Never needs new slots (intersection only shrinks or frees).  Caller
 * holds a's write lock and b's read lock. */
static inline void rb_intersect_locked(RbHandle *a, RbHandle *b) {
    RbBucket *abt = rb_buckets(a);
    RbBucket *bbt = rb_buckets(b);
    for (uint32_t hi = 0; hi < RB_NUM_BUCKETS; hi++) {
        if (abt[hi].type == RB_TYPE_NONE) continue;

        if (bbt[hi].type == RB_TYPE_NONE) {
            rb_free_slot(a, abt[hi].container_off);
            abt[hi].container_off = 0;
            abt[hi].type = RB_TYPE_NONE;
            abt[hi].cardinality = 0;
            continue;
        }

        if (abt[hi].type == RB_TYPE_ARRAY && bbt[hi].type == RB_TYPE_ARRAY) {
            /* array & array -> two-pointer intersect into a C-stack temp. */
            uint16_t tmp[RB_ARRAY_MAX];
            uint16_t *av = rb_array(a, abt[hi].container_off);
            const uint16_t *bv = rb_array(b, bbt[hi].container_off);
            uint32_t ai = 0, bi = 0, n = 0;
            uint32_t ac = rb_array_card(&abt[hi]), bc = rb_array_card(&bbt[hi]);
            while (ai < ac && bi < bc) {
                uint16_t x = av[ai], y = bv[bi];
                if (x < y) ai++;
                else if (x > y) bi++;
                else { tmp[n++] = x; ai++; bi++; }
            }
            memcpy(av, tmp, (size_t)n * sizeof(uint16_t));
            abt[hi].cardinality = n;
        }
        else if (abt[hi].type == RB_TYPE_ARRAY && bbt[hi].type == RB_TYPE_BITMAP) {
            /* array(a) & bitmap(b): keep a's values whose bit is set in b. */
            uint16_t *av = rb_array(a, abt[hi].container_off);
            const uint64_t *bb = rb_bitmap(b, bbt[hi].container_off);
            uint32_t n = 0, ac = rb_array_card(&abt[hi]);
            for (uint32_t i = 0; i < ac; i++) {
                uint16_t lo = av[i];
                if ((bb[lo >> 6] >> (lo & 63)) & 1) av[n++] = lo;
            }
            abt[hi].cardinality = n;
        }
        else if (abt[hi].type == RB_TYPE_BITMAP && bbt[hi].type == RB_TYPE_ARRAY) {
            /* bitmap(a) & array(b) -> result is b's values that are set in a;
             * write it back as an ARRAY into a's slot.  Snapshot b's array to
             * a temp (a's slot is being overwritten). */
            uint16_t tmp[RB_ARRAY_MAX];
            const uint16_t *bv = rb_array(b, bbt[hi].container_off);
            uint64_t *abits = rb_bitmap(a, abt[hi].container_off);
            uint32_t n = 0, bc = rb_array_card(&bbt[hi]);
            for (uint32_t i = 0; i < bc; i++) {
                uint16_t lo = bv[i];
                if ((abits[lo >> 6] >> (lo & 63)) & 1) tmp[n++] = lo;
            }
            uint16_t *av = rb_array(a, abt[hi].container_off);
            memcpy(av, tmp, (size_t)n * sizeof(uint16_t));   /* same slot, array view */
            abt[hi].type = RB_TYPE_ARRAY;
            abt[hi].cardinality = n;
        }
        else { /* bitmap(a) & bitmap(b) */
            uint64_t *abits = rb_bitmap(a, abt[hi].container_off);
            const uint64_t *bb = rb_bitmap(b, bbt[hi].container_off);
            for (uint32_t w = 0; w < 1024; w++) abits[w] &= bb[w];
            abt[hi].cardinality = (uint32_t)rb_popcount_bitmap(abits);
        }

        /* If the bucket emptied, free its slot. */
        if (abt[hi].cardinality == 0) {
            rb_free_slot(a, abt[hi].container_off);
            abt[hi].container_off = 0;
            abt[hi].type = RB_TYPE_NONE;
        }
    }

    rb_recompute_cardinality(a, abt);
}

/* ================================================================
 * Validate args + header init / setup / open / destroy
 * ================================================================ */

/* Validate create args.  Single source of truth: the XS layer does NOT
 * duplicate these range checks. */
static int rb_validate_create_args(uint64_t container_cap, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (container_cap < 1) { RB_ERR("container_capacity must be >= 1"); return 0; }
    if (container_cap > RB_MAX_CONTAINERS) { RB_ERR("container_capacity must be <= %u", (unsigned)RB_MAX_CONTAINERS); return 0; }
    {
        uint64_t total = rb_total_size((uint32_t)container_cap);
        if (total > (uint64_t)SIZE_MAX) { RB_ERR("requested mapping too large"); return 0; }
    }
    return 1;
}

/* Generate a non-zero per-bitmap identity, used ONLY at create time to order
 * set-op lock acquisition consistently across unrelated processes.  Prefers
 * getrandom(); on any failure/short read falls back to a non-zero mix of pid,
 * a process-local counter, and the header address.  Never returns 0. */
static inline uint64_t rb_gen_bitmap_id(const void *hdr_addr) {
    static uint32_t rb_id_counter = 0;
    uint64_t id = 0;
    ssize_t r = getrandom(&id, sizeof id, 0);
    if (r != (ssize_t)sizeof id) {
        uint32_t c = __atomic_add_fetch(&rb_id_counter, 1, __ATOMIC_RELAXED);
        id = ((uint64_t)(uint32_t)getpid() << 32)
           ^ ((uint64_t)c * 0x9E3779B97F4A7C15ull)
           ^ (uint64_t)(uintptr_t)hdr_addr;
    }
    if (id == 0) id = 0x9E3779B97F4A7C15ull;   /* never 0 */
    return id;
}

static inline void rb_init_header(void *base, uint32_t container_cap, uint64_t total_size) {
    RbLayout L = rb_layout();
    RbHeader *hdr = (RbHeader *)base;
    /* Zero the header + reader-slot + occ-bitmap + bucket-table region (up to the
     * container pool, so the occ bitmap starts all-clear).  A fresh mapping is
     * OS-zeroed, but zero explicitly for the reopen-of-anon path. */
    memset(base, 0, (size_t)L.container_pool);
    hdr->magic              = RB_MAGIC;
    hdr->version            = RB_VERSION;
    hdr->bitmap_id          = rb_gen_bitmap_id(base);
    hdr->container_cap      = container_cap;
    hdr->container_used     = 1;   /* slot 0 reserved as the NULL sentinel */
    hdr->free_head          = 0;
    hdr->free_count         = 0;
    hdr->cardinality        = 0;
    hdr->total_size         = total_size;
    hdr->reader_slots_off   = L.reader_slots;
    hdr->bucket_table_off   = L.bucket_table;
    hdr->container_pool_off = L.container_pool;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline RbHandle *rb_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    RbHeader *hdr = (RbHeader *)base;
    RbHandle *h = (RbHandle *)calloc(1, sizeof(RbHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    RbLayout L      = rb_layout();
    h->hdr          = hdr;
    h->base         = base;
    /* All region bases derive from the trusted compile-time layout, not the
     * peer-writable header offsets; container_cap is the validated fixed
     * geometry (rb_validate_header / rb_validate_create_args ran before this). */
    h->reader_slots = (RbReaderSlot *)((uint8_t *)base + L.reader_slots);
    h->occ          = (uint64_t *)((uint8_t *)base + L.occ);   /* trusted layout offset */
    h->bucket_table = (RbBucket *)((uint8_t *)base + L.bucket_table);
    h->pool         = (uint8_t *)base + L.container_pool;
    h->container_cap = hdr->container_cap;
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by rb_create reopen and rb_open_fd).
 * Stored geometry wins on reopen. */
static inline int rb_validate_header(const RbHeader *hdr, uint64_t file_size) {
    if (hdr->magic != RB_MAGIC) return 0;
    if (hdr->version != RB_VERSION) return 0;
    if (hdr->bitmap_id == 0) return 0;   /* identity must have been set at create */
    if (hdr->container_cap < 1 || hdr->container_cap > RB_MAX_CONTAINERS) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != rb_total_size(hdr->container_cap)) return 0;
    RbLayout L = rb_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->bucket_table_off != L.bucket_table) return 0;
    if (hdr->container_pool_off != L.container_pool) return 0;
    if (hdr->container_used < 1 || hdr->container_used > hdr->container_cap) return 0;
    if (hdr->free_head >= hdr->container_cap) return 0;
    if (hdr->free_count > hdr->container_cap) return 0;
    return 1;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at
 * file_mode, default 0600), or attach an existing file (O_RDWR|O_NOFOLLOW, no
 * O_CREAT). Blocks a symlink swap or pre-seeded/hard-linked backing file;
 * cross-user sharing is opt-in via a wider file_mode. */
static int rb_secure_open(const char *path, mode_t file_mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, file_mode);
        if (fd >= 0) { (void)fchmod(fd, file_mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { RB_ERR("create(%s): %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;
        RB_ERR("open(%s): %s", path, strerror(errno));
        return -1;
    }
    RB_ERR("open(%s): create/attach kept racing", path);
    return -1;
}

static RbHandle *rb_create(const char *path, uint64_t container_cap_in, mode_t file_mode, char *errbuf) {
    if (!rb_validate_create_args(container_cap_in, errbuf)) return NULL;
    uint32_t container_cap = (uint32_t)container_cap_in;

    uint64_t total = rb_total_size(container_cap);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { RB_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = rb_secure_open(path, file_mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { RB_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { RB_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(RbHeader)) {
            RB_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, file_mode) < 0)) {
            RB_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            RB_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { RB_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!rb_validate_header((RbHeader *)base, (uint64_t)st.st_size)) {
                RB_ERR("invalid roaring-bitmap file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return rb_setup(base, map_size, path, -1);
        }
    }
    rb_init_header(base, container_cap, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return rb_setup(base, map_size, path, -1);
}

static RbHandle *rb_create_memfd(const char *name, uint64_t container_cap_in, char *errbuf) {
    if (!rb_validate_create_args(container_cap_in, errbuf)) return NULL;
    uint32_t container_cap = (uint32_t)container_cap_in;

    uint64_t total = rb_total_size(container_cap);
    int fd = memfd_create(name ? name : "roaring", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { RB_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        RB_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { RB_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    rb_init_header(base, container_cap, total);
    return rb_setup(base, (size_t)total, NULL, fd);
}

static RbHandle *rb_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { RB_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(RbHeader)) { RB_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { RB_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!rb_validate_header((RbHeader *)base, (uint64_t)st.st_size)) {
        RB_ERR("invalid roaring-bitmap file"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { RB_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return rb_setup(base, ms, NULL, myfd);
}

static void rb_destroy(RbHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&rb_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        rb_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int rb_msync(RbHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

#endif /* ROARING_H */
