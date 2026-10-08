/*
 * shm_generic.h -- macro template for shared-memory hash maps.  Define first:
 *   SHM_PREFIX, SHM_NODE_TYPE, SHM_VARIANT_ID (unique, checked in the header)
 *   SHM_KEY_IS_INT + SHM_KEY_INT_TYPE, or neither for string keys
 *   SHM_VAL_IS_STR, or SHM_VAL_INT_TYPE
 *   SHM_HAS_COUNTERS (optional, integer values): incr/decr, max/min, cas
 */

/* ---- Part 1: shared definitions (included once) ---- */

#ifndef SHM_DEFS_H
#define SHM_DEFS_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sys/mman.h>
#include <sys/stat.h>

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#error "shm_generic.h: inline string packing requires little-endian architecture"
#endif
#include <sys/file.h>
#include <pthread.h>
#include <sys/syscall.h>
#include <limits.h>
#include <signal.h>
#include <errno.h>
/* Optional (minimal containers lack it): both values used are kernel ABI. */
#ifdef SHM_HAVE_LINUX_FUTEX_H
#include <linux/futex.h>
#endif
#ifndef FUTEX_WAIT
#define FUTEX_WAIT 0
#endif
#ifndef FUTEX_WAKE
#define FUTEX_WAKE 1
#endif

/* glibc < 2.27 lacks memfd_create and the sealing constants; values are kernel ABI. */
#ifndef MFD_CLOEXEC
#define MFD_CLOEXEC        0x0001U
#endif
#ifndef MFD_ALLOW_SEALING
#define MFD_ALLOW_SEALING  0x0002U
#endif
#ifndef F_ADD_SEALS
#define F_ADD_SEALS  1033   /* F_LINUX_SPECIFIC_BASE + 9 */
#endif
#ifndef F_SEAL_SHRINK
#define F_SEAL_SHRINK 0x0002
#endif
#ifndef F_SEAL_GROW
#define F_SEAL_GROW   0x0004
#endif
#if defined(__GLIBC__) && defined(__GLIBC_PREREQ)
#  if !__GLIBC_PREREQ(2, 27)
#    define SHM_MEMFD_VIA_SYSCALL 1
#  endif
#endif
#ifdef SHM_MEMFD_VIA_SYSCALL
#  ifndef SYS_memfd_create
#    error "memfd_create is unavailable: glibc < 2.27 and no SYS_memfd_create"
#  endif
#  define shm_memfd_create(name, flags) ((int)syscall(SYS_memfd_create, (name), (flags)))
#else
#  define shm_memfd_create(name, flags) memfd_create((name), (flags))
#endif

#ifdef __SSE2__
#include <emmintrin.h>
#endif

#define XXH_INLINE_ALL
#include "xxhash.h"

#define SHM_MAGIC       0x53484D31U  /* "SHM1" */
#define SHM_VERSION     10U
/* new_sharded's ceiling: the power-of-two round-up must not overflow. */
#define SHM_MAX_SHARDS  4096U

#ifndef SHM_READER_SLOTS
#define SHM_READER_SLOTS 1024  /* max concurrent reader processes for dead-process recovery */
#endif
/* Reader-slot occupancy bitmap: a bit is set on claim, cleared on clean release. */
#define SHM_OCC_WORDS   (((SHM_READER_SLOTS) + 63) / 64)
#define SHM_OCC_BYTES   ((uint64_t)SHM_OCC_WORDS * 8)
#define SHM_INITIAL_CAP 16
#define SHM_MAX_STR_LEN 0x3FFFFFFFU  /* ~1GB, bit 30 reserved for inline flag */
#define SHM_LRU_NONE    UINT32_MAX

/* UINT32_MAX = use default TTL; 0 = no TTL; other = per-key TTL */
#define SHM_TTL_USE_DEFAULT UINT32_MAX

/* Hash half that picks the shard; fixed per set, or keys would change shards. */
#define SHM_ROUTING_LEGACY 0  /* low half, the half the in-shard probe uses */
#define SHM_ROUTING_SPLIT  1  /* high half, which the slot index ignores */

#define SHM_IS_EXPIRED(h, i, now) \
    ((h)->expires_at && (h)->expires_at[(i)] && \
     (now) >= (h)->expires_at[(i)])

static inline uint32_t shm_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_COARSE, &ts);
    return (uint32_t)ts.tv_sec;
}

static inline uint32_t shm_expiry_ts(uint32_t ttl) {
    uint64_t sum = (uint64_t)shm_now() + ttl;
    return (sum > UINT32_MAX) ? UINT32_MAX : (uint32_t)sum;
}

#define SHM_EMPTY     0
#define SHM_TOMBSTONE 1
#define SHM_TAG_MIN   2   /* state values 2-255 = LIVE with hash tag */
#define SHM_IS_LIVE(st) ((st) >= SHM_TAG_MIN)
/* During PLACE (CLEAN left no tombstones): a live entry not yet re-placed. */
#define SHM_MOVE      SHM_TOMBSTONE

/* rz_phase, each restartable.  CLEAN empties tombstones, MARK turns every live
 * entry into SHM_MOVE, PLACE re-inserts them; CLEAR is a clear() under way. */
#define SHM_RZ_NONE   0
#define SHM_RZ_CLEAN  1
#define SHM_RZ_MARK   2
#define SHM_RZ_PLACE  3
#define SHM_RZ_CLEAR  4

/* PLACE on a string-key table of at least SHM_RZ_PREFETCH_MIN slots prefetches
 * the arena key of the entry this far ahead. */
#define SHM_RZ_PREFETCH_AHEAD 24
#define SHM_RZ_PREFETCH_MIN   (1u << 16)

static inline int shm_rz_cap_ok(uint32_t cap, uint32_t max_mask) {
    return cap && (cap & (cap - 1)) == 0 && cap - 1 <= max_mask;
}

static inline uint32_t shm_count_live(const uint8_t *states, uint32_t cap) {
    uint32_t live = 0, i = 0;
#ifdef __SSE2__
    const __m128i one = _mm_set1_epi8(1), tag_min = _mm_set1_epi8(SHM_TAG_MIN);
    __m128i sum = _mm_setzero_si128();
    for (; i + 16 <= cap; i += 16) {
        __m128i c = _mm_loadu_si128((const __m128i *)(states + i));
        __m128i is_live = _mm_cmpeq_epi8(_mm_min_epu8(c, tag_min), tag_min);
        sum = _mm_add_epi64(sum, _mm_sad_epu8(_mm_and_si128(is_live, one), _mm_setzero_si128()));
    }
    live = (uint32_t)_mm_cvtsi128_si32(sum) + (uint32_t)_mm_cvtsi128_si32(_mm_srli_si128(sum, 8));
#endif
    for (; i < cap; i++) live += SHM_IS_LIVE(states[i]);
    return live;
}

static inline void shm_states_clean(uint8_t *states, uint32_t cap) {
    uint32_t i = 0;
#ifdef __SSE2__
    const __m128i tomb = _mm_set1_epi8(SHM_TOMBSTONE);
    for (; i + 16 <= cap; i += 16) {
        __m128i c = _mm_loadu_si128((const __m128i *)(states + i));
        _mm_storeu_si128((__m128i *)(states + i), _mm_andnot_si128(_mm_cmpeq_epi8(c, tomb), c));
    }
#endif
    for (; i < cap; i++) states[i] = states[i] == SHM_TOMBSTONE ? SHM_EMPTY : states[i];
}

static inline void shm_states_mark(uint8_t *states, uint32_t cap) {
    uint32_t i = 0;
#ifdef __SSE2__
    const __m128i move = _mm_set1_epi8(SHM_MOVE);
    for (; i + 16 <= cap; i += 16) {
        __m128i c = _mm_loadu_si128((const __m128i *)(states + i));
        _mm_storeu_si128((__m128i *)(states + i),
                         _mm_andnot_si128(_mm_cmpeq_epi8(c, _mm_setzero_si128()), move));
    }
#endif
    for (; i < cap; i++) states[i] = states[i] == SHM_EMPTY ? SHM_EMPTY : SHM_MOVE;
}

#define SHM_MAKE_TAG(hash) ((uint8_t)(((hash) >> 24) % 254 + SHM_TAG_MIN))
/* Tag-based probe filtering needs TOMBSTONE < TAG_MIN. */
typedef char shm_tag_invariant_check[(SHM_TOMBSTONE < SHM_TAG_MIN) ? 1 : -1];

static inline int shm_find_next_live(const uint8_t *states, uint32_t cap, uint32_t *pos) {
    uint32_t i = *pos;
#ifdef __SSE2__
    __m128i ones = _mm_set1_epi8(1);
    uint32_t align_end = (i + 15) & ~(uint32_t)15;
    if (align_end > cap) align_end = cap;
    for (; i < align_end; i++) {
        if (states[i] >= SHM_TAG_MIN) { *pos = i; return 1; }
    }
    /* saturating byte - 1 is nonzero iff byte >= SHM_TAG_MIN */
    for (; i + 16 <= cap; i += 16) {
        __m128i chunk = _mm_loadu_si128((const __m128i *)(states + i));
        __m128i sub = _mm_subs_epu8(chunk, ones);
        int mask = _mm_movemask_epi8(_mm_cmpeq_epi8(sub, _mm_setzero_si128()));
        mask = ~mask & 0xFFFF;
        if (mask) { *pos = i + __builtin_ctz(mask); return 1; }
    }
#endif
    for (; i < cap; i++) {
        if (states[i] >= SHM_TAG_MIN) { *pos = i; return 1; }
    }
    return 0;
}

/* 16 contiguous state bytes: the caller handles table wrap. */
#ifdef __SSE2__
static inline void shm_probe_group(const uint8_t *states, uint32_t pos,
                                    uint8_t tag, uint16_t *match_mask,
                                    uint16_t *empty_mask) {
    __m128i group = _mm_loadu_si128((const __m128i *)(states + pos));
    __m128i tag_v = _mm_set1_epi8((char)tag);
    __m128i zero_v = _mm_setzero_si128();
    *match_mask = (uint16_t)_mm_movemask_epi8(_mm_cmpeq_epi8(group, tag_v));
    *empty_mask = (uint16_t)_mm_movemask_epi8(_mm_cmpeq_epi8(group, zero_v));
}
#endif

#define SHM_ARENA_NUM_CLASSES 16  /* 2^4..2^19 = 16..524288 */
#define SHM_EVICT_SEARCH 32       /* oldest entries searched for a block of the request's class */
#define SHM_LRU_SPARE_MAX 64      /* second chances one eviction grants before it takes an entry anyway */
#define SHM_ARENA_MIN_ALLOC   16
/* A free-list walk longer than this is following a corrupted cycle. */
#define SHM_ARENA_FREELIST_MAX(cap) ((uint32_t)((cap) / SHM_ARENA_MIN_ALLOC) + 1)

/* ---- UTF-8 and inline-string flag packing ----
 * key_len / val_len (uint32_t): bit 31 = UTF-8, bit 30 = inline, bits 0-29 =
 * length.  Inline: _off plus bits 0-23 of _len hold up to 7 bytes of data,
 * bits 24-26 its length.  Arena: _off is the offset, bits 0-29 the length. */

#define SHM_UTF8_FLAG    ((uint32_t)0x80000000U)
#define SHM_INLINE_FLAG  ((uint32_t)0x40000000U)
#define SHM_LEN_MASK     ((uint32_t)0x3FFFFFFFU)
#define SHM_INLINE_MAX   7

#define SHM_PACK_LEN(len, utf8)   ((uint32_t)(len) | ((utf8) ? SHM_UTF8_FLAG : 0))
#define SHM_UNPACK_LEN(packed)    ((uint32_t)((packed) & SHM_LEN_MASK))
#define SHM_UNPACK_UTF8(packed)   (((packed) & SHM_UTF8_FLAG) != 0)
#define SHM_IS_INLINE(packed)     (((packed) & SHM_INLINE_FLAG) != 0)

#define SHM_STR_LEN(packed) \
    (SHM_IS_INLINE(packed) ? shm_inline_len(packed) : SHM_UNPACK_LEN(packed))

static inline void shm_inline_pack(uint32_t *off, uint32_t *len_field,
                                    const char *str, uint32_t slen, bool utf8) {
    uint32_t lf = SHM_INLINE_FLAG | ((uint32_t)slen << 24);
    if (utf8) lf |= SHM_UTF8_FLAG;
    uint32_t o = 0;
    memcpy(&o, str, slen > 4 ? 4 : slen);
    if (slen > 4) {
        uint32_t rest = 0;
        memcpy(&rest, str + 4, slen - 4);
        lf |= rest;
    }
    /* Pass through the inline-empty state, which shm_str_free ignores, so a killed
     * writer leaves no (off,len) to misfree.  Atomic so the interim store stays. */
    __atomic_store_n(len_field, SHM_INLINE_FLAG, __ATOMIC_RELEASE);
    __atomic_store_n(off, o, __ATOMIC_RELEASE);
    __atomic_store_n(len_field, lf, __ATOMIC_RELEASE);
}

static inline uint32_t shm_inline_len(uint32_t len_field) {
    return (len_field >> 24) & 0x7;
}

static inline const char *shm_inline_read(uint32_t off, uint32_t len_field,
                                           char *buf) {
    uint32_t slen = shm_inline_len(len_field);
    memcpy(buf, &off, slen > 4 ? 4 : slen);
    if (slen > 4) {
        uint32_t rest = len_field & 0x00FFFFFFU;
        memcpy(buf + 4, &rest, slen - 4);
    }
    return buf;
}

static inline const char *shm_str_ptr(uint32_t off, uint32_t len_field,
                                       const char *arena, uint64_t arena_cap,
                                       char *inline_buf,
                                       uint32_t *out_len) {
    if (SHM_IS_INLINE(len_field)) {
        *out_len = shm_inline_len(len_field);
        return shm_inline_read(off, len_field, inline_buf);
    }
    uint32_t len = SHM_UNPACK_LEN(len_field);
    if (off < SHM_ARENA_MIN_ALLOC || (uint64_t)off + len > arena_cap) {
        /* off/len are peer-writable: never return an out-of-bounds pointer. */
        *out_len = 0;
        return inline_buf;
    }
    *out_len = len;
    return arena + off;
}

/* ---- Shared memory header (256 bytes, 4 cache lines, in mmap) ---- */

/* No trailing semicolon: the call site adds one; a stray one is invalid C89. */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#define SHM_STATIC_ASSERT(cond, msg) _Static_assert(cond, msg)
#else
#define SHM_SA_JOIN2(a, b) a##b
#define SHM_SA_JOIN(a, b)  SHM_SA_JOIN2(a, b)
#define SHM_STATIC_ASSERT(cond, msg) \
    typedef char SHM_SA_JOIN(shm_static_assert_, __LINE__)[(cond) ? 1 : -1]
#endif

typedef struct {
    /* ---- Cache line 0 (0-63): immutable after create ---- */
    uint32_t magic;           /* 0 */
    uint32_t version;         /* 4 */
    uint32_t variant_id;      /* 8 */
    uint32_t node_size;       /* 12 */
    uint32_t max_table_cap;   /* 16 */
    uint32_t table_cap;       /* 20: changes on resize only */
    uint32_t max_size;        /* 24: LRU capacity, 0 = disabled */
    uint32_t default_ttl;     /* 28: TTL seconds, 0 = disabled */
    uint64_t total_size;      /* 32 */
    uint64_t nodes_off;       /* 40 */
    uint64_t states_off;      /* 48 */
    uint64_t arena_off;       /* 56 */

    /* ---- Cache line 1 (64-127): seqlock + read-path data ---- */
    uint32_t seq;             /* 64: seqlock counter, odd = writer active */
    uint32_t drain_seq;       /* 68: futex a releasing reader bumps to wake a draining writer */
    uint64_t arena_cap;       /* 72: immutable */
    uint64_t reader_slots_off;/* 80 */
    uint32_t slotless_rdepth; /* 88: read-locks held by readers with no reader-slot */
    uint32_t arena_large_free;/* 92: head of the >2^19 large-block free list (0 = empty) */
    /* 96-127 were carved from the pad: a file written before them reads 0. */
    uint8_t  sealed;          /* 96: 1 = frozen (read-only; lock-free reads) */
    uint8_t  routing;         /* 97: SHM_ROUTING_* */
    uint8_t  shard_log2;      /* 98: log2(shards)+1 once a set's creator stamped it, else 0 */
    uint8_t  rz_phase;        /* 99: SHM_RZ_*, a resize in progress */
    uint32_t pop_cursor;      /* 100: next slot a non-LRU pop or drain examines (wraps) */
    uint32_t shift_cursor;    /* 104: the slot above the next one a non-LRU shift examines,
                                 0 meaning the top of the table */
    /* The resize record, meaningful while rz_phase is set. */
    uint8_t  rz_old_log2;     /* 108 */
    uint8_t  rz_new_log2;     /* 109 */
    uint16_t rz_rsv;          /* 110 */
    uint64_t rz_move;         /* 112: the move in flight, src | dst << 32 */
    uint32_t rz_cursor;       /* 120: no slot below it holds an entry still to move */
    uint32_t rz_seq;          /* 124: the odd seq of the write section that recorded it */

    /* ---- Cache line 2 (128-191): rwlock + write-hot fields ---- */
    uint32_t wlock;           /* 128: 0 or SHM_RWLOCK_WR(pid); readers count in their slots */
    uint32_t rwait;           /* 132: waiters parked on wlock; may over-count */
    uint32_t size;            /* 136 */
    uint32_t tombstones;      /* 140 */
    uint32_t lru_head;        /* 144: MRU slot index */
    uint32_t lru_tail;        /* 148: LRU slot index */
    uint32_t flush_cursor;    /* 152: partial flush_expired scan cursor */
    uint32_t table_gen;       /* 156: incremented on every resize */
    uint64_t arena_bump;      /* 160 */
    uint64_t stat_evictions;  /* 168 */
    uint64_t stat_expired;    /* 176 */
    uint32_t stat_recoveries; /* 184 */
    uint32_t lru_skip;        /* 188: promotion skip mask (power-of-2 minus 1, 0=strict LRU) */

    /* ---- Cache line 3 (192-255): arena free lists ---- */
    uint32_t arena_free[SHM_ARENA_NUM_CLASSES]; /* 192-255 */
} ShmHeader;

SHM_STATIC_ASSERT(sizeof(ShmHeader) == 256, "ShmHeader must be exactly 256 bytes (4 cache lines)");
/* shm_create_sharded CASes shard_log2 across processes; libatomic's fallback
 * lock is per process.  C11 only: GCC before 5 cannot fold this builtin. */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
SHM_STATIC_ASSERT(__atomic_always_lock_free(sizeof(((ShmHeader *)0)->shard_log2), 0),
                  "cross-process CAS on shard_log2 needs a lock-free byte atomic");
#endif

/* A reader's whole share of the lock is its slot's rdepth, so clearing a dead
 * reader's pid releases it.  _rsv* keep the on-disk 16-byte slot size. */
typedef struct {
    uint32_t pid;      /* 0 = unclaimed */
    uint32_t rdepth;   /* read-locks this process holds */
    uint32_t _rsv1;
    uint32_t _rsv2;
} ShmReaderSlot;

/* Consecutive pids start their slot search a cache line apart. */
#define SHM_READER_SLOT_STRIDE (64 / sizeof(ShmReaderSlot))

typedef struct ShmHandle_s {
    ShmHeader *hdr;
    void      *nodes;
    uint8_t   *states;
    char      *arena;
    uint32_t  *lru_prev;
    uint32_t  *lru_next;
    uint8_t   *lru_accessed; /* clock second-chance bits */
    uint32_t  *expires_at;
    ShmReaderSlot *reader_slots;
    uint64_t  *occ;
    uint32_t   my_slot_idx;  /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t   cached_pid;   /* getpid() cached at last slot claim */
    uint32_t   cached_fork_gen; /* shm_fork_gen at last slot claim; a mismatch reclaims */
    uint32_t slotless_held; /* rwlock read-locks held with no reader-slot */
    uint32_t occ_sweep_in;  /* write locks left before the next occupancy sweep */
    uint32_t slotless_retry_in; /* locks left before a slotless handle rescans */
    uint32_t compact_backoff; /* refusals left before a dense arena is compacted again */
    uint32_t compact_period;  /* how long that wait currently is; grows while it does not pay */
    uint32_t compact_size;    /* the map's size at the last slide that did not pay */
    uint32_t arena_need;    /* block the refused store wanted; what a slide has to beat to count */
    uint8_t  arena_failed;  /* the arena refused a store: compact before the next store */
    uint8_t  reclaim_wait;  /* seconds the last expired flush that freed little backs off */
    uint32_t reclaim_at;    /* shm_now() before which an unforced expired flush is skipped */
    uint32_t reclaim_cap;   /* table_cap the backoff was measured at */
    uint32_t reclaim_sec;   /* shm_now() + 1 of the last flush; nothing expires twice in a second */
    uint32_t lock_depth;    /* RDLOCK_GUARD open on this handle */
    uint64_t map_id;        /* see shm_map_id_of */
    dev_t    file_dev;      /* the backing file as opened: unlink removes the path */
    ino_t    file_ino;      /*   only while it still names this file */
    int      wrlock_ent;    /* this map's shm_wrlock_maps entry, or SHM_WRLOCK_UNRESOLVED */
    uint8_t  pending_close; /* DESTROY arrived while lock_depth > 0; free at depth 0 */
    int      readonly;      /* 1 = frozen PROT_READ view: never write the mapping
                               (no rdepth, no clock bit) */
    size_t     mmap_size;
    uint32_t   max_mask;    /* max_table_cap - 1, for seqlock bounds clamping */
    uint32_t   iter_pos;
    char      *copy_buf;
    uint32_t   copy_buf_size;
    uint32_t   iterating;   /* active iterator count (each + cursors) */
    uint32_t   iter_gen;    /* table_gen snapshot for each() */
    uint8_t    iter_active;
    uint8_t    deferred;    /* shrink/compact deferred while iterating */
    uint8_t    flush_done;  /* shard of a set: its partial-flush cycle ended this round */
    uint8_t    flush_freed; /* this handle's partial flushes freed entries this cycle */
    uint32_t   flush_seen;  /* flush_cursor as this handle's last partial flush left it */
    uint32_t   flush_gen;   /*   and the table_gen it was left at */
    char      *path;
    int        backing_fd;  /* memfd to close on destroy, else -1 */
    struct ShmHandle_s **shard_handles; /* non-NULL: a sharded map's dispatcher */
    uint32_t   num_shards;
    uint32_t   shard_mask;
    uint8_t    route_high;     /* shard on the high hash half (see SHM_ROUTING_*) */
    uint32_t   shard_iter;
    uint32_t   shard_rr;       /* pop/shift/drain start; apart from shard_iter so a
                                  drain inside each() skips no shard */
    void     (*rz_resume)(struct ShmHandle_s *h); /* the variant's rz_run */
    sigset_t   sig_old;        /* the signal mask to restore while sig_held */
    uint8_t    sig_held;       /* signals are blocked until this write lock is released */
    uint64_t   sect_bytes;     /* string bytes hashed, stored, compared or copied out
                                  under this write lock */
    volatile int *sig_count;   /* the interpreter's PL_sig_pending */
    int        sig_seen;       /*   as this write lock found it */
    uint64_t   reclaim_kept;   /* expired slot the last flush kept, table_gen << 32 | slot;
                                  UINT64_MAX if none */
} ShmHandle;

/* ---- Signals held across a long pass ----
 * Perl croaks from its C signal handler once 120 signals are pending, stranding
 * a held write lock.  A write blocks signals once one arrives (shm_sig_check),
 * or before a step over this many slots or SHM_SIG_HOLD_BYTES of strings; never
 * before taking the lock, or a waiter cannot be killed. */
#define SHM_SIG_HOLD_MIN 4096u
#define SHM_SIG_HOLD_BYTES ((uint64_t)SHM_SIG_HOLD_MIN << 8)
#define SHM_SIG_CHECK_SLOTS 255u    /* masks: a slot scan checks every 256th slot, */
#define SHM_SIG_CHECK_ENTRIES 15u   /*   a batch every 16th entry */
static volatile int shm_sig_none;   /* sig_count of a handle no interpreter watches */
static __attribute__((noinline, cold)) void shm_sig_block(ShmHandle *h) {
    sigset_t all;
    sigfillset(&all);
    sigdelset(&all, SIGSEGV);
    sigdelset(&all, SIGBUS);
    sigdelset(&all, SIGFPE);
    sigdelset(&all, SIGILL);
    if (pthread_sigmask(SIG_BLOCK, &all, &h->sig_old) == 0) h->sig_held = 1;
}
static inline void shm_sig_hold(ShmHandle *h, uint32_t work) {
    if (work >= SHM_SIG_HOLD_MIN && !h->sig_held) shm_sig_block(h);
}
static inline __attribute__((always_inline)) void shm_sig_check(ShmHandle *h) {
    if (__builtin_expect(*h->sig_count != h->sig_seen, 0) && !h->sig_held) shm_sig_block(h);
}
static inline void shm_sig_check_every(ShmHandle *h, uint32_t done, uint32_t mask) {
    if (!(done & mask)) shm_sig_check(h);
}
static inline void shm_sig_hold_bytes(ShmHandle *h, uint32_t bytes) {
    h->sect_bytes += bytes;
    if (h->sect_bytes >= SHM_SIG_HOLD_BYTES) shm_sig_hold(h, SHM_SIG_HOLD_MIN);
}
static inline void shm_sig_release(ShmHandle *h) {
    if (__builtin_expect(h->sig_held, 0)) {
        h->sig_held = 0;
        pthread_sigmask(SIG_SETMASK, &h->sig_old, NULL);
    }
}
static inline void shm_set_sig_count(ShmHandle *h, volatile int *count) {
    h->sig_count = count;
    for (uint32_t i = 0; h->shard_handles && i < h->num_shards; i++)
        h->shard_handles[i]->sig_count = count;
}

typedef struct {
    ShmHandle *handle;       /* for sharded, the dispatcher */
    ShmHandle *current;      /* current shard handle (== handle for single maps) */
    SV        *owner;        /* keeps the mmap/handle alive while the cursor lives */
    uint32_t   iter_pos;
    uint32_t   gen;          /* table_gen snapshot -- reset on mismatch */
    uint32_t   shard_idx;
    uint32_t   shard_count;  /* 1 for single maps */
    char      *copy_buf;
    uint32_t   copy_buf_size;
} ShmCursor;

static inline int shm_grow_buf(char **buf, uint32_t *cap, uint32_t needed) {
    if (needed == 0) needed = 1;
    if (needed <= *cap) return 1;
    uint32_t ns = *cap ? *cap : 64;
    while (ns < needed) {
        uint32_t next = ns * 2;
        if (next <= ns) { ns = needed; break; }
        ns = next;
    }
    char *nb = (char *)realloc(*buf, ns);
    if (!nb) return 0;
    *buf = nb;
    *cap = ns;
    return 1;
}

static inline int shm_ensure_copy_buf(ShmHandle *h, uint32_t needed) {
    return shm_grow_buf(&h->copy_buf, &h->copy_buf_size, needed);
}

static inline int shm_cursor_ensure_copy_buf(ShmCursor *c, uint32_t needed) {
    return shm_grow_buf(&c->copy_buf, &c->copy_buf_size, needed);
}

static inline uint64_t shm_hash_int64(int64_t key) {
    return XXH3_64bits(&key, sizeof(key));
}

