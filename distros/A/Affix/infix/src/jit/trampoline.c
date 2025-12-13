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
 * @file trampoline.c
 * @brief The core JIT engine for generating forward and reverse trampolines.
 * @ingroup internal_jit
 *
 * @details This module is the central orchestrator of the `infix` library. It brings
 * together the type system, memory management, and ABI-specific logic to generate
 * executable machine code at runtime.
 *
 * It implements both the high-level Signature API (e.g., `infix_forward_create`)
 * and the low-level Manual API (e.g., `infix_forward_create_manual`). The high-level
 * functions are convenient wrappers that use the signature parser to create the
 * necessary `infix_type` objects before calling the core internal implementation.
 *
 * The core logic is encapsulated in `_infix_forward_create_internal` and
 * `_infix_reverse_create_internal`. These functions follow a clear pipeline:
 * 1.  **Prepare:** Analyze the function signature with the appropriate ABI-specific
 *     `prepare_*_call_frame` function to create a layout blueprint.
 * 2.  **Generate:** Use the layout blueprint to call a sequence of ABI-specific
 *     `generate_*` functions, which emit machine code into a temporary `code_buffer`.
 * 3.  **Finalize:** Allocate executable memory, copy the generated code into it,
 *     create the final self-contained trampoline handle (deep-copying all type
 *     metadata), and make the code executable.
 */
#include "common/infix_internals.h"
#include "common/utility.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if defined(INFIX_OS_MACOS)
#include <pthread.h>
#endif
#if defined(INFIX_OS_WINDOWS)
#include <windows.h>
#else
#include <sys/mman.h>
#include <unistd.h>
#endif
// Forward Declaration for Internal Creation Function
static infix_status _infix_reverse_create_internal(infix_reverse_t ** out_context,
                                                   infix_type * return_type,
                                                   infix_type ** arg_types,
                                                   size_t num_args,
                                                   size_t num_fixed_args,
                                                   void * user_callback_fn,
                                                   void * user_data,
                                                   bool is_callback);
// ABI Specification V-Table Declarations (extern to link to the specific implementations)
#if defined(INFIX_ABI_WINDOWS_X64)
extern const infix_forward_abi_spec g_win_x64_forward_spec;
extern const infix_reverse_abi_spec g_win_x64_reverse_spec;
extern const infix_direct_forward_abi_spec g_win_x64_direct_forward_spec;
#elif defined(INFIX_ABI_SYSV_X64)
extern const infix_forward_abi_spec g_sysv_x64_forward_spec;
extern const infix_reverse_abi_spec g_sysv_x64_reverse_spec;
extern const infix_direct_forward_abi_spec g_sysv_x64_direct_forward_spec;
#elif defined(INFIX_ABI_AAPCS64)
extern const infix_forward_abi_spec g_arm64_forward_spec;
extern const infix_reverse_abi_spec g_arm64_reverse_spec;
extern const infix_direct_forward_abi_spec g_arm64_direct_forward_spec;
#endif
/**
 * @internal
 * @brief Retrieves a pointer to the ABI specification v-table for forward calls.
 * @details This function is the entry point to the ABI abstraction layer. It uses
 * compile-time preprocessor macros (defined in `infix_config.h`) to select and
 * return the correct v-table for the target platform.
 * @return A pointer to the active `infix_forward_abi_spec`, or `nullptr` if the
 *         platform is unsupported.
 */
const infix_forward_abi_spec * get_current_forward_abi_spec() {
#if defined(INFIX_ABI_WINDOWS_X64)
    return &g_win_x64_forward_spec;
#elif defined(INFIX_ABI_SYSV_X64)
    return &g_sysv_x64_forward_spec;
#elif defined(INFIX_ABI_AAPCS64)
    return &g_arm64_forward_spec;
#else
    return nullptr;
#endif
}
/**
 * @internal
 * @brief Retrieves a pointer to the ABI specification v-table for reverse calls.
 * @return A pointer to the active `infix_reverse_abi_spec`, or `nullptr` if the
 *         platform is unsupported.
 */
const infix_reverse_abi_spec * get_current_reverse_abi_spec() {
#if defined(INFIX_ABI_WINDOWS_X64)
    return &g_win_x64_reverse_spec;
#elif defined(INFIX_ABI_SYSV_X64)
    return &g_sysv_x64_reverse_spec;
#elif defined(INFIX_ABI_AAPCS64)
    return &g_arm64_reverse_spec;
#else
    return nullptr;
#endif
}
/**
 * @internal
 * @brief Retrieves a pointer to the ABI v-table for direct marshalling forward calls.
 * @return A pointer to the active `infix_direct_forward_abi_spec`, or `nullptr`.
 */
const infix_direct_forward_abi_spec * get_current_direct_forward_abi_spec() {
#if defined(INFIX_ABI_WINDOWS_X64)
    return &g_win_x64_direct_forward_spec;
#elif defined(INFIX_ABI_SYSV_X64)
    return &g_sysv_x64_direct_forward_spec;
#elif defined(INFIX_ABI_AAPCS64)
    return &g_arm64_direct_forward_spec;
#else
    return nullptr;
#endif
}
// Code Buffer Implementation
/**
 * @internal
 * @brief Initializes a `code_buffer` for JIT code generation.
 * @param buf A pointer to the `code_buffer` to initialize.
 * @param arena The temporary arena to use for the buffer's memory.
 */
void code_buffer_init(code_buffer * buf, infix_arena_t * arena) {
    buf->capacity = 64;  // Start with a small initial capacity.
    buf->arena = arena;
    buf->code = infix_arena_alloc(arena, buf->capacity, 16);
    buf->size = 0;
    buf->error = (buf->code == nullptr);
}
/**
 * @internal
 * @brief Appends data to a `code_buffer`, reallocating from its arena if necessary.
 *
 * @details If the buffer runs out of space, it doubles its capacity until the new data
 * fits. All allocations happen within the temporary arena, so no manual `free` or
 * `realloc` calls are needed; cleanup is automatic when the arena is destroyed.
 *
 * @param buf The code buffer.
 * @param data A pointer to the data to append.
 * @param len The length of the data in bytes.
 */
