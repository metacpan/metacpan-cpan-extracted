/*
 * intern.h -- Shared-memory string interning table for Linux
 *
 * Maps arbitrary byte strings to dense uint32 ids and back. Each string is
 * stored once in an append-only arena ([uint32 len][bytes]); an open-addressed
 * forward hash maps string -> id; reverse[id] -> arena offset is the one
 * authoritative id->offset map. Several processes share the mapping; a
 * write-preferring futex rwlock with reader-slot dead-process recovery guards
 * mutation.
 *
 * Layout: Header -> reader_slots[1024] -> forward_hash -> reverse_array -> arena
 */

#ifndef INTERN_H
#define INTERN_H

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

#define XXH_INLINE_ALL
#include "xxhash.h"

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "intern.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define SI_MAGIC        0x544E4953U  /* "SINT" (little-endian) */
#define SI_VERSION      2            /* 2: added the occupancy bitmap region (layout change) */
#define SI_ERR_BUFLEN   256
#define SI_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these SI_OCC_WORDS words to visit only
 * OCCUPIED slots (O(words + live readers)) instead of all SI_READER_SLOTS. */
#define SI_OCC_WORDS    (((SI_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define SI_OCC_BYTES    ((uint64_t)SI_OCC_WORDS * 8)       /* 128 bytes */
#define SI_MAX_STRINGS  0x40000000u  /* id-space cap (2^30) */
#define SI_MAX_ARENA    0xFFFFFFFFu  /* arena cap (offsets are uint32) */

#define SI_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, SI_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

/* ================================================================
 * Structs
 * ================================================================ */

/* forward-hash slot (open addressing): string -> id. Stores only the id; the
   string bytes are reached via reverse[id] -> arena, so there is one
   authoritative id->offset map. `fp` is the low 8 hash bits, a cheap
   fingerprint to skip most full compares on a probe collision. */
typedef struct {
    uint32_t id;       /* interned id */
    uint8_t  fp;       /* low 8 bits of the hash */
    uint8_t  state;    /* 0 empty, 1 occupied */
    uint16_t _pad;
} SiSlot;

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
} SiReaderSlot;

struct SiHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t max_strings;             /* 8   id capacity */
    uint32_t hash_slots;              /* 12  forward-hash slots (power of two) */
    uint32_t arena_bytes;             /* 16  arena capacity */
    uint32_t count;                   /* 20  interned strings; also the next id to assign */
    uint32_t arena_used;              /* 24  bytes used in the arena */
    uint32_t _pad0;                   /* 28 */
    uint64_t total_size;              /* 32 */
    uint64_t reader_slots_off;        /* 40 */
    uint64_t hash_off;                /* 48 */
    uint64_t reverse_off;             /* 56 */
    uint64_t arena_off;               /* 64 */
    uint32_t wlock;                   /* 72  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 76  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 80  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* 84  readers holding with no reader-slot (documented residual; was padding) */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct SiHeader SiHeader;

_Static_assert(sizeof(SiHeader) == 256, "SiHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct SiHandle {
    SiHeader     *hdr;
    SiReaderSlot *reader_slots;  /* SI_READER_SLOTS entries */
    uint64_t     *occ;           /* SI_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    SiSlot       *slots;         /* forward hash: string -> id */
    uint32_t     *reverse;       /* id -> arena offset */
    uint8_t      *arena;         /* string store ([uint32 len][bytes] records) */
    size_t        mmap_size;
    /* Immutable geometry cached at attach (values are validated in
     * si_validate_header on the open path, and correct-by-construction on the
     * create path).  Array indexing and loop bounds use THESE, never the live
     * h->hdr->{hash_slots,max_strings,arena_bytes}, so a lock-violating peer
     * that corrupts those header words after we attach cannot redirect an
     * index or loop bound out of the physically-sized shared arrays. */
    uint32_t      hash_slots;    /* forward-hash slot count (sizes h->slots)   */
    uint32_t      max_strings;   /* id capacity (sizes h->reverse)             */
    uint32_t      arena_bytes;   /* arena capacity (sizes h->arena)            */
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* si_fork_gen value at last slot claim */
    uint32_t      slotless_held; /* read-locks this process holds with no reader-slot */
} SiHandle;

