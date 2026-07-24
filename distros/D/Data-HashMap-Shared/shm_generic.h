/*
 * shm_generic.h -- Macro-template for shared-memory hash maps.
 *
 * Before including, define:
 *   SHM_PREFIX         -- function prefix (e.g., shm_ii)
 *   SHM_NODE_TYPE      -- node struct name
 *   SHM_VARIANT_ID     -- unique integer for header validation
 *
 * Key type (choose one):
 *   SHM_KEY_IS_INT + SHM_KEY_INT_TYPE  -- integer key
 *   (leave undefined for string keys via arena)
 *
 * Value type (choose one):
 *   SHM_VAL_IS_STR                      -- string value via arena
 *   SHM_VAL_INT_TYPE                    -- integer value
 *
 * Optional:
 *   SHM_HAS_COUNTERS  -- generate incr/decr/incr_by, max/min, and integer cas (integer values only)
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
#include <pthread.h>  /* pthread_atfork -- available in libc on modern glibc; no -lpthread needed */
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
#define SHM_VERSION     10U  /* 10: added the occupancy bitmap region (layout change) */
#ifndef SHM_READER_SLOTS
#define SHM_READER_SLOTS 1024  /* max concurrent reader processes for dead-process recovery */
#endif
/* Occupancy bitmap: one bit per reader slot, set when a process claims a slot and
 * cleared on clean release.  A writer scans these SHM_OCC_WORDS words to visit
 * only OCCUPIED slots (O(words + live readers)) instead of all SHM_READER_SLOTS. */
#define SHM_OCC_WORDS   (((SHM_READER_SLOTS) + 63) / 64)   /* 16 for 1024 slots */
#define SHM_OCC_BYTES   ((uint64_t)SHM_OCC_WORDS * 8)      /* 128 bytes */
#define SHM_INITIAL_CAP 16
#define SHM_MAX_STR_LEN 0x3FFFFFFFU  /* ~1GB, bit 30 reserved for inline flag */
#define SHM_LRU_NONE    UINT32_MAX

/* UINT32_MAX = use default TTL; 0 = no TTL; other = per-key TTL */
#define SHM_TTL_USE_DEFAULT UINT32_MAX

#define SHM_IS_EXPIRED(h, i, now) \
    ((h)->expires_at && (h)->expires_at[(i)] && \
     (now) >= (h)->expires_at[(i)])

/* Fast monotonic seconds -- avoids time() syscall overhead.
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
 * Works on contiguous memory -- caller must handle table wrap. */
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
 *   bit 30       = INLINE flag (string <= 7 bytes stored in off+len fields)
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

/* Arena-mode packing (unchanged for <=1GB strings) */
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
    uint32_t drain_seq;       /* 68: futex bumped by a reader releasing under a draining writer
                                 (wakes it). Was rwlock_writers_waiting; same offset/size. */
    uint64_t arena_cap;       /* 72: immutable, read by seqlock string path */
    uint64_t reader_slots_off;/* 80: offset of reader-PID slot table for dead-reader recovery */
    uint32_t slotless_rdepth; /* 88: read-locks held by readers with no reader-slot (documented
                                 residual). Was slotless_readers; same offset/size. */
    uint32_t arena_large_free;/* 92: head of the >2^19 large-block free list (was reserved; 0=empty) */
    uint8_t  _reserved1[32];  /* 96-127 */

    /* ---- Cache line 2 (128-191): rwlock + write-hot fields ---- */
    uint32_t wlock;           /* 128: WRITER word ONLY: 0 (free) or 0x80000000|pid.  NOT a reader count. */
    uint32_t rwait;           /* 132: parked-waiter hint (readers+writers blocked on wlock); over-count-safe */
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
} ShmReaderSlot;

/* ---- Process-local handle ---- */

typedef struct ShmHandle_s {
    ShmHeader *hdr;
    void      *nodes;
    uint8_t   *states;
    char      *arena;
    uint32_t  *lru_prev;    /* NULL if LRU disabled */
    uint32_t  *lru_next;    /* NULL if LRU disabled */
    uint8_t   *lru_accessed; /* NULL if LRU disabled -- clock second-chance bit */
    uint32_t  *expires_at;  /* NULL if TTL disabled */
    ShmReaderSlot *reader_slots; /* SHM_READER_SLOTS entries */
    uint64_t  *occ;          /* SHM_OCC_WORDS-word slot-occupancy bitmap (trusted layout offset) */
    uint32_t   my_slot_idx;  /* UINT32_MAX if all slots taken (no recovery for this handle) */
    uint32_t   cached_pid;   /* getpid() cached at last slot claim */
    uint32_t   cached_fork_gen; /* shm_fork_gen value at last slot claim -- mismatch triggers reclaim */
    uint32_t slotless_held; /* rwlock read-locks held with no reader-slot */
    uint32_t lock_depth;    /* locks this process holds via RDLOCK_GUARD/WRSEQ_GUARD */
    uint8_t  pending_close; /* DESTROY arrived while lock_depth > 0; free at depth 0 */
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
    int        backing_fd;  /* memfd fd to close on destroy, -1 otherwise */
    /* Sharding: if shard_handles != NULL, this is a sharded map dispatcher */
    struct ShmHandle_s **shard_handles; /* NULL for single map */
    uint32_t   num_shards;
    uint32_t   shard_mask;     /* num_shards - 1 (power of 2) */
    uint32_t   shard_iter;     /* current shard for each()/cursor iteration */
} ShmHandle;

/* ---- Cursor (independent iterator) ---- */

