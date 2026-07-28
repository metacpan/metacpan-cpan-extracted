/*
 * reservoir.h -- Shared-memory reservoir sampler for Linux
 *
 * Maintains a uniform random sample of k items drawn from an unbounded stream
 * (Algorithm R) in fixed memory: each observed item either fills an empty slot
 * (while the reservoir is not yet full) or, once full, replaces a uniformly
 * random slot with probability k/i for the i-th item.  A shared xorshift64 RNG
 * lives in the header so concurrent processes sample one consistent reservoir.
 * A write-preferring futex rwlock with reader-slot dead-process recovery guards
 * mutation.  Items are stored inline, truncated to item_size bytes.
 *
 * A reservoir may instead be created in WEIGHTED mode (Efraimidis-Spirakis
 * A-Res): each item carries a weight and is kept with probability proportional
 * to it, via a shared min-heap keyed by u^(1/weight) over the same items region.
 *
 * Layout (uniform):  Header -> reader_slots[1024] -> occ -> items[k * (8 + item_size)]
 * Layout (weighted): Header -> reader_slots[1024] -> occ -> heap[k * 16] -> items[...]
 */

#ifndef RSV_H
#define RSV_H

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
#error "reservoir.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define RSV_MAGIC        0x52565352U  /* Reservoir */
#define RSV_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define RSV_ERR_BUFLEN   256
#ifndef RSV_READER_SLOTS
#define RSV_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these RSV_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all RSV_READER_SLOTS. */
#define RSV_OCC_WORDS   (((RSV_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define RSV_OCC_BYTES   ((uint64_t)RSV_OCC_WORDS * 8)      /* 128 bytes */
#define RSV_MIN_K        1
#define RSV_MAX_K        0x40000000ULL   /* 2^30 reservoir slots cap */
#define RSV_MIN_ITEM     1
#define RSV_MAX_ITEM     0x10000ULL      /* 64 KiB max bytes per stored item */

#define RSV_MODE_UNIFORM  0U             /* Algorithm R: uniform sample of the stream */
#define RSV_MODE_WEIGHTED 1U             /* Efraimidis-Spirakis A-Res: weighted sample */

#define RSV_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, RSV_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} RsvReaderSlot;

struct RsvHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t mode;                    /* 8   RSV_MODE_UNIFORM | RSV_MODE_WEIGHTED */
    uint32_t _pad1;                   /* 12 */
    uint64_t k;                       /* 16  reservoir capacity (number of slots) */
    uint64_t item_size;               /* 24  max bytes stored per item */
    uint64_t capacity;                /* 32  == k (family stats parity) */
    uint64_t stride;                  /* 40  bytes per slot: 8 (len) + item_size, 8-aligned */
    uint64_t total_size;              /* 48 */
    uint64_t reader_slots_off;        /* 56 */
    uint64_t slots_off;               /* 64 */
    uint32_t wlock;                   /* 72  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 76  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 80  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 88 */
    uint64_t seen;                    /* 96  total items observed (mutable, under wrlock) */
    uint64_t rng_state;               /* 104 xorshift64 RNG state (mutable, under wrlock) */
    uint64_t heap_off;                /* 112 weighted A-Res min-heap region (0 in uniform mode) */
    uint8_t  _pad[136];               /* 120..255 */
};
typedef struct RsvHeader RsvHeader;

_Static_assert(sizeof(RsvHeader) == 256, "RsvHeader must be 256 bytes");

/* Weighted (A-Res) min-heap entry: `key` = u^(1/weight), the smallest at the
 * root so a heavier arrival can evict it.  `item` indexes the items region (a
 * fixed cell that stays put -- only these 16-byte entries move during sift). */
typedef struct { double key; uint64_t item; } RsvHeapEnt;
_Static_assert(sizeof(RsvHeapEnt) == 16, "RsvHeapEnt must be 16 bytes");

/* ---- Process-local handle ---- */