static inline uint64_t shm_hash_string(const char *data, uint32_t len) {
    return XXH3_64bits(data, (size_t)len);
}

/* ---- Futex-based read-write lock ---- */

#define SHM_RWLOCK_SPIN_LIMIT 32
#define SHM_LOCK_TIMEOUT_SEC  2  /* FUTEX_WAIT timeout for stale lock detection */

static inline void shm_rwlock_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

#define SHM_RWLOCK_WRITER_BIT 0x80000000U
#define SHM_RWLOCK_PID_MASK   0x7FFFFFFFU
#define SHM_RWLOCK_WR(pid)    (SHM_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & SHM_RWLOCK_PID_MASK))

/* kill(pid,0) succeeds for an unreaped zombie.  An unreadable /proc says "not a
 * zombie", never force-recovering a possibly-live holder. */
static inline int shm_pid_is_zombie(uint32_t pid) {
    char path[32], buf[256];
    snprintf(path, sizeof(path), "/proc/%u/stat", (unsigned)pid);
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return 0;
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    if (n <= 0) return 0;
    buf[n] = '\0';
    /* "pid (comm) state ..."; comm may contain ')' */
    char *rp = strrchr(buf, ')');
    if (!rp || rp + 2 >= buf + n) return 0;
    return rp[1] == ' ' && rp[2] == 'Z';
}

/* Per map, write locks this process (any handle or thread) holds or is
 * acquiring: our own pid in its lock word is a recycled ghost only at 0.
 * Entries are never freed (that races an acquirer); a process past
 * SHM_WRLOCK_MAPS maps reads every own-pid lock as held. */
#define SHM_WRLOCK_MAPS 256
#define SHM_WRLOCK_NO_ENTRY   (-1)
#define SHM_WRLOCK_UNRESOLVED (-2)   /* a handle that has not write-locked yet */
/* Low 32 bits count holds; the generation above lets a repairer see one come and go. */
#define SHM_WRLOCK_HOLD ((1ULL << 32) | 1)
typedef struct { uint64_t id; uint64_t holds; } ShmWrlockMap;
static ShmWrlockMap shm_wrlock_maps[SHM_WRLOCK_MAPS];
/* Holds through handles with no entry; non-zero makes every own-pid lock read as held. */
static uint32_t shm_wrlock_untracked = 0;
/* An anonymous map (shared only by inheritance) uses its address.  A collision
 * costs recovery on both maps, never correctness. */
static inline uint64_t shm_map_id_of(uint64_t dev, uint64_t ino, const void *base) {
    uint64_t id = ino ? (dev * 0x9E3779B97F4A7C15ULL) ^ (ino + 0x165667B19E3779F9ULL)
                      : (uint64_t)(uintptr_t)base;
    return id ? id : 1;   /* 0 marks a free slot */
}

static inline int shm_wrlock_entry(uint64_t id) {
    for (int i = 0; i < SHM_WRLOCK_MAPS; i++) {
        if (__atomic_load_n(&shm_wrlock_maps[i].id, __ATOMIC_SEQ_CST) == id)
            return i;
        uint64_t expected = 0;
        if (__atomic_compare_exchange_n(&shm_wrlock_maps[i].id, &expected, id, 0,
                                        __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            return i;
        if (expected == id) return i;
    }
    return SHM_WRLOCK_NO_ENTRY;
}

/* Resolved at the first write lock or repair, so read-only use spends no entry.
 * A handle is one thread's. */
static inline int shm_wrlock_ent_of(ShmHandle *h) {
    if (h->wrlock_ent == SHM_WRLOCK_UNRESOLVED)
        h->wrlock_ent = shm_wrlock_entry(h->map_id);
    return h->wrlock_ent;
}

/* Raise before the lock word can carry our pid and drop after it is clear, or
 * another thread of ours reads our live lock as a ghost. */
static inline void shm_wrlock_hold(int ent) {
    if (ent == SHM_WRLOCK_NO_ENTRY)
        __atomic_add_fetch(&shm_wrlock_untracked, 1, __ATOMIC_SEQ_CST);
    else
        __atomic_add_fetch(&shm_wrlock_maps[ent].holds, SHM_WRLOCK_HOLD, __ATOMIC_SEQ_CST);
}

static inline void shm_wrlock_unhold(int ent) {
    if (ent == SHM_WRLOCK_NO_ENTRY)
        __atomic_sub_fetch(&shm_wrlock_untracked, 1, __ATOMIC_SEQ_CST);
    else
        __atomic_sub_fetch(&shm_wrlock_maps[ent].holds, 1, __ATOMIC_SEQ_CST);
}

static inline int shm_wrlock_busy(int ent) {
    return (uint32_t)__atomic_load_n(&shm_wrlock_maps[ent].holds, __ATOMIC_SEQ_CST) != 0;
}

/* Without allocating: a map with no entry was never write-locked by us. */
static inline int shm_wrlock_held_by_id(uint64_t id) {
    if (__atomic_load_n(&shm_wrlock_untracked, __ATOMIC_SEQ_CST) != 0)
        return 1;
    for (int i = 0; i < SHM_WRLOCK_MAPS; i++) {
        uint64_t slot = __atomic_load_n(&shm_wrlock_maps[i].id, __ATOMIC_SEQ_CST);
        if (slot == id)
            return shm_wrlock_busy(i);
        if (slot == 0) return 0;   /* entries are appended, so a gap ends the search */
    }
    return 0;
}

/* Acquiring callers drop their own hold before asking. */
static inline int shm_wrlock_ours(const ShmHandle *h) {
    int ent = h->wrlock_ent;
    if (ent == SHM_WRLOCK_UNRESOLVED) return shm_wrlock_held_by_id(h->map_id);
    if (__atomic_load_n(&shm_wrlock_untracked, __ATOMIC_SEQ_CST) != 0) return 1;
    if (ent == SHM_WRLOCK_NO_ENTRY) return 1;
    return shm_wrlock_busy(ent);
}

/* Repairer's token, holds 0 -> 1: no thread of ours held or was acquiring the
 * map, and other repairers are barred.  Acquirers are not: while holds still
 * equal *claimed, none has started since. */
static inline int shm_wrlock_claim_idle(int ent, uint64_t *claimed) {
    uint64_t v;
    if (ent == SHM_WRLOCK_NO_ENTRY) return 0;
    if (__atomic_load_n(&shm_wrlock_untracked, __ATOMIC_SEQ_CST) != 0) return 0;
    v = __atomic_load_n(&shm_wrlock_maps[ent].holds, __ATOMIC_SEQ_CST);
    if ((uint32_t)v != 0) return 0;
    *claimed = v + 1;
    return __atomic_compare_exchange_n(&shm_wrlock_maps[ent].holds, &v, v + 1, 0,
                                       __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
}

/* 1 if alive or unknown.  A recycled pid reads alive until that process exits. */
static inline int shm_pid_alive(uint32_t pid) {
    if (pid == 0) return 0; /* kill(0,0) would ask about our process group */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0;
    return !shm_pid_is_zombie(pid);
}

/* Our own pid in a lock word is a dead writer's, recycled to us, unless a
 * thread of ours holds this map. */
static inline int shm_holder_blocks_us(const ShmHandle *h, uint32_t pid) {
    if (pid == h->cached_pid && !shm_wrlock_ours(h))
        return 0;
    return shm_pid_alive(pid);
}

static void shm_lru_rebuild_if_corrupt(ShmHandle *h);
static void shm_recount_counters(ShmHandle *h);
static inline void shm_seqlock_write_begin(uint32_t *seq);
static inline void shm_seqlock_write_end(uint32_t *seq);

/* Force-recover a stale write lock left by a dead process: CAS to our own pid,
 * so a later recoverer can re-recover if we crash mid-repair. */
static inline void shm_recover_stale_lock(ShmHandle *h, uint32_t observed_wlock) {
    ShmHeader *hdr = h->hdr;
    uint32_t mypid = SHM_RWLOCK_WR((uint32_t)getpid());
    int ent = shm_wrlock_ent_of(h);
    if (observed_wlock == mypid) {
        /* Own-pid ghost: the CAS below succeeds for every thread of ours, so the
         * map's holds arbitrate instead. */
        uint64_t claimed;
        if (!shm_wrlock_claim_idle(ent, &claimed))
            return;
        /* A hold since the claim moves the generation even if the word looks
         * unchanged; the word is read first, so a hold that wrote it is seen. */
        if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) != mypid ||
            __atomic_load_n(&shm_wrlock_maps[ent].holds, __ATOMIC_SEQ_CST) != claimed) {
            shm_wrlock_unhold(ent);
            return;
        }
    } else {
        shm_wrlock_hold(ent);   /* the repair is a hold */
    }
    /* SEQ_CST like the acquire path's CAS: it must publish the hold above to a
     * thread of ours that reads our pid here. */
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED)) {
        shm_wrlock_unhold(ent);
        return;
    }
    h->sig_seen = *h->sig_count;
    shm_sig_hold(h, hdr->table_cap);
    /* Even out the dead writer's seq first so readers proceed: the repair below
     * touches nothing lock-free readers read.  A resize does: finish it, seq odd. */
    uint32_t seq = __atomic_load_n(&hdr->seq, __ATOMIC_RELAXED);
    if (__atomic_load_n(&hdr->rz_phase, __ATOMIC_ACQUIRE) != SHM_RZ_NONE && h->rz_resume) {
        if (!(seq & 1))
            shm_seqlock_write_begin(&hdr->seq);
        h->rz_resume(h);
        shm_seqlock_write_end(&hdr->seq);
    } else if (seq & 1)
        __atomic_store_n(&hdr->seq, seq + 1, __ATOMIC_RELEASE);
    shm_lru_rebuild_if_corrupt(h);
    shm_recount_counters(h);
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    shm_wrlock_unhold(ent);   /* after the word is 0, never before */
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    shm_sig_release(h);
}

static const struct timespec shm_lock_timeout = { SHM_LOCK_TIMEOUT_SEC, 0 };
/* A draining writer waits this long before probing the readers still holding. */
static const struct timespec shm_drain_probe_after = { 0, 20 * 1000 * 1000 };

/* Bumped in the atfork child so a handle detects a fork without getpid(). */
static uint32_t shm_fork_gen = 1;
static pthread_once_t shm_atfork_once = PTHREAD_ONCE_INIT;
static void shm_on_fork_child(void) {
    __atomic_add_fetch(&shm_fork_gen, 1, __ATOMIC_RELAXED);
    /* The child holds no write lock: every published hold is a parent thread's. */
    __atomic_store_n(&shm_wrlock_untracked, 0, __ATOMIC_RELAXED);
    for (int i = 0; i < SHM_WRLOCK_MAPS; i++)
        __atomic_store_n(&shm_wrlock_maps[i].holds, 0, __ATOMIC_RELAXED);
}
static void shm_atfork_init(void) {
    pthread_atfork(NULL, NULL, shm_on_fork_child);
}

/* SEQ_CST: the bit is set before the slot's rdepth can go non-zero, so a
 * writer's bitmap scan never misses a committed reader. */
static inline void shm_occ_set(ShmHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void shm_occ_clear(ShmHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

/* Locks between a slotless handle's rescans for a free slot. */
#define SHM_SLOTLESS_RETRY_EVERY 256u
static inline void shm_claim_reader_slot(ShmHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&shm_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* A fork always rescans: the child owns none of the parent's slots. */
    if (h->my_slot_idx == UINT32_MAX && cur_gen == h->cached_fork_gen
            && h->slotless_retry_in) {
        h->slotless_retry_in--;
        return;
    }
    pthread_once(&shm_atfork_once, shm_atfork_init);
    /* Re-read after pthread_once: shm_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&shm_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = (uint32_t)(now_pid * SHM_READER_SLOT_STRIDE % SHM_READER_SLOTS);
    for (uint32_t i = 0; i < SHM_READER_SLOTS; i++) {
        uint32_t s = (start + i) % SHM_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* A drained dead predecessor may have left rdepth set. */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            shm_occ_set(h, s);
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot, so reclaim one whose owner is dead.  Safe even at
     * rdepth>0: a writer scan ignores rdepth when pid==0. */
    for (uint32_t i = 0; i < SHM_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        /* kill() alone, as in shm_occ_sweep: a zombie's slot frees once reaped. */
        if (dpid == 0 || dpid == now_pid || kill((pid_t)dpid, 0) == 0 || errno != ESRCH) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            shm_occ_set(h, i);
            h->my_slot_idx = i;
            return;
        }
    }
    /* Slotless: the lock still works, but this reader's death is not recoverable. */
    h->slotless_retry_in = SHM_SLOTLESS_RETRY_EVERY;
}

/* Dead readers need nothing here: the draining writer clears them. */
static inline void shm_recover_after_timeout(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    /* ACQUIRE at every load feeding shm_holder_blocks_us: it pairs with the
     * holder's CAS, so a thread of ours that sees our pid also sees the hold. */
    uint32_t val = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
    if (val >= SHM_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & SHM_RWLOCK_PID_MASK;
        if (!shm_holder_blocks_us(h, pid))
            shm_recover_stale_lock(h, val);
    }
}

/* rwait may over-count (a waiter killed while parked), never under-count. */
static inline void shm_park(ShmHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void shm_unpark(ShmHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* SEQ_CST: Dekker pairs with the writer's wlock CAS and rdepth scan (inc() with
 * rdlock's re-check, dec() with shm_reader_wake_drain's load).  dec() peels
 * slotless first, so a slot claimed mid-hold cannot take the decrement. */
static inline void shm_rdepth_inc(ShmHandle *h) {
    if (h->my_slot_idx != UINT32_MAX) {
        __atomic_add_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_SEQ_CST);
    } else {
        __atomic_add_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
        h->slotless_held++;
    }
}
static inline void shm_rdepth_dec(ShmHandle *h) {
    if (h->slotless_held > 0) {
        h->slotless_held--;
        __atomic_sub_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_SEQ_CST);
    } else if (h->my_slot_idx != UINT32_MAX) {
        uint32_t *rdepth = &h->reader_slots[h->my_slot_idx].rdepth;
        /* Below zero: shm_rdlock_drop_unwound took this lock back from under
         * its section, beneath a signal handler that interrupted it. */
        if (__atomic_sub_fetch(rdepth, 1, __ATOMIC_SEQ_CST) == UINT32_MAX)
            __atomic_add_fetch(rdepth, 1, __ATOMIC_SEQ_CST);
    }
}

static inline void shm_reader_wake_drain(ShmHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_SEQ_CST) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

/* The read locks this handle holds: its slot is its own. */
static inline uint32_t shm_rd_held(const ShmHandle *h) {
    return h->slotless_held + (h->my_slot_idx == UINT32_MAX ? 0 :
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_RELAXED));
}

/* At a lock call a handle's read locks are its open guards' (lock_depth); any
 * more were left by a call croaked out of its section. */
static inline void shm_rdlock_drop_unwound(ShmHandle *h) {
    if (__builtin_expect(shm_rd_held(h) <= h->lock_depth, 1)) return;
    while (shm_rd_held(h) > h->lock_depth) shm_rdepth_dec(h);
    shm_reader_wake_drain(h);
}

static inline void shm_rwlock_rdlock(ShmHandle *h) {
    /* Frozen: no writer exists, and PROT_READ would fault on the rdepth publish. */
    if (h->readonly) return;
    shm_claim_reader_slot(h);
    ShmHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            shm_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;
            /* A writer arrived meanwhile: yield (write-preferring). */
            shm_rdepth_dec(h);
            shm_reader_wake_drain(h);
            spin = 0;
            continue;
        }
        /* The writer may be draining a read lock this handle was croaked out of. */
        shm_rdlock_drop_unwound(h);
        if (__builtin_expect(spin < SHM_RWLOCK_SPIN_LIMIT, 1)) {
            shm_rwlock_spin_pause();
            continue;
        }
        if (cur >= SHM_RWLOCK_WRITER_BIT &&
            !shm_holder_blocks_us(h, cur & SHM_RWLOCK_PID_MASK)) {
            shm_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        shm_park(h);
        cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &shm_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                shm_unpark(h);
                shm_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        shm_unpark(h);
        spin = 0;
    }
}

static inline void shm_rwlock_rdunlock(ShmHandle *h) {
    if (h->readonly) return;
    shm_rdepth_dec(h);
    shm_reader_wake_drain(h);
}

/* Clears the bits of unowned slots.  Clear, re-read the pid, restore the bit if
 * it was claimed meanwhile: a claimant sets pid before the bit. */
#define SHM_OCC_SWEEP_EVERY 1024u
static inline void shm_occ_sweep(ShmHandle *h) {
    for (uint32_t w = 0; w < SHM_OCC_WORDS; w++) {
        uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
        while (word) {
            uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
            word &= word - 1;
            uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
            /* Pid before rdepth: a reader killed mid-lock is drained to pid 0
             * with rdepth left set. */
            if (pid != 0) {
                if (__atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST) != 0) continue;
                /* kill() alone: a zombie's idle slot frees once reaped. */
                if (pid == h->cached_pid || kill((pid_t)pid, 0) == 0 || errno != ESRCH) continue;
                uint32_t ep = pid;
                if (!__atomic_compare_exchange_n(&h->reader_slots[i].pid, &ep, 0,
                        0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
                    continue;
            }
            shm_occ_clear(h, i);
            if (__atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_SEQ_CST) != 0)
                shm_occ_set(h, i);
        }
    }
}

static inline void shm_rwlock_wrlock(ShmHandle *h) {
    /* No Perl API: xt/slotless_reader_recovery.t compiles this with plain cc.
     * A frozen handle never arrives: every mutator croaks before locking. */
    shm_claim_reader_slot(h);  /* refresh cached_pid across fork */
    ShmHeader *hdr = h->hdr;
    /* The owner pid is in the lock word: no crash window between taking and owning. */
    uint32_t mypid = SHM_RWLOCK_WR(h->cached_pid);
    int ent = shm_wrlock_ent_of(h);
    /* Phase 1: exclude other writers. */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        shm_wrlock_hold(ent);
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_ACQUIRE))
            break;
        shm_wrlock_unhold(ent);   /* before the test below, which asks about others */
        shm_rdlock_drop_unwound(h);   /* the holder may be draining a read lock we left */
        if (__builtin_expect(spin < SHM_RWLOCK_SPIN_LIMIT, 1)) {
            for (uint32_t k = 1u << (spin < 8 ? spin : 8); k; k--) shm_rwlock_spin_pause();
            while (__atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED) != 0 && ++spin < SHM_RWLOCK_SPIN_LIMIT)
                shm_rwlock_spin_pause();
            continue;
        }
        if (expected >= SHM_RWLOCK_WRITER_BIT &&
            !shm_holder_blocks_us(h, expected & SHM_RWLOCK_PID_MASK)) {
            shm_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        shm_park(h);
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->wlock, FUTEX_WAIT, cur,
                              &shm_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                shm_unpark(h);
                shm_recover_after_timeout(h);
                spin = 0;
                continue;
            }
        }
        shm_unpark(h);
        spin = 0;
    }
    /* Phase 2: no new reader joins; drain those holding. */
    for (int probe = 0;;) {
        /* ACQUIRE, or ARM64 may read it after the scan below and wait on a
         * bump it has already missed, until the timeout. */
        uint32_t v = __atomic_load_n(&hdr->drain_seq, __ATOMIC_ACQUIRE);
        int busy = 0;
        for (uint32_t w = 0; w < SHM_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (probe && !shm_pid_alive(pid)) {
                    /* Dead reader: drop its pid; leave the occ bit, not to race a claimant. */
                    uint32_t ep = pid;
                    __atomic_compare_exchange_n(&h->reader_slots[i].pid, &ep, 0,
                            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
                    continue;
                }
                busy = 1;
            }
        }
        /* A dead slotless reader is never drained (documented limitation). */
        if (__atomic_load_n(&hdr->slotless_rdepth, __ATOMIC_SEQ_CST) != 0)
            busy = 1;
        if (!busy) {
            if (h->occ_sweep_in-- == 0) { h->occ_sweep_in = SHM_OCC_SWEEP_EVERY; shm_occ_sweep(h); }
            h->sect_bytes = 0;
            h->sig_seen = *h->sig_count;
            return;
        }
        /* One may be ours, left by a croaked call; dropping it ends the wait at once. */
        shm_rdlock_drop_unwound(h);
        /* Probe liveness after the first timeout, or EINTR: signals restarting
         * the relative wait would otherwise postpone it forever. */
        if (syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v,
                    probe ? &shm_lock_timeout : &shm_drain_probe_after, NULL, 0) == -1 &&
            (errno == ETIMEDOUT || errno == EINTR))
            probe = 1;
    }
}

static inline void shm_rwlock_wrunlock(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    shm_wrlock_unhold(h->wrlock_ent);   /* after the word is 0, never before */
    /* Never reset rwait when a wake finds nobody: a waiter between its rwait++
     * and FUTEX_WAIT would then sleep to its timeout, as no unlock wakes it. */
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    shm_sig_release(h);
}

/* ---- Seqlock (lock-free readers) ---- */

/* Torn lock-free passes before get/exists take the read lock. */
#define SHM_READ_TRIES_UNLOCKED 8
/* A value this long that tore once is re-read under the read lock at once. */
#define SHM_READ_TORN_BIG (64u * 1024)

static inline uint32_t shm_seqlock_read_begin(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    int spin = 0, budget = 100000;
    for (;;) {
        uint32_t s = __atomic_load_n(&hdr->seq, __ATOMIC_ACQUIRE);
        if (__builtin_expect((s & 1) == 0, 1)) return s;
        if (__builtin_expect(spin < budget, 1)) {
            shm_rwlock_spin_pause();
            spin++;
            continue;
        }
        /* Prolonged odd seq -- check for dead writer */
        uint32_t val = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (val >= SHM_RWLOCK_WRITER_BIT) {
            uint32_t pid = val & SHM_RWLOCK_PID_MASK;
            /* shm_holder_blocks_us's rule, with getpid(): cached_pid is 0 before
             * a handle's first lock, and the parent's in a fork child until then. */
            if (pid == 0
                || (pid == (uint32_t)getpid() && !shm_wrlock_ours(h))
                || !shm_pid_alive(pid)) {
                /* A PROT_READ view cannot recover: return stale rather than spin. */
                if (h->readonly) return s;
                shm_recover_stale_lock(h, val);
                spin = 0;
                continue;
            }
        } else if (h->readonly) {
            return s;   /* odd seq with no holder: nothing will ever republish */
        }
        struct timespec ts = {0, 1000000};
        nanosleep(&ts, NULL);
        spin = 0;
        budget = 2000;
    }
}

static inline int shm_seqlock_read_retry(uint32_t *seq, uint32_t start) {
    __atomic_thread_fence(__ATOMIC_ACQUIRE);
    return __atomic_load_n(seq, __ATOMIC_RELAXED) != start;
}

static inline void shm_seqlock_write_begin(uint32_t *seq) {
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);
    /* StoreStore: on ARM64 the odd seq must be visible before the writes that follow. */
    __atomic_thread_fence(__ATOMIC_RELEASE);
}

static inline void shm_seqlock_write_end(uint32_t *seq) {
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);
}

/* ---- Arena allocator ---- */

static inline uint32_t shm_next_pow2(uint32_t v);

static inline uint32_t shm_arena_round_up(uint32_t len) {
    if (len < SHM_ARENA_MIN_ALLOC) return SHM_ARENA_MIN_ALLOC;
    return shm_next_pow2(len);
}

/* Offset 0 is reserved: a block of exactly arena_cap never fits. */
static inline int shm_arena_can_hold(const ShmHeader *hdr, uint32_t slen) {
    return slen <= SHM_INLINE_MAX ||
           (uint64_t)SHM_ARENA_MIN_ALLOC + shm_arena_round_up(slen) <= hdr->arena_cap;
}

static inline int shm_arena_class_index(uint32_t alloc_size) {
    if (alloc_size <= SHM_ARENA_MIN_ALLOC) return 0;
    if (alloc_size > (SHM_ARENA_MIN_ALLOC << (SHM_ARENA_NUM_CLASSES - 1))) return -1;
    return 32 - __builtin_clz(alloc_size - 1) - 4;  /* log2(alloc_size) - 4 */
}

static inline uint32_t shm_arena_alloc(ShmHeader *hdr, char *arena, uint32_t len) {
    uint32_t asize = shm_arena_round_up(len);
    int cls = shm_arena_class_index(asize);

    if (cls >= 0 && hdr->arena_free[cls] != 0) {
        uint32_t head = hdr->arena_free[cls];
        /* Heads are peer-writable: treat a wild one as an empty class. */
        if (head >= SHM_ARENA_MIN_ALLOC && (uint64_t)head + asize <= hdr->arena_cap) {
            uint32_t next;
            memcpy(&next, arena + head, sizeof(uint32_t));
            hdr->arena_free[cls] = next;
            return head;
        }
    }
    if (cls < 0) {
        uint32_t prev = 0, cur = hdr->arena_large_free;
        uint32_t guard = SHM_ARENA_FREELIST_MAX(hdr->arena_cap);
        uint32_t steps = 0;
        while (cur != 0 && steps++ < guard) {
            uint32_t next, blk;
            /* cur is peer-writable.  Bound by the 8-byte [next][size] header, not
             * asize: a smaller valid block near the end is skipped, not fatal. */
            if (cur < SHM_ARENA_MIN_ALLOC ||
                (uint64_t)cur + 2 * sizeof(uint32_t) > hdr->arena_cap) break;
            memcpy(&next, arena + cur, sizeof(uint32_t));
            memcpy(&blk, arena + cur + sizeof(uint32_t), sizeof(uint32_t));
            if (!blk || (uint64_t)cur + blk > hdr->arena_cap) break;
            /* Exact size: a larger block would be refiled at the smaller size on free. */
            if (blk == asize) {
                if (prev == 0) hdr->arena_large_free = next;
                else memcpy(arena + prev, &next, sizeof(uint32_t));
                return cur;
            }
            prev = cur; cur = next;
        }
    }

    uint64_t off = hdr->arena_bump;
    if (off + asize > hdr->arena_cap || off + asize > (uint64_t)UINT32_MAX)
        return 0;
    hdr->arena_bump = off + asize;
    return (uint32_t)off;
}

static inline void shm_arena_free_block(ShmHeader *hdr, char *arena,
                                         uint32_t off, uint32_t len) {
    uint32_t asize = shm_arena_round_up(len);
    int cls = shm_arena_class_index(asize);
    if (off < SHM_ARENA_MIN_ALLOC) return;
    /* off is peer-writable: leak a wild block rather than write out of bounds. */
    if ((uint64_t)off + asize > hdr->arena_cap) return;
    if (cls < 0) {
        uint32_t old_head = hdr->arena_large_free;
        memcpy(arena + off, &old_head, sizeof(uint32_t));                  /* next */
        memcpy(arena + off + sizeof(uint32_t), &asize, sizeof(uint32_t));  /* size */
        /* The head publishes the block: its link must already be in it. */
        __atomic_signal_fence(__ATOMIC_SEQ_CST);
        hdr->arena_large_free = off;
        return;
    }
    uint32_t old_head = hdr->arena_free[cls];
    memcpy(arena + off, &old_head, sizeof(uint32_t));
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    hdr->arena_free[cls] = off;
}

/* The tag publishes a slot: whatever it covers, its TTL included, is stored before it. */
static inline void shm_publish_tag(uint8_t *states, uint32_t pos, uint8_t tag) {
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    states[pos] = tag;
}