void code_buffer_append(code_buffer * buf, const void * data, size_t len) {
    if (buf->error)
        return;
    if (len > SIZE_MAX - buf->size) {  // Overflow check
        buf->error = true;
        return;
    }
    if (buf->size + len > buf->capacity) {
        size_t new_capacity = buf->capacity;
        while (new_capacity < buf->size + len) {
            if (new_capacity > SIZE_MAX / 2) {  // Overflow check
                buf->error = true;
                return;
            }
            new_capacity *= 2;
        }
        void * new_code = infix_arena_alloc(buf->arena, new_capacity, 16);
        if (new_code == nullptr) {
            buf->error = true;
            return;
        }
        infix_memcpy(new_code, buf->code, buf->size);
        buf->code = new_code;
        buf->capacity = new_capacity;
    }
    infix_memcpy(buf->code + buf->size, data, len);
    buf->size += len;
}
/** @internal @brief Appends a single byte to the code buffer. */
void emit_byte(code_buffer * buf, uint8_t byte) { code_buffer_append(buf, &byte, 1); }
/** @internal @brief Appends a 32-bit integer (little-endian) to the code buffer. */
void emit_int32(code_buffer * buf, int32_t value) { code_buffer_append(buf, &value, 4); }
/** @internal @brief Appends a 64-bit integer (little-endian) to the code buffer. */
void emit_int64(code_buffer * buf, int64_t value) { code_buffer_append(buf, &value, 8); }
// Type Graph Validation
/** @internal A node for a visited list to detect cycles in `_is_type_graph_resolved_recursive`. */
typedef struct visited_node_t {
    const infix_type * type;
    struct visited_node_t * next;
} visited_node_t;
/**
 * @internal
 * @brief Recursively checks if a type graph is fully resolved (contains no named references).
 *
 * This is a critical pre-flight check before passing a type graph to the ABI
 * classification layer, which expects all types to have concrete size and
 * alignment information. An unresolved `@Name` node would cause it to fail.
 *
 * @param type The type to check.
 * @param visited_head A list to track visited nodes and prevent infinite recursion on cycles.
 * @return `true` if the graph is fully resolved, `false` otherwise.
 */
static bool _is_type_graph_resolved_recursive(const infix_type * type, visited_node_t * visited_head) {
    if (!type)
        return true;
    if (type->is_incomplete)
        return false;
    // Cycle detection: if we've seen this node before, we can assume it's resolved
    // for the purpose of this check, as we'll validate it on the first visit.
    for (visited_node_t * v = visited_head; v != NULL; v = v->next)
        if (v->type == type)
            return true;
    visited_node_t current_visited_node = {.type = type, .next = visited_head};
    switch (type->category) {
    case INFIX_TYPE_NAMED_REFERENCE:
        return false;  // Base case: an unresolved reference.
    case INFIX_TYPE_POINTER:
        return _is_type_graph_resolved_recursive(type->meta.pointer_info.pointee_type, &current_visited_node);
    case INFIX_TYPE_ARRAY:
        return _is_type_graph_resolved_recursive(type->meta.array_info.element_type, &current_visited_node);
    case INFIX_TYPE_STRUCT:
    case INFIX_TYPE_UNION:
        for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i)
            if (!_is_type_graph_resolved_recursive(type->meta.aggregate_info.members[i].type, &current_visited_node))
                return false;
        return true;
    case INFIX_TYPE_REVERSE_TRAMPOLINE:
        if (!_is_type_graph_resolved_recursive(type->meta.func_ptr_info.return_type, &current_visited_node))
            return false;
        for (size_t i = 0; i < type->meta.func_ptr_info.num_args; ++i)
            if (!_is_type_graph_resolved_recursive(type->meta.func_ptr_info.args[i].type, &current_visited_node))
                return false;
        return true;
    default:
        return true;  // Primitives, void, etc., are always resolved.
    }
}
/**
 * @internal
 * @brief Public-internal wrapper for the recursive resolution check.
 */
static bool _is_type_graph_resolved(const infix_type * type) { return _is_type_graph_resolved_recursive(type, NULL); }
/**
 * @internal
 * @brief Estimates the memory required to store the type metadata for a function signature.
 *
 * This function iterates through the return and argument types, using the internal
 * _infix_estimate_graph_size utility to sum the required bytes for a deep copy
 * of all type information.
 *
 * @param temp_arena A temporary arena for the estimator's bookkeeping.
 * @param return_type The function's return type.
 * @param arg_types The array of argument types.
 * @param num_args The number of arguments.
 * @return The estimated size in bytes.
 */
