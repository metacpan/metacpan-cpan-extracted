/*
 * hiertimingwheel.h -- Shared-memory hierarchical timing wheel for Linux
 *
 * O(1) timer scheduling at any delay: a hierarchical (Varghese-Lauck) timing
 * wheel of num_levels cascading wheels, each with num_slots (=S) buckets.  A
 * level-k slot spans S^k ticks, so the structure schedules any delay in
 * [1, S^num_levels).  Scheduling and cancelling a timer are O(1); a far-future
 * timer waits in a coarse level and cascades down to finer levels as its time
 * approaches, so it is touched only once per coarse tick (versus a single-level
 * wheel that revisits it every rotation).  The wheels live in a shared mapping so
 * several processes schedule into and advance one clock; a write-preferring futex
 * rwlock with reader-slot dead-process recovery guards mutation.  Each timer
 * carries an arbitrary 64-bit payload returned when it fires.
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> buckets[num_levels*num_slots] -> timers[capacity]
 */

#ifndef HW_H
#define HW_H

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
#error "hiertimingwheel.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define HW_MAGIC        0x4C575448  /* HierTimingWheel */
#define HW_VERSION      2            /* 2: added the occupancy bitmap region (layout change) */
#define HW_ERR_BUFLEN   256
#ifndef HW_READER_SLOTS
#define HW_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these HW_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all HW_READER_SLOTS. */
#define HW_OCC_WORDS    (((HW_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define HW_OCC_BYTES    ((uint64_t)HW_OCC_WORDS * 8)       /* 128 bytes */
#define HW_MIN_SLOTS    2
#define HW_MAX_SLOTS    0x10000U      /* 2^16 slots per level */
#define HW_MIN_LEVELS   1
#define HW_MAX_LEVELS   16            /* number of cascading wheels */
#define HW_MIN_CAP      1
#define HW_MAX_CAP      0x1000000U    /* 2^24 concurrent timers (index fits uint32, < HW_NIL) */
#define HW_NIL          0xFFFFFFFFU   /* empty list link / free-list terminator */

#define HW_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, HW_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} HwReaderSlot;

struct HwHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t num_slots;               /* 8   slots per level (S) */
    uint32_t num_levels;              /* 12  number of cascading wheels (L) */
    uint32_t capacity;                /* 16  max concurrent timers */
    uint32_t free_head;               /* 20  free-list head (timer index) or HW_NIL */
    uint64_t now;                     /* 24  absolute tick counter */
    uint64_t count;                   /* 32  active timers */
    uint64_t slots_off;               /* 40  offset of the bucket heads (num_levels*num_slots uint32) */
    uint64_t timers_off;              /* 48  offset of the timer pool */
    uint64_t total_size;              /* 56 */
    uint64_t reader_slots_off;        /* 64 */
    uint32_t wlock;                   /* 72  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 76  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 80  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct HwHeader HwHeader;

_Static_assert(sizeof(HwHeader) == 256, "HwHeader must be 256 bytes");

/* One timer: a payload plus its absolute expiry tick, linked into its current
 * bucket by a doubly-linked list (prev/next) for O(1) cancellation.  `bucket` is
 * the flat bucket index (level*num_slots + slot) it currently sits in.  state is
 * 0 when the timer is on the free list, 1 when active. */
typedef struct {
    uint64_t payload;
    uint64_t expiry;
    uint32_t prev;
    uint32_t next;
    uint32_t bucket;
    uint32_t state;
} HwTimer;
_Static_assert(sizeof(HwTimer) == 32, "HwTimer must be 32 bytes");

/* ---- Process-local handle ---- */

typedef struct HwHandle {
    HwHeader     *hdr;
    HwReaderSlot *reader_slots;  /* HW_READER_SLOTS entries */
    uint64_t     *occ;           /* HW_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      slots_off;     /* validated offsets, cached: never re-read from the peer-writable header */
    uint64_t      timers_off;
    uint32_t      num_slots;     /* cached (S) */
    uint32_t      num_levels;    /* cached (L) */
    uint64_t      tick[HW_MAX_LEVELS + 1]; /* tick[k] = S^k ticks per level-k slot; tick[L] = max delay + 1 */
    uint32_t      capacity;      /* cached */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* hw_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} HwHandle;

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

