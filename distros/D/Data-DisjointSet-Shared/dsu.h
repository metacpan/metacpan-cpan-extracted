/*
 * dsu.h -- Shared-memory union-find (disjoint-set) for Linux
 *
 * Maintains a partition of a fixed universe of N integer elements (0..N-1)
 * into disjoint sets. union(a,b) merges the two sets containing a and b;
 * find(x) returns the canonical representative (root) of x's set; connected
 * tests whether two elements are in the same set. Path compression (path
 * halving) on find plus union by size give near-constant amortized time per
 * operation. The parent/size arrays live in a shared mapping so several
 * processes share one structure; a write-preferring futex rwlock with
 * reader-slot dead-process recovery guards mutation.
 *
 * NOTE: find / connected / set_size perform path compression -- they MUTATE
 * the structure -- so every accessor that calls dsu_find acquires the WRITE
 * lock. Only num_sets / capacity are true read-only operations.
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> parent[n] (uint32) -> size[n] (uint32)
 */

#ifndef DSU_H
#define DSU_H

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
#error "dsu.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define DSU_MAGIC        0x55534444U  /* "DDSU" (little-endian) */
#define DSU_VERSION      2            /* 2: added the occupancy bitmap region (layout change) */
#define DSU_ERR_BUFLEN   256
#define DSU_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */

/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these DSU_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all DSU_READER_SLOTS. */
#define DSU_OCC_WORDS   (((DSU_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define DSU_OCC_BYTES   ((uint64_t)DSU_OCC_WORDS * 8)      /* 128 bytes */
#define DSU_MAX_N        (1u << 31)   /* 2.1B elements: keeps n*8 well within size_t and size[] sums within uint32 */

#define DSU_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, DSU_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} DsuReaderSlot;

struct DsuHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t _pad0;                   /* 8 */
    uint32_t _pad1;                   /* 12 */

    /* ---- configuration / partition state ---- */
    uint32_t n;                       /* 16  number of elements = capacity     */
    uint32_t num_sets;                /* 20  current count of disjoint sets     */
    uint32_t _pad2;                   /* 24 */
    uint32_t _pad3;                   /* 28 */

    /* ---- offsets / size ---- */
    uint64_t total_size;              /* 32 */
    uint64_t reader_slots_off;        /* 40 */
    uint64_t parent_off;              /* 48 */
    uint64_t size_off;                /* 56 */

    /* ---- lock + stats ---- */
    uint32_t wlock;                   /* 64  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 68  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 72  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* 76  readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 80 */
    uint8_t  _pad[168];               /* 88..255 */
};
typedef struct DsuHeader DsuHeader;

_Static_assert(sizeof(DsuHeader) == 256, "DsuHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct DsuHandle {
    DsuHeader     *hdr;
    DsuReaderSlot *reader_slots;  /* DSU_READER_SLOTS entries */
    void          *base;          /* mmap base */
    uint32_t       n;             /* cached capacity (hdr->n is peer-writable; snapshot at attach) */
    uint32_t      *parent;        /* cached parent[] base from trusted layout, not hdr->parent_off */
    uint32_t      *size;          /* cached size[] base from trusted layout, not hdr->size_off */
    uint64_t      *occ;           /* DSU_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    size_t         mmap_size;
    char          *path;          /* backing file path (strdup'd) */
    int            backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t       my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;    /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* dsu_fork_gen value at last slot claim */
    uint32_t       slotless_held; /* read-locks this process holds with no reader-slot */
} DsuHandle;

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

