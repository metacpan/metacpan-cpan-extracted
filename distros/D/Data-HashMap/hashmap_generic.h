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

/* ---- Hash functions ---- */

#ifndef HM_HASH_FUNCTIONS_DEFINED
#define HM_HASH_FUNCTIONS_DEFINED

/* xxHash64-like mix for integer keys */
static inline size_t hm_hash_int64(int64_t key) {
    const uint64_t k1 = 0x9E3779B185EBCA87ULL;
    const uint64_t k2 = 0xC2B2AE3D27D4EB4FULL;
    uint64_t x = (uint64_t)key;
    x ^= x >> 27;
    x *= k1;
    x ^= x >> 31;
    x *= k2;
    x ^= x >> 27;
    return (size_t)x;
}

/* xxHash32-inspired string hash */
static inline uint32_t hm_hash_string(const char* data, uint32_t len) {
    const uint32_t prime1 = 0x9E3779B1U;
    const uint32_t prime2 = 0x85EBCA77U;
    const uint32_t prime3 = 0xC2B2AE3DU;
    const uint32_t prime4 = 0x27D4EB2FU;
    const uint32_t prime5 = 0x165667B1U;

    uint32_t h;
    const uint8_t* p = (const uint8_t*)data;
    const uint8_t* end = p + len;

    if (len >= 16) {
        uint32_t v1 = prime1 + prime2;
        uint32_t v2 = prime2;
        uint32_t v3 = 0;
        uint32_t v4 = 0 - prime1;
        do {
            uint32_t k;
            memcpy(&k, p, 4); v1 += k * prime2; v1 = (v1 << 13) | (v1 >> 19); v1 *= prime1; p += 4;
            memcpy(&k, p, 4); v2 += k * prime2; v2 = (v2 << 13) | (v2 >> 19); v2 *= prime1; p += 4;
            memcpy(&k, p, 4); v3 += k * prime2; v3 = (v3 << 13) | (v3 >> 19); v3 *= prime1; p += 4;
            memcpy(&k, p, 4); v4 += k * prime2; v4 = (v4 << 13) | (v4 >> 19); v4 *= prime1; p += 4;
        } while (p <= end - 16);
        h = ((v1 << 1) | (v1 >> 31)) + ((v2 << 7) | (v2 >> 25)) +
            ((v3 << 12) | (v3 >> 20)) + ((v4 << 18) | (v4 >> 14));
    } else {
        h = prime5;
    }

    h += (uint32_t)len;

    while (p + 4 <= end) {
        uint32_t k;
        memcpy(&k, p, 4);
        h += k * prime3;
        h = ((h << 17) | (h >> 15)) * prime4;
        p += 4;
    }
    while (p < end) {
        h += (*p) * prime5;
        h = ((h << 11) | (h >> 21)) * prime1;
        p++;
    }

    h ^= h >> 15;
    h *= prime2;
    h ^= h >> 13;
    h *= prime3;
    h ^= h >> 16;

    return h;
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
    /* TTL fields (active only when default_ttl > 0) */
    uint32_t  default_ttl;
    uint32_t* expires_at;
    /* Iterator state for each() */
    size_t    iter_pos;
#ifdef HM_VALUE_IS_SV
    void (*free_value_fn)(void*);  /* SvREFCNT_dec callback */
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
    size_t i;
    for (i = 0; i < capacity; i++) {
#ifdef HM_KEY_IS_INT
        nodes[i].key = HM_EMPTY_KEY;
#else
        nodes[i].key = NULL;
        nodes[i].key_len = 0;
        nodes[i].key_hash = 0;
#endif
#ifdef HM_VALUE_IS_STR
        nodes[i].value = NULL;
        nodes[i].val_len = 0;
#elif defined(HM_VALUE_IS_SV)
        nodes[i].value = NULL;
#else
        nodes[i].value = 0;
#endif
    }
}

/* ---- Free resources for a single node ---- */

static inline void HM_FN(free_node)(HM_MAP_TYPE* map, HM_NODE_TYPE* node) {
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
    if (node->value != NULL && map->free_value_fn) {
        map->free_value_fn(node->value);
        node->value = NULL;
    }
#endif
    (void)node;
}

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
    HM_FN(lru_unlink)(map, idx);
    HM_FN(lru_push_front)(map, idx);
}

