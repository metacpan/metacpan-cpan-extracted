/*
 * shm_generic.h — Macro-template for shared-memory hash maps.
 *
 * Before including, define:
 *   SHM_PREFIX         — function prefix (e.g., shm_ii)
 *   SHM_NODE_TYPE      — node struct name
 *   SHM_VARIANT_ID     — unique integer for header validation
 *
 * Key type (choose one):
 *   SHM_KEY_IS_INT + SHM_KEY_INT_TYPE  — integer key
 *   (leave undefined for string keys via arena)
 *
 * Value type (choose one):
 *   SHM_VAL_IS_STR                      — string value via arena
 *   SHM_VAL_INT_TYPE                    — integer value
 *
 * Optional:
 *   SHM_HAS_COUNTERS  — generate incr/decr/incr_by (integer values only)
 */

/* ================================================================
 * Part 1: Shared definitions (included once)
 * ================================================================ */

#ifndef SHM_DEFS_H
#define SHM_DEFS_H

#include <stdint.h>
#include <stdbool.h>
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
#include <sys/syscall.h>
#include <limits.h>
#include <signal.h>
#include <errno.h>
#include <linux/futex.h>

#ifdef __SSE2__
#include <emmintrin.h>
#endif

#define XXH_INLINE_ALL
#include "xxhash.h"

/* ---- Constants ---- */

#define SHM_MAGIC       0x53484D31U  /* "SHM1" */
#define SHM_VERSION     7
#define SHM_INITIAL_CAP 16
#define SHM_MAX_STR_LEN 0x3FFFFFFFU  /* ~1GB, bit 30 reserved for inline flag */
#define SHM_LRU_NONE    UINT32_MAX

/* UINT32_MAX = use default TTL; 0 = no TTL; other = per-key TTL */
#define SHM_TTL_USE_DEFAULT UINT32_MAX

#define SHM_IS_EXPIRED(h, i, now) \
    ((h)->expires_at && (h)->expires_at[(i)] && \
     (now) >= (h)->expires_at[(i)])

/* Fast monotonic seconds — avoids time() syscall overhead.
 * CLOCK_MONOTONIC_COARSE is always vDSO on Linux (~2ns). */
static inline uint32_t shm_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_COARSE, &ts);
    return (uint32_t)ts.tv_sec;
}

/* Compute expiry timestamp with overflow protection */
static inline uint32_t shm_expiry_ts(uint32_t ttl) {
    uint64_t sum = (uint64_t)shm_now() + ttl;
    return (sum > UINT32_MAX) ? UINT32_MAX : (uint32_t)sum;
}

#define SHM_EMPTY     0
#define SHM_TOMBSTONE 1
#define SHM_TAG_MIN   2   /* state values 2-255 = LIVE with hash tag */
#define SHM_IS_LIVE(st) ((st) >= SHM_TAG_MIN)
#define SHM_MAKE_TAG(hash) ((uint8_t)(((hash) >> 24) % 254 + SHM_TAG_MIN))
/* Invariant: TOMBSTONE < TAG_MIN so tag-based probe filtering works.
 * Compile-time check via negative-size array trick: */
typedef char shm_tag_invariant_check[(SHM_TOMBSTONE < SHM_TAG_MIN) ? 1 : -1];

/* SIMD helper: find next LIVE slot (state >= SHM_TAG_MIN) in states[],
 * starting at position *pos. Returns 1 if found (updates *pos), 0 if
 * no live slot found before cap. */
static inline int shm_find_next_live(const uint8_t *states, uint32_t cap, uint32_t *pos) {
    uint32_t i = *pos;
#ifdef __SSE2__
    /* Check if byte is NOT empty(0) and NOT tombstone(1) using unsigned
     * saturation: sub_sat(byte, 1) > 0 iff byte >= 2 = SHM_TAG_MIN */
    __m128i ones = _mm_set1_epi8(1);
    /* Align to 16-byte boundary first (scalar) */
    uint32_t align_end = (i + 15) & ~(uint32_t)15;
    if (align_end > cap) align_end = cap;
    for (; i < align_end; i++) {
        if (states[i] >= SHM_TAG_MIN) { *pos = i; return 1; }
    }
    /* SIMD scan: subs_u8(chunk, 1) is nonzero for bytes >= 2 */
    for (; i + 16 <= cap; i += 16) {
        __m128i chunk = _mm_loadu_si128((const __m128i *)(states + i));
        __m128i sub = _mm_subs_epu8(chunk, ones);  /* unsigned saturating sub */
        int mask = _mm_movemask_epi8(_mm_cmpeq_epi8(sub, _mm_setzero_si128()));
        mask = ~mask & 0xFFFF;  /* invert: bits set where sub != 0 (live) */
        if (mask) { *pos = i + __builtin_ctz(mask); return 1; }
    }
#endif
    /* Scalar fallback */
    for (; i < cap; i++) {
        if (states[i] >= SHM_TAG_MIN) { *pos = i; return 1; }
    }
    return 0;
}

/* SIMD probe helper: scan up to 16 state bytes from a given position
 * for tag matches or EMPTY slots. Returns via *match_mask (tag hits)
 * and *empty_mask (empty slots). Caller uses bitmasks to iterate.
 * Works on contiguous memory — caller must handle table wrap. */
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
#define SHM_ARENA_MIN_ALLOC   16

/* ---- UTF-8 and inline-string flag packing ---- */
/*
 * key_len / val_len layout (uint32_t):
 *   bit 31       = UTF-8 flag
 *   bit 30       = INLINE flag (string ≤ 7 bytes stored in off+len fields)
 *   bits 0-29    = length (max ~1GB)
 *
 * When INLINE is set:
 *   The associated _off field (4 bytes) + bits 0-23 of _len (3 bytes) hold
 *   up to 7 bytes of string data.  Length is in bits 24-26 of _len (0-7).
 *   bits 27-29 are reserved (0).
 *
 * When INLINE is NOT set (arena mode):
 *   _off = arena offset, _len bits 0-29 = length.
 */

#define SHM_UTF8_FLAG    ((uint32_t)0x80000000U)
#define SHM_INLINE_FLAG  ((uint32_t)0x40000000U)
#define SHM_LEN_MASK     ((uint32_t)0x3FFFFFFFU)
#define SHM_INLINE_MAX   7  /* max bytes that fit inline */

/* Arena-mode packing (unchanged for ≤1GB strings) */
#define SHM_PACK_LEN(len, utf8)   ((uint32_t)(len) | ((utf8) ? SHM_UTF8_FLAG : 0))
#define SHM_UNPACK_LEN(packed)    ((uint32_t)((packed) & SHM_LEN_MASK))
#define SHM_UNPACK_UTF8(packed)   (((packed) & SHM_UTF8_FLAG) != 0)
#define SHM_IS_INLINE(packed)     (((packed) & SHM_INLINE_FLAG) != 0)

/* Get string length for either inline or arena mode */
#define SHM_STR_LEN(packed) \
    (SHM_IS_INLINE(packed) ? shm_inline_len(packed) : SHM_UNPACK_LEN(packed))

/* Inline packing: store len in bits 24-26, data in _off (4B) + _len bits 0-23 (3B) */
static inline void shm_inline_pack(uint32_t *off, uint32_t *len_field,
                                    const char *str, uint32_t slen, bool utf8) {
    uint32_t lf = SHM_INLINE_FLAG | ((uint32_t)slen << 24);
    if (utf8) lf |= SHM_UTF8_FLAG;
    uint32_t o = 0;
    /* copy first 4 bytes into off, next 3 into lower 24 bits of len_field */
    memcpy(&o, str, slen > 4 ? 4 : slen);
    if (slen > 4) {
        uint32_t rest = 0;
        memcpy(&rest, str + 4, slen - 4);
        lf |= rest;
    }
    *off = o;
    *len_field = lf;
}

static inline uint32_t shm_inline_len(uint32_t len_field) {
    return (len_field >> 24) & 0x7;
}

/* Read inline string into caller buffer. Returns pointer to data (buf). */
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

/* Get string pointer + length, handling both inline and arena modes.
 * For inline, copies to buf and returns buf. For arena, returns arena pointer directly. */
static inline const char *shm_str_ptr(uint32_t off, uint32_t len_field,
                                       const char *arena, char *inline_buf,
                                       uint32_t *out_len) {
    if (SHM_IS_INLINE(len_field)) {
        *out_len = shm_inline_len(len_field);
        return shm_inline_read(off, len_field, inline_buf);
    }
    *out_len = SHM_UNPACK_LEN(len_field);
    return arena + off;
}

/* ---- Shared memory header (256 bytes, 4 cache lines, in mmap) ---- */

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#define SHM_STATIC_ASSERT(cond, msg) _Static_assert(cond, msg)
#else
#define SHM_STATIC_ASSERT(cond, msg)
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
    uint32_t _pad1;           /* 68 */
    uint64_t arena_cap;       /* 72: immutable, read by seqlock string path */
    uint8_t  _reserved1[48];  /* 80-127 */

    /* ---- Cache line 2 (128-191): rwlock + write-hot fields ---- */
    uint32_t rwlock;          /* 128: 0=unlocked, 1..0x7FFFFFFF=readers, 0x80000000|pid=writer */
    uint32_t rwlock_waiters;  /* 132 */
    uint32_t size;            /* 136 */
    uint32_t tombstones;      /* 140 */
    uint32_t lru_head;        /* 144: MRU slot index */
    uint32_t lru_tail;        /* 148: LRU slot index */
    uint32_t flush_cursor;    /* 152: partial flush_expired scan cursor */
    uint32_t table_gen;       /* 156: incremented on every resize */
    uint64_t arena_bump;      /* 160 */
    uint64_t stat_evictions;  /* 168: cumulative LRU eviction count */
    uint64_t stat_expired;    /* 176: cumulative TTL expiration count */
    uint32_t stat_recoveries; /* 184: cumulative stale lock recovery count */
    uint32_t lru_skip;        /* 188: promotion skip mask (power-of-2 minus 1, 0=strict LRU) */

    /* ---- Cache line 3 (192-255): arena free lists ---- */
    uint32_t arena_free[SHM_ARENA_NUM_CLASSES]; /* 192-255 */
} ShmHeader;

SHM_STATIC_ASSERT(sizeof(ShmHeader) == 256, "ShmHeader must be exactly 256 bytes (4 cache lines)");

/* ---- Process-local handle ---- */

typedef struct ShmHandle_s {
    ShmHeader *hdr;
    void      *nodes;
    uint8_t   *states;
    char      *arena;
    uint32_t  *lru_prev;    /* NULL if LRU disabled */
    uint32_t  *lru_next;    /* NULL if LRU disabled */
    uint8_t   *lru_accessed; /* NULL if LRU disabled — clock second-chance bit */
    uint32_t  *expires_at;  /* NULL if TTL disabled */
    size_t     mmap_size;
    uint32_t   max_mask;    /* max_table_cap - 1, for seqlock bounds clamping */
    uint32_t   iter_pos;
    char      *copy_buf;
    uint32_t   copy_buf_size;
    uint32_t   iterating;   /* active iterator count (each + cursors) */
    uint32_t   iter_gen;    /* table_gen snapshot for each() */
    uint8_t    iter_active; /* 1 = built-in each is in progress */
    uint8_t    deferred;    /* shrink/compact deferred while iterating */
    char      *path;        /* backing file path (strdup'd) */
    /* Sharding: if shard_handles != NULL, this is a sharded map dispatcher */
    struct ShmHandle_s **shard_handles; /* NULL for single map */
    uint32_t   num_shards;
    uint32_t   shard_mask;     /* num_shards - 1 (power of 2) */
    uint32_t   shard_iter;     /* current shard for each()/cursor iteration */
} ShmHandle;

/* Shard dispatch: resolve key to target handle */
#define SHM_SHARD(h, hash) \
    ((h)->shard_handles ? (h)->shard_handles[(hash) & (h)->shard_mask] : (h))

/* ---- Cursor (independent iterator) ---- */

