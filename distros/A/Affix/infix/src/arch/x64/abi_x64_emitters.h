#pragma once
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
 * @file abi_x64_emitters.h
 * @brief Declares internal helper functions for emitting x86-64 machine code.
 * @ingroup internal_abi_x64
 *
 * @internal
 * This header provides the function prototypes for all low-level x86-64
 * instruction emitters. These functions are the fundamental building blocks
 * used by both the Windows x64 and System V x64 ABI implementations to generate
 * machine code. Each function corresponds to a specific machine instruction
 * or a common addressing mode, encapsulating the complexities of x86-64 encoding.
 * @endinternal
 */
#include "arch/x64/abi_x64_common.h"
#include "common/infix_internals.h"

// GPR <-> Immediate Value Emitters
/** @internal @brief Emits `mov r64, imm64` to load a 64-bit immediate value into a register. */
INFIX_INTERNAL void emit_mov_reg_imm64(code_buffer * buf, x64_gpr reg, uint64_t value);
/** @internal @brief Emits `mov r64, imm32` (sign-extended) to load a 32-bit immediate into a register. */
INFIX_INTERNAL void emit_mov_reg_imm32(code_buffer * buf, x64_gpr reg, int32_t imm);

// GPR <-> GPR Move Emitters
/** @internal @brief Emits `mov r64, r64` for a register-to-register move. */
INFIX_INTERNAL void emit_mov_reg_reg(code_buffer * buf, x64_gpr dest, x64_gpr src);

