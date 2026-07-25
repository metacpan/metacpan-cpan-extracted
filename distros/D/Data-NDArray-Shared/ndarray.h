/*
 * ndarray.h -- Shared-memory typed dense N-dimensional numeric array for Linux
 *
 * Holds one contiguous, row-major numeric tensor of a fixed dtype (one of
 * f64/f32/i64/i32/i16/i8/u64/u32/u16/u8), a fixed shape (1..8 dimensions) and
 * the matching row-major strides, in a shared mapping so several processes
 * share one array. Element access is by multi-index or by flat index; the
 * whole array supports fill/zero, reshape (no copy), reductions (sum/min/max/
 * mean) and in-place scalar and element-wise array arithmetic. A
 * write-preferring futex rwlock with reader-slot dead-process recovery guards
 * mutation; immutable header fields (dtype/ndim/shape/strides/size/itemsize)
 * are read lock-free.
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> data[size * itemsize]
 */

#ifndef NDARRAY_H
#define NDARRAY_H

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
#include <sys/random.h>
#include <linux/futex.h>
#include <pthread.h>

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "ndarray.h: requires little-endian architecture"
#endif


/* ================================================================
 * Constants
 * ================================================================ */

#define NDA_MAGIC        0x4144444EU  /* "NDDA" (little-endian) */
#define NDA_VERSION      2   /* 2: added the occupancy bitmap region (layout change) */
#define NDA_ERR_BUFLEN   256
#define NDA_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */

/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these NDA_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all NDA_READER_SLOTS. */
#define NDA_OCC_WORDS   (((NDA_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define NDA_OCC_BYTES   ((uint64_t)NDA_OCC_WORDS * 8)      /* 128 bytes */
#define NDA_MAX_DIMS     8
#define NDA_MAX_BYTES    ((uint64_t)1 << 40)   /* 1 TiB cap on the data buffer */

#define NDA_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, NDA_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while (0)

/* ================================================================
 * dtypes
 * ================================================================ */

enum NdaDtype {
    NDA_F64, NDA_F32, NDA_I64, NDA_I32, NDA_I16,
    NDA_I8,  NDA_U64, NDA_U32, NDA_U16, NDA_U8,
    NDA_NTYPES
};

static const uint32_t nda_itemsize_tab[NDA_NTYPES] = { 8,4,8,4,2,1,8,4,2,1 };
static const char *const nda_name_tab[NDA_NTYPES]  =
    { "f64","f32","i64","i32","i16","i8","u64","u32","u16","u8" };

/* Classify a dtype.  Float = F64,F32; signed-int = I64..I8; rest unsigned. */
static inline int nda_is_float(uint32_t dt)  { return dt == NDA_F64 || dt == NDA_F32; }
static inline int nda_is_signed(uint32_t dt) { return dt == NDA_I64 || dt == NDA_I32 || dt == NDA_I16 || dt == NDA_I8; }

/* Parse a dtype name string -> enum, or -1 if unknown. */
static inline int nda_dtype_from_name(const char *s, size_t len) {
    for (int i = 0; i < NDA_NTYPES; i++)
        if (strlen(nda_name_tab[i]) == len && memcmp(nda_name_tab[i], s, len) == 0)
            return i;
    return -1;
}

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
} NdaReaderSlot;

struct NdaHeader {
    uint32_t magic, version;          /* 0,4 */
    uint32_t dtype;                   /* 8   enum NdaDtype */
    uint32_t ndim;                    /* 12  1..NDA_MAX_DIMS */

    /* ---- shape / strides (in ELEMENTS, row-major) ---- */
    uint64_t shape[NDA_MAX_DIMS];     /* 16  .. 79 */
    uint64_t strides[NDA_MAX_DIMS];   /* 80  .. 143 */
    uint64_t size;                    /* 144 product of shape = total elements */
    uint32_t itemsize;                /* 152 bytes per element */
    uint32_t _pad0;                   /* 156 */

    /* ---- offsets / sizes ---- */
    uint64_t total_size;              /* 160 */
    uint64_t reader_slots_off;        /* 168 */
    uint64_t data_off;                /* 176 */
    uint64_t array_id;                /* 184 stable identity for set-op lock ordering */