typedef struct {
    ShmHandle *handle;       /* for single maps, direct handle; for sharded, the dispatcher */
    ShmHandle *current;      /* current shard handle (== handle for single maps) */
    SV        *owner;        /* ref to the map's referent SV; keeps the mmap/handle alive while the cursor lives */
    uint32_t   iter_pos;
    uint32_t   gen;          /* table_gen snapshot -- reset on mismatch */
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

/* Writer word encoding: WRITER_BIT|pid when write-locked, 0 when free. */
#define SHM_RWLOCK_WRITER_BIT 0x80000000U
#define SHM_RWLOCK_PID_MASK   0x7FFFFFFFU
#define SHM_RWLOCK_WR(pid)    (SHM_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & SHM_RWLOCK_PID_MASK))

/* Check if a PID is alive. Returns 1 if alive or unknown, 0 if definitely dead. */
/* Liveness via kill(pid,0). NOTE: cannot detect PID reuse -- if a dead
 * lock-holder's PID is recycled to an unrelated live process before recovery
 * runs, this reports "alive" and that slot's orphaned contribution is not
 * reclaimed until the recycled process exits. Robust detection would require
 * a per-slot process-start-time epoch (a header-layout/SHM_VERSION change).
 * Documented under "Crash Safety" in the POD. */
/* A zombie (dead but not yet reaped) still answers kill(pid,0) as alive, so a
 * process that crashed while holding the lock and lingers unreaped would never
 * be recovered.  Treat /proc/<pid>/stat state 'Z' as dead.  Linux-only (as is
 * this module); if /proc is unreadable we fall back to "alive" (safe: we never
 * force-recover a possibly-live holder). */
static inline int shm_pid_is_zombie(uint32_t pid) {
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
static inline int shm_pid_alive(uint32_t pid) {
    if (pid == 0) return 1; /* no owner recorded, assume alive */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    return !shm_pid_is_zombie(pid); /* kill() also succeeds for a zombie -> treat as dead */
}

/* Forward declaration -- defined later in the LRU helpers section. */
static void shm_lru_rebuild_if_corrupt(ShmHandle *h);

/* Force-recover a stale write lock left by a dead process.
 * CAS to OUR pid to hold the lock while fixing seqlock, then release.
 * Using our pid (not a bare WRITER_BIT sentinel) means a subsequent
 * recovering process can detect and re-recover if we crash mid-recovery. */
static inline void shm_recover_stale_lock(ShmHandle *h, uint32_t observed_wlock) {
    ShmHeader *hdr = h->hdr;
    uint32_t mypid = SHM_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->wlock, &observed_wlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    /* We now hold the write lock as mypid.  Repair shared state -- the
     * seqlock counter (if dead writer left it odd) and the LRU doubly-
     * linked list (if dead writer left it one-way-broken) -- while no
     * other process can mutate them. */
    uint32_t seq = __atomic_load_n(&hdr->seq, __ATOMIC_RELAXED);
    if (seq & 1)
        __atomic_store_n(&hdr->seq, seq + 1, __ATOMIC_RELEASE);
    shm_lru_rebuild_if_corrupt(h);
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    /* Release the lock */
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec shm_lock_timeout = { SHM_LOCK_TIMEOUT_SEC, 0 };

/* Process-global fork-generation counter.  Incremented in the pthread_atfork
 * child callback so every open handle detects a fork transition on the next
 * lock call without paying a getpid() syscall on the hot path. */
static uint32_t shm_fork_gen = 1;
static pthread_once_t shm_atfork_once = PTHREAD_ONCE_INIT;
static void shm_on_fork_child(void) {
    __atomic_add_fetch(&shm_fork_gen, 1, __ATOMIC_RELAXED);
}
static void shm_atfork_init(void) {
    pthread_atfork(NULL, NULL, shm_on_fork_child);
}

/* Ensure this process owns a reader slot.  Called from the lock helpers so
 * that fork()'d children pick up their own slot lazily instead of sharing
 * the parent's.  Hot-path is a single relaxed load + compare; only on a
 * fork-generation mismatch do we touch getpid() and scan slots. */
/* Occupancy bitmap: set a slot's bit when it is claimed, clear it on clean
 * release.  SEQ_CST so a set bit is ordered before the slot's rdepth can go
 * non-zero (bit set in claim, which precedes any rdlock), letting a writer's
 * SEQ_CST bitmap scan never miss a slot a committed reader holds. */
static inline void shm_occ_set(ShmHandle *h, uint32_t s) {
    __atomic_fetch_or(&h->occ[s >> 6], (uint64_t)1 << (s & 63), __ATOMIC_SEQ_CST);
}
static inline void shm_occ_clear(ShmHandle *h, uint32_t s) {
    __atomic_fetch_and(&h->occ[s >> 6], ~((uint64_t)1 << (s & 63)), __ATOMIC_SEQ_CST);
}

static inline void shm_claim_reader_slot(ShmHandle *h) {
    uint32_t cur_gen = __atomic_load_n(&shm_fork_gen, __ATOMIC_RELAXED);
    if (__builtin_expect(cur_gen == h->cached_fork_gen && h->my_slot_idx != UINT32_MAX, 1))
        return;
    /* Cold path -- register the atfork hook once per process, then claim. */
    pthread_once(&shm_atfork_once, shm_atfork_init);
    /* Re-read after pthread_once: shm_on_fork_child may have bumped it. */
    cur_gen = __atomic_load_n(&shm_fork_gen, __ATOMIC_RELAXED);
    uint32_t now_pid = (uint32_t)getpid();
    h->cached_pid = now_pid;
    if (cur_gen != h->cached_fork_gen) h->slotless_held = 0;  /* fork: child holds none of the parent's slotless read locks */
    h->cached_fork_gen = cur_gen;
    h->my_slot_idx = UINT32_MAX;
    uint32_t start = now_pid % SHM_READER_SLOTS;
    /* Pass 1: take a free slot. */
    for (uint32_t i = 0; i < SHM_READER_SLOTS; i++) {
        uint32_t s = (start + i) % SHM_READER_SLOTS;
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&h->reader_slots[s].pid,
                &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            /* Fresh owner holds no read locks yet; clear any stale rdepth left by
             * a dead predecessor (its contribution is dropped as we take over). */
            __atomic_store_n(&h->reader_slots[s].rdepth, 0, __ATOMIC_RELAXED);
            shm_occ_set(h, s);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = s;
            return;
        }
    }
    /* Pass 2: no free slot -- reclaim one whose owner is dead.  Safe to take even
     * if its rdepth>0: clearing pid drops the dead reader's entire contribution
     * (a writer scan ignores rdepth when pid==0) and we reset rdepth to 0 as we
     * claim it.  No orphaned shared counter exists to preserve, so (unlike the
     * old design) we need not skip dead slots that still show a read count. */
    for (uint32_t i = 0; i < SHM_READER_SLOTS; i++) {
        uint32_t dpid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
        if (dpid == 0 || dpid == now_pid || shm_pid_alive(dpid)) continue;
        uint32_t expected = dpid;
        if (__atomic_compare_exchange_n(&h->reader_slots[i].pid, &expected, now_pid, 0,
                __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->reader_slots[i].rdepth, 0, __ATOMIC_RELAXED);
            shm_occ_set(h, i);   /* mark occupied BEFORE any rdlock can bump rdepth */
            h->my_slot_idx = i;
            return;
        }
    }
    /* Table full -- leave my_slot_idx = UINT32_MAX so this handle takes the
     * slotless path (lock still works; recovery of THIS reader's death is the
     * documented slotless limitation). */
}

/* Inspect the writer word after a futex-wait timeout.  If a dead writer holds
 * it, force-recover the lock (which also rebuilds the LRU list if it was left
 * half-linked, all under the recovered write lock).  Dead READERS need no action
 * here: only a writer that owns wlock drains readers, and it clears dead readers
 * inline in its own scan. */
static inline void shm_recover_after_timeout(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
    if (val >= SHM_RWLOCK_WRITER_BIT) {
        uint32_t pid = val & SHM_RWLOCK_PID_MASK;
        if (!shm_pid_alive(pid))
            shm_recover_stale_lock(h, val);
    }
}

/* Bump/drop the parked-waiter hint.  Both readers (blocked at the gate) and
 * writers (blocked acquiring wlock) wait on the wlock futex and use this, so
 * wrunlock/recover know whether a FUTEX_WAKE is worth a syscall.  A waiter
 * SIGKILLed while parked leaves rwait over-counted -> at most a spurious wake
 * (harmless); it can never under-count, so no wakeup is lost. */
static inline void shm_park(ShmHandle *h) {
    __atomic_add_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}
static inline void shm_unpark(ShmHandle *h) {
    __atomic_sub_fetch(&h->hdr->rwait, 1, __ATOMIC_RELAXED);
}

/* Publish (inc) / retract (dec) this reader's presence -- its ENTIRE
 * contribution to the lock.  A slotted reader uses its slot's rdepth; a reader
 * that could not claim a slot uses the global slotless_rdepth.  inc() is SEQ_CST
 * so the wlock re-check that follows it in rdlock forms a Dekker handshake with
 * the writer's SEQ_CST wlock-store + rdepth-scan.  dec() peels slotless first so
 * a slot claimed mid-hold cannot misattribute the decrement. */
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
        __atomic_sub_fetch(&h->hdr->slotless_rdepth, 1, __ATOMIC_RELEASE);
    } else if (h->my_slot_idx != UINT32_MAX) {
        __atomic_sub_fetch(&h->reader_slots[h->my_slot_idx].rdepth, 1, __ATOMIC_RELEASE);
    }
}

/* Wake a writer that may be draining readers (it waits on drain_seq).  Called
 * after every rdepth decrement so a released read lock lets the writer re-scan
 * promptly instead of waiting out its timeout. */
