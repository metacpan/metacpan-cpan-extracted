/*
 * fenwick.h -- Shared-memory Fenwick tree (binary indexed tree) for Linux
 *
 * A fixed-size array of n signed int64 positions supporting O(log n) point
 * update and prefix-sum query: add a delta at a position, ask the sum over any
 * prefix or range, or binary-search for the position where a cumulative total
 * is reached (rank / weighted lookup).  The tree lives in a shared mapping so
 * several processes update and query one structure; a write-preferring futex
 * rwlock with reader-slot dead-process recovery guards mutation.  Two trees of
 * equal size can be merged (element-wise add -- a Fenwick tree is linear).
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> tree[(n+1) int64]  (1-indexed, slot 0 unused)
 */

#ifndef FEN_H
#define FEN_H

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
#error "fenwick.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define FEN_MAGIC        0x574E4546U  /* Fenwick */
#define FEN_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define FEN_ERR_BUFLEN   256
#ifndef FEN_READER_SLOTS
#define FEN_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these FEN_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all FEN_READER_SLOTS. */
#define FEN_OCC_WORDS   (((FEN_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define FEN_OCC_BYTES   ((uint64_t)FEN_OCC_WORDS * 8)      /* 128 bytes */
#define FEN_MIN_N        1
#define FEN_MAX_N        0x100000000ULL /* 2^32 positions; (n+1)*8-byte tree cap (~32 GiB) */

#define FEN_MODE_POINT   0U   /* single BIT: point update + prefix/range query */
#define FEN_MODE_RANGE   1U   /* two BITs: range update (range_add) + range query */

#define FEN_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, FEN_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} FenReaderSlot;

struct FenHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t mode;                    /* 8   FEN_MODE_POINT | FEN_MODE_RANGE */
    uint32_t _pad1;                   /* 12 */
    uint64_t n;                       /* 16  number of positions (1..n); tree has n+1 int64 slots */
    uint64_t tree2_off;               /* 24  second BIT (range mode; 0 in point mode) */
    uint64_t capacity;                /* 32  == n (kept for family stats parity) */
    uint64_t _reserved1;              /* 40 */
    uint64_t total_size;              /* 48 */
    uint64_t reader_slots_off;        /* 56 */
    uint64_t tree_off;                /* 64 */
    uint32_t wlock;                   /* 72  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 76  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 80  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct FenHeader FenHeader;

_Static_assert(sizeof(FenHeader) == 256, "FenHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct FenHandle {
    FenHeader     *hdr;
    FenReaderSlot *reader_slots;  /* FEN_READER_SLOTS entries */
    uint64_t      *occ;          /* FEN_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      tree_off;      /* validated tree-array offset, cached: never re-read from the peer-writable header */
    uint64_t      tree2_off;     /* second BIT offset (range mode), cached; 0 in point mode */
    uint32_t      mode;          /* FEN_MODE_* (cached from validated header) */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* fen_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} FenHandle;

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