    /* ---- lock + stats ---- */
    uint32_t wlock;                   /* 192  WRITER word ONLY: 0 (free) or WRITER_BIT|pid.  NOT a reader count. */
    uint32_t rwait;                   /* 196  parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
    uint32_t drain_seq;               /* 200  futex bumped by a reader releasing under a draining writer (wakes it) */
    uint32_t slotless_rdepth;         /* 204  readers holding with no reader-slot (documented residual) */
    uint64_t stat_ops;                /* 208 */
    uint8_t  _pad[40];                /* 216..255 */
};
typedef struct NdaHeader NdaHeader;

_Static_assert(sizeof(struct NdaHeader) == 256, "NdaHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct NdaHandle {
    NdaHeader     *hdr;
    NdaReaderSlot *reader_slots;  /* NDA_READER_SLOTS entries */
    uint64_t      *occ;           /* NDA_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    void          *base;          /* mmap base */
    /* ---- immutable geometry cached at attach (Layer B: never re-read the
     * peer-writable header for a loop bound / byte extent / data base; a
     * lock-violating peer that corrupts hdr->{size,itemsize,data_off} after we
     * attached must not drive an OOB access) ---- */
    char          *data;          /* data base = trusted layout, NOT peer hdr->data_off */
    uint64_t       size;          /* total element count (immutable after create) */
    uint32_t       dtype;         /* enum NdaDtype (immutable after create); every element-width / element-type decision uses THIS, never peer hdr->dtype */
    uint32_t       itemsize;      /* bytes per element (immutable after create) */
    size_t         mmap_size;
    char          *path;          /* backing file path (strdup'd) */
    int            backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t       my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;    /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* nda_fork_gen value at last slot claim */
    uint32_t       slotless_held; /* read-locks this process holds with no reader-slot */
} NdaHandle;

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

#define NDA_RWLOCK_SPIN_LIMIT 32
#define NDA_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale-lock detection / drain re-scan */

static inline void nda_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define NDA_RWLOCK_WRITER_BIT 0x80000000U
#define NDA_RWLOCK_PID_MASK   0x7FFFFFFFU
#define NDA_RWLOCK_WR(pid)    (NDA_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & NDA_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Documented under "Crash Safety"
 * in the POD. */
/* A zombie (dead but not yet reaped) still answers kill(pid,0) as alive, so a
 * process that crashed while holding the lock and lingers unreaped would never
 * be recovered.  Treat /proc/<pid>/stat state 'Z' as dead.  Linux-only (as is
 * this module); if /proc is unreadable we fall back to "alive" (safe: we never
 * force-recover a possibly-live holder). */