static inline void shm_reader_wake_drain(ShmHandle *h) {
    if (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0) {
        __atomic_add_fetch(&h->hdr->drain_seq, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &h->hdr->drain_seq, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void shm_rwlock_rdlock(ShmHandle *h) {
    shm_claim_reader_slot(h);
    ShmHeader *hdr = h->hdr;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(&hdr->wlock, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            /* Optimistically take the read: publish rdepth, then re-check wlock.
             * SEQ_CST inc + SEQ_CST load vs the writer's SEQ_CST wlock CAS +
             * SEQ_CST rdepth scan: by the single total order of SEQ_CST ops the
             * two sides cannot both miss each other, so we never hold
             * concurrently with a writer. */
            shm_rdepth_inc(h);
            if (__atomic_load_n(&hdr->wlock, __ATOMIC_SEQ_CST) == 0)
                return;                       /* no writer after our publish -> we hold the read lock */
            /* A writer appeared during our publish -- yield to it (write-preferring). */
            shm_rdepth_dec(h);
            shm_reader_wake_drain(h);          /* let the draining writer see rdepth drop */
            spin = 0;
            continue;
        }
        /* wlock != 0: a writer holds or is acquiring.  Recover if it is dead. */
        if (cur >= SHM_RWLOCK_WRITER_BIT &&
            !shm_pid_alive(cur & SHM_RWLOCK_PID_MASK)) {
            shm_recover_stale_lock(h, cur);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < SHM_RWLOCK_SPIN_LIMIT, 1)) {
            shm_rwlock_spin_pause();
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
    shm_rdepth_dec(h);                 /* RELEASE: drop our entire contribution */
    shm_reader_wake_drain(h);          /* if a writer is draining, wake it to re-scan */
}

static inline void shm_rwlock_wrlock(ShmHandle *h) {
    shm_claim_reader_slot(h);  /* refresh cached_pid across fork */
    ShmHeader *hdr = h->hdr;
    /* Encode PID in the wlock word itself (0x80000000 | pid) to eliminate any
     * crash window between acquiring the lock and storing the owner. */
    uint32_t mypid = SHM_RWLOCK_WR(h->cached_pid);
    /* Phase 1: acquire the writer word (mutual exclusion among writers). */
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->wlock, &expected, mypid,
                0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
            break;
        /* Contended: expected now holds the current wlock value. */
        if (expected >= SHM_RWLOCK_WRITER_BIT &&
            !shm_pid_alive(expected & SHM_RWLOCK_PID_MASK)) {
            shm_recover_stale_lock(h, expected);
            spin = 0;
            continue;
        }
        if (__builtin_expect(spin < SHM_RWLOCK_SPIN_LIMIT, 1)) {
            shm_rwlock_spin_pause();
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
    /* Phase 2: we own wlock, so no NEW reader can join (they see wlock!=0 and
     * yield).  Drain the readers that were already holding when we won the CAS.
     * The SEQ_CST CAS above + the SEQ_CST rdepth loads below are the writer side
     * of the Dekker handshake. */
    for (;;) {
        uint32_t v = __atomic_load_n(&hdr->drain_seq, __ATOMIC_RELAXED);  /* snapshot BEFORE scan */
        int busy = 0;
        /* Visit only OCCUPIED slots via the occupancy bitmap (SEQ_CST: a committed
         * reader's bit -- set in claim, before its rdepth++ -- is ordered before
         * this scan, so no held slot is skipped).  O(SHM_OCC_WORDS + live readers)
         * instead of O(SHM_READER_SLOTS). */
        for (uint32_t w = 0; w < SHM_OCC_WORDS; w++) {
            uint64_t word = __atomic_load_n(&h->occ[w], __ATOMIC_SEQ_CST);
            while (word) {
                uint32_t i = (w << 6) + (uint32_t)__builtin_ctzll(word);
                word &= word - 1;                          /* consume this bit (local copy) */
                uint32_t rd = __atomic_load_n(&h->reader_slots[i].rdepth, __ATOMIC_SEQ_CST);
                if (rd == 0) continue;                      /* occupied but not read-locking now */
                uint32_t pid = __atomic_load_n(&h->reader_slots[i].pid, __ATOMIC_ACQUIRE);
                if (pid == 0) continue;                     /* stale rdepth on a freed slot */
                if (!shm_pid_alive(pid)) {
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
        syscall(SYS_futex, &hdr->drain_seq, FUTEX_WAIT, v, &shm_lock_timeout, NULL, 0);
    }
}

static inline void shm_rwlock_wrunlock(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    __atomic_store_n(&hdr->wlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwait, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ---- Seqlock (lock-free readers) ---- */

static inline uint32_t shm_seqlock_read_begin(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    int spin = 0;
    for (;;) {
        uint32_t s = __atomic_load_n(&hdr->seq, __ATOMIC_ACQUIRE);
        if (__builtin_expect((s & 1) == 0, 1)) return s;
        if (__builtin_expect(spin < 100000, 1)) {
            shm_rwlock_spin_pause();
            spin++;
            continue;
        }
        /* Prolonged odd seq -- check for dead writer */
        uint32_t val = __atomic_load_n(&hdr->wlock, __ATOMIC_RELAXED);
        if (val >= SHM_RWLOCK_WRITER_BIT) {
            uint32_t pid = val & SHM_RWLOCK_PID_MASK;
            if (!shm_pid_alive(pid)) {
                shm_recover_stale_lock(h, val);
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
    /* StoreStore (Linux write_seqcount_begin's smp_wmb): the odd seq must be
     * visible before the entry writes that follow, or an ARM64 reader could
     * load an even seq yet observe half-written data and pass read_retry. */
    __atomic_thread_fence(__ATOMIC_RELEASE);
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
        /* Free-list heads are peer-writable: a wild head would send both the
         * pop read below and the caller's string store out of bounds.  Gate
         * against arena_cap (read-path clamp discipline); on corruption treat
         * the class as empty and fall back to bump allocation. */
        if ((uint64_t)head + asize <= hdr->arena_cap) {
            uint32_t next;
            memcpy(&next, arena + head, sizeof(uint32_t));
            hdr->arena_free[cls] = next;
            return head;
        }
    }
    if (cls < 0) {
        /* Large request: first-fit over the large free list before bumping. */
        uint32_t prev = 0, cur = hdr->arena_large_free;
        while (cur != 0) {
            uint32_t next, blk;
            /* cur is peer-writable: never dereference a wild offset; abandon
             * the walk and fall back to bump allocation.  Gating cur+asize
             * also covers the 8-byte [next][size] read (asize > 2^19 here). */
            if ((uint64_t)cur + asize > hdr->arena_cap) break;
            memcpy(&next, arena + cur, sizeof(uint32_t));
            memcpy(&blk, arena + cur + sizeof(uint32_t), sizeof(uint32_t));
            if (blk >= asize) {
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
    if (off == 0) return;
    /* off comes from a peer-writable node field: a wild value would send the
     * free-list link write below out of bounds.  Leak the block instead. */
    if ((uint64_t)off + asize > hdr->arena_cap) return;
    if (cls < 0) {
        /* Large block (> 2^19): single first-fit free list keyed by size, so
         * churn of >512 KiB values recycles instead of leaking to bump-only.
         * The block (>= 2^20 bytes) has ample room for the [next][size] head. */
        uint32_t old_head = hdr->arena_large_free;
        memcpy(arena + off, &old_head, sizeof(uint32_t));                  /* next */
        memcpy(arena + off + sizeof(uint32_t), &asize, sizeof(uint32_t));  /* size */
        hdr->arena_large_free = off;
        return;
    }
    uint32_t old_head = hdr->arena_free[cls];
    memcpy(arena + off, &old_head, sizeof(uint32_t));
    hdr->arena_free[cls] = off;
}

/* Store a string: inline if <= 7 bytes, arena otherwise. Returns 1 on success, 0 on arena OOM. */
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
                                 const char *arena, uint32_t arena_cap, uint32_t len) {
    if (SHM_IS_INLINE(len_field)) {
        shm_inline_read(off, len_field, dst);
    } else if ((uint64_t)off + len <= arena_cap) {
        memcpy(dst, arena + off, len);
    } else {
        /* off/len come from the mmap'd node and a local peer
         * can corrupt the backing file. A poisoned record delivers zeros here
         * rather than reading out of bounds (CWE-125). The get path already
         * bounded this; centralizing it covers every other caller
         * (each/keys/values/pop/shift/take/swap/drain/cursor). */
        memset(dst, 0, len);
    }
}

/* ---- Utility ---- */

static inline uint32_t shm_next_pow2(uint32_t v) {
    if (v < 2) return 2;
    if (v > 0x80000000U) return 0;  /* overflow: no valid power of 2 */
    v--;
    v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16;
    return v + 1;
}

/* Largest power-of-2 table capacity for a given max_entries.
 * Cap at 2^31 (largest power-of-2 table the design supports) before
 * next_pow2: a huge max_entries would otherwise overflow the uint32
 * cast or make next_pow2 return 0, silently yielding a tiny table. */
static inline uint32_t shm_max_tcap_from_entries(uint32_t max_entries) {
    uint64_t want = (uint64_t)max_entries * 4 / 3 + 1;
    uint32_t cap = (want > 0x80000000ULL) ? 0x80000000U : shm_next_pow2((uint32_t)want);
    return cap < SHM_INITIAL_CAP ? SHM_INITIAL_CAP : cap;
}

/* Convert lru_skip percentage (0-99) to power-of-2 mask used by lru_promote.
 * skip=50->mask=1 (every 2nd), 75->3 (every 4th), 90->15 (every 16th),
 * 95->31 (every 32nd).  Values outside 1..99 disable skipping (mask=0). */
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
     * Branch-predictor friendly -- the skip branch is nearly always taken.
     * Tail entry is never skipped to preserve eviction correctness. */
    if (hdr->lru_skip > 0 && idx != hdr->lru_tail) {
        static __thread uint32_t promote_ctr = 0;
        if ((++promote_ctr & hdr->lru_skip) != 0)
            return;
    }
    shm_lru_unlink(h, idx);
    shm_lru_push_front(h, idx);
}

/* Validate the LRU doubly-linked list and rebuild it from `states[]` if
 * inconsistent.  Called from the writer-lock recovery path because a dead
 * writer killed mid-`lru_unlink`/`push_front`/`promote` leaves the list in
 * a one-way-broken state that could infinite-loop the next `lru_evict_one`.
 *
 * Rebuild semantics: the list is reconstructed in slot-index order (which
 * is meaningless for LRU correctness -- the clock-eviction algorithm
 * re-establishes locality on the next few promotes).  Loses ordering, not
 * correctness.  Variant-agnostic -- uses only the byte-array `states` and
 * the typeless lru_prev/lru_next arrays. */
static void shm_lru_rebuild_if_corrupt(ShmHandle *h) {
    if (!h->lru_prev) return;  /* LRU disabled */
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
            if (++chain_len > cap) { corrupt = 1; break; }  /* cycle */
        }
        if (!corrupt && prev_idx != tail) corrupt = 1;
    }
    /* Orphan check: a dead writer killed between any of states[i]=LIVE,
     * size++, and shm_lru_push_front leaves a slot in an inconsistent
     * subset of {states[], chain, hdr->size}.  Counting actual LIVE
     * entries and comparing against chain_len catches every window
     * (including the one where size is itself behind LIVE -- comparing
     * chain_len to hdr->size alone misses that case). */
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
    uint32_t rebuilt_count = 0;
    uint32_t tomb_count = 0;
    for (uint32_t i = 0; i < cap; i++) {
        uint8_t st = h->states[i];
        if (st == SHM_TOMBSTONE) { tomb_count++; continue; }
        if (!SHM_IS_LIVE(st)) continue;
        h->lru_prev[i] = prev;
        if (prev != SHM_LRU_NONE) h->lru_next[prev] = i;
        else new_head = i;
        prev = i;
        rebuilt_count++;
    }
    hdr->lru_head = new_head;
    hdr->lru_tail = prev;
    /* Reconcile hdr->size and hdr->tombstones with actual state[].
     * A dead writer mid-op may have left these counters out of sync;
     * resyncing here prevents downstream maybe_grow/maybe_shrink from
     * deciding based on stale counts. */
    hdr->size = rebuilt_count;
    hdr->tombstones = tomb_count;
    /* No stat_recoveries bump here -- caller (shm_recover_stale_lock) accounts
     * for the recovery event once, regardless of whether the LRU was rebuilt. */
}

/* ---- Create / Open / Close ---- */

/* Error buffer for shm_create_map diagnostics */
#define SHM_ERR_BUFLEN 256

/* Computed layout -- sizes and offsets of all variable-length regions
 * following the header. Filled by shm_compute_layout and used by both
 * create and reopen paths. */
typedef struct {
    uint64_t nodes_off, states_off;
    uint64_t lru_prev_off, lru_next_off, lru_accessed_off;
    uint64_t expires_off;
    uint64_t reader_slots_off;
    uint64_t occ_off;
    uint64_t arena_off, arena_cap;
    uint64_t total_size;
    uint64_t end_off;  /* end of LRU/TTL region -- caller verifies file is at least this large */
} ShmLayout;

/* Clamp a requested arena capacity to the usable range: a 4096-byte floor so
 * the arena is always functional, and a UINT32_MAX ceiling because arena
 * offsets are uint32. */
static inline uint64_t shm_clamp_arena_cap(uint64_t want) {
    if (want < 4096) return 4096;
    if (want > UINT32_MAX) return UINT32_MAX;
    return want;
}

/* Compute region offsets after the header.
 *   max_tcap, node_size: table dimensions
 *   has_lru, has_ttl, has_arena: which optional regions are present
 *   max_entries, arena_cap_override: only used when has_arena. arena_cap is
 *     arena_cap_override (bytes) when nonzero, else the ~128 B/entry default
 *     max(max_entries*128, 4096); both clamped via shm_clamp_arena_cap.
 * On create, the caller maps `lo->total_size` bytes; on reopen, the caller
 * verifies the file is at least `lo->end_off` bytes (reader_slots_off and
 * total_size are taken from the stored header). */
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
        lo->lru_accessed_off = off; off += max_tcap;  /* uint8_t per slot */
    }
    if (has_ttl) {
        off = (off + 3) & ~(uint64_t)3;
        lo->expires_off = off; off += (uint64_t)max_tcap * sizeof(uint32_t);
    }
    lo->end_off = off;
    off = (off + 7) & ~(uint64_t)7;
    lo->reader_slots_off = off;
    off += (uint64_t)SHM_READER_SLOTS * sizeof(ShmReaderSlot);
    lo->occ_off = off;                 /* occupancy bitmap right after reader_slots */
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

/* Initialize a freshly-mmap'd header and zero out the optional regions.
 * Used by both shm_create_map and shm_create_memfd. */
static inline void shm_init_header(ShmHeader *hdr, void *base,
                                    const ShmLayout *lo, uint32_t max_tcap,
                                    uint32_t node_size, uint32_t variant_id,
                                    int has_arena, int has_lru, int has_ttl,
                                    uint32_t max_size, uint32_t default_ttl,
                                    uint32_t lru_skip) {
    memset(hdr, 0, sizeof(ShmHeader));
    hdr->magic         = SHM_MAGIC;
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
    hdr->max_size      = max_size;
    hdr->default_ttl   = default_ttl;
    hdr->lru_skip      = shm_lru_skip_to_mask(lru_skip);
    hdr->lru_head      = SHM_LRU_NONE;
    hdr->lru_tail      = SHM_LRU_NONE;
    if (has_lru) {
        memset((char *)base + lo->lru_prev_off, 0xFF, max_tcap * sizeof(uint32_t));
        memset((char *)base + lo->lru_next_off, 0xFF, max_tcap * sizeof(uint32_t));
        memset((char *)base + lo->lru_accessed_off, 0, max_tcap);
    }
    if (has_ttl)
        memset((char *)base + lo->expires_off, 0, max_tcap * sizeof(uint32_t));
    memset((char *)base + lo->reader_slots_off, 0,
           SHM_READER_SLOTS * sizeof(ShmReaderSlot));
    /* Zero the occupancy bitmap explicitly: create does not memset the whole
     * mapping, so do not rely on OS zero-fill for this region. */
    memset((char *)base + lo->occ_off, 0, SHM_OCC_BYTES);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* Validate a header read from disk/fd. Returns 1 if valid, 0 otherwise.
 * Caller must already have verified file is at least sizeof(ShmHeader) bytes
 * and that hdr->total_size matches the file size. */
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

/* Format a header-validation error message into errbuf.  `prefix` is the
 * caller-supplied identifier (a path on the file-based create/reopen path,
 * the literal "fd" on the fd-reopen path).  Picks the first failing field
 * for clearer diagnostics; falls back to a generic "corrupt header". */
static inline void shm_format_header_error(char *errbuf, const char *prefix,
                                            const ShmHeader *hdr,
                                            uint32_t variant_id) {
    if (!errbuf) return;
    if (hdr->magic != SHM_MAGIC)
        snprintf(errbuf, SHM_ERR_BUFLEN, "%s: bad magic (not a HashMap::Shared file)", prefix);
    else if (hdr->version != SHM_VERSION)
        snprintf(errbuf, SHM_ERR_BUFLEN, "%s: version mismatch (file=%u, expected=%u)",
                 prefix, hdr->version, SHM_VERSION);
    else if (hdr->variant_id != variant_id)
        snprintf(errbuf, SHM_ERR_BUFLEN, "%s: variant mismatch (file=%u, expected=%u)",
                 prefix, hdr->variant_id, variant_id);
    else
        snprintf(errbuf, SHM_ERR_BUFLEN, "%s: corrupt header", prefix);
}

/* Recompute layout from a validated header and verify both the LRU/TTL
 * region and the reader_slots region fit inside `mapped_size`.  Returns
 * 1 on success (lo filled with disk-recorded reader_slots_off); 0 on
 * failure (errbuf populated). */
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
    /* Locate reader_slots from the trusted, locally-computed layout, NOT the
     * peer-writable hdr->reader_slots_off: a peer sharing the backing file that
     * corrupts the stored offset must not be able to misdirect our reader_slots
     * pointer.  We still sanity-gate the stored offset (rejects grossly corrupt
     * files) but bounds-check the locally-computed region against the real
     * mapping and keep lo->reader_slots_off as shm_compute_layout produced it. */
    uint64_t rs_off = hdr->reader_slots_off;
    if (!rs_off || rs_off < lo->end_off ||
        lo->reader_slots_off + SHM_READER_SLOTS * sizeof(ShmReaderSlot) > mapped_size) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN,
                             "%s: reader_slots region missing or out of bounds", prefix);
        return 0;
    }
    return 1;
}

/* Allocate the process-local ShmHandle given an already-mmap'd base and
 * a computed layout. Shared by shm_create_map, shm_create_memfd and
 * shm_open_fd_map; all three differ only in how they acquire `base`. */
static ShmHandle *shm_alloc_handle(void *base, uint64_t total_size,
                                    int has_arena, int has_lru, int has_ttl,
                                    const ShmLayout *lo,
                                    const char *path, int backing_fd, char *errbuf) {
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
    h->arena     = has_arena ? (char *)hdr + lo->arena_off : NULL;   /* trusted layout offset, like reader_slots */
    h->lru_prev  = has_lru ? (uint32_t *)((char *)hdr + lo->lru_prev_off) : NULL;
    h->lru_next  = has_lru ? (uint32_t *)((char *)hdr + lo->lru_next_off) : NULL;
    h->lru_accessed = has_lru ? (uint8_t *)((char *)hdr + lo->lru_accessed_off) : NULL;
    h->expires_at = has_ttl ? (uint32_t *)((char *)hdr + lo->expires_off) : NULL;
    h->reader_slots = (ShmReaderSlot *)((char *)hdr + lo->reader_slots_off);
    h->occ          = (uint64_t *)((char *)hdr + lo->occ_off);   /* trusted layout offset */
    /* Slot claimed lazily on first lock -- see shm_claim_reader_slot. */
    h->my_slot_idx = UINT32_MAX;
    h->cached_pid = 0;
    h->mmap_size = (size_t)total_size;
    h->max_mask  = hdr->max_table_cap - 1;
    h->iter_pos  = 0;
    h->backing_fd = backing_fd;
    /* Hash lookups are random-access: hint the kernel to skip
     * read-ahead. Best-effort -- failure (e.g., MADV_RANDOM not
     * supported) is harmless. */
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
    /* Pre-size copy_buf for string variants to avoid realloc on first access */
    if (has_arena) {
        h->copy_buf = (char *)malloc(256);
        if (h->copy_buf) h->copy_buf_size = 256;
    }
    return h;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at
 * file_mode, default 0600 = owner-only), or attach an existing file
 * (O_RDWR|O_NOFOLLOW, no O_CREAT). Blocks a symlink swap or a pre-seeded/
 * hard-linked backing file; cross-user sharing is opt-in via a wider file_mode. */
static int shm_secure_open(const char *path, mode_t file_mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, file_mode);
        if (fd >= 0) { (void)fchmod(fd, file_mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) {
            if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "create(%s): %s", path, strerror(errno));
            return -1;
        }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;   /* creator unlinked between our two opens; retry */
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "open(%s): %s", path, strerror(errno));
        return -1;
    }
    if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "open(%s): create/attach kept racing", path);
    return -1;
}

static ShmHandle *shm_create_map(const char *path, uint32_t max_entries,
                                  uint32_t node_size, uint32_t variant_id,
                                  int has_arena, uint32_t max_size,
                                  uint32_t default_ttl, uint32_t lru_skip,
                                  uint64_t arena_cap_override, mode_t file_mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    uint32_t max_tcap = shm_max_tcap_from_entries(max_entries);

    int has_lru = (max_size > 0);
    int has_ttl = (default_ttl > 0);

    ShmLayout lo;
    shm_compute_layout(&lo, max_tcap, node_size, has_lru, has_ttl, has_arena, max_entries, arena_cap_override);

    #define SHM_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

    int anonymous = (path == NULL);
    int fd = -1;
    int is_new;
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

        while (flock(fd, LOCK_EX) < 0) {
            if (errno == EINTR) continue;  /* retry: a signal interrupted the blocking lock */
            SHM_ERR("flock(%s): %s", path, strerror(errno)); close(fd); return NULL;
        }

        if (fstat(fd, &st) < 0) { SHM_ERR("fstat(%s): %s", path, strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }

        is_new = (st.st_size == 0);

        if (!is_new && (uint64_t)st.st_size < sizeof(ShmHeader)) {
            SHM_ERR("%s: file too small (%lld bytes, need %zu)", path,
                    (long long)st.st_size, sizeof(ShmHeader));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (is_new && (st.st_uid != geteuid() || fchmod(fd, file_mode) < 0)) {
            SHM_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new) {
            if (ftruncate(fd, (off_t)lo.total_size) < 0) {
                SHM_ERR("ftruncate(%s, %llu): %s", path, (unsigned long long)lo.total_size, strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
        }

        base = mmap(NULL, is_new ? lo.total_size : (size_t)st.st_size,
                     PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { SHM_ERR("mmap(%s): %s", path, strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
    }

    ShmHeader *hdr = (ShmHeader *)base;
    uint64_t mapped_size = is_new ? lo.total_size : (uint64_t)st.st_size;

    if (is_new) {
        shm_init_header(hdr, base, &lo, max_tcap, node_size, variant_id,
                        has_arena, has_lru, has_ttl, max_size, default_ttl, lru_skip);
    } else {
        int ok = (hdr->total_size == (uint64_t)st.st_size &&
                  shm_validate_header(hdr, variant_id, node_size));
        if (ok) {
            has_lru = (hdr->max_size > 0);
            has_ttl = (hdr->default_ttl > 0);
            ok = shm_validate_layout_regions(&lo, hdr, has_arena, mapped_size, errbuf, path);
        } else {
            shm_format_header_error(errbuf, path, hdr, variant_id);
        }
        if (!ok) {
            munmap(base, (size_t)st.st_size);
            flock(fd, LOCK_UN); close(fd);
            return NULL;
        }
    }

    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    #undef SHM_ERR

    return shm_alloc_handle(base, mapped_size, has_arena, has_lru, has_ttl,
                             &lo, path, -1, errbuf);
}

/* ---- memfd-backed map (fd-shareable, no filesystem presence) ---- */
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

    int fd = memfd_create(name ? name : "hashmap", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "memfd_create: %s", strerror(errno));
        return NULL;
    }
    if (ftruncate(fd, (off_t)lo.total_size) < 0) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "ftruncate: %s", strerror(errno));
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

    return shm_alloc_handle(base, lo.total_size, has_arena, has_lru, has_ttl,
                             &lo, NULL, fd, errbuf);
}

/* ---- Re-open a memfd (or any existing SHM-formatted fd) ---- */
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
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "mmap: %s", strerror(errno));
        return NULL;
    }

    ShmHeader *hdr = (ShmHeader *)base;
    if (hdr->total_size != (uint64_t)st.st_size ||
        !shm_validate_header(hdr, variant_id, node_size)) {
        shm_format_header_error(errbuf, "fd", hdr, variant_id);
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
                             &lo, NULL, myfd, errbuf);
}

static inline int shm_msync(ShmHandle *h) {
    if (!h) return 0;
    if (h->shard_handles) {
        for (uint32_t i = 0; i < h->num_shards; i++) {
            int rc;
            do { rc = msync(h->shard_handles[i]->hdr,
                            h->shard_handles[i]->mmap_size, MS_SYNC); }
            while (rc != 0 && errno == EINTR);  /* retry on signal interruption */
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

static void shm_close_map_now(ShmHandle *h);

/* Destroying a handle while THIS process holds one of its locks would leave the
 * save-stack lock cleanup (shm_rdunlock_cleanup / shm_wrseq_unlock_cleanup)
 * dereferencing freed memory on unwind -- the guards capture the raw handle
 * pointer. Argument magic can call $obj->DESTROY from inside a guarded region,
 * so defer the free until the last lock is released.
 * lock_depth lives in the process-local handle, not the shared segment: no
 * on-disk format change, and no atomics (a handle is never shared between
 * threads -- CLONE_SKIP forbids cloning it). */
static void shm_close_map(ShmHandle *h) {
    if (!h) return;
    if (h->lock_depth) { h->pending_close = 1; return; }
    shm_close_map_now(h);
}

static void shm_close_map_now(ShmHandle *h) {
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
    /* Release our reader slot -- only if we still own it AND no fork has
     * happened since we claimed it.  A forked child that inherits the
     * handle but never acquired the lock itself must NOT clear the
     * parent's slot via the inherited cached_pid (parent is still using
     * it).  The fork-generation check distinguishes the original owner
     * from a fork descendant that's about to exit. */
    if (h->reader_slots && h->my_slot_idx != UINT32_MAX && h->cached_pid &&
        h->cached_fork_gen == __atomic_load_n(&shm_fork_gen, __ATOMIC_RELAXED) &&
        __atomic_load_n(&h->reader_slots[h->my_slot_idx].rdepth, __ATOMIC_ACQUIRE) == 0) {
        /* rdepth==0: a still-held read lock's slot must survive for recovery */
        /* Clear our occ bit BEFORE freeing the slot: we still own the pid so no
         * claimant can take the slot mid-clear, and rdepth==0 so no writer needs
         * to see us.  (A crash skips this -> the bit is reclaimed lazily by a
         * writer scan / re-claim, same as the pid.) */
        shm_occ_clear(h, h->my_slot_idx);
        uint32_t expected = h->cached_pid;
        /* Just CAS pid -> 0; do NOT clear rdepth here -- between the CAS
         * and the store, a new process could claim the slot and start
         * incrementing rdepth, which our store would clobber.  The
         * next claimant's shm_claim_reader_slot zeros it. */
        __atomic_compare_exchange_n(&h->reader_slots[h->my_slot_idx].pid,
                &expected, 0, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED);
    }
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    if (h->backing_fd >= 0) close(h->backing_fd);
    free(h->copy_buf);
    free(h->path);
    free(h);
}

/* Create a sharded map: N independent maps behind one handle */
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
    h->backing_fd = -1;   /* dispatcher owns no fd; calloc left it 0 (=stdin) */
    h->path = strdup(path_prefix);
    if (!h->path) {
        if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, "strdup: out of memory");
        free(h->shard_handles);
        free(h);
        return NULL;
    }

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
                                               default_ttl, lru_skip, arena_cap_override, file_mode, errbuf);
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
    if (!h->shard_handles) {
        if (!h->path) return 0;
        return shm_unlink_path(h->path);
    }
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

/* ================================================================
 * v9 -> v10 on-disk migration (offline structural upcast).  The v10
 * layout inserts a 128-byte reader-slot occupancy bitmap between the
 * reader-slot table and the arena; a v9 file is byte-identical apart
 * from that missing region, so migration is a pure re-header + shift --
 * no re-hashing and no old library required.  Returns 1 if the file was
 * upgraded, 0 if it is already current (v10), -1 on error (errbuf set).
 * The caller MUST ensure no process has the file mapped.
 * ================================================================ */
#define SHMUP_ERR(...) do { if (errbuf) snprintf(errbuf, SHM_ERR_BUFLEN, __VA_ARGS__); } while (0)
#define SHM_UPGRADE_SRC_VERSION 9U   /* the single previous on-disk format this transform upgrades from */
/* Tripwire: this function implements EXACTLY the v9 -> v10 (occupancy-bitmap
 * insertion) transform and stamps the result as SHM_VERSION.  If the on-disk
 * format is ever bumped again, compilation fails here until the new step is
 * added and this assertion (and SHM_UPGRADE_SRC_VERSION) are updated -- so the
 * tool can never silently apply the wrong transform and mis-stamp a file. */
SHM_STATIC_ASSERT(SHM_VERSION == 10U,
    "shm_upgrade_file only knows v9 -> v10; extend it when SHM_VERSION changes");
static int shm_upgrade_file(const char *path, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    int fd = open(path, O_RDWR | O_NOFOLLOW | O_CLOEXEC);
    if (fd < 0) { SHMUP_ERR("open %s: %s", path, strerror(errno)); return -1; }
    struct stat st;
    if (fstat(fd, &st) != 0) { SHMUP_ERR("fstat %s: %s", path, strerror(errno)); close(fd); return -1; }
    if ((uint64_t)st.st_size < sizeof(ShmHeader)) {
        SHMUP_ERR("%s: too small to be a HashMap file (%lld bytes)", path, (long long)st.st_size);
        close(fd); return -1;
    }
    ShmHeader hdr;
    if (pread(fd, &hdr, sizeof hdr, 0) != (ssize_t)sizeof hdr) {
        SHMUP_ERR("read header %s: %s", path, strerror(errno)); close(fd); return -1;
    }
    if (hdr.magic != SHM_MAGIC) { SHMUP_ERR("%s: bad magic (not a HashMap::Shared file)", path); close(fd); return -1; }
    if (hdr.version == SHM_VERSION) { close(fd); return 0; }   /* already current */
    if (hdr.version != SHM_UPGRADE_SRC_VERSION) {
        SHMUP_ERR("%s: unsupported source version %u (migrates %u -> %u only)",
                  path, hdr.version, SHM_UPGRADE_SRC_VERSION, (unsigned)SHM_VERSION);
        close(fd); return -1;
    }
    if (hdr.wlock & 0x80000000U) {
        SHMUP_ERR("%s: locked by a live writer (pid %u); ensure no process is using it",
                  path, hdr.wlock & 0x7FFFFFFFU);
        close(fd); return -1;
    }
    if ((uint64_t)st.st_size != hdr.total_size) {
        SHMUP_ERR("%s: size mismatch (file=%lld, header=%llu)",
                  path, (long long)st.st_size, (unsigned long long)hdr.total_size);
        close(fd); return -1;
    }
    uint64_t rss = (uint64_t)SHM_READER_SLOTS * sizeof(ShmReaderSlot);
    uint64_t occ_off = hdr.reader_slots_off + rss;   /* v9 arena start == new occ-region start */
    if (hdr.reader_slots_off < sizeof(ShmHeader) || occ_off > hdr.total_size) {
        SHMUP_ERR("%s: reader-slot region out of range (corrupt header)", path); close(fd); return -1;
    }
    int has_arena = (hdr.arena_off != 0);
    if (has_arena ? (hdr.arena_off != occ_off) : (hdr.total_size != occ_off)) {
        SHMUP_ERR("%s: unexpected v9 layout; refusing to migrate", path); close(fd); return -1;
    }
    uint64_t old_size = hdr.total_size, new_size = old_size + SHM_OCC_BYTES;
    uint8_t *old = (uint8_t *)malloc((size_t)old_size);
    uint8_t *neu = (uint8_t *)malloc((size_t)new_size);
    if (!old || !neu) { SHMUP_ERR("out of memory"); free(old); free(neu); close(fd); return -1; }
    if (pread(fd, old, (size_t)old_size, 0) != (ssize_t)old_size) {
        SHMUP_ERR("read %s: %s", path, strerror(errno)); free(old); free(neu); close(fd); return -1;
    }
    close(fd);
    /* header..reader_slots copied verbatim; insert a zeroed occ region; shift the arena */
    memcpy(neu, old, (size_t)occ_off);
    memset(neu + occ_off, 0, (size_t)SHM_OCC_BYTES);
    memcpy(neu + occ_off + SHM_OCC_BYTES, old + occ_off, (size_t)(old_size - occ_off));
    free(old);
    ShmHeader *nh = (ShmHeader *)neu;
    nh->version    = SHM_VERSION;
    nh->total_size = new_size;
    if (has_arena) nh->arena_off += SHM_OCC_BYTES;
    /* reset transient lock/recovery state so the migrated file opens clean */
    nh->wlock = 0; nh->rwait = 0; nh->seq = 0; nh->drain_seq = 0; nh->slotless_rdepth = 0;
    memset(neu + hdr.reader_slots_off, 0, (size_t)rss);   /* drop any stale reader PIDs */
    /* write to a sibling temp file, fsync, atomic rename; preserve mode */
    size_t plen = strlen(path);
    char *tmp = (char *)malloc(plen + 16);
    if (!tmp) { SHMUP_ERR("out of memory"); free(neu); return -1; }
    snprintf(tmp, plen + 16, "%s.upgrade-tmp", path);
    int tfd = open(tmp, O_RDWR | O_CREAT | O_TRUNC | O_NOFOLLOW | O_CLOEXEC, st.st_mode & 07777);
    if (tfd < 0) { SHMUP_ERR("create %s: %s", tmp, strerror(errno)); free(neu); free(tmp); return -1; }
    (void)fchmod(tfd, st.st_mode & 07777);
    int ok = (write(tfd, neu, (size_t)new_size) == (ssize_t)new_size) && (fsync(tfd) == 0);
    free(neu);
    if (!ok)                 { SHMUP_ERR("write %s: %s", tmp, strerror(errno)); close(tfd); unlink(tmp); free(tmp); return -1; }
    if (close(tfd) != 0)     { SHMUP_ERR("close %s: %s", tmp, strerror(errno)); unlink(tmp); free(tmp); return -1; }
    if (rename(tmp, path) != 0) { SHMUP_ERR("rename %s: %s", tmp, strerror(errno)); unlink(tmp); free(tmp); return -1; }
    free(tmp);
    return 1;
}
#undef SHMUP_ERR
#undef SHM_UPGRADE_SRC_VERSION

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
  /* Keys are compared by bytes only. The stored UTF8 flag is metadata for
   * flag-restoration on retrieval; it must not affect lookup equality,
   * otherwise ASCII strings with toggled flag (easy to produce in Perl via
   * utf8::upgrade/downgrade, `use utf8`, or source literal encoding) would
   * miss their stored value. */
  static inline int SHM_PASTE(SHM_PREFIX, _key_eq_str)(
      const SHM_NODE_TYPE *np, const char *arena, const char *str, uint32_t len, bool utf8) {
      (void)utf8;
      uint32_t kl_packed = np->key_len;
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

/* This variant uses the arena (string keys and/or string values). */
#if !defined(SHM_KEY_IS_INT) || defined(SHM_VAL_IS_STR)
  #define SHM_HAS_ARENA 1
#else
  #define SHM_HAS_ARENA 0
#endif

static ShmHandle *SHM_FN(create)(const char *path, uint32_t max_entries,
                                  uint32_t max_size, uint32_t default_ttl,
                                  uint32_t lru_skip, uint64_t arena_cap_override,
                                  mode_t file_mode, char *errbuf) {
    return shm_create_map(path, max_entries,
                           (uint32_t)sizeof(SHM_NODE_TYPE),
                           SHM_VARIANT_ID, SHM_HAS_ARENA,
                           max_size, default_ttl, lru_skip, arena_cap_override, file_mode, errbuf);
}

static ShmHandle *SHM_FN(create_sharded)(const char *path_prefix,
                                          uint32_t num_shards,
                                          uint32_t max_entries,
                                          uint32_t max_size, uint32_t default_ttl,
                                          uint32_t lru_skip, uint64_t arena_cap_override,
                                          mode_t file_mode, char *errbuf) {
    return shm_create_sharded(path_prefix, num_shards, max_entries,
                               (uint32_t)sizeof(SHM_NODE_TYPE),
                               SHM_VARIANT_ID, SHM_HAS_ARENA,
                               max_size, default_ttl, lru_skip, arena_cap_override, file_mode, errbuf);
}

static ShmHandle *SHM_FN(create_memfd)(const char *name, uint32_t max_entries,
                                        uint32_t max_size, uint32_t default_ttl,
                                        uint32_t lru_skip, uint64_t arena_cap_override,
                                        char *errbuf) {
    return shm_create_memfd(name, max_entries,
                             (uint32_t)sizeof(SHM_NODE_TYPE),
                             SHM_VARIANT_ID, SHM_HAS_ARENA,
                             max_size, default_ttl, lru_skip, arena_cap_override, errbuf);
}

static ShmHandle *SHM_FN(open_fd)(int fd, char *errbuf) {
    return shm_open_fd_map(fd, SHM_VARIANT_ID,
                            (uint32_t)sizeof(SHM_NODE_TYPE), errbuf);
}

/* ---- Rehash helper (used during resize) -- returns new index ---- */

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
#if !defined(SHM_KEY_IS_INT) || defined(SHM_VAL_IS_STR)
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
#endif
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

/* Standard "remove a live entry": detach from LRU, clear TTL, tombstone.
 * Used by remove/take/cas_take/pop/shift/drain -- anywhere a caller-located
 * entry is being deleted. Distinct from expire_at (bumps stat_expired) and
 * lru_evict_one (picks the victim by clock-walking the LRU). */
static inline void SHM_FN(remove_at)(ShmHandle *h, uint32_t idx) {
    if (h->lru_prev) shm_lru_unlink(h, idx);
    if (h->expires_at) h->expires_at[idx] = 0;
    SHM_FN(tombstone_at)(h, idx);
}

/* ---- LRU eviction ---- */

static void SHM_FN(lru_evict_one)(ShmHandle *h) {
    ShmHeader *hdr = h->hdr;
    /* Second-chance clock: walk from tail, if accessed -> clear and
     * promote (give second chance), else -> evict. */
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
    /* If the victim is already past its TTL, attribute the removal to
     * expiration rather than eviction so stat_evictions reflects true
     * capacity pressure (not TTL-driven removals that happened to hit
     * the LRU tail). */
    int was_expired = SHM_IS_EXPIRED(h, victim, shm_now());
    SHM_FN(remove_at)(h, victim);
    __atomic_add_fetch(was_expired ? &hdr->stat_expired
                                   : &hdr->stat_evictions, 1, __ATOMIC_RELAXED);
}

/* ---- TTL expiration ---- */

static void SHM_FN(expire_at)(ShmHandle *h, uint32_t idx) {
    SHM_FN(remove_at)(h, idx);
    __atomic_add_fetch(&h->hdr->stat_expired, 1, __ATOMIC_RELAXED);
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
        /* Grow even while iterating: a load-driven insert must never silently
         * fail below max_entries.  Both iterators auto-reset on the resulting
         * table_gen bump (built-in each via iter_gen, cursors via c->gen), so
         * an abandoned each or long-lived cursor can no longer wedge the table
         * at capacity.  (Tombstone compaction below and shrink stay deferred.) */
        if (cap < hdr->max_table_cap)  /* cap is pow2; cap*2 can't overflow here */
            SHM_FN(resize)(h, cap * 2);
        else if (tomb > size || tomb > cap / 4)
            SHM_FN(resize)(h, cap);  /* at max capacity: compact tombstones in place */
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
    if (!h || !h->deferred || h->iterating > 0) return;
    h->deferred = 0;
    ShmHeader *hdr = h->hdr;
    shm_rwlock_wrlock(h);
    shm_seqlock_write_begin(&hdr->seq);
    uint32_t size = hdr->size, tomb = hdr->tombstones, cap = hdr->table_cap;
    if ((uint64_t)(size + tomb) * 4 > (uint64_t)cap * 3) {
        if (cap < hdr->max_table_cap)  /* cap is pow2; cap*2 can't overflow here */
            SHM_FN(resize)(h, cap * 2);
        else if (tomb > size || tomb > cap / 4)
            SHM_FN(resize)(h, cap);  /* at max capacity: compact tombstones in place */
    } else if (cap > SHM_INITIAL_CAP && (uint64_t)size * 4 < cap) {
        uint32_t new_cap = cap / 2;
        if (new_cap < SHM_INITIAL_CAP) new_cap = SHM_INITIAL_CAP;
        SHM_FN(resize)(h, new_cap);
    } else if (tomb > size || tomb > cap / 4) {
        SHM_FN(resize)(h, cap);
    }
    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
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
        /* SHM_IS_LIVE -- check tag then key match */
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
    /* Unified seqlock path -- lock-free for ALL maps including LRU/TTL.
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
        uint32_t seq = shm_seqlock_read_begin(h);

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
        /* SIMD fast path: check first 16 states in one shot.
         * Bound by the clamped extent (mask+1), NOT a live re-read of
         * hdr->table_cap: a peer corrupting table_cap past max_table_cap
         * must not let this group load run off the states[] array. */
        if (pos + 16 <= mask + 1) {
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
                    (void)key_utf8;  /* flag is metadata for retrieval, not part of key identity */
                    if (kl != key_len) goto simd_next;
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
#ifndef SHM_KEY_IS_INT
            simd_next:  /* goto target only exists on the string-key compare path */
#endif
                relevant &= relevant - 1;
            }
            if (emask) goto simd_done;  /* hit empty -- key absent */
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
                /* key_utf8 is metadata for retrieval, not part of identity */
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
                    found = 0;  /* expired -- treat as absent */
                }
            }
        }

        if (found) {
#ifdef SHM_VAL_IS_STR
            if (SHM_IS_INLINE(local_vlen_packed)) {
                /* Inline value -- data is in local_voff + local_vlen_packed, no arena access */
                if (local_vl > h->copy_buf_size || !h->copy_buf) {
                    if (!shm_ensure_copy_buf(h, local_vl > 0 ? local_vl : 1)) return 0;
                    continue;
                }
                shm_inline_read(local_voff, local_vlen_packed, h->copy_buf);
            } else {
                /* Arena value -- bounds check before copy */
                if ((uint64_t)local_voff + local_vl > arena_cap) continue;
                if (local_vl > h->copy_buf_size || !h->copy_buf) {
                    if (!shm_ensure_copy_buf(h, local_vl > 0 ? local_vl : 1)) return 0;
                    continue;
                }
                memcpy(h->copy_buf, h->arena + local_voff, local_vl);
            }
#endif
            if (shm_seqlock_read_retry(&hdr->seq, seq)) continue;

            /* validated -- set clock accessed bit and commit results */
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
            if (st != tag) continue;  /* tombstone or tag mismatch */
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            int found = !SHM_IS_EXPIRED(h, idx, now);
            shm_rwlock_rdunlock(h);
            return found;
        }
    }

    shm_rwlock_rdunlock(h);
    return 0;
}

/* ---- Exists (seqlock -- lock-free read path) ---- */

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
        uint32_t seq = shm_seqlock_read_begin(h);

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

/* Lockless remove body -- caller must hold writer lock + seqlock and have
 * already shard-dispatched. Used by remove() and remove_multi. */
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
    uint32_t hash = SHM_HASH_KEY_STR(key_str, key_len);
#endif
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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
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

/* ---- Add (insert only if key absent, returns 1=inserted, 0=already exists or full) ---- */

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
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(h);
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
            /* Live key blocks add; expired entries are reclaimed */
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

    if (insert_pos == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }

    if (hdr->max_size > 0 && hdr->size >= hdr->max_size)
        SHM_FN(lru_evict_one)(h);

    int was_tombstone = (states[insert_pos] == SHM_TOMBSTONE);
#ifdef SHM_KEY_IS_INT
    nodes[insert_pos].key = key;
#else
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].key_off, &nodes[insert_pos].key_len, key_str, key_len, key_utf8)) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
        return 0;
    }