typedef struct {
    ShmHandle *handle;       /* for single maps, direct handle; for sharded, the dispatcher */
    ShmHandle *current;      /* current shard handle (== handle for single maps) */
    uint32_t   iter_pos;
    uint32_t   gen;          /* table_gen snapshot — reset on mismatch */
    uint32_t   shard_idx;    /* current shard index (0 for single maps) */
    uint32_t   shard_count;  /* total shards (1 for single maps) */
    char      *copy_buf;
    uint32_t   copy_buf_size;
} ShmCursor;

/* Grow a copy buffer to hold `needed` bytes; returns 0 on OOM */
static inline int shm_grow_buf(char **buf, uint32_t *cap, uint32_t needed) {
    if (needed == 0) needed = 1;
    if (needed <= *cap) return 1;
    uint32_t ns = *cap ? *cap : 64;
    while (ns < needed) {
        uint32_t next = ns * 2;
        if (next <= ns) { ns = needed; break; } /* overflow guard */
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

/* ---- Hash functions (xxHash, XXH3) ---- */

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

/* Extract writer PID from rwlock value (lower 31 bits when write-locked). */
#define SHM_RWLOCK_WRITER_BIT 0x80000000U
#define SHM_RWLOCK_PID_MASK   0x7FFFFFFFU
#define SHM_RWLOCK_WR(pid)    (SHM_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & SHM_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
static inline int shm_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Force-recover a stale write lock left by a dead process.
 * CAS to recovery sentinel (WRITER_BIT, no PID) to hold the lock while
 * fixing seqlock, then release. This prevents a new writer from acquiring
 * between the CAS and the seq fix. */
static inline void shm_recover_stale_lock(ShmHeader *hdr, uint32_t observed_rwlock) {
    /* CAS to recovery sentinel — keeps lock held, blocks new writers */
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            SHM_RWLOCK_WRITER_BIT, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* Fix seqlock while lock is still held by us */
    uint32_t seq = __atomic_load_n(&hdr->seq, __ATOMIC_RELAXED);
    if (seq & 1)
        __atomic_store_n(&hdr->seq, seq + 1, __ATOMIC_RELEASE);
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    /* Now release the lock */
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec shm_lock_timeout = { SHM_LOCK_TIMEOUT_SEC, 0 };

static inline void shm_rwlock_rdlock(ShmHeader *hdr) {
    uint32_t *lock = &hdr->rwlock;
    uint32_t *waiters = &hdr->rwlock_waiters;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Write-preferring: when lock is free (cur==0) and writers are
         * waiting, yield to let the writer acquire. When readers are
         * already active (cur>=1), new readers may join freely. */
        if (cur > 0 && cur < SHM_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(waiters, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < SHM_RWLOCK_SPIN_LIMIT, 1)) {
            shm_rwlock_spin_pause();
            continue;
        }
        __atomic_add_fetch(waiters, 1, __ATOMIC_RELAXED);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        /* Sleep when write-locked OR when yielding to waiting writers */
        if (cur >= SHM_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &shm_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT && cur >= SHM_RWLOCK_WRITER_BIT) {
                __atomic_sub_fetch(waiters, 1, __ATOMIC_RELAXED);
                uint32_t val = __atomic_load_n(lock, __ATOMIC_RELAXED);
                if (val >= SHM_RWLOCK_WRITER_BIT) {
                    uint32_t pid = val & SHM_RWLOCK_PID_MASK;
                    if (!shm_pid_alive(pid))
                        shm_recover_stale_lock(hdr, val);
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(waiters, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline void shm_rwlock_rdunlock(ShmHeader *hdr) {
    uint32_t prev = __atomic_sub_fetch(&hdr->rwlock, 1, __ATOMIC_RELEASE);
    if (prev == 0 && __atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void shm_rwlock_wrlock(ShmHeader *hdr) {
    uint32_t *lock = &hdr->rwlock;
    uint32_t *waiters = &hdr->rwlock_waiters;
    /* Encode PID in the rwlock word itself (0x80000000 | pid) to eliminate
     * any crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = SHM_RWLOCK_WR((uint32_t)getpid());
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < SHM_RWLOCK_SPIN_LIMIT, 1)) {
            shm_rwlock_spin_pause();
            continue;
        }
        __atomic_add_fetch(waiters, 1, __ATOMIC_RELAXED);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &shm_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(waiters, 1, __ATOMIC_RELAXED);
                uint32_t val = __atomic_load_n(lock, __ATOMIC_RELAXED);
                if (val >= SHM_RWLOCK_WRITER_BIT) {
                    uint32_t pid = val & SHM_RWLOCK_PID_MASK;
                    if (!shm_pid_alive(pid))
                        shm_recover_stale_lock(hdr, val);
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(waiters, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline void shm_rwlock_wrunlock(ShmHeader *hdr) {
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ---- Seqlock (lock-free readers) ---- */

static inline uint32_t shm_seqlock_read_begin(ShmHeader *hdr) {
    int spin = 0;
    for (;;) {
        uint32_t s = __atomic_load_n(&hdr->seq, __ATOMIC_ACQUIRE);
        if (__builtin_expect((s & 1) == 0, 1)) return s;
        if (__builtin_expect(spin < 100000, 1)) {
            shm_rwlock_spin_pause();
            spin++;
            continue;
        }
        /* Prolonged odd seq — check for dead writer */
        uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
        if (val >= SHM_RWLOCK_WRITER_BIT) {
            uint32_t pid = val & SHM_RWLOCK_PID_MASK;
            if (!shm_pid_alive(pid)) {
                shm_recover_stale_lock(hdr, val);
                spin = 0;
                continue;
            }
        }
        /* Writer is alive, yield CPU */
        struct timespec ts = {0, 1000000}; /* 1ms */
        nanosleep(&ts, NULL);
        spin = 0;
    }
}

static inline int shm_seqlock_read_retry(uint32_t *seq, uint32_t start) {
    __atomic_thread_fence(__ATOMIC_ACQUIRE);  /* ensure data loads complete before retry check */
    return __atomic_load_n(seq, __ATOMIC_RELAXED) != start;
}

static inline void shm_seqlock_write_begin(uint32_t *seq) {
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);  /* seq becomes odd */
}

static inline void shm_seqlock_write_end(uint32_t *seq) {
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);  /* seq becomes even */
}

/* ---- Arena allocator ---- */

static inline uint32_t shm_next_pow2(uint32_t v);

static inline uint32_t shm_arena_round_up(uint32_t len) {
    if (len < SHM_ARENA_MIN_ALLOC) return SHM_ARENA_MIN_ALLOC;
    return shm_next_pow2(len);
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
        uint32_t next;
        memcpy(&next, arena + head, sizeof(uint32_t));
        hdr->arena_free[cls] = next;
        return head;
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
    if (cls < 0 || off == 0) return;

    uint32_t old_head = hdr->arena_free[cls];
    memcpy(arena + off, &old_head, sizeof(uint32_t));
    hdr->arena_free[cls] = off;
}

/* Store a string: inline if ≤ 7 bytes, arena otherwise. Returns 1 on success, 0 on arena OOM. */
static inline int shm_str_store(ShmHeader *hdr, char *arena,
                                 uint32_t *off, uint32_t *len_field,
                                 const char *str, uint32_t slen, bool utf8) {
    if (slen <= SHM_INLINE_MAX) {
        shm_inline_pack(off, len_field, str, slen, utf8);
        return 1;
    }
    uint32_t aoff = shm_arena_alloc(hdr, arena, slen);
    if (aoff == 0 && slen > 0) return 0;
    memcpy(arena + aoff, str, slen);
    *off = aoff;
    *len_field = SHM_PACK_LEN(slen, utf8);
    return 1;
}

/* Free a string's arena block (no-op for inline strings) */
static inline void shm_str_free(ShmHeader *hdr, char *arena,
                                 uint32_t off, uint32_t len_field) {
    if (!SHM_IS_INLINE(len_field))
        shm_arena_free_block(hdr, arena, off, SHM_UNPACK_LEN(len_field));
}

/* Copy string data (inline or arena) into a destination buffer */
static inline void shm_str_copy(char *dst, uint32_t off, uint32_t len_field,
                                 const char *arena, uint32_t len) {
    if (SHM_IS_INLINE(len_field))
        shm_inline_read(off, len_field, dst);
    else
        memcpy(dst, arena + off, len);
}

/* ---- Utility ---- */

static inline uint32_t shm_next_pow2(uint32_t v) {
    if (v < 2) return 2;
    if (v > 0x80000000U) return 0;  /* overflow: no valid power of 2 */
    v--;
    v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16;
    return v + 1;
}

/* ---- LRU helpers ---- */

static inline void shm_lru_unlink(ShmHandle *h, uint32_t idx) {
    uint32_t *prev = h->lru_prev;
    uint32_t *next = h->lru_next;
    ShmHeader *hdr = h->hdr;
    uint32_t p = prev[idx], n = next[idx];
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
    if (h->lru_accessed) __atomic_store_n(&h->lru_accessed[idx], 0, __ATOMIC_RELAXED);  /* clear stale clock bit */
    prev[idx] = SHM_LRU_NONE;
    next[idx] = hdr->lru_head;
    if (hdr->lru_head != SHM_LRU_NONE) prev[hdr->lru_head] = idx;
    else hdr->lru_tail = idx;
    hdr->lru_head = idx;
}

static inline void shm_lru_promote(ShmHandle *h, uint32_t idx) {
    ShmHeader *hdr = h->hdr;
    if (hdr->lru_head == idx) return;
    /* Counter-based promotion skip: promote every (mask+1)th access.
     * Branch-predictor friendly — the skip branch is nearly always taken.
     * Tail entry is never skipped to preserve eviction correctness. */
    if (hdr->lru_skip > 0 && idx != hdr->lru_tail) {
        static __thread uint32_t promote_ctr = 0;
        if ((++promote_ctr & hdr->lru_skip) != 0)
            return;
    }
    shm_lru_unlink(h, idx);
    shm_lru_push_front(h, idx);
}

/* ---- Create / Open / Close ---- */

/* Error buffer for shm_create_map diagnostics */
#define SHM_ERR_BUFLEN 256

static ShmHandle *shm_create_map(const char *path, uint32_t max_entries,
                                  uint32_t node_size, uint32_t variant_id,
                                  int has_arena, uint32_t max_size,
                                  uint32_t default_ttl, uint32_t lru_skip,
                                  char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    uint32_t max_tcap = shm_next_pow2((uint32_t)((uint64_t)max_entries * 4 / 3 + 1));
    if (max_tcap < SHM_INITIAL_CAP) max_tcap = SHM_INITIAL_CAP;

    int has_lru = (max_size > 0);
    int has_ttl = (default_ttl > 0);

    uint64_t nodes_off  = sizeof(ShmHeader);
    uint64_t states_off = nodes_off + (uint64_t)max_tcap * node_size;
    uint64_t next_off   = states_off + max_tcap;

    /* LRU arrays (between states and arena) */
    uint64_t lru_prev_off = 0, lru_next_off = 0, lru_accessed_off = 0, expires_off = 0;
    if (has_lru) {
        next_off = (next_off + 3) & ~(uint64_t)3;
        lru_prev_off = next_off;
        next_off += (uint64_t)max_tcap * sizeof(uint32_t);
        lru_next_off = next_off;
        next_off += (uint64_t)max_tcap * sizeof(uint32_t);
        lru_accessed_off = next_off;
        next_off += max_tcap;  /* uint8_t per slot */
    }
    if (has_ttl) {
        next_off = (next_off + 3) & ~(uint64_t)3;
        expires_off = next_off;
        next_off += (uint64_t)max_tcap * sizeof(uint32_t);
    }

    uint64_t arena_off = 0, arena_cap = 0;
    if (has_arena) {
        arena_off = (next_off + 7) & ~(uint64_t)7;
        arena_cap = (uint64_t)max_entries * 128;
        if (arena_cap < 4096) arena_cap = 4096;
    }

    uint64_t total_size = has_arena ? arena_off + arena_cap : next_off;

    #define SHM_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

    int fd = open(path, O_RDWR | O_CREAT, 0666);
    if (fd < 0) { SHM_ERR("open(%s): %s", path, strerror(errno)); return NULL; }

    if (flock(fd, LOCK_EX) < 0) { SHM_ERR("flock(%s): %s", path, strerror(errno)); close(fd); return NULL; }

    struct stat st;
    if (fstat(fd, &st) < 0) { SHM_ERR("fstat(%s): %s", path, strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }

    int is_new = (st.st_size == 0);

    if (!is_new && (uint64_t)st.st_size < sizeof(ShmHeader)) {
        SHM_ERR("%s: file too small (%lld bytes, need %zu)", path,
                (long long)st.st_size, sizeof(ShmHeader));
        flock(fd, LOCK_UN); close(fd); return NULL;
    }

    if (is_new) {
        if (ftruncate(fd, (off_t)total_size) < 0) {
            SHM_ERR("ftruncate(%s, %llu): %s", path, (unsigned long long)total_size, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
    }

    void *base = mmap(NULL, is_new ? total_size : (size_t)st.st_size,
                       PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { SHM_ERR("mmap(%s): %s", path, strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }

    ShmHeader *hdr = (ShmHeader *)base;

    if (is_new) {
        memset(hdr, 0, sizeof(ShmHeader));
        hdr->magic         = SHM_MAGIC;
        hdr->version       = SHM_VERSION;
        hdr->variant_id    = variant_id;
        hdr->node_size     = node_size;
        hdr->max_table_cap = max_tcap;
        hdr->table_cap     = SHM_INITIAL_CAP;
        hdr->total_size    = total_size;
        hdr->nodes_off     = nodes_off;
        hdr->states_off    = states_off;
        hdr->arena_off     = has_arena ? arena_off : 0;
        hdr->arena_cap     = arena_cap;
        hdr->arena_bump    = SHM_ARENA_MIN_ALLOC; /* reserve offset 0 */
        hdr->max_size      = max_size;
        hdr->default_ttl   = default_ttl;
        /* Convert skip percentage (0-99) to power-of-2 mask.
         * skip=50→mask=1(every 2nd), 75→3(4th), 90→15(16th), 95→31(32nd) */
        {
            uint32_t mask = 0;
            if (lru_skip > 0 && lru_skip < 100) {
                uint32_t interval = 100 / (100 - (lru_skip > 99 ? 99 : lru_skip));
                uint32_t p = 1;
                while (p < interval) p <<= 1;
                mask = p - 1;
            }
            hdr->lru_skip = mask;
        }
        hdr->lru_head      = SHM_LRU_NONE;
        hdr->lru_tail      = SHM_LRU_NONE;

        /* init LRU arrays (full max_tcap, not just initial cap) */
        if (has_lru) {
            memset((char *)base + lru_prev_off, 0xFF,
                   max_tcap * sizeof(uint32_t));
            memset((char *)base + lru_next_off, 0xFF,
                   max_tcap * sizeof(uint32_t));
            memset((char *)base + lru_accessed_off, 0, max_tcap);
        }
        if (has_ttl) {
            memset((char *)base + expires_off, 0,
                   max_tcap * sizeof(uint32_t));
        }

        __atomic_thread_fence(__ATOMIC_SEQ_CST);
    } else {
        int valid = (hdr->magic == SHM_MAGIC &&
                     hdr->version == SHM_VERSION &&
                     hdr->variant_id == variant_id &&
                     hdr->node_size == node_size &&
                     hdr->total_size == (uint64_t)st.st_size &&
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
        if (!valid) {
            if (hdr->magic != SHM_MAGIC)
                SHM_ERR("%s: bad magic (not a HashMap::Shared file)", path);
            else if (hdr->version != SHM_VERSION)
                SHM_ERR("%s: version mismatch (file=%u, expected=%u)", path, hdr->version, SHM_VERSION);
            else if (hdr->variant_id != variant_id)
                SHM_ERR("%s: variant mismatch (file=%u, expected=%u)", path, hdr->variant_id, variant_id);
            else
                SHM_ERR("%s: corrupt header", path);
            munmap(base, (size_t)st.st_size);
            flock(fd, LOCK_UN); close(fd);
            return NULL;
        }
        total_size = (uint64_t)st.st_size;

        /* Recompute LRU/TTL offsets from header fields */
        has_lru = (hdr->max_size > 0);
        has_ttl = (hdr->default_ttl > 0);
        next_off = hdr->states_off + hdr->max_table_cap;
        if (has_lru) {
            next_off = (next_off + 3) & ~(uint64_t)3;
            lru_prev_off = next_off;
            next_off += (uint64_t)hdr->max_table_cap * sizeof(uint32_t);
            lru_next_off = next_off;
            next_off += (uint64_t)hdr->max_table_cap * sizeof(uint32_t);
            lru_accessed_off = next_off;
            next_off += hdr->max_table_cap;
        }
        if (has_ttl) {
            next_off = (next_off + 3) & ~(uint64_t)3;
            expires_off = next_off;
            next_off += (uint64_t)hdr->max_table_cap * sizeof(uint32_t);
        }
        if (next_off > total_size) {
            SHM_ERR("%s: file too small for LRU/TTL arrays", path);
            munmap(base, (size_t)st.st_size);
            flock(fd, LOCK_UN); close(fd);
            return NULL;
        }
    }

    flock(fd, LOCK_UN);
    close(fd);

    ShmHandle *h = (ShmHandle *)calloc(1, sizeof(ShmHandle));
    if (!h) { SHM_ERR("calloc: out of memory"); munmap(base, (size_t)total_size); return NULL; }

    h->hdr       = hdr;
    h->nodes     = (char *)hdr + hdr->nodes_off;
    h->states    = (uint8_t *)((char *)hdr + hdr->states_off);
    h->arena     = hdr->arena_off ? (char *)hdr + hdr->arena_off : NULL;
    h->lru_prev  = has_lru ? (uint32_t *)((char *)hdr + lru_prev_off) : NULL;
    h->lru_next  = has_lru ? (uint32_t *)((char *)hdr + lru_next_off) : NULL;
    h->lru_accessed = has_lru ? (uint8_t *)((char *)hdr + lru_accessed_off) : NULL;
    h->expires_at = has_ttl ? (uint32_t *)((char *)hdr + expires_off) : NULL;
    h->mmap_size = (size_t)total_size;
    h->max_mask  = hdr->max_table_cap - 1;
    h->iter_pos  = 0;
    h->path      = strdup(path);
    if (!h->path) { SHM_ERR("strdup: out of memory"); munmap(base, (size_t)total_size); free(h); return NULL; }

    /* Pre-size copy_buf for string variants to avoid realloc on first access */
    if (has_arena) {
        h->copy_buf = (char *)malloc(256);
        if (h->copy_buf) h->copy_buf_size = 256;
    }

    #undef SHM_ERR
    return h;
}

static void shm_close_map(ShmHandle *h) {
    if (!h) return;
    if (h->shard_handles) {
        /* Sharded: close all sub-handles */
        for (uint32_t i = 0; i < h->num_shards; i++)
            shm_close_map(h->shard_handles[i]);
        free(h->shard_handles);
        free(h->path);
        free(h);
        return;
    }
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->copy_buf);
    free(h->path);
    free(h);
}

/* Create a sharded map: N independent maps behind one handle */
static ShmHandle *shm_create_sharded(const char *path_prefix, uint32_t num_shards,
                                      uint32_t max_entries, uint32_t node_size,
                                      uint32_t variant_id, int has_arena,
                                      uint32_t max_size, uint32_t default_ttl,
                                      uint32_t lru_skip, char *errbuf) {
    /* Round up to power of 2 */
    uint32_t ns = 1;
    while (ns < num_shards) ns <<= 1;
    num_shards = ns;

    ShmHandle *h = (ShmHandle *)calloc(1, sizeof(ShmHandle));
    if (!h) { if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "calloc: out of memory"); return NULL; }

    h->shard_handles = (ShmHandle **)calloc(num_shards, sizeof(ShmHandle *));
    if (!h->shard_handles) { free(h); if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "calloc: out of memory"); return NULL; }

    h->num_shards = num_shards;
    h->shard_mask = num_shards - 1;
    h->path = strdup(path_prefix);

    for (uint32_t i = 0; i < num_shards; i++) {
        char shard_path[4096];
        int sn = snprintf(shard_path, sizeof(shard_path), "%s.%u", path_prefix, i);
        if (sn < 0 || sn >= (int)sizeof(shard_path)) {
            if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "shard path too long");
            for (uint32_t j = 0; j < i; j++)
                shm_close_map(h->shard_handles[j]);
            free(h->shard_handles);
            free(h->path);
            free(h);
            return NULL;
        }
        h->shard_handles[i] = shm_create_map(shard_path, max_entries, node_size,
                                               variant_id, has_arena, max_size,
                                               default_ttl, lru_skip, errbuf);
        if (!h->shard_handles[i]) {
            /* Clean up already-created shards */
            for (uint32_t j = 0; j < i; j++)
                shm_close_map(h->shard_handles[j]);
            free(h->shard_handles);
            free(h->path);
            free(h);
            return NULL;
        }
    }
    return h;
}

/* Unlink the backing file. Returns 1 on success, 0 on failure. */
static int shm_unlink_path(const char *path) {
    return (unlink(path) == 0) ? 1 : 0;
}

static int shm_unlink_sharded(ShmHandle *h) {
    if (!h->shard_handles) return shm_unlink_path(h->path);
    int ok = 1;
    for (uint32_t i = 0; i < h->num_shards; i++) {
        if (h->shard_handles[i] && h->shard_handles[i]->path) {
            if (unlink(h->shard_handles[i]->path) != 0) ok = 0;
        }
    }
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

static inline void shm_cursor_destroy(ShmCursor *c) {
    if (!c) return;
    ShmHandle *cur = c->current;
    if (cur && cur->iterating > 0)
        cur->iterating--;
    free(c->copy_buf);
    free(c);
}

#endif /* SHM_DEFS_H */


/* ================================================================
 * Part 2: Template (included per variant)
 * ================================================================ */

#define SHM_PASTE2(a, b) a##_##b
#define SHM_PASTE(a, b)  SHM_PASTE2(a, b)
#define SHM_FN(name)     SHM_PASTE(SHM_PREFIX, name)

/* ---- Node struct ---- */

typedef struct {
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key;
#else
    uint32_t key_off;
    uint32_t key_len; /* high bit = UTF-8 */
#endif
#ifdef SHM_VAL_IS_STR
    uint32_t val_off;
    uint32_t val_len; /* high bit = UTF-8 */
#else
    SHM_VAL_INT_TYPE value;
#endif
} SHM_NODE_TYPE;

/* ---- Shard dispatch for entry-point functions ---- */
#undef SHM_SHARD_DISPATCH
#ifdef SHM_KEY_IS_INT
  #define SHM_SHARD_DISPATCH(h, key_arg) \
      if ((h)->shard_handles) { \
          uint32_t _sh_hash = SHM_HASH_KEY(key_arg); \
          h = (h)->shard_handles[_sh_hash & (h)->shard_mask]; \
      }
#else
  #define SHM_SHARD_DISPATCH(h, key_str_arg, key_len_arg) \
      if ((h)->shard_handles) { \
          uint32_t _sh_hash = SHM_HASH_KEY_STR(key_str_arg, key_len_arg); \
          h = (h)->shard_handles[_sh_hash & (h)->shard_mask]; \
      }
#endif

/* ---- Key hashing ---- */

#ifdef SHM_KEY_IS_INT
  #define SHM_HASH_KEY(k) ((uint32_t)(shm_hash_int64((int64_t)(k))))
  #define SHM_KEY_EQ(node_ptr, k) ((node_ptr)->key == (k))
#else
  #define SHM_HASH_KEY_STR(str, len) ((uint32_t)shm_hash_string((str), (len)))
  static inline int SHM_PASTE(SHM_PREFIX, _key_eq_str)(
      const SHM_NODE_TYPE *np, const char *arena, const char *str, uint32_t len, bool utf8) {
      uint32_t kl_packed = np->key_len;
      if (SHM_UNPACK_UTF8(kl_packed) != utf8) return 0;
      if (SHM_IS_INLINE(kl_packed)) {
          if (shm_inline_len(kl_packed) != len) return 0;
          char buf[SHM_INLINE_MAX];
          shm_inline_read(np->key_off, kl_packed, buf);
          return memcmp(buf, str, len) == 0;
      }
      if (SHM_UNPACK_LEN(kl_packed) != len) return 0;
      return memcmp(arena + np->key_off, str, len) == 0;
  }
  #define SHM_KEY_EQ_STR(node_ptr, arena, str, len, utf8) \
      SHM_PASTE(SHM_PREFIX, _key_eq_str)((node_ptr), (arena), (str), (len), (utf8))
#endif

/* ---- Create / Open ---- */

static ShmHandle *SHM_FN(create)(const char *path, uint32_t max_entries,
                                  uint32_t max_size, uint32_t default_ttl,
                                  uint32_t lru_skip, char *errbuf) {
    int has_arena = 0;
#ifndef SHM_KEY_IS_INT
    has_arena = 1;
#endif
#ifdef SHM_VAL_IS_STR
    has_arena = 1;
#endif
    return shm_create_map(path, max_entries,
                           (uint32_t)sizeof(SHM_NODE_TYPE),
                           SHM_VARIANT_ID, has_arena,
                           max_size, default_ttl, lru_skip, errbuf);
}

static ShmHandle *SHM_FN(create_sharded)(const char *path_prefix,
                                          uint32_t num_shards,
                                          uint32_t max_entries,
                                          uint32_t max_size, uint32_t default_ttl,
                                          uint32_t lru_skip, char *errbuf) {
    int has_arena = 0;
#ifndef SHM_KEY_IS_INT
    has_arena = 1;
#endif
#ifdef SHM_VAL_IS_STR
    has_arena = 1;
#endif
    return shm_create_sharded(path_prefix, num_shards, max_entries,
                               (uint32_t)sizeof(SHM_NODE_TYPE),
                               SHM_VARIANT_ID, has_arena,
                               max_size, default_ttl, lru_skip, errbuf);
}

/* ---- Rehash helper (used during resize) — returns new index ---- */

static uint32_t SHM_FN(rehash_insert_raw)(ShmHandle *h, SHM_NODE_TYPE *node) {
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t mask = hdr->table_cap - 1;

#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(node->key);
#else
    char ibuf[SHM_INLINE_MAX];
    uint32_t klen;
    const char *kptr = shm_str_ptr(node->key_off, node->key_len, h->arena, ibuf, &klen);
    uint32_t hash = shm_hash_string(kptr, klen);
#endif

    uint32_t pos = hash & mask;
    while (SHM_IS_LIVE(states[pos]))
        pos = (pos + 1) & mask;

    nodes[pos] = *node;
    states[pos] = SHM_MAKE_TAG(hash);
    return pos;
}

/* ---- Tombstone at index (helper for eviction/expiry) ---- */

static void SHM_FN(tombstone_at)(ShmHandle *h, uint32_t idx) {
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
#ifndef SHM_KEY_IS_INT
    shm_str_free(hdr, h->arena, nodes[idx].key_off, nodes[idx].key_len);
#endif
#ifdef SHM_VAL_IS_STR
    shm_str_free(hdr, h->arena, nodes[idx].val_off, nodes[idx].val_len);
#endif
    h->states[idx] = SHM_TOMBSTONE;
    hdr->size--;
    hdr->tombstones++;
}

/* ---- LRU eviction ---- */

static void SHM_FN(lru_evict_one)(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    /* Second-chance clock: walk from tail, if accessed → clear and
     * promote (give second chance), else → evict. */
    uint32_t victim = hdr->lru_tail;
    while (victim != SHM_LRU_NONE) {
        if (h->lru_accessed && __atomic_load_n(&h->lru_accessed[victim], __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->lru_accessed[victim], 0, __ATOMIC_RELAXED);
            /* Promote: give second chance */
            uint32_t prev = h->lru_prev[victim];
            shm_lru_unlink(h, victim);
            shm_lru_push_front(h, victim);
            victim = prev;  /* continue from where we were */
            if (victim == SHM_LRU_NONE) victim = hdr->lru_tail;
            continue;
        }
        break;
    }
    if (victim == SHM_LRU_NONE) return;
    shm_lru_unlink(h, victim);
    if (h->expires_at) h->expires_at[victim] = 0;
    SHM_FN(tombstone_at)(h, victim);
    hdr->stat_evictions++;
}

/* ---- TTL expiration ---- */

static void SHM_FN(expire_at)(ShmHandle *h, uint32_t idx) {
    if (h->lru_prev) shm_lru_unlink(h, idx);
    h->expires_at[idx] = 0;
    SHM_FN(tombstone_at)(h, idx);
    h->hdr->stat_expired++;
}

/* ---- Resize (elastic grow/shrink) ---- */

static int SHM_FN(resize)(ShmHandle *h, uint32_t new_cap) {
    ShmHeader *hdr = h->hdr;
    uint32_t old_cap = hdr->table_cap;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;

    uint32_t live = hdr->size;
    SHM_NODE_TYPE *saved = NULL;
    uint32_t *saved_indices = NULL;
    uint32_t *old_to_new = NULL;
    uint32_t *saved_exp = NULL;

    /* Save LRU order (tail-to-head) */
    uint32_t *lru_order = NULL;
    uint32_t lru_count = 0;
    int need_mapping = (h->lru_prev || h->expires_at);

    if (live > 0) {
        saved = (SHM_NODE_TYPE *)malloc((size_t)live * sizeof(SHM_NODE_TYPE));
        if (!saved) return 0;

        if (need_mapping) {
            saved_indices = (uint32_t *)malloc((size_t)live * sizeof(uint32_t));
            old_to_new = (uint32_t *)malloc((size_t)old_cap * sizeof(uint32_t));
            if (!saved_indices || !old_to_new) {
                free(saved); free(saved_indices); free(old_to_new);
                return 0;
            }
            memset(old_to_new, 0xFF, old_cap * sizeof(uint32_t));
        }

        if (h->lru_prev) {
            lru_order = (uint32_t *)malloc((size_t)live * sizeof(uint32_t));
            if (!lru_order) {
                free(saved); free(saved_indices); free(old_to_new);
                return 0;
            }
            uint32_t idx = hdr->lru_tail;
            while (idx != SHM_LRU_NONE && lru_count < live) {
                lru_order[lru_count++] = idx;
                idx = h->lru_prev[idx];
            }
        }

        if (h->expires_at) {
            saved_exp = (uint32_t *)malloc(old_cap * sizeof(uint32_t));
            if (!saved_exp) {
                free(saved); free(saved_indices); free(old_to_new); free(lru_order);
                return 0;
            }
            memcpy(saved_exp, h->expires_at, old_cap * sizeof(uint32_t));
        }

        uint32_t j = 0;
        for (uint32_t i = 0; i < old_cap && j < live; i++) {
            if (SHM_IS_LIVE(states[i])) {
                saved[j] = nodes[i];
                if (saved_indices) saved_indices[j] = i;
                j++;
            }
        }
        live = j;
    }

    memset(states, SHM_EMPTY, new_cap);
    hdr->table_cap = new_cap;
    hdr->tombstones = 0;

    /* Reset LRU arrays */
    if (h->lru_prev) {
        memset(h->lru_prev, 0xFF, new_cap * sizeof(uint32_t));
        memset(h->lru_next, 0xFF, new_cap * sizeof(uint32_t));
        if (h->lru_accessed) memset(h->lru_accessed, 0, new_cap);
        hdr->lru_head = SHM_LRU_NONE;
        hdr->lru_tail = SHM_LRU_NONE;
    }
    if (h->expires_at) {
        memset(h->expires_at, 0, new_cap * sizeof(uint32_t));
    }

    for (uint32_t k = 0; k < live; k++) {
        uint32_t new_idx = SHM_FN(rehash_insert_raw)(h, &saved[k]);
        if (old_to_new) old_to_new[saved_indices[k]] = new_idx;
    }

    /* Rebuild LRU chain in original order (lru_order[0]=tail/LRU, last=head/MRU).
     * Push front from LRU to MRU so the last push (MRU) ends up at head. */
    if (h->lru_prev && lru_order) {
        for (uint32_t i = 0; i < lru_count; i++) {
            uint32_t new_idx = old_to_new[lru_order[i]];
            if (new_idx != SHM_LRU_NONE)
                shm_lru_push_front(h, new_idx);
        }
    }

    /* Restore expires_at */
    if (h->expires_at && saved_exp) {
        for (uint32_t k = 0; k < live; k++) {
            uint32_t new_idx = old_to_new[saved_indices[k]];
            if (new_idx != SHM_LRU_NONE)
                h->expires_at[new_idx] = saved_exp[saved_indices[k]];
        }
    }

    if (new_cap < old_cap) {
        size_t node_shrink = (size_t)(old_cap - new_cap) * sizeof(SHM_NODE_TYPE);
        madvise((char *)nodes + (size_t)new_cap * sizeof(SHM_NODE_TYPE),
                node_shrink, MADV_DONTNEED);
        madvise(states + new_cap, old_cap - new_cap, MADV_DONTNEED);
    }

    hdr->table_gen++;

    free(saved);
    free(saved_indices);
    free(old_to_new);
    free(lru_order);
    free(saved_exp);
    return 1;
}

static inline void SHM_FN(maybe_grow)(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    uint32_t size = hdr->size, tomb = hdr->tombstones, cap = hdr->table_cap;
    if (__builtin_expect((uint64_t)(size + tomb) * 4 > (uint64_t)cap * 3, 0)) {
        if (h->iterating > 0) { h->deferred = 1; return; }
        uint32_t new_cap = cap * 2;
        if (new_cap <= hdr->max_table_cap)
            SHM_FN(resize)(h, new_cap);
    } else if (__builtin_expect(tomb > size || tomb > cap / 4, 0)) {
        if (h->iterating > 0) { h->deferred = 1; return; }
        SHM_FN(resize)(h, cap);
    }
}

static inline void SHM_FN(maybe_shrink)(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    if (hdr->table_cap <= SHM_INITIAL_CAP) return;
    if (__builtin_expect((uint64_t)hdr->size * 4 < hdr->table_cap, 0)) {
        if (h->iterating > 0) { h->deferred = 1; return; }
        uint32_t new_cap = hdr->table_cap / 2;
        if (new_cap < SHM_INITIAL_CAP) new_cap = SHM_INITIAL_CAP;
        SHM_FN(resize)(h, new_cap);
    }
}

static inline void SHM_FN(flush_deferred)(ShmHandle *h) {
    if (!h->deferred || h->iterating > 0) return;
    h->deferred = 0;
    ShmHeader *hdr = h->hdr;
    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);
    uint32_t size = hdr->size, tomb = hdr->tombstones, cap = hdr->table_cap;
    if ((uint64_t)(size + tomb) * 4 > (uint64_t)cap * 3) {
        uint32_t new_cap = cap * 2;
        if (new_cap <= hdr->max_table_cap)
            SHM_FN(resize)(h, new_cap);
    } else if (cap > SHM_INITIAL_CAP && (uint64_t)size * 4 < cap) {
        uint32_t new_cap = cap / 2;
        if (new_cap < SHM_INITIAL_CAP) new_cap = SHM_INITIAL_CAP;
        SHM_FN(resize)(h, new_cap);
    } else if (tomb > size || tomb > cap / 4) {
        SHM_FN(resize)(h, cap);
    }
    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
}

/* ---- Put ---- */

/* put_inner: probe+insert/update WITHOUT locking. Caller holds wrlock+seqlock.
 * Returns 1 on success, 0 on failure (arena full / table full). */
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
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    uint32_t pos = hash & mask;
    uint32_t insert_pos = UINT32_MAX;

    /* Resolve effective expiry timestamp */
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
        /* SHM_IS_LIVE — check tag then key match */
        if (st != tag) continue;
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            /* update existing value */
#ifdef SHM_VAL_IS_STR
            {
                uint32_t old_off = nodes[idx].val_off;
                uint32_t old_lf = nodes[idx].val_len;
                if (!shm_str_store(hdr, h->arena, &nodes[idx].val_off, &nodes[idx].val_len, val_str, val_len, val_utf8))
                    return 0;
                shm_str_free(hdr, h->arena, old_off, old_lf);
            }
#else
            nodes[idx].value = value;
#endif
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at) {
                if (ttl_sec != SHM_TTL_USE_DEFAULT || h->expires_at[idx] != 0)
                    h->expires_at[idx] = exp_ts;
            }
            return 1;
        }
    }

    if (insert_pos == UINT32_MAX) return 0;

    /* LRU eviction only when actually inserting */
    if (hdr->max_size > 0 && hdr->size >= hdr->max_size)
        SHM_FN(lru_evict_one)(h);

    /* insert new entry */
    int was_tombstone = (states[insert_pos] == SHM_TOMBSTONE);

#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8))
        return 0;
#endif

#ifdef SHM_VAL_IS_STR
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, val_str, val_len, val_utf8)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        return 0;
    }
#else
    nodes[insert_pos].value = value;
#endif

    states[insert_pos] = SHM_MAKE_TAG(hash);
    hdr->size++;
    if (was_tombstone) hdr->tombstones--;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);
    if (h->expires_at) h->expires_at[insert_pos] = exp_ts;

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
    shm_rwlock_wrlock(h->hdr);
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
    shm_rwlock_wrunlock(h->hdr);
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

/* ---- Get (seqlock — lock-free read path) ---- */

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
    /* Unified seqlock path — lock-free for ALL maps including LRU/TTL.
     * LRU uses clock/second-chance: just set accessed bit, no wrlock.
     * TTL check is done under seqlock retry protection. */
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t max_mask = h->max_mask;
#if !defined(SHM_KEY_IS_INT) || defined(SHM_VAL_IS_STR)
    uint64_t arena_cap = hdr->arena_cap;  /* immutable after create */
#endif
#ifndef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#else
    uint32_t hash = SHM_HASH_KEY(key);
#endif

    for (;;) {
        uint32_t seq = shm_seqlock_read_begin(hdr);

        uint32_t mask = (hdr->table_cap - 1) & max_mask;
        uint32_t pos = hash & mask;
        int found = 0;
        uint32_t local_idx = 0;

        /* local copies of result data */
#ifdef SHM_VAL_IS_STR
        uint32_t local_vl = 0, local_voff = 0, local_vlen_packed = 0;
#else
        SHM_VAL_INT_TYPE local_value = 0;
#endif

        uint8_t tag = SHM_MAKE_TAG(hash);
        uint32_t probe_start = 0;  /* scalar loop starts here */

#ifdef __SSE2__
        /* SIMD fast path: check first 16 states in one shot */
        if (pos + 16 <= hdr->table_cap) {
            uint16_t mmask, emask;
            shm_probe_group(states, pos, tag, &mmask, &emask);
            /* Only consider matches before first empty */
            uint16_t cutoff = emask ? (uint16_t)((1U << __builtin_ctz(emask)) - 1) : 0xFFFF;
            uint16_t relevant = mmask & cutoff;
            while (relevant) {
                int bit = __builtin_ctz(relevant);
                uint32_t idx = pos + bit;
                __builtin_prefetch(&nodes[idx], 0, 1);
#ifdef SHM_KEY_IS_INT
                if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
                {
                    uint32_t kl_packed = nodes[idx].key_len;
                    uint32_t kl = SHM_STR_LEN(kl_packed);
                    if (kl != key_len || SHM_UNPACK_UTF8(kl_packed) != key_utf8) goto simd_next;
                    if (SHM_IS_INLINE(kl_packed)) {
                        char ibuf[SHM_INLINE_MAX];
                        shm_inline_read(nodes[idx].key_off, kl_packed, ibuf);
                        if (memcmp(ibuf, key_str, kl) != 0) goto simd_next;
                    } else {
                        uint32_t koff = nodes[idx].key_off;
                        if ((uint64_t)koff + kl > arena_cap) goto simd_done;
                        if (memcmp(h->arena + koff, key_str, kl) != 0) goto simd_next;
                    }
                }
                {
#endif
#ifdef SHM_VAL_IS_STR
                    local_vlen_packed = nodes[idx].val_len;
                    local_vl = SHM_STR_LEN(local_vlen_packed);
                    local_voff = nodes[idx].val_off;
#else
                    local_value = __atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED);
#endif
                    local_idx = idx;
                    found = 1;
                    goto simd_done;
                }
            simd_next:
                relevant &= relevant - 1;
            }
            if (emask) goto simd_done;  /* hit empty — key absent */
            probe_start = 16;           /* all 16 occupied, continue scalar from pos+16 */
        }
simd_done:
#endif
        if (!found) {
        for (uint32_t i = probe_start; i <= mask; i++) {
            uint32_t idx = (pos + i) & mask;
            uint8_t st = states[idx];
            __builtin_prefetch(&nodes[idx], 0, 1);
            __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);

            if (st == SHM_EMPTY) break;
            if (st != tag) continue;

#ifdef SHM_KEY_IS_INT
            if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
            {
                uint32_t kl_packed = nodes[idx].key_len;
                uint32_t koff = nodes[idx].key_off;
                uint32_t kl = SHM_STR_LEN(kl_packed);
                if (kl != key_len) continue;
                if (SHM_UNPACK_UTF8(kl_packed) != key_utf8) continue;
                if (SHM_IS_INLINE(kl_packed)) {
                    char ibuf[SHM_INLINE_MAX];
                    shm_inline_read(koff, kl_packed, ibuf);
                    if (memcmp(ibuf, key_str, kl) != 0) continue;
                } else {
                    if ((uint64_t)koff + kl > arena_cap) break;
                    if (memcmp(h->arena + koff, key_str, kl) != 0) continue;
                }
            }
            {
#endif
#ifdef SHM_VAL_IS_STR
                local_vlen_packed = nodes[idx].val_len;
                local_vl = SHM_STR_LEN(local_vlen_packed);
                local_voff = nodes[idx].val_off;
#else
                local_value = __atomic_load_n(&nodes[idx].value, __ATOMIC_RELAXED);
#endif
                local_idx = idx;
                found = 1;
                break;
            }
        }
        }

        if (found) {
            /* TTL check under seqlock (torn expiry caught by retry) */
            if (h->expires_at) {
                uint32_t exp = h->expires_at[local_idx];
                if (exp != 0 && shm_now() >= exp) {
                    found = 0;  /* expired — treat as absent */
                }
            }
        }

        if (found) {
#ifdef SHM_VAL_IS_STR
            if (SHM_IS_INLINE(local_vlen_packed)) {
                /* Inline value — data is in local_voff + local_vlen_packed, no arena access */
                if (local_vl > h->copy_buf_size || !h->copy_buf) {
                    if (!shm_ensure_copy_buf(h, local_vl > 0 ? local_vl : 1)) return 0;
                    continue;
                }
                shm_inline_read(local_voff, local_vlen_packed, h->copy_buf);
            } else {
                /* Arena value — bounds check before copy */
                if ((uint64_t)local_voff + local_vl > arena_cap) continue;
                if (local_vl > h->copy_buf_size || !h->copy_buf) {
                    if (!shm_ensure_copy_buf(h, local_vl > 0 ? local_vl : 1)) return 0;
                    continue;
                }
                memcpy(h->copy_buf, h->arena + local_voff, local_vl);
            }
#endif
            if (shm_seqlock_read_retry(&hdr->seq, seq)) continue;

            /* validated — set clock accessed bit and commit results */
            if (h->lru_accessed)
                __atomic_store_n(&h->lru_accessed[local_idx], 1, __ATOMIC_RELAXED);
#ifdef SHM_VAL_IS_STR
            *out_str = h->copy_buf;
            *out_len = local_vl;
            *out_utf8 = SHM_UNPACK_UTF8(local_vlen_packed);
#else
            *out_value = local_value;
#endif
            return 1;
        }

        if (shm_seqlock_read_retry(&hdr->seq, seq)) continue;
        return 0;
    }
}

/* ---- Exists (with TTL check under rdlock) ---- */

static int SHM_FN(exists_ttl)(ShmHandle *h,
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
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t now = shm_now();

    shm_rwlock_rdlock(hdr);

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
            if (st != tag) continue;  /* tombstone or tag mismatch */
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            int found = !SHM_IS_EXPIRED(h, idx, now);
            shm_rwlock_rdunlock(hdr);
            return found;
        }
    }

    shm_rwlock_rdunlock(hdr);
    return 0;
}

