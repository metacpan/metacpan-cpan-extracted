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
 * @file abi_arm64_emitters.c
 * @brief Implements internal helper functions for emitting AArch64 machine code.
 * @ingroup internal_abi_aarch64
 *
 * @internal
 * This file provides the concrete implementations for the low-level AArch64
 * instruction emitters. Each function constructs a single, valid 32-bit AArch64
 * instruction word from its component parts (registers, immediates, etc.) and
 * appends it to a `code_buffer`.
 *
 * This module encapsulates the bitwise logic for encoding ARM64 instructions,
 * keeping the main `abi_arm64.c` file focused on the higher-level logic of
 * applying the AAPCS64 ABI rules.
 * @endinternal
 */
#include "arch/aarch64/abi_arm64_emitters.h"
#include "common/utility.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
// GPR <-> Immediate Value Emitters
/*
 * @internal
 * @brief Emits a single AArch64 `MOVZ` or `MOVK` instruction.
 * @details This is a fundamental building block for loading large 64-bit constants.
 *          - `MOVZ` (Move Wide with Zero): Zeros the register and writes a 16-bit immediate.
 *          - `MOVK` (Move Wide with Keep): Writes a 16-bit immediate, preserving other bits.
 *
 *          Opcode format (MOVZ, 64-bit): 1 1 0 100101 hw imm16 Rd  (base 0xD2800000)
 *          Opcode format (MOVK, 64-bit): 1 1 1 100101 hw imm16 Rd  (base 0xF2800000)
 *
 * @param buf The code buffer to append the instruction to.
 * @param is_movz If true, emits `MOVZ`; otherwise, emits `MOVK`.
 * @param dest_reg The destination GPR (X0-X30).
 * @param imm The 16-bit immediate value to load.
 * @param shift_count The left shift to apply (0 for LSL #0, 1 for LSL #16, etc.).
 */
INFIX_INTERNAL void emit_arm64_mov_imm_chunk(
    code_buffer * buf, bool is_movz, uint64_t dest_reg, uint16_t imm, uint8_t shift_count) {
    if (buf->error)
        return;
    // Base encoding for MOVZ Xd, #imm, LSL #shift
    uint32_t instr = A64_SF_64BIT | A64_OP_MOVE_WIDE_IMM | A64_OPC_MOVZ;
    if (!is_movz)
        // Change opcode from MOVZ to MOVK by setting the 'opc' field to '11'.
        instr = (instr & ~A64_OPC_MOVZ) | A64_OPC_MOVK;
    // 'hw' field encodes the shift: 00=LSL 0, 01=LSL 16, 10=LSL 32, 11=LSL 48.
    instr |= ((uint32_t)shift_count & 0x3) << 21;
    // 'imm16' field holds the 16-bit immediate.
    instr |= ((uint32_t)imm & 0xFFFF) << 5;
    // 'Rd' field holds the destination register.
    instr |= (dest_reg & 0x1F);
    emit_int32(buf, instr);
}
/**
 * @internal
 * @brief Emits a sequence of instructions to load an arbitrary 64-bit immediate into a GPR.
 * @details As AArch64 instructions are fixed-size, loading a full 64-bit value requires
 *          multiple instructions. This function implements the standard pattern of one
 *          `MOVZ` followed by up to three `MOVK` instructions. It intelligently omits
 *          `MOVK` for any 16-bit chunk that is zero.
 * @param buf The code buffer.
 * @param dest The destination GPR.
 * @param value The 64-bit immediate value to load.
 */