#endif
#ifdef SHM_VAL_IS_STR
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, val_str, val_len, val_utf8)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
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
        uint32_t ttl = (ttl_sec == SHM_TTL_USE_DEFAULT) ? hdr->default_ttl : ttl_sec;
        h->expires_at[insert_pos] = ttl > 0 ? shm_expiry_ts(ttl) : 0;
    }

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

/* ---- Update (overwrite only if key exists, returns 1=updated, 0=not found) ---- */

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
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(h);
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
                shm_rwlock_wrunlock(h);
                return 0;
            }
#ifdef SHM_VAL_IS_STR
            {
                uint32_t old_off = nodes[idx].val_off;
                uint32_t old_lf = nodes[idx].val_len;
                if (!shm_str_store(hdr, h->arena, &nodes[idx].val_off, &nodes[idx].val_len, val_str, val_len, val_utf8)) {
                    shm_seqlock_write_end(&hdr->seq);
                    shm_rwlock_wrunlock(h);
                    return 0;
                }
                shm_str_free(hdr, h->arena, old_off, old_lf);
            }
#else
            nodes[idx].value = value;
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

    shm_rwlock_wrlock(h);
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
                    shm_rwlock_wrunlock(h);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, old_vl);
                *out_str = h->copy_buf;
                *out_len = old_vl;
                *out_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);

                {
                    uint32_t old_off = nodes[idx].val_off;
                    uint32_t old_lf = nodes[idx].val_len;
                    if (!shm_str_store(hdr, h->arena, &nodes[idx].val_off, &nodes[idx].val_len, val_str, val_len, val_utf8)) {
                        shm_seqlock_write_end(&hdr->seq);
                        shm_rwlock_wrunlock(h);
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
            shm_rwlock_wrunlock(h);
            return 1; /* swapped existing */
        }
    }

    /* Key not found -- insert new */
    if (insert_pos == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
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
        shm_rwlock_wrunlock(h);
        return 0;
    }