/* ---- Exists (seqlock — lock-free read path) ---- */

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
    /* TTL active: use rdlock path for expiry check */
    if (h->expires_at) {
#ifdef SHM_KEY_IS_INT
        return SHM_FN(exists_ttl)(h, key);
#else
        return SHM_FN(exists_ttl)(h, key_str, key_len, key_utf8);
#endif
    }

    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t max_mask = h->max_mask;
#ifndef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#else
    uint32_t hash = SHM_HASH_KEY(key);
#endif

    for (;;) {
        uint32_t seq = shm_seqlock_read_begin(hdr);

        uint32_t mask = (hdr->table_cap - 1) & max_mask;
        uint32_t pos = hash & mask;
        int found = 0;

        uint8_t tag = SHM_MAKE_TAG(hash);
        for (uint32_t i = 0; i <= mask; i++) {
            uint32_t idx = (pos + i) & mask;
            uint8_t st = states[idx];
        __builtin_prefetch(&nodes[idx], 0, 1);
        __builtin_prefetch(&nodes[(idx + 1) & mask], 0, 1);
            if (st == SHM_EMPTY) break;
            if (st != tag) continue;  /* tombstone or tag mismatch */
#ifdef SHM_KEY_IS_INT
            if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
            if (!SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) continue;
            {
#endif
                found = 1;
                break;
            }
        }

        if (shm_seqlock_read_retry(&hdr->seq, seq)) continue;
        return found;
    }
}

