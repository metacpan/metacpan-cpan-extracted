/*
 * hashmap_generic.h — Macro-template for type-specialized hashmaps.
 *
 * Before including this file, define:
 *   HM_PREFIX      — function name prefix (e.g., hashmap_ii)
 *   HM_NODE_TYPE   — node struct name
 *   HM_MAP_TYPE    — map struct name
 *
 * Key type (choose one):
 *   HM_KEY_IS_INT  — define for integer keys
 *   (leave undefined for string keys: char* + uint32_t len + uint32_t hash)
 *
 * Value type (choose one):
 *   HM_VALUE_IS_STR — define for string values (char* + uint32_t len)
 *   HM_VALUE_IS_SV  — define for opaque pointer values (void*, refcounted externally)
 *   (leave undefined for integer values)
 *
 * Integer width (optional, defaults to int64_t):
 *   HM_INT_TYPE    — integer type (int32_t or int64_t)
 *   HM_INT_MIN     — minimum value (sentinel: empty key)
 *   HM_INT_MAX     — maximum value (for overflow checks)
 *
 * Optional:
 *   HM_HAS_COUNTERS — define to generate incr/decr functions (int values only)
 */

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* ---- Macro helpers ---- */

#define HM_PASTE2(a, b)  a##_##b
#define HM_PASTE(a, b)   HM_PASTE2(a, b)
#define HM_FN(name)      HM_PASTE(HM_PREFIX, name)

/* ---- Integer type defaults ---- */

#ifndef HM_INT_TYPE
#define HM_INT_TYPE  int64_t
#define HM_INT_MIN   INT64_MIN
#define HM_INT_MAX   INT64_MAX
#endif

/* ---- Branch prediction ---- */

#ifndef HM_LIKELY
#if defined(__GNUC__) || defined(__clang__)
#define HM_LIKELY(x)   __builtin_expect(!!(x), 1)
#define HM_UNLIKELY(x) __builtin_expect(!!(x), 0)
#else
#define HM_LIKELY(x)   (x)
#define HM_UNLIKELY(x) (x)
#endif
#endif

/* ---- TTL timestamp helper ---- */

/* Saturates; 0 is the no-expiry sentinel, so an exact 0 becomes 1. */
#ifndef HM_EXPIRY_AT_DEFINED
#define HM_EXPIRY_AT_DEFINED
static inline uint32_t hm_expiry_at(uint32_t ttl) {
    uint32_t now = (uint32_t)time(NULL);
    uint32_t e = now + ttl;
    if (e < now) e = UINT32_MAX;
    return e ? e : 1;
}
#endif

/* If idx has expired, expires it and returns false from the enclosing function. */
#ifndef HM_TTL_CHECK_EXPIRED_DEFINED
#define HM_TTL_CHECK_EXPIRED_DEFINED
#define HM_TTL_CHECK_EXPIRED(map, idx, may_compact) do { \
    if (HM_UNLIKELY((map)->expires_at && (map)->expires_at[idx]) && \
        (uint32_t)time(NULL) > (map)->expires_at[idx]) { \
        HM_FN(expire_at)((map), (idx), (may_compact)); \
        return false; \
    } \
} while (0)
#endif

#ifndef HM_MAYBE_COMPACT_DEFINED
#define HM_MAYBE_COMPACT_DEFINED
#define HM_MAYBE_COMPACT(map) do { \
    if ((map)->tombstones > (map)->capacity / 4 || \
        ((map)->size > 0 && (map)->tombstones > (map)->size && \
         (map)->tombstones > (map)->capacity / 8)) \
        HM_FN(compact)(map); \
} while (0)
#endif

/* Returns fail_ret from the enclosing function on OOM. */
#ifndef HM_ENSURE_CAPACITY_DEFINED
#define HM_ENSURE_CAPACITY_DEFINED
#define HM_ENSURE_CAPACITY(map, fail_ret) do { \
    if (((map)->size + (map)->tombstones) * 4 >= (map)->capacity * 3) { \
        if ((map)->expires_at) HM_FN(reap_expired)(map); \
        if (((map)->size + (map)->tombstones) * 4 >= (map)->capacity * 3) { \
            if ((map)->tombstones * 2 >= (map)->size) { \
                if (!HM_FN(compact)(map)) return fail_ret; \
            } else { \
                if (!HM_FN(resize)(map)) return fail_ret; \
            } \
        } \
    } \
} while (0)
#endif

/* Call before changing map state: returns fail_ret from the enclosing function on OOM. */
#ifndef HM_LAZY_ALLOC_EXPIRES_DEFINED
#define HM_LAZY_ALLOC_EXPIRES_DEFINED
#define HM_LAZY_ALLOC_EXPIRES(map, entry_ttl, fail_ret) do { \
    if (HM_UNLIKELY((entry_ttl) > 0 && !(map)->expires_at)) { \
        (map)->expires_at = (uint32_t*)calloc((map)->capacity, sizeof(uint32_t)); \
        if (!(map)->expires_at) return fail_ret; \
    } \
} while (0)
#endif

/* Assumes expires_at[slot] is already 0, as on a fresh get_or_set slot. */
#ifndef HM_APPLY_ENTRY_TTL_DEFINED
#define HM_APPLY_ENTRY_TTL_DEFINED
#define HM_APPLY_ENTRY_TTL(map, idx, entry_ttl) do { \
    if ((map)->expires_at) { \
        uint32_t _hm_ttl = (entry_ttl) > 0 ? (entry_ttl) : (map)->default_ttl; \
        if (_hm_ttl > 0) (map)->expires_at[idx] = hm_expiry_at(_hm_ttl); \
    } \
} while (0)
#endif

/* ---- Constants ---- */

#ifndef HM_INITIAL_CAPACITY
#define HM_INITIAL_CAPACITY 16
#endif

#ifdef HM_KEY_IS_INT
  #define HM_EMPTY_KEY     HM_INT_MIN
  #define HM_TOMBSTONE_KEY (HM_INT_MIN + 1)
  #define HM_IS_RESERVED_KEY(k) ((k) == HM_EMPTY_KEY || (k) == HM_TOMBSTONE_KEY)
#endif

/* ---- UTF-8 flag packing in uint32_t length ---- */

#ifndef HM_UTF8_MACROS_DEFINED
#define HM_UTF8_MACROS_DEFINED
#define HM_UTF8_FLAG    ((uint32_t)0x80000000U)
#define HM_LEN_MASK     ((uint32_t)0x7FFFFFFFU)
#define HM_PACK_LEN(len, is_utf8) ((uint32_t)(len) | ((is_utf8) ? HM_UTF8_FLAG : 0))
#define HM_UNPACK_LEN(packed)     ((uint32_t)((packed) & HM_LEN_MASK))
#define HM_UNPACK_UTF8(packed)    (((packed) & HM_UTF8_FLAG) != 0)
#endif

/* ---- LRU sentinel ---- */

#ifndef HM_LRU_NONE_DEFINED
#define HM_LRU_NONE_DEFINED
#define HM_LRU_NONE UINT32_MAX
#endif

/* ---- Hash functions (xxHash v0.8.3) ---- */

#ifndef HM_HASH_FUNCTIONS_DEFINED
#define HM_HASH_FUNCTIONS_DEFINED

/* perl's malloc macros need my_perl, which static inline code lacks: use the system allocator. */
#undef malloc
#undef free
#undef calloc
#undef realloc

#define XXH_INLINE_ALL
#include "xxhash.h"

/* Derived once in BOOT from PL_hash_seed. */
static XXH_ALIGN(XXH_SEC_ALIGN) uint8_t hm_hash_secret[XXH3_SECRET_DEFAULT_SIZE];

static inline size_t hm_hash_int64(int64_t key) {
    return (size_t)XXH3_64bits_withSecret(&key, sizeof(key), hm_hash_secret, sizeof(hm_hash_secret));
}

static inline uint32_t hm_hash_string(const char* data, uint32_t len) {
    return (uint32_t)XXH3_64bits_withSecret(data, len, hm_hash_secret, sizeof(hm_hash_secret));
}

#endif /* HM_HASH_FUNCTIONS_DEFINED */

/* ---- Tombstone marker for string keys ---- */

#ifndef HM_KEY_IS_INT
  #ifndef HM_STR_TOMBSTONE_DEFINED
  #define HM_STR_TOMBSTONE_DEFINED
  static char hm_str_tombstone_marker;
  #endif
  #define HM_STR_TOMBSTONE (&hm_str_tombstone_marker)
#endif

/* ---- Node struct ---- */

typedef struct {
#ifdef HM_KEY_IS_INT
    HM_INT_TYPE key;
#else
    char*    key;       /* NULL = empty, HM_STR_TOMBSTONE = deleted */
    uint32_t key_len;   /* high bit = UTF-8 flag */
    uint32_t key_hash;
#endif
#ifdef HM_VALUE_IS_STR
    char*    value;
    uint32_t val_len;   /* high bit = UTF-8 flag */
#elif defined(HM_VALUE_IS_SV)
    void*    value;     /* opaque SV* — refcounted by caller */
#else
    HM_INT_TYPE value;
#endif
} HM_NODE_TYPE;