#endif
#ifdef SHM_VAL_IS_STR
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, val_str, val_len, val_utf8)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
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
    shm_rwlock_wrunlock(h);
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

    shm_rwlock_wrlock(h);
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
                shm_rwlock_wrunlock(h);
                return 0;
            }

            /* copy value out before tombstoning */
#ifdef SHM_VAL_IS_STR
            {
                uint32_t vl = SHM_STR_LEN(nodes[idx].val_len);
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
            *out_value = nodes[idx].value;
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

/* ---- Compare-and-take (atomic remove if value matches expected) ----
 * Returns 1 if matched and removed (old value copied out); 0 if key missing,
 * expired, or value did not match. Integer variants compare by integer
 * equality; string-value variants compare bytes only. */
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
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(h);
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
                shm_rwlock_wrunlock(h);
                return 0;
            }
#ifdef SHM_VAL_IS_STR
            char ibuf[SHM_INLINE_MAX];
            uint32_t cur_len;
            const char *cur_str = shm_str_ptr(nodes[idx].val_off, nodes[idx].val_len,
                                              h->arena, ibuf, &cur_len);
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
            if (nodes[idx].value != expected) {
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            *out_value = nodes[idx].value;
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

    shm_rwlock_wrlock(h);
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
        shm_rwlock_wrunlock(h);
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
#ifndef SHM_KEY_IS_INT
        uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
        /* key is in copy_buf[0..kl), put value after it.
         * Reassign out_key_str in case realloc moved the buffer. */
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
    *out_value = nodes[idx].value;
#endif

    SHM_FN(remove_at)(h, idx);
    SHM_FN(maybe_shrink)(h);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
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

    shm_rwlock_wrlock(h);
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
        shm_rwlock_wrunlock(h);
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
#ifndef SHM_KEY_IS_INT
        uint32_t kl = SHM_STR_LEN(nodes[idx].key_len);
        /* Reassign out_key_str in case realloc moved the buffer. */
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
    *out_value = nodes[idx].value;
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
    uint32_t now = h->expires_at ? shm_now() : 0;
    uint32_t count = 0;
    uint32_t buf_used = *buf_used_p;
    (void)buf; (void)buf_cap;  /* used only by the string key/value copy paths below */

    if (limit == 0) return 0;

    shm_rwlock_wrlock(h);
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
            if ((uint64_t)buf_used + kl > UINT32_MAX) break;  /* drain buffer would exceed 4GB */
            if (!shm_grow_buf(buf, buf_cap, buf_used + kl)) break;
            shm_str_copy(*buf + buf_used, nodes[idx].key_off, nodes[idx].key_len, h->arena, h->hdr->arena_cap, kl);
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
            if ((uint64_t)buf_used + vl > UINT32_MAX) break;  /* drain buffer would exceed 4GB */
            if (!shm_grow_buf(buf, buf_cap, buf_used + vl)) break;
            shm_str_copy(*buf + buf_used, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, vl);
            out[count].val_off = buf_used;
            out[count].val_len = vl;
            out[count].val_utf8 = SHM_UNPACK_UTF8(nodes[idx].val_len);
            buf_used += vl;
        }