/* Live block: ref = node index << 1 | is_value; at 2^31 slots max the shift has
 * no room for another flag.  Snapshotted free block: ref = size. */
typedef struct { uint32_t off; uint32_t ref; } ShmArenaRef;

static int shm_arena_ref_cmp(const void *a, const void *b) {
    uint32_t x = ((const ShmArenaRef *)a)->off, y = ((const ShmArenaRef *)b)->off;
    return x < y ? -1 : x > y ? 1 : 0;
}

/* So a gap compaction cannot close is relisted as the same blocks: classes
 * never split.  `out` NULL only counts. */
static uint32_t shm_arena_snapshot_free(const ShmHeader *hdr, const char *arena,
                                        ShmArenaRef *out, uint32_t cap) {
    uint32_t n = 0;
    uint32_t guard = SHM_ARENA_FREELIST_MAX(hdr->arena_cap);
    for (int c = 0; c < SHM_ARENA_NUM_CLASSES; c++) {
        uint32_t size = (uint32_t)SHM_ARENA_MIN_ALLOC << c;
        uint32_t off = hdr->arena_free[c], steps = 0;
        while (off && steps++ < guard) {
            if (off < SHM_ARENA_MIN_ALLOC || (uint64_t)off + size > hdr->arena_cap) break;
            if (out) { if (n >= cap) return n; out[n].off = off; out[n].ref = size; }
            n++;
            memcpy(&off, arena + off, sizeof(uint32_t));
        }
    }
    uint32_t off = hdr->arena_large_free, steps = 0;
    while (off && steps++ < guard) {
        uint32_t next, size;
        if (off < SHM_ARENA_MIN_ALLOC || (uint64_t)off + 2 * sizeof(uint32_t) > hdr->arena_cap) break;
        memcpy(&next, arena + off, sizeof(uint32_t));
        memcpy(&size, arena + off + sizeof(uint32_t), sizeof(uint32_t));
        if (!size || (uint64_t)off + size > hdr->arena_cap) break;
        if (out) { if (n >= cap) return n; out[n].off = off; out[n].ref = size; }
        n++;
        off = next;
    }
    return n;
}

/* Each block is clipped to [from, to) and cut into chunks no larger than itself,
 * so blocks never merge.  Gaps and blocks ascend: one cursor serves every gap. */
static void shm_arena_relist_gap(ShmHeader *hdr, char *arena, const ShmArenaRef *blocks,
                                 uint32_t n, uint32_t *ci, uint32_t from, uint32_t to) {
    while (*ci < n && (uint64_t)blocks[*ci].off + blocks[*ci].ref <= from) (*ci)++;
    uint32_t i = *ci;
    while (i < n && blocks[i].off < to) {
        uint32_t s = blocks[i].off > from ? blocks[i].off : from;
        uint64_t e = (uint64_t)blocks[i].off + blocks[i].ref;
        if (e > to) e = to;
        while (e > s && e - s >= SHM_ARENA_MIN_ALLOC) {
            uint32_t span = (uint32_t)(e - s), chunk = blocks[i].ref;
            while (chunk > span) chunk >>= 1;
            shm_arena_free_block(hdr, arena, s, chunk);
            s += chunk;
        }
        i++;
    }
    *ci = i;
}

/* Only the smallest class with no free block and no headroom can gain from a
 * slide, and only if it fits headroom plus holes. */
static inline int shm_arena_slide_useless(const ShmHeader *hdr, uint64_t live) {
    uint64_t headroom = hdr->arena_cap - hdr->arena_bump;
    uint64_t used = hdr->arena_bump - SHM_ARENA_MIN_ALLOC;
    if (live > used) return 0;
    for (int c = 0; c < SHM_ARENA_NUM_CLASSES; c++) {
        uint64_t size = (uint64_t)SHM_ARENA_MIN_ALLOC << c;
        if (hdr->arena_free[c] || size <= headroom) continue;
        return size > headroom + (used - live);
    }
    return 0;
}

static inline void shm_arena_reset(ShmHeader *hdr) {
    memset(hdr->arena_free, 0, sizeof(hdr->arena_free));
    hdr->arena_large_free = 0;
    hdr->arena_bump = SHM_ARENA_MIN_ALLOC;
}

static inline int shm_str_store(ShmHeader *hdr, char *arena,
                                 uint32_t *off, uint32_t *len_field,
                                 const char *str, uint32_t slen, bool utf8) {
    if (slen <= SHM_INLINE_MAX) {
        shm_inline_pack(off, len_field, str, slen, utf8);
        return 1;
    }
    uint32_t aoff = shm_arena_alloc(hdr, arena, slen);
    if (aoff == 0) return 0;
    memcpy(arena + aoff, str, slen);
    /* Interim inline-empty state -- see shm_inline_pack. */
    __atomic_store_n(len_field, SHM_INLINE_FLAG, __ATOMIC_RELEASE);
    __atomic_store_n(off, aoff, __ATOMIC_RELEASE);
    __atomic_store_n(len_field, SHM_PACK_LEN(slen, utf8), __ATOMIC_RELEASE);
    return 1;
}

static inline void shm_str_free(ShmHeader *hdr, char *arena,
                                 uint32_t off, uint32_t len_field) {
    if (!SHM_IS_INLINE(len_field))
        shm_arena_free_block(hdr, arena, off, SHM_UNPACK_LEN(len_field));
}

static inline void shm_str_copy(char *dst, uint32_t off, uint32_t len_field,
                                 const char *arena, uint64_t arena_cap, uint32_t len) {
    if (SHM_IS_INLINE(len_field)) {
        shm_inline_read(off, len_field, dst);
    } else if (off >= SHM_ARENA_MIN_ALLOC && (uint64_t)off + len <= arena_cap) {
        memcpy(dst, arena + off, len);
    } else {
        /* A poisoned record reads as zeros.  Readers that take an arena pointer
         * instead bound off+len against arena_cap themselves. */
        memset(dst, 0, len);
    }
}

static inline uint32_t shm_next_pow2(uint32_t v) {
    if (v < 2) return 2;
    if (v > 0x80000000U) return 0;
    v--;
    v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16;
    return v + 1;
}

/* Cap at 2^31 before next_pow2, which returns 0 above it. */
static inline uint32_t shm_max_tcap_from_entries(uint32_t max_entries) {
    uint64_t want = (uint64_t)max_entries * 4 / 3 + 1;
    uint32_t cap = (want > 0x80000000ULL) ? 0x80000000U : shm_next_pow2((uint32_t)want);
    return cap < SHM_INITIAL_CAP ? SHM_INITIAL_CAP : cap;
}

static inline int shm_over_load(uint32_t size, uint32_t tomb, uint32_t cap) {
    return (uint64_t)(size + tomb) * 4 > (uint64_t)cap * 3;
}

/* The last test matters at max capacity: nothing else stops churn from filling
 * every empty slot, after which each miss walks the whole table. */
static inline int shm_needs_compaction(uint32_t size, uint32_t tomb, uint32_t cap) {
    return tomb > size || tomb > cap / 4 || (uint64_t)tomb * 2 > (uint64_t)cap - size;
}

static inline int shm_under_load(uint32_t size, uint32_t cap) {
    return cap > SHM_INITIAL_CAP && (uint64_t)size * 4 < cap;
}

/* All the way down in one call: batch removers reach it once per batch. */
static inline uint32_t shm_shrink_target(uint32_t size, uint32_t cap) {
    while (shm_under_load(size, cap)) cap /= 2;
    if (cap < SHM_INITIAL_CAP) cap = SHM_INITIAL_CAP;
    return cap;
}

/* lru_skip percentage to the promotion mask: 50 -> 1 (every 2nd), 90 -> 15,
 * 95 -> 31.  Outside 1..99 skipping is off. */
static inline uint32_t shm_lru_skip_to_mask(uint32_t lru_skip) {
    if (lru_skip == 0 || lru_skip >= 100) return 0;
    uint32_t interval = 100 / (100 - lru_skip);
    uint32_t p = 1;
    while (p < interval) p <<= 1;
    return p - 1;
}

/* ---- LRU helpers ---- */

static inline void shm_lru_unlink(ShmHandle *h, uint32_t idx) {
    uint32_t *prev = h->lru_prev;
    uint32_t *next = h->lru_next;
    ShmHeader *hdr = h->hdr;
    uint32_t p = prev[idx], n = next[idx];
    if (p == SHM_LRU_NONE && n == SHM_LRU_NONE && hdr->lru_head != idx) return;
    if (p != SHM_LRU_NONE) next[p] = n;
    else hdr->lru_head = n;
    if (n != SHM_LRU_NONE) prev[n] = p;
    else hdr->lru_tail = p;
    prev[idx] = next[idx] = SHM_LRU_NONE;
}

static inline void shm_lru_push_front(ShmHandle *h, uint32_t idx) {
    uint32_t *prev = h->lru_prev;
    uint32_t *next = h->lru_next;
    ShmHeader *hdr = h->hdr;
    if (h->lru_accessed) __atomic_store_n(&h->lru_accessed[idx], 0, __ATOMIC_RELAXED);
    prev[idx] = SHM_LRU_NONE;
    next[idx] = hdr->lru_head;
    if (hdr->lru_head != SHM_LRU_NONE) prev[hdr->lru_head] = idx;
    else hdr->lru_tail = idx;
    hdr->lru_head = idx;
}

static inline void shm_lru_promote(ShmHandle *h, uint32_t idx) {
    ShmHeader *hdr = h->hdr;
    if (hdr->lru_head == idx) return;
    /* Promote every (mask+1)th access, set the clock bit on the rest; never skip
     * the tail, or eviction would take a hot entry. */
    if (hdr->lru_skip > 0 && idx != hdr->lru_tail) {
        static __thread uint32_t promote_ctr = 0;
        if ((++promote_ctr & hdr->lru_skip) != 0) {
            __atomic_store_n(&h->lru_accessed[idx], 1, __ATOMIC_RELAXED);
            return;
        }
    }
    shm_lru_unlink(h, idx);
    shm_lru_push_front(h, idx);
}

/* Never on a frozen map (PROT_READ; the file stays as sealed).  A set bit is
 * not rewritten, so a hot key's line stays shared. */
static inline void shm_lru_mark(ShmHandle *h, uint32_t idx) {
    if (h->lru_accessed && !h->readonly &&
        !__atomic_load_n(&h->lru_accessed[idx], __ATOMIC_RELAXED) &&
        !__atomic_load_n(&h->hdr->sealed, __ATOMIC_RELAXED))
        __atomic_store_n(&h->lru_accessed[idx], 1, __ATOMIC_RELAXED);
}

/* Recount size/tombstones from states[]: a writer killed between publishing
 * states[idx] and bumping the counters leaves them behind the table. */
static void shm_recount_counters(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    uint32_t cap = hdr->table_cap, live = 0, tomb = 0;
    for (uint32_t i = 0; i < cap; i++) {
        uint8_t st = h->states[i];
        if (st == SHM_TOMBSTONE) tomb++;
        else if (SHM_IS_LIVE(st)) live++;
    }
    /* Bracket only the stores: an attach validates size and tombstones together. */
    shm_seqlock_write_begin(&hdr->seq);
    /* Decreasing counter first: an increase can transiently exceed table_cap,
     * and a crash there is unrepairable.  Atomic, or gcc merges the arms. */
    if (tomb <= hdr->tombstones) {
        __atomic_store_n(&hdr->tombstones, tomb, __ATOMIC_RELEASE);
        __atomic_store_n(&hdr->size, live, __ATOMIC_RELEASE);
    } else {
        __atomic_store_n(&hdr->size, live, __ATOMIC_RELEASE);
        __atomic_store_n(&hdr->tombstones, tomb, __ATOMIC_RELEASE);
    }
    shm_seqlock_write_end(&hdr->seq);
}

/* A writer killed mid-unlink/push_front leaves a break that would loop the next
 * eviction.  The rebuild is in slot order: recency is lost, not entries. */
static void shm_lru_rebuild_if_corrupt(ShmHandle *h) {
    if (!h->lru_prev) return;
    ShmHeader *hdr = h->hdr;
    uint32_t cap = hdr->table_cap;
    uint32_t head = hdr->lru_head;
    uint32_t tail = hdr->lru_tail;
    int corrupt = 0;
    uint32_t chain_len = 0;

    if ((head != SHM_LRU_NONE && head >= cap) ||
        (tail != SHM_LRU_NONE && tail >= cap)) {
        corrupt = 1;
    } else {
        uint32_t prev_idx = SHM_LRU_NONE;
        uint32_t idx = head;
        while (idx != SHM_LRU_NONE) {
            if (idx >= cap || !SHM_IS_LIVE(h->states[idx]) ||
                h->lru_prev[idx] != prev_idx) { corrupt = 1; break; }
            prev_idx = idx;
            idx = h->lru_next[idx];
            if (++chain_len > cap) { corrupt = 1; break; }
        }
        if (!corrupt && prev_idx != tail) corrupt = 1;
    }
    /* Count live states, not hdr->size, which a killed writer can leave behind. */
    uint32_t live_count = 0;
    if (!corrupt) {
        for (uint32_t i = 0; i < cap; i++)
            if (SHM_IS_LIVE(h->states[i])) live_count++;
        if (chain_len != live_count) corrupt = 1;
    }
    if (!corrupt) return;

    memset(h->lru_prev, 0xFF, (size_t)cap * sizeof(uint32_t));
    memset(h->lru_next, 0xFF, (size_t)cap * sizeof(uint32_t));
    if (h->lru_accessed) memset(h->lru_accessed, 0, cap);
    uint32_t prev = SHM_LRU_NONE;
    uint32_t new_head = SHM_LRU_NONE;
    for (uint32_t i = 0; i < cap; i++) {
        if (!SHM_IS_LIVE(h->states[i])) continue;
        h->lru_prev[i] = prev;
        if (prev != SHM_LRU_NONE) h->lru_next[prev] = i;
        else new_head = i;
        prev = i;
    }
    hdr->lru_head = new_head;
    hdr->lru_tail = prev;
}

/* Rerun from the SHM_RZ_CLEAR record after a crash: table_cap drops only once
 * every state is empty, and the stores after it repeat harmlessly. */
static void shm_clear_run(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    memset(h->states, SHM_EMPTY, hdr->table_cap);
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    hdr->size = 0;
    hdr->tombstones = 0;
    if (hdr->table_cap > SHM_INITIAL_CAP)
        hdr->table_cap = SHM_INITIAL_CAP;

    if (h->arena)
        shm_arena_reset(hdr);

    /* LRU links and TTLs are read only after an insert or move writes them. */
    if (h->lru_prev) {
        memset(h->lru_prev, 0xFF, SHM_INITIAL_CAP * sizeof(uint32_t));
        memset(h->lru_next, 0xFF, SHM_INITIAL_CAP * sizeof(uint32_t));
        if (h->lru_accessed) memset(h->lru_accessed, 0, SHM_INITIAL_CAP);
        hdr->lru_head = SHM_LRU_NONE;
        hdr->lru_tail = SHM_LRU_NONE;
    }

    if (h->expires_at) {
        memset(h->expires_at, 0, SHM_INITIAL_CAP * sizeof(uint32_t));
        hdr->flush_cursor = 0;
    }
    hdr->pop_cursor = 0;
    hdr->shift_cursor = 0;

    hdr->table_gen++;
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    __atomic_store_n(&hdr->rz_phase, SHM_RZ_NONE, __ATOMIC_RELEASE);
}

/* ---- Create / Open / Close ---- */

#define SHM_ERR_BUFLEN (PATH_MAX + 256)

typedef struct {
    uint64_t nodes_off, states_off;
    uint64_t lru_prev_off, lru_next_off, lru_accessed_off;
    uint64_t expires_off;
    uint64_t reader_slots_off;
    uint64_t occ_off;
    uint64_t arena_off, arena_cap;
    uint64_t total_size;
    uint64_t end_off;  /* end of the LRU/TTL region; the file must reach it */
} ShmLayout;

static inline uint64_t shm_clamp_arena_cap(uint64_t want) {
    if (want < 4096) return 4096;
    if (want > UINT32_MAX) return UINT32_MAX;
    return want;
}

/* Reopen checks the file against end_off and takes reader_slots_off and
 * total_size from the header. */
static inline void shm_compute_layout(ShmLayout *lo, uint32_t max_tcap,
                                       uint32_t node_size, int has_lru,
                                       int has_ttl, int has_arena,
                                       uint32_t max_entries,
                                       uint64_t arena_cap_override) {
    lo->nodes_off  = sizeof(ShmHeader);
    lo->states_off = lo->nodes_off + (uint64_t)max_tcap * node_size;
    uint64_t off = lo->states_off + max_tcap;
    lo->lru_prev_off = lo->lru_next_off = lo->lru_accessed_off = 0;
    lo->expires_off = 0;
    if (has_lru) {
        off = (off + 3) & ~(uint64_t)3;
        lo->lru_prev_off = off; off += (uint64_t)max_tcap * sizeof(uint32_t);
        lo->lru_next_off = off; off += (uint64_t)max_tcap * sizeof(uint32_t);
        lo->lru_accessed_off = off; off += max_tcap;
    }
    if (has_ttl) {
        off = (off + 3) & ~(uint64_t)3;
        lo->expires_off = off; off += (uint64_t)max_tcap * sizeof(uint32_t);
    }
    lo->end_off = off;
    off = (off + 7) & ~(uint64_t)7;
    lo->reader_slots_off = off;
    off += (uint64_t)SHM_READER_SLOTS * sizeof(ShmReaderSlot);
    lo->occ_off = off;
    off += SHM_OCC_BYTES;
    lo->arena_off = lo->arena_cap = 0;
    if (has_arena) {
        lo->arena_off = (off + 7) & ~(uint64_t)7;
        uint64_t want = arena_cap_override ? arena_cap_override
                                           : (uint64_t)max_entries * 128;
        lo->arena_cap = shm_clamp_arena_cap(want);
        lo->total_size = lo->arena_off + lo->arena_cap;
    } else {
        lo->total_size = off;
    }
}

static inline void shm_init_header(ShmHeader *hdr, void *base,
                                    const ShmLayout *lo, uint32_t max_tcap,
                                    uint32_t node_size, uint32_t variant_id,
                                    int has_arena, int has_lru, int has_ttl,
                                    uint32_t max_size, uint32_t default_ttl,
                                    uint32_t lru_skip) {
    memset(hdr, 0, sizeof(ShmHeader));
    hdr->version       = SHM_VERSION;
    hdr->variant_id    = variant_id;
    hdr->node_size     = node_size;
    hdr->max_table_cap = max_tcap;
    hdr->table_cap     = SHM_INITIAL_CAP;
    hdr->total_size    = lo->total_size;
    hdr->nodes_off     = lo->nodes_off;
    hdr->states_off    = lo->states_off;
    hdr->arena_off     = has_arena ? lo->arena_off : 0;
    hdr->arena_cap     = lo->arena_cap;
    hdr->reader_slots_off = lo->reader_slots_off;
    hdr->arena_bump    = SHM_ARENA_MIN_ALLOC;  /* reserve offset 0 */
    hdr->routing       = SHM_ROUTING_SPLIT;
    hdr->max_size      = max_size;
    hdr->default_ttl   = default_ttl;
    hdr->lru_skip      = shm_lru_skip_to_mask(lru_skip);
    hdr->lru_head      = SHM_LRU_NONE;
    hdr->lru_tail      = SHM_LRU_NONE;
    /* Only the initial table: see shm_clear_run. */
    if (has_lru) {
        memset((char *)base + lo->lru_prev_off, 0xFF, SHM_INITIAL_CAP * sizeof(uint32_t));
        memset((char *)base + lo->lru_next_off, 0xFF, SHM_INITIAL_CAP * sizeof(uint32_t));
        memset((char *)base + lo->lru_accessed_off, 0, SHM_INITIAL_CAP);
    }
    if (has_ttl)
        memset((char *)base + lo->expires_off, 0, SHM_INITIAL_CAP * sizeof(uint32_t));
    memset((char *)base + lo->reader_slots_off, 0,
           SHM_READER_SLOTS * sizeof(ShmReaderSlot));
    /* Create does not memset the mapping: no OS zero-fill to rely on. */
    memset((char *)base + lo->occ_off, 0, SHM_OCC_BYTES);
    /* Magic last, as a release store: the commit point, so a creator killed
       before it leaves magic == 0, never a file mistaken for a valid one. */
    __atomic_store_n(&hdr->magic, SHM_MAGIC, __ATOMIC_RELEASE);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* The caller has checked the file size against sizeof(ShmHeader) and total_size. */
static inline int shm_validate_header(const ShmHeader *hdr,
                                       uint32_t variant_id, uint32_t node_size) {
    return (hdr->magic == SHM_MAGIC &&
            hdr->version == SHM_VERSION &&
            hdr->variant_id == variant_id &&
            hdr->node_size == node_size &&
            hdr->nodes_off >= sizeof(ShmHeader) &&
            hdr->states_off > hdr->nodes_off &&
            hdr->states_off < hdr->total_size &&
            (!hdr->arena_off || (hdr->arena_off < hdr->total_size &&
                                 hdr->arena_off + hdr->arena_cap <= hdr->total_size &&
                                 hdr->arena_bump <= hdr->arena_cap &&
                                 hdr->arena_bump >= SHM_ARENA_MIN_ALLOC)) &&
            hdr->max_table_cap > 0 &&
            (hdr->max_table_cap & (hdr->max_table_cap - 1)) == 0 &&
            hdr->table_cap > 0 &&
            (hdr->table_cap & (hdr->table_cap - 1)) == 0 &&
            hdr->table_cap <= hdr->max_table_cap &&
            hdr->states_off + hdr->max_table_cap <= hdr->total_size &&
            hdr->nodes_off + (uint64_t)hdr->max_table_cap * hdr->node_size <= hdr->states_off &&
            hdr->size <= hdr->table_cap &&
            hdr->tombstones <= hdr->table_cap - hdr->size &&
            (!hdr->max_size ||
             ((hdr->lru_head == SHM_LRU_NONE || hdr->lru_head < hdr->max_table_cap) &&
              (hdr->lru_tail == SHM_LRU_NONE || hdr->lru_tail < hdr->max_table_cap))));
}

/* size + tombstones <= table_cap can read torn on a healthy saturated map, so
 * reject only when the seqlock shows no writer was active across the check. */
static inline int shm_validate_header_live(const ShmHeader *hdr,
                                            uint32_t variant_id, uint32_t node_size,
                                            uint64_t map_id) {
    for (int attempt = 0; attempt < 4096; attempt++) {
        uint32_t s1 = __atomic_load_n(&hdr->seq, __ATOMIC_ACQUIRE);
        int ok = shm_validate_header(hdr, variant_id, node_size);
        __atomic_thread_fence(__ATOMIC_ACQUIRE);
        uint32_t s2 = __atomic_load_n(&hdr->seq, __ATOMIC_RELAXED);
        if (ok) return 1;
        /* Only a live holder can still republish, and a repair scan runs with
         * seq even, so seq stability alone proves nothing. */
        uint32_t w = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        /* shm_holder_blocks_us's rule, by map id */
        uint32_t wpid = w & SHM_RWLOCK_PID_MASK;
        int live_holder = (w >= SHM_RWLOCK_WRITER_BIT) && wpid != 0 &&
                          (wpid != (uint32_t)getpid() || shm_wrlock_held_by_id(map_id)) &&
                          shm_pid_alive(wpid);
        if (!live_holder) {
            /* Stable even seq: a real violation.  Stable odd: a dead writer's
             * leftover, one more read decides.  A moved seq means torn: retry. */
            if (s1 == s2)
                return (s1 & 1) ? shm_validate_header(hdr, variant_id, node_size) : 0;
        }
        if (attempt >= 8) { struct timespec ts = { 0, 500000 }; nanosleep(&ts, NULL); }
    }
    return shm_validate_header(hdr, variant_id, node_size);
}

static inline const char *shm_variant_name(uint32_t id) {
    static const char *const names[] = { "?", "I16", "I32", "II", "I16S", "I32S",
                                         "IS", "SI16", "SI32", "SI", "SS" };
    return id < sizeof(names) / sizeof(*names) ? names[id] : "?";
}

static inline void shm_format_header_error(char *errbuf, const char *prefix,
                                            const ShmHeader *hdr,
                                            uint32_t variant_id, uint64_t file_size) {
    if (!errbuf) return;
    if (hdr->magic != SHM_MAGIC)
        snprintf(errbuf, SHM_ERR_BUFLEN, "%s: bad magic (not a HashMap::Shared file)", prefix);
    else if (hdr->version != SHM_VERSION)
        snprintf(errbuf, SHM_ERR_BUFLEN, "%s: version mismatch (file=%u, expected=%u)",
                 prefix, hdr->version, SHM_VERSION);
    else if (hdr->variant_id != variant_id)
        snprintf(errbuf, SHM_ERR_BUFLEN, "%s: variant mismatch (the file is %s, not %s)",
                 prefix, shm_variant_name(hdr->variant_id), shm_variant_name(variant_id));
    else if (hdr->total_size != file_size)
        snprintf(errbuf, SHM_ERR_BUFLEN,
                 "%s: the file is %llu bytes but its header says %llu (a truncated or extended copy?)",
                 prefix, (unsigned long long)file_size, (unsigned long long)hdr->total_size);
    else
        snprintf(errbuf, SHM_ERR_BUFLEN, "%s: corrupt header", prefix);
}

static inline int shm_validate_layout_regions(ShmLayout *lo, const ShmHeader *hdr,
                                                int has_arena, uint64_t mapped_size,
                                                char *errbuf, const char *prefix) {
    int has_lru = (hdr->max_size > 0);
    int has_ttl = (hdr->default_ttl > 0);
    shm_compute_layout(lo, hdr->max_table_cap, hdr->node_size,
                       has_lru, has_ttl, has_arena, 0, 0);
    if (lo->end_off > mapped_size) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN,
                             "%s: file too small for LRU/TTL arrays", prefix);
        return 0;
    }
    /* Pointers come from the local layout, never the peer-writable
     * hdr->reader_slots_off, which is only sanity-gated. */
    uint64_t rs_off = hdr->reader_slots_off;
    if (!rs_off || rs_off < lo->end_off ||
        lo->reader_slots_off + SHM_READER_SLOTS * sizeof(ShmReaderSlot) > mapped_size ||
        lo->occ_off + SHM_OCC_BYTES > mapped_size) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN,
                             "%s: reader_slots region missing or out of bounds", prefix);
        return 0;
    }
    return 1;
}

