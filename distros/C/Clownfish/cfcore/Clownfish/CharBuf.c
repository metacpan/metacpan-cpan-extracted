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

#define C_CFISH_CHARBUF
#define C_CFISH_STRING
#define CFISH_USE_SHORT_NAMES

#include "charmony.h"

#include <stddef.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "Clownfish/CharBuf.h"

#include "Clownfish/Err.h"
#include "Clownfish/String.h"
#include "Clownfish/Util/Memory.h"
#include "Clownfish/Class.h"

// Append trusted UTF-8 to the CharBuf.
static void
S_cat_utf8(CharBuf *self, const char* ptr, size_t size);

// Inline version of S_cat_utf8.
static CFISH_INLINE void
SI_cat_utf8(CharBuf *self, const char* ptr, size_t size);

// Ensure that the CharBuf's capacity is at least (size + extra).
// If the buffer must be grown, oversize the allocation.
static CFISH_INLINE void
SI_add_grow_and_oversize(CharBuf *self, size_t size, size_t extra);

// Compilers tend to inline this function although this is the unlikely
// slow path. If we ever add cross-platform support for the noinline
// attribute, it should be marked as such to reduce code size.
static void
S_grow_and_oversize(CharBuf *self, size_t min_size);

// Not inlining the THROW macro reduces code size and complexity of
// SI_add_grow_and_oversize.
static void
S_overflow_error(void);

// Helper function for throwing invalid format specifier error.
static void
S_die_invalid_specifier(const char *specifier);

CharBuf*
CB_new(size_t size) {
    CharBuf *self = (CharBuf*)Class_Make_Obj(CHARBUF);
    return CB_init(self, size);
}

CharBuf*
CB_init(CharBuf *self, size_t size) {
    // Derive.
    self->ptr = (char*)MALLOCATE(size);

    // Assign.
    self->size = 0;
    self->cap  = size;

    return self;
}

void
CB_Destroy_IMP(CharBuf *self) {
    FREEMEM(self->ptr);
    SUPER_DESTROY(self, CHARBUF);
}

void
CB_Grow_IMP(CharBuf *self, size_t size) {
    if (size > self->cap) {
        self->cap = size;
        self->ptr = (char*)REALLOCATE(self->ptr, size);
    }
}

static void
S_die_invalid_specifier(const char *specifier) {
    char buf[4];
    buf[0] = specifier[0];
    buf[1] = '\0';

    if (specifier[0] == 'i' || specifier[0] == 'u' || specifier[0] == 'x'
        || specifier[0] == 'f'
       ) {
        if (specifier[1] < '0' || specifier[1] > '9') {
            THROW(ERR, "Specifier %%%s must be followed by width", buf);
        }
        else {
            size_t size = specifier[2] >= '0' && specifier[2] <= '9' ? 3 : 2;
            memcpy(buf, specifier, size);
            buf[size] = '\0';
            THROW(ERR, "Specifier %%%s has invalid width", buf);
        }
    }
    else {
        THROW(ERR, "Invalid specifier %%%s", buf);
    }
}

void
CB_catf(CharBuf *self, const char *pattern, ...) {
    va_list args;
    va_start(args, pattern);
    CB_VCatF(self, pattern, args);
    va_end(args);
}

void
CB_VCatF_IMP(CharBuf *self, const char *pattern, va_list args) {
    size_t      pattern_len = strlen(pattern);
    const char *pattern_end = pattern + pattern_len;
    char        buf[64];

    for (; pattern < pattern_end; pattern++) {
        const char *slice_end = pattern;

        // Consume all characters leading up to a '%'.
        while (slice_end < pattern_end && *slice_end != '%') { slice_end++; }
        if (pattern != slice_end) {
            ptrdiff_t size = slice_end - pattern;
            VALIDATE_UTF8(pattern, size);
            S_cat_utf8(self, pattern, (size_t)size);
            pattern = slice_end;
        }

        if (pattern < pattern_end) {
            pattern++; // Move past '%'.

            switch (*pattern) {
                case '%': {
                        S_cat_utf8(self, "%", 1);
                    }
                    break;
                case 'o': {
                        Obj *obj = va_arg(args, Obj*);
                        if (!obj) {
                            S_cat_utf8(self, "[NULL]", 6);
                        }
                        else if (Obj_is_a(obj, STRING)) {
                            CB_Cat(self, (String*)obj);
                        }
                        else {
                            String *string = Obj_To_String(obj);
                            CB_Cat(self, string);
                            DECREF(string);
                        }
                    }
                    break;
                case 'i': {
                        int64_t val = 0;
                        if (pattern[1] == '8') {
                            val = va_arg(args, int32_t);
                            pattern++;
                        }
                        else if (pattern[1] == '3' && pattern[2] == '2') {
                            val = va_arg(args, int32_t);
                            pattern += 2;
                        }
                        else if (pattern[1] == '6' && pattern[2] == '4') {
                            val = va_arg(args, int64_t);
                            pattern += 2;
                        }
                        else {
                            S_die_invalid_specifier(pattern);
                        }
                        int size = sprintf(buf, "%" PRId64, val);
                        S_cat_utf8(self, buf, (size_t)size);
                    }
                    break;
                case 'u': {
                        uint64_t val = 0;
                        if (pattern[1] == '8') {
                            val = va_arg(args, uint32_t);
                            pattern += 1;
                        }
                        else if (pattern[1] == '3' && pattern[2] == '2') {
                            val = va_arg(args, uint32_t);
                            pattern += 2;
                        }
                        else if (pattern[1] == '6' && pattern[2] == '4') {
                            val = va_arg(args, uint64_t);
                            pattern += 2;
                        }
                        else {
                            S_die_invalid_specifier(pattern);
                        }
                        int size = sprintf(buf, "%" PRIu64, val);
                        S_cat_utf8(self, buf, (size_t)size);
                    }
                    break;
                case 'f': {
                        if (pattern[1] == '6' && pattern[2] == '4') {
                            double num  = va_arg(args, double);
                            char bigbuf[512];
                            int size = sprintf(bigbuf, "%g", num);
                            S_cat_utf8(self, bigbuf, (size_t)size);
                            pattern += 2;
                        }
                        else {
                            S_die_invalid_specifier(pattern);
                        }
                    }
                    break;
                case 'x': {
                        if (pattern[1] == '3' && pattern[2] == '2') {
                            unsigned long val = va_arg(args, uint32_t);
                            int size = sprintf(buf, "%.8lx", val);
                            S_cat_utf8(self, buf, (size_t)size);
                            pattern += 2;
                        }
                        else {
                            S_die_invalid_specifier(pattern);
                        }
                    }
                    break;
                case 's': {
                        char *string = va_arg(args, char*);
                        if (string == NULL) {
                            S_cat_utf8(self, "[NULL]", 6);
                        }
                        else {
                            size_t size = strlen(string);
                            VALIDATE_UTF8(string, size);
                            S_cat_utf8(self, string, size);
                        }
                    }
                    break;
                default: {
                        // Assume NULL-terminated pattern string, which
                        // eliminates the need for bounds checking if '%' is
                        // the last visible character.
                        S_die_invalid_specifier(pattern);
                    }
            }
        }
    }
}