#else
        out[count].value = nodes[idx].value;
#endif

        SHM_FN(remove_at)(h, idx);
        count++;
    }

    if (count > 0) SHM_FN(maybe_shrink)(h);

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

    /* fast path: existing key under read lock + atomic add (no LRU/TTL).
     * No seqlock bump is needed here: only the single `value` word changes, and
     * a concurrent get() reads it with one atomic load, so per-location coherence
     * hands it old-or-new (never torn) on every arch including aarch64. The
     * seqlock exists to guard multi-field snapshots against structural writers
     * (resize / key-replace / expire); this path touches neither key nor state. */
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

    /* slow path: find-or-insert under write lock */
    shm_rwlock_wrlock(h);
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
                /* treat as not found -- will insert below */
                if (insert_pos == UINT32_MAX) insert_pos = slot;
                break;
            }

            nodes[slot].value += delta;
            SHM_VAL_INT_TYPE result = nodes[slot].value;
            if (h->lru_prev) shm_lru_promote(h, slot);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[slot] != 0)
                h->expires_at[slot] = shm_expiry_ts(hdr->default_ttl);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            *ok = 1;
            return result;
        }
    }

    if (insert_pos == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
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
        shm_rwlock_wrunlock(h);
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
    shm_rwlock_wrunlock(h);
    *ok = 1;
    return delta;
}