typedef struct {
    HM_NODE_TYPE* nodes;
    size_t capacity;
    size_t size;
    size_t tombstones;
    size_t mask;
    /* LRU fields (active only when max_size > 0) */
    size_t    max_size;
    uint32_t  lru_head;
    uint32_t  lru_tail;
    uint32_t* lru_prev;
    uint32_t* lru_next;
    uint32_t  lru_skip;       /* original percentage for accessor */
    uint32_t  lru_skip_ctr;   /* gains 100 - lru_skip per access; promotes at 100 */
    /* TTL fields (allocated on first TTL use) */
    uint32_t  default_ttl;
    uint32_t* expires_at;
    size_t    iter_pos;
#ifdef HM_VALUE_IS_SV
    void (*free_value_fn)(void*);      /* deferred release, for single-slot paths */
    void (*free_value_now_fn)(void*);  /* immediate release, for clear/destroy */
    bool copy_values;                  /* store copies instead of the caller's SV */
#endif
} HM_MAP_TYPE;

/* ---- Slot state macros ---- */

#ifdef HM_KEY_IS_INT
  #define HM_SLOT_IS_EMPTY(n)     ((n)->key == HM_EMPTY_KEY)
  #define HM_SLOT_IS_TOMBSTONE(n) ((n)->key == HM_TOMBSTONE_KEY)
  #define HM_SLOT_IS_LIVE(n)      (!HM_SLOT_IS_EMPTY(n) && !HM_SLOT_IS_TOMBSTONE(n))
#else
  #define HM_SLOT_IS_EMPTY(n)     ((n)->key == NULL)
  #define HM_SLOT_IS_TOMBSTONE(n) ((n)->key == HM_STR_TOMBSTONE)
  #define HM_SLOT_IS_LIVE(n)      (!HM_SLOT_IS_EMPTY(n) && !HM_SLOT_IS_TOMBSTONE(n))
#endif

/* ---- Init nodes ---- */

static inline void HM_FN(init_nodes)(HM_NODE_TYPE* nodes, size_t capacity) {
#ifdef HM_KEY_IS_INT
    /* Integer keys use sentinel values — must init per-element */
    size_t i;
    for (i = 0; i < capacity; i++) {
        nodes[i].key = HM_EMPTY_KEY;
#ifdef HM_VALUE_IS_STR
        nodes[i].value = NULL;
        nodes[i].val_len = 0;
#elif defined(HM_VALUE_IS_SV)
        nodes[i].value = NULL;
#else
        nodes[i].value = 0;
#endif
    }
#else
    /* String keys: NULL=empty, all-zero works for pointers and lengths */
    memset(nodes, 0, capacity * sizeof(HM_NODE_TYPE));
#endif
}

/* ---- Free resources for a single node ---- */

static inline void HM_FN(free_node_impl)(HM_MAP_TYPE* map, HM_NODE_TYPE* node, bool now) {
    (void)map;
#ifndef HM_KEY_IS_INT
    if (node->key != NULL && node->key != HM_STR_TOMBSTONE) {
        free(node->key);
        node->key = NULL;
    }
#endif
#ifdef HM_VALUE_IS_STR
    if (node->value != NULL) {
        free(node->value);
        node->value = NULL;
    }
#elif defined(HM_VALUE_IS_SV)
    if (node->value != NULL) {
        void (*rel)(void*) = now ? map->free_value_now_fn : map->free_value_fn;
        if (rel) rel(node->value);
        node->value = NULL;
    }
#endif
    (void)node; (void)now;
}

#define HM_FREE_NODE(map, node)     HM_FN(free_node_impl)((map), (node), false)
#define HM_FREE_NODE_NOW(map, node) HM_FN(free_node_impl)((map), (node), true)

/* ---- LRU helpers ---- */

static inline void HM_FN(lru_unlink)(HM_MAP_TYPE* map, uint32_t idx) {
    uint32_t p = map->lru_prev[idx];
    uint32_t n = map->lru_next[idx];
    if (p != HM_LRU_NONE) map->lru_next[p] = n;
    else                   map->lru_head = n;
    if (n != HM_LRU_NONE) map->lru_prev[n] = p;
    else                   map->lru_tail = p;
    map->lru_prev[idx] = HM_LRU_NONE;
    map->lru_next[idx] = HM_LRU_NONE;
}

static inline void HM_FN(lru_push_front)(HM_MAP_TYPE* map, uint32_t idx) {
    map->lru_prev[idx] = HM_LRU_NONE;
    map->lru_next[idx] = map->lru_head;
    if (map->lru_head != HM_LRU_NONE)
        map->lru_prev[map->lru_head] = idx;
    else
        map->lru_tail = idx;
    map->lru_head = idx;
}

static inline void HM_FN(lru_promote)(HM_MAP_TYPE* map, uint32_t idx) {
    if (map->lru_head == idx) return;
    if (map->lru_skip && idx != map->lru_tail) {
        map->lru_skip_ctr += 100 - map->lru_skip;
        if (map->lru_skip_ctr < 100) return;
        map->lru_skip_ctr -= 100;
    }
    HM_FN(lru_unlink)(map, idx);
    HM_FN(lru_push_front)(map, idx);
}

static void HM_FN(tombstone_at)(HM_MAP_TYPE* map, size_t index) {
    HM_FREE_NODE(map, &map->nodes[index]);
#ifdef HM_KEY_IS_INT
    map->nodes[index].key = HM_TOMBSTONE_KEY;
#else
    map->nodes[index].key = HM_STR_TOMBSTONE;
    map->nodes[index].key_len = 0;
    map->nodes[index].key_hash = 0;
#endif
#ifdef HM_VALUE_IS_STR
    map->nodes[index].val_len = 0;
#endif
    if (map->expires_at) map->expires_at[index] = 0;
    map->size--;
    map->tombstones++;
}

static void HM_FN(lru_evict_one)(HM_MAP_TYPE* map) {
    uint32_t victim = map->lru_tail;
    if (victim == HM_LRU_NONE) return;
    HM_FN(lru_unlink)(map, victim);
    HM_FN(tombstone_at)(map, (size_t)victim);
}

static bool HM_FN(compact)(HM_MAP_TYPE* map);

/* may_compact is false on read paths so that a lookup never resets an each() in progress. */
static void HM_FN(expire_at)(HM_MAP_TYPE* map, size_t index, bool may_compact) {
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    if (may_compact) HM_MAYBE_COMPACT(map);
}

/* ---- Create / Destroy ---- */

static HM_MAP_TYPE* HM_FN(create)(size_t max_size, uint32_t default_ttl, uint32_t lru_skip) {
    HM_MAP_TYPE* map = (HM_MAP_TYPE*)malloc(sizeof(HM_MAP_TYPE));
    if (!map) return NULL;

    map->capacity = HM_INITIAL_CAPACITY;
    map->mask = HM_INITIAL_CAPACITY - 1;
    map->size = 0;
    map->tombstones = 0;
    map->max_size = max_size;
    map->default_ttl = default_ttl;
    map->lru_skip = (lru_skip > 99) ? 99 : lru_skip;
    map->lru_skip_ctr = 0;
    map->lru_head = HM_LRU_NONE;
    map->lru_tail = HM_LRU_NONE;
    map->lru_prev = NULL;
    map->lru_next = NULL;
    map->iter_pos = 0;
#ifdef HM_VALUE_IS_SV
    map->free_value_fn = NULL;
    map->free_value_now_fn = NULL;
    map->copy_values = false;
#endif
    map->expires_at = NULL;

    map->nodes = (HM_NODE_TYPE*)malloc(map->capacity * sizeof(HM_NODE_TYPE));
    if (!map->nodes) { free(map); return NULL; }
    HM_FN(init_nodes)(map->nodes, map->capacity);

    if (max_size > 0) {
        map->lru_prev = (uint32_t*)malloc(map->capacity * sizeof(uint32_t));
        map->lru_next = (uint32_t*)malloc(map->capacity * sizeof(uint32_t));
        if (!map->lru_prev || !map->lru_next) {
            free(map->lru_prev); free(map->lru_next);
            free(map->nodes); free(map);
            return NULL;
        }
        memset(map->lru_prev, 0xFF, map->capacity * sizeof(uint32_t));
        memset(map->lru_next, 0xFF, map->capacity * sizeof(uint32_t));
    }

    if (default_ttl > 0) {
        map->expires_at = (uint32_t*)calloc(map->capacity, sizeof(uint32_t));
        if (!map->expires_at) {
            free(map->lru_prev); free(map->lru_next);
            free(map->nodes); free(map);
            return NULL;
        }
    }

    return map;
}

static void HM_FN(destroy)(HM_MAP_TYPE* map) {
    if (!map) return;
#if !defined(HM_KEY_IS_INT) || defined(HM_VALUE_IS_STR) || defined(HM_VALUE_IS_SV)
    {
        size_t i;
        for (i = 0; i < map->capacity; i++) {
            if (HM_SLOT_IS_LIVE(&map->nodes[i])) {
                HM_FREE_NODE_NOW(map, &map->nodes[i]);
            }
        }
    }
#endif
    free(map->lru_prev);
    free(map->lru_next);
    free(map->expires_at);
    free(map->nodes);
    free(map);
}