static ShmHandle *shm_alloc_handle(void *base, uint64_t total_size,
                                    int has_arena, int has_lru, int has_ttl,
                                    const ShmLayout *lo,
                                    const char *path, int backing_fd,
                                    uint64_t map_id, char *errbuf) {
    ShmHeader *hdr = (ShmHeader *)base;
    ShmHandle *h = (ShmHandle *)calloc(1, sizeof(ShmHandle));
    if (!h) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "calloc: out of memory");
        munmap(base, (size_t)total_size);
        if (backing_fd >= 0) close(backing_fd);
        return NULL;
    }
    h->hdr       = hdr;
    h->nodes     = (char *)hdr + hdr->nodes_off;
    h->states    = (uint8_t *)((char *)hdr + hdr->states_off);
    h->arena     = has_arena ? (char *)hdr + lo->arena_off : NULL;   /* local layout, not the header */
    h->lru_prev  = has_lru ? (uint32_t *)((char *)hdr + lo->lru_prev_off) : NULL;
    h->lru_next  = has_lru ? (uint32_t *)((char *)hdr + lo->lru_next_off) : NULL;
    h->lru_accessed = has_lru ? (uint8_t *)((char *)hdr + lo->lru_accessed_off) : NULL;
    h->expires_at = has_ttl ? (uint32_t *)((char *)hdr + lo->expires_off) : NULL;
    h->reader_slots = (ShmReaderSlot *)((char *)hdr + lo->reader_slots_off);
    h->occ          = (uint64_t *)((char *)hdr + lo->occ_off);
    h->my_slot_idx = UINT32_MAX;
    /* occ_sweep_in stays 0, so the handle's first write lock sweeps. */
    h->cached_pid = 0;
    h->map_id    = map_id;
    h->wrlock_ent = SHM_WRLOCK_UNRESOLVED;
    h->mmap_size = (size_t)total_size;
    h->max_mask  = hdr->max_table_cap - 1;
    h->iter_pos  = 0;
    h->backing_fd = backing_fd;
    h->sig_count = &shm_sig_none;
    (void)madvise(base, (size_t)total_size, MADV_RANDOM);
    if (path) {
        h->path = strdup(path);
        if (!h->path) {
            if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "strdup: out of memory");
            munmap(base, (size_t)total_size);
            if (backing_fd >= 0) close(backing_fd);
            free(h);
            return NULL;
        }
    }
    if (has_arena) {
        h->copy_buf = (char *)malloc(256);
        if (h->copy_buf) h->copy_buf_size = 256;
    }
    return h;
}

/* O_NOFOLLOW refuses a symlink at the path as ELOOP, whose text blames a loop. */
static const char *shm_open_reason(const char *path, int err) {
    struct stat st;
    if (err == ELOOP && lstat(path, &st) == 0 && S_ISLNK(st.st_mode))
        return "is a symbolic link";
    return strerror(err);
}

static int shm_secure_open(const char *path, mode_t file_mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, file_mode);
        if (fd >= 0) { (void)fchmod(fd, file_mode); return fd; }   /* undo umask */
        if (errno != EEXIST) {
            if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "create(%s): %s", path, strerror(errno));
            return -1;
        }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* unlinked between the two opens */
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "open(%s): %s", path, shm_open_reason(path, errno));
        return -1;
    }
    if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "open(%s): create/attach kept racing", path);
    return -1;
}

/* Read, not mapped: a read fault on a tmpfs hole allocates the page. */
static int shm_file_is_zero(int fd, uint64_t size) {
    char buf[16384];
    for (uint64_t off = 0; off < size; ) {
        ssize_t n = pread(fd, buf, size - off < sizeof buf ? (size_t)(size - off) : sizeof buf, (off_t)off);
        if (n <= 0) return 0;
        for (ssize_t i = 0; i < n; i++) if (buf[i]) return 0;
        off += (uint64_t)n;
    }
    return 1;
}

static int shm_reserving(void) {
    const char *sp = getenv("DATA_HASHMAP_SHARED_SPARSE");
    return sp && !strcmp(sp, "0");
}

/* No fallocate here (musl passes EOPNOTSUPP through): write a zero byte into
 * each block of the still all-zero file, as glibc does. */
static int shm_reserve_by_writing(int fd, uint64_t size) {
    struct stat st;
    uint64_t step = 4096;
    if (fstat(fd, &st) == 0 && st.st_blksize > 0 && st.st_blksize < 4096 &&
        !(st.st_blksize & (st.st_blksize - 1)))
        step = (uint64_t)st.st_blksize;
    for (uint64_t off = 0; off < size; off += step) {
        ssize_t n;
        do n = pwrite(fd, "", 1, (off_t)off); while (n < 0 && errno == EINTR);
        if (n != 1) return n < 0 ? errno : EIO;
    }
    return 0;
}

static int shm_reserve(int fd, uint64_t size) {
    if (!shm_reserving()) return 0;
    /* Before Linux 6.11 tmpfs gives up at any pending signal and undoes the allocation, so a
     * periodic one could keep it from ever completing; SIGSTOP cannot be blocked. */
    sigset_t all, old;
    sigfillset(&all);
    sigprocmask(SIG_BLOCK, &all, &old);
    int e;
    do e = posix_fallocate(fd, 0, (off_t)size); while (e == EINTR);
    sigprocmask(SIG_SETMASK, &old, NULL);
    if (e == EOPNOTSUPP || e == EINVAL) e = shm_reserve_by_writing(fd, size);
    if (e == 0) return 0;
    errno = e;
    return -1;
}

#define SHM_CREATE_RACE_TRIES 250
static const struct timespec shm_create_race_nap = { 0, 2 * 1000 * 1000 };

static ShmHandle *shm_create_map(const char *path, uint32_t max_entries,
                                  uint32_t node_size, uint32_t variant_id,
                                  int has_arena, uint32_t max_size,
                                  uint32_t default_ttl, uint32_t lru_skip,
                                  uint64_t arena_cap_override, mode_t file_mode, char *errbuf,
                                  int *hold_fd) {
    if (errbuf) errbuf[0] = '\0';
    uint32_t max_tcap = shm_max_tcap_from_entries(max_entries);

    int has_lru = (max_size > 0);
    int has_ttl = (default_ttl > 0);

    ShmLayout lo;
    shm_compute_layout(&lo, max_tcap, node_size, has_lru, has_ttl, has_arena, max_entries, arena_cap_override);

    #define SHM_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

    /* Bounds the path every message below prints, so the reason always fits. */
    if (path && strlen(path) >= PATH_MAX) {
        SHM_ERR("%.64s...: %s", path, strerror(ENAMETOOLONG));
        return NULL;
    }

    int anonymous = (path == NULL);
    int fd = -1;
    int is_new, created = 0;
    struct stat st = { 0 };
    void *base;

    if (anonymous) {
        base = mmap(NULL, lo.total_size, PROT_READ | PROT_WRITE,
                     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { SHM_ERR("mmap(anon): %s", strerror(errno)); return NULL; }
        is_new = 1;
    } else {
        fd = shm_secure_open(path, file_mode, errbuf);
        if (fd < 0) return NULL;

        for (int tries = 0;; tries++) {
            while (flock(fd, LOCK_EX) < 0) {
                if (errno == EINTR) continue;
                SHM_ERR("flock(%s): %s", path, strerror(errno)); close(fd); return NULL;
            }

            if (fstat(fd, &st) < 0) { SHM_ERR("fstat(%s): %s", path, strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }

            is_new = created = (st.st_size == 0);
            /* Another user's empty file is their create between open and flock. */
            if (!is_new || st.st_uid == geteuid() || tries == SHM_CREATE_RACE_TRIES) break;
            flock(fd, LOCK_UN);
            nanosleep(&shm_create_race_nap, NULL);
        }

        if (!is_new && (uint64_t)st.st_size < sizeof(ShmHeader)) {
            SHM_ERR("%s: file too small (%lld bytes, need %zu)", path,
                    (long long)st.st_size, sizeof(ShmHeader));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (is_new) {
            if (st.st_uid != geteuid()) {
                SHM_ERR("%s: refusing to initialize file not owned by us", path);
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
            if (fchmod(fd, file_mode) < 0) {
                SHM_ERR("fchmod(%s): %s", path, strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
            if (ftruncate(fd, (off_t)lo.total_size) < 0) {
                SHM_ERR("ftruncate(%s, %llu): %s", path, (unsigned long long)lo.total_size, strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
            if (shm_reserve(fd, lo.total_size) < 0) {
                SHM_ERR("%s: cannot reserve %llu bytes: %s", path, (unsigned long long)lo.total_size, strerror(errno));
                if (ftruncate(fd, 0) < 0) { /* best effort */ }
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
        }

        base = mmap(NULL, is_new ? lo.total_size : (size_t)st.st_size,
                     PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            SHM_ERR("mmap(%s): %s", path, strerror(errno));
            if (is_new && ftruncate(fd, 0) < 0) { /* best effort */ }
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
    }

    ShmHeader *hdr = (ShmHeader *)base;
    uint64_t map_id = shm_map_id_of(st.st_dev, st.st_ino, base);
    uint64_t mapped_size = is_new ? lo.total_size : (uint64_t)st.st_size;

    if (is_new) {
        shm_init_header(hdr, base, &lo, max_tcap, node_size, variant_id,
                        has_arena, has_lru, has_ttl, max_size, default_ttl, lru_skip);
    } else {
        int ok = (hdr->total_size == (uint64_t)st.st_size &&
                  shm_validate_header_live(hdr, variant_id, node_size, map_id));
        if (ok) {
            has_lru = (hdr->max_size > 0);
            has_ttl = (hdr->default_ttl > 0);
            ok = shm_validate_layout_regions(&lo, hdr, has_arena, mapped_size, errbuf, path);
        } else if (hdr->magic == 0 && (uint64_t)st.st_size == lo.total_size
                   && st.st_uid == geteuid()
                   && shm_file_is_zero(fd, (uint64_t)st.st_size)) {
            /* A creator killed before the header init left an all-zero file. */
            if (fchmod(fd, file_mode) < 0) {
                SHM_ERR("%s: fchmod: %s", path, strerror(errno));
                munmap(base, (size_t)st.st_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            if (shm_reserve(fd, lo.total_size) < 0) {
                SHM_ERR("%s: cannot reserve %llu bytes: %s", path, (unsigned long long)lo.total_size, strerror(errno));
                munmap(base, (size_t)st.st_size);
                if (ftruncate(fd, 0) < 0) { /* best effort */ }
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
            shm_init_header(hdr, base, &lo, max_tcap, node_size, variant_id,
                            has_arena, has_lru, has_ttl, max_size, default_ttl, lru_skip);
            ok = created = 1;
        } else if (hdr->magic == 0 && (uint64_t)st.st_size == lo.total_size
                   && st.st_uid == geteuid()) {
            /* A creator died between the field stores and the magic commit. */
            SHM_ERR("%s: incomplete map file left by an interrupted create; remove it and retry", path);
        } else {
            shm_format_header_error(errbuf, path, hdr, variant_id, (uint64_t)st.st_size);
        }
        if (!ok) {
            munmap(base, (size_t)st.st_size);
            flock(fd, LOCK_UN); close(fd);
            return NULL;
        }
        if (hdr->sealed) {
            SHM_ERR("%s is frozen (read-only); open it with new_readonly", path);
            munmap(base, (size_t)st.st_size);
            flock(fd, LOCK_UN); close(fd);
            return NULL;
        }
    }

    #undef SHM_ERR
    ShmHandle *nh = shm_alloc_handle(base, mapped_size, has_arena, has_lru, has_ttl,
                                     &lo, path, -1, map_id, errbuf);
    if (nh) { nh->file_dev = st.st_dev; nh->file_ino = st.st_ino; }
    if (fd >= 0) {
        if (nh && hold_fd && created) *hold_fd = fd;   /* still locked: the caller releases it */
        else { flock(fd, LOCK_UN); close(fd); }
    }
    return nh;
}

static ShmHandle *shm_create_memfd(const char *name, uint32_t max_entries,
                                    uint32_t node_size, uint32_t variant_id,
                                    int has_arena, uint32_t max_size,
                                    uint32_t default_ttl, uint32_t lru_skip,
                                    uint64_t arena_cap_override, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    uint32_t max_tcap = shm_max_tcap_from_entries(max_entries);
    int has_lru = (max_size > 0);
    int has_ttl = (default_ttl > 0);

    ShmLayout lo;
    shm_compute_layout(&lo, max_tcap, node_size, has_lru, has_ttl, has_arena, max_entries, arena_cap_override);

    int fd = shm_memfd_create(name ? name : "hashmap", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "memfd_create: %s", strerror(errno));
        return NULL;
    }
    if (ftruncate(fd, (off_t)lo.total_size) < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "ftruncate: %s", strerror(errno));
        close(fd); return NULL;
    }
    if (shm_reserve(fd, lo.total_size) < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "memfd: cannot reserve %llu bytes: %s", (unsigned long long)lo.total_size, strerror(errno));
        close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)lo.total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "mmap: %s", strerror(errno));
        close(fd); return NULL;
    }

    shm_init_header((ShmHeader *)base, base, &lo, max_tcap, node_size, variant_id,
                    has_arena, has_lru, has_ttl, max_size, default_ttl, lru_skip);

    struct stat mst;
    uint64_t map_id = fstat(fd, &mst) == 0 ? shm_map_id_of(mst.st_dev, mst.st_ino, base)
                                           : shm_map_id_of(0, 0, base);
    return shm_alloc_handle(base, lo.total_size, has_arena, has_lru, has_ttl,
                             &lo, NULL, fd, map_id, errbuf);
}

static ShmHandle *shm_open_fd_map(int fd, uint32_t variant_id, uint32_t node_size,
                                   char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "fstat: %s", strerror(errno));
        return NULL;
    }
    if ((uint64_t)st.st_size < sizeof(ShmHeader)) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "fd: file too small for header");
        return NULL;
    }
    /* before mmap: a creator may truncate the file until it has set magic */
    uint32_t magic;
    ssize_t got = pread(fd, &magic, sizeof magic, offsetof(ShmHeader, magic));
    if (got < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "fd: read: %s", strerror(errno));
        return NULL;
    }
    if (got != (ssize_t)sizeof magic || magic != SHM_MAGIC) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "fd: bad magic (not a HashMap::Shared file)");
        return NULL;
    }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "mmap: %s", strerror(errno));
        return NULL;
    }

    ShmHeader *hdr = (ShmHeader *)base;
    uint64_t map_id = shm_map_id_of(st.st_dev, st.st_ino, base);
    if (hdr->total_size != (uint64_t)st.st_size ||
        !shm_validate_header_live(hdr, variant_id, node_size, map_id)) {
        shm_format_header_error(errbuf, "fd", hdr, variant_id, (uint64_t)st.st_size);
        munmap(base, ms);
        return NULL;
    }
    if (hdr->sealed) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN,
                             "this map is frozen (read-only); open a file with new_readonly; "
                             "a frozen memfd cannot be reopened");
        munmap(base, ms);
        return NULL;
    }

    int has_arena = (hdr->arena_off != 0);
    int has_lru   = (hdr->max_size > 0);
    int has_ttl   = (hdr->default_ttl > 0);
    ShmLayout lo;
    if (!shm_validate_layout_regions(&lo, hdr, has_arena, hdr->total_size, errbuf, "fd")) {
        munmap(base, ms);
        return NULL;
    }

    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "fcntl: %s", strerror(errno));
        munmap(base, ms);
        return NULL;
    }
    return shm_alloc_handle(base, hdr->total_size, has_arena, has_lru, has_ttl,
                             &lo, NULL, myfd, map_id, errbuf);
}

/* A non-frozen file is refused: lock-free readers would race a live writer. */
static ShmHandle *shm_open_readonly_map(const char *path, uint32_t variant_id,
                                        uint32_t node_size, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (strlen(path) >= PATH_MAX) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "%.64s...: %s", path, strerror(ENAMETOOLONG));
        return NULL;
    }
    int fd = open(path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
    if (fd < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "open(%s): %s", path, shm_open_reason(path, errno));
        return NULL;
    }
    struct stat st;
    if (fstat(fd, &st) < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "fstat(%s): %s", path, strerror(errno));
        close(fd); return NULL;
    }
    if ((uint64_t)st.st_size < sizeof(ShmHeader)) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "%s: file too small for header", path);
        close(fd); return NULL;
    }
    /* before mmap: a creator may truncate the file until it has set magic */
    uint32_t magic;
    ssize_t got = pread(fd, &magic, sizeof magic, offsetof(ShmHeader, magic));
    if (got < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "%s: read: %s", path, strerror(errno));
        close(fd); return NULL;
    }
    if (got != (ssize_t)sizeof magic || magic != SHM_MAGIC) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "%s: bad magic (not a HashMap::Shared file)", path);
        close(fd); return NULL;
    }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ, MAP_SHARED, fd, 0);
    int mmap_errno = errno;
    close(fd);
    if (base == MAP_FAILED) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "mmap(%s): %s", path, strerror(mmap_errno));
        return NULL;
    }
    ShmHeader *hdr = (ShmHeader *)base;
    uint64_t map_id = shm_map_id_of(st.st_dev, st.st_ino, base);
    if (hdr->total_size != (uint64_t)st.st_size ||
        !shm_validate_header_live(hdr, variant_id, node_size, map_id)) {
        shm_format_header_error(errbuf, path, hdr, variant_id, (uint64_t)st.st_size);
        munmap(base, ms);
        return NULL;
    }
    if (!hdr->sealed) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN,
                             "%s is not frozen: call ->freeze on the producer before opening read-only", path);
        munmap(base, ms);
        return NULL;
    }

    /* Unrepairable: a read-write attach refuses a sealed file.  freeze seals
     * under the lock, so a live holder will still finish. */
    if ((hdr->seq & 1) || hdr->wlock != 0) {
        uint32_t holder = hdr->wlock & SHM_RWLOCK_PID_MASK;
        if (errbuf) {
            if (holder && shm_pid_alive(holder) &&
                (holder != (uint32_t)getpid() || shm_wrlock_held_by_id(map_id)))
                snprintf(errbuf, SHM_ERR_BUFLEN,
                    "%s: a write is still in flight on this frozen file (pid %u); retry",
                    path, holder);
            else
                snprintf(errbuf, SHM_ERR_BUFLEN,
                    "%s: frozen file was left mid-update by a crashed writer; recreate it", path);
        }
        munmap(base, ms);
        return NULL;
    }
    int has_arena = (hdr->arena_off != 0);
    int has_lru   = (hdr->max_size > 0);
    int has_ttl   = (hdr->default_ttl > 0);
    ShmLayout lo;
    if (!shm_validate_layout_regions(&lo, hdr, has_arena, hdr->total_size, errbuf, path)) {
        munmap(base, ms);
        return NULL;
    }
    ShmHandle *h = shm_alloc_handle(base, hdr->total_size, has_arena, has_lru, has_ttl,
                                    &lo, path, -1, map_id,
                                    errbuf);   /* munmaps + frees on OOM */
    if (!h) return NULL;
    h->file_dev = st.st_dev;
    h->file_ino = st.st_ino;
    h->readonly = 1;
    return h;
}

static inline int shm_msync(ShmHandle *h) {
    if (!h) return 0;
    if (h->readonly) return 0;
    if (h->shard_handles) {
        for (uint32_t i = 0; i < h->num_shards; i++) {
            int rc;
            do { rc = msync(h->shard_handles[i]->hdr,
                            h->shard_handles[i]->mmap_size, MS_SYNC); }
            while (rc != 0 && errno == EINTR);
            if (rc != 0) return rc;
        }
        return 0;
    }
    if (!h->hdr) return 0;
    int rc;
    do { rc = msync(h->hdr, h->mmap_size, MS_SYNC); }
    while (rc != 0 && errno == EINTR);
    return rc;
}

static void shm_seal(ShmHandle *h) {
    shm_rwlock_wrlock(h);
    __atomic_store_n(&h->hdr->sealed, 1, __ATOMIC_RELEASE);
    shm_rwlock_wrunlock(h);
}

/* Seal every shard before flushing any, so a failed flush leaves the set sealed.
 * shm_msync skips a read-only handle, so shm_mark_readonly comes after this. */
static int shm_freeze(ShmHandle *h) {
    if (!h) return 0;
    uint32_t n = h->shard_handles ? h->num_shards : 1;
    ShmHandle **hs = h->shard_handles ? h->shard_handles : &h;
    for (uint32_t i = 0; i < n; i++) shm_seal(hs[i]);
    if (!h->path && h->backing_fd < 0) return 0;
    return shm_msync(h);
}

static void shm_mark_readonly(ShmHandle *h) {
    if (!h) return;
    h->readonly = 1;
    if (h->shard_handles)
        for (uint32_t i = 0; i < h->num_shards; i++)
            if (h->shard_handles[i]) h->shard_handles[i]->readonly = 1;
}

/* The shared header, not h->readonly, which misses a freeze through another
 * handle.  freeze seals shard 0 first. */
static inline int shm_is_sealed(const ShmHandle *h) {
    if (!h) return 0;
    if (h->shard_handles) {
        const ShmHandle *s = h->num_shards ? h->shard_handles[0] : NULL;
        return s && s->hdr && __atomic_load_n(&s->hdr->sealed, __ATOMIC_RELAXED);
    }
    return h->hdr && __atomic_load_n(&h->hdr->sealed, __ATOMIC_RELAXED);
}

/* A freezer killed between shard seals leaves a partly sealed set that only
 * another freeze can finish. */
static inline int shm_is_fully_sealed(const ShmHandle *h) {
    if (!h->shard_handles) return shm_is_sealed(h);
    for (uint32_t i = 0; i < h->num_shards; i++)
        if (!__atomic_load_n(&h->shard_handles[i]->hdr->sealed, __ATOMIC_RELAXED)) return 0;
    return 1;
}

static void shm_close_map_now(ShmHandle *h);

/* Defer the free to the last unlock: the save-stack cleanup still uses the
 * handle.  No atomics: CLONE_SKIP keeps a handle in one thread. */
static void shm_close_map(ShmHandle *h) {
    if (!h) return;
    if (h->lock_depth) { h->pending_close = 1; return; }
    shm_close_map_now(h);
}

static void shm_close_map_now(ShmHandle *h) {
    if (!h) return;
    if (h->shard_handles) {
        for (uint32_t i = 0; i < h->num_shards; i++)
            shm_close_map(h->shard_handles[i]);
        free(h->shard_handles);
        free(h->path);
        free(h);
        return;
    }
    if (h->hdr && !h->readonly &&
        h->cached_fork_gen == __atomic_load_n(&shm_fork_gen, __ATOMIC_RELAXED))
        shm_rdlock_drop_unwound(h);
    /* Not after a fork: a child must not clear the parent's slot.  A slot with
     * a read lock still held must survive for recovery. */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&shm_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* Occ bit first, while we still own the pid. */
        shm_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        /* Leave rdepth alone: a store after the CAS could clobber a new
         * claimant's increments.  The next claim zeroes it. */
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    if (h->backing_fd >= 0) close(h->backing_fd);
    free(h->copy_buf);
    free(h->path);
    free(h);
}

/* held[j] >= 0: shard j was created here and is still locked, so nobody has
 * attached it; truncate it back to an abandoned create. */
static ShmHandle *shm_sharded_fail(ShmHandle *h, uint32_t created, int *held) {
    for (uint32_t j = 0; j < created; j++) {
        shm_close_map(h->shard_handles[j]);
        if (held && held[j] >= 0) {
            if (ftruncate(held[j], 0) < 0) { /* best effort */ }
            flock(held[j], LOCK_UN);
            close(held[j]);
        }
    }
    free(held);
    free(h->shard_handles);
    free(h->path);
    free(h);
    return NULL;
}

static ShmHandle *shm_create_sharded(const char *path_prefix, uint32_t num_shards,
                                      uint32_t max_entries, uint32_t node_size,
                                      uint32_t variant_id, int has_arena,
                                      uint32_t max_size, uint32_t default_ttl,
                                      uint32_t lru_skip, uint64_t arena_cap_override,
                                      mode_t file_mode, char *errbuf) {
    if (!path_prefix) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "new_sharded requires a path_prefix");
        return NULL;
    }
    if (num_shards > SHM_MAX_SHARDS) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN,
                             "num_shards %u exceeds the maximum of %u",
                             num_shards, (unsigned)SHM_MAX_SHARDS);
        return NULL;
    }
    uint32_t ns = 1;
    uint8_t want_log2 = 1;
    while (ns < num_shards) { ns <<= 1; want_log2++; }
    num_shards = ns;

    int *held = NULL;   /* reserving: the still-locked fd of each shard this call creates */
    ShmHandle *h = (ShmHandle *)calloc(1, sizeof(ShmHandle));
    if (!h) { if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "calloc: out of memory"); return NULL; }

    h->shard_handles = (ShmHandle **)calloc(num_shards, sizeof(ShmHandle *));
    if (!h->shard_handles) { if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "calloc: out of memory"); return shm_sharded_fail(h, 0, held); }

    h->num_shards = num_shards;
    h->shard_mask = num_shards - 1;
    h->backing_fd = -1;   /* calloc left 0 = stdin */
    h->sig_count = &shm_sig_none;
    h->path = strdup(path_prefix);
    if (!h->path) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "strdup: out of memory");
        return shm_sharded_fail(h, 0, held);
    }

    if (shm_reserving()) {
        held = (int *)malloc(num_shards * sizeof(int));
        if (!held) { if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "malloc: out of memory"); return shm_sharded_fail(h, 0, held); }
        for (uint32_t i = 0; i < num_shards; i++) held[i] = -1;
    }
    for (uint32_t i = 0; i < num_shards; i++) {
        char shard_path[4096];
        int sn = snprintf(shard_path, sizeof(shard_path), "%s.%u", path_prefix, i);
        if (sn < 0 || sn >= (int)sizeof(shard_path)) {
            if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "shard path too long");
            return shm_sharded_fail(h, i, held);
        }
        h->shard_handles[i] = shm_create_map(shard_path, max_entries, node_size,
                                               variant_id, has_arena, max_size,
                                               default_ttl, lru_skip, arena_cap_override, file_mode, errbuf,
                                               held ? &held[i] : NULL);
        if (!h->shard_handles[i]) return shm_sharded_fail(h, i, held);
        /* A wrong count hides every key that routes elsewhere; 0 = never stamped. */
        const ShmHeader *sh = h->shard_handles[i]->hdr;
        if (sh->routing != SHM_ROUTING_LEGACY && sh->shard_log2 &&
            sh->shard_log2 != want_log2) {
            unsigned recorded = 1u << ((sh->shard_log2 - 1) & 31);
            if (errbuf && i == 0)
                snprintf(errbuf, SHM_ERR_BUFLEN,
                    "%s was created with %u shards, not %u",
                    path_prefix, recorded, num_shards);
            else if (errbuf)
                snprintf(errbuf, SHM_ERR_BUFLEN,
                    "%s.%u records %u shards, not %u",
                    path_prefix, i, recorded, num_shards);
            return shm_sharded_fail(h, i + 1, held);
        }
        if (i > 0) {
            /* Else a stray file from an earlier run joins the set. */
            const ShmHeader *a = h->shard_handles[0]->hdr;
            const ShmHeader *b = sh;
            const char *what =
                b->max_table_cap != a->max_table_cap ? "max_entries" :
                b->max_size      != a->max_size      ? "max_size"    :
                b->default_ttl   != a->default_ttl   ? "ttl"         :
                b->lru_skip      != a->lru_skip      ? "lru_skip"    :
                b->arena_cap     != a->arena_cap     ? "arena_cap"   :
                b->routing       != a->routing       ? "routing"     : NULL;
            if (what) {
                if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN,
                    "%s.%u disagrees with shard 0 on %s; the shards were not created "
                    "together", path_prefix, i, what);
                return shm_sharded_fail(h, i + 1, held);
            }
        }
    }
    /* Stamp only once every shard agreed, so a refused open stamps nothing.
     * Shard 0's CAS serialises creators: one with another count is refused. */
    ShmHeader *s0 = h->shard_handles[0]->hdr;
    if (s0->routing != SHM_ROUTING_LEGACY) {
        uint8_t seen = 0;
        if (!__atomic_compare_exchange_n(&s0->shard_log2, &seen, want_log2, 0,
                                         __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE) &&
            seen != want_log2) {
            if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN,
                "%s was created with %u shards, not %u",
                path_prefix, 1u << ((seen - 1) & 31), num_shards);
            return shm_sharded_fail(h, num_shards, held);
        }
        for (uint32_t i = 1; i < num_shards; i++) {
            ShmHeader *s = h->shard_handles[i]->hdr;
            uint8_t unset = 0;
            __atomic_compare_exchange_n(&s->shard_log2, &unset, want_log2, 0,
                                        __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
        }
    }

    h->route_high = (s0->routing != SHM_ROUTING_LEGACY);
    if (held) {
        for (uint32_t i = 0; i < num_shards; i++)
            if (held[i] >= 0) { flock(held[i], LOCK_UN); close(held[i]); }
        free(held);
    }
    return h;
}

