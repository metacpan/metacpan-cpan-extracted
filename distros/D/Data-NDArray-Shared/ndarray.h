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
 * Layout: Header -> reader_slots[1024] -> data[size * itemsize]
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
#define NDA_VERSION      1
#define NDA_ERR_BUFLEN   256
#define NDA_READER_SLOTS 1024         /* max concurrent reader processes for dead-process recovery */
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

/* Per-process slot for dead-process recovery.  Each shared rwlock counter
 * is mirrored here so a wrlock timeout can attribute and reverse a dead
 * process's contribution instead of waiting for the slow per-op timeout
 * drain. */
typedef struct {
    uint32_t pid;            /* 0 = unclaimed */
    uint32_t subcount;       /* in-flight rdlock acquisitions for this process */
    uint32_t waiters_parked; /* contribution to hdr->rwlock_waiters         */
    uint32_t writers_parked; /* contribution to hdr->rwlock_writers_waiting */
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
    uint32_t rwlock;                  /* 192 */
    uint32_t rwlock_waiters;          /* 196 */
    uint32_t rwlock_writers_waiting;  /* 200 */
    uint32_t _pad1;                   /* 204 */
    uint64_t stat_ops;                /* 208 */
    uint8_t  _pad[40];                /* 216..255 */
};
typedef struct NdaHeader NdaHeader;

_Static_assert(sizeof(struct NdaHeader) == 256, "NdaHeader must be 256 bytes");

/* ---- Process-local handle ---- */

typedef struct NdaHandle {
    NdaHeader     *hdr;
    NdaReaderSlot *reader_slots;  /* NDA_READER_SLOTS entries */
    void          *base;          /* mmap base */
    size_t         mmap_size;
    char          *path;          /* backing file path (strdup'd) */
    int            backing_fd;    /* memfd or reopened-fd to close on destroy, -1 for file/anon */
    uint32_t       my_slot_idx;   /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t       cached_pid;    /* getpid() cached at last slot claim */
    uint32_t       cached_fork_gen; /* nda_fork_gen value at last slot claim */
} NdaHandle;

/* ================================================================
 * Futex-based write-preferring read-write lock
 * with reader-slot dead-process recovery
 * ================================================================ */

#define NDA_RWLOCK_SPIN_LIMIT 32
#define NDA_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void nda_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define NDA_RWLOCK_WRITER_BIT 0x80000000U
#define NDA_RWLOCK_PID_MASK   0x7FFFFFFFU
#define NDA_RWLOCK_WR(pid)    (NDA_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & NDA_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Documented under "Crash Safety"
 * in the POD. */
static inline int nda_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing shared state, then release. */
static inline void nda_recover_stale_lock(NdaHandle *h, uint32_t observed_rwlock) {
    NdaHeader *hdr = h->hdr;
    uint32_t mypid = NDA_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  No additional shared state needs
     * repair here (this module has no seqlock); just release the lock. */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
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

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's. */
static inline void nda_claim_reader_slot(NdaHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&nda_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&nda_atfork_once, nda_atfork_init);
    cur_gen = __atomic_load_n(&nda_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % NDA_READER_SLOTS;
    for (uint32_t i = 0; i < NDA_READER_SLOTS; i++) {
        uint32_t s = (start + i) % NDA_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
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
static inline void nda_atomic_sub_cap(uint32_t *p, uint32_t sub) {
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
 * contributions back to the global counters. */
static inline void nda_drain_dead_slot(NdaHandle *h, uint32_t i, uint32_t pid) {
    NdaHeader *hdr = h->hdr;
    uint32_t expected = pid;
    if (!__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    uint32_t wp    = __atomic_load_n(&h->reader_slots[i].waiters_parked, __ATOMIC_RELAXED);
    uint32_t writp = __atomic_load_n(&h->reader_slots[i].writers_parked, __ATOMIC_RELAXED);
    if (wp)    nda_atomic_sub_cap(&hdr->rwlock_waiters, wp);
    if (writp) nda_atomic_sub_cap(&hdr->rwlock_writers_waiting, writp);
}

/* Scan reader slots for dead-process recovery. */
static inline void nda_recover_dead_readers(NdaHandle *h) {
    if (!h->reader_slots) return;
    NdaHeader *hdr = h->hdr;
    int any_live_reader = 0;
    int found_dead_reader = 0;

    for (uint32_t i = 0; i < NDA_READER_SLOTS; i++) {
        uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (pid == 0) continue;
        uint32_t sc = __atomic_load_n(&h->reader_slots[i].subcount, __ATOMIC_RELAXED);
        if (nda_pid_alive(pid)) {
            if (sc > 0) any_live_reader = 1;
            continue;
        }
        if (sc > 0) { found_dead_reader = 1; continue; }
        nda_drain_dead_slot(h, i, pid);
    }

    if (found_dead_reader && !any_live_reader) {
        uint32_t cur = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
        if (cur > 0 && cur < NDA_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(&hdr->rwlock, &cur, 0,
                    0, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
            }
        }
        for (uint32_t i = 0; i < NDA_READER_SLOTS; i++) {
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            if (pid == 0 || nda_pid_alive(pid)) continue;
            nda_drain_dead_slot(h, i, pid);
        }
    }
}

/* Inspect the lock word after a futex-wait timeout. */
static inline void nda_recover_after_timeout(NdaHandle *h) {
    NdaHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
    if (val >= NDA_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & NDA_RWLOCK_PID_MASK;
        if (!nda_pid_alive(pid))
            nda_recover_stale_lock(h, val);
    } else {
        nda_recover_dead_readers(h);
    }
}

/* Park/unpark helpers. */
static inline void nda_park_reader(NdaHandle *h) {
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
}
static inline void nda_unpark_reader(NdaHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
}
static inline void nda_park_writer(NdaHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
    __atomic_add_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
}
static inline void nda_unpark_writer(NdaHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwlock_waiters, 1, __ATOMIC_RELAXED);
    __atomic_sub_fetch(&h->hdr->rwlock_writers_waiting, 1, __ATOMIC_RELAXED);
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].waiters_parked, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].writers_parked, 1, __ATOMIC_RELAXED);
    }
}

