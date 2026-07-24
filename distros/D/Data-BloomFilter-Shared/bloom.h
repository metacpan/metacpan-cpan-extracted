/*
 * bloom.h -- Shared-memory Bloom filter for Linux
 *
 * Probabilistic set membership: tells you whether an item is "definitely not"
 * or "probably" in the set, in a fixed amount of memory, with a tunable false-
 * positive rate and no false negatives. Each item is hashed once (XXH3-128);
 * the two 64-bit halves drive k probe bits (Kirsch-Mitzenmacher double hashing)
 * into a power-of-two bit array. The bit array lives in a shared mapping so
 * several processes share one filter; a write-preferring futex rwlock with
 * reader-slot dead-process recovery guards mutation. Two filters of equal
 * geometry can be merged (bitwise OR -> union of memberships).
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> bits[m_bits/8]
 */

#ifndef BLOOM_H
#define BLOOM_H

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
#error "bloom.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define BF_MAGIC        0x4D4F4F42U  /* "BOOM" (little-endian) */
#define BF_VERSION      2            /* 2: added the occupancy bitmap region (layout change) */
#define BF_ERR_BUFLEN   256
#ifndef BF_READER_SLOTS
#define BF_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these BF_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all BF_READER_SLOTS. */
#define BF_OCC_WORDS    (((BF_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define BF_OCC_BYTES    ((uint64_t)BF_OCC_WORDS * 8)      /* 128 bytes */
#define BF_MIN_BITS     64           /* floor on the bit array size (power of two) */
#define BF_MAX_BITS     0x4000000000ULL /* 2^38 bits = 32 GiB bit array cap */
#define BF_MIN_K        1
#define BF_MAX_K        32

#define BF_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, BF_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} BfReaderSlot;

struct BfHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t k;                       /* 8   number of hash probes per item */
    uint32_t _pad0;                   /* 12 */
    uint64_t m_bits;                  /* 16  bit array size in bits (power of two) */
    uint64_t m_mask;                  /* 24  m_bits - 1 (probe index mask) */
    uint64_t capacity;                /* 32  configured item capacity n (for stats) */
    double   fp_rate;                 /* 40  configured target false-positive rate (for stats) */
    uint64_t total_size;              /* 48 */
    uint64_t reader_slots_off;        /* 56 */
    uint64_t bits_off;                /* 64 */
    uint32_t wlock;                   /* 72  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 76  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 80  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct BfHeader BfHeader;

_Static_assert(sizeof(BfHeader) == 256, "BfHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct BfHandle {
    BfHeader     *hdr;
    BfReaderSlot *reader_slots;  /* BF_READER_SLOTS entries */
    uint64_t     *occ;           /* BF_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      bits_off;      /* validated bit-array offset, cached: never re-read from the peer-writable header */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* bf_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} BfHandle;

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