static int shm_unlink_path(const char *path) {
    return (unlink(path) == 0) ? 1 : 0;
}

/* After a chdir or a rename the path may name another file: leave it alone. */
static int shm_unlink_own(const ShmHandle *h) {
    struct stat st;
    if (!h->path || lstat(h->path, &st) != 0 ||
        st.st_dev != h->file_dev || st.st_ino != h->file_ino)
        return 0;
    return shm_unlink_path(h->path);
}

static int shm_unlink_sharded(ShmHandle *h) {
    if (!h->shard_handles) return shm_unlink_own(h);
    int ok = 1;
    for (uint32_t i = 0; i < h->num_shards; i++)
        if (h->shard_handles[i] && h->shard_handles[i]->path &&
            !shm_unlink_own(h->shard_handles[i]))
            ok = 0;
    return ok;
}

static inline ShmCursor *shm_cursor_create(ShmHandle *h) {
    ShmCursor *c = (ShmCursor *)calloc(1, sizeof(ShmCursor));
    if (!c) return NULL;
    c->handle = h;
    if (h->shard_handles) {
        c->shard_count = h->num_shards;
        c->shard_idx = 0;
        c->current = h->shard_handles[0];
    } else {
        c->shard_count = 1;
        c->shard_idx = 0;
        c->current = h;
    }
    c->gen = c->current->hdr->table_gen;
    c->current->iterating++;
    return c;
}

static inline uint32_t shm_shard_index(const ShmHandle *h, uint64_t hash64) {
    uint32_t bits = h->route_high ? (uint32_t)(hash64 >> 32) : (uint32_t)hash64;
    return bits & h->shard_mask;
}

static inline void shm_cursor_destroy(ShmCursor *c) {
    if (!c) return;
    ShmHandle *cur = c->current;
    if (cur && cur->iterating > 0)
        cur->iterating--;
    free(c->copy_buf);
    free(c);
}

#endif /* SHM_DEFS_H */


/* ---- Part 2: template (included once per variant) ---- */

#define SHM_PASTE2(a, b) a##_##b
#define SHM_PASTE(a, b)  SHM_PASTE2(a, b)
#define SHM_FN(name)     SHM_PASTE(SHM_PREFIX, name)

typedef struct {
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key;
#else
    uint32_t key_off;
    uint32_t key_len;
#endif
#ifdef SHM_VAL_IS_STR
    uint32_t val_off;
    uint32_t val_len;
#else
    SHM_VAL_INT_TYPE value;
#endif
} SHM_NODE_TYPE;

#undef SHM_SHARD_DISPATCH
#ifdef SHM_KEY_IS_INT
  #define SHM_SHARD_DISPATCH(h, key_arg) \
      if ((h)->shard_handles) { \
          h = (h)->shard_handles[shm_shard_index((h), SHM_HASH_KEY64(key_arg))]; \
      }
#else
  #define SHM_SHARD_DISPATCH(h, key_str_arg, key_len_arg) \
      if ((h)->shard_handles) { \
          h = (h)->shard_handles[shm_shard_index((h), SHM_HASH_KEY_STR64(key_str_arg, key_len_arg))]; \
      }
#endif

#ifdef SHM_KEY_IS_INT
  #define SHM_HASH_KEY(k) ((uint32_t)(shm_hash_int64((int64_t)(k))))
  #define SHM_HASH_KEY64(k) (shm_hash_int64((int64_t)(k)))
  #define SHM_KEY_EQ(node_ptr, k) ((node_ptr)->key == (k))
#else
  #define SHM_HASH_KEY_STR(str, len) ((uint32_t)shm_hash_string((str), (len)))
  #define SHM_HASH_KEY_STR64(str, len) (shm_hash_string((str), (len)))
  /* Bytes only: the UTF8 flag is metadata, or an upgraded ASCII key would miss. */
  static inline int SHM_PASTE(SHM_PREFIX, _key_eq_str)(
      const SHM_NODE_TYPE *np, const char *arena, uint64_t arena_cap,
      const char *str, uint32_t len, bool utf8) {
      (void)utf8;
      uint32_t kl_packed = np->key_len;
      if (SHM_IS_INLINE(kl_packed)) {
          if (shm_inline_len(kl_packed) != len) return 0;
          char buf[SHM_INLINE_MAX];
          shm_inline_read(np->key_off, kl_packed, buf);
          return memcmp(buf, str, len) == 0;
      }
      if (SHM_UNPACK_LEN(kl_packed) != len) return 0;
      /* A corrupt key_off is a miss, so the probe continues. */
      if (np->key_off < SHM_ARENA_MIN_ALLOC || (uint64_t)np->key_off + len > arena_cap) return 0;
      return memcmp(arena + np->key_off, str, len) == 0;
  }
  #define SHM_KEY_EQ_STR(node_ptr, arena, arena_cap, str, len, utf8) \
      SHM_PASTE(SHM_PREFIX, _key_eq_str)((node_ptr), (arena), (arena_cap), \
                                         (str), (len), (utf8))
#endif

#if !defined(SHM_KEY_IS_INT) || defined(SHM_VAL_IS_STR)
  #define SHM_HAS_ARENA 1
#else
  #define SHM_HAS_ARENA 0
#endif

static void SHM_FN(rz_run)(ShmHandle *h);

/* Give the handle, and each shard of a set, this variant's resize resume. */
static ShmHandle *SHM_FN(bind)(ShmHandle *h) {
    if (!h) return NULL;
    h->rz_resume = SHM_FN(rz_run);
    for (uint32_t i = 0; i < h->num_shards; i++)
        h->shard_handles[i]->rz_resume = SHM_FN(rz_run);
    return h;
}

static ShmHandle *SHM_FN(create)(const char *path, uint32_t max_entries,
                                  uint32_t max_size, uint32_t default_ttl,
                                  uint32_t lru_skip, uint64_t arena_cap_override,
                                  mode_t file_mode, char *errbuf) {
    return SHM_FN(bind)(shm_create_map(path, max_entries,
                           (uint32_t)sizeof(SHM_NODE_TYPE),
                           SHM_VARIANT_ID, SHM_HAS_ARENA,
                           max_size, default_ttl, lru_skip, arena_cap_override, file_mode, errbuf, NULL));
}

static ShmHandle *SHM_FN(create_sharded)(const char *path_prefix,
                                          uint32_t num_shards,
                                          uint32_t max_entries,
                                          uint32_t max_size, uint32_t default_ttl,
                                          uint32_t lru_skip, uint64_t arena_cap_override,
                                          mode_t file_mode, char *errbuf) {
    return SHM_FN(bind)(shm_create_sharded(path_prefix, num_shards, max_entries,
                               (uint32_t)sizeof(SHM_NODE_TYPE),
                               SHM_VARIANT_ID, SHM_HAS_ARENA,
                               max_size, default_ttl, lru_skip, arena_cap_override, file_mode, errbuf));
}

static ShmHandle *SHM_FN(create_memfd)(const char *name, uint32_t max_entries,
                                        uint32_t max_size, uint32_t default_ttl,
                                        uint32_t lru_skip, uint64_t arena_cap_override,
                                        char *errbuf) {
    return SHM_FN(bind)(shm_create_memfd(name, max_entries,
                             (uint32_t)sizeof(SHM_NODE_TYPE),
                             SHM_VARIANT_ID, SHM_HAS_ARENA,
                             max_size, default_ttl, lru_skip, arena_cap_override, errbuf));
}

static ShmHandle *SHM_FN(open_fd)(int fd, char *errbuf) {
    return SHM_FN(bind)(shm_open_fd_map(fd, SHM_VARIANT_ID,
                            (uint32_t)sizeof(SHM_NODE_TYPE), errbuf));
}

static ShmHandle *SHM_FN(open_readonly)(const char *path, char *errbuf) {
    return shm_open_readonly_map(path, SHM_VARIANT_ID,
                                  (uint32_t)sizeof(SHM_NODE_TYPE), errbuf);
}

static inline uint32_t SHM_FN(node_hash)(ShmHandle *h, const SHM_NODE_TYPE *node) {
#ifdef SHM_KEY_IS_INT
    (void)h;
    return SHM_HASH_KEY(node->key);
#else
    char ibuf[SHM_INLINE_MAX];
    uint32_t klen;
    const char *kptr = shm_str_ptr(node->key_off, node->key_len, h->arena, h->hdr->arena_cap, ibuf, &klen);
    return shm_hash_string(kptr, klen);
#endif
}

static void SHM_FN(tombstone_at)(ShmHandle *h, uint32_t idx) {
    ShmHeader *hdr = h->hdr;
#if !defined(SHM_KEY_IS_INT) || defined(SHM_VAL_IS_STR)
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
#endif
    /* Retire the slot first: a freed block's first word becomes a free-list link,
     * which a still-live node would read if the writer died in between. */
    h->states[idx] = SHM_TOMBSTONE;
    hdr->size--;
    hdr->tombstones++;
#ifndef SHM_KEY_IS_INT
    shm_str_free(hdr, h->arena, nodes[idx].key_off, nodes[idx].key_len);
#endif
#ifdef SHM_VAL_IS_STR
    shm_str_free(hdr, h->arena, nodes[idx].val_off, nodes[idx].val_len);
#endif
}

static inline void SHM_FN(remove_at)(ShmHandle *h, uint32_t idx) {
    if (h->lru_prev) shm_lru_unlink(h, idx);
    /* Tombstone first: a live entry with its TTL cleared would never expire. */
    SHM_FN(tombstone_at)(h, idx);
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    if (h->expires_at) h->expires_at[idx] = 0;
}

static void SHM_FN(lru_evict_at)(ShmHandle *h, uint32_t idx) {
    int was_expired = SHM_IS_EXPIRED(h, idx, shm_now());
    SHM_FN(remove_at)(h, idx);
    __atomic_add_fetch(was_expired ? &h->hdr->stat_expired
                                   : &h->hdr->stat_evictions, 1, __ATOMIC_RELAXED);
}

/* `keep`, never the victim, is the entry an overwrite is replacing. */
static void SHM_FN(lru_evict_one_keep)(ShmHandle *h, uint32_t keep) {
    ShmHeader *hdr = h->hdr;
    uint32_t victim = hdr->lru_tail, spared = 0, now = h->expires_at ? shm_now() : 0;
    while (victim != SHM_LRU_NONE) {
        if (victim == keep) {
            victim = h->lru_prev[victim];
            continue;
        }
        if (SHM_IS_EXPIRED(h, victim, now)) break;
        if (h->lru_accessed && spared++ < SHM_LRU_SPARE_MAX &&
            __atomic_load_n(&h->lru_accessed[victim], __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->lru_accessed[victim], 0, __ATOMIC_RELAXED);
            uint32_t prev = h->lru_prev[victim];
            shm_lru_unlink(h, victim);
            shm_lru_push_front(h, victim);
            victim = prev;
            if (victim == SHM_LRU_NONE) victim = hdr->lru_tail;
            continue;
        }
        break;
    }
    if (victim == SHM_LRU_NONE) return;
    SHM_FN(lru_evict_at)(h, victim);
}

static void SHM_FN(lru_evict_one)(ShmHandle *h) {
    SHM_FN(lru_evict_one_keep)(h, SHM_LRU_NONE);
}

#ifdef SHM_KEY_IS_INT
#define SHM_KEY_SLEN(n) 0
#else
#define SHM_KEY_SLEN(n) (n)
#endif
#ifdef SHM_VAL_IS_STR
#define SHM_VAL_SLEN(n) (n)
#else
#define SHM_VAL_SLEN(n) 0
#endif

/* No eviction for strings that can never be stored: the insert is refused. */
static inline void SHM_FN(evict_for_insert)(ShmHandle *h, uint32_t klen, uint32_t vlen) {
    ShmHeader *hdr = h->hdr;
    if (hdr->max_size > 0 && hdr->size >= hdr->max_size &&
        shm_arena_can_hold(hdr, klen) && shm_arena_can_hold(hdr, vlen))
        SHM_FN(lru_evict_one)(h);
}

static void SHM_FN(expire_at)(ShmHandle *h, uint32_t idx) {
    SHM_FN(remove_at)(h, idx);
    __atomic_add_fetch(&h->hdr->stat_expired, 1, __ATOMIC_RELAXED);
}

/* Unforced, skipped for 1, 2, 4 ... 64 s after a flush that freed under a
 * sixteenth of the table.  A second flush in one second can free only the
 * entry the first one kept, left expired by a failed overwrite. */
static uint32_t SHM_FN(reclaim_expired)(ShmHandle *h, int forced, uint32_t keep) {
    uint32_t now = shm_now(), cap = h->hdr->table_cap, freed = 0;
    if (h->reclaim_cap != cap) {
        h->reclaim_cap = cap;
        h->reclaim_wait = 0;
        h->reclaim_at = 0;
    }
    if (h->reclaim_sec == now + 1) {
        uint64_t kept = h->reclaim_kept;
        if (kept == UINT64_MAX) return 0;
        if ((uint32_t)(kept >> 32) == h->hdr->table_gen) {
            uint32_t idx = (uint32_t)kept;
            if (idx == keep) return 0;   /* the same overwrite still protects it */
            h->reclaim_kept = UINT64_MAX;
            if (SHM_IS_LIVE(h->states[idx]) && SHM_IS_EXPIRED(h, idx, now)) {
                shm_sig_check(h);
                SHM_FN(expire_at)(h, idx);
                return 1;
            }
            return 0;
        }
        forced = 1;   /* a resize moved it */
    }
    if (!forced && now < h->reclaim_at) return 0;
    h->reclaim_sec = now + 1;
    h->reclaim_kept = keep != SHM_LRU_NONE && SHM_IS_EXPIRED(h, keep, now)
        ? (uint64_t)h->hdr->table_gen << 32 | keep : UINT64_MAX;
    shm_sig_hold(h, cap);
    for (uint32_t i = 0; i < cap; i++) {
        if (i != keep && SHM_IS_LIVE(h->states[i]) && SHM_IS_EXPIRED(h, i, now)) {
            shm_sig_check(h);
            SHM_FN(expire_at)(h, i);
            freed++;
        }
    }
    if (freed >= cap / 16) {
        h->reclaim_wait = 0;
        h->reclaim_at = 0;
    } else {
        h->reclaim_wait = h->reclaim_wait ? (h->reclaim_wait < 64 ? h->reclaim_wait * 2 : 64) : 1;
        h->reclaim_at = now + h->reclaim_wait;
    }
    return freed;
}

#if SHM_HAS_ARENA
static inline int SHM_FN(block_is)(uint32_t len_field, uint32_t asize) {
    return !SHM_IS_INLINE(len_field) && shm_arena_round_up(SHM_UNPACK_LEN(len_field)) == asize;
}

static int SHM_FN(lru_evict_for)(ShmHandle *h, uint32_t slen, uint32_t keep) {
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint32_t asize = shm_arena_round_up(slen);
    uint32_t pos = hdr->lru_tail;
    for (uint32_t n = 0; n < SHM_EVICT_SEARCH && pos != SHM_LRU_NONE; n++) {
        if (pos != keep && (
#ifndef SHM_KEY_IS_INT
                SHM_FN(block_is)(nodes[pos].key_len, asize) ||
#endif
#ifdef SHM_VAL_IS_STR
                SHM_FN(block_is)(nodes[pos].val_len, asize) ||
#endif
                0)) {
            SHM_FN(lru_evict_at)(h, pos);
            return 1;
        }
        pos = h->lru_prev[pos];
    }
    uint32_t before = hdr->size;
    SHM_FN(lru_evict_one_keep)(h, keep);
    return hdr->size < before;
}

static int SHM_FN(store_or_evict)(ShmHandle *h, uint32_t *off, uint32_t *len,
                                  const char *str, uint32_t slen, bool utf8, uint32_t keep) {
    shm_sig_hold_bytes(h, slen);
    if (shm_str_store(h->hdr, h->arena, off, len, str, slen, utf8)) return 1;
    if (!shm_arena_can_hold(h->hdr, slen)) return 0;
    /* One eviction only: if its block was the wrong size, more are as blind. */
    if (h->lru_prev && SHM_FN(lru_evict_for)(h, slen, keep) &&
        shm_str_store(h->hdr, h->arena, off, len, str, slen, utf8))
        return 1;
    if (h->expires_at && SHM_FN(reclaim_expired)(h, 1, keep) &&
        shm_str_store(h->hdr, h->arena, off, len, str, slen, utf8))
        return 1;
    /* Arm only after the eviction, which is how a full LRU cache normally stores. */
    h->arena_failed = 1;
    h->arena_need = shm_arena_round_up(slen);
    return 0;
}

/* Crash-safe: the free lists are cleared first, and a block moves only wholly
 * below its source, so its node points at intact bytes until one aligned 32-bit
 * store repoints it.  A killed writer leaks the free blocks not yet relisted. */
static uint64_t SHM_FN(arena_compact)(ShmHandle *h, int only_if_useful) {
    ShmHeader *hdr = h->hdr;
    uint64_t before = hdr->arena_bump;
    if (before <= SHM_ARENA_MIN_ALLOC) return 0;

    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t cap = hdr->table_cap;
    shm_sig_hold(h, before >= SHM_SIG_HOLD_BYTES ? SHM_SIG_HOLD_MIN : cap);

    uint32_t n = 0;
    uint64_t live = 0;
    for (uint32_t i = 0; i < cap; i++) {
        if (states[i] < SHM_TAG_MIN) continue;
#ifndef SHM_KEY_IS_INT
        if (!SHM_IS_INLINE(nodes[i].key_len)) {
            n++;
            live += shm_arena_round_up(SHM_UNPACK_LEN(nodes[i].key_len));
        }
#endif
#ifdef SHM_VAL_IS_STR
        if (!SHM_IS_INLINE(nodes[i].val_len)) {
            n++;
            live += shm_arena_round_up(SHM_UNPACK_LEN(nodes[i].val_len));
        }
#endif
    }
    if (n == 0) {
        shm_arena_reset(hdr);
        return before - SHM_ARENA_MIN_ALLOC;
    }
    if (only_if_useful && shm_arena_slide_useless(hdr, live)) return 0;

    /* Allocate first, so a failure leaves the arena as it was. */
    ShmArenaRef *refs = (ShmArenaRef *)malloc((size_t)n * sizeof *refs);
    if (!refs) return 0;

    uint32_t fcap = shm_arena_snapshot_free(hdr, h->arena, NULL, 0);
    ShmArenaRef *frees = NULL;
    uint32_t fn = 0;
    if (fcap) {
        frees = (ShmArenaRef *)malloc((size_t)fcap * sizeof *frees);
        if (!frees) { free(refs); return 0; }
        fn = shm_arena_snapshot_free(hdr, h->arena, frees, fcap);
        qsort(frees, fn, sizeof *frees, shm_arena_ref_cmp);
    }

    /* Sources vacated by a slide, newer than the snapshot; every destination lies
     * below the gap being relisted. */
    ShmArenaRef *vac = (ShmArenaRef *)malloc((size_t)n * sizeof *vac);
    if (!vac) { free(frees); free(refs); return 0; }

    /* From here on nothing may be handed a block that is about to move. */
    memset(hdr->arena_free, 0, sizeof(hdr->arena_free));
    hdr->arena_large_free = 0;

    uint32_t m = 0;
    for (uint32_t i = 0; i < cap && m < n; i++) {
        if (states[i] < SHM_TAG_MIN) continue;
#ifndef SHM_KEY_IS_INT
        if (!SHM_IS_INLINE(nodes[i].key_len)) {
            refs[m].off = nodes[i].key_off; refs[m].ref = i << 1; m++;
        }
#endif
#ifdef SHM_VAL_IS_STR
        if (m < n && !SHM_IS_INLINE(nodes[i].val_len)) {
            refs[m].off = nodes[i].val_off; refs[m].ref = (i << 1) | 1u; m++;
        }
#endif
    }
    qsort(refs, m, sizeof *refs, shm_arena_ref_cmp);

    uint32_t vn = 0, vi = 0;

    uint64_t bump = SHM_ARENA_MIN_ALLOC;
    uint32_t fi = 0;
    for (uint32_t k = 0; k < m; k++) {
        uint32_t idx = refs[k].ref >> 1;
        uint32_t off = refs[k].off, packed;
        uint32_t *offp;
#if defined(SHM_VAL_IS_STR) && !defined(SHM_KEY_IS_INT)
        int is_val = (int)(refs[k].ref & 1u);
        offp   = is_val ? &nodes[idx].val_off : &nodes[idx].key_off;
        packed = is_val ?  nodes[idx].val_len :  nodes[idx].key_len;
#elif defined(SHM_VAL_IS_STR)
        offp = &nodes[idx].val_off; packed = nodes[idx].val_len;
#else
        offp = &nodes[idx].key_off; packed = nodes[idx].key_len;
#endif
        uint32_t len  = SHM_UNPACK_LEN(packed);
        uint32_t size = shm_arena_round_up(len);
        /* Leave a wild peer-written offset where it is. */
        if (off < SHM_ARENA_MIN_ALLOC || (uint64_t)off + size > hdr->arena_cap)
            continue;
        if (bump + size <= off) {
            memcpy(h->arena + bump, h->arena + off, len);
            __atomic_store_n(offp, (uint32_t)bump, __ATOMIC_RELEASE);
            bump += size;
            vac[vn].off = off; vac[vn].ref = size; vn++;
        } else if ((uint64_t)off + size > bump) {
            /* Stuck: relist the free space below it, or the bump strands it. */
            if ((uint64_t)off > bump) {
                shm_arena_relist_gap(hdr, h->arena, frees, fn, &fi, (uint32_t)bump, off);
                shm_arena_relist_gap(hdr, h->arena, vac, vn, &vi, (uint32_t)bump, off);
            }
            bump = (uint64_t)off + size;
        }
    }
    free(vac);
    free(frees);
    free(refs);
    hdr->arena_bump = bump < before ? bump : before;
    return before - hdr->arena_bump;
}
#endif

/* Call before anything of the entry being stored is allocated: the key is stored
 * before size++, and a reclaim in between would hand its block out again.
 * A slide moves blocks: no arena pointer or offset survives the call. */
#define SHM_COMPACT_BACKOFF     64u
#define SHM_COMPACT_BACKOFF_MAX (1u << 20)
static void SHM_FN(arena_reclaim)(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    if (!h->arena) return;
    if (hdr->size == 0) {
        /* Even if the bump reads empty: a writer killed among clear()'s plain
         * arena stores can leave lists naming blocks the bump hands out again. */
        h->arena_failed = 0;
        h->compact_backoff = 0;
        h->compact_period = 0;
        shm_arena_reset(hdr);
        return;
    }
#if SHM_HAS_ARENA
    if (!h->arena_failed) return;
    h->arena_failed = 0;
    /* A sixteenth of the entries gone since may have freed what the slide lacked. */
    if (h->compact_backoff && hdr->size < h->compact_size - h->compact_size / 16)
        h->compact_backoff = 0;
    if (h->compact_backoff) { h->compact_backoff--; return; }
    uint64_t got = SHM_FN(arena_compact)(h, 1);
    if (got >= h->arena_need) {
        h->compact_period = 0;
    } else if (h->compact_period >= SHM_COMPACT_BACKOFF_MAX / 8) {
        h->compact_period = SHM_COMPACT_BACKOFF_MAX;
    } else {
        h->compact_period = h->compact_period ? h->compact_period * 8 : SHM_COMPACT_BACKOFF;
    }
    h->compact_size = hdr->size;
    h->compact_backoff = h->compact_period;
#endif
}

/* No free slot on a TTL map: flush the expired, take the first freed on the path. */
static uint32_t SHM_FN(insert_slot)(ShmHandle *h, uint32_t pos, uint32_t mask, uint32_t insert_pos) {
    if (insert_pos != UINT32_MAX || !h->expires_at || !SHM_FN(reclaim_expired)(h, 1, SHM_LRU_NONE))
        return insert_pos;
    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        if (!SHM_IS_LIVE(h->states[idx])) return idx;
    }
    return UINT32_MAX;
}

/* ---- Resize (elastic grow/shrink) ----
 * In place and restartable: the rz_* record and the table decide at every
 * instruction boundary how to finish; a dead writer's successor reruns rz_run. */

/* Complete a committed move: repoint the LRU neighbours at dst, then free src. */
static inline __attribute__((always_inline))
void SHM_FN(rz_settle)(ShmHandle *h, uint32_t src, uint32_t dst) {
    ShmHeader *hdr = h->hdr;
    if (h->lru_prev) {
        uint32_t p = h->lru_prev[dst], n = h->lru_next[dst];
        if (p != SHM_LRU_NONE) h->lru_next[p] = dst;
        else if (hdr->lru_head == src) hdr->lru_head = dst;
        if (n != SHM_LRU_NONE) h->lru_prev[n] = dst;
        else if (hdr->lru_tail == src) hdr->lru_tail = dst;
    }
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    h->states[src] = SHM_EMPTY;
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    if (h->expires_at) h->expires_at[src] = 0;
    if (h->lru_prev) {
        h->lru_prev[src] = h->lru_next[src] = SHM_LRU_NONE;
        if (h->lru_accessed) h->lru_accessed[src] = 0;
    }
}

/* The record names the move before the copy; states[dst] leaving SHM_EMPTY commits it. */
static inline __attribute__((always_inline))
void SHM_FN(rz_move)(ShmHandle *h, uint32_t src, uint32_t dst, uint8_t st) {
    if (src != dst) {
        SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
        __atomic_store_n(&h->hdr->rz_move, (uint64_t)src | (uint64_t)dst << 32, __ATOMIC_RELAXED);
        __atomic_signal_fence(__ATOMIC_SEQ_CST);
        nodes[dst] = nodes[src];
        if (h->expires_at) h->expires_at[dst] = h->expires_at[src];
        if (h->lru_prev) {
            h->lru_prev[dst] = h->lru_prev[src];
            h->lru_next[dst] = h->lru_next[src];
            if (h->lru_accessed)
                h->lru_accessed[dst] = __atomic_load_n(&h->lru_accessed[src], __ATOMIC_RELAXED);
        }
    }
    shm_publish_tag(h->states, dst, st);
    if (src != dst) {
        __atomic_signal_fence(__ATOMIC_SEQ_CST);
        SHM_FN(rz_settle)(h, src, dst);
    }
}

/* A target held by an entry still to move is vacated by parking that entry in a
 * free slot, placed next.  0 (no free slot) only on a record resize() did not write. */