/* ---- clear: remove all entries without destroying the map ---- */

static void HM_FN(clear)(HM_MAP_TYPE* map) {
    if (!map) return;
    /* A value's DESTROY may look at the map, so it stays consistent at every step. */
    map->iter_pos = 0;
    if (map->lru_prev) {
        memset(map->lru_prev, 0xFF, map->capacity * sizeof(uint32_t));
        memset(map->lru_next, 0xFF, map->capacity * sizeof(uint32_t));
        map->lru_head = HM_LRU_NONE;
        map->lru_tail = HM_LRU_NONE;
    }
    if (map->expires_at)
        memset(map->expires_at, 0, map->capacity * sizeof(uint32_t));
    {
        size_t i;
        for (i = 0; i < map->capacity; i++) {
            if (HM_SLOT_IS_LIVE(&map->nodes[i])) {
                HM_NODE_TYPE dead = map->nodes[i];
                HM_FN(init_nodes)(&map->nodes[i], 1);
                if (map->size) map->size--;
                HM_FREE_NODE_NOW(map, &dead);
            } else if (HM_SLOT_IS_TOMBSTONE(&map->nodes[i])) {
                HM_FN(init_nodes)(&map->nodes[i], 1);
                if (map->tombstones) map->tombstones--;
            }
        }
    }
    map->size = 0;
    map->tombstones = 0;
}

/* ---- reap_expired / purge ---- */

/* Must not compact: the capacity check that calls it decides between compacting and growing. */
static void HM_FN(reap_expired)(HM_MAP_TYPE* map) {
    if (!map || !map->expires_at) return;
    uint32_t now = (uint32_t)time(NULL);
    size_t i;
    for (i = 0; i < map->capacity; i++) {
        if (HM_SLOT_IS_LIVE(&map->nodes[i]) &&
            map->expires_at[i] && now > map->expires_at[i]) {
            if (HM_UNLIKELY(map->lru_prev))
                HM_FN(lru_unlink)(map, (uint32_t)i);
            HM_FN(tombstone_at)(map, i);
        }
    }
}

static void HM_FN(purge)(HM_MAP_TYPE* map) {
    if (!map || !map->expires_at) return;
    HM_FN(reap_expired)(map);
    if (map->tombstones > 0) HM_FN(compact)(map);
}

/* ---- clone: deep copy the entire map ---- */

static HM_MAP_TYPE* HM_FN(clone)(const HM_MAP_TYPE* map) {
    if (!map) return NULL;

    HM_MAP_TYPE* c = (HM_MAP_TYPE*)malloc(sizeof(HM_MAP_TYPE));
    if (!c) return NULL;
    *c = *map;
    c->iter_pos = 0;
#ifdef HM_VALUE_IS_SV
    c->free_value_fn = NULL;  /* prevent double-dec on OOM cleanup */
    c->free_value_now_fn = NULL;
#endif

    c->nodes = (HM_NODE_TYPE*)malloc(map->capacity * sizeof(HM_NODE_TYPE));
    if (!c->nodes) { free(c); return NULL; }
    /* Null shared pointers so goto-fail destroy() won't free source arrays */
    c->lru_prev = NULL;
    c->lru_next = NULL;
    c->expires_at = NULL;

    /* Start empty so that an OOM part-way leaves a valid map for destroy(). */
    HM_FN(init_nodes)(c->nodes, map->capacity);
    c->size = 0;
    c->tombstones = 0;
    {
        size_t i;
        for (i = 0; i < map->capacity; i++) {
            if (!HM_SLOT_IS_LIVE(&map->nodes[i])) {
                /* Tombstones hold probe chains together, so they must survive the copy. */
                if (HM_SLOT_IS_TOMBSTONE(&map->nodes[i])) {
#ifdef HM_KEY_IS_INT
                    c->nodes[i].key = HM_TOMBSTONE_KEY;
#else
                    c->nodes[i].key = HM_STR_TOMBSTONE;
#endif
                    c->tombstones++;
                }
                continue;
            }
#ifdef HM_KEY_IS_INT
            c->nodes[i].key = map->nodes[i].key;
#else
            {
                uint32_t klen = HM_UNPACK_LEN(map->nodes[i].key_len);
                c->nodes[i].key = (char*)malloc(klen + 1);
                if (!c->nodes[i].key) goto fail;
                memcpy(c->nodes[i].key, map->nodes[i].key, klen + 1);
                c->nodes[i].key_len = map->nodes[i].key_len;
                c->nodes[i].key_hash = map->nodes[i].key_hash;
            }
#endif
#ifdef HM_VALUE_IS_STR
            if (map->nodes[i].value) {
                uint32_t vlen = HM_UNPACK_LEN(map->nodes[i].val_len);
                c->nodes[i].value = (char*)malloc(vlen + 1);
                if (!c->nodes[i].value) goto fail;
                memcpy(c->nodes[i].value, map->nodes[i].value, vlen + 1);
            }
            c->nodes[i].val_len = map->nodes[i].val_len;
#elif defined(HM_VALUE_IS_SV)
            c->nodes[i].value = map->nodes[i].value;
            /* the caller copies SV* values (needs pTHX) */
#else
            c->nodes[i].value = map->nodes[i].value;
#endif
            c->size++;
        }
    }

    if (map->lru_prev) {
        c->lru_prev = (uint32_t*)malloc(map->capacity * sizeof(uint32_t));
        c->lru_next = (uint32_t*)malloc(map->capacity * sizeof(uint32_t));
        if (!c->lru_prev || !c->lru_next) goto fail;
        memcpy(c->lru_prev, map->lru_prev, map->capacity * sizeof(uint32_t));
        memcpy(c->lru_next, map->lru_next, map->capacity * sizeof(uint32_t));
    }

    if (map->expires_at) {
        c->expires_at = (uint32_t*)malloc(map->capacity * sizeof(uint32_t));
        if (!c->expires_at) goto fail;
        memcpy(c->expires_at, map->expires_at, map->capacity * sizeof(uint32_t));
    }

#ifdef HM_VALUE_IS_SV
    c->free_value_fn = map->free_value_fn;  /* restore after successful copy */
    c->free_value_now_fn = map->free_value_now_fn;
#endif
    return c;

fail:
    HM_FN(destroy)(c);
    return NULL;
}

/* ---- Rehash: resize to specific capacity ---- */

static bool HM_FN(rehash_to)(HM_MAP_TYPE* map, size_t new_capacity) {
    if (new_capacity == 0 || new_capacity > SIZE_MAX / sizeof(HM_NODE_TYPE)) return false;
    size_t old_capacity = map->capacity;
    HM_NODE_TYPE* old_nodes = map->nodes;
    size_t new_mask = new_capacity - 1;
    HM_NODE_TYPE* new_nodes = (HM_NODE_TYPE*)malloc(new_capacity * sizeof(HM_NODE_TYPE));
    if (!new_nodes) return false;

    uint32_t* new_lru_prev = NULL;
    uint32_t* new_lru_next = NULL;
    uint32_t* old_to_new = NULL;
    if (map->lru_prev) {
        if (new_capacity > (size_t)(uint32_t)-2) {
            free(new_nodes);
            return false; /* capacity would overflow uint32_t LRU indices */
        }
        new_lru_prev = (uint32_t*)malloc(new_capacity * sizeof(uint32_t));
        new_lru_next = (uint32_t*)malloc(new_capacity * sizeof(uint32_t));
        old_to_new   = (uint32_t*)malloc(old_capacity * sizeof(uint32_t));
        if (!new_lru_prev || !new_lru_next || !old_to_new) {
            free(new_nodes); free(new_lru_prev); free(new_lru_next); free(old_to_new);
            return false;
        }
        memset(new_lru_prev, 0xFF, new_capacity * sizeof(uint32_t));
        memset(new_lru_next, 0xFF, new_capacity * sizeof(uint32_t));
        memset(old_to_new, 0xFF, old_capacity * sizeof(uint32_t));
    }

    uint32_t* new_expires_at = NULL;
    if (map->expires_at) {
        new_expires_at = (uint32_t*)calloc(new_capacity, sizeof(uint32_t));
        if (!new_expires_at) {
            free(new_nodes); free(new_lru_prev); free(new_lru_next); free(old_to_new);
            return false;
        }
    }

    HM_FN(init_nodes)(new_nodes, new_capacity);

    {
        size_t i;
        for (i = 0; i < old_capacity; i++) {
            if (HM_SLOT_IS_LIVE(&old_nodes[i])) {
#ifdef HM_KEY_IS_INT
                size_t index = hm_hash_int64((int64_t)old_nodes[i].key) & new_mask;
                while (new_nodes[index].key != HM_EMPTY_KEY)
                    index = (index + 1) & new_mask;
#else
                size_t index = (size_t)old_nodes[i].key_hash & new_mask;
                while (new_nodes[index].key != NULL)
                    index = (index + 1) & new_mask;
#endif
                new_nodes[index] = old_nodes[i];
                if (old_to_new) old_to_new[i] = (uint32_t)index;
                if (new_expires_at)
                    new_expires_at[index] = map->expires_at[i];
            }
        }
    }

    if (map->lru_prev && map->lru_head != HM_LRU_NONE) {
        uint32_t old_idx = map->lru_head;
        uint32_t prev_new = HM_LRU_NONE;
        uint32_t new_head = HM_LRU_NONE;
        uint32_t new_tail = HM_LRU_NONE;

        while (old_idx != HM_LRU_NONE) {
            uint32_t next_old = map->lru_next[old_idx];
            uint32_t ni = old_to_new[old_idx];
            if (ni != HM_LRU_NONE) {
                new_lru_prev[ni] = prev_new;
                new_lru_next[ni] = HM_LRU_NONE;
                if (prev_new != HM_LRU_NONE) new_lru_next[prev_new] = ni;
                else new_head = ni;
                new_tail = ni;
                prev_new = ni;
            }
            old_idx = next_old;
        }

        free(map->lru_prev); free(map->lru_next);
        map->lru_prev = new_lru_prev;
        map->lru_next = new_lru_next;
        map->lru_head = new_head;
        map->lru_tail = new_tail;
    } else if (map->lru_prev) {
        free(map->lru_prev); free(map->lru_next);
        map->lru_prev = new_lru_prev;
        map->lru_next = new_lru_next;
    }
    free(old_to_new);

    if (map->expires_at) {
        free(map->expires_at);
        map->expires_at = new_expires_at;
    }

    free(old_nodes);
    map->nodes = new_nodes;
    map->capacity = new_capacity;
    map->mask = new_mask;
    map->tombstones = 0;
    map->iter_pos = 0;
    return true;
}

