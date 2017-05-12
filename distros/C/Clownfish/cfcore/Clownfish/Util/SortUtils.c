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

#define C_CFISH_SORTUTILS
#define CFISH_USE_SHORT_NAMES

#include <string.h>
#include "Clownfish/Util/SortUtils.h"
#include "Clownfish/Err.h"

// Recursive merge sorting functions.
static void
S_msort4(void *velems, void *vscratch, size_t left, size_t right,
         CFISH_Sort_Compare_t compare, void *context);
static void
S_msort8(void *velems, void *vscratch, size_t left, size_t right,
         CFISH_Sort_Compare_t compare, void *context);
static void
S_msort_any(void *velems, void *vscratch, size_t left, size_t right,
            CFISH_Sort_Compare_t compare, void *context, size_t width);

static CFISH_INLINE void
SI_merge(void *left_vptr,  size_t left_size,
         void *right_vptr, size_t right_size,
         void *vdest, size_t width, CFISH_Sort_Compare_t compare, void *context);

void
Sort_mergesort(void *elems, void *scratch, size_t num_elems, size_t width,
               CFISH_Sort_Compare_t compare, void *context) {
    // Arrays of 0 or 1 items are already sorted.
    if (num_elems < 2) { return; }

    // Dispatch by element size.
    switch (width) {
        case 0:
            THROW(ERR, "Parameter 'width' cannot be 0");
            break;
        case 4:
            S_msort4(elems, scratch, 0, num_elems - 1, compare, context);
            break;
        case 8:
            S_msort8(elems, scratch, 0, num_elems - 1, compare, context);
            break;
        default:
            S_msort_any(elems, scratch, 0, num_elems - 1, compare,
                        context, width);
            break;
    }
}

#define WIDTH 4
static void
S_msort4(void *velems, void *vscratch, size_t left, size_t right,
         CFISH_Sort_Compare_t compare, void *context) {
    uint8_t *elems   = (uint8_t*)velems;
    uint8_t *scratch = (uint8_t*)vscratch;
    if (right > left) {
        const size_t mid = left + (right - left) / 2 + 1;
        S_msort4(elems, scratch, left, mid - 1, compare, context);
        S_msort4(elems, scratch, mid,  right, compare, context);
        SI_merge((elems + left * WIDTH), (mid - left),
                 (elems + mid * WIDTH), (right - mid + 1),
                 scratch, WIDTH, compare, context);
        memcpy((elems + left * WIDTH), scratch, ((right - left + 1) * WIDTH));
    }
}

#undef WIDTH
#define WIDTH 8
static void
S_msort8(void *velems, void *vscratch, size_t left, size_t right,
         CFISH_Sort_Compare_t compare, void *context) {
    uint8_t *elems   = (uint8_t*)velems;
    uint8_t *scratch = (uint8_t*)vscratch;
    if (right > left) {
        const size_t mid = left + (right - left) / 2 + 1;
        S_msort8(elems, scratch, left, mid - 1, compare, context);
        S_msort8(elems, scratch, mid,  right, compare, context);
        SI_merge((elems + left * WIDTH), (mid - left),
                 (elems + mid * WIDTH), (right - mid + 1),
                 scratch, WIDTH, compare, context);
        memcpy((elems + left * WIDTH), scratch, ((right - left + 1) * WIDTH));
    }
}

#undef WIDTH
static void
S_msort_any(void *velems, void *vscratch, size_t left, size_t right,
            CFISH_Sort_Compare_t compare, void *context, size_t width) {
    uint8_t *elems   = (uint8_t*)velems;
    uint8_t *scratch = (uint8_t*)vscratch;
    if (right > left) {
        const size_t mid = left + (right - left) / 2 + 1;
        S_msort_any(elems, scratch, left, mid - 1, compare, context, width);
        S_msort_any(elems, scratch, mid,  right,   compare, context, width);
        SI_merge((elems + left * width), (mid - left),
                 (elems + mid * width), (right - mid + 1),
                 scratch, width, compare, context);
        memcpy((elems + left * width), scratch, ((right - left + 1) * width));
    }
}

static CFISH_INLINE void
SI_merge(void *left_vptr,  size_t left_size,
         void *right_vptr, size_t right_size,
         void *vdest, size_t width, CFISH_Sort_Compare_t compare,
         void *context) {
    uint8_t *left_ptr    = (uint8_t*)left_vptr;
    uint8_t *right_ptr   = (uint8_t*)right_vptr;
    uint8_t *left_limit  = left_ptr + left_size * width;
    uint8_t *right_limit = right_ptr + right_size * width;
    uint8_t *dest        = (uint8_t*)vdest;

    while (left_ptr < left_limit && right_ptr < right_limit) {
        if (compare(context, left_ptr, right_ptr) < 1) {
            memcpy(dest, left_ptr, width);
            dest += width;
            left_ptr += width;
        }
        else {
            memcpy(dest, right_ptr, width);
            dest += width;
            right_ptr += width;
        }
    }

    const ptrdiff_t left_remaining = left_limit - left_ptr;
    memcpy(dest, left_ptr, (size_t)left_remaining);
    dest += left_remaining;
    const ptrdiff_t right_remaining = right_limit - right_ptr;
    memcpy(dest, right_ptr, (size_t)right_remaining);
}


