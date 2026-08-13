/*
 * topk.h -- Shared-memory top-k heavy hitters (Space-Saving) for Linux
 *
 * Streaming heavy-hitters: with a fixed set of m counters it tracks the m most
 * frequent keys of a stream and estimates each one's count, using the
 * Space-Saving algorithm. Observing a monitored key bumps its counter;
 * observing a new key when full evicts the smallest counter and hands its count
 * to the newcomer as an over-estimate bound, so a key's true count lies in
 * [count-error, count]. A min-heap over the counts finds the eviction victim in
 * O(log m) and an intrusive hash index tests membership in O(1). The counters
 * live in a shared mapping so several processes feed one summary; a
 * write-preferring futex rwlock with reader-slot dead-process recovery guards
 * mutation. Keys are compared by their first key_size bytes.
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> slots[m] -> heap[m] -> buckets[nb]
 */

#ifndef TK_H
#define TK_H

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
#error "topk.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define TK_MAGIC        0x4B504F54  /* TopK */
#define TK_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define TK_ERR_BUFLEN   256
#ifndef TK_READER_SLOTS
#define TK_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these TK_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all TK_READER_SLOTS. */
#define TK_OCC_WORDS   (((TK_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define TK_OCC_BYTES   ((uint64_t)TK_OCC_WORDS * 8)      /* 128 bytes */
#define TK_MIN_CAP      1                /* min number of monitored counters */
#define TK_MAX_CAP      0x1000000ULL     /* 2^24 counters cap */
#define TK_MIN_KEYSIZE  1                /* min inline key bytes */
#define TK_MAX_KEYSIZE  4096             /* max inline key bytes */
#define TK_NIL          0xFFFFFFFFU      /* empty slot-index sentinel (hash chains, heap) */

#define TK_MODE_PLAIN   0U               /* integer counts (classic Space-Saving) */
#define TK_MODE_DECAYED 1U               /* forward-decayed weighted counts (Cormode) */
#define TK_RESCALE_LN   34.0             /* rescale the landmark once alpha*(now-L) exceeds this (g ~ 6e14) */

#define TK_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, TK_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} TkReaderSlot;

struct TkHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t capacity;                /* 8   m: number of monitored counters (slots) */
    uint32_t key_size;                /* 12  max inline key bytes */
    uint64_t hash_buckets;            /* 16  number of hash buckets (power of two) */
    uint64_t used;                    /* 24  distinct keys currently monitored (<= capacity) */
    uint64_t seen;                    /* 32  total observations */
    uint64_t slots_off;               /* 40  offset of the slots array */
    uint64_t total_size;              /* 48 */
    uint64_t reader_slots_off;        /* 56 */
    uint64_t heap_off;                /* 64  offset of the min-heap array (slot indices) */
    uint32_t wlock;                   /* 72  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 76  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 80  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;   /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 88 */
    uint64_t bucket_off;              /* 96  offset of the hash bucket array */
    uint32_t mode;                    /* 104 TK_MODE_PLAIN | TK_MODE_DECAYED */
    uint32_t _pad2;                   /* 108 */
    double   alpha;                   /* 112 decay rate ln(2)/half_life (decayed mode; 0 if plain) */
    double   now;                     /* 120 current time: max timestamp seen, or per-add tick */
    double   landmark;                /* 128 forward-decay landmark L (decayed mode) */
    uint8_t  _pad[120];               /* 136..255 */
};
typedef struct TkHeader TkHeader;

_Static_assert(sizeof(TkHeader) == 256, "TkHeader must be 256 bytes");

/* Per-slot record: a monitored (key, count, error) triple.  The key bytes
 * (key_size of them) follow this fixed header in memory; the per-slot stride
 * is sizeof(TkSlot) + align8(key_size).  heap_pos is this slot's index in the
 * min-heap; hnext chains slots that share a hash bucket. */
typedef struct {
    uint64_t count;      /* observed count (an upper bound on the true count) */
    uint64_t error;      /* max over-estimate: true count is in [count-error, count] */
    uint32_t heap_pos;   /* position of this slot in the heap array */
    uint32_t hnext;      /* next slot in the hash chain, or TK_NIL */
    uint32_t key_len;    /* stored key length (<= key_size) */
    uint32_t _pad;       /* keep the trailing key bytes 8-aligned */
} TkSlot;
_Static_assert(sizeof(TkSlot) == 32, "TkSlot must be 32 bytes");

