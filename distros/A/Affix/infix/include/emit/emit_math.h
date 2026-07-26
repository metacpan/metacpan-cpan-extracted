/**
 * Copyright (c) 2025 Sanko Robinson
 *
 * This source code is dual-licensed under the Artistic License 2.0 or the MIT License.
 * You may choose to use the code under the terms of either license.
 *
 * SPDX-License-Identifier: (Artistic-2.0 OR MIT)
 */
/**
 * @file emit_math.h
 * @brief Math operations for JIT code generation.
 */
#ifndef INFIX_EMIT_MATH_H
#define INFIX_EMIT_MATH_H

#include "emit.h"
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    EMIT_CC_O,
    EMIT_CC_NO,
    EMIT_CC_B,
    EMIT_CC_AE,
    EMIT_CC_E,
    EMIT_CC_NE,
    EMIT_CC_BE,
    EMIT_CC_A,
    EMIT_CC_S,
    EMIT_CC_NS,
    EMIT_CC_P,
    EMIT_CC_NP,
    EMIT_CC_L,
    EMIT_CC_GE,
    EMIT_CC_LE,
    EMIT_CC_G,
} emit_cc_t;

typedef enum {
    EMIT_REG_RAX = 0,
    EMIT_REG_RCX = 1,
    EMIT_REG_RDX = 2,
    EMIT_REG_RBX = 3,
    EMIT_REG_RSP = 4,
    EMIT_REG_RBP = 5,
    EMIT_REG_RSI = 6,
    EMIT_REG_RDI = 7,
    EMIT_REG_R8 = 8,
    EMIT_REG_R9 = 9,
    EMIT_REG_R10 = 10,
    EMIT_REG_R11 = 11,
    EMIT_REG_R12 = 12,
    EMIT_REG_R13 = 13,
    EMIT_REG_R14 = 14,
    EMIT_REG_R15 = 15,
} emit_register_t;

INFIX_API infix_status emit_math_mov_imm(emit_context_t * ctx, emit_register_t dest, uint64_t imm);
INFIX_API infix_status emit_math_mov_reg(emit_context_t * ctx, emit_register_t dest, emit_register_t src);
INFIX_API infix_status emit_math_movq_gpr_xmm(emit_context_t * ctx, emit_register_t gpr_dest, emit_register_t xmm_src);
INFIX_API infix_status emit_math_movsd_reg(emit_context_t * ctx, emit_register_t dest, emit_register_t src);
INFIX_API infix_status emit_math_addsd(emit_context_t * ctx, emit_register_t dest, emit_register_t src);
INFIX_API infix_status emit_math_load_f64(emit_context_t * ctx,
                                          emit_register_t dest,
                                          emit_register_t base,
                                          int32_t offset);

INFIX_API infix_status emit_math_add(emit_context_t * ctx, emit_register_t dest, emit_register_t src);
INFIX_API infix_status emit_math_add_imm(emit_context_t * ctx, emit_register_t dest, int32_t imm);
INFIX_API infix_status emit_math_sub(emit_context_t * ctx, emit_register_t dest, emit_register_t src);
INFIX_API infix_status emit_math_sub_imm(emit_context_t * ctx, emit_register_t dest, int32_t imm);
INFIX_API infix_status emit_math_mul(emit_context_t * ctx, emit_register_t src);
INFIX_API infix_status emit_math_imul_imm(emit_context_t * ctx, emit_register_t dest, int32_t imm);

INFIX_API infix_status emit_math_and(emit_context_t * ctx, emit_register_t dest, emit_register_t src);
INFIX_API infix_status emit_math_or(emit_context_t * ctx, emit_register_t dest, emit_register_t src);
INFIX_API infix_status emit_math_xor(emit_context_t * ctx, emit_register_t dest, emit_register_t src);
INFIX_API infix_status emit_math_not(emit_context_t * ctx, emit_register_t reg);
INFIX_API infix_status emit_math_neg(emit_context_t * ctx, emit_register_t reg);

INFIX_API infix_status emit_math_shl(emit_context_t * ctx, emit_register_t dest, emit_register_t src);
INFIX_API infix_status emit_math_shr(emit_context_t * ctx, emit_register_t dest, emit_register_t src);
INFIX_API infix_status emit_math_sal(emit_context_t * ctx, emit_register_t reg, uint8_t amount);
INFIX_API infix_status emit_math_sar(emit_context_t * ctx, emit_register_t reg, uint8_t amount);

INFIX_API infix_status emit_math_cmp(emit_context_t * ctx, emit_register_t a, emit_register_t b);
INFIX_API infix_status emit_math_cmp_imm(emit_context_t * ctx, emit_register_t reg, int32_t imm);
INFIX_API infix_status emit_math_test(emit_context_t * ctx, emit_register_t a, emit_register_t b);

INFIX_API infix_status emit_math_jmp(emit_context_t * ctx, const char * label);
INFIX_API infix_status emit_math_jmp_cc(emit_context_t * ctx, emit_cc_t cc, const char * label);
INFIX_API infix_status emit_math_call(emit_context_t * ctx, const char * name);
INFIX_API infix_status emit_math_prologue(emit_context_t * ctx);
INFIX_API infix_status emit_math_epilogue(emit_context_t * ctx);
INFIX_API infix_status emit_math_ret(emit_context_t * ctx);

INFIX_API infix_status emit_math_push(emit_context_t * ctx, emit_register_t reg);
INFIX_API infix_status emit_math_pop(emit_context_t * ctx, emit_register_t reg);

INFIX_API infix_status emit_math_load_reg(emit_context_t * ctx,
                                          emit_register_t dest,
                                          emit_register_t base,
                                          int32_t offset);
INFIX_API infix_status emit_math_store_reg(emit_context_t * ctx,
                                           emit_register_t base,
                                           int32_t offset,
                                           emit_register_t src);

INFIX_API infix_status emit_math_load_sym(emit_context_t * ctx, emit_register_t dest, const char * sym);
INFIX_API infix_status emit_math_store_sym(emit_context_t * ctx, const char * sym, emit_register_t src);

#ifdef __cplusplus
}
#endif

#endif /* INFIX_EMIT_MATH_H */