static size_t _estimate_metadata_size(infix_arena_t * temp_arena,
                                      infix_type * return_type,
                                      infix_type ** arg_types,
                                      size_t num_args) {
    size_t total_size = 0;
    total_size += _infix_estimate_graph_size(temp_arena, return_type);
    if (arg_types != nullptr) {
        // Add space for the arg_types pointer array itself.
        total_size += sizeof(infix_type *) * num_args;
        for (size_t i = 0; i < num_args; ++i)
            total_size += _infix_estimate_graph_size(temp_arena, arg_types[i]);
    }
    return total_size;
}
// Forward Trampoline API Implementation
c23_nodiscard infix_unbound_cif_func infix_forward_get_unbound_code(infix_forward_t * trampoline) {
    if (trampoline == nullptr || trampoline->is_direct_trampoline || trampoline->target_fn != nullptr)
        return nullptr;
    return (infix_unbound_cif_func)trampoline->exec.rx_ptr;
}
c23_nodiscard infix_cif_func infix_forward_get_code(infix_forward_t * trampoline) {
    if (trampoline == nullptr || trampoline->is_direct_trampoline || trampoline->target_fn == nullptr)
        return nullptr;
    return (infix_cif_func)trampoline->exec.rx_ptr;
}
c23_nodiscard infix_direct_cif_func infix_forward_get_direct_code(infix_forward_t * trampoline) {
    if (trampoline == nullptr || !trampoline->is_direct_trampoline)
        return nullptr;
    return (infix_direct_cif_func)trampoline->exec.rx_ptr;
}
/**
 * @internal
 * @brief The core implementation for creating a forward trampoline.
 *
 * This function orchestrates the JIT compilation pipeline:
 * 1. Validates input types to ensure they are fully resolved.
 * 2. Selects the appropriate ABI specification v-table for the target platform.
 * 3. Creates a temporary arena for all intermediate allocations (layout, code buffer).
 * 4. Invokes the ABI spec functions in sequence to generate the call frame layout and machine code.
 * 5. Allocates the final `infix_forward_t` handle.
 * 6. Creates a private arena for the handle and deep-copies all type info into it,
 *    making the handle completely self-contained and independent of its source types.
 * 7. Allocates executable memory, copies the generated code, and makes it executable.
 *
 * @param[out] out_trampoline Receives the created trampoline handle.
 * @param[in] target_arena The arena to eventually store the trampoline in.
 * @param[in] return_type The fully resolved return type.
 * @param[in] arg_types An array of fully resolved argument types.
 * @param[in] num_args Total number of arguments.
 * @param[in] num_fixed_args Number of fixed (non-variadic) arguments.
 * @param[in] target_fn The target function pointer, or `nullptr` for an unbound trampoline.
 * @return `INFIX_SUCCESS` on success.
 */
c23_nodiscard infix_status _infix_forward_create_impl(infix_forward_t ** out_trampoline,
                                                      infix_arena_t * target_arena,
                                                      infix_type * return_type,
                                                      infix_type ** arg_types,
                                                      size_t num_args,
                                                      size_t num_fixed_args,
                                                      void * target_fn) {
    if (out_trampoline == nullptr || return_type == nullptr || (arg_types == nullptr && num_args > 0)) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_UNKNOWN, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    // Pre-flight check: ensure all types are resolved before passing to ABI layer.
    if (!_is_type_graph_resolved(return_type)) {
        _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_UNRESOLVED_NAMED_TYPE, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    for (size_t i = 0; i < num_args; ++i) {
        if (arg_types[i] == nullptr || !_is_type_graph_resolved(arg_types[i])) {
            _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_UNRESOLVED_NAMED_TYPE, 0);
            return INFIX_ERROR_INVALID_ARGUMENT;
        }
    }
    const infix_forward_abi_spec * spec = get_current_forward_abi_spec();
    if (spec == nullptr) {
        _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_UNSUPPORTED_ABI, 0);
        return INFIX_ERROR_UNSUPPORTED_ABI;
    }
    infix_status status = INFIX_SUCCESS;
    infix_call_frame_layout * layout = nullptr;
    infix_forward_t * handle = nullptr;
    // Use a temporary arena for all intermediate allocations during code generation.
    infix_arena_t * temp_arena = infix_arena_create(65536);
    if (!temp_arena) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    code_buffer buf;
    code_buffer_init(&buf, temp_arena);
    // JIT Compilation Pipeline
    // 1. Prepare: Classify arguments and create the layout blueprint.
    status = spec->prepare_forward_call_frame(
        temp_arena, &layout, return_type, arg_types, num_args, num_fixed_args, target_fn);
    if (status != INFIX_SUCCESS)
        goto cleanup;
    // 2. Generate: Emit machine code based on the layout.
    status = spec->generate_forward_prologue(&buf, layout);
    if (status != INFIX_SUCCESS)
        goto cleanup;
    status = spec->generate_forward_argument_moves(&buf, layout, arg_types, num_args, num_fixed_args);
    if (status != INFIX_SUCCESS)
        goto cleanup;
    status = spec->generate_forward_call_instruction(&buf, layout);
    if (status != INFIX_SUCCESS)
        goto cleanup;
    status = spec->generate_forward_epilogue(&buf, layout, return_type);
    if (status != INFIX_SUCCESS)
        goto cleanup;
    if (buf.error || temp_arena->error) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }
    // Finalize Handle
    handle = infix_calloc(1, sizeof(infix_forward_t));
    if (handle == nullptr) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }
    // "Estimate" stage: Calculate the exact size needed for the handle's private arena.
    size_t required_metadata_size = _estimate_metadata_size(temp_arena, return_type, arg_types, num_args);
    if (target_arena) {
        handle->arena = target_arena;
        handle->is_external_arena = true;
    }
    else {
        handle->arena = infix_arena_create(required_metadata_size + INFIX_TRAMPOLINE_HEADROOM);
        handle->is_external_arena = false;
    }
    if (handle->arena == nullptr) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }
    // "Copy" stage: Deep copy all type info into the handle's private arena.
    handle->return_type = _copy_type_graph_to_arena(handle->arena, return_type);
    if (num_args > 0) {
        handle->arg_types = infix_arena_alloc(handle->arena, sizeof(infix_type *) * num_args, _Alignof(infix_type *));
        if (handle->arg_types == nullptr) {
            status = INFIX_ERROR_ALLOCATION_FAILED;
            goto cleanup;
        }
        for (size_t i = 0; i < num_args; ++i) {
            handle->arg_types[i] = _copy_type_graph_to_arena(handle->arena, arg_types[i]);
            // Check for allocation failure during copy
            if (arg_types[i] != nullptr && handle->arg_types[i] == nullptr && !handle->arena->error) {
                status = INFIX_ERROR_ALLOCATION_FAILED;
                goto cleanup;
            }
        }
    }
    handle->num_args = num_args;
    handle->num_fixed_args = num_fixed_args;
    handle->target_fn = target_fn;
    // Allocate and finalize executable memory.
    handle->exec = infix_executable_alloc(buf.size);
    if (handle->exec.rw_ptr == nullptr) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }
    infix_memcpy(handle->exec.rw_ptr, buf.code, buf.size);
    if (!infix_executable_make_executable(handle->exec)) {
        status = INFIX_ERROR_PROTECTION_FAILED;
        goto cleanup;
    }
    infix_dump_hex(handle->exec.rx_ptr, handle->exec.size, "Forward Trampoline Machine Code");
    *out_trampoline = handle;
