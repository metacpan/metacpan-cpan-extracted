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
 * Layout: Header -> reader_slots[1024] -> bucket_table[65536] -> container_pool[container_cap]
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
#define RB_VERSION        1
#define RB_ERR_BUFLEN     256
#define RB_READER_SLOTS   1024         /* max concurrent reader processes for dead-process recovery */
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

/* Per-process slot for dead-process recovery.  Mirrors this process's
 * contribution to each shared rwlock counter so a wrlock timeout can attribute
 * and reverse a dead process's share instead of waiting for the slow per-op
 * timeout drain. */
typedef struct {
    uint32_t pid;            /* 0 = unclaimed */
    uint32_t subcount;       /* in-flight rdlock acquisitions for this process */
    uint32_t waiters_parked; /* contribution to hdr->rwlock_waiters         */
    uint32_t writers_parked; /* contribution to hdr->rwlock_writers_waiting */
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
    uint32_t rwlock;                  /* 72 */
    uint32_t rwlock_waiters;          /* 76 */
    uint32_t rwlock_writers_waiting;  /* 80 */
    uint32_t _pad0;                   /* 84  align stat_ops to 8 */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad1[160];              /* 96..255 */
};
typedef struct RbHeader RbHeader;

_Static_assert(sizeof(RbHeader) == 256, "RbHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct RbHandle {
    RbHeader     *hdr;
    RbReaderSlot *reader_slots;   /* RB_READER_SLOTS entries */
    void         *base;           /* mmap base */
    size_t        mmap_size;
    char         *path;           /* backing file path (strdup'd) */
    int           backing_fd;     /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;    /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;     /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen;/* rb_fork_gen value at last slot claim */
} RbHandle;

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define RB_RWLOCK_SPIN_LIMIT 32
#define RB_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void rb_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define RB_RWLOCK_WRITER_BIT 0x80000000U
#define RB_RWLOCK_PID_MASK   0x7FFFFFFFU
#define RB_RWLOCK_WR(pid)    (RB_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & RB_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Documented under "Crash Safety". */
static inline int rb_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void rb_recover_stale_lock(RbHandle *h, uint32_t observed_rwlock) {
    RbHeader *hdr = h->hdr;
    uint32_t mypid = RB_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
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

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
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
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % RB_READER_SLOTS;
    for (uint32_t i = 0; i < RB_READER_SLOTS; i++) {
        uint32_t s = (start + i) % RB_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and rb_recover_dead_readers won't drain them
             * once we own the slot (the CAS expects the dead PID). */
            __atomic_store_n(&h->reader_slots[s].subcount, 0, __ATOMIC_RELAXED);
            __atomic_store_n(&h->reader_slots[s].waiters_parked, 0, __ATOMIC_RELAXED);
            __atomic_store_n(&h->reader_slots[s].writers_parked, 0, __ATOMIC_RELAXED);
            h->my_slot_idx = s;
            return;
        }
    }
    /* Table full -- leave my_slot_idx = UINT32_MAX so we silently skip
     * tracking for this handle (lock still works; just no recovery). */
}

/* Atomically subtract `sub` from a counter, capped at 0 (never underflows). */
static inline void rb_atomic_sub_cap(uint32_t *p, uint32_t sub) {
    if (!sub) return;
    uint32_t cur = __atomic_load_n(p, __ATOMIC_RELAXED);
    for (;;) {
        uint32_t want = (cur > sub) ? cur - sub : 0;
        if (__atomic_compare_exchange_n(p, &cur, want,
                1, __ATOMIC_RELAXED, __ATOMIC_RELAXED))
            return;
    }
}

/* Try to claim a dead slot (CAS pid -> 0) and drain its parked-waiter
 * contributions back to the global counters.  A no-op if the slot was stolen
 * by another recoverer or had no waiter contribution to drain.
 *
 * Note: subcount/waiters_parked/writers_parked are NOT zeroed here.
 * rb_claim_reader_slot zeros all three on every claim, so leaving stale
 * values is harmless. */
static inline void rb_drain_dead_slot(RbHandle *h, uint32_t i, uint32_t pid) {
    RbHeader *hdr = h->hdr;
    uint32_t expected = pid;
    /* ACQ_REL on success: RELEASE publishes pid=0; ACQUIRE syncs us with the
     * dead process's prior writes to waiters_parked/writers_parked. */
    if (!__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    uint32_t wp    = __atomic_load_n(&h->reader_slots[i].waiters_parked, __ATOMIC_RELAXED);
    uint32_t writp = __atomic_load_n(&h->reader_slots[i].writers_parked, __ATOMIC_RELAXED);
    if (wp)    rb_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) rb_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
}

/* Scan reader slots for dead-process recovery.
 *
 * For each dead PID with non-zero contributions to the shared rwlock,
 * rwlock_waiters, or rwlock_writers_waiting counters, drain its share back
 * out so live processes don't have to wait for the slow per-op timeout
 * decrement to drain it for them. */
