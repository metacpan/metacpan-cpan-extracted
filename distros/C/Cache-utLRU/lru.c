#include <assert.h>
#include "gmem.h"
#include "lru.h"

Cache* cache_build(pTHX_ int capacity)
{
    Cache* cache;
    GMEM_NEW(cache, Cache*, sizeof(Cache));
    if (cache) {
        cache->capacity = capacity;
        cache->data = NULL;
    }
    return cache;
}

void cache_destroy(pTHX_ Cache* cache)
{
    cache_clear(aTHX_ cache);
#if defined(GMEM_CHECK)
    assert(HASH_COUNT(cache->data) == 0);
#endif
    GMEM_DEL(cache, Cache*, sizeof(Cache));
}

int cache_size(pTHX_ Cache* cache)
{
    return HASH_COUNT(cache->data);
}

int cache_capacity(pTHX_ Cache* cache)
{
    return cache->capacity;
}

static void clear_entry(pTHX_ Cache* cache, CacheEntry* entry)
{
    SvREFCNT_dec(entry->key);
    SvREFCNT_dec(entry->val);
    HASH_DELETE(hh, cache->data, entry);
    free(entry);
}

void cache_clear(pTHX_ Cache* cache)
{
    CacheEntry* entry;
    CacheEntry* tmp;
    HASH_ITER(hh, cache->data, entry, tmp) {
        clear_entry(aTHX_ cache, entry);
    }
}

SV* cache_find(pTHX_ Cache* cache, SV* key)
{
    STRLEN klen = 0;
    char* kptr = NULL;
    kptr = SvPV(key, klen);
    /* fprintf(stderr, "FIND KEY %lu [%s]\n", klen, kptr); */

    CacheEntry* entry;
    HASH_FIND(hh, cache->data, kptr, klen, entry);
    if (!entry) {
        return NULL;
    }

    /*
     * remove it; the subsequent add will throw it on the front of the list
     */
    HASH_DELETE(hh, cache->data, entry);
    HASH_ADD_KEYPTR(hh, cache->data, kptr, klen, entry);

    return entry->val;
}

int cache_add(pTHX_ Cache* cache, SV* key, SV* val)
{
    CacheEntry* entry = (CacheEntry*) malloc(sizeof(CacheEntry));
    if (!entry) {
        return 0;
    }

#if 0
    /*
     * This version simply increments the refcnt for key and val.
     * It is MUCH faster, and it would be awesome if we could use it.
     * BUT
     * Depending on how the key value was declared / used in Perl,
     * we have no guarantees that we will NOT overwrite data in the cache.
     */
    entry->key = key;
    entry->val = val;
    SvREFCNT_inc(entry->key);
    SvREFCNT_inc(entry->val);
#elif 1
    /*
     * This version creates SV* copies of key and val.
     * It is MUCH slower, but it might be the (only) correct way to do it.
     */
    entry->key = newSVsv(key);
    entry->val = newSVsv(val);
#else
    /*
     * This version creates SV* copies of key only.
     * It is slower, and maybe it works...
     */
    entry->key = newSVsv(key);
    entry->val = val;
    SvREFCNT_inc(entry->val);
#endif

    /* do not use gmem for these elements,
     * they will be deleted internally by ut */
    STRLEN klen = 0;
    char* kptr = NULL;
    kptr = SvPV(entry->key, klen);
    /* fprintf(stderr, "ADD KEY %lu [%s]\n", klen, kptr); */

    HASH_ADD_KEYPTR(hh, cache->data, kptr, klen, entry);

    /*
     * prune the cache to not exceed its size
     */
    int size = HASH_COUNT(cache->data);
    int j;
    for (j = cache->capacity; j < size; ++j) {
        CacheEntry* tmp;
        HASH_ITER(hh, cache->data, entry, tmp) {
            /*
             * prune the first entry; loop is based on insertion
             * order so this deletes the oldest item
             */

            clear_entry(aTHX_ cache, entry);
            break;
        }
    }

    return 1;
}

void cache_iterate(pTHX_ Cache* cache, CacheVisitor visitor, void* arg)
{
    CacheEntry* entry = NULL;
    CacheEntry* tmp = NULL;
    HASH_ITER(hh, cache->data, entry, tmp) {
        visitor(cache, entry, arg);
    }
}
