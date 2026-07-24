/*
 * cuckoo.h -- Shared-memory Cuckoo filter for Linux
 *
 * Approximate set membership WITH delete: tells you whether an item is
 * "definitely not" or "probably" in the set, in a fixed amount of memory, with
 * a tiny false-positive rate -- and unlike a Bloom filter it supports removal.
 * Each item is hashed once (XXH3-128); a 16-bit fingerprint plus two candidate
 * buckets (partial-key cuckoo hashing) drive a bucketed open-addressed table of
 * CF_SLOTS fingerprint slots per bucket. The table lives in a shared mapping so
 * several processes share one filter; a write-preferring futex rwlock with
 * reader-slot dead-process recovery guards mutation. The filter has a bounded
 * capacity: add returns false (a true no-op) when the table is full.
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> slots[num_buckets * CF_SLOTS]
 */

#ifndef CUCKOO_H
#define CUCKOO_H

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
#error "cuckoo.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define CF_MAGIC        0x4B4F4F43U  /* "COOK" (little-endian) */
#define CF_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define CF_ERR_BUFLEN   256
#define CF_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these CF_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all CF_READER_SLOTS. */
#define CF_OCC_WORDS    (((CF_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define CF_OCC_BYTES    ((uint64_t)CF_OCC_WORDS * 8)      /* 128 bytes */
#define CF_SLOTS        4            /* fingerprint slots per bucket */
#define CF_MAX_KICKS    500          /* cuckoo eviction bound before declaring the table full */
#define CF_MIN_BUCKETS  2            /* floor on the bucket count (power of two) */
#define CF_MAX_BUCKETS  0x4000000000ULL /* 2^38 buckets cap (2^38*4*2 = 2 TiB slot array) */

#define CF_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, CF_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} CfReaderSlot;

struct CfHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t _pad0;                   /* 8  */
    uint32_t _pad1;                   /* 12 */
    uint64_t num_buckets;             /* 16  bucket count (power of two) */
    uint64_t bucket_mask;             /* 24  num_buckets - 1 (bucket index mask) */
    uint64_t capacity;                /* 32  configured item capacity (for stats) */
    uint64_t count;                   /* 40  live fingerprint count (maintained on add/remove) */
    uint64_t rng_state;               /* 48  xorshift64 state for eviction victim choice */
    uint64_t total_size;              /* 56 */
    uint64_t reader_slots_off;        /* 64 */
    uint64_t slots_off;               /* 72 */
    uint32_t wlock;                   /* 80  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 84  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 88  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* 92  readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 96 */
    uint8_t  _pad[152];               /* 104..255 */
};
typedef struct CfHeader CfHeader;

_Static_assert(sizeof(CfHeader) == 256, "CfHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct CfHandle {
    CfHeader     *hdr;
    CfReaderSlot *reader_slots;  /* CF_READER_SLOTS entries */
    uint64_t     *occ;           /* CF_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* cf_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} CfHandle;

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

#define CF_RWLOCK_SPIN_LIMIT 32
#define CF_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void cf_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define CF_RWLOCK_WRITER_BIT 0x80000000U
#define CF_RWLOCK_PID_MASK   0x7FFFFFFFU
#define CF_RWLOCK_WR(pid)    (CF_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & CF_RWLOCK_PID_MASK))

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
static inline int cf_pid_is_zombie(uint32_t pid) {
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
static inline int cf_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !cf_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void cf_recover_stale_lock(CfHandle *h, uint32_t observed_wlock) {
    CfHeader *hdr = h->hdr;
    uint32_t mypid = CF_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec cf_lock_timeout = { CF_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t cf_fork_gen = 1;
static pthread_once_t cf_atfork_once = PTHREAD_ONCE_INIT;
static void cf_on_fork_child(void) {
    __atomic_add_fetch(&cf_fork_gen, 1, __ATOMIC_RELAXED);
}
static void cf_atfork_init(void) {
    pthread_atfork(NULL, NULL, cf_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void cf_occ_set(CfHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void cf_occ_clear(CfHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so that
 * fork()'d children pick up their own slot lazily instead of sharing the
 * parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void cf_claim_reader_slot(CfHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&cf_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&cf_atfork_once, cf_atfork_init);
    /* Re-read after pthread_once: cf_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&cf_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % CF_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < CF_READER_SLOTS; i++) {
        uint32_t s = (start + i) % CF_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            cf_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < CF_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || cf_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            cf_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void cf_recover_after_timeout(CfHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= CF_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & CF_RWLOCK_PID_MASK;
        if (!cf_pid_alive(pid))
            cf_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void cf_park(CfHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void cf_unpark(CfHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void cf_rdepth_inc(CfHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void cf_rdepth_dec(CfHandle *h) {
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
static inline void cf_reader_wake_drain(CfHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void cf_rwlock_rdlock(CfHandle *h) {
    cf_claim_reader_slot(h);
    CfHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            cf_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            cf_rdepth_dec(h);
            cf_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= CF_RWLOCK_WRITER_BIT &&
            !cf_pid_alive(cur & CF_RWLOCK_PID_MASK)) {
            cf_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < CF_RWLOCK_SPIN_LIMIT, 1)) {
            cf_rwlock_spin_pause();
            continue;
        }
        cf_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &cf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                cf_unpark(h);
                cf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        cf_unpark(h);
        spin = 0;
    }
}

static inline void cf_rwlock_rdunlock(CfHandle *h) {
    cf_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    cf_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void cf_rwlock_wrlock(CfHandle *h) {
    cf_claim_reader_slot(h);  /* refresh cached_pid across fork */
    CfHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = CF_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= CF_RWLOCK_WRITER_BIT &&
            !cf_pid_alive(expected & CF_RWLOCK_PID_MASK)) {
            cf_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < CF_RWLOCK_SPIN_LIMIT, 1)) {
            cf_rwlock_spin_pause();
            continue;
        }
        cf_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &cf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                cf_unpark(h);
                cf_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        cf_unpark(h);
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
         * this scan, so no held slot is skipped).  O(CF_OCC_WORDS + live readers)
         * instead of O(CF_READER_SLOTS). */
        for (uint32_t w = 0; w < CF_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!cf_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &cf_lock_timeout, NULL, 0);
    }
}