static bool HM_FN(resize)(HM_MAP_TYPE* map) {
    if (map->capacity > SIZE_MAX / 2) return false;
    return HM_FN(rehash_to)(map, map->capacity * 2);
}

static bool HM_FN(compact)(HM_MAP_TYPE* map) {
    return HM_FN(rehash_to)(map, map->capacity);
}

static bool HM_FN(reserve)(HM_MAP_TYPE* map, size_t count) {
    if (count > SIZE_MAX / 4) return false;
    /* Compute capacity for count entries at 75% load factor */
    size_t needed = (count * 4 + 2) / 3;
    if (needed <= map->capacity) return true;
    size_t cap = map->capacity;
    while (cap < needed) {
        if (cap > SIZE_MAX / 2) return false;
        cap <<= 1;
    }
    return HM_FN(rehash_to)(map, cap);
}

/* ---- find_node: find existing key or return empty/capacity (not found) ---- */

#ifdef HM_KEY_IS_INT

static inline size_t HM_FN(find_node)(const HM_MAP_TYPE* map, HM_INT_TYPE key) {
    size_t index = hm_hash_int64((int64_t)key) & map->mask;
    const size_t original_index = index;
    const HM_NODE_TYPE* nodes = map->nodes;

    do {
        HM_INT_TYPE k = nodes[index].key;
        if (k == key) return index;
        if (k == HM_EMPTY_KEY) return index;
        index = (index + 1) & map->mask;
    } while (HM_LIKELY(index != original_index));

    return map->capacity;
}

#else /* string keys */

static inline size_t HM_FN(find_node)(const HM_MAP_TYPE* map,
                                       const char* key, uint32_t key_len, uint32_t key_hash) {
    size_t index = (size_t)key_hash & map->mask;
    const size_t original_index = index;
    const HM_NODE_TYPE* nodes = map->nodes;

    do {
        if (nodes[index].key == NULL) return index;
        if (nodes[index].key != HM_STR_TOMBSTONE &&
            nodes[index].key_hash == key_hash &&
            HM_UNPACK_LEN(nodes[index].key_len) == key_len &&
            memcmp(nodes[index].key, key, key_len) == 0) {
            return index;
        }
        index = (index + 1) & map->mask;
    } while (HM_LIKELY(index != original_index));

    return map->capacity;
}

#endif

/* ---- find_slot_for_insert ---- */

#ifdef HM_KEY_IS_INT

static inline size_t HM_FN(find_slot_for_insert)(HM_MAP_TYPE* map, HM_INT_TYPE key, bool* found) {
    size_t index = hm_hash_int64((int64_t)key) & map->mask;
    const size_t original_index = index;
    HM_NODE_TYPE* nodes = map->nodes;
    size_t first_tombstone = map->capacity;

    do {
        HM_INT_TYPE k = nodes[index].key;
        if (k == key) {
            *found = true;
            return index;
        }
        if (k == HM_EMPTY_KEY) {
            *found = false;
            return (first_tombstone < map->capacity) ? first_tombstone : index;
        }
        if (k == HM_TOMBSTONE_KEY && first_tombstone >= map->capacity) {
            first_tombstone = index;
        }
        index = (index + 1) & map->mask;
    } while (index != original_index);

    *found = false;
    return first_tombstone;
}

#else /* string keys */

static inline size_t HM_FN(find_slot_for_insert)(HM_MAP_TYPE* map,
                                                   const char* key, uint32_t key_len,
                                                   uint32_t key_hash, bool* found) {
    size_t index = (size_t)key_hash & map->mask;
    const size_t original_index = index;
    HM_NODE_TYPE* nodes = map->nodes;
    size_t first_tombstone = map->capacity;

    do {
        if (nodes[index].key == NULL) {
            *found = false;
            return (first_tombstone < map->capacity) ? first_tombstone : index;
        }
        if (nodes[index].key == HM_STR_TOMBSTONE) {
            if (first_tombstone >= map->capacity) first_tombstone = index;
        } else if (nodes[index].key_hash == key_hash &&
                   HM_UNPACK_LEN(nodes[index].key_len) == key_len &&
                   memcmp(nodes[index].key, key, key_len) == 0) {
            *found = true;
            return index;
        }
        index = (index + 1) & map->mask;
    } while (index != original_index);

    *found = false;
    return first_tombstone;
}

#endif

/* ---- put ---- */

#ifdef HM_KEY_IS_INT

static inline bool HM_FN(key_is_reserved)(HM_INT_TYPE key) {
    return HM_IS_RESERVED_KEY(key);
}

static bool HM_FN(put)(HM_MAP_TYPE* map, HM_INT_TYPE key,
#ifdef HM_VALUE_IS_STR
                        const char* value, uint32_t val_len, bool val_utf8,
#elif defined(HM_VALUE_IS_SV)
                        void* value,
#else
                        HM_INT_TYPE value,
#endif
                        uint32_t entry_ttl) {
    if (!map || HM_IS_RESERVED_KEY(key)) return false;

    HM_ENSURE_CAPACITY(map, false);

    bool found;
    size_t index = HM_FN(find_slot_for_insert)(map, key, &found);
    if (index >= map->capacity) return false;

    if (!found && map->max_size > 0 && map->size >= map->max_size) {
        HM_FN(lru_evict_one)(map);
        /* Re-probe after eviction to find optimal insertion slot */
        index = HM_FN(find_slot_for_insert)(map, key, &found);
        if (index >= map->capacity) return false;
    }

    HM_LAZY_ALLOC_EXPIRES(map, entry_ttl, false);

#ifdef HM_VALUE_IS_STR
    char* new_val = NULL;
    uint32_t new_val_len = 0;
    if (value && val_len > 0) {
        new_val = (char*)malloc(val_len + 1);
        if (!new_val) return false;
        memcpy(new_val, value, val_len);
        new_val[val_len] = '\0';
        new_val_len = HM_PACK_LEN(val_len, val_utf8);
    } else if (value) {
        new_val = (char*)malloc(1);
        if (!new_val) return false;
        new_val[0] = '\0';
        new_val_len = HM_PACK_LEN(0, val_utf8);
    }
#endif

    if (found) {
#ifdef HM_VALUE_IS_STR
        if (map->nodes[index].value) free(map->nodes[index].value);
#elif defined(HM_VALUE_IS_SV)
        if (map->nodes[index].value && map->free_value_fn)
            map->free_value_fn(map->nodes[index].value);
#endif
    } else {
        if (HM_SLOT_IS_TOMBSTONE(&map->nodes[index])) {
            map->tombstones--;
        }
        map->size++;
        map->nodes[index].key = key;
    }

#ifdef HM_VALUE_IS_STR
    map->nodes[index].value = new_val;
    map->nodes[index].val_len = new_val_len;
#else
    map->nodes[index].value = value;
#endif

    if (HM_UNLIKELY(map->lru_prev)) {
        if (found) HM_FN(lru_promote)(map, (uint32_t)index);
        else       HM_FN(lru_push_front)(map, (uint32_t)index);
    }
    if (map->expires_at) {
        uint32_t ttl = entry_ttl > 0 ? entry_ttl : map->default_ttl;
        if (ttl > 0)
            map->expires_at[index] = hm_expiry_at(ttl);
        else
            map->expires_at[index] = 0;
    }

    return true;
}

#else /* string keys */

