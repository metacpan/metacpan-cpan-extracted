/**
 * Copyright (c) 2025 Sanko Robinson
 *
 * This source code is dual-licensed under the Artistic License 2.0 or the MIT License.
 * You may choose to use this code under the terms of either license.
 *
 * SPDX-License-Identifier: (Artistic-2.0 OR MIT)
 */
/**
 * @file allocator.c
 * @brief The process-wide allocator table used for all of infix's internal heap allocations.
 *
 * Every internal allocation is routed through `infix_allocator` (see the `infix_*`
 * memory macros in `infix.h`). By default the table points at the C library's
 * `malloc`/`calloc`/`realloc`/`free`, so out of the box infix behaves exactly as it
 * always has. Host applications can install their own allocator with
 * `infix_set_allocator()` (e.g. a language runtime's tracked heap) so that every
 * block infix allocates and returns to the host comes from a single, known allocator.
 */
#include "common/infix_internals.h"
#include <stdlib.h>

infix_allocator_t infix_allocator = {malloc, calloc, realloc, free};

void infix_set_allocator(const infix_allocator_t * allocator) {
    if (allocator) {
        infix_allocator = *allocator;
    }
    else {
        infix_allocator.malloc = malloc;
        infix_allocator.calloc = calloc;
        infix_allocator.realloc = realloc;
        infix_allocator.free = free;
    }
}
