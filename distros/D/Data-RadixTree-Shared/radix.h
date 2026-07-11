/*
 * radix.h -- Shared-memory compressed radix tree (PATRICIA-style trie) for Linux
 *
 * Maps arbitrary byte-string keys to uint64 values. A radix-256 trie with
 * path/edge compression: each node carries a label (a run of bytes shared by
 * the whole subtree) so chains of single-child nodes collapse into one edge.
 * Insert and lookup are O(key length). Beyond exact lookup the tree answers
 * longest-prefix queries -- the longest stored key that is a prefix of a query
 * string -- which is what routing tables want. The node pool and label arena
 * live in a shared mapping so several processes share one tree; a
 * write-preferring futex rwlock with reader-slot dead-process recovery guards
 * mutation.
 *
 * lookup / exists / longest_prefix are pure reads (no path compression) and run
 * under the READ lock; insert / delete / clear take the WRITE lock.
 *
 * delete is LAZY in v1: it unmarks the key's value but does not free node-pool
 * or arena space. Size the capacities for the working set, or clear() to reset.
 *
 * Layout: Header -> reader_slots[1024] -> node_pool[node_cap] -> label_arena[arena_cap]
 */

#ifndef RADIX_H
#define RADIX_H

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
#include <linux/futex.h>
#include <pthread.h>

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "radix.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define RDX_MAGIC        0x58444152U  /* "RADX" (little-endian) */
#define RDX_VERSION      1
#define RDX_ERR_BUFLEN   256
#ifndef RDX_READER_SLOTS
#define RDX_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
#define RDX_MAX_NODES    (1u << 24)   /* 16.7M nodes: node index 0 is the reserved NIL sentinel */
#define RDX_MAX_ARENA    0xF0000000u  /* ~3.75 GiB label arena; offsets/lengths are uint32 */

#define RDX_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, RDX_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

/* ================================================================
 * Structs
 * ================================================================ */

/* Radix-tree node (fixed size).  children[b] == 0 means "no child on byte b",
 * so node index 0 is the reserved NIL sentinel and is never a real node.  The
 * label (children-shared prefix of this edge) lives in the arena at
 * [label_off, label_off+label_len). */
typedef struct {
    uint32_t children[256];  /* child node index per next byte; 0 == none */
    uint32_t label_off;      /* offset of this edge's label in the arena */
    uint32_t label_len;      /* length of the label in bytes */
    uint64_t value;          /* stored value (valid only when has_value) */
    uint8_t  has_value;      /* 1 if a key ends exactly at this node */
    uint8_t  _pad[7];        /* pad to 8-byte alignment (1048 bytes total) */
} RdxNode;

_Static_assert(sizeof(RdxNode) == 256u * 4u + 4u + 4u + 8u + 8u, "RdxNode layout");
_Static_assert(sizeof(RdxNode) % 8 == 0, "RdxNode must be 8-byte aligned");

/* Per-process slot for dead-process recovery.  Each shared rwlock counter
 * (the main rwlock-reader count, rwlock_waiters, rwlock_writers_waiting)
 * is mirrored here so a wrlock timeout can attribute and reverse a dead
 * process's contribution instead of waiting for the slow per-op timeout
 * drain. */
typedef struct {
    uint32_t pid;            /* 0 = unclaimed */
    uint32_t subcount;       /* in-flight rdlock acquisitions for this process */
    uint32_t waiters_parked; /* contribution to hdr->rwlock_waiters         */
    uint32_t writers_parked; /* contribution to hdr->rwlock_writers_waiting */
} RdxReaderSlot;

struct RdxHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t node_cap;                /* 8   node-pool capacity (slots, incl. NIL) */
    uint32_t node_used;               /* 12  high-water of ever-allocated nodes (incl. NIL+root) */
    uint32_t root;                    /* 16  root node index (allocated at create) */
    uint32_t arena_cap;               /* 20  label-arena capacity in bytes */
    uint32_t arena_used;              /* 24  bytes used in the arena */
    uint32_t _pad1;                   /* 28  (was free_head; lazy delete never freed nodes) */
    uint64_t keys;                    /* 32  count of stored keys */
    uint64_t total_size;              /* 40 */
    uint64_t reader_slots_off;        /* 48 */
    uint64_t node_pool_off;           /* 56 */
    uint64_t arena_off;               /* 64 */
    uint32_t rwlock;                  /* 72 */
    uint32_t rwlock_waiters;          /* 76 */
    uint32_t rwlock_writers_waiting;  /* 80 */
    uint32_t slotless_readers;  /* live readers holding the lock with no reader-slot (was padding) */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct RdxHeader RdxHeader;