static inline void rb_recover_dead_readers(RbHandle *h) {
    if (!h->reader_slots) return;
    RbHeader *hdr = h->hdr;
    int any_live_reader = 0;
    int found_dead_reader = 0;

    /* Pass 1: classify slots.  Dead pid with sc == 0 is wiped immediately to
     * free the slot and drain orphan parked-waiter counters.  Dead pid with
     * sc > 0 is left intact: if force-reset cannot fire (a live reader is
     * concurrently present), wiping it would lose the only record of its
     * orphan rwlock contribution and strand writers. */
    for (uint32_t i = 0; i < RB_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (rb_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        rb_drain_dead_slot(h, i, pid);
    }

    /* Pass 2: only if force-reset will fire.  Issue the rwlock force-reset
     * CAS FIRST (narrow window since pass 1), then wipe the deferred dead
     * slots outside the race-sensitive window. */
    if (found_dead_reader && !any_live_reader) {
        /* ACQUIRE: a late reader's subcount++ (before its rwlock CAS) is then visible below. */
        uint32_t cur = __atomic_load_n(&hdr->rwlock, __ATOMIC_ACQUIRE);
        int drain_ok = 1;   /* keep dead slots if the reset doesn't fire */
        if (cur > 0 && cur < RB_RWLOCK_WRITER_BIT) {
            /* Re-scan for a live reader (fail-safe: only suppresses a reset). */
            int live_now = 0;   /* no slotless readers here: scanning slots is complete */
            for (uint32_t i = 0; !live_now && i < RB_READER_SLOTS; i++) {
                uint32_t p = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (p && rb_pid_alive(p) &&
                    __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED) > 0)
                    live_now = 1;
            }
            if (live_now) {
                drain_ok = 0;
            } else if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            } else {
                drain_ok = 0;   /* rwlock changed under us -- shares may still be live */
            }
        }
        if (drain_ok) {
            for (uint32_t i = 0; i < RB_READER_SLOTS; i++) {
                uint32_t p = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (p == 0 || rb_pid_alive(p)) continue;
                rb_drain_dead_slot(h, i, p);
            }
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters. */
static inline void rb_recover_after_timeout(RbHandle *h) {
    RbHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= RB_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & RB_RWLOCK_PID_MASK;
        if (!rb_pid_alive(pid))
            rb_recover_stale_lock(h, val);
    } else {
        rb_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution. */
static inline void rb_park_reader(RbHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void rb_unpark_reader(RbHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void rb_park_writer(RbHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void rb_unpark_writer(RbHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void rb_rwlock_rdlock(RbHandle *h) {
    rb_claim_reader_slot(h);
    RbHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    /* Claim subcount BEFORE bumping the shared rwlock counter so a concurrent
     * writer-side recovery scan that sees our PID alive with subcount > 0 will
     * (correctly) defer force-reset even while we are still spinning. */
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Write-preferring: when free (cur==0) and writers wait, yield. When
         * readers are already active (cur>=1), new readers may join freely. */
        if (cur > 0 && cur < RB_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < RB_RWLOCK_SPIN_LIMIT, 1)) {
            rb_rwlock_spin_pause();
            continue;
        }
        rb_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur >= RB_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &rb_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                rb_unpark_reader(h);
                rb_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        rb_unpark_reader(h);
        spin = 0;
    }
}

static inline void rb_rwlock_rdunlock(RbHandle *h) {
    RbHeader *hdr = h->hdr;
    /* Release the shared counter BEFORE dropping our subcount so "any live PID
     * with subcount > 0" stays a reliable in-flight indicator for recovery. */
    uint32_t after = __atomic_sub_fetch(&hdr->rwlock, 1, __ATOMIC_RELEASE);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    if (after == 0 && __atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void rb_rwlock_wrlock(RbHandle *h) {
    rb_claim_reader_slot(h);  /* refresh cached_pid across fork */
    RbHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = RB_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < RB_RWLOCK_SPIN_LIMIT, 1)) {
            rb_rwlock_spin_pause();
            continue;
        }
        rb_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &rb_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                rb_unpark_writer(h);
                rb_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        rb_unpark_writer(h);
        spin = 0;
    }
}

static inline void rb_rwlock_wrunlock(RbHandle *h) {
    RbHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + bucket-table / container-pool accessors
 *
 * Layout: Header -> reader_slots[1024] -> bucket_table[65536] -> container_pool
 * RbReaderSlot is 16 bytes and RbBucket is 16 bytes, so every region begins on
 * a 16-byte boundary; container slots are 8192 bytes (8-byte aligned for the
 * uint64 bitmap interpretation).
 * ================================================================ */

typedef struct { uint64_t reader_slots, bucket_table, container_pool; } RbLayout;

static inline RbLayout rb_layout(void) {
    RbLayout L;
    L.reader_slots   = sizeof(RbHeader);
    L.bucket_table   = L.reader_slots + (uint64_t)RB_READER_SLOTS * sizeof(RbReaderSlot);
    L.container_pool = L.bucket_table + (uint64_t)RB_NUM_BUCKETS * sizeof(RbBucket);
    return L;
}

static inline uint64_t rb_total_size(uint32_t container_cap) {
    RbLayout L = rb_layout();
    return L.container_pool + (uint64_t)container_cap * RB_CONTAINER_BYTES;
}

static inline RbBucket *rb_buckets(RbHandle *h) {
    return (RbBucket *)((char *)h->base + h->hdr->bucket_table_off);
}
static inline uint8_t *rb_pool(RbHandle *h) {
    return (uint8_t *)((char *)h->base + h->hdr->container_pool_off);
}
/* Base pointer of container slot `i` (1-based; i==0 is the NULL sentinel).
 * `i` originates from a bucket's file-stored container_off, which a local peer
 * can corrupt to an out-of-range slot; clamp to the reserved sentinel (0) so the
 * returned pointer always lands inside the container pool. */
static inline void *rb_slot(RbHandle *h, uint32_t i) {
    if (i >= h->hdr->container_cap) i = 0;
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
    /* Zero the header + reader-slot + bucket-table region.  A fresh mapping is
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
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (RbReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
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
     * exhausts the slot table); skip if a lock is still held (subcount>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&rb_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].subcount, __ATOMIC_ACQUIRE) == 0) {
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
