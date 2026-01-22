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
 * @file abi_win_x64.c
 * @brief Implements the FFI logic for the Windows x64 calling convention.
 * @ingroup internal_abi_x64
 *
 * @internal
 * This file provides the concrete implementation of the ABI spec for the Microsoft
 * x64 calling convention, used on all 64-bit versions of Windows.
 *
 * Key features and differences from the System V ABI implemented here:
 *
 * - **Register "Slots":** The first four arguments are passed in registers, but the
 *   slots are shared. RCX/XMM0 is the first slot, RDX/XMM1 is the second, etc.
 *   An `int` followed by a `float` would use RCX and XMM1.
 *
 * - **Shadow Space:** The caller must allocate a 32-byte "shadow space" on the stack
 *   for the callee.
 *
 * - **By-Reference Passing:** Aggregates (structs/unions) are passed by reference
 *   if their size is not a power of two (1, 2, 4, or 8 bytes), or if they have
 *   special constructors.
 *   **Crucially, all SIMD vectors > 16 bytes (__m256, __m512) are passed by reference.**
 *   **__m128 (16 bytes) is passed by value in XMM.**
 *
 * - **Return Values:**
 *   - Scalars and __m128 are returned in registers (RAX/XMM0).
 *   - **__m256 and __m512 are returned in registers (YMM0/ZMM0).**
 *   - Aggregates > 8 bytes (excluding vectors) are returned via a hidden pointer.
 * @endinternal
 */
// This file performs many safe conversions from size_t to int32_t for instruction
// offsets. The library's internal limits (INFIX_MAX_STACK_ALLOC) ensure these
// conversions do not lose data. We disable the warning to produce a clean build.
#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable : 4267)  // conversion from 'size_t' to 'int32_t'
#endif
#include "arch/x64/abi_x64_common.h"
#include "arch/x64/abi_x64_emitters.h"
#include "common/infix_internals.h"
#include "common/utility.h"
#include <stdbool.h>
#include <stdlib.h>
/** An array of GPRs used for passing the first four integer/pointer arguments. */
static const x64_gpr GPR_ARGS[] = {RCX_REG, RDX_REG, R8_REG, R9_REG};
/** An array of XMM registers used for passing the first four floating-point arguments. */
static const x64_xmm XMM_ARGS[] = {XMM0_REG, XMM1_REG, XMM2_REG, XMM3_REG};
/** The number of register "slots" available for arguments. */
#define NUM_GPR_ARGS 4
/** The number of XMM registers used for arguments. */
#define NUM_XMM_ARGS 4
/** The size in bytes of the mandatory stack space reserved by the caller for the callee. */
#define SHADOW_SPACE 32
/** @brief The v-table of Windows x64 functions for generating forward trampolines. */
static infix_status prepare_forward_call_frame_win_x64(infix_arena_t * arena,
                                                       infix_call_frame_layout ** out_layout,
                                                       infix_type * ret_type,
                                                       infix_type ** arg_types,
                                                       size_t num_args,
                                                       size_t num_fixed_args,
                                                       void * target_fn);
static infix_status generate_forward_prologue_win_x64(code_buffer * buf, infix_call_frame_layout * layout);
static infix_status generate_forward_argument_moves_win_x64(code_buffer * buf,
                                                            infix_call_frame_layout * layout,
                                                            infix_type ** arg_types,
                                                            size_t num_args,
                                                            size_t num_fixed_args);
static infix_status generate_forward_call_instruction_win_x64(code_buffer *, infix_call_frame_layout *);
static infix_status generate_forward_epilogue_win_x64(code_buffer * buf,
                                                      infix_call_frame_layout * layout,
                                                      infix_type * ret_type);
const infix_forward_abi_spec g_win_x64_forward_spec = {
    .prepare_forward_call_frame = prepare_forward_call_frame_win_x64,
    .generate_forward_prologue = generate_forward_prologue_win_x64,
    .generate_forward_argument_moves = generate_forward_argument_moves_win_x64,
    .generate_forward_call_instruction = generate_forward_call_instruction_win_x64,
    .generate_forward_epilogue = generate_forward_epilogue_win_x64};
/** @brief The v-table of Windows x64 functions for generating reverse trampolines. */
static infix_status prepare_reverse_call_frame_win_x64(infix_arena_t * arena,
                                                       infix_reverse_call_frame_layout ** out_layout,
                                                       infix_reverse_t * context);
static infix_status generate_reverse_prologue_win_x64(code_buffer * buf, infix_reverse_call_frame_layout * layout);
static infix_status generate_reverse_argument_marshalling_win_x64(code_buffer * buf,
                                                                  infix_reverse_call_frame_layout * layout,
                                                                  infix_reverse_t * context);
static infix_status generate_reverse_dispatcher_call_win_x64(code_buffer * buf,
                                                             infix_reverse_call_frame_layout * layout,
                                                             infix_reverse_t * context);
static infix_status generate_reverse_epilogue_win_x64(code_buffer * buf,
                                                      infix_reverse_call_frame_layout * layout,
                                                      infix_reverse_t * context);
const infix_reverse_abi_spec g_win_x64_reverse_spec = {
    .prepare_reverse_call_frame = prepare_reverse_call_frame_win_x64,
    .generate_reverse_prologue = generate_reverse_prologue_win_x64,
    .generate_reverse_argument_marshalling = generate_reverse_argument_marshalling_win_x64,
    .generate_reverse_dispatcher_call = generate_reverse_dispatcher_call_win_x64,
    .generate_reverse_epilogue = generate_reverse_epilogue_win_x64};

/** @brief The v-table for the new Direct Marshalling ABI. */
static infix_status prepare_direct_forward_call_frame_win_x64(infix_arena_t * arena,
                                                              infix_direct_call_frame_layout ** out_layout,
                                                              infix_type * ret_type,
                                                              infix_type ** arg_types,
                                                              size_t num_args,
                                                              infix_direct_arg_handler_t * handlers,
                                                              void * target_fn);
static infix_status generate_direct_forward_prologue_win_x64(code_buffer * buf,
                                                             infix_direct_call_frame_layout * layout);
static infix_status generate_direct_forward_argument_moves_win_x64(code_buffer * buf,
                                                                   infix_direct_call_frame_layout * layout);
static infix_status generate_direct_forward_call_instruction_win_x64(code_buffer * buf,
                                                                     infix_direct_call_frame_layout * layout);
static infix_status generate_direct_forward_epilogue_win_x64(code_buffer * buf,
                                                             infix_direct_call_frame_layout * layout,
                                                             infix_type * ret_type);
const infix_direct_forward_abi_spec g_win_x64_direct_forward_spec = {
    .prepare_direct_forward_call_frame = prepare_direct_forward_call_frame_win_x64,
    .generate_direct_forward_prologue = generate_direct_forward_prologue_win_x64,
    .generate_direct_forward_argument_moves = generate_direct_forward_argument_moves_win_x64,
    .generate_direct_forward_call_instruction = generate_direct_forward_call_instruction_win_x64,
    .generate_direct_forward_epilogue = generate_direct_forward_epilogue_win_x64};

