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
 * @file abi_sysv_x64.c
 * @brief Implements the FFI logic for the System V AMD64 ABI.
 * @ingroup internal_abi_x64
 *
 * @internal
 * This file provides the concrete implementation of the ABI spec for the System V
 * x86-64 ABI, the standard calling convention for Linux, macOS, BSD, and other
 * UNIX-like operating systems on this architecture.
 *
 * Key features of the System V ABI implemented here:
 *
 * - **Register Usage:**
 *   - GPRs for integers/pointers: RDI, RSI, RDX, RCX, R8, R9.
 *   - XMMs for floats/doubles: XMM0-XMM7.
 *
 * - **Aggregate Classification:** Structs up to 16 bytes are recursively classified
 *   into one or two "eightbytes" (64-bit chunks). Based on the classes of these
 *   eightbytes (INTEGER, SSE, MEMORY), the aggregate can be passed in up to two
 *   registers (GPRs and/or XMMs) or on the stack.
 *
 * - **Return Values:**
 *   - Small aggregates (<= 16 bytes) are returned in RAX/RDX and/or XMM0/XMM1.
 *   - Larger aggregates (> 16 bytes) are returned via a hidden pointer in RDI.
 *   - `long double` is a special case and is returned on the x87 FPU stack `st(0)`.
 *
 * - **Variadic Functions:** Before calling a variadic function, the `AL` register
 *   must be set to the number of XMM registers used for arguments.
 * @endinternal
 */
#include "arch/x64/abi_x64_common.h"
#include "arch/x64/abi_x64_emitters.h"
#include "common/infix_internals.h"
#include "common/utility.h"
#include <stdbool.h>
#include <stdlib.h>

/** An array of GPRs used for passing the first 6 integer/pointer arguments, in order. */
static const x64_gpr GPR_ARGS[] = {RDI_REG, RSI_REG, RDX_REG, RCX_REG, R8_REG, R9_REG};
/** An array of XMM registers used for passing the first 8 floating-point arguments, in order. */
static const x64_xmm XMM_ARGS[] = {XMM0_REG, XMM1_REG, XMM2_REG, XMM3_REG, XMM4_REG, XMM5_REG, XMM6_REG, XMM7_REG};
/** The number of GPRs available for argument passing. */
#define NUM_GPR_ARGS 6
/** The number of XMM registers available for argument passing. */
#define NUM_XMM_ARGS 8
/** A safe recursion limit for the aggregate classification algorithm to prevent stack overflow. */
#define MAX_CLASSIFY_DEPTH 32
/** A safe limit on the number of fields to classify to prevent DoS from exponential complexity. */
#define MAX_AGGREGATE_FIELDS_TO_CLASSIFY 32
/**
 * @internal
 * @brief The System V classification for an "eightbyte" (a 64-bit chunk of a type).
 */
typedef enum {
    NO_CLASS,  ///< This eightbyte has not been classified yet. It's the initial state.
    INTEGER,   ///< This eightbyte should be passed in a general-purpose register (GPR).
    SSE,       ///< This eightbyte should be passed in an SSE register (XMM).
    MEMORY     ///< The argument is too complex or large and must be passed on the stack.
} arg_class_t;

/** The v-table of System V x64 functions for generating forward trampolines. */
static infix_status prepare_forward_call_frame_sysv_x64(infix_arena_t * arena,
                                                        infix_call_frame_layout ** out_layout,
                                                        infix_type * ret_type,
                                                        infix_type ** arg_types,
                                                        size_t num_args,
                                                        size_t num_fixed_args,
                                                        void * target_fn);
static infix_status generate_forward_prologue_sysv_x64(code_buffer * buf, infix_call_frame_layout * layout);
static infix_status generate_forward_argument_moves_sysv_x64(code_buffer * buf,
                                                             infix_call_frame_layout * layout,
                                                             infix_type ** arg_types,
                                                             size_t num_args,
                                                             size_t num_fixed_args);
static infix_status generate_forward_call_instruction_sysv_x64(code_buffer *, infix_call_frame_layout *);
static infix_status generate_forward_epilogue_sysv_x64(code_buffer * buf,
                                                       infix_call_frame_layout * layout,
                                                       infix_type * ret_type);
const infix_forward_abi_spec g_sysv_x64_forward_spec = {
    .prepare_forward_call_frame = prepare_forward_call_frame_sysv_x64,
    .generate_forward_prologue = generate_forward_prologue_sysv_x64,
    .generate_forward_argument_moves = generate_forward_argument_moves_sysv_x64,
    .generate_forward_call_instruction = generate_forward_call_instruction_sysv_x64,
    .generate_forward_epilogue = generate_forward_epilogue_sysv_x64};

/** The v-table of System V x64 functions for generating reverse trampolines. */
static infix_status prepare_reverse_call_frame_sysv_x64(infix_arena_t * arena,
                                                        infix_reverse_call_frame_layout ** out_layout,
                                                        infix_reverse_t * context);
static infix_status generate_reverse_prologue_sysv_x64(code_buffer * buf, infix_reverse_call_frame_layout * layout);
static infix_status generate_reverse_argument_marshalling_sysv_x64(code_buffer * buf,
                                                                   infix_reverse_call_frame_layout * layout,
                                                                   infix_reverse_t * context);
static infix_status generate_reverse_dispatcher_call_sysv_x64(code_buffer * buf,
                                                              infix_reverse_call_frame_layout * layout,
                                                              infix_reverse_t * context);
static infix_status generate_reverse_epilogue_sysv_x64(code_buffer * buf,
                                                       infix_reverse_call_frame_layout * layout,
                                                       infix_reverse_t * context);
const infix_reverse_abi_spec g_sysv_x64_reverse_spec = {
    .prepare_reverse_call_frame = prepare_reverse_call_frame_sysv_x64,
    .generate_reverse_prologue = generate_reverse_prologue_sysv_x64,
    .generate_reverse_argument_marshalling = generate_reverse_argument_marshalling_sysv_x64,
    .generate_reverse_dispatcher_call = generate_reverse_dispatcher_call_sysv_x64,
    .generate_reverse_epilogue = generate_reverse_epilogue_sysv_x64};

/** The v-table for the new Direct Marshalling ABI. */
static infix_status prepare_direct_forward_call_frame_sysv_x64(infix_arena_t * arena,
                                                               infix_direct_call_frame_layout ** out_layout,
                                                               infix_type * ret_type,
                                                               infix_type ** arg_types,
                                                               size_t num_args,
                                                               infix_direct_arg_handler_t * handlers,
                                                               void * target_fn);
static infix_status generate_direct_forward_prologue_sysv_x64(code_buffer * buf,
                                                              infix_direct_call_frame_layout * layout);
static infix_status generate_direct_forward_argument_moves_sysv_x64(code_buffer * buf,
                                                                    infix_direct_call_frame_layout * layout);
static infix_status generate_direct_forward_call_instruction_sysv_x64(code_buffer * buf,
                                                                      infix_direct_call_frame_layout * layout);
static infix_status generate_direct_forward_epilogue_sysv_x64(code_buffer * buf,
                                                              infix_direct_call_frame_layout * layout,
                                                              infix_type * ret_type);
const infix_direct_forward_abi_spec g_sysv_x64_direct_forward_spec = {
    .prepare_direct_forward_call_frame = prepare_direct_forward_call_frame_sysv_x64,
    .generate_direct_forward_prologue = generate_direct_forward_prologue_sysv_x64,
    .generate_direct_forward_argument_moves = generate_direct_forward_argument_moves_sysv_x64,
    .generate_direct_forward_call_instruction = generate_direct_forward_call_instruction_sysv_x64,
    .generate_direct_forward_epilogue = generate_direct_forward_epilogue_sysv_x64};

/**
 * @internal
 * @brief Recursively classifies the eightbytes of an aggregate type.
 * @details This is the core of the complex System V classification algorithm. It traverses
 * the fields of a struct/array, examining each 8-byte chunk ("eightbyte") and assigning it a
 * class (INTEGER, SSE, MEMORY). The classification is "merged" according to ABI rules
 * (e.g., if an eightbyte contains both INTEGER and SSE parts, it becomes INTEGER).
 *
 * @param type The type of the current member/element being examined.
 * @param offset The byte offset of this member from the start of the aggregate.
 * @param[in,out] classes An array of two `arg_class_t` that is updated during classification.
 * @param depth The current recursion depth (to prevent stack overflow on malicious input).
 * @param field_count A counter to prevent DoS from excessively complex types.
 * @return `true` if a condition forcing MEMORY classification is found, `false` otherwise.
 */