INFIX_INTERNAL void emit_arm64_load_u64_immediate(code_buffer * buf, arm64_gpr dest, uint64_t value) {
    // Load the lowest 16 bits with MOVZ (zeros the rest of the register).
    emit_arm64_mov_imm_chunk(buf, true, dest, (value >> 0) & 0xFFFF, 0);
    // For each subsequent 16-bit chunk, use MOVK (Move Wide with Keep) only if
    // the chunk is not zero to avoid emitting redundant instructions.
    if ((value >> 16) & 0xFFFF)
        emit_arm64_mov_imm_chunk(buf, false, dest, (value >> 16) & 0xFFFF, 1);
    if ((value >> 32) & 0xFFFF)
        emit_arm64_mov_imm_chunk(buf, false, dest, (value >> 32) & 0xFFFF, 2);
    if ((value >> 48) & 0xFFFF)
        emit_arm64_mov_imm_chunk(buf, false, dest, (value >> 48) & 0xFFFF, 3);
}
// GPR <-> GPR Move Emitters
/*
 * @internal
 * @brief Emits a `MOV` instruction for a register-to-register move.
 * @details This is an alias for another instruction. For GPRs, `MOV Xd, Xn` is
 *          encoded as `ORR Xd, XZR, Xn` (bitwise OR with the zero register).
 *          For moves involving the Stack Pointer, it's an alias for `ADD Xd, SP, #0`.
 *
 *          Encodes `MOV Xd, Xn` which is an alias for `ORR Xd, XZR, Xn`.
 *
 *          Opcode (64-bit): 10101010000111110000001111100000 (0xAA1F03E0) + dest
 *
 *          This requires a special case for moving the stack pointer.
 * @param buf The code buffer.
 * @param is64 True for a 64-bit move (X registers), false for 32-bit (W registers).
 * @param dest The destination register.
 * @param src The source register.
 */
INFIX_INTERNAL void emit_arm64_mov_reg(code_buffer * buf, bool is64, arm64_gpr dest, arm64_gpr src) {
    if (buf->error)
        return;
    // Special case: MOV to/from SP is an alias for ADD Xd, SP, #0.
    // The generic ORR-based alias treats register 31 as XZR, not SP.
    if (dest == SP_REG || src == SP_REG) {
        uint32_t instr = (is64 ? A64_SF_64BIT : A64_SF_32BIT) | A64_OP_ADD_SUB_IMM | A64_OPC_ADD;
        instr |= (uint32_t)(src & 0x1F) << 5;  // Rn
        instr |= (uint32_t)(dest & 0x1F);      // Rd
        emit_int32(buf, instr);
        return;
    }
    // Standard case: MOV is an alias for ORR Xd, XZR, Xn
    uint32_t instr = (is64 ? A64_SF_64BIT : A64_SF_32BIT) | A64_OP_LOGICAL_REG | A64_OPCODE_ORR;
    instr |= (uint32_t)(src & 0x1F) << 16;  // Rm (source register)
    instr |= (31U) << 5;                    // Rn (XZR/WZR - the zero register)
    instr |= (uint32_t)(dest & 0x1F);       // Rd (destination register)
    emit_int32(buf, instr);
}
// Memory <-> GPR Load/Store Emitters
/**
 * @internal
 * @brief Emits a `LDR` (Load Register) instruction with an unsigned immediate offset.
 * @details Assembly: `LDR <Wt|Xt>, [<Xn|SP>, #pimm]`
 *
 *          Opcode (64-bit): 11_111_00_1_01_... (base 0xB9400000)
 *          Opcode (32-bit): 10_111_00_1_01_... (base 0x79400000)
 *
 * @param buf The code buffer.
 * @param is64 True to load 64 bits (`Xt`), false to load 32 bits (`Wt`).
 * @param dest The destination GPR.
 * @param base The base address register (GPR or SP).
 * @param offset The byte offset from the base register. Must be a multiple of the access size.
 */
