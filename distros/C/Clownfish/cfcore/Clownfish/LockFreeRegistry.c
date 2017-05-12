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

#define CFISH_USE_SHORT_NAMES

#include "Clownfish/Obj.h"
#include "Clownfish/LockFreeRegistry.h"
#include "Clownfish/Err.h"
#include "Clownfish/Class.h"
#include "Clownfish/String.h"
#include "Clownfish/Util/Atomic.h"
#include "Clownfish/Util/Memory.h"

struct cfish_LockFreeRegistry {
    size_t  capacity;
    void   *entries;
};

typedef struct cfish_LFRegEntry {
    String *key;
    Obj *value;
    size_t hash_sum;
    struct cfish_LFRegEntry *volatile next;
} cfish_LFRegEntry;
#define LFRegEntry cfish_LFRegEntry

LockFreeRegistry*
LFReg_new(size_t capacity) {
    LockFreeRegistry *self
        = (LockFreeRegistry*)CALLOCATE(1, sizeof(LockFreeRegistry));
    self->capacity = capacity;
    self->entries  = CALLOCATE(capacity, sizeof(void*));
    return self;
}

bool
LFReg_register(LockFreeRegistry *self, String *key, Obj *value) {
    LFRegEntry  *new_entry = NULL;
    size_t       hash_sum  = Str_Hash_Sum(key);
    size_t       bucket    = hash_sum  % self->capacity;
    LFRegEntry  *volatile *entries = (LFRegEntry*volatile*)self->entries;
    LFRegEntry  *volatile *slot    = &(entries[bucket]);

    // Proceed through the linked list.  Bail out if the key has already been
    // registered.
FIND_END_OF_LINKED_LIST:
    while (*slot) {
        LFRegEntry *entry = *slot;
        if (entry->hash_sum == hash_sum) {
            if (Str_Equals(key, (Obj*)entry->key)) {
                if (new_entry) {
                    DECREF(new_entry->key);
                    DECREF(new_entry->value);
                    FREEMEM(new_entry);
                }
                return false;
            }
        }
        slot = &(entry->next);
    }

    // We've found an empty slot. Create the new entry.
    if (!new_entry) {
        new_entry = (LFRegEntry*)MALLOCATE(sizeof(LFRegEntry));
        new_entry->hash_sum  = hash_sum;
        new_entry->key       = Str_new_from_trusted_utf8(Str_Get_Ptr8(key),
                                                         Str_Get_Size(key));
        new_entry->value     = INCREF(value);
        new_entry->next      = NULL;
    }

    /* Attempt to append the new node onto the end of the linked list.
     * However, if another thread filled the slot since we found it (perhaps
     * while we were allocating that new node), the compare-and-swap will
     * fail.  If that happens, we have to go back and find the new end of the
     * linked list, then try again. */
#if 1
    if (!Atomic_cas_ptr((void*volatile*)slot, NULL, new_entry)) {
        goto FIND_END_OF_LINKED_LIST;
    }
#else
    // This non-atomic version can be used to check whether the test suite
    // catches any race conditions.
    if (*slot == NULL) {
        *slot = new_entry;
    }
    else {
        goto FIND_END_OF_LINKED_LIST;
    }
#endif

    return true;
}

Obj*
LFReg_fetch(LockFreeRegistry *self, String *key) {
    size_t       hash_sum  = Str_Hash_Sum(key);
    size_t       bucket    = hash_sum  % self->capacity;
    LFRegEntry **entries   = (LFRegEntry**)self->entries;
    LFRegEntry  *entry     = entries[bucket];

    while (entry) {
        if (entry->hash_sum  == hash_sum) {
            if (Str_Equals(key, (Obj*)entry->key)) {
                return entry->value;
            }
        }
        entry = entry->next;
    }

    return NULL;
}

void
LFReg_destroy(LockFreeRegistry *self) {
    LFRegEntry **entries = (LFRegEntry**)self->entries;

    for (size_t i = 0; i < self->capacity; i++) {
        LFRegEntry *entry = entries[i];
        while (entry) {
            LFRegEntry *next_entry = entry->next;
            DECREF(entry->key);
            DECREF(entry->value);
            FREEMEM(entry);
            entry = next_entry;
        }
    }
    FREEMEM(self->entries);

    FREEMEM(self);
}