// Memory -> GPR Load Emitters
/** @internal @brief Emits `mov r64, [base + offset]` to load a 64-bit value from memory. */
INFIX_INTERNAL void emit_mov_reg_mem(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `mov r32, [base + offset]` to load a 32-bit value (zero-extended to 64). */
INFIX_INTERNAL void emit_mov_reg32_mem(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `movsxd r64, [base + offset]` to load a 32-bit value and sign-extend to 64. */
INFIX_INTERNAL void emit_movsxd_reg_mem(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `movsx r64, r/m8` to load a signed 8-bit value and sign-extend to 64. */
INFIX_INTERNAL void emit_movsx_reg64_mem8(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `movsx r64, r/m16` to load a signed 16-bit value and sign-extend to 64. */
INFIX_INTERNAL void emit_movsx_reg64_mem16(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `movzx r64, r/m8` to load an unsigned 8-bit value and zero-extend to 64. */
INFIX_INTERNAL void emit_movzx_reg64_mem8(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `movzx r64, r/m16` to load an unsigned 16-bit value and zero-extend to 64. */
INFIX_INTERNAL void emit_movzx_reg64_mem16(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset);

// GPR -> Memory Store Emitters
/** @internal @brief Emits `mov [base + offset], r64` to store a 64-bit GPR to memory. */
INFIX_INTERNAL void emit_mov_mem_reg(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_gpr src);
/** @internal @brief Emits `mov [base + offset], r32` to store a 32-bit GPR to memory. */
INFIX_INTERNAL void emit_mov_mem_reg32(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_gpr src);
/** @internal @brief Emits `mov [base + offset], r16` to store a 16-bit GPR to memory. */
INFIX_INTERNAL void emit_mov_mem_reg16(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_gpr src);
/** @internal @brief Emits `mov [base + offset], r8` to store an 8-bit GPR to memory. */
INFIX_INTERNAL void emit_mov_mem_reg8(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_gpr src);

// Memory <-> XMM/YMM (SSE/AVX) Emitters
/** @internal @brief Emits `movss xmm, [base + offset]` to load a 32-bit float from memory. */
INFIX_INTERNAL void emit_movss_xmm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `movss [base + offset], xmm` to store a 32-bit float to memory. */
INFIX_INTERNAL void emit_movss_mem_xmm(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_xmm src);
/** @internal @brief Emits `movsd xmm, [base + offset]` to load a 64-bit double from memory. */
INFIX_INTERNAL void emit_movsd_xmm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `movsd [base + offset], xmm` to store a 64-bit double to memory. */
INFIX_INTERNAL void emit_movsd_mem_xmm(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_xmm src);
/** @internal @brief Emits `movups xmm, [base + offset]` to load a 128-bit unaligned value from memory. */
INFIX_INTERNAL void emit_movups_xmm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `movups [base + offset], xmm` to store a 128-bit unaligned value to memory. */
INFIX_INTERNAL void emit_movups_mem_xmm(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_xmm src);
/** @internal @brief Emits `movaps xmm, xmm` to move 128 bits between XMM registers. */
INFIX_INTERNAL void emit_movups_xmm_xmm(code_buffer * buf, x64_xmm dest, x64_xmm src);
/** @internal @brief Emits `vmovupd ymm, [base + offset]` to load a 256-bit unaligned value (AVX). */
INFIX_INTERNAL void emit_vmovupd_ymm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `vmovupd zmm, [base + offset]` to load a 512-bit unaligned value (AVX-512). */
INFIX_INTERNAL void emit_vmovupd_zmm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `vmovupd [base + offset], zmm` to store a 512-bit unaligned value (AVX-512). */
INFIX_INTERNAL void emit_vmovupd_mem_zmm(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_xmm src);
/** @internal @brief Emits `vmovupd [base + offset], ymm` to store a 256-bit unaligned value (AVX). */
INFIX_INTERNAL void emit_vmovupd_mem_ymm(code_buffer * buf, x64_gpr dest_base, int32_t offset, x64_xmm src);
/** @internal @brief Emits `vzeroupper` to clear the upper bits of all YMM/ZMM registers. */
INFIX_INTERNAL void emit_vzeroupper(code_buffer * buf);
/** @internal @brief Emits `cvtsd2ss xmm1, xmm2/m64` to convert a double to a float. */
INFIX_INTERNAL void emit_cvtsd2ss_xmm_xmm(code_buffer * buf, x64_xmm dest, x64_xmm src);
/** @brief Emits `movaps xmm1, xmm2/m128` to move 128 bits between XMM registers. */
INFIX_INTERNAL void emit_movaps_xmm_xmm(code_buffer * buf, x64_xmm dest, x64_xmm src);
/** @internal @brief Emits `cvtsd2ss xmm, [base + offset]` to load a double, convert it to float, and store in xmm. */
INFIX_INTERNAL void emit_cvtsd2ss_xmm_mem(code_buffer * buf, x64_xmm dest, x64_gpr src_base, int32_t offset);

// GPR <-> XMM Move Emitters
/** @internal @brief Emits `movq xmm, r64` to move 64 bits from a GPR to an XMM register. */
INFIX_INTERNAL void emit_movq_xmm_gpr(code_buffer * buf, x64_xmm dest, x64_gpr src);
/** @internal @brief Emits `movq r64, xmm` to move 64 bits from an XMM to a GPR. */
INFIX_INTERNAL void emit_movq_gpr_xmm(code_buffer * buf, x64_gpr dest, x64_xmm src);

// Memory <-> x87 FPU Emitters
/** @internal @brief Emits `fldt [base + offset]` to load an 80-bit `long double` onto the FPU stack. */
INFIX_INTERNAL void emit_fldt_mem(code_buffer * buf, x64_gpr base, int32_t offset);
/** @internal @brief Emits `fstpt [base + offset]` to store and pop an 80-bit `long double`. */
INFIX_INTERNAL void emit_fstpt_mem(code_buffer * buf, x64_gpr base, int32_t offset);

// Arithmetic & Logic Emitters
/** @internal @brief Emits `lea r64, [base + offset]` to load an effective address. */
INFIX_INTERNAL void emit_lea_reg_mem(code_buffer * buf, x64_gpr dest, x64_gpr src_base, int32_t offset);
/** @internal @brief Emits `add r64, imm8` to add a sign-extended 8-bit immediate to a GPR. */
INFIX_INTERNAL void emit_add_reg_imm8(code_buffer * buf, x64_gpr reg, int8_t imm);  // Unused
/** @internal @brief Emits `add r64, imm32` to add a 32-bit immediate to a GPR. */
INFIX_INTERNAL void emit_add_reg_imm32(code_buffer * buf, x64_gpr reg, int32_t imm);
/** @internal @brief Emits `sub r64, imm32` to subtract a 32-bit immediate from a GPR. */
INFIX_INTERNAL void emit_sub_reg_imm32(code_buffer * buf, x64_gpr reg, int32_t imm);
/** @internal @brief Emits `and r64, imm8` to perform a bitwise AND with a sign-extended 8-bit immediate. */
INFIX_INTERNAL void emit_and_reg_imm8(code_buffer * buf, x64_gpr reg, int8_t imm);
/** @internal @brief Emits `dec r64` to decrement a 64-bit register by 1. */
INFIX_INTERNAL void emit_dec_reg(code_buffer * buf, x64_gpr reg);

// Stack & Control Flow Emitters
/** @internal @brief Emits `push r64` to push a GPR onto the stack. */
INFIX_INTERNAL void emit_push_reg(code_buffer * buf, x64_gpr reg);
/** @internal @brief Emits `pop r64` to pop a 64-bit value from the stack into a register. */
INFIX_INTERNAL void emit_pop_reg(code_buffer * buf, x64_gpr reg);
/** @internal @brief Emits `call r64` to call a function pointer stored in a register. */
INFIX_INTERNAL void emit_call_reg(code_buffer * buf, x64_gpr reg);
/** @internal @brief Emits `ret` to return from a function. */
INFIX_INTERNAL void emit_ret(code_buffer * buf);
/** @internal @brief Emits `test r64, r64` to test if a register is zero. */
INFIX_INTERNAL void emit_test_reg_reg(code_buffer * buf, x64_gpr reg1, x64_gpr reg2);
/** @internal @brief Emits `cmp r64, r64` to compare two registers. */
INFIX_INTERNAL void emit_cmp_reg_reg(code_buffer * buf, x64_gpr reg1, x64_gpr reg2);
/** @internal @brief Emits `jnz rel8` for a short conditional jump if not zero. */
INFIX_INTERNAL void emit_jnz_short(code_buffer * buf, int8_t offset);
/** @internal @brief Emits `je rel8` for a short conditional jump if equal. */
INFIX_INTERNAL void emit_je_short(code_buffer * buf, int8_t offset);
/** @internal @brief Emits `jmp r64` to jump to an address in a register. */
INFIX_INTERNAL void emit_jmp_reg(code_buffer * buf, x64_gpr reg);
/** @internal @brief Emits `ud2`, an undefined instruction that causes an invalid opcode exception. */
INFIX_INTERNAL void emit_ud2(code_buffer * buf);

// Stack Operation Emitters
/** @internal @brief Emits `pop r64` to pop a 64-bit value from the stack into a register. */
INFIX_INTERNAL void emit_pop_reg(code_buffer * buf, x64_gpr reg);
// Instruction Encoding Helpers
/** @internal @brief Emits an x86-64 ModR/M byte, used to encode operands. */
INFIX_INTERNAL void emit_modrm(code_buffer * buf, uint8_t mod, uint8_t reg_opcode, uint8_t rm);
/** @internal @brief Emits an x86-64 REX prefix byte for 64-bit operations and extended registers. */
INFIX_INTERNAL void emit_rex_prefix(code_buffer * buf, bool w, bool r, bool x, bool b);
/** @internal @brief Emits the `syscall` instruction (0x0F 0x05) for x86-64. */
INFIX_INTERNAL void emit_syscall(code_buffer * buf);
/** @internal @brief Emits the `leave` instruction, equivalent to `mov rsp, rbp; pop rbp`. */
INFIX_INTERNAL void emit_leave(code_buffer * buf);