cleanup:
    // If any step failed, ensure the partially created handle is fully destroyed.
    if (status != INFIX_SUCCESS && handle != nullptr)
        infix_forward_destroy(handle);
    // The temporary arena is always destroyed.
    infix_arena_destroy(temp_arena);
    return status;
}
/**
 * @internal
 * @brief The core implementation for creating a direct marshalling forward trampoline.
 *
 * This function orchestrates the JIT compilation pipeline for the direct marshalling
 * feature. It is the internal counterpart to the public `infix_forward_create_direct`
 * function and is called after the signature string has been parsed into a type graph.
 *
 * The pipeline is as follows:
 * 1.  Selects the appropriate `infix_direct_forward_abi_spec` v-table for the target platform.
 * 2.  Invokes `prepare_direct_forward_call_frame` to analyze the signature and handlers,
 *     producing a complete layout blueprint.
 * 3.  Calls the `generate_*` functions from the v-table in sequence. This emits machine code
 *     that includes direct calls to the user-provided marshaller and write-back functions.
 * 4.  Finalizes the `infix_forward_t` handle, marking it as a `is_direct_trampoline`.
 * 5.  Allocates executable memory, copies the generated code, and makes it executable.
 *
 * @param[out] out_trampoline Receives the created trampoline handle.
 * @param[in] return_type The fully resolved return type.
 * @param[in] arg_types An array of fully resolved argument types.
 * @param[in] num_args Total number of arguments.
 * @param[in] target_fn The target C function pointer.
 * @param[in] handlers An array of handler structs provided by the user.
 * @return `INFIX_SUCCESS` on success, or an error code on failure.
 */
c23_nodiscard infix_status _infix_forward_create_direct_impl(infix_forward_t ** out_trampoline,
                                                             infix_type * return_type,
                                                             infix_type ** arg_types,
                                                             size_t num_args,
                                                             void * target_fn,
                                                             infix_direct_arg_handler_t * handlers) {
    // 1. Validation and Setup
    if (!out_trampoline || !return_type || (!arg_types && num_args > 0) || !target_fn || !handlers) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_UNKNOWN, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    const infix_direct_forward_abi_spec * spec = get_current_direct_forward_abi_spec();
    if (spec == nullptr) {
        _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_UNSUPPORTED_ABI, 0);
        return INFIX_ERROR_UNSUPPORTED_ABI;
    }

    infix_status status = INFIX_SUCCESS;
    infix_direct_call_frame_layout * layout = nullptr;
    infix_forward_t * handle = nullptr;
    infix_arena_t * temp_arena = infix_arena_create(65536);
    if (!temp_arena) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    code_buffer buf;
    code_buffer_init(&buf, temp_arena);

    // 2. JIT Compilation Pipeline
    status = spec->prepare_direct_forward_call_frame(
        temp_arena, &layout, return_type, arg_types, num_args, handlers, target_fn);
    if (status != INFIX_SUCCESS)
        goto cleanup;

    status = spec->generate_direct_forward_prologue(&buf, layout);
    if (status != INFIX_SUCCESS)
        goto cleanup;

    status = spec->generate_direct_forward_argument_moves(&buf, layout);
    if (status != INFIX_SUCCESS)
        goto cleanup;

    status = spec->generate_direct_forward_call_instruction(&buf, layout);
    if (status != INFIX_SUCCESS)
        goto cleanup;

    status = spec->generate_direct_forward_epilogue(&buf, layout, return_type);
    if (status != INFIX_SUCCESS)
        goto cleanup;

    if (buf.error || temp_arena->error) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }

    // 3. Finalize Handle
    handle = infix_calloc(1, sizeof(infix_forward_t));
    if (handle == nullptr) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }

    handle->is_direct_trampoline = true;  // Mark this as a direct marshalling trampoline.

    size_t required_metadata_size = _estimate_metadata_size(temp_arena, return_type, arg_types, num_args);
    handle->arena = infix_arena_create(required_metadata_size + INFIX_TRAMPOLINE_HEADROOM);
    handle->is_external_arena = false;
    if (handle->arena == nullptr) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }

    handle->return_type = _copy_type_graph_to_arena(handle->arena, return_type);
    if (num_args > 0) {
        handle->arg_types = infix_arena_alloc(handle->arena, sizeof(infix_type *) * num_args, _Alignof(infix_type *));
        if (!handle->arg_types) {
            status = INFIX_ERROR_ALLOCATION_FAILED;
            goto cleanup;
        }
        for (size_t i = 0; i < num_args; ++i) {
            handle->arg_types[i] = _copy_type_graph_to_arena(handle->arena, arg_types[i]);
            if (arg_types[i] && !handle->arg_types[i] && !handle->arena->error) {
                status = INFIX_ERROR_ALLOCATION_FAILED;
                goto cleanup;
            }
        }
    }
    handle->num_args = num_args;
    handle->num_fixed_args = num_args;  // Direct trampolines are always fixed-arity.
    handle->target_fn = target_fn;

    // 4. Allocate and Finalize Executable Memory
    handle->exec = infix_executable_alloc(buf.size);
    if (handle->exec.rw_ptr == nullptr) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }
    infix_memcpy(handle->exec.rw_ptr, buf.code, buf.size);
    if (!infix_executable_make_executable(handle->exec)) {
        status = INFIX_ERROR_PROTECTION_FAILED;
        goto cleanup;
    }

    infix_dump_hex(handle->exec.rx_ptr, handle->exec.size, "Direct-Marshalling Forward Trampoline Machine Code");
    *out_trampoline = handle;

