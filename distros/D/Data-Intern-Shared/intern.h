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
#define SI_VERSION      1
#define SI_ERR_BUFLEN   256
#define SI_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
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

/* Per-process slot for dead-process recovery.  Each shared rwlock counter
 * (the main rwlock-reader count, rwlock_waiters, rwlock_writers_waiting)
 * is mirrored here so a wrlock timeout can attribute and reverse a dead
 * process's contribution instead of waiting for the slow per-op timeout
 * drain. */
typedef struct {
    uint32_t pid;            /* 0 = unclaimed */
    uint32_t subcount;       /* in-flight rdlock acquisitions for this process */
    uint32_t waiters_parked; /* contribution to hdr->rwlock_waiters         */
    uint32_t writers_parked; /* contribution to hdr->rwlock_writers_waiting */
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
    uint32_t rwlock;                  /* 72 */
    uint32_t rwlock_waiters;          /* 76 */
    uint32_t rwlock_writers_waiting;  /* 80 */
    uint32_t _pad1;                   /* 84 */
    uint64_t stat_ops;                /* 88 */
    uint8_t  _pad[160];               /* 96..255 */
};
typedef struct SiHeader SiHeader;

_Static_assert(sizeof(SiHeader) == 256, "SiHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct SiHandle {
    SiHeader     *hdr;
    SiReaderSlot *reader_slots;  /* SI_READER_SLOTS entries */
    SiSlot       *slots;         /* forward hash: string -> id */
    uint32_t     *reverse;       /* id -> arena offset */
    uint8_t      *arena;         /* string store ([uint32 len][bytes] records) */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* si_fork_gen value at last slot claim */
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
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define SI_RWLOCK_SPIN_LIMIT 32
#define SI_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void si_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define SI_RWLOCK_WRITER_BIT 0x80000000U
#define SI_RWLOCK_PID_MASK   0x7FFFFFFFU
#define SI_RWLOCK_WR(pid)    (SI_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & SI_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/version change).
 * Documented under "Crash Safety" in the POD. */
static inline int si_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void si_recover_stale_lock(SiHandle *h, uint32_t observed_rwlock) {
    SiHeader *hdr = h->hdr;
    uint32_t mypid = SI_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
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

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
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
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % SI_READER_SLOTS;
    for (uint32_t i = 0; i < SI_READER_SLOTS; i++) {
        uint32_t s = (start + i) % SI_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Zero all mirror fields, not just subcount: a SIGKILL'd
             * predecessor may have left waiters_parked/writers_parked
             * non-zero, and si_recover_dead_readers won't drain them
             * once we own the slot (the CAS expects the dead PID). */
            __atomic_store_n(&h->reader_slots[s].subcount, 0, __ATOMIC_RELAXED);
            __atomic_store_n(&h->reader_slots[s].waiters_parked, 0, __ATOMIC_RELAXED);
            __atomic_store_n(&h->reader_slots[s].writers_parked, 0, __ATOMIC_RELAXED);
            h->my_slot_idx = s;
            return;
        }
    }
    /* Table full -- leave my_slot_idx = UINT32_MAX so we silently skip
     * tracking for this handle (lock still works; just no recovery). */
}

/* Atomically subtract `sub` from a counter, capped at 0 (never underflows). */
static inline void si_atomic_sub_cap(uint32_t *p, uint32_t sub) {
    if (!sub) return;
    uint32_t cur = __atomic_load_n(p, __ATOMIC_RELAXED);
    for (;;) {
        uint32_t want = (cur > sub) ? cur - sub : 0;
        if (__atomic_compare_exchange_n(p, &cur, want,
                1, __ATOMIC_RELAXED, __ATOMIC_RELAXED))
            return;
    }
}

/* Try to claim a dead slot (CAS pid -> 0) and drain its parked-waiter
 * contributions back to the global counters.  A no-op if the slot was stolen
 * by another recoverer or had no waiter contribution to drain.
 *
 * Note: subcount/waiters_parked/writers_parked are NOT zeroed here.
 * Between our CAS and a follow-up store, a new process could claim the
 * slot and start populating these fields -- our stores would clobber its
 * state.  si_claim_reader_slot zeros all three on every claim, so
 * leaving stale values is harmless. */