static int SHM_FN(rz_place)(ShmHandle *h, uint32_t s, uint32_t mask,
                            uint32_t work, uint32_t *spare) {
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    for (;;) {
        uint32_t hash = SHM_FN(node_hash)(h, &nodes[s]);
        uint32_t t = hash & mask, n = 0;
        while (SHM_IS_LIVE(states[t])) {
            if (n++ > mask) return 0;
            t = (t + 1) & mask;
        }
        if (t == s || states[t] == SHM_EMPTY) {
            SHM_FN(rz_move)(h, s, t, SHM_MAKE_TAG(hash));
            return 1;
        }
        uint32_t e = *spare;
        for (n = 0; states[e] != SHM_EMPTY; e = e + 1 < work ? e + 1 : 0)
            if (n++ >= work) return 0;
        *spare = e;
        if (e < hdr->rz_cursor) __atomic_store_n(&hdr->rz_cursor, e, __ATOMIC_RELAXED);
        SHM_FN(rz_move)(h, t, e, SHM_MOVE);
        SHM_FN(rz_move)(h, s, t, SHM_MAKE_TAG(hash));
        s = e;
    }
}

static void SHM_FN(rz_run)(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    uint8_t *states = h->states;
    uint8_t phase = __atomic_load_n(&hdr->rz_phase, __ATOMIC_ACQUIRE);
    if (phase == SHM_RZ_NONE) return;
    if (phase == SHM_RZ_CLEAR) {
        if (hdr->rz_seq == __atomic_load_n(&hdr->seq, __ATOMIC_RELAXED))
            shm_clear_run(h);
        else
            __atomic_store_n(&hdr->rz_phase, SHM_RZ_NONE, __ATOMIC_RELEASE);
        return;
    }
    uint8_t ol = hdr->rz_old_log2, nl = hdr->rz_new_log2;
    uint32_t old_cap = ol < 32 ? 1u << ol : 0, new_cap = nl < 32 ? 1u << nl : 0;
    uint32_t work = old_cap > new_cap ? old_cap : new_cap;
    /* Drop a record that cannot be followed within the table, or a stale one:
     * only the write section that recorded it is still at its seq.  table_cap
     * changes last. */
    uint32_t cap = hdr->table_cap;
    if (phase > SHM_RZ_PLACE || hdr->rz_seq != __atomic_load_n(&hdr->seq, __ATOMIC_RELAXED) ||
        !shm_rz_cap_ok(old_cap, h->max_mask) || !shm_rz_cap_ok(new_cap, h->max_mask) ||
        (cap != old_cap && cap != new_cap)) {
        __atomic_store_n(&hdr->rz_phase, SHM_RZ_NONE, __ATOMIC_RELEASE);
        return;
    }
#ifndef SHM_KEY_IS_INT
    if (hdr->arena_bump >= SHM_SIG_HOLD_BYTES) shm_sig_hold(h, SHM_SIG_HOLD_MIN);
#endif
    if (phase == SHM_RZ_CLEAN) {
        __atomic_store_n(&hdr->tombstones, 0, __ATOMIC_RELAXED);
        shm_states_clean(states, old_cap);
        if (new_cap > old_cap) memset(states + old_cap, SHM_EMPTY, new_cap - old_cap);
        __atomic_signal_fence(__ATOMIC_SEQ_CST);
        __atomic_store_n(&hdr->rz_phase, phase = SHM_RZ_MARK, __ATOMIC_RELEASE);
        __atomic_signal_fence(__ATOMIC_SEQ_CST);
    }
    if (phase == SHM_RZ_MARK) {
        shm_states_mark(states, old_cap);
        __atomic_signal_fence(__ATOMIC_SEQ_CST);
        __atomic_store_n(&hdr->rz_phase, SHM_RZ_PLACE, __ATOMIC_RELEASE);
        __atomic_signal_fence(__ATOMIC_SEQ_CST);
    }
    uint64_t mv = __atomic_load_n(&hdr->rz_move, __ATOMIC_RELAXED);
    uint32_t src = (uint32_t)mv, dst = (uint32_t)(mv >> 32);
    if (src != dst && src < work && dst < work && states[dst] != SHM_EMPTY)
        SHM_FN(rz_settle)(h, src, dst);
    uint32_t spare = new_cap > old_cap ? old_cap : 0;
    uint32_t i = hdr->rz_cursor;
    if (i > work) i = 0;
    /* Only a run resumed in PLACE can find an entry to move above old_cap. */
    uint32_t scan = phase == SHM_RZ_PLACE ? work : old_cap;
#ifndef SHM_KEY_IS_INT
    const int prefetch = work >= SHM_RZ_PREFETCH_MIN;
#endif
    while (i < scan) {
        uint32_t stop = (i | SHM_SIG_CHECK_SLOTS) + 1;
        if (stop > scan) stop = scan;
        for (; i < stop; i++) {
#ifndef SHM_KEY_IS_INT
            uint32_t j = i + SHM_RZ_PREFETCH_AHEAD;
            if (prefetch && j < scan && states[j] == SHM_MOVE) {
                const SHM_NODE_TYPE *nd = (const SHM_NODE_TYPE *)h->nodes + j;
                if (!SHM_IS_INLINE(nd->key_len)) __builtin_prefetch(h->arena + nd->key_off);
            }
#endif
            if (states[i] != SHM_MOVE) continue;
            if (!SHM_FN(rz_place)(h, i, new_cap - 1, work, &spare)) {
                __atomic_store_n(&hdr->rz_phase, SHM_RZ_NONE, __ATOMIC_RELEASE);
                return;
            }
            __atomic_store_n(&hdr->rz_cursor, i + 1, __ATOMIC_RELAXED);
        }
        shm_sig_check(h);
    }
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    __atomic_store_n(&hdr->table_cap, new_cap, __ATOMIC_RELEASE);
    /* Rehashing can move an expired entry behind a partial flush's cursor. */
    if (h->expires_at) hdr->flush_cursor = 0;
    hdr->table_gen++;
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    __atomic_store_n(&hdr->rz_phase, SHM_RZ_NONE, __ATOMIC_RELEASE);
}

static int SHM_FN(resize)(ShmHandle *h, uint32_t new_cap) {
    ShmHeader *hdr = h->hdr;
    uint32_t old_cap = hdr->table_cap, live;
    if (!shm_rz_cap_ok(old_cap, h->max_mask) || !shm_rz_cap_ok(new_cap, h->max_mask)) return 0;
    shm_sig_hold(h, old_cap > new_cap ? old_cap : new_cap);
    live = shm_count_live(h->states, old_cap);
    /* Placement needs a free slot to park in. */
    if (live >= new_cap) return 0;
    if (live == 0) {
        /* No record needed: the table is a whole empty one after each store. */
        memset(h->states, SHM_EMPTY, old_cap > new_cap ? old_cap : new_cap);
        __atomic_store_n(&hdr->tombstones, 0, __ATOMIC_RELAXED);
        __atomic_signal_fence(__ATOMIC_SEQ_CST);
        __atomic_store_n(&hdr->table_cap, new_cap, __ATOMIC_RELEASE);
        if (h->expires_at) hdr->flush_cursor = 0;
        hdr->table_gen++;
        return 1;
    }
    hdr->rz_old_log2 = (uint8_t)__builtin_ctz(old_cap);
    hdr->rz_new_log2 = (uint8_t)__builtin_ctz(new_cap);
    hdr->rz_seq = __atomic_load_n(&hdr->seq, __ATOMIC_RELAXED);
    hdr->rz_move = 0;
    hdr->rz_cursor = 0;
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    __atomic_store_n(&hdr->rz_phase, SHM_RZ_CLEAN, __ATOMIC_RELEASE);
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    SHM_FN(rz_run)(h);
    return 1;
}

static __attribute__((noinline)) void SHM_FN(grow_or_compact)(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    uint32_t size = hdr->size, tomb = hdr->tombstones, cap = hdr->table_cap;
    if (shm_over_load(size, tomb, cap)) {
        if (h->expires_at && SHM_FN(reclaim_expired)(h, 0, SHM_LRU_NONE) != 0) {
            size = hdr->size;
            tomb = hdr->tombstones;
        }
        /* Grow even while iterating (iterators reset on the table_gen bump), or an
         * abandoned each() wedges the table; compaction and shrink stay deferred. */
        if (h->expires_at && tomb >= cap / 16 && !shm_over_load(size, 0, cap) && h->iterating == 0)
            SHM_FN(resize)(h, cap);
        else if (cap < hdr->max_table_cap)
            SHM_FN(resize)(h, cap * 2);
        else if (shm_needs_compaction(size, tomb, cap))
            SHM_FN(resize)(h, cap);
    } else if (shm_needs_compaction(size, tomb, cap)) {
        if (h->iterating > 0) { h->deferred = 1; return; }
        SHM_FN(resize)(h, cap);
    }
}

static inline __attribute__((always_inline)) void SHM_FN(maybe_grow)(ShmHandle *h) {
    const ShmHeader *hdr = h->hdr;
    uint32_t size = hdr->size, tomb = hdr->tombstones, cap = hdr->table_cap;
    if (__builtin_expect(shm_over_load(size, tomb, cap) || shm_needs_compaction(size, tomb, cap), 0))
        SHM_FN(grow_or_compact)(h);
}

static inline void SHM_FN(maybe_shrink)(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    if (__builtin_expect(shm_under_load(hdr->size, hdr->table_cap), 0)) {
        if (h->iterating > 0) { h->deferred = 1; return; }
        SHM_FN(resize)(h, shm_shrink_target(hdr->size, hdr->table_cap));
    }
}

static inline void SHM_FN(flush_deferred)(ShmHandle *h) {
    if (!h || !h->deferred || h->iterating > 0) return;
    h->deferred = 0;
    /* A deferred resize outlives freeze(), and no caller here has a frozen guard. */
    if (h->readonly || shm_is_sealed(h)) return;
    ShmHeader *hdr = h->hdr;
    shm_rwlock_wrlock(h);
    /* Re-test under the lock: freeze() seals under it. */
    if (shm_is_sealed(h)) { shm_rwlock_wrunlock(h); return; }
    shm_seqlock_write_begin(&hdr->seq);
    uint32_t size = hdr->size, tomb = hdr->tombstones, cap = hdr->table_cap;
    if (shm_over_load(size, tomb, cap)) {
        if (cap < hdr->max_table_cap)
            SHM_FN(resize)(h, cap * 2);
        else if (shm_needs_compaction(size, tomb, cap))
            SHM_FN(resize)(h, cap);
    } else if (shm_under_load(size, cap)) {
        SHM_FN(resize)(h, shm_shrink_target(size, cap));
    } else if (shm_needs_compaction(size, tomb, cap)) {
        SHM_FN(resize)(h, cap);
    }
    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
}

/* Caller holds wrlock + seqlock.  0 when the arena or table is full. */
static int SHM_FN(put_inner)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8,
#else
    SHM_VAL_INT_TYPE value,
#endif
    uint32_t ttl_sec
) {
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;

    SHM_FN(maybe_grow)(h);
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint32_t insert_pos = UINT32_MAX;

    uint32_t exp_ts = 0;
    if (h->expires_at) {
        uint32_t ttl = (ttl_sec == SHM_TTL_USE_DEFAULT) ? hdr->default_ttl : ttl_sec;
        if (ttl > 0)
            exp_ts = shm_expiry_ts(ttl);
    }

    uint8_t tag = SHM_MAKE_TAG(hash);
    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);

        if (st == SHM_EMPTY) {
            if (insert_pos == UINT32_MAX) insert_pos = idx;
            break;
        }
        if (st == SHM_TOMBSTONE) {
            if (insert_pos == UINT32_MAX) insert_pos = idx;
            continue;
        }
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
#ifdef SHM_VAL_IS_STR
            {
                /* Before old_off is read: a slide may move the old block. */
                SHM_FN(arena_reclaim)(h);
                uint32_t old_off = nodes[idx].val_off;
                uint32_t old_lf = nodes[idx].val_len;
                if (!SHM_FN(store_or_evict)(h, &nodes[idx].val_off, &nodes[idx].val_len, val_str, val_len, val_utf8, idx))
                    return 0;
                shm_str_free(hdr, h->arena, old_off, old_lf);
            }
#else
            __atomic_store_n(&nodes[idx].value, value, __ATOMIC_RELAXED);
#endif
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at) {
                if (ttl_sec != SHM_TTL_USE_DEFAULT || h->expires_at[idx] != 0)
                    h->expires_at[idx] = exp_ts;
            }
            return 1;
        }
    }

    if ((insert_pos = SHM_FN(insert_slot)(h, pos, mask, insert_pos)) == UINT32_MAX)
        return 0;

    SHM_FN(evict_for_insert)(h, SHM_KEY_SLEN(key_len), SHM_VAL_SLEN(val_len));

    int was_tombstone = (states[insert_pos] == SHM_TOMBSTONE);
    SHM_FN(arena_reclaim)(h);

#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!SHM_FN(store_or_evict)(h, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8, SHM_LRU_NONE))
        return 0;
#endif

#ifdef SHM_VAL_IS_STR
    if (!SHM_FN(store_or_evict)(h, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, val_str, val_len, val_utf8, SHM_LRU_NONE)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        return 0;
    }
#else
    __atomic_store_n(&nodes[insert_pos].value, value, __ATOMIC_RELAXED);
#endif

    if (h->expires_at) h->expires_at[insert_pos] = exp_ts;
    shm_publish_tag(states, insert_pos, SHM_MAKE_TAG(hash));
    /* tombstones-- before size++, or a saturated map briefly reads as
     * size + tombstones > table_cap, which an attach refuses. */
    if (was_tombstone) hdr->tombstones--;
    hdr->size++;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);

    return 1;
}

static int SHM_FN(put_impl)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8,
#else
    SHM_VAL_INT_TYPE value,
#endif
    uint32_t ttl_sec
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    shm_rwlock_wrlock(h);
    shm_seqlock_write_begin(&h->hdr->seq);
    int rc = SHM_FN(put_inner)(h,
#ifdef SHM_KEY_IS_INT
        key,
#else
        key_str, key_len, key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
        val_str, val_len, val_utf8,
#else
        value,
#endif
        ttl_sec);
    shm_seqlock_write_end(&h->hdr->seq);
    shm_rwlock_wrunlock(h);
    return rc;
}

static inline int SHM_FN(put)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8
#else
    SHM_VAL_INT_TYPE value
#endif
) {
    return SHM_FN(put_impl)(h,
#ifdef SHM_KEY_IS_INT
        key,
#else
        key_str, key_len, key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
        val_str, val_len, val_utf8,
#else
        value,
#endif
        SHM_TTL_USE_DEFAULT);
}

static inline int SHM_FN(put_ttl)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8,
#else
    SHM_VAL_INT_TYPE value,
#endif
    uint32_t ttl_sec
) {
    if (ttl_sec >= SHM_TTL_USE_DEFAULT - 1) ttl_sec = SHM_TTL_USE_DEFAULT - 2;
    return SHM_FN(put_impl)(h,
#ifdef SHM_KEY_IS_INT
        key,
#else
        key_str, key_len, key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
        val_str, val_len, val_utf8,
#else
        value,
#endif
        ttl_sec);
}

/* ---- Get (seqlock -- lock-free read path) ---- */

#ifndef SHM_KEY_IS_INT
/* -1: arena offset out of bounds (a torn record, or corruption). */
static inline int SHM_FN(key_at)(const ShmHandle *h, const SHM_NODE_TYPE *n,
                                 const char *key_str, uint32_t key_len, uint64_t arena_cap) {
    uint32_t kl_packed = n->key_len;
    uint32_t kl = SHM_STR_LEN(kl_packed);
    if (kl != key_len) return 0;
    if (SHM_IS_INLINE(kl_packed)) {
        char ibuf[SHM_INLINE_MAX];
        shm_inline_read(n->key_off, kl_packed, ibuf);
        return memcmp(ibuf, key_str, kl) == 0;
    }
    uint32_t koff = n->key_off;
    if (koff < SHM_ARENA_MIN_ALLOC || (uint64_t)koff + kl > arena_cap) return -1;
    return memcmp(h->arena + koff, key_str, kl) == 0;
}
#endif

static inline uint32_t SHM_FN(probe_lockfree)(const ShmHandle *h, uint32_t mask, uint32_t hash,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key
#else
    const char *key_str, uint32_t key_len, uint64_t arena_cap
#endif
) {
    const SHM_NODE_TYPE *nodes = (const SHM_NODE_TYPE *)h->nodes;
    const uint8_t *states = h->states;
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);
    uint32_t i = 0;
    __builtin_prefetch(&nodes[pos], 0, 1);
#ifdef SHM_KEY_IS_INT
#define SHM_PROBE_MATCH(idx) \
    if (SHM_KEY_EQ(&nodes[idx], key)) return (idx)
#else
#define SHM_PROBE_MATCH(idx) do { \
        int r_ = SHM_FN(key_at)(h, &nodes[idx], key_str, key_len, arena_cap); \
        if (r_) return r_ > 0 ? (idx) : UINT32_MAX; \
    } while (0)
#endif
#ifdef __SSE2__
    /* Bound by the clamped mask, never a re-read of the peer-writable table_cap. */
    if (pos + 16 <= mask + 1) {
        uint16_t mmask, emask;
        shm_probe_group(states, pos, tag, &mmask, &emask);
        uint16_t cutoff = emask ? (uint16_t)((1U << __builtin_ctz(emask)) - 1) : 0xFFFF;
        for (uint16_t relevant = mmask & cutoff; relevant; relevant &= relevant - 1) {
            uint32_t idx = pos + (uint32_t)__builtin_ctz(relevant);
            SHM_PROBE_MATCH(idx);
        }
        if (emask) return UINT32_MAX;
        i = 16;
    }
#endif
    for (; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
        SHM_PROBE_MATCH(idx);
    }
#undef SHM_PROBE_MATCH
    return UINT32_MAX;
}

static int SHM_FN(get)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char **out_str, uint32_t *out_len, bool *out_utf8
#else
    SHM_VAL_INT_TYPE *out_value
#endif
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
#ifndef SHM_KEY_IS_INT
    (void)key_utf8;
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint32_t max_mask = h->max_mask;
#if !defined(SHM_KEY_IS_INT) || defined(SHM_VAL_IS_STR)
    uint64_t arena_cap = hdr->arena_cap;
#endif
#ifndef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#else
    uint32_t hash = SHM_HASH_KEY(key);
#endif

    int locked = 0;
#define SHM_GET_RETURN(v) do { if (locked) shm_rwlock_rdunlock(h); return (v); } while (0)
    for (int pass = 0; ; pass++) {
        if (pass == SHM_READ_TRIES_UNLOCKED && !h->readonly) {
            shm_rwlock_rdlock(h);
            locked = 1;
        }
        uint32_t seq = shm_seqlock_read_begin(h);

        uint32_t mask = (hdr->table_cap - 1) & max_mask;
        if (h->expires_at) __builtin_prefetch(&h->expires_at[hash & mask], 0, 1);
        if (h->lru_accessed) __builtin_prefetch(&h->lru_accessed[hash & mask], 0, 1);
#ifdef SHM_KEY_IS_INT
        uint32_t local_idx = SHM_FN(probe_lockfree)(h, mask, hash, key);
#else
        uint32_t local_idx = SHM_FN(probe_lockfree)(h, mask, hash, key_str, key_len, arena_cap);
#endif
        int found = local_idx != UINT32_MAX;
        if (found && h->expires_at) {
            uint32_t exp = h->expires_at[local_idx];
            if (exp != 0 && shm_now() >= exp) found = 0;
        }

        if (found) {
#ifdef SHM_VAL_IS_STR
            uint32_t local_vlen_packed = nodes[local_idx].val_len;
            uint32_t local_vl = SHM_STR_LEN(local_vlen_packed);
            uint32_t local_voff = nodes[local_idx].val_off;
            if (SHM_IS_INLINE(local_vlen_packed)) {
                if (local_vl > h->copy_buf_size || !h->copy_buf) {
                    if (!shm_ensure_copy_buf(h, local_vl > 0 ? local_vl : 1)) SHM_GET_RETURN(0);
                    continue;
                }
                shm_inline_read(local_voff, local_vlen_packed, h->copy_buf);
            } else {
                if (local_voff < SHM_ARENA_MIN_ALLOC || (uint64_t)local_voff + local_vl > arena_cap) {
                    /* Retry only if seq moved (torn); stable corruption reads as zeros. */
                    if (shm_seqlock_read_retry(&hdr->seq, seq)) continue;
                    if (local_vl > h->copy_buf_size || !h->copy_buf) {
                        if (!shm_ensure_copy_buf(h, local_vl > 0 ? local_vl : 1)) SHM_GET_RETURN(0);
                        continue;
                    }
                    memset(h->copy_buf, 0, local_vl);
                } else {
                    if (local_vl > h->copy_buf_size || !h->copy_buf) {
                        if (!shm_ensure_copy_buf(h, local_vl > 0 ? local_vl : 1)) SHM_GET_RETURN(0);
                        continue;
                    }
                    memcpy(h->copy_buf, h->arena + local_voff, local_vl);
                }
            }
#else
            SHM_VAL_INT_TYPE local_value = __atomic_load_n(&nodes[local_idx].value, __ATOMIC_RELAXED);
#endif
            if (shm_seqlock_read_retry(&hdr->seq, seq)) {
#ifdef SHM_VAL_IS_STR
                if (local_vl >= SHM_READ_TORN_BIG && pass < SHM_READ_TRIES_UNLOCKED - 1)
                    pass = SHM_READ_TRIES_UNLOCKED - 1;
#endif
                continue;
            }

            shm_lru_mark(h, local_idx);
#ifdef SHM_VAL_IS_STR
            *out_str = h->copy_buf;
            *out_len = local_vl;
            *out_utf8 = SHM_UNPACK_UTF8(local_vlen_packed);
#else
            *out_value = local_value;
#endif
            SHM_GET_RETURN(1);
        }

        if (shm_seqlock_read_retry(&hdr->seq, seq)) continue;
        SHM_GET_RETURN(0);
    }
#undef SHM_GET_RETURN
}

static int SHM_FN(exists)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key
#else
    const char *key_str, uint32_t key_len, bool key_utf8
#endif
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
#ifndef SHM_KEY_IS_INT
    (void)key_utf8;
#endif
    ShmHeader *hdr = h->hdr;
    uint32_t max_mask = h->max_mask;
#ifndef SHM_KEY_IS_INT
    uint64_t arena_cap = hdr->arena_cap;
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#else
    uint32_t hash = SHM_HASH_KEY(key);
#endif

    int locked = 0;
    for (int pass = 0; ; pass++) {
        if (pass == SHM_READ_TRIES_UNLOCKED && !h->readonly) {
            shm_rwlock_rdlock(h);
            locked = 1;
        }
        uint32_t seq = shm_seqlock_read_begin(h);

        uint32_t mask = (hdr->table_cap - 1) & max_mask;
        if (h->expires_at) __builtin_prefetch(&h->expires_at[hash & mask], 0, 1);
#ifdef SHM_KEY_IS_INT
        uint32_t idx = SHM_FN(probe_lockfree)(h, mask, hash, key);
#else
        uint32_t idx = SHM_FN(probe_lockfree)(h, mask, hash, key_str, key_len, arena_cap);
#endif
        int found = idx != UINT32_MAX;
        if (found && h->expires_at) {
            uint32_t exp = h->expires_at[idx];
            if (exp != 0 && shm_now() >= exp) found = 0;
        }

        if (shm_seqlock_read_retry(&hdr->seq, seq)) continue;
        if (locked) shm_rwlock_rdunlock(h);
        return found;
    }
}

/* Caller holds wrlock + seqlock on the dispatched shard. */
static int SHM_FN(remove_inner)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key
#else
    const char *key_str, uint32_t key_len, bool key_utf8
#endif
) {
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t now = h->expires_at ? shm_now() : 0;
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);
    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) return 0;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            /* Expired is absent, as every other operation reports it. */
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                return 0;
            }
            SHM_FN(remove_at)(h, idx);
            return 1;
        }
    }
    return 0;
}

static int SHM_FN(remove)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key
#else
    const char *key_str, uint32_t key_len, bool key_utf8
#endif
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    shm_rwlock_wrlock(h);
    shm_seqlock_write_begin(&hdr->seq);
    int rc = SHM_FN(remove_inner)(h,
#ifdef SHM_KEY_IS_INT
        key
#else
        key_str, key_len, key_utf8
#endif
    );
    if (rc) SHM_FN(maybe_shrink)(h);
    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return rc;
}

/* ---- Add: 1 inserted, 0 present or full ---- */

static int SHM_FN(add_impl)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8,
#else
    SHM_VAL_INT_TYPE value,
#endif
    uint32_t ttl_sec
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    SHM_FN(maybe_grow)(h);
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);
    uint32_t insert_pos = UINT32_MAX;

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) {
            if (insert_pos == UINT32_MAX) insert_pos = idx;
            break;
        }
        if (st == SHM_TOMBSTONE) {
            if (insert_pos == UINT32_MAX) insert_pos = idx;
            continue;
        }
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                if (insert_pos == UINT32_MAX) insert_pos = idx;
                break;
            }
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 0;
        }
    }

    if ((insert_pos = SHM_FN(insert_slot)(h, pos, mask, insert_pos)) == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }

    SHM_FN(evict_for_insert)(h, SHM_KEY_SLEN(key_len), SHM_VAL_SLEN(val_len));

    int was_tombstone = (states[insert_pos] == SHM_TOMBSTONE);
    SHM_FN(arena_reclaim)(h);
#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!SHM_FN(store_or_evict)(h, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8, SHM_LRU_NONE)) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }
#endif
#ifdef SHM_VAL_IS_STR
    if (!SHM_FN(store_or_evict)(h, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, val_str, val_len, val_utf8, SHM_LRU_NONE)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }
#else
    __atomic_store_n(&nodes[insert_pos].value, value, __ATOMIC_RELAXED);
#endif
    if (h->expires_at) {
        uint32_t ttl = (ttl_sec == SHM_TTL_USE_DEFAULT) ? hdr->default_ttl : ttl_sec;
        h->expires_at[insert_pos] = ttl > 0 ? shm_expiry_ts(ttl) : 0;
    }
    shm_publish_tag(states, insert_pos, SHM_MAKE_TAG(hash));
    /* tombstones-- before size++: see put_inner */
    if (was_tombstone) hdr->tombstones--;
    hdr->size++;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return 1;
}

static inline int SHM_FN(add)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8
#else
    SHM_VAL_INT_TYPE value
#endif
) {
    return SHM_FN(add_impl)(h,
#ifdef SHM_KEY_IS_INT
        key,
#else
        key_str, key_len, key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
        val_str, val_len, val_utf8,
#else
        value,
#endif
        SHM_TTL_USE_DEFAULT);
}

static inline int SHM_FN(add_ttl)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8,
#else
    SHM_VAL_INT_TYPE value,
#endif
    uint32_t ttl_sec
) {
    if (ttl_sec >= SHM_TTL_USE_DEFAULT - 1) ttl_sec = SHM_TTL_USE_DEFAULT - 2;
    return SHM_FN(add_impl)(h,
#ifdef SHM_KEY_IS_INT
        key,
#else
        key_str, key_len, key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
        val_str, val_len, val_utf8,
#else
        value,
#endif
        ttl_sec);
}

/* ---- Update: 1 updated, 0 absent or full ---- */

static int SHM_FN(update_impl)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8,
#else
    SHM_VAL_INT_TYPE value,
#endif
    uint32_t ttl_sec
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
#ifdef SHM_VAL_IS_STR
            {
                SHM_FN(arena_reclaim)(h);
                uint32_t old_off = nodes[idx].val_off;
                uint32_t old_lf = nodes[idx].val_len;
                if (!SHM_FN(store_or_evict)(h, &nodes[idx].val_off, &nodes[idx].val_len, val_str, val_len, val_utf8, idx)) {
                    shm_seqlock_write_end(&hdr->seq);
                    shm_rwlock_wrunlock(h);
                    return 0;
                }
                shm_str_free(hdr, h->arena, old_off, old_lf);
            }