/* Tombstone a node at a known index (used by LRU eviction and TTL expiry) */
static void HM_FN(tombstone_at)(HM_MAP_TYPE* map, size_t index) {
    HM_FN(free_node)(map, &map->nodes[index]);
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

/* Evict the LRU tail entry */
static void HM_FN(lru_evict_one)(HM_MAP_TYPE* map) {
    uint32_t victim = map->lru_tail;
    if (victim == HM_LRU_NONE) return;
    HM_FN(lru_unlink)(map, victim);
    HM_FN(tombstone_at)(map, (size_t)victim);
}

/* Forward declaration (needed by expire_at) */
static bool HM_FN(compact)(HM_MAP_TYPE* map);

/* Expire a TTL'd entry at a known index, with compact check */
static void HM_FN(expire_at)(HM_MAP_TYPE* map, size_t index) {
    if (map->lru_prev) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    if (map->tombstones > map->capacity / 4 ||
        (map->size > 0 && map->tombstones > map->size)) {
        HM_FN(compact)(map);
    }
}

/* ---- Create / Destroy ---- */

static HM_MAP_TYPE* HM_FN(create)(size_t max_size, uint32_t default_ttl) {
    HM_MAP_TYPE* map = (HM_MAP_TYPE*)malloc(sizeof(HM_MAP_TYPE));
    if (!map) return NULL;

    map->capacity = HM_INITIAL_CAPACITY;
    map->mask = HM_INITIAL_CAPACITY - 1;
    map->size = 0;
    map->tombstones = 0;
    map->max_size = max_size;
    map->default_ttl = default_ttl;
    map->lru_head = HM_LRU_NONE;
    map->lru_tail = HM_LRU_NONE;
    map->lru_prev = NULL;
    map->lru_next = NULL;
    map->iter_pos = 0;
#ifdef HM_VALUE_IS_SV
    map->free_value_fn = NULL;
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
                HM_FN(free_node)(map, &map->nodes[i]);
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
#if !defined(HM_KEY_IS_INT) || defined(HM_VALUE_IS_STR) || defined(HM_VALUE_IS_SV)
    {
        size_t i;
        for (i = 0; i < map->capacity; i++) {
            if (HM_SLOT_IS_LIVE(&map->nodes[i]))
                HM_FN(free_node)(map, &map->nodes[i]);
        }
    }
#endif
    HM_FN(init_nodes)(map->nodes, map->capacity);
    map->size = 0;
    map->tombstones = 0;
    map->iter_pos = 0;
    if (map->lru_prev) {
        memset(map->lru_prev, 0xFF, map->capacity * sizeof(uint32_t));
        memset(map->lru_next, 0xFF, map->capacity * sizeof(uint32_t));
        map->lru_head = HM_LRU_NONE;
        map->lru_tail = HM_LRU_NONE;
    }
    if (map->expires_at)
        memset(map->expires_at, 0, map->capacity * sizeof(uint32_t));
}

/* ---- Rehash: unified resize (grow=true) and compact (grow=false) ---- */

static bool HM_FN(rehash)(HM_MAP_TYPE* map, bool grow) {
    size_t old_capacity = map->capacity;
    HM_NODE_TYPE* old_nodes = map->nodes;

    size_t new_capacity = grow ? old_capacity * 2 : old_capacity;
    size_t new_mask = new_capacity - 1;
    HM_NODE_TYPE* new_nodes = (HM_NODE_TYPE*)malloc(new_capacity * sizeof(HM_NODE_TYPE));
    if (!new_nodes) return false;

    /* Allocate new LRU arrays if active */
    uint32_t* new_lru_prev = NULL;
    uint32_t* new_lru_next = NULL;
    uint32_t* old_to_new = NULL;
    if (map->lru_prev) {
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

    /* Allocate new TTL array if active */
    uint32_t* new_expires_at = NULL;
    if (map->expires_at) {
        new_expires_at = (uint32_t*)calloc(new_capacity, sizeof(uint32_t));
        if (!new_expires_at) {
            free(new_nodes); free(new_lru_prev); free(new_lru_next); free(old_to_new);
            return false;
        }
    }

    HM_FN(init_nodes)(new_nodes, new_capacity);

    /* Copy live entries */
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

    /* Rebuild LRU linked list preserving order */
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
    return HM_FN(rehash)(map, true);
}

static bool HM_FN(compact)(HM_MAP_TYPE* map) {
    return HM_FN(rehash)(map, false);
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
    } while (index != original_index);

    return map->capacity;
}

#else /* string keys */

static inline size_t HM_FN(find_node)(const HM_MAP_TYPE* map,
                                       const char* key, uint32_t key_len, uint32_t key_hash) {
    size_t index = (size_t)key_hash & map->mask;
    const size_t original_index = index;
    const HM_NODE_TYPE* nodes = map->nodes;

    do {
        if (nodes[index].key == NULL) return index; /* empty */
        if (nodes[index].key != HM_STR_TOMBSTONE &&
            nodes[index].key_hash == key_hash &&
            HM_UNPACK_LEN(nodes[index].key_len) == key_len &&
            memcmp(nodes[index].key, key, key_len) == 0) {
            return index; /* found */
        }
        index = (index + 1) & map->mask;
    } while (index != original_index);

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

    if ((map->size + map->tombstones) * 4 >= map->capacity * 3) {
        if (map->max_size > 0 && map->tombstones > 0) {
            if (!HM_FN(compact)(map)) return false;
        } else {
            if (!HM_FN(resize)(map)) return false;
        }
    }

    bool found;
    size_t index = HM_FN(find_slot_for_insert)(map, key, &found);
    if (index >= map->capacity) return false;

    /* LRU eviction: only on new insert at capacity */
    if (!found && map->max_size > 0 && map->size >= map->max_size) {
        HM_FN(lru_evict_one)(map);
        /* Re-probe after eviction to find optimal insertion slot */
        index = HM_FN(find_slot_for_insert)(map, key, &found);
        if (index >= map->capacity) return false;
    }

#ifdef HM_VALUE_IS_STR
    /* Pre-allocate value before modifying map state */
    char* new_val = NULL;
    uint32_t new_val_len = 0;
    if (value && val_len > 0) {
        new_val = (char*)malloc(val_len);
        if (!new_val) return false;
        memcpy(new_val, value, val_len);
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
        if (map->nodes[index].key == HM_TOMBSTONE_KEY) {
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

    /* LRU maintenance */
    if (map->lru_prev) {
        if (found) HM_FN(lru_promote)(map, (uint32_t)index);
        else       HM_FN(lru_push_front)(map, (uint32_t)index);
    }
    /* TTL maintenance — lazy allocation on first per-key TTL */
    if (entry_ttl > 0 && !map->expires_at)
        map->expires_at = (uint32_t*)calloc(map->capacity, sizeof(uint32_t));
    if (map->expires_at) {
        uint32_t ttl = entry_ttl > 0 ? entry_ttl : map->default_ttl;
        if (ttl > 0)
            map->expires_at[index] = (uint32_t)time(NULL) + ttl;
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

    if ((map->size + map->tombstones) * 4 >= map->capacity * 3) {
        if (map->max_size > 0 && map->tombstones > 0) {
            if (!HM_FN(compact)(map)) return false;
        } else {
            if (!HM_FN(resize)(map)) return false;
        }
    }

    bool found;
    size_t index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
    if (index >= map->capacity) return false;

    /* LRU eviction: only on new insert at capacity */
    if (!found && map->max_size > 0 && map->size >= map->max_size) {
        HM_FN(lru_evict_one)(map);
        /* Re-probe after eviction to find optimal insertion slot */
        index = HM_FN(find_slot_for_insert)(map, key, key_len, key_hash, &found);
        if (index >= map->capacity) return false;
    }

#ifdef HM_VALUE_IS_STR
    /* Pre-allocate value before modifying map state */
    char* new_val = NULL;
    uint32_t new_val_len = 0;
    if (value && val_len > 0) {
        new_val = (char*)malloc(val_len);
        if (!new_val) return false;
        memcpy(new_val, value, val_len);
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

    /* LRU maintenance */
    if (map->lru_prev) {
        if (found) HM_FN(lru_promote)(map, (uint32_t)index);
        else       HM_FN(lru_push_front)(map, (uint32_t)index);
    }
    /* TTL maintenance — lazy allocation on first per-key TTL */
    if (entry_ttl > 0 && !map->expires_at)
        map->expires_at = (uint32_t*)calloc(map->capacity, sizeof(uint32_t));
    if (map->expires_at) {
        uint32_t ttl = entry_ttl > 0 ? entry_ttl : map->default_ttl;
        if (ttl > 0)
            map->expires_at[index] = (uint32_t)time(NULL) + ttl;
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

    /* TTL check */
    if (map->expires_at && map->expires_at[index] &&
        (uint32_t)time(NULL) >= map->expires_at[index]) {
        HM_FN(expire_at)(map, index);
        return false;
    }

    if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);

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

    /* TTL check */
    if (map->expires_at && map->expires_at[index] &&
        (uint32_t)time(NULL) >= map->expires_at[index]) {
        HM_FN(expire_at)(map, index);
        return false;
    }

    if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);

    *out_value = map->nodes[index].value;
    return true;
}
#else
static bool HM_FN(get)(HM_MAP_TYPE* map, HM_INT_TYPE key, HM_INT_TYPE* out_value) {
    if (!map || !out_value || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key == HM_EMPTY_KEY) return false;

    /* TTL check */
    if (map->expires_at && map->expires_at[index] &&
        (uint32_t)time(NULL) >= map->expires_at[index]) {
        HM_FN(expire_at)(map, index);
        return false;
    }

    if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);

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

    /* TTL check */
    if (map->expires_at && map->expires_at[index] &&
        (uint32_t)time(NULL) >= map->expires_at[index]) {
        HM_FN(expire_at)(map, index);
        return false;
    }

    if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);

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

    /* TTL check */
    if (map->expires_at && map->expires_at[index] &&
        (uint32_t)time(NULL) >= map->expires_at[index]) {
        HM_FN(expire_at)(map, index);
        return false;
    }

    if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);

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

    /* TTL check */
    if (map->expires_at && map->expires_at[index] &&
        (uint32_t)time(NULL) >= map->expires_at[index]) {
        HM_FN(expire_at)(map, index);
        return false;
    }

    if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);

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

    /* TTL check */
    if (map->expires_at && map->expires_at[index] &&
        (uint32_t)time(NULL) >= map->expires_at[index]) {
        HM_FN(expire_at)(map, index);
        return false;
    }
    return true;
}