cleanup:
    if (status != INFIX_SUCCESS && handle != nullptr)
        infix_forward_destroy(handle);
    infix_arena_destroy(temp_arena);
    return status;
}
/**
 * @brief Creates a bound forward trampoline from `infix_type` objects (Manual API).
 *
 * @details This is the lower-level, programmatic way to create a bound forward trampoline.
 * It bypasses the signature string parser, making it suitable for performance-critical
 * applications or language bindings that construct type information dynamically.
 *
 * All `infix_type` objects passed to this function must be fully resolved and have
 * a valid layout. They should be allocated from a user-managed `infix_arena_t`.
 *
 * @param[out] out_trampoline Receives the created trampoline handle.
 * @param[in] return_type The `infix_type` for the function's return value.
 * @param[in] arg_types An array of `infix_type*` for the function's arguments.
 * @param[in] num_args The number of arguments.
 * @param[in] num_fixed_args The number of non-variadic arguments.
 * @param[in] target_function The address of the C function to call.
 * @return `INFIX_SUCCESS` on success.
 */
c23_nodiscard infix_status infix_forward_create_manual(infix_forward_t ** out_trampoline,
                                                       infix_type * return_type,
                                                       infix_type ** arg_types,
                                                       size_t num_args,
                                                       size_t num_fixed_args,
                                                       void * target_function) {
    // This is part of the "Manual API". It calls the internal implementation directly
    // without involving the signature parser. `source_arena` is null because the
    // types are assumed to be managed by the user.
    _infix_clear_error();
    return _infix_forward_create_impl(
        out_trampoline, nullptr, return_type, arg_types, num_args, num_fixed_args, target_function);
}
/**
 * @brief Creates an unbound forward trampoline from `infix_type` objects (Manual API).
 *
 * @details This is the lower-level, programmatic way to create an unbound forward trampoline.
 * It bypasses the signature string parser.
 *
 * @param[out] out_trampoline Receives the created trampoline handle.
 * @param[in] return_type The `infix_type` for the function's return value.
 * @param[in] arg_types An array of `infix_type*` for the function's arguments.
 * @param[in] num_args The number of arguments.
 * @param[in] num_fixed_args The number of non-variadic arguments.
 * @return `INFIX_SUCCESS` on success.
 */
c23_nodiscard infix_status infix_forward_create_unbound_manual(infix_forward_t ** out_trampoline,
                                                               infix_type * return_type,
                                                               infix_type ** arg_types,
                                                               size_t num_args,
                                                               size_t num_fixed_args) {
    _infix_clear_error();
    return _infix_forward_create_impl(
        out_trampoline, nullptr, return_type, arg_types, num_args, num_fixed_args, nullptr);
}
/**
 * @brief Destroys a forward trampoline and frees all associated memory.
 * @details This function safely releases all resources owned by the trampoline,
 * including its JIT-compiled executable code and its private memory arena which
 * stores the deep-copied type information.
 * @param[in] trampoline The trampoline to destroy. Safe to call with `nullptr`.
 */
void infix_forward_destroy(infix_forward_t * trampoline) {
    if (trampoline == nullptr)
        return;
    // Destroying the private arena frees all deep-copied type metadata.
    if (trampoline->arena && !trampoline->is_external_arena)
        infix_arena_destroy(trampoline->arena);
    // Free the JIT-compiled executable code.
    infix_executable_free(trampoline->exec);
    // Free the handle struct itself.
    infix_free(trampoline);
}
// Reverse Trampoline API Implementation
/**
 * @internal
 * @brief Gets the system's memory page size in a portable way.
 * @return The page size in bytes.
 */
static size_t get_page_size() {
#if defined(INFIX_OS_WINDOWS)
    SYSTEM_INFO sysInfo;
    GetSystemInfo(&sysInfo);
    return sysInfo.dwPageSize;
#else
    // sysconf is the standard POSIX way to get system configuration values.
    return sysconf(_SC_PAGESIZE);
#endif
}
/**
 * @internal
 * @brief The core implementation for creating a reverse trampoline (callback or closure).
 *
 * @details This function orchestrates the JIT compilation pipeline for reverse calls.
 * It has a special `is_callback` flag that distinguishes between the two reverse
 * trampoline models:
 *
 * - **Type-safe Callback (`is_callback = true`):** In this model, the user provides a
 *   standard C function pointer with a matching signature. This function internally
 *   creates a *forward* trampoline (`cached_forward_trampoline`) that is used by the
 *   universal C dispatcher to call the user's handler in a type-safe way.
 *
 * - **Generic Closure (`is_callback = false`):** The user provides a generic handler of
 *   type `infix_closure_handler_fn`. The universal dispatcher calls this handler
 *   directly, without needing a cached forward trampoline.
 *
 * For security, the entire `infix_reverse_t` context struct is allocated in a
 * special page-aligned memory region that is made read-only after initialization.
 *
 * @param is_callback `true` to create a type-safe callback, `false` for a generic closure.
 * @return `INFIX_SUCCESS` on success.
 */
