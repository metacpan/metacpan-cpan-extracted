/**
 * Copyright (c) 2026 Sanko Robinson
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
 * @file abi_riscv64.c
 * @brief Implements the FFI logic for the RISC-V RV64GC (lp64d) architecture.
 * @ingroup internal_abi_riscv64
 *
 * @internal
 * This file provides the concrete implementation of the `infix_forward_abi_spec`,
 * `infix_reverse_abi_spec`, and `infix_direct_forward_abi_spec` for the RISC-V
 * RV64 64-bit base integer + IEEE double-precision floating-point ABI (LP64D).
 * It follows the ratified "RISC-V ELF psABI Specification" (v1.0).
 *
 * @section riscv64_rules Key RISC-V psABI Rules Implemented
 *
 * - **Register Usage:**
 *   - The first 8 integer/pointer arguments are passed in GPRs (a0-a7).
 *   - The first 8 floating-point arguments are passed in FPRs (fa0-fa7).
 *
 * - **Scalar Classification:**
 *   - `float`/`double` scalars are passed in FPRs.
 *   - 2xXLEN (16-byte) integer scalars and aggregates are passed in an even-aligned
 *     GPR pair (aN/aN+1). There is no register/stack split on RISC-V.
 *   - 2xXLEN (16-byte) floating-point scalars (`long double`) are passed in an
 *     even-aligned FPR pair.
 *
 * - **Aggregate Classification:**
 *   - Aggregates larger than 2xXLEN (16 bytes) are passed by reference (a pointer
 *     in a GPR). Larger return values are returned via a hidden pointer in a0.
 *   - Aggregates of at most 2xXLEN bits containing only floating-point members are
 *     passed in FPRs, one FPR per member, in order.
 *   - All other aggregates are passed in GPRs.
 *
 * - **Variadic Calls:**
 *   - Variadic arguments use the integer calling convention: floats and doubles are
 *     passed in GPRs, not FPRs.
 *   - Once any variadic argument has been placed on the stack, all subsequent
 *     variadic arguments are passed on the stack.
 *
 * - **Return Values:**
 *   - Scalars, 2xXLEN scalars, and aggregates up to 16 bytes are returned in
 *     registers (a0/a1, fa0/fa1). Larger aggregates use the memory strategy.
 *
 * - **Stack Alignment:** The stack pointer is always 16-byte aligned; stack argument
 *   slots are 8-byte wide (16-byte arguments are 16-byte aligned).
 * @endinternal
 */
#include "arch/riscv/abi_riscv64_common.h"
#include "arch/riscv/abi_riscv64_emitters.h"
#include "common/infix_internals.h"
#include "common/utility.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

/** @internal The GPRs used for the first 8 integer/pointer arguments (a0-a7). */
static const riscv_gpr GPR_ARGS[] = {X_A0_REG, X_A1_REG, X_A2_REG, X_A3_REG, X_A4_REG, X_A5_REG, X_A6_REG, X_A7_REG};
/** @internal The FPRs used for the first 8 floating-point arguments (fa0-fa7). */
static const riscv_fpr FPR_ARGS[] = {
    F_FA0_REG, F_FA1_REG, F_FA2_REG, F_FA3_REG, F_FA4_REG, F_FA5_REG, F_FA6_REG, F_FA7_REG};
/** @internal The number of GPRs available for argument passing. */
#define RV_NUM_GPR_ARGS 8
/** @internal The number of FPRs available for argument passing. */
#define RV_NUM_FPR_ARGS 8
/** @internal A safety limit on the number of FP members to classify in an aggregate. */
#define RV_MAX_FLATTENED_FIELDS 32
/** @internal A safety limit on the recursion depth when flattening an aggregate. */
#define RV_MAX_FLATTEN_DEPTH 32
/** @internal Stack space reserved for the three callee-saved context registers (s1/s2/s3). */
#define RV_FWD_SAVED_SIZE 32
/** @internal Stack space reserved for the saved return address in a reverse stub. */
#define RV_REV_SAVED_SIZE 16

/** @internal The classification result for a single argument. */
typedef struct {
    infix_arg_location_type type; /**< The physical location (GPR/FPR/Pair/Stack). */
    uint8_t reg_index;            /**< The first register used (GPR base for MIXED). */
    uint8_t reg_index2;           /**< The second register (FPR base for MIXED). */
    uint32_t num_regs;            /**< Number of registers (for FPR aggregates / 2xXLEN). */
    uint32_t stack_offset;        /**< Byte offset from the stack pointer. */
} rv64_arg_class;

/** @internal The v-table of RISC-V functions for generating forward trampolines. */
static infix_status prepare_forward_call_frame_riscv64(infix_arena_t * arena,
                                                       infix_call_frame_layout ** out_layout,
                                                       infix_type * ret_type,
                                                       infix_type ** arg_types,
                                                       size_t num_args,
                                                       size_t num_fixed_args,
                                                       void * target_fn);
static infix_status generate_forward_prologue_riscv64(code_buffer * buf, infix_call_frame_layout * layout);
static infix_status generate_forward_argument_moves_riscv64(code_buffer * buf,
                                                            infix_call_frame_layout * layout,
                                                            infix_type ** arg_types,
                                                            size_t num_args,
                                                            c23_maybe_unused size_t num_fixed_args);
static infix_status generate_forward_call_instruction_riscv64(code_buffer *, infix_call_frame_layout *);
static infix_status generate_forward_epilogue_riscv64(code_buffer * buf,
                                                      infix_call_frame_layout * layout,
                                                      infix_type * ret_type);
const infix_forward_abi_spec g_riscv64_forward_spec = {
    .prepare_forward_call_frame = prepare_forward_call_frame_riscv64,
    .generate_forward_prologue = generate_forward_prologue_riscv64,
    .generate_forward_argument_moves = generate_forward_argument_moves_riscv64,
    .generate_forward_call_instruction = generate_forward_call_instruction_riscv64,
    .generate_forward_epilogue = generate_forward_epilogue_riscv64};

/** @internal The v-table of RISC-V functions for generating reverse trampolines. */
static infix_status prepare_reverse_call_frame_riscv64(infix_arena_t * arena,
                                                       infix_reverse_call_frame_layout ** out_layout,
                                                       infix_reverse_t * context);
static infix_status generate_reverse_prologue_riscv64(code_buffer * buf, infix_reverse_call_frame_layout * layout);
static infix_status generate_reverse_argument_marshalling_riscv64(code_buffer * buf,
                                                                  infix_reverse_call_frame_layout * layout,
                                                                  infix_reverse_t * context);
static infix_status generate_reverse_dispatcher_call_riscv64(code_buffer * buf,
                                                             infix_reverse_call_frame_layout * layout,
                                                             infix_reverse_t * context);
static infix_status generate_reverse_epilogue_riscv64(code_buffer * buf,
                                                      infix_reverse_call_frame_layout * layout,
                                                      infix_reverse_t * context);
const infix_reverse_abi_spec g_riscv64_reverse_spec = {
    .prepare_reverse_call_frame = prepare_reverse_call_frame_riscv64,
    .generate_reverse_prologue = generate_reverse_prologue_riscv64,
    .generate_reverse_argument_marshalling = generate_reverse_argument_marshalling_riscv64,
    .generate_reverse_dispatcher_call = generate_reverse_dispatcher_call_riscv64,
    .generate_reverse_epilogue = generate_reverse_epilogue_riscv64};

/** @internal The v-table for the new Direct Marshalling ABI. */
static infix_status prepare_direct_forward_call_frame_riscv64(infix_arena_t * arena,
                                                              infix_direct_call_frame_layout ** out_layout,
                                                              infix_type * ret_type,
                                                              infix_type ** arg_types,
                                                              size_t num_args,
                                                              infix_direct_arg_handler_t * handlers,
                                                              void * target_fn);
static infix_status generate_direct_forward_prologue_riscv64(code_buffer * buf,
                                                             infix_direct_call_frame_layout * layout);
static infix_status generate_direct_forward_argument_moves_riscv64(code_buffer * buf,
                                                                   infix_direct_call_frame_layout * layout);
static infix_status generate_direct_forward_call_instruction_riscv64(code_buffer * buf,
                                                                     infix_direct_call_frame_layout * layout);
static infix_status generate_direct_forward_epilogue_riscv64(code_buffer * buf,
                                                             infix_direct_call_frame_layout * layout,
                                                             infix_type * ret_type);
const infix_direct_forward_abi_spec g_riscv64_direct_forward_spec = {
    .prepare_direct_forward_call_frame = prepare_direct_forward_call_frame_riscv64,
    .generate_direct_forward_prologue = generate_direct_forward_prologue_riscv64,
    .generate_direct_forward_argument_moves = generate_direct_forward_argument_moves_riscv64,
    .generate_direct_forward_call_instruction = generate_direct_forward_call_instruction_riscv64,
    .generate_direct_forward_epilogue = generate_direct_forward_epilogue_riscv64};

//
// Low-level helpers
//

/**
 * @internal
 * @brief Emit `rd = rs_base + offset`, materializing the offset via the `li` expansion
 *        when it does not fit in a 12-bit immediate.
 */
static void rv64_emit_compute_addr(code_buffer * buf, uint8_t rd, uint8_t rs_base, int32_t offset) {
    if (offset >= -2048 && offset <= 2047) {
        infix_riscv64_emit_addi(buf, rd, rs_base, offset);
        return;
    }
    infix_riscv64_emit_load_u64_immediate(buf, rd, (uint64_t)(int64_t)offset);
    infix_riscv64_emit_add(buf, rd, rs_base, rd);
}