/* ---- Remove ---- */

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
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

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
            if (st != tag) continue;  /* tombstone or tag mismatch */

#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            if (h->lru_prev) shm_lru_unlink(h, idx);
            if (h->expires_at) h->expires_at[idx] = 0;
            SHM_FN(tombstone_at)(h, idx);

            SHM_FN(maybe_shrink)(h);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 1;
        }
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    return 0;
}

/* ---- Add (insert only if key absent, returns 1=inserted, 0=already exists or full) ---- */

static int SHM_FN(add)(ShmHandle *h,
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
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

    SHM_FN(maybe_grow)(h);
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            /* Check TTL — treat expired as absent */
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                if (insert_pos == UINT32_MAX) insert_pos = idx;
                break;
            }
            /* Key exists and is live — add fails */
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 0;
        }
    }

    if (insert_pos == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }

    /* LRU eviction if at capacity */
    if (hdr->max_size > 0 && hdr->size >= hdr->max_size)
        SHM_FN(lru_evict_one)(h);

    /* Insert new entry (same as put_impl insert path) */
    int was_tombstone = (states[insert_pos] == SHM_TOMBSTONE);
#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8)) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }
#endif
#ifdef SHM_VAL_IS_STR
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, val_str, val_len, val_utf8)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }
#else
    nodes[insert_pos].value = value;