static infix_status _infix_reverse_create_internal(infix_reverse_t ** out_context,
                                                   infix_type * return_type,
                                                   infix_type ** arg_types,
                                                   size_t num_args,
                                                   size_t num_fixed_args,
                                                   void * user_callback_fn,
                                                   void * user_data,
                                                   bool is_callback) {
    if (out_context == nullptr || return_type == nullptr || num_fixed_args > num_args) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_UNKNOWN, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    // Pre-flight check: ensure all types are fully resolved.
    if (!_is_type_graph_resolved(return_type)) {
        _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_UNRESOLVED_NAMED_TYPE, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    if (arg_types == nullptr && num_args > 0) {
        _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_UNRESOLVED_NAMED_TYPE, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    for (size_t i = 0; i < num_args; ++i) {
        if (arg_types[i] == nullptr || !_is_type_graph_resolved(arg_types[i])) {
            _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_UNRESOLVED_NAMED_TYPE, 0);
            return INFIX_ERROR_INVALID_ARGUMENT;
        }
    }
    const infix_reverse_abi_spec * spec = get_current_reverse_abi_spec();
    if (spec == nullptr) {
        _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_UNSUPPORTED_ABI, 0);
        return INFIX_ERROR_UNSUPPORTED_ABI;
    }
    infix_status status = INFIX_SUCCESS;
    infix_reverse_call_frame_layout * layout = nullptr;
    infix_reverse_t * context = nullptr;
    infix_arena_t * temp_arena = nullptr;
    infix_protected_t prot = {.rw_ptr = nullptr, .size = 0};
    code_buffer buf;
    temp_arena = infix_arena_create(65536);
    if (!temp_arena) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    code_buffer_init(&buf, temp_arena);
    // Security Hardening: Allocate the context struct itself in special, page-aligned
    // memory that can be made read-only after initialization.
    size_t page_size = get_page_size();
    size_t context_alloc_size = (sizeof(infix_reverse_t) + page_size - 1) & ~(page_size - 1);
    prot = infix_protected_alloc(context_alloc_size);
    if (prot.rw_ptr == nullptr) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }
    context = (infix_reverse_t *)prot.rw_ptr;
    infix_memset(context, 0, context_alloc_size);
    // "Estimate" stage: Calculate the exact size needed for the context's private arena.
    size_t required_metadata_size = _estimate_metadata_size(temp_arena, return_type, arg_types, num_args);
    // Create the context's private arena with the calculated size plus some headroom for safety.
    context->arena = infix_arena_create(required_metadata_size + INFIX_TRAMPOLINE_HEADROOM);
    if (context->arena == nullptr) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }
    // Populate the context fields.
    context->protected_ctx = prot;
    context->num_args = num_args;
    context->num_fixed_args = num_fixed_args;
    context->is_variadic = (num_fixed_args < num_args);
    context->user_callback_fn = user_callback_fn;
    context->user_data = user_data;
    context->internal_dispatcher = infix_internal_dispatch_callback_fn_impl;
    context->cached_forward_trampoline = nullptr;
    // "Copy" stage: deep copy all types into the context's private arena.
    context->return_type = _copy_type_graph_to_arena(context->arena, return_type);
    if (num_args > 0) {
        context->arg_types = infix_arena_alloc(context->arena, sizeof(infix_type *) * num_args, _Alignof(infix_type *));
        if (context->arg_types == nullptr) {
            status = INFIX_ERROR_ALLOCATION_FAILED;
            goto cleanup;
        }
        for (size_t i = 0; i < num_args; ++i) {
            context->arg_types[i] = _copy_type_graph_to_arena(context->arena, arg_types[i]);
            if (arg_types[i] != nullptr && context->arg_types[i] == nullptr) {
                status = INFIX_ERROR_ALLOCATION_FAILED;
                goto cleanup;
            }
        }
    }
    // Special step for type-safe callbacks: generate and cache a forward trampoline
    // that will be used to call the user's type-safe C handler.
    if (is_callback) {
        status = infix_forward_create_manual(&context->cached_forward_trampoline,
                                             context->return_type,
                                             context->arg_types,
                                             context->num_args,
                                             context->num_fixed_args,
                                             user_callback_fn);
        if (status != INFIX_SUCCESS)
            goto cleanup;
    }
    // JIT Compilation Pipeline for Reverse Stub
    status = spec->prepare_reverse_call_frame(temp_arena, &layout, context);
    if (status != INFIX_SUCCESS)
        goto cleanup;
    status = spec->generate_reverse_prologue(&buf, layout);
    if (status != INFIX_SUCCESS)
        goto cleanup;
    status = spec->generate_reverse_argument_marshalling(&buf, layout, context);
    if (status != INFIX_SUCCESS)
        goto cleanup;
    status = spec->generate_reverse_dispatcher_call(&buf, layout, context);
    if (status != INFIX_SUCCESS)
        goto cleanup;
    status = spec->generate_reverse_epilogue(&buf, layout, context);
    if (status != INFIX_SUCCESS)
        goto cleanup;
    // End of Pipeline
    if (buf.error || temp_arena->error) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }
    context->exec = infix_executable_alloc(buf.size);
    if (context->exec.rw_ptr == nullptr) {
        status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }
    infix_memcpy(context->exec.rw_ptr, buf.code, buf.size);
    if (!infix_executable_make_executable(context->exec)) {
        status = INFIX_ERROR_PROTECTION_FAILED;
        goto cleanup;
    }
    // Security Hardening: Make the context memory read-only to prevent runtime corruption.
    if (!infix_protected_make_readonly(context->protected_ctx)) {
        status = INFIX_ERROR_PROTECTION_FAILED;
        goto cleanup;
    }
    infix_dump_hex(context->exec.rx_ptr, buf.size, "Reverse Trampoline Machine Code");
    *out_context = context;
cleanup:
    if (status != INFIX_SUCCESS) {
        // If allocation of the context itself failed, prot.rw_ptr will be null.
        if (prot.rw_ptr != nullptr)
            infix_reverse_destroy(context);
    }
    infix_arena_destroy(temp_arena);
    return status;
}
/**
 * @brief Creates a type-safe reverse trampoline (callback) from `infix_type` objects (Manual API).
 * @param[out] out_context Receives the created context handle.
 * @param[in] return_type The function's return type.
 * @param[in] arg_types An array of argument types.
 * @param[in] num_args The number of arguments.
 * @param[in] num_fixed_args The number of non-variadic arguments.
 * @param[in] user_callback_fn A pointer to the type-safe C handler function.
 * @return `INFIX_SUCCESS` on success.
 */
c23_nodiscard infix_status infix_reverse_create_callback_manual(infix_reverse_t ** out_context,
                                                                infix_type * return_type,
                                                                infix_type ** arg_types,
                                                                size_t num_args,
                                                                size_t num_fixed_args,
                                                                void * user_callback_fn) {
    _infix_clear_error();
    return _infix_reverse_create_internal(
        out_context, return_type, arg_types, num_args, num_fixed_args, user_callback_fn, nullptr, true);
}
/**
 * @brief Creates a generic reverse trampoline (closure) from `infix_type` objects (Manual API).
 * @param[out] out_context Receives the created context handle.
 * @param[in] return_type The function's return type.
 * @param[in] arg_types An array of argument types.
 * @param[in] num_args The number of arguments.
 * @param[in] num_fixed_args The number of non-variadic arguments.
 * @param[in] user_callback_fn A pointer to the generic `infix_closure_handler_fn`.
 * @param[in] user_data A `void*` pointer to application-specific state.
 * @return `INFIX_SUCCESS` on success.
 */
