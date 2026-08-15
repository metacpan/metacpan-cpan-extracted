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
 * @file abi_x64_emitters.c
 * @brief Implements internal helper functions for emitting x86-64 machine code.
 * @ingroup internal_abi_x64
 *
 * @internal
 * This file provides the concrete implementations for the low-level x86-64
 * instruction emitters. These functions are the fundamental building blocks
 * used by both the Windows x64 and System V ABI implementations.
 *
 * By centralizing these functions, we encapsulate the complex details of x86-64
 * instruction encoding (opcodes, ModR/M bytes, REX prefixes). For a definitive
 * reference, see the Intel 64 and IA-32 Architectures Software Developer's Manuals.
 * @endinternal
 */
#include "arch/x64/abi_x64_emitters.h"
#include "common/utility.h"
#include <assert.h>
#include <string.h>
// Helper defines for REX prefix bits, making the code more readable.
#define REX_W (1 << 3)  // 64-bit operand size
#define REX_R (1 << 2)  // Extends ModR/M 'reg' field
#define REX_X (1 << 1)  // Extends SIB 'index' field
#define REX_B (1 << 0)  // Extends ModR/M 'r/m' or SIB 'base' field
// Instruction Encoding Helpers
/*
 * @internal
 * @brief Emits an x86-64 REX prefix byte.
 * @details The REX prefix is a single byte (0x40-0x4F) used in 64-bit mode to:
 * - Set operand size to 64 bits (W bit).
 * - Extend the register fields to access R8-R15 (R, X, B bits).
 */
INFIX_INTERNAL void emit_rex_prefix(code_buffer * buf, bool w, bool r, bool x, bool b) {
    uint8_t rex_byte = 0x40;
    if (w)
        rex_byte |= REX_W;
    if (r)
        rex_byte |= REX_R;
    if (x)
        rex_byte |= REX_X;
    if (b)
        rex_byte |= REX_B;
    emit_byte(buf, rex_byte);
}
/*
 * @internal
 * @brief Emits an x86-64 ModR/M byte.
 * @details The ModR/M byte is a crucial part of many instructions, specifying the addressing mode.
 * It encodes register operands and memory operands.
 */
INFIX_INTERNAL void emit_modrm(code_buffer * buf, uint8_t mod, uint8_t reg_opcode, uint8_t rm) {
    uint8_t modrm_byte = (mod << 6) | (reg_opcode << 3) | rm;
    emit_byte(buf, modrm_byte);
}
// GPR <-> Immediate Value Emitters
/**
 * @internal
 * @brief Emits `mov r64, imm64` to load a 64-bit immediate value into a register.
 * @details Instruction Breakdown: MOV r64, imm64
 * Opcode format: REX.W + B8+rd imm64
 */
INFIX_INTERNAL void emit_mov_reg_imm64(code_buffer * buf, x64_gpr reg, uint64_t imm) {
    emit_rex_prefix(buf, 1, 0, 0, reg >= R8_REG);
    emit_byte(buf, 0xB8 + (reg % 8));
    emit_int64(buf, imm);
}
/**
 * @internal
 * @brief Emits `mov r/m64, imm32` (sign-extended) to load a 32-bit immediate into a register.
 * @details Instruction Breakdown: MOV r/m64, imm32 (sign-extended)
 * Opcode format: REX.W + C7 /0 id
 */
INFIX_INTERNAL void emit_mov_reg_imm32(code_buffer * buf, x64_gpr reg, int32_t imm) {
    emit_rex_prefix(buf, 1, 0, 0, reg >= R8_REG);
    emit_byte(buf, 0xC7);
    emit_modrm(buf, 3, 0, reg % 8);  // mod=11 (register), reg=/0
    emit_int32(buf, imm);
}
// GPR <-> GPR Move Emitters
/**
 * @internal
 * @brief Emits `mov r/m64, r64` for a register-to-register move.
 * @details Instruction Breakdown: MOV r/m64, r64
 * Opcode format: REX.W + 89 /r
 */