#define FEN_RWLOCK_SPIN_LIMIT 32
#define FEN_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void fen_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define FEN_RWLOCK_WRITER_BIT 0x80000000U
#define FEN_RWLOCK_PID_MASK   0x7FFFFFFFU
#define FEN_RWLOCK_WR(pid)    (FEN_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & FEN_RWLOCK_PID_MASK))

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
static inline int fen_pid_is_zombie(uint32_t pid) {
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
static inline int fen_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !fen_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void fen_recover_stale_lock(FenHandle *h, uint32_t observed_wlock) {
    FenHeader *hdr = h->hdr;
    uint32_t mypid = FEN_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec fen_lock_timeout = { FEN_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t fen_fork_gen = 1;
static pthread_once_t fen_atfork_once = PTHREAD_ONCE_INIT;
static void fen_on_fork_child(void) {
    __atomic_add_fetch(&fen_fork_gen, 1, __ATOMIC_RELAXED);
}
static void fen_atfork_init(void) {
    pthread_atfork(NULL, NULL, fen_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void fen_occ_set(FenHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void fen_occ_clear(FenHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so that
 * fork()'d children pick up their own slot lazily instead of sharing the
 * parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void fen_claim_reader_slot(FenHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&fen_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&fen_atfork_once, fen_atfork_init);
    /* Re-read after pthread_once: fen_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&fen_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % FEN_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < FEN_READER_SLOTS; i++) {
        uint32_t s = (start + i) % FEN_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            fen_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < FEN_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || fen_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            fen_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void fen_recover_after_timeout(FenHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= FEN_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & FEN_RWLOCK_PID_MASK;
        if (!fen_pid_alive(pid))
            fen_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void fen_park(FenHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void fen_unpark(FenHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void fen_rdepth_inc(FenHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void fen_rdepth_dec(FenHandle *h) {
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
static inline void fen_reader_wake_drain(FenHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void fen_rwlock_rdlock(FenHandle *h) {
    fen_claim_reader_slot(h);
    FenHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            fen_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            fen_rdepth_dec(h);
            fen_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= FEN_RWLOCK_WRITER_BIT &&
            !fen_pid_alive(cur & FEN_RWLOCK_PID_MASK)) {
            fen_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < FEN_RWLOCK_SPIN_LIMIT, 1)) {
            fen_rwlock_spin_pause();
            continue;
        }
        fen_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &fen_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                fen_unpark(h);
                fen_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        fen_unpark(h);
        spin = 0;
    }
}

static inline void fen_rwlock_rdunlock(FenHandle *h) {
    fen_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    fen_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void fen_rwlock_wrlock(FenHandle *h) {
    fen_claim_reader_slot(h);  /* refresh cached_pid across fork */
    FenHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = FEN_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= FEN_RWLOCK_WRITER_BIT &&
            !fen_pid_alive(expected & FEN_RWLOCK_PID_MASK)) {
            fen_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < FEN_RWLOCK_SPIN_LIMIT, 1)) {
            fen_rwlock_spin_pause();
            continue;
        }
        fen_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &fen_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                fen_unpark(h);
                fen_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        fen_unpark(h);
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
         * this scan, so no held slot is skipped).  O(FEN_OCC_WORDS + live readers)
         * instead of O(FEN_READER_SLOTS). */
        for (uint32_t w = 0; w < FEN_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!fen_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &fen_lock_timeout, NULL, 0);
    }
}

static inline void fen_rwlock_wrunlock(FenHandle *h) {
    FenHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> tree[(n+1) int64]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> tree. */
typedef struct { uint64_t reader_slots, occ, tree; } FenLayout;

static inline FenLayout fen_layout(void) {
    FenLayout L;
    L.reader_slots = sizeof(FenHeader);
    L.occ          = L.reader_slots + (uint64_t)FEN_READER_SLOTS * sizeof(FenReaderSlot);
    L.tree         = L.occ + FEN_OCC_BYTES;
    L.tree         = (L.tree + 7) & ~(uint64_t)7;   /* 8-byte align the int64 tree array */
    return L;
}

/* the tree is 1-indexed: n+1 int64 slots, slot 0 unused.  Range mode appends a
 * second BIT of the same shape right after the first. */
static inline uint64_t fen_tree2_off_for(uint64_t n, uint32_t mode) {
    if (mode != FEN_MODE_RANGE) return 0;
    return fen_layout().tree + (n + 1) * sizeof(int64_t);
}
static inline uint64_t fen_total_size(uint64_t n, uint32_t mode) {
    FenLayout L = fen_layout();
    uint64_t trees = (mode == FEN_MODE_RANGE) ? 2 : 1;
    return L.tree + trees * (n + 1) * sizeof(int64_t);
}

static inline void fen_init_header(void *base, uint64_t n, uint32_t mode, uint64_t total) {
    FenLayout L = fen_layout();
    FenHeader *hdr = (FenHeader *)base;
    /* Zero the header + reader-slot region (lock-recovery state); the tree array
       relies on the fresh mapping being OS zero-filled (all prefix sums == 0). */
    memset(base, 0, (size_t)L.tree);
    hdr->magic            = FEN_MAGIC;
    hdr->version          = FEN_VERSION;
    hdr->mode             = mode;
    hdr->n                = n;
    hdr->capacity         = n;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->tree_off         = L.tree;
    hdr->tree2_off        = fen_tree2_off_for(n, mode);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline int64_t *fen_tree(FenHandle *h) {
    return (int64_t *)((char *)h->base + h->tree_off);
}

/* Layer B trusted bound: number of int64 tree slots guaranteed within the real
 * mapping.  Derived from the process-local mmap_size (fixed at attach, not
 * peer-writable) and the SAME tree_off fen_tree() uses, so a peer that corrupts
 * hdr->n / tree_off after attach-time validation can never drive an access
 * outside the mapping.  Equals n+1 for a valid tree, so clamps are never taken. */
static inline uint64_t fen_tree_slots_max(FenHandle *h) {
    uint64_t off = h->tree_off;
    if (off >= h->mmap_size) return 0;
    return (h->mmap_size - off) / sizeof(int64_t);
}

static inline FenHandle *fen_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    FenHeader *hdr = (FenHeader *)base;
    FenHandle *h = (FenHandle *)calloc(1, sizeof(FenHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (FenReaderSlot *)((uint8_t *)base + sizeof(FenHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + fen_layout().occ);        /* trusted layout offset */
    h->tree_off     = hdr->tree_off;   /* single validated read; bound and pointer stay consistent */
    h->tree2_off    = hdr->tree2_off;
    h->mode         = hdr->mode;
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by fen_create reopen and fen_open_fd). */
static inline int fen_validate_header(const FenHeader *hdr, uint64_t file_size) {
    if (hdr->magic != FEN_MAGIC) return 0;
    if (hdr->version != FEN_VERSION) return 0;
    if (hdr->mode != FEN_MODE_POINT && hdr->mode != FEN_MODE_RANGE) return 0;
    if (hdr->n < FEN_MIN_N || hdr->n > FEN_MAX_N) return 0;
    if (hdr->capacity != hdr->n) return 0;
    if (hdr->tree2_off != fen_tree2_off_for(hdr->n, hdr->mode)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != fen_total_size(hdr->n, hdr->mode)) return 0;
    FenLayout L = fen_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->tree_off != L.tree) return 0;
    return 1;
}

/* validate the requested number of positions n */
static int fen_validate_n(uint64_t n, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (n < FEN_MIN_N) { FEN_ERR("n (number of positions) must be >= 1"); return 0; }
    if (n > FEN_MAX_N) { FEN_ERR("n too large for the tree cap"); return 0; }
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via fen_validate_header. */
static int fen_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { FEN_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        FEN_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    FEN_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static FenHandle *fen_create(const char *path, uint64_t n, uint32_t fmode, mode_t mode, char *errbuf) {
    if (!fen_validate_n(n, errbuf)) return NULL;

    uint64_t total = fen_total_size(n, fmode);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { FEN_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = fen_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { FEN_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { FEN_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(FenHeader)) {
            FEN_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            FEN_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            FEN_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { FEN_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!fen_validate_header((FenHeader *)base, (uint64_t)st.st_size)) {
                FEN_ERR("invalid Fenwick tree file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return fen_setup(base, map_size, path, -1);
        }
    }
    fen_init_header(base, n, fmode, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return fen_setup(base, map_size, path, -1);
}

static FenHandle *fen_create_memfd(const char *name, uint64_t n, uint32_t fmode, char *errbuf) {
    if (!fen_validate_n(n, errbuf)) return NULL;

    uint64_t total = fen_total_size(n, fmode);
    int fd = memfd_create(name ? name : "fenwick", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { FEN_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        FEN_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { FEN_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    fen_init_header(base, n, fmode, total);
    return fen_setup(base, (size_t)total, NULL, fd);
}

static FenHandle *fen_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { FEN_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(FenHeader)) { FEN_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { FEN_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!fen_validate_header((FenHeader *)base, (uint64_t)st.st_size)) {
        FEN_ERR("invalid Fenwick tree table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { FEN_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return fen_setup(base, ms, NULL, myfd);
}

static void fen_destroy(FenHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&fen_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        fen_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int fen_msync(FenHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Fenwick tree (binary indexed tree) operations -- callers hold the lock.
 * 1-indexed: positions 1..n; tree[x] holds the sum of (x - lowbit(x), x],
 * lowbit(x) = x & -x.  Values are signed int64 (deltas may be negative).
 * ================================================================ */

static inline uint64_t fen_lowbit(uint64_t x) { return x & (~x + 1ULL); }

/* highest 1-based index safely inside the mapping (min of n and the Layer-B bound) */
static inline uint64_t fen_nmax(FenHandle *h) {
    uint64_t nn   = h->hdr->n;
    uint64_t smax = fen_tree_slots_max(h);          /* n+1 for a valid tree */
    uint64_t hi   = smax ? smax - 1 : 0;            /* highest valid 1-based index */
    return nn < hi ? nn : hi;
}

/* add delta at position i (1-based); caller guarantees 1 <= i <= n */
static void fen_update_locked(FenHandle *h, uint64_t i, int64_t delta) {
    int64_t *tree = fen_tree(h);
    uint64_t nmax = fen_nmax(h);
    for (uint64_t x = i; x >= 1 && x <= nmax; x += fen_lowbit(x))
        tree[x] += delta;
}

/* prefix sum over positions 1..i (1-based); caller guarantees 0 <= i <= n */
static int64_t fen_prefix_locked(FenHandle *h, uint64_t i) {
    const int64_t *tree = fen_tree(h);
    uint64_t nmax = fen_nmax(h);
    if (i > nmax) i = nmax;                          /* Layer B: never read past the mapping */
    int64_t s = 0;
    for (uint64_t x = i; x > 0; x -= fen_lowbit(x))
        s += tree[x];
    return s;
}

/* sum over positions l..r inclusive (1-based); caller guarantees 1 <= l <= r <= n */
static int64_t fen_range_locked(FenHandle *h, uint64_t l, uint64_t r) {
    return fen_prefix_locked(h, r) - fen_prefix_locked(h, l - 1);
}

/* smallest position i with prefix(i) >= target, or n+1 if none.  Binary lifting;
 * meaningful when all stored values are non-negative (rank / weighted lookup). */
static uint64_t fen_lower_bound_locked(FenHandle *h, int64_t target) {
    const int64_t *tree = fen_tree(h);
    uint64_t nmax = fen_nmax(h);
    uint64_t pos = 0, step = 1;
    int64_t  acc = 0;
    while ((step << 1) && (step << 1) <= nmax) step <<= 1;   /* largest power of two <= nmax */
    for (; step > 0; step >>= 1) {
        uint64_t nxt = pos + step;
        if (nxt <= nmax && acc + tree[nxt] < target) { pos = nxt; acc += tree[nxt]; }
    }
    return pos + 1;
}

/* merge src tree slots into dst (equal n): element-wise add -- a Fenwick tree is
 * linear, so tree(A) + tree(B) == tree(A+B). src_slots = slots the buffer holds. */
static void fen_merge_locked(FenHandle *dst, const int64_t *src, uint64_t src_slots) {
    int64_t *tree = fen_tree(dst);
    uint64_t slots = dst->hdr->n + 1;
    uint64_t slots_max = fen_tree_slots_max(dst);   /* Layer B: clamp writes to dst mapping */
    if (slots > slots_max) slots = slots_max;
    if (slots > src_slots) slots = src_slots;        /* ...and reads to the src buffer */
    for (uint64_t x = 1; x < slots; x++)             /* slot 0 unused */
        tree[x] += src[x];
}

/* reset all positions to 0 (caller holds the write lock) */
static inline void fen_clear_locked(FenHandle *h) {
    uint64_t slots = h->hdr->n + 1;
    if (h->mode == FEN_MODE_RANGE) slots *= 2;       /* both BITs are contiguous after tree_off */
    uint64_t slots_max = fen_tree_slots_max(h);      /* Layer B: clamp memset to the mapping */
    if (slots > slots_max) slots = slots_max;
    memset(fen_tree(h), 0, (size_t)(slots * sizeof(int64_t)));
}

/* ================================================================
 * Range mode: two BITs (B1 = fen_tree, B2 = fen_tree2) give O(log n) range
 * update AND range query.  range_add(l,r,d): B1 += d@l, -d@(r+1); B2 += d*(l-1)@l,
 * -d*r@(r+1).  prefix(i) = B1.prefix(i)*i - B2.prefix(i).  The r+1==n+1 sentinel
 * write is safely dropped -- it would only affect prefixes beyond n, never queried.
 * ================================================================ */

static inline int64_t *fen_tree2(FenHandle *h) {
    return (int64_t *)((char *)h->base + h->tree2_off);
}
/* Layer B trusted bound: int64 slots guaranteed within the mapping past tree2_off */
static inline uint64_t fen_tree2_slots_max(FenHandle *h) {
    uint64_t off = h->tree2_off;
    if (off == 0 || off >= h->mmap_size) return 0;
    return (h->mmap_size - off) / sizeof(int64_t);
}
/* highest 1-based index safely inside BOTH BIT arrays (range mode) */
static inline uint64_t fen_range_nmax(FenHandle *h) {
    uint64_t nn = h->hdr->n;
    uint64_t s1 = fen_tree_slots_max(h),  hi1 = s1 ? s1 - 1 : 0;
    uint64_t s2 = fen_tree2_slots_max(h), hi2 = s2 ? s2 - 1 : 0;
    uint64_t hi = hi1 < hi2 ? hi1 : hi2;
    return nn < hi ? nn : hi;
}
/* BIT primitives on an explicit tree array, bounded by nmax (1-based) */
static inline void fen_bit_add(int64_t *tree, uint64_t i, int64_t delta, uint64_t nmax) {
    for (uint64_t x = i; x >= 1 && x <= nmax; x += fen_lowbit(x)) tree[x] += delta;
}
static inline int64_t fen_bit_prefix(const int64_t *tree, uint64_t i, uint64_t nmax) {
    if (i > nmax) i = nmax;
    int64_t s = 0;
    for (uint64_t x = i; x > 0; x -= fen_lowbit(x)) s += tree[x];
    return s;
}
/* add delta to every position in [l,r] (1-based); caller holds the write lock */
static void fen_range_add_locked(FenHandle *h, uint64_t l, uint64_t r, int64_t delta) {
    int64_t *b1 = fen_tree(h), *b2 = fen_tree2(h);
    uint64_t nmax = fen_range_nmax(h);
    if (l < 1) l = 1;
    if (r > nmax) r = nmax;
    if (l > r) return;
    fen_bit_add(b1, l, delta, nmax);
    fen_bit_add(b2, l, delta * (int64_t)(l - 1), nmax);
    if (r + 1 <= nmax) {                              /* drop the r+1==n+1 sentinel: never queried */
        fen_bit_add(b1, r + 1, -delta, nmax);
        fen_bit_add(b2, r + 1, -delta * (int64_t)r, nmax);
    }
}
/* prefix sum over 1..i (range mode); caller holds a lock */
static int64_t fen_range_prefix_locked(FenHandle *h, uint64_t i) {
    uint64_t nmax = fen_range_nmax(h);
    if (i > nmax) i = nmax;
    int64_t p1 = fen_bit_prefix(fen_tree(h),  i, nmax);
    int64_t p2 = fen_bit_prefix(fen_tree2(h), i, nmax);
    return p1 * (int64_t)i - p2;
}
/* sum over l..r inclusive (range mode); caller holds a lock */
static int64_t fen_range_range_locked(FenHandle *h, uint64_t l, uint64_t r) {
    if (l < 1) l = 1;
    return fen_range_prefix_locked(h, r) - fen_range_prefix_locked(h, l - 1);
}

/* ---- mode-dispatching wrappers used by the XS (point vs range) ---- */
static inline void fen_add1_locked(FenHandle *h, uint64_t i, int64_t d) {
    if (h->mode == FEN_MODE_RANGE) fen_range_add_locked(h, i, i, d);   /* point add == range_add(i,i) */
    else                           fen_update_locked(h, i, d);
}
static inline int64_t fen_pref_locked(FenHandle *h, uint64_t i) {
    return (h->mode == FEN_MODE_RANGE) ? fen_range_prefix_locked(h, i) : fen_prefix_locked(h, i);
}
static inline int64_t fen_rng_locked(FenHandle *h, uint64_t l, uint64_t r) {
    return (h->mode == FEN_MODE_RANGE) ? fen_range_range_locked(h, l, r) : fen_range_locked(h, l, r);
}

#endif /* FEN_H */