String*
CB_To_String_IMP(CharBuf *self) {
    return Str_new_from_trusted_utf8(self->ptr, self->size);
}

String*
CB_Yield_String_IMP(CharBuf *self) {
    // Null-terminate buffer.
    size_t size = self->size;
    SI_add_grow_and_oversize(self, size, 1);
    self->ptr[size] = '\0';

    String *retval = Str_new_steal_trusted_utf8(self->ptr, size);

    // Clear CharBuf.
    self->ptr  = NULL;
    self->size = 0;
    self->cap  = 0;

    return retval;
}

void
CB_Cat_Char_IMP(CharBuf *self, int32_t code_point) {
    if (code_point < 0
        || (code_point >= 0xD800 && code_point < 0xE000)
        || code_point >= 0x110000
       ) {
        THROW(ERR, "Invalid code point: 0x%x32", (uint32_t)code_point);
    }
    const size_t MAX_UTF8_BYTES = 4;
    size_t old_size = self->size;
    SI_add_grow_and_oversize(self, old_size, MAX_UTF8_BYTES);
    char *end = self->ptr + old_size;
    size_t count = Str_encode_utf8_char(code_point, (uint8_t*)end);
    self->size += count;
}

CharBuf*
CB_Clone_IMP(CharBuf *self) {
    size_t   size  = self->size;
    CharBuf *clone = CB_new(size);

    clone->size = size;
    memcpy(clone->ptr, self->ptr, size);

    return clone;
}

void
CB_Cat_Utf8_IMP(CharBuf *self, const char* ptr, size_t size) {
    VALIDATE_UTF8(ptr, size);
    SI_cat_utf8(self, ptr, size);
}

void
CB_Cat_Trusted_Utf8_IMP(CharBuf *self, const char* ptr, size_t size) {
    SI_cat_utf8(self, ptr, size);
}

void
CB_Cat_IMP(CharBuf *self, String *string) {
    SI_cat_utf8(self, string->ptr, string->size);
}

void
CB_Clear_IMP(CharBuf *self) {
    self->size = 0;
}

size_t
CB_Get_Size_IMP(CharBuf *self) {
    return self->size;
}

static void
S_cat_utf8(CharBuf *self, const char* ptr, size_t size) {
    SI_cat_utf8(self, ptr, size);
}

static CFISH_INLINE void
SI_cat_utf8(CharBuf *self, const char* ptr, size_t size) {
    size_t old_size = self->size;
    SI_add_grow_and_oversize(self, old_size, size);
    memcpy(self->ptr + old_size, ptr, size);
    self->size = old_size + size;
}

static CFISH_INLINE void
SI_add_grow_and_oversize(CharBuf *self, size_t size, size_t extra) {
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
S_grow_and_oversize(CharBuf *self, size_t min_size) {
    // Oversize by 25%, but at least eight bytes.
    size_t extra = min_size / 4;
    // Round up to next multiple of eight.
    extra = (extra + 7) & ((size_t)(~7));

    size_t capacity = min_size + extra;
    if (capacity < min_size) {
        capacity = SIZE_MAX;
    }

    self->cap = capacity;
    self->ptr = (char*)REALLOCATE(self->ptr, capacity);
}

static void
S_overflow_error() {
    THROW(ERR, "CharBuf buffer overflow");
}


