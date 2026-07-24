/*
 * minhash.h -- Shared-memory MinHash sketch for Linux
 *
 * Jaccard-similarity estimation: keeps k "minimum hash" registers so that two
 * sketches, compared register by register, estimate the Jaccard similarity of
 * their underlying sets by the fraction of registers that agree, in a fixed
 * amount of memory. Each item is hashed once (XXH3-64) and mixed with each
 * register's index, so the k registers behave like k independent min-hashes and
 * every register keeps the minimum value it has ever seen. The registers live
 * in a shared mapping so several processes update one sketch; a write-preferring
 * futex rwlock with reader-slot dead-process recovery guards mutation. Two
 * sketches of equal size can be merged (element-wise minimum -> the sketch of
 * the union of the two sets).
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> registers[k*8]
 */

#ifndef MNH_H
#define MNH_H

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
#error "minhash.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define MNH_MAGIC        0x484E494DU  /* MinHash */
#define MNH_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define MNH_ERR_BUFLEN   256
#ifndef MNH_READER_SLOTS
#define MNH_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these MNH_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all MNH_READER_SLOTS. */
#define MNH_OCC_WORDS   (((MNH_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define MNH_OCC_BYTES   ((uint64_t)MNH_OCC_WORDS * 8)      /* 128 bytes */
#define MNH_MIN_K        1
#define MNH_MAX_K        0x1000000ULL   /* 2^24 registers cap */

#define MNH_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, MNH_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} MnhReaderSlot;

struct MnhHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t _pad0;                   /* 8 */
    uint32_t _pad1;                   /* 12 */
    uint64_t k;                       /* 16  number of min-hash registers */
    uint64_t _reserved0;              /* 24 */
    uint64_t capacity;                /* 32  == k (family stats parity) */
    uint64_t _reserved1;              /* 40 */
    uint64_t total_size;              /* 48 */
    uint64_t reader_slots_off;        /* 56 */
    uint64_t registers_off;           /* 64 */
    uint32_t wlock;                   /* 72  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 76  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 80  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct MnhHeader MnhHeader;

_Static_assert(sizeof(MnhHeader) == 256, "MnhHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct MnhHandle {
    MnhHeader     *hdr;
    MnhReaderSlot *reader_slots;  /* MNH_READER_SLOTS entries */
    uint64_t      *occ;          /* MNH_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      registers_off;  /* validated register-array offset, cached: never re-read from the peer-writable header */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* mnh_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} MnhHandle;

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