#define DSU_RWLOCK_SPIN_LIMIT 32
#define DSU_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void dsu_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define DSU_RWLOCK_WRITER_BIT 0x80000000U
#define DSU_RWLOCK_PID_MASK   0x7FFFFFFFU
#define DSU_RWLOCK_WR(pid)    (DSU_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & DSU_RWLOCK_PID_MASK))

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
static inline int dsu_pid_is_zombie(uint32_t pid) {
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
static inline int dsu_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !dsu_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void dsu_recover_stale_lock(DsuHandle *h, uint32_t observed_wlock) {
    DsuHeader *hdr = h->hdr;
    uint32_t mypid = DSU_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec dsu_lock_timeout = { DSU_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t dsu_fork_gen = 1;
static pthread_once_t dsu_atfork_once = PTHREAD_ONCE_INIT;
static void dsu_on_fork_child(void) {
    __atomic_add_fetch(&dsu_fork_gen, 1, __ATOMIC_RELAXED);
}
static void dsu_atfork_init(void) {
    pthread_atfork(NULL, NULL, dsu_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void dsu_occ_set(DsuHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void dsu_occ_clear(DsuHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void dsu_claim_reader_slot(DsuHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&dsu_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&dsu_atfork_once, dsu_atfork_init);
    /* Re-read after pthread_once: dsu_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&dsu_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % DSU_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < DSU_READER_SLOTS; i++) {
        uint32_t s = (start + i) % DSU_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            dsu_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < DSU_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || dsu_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            dsu_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void dsu_recover_after_timeout(DsuHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= DSU_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & DSU_RWLOCK_PID_MASK;
        if (!dsu_pid_alive(pid))
            dsu_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void dsu_park(DsuHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void dsu_unpark(DsuHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void dsu_rdepth_inc(DsuHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void dsu_rdepth_dec(DsuHandle *h) {
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
static inline void dsu_reader_wake_drain(DsuHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void dsu_rwlock_rdlock(DsuHandle *h) {
    dsu_claim_reader_slot(h);
    DsuHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            dsu_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            dsu_rdepth_dec(h);
            dsu_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= DSU_RWLOCK_WRITER_BIT &&
            !dsu_pid_alive(cur & DSU_RWLOCK_PID_MASK)) {
            dsu_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < DSU_RWLOCK_SPIN_LIMIT, 1)) {
            dsu_rwlock_spin_pause();
            continue;
        }
        dsu_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &dsu_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                dsu_unpark(h);
                dsu_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        dsu_unpark(h);
        spin = 0;
    }
}

static inline void dsu_rwlock_rdunlock(DsuHandle *h) {
    dsu_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    dsu_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void dsu_rwlock_wrlock(DsuHandle *h) {
    dsu_claim_reader_slot(h);  /* refresh cached_pid across fork */
    DsuHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = DSU_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= DSU_RWLOCK_WRITER_BIT &&
            !dsu_pid_alive(expected & DSU_RWLOCK_PID_MASK)) {
            dsu_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < DSU_RWLOCK_SPIN_LIMIT, 1)) {
            dsu_rwlock_spin_pause();
            continue;
        }
        dsu_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &dsu_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                dsu_unpark(h);
                dsu_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        dsu_unpark(h);
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
         * this scan, so no held slot is skipped).  O(DSU_OCC_WORDS + live readers)
         * instead of O(DSU_READER_SLOTS). */
        for (uint32_t w = 0; w < DSU_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!dsu_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &dsu_lock_timeout, NULL, 0);
    }
}

static inline void dsu_rwlock_wrunlock(DsuHandle *h) {
    DsuHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> parent[n] (uint32) -> size[n] (uint32)
 * Both arrays are 4-byte words; the reader-slot region and the 8-byte-word occ
 * bitmap are multiples of 4 bytes, so parent_off and size_off are naturally
 * 4-byte aligned.
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> parent[] -> size[]. */
typedef struct { uint64_t reader_slots, occ, parent, size; } DsuLayout;

static inline DsuLayout dsu_layout(uint32_t n) {
    DsuLayout L;
    L.reader_slots = sizeof(DsuHeader);
    L.occ          = L.reader_slots + (uint64_t)DSU_READER_SLOTS * sizeof(DsuReaderSlot);
    L.parent       = L.occ + DSU_OCC_BYTES;
    L.size         = L.parent + (uint64_t)n * sizeof(uint32_t);
    return L;
}

static inline uint64_t dsu_total_size(uint32_t n) {
    DsuLayout L = dsu_layout(n);
    return L.size + (uint64_t)n * sizeof(uint32_t);   /* parent[n] + size[n] */
}

/* Return the cached, trusted-layout array bases.  We deliberately do NOT read
 * hdr->parent_off / hdr->size_off here: those live in the peer-writable header
 * and a lock-violating peer that corrupted them after we attached could aim the
 * base pointer anywhere, turning an in-range p[x] into an OOB read/write.  Both
 * were validated == dsu_layout(n) at attach and are re-derived from cached n. */
static inline uint32_t *dsu_parent(DsuHandle *h) {
    return h->parent;
}

static inline uint32_t *dsu_size(DsuHandle *h) {
    return h->size;
}

/* ================================================================
 * Union-find core (callers hold the WRITE lock -- find compresses)
 * ================================================================ */

/* Find the root of x with path halving (every other node on the path is
 * relinked to its grandparent).  MUTATING -- the caller must hold the write
 * lock.  x must already be range-checked (< n) by the XS layer. */
static inline uint32_t dsu_find(DsuHandle *h, uint32_t x) {
    uint32_t *p = dsu_parent(h);
    uint32_t n = h->n;                    /* cached at attach; hdr->n is peer-writable */
    if (x >= n) return x;                 /* callers range-check; be defensive */
    while (p[x] != x) {
        /* parent[] values come from the (possibly attacker-tampered) backing
         * file. Bound each before using it as an index so a poisoned parent
         * cannot drive an out-of-bounds read or path-halving write (CWE-787);
         * on a bad value stop and return the current node as a pseudo-root. */
        uint32_t px = p[x];
        if (px >= n) break;
        uint32_t gpx = p[px];
        if (gpx >= n) break;
        p[x] = gpx;                       /* path halving */
        x = gpx;
    }
    return x;
}

/* Union the sets containing a and b by size (the larger-sized root wins, so
 * the tree stays shallow).  Returns 1 if the two were in different sets and
 * are now merged, 0 if they were already in the same set.  Caller holds the
 * write lock; a and b are range-checked. */
static inline int dsu_union_locked(DsuHandle *h, uint32_t a, uint32_t b) {
    uint32_t ra = dsu_find(h, a), rb = dsu_find(h, b);
    if (ra == rb) return 0;
    uint32_t *p  = dsu_parent(h);
    uint32_t *sz = dsu_size(h);
    if (sz[ra] < sz[rb]) { uint32_t t = ra; ra = rb; rb = t; }
    p[rb] = ra;
    sz[ra] += sz[rb];
    h->hdr->num_sets--;
    return 1;
}

/* Whether a and b are in the same set (mutates via path compression). */
static inline int dsu_connected_locked(DsuHandle *h, uint32_t a, uint32_t b) {
    return dsu_find(h, a) == dsu_find(h, b);
}

/* Size of the set containing x (mutates via path compression). */
static inline uint32_t dsu_set_size_locked(DsuHandle *h, uint32_t x) {
    return dsu_size(h)[dsu_find(h, x)];
}

/* Reset to all singletons: parent[i]=i, size[i]=1, num_sets=n.
 * Caller holds the write lock. */
static inline void dsu_reset_locked(DsuHandle *h) {
    uint32_t *p = dsu_parent(h);
    uint32_t *sz = dsu_size(h);
    uint32_t n = h->n;                    /* cached at attach; hdr->n is peer-writable */
    for (uint32_t i = 0; i < n; i++) { p[i] = i; sz[i] = 1; }
    h->hdr->num_sets = n;
}

/* ================================================================
 * Validate args + header init / setup / open / destroy
 * ================================================================ */

/* Validate create args.  Single source of truth: the XS layer does NOT
 * duplicate this range check. */
static int dsu_validate_create_args(uint64_t n, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (n < 1) { DSU_ERR("n must be >= 1"); return 0; }
    if (n > DSU_MAX_N) { DSU_ERR("n must be <= %u", (unsigned)DSU_MAX_N); return 0; }
    return 1;
}

static inline void dsu_init_header(void *base, uint32_t n, uint64_t total_size) {
    DsuLayout L = dsu_layout(n);
    DsuHeader *hdr = (DsuHeader *)base;
    /* Explicitly zero the header + reader-slot region (lock-recovery state);
       the parent/size arrays are initialized explicitly below. */
    memset(base, 0, (size_t)L.parent);
    hdr->magic            = DSU_MAGIC;
    hdr->version          = DSU_VERSION;
    hdr->n                = n;
    hdr->num_sets         = n;
    hdr->total_size       = total_size;
    hdr->reader_slots_off = L.reader_slots;
    hdr->parent_off       = L.parent;
    hdr->size_off         = L.size;
    {
        uint32_t *p  = (uint32_t *)((char *)base + L.parent);
        uint32_t *sz = (uint32_t *)((char *)base + L.size);
        for (uint32_t i = 0; i < n; i++) { p[i] = i; sz[i] = 1; }
    }
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline DsuHandle *dsu_setup(void *base, size_t map_size,
                                   const char *path, int backing_fd) {
    DsuHeader *hdr = (DsuHeader *)base;
    DsuHandle *h = (DsuHandle *)calloc(1, sizeof(DsuHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (DsuReaderSlot *)((uint8_t *)base + sizeof(DsuHeader));  /* trusted layout, not the peer-writable header offset */
    /* Snapshot capacity ONCE into a local and re-verify it against the mapping
     * size before trusting it: a write-peer can flip hdr->n in the window
     * between dsu_validate_header and here (after flock(LOCK_UN)/close on the
     * create-attach path, or after F_DUPFD_CLOEXEC on the open_fd path), so the
     * earlier validation does not pin the value we cache.  Derive array bases
     * from the TRUSTED layout of the verified local.  All hot-path
     * bounds/indexing use these cached copies so a later peer edit to hdr->n /
     * hdr->parent_off / hdr->size_off cannot drive OOB access. */
    {
        uint32_t n = __atomic_load_n(&hdr->n, __ATOMIC_ACQUIRE);
        if (n < 1 || n > DSU_MAX_N || dsu_total_size(n) != (uint64_t)map_size) {
            munmap(base, map_size);
            if (backing_fd >= 0) close(backing_fd);
            free(h);
            return NULL;
        }
        DsuLayout L = dsu_layout(n);
        h->n        = n;
        h->occ      = (uint64_t *)((uint8_t *)base + L.occ);    /* trusted layout offset */
        h->parent   = (uint32_t *)((uint8_t *)base + L.parent);
        h->size     = (uint32_t *)((uint8_t *)base + L.size);
    }
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by dsu_create reopen and dsu_open_fd).
 * Stored n wins on reopen; require total_size == the size n implies and ==
 * the actual file size, and all offsets to match the canonical layout. */
static inline int dsu_validate_header(const DsuHeader *hdr, uint64_t file_size) {
    if (hdr->magic != DSU_MAGIC) return 0;
    if (hdr->version != DSU_VERSION) return 0;
    if (hdr->n < 1 || hdr->n > DSU_MAX_N) return 0;
    if (hdr->num_sets < 1 || hdr->num_sets > hdr->n) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != dsu_total_size(hdr->n)) return 0;
    DsuLayout L = dsu_layout(hdr->n);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->parent_off != L.parent) return 0;
    if (hdr->size_off != L.size) return 0;
    return 1;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at mode,
 * default 0600), or attach an existing file (O_RDWR|O_NOFOLLOW, no O_CREAT). */
static int dsu_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { DSU_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        DSU_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    DSU_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static DsuHandle *dsu_create(const char *path, uint64_t n_in, mode_t mode, char *errbuf) {
    if (!dsu_validate_create_args(n_in, errbuf)) return NULL;
    uint32_t n = (uint32_t)n_in;

    uint64_t total = dsu_total_size(n);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { DSU_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = dsu_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { DSU_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { DSU_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(DsuHeader)) {
            DSU_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            DSU_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            DSU_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { DSU_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!dsu_validate_header((DsuHeader *)base, (uint64_t)st.st_size)) {
                DSU_ERR("invalid disjoint-set file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return dsu_setup(base, map_size, path, -1);
        }
    }
    dsu_init_header(base, n, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return dsu_setup(base, map_size, path, -1);
}

static DsuHandle *dsu_create_memfd(const char *name, uint64_t n_in, char *errbuf) {
    if (!dsu_validate_create_args(n_in, errbuf)) return NULL;
    uint32_t n = (uint32_t)n_in;

    uint64_t total = dsu_total_size(n);
    int fd = memfd_create(name ? name : "dsu", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { DSU_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        DSU_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { DSU_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    dsu_init_header(base, n, total);
    return dsu_setup(base, (size_t)total, NULL, fd);
}

static DsuHandle *dsu_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { DSU_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(DsuHeader)) { DSU_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { DSU_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!dsu_validate_header((DsuHeader *)base, (uint64_t)st.st_size)) {
        DSU_ERR("invalid disjoint-set table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { DSU_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return dsu_setup(base, ms, NULL, myfd);
}

static void dsu_destroy(DsuHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&dsu_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        dsu_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int dsu_msync(DsuHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

#endif /* DSU_H */