#else
            __atomic_store_n(&nodes[idx].value, value, __ATOMIC_RELAXED);
#endif
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at) {
                if (ttl_sec == SHM_TTL_USE_DEFAULT) {
                    if (hdr->default_ttl > 0 && h->expires_at[idx] != 0)
                        h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);
                } else {
                    h->expires_at[idx] = ttl_sec > 0 ? shm_expiry_ts(ttl_sec) : 0;
                }
            }

            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return 0;
}

static inline int SHM_FN(update)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8
#else
    SHM_VAL_INT_TYPE value
#endif
) {
    return SHM_FN(update_impl)(h,
#ifdef SHM_KEY_IS_INT
        key,
#else
        key_str, key_len, key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
        val_str, val_len, val_utf8,
#else
        value,
#endif
        SHM_TTL_USE_DEFAULT);
}

static inline int SHM_FN(update_ttl)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8,
#else
    SHM_VAL_INT_TYPE value,
#endif
    uint32_t ttl_sec
) {
    if (ttl_sec >= SHM_TTL_USE_DEFAULT - 1) ttl_sec = SHM_TTL_USE_DEFAULT - 2;
    return SHM_FN(update_impl)(h,
#ifdef SHM_KEY_IS_INT
        key,
#else
        key_str, key_len, key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
        val_str, val_len, val_utf8,
#else
        value,
#endif
        ttl_sec);
}

/* ---- Swap: 1 replaced (old value out), 2 inserted, 0 full ---- */

static int SHM_FN(swap)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *val_str, uint32_t val_len, bool val_utf8,
    const char **out_str, uint32_t *out_len, bool *out_utf8
#else
    SHM_VAL_INT_TYPE value,
    SHM_VAL_INT_TYPE *out_value
#endif
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    SHM_FN(maybe_grow)(h);
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);
    uint32_t insert_pos = UINT32_MAX;

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) {
            if (insert_pos == UINT32_MAX) insert_pos = idx;
            break;
        }
        if (st == SHM_TOMBSTONE) {
            if (insert_pos == UINT32_MAX) insert_pos = idx;
            continue;
        }
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                if (insert_pos == UINT32_MAX) insert_pos = idx;
                break;
            }
#ifdef SHM_VAL_IS_STR
            {
                uint32_t old_vl = SHM_STR_LEN(nodes[idx].val_len);
                shm_sig_hold_bytes(h, old_vl);
                if (!shm_ensure_copy_buf(h, old_vl)) {
                    shm_seqlock_write_end(&hdr->seq);
                    shm_rwlock_wrunlock(h);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, old_vl);
                *out_str = h->copy_buf;
                *out_len = old_vl;
                *out_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);

                {
                    SHM_FN(arena_reclaim)(h);   /* the old value is already in copy_buf */
                    uint32_t old_off = nodes[idx].val_off;
                    uint32_t old_lf = nodes[idx].val_len;
                    if (!SHM_FN(store_or_evict)(h, &nodes[idx].val_off, &nodes[idx].val_len, val_str, val_len, val_utf8, idx)) {
                        shm_seqlock_write_end(&hdr->seq);
                        shm_rwlock_wrunlock(h);
                        return 0;
                    }
                    shm_str_free(hdr, h->arena, old_off, old_lf);
                }
            }
#else
            *out_value = __atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED);
            __atomic_store_n(&nodes[idx].value, value, __ATOMIC_RELAXED);
#endif
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[idx] != 0)
                h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);

            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    if ((insert_pos = SHM_FN(insert_slot)(h, pos, mask, insert_pos)) == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }

    SHM_FN(evict_for_insert)(h, SHM_KEY_SLEN(key_len), SHM_VAL_SLEN(val_len));

    int was_tombstone = (states[insert_pos] == SHM_TOMBSTONE);
    SHM_FN(arena_reclaim)(h);
#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!SHM_FN(store_or_evict)(h, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8, SHM_LRU_NONE)) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }
#endif
#ifdef SHM_VAL_IS_STR
    if (!SHM_FN(store_or_evict)(h, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, val_str, val_len, val_utf8, SHM_LRU_NONE)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }
#else
    __atomic_store_n(&nodes[insert_pos].value, value, __ATOMIC_RELAXED);
#endif
    if (h->expires_at) {
        uint32_t ttl = hdr->default_ttl;
        h->expires_at[insert_pos] = ttl > 0 ? shm_expiry_ts(ttl) : 0;
    }
    shm_publish_tag(states, insert_pos, SHM_MAKE_TAG(hash));
    /* tombstones-- before size++: see put_inner */
    if (was_tombstone) hdr->tombstones--;
    hdr->size++;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return 2;
}

static int SHM_FN(take)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char **out_str, uint32_t *out_len, bool *out_utf8
#else
    SHM_VAL_INT_TYPE *out_value
#endif
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;

#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }

#ifdef SHM_VAL_IS_STR
            {
                uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
                shm_sig_hold_bytes(h, vl);
                if (!shm_ensure_copy_buf(h, vl)) {
                    shm_seqlock_write_end(&hdr->seq);
                    shm_rwlock_wrunlock(h);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, vl);
                *out_str = h->copy_buf;
                *out_len = vl;
                *out_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
            }
#else
            *out_value = __atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED);
#endif
            SHM_FN(remove_at)(h, idx);

            SHM_FN(maybe_shrink)(h);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return 0;
}

/* ---- Compare-and-take: 1 if the value matched and the entry was removed ----
 * String values compare by bytes only. */
static int SHM_FN(cas_take)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *expected_str, uint32_t expected_len,
    const char **out_str, uint32_t *out_len, bool *out_utf8
#else
    SHM_VAL_INT_TYPE expected, SHM_VAL_INT_TYPE *out_value
#endif
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
#ifdef SHM_VAL_IS_STR
            char ibuf[SHM_INLINE_MAX];
            uint32_t cur_len;
            const char *cur_str = shm_str_ptr(nodes[idx].val_off, nodes[idx].val_len,
                                              h->arena, h->hdr->arena_cap, ibuf, &cur_len);
            if (cur_len == expected_len) shm_sig_hold_bytes(h, cur_len);
            if (cur_len != expected_len || memcmp(cur_str, expected_str, cur_len) != 0) {
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            if (!shm_ensure_copy_buf(h, cur_len)) {
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            memcpy(h->copy_buf, cur_str, cur_len);
            *out_str = h->copy_buf;
            *out_len = cur_len;
            *out_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
#else
            if (__atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED) != expected) {
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            *out_value = __atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED);
#endif
            SHM_FN(remove_at)(h, idx);
            SHM_FN(maybe_shrink)(h);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return 0;
}

/* ---- Pop: the LRU tail, else the next live slot from pop_cursor ---- */

static int SHM_FN(pop)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE *out_key,
#else
    const char **out_key_str, uint32_t *out_key_len, bool *out_key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char **out_val_str, uint32_t *out_val_len, bool *out_val_utf8
#else
    SHM_VAL_INT_TYPE *out_value
#endif
) {
    if (h->shard_handles) {
        for (uint32_t i = 0; i < h->num_shards; i++) {
            uint32_t si = (h->shard_rr + i) % h->num_shards;
            int rc = SHM_FN(pop)(h->shard_handles[si],
#ifdef SHM_KEY_IS_INT
                out_key,
#else
                out_key_str, out_key_len, out_key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
                out_val_str, out_val_len, out_val_utf8
#else
                out_value
#endif
            );
            if (rc) { h->shard_rr = (si + 1) % h->num_shards; return 1; }
        }
        return 0;
    }
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t idx = UINT32_MAX, size0 = hdr->size;
    if (h->lru_prev && hdr->lru_tail != SHM_LRU_NONE) {
        uint32_t pos = hdr->lru_tail;
        while (pos != SHM_LRU_NONE) {
            if (!SHM_IS_EXPIRED(h, pos, now)) { idx = pos; break; }
            uint32_t prev = h->lru_prev[pos];
            shm_sig_check(h);
            SHM_FN(expire_at)(h, pos);
            pos = prev;
        }
    } else {
        uint32_t cap = hdr->table_cap;
        uint32_t start = hdr->pop_cursor < cap ? hdr->pop_cursor : 0;
        for (uint32_t n = 0; n < cap; n++) {
            uint32_t i = (start + n) % cap;
            shm_sig_check_every(h, n + 1, SHM_SIG_CHECK_SLOTS);
            if (!SHM_IS_LIVE(states[i])) continue;
            if (SHM_IS_EXPIRED(h, i, now)) {
                shm_sig_check(h);
                SHM_FN(expire_at)(h, i);
                continue;
            }
            idx = i;
            hdr->pop_cursor = (i + 1) % cap;
            break;
        }
    }

    if (idx == UINT32_MAX) {
        if (hdr->size != size0) SHM_FN(maybe_shrink)(h);
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }

#ifdef SHM_KEY_IS_INT
    *out_key = nodes[idx].key;
#else
    {
        uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
        shm_sig_hold_bytes(h, kl);
        if (!shm_ensure_copy_buf(h, kl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 0;
        }
        shm_str_copy(h->copy_buf, nodes[idx].key_off, nodes[idx].key_len, h->arena, h->hdr->arena_cap, kl);
        *out_key_str = h->copy_buf;
        *out_key_len = kl;
        *out_key_utf8 = SHM_UNPACK_UTF8(nodes[idx].key_len);
    }
#endif
#ifdef SHM_VAL_IS_STR
    {
        uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
        shm_sig_hold_bytes(h, vl);
#ifndef SHM_KEY_IS_INT
        uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
        /* Value after the key; realloc may move the key too. */
        if (!shm_ensure_copy_buf(h, kl + vl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 0;
        }
        *out_key_str = h->copy_buf;
        shm_str_copy(h->copy_buf + kl, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, vl);
        *out_val_str = h->copy_buf + kl;
#else
        if (!shm_ensure_copy_buf(h, vl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 0;
        }
        shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, vl);
        *out_val_str = h->copy_buf;
#endif
        *out_val_len = vl;
        *out_val_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
    }
#else
    *out_value = __atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED);
#endif

    SHM_FN(remove_at)(h, idx);
    SHM_FN(maybe_shrink)(h);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return 1;
}

/* ---- Shift: the LRU head, else the next live slot below shift_cursor ---- */

static int SHM_FN(shift)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE *out_key,
#else
    const char **out_key_str, uint32_t *out_key_len, bool *out_key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char **out_val_str, uint32_t *out_val_len, bool *out_val_utf8
#else
    SHM_VAL_INT_TYPE *out_value
#endif
) {
    if (h->shard_handles) {
        for (uint32_t i = 0; i < h->num_shards; i++) {
            uint32_t si = (h->shard_rr + i) % h->num_shards;
            int rc = SHM_FN(shift)(h->shard_handles[si],
#ifdef SHM_KEY_IS_INT
                out_key,
#else
                out_key_str, out_key_len, out_key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
                out_val_str, out_val_len, out_val_utf8
#else
                out_value
#endif
            );
            if (rc) { h->shard_rr = (si + 1) % h->num_shards; return 1; }
        }
        return 0;
    }
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t idx = UINT32_MAX, size0 = hdr->size;
    if (h->lru_prev && hdr->lru_head != SHM_LRU_NONE) {
        uint32_t pos = hdr->lru_head;
        while (pos != SHM_LRU_NONE) {
            if (!SHM_IS_EXPIRED(h, pos, now)) { idx = pos; break; }
            uint32_t nxt = h->lru_next[pos];
            shm_sig_check(h);
            SHM_FN(expire_at)(h, pos);
            pos = nxt;
        }
    } else {
        uint32_t cap = hdr->table_cap;
        uint32_t start = (hdr->shift_cursor == 0 || hdr->shift_cursor > cap) ? cap : hdr->shift_cursor;
        for (uint32_t n = 0; n < cap; n++) {
            uint32_t i = (start + cap - 1 - n) % cap;
            shm_sig_check_every(h, n + 1, SHM_SIG_CHECK_SLOTS);
            if (!SHM_IS_LIVE(states[i])) continue;
            if (SHM_IS_EXPIRED(h, i, now)) {
                shm_sig_check(h);
                SHM_FN(expire_at)(h, i);
                continue;
            }
            idx = i;
            hdr->shift_cursor = i;
            break;
        }
    }

    if (idx == UINT32_MAX) {
        if (hdr->size != size0) SHM_FN(maybe_shrink)(h);
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }

#ifdef SHM_KEY_IS_INT
    *out_key = nodes[idx].key;
#else
    {
        uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
        shm_sig_hold_bytes(h, kl);
        if (!shm_ensure_copy_buf(h, kl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 0;
        }
        shm_str_copy(h->copy_buf, nodes[idx].key_off, nodes[idx].key_len, h->arena, h->hdr->arena_cap, kl);
        *out_key_str = h->copy_buf;
        *out_key_len = kl;
        *out_key_utf8 = SHM_UNPACK_UTF8(nodes[idx].key_len);
    }
#endif
#ifdef SHM_VAL_IS_STR
    {
        uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
        shm_sig_hold_bytes(h, vl);
#ifndef SHM_KEY_IS_INT
        uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
        /* Value after the key; realloc may move the key too. */
        if (!shm_ensure_copy_buf(h, kl + vl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 0;
        }
        *out_key_str = h->copy_buf;
        shm_str_copy(h->copy_buf + kl, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, vl);
        *out_val_str = h->copy_buf + kl;
#else
        if (!shm_ensure_copy_buf(h, vl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 0;
        }
        shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, vl);
        *out_val_str = h->copy_buf;
#endif
        *out_val_len = vl;
        *out_val_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
    }
#else
    *out_value = __atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED);
#endif

    SHM_FN(remove_at)(h, idx);
    SHM_FN(maybe_shrink)(h);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return 1;
}

/* ---- Drain (pop up to N entries, returns count) ---- */

typedef struct {
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key;
#else
    uint32_t key_off;  /* offset into drain_buf */
    uint32_t key_len;
    bool     key_utf8;
#endif
#ifdef SHM_VAL_IS_STR
    uint32_t val_off;  /* offset into drain_buf */
    uint32_t val_len;
    bool     val_utf8;
#else
    SHM_VAL_INT_TYPE value;
#endif
} SHM_PASTE(SHM_PREFIX, drain_entry);

static uint32_t SHM_FN(drain_inner)(ShmHandle *h, uint32_t limit,
    SHM_PASTE(SHM_PREFIX, drain_entry) *out, char **buf, uint32_t *buf_cap,
    uint32_t *buf_used_p) {
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t count = 0;
    uint32_t buf_used = *buf_used_p;
    (void)buf; (void)buf_cap;

    if (limit == 0) return 0;

    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t cap = hdr->table_cap;
    uint32_t cur = hdr->pop_cursor < cap ? hdr->pop_cursor : 0;
    uint32_t scanned = 0, size0 = hdr->size;
    while (count < limit) {
        uint32_t idx = UINT32_MAX;

        if (h->lru_prev && hdr->lru_tail != SHM_LRU_NONE) {
            uint32_t pos = hdr->lru_tail;
            while (pos != SHM_LRU_NONE) {
                if (!SHM_IS_EXPIRED(h, pos, now)) { idx = pos; break; }
                uint32_t prev = h->lru_prev[pos];
                shm_sig_check(h);
                SHM_FN(expire_at)(h, pos);
                pos = prev;
            }
        } else {
            while (scanned < cap) {
                uint32_t i = cur;
                cur = (cur + 1) % cap;
                shm_sig_check_every(h, ++scanned, SHM_SIG_CHECK_SLOTS);
                if (!SHM_IS_LIVE(states[i])) continue;
                if (SHM_IS_EXPIRED(h, i, now)) {
                    shm_sig_check(h);
                    SHM_FN(expire_at)(h, i);
                    continue;
                }
                idx = i;
                break;
            }
        }

        if (idx == UINT32_MAX) break;

#ifdef SHM_KEY_IS_INT
        out[count].key = nodes[idx].key;
#else
        {
            uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
            shm_sig_hold_bytes(h, kl);
            if ((uint64_t)buf_used + kl > UINT32_MAX) break;
            if (!shm_grow_buf(buf, buf_cap, buf_used + kl)) break;
            shm_str_copy(*buf + buf_used, nodes[idx].key_off, nodes[idx].key_len, h->arena, h->hdr->arena_cap, kl);
            out[count].key_off = buf_used;
            out[count].key_len = kl;
            out[count].key_utf8 = SHM_UNPACK_UTF8(nodes[idx].key_len);
            buf_used += kl;
        }
#endif
#ifdef SHM_VAL_IS_STR
        {
            uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
            shm_sig_hold_bytes(h, vl);
            if ((uint64_t)buf_used + vl > UINT32_MAX) break;
            if (!shm_grow_buf(buf, buf_cap, buf_used + vl)) break;
            shm_str_copy(*buf + buf_used, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, vl);
            out[count].val_off = buf_used;
            out[count].val_len = vl;
            out[count].val_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
            buf_used += vl;
        }
#else
        out[count].value = __atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED);
#endif

        SHM_FN(remove_at)(h, idx);
        shm_sig_check_every(h, ++count, SHM_SIG_CHECK_ENTRIES);
    }

    if (!h->lru_prev) hdr->pop_cursor = cur;
    if (hdr->size != size0) SHM_FN(maybe_shrink)(h);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    *buf_used_p = buf_used;
    return count;
}

static uint32_t SHM_FN(drain)(ShmHandle *h, uint32_t limit,
    SHM_PASTE(SHM_PREFIX, drain_entry) *out, char **buf, uint32_t *buf_cap) {
    uint32_t buf_used = 0;
    if (h->shard_handles) {
        uint32_t total = 0;
        for (uint32_t i = 0; i < h->num_shards && total < limit; i++) {
            uint32_t si = (h->shard_rr + i) % h->num_shards;
            uint32_t got = SHM_FN(drain_inner)(h->shard_handles[si], limit - total,
                                                out + total, buf, buf_cap, &buf_used);
            total += got;
        }
        if (total > 0) h->shard_rr = (h->shard_rr + 1) % h->num_shards;
        return total;
    }
    return SHM_FN(drain_inner)(h, limit, out, buf, buf_cap, &buf_used);
}

/* ---- Counter operations, atomic max/min, and integer-value cas ---- */

#ifdef SHM_HAS_COUNTERS

static inline int SHM_FN(find_slot)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
    uint32_t *out_idx) {
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);
    uint32_t probe_start = 0;
    __builtin_prefetch(&nodes[pos], 0, 1);

#ifdef __SSE2__
    if (pos + 16 <= hdr->table_cap) {
        uint16_t mmask, emask;
        shm_probe_group(states, pos, tag, &mmask, &emask);
        uint16_t cutoff = emask ? (uint16_t)((1U << __builtin_ctz(emask)) - 1) : 0xFFFF;
        uint16_t relevant = mmask & cutoff;
        while (relevant) {
            int bit = __builtin_ctz(relevant);
            uint32_t idx = pos + bit;
#ifdef SHM_KEY_IS_INT
            if (SHM_KEY_EQ(&nodes[idx], key)) { *out_idx = idx; return 1; }
#else
            if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) { *out_idx = idx; return 1; }
#endif
            relevant &= relevant - 1;
        }
        if (emask) return 0;
        probe_start = 16;
    }
#endif

    for (uint32_t i = probe_start; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) return 0;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            *out_idx = idx;
            return 1;
        }
    }
    return 0;
}

static SHM_VAL_INT_TYPE SHM_FN(incr_by)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
    SHM_VAL_INT_TYPE delta, int *ok) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;

    /* No LRU or TTL: only the value word changes, which get() reads with one
     * atomic load, so the read lock suffices and seq is not bumped. */
    if (!h->lru_prev && !h->expires_at) {
        shm_rwlock_rdlock(h);
        uint32_t idx;
#ifdef SHM_KEY_IS_INT
        if (SHM_FN(find_slot)(h, key, &idx)) {
#else
        if (SHM_FN(find_slot)(h, key_str, key_len, key_utf8, &idx)) {
#endif
            SHM_VAL_INT_TYPE result =
                __atomic_add_fetch(&nodes[idx].value, delta, __ATOMIC_ACQ_REL);
            shm_rwlock_rdunlock(h);
            *ok = 1;
            return result;
        }
        shm_rwlock_rdunlock(h);
    }

    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    SHM_FN(maybe_grow)(h);
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint32_t insert_pos = UINT32_MAX;

    uint8_t tag = SHM_MAKE_TAG(hash);
    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t slot = (pos + i) & mask;
        uint8_t st = h->states[slot];
        __builtin_prefetch(&nodes[slot], 0, 1);
        __builtin_prefetch(&nodes[(slot + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) {
            if (insert_pos == UINT32_MAX) insert_pos = slot;
            break;
        }
        if (st == SHM_TOMBSTONE) {
            if (insert_pos == UINT32_MAX) insert_pos = slot;
            continue;
        }
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[slot], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[slot], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, slot, now)) {
                SHM_FN(expire_at)(h, slot);
                if (insert_pos == UINT32_MAX) insert_pos = slot;
                break;
            }

            __atomic_add_fetch(&nodes[slot].value, delta, __ATOMIC_RELAXED);
            SHM_VAL_INT_TYPE result = __atomic_load_n(&nodes[slot].value, __ATOMIC_RELAXED);
            if (h->lru_prev) shm_lru_promote(h, slot);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[slot] != 0)
                h->expires_at[slot] = shm_expiry_ts(hdr->default_ttl);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            *ok = 1;
            return result;
        }
    }

    if ((insert_pos = SHM_FN(insert_slot)(h, pos, mask, insert_pos)) == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        *ok = 0;
        return 0;
    }

    SHM_FN(evict_for_insert)(h, SHM_KEY_SLEN(key_len), 0);

    int was_tombstone = (h->states[insert_pos] == SHM_TOMBSTONE);
    SHM_FN(arena_reclaim)(h);
#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!SHM_FN(store_or_evict)(h, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8, SHM_LRU_NONE)) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        *ok = 0;
        return 0;
    }
#endif
    __atomic_store_n(&nodes[insert_pos].value, delta, __ATOMIC_RELAXED);
    if (h->expires_at)
        h->expires_at[insert_pos] = hdr->default_ttl > 0 ? shm_expiry_ts(hdr->default_ttl) : 0;
    shm_publish_tag(h->states, insert_pos, SHM_MAKE_TAG(hash));
    if (was_tombstone) hdr->tombstones--;
    hdr->size++;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    *ok = 1;
    return delta;
}

/* ---- Atomic max / min: returns the stored value; an absent key gets `desired` ---- */
static SHM_VAL_INT_TYPE SHM_FN(set_minmax)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
    SHM_VAL_INT_TYPE desired, int want_max, int *ok) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;

    /* Read-lock fast path, as in incr_by. */
    if (!h->lru_prev && !h->expires_at) {
        shm_rwlock_rdlock(h);
        uint32_t idx;
#ifdef SHM_KEY_IS_INT
        if (SHM_FN(find_slot)(h, key, &idx)) {
#else
        if (SHM_FN(find_slot)(h, key_str, key_len, key_utf8, &idx)) {
#endif
            SHM_VAL_INT_TYPE cur = __atomic_load_n(&nodes[idx].value, __ATOMIC_ACQUIRE);
            while (want_max ? (desired > cur) : (desired < cur)) {
                if (__atomic_compare_exchange_n(&nodes[idx].value, &cur, desired,
                        0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
                    cur = desired;
                    break;
                }
            }
            shm_rwlock_rdunlock(h);
            *ok = 1;
            return cur;
        }
        shm_rwlock_rdunlock(h);
    }

    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    SHM_FN(maybe_grow)(h);
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint32_t insert_pos = UINT32_MAX;

    uint8_t tag = SHM_MAKE_TAG(hash);
    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t slot = (pos + i) & mask;
        uint8_t st = h->states[slot];
        __builtin_prefetch(&nodes[slot], 0, 1);
        __builtin_prefetch(&nodes[(slot + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) {
            if (insert_pos == UINT32_MAX) insert_pos = slot;
            break;
        }
        if (st == SHM_TOMBSTONE) {
            if (insert_pos == UINT32_MAX) insert_pos = slot;
            continue;
        }
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[slot], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[slot], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, slot, now)) {
                SHM_FN(expire_at)(h, slot);
                if (insert_pos == UINT32_MAX) insert_pos = slot;
                break;
            }

            SHM_VAL_INT_TYPE cur = __atomic_load_n(&nodes[slot].value, __ATOMIC_RELAXED);
            SHM_VAL_INT_TYPE result =
                want_max ? (desired > cur ? desired : cur)
                         : (desired < cur ? desired : cur);
            __atomic_store_n(&nodes[slot].value, result, __ATOMIC_RELAXED);
            if (h->lru_prev) shm_lru_promote(h, slot);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[slot] != 0)
                h->expires_at[slot] = shm_expiry_ts(hdr->default_ttl);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            *ok = 1;
            return result;
        }
    }

    if ((insert_pos = SHM_FN(insert_slot)(h, pos, mask, insert_pos)) == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        *ok = 0;
        return 0;
    }

    SHM_FN(evict_for_insert)(h, SHM_KEY_SLEN(key_len), 0);

    int was_tombstone = (h->states[insert_pos] == SHM_TOMBSTONE);
    SHM_FN(arena_reclaim)(h);
#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!SHM_FN(store_or_evict)(h, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8, SHM_LRU_NONE)) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        *ok = 0;
        return 0;
    }
#endif
    __atomic_store_n(&nodes[insert_pos].value, desired, __ATOMIC_RELAXED);
    if (h->expires_at)
        h->expires_at[insert_pos] = hdr->default_ttl > 0 ? shm_expiry_ts(hdr->default_ttl) : 0;
    shm_publish_tag(h->states, insert_pos, SHM_MAKE_TAG(hash));
    if (was_tombstone) hdr->tombstones--;
    hdr->size++;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    *ok = 1;
    return desired;
}

/* ---- Compare-and-swap (atomic, integer-value variants) ---- */

static int SHM_FN(cas)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
    SHM_VAL_INT_TYPE expected, SHM_VAL_INT_TYPE desired
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;

    /* No LRU or TTL: only the value word changes, as in incr_by's fast path. */
    if (!h->lru_prev && !h->expires_at) {
        shm_rwlock_rdlock(h);
        uint32_t idx;
#ifdef SHM_KEY_IS_INT
        int ok = SHM_FN(find_slot)(h, key, &idx);
#else
        int ok = SHM_FN(find_slot)(h, key_str, key_len, key_utf8, &idx);
#endif
        ok = ok && __atomic_compare_exchange_n(&nodes[idx].value, &expected, desired,
                                               0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
        shm_rwlock_rdunlock(h);
        return ok;
    }

    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            if (__atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED) == expected) {
                __atomic_store_n(&nodes[idx].value, desired, __ATOMIC_RELAXED);
                if (h->lru_prev) shm_lru_promote(h, idx);
                if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[idx] != 0)
                    h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 1;
            }
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 0;
        }
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return 0;
}

#endif /* SHM_HAS_COUNTERS */

/* ---- Compare-and-swap (atomic, string-value variants) ---- */