c23_nodiscard infix_status infix_reverse_create_closure_manual(infix_reverse_t ** out_context,
                                                               infix_type * return_type,
                                                               infix_type ** arg_types,
                                                               size_t num_args,
                                                               size_t num_fixed_args,
                                                               infix_closure_handler_fn user_callback_fn,
                                                               void * user_data) {
    _infix_clear_error();
    return _infix_reverse_create_internal(
        out_context, return_type, arg_types, num_args, num_fixed_args, (void *)user_callback_fn, user_data, false);
}
/**
 * @brief Destroys a reverse trampoline and frees all associated memory.
 * @details This function safely releases all resources owned by the reverse trampoline,
 * including its JIT-compiled stub, its private memory arena, the cached forward
 * trampoline (if any), and the special read-only memory region for the context itself.
 * @param[in] reverse_trampoline The reverse trampoline context to destroy. Safe to call with `nullptr`.
 */
void infix_reverse_destroy(infix_reverse_t * reverse_trampoline) {
    if (reverse_trampoline == nullptr)
        return;
    // The cached trampoline (if it exists) must also be destroyed.
    if (reverse_trampoline->cached_forward_trampoline)
        infix_forward_destroy(reverse_trampoline->cached_forward_trampoline);
    if (reverse_trampoline->arena)
        infix_arena_destroy(reverse_trampoline->arena);
    infix_executable_free(reverse_trampoline->exec);
    // Free the special read-only memory region for the context struct.
    infix_protected_free(reverse_trampoline->protected_ctx);
}
/**
 * @brief Gets the native, callable C function pointer from a reverse trampoline.
 * @param[in] reverse_trampoline The `infix_reverse_t` context handle.
 * @return A `void*` that can be cast to the appropriate C function pointer type and called.
 *         The returned pointer is valid for the lifetime of the context handle.
 */
c23_nodiscard void * infix_reverse_get_code(const infix_reverse_t * reverse_trampoline) {
    if (reverse_trampoline == nullptr)
        return nullptr;
    return reverse_trampoline->exec.rx_ptr;
}
/**
 * @brief Gets the user-provided data pointer from a closure context.
 * @param[in] reverse_trampoline The `infix_reverse_t` context handle created with `infix_reverse_create_closure`.
 * @return The `void* user_data` that was provided during creation.
 */