/** @internal Wide-offset `ld rd, offset(rs_base)`. */
static void rv64_mem_ld(code_buffer * buf, uint8_t rd, uint8_t rs_base, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_ld(buf, rd, rs_base, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_ld(buf, rd, RV_SCRATCH0_REG, 0);
}

/** @internal Wide-offset `sd data, offset(rs_base)`. */
static void rv64_mem_sd(code_buffer * buf, uint8_t rs_base, uint8_t data, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_sd(buf, rs_base, data, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_sd(buf, RV_SCRATCH0_REG, data, 0);
}

/** @internal Wide-offset `lw rd, offset(rs_base)`. */
static void rv64_mem_lw(code_buffer * buf, uint8_t rd, uint8_t rs_base, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_lw(buf, rd, rs_base, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_lw(buf, rd, RV_SCRATCH0_REG, 0);
}

/** @internal Wide-offset `sw data, offset(rs_base)`. */
static void rv64_mem_sw(code_buffer * buf, uint8_t rs_base, uint8_t data, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_sw(buf, rs_base, data, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_sw(buf, RV_SCRATCH0_REG, data, 0);
}

/** @internal Wide-offset `lbu rd, offset(rs_base)`. */
static void rv64_mem_lbu(code_buffer * buf, uint8_t rd, uint8_t rs_base, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_lbu(buf, rd, rs_base, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_lbu(buf, rd, RV_SCRATCH0_REG, 0);
}

/** @internal Wide-offset `lhu rd, offset(rs_base)`. */
static void rv64_mem_lhu(code_buffer * buf, uint8_t rd, uint8_t rs_base, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_lhu(buf, rd, rs_base, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_lhu(buf, rd, RV_SCRATCH0_REG, 0);
}

/** @internal Wide-offset `sb data, offset(rs_base)`. */
static void rv64_mem_sb(code_buffer * buf, uint8_t rs_base, uint8_t data, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_sb(buf, rs_base, data, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_sb(buf, RV_SCRATCH0_REG, data, 0);
}

/** @internal Wide-offset `sh data, offset(rs_base)`. */
static void rv64_mem_sh(code_buffer * buf, uint8_t rs_base, uint8_t data, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_sh(buf, rs_base, data, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_sh(buf, RV_SCRATCH0_REG, data, 0);
}

/** @internal Wide-offset `fld rd, offset(rs_base)`. */
static void rv64_mem_fld(code_buffer * buf, uint8_t rd, uint8_t rs_base, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_fld(buf, rd, rs_base, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_fld(buf, rd, RV_SCRATCH0_REG, 0);
}

/** @internal Wide-offset `fsd data, offset(rs_base)`. */
static void rv64_mem_fsd(code_buffer * buf, uint8_t rs_base, uint8_t data, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_fsd(buf, rs_base, data, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_fsd(buf, RV_SCRATCH0_REG, data, 0);
}

/** @internal Wide-offset `flw rd, offset(rs_base)`. */
static void rv64_mem_flw(code_buffer * buf, uint8_t rd, uint8_t rs_base, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_flw(buf, rd, rs_base, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_flw(buf, rd, RV_SCRATCH0_REG, 0);
}

/** @internal Wide-offset `fsw data, offset(rs_base)`. */
static void rv64_mem_fsw(code_buffer * buf, uint8_t rs_base, uint8_t data, int32_t off) {
    if (off >= -2048 && off <= 2047) {
        infix_riscv64_emit_fsw(buf, rs_base, data, off);
        return;
    }
    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, rs_base, off);
    infix_riscv64_emit_fsw(buf, RV_SCRATCH0_REG, data, 0);
}

/** @internal Decrement the stack pointer by an arbitrary (16-byte aligned) amount. */
static void rv64_emit_stack_sub(code_buffer * buf, uint32_t amount) {
    if (amount == 0)
        return;
    if (amount <= 2047) {
        infix_riscv64_emit_addi(buf, X_SP_REG, X_SP_REG, -(int32_t)amount);
        return;
    }
    infix_riscv64_emit_load_u64_immediate(buf, RV_SCRATCH0_REG, (uint64_t)(-(int64_t)amount));
    infix_riscv64_emit_add(buf, X_SP_REG, X_SP_REG, RV_SCRATCH0_REG);
}

/** @internal Increment the stack pointer by an arbitrary (16-byte aligned) amount. */
static void rv64_emit_stack_add(code_buffer * buf, uint32_t amount) {
    if (amount == 0)
        return;
    if (amount <= 2047) {
        infix_riscv64_emit_addi(buf, X_SP_REG, X_SP_REG, (int32_t)amount);
        return;
    }
    infix_riscv64_emit_load_u64_immediate(buf, RV_SCRATCH0_REG, (uint64_t)amount);
    infix_riscv64_emit_add(buf, X_SP_REG, X_SP_REG, RV_SCRATCH0_REG);
}

/**
 * @internal
 * @brief Load an integer scalar of an explicit size from memory, applying the RISC-V
 *        sub-XLEN extension rules.
 */
static void rv64_emit_load_gpr_value_sized(
    code_buffer * buf, uint8_t rd, uint8_t addr_reg, size_t size, bool is_signed) {
    if (size == 1)
        if (is_signed)
            infix_riscv64_emit_lb(buf, rd, addr_reg, 0);
        else
            infix_riscv64_emit_lbu(buf, rd, addr_reg, 0);
    else if (size == 2)
        if (is_signed)
            infix_riscv64_emit_lh(buf, rd, addr_reg, 0);
        else
            infix_riscv64_emit_lhu(buf, rd, addr_reg, 0);
    else if (size <= 4)
        if (is_signed)
            infix_riscv64_emit_lw(buf, rd, addr_reg, 0);
        else
            infix_riscv64_emit_lwu(buf, rd, addr_reg, 0);
    else
        infix_riscv64_emit_ld(buf, rd, addr_reg, 0);
}

/**
 * @internal
 * @brief Load a scalar from memory, applying the RISC-V sub-XLEN extension rules.
 * @details Signed primitives are sign-extended (lb/lh/lw); unsigned primitives and
 *          small aggregates are zero-extended (lbu/lhu/lwu); 8-byte values use `ld`.
 */
static void rv64_emit_load_gpr_value(code_buffer * buf, uint8_t rd, uint8_t addr_reg, const infix_type * type) {
    bool is_signed_lt_64 = type->category == INFIX_TYPE_PRIMITIVE && type->size < 8 &&
        (type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 || type->meta.primitive_id == INFIX_PRIMITIVE_SINT16 ||
         type->meta.primitive_id == INFIX_PRIMITIVE_SINT32);
    rv64_emit_load_gpr_value_sized(buf, rd, addr_reg, type->size, is_signed_lt_64);
}

/**
 * @internal
 * @brief Copy raw memory in 8-byte chunks with an exact-byte tail.
 * @param dst_base The base register of the destination address.
 * @param dst_off The destination offset.
 * @param src_base The base register of the source address.
 * @param src_off The source offset.
 * @param size The number of bytes to copy.
 */
static void rv64_emit_copy_memory(
    code_buffer * buf, uint8_t dst_base, int32_t dst_off, uint8_t src_base, int32_t src_off, size_t size) {
    size_t remaining = size;
    int32_t so = src_off;
    int32_t doff = dst_off;
    while (remaining >= 8) {
        rv64_mem_ld(buf, RV_SCRATCH1_REG, src_base, so);
        rv64_mem_sd(buf, dst_base, RV_SCRATCH1_REG, doff);
        so += 8;
        doff += 8;
        remaining -= 8;
    }
    if (remaining & 4) {
        rv64_mem_lw(buf, RV_SCRATCH1_REG, src_base, so);
        rv64_mem_sw(buf, dst_base, RV_SCRATCH1_REG, doff);
        so += 4;
        doff += 4;
        remaining -= 4;
    }
    if (remaining & 2) {
        rv64_mem_lhu(buf, RV_SCRATCH1_REG, src_base, so);
        rv64_mem_sh(buf, dst_base, RV_SCRATCH1_REG, doff);
        so += 2;
        doff += 2;
        remaining -= 2;
    }
    if (remaining & 1) {
        rv64_mem_lbu(buf, RV_SCRATCH1_REG, src_base, so);
        rv64_mem_sb(buf, dst_base, RV_SCRATCH1_REG, doff);
    }
}

/**
 * @internal
 * @brief Store the low `size` bytes of register `rd` into memory, shifting the
 *        register as needed for non-power-of-2 sizes.
 */
static void rv64_emit_store_gpr_low_bytes(code_buffer * buf, uint8_t base, uint8_t rd, int32_t off, size_t size) {
    size_t o = 0;
    size_t remaining = size;
    while (remaining >= 8) {
        rv64_mem_sd(buf, base, rd, off + (int32_t)o);
        o += 8;
        remaining -= 8;
    }
    if (remaining & 4) {
        if (o > 0)
            infix_riscv64_emit_srli(buf, RV_SCRATCH1_REG, rd, (uint8_t)(o * 8));
        rv64_mem_sw(buf, base, o > 0 ? RV_SCRATCH1_REG : rd, off + (int32_t)o);
        o += 4;
        remaining -= 4;
    }
    if (remaining & 2) {
        if (o > 0)
            infix_riscv64_emit_srli(buf, RV_SCRATCH1_REG, rd, (uint8_t)(o * 8));
        rv64_mem_sh(buf, base, o > 0 ? RV_SCRATCH1_REG : rd, off + (int32_t)o);
        o += 2;
        remaining -= 2;
    }
    if (remaining & 1) {
        if (o > 0)
            infix_riscv64_emit_srli(buf, RV_SCRATCH1_REG, rd, (uint8_t)(o * 8));
        rv64_mem_sb(buf, base, o > 0 ? RV_SCRATCH1_REG : rd, off + (int32_t)o);
    }
}

/**
 * @internal
 * @brief Store the integer return value held in a0/a1 into the return buffer.
 * @details Bytes 0-7 come from a0; bytes 8-15 from a1 (for sizes 9-16).
 */
static void rv64_emit_store_gpr_return(code_buffer * buf, uint8_t base, size_t size) {
    if (size <= 8) {
        rv64_emit_store_gpr_low_bytes(buf, base, X_A0_REG, 0, size);
        return;
    }
    rv64_mem_sd(buf, base, X_A0_REG, 0);
    rv64_emit_store_gpr_low_bytes(buf, base, X_A1_REG, 8, size - 8);
}

/** @internal Store a 4/8-byte floating-point value from an FPR into memory. */
static void rv64_emit_store_fp_value(code_buffer * buf, uint8_t base, uint8_t fa, int32_t off, size_t size) {
    if (size == 8)
        rv64_mem_fsd(buf, base, fa, off);
    else if (size == 4)
        rv64_mem_fsw(buf, base, fa, off);
}

/** @internal Load a 4/8-byte floating-point value from memory into an FPR. */
static void rv64_emit_load_fp_value(code_buffer * buf, uint8_t base, uint8_t fa, int32_t off, size_t size) {
    if (size == 8)
        rv64_mem_fld(buf, fa, base, off);
    else if (size == 4)
        rv64_mem_flw(buf, fa, base, off);
}

//
// Classification
//

/** @internal A single scalar leaf of an aggregate, in struct order. */
typedef struct {
    size_t offset;  /**< Byte offset of the leaf within the aggregate. */
    size_t size;    /**< Leaf size in bytes (1, 2, 4, 8 or 16 for a long double). */
    bool is_fp;     /**< `true` if the leaf is a `float`/`double` scalar. */
    bool is_signed; /**< `true` for signed primitive integer leaves narrower than XLEN. */
} rv64_all_leaf;

/** @internal A flattened, in-order list of every scalar leaf of an aggregate. */
typedef struct {
    size_t count;
    rv64_all_leaf leaves[RV_MAX_FLATTENED_FIELDS];
} rv64_all_leaf_list;

/**
 * @internal
 * @brief Recursively flatten every scalar leaf of an aggregate (structs and arrays).
 * @details Unions are not flattened; `_Complex` types expand into two leaves of the
 *          component type. Returns `false` if a leaf exceeds the leaf-table capacity,
 *          the type graph is pathologically deep, or a malformed (null) node is reached.
 */
static bool rv64_flatten_all_recursive(const infix_type * type,
                                       size_t base_offset,
                                       rv64_all_leaf_list * out,
                                       size_t depth) {
    // A recursive call can be made with a NULL type from a malformed aggregate.
    if (type == nullptr)
        return false;  // Terminate this recursion path.
    // Give up on pathologically deep type graphs instead of exhausting the stack.
    if (depth > RV_MAX_FLATTEN_DEPTH)
        return false;
    if (type->category == INFIX_TYPE_STRUCT) {
        if (type->meta.aggregate_info.members == nullptr)
            return false;
        for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
            const infix_struct_member * member = &type->meta.aggregate_info.members[i];
            if (member->type == nullptr)
                return false;
            // Check the leaf-table capacity before descending any further.
            if (out->count >= RV_MAX_FLATTENED_FIELDS)
                return false;
            if (!rv64_flatten_all_recursive(member->type, base_offset + member->offset, out, depth + 1))
                return false;
        }
        return true;
    }
    if (type->category == INFIX_TYPE_ARRAY) {
        if (type->meta.array_info.element_type == nullptr)
            return false;
        // A zero-sized element never advances the offset, so iterating every
        // element is pointless and, for chains like `a[127][127][...][0]`,
        // explodes exponentially without ever producing a leaf (which would
        // otherwise trip the leaf-table capacity guard). Flatten the element
        // type just once at the starting offset.
        if (type->meta.array_info.element_type->size == 0) {
            if (type->meta.array_info.num_elements > 0)
                return rv64_flatten_all_recursive(type->meta.array_info.element_type, base_offset, out, depth + 1);
            return true;  // An empty array has no effect on the leaf list.
        }
        for (size_t i = 0; i < type->meta.array_info.num_elements; ++i) {
            // Check the leaf-table capacity before each recursive call.
            if (out->count >= RV_MAX_FLATTENED_FIELDS)
                return false;
            if (!rv64_flatten_all_recursive(type->meta.array_info.element_type,
                                            base_offset + i * type->meta.array_info.element_type->size,
                                            out,
                                            depth + 1))
                return false;
        }
        return true;
    }
    if (type->category == INFIX_TYPE_COMPLEX) {
        // `_Complex double` is the two FP scalars {real, imag}.
        size_t comp_size = type->meta.complex_info.base_type ? type->meta.complex_info.base_type->size : type->size / 2;
        if (out->count + 2 > RV_MAX_FLATTENED_FIELDS)
            return false;
        out->leaves[out->count++] = (rv64_all_leaf){base_offset, comp_size, true, false};
        out->leaves[out->count++] = (rv64_all_leaf){base_offset + comp_size, comp_size, true, false};
        return true;
    }
    if (out->count >= RV_MAX_FLATTENED_FIELDS)
        return false;
    bool is_signed = type->category == INFIX_TYPE_PRIMITIVE && type->size < 8 &&
        (type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 || type->meta.primitive_id == INFIX_PRIMITIVE_SINT16 ||
         type->meta.primitive_id == INFIX_PRIMITIVE_SINT32);
    out->leaves[out->count++] = (rv64_all_leaf){base_offset, type->size, is_float(type) || is_double(type), is_signed};
    return true;
}

/**
 * @internal
 * @brief Flatten an aggregate (or a scalar leaf list) into every scalar leaf.
 * @return `true` on success. A scalar type yields a single leaf.
 */
static bool rv64_flatten_all(const infix_type * type, rv64_all_leaf_list * out) {
    out->count = 0;
    return rv64_flatten_all_recursive(type, 0, out, 0);
}

/**
 * @internal
 * @brief Load an aggregate's floating-point leaves into consecutive FPRs.
 * @details A 16-byte FP leaf (long double) consumes two FPRs; smaller leaves one.
 */
static void rv64_emit_load_fp_aggregate(code_buffer * buf,
                                        uint8_t addr_reg,
                                        uint8_t base_fpr,
                                        const infix_type * type) {
    rv64_all_leaf_list leaves;
    if (!rv64_flatten_all(type, &leaves))
        return;
    uint8_t fpr = base_fpr;
    for (size_t j = 0; j < leaves.count; ++j) {
        const rv64_all_leaf * leaf = &leaves.leaves[j];
        if (leaf->is_fp) {
            if (leaf->size >= 16) {
                rv64_mem_fld(buf, fpr, addr_reg, (int32_t)leaf->offset);
                rv64_mem_fld(buf, fpr + 1, addr_reg, (int32_t)(leaf->offset + 8));
                fpr += 2;
            }
            else {
                rv64_emit_load_fp_value(buf, addr_reg, fpr++, (int32_t)leaf->offset, leaf->size);
            }
        }
    }
}

/**
 * @internal
 * @brief Store consecutive FPRs into an aggregate's floating-point leaves.
 */
static void rv64_emit_store_fp_aggregate(code_buffer * buf,
                                         uint8_t addr_reg,
                                         uint8_t base_fpr,
                                         const infix_type * type) {
    rv64_all_leaf_list leaves;
    if (!rv64_flatten_all(type, &leaves))
        return;
    uint8_t fpr = base_fpr;
    for (size_t j = 0; j < leaves.count; ++j) {
        const rv64_all_leaf * leaf = &leaves.leaves[j];
        if (leaf->is_fp) {
            if (leaf->size >= 16) {
                rv64_mem_fsd(buf, addr_reg, fpr, (int32_t)leaf->offset);
                rv64_mem_fsd(buf, addr_reg, fpr + 1, (int32_t)(leaf->offset + 8));
                fpr += 2;
            }
            else {
                rv64_emit_store_fp_value(buf, addr_reg, fpr++, (int32_t)leaf->offset, leaf->size);
            }
        }
    }
}

/**
 * @internal
 * @brief Load the integer (GPR) and FP (FPR) leaves of a mixed aggregate.
 * @details The integer leaf is extended into the GPR per its width; the FP leaf
 *          is loaded as-is. GPR leaf index is `reg_index`, FPR leaf `reg_index2`.
 */
static void rv64_emit_load_mixed(
    code_buffer * buf, uint8_t addr_reg, uint8_t gpr_reg, uint8_t fpr_reg, const infix_type * type) {
    rv64_all_leaf_list leaves;
    if (!rv64_flatten_all(type, &leaves))
        return;
    for (size_t j = 0; j < leaves.count; ++j) {
        const rv64_all_leaf * leaf = &leaves.leaves[j];
        if (leaf->is_fp)
            rv64_emit_load_fp_value(buf, addr_reg, fpr_reg, (int32_t)leaf->offset, leaf->size);
        else
            rv64_emit_load_gpr_value_sized(buf, gpr_reg, addr_reg, leaf->size, leaf->is_signed);
    }
}

/**
 * @internal
 * @brief Store the GPR and FPR leaves of a mixed aggregate back to memory.
 * @details The integer leaf is stored at its natural width so it never clobbers
 *          the FP leaf when the leaves share bytes of an 8-byte word.
 */
static void rv64_emit_store_mixed(
    code_buffer * buf, uint8_t addr_reg, uint8_t gpr_reg, uint8_t fpr_reg, const infix_type * type) {
    rv64_all_leaf_list leaves;
    if (!rv64_flatten_all(type, &leaves))
        return;
    for (size_t j = 0; j < leaves.count; ++j) {
        const rv64_all_leaf * leaf = &leaves.leaves[j];
        if (leaf->is_fp)
            rv64_emit_store_fp_value(buf, addr_reg, fpr_reg, (int32_t)leaf->offset, leaf->size);
        else
            rv64_emit_store_gpr_low_bytes(buf, addr_reg, gpr_reg, (int32_t)leaf->offset, leaf->size);
    }
}

/**
 * @internal
 * @brief Describes how a return value is delivered, mirroring the psABI's
 *        "returned the same way as a first named argument" rule.
 */
typedef struct {
    bool sret;             /**< Returned via a hidden pointer in a0 (return value in memory). */
    bool mixed;            /**< One integer leaf in a0 and one FP leaf in fa0. */
    uint8_t fp_count;      /**< FP leaves returned in fa0.. (0, 1 or 2). */
    uint8_t gpr_count;     /**< GPR leaves returned in a0.. (1 or 2 for integer CC returns). */
    int32_t fp_offsets[2]; /**< Offsets of the FP leaves within the return value. */
    size_t fp_sizes[2];    /**< Sizes of the FP leaves (4 or 8). */
    int32_t int_offset;    /**< Offset of the integer leaf (mixed returns). */
    size_t int_size;       /**< Size of the integer leaf (mixed returns). */
    bool int_signed;       /**< Whether the integer leaf is a signed primitive (mixed returns). */
} rv64_return_class;

/**
 * @internal
 * @brief Returns `true` if a return value must be passed by reference.
 * @details Aggregates larger than 2xXLEN (16 bytes) are returned via a hidden
 *          pointer passed in a0; everything else is returned in registers.
 */
static bool rv64_return_in_memory(const infix_type * type) {
    if (type->category != INFIX_TYPE_STRUCT && type->category != INFIX_TYPE_UNION &&
        type->category != INFIX_TYPE_ARRAY && type->category != INFIX_TYPE_COMPLEX)
        return false;
    return type->size > 16;
}

/**
 * @internal
 * @brief Classify a return type into its register/memory delivery plan.
 * @details Follows the psABI hardware floating-point calling convention: a scalar
 *          FP real returns in fa0, `_Complex` and two-FP aggregates in fa0/fa1,
 *          one-FP-one-integer aggregates in fa0+a0, and everything else through the
 *          integer convention (a0 or the a0/a1 pair). Aggregates wider than 2xXLEN
 *          are returned in memory via a hidden sret pointer.
 */
static rv64_return_class rv64_classify_return(const infix_type * type) {
    rv64_return_class rc;
    memset(&rc, 0, sizeof(rc));
    if (type->category == INFIX_TYPE_VOID)
        return rc;
    if (rv64_return_in_memory(type)) {
        rc.sret = true;
        return rc;
    }
    if (is_float(type) || is_double(type)) {
        rc.fp_count = 1;
        rc.fp_offsets[0] = 0;
        rc.fp_sizes[0] = type->size;
        return rc;
    }
    if (type->category == INFIX_TYPE_PRIMITIVE || type->category == INFIX_TYPE_POINTER ||
        type->category == INFIX_TYPE_ENUM || type->category == INFIX_TYPE_UNION) {
        rc.gpr_count = (type->size <= 8) ? 1 : 2;
        return rc;
    }
    if (type->category == INFIX_TYPE_STRUCT || type->category == INFIX_TYPE_COMPLEX) {
        rv64_all_leaf_list leaves;
        if (rv64_flatten_all(type, &leaves) && leaves.count <= 2) {
            size_t fp = 0;
            size_t fp_idx[2] = {SIZE_MAX, SIZE_MAX};
            size_t int_idx = SIZE_MAX;
            for (size_t j = 0; j < leaves.count; ++j) {
                const rv64_all_leaf * leaf = &leaves.leaves[j];
                if (leaf->is_fp && leaf->size <= 8)
                    fp_idx[fp++] = j;
                else if (!leaf->is_fp && leaf->size <= 8)
                    int_idx = j;
            }
            if (fp == 1 && int_idx != SIZE_MAX) {
                rc.mixed = true;
                rc.fp_count = 1;
                rc.gpr_count = 1;
                rc.fp_offsets[0] = (int32_t)leaves.leaves[fp_idx[0]].offset;
                rc.fp_sizes[0] = leaves.leaves[fp_idx[0]].size;
                rc.int_offset = (int32_t)leaves.leaves[int_idx].offset;
                rc.int_size = leaves.leaves[int_idx].size;
                rc.int_signed = leaves.leaves[int_idx].is_signed;
                return rc;
            }
            if (fp == 2 && int_idx == SIZE_MAX) {
                rc.fp_count = 2;
                rc.fp_offsets[0] = (int32_t)leaves.leaves[fp_idx[0]].offset;
                rc.fp_offsets[1] = (int32_t)leaves.leaves[fp_idx[1]].offset;
                rc.fp_sizes[0] = leaves.leaves[fp_idx[0]].size;
                rc.fp_sizes[1] = leaves.leaves[fp_idx[1]].size;
                return rc;
            }
            if (fp == 1 && int_idx == SIZE_MAX && leaves.count == 1) {
                rc.fp_count = 1;
                rc.fp_offsets[0] = (int32_t)leaves.leaves[fp_idx[0]].offset;
                rc.fp_sizes[0] = leaves.leaves[fp_idx[0]].size;
                return rc;
            }
        }
        // Everything else (4-float structs, {long double}, 3+ leaf structs) is integer CC.
        rc.gpr_count = (type->size <= 8) ? 1 : 2;
        return rc;
    }
    rc.gpr_count = (type->size <= 8) ? 1 : 2;
    return rc;
}

/**
 * @internal
 * @brief Place an argument on the stack following the RISC-V psABI rules.
 * @details Stack slots are 8-byte wide and aligned to the greater of the type's
 *          alignment and XLEN (capped at the 16-byte stack alignment).
 */
static uint32_t rv64_stack_place(uint32_t * stack_offset, const infix_type * type) {
    size_t align = type->alignment;
    if (align < 8)
        align = 8;
    if (align > 16)
        align = 16;
    *stack_offset = (uint32_t)((*stack_offset + (align - 1)) & ~(align - 1));
    uint32_t off = *stack_offset;
    *stack_offset += (uint32_t)((type->size + 7) & ~7);
    return off;
}

/**
 * @internal
 * @brief Classify an argument using the RISC-V integer calling convention.
 * @details Values wider than 2xXLEN are passed by reference (a pointer in a GPR).
 *          2xXLEN values use a GPR pair; variadic 2xXLEN values with 2xXLEN-bit
 *          alignment require an even-aligned pair. Named 2xXLEN values never
 *          align to an even boundary and split across a7 + the stack when exactly
 *          one register remains. Smaller values use a single GPR. On register
 *          exhaustion, the whole argument moves to the stack.
 */
static rv64_arg_class rv64_classify_integer(
    infix_type * type, bool is_variadic_arg, size_t * gpr_count, uint32_t * stack_offset, bool * variadic_stack_mode) {
    rv64_arg_class cls = {.type = ARG_LOCATION_STACK, .num_regs = 1};
    if (type->size > 16) {
        // Scalars/aggregates wider than 2xXLEN are passed by reference.
        if (*gpr_count < RV_NUM_GPR_ARGS) {
            cls.type = ARG_LOCATION_GPR_REFERENCE;
            cls.reg_index = (uint8_t)(*gpr_count)++;
        }
        else {
            if (is_variadic_arg)
                *variadic_stack_mode = true;
            cls.type = ARG_LOCATION_STACK;
            uint32_t off = (uint32_t)((*stack_offset + 7) & ~7);
            cls.stack_offset = off;
            *stack_offset = off + 8;  // The pointer occupies a single 8-byte slot.
        }
        return cls;
    }
    if (type->size > 8) {
        if (is_variadic_arg) {
            // Variadic 2xXLEN: an aligned (even) register pair when the type's
            // alignment is 2xXLEN bits, a plain pair otherwise; never split.
            bool needs_even = (type->alignment >= 16);
            if ((*gpr_count + 1 >= RV_NUM_GPR_ARGS) || (needs_even && (*gpr_count % 2 != 0))) {
                *variadic_stack_mode = true;
                cls.type = ARG_LOCATION_STACK;
                cls.stack_offset = rv64_stack_place(stack_offset, type);
                return cls;
            }
            cls.type = ARG_LOCATION_GPR_PAIR;
            cls.reg_index = (uint8_t)*gpr_count;
            *gpr_count += 2;
            return cls;
        }
        // Named: exactly one GPR left -> low half in that register, high half on the stack.
        if (*gpr_count == RV_NUM_GPR_ARGS - 1) {
            cls.type = ARG_LOCATION_GPR_STACK_SPLIT;
            cls.reg_index = (uint8_t)(*gpr_count)++;
            uint32_t off = (uint32_t)((*stack_offset + 7) & ~7);
            cls.stack_offset = off;
            *stack_offset = off + 8;
            return cls;
        }
        if (*gpr_count + 1 < RV_NUM_GPR_ARGS) {
            cls.type = ARG_LOCATION_GPR_PAIR;
            cls.reg_index = (uint8_t)*gpr_count;
            *gpr_count += 2;
        }
        else {
            cls.type = ARG_LOCATION_STACK;
            cls.stack_offset = rv64_stack_place(stack_offset, type);
        }
        return cls;
    }
    if (*gpr_count < RV_NUM_GPR_ARGS) {
        cls.type = ARG_LOCATION_GPR;
        cls.reg_index = (uint8_t)(*gpr_count)++;
    }
    else {
        if (is_variadic_arg)
            *variadic_stack_mode = true;
        cls.type = ARG_LOCATION_STACK;
        cls.stack_offset = rv64_stack_place(stack_offset, type);
    }
    return cls;
}

/**
 * @internal
 * @brief Classify a single argument into its physical ABI location.
 * @param type The argument's type.
 * @param is_variadic_arg `true` for arguments beyond `num_fixed_args`.
 * @param gpr_count The running GPR index (starts at 1 if a0 holds the sret pointer).
 * @param vpr_count The running FPR index.
 * @param stack_offset The running outgoing/caller stack offset.
 * @param variadic_stack_mode Sticky flag: once set, all variadic args go on the stack.
 */
static rv64_arg_class rv64_classify_arg(infix_type * type,
                                        bool is_variadic_arg,
                                        size_t * gpr_count,
                                        size_t * vpr_count,
                                        uint32_t * stack_offset,
                                        bool * variadic_stack_mode) {
    rv64_arg_class cls = {.type = ARG_LOCATION_STACK, .num_regs = 1};

    // Arrays decay to pointers and are always passed as 8-byte values.
    if (type->category == INFIX_TYPE_ARRAY) {
        if (!*variadic_stack_mode && *gpr_count < RV_NUM_GPR_ARGS) {
            cls.type = ARG_LOCATION_GPR;
            cls.reg_index = (uint8_t)(*gpr_count)++;
        }
        else {
            if (is_variadic_arg)
                *variadic_stack_mode = true;
            cls.type = ARG_LOCATION_STACK;
            *stack_offset = (*stack_offset + 7) & ~7;
            cls.stack_offset = *stack_offset;
            *stack_offset += 8;
        }
        return cls;
    }

    // Once any variadic argument has been placed on the stack, all the rest are too.
    if (is_variadic_arg && *variadic_stack_mode) {
        cls.type = ARG_LOCATION_STACK;
        cls.stack_offset = rv64_stack_place(stack_offset, type);
        return cls;
    }

    // Variadic arguments use the integer calling convention (GPRs).
    if (is_variadic_arg)
        return rv64_classify_integer(type, true, gpr_count, stack_offset, variadic_stack_mode);

    // Named single-precision / double-precision scalars.
    if (is_float(type) || is_double(type)) {
        if (*vpr_count < RV_NUM_FPR_ARGS) {
            cls.type = ARG_LOCATION_VPR;
            cls.reg_index = (uint8_t)(*vpr_count)++;
            cls.num_regs = 1;
        }
        else {
            // FPRs are exhausted: the psABI spills FP reals into the integer
            // argument registers (a0-a7) before they go on the stack.
            return rv64_classify_integer(type, false, gpr_count, stack_offset, variadic_stack_mode);
        }
        return cls;
    }

    // Aggregates: > 16 bytes pass by reference; the psABI hardware FP rules apply
    // to aggregates of at most 2xXLEN bytes with at most two FP members.
    bool is_aggregate = (type->category == INFIX_TYPE_STRUCT || type->category == INFIX_TYPE_UNION ||
                         type->category == INFIX_TYPE_COMPLEX);
    if (is_aggregate) {
        if (type->size > 16) {
            if (!*variadic_stack_mode && *gpr_count < RV_NUM_GPR_ARGS) {
                cls.type = ARG_LOCATION_GPR_REFERENCE;
                cls.reg_index = (uint8_t)(*gpr_count)++;
            }
            else {
                if (is_variadic_arg)
                    *variadic_stack_mode = true;
                cls.type = ARG_LOCATION_STACK;
                *stack_offset = (*stack_offset + 7) & ~7;
                cls.stack_offset = *stack_offset;
                *stack_offset += 8;  // The pointer occupies a single 8-byte slot.
            }
            return cls;
        }
        if (type->category == INFIX_TYPE_UNION)
            return rv64_classify_integer(type, false, gpr_count, stack_offset, variadic_stack_mode);

        // Structs (with arrays flattened) and `_Complex` types of at most 2xXLEN.
        rv64_all_leaf_list leaves;
        if (rv64_flatten_all(type, &leaves)) {
            size_t fp = 0;
            size_t int_idx = SIZE_MAX;
            size_t long_leaf = SIZE_MAX;
            for (size_t j = 0; j < leaves.count; ++j) {
                const rv64_all_leaf * leaf = &leaves.leaves[j];
                if (leaf->is_fp && leaf->size <= 8)
                    fp++;
                else if (!leaf->is_fp && leaf->size <= 8)
                    int_idx = j;
                else
                    long_leaf = j;
            }
            // One FP real + one integer (either order): FPR + GPR.
            if (fp == 1 && int_idx != SIZE_MAX && long_leaf == SIZE_MAX && leaves.count == 2) {
                if (*vpr_count < RV_NUM_FPR_ARGS && *gpr_count < RV_NUM_GPR_ARGS) {
                    cls.type = ARG_LOCATION_MIXED;
                    cls.reg_index = (uint8_t)(*gpr_count)++;   // GPR for the integer leaf.
                    cls.reg_index2 = (uint8_t)(*vpr_count)++;  // FPR for the FP leaf.
                    cls.num_regs = (1 << 8) | 1;
                    return cls;
                }
                return rv64_classify_integer(type, false, gpr_count, stack_offset, variadic_stack_mode);
            }
            // Two FP reals (or a `_Complex` scalar): two FPRs in memory order.
            if (fp == 2 && int_idx == SIZE_MAX && long_leaf == SIZE_MAX) {
                if (*vpr_count + 2 <= RV_NUM_FPR_ARGS) {
                    cls.type = ARG_LOCATION_VPR;
                    cls.reg_index = (uint8_t)*vpr_count;
                    cls.num_regs = 2;
                    *vpr_count += 2;
                    return cls;
                }
                return rv64_classify_integer(type, false, gpr_count, stack_offset, variadic_stack_mode);
            }
            // A single FP real (a one-member FP struct).
            if (fp == 1 && int_idx == SIZE_MAX && long_leaf == SIZE_MAX) {
                if (*vpr_count < RV_NUM_FPR_ARGS) {
                    cls.type = ARG_LOCATION_VPR;
                    cls.reg_index = (uint8_t)(*vpr_count)++;
                    cls.num_regs = 1;
                    return cls;
                }
                return rv64_classify_integer(type, false, gpr_count, stack_offset, variadic_stack_mode);
            }
        }
    }

    // Everything else (integers, enums, pointers, unions, 3+ leaf or 4-float
    // aggregates, {long double}) is integer.
    return rv64_classify_integer(type, false, gpr_count, stack_offset, variadic_stack_mode);
}

//
// Forward trampolines
//

/**
 * @internal
 * @brief Stage 1 (Forward): Analyzes a signature and creates a call frame layout.
 */
static infix_status prepare_forward_call_frame_riscv64(infix_arena_t * arena,
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
    layout->arg_locations =
        infix_arena_calloc(arena, num_args, sizeof(infix_arg_location), _Alignof(infix_arg_location));
    if (layout->arg_locations == nullptr && num_args > 0) {
        *out_layout = nullptr;
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    layout->is_variadic = (num_fixed_args < num_args);
    layout->target_fn = target_fn;
    layout->num_args = num_args;
    layout->num_stack_args = 0;

    layout->return_value_in_memory = rv64_return_in_memory(ret_type);
    // When the target returns by memory, a0 holds the hidden sret pointer.
    size_t gpr_count = layout->return_value_in_memory ? 1 : 0;
    size_t vpr_count = 0;
    uint32_t stack_offset = 0;
    bool variadic_stack_mode = false;

    for (size_t i = 0; i < num_args; ++i) {
        infix_type * type = arg_types[i];
        if (type->size > INFIX_MAX_ARG_SIZE) {
            *out_layout = nullptr;
            return INFIX_ERROR_LAYOUT_FAILED;
        }
        bool is_variadic_arg = (i >= num_fixed_args);
        rv64_arg_class cls =
            rv64_classify_arg(type, is_variadic_arg, &gpr_count, &vpr_count, &stack_offset, &variadic_stack_mode);
        layout->arg_locations[i].type = cls.type;
        layout->arg_locations[i].reg_index = cls.reg_index;
        layout->arg_locations[i].reg_index2 = cls.reg_index2;
        layout->arg_locations[i].num_regs = cls.num_regs;
        layout->arg_locations[i].stack_offset = cls.stack_offset;
        if (cls.type == ARG_LOCATION_STACK)
            layout->num_stack_args++;
    }

    layout->total_stack_alloc = (stack_offset + 15) & ~15;
    layout->num_gpr_args = (uint8_t)gpr_count;
    layout->num_vpr_args = (uint8_t)vpr_count;
    if (layout->total_stack_alloc > INFIX_MAX_STACK_ALLOC) {
        *out_layout = nullptr;
        return INFIX_ERROR_LAYOUT_FAILED;
    }
    *out_layout = layout;
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 2 (Forward): Generates the function prologue.
 * @details Saves the callee-saved context registers (s1 = target, s2 = return
 *          buffer, s3 = args array), moves the trampoline's own arguments into
 *          them, and allocates space for the outgoing stack arguments.
 */
static infix_status generate_forward_prologue_riscv64(code_buffer * buf, infix_call_frame_layout * layout) {
    infix_riscv64_emit_addi(buf, X_SP_REG, X_SP_REG, -RV_FWD_SAVED_SIZE);
    rv64_mem_sd(buf, X_SP_REG, RV_CTX_TARGET_REG, 0);
    rv64_mem_sd(buf, X_SP_REG, RV_CTX_RET_REG, 8);
    rv64_mem_sd(buf, X_SP_REG, RV_CTX_ARGS_REG, 16);
    rv64_mem_sd(buf, X_SP_REG, X_RA_REG, 24);

    layout->prologue_size = (uint32_t)buf->size;

    if (layout->target_fn == nullptr) {  // Unbound trampoline args: (target_fn, ret_ptr, args_ptr) in a0, a1, a2.
        infix_riscv64_emit_addi(buf, RV_CTX_TARGET_REG, X_A0_REG, 0);
        infix_riscv64_emit_addi(buf, RV_CTX_RET_REG, X_A1_REG, 0);
        infix_riscv64_emit_addi(buf, RV_CTX_ARGS_REG, X_A2_REG, 0);
    }
    else {  // Bound trampoline args: (ret_ptr, args_ptr) in a0, a1.
        infix_riscv64_emit_addi(buf, RV_CTX_RET_REG, X_A0_REG, 0);
        infix_riscv64_emit_addi(buf, RV_CTX_ARGS_REG, X_A1_REG, 0);
    }
    rv64_emit_stack_sub(buf, (uint32_t)layout->total_stack_alloc);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 3 (Forward): Generates code to move arguments into their native locations.
 */
static infix_status generate_forward_argument_moves_riscv64(code_buffer * buf,
                                                            infix_call_frame_layout * layout,
                                                            infix_type ** arg_types,
                                                            size_t num_args,
                                                            c23_maybe_unused size_t num_fixed_args) {
    // Hidden pointer for large struct returns is passed in a0.
    if (layout->return_value_in_memory)
        infix_riscv64_emit_addi(buf, X_A0_REG, RV_CTX_RET_REG, 0);

    for (size_t i = 0; i < num_args; ++i) {
        infix_arg_location * loc = &layout->arg_locations[i];
        infix_type * type = arg_types[i];
        // t0 = args_array[i]
        rv64_mem_ld(buf, RV_SCRATCH0_REG, RV_CTX_ARGS_REG, (int32_t)(i * sizeof(void *)));

        switch (loc->type) {
        case ARG_LOCATION_GPR:
            if (type->category == INFIX_TYPE_ARRAY) {
                infix_riscv64_emit_addi(buf, GPR_ARGS[loc->reg_index], RV_SCRATCH0_REG, 0);
                break;
            }
            rv64_emit_load_gpr_value(buf, GPR_ARGS[loc->reg_index], RV_SCRATCH0_REG, type);
            break;
        case ARG_LOCATION_GPR_PAIR:
            rv64_mem_ld(buf, GPR_ARGS[loc->reg_index], RV_SCRATCH0_REG, 0);
            rv64_mem_ld(buf, GPR_ARGS[loc->reg_index + 1], RV_SCRATCH0_REG, 8);
            break;
        case ARG_LOCATION_GPR_STACK_SPLIT:
            // 2xXLEN value with exactly one register left: low half in the
            // register, high half in the outgoing stack slot.
            rv64_mem_ld(buf, GPR_ARGS[loc->reg_index], RV_SCRATCH0_REG, 0);
            rv64_mem_ld(buf, RV_SCRATCH1_REG, RV_SCRATCH0_REG, 8);
            rv64_mem_sd(buf, X_SP_REG, RV_SCRATCH1_REG, (int32_t)loc->stack_offset);
            break;
        case ARG_LOCATION_GPR_REFERENCE:
            infix_riscv64_emit_addi(buf, GPR_ARGS[loc->reg_index], RV_SCRATCH0_REG, 0);
            break;
        case ARG_LOCATION_VPR:
            if (type->category == INFIX_TYPE_STRUCT || type->category == INFIX_TYPE_COMPLEX)
                rv64_emit_load_fp_aggregate(buf, RV_SCRATCH0_REG, FPR_ARGS[loc->reg_index], type);
            else
                rv64_emit_load_fp_value(buf, RV_SCRATCH0_REG, FPR_ARGS[loc->reg_index], 0, type->size);
            break;
        case ARG_LOCATION_MIXED:
            rv64_emit_load_mixed(buf, RV_SCRATCH0_REG, GPR_ARGS[loc->reg_index], FPR_ARGS[loc->reg_index2], type);
            break;
        case ARG_LOCATION_STACK:
            if (type->size > 16 || type->category == INFIX_TYPE_ARRAY) {
                // By-reference / array argument: the pointer itself is the value.
                rv64_mem_sd(buf, X_SP_REG, RV_SCRATCH0_REG, (int32_t)loc->stack_offset);
                break;
            }
            if ((type->category == INFIX_TYPE_PRIMITIVE || type->category == INFIX_TYPE_POINTER ||
                 type->category == INFIX_TYPE_ENUM) &&
                type->size <= 8) {
                // Narrow scalars are extended into a full 8-byte stack slot.
                rv64_emit_load_gpr_value(buf, RV_SCRATCH1_REG, RV_SCRATCH0_REG, type);
                rv64_mem_sd(buf, X_SP_REG, RV_SCRATCH1_REG, (int32_t)loc->stack_offset);
                break;
            }
            // Aggregates up to 16 bytes and 2xXLEN scalars copy their raw bytes.
            rv64_emit_copy_memory(buf, X_SP_REG, (int32_t)loc->stack_offset, RV_SCRATCH0_REG, 0, type->size);
            break;
        default:
            break;
        }
    }
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 3.5 (Forward): Generates the call instruction.
 * @details Null-checks the target pointer (crashing via `ebreak` if null) and
 *          emits `jalr ra, target, 0`.
 */
static infix_status generate_forward_call_instruction_riscv64(code_buffer * buf,
                                                              c23_maybe_unused infix_call_frame_layout * layout) {
    uint8_t target_reg = RV_SCRATCH0_REG;
    if (layout->target_fn)
        infix_riscv64_emit_load_u64_immediate(buf, target_reg, (uint64_t)layout->target_fn);
    else
        infix_riscv64_emit_addi(buf, target_reg, RV_CTX_TARGET_REG, 0);
    // A non-null target skips the ebreak and calls the target; a null target falls
    // through into the ebreak and traps. The target returns to the epilogue.
    infix_riscv64_emit_bne(buf, target_reg, X_ZERO_REG, 8);
    infix_riscv64_emit_ebreak(buf);
    infix_riscv64_emit_jalr(buf, X_RA_REG, target_reg, 0);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 4 (Forward): Generates the function epilogue.
 * @details Copies the return value from a0/a1/fa0/fa1 into the user's return
 *          buffer, deallocates the frame, restores the context registers, and
 *          returns to the caller.
 */
static infix_status generate_forward_epilogue_riscv64(code_buffer * buf,
                                                      infix_call_frame_layout * layout,
                                                      infix_type * ret_type) {
    layout->epilogue_offset = (uint32_t)buf->size;
    if (ret_type->category != INFIX_TYPE_VOID && !layout->return_value_in_memory) {
        rv64_return_class rc = rv64_classify_return(ret_type);
        if (rc.mixed) {
            // One integer leaf in a0 and one FP leaf in fa0.
            rv64_emit_store_fp_value(buf, RV_CTX_RET_REG, F_FA0_REG, rc.fp_offsets[0], rc.fp_sizes[0]);
            rv64_emit_store_gpr_low_bytes(buf, RV_CTX_RET_REG, X_A0_REG, rc.int_offset, rc.int_size);
        }
        else if (rc.fp_count == 2) {
            rv64_emit_store_fp_value(buf, RV_CTX_RET_REG, F_FA0_REG, rc.fp_offsets[0], rc.fp_sizes[0]);
            rv64_emit_store_fp_value(buf, RV_CTX_RET_REG, F_FA1_REG, rc.fp_offsets[1], rc.fp_sizes[1]);
        }
        else if (rc.fp_count == 1) {
            rv64_emit_store_fp_value(buf, RV_CTX_RET_REG, F_FA0_REG, rc.fp_offsets[0], rc.fp_sizes[0]);
        }
        else {
            rv64_emit_store_gpr_return(buf, RV_CTX_RET_REG, ret_type->size);
        }
    }
    rv64_emit_stack_add(buf, (uint32_t)layout->total_stack_alloc);
    rv64_mem_ld(buf, RV_CTX_TARGET_REG, X_SP_REG, 0);
    rv64_mem_ld(buf, RV_CTX_RET_REG, X_SP_REG, 8);
    rv64_mem_ld(buf, RV_CTX_ARGS_REG, X_SP_REG, 16);
    rv64_mem_ld(buf, X_RA_REG, X_SP_REG, 24);
    infix_riscv64_emit_addi(buf, X_SP_REG, X_SP_REG, RV_FWD_SAVED_SIZE);
    infix_riscv64_emit_jalr(buf, X_ZERO_REG, X_RA_REG, 0);
    return INFIX_SUCCESS;
}

//
// Reverse trampolines
//

/**
 * @internal
 * @brief Stage 1 (Reverse): Calculates the stack layout for a reverse trampoline stub.
 */
static infix_status prepare_reverse_call_frame_riscv64(infix_arena_t * arena,
                                                       infix_reverse_call_frame_layout ** out_layout,
                                                       infix_reverse_t * context) {
    infix_reverse_call_frame_layout * layout = infix_arena_calloc(
        arena, 1, sizeof(infix_reverse_call_frame_layout), _Alignof(infix_reverse_call_frame_layout));
    if (layout == nullptr)
        return INFIX_ERROR_ALLOCATION_FAILED;
    if (context->return_type->size > INFIX_MAX_ARG_SIZE) {
        *out_layout = nullptr;
        return INFIX_ERROR_LAYOUT_FAILED;
    }
    size_t return_size = (context->return_type->size + 15) & ~15;
    size_t args_array_size = (context->num_args * sizeof(void *) + 15) & ~15;
    size_t saved_args_data_size = 0;
    for (size_t i = 0; i < context->num_args; ++i) {
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
    if (total_local_space > INFIX_MAX_STACK_ALLOC) {
        *out_layout = nullptr;
        return INFIX_ERROR_LAYOUT_FAILED;
    }
    layout->total_stack_alloc = (total_local_space + 15) & ~15;
    layout->return_buffer_offset = 0;
    layout->args_array_offset = layout->return_buffer_offset + (int32_t)return_size;
    layout->saved_args_offset = layout->args_array_offset + (int32_t)args_array_size;
    *out_layout = layout;
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 2 (Reverse): Generates the prologue for the reverse trampoline stub.
 */
static infix_status generate_reverse_prologue_riscv64(code_buffer * buf, infix_reverse_call_frame_layout * layout) {
    infix_riscv64_emit_addi(buf, X_SP_REG, X_SP_REG, -RV_REV_SAVED_SIZE);
    rv64_mem_sd(buf, X_SP_REG, X_RA_REG, 0);
    layout->prologue_size = (uint32_t)buf->size;
    rv64_emit_stack_sub(buf, (uint32_t)layout->total_stack_alloc);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 3 (Reverse): Generates code to marshal arguments into the `void**` array.
 * @details Copies each incoming argument (from GPRs, FPRs, or the caller's stack)
 *          into a saved-data area on the stub's local stack and populates
 *          `args_array` with pointers to it.
 */
static infix_status generate_reverse_argument_marshalling_riscv64(code_buffer * buf,
                                                                  infix_reverse_call_frame_layout * layout,
                                                                  infix_reverse_t * context) {
    bool return_in_memory = rv64_return_in_memory(context->return_type);
    // a0 holds the hidden sret pointer when the return value is in memory; the
    // dispatcher needs it again when it writes the return value back out, so
    // stash it in the return-buffer slot before anything clobbers a0.
    if (return_in_memory)
        rv64_mem_sd(buf, X_SP_REG, X_A0_REG, layout->return_buffer_offset);
    // a0 holds the hidden sret pointer when the return value is in memory.
    size_t gpr_idx = return_in_memory ? 1 : 0;
    size_t vpr_idx = 0;
    uint32_t stack_offset = 0;
    bool variadic_stack_mode = false;
    size_t current_saved_data_offset = 0;
    // The caller's stack arguments sit directly above our saved return address.
    const int32_t caller_stack_base = RV_REV_SAVED_SIZE + (int32_t)layout->total_stack_alloc;

    for (size_t i = 0; i < context->num_args; ++i) {
        infix_type * type = context->arg_types[i];
        bool is_variadic_arg = (i >= context->num_fixed_args);
        rv64_arg_class cls =
            rv64_classify_arg(type, is_variadic_arg, &gpr_idx, &vpr_idx, &stack_offset, &variadic_stack_mode);

        int32_t arg_save_loc = (int32_t)(layout->saved_args_offset + current_saved_data_offset);

        bool raw_pointer = false;
        switch (cls.type) {
        case ARG_LOCATION_GPR:
            rv64_mem_sd(buf, X_SP_REG, GPR_ARGS[cls.reg_index], arg_save_loc);
            break;
        case ARG_LOCATION_GPR_PAIR:
            rv64_mem_sd(buf, X_SP_REG, GPR_ARGS[cls.reg_index], arg_save_loc);
            rv64_mem_sd(buf, X_SP_REG, GPR_ARGS[cls.reg_index + 1], arg_save_loc + 8);
            break;
        case ARG_LOCATION_GPR_STACK_SPLIT:
            // 2xXLEN value split across a register and the caller's stack.
            rv64_mem_sd(buf, X_SP_REG, GPR_ARGS[cls.reg_index], arg_save_loc);
            rv64_mem_ld(buf, RV_SCRATCH0_REG, X_SP_REG, caller_stack_base + (int32_t)cls.stack_offset);
            rv64_mem_sd(buf, X_SP_REG, RV_SCRATCH0_REG, arg_save_loc + 8);
            break;
        case ARG_LOCATION_GPR_REFERENCE:
            // Large aggregate passed by reference: the argument is the pointer
            // itself, which the dispatcher dereferences. Store the raw pointer
            // straight into args_array[i].
            raw_pointer = true;
            break;
        case ARG_LOCATION_VPR:
            if (cls.num_regs > 1) {
                rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, X_SP_REG, arg_save_loc);
                rv64_emit_store_fp_aggregate(buf, RV_SCRATCH0_REG, FPR_ARGS[cls.reg_index], type);
            }
            else {
                rv64_emit_store_fp_value(buf, X_SP_REG, FPR_ARGS[cls.reg_index], arg_save_loc, type->size);
            }
            break;
        case ARG_LOCATION_MIXED:
            rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, X_SP_REG, arg_save_loc);
            rv64_emit_store_mixed(buf, RV_SCRATCH0_REG, GPR_ARGS[cls.reg_index], FPR_ARGS[cls.reg_index2], type);
            break;
        case ARG_LOCATION_STACK:
            if (type->size > 16) {
                // By-reference pointer passed on the caller's stack.
                rv64_mem_ld(buf, RV_SCRATCH0_REG, X_SP_REG, caller_stack_base + (int32_t)cls.stack_offset);
                rv64_mem_sd(buf, X_SP_REG, RV_SCRATCH0_REG, arg_save_loc);
            }
            else {
                rv64_emit_copy_memory(
                    buf, X_SP_REG, arg_save_loc, X_SP_REG, caller_stack_base + (int32_t)cls.stack_offset, type->size);
            }
            break;
        default:
            break;
        }

        if (raw_pointer) {
            // args_array[i] = the raw pointer value from the argument register.
            rv64_mem_sd(
                buf, X_SP_REG, GPR_ARGS[cls.reg_index], layout->args_array_offset + (int32_t)(i * sizeof(void *)));
        }
        else {
            // args_array[i] = sp + arg_save_loc
            rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, X_SP_REG, arg_save_loc);
            rv64_mem_sd(buf, X_SP_REG, RV_SCRATCH0_REG, layout->args_array_offset + (int32_t)(i * sizeof(void *)));
        }

        current_saved_data_offset += (type->size + 15) & ~15;
    }
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 4 (Reverse): Generates the call to the C dispatcher.
 * @details Loads `(context, return_buffer_ptr, args_array_ptr)` into a0/a1/a2 and
 *          calls the dispatcher via `jalr`.
 */
static infix_status generate_reverse_dispatcher_call_riscv64(code_buffer * buf,
                                                             infix_reverse_call_frame_layout * layout,
                                                             infix_reverse_t * context) {
    infix_riscv64_emit_load_u64_immediate(buf, X_A0_REG, (uint64_t)context);
    if (rv64_return_in_memory(context->return_type))
        rv64_mem_ld(buf, X_A1_REG, X_SP_REG, layout->return_buffer_offset);
    else
        rv64_emit_compute_addr(buf, X_A1_REG, X_SP_REG, layout->return_buffer_offset);
    rv64_emit_compute_addr(buf, X_A2_REG, X_SP_REG, layout->args_array_offset);
    infix_riscv64_emit_load_u64_immediate(buf, RV_SCRATCH0_REG, (uint64_t)context->internal_dispatcher);
    infix_riscv64_emit_jalr(buf, X_RA_REG, RV_SCRATCH0_REG, 0);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 5 (Reverse): Generates the epilogue for the reverse trampoline stub.
 */
static infix_status generate_reverse_epilogue_riscv64(code_buffer * buf,
                                                      infix_reverse_call_frame_layout * layout,
                                                      infix_reverse_t * context) {
    bool return_in_memory = rv64_return_in_memory(context->return_type);
    if (context->return_type->category != INFIX_TYPE_VOID && !return_in_memory) {
        rv64_return_class rc = rv64_classify_return(context->return_type);
        if (rc.mixed) {
            // One integer leaf in a0 and one FP leaf in fa0.
            rv64_emit_load_fp_value(
                buf, X_SP_REG, F_FA0_REG, layout->return_buffer_offset + rc.fp_offsets[0], rc.fp_sizes[0]);
            rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, X_SP_REG, layout->return_buffer_offset + rc.int_offset);
            rv64_emit_load_gpr_value_sized(buf, X_A0_REG, RV_SCRATCH0_REG, rc.int_size, rc.int_signed);
        }
        else if (rc.fp_count == 2) {
            rv64_emit_load_fp_value(
                buf, X_SP_REG, F_FA0_REG, layout->return_buffer_offset + rc.fp_offsets[0], rc.fp_sizes[0]);
            rv64_emit_load_fp_value(
                buf, X_SP_REG, F_FA1_REG, layout->return_buffer_offset + rc.fp_offsets[1], rc.fp_sizes[1]);
        }
        else if (rc.fp_count == 1) {
            rv64_emit_load_fp_value(
                buf, X_SP_REG, F_FA0_REG, layout->return_buffer_offset + rc.fp_offsets[0], rc.fp_sizes[0]);
        }
        else {
            rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, X_SP_REG, layout->return_buffer_offset);
            rv64_emit_load_gpr_value(buf, X_A0_REG, RV_SCRATCH0_REG, context->return_type);
            if (context->return_type->size > 8)
                rv64_mem_ld(buf, X_A1_REG, RV_SCRATCH0_REG, 8);
        }
    }
    rv64_emit_stack_add(buf, (uint32_t)layout->total_stack_alloc);
    rv64_mem_ld(buf, X_RA_REG, X_SP_REG, 0);
    infix_riscv64_emit_addi(buf, X_SP_REG, X_SP_REG, RV_REV_SAVED_SIZE);
    infix_riscv64_emit_jalr(buf, X_ZERO_REG, X_RA_REG, 0);
    return INFIX_SUCCESS;
}

//
// Direct marshalling trampolines
//

/** @internal Scratch-space requirements for a single direct argument. */
typedef struct {
    bool needs_scratch;
    size_t size;
    size_t align;
} rv64_direct_scratch_info;

/** @internal Compute the scratch-space needs for a direct argument. */
static rv64_direct_scratch_info rv64_direct_scratch(const infix_direct_arg_layout * arg) {
    rv64_direct_scratch_info info = {false, 0, 0};
    if (arg->handler->aggregate_marshaller) {
        info.needs_scratch = true;
        info.size = arg->type->size;
        info.align = arg->type->alignment;
    }
    else if (arg->handler->scalar_marshaller) {
        info.needs_scratch = true;
        info.size = 16;
        info.align = 16;
    }
    else if (arg->handler->writeback_handler) {
        const infix_type * pointee =
            (arg->type->category == INFIX_TYPE_POINTER) ? arg->type->meta.pointer_info.pointee_type : arg->type;
        info.needs_scratch = true;
        info.size = pointee->size;
        info.align = pointee->alignment;
    }
    return info;
}

/** @internal Recompute the standard (outgoing stack args) allocation size. */
static size_t rv64_direct_standard_alloc(const infix_direct_call_frame_layout * layout) {
    size_t stack_offset = 0;
    for (size_t i = 0; i < layout->num_args; ++i) {
        const infix_arg_location * loc = &layout->args[i].location;
        if (loc->type == ARG_LOCATION_STACK) {
            size_t s = layout->args[i].type->size;
            if (s > 16)
                s = 8;  // By-reference pointers occupy a single 8-byte slot.
            size_t end = loc->stack_offset + ((s + 7) & ~7);
            if (end > stack_offset)
                stack_offset = end;
        }
        else if (loc->type == ARG_LOCATION_GPR_STACK_SPLIT) {
            // The high half of a split 2xXLEN value occupies an 8-byte stack slot.
            size_t end = loc->stack_offset + 8;
            if (end > stack_offset)
                stack_offset = end;
        }
    }
    return (stack_offset + 15) & ~15;
}

/**
 * @internal
 * @brief Stage 1 (Direct): Analyzes a signature and creates a direct call frame layout.
 */
static infix_status prepare_direct_forward_call_frame_riscv64(infix_arena_t * arena,
                                                              infix_direct_call_frame_layout ** out_layout,
                                                              infix_type * ret_type,
                                                              infix_type ** arg_types,
                                                              size_t num_args,
                                                              infix_direct_arg_handler_t * handlers,
                                                              void * target_fn) {
    infix_call_frame_layout * standard_layout = nullptr;
    infix_status status =
        prepare_forward_call_frame_riscv64(arena, &standard_layout, ret_type, arg_types, num_args, num_args, target_fn);
    if (status != INFIX_SUCCESS)
        return status;

    infix_direct_call_frame_layout * layout =
        infix_arena_calloc(arena, 1, sizeof(infix_direct_call_frame_layout), _Alignof(infix_direct_call_frame_layout));
    if (layout == nullptr)
        return INFIX_ERROR_ALLOCATION_FAILED;
    layout->args =
        infix_arena_calloc(arena, num_args, sizeof(infix_direct_arg_layout), _Alignof(infix_direct_arg_layout));
    if (layout->args == nullptr && num_args > 0)
        return INFIX_ERROR_ALLOCATION_FAILED;

    layout->num_args = num_args;
    layout->target_fn = target_fn;
    layout->return_value_in_memory = standard_layout->return_value_in_memory;

    size_t scratch_space_needed = 0;
    for (size_t i = 0; i < num_args; ++i) {
        layout->args[i].location = standard_layout->arg_locations[i];
        layout->args[i].type = arg_types[i];
        layout->args[i].handler = &handlers[i];
        rv64_direct_scratch_info info = rv64_direct_scratch(&layout->args[i]);
        if (info.needs_scratch) {
            scratch_space_needed = _infix_align_up(scratch_space_needed, info.align);
            scratch_space_needed += info.size;
        }
    }

    size_t total_needed = standard_layout->total_stack_alloc + scratch_space_needed;
    layout->total_stack_alloc = (total_needed + 15) & ~15;

    *out_layout = layout;
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 2 (Direct): Generates the direct trampoline prologue.
 */
static infix_status generate_direct_forward_prologue_riscv64(code_buffer * buf,
                                                             infix_direct_call_frame_layout * layout) {
    infix_riscv64_emit_addi(buf, X_SP_REG, X_SP_REG, -RV_FWD_SAVED_SIZE);
    rv64_mem_sd(buf, X_SP_REG, RV_CTX_TARGET_REG, 0);
    rv64_mem_sd(buf, X_SP_REG, RV_CTX_RET_REG, 8);
    rv64_mem_sd(buf, X_SP_REG, RV_CTX_ARGS_REG, 16);
    rv64_mem_sd(buf, X_SP_REG, X_RA_REG, 24);
    layout->prologue_size = (uint32_t)buf->size;
    // The direct CIF is called with (ret_ptr, lang_args) in a0, a1.
    infix_riscv64_emit_addi(buf, RV_CTX_RET_REG, X_A0_REG, 0);
    infix_riscv64_emit_addi(buf, RV_CTX_ARGS_REG, X_A1_REG, 0);
    rv64_emit_stack_sub(buf, (uint32_t)layout->total_stack_alloc);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 3 (Direct): Generates code to call marshallers and place arguments.
 */
static infix_status generate_direct_forward_argument_moves_riscv64(code_buffer * buf,
                                                                   infix_direct_call_frame_layout * layout) {
    if (layout->return_value_in_memory)
        infix_riscv64_emit_addi(buf, X_A0_REG, RV_CTX_RET_REG, 0);

    const size_t scratch_base_from_sp = rv64_direct_standard_alloc(layout);
    size_t current_scratch_offset = 0;

    // PHASE 1: MARSHALL & SAVE TO STACK

    for (size_t i = 0; i < layout->num_args; ++i) {
        const infix_direct_arg_layout * arg = &layout->args[i];
        rv64_direct_scratch_info info = rv64_direct_scratch(arg);
        int32_t my_scratch_offset = -1;
        if (info.needs_scratch) {
            current_scratch_offset = _infix_align_up(current_scratch_offset, info.align);
            my_scratch_offset = (int32_t)(scratch_base_from_sp + current_scratch_offset);
            current_scratch_offset += info.size;
        }
        if (!info.needs_scratch || (!arg->handler->aggregate_marshaller && !arg->handler->scalar_marshaller))
            continue;

        // a0 = language object
        rv64_mem_ld(buf, X_A0_REG, RV_CTX_ARGS_REG, (int32_t)(i * sizeof(void *)));

        if (arg->handler->aggregate_marshaller) {
            rv64_emit_compute_addr(buf, X_A1_REG, X_SP_REG, my_scratch_offset);
            infix_riscv64_emit_load_u64_immediate(buf, X_A2_REG, (uint64_t)arg->type);
            infix_riscv64_emit_load_u64_immediate(buf, RV_SCRATCH0_REG, (uint64_t)arg->handler->aggregate_marshaller);
            infix_riscv64_emit_jalr(buf, X_RA_REG, RV_SCRATCH0_REG, 0);
        }
        else {
            infix_riscv64_emit_load_u64_immediate(buf, RV_SCRATCH0_REG, (uint64_t)arg->handler->scalar_marshaller);
            infix_riscv64_emit_jalr(buf, X_RA_REG, RV_SCRATCH0_REG, 0);
            rv64_mem_sd(buf, X_SP_REG, X_A0_REG, my_scratch_offset);
        }
    }

    // PHASE 2: PLACE (Stack -> Registers)

    current_scratch_offset = 0;

    for (size_t i = 0; i < layout->num_args; ++i) {
        const infix_direct_arg_layout * arg = &layout->args[i];
        rv64_direct_scratch_info info = rv64_direct_scratch(arg);
        int32_t my_scratch_offset = -1;
        if (info.needs_scratch) {
            current_scratch_offset = _infix_align_up(current_scratch_offset, info.align);
            my_scratch_offset = (int32_t)(scratch_base_from_sp + current_scratch_offset);
            current_scratch_offset += info.size;
        }
        if (!info.needs_scratch)
            continue;

        bool pass_address = (arg->type->category == INFIX_TYPE_POINTER);
        bool is_value_move =
            arg->handler->aggregate_marshaller || (arg->handler->writeback_handler && !arg->handler->scalar_marshaller);

        if (is_value_move) {
            switch (arg->location.type) {
            case ARG_LOCATION_GPR_REFERENCE:
                rv64_emit_compute_addr(buf, GPR_ARGS[arg->location.reg_index], X_SP_REG, my_scratch_offset);
                break;
            case ARG_LOCATION_GPR:
                if (pass_address)
                    rv64_emit_compute_addr(buf, GPR_ARGS[arg->location.reg_index], X_SP_REG, my_scratch_offset);
                else
                    rv64_mem_ld(buf, GPR_ARGS[arg->location.reg_index], X_SP_REG, my_scratch_offset);
                break;
            case ARG_LOCATION_GPR_PAIR:
                if (pass_address)
                    rv64_emit_compute_addr(buf, GPR_ARGS[arg->location.reg_index], X_SP_REG, my_scratch_offset);
                else {
                    rv64_mem_ld(buf, GPR_ARGS[arg->location.reg_index], X_SP_REG, my_scratch_offset);
                    rv64_mem_ld(buf, GPR_ARGS[arg->location.reg_index + 1], X_SP_REG, my_scratch_offset + 8);
                }
                break;
            case ARG_LOCATION_GPR_STACK_SPLIT:
                rv64_mem_ld(buf, GPR_ARGS[arg->location.reg_index], X_SP_REG, my_scratch_offset);
                rv64_mem_ld(buf, RV_SCRATCH1_REG, X_SP_REG, my_scratch_offset + 8);
                rv64_mem_sd(buf, X_SP_REG, RV_SCRATCH1_REG, (int32_t)arg->location.stack_offset);
                break;
            case ARG_LOCATION_VPR:
                if (arg->type->category == INFIX_TYPE_STRUCT || arg->type->category == INFIX_TYPE_COMPLEX) {
                    rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, X_SP_REG, my_scratch_offset);
                    rv64_emit_load_fp_aggregate(buf, RV_SCRATCH0_REG, FPR_ARGS[arg->location.reg_index], arg->type);
                }
                else {
                    rv64_emit_load_fp_value(
                        buf, X_SP_REG, FPR_ARGS[arg->location.reg_index], my_scratch_offset, arg->type->size);
                }
                break;
            case ARG_LOCATION_MIXED:
                rv64_emit_compute_addr(buf, RV_SCRATCH0_REG, X_SP_REG, my_scratch_offset);
                rv64_emit_load_mixed(buf,
                                     RV_SCRATCH0_REG,
                                     GPR_ARGS[arg->location.reg_index],
                                     FPR_ARGS[arg->location.reg_index2],
                                     arg->type);
                break;
            case ARG_LOCATION_STACK:
                if (pass_address) {
                    rv64_emit_compute_addr(buf, RV_SCRATCH1_REG, X_SP_REG, my_scratch_offset);
                    rv64_mem_sd(buf, X_SP_REG, RV_SCRATCH1_REG, (int32_t)arg->location.stack_offset);
                }
                else {
                    rv64_emit_copy_memory(buf,
                                          X_SP_REG,
                                          (int32_t)arg->location.stack_offset,
                                          X_SP_REG,
                                          my_scratch_offset,
                                          arg->type->size);
                }
                break;
            default:
                break;
            }
        }
        else if (arg->handler->scalar_marshaller) {
            switch (arg->location.type) {
            case ARG_LOCATION_GPR:
                rv64_mem_ld(buf, GPR_ARGS[arg->location.reg_index], X_SP_REG, my_scratch_offset);
                break;
            case ARG_LOCATION_VPR:
                if (is_float(arg->type)) {
                    // The scalar marshaller returns the value as a double; narrow it.
                    rv64_mem_fld(buf, FPR_ARGS[arg->location.reg_index], X_SP_REG, my_scratch_offset);
                    infix_riscv64_emit_fcvt_s_d(
                        buf, FPR_ARGS[arg->location.reg_index], FPR_ARGS[arg->location.reg_index]);
                }
                else {
                    rv64_mem_fld(buf, FPR_ARGS[arg->location.reg_index], X_SP_REG, my_scratch_offset);
                }
                break;
            case ARG_LOCATION_STACK:
                rv64_mem_ld(buf, RV_SCRATCH1_REG, X_SP_REG, my_scratch_offset);
                rv64_mem_sd(buf, X_SP_REG, RV_SCRATCH1_REG, (int32_t)arg->location.stack_offset);
                break;
            default:
                break;
            }
        }
    }
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 3.5 (Direct): Generates the call instruction.
 */
static infix_status generate_direct_forward_call_instruction_riscv64(
    code_buffer * buf, c23_maybe_unused infix_direct_call_frame_layout * layout) {
    infix_riscv64_emit_load_u64_immediate(buf, RV_SCRATCH0_REG, (uint64_t)layout->target_fn);
    // A non-null target skips the ebreak and calls the target; a null target falls
    // through into the ebreak and traps. The target returns to the epilogue.
    infix_riscv64_emit_bne(buf, RV_SCRATCH0_REG, X_ZERO_REG, 8);
    infix_riscv64_emit_ebreak(buf);
    infix_riscv64_emit_jalr(buf, X_RA_REG, RV_SCRATCH0_REG, 0);
    return INFIX_SUCCESS;
}

/**
 * @internal
 * @brief Stage 4 (Direct): Generates the epilogue, including write-back calls.
 */
static infix_status generate_direct_forward_epilogue_riscv64(code_buffer * buf,
                                                             infix_direct_call_frame_layout * layout,
                                                             infix_type * ret_type) {
    layout->epilogue_offset = (uint32_t)buf->size;
    if (ret_type->category != INFIX_TYPE_VOID && !layout->return_value_in_memory) {
        rv64_return_class rc = rv64_classify_return(ret_type);
        if (rc.mixed) {
            rv64_emit_store_fp_value(buf, RV_CTX_RET_REG, F_FA0_REG, rc.fp_offsets[0], rc.fp_sizes[0]);
            rv64_emit_store_gpr_low_bytes(buf, RV_CTX_RET_REG, X_A0_REG, rc.int_offset, rc.int_size);
        }
        else if (rc.fp_count == 2) {
            rv64_emit_store_fp_value(buf, RV_CTX_RET_REG, F_FA0_REG, rc.fp_offsets[0], rc.fp_sizes[0]);
            rv64_emit_store_fp_value(buf, RV_CTX_RET_REG, F_FA1_REG, rc.fp_offsets[1], rc.fp_sizes[1]);
        }
        else if (rc.fp_count == 1) {
            rv64_emit_store_fp_value(buf, RV_CTX_RET_REG, F_FA0_REG, rc.fp_offsets[0], rc.fp_sizes[0]);
        }
        else {
            rv64_emit_store_gpr_return(buf, RV_CTX_RET_REG, ret_type->size);
        }
    }

    const size_t scratch_base_from_sp = rv64_direct_standard_alloc(layout);
    size_t epilogue_scratch_offset = 0;

    for (size_t i = 0; i < layout->num_args; ++i) {
        const infix_direct_arg_layout * arg = &layout->args[i];
        rv64_direct_scratch_info info = rv64_direct_scratch(arg);
        int32_t my_scratch_offset = -1;
        if (info.needs_scratch) {
            epilogue_scratch_offset = _infix_align_up(epilogue_scratch_offset, info.align);
            my_scratch_offset = (int32_t)(scratch_base_from_sp + epilogue_scratch_offset);
            epilogue_scratch_offset += info.size;
        }

        if (arg->handler->writeback_handler) {
            // Save the C return value before calling out.
            infix_riscv64_emit_addi(buf, X_SP_REG, X_SP_REG, -32);
            rv64_mem_sd(buf, X_SP_REG, X_A0_REG, 0);
            rv64_mem_sd(buf, X_SP_REG, X_A1_REG, 8);
            rv64_mem_fsd(buf, X_SP_REG, F_FA0_REG, 16);

            // a0 = language object
            rv64_mem_ld(buf, X_A0_REG, RV_CTX_ARGS_REG, (int32_t)(i * sizeof(void *)));
            // a1 = c_data_ptr (the scratch slot, 32 bytes above the current SP)
            rv64_emit_compute_addr(buf, X_A1_REG, X_SP_REG, 32 + my_scratch_offset);
            // a2 = type
            infix_riscv64_emit_load_u64_immediate(buf, X_A2_REG, (uint64_t)arg->type);
            // Call the handler.
            infix_riscv64_emit_load_u64_immediate(buf, RV_SCRATCH0_REG, (uint64_t)arg->handler->writeback_handler);
            infix_riscv64_emit_jalr(buf, X_RA_REG, RV_SCRATCH0_REG, 0);

            // Restore the C return value.
            rv64_mem_fld(buf, F_FA0_REG, X_SP_REG, 16);
            rv64_mem_ld(buf, X_A1_REG, X_SP_REG, 8);
            rv64_mem_ld(buf, X_A0_REG, X_SP_REG, 0);
            infix_riscv64_emit_addi(buf, X_SP_REG, X_SP_REG, 32);
        }
    }

    rv64_emit_stack_add(buf, (uint32_t)layout->total_stack_alloc);
    rv64_mem_ld(buf, RV_CTX_TARGET_REG, X_SP_REG, 0);
    rv64_mem_ld(buf, RV_CTX_RET_REG, X_SP_REG, 8);
    rv64_mem_ld(buf, RV_CTX_ARGS_REG, X_SP_REG, 16);
    rv64_mem_ld(buf, X_RA_REG, X_SP_REG, 24);
    infix_riscv64_emit_addi(buf, X_SP_REG, X_SP_REG, RV_FWD_SAVED_SIZE);
    infix_riscv64_emit_jalr(buf, X_ZERO_REG, X_RA_REG, 0);
    return INFIX_SUCCESS;
}
