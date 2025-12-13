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
#pragma once
/**
 * @file abi_arm64_emitters.h
 * @brief Declares internal helper functions for emitting AArch64 machine code.
 * @ingroup internal_abi_aarch64
 *
 * @internal
 * This header provides the function prototypes for all low-level AArch64 instruction
 * emitters. These functions are the fundamental building blocks used by `abi_arm64.c`
 * to generate the machine code for both forward and reverse trampolines.
 *
 * This module was created to cleanly separate the low-level, bit-twiddling details
 * of AArch64 instruction set encoding from the higher-level logic of applying the
 * AAPCS64 ABI rules (like argument classification and stack layout).
 * @endinternal
 */
#include "arch/aarch64/abi_arm64_common.h"
#include "common/infix_internals.h"
// GPR <-> Immediate Value Emitters
/** @internal @brief Emits a MOVZ/MOVK sequence to load an arbitrary 64-bit immediate into a GPR. */
void emit_arm64_load_u64_immediate(code_buffer * buf, arm64_gpr dest, uint64_t value);
// GPR <-> GPR Move Emitters
/** @internal @brief Emits `MOV <Xd|Wd>, <Xn|Wn>` for a register-to-register move. */
void emit_arm64_mov_reg(code_buffer * buf, bool is64, arm64_gpr dest, arm64_gpr src);
// Memory <-> GPR Load/Store Emitters
/** @internal @brief Emits `LDR <Wt|Xt>, [<Xn|SP>, #imm]` to load a GPR from memory. */
void emit_arm64_ldr_imm(code_buffer * buf, bool is64, arm64_gpr dest, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `LDRB <Wt>, [<Xn|SP>, #imm]` to load a byte from memory. */
void emit_arm64_ldrb_imm(code_buffer * buf, arm64_gpr dest, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `LDRH <Wt>, [<Xn|SP>, #imm]` to load a half-word from memory. */
void emit_arm64_ldrh_imm(code_buffer * buf, arm64_gpr dest, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `LDRSW <Xt>, [<Xn|SP>, #imm]` to load a 32-bit value and sign-extend to 64-bit. */
void emit_arm64_ldrsw_imm(code_buffer * buf, arm64_gpr dest, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `STR <Wt|Xt>, [<Xn|SP>, #imm]` to store a GPR to memory. */
void emit_arm64_str_imm(code_buffer * buf, bool is64, arm64_gpr src, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `STRB <Wt>, [<Xn|SP>, #imm]` to store a byte from a GPR to memory. */
void emit_arm64_strb_imm(code_buffer * buf, arm64_gpr src, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `STRH <Wt>, [<Xn|SP>, #imm]` to store a half-word (16-bit) from a GPR to memory. */
void emit_arm64_strh_imm(code_buffer * buf, arm64_gpr src, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `STP <Xt1>, <Xt2>, [Xn|SP, #imm]!` with pre-indexing to store a pair of GPRs. */
void emit_arm64_stp_pre_index(
    code_buffer * buf, bool is64, arm64_gpr src1, arm64_gpr src2, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `LDP <Xt1>, <Xt2>, [Xn|SP], #imm` with post-indexing to load a pair of GPRs. */
void emit_arm64_ldp_post_index(
    code_buffer * buf, bool is64, arm64_gpr dest1, arm64_gpr dest2, arm64_gpr base, int32_t offset);
// Memory <-> VPR (SIMD/FP) Emitters
/** @internal @brief Emits `LDR <St|Dt>, [<Xn|SP>, #imm]` to load a 32/64-bit FP value from memory. */
void emit_arm64_ldr_vpr(code_buffer * buf, bool is64, arm64_vpr dest, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `STR <St|Dt>, [<Xn|SP>, #imm]` to store a 32/64-bit FP value to memory. */
void emit_arm64_str_vpr(code_buffer * buf, bool is64, arm64_vpr src, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `LDR <Qt>, [<Xn|SP>, #imm]` for a 128-bit load into a SIMD&FP register. */
void emit_arm64_ldr_q_imm(code_buffer * buf, arm64_vpr dest, arm64_gpr base, int32_t offset);
/** @internal @brief Emits `STR <Qt>, [<Xn|SP>, #imm]` for a 128-bit store from a SIMD&FP register. */
void emit_arm64_str_q_imm(code_buffer * buf, arm64_vpr src, arm64_gpr base, int32_t offset);
// Arithmetic Emitters
/** @internal @brief Emits `ADD(S) <Xd|Wd>, <Xn|Wn>, #imm` to add an immediate to a GPR. */
void emit_arm64_add_imm(code_buffer * buf, bool is64, bool set_flags, arm64_gpr dest, arm64_gpr base, uint32_t imm);
/** @internal @brief Emits `SUB(S) <Xd|Wd>, <Xn|Wn>, #imm` to subtract an immediate from a GPR. */
void emit_arm64_sub_imm(code_buffer * buf, bool is64, bool set_flags, arm64_gpr dest, arm64_gpr base, uint32_t imm);
// Control Flow Emitters
/** @internal @brief Emits `BLR <Xn>` to branch with link to a register. */
void emit_arm64_blr_reg(code_buffer * buf, arm64_gpr reg);
/** @internal @brief Emits `RET [Xn]` to return from a function (defaults to `RET X30`). */
void emit_arm64_ret(code_buffer * buf, arm64_gpr reg);
/** @internal @brief Emits `CBNZ <Xt>, #imm` to compare and branch if register is not zero. */
void emit_arm64_cbnz(code_buffer * buf, bool is64, arm64_gpr reg, int32_t offset);
/** @internal @brief Emits `BRK #imm` to cause a software breakpoint exception. */
void emit_arm64_brk(code_buffer * buf, uint16_t imm);
/** @internal @brief Emits `BR <Xn>` to branch to an address in a register. */
void emit_arm64_b_reg(code_buffer * buf, arm64_gpr reg);
/** @internal @brief Emits `BRK #imm` to cause a software breakpoint exception. */
void emit_arm64_brk(code_buffer * buf, uint16_t imm);
/** @internal @brief Emits `BR <Xn>` to branch to an address in a register. */
void emit_arm64_b_reg(code_buffer * buf, arm64_gpr reg);
/**
 * @internal
 * @brief Emits `SVC #imm` to generate a supervisor call exception.
 * @details This is the instruction used to make system calls on AArch64.
 * @param buf The code buffer to append the instruction to.
 * @param imm A 16-bit immediate value passed to the kernel. For syscalls, this is typically 0.
 */
void emit_arm64_svc_imm(code_buffer * buf, uint16_t imm);