static inline void si_drain_dead_slot(SiHandle *h, uint32_t i, uint32_t pid) {
    SiHeader *hdr = h->hdr;
    uint32_t expected = pid;
    /* ACQ_REL on success: RELEASE publishes pid=0 to other observers;
     * ACQUIRE syncs us with prior writes from the dead process to
     * waiters_parked/writers_parked.  On weakly-ordered archs (aarch64)
     * a plain RELAXED load before the CAS could miss those writes;
     * loading them after the CAS keeps them inside the acquire window. */
    if (!__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    uint32_t wp    = __atomic_load_n(&h->reader_slots[i].waiters_parked, __ATOMIC_RELAXED);
    uint32_t writp = __atomic_load_n(&h->reader_slots[i].writers_parked, __ATOMIC_RELAXED);
    if (wp)    si_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) si_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
}

/* Scan reader slots for dead-process recovery.
 *
 * For each dead PID with non-zero contributions to the shared rwlock,
 * rwlock_waiters, or rwlock_writers_waiting counters, drain its share back
 * out so live processes don't have to wait for the slow per-op timeout
 * decrement to drain it for them.
 *
 * For the main rwlock counter we use the "no live reader holds -> force-
 * reset to 0" trick (precise) because per-process attribution of the
 * subcount is racy across the inc-counter-then-inc-subcount window. */
static inline void si_recover_dead_readers(SiHandle *h) {
    if (!h->reader_slots) return;
    SiHeader *hdr = h->hdr;
    int any_live_reader = 0;
    int found_dead_reader = 0;

    /* Pass 1: classify slots.  Slots with dead pid and sc == 0 (no rwlock
     * contribution to lose) are wiped immediately to free the slot for
     * future claimants and drain any orphan parked-waiter counters.  Slots
     * with dead pid and sc > 0 are left intact in this pass: if force-
     * reset cannot fire (because a live reader is concurrently present),
     * wiping the dead slot would lose the only record of its orphan
     * rwlock contribution and strand writers permanently once the live
     * reader releases. */
    for (uint32_t i = 0; i < SI_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (si_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        si_drain_dead_slot(h, i, pid);
    }

    /* Pass 2: only if force-reset will fire.  Issue the rwlock force-
     * reset CAS FIRST, while the window since pass 1's last scan is
     * still narrow (a handful of instructions, as in the original
     * single-pass code).  A new reader that started rdlock between
     * pass 1's scan and the CAS will either:
     *   (a) have already CAS'd rwlock from cur to cur+1 -- our CAS then
     *       fails (cur mismatched), recovery yields and a future
     *       cycle retries; or
     *   (b) be still in the subcount-bump phase -- our CAS sees the
     *       stale cur and resets to 0; the new reader's subsequent CAS
     *       rwlock(0 -> 1) succeeds cleanly.
     * Only after the CAS resolves do we wipe the deferred dead slots,
     * keeping that work outside the race-sensitive window. */
    if (found_dead_reader && !any_live_reader) {
        uint32_t cur = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
        if (cur > 0 && cur < SI_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            }
        }
        for (uint32_t i = 0; i < SI_READER_SLOTS; i++) {
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            if (pid == 0 || si_pid_alive(pid)) continue;
            si_drain_dead_slot(h, i, pid);
        }
    }
}

/* Inspect the lock word after a futex-wait timeout.  If a dead writer
 * holds it, force-recover the lock.  Otherwise drain dead readers' shares
 * of the rwlock/waiter counters.  Called from rdlock and wrlock ETIMEDOUT
 * branches -- identical recovery logic in both. */
static inline void si_recover_after_timeout(SiHandle *h) {
    SiHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= SI_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & SI_RWLOCK_PID_MASK;
        if (!si_pid_alive(pid))
            si_recover_stale_lock(h, val);
    } else {
        si_recover_dead_readers(h);
    }
}

/* Park/unpark helpers: bump the global waiter counters together with this
 * process's mirrored slot counters so a wrlock-timeout recovery scan can
 * attribute and reverse a dead PID's contribution.  Kept paired to make
 * accidental drift between global and per-slot counts impossible. */