#define MNH_RWLOCK_SPIN_LIMIT 32
#define MNH_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void mnh_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define MNH_RWLOCK_WRITER_BIT 0x80000000U
#define MNH_RWLOCK_PID_MASK   0x7FFFFFFFU
#define MNH_RWLOCK_WR(pid)    (MNH_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & MNH_RWLOCK_PID_MASK))

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
static inline int mnh_pid_is_zombie(uint32_t pid) {
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
static inline int mnh_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !mnh_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void mnh_recover_stale_lock(MnhHandle *h, uint32_t observed_wlock) {
    MnhHeader *hdr = h->hdr;
    uint32_t mypid = MNH_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec mnh_lock_timeout = { MNH_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t mnh_fork_gen = 1;
static pthread_once_t mnh_atfork_once = PTHREAD_ONCE_INIT;
static void mnh_on_fork_child(void) {
    __atomic_add_fetch(&mnh_fork_gen, 1, __ATOMIC_RELAXED);
}
static void mnh_atfork_init(void) {
    pthread_atfork(NULL, NULL, mnh_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void mnh_occ_set(MnhHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void mnh_occ_clear(MnhHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void mnh_claim_reader_slot(MnhHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&mnh_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&mnh_atfork_once, mnh_atfork_init);
    /* Re-read after pthread_once: mnh_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&mnh_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % MNH_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < MNH_READER_SLOTS; i++) {
        uint32_t s = (start + i) % MNH_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            mnh_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < MNH_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || mnh_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            mnh_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void mnh_recover_after_timeout(MnhHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= MNH_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & MNH_RWLOCK_PID_MASK;
        if (!mnh_pid_alive(pid))
            mnh_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void mnh_park(MnhHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void mnh_unpark(MnhHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void mnh_rdepth_inc(MnhHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void mnh_rdepth_dec(MnhHandle *h) {
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
static inline void mnh_reader_wake_drain(MnhHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void mnh_rwlock_rdlock(MnhHandle *h) {
    mnh_claim_reader_slot(h);
    MnhHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            mnh_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            mnh_rdepth_dec(h);
            mnh_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= MNH_RWLOCK_WRITER_BIT &&
            !mnh_pid_alive(cur & MNH_RWLOCK_PID_MASK)) {
            mnh_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < MNH_RWLOCK_SPIN_LIMIT, 1)) {
            mnh_rwlock_spin_pause();
            continue;
        }
        mnh_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &mnh_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                mnh_unpark(h);
                mnh_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        mnh_unpark(h);
        spin = 0;
    }
}

static inline void mnh_rwlock_rdunlock(MnhHandle *h) {
    mnh_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    mnh_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void mnh_rwlock_wrlock(MnhHandle *h) {
    mnh_claim_reader_slot(h);  /* refresh cached_pid across fork */
    MnhHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = MNH_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= MNH_RWLOCK_WRITER_BIT &&
            !mnh_pid_alive(expected & MNH_RWLOCK_PID_MASK)) {
            mnh_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < MNH_RWLOCK_SPIN_LIMIT, 1)) {
            mnh_rwlock_spin_pause();
            continue;
        }
        mnh_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &mnh_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                mnh_unpark(h);
                mnh_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        mnh_unpark(h);
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
         * this scan, so no held slot is skipped).  O(MNH_OCC_WORDS + live readers)
         * instead of O(MNH_READER_SLOTS). */
        for (uint32_t w = 0; w < MNH_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!mnh_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &mnh_lock_timeout, NULL, 0);
    }
}

static inline void mnh_rwlock_wrunlock(MnhHandle *h) {
    MnhHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> registers[k*8]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> registers[]. */
typedef struct { uint64_t reader_slots, occ, registers; } MnhLayout;

static inline MnhLayout mnh_layout(void) {
    MnhLayout L;
    L.reader_slots = sizeof(MnhHeader);
    L.occ          = L.reader_slots + (uint64_t)MNH_READER_SLOTS * sizeof(MnhReaderSlot);
    L.registers    = L.occ + MNH_OCC_BYTES;
    L.registers    = (L.registers + 7) & ~(uint64_t)7;   /* 8-byte align the uint64 registers */
    return L;
}

static inline uint64_t mnh_total_size(uint64_t k) {
    MnhLayout L = mnh_layout();
    return L.registers + k * sizeof(uint64_t);
}

static inline void mnh_init_header(void *base, uint64_t k, uint64_t total) {
    MnhLayout L = mnh_layout();
    MnhHeader *hdr = (MnhHeader *)base;
    /* zero the header + reader-slot region, then fill the registers with the
       empty sentinel UINT64_MAX (a min-update replaces it with any real hash) */
    memset(base, 0, (size_t)L.registers);
    hdr->magic            = MNH_MAGIC;
    hdr->version          = MNH_VERSION;
    hdr->k                = k;
    hdr->capacity         = k;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->registers_off    = L.registers;
    memset((char *)base + L.registers, 0xFF, (size_t)(k * sizeof(uint64_t)));  /* registers = UINT64_MAX */
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint64_t *mnh_registers(MnhHandle *h) {
    return (uint64_t *)((char *)h->base + h->registers_off);
}

/* Layer B trusted bound: number of uint64 registers guaranteed within the real
 * mapping.  Derived from the process-local mmap_size and the SAME registers_off
 * mnh_registers() uses, so a peer that corrupts hdr->k / registers_off after
 * attach-time validation can never drive an access outside the mapping.  Equals
 * k for a valid sketch, so every clamp below it is a never-taken branch. */
static inline uint64_t mnh_reg_max(MnhHandle *h) {
    uint64_t off = h->registers_off;
    if (off >= h->mmap_size) return 0;
    return (h->mmap_size - off) / sizeof(uint64_t);
}

static inline MnhHandle *mnh_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    MnhHeader *hdr = (MnhHeader *)base;
    MnhHandle *h = (MnhHandle *)calloc(1, sizeof(MnhHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (MnhReaderSlot *)((uint8_t *)base + sizeof(MnhHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + mnh_layout().occ);        /* trusted layout offset */
    h->registers_off = hdr->registers_off;   /* single validated read; bound and pointer stay consistent */
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by mnh_create reopen and mnh_open_fd). */
static inline int mnh_validate_header(const MnhHeader *hdr, uint64_t file_size) {
    if (hdr->magic != MNH_MAGIC) return 0;
    if (hdr->version != MNH_VERSION) return 0;
    if (hdr->k < MNH_MIN_K || hdr->k > MNH_MAX_K) return 0;
    if (hdr->capacity != hdr->k) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != mnh_total_size(hdr->k)) return 0;
    MnhLayout L = mnh_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->registers_off != L.registers) return 0;
    return 1;
}

/* validate the requested number of registers k */
static int mnh_validate_args(uint64_t k, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (k < MNH_MIN_K || k > MNH_MAX_K) { MNH_ERR("number of registers must be between 1 and 2^24"); return 0; }
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via mnh_validate_header. */
static int mnh_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { MNH_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        MNH_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    MNH_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static MnhHandle *mnh_create(const char *path, uint64_t k, mode_t mode, char *errbuf) {
    if (!mnh_validate_args(k, errbuf)) return NULL;

    uint64_t total = mnh_total_size(k);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { MNH_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = mnh_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { MNH_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { MNH_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(MnhHeader)) {
            MNH_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            MNH_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            MNH_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { MNH_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!mnh_validate_header((MnhHeader *)base, (uint64_t)st.st_size)) {
                MNH_ERR("invalid MinHash sketch file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return mnh_setup(base, map_size, path, -1);
        }
    }
    mnh_init_header(base, k, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return mnh_setup(base, map_size, path, -1);
}

static MnhHandle *mnh_create_memfd(const char *name, uint64_t k, char *errbuf) {
    if (!mnh_validate_args(k, errbuf)) return NULL;

    uint64_t total = mnh_total_size(k);
    int fd = memfd_create(name ? name : "minhash", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { MNH_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        MNH_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { MNH_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    mnh_init_header(base, k, total);
    return mnh_setup(base, (size_t)total, NULL, fd);
}

static MnhHandle *mnh_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { MNH_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(MnhHeader)) { MNH_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { MNH_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!mnh_validate_header((MnhHeader *)base, (uint64_t)st.st_size)) {
        MNH_ERR("invalid MinHash sketch table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { MNH_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return mnh_setup(base, ms, NULL, myfd);
}

static void mnh_destroy(MnhHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&mnh_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        mnh_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int mnh_msync(MnhHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * MinHash operations (callers hold the lock).  Each of the k registers
 * holds the minimum hash value seen for an independent hash function; an
 * item is hashed once, then mixed with each register's index so the k
 * registers behave like k independent min-hashes.  The Jaccard similarity
 * of two sets is estimated by the fraction of registers that agree between
 * their sketches.
 * ================================================================ */

/* mix a base hash with register index j into an independent 64-bit value
 * (a splitmix64-style finalizer keyed by j) */
static inline uint64_t mnh_mix(uint64_t base, uint64_t j) {
    uint64_t x = base + (j + 1) * 0x9E3779B97F4A7C15ULL;
    x ^= x >> 30; x *= 0xBF58476D1CE4E5B9ULL;
    x ^= x >> 27; x *= 0x94D049BB133111EBULL;
    x ^= x >> 31;
    return x;
}

/* fold one item into the sketch: for each register keep the smaller of its
 * current value and this item's mixed hash.  Returns 1 if any register was
 * lowered (the item changed the sketch), else 0. */
static int mnh_add_locked(MnhHandle *h, const void *item, size_t len) {
    uint64_t base = XXH3_64bits(item, len);
    uint64_t k = h->hdr->k;
    uint64_t kmax = mnh_reg_max(h);        /* Layer B: clamp to the mapping */
    if (k > kmax) k = kmax;
    uint64_t *reg = mnh_registers(h);
    int changed = 0;
    for (uint64_t j = 0; j < k; j++) {
        uint64_t v = mnh_mix(base, j);
        if (v < reg[j]) { reg[j] = v; changed = 1; }
    }
    return changed;
}

/* count registers that agree between this sketch and a snapshot of another's
 * registers; the Jaccard estimate is agree / k.  other_k is how many
 * registers the snapshot buffer actually holds. */
static uint64_t mnh_agree_locked(MnhHandle *h, const uint64_t *other, uint64_t other_k) {
    uint64_t k = h->hdr->k;
    uint64_t kmax = mnh_reg_max(h);        /* Layer B: clamp to the mapping */
    if (k > kmax) k = kmax;
    if (k > other_k) k = other_k;          /* ...and to the snapshot buffer */
    uint64_t *reg = mnh_registers(h);
    uint64_t agree = 0;
    for (uint64_t j = 0; j < k; j++)
        if (reg[j] == other[j]) agree++;
    return agree;
}

/* ---- b-bit MinHash: compare / export only the low b bits of each register ---- */
static inline uint64_t mnh_bbit_mask(uint32_t b) {
    return (b >= 64) ? ~(uint64_t)0 : (((uint64_t)1 << b) - 1);
}
/* correct the observed b-bit match fraction f to a Jaccard estimate: two registers
 * whose true minimums differ still collide in b bits with probability 2^-b, so
 * P(match) = J + (1-J)*2^-b  =>  J = (f - 2^-b)/(1 - 2^-b), clamped to [0,1]. */
static inline double mnh_bbit_correct(double f, uint32_t b) {
    double j;
    if (b >= 64) j = f;                                   /* no random-collision term */
    else { double p0 = 1.0 / (double)((uint64_t)1 << b);  /* 2^-b, exact for b < 64 */
           j = (f - p0) / (1.0 - p0); }
    return j < 0.0 ? 0.0 : (j > 1.0 ? 1.0 : j);
}
/* count registers whose low b bits agree between this sketch and the `other` snapshot */
static uint64_t mnh_bbit_agree_locked(MnhHandle *h, const uint64_t *other, uint64_t other_k, uint64_t mask) {
    uint64_t k = h->hdr->k;
    uint64_t kmax = mnh_reg_max(h);        /* Layer B: clamp to the mapping */
    if (k > kmax) k = kmax;
    if (k > other_k) k = other_k;          /* ...and to the snapshot buffer */
    uint64_t *reg = mnh_registers(h);
    uint64_t agree = 0;
    for (uint64_t j = 0; j < k; j++)
        if ((reg[j] & mask) == (other[j] & mask)) agree++;
    return agree;
}
/* pack the low b bits of n registers into out[] (ceil(n*b/8) bytes; register i at bit i*b) */
static void mnh_bbit_pack(const uint64_t *reg, uint64_t n, uint32_t b, uint8_t *out) {
    uint64_t nbytes = (n * (uint64_t)b + 7) / 8;
    memset(out, 0, (size_t)nbytes);
    uint64_t mask = mnh_bbit_mask(b);
    for (uint64_t i = 0; i < n; i++) {
        uint64_t v = reg[i] & mask, bitpos = i * (uint64_t)b;
        for (uint32_t j = 0; j < b; j++)
            if ((v >> j) & 1) out[(bitpos + j) >> 3] |= (uint8_t)(1u << ((bitpos + j) & 7));
    }
}
/* extract register i's b-bit value from a packed signature buffer */
static inline uint64_t mnh_bbit_get(const uint8_t *buf, uint64_t i, uint32_t b) {
    uint64_t bitpos = i * (uint64_t)b, v = 0;
    for (uint32_t j = 0; j < b; j++)
        v |= (uint64_t)((buf[(bitpos + j) >> 3] >> ((bitpos + j) & 7)) & 1) << j;
    return v;
}

/* number of registers that have taken a value (differ from the UINT64_MAX
 * empty sentinel); 0 means the sketch is empty. (caller holds a lock) */
static uint64_t mnh_filled_locked(MnhHandle *h) {
    uint64_t k = h->hdr->k;
    uint64_t kmax = mnh_reg_max(h);        /* Layer B: clamp to the mapping */
    if (k > kmax) k = kmax;
    uint64_t *reg = mnh_registers(h);
    uint64_t filled = 0;
    for (uint64_t j = 0; j < k; j++)
        if (reg[j] != UINT64_MAX) filled++;
    return filled;
}

/* merge another sketch's registers into this one: element-wise minimum, so
 * the result is the min-hash sketch of the union of the two input sets.
 * src_k is the number of registers the src buffer actually holds. */
static void mnh_merge_locked(MnhHandle *dst, const uint64_t *src, uint64_t src_k) {
    uint64_t k = dst->hdr->k;
    uint64_t kmax = mnh_reg_max(dst);      /* Layer B: clamp writes to dst mapping */
    if (k > kmax) k = kmax;
    if (k > src_k) k = src_k;              /* ...and reads to the src buffer */
    uint64_t *reg = mnh_registers(dst);
    for (uint64_t j = 0; j < k; j++)
        if (src[j] < reg[j]) reg[j] = src[j];
}

/* reset every register to the empty sentinel (caller holds the write lock) */
static inline void mnh_clear_locked(MnhHandle *h) {
    uint64_t k = h->hdr->k;
    uint64_t kmax = mnh_reg_max(h);        /* Layer B: clamp memset to the mapping */
    if (k > kmax) k = kmax;
    memset(mnh_registers(h), 0xFF, (size_t)(k * sizeof(uint64_t)));
}

#endif /* MNH_H */
