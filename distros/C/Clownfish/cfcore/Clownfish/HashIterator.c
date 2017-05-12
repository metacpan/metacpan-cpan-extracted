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

#define C_CFISH_HASH
#define C_CFISH_HASHITERATOR
#define CFISH_USE_SHORT_NAMES

#include "Clownfish/Class.h"
#include "Clownfish/Err.h"
#include "Clownfish/String.h"

#include "Clownfish/Hash.h"
#include "Clownfish/HashIterator.h"

static String *TOMBSTONE;

typedef struct HashEntry {
    String *key;
    Obj    *value;
    size_t  hash_sum;
} HashEntry;

void
HashIter_init_class() {
    TOMBSTONE = Hash_get_tombstone();
    if (!TOMBSTONE) {
        THROW(ERR, "Singleton tombstone not set in Hash.");
    }
}

HashIterator*
HashIter_new(Hash *hash) {
    HashIterator *self = (HashIterator*)Class_Make_Obj(HASHITERATOR);
    return HashIter_init(self, hash);
}

HashIterator*
HashIter_init(HashIterator *self, Hash *hash) {
    self->hash     = (Hash*)INCREF(hash);
    self->tick     = (size_t)-1;
    self->capacity = hash->capacity;
    return self;
}

bool
HashIter_Next_IMP(HashIterator *self) {
    if (self->capacity != self->hash->capacity) {
        THROW(ERR, "Hash modified during iteration.");
    }
    while (1) {
        if (++self->tick >= self->capacity) {
            // Iteration complete. Pin tick at capacity.
            self->tick = self->capacity;
            return false;
        }
        else {
            HashEntry *const entry
                = (HashEntry*)self->hash->entries + self->tick;
            if (entry->key && entry->key != TOMBSTONE) {
                // Success.
                return true;
            }
        }
    }
}

String*
HashIter_Get_Key_IMP(HashIterator *self) {
    if (self->capacity != self->hash->capacity) {
        THROW(ERR, "Hash modified during iteration.");
    }
    if (self->tick == (size_t)-1) {
        THROW(ERR, "Invalid call to Get_Key before iteration.");
    }
    else if (self->tick >= self->capacity) {
        THROW(ERR, "Invalid call to Get_Key after end of iteration.");
    }

    HashEntry *const entry
        = (HashEntry*)self->hash->entries + self->tick;
    if (entry->key == TOMBSTONE) {
        THROW(ERR, "Hash modified during iteration.");
    }
    return entry->key;
}

Obj*
HashIter_Get_Value_IMP(HashIterator *self) {
    if (self->capacity != self->hash->capacity) {
        THROW(ERR, "Hash modified during iteration.");
    }
    if (self->tick == (size_t)-1) {
        THROW(ERR, "Invalid call to Get_Value before iteration.");
    }
    else if (self->tick >= self->capacity) {
        THROW(ERR, "Invalid call to Get_Value after end of iteration.");
    }

    HashEntry *const entry
        = (HashEntry*)self->hash->entries + self->tick;
    return entry->value;
}

void
HashIter_Destroy_IMP(HashIterator *self) {
    DECREF(self->hash);

    SUPER_DESTROY(self, HASHITERATOR);
}