#endif
    states[insert_pos] = SHM_MAKE_TAG(hash);
    hdr->size++;
    if (was_tombstone) hdr->tombstones--;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);
    if (h->expires_at) {
        uint32_t ttl = hdr->default_ttl;
        h->expires_at[insert_pos] = ttl > 0 ? shm_expiry_ts(ttl) : 0;
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    return 1;
}

/* ---- Update (overwrite only if key exists, returns 1=updated, 0=not found) ---- */

static int SHM_FN(update)(ShmHandle *h,
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
#ifdef SHM_KEY_IS_INT
    SHM_SHARD_DISPATCH(h, key);
#else
    SHM_SHARD_DISPATCH(h, key_str, key_len);
#endif
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(hdr);
                return 0;
            }
            /* Update value */
#ifdef SHM_VAL_IS_STR
            {
                uint32_t old_off = nodes[idx].val_off;
                uint32_t old_lf = nodes[idx].val_len;
                if (!shm_str_store(hdr, h->arena, &nodes[idx].val_off, &nodes[idx].val_len, val_str, val_len, val_utf8)) {
                    shm_seqlock_write_end(&hdr->seq);
                    shm_rwlock_wrunlock(hdr);
                    return 0;
                }
                shm_str_free(hdr, h->arena, old_off, old_lf);
            }