/* ---- Atomic max / min (monotonic raise/lower; insert-if-absent) ---- */
/* want_max != 0: store max(current, desired); else min(current, desired).
 * Returns the resulting stored value; an absent key inserts `desired`. The
 * compare-and-set happens under a single lock acquisition, so there is no
 * read->modify gap for a concurrent incr_by / cas / max / min to slip into. */
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
    uint32_t now = h->expires_at ? shm_now() : 0;

    /* fast path: existing key under read lock + atomic compare-and-set loop
       (no LRU/TTL). The common "already past the bound" case returns read-only,
       writing nothing. No seqlock bump needed (see incr_by): only the single
       `value` word changes, read atomically by get(); key/state are untouched. */
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
                /* on failure __atomic_compare_exchange_n reloads cur, so a
                   concurrent raise/lower is observed and the loop re-checks */
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

    /* slow path: find-or-insert under write lock (handles LRU/TTL like incr_by) */
    shm_rwlock_wrlock(h);
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
            if (SHM_IS_EXPIRED(h, slot, now)) {
                SHM_FN(expire_at)(h, slot);
                /* treat as not found -- will insert below */
                if (insert_pos == UINT32_MAX) insert_pos = slot;
                break;
            }

            SHM_VAL_INT_TYPE cur = nodes[slot].value;
            SHM_VAL_INT_TYPE result =
                want_max ? (desired > cur ? desired : cur)
                         : (desired < cur ? desired : cur);
            nodes[slot].value = result;
            if (h->lru_prev) shm_lru_promote(h, slot);
            if (h->expires_at && hdr->default_ttl > 0 && h->expires_at[slot] != 0)
                h->expires_at[slot] = shm_expiry_ts(hdr->default_ttl);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            *ok = 1;
            return result;
        }
    }

    if (insert_pos == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
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
        shm_rwlock_wrunlock(h);
        *ok = 0;
        return 0;
    }