#else

static bool HM_FN(exists)(HM_MAP_TYPE* map,
                           const char* key, uint32_t key_len, uint32_t key_hash) {
    if (!map || !key) return false;
    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;

    /* TTL check */
    if (map->expires_at && map->expires_at[index] &&
        (uint32_t)time(NULL) >= map->expires_at[index]) {
        HM_FN(expire_at)(map, index);
        return false;
    }
    return true;
}

#endif

/* ---- remove ---- */

#ifdef HM_KEY_IS_INT

static bool HM_FN(remove)(HM_MAP_TYPE* map, HM_INT_TYPE key) {
    if (!map || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index >= map->capacity || map->nodes[index].key != key) return false;

    /* TTL check: treat expired entry as already gone */
    if (map->expires_at && map->expires_at[index] &&
        (uint32_t)time(NULL) >= map->expires_at[index]) {
        HM_FN(expire_at)(map, index);
        return false;
    }

    if (map->lru_prev) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    if (map->tombstones > map->capacity / 4 ||
        (map->size > 0 && map->tombstones > map->size)) {
        HM_FN(compact)(map);
    }
    return true;
}

#else /* string keys */

static bool HM_FN(remove)(HM_MAP_TYPE* map,
                           const char* key, uint32_t key_len, uint32_t key_hash) {
    if (!map || !key) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index >= map->capacity || map->nodes[index].key == NULL) return false;

    /* TTL check: treat expired entry as already gone */
    if (map->expires_at && map->expires_at[index] &&
        (uint32_t)time(NULL) >= map->expires_at[index]) {
        HM_FN(expire_at)(map, index);
        return false;
    }

    if (map->lru_prev) HM_FN(lru_unlink)(map, (uint32_t)index);
    HM_FN(tombstone_at)(map, index);
    if (map->tombstones > map->capacity / 4 ||
        (map->size > 0 && map->tombstones > map->size)) {
        HM_FN(compact)(map);
    }
    return true;
}

