/*
 * hll.h -- Shared-memory HyperLogLog cardinality estimator for Linux
 *
 * Estimates the number of distinct items seen (probabilistic distinct-count)
 * using a fixed array of m = 2^precision single-byte registers. Each item is
 * hashed (XXH3); the top `precision` bits pick a register, the position of the
 * first set bit in the rest updates that register with a running maximum. The
 * register array lives in a shared mapping so several processes share one
 * estimator; a write-preferring futex rwlock with reader-slot dead-process
 * recovery guards mutation. Two estimators of equal precision can be merged
 * (register-wise max).
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> regs[m]
 */

#ifndef HLL_H
#define HLL_H

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

#define XXH_INLINE_ALL
#include "xxhash.h"

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "hll.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define HLL_MAGIC        0x474C4C48U  /* "HLLG" (little-endian) */
#define HLL_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define HLL_ERR_BUFLEN   256
#define HLL_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */

/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these HLL_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all HLL_READER_SLOTS. */
#define HLL_OCC_WORDS   (((HLL_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define HLL_OCC_BYTES   ((uint64_t)HLL_OCC_WORDS * 8)      /* 128 bytes */
#define HLL_MIN_PRECISION 4           /* m = 16  registers */
#define HLL_MAX_PRECISION 18          /* m = 262144 registers (256 KB) */

#define HLL_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, HLL_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} HllReaderSlot;

struct HllHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t precision;               /* 8   register-index bit count */
    uint32_t m;                       /* 12  register count (= 1 << precision) */
    uint32_t _pad0;                   /* 16 */
    uint32_t _pad1;                   /* 20 */
    uint64_t total_size;              /* 24 */
    uint64_t reader_slots_off;        /* 32 */
    uint64_t regs_off;                /* 40 */
    uint32_t wlock;                   /* 48  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 52  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 56  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* 60  readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 64 */
    uint8_t  _pad[184];               /* 72..255 */
};
typedef struct HllHeader HllHeader;

_Static_assert(sizeof(HllHeader) == 256, "HllHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct HllHandle {
    HllHeader     *hdr;
    HllReaderSlot *reader_slots;  /* HLL_READER_SLOTS entries */
    uint64_t      *occ;           /* HLL_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void          *base;          /* mmap base */
    size_t         mmap_size;
    char          *path;          /* backing file path (strdup'd) */
    int            backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t       my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;    /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* hll_fork_gen value at last slot claim */
    uint32_t       slotless_held; /* read-locks this process holds with no reader-slot */
} HllHandle;

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