#else
            nodes[idx].value = value;
#endif
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[idx] != 0)
                h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);

            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 1;
        }
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    return 0;
}

/* ---- Swap (put + return old value; returns 1=swapped existing, 2=inserted new, 0=full) ---- */

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
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

    SHM_FN(maybe_grow)(h);
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                if (insert_pos == UINT32_MAX) insert_pos = idx;
                break;
            }
            /* Copy old value out, then overwrite */
#ifdef SHM_VAL_IS_STR
            {
                uint32_t old_vl = SHM_STR_LEN(nodes[idx].val_len);
                if (!shm_ensure_copy_buf(h, old_vl)) {
                    shm_seqlock_write_end(&hdr->seq);
                    shm_rwlock_wrunlock(hdr);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, old_vl);
                *out_str = h->copy_buf;
                *out_len = old_vl;
                *out_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);

                {
                    uint32_t old_off = nodes[idx].val_off;
                    uint32_t old_lf = nodes[idx].val_len;
                    if (!shm_str_store(hdr, h->arena, &nodes[idx].val_off, &nodes[idx].val_len, val_str, val_len, val_utf8)) {
                        shm_seqlock_write_end(&hdr->seq);
                        shm_rwlock_wrunlock(hdr);
                        return 0;
                    }
                    shm_str_free(hdr, h->arena, old_off, old_lf);
                }
            }
#else
            *out_value = nodes[idx].value;
            nodes[idx].value = value;
#endif
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[idx] != 0)
                h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);

            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 1; /* swapped existing */
        }
    }

    /* Key not found — insert new */
    if (insert_pos == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }

    /* LRU eviction if at capacity */
    if (hdr->max_size > 0 && hdr->size >= hdr->max_size)
        SHM_FN(lru_evict_one)(h);

    int was_tombstone = (states[insert_pos] == SHM_TOMBSTONE);
#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8)) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }
#endif
#ifdef SHM_VAL_IS_STR
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, val_str, val_len, val_utf8)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }
#else
    nodes[insert_pos].value = value;
#endif
    states[insert_pos] = SHM_MAKE_TAG(hash);
    hdr->size++;
    if (was_tombstone) hdr->tombstones--;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);
    if (h->expires_at) {
        uint32_t ttl = hdr->default_ttl;
        h->expires_at[insert_pos] = ttl > 0 ? shm_expiry_ts(ttl) : 0;
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    return 2; /* inserted new (no old value) */
}

/* ---- Take (remove and return value) ---- */

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
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

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
            if (st != tag) continue;  /* tombstone or tag mismatch */

#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            /* check TTL */
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(hdr);
                return 0;
            }

            /* copy value out before tombstoning */
#ifdef SHM_VAL_IS_STR
            {
                uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
                if (!shm_ensure_copy_buf(h, vl)) {
                    shm_seqlock_write_end(&hdr->seq);
                    shm_rwlock_wrunlock(hdr);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, vl);
                *out_str = h->copy_buf;
                *out_len = vl;
                *out_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
            }
#else
            *out_value = nodes[idx].value;
#endif
            if (h->lru_prev) shm_lru_unlink(h, idx);
            if (h->expires_at) h->expires_at[idx] = 0;
            SHM_FN(tombstone_at)(h, idx);

            SHM_FN(maybe_shrink)(h);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 1;
        }
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    return 0;
}

/* ---- Pop (remove and return one entry: LRU tail if LRU, else first found) ---- */

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
            uint32_t si = (h->shard_iter + i) % h->num_shards;
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
            if (rc) { h->shard_iter = (si + 1) % h->num_shards; return 1; }
        }
        return 0;
    }
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

    /* Find victim: LRU tail if available, else linear scan */
    uint32_t idx = UINT32_MAX;
    if (h->lru_prev && hdr->lru_tail != SHM_LRU_NONE) {
        /* Walk from tail, skipping expired */
        uint32_t pos = hdr->lru_tail;
        while (pos != SHM_LRU_NONE) {
            if (!SHM_IS_EXPIRED(h, pos, now)) { idx = pos; break; }
            uint32_t prev = h->lru_prev[pos];
            SHM_FN(expire_at)(h, pos);
            pos = prev;
        }
    } else {
        /* No LRU: scan from slot 0, expire stale entries along the way */
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (!SHM_IS_LIVE(states[i])) continue;
            if (SHM_IS_EXPIRED(h, i, now)) {
                SHM_FN(expire_at)(h, i);
                continue;
            }
            idx = i; break;
        }
    }

    if (idx == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }

    /* Copy key+value out */
#ifdef SHM_KEY_IS_INT
    *out_key = nodes[idx].key;
#else
    {
        uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
        if (!shm_ensure_copy_buf(h, kl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 0;
        }
        shm_str_copy(h->copy_buf, nodes[idx].key_off, nodes[idx].key_len, h->arena, kl);
        *out_key_str = h->copy_buf;
        *out_key_len = kl;
        *out_key_utf8 = SHM_UNPACK_UTF8(nodes[idx].key_len);
    }
#endif
#ifdef SHM_VAL_IS_STR
    {
        uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
#ifndef SHM_KEY_IS_INT
        uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
        /* key is in copy_buf[0..kl), put value after it.
         * Reassign out_key_str in case realloc moved the buffer. */
        if (!shm_ensure_copy_buf(h, kl + vl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 0;
        }
        *out_key_str = h->copy_buf;
        shm_str_copy(h->copy_buf + kl, nodes[idx].val_off, nodes[idx].val_len, h->arena, vl);
        *out_val_str = h->copy_buf + kl;
#else
        if (!shm_ensure_copy_buf(h, vl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 0;
        }
        shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, vl);
        *out_val_str = h->copy_buf;
#endif
        *out_val_len = vl;
        *out_val_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
    }
#else
    *out_value = nodes[idx].value;
#endif

    if (h->lru_prev) shm_lru_unlink(h, idx);
    if (h->expires_at) h->expires_at[idx] = 0;
    SHM_FN(tombstone_at)(h, idx);
    SHM_FN(maybe_shrink)(h);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    return 1;
}

/* ---- Shift (remove and return one entry: LRU head if LRU, else last found) ---- */

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
            uint32_t si = (h->shard_iter + i) % h->num_shards;
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
            if (rc) { h->shard_iter = (si + 1) % h->num_shards; return 1; }
        }
        return 0;
    }
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

    /* Find victim: LRU head if available, else scan backward */
    uint32_t idx = UINT32_MAX;
    if (h->lru_prev && hdr->lru_head != SHM_LRU_NONE) {
        /* Walk from head, skipping expired */
        uint32_t pos = hdr->lru_head;
        while (pos != SHM_LRU_NONE) {
            if (!SHM_IS_EXPIRED(h, pos, now)) { idx = pos; break; }
            uint32_t nxt = h->lru_next[pos];
            SHM_FN(expire_at)(h, pos);
            pos = nxt;
        }
    } else {
        /* No LRU: scan backward from last slot, expire stale entries */
        for (uint32_t i = hdr->table_cap; i > 0; i--) {
            if (!SHM_IS_LIVE(states[i - 1])) continue;
            if (SHM_IS_EXPIRED(h, i - 1, now)) {
                SHM_FN(expire_at)(h, i - 1);
                continue;
            }
            idx = i - 1; break;
        }
    }

    if (idx == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }

    /* Copy key+value out */
#ifdef SHM_KEY_IS_INT
    *out_key = nodes[idx].key;
#else
    {
        uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
        if (!shm_ensure_copy_buf(h, kl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 0;
        }
        shm_str_copy(h->copy_buf, nodes[idx].key_off, nodes[idx].key_len, h->arena, kl);
        *out_key_str = h->copy_buf;
        *out_key_len = kl;
        *out_key_utf8 = SHM_UNPACK_UTF8(nodes[idx].key_len);
    }
#endif
#ifdef SHM_VAL_IS_STR
    {
        uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
#ifndef SHM_KEY_IS_INT
        uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
        /* Reassign out_key_str in case realloc moved the buffer. */
        if (!shm_ensure_copy_buf(h, kl + vl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 0;
        }
        *out_key_str = h->copy_buf;
        shm_str_copy(h->copy_buf + kl, nodes[idx].val_off, nodes[idx].val_len, h->arena, vl);
        *out_val_str = h->copy_buf + kl;
#else
        if (!shm_ensure_copy_buf(h, vl + 1)) {
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 0;
        }
        shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, vl);
        *out_val_str = h->copy_buf;
#endif
        *out_val_len = vl;
        *out_val_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
    }
#else
    *out_value = nodes[idx].value;
#endif

    if (h->lru_prev) shm_lru_unlink(h, idx);
    if (h->expires_at) h->expires_at[idx] = 0;
    SHM_FN(tombstone_at)(h, idx);
    SHM_FN(maybe_shrink)(h);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
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
    uint32_t now = h->expires_at ? shm_now() : 0;
    uint32_t count = 0;
    uint32_t buf_used = *buf_used_p;

    if (limit == 0) return 0;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t scan_pos = 0;  /* non-LRU scan cursor to avoid O(N^2) rescan */
    while (count < limit) {
        uint32_t idx = UINT32_MAX;

        if (h->lru_prev && hdr->lru_tail != SHM_LRU_NONE) {
            uint32_t pos = hdr->lru_tail;
            while (pos != SHM_LRU_NONE) {
                if (!SHM_IS_EXPIRED(h, pos, now)) { idx = pos; break; }
                uint32_t prev = h->lru_prev[pos];
                SHM_FN(expire_at)(h, pos);
                pos = prev;
            }
        } else {
            for (; scan_pos < hdr->table_cap; scan_pos++) {
                if (!SHM_IS_LIVE(states[scan_pos])) continue;
                if (SHM_IS_EXPIRED(h, scan_pos, now)) {
                    SHM_FN(expire_at)(h, scan_pos);
                    continue;
                }
                idx = scan_pos++;
                break;
            }
        }

        if (idx == UINT32_MAX) break;

        /* Copy key */
#ifdef SHM_KEY_IS_INT
        out[count].key = nodes[idx].key;
#else
        {
            uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
            uint32_t need = buf_used + kl;
            if (need > *buf_cap) {
                uint32_t ns = *buf_cap ? *buf_cap * 2 : 4096;
                while (ns < need) ns *= 2;
                char *nb = (char *)realloc(*buf, ns);
                if (!nb) break;
                *buf = nb; *buf_cap = ns;
            }
            shm_str_copy(*buf + buf_used, nodes[idx].key_off, nodes[idx].key_len, h->arena, kl);
            out[count].key_off = buf_used;
            out[count].key_len = kl;
            out[count].key_utf8 = SHM_UNPACK_UTF8(nodes[idx].key_len);
            buf_used += kl;
        }
#endif
        /* Copy value */
#ifdef SHM_VAL_IS_STR
        {
            uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
            uint32_t need = buf_used + vl;
            if (need > *buf_cap) {
                uint32_t ns = *buf_cap ? *buf_cap * 2 : 4096;
                while (ns < need) ns *= 2;
                char *nb = (char *)realloc(*buf, ns);
                if (!nb) break;
                *buf = nb; *buf_cap = ns;
            }
            shm_str_copy(*buf + buf_used, nodes[idx].val_off, nodes[idx].val_len, h->arena, vl);
            out[count].val_off = buf_used;
            out[count].val_len = vl;
            out[count].val_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
            buf_used += vl;
        }
#else
        out[count].value = nodes[idx].value;
#endif

        if (h->lru_prev) shm_lru_unlink(h, idx);
        if (h->expires_at) h->expires_at[idx] = 0;
        SHM_FN(tombstone_at)(h, idx);
        count++;
    }

    if (count > 0) SHM_FN(maybe_shrink)(h);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    *buf_used_p = buf_used;
    return count;
}

