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
 * @file abi_riscv64_emitters.c
 * @brief Emits single RISC-V (RV64GC) instructions into a `code_buffer`.
 * @ingroup internal_abi_riscv64
 *
 * @internal
 * Each function in this file encodes exactly one RISC-V instruction and appends
 * it to a `code_buffer`. The emitters are intentionally low-level: they do not
 * know about the FFI marshalling logic and instead serve as the instruction-level
 * building blocks for `abi_riscv64.c`.
 *
 * The encoding helpers (`rv_enc_*`) implement the base RISC-V instruction
 * formats (R, I, S, B, U, J) as described in "The RISC-V Instruction Set
 * Manual, Volume I".
 * @endinternal
 */
#include "arch/riscv/abi_riscv64_emitters.h"
#include "arch/riscv/abi_riscv64_common.h"
#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

// Instruction encoding helpers (RISC-V base formats)
/** @internal Mask a value to the signed 12-bit range `[-2048, 2047]`. */
static inline uint32_t rv_sx_imm12(int32_t imm) { return (uint32_t)(imm & 0xFFF); }
/** @internal Mask a value to the unsigned 20-bit range `[0, 0xFFFFF]`. */
static inline uint32_t rv_imm20(uint32_t imm) { return imm & 0xFFFFF; }

/** @internal R-type: `funct7 rs2 rs1 funct3 rd opcode`. */
static inline uint32_t rv_enc_r(
    uint32_t funct7, uint8_t rs2, uint8_t rs1, uint32_t funct3, uint8_t rd, uint32_t opcode) {
    return (funct7 << 25) | ((uint32_t)rs2 << RV_RS2_SHIFT) | ((uint32_t)rs1 << RV_RS1_SHIFT) |
        (funct3 << RV_FUNCT3_SHIFT) | ((uint32_t)rd << RV_RD_SHIFT) | opcode;
}
/** @internal I-type: `imm12 rs1 funct3 rd opcode`. */
static inline uint32_t rv_enc_i(uint32_t imm12, uint8_t rs1, uint32_t funct3, uint8_t rd, uint32_t opcode) {
    return (imm12 << 20) | ((uint32_t)rs1 << RV_RS1_SHIFT) | (funct3 << RV_FUNCT3_SHIFT) |
        ((uint32_t)rd << RV_RD_SHIFT) | opcode;
}
/** @internal S-type: `imm[11:5] rs2 rs1 funct3 imm[4:0] opcode`. */
static inline uint32_t rv_enc_s(uint32_t imm12, uint8_t rs2, uint8_t rs1, uint32_t funct3, uint32_t opcode) {
    return (((imm12 >> 5) & 0x7F) << 25) | ((uint32_t)rs2 << RV_RS2_SHIFT) | ((uint32_t)rs1 << RV_RS1_SHIFT) |
        (funct3 << RV_FUNCT3_SHIFT) | ((imm12 & 0x1F) << 7) | opcode;
}
/** @internal B-type: `imm[12|10:5] rs2 rs1 funct3 imm[4:1|11] opcode`. */
static inline uint32_t rv_enc_b(uint32_t imm13, uint8_t rs2, uint8_t rs1, uint32_t funct3, uint32_t opcode) {
    return (((imm13 >> 12) & 0x1) << 31) | (((imm13 >> 5) & 0x3F) << 25) | ((uint32_t)rs2 << RV_RS2_SHIFT) |
        ((uint32_t)rs1 << RV_RS1_SHIFT) | (funct3 << RV_FUNCT3_SHIFT) | (((imm13 >> 1) & 0xF) << 8) |
        (((imm13 >> 11) & 0x1) << 7) | opcode;
}
/** @internal U-type: `imm20 rd opcode`. */
static inline uint32_t rv_enc_u(uint32_t imm20, uint8_t rd, uint32_t opcode) {
    return (imm20 << 12) | ((uint32_t)rd << RV_RD_SHIFT) | opcode;
}
/** @internal J-type: `imm[20|10:1|11|19:12] rd opcode`. */
static inline uint32_t rv_enc_j(uint32_t imm21, uint8_t rd, uint32_t opcode) {
    return (((imm21 >> 20) & 0x1) << 31) | (((imm21 >> 1) & 0x3FF) << 21) | (((imm21 >> 11) & 0x1) << 20) |
        (((imm21 >> 12) & 0xFF) << 12) | ((uint32_t)rd << RV_RD_SHIFT) | opcode;
}
/** @internal Shift-immediate I-type (RV64): `funct6 shamt rs1 funct3 rd opcode`. */
static inline uint32_t rv_enc_shift(uint32_t funct6, uint8_t shamt, uint8_t rs1, uint32_t funct3, uint8_t rd) {
    return (funct6 << 26) | ((uint32_t)shamt << 20) | ((uint32_t)rs1 << RV_RS1_SHIFT) | (funct3 << RV_FUNCT3_SHIFT) |
        ((uint32_t)rd << RV_RD_SHIFT) | RV_OP_OP_IMM;
}
/** @internal Append a fully-encoded instruction word to a `code_buffer`. */
static inline void rv_emit(code_buffer * buf, uint32_t word) {
    if (buf->error)
        return;
    emit_int32(buf, (int32_t)word);
}

