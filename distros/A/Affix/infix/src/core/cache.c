/**
 * Copyright (c) 2025 Sanko Robinson
 *
 * This source code is dual-licensed under the Artistic License 2.0 or the MIT License.
 * You may choose to use this code under the terms of either license.
 *
 * SPDX-License-Identifier: (Artistic-2.0 OR MIT)
 *
 * The documentation blocks within this file are licensed under the
 * Creative Commons Attribution 4.0 International License (CC BY 4.0).
 *
 * SPDX-License-Identifier: CC-BY-4.0
 */
/**
 * @file cache.c
 * @brief Implements trampoline deduplication and caching.
 * @ingroup internal_core
 */
#include "common/infix_internals.h"
#include <stdlib.h>
#include <string.h>

/** @internal Initial number of buckets for the global trampoline cache. */
#define CACHE_BUCKETS 1021

/** @internal Maximum number of entries the global trampoline cache will retain.
 *  The cache is bounded so that applications which create many unique trampoline
 *  signatures (e.g., generated FFI bindings, or a fuzzer) cannot exhaust memory by
 *  permanently retaining every JIT-compiled handle. Once this limit is reached, the
 *  least-recently-used entries are evicted (and destroyed when no longer referenced). */
#define CACHE_MAX_ENTRIES INFIX_CACHE_MAX_ENTRIES

/** @internal A single entry in the global trampoline cache. */
typedef struct _cache_entry_t {
    infix_forward_t * trampoline;     /**< The cached trampoline handle. */
    struct _cache_entry_t * next;     /**< Next entry in the hash bucket chain. */
    struct _cache_entry_t * lru_prev; /**< Previous entry in the LRU list. */
    struct _cache_entry_t * lru_next; /**< Next entry in the LRU list. */
} _cache_entry_t;

/** @internal The global hash table for forward trampolines. */
static _cache_entry_t * g_trampoline_cache[CACHE_BUCKETS];
/** @internal Most-recently-used end of the LRU list. */
static _cache_entry_t * g_cache_lru_head;
/** @internal Least-recently-used end of the LRU list (eviction candidate). */
static _cache_entry_t * g_cache_lru_tail;
/** @internal Number of entries currently in the cache. */
static size_t g_cache_count = 0;
/** @internal Mutex to protect the global cache. */
static infix_mutex_t g_cache_mutex = INFIX_MUTEX_INITIALIZER;

/**
 * @internal
 * @brief Unlinks an entry from the LRU list. Assumes the mutex is held.
 */
static void _cache_lru_unlink(_cache_entry_t * entry) {
    if (entry->lru_prev)
        entry->lru_prev->lru_next = entry->lru_next;
    else
        g_cache_lru_head = entry->lru_next;
    if (entry->lru_next)
        entry->lru_next->lru_prev = entry->lru_prev;
    else
        g_cache_lru_tail = entry->lru_prev;
    entry->lru_prev = nullptr;
    entry->lru_next = nullptr;
}

/**
 * @internal
 * @brief Pushes an entry onto the front (MRU end) of the LRU list. Assumes the mutex is held.
 */
static void _cache_lru_push_front(_cache_entry_t * entry) {
    entry->lru_prev = nullptr;
    entry->lru_next = g_cache_lru_head;
    if (g_cache_lru_head)
        g_cache_lru_head->lru_prev = entry;
    g_cache_lru_head = entry;
    if (g_cache_lru_tail == nullptr)
        g_cache_lru_tail = entry;
}

/**
 * @internal
 * @brief Computes a hash for a cache lookup.
 */
static uint64_t _cache_hash(const char * sig, void * target_fn, bool is_safe) {
    uint64_t h = 5381;
    int c;
    while ((c = *sig++))
        h = ((h << 5) + h) + c;
    h ^= (uint64_t)(uintptr_t)target_fn;
    if (is_safe)
        h ^= 0x123456789ABCDEF0ULL;
    return h;
}

/**
 * @internal
 * @brief Searches the global cache for an existing trampoline.
 * @return The cached trampoline with its ref_count incremented, or NULL if not found.
 */
infix_forward_t * _infix_cache_lookup(const char * signature, void * target_fn, bool is_safe) {
    uint64_t h = _cache_hash(signature, target_fn, is_safe);
    size_t index = h % CACHE_BUCKETS;

    INFIX_MUTEX_LOCK(&g_cache_mutex);
    for (_cache_entry_t * entry = g_trampoline_cache[index]; entry; entry = entry->next) {
        if (entry->trampoline->target_fn == target_fn && entry->trampoline->is_safe == is_safe &&
            strcmp(entry->trampoline->signature, signature) == 0) {
            // Cache hit: promote the entry to the MRU end of the LRU list.
            _cache_lru_unlink(entry);
            _cache_lru_push_front(entry);
            entry->trampoline->ref_count++;
            INFIX_MUTEX_UNLOCK(&g_cache_mutex);
            return entry->trampoline;
        }
    }
    INFIX_MUTEX_UNLOCK(&g_cache_mutex);
    return NULL;
}

/**
 * @internal
 * @brief Internal non-locking removal helper (forward declaration).
 */
static bool _cache_remove_no_lock(infix_forward_t * trampoline);