static bool HM_FN(put)(HM_MAP_TYPE* map,
                        const char* key, uint32_t key_len, uint32_t key_hash, bool key_utf8,
#ifdef HM_VALUE_IS_STR
                        const char* value, uint32_t val_len, bool val_utf8,
#elif defined(HM_VALUE_IS_SV)
                        void* value,
#else
                        HM_INT_TYPE value,
#endif
                        uint32_t entry_ttl) {
    if (!map || !key) return false;

    HM_ENSURE_CAPACITY(map, false);

    bool found;
    size_t index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
    if (index >= map->capacity) return false;

    if (!found && map->max_size > 0 && map->size >= map->max_size) {
        HM_FN(lru_evict_one)(map);
        /* Re-probe after eviction to find optimal insertion slot */
        index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
        if (index >= map->capacity) return false;
    }

    HM_LAZY_ALLOC_EXPIRES(map, entry_ttl, false);

#ifdef HM_VALUE_IS_STR
    char* new_val = NULL;
    uint32_t new_val_len = 0;
    if (value && val_len > 0) {
        new_val = (char*)malloc(val_len + 1);
        if (!new_val) return false;
        memcpy(new_val, value, val_len);
        new_val[val_len] = '\0';
        new_val_len = HM_PACK_LEN(val_len, val_utf8);
    } else if (value) {
        new_val = (char*)malloc(1);
        if (!new_val) return false;
        new_val[0] = '\0';
        new_val_len = HM_PACK_LEN(0, val_utf8);
    }
#endif

    if (found) {
#ifdef HM_VALUE_IS_STR
        if (map->nodes[index].value) free(map->nodes[index].value);
#elif defined(HM_VALUE_IS_SV)
        if (map->nodes[index].value && map->free_value_fn)
            map->free_value_fn(map->nodes[index].value);
#endif
        map->nodes[index].key_len = HM_PACK_LEN(key_len, key_utf8);
    } else {
        char* new_key = (char*)malloc(key_len + 1);
        if (!new_key) {
#ifdef HM_VALUE_IS_STR
            free(new_val);
#endif
            return false;
        }
        memcpy(new_key, key, key_len);
        new_key[key_len] = '\0';
        if (HM_SLOT_IS_TOMBSTONE(&map->nodes[index])) {
            map->tombstones--;
        }
        map->size++;
        map->nodes[index].key = new_key;
        map->nodes[index].key_len = HM_PACK_LEN(key_len, key_utf8);
        map->nodes[index].key_hash = key_hash;
    }

#ifdef HM_VALUE_IS_STR
    map->nodes[index].value = new_val;
    map->nodes[index].val_len = new_val_len;
#else
    map->nodes[index].value = value;
#endif

    if (HM_UNLIKELY(map->lru_prev)) {
        if (found) HM_FN(lru_promote)(map, (uint32_t)index);
        else       HM_FN(lru_push_front)(map, (uint32_t)index);
    }
    if (map->expires_at) {
        uint32_t ttl = entry_ttl > 0 ? entry_ttl : map->default_ttl;
        if (ttl > 0)
            map->expires_at[index] = hm_expiry_at(ttl);
        else
            map->expires_at[index] = 0;
    }

    return true;
}

#endif /* HM_KEY_IS_INT */

/* ---- get ---- */

#ifdef HM_KEY_IS_INT

#ifdef HM_VALUE_IS_STR
static bool HM_FN(get)(HM_MAP_TYPE* map, HM_INT_TYPE key,
                        const char** out_value, uint32_t* out_len, bool* out_utf8) {
    if (!map || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key == HM_EMPTY_KEY) return false;

    HM_TTL_CHECK_EXPIRED(map, index, false);

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);

    *out_value = map->nodes[index].value;
    *out_len = HM_UNPACK_LEN(map->nodes[index].val_len);
    *out_utf8 = HM_UNPACK_UTF8(map->nodes[index].val_len);
    return true;
}
#elif defined(HM_VALUE_IS_SV)
static bool HM_FN(get)(HM_MAP_TYPE* map, HM_INT_TYPE key, void** out_value) {
    if (!map || !out_value || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key == HM_EMPTY_KEY) return false;

    HM_TTL_CHECK_EXPIRED(map, index, false);

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);

    *out_value = map->nodes[index].value;
    return true;
}
#else
static bool HM_FN(get)(HM_MAP_TYPE* map, HM_INT_TYPE key, HM_INT_TYPE* out_value) {
    if (!map || !out_value || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key == HM_EMPTY_KEY) return false;

    HM_TTL_CHECK_EXPIRED(map, index, false);

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);

    *out_value = map->nodes[index].value;
    return true;
}
#endif

#else /* string keys */

#ifdef HM_VALUE_IS_STR
static bool HM_FN(get)(HM_MAP_TYPE* map,
                        const char* key, uint32_t key_len, uint32_t key_hash,
                        const char** out_value, uint32_t* out_len, bool* out_utf8) {
    if (!map || !key) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;

    HM_TTL_CHECK_EXPIRED(map, index, false);

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);

    *out_value = map->nodes[index].value;
    *out_len = HM_UNPACK_LEN(map->nodes[index].val_len);
    *out_utf8 = HM_UNPACK_UTF8(map->nodes[index].val_len);
    return true;
}
#elif defined(HM_VALUE_IS_SV)
static bool HM_FN(get)(HM_MAP_TYPE* map,
                        const char* key, uint32_t key_len, uint32_t key_hash,
                        void** out_value) {
    if (!map || !key || !out_value) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;

    HM_TTL_CHECK_EXPIRED(map, index, false);

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);

    *out_value = map->nodes[index].value;
    return true;
}
#else
static bool HM_FN(get)(HM_MAP_TYPE* map,
                        const char* key, uint32_t key_len, uint32_t key_hash,
                        HM_INT_TYPE* out_value) {
    if (!map || !key || !out_value) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;

    HM_TTL_CHECK_EXPIRED(map, index, false);

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);

    *out_value = map->nodes[index].value;
    return true;
}
#endif

#endif /* HM_KEY_IS_INT */

/* ---- exists ---- */

#ifdef HM_KEY_IS_INT

static bool HM_FN(exists)(HM_MAP_TYPE* map, HM_INT_TYPE key) {
    if (!map || HM_IS_RESERVED_KEY(key)) return false;
    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key == HM_EMPTY_KEY) return false;

    HM_TTL_CHECK_EXPIRED(map, index, false);
    return true;
}

#else

static bool HM_FN(exists)(HM_MAP_TYPE* map,
                           const char* key, uint32_t key_len, uint32_t key_hash) {
    if (!map || !key) return false;
    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;

    HM_TTL_CHECK_EXPIRED(map, index, false);
    return true;
}

#endif

/* ---- remove ---- */

#ifdef HM_KEY_IS_INT

static bool HM_FN(remove)(HM_MAP_TYPE* map, HM_INT_TYPE key) {
    if (!map || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key != key) return false;

    HM_TTL_CHECK_EXPIRED(map, index, true);

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    HM_MAYBE_COMPACT(map);
    return true;
}

#else /* string keys */

static bool HM_FN(remove)(HM_MAP_TYPE* map,
                           const char* key, uint32_t key_len, uint32_t key_hash) {
    if (!map || !key) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;

    HM_TTL_CHECK_EXPIRED(map, index, true);

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    HM_MAYBE_COMPACT(map);
    return true;
}

#endif

/* ---- Take (remove and return value) ---- */

#ifdef HM_KEY_IS_INT

#ifdef HM_VALUE_IS_STR
static bool HM_FN(take)(HM_MAP_TYPE* map, HM_INT_TYPE key,
                         const char** out_value, uint32_t* out_len, bool* out_utf8) {
    if (!map || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key != key) return false;

    HM_TTL_CHECK_EXPIRED(map, index, true);

    *out_value = map->nodes[index].value;
    *out_len = HM_UNPACK_LEN(map->nodes[index].val_len);
    *out_utf8 = HM_UNPACK_UTF8(map->nodes[index].val_len);
    map->nodes[index].value = NULL;  /* prevent free_node from freeing */

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    HM_MAYBE_COMPACT(map);
    return true;
}
#elif defined(HM_VALUE_IS_SV)
static bool HM_FN(take)(HM_MAP_TYPE* map, HM_INT_TYPE key, void** out_value) {
    if (!map || !out_value || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key != key) return false;

    HM_TTL_CHECK_EXPIRED(map, index, true);

    *out_value = map->nodes[index].value;
    map->nodes[index].value = NULL;  /* transfer ownership to caller */

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    HM_MAYBE_COMPACT(map);
    return true;
}
#else
static bool HM_FN(take)(HM_MAP_TYPE* map, HM_INT_TYPE key, HM_INT_TYPE* out_value) {
    if (!map || !out_value || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key != key) return false;

    HM_TTL_CHECK_EXPIRED(map, index, true);

    *out_value = map->nodes[index].value;

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    HM_MAYBE_COMPACT(map);
    return true;
}
#endif

#else /* string keys */

