/*
 * cms.h -- Shared-memory Count-Min sketch for Linux
 *
 * Approximate frequency estimation over a stream in fixed memory. Each item is
 * hashed once (XXH3-128); the two 64-bit halves drive one column per row
 * (d-row double hashing) into a d x w counter matrix (w a power of two). add
 * increments the d cells; estimate returns the minimum of the d cells, which
 * never underestimates the true count and overestimates by at most epsilon*total
 * with probability >= 1-delta. The matrix lives in a shared mapping so several
 * processes share one sketch; a write-preferring futex rwlock with reader-slot
 * dead-process recovery guards mutation. Two sketches of equal geometry can be
 * merged (cellwise add -> sum of streams).
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> counters[d * w]
 */

#ifndef CMS_H
#define CMS_H

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
#error "cms.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define CMS_MAGIC        0x534D4F43U  /* "COMS" (little-endian) */
#define CMS_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define CMS_ERR_BUFLEN   256
#ifndef CMS_READER_SLOTS
#define CMS_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these CMS_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all CMS_READER_SLOTS. */
#define CMS_OCC_WORDS   (((CMS_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define CMS_OCC_BYTES   ((uint64_t)CMS_OCC_WORDS * 8)      /* 128 bytes */
#define CMS_MIN_W        2            /* floor on the column count (power of two) */
#define CMS_MAX_W        0x100000000ULL /* 2^32 columns cap */
#define CMS_MIN_D        1
#define CMS_MAX_D        32

#define CMS_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, CMS_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

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
} CmsReaderSlot;

struct CmsHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t d;                       /* 8   rows (hash functions), in [1,32] */
    uint32_t _pad0;                   /* 12 */
    uint64_t w;                       /* 16  columns (power of two) */
    uint64_t mask;                    /* 24  w - 1 (column index mask) */
    uint64_t total;                   /* 32  sum of all increments (for stats) */
    uint64_t total_size;              /* 40 */
    uint64_t reader_slots_off;        /* 48 */
    uint64_t counters_off;            /* 56 */
    uint32_t wlock;                   /* 64  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 68  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 72  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 80 */
    uint8_t  _pad[168];               /* 88..255 */
};
typedef struct CmsHeader CmsHeader;

_Static_assert(sizeof(CmsHeader) == 256, "CmsHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct CmsHandle {
    CmsHeader     *hdr;
    CmsReaderSlot *reader_slots;  /* CMS_READER_SLOTS entries */
    uint64_t      *occ;           /* CMS_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void          *base;          /* mmap base */
    size_t         mmap_size;
    char          *path;          /* backing file path (strdup'd) */
    int            backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t       my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;    /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* cms_fork_gen value at last slot claim */
    uint32_t slotless_held; /* read-locks this process holds with no reader-slot */
} CmsHandle;

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