_Static_assert(sizeof(RdxHeader) == 256, "RdxHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct RdxHandle {
    RdxHeader     *hdr;
    RdxReaderSlot *reader_slots;  /* RDX_READER_SLOTS entries */
    void          *base;          /* mmap base */
    size_t         mmap_size;
    char          *path;          /* backing file path (strdup'd) */
    int            backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t       my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;    /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* rdx_fork_gen value at last slot claim */
    uint32_t slotless_held; /* rwlock read-locks held with no reader-slot */
} RdxHandle;

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define RDX_RWLOCK_SPIN_LIMIT 32
#define RDX_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void rdx_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define RDX_RWLOCK_WRITER_BIT 0x80000000U
#define RDX_RWLOCK_PID_MASK   0x7FFFFFFFU
#define RDX_RWLOCK_WR(pid)    (RDX_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & RDX_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
static inline int rdx_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void rdx_recover_stale_lock(RdxHandle *h, uint32_t observed_rwlock) {
    RdxHeader *hdr = h->hdr;
    uint32_t mypid = RDX_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec rdx_lock_timeout = { RDX_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t rdx_fork_gen = 1;
static pthread_once_t rdx_atfork_once = PTHREAD_ONCE_INIT;
static void rdx_on_fork_child(void) {
    __atomic_add_fetch(&rdx_fork_gen, 1, __ATOMIC_RELAXED);
}
static void rdx_atfork_init(void) {
    pthread_atfork(NULL, NULL, rdx_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void rdx_claim_reader_slot(RdxHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&rdx_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&rdx_atfork_once, rdx_atfork_init);
    /* Re-read after pthread_once: rdx_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&rdx_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % RDX_READER_SLOTS;
    for (uint32_t i = 0; i < RDX_READER_SLOTS; i++) {
        uint32_t s = (start + i) % RDX_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and rdx_recover_dead_readers won't drain them
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
static inline void rdx_atomic_sub_cap(uint32_t *p, uint32_t sub) {
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
 * Between our CAS and a follow-up store, a new process could claim the
 * slot and start populating these fields -- our stores would clobber its
 * state.  rdx_claim_reader_slot zeros all three on every claim, so
 * leaving stale values is harmless. */
static inline void rdx_drain_dead_slot(RdxHandle *h, uint32_t i, uint32_t pid) {
    RdxHeader *hdr = h->hdr;
    uint32_t expected = pid;
    /* ACQ_REL on success: RELEASE publishes pid=0 to other observers;
     * ACQUIRE syncs us with prior writes from the dead process to
     * waiters_parked/writers_parked.  On weakly-ordered archs (aarch64)
     * a plain RELAXED load before the CAS could miss those writes;
     * loading them after the CAS keeps them inside the acquire window. */
    if (!__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    uint32_t wp    = __atomic_load_n(&h->reader_slots[i].waiters_parked, __ATOMIC_RELAXED);
    uint32_t writp = __atomic_load_n(&h->reader_slots[i].writers_parked, __ATOMIC_RELAXED);
    if (wp)    rdx_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) rdx_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
}

/* Scan reader slots for dead-process recovery.
 *
 * For each dead PID with non-zero contributions to the shared rwlock,
 * rwlock_waiters, or rwlock_writers_waiting counters, drain its share back
 * out so live processes don't have to wait for the slow per-op timeout
 * decrement to drain it for them.
 *
 * For the main rwlock counter we use the "no live reader holds -> force-
 * reset to 0" trick (precise) because per-process attribution of the
 * subcount is racy across the inc-counter-then-inc-subcount window. */
static inline void rdx_recover_dead_readers(RdxHandle *h) {
    if (!h->reader_slots) return;
    RdxHeader *hdr = h->hdr;
    int any_live_reader = 0;
    int found_dead_reader = 0;

    /* Pass 1: classify slots.  Slots with dead pid and sc == 0 (no rwlock
     * contribution to lose) are wiped immediately to free the slot for
     * future claimants and drain any orphan parked-waiter counters.  Slots
     * with dead pid and sc > 0 are left intact in this pass: if force-
     * reset cannot fire (because a live reader is concurrently present),
     * wiping the dead slot would lose the only record of its orphan
     * rwlock contribution and strand writers permanently once the live
     * reader releases. */
    for (uint32_t i = 0; i < RDX_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (rdx_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        rdx_drain_dead_slot(h, i, pid);
    }

    /* Pass 2: only if force-reset will fire.  Issue the rwlock force-
     * reset CAS FIRST, while the window since pass 1's last scan is
     * still narrow (a handful of instructions, as in the original
     * single-pass code).  A new reader that started rdlock between
     * pass 1's scan and the CAS will either:
     *   (a) have already CAS'd rwlock from cur to cur+1 -- our CAS then
     *       fails (cur mismatched), recovery yields and a future
     *       cycle retries; or
     *   (b) be still in the subcount-bump phase -- our CAS sees the
     *       stale cur and resets to 0; the new reader's subsequent CAS
     *       rwlock(0 -> 1) succeeds cleanly.
     * Only after the CAS resolves do we wipe the deferred dead slots,
     * keeping that work outside the race-sensitive window. */
    /* A live reader with no slot (table was full) is invisible to the scan
     * above but still holds a +1 in the lock word; never force-reset under it. */
    if (__atomic_load_n(&hdr->slotless_readers, __ATOMIC_RELAXED) > 0)
        any_live_reader = 1;
    if (found_dead_reader && !any_live_reader) {
        /* ACQUIRE: a late reader's subcount++ (before its rwlock CAS) is then visible below. */
        uint32_t cur = __atomic_load_n(&hdr->rwlock, __ATOMIC_ACQUIRE);
        int drain_ok = 1;   /* keep dead slots if the reset doesn't fire */
        if (cur > 0 && cur < RDX_RWLOCK_WRITER_BIT) {
            /* Re-scan for a live reader (fail-safe: only suppresses a reset). */
            int live_now = __atomic_load_n(&hdr->slotless_readers, __ATOMIC_RELAXED) > 0;
            for (uint32_t i = 0; !live_now && i < RDX_READER_SLOTS; i++) {
                uint32_t p = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (p && rdx_pid_alive(p) &&
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
            for (uint32_t i = 0; i < RDX_READER_SLOTS; i++) {
                uint32_t p = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (p == 0 || rdx_pid_alive(p)) continue;
                rdx_drain_dead_slot(h, i, p);
            }
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters.  Called from rdlock and wrlock ETIMEDOUT
 * branches -- identical recovery logic in both. */
static inline void rdx_recover_after_timeout(RdxHandle *h) {
    RdxHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= RDX_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & RDX_RWLOCK_PID_MASK;
        if (!rdx_pid_alive(pid))
            rdx_recover_stale_lock(h, val);
    } else {
        rdx_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution.  Kept paired to make
 * accidental drift between global and per-slot counts impossible. */
static inline void rdx_park_reader(RdxHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void rdx_unpark_reader(RdxHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void rdx_park_writer(RdxHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void rdx_unpark_writer(RdxHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

/* Reader accounting: a reader mirrors its +1 in the lock word so dead-reader
 * recovery can see it. A slotted reader uses its slot subcount; a reader that
 * could not claim a slot (table full) uses the global hdr->slotless_readers,
 * so recovery's force-reset never fires out from under it. leave() peels
 * slotless first so a later slot claim cannot misattribute the decrement. */
static inline void rdx_reader_enter(RdxHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_readers, 1, __ATOMIC_RELAXED);
        h->slotless_held++;
    }
}
static inline void rdx_reader_leave(RdxHandle *h) {
    if (h->slotless_held > 0) {
        h->slotless_held--;
        __atomic_sub_fetch(&h->hdr->slotless_readers, 1, __ATOMIC_RELAXED);
    } else if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    }
}

static inline void rdx_rwlock_rdlock(RdxHandle *h) {
    rdx_claim_reader_slot(h);
    RdxHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    /* Claim subcount BEFORE bumping the shared rwlock counter.  This way
     * a concurrent writer-side recovery scan that sees our PID alive with
     * subcount > 0 will (correctly) defer force-reset, even while we are
     * still spinning trying to win the rwlock CAS.  Without this, a reader
     * killed between rwlock CAS-success and subcount++ would let recovery
     * force-reset rwlock to 0 underneath us, causing a UINT32_MAX wrap on
     * our eventual rdunlock dec. */
    rdx_reader_enter(h);
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Write-preferring: when lock is free (cur==0) and writers are
         * waiting, yield to let the writer acquire. When readers are
         * already active (cur>=1), new readers may join freely. */
        if (cur > 0 && cur < RDX_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < RDX_RWLOCK_SPIN_LIMIT, 1)) {
            rdx_rwlock_spin_pause();
            continue;
        }
        rdx_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= RDX_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &rdx_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                rdx_unpark_reader(h);
                rdx_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        rdx_unpark_reader(h);
        spin = 0;
    }
}

static inline void rdx_rwlock_rdunlock(RdxHandle *h) {
    RdxHeader *hdr = h->hdr;
    /* Release the shared counter BEFORE dropping our subcount so that
     * "any live PID with subcount > 0" is a reliable in-flight indicator
     * for the writer-side recovery scan.  Inverting these would create a
     * window where we still own a unit of rwlock but our slot subcount is
     * 0, letting recovery force-reset rwlock underneath us. */
    uint32_t after = __atomic_sub_fetch(&hdr->rwlock, 1, __ATOMIC_RELEASE);
    rdx_reader_leave(h);
    if (after == 0 && __atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void rdx_rwlock_wrlock(RdxHandle *h) {
    rdx_claim_reader_slot(h);  /* refresh cached_pid across fork */
    RdxHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = RDX_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < RDX_RWLOCK_SPIN_LIMIT, 1)) {
            rdx_rwlock_spin_pause();
            continue;
        }
        rdx_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &rdx_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                rdx_unpark_writer(h);
                rdx_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        rdx_unpark_writer(h);
        spin = 0;
    }
}

static inline void rdx_rwlock_wrunlock(RdxHandle *h) {
    RdxHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + node-pool / arena accessors
 *
 * Layout: Header -> reader_slots[1024] -> node_pool[node_cap] -> arena[arena_cap]
 * RdxNode is 8-byte aligned (sizeof %8 == 0) and RdxReaderSlot is 16 bytes,
 * so node_pool_off is 8-byte aligned.  The arena is raw bytes (no alignment
 * requirement) and follows the node pool.
 * ================================================================ */

typedef struct { uint64_t reader_slots, node_pool, arena; } RdxLayout;

static inline RdxLayout rdx_layout(uint32_t node_cap) {
    RdxLayout L;
    L.reader_slots = sizeof(RdxHeader);
    L.node_pool    = L.reader_slots + (uint64_t)RDX_READER_SLOTS * sizeof(RdxReaderSlot);
    L.arena        = L.node_pool + (uint64_t)node_cap * sizeof(RdxNode);
    return L;
}

static inline uint64_t rdx_total_size(uint32_t node_cap, uint32_t arena_cap) {
    RdxLayout L = rdx_layout(node_cap);
    return L.arena + (uint64_t)arena_cap;
}

static inline RdxNode *rdx_nodes(RdxHandle *h) {
    return (RdxNode *)((char *)h->base + h->hdr->node_pool_off);
}
static inline uint8_t *rdx_arena(RdxHandle *h) {
    return (uint8_t *)((char *)h->base + h->hdr->arena_off);
}

/* ================================================================
 * Node allocation + arena append.  Callers hold the WRITE lock.
 * ================================================================ */

/* Allocate a node: bump node_used, else 0 (pool exhausted).  Returns a zeroed
 * node index.  v1 has no freelist (delete is lazy and never frees nodes), so a
 * node always comes off the high-water mark.  The caller pre-checks capacity
 * before any mutation, so a 0 return must not happen mid-insert. */
static inline uint32_t rdx_alloc_node(RdxHandle *h) {
    RdxHeader *hdr = h->hdr;
    RdxNode *nodes = rdx_nodes(h);
    if (hdr->node_used < hdr->node_cap) {
        uint32_t idx = hdr->node_used++;
        memset(&nodes[idx], 0, sizeof(RdxNode));
        return idx;
    }
    return 0;
}

/* Append `len` bytes to the arena, returning the offset of the first byte.
 * Append-only: existing bytes never move, so pointers into the arena stay
 * valid across appends.  The caller pre-checked that len bytes fit. */
static inline uint32_t rdx_arena_append(RdxHandle *h, const uint8_t *bytes, uint32_t len) {
    RdxHeader *hdr = h->hdr;
    uint32_t off = hdr->arena_used;
    if (len) memcpy(rdx_arena(h) + off, bytes, len);
    hdr->arena_used += len;
    return off;
}

/* Worst case any single insert consumes: up to 2 new nodes (a split makes a
 * mid node + a leaf node) and up to klen arena bytes (the leaf's label).
 * v1 has no freelist, so the 2 nodes must come fresh from the high-water mark.
 * Returns 1 if both fit, 0 otherwise.  Caller holds the write lock. */
static inline int rdx_insert_has_room(RdxHandle *h, uint32_t klen) {
    RdxHeader *hdr = h->hdr;
    if (hdr->node_cap - hdr->node_used < 2) return 0;
    if (hdr->arena_cap - hdr->arena_used < klen) return 0;
    return 1;
}

/* ================================================================
 * Radix-tree core
 * ================================================================ */

#ifndef RDX_MIN
#define RDX_MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

/* Common-prefix length: number of leading bytes where a[i]==b[i], up to max. */
static inline uint32_t rdx_cpl(const uint8_t *a, const uint8_t *b, uint32_t max) {
    uint32_t i = 0;
    while (i < max && a[i] == b[i]) i++;
    return i;
}

/* Insert key -> value.  Returns 1 if a new key was added, 0 if an existing key
 * was updated.  Caller holds the write lock AND has verified rdx_insert_has_room
 * (so every rdx_alloc_node / rdx_arena_append below is guaranteed to succeed,
 * keeping the tree consistent -- no partial-split-on-OOM possibility). */
static inline int rdx_insert_locked(RdxHandle *h, const uint8_t *key, uint32_t klen, uint64_t value) {
    RdxHeader *hdr = h->hdr;
    RdxNode *nodes = rdx_nodes(h);
    uint8_t *arena = rdx_arena(h);
    uint32_t cur = hdr->root, kpos = 0;
    for (;;) {
        if (kpos == klen) {                       /* key ends here -> mark this node */
            int isnew = !nodes[cur].has_value;
            nodes[cur].has_value = 1;
            nodes[cur].value = value;
            if (isnew) hdr->keys++;
            return isnew;
        }
        uint8_t b = key[kpos];
        uint32_t ch = nodes[cur].children[b];
        if (ch == 0) {                            /* no child on b -> new leaf with the rest as its label */
            uint32_t leaf = rdx_alloc_node(h);
            nodes = rdx_nodes(h);                 /* base is stable, but re-fetch defensively after alloc */
            nodes[leaf].label_off = rdx_arena_append(h, key + kpos, klen - kpos);
            nodes[leaf].label_len = klen - kpos;
            nodes[leaf].has_value = 1;
            nodes[leaf].value = value;
            /* Publish the fully-initialized leaf before linking it in, so a
             * process that takes the lock after a mid-insert SIGKILL + dead-
             * writer recovery never sees children[b]==leaf while the leaf's
             * label_off/len are still garbage (which would drive an out-of-
             * bounds arena read). The link is the single-word commit; a crash
             * before it leaks the node but keeps the tree consistent. */
            __atomic_thread_fence(__ATOMIC_RELEASE);
            nodes[cur].children[b] = leaf;
            hdr->keys++;
            return 1;
        }
        /* match the child's label against key[kpos..] */
        const uint8_t *L = arena + nodes[ch].label_off;
        uint32_t llen = nodes[ch].label_len;
        uint32_t m = rdx_cpl(L, key + kpos, RDX_MIN(llen, klen - kpos));
        if (m == llen) {                          /* whole label matched -> descend */
            cur = ch;
            kpos += llen;
            continue;
        }
        /* partial match -> split the child's edge at m.
         * mid takes L[0..m-1]; child keeps L[m..] (sharing the same arena region).
         * Capture mid_first = L[m] BEFORE mutating ch's label_off (L is a pointer
         * into the arena and is unaffected by the label_off change, but be explicit). */
        uint8_t mid_first = L[m];
        uint32_t mid = rdx_alloc_node(h);
        nodes = rdx_nodes(h);
        nodes[mid].label_off = nodes[ch].label_off;       /* first m bytes */
        nodes[mid].label_len = m;
        nodes[ch].label_off += m;                         /* child keeps the remainder, same region */
        nodes[ch].label_len -= m;
        nodes[mid].children[mid_first] = ch;
        nodes[cur].children[b] = mid;
        if (kpos + m == klen) {                            /* the key ends exactly at the split point */
            nodes[mid].has_value = 1;
            nodes[mid].value = value;
            hdr->keys++;
            return 1;
        }
        uint32_t leaf = rdx_alloc_node(h);
        nodes = rdx_nodes(h);
        nodes[leaf].label_off = rdx_arena_append(h, key + kpos + m, klen - kpos - m);
        nodes[leaf].label_len = klen - kpos - m;
        nodes[leaf].has_value = 1;
        nodes[leaf].value = value;
        nodes[mid].children[key[kpos + m]] = leaf;
        hdr->keys++;
        return 1;
    }
}

/* Navigate `key` to its terminal node.  Returns the node index once the full
 * key is consumed, or 0 (the NIL sentinel) if any step diverges.  Read-only, so
 * the caller may hold the READ or write lock.  root is always >= 1, so a 0
 * return is an unambiguous "not found". */
static inline uint32_t rdx_find_locked(RdxHandle *h, const uint8_t *key, uint32_t klen) {
    RdxNode *nodes = rdx_nodes(h);
    uint8_t *arena = rdx_arena(h);
    uint32_t node_used = h->hdr->node_used, arena_used = h->hdr->arena_used;
    uint32_t cur = h->hdr->root, kpos = 0;
    for (;;) {
        if (kpos == klen) return cur;
        uint32_t ch = nodes[cur].children[key[kpos]];
        /* child index and label extent are read from the mmap'd
         * (locally attacker-writable) file; bound both before dereferencing.
         * Valid data always satisfies these, so it is a never-taken branch. */
        if (!ch || ch >= node_used) return 0;
        uint32_t loff = nodes[ch].label_off, llen = nodes[ch].label_len;
        if ((uint64_t)loff + llen > arena_used) return 0;
        if (klen - kpos < llen) return 0;
        if (memcmp(arena + loff, key + kpos, llen) != 0) return 0;
        cur = ch;
        kpos += llen;
    }
}

/* Exact lookup.  Returns 1 and sets *out if found, else 0.  Read-only (no path
 * compression) so the caller may hold the READ lock. */
static inline int rdx_lookup_locked(RdxHandle *h, const uint8_t *key, uint32_t klen, uint64_t *out) {
    uint32_t n = rdx_find_locked(h, key, klen);
    if (!n) return 0;
    RdxNode *nodes = rdx_nodes(h);
    if (nodes[n].has_value) { if (out) *out = nodes[n].value; return 1; }
    return 0;
}

/* Longest-prefix match: is some stored key a prefix of `key`?  Returns 1 and
 * sets *out to the value of the LONGEST such stored key, else 0.  Read-only. */
static inline int rdx_longest_prefix_locked(RdxHandle *h, const uint8_t *key, uint32_t klen, uint64_t *out) {
    RdxNode *nodes = rdx_nodes(h);
    uint8_t *arena = rdx_arena(h);
    uint32_t node_used = h->hdr->node_used, arena_used = h->hdr->arena_used;
    uint32_t cur = h->hdr->root, kpos = 0;
    int found = 0;
    if (nodes[cur].has_value) { if (out) *out = nodes[cur].value; found = 1; }  /* empty key stored */
    for (;;) {
        if (kpos == klen) break;
        uint32_t ch = nodes[cur].children[key[kpos]];
        /* same bound as rdx_find_locked -- child index and label
         * extent come from the attacker-writable mmap; reject on a bad value. */
        if (!ch || ch >= node_used) break;
        uint32_t loff = nodes[ch].label_off, llen = nodes[ch].label_len;
        if ((uint64_t)loff + llen > arena_used) break;
        if (klen - kpos < llen || memcmp(arena + loff, key + kpos, llen) != 0) break;
        cur = ch;
        kpos += llen;
        if (nodes[cur].has_value) { if (out) *out = nodes[cur].value; found = 1; }
    }
    return found;
}

/* Lazy delete: walk to the node; if found and has_value, clear it.  Returns
 * 1 if a key was removed, 0 if absent.  Does NOT free nodes or compact the
 * arena in v1.  Caller holds the write lock. */
static inline int rdx_delete_locked(RdxHandle *h, const uint8_t *key, uint32_t klen) {
    uint32_t n = rdx_find_locked(h, key, klen);
    if (!n) return 0;
    RdxNode *nodes = rdx_nodes(h);
    if (!nodes[n].has_value) return 0;
    nodes[n].has_value = 0;
    nodes[n].value = 0;
    h->hdr->keys--;
    return 1;
}

/* Reset to a single empty root: node_used=2, arena_used=0, keys=0, and a fresh
 * zeroed root.  Caller holds the write lock. */
static inline void rdx_clear_locked(RdxHandle *h) {
    RdxHeader *hdr = h->hdr;
    RdxNode *nodes = rdx_nodes(h);
    hdr->node_used = 2;
    hdr->arena_used = 0;
    hdr->keys = 0;
    memset(&nodes[hdr->root], 0, sizeof(RdxNode));   /* zero children + has_value + label */
}

/* ================================================================
 * Validate args + header init / setup / open / destroy
 * ================================================================ */

/* Validate create args.  Single source of truth: the XS layer does NOT
 * duplicate these range checks. */
static int rdx_validate_create_args(uint64_t node_cap, uint64_t arena_cap, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (node_cap < 2) { RDX_ERR("node_capacity must be >= 2 (NIL + root)"); return 0; }
    if (node_cap > RDX_MAX_NODES) { RDX_ERR("node_capacity must be <= %u", (unsigned)RDX_MAX_NODES); return 0; }
    if (arena_cap < 1) { RDX_ERR("arena_capacity must be >= 1"); return 0; }
    if (arena_cap > RDX_MAX_ARENA) { RDX_ERR("arena_capacity must be <= %u", (unsigned)RDX_MAX_ARENA); return 0; }
    /* Keep the whole mapping within size_t (matters on 32-bit, but we already
     * require 64-bit Perl; still, guard against absurd products). */
    {
        uint64_t total = rdx_total_size((uint32_t)node_cap, (uint32_t)arena_cap);
        if (total > (uint64_t)SIZE_MAX) { RDX_ERR("requested mapping too large"); return 0; }
    }
    return 1;
}

static inline void rdx_init_header(void *base, uint32_t node_cap, uint32_t arena_cap, uint64_t total_size) {
    RdxLayout L = rdx_layout(node_cap);
    RdxHeader *hdr = (RdxHeader *)base;
    /* Zero the header + reader-slot region (lock-recovery state).  The node
     * pool and arena are read only within [0,node_used)/[0,arena_used); a
     * fresh mapping is OS-zeroed, but we explicitly zero node 0 (NIL) and the
     * root below for clarity / for the reopen-of-anon path. */
    memset(base, 0, (size_t)L.node_pool);
    hdr->magic            = RDX_MAGIC;
    hdr->version          = RDX_VERSION;
    hdr->node_cap         = node_cap;
    hdr->arena_cap        = arena_cap;
    hdr->total_size       = total_size;
    hdr->reader_slots_off = L.reader_slots;
    hdr->node_pool_off    = L.node_pool;
    hdr->arena_off        = L.arena;
    {
        RdxNode *nodes = (RdxNode *)((char *)base + L.node_pool);
        memset(&nodes[0], 0, sizeof(RdxNode));   /* NIL sentinel */
        memset(&nodes[1], 0, sizeof(RdxNode));   /* root: empty label, no value, no children */
        hdr->root      = 1;
        hdr->node_used = 2;                      /* NIL + root */
        hdr->arena_used = 0;
        hdr->keys      = 0;
    }
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline RdxHandle *rdx_setup(void *base, size_t map_size,
                                   const char *path, int backing_fd) {
    RdxHeader *hdr = (RdxHeader *)base;
    RdxHandle *h = (RdxHandle *)calloc(1, sizeof(RdxHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (RdxReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by rdx_create reopen and rdx_open_fd).
 * Stored geometry wins on reopen; require total_size to equal both the size
 * the stored caps imply AND the actual file size, and all offsets to match
 * the canonical layout. */
static inline int rdx_validate_header(const RdxHeader *hdr, uint64_t file_size) {
    if (hdr->magic != RDX_MAGIC) return 0;
    if (hdr->version != RDX_VERSION) return 0;
    if (hdr->node_cap < 2 || hdr->node_cap > RDX_MAX_NODES) return 0;
    if (hdr->arena_cap < 1 || hdr->arena_cap > RDX_MAX_ARENA) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != rdx_total_size(hdr->node_cap, hdr->arena_cap)) return 0;
    RdxLayout L = rdx_layout(hdr->node_cap);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->node_pool_off != L.node_pool) return 0;
    if (hdr->arena_off != L.arena) return 0;
    if (hdr->root == 0 || hdr->root >= hdr->node_cap) return 0;
    if (hdr->node_used < 2 || hdr->node_used > hdr->node_cap) return 0;
    if (hdr->arena_used > hdr->arena_cap) return 0;
    return 1;
}

/* Securely obtain a fd for a file-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents. */
static int rdx_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { RDX_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        RDX_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    RDX_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static RdxHandle *rdx_create(const char *path, uint64_t node_cap_in, uint64_t arena_cap_in, mode_t mode, char *errbuf) {
    if (!rdx_validate_create_args(node_cap_in, arena_cap_in, errbuf)) return NULL;
    uint32_t node_cap = (uint32_t)node_cap_in;
    uint32_t arena_cap = (uint32_t)arena_cap_in;

    uint64_t total = rdx_total_size(node_cap, arena_cap);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { RDX_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = rdx_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { RDX_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { RDX_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(RdxHeader)) {
            RDX_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            RDX_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { RDX_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!rdx_validate_header((RdxHeader *)base, (uint64_t)st.st_size)) {
                RDX_ERR("invalid radix-tree file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return rdx_setup(base, map_size, path, -1);
        }
    }
    rdx_init_header(base, node_cap, arena_cap, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return rdx_setup(base, map_size, path, -1);
}

static RdxHandle *rdx_create_memfd(const char *name, uint64_t node_cap_in, uint64_t arena_cap_in, char *errbuf) {
    if (!rdx_validate_create_args(node_cap_in, arena_cap_in, errbuf)) return NULL;
    uint32_t node_cap = (uint32_t)node_cap_in;
    uint32_t arena_cap = (uint32_t)arena_cap_in;

    uint64_t total = rdx_total_size(node_cap, arena_cap);
    int fd = memfd_create(name ? name : "radix", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { RDX_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        RDX_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { RDX_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    rdx_init_header(base, node_cap, arena_cap, total);
    return rdx_setup(base, (size_t)total, NULL, fd);
}

static RdxHandle *rdx_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { RDX_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(RdxHeader)) { RDX_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { RDX_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!rdx_validate_header((RdxHeader *)base, (uint64_t)st.st_size)) {
        RDX_ERR("invalid radix-tree table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { RDX_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return rdx_setup(base, ms, NULL, myfd);
}

static void rdx_destroy(RdxHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a lock is still held (subcount>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&rdx_fork_gen, __ATOMIC_RELAXED) &&
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

static inline int rdx_msync(RdxHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

#endif /* RADIX_H */
