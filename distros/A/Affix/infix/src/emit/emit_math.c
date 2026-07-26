/**
 * Copyright (c) 2025 Sanko Robinson
 *
 * This source code is dual-licensed under the Artistic License 2.0 or the MIT License.
 * You may choose to use the code under the terms of either license.
 *
 * SPDX-License-Identifier: (Artistic-2.0 OR MIT)
 */
/**
 * @file emit_math.c
 * @brief Math operations for JIT code generation (x86-64 and ARM64).
 */
#include "emit/emit_math.h"
#include "emit/emit.h"
#include "emit_internals.h"
#include <stdio.h>
#include <string.h>

#define EMIT_CHECK(x)            \
    do {                         \
        infix_status _s = (x);   \
        if (_s != INFIX_SUCCESS) \
            return _s;           \
    } while (0)

#define EMIT_REG_NEEDS_REX(reg) ((reg) >= 8)

static infix_status emit_x86_rex(emit_context_t * ctx, bool w, bool r, bool x, bool b) {
    if (ctx->arch == EMIT_ARCH_X86_64 && (w || r || x || b)) {
        uint8_t rex = 0x40 | (w << 3) | (r << 2) | (x << 1) | b;
        return emit_emit_u8(ctx, rex);
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_mov_imm(emit_context_t * ctx, emit_register_t dest, uint64_t imm) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, false, false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0xB8 | (dest & 0x07)));
        EMIT_CHECK(emit_emit_u64(ctx, imm));
    }
    return INFIX_SUCCESS;
}
INFIX_API infix_status emit_math_movq_gpr_xmm(emit_context_t * ctx, emit_register_t gpr_dest, emit_register_t xmm_src) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        /* MOVQ r64, xmm -> 66 REX.W 0F 7E /r */
        EMIT_CHECK(emit_emit_u8(ctx, 0x66));
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(xmm_src), false, EMIT_REG_NEEDS_REX(gpr_dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x0F));
        EMIT_CHECK(emit_emit_u8(ctx, 0x7E));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((xmm_src & 0x07) << 3) | (gpr_dest & 0x07)));
    }
    return INFIX_SUCCESS;
}
INFIX_API infix_status emit_math_mov_reg(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(src), false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x89));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((src & 0x07) << 3) | (dest & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_add(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(src), false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x01));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((src & 0x07) << 3) | (dest & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_add_imm(emit_context_t * ctx, emit_register_t dest, int32_t imm) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, false, false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x81));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | (dest & 0x07)));
        EMIT_CHECK(emit_emit_u32(ctx, (uint32_t)imm));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_sub(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(src), false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x29));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((src & 0x07) << 3) | (dest & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_sub_imm(emit_context_t * ctx, emit_register_t dest, int32_t imm) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, false, false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x81));
        EMIT_CHECK(emit_emit_u8(ctx, 0xE8 | (dest & 0x07)));
        EMIT_CHECK(emit_emit_u32(ctx, (uint32_t)imm));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_mul(emit_context_t * ctx, emit_register_t src) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, false, false, EMIT_REG_NEEDS_REX(src)));
        EMIT_CHECK(emit_emit_u8(ctx, 0xF7));
        EMIT_CHECK(emit_emit_u8(ctx, 0xE0 | (src & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_imul_imm(emit_context_t * ctx, emit_register_t dest, int32_t imm) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(dest), false, EMIT_REG_NEEDS_REX(dest)));
        if (imm >= -128 && imm <= 127) {
            EMIT_CHECK(emit_emit_u8(ctx, 0x6B));
            EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((dest & 0x07) << 3) | (dest & 0x07)));
            EMIT_CHECK(emit_emit_u8(ctx, (uint8_t)imm));
        }
        else {
            EMIT_CHECK(emit_emit_u8(ctx, 0x69));
            EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((dest & 0x07) << 3) | (dest & 0x07)));
            EMIT_CHECK(emit_emit_u32(ctx, (uint32_t)imm));
        }
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_and(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(src), false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x21));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((src & 0x07) << 3) | (dest & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_or(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(src), false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x09));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((src & 0x07) << 3) | (dest & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_xor(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(src), false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x31));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((src & 0x07) << 3) | (dest & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_not(emit_context_t * ctx, emit_register_t reg) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, false, false, EMIT_REG_NEEDS_REX(reg)));
        EMIT_CHECK(emit_emit_u8(ctx, 0xF7));
        EMIT_CHECK(emit_emit_u8(ctx, 0xD0 | (reg & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_neg(emit_context_t * ctx, emit_register_t reg) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, false, false, EMIT_REG_NEEDS_REX(reg)));
        EMIT_CHECK(emit_emit_u8(ctx, 0xF7));
        EMIT_CHECK(emit_emit_u8(ctx, 0xD8 | (reg & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_shl(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        if (src != EMIT_REG_RCX)
            return INFIX_ERROR_INVALID_ARGUMENT;
        EMIT_CHECK(emit_x86_rex(ctx, true, false, false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0xD3));
        EMIT_CHECK(emit_emit_u8(ctx, 0xE0 | (dest & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_shr(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        if (src != EMIT_REG_RCX)
            return INFIX_ERROR_INVALID_ARGUMENT;
        EMIT_CHECK(emit_x86_rex(ctx, true, false, false, EMIT_REG_NEEDS_REX(dest)));
        EMIT_CHECK(emit_emit_u8(ctx, 0xD3));
        EMIT_CHECK(emit_emit_u8(ctx, 0xE8 | (dest & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_cmp(emit_context_t * ctx, emit_register_t a, emit_register_t b) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(b), false, EMIT_REG_NEEDS_REX(a)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x39));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((b & 0x07) << 3) | (a & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_cmp_imm(emit_context_t * ctx, emit_register_t reg, int32_t imm) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, false, false, EMIT_REG_NEEDS_REX(reg)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x81));
        EMIT_CHECK(emit_emit_u8(ctx, 0xF8 | (reg & 0x07)));
        EMIT_CHECK(emit_emit_u32(ctx, (uint32_t)imm));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_test(emit_context_t * ctx, emit_register_t a, emit_register_t b) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(b), false, EMIT_REG_NEEDS_REX(a)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x85));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((b & 0x07) << 3) | (a & 0x07)));
    }
    return INFIX_SUCCESS;
}

static const uint8_t x86_jcc_opcodes[16] = {
    0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F};

INFIX_API infix_status emit_math_jmp(emit_context_t * ctx, const char * label) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        uint64_t jump_offset = ctx->current_section->size;
        EMIT_CHECK(emit_emit_u8(ctx, 0xE9));
        EMIT_CHECK(emit_emit_u32(ctx, 0));
        EMIT_CHECK(emit_add_relocation(ctx, label, jump_offset + 1, 4, 5));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_jmp_cc(emit_context_t * ctx, emit_cc_t cc, const char * label) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        uint64_t jump_offset = ctx->current_section->size;
        EMIT_CHECK(emit_emit_u8(ctx, 0x0F));
        EMIT_CHECK(emit_emit_u8(ctx, x86_jcc_opcodes[cc]));
        EMIT_CHECK(emit_emit_u32(ctx, 0));
        EMIT_CHECK(emit_add_relocation(ctx, label, jump_offset + 2, 4, 6));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_call(emit_context_t * ctx, const char * name) {
    _infix_clear_error();
    if (!ctx)
        return INFIX_ERROR_INVALID_ARGUMENT;
    if (ctx->arch == EMIT_ARCH_X86_64) {
        uint64_t call_offset = ctx->current_section->size;
        EMIT_CHECK(emit_emit_u8(ctx, 0xE8));
        EMIT_CHECK(emit_emit_u32(ctx, 0));
        EMIT_CHECK(emit_add_relocation(ctx, name, call_offset + 1, 4, 5));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_prologue(emit_context_t * ctx) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_emit_u8(ctx, 0x55));
        EMIT_CHECK(emit_emit_u8(ctx, 0x48));
        EMIT_CHECK(emit_emit_u8(ctx, 0x8B));
        EMIT_CHECK(emit_emit_u8(ctx, 0xEC));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_epilogue(emit_context_t * ctx) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_emit_u8(ctx, 0xC9));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC3));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_ret(emit_context_t * ctx) {
    if (ctx->arch == EMIT_ARCH_X86_64)
        EMIT_CHECK(emit_emit_u8(ctx, 0xC3));
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_push(emit_context_t * ctx, emit_register_t reg) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, false, false, false, EMIT_REG_NEEDS_REX(reg)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x50 | (reg & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_pop(emit_context_t * ctx, emit_register_t reg) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_x86_rex(ctx, false, false, false, EMIT_REG_NEEDS_REX(reg)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x58 | (reg & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_load_reg(emit_context_t * ctx,
                                          emit_register_t dest,
                                          emit_register_t base,
                                          int32_t offset) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        uint8_t mod = (offset == 0 && (base & 0x07) != 5) ? 0x00 : ((offset >= -128 && offset <= 127) ? 0x40 : 0x80);
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(dest), false, EMIT_REG_NEEDS_REX(base)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x8B));
        EMIT_CHECK(emit_emit_u8(ctx, mod | ((dest & 0x07) << 3) | (base & 0x07)));
        if ((base & 0x07) == 4)
            EMIT_CHECK(emit_emit_u8(ctx, 0x24));
        if (mod == 0x40)
            EMIT_CHECK(emit_emit_u8(ctx, (uint8_t)offset));
        else if (mod == 0x80)
            EMIT_CHECK(emit_emit_u32(ctx, (uint32_t)offset));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_store_reg(emit_context_t * ctx,
                                           emit_register_t base,
                                           int32_t offset,
                                           emit_register_t src) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        uint8_t mod = (offset == 0 && (base & 0x07) != 5) ? 0x00 : ((offset >= -128 && offset <= 127) ? 0x40 : 0x80);
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(src), false, EMIT_REG_NEEDS_REX(base)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x89));
        EMIT_CHECK(emit_emit_u8(ctx, mod | ((src & 0x07) << 3) | (base & 0x07)));
        if ((base & 0x07) == 4)
            EMIT_CHECK(emit_emit_u8(ctx, 0x24));
        if (mod == 0x40)
            EMIT_CHECK(emit_emit_u8(ctx, (uint8_t)offset));
        else if (mod == 0x80)
            EMIT_CHECK(emit_emit_u32(ctx, (uint32_t)offset));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_load_sym(emit_context_t * ctx, emit_register_t dest, const char * sym) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        uint64_t load_offset = ctx->current_section->size;
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(dest), false, false));
        EMIT_CHECK(emit_emit_u8(ctx, 0x8B));
        EMIT_CHECK(emit_emit_u8(ctx, 0x05 | ((dest & 0x07) << 3)));
        EMIT_CHECK(emit_emit_u32(ctx, 0));
        EMIT_CHECK(emit_add_relocation(ctx, sym, load_offset + 3, 4, 7));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_store_sym(emit_context_t * ctx, const char * sym, emit_register_t src) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        uint64_t store_offset = ctx->current_section->size;
        EMIT_CHECK(emit_x86_rex(ctx, true, EMIT_REG_NEEDS_REX(src), false, false));
        EMIT_CHECK(emit_emit_u8(ctx, 0x89));
        EMIT_CHECK(emit_emit_u8(ctx, 0x05 | ((src & 0x07) << 3)));
        EMIT_CHECK(emit_emit_u32(ctx, 0));
        EMIT_CHECK(emit_add_relocation(ctx, sym, store_offset + 3, 4, 7));
    }
    return INFIX_SUCCESS;
}