/**
 * @internal
 * @brief Determines if a type is returned by value in RAX/XMM0 or via a hidden pointer.
 * @details On Windows x64:
 * - Scalars and __m128 are returned in registers (RAX or XMM0).
 * - **__m256 and __m512 are returned in registers (YMM0 or ZMM0).**
 * - Aggregates > 8 bytes (excluding vectors) are returned via a hidden pointer.
 */
static bool return_value_is_by_reference(const infix_type * type) {
    if (type->category == INFIX_TYPE_VECTOR) {
// Windows x64 ABI (MSVC) returns ALL vectors in registers (XMM0, YMM0, ZMM0).
// However, MinGW (GCC on Windows) diverges for __m256 and __m512, returning them via hidden pointer.
#if defined(__MINGW32__) || defined(__MINGW64__)
        if (type->size > 16)
            return true;
#endif
        return false;
    }

    if (type->category == INFIX_TYPE_STRUCT || type->category == INFIX_TYPE_UNION ||
        type->category == INFIX_TYPE_ARRAY || type->category == INFIX_TYPE_COMPLEX)
        return type->size != 1 && type->size != 2 && type->size != 4 && type->size != 8;
#if defined(INFIX_COMPILER_GCC)
    // GCC/Clang have a special case for returning long double by reference on Windows.
    if (is_long_double(type))
        return true;
#endif
    return false;
}
/**
 * @internal
 * @brief Determines if a type must be passed by reference on the Windows x64 ABI.
 * @details
 * - Arrays are passed as pointers (C decay).
 * - __m128, __m256, __m512 are ALL passed by reference (pointer).
 * - Aggregates > 8 bytes or non-power-of-two size are passed by reference.
 */
static bool is_passed_by_reference(const infix_type * type) {
    if (type == nullptr)
        return false;
    // Arrays passed as arguments decay to pointers. We must pass the address.
    if (type->category == INFIX_TYPE_ARRAY)
        return true;

    // Windows x64 ABI:
    // All vector types are passed by reference (pointer to memory) in standard calls.
    if (type->category == INFIX_TYPE_VECTOR)
        return true;

    return type->size != 1 && type->size != 2 && type->size != 4 && type->size != 8;
}

/**
 * @internal
 * @brief Stage 1 (Forward): Analyzes a signature and creates a call frame layout for Windows x64.
 * @details Assigns each argument to a register "slot" or the stack. If the return value is
 *          passed by reference, it consumes the first slot (RCX).
 * @param arena The temporary arena for allocations.
 * @param out_layout Receives the created layout blueprint.
 * @param ret_type The function's return type.
 * @param arg_types Array of argument types.
 * @param num_args Total number of arguments.
 * @param num_fixed_args Number of non-variadic arguments.
 * @param target_fn The target function address.
 * @return `INFIX_SUCCESS` on success.
 */
