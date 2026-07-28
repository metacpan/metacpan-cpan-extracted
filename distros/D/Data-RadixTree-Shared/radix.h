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
 * Layout: Header -> reader_slots[1024] -> occ_bitmap -> node_pool[node_cap] -> label_arena[arena_cap]
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
#define RDX_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define RDX_ERR_BUFLEN   256
#ifndef RDX_READER_SLOTS
#define RDX_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these RDX_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all RDX_READER_SLOTS. */
#define RDX_OCC_WORDS   (((RDX_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define RDX_OCC_BYTES   ((uint64_t)RDX_OCC_WORDS * 8)      /* 128 bytes */
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
} RdxReaderSlot;

struct RdxHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t node_cap;                /* 8   node-pool capacity (slots, incl. NIL) */
    uint32_t node_used;               /* 12  high-water of ever-allocated nodes (incl. NIL+root) */
    uint32_t root;                    /* 16  root node index (allocated at create) */
    uint32_t arena_cap;               /* 20  label-arena capacity in bytes */
    uint32_t arena_used;              /* 24  bytes used in the arena */
    uint32_t free_head;               /* 28  head of the free-node list, 0 == empty (node 0 is
                                       *     NIL so it can never be on the list).  Reuses the
                                       *     slot this field originally had, so the on-disk
                                       *     format is unchanged: existing files carry 0 here,
                                       *     which reads correctly as "no free nodes". */
    uint64_t keys;                    /* 32  count of stored keys */
    uint64_t total_size;              /* 40 */
    uint64_t reader_slots_off;        /* 48 */
    uint64_t node_pool_off;           /* 56 */
    uint64_t arena_off;               /* 64 */
    uint32_t wlock;                   /* 72  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 76  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 80  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct RdxHeader RdxHeader;

_Static_assert(sizeof(RdxHeader) == 256, "RdxHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct RdxHandle {
    RdxHeader     *hdr;
    RdxReaderSlot *reader_slots;  /* RDX_READER_SLOTS entries */
    uint64_t      *occ;           /* RDX_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void          *base;          /* mmap base */
    /* Fixed geometry cached at attach from validated header.  These bound every
     * node-pool / arena access so a lock-violating peer that later corrupts the
     * peer-writable header (node_cap/arena_cap/node_pool_off/arena_off) cannot
     * turn a live index or offset into an out-of-bounds reference. */
    uint32_t       node_cap;      /* node-pool capacity (array size, incl. NIL) */
    uint32_t       arena_cap;     /* label-arena capacity in bytes */
    uint64_t       node_pool_off; /* node-pool offset from trusted layout */
    uint64_t       arena_off;     /* arena offset from trusted layout */
    size_t         mmap_size;
    char          *path;          /* backing file path (strdup'd) */
    int            backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t       my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;    /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* rdx_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} RdxHandle;

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