#define HW_RWLOCK_SPIN_LIMIT 32
#define HW_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void hw_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define HW_RWLOCK_WRITER_BIT 0x80000000U
#define HW_RWLOCK_PID_MASK   0x7FFFFFFFU
#define HW_RWLOCK_WR(pid)    (HW_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & HW_RWLOCK_PID_MASK))

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
static inline int hw_pid_is_zombie(uint32_t pid) {
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
static inline int hw_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !hw_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void hw_recover_stale_lock(HwHandle *h, uint32_t observed_wlock) {
    HwHeader *hdr = h->hdr;
    uint32_t mypid = HW_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec hw_lock_timeout = { HW_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t hw_fork_gen = 1;
static pthread_once_t hw_atfork_once = PTHREAD_ONCE_INIT;
static void hw_on_fork_child(void) {
    __atomic_add_fetch(&hw_fork_gen, 1, __ATOMIC_RELAXED);
}
static void hw_atfork_init(void) {
    pthread_atfork(NULL, NULL, hw_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void hw_occ_set(HwHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void hw_occ_clear(HwHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void hw_claim_reader_slot(HwHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&hw_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&hw_atfork_once, hw_atfork_init);
    /* Re-read after pthread_once: hw_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&hw_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % HW_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < HW_READER_SLOTS; i++) {
        uint32_t s = (start + i) % HW_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            hw_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < HW_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || hw_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            hw_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void hw_recover_after_timeout(HwHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= HW_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & HW_RWLOCK_PID_MASK;
        if (!hw_pid_alive(pid))
            hw_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void hw_park(HwHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void hw_unpark(HwHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void hw_rdepth_inc(HwHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void hw_rdepth_dec(HwHandle *h) {
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
static inline void hw_reader_wake_drain(HwHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void hw_rwlock_rdlock(HwHandle *h) {
    hw_claim_reader_slot(h);
    HwHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            hw_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            hw_rdepth_dec(h);
            hw_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= HW_RWLOCK_WRITER_BIT &&
            !hw_pid_alive(cur & HW_RWLOCK_PID_MASK)) {
            hw_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < HW_RWLOCK_SPIN_LIMIT, 1)) {
            hw_rwlock_spin_pause();
            continue;
        }
        hw_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &hw_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                hw_unpark(h);
                hw_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        hw_unpark(h);
        spin = 0;
    }
}

static inline void hw_rwlock_rdunlock(HwHandle *h) {
    hw_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    hw_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void hw_rwlock_wrlock(HwHandle *h) {
    hw_claim_reader_slot(h);  /* refresh cached_pid across fork */
    HwHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = HW_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= HW_RWLOCK_WRITER_BIT &&
            !hw_pid_alive(expected & HW_RWLOCK_PID_MASK)) {
            hw_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < HW_RWLOCK_SPIN_LIMIT, 1)) {
            hw_rwlock_spin_pause();
            continue;
        }
        hw_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &hw_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                hw_unpark(h);
                hw_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        hw_unpark(h);
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
         * this scan, so no held slot is skipped).  O(HW_OCC_WORDS + live readers)
         * instead of O(HW_READER_SLOTS). */
        for (uint32_t w = 0; w < HW_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!hw_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &hw_lock_timeout, NULL, 0);
    }
}

static inline void hw_rwlock_wrunlock(HwHandle *h) {
    HwHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> buckets[num_levels*num_slots] -> timers[capacity]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets.
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> buckets[num_levels*num_slots] -> timers[capacity] */
typedef struct { uint64_t reader_slots, occ, slots, timers, total; } HwLayout;

static inline HwLayout hw_layout_for(uint32_t num_slots, uint32_t num_levels, uint32_t capacity) {
    HwLayout L;
    L.reader_slots = sizeof(HwHeader);
    L.occ          = L.reader_slots + (uint64_t)HW_READER_SLOTS * sizeof(HwReaderSlot);
    L.slots        = L.occ + HW_OCC_BYTES;
    L.slots        = (L.slots + 7) & ~(uint64_t)7;
    L.timers       = L.slots + (uint64_t)num_levels * num_slots * sizeof(uint32_t);
    L.timers       = (L.timers + 7) & ~(uint64_t)7;
    L.total        = L.timers + (uint64_t)capacity * sizeof(HwTimer);
    return L;
}

static inline uint64_t hw_total_size(uint32_t num_slots, uint32_t num_levels, uint32_t capacity) {
    return hw_layout_for(num_slots, num_levels, capacity).total;
}

/* compute tick[k] = num_slots^k (ticks per level-k slot) for k in 0..num_levels
 * into out[]; returns 0 if num_slots^num_levels overflows uint64 (the maximum
 * schedulable delay + 1), else 1. */
static inline int hw_compute_ticks(uint32_t num_slots, uint32_t num_levels, uint64_t *out) {
    out[0] = 1;
    for (uint32_t k = 1; k <= num_levels; k++) {
        if (num_slots == 0 || out[k - 1] > UINT64_MAX / num_slots) return 0;   /* overflow */
        out[k] = out[k - 1] * num_slots;
    }
    return 1;
}

static inline uint32_t *hw_slots(HwHandle *h) { return (uint32_t *)((char *)h->base + h->slots_off); }
static inline HwTimer  *hw_timer(HwHandle *h, uint64_t i) { return (HwTimer *)((char *)h->base + h->timers_off) + i; }
static inline uint64_t  hw_num_bucket(HwHandle *h) { return (uint64_t)h->num_levels * h->num_slots; }

static inline void hw_init_header(void *base, uint32_t num_slots, uint32_t num_levels, uint32_t capacity, uint64_t total) {
    HwLayout L = hw_layout_for(num_slots, num_levels, capacity);
    HwHeader *hdr = (HwHeader *)base;
    memset(base, 0, (size_t)L.total);
    uint32_t *slots = (uint32_t *)((char *)base + L.slots);
    uint64_t nb = (uint64_t)num_levels * num_slots;
    for (uint64_t s = 0; s < nb; s++) slots[s] = HW_NIL;            /* all buckets empty */
    HwTimer *timers = (HwTimer *)((char *)base + L.timers);
    for (uint32_t i = 0; i < capacity; i++) {                        /* thread the free list */
        timers[i].next   = (i + 1 < capacity) ? (i + 1) : HW_NIL;
        timers[i].prev   = HW_NIL;
        timers[i].bucket = HW_NIL;
        timers[i].state  = 0;
    }
    hdr->magic            = HW_MAGIC;
    hdr->version          = HW_VERSION;
    hdr->num_slots        = num_slots;
    hdr->num_levels       = num_levels;
    hdr->capacity         = capacity;
    hdr->free_head        = capacity ? 0 : HW_NIL;
    hdr->now              = 0;
    hdr->count            = 0;
    hdr->slots_off        = L.slots;
    hdr->timers_off       = L.timers;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* Layer B trusted bound: number of timers guaranteed within the real mapping.
 * Equals capacity for a valid wheel; every timer index from shared memory is
 * checked against it so a corrupt link can never drive an access out of bounds. */
static inline uint64_t hw_timers_max(HwHandle *h) {
    if (h->timers_off >= h->mmap_size) return 0;
    return (h->mmap_size - h->timers_off) / sizeof(HwTimer);
}
#define HW_TIMER_OK(h, i)  ((uint32_t)(i) != HW_NIL && (uint64_t)(i) < (uint64_t)(h)->capacity)
#define HW_BUCKET_OK(h, b) ((uint32_t)(b) != HW_NIL && (uint64_t)(b) < hw_num_bucket(h))

static inline HwHandle *hw_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    HwHeader *hdr = (HwHeader *)base;
    HwHandle *h = (HwHandle *)calloc(1, sizeof(HwHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (HwReaderSlot *)((uint8_t *)base + sizeof(HwHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + hw_layout_for(0, 0, 0).occ);  /* occ offset is geometry-independent (trusted) */
    h->slots_off    = hdr->slots_off;   /* single validated read of each geometry field */
    h->timers_off   = hdr->timers_off;
    h->num_slots    = hdr->num_slots;
    h->num_levels   = hdr->num_levels;
    h->capacity     = hdr->capacity;
    hw_compute_ticks(h->num_slots, h->num_levels, h->tick);   /* validate_header ensured no overflow */
    h->mmap_size    = map_size;
    /* Layer B: clamp the cached capacity to the number of timers that actually fit */
    {
        uint64_t fit = hw_timers_max(h);
        if ((uint64_t)h->capacity > fit) h->capacity = (uint32_t)fit;
    }
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by hw_create reopen and hw_open_fd). */
static inline int hw_validate_header(const HwHeader *hdr, uint64_t file_size) {
    if (hdr->magic != HW_MAGIC) return 0;
    if (hdr->version != HW_VERSION) return 0;
    if (hdr->num_slots < HW_MIN_SLOTS || hdr->num_slots > HW_MAX_SLOTS) return 0;
    if (hdr->num_levels < HW_MIN_LEVELS || hdr->num_levels > HW_MAX_LEVELS) return 0;
    if (hdr->capacity < HW_MIN_CAP || hdr->capacity > HW_MAX_CAP) return 0;
    if (hdr->count > hdr->capacity) return 0;
    { uint64_t t[HW_MAX_LEVELS + 1];
      if (!hw_compute_ticks(hdr->num_slots, hdr->num_levels, t)) return 0; }   /* S^L must fit uint64 */
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != hw_total_size(hdr->num_slots, hdr->num_levels, hdr->capacity)) return 0;
    HwLayout L = hw_layout_for(hdr->num_slots, hdr->num_levels, hdr->capacity);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->slots_off != L.slots) return 0;
    if (hdr->timers_off != L.timers) return 0;
    return 1;
}

/* validate the requested wheel geometry + timer capacity */
static int hw_validate_args(uint64_t num_slots, uint64_t num_levels, uint64_t capacity, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (num_slots < HW_MIN_SLOTS || num_slots > HW_MAX_SLOTS) { HW_ERR("num_slots must be between 2 and 2^16"); return 0; }
    if (num_levels < HW_MIN_LEVELS || num_levels > HW_MAX_LEVELS) { HW_ERR("num_levels must be between 1 and 16"); return 0; }
    if (capacity < HW_MIN_CAP || capacity > HW_MAX_CAP) { HW_ERR("capacity must be between 1 and 2^24"); return 0; }
    { uint64_t t[HW_MAX_LEVELS + 1];
      if (!hw_compute_ticks((uint32_t)num_slots, (uint32_t)num_levels, t))
          { HW_ERR("num_slots^num_levels overflows 64 bits; reduce num_slots or num_levels"); return 0; } }
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via hw_validate_header. */
static int hw_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { HW_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        HW_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    HW_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static HwHandle *hw_create(const char *path, uint64_t num_slots, uint64_t num_levels, uint64_t capacity, mode_t mode, char *errbuf) {
    if (!hw_validate_args(num_slots, num_levels, capacity, errbuf)) return NULL;

    uint64_t total = hw_total_size((uint32_t)num_slots, (uint32_t)num_levels, (uint32_t)capacity);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { HW_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = hw_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { HW_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { HW_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(HwHeader)) {
            HW_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            HW_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            HW_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { HW_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!hw_validate_header((HwHeader *)base, (uint64_t)st.st_size)) {
                HW_ERR("invalid hierarchical timing-wheel file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return hw_setup(base, map_size, path, -1);
        }
    }
    hw_init_header(base, (uint32_t)num_slots, (uint32_t)num_levels, (uint32_t)capacity, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return hw_setup(base, map_size, path, -1);
}

static HwHandle *hw_create_memfd(const char *name, uint64_t num_slots, uint64_t num_levels, uint64_t capacity, char *errbuf) {
    if (!hw_validate_args(num_slots, num_levels, capacity, errbuf)) return NULL;

    uint64_t total = hw_total_size((uint32_t)num_slots, (uint32_t)num_levels, (uint32_t)capacity);
    int fd = memfd_create(name ? name : "hiertimingwheel", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { HW_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        HW_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { HW_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    hw_init_header(base, (uint32_t)num_slots, (uint32_t)num_levels, (uint32_t)capacity, total);
    return hw_setup(base, (size_t)total, NULL, fd);
}

static HwHandle *hw_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { HW_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(HwHeader)) { HW_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { HW_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!hw_validate_header((HwHeader *)base, (uint64_t)st.st_size)) {
        HW_ERR("invalid hierarchical timing-wheel table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { HW_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return hw_setup(base, ms, NULL, myfd);
}

static void hw_destroy(HwHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&hw_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        hw_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int hw_msync(HwHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Hierarchical timing-wheel operations (callers hold the lock)
 *
 * num_levels cascading wheels of num_slots (=S) buckets each; a level-k slot
 * spans tick[k]=S^k ticks, so the whole structure schedules any delay in
 * [1, S^num_levels).  A timer stores its absolute expiry; it is placed in the
 * lowest level whose range covers its remaining delay, at slot (expiry/tick[k])%S.
 * On each tick level 0 fires its current slot; when level 0 wraps, the next
 * level's now-current slot cascades down -- its timers are re-binned into finer
 * levels by remaining delay -- recursively up the levels.  Timers live in a fixed
 * pool with a free list; each bucket is a doubly-linked list (prev/next) so
 * cancellation is O(1).  Every timer index and bucket index read from shared
 * memory is bounds checked, so a corrupt link can never drive an OOB access.
 * ================================================================ */

/* unlink timer `t` from its current bucket's doubly-linked list */
static void hw_unlink(HwHandle *h, uint32_t t) {
    HwTimer *tm = hw_timer(h, t);
    uint32_t pv = tm->prev, nx = tm->next;
    if (HW_TIMER_OK(h, pv)) hw_timer(h, pv)->next = nx;
    else if (HW_BUCKET_OK(h, tm->bucket)) hw_slots(h)[tm->bucket] = nx;   /* t was the head */
    if (HW_TIMER_OK(h, nx)) hw_timer(h, nx)->prev = pv;
}

/* return timer `t` to the free list (caller has already unlinked it) */
static void hw_free(HwHandle *h, uint32_t t) {
    HwTimer *tm = hw_timer(h, t);
    tm->state  &= ~1u;   /* clear active bit; keep generation so the next reuse of this slot gets a fresh one */
    tm->prev   = HW_NIL;
    tm->bucket = HW_NIL;
    tm->next   = h->hdr->free_head;
    h->hdr->free_head = t;
}

/* link an already-populated timer `t` into flat bucket `b` (prepend) */
static void hw_link(HwHandle *h, uint32_t t, uint64_t b) {
    HwTimer *tm = hw_timer(h, t);
    tm->bucket = (uint32_t)b;
    tm->prev   = HW_NIL;
    uint32_t head = hw_slots(h)[b];
    tm->next = head;
    if (HW_TIMER_OK(h, head)) hw_timer(h, head)->prev = t;
    hw_slots(h)[b] = t;
}

/* choose the flat bucket for a timer whose absolute expiry is E, given the
 * current time now: the lowest level k with (E-now) < tick[k+1], slot
 * (E/tick[k])%S.  A remaining delay of 0 lands in level 0's current slot. */
static uint64_t hw_bucket_for(HwHandle *h, uint64_t E, uint64_t now) {
    uint64_t delay = (E > now) ? E - now : 0;
    uint32_t S = h->num_slots, L = h->num_levels, k = 0;
    while (k + 1 < L && delay >= h->tick[k + 1]) k++;      /* lowest level covering `delay` */
    uint64_t slot = (E / h->tick[k]) % S;
    return (uint64_t)k * S + slot;                         /* flat bucket index */
}

/* schedule a timer to fire in `delay` ticks (>= 1); returns its id, or -1 if the
 * pool is full or the delay exceeds the wheel's range.  (caller holds wrlock) */
static int64_t hw_add_locked(HwHandle *h, uint64_t delay, uint64_t payload) {
    if (h->num_slots == 0 || h->num_levels == 0 || h->capacity == 0) return -1;
    if (delay < 1) delay = 1;                              /* minimum effective delay is one tick */
    if (delay >= h->tick[h->num_levels]) return -2;        /* beyond S^num_levels: not schedulable */
    uint32_t t = h->hdr->free_head;
    if (!HW_TIMER_OK(h, t)) return -1;                     /* full (or corrupt free head) */
    if (hw_timer(h, t)->state & 1u) return -1;             /* Layer B: free head points at an active timer */
    h->hdr->free_head = hw_timer(h, t)->next;              /* pop the free list */

    uint64_t now = h->hdr->now, E = now + delay;
    HwTimer *tm = hw_timer(h, t);
    tm->payload = payload;
    tm->expiry  = E;
    uint32_t gen = (tm->state >> 1) + 1;                   /* bump generation for this reuse */
    tm->state   = (gen << 1) | 1u;                         /* low bit = active, upper bits = generation */
    hw_link(h, t, hw_bucket_for(h, E, now));
    h->hdr->count++;
    return ((int64_t)gen << 32) | (int64_t)t;             /* id encodes the generation so cancel() can reject a reused slot */
}

/* cancel timer `t`; returns 1 if it was active and is now removed, else 0.
 * (caller holds the write lock) */
static int hw_cancel_locked(HwHandle *h, uint64_t id) {
    uint32_t idx = (uint32_t)(id & 0xFFFFFFFFu);
    uint32_t gen = (uint32_t)((id >> 32) & 0x7FFFFFFFu);
    if (!HW_TIMER_OK(h, idx)) return 0;
    HwTimer *tm = hw_timer(h, idx);
    if (!(tm->state & 1u)) return 0;                       /* free / already fired */
    if ((tm->state >> 1) != gen) return 0;                 /* stale id: this slot was reused by a later timer */
    hw_unlink(h, idx);
    hw_free(h, idx);
    if (h->hdr->count) h->hdr->count--;
    return 1;
}

/* re-bin every timer in level-k's now-current bucket into a finer level (called
 * when `now` has just reached a multiple of tick[k]).  If level k also wrapped,
 * cascade level k+1 first (top-down) so higher levels feed into this one. */
static void hw_cascade(HwHandle *h, uint32_t k) {
    uint32_t S = h->num_slots;
    uint64_t slot = (h->hdr->now / h->tick[k]) % S;
    if (slot == 0 && k + 1 < h->num_levels) hw_cascade(h, k + 1);   /* level k wrapped too */
    uint64_t b = (uint64_t)k * S + slot;
    uint32_t t = hw_slots(h)[b];
    hw_slots(h)[b] = HW_NIL;                               /* detach the whole list */
    uint64_t guard = 0;
    while (HW_TIMER_OK(h, t) && guard++ <= (uint64_t)h->capacity) {
        HwTimer *tm = hw_timer(h, t);
        uint32_t nx = tm->next;
        if (tm->state & 1u)                                /* re-insert into a lower level (or level-0 current slot) */
            hw_link(h, t, hw_bucket_for(h, tm->expiry, h->hdr->now));
        t = nx;
    }
}

/* advance the wheel by `ticks`, collecting fired payloads into out[] (capped at
 * out_cap); returns the number fired.  (caller holds the write lock) */
static uint64_t hw_advance_locked(HwHandle *h, uint64_t ticks, uint64_t *out, uint64_t out_cap) {
    uint64_t fired = 0;
    uint32_t S = h->num_slots;
    if (S == 0 || h->num_levels == 0) return 0;
    for (uint64_t j = 0; j < ticks; j++) {
        h->hdr->now++;
        uint64_t now = h->hdr->now;
        if (now % S == 0 && h->num_levels > 1)             /* level 0 wrapped -> cascade higher levels down */
            hw_cascade(h, 1);
        uint64_t b = now % S;                              /* level-0 current slot (tick[0]==1) */
        uint32_t t = hw_slots(h)[b];
        uint64_t guard = 0;
        while (HW_TIMER_OK(h, t) && guard++ <= (uint64_t)h->capacity) {
            HwTimer *tm = hw_timer(h, t);
            if (!(tm->state & 1u)) break;                  /* Layer B: corrupt link into a freed node */
            uint32_t nx = tm->next;
            hw_unlink(h, t);                               /* every timer in level-0's current slot is due now */
            hw_free(h, t);
            if (h->hdr->count) h->hdr->count--;
            if (fired < out_cap) out[fired++] = tm->payload;   /* cap BOTH the write and the count */
            t = nx;
        }
    }
    return fired;
}

/* reset to an empty wheel: rethread the free list, clear the buckets, reset time.
 * (caller holds the write lock) */
static inline void hw_clear_locked(HwHandle *h) {
    uint64_t nb = hw_num_bucket(h), cap = h->capacity;
    uint64_t smax = (h->slots_off < h->mmap_size) ? (h->mmap_size - h->slots_off) / sizeof(uint32_t) : 0;
    if (nb > smax) nb = smax;                              /* Layer B */
    uint64_t tmax = hw_timers_max(h);
    if (cap > tmax) cap = tmax;
    uint32_t *slots = hw_slots(h);
    for (uint64_t s = 0; s < nb; s++) slots[s] = HW_NIL;
    for (uint64_t i = 0; i < cap; i++) {
        HwTimer *tm = hw_timer(h, i);
        tm->next   = (i + 1 < cap) ? (uint32_t)(i + 1) : HW_NIL;
        tm->prev   = HW_NIL;
        tm->bucket = HW_NIL;
        tm->state  &= ~1u;   /* clear active bit; keep generation so ids from before clear() stay distinguishable (no clear-then-reuse ABA) */
    }
    h->hdr->now = 0;
    h->hdr->count = 0;
    h->hdr->free_head = cap ? 0 : HW_NIL;
}

#endif /* HW_H */