static inline int nda_pid_is_zombie(uint32_t pid) {
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
static inline int nda_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !nda_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Force-recover a stale WRITE lock left by a dead writer (held or mid-drain).
 * CAS to OUR pid to hold the lock while fixing shared state, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent recovering
 * process can detect and re-recover if we crash mid-recovery. */
static inline void nda_recover_stale_lock(NdaHandle *h, uint32_t observed_wlock) {
    NdaHeader *hdr = h->hdr;
    uint32_t mypid = NDA_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec nda_lock_timeout = { NDA_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t nda_fork_gen = 1;
static pthread_once_t nda_atfork_once = PTHREAD_ONCE_INIT;
static void nda_on_fork_child(void) {
    __atomic_add_fetch(&nda_fork_gen, 1, __ATOMIC_RELAXED);
}
static void nda_atfork_init(void) {
    pthread_atfork(NULL, NULL, nda_on_fork_child);
}

/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void nda_occ_set(NdaHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void nda_occ_clear(NdaHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so that
 * fork()'d children pick up their own slot lazily instead of sharing the
 * parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
static inline void nda_claim_reader_slot(NdaHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&nda_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&nda_atfork_once, nda_atfork_init);
    /* Re-read after pthread_once: nda_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&nda_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % NDA_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < NDA_READER_SLOTS; i++) {
        uint32_t s = (start + i) % NDA_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            nda_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < NDA_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || nda_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            nda_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
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
static inline void nda_recover_after_timeout(NdaHandle *h) {
    uint32_t val = __atomic_load_n(&h->hdr->wlock, __ATOMIC_RELAXED);
    if (val >= NDA_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & NDA_RWLOCK_PID_MASK;
        if (!nda_pid_alive(pid))
            nda_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void nda_park(NdaHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void nda_unpark(NdaHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  leave() peels slotless first
 * so a slot claimed mid-hold cannot misattribute the decrement. */
static inline void nda_rdepth_inc(NdaHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void nda_rdepth_dec(NdaHandle *h) {
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
static inline void nda_reader_wake_drain(NdaHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void nda_rwlock_rdlock(NdaHandle *h) {
    nda_claim_reader_slot(h);
    NdaHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            nda_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            nda_rdepth_dec(h);
            nda_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= NDA_RWLOCK_WRITER_BIT &&
            !nda_pid_alive(cur & NDA_RWLOCK_PID_MASK)) {
            nda_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < NDA_RWLOCK_SPIN_LIMIT, 1)) {
            nda_rwlock_spin_pause();
            continue;
        }
        nda_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &nda_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                nda_unpark(h);
                nda_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        nda_unpark(h);
        spin = 0;
    }
}

static inline void nda_rwlock_rdunlock(NdaHandle *h) {
    nda_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    nda_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void nda_rwlock_wrlock(NdaHandle *h) {
    nda_claim_reader_slot(h);  /* refresh cached_pid across fork */
    NdaHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = NDA_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= NDA_RWLOCK_WRITER_BIT &&
            !nda_pid_alive(expected & NDA_RWLOCK_PID_MASK)) {
            nda_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < NDA_RWLOCK_SPIN_LIMIT, 1)) {
            nda_rwlock_spin_pause();
            continue;
        }
        nda_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &nda_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                nda_unpark(h);
                nda_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        nda_unpark(h);
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
         * this scan, so no held slot is skipped).  O(NDA_OCC_WORDS + live readers)
         * instead of O(NDA_READER_SLOTS). */
        for (uint32_t w = 0; w < NDA_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!nda_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &nda_lock_timeout, NULL, 0);
    }
}

static inline void nda_rwlock_wrunlock(NdaHandle *h) {
    NdaHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + data access
 *
 * Layout: Header -> reader_slots[1024] -> occ bitmap -> data[size * itemsize]
 * The reader-slot region is a multiple of 16 bytes, the occ bitmap is 128
 * bytes, and the header is 256 bytes, so data_off is 16-byte aligned (good for
 * any element width).
 * ================================================================ */

typedef struct { uint64_t reader_slots, occ, data; } NdaLayout;

static inline NdaLayout nda_layout(void) {
    NdaLayout L;
    L.reader_slots = sizeof(struct NdaHeader);
    L.occ          = L.reader_slots + (uint64_t)NDA_READER_SLOTS * sizeof(NdaReaderSlot);
    L.data         = L.occ + NDA_OCC_BYTES;
    return L;
}

static inline uint64_t nda_total_size(uint64_t data_bytes) {
    NdaLayout L = nda_layout();
    return L.data + data_bytes;
}

static inline char *nda_data(NdaHandle *h) {
    return h->data;   /* cached trusted layout base; never re-read peer hdr->data_off */
}

/* Flat element index for a multi-index (caller has bounds-checked each dim). */
static inline uint64_t nda_flat_offset(NdaHandle *h, const uint64_t *idx, uint32_t ndim) {
    const uint64_t *st = h->hdr->strides;
    uint64_t off = 0;
    for (uint32_t d = 0; d < ndim; d++) off += idx[d] * st[d];
    return off;
}

/* ================================================================
 * Typed element load (callers hold a lock).  Read element e as a double.
 * ================================================================ */

static inline double nda_load_nv(NdaHandle *h, uint64_t e) {
    char *base = nda_data(h);
    switch (h->dtype) {   /* cached: peer hdr->dtype must not resize the element */
        case NDA_F64: { double   v; memcpy(&v, base + e*8, 8); return v; }
        case NDA_F32: { float    v; memcpy(&v, base + e*4, 4); return (double)v; }
        case NDA_I64: { int64_t  v; memcpy(&v, base + e*8, 8); return (double)v; }
        case NDA_I32: { int32_t  v; memcpy(&v, base + e*4, 4); return (double)v; }
        case NDA_I16: { int16_t  v; memcpy(&v, base + e*2, 2); return (double)v; }
        case NDA_I8:  { int8_t   v; v = (int8_t)base[e];       return (double)v; }
        case NDA_U64: { uint64_t v; memcpy(&v, base + e*8, 8); return (double)v; }
        case NDA_U32: { uint32_t v; memcpy(&v, base + e*4, 4); return (double)v; }
        case NDA_U16: { uint16_t v; memcpy(&v, base + e*2, 2); return (double)v; }
        case NDA_U8:  { uint8_t  v; v = (uint8_t)base[e];      return (double)v; }
    }
    return 0.0;
}

/* Load element e of a SIGNED-int dtype widened to int64_t (caller holds a
 * lock; dtype must be one of I64/I32/I16/I8). */
static inline int64_t nda_load_i64(NdaHandle *h, uint64_t e) {
    char *base = nda_data(h);
    switch (h->dtype) {   /* cached: peer hdr->dtype must not resize the element */
        case NDA_I64: { int64_t v; memcpy(&v, base + e*8, 8); return v; }
        case NDA_I32: { int32_t v; memcpy(&v, base + e*4, 4); return (int64_t)v; }
        case NDA_I16: { int16_t v; memcpy(&v, base + e*2, 2); return (int64_t)v; }
        case NDA_I8:  { int8_t  v = (int8_t)base[e];          return (int64_t)v; }
        default: return 0;
    }
}

/* Load element e of an UNSIGNED-int dtype widened to uint64_t (caller holds a
 * lock; dtype must be one of U64/U32/U16/U8). */
static inline uint64_t nda_load_u64(NdaHandle *h, uint64_t e) {
    char *base = nda_data(h);
    switch (h->dtype) {   /* cached: peer hdr->dtype must not resize the element */
        case NDA_U64: { uint64_t v; memcpy(&v, base + e*8, 8); return v; }
        case NDA_U32: { uint32_t v; memcpy(&v, base + e*4, 4); return (uint64_t)v; }
        case NDA_U16: { uint16_t v; memcpy(&v, base + e*2, 2); return (uint64_t)v; }
        case NDA_U8:  { uint8_t  v = (uint8_t)base[e];          return (uint64_t)v; }
        default: return 0;
    }
}

/* Sum every element as a double (caller holds the read lock). */
static inline double nda_sum_locked(NdaHandle *h) {
    uint64_t size = h->size, e;   /* cached immutable count, not peer hdr->size */
    double acc = 0.0;
    for (e = 0; e < size; e++) acc += nda_load_nv(h, e);
    return acc;
}

/* Find the flat index of the min (want_max=0) or max (want_max=1) element,
 * comparing in the element's NATIVE type so that i64/u64 values above 2^53
 * (which collapse/mis-order as doubles) are ranked exactly.  Float dtypes
 * compare as double.  Caller holds the read lock; size >= 1 always. */
static inline uint64_t nda_argextreme_locked(NdaHandle *h, int want_max) {
    uint64_t size = h->size, e, best = 0;   /* cached immutable count, not peer hdr->size */
    uint32_t dt = h->dtype;   /* cached: peer hdr->dtype must not resize the element */
    if (nda_is_float(dt)) {
        double bestv = nda_load_nv(h, 0);
        for (e = 1; e < size; e++) {
            double v = nda_load_nv(h, e);
            if (want_max ? (v > bestv) : (v < bestv)) { bestv = v; best = e; }
        }
    } else if (nda_is_signed(dt)) {
        int64_t bestv = nda_load_i64(h, 0);
        for (e = 1; e < size; e++) {
            int64_t v = nda_load_i64(h, e);
            if (want_max ? (v > bestv) : (v < bestv)) { bestv = v; best = e; }
        }
    } else {
        uint64_t bestv = nda_load_u64(h, 0);
        for (e = 1; e < size; e++) {
            uint64_t v = nda_load_u64(h, e);
            if (want_max ? (v > bestv) : (v < bestv)) { bestv = v; best = e; }
        }
    }
    return best;
}

/* ================================================================
 * Validate create args + header init / setup / open / destroy
 * ================================================================ */

/* Generate a non-zero per-array identity, used ONLY at create time to order
 * element-wise set-op lock acquisition consistently across unrelated
 * processes.  Prefers getrandom(); on any failure/short read falls back to a
 * non-zero mix.  Never returns 0. */
static inline uint64_t nda_gen_array_id(const void *hdr_addr) {
    static uint32_t nda_id_counter = 0;
    uint64_t id = 0;
    ssize_t r = getrandom(&id, sizeof id, 0);
    if (r != (ssize_t)sizeof id) {
        uint32_t c = __atomic_add_fetch(&nda_id_counter, 1, __ATOMIC_RELAXED);
        id = ((uint64_t)(uint32_t)getpid() << 32)
           ^ ((uint64_t)c * 0x9E3779B97F4A7C15ull)
           ^ (uint64_t)(uintptr_t)hdr_addr;
    }
    if (id == 0) id = 0x9E3779B97F4A7C15ull;   /* never 0 */
    return id;
}

/* Validate create args + compute derived shape/strides/size/itemsize.
 * Single source of truth: the XS layer does NOT duplicate these checks.
 * On success fills *out_* and returns 1; on failure writes errbuf, returns 0. */
static int nda_validate_create_args(int dtype, const uint64_t *shape, uint32_t ndim,
                                    uint64_t *out_size, uint64_t out_strides[NDA_MAX_DIMS],
                                    uint64_t *out_data_bytes, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (dtype < 0 || dtype >= NDA_NTYPES) { NDA_ERR("unknown dtype"); return 0; }
    if (ndim < 1) { NDA_ERR("ndim must be >= 1"); return 0; }
    if (ndim > NDA_MAX_DIMS) { NDA_ERR("ndim must be <= %d", NDA_MAX_DIMS); return 0; }
    uint64_t size = 1;
    for (uint32_t d = 0; d < ndim; d++) {
        if (shape[d] < 1) { NDA_ERR("shape[%u] must be >= 1", d); return 0; }
        /* size *= shape[d] with overflow guard */
        if (shape[d] > UINT64_MAX / size) { NDA_ERR("shape too large"); return 0; }
        size *= shape[d];
    }
    uint32_t itemsize = nda_itemsize_tab[dtype];
    if (size > NDA_MAX_BYTES / itemsize) { NDA_ERR("shape too large"); return 0; }
    uint64_t data_bytes = size * itemsize;
    /* row-major strides */
    out_strides[ndim - 1] = 1;
    for (int d = (int)ndim - 2; d >= 0; d--)
        out_strides[d] = out_strides[d + 1] * shape[d + 1];
    *out_size = size;
    *out_data_bytes = data_bytes;
    return 1;
}

static inline void nda_init_header(void *base, int dtype, const uint64_t *shape,
                                   uint32_t ndim, uint64_t size,
                                   const uint64_t *strides,
                                   uint64_t total_size) {
    NdaLayout L = nda_layout();
    NdaHeader *hdr = (NdaHeader *)base;
    /* Zero the header + reader-slot region (lock-recovery state) and the data
       buffer (fresh array starts all-zero). */
    memset(base, 0, (size_t)total_size);
    hdr->magic            = NDA_MAGIC;
    hdr->version          = NDA_VERSION;
    hdr->dtype            = (uint32_t)dtype;
    hdr->ndim             = ndim;
    for (uint32_t d = 0; d < ndim; d++) { hdr->shape[d] = shape[d]; hdr->strides[d] = strides[d]; }
    hdr->size             = size;
    hdr->itemsize         = nda_itemsize_tab[dtype];
    hdr->total_size       = total_size;
    hdr->reader_slots_off = L.reader_slots;
    hdr->data_off         = L.data;
    hdr->array_id         = nda_gen_array_id(base);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static inline NdaHandle *nda_setup(void *base, size_t map_size,
                                   const char *path, int backing_fd) {
    NdaHeader *hdr = (NdaHeader *)base;
    NdaHandle *h = (NdaHandle *)calloc(1, sizeof(NdaHandle));
    if (!h) {
        munmap(base, map_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    NdaLayout L     = nda_layout();
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (NdaReaderSlot *)((uint8_t *)base + sizeof(NdaHeader));  /* trusted layout, not the peer-writable header offset */
    h->occ          = (uint64_t *)((uint8_t *)base + L.occ);   /* trusted layout offset */
    h->data         = (char *)base + L.data;   /* trusted layout, not the peer-writable hdr->data_off */
    h->size         = hdr->size;               /* cache immutable geometry (validated at attach) */
    /* Cache dtype too: a lock-violating peer that corrupts hdr->dtype after we
       attached must not change the per-element WIDTH (nb) while size/data stay
       fixed -> OOB.  Validate it in range exactly like the other cached
       geometry (every create/attach path has already validated it; clamp
       defensively so an out-of-range value can never index a typed table). */
    h->dtype        = (hdr->dtype < NDA_NTYPES) ? hdr->dtype : NDA_F64;
    h->itemsize     = hdr->itemsize;
    h->mmap_size    = map_size;
    h->path         = path ? strdup(path) : NULL;
    h->backing_fd   = backing_fd;
    h->my_slot_idx  = UINT32_MAX;
    return h;
}

/* Validate a mapped header (shared by reopen and open_fd).  Stored
 * dtype/shape/strides/size win on reopen; require self-consistency and the
 * file size to match. */
static inline int nda_validate_header(const NdaHeader *hdr, uint64_t file_size) {
    if (hdr->magic != NDA_MAGIC) return 0;
    if (hdr->version != NDA_VERSION) return 0;
    if (hdr->dtype >= NDA_NTYPES) return 0;
    if (hdr->ndim < 1 || hdr->ndim > NDA_MAX_DIMS) return 0;
    if (hdr->itemsize != nda_itemsize_tab[hdr->dtype]) return 0;
    uint64_t size = 1;
    for (uint32_t d = 0; d < hdr->ndim; d++) {
        if (hdr->shape[d] < 1) return 0;
        if (hdr->shape[d] > UINT64_MAX / size) return 0;
        size *= hdr->shape[d];
    }
    if (hdr->size != size) return 0;
    if (size > NDA_MAX_BYTES / hdr->itemsize) return 0;
    /* row-major stride check */
    uint64_t st = 1;
    for (int d = (int)hdr->ndim - 1; d >= 0; d--) {
        if (hdr->strides[d] != st) return 0;
        st *= hdr->shape[d];
    }
    uint64_t data_bytes = size * hdr->itemsize;
    NdaLayout L = nda_layout();
    if (hdr->reader_slots_off != L.reader_slots) return 0;
    if (hdr->data_off != L.data) return 0;
    if (hdr->total_size != L.data + data_bytes) return 0;
    if (hdr->total_size != file_size) return 0;
    return 1;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at mode,
 * default 0600), or attach an existing file (O_RDWR|O_NOFOLLOW, no O_CREAT). */
static int nda_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { NDA_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        NDA_ERR("open %s: %s", path, strerror(errno));  /* ELOOP => symlink rejected */
        return -1;
    }
    NDA_ERR("open %s: create/attach kept racing", path);
    return -1;
}

static NdaHandle *nda_create(const char *path, int dtype,
                             const uint64_t *shape, uint32_t ndim, mode_t mode, char *errbuf) {
    uint64_t size, strides[NDA_MAX_DIMS], data_bytes;
    if (!nda_validate_create_args(dtype, shape, ndim, &size, strides, &data_bytes, errbuf))
        return NULL;

    uint64_t total = nda_total_size(data_bytes);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { NDA_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = nda_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (flock(fd, LOCK_EX) < 0) { NDA_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat stt;
        if (fstat(fd, &stt) < 0) { NDA_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (stt.st_size == 0);
        if (!is_new && (uint64_t)stt.st_size < sizeof(struct NdaHeader)) {
            NDA_ERR("%s: file too small (%lld)", path, (long long)stt.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (stt.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            NDA_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            NDA_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)stt.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { NDA_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!nda_validate_header((NdaHeader *)base, (uint64_t)stt.st_size)) {
                NDA_ERR("invalid ndarray file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return nda_setup(base, map_size, path, -1);
        }
    }
    nda_init_header(base, dtype, shape, ndim, size, strides, total);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return nda_setup(base, map_size, path, -1);
}

static NdaHandle *nda_create_memfd(const char *name, int dtype,
                                   const uint64_t *shape, uint32_t ndim, char *errbuf) {
    uint64_t size, strides[NDA_MAX_DIMS], data_bytes;
    if (!nda_validate_create_args(dtype, shape, ndim, &size, strides, &data_bytes, errbuf))
        return NULL;

    uint64_t total = nda_total_size(data_bytes);
    int fd = memfd_create(name ? name : "ndarray", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { NDA_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) {
        NDA_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { NDA_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    nda_init_header(base, dtype, shape, ndim, size, strides, total);
    return nda_setup(base, (size_t)total, NULL, fd);
}

static NdaHandle *nda_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat stt;
    if (fstat(fd, &stt) < 0) { NDA_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)stt.st_size < sizeof(struct NdaHeader)) { NDA_ERR("too small"); return NULL; }
    size_t ms = (size_t)stt.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { NDA_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!nda_validate_header((NdaHeader *)base, (uint64_t)stt.st_size)) {
        NDA_ERR("invalid ndarray"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { NDA_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return nda_setup(base, ms, NULL, myfd);
}

static void nda_destroy(NdaHandle *h) {
    if (!h) return;
    /* Release our reader slot on clean teardown (else short-lived-reader churn
     * exhausts the slot table); skip if a read lock is still held (rdepth>0). */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&nda_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        nda_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->base) munmap(h->base, h->mmap_size);
    free(h->path);
    free(h);
}

static inline int nda_msync(NdaHandle *h) {
    if (!h || !h->base) return 0;
    return msync(h->base, h->mmap_size, MS_SYNC);
}

#endif /* NDARRAY_H */