static bool classify_recursive(
    const infix_type * type, size_t offset, arg_class_t classes[2], int depth, size_t * field_count) {
    // A recursive call can be made with a NULL type (e.g., from a malformed array from fuzzer).
    if (type == nullptr)
        return false;  // Terminate recusion path.
    // Abort classification if the type is excessively complex or too deep. Give up and pass in memory.
    if (*field_count > MAX_AGGREGATE_FIELDS_TO_CLASSIFY || depth > MAX_CLASSIFY_DEPTH) {
        classes[0] = MEMORY;
        return true;
    }
    // The ABI requires natural alignment. If a fuzzer creates a type with an unaligned
    // member, it must be passed in memory. A zero alignment would cause a crash.
    if (type->alignment != 0 && offset % type->alignment != 0) {
        classes[0] = MEMORY;
        return true;
    }
    // If a struct is packed, its layout is explicit and should not be inferred
    // by recursive classification. Treat it as an opaque block of memory.
    // For classification purposes, this is equivalent to an integer array.
    if (type->category == INFIX_TYPE_PRIMITIVE) {
        (*field_count)++;
        // `long double` is a special case. It is passed in memory on the stack, not x87 registers.
        if (is_long_double(type)) {
            classes[0] = MEMORY;
            return true;
        }
        // Consider all eightbytes that the primitive occupies, not just the starting offset.
        size_t start_offset = offset;
        // Check for overflow before calculating end_offset
        if (type->size == 0)
            return false;
        if (start_offset > SIZE_MAX - (type->size - 1)) {
            classes[0] = MEMORY;
            return true;
        }
        size_t end_offset = start_offset + type->size - 1;
        size_t start_eightbyte = start_offset / 8;
        size_t end_eightbyte = end_offset / 8;
        arg_class_t new_class = (is_float(type) || is_double(type)) ? SSE : INTEGER;
        for (size_t index = start_eightbyte; index <= end_eightbyte && index < 2; ++index) {
            // Merge the new class with the existing class for this eightbyte.
            // The rule is: if an eightbyte contains both SSE and INTEGER parts, it is classified as INTEGER.
            if (classes[index] != new_class)
                classes[index] = (classes[index] == NO_CLASS) ? new_class : INTEGER;
        }
        return false;
    }
    if (type->category == INFIX_TYPE_POINTER) {
        (*field_count)++;
        size_t index = offset / 8;
        if (index < 2 && classes[index] != INTEGER)
            classes[index] = INTEGER;  // Pointers are always INTEGER class. Merge with existing class.
        return false;
    }
    if (type->category == INFIX_TYPE_ARRAY) {
        if (type->meta.array_info.element_type == nullptr)
            return false;
        // If the array elements have no size, iterating over them is pointless
        // and can cause a timeout if num_elements is large, as the offset never advances.
        // We only need to classify the element type once at the starting offset.
        if (type->meta.array_info.element_type->size == 0) {
            if (type->meta.array_info.num_elements > 0)
                // Classify the zero-sized element just once.
                return classify_recursive(type->meta.array_info.element_type, offset, classes, depth + 1, field_count);
            return false;  // An empty array of zero-sized structs has no effect on classification.
        }
        for (size_t i = 0; i < type->meta.array_info.num_elements; ++i) {
            // Check count *before* each recursive call inside the loop.
            if (*field_count > MAX_AGGREGATE_FIELDS_TO_CLASSIFY) {
                classes[0] = MEMORY;
                return true;
            }
            size_t element_offset = offset + i * type->meta.array_info.element_type->size;
            // If we are already past the 16-byte boundary relevant for
            // register passing, there is no need to classify further. This prunes
            // the recursion tree for large arrays.
            if (element_offset >= 16)
                break;
            if (classify_recursive(type->meta.array_info.element_type, element_offset, classes, depth + 1, field_count))
                return true;  // Propagate unaligned discovery up the call stack
        }
        return false;
    }
    if (type->category == INFIX_TYPE_COMPLEX) {
        infix_type * base = type->meta.complex_info.base_type;
        // A zero-sized base type would cause infinite recursion.
        // Treat this as a malformed type and stop classification.
        if (base == nullptr || base->size == 0)
            return false;
        // A complex number is just like a struct { base_type real; base_type imag; }
        // So we classify the first element at offset 0.
        if (classify_recursive(base, offset, classes, depth + 1, field_count))
            return true;  // Propagate unaligned discovery
        // And the second element at offset + size of the base.
        if (classify_recursive(base, offset + base->size, classes, depth + 1, field_count))
            return true;  // Propagate unaligned discovery
        return false;
    }
    if (type->category == INFIX_TYPE_STRUCT || type->category == INFIX_TYPE_UNION) {
        // A generated type can have num_members > 0 but a NULL members pointer.
        // This is invalid and must be passed in memory.
        if (type->meta.aggregate_info.members == nullptr) {
            classes[0] = MEMORY;
            return true;
        }
        // Recursively classify each member of the struct/union.
        for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
            // Check count *before* each recursive call inside the loop.
            if (*field_count > MAX_AGGREGATE_FIELDS_TO_CLASSIFY) {
                classes[0] = MEMORY;
                return true;
            }
            infix_struct_member * member = &type->meta.aggregate_info.members[i];
            // A generated type can have a NULL member type.
            // This is invalid, and the aggregate must be passed in memory.
            if (member->type == nullptr) {
                classes[0] = MEMORY;
                return true;
            }
            size_t member_offset = offset + member->offset;
            // If this member starts at or after the 16-byte boundary,
            // it cannot influence register classification, so we can skip it.
            if (member_offset >= 16)
                continue;
            if (classify_recursive(member->type, member_offset, classes, depth + 1, field_count))
                return true;  // Propagate unaligned discovery
        }
        return false;
    }
    return false;
}
/**
 * @internal
 * @brief Classifies an aggregate type for argument passing according to the System V ABI.
 * @details This function implements the complete classification algorithm. An aggregate
 *          is broken down into up to two "eightbytes". Each is classified as INTEGER,
 *          SSE, or MEMORY. If the size is > 16 bytes or classification fails, it's MEMORY.
 *
 * @param type The aggregate type to classify.
 * @param[out] classes An array of two `arg_class_t` to be filled.
 * @param[out] num_classes The number of valid classes (1 or 2).
 */
static void classify_aggregate_sysv(const infix_type * type, arg_class_t classes[2], size_t * num_classes) {
    // Initialize to a clean state.
    classes[0] = NO_CLASS;
    classes[1] = NO_CLASS;
    *num_classes = 0;
    // If the size is greater than 16 bytes, it's passed in memory.
    if (type->size > 16) {
        classes[0] = MEMORY;
        *num_classes = 1;
        return;
    }
    // Run the recursive classification. If it returns true, an unaligned
    // field was found, and the class is already set to MEMORY. We can stop.
    size_t field_count = 0;                                       // Initialize the counter for this aggregate.
    if (classify_recursive(type, 0, classes, 0, &field_count)) {  // Pass counter to initial call
        *num_classes = 1;
        return;
    }
    // Post-processing for alignment padding.
    if (type->size > 0 && classes[0] == NO_CLASS)
        classes[0] = INTEGER;
    if (type->size > 8 && classes[1] == NO_CLASS)
        classes[1] = INTEGER;
    // Count the number of valid, classified eightbytes.
    if (classes[0] != NO_CLASS)
        (*num_classes)++;
    if (classes[1] != NO_CLASS)
        (*num_classes)++;
}
/**
 * @internal
 * @brief Stage 1 (Forward): Analyzes a signature and creates a call frame layout for System V.
 * @details This function iterates through a function's arguments, classifying each one
 *          to determine its location (GPR, XMM, or stack) according to the SysV ABI rules.
 * @param arena The temporary arena for allocations.
 * @param out_layout Receives the created layout blueprint.
 * @param ret_type The function's return type.
 * @param arg_types Array of argument types.
 * @param num_args Total number of arguments.
 * @param num_fixed_args Number of non-variadic arguments.
 * @param target_fn The target function address.
 * @return `INFIX_SUCCESS` on success, or an error code on failure.
 */