#define HLL_RWLOCK_SPIN_LIMIT 32
#define HLL_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void hll_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define HLL_RWLOCK_WRITER_BIT 0x80000000U
#define HLL_RWLOCK_PID_MASK   0x7FFFFFFFU
#define HLL_RWLOCK_WR(pid)    (HLL_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & HLL_RWLOCK_PID_MASK))

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
static inline int hll_pid_is_zombie(uint32_t pid) {
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
static inline int hll_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !hll_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void hll_recover_stale_lock(HllHandle *h, uint32_t observed_wlock) {
    HllHeader *hdr = h->hdr;
    uint32_t mypid = HLL_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec hll_lock_timeout = { HLL_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t hll_fork_gen = 1;
static pthread_once_t hll_atfork_once = PTHREAD_ONCE_INIT;
static void hll_on_fork_child(void) {
    __atomic_add_fetch(&hll_fork_gen, 1, __ATOMIC_RELAXED);
}
static void hll_atfork_init(void) {
    pthread_atfork(NULL, NULL, hll_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void hll_occ_set(HllHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void hll_occ_clear(HllHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so that
 * fork()'d children pick up their own slot lazily instead of sharing the
 * parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void hll_claim_reader_slot(HllHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&hll_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&hll_atfork_once, hll_atfork_init);
    /* Re-read after pthread_once: hll_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&hll_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % HLL_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < HLL_READER_SLOTS; i++) {
        uint32_t s = (start + i) % HLL_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            hll_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < HLL_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || hll_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            hll_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void hll_recover_after_timeout(HllHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= HLL_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & HLL_RWLOCK_PID_MASK;
        if (!hll_pid_alive(pid))
            hll_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void hll_park(HllHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void hll_unpark(HllHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void hll_rdepth_inc(HllHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void hll_rdepth_dec(HllHandle *h) {
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
static inline void hll_reader_wake_drain(HllHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void hll_rwlock_rdlock(HllHandle *h) {
    hll_claim_reader_slot(h);
    HllHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            hll_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            hll_rdepth_dec(h);
            hll_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= HLL_RWLOCK_WRITER_BIT &&
            !hll_pid_alive(cur & HLL_RWLOCK_PID_MASK)) {
            hll_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < HLL_RWLOCK_SPIN_LIMIT, 1)) {
            hll_rwlock_spin_pause();
            continue;
        }
        hll_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &hll_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                hll_unpark(h);
                hll_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        hll_unpark(h);
        spin = 0;
    }
}

static inline void hll_rwlock_rdunlock(HllHandle *h) {
    hll_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    hll_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void hll_rwlock_wrlock(HllHandle *h) {
    hll_claim_reader_slot(h);  /* refresh cached_pid across fork */
    HllHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = HLL_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= HLL_RWLOCK_WRITER_BIT &&
            !hll_pid_alive(expected & HLL_RWLOCK_PID_MASK)) {
            hll_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < HLL_RWLOCK_SPIN_LIMIT, 1)) {
            hll_rwlock_spin_pause();
            continue;
        }
        hll_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &hll_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                hll_unpark(h);
                hll_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        hll_unpark(h);
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
         * this scan, so no held slot is skipped).  O(HLL_OCC_WORDS + live readers)
         * instead of O(HLL_READER_SLOTS). */
        for (uint32_t w = 0; w < HLL_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!hll_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &hll_lock_timeout, NULL, 0);
    }
}

static inline void hll_rwlock_wrunlock(HllHandle *h) {
    HllHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> regs[m]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> regs[m]. */
typedef struct { uint64_t reader_slots, occ, regs; } HllLayout;

static inline HllLayout hll_layout(void) {
    HllLayout L;
    L.reader_slots = sizeof(HllHeader);
    L.occ          = L.reader_slots + (uint64_t)HLL_READER_SLOTS * sizeof(HllReaderSlot);
    L.regs         = L.occ + HLL_OCC_BYTES;
    L.regs         = (L.regs + 7) & ~(uint64_t)7;   /* 8-byte align the register array */
    return L;
}

static inline uint64_t hll_total_size(uint32_t m) {
    HllLayout L = hll_layout();
    return L.regs + (uint64_t)m;
}

static inline void hll_init_header(void *base, uint32_t precision, uint32_t m, uint64_t total) {
    HllLayout L = hll_layout();
    HllHeader *hdr = (HllHeader *)base;
    /* Explicitly zero the header + reader-slot region (lock-recovery state, like
       intern.h); the register array relies on the fresh mapping being OS zero-filled. */
    memset(base, 0, (size_t)L.regs);
    hdr->magic            = HLL_MAGIC;
    hdr->version          = HLL_VERSION;
    hdr->precision        = precision;
    hdr->m                = m;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->regs_off         = L.regs;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint8_t *hll_regs(HllHandle *h) {
    return (uint8_t *)((char *)h->base + h->hdr->regs_off);
}

/* Snapshot the peer-writable register geometry (precision, m, regs_off) ONCE
 * and bound it against the trusted mapping size (h->mmap_size comes from fstat
 * at attach, NOT from the segment a local peer can rewrite via MAP_SHARED).
 * Returns a pointer to the register array plus its count/precision via the
 * out-params, or NULL if the header does not describe a region wholly inside
 * the mapping.  Callers hold the lock; the NULL branch is a predictable
 * never-taken path for a valid, untampered file.  Reading each field into a
 * local and validating the local (not re-reading) closes the TOCTOU window. */
static inline uint8_t *hll_regs_checked(HllHandle *h, uint32_t *m_out, uint32_t *p_out) {
    uint32_t p   = h->hdr->precision;
    uint32_t m   = h->hdr->m;
    uint64_t off = h->hdr->regs_off;
    if (p < HLL_MIN_PRECISION || p > HLL_MAX_PRECISION) return NULL;
    if (m != (1u << p)) return NULL;                              /* ties m to p */
    if (off > h->mmap_size || (uint64_t)m > (uint64_t)h->mmap_size - off) return NULL;
    if (m_out) *m_out = m;
    if (p_out) *p_out = p;
    return (uint8_t *)((char *)h->base + off);
}

static inline HllHandle *hll_setup(void *base, size_t map_size,
                                   const char *path, int backing_fd) {
    HllHeader *hdr = (HllHeader *)base;
    HllHandle *h = (HllHandle *)calloc(1, sizeof(HllHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (HllReaderSlot *)((uint8_t *)base + sizeof(HllHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + hll_layout().occ);        /* trusted layout offset */
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by hll_create reopen and hll_open_fd). */
static inline int hll_validate_header(const HllHeader *hdr, uint64_t file_size) {
    if (hdr->magic != HLL_MAGIC) return 0;
    if (hdr->version != HLL_VERSION) return 0;
    if (hdr->precision < HLL_MIN_PRECISION || hdr->precision > HLL_MAX_PRECISION) return 0;
    if (hdr->m != (1u << hdr->precision)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != hll_total_size(hdr->m)) return 0;
    HllLayout L = hll_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->regs_off != L.regs) return 0;
    return 1;
}

/* validate the precision argument */
static int hll_validate_create_args(uint32_t precision, uint32_t *m_out, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (precision < HLL_MIN_PRECISION || precision > HLL_MAX_PRECISION) {
        HLL_ERR("precision must be between %d and %d", HLL_MIN_PRECISION, HLL_MAX_PRECISION);
        return 0;
    }
    *m_out = 1u << precision;
    return 1;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at mode,
 * default 0600), or attach an existing file (O_RDWR|O_NOFOLLOW, no O_CREAT). */
static int hll_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { HLL_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        HLL_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    HLL_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static HllHandle *hll_create(const char *path, uint32_t precision, mode_t mode, char *errbuf) {
    uint32_t m;
    if (!hll_validate_create_args(precision, &m, errbuf)) return NULL;

    uint64_t total = hll_total_size(m);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { HLL_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = hll_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { HLL_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { HLL_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(HllHeader)) {
            HLL_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            HLL_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            HLL_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { HLL_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!hll_validate_header((HllHeader *)base, (uint64_t)st.st_size)) {
                HLL_ERR("invalid HyperLogLog file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return hll_setup(base, map_size, path, -1);
        }
    }
    hll_init_header(base, precision, m, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return hll_setup(base, map_size, path, -1);
}

static HllHandle *hll_create_memfd(const char *name, uint32_t precision, char *errbuf) {
    uint32_t m;
    if (!hll_validate_create_args(precision, &m, errbuf)) return NULL;

    uint64_t total = hll_total_size(m);
    int fd = memfd_create(name ? name : "hll", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { HLL_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        HLL_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { HLL_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    hll_init_header(base, precision, m, total);
    return hll_setup(base, (size_t)total, NULL, fd);
}

static HllHandle *hll_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { HLL_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(HllHeader)) { HLL_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { HLL_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!hll_validate_header((HllHeader *)base, (uint64_t)st.st_size)) {
        HLL_ERR("invalid HyperLogLog table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { HLL_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return hll_setup(base, ms, NULL, myfd);
}

static void hll_destroy(HllHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&hll_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        hll_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int hll_msync(HllHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * HyperLogLog operations (callers hold the lock)
 * ================================================================ */

/* add one item; returns 1 if a register increased, else 0 */
static int hll_add_locked(HllHandle *h, const void *item, size_t len) {
    uint32_t p = 0, m = 0;
    uint8_t *regs = hll_regs_checked(h, &m, &p);        /* bound peer-writable geometry */
    if (!regs) return 0;                                /* tampered header: skip, never trap */
    uint64_t x = XXH3_64bits(item, len);
    uint32_t idx = (uint32_t)(x >> (64 - p));           /* top p bits; < 2^p == m by the check */
    uint64_t rest = (x << p) | (1ULL << (p - 1));       /* guard bit so clz terminates */
    uint8_t  rho  = (uint8_t)(__builtin_clzll(rest) + 1);
    if (regs[idx] < rho) { regs[idx] = rho; return 1; }
    return 0;
}

/* estimate; returns a double */
static double hll_count_locked(HllHandle *h) {
    uint32_t m = 0;
    uint8_t *regs = hll_regs_checked(h, &m, NULL);
    if (!regs) return 0.0;                          /* tampered header: report empty */
    double sum = 0.0;
    uint32_t V = 0;
    for (uint32_t j = 0; j < m; j++) {
        sum += ldexp(1.0, -(int)regs[j]);
        V += (regs[j] == 0);
    }
    double alpha;
    if      (m == 16) alpha = 0.673;
    else if (m == 32) alpha = 0.697;
    else if (m == 64) alpha = 0.709;
    else              alpha = 0.7213 / (1.0 + 1.079 / (double)m);
    double E = alpha * (double)m * (double)m / sum;
    if (E <= 2.5 * (double)m && V > 0)
        E = (double)m * log((double)m / (double)V);  /* linear counting (small range) */
    return E;
}

/* merge src registers into dst; register-wise max over the in-bounds prefix.
 * src_len bounds reads of src_regs (a temp sized to the source's registers). */
static void hll_merge_regs(HllHandle *dst, const uint8_t *src_regs, uint32_t src_len) {
    uint32_t m = 0;
    uint8_t *regs = hll_regs_checked(dst, &m, NULL);
    if (!regs) return;
    uint32_t n = (src_len < m) ? src_len : m;         /* never read past either array */
    for (uint32_t j = 0; j < n; j++)
        if (src_regs[j] > regs[j]) regs[j] = src_regs[j];
}

/* reset all registers to 0 (caller holds the write lock) */
static inline void hll_clear_locked(HllHandle *h) {
    uint32_t m = 0;
    uint8_t *regs = hll_regs_checked(h, &m, NULL);   /* bound the memset length */
    if (!regs) return;
    memset(regs, 0, (size_t)m);
}

#endif /* HLL_H */
