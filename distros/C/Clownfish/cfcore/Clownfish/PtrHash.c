/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <limits.h>
#include <stddef.h>

#include "charmony.h"

#define CFISH_USE_SHORT_NAMES
#include "Clownfish/PtrHash.h"
#include "Clownfish/Err.h"
#include "Clownfish/Util/Memory.h"

#undef PTRHASH_STATS

#ifdef PTRHASH_STATS
  #include <stdio.h>
#endif

#if CHAR_BIT * CHY_SIZEOF_PTR <= 32
  #define PTR_BITS 32
#else
  #define PTR_BITS 64
#endif

#define MAX_FILL_FACTOR 0.625

typedef struct PtrHashEntry {
    void *key;
    void *value;
} PtrHashEntry;

struct PtrHash {
    size_t num_items;
    size_t cap;
    int    shift;
    PtrHashEntry *entries;
    PtrHashEntry *end;
};

static CFISH_INLINE size_t
SI_find_index(void *key, int shift);

static CFISH_INLINE size_t
SI_get_cap(size_t size);

static void
S_resize(PtrHash *self);

PtrHash*
PtrHash_new(size_t min_cap) {
    PtrHash *self   = (PtrHash*)MALLOCATE(sizeof(PtrHash));

    // Use minimum size of 8.
    // size == 2 ** (PTR_BITS - shift)
    size_t size  = 8;
    int    shift = PTR_BITS - 3;
    size_t cap   = SI_get_cap(size);

    while (cap < min_cap) {
        if (size > SIZE_MAX / 2 || shift == 0) {
            THROW(ERR, "PtrHash size overflow");
        }
        size  *= 2;
        shift -= 1;
        cap    = SI_get_cap(size);
    }

    self->num_items = 0;
    self->cap       = cap;
    self->shift     = shift;
    self->entries   = (PtrHashEntry*)CALLOCATE(size, sizeof(PtrHashEntry));
    self->end       = &self->entries[size];

    return self;
}

void
PtrHash_Destroy(PtrHash *self) {
    FREEMEM(self->entries);
    FREEMEM(self);
}

// Multiplicative hash function using the prime nearest to the golden ratio.
// Reasonably good and very fast.
static CFISH_INLINE size_t
SI_find_index(void *key, int shift) {
#if PTR_BITS == 32
    uint32_t value = (uint32_t)key * 0x9E3779B1u;
#else
    uint64_t value = (uint64_t)key * UINT64_C(0x9E3779B97F4A7C55);
#endif
    return (size_t)(value >> shift);
}

static CFISH_INLINE size_t
SI_get_cap(size_t size) {
    return (size_t)(MAX_FILL_FACTOR * size);
}

void
PtrHash_Store(PtrHash *self, void *key, void *value) {
    if (key == NULL) {
        THROW(ERR, "Can't store NULL key");
    }

    size_t index = SI_find_index(key, self->shift);
    PtrHashEntry *entry = &self->entries[index];

    while (entry->key != NULL) {
        if (entry->key == key) {
            entry->value = value;
            return;
        }

        entry += 1;
        if (entry >= self->end) { entry = self->entries; }
    }

    if (self->num_items >= self->cap) {
        S_resize(self);
        index = SI_find_index(key, self->shift);
        entry = &self->entries[index];

        while (entry->key != NULL) {
            entry += 1;
            if (entry >= self->end) { entry = self->entries; }
        }
    }

    entry->key   = key;
    entry->value = value;
    self->num_items += 1;
}

void*
PtrHash_Fetch(PtrHash *self, void *key) {
    if (key == NULL) {
        THROW(ERR, "Can't fetch NULL key");
    }

    size_t index = SI_find_index(key, self->shift);
    PtrHashEntry *entry = &self->entries[index];

    while (entry->key != NULL) {
        if (entry->key == key) {
            return entry->value;
        }

        entry += 1;
        if (entry >= self->end) { entry = self->entries; }
    }

    return NULL;
}

static void
S_resize(PtrHash *self) {
    size_t old_size = (size_t)(self->end - self->entries);
    if (old_size > SIZE_MAX / 2 || self->shift == 0) {
        THROW(ERR, "PtrHash size overflow");
    }
    size_t size  = old_size * 2;
    int    shift = self->shift - 1;

    PtrHashEntry *entries
        = (PtrHashEntry*)CALLOCATE(size, sizeof(PtrHashEntry));
    PtrHashEntry *end = &entries[size];

#ifdef PTRHASH_STATS
    size_t extra_probes = 0;
#endif

    for (PtrHashEntry *old_entry = self->entries;
         old_entry < self->end;
         ++old_entry
        ) {
        void *key = old_entry->key;
        if (key == NULL) { continue; }

#ifdef PTRHASH_STATS
        size_t i         = old_entry - self->entries;
        size_t old_index = SI_find_index(key, self->shift);
        extra_probes += (i - old_index) & (old_size - 1);
#endif

        size_t index = SI_find_index(key, shift);
        PtrHashEntry *entry = &entries[index];

        while (entry->key != NULL) {
            entry += 1;
            if (entry >= end) { entry = entries; }
        }

        entry->key   = key;
        entry->value = old_entry->value;
    }

#ifdef PTRHASH_STATS
    fprintf(stderr, "size: %u, avg probes: %.2f\n",
            (unsigned)old_size,
            (double)extra_probes / self->num_items + 1.0);
#endif

    FREEMEM(self->entries);

    self->cap     = SI_get_cap(size);
    self->shift   = shift;
    self->entries = entries;
    self->end     = end;
}