/* Floating Point Operations */
INFIX_API infix_status emit_math_movsd_reg(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_emit_u8(ctx, 0xF2));
        EMIT_CHECK(emit_x86_rex(ctx, false, EMIT_REG_NEEDS_REX(dest), false, EMIT_REG_NEEDS_REX(src)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x0F));
        EMIT_CHECK(emit_emit_u8(ctx, 0x10));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((dest & 0x07) << 3) | (src & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_addsd(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_emit_u8(ctx, 0xF2));
        EMIT_CHECK(emit_x86_rex(ctx, false, EMIT_REG_NEEDS_REX(dest), false, EMIT_REG_NEEDS_REX(src)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x0F));
        EMIT_CHECK(emit_emit_u8(ctx, 0x58));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((dest & 0x07) << 3) | (src & 0x07)));
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_math_subsd(emit_context_t * ctx, emit_register_t dest, emit_register_t src) {
    if (ctx->arch == EMIT_ARCH_X86_64) {
        EMIT_CHECK(emit_emit_u8(ctx, 0xF2));
        EMIT_CHECK(emit_x86_rex(ctx, false, EMIT_REG_NEEDS_REX(dest), false, EMIT_REG_NEEDS_REX(src)));
        EMIT_CHECK(emit_emit_u8(ctx, 0x0F));
        EMIT_CHECK(emit_emit_u8(ctx, 0x5C));
        EMIT_CHECK(emit_emit_u8(ctx, 0xC0 | ((dest & 0x07) << 3) | (src & 0x07)));
    }
    return INFIX_SUCCESS;
}