static uint32_t SHM_FN(drain)(ShmHandle *h, uint32_t limit,
    SHM_PASTE(SHM_PREFIX, drain_entry) *out, char **buf, uint32_t *buf_cap) {
    uint32_t buf_used = 0;
    if (h->shard_handles) {
        uint32_t total = 0;
        for (uint32_t i = 0; i < h->num_shards && total < limit; i++) {
            uint32_t si = (h->shard_iter + i) % h->num_shards;
            uint32_t got = SHM_FN(drain_inner)(h->shard_handles[si], limit - total,
                                                out + total, buf, buf_cap, &buf_used);
            total += got;
        }
        if (total > 0) h->shard_iter = (h->shard_iter + 1) % h->num_shards;
        return total;
    }
    return SHM_FN(drain_inner)(h, limit, out, buf, buf_cap, &buf_used);
}

/* ---- Counter operations (integer values only) ---- */

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
            if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) { *out_idx = idx; return 1; }
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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
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
    uint32_t now = h->expires_at ? shm_now() : 0;

    /* fast path: existing key under read lock + atomic add (no LRU/TTL) */
    if (!h->lru_prev && !h->expires_at) {
        shm_rwlock_rdlock(hdr);
        uint32_t idx;
#ifdef SHM_KEY_IS_INT
        if (SHM_FN(find_slot)(h, key, &idx)) {
#else
        if (SHM_FN(find_slot)(h, key_str, key_len, key_utf8, &idx)) {
#endif
            SHM_VAL_INT_TYPE result =
                __atomic_add_fetch(&nodes[idx].value, delta, __ATOMIC_ACQ_REL);
            shm_rwlock_rdunlock(hdr);
            *ok = 1;
            return result;
        }
        shm_rwlock_rdunlock(hdr);
    }

    /* slow path: find-or-insert under write lock */
    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

    SHM_FN(maybe_grow)(h);
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
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
        if (SHM_KEY_EQ_STR(&nodes[slot], h->arena, key_str, key_len, key_utf8)) {
#endif
            /* TTL check */
            if (SHM_IS_EXPIRED(h, slot, now)) {
                SHM_FN(expire_at)(h, slot);
                /* treat as not found — will insert below */
                if (insert_pos == UINT32_MAX) insert_pos = slot;
                break;
            }

            nodes[slot].value += delta;
            SHM_VAL_INT_TYPE result = nodes[slot].value;
            if (h->lru_prev) shm_lru_promote(h, slot);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[slot] != 0)
                h->expires_at[slot] = shm_expiry_ts(hdr->default_ttl);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            *ok = 1;
            return result;
        }
    }

    if (insert_pos == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        *ok = 0;
        return 0;
    }

    /* LRU eviction only when actually inserting */
    if (hdr->max_size > 0 && hdr->size >= hdr->max_size)
        SHM_FN(lru_evict_one)(h);

    int was_tombstone = (h->states[insert_pos] == SHM_TOMBSTONE);
#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8)) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        *ok = 0;
        return 0;
    }
#endif
    nodes[insert_pos].value = delta;
    h->states[insert_pos] = SHM_MAKE_TAG(hash);
    hdr->size++;
    if (was_tombstone) hdr->tombstones--;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);
    if (h->expires_at && hdr->default_ttl > 0)
        h->expires_at[insert_pos] = shm_expiry_ts(hdr->default_ttl);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    *ok = 1;
    return delta;
}

/* ---- Compare-and-swap (atomic, integer values only) ---- */

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
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(hdr);
                return 0;
            }
            if (nodes[idx].value == expected) {
                nodes[idx].value = desired;
                if (h->lru_prev) shm_lru_promote(h, idx);
                if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[idx] != 0)
                    h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(hdr);
                return 1;
            }
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 0;
        }
    }

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    return 0;
}

#endif /* SHM_HAS_COUNTERS */

/* ---- Size ---- */

static inline uint32_t SHM_FN(size)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(size)(h->shard_handles[i]);
        return (uint32_t)(total > UINT32_MAX ? UINT32_MAX : total);
    }
    return __atomic_load_n(&h->hdr->size, __ATOMIC_ACQUIRE);
}

/* ---- Max entries ---- */

static inline uint32_t SHM_FN(max_entries)(ShmHandle *h) {
    if (h->shard_handles) return SHM_FN(max_entries)(h->shard_handles[0]);
    return h->hdr->max_table_cap * 3 / 4;
}

/* ---- Accessors ---- */

static inline uint32_t SHM_FN(max_size)(ShmHandle *h) {
    if (h->shard_handles) return SHM_FN(max_size)(h->shard_handles[0]);
    return h->hdr->max_size;
}

static inline uint32_t SHM_FN(ttl)(ShmHandle *h) {
    if (h->shard_handles) return SHM_FN(ttl)(h->shard_handles[0]);
    return h->hdr->default_ttl;
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
    if (!h->expires_at) return -1;  /* TTL not enabled */

    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;

    shm_rwlock_rdlock(hdr);

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
            if (st != tag) continue;  /* tombstone or tag mismatch */
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            uint32_t exp = h->expires_at[idx];
            if (exp == 0) {
                shm_rwlock_rdunlock(hdr);
                return 0;  /* permanent entry */
            }
            uint32_t now = shm_now();
            if (now >= exp) {
                shm_rwlock_rdunlock(hdr);
                return -1;  /* expired */
            }
            int64_t remaining = (int64_t)(exp - now);
            shm_rwlock_rdunlock(hdr);
            return remaining;
        }
    }

    shm_rwlock_rdunlock(hdr);
    return -1;  /* not found */
}

/* ---- Persist (remove TTL from a key, making it permanent) ---- */
/* Seqlock required: get() reads expires_at[] under seqlock. */

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
    uint32_t now = shm_now();

    shm_rwlock_wrlock(hdr);

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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                shm_seqlock_write_begin(&hdr->seq);
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(hdr);
                return 0;
            }
            shm_seqlock_write_begin(&hdr->seq);
            h->expires_at[idx] = 0;  /* permanent */
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 1;
        }
    }

    shm_rwlock_wrunlock(hdr);
    return 0;
}

/* ---- Set TTL (change TTL without changing value) ---- */

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
    uint32_t now = shm_now();

    shm_rwlock_wrlock(hdr);

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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                shm_seqlock_write_begin(&hdr->seq);
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(hdr);
                return 0;
            }
            shm_seqlock_write_begin(&hdr->seq);
            if (ttl_sec == 0)
                h->expires_at[idx] = 0;  /* permanent */
            else
                h->expires_at[idx] = shm_expiry_ts(ttl_sec);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 1;
        }
    }

    shm_rwlock_wrunlock(hdr);
    return 0;
}

/* ---- Stats ---- */

static inline uint32_t SHM_FN(capacity)(ShmHandle *h) {
    if (h->shard_handles) {
        uint32_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(capacity)(h->shard_handles[i]);
        return (uint32_t)total;
    }
    return h->hdr->table_cap;
}

static inline uint32_t SHM_FN(tombstones)(ShmHandle *h) {
    if (h->shard_handles) {
        uint32_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(tombstones)(h->shard_handles[i]);
        return (uint32_t)total;
    }
    return h->hdr->tombstones;
}

static inline size_t SHM_FN(mmap_size)(ShmHandle *h) {
    if (h->shard_handles) return SHM_FN(mmap_size)(h->shard_handles[0]);
    return h->mmap_size;
}

/* ---- Flush expired entries (partial / gradual) ---- */

/* Scan up to `limit` slots starting from the shared flush_cursor.
 * Returns the number of entries actually expired.
 * Sets *done_out to 1 if the cursor wrapped around (full cycle complete).
 * The wrlock is held only for `limit` slots, not the entire table. */
static uint32_t SHM_FN(flush_expired_partial)(ShmHandle *h, uint32_t limit, int *done_out) {
    if (h->shard_handles) {
        uint32_t total = 0;
        int all_done = 1;
        for (uint32_t i = 0; i < h->num_shards; i++) {
            int done = 0;
            total += SHM_FN(flush_expired_partial)(h->shard_handles[i], limit, &done);
            if (!done) all_done = 0;
        }
        if (done_out) *done_out = all_done;
        return total;
    }
    if (!h->expires_at) {
        if (done_out) *done_out = 1;  /* trivially complete */
        return 0;
    }
    if (done_out) *done_out = 0;

    ShmHeader *hdr = h->hdr;
    uint8_t *states = h->states;
    uint32_t now = shm_now();
    uint32_t flushed = 0;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

    uint32_t cap = hdr->table_cap;
    uint32_t start = hdr->flush_cursor;
    if (start >= cap) start = 0;       /* clamp after shrink */
    if (limit == 0) limit = 1;         /* scan at least one slot */
    if (limit > cap) limit = cap;      /* can't scan more than exists */

    for (uint32_t n = 0; n < limit; n++) {
        uint32_t i = (start + n) % cap;
        if (SHM_IS_LIVE(states[i]) && h->expires_at[i] != 0 && now >= h->expires_at[i]) {
            SHM_FN(expire_at)(h, i);
            flushed++;
        }
    }

    uint32_t next = (start + limit) % cap;
    /* Full cycle complete when this chunk crossed the end of the table */
    int done = (limit >= cap || start + limit >= cap);
    hdr->flush_cursor = done ? 0 : next;

    if (done_out) *done_out = done;

    /* Only shrink/compact when a full cycle is done, otherwise the rehash
     * can move entries to slots the cursor already passed. */
    if (done && flushed > 0)
        SHM_FN(maybe_shrink)(h);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    return flushed;
}

/* Convenience: full scan in one call (original behavior). */
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

/* ---- Touch (refresh TTL / promote LRU without changing value) ---- */

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
    if (!h->lru_prev && !h->expires_at) return 0;  /* nothing to do */

    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(hdr);

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
            if (st != tag) continue;  /* tombstone or tag mismatch */
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                shm_seqlock_write_begin(&hdr->seq);
                SHM_FN(expire_at)(h, idx);
                SHM_FN(maybe_shrink)(h);
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(hdr);
                return 0;
            }
            shm_seqlock_write_begin(&hdr->seq);
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[idx] != 0) {
                h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);
            }
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 1;
        }
    }

    shm_rwlock_wrunlock(hdr);
    return 0;
}

/* ---- Reserve (pre-grow table to target capacity) ---- */

static int SHM_FN(reserve)(ShmHandle *h, uint32_t target) {
    if (h->shard_handles) {
        int ok = 1;
        for (uint32_t i = 0; i < h->num_shards; i++)
            ok &= SHM_FN(reserve)(h->shard_handles[i], target);
        return ok;
    }
    ShmHeader *hdr = h->hdr;
    if (target > hdr->max_table_cap) return 0;
    /* compute min capacity for target entries at <75% load */
    uint32_t needed = shm_next_pow2(target + target / 3 + 1);
    if (needed < SHM_INITIAL_CAP) needed = SHM_INITIAL_CAP;
    if (needed <= hdr->table_cap) return 1;  /* already big enough */
    if (needed > hdr->max_table_cap) return 0;  /* exceeds max */

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);
    int ok = 1;
    if (needed > hdr->table_cap)
        ok = SHM_FN(resize)(h, needed);
    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    return ok;
}

/* ---- Cache stats accessors ---- */

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