static inline void cf_rwlock_wrunlock(CfHandle *h) {
    CfHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> slots[num_buckets * CF_SLOTS]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> slots[]. */
typedef struct { uint64_t reader_slots, occ, slots; } CfLayout;

static inline CfLayout cf_layout(void) {
    CfLayout L;
    L.reader_slots = sizeof(CfHeader);
    L.occ          = L.reader_slots + (uint64_t)CF_READER_SLOTS * sizeof(CfReaderSlot);
    L.slots        = L.occ + CF_OCC_BYTES;
    L.slots        = (L.slots + 7) & ~(uint64_t)7;   /* 8-byte align the slot array */
    return L;
}

static inline uint64_t cf_total_size(uint64_t num_buckets) {
    CfLayout L = cf_layout();
    /* num_buckets * CF_SLOTS uint16_t fingerprint slots */
    return L.slots + num_buckets * (uint64_t)CF_SLOTS * sizeof(uint16_t);
}

/* round v up to the next power of two (64-bit), with a floor of CF_MIN_BUCKETS */
static inline uint64_t cf_next_pow2_u64(uint64_t v) {
    if (v <= CF_MIN_BUCKETS) return CF_MIN_BUCKETS;
    return 1ULL << (64 - __builtin_clzll(v - 1));
}

static inline void cf_init_header(void *base, uint64_t num_buckets,
                                  uint64_t capacity, uint64_t total) {
    CfLayout L = cf_layout();
    CfHeader *hdr = (CfHeader *)base;
    /* Zero the header + reader-slot region (lock-recovery state); the slot
       array relies on the fresh mapping being OS zero-filled (0 = empty slot). */
    memset(base, 0, (size_t)L.slots);
    hdr->magic            = CF_MAGIC;
    hdr->version          = CF_VERSION;
    hdr->num_buckets      = num_buckets;
    hdr->bucket_mask      = num_buckets - 1;
    hdr->capacity         = capacity;
    hdr->count            = 0;
    /* Deterministic, non-zero seed for the eviction-victim RNG. */
    hdr->rng_state        = 0x9e3779b97f4a7c15ULL ^ (capacity * 0x2545F4914F6CDD1DULL);
    if (hdr->rng_state == 0) hdr->rng_state = 1;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->slots_off        = L.slots;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint16_t *cf_slots(CfHandle *h) {
    /* Layer B: locate the slot array via the trusted compile-time layout, NOT
     * the attacker-writable hdr->slots_off -- a peer that corrupts slots_off in
     * shared memory must not be able to relocate the base outside the mapping.
     * Validation at open guarantees hdr->slots_off == cf_layout().slots for a
     * valid filter, so this is identical for valid data. */
    return (uint16_t *)((char *)h->base + cf_layout().slots);
}

static inline CfHandle *cf_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    CfHeader *hdr = (CfHeader *)base;
    CfHandle *h = (CfHandle *)calloc(1, sizeof(CfHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (CfReaderSlot *)((uint8_t *)base + cf_layout().reader_slots);
    h->occ          = (uint64_t *)((uint8_t *)base + cf_layout().occ);        /* trusted layout offset */
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by cf_create reopen and cf_open_fd). */
static inline int cf_validate_header(const CfHeader *hdr, uint64_t file_size) {
    if (hdr->magic != CF_MAGIC) return 0;
    if (hdr->version != CF_VERSION) return 0;
    if (hdr->num_buckets < CF_MIN_BUCKETS || hdr->num_buckets > CF_MAX_BUCKETS) return 0;
    if ((hdr->num_buckets & (hdr->num_buckets - 1)) != 0) return 0;   /* power of two */
    if (hdr->bucket_mask != hdr->num_buckets - 1) return 0;
    if (hdr->capacity == 0) return 0;
    if (hdr->rng_state == 0) return 0;
    if (hdr->count > hdr->num_buckets * (uint64_t)CF_SLOTS) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != cf_total_size(hdr->num_buckets)) return 0;
    CfLayout L = cf_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->slots_off != L.slots) return 0;
    return 1;
}

/* validate args + compute the geometry (num_buckets) */
static int cf_validate_create_args(uint64_t capacity,
                                   uint64_t *num_buckets_out, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity < 1) { CF_ERR("capacity must be >= 1"); return 0; }

    /* Size for the target load factor: num_buckets =
       next_pow2(ceil(capacity / CF_SLOTS / 0.95)), floor CF_MIN_BUCKETS.
       Reject (don't silently cap) a capacity that would exceed the bucket cap,
       else the filter would be undersized and overflow at the requested load. */
    double want_d = ceil((double)capacity / (double)CF_SLOTS / 0.95);
    if (want_d > (double)CF_MAX_BUCKETS) { CF_ERR("capacity too large for the bucket cap"); return 0; }
    uint64_t num_buckets = cf_next_pow2_u64((uint64_t)want_d);   /* next_pow2 floors at CF_MIN_BUCKETS */

    *num_buckets_out = num_buckets;
    return 1;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at mode,
 * default 0600), or attach an existing file (O_RDWR|O_NOFOLLOW, no O_CREAT). */