#define CMS_RWLOCK_SPIN_LIMIT 32
#define CMS_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void cms_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define CMS_RWLOCK_WRITER_BIT 0x80000000U
#define CMS_RWLOCK_PID_MASK   0x7FFFFFFFU
#define CMS_RWLOCK_WR(pid)    (CMS_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & CMS_RWLOCK_PID_MASK))

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
static inline int cms_pid_is_zombie(uint32_t pid) {
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
static inline int cms_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !cms_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void cms_recover_stale_lock(CmsHandle *h, uint32_t observed_wlock) {
    CmsHeader *hdr = h->hdr;
    uint32_t mypid = CMS_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec cms_lock_timeout = { CMS_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t cms_fork_gen = 1;
static pthread_once_t cms_atfork_once = PTHREAD_ONCE_INIT;
static void cms_on_fork_child(void) {
    __atomic_add_fetch(&cms_fork_gen, 1, __ATOMIC_RELAXED);
}
static void cms_atfork_init(void) {
    pthread_atfork(NULL, NULL, cms_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void cms_occ_set(CmsHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void cms_occ_clear(CmsHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

static inline void cms_claim_reader_slot(CmsHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&cms_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&cms_atfork_once, cms_atfork_init);
    /* Re-read after pthread_once: cms_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&cms_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % CMS_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < CMS_READER_SLOTS; i++) {
        uint32_t s = (start + i) % CMS_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            cms_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < CMS_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || cms_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            cms_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void cms_recover_after_timeout(CmsHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= CMS_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & CMS_RWLOCK_PID_MASK;
        if (!cms_pid_alive(pid))
            cms_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void cms_park(CmsHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void cms_unpark(CmsHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void cms_rdepth_inc(CmsHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void cms_rdepth_dec(CmsHandle *h) {
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
static inline void cms_reader_wake_drain(CmsHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void cms_rwlock_rdlock(CmsHandle *h) {
    cms_claim_reader_slot(h);
    CmsHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            cms_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            cms_rdepth_dec(h);
            cms_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= CMS_RWLOCK_WRITER_BIT &&
            !cms_pid_alive(cur & CMS_RWLOCK_PID_MASK)) {
            cms_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < CMS_RWLOCK_SPIN_LIMIT, 1)) {
            cms_rwlock_spin_pause();
            continue;
        }
        cms_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &cms_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                cms_unpark(h);
                cms_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        cms_unpark(h);
        spin = 0;
    }
}

static inline void cms_rwlock_rdunlock(CmsHandle *h) {
    cms_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    cms_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void cms_rwlock_wrlock(CmsHandle *h) {
    cms_claim_reader_slot(h);  /* refresh cached_pid across fork */
    CmsHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = CMS_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= CMS_RWLOCK_WRITER_BIT &&
            !cms_pid_alive(expected & CMS_RWLOCK_PID_MASK)) {
            cms_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < CMS_RWLOCK_SPIN_LIMIT, 1)) {
            cms_rwlock_spin_pause();
            continue;
        }
        cms_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &cms_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                cms_unpark(h);
                cms_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        cms_unpark(h);
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
         * this scan, so no held slot is skipped).  O(CMS_OCC_WORDS + live readers)
         * instead of O(CMS_READER_SLOTS). */
        for (uint32_t wd = 0; wd < CMS_OCC_WORDS; wd++) {
            uint64_t word = __atomic_load_n(&h->occ[wd], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (wd << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!cms_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &cms_lock_timeout, NULL, 0);
    }
}

static inline void cms_rwlock_wrunlock(CmsHandle *h) {
    CmsHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + create / open / destroy
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> counters[d * w]
 * ================================================================ */

/* Single source of truth for the mmap region layout offsets:
 * Header -> reader_slots[] -> occ bitmap -> counters. */
typedef struct { uint64_t reader_slots, occ, counters; } CmsLayout;

static inline CmsLayout cms_layout(void) {
    CmsLayout L;
    L.reader_slots = sizeof(CmsHeader);
    L.occ          = L.reader_slots + (uint64_t)CMS_READER_SLOTS * sizeof(CmsReaderSlot);
    L.counters     = L.occ + CMS_OCC_BYTES;
    L.counters     = (L.counters + 7) & ~(uint64_t)7;   /* 8-byte align the counter matrix (uint64_t words) */
    return L;
}

static inline uint64_t cms_total_size(uint64_t w, uint32_t d) {
    CmsLayout L = cms_layout();
    return L.counters + (uint64_t)d * w * sizeof(uint64_t);   /* d*w uint64_t cells */
}

/* round v up to the next power of two (64-bit), with a floor of CMS_MIN_W */
static inline uint64_t cms_next_pow2_u64(uint64_t v) {
    if (v <= CMS_MIN_W) return CMS_MIN_W;
    return 1ULL << (64 - __builtin_clzll(v - 1));
}

static inline void cms_init_header(void *base, uint64_t w, uint32_t d,
                                   uint64_t total_size) {
    CmsLayout L = cms_layout();
    CmsHeader *hdr = (CmsHeader *)base;
    /* Explicitly zero the header + reader-slot region (lock-recovery state);
       the counter matrix relies on the fresh mapping being OS zero-filled. */
    memset(base, 0, (size_t)L.counters);
    hdr->magic            = CMS_MAGIC;
    hdr->version          = CMS_VERSION;
    hdr->d                = d;
    hdr->w                = w;
    hdr->mask             = w - 1;
    hdr->total            = 0;
    hdr->total_size       = total_size;
    hdr->reader_slots_off = L.reader_slots;
    hdr->counters_off     = L.counters;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline uint64_t *cms_counters(CmsHandle *h) {
    return (uint64_t *)((char *)h->base + h->hdr->counters_off);
}

static inline CmsHandle *cms_setup(void *base, size_t map_size,
                                   const char *path, int backing_fd) {
    CmsHeader *hdr = (CmsHeader *)base;
    CmsHandle *h = (CmsHandle *)calloc(1, sizeof(CmsHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr          = hdr;
    h->base         = base;
    /* Derive reader_slots from the trusted fixed layout, not the stored
     * (shared-segment, attacker-mutable) reader_slots_off. validate_header
     * requires reader_slots_off to equal this for any file we open, so this is
     * identical for valid data and never trusts a poisoned offset. */
    h->reader_slots = (CmsReaderSlot *)((uint8_t *)base + cms_layout().reader_slots);
    h->occ          = (uint64_t *)((uint8_t *)base + cms_layout().occ);        /* trusted layout offset */
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by cms_create reopen and cms_open_fd). */
static inline int cms_validate_header(const CmsHeader *hdr, uint64_t file_size) {
    if (hdr->magic != CMS_MAGIC) return 0;
    if (hdr->version != CMS_VERSION) return 0;
    if (hdr->d < CMS_MIN_D || hdr->d > CMS_MAX_D) return 0;
    if (hdr->w < CMS_MIN_W || hdr->w > CMS_MAX_W) return 0;
    if ((hdr->w & (hdr->w - 1)) != 0) return 0;             /* power of two */
    if (hdr->mask != hdr->w - 1) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->total_size != cms_total_size(hdr->w, hdr->d)) return 0;
    CmsLayout L = cms_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->counters_off != L.counters) return 0;
    return 1;
}

/* validate args + compute the geometry (w, d).
 *   w = next_pow2(ceil(M_E / epsilon)), floor CMS_MIN_W, cap CMS_MAX_W
 *   d = ceil(log(1 / delta)) clamped to [1, 32] */
static int cms_validate_create_args(double epsilon, double delta,
                                    uint64_t *w_out, uint32_t *d_out, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (!(epsilon > 0.0 && epsilon < 1.0)) { CMS_ERR("epsilon must be between 0 and 1 (exclusive)"); return 0; }
    if (!(delta > 0.0 && delta < 1.0))     { CMS_ERR("delta must be between 0 and 1 (exclusive)"); return 0; }

    /* w = next_pow2(ceil(e / epsilon)), floor CMS_MIN_W. Reject (don't silently
       clamp) an epsilon so small the column count would exceed the cap, else the
       achieved error bound would be worse than requested (and the mapping huge). */
    double w_opt_d = ceil(M_E / epsilon);
    if (w_opt_d > (double)CMS_MAX_W) { CMS_ERR("epsilon too small for the column cap"); return 0; }
    uint64_t w = cms_next_pow2_u64((uint64_t)w_opt_d);

    /* d = ceil(log(1/delta)) clamped to [1, 32] */
    double d_d = ceil(log(1.0 / delta));
    long dl = (long)d_d;
    if (dl < CMS_MIN_D) dl = CMS_MIN_D;
    if (dl > CMS_MAX_D) dl = CMS_MAX_D;
    uint32_t d = (uint32_t)dl;

    *w_out = w;
    *d_out = d;
    return 1;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at mode,
 * default 0600), or attach an existing file (O_RDWR|O_NOFOLLOW, no O_CREAT). */
static int cms_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { CMS_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        CMS_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    CMS_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static CmsHandle *cms_create(const char *path, double epsilon, double delta, mode_t mode, char *errbuf) {
    uint64_t w;
    uint32_t d;
    if (!cms_validate_create_args(epsilon, delta, &w, &d, errbuf)) return NULL;

    uint64_t total = cms_total_size(w, d);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { CMS_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = cms_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { CMS_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { CMS_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(CmsHeader)) {
            CMS_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            CMS_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            CMS_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { CMS_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!cms_validate_header((CmsHeader *)base, (uint64_t)st.st_size)) {
                CMS_ERR("invalid Count-Min sketch file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return cms_setup(base, map_size, path, -1);
        }
    }
    cms_init_header(base, w, d, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return cms_setup(base, map_size, path, -1);
}

static CmsHandle *cms_create_memfd(const char *name, double epsilon, double delta, char *errbuf) {
    uint64_t w;
    uint32_t d;
    if (!cms_validate_create_args(epsilon, delta, &w, &d, errbuf)) return NULL;

    uint64_t total = cms_total_size(w, d);
    int fd = memfd_create(name ? name : "cms", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { CMS_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        CMS_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { CMS_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    cms_init_header(base, w, d, total);
    return cms_setup(base, (size_t)total, NULL, fd);
}

static CmsHandle *cms_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { CMS_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(CmsHeader)) { CMS_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { CMS_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!cms_validate_header((CmsHeader *)base, (uint64_t)st.st_size)) {
        CMS_ERR("invalid Count-Min sketch table"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { CMS_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return cms_setup(base, ms, NULL, myfd);
}

static void cms_destroy(CmsHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&cms_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        cms_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int cms_msync(CmsHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Count-Min sketch operations (callers hold the lock) -- d-row double
 * hashing: one XXH3-128 hash drives all d row probes.
 * Row r's column = (h1 + r*h2) & mask.
 * ================================================================ */

static inline void cms_indices(const void *item, size_t len,
                               uint64_t *h1, uint64_t *h2) {
    XXH128_hash_t hh = XXH3_128bits(item, len);
    *h1 = hh.low64;
    *h2 = hh.high64 | 1ULL;   /* force odd so the d row columns spread over the pow2 matrix */
}

/* add n to each of the d cells; bump total by n (caller holds the write lock) */
static void cms_add_locked(CmsHandle *h, const void *item, size_t len, uint64_t n) {
    uint64_t h1, h2;
    cms_indices(item, len, &h1, &h2);
    uint64_t w = h->hdr->w;
    uint64_t mask = h->hdr->mask;
    uint32_t d = h->hdr->d;
    /* w/mask/d/counters_off are read from the shared segment; a local peer with
     * write access to the backing file can corrupt them after we validated the
     * header at open. Snapshot the offset once and bound every derived cell
     * index against the process-local mmap_size (trusted) so a poisoned header
     * can never drive an out-of-bounds write. Never-taken for valid data. */
    uint64_t off = h->hdr->counters_off;
    uint64_t avail = (off <= h->mmap_size) ? (h->mmap_size - off) / sizeof(uint64_t) : 0;
    uint64_t *counters = (uint64_t *)((char *)h->base + off);
    for (uint32_t r = 0; r < d; r++) {
        uint64_t c = (h1 + (uint64_t)r * h2) & mask;
        uint64_t idx = (uint64_t)r * w + c;
        if (idx < avail) counters[idx] += n;
    }
    h->hdr->total += n;
}

/* return the minimum of the d cells -- the Count-Min estimate, which never
 * underestimates the true count (caller holds a lock) */
static uint64_t cms_estimate_locked(CmsHandle *h, const void *item, size_t len) {
    uint64_t h1, h2;
    cms_indices(item, len, &h1, &h2);
    uint64_t w = h->hdr->w;
    uint64_t mask = h->hdr->mask;
    uint32_t d = h->hdr->d;
    /* Same at-use bound as cms_add_locked: reject any poisoned-header index that
     * would fall outside the mapping instead of reading out of bounds. */
    uint64_t off = h->hdr->counters_off;
    uint64_t avail = (off <= h->mmap_size) ? (h->mmap_size - off) / sizeof(uint64_t) : 0;
    uint64_t *counters = (uint64_t *)((char *)h->base + off);
    uint64_t m = UINT64_MAX;
    for (uint32_t r = 0; r < d; r++) {
        uint64_t c = (h1 + (uint64_t)r * h2) & mask;
        uint64_t idx = (uint64_t)r * w + c;
        if (idx < avail) {
            uint64_t v = counters[idx];
            if (v < m) m = v;
        }
    }
    return m;
}

/* merge src cells into dst (caller guarantees equal w and d); cellwise add,
 * saturating at UINT64_MAX on overflow (caller holds dst's write lock) */
static void cms_merge_counters(uint64_t *dst, const uint64_t *src, uint64_t cells) {
    for (uint64_t i = 0; i < cells; i++) {
        if (dst[i] > UINT64_MAX - src[i]) dst[i] = UINT64_MAX;
        else dst[i] += src[i];
    }
}

/* reset all counters to 0 and total to 0 (caller holds the write lock) */
static inline void cms_clear_locked(CmsHandle *h) {
    /* d/w/counters_off are attacker-controlled shared-segment reads; clamp the
     * memset length to what the process-local mmap_size actually backs so a
     * poisoned geometry can never memset past the mapping. Equal for valid data. */
    uint64_t off = h->hdr->counters_off;
    uint64_t avail = (off <= h->mmap_size) ? (h->mmap_size - off) / sizeof(uint64_t) : 0;
    uint64_t cells = (uint64_t)h->hdr->d * h->hdr->w;
    if (cells > avail) cells = avail;
    memset((char *)h->base + off, 0, (size_t)(cells * sizeof(uint64_t)));
    h->hdr->total = 0;
}

#endif /* CMS_H */