#ifdef HM_VALUE_IS_STR
static bool HM_FN(take)(HM_MAP_TYPE* map,
                         const char* key, uint32_t key_len, uint32_t key_hash,
                         const char** out_value, uint32_t* out_len, bool* out_utf8) {
    if (!map || !key) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;

    HM_TTL_CHECK_EXPIRED(map, index, true);

    *out_value = map->nodes[index].value;
    *out_len = HM_UNPACK_LEN(map->nodes[index].val_len);
    *out_utf8 = HM_UNPACK_UTF8(map->nodes[index].val_len);
    map->nodes[index].value = NULL;

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    HM_MAYBE_COMPACT(map);
    return true;
}
#elif defined(HM_VALUE_IS_SV)
static bool HM_FN(take)(HM_MAP_TYPE* map,
                         const char* key, uint32_t key_len, uint32_t key_hash,
                         void** out_value) {
    if (!map || !key || !out_value) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;

    HM_TTL_CHECK_EXPIRED(map, index, true);

    *out_value = map->nodes[index].value;
    map->nodes[index].value = NULL;

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    HM_MAYBE_COMPACT(map);
    return true;
}
#else
static bool HM_FN(take)(HM_MAP_TYPE* map,
                         const char* key, uint32_t key_len, uint32_t key_hash,
                         HM_INT_TYPE* out_value) {
    if (!map || !key || !out_value) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;

    HM_TTL_CHECK_EXPIRED(map, index, true);

    *out_value = map->nodes[index].value;

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    HM_MAYBE_COMPACT(map);
    return true;
}
#endif

#endif /* HM_KEY_IS_INT */

/* ---- persist: remove TTL from a key ---- */

#ifdef HM_KEY_IS_INT
static bool HM_FN(persist)(HM_MAP_TYPE* map, HM_INT_TYPE key) {
    if (!map || HM_IS_RESERVED_KEY(key)) return false;
    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key == HM_EMPTY_KEY) return false;
    HM_TTL_CHECK_EXPIRED(map, index, true);
    if (map->expires_at) map->expires_at[index] = 0;
    return true;
}
#else
static bool HM_FN(persist)(HM_MAP_TYPE* map,
                             const char* key, uint32_t key_len, uint32_t key_hash) {
    if (!map || !key) return false;
    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;
    HM_TTL_CHECK_EXPIRED(map, index, true);
    if (map->expires_at) map->expires_at[index] = 0;
    return true;
}
#endif

/* ---- swap: replace value, return old value ---- */

#ifdef HM_KEY_IS_INT

#ifdef HM_VALUE_IS_STR
static bool HM_FN(swap)(HM_MAP_TYPE* map, HM_INT_TYPE key,
                          const char* new_val, uint32_t new_len, bool new_utf8,
                          const char** out_old, uint32_t* out_old_len, bool* out_old_utf8) {
    if (!map || HM_IS_RESERVED_KEY(key)) return false;
    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key != key) return false;
    HM_TTL_CHECK_EXPIRED(map, index, true);
    *out_old = map->nodes[index].value;
    *out_old_len = HM_UNPACK_LEN(map->nodes[index].val_len);
    *out_old_utf8 = HM_UNPACK_UTF8(map->nodes[index].val_len);
    if (new_val && new_len > 0) {
        char* buf = (char*)malloc(new_len + 1);
        if (!buf) return false;
        memcpy(buf, new_val, new_len);
        buf[new_len] = '\0';
        map->nodes[index].value = buf;
    } else if (new_val) {
        char* buf = (char*)malloc(1);
        if (!buf) return false;
        buf[0] = '\0';
        map->nodes[index].value = buf;
    } else {
        map->nodes[index].value = NULL;
    }
    map->nodes[index].val_len = HM_PACK_LEN(new_len, new_utf8);
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
    return true;
}
#elif defined(HM_VALUE_IS_SV)
static bool HM_FN(swap)(HM_MAP_TYPE* map, HM_INT_TYPE key,
                          void* new_val, void** out_old) {
    if (!map || !out_old || HM_IS_RESERVED_KEY(key)) return false;
    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key != key) return false;
    HM_TTL_CHECK_EXPIRED(map, index, true);
    *out_old = map->nodes[index].value;
    map->nodes[index].value = new_val;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
    return true;
}
#else
static bool HM_FN(swap)(HM_MAP_TYPE* map, HM_INT_TYPE key,
                          HM_INT_TYPE new_val, HM_INT_TYPE* out_old) {
    if (!map || !out_old || HM_IS_RESERVED_KEY(key)) return false;
    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key != key) return false;
    HM_TTL_CHECK_EXPIRED(map, index, true);
    *out_old = map->nodes[index].value;
    map->nodes[index].value = new_val;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
    return true;
}
#endif

#else /* string keys */

#ifdef HM_VALUE_IS_STR
static bool HM_FN(swap)(HM_MAP_TYPE* map,
                          const char* key, uint32_t key_len, uint32_t key_hash,
                          const char* new_val, uint32_t new_len, bool new_utf8,
                          const char** out_old, uint32_t* out_old_len, bool* out_old_utf8) {
    if (!map || !key) return false;
    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;
    HM_TTL_CHECK_EXPIRED(map, index, true);
    *out_old = map->nodes[index].value;
    *out_old_len = HM_UNPACK_LEN(map->nodes[index].val_len);
    *out_old_utf8 = HM_UNPACK_UTF8(map->nodes[index].val_len);
    if (new_val && new_len > 0) {
        char* buf = (char*)malloc(new_len + 1);
        if (!buf) return false;
        memcpy(buf, new_val, new_len);
        buf[new_len] = '\0';
        map->nodes[index].value = buf;
    } else if (new_val) {
        char* buf = (char*)malloc(1);
        if (!buf) return false;
        buf[0] = '\0';
        map->nodes[index].value = buf;
    } else {
        map->nodes[index].value = NULL;
    }
    map->nodes[index].val_len = HM_PACK_LEN(new_len, new_utf8);
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
    return true;
}
#elif defined(HM_VALUE_IS_SV)
static bool HM_FN(swap)(HM_MAP_TYPE* map,
                          const char* key, uint32_t key_len, uint32_t key_hash,
                          void* new_val, void** out_old) {
    if (!map || !key || !out_old) return false;
    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;
    HM_TTL_CHECK_EXPIRED(map, index, true);
    *out_old = map->nodes[index].value;
    map->nodes[index].value = new_val;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
    return true;
}
#else
static bool HM_FN(swap)(HM_MAP_TYPE* map,
                          const char* key, uint32_t key_len, uint32_t key_hash,
                          HM_INT_TYPE new_val, HM_INT_TYPE* out_old) {
    if (!map || !key || !out_old) return false;
    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;
    HM_TTL_CHECK_EXPIRED(map, index, true);
    *out_old = map->nodes[index].value;
    map->nodes[index].value = new_val;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
    return true;
}
#endif

#endif /* HM_KEY_IS_INT */

/* ---- cas: compare-and-swap (int values only) ---- */

#if !defined(HM_VALUE_IS_STR) && !defined(HM_VALUE_IS_SV)

#ifdef HM_KEY_IS_INT
static bool HM_FN(cas)(HM_MAP_TYPE* map, HM_INT_TYPE key,
                         HM_INT_TYPE expected, HM_INT_TYPE new_val) {
    if (!map || HM_IS_RESERVED_KEY(key)) return false;
    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key != key) return false;
    HM_TTL_CHECK_EXPIRED(map, index, true);
    if (map->nodes[index].value != expected) return false;
    map->nodes[index].value = new_val;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
    return true;
}
#else
static bool HM_FN(cas)(HM_MAP_TYPE* map,
                         const char* key, uint32_t key_len, uint32_t key_hash,
                         HM_INT_TYPE expected, HM_INT_TYPE new_val) {
    if (!map || !key) return false;
    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;
    HM_TTL_CHECK_EXPIRED(map, index, true);
    if (map->nodes[index].value != expected) return false;
    map->nodes[index].value = new_val;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
    return true;
}
#endif

#endif /* int values only */

/* ---- Counter operations (int values only) ---- */

#ifdef HM_HAS_COUNTERS

#ifdef HM_KEY_IS_INT

static inline size_t HM_FN(find_or_allocate)(HM_MAP_TYPE* map, HM_INT_TYPE key) {
    size_t index = hm_hash_int64((int64_t)key) & map->mask;
    const size_t original_index = index;
    HM_NODE_TYPE* nodes = map->nodes;
    size_t first_tombstone = map->capacity;

    do {
        HM_INT_TYPE k = nodes[index].key;
        if (k == key) return index;
        if (k == HM_EMPTY_KEY) {
            size_t target = (first_tombstone < map->capacity) ? first_tombstone : index;
            if (HM_SLOT_IS_TOMBSTONE(&nodes[target])) map->tombstones--;
            nodes[target].key = key;
            nodes[target].value = 0;
            map->size++;
            return target;
        }
        if (k == HM_TOMBSTONE_KEY && first_tombstone >= map->capacity) {
            first_tombstone = index;
        }
        index = (index + 1) & map->mask;
    } while (index != original_index);

    if (first_tombstone < map->capacity) {
        map->tombstones--;
        nodes[first_tombstone].key = key;
        nodes[first_tombstone].value = 0;
        map->size++;
        return first_tombstone;
    }
    return map->capacity;
}

static bool HM_FN(increment)(HM_MAP_TYPE* map, HM_INT_TYPE key, HM_INT_TYPE* out_value) {
    if (!map || !out_value || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index < map->capacity && map->nodes[index].key == key) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            goto new_key;
        }
        if (map->nodes[index].value == HM_INT_MAX) return false;
        *out_value = ++map->nodes[index].value;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    HM_ENSURE_CAPACITY(map, false);

    index = HM_FN(find_or_allocate)(map, key);
    if (index >= map->capacity) return false;
    *out_value = ++map->nodes[index].value;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
    return true;
}