#endif

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
            if (nodes[target].key == HM_TOMBSTONE_KEY) map->tombstones--;
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
        /* TTL check */
        if (map->expires_at && map->expires_at[index] &&
            (uint32_t)time(NULL) >= map->expires_at[index]) {
            HM_FN(expire_at)(map, index);
            goto new_key;
        }
        if (map->nodes[index].value == HM_INT_MAX) return false;
        *out_value = ++map->nodes[index].value;
        if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);
        if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    if ((map->size + map->tombstones) * 4 >= map->capacity * 3) {
        if (map->max_size > 0 && map->tombstones > 0) {
            if (!HM_FN(compact)(map)) return false;
        } else {
            if (!HM_FN(resize)(map)) return false;
        }
    }

    index = HM_FN(find_or_allocate)(map, key);
    if (index >= map->capacity) return false;
    *out_value = ++map->nodes[index].value;
    if (map->lru_prev) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
    return true;
}

static bool HM_FN(increment_by)(HM_MAP_TYPE* map, HM_INT_TYPE key, HM_INT_TYPE delta, HM_INT_TYPE* out_value) {
    if (!map || !out_value || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index < map->capacity && map->nodes[index].key == key) {
        /* TTL check */
        if (map->expires_at && map->expires_at[index] &&
            (uint32_t)time(NULL) >= map->expires_at[index]) {
            HM_FN(expire_at)(map, index);
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
        if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);
        if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    if ((map->size + map->tombstones) * 4 >= map->capacity * 3) {
        if (map->max_size > 0 && map->tombstones > 0) {
            if (!HM_FN(compact)(map)) return false;
        } else {
            if (!HM_FN(resize)(map)) return false;
        }
    }

    index = HM_FN(find_or_allocate)(map, key);
    if (index >= map->capacity) return false;
    map->nodes[index].value = delta;
    *out_value = delta;
    if (map->lru_prev) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
    return true;
}

static bool HM_FN(decrement)(HM_MAP_TYPE* map, HM_INT_TYPE key, HM_INT_TYPE* out_value) {
    if (!map || !out_value || HM_IS_RESERVED_KEY(key)) return false;

    size_t index = HM_FN(find_node)(map, key);
    if (index < map->capacity && map->nodes[index].key == key) {
        /* TTL check */
        if (map->expires_at && map->expires_at[index] &&
            (uint32_t)time(NULL) >= map->expires_at[index]) {
            HM_FN(expire_at)(map, index);
            goto new_key;
        }
        if (map->nodes[index].value == HM_INT_MIN) return false;
        *out_value = --map->nodes[index].value;
        if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);
        if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    if ((map->size + map->tombstones) * 4 >= map->capacity * 3) {
        if (map->max_size > 0 && map->tombstones > 0) {
            if (!HM_FN(compact)(map)) return false;
        } else {
            if (!HM_FN(resize)(map)) return false;
        }
    }

    index = HM_FN(find_or_allocate)(map, key);
    if (index >= map->capacity) return false;
    *out_value = --map->nodes[index].value;
    if (map->lru_prev) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
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
    if (index < map->capacity && map->nodes[index].key != NULL &&
        map->nodes[index].key != HM_STR_TOMBSTONE) {
        /* TTL check */
        if (map->expires_at && map->expires_at[index] &&
            (uint32_t)time(NULL) >= map->expires_at[index]) {
            HM_FN(expire_at)(map, index);
            goto new_key;
        }
        if (map->nodes[index].value == HM_INT_MAX) return false;
        *out_value = ++map->nodes[index].value;
        if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);
        if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    if ((map->size + map->tombstones) * 4 >= map->capacity * 3) {
        if (map->max_size > 0 && map->tombstones > 0) {
            if (!HM_FN(compact)(map)) return false;
        } else {
            if (!HM_FN(resize)(map)) return false;
        }
    }

    index = HM_FN(find_or_allocate)(map, key, key_len, key_hash, key_utf8);
    if (index >= map->capacity) return false;
    *out_value = ++map->nodes[index].value;
    if (map->lru_prev) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
    return true;
}

static bool HM_FN(increment_by)(HM_MAP_TYPE* map,
                                 const char* key, uint32_t key_len, uint32_t key_hash, bool key_utf8,
                                 HM_INT_TYPE delta, HM_INT_TYPE* out_value) {
    if (!map || !key || !out_value) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index < map->capacity && map->nodes[index].key != NULL &&
        map->nodes[index].key != HM_STR_TOMBSTONE) {
        /* TTL check */
        if (map->expires_at && map->expires_at[index] &&
            (uint32_t)time(NULL) >= map->expires_at[index]) {
            HM_FN(expire_at)(map, index);
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
        if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);
        if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    if ((map->size + map->tombstones) * 4 >= map->capacity * 3) {
        if (map->max_size > 0 && map->tombstones > 0) {
            if (!HM_FN(compact)(map)) return false;
        } else {
            if (!HM_FN(resize)(map)) return false;
        }
    }

    index = HM_FN(find_or_allocate)(map, key, key_len, key_hash, key_utf8);
    if (index >= map->capacity) return false;
    map->nodes[index].value = delta;
    *out_value = delta;
    if (map->lru_prev) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
    return true;
}

static bool HM_FN(decrement)(HM_MAP_TYPE* map,
                              const char* key, uint32_t key_len, uint32_t key_hash, bool key_utf8,
                              HM_INT_TYPE* out_value) {
    if (!map || !key || !out_value) return false;

    size_t index = HM_FN(find_node)(map, key, key_len, key_hash);
    if (index < map->capacity && map->nodes[index].key != NULL &&
        map->nodes[index].key != HM_STR_TOMBSTONE) {
        /* TTL check */
        if (map->expires_at && map->expires_at[index] &&
            (uint32_t)time(NULL) >= map->expires_at[index]) {
            HM_FN(expire_at)(map, index);
            goto new_key;
        }
        if (map->nodes[index].value == HM_INT_MIN) return false;
        *out_value = --map->nodes[index].value;
        if (map->lru_prev) HM_FN(lru_promote)(map, (uint32_t)index);
        if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
        return true;
    }

new_key:
    if (map->max_size > 0 && map->size >= map->max_size)
        HM_FN(lru_evict_one)(map);

    if ((map->size + map->tombstones) * 4 >= map->capacity * 3) {
        if (map->max_size > 0 && map->tombstones > 0) {
            if (!HM_FN(compact)(map)) return false;
        } else {
            if (!HM_FN(resize)(map)) return false;
        }
    }

    index = HM_FN(find_or_allocate)(map, key, key_len, key_hash, key_utf8);
    if (index >= map->capacity) return false;
    *out_value = --map->nodes[index].value;
    if (map->lru_prev) HM_FN(lru_push_front)(map, (uint32_t)index);
    if (map->expires_at && map->default_ttl > 0) map->expires_at[index] = (uint32_t)time(NULL) + map->default_ttl;
    return true;
}

#endif /* HM_KEY_IS_INT for counters */

#endif /* HM_HAS_COUNTERS */

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

#ifdef HM_KEY_IS_INT
  #undef HM_KEY_IS_INT
#endif
#ifdef HM_VALUE_IS_STR
  #undef HM_VALUE_IS_STR
#endif
#ifdef HM_VALUE_IS_SV
  #undef HM_VALUE_IS_SV
#endif
#ifdef HM_HAS_COUNTERS
  #undef HM_HAS_COUNTERS
#endif

#undef HM_INT_TYPE
#undef HM_INT_MIN
#undef HM_INT_MAX