static inline void si_park_reader(SiHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void si_unpark_reader(SiHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void si_park_writer(SiHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void si_unpark_writer(SiHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void si_rwlock_rdlock(SiHandle *h) {
    si_claim_reader_slot(h);
    SiHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    /* Claim subcount BEFORE bumping the shared rwlock counter.  This way
     * a concurrent writer-side recovery scan that sees our PID alive with
     * subcount > 0 will (correctly) defer force-reset, even while we are
     * still spinning trying to win the rwlock CAS.  Without this, a reader
     * killed between rwlock CAS-success and subcount++ would let recovery
     * force-reset rwlock to 0 underneath us, causing a UINT32_MAX wrap on
     * our eventual rdunlock dec. */
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Write-preferring: when lock is free (cur==0) and writers are
         * waiting, yield to let the writer acquire. When readers are
         * already active (cur>=1), new readers may join freely. */
        if (cur > 0 && cur < SI_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < SI_RWLOCK_SPIN_LIMIT, 1)) {
            si_rwlock_spin_pause();
            continue;
        }
        si_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= SI_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &si_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                si_unpark_reader(h);
                si_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        si_unpark_reader(h);
        spin = 0;
    }
}

static inline void si_rwlock_rdunlock(SiHandle *h) {
    SiHeader *hdr = h->hdr;
    /* Release the shared counter BEFORE dropping our subcount so that
     * "any live PID with subcount > 0" is a reliable in-flight indicator
     * for the writer-side recovery scan.  Inverting these would create a
     * window where we still own a unit of rwlock but our slot subcount is
     * 0, letting recovery force-reset rwlock underneath us. */
    uint32_t after = __atomic_sub_fetch(&hdr->rwlock, 1, __ATOMIC_RELEASE);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    if (after == 0 && __atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void si_rwlock_wrlock(SiHandle *h) {
    si_claim_reader_slot(h);  /* refresh cached_pid across fork */
    SiHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = SI_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < SI_RWLOCK_SPIN_LIMIT, 1)) {
            si_rwlock_spin_pause();
            continue;
        }
        si_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &si_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                si_unpark_writer(h);
                si_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        si_unpark_writer(h);
        spin = 0;
    }
}

static inline void si_rwlock_wrunlock(SiHandle *h) {
    SiHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> forward_hash -> reverse_array -> arena
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets. */
typedef struct { uint64_t reader_slots, hash, reverse, arena; } SiLayout;

static inline SiLayout si_layout(uint32_t hash_slots, uint32_t max_strings) {
    SiLayout L;
    L.reader_slots = sizeof(SiHeader);
    L.hash         = L.reader_slots + (uint64_t)SI_READER_SLOTS * sizeof(SiReaderSlot);
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
    h->reader_slots = (SiReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
    h->slots        = (SiSlot *)((uint8_t *)base + hdr->hash_off);
    h->reverse      = (uint32_t *)((uint8_t *)base + hdr->reverse_off);
    h->arena        = (uint8_t *)base + hdr->arena_off;
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

static SiHandle *si_create(const char *path, uint32_t max_strings, uint32_t arena_bytes, char *errbuf) {
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
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { SI_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { SI_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { SI_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(SiHeader)) {
            SI_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
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
    memset(h->slots, 0, (size_t)hdr->hash_slots * sizeof(SiSlot));
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
    uint32_t mask = h->hdr->hash_slots - 1;
    uint32_t i = (uint32_t)(hash & mask);
    uint8_t want_fp = (uint8_t)(hash & 0xff);
    while (h->slots[i].state) {
        if (h->slots[i].fp == want_fp) {
            uint32_t l;
            const char *cand = si_arena_str(h, h->reverse[h->slots[i].id], &l);
            if (l == n && memcmp(cand, s, n) == 0) { *found = 1; return i; }
        }
        i = (i + 1) & mask;
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
    if (hdr->count >= hdr->max_strings) return -1;
    uint64_t need = (uint64_t)sizeof(uint32_t) + n;   /* arena cap (<= UINT32_MAX) also bounds n */
    if ((uint64_t)hdr->arena_used + need > hdr->arena_bytes) return -1;
    uint32_t off = hdr->arena_used;
    uint32_t l = (uint32_t)n;
    memcpy(h->arena + off, &l, sizeof(l));
    if (n) memcpy(h->arena + off + sizeof(uint32_t), s, n);
    hdr->arena_used += (uint32_t)need;
    uint32_t id = hdr->count;
    h->reverse[id] = off;
    h->slots[slot].id    = id;
    h->slots[slot].fp    = (uint8_t)(hash & 0xff);
    h->slots[slot].state = 1;
    hdr->count++;
    return id;
}

#endif /* INTERN_H */