static inline uint32_t SHM_FN(stat_recoveries)(ShmHandle *h) {
    if (h->shard_handles) {
        uint32_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(stat_recoveries)(h->shard_handles[i]);
        return (uint32_t)total;
    }
    return __atomic_load_n(&h->hdr->stat_recoveries, __ATOMIC_RELAXED);
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

/* ---- Clear ---- */

static void SHM_FN(clear)(ShmHandle *h) {
    if (h->shard_handles) {
        for (uint32_t i = 0; i < h->num_shards; i++)
            SHM_FN(clear)(h->shard_handles[i]);
        return;
    }
    ShmHeader *hdr = h->hdr;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

    memset(h->states, SHM_EMPTY, hdr->table_cap);
    hdr->size = 0;
    hdr->tombstones = 0;

    /* shrink back to initial capacity */
    if (hdr->table_cap > SHM_INITIAL_CAP) {
        uint32_t old_cap = hdr->table_cap;
        hdr->table_cap = SHM_INITIAL_CAP;
        size_t node_shrink = (size_t)(old_cap - SHM_INITIAL_CAP) * sizeof(SHM_NODE_TYPE);
        madvise((char *)h->nodes + (size_t)SHM_INITIAL_CAP * sizeof(SHM_NODE_TYPE),
                node_shrink, MADV_DONTNEED);
        madvise(h->states + SHM_INITIAL_CAP, old_cap - SHM_INITIAL_CAP, MADV_DONTNEED);
    }

    /* reset arena */
    if (h->arena) {
        hdr->arena_bump = SHM_ARENA_MIN_ALLOC;
        memset(hdr->arena_free, 0, sizeof(hdr->arena_free));
        madvise(h->arena, (size_t)hdr->arena_cap, MADV_DONTNEED);
    }

    /* reset LRU (full max_table_cap range) */
    if (h->lru_prev) {
        memset(h->lru_prev, 0xFF, hdr->max_table_cap * sizeof(uint32_t));
        memset(h->lru_next, 0xFF, hdr->max_table_cap * sizeof(uint32_t));
        if (h->lru_accessed) memset(h->lru_accessed, 0, hdr->max_table_cap);
        hdr->lru_head = SHM_LRU_NONE;
        hdr->lru_tail = SHM_LRU_NONE;
    }

    /* reset TTL (full max_table_cap range) */
    if (h->expires_at) {
        memset(h->expires_at, 0, hdr->max_table_cap * sizeof(uint32_t));
        hdr->flush_cursor = 0;
    }

    hdr->table_gen++;

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);

    h->iter_pos = 0;
    if (h->iter_active) {
        h->iter_active = 0;
        if (h->iterating > 0) h->iterating--;
    }
    h->deferred = 0;
}

/* ---- Iterator reset ---- */

static inline void SHM_FN(iter_reset)(ShmHandle *h) {
    if (h->shard_handles) {
        for (uint32_t i = 0; i < h->num_shards; i++)
            SHM_FN(iter_reset)(h->shard_handles[i]);
        h->shard_iter = 0;
        return;
    }
    if (h->iter_active) {
        h->iter_active = 0;
        if (h->iterating > 0) h->iterating--;
    }
    h->iter_pos = 0;
}

/* ---- Get or set (atomic: lookup + insert under single wrlock) ---- */

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
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(hdr);
    shm_seqlock_write_begin(&hdr->seq);

    SHM_FN(maybe_grow)(h);
    uint32_t mask = hdr->table_cap - 1;
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            /* TTL check */
            if (SHM_IS_EXPIRED(h, idx, now)) {
                SHM_FN(expire_at)(h, idx);
                if (insert_pos == UINT32_MAX) insert_pos = idx;
                break;
            }

#ifdef SHM_VAL_IS_STR
            {
                uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
                if (!shm_ensure_copy_buf(h, vl)) {
                    shm_seqlock_write_end(&hdr->seq);
                    shm_rwlock_wrunlock(hdr);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, vl);
                *out_str = h->copy_buf;
                *out_len = vl;
                *out_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
            }
#else
            *out_value = nodes[idx].value;
#endif
            if (h->lru_prev) shm_lru_promote(h, idx);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[idx] != 0)
                h->expires_at[idx] = shm_expiry_ts(hdr->default_ttl);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
            return 1;
        }
    }

    /* not found — insert default value */
    if (insert_pos == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }

    /* LRU eviction only when actually inserting a new entry */
    if (hdr->max_size > 0 && hdr->size >= hdr->max_size)
        SHM_FN(lru_evict_one)(h);

    int was_tombstone = (states[insert_pos] == SHM_TOMBSTONE);

#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8)) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }
#endif

#ifdef SHM_VAL_IS_STR
    if (!shm_ensure_copy_buf(h, def_len > 0 ? def_len : 1)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, def_str, def_len, def_utf8)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(hdr);
        return 0;
    }
#else
    nodes[insert_pos].value = def_value;
#endif

    states[insert_pos] = SHM_MAKE_TAG(hash);
    hdr->size++;
    if (was_tombstone) hdr->tombstones--;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);
    if (h->expires_at && hdr->default_ttl > 0)
        h->expires_at[insert_pos] = shm_expiry_ts(hdr->default_ttl);

#ifdef SHM_VAL_IS_STR
    memcpy(h->copy_buf, def_str, def_len);
    *out_str = h->copy_buf;
    *out_len = def_len;
    *out_utf8 = def_utf8;
#else
    *out_value = def_value;
#endif
    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(hdr);
    return 2; /* 2 = inserted new */
}

/* ---- Each (iterator) ---- */

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
    /* Sharded: chain each() across shards */
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
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_rdlock(hdr);

    if (!h->iter_active) {
        h->iter_active = 1;
        h->iter_gen = hdr->table_gen;
        h->iterating++;
    }

    /* Auto-reset on cross-process resize */
    if (h->iter_gen != hdr->table_gen) {
        h->iter_pos = 0;
        h->iter_gen = hdr->table_gen;
    }

    while (shm_find_next_live(states, hdr->table_cap, &h->iter_pos)) {
        uint32_t pos = h->iter_pos++;
        {
            /* skip expired entries */
            if (SHM_IS_EXPIRED(h, pos, now))
                continue;

#ifdef SHM_KEY_IS_INT
            *out_key = nodes[pos].key;
#else
            {
                uint32_t kl = SHM_STR_LEN(nodes[pos].key_len);
#ifdef SHM_VAL_IS_STR
                uint32_t vl = SHM_STR_LEN(nodes[pos].val_len);
                uint64_t total64 = (uint64_t)kl + vl;
                if (total64 > UINT32_MAX) {
                    h->iter_pos = 0;
                    h->iter_active = 0;
                    if (h->iterating > 0) h->iterating--;
                    shm_rwlock_rdunlock(hdr);
                    return 0;
                }
                uint32_t total = (uint32_t)total64;
#else
                uint32_t total = kl;
#endif
                if (!shm_ensure_copy_buf(h, total)) {
                    h->iter_pos = 0;
                    h->iter_active = 0;
                    if (h->iterating > 0) h->iterating--;
                    shm_rwlock_rdunlock(hdr);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[pos].key_off, nodes[pos].key_len, h->arena, kl);
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
                shm_str_copy(h->copy_buf + kl, nodes[pos].val_off, nodes[pos].val_len, h->arena, vl);
                *out_val_str = h->copy_buf + kl;
#else
                if (!shm_ensure_copy_buf(h, vl)) {
                    h->iter_pos = 0;
                    h->iter_active = 0;
                    if (h->iterating > 0) h->iterating--;
                    shm_rwlock_rdunlock(hdr);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[pos].val_off, nodes[pos].val_len, h->arena, vl);
                *out_val_str = h->copy_buf;
#endif
                *out_val_len = vl;
                *out_val_utf8 = SHM_UNPACK_UTF8(nodes[pos].val_len);
            }
#else
            *out_value = nodes[pos].value;
#endif
            shm_rwlock_rdunlock(hdr);
            return 1;
        }
    }

    h->iter_pos = 0;
    h->iter_active = 0;
    if (h->iterating > 0) h->iterating--;
    shm_rwlock_rdunlock(hdr);
    return 0;  /* caller should call flush_deferred */
}

/* ---- Cursor iteration ---- */

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
    /* Chain across shards: when current shard exhausted, move to next */
    while (c->shard_idx < c->shard_count) {
        ShmHandle *h = c->current;
        ShmHeader *hdr = h->hdr;
        SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
        uint8_t *states = h->states;
        uint32_t now = h->expires_at ? shm_now() : 0;

        shm_rwlock_rdlock(hdr);

        /* Auto-reset on cross-process resize */
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
                    uint64_t total64 = (uint64_t)kl + vl;
                    if (total64 > UINT32_MAX) {
                        shm_rwlock_rdunlock(hdr);
                        return 0;
                    }
                    uint32_t total = (uint32_t)total64;
#else
                    uint32_t total = kl;
#endif
                    if (!shm_cursor_ensure_copy_buf(c, total)) {
                        shm_rwlock_rdunlock(hdr);
                        return 0;
                    }
                    shm_str_copy(c->copy_buf, nodes[pos].key_off, nodes[pos].key_len, h->arena, kl);
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
                    shm_str_copy(c->copy_buf + kl, nodes[pos].val_off, nodes[pos].val_len, h->arena, vl);
                    *out_val_str = c->copy_buf + kl;
#else
                    if (!shm_cursor_ensure_copy_buf(c, vl)) {
                        shm_rwlock_rdunlock(hdr);
                        return 0;
                    }
                    shm_str_copy(c->copy_buf, nodes[pos].val_off, nodes[pos].val_len, h->arena, vl);
                    *out_val_str = c->copy_buf;
#endif
                    *out_val_len = vl;
                    *out_val_utf8 = SHM_UNPACK_UTF8(nodes[pos].val_len);
                }
#else
                *out_value = nodes[pos].value;
#endif
                shm_rwlock_rdunlock(hdr);
                return 1;
            }
        }

        shm_rwlock_rdunlock(hdr);

        /* Current shard exhausted — flush deferred work and advance */
        if (h->iterating > 0) h->iterating--;
        SHM_FN(flush_deferred)(h);
        c->shard_idx++;
        if (c->shard_idx < c->shard_count) {
            ShmHandle *parent = c->handle;
            c->current = parent->shard_handles[c->shard_idx];
            c->current->iterating++;
            c->iter_pos = 0;
            c->gen = c->current->hdr->table_gen;
        }
    }

    return 0;
}

static inline void SHM_FN(cursor_reset)(ShmCursor *c) {
    /* Decrement current shard's iterating counter and flush deferred */
    if (c->current && c->current->iterating > 0)
        c->current->iterating--;
    SHM_FN(flush_deferred)(c->current);
    /* Reset to first shard */
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

/* Position cursor at the slot of a specific key. Returns 1 if found, 0 if not.
   Next cursor_next call will return this key's entry, then continue forward. */
static int SHM_FN(cursor_seek)(ShmCursor *c,
#ifdef SHM_KEY_IS_INT
    SHM_KEY_INT_TYPE key
#else
    const char *key_str, uint32_t key_len, bool key_utf8
#endif
) {
    /* For sharded maps, route to the correct shard based on key hash */
#ifdef SHM_KEY_IS_INT
    uint32_t hash = SHM_HASH_KEY(key);
#else
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
    ShmHandle *parent = c->handle;
    ShmHandle *target;
    uint32_t target_shard = 0;
    if (parent->shard_handles) {
        target_shard = hash & parent->shard_mask;
        target = parent->shard_handles[target_shard];
    } else {
        target = parent;
    }

    /* Switch cursor to the target shard */
    if (target != c->current) {
        if (c->current && c->current->iterating > 0)
            c->current->iterating--;
        SHM_FN(flush_deferred)(c->current);
        c->current = target;
        c->current->iterating++;
        c->shard_idx = target_shard;
    }

    ShmHandle *h = c->current;
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_rdlock(hdr);

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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            if (SHM_IS_EXPIRED(h, idx, now)) {
                shm_rwlock_rdunlock(hdr);
                return 0;
            }
            c->iter_pos = idx;
            c->gen = hdr->table_gen;
            shm_rwlock_rdunlock(hdr);
            return 1;
        }
    }

    shm_rwlock_rdunlock(hdr);
    return 0;
}

/* ---- Undefine template macros ---- */

#undef SHM_PASTE2
#undef SHM_PASTE
#undef SHM_FN
#undef SHM_NODE_TYPE
#undef SHM_PREFIX
#undef SHM_VARIANT_ID

#ifdef SHM_KEY_IS_INT
  #undef SHM_KEY_IS_INT
  #undef SHM_KEY_INT_TYPE
  #undef SHM_HASH_KEY
  #undef SHM_KEY_EQ
#else
  #undef SHM_HASH_KEY_STR
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