#endif
    nodes[insert_pos].value = desired;
    h->states[insert_pos] = SHM_MAKE_TAG(hash);
    hdr->size++;
    if (was_tombstone) hdr->tombstones--;

    if (h->lru_prev) shm_lru_push_front(h, insert_pos);
    if (h->expires_at && hdr->default_ttl > 0)
        h->expires_at[insert_pos] = shm_expiry_ts(hdr->default_ttl);

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
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(h);
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
                shm_rwlock_wrunlock(h);
                return 0;
            }
            if (nodes[idx].value == expected) {
                nodes[idx].value = desired;
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
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_wrlock(h);
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
                shm_rwlock_wrunlock(h);
                return 0;
            }
            char ibuf[SHM_INLINE_MAX];
            uint32_t cur_len;
            const char *cur_str = shm_str_ptr(nodes[idx].val_off, nodes[idx].val_len,
                                              h->arena, ibuf, &cur_len);
            if (cur_len != expected_len || memcmp(cur_str, expected_str, cur_len) != 0) {
                shm_seqlock_write_end(&hdr->seq);
                shm_rwlock_wrunlock(h);
                return 0;
            }
            uint32_t old_off = nodes[idx].val_off;
            uint32_t old_lf = nodes[idx].val_len;
            if (!shm_str_store(hdr, h->arena, &nodes[idx].val_off, &nodes[idx].val_len,
                               desired_str, desired_len, desired_utf8)) {
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
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(max_entries)(h->shard_handles[i]);
        return (uint32_t)(total > UINT32_MAX ? UINT32_MAX : total);
    }
    /* cast first: max_table_cap can be 2^31, where *3 would overflow uint32 */
    return (uint32_t)((uint64_t)h->hdr->max_table_cap * 3 / 4);
}

/* ---- Accessors ---- */

static inline uint32_t SHM_FN(max_size)(ShmHandle *h) {
    if (h->shard_handles) {
        uint64_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(max_size)(h->shard_handles[i]);
        return (uint32_t)(total > UINT32_MAX ? UINT32_MAX : total);
    }
    return h->hdr->max_size;
}

static inline uint32_t SHM_FN(ttl)(ShmHandle *h) {
    if (h->shard_handles) return SHM_FN(ttl)(h->shard_handles[0]);
    return h->hdr->default_ttl;
}

/* ---- Get value with TTL remaining (atomic snapshot) ----
 * Returns 1 if key found and live (output args filled); 0 if missing/expired.
 * *out_ttl_remaining encodes the entry's TTL state on a return of 1:
 *   -1 = map has no TTL enabled
 *    0 = entry is permanent
 *   >0 = seconds remaining until expiry
 * Caller may pass NULL out_ttl_remaining if only the value is wanted.
 */
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
    uint32_t now_ts = h->expires_at ? shm_now() : 0;

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
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
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
            *out_value = nodes[idx].value;
#endif
            /* count as an access for LRU second-chance, like get() does */
            if (h->lru_accessed)
                __atomic_store_n(&h->lru_accessed[idx], 1, __ATOMIC_RELAXED);
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
    if (!h->expires_at) return -1;  /* TTL not enabled */

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
            if (st != tag) continue;  /* tombstone or tag mismatch */
#ifdef SHM_KEY_IS_INT
        if (SHM_KEY_EQ(&nodes[idx], key)) {
#else
        if (SHM_KEY_EQ_STR(&nodes[idx], h->arena, key_str, key_len, key_utf8)) {
#endif
            uint32_t exp = h->expires_at[idx];
            if (exp == 0) {
                shm_rwlock_rdunlock(h);
                return 0;  /* permanent entry */
            }
            uint32_t now = shm_now();
            if (now >= exp) {
                shm_rwlock_rdunlock(h);
                return -1;  /* expired */
            }
            int64_t remaining = (int64_t)(exp - now);
            shm_rwlock_rdunlock(h);
            return remaining;
        }
    }

    shm_rwlock_rdunlock(h);
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

    shm_rwlock_wrlock(h);

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
                shm_rwlock_wrunlock(h);
                return 0;
            }
            shm_seqlock_write_begin(&hdr->seq);
            h->expires_at[idx] = 0;  /* permanent */
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    shm_rwlock_wrunlock(h);
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

    shm_rwlock_wrlock(h);

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
                shm_rwlock_wrunlock(h);
                return 0;
            }
            shm_seqlock_write_begin(&hdr->seq);
            if (ttl_sec == 0)
                h->expires_at[idx] = 0;  /* permanent */
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
    if (h->shard_handles) {
        size_t total = 0;
        for (uint32_t i = 0; i < h->num_shards; i++)
            total += SHM_FN(mmap_size)(h->shard_handles[i]);
        return total;
    }
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

    shm_rwlock_wrlock(h);
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
    int done = (limit >= cap || (uint64_t)start + limit >= cap);
    hdr->flush_cursor = done ? 0 : next;

    if (done_out) *done_out = done;

    /* Only shrink/compact when a full cycle is done, otherwise the rehash
     * can move entries to slots the cursor already passed. */
    if (done && flushed > 0)
        SHM_FN(maybe_shrink)(h);

    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
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

    shm_rwlock_wrlock(h);

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

    shm_rwlock_wrlock(h);
    shm_seqlock_write_begin(&hdr->seq);
    int ok = 1;
    if (needed > hdr->table_cap)
        ok = SHM_FN(resize)(h, needed);
    shm_seqlock_write_end(&hdr->seq);
    shm_rwlock_wrunlock(h);
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

    shm_rwlock_wrlock(h);
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
        hdr->arena_large_free = 0;
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
    shm_rwlock_wrunlock(h);

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

    shm_rwlock_wrlock(h);
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
                    shm_rwlock_wrunlock(h);
                    return 0;
                }
                shm_str_copy(h->copy_buf, nodes[idx].val_off, nodes[idx].val_len, h->arena, h->hdr->arena_cap, vl);
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
            shm_rwlock_wrunlock(h);
            return 1;
        }
    }

    /* not found -- insert default value */
    if (insert_pos == UINT32_MAX) {
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
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
    if (!shm_str_store(hdr, h->arena, &nodes[insert_pos].val_off, &nodes[insert_pos].val_len, def_str, def_len, def_utf8)) {
#ifndef SHM_KEY_IS_INT
        shm_str_free(hdr, h->arena, nodes[insert_pos].key_off, nodes[insert_pos].key_len);
#endif
        shm_seqlock_write_end(&hdr->seq);
        shm_rwlock_wrunlock(h);
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
    shm_rwlock_wrunlock(h);
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

    shm_rwlock_rdlock(h);

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
                    shm_rwlock_rdunlock(h);
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
            *out_value = nodes[pos].value;
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

        shm_rwlock_rdlock(h);

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
                        shm_rwlock_rdunlock(h);
                        return 0;
                    }
                    uint32_t total = (uint32_t)total64;
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
                *out_value = nodes[pos].value;
#endif
                shm_rwlock_rdunlock(h);
                return 1;
            }
        }

        shm_rwlock_rdunlock(h);

        /* Current shard exhausted -- flush deferred work and advance */
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
            /* All shards exhausted: clear c->current so cursor_destroy /
             * cursor_reset / cursor_seek don't double-decrement the last
             * shard's `iterating` counter (we already did at line above). */
            c->current = NULL;
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
        /* Stale iter_pos/gen from the previous shard would corrupt a
         * subsequent cursor_next on the new shard (which uses the
         * gen-mismatch check as its only reset trigger, and two fresh
         * shards can coincidentally share table_gen=0). */
        c->iter_pos = 0;
        c->gen = target->hdr->table_gen;
    }

    ShmHandle *h = c->current;
    ShmHeader *hdr = h->hdr;
    SHM_NODE_TYPE *nodes = (SHM_NODE_TYPE *)h->nodes;
    uint8_t *states = h->states;
    uint32_t now = h->expires_at ? shm_now() : 0;

    shm_rwlock_rdlock(h);

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
                shm_rwlock_rdunlock(h);
                return 0;
            }
            c->iter_pos = idx;
            c->gen = hdr->table_gen;
            shm_rwlock_rdunlock(h);
            return 1;
        }
    }

    shm_rwlock_rdunlock(h);
    return 0;
}

/* ---- Undefine template macros ---- */

#undef SHM_PASTE2
#undef SHM_PASTE
#undef SHM_FN
#undef SHM_NODE_TYPE
#undef SHM_PREFIX
#undef SHM_VARIANT_ID
#undef SHM_HAS_ARENA

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