c23_nodiscard void * infix_reverse_get_user_data(const infix_reverse_t * reverse_trampoline) {
    if (reverse_trampoline == nullptr)
        return nullptr;
    return reverse_trampoline->user_data;
}
// High-Level Signature API Wrappers
c23_nodiscard infix_status infix_forward_create_in_arena(infix_forward_t ** out_trampoline,
                                                         infix_arena_t * target_arena,
                                                         const char * signature,
                                                         void * target_function,
                                                         infix_registry_t * registry) {
    _infix_clear_error();
    if (!signature) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_UNKNOWN, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    infix_arena_t * arena = nullptr;
    infix_type * ret_type = nullptr;
    infix_function_argument * args = nullptr;
    size_t num_args = 0, num_fixed = 0;
    infix_type ** arg_types = nullptr;
    infix_status status;
    if (signature[0] == '@') {
        if (registry == nullptr) {
            _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_UNKNOWN, 0);  // Using @Name requires a registry
            return INFIX_ERROR_INVALID_ARGUMENT;
        }
        const infix_type * func_type = infix_registry_lookup_type(registry, &signature[1]);
        if (func_type == NULL) {
            _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_UNRESOLVED_NAMED_TYPE, 0);
            return INFIX_ERROR_INVALID_ARGUMENT;
        }
        if (func_type->category != INFIX_TYPE_REVERSE_TRAMPOLINE) {
            // The user provided a name for a non-function type (e.g., "@Point")
            _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_UNEXPECTED_TOKEN, 0);
            return INFIX_ERROR_INVALID_ARGUMENT;
        }
        // We have a valid function type from the registry. Now, unpack its components.
        ret_type = func_type->meta.func_ptr_info.return_type;
        num_args = func_type->meta.func_ptr_info.num_args;
        num_fixed = func_type->meta.func_ptr_info.num_fixed_args;
        args = func_type->meta.func_ptr_info.args;
        // The Manual API needs a temporary arena to hold the arg_types array.
        infix_arena_t * temp_arena = infix_arena_create(sizeof(infix_type *) * num_args + 128);
        if (!temp_arena) {
            _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
            return INFIX_ERROR_ALLOCATION_FAILED;
        }
        if (num_args > 0) {
            arg_types = infix_arena_alloc(temp_arena, sizeof(infix_type *) * num_args, _Alignof(infix_type *));
            if (!arg_types) {
                infix_arena_destroy(temp_arena);
                _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
                return INFIX_ERROR_ALLOCATION_FAILED;
            }
            for (size_t i = 0; i < num_args; ++i)
                arg_types[i] = args[i].type;
        }
        arena = temp_arena;
    }
    else {
        // This is a high-level wrapper. It uses the parser to build the type info first.
        status = infix_signature_parse(signature, &arena, &ret_type, &args, &num_args, &num_fixed, registry);
        if (status != INFIX_SUCCESS) {
            infix_arena_destroy(arena);
            return status;
        }
        // Extract the `infix_type*` array from the parsed `infix_function_argument` array.
        arg_types = (num_args > 0) ? infix_arena_alloc(arena, sizeof(infix_type *) * num_args, _Alignof(infix_type *))
                                   : nullptr;
        if (num_args > 0 && !arg_types) {
            infix_arena_destroy(arena);
            _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
            return INFIX_ERROR_ALLOCATION_FAILED;
        }
        for (size_t i = 0; i < num_args; ++i)
            arg_types[i] = args[i].type;
    }
    // Call the core internal implementation with the parsed types.
    status = _infix_forward_create_impl(
        out_trampoline, target_arena, ret_type, arg_types, num_args, num_fixed, target_function);
    infix_arena_destroy(arena);
    return status;
}
c23_nodiscard infix_status infix_forward_create(infix_forward_t ** out_trampoline,
                                                const char * signature,
                                                void * target_function,
                                                infix_registry_t * registry) {
    return infix_forward_create_in_arena(out_trampoline, NULL, signature, target_function, registry);
}
c23_nodiscard infix_status infix_forward_create_unbound(infix_forward_t ** out_trampoline,
                                                        const char * signature,
                                                        infix_registry_t * registry) {
    return infix_forward_create_in_arena(out_trampoline, NULL, signature, NULL, registry);
}
c23_nodiscard infix_status infix_forward_create_direct(infix_forward_t ** out_trampoline,
                                                       const char * signature,
                                                       void * target_function,
                                                       infix_direct_arg_handler_t * handlers,
                                                       infix_registry_t * registry) {
    _infix_clear_error();
    if (!signature || !target_function || !handlers) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_UNKNOWN, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    infix_arena_t * arena = nullptr;
    infix_type * ret_type = nullptr;
    infix_function_argument * args = nullptr;
    size_t num_args = 0, num_fixed = 0;
    infix_type ** arg_types = nullptr;

    // Parse the signature to get the type graph.
    infix_status status = infix_signature_parse(signature, &arena, &ret_type, &args, &num_args, &num_fixed, registry);
    if (status != INFIX_SUCCESS) {
        infix_arena_destroy(arena);
        return status;
    }

    // Convert the parsed `infix_function_argument*` array to an `infix_type**` array.
    if (num_args > 0) {
        arg_types = infix_arena_alloc(arena, sizeof(infix_type *) * num_args, _Alignof(infix_type *));
        if (!arg_types) {
            infix_arena_destroy(arena);
            _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
            return INFIX_ERROR_ALLOCATION_FAILED;
        }
        for (size_t i = 0; i < num_args; ++i)
            arg_types[i] = args[i].type;
    }

    // Call the core internal implementation with the parsed types and provided handlers.
    status =
        _infix_forward_create_direct_impl(out_trampoline, ret_type, arg_types, num_args, target_function, handlers);

    // Clean up the temporary arena used by the parser.
    infix_arena_destroy(arena);
    return status;
}
c23_nodiscard infix_status infix_reverse_create_callback(infix_reverse_t ** out_context,
                                                         const char * signature,
                                                         void * user_callback_fn,
                                                         infix_registry_t * registry) {
    infix_arena_t * arena = nullptr;
    infix_type * ret_type = nullptr;
    infix_function_argument * args = nullptr;
    size_t num_args = 0, num_fixed = 0;
    infix_status status = infix_signature_parse(signature, &arena, &ret_type, &args, &num_args, &num_fixed, registry);
    if (status != INFIX_SUCCESS) {
        infix_arena_destroy(arena);
        return status;
    }
    infix_type ** arg_types =
        (num_args > 0) ? infix_arena_alloc(arena, sizeof(infix_type *) * num_args, _Alignof(infix_type *)) : nullptr;
    if (num_args > 0 && !arg_types) {
        infix_arena_destroy(arena);
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    for (size_t i = 0; i < num_args; ++i)
        arg_types[i] = args[i].type;
    // Call the manual API with the parsed types.
    status =
        infix_reverse_create_callback_manual(out_context, ret_type, arg_types, num_args, num_fixed, user_callback_fn);
    infix_arena_destroy(arena);
    return status;
}
c23_nodiscard infix_status infix_reverse_create_closure(infix_reverse_t ** out_context,
                                                        const char * signature,
                                                        infix_closure_handler_fn user_callback_fn,
                                                        void * user_data,
                                                        infix_registry_t * registry) {
    infix_arena_t * arena = nullptr;
    infix_type * ret_type = nullptr;
    infix_function_argument * args = nullptr;
    size_t num_args = 0, num_fixed = 0;
    infix_status status = infix_signature_parse(signature, &arena, &ret_type, &args, &num_args, &num_fixed, registry);
    if (status != INFIX_SUCCESS) {
        infix_arena_destroy(arena);
        return status;
    }
    infix_type ** arg_types =
        (num_args > 0) ? infix_arena_alloc(arena, sizeof(infix_type *) * num_args, _Alignof(infix_type *)) : nullptr;
    if (num_args > 0 && !arg_types) {
        infix_arena_destroy(arena);
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    for (size_t i = 0; i < num_args; ++i)
        arg_types[i] = args[i].type;
    status = infix_reverse_create_closure_manual(
        out_context, ret_type, arg_types, num_args, num_fixed, user_callback_fn, user_data);
    infix_arena_destroy(arena);
    return status;
}
// ============================================================================
//                       UNITY BUILD INCLUDES
// This section includes the actual ABI implementations at the end of the file.
// Because `trampoline.c` is the central translation unit, including the
// correct ABI-specific .c file here makes its functions (`g_win_x64_spec`, etc.)
// available without needing to add platform-specific logic to the build system.
// The `infix_config.h` header ensures only one of these #if blocks is active.
// ============================================================================
#if defined(INFIX_ABI_WINDOWS_X64)
#include "../arch/x64/abi_win_x64.c"
#include "../arch/x64/abi_x64_emitters.c"
#elif defined(INFIX_ABI_SYSV_X64)
#include "../arch/x64/abi_sysv_x64.c"
#include "../arch/x64/abi_x64_emitters.c"
#elif defined(INFIX_ABI_AAPCS64)
#include "../arch/aarch64/abi_arm64.c"
#include "../arch/aarch64/abi_arm64_emitters.c"
#else
#error "No supported ABI was selected for the unity build in trampoline.c."
#endif