void infix_riscv64_emit_addi(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm), rs1, RV_F3_ADD_SUB, rd, RV_OP_OP_IMM));
}
void infix_riscv64_emit_addiw(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm), rs1, RV_F3_ADD_SUB, rd, RV_OP_OP_IMM_32));
}
void infix_riscv64_emit_add(code_buffer * buf, uint8_t rd, uint8_t rs1, uint8_t rs2) {
    rv_emit(buf, rv_enc_r(RV_F7_ADD, rs2, rs1, RV_F3_ADD_SUB, rd, RV_OP_OP));
}
void infix_riscv64_emit_sub(code_buffer * buf, uint8_t rd, uint8_t rs1, uint8_t rs2) {
    rv_emit(buf, rv_enc_r(RV_F7_SUB, rs2, rs1, RV_F3_ADD_SUB, rd, RV_OP_OP));
}
void infix_riscv64_emit_slli(code_buffer * buf, uint8_t rd, uint8_t rs1, uint8_t shamt) {
    rv_emit(buf, rv_enc_shift(RV_F6_SLLI, shamt & 0x3F, rs1, RV_F3_SLL, rd));
}
void infix_riscv64_emit_srli(code_buffer * buf, uint8_t rd, uint8_t rs1, uint8_t shamt) {
    rv_emit(buf, rv_enc_shift(RV_F6_SRLI, shamt & 0x3F, rs1, RV_F3_SR, rd));
}
void infix_riscv64_emit_lui(code_buffer * buf, uint8_t rd, uint32_t imm20) {
    rv_emit(buf, rv_enc_u(rv_imm20(imm20), rd, RV_OP_LUI));
}
void infix_riscv64_emit_auipc(code_buffer * buf, uint8_t rd, uint32_t imm20) {
    rv_emit(buf, rv_enc_u(rv_imm20(imm20), rd, RV_OP_AUIPC));
}
void infix_riscv64_emit_jal(code_buffer * buf, uint8_t rd, int32_t imm20) {
    rv_emit(buf, rv_enc_j((uint32_t)(imm20 & ~1), rd, RV_OP_JAL));
}
void infix_riscv64_emit_jalr(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm12), rs1, RV_F3_ADD_SUB, rd, RV_OP_JALR));
}
void infix_riscv64_emit_beq(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12) {
    rv_emit(buf, rv_enc_b((uint32_t)(imm12 & ~1), rs2, rs1, RV_F3_BEQ, RV_OP_BRANCH));
}
void infix_riscv64_emit_bne(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12) {
    rv_emit(buf, rv_enc_b((uint32_t)(imm12 & ~1), rs2, rs1, RV_F3_BNE, RV_OP_BRANCH));
}
void infix_riscv64_emit_ld(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm12), rs1, RV_F3_LD, rd, RV_OP_LOAD));
}
void infix_riscv64_emit_lw(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm12), rs1, RV_F3_LW, rd, RV_OP_LOAD));
}
void infix_riscv64_emit_lwu(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm12), rs1, RV_F3_LWU, rd, RV_OP_LOAD));
}
void infix_riscv64_emit_lb(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm12), rs1, RV_F3_LB, rd, RV_OP_LOAD));
}
void infix_riscv64_emit_lbu(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm12), rs1, RV_F3_LBU, rd, RV_OP_LOAD));
}
void infix_riscv64_emit_lh(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm12), rs1, RV_F3_LH, rd, RV_OP_LOAD));
}
void infix_riscv64_emit_lhu(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm12), rs1, RV_F3_LHU, rd, RV_OP_LOAD));
}
void infix_riscv64_emit_sd(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12) {
    rv_emit(buf, rv_enc_s(rv_sx_imm12(imm12), rs2, rs1, RV_F3_LD, RV_OP_STORE));
}
void infix_riscv64_emit_sw(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12) {
    rv_emit(buf, rv_enc_s(rv_sx_imm12(imm12), rs2, rs1, RV_F3_LW, RV_OP_STORE));
}
void infix_riscv64_emit_sb(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12) {
    rv_emit(buf, rv_enc_s(rv_sx_imm12(imm12), rs2, rs1, RV_F3_LB, RV_OP_STORE));
}
void infix_riscv64_emit_sh(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12) {
    rv_emit(buf, rv_enc_s(rv_sx_imm12(imm12), rs2, rs1, RV_F3_LH, RV_OP_STORE));
}
void infix_riscv64_emit_fld(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm12), rs1, RV_F3_FLD, rd, RV_OP_FLOAD));
}
void infix_riscv64_emit_fsd(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12) {
    rv_emit(buf, rv_enc_s(rv_sx_imm12(imm12), rs2, rs1, RV_F3_FLD, RV_OP_FSTORE));
}
void infix_riscv64_emit_flw(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12) {
    rv_emit(buf, rv_enc_i(rv_sx_imm12(imm12), rs1, RV_F3_FLW, rd, RV_OP_FLOAD));
}
void infix_riscv64_emit_fsw(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12) {
    rv_emit(buf, rv_enc_s(rv_sx_imm12(imm12), rs2, rs1, RV_F3_FLW, RV_OP_FSTORE));
}
void infix_riscv64_emit_fmv_d(code_buffer * buf, uint8_t rd, uint8_t rs1) {
    rv_emit(buf, rv_enc_r(RV_F7_FSGNJ_D, rs1, rs1, RV_F3_ADD_SUB, rd, RV_OP_FP));
}
void infix_riscv64_emit_fmv_s(code_buffer * buf, uint8_t rd, uint8_t rs1) {
    rv_emit(buf, rv_enc_r(RV_F7_FSGNJ_S, rs1, rs1, RV_F3_ADD_SUB, rd, RV_OP_FP));
}
void infix_riscv64_emit_fmv_w_x(code_buffer * buf, uint8_t rd, uint8_t rs1) {
    rv_emit(buf, rv_enc_r(RV_F7_FMV_S_X, 0, rs1, RV_F3_ADD_SUB, rd, RV_OP_FP));
}
void infix_riscv64_emit_fmv_x_w(code_buffer * buf, uint8_t rd, uint8_t rs1) {
    rv_emit(buf, rv_enc_r(RV_F7_FMV_X_S, 0, rs1, RV_F3_ADD_SUB, rd, RV_OP_FP));
}
void infix_riscv64_emit_fcvt_d_s(code_buffer * buf, uint8_t rd, uint8_t rs1) {
    rv_emit(buf, rv_enc_r(RV_F7_FCVT_D_S, RV_RS2_FCVT_D_S, rs1, RV_F3_ADD_SUB, rd, RV_OP_FP));
}
void infix_riscv64_emit_fcvt_s_d(code_buffer * buf, uint8_t rd, uint8_t rs1) {
    rv_emit(buf, rv_enc_r(RV_F7_FCVT_S_D, RV_RS2_FCVT_S_D, rs1, RV_F3_ADD_SUB, rd, RV_OP_FP));
}
void infix_riscv64_emit_ebreak(code_buffer * buf) { rv_emit(buf, 0x00100073U); }
/**
 * @internal
 * @brief Materialize an arbitrary 64-bit immediate into `rd`.
 * @details This mirrors the AArch64 `emit_arm64_load_u64_immediate` used to load
 *          absolute function/context addresses into registers. It uses the RISC-V
 *          assembler's standard `li` expansion:
 *
 *          - A value that fits in a signed 12-bit immediate becomes a single `addi rd, x0, imm`.
 *          - A value whose upper 32 bits are the sign-extension of bit 31 becomes
 *            `lui`+`addiw` (four bytes).
 *          - Anything else becomes `lui`/`addiw`/`slli` to place the low 32 bits,
 *            then `lui`/`addi`/`add` to merge in the high 32 bits (12 bytes).
 *
 *          The scratch register used in the general case is `RV_SCRATCH2_REG`
 *          (x7). It is never used as a value register by any other part of the
 *          RISC-V backend, so it is safe to clobber here regardless of `rd`.
 * @param buf The code buffer.
 * @param rd The destination general-purpose register.
 * @param imm The 64-bit value to materialize.
 */