static int cf_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { CF_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        CF_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    CF_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static CfHandle *cf_create(const char *path, uint64_t capacity, mode_t mode, char *errbuf) {
    uint64_t num_buckets;
    if (!cf_validate_create_args(capacity, &num_buckets, errbuf)) return NULL;

    uint64_t total = cf_total_size(num_buckets);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { CF_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = cf_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { CF_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { CF_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(CfHeader)) {
            CF_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            CF_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            CF_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { CF_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!cf_validate_header((CfHeader *)base, (uint64_t)st.st_size)) {
                CF_ERR("invalid Cuckoo filter file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return cf_setup(base, map_size, path, -1);
        }
    }
    cf_init_header(base, num_buckets, capacity, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return cf_setup(base, map_size, path, -1);
}

static CfHandle *cf_create_memfd(const char *name, uint64_t capacity, char *errbuf) {
    uint64_t num_buckets;
    if (!cf_validate_create_args(capacity, &num_buckets, errbuf)) return NULL;

    uint64_t total = cf_total_size(num_buckets);
    int fd = memfd_create(name ? name : "cuckoo", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { CF_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        CF_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { CF_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    cf_init_header(base, num_buckets, capacity, total);
    return cf_setup(base, (size_t)total, NULL, fd);
}

static CfHandle *cf_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { CF_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(CfHeader)) { CF_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { CF_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!cf_validate_header((CfHeader *)base, (uint64_t)st.st_size)) {
        CF_ERR("invalid Cuckoo filter table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { CF_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return cf_setup(base, ms, NULL, myfd);
}

static void cf_destroy(CfHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&cf_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        cf_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int cf_msync(CfHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Cuckoo filter operations (callers hold the lock)
 *
 * Partial-key cuckoo hashing from a single XXH3-128 hash: a 16-bit non-zero
 * fingerprint plus two candidate buckets i1 and i2 = alt(i1, fp), where alt is
 * an XOR-based involution so alt(alt(i,fp),fp) == i and i1 != i2.
 * ================================================================ */

/* xorshift64 victim-choice RNG; advances and stores hdr->rng_state.
 * Called only under the write lock. */
static inline uint64_t cf_rng_next(CfHandle *h) {
    uint64_t x = h->hdr->rng_state;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    h->hdr->rng_state = x;
    return x;
}

/* Spread a 16-bit fingerprint's bits across 64 bits (good integer mix). */
static inline uint64_t cf_fp_mix(uint16_t fp) {
    return (uint64_t)fp * 0x9e3779b97f4a7c15ULL;   /* golden-ratio mix; full 64 bits */
}

/* Alternate bucket for (i, fp): involutive XOR displacement masked to the
 * table. fh is forced non-zero so the alternate is always a different bucket
 * (i1 != i2). Since num_buckets is a power of two and fh < num_buckets,
 * i ^ fh stays < num_buckets, and alt(alt(i,fp),fp) == i. */
static inline uint64_t cf_alt(CfHandle *h, uint64_t i, uint16_t fp) {
    uint64_t mask = h->hdr->bucket_mask;
    uint64_t fh = cf_fp_mix(fp) & mask;
    if (fh == 0) fh = 1;
    return (i ^ fh) & mask;
}

/* Buckets that physically fit in the mapping, derived from the trusted
 * process-local mmap_size and the compile-time layout -- NOT from the
 * attacker-writable header geometry (num_buckets/bucket_mask/slots_off).
 * For any filter that passed validation at open this equals hdr->num_buckets
 * (mmap_size == cf_layout().slots + num_buckets*CF_SLOTS*2), so bounding
 * against it never changes behavior for valid data. */
static inline uint64_t cf_phys_buckets(CfHandle *h) {
    uint64_t base_off = cf_layout().slots;
    if (h->mmap_size <= base_off) return 0;
    return (uint64_t)(h->mmap_size - base_off) / ((uint64_t)CF_SLOTS * sizeof(uint16_t));
}

/* pointer to bucket i's CF_SLOTS fingerprint slots.
 * Layer B: the bucket index i is derived from hdr->bucket_mask (attacker-
 * writable), so fold any out-of-range i back into the physically-mapped bucket
 * range before indexing -- the returned pointer can then never fall outside the
 * mapping. i & (phys-1) <= phys-1 < phys for any i (AND only clears bits), so
 * this is in-bounds regardless of the corrupted value; for valid data i < phys
 * already, so it is a no-op. */
static inline uint16_t *cf_bucket(CfHandle *h, uint64_t i) {
    uint64_t phys = cf_phys_buckets(h);
    if (phys && i >= phys) i &= (phys - 1);
    return cf_slots(h) + i * (uint64_t)CF_SLOTS;
}

/* slot index of fp in bucket i, or -1 if absent */
static inline int cf_bucket_find(CfHandle *h, uint64_t i, uint16_t fp) {
    uint16_t *b = cf_bucket(h, i);
    for (int j = 0; j < CF_SLOTS; j++)
        if (b[j] == fp) return j;
    return -1;
}

/* place fp in a free (0) slot of bucket i: return 1 if placed, 0 if full */
static inline int cf_bucket_insert(CfHandle *h, uint64_t i, uint16_t fp) {
    uint16_t *b = cf_bucket(h, i);
    for (int j = 0; j < CF_SLOTS; j++) {
        if (b[j] == 0) { b[j] = fp; return 1; }
    }
    return 0;
}

/* derive the fingerprint and the two candidate buckets for (item,len) */
static inline void cf_hash(CfHandle *h, const void *item, size_t len,
                           uint16_t *fp_out, uint64_t *i1_out, uint64_t *i2_out) {
    XXH128_hash_t hh = XXH3_128bits(item, len);
    uint16_t fp = (uint16_t)(hh.high64 & 0xFFFF);
    if (fp == 0) fp = 1;                       /* 0 means empty slot; never use it */
    uint64_t i1 = (uint64_t)(hh.low64 & h->hdr->bucket_mask);
    *fp_out = fp;
    *i1_out = i1;
    *i2_out = cf_alt(h, i1, fp);
}

/* Add (item,len). Returns 1 on success, 0 if the table is full.
 *
 * ATOMIC: a failed add is a true no-op (the table is byte-identical to before),
 * so a failed add can never introduce a false negative -- every fingerprint
 * that was present stays present. The eviction path records every swap and
 * rolls them back in reverse if CF_MAX_KICKS is exhausted. */
static int cf_add_locked(CfHandle *h, const void *item, size_t len) {
    uint16_t fp;
    uint64_t i1, i2;
    cf_hash(h, item, len, &fp, &i1, &i2);

    if (cf_bucket_insert(h, i1, fp) || cf_bucket_insert(h, i2, fp)) {
        h->hdr->count++;
        return 1;
    }

    /* Both candidate buckets are full -> cuckoo eviction with a recorded
     * path so an exhausted run can be rolled back to a byte-identical state. */
    uint64_t path_i[CF_MAX_KICKS];
    uint8_t  path_j[CF_MAX_KICKS];
    uint64_t i = (cf_rng_next(h) & 1) ? i1 : i2;
    uint16_t carried = fp;
    for (int n = 0; n < CF_MAX_KICKS; n++) {
        uint8_t j = (uint8_t)(cf_rng_next(h) % CF_SLOTS);
        path_i[n] = i;
        path_j[n] = j;
        uint16_t tmp = cf_bucket(h, i)[j];      /* swap carried into slot j */
        cf_bucket(h, i)[j] = carried;
        carried = tmp;
        i = cf_alt(h, i, carried);              /* follow the evicted fingerprint */
        if (cf_bucket_insert(h, i, carried)) {  /* free slot in the new bucket? */
            h->hdr->count++;
            return 1;                           /* placed -> committed */
        }
    }
    /* Exhausted: roll back every swap in reverse so the table is unchanged.
     * After undoing step 0, carried == fp and nothing was modified. */
    for (int n = CF_MAX_KICKS - 1; n >= 0; n--) {
        uint16_t tmp = cf_bucket(h, path_i[n])[path_j[n]];
        cf_bucket(h, path_i[n])[path_j[n]] = carried;
        carried = tmp;
    }
    return 0;   /* full; NO state change */
}

/* return 1 if (item,len) is probably present, else 0 (definitely absent) */
static int cf_contains_locked(CfHandle *h, const void *item, size_t len) {
    uint16_t fp;
    uint64_t i1, i2;
    cf_hash(h, item, len, &fp, &i1, &i2);
    return cf_bucket_find(h, i1, fp) >= 0 || cf_bucket_find(h, i2, fp) >= 0;
}

/* Number of stored fingerprints matching (item,len) across its two candidate
 * buckets: 0 .. 2*CF_SLOTS. Since add stores a fresh copy each time and a given
 * fingerprint can only ever live in these two buckets, this is the item's
 * occurrence count -- how many times it was added minus removed -- capped at the
 * structural ceiling 2*CF_SLOTS (== 8). Probabilistic like contains(): a distinct
 * item whose 16-bit fingerprint collides AND maps into a candidate bucket inflates
 * the result (the remove() caveat). Guards i2 == i1 (a fingerprint can map both
 * candidates to the same bucket) so those 4 slots are not double-counted. */
static int cf_count_of_locked(CfHandle *h, const void *item, size_t len) {
    uint16_t fp;
    uint64_t i1, i2;
    cf_hash(h, item, len, &fp, &i1, &i2);
    int n = 0;
    uint16_t *b = cf_bucket(h, i1);
    for (int j = 0; j < CF_SLOTS; j++) if (b[j] == fp) n++;
    if (i2 != i1) {
        b = cf_bucket(h, i2);
        for (int j = 0; j < CF_SLOTS; j++) if (b[j] == fp) n++;
    }
    return n;
}

/* remove ONE matching fingerprint of (item,len): clear the slot, return 1 if
 * found, else 0. Removing an item that was never added (or one whose 16-bit
 * fingerprint collides with a present item) can delete the wrong fingerprint --
 * standard cuckoo-filter caveat; only remove items you added. */
static int cf_remove_locked(CfHandle *h, const void *item, size_t len) {
    uint16_t fp;
    uint64_t i1, i2;
    cf_hash(h, item, len, &fp, &i1, &i2);
    int j = cf_bucket_find(h, i1, fp);
    if (j >= 0) { cf_bucket(h, i1)[j] = 0; h->hdr->count--; return 1; }
    j = cf_bucket_find(h, i2, fp);
    if (j >= 0) { cf_bucket(h, i2)[j] = 0; h->hdr->count--; return 1; }
    return 0;
}

/* reset all slots to 0, count = 0 (caller holds the write lock) */
static inline void cf_clear_locked(CfHandle *h) {
    /* Layer B: bound the memset length by the physically-mapped bucket count so
     * a corrupted hdr->num_buckets can't drive an out-of-bounds write. For
     * valid data num_buckets == phys, so the clamp is a no-op. */
    uint64_t nb = h->hdr->num_buckets, phys = cf_phys_buckets(h);
    if (nb > phys) nb = phys;
    memset(cf_slots(h), 0, (size_t)(nb * (uint64_t)CF_SLOTS * sizeof(uint16_t)));
    h->hdr->count = 0;
}

#endif /* CUCKOO_H */