/* ---- Process-local handle ---- */

typedef struct TkHandle {
    TkHeader     *hdr;
    TkReaderSlot *reader_slots;  /* TK_READER_SLOTS entries */
    uint64_t     *occ;           /* TK_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void         *base;          /* mmap base */
    uint64_t      slots_off;     /* validated, cached: never re-read from the peer-writable header */
    uint64_t      heap_off;      /* validated, cached */
    uint64_t      bucket_off;    /* validated, cached */
    uint32_t      capacity;      /* m, cached */
    uint32_t      key_size;      /* cached */
    uint64_t      hash_mask;     /* hash_buckets - 1, cached */
    uint64_t      stride;        /* per-slot byte stride, cached */
    uint32_t      mode;          /* TK_MODE_* (cached from validated header) */
    double        alpha;         /* decay rate (cached; 0 if plain) */
    size_t        mmap_size;
    char         *path;          /* backing file path (strdup'd) */
    int           backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t      my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t      cached_pid;    /* getpid() cached at last slot claim */
    uint32_t      cached_fork_gen; /* tk_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} TkHandle;

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

#define TK_RWLOCK_SPIN_LIMIT 32
#define TK_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void tk_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define TK_RWLOCK_WRITER_BIT 0x80000000U
#define TK_RWLOCK_PID_MASK   0x7FFFFFFFU
#define TK_RWLOCK_WR(pid)    (TK_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & TK_RWLOCK_PID_MASK))

/* A zombie (dead but not yet reaped) still answers kill(pid,0) as alive, so a
 * process that crashed while holding the lock and lingers unreaped would never
 * be recovered.  Treat /proc/<pid>/stat state 'Z' as dead.  Linux-only (as is
 * this module); if /proc is unreadable we fall back to "alive" (safe: we never
 * force-recover a possibly-live holder). */
static inline int tk_pid_is_zombie(uint32_t pid) {
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
/* 1 if alive or unknown, 0 if definitely dead.  Cannot detect PID reuse: a
 * recycled PID reports "alive" and the slot is not reclaimed until that
 * process exits.  See "Crash Safety" in the POD. */
static inline int tk_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !tk_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void tk_recover_stale_lock(TkHandle *h, uint32_t observed_wlock) {
    TkHeader *hdr = h->hdr;
    uint32_t mypid = TK_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec tk_lock_timeout = { TK_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t tk_fork_gen = 1;
static pthread_once_t tk_atfork_once = PTHREAD_ONCE_INIT;
static void tk_on_fork_child(void) {
    __atomic_add_fetch(&tk_fork_gen, 1, __ATOMIC_RELAXED);
}
static void tk_atfork_init(void) {
    pthread_atfork(NULL, NULL, tk_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void tk_occ_set(TkHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void tk_occ_clear(TkHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so that
 * fork()'d children pick up their own slot lazily instead of sharing the
 * parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void tk_claim_reader_slot(TkHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&tk_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&tk_atfork_once, tk_atfork_init);
    /* Re-read after pthread_once: tk_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&tk_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % TK_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < TK_READER_SLOTS; i++) {
        uint32_t s = (start + i) % TK_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            tk_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it. */
    for (uint32_t i = 0; i < TK_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || tk_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            tk_occ_set(h, i);
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
static inline void tk_recover_after_timeout(TkHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= TK_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & TK_RWLOCK_PID_MASK;
        if (!tk_pid_alive(pid))
            tk_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void tk_park(TkHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void tk_unpark(TkHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void tk_rdepth_inc(TkHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void tk_rdepth_dec(TkHandle *h) {
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
static inline void tk_reader_wake_drain(TkHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void tk_rwlock_rdlock(TkHandle *h) {
    tk_claim_reader_slot(h);
    TkHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            tk_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            tk_rdepth_dec(h);
            tk_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= TK_RWLOCK_WRITER_BIT &&
            !tk_pid_alive(cur & TK_RWLOCK_PID_MASK)) {
            tk_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < TK_RWLOCK_SPIN_LIMIT, 1)) {
            tk_rwlock_spin_pause();
            continue;
        }
        tk_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &tk_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                tk_unpark(h);
                tk_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        tk_unpark(h);
        spin = 0;
    }
}

static inline void tk_rwlock_rdunlock(TkHandle *h) {
    tk_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    tk_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void tk_rwlock_wrlock(TkHandle *h) {
    tk_claim_reader_slot(h);  /* refresh cached_pid across fork */
    TkHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = TK_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= TK_RWLOCK_WRITER_BIT &&
            !tk_pid_alive(expected & TK_RWLOCK_PID_MASK)) {
            tk_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < TK_RWLOCK_SPIN_LIMIT, 1)) {
            tk_rwlock_spin_pause();
            continue;
        }
        tk_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &tk_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                tk_unpark(h);
                tk_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        tk_unpark(h);
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
         * this scan, so no held slot is skipped).  O(TK_OCC_WORDS + live readers)
         * instead of O(TK_READER_SLOTS). */
        for (uint32_t w = 0; w < TK_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!tk_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &tk_lock_timeout, NULL, 0);
    }
}

static inline void tk_rwlock_wrunlock(TkHandle *h) {
    TkHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> slots[m] -> heap[m] -> buckets[nb]
 *   slots[]   : m records of (count, error, key); stride = sizeof(TkSlot)+align8(key_size)
 *   heap[]    : m uint32 slot-indices, a min-heap ordered by slot count
 *   buckets[] : nb uint32 slot-indices (or TK_NIL), an intrusive hash index
 * ================================================================ */

#define TK_SLOT_OK(h, i) ((uint64_t)(i) < (uint64_t)(h)->capacity)

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> slots[] -> heap[] -> buckets[]. */
typedef struct { uint64_t reader_slots, occ, slots, heap, buckets, total; } TkLayout;

/* per-slot byte stride for a given key_size (keeps each slot 8-aligned) */
static inline uint64_t tk_stride(uint32_t key_size) {
    return (uint64_t)sizeof(TkSlot) + (((uint64_t)key_size + 7) & ~(uint64_t)7);
}

/* number of hash buckets for m counters: next_pow2(2*m), floor 8 (load <= 0.5) */
static inline uint64_t tk_buckets_for(uint64_t m) {
    uint64_t want = m * 2;
    if (want < 8) want = 8;
    if ((want & (want - 1)) == 0) return want;
    return 1ULL << (64 - __builtin_clzll(want));
}

static inline TkLayout tk_layout_for(uint32_t m, uint32_t key_size) {
    TkLayout L;
    uint64_t stride = tk_stride(key_size);
    L.reader_slots = sizeof(TkHeader);
    L.occ          = L.reader_slots + (uint64_t)TK_READER_SLOTS * sizeof(TkReaderSlot);
    L.slots        = L.occ + TK_OCC_BYTES;
    L.slots        = (L.slots + 7) & ~(uint64_t)7;
    L.heap         = L.slots + (uint64_t)m * stride;
    L.heap         = (L.heap + 7) & ~(uint64_t)7;
    L.buckets      = L.heap + (uint64_t)m * sizeof(uint32_t);
    L.buckets      = (L.buckets + 7) & ~(uint64_t)7;
    L.total        = L.buckets + tk_buckets_for(m) * sizeof(uint32_t);
    return L;
}

static inline uint64_t tk_total_size(uint32_t m, uint32_t key_size) {
    return tk_layout_for(m, key_size).total;
}

static inline void tk_init_header(void *base, uint32_t m, uint32_t key_size, uint32_t mode, double alpha, uint64_t total) {
    TkLayout L = tk_layout_for(m, key_size);
    TkHeader *hdr = (TkHeader *)base;
    /* Zero header + reader-slots + slots + heap, then set every hash bucket to
       TK_NIL (0xFF bytes) so the table starts empty. */
    memset(base, 0, (size_t)L.buckets);
    memset((char *)base + L.buckets, 0xFF, (size_t)(L.total - L.buckets));   /* buckets = TK_NIL */
    hdr->version          = TK_VERSION;
    hdr->capacity         = m;
    hdr->key_size         = key_size;
    hdr->hash_buckets     = tk_buckets_for(m);
    hdr->used             = 0;
    hdr->seen             = 0;
    hdr->slots_off        = L.slots;
    hdr->total_size       = total;
    hdr->reader_slots_off = L.reader_slots;
    hdr->heap_off         = L.heap;
    hdr->bucket_off       = L.buckets;
    hdr->mode             = mode;
    hdr->alpha            = alpha;
    hdr->now              = 0.0;
    hdr->landmark         = 0.0;
    /* Publish magic LAST, as a release store: it is the commit point, so a
       creator killed before it leaves magic==0 and never a file mistaken for
       a valid one.  A kill during the field stores leaves one to remove by
       hand. */
    __atomic_store_n(&hdr->magic, TK_MAGIC, __ATOMIC_RELEASE);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* ---- accessors ---- */
static inline TkSlot *tk_slot(TkHandle *h, uint64_t i) {
    return (TkSlot *)((char *)h->base + h->slots_off + i * h->stride);
}
static inline char *tk_slot_key(TkSlot *s) { return (char *)s + sizeof(TkSlot); }
static inline uint32_t *tk_heap(TkHandle *h) {
    return (uint32_t *)((char *)h->base + h->heap_off);
}
static inline uint32_t *tk_buckets(TkHandle *h) {
    return (uint32_t *)((char *)h->base + h->bucket_off);
}

/* Layer B trusted bound: the number of slots guaranteed to lie within the real
 * mapping.  Derived from the process-local mmap_size (fixed at attach, not
 * peer-writable) and the SAME slots_off/stride the accessors use, so a corrupt
 * hdr->capacity can never drive a slot access outside the mapping.  Equals m
 * for a valid table; every clamp below it is a never-taken branch in normal use. */
static inline uint64_t tk_slots_max(TkHandle *h) {
    if (h->slots_off >= h->mmap_size || h->stride == 0) return 0;
    return (h->mmap_size - h->slots_off) / h->stride;
}

static inline TkHandle *tk_setup(void *base, size_t map_size,
                                 const char *path, int backing_fd) {
    TkHeader *hdr = (TkHeader *)base;
    TkHandle *h = (TkHandle *)calloc(1, sizeof(TkHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (TkReaderSlot *)((uint8_t *)base + sizeof(TkHeader));  /* trusted layout, not the peer-writable header offset */
    /* occ offset is invariant to capacity/key_size (reader_slots + a compile-time
     * constant), so this is a trusted layout offset independent of the header. */
    h->occ          = (uint64_t *)((uint8_t *)base + tk_layout_for(0, 0).occ);
    /* single validated read of each geometry field; cached so the process-local
       bound and the pointers it feeds stay consistent even if a peer later
       corrupts the shared header. */
    h->slots_off    = hdr->slots_off;
    h->heap_off     = hdr->heap_off;
    h->bucket_off   = hdr->bucket_off;
    h->capacity     = hdr->capacity;
    h->key_size     = hdr->key_size;
    h->hash_mask    = hdr->hash_buckets - 1;
    h->stride       = tk_stride(hdr->key_size);
    h->mode         = hdr->mode;
    h->alpha        = hdr->alpha;
    h->mmap_size    = map_size;
    /* Layer B: if the mapping cannot even hold `capacity` slots the header lied
       about its size; clamp the cached capacity to what actually fits.  (Uses
       h->mmap_size + h->slots_off + h->stride, all set just above.) */
    {
        uint64_t fit = tk_slots_max(h);
        if ((uint64_t)h->capacity > fit) h->capacity = (uint32_t)fit;
    }
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by tk_create reopen and tk_open_fd). */
static inline int tk_validate_header(const TkHeader *hdr, uint64_t file_size) {
    if (hdr->magic != TK_MAGIC) return 0;
    if (hdr->version != TK_VERSION) return 0;
    if (hdr->mode != TK_MODE_PLAIN && hdr->mode != TK_MODE_DECAYED) return 0;
    if (hdr->mode == TK_MODE_DECAYED && !(hdr->alpha > 0.0 && isfinite(hdr->alpha))) return 0;
    if (hdr->mode == TK_MODE_DECAYED && (!isfinite(hdr->now) || !isfinite(hdr->landmark))) return 0;
    if (hdr->capacity < TK_MIN_CAP || hdr->capacity > TK_MAX_CAP) return 0;
    if (hdr->key_size < TK_MIN_KEYSIZE || hdr->key_size > TK_MAX_KEYSIZE) return 0;
    if (hdr->hash_buckets != tk_buckets_for(hdr->capacity)) return 0;
    if (hdr->used > hdr->capacity) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != tk_total_size((uint32_t)hdr->capacity, hdr->key_size)) return 0;
    TkLayout L = tk_layout_for((uint32_t)hdr->capacity, hdr->key_size);
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->slots_off != L.slots) return 0;
    if (hdr->heap_off != L.heap) return 0;
    if (hdr->bucket_off != L.buckets) return 0;
    return 1;
}

/* validate the requested capacity + key_size */
static int tk_validate_args(uint64_t capacity, uint64_t key_size, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity < TK_MIN_CAP || capacity > TK_MAX_CAP) { TK_ERR("capacity must be between 1 and 2^24"); return 0; }
    if (key_size < TK_MIN_KEYSIZE || key_size > TK_MAX_KEYSIZE) { TK_ERR("key_size must be between 1 and 4096"); return 0; }
    return 1;
}

/* Securely obtain a fd for a path-backed segment: create it exclusively
 * (O_CREAT|O_EXCL|O_NOFOLLOW at `mode`, default 0600 = owner-only), or, if it
 * already exists, attach to it (O_RDWR|O_NOFOLLOW, no O_CREAT). O_EXCL blocks a
 * pre-seeded or hard-linked file and O_NOFOLLOW a symlink swap, so a local
 * attacker can no longer redirect or poison the backing store through the path.
 * Cross-user sharing is opt-in via a wider `mode` (e.g. 0660); the caller still
 * validates the file's contents via tk_validate_header. */
static int tk_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { TK_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        TK_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    TK_ERR("open %s: create/attach kept racing", path);
    return -1;
}

/* True iff the whole mapped region is zero -- what an abandoned mid-init
   creator leaves.  Lets recovery re-init only a provably-empty file, never
   one that merely starts with a zero word.  Cold path, so a byte scan is
   fine. */
static inline int tk_region_is_zero(const void *p, size_t n) {
    const unsigned char *b = (const unsigned char *)p;
    for (size_t i = 0; i < n; i++) if (b[i]) return 0;
    return 1;
}

static TkHandle *tk_create(const char *path, uint64_t capacity, uint64_t key_size, uint32_t tkmode, double alpha, mode_t mode, char *errbuf) {
    if (!tk_validate_args(capacity, key_size, errbuf)) return NULL;

    uint64_t total = tk_total_size((uint32_t)capacity, (uint32_t)key_size);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { TK_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = tk_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { TK_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { TK_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(TkHeader)) {
            TK_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            TK_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            TK_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { TK_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!tk_validate_header((TkHeader *)base, (uint64_t)st.st_size)) {
                /* Recover an abandoned mid-init file: a creator killed
                 * between the ftruncate and the header init leaves a
                 * full-size, all-zero (magic==0) file that would brick every
                 * future open of this path.  Re-initialize ONLY when it is
                 * exactly our size, still uninitialized, and owned by us;
                 * anything else still errors. */
                if (((TkHeader *)base)->magic == 0 && (uint64_t)st.st_size == total
                    && st.st_uid == geteuid() && tk_region_is_zero(base, map_size)) {
                    if (fchmod(fd, mode) < 0) {
                        TK_ERR("%s: fchmod: %s", path, strerror(errno));
                        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                    }
                    tk_init_header(base, (uint32_t)capacity, (uint32_t)key_size, tkmode, alpha, total);
                    flock(fd, LOCK_UN); close(fd);
                    return tk_setup(base, map_size, path, -1);
                }
                if (((TkHeader *)base)->magic == 0 && (uint64_t)st.st_size == total
                    && st.st_uid == geteuid()) {
                    TK_ERR("%s: incomplete top-k table file left by an interrupted create; remove it and retry", path);
                    munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                }
                TK_ERR("invalid top-k table file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return tk_setup(base, map_size, path, -1);
        }
    }
    tk_init_header(base, (uint32_t)capacity, (uint32_t)key_size, tkmode, alpha, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return tk_setup(base, map_size, path, -1);
}

static TkHandle *tk_create_memfd(const char *name, uint64_t capacity, uint64_t key_size, uint32_t tkmode, double alpha, char *errbuf) {
    if (!tk_validate_args(capacity, key_size, errbuf)) return NULL;

    uint64_t total = tk_total_size((uint32_t)capacity, (uint32_t)key_size);
    int fd = memfd_create(name ? name : "topk", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { TK_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        TK_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { TK_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    tk_init_header(base, (uint32_t)capacity, (uint32_t)key_size, tkmode, alpha, total);
    return tk_setup(base, (size_t)total, NULL, fd);
}

static TkHandle *tk_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { TK_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(TkHeader)) { TK_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { TK_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!tk_validate_header((TkHeader *)base, (uint64_t)st.st_size)) {
        TK_ERR("invalid top-k table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { TK_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return tk_setup(base, ms, NULL, myfd);
}

static void tk_destroy(TkHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&tk_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        if (h->occ) tk_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int tk_msync(TkHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Space-Saving operations (callers hold the lock)
 *
 * A fixed set of m counters monitors the heaviest keys.  Observing a key that
 * is already monitored bumps its count; observing a new key when a counter is
 * free fills it; observing a new key when full evicts the minimum-count counter,
 * inheriting its count as the new key's error bound.  A min-heap (over counts)
 * finds the eviction victim in O(log m); an intrusive hash index (chaining via
 * slot->hnext) tests membership in O(1).  Keys are compared by their first
 * key_size bytes (longer keys are truncated on the way in).
 * ================================================================ */

static inline uint64_t tk_hash(const void *key, size_t len) {
    return XXH3_64bits(key, len);
}

/* ---- forward-decay helpers (decayed mode stores a double's bits in count/error) ---- */
static inline double   tk_w_get(uint64_t bits) { double d;   memcpy(&d, &bits, sizeof d); return d; }
static inline uint64_t tk_w_bits(double d)     { uint64_t b; memcpy(&b, &d,   sizeof b); return b; }
/* forward-decay factor g(now) = exp(alpha*(now - landmark)); >= 1, == 1 just after a rescale */
static inline double tk_g(TkHandle *h) {
    return exp(h->alpha * (h->hdr->now - h->hdr->landmark));
}
/* mode-aware count comparisons for the min-heap */
static inline int tk_slot_lt(TkHandle *h, const TkSlot *a, const TkSlot *b) {
    if (h->mode == TK_MODE_DECAYED) return tk_w_get(a->count) < tk_w_get(b->count);
    return a->count < b->count;
}
static inline int tk_slot_le(TkHandle *h, const TkSlot *a, const TkSlot *b) {
    if (h->mode == TK_MODE_DECAYED) return tk_w_get(a->count) <= tk_w_get(b->count);
    return a->count <= b->count;
}

/* ---- min-heap over slot counts (heap[] holds slot indices) ---- */

static inline void tk_heap_swap(TkHandle *h, uint32_t *heap, uint64_t a, uint64_t b) {
    uint32_t sa = heap[a], sb = heap[b];
    heap[a] = sb; heap[b] = sa;
    if (TK_SLOT_OK(h, sa)) tk_slot(h, sa)->heap_pos = (uint32_t)b;
    if (TK_SLOT_OK(h, sb)) tk_slot(h, sb)->heap_pos = (uint32_t)a;
}

static void tk_sift_up(TkHandle *h, uint32_t *heap, uint64_t pos) {
    while (pos > 0) {
        uint64_t parent = (pos - 1) / 2;
        uint32_t sp = heap[parent], sc = heap[pos];
        if (!TK_SLOT_OK(h, sp) || !TK_SLOT_OK(h, sc)) break;      /* Layer B */
        if (tk_slot_le(h, tk_slot(h, sp), tk_slot(h, sc))) break;
        tk_heap_swap(h, heap, parent, pos);
        pos = parent;
    }
}

static void tk_sift_down(TkHandle *h, uint32_t *heap, uint64_t size, uint64_t pos) {
    for (;;) {
        uint64_t l = 2 * pos + 1, r = 2 * pos + 2, smallest = pos;
        if (l < size) {
            uint32_t sl = heap[l], ss = heap[smallest];
            if (TK_SLOT_OK(h, sl) && TK_SLOT_OK(h, ss) &&
                tk_slot_lt(h, tk_slot(h, sl), tk_slot(h, ss))) smallest = l;
        }
        if (r < size) {
            uint32_t sr = heap[r], ss = heap[smallest];
            if (TK_SLOT_OK(h, sr) && TK_SLOT_OK(h, ss) &&
                tk_slot_lt(h, tk_slot(h, sr), tk_slot(h, ss))) smallest = r;
        }
        if (smallest == pos) break;
        tk_heap_swap(h, heap, pos, smallest);
        pos = smallest;
    }
}

/* current heap size, clamped to the capacity (Layer B: hdr->used is peer-writable) */
static inline uint64_t tk_heap_size(TkHandle *h) {
    uint64_t used = h->hdr->used;
    return (used > h->capacity) ? h->capacity : used;
}

/* ---- intrusive hash index (chaining via slot->hnext) ---- */

/* find the slot monitoring `key` (klen already truncated), or TK_NIL */
static uint32_t tk_hash_find(TkHandle *h, const void *key, uint32_t klen, uint64_t hv) {
    uint32_t *buckets = tk_buckets(h);
    uint32_t s = buckets[hv & h->hash_mask];
    uint64_t guard = 0;
    while (s != TK_NIL && TK_SLOT_OK(h, s) && guard++ <= (uint64_t)h->capacity) {
        TkSlot *sl = tk_slot(h, s);
        uint32_t kl = sl->key_len; if (kl > h->key_size) kl = h->key_size;     /* Layer B */
        if (kl == klen && memcmp(tk_slot_key(sl), key, klen) == 0) return s;
        s = sl->hnext;
    }
    return TK_NIL;
}

/* prepend slot s (key already stored) to its hash chain */
static void tk_hash_insert(TkHandle *h, uint32_t s, uint64_t hv) {
    uint32_t *buckets = tk_buckets(h);
    uint64_t b = hv & h->hash_mask;
    tk_slot(h, s)->hnext = buckets[b];
    buckets[b] = s;
}

/* unlink slot s from its hash chain (hv = hash of its stored key) */
static void tk_hash_remove(TkHandle *h, uint32_t s, uint64_t hv) {
    uint32_t *buckets = tk_buckets(h);
    uint64_t b = hv & h->hash_mask;
    uint32_t cur = buckets[b];
    if (cur == s) { buckets[b] = tk_slot(h, s)->hnext; return; }
    uint64_t guard = 0;
    while (cur != TK_NIL && TK_SLOT_OK(h, cur) && guard++ <= (uint64_t)h->capacity) {
        TkSlot *c = tk_slot(h, cur);
        if (c->hnext == s) { c->hnext = tk_slot(h, s)->hnext; return; }
        cur = c->hnext;
    }
}

/* store (truncated) key bytes into slot s; returns the stored length */
static inline uint32_t tk_store_key(TkHandle *h, uint32_t s, const void *key, size_t len) {
    uint32_t klen = (len > h->key_size) ? h->key_size : (uint32_t)len;
    TkSlot *sl = tk_slot(h, s);
    memcpy(tk_slot_key(sl), key, klen);
    sl->key_len = klen;
    return klen;
}

/* Rescale all weights by 1/g and advance the landmark to now, keeping the
 * forward-decay weights bounded (decayed mode; caller holds the write lock). */
static void tk_rescale(TkHandle *h) {
    double g = tk_g(h);
    if (!(g > 1.0)) { h->hdr->landmark = h->hdr->now; return; }   /* g <= 1 or NaN: nothing to rescale */
    double inv = isfinite(g) ? 1.0 / g : 0.0;   /* g == +Inf: a huge time gap fully decayed all old weight -> 0 */
    uint64_t used = tk_heap_size(h);
    uint64_t smax = tk_slots_max(h);
    if (used > smax) used = smax;                     /* Layer B */
    for (uint64_t i = 0; i < used; i++) {
        TkSlot *sl = tk_slot(h, i);
        sl->count = tk_w_bits(tk_w_get(sl->count) * inv);
        sl->error = tk_w_bits(tk_w_get(sl->error) * inv);
    }
    h->hdr->landmark = h->hdr->now;                   /* g(now) == 1 again */
}

/* Observe one item; returns the item's estimated count after this observation.
 * (caller holds the write lock) */
static uint64_t tk_observe_locked(TkHandle *h, const void *item, size_t len, int has_ts, double ts) {
    if (h->capacity == 0) return 0;                        /* Layer B: unusable mapping */
    uint32_t klen = (len > h->key_size) ? h->key_size : (uint32_t)len;
    uint64_t hv = tk_hash(item, klen);
    h->hdr->seen++;

    double g = 1.0;                                        /* increment weight (1 in plain mode) */
    if (h->mode == TK_MODE_DECAYED) {
        /* advance the monotonic clock: to ts if given and larger, else one tick */
        if (has_ts) { if (ts > h->hdr->now) h->hdr->now = ts; }
        else h->hdr->now += 1.0;
        if (h->alpha * (h->hdr->now - h->hdr->landmark) > TK_RESCALE_LN)
            tk_rescale(h);                                 /* advance the landmark to keep g bounded */
        g = tk_g(h);
    }

    uint32_t s = tk_hash_find(h, item, klen, hv);
    uint32_t *heap = tk_heap(h);
    if (s != TK_NIL) {                                     /* already monitored: bump */
        TkSlot *sl = tk_slot(h, s);
        if (h->mode == TK_MODE_DECAYED) sl->count = tk_w_bits(tk_w_get(sl->count) + g);
        else                            sl->count++;
        uint64_t size = tk_heap_size(h);
        uint64_t pos = sl->heap_pos;
        if (pos < size) tk_sift_down(h, heap, size, pos); /* count rose -> sink it */
        return sl->count;
    }

    uint64_t used_now = h->hdr->used;                     /* Layer B: read the peer-writable count ONCE */
    if (used_now < h->capacity) {                         /* warm-up: fill a fresh slot */
        uint32_t ns = (uint32_t)used_now;                 /* index by the same value the guard validated */
        TkSlot *sl = tk_slot(h, ns);
        tk_store_key(h, ns, item, len);
        sl->count = (h->mode == TK_MODE_DECAYED) ? tk_w_bits(g)   : 1;
        sl->error = (h->mode == TK_MODE_DECAYED) ? tk_w_bits(0.0) : 0;
        sl->hnext = TK_NIL;
        sl->heap_pos = ns;
        heap[ns] = ns;
        tk_hash_insert(h, ns, hv);
        h->hdr->used++;
        tk_sift_up(h, heap, ns);
        return sl->count;
    }

    /* full: evict the minimum-count slot (heap root) */
    uint32_t victim = heap[0];
    if (!TK_SLOT_OK(h, victim)) return 0;                 /* Layer B: corrupt heap root */
    TkSlot *sl = tk_slot(h, victim);
    uint32_t old_kl = sl->key_len; if (old_kl > h->key_size) old_kl = h->key_size;
    uint64_t old_hv = tk_hash(tk_slot_key(sl), old_kl);
    tk_hash_remove(h, victim, old_hv);                    /* drop the evicted key */
    tk_store_key(h, victim, item, len);
    if (h->mode == TK_MODE_DECAYED) {
        double min_w = tk_w_get(sl->count);               /* victim's weight (heap minimum) */
        sl->error = tk_w_bits(min_w);                     /* over-estimate bound */
        sl->count = tk_w_bits(min_w + g);
    } else {
        uint64_t min_count = sl->count;
        sl->error = min_count;
        sl->count = min_count + 1;
    }
    tk_hash_insert(h, victim, hv);
    tk_sift_down(h, heap, h->capacity, 0);                /* root's count rose -> sink it */
    return sl->count;
}

/* estimated count of `item` (0 if not monitored); *err_out gets the over-estimate
 * bound if non-NULL.  (caller holds a lock) */
static uint64_t tk_estimate_locked(TkHandle *h, const void *item, size_t len, uint64_t *err_out) {
    uint32_t klen = (len > h->key_size) ? h->key_size : (uint32_t)len;
    uint64_t hv = tk_hash(item, klen);
    uint32_t s = tk_hash_find(h, item, klen, hv);
    if (s == TK_NIL) { if (err_out) *err_out = 0; return 0; }
    TkSlot *sl = tk_slot(h, s);
    if (err_out) *err_out = sl->error;
    return sl->count;
}

/* reset to an empty table (caller holds the write lock) */
static inline void tk_clear_locked(TkHandle *h) {
    h->hdr->used = 0;
    h->hdr->seen = 0;
    uint64_t nb = h->hash_mask + 1;
    memset(tk_buckets(h), 0xFF, (size_t)(nb * sizeof(uint32_t)));   /* all buckets -> TK_NIL */
}

#endif /* TK_H */
