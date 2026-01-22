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
 * @file arena.c
 * @brief Implements a simple, fast arena (or region-based) allocator.
 * @ingroup internal_core
 *
 * @details Arenas provide a mechanism for fast, grouped memory allocations that can all
 * be freed at once with a single call. This allocation strategy is also known as
 * region-based memory management.
 *
 * An arena works by pre-allocating a large, contiguous block of memory (the "region").
 * Subsequent allocation requests are satisfied by simply "bumping" a pointer
 * within this block. This "bump allocation" is extremely fast as it involves only
 * pointer arithmetic and avoids the overhead of system calls (`malloc`/`free`) for
 * each small allocation.
 *
 * This model is used extensively by the `infix` type system to manage the
 * lifetime of `infix_type` object graphs. When a type is created from a signature
 * or via the Manual API, all its constituent nodes are allocated from a single
 * arena. When the type is no longer needed, destroying the arena frees all
 * associated memory at once, preventing memory leaks and eliminating the need
 * for complex reference counting or garbage collection.
 */
#include "common/infix_internals.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
/**
 * @internal
 * @brief Creates a new memory arena with a specified initial size.
 *
 * Allocates an `infix_arena_t` struct and its backing buffer in a single block
 * of memory. If allocation fails at any point, it cleans up successfully allocated
 * parts, sets a detailed error, and returns `nullptr`.
 *
 * @param initial_size The number of bytes for the initial backing buffer. A larger
 *        size can reduce the chance of reallocation for complex types.
 * @return A pointer to the new `infix_arena_t`, or `nullptr` on failure.
 */
INFIX_API c23_nodiscard infix_arena_t * infix_arena_create(size_t initial_size) {
    // Use calloc to ensure the initial struct state is zeroed.
    infix_arena_t * arena = infix_calloc(1, sizeof(infix_arena_t));
    if (arena == nullptr) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return nullptr;
    }
    arena->buffer = infix_calloc(1, initial_size);
    if (arena->buffer == nullptr && initial_size > 0) {
        infix_free(arena);
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return nullptr;
    }
    arena->capacity = initial_size;
    arena->current_offset = 0;
    arena->error = false;
    arena->next_block = nullptr;
    arena->block_size = initial_size;
    return arena;
}
/**
 * @internal
 * @brief Destroys an arena and frees all memory associated with it.
 *
 * This function frees the arena's single backing buffer and the `infix_arena_t`
 * struct itself. Any pointers returned by `infix_arena_alloc` from this arena
 * become invalid after this call. It is safe to call this function with a
 * `nullptr` argument.
 *
 * @param arena A pointer to the arena to destroy.
 */
INFIX_API void infix_arena_destroy(infix_arena_t * arena) {
    if (arena == nullptr)
        return;
    // Traverse the chain of blocks and free each one.
    infix_arena_t * current = arena;
    while (current != nullptr) {
        infix_arena_t * next = current->next_block;
        if (current->buffer)
            infix_free(current->buffer);
        infix_free(current);
        current = next;
    }
}
/**
 * @internal
 * @brief Allocates a block of memory from an arena with a specified alignment.
 *
 * This is a "bump" allocator. It calculates the next memory address that satisfies
 * the requested alignment, checks if there is sufficient capacity in the arena's
 * buffer, and if so, "bumps" the `current_offset` pointer and returns the address.
 *
 * This operation is extremely fast as it involves no system calls, only simple
 * integer and pointer arithmetic.
 *
 * If an allocation fails (due to insufficient space or invalid arguments), the
 * arena's `error` flag is set, a detailed error is reported, and all subsequent
 * allocations from this arena will also fail.
 *
 * @param arena The arena to allocate from.
 * @param size The number of bytes to allocate.
 * @param alignment The required alignment for the allocation. Must be a power of two.
 * @return A pointer to the allocated memory, or `nullptr` if the arena is out of
 *         memory, has its error flag set, or an invalid alignment is requested.
 */
INFIX_API c23_nodiscard void * infix_arena_alloc(infix_arena_t * arena, size_t size, size_t alignment) {
    if (arena == nullptr)
        return nullptr;

    // Ensure alignment is power of 2
    if (alignment == 0 || (alignment & (alignment - 1)) != 0) {
        arena->error = true;
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_INVALID_ALIGNMENT, 0);
        return nullptr;
    }

    infix_arena_t * block = arena;
    while (true) {
        if (block->error)
            return nullptr;

        // 1. Calculate current absolute address
        uintptr_t current_ptr = (uintptr_t)(block->buffer + block->current_offset);

        // 2. Calculate aligned address
        // (x + align - 1) & ~(align - 1)
        uintptr_t aligned_ptr = (current_ptr + (alignment - 1)) & ~(alignment - 1);

        // 3. Calculate padding needed
        size_t padding = (size_t)(aligned_ptr - current_ptr);

        // 4. Calculate total space required in this block
        size_t total_needed = size + padding;

        // Check if fits in current block
        if (block->current_offset + total_needed <= block->capacity) {
            void * ret = (void *)aligned_ptr;
            block->current_offset += total_needed;
            return ret;
        }

        // 5. Allocation failed in current block. Check next or create new.
        if (block->next_block) {
            block = block->next_block;
            continue;
        }

        // Create new block. Ensure it's large enough for alignment + size.
        size_t next_cap = block->block_size * 2;
        if (next_cap < size + alignment)
            next_cap = size + alignment;

        block->next_block = infix_arena_create(next_cap);
        if (!block->next_block) {
            block->error = true;
            return nullptr;
        }

        block = block->next_block;
    }
}
/**
 * @internal
 * @brief Allocates and zero-initializes a block of memory from an arena.
 *
 * This function is a convenience wrapper around `infix_arena_alloc` that also
 * ensures the allocated memory is set to zero, mimicking the behavior of `calloc`.
 * It includes a check for integer overflow on the `num * size` calculation and
 * will set a detailed error on failure.
 *
 * @param arena The arena to allocate from.
 * @param num The number of elements to allocate.
 * @param size The size of each element.
 * @param alignment The required alignment for the allocation. Must be a power of two.
 * @return A pointer to the zero-initialized memory, or `nullptr` on failure.
 */
INFIX_API c23_nodiscard void * infix_arena_calloc(infix_arena_t * arena, size_t num, size_t size, size_t alignment) {
    // Security: Check for multiplication overflow.
    if (size > 0 && num > SIZE_MAX / size) {
        if (arena)
            arena->error = true;
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_INTEGER_OVERFLOW, 0);
        return nullptr;
    }
    size_t total_size = num * size;
    void * ptr = infix_arena_alloc(arena, total_size, alignment);
    if (ptr != nullptr)
        memset(ptr, 0, total_size);
    return ptr;
}
