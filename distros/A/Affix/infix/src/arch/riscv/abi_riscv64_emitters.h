#pragma once
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
 * @file abi_riscv64_emitters.h
 * @brief Public interface for emitting RISC-V (RV64GC) instructions.
 * @ingroup internal_abi_riscv64
 *
 * @internal
 * The RISC-V backend is compiled as a "unity build" (`abi_riscv64.c` is included at the end of
 * `src/jit/trampoline.c`), so the implementation of these functions lives in the corresponding
 * `abi_riscv64_emitters.c` file, and this header declares their prototypes for use elsewhere.
 *
 * Every emitter appends a single, valid 32-bit RISC-V instruction to a `code_buffer`.
 * @endinternal
 */
#include "common/infix_internals.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/**
 * @internal
 * @brief Emit an `addi rd, rs1, imm` instruction. Used for stack frame adjustment and
 *        constant arithmetic.
 */
INFIX_INTERNAL void infix_riscv64_emit_addi(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm);
/**
 * @internal
 * @brief Emit an `addiw rd, rs1, imm` instruction (the RV64I 32-bit sign-extending variant).
 */
INFIX_INTERNAL void infix_riscv64_emit_addiw(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm);
/**
 * @internal
 * @brief Emit an `add rd, rs1, rs2` instruction. Used to compute pointers and offsets.
 */
INFIX_INTERNAL void infix_riscv64_emit_add(code_buffer * buf, uint8_t rd, uint8_t rs1, uint8_t rs2);
/**
 * @internal
 * @brief Emit a `sub rd, rs1, rs2` instruction.
 */
INFIX_INTERNAL void infix_riscv64_emit_sub(code_buffer * buf, uint8_t rd, uint8_t rs1, uint8_t rs2);
/**
 * @internal
 * @brief Emit a `slli rd, rs1, shamt` instruction.
 */
INFIX_INTERNAL void infix_riscv64_emit_slli(code_buffer * buf, uint8_t rd, uint8_t rs1, uint8_t shamt);
/**
 * @internal
 * @brief Emit a `srli rd, rs1, shamt` instruction.
 */
INFIX_INTERNAL void infix_riscv64_emit_srli(code_buffer * buf, uint8_t rd, uint8_t rs1, uint8_t shamt);
/**
 * @internal
 * @brief Emit a `lui rd, imm20` instruction.
 */
INFIX_INTERNAL void infix_riscv64_emit_lui(code_buffer * buf, uint8_t rd, uint32_t imm20);
/**
 * @internal
 * @brief Emit an `auipc rd, imm20` instruction.
 */
INFIX_INTERNAL void infix_riscv64_emit_auipc(code_buffer * buf, uint8_t rd, uint32_t imm20);
/**
 * @internal
 * @brief Emit a `jal rd, imm20` instruction (a near-relative call/jump).
 */
INFIX_INTERNAL void infix_riscv64_emit_jal(code_buffer * buf, uint8_t rd, int32_t imm20);
/**
 * @internal
 * @brief Emit a `jalr rd, rs1, imm12` instruction (an indirect call/jump).
 */
INFIX_INTERNAL void infix_riscv64_emit_jalr(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12);
/**
 * @internal
 * @brief Emit a `beq rs1, rs2, imm12` instruction.
 */
INFIX_INTERNAL void infix_riscv64_emit_beq(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12);
/**
 * @internal
 * @brief Emit a `bne rs1, rs2, imm12` instruction.
 */
INFIX_INTERNAL void infix_riscv64_emit_bne(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12);
/**
 * @internal
 * @brief Emit a `lb rd, imm12(rs1)` instruction (a sign-extending byte load).
 */
INFIX_INTERNAL void infix_riscv64_emit_lb(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12);
/**
 * @internal
 * @brief Emit an `lbu rd, imm12(rs1)` instruction (a zero-extending byte load).
 */
INFIX_INTERNAL void infix_riscv64_emit_lbu(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12);
/**
 * @internal
 * @brief Emit a `lh rd, imm12(rs1)` instruction (a sign-extending halfword load).
 */
INFIX_INTERNAL void infix_riscv64_emit_lh(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12);
/**
 * @internal
 * @brief Emit an `lhu rd, imm12(rs1)` instruction (a zero-extending halfword load).
 */
INFIX_INTERNAL void infix_riscv64_emit_lhu(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12);
/**
 * @internal
 * @brief Emit a `sb rs2, imm12(rs1)` instruction (a byte store).
 */
INFIX_INTERNAL void infix_riscv64_emit_sb(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12);
/**
 * @internal
 * @brief Emit a `sh rs2, imm12(rs1)` instruction (a halfword store).
 */