#define RDX_RWLOCK_SPIN_LIMIT 32
#define RDX_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void rdx_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define RDX_RWLOCK_WRITER_BIT 0x80000000U
#define RDX_RWLOCK_PID_MASK   0x7FFFFFFFU
#define RDX_RWLOCK_WR(pid)    (RDX_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & RDX_RWLOCK_PID_MASK))

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
static inline int rdx_pid_is_zombie(uint32_t pid) {
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
static inline int rdx_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !rdx_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void rdx_recover_stale_lock(RdxHandle *h, uint32_t observed_wlock) {
    RdxHeader *hdr = h->hdr;
    uint32_t mypid = RDX_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
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

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void rdx_occ_set(RdxHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void rdx_occ_clear(RdxHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
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
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < RDX_READER_SLOTS; i++) {
        uint32_t s = (start + i) % RDX_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            rdx_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < RDX_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || rdx_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            rdx_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void rdx_recover_after_timeout(RdxHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= RDX_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & RDX_RWLOCK_PID_MASK;
        if (!rdx_pid_alive(pid))
            rdx_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void rdx_park(RdxHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void rdx_unpark(RdxHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void rdx_rdepth_inc(RdxHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void rdx_rdepth_dec(RdxHandle *h) {
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
static inline void rdx_reader_wake_drain(RdxHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void rdx_rwlock_rdlock(RdxHandle *h) {
    rdx_claim_reader_slot(h);
    RdxHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            rdx_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            rdx_rdepth_dec(h);
            rdx_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= RDX_RWLOCK_WRITER_BIT &&
            !rdx_pid_alive(cur & RDX_RWLOCK_PID_MASK)) {
            rdx_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < RDX_RWLOCK_SPIN_LIMIT, 1)) {
            rdx_rwlock_spin_pause();
            continue;
        }
        rdx_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &rdx_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                rdx_unpark(h);
                rdx_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        rdx_unpark(h);
        spin = 0;
    }
}

static inline void rdx_rwlock_rdunlock(RdxHandle *h) {
    rdx_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    rdx_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void rdx_rwlock_wrlock(RdxHandle *h) {
    rdx_claim_reader_slot(h);  /* refresh cached_pid across fork */
    RdxHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = RDX_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= RDX_RWLOCK_WRITER_BIT &&
            !rdx_pid_alive(expected & RDX_RWLOCK_PID_MASK)) {
            rdx_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < RDX_RWLOCK_SPIN_LIMIT, 1)) {
            rdx_rwlock_spin_pause();
            continue;
        }
        rdx_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &rdx_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                rdx_unpark(h);
                rdx_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        rdx_unpark(h);
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
         * this scan, so no held slot is skipped).  O(RDX_OCC_WORDS + live readers)
         * instead of O(RDX_READER_SLOTS). */
        for (uint32_t w = 0; w < RDX_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!rdx_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &rdx_lock_timeout, NULL, 0);
    }
}

static inline void rdx_rwlock_wrunlock(RdxHandle *h) {
    RdxHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + node-pool / arena accessors
 *
 * Layout: Header -> reader_slots[1024] -> occ_bitmap -> node_pool[node_cap] -> arena[arena_cap]
 * RdxNode is 8-byte aligned (sizeof %8 == 0), RdxReaderSlot is 16 bytes, and the
 * occ bitmap is RDX_OCC_BYTES (a multiple of 8), so node_pool_off stays 8-byte
 * aligned.  The arena is raw bytes (no alignment requirement) after the pool.
 * ================================================================ */

typedef struct { uint64_t reader_slots, occ, node_pool, arena; } RdxLayout;

static inline RdxLayout rdx_layout(uint32_t node_cap) {
    RdxLayout L;
    L.reader_slots = sizeof(RdxHeader);
    L.occ          = L.reader_slots + (uint64_t)RDX_READER_SLOTS * sizeof(RdxReaderSlot);
    L.node_pool    = L.occ + RDX_OCC_BYTES;
    L.arena        = L.node_pool + (uint64_t)node_cap * sizeof(RdxNode);
    return L;
}

static inline uint64_t rdx_total_size(uint32_t node_cap, uint32_t arena_cap) {
    RdxLayout L = rdx_layout(node_cap);
    return L.arena + (uint64_t)arena_cap;
}

static inline RdxNode *rdx_nodes(RdxHandle *h) {
    return (RdxNode *)((char *)h->base + h->node_pool_off);   /* cached trusted offset, not peer-writable header */
}
static inline uint8_t *rdx_arena(RdxHandle *h) {
    return (uint8_t *)((char *)h->base + h->arena_off);       /* cached trusted offset, not peer-writable header */
}

/* ================================================================
 * Node allocation + arena append.  Callers hold the WRITE lock.
 * ================================================================ */

/* Allocate a node: bump node_used, else 0 (pool exhausted).  Returns a zeroed
 * node index.  v1 has no freelist (delete is lazy and never frees nodes), so a
 * node always comes off the high-water mark.  The caller pre-checks capacity
 * before any mutation, so a 0 return must not happen mid-insert. */
/* Push a node onto the free list.  Callers must hold the write lock and must
 * have already made the node unreachable from the tree.  Node 0 is NIL and is
 * never freed.  The free-list link lives in the dead node's label_off. */
static inline void rdx_free_node(RdxHandle *h, uint32_t idx) {
    if (idx == 0 || idx >= h->node_cap) return;   /* never recycle NIL or an out-of-pool index */
    RdxHeader *hdr = h->hdr;
    RdxNode *nodes = rdx_nodes(h);
    memset(&nodes[idx], 0, sizeof(RdxNode));
    nodes[idx].label_off = hdr->free_head;        /* next-free link (0 terminates) */
    hdr->free_head = idx;
}

static inline uint32_t rdx_alloc_node(RdxHandle *h) {
    RdxHeader *hdr = h->hdr;
    RdxNode *nodes = rdx_nodes(h);
    /* Recycle first.  free_head is peer-writable, so bound it against the cached
     * pool capacity before dereferencing: a corrupt value must never index out of
     * the node pool (an in-range corrupt value can only confuse the tree, which is
     * the same trust level as any other header field). */
    uint32_t idx = hdr->free_head;
    if (idx != 0 && idx < h->node_cap) {
        uint32_t next = nodes[idx].label_off;
        hdr->free_head = (next < h->node_cap) ? next : 0;
        memset(&nodes[idx], 0, sizeof(RdxNode));
        return idx;
    }
    if (hdr->node_used < h->node_cap) {   /* cached cap: the write index must stay in the real pool */
        idx = hdr->node_used++;
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
    /* off is the peer-writable arena_used; the caller pre-checked room against
     * the cached cap, but re-verify here so a concurrent lock-violating peer
     * that inflated arena_used cannot drive this memcpy past the arena. */
    if (len) {
        if ((uint64_t)off + len > h->arena_cap) return off;   /* refuse OOB write */
        memcpy(rdx_arena(h) + off, bytes, len);
    }
    hdr->arena_used += len;
    return off;
}

/* Worst case any single insert consumes: the copy-on-write edge split
 * transiently allocates THREE nodes (mid + ch2 + the new leaf) before the
 * displaced child is recycled post-commit (net consumption is 2), plus up to
 * klen arena bytes (the leaf's label).  Returns 1 if both fit, 0 otherwise.
 * Caller holds the write lock. */
#define RDX_INSERT_MAX_ALLOC 3

/* Count the nodes a single insert can draw on: fresh high-water slots plus
 * free-list entries.  rdx_alloc_node recycles before bumping the high-water
 * mark, so both sources must count -- checking the high-water mark alone
 * would refuse inserts that recycled nodes could satisfy, and (pre-fix)
 * checking it against 2 instead of 3 let a split run out of nodes mid-way
 * and return 0, which insert reported as "key already existed, updated"
 * while the key was never stored.
 * The free-list head and links live in peer-writable shared memory, threaded
 * through label_off: walking at most the remaining need keeps a corrupt list
 * containing a cycle bounded here, and every link is checked against the
 * cached pool capacity before it is dereferenced -- the same bounds
 * rdx_alloc_node applies when it pops.  The walk runs under the caller's
 * write lock, so a well-formed list cannot change under it. */
static inline int rdx_nodes_available(RdxHandle *h, uint32_t need) {
    RdxHeader *hdr = h->hdr;
    /* Cached cap: the used counter is peer-writable, so compute headroom
     * against the fixed geometry (and clamp an inflated used-mark to "no
     * high-water room", so the unsigned subtraction can never wrap to a huge
     * "room available"). */
    uint32_t avail = (hdr->node_used < h->node_cap) ? h->node_cap - hdr->node_used : 0;
    RdxNode *nodes = rdx_nodes(h);
    uint32_t idx = hdr->free_head;
    while (avail < need && idx != 0 && idx < h->node_cap) {
        avail++;
        idx = nodes[idx].label_off;
    }
    return avail >= need;
}

static inline int rdx_insert_has_room(RdxHandle *h, uint32_t klen) {
    RdxHeader *hdr = h->hdr;
    if (!rdx_nodes_available(h, RDX_INSERT_MAX_ALLOC)) return 0;
    /* Cached cap, same anti-wrap guard as above for the peer-writable
     * arena_used. */
    if (hdr->arena_used > h->arena_cap || h->arena_cap - hdr->arena_used < klen) return 0;
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
    if (cur == 0 || cur >= h->node_cap) return 0; /* root read from peer-writable header; keep the index in-pool */
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
        /* child index is read from the peer-writable mmap; an out-of-pool value
         * (like the read paths' `ch >= node_used` reject) is treated as absent so
         * the corrupt link is overwritten by a fresh in-pool leaf below, never
         * followed into an out-of-bounds node dereference / OOB child write. */
        if (ch == 0 || ch >= h->node_cap) {       /* no child on b -> new leaf with the rest as its label */
            uint32_t leaf = rdx_alloc_node(h);
            nodes = rdx_nodes(h);                 /* base is stable, but re-fetch defensively after alloc */
            /* Pool exhausted: rdx_alloc_node returns 0, which is the NIL
             * sentinel. Writing through it corrupts NIL (every read path
             * treats 0 as "not found") and linking children[b]=0 silently
             * drops the key while insert still reports success. Fail instead. */
            if (!leaf) return 0;
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
        /* match the child's label against key[kpos..].  label_off/label_len also
         * come from the peer-writable mmap; clamp the extent against the cached
         * arena capacity (as the read paths do with `loff + llen > arena_used`)
         * before forming arena + label_off or reading/adjusting the label, so a
         * corrupted offset can never drive an out-of-bounds arena read or an OOB
         * label_off/label_len write on the split path below. */
        uint32_t loff = nodes[ch].label_off, llen = nodes[ch].label_len;
        if ((uint64_t)loff + llen > h->arena_cap) return 0;
        const uint8_t *L = arena + loff;
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
        /* Copy-on-write split.  Build a NEW child (ch2) that carries the
         * remainder label and inherits ch's children/value, plus the new middle
         * node, and leave the live tree COMPLETELY untouched until one final
         * store publishes mid.
         *
         * The previous in-place version truncated ch's label (label_off += m)
         * before publishing mid, so a crash in that window left `cur` pointing
         * at a child whose label had lost its first m bytes -- silently losing
         * every key beneath it.  Publishing first instead would leave the prefix
         * counted twice, so NEITHER in-place ordering is crash-safe; only
         * copy-on-write is.  The displaced ch is recycled AFTER the commit, so a
         * crash between the two only leaks one node (reclaimed by the free list)
         * rather than corrupting the tree.  Node accounting is unchanged versus
         * the old code: the extra allocation is paid for by recycling ch. */
        uint32_t mid = rdx_alloc_node(h);
        /* Pool exhausted -> 0 == NIL; bail before touching anything, so the tree
         * is left exactly as it was rather than writing through NIL. */
        if (!mid) return 0;
        uint32_t ch2 = rdx_alloc_node(h);
        if (!ch2) { rdx_free_node(h, mid); return 0; }
        uint32_t leaf = 0;
        if (kpos + m != klen) {                            /* key continues past the split */
            leaf = rdx_alloc_node(h);
            if (!leaf) { rdx_free_node(h, ch2); rdx_free_node(h, mid); return 0; }
        }
        nodes = rdx_nodes(h);
        nodes[ch2] = nodes[ch];                            /* inherit children/value */
        nodes[ch2].label_off = nodes[ch].label_off + m;    /* remainder, same arena region */
        nodes[ch2].label_len = nodes[ch].label_len - m;
        nodes[mid].label_off = nodes[ch].label_off;        /* first m bytes */
        nodes[mid].label_len = m;
        nodes[mid].children[mid_first] = ch2;
        if (leaf) {
            nodes[leaf].label_off = rdx_arena_append(h, key + kpos + m, klen - kpos - m);
            nodes[leaf].label_len = klen - kpos - m;
            nodes[leaf].has_value = 1;
            nodes[leaf].value = value;
            nodes[mid].children[key[kpos + m]] = leaf;
        } else {                                           /* key ends exactly at the split point */
            nodes[mid].has_value = 1;
            nodes[mid].value = value;
        }
        /* Single-word commit: everything above is unreachable until this store. */
        __atomic_store_n(&nodes[cur].children[b], mid, __ATOMIC_RELEASE);
        rdx_free_node(h, ch);                              /* displaced: recycle post-commit */
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
    /* Bounds come from the peer-writable header; clamp the mutable used-marks to
     * the cached fixed capacities so an inflated node_used/arena_used can never
     * admit an out-of-pool child index or out-of-arena label extent. */
    uint32_t node_used = h->hdr->node_used, arena_used = h->hdr->arena_used;
    if (node_used > h->node_cap)  node_used  = h->node_cap;
    if (arena_used > h->arena_cap) arena_used = h->arena_cap;
    uint32_t cur = h->hdr->root, kpos = 0;
    if (cur == 0 || cur >= node_used) return 0;   /* root read from peer-writable header */
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
    /* Same clamp as rdx_find_locked: the used-marks are peer-writable, so cap
     * them at the cached fixed geometry before they bound any array access. */
    uint32_t node_used = h->hdr->node_used, arena_used = h->hdr->arena_used;
    if (node_used > h->node_cap)  node_used  = h->node_cap;
    if (arena_used > h->arena_cap) arena_used = h->arena_cap;
    uint32_t cur = h->hdr->root, kpos = 0;
    int found = 0;
    if (cur == 0 || cur >= node_used) return 0;   /* root read from peer-writable header */
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
    /* Drop the recycle list too. It names nodes above the reset high-water
     * mark, so leaving it would hand the same node out twice -- once popped
     * from the stale list and once from the bump path -- silently losing the
     * keys stored under whichever insert lost the race. */
    hdr->free_head = 0;
    if (hdr->root && hdr->root < h->node_cap)        /* root is peer-writable; keep the memset in-pool */
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
    h->reader_slots = (RdxReaderSlot *)((uint8_t *)base + sizeof(RdxHeader));  /* trusted layout, not the peer-writable header offset */
    /* Cache fixed geometry from the (already-validated) header and derive the
     * pool/arena offsets from the canonical layout -- never re-read the
     * peer-writable node_pool_off/arena_off/node_cap/arena_cap on the hot path. */
    {
        RdxLayout L = rdx_layout(hdr->node_cap);
        h->occ           = (uint64_t *)((uint8_t *)base + L.occ);   /* trusted layout offset */
        h->node_cap      = hdr->node_cap;
        h->arena_cap     = hdr->arena_cap;
        h->node_pool_off = L.node_pool;
        h->arena_off     = L.arena;
    }
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
    if (hdr->free_head >= hdr->node_cap) return 0;   /* 0 == empty; any real entry must be in-pool */
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
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            RDX_ERR("%s: refusing to initialize file not owned by us", path);
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
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&rdx_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        rdx_occ_clear(h, h->my_slot_idx);
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