#define BF_RWLOCK_SPIN_LIMIT 32
#define BF_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void bf_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define BF_RWLOCK_WRITER_BIT 0x80000000U
#define BF_RWLOCK_PID_MASK   0x7FFFFFFFU
#define BF_RWLOCK_WR(pid)    (BF_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & BF_RWLOCK_PID_MASK))

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
static inline int bf_pid_is_zombie(uint32_t pid) {
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
static inline int bf_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !bf_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void bf_recover_stale_lock(BfHandle *h, uint32_t observed_wlock) {
    BfHeader *hdr = h->hdr;
    uint32_t mypid = BF_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec bf_lock_timeout = { BF_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t bf_fork_gen = 1;
static pthread_once_t bf_atfork_once = PTHREAD_ONCE_INIT;
static void bf_on_fork_child(void) {
    __atomic_add_fetch(&bf_fork_gen, 1, __ATOMIC_RELAXED);
}
static void bf_atfork_init(void) {
    pthread_atfork(NULL, NULL, bf_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void bf_occ_set(BfHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void bf_occ_clear(BfHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void bf_claim_reader_slot(BfHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&bf_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&bf_atfork_once, bf_atfork_init);
    /* Re-read after pthread_once: bf_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&bf_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % BF_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < BF_READER_SLOTS; i++) {
        uint32_t s = (start + i) % BF_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            bf_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < BF_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || bf_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            bf_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void bf_recover_after_timeout(BfHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= BF_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & BF_RWLOCK_PID_MASK;
        if (!bf_pid_alive(pid))
            bf_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void bf_park(BfHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void bf_unpark(BfHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void bf_rdepth_inc(BfHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void bf_rdepth_dec(BfHandle *h) {
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
static inline void bf_reader_wake_drain(BfHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void bf_rwlock_rdlock(BfHandle *h) {
    bf_claim_reader_slot(h);
    BfHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            bf_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            bf_rdepth_dec(h);
            bf_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= BF_RWLOCK_WRITER_BIT &&
            !bf_pid_alive(cur & BF_RWLOCK_PID_MASK)) {
            bf_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < BF_RWLOCK_SPIN_LIMIT, 1)) {
            bf_rwlock_spin_pause();
            continue;
        }
        bf_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &bf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                bf_unpark(h);
                bf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        bf_unpark(h);
        spin = 0;
    }
}

static inline void bf_rwlock_rdunlock(BfHandle *h) {
    bf_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    bf_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void bf_rwlock_wrlock(BfHandle *h) {
    bf_claim_reader_slot(h);  /* refresh cached_pid across fork */
    BfHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = BF_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= BF_RWLOCK_WRITER_BIT &&
            !bf_pid_alive(expected & BF_RWLOCK_PID_MASK)) {
            bf_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < BF_RWLOCK_SPIN_LIMIT, 1)) {
            bf_rwlock_spin_pause();
            continue;
        }
        bf_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &bf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                bf_unpark(h);
                bf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        bf_unpark(h);
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
         * this scan, so no held slot is skipped).  O(BF_OCC_WORDS + live readers)
         * instead of O(BF_READER_SLOTS). */
        for (uint32_t w = 0; w < BF_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!bf_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &bf_lock_timeout, NULL, 0);
    }
}

static inline void bf_rwlock_wrunlock(BfHandle *h) {
    BfHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> bits[m_bits/8]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> bits[]. */
typedef struct { uint64_t reader_slots, occ, bits; } BfLayout;

static inline BfLayout bf_layout(void) {
    BfLayout L;
    L.reader_slots = sizeof(BfHeader);
    L.occ          = L.reader_slots + (uint64_t)BF_READER_SLOTS * sizeof(BfReaderSlot);
    L.bits         = L.occ + BF_OCC_BYTES;
    L.bits         = (L.bits + 7) & ~(uint64_t)7;   /* 8-byte align the bit array (uint64_t words) */
    return L;
}

static inline uint64_t bf_total_size(uint64_t m_bits) {
    BfLayout L = bf_layout();
    return L.bits + (m_bits / 8);   /* m_bits is a power of two >= 64 -> exact bytes */
}

/* round v up to the next power of two (64-bit), with a floor of BF_MIN_BITS */
static inline uint64_t bf_next_pow2_u64(uint64_t v) {
    if (v <= BF_MIN_BITS) return BF_MIN_BITS;
    return 1ULL << (64 - __builtin_clzll(v - 1));
}

static inline void bf_init_header(void *base, uint32_t k, uint64_t m_bits,
                                  uint64_t capacity, double fp_rate, uint64_t total) {
    BfLayout L = bf_layout();
    BfHeader *hdr = (BfHeader *)base;
    /* Explicitly zero the header + reader-slot region (lock-recovery state, like
       hll.h); the bit array relies on the fresh mapping being OS zero-filled. */
    memset(base, 0, (size_t)L.bits);
    hdr->magic            = BF_MAGIC;
    hdr->version          = BF_VERSION;
    hdr->k                = k;
    hdr->m_bits           = m_bits;
    hdr->m_mask           = m_bits - 1;
    hdr->capacity         = capacity;
    hdr->fp_rate          = fp_rate;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->bits_off         = L.bits;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint64_t *bf_bits(BfHandle *h) {
    return (uint64_t *)((char *)h->base + h->bits_off);
}

/* Layer B trusted bound: the number of 64-bit words in the bit array that are
 * guaranteed to lie within the real mapping.  Derived from the process-local
 * mmap_size (fixed at attach time, not writable by a peer) and the SAME
 * bits_off that bf_bits() uses, so bits[0 .. bf_bits_words_max()-1] can never
 * fall outside the mapping even if a peer sharing the backing file corrupts the
 * header (m_bits / m_mask / bits_off) after attach-time validation.  For a
 * valid filter this equals m_bits/64 exactly, so every clamp below it is a
 * never-taken branch in normal use. */
static inline uint64_t bf_bits_words_max(BfHandle *h) {
    uint64_t off = h->bits_off;
    if (off >= h->mmap_size) return 0;
    return (h->mmap_size - off) / sizeof(uint64_t);
}

static inline BfHandle *bf_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    BfHeader *hdr = (BfHeader *)base;
    BfHandle *h = (BfHandle *)calloc(1, sizeof(BfHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (BfReaderSlot *)((uint8_t *)base + sizeof(BfHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + bf_layout().occ);       /* trusted layout offset */
    h->bits_off     = hdr->bits_off;   /* single validated read; bound and pointer stay consistent */
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by bf_create reopen and bf_open_fd). */
static inline int bf_validate_header(const BfHeader *hdr, uint64_t file_size) {
    if (hdr->magic != BF_MAGIC) return 0;
    if (hdr->version != BF_VERSION) return 0;
    if (hdr->k < BF_MIN_K || hdr->k > BF_MAX_K) return 0;
    if (hdr->m_bits < BF_MIN_BITS || hdr->m_bits > BF_MAX_BITS) return 0;
    if ((hdr->m_bits & (hdr->m_bits - 1)) != 0) return 0;        /* power of two */
    if (hdr->m_mask != hdr->m_bits - 1) return 0;
    if (hdr->capacity == 0) return 0;
    if (!(hdr->fp_rate > 0.0 && hdr->fp_rate < 1.0)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != bf_total_size(hdr->m_bits)) return 0;
    BfLayout L = bf_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->bits_off != L.bits) return 0;
    return 1;
}

/* validate args + compute the geometry (k, m_bits) */
static int bf_validate_create_args(uint64_t capacity, double fp_rate,
                                   uint32_t *k_out, uint64_t *m_bits_out, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity < 1) { BF_ERR("capacity must be >= 1"); return 0; }
    if (!(fp_rate > 0.0 && fp_rate < 1.0)) { BF_ERR("fp_rate must be between 0 and 1 (exclusive)"); return 0; }

    /* k = round(-log2(fp_rate)) clamped to [1, 32] */
    long kl = lround(-log2(fp_rate));
    if (kl < BF_MIN_K) kl = BF_MIN_K;
    if (kl > BF_MAX_K) kl = BF_MAX_K;
    uint32_t k = (uint32_t)kl;

    /* m_opt = ceil(capacity * k / ln2); reject if it would exceed the bit-array
     * cap (otherwise the filter would be silently undersized -> fp_rate broken);
     * m_bits = next_pow2(m_opt), floor BF_MIN_BITS. */
    double m_opt_d = ceil((double)capacity * (double)k / M_LN2);
    if (m_opt_d > (double)BF_MAX_BITS) { BF_ERR("capacity too large for the bit-array cap"); return 0; }
    uint64_t m_bits = bf_next_pow2_u64((uint64_t)m_opt_d);

    *k_out = k;
    *m_bits_out = m_bits;
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via bf_validate_header. */
static int bf_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { BF_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        BF_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    BF_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static BfHandle *bf_create(const char *path, uint64_t capacity, double fp_rate, mode_t mode, char *errbuf) {
    uint32_t k;
    uint64_t m_bits;
    if (!bf_validate_create_args(capacity, fp_rate, &k, &m_bits, errbuf)) return NULL;

    uint64_t total = bf_total_size(m_bits);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { BF_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = bf_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { BF_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { BF_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(BfHeader)) {
            BF_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            BF_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            BF_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { BF_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!bf_validate_header((BfHeader *)base, (uint64_t)st.st_size)) {
                BF_ERR("invalid Bloom filter file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return bf_setup(base, map_size, path, -1);
        }
    }
    bf_init_header(base, k, m_bits, capacity, fp_rate, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return bf_setup(base, map_size, path, -1);
}

static BfHandle *bf_create_memfd(const char *name, uint64_t capacity, double fp_rate, char *errbuf) {
    uint32_t k;
    uint64_t m_bits;
    if (!bf_validate_create_args(capacity, fp_rate, &k, &m_bits, errbuf)) return NULL;

    uint64_t total = bf_total_size(m_bits);
    int fd = memfd_create(name ? name : "bloom", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { BF_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        BF_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { BF_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    bf_init_header(base, k, m_bits, capacity, fp_rate, total);
    return bf_setup(base, (size_t)total, NULL, fd);
}

static BfHandle *bf_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { BF_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(BfHeader)) { BF_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { BF_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!bf_validate_header((BfHeader *)base, (uint64_t)st.st_size)) {
        BF_ERR("invalid Bloom filter table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { BF_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return bf_setup(base, ms, NULL, myfd);
}

static void bf_destroy(BfHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&bf_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        bf_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int bf_msync(BfHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Bloom filter operations (callers hold the lock) -- double hashing
 * (Kirsch-Mitzenmacher): one XXH3-128 hash drives all k probes.
 * ================================================================ */

static inline void bf_indices(BfHandle *h, const void *item, size_t len,
                              uint64_t *h1, uint64_t *h2) {
    (void)h;
    XXH128_hash_t hh = XXH3_128bits(item, len);
    *h1 = hh.low64;
    *h2 = hh.high64 | 1ULL;   /* force odd so the k probes spread over the pow2 table */
}

/* set k bits; return 1 if the item was probably NEW (at least one bit was 0), else 0 */
static int bf_add_locked(BfHandle *h, const void *item, size_t len) {
    uint64_t h1, h2;
    bf_indices(h, item, len, &h1, &h2);
    uint64_t mask = h->hdr->m_mask;
    uint32_t k = h->hdr->k;
    uint64_t *bits = bf_bits(h);
    /* Layer B: the highest word any masked probe can reach is (mask >> 6).
     * m_mask lives in the shared segment, so a peer that shares the backing
     * file could widen it past the real bit array after validation; bound it
     * against the mapping.  For a valid filter (mask == m_bits-1) this is
     * m_bits/64 - 1 < word_count, so the branch is never taken. */
    if ((mask >> 6) >= bf_bits_words_max(h)) return 0;
    int was_new = 0;
    for (uint32_t i = 0; i < k; i++) {
        uint64_t idx = (h1 + (uint64_t)i * h2) & mask;
        uint64_t word = idx >> 6;
        uint64_t bit  = 1ULL << (idx & 63);
        if (!(bits[word] & bit)) { bits[word] |= bit; was_new = 1; }
    }
    return was_new;
}

/* return 1 if ALL k bits are set (probably present), else 0 */
static int bf_contains_locked(BfHandle *h, const void *item, size_t len) {
    uint64_t h1, h2;
    bf_indices(h, item, len, &h1, &h2);
    uint64_t mask = h->hdr->m_mask;
    uint32_t k = h->hdr->k;
    uint64_t *bits = bf_bits(h);
    /* Layer B: bound the highest reachable word against the mapping (see
     * bf_add_locked).  A corrupt mask cannot confirm membership -> "not
     * present" is the safe answer; never-taken for a valid filter. */
    if ((mask >> 6) >= bf_bits_words_max(h)) return 0;
    for (uint32_t i = 0; i < k; i++) {
        uint64_t idx = (h1 + (uint64_t)i * h2) & mask;
        uint64_t word = idx >> 6;
        uint64_t bit  = 1ULL << (idx & 63);
        if (!(bits[word] & bit)) return 0;
    }
    return 1;
}

/* count set bits across the whole array (caller holds a lock) */
static uint64_t bf_popcount_locked(BfHandle *h) {
    uint64_t *bits = bf_bits(h);
    uint64_t words = h->hdr->m_bits / 64;
    uint64_t words_max = bf_bits_words_max(h);   /* Layer B: clamp scan to the mapping */
    if (words > words_max) words = words_max;
    uint64_t n = 0;
    for (uint64_t i = 0; i < words; i++)
        n += (uint64_t)__builtin_popcountll(bits[i]);
    return n;
}

/* estimate the number of distinct items added, from a pre-computed popcount X.
   n_est = -(m/k) * ln(1 - X/m); saturated -> capacity. (caller holds a lock) */
static uint64_t bf_count_from_popcount(BfHandle *h, uint64_t X) {
    uint64_t m_bits = h->hdr->m_bits;
    uint32_t k = h->hdr->k;
    if (X >= m_bits) return h->hdr->capacity;     /* saturated */
    double n_est = -((double)m_bits / (double)k) * log(1.0 - (double)X / (double)m_bits);
    if (n_est < 0.0) n_est = 0.0;
    return (uint64_t)(n_est + 0.5);
}

/* estimate the number of distinct items added (popcounts the array). (caller holds a lock) */
static uint64_t bf_count_locked(BfHandle *h) {
    return bf_count_from_popcount(h, bf_popcount_locked(h));
}

/* merge src words into dst (caller guarantees equal m_bits); bitwise OR.
 * src_count is the number of words the src_words buffer actually holds. */
static void bf_merge_words(BfHandle *dst, const uint64_t *src_words, uint64_t src_count) {
    uint64_t *bits = bf_bits(dst);
    uint64_t words = dst->hdr->m_bits / 64;
    uint64_t words_max = bf_bits_words_max(dst);  /* Layer B: clamp writes to dst mapping */
    if (words > words_max) words = words_max;
    if (words > src_count) words = src_count;     /* ...and reads to the src buffer */
    for (uint64_t i = 0; i < words; i++)
        bits[i] |= src_words[i];
}

/* reset all bits to 0 (caller holds the write lock) */
static inline void bf_clear_locked(BfHandle *h) {
    uint64_t words = h->hdr->m_bits / 64;
    uint64_t words_max = bf_bits_words_max(h);    /* Layer B: clamp memset to the mapping */
    if (words > words_max) words = words_max;
    memset(bf_bits(h), 0, (size_t)(words * sizeof(uint64_t)));
}

#endif /* BLOOM_H */