INFIX_INTERNAL void infix_riscv64_emit_sh(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12);
/**
 * @internal
 * @brief Emit a `ld rd, imm12(rs1)` instruction (a 64-bit integer load).
 */
INFIX_INTERNAL void infix_riscv64_emit_ld(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12);
/**
 * @internal
 * @brief Emit a `lw rd, imm12(rs1)` instruction (a 32-bit sign-extending integer load).
 */
INFIX_INTERNAL void infix_riscv64_emit_lw(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12);
/**
 * @internal
 * @brief Emit an `lwu rd, imm12(rs1)` instruction (a 32-bit zero-extending integer load).
 */
INFIX_INTERNAL void infix_riscv64_emit_lwu(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12);
/**
 * @internal
 * @brief Emit a `sd rs2, imm12(rs1)` instruction (a 64-bit integer store).
 */
INFIX_INTERNAL void infix_riscv64_emit_sd(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12);
/**
 * @internal
 * @brief Emit a `sw rs2, imm12(rs1)` instruction (a 32-bit integer store).
 */
INFIX_INTERNAL void infix_riscv64_emit_sw(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12);
/**
 * @internal
 * @brief Emit a `fld rd, imm12(rs1)` instruction (a 64-bit FP load).
 */
INFIX_INTERNAL void infix_riscv64_emit_fld(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12);
/**
 * @internal
 * @brief Emit a `fsd rs2, imm12(rs1)` instruction (a 64-bit FP store).
 */
INFIX_INTERNAL void infix_riscv64_emit_fsd(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12);
/**
 * @internal
 * @brief Emit a `flw rd, imm12(rs1)` instruction (a 32-bit FP load).
 */
INFIX_INTERNAL void infix_riscv64_emit_flw(code_buffer * buf, uint8_t rd, uint8_t rs1, int32_t imm12);
/**
 * @internal
 * @brief Emit a `fsw rs2, imm12(rs1)` instruction (a 32-bit FP store).
 */
INFIX_INTERNAL void infix_riscv64_emit_fsw(code_buffer * buf, uint8_t rs1, uint8_t rs2, int32_t imm12);
/**
 * @internal
 * @brief Emit a `fmv.d rd(FP), rs1(FP)` instruction (a 64-bit FP register move).
 */
INFIX_INTERNAL void infix_riscv64_emit_fmv_d(code_buffer * buf, uint8_t rd, uint8_t rs1);
/**
 * @internal
 * @brief Emit a `fmv.s rd(FP), rs1(FP)` instruction (a 32-bit FP register move).
 */
INFIX_INTERNAL void infix_riscv64_emit_fmv_s(code_buffer * buf, uint8_t rd, uint8_t rs1);
/**
 * @internal
 * @brief Emit a `fmv.w.x rd(FP), rs1(GPR)` instruction (copies the low 32 bits of a GPR
 *        into a 32-bit FP register).
 */
INFIX_INTERNAL void infix_riscv64_emit_fmv_w_x(code_buffer * buf, uint8_t rd, uint8_t rs1);
/**
 * @internal
 * @brief Emit a `fmv.x.w rd(GPR), rs1(FP)` instruction (copies the bits of a 32-bit FP
 *        register into a GPR).
 */
INFIX_INTERNAL void infix_riscv64_emit_fmv_x_w(code_buffer * buf, uint8_t rd, uint8_t rs1);
/**
 * @internal
 * @brief Emit a `fcvt.d.s rd(FP), rs1(FP)` instruction (widens a 32-bit float to 64-bit double).
 */
INFIX_INTERNAL void infix_riscv64_emit_fcvt_d_s(code_buffer * buf, uint8_t rd, uint8_t rs1);
/**
 * @internal
 * @brief Emit a `fcvt.s.d rd(FP), rs1(FP)` instruction (narrows a 64-bit double to 32-bit float).
 */
INFIX_INTERNAL void infix_riscv64_emit_fcvt_s_d(code_buffer * buf, uint8_t rd, uint8_t rs1);
/**
 * @internal
 * @brief Emit an `ebreak` instruction (a debugging trap).
 */
INFIX_INTERNAL void infix_riscv64_emit_ebreak(code_buffer * buf);
/**
 * @internal
 * @brief Load a signed 64-bit immediate value into a register using the standard `li`
 *        expansion. This mirrors how the AArch64 backend materializes large constants
 *        (e.g., for the reverse dispatcher or absolute function addresses).
 */
INFIX_INTERNAL void infix_riscv64_emit_load_u64_immediate(code_buffer * buf, uint8_t rd, uint64_t imm);