/* ================================================================
 * Helpers
 * ================================================================ */

static inline uint32_t si_next_pow2(uint32_t v) {
    if (v < 2) return 1;
    return 1u << (32 - __builtin_clz(v - 1));
}

/* string hash (XXH3): deterministic across processes on this LE platform */
static inline uint64_t si_hash(const void *s, size_t n) {
    return XXH3_64bits(s, n);
}

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

#define SI_RWLOCK_SPIN_LIMIT 32
#define SI_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void si_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define SI_RWLOCK_WRITER_BIT 0x80000000U
#define SI_RWLOCK_PID_MASK   0x7FFFFFFFU
#define SI_RWLOCK_WR(pid)    (SI_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & SI_RWLOCK_PID_MASK))

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
static inline int si_pid_is_zombie(uint32_t pid) {
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
static inline int si_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !si_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void si_recover_stale_lock(SiHandle *h, uint32_t observed_wlock) {
    SiHeader *hdr = h->hdr;
    uint32_t mypid = SI_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec si_lock_timeout = { SI_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t si_fork_gen = 1;
static pthread_once_t si_atfork_once = PTHREAD_ONCE_INIT;
static void si_on_fork_child(void) {
    __atomic_add_fetch(&si_fork_gen, 1, __ATOMIC_RELAXED);
}
static void si_atfork_init(void) {
    pthread_atfork(NULL, NULL, si_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so that
 * fork()'d children pick up their own slot lazily instead of sharing the
 * parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void si_occ_set(SiHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void si_occ_clear(SiHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

static inline void si_claim_reader_slot(SiHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&si_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&si_atfork_once, si_atfork_init);
    /* Re-read after pthread_once: si_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&si_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % SI_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < SI_READER_SLOTS; i++) {
        uint32_t s = (start + i) % SI_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            si_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < SI_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || si_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            si_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void si_recover_after_timeout(SiHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= SI_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & SI_RWLOCK_PID_MASK;
        if (!si_pid_alive(pid))
            si_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void si_park(SiHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void si_unpark(SiHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void si_rdepth_inc(SiHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void si_rdepth_dec(SiHandle *h) {
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
static inline void si_reader_wake_drain(SiHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void si_rwlock_rdlock(SiHandle *h) {
    si_claim_reader_slot(h);
    SiHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            si_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            si_rdepth_dec(h);
            si_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= SI_RWLOCK_WRITER_BIT &&
            !si_pid_alive(cur & SI_RWLOCK_PID_MASK)) {
            si_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < SI_RWLOCK_SPIN_LIMIT, 1)) {
            si_rwlock_spin_pause();
            continue;
        }
        si_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &si_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                si_unpark(h);
                si_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        si_unpark(h);
        spin = 0;
    }
}

static inline void si_rwlock_rdunlock(SiHandle *h) {
    si_rdepth_dec(h);                  /* RELEASE: drop our entire contribution */
    si_reader_wake_drain(h);           /* if a writer is draining, wake it to re-scan */
}

static inline void si_rwlock_wrlock(SiHandle *h) {
    si_claim_reader_slot(h);  /* refresh cached_pid across fork */
    SiHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = SI_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= SI_RWLOCK_WRITER_BIT &&
            !si_pid_alive(expected & SI_RWLOCK_PID_MASK)) {
            si_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < SI_RWLOCK_SPIN_LIMIT, 1)) {
            si_rwlock_spin_pause();
            continue;
        }
        si_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &si_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                si_unpark(h);
                si_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        si_unpark(h);
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
         * this scan, so no held slot is skipped).  O(SI_OCC_WORDS + live readers)
         * instead of O(SI_READER_SLOTS). */
        for (uint32_t w = 0; w < SI_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!si_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &si_lock_timeout, NULL, 0);
    }
}

static inline void si_rwlock_wrunlock(SiHandle *h) {
    SiHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> forward_hash -> reverse_array -> arena
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets. */
typedef struct { uint64_t reader_slots, occ, hash, reverse, arena; } SiLayout;

static inline SiLayout si_layout(uint32_t hash_slots, uint32_t max_strings) {
    SiLayout L;
    L.reader_slots = sizeof(SiHeader);
    L.occ          = L.reader_slots + (uint64_t)SI_READER_SLOTS * sizeof(SiReaderSlot);
    L.hash         = L.occ + SI_OCC_BYTES;
    L.reverse      = L.hash + (uint64_t)hash_slots * sizeof(SiSlot);
    L.arena        = L.reverse + (uint64_t)max_strings * sizeof(uint32_t);
    L.arena        = (L.arena + 7) & ~(uint64_t)7;   /* 8-byte align the arena */
    return L;
}

static inline uint64_t si_total_size(uint32_t hash_slots, uint32_t max_strings, uint32_t arena_bytes) {
    SiLayout L = si_layout(hash_slots, max_strings);
    return L.arena + (uint64_t)arena_bytes;
}

static inline void si_init_header(void *base, uint32_t max_strings, uint32_t hash_slots,
                                  uint32_t arena_bytes, uint64_t total) {
    SiLayout L = si_layout(hash_slots, max_strings);
    SiHeader *hdr = (SiHeader *)base;
    /* zero the header + reader slots + hash region only; the reverse array and
       arena are read solely within [0,count)/[0,arena_used), both starting at 0,
       and the fresh mapping is already zero-filled by the OS. */
    memset(base, 0, (size_t)L.reverse);
    hdr->magic            = SI_MAGIC;
    hdr->version          = SI_VERSION;
    hdr->max_strings      = max_strings;
    hdr->hash_slots       = hash_slots;
    hdr->arena_bytes      = arena_bytes;
    hdr->count            = 0;
    hdr->arena_used       = 0;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->hash_off         = L.hash;
    hdr->reverse_off      = L.reverse;
    hdr->arena_off        = L.arena;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline SiHandle *si_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    SiHeader *hdr = (SiHeader *)base;
    SiHandle *h = (SiHandle *)calloc(1, sizeof(SiHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->reader_slots = (SiReaderSlot *)((uint8_t *)base + sizeof(SiHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + si_layout(hdr->hash_slots, hdr->max_strings).occ);  /* trusted layout offset */
    h->slots        = (SiSlot *)((uint8_t *)base + hdr->hash_off);
    h->reverse      = (uint32_t *)((uint8_t *)base + hdr->reverse_off);
    h->arena        = (uint8_t *)base + hdr->arena_off;
    h->hash_slots   = hdr->hash_slots;   /* cache immutable geometry at attach */
    h->max_strings  = hdr->max_strings;
    h->arena_bytes  = hdr->arena_bytes;
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by si_create reopen and si_open_fd). */
static inline int si_validate_header(const SiHeader *hdr, uint64_t file_size) {
    if (hdr->magic != SI_MAGIC) return 0;
    if (hdr->version != SI_VERSION) return 0;
    if (hdr->max_strings == 0 || hdr->max_strings > SI_MAX_STRINGS) return 0;
    if (hdr->hash_slots == 0 || (hdr->hash_slots & (hdr->hash_slots - 1)) != 0) return 0; /* pow2 */
    if (hdr->hash_slots <= hdr->max_strings) return 0;   /* probe termination: an empty slot always exists */
    if (hdr->arena_bytes == 0) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != si_total_size(hdr->hash_slots, hdr->max_strings, hdr->arena_bytes)) return 0;
    SiLayout L = si_layout(hdr->hash_slots, hdr->max_strings);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->hash_off    != L.hash)    return 0;
    if (hdr->reverse_off != L.reverse) return 0;
    if (hdr->arena_off   != L.arena)   return 0;
    if (hdr->count > hdr->max_strings) return 0;
    if (hdr->arena_used > hdr->arena_bytes) return 0;
    return 1;
}

/* validate args + compute the hash-slot count and (if 0) a default arena size */
static int si_validate_create_args(uint32_t max_strings, uint32_t *arena_bytes_io,
                                   uint32_t *hash_slots, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (max_strings == 0) { SI_ERR("max_strings must be > 0"); return 0; }
    if (max_strings > SI_MAX_STRINGS) { SI_ERR("max_strings too large (max %u)", SI_MAX_STRINGS); return 0; }
    uint64_t want = (uint64_t)max_strings * 10 / 7 + 1;        /* hash load factor ~0.7 */
    /* next_pow2(want) is always strictly > max_strings, so a probe always finds
       an empty slot (lookup misses cannot loop forever). With max_strings capped
       at 2^30, want <= ~1.43*2^30 < 2^31, whose next_pow2 is 2^31 -- fits uint32. */
    *hash_slots = si_next_pow2((uint32_t)want);
    if (*arena_bytes_io == 0) {                                /* default arena: 32 bytes/string */
        uint64_t a = (uint64_t)max_strings * 32;
        if (a > SI_MAX_ARENA) a = SI_MAX_ARENA;
        if (a < 64) a = 64;
        *arena_bytes_io = (uint32_t)a;
    }
    return 1;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at mode,
 * default 0600), or attach an existing file (O_RDWR|O_NOFOLLOW, no O_CREAT). */
static int si_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { SI_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        SI_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    SI_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static SiHandle *si_create(const char *path, uint32_t max_strings, uint32_t arena_bytes, mode_t mode, char *errbuf) {
    uint32_t hash_slots;
    if (!si_validate_create_args(max_strings, &arena_bytes, &hash_slots, errbuf)) return NULL;

    uint64_t total = si_total_size(hash_slots, max_strings, arena_bytes);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { SI_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = si_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { SI_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { SI_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(SiHeader)) {
            SI_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            SI_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            SI_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { SI_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!si_validate_header((SiHeader *)base, (uint64_t)st.st_size)) {
                SI_ERR("invalid intern file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return si_setup(base, map_size, path, -1);
        }
    }
    si_init_header(base, max_strings, hash_slots, arena_bytes, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return si_setup(base, map_size, path, -1);
}

static SiHandle *si_create_memfd(const char *name, uint32_t max_strings, uint32_t arena_bytes, char *errbuf) {
    uint32_t hash_slots;
    if (!si_validate_create_args(max_strings, &arena_bytes, &hash_slots, errbuf)) return NULL;

    uint64_t total = si_total_size(hash_slots, max_strings, arena_bytes);
    int fd = memfd_create(name ? name : "intern", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { SI_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        SI_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { SI_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    si_init_header(base, max_strings, hash_slots, arena_bytes, total);
    return si_setup(base, (size_t)total, NULL, fd);
}

static SiHandle *si_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { SI_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(SiHeader)) { SI_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { SI_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!si_validate_header((SiHeader *)base, (uint64_t)st.st_size)) {
        SI_ERR("invalid intern table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { SI_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return si_setup(base, ms, NULL, myfd);
}

static void si_destroy(SiHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&si_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        si_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int si_msync(SiHandle *h) {
    if (!h || !h->hdr) return 0;
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Interning (callers hold the lock)
 * ================================================================ */

/* reset to empty (caller holds the write lock) */
static inline void si_clear_locked(SiHandle *h) {
    SiHeader *hdr = h->hdr;
    hdr->count      = 0;
    hdr->arena_used = 0;
    memset(h->slots, 0, (size_t)h->hash_slots * sizeof(SiSlot));  /* cached geometry, not peer-writable hdr->hash_slots */
}

/* the string record at arena offset `off`: sets *len, returns a pointer to the
   bytes (the uint32 length prefix is read unaligned-safely) */
static inline const char *si_arena_str(SiHandle *h, uint32_t off, uint32_t *len) {
    uint32_t l;
    memcpy(&l, h->arena + off, sizeof(l));
    *len = l;
    return (const char *)(h->arena + off + sizeof(uint32_t));
}

/* slot for (s,n): if *found, an occupied matching slot; else the first empty
   slot for insertion. A probe always terminates (hash_slots > max_strings >= count). */
static inline uint32_t si_idx_find(SiHandle *h, const char *s, size_t n, uint64_t hash, int *found) {
    uint32_t hslots = h->hash_slots;   /* cached geometry: masks + bounds h->slots[] */
    uint32_t mask = hslots - 1;
    uint32_t i = (uint32_t)(hash & mask);
    uint8_t want_fp = (uint8_t)(hash & 0xff);
    /* count/arena_used are MUTABLE peer-writable header words used below as the
     * bound gating h->reverse[id] and h->arena[off] access.  Clamp each to the
     * cached PHYSICAL array size so a corrupted (over-large) counter cannot let
     * a crafted id/offset index past the mapped array.  No-op for a valid table
     * (count <= max_strings, arena_used <= arena_bytes always hold). */
    uint32_t count = h->hdr->count;
    if (count > h->max_strings) count = h->max_strings;
    uint32_t used  = h->hdr->arena_used;
    if (used > h->arena_bytes) used = h->arena_bytes;
    uint32_t probes = 0;
    while (h->slots[i].state) {
        if (h->slots[i].fp == want_fp) {
            /* slots[i].id, reverse[id] and the arena length prefix all come from
             * the mmap'd file; a local peer can corrupt them. Bound each before
             * dereferencing so a bad value skips this slot instead of trapping:
             * id must be a live id (< count), and the record [off .. off+4+len]
             * must lie within arena_used. For a valid table every check holds,
             * so a real hit is never dropped. */
            uint32_t id = h->slots[i].id;
            if (id < count) {
                uint32_t off = h->reverse[id];
                if (off <= used && used - off >= sizeof(uint32_t)) {
                    uint32_t l;
                    const char *cand = si_arena_str(h, off, &l);
                    if (l <= used - off - (uint32_t)sizeof(uint32_t)
                        && l == n && memcmp(cand, s, n) == 0) { *found = 1; return i; }
                }
            }
        }
        i = (i + 1) & mask;
        /* Cap the probe at the table size: a corrupted, fully-occupied slot
         * table (every state=1) would otherwise loop forever on a miss. A valid
         * table always has an empty slot (hash_slots > max_strings >= count). */
        if (++probes >= hslots) break;
    }
    *found = 0;
    return i;
}

/* id of (s,n) if present: returns 1 and sets *id, else 0 */
static inline int si_id_of_locked(SiHandle *h, const char *s, size_t n, uint32_t *id) {
    int f;
    uint32_t i = si_idx_find(h, s, n, si_hash(s, n), &f);
    if (f) { *id = h->slots[i].id; return 1; }
    return 0;
}

/* intern (s,n): returns the id (>=0, existing or new), or -1 if the id space or
   the arena is exhausted */
static int64_t si_intern_locked(SiHandle *h, const char *s, size_t n) {
    SiHeader *hdr = h->hdr;
    uint64_t hash = si_hash(s, n);
    int f;
    uint32_t slot = si_idx_find(h, s, n, hash, &f);
    if (f) return h->slots[slot].id;
    /* Read the mutable counters ONCE and bound them against the cached PHYSICAL
     * geometry (max_strings sizes reverse[], arena_bytes sizes arena[]); the
     * same local is then used as the write index, so a peer that mutates the
     * header word after the check cannot redirect the store out of bounds. */
    uint32_t id = hdr->count;
    if (id >= h->max_strings) return -1;
    uint64_t need = (uint64_t)sizeof(uint32_t) + n;   /* arena cap (<= UINT32_MAX) also bounds n */
    uint32_t off = hdr->arena_used;
    if ((uint64_t)off + need > h->arena_bytes) return -1;
    uint32_t l = (uint32_t)n;
    memcpy(h->arena + off, &l, sizeof(l));
    if (n) memcpy(h->arena + off + sizeof(uint32_t), s, n);
    hdr->arena_used += (uint32_t)need;
    h->reverse[id] = off;
    h->slots[slot].id    = id;
    h->slots[slot].fp    = (uint8_t)(hash & 0xff);
    /* Crash-consistent commit order: publish the arena bytes, reverse[id] and
     * slot id/fp, THEN commit the id (count++), THEN -- last -- make the slot
     * findable (state=1). A writer SIGKILL'd mid-commit then leaves at worst a
     * committed-but-unfindable id (a re-intern makes a harmless duplicate) or
     * a few leaked arena bytes. The old order (state=1 before count++) instead
     * left a FINDABLE slot whose id `count` had not advanced past, so the next
     * intern reused that id and collided (string(id) then returned the wrong
     * bytes). The release fences keep the order visible to a process that takes
     * the lock after dead-writer recovery. */
    __atomic_thread_fence(__ATOMIC_RELEASE);
    hdr->count++;
    __atomic_thread_fence(__ATOMIC_RELEASE);
    h->slots[slot].state = 1;
    return id;
}

#endif /* INTERN_H */