static bool HM_FN(increment_by)(HM_MAP_TYPE* map, HM_INT_TYPE key, HM_INT_TYPE delta, HM_INT_TYPE* out_value) {
    if (!map || !out_value || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index < map->capacity && map->nodes[index].key == key) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            goto new_key;
        }
        HM_INT_TYPE val = map->nodes[index].value;
        if (delta > 0 && val > HM_INT_MAX - delta) return false;
        if (delta < 0) {
            if (delta == HM_INT_MIN) { if (val < 0) return false; }
            else { if (val < HM_INT_MIN - delta) return false; }
        }
        map->nodes[index].value += delta;
        *out_value = map->nodes[index].value;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    HM_ENSURE_CAPACITY(map, false);

    index = HM_FN(find_or_allocate)(map, key);
    if (index >= map->capacity) return false;
    map->nodes[index].value = delta;
    *out_value = delta;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
    return true;
}

static bool HM_FN(decrement)(HM_MAP_TYPE* map, HM_INT_TYPE key, HM_INT_TYPE* out_value) {
    if (!map || !out_value || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index < map->capacity && map->nodes[index].key == key) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            goto new_key;
        }
        if (map->nodes[index].value == HM_INT_MIN) return false;
        *out_value = --map->nodes[index].value;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    HM_ENSURE_CAPACITY(map, false);

    index = HM_FN(find_or_allocate)(map, key);
    if (index >= map->capacity) return false;
    *out_value = --map->nodes[index].value;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
    return true;
}

#else /* string keys + counters */

static inline size_t HM_FN(find_or_allocate)(HM_MAP_TYPE* map,
                                              const char* key, uint32_t key_len,
                                              uint32_t key_hash, bool key_utf8) {
    size_t index = (size_t)key_hash & map->mask;
    const size_t original_index = index;
    HM_NODE_TYPE* nodes = map->nodes;
    size_t first_tombstone = map->capacity;

    do {
        if (nodes[index].key == NULL) {
            size_t target = (first_tombstone < map->capacity) ? first_tombstone : index;
            char* new_key = (char*)malloc(key_len + 1);
            if (!new_key) return map->capacity;
            memcpy(new_key, key, key_len);
            new_key[key_len] = '\0';
            if (HM_SLOT_IS_TOMBSTONE(&nodes[target])) map->tombstones--;
            nodes[target].key = new_key;
            nodes[target].key_len = HM_PACK_LEN(key_len, key_utf8);
            nodes[target].key_hash = key_hash;
            nodes[target].value = 0;
            map->size++;
            return target;
        }
        if (nodes[index].key == HM_STR_TOMBSTONE) {
            if (first_tombstone >= map->capacity) first_tombstone = index;
        } else if (nodes[index].key_hash == key_hash &&
                   HM_UNPACK_LEN(nodes[index].key_len) == key_len &&
                   memcmp(nodes[index].key, key, key_len) == 0) {
            return index;
        }
        index = (index + 1) & map->mask;
    } while (index != original_index);

    if (first_tombstone < map->capacity) {
        char* new_key = (char*)malloc(key_len + 1);
        if (!new_key) return map->capacity;
        memcpy(new_key, key, key_len);
        new_key[key_len] = '\0';
        map->tombstones--;
        nodes[first_tombstone].key = new_key;
        nodes[first_tombstone].key_len = HM_PACK_LEN(key_len, key_utf8);
        nodes[first_tombstone].key_hash = key_hash;
        nodes[first_tombstone].value = 0;
        map->size++;
        return first_tombstone;
    }
    return map->capacity;
}

static bool HM_FN(increment)(HM_MAP_TYPE* map,
                              const char* key, uint32_t key_len, uint32_t key_hash, bool key_utf8,
                              HM_INT_TYPE* out_value) {
    if (!map || !key || !out_value) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index < map->capacity && HM_SLOT_IS_LIVE(&map->nodes[index])) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            goto new_key;
        }
        if (map->nodes[index].value == HM_INT_MAX) return false;
        *out_value = ++map->nodes[index].value;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    HM_ENSURE_CAPACITY(map, false);

    index = HM_FN(find_or_allocate)(map, key, key_len, key_hash, key_utf8);
    if (index >= map->capacity) return false;
    *out_value = ++map->nodes[index].value;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
    return true;
}

static bool HM_FN(increment_by)(HM_MAP_TYPE* map,
                                 const char* key, uint32_t key_len, uint32_t key_hash, bool key_utf8,
                                 HM_INT_TYPE delta, HM_INT_TYPE* out_value) {
    if (!map || !key || !out_value) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index < map->capacity && HM_SLOT_IS_LIVE(&map->nodes[index])) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            goto new_key;
        }
        HM_INT_TYPE val = map->nodes[index].value;
        if (delta > 0 && val > HM_INT_MAX - delta) return false;
        if (delta < 0) {
            if (delta == HM_INT_MIN) { if (val < 0) return false; }
            else { if (val < HM_INT_MIN - delta) return false; }
        }
        map->nodes[index].value += delta;
        *out_value = map->nodes[index].value;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    HM_ENSURE_CAPACITY(map, false);

    index = HM_FN(find_or_allocate)(map, key, key_len, key_hash, key_utf8);
    if (index >= map->capacity) return false;
    map->nodes[index].value = delta;
    *out_value = delta;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
    return true;
}

static bool HM_FN(decrement)(HM_MAP_TYPE* map,
                              const char* key, uint32_t key_len, uint32_t key_hash, bool key_utf8,
                              HM_INT_TYPE* out_value) {
    if (!map || !key || !out_value) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index < map->capacity && HM_SLOT_IS_LIVE(&map->nodes[index])) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            goto new_key;
        }
        if (map->nodes[index].value == HM_INT_MIN) return false;
        *out_value = --map->nodes[index].value;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    HM_ENSURE_CAPACITY(map, false);

    index = HM_FN(find_or_allocate)(map, key, key_len, key_hash, key_utf8);
    if (index >= map->capacity) return false;
    *out_value = --map->nodes[index].value;
    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (HM_UNLIKELY(map->expires_at && map->default_ttl > 0)) map->expires_at[index] = hm_expiry_at(map->default_ttl);
    return true;
}

#endif /* HM_KEY_IS_INT for counters */

#endif /* HM_HAS_COUNTERS */

/* ---- get_or_set: single-probe get with insert on miss ---- */

#ifdef HM_KEY_IS_INT

#ifdef HM_VALUE_IS_STR
/* get_or_set for int-key, string-value: returns index, sets *was_found */
static size_t HM_FN(get_or_set)(HM_MAP_TYPE* map, HM_INT_TYPE key,
                                  const char* def_val, uint32_t def_len, bool def_utf8,
                                  uint32_t entry_ttl, bool* was_found) {
    *was_found = false;
    if (!map || HM_IS_RESERVED_KEY(key)) return map ? map->capacity : 0;

    HM_ENSURE_CAPACITY(map, map->capacity);

    bool found;
    size_t index = HM_FN(find_slot_for_insert)(map, key, &found);
    if (index >= map->capacity) return map->capacity;

    if (found) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            found = false;
            /* Re-probe after expiry */
            index = HM_FN(find_slot_for_insert)(map, key, &found);
            if (index >= map->capacity) return map->capacity;
        }
    }

    if (found) {
        *was_found = true;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        return index;
    }

    if (map->max_size > 0 && map->size >= map->max_size) {
        HM_FN(lru_evict_one)(map);
        index = HM_FN(find_slot_for_insert)(map, key, &found);
        if (index >= map->capacity) return map->capacity;
    }

    HM_LAZY_ALLOC_EXPIRES(map, entry_ttl, map->capacity);

    char* new_val = NULL;
    uint32_t new_val_len = 0;
    if (def_val && def_len > 0) {
        new_val = (char*)malloc(def_len + 1);
        if (!new_val) return map->capacity;
        memcpy(new_val, def_val, def_len);
        new_val[def_len] = '\0';
        new_val_len = HM_PACK_LEN(def_len, def_utf8);
    } else if (def_val) {
        new_val = (char*)malloc(1);
        if (!new_val) return map->capacity;
        new_val[0] = '\0';
        new_val_len = HM_PACK_LEN(0, def_utf8);
    }

    if (HM_SLOT_IS_TOMBSTONE(&map->nodes[index])) map->tombstones--;
    map->size++;
    map->nodes[index].key = key;
    map->nodes[index].value = new_val;
    map->nodes[index].val_len = new_val_len;

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    HM_APPLY_ENTRY_TTL(map, index, entry_ttl);

    return index;
}
#elif defined(HM_VALUE_IS_SV)
static size_t HM_FN(get_or_set)(HM_MAP_TYPE* map, HM_INT_TYPE key,
                                  void* def_val, uint32_t entry_ttl, bool* was_found) {
    *was_found = false;
    if (!map || HM_IS_RESERVED_KEY(key)) return map ? map->capacity : 0;

    HM_ENSURE_CAPACITY(map, map->capacity);

    bool found;
    size_t index = HM_FN(find_slot_for_insert)(map, key, &found);
    if (index >= map->capacity) return map->capacity;

    if (found) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            found = false;
            index = HM_FN(find_slot_for_insert)(map, key, &found);
            if (index >= map->capacity) return map->capacity;
        }
    }

    if (found) {
        *was_found = true;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        return index;
    }

    if (map->max_size > 0 && map->size >= map->max_size) {
        HM_FN(lru_evict_one)(map);
        index = HM_FN(find_slot_for_insert)(map, key, &found);
        if (index >= map->capacity) return map->capacity;
    }

    HM_LAZY_ALLOC_EXPIRES(map, entry_ttl, map->capacity);

    if (HM_SLOT_IS_TOMBSTONE(&map->nodes[index])) map->tombstones--;
    map->size++;
    map->nodes[index].key = key;
    map->nodes[index].value = def_val;

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    HM_APPLY_ENTRY_TTL(map, index, entry_ttl);

    return index;
}
#else
static size_t HM_FN(get_or_set)(HM_MAP_TYPE* map, HM_INT_TYPE key,
                                  HM_INT_TYPE def_val, uint32_t entry_ttl, bool* was_found) {
    *was_found = false;
    if (!map || HM_IS_RESERVED_KEY(key)) return map ? map->capacity : 0;

    HM_ENSURE_CAPACITY(map, map->capacity);

    bool found;
    size_t index = HM_FN(find_slot_for_insert)(map, key, &found);
    if (index >= map->capacity) return map->capacity;

    if (found) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            found = false;
            index = HM_FN(find_slot_for_insert)(map, key, &found);
            if (index >= map->capacity) return map->capacity;
        }
    }

    if (found) {
        *was_found = true;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        return index;
    }

    if (map->max_size > 0 && map->size >= map->max_size) {
        HM_FN(lru_evict_one)(map);
        index = HM_FN(find_slot_for_insert)(map, key, &found);
        if (index >= map->capacity) return map->capacity;
    }

    HM_LAZY_ALLOC_EXPIRES(map, entry_ttl, map->capacity);

    if (HM_SLOT_IS_TOMBSTONE(&map->nodes[index])) map->tombstones--;
    map->size++;
    map->nodes[index].key = key;
    map->nodes[index].value = def_val;

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    HM_APPLY_ENTRY_TTL(map, index, entry_ttl);

    return index;
}
#endif

