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

#define C_CFISH_BYTEBUF
#define CFISH_USE_SHORT_NAMES

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "Clownfish/Class.h"
#include "Clownfish/ByteBuf.h"
#include "Clownfish/Blob.h"
#include "Clownfish/Err.h"
#include "Clownfish/String.h"
#include "Clownfish/Util/Memory.h"

// Ensure that the ByteBuf's capacity is at least (size + extra).
// If the buffer must be grown, oversize the allocation.
static CFISH_INLINE void
SI_add_grow_and_oversize(ByteBuf *self, size_t size, size_t extra);

// Compilers tend to inline this function although this is the unlikely
// slow path. If we ever add cross-platform support for the noinline
// attribute, it should be marked as such to reduce code size.
static void
S_grow_and_oversize(ByteBuf *self, size_t min_size);

// Not inlining the THROW macro reduces code size and complexity of
// SI_add_grow_and_oversize.
static void
S_overflow_error(void);

ByteBuf*
BB_new(size_t capacity) {
    ByteBuf *self = (ByteBuf*)Class_Make_Obj(BYTEBUF);
    return BB_init(self, capacity);
}

ByteBuf*
BB_init(ByteBuf *self, size_t min_cap) {
    // Round up to next multiple of eight.
    size_t capacity = (min_cap + 7) & ((size_t)~7);
    // Check for overflow.
    if (capacity < min_cap) { capacity = SIZE_MAX; }

    self->buf  = (char*)MALLOCATE(capacity);
    self->size = 0;
    self->cap  = capacity;
    return self;
}

ByteBuf*
BB_new_bytes(const void *bytes, size_t size) {
    ByteBuf *self = (ByteBuf*)Class_Make_Obj(BYTEBUF);
    return BB_init_bytes(self, bytes, size);
}

ByteBuf*
BB_init_bytes(ByteBuf *self, const void *bytes, size_t size) {
    // Round up to next multiple of eight.
    size_t capacity = (size + 7) & ((size_t)~7);
    // Check for overflow.
    if (capacity < size) { capacity = SIZE_MAX; }

    self->buf  = (char*)MALLOCATE(capacity);
    self->size = size;
    self->cap  = capacity;
    memcpy(self->buf, bytes, size);
    return self;
}

ByteBuf*
BB_new_steal_bytes(void *bytes, size_t size, size_t capacity) {
    ByteBuf *self = (ByteBuf*)Class_Make_Obj(BYTEBUF);
    return BB_init_steal_bytes(self, bytes, size, capacity);
}

ByteBuf*
BB_init_steal_bytes(ByteBuf *self, void *bytes, size_t size,
                    size_t capacity) {
    self->buf  = (char*)bytes;
    self->size = size;
    self->cap  = capacity;
    return self;
}

void
BB_Destroy_IMP(ByteBuf *self) {
    FREEMEM(self->buf);
    SUPER_DESTROY(self, BYTEBUF);
}

ByteBuf*
BB_Clone_IMP(ByteBuf *self) {
    return BB_new_bytes(self->buf, self->size);
}

void
BB_Set_Size_IMP(ByteBuf *self, size_t size) {
    if (size > self->cap) {
        THROW(ERR, "Can't set size to %u64 (greater than capacity of %u64)",
              (uint64_t)size, (uint64_t)self->cap);
    }
    self->size = size;
}

char*
BB_Get_Buf_IMP(ByteBuf *self) {
    return self->buf;
}

size_t
BB_Get_Size_IMP(ByteBuf *self) {
    return self->size;
}

size_t
BB_Get_Capacity_IMP(ByteBuf *self) {
    return self->cap;
}

static CFISH_INLINE bool
SI_equals_bytes(ByteBuf *self, const void *bytes, size_t size) {
    if (self->size != size) { return false; }
    return (memcmp(self->buf, bytes, self->size) == 0);
}

bool
BB_Equals_IMP(ByteBuf *self, Obj *other) {
    ByteBuf *const twin = (ByteBuf*)other;
    if (twin == self)              { return true; }
    if (!Obj_is_a(other, BYTEBUF)) { return false; }
    return SI_equals_bytes(self, twin->buf, twin->size);
}

bool
BB_Equals_Bytes_IMP(ByteBuf *self, const void *bytes, size_t size) {
    return SI_equals_bytes(self, bytes, size);
}

static CFISH_INLINE void
SI_cat_bytes(ByteBuf *self, const void *bytes, size_t size) {
    SI_add_grow_and_oversize(self, self->size, size);
    memcpy(self->buf + self->size, bytes, size);
    self->size += size;
}

void
BB_Cat_Bytes_IMP(ByteBuf *self, const void *bytes, size_t size) {
    SI_cat_bytes(self, bytes, size);
}

void
BB_Cat_IMP(ByteBuf *self, Blob *blob) {
    SI_cat_bytes(self, Blob_Get_Buf(blob), Blob_Get_Size(blob));
}

char*
BB_Grow_IMP(ByteBuf *self, size_t min_cap) {
    if (min_cap > self->cap) {
        // Round up to next multiple of eight.
        size_t capacity = (min_cap + 7) & ((size_t)~7);
        // Check for overflow.
        if (capacity < min_cap) { capacity = SIZE_MAX; }

        self->buf = (char*)REALLOCATE(self->buf, capacity);
        self->cap = capacity;
    }

    return self->buf;
}

Blob*
BB_Yield_Blob_IMP(ByteBuf *self) {
    Blob *blob = Blob_new_steal(self->buf, self->size);
    self->buf  = NULL;
    self->size = 0;
    self->cap  = 0;
    return blob;
}

String*
BB_Utf8_To_String_IMP(ByteBuf *self) {
    return Str_new_from_utf8(self->buf, self->size);
}

String*
BB_Trusted_Utf8_To_String_IMP(ByteBuf *self) {
    return Str_new_from_trusted_utf8(self->buf, self->size);
}

int32_t
BB_Compare_To_IMP(ByteBuf *self, Obj *other) {
    ByteBuf *twin = (ByteBuf*)CERTIFY(other, BYTEBUF);
    const size_t size = self->size < twin->size ? self->size : twin->size;

    int32_t comparison = memcmp(self->buf, twin->buf, size);

    if (comparison == 0 && self->size != twin->size) {
        comparison = self->size < twin->size ? -1 : 1;
    }

    return comparison;
}

static CFISH_INLINE void
SI_add_grow_and_oversize(ByteBuf *self, size_t size, size_t extra) {
    size_t min_size = size + extra;
    if (min_size < size) {
        S_overflow_error();
        return;
    }

    if (min_size > self->cap) {
        S_grow_and_oversize(self, min_size);
    }
}

static void
S_grow_and_oversize(ByteBuf *self, size_t min_size) {
    // Oversize by 25%, but at least eight bytes.
    size_t extra = min_size / 4;
    // Round up to next multiple of eight.
    extra = (extra + 7) & ((size_t)~7);

    size_t capacity = min_size + extra;
    // Check for overflow.
    if (capacity < min_size) { capacity = SIZE_MAX; }

    self->buf = (char*)REALLOCATE(self->buf, capacity);
    self->cap = capacity;
}

static void
S_overflow_error() {
    THROW(ERR, "ByteBuf buffer overflow");
}