INFIX_INTERNAL void emit_arm64_ldr_imm(code_buffer * buf, bool is64, arm64_gpr dest, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    const int scale = is64 ? 8 : 4;

    if (offset >= 0 && offset % scale == 0 && (offset / scale) <= 0xFFF) {
        uint32_t size_bits = is64 ? (0b11U << 30) : (0b10U << 30);
        uint32_t instr = size_bits | A64_OP_LOAD_STORE_IMM_UNSIGNED | A64_LDR_OP;
        instr |= ((uint32_t)(offset / scale) & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(dest & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        // Fallback for large/unaligned/negative offsets: compute address into X16
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_ldr_imm(buf, is64, dest, X16_REG, 0);
    }
}
/**
 * @internal
 * @brief Emits a `LDRB` (Load Register Byte) instruction.
 * @details Opcode: 00_111_00_1_01_... (base 0x39400000)
 */
INFIX_INTERNAL void emit_arm64_ldrb_imm(code_buffer * buf, arm64_gpr dest, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    if (offset >= 0 && offset <= 0xFFF) {
        uint32_t instr = 0x39400000;
        instr |= ((uint32_t)offset & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(dest & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_ldrb_imm(buf, dest, X16_REG, 0);
    }
}
/**
 * @internal
 * @brief Emits a `LDRH` (Load Register Halfword) instruction.
 * @details Opcode: 01_111_00_1_01_... (base 0x79400000)
 */
INFIX_INTERNAL void emit_arm64_ldrh_imm(code_buffer * buf, arm64_gpr dest, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    if (offset >= 0 && offset % 2 == 0 && (offset / 2) <= 0xFFF) {
        uint32_t instr = 0x79400000;
        instr |= ((uint32_t)(offset / 2) & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(dest & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_ldrh_imm(buf, dest, X16_REG, 0);
    }
}
/**
 * @internal
 * @brief Emits a `LDRSW` (Load Register Signed Word) instruction.
 * @details Assembly: `LDRSW <Xt>, [<Xn|SP>, #pimm]`
 *          This loads a 32-bit value from memory and sign-extends it to 64 bits.
 *
 *          Opcode: 10_111_00_1_10_... (base 0xB9800000)
 *
 * @param buf The code buffer.
 * @param dest The 64-bit destination GPR (`Xt`).
 * @param base The base address register.
 * @param offset The byte offset, which must be a multiple of 4.
 */
INFIX_INTERNAL void emit_arm64_ldrsw_imm(code_buffer * buf, arm64_gpr dest, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    if (offset >= 0 && offset % 4 == 0 && (offset / 4) <= 0xFFF) {
        uint32_t instr = (0b10U << 30) | A64_OP_LOAD_STORE_IMM_UNSIGNED | (0b10U << 22);
        instr |= ((uint32_t)(offset / 4) & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(dest & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        // Fallback
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_ldrsw_imm(buf, dest, X16_REG, 0);
    }
}
/**
 * @internal
 * @brief Emits a `LDRSB` (Load Register Signed Byte) instruction (64-bit destination).
 * @details Opcode: 00_111_00_1_10_... (base 0x39800000)
 */
INFIX_INTERNAL void emit_arm64_ldrsb_imm(code_buffer * buf, arm64_gpr dest, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    if (offset >= 0 && offset <= 0xFFF) {
        uint32_t instr = 0x39800000;
        instr |= ((uint32_t)offset & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(dest & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_ldrsb_imm(buf, dest, X16_REG, 0);
    }
}
/**
 * @internal
 * @brief Emits a `LDRSH` (Load Register Signed Halfword) instruction (64-bit destination).
 * @details Opcode: 01_111_00_1_10_... (base 0x79800000)
 */
INFIX_INTERNAL void emit_arm64_ldrsh_imm(code_buffer * buf, arm64_gpr dest, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    if (offset >= 0 && offset % 2 == 0 && (offset / 2) <= 0xFFF) {
        uint32_t instr = 0x79800000;
        instr |= ((uint32_t)(offset / 2) & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(dest & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_ldrsh_imm(buf, dest, X16_REG, 0);
    }
}
/**
 * @internal
 * @brief Emits a `STR` (Store Register) instruction with an unsigned immediate offset.
 * @details Assembly: `STR <Wt|Xt>, [<Xn|SP>, #pimm]`
 *
 *          Opcode (64-bit): 11_111_00_1_00_... (base 0xB9000000)
 *          Opcode (32-bit): 10_111_00_1_00_... (base 0x79000000)
 *
 * @param buf The code buffer.
 * @param is64 True to store 64 bits (`Xt`), false to store 32 bits (`Wt`).
 * @param src The source GPR.
 * @param base The base address register.
 * @param offset The byte offset, a multiple of the access size.
 */
INFIX_INTERNAL void emit_arm64_str_imm(code_buffer * buf, bool is64, arm64_gpr src, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    const int scale = is64 ? 8 : 4;
    if (offset >= 0 && offset % scale == 0 && (offset / scale) <= 0xFFF) {
        uint32_t size_bits = is64 ? (0b11U << 30) : (0b10U << 30);
        uint32_t instr = size_bits | A64_OP_LOAD_STORE_IMM_UNSIGNED;
        instr |= ((uint32_t)(offset / scale) & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(src & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        // Fallback
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_str_imm(buf, is64, src, X16_REG, 0);
    }
}

/**
 * @internal
 * @brief Emits a `STRB` (Store Register Byte) instruction.
 * @details Assembly: `STRB <Wt>, [<Xn|SP>, #pimm]`
 *
 *          Opcode: 00_111_00_1_00_... (base 0x39000000)
 *
 * @param buf The code buffer.
 * @param is64 True to store 64 bits (`Xt`), false to store 32 bits (`Wt`).
 * @param src The source GPR.
 * @param base The base address register.
 * @param offset The byte offset, a multiple of the access size.
 */
INFIX_INTERNAL void emit_arm64_strb_imm(code_buffer * buf, arm64_gpr src, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    if (offset >= 0 && offset <= 0xFFF) {
        uint32_t instr = (0b00U << 30) | A64_OP_LOAD_STORE_IMM_UNSIGNED;  // STRB opcode
        instr |= ((uint32_t)offset & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(src & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        // Fallback
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_strb_imm(buf, src, X16_REG, 0);
    }
}
/**
 * @internal
 * @brief Emits a `STRH` (Store Register Halfword) instruction.
 * @details Stores the low 16 bits of a register
 *          Assembly: `STRH <Wt>, [<Xn|SP>, #imm]`
 *
 *          Opcode: 01_111_00_1_00_... (base 0x79000000)
 *
 */
INFIX_INTERNAL void emit_arm64_strh_imm(code_buffer * buf, arm64_gpr src, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    if (offset >= 0 && offset % 2 == 0 && (offset / 2) <= 0xFFF) {
        uint32_t instr = (0b01U << 30) | A64_OP_LOAD_STORE_IMM_UNSIGNED;  // STRH opcode
        instr |= ((uint32_t)(offset / 2) & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(src & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        // Fallback
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_strh_imm(buf, src, X16_REG, 0);
    }
}
/**
 * @internal
 * @brief Emits an `STP` (Store Pair) instruction with pre-indexing.
 * @details Assembly: `STP <Xt1>, <Xt2>, [Xn|SP, #imm]!`
 *          This instruction stores two registers and updates the base register.
 *
 *          Opcode (64-bit): 1010100110...
 *
 * @param offset A signed, scaled immediate offset.
 */
INFIX_INTERNAL void emit_arm64_stp_pre_index(
    code_buffer * buf, bool is64, arm64_gpr src1, arm64_gpr src2, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    int scale = is64 ? 8 : 4;
    if (offset % scale != 0 || (offset / scale) < -64 || (offset / scale) > 63) {
        buf->error = true;
        return;
    }
    // Instruction format: opc:101001:L=0:imm7:Rt2:Rn:Rt
    // For STP: opc=?, L=0
    uint32_t instr =
        (is64 ? A64_SF_64BIT : A64_SF_32BIT) | A64_OPC_STP | A64_OP_LOAD_STORE_PAIR_BASE | A64_ADDR_PRE_INDEX;
    instr |= ((uint32_t)(offset / scale) & 0x7F) << 15;
    instr |= (uint32_t)(src2 & 0x1F) << 10;
    instr |= (uint32_t)(base & 0x1F) << 5;
    instr |= (uint32_t)(src1 & 0x1F);
    emit_int32(buf, instr);
}
/*
 * Implementation for emit_arm64_ldp_post_index (Load Pair).
 * Encodes `LDP <Xt1>, <Xt2>, [Xn|SP], #imm`.
 * Opcode (64-bit): 1010100011...
 */
INFIX_INTERNAL void emit_arm64_ldp_post_index(
    code_buffer * buf, bool is64, arm64_gpr dest1, arm64_gpr dest2, arm64_gpr base, int32_t offset) {
    uint32_t instr = 0xA8C00000;  // Base for LDP post-indexed
    if (is64)
        instr |= (1u << 31);
    int scale = is64 ? 8 : 4;
    assert(offset % scale == 0 && (offset / scale) >= -64 && (offset / scale) <= 63);
    instr |= ((uint32_t)(offset / scale) & 0x7F) << 15;
    instr |= (uint32_t)(dest2 & 0x1F) << 10;
    instr |= (uint32_t)(base & 0x1F) << 5;
    instr |= (uint32_t)(dest1 & 0x1F);
    emit_int32(buf, instr);
}
// Memory <-> VPR (SIMD/FP) Emitters
/*
 * Implementation for emit_arm64_ldr_vpr.
 * Encodes `LDR <St|Dt>, [<Xn|SP>, #imm]`.
 * Opcode (64-bit, D reg): 11_111_10_1_01_... (base 0xBD400000)
 * Opcode (32-bit, S reg): 10_111_10_1_01_... (base 0x7D400000)
 */
INFIX_INTERNAL void emit_arm64_ldr_vpr(code_buffer * buf, bool is64, arm64_vpr dest, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    const int scale = is64 ? 8 : 4;
    if (offset >= 0 && offset % scale == 0 && (offset / scale) <= 0xFFF) {
        uint32_t instr = 0x3d400000;
        uint32_t size_bits = is64 ? 0b11 : 0b10;
        instr |= (size_bits << 30);
        instr |= ((uint32_t)(offset / scale) & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(dest & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        // Fallback
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_ldr_vpr(buf, is64, dest, X16_REG, 0);
    }
}
/*
 * Implementation for emit_arm64_str_vpr.
 * Encodes `STR <St|Dt>, [<Xn|SP>, #imm]`.
 * Opcode (64-bit, D reg): 11_111_10_1_00_... (base 0xBD000000)
 * Opcode (32-bit, S reg): 10_111_10_1_00_... (base 0x7D000000)
 */
INFIX_INTERNAL void emit_arm64_str_vpr(code_buffer * buf, bool is64, arm64_vpr src, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    const int scale = is64 ? 8 : 4;
    if (offset >= 0 && offset % scale == 0 && (offset / scale) <= 0xFFF) {
        uint32_t instr = 0x3d000000;
        uint32_t size_bits = is64 ? 0b11 : 0b10;
        instr |= (size_bits << 30);
        instr |= ((uint32_t)(offset / scale) & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(src & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        // Fallback
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_str_vpr(buf, is64, src, X16_REG, 0);
    }
}
/*
 * Implementation for emit_arm64_ldr_q_imm.
 * Encodes `LDR <Qt>, [Xn, #imm]` for a 128-bit load into a full V-register.
 * Opcode: 00_111_10_1_01... (base 0x3DC00000)
 */
INFIX_INTERNAL void emit_arm64_ldr_q_imm(code_buffer * buf, arm64_vpr dest, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    // Validate immediate offset for 128-bit (16-byte) access
    if (offset >= 0 && offset % 16 == 0 && (offset / 16) <= 0xFFF) {
        uint32_t instr = 0x3DC00000;
        instr |= ((uint32_t)(offset / 16) & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(dest & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        // Fallback: Calculate address into X16 and load with 0 offset
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_ldr_q_imm(buf, dest, X16_REG, 0);
    }
}
/*
 * Implementation for emit_arm64_str_q_imm.
 * Encodes `STR <Qt>, [Xn, #imm]` for a 128-bit store from a full V-register.
 * Opcode: 00_111_10_1_00... (base 0x3D800000)
 */
INFIX_INTERNAL void emit_arm64_str_q_imm(code_buffer * buf, arm64_vpr src, arm64_gpr base, int32_t offset) {
    if (buf->error)
        return;
    // Validate immediate offset for 128-bit (16-byte) access
    if (offset >= 0 && offset % 16 == 0 && (offset / 16) <= 0xFFF) {
        uint32_t instr = 0x3D800000;
        instr |= ((uint32_t)(offset / 16) & 0xFFF) << 10;
        instr |= (uint32_t)(base & 0x1F) << 5;
        instr |= (uint32_t)(src & 0x1F);
        emit_int32(buf, instr);
    }
    else {
        // Fallback: Calculate address into X16 and store with 0 offset
        if (offset >= 0)
            emit_arm64_add_imm(buf, true, false, X16_REG, base, (uint32_t)offset);
        else
            emit_arm64_sub_imm(buf, true, false, X16_REG, base, (uint32_t)(-offset));
        emit_arm64_str_q_imm(buf, src, X16_REG, 0);
    }
}
// Arithmetic Emitters
/*
 * @internal
 * Generic helper for emitting ARM64 `ADD` or `SUB` with an immediate.
 * It handles large immediates by falling back to a multi-instruction sequence that
 * uses a scratch register (X15), since single instructions have a limited immediate range.
 */
INFIX_INTERNAL void emit_arm64_arith_imm(
    code_buffer * buf, bool is_sub, bool is64, bool set_flags, arm64_gpr dest, arm64_gpr base, uint32_t imm) {
    uint32_t instr = is_sub ? 0x51000000 : 0x11000000;
    if (is64)
        instr |= (1u << 31);
    if (set_flags)
        instr |= (1u << 29);
    if (imm <= 0xFFF)  // Check for un-shifted 12-bit immediate.
        instr |= (imm & 0xFFF) << 10;
    else if ((imm & 0xFFF) == 0 && (imm >> 12) <= 0xFFF && (imm >> 12) > 0) {  // Check for shifted 12-bit immediate.
        instr |= (1u << 22);                                                   // 'sh' bit selects LSL #12 shift.
        instr |= ((imm >> 12) & 0xFFF) << 10;
    }
    else {
        // Immediate is too large. Load it into a scratch register (X15) and do a register-based operation.
        arm64_gpr scratch_reg = X15_REG;
        emit_arm64_load_u64_immediate(buf, scratch_reg, imm);
        uint32_t reg_instr = is_sub ? 0x4B000000 : 0x0B000000;
        if (is64)
            reg_instr |= (1u << 31);
        if (set_flags)
            reg_instr |= (1u << 29);
        reg_instr |= (uint32_t)(scratch_reg & 0x1F) << 16;
        reg_instr |= (uint32_t)(base & 0x1F) << 5;
        reg_instr |= (uint32_t)(dest & 0x1F);
        emit_int32(buf, reg_instr);
        return;
    }
    instr |= (uint32_t)(base & 0x1F) << 5;
    instr |= (uint32_t)(dest & 0x1F);
    emit_int32(buf, instr);
}
/*
 * Implementation for emit_arm64_add_imm.
 * Opcode (64-bit): 10_0_10001_... (0x91...)
 * Opcode (32-bit): 00_0_10001_... (0x11...)
 */
INFIX_INTERNAL void emit_arm64_add_imm(
    code_buffer * buf, bool is64, bool set_flags, arm64_gpr dest, arm64_gpr base, uint32_t imm) {
    emit_arm64_arith_imm(buf, false, is64, set_flags, dest, base, imm);
}
/*
 * Implementation for emit_arm64_sub_imm.
 * Opcode (64-bit): 11_0_10001_... (0xD1...)
 * Opcode (32-bit): 01_0_10001_... (0x51...)
 */
INFIX_INTERNAL void emit_arm64_sub_imm(
    code_buffer * buf, bool is64, bool set_flags, arm64_gpr dest, arm64_gpr base, uint32_t imm) {
    emit_arm64_arith_imm(buf, true, is64, set_flags, dest, base, imm);
}
// Control Flow Emitters
/*
 * Implementation for emit_arm64_blr_reg (Branch with Link to Register).
 * Opcode: 1101011000111111000000... (0xD63F0000)
 */
INFIX_INTERNAL void emit_arm64_blr_reg(code_buffer * buf, arm64_gpr reg) {
    uint32_t instr = 0xD63F0000;
    instr |= (uint32_t)(reg & 0x1F) << 5;
    emit_int32(buf, instr);
}
/*
 * Implementation for emit_arm64_ret.
 * Opcode: 1101011001011111000000... (0xD65F0000)
 * Defaults to `RET X30` if X30_LR_REG is passed.
 */
INFIX_INTERNAL void emit_arm64_ret(code_buffer * buf, arm64_gpr reg) {
    uint32_t instr = 0xD65F0000;
    instr |= (uint32_t)(reg & 0x1F) << 5;
    emit_int32(buf, instr);
}
/**
 * @internal
 * @brief Emits a `CBNZ` (Compare and Branch on Non-Zero) instruction.
 * @details Assembly: `CBNZ <Xt>, #imm`.
 *
 *          Opcode (64-bit): 10110101... (0xB5...)
 *
 * @param offset A signed byte offset from the current instruction, which must be a multiple of 4.
 */
INFIX_INTERNAL void emit_arm64_cbnz(code_buffer * buf, bool is64, arm64_gpr reg, int32_t offset) {
    if (buf->error)
        return;
    // Offset is encoded as a 19-bit immediate, scaled by 4 bytes.
    // 262144 is the max alloc size
    if (offset % 4 != 0 || (offset / 4) < -262144 || (offset / 4) > 262143) {
        buf->error = true;
        return;
    }
    uint32_t instr = (is64 ? A64_SF_64BIT : A64_SF_32BIT) | A64_OP_COMPARE_BRANCH_IMM | A64_OPC_CBNZ;
    instr |= ((uint32_t)(offset / 4) & 0x7FFFF) << 5;
    instr |= (uint32_t)(reg & 0x1F);
    emit_int32(buf, instr);
}
/**
 * @internal
 * @brief Emits a `BRK` (Breakpoint) instruction.
 * @details Assembly: `BRK #imm`. This causes a software breakpoint exception,
 *          useful for safely crashing on fatal errors (like a null function call).
 *
 * Opcode: 11010100001... (0xD42...)
 */
INFIX_INTERNAL void emit_arm64_brk(code_buffer * buf, uint16_t imm) {
    if (buf->error)
        return;
    uint32_t instr = A64_OP_SYSTEM | A64_OP_BRK;
    instr |= (uint32_t)(imm & 0xFFFF) << 5;
    emit_int32(buf, instr);
}
/**
 * @internal
 * @brief Emits a `BR` (Branch to Register) instruction.
 * @details This instruction performs an indirect, unconditional branch to the
 *          address contained in the specified register. It is functionally similar to
 *          `JMP` on x86.
 *
 * Assembly: `BR <Xn>`. An unconditional indirect jump.
 *
 * Opcode: 1101011000011111000000... (0xD61F0000)
 */
INFIX_INTERNAL void emit_arm64_b_reg(code_buffer * buf, arm64_gpr reg) {
    if (buf->error)
        return;
    uint32_t instr = A64_OP_BRANCH_REG | A64_OPC_BR;
    instr |= (uint32_t)(reg & 0x1F) << 5;
    emit_int32(buf, instr);
}
/**
 * @internal
 * @brief Emits `SVC #imm` (Supervisor Call) instruction.
 * @details Opcode: 11010100_00_imm16_0001
 */
INFIX_INTERNAL void emit_arm64_svc_imm(code_buffer * buf, uint16_t imm) {
    if (buf->error)
        return;
    uint32_t instr = A64_OP_SYSTEM | A64_OP_SVC;
    instr |= (uint32_t)(imm & 0xFFFF) << 5;
    emit_int32(buf, instr);
}