#else /* string keys */

#ifdef HM_VALUE_IS_STR
static size_t HM_FN(get_or_set)(HM_MAP_TYPE* map,
                                  const char* key, uint32_t key_len, uint32_t key_hash, bool key_utf8,
                                  const char* def_val, uint32_t def_len, bool def_utf8,
                                  uint32_t entry_ttl, bool* was_found) {
    *was_found = false;
    if (!map || !key) return map ? map->capacity : 0;

    HM_ENSURE_CAPACITY(map, map->capacity);

    bool found;
    size_t index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
    if (index >= map->capacity) return map->capacity;

    if (found) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            found = false;
            index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
            if (index >= map->capacity) return map->capacity;
        }
    }

    if (found) {
        *was_found = true;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        return index;
    }

    if (map->max_size > 0 && map->size >= map->max_size) {
        HM_FN(lru_evict_one)(map);
        index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
        if (index >= map->capacity) return map->capacity;
    }

    HM_LAZY_ALLOC_EXPIRES(map, entry_ttl, map->capacity);

    char* new_key = (char*)malloc(key_len + 1);
    if (!new_key) return map->capacity;
    memcpy(new_key, key, key_len);
    new_key[key_len] = '\0';

    char* new_val = NULL;
    uint32_t new_val_len = 0;
    if (def_val && def_len > 0) {
        new_val = (char*)malloc(def_len + 1);
        if (!new_val) { free(new_key); return map->capacity; }
        memcpy(new_val, def_val, def_len);
        new_val[def_len] = '\0';
        new_val_len = HM_PACK_LEN(def_len, def_utf8);
    } else if (def_val) {
        new_val = (char*)malloc(1);
        if (!new_val) { free(new_key); return map->capacity; }
        new_val[0] = '\0';
        new_val_len = HM_PACK_LEN(0, def_utf8);
    }

    if (HM_SLOT_IS_TOMBSTONE(&map->nodes[index])) map->tombstones--;
    map->size++;
    map->nodes[index].key = new_key;
    map->nodes[index].key_len = HM_PACK_LEN(key_len, key_utf8);
    map->nodes[index].key_hash = key_hash;
    map->nodes[index].value = new_val;
    map->nodes[index].val_len = new_val_len;

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    HM_APPLY_ENTRY_TTL(map, index, entry_ttl);

    return index;
}
#elif defined(HM_VALUE_IS_SV)
static size_t HM_FN(get_or_set)(HM_MAP_TYPE* map,
                                  const char* key, uint32_t key_len, uint32_t key_hash, bool key_utf8,
                                  void* def_val, uint32_t entry_ttl, bool* was_found) {
    *was_found = false;
    if (!map || !key) return map ? map->capacity : 0;

    HM_ENSURE_CAPACITY(map, map->capacity);

    bool found;
    size_t index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
    if (index >= map->capacity) return map->capacity;

    if (found) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            found = false;
            index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
            if (index >= map->capacity) return map->capacity;
        }
    }

    if (found) {
        *was_found = true;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        return index;
    }

    if (map->max_size > 0 && map->size >= map->max_size) {
        HM_FN(lru_evict_one)(map);
        index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
        if (index >= map->capacity) return map->capacity;
    }

    HM_LAZY_ALLOC_EXPIRES(map, entry_ttl, map->capacity);

    char* new_key = (char*)malloc(key_len + 1);
    if (!new_key) return map->capacity;
    memcpy(new_key, key, key_len);
    new_key[key_len] = '\0';

    if (HM_SLOT_IS_TOMBSTONE(&map->nodes[index])) map->tombstones--;
    map->size++;
    map->nodes[index].key = new_key;
    map->nodes[index].key_len = HM_PACK_LEN(key_len, key_utf8);
    map->nodes[index].key_hash = key_hash;
    map->nodes[index].value = def_val;

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    HM_APPLY_ENTRY_TTL(map, index, entry_ttl);

    return index;
}
#else
static size_t HM_FN(get_or_set)(HM_MAP_TYPE* map,
                                  const char* key, uint32_t key_len, uint32_t key_hash, bool key_utf8,
                                  HM_INT_TYPE def_val, uint32_t entry_ttl, bool* was_found) {
    *was_found = false;
    if (!map || !key) return map ? map->capacity : 0;

    HM_ENSURE_CAPACITY(map, map->capacity);

    bool found;
    size_t index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
    if (index >= map->capacity) return map->capacity;

    if (found) {
        if (HM_UNLIKELY(map->expires_at && map->expires_at[index]) &&
            (uint32_t)time(NULL) > map->expires_at[index]) {
            HM_FN(expire_at)(map, index, true);
            found = false;
            index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
            if (index >= map->capacity) return map->capacity;
        }
    }

    if (found) {
        *was_found = true;
        if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_promote)(map, (uint32_t)index);
        return index;
    }

    if (map->max_size > 0 && map->size >= map->max_size) {
        HM_FN(lru_evict_one)(map);
        index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
        if (index >= map->capacity) return map->capacity;
    }

    HM_LAZY_ALLOC_EXPIRES(map, entry_ttl, map->capacity);

    char* new_key = (char*)malloc(key_len + 1);
    if (!new_key) return map->capacity;
    memcpy(new_key, key, key_len);
    new_key[key_len] = '\0';

    if (HM_SLOT_IS_TOMBSTONE(&map->nodes[index])) map->tombstones--;
    map->size++;
    map->nodes[index].key = new_key;
    map->nodes[index].key_len = HM_PACK_LEN(key_len, key_utf8);
    map->nodes[index].key_hash = key_hash;
    map->nodes[index].value = def_val;

    if (HM_UNLIKELY(map->lru_prev)) HM_FN(lru_push_front)(map, (uint32_t)index);
    HM_APPLY_ENTRY_TTL(map, index, entry_ttl);

    return index;
}
#endif

#endif /* HM_KEY_IS_INT for get_or_set */

/* ---- Cleanup macros for next inclusion ---- */

#undef HM_SLOT_IS_EMPTY
#undef HM_SLOT_IS_TOMBSTONE
#undef HM_SLOT_IS_LIVE
#ifdef HM_KEY_IS_INT
  #undef HM_EMPTY_KEY
  #undef HM_TOMBSTONE_KEY
  #undef HM_IS_RESERVED_KEY
#endif

#undef HM_PREFIX
#undef HM_NODE_TYPE
#undef HM_MAP_TYPE
#undef HM_FN
#undef HM_PASTE
#undef HM_PASTE2

#undef HM_KEY_IS_INT
#undef HM_VALUE_IS_STR
#undef HM_VALUE_IS_SV
#undef HM_HAS_COUNTERS

#undef HM_INT_TYPE
#undef HM_INT_MIN
#undef HM_INT_MAX