/**
 * @internal
 * @brief Inserts a trampoline into the global cache.
 * @details The cache is bounded by `CACHE_MAX_ENTRIES`. When the limit is exceeded,
 *          least-recently-used entries are evicted (and destroyed if unreferenced),
 *          so the cache cannot grow without bound.
 */
void _infix_cache_insert(infix_forward_t * trampoline) {
    uint64_t h = _cache_hash(trampoline->signature, trampoline->target_fn, trampoline->is_safe);
    size_t index = h % CACHE_BUCKETS;

    INFIX_MUTEX_LOCK(&g_cache_mutex);
    // Double check it's not already there
    for (_cache_entry_t * entry = g_trampoline_cache[index]; entry; entry = entry->next) {
        if (entry->trampoline->target_fn == trampoline->target_fn &&
            entry->trampoline->is_safe == trampoline->is_safe &&
            strcmp(entry->trampoline->signature, trampoline->signature) == 0) {
            INFIX_MUTEX_UNLOCK(&g_cache_mutex);
            return;
        }
    }

    _cache_entry_t * entry = infix_malloc(sizeof(_cache_entry_t));
    if (!entry) {
        INFIX_MUTEX_UNLOCK(&g_cache_mutex);
        return;
    }

    entry->trampoline = trampoline;
    trampoline->ref_count++;  // Cache reference
    entry->next = g_trampoline_cache[index];
    entry->lru_prev = nullptr;
    entry->lru_next = nullptr;
    g_trampoline_cache[index] = entry;
    _cache_lru_push_front(entry);
    g_cache_count++;

    // Evict least-recently-used entries until the cache is back within its bound.
    while (g_cache_count > CACHE_MAX_ENTRIES && g_cache_lru_tail) {
        infix_forward_t * victim = g_cache_lru_tail->trampoline;
        // The victim is guaranteed to be in the hash table; if not, bail out to
        // avoid spinning on an inconsistent LRU list.
        if (!_cache_remove_no_lock(victim))
            break;
        if (victim->ref_count == 0)
            _infix_forward_destroy_internal(victim);
    }
    INFIX_MUTEX_UNLOCK(&g_cache_mutex);
}

/**
 * @internal
 * @brief Clears all entries from the global cache.
 */
void _infix_cache_clear(void) {
    INFIX_MUTEX_LOCK(&g_cache_mutex);
    for (size_t i = 0; i < CACHE_BUCKETS; ++i) {
        _cache_entry_t * entry = g_trampoline_cache[i];
        while (entry) {
            _cache_entry_t * next = entry->next;
            if (--entry->trampoline->ref_count == 0)
                _infix_forward_destroy_internal(entry->trampoline);
            infix_free(entry);
            entry = next;
        }
        g_trampoline_cache[i] = nullptr;
    }
    g_cache_lru_head = nullptr;
    g_cache_lru_tail = nullptr;
    g_cache_count = 0;
    INFIX_MUTEX_UNLOCK(&g_cache_mutex);
}

/**
 * @internal
 * @brief Returns the number of entries currently in the global cache.
 */
size_t _infix_cache_count(void) {
    INFIX_MUTEX_LOCK(&g_cache_mutex);
    size_t count = g_cache_count;
    INFIX_MUTEX_UNLOCK(&g_cache_mutex);
    return count;
}

/**
 * @internal
 * @brief Internal non-locking removal helper.
 * @details Removes the entry from both the hash bucket chain and the LRU list.
 *          The caller is responsible for destroying the trampoline once its
 *          ref_count reaches zero.
 */
static bool _cache_remove_no_lock(infix_forward_t * trampoline) {
    if (!trampoline->signature)
        return false;
    uint64_t h = _cache_hash(trampoline->signature, trampoline->target_fn, trampoline->is_safe);
    size_t index = h % CACHE_BUCKETS;

    _cache_entry_t ** p = &g_trampoline_cache[index];
    while (*p) {
        if ((*p)->trampoline == trampoline) {
            _cache_entry_t * to_free = *p;
            *p = to_free->next;
            _cache_lru_unlink(to_free);
            g_cache_count--;
            infix_free(to_free);
            trampoline->ref_count--;  // Decrement since cache no longer holds it
            return true;
        }
        p = &((*p)->next);
    }
    return false;
}

/**
 * @internal
 * @brief Removes a trampoline from the global cache.
 * @return True if found and removed.
 */
bool _infix_cache_remove(infix_forward_t * trampoline) {
    INFIX_MUTEX_LOCK(&g_cache_mutex);
    bool result = _cache_remove_no_lock(trampoline);
    INFIX_MUTEX_UNLOCK(&g_cache_mutex);
    return result;
}

/**
 * @internal
 * @brief Releases a reference to a trampoline, destroying it if the count hits 0.
 */
void _infix_cache_release(infix_forward_t * trampoline) {
    if (!trampoline)
        return;

    INFIX_MUTEX_LOCK(&g_cache_mutex);
    if (--trampoline->ref_count > 0) {
        INFIX_MUTEX_UNLOCK(&g_cache_mutex);
        return;
    }

    // Reference count is 0. Remove from cache and destroy.
    _cache_remove_no_lock(trampoline);
    INFIX_MUTEX_UNLOCK(&g_cache_mutex);

    _infix_forward_destroy_internal(trampoline);
}