typedef struct RsvHandle {
    RsvHeader     *hdr;
    RsvReaderSlot *reader_slots;  /* RSV_READER_SLOTS entries */
    uint64_t      *occ;          /* RSV_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      slots_off;   /* validated geometry, cached: never re-read from the peer-writable header */
    uint64_t      k;           /* reservoir size (cached) */
    uint64_t      item_size;   /* max bytes per item (cached) */
    uint64_t      stride;      /* per-slot byte stride (cached) */
    uint32_t      mode;        /* RSV_MODE_* sampling mode (cached from validated header) */
    uint64_t      heap_off;    /* weighted min-heap region offset (cached), 0 if uniform */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* rsv_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} RsvHandle;

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

#define RSV_RWLOCK_SPIN_LIMIT 32
#define RSV_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void rsv_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define RSV_RWLOCK_WRITER_BIT 0x80000000U
#define RSV_RWLOCK_PID_MASK   0x7FFFFFFFU
#define RSV_RWLOCK_WR(pid)    (RSV_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & RSV_RWLOCK_PID_MASK))

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
static inline int rsv_pid_is_zombie(uint32_t pid) {
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
static inline int rsv_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !rsv_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void rsv_recover_stale_lock(RsvHandle *h, uint32_t observed_wlock) {
    RsvHeader *hdr = h->hdr;
    uint32_t mypid = RSV_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec rsv_lock_timeout = { RSV_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t rsv_fork_gen = 1;
static pthread_once_t rsv_atfork_once = PTHREAD_ONCE_INIT;
static void rsv_on_fork_child(void) {
    __atomic_add_fetch(&rsv_fork_gen, 1, __ATOMIC_RELAXED);
}
static void rsv_atfork_init(void) {
    pthread_atfork(NULL, NULL, rsv_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void rsv_occ_set(RsvHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void rsv_occ_clear(RsvHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void rsv_claim_reader_slot(RsvHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&rsv_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&rsv_atfork_once, rsv_atfork_init);
    /* Re-read after pthread_once: rsv_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&rsv_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % RSV_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < RSV_READER_SLOTS; i++) {
        uint32_t s = (start + i) % RSV_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            rsv_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < RSV_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || rsv_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            rsv_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void rsv_recover_after_timeout(RsvHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= RSV_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & RSV_RWLOCK_PID_MASK;
        if (!rsv_pid_alive(pid))
            rsv_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void rsv_park(RsvHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void rsv_unpark(RsvHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void rsv_rdepth_inc(RsvHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void rsv_rdepth_dec(RsvHandle *h) {
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
static inline void rsv_reader_wake_drain(RsvHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void rsv_rwlock_rdlock(RsvHandle *h) {
    rsv_claim_reader_slot(h);
    RsvHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            rsv_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            rsv_rdepth_dec(h);
            rsv_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= RSV_RWLOCK_WRITER_BIT &&
            !rsv_pid_alive(cur & RSV_RWLOCK_PID_MASK)) {
            rsv_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < RSV_RWLOCK_SPIN_LIMIT, 1)) {
            rsv_rwlock_spin_pause();
            continue;
        }
        rsv_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &rsv_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                rsv_unpark(h);
                rsv_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        rsv_unpark(h);
        spin = 0;
    }
}

static inline void rsv_rwlock_rdunlock(RsvHandle *h) {
    rsv_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    rsv_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void rsv_rwlock_wrlock(RsvHandle *h) {
    rsv_claim_reader_slot(h);  /* refresh cached_pid across fork */
    RsvHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = RSV_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= RSV_RWLOCK_WRITER_BIT &&
            !rsv_pid_alive(expected & RSV_RWLOCK_PID_MASK)) {
            rsv_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < RSV_RWLOCK_SPIN_LIMIT, 1)) {
            rsv_rwlock_spin_pause();
            continue;
        }
        rsv_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &rsv_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                rsv_unpark(h);
                rsv_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        rsv_unpark(h);
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
         * this scan, so no held slot is skipped).  O(RSV_OCC_WORDS + live readers)
         * instead of O(RSV_READER_SLOTS). */
        for (uint32_t w = 0; w < RSV_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!rsv_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &rsv_lock_timeout, NULL, 0);
    }
}

static inline void rsv_rwlock_wrunlock(RsvHandle *h) {
    RsvHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> slots[k*(8+item_size)]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> slots. */
typedef struct { uint64_t reader_slots, occ, slots; } RsvLayout;

static inline RsvLayout rsv_layout(void) {
    RsvLayout L;
    L.reader_slots = sizeof(RsvHeader);
    L.occ          = L.reader_slots + (uint64_t)RSV_READER_SLOTS * sizeof(RsvReaderSlot);
    L.slots        = L.occ + RSV_OCC_BYTES;
    L.slots        = (L.slots + 7) & ~(uint64_t)7;   /* 8-byte align the slots array */
    return L;
}

/* bytes per slot: an 8-byte length followed by item_size data bytes, 8-aligned */
static inline uint64_t rsv_stride(uint64_t item_size) {
    return (8 + item_size + 7) & ~(uint64_t)7;
}

/* Weighted mode inserts a k-entry min-heap between the reader slots and the
 * items region; uniform mode has no heap.  These are the single source of truth
 * for the region offsets, used by both init and validate (never trust a stored
 * derived field -- always re-derive from k + mode). */
static inline uint64_t rsv_heap_region_off(uint32_t mode) {
    return (mode == RSV_MODE_WEIGHTED) ? rsv_layout().slots : 0;
}
static inline uint64_t rsv_items_off(uint64_t k, uint32_t mode) {
    RsvLayout L = rsv_layout();
    if (mode == RSV_MODE_WEIGHTED) {
        uint64_t after_heap = L.slots + k * sizeof(RsvHeapEnt);
        return (after_heap + 7) & ~(uint64_t)7;   /* 8-align the items array */
    }
    return L.slots;
}
static inline uint64_t rsv_total_size(uint64_t k, uint64_t item_size, uint32_t mode) {
    return rsv_items_off(k, mode) + k * rsv_stride(item_size);
}

static inline void rsv_init_header(void *base, uint64_t k, uint64_t item_size, uint32_t mode, uint64_t total) {
    RsvLayout L = rsv_layout();
    RsvHeader *hdr = (RsvHeader *)base;
    /* Zero the header + reader-slot region (lock-recovery state); the slots array
       relies on the fresh mapping being OS zero-filled (all lengths 0 = empty). */
    memset(base, 0, (size_t)L.slots);
    hdr->magic            = RSV_MAGIC;
    hdr->version          = RSV_VERSION;
    hdr->mode             = mode;
    hdr->k                = k;
    hdr->item_size        = item_size;
    hdr->capacity         = k;
    hdr->stride           = rsv_stride(item_size);
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->heap_off         = rsv_heap_region_off(mode);
    hdr->slots_off        = rsv_items_off(k, mode);
    hdr->seen             = 0;
    /* seed the shared RNG from process + monotonic-clock entropy (never zero) */
    {
        struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);
        uint64_t s = ((uint64_t)getpid() << 32) ^ (uint64_t)ts.tv_nsec ^ ((uint64_t)ts.tv_sec << 20);
        s ^= 0x9E3779B97F4A7C15ULL;
        hdr->rng_state = s ? s : 0x9E3779B97F4A7C15ULL;
    }
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint8_t *rsv_slots(RsvHandle *h) {
    return (uint8_t *)((char *)h->base + h->slots_off);
}

/* Layer B trusted bound: number of whole slots guaranteed within the real
 * mapping.  Derived from the process-local mmap_size and the SAME slots_off /
 * stride rsv_slots() uses, so a peer that corrupts hdr->k / stride / slots_off
 * after attach-time validation can never drive an access outside the mapping. */
static inline uint64_t rsv_slots_max(RsvHandle *h) {
    uint64_t off    = h->slots_off;
    uint64_t stride = h->stride;            /* cached at attach, not the peer-writable header */
    if (off >= h->mmap_size || stride == 0) return 0;
    return (h->mmap_size - off) / stride;
}

static inline RsvHandle *rsv_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    RsvHeader *hdr = (RsvHeader *)base;
    RsvHandle *h = (RsvHandle *)calloc(1, sizeof(RsvHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (RsvReaderSlot *)((uint8_t *)base + sizeof(RsvHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + rsv_layout().occ);        /* trusted layout offset */
    /* Cache the geometry from the validated header; the ops use these, never the
       peer-writable hdr->* fields, so a later corruption cannot change a stride /
       item_size / count out from under a bounds check. */
    h->slots_off    = hdr->slots_off;
    h->k            = hdr->k;
    h->item_size    = hdr->item_size;
    h->stride       = hdr->stride;
    h->mode         = hdr->mode;
    h->heap_off     = hdr->heap_off;
    h->mmap_size    = map_size;
    /* Layer B: if the mapping cannot even hold k slots the header lied about its
       size; clamp k to what actually fits (stride is validated 8+item_size). */
    if (h->stride) {
        uint64_t fit = (map_size > h->slots_off) ? (map_size - h->slots_off) / h->stride : 0;
        if (h->k > fit) h->k = fit;
    }
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by rsv_create reopen and rsv_open_fd). */
static inline int rsv_validate_header(const RsvHeader *hdr, uint64_t file_size) {
    if (hdr->magic != RSV_MAGIC) return 0;
    if (hdr->version != RSV_VERSION) return 0;
    if (hdr->mode != RSV_MODE_UNIFORM && hdr->mode != RSV_MODE_WEIGHTED) return 0;
    if (hdr->k < RSV_MIN_K || hdr->k > RSV_MAX_K) return 0;
    if (hdr->item_size < RSV_MIN_ITEM || hdr->item_size > RSV_MAX_ITEM) return 0;
    if (hdr->capacity != hdr->k) return 0;
    if (hdr->stride != rsv_stride(hdr->item_size)) return 0;
    if (hdr->heap_off != rsv_heap_region_off(hdr->mode)) return 0;
    if (hdr->slots_off != rsv_items_off(hdr->k, hdr->mode)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != rsv_total_size(hdr->k, hdr->item_size, hdr->mode)) return 0;
    RsvLayout L = rsv_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    return 1;
}

/* validate constructor args (k reservoir size, item_size max bytes per item) */
static int rsv_validate_args(uint64_t k, uint64_t item_size, uint32_t mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (k < RSV_MIN_K || k > RSV_MAX_K) { RSV_ERR("reservoir size must be between 1 and 2^30"); return 0; }
    if (item_size < RSV_MIN_ITEM || item_size > RSV_MAX_ITEM) { RSV_ERR("item_size must be between 1 and 65536"); return 0; }
    if (rsv_stride(item_size) > (UINT64_MAX / 4) / k) { RSV_ERR("reservoir_size * item_size too large"); return 0; }
    if (mode == RSV_MODE_WEIGHTED && sizeof(RsvHeapEnt) > (UINT64_MAX / 4) / k) { RSV_ERR("reservoir_size too large for the weighted heap"); return 0; }
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via rsv_validate_header. */
static int rsv_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { RSV_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        RSV_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    RSV_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static RsvHandle *rsv_create(const char *path, uint64_t k, uint64_t item_size, uint32_t weighted, mode_t mode, char *errbuf) {
    if (!rsv_validate_args(k, item_size, weighted, errbuf)) return NULL;

    uint64_t total = rsv_total_size(k, item_size, weighted);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { RSV_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = rsv_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { RSV_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { RSV_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(RsvHeader)) {
            RSV_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            RSV_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            RSV_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { RSV_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!rsv_validate_header((RsvHeader *)base, (uint64_t)st.st_size)) {
                RSV_ERR("invalid reservoir file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return rsv_setup(base, map_size, path, -1);
        }
    }
    rsv_init_header(base, k, item_size, weighted, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return rsv_setup(base, map_size, path, -1);
}

static RsvHandle *rsv_create_memfd(const char *name, uint64_t k, uint64_t item_size, uint32_t weighted, char *errbuf) {
    if (!rsv_validate_args(k, item_size, weighted, errbuf)) return NULL;

    uint64_t total = rsv_total_size(k, item_size, weighted);
    int fd = memfd_create(name ? name : "reservoir", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { RSV_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        RSV_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { RSV_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    rsv_init_header(base, k, item_size, weighted, total);
    return rsv_setup(base, (size_t)total, NULL, fd);
}

static RsvHandle *rsv_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { RSV_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(RsvHeader)) { RSV_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { RSV_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!rsv_validate_header((RsvHeader *)base, (uint64_t)st.st_size)) {
        RSV_ERR("invalid reservoir table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { RSV_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return rsv_setup(base, ms, NULL, myfd);
}

static void rsv_destroy(RsvHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&rsv_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        rsv_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int rsv_msync(RsvHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Reservoir sampling operations (callers hold the lock) -- Algorithm R with a
 * shared xorshift64 RNG.  Each slot is [uint64 len][item_size data bytes].
 * ================================================================ */

static inline uint64_t rsv_rng_next(RsvHeader *hdr) {
    uint64_t x = hdr->rng_state;
    x ^= x << 13; x ^= x >> 7; x ^= x << 17;   /* xorshift64 state advance (period/determinism preserved) */
    hdr->rng_state = x;
    /* SplitMix64 output finalizer: xorshift64 does not diffuse the seed into the
     * high bits, so the first post-seed output (and the high bits the weighted
     * A-Res key reads) would be a near-deterministic function of the seed.  Mix
     * the returned value across all 64 bits without touching the state advance. */
    uint64_t z = x;
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}

/* pointer to slot i's [uint64 len][item_size data] record */
static inline uint8_t *rsv_slot(RsvHandle *h, uint64_t i) {
    return rsv_slots(h) + i * h->stride;
}

/* store an item into slot idx (truncated to item_size) */
static inline void rsv_store(RsvHandle *h, uint64_t idx, const void *item, uint64_t len) {
    uint8_t *slot = rsv_slot(h, idx);
    uint64_t cap = h->item_size;            /* cached: <= stride-8, so the write stays in-slot */
    if (len > cap) len = cap;                   /* truncate over-long items */
    memcpy(slot, &len, sizeof(uint64_t));        /* stored length */
    if (len) memcpy(slot + 8, item, (size_t)len);
}

/* number of items currently held = min(seen, k) */
static inline uint64_t rsv_count_locked(RsvHandle *h) {
    uint64_t k = h->k, seen = h->hdr->seen;    /* k cached; seen is live mutable state */
    return seen < k ? seen : k;
}

/* observe one item.  Returns 1 if stored in the reservoir, 0 if discarded.
 * Algorithm R: the i-th item fills slot i-1 while the reservoir is not full;
 * once full, it replaces a uniformly random slot with probability k/i. */
static int rsv_add_locked(RsvHandle *h, const void *item, uint64_t len) {
    RsvHeader *hdr = h->hdr;
    uint64_t k = h->k;                          /* cached geometry */
    uint64_t smax = rsv_slots_max(h);
    if (k > smax) k = smax;                     /* Layer B: never index past the mapping */
    if (k == 0) return 0;
    uint64_t s = ++hdr->seen;                   /* 1-based index of this item */
    uint64_t idx;
    if (s <= k) {
        idx = s - 1;                            /* still filling the reservoir */
    } else {
        uint64_t j = rsv_rng_next(hdr) % s;     /* uniform in [0, s) */
        if (j >= k) return 0;                   /* discard (prob (s-k)/s) */
        idx = j;                                /* replace slot j (prob k/s) */
    }
    if (idx >= smax) return 0;                  /* Layer B: reject a wrapped/corrupt seen (idx underflow) -> no OOB */
    rsv_store(h, idx, item, len);
    return 1;
}

/* ---- weighted (A-Res) min-heap over the items region (weighted mode only) ----
 * One 16-byte {key,item} entry per kept item; entry.item indexes a fixed items
 * cell that stays put -- sifting moves only these entries, never the item bytes. */
static inline RsvHeapEnt *rsv_heap(RsvHandle *h) {
    return (RsvHeapEnt *)((char *)h->base + h->heap_off);
}
/* Layer B trusted bound: heap entries guaranteed within the real mapping. */
static inline uint64_t rsv_heap_max(RsvHandle *h) {
    uint64_t off = h->heap_off;
    if (off == 0 || off >= h->mmap_size) return 0;
    return (h->mmap_size - off) / sizeof(RsvHeapEnt);
}
static inline void rsv_heap_swap(RsvHeapEnt *hp, uint64_t a, uint64_t b) {
    RsvHeapEnt t = hp[a]; hp[a] = hp[b]; hp[b] = t;
}
static inline void rsv_heap_sift_up(RsvHeapEnt *hp, uint64_t i) {
    while (i > 0) {
        uint64_t p = (i - 1) / 2;
        if (hp[i].key < hp[p].key) { rsv_heap_swap(hp, i, p); i = p; } else break;
    }
}
static inline void rsv_heap_sift_down(RsvHeapEnt *hp, uint64_t i, uint64_t size) {
    for (;;) {
        uint64_t l = 2*i + 1, r = 2*i + 2, m = i;
        if (l < size && hp[l].key < hp[m].key) m = l;
        if (r < size && hp[r].key < hp[m].key) m = r;
        if (m == i) break;
        rsv_heap_swap(hp, i, m); i = m;
    }
}

/* observe one weighted item.  A-Res: assign it key = u^(1/weight), u ~ U(0,1];
 * keep the k items with the largest keys via a min-heap (root = smallest kept
 * key).  Returns 1 if kept, 0 if discarded.  `weight` is validated finite > 0 in
 * XS before the lock.  Caller holds the write lock. */
static int rsv_add_weighted_locked(RsvHandle *h, const void *item, uint64_t len, double weight) {
    RsvHeader *hdr = h->hdr;
    uint64_t k = h->k;                          /* cached geometry */
    uint64_t smax = rsv_slots_max(h);
    uint64_t hmax = rsv_heap_max(h);
    if (k > smax) k = smax;
    if (k > hmax) k = hmax;                     /* Layer B: never index past either region */
    if (k == 0) return 0;
    uint64_t x = rsv_rng_next(hdr);
    double u = (double)((x >> 11) + 1) * (1.0 / 9007199254740992.0);   /* (0, 1] */
    double key = pow(u, 1.0 / weight);
    RsvHeapEnt *hp = rsv_heap(h);
    uint64_t size = hdr->seen < k ? hdr->seen : k;   /* items currently kept */
    if (size < k) {                             /* still filling: append + sift up */
        rsv_store(h, size, item, len);
        hp[size].key = key; hp[size].item = size;
        rsv_heap_sift_up(hp, size);
        hdr->seen++;
        return 1;
    }
    hdr->seen++;                                /* full: this item was observed regardless */
    if (key > hp[0].key) {                       /* heavier than the current minimum: evict it */
        uint64_t cell = hp[0].item;
        if (cell >= k) return 0;                /* Layer B: corrupt heap entry -> refuse */
        rsv_store(h, cell, item, len);
        hp[0].key = key;
        rsv_heap_sift_down(hp, 0, k);
        return 1;
    }
    return 0;                                    /* lighter: discard */
}

/* point *out_ptr/*out_len at slot i's item inside the mapping (caller holds the
 * read lock).  Returns 1 if i is a filled slot, else 0. */
static int rsv_get_locked(RsvHandle *h, uint64_t i, const uint8_t **out_ptr, uint64_t *out_len) {
    if (i >= rsv_count_locked(h) || i >= rsv_slots_max(h)) return 0;
    uint8_t *slot = rsv_slot(h, i);
    uint64_t len; memcpy(&len, slot, sizeof(uint64_t));
    if (len > h->item_size) len = h->item_size;   /* Layer B clamp (cached item_size) */
    *out_ptr = slot + 8;
    *out_len = len;
    return 1;
}

/* reset the reservoir to empty (caller holds the write lock) */
static inline void rsv_clear_locked(RsvHandle *h) {
    uint64_t k = h->k;                          /* cached geometry */
    uint64_t smax = rsv_slots_max(h);
    if (k > smax) k = smax;
    for (uint64_t i = 0; i < k; i++) {           /* zero each slot's length word */
        uint64_t z = 0; memcpy(rsv_slot(h, i), &z, sizeof(uint64_t));
    }
    h->hdr->seen = 0;
}

#endif /* RSV_H */