INFIX_INTERNAL void emit_mov_reg_reg(code_buffer * buf, x64_gpr dest, x64_gpr src) {
    uint8_t rex = REX_W;
    if (dest >= R8_REG)
        rex |= REX_B;
    if (src >= R8_REG)
        rex |= REX_R;
    emit_byte(buf, 0x40 | rex);
    emit_byte(buf, 0x89);
    emit_modrm(buf, 3, src % 8, dest % 8);
}
// Memory -> GPR Load Emitters
/**
 * @internal
 * @brief Emits `mov r64, r/m64` to load a 64-bit value from memory.
 * @details Instruction Breakdown: MOV r64, r/m64
 * Opcode format: REX.W + 8B /r
 */
INFIX_INTERNAL void emit_mov_reg_mem(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset) {
    emit_rex_prefix(buf, 1, dest >= R8_REG, 0, src_base >= R8_REG);
    emit_byte(buf, 0x8B);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `mov r32, r/m32` to load a 32-bit value (zero-extended to 64).
 * @details Opcode format: 8B /r (without REX.W)
 */
INFIX_INTERNAL void emit_mov_reg32_mem(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset) {
    uint8_t rex = 0;
    if (dest >= R8_REG)
        rex |= REX_R;
    if (src_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    emit_byte(buf, 0x8B);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `movsxd r64, r/m32` to load a 32-bit value and sign-extend to 64.
 * @details Opcode format: REX.W + 63 /r
 */
INFIX_INTERNAL void emit_movsxd_reg_mem(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset) {
    emit_rex_prefix(buf, 1, dest >= R8_REG, 0, src_base >= R8_REG);
    emit_byte(buf, 0x63);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `movsx r64, r/m8` to load a signed 8-bit value and sign-extend to 64.
 * @details Opcode format: REX.W + 0F BE /r
 */
INFIX_INTERNAL void emit_movsx_reg64_mem8(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset) {
    emit_rex_prefix(buf, 1, dest >= R8_REG, 0, src_base >= R8_REG);
    EMIT_BYTES(buf, 0x0F, 0xBE);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `movsx r64, r/m16` to load a signed 16-bit value and sign-extend to 64.
 * @details Opcode format: REX.W + 0F BF /r
 */
INFIX_INTERNAL void emit_movsx_reg64_mem16(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset) {
    emit_rex_prefix(buf, 1, dest >= R8_REG, 0, src_base >= R8_REG);
    EMIT_BYTES(buf, 0x0F, 0xBF);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `movzx r64, r/m8` to load an unsigned 8-bit value and zero-extend to 64.
 * @details Opcode format: REX.W + 0F B6 /r
 */
INFIX_INTERNAL void emit_movzx_reg64_mem8(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset) {
    emit_rex_prefix(buf, 1, dest >= R8_REG, 0, src_base >= R8_REG);
    EMIT_BYTES(buf, 0x0F, 0xB6);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `movzx r64, r/m16` to load an unsigned 16-bit value and zero-extend to 64.
 * @details Opcode format: REX.W + 0F B7 /r
 */
INFIX_INTERNAL void emit_movzx_reg64_mem16(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset) {
    emit_rex_prefix(buf, 1, dest >= R8_REG, 0, src_base >= R8_REG);
    EMIT_BYTES(buf, 0x0F, 0xB7);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
// GPR -> Memory Store Emitters
/**
 * @internal
 * @brief Emits `mov [base + offset], r64` to store a 64-bit GPR to memory.
 * @details Opcode format: REX.W + 89 /r
 */
INFIX_INTERNAL void emit_mov_mem_reg(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_gpr src) {
    emit_rex_prefix(buf, 1, src >= R8_REG, 0, dest_base >= R8_REG);
    emit_byte(buf, 0x89);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (dest_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, src % 8, dest_base % 8);
    if (dest_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `mov [base + offset], r32` to store a 32-bit GPR to memory.
 * @details Opcode format: 89 /r (without REX.W)
 */
INFIX_INTERNAL void emit_mov_mem_reg32(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_gpr src) {
    uint8_t rex = 0;
    if (src >= R8_REG)
        rex |= REX_R;
    if (dest_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    emit_byte(buf, 0x89);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (dest_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, src % 8, dest_base % 8);
    if (dest_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `mov [base + offset], r16` to store a 16-bit GPR to memory.
 * @details Opcode format: 66 + 89 /r (66 is the operand-size override prefix).
 */
INFIX_INTERNAL void emit_mov_mem_reg16(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_gpr src) {
    emit_byte(buf, 0x66);
    uint8_t rex = 0;
    if (src >= R8_REG)
        rex |= REX_R;
    if (dest_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    emit_byte(buf, 0x89);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (dest_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, src % 8, dest_base % 8);
    if (dest_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `mov [base + offset], r8` to store an 8-bit GPR to memory.
 * @details Opcode format: 88 /r
 */
INFIX_INTERNAL void emit_mov_mem_reg8(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_gpr src) {
    uint8_t rex = 0;
    if (src >= R8_REG || dest_base >= R8_REG || src >= RSP_REG)
        rex = 0x40;
    if (src >= R8_REG)
        rex |= REX_R;
    if (dest_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, rex);
    emit_byte(buf, 0x88);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (dest_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, src % 8, dest_base % 8);
    if (dest_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
// Memory <-> XMM/YMM (SSE/AVX) Emitters
/**
 * @internal
 * @brief Emits `movss xmm, [base + offset]` to load a 32-bit float from memory.
 * @details Opcode format: F3 0F 10 /r
 */
INFIX_INTERNAL void emit_movss_xmm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset) {
    emit_byte(buf, 0xF3);
    uint8_t rex = 0;
    if (dest >= XMM8_REG)
        rex |= REX_R;
    if (src_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    EMIT_BYTES(buf, 0x0F, 0x10);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `movss [base + offset], xmm` to store a 32-bit float to memory.
 * @details Opcode format: F3 0F 11 /r
 */
INFIX_INTERNAL void emit_movss_mem_xmm(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_xmm src) {
    emit_byte(buf, 0xF3);
    uint8_t rex = 0;
    if (src >= XMM8_REG)
        rex |= REX_R;
    if (dest_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    EMIT_BYTES(buf, 0x0F, 0x11);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (dest_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, src % 8, dest_base % 8);
    if (dest_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `movsd xmm, [base + offset]` to load a 64-bit double from memory.
 * @details Opcode format: F2 0F 10 /r
 */
INFIX_INTERNAL void emit_movsd_xmm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset) {
    emit_byte(buf, 0xF2);
    uint8_t rex = 0;
    if (dest >= XMM8_REG)
        rex |= REX_R;
    if (src_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    EMIT_BYTES(buf, 0x0F, 0x10);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `movsd [base + offset], xmm` to store a 64-bit double to memory.
 * @details Opcode format: F2 0F 11 /r
 */
INFIX_INTERNAL void emit_movsd_mem_xmm(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_xmm src) {
    emit_byte(buf, 0xF2);
    uint8_t rex = 0;
    if (src >= XMM8_REG)
        rex |= REX_R;
    if (dest_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    EMIT_BYTES(buf, 0x0F, 0x11);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (dest_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, src % 8, dest_base % 8);
    if (dest_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `movups xmm, [base + offset]` to load a 128-bit unaligned value from memory.
 * @details Opcode format: 0F 10 /r
 */
INFIX_INTERNAL void emit_movups_xmm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset) {
    uint8_t rex = 0;
    if (dest >= XMM8_REG)
        rex |= REX_R;
    if (src_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    EMIT_BYTES(buf, 0x0F, 0x10);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `movups [base + offset], xmm` to store a 128-bit unaligned value to memory.
 * @details Opcode format: 0F 11 /r
 */
INFIX_INTERNAL void emit_movups_mem_xmm(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_xmm src) {
    uint8_t rex = 0;
    if (src >= XMM8_REG)
        rex |= REX_R;
    if (dest_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    EMIT_BYTES(buf, 0x0F, 0x11);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (dest_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, src % 8, dest_base % 8);
    if (dest_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits a VEX prefix for an AVX instruction.
 * @details This helper centralizes the logic of choosing between 2-byte (C5) and 3-byte (C4) VEX encodings.
 */
INFIX_INTERNAL void emit_vex_prefix(
    code_buffer * buf, bool r, bool x, bool b, uint8_t m, bool w, uint8_t v, bool l, uint8_t p) {
    // VEX encoding inverts R, X, B bits.
    // The 2-byte VEX prefix cannot encode the L bit for 256-bit operations.
    // The condition must ensure we only use it for 128-bit operations (l=0).
    if (!b && !x && m == 1 && w == 0 && !l) {
        // Use 2-byte VEX prefix (C5) when possible.
        emit_byte(buf, 0xC5);
        uint8_t byte2 = ((!r) << 7) | ((~v & 0xF) << 3) | ((l & 1) << 2) | (p & 3);
        emit_byte(buf, byte2);
    }
    else {
        // Fall back to 3-byte VEX prefix (C4).
        emit_byte(buf, 0xC4);
        uint8_t byte2 = ((!r) << 7) | ((!x) << 6) | ((!b) << 5) | (m & 0x1F);
        emit_byte(buf, byte2);
        uint8_t byte3 = ((w & 1) << 7) | ((~v & 0xF) << 3) | ((l & 1) << 2) | (p & 3);
        emit_byte(buf, byte3);
    }
}
/**
 * @internal
 * @brief Emits a 4-byte EVEX prefix for an AVX-512 instruction, following the Intel SDM.
 */
INFIX_INTERNAL void emit_evex_prefix(code_buffer * buf,
                                     uint8_t map,  // 1 for 0F, 2 for 0F38, 3 for 0F3A
                                     uint8_t pp,   // 00=none, 01=66, 10=F3, 11=F2
                                     bool W,
                                     bool R,
                                     bool X,
                                     bool B,
                                     bool R_prime,  // Register bits
                                     uint8_t vvvv,  // Source register (inverted)
                                     bool L,
                                     bool L_prime,
                                     bool z,
                                     bool b,
                                     uint8_t aaa)  // Masking/control bits
{
    emit_byte(buf, 0x62);
    // Byte 2: P0 - R, X, B, R' bits are inverted. 0 means 1, 1 means 0.
    uint8_t p0 = 0;
    p0 |= (R ? 0 : 1) << 7;        // Inverted R bit
    p0 |= (X ? 0 : 1) << 6;        // Inverted X bit
    p0 |= (B ? 0 : 1) << 5;        // Inverted B bit
    p0 |= (R_prime ? 0 : 1) << 4;  // Inverted R' bit
    p0 |= (map & 0x0F);            // Low 4 bits select the opcode map (0F, 0F38, 0F3A)
    emit_byte(buf, p0);
    // Byte 3: P1
    uint8_t p1 = 0;
    p1 |= (pp & 0b11);
    p1 |= (1 << 2);              // ' (marks EVEX), must be 1
    p1 |= ((~vvvv & 0xF) << 3);  // vvvv field is inverted
    p1 |= W ? (1 << 7) : 0;
    emit_byte(buf, p1);
    // Byte 4: P2
    uint8_t p2 = 0;
    p2 |= (aaa & 0b111);
    p2 |= b ? (1 << 4) : 0;
    p2 |= L_prime ? (1 << 6) : 0;
    p2 |= L ? (1 << 5) : 0;
    p2 |= z ? (1 << 7) : 0;
    // V' bit is the high bit of the 5-bit vvvv register specifier and is NOT inverted.
    p2 |= (((vvvv >> 4) & 1) << 3);
    emit_byte(buf, p2);
}
/**
 * @internal
 * @brief Emits `vmovupd ymm, [base + offset]` to load a 256-bit unaligned value (AVX).
 * @details Instruction format: VEX.256.66.0F.WIG 10 /r
 */
INFIX_INTERNAL void emit_vmovupd_ymm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset) {
    // VEX prefix fields for vmovupd ymm, m256:
    // L=1 (256-bit), p=1 (from 66 prefix), m-mmmm=01 (from 0F map).
    // The vvvv field is not used for a memory source and should be 0.
    emit_vex_prefix(buf, dest >= XMM8_REG, 0, src_base >= R8_REG, 1, false, 0, true, 1);
    emit_byte(buf, 0x10);  // Opcode for MOVUPD
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `vmovupd [base + offset], ymm` to store a 256-bit unaligned value (AVX).
 * @details Instruction format: VEX.256.66.0F.WIG 11 /r
 */
INFIX_INTERNAL void emit_vmovupd_mem_ymm(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_xmm src) {
    // For a store, the VEX.vvvv field is not used and should be 0.
    emit_vex_prefix(buf, src >= XMM8_REG, 0, dest_base >= R8_REG, 1, false, 0, true, 1);
    emit_byte(buf, 0x11);  // Opcode for MOVUPD (store)
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (dest_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, src % 8, dest_base % 8);
    if (dest_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `vmovupd zmm, [base + offset]` to load a 512-bit unaligned value (AVX-512).
 * @details Instruction format: EVEX.512.66.0F.W0 10 /r
 */
INFIX_INTERNAL void emit_vmovupd_zmm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset) {
    // For vmovupd zmm, m512:
    // vvvv field is unused and must be 0.
    emit_evex_prefix(buf,
                     1,
                     1,
                     true,  // W=1 for double-precision
                     dest >= XMM8_REG,
                     false,
                     src_base >= R8_REG,
                     dest >= XMM16_REG,
                     // Per Intel SDM: For mem source, EVEX.vvvv must be 1111b (inverted from 0)
                     // and EVEX.V' must be 1. The value 16 (0b10000) encodes this.
                     16,
                     false,  // L=0 for 512-bit
                     true,   // L'=1 for 512-bit
                     false,
                     false,
                     0);
    emit_byte(buf, 0x10);  // Opcode for MOVUPD
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `vmovupd [base + offset], zmm` to store a 512-bit unaligned value (AVX-512).
 * @details Instruction format: EVEX.512.66.0F.W0 11 /r
 */
INFIX_INTERNAL void emit_vmovupd_mem_zmm(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_xmm src) {
    // For a store, the source register is encoded in EVEX.reg_field (via ModRM)
    // and the vvvv field is repurposed. Per Intel SDM, for a memory destination,
    // V' must be 1. We encode this by passing a value with the 5th bit set (16)
    // to the vvvv parameter of the prefix emitter.
    emit_evex_prefix(buf,
                     1,     // map: 0F
                     1,     // pp: 66
                     true,  // W: 1 (double-precision)
                     src >= XMM8_REG,
                     false,
                     dest_base >= R8_REG,
                     src >= XMM16_REG,
                     16,     // vvvv field + V' bit encoding for memory destination
                     false,  // L=0 for 512-bit
                     true,   // L'=1 for 512-bit
                     false,  // z=0
                     false,  // b=0
                     0);     // aaa=0
    emit_byte(buf, 0x11);    // Opcode for MOVUPD (store)
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (dest_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, src % 8, dest_base % 8);
    if (dest_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `vzeroupper` to clear the upper bits of all YMM/ZMM registers.
 * @details Opcode format: VEX.128.0F.77
 */
INFIX_INTERNAL void emit_vzeroupper(code_buffer * buf) {
    // VEX.128.0F.77 (C5 F8 77)
    // L=0 (128-bit), p=0 (no prefix), m-mmmm=1 (0F map), vvvv=1111 (none)
    emit_vex_prefix(buf, 0, 0, 0, 1, 0, 0, 0, 0);
    emit_byte(buf, 0x77);
}
/**
 * @internal
 * @brief Emits `cvtsd2ss xmm1, xmm2/m64` to convert a double to a float.
 * @details Opcode format: F2 0F 5A /r
 */
INFIX_INTERNAL void emit_cvtsd2ss_xmm_xmm(code_buffer * buf, x64_xmm dest, x64_xmm src) {
    emit_byte(buf, 0xF2);
    uint8_t rex = 0;
    if (dest >= XMM8_REG)
        rex |= REX_R;
    if (src >= XMM8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    EMIT_BYTES(buf, 0x0F, 0x5A);
    emit_modrm(buf, 3, dest % 8, src % 8);
}

/**
 * @internal
 * @brief Emits `cvtsd2ss xmm, [base + offset]` to load a double, convert to float, and store in xmm.
 * @details Opcode format: F2 0F 5A /r
 */
INFIX_INTERNAL void emit_cvtsd2ss_xmm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset) {
    emit_byte(buf, 0xF2);  // F2 prefix for SD (scalar double)
    uint8_t rex = 0;
    if (dest >= XMM8_REG)
        rex |= REX_R;
    if (src_base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);

    EMIT_BYTES(buf, 0x0F, 0x5A);  // Opcode for CVTSD2SS

    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;

    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);

    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);  // SIB byte for RSP base

    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}

/**
 * @internal
 * @brief Emits `movaps xmm1, xmm2/m128` to move 128 bits between XMM registers.
 * @details Opcode format: 0F 28 /r
 */
INFIX_INTERNAL void emit_movaps_xmm_xmm(code_buffer * buf, x64_xmm dest, x64_xmm src) {
    uint8_t rex = 0;
    if (dest >= XMM8_REG)
        rex |= REX_R;
    if (src >= XMM8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    EMIT_BYTES(buf, 0x0F, 0x28);
    emit_modrm(buf, 3, dest % 8, src % 8);
}

// GPR <-> XMM Move Emitters
/**
 * @internal
 * @brief Emits `movq xmm, r64` to move 64 bits from a GPR to an XMM register.
 * @details Opcode format: 66 + REX.W + 0F 6E /r
 */
INFIX_INTERNAL void emit_movq_xmm_gpr(code_buffer * buf, x64_xmm dest, x64_gpr src) {
    emit_byte(buf, 0x66);
    emit_rex_prefix(buf, 1, dest >= XMM8_REG, 0, src >= R8_REG);
    EMIT_BYTES(buf, 0x0F, 0x6E);
    emit_modrm(buf, 3, dest % 8, src % 8);
}
/**
 * @internal
 * @brief Emits `movq r64, xmm` to move 64 bits from an XMM to a GPR.
 * @details Opcode format: 66 + REX.W + 0F 7E /r
 */
INFIX_INTERNAL void emit_movq_gpr_xmm(code_buffer * buf, x64_gpr dest, x64_xmm src) {
    emit_byte(buf, 0x66);
    emit_rex_prefix(buf, 1, src >= XMM8_REG, 0, dest >= R8_REG);
    EMIT_BYTES(buf, 0x0F, 0x7E);
    emit_modrm(buf, 3, src % 8, dest % 8);
}
// Memory <-> x87 FPU Emitters
/**
 * @internal
 * @brief Emits `fldt [base + offset]` to load an 80-bit `long double` onto the FPU stack.
 * @details Opcode format: DB /5
 */
INFIX_INTERNAL void emit_fldt_mem(code_buffer * buf, x64_gpr base, int32_t offset) {
    uint8_t rex = 0;
    if (base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    emit_byte(buf, 0xDB);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, 5, base % 8);  // reg field is 5 for this instruction
    if (base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `fstpt [base + offset]` to store and pop an 80-bit `long double`.
 * @details Opcode format: DB /7
 */
INFIX_INTERNAL void emit_fstpt_mem(code_buffer * buf, x64_gpr base, int32_t offset) {
    uint8_t rex = 0;
    if (base >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    emit_byte(buf, 0xDB);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, 7, base % 8);  // reg field is 7 for this instruction
    if (base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
// Arithmetic & Logic Emitters
/**
 * @internal
 * @brief Emits `lea r64, [base + offset]` to load an effective address.
 * @details Opcode format: REX.W + 8D /r
 */
INFIX_INTERNAL void emit_lea_reg_mem(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset) {
    emit_rex_prefix(buf, 1, dest >= R8_REG, 0, src_base >= R8_REG);
    emit_byte(buf, 0x8D);
    uint8_t mod = (offset >= -128 && offset <= 127) ? 0x40 : 0x80;
    if (offset == 0 && (src_base % 8) != RBP_REG)
        mod = 0x00;
    emit_modrm(buf, mod >> 6, dest % 8, src_base % 8);
    if (src_base % 8 == RSP_REG)
        emit_byte(buf, 0x24);
    if (mod == 0x40)
        emit_byte(buf, (uint8_t)offset);
    else if (mod == 0x80)
        emit_int32(buf, offset);
}
/**
 * @internal
 * @brief Emits `add r64, imm32` to add a 32-bit immediate to a GPR.
 * @details Opcode format: REX.W + 81 /0 id
 */
INFIX_INTERNAL void emit_add_reg_imm32(code_buffer * buf, x64_gpr reg, int32_t imm) {
    emit_rex_prefix(buf, 1, 0, 0, reg >= R8_REG);
    emit_byte(buf, 0x81);
    emit_modrm(buf, 3, 0, reg % 8);  // mod=11, reg=/0 for ADD
    emit_int32(buf, imm);
}
/**
 * @internal
 * @brief Emits `sub r64, imm32` to subtract a 32-bit immediate from a GPR.
 * @details Opcode format: REX.W + 81 /5 id
 */
INFIX_INTERNAL void emit_sub_reg_imm32(code_buffer * buf, x64_gpr reg, int32_t imm) {
    emit_rex_prefix(buf, 1, 0, 0, reg >= R8_REG);
    emit_byte(buf, 0x81);
    emit_modrm(buf, 3, 5, reg % 8);  // mod=11, reg=/5 for SUB
    emit_int32(buf, imm);
}
/**
 * @internal
 * @brief Emits `and r64, imm8` to perform a bitwise AND with a sign-extended 8-bit immediate.
 * @details Opcode format: REX.W 83 /4 ib
 */
INFIX_INTERNAL void emit_and_reg_imm8(code_buffer * buf, x64_gpr reg, int8_t imm) {
    emit_rex_prefix(buf, 1, 0, 0, reg >= R8_REG);
    emit_byte(buf, 0x83);
    emit_modrm(buf, 3, 4, reg % 8);  // mod=11, reg=/4 for AND
    emit_byte(buf, (uint8_t)imm);
}
/**
 * @internal
 * @brief Emits `add r/m64, imm8` (sign-extended) to a GPR.
 * @details Opcode format: REX.W + 83 /0 ib
 */
INFIX_INTERNAL void emit_add_reg_imm8(code_buffer * buf, x64_gpr reg, int8_t imm) {
    emit_rex_prefix(buf, 1, 0, 0, (reg >= R8_REG));
    emit_byte(buf, 0x83);
    emit_modrm(buf, 3, 0, (reg & 0x7));
    emit_byte(buf, imm);
}
/**
 * @internal
 * @brief Emits `dec r/m64` to decrement a 64-bit register by 1.
 * @details Opcode format: REX.W + FF /1
 */
INFIX_INTERNAL void emit_dec_reg(code_buffer * buf, x64_gpr reg) {
    emit_rex_prefix(buf, 1, 0, 0, reg >= R8_REG);
    emit_byte(buf, 0xFF);
    emit_modrm(buf, 3, 1, reg % 8);
}
// Stack & Control Flow Emitters
/**
 * @internal
 * @brief Emits `push r64` to push a GPR onto the stack.
 * @details Opcode format: [REX.B] 50+rd
 */
INFIX_INTERNAL void emit_push_reg(code_buffer * buf, x64_gpr reg) {
    uint8_t rex = 0;
    if (reg >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    emit_byte(buf, 0x50 + (reg % 8));
}
/**
 * @internal
 * @brief Emits `pop r64` to pop a 64-bit value from the stack into a register.
 * @details Opcode format: [REX.B] 58+rd
 */
INFIX_INTERNAL void emit_pop_reg(code_buffer * buf, x64_gpr reg) {
    uint8_t rex = 0;
    if (reg >= R8_REG)
        rex |= REX_B;
    if (rex)
        emit_byte(buf, 0x40 | rex);
    emit_byte(buf, 0x58 + (reg % 8));
}
/**
 * @internal
 * @brief Emits `call r64` to call a function pointer stored in a register.
 * @details Opcode format: [REX.W] [REX.B] FF /2
 */
INFIX_INTERNAL void emit_call_reg(code_buffer * buf, x64_gpr reg) {
    uint8_t rex = REX_W;
    if (reg >= R8_REG)
        rex |= REX_B;
    if (rex != REX_W)
        emit_byte(buf, 0x40 | rex);  // REX is only needed for extended regs
    else if (rex == REX_W)
        emit_byte(buf, 0x48);
    emit_byte(buf, 0xFF);
    emit_modrm(buf, 3, 2, reg % 8);  // mod=11, reg=/2 for CALL
}
/**
 * @internal
 * @brief Emits `ret` to return from a function.
 * @details Opcode: C3
 */
INFIX_INTERNAL void emit_ret(code_buffer * buf) { emit_byte(buf, 0xC3); }
/**
 * @internal
 * @brief Emits `cmp r64, r64` to compare two registers.
 * @details Opcode format: REX.W + 39 /r
 */
INFIX_INTERNAL void emit_cmp_reg_reg(code_buffer * buf, x64_gpr reg1, x64_gpr reg2) {
    emit_rex_prefix(buf, 1, reg2 >= R8_REG, 0, reg1 >= R8_REG);
    emit_byte(buf, 0x39);
    emit_modrm(buf, 3, reg2 % 8, reg1 % 8);
}
/**
 * @internal
 * @brief Emits `test r64, r64` to test if a register is zero.
 * @details Opcode format: REX.W + 85 /r
 */
INFIX_INTERNAL void emit_test_reg_reg(code_buffer * buf, x64_gpr reg1, x64_gpr reg2) {
    emit_rex_prefix(buf, 1, reg2 >= R8_REG, 0, reg1 >= R8_REG);
    emit_byte(buf, 0x85);
    emit_modrm(buf, 3, reg2 % 8, reg1 % 8);
}
/**
 * @internal
 * @brief Emits `jnz rel8` for a short conditional jump if not zero.
 * @details Opcode format: 75 rel8
 */
INFIX_INTERNAL void emit_jnz_short(code_buffer * buf, int8_t offset) { EMIT_BYTES(buf, 0x75, (uint8_t)offset); }
/**
 * @internal
 * @brief Emits `je rel8` for a short conditional jump if equal.
 * @details Opcode format: 74 rel8
 */
INFIX_INTERNAL void emit_je_short(code_buffer * buf, int8_t offset) { EMIT_BYTES(buf, 0x74, (uint8_t)offset); }
/**
 * @internal
 * @brief Emits a `jmp r64` instruction.
 * @details This instruction performs an indirect jump to the address contained in the
 * specified 64-bit register. Opcode format: [REX.B] FF /4
 */
INFIX_INTERNAL void emit_jmp_reg(code_buffer * buf, x64_gpr reg) {
    uint8_t rex = 0;
    if (reg >= R8_REG)
        rex = 0x40 | REX_B;
    if (rex)
        emit_byte(buf, rex);
    emit_byte(buf, 0xFF);
    emit_modrm(buf, 3, 4, reg % 8);  // mod=11 (register), reg=/4 for JMP
}
/**
 * @internal
 * @brief Emits `ud2`, an undefined instruction that causes an invalid opcode exception.
 * @details Opcode format: 0F 0B
 */
INFIX_INTERNAL void emit_ud2(code_buffer * buf) { EMIT_BYTES(buf, 0x0F, 0x0B); }
/**
 * @internal
 * @brief Emits the two-byte `syscall` instruction.
 * @details Opcode: 0F 05
 */
INFIX_INTERNAL void emit_syscall(code_buffer * buf) { EMIT_BYTES(buf, 0x0F, 0x05); }
/**
 * @internal
 * @brief Emits the `leave` instruction to tear down a stack frame.
 * @details This is equivalent to `mov rsp, rbp` followed by `pop rbp`.
 *          Opcode: C9
 */
INFIX_INTERNAL void emit_leave(code_buffer * buf) { emit_byte(buf, 0xC9); }