#ifdef SHM_VAL_IS_STR
static int SHM_FN(cas)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
    const char *expected_str, uint32_t expected_len,
    const char *desired_str, uint32_t desired_len, bool desired_utf8
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            char ibuf[SHM_INLINE_MAX];
            uint32_t cur_len;
            const char *cur_str = shm_str_ptr(nodes[idx].val_off, nodes[idx].val_len,
                                              h->arena, h->hdr->arena_cap, ibuf, &cur_len);
            if (cur_len == expected_len) shm_sig_hold_bytes(h, cur_len);
            if (cur_len != expected_len || memcmp(cur_str, expected_str, cur_len) != 0) {
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            SHM_FN(arena_reclaim)(h);   /* cur_str is done with: the compare is above */
            uint32_t old_off = nodes[idx].val_off;
            uint32_t old_lf = nodes[idx].val_len;
            if (!SHM_FN(store_or_evict)(h, &nodes[idx].val_off, &nodes[idx].val_len,
                               desired_str, desired_len, desired_utf8, idx)) {
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            shm_str_free(hdr, h->arena, old_off, old_lf);
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[idx] != 0)
                h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return 0;
}
#endif /* SHM_VAL_IS_STR */

static inline uint64_t SHM_FN(size)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(size)(h->shard_handles[i]);
        return total;
    }
    return __atomic_load_n(&h->hdr->size, __ATOMIC_ACQUIRE);
}

static inline uint64_t SHM_FN(max_entries)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(max_entries)(h->shard_handles[i]);
        return total;
    }
    /* 2^31 * 3 overflows uint32 */
    return (uint64_t)h->hdr->max_table_cap * 3 / 4;
}

static inline uint64_t SHM_FN(max_size)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(max_size)(h->shard_handles[i]);
        return total;
    }
    return h->hdr->max_size;
}

static inline uint32_t SHM_FN(ttl)(ShmHandle *h) {
    if (h->shard_handles) return SHM_FN(ttl)(h->shard_handles[0]);
    return h->hdr->default_ttl;
}

/* *out_ttl_remaining (may be NULL): -1 without TTL, 0 permanent, else seconds left. */
static int SHM_FN(get_with_ttl)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char **out_str, uint32_t *out_len, bool *out_utf8,
#else
    SHM_VAL_INT_TYPE *out_value,
#endif
    int64_t *out_ttl_remaining
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_rdlock(h);
    uint32_t now_ts = h->expires_at ? shm_now() : 0;

    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now_ts)) {
                shm_rwlock_rdunlock(h);
                return 0;
            }
#ifdef SHM_VAL_IS_STR
            {
                uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
                if (!shm_ensure_copy_buf(h, vl)) {
                    shm_rwlock_rdunlock(h);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, vl);
                *out_str = h->copy_buf;
                *out_len = vl;
                *out_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
            }
#else
            *out_value = __atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED);
#endif
            shm_lru_mark(h, idx);
            if (out_ttl_remaining) {
                if (!h->expires_at) *out_ttl_remaining = -1;
                else if (h->expires_at[idx] == 0) *out_ttl_remaining = 0;
                else *out_ttl_remaining = (int64_t)(h->expires_at[idx] - now_ts);
            }
            shm_rwlock_rdunlock(h);
            return 1;
        }
    }

    shm_rwlock_rdunlock(h);
    return 0;
}

/* ---- TTL remaining for a key (-1 = not found/expired, 0 = permanent) ---- */

static int64_t SHM_FN(ttl_remaining)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key
#else
    const char *key_str, uint32_t key_len, bool key_utf8
#endif
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    if (!h->expires_at) return -1;

    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;

    shm_rwlock_rdlock(h);

    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            uint32_t exp = h->expires_at[idx];
            if (exp == 0) {
                shm_rwlock_rdunlock(h);
                return 0;
            }
            uint32_t now = shm_now();
            if (now >= exp) {
                shm_rwlock_rdunlock(h);
                return -1;
            }
            int64_t remaining = (int64_t)(exp - now);
            shm_rwlock_rdunlock(h);
            return remaining;
        }
    }

    shm_rwlock_rdunlock(h);
    return -1;
}

/* expires_at changes under the seqlock: get() reads it lock-free. */

static int SHM_FN(persist)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key
#else
    const char *key_str, uint32_t key_len, bool key_utf8
#endif
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    if (!h->expires_at) return 0;

    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = shm_now();

    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                shm_seqlock_write_begin(&hdr->seq);
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            shm_seqlock_write_begin(&hdr->seq);
            h->expires_at[idx] = 0;
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    shm_rwlock_wrunlock(h);
    return 0;
}

static int SHM_FN(set_ttl)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
    uint32_t ttl_sec
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    if (!h->expires_at) return 0;

    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = shm_now();

    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                shm_seqlock_write_begin(&hdr->seq);
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            shm_seqlock_write_begin(&hdr->seq);
            if (ttl_sec == 0)
                h->expires_at[idx] = 0;
            else
                h->expires_at[idx] = shm_expiry_ts(ttl_sec);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    shm_rwlock_wrunlock(h);
    return 0;
}

static inline uint64_t SHM_FN(capacity)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(capacity)(h->shard_handles[i]);
        return total;
    }
    return __atomic_load_n(&h->hdr->table_cap, __ATOMIC_ACQUIRE);
}

static inline uint64_t SHM_FN(tombstones)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(tombstones)(h->shard_handles[i]);
        return total;
    }
    return __atomic_load_n(&h->hdr->tombstones, __ATOMIC_ACQUIRE);
}

static inline size_t SHM_FN(mmap_size)(ShmHandle *h) {
    if (h->shard_handles) {
        size_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(mmap_size)(h->shard_handles[i]);
        return total;
    }
    return h->mmap_size;
}

/* *done_out: the shared flush_cursor completed a cycle. */
static uint32_t SHM_FN(flush_expired_partial)(ShmHandle *h, uint32_t limit, int *done_out) {
    if (h->shard_handles) {
        /* A shard that finished its cycle waits for the others. */
        uint32_t total = 0;
        int all_done = 1;
        for (uint32_t i = 0; i < h->num_shards; i++) {
            ShmHandle *s = h->shard_handles[i];
            if (!s->flush_done) {
                int done = 0;
                total += SHM_FN(flush_expired_partial)(s, limit, &done);
                s->flush_done = (uint8_t)done;
            }
            all_done &= s->flush_done;
        }
        if (all_done)
            for (uint32_t i = 0; i < h->num_shards; i++) h->shard_handles[i]->flush_done = 0;
        if (done_out) *done_out = all_done;
        return total;
    }
    if (!h->expires_at) {
        if (done_out) *done_out = 1;
        return 0;
    }
    if (done_out) *done_out = 0;

    ShmHeader *hdr = h->hdr;
    uint8_t *states = h->states;
    uint32_t flushed = 0;

    shm_rwlock_wrlock(h);
    uint32_t now = shm_now();
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t cap = hdr->table_cap;
    uint32_t start = hdr->flush_cursor;
    if (start >= cap) start = 0;
    /* Behind where this handle left the cursor, another flusher ended the cycle. */
    int lapped = hdr->table_gen == h->flush_gen && start < h->flush_seen;
    if (limit == 0) limit = 1;
    if (limit >= cap) { start = 0; limit = cap; }
    else if (limit > cap - start) limit = cap - start;
    shm_sig_hold(h, limit);

    for (uint32_t i = start; i < start + limit; i++) {
        if (SHM_IS_LIVE(states[i]) && h->expires_at[i] != 0 && now >= h->expires_at[i]) {
            shm_sig_check(h);
            SHM_FN(expire_at)(h, i);
            flushed++;
        }
    }

    int done = start + limit == cap;
    hdr->flush_cursor = done ? 0 : start + limit;

    if (done_out) *done_out = done || lapped;

    /* Shrink only at a cycle's end: a rehash could move entries behind the cursor. */
    if (flushed) h->flush_freed = 1;
    if (done && h->flush_freed) {
        h->flush_freed = 0;
        SHM_FN(maybe_shrink)(h);
    }
    h->flush_seen = hdr->flush_cursor;
    h->flush_gen = hdr->table_gen;

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return flushed;
}

static uint32_t SHM_FN(flush_expired)(ShmHandle *h) {
    if (h->shard_handles) {
        uint32_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(flush_expired)(h->shard_handles[i]);
        return total;
    }
    if (!h->expires_at) return 0;
    int done;
    return SHM_FN(flush_expired_partial)(h, UINT32_MAX, &done);
}

static int SHM_FN(touch)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key
#else
    const char *key_str, uint32_t key_len, bool key_utf8
#endif
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    if (!h->lru_prev && !h->expires_at) return 0;

    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;

    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                shm_seqlock_write_begin(&hdr->seq);
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            shm_seqlock_write_begin(&hdr->seq);
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[idx] != 0) {
                h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);
            }
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    shm_rwlock_wrunlock(h);
    return 0;
}

static int SHM_FN(reserve)(ShmHandle *h, uint32_t target) {
    if (h->shard_handles) {
        int ok = 1;
        for (uint32_t i = 0; i < h->num_shards; i++)
            ok &= SHM_FN(reserve)(h->shard_handles[i], target);
        return ok;
    }
    ShmHeader *hdr = h->hdr;
    /* The ceiling matches max_entries(). */
    if (target > (uint32_t)((uint64_t)hdr->max_table_cap * 3 / 4)) return 0;
    uint32_t needed = shm_next_pow2(target + target / 3 + 1);
    /* The top of the range rounds above max_table_cap but still fits in it. */
    if (needed == 0 || needed > hdr->max_table_cap) needed = hdr->max_table_cap;
    if (needed < SHM_INITIAL_CAP) needed = SHM_INITIAL_CAP;
    if (needed <= hdr->table_cap) return 1;

    shm_rwlock_wrlock(h);
    shm_seqlock_write_begin(&hdr->seq);
    int ok = 1;
    if (needed > hdr->table_cap)
        ok = SHM_FN(resize)(h, needed);
    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return ok;
}

static inline uint64_t SHM_FN(stat_evictions)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(stat_evictions)(h->shard_handles[i]);
        return (uint64_t)total;
    }
    return __atomic_load_n(&h->hdr->stat_evictions, __ATOMIC_RELAXED);
}

static inline uint64_t SHM_FN(stat_expired)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(stat_expired)(h->shard_handles[i]);
        return (uint64_t)total;
    }
    return __atomic_load_n(&h->hdr->stat_expired, __ATOMIC_RELAXED);
}

static inline uint64_t SHM_FN(stat_recoveries)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(stat_recoveries)(h->shard_handles[i]);
        return total;
    }
    return __atomic_load_n(&h->hdr->stat_recoveries, __ATOMIC_RELAXED);
}

static uint64_t SHM_FN(compact)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(compact)(h->shard_handles[i]);
        return total;
    }
    if (!h->arena) return 0;
    uint64_t freed = 0;
    shm_rwlock_wrlock(h);
    shm_seqlock_write_begin(&h->hdr->seq);
#if SHM_HAS_ARENA
    freed = SHM_FN(arena_compact)(h, 0);
#endif
    h->arena_failed = 0;
    h->compact_backoff = 0;
    h->compact_period = 0;
    shm_seqlock_write_end(&h->hdr->seq);
    shm_rwlock_wrunlock(h);
    return freed;
}

static inline uint64_t SHM_FN(arena_used)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(arena_used)(h->shard_handles[i]);
        return (uint64_t)total;
    }
    return h->arena ? __atomic_load_n(&h->hdr->arena_bump, __ATOMIC_RELAXED) : 0;
}

static inline uint64_t SHM_FN(arena_cap)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(arena_cap)(h->shard_handles[i]);
        return (uint64_t)total;
    }
    return h->arena ? h->hdr->arena_cap : 0;
}

static void SHM_FN(clear)(ShmHandle *h) {
    if (h->shard_handles) {
        for (uint32_t i = 0; i < h->num_shards; i++)
            SHM_FN(clear)(h->shard_handles[i]);
        /* Or a later each() resumes mid-set and skips the shards below. */
        h->shard_iter = 0;
        return;
    }
    ShmHeader *hdr = h->hdr;

    shm_rwlock_wrlock(h);
    shm_sig_hold(h, hdr->table_cap);
    shm_seqlock_write_begin(&hdr->seq);

    hdr->rz_seq = __atomic_load_n(&hdr->seq, __ATOMIC_RELAXED);
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    __atomic_store_n(&hdr->rz_phase, SHM_RZ_CLEAR, __ATOMIC_RELEASE);
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    shm_clear_run(h);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);

    h->iter_pos = 0;
    if (h->iter_active) {
        h->iter_active = 0;
        if (h->iterating > 0) h->iterating--;
    }
    h->deferred = 0;
}

static inline void SHM_FN(iter_reset)(ShmHandle *h) {
    if (h->shard_handles) {
        for (uint32_t i = 0; i < h->num_shards; i++) {
            SHM_FN(iter_reset)(h->shard_handles[i]);
            /* Deferred work is on the shards, never the dispatcher. */
            SHM_FN(flush_deferred)(h->shard_handles[i]);
        }
        h->shard_iter = 0;
        return;
    }
    if (h->iter_active) {
        h->iter_active = 0;
        if (h->iterating > 0) h->iterating--;
    }
    h->iter_pos = 0;
}

static int SHM_FN(get_or_set)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key,
#else
    const char *key_str, uint32_t key_len, bool key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char *def_str, uint32_t def_len, bool def_utf8,
    const char **out_str, uint32_t *out_len, bool *out_utf8
#else
    SHM_VAL_INT_TYPE def_value,
    SHM_VAL_INT_TYPE *out_value
#endif
) {
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;

    /* No LRU or TTL: a hit changes nothing, so get() answers it lock-free. */
    if (!h->lru_prev && !h->expires_at) {
#if defined(SHM_KEY_IS_INT) && defined(SHM_VAL_IS_STR)
        if (SHM_FN(get)(h, key, out_str, out_len, out_utf8)) return 1;
#elif defined(SHM_KEY_IS_INT)
        if (SHM_FN(get)(h, key, out_value)) return 1;
#elif defined(SHM_VAL_IS_STR)
        if (SHM_FN(get)(h, key_str, key_len, key_utf8, out_str, out_len, out_utf8)) return 1;
#else
        if (SHM_FN(get)(h, key_str, key_len, key_utf8, out_value)) return 1;
#endif
    }

    shm_rwlock_wrlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;
    shm_seqlock_write_begin(&hdr->seq);

    SHM_FN(maybe_grow)(h);
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    shm_sig_hold_bytes(h, key_len);
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint32_t insert_pos = UINT32_MAX;

    uint8_t tag = SHM_MAKE_TAG(hash);
    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);

        if (st == SHM_EMPTY) {
            if (insert_pos == UINT32_MAX) insert_pos = idx;
            break;
        }
        if (st == SHM_TOMBSTONE) {
            if (insert_pos == UINT32_MAX) insert_pos = idx;
            continue;
        }
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                if (insert_pos == UINT32_MAX) insert_pos = idx;
                break;
            }

#ifdef SHM_VAL_IS_STR
            {
                uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
                shm_sig_hold_bytes(h, vl);
                if (!shm_ensure_copy_buf(h, vl)) {
                    shm_seqlock_write_end(&hdr->seq);
                    shm_rwlock_wrunlock(h);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, vl);
                *out_str = h->copy_buf;
                *out_len = vl;
                *out_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
            }
#else
            *out_value = __atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED);
#endif
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[idx] != 0)
                h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    if ((insert_pos = SHM_FN(insert_slot)(h, pos, mask, insert_pos)) == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }

    SHM_FN(evict_for_insert)(h, SHM_KEY_SLEN(key_len), SHM_VAL_SLEN(def_len));

    int was_tombstone = (states[insert_pos] == SHM_TOMBSTONE);
    SHM_FN(arena_reclaim)(h);

#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!SHM_FN(store_or_evict)(h, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8, SHM_LRU_NONE)) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }
#endif

#ifdef SHM_VAL_IS_STR
    if (!shm_ensure_copy_buf(h, def_len > 0 ? def_len : 1)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }
    if (!SHM_FN(store_or_evict)(h, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, def_str, def_len, def_utf8, SHM_LRU_NONE)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }
#else
    __atomic_store_n(&nodes[insert_pos].value, def_value, __ATOMIC_RELAXED);
#endif

    if (h->expires_at)
        h->expires_at[insert_pos] = hdr->default_ttl > 0 ? shm_expiry_ts(hdr->default_ttl) : 0;
    shm_publish_tag(states, insert_pos, SHM_MAKE_TAG(hash));
    /* tombstones-- before size++: see put_inner */
    if (was_tombstone) hdr->tombstones--;
    hdr->size++;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);

#ifdef SHM_VAL_IS_STR
    memcpy(h->copy_buf, def_str, def_len);
    *out_str = h->copy_buf;
    *out_len = def_len;
    *out_utf8 = def_utf8;
#else
    *out_value = def_value;
#endif
    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
    return 2; /* inserted */
}

static int SHM_FN(each)(ShmHandle *h,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE *out_key,
#else
    const char **out_key_str, uint32_t *out_key_len, bool *out_key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char **out_val_str, uint32_t *out_val_len, bool *out_val_utf8
#else
    SHM_VAL_INT_TYPE *out_value
#endif
) {
    if (h->shard_handles) {
        while (h->shard_iter < h->num_shards) {
            int rc = SHM_FN(each)(h->shard_handles[h->shard_iter],
#ifdef SHM_KEY_IS_INT
                out_key,
#else
                out_key_str, out_key_len, out_key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
                out_val_str, out_val_len, out_val_utf8
#else
                out_value
#endif
            );
            if (rc) return 1;
            SHM_FN(flush_deferred)(h->shard_handles[h->shard_iter]);
            h->shard_iter++;
        }
        h->shard_iter = 0;
        return 0;
    }
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_rdlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;

    if (!h->iter_active) {
        h->iter_active = 1;
        h->iter_gen = hdr->table_gen;
        h->iterating++;
    }

    if (h->iter_gen != hdr->table_gen) {
        h->iter_pos = 0;
        h->iter_gen = hdr->table_gen;
    }

    while (shm_find_next_live(states, hdr->table_cap, &h->iter_pos)) {
        uint32_t pos = h->iter_pos++;
        {
            if (SHM_IS_EXPIRED(h, pos, now))
                continue;

#ifdef SHM_KEY_IS_INT
            *out_key = nodes[pos].key;
#else
            {
                uint32_t kl = SHM_STR_LEN(nodes[pos].key_len);
#ifdef SHM_VAL_IS_STR
                uint32_t vl = SHM_STR_LEN(nodes[pos].val_len);
                uint32_t total = kl + vl;
#else
                uint32_t total = kl;
#endif
                if (!shm_ensure_copy_buf(h, total)) {
                    h->iter_pos = 0;
                    h->iter_active = 0;
                    if (h->iterating > 0) h->iterating--;
                    shm_rwlock_rdunlock(h);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[pos].key_off, nodes[pos].key_len, h->arena, h->hdr->arena_cap, kl);
                *out_key_str = h->copy_buf;
                *out_key_len = kl;
                *out_key_utf8 = SHM_UNPACK_UTF8(nodes[pos].key_len);
            }
#endif
#ifdef SHM_VAL_IS_STR
            {
                uint32_t vl = SHM_STR_LEN(nodes[pos].val_len);
#ifndef SHM_KEY_IS_INT
                uint32_t kl = SHM_STR_LEN(nodes[pos].key_len);
                shm_str_copy(h->copy_buf + kl, nodes[pos].val_off, nodes[pos].val_len, h->arena, h->hdr->arena_cap, vl);
                *out_val_str = h->copy_buf + kl;
#else
                if (!shm_ensure_copy_buf(h, vl)) {
                    h->iter_pos = 0;
                    h->iter_active = 0;
                    if (h->iterating > 0) h->iterating--;
                    shm_rwlock_rdunlock(h);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[pos].val_off, nodes[pos].val_len, h->arena, h->hdr->arena_cap, vl);
                *out_val_str = h->copy_buf;
#endif
                *out_val_len = vl;
                *out_val_utf8 = SHM_UNPACK_UTF8(nodes[pos].val_len);
            }
#else
            *out_value = __atomic_load_n(&nodes[pos].value, __ATOMIC_RELAXED);
#endif
            shm_rwlock_rdunlock(h);
            return 1;
        }
    }

    h->iter_pos = 0;
    h->iter_active = 0;
    if (h->iterating > 0) h->iterating--;
    shm_rwlock_rdunlock(h);
    return 0;  /* caller should call flush_deferred */
}

static int SHM_FN(cursor_next)(ShmCursor *c,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE *out_key,
#else
    const char **out_key_str, uint32_t *out_key_len, bool *out_key_utf8,
#endif
#ifdef SHM_VAL_IS_STR
    const char **out_val_str, uint32_t *out_val_len, bool *out_val_utf8
#else
    SHM_VAL_INT_TYPE *out_value
#endif
) {
    while (c->shard_idx < c->shard_count) {
        ShmHandle *h = c->current;
        ShmHeader *hdr = h->hdr;
        SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
        uint8_t *states = h->states;
        shm_rwlock_rdlock(h);
        uint32_t now = h->expires_at ? shm_now() : 0;

        if (c->gen != hdr->table_gen) {
            c->iter_pos = 0;
            c->gen = hdr->table_gen;
        }

        while (shm_find_next_live(states, hdr->table_cap, &c->iter_pos)) {
            uint32_t pos = c->iter_pos++;
            {
                if (SHM_IS_EXPIRED(h, pos, now))
                    continue;

#ifdef SHM_KEY_IS_INT
                *out_key = nodes[pos].key;
#else
                {
                    uint32_t kl = SHM_STR_LEN(nodes[pos].key_len);
#ifdef SHM_VAL_IS_STR
                    uint32_t vl = SHM_STR_LEN(nodes[pos].val_len);
                    uint32_t total = kl + vl;
#else
                    uint32_t total = kl;
#endif
                    if (!shm_cursor_ensure_copy_buf(c, total)) {
                        shm_rwlock_rdunlock(h);
                        return 0;
                    }
                    shm_str_copy(c->copy_buf, nodes[pos].key_off, nodes[pos].key_len, h->arena, h->hdr->arena_cap, kl);
                    *out_key_str = c->copy_buf;
                    *out_key_len = kl;
                    *out_key_utf8 = SHM_UNPACK_UTF8(nodes[pos].key_len);
                }
#endif
#ifdef SHM_VAL_IS_STR
                {
                    uint32_t vl = SHM_STR_LEN(nodes[pos].val_len);
#ifndef SHM_KEY_IS_INT
                    uint32_t kl = SHM_STR_LEN(nodes[pos].key_len);
                    shm_str_copy(c->copy_buf + kl, nodes[pos].val_off, nodes[pos].val_len, h->arena, h->hdr->arena_cap, vl);
                    *out_val_str = c->copy_buf + kl;
#else
                    if (!shm_cursor_ensure_copy_buf(c, vl)) {
                        shm_rwlock_rdunlock(h);
                        return 0;
                    }
                    shm_str_copy(c->copy_buf, nodes[pos].val_off, nodes[pos].val_len, h->arena, h->hdr->arena_cap, vl);
                    *out_val_str = c->copy_buf;
#endif
                    *out_val_len = vl;
                    *out_val_utf8 = SHM_UNPACK_UTF8(nodes[pos].val_len);
                }
#else
                *out_value = __atomic_load_n(&nodes[pos].value, __ATOMIC_RELAXED);
#endif
                shm_rwlock_rdunlock(h);
                return 1;
            }
        }

        shm_rwlock_rdunlock(h);

        if (h->iterating > 0) h->iterating--;
        SHM_FN(flush_deferred)(h);
        c->shard_idx++;
        if (c->shard_idx < c->shard_count) {
            ShmHandle *parent = c->handle;
            c->current = parent->shard_handles[c->shard_idx];
            c->current->iterating++;
            c->iter_pos = 0;
            c->gen = c->current->hdr->table_gen;
        } else {
            /* Or destroy, reset and seek decrement the last shard's `iterating` again. */
            c->current = NULL;
        }
    }

    return 0;
}

static inline void SHM_FN(cursor_reset)(ShmCursor *c) {
    if (c->current && c->current->iterating > 0)
        c->current->iterating--;
    SHM_FN(flush_deferred)(c->current);
    c->shard_idx = 0;
    if (c->handle->shard_handles) {
        c->current = c->handle->shard_handles[0];
    } else {
        c->current = c->handle;
    }
    c->current->iterating++;
    c->iter_pos = 0;
    c->gen = c->current->hdr->table_gen;
}

/* The next cursor_next returns this key's entry, then continues forward. */
static int SHM_FN(cursor_seek)(ShmCursor *c,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key
#else
    const char *key_str, uint32_t key_len, bool key_utf8
#endif
) {
#ifdef SHM_KEY_IS_INT
    uint64_t hash64 = SHM_HASH_KEY64(key);
#else
    uint64_t hash64 = SHM_HASH_KEY_STR64(key_str, key_len);
#endif
    uint32_t hash = (uint32_t)hash64;
    ShmHandle *parent = c->handle;
    ShmHandle *target;
    uint32_t target_shard = 0;
    if (parent->shard_handles) {
        target_shard = shm_shard_index(parent, hash64);
        target = parent->shard_handles[target_shard];
    } else {
        target = parent;
    }

    /* Probe first: a seek that finds nothing leaves the iteration where it was. */
    ShmHandle *h = target;
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    shm_rwlock_rdlock(h);
    uint32_t now = h->expires_at ? shm_now() : 0;

    uint32_t mask = hdr->table_cap - 1;
    uint32_t pos = hash & mask;
    uint8_t tag = SHM_MAKE_TAG(hash);

    for (uint32_t i = 0; i <= mask; i++) {
        uint32_t idx = (pos + i) & mask;
        uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
        if (st == SHM_EMPTY) break;
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, h->hdr->arena_cap, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                shm_rwlock_rdunlock(h);
                return 0;
            }
            uint32_t found_gen = hdr->table_gen;
            shm_rwlock_rdunlock(h);
            /* gen as read under the lock: a resize since makes cursor_next reset. */
            if (target != c->current) {
                if (c->current && c->current->iterating > 0)
                    c->current->iterating--;
                SHM_FN(flush_deferred)(c->current);
                c->current = target;
                c->current->iterating++;
                c->shard_idx = target_shard;
            }
            c->iter_pos = idx;
            c->gen = found_gen;
            return 1;
        }
    }

    shm_rwlock_rdunlock(h);
    return 0;
}

#undef SHM_PASTE2
#undef SHM_PASTE
#undef SHM_FN
#undef SHM_NODE_TYPE
#undef SHM_PREFIX
#undef SHM_VARIANT_ID
#undef SHM_HAS_ARENA
#undef SHM_COMPACT_BACKOFF
#undef SHM_COMPACT_BACKOFF_MAX
#undef SHM_KEY_SLEN
#undef SHM_VAL_SLEN

#ifdef SHM_KEY_IS_INT
  #undef SHM_KEY_IS_INT
  #undef SHM_KEY_INT_TYPE
  #undef SHM_HASH_KEY
  #undef SHM_HASH_KEY64
  #undef SHM_KEY_EQ
#else
  #undef SHM_HASH_KEY_STR
  #undef SHM_HASH_KEY_STR64
  #undef SHM_KEY_EQ_STR
#endif

#ifdef SHM_VAL_IS_STR
  #undef SHM_VAL_IS_STR
#else
  #undef SHM_VAL_INT_TYPE
#endif

#ifdef SHM_HAS_COUNTERS
  #undef SHM_HAS_COUNTERS
#endif