static infix_status prepare_forward_call_frame_win_x64(infix_arena_t * arena,
                                                       infix_call_frame_layout ** out_layout,
                                                       infix_type * ret_type,
                                                       infix_type ** arg_types,
                                                       size_t num_args,
                                                       size_t num_fixed_args,
                                                       void * target_fn) {
    if (out_layout == nullptr)
        return INFIX_ERROR_INVALID_ARGUMENT;
    infix_call_frame_layout * layout =
        infix_arena_calloc(arena, 1, sizeof(infix_call_frame_layout), _Alignof(infix_call_frame_layout));
    if (layout == nullptr) {
        *out_layout = nullptr;
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    layout->is_variadic = num_args > num_fixed_args;
    layout->target_fn = target_fn;
    INFIX_DEBUG_PRINTF("Allocating %llu bytes for arg_locations in temp_arena",
                       (unsigned long long)(num_args * sizeof(infix_arg_location)));
    layout->arg_locations =
        infix_arena_calloc(arena, num_args, sizeof(infix_arg_location), _Alignof(infix_arg_location));
    if (layout->arg_locations == nullptr && num_args > 0) {
        *out_layout = nullptr;
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    layout->return_value_in_memory = return_value_is_by_reference(ret_type);
    size_t arg_position = 0;
    if (layout->return_value_in_memory)
        arg_position++;  // The hidden return pointer consumes the first slot (RCX).
    size_t current_stack_offset = SHADOW_SPACE;
    layout->num_stack_args = 0;
    for (size_t i = 0; i < num_args; ++i) {
        infix_type * current_type = arg_types[i];
        // Detect vectors as FP so they get XMM slots if passed by value (<=16 bytes).
        bool is_fp = is_float(current_type) || is_double(current_type) || (current_type->category == INFIX_TYPE_VECTOR);
        // as FP register args in the slot assignment logic
        // (they go to GPR slots as pointers).
        bool is_ref = is_passed_by_reference(current_type);
        bool is_variadic_arg = (i >= num_fixed_args);

        if (arg_position < 4) {
            if (is_fp && !is_ref && !is_variadic_arg) {
                layout->arg_locations[i].type = ARG_LOCATION_XMM;
                layout->arg_locations[i].reg_index = (uint8_t)arg_position++;
            }
            else {
                layout->arg_locations[i].type = ARG_LOCATION_GPR;
                layout->arg_locations[i].reg_index = (uint8_t)arg_position++;
            }
        }
        else {
            layout->arg_locations[i].type = ARG_LOCATION_STACK;
            layout->arg_locations[i].stack_offset = (uint32_t)current_stack_offset;
            layout->num_stack_args++;
            // Calculate space needed on the stack for this argument.
            // By-reference types (including arrays/vectors) are just a pointer (8 bytes).
            size_t arg_stack_space = is_ref ? 8 : ((current_type->size + 7) & ~7);
            current_stack_offset += arg_stack_space;
            // Step 0: Make sure we aren't blowing ourselves up
            if (current_stack_offset > INFIX_MAX_ARG_SIZE) {
                *out_layout = nullptr;
                return INFIX_ERROR_LAYOUT_FAILED;
            }
        }
    }
    size_t total_stack_arg_size = current_stack_offset - SHADOW_SPACE;
    // Total allocation must include shadow space and be 16-byte aligned.
    layout->total_stack_alloc = (SHADOW_SPACE + total_stack_arg_size + 15) & ~15;
    // Prevent integer overflow and excessive stack allocation.
    if (layout->total_stack_alloc > INFIX_MAX_STACK_ALLOC) {
        fprintf(stderr, "Error: Calculated stack allocation exceeds safe limit of %d bytes.\n", INFIX_MAX_STACK_ALLOC);
        *out_layout = nullptr;
        return INFIX_ERROR_LAYOUT_FAILED;
    }
    *out_layout = layout;
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 2 (Forward): Generates the function prologue for the Windows x64 trampoline.
 * @details This function emits the standard machine code required at the beginning of a function.
 *          The generated assembly performs these steps:
 *          1.  `push rbp` / `mov rbp, rsp`: Creates a standard stack frame.
 *          2.  `push r12-r15`: Saves all callee-saved registers that the trampoline will
 *              use to hold its context.
 *          3.  `and rsp, -16`: **Forces 16-byte stack alignment**. This is critical because
 *              SIMD instructions in the target function may segfault if the stack is misaligned.
 *          4.  `mov r12, rcx`, etc.: Moves the trampoline's own arguments into preserved registers.
 *          5.  `sub rsp, imm32`: Allocates the required space on the stack.
 *
 * @param buf The code buffer to write the assembly into.
 * @param layout The call frame layout containing total stack allocation information.
 * @return `INFIX_SUCCESS` on successful code generation.
 */
static infix_status generate_forward_prologue_win_x64(code_buffer * buf, infix_call_frame_layout * layout) {
    emit_push_reg(buf, RBP_REG);              // push rbp
    emit_mov_reg_reg(buf, RBP_REG, RSP_REG);  // mov rbp, rsp
    // Save callee-saved registers we will use to hold our context.
    emit_push_reg(buf, R12_REG);  // push r12 (will hold target function address)
    emit_push_reg(buf, R13_REG);  // push r13 (will hold return value pointer)
    emit_push_reg(buf, R14_REG);  // push r14 (will hold argument pointers array)
    emit_push_reg(buf, R15_REG);  // push r15 (will be a scratch register for data moves)

    // FORCE 16-BYTE ALIGNMENT.
    // AND RSP, -16 (48 83 E4 F0)
    EMIT_BYTES(buf, 0x48, 0x83, 0xE4, 0xF0);

    // Move incoming trampoline arguments to non-volatile registers.
    if (layout->target_fn == nullptr) {           // Unbound: (target_fn, ret_ptr, args_ptr) in RCX, RDX, R8
        emit_mov_reg_reg(buf, R12_REG, RCX_REG);  // R12 = target function
        emit_mov_reg_reg(buf, R13_REG, RDX_REG);  // R13 = return value buffer
        emit_mov_reg_reg(buf, R14_REG, R8_REG);   // R14 = argument values array
    }
    else {                                        // Bound: (ret_ptr, args_ptr) in RCX, RDX
        emit_mov_reg_reg(buf, R13_REG, RCX_REG);  // R13 = return value buffer
        emit_mov_reg_reg(buf, R14_REG, RDX_REG);  // R14 = argument values array
    }
    // Allocate stack space for arguments and shadow space.
    if (layout->total_stack_alloc > 0)
        emit_sub_reg_imm32(buf, RSP_REG, (int32_t)layout->total_stack_alloc);
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 3 (Forward): Generates code to move arguments into their native locations.
 * @details This function iterates through the layout blueprint and emits `mov` instructions
 *          to place each argument into its assigned register or stack slot.
 *
 *          Key behaviors implemented:
 *          - **Register Arguments:** Loads data into the correct GPR or XMM register.
 *          - **Sign-Extension:** Uses `movsxd` for signed integers smaller than 64 bits.
 *          - **By-Reference Arguments:** Loads the pointer directly into the GPR.
 *          - **Stack Arguments:** Copies data to the stack, past the 32-byte shadow space.
 *          - **Variadic Floats:** Correctly passes float/double arguments in both the
 *            appropriate GPR and XMM register for variadic functions.
 * @param buf The code buffer.
 * @param layout The layout blueprint.
 * @param arg_types The array of argument types.
 * @param num_args Total number of arguments.
 * @param num_fixed_args Number of fixed arguments.
 * @return `INFIX_SUCCESS` on success.
 */
static infix_status generate_forward_argument_moves_win_x64(code_buffer * buf,
                                                            infix_call_frame_layout * layout,
                                                            infix_type ** arg_types,
                                                            size_t num_args,
                                                            size_t num_fixed_args) {
    // If returning a large struct, the hidden pointer (stored in r13) must be moved to RCX.
    if (layout->return_value_in_memory)
        emit_mov_reg_reg(buf, GPR_ARGS[0], R13_REG);
    // Marshall Register Arguments
    for (size_t i = 0; i < num_args; ++i) {
        infix_arg_location * loc = &layout->arg_locations[i];
        if (loc->type == ARG_LOCATION_STACK)
            continue;  // Handle stack args later.
        infix_type * current_type = arg_types[i];
        bool is_variadic_arg = (i >= num_fixed_args);
        // R15 = pointer to the current argument's data from the args_array.
        emit_mov_reg_mem(buf, R15_REG, R14_REG, (int32_t)(i * sizeof(void *)));
        if (loc->type == ARG_LOCATION_GPR) {
            if (is_passed_by_reference(current_type))
                // For Arrays/By-Ref Structs/Vectors: The data in R15 IS the pointer we want. Move it to destination.
                emit_mov_reg_reg(buf, GPR_ARGS[loc->reg_index], R15_REG);
            else if (layout->is_variadic && is_variadic_arg && (is_float(current_type) || is_double(current_type))) {
                // Variadic Rule: float/double are passed in both GPR and XMM.
                x64_xmm xmm_reg = XMM_ARGS[loc->reg_index];
                x64_gpr gpr_reg = GPR_ARGS[loc->reg_index];
                emit_movsd_xmm_mem(buf, xmm_reg, R15_REG, 0);  // Load into XMM
                emit_movq_gpr_xmm(buf, gpr_reg, xmm_reg);      // Copy from XMM to GPR
            }
            else {
                bool is_signed = current_type->category == INFIX_TYPE_PRIMITIVE && current_type->size <= 4 &&
                    (current_type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
                     current_type->meta.primitive_id == INFIX_PRIMITIVE_SINT16 ||
                     current_type->meta.primitive_id == INFIX_PRIMITIVE_SINT32);

                if (is_signed) {
                    // Signed types need sign extension
                    if (current_type->size == 1)
                        emit_movsx_reg64_mem8(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                    else if (current_type->size == 2)
                        emit_movsx_reg64_mem16(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                    else
                        emit_movsxd_reg_mem(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                }
                else {
                    // Unsigned types (including small structs/bitfields) need zero extension
                    if (current_type->size == 1)
                        emit_movzx_reg64_mem8(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                    else if (current_type->size == 2)
                        emit_movzx_reg64_mem16(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                    else if (current_type->size == 4)
                        emit_mov_reg32_mem(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                    else
                        emit_mov_reg_mem(buf, GPR_ARGS[loc->reg_index], R15_REG, 0);
                }
            }
        }
        else {  // ARG_LOCATION_XMM
            if (is_float(current_type))
                emit_movss_xmm_mem(buf, XMM_ARGS[loc->reg_index], R15_REG, 0);
            else if (current_type->category == INFIX_TYPE_VECTOR)
                emit_movups_xmm_mem(buf, XMM_ARGS[loc->reg_index], R15_REG, 0);
            else
                emit_movsd_xmm_mem(buf, XMM_ARGS[loc->reg_index], R15_REG, 0);
        }
    }
    // Marshall Stack Arguments
    for (size_t i = 0; i < num_args; ++i) {
        if (layout->arg_locations[i].type != ARG_LOCATION_STACK)
            continue;
        infix_type * current_type = arg_types[i];
        infix_arg_location * loc = &layout->arg_locations[i];
        // R15 = pointer to the argument's data.
        emit_mov_reg_mem(buf, R15_REG, R14_REG, i * sizeof(void *));
        if (is_passed_by_reference(current_type))
            // Arrays/By-Ref: R15 IS the pointer. Store it on the stack.
            emit_mov_mem_reg(buf, RSP_REG, loc->stack_offset, R15_REG);
        else {
            // Copy the argument data from the user's buffer to the stack, 8 bytes at a time.
            for (size_t offset = 0; offset < current_type->size; offset += 8) {
                emit_mov_reg_mem(buf, RAX_REG, R15_REG, offset);                      // Load 8 bytes into scratch reg
                emit_mov_mem_reg(buf, RSP_REG, loc->stack_offset + offset, RAX_REG);  // Store to stack
            }
        }
    }
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 3.5 (Forward): Generates the null-check and call instruction.
 * @param buf The code buffer.
 * @param layout The call frame layout.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_forward_call_instruction_win_x64(code_buffer * buf,
                                                              c23_maybe_unused infix_call_frame_layout * layout) {
    if (layout->target_fn) {
        // For a bound trampoline, the target is hardcoded. Load it into R12.
        emit_mov_reg_imm64(buf, R12_REG, (uint64_t)layout->target_fn);
    }
    // For an unbound trampoline, R12 was already loaded from the first argument in the prologue.
    // On Windows x64, the target function pointer is stored in R12.
    emit_test_reg_reg(buf, R12_REG, R12_REG);  // test r12, r12
    emit_jnz_short(buf, 2);                    // jnz +2
    emit_ud2(buf);                             // ud2
    emit_call_reg(buf, R12_REG);               // call r12
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 4 (Forward): Generates the function epilogue for the Windows x64 trampoline.
 * @details This function emits the code to handle the function's return value and
 *          properly tear down the stack frame.
 *
 *          Since the prologue used `AND RSP, -16`, we cannot restore `RSP` by simply adding
 *          to it. Instead, we use `LEA RSP, [RBP - 32]` to restore `RSP` to point exactly
 *          to where the saved registers (R12-R15) are stored.
 *          Offset calculation: RBP is pushed, then R12, R13, R14, R15.
 *          RBP points to saved RBP.
 *          R12 @ RBP-8
 *          R13 @ RBP-16
 *          R14 @ RBP-24
 *          R15 @ RBP-32
 *
 * @param buf The code buffer.
 * @param layout The call frame layout.
 * @param ret_type The `infix_type` of the function's return value.
 * @return `INFIX_SUCCESS` on successful code generation.
 */
static infix_status generate_forward_epilogue_win_x64(code_buffer * buf,
                                                      infix_call_frame_layout * layout,
                                                      infix_type * ret_type) {
    // R13 holds the pointer to the FFI return buffer.
    if (ret_type->category != INFIX_TYPE_VOID && !layout->return_value_in_memory) {
        if (is_float(ret_type))
            emit_movss_mem_xmm(buf, R13_REG, 0, XMM0_REG);
        else if (is_double(ret_type))
            emit_movsd_mem_xmm(buf, R13_REG, 0, XMM0_REG);
        else if (ret_type->size == 16 &&
                 (ret_type->category == INFIX_TYPE_PRIMITIVE || ret_type->category == INFIX_TYPE_VECTOR))
            // `__int128_t` (on GCC/Clang) and 16-byte vectors are returned in XMM0.
            emit_movups_mem_xmm(buf, R13_REG, 0, XMM0_REG);
        else if (ret_type->size == 32 && ret_type->category == INFIX_TYPE_VECTOR)
            emit_vmovupd_mem_ymm(buf, R13_REG, 0, XMM0_REG);
        else if (ret_type->size == 64 && ret_type->category == INFIX_TYPE_VECTOR)
            emit_vmovupd_mem_zmm(buf, R13_REG, 0, XMM0_REG);
        else {
            // All other by-value types are returned in RAX. Use a size-appropriate store.
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
            case 8:
                emit_mov_mem_reg(buf, R13_REG, 0, RAX_REG);
                break;
            default:
                break;  // Should be unreachable
            }
        }
    }
    // Restore stack pointer to the saved registers area.
    // 4 registers pushed (R12, R13, R14, R15) relative to RBP.
    // LEA RSP, [RBP - 32]
    emit_lea_reg_mem(buf, RSP_REG, RBP_REG, -32);

    // Restore callee-saved registers and return.
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
 * @details This function determines the total stack space needed by the JIT-compiled stub.
 * This space includes areas to save all incoming argument registers, a buffer for the
 * return value, the `args_array`, a data area for by-value arguments, and the
 * shadow space the stub must provide for the C dispatcher it calls.
 *
 * @param arena The temporary arena for allocations.
 * @param[out] out_layout The resulting reverse call frame layout blueprint, populated with offsets.
 * @param context The reverse trampoline context with full signature information.
 * @return `INFIX_SUCCESS` on success, or an error code on failure.
 */
static infix_status prepare_reverse_call_frame_win_x64(infix_arena_t * arena,
                                                       infix_reverse_call_frame_layout ** out_layout,
                                                       infix_reverse_t * context) {
    infix_reverse_call_frame_layout * layout = infix_arena_calloc(
        arena, 1, sizeof(infix_reverse_call_frame_layout), _Alignof(infix_reverse_call_frame_layout));
    if (!layout)
        return INFIX_ERROR_ALLOCATION_FAILED;
    if (!context || !context->return_type)
        return INFIX_ERROR_INVALID_ARGUMENT;
    // Calculate space needed for each component, ensuring 16-byte alignment for safety.
    size_t return_size = (context->return_type->size + 15) & ~15;
    size_t args_array_size = context->num_args * sizeof(void *);
    size_t saved_args_data_size = 0;
    for (size_t i = 0; i < context->num_args; ++i) {
        if (context->arg_types[i] == nullptr) {
            *out_layout = nullptr;
            // Set error for an illegal type in an aggregate (a NULL type pointer).
            _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_INVALID_MEMBER_TYPE, 0);
            return INFIX_ERROR_INVALID_ARGUMENT;
        }
        if (!is_passed_by_reference(context->arg_types[i]))
            saved_args_data_size += (context->arg_types[i]->size + 15) & ~15;
    }
    // Security: Check against excessively large argument data size.
    if (saved_args_data_size > INFIX_MAX_ARG_SIZE) {
        *out_layout = nullptr;
        return INFIX_ERROR_LAYOUT_FAILED;
    }
    size_t gpr_reg_save_area_size = NUM_GPR_ARGS * 8;
    size_t xmm_reg_save_area_size = NUM_XMM_ARGS * 16;
    // The total space needed includes all local data plus the shadow space for the call to the C dispatcher.
    size_t total_local_space = return_size + args_array_size + saved_args_data_size + gpr_reg_save_area_size +
        xmm_reg_save_area_size + SHADOW_SPACE;
    // Prevent integer overflow from fuzzer-provided types that are impractically large by ensuring the total required
    // stack space is within a safe limit.
    if (total_local_space > INFIX_MAX_STACK_ALLOC) {
        *out_layout = nullptr;
        return INFIX_ERROR_LAYOUT_FAILED;
    }
    // The total allocation for the stack frame must be 16-byte aligned.
    layout->total_stack_alloc = (total_local_space + 15) & ~15;
    // Define the layout of our local stack variables relative to RSP after allocation.
    // [ shadow space | return_buffer | gpr_save | xmm_save | args_array | saved_args_data ]
    layout->return_buffer_offset = SHADOW_SPACE;
    layout->gpr_save_area_offset = layout->return_buffer_offset + return_size;
    layout->xmm_save_area_offset = layout->gpr_save_area_offset + gpr_reg_save_area_size;
    layout->args_array_offset = layout->xmm_save_area_offset + xmm_reg_save_area_size;

    // Ensure 16-byte alignment for the saved arguments area.
    layout->saved_args_offset = (layout->args_array_offset + args_array_size + 15) & ~15;

    *out_layout = layout;
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 2 (Reverse): Generates the prologue for the reverse trampoline stub.
 * @details Emits the standard Windows x64 function entry code. This involves:
 *          1. Creating a standard stack frame (`push rbp; mov rbp, rsp`).
 *          2. Saving any non-volatile registers that the stub will use as scratch space
 *             (RSI and RDI in this implementation).
 *          3. **Forcing stack alignment** (`and rsp, -16`).
 *          4. Allocating all necessary local stack space for the stub's internal
 *             data structures, as calculated in the `prepare` stage.
 *
 * @param buf The code buffer to write the assembly into.
 * @param layout The blueprint containing the total stack space to allocate.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_reverse_prologue_win_x64(code_buffer * buf, infix_reverse_call_frame_layout * layout) {
    // Standard function prologue to establish a stack frame.
    emit_push_reg(buf, RBP_REG);
    emit_mov_reg_reg(buf, RBP_REG, RSP_REG);
    // Save callee-saved registers that we might use as scratch registers.
    emit_push_reg(buf, RSI_REG);
    emit_push_reg(buf, RDI_REG);

    // FORCE 16-BYTE ALIGNMENT.
    // AND RSP, -16 (48 83 E4 F0)
    EMIT_BYTES(buf, 0x48, 0x83, 0xE4, 0xF0);

    // Allocate all local stack space calculated in the prepare stage. This includes
    // space for register save areas, the return buffer, args_array, and shadow space.
    if (layout->total_stack_alloc > 0)
        emit_sub_reg_imm32(buf, RSP_REG, layout->total_stack_alloc);
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 3 (Reverse): Generates code to marshal arguments into the generic `void**` array.
 * @details This function performs the "un-marshalling" of arguments from their native
 *          locations into the generic format expected by the C dispatcher.
 *
 *          The process is as follows:
 *          1.  **Save All Argument Registers:** It first saves all four potential integer
 *              argument registers (RCX, RDX, R8, R9) and all four potential floating-point
 *              registers (XMM0-3) to a dedicated save area on the local stack. This
 *              captures all register-based arguments in one place.
 *
 *          2.  **Populate `args_array`:** It then iterates through the function's expected
 *              arguments and generates code to populate the `args_array`. For each argument:
 *              a. It determines if the argument was passed in a register or on the stack.
 *              b. If passed by reference, it gets the pointer directly from the register
 *                 save area or the caller's stack.
 *              c. If passed by value, it gets a pointer *to the saved copy* of the value.
 *              d. This pointer is then stored in the correct slot of the `args_array`.
 *
 * @param buf The code buffer.
 * @param layout The blueprint containing stack offsets for the save areas and `args_array`.
 * @param context The context containing the argument type information for the callback.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_reverse_argument_marshalling_win_x64(code_buffer * buf,
                                                                  infix_reverse_call_frame_layout * layout,
                                                                  infix_reverse_t * context) {
    // Step 1: Save all potential incoming argument registers to our local stack
    emit_mov_mem_reg(buf, RSP_REG, layout->gpr_save_area_offset + 0 * 8, RCX_REG);
    emit_mov_mem_reg(buf, RSP_REG, layout->gpr_save_area_offset + 1 * 8, RDX_REG);
    emit_mov_mem_reg(buf, RSP_REG, layout->gpr_save_area_offset + 2 * 8, R8_REG);
    emit_mov_mem_reg(buf, RSP_REG, layout->gpr_save_area_offset + 3 * 8, R9_REG);
    emit_movups_mem_xmm(buf, RSP_REG, layout->xmm_save_area_offset + 0 * 16, XMM0_REG);
    emit_movups_mem_xmm(buf, RSP_REG, layout->xmm_save_area_offset + 1 * 16, XMM1_REG);
    emit_movups_mem_xmm(buf, RSP_REG, layout->xmm_save_area_offset + 2 * 16, XMM2_REG);
    emit_movups_mem_xmm(buf, RSP_REG, layout->xmm_save_area_offset + 3 * 16, XMM3_REG);
    // Step 2: Populate the `args_array` with pointers to the argument data
    size_t arg_pos_offset = return_value_is_by_reference(context->return_type) ? 1 : 0;
    size_t stack_slot_offset = 0;  // Tracks arguments on the caller's stack.
    for (size_t i = 0; i < context->num_args; i++) {
        infix_type * current_type = context->arg_types[i];
        bool is_fp = is_float(current_type) || is_double(current_type) ||
            (current_type->category == INFIX_TYPE_VECTOR && current_type->size <= 16);
        bool passed_by_ref = is_passed_by_reference(current_type);
        size_t arg_pos = i + arg_pos_offset;
        bool is_variadic_arg = (i >= context->num_fixed_args);
        if (arg_pos < 4) {
            // Argument was passed in a register. We need a pointer to its saved copy.
            int32_t source_offset;
            bool use_xmm = is_fp && !is_variadic_arg && !passed_by_ref;
            if (use_xmm)
                source_offset = layout->xmm_save_area_offset + arg_pos * 16;
            else
                source_offset = layout->gpr_save_area_offset + arg_pos * 8;
            if (passed_by_ref)
                // The value in the GPR save area IS the pointer we need. Load it directly.
                emit_mov_reg_mem(buf, RAX_REG, RSP_REG, source_offset);
            else
                // The value is the data itself. Get a pointer TO the saved data.
                emit_lea_reg_mem(buf, RAX_REG, RSP_REG, source_offset);
            // Store the final pointer into the args_array.
            emit_mov_mem_reg(buf, RSP_REG, layout->args_array_offset + i * sizeof(void *), RAX_REG);
        }
        else {
            // Argument was passed on the caller's stack.
            // After our prologue, caller stack args start at [rbp + 16 (ret addr + old rbp) + 32 (shadow space)].
            int32_t caller_stack_offset = 16 + SHADOW_SPACE + (stack_slot_offset * 8);
            if (passed_by_ref)
                // The value on the stack IS the pointer we need. Load it.
                emit_mov_reg_mem(buf, RAX_REG, RBP_REG, caller_stack_offset);
            else
                // The value on the stack is the data. Get a pointer TO it.
                emit_lea_reg_mem(buf, RAX_REG, RBP_REG, caller_stack_offset);
            // Store the final pointer into the args_array.
            emit_mov_mem_reg(buf, RSP_REG, layout->args_array_offset + i * sizeof(void *), RAX_REG);
            // Advance our offset into the caller's stack frame for the next argument.
            size_t size_on_stack = (passed_by_ref) ? 8 : current_type->size;
            stack_slot_offset += (size_on_stack + 7) / 8;
        }
    }
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 4 (Reverse): Generates the code to call the high-level C dispatcher function.
 * @details This function emits the instructions to load the three arguments for the C
 *          dispatcher into the correct registers according to the Windows x64 ABI,
 *          then calls the dispatcher.
 *
 *          The C dispatcher's signature is:
 *          `void fn(infix_reverse_t* context, void* return_value_ptr, void** args_array)`
 *
 *          The generated code performs the following argument setup:
 *          1. `RCX` (Arg 1): The `context` pointer (a 64-bit immediate).
 *          2. `RDX` (Arg 2): The pointer to the return value buffer. This is either a
 *             pointer to local stack space, or the original pointer passed by the
 *             caller in RCX if the function returns a large struct by reference.
 *          3. `R8` (Arg 3): The pointer to the `args_array` on the local stack.
 *          4. The address of the dispatcher function itself is loaded into `R9`,
 *             which is then called.
 * @param buf The code buffer.
 * @param layout The blueprint containing stack offsets.
 * @param context The context, containing the dispatcher's address.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_reverse_dispatcher_call_win_x64(code_buffer * buf,
                                                             infix_reverse_call_frame_layout * layout,
                                                             infix_reverse_t * context) {
    // Arg 1 (RCX): Load the `context` pointer.
    emit_mov_reg_imm64(buf, RCX_REG, (uint64_t)context);
    // Arg 2 (RDX): Load the pointer to the return value buffer.
    if (return_value_is_by_reference(context->return_type))
        // If the return is by reference, the original caller passed the destination
        // pointer in RCX. We saved it in our GPR save area. Load it back now.
        emit_mov_reg_mem(buf, RDX_REG, RSP_REG, layout->gpr_save_area_offset + 0 * 8);
    else
        // Otherwise, the return buffer is on our local stack. Load its address.
        emit_lea_reg_mem(buf, RDX_REG, RSP_REG, layout->return_buffer_offset);
    // Arg 3 (R8): Load the address of the `args_array` on our local stack.
    emit_lea_reg_mem(buf, R8_REG, RSP_REG, layout->args_array_offset);
    // Load the C dispatcher's address into a scratch register (R9) and call it.
    emit_mov_reg_imm64(buf, R9_REG, (uint64_t)context->internal_dispatcher);
    emit_call_reg(buf, R9_REG);
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 5 (Reverse): Generates the epilogue for the reverse trampoline stub.
 * @details After the C dispatcher returns, this code is responsible for the final steps
 *          of the reverse trampoline. It retrieves the return value from the buffer on
 *          the stub's local stack and places it into the correct native return register
 *          (`RAX` or `XMM0`) as required by the Windows x64 ABI.
 *
 *          It then restores the stack pointer using `LEA RSP, [RBP - 16]` to undo the
 *          dynamic alignment performed in the prologue, restores saved registers, and returns.
 *
 * @param buf The code buffer.
 * @param layout The blueprint containing stack offsets.
 * @param context The context containing the return type information.
 * @return `INFIX_SUCCESS`.
 */
static infix_status generate_reverse_epilogue_win_x64(code_buffer * buf,
                                                      infix_reverse_call_frame_layout * layout,
                                                      infix_reverse_t * context) {
    // Handle the return value after the dispatcher returns.
    if (context->return_type->category != INFIX_TYPE_VOID) {
        if (return_value_is_by_reference(context->return_type))
            // The return value was written directly via the hidden pointer.
            // The ABI requires this original pointer (which was in RCX) to be returned in RAX.
            emit_mov_reg_mem(buf, RAX_REG, RSP_REG, layout->gpr_save_area_offset + 0 * 8);
        else {
            // The return value is in our local buffer. Load it into the correct return register.
#if !defined(INFIX_COMPILER_MSVC)
            if (context->return_type->size == 16 && context->return_type->category == INFIX_TYPE_PRIMITIVE)
                // GCC/Clang on Windows returns 128-bit integers and long double in XMM0.
                emit_movups_xmm_mem(buf, XMM0_REG, RSP_REG, layout->return_buffer_offset);
            else
#endif
                if (context->return_type->category == INFIX_TYPE_VECTOR) {
                if (context->return_type->size == 64)
                    emit_vmovupd_zmm_mem(buf, XMM0_REG, RSP_REG, layout->return_buffer_offset);
                else if (context->return_type->size == 32)
                    emit_vmovupd_ymm_mem(buf, XMM0_REG, RSP_REG, layout->return_buffer_offset);
                else  // size 16
                    emit_movups_xmm_mem(buf, XMM0_REG, RSP_REG, layout->return_buffer_offset);
            }
            else if (is_float(context->return_type))
                emit_movss_xmm_mem(buf, XMM0_REG, RSP_REG, layout->return_buffer_offset);
            else if (is_double(context->return_type))
                emit_movsd_xmm_mem(buf, XMM0_REG, RSP_REG, layout->return_buffer_offset);
            else
                // All other by-value types (integers, pointers, small structs) are returned in RAX.
                emit_mov_reg_mem(buf, RAX_REG, RSP_REG, layout->return_buffer_offset);
        }
    }
    // Restore stack pointer to the saved registers area.
    // 2 registers pushed (RSI, RDI) = 16 bytes.
    // LEA RSP, [RBP - 16]
    emit_lea_reg_mem(buf, RSP_REG, RBP_REG, -16);

    emit_pop_reg(buf, RDI_REG);
    emit_pop_reg(buf, RSI_REG);
    emit_pop_reg(buf, RBP_REG);
    emit_ret(buf);
    return INFIX_SUCCESS;
}
/**
 * @internal
 * @brief Stage 1 (Direct): Analyzes a signature and creates a call frame layout for Windows x64.
 * @details This function defines the on-stack layout for a direct marshalling trampoline.
 * It allocates space for outgoing stack arguments, a scratch buffer for each aggregate
 * marshaller, and a temporary save slot for each scalar marshaller.
 */
static infix_status prepare_direct_forward_call_frame_win_x64(infix_arena_t * arena,
                                                              infix_direct_call_frame_layout ** out_layout,
                                                              infix_type * ret_type,
                                                              infix_type ** arg_types,
                                                              size_t num_args,
                                                              infix_direct_arg_handler_t * handlers,
                                                              void * target_fn) {
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
    layout->return_value_in_memory = return_value_is_by_reference(ret_type);

    size_t arg_position = 0;
    if (layout->return_value_in_memory)
        arg_position++;

    size_t outgoing_stack_offset = SHADOW_SPACE;
    size_t temp_space_offset = 0;

    // First pass: Classify ABI locations and calculate required temporary space.
    for (size_t i = 0; i < num_args; ++i) {
        const infix_type * type = arg_types[i];
        layout->args[i].type = type;
        layout->args[i].handler = &handlers[i];

        // Allocate temporary space for this argument's marshalled result.
        if (handlers[i].aggregate_marshaller) {
            temp_space_offset = _infix_align_up(temp_space_offset, type->alignment);
            layout->args[i].location.num_regs = (uint32_t)temp_space_offset;  // Store temp offset in num_regs
            temp_space_offset += type->size;
        }
        else if (handlers[i].scalar_marshaller) {
            temp_space_offset = _infix_align_up(temp_space_offset, 16);
            layout->args[i].location.num_regs = (uint32_t)temp_space_offset;  // Temp save slot for scalar
            temp_space_offset += 16;
        }
        else if (handlers[i].writeback_handler) {  // For out-only parameters
            const infix_type * pointee =
                (type->category == INFIX_TYPE_POINTER) ? type->meta.pointer_info.pointee_type : type;
            temp_space_offset = _infix_align_up(temp_space_offset, pointee->alignment);
            layout->args[i].location.num_regs = (uint32_t)temp_space_offset;
            temp_space_offset += pointee->size;
        }

        // Determine final ABI location.
        bool is_fp = is_float(type) || is_double(type);
        bool by_ref =
            is_passed_by_reference(type) || (type->category == INFIX_TYPE_POINTER && handlers[i].aggregate_marshaller);

        if (arg_position < 4) {
            if (is_fp && !by_ref) {
                layout->args[i].location.type = ARG_LOCATION_XMM;
                layout->args[i].location.reg_index = (uint8_t)arg_position++;
            }
            else {
                layout->args[i].location.type = ARG_LOCATION_GPR;
                layout->args[i].location.reg_index = (uint8_t)arg_position++;
            }
        }
        else
            layout->args[i].location.type = ARG_LOCATION_STACK;
    }

    // Second pass: Calculate final outgoing stack offsets and total allocation size.
    for (size_t i = 0; i < num_args; ++i) {
        if (layout->args[i].location.type == ARG_LOCATION_STACK) {
            const infix_type * type = arg_types[i];
            bool by_ref = is_passed_by_reference(type) ||
                (type->category == INFIX_TYPE_POINTER && handlers[i].aggregate_marshaller);
            // Overwrite the temp offset with the final outgoing offset.
            layout->args[i].location.stack_offset = (uint32_t)outgoing_stack_offset;
            size_t size_on_stack = by_ref ? 8 : ((type->size + 7) & ~7);
            outgoing_stack_offset += size_on_stack;
        }
    }

    // Ensure the base of the scratch area is 16-byte aligned, matching Generate phase logic.
    size_t scratch_base_offset = (outgoing_stack_offset + 15) & ~15;

    size_t total_needed = scratch_base_offset + temp_space_offset;
    layout->total_stack_alloc = (total_needed + 15) & ~15;

    // Final pass: Adjust temp/scratch offsets to be relative to RSP after allocation.
    size_t temp_base_offset = scratch_base_offset;
    for (size_t i = 0; i < num_args; ++i) {
        if (layout->args[i].handler->aggregate_marshaller || layout->args[i].handler->scalar_marshaller ||
            layout->args[i].handler->writeback_handler) {
            layout->args[i].location.num_regs += temp_base_offset;
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
 * @brief Stage 2 (Direct): Generates the function prologue.
 * @details Establishes a stack frame, saves callee-saved registers (R12-R15) for context,
 * moves the direct CIF arguments (`ret_ptr`, `lang_args`) into them, and allocates all
 * stack space required for outgoing arguments, shadow space, and local marshalling buffers.
 *
 * This version uses **forced 16-byte stack alignment** via `AND RSP, -16`.
 */
static infix_status generate_direct_forward_prologue_win_x64(code_buffer * buf,
                                                             infix_direct_call_frame_layout * layout) {
    emit_push_reg(buf, RBP_REG);
    emit_mov_reg_reg(buf, RBP_REG, RSP_REG);
    // Save callee-saved registers we will use for our context.
    emit_push_reg(buf, R12_REG);  // Will hold scratch data
    emit_push_reg(buf, R13_REG);  // Will hold return value pointer
    emit_push_reg(buf, R14_REG);  // Will hold language objects array pointer
    emit_push_reg(buf, R15_REG);  // Will hold target function address

    // FORCE 16-BYTE ALIGNMENT.
    // AND RSP, -16 (48 83 E4 F0)
    EMIT_BYTES(buf, 0x48, 0x83, 0xE4, 0xF0);

    // The direct CIF is called with (ret_ptr, lang_args) in RCX, RDX.
    emit_mov_reg_reg(buf, R13_REG, RCX_REG);  // r13 = ret_ptr
    emit_mov_reg_reg(buf, R14_REG, RDX_REG);  // r14 = lang_objects array

    // Allocate all stack space.
    if (layout->total_stack_alloc > 0)
        emit_sub_reg_imm32(buf, RSP_REG, (int32_t)layout->total_stack_alloc);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 3 (Direct): Generates code to call marshallers and move arguments for Windows x64.
 * @details This corrected implementation uses a two-phase approach for each argument:
 * 1. MARSHALL: Call the user's handler to get the C value into a temporary location
 *    (RAX/XMM0 for scalars, a local stack buffer for aggregates).
 * 2. PLACE: Move the value from its temporary location to its final destination
 *    (the register or stack slot required by the ABI for the target C call).
 * This separation prevents register clobbering and ensures correctness.
 */
static infix_status generate_direct_forward_argument_moves_win_x64(code_buffer * buf,
                                                                   infix_direct_call_frame_layout * layout) {
    // PHASE 1: MARSHALL & SAVE
    for (size_t i = 0; i < layout->num_args; ++i) {
        const infix_direct_arg_layout * arg_layout = &layout->args[i];
        int32_t temp_offset = (int32_t)arg_layout->location.num_regs;

        if (arg_layout->handler->scalar_marshaller || arg_layout->handler->aggregate_marshaller) {

            // Arg 1 (RCX) for marshaller: the language object pointer.
            emit_mov_reg_mem(buf, RCX_REG, R14_REG, i * sizeof(void *));

            if (arg_layout->handler->scalar_marshaller) {
                emit_mov_reg_imm64(buf, R10_REG, (uint64_t)arg_layout->handler->scalar_marshaller);
                emit_call_reg(buf, R10_REG);  // Result is now in RAX or XMM0.

                emit_mov_mem_reg(buf, RSP_REG, temp_offset, RAX_REG);
            }
            else if (arg_layout->handler->aggregate_marshaller) {
                // Arg 2 (RDX): Pointer to our stack buffer for the aggregate.
                emit_lea_reg_mem(buf, RDX_REG, RSP_REG, temp_offset);

                // Arg 3 (R8): The infix_type*.
                emit_mov_reg_imm64(buf, R8_REG, (uint64_t)arg_layout->type);
                emit_mov_reg_imm64(buf, R10_REG, (uint64_t)arg_layout->handler->aggregate_marshaller);
                emit_call_reg(buf, R10_REG);
            }
        }
    }

    // PHASE 2: PLACE
    if (layout->return_value_in_memory)
        emit_mov_reg_reg(buf, RCX_REG, R13_REG);

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
            if (is_passed_by_reference(arg_layout->type) || is_ptr_to_marshalled_agg || is_out_param)
                emit_lea_reg_mem(buf, GPR_ARGS[arg_layout->location.reg_index], RSP_REG, temp_offset);
            else
                emit_mov_reg_mem(buf, GPR_ARGS[arg_layout->location.reg_index], RSP_REG, temp_offset);
            break;

        case ARG_LOCATION_XMM:
            {
                // Load the marshalled double-precision value from our temp slot into a scratch register (XMM15).
                emit_movsd_xmm_mem(buf, XMM15_REG, RSP_REG, temp_offset);

                // If the target C type is actually a float, we must convert the double to a float.
                if (is_float(arg_layout->type))
                    // `cvtsd2ss xmm15, xmm15` : Convert Scalar Double to Scalar Single in place.
                    emit_cvtsd2ss_xmm_xmm(buf, XMM15_REG, XMM15_REG);

                // Now move the correctly-sized value from XMM15 to the final destination register.
                emit_movaps_xmm_xmm(buf, XMM_ARGS[arg_layout->location.reg_index], XMM15_REG);
            }
            break;

        case ARG_LOCATION_STACK:
            {
                int32_t out_stack_offset = (int32_t)arg_layout->location.stack_offset;

                if (is_float(arg_layout->type)) {
                    // Load the double from the temp slot, convert it, then store the single.
                    emit_movsd_xmm_mem(buf, XMM15_REG, RSP_REG, temp_offset);
                    emit_cvtsd2ss_xmm_xmm(buf, XMM15_REG, XMM15_REG);
                    emit_movss_mem_xmm(buf, RSP_REG, out_stack_offset, XMM15_REG);
                }
                else if (!arg_layout->handler->scalar_marshaller && !arg_layout->handler->aggregate_marshaller) {
                    emit_lea_reg_mem(buf, RAX_REG, RSP_REG, temp_offset);
                    emit_mov_mem_reg(buf, RSP_REG, out_stack_offset, RAX_REG);
                }
                else {
                    // All other stack arguments are passed by value (even large ones, by copying).
                    for (size_t offset = 0; offset < arg_layout->type->size; offset += 8) {
                        emit_mov_reg_mem(buf, RAX_REG, RSP_REG, temp_offset + offset);
                        emit_mov_mem_reg(buf, RSP_REG, out_stack_offset + offset, RAX_REG);
                    }
                }
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
 * @brief Stage 3.5 (Direct): Generates the call instruction.
 */
static infix_status generate_direct_forward_call_instruction_win_x64(code_buffer * buf,
                                                                     infix_direct_call_frame_layout * layout) {
    emit_mov_reg_imm64(buf, R15_REG, (uint64_t)layout->target_fn);  // Use R15 for target function
    emit_test_reg_reg(buf, R15_REG, R15_REG);
    emit_jnz_short(buf, 2);
    emit_ud2(buf);
    emit_call_reg(buf, R15_REG);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 4 (Direct): Generates the epilogue, including write-back calls.
 *
 * Uses `LEA RSP, [RBP - 32]` to safely restore the stack pointer.
 */
static infix_status generate_direct_forward_epilogue_win_x64(code_buffer * buf,
                                                             infix_direct_call_frame_layout * layout,
                                                             infix_type * ret_type) {
    // 1. Handle C function's return value.
    if (ret_type->category != INFIX_TYPE_VOID && !layout->return_value_in_memory) {
        if (is_float(ret_type))
            emit_movss_mem_xmm(buf, R13_REG, 0, XMM0_REG);
        else if (is_double(ret_type))
            emit_movsd_mem_xmm(buf, R13_REG, 0, XMM0_REG);
        else if (ret_type->size == 16 &&
                 (ret_type->category == INFIX_TYPE_PRIMITIVE || ret_type->category == INFIX_TYPE_VECTOR))
            // `__int128_t` (on GCC/Clang) and 16-byte vectors are returned in XMM0.
            emit_movups_mem_xmm(buf, R13_REG, 0, XMM0_REG);
        else if (ret_type->size == 32 && ret_type->category == INFIX_TYPE_VECTOR)
            emit_vmovupd_mem_ymm(buf, R13_REG, 0, XMM0_REG);
        else if (ret_type->size == 64 && ret_type->category == INFIX_TYPE_VECTOR)
            emit_vmovupd_mem_zmm(buf, R13_REG, 0, XMM0_REG);
        else {
            // All other by-value types are returned in RAX. Use a size-appropriate store.
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
            case 8:
                emit_mov_mem_reg(buf, R13_REG, 0, RAX_REG);
                break;
            default:
                break;
            }
        }
    }

    // 2. Call Write-Back Handlers
    for (size_t i = 0; i < layout->num_args; ++i) {
        const infix_direct_arg_layout * arg_layout = &layout->args[i];
        if (arg_layout->handler->writeback_handler) {
            emit_sub_reg_imm32(buf, RSP_REG, 48);
            emit_mov_mem_reg(buf, RSP_REG, 32, RAX_REG);
            emit_movsd_mem_xmm(buf, RSP_REG, 40, XMM0_REG);

            emit_mov_reg_mem(buf, RCX_REG, R14_REG, i * sizeof(void *));

            int32_t temp_offset = (int32_t)arg_layout->location.num_regs;
            emit_lea_reg_mem(buf, RDX_REG, RSP_REG, temp_offset + 48);

            emit_mov_reg_imm64(buf, R8_REG, (uint64_t)arg_layout->type);

            emit_mov_reg_imm64(buf, R10_REG, (uint64_t)arg_layout->handler->writeback_handler);
            emit_call_reg(buf, R10_REG);

            emit_mov_reg_mem(buf, RAX_REG, RSP_REG, 32);
            emit_movsd_xmm_mem(buf, XMM0_REG, RSP_REG, 40);
            emit_add_reg_imm32(buf, RSP_REG, 48);
        }
    }

    // 3. Safe Epilogue
    // Restore stack pointer to the saved registers area.
    // 4 registers pushed (R12, R13, R14, R15) = 32 bytes.
    // LEA RSP, [RBP - 32]
    emit_lea_reg_mem(buf, RSP_REG, RBP_REG, -32);

    emit_pop_reg(buf, R15_REG);
    emit_pop_reg(buf, R14_REG);
    emit_pop_reg(buf, R13_REG);
    emit_pop_reg(buf, R12_REG);
    emit_pop_reg(buf, RBP_REG);
    emit_ret(buf);

    return INFIX_SUCCESS;
}

#ifdef _MSC_VER
#pragma warning(pop)
#endif