static infix_status prepare_forward_call_frame_sysv_x64(infix_arena_t * arena,
                                                        infix_call_frame_layout ** out_layout,
                                                        infix_type * ret_type,
                                                        infix_type ** arg_types,
                                                        size_t num_args,
                                                        size_t num_fixed_args,
                                                        void * target_fn) {
    if (out_layout == nullptr)
        return INFIX_ERROR_INVALID_ARGUMENT;
    // Allocate the layout struct that will hold our results.
    infix_call_frame_layout * layout =
        infix_arena_calloc(arena, 1, sizeof(infix_call_frame_layout), _Alignof(infix_call_frame_layout));
    if (layout == nullptr) {
        *out_layout = nullptr;
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    layout->is_variadic = num_args > num_fixed_args;
    layout->target_fn = target_fn;
    layout->arg_locations =
        infix_arena_calloc(arena, num_args, sizeof(infix_arg_location), _Alignof(infix_arg_location));
    if (layout->arg_locations == nullptr && num_args > 0) {
        *out_layout = nullptr;
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    // gpr_count and xmm_count track the next available GPR and XMM argument registers.
    // current_stack_offset tracks the next available stack slot for arguments.
    size_t gpr_count = 0, xmm_count = 0, current_stack_offset = 0;
    // Determine if the return value requires a hidden pointer argument passed in RDI.
    bool ret_is_aggregate = (ret_type->category == INFIX_TYPE_STRUCT || ret_type->category == INFIX_TYPE_UNION ||
                             ret_type->category == INFIX_TYPE_ARRAY || ret_type->category == INFIX_TYPE_COMPLEX);
    // Rule 1: Aggregates larger than 16 bytes are always returned via hidden pointer.
    // Exception: 256/512-bit vectors are returned in YMM0/ZMM0.
    layout->return_value_in_memory =
        (ret_is_aggregate && ret_type->category != INFIX_TYPE_VECTOR && ret_type->size > 16);
    // Rule 2: Small aggregates (<= 16 bytes) must also be returned via hidden pointer
    // if their classification is MEMORY. This is critical for types like packed structs
    // with unaligned members.
    if (ret_is_aggregate && !layout->return_value_in_memory) {
        arg_class_t ret_classes[2];
        size_t num_ret_classes;
        classify_aggregate_sysv(ret_type, ret_classes, &num_ret_classes);
        if (num_ret_classes > 0 && ret_classes[0] == MEMORY)
            layout->return_value_in_memory = true;
    }
    // Exception: `long double` is a special case and is always returned on the x87
    // FPU stack, never via a hidden pointer.
    if (is_long_double(ret_type))
        layout->return_value_in_memory = false;
    // If a hidden pointer is used, it consumes the first GPR (RDI).
    if (layout->return_value_in_memory)
        gpr_count++;
    layout->num_stack_args = 0;
    // Main Argument Classification Loop
    for (size_t i = 0; i < num_args; ++i) {
        infix_type * type = arg_types[i];
        // Security: Reject excessively large types before they reach the code generator.
        if (type->size > INFIX_MAX_ARG_SIZE) {
            *out_layout = nullptr;
            return INFIX_ERROR_LAYOUT_FAILED;
        }
        // An array passed as a function parameter decays to a pointer.
        // We must treat it as a pointer (INTEGER class) for classification,
        // bypassing the aggregate classification logic which would incorrectly
        // treat it as a by-value struct.
        if (type->category == INFIX_TYPE_ARRAY) {
            if (gpr_count < NUM_GPR_ARGS) {
                layout->arg_locations[i].type = ARG_LOCATION_GPR;
                layout->arg_locations[i].reg_index = gpr_count++;
            }
            else {
                layout->arg_locations[i].type = ARG_LOCATION_STACK;
                layout->arg_locations[i].stack_offset = current_stack_offset;
                current_stack_offset += 8;  // Pointers are 8 bytes on the stack
                layout->num_stack_args++;
            }
            continue;  // Argument classified, skip the rest of the loop.
        }
        // Classify the argument type
        // Special case: `long double` is always passed on the stack.
        if (is_long_double(type)) {
            layout->arg_locations[i].type = ARG_LOCATION_STACK;
            size_t align = type->alignment;

            if (align < 8)
                align = 8;  // Stack slots are minimum 8 bytes

            // Align current offset up to the required alignment (e.g. 16)
            current_stack_offset = (current_stack_offset + (align - 1)) & ~(align - 1);
            layout->arg_locations[i].stack_offset = current_stack_offset;
            current_stack_offset += (type->size + 7) & ~7;  // Advance by size, 8-byte aligned
            layout->num_stack_args++;
            continue;  // Go to next argument
        }
        bool is_aggregate = type->category == INFIX_TYPE_STRUCT || type->category == INFIX_TYPE_UNION ||
            type->category == INFIX_TYPE_ARRAY || type->category == INFIX_TYPE_COMPLEX;
        arg_class_t classes[2] = {NO_CLASS, NO_CLASS};
        size_t num_classes = 0;
        bool placed_in_register = false;
        if (is_aggregate)
            // Complex types need the full classification algorithm.
            classify_aggregate_sysv(type, classes, &num_classes);
        else {
            // Simple primitive and vector types are classified directly.
            if (is_float(type) || is_double(type) || type->category == INFIX_TYPE_VECTOR) {
                classes[0] = SSE;
                num_classes = 1;
                // Special classification for large AVX vectors (YMM/ZMM).
                // They are passed in a single register, which we model as a single SSE class.
                // The size check distinguishes them from 128-bit vectors.
                if (type->category == INFIX_TYPE_VECTOR && (type->size == 32 || type->size == 64))
                    num_classes = 1;  // Treat as a single unit for classification
            }
            else {
                classes[0] = INTEGER;
                num_classes = 1;
                // Primitives > 8 bytes (like __int128) are treated as two INTEGER parts.
                if (type->size > 8) {
                    classes[1] = INTEGER;
                    num_classes = 2;
                }
            }
        }
        // If classification resulted in MEMORY, it must go on the stack.
        placed_in_register = false;
        if (num_classes > 0 && classes[0] != MEMORY) {
            if (num_classes == 1) {
                // Case 1: Argument fits in a single register.
                // Check for available GPR or XMM registers individually. This is the core of the bug fix.
                if (classes[0] == INTEGER && gpr_count < NUM_GPR_ARGS) {
                    layout->arg_locations[i].type = ARG_LOCATION_GPR;
                    layout->arg_locations[i].reg_index = gpr_count++;
                    placed_in_register = true;
                }
                else if (classes[0] == SSE && type->category == INFIX_TYPE_VECTOR &&
                         (type->size == 32 || type->size == 64) && xmm_count < NUM_XMM_ARGS) {
                    // AVX/256-bit or AVX-512/512-bit vector case
                    layout->arg_locations[i].type = ARG_LOCATION_XMM;  // Re-use XMM type
                    layout->arg_locations[i].reg_index = xmm_count++;
                    placed_in_register = true;
                }
                else if (classes[0] == SSE && xmm_count < NUM_XMM_ARGS) {
                    layout->arg_locations[i].type = ARG_LOCATION_XMM;
                    layout->arg_locations[i].reg_index = xmm_count++;
                    placed_in_register = true;
                }
            }
            else {  // num_classes == 2
                // Argument is passed in two registers.
                // Here, a combined check is correct, as we must have room for both parts.
                size_t gpr_needed = (classes[0] == INTEGER) + (classes[1] == INTEGER);
                size_t xmm_needed = (classes[0] == SSE) + (classes[1] == SSE);
                if (gpr_count + gpr_needed <= NUM_GPR_ARGS && xmm_count + xmm_needed <= NUM_XMM_ARGS) {
                    if (classes[0] == INTEGER && classes[1] == INTEGER) {
                        layout->arg_locations[i].type = ARG_LOCATION_GPR_PAIR;
                        layout->arg_locations[i].reg_index = gpr_count;
                        layout->arg_locations[i].reg_index2 = gpr_count + 1;
                    }
                    else if (classes[0] == SSE && classes[1] == SSE) {
                        layout->arg_locations[i].type = ARG_LOCATION_SSE_SSE_PAIR;
                        layout->arg_locations[i].reg_index = xmm_count;
                        layout->arg_locations[i].reg_index2 = xmm_count + 1;
                    }
                    else {  // Mixed GPR and SSE
                        if (classes[0] == INTEGER) {
                            layout->arg_locations[i].type = ARG_LOCATION_INTEGER_SSE_PAIR;
                            layout->arg_locations[i].reg_index = gpr_count;
                            layout->arg_locations[i].reg_index2 = xmm_count;
                        }
                        else {
                            layout->arg_locations[i].type = ARG_LOCATION_SSE_INTEGER_PAIR;
                            layout->arg_locations[i].reg_index = xmm_count;
                            layout->arg_locations[i].reg_index2 = gpr_count;
                        }
                    }
                    gpr_count += gpr_needed;
                    xmm_count += xmm_needed;
                    placed_in_register = true;
                }
            }
        }
        // Fallback to stack
        if (!placed_in_register) {
            layout->arg_locations[i].type = ARG_LOCATION_STACK;
            // Align current offset to the argument's natural alignment requirements.
            // SysV requires 16-byte alignment for long double, __int128, and __m128 on the stack.
            size_t align = type->alignment;
            if (align < 8)
                align = 8;  // Stack slots are at least 8 bytes
            current_stack_offset = (current_stack_offset + (align - 1)) & ~(align - 1);  // Align up
            layout->arg_locations[i].stack_offset = current_stack_offset;
            current_stack_offset += (type->size + 7) & ~7;  // Align to 8 bytes.
            layout->num_stack_args++;
        }
    }
    // Finalize the layout properties.
    layout->num_gpr_args = gpr_count;
    layout->num_xmm_args = xmm_count;
    // The total stack space for arguments must be 16-byte aligned before the call.
    layout->total_stack_alloc = (current_stack_offset + 15) & ~15;
    // Safety check against excessive stack allocation.
    if (layout->total_stack_alloc > INFIX_MAX_STACK_ALLOC) {
        *out_layout = nullptr;
        return INFIX_ERROR_LAYOUT_FAILED;
    }
    *out_layout = layout;
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 2 (Forward): Generates the function prologue for the System V trampoline.
 * @details Sets up a standard stack frame, saves registers for the trampoline's context,
 *          and allocates stack space for arguments.
 * @param buf The code buffer.
 * @param layout The call frame layout.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_forward_prologue_sysv_x64(code_buffer * buf, infix_call_frame_layout * layout) {
    // Standard Function Prologue
    emit_push_reg(buf, RBP_REG);              // push rbp
    emit_mov_reg_reg(buf, RBP_REG, RSP_REG);  // mov rbp, rsp
    // Save Callee-Saved Registers
    // We will use these registers to store our context (target_fn, ret_ptr, args_ptr)
    // across the native function call, so we must save their original values first.
    emit_push_reg(buf, R12_REG);  // push r12
    emit_push_reg(buf, R13_REG);  // push r13
    emit_push_reg(buf, R14_REG);  // push r14
    emit_push_reg(buf, R15_REG);  // push r15
    // Move Trampoline Arguments to Persistent Registers
    if (layout->target_fn == nullptr) {  // Unbound trampoline
        // The trampoline is called with (target_fn, ret_ptr, args_ptr) in RDI, RSI, RDX.
        // We move these into our saved callee-saved registers to protect them.
        emit_mov_reg_reg(buf, R12_REG, RDI_REG);  // r12 = target_fn
        emit_mov_reg_reg(buf, R13_REG, RSI_REG);  // r13 = ret_ptr
        emit_mov_reg_reg(buf, R14_REG, RDX_REG);  // r14 = args_ptr
    }
    else {  // Bound trampoline
        // The trampoline is called with (ret_ptr, args_ptr) in RDI, RSI.
        emit_mov_reg_reg(buf, R13_REG, RDI_REG);  // r13 = ret_ptr
        emit_mov_reg_reg(buf, R14_REG, RSI_REG);  // r14 = args_ptr
    }
    // Allocate Stack Space
    // If any arguments are passed on the stack, allocate space for them.
    // The ABI requires this space to be 16-byte aligned.
    if (layout->total_stack_alloc > 0)
        emit_sub_reg_imm32(buf, RSP_REG, layout->total_stack_alloc);
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 3 (Forward): Generates code to move arguments from the `void**` array
 *          into their correct native locations (registers or stack).
 * @param buf The code buffer.
 * @param layout The layout blueprint.
 * @param arg_types The array of argument types.
 * @param num_args Total number of arguments.
 * @param num_fixed_args Number of fixed arguments.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_forward_argument_moves_sysv_x64(code_buffer * buf,
                                                             infix_call_frame_layout * layout,
                                                             infix_type ** arg_types,
                                                             size_t num_args,
                                                             c23_maybe_unused size_t num_fixed_args) {
    // If returning a large struct, the hidden pointer (stored in r13) must be moved to RDI.
    if (layout->return_value_in_memory)
        emit_mov_reg_reg(buf, GPR_ARGS[0], R13_REG);  // mov rdi, r13
    // Marshall Register Arguments
    // Loop over all arguments that are passed in registers.
    for (size_t i = 0; i < num_args; ++i) {
        infix_arg_location * loc = &layout->arg_locations[i];
        if (loc->type == ARG_LOCATION_STACK)
            continue;  // Handle stack arguments in a separate pass.
        // Load the pointer to the argument's data into a scratch register (r15).
        // r14 holds the base of the `void** args_array`.
        // r15 = args_array[i]
        emit_mov_reg_mem(buf, R15_REG, R14_REG, i * sizeof(void *));
        switch (loc->type) {
        case ARG_LOCATION_GPR:
            {
                infix_type * current_type = arg_types[i];
                // An array parameter decays to a pointer. The `args` array for it
                // contains a pointer TO the array data. We must pass this pointer itself,
                // not the data it points to. R15 already holds this pointer.
                if (current_type->category == INFIX_TYPE_ARRAY) {
                    emit_mov_reg_reg(buf, GPR_ARGS[loc->reg_index], R15_REG);
                    break;  // This case is now handled.
                }
                bool is_signed = current_type->category == INFIX_TYPE_PRIMITIVE &&
                    (current_type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
                     current_type->meta.primitive_id == INFIX_PRIMITIVE_SINT16 ||
                     current_type->meta.primitive_id == INFIX_PRIMITIVE_SINT32);
                if (is_signed) {
                    if (current_type->size == 1)
                        emit_movsx_reg64_mem8(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                    else if (current_type->size == 2)
                        emit_movsx_reg64_mem16(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                    else
                        emit_movsxd_reg_mem(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                }
                else {
                    if (current_type->size == 1)
                        emit_movzx_reg64_mem8(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                    else if (current_type->size == 2)
                        emit_movzx_reg64_mem16(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                    else if (current_type->size == 4)
                        emit_mov_reg32_mem(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                    else
                        emit_mov_reg_mem(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                }
                break;
            }
        case ARG_LOCATION_XMM:
            if (is_float(arg_types[i]))
                // movss xmm_reg, [r15] (Move Scalar Single-Precision)
                emit_movss_xmm_mem(buf, XMM_ARGS[loc->reg_index], R15_REG, 0);
            else if (arg_types[i]->category == INFIX_TYPE_VECTOR && arg_types[i]->size == 32)
                // AVX case: Use the new 256-bit move emitter
                emit_vmovupd_ymm_mem(buf, XMM_ARGS[loc->reg_index], R15_REG, 0);
            else if (arg_types[i]->category == INFIX_TYPE_VECTOR && arg_types[i]->size == 64)
                // AVX-512 case: Use the new 512-bit move emitter
                emit_vmovupd_zmm_mem(buf, XMM_ARGS[loc->reg_index], R15_REG, 0);
            else if (arg_types[i]->category == INFIX_TYPE_VECTOR)
                emit_movups_xmm_mem(buf, XMM_ARGS[loc->reg_index], R15_REG, 0);
            else
                // movsd xmm_reg, [r15] (Move Scalar Double-Precision)
                emit_movsd_xmm_mem(buf, XMM_ARGS[loc->reg_index], R15_REG, 0);
            break;
        case ARG_LOCATION_GPR_PAIR:
            emit_mov_reg_mem(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);   // mov gpr, [r15]
            emit_mov_reg_mem(buf, GPR_ARGS[loc->reg_index2], R15_REG, 8);  // movsd xmm, [r15 + 8]
            break;
        case ARG_LOCATION_INTEGER_SSE_PAIR:
            emit_mov_reg_mem(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);     // mov gpr, [r15]
            emit_movsd_xmm_mem(buf, XMM_ARGS[loc->reg_index2], R15_REG, 8);  // movsd xmm2, [r15 + 8]
            break;
        case ARG_LOCATION_SSE_INTEGER_PAIR:
            emit_movsd_xmm_mem(buf, XMM_ARGS[loc->reg_index], R15_REG, 0);  // movsd xmm, [r15]
            emit_mov_reg_mem(buf, GPR_ARGS[loc->reg_index2], R15_REG, 8);   // mov gpr, [r15 + 8]
            break;
        case ARG_LOCATION_SSE_SSE_PAIR:
            emit_movsd_xmm_mem(buf, XMM_ARGS[loc->reg_index], R15_REG, 0);   // movsd xmm1, [r15]
            emit_movsd_xmm_mem(buf, XMM_ARGS[loc->reg_index2], R15_REG, 8);  // movsd xmm2, [r15 + 8]
            break;
        default:
            // Should be unreachable if layout is correct.
            break;
        }
    }
    // Marshall Stack Arguments
    if (layout->num_stack_args > 0) {
        for (size_t i = 0; i < num_args; ++i) {
            if (layout->arg_locations[i].type != ARG_LOCATION_STACK)
                continue;
            // Load pointer to argument data into r15.
            emit_mov_reg_mem(buf, R15_REG, R14_REG, i * sizeof(void *));  // r15 = args_array[i]
            size_t size = arg_types[i]->size;
            // Copy the argument data from the user-provided buffer to the stack, 8 bytes at a time.
            for (size_t offset = 0; offset < size; offset += 8) {
                // mov rax, [r15 + offset] (load 8 bytes into scratch register)
                emit_mov_reg_mem(buf, RAX_REG, R15_REG, offset);
                // mov [rsp + stack_offset], rax (store 8 bytes onto the stack)
                emit_mov_mem_reg(buf, RSP_REG, layout->arg_locations[i].stack_offset + offset, RAX_REG);
            }
        }
    }
    // Handle Variadic Calls
    // The ABI requires that AL contains the number of XMM registers used for arguments.
    if (layout->is_variadic)
        // mov al, num_xmm_args (or mov eax, num_xmm_args)
        emit_mov_reg_imm32(buf, RAX_REG, (int32_t)layout->num_xmm_args);
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 3.5 (Forward): Generates the null-check and call instruction.
 * @param buf The code buffer.
 * @param layout The call frame layout.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_forward_call_instruction_sysv_x64(code_buffer * buf,
                                                               c23_maybe_unused infix_call_frame_layout * layout) {
    // For a bound trampoline, load the hardcoded address into R12.
    // For an unbound trampoline, R12 was already loaded from RDI in the prologue.
    if (layout->target_fn)
        emit_mov_reg_imm64(buf, R12_REG, (uint64_t)layout->target_fn);
    // On SysV x64, the target function pointer is stored in R12.
    emit_test_reg_reg(buf, R12_REG, R12_REG);  // test r12, r12 ; check if function pointer is null
    emit_jnz_short(buf, 2);                    // jnz +2       ; if not null, skip the crash instruction
    emit_ud2(buf);                             // ud2          ; crash safely if null
    emit_call_reg(buf, R12_REG);               // call r12     ; call the function
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 4 (Forward): Generates the function epilogue for the System V trampoline.
 * @details Emits code to handle the function's return value (from RAX/RDX, XMM0/XMM1, or
 *          the x87 FPU stack for `long double`) and properly tear down the stack frame.
 * @param buf The code buffer.
 * @param layout The layout blueprint.
 * @param ret_type The function's return type.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_forward_epilogue_sysv_x64(code_buffer * buf,
                                                       infix_call_frame_layout * layout,
                                                       infix_type * ret_type) {
    // Handle Return Value
    // If the function returns something and it wasn't via a hidden pointer...
    if (ret_type->category != INFIX_TYPE_VOID && !layout->return_value_in_memory) {
        if (is_long_double(ret_type))
            // `long double` is returned on the x87 FPU stack (st0).
            // We store it into the user's return buffer (pointer held in r13).
            // fstpt [r13] (Store Floating Point value and Pop)
            emit_fstpt_mem(buf, R13_REG, 0);
        else {
            // For other types, we must classify the return type just like an argument.
            arg_class_t classes[2];
            size_t num_classes = 0;
            bool is_aggregate = ret_type->category == INFIX_TYPE_STRUCT || ret_type->category == INFIX_TYPE_UNION ||
                ret_type->category == INFIX_TYPE_ARRAY || ret_type->category == INFIX_TYPE_COMPLEX;
            if (is_aggregate)
                classify_aggregate_sysv(ret_type, classes, &num_classes);
            else if (is_float(ret_type) || is_double(ret_type) || (ret_type->category == INFIX_TYPE_VECTOR)) {
                classes[0] = SSE;
                num_classes = 1;
            }
            else {
                classes[0] = INTEGER;
                num_classes = 1;
                if (ret_type->size > 8) {
                    classes[1] = INTEGER;
                    num_classes = 2;
                }
            }
            if (num_classes == 1) {  // Returned in a single register
                if (classes[0] == SSE) {
                    if (is_float(ret_type))
                        emit_movss_mem_xmm(buf, R13_REG, 0, XMM0_REG);  // movss [r13], xmm0
                    else if (ret_type->category == INFIX_TYPE_VECTOR && ret_type->size == 32)
                        emit_vmovupd_mem_ymm(buf, R13_REG, 0, XMM0_REG);  // AVX case
                    else if (ret_type->category == INFIX_TYPE_VECTOR && ret_type->size == 64)
                        emit_vmovupd_mem_zmm(buf, R13_REG, 0, XMM0_REG);  // AVX-512 case
                    else if (ret_type->category == INFIX_TYPE_VECTOR)
                        emit_movups_mem_xmm(buf, R13_REG, 0, XMM0_REG);
                    else
                        emit_movsd_mem_xmm(buf, R13_REG, 0, XMM0_REG);  // movsd [r13], xmm0
                }
                else {  // INTEGER class
                    // Use a size-appropriate move to avoid writing past the end of the buffer.
                    switch (ret_type->size) {
                    case 1:
                        emit_mov_mem_reg8(buf, R13_REG, 0, RAX_REG);  // mov [r13], al
                        break;
                    case 2:
                        emit_mov_mem_reg16(buf, R13_REG, 0, RAX_REG);  // mov [r13], ax
                        break;
                    case 4:
                        emit_mov_mem_reg32(buf, R13_REG, 0, RAX_REG);  // mov [r13], eax
                        break;
                    default:
                        emit_mov_mem_reg(buf, R13_REG, 0, RAX_REG);  // mov [r13], rax
                        break;
                    }
                }
            }
            else if (num_classes == 2) {  // Returned in two registers
                if (classes[0] == INTEGER && classes[1] == INTEGER) {
                    emit_mov_mem_reg(buf, R13_REG, 0, RAX_REG);  // mov [r13], rax
                    emit_mov_mem_reg(buf, R13_REG, 8, RDX_REG);  // mov [r13 + 8], rdx
                }
                else if (classes[0] == SSE && classes[1] == SSE) {
                    if (ret_type->category == INFIX_TYPE_VECTOR && ret_type->size == 32) {
                        emit_vmovupd_mem_ymm(buf, R13_REG, 0, XMM0_REG);
                        emit_vmovupd_mem_ymm(buf, R13_REG, 32, XMM1_REG);
                    }
                    else if (ret_type->category == INFIX_TYPE_VECTOR) {
                        emit_movups_mem_xmm(buf, R13_REG, 0, XMM0_REG);
                        emit_movups_mem_xmm(buf, R13_REG, 16, XMM1_REG);
                    }
                    else {
                        emit_movsd_mem_xmm(buf, R13_REG, 0, XMM0_REG);  // movsd [r13], xmm0
                        emit_movsd_mem_xmm(buf, R13_REG, 8, XMM1_REG);  // movsd [r13 + 8], xmm1
                    }
                }
                else if (classes[0] == INTEGER && classes[1] == SSE) {
                    emit_mov_mem_reg(buf, R13_REG, 0, RAX_REG);     // mov [r13], rax
                    emit_movsd_mem_xmm(buf, R13_REG, 8, XMM0_REG);  // movsd [r13 + 8], xmm0
                }
                else {                                              // SSE, INTEGER
                    emit_movsd_mem_xmm(buf, R13_REG, 0, XMM0_REG);  // movsd [r13], xmm0
                    emit_mov_mem_reg(buf, R13_REG, 8, RAX_REG);     // mov [r13 + 8], rax
                }
            }
        }
    }
    // Deallocate Stack
    if (layout->total_stack_alloc > 0)
        emit_add_reg_imm32(buf, RSP_REG, layout->total_stack_alloc);
    // Restore Registers and Return
    emit_pop_reg(buf, R15_REG);
    emit_pop_reg(buf, R14_REG);
    emit_pop_reg(buf, R13_REG);
    emit_pop_reg(buf, R12_REG);
    emit_pop_reg(buf, RBP_REG);
    emit_ret(buf);
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 1 (Reverse): Calculates the stack layout for a reverse trampoline stub.
 * @details This function determines the total stack space needed for the stub's local variables,
 *          including the return buffer, the `void**` args_array, and the saved argument data.
 * @param arena The temporary arena for allocations.
 * @param[out] out_layout The resulting reverse call frame layout blueprint.
 * @param context The reverse trampoline context.
 * @return `INFIX_SUCCESS` on success.
 */
static infix_status prepare_reverse_call_frame_sysv_x64(infix_arena_t * arena,
                                                        infix_reverse_call_frame_layout ** out_layout,
                                                        infix_reverse_t * context) {
    infix_reverse_call_frame_layout * layout = infix_arena_calloc(
        arena, 1, sizeof(infix_reverse_call_frame_layout), _Alignof(infix_reverse_call_frame_layout));
    if (!layout)
        return INFIX_ERROR_ALLOCATION_FAILED;
    // Calculate space for each component, ensuring 16-byte alignment for safety and simplicity.
    size_t return_size = (context->return_type->size + 15) & ~15;
    size_t args_array_size = (context->num_args * sizeof(void *) + 15) & ~15;
    size_t saved_args_data_size = 0;
    for (size_t i = 0; i < context->num_args; ++i) {
        // Security: Reject excessively large types before they reach the code generator.
        if (context->arg_types[i]->size > INFIX_MAX_ARG_SIZE) {
            *out_layout = nullptr;
            return INFIX_ERROR_LAYOUT_FAILED;
        }
        saved_args_data_size += (context->arg_types[i]->size + 15) & ~15;
    }
    if (saved_args_data_size > INFIX_MAX_ARG_SIZE) {
        *out_layout = nullptr;
        return INFIX_ERROR_LAYOUT_FAILED;
    }
    size_t total_local_space = return_size + args_array_size + saved_args_data_size;
    // Safety check against allocating too much stack.
    if (total_local_space > INFIX_MAX_STACK_ALLOC) {
        *out_layout = nullptr;
        return INFIX_ERROR_LAYOUT_FAILED;
    }
    // The total allocation for the stack frame must be 16-byte aligned.
    layout->total_stack_alloc = (total_local_space + 15) & ~15;
    // Local variables are accessed via negative offsets from the frame pointer (RBP).
    // The layout is [ return_buffer | args_array | saved_args_data ]
    layout->return_buffer_offset = -(int32_t)layout->total_stack_alloc;
    layout->args_array_offset = layout->return_buffer_offset + return_size;
    layout->saved_args_offset = layout->args_array_offset + args_array_size;
    *out_layout = layout;
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 2 (Reverse): Generates the prologue for the reverse trampoline stub.
 * @details Emits standard System V function entry code, creates a stack frame,
 *          and allocates all necessary local stack space.
 * @param buf The code buffer.
 * @param layout The layout blueprint.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_reverse_prologue_sysv_x64(code_buffer * buf, infix_reverse_call_frame_layout * layout) {
    emit_push_reg(buf, RBP_REG);                                  // push rbp
    emit_mov_reg_reg(buf, RBP_REG, RSP_REG);                      // mov rbp, rsp
    emit_sub_reg_imm32(buf, RSP_REG, layout->total_stack_alloc);  // Allocate our calculated space.
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 3 (Reverse): Generates code to marshal arguments from their native
 *          locations into the generic `void**` array for the C dispatcher.
 * @param buf The code buffer.
 * @param layout The layout blueprint.
 * @param context The reverse trampoline context.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_reverse_argument_marshalling_sysv_x64(code_buffer * buf,
                                                                   infix_reverse_call_frame_layout * layout,
                                                                   infix_reverse_t * context) {
    size_t gpr_idx = 0, xmm_idx = 0, current_saved_data_offset = 0;
    // Correctly determine if the return value uses a hidden pointer by performing a full ABI classification.
    bool return_in_memory = false;
    infix_type * ret_type = context->return_type;
    bool ret_is_aggregate = (ret_type->category == INFIX_TYPE_STRUCT || ret_type->category == INFIX_TYPE_UNION ||
                             ret_type->category == INFIX_TYPE_ARRAY || ret_type->category == INFIX_TYPE_COMPLEX);
    if (ret_is_aggregate) {
        if (ret_type->size > 16)
            return_in_memory = true;
        else {
            arg_class_t ret_classes[2];
            size_t num_ret_classes;
            classify_aggregate_sysv(ret_type, ret_classes, &num_ret_classes);
            if (num_ret_classes > 0 && ret_classes[0] == MEMORY)
                return_in_memory = true;
        }
    }
    // The long double primitive is a special case that does not use the hidden pointer.
    if (is_long_double(ret_type))
        return_in_memory = false;
    // If the return value is passed by reference, save the pointer from RDI.
    if (return_in_memory)
        emit_mov_mem_reg(buf, RBP_REG, layout->return_buffer_offset, GPR_ARGS[gpr_idx++]);  // mov [rbp + offset], rdi
    // Stack arguments passed by the caller start at [rbp + 16].
    size_t stack_arg_offset = 16;
    for (size_t i = 0; i < context->num_args; i++) {
        int32_t arg_save_loc = layout->saved_args_offset + current_saved_data_offset;
        infix_type * current_type = context->arg_types[i];

        // Correct classification logic for vectors/primitives vs aggregates
        arg_class_t classes[2] = {NO_CLASS, NO_CLASS};
        size_t num_classes = 0;
        bool is_aggregate =
            (current_type->category == INFIX_TYPE_STRUCT || current_type->category == INFIX_TYPE_UNION ||
             current_type->category == INFIX_TYPE_ARRAY || current_type->category == INFIX_TYPE_COMPLEX);

        if (is_aggregate) {
            classify_aggregate_sysv(current_type, classes, &num_classes);
        }
        else if (is_float(current_type) || is_double(current_type) || current_type->category == INFIX_TYPE_VECTOR) {
            classes[0] = SSE;
            num_classes = 1;
        }
        else {
            classes[0] = INTEGER;
            num_classes = 1;
            if (current_type->size > 8) {
                classes[1] = INTEGER;
                num_classes = 2;
            }
        }

        bool is_from_stack = false;
        // Determine if the argument is in registers or on the stack.
        if (classes[0] == MEMORY)
            is_from_stack = true;
        else if (num_classes == 1) {
            if (classes[0] == SSE)
                if (xmm_idx < NUM_XMM_ARGS) {
                    // Use 128-bit move for vectors to prevent truncation
                    if (current_type->category == INFIX_TYPE_VECTOR && current_type->size == 16)
                        emit_movups_mem_xmm(buf, RBP_REG, arg_save_loc, XMM_ARGS[xmm_idx++]);
                    else if (is_float(current_type))
                        emit_movss_mem_xmm(buf, RBP_REG, arg_save_loc, XMM_ARGS[xmm_idx++]);
                    else
                        emit_movsd_mem_xmm(buf, RBP_REG, arg_save_loc, XMM_ARGS[xmm_idx++]);
                }
                else
                    is_from_stack = true;
            else if (gpr_idx < NUM_GPR_ARGS)
                emit_mov_mem_reg(buf, RBP_REG, arg_save_loc, GPR_ARGS[gpr_idx++]);
            else
                is_from_stack = true;
        }
        else if (num_classes == 2) {
            size_t gprs_needed = (classes[0] == INTEGER) + (classes[1] == INTEGER);
            size_t xmms_needed = (classes[0] == SSE) + (classes[1] == SSE);
            if (gpr_idx + gprs_needed <= NUM_GPR_ARGS && xmm_idx + xmms_needed <= NUM_XMM_ARGS) {
                if (classes[0] == SSE)
                    emit_movsd_mem_xmm(buf, RBP_REG, arg_save_loc, XMM_ARGS[xmm_idx++]);
                else
                    emit_mov_mem_reg(buf, RBP_REG, arg_save_loc, GPR_ARGS[gpr_idx++]);
                if (classes[1] == SSE)
                    emit_movsd_mem_xmm(buf, RBP_REG, arg_save_loc + 8, XMM_ARGS[xmm_idx++]);
                else
                    emit_mov_mem_reg(buf, RBP_REG, arg_save_loc + 8, GPR_ARGS[gpr_idx++]);
            }
            else
                is_from_stack = true;
        }
        if (is_from_stack) {
            for (size_t offset = 0; offset < current_type->size; offset += 8) {
                emit_mov_reg_mem(buf, RAX_REG, RBP_REG, stack_arg_offset + offset);
                emit_mov_mem_reg(buf, RBP_REG, arg_save_loc + offset, RAX_REG);
            }
            stack_arg_offset += (current_type->size + 7) & ~7;
        }
        emit_lea_reg_mem(buf, RAX_REG, RBP_REG, arg_save_loc);
        emit_mov_mem_reg(buf, RBP_REG, layout->args_array_offset + i * sizeof(void *), RAX_REG);
        current_saved_data_offset += (current_type->size + 15) & ~15;
    }
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 4 (Reverse): Generates the code to call the high-level C dispatcher function.
 * @details Emits code to load the dispatcher's arguments into the correct registers
 *          according to the System V ABI, then calls the dispatcher.
 *
 *          The C dispatcher's signature is:
 *          `void fn(infix_reverse_t* context, void* return_value_ptr, void** args_array)`
 *
 *          The generated code performs the following argument setup:
 *          1. `RDI` (Arg 1): The `context` pointer (a 64-bit immediate).
 *          2. `RSI` (Arg 2): The pointer to the return value buffer. This is either a
 *             pointer to local stack space, or the original pointer passed by the
 *             caller in RDI if the function returns a large struct by reference.
 *          3. `RDX` (Arg 3): The pointer to the `args_array` on the local stack.
 *          4. The address of the dispatcher function itself is loaded into a scratch
 *             register (`RAX`), which is then called.
 * @param buf The code buffer.
 * @param layout The layout blueprint.
 * @param context The reverse context.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_reverse_dispatcher_call_sysv_x64(code_buffer * buf,
                                                              infix_reverse_call_frame_layout * layout,
                                                              infix_reverse_t * context) {
    // Arg 1 (RDI): The infix_reverse_t context pointer.
    emit_mov_reg_imm64(buf, RDI_REG, (uint64_t)context);  // mov rdi, #context_addr
    // Arg 2 (RSI): Pointer to the return buffer.
    // Correctly determine if the hidden pointer was used for the return value.
    bool return_in_memory = false;
    infix_type * ret_type = context->return_type;
    bool ret_is_aggregate = (ret_type->category == INFIX_TYPE_STRUCT || ret_type->category == INFIX_TYPE_UNION ||
                             ret_type->category == INFIX_TYPE_ARRAY || ret_type->category == INFIX_TYPE_COMPLEX);
    if (ret_is_aggregate) {
        if (ret_type->size > 16)
            return_in_memory = true;
        else {
            arg_class_t ret_classes[2];
            size_t num_ret_classes;
            classify_aggregate_sysv(ret_type, ret_classes, &num_ret_classes);
            if (num_ret_classes > 0 && ret_classes[0] == MEMORY)
                return_in_memory = true;
        }
    }
    if (is_long_double(ret_type))
        return_in_memory = false;
    if (return_in_memory)
        // The pointer was passed to us in RDI and saved. Load it back.
        emit_mov_reg_mem(buf, RSI_REG, RBP_REG, layout->return_buffer_offset);  // mov rsi, [rbp + return_buffer_offset]
    else
        // The return buffer is a local variable. Calculate its address.
        emit_lea_reg_mem(buf, RSI_REG, RBP_REG, layout->return_buffer_offset);  // lea rsi, [rbp + return_buffer_offset]
    // Arg 3 (RDX): Pointer to the args_array we just built.
    emit_lea_reg_mem(buf, RDX_REG, RBP_REG, layout->args_array_offset);  // lea rdx, [rbp + args_array_offset]
    // Load the dispatcher's address into a scratch register and call it.
    emit_mov_reg_imm64(buf, RAX_REG, (uint64_t)context->internal_dispatcher);  // mov rax, #dispatcher_addr
    emit_call_reg(buf, RAX_REG);
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 5 (Reverse): Generates the epilogue for the reverse trampoline stub.
 * @details Retrieves the return value from the local buffer and places it into the
 *          correct return registers (RAX/RDX, XMM0/XMM1) or the x87 FPU stack. Then,
 *          it tears down the stack frame and returns to the native caller.
 * @param buf The code buffer.
 * @param layout The layout blueprint.
 * @param context The reverse context.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_reverse_epilogue_sysv_x64(code_buffer * buf,
                                                       infix_reverse_call_frame_layout * layout,
                                                       infix_reverse_t * context) {
    if (context->return_type->category != INFIX_TYPE_VOID) {
        // Correctly determine if the return value uses a hidden pointer by performing a full ABI classification.
        bool return_in_memory = false;
        infix_type * ret_type = context->return_type;
        bool ret_is_aggregate = (ret_type->category == INFIX_TYPE_STRUCT || ret_type->category == INFIX_TYPE_UNION ||
                                 ret_type->category == INFIX_TYPE_ARRAY || ret_type->category == INFIX_TYPE_COMPLEX);
        if (ret_is_aggregate) {
            if (ret_type->size > 16)
                return_in_memory = true;
            else {
                arg_class_t ret_classes[2];
                size_t num_ret_classes;
                classify_aggregate_sysv(ret_type, ret_classes, &num_ret_classes);
                if (num_ret_classes > 0 && ret_classes[0] == MEMORY)
                    return_in_memory = true;
            }
        }
        if (is_long_double(ret_type))
            return_in_memory = false;
        // Now, handle the return value based on the correct classification.
        if (is_long_double(context->return_type))
            emit_fldt_mem(buf, RBP_REG, layout->return_buffer_offset);
        else if (return_in_memory)
            // The return value was written directly via the hidden pointer.
            // The ABI requires this pointer to be returned in RAX.
            emit_mov_reg_mem(buf, RAX_REG, RBP_REG, layout->return_buffer_offset);
        else {
            // Classify the return type to determine which registers to load.
            arg_class_t classes[2];
            size_t num_classes;
            // Ensure 128-bit vectors are also classified as SSE
            if (context->return_type->category == INFIX_TYPE_VECTOR &&
                (context->return_type->size == 16 || context->return_type->size == 32 ||
                 context->return_type->size == 64)) {
                classes[0] = SSE;
                num_classes = 1;
            }
            else
                classify_aggregate_sysv(context->return_type, classes, &num_classes);
            if (num_classes >= 1) {  // First eightbyte
                if (classes[0] == SSE) {
                    if (is_float(context->return_type))
                        emit_movss_xmm_mem(buf, XMM0_REG, RBP_REG, layout->return_buffer_offset);
                    else if (context->return_type->category == INFIX_TYPE_VECTOR && context->return_type->size == 32)
                        emit_vmovupd_ymm_mem(buf, XMM0_REG, RBP_REG, layout->return_buffer_offset);
                    else if (context->return_type->category == INFIX_TYPE_VECTOR && context->return_type->size == 64)
                        emit_vmovupd_zmm_mem(buf, XMM0_REG, RBP_REG, layout->return_buffer_offset);
                    // Use 128-bit move for standard vectors
                    else if (context->return_type->category == INFIX_TYPE_VECTOR)
                        emit_movups_xmm_mem(buf, XMM0_REG, RBP_REG, layout->return_buffer_offset);
                    else
                        emit_movsd_xmm_mem(buf, XMM0_REG, RBP_REG, layout->return_buffer_offset);
                }
                else  // INTEGER
                    emit_mov_reg_mem(buf, RAX_REG, RBP_REG, layout->return_buffer_offset);
            }
            if (num_classes == 2) {  // Second eightbyte
                if (classes[1] == SSE)
                    if (context->return_type->category == INFIX_TYPE_VECTOR && context->return_type->size == 32)
                        emit_vmovupd_ymm_mem(buf, XMM1_REG, RBP_REG, layout->return_buffer_offset + 32);
                    else
                        emit_movsd_xmm_mem(buf, XMM1_REG, RBP_REG, layout->return_buffer_offset + 8);
                else  // INTEGER
                    emit_mov_reg_mem(buf, RDX_REG, RBP_REG, layout->return_buffer_offset + 8);
            }
        }
    }
    // Standard function epilogue: tear down stack frame and return.
    emit_mov_reg_reg(buf, RSP_REG, RBP_REG);
    emit_pop_reg(buf, RBP_REG);
    emit_ret(buf);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 1 (Direct): Analyzes a signature and creates a call frame layout for System V.
 * @details This is the direct-marshalling equivalent of the standard `prepare` function.
 * It performs the same argument classification, but populates the new `infix_direct_call_frame_layout`
 * struct, which also stores pointers to the argument types and user-provided handlers.
 * It also calculates the necessary scratch space on the stack for marshalling.
 */
static infix_status prepare_direct_forward_call_frame_sysv_x64(infix_arena_t * arena,
                                                               infix_direct_call_frame_layout ** out_layout,
                                                               infix_type * ret_type,
                                                               infix_type ** arg_types,
                                                               size_t num_args,
                                                               infix_direct_arg_handler_t * handlers,
                                                               void * target_fn) {
    // Use the standard classifier to determine the final ABI locations for all arguments.
    infix_call_frame_layout * standard_layout = nullptr;
    infix_status status = prepare_forward_call_frame_sysv_x64(
        arena, &standard_layout, ret_type, arg_types, num_args, num_args, target_fn);
    if (status != INFIX_SUCCESS)
        return status;

    // Create the new direct layout and copy basic info.
    infix_direct_call_frame_layout * layout =
        infix_arena_calloc(arena, 1, sizeof(infix_direct_call_frame_layout), _Alignof(infix_direct_call_frame_layout));
    if (!layout)
        return INFIX_ERROR_ALLOCATION_FAILED;

    layout->args =
        infix_arena_calloc(arena, num_args, sizeof(infix_direct_arg_layout), _Alignof(infix_direct_arg_layout));
    if (!layout->args && num_args > 0)
        return INFIX_ERROR_ALLOCATION_FAILED;

    layout->num_args = num_args;
    layout->target_fn = target_fn;
    layout->return_value_in_memory = standard_layout->return_value_in_memory;

    // Calculate scratch space needed on the stack.
    size_t scratch_space_needed = 0;
    for (size_t i = 0; i < num_args; ++i) {
        layout->args[i].location = standard_layout->arg_locations[i];
        layout->args[i].type = arg_types[i];
        layout->args[i].handler = &handlers[i];

        if (handlers[i].aggregate_marshaller) {
            scratch_space_needed = _infix_align_up(scratch_space_needed, arg_types[i]->alignment);
            layout->args[i].location.num_regs = (uint32_t)scratch_space_needed;
            scratch_space_needed += arg_types[i]->size;
        }
        else if (handlers[i].scalar_marshaller) {
            scratch_space_needed = _infix_align_up(scratch_space_needed, 16);
            layout->args[i].location.num_regs = (uint32_t)scratch_space_needed;
            scratch_space_needed += 16;
        }
        else if (handlers[i].writeback_handler) {
            const infix_type * pointee = (arg_types[i]->category == INFIX_TYPE_POINTER)
                ? arg_types[i]->meta.pointer_info.pointee_type
                : arg_types[i];
            scratch_space_needed = _infix_align_up(scratch_space_needed, pointee->alignment);
            layout->args[i].location.num_regs = (uint32_t)scratch_space_needed;
            scratch_space_needed += pointee->size;
        }
    }

    // Calculate total stack allocation and finalize offsets.
    size_t total_stack_arg_size = standard_layout->total_stack_alloc;

    // Use scratch_space_needed, not the uninitialized temp_space_offset variable.
    size_t total_needed = total_stack_arg_size + scratch_space_needed;

    layout->total_stack_alloc = (total_needed + 15) & ~15;

    // Adjust temp offsets to be relative to RSP after allocation.
    // Standard args are at the bottom (lower offsets), scratch space is above them.
    size_t temp_base_offset = total_stack_arg_size;
    for (size_t i = 0; i < num_args; ++i) {
        if (layout->args[i].handler->aggregate_marshaller || layout->args[i].handler->scalar_marshaller ||
            layout->args[i].handler->writeback_handler) {
            layout->args[i].location.num_regs += (uint32_t)temp_base_offset;
        }
    }

    if (layout->total_stack_alloc > INFIX_MAX_STACK_ALLOC) {
        *out_layout = nullptr;
        return INFIX_ERROR_LAYOUT_FAILED;
    }
    *out_layout = layout;
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 2 (Direct): Generates the direct marshalling prologue for System V.
 * @details Establishes a stack frame, saves callee-saved registers for context,
 * moves the direct CIF arguments (`ret_ptr`, `lang_args`) into them, and allocates all
 * stack space required for outgoing arguments and local marshalling buffers.
 */
static infix_status generate_direct_forward_prologue_sysv_x64(code_buffer * buf,
                                                              infix_direct_call_frame_layout * layout) {
    emit_push_reg(buf, RBP_REG);
    emit_mov_reg_reg(buf, RBP_REG, RSP_REG);

    // Save callee-saved registers we will use for our context.
    // We push 4 registers (32 bytes) to maintain 16-byte stack alignment
    // (Previous stack state: [RetAddr]+[OldRBP] = 16 bytes. +32 bytes = 48 bytes. Aligned.)
    emit_push_reg(buf, R12_REG);  // Will hold scratch data / target function
    emit_push_reg(buf, R13_REG);  // Will hold return value pointer
    emit_push_reg(buf, R14_REG);  // Will hold language objects array pointer
    emit_push_reg(buf, R15_REG);  // Padding/Scratch (keeps stack aligned)

    // The direct CIF is called with (ret_ptr, lang_args) in RDI, RSI.
    emit_mov_reg_reg(buf, R13_REG, RDI_REG);  // r13 = ret_ptr
    emit_mov_reg_reg(buf, R14_REG, RSI_REG);  // r14 = lang_objects array

    // Allocate all stack space.
    if (layout->total_stack_alloc > 0)
        emit_sub_reg_imm32(buf, RSP_REG, layout->total_stack_alloc);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 3 (Direct): Generates code to call marshallers and move arguments for System V.
 * @details This corrected implementation uses a two-phase approach:
 * 1. MARSHALL & SAVE: Call each user handler and save the C value to a temporary
 *    local stack buffer. This prevents register clobbering.
 * 2. PLACE: Load the C value from its temporary location and move it to its final
 *    destination (the register or stack slot required by the System V ABI).
 */
static infix_status generate_direct_forward_argument_moves_sysv_x64(code_buffer * buf,
                                                                    infix_direct_call_frame_layout * layout) {
    // PHASE 1: MARSHALL & SAVE
    for (size_t i = 0; i < layout->num_args; ++i) {
        const infix_direct_arg_layout * arg_layout = &layout->args[i];
        int32_t temp_offset = (int32_t)arg_layout->location.num_regs;

        if (!arg_layout->handler->scalar_marshaller && !arg_layout->handler->aggregate_marshaller)
            continue;

        // Arg 1 (RDI) for marshaller: the language object pointer.
        emit_mov_reg_mem(buf, RDI_REG, R14_REG, i * sizeof(void *));

        if (arg_layout->handler->scalar_marshaller) {
            emit_mov_reg_imm64(buf, R10_REG, (uint64_t)arg_layout->handler->scalar_marshaller);
            emit_call_reg(buf, R10_REG);  // Result is now in RAX or XMM0.

            // Store RAX to stack. PLACE phase will load to XMM if needed.
            emit_mov_mem_reg(buf, RSP_REG, temp_offset, RAX_REG);
        }
        else if (arg_layout->handler->aggregate_marshaller) {
            // Arg 2 (RSI): Pointer to our stack buffer for the aggregate.
            emit_lea_reg_mem(buf, RSI_REG, RSP_REG, temp_offset);
            // Arg 3 (RDX): The infix_type*.
            emit_mov_reg_imm64(buf, RDX_REG, (uint64_t)arg_layout->type);
            emit_mov_reg_imm64(buf, R10_REG, (uint64_t)arg_layout->handler->aggregate_marshaller);
            emit_call_reg(buf, R10_REG);
        }
    }

    // PHASE 2: PLACE
    if (layout->return_value_in_memory)
        emit_mov_reg_reg(buf, GPR_ARGS[0], R13_REG);

    for (size_t i = 0; i < layout->num_args; ++i) {
        const infix_direct_arg_layout * arg_layout = &layout->args[i];
        int32_t temp_offset = (int32_t)arg_layout->location.num_regs;

        bool is_ptr_to_marshalled_agg =
            (arg_layout->type->category == INFIX_TYPE_POINTER && arg_layout->handler->aggregate_marshaller != NULL);
        bool is_out_param =
            (arg_layout->type->category == INFIX_TYPE_POINTER && arg_layout->handler->writeback_handler != NULL &&
             arg_layout->handler->scalar_marshaller == NULL && arg_layout->handler->aggregate_marshaller == NULL);

        switch (arg_layout->location.type) {
        case ARG_LOCATION_GPR:
            if (is_ptr_to_marshalled_agg || is_out_param)
                emit_lea_reg_mem(buf, GPR_ARGS[arg_layout->location.reg_index], RSP_REG, temp_offset);
            else
                emit_mov_reg_mem(buf, GPR_ARGS[arg_layout->location.reg_index], RSP_REG, temp_offset);
            break;
        case ARG_LOCATION_XMM:
            if (is_float(arg_layout->type))
                emit_cvtsd2ss_xmm_mem(buf, XMM_ARGS[arg_layout->location.reg_index], RSP_REG, temp_offset);
            else
                emit_movsd_xmm_mem(buf, XMM_ARGS[arg_layout->location.reg_index], RSP_REG, temp_offset);
            break;
        case ARG_LOCATION_GPR_PAIR:
            emit_mov_reg_mem(buf, GPR_ARGS[arg_layout->location.reg_index], RSP_REG, temp_offset);
            emit_mov_reg_mem(buf, GPR_ARGS[arg_layout->location.reg_index2], RSP_REG, temp_offset + 8);
            break;
        case ARG_LOCATION_SSE_SSE_PAIR:
            emit_movsd_xmm_mem(buf, XMM_ARGS[arg_layout->location.reg_index], RSP_REG, temp_offset);
            emit_movsd_xmm_mem(buf, XMM_ARGS[arg_layout->location.reg_index2], RSP_REG, temp_offset + 8);
            break;
        case ARG_LOCATION_INTEGER_SSE_PAIR:
            emit_mov_reg_mem(buf, GPR_ARGS[arg_layout->location.reg_index], RSP_REG, temp_offset);
            emit_movsd_xmm_mem(buf, XMM_ARGS[arg_layout->location.reg_index2], RSP_REG, temp_offset + 8);
            break;
        case ARG_LOCATION_SSE_INTEGER_PAIR:
            emit_movsd_xmm_mem(buf, XMM_ARGS[arg_layout->location.reg_index], RSP_REG, temp_offset);
            emit_mov_reg_mem(buf, GPR_ARGS[arg_layout->location.reg_index2], RSP_REG, temp_offset + 8);
            break;

        case ARG_LOCATION_STACK:
            for (size_t offset = 0; offset < arg_layout->type->size; offset += 8) {
                emit_mov_reg_mem(buf, RAX_REG, RSP_REG, temp_offset + offset);
                emit_mov_mem_reg(buf, RSP_REG, arg_layout->location.stack_offset + offset, RAX_REG);
            }
            break;
        default:
            break;
        }
    }
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 3.5 (Direct): Generates the call instruction for System V.
 */
static infix_status generate_direct_forward_call_instruction_sysv_x64(code_buffer * buf,
                                                                      infix_direct_call_frame_layout * layout) {
    emit_mov_reg_imm64(buf, R12_REG, (uint64_t)layout->target_fn);
    emit_test_reg_reg(buf, R12_REG, R12_REG);
    emit_jnz_short(buf, 2);
    emit_ud2(buf);
    emit_call_reg(buf, R12_REG);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 4 (Direct): Generates the function epilogue for System V.
 */
static infix_status generate_direct_forward_epilogue_sysv_x64(code_buffer * buf,
                                                              infix_direct_call_frame_layout * layout,
                                                              infix_type * ret_type) {
    if (ret_type->category != INFIX_TYPE_VOID && !layout->return_value_in_memory) {
        // Use full ABI classification for return values
        if (is_long_double(ret_type))
            emit_fstpt_mem(buf, R13_REG, 0);
        else {
            arg_class_t classes[2];
            size_t num_classes = 0;
            bool is_aggregate = ret_type->category == INFIX_TYPE_STRUCT || ret_type->category == INFIX_TYPE_UNION ||
                ret_type->category == INFIX_TYPE_ARRAY || ret_type->category == INFIX_TYPE_COMPLEX;

            if (is_aggregate)
                classify_aggregate_sysv(ret_type, classes, &num_classes);
            else if (is_float(ret_type) || is_double(ret_type) || (ret_type->category == INFIX_TYPE_VECTOR)) {
                classes[0] = SSE;
                num_classes = 1;
            }
            else {
                classes[0] = INTEGER;
                num_classes = 1;
                if (ret_type->size > 8) {
                    classes[1] = INTEGER;
                    num_classes = 2;
                }
            }

            if (num_classes == 1) {
                if (classes[0] == SSE) {
                    if (is_float(ret_type))
                        emit_movss_mem_xmm(buf, R13_REG, 0, XMM0_REG);
                    else if (ret_type->category == INFIX_TYPE_VECTOR && ret_type->size == 32)
                        emit_vmovupd_mem_ymm(buf, R13_REG, 0, XMM0_REG);
                    else if (ret_type->category == INFIX_TYPE_VECTOR && ret_type->size == 64)
                        emit_vmovupd_mem_zmm(buf, R13_REG, 0, XMM0_REG);
                    else if (ret_type->category == INFIX_TYPE_VECTOR)
                        emit_movups_mem_xmm(buf, R13_REG, 0, XMM0_REG);
                    else
                        emit_movsd_mem_xmm(buf, R13_REG, 0, XMM0_REG);
                }
                else {  // INTEGER
                    switch (ret_type->size) {
                    case 1:
                        emit_mov_mem_reg8(buf, R13_REG, 0, RAX_REG);
                        break;
                    case 2:
                        emit_mov_mem_reg16(buf, R13_REG, 0, RAX_REG);
                        break;
                    case 4:
                        emit_mov_mem_reg32(buf, R13_REG, 0, RAX_REG);
                        break;
                    default:
                        emit_mov_mem_reg(buf, R13_REG, 0, RAX_REG);
                        break;
                    }
                }
            }
            else if (num_classes == 2) {
                if (classes[0] == INTEGER && classes[1] == INTEGER) {
                    emit_mov_mem_reg(buf, R13_REG, 0, RAX_REG);
                    emit_mov_mem_reg(buf, R13_REG, 8, RDX_REG);
                }
                else if (classes[0] == SSE && classes[1] == SSE) {
                    emit_movsd_mem_xmm(buf, R13_REG, 0, XMM0_REG);
                    emit_movsd_mem_xmm(buf, R13_REG, 8, XMM1_REG);
                }
                else if (classes[0] == INTEGER && classes[1] == SSE) {
                    emit_mov_mem_reg(buf, R13_REG, 0, RAX_REG);
                    emit_movsd_mem_xmm(buf, R13_REG, 8, XMM0_REG);
                }
                else {  // SSE, INTEGER
                    emit_movsd_mem_xmm(buf, R13_REG, 0, XMM0_REG);
                    emit_mov_mem_reg(buf, R13_REG, 8, RAX_REG);
                }
            }
        }
    }

    // Call Write-Back Handlers
    for (size_t i = 0; i < layout->num_args; ++i) {
        const infix_direct_arg_layout * arg = &layout->args[i];
        if (arg->handler->writeback_handler) {
            // Save return registers before call
            emit_push_reg(buf, RAX_REG);           // +8
            emit_push_reg(buf, RDX_REG);           // +8
            emit_sub_reg_imm32(buf, RSP_REG, 32);  // +32 (space for XMM0/XMM1)
            // Total stack shift: +48 bytes

            emit_movsd_mem_xmm(buf, RSP_REG, 0, XMM0_REG);

            // Set up args for write-back call
            emit_mov_reg_mem(buf, RDI_REG, R14_REG, i * sizeof(void *));

            // Arg 2 (RSI): Pointer to the C data (in our scratch space)
            // Offsets are relative to the *original* RSP of the body.
            // Since we just pushed/subbed 48 bytes, we must add 48 to reach the original frame.
            int32_t temp_offset = (int32_t)arg->location.num_regs;
            emit_lea_reg_mem(buf, RSI_REG, RSP_REG, temp_offset + 48);

            emit_mov_reg_imm64(buf, RDX_REG, (uint64_t)arg->type);

            emit_mov_reg_imm64(buf, R10_REG, (uint64_t)arg->handler->writeback_handler);
            emit_call_reg(buf, R10_REG);

            // Restore return registers
            emit_movsd_xmm_mem(buf, XMM0_REG, RSP_REG, 0);
            emit_add_reg_imm32(buf, RSP_REG, 32);
            emit_pop_reg(buf, RDX_REG);
            emit_pop_reg(buf, RAX_REG);
        }
    }

    // Standard Epilogue
    if (layout->total_stack_alloc > 0)
        emit_add_reg_imm32(buf, RSP_REG, (int32_t)layout->total_stack_alloc);

    emit_pop_reg(buf, R15_REG);
    emit_pop_reg(buf, R14_REG);
    emit_pop_reg(buf, R13_REG);
    emit_pop_reg(buf, R12_REG);

    emit_pop_reg(buf, RBP_REG);
    emit_ret(buf);

    return INFIX_SUCCESS;
}