static inline void nda_rwlock_rdlock(NdaHandle *h) {
    nda_claim_reader_slot(h);
    NdaHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur > 0 && cur < NDA_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < NDA_RWLOCK_SPIN_LIMIT, 1)) {
            nda_rwlock_spin_pause();
            continue;
        }
        nda_park_reader(h);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur >= NDA_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &nda_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                nda_unpark_reader(h);
                nda_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        nda_unpark_reader(h);
        spin = 0;
    }
}

static inline void nda_rwlock_rdunlock(NdaHandle *h) {
    NdaHeader *hdr = h->hdr;
    uint32_t after = __atomic_sub_fetch(&hdr->rwlock, 1, __ATOMIC_RELEASE);
    if (h->my_slot_idx != UINT32_MAX)
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].subcount, 1, __ATOMIC_RELAXED);
    if (after == 0 && __atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void nda_rwlock_wrlock(NdaHandle *h) {
    nda_claim_reader_slot(h);  /* refresh cached_pid across fork */
    NdaHeader *hdr = h->hdr;
    uint32_t *lock = &hdr->rwlock;
    uint32_t mypid = NDA_RWLOCK_WR(h->cached_pid);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < NDA_RWLOCK_SPIN_LIMIT, 1)) {
            nda_rwlock_spin_pause();
            continue;
        }
        nda_park_writer(h);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &nda_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                nda_unpark_writer(h);
                nda_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        nda_unpark_writer(h);
        spin = 0;
    }
}

static inline void nda_rwlock_wrunlock(NdaHandle *h) {
    NdaHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ================================================================
 * Layout math + data access
 *
 * Layout: Header -> reader_slots[1024] -> data[size * itemsize]
 * The reader-slot region is a multiple of 16 bytes, and the header is 256
 * bytes, so data_off is 16-byte aligned (good for any element width).
 * ================================================================ */

typedef struct { uint64_t reader_slots, data; } NdaLayout;

static inline NdaLayout nda_layout(void) {
    NdaLayout L;
    L.reader_slots = sizeof(struct NdaHeader);
    L.data         = L.reader_slots + (uint64_t)NDA_READER_SLOTS * sizeof(NdaReaderSlot);
    return L;
}

static inline uint64_t nda_total_size(uint64_t data_bytes) {
    NdaLayout L = nda_layout();
    return L.data + data_bytes;
}

static inline char *nda_data(NdaHandle *h) {
    return (char *)h->base + h->hdr->data_off;
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
    switch (h->hdr->dtype) {
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
    switch (h->hdr->dtype) {
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
    switch (h->hdr->dtype) {
        case NDA_U64: { uint64_t v; memcpy(&v, base + e*8, 8); return v; }
        case NDA_U32: { uint32_t v; memcpy(&v, base + e*4, 4); return (uint64_t)v; }
        case NDA_U16: { uint16_t v; memcpy(&v, base + e*2, 2); return (uint64_t)v; }
        case NDA_U8:  { uint8_t  v = (uint8_t)base[e];          return (uint64_t)v; }
        default: return 0;
    }
}

/* Sum every element as a double (caller holds the read lock). */
static inline double nda_sum_locked(NdaHandle *h) {
    uint64_t size = h->hdr->size, e;
    double acc = 0.0;
    for (e = 0; e < size; e++) acc += nda_load_nv(h, e);
    return acc;
}

/* Find the flat index of the min (want_max=0) or max (want_max=1) element,
 * comparing in the element's NATIVE type so that i64/u64 values above 2^53
 * (which collapse/mis-order as doubles) are ranked exactly.  Float dtypes
 * compare as double.  Caller holds the read lock; size >= 1 always. */
static inline uint64_t nda_argextreme_locked(NdaHandle *h, int want_max) {
    uint64_t size = h->hdr->size, e, best = 0;
    uint32_t dt = h->hdr->dtype;
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
    h->hdr          = hdr;
    h->base         = base;
    h->reader_slots = (NdaReaderSlot *)((uint8_t *)base + hdr->reader_slots_off);
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

static NdaHandle *nda_create(const char *path, int dtype,
                             const uint64_t *shape, uint32_t ndim, char *errbuf) {
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
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { NDA_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { NDA_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat stt;
        if (fstat(fd, &stt) < 0) { NDA_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (stt.st_size == 0);
        if (!is_new && (uint64_t)stt.st_size < sizeof(struct NdaHeader)) {
            NDA_ERR("%s: file too small (%lld)", path, (long long)stt.st_size);
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