void infix_riscv64_emit_load_u64_immediate(code_buffer * buf, uint8_t rd, uint64_t imm) {
    const int64_t simm = (int64_t)imm;
    if (simm >= -2048 && simm <= 2047) {
        infix_riscv64_emit_addi(buf, rd, X_ZERO_REG, (int32_t)simm);
        return;
    }
    if (simm >= INT32_MIN && simm <= INT32_MAX) {
        // lui + addiw
        const int64_t hi = (simm + 0x800) >> 12;
        const int64_t lo = simm - (hi << 12);
        infix_riscv64_emit_lui(buf, rd, (uint32_t)(hi & 0xFFFFF));
        infix_riscv64_emit_addiw(buf, rd, rd, (int32_t)lo);
        return;
    }
    // Check whether the value is the sign-extension of its low 32 bits.
    if (simm == (int64_t)(int32_t)(uint32_t)imm) {
        const int32_t imm32 = (int32_t)(uint32_t)imm;
        const int64_t hi = ((int64_t)imm32 + 0x800) >> 12;
        const int64_t lo = (int64_t)imm32 - (hi << 12);
        infix_riscv64_emit_lui(buf, rd, (uint32_t)(hi & 0xFFFFF));
        infix_riscv64_emit_addiw(buf, rd, rd, (int32_t)lo);
        return;
    }
    // General 64-bit case: (high32 << 32) | low32.
    // The low 32 bits are merged in zero-extended so the result is exact even when
    // bit 31 of `low32` is set.
    const uint32_t hi32 = (uint32_t)(imm >> 32);
    const uint32_t lo32 = (uint32_t)imm;
    {
        // rd = (sign-extended hi32) << 32 == hi32 << 32 (exact mod 2^64).
        const int32_t hi_s = (int32_t)hi32;
        const int32_t h = (int32_t)(((int64_t)hi_s + 0x800) >> 12);
        const int32_t l = hi_s - (h << 12);
        infix_riscv64_emit_lui(buf, rd, (uint32_t)(h & 0xFFFFF));
        infix_riscv64_emit_addiw(buf, rd, rd, l);
        infix_riscv64_emit_slli(buf, rd, rd, 32);
    }
    {
        // Scratch = zero-extended lo32, then OR it in.
        const int32_t lo_s = (int32_t)lo32;
        const int32_t h = (int32_t)(((int64_t)lo_s + 0x800) >> 12);
        const int32_t l = lo_s - (h << 12);
        infix_riscv64_emit_lui(buf, RV_SCRATCH2_REG, (uint32_t)(h & 0xFFFFF));
        infix_riscv64_emit_addiw(buf, RV_SCRATCH2_REG, RV_SCRATCH2_REG, l);
        infix_riscv64_emit_slli(buf, RV_SCRATCH2_REG, RV_SCRATCH2_REG, 32);
        infix_riscv64_emit_srli(buf, RV_SCRATCH2_REG, RV_SCRATCH2_REG, 32);
        infix_riscv64_emit_add(buf, rd, rd, RV_SCRATCH2_REG);
    }
}
