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
 * @file abi_riscv64_common.h
 * @brief Common register definitions and instruction encodings for the RISC-V RV64GC architecture.
 * @ingroup internal_abi_riscv64
 *
 * @internal
 * This header serves two primary purposes for the RISC-V backend:
 *
 * 1.  **Register Enumerations:** It defines enums for the general-purpose registers (GPRs) and
 *     the floating-point registers (FPRs). These enums provide a clear, type-safe,
 *     and self-documenting way to refer to specific registers when emitting machine
 *     code or implementing the ABI logic. The comments on each register describe its
 *     role according to the standard RISC-V ELF psABI calling convention (lp64d).
 *
 * 2.  **Instruction Encoding Constants:** It contains preprocessor definitions for the
 *     fixed bitfields of various RISC-V instructions. This abstracts away the
 *     "magic numbers" of machine code generation, making the emitter code in
 *     `abi_riscv64_emitters.c` more readable and easier to verify against the
 *     RISC-V specification (Volume I: Unprivileged ISA).
 * @endinternal
 */
#include <stdint.h>
/**
 * @internal
 * @enum riscv_gpr
 * @brief Enumerates the RISC-V 64-bit General-Purpose Registers (x0-x31).
 *
 * @details The enum values (0-31) correspond directly to the 5-bit register numbers
 * used in the encoding of machine code instructions. The comments on each register
 * describe its primary role according to the RISC-V psABI.
 */
typedef enum {
    X_ZERO_REG = 0,  ///< x0: Hardwired zero. Reads return 0, writes are ignored.
    X_RA_REG,        ///< x1: Return Address. Set by `jal`/`jalr`; the standard link register.
    X_SP_REG,        ///< x2: Stack Pointer. Must always be 16-byte aligned.
    X_GP_REG,        ///< x3: Global Pointer (reserved for the ABI).
    X_TP_REG,        ///< x4: Thread Pointer (reserved for the ABI).
    X_T0_REG,        ///< x5: Temporary / caller-saved.
    X_T1_REG,        ///< x6: Temporary / caller-saved.
    X_T2_REG,        ///< x7: Temporary / caller-saved.
    X_S0_REG,        ///< x8: Saved register / Frame Pointer (`fp`). Callee-saved.
    X_S1_REG,        ///< x9: Saved register. Callee-saved.
    X_A0_REG = 10,   ///< x10: Argument 1 / Return value / caller-saved.
    X_A1_REG,        ///< x11: Argument 2 / Return value / caller-saved.
    X_A2_REG,        ///< x12: Argument 3 / caller-saved... (volatile).
    X_A3_REG,        ///< x13: Argument 4.
    X_A4_REG,        ///< x14: Argument 5.
    X_A5_REG,        ///< x15: Argument 6.
    X_A6_REG,        ///< x16: Argument 7.
    X_A7_REG,        ///< x17: Argument 8.
    X_S2_REG = 18,   ///< x18: Saved register. Callee-saved.
    X_S3_REG,        ///< x19: Saved register. Callee-saved.
    X_S4_REG,        ///< x20: Saved register. Callee-saved.
    X_S5_REG,        ///< x21: Saved register. Callee-saved.
    X_S6_REG,        ///< x22: Saved register. Callee-saved.
    X_S7_REG,        ///< x23: Saved register. Callee-saved.
    X_S8_REG,        ///< x24: Saved register. Callee-saved.
    X_S9_REG,        ///< x25: Saved register. Callee-saved.
    X_S10_REG,       ///< x26: Saved register. Callee-saved.
    X_S11_REG,       ///< x27: Saved register. Callee-saved.
    X_T3_REG = 28,   ///< x28: Temporary / caller-saved.
    X_T4_REG,        ///< x29: Temporary / caller-saved.
    X_T5_REG,        ///< x30: Temporary / caller-saved.
    X_T6_REG         ///< x31: Temporary / caller-saved.
} riscv_gpr;
/**
 * @internal
 * @enum riscv_fpr
 * @brief Enumerates the RISC-V 64-bit Floating-Point Registers (f0-f31).
 *
 * @details The enum values (0-31) correspond directly to the 5-bit register numbers
 * used in the encoding of FP instructions. In the LP64D psABI the floating-point
 * argument registers are `fa0`-`fa7`, which map to f10-f17 (NOT f0-f7).
 */
typedef enum {
    F_FT0_REG = 0,   ///< f0: Temporary / caller-saved.
    F_FT1_REG,       ///< f1: Temporary / caller-saved.
    F_FT2_REG,       ///< f2: Temporary / caller-saved.
    F_FT3_REG,       ///< f3: Temporary / caller-saved.
    F_FT4_REG,       ///< f4: Temporary / caller-saved.
    F_FT5_REG,       ///< f5: Temporary / caller-saved.
    F_FT6_REG,       ///< f6: Temporary / caller-saved.
    F_FT7_REG,       ///< f7: Temporary / caller-saved.
    F_FS0_REG = 8,   ///< f8: Saved register. Callee-saved.
    F_FS1_REG,       ///< f9: Saved register. Callee-saved.
    F_FA0_REG = 10,  ///< f10: FP Argument 1 / FP Return value / caller-saved.
    F_FA1_REG,       ///< f11: FP Argument 2 / caller-saved.
    F_FA2_REG,       ///< f12: FP Argument 3.
    F_FA3_REG,       ///< f13: FP Argument 4.
    F_FA4_REG,       ///< f14: FP Argument 5.
    F_FA5_REG,       ///< f15: FP Argument 6.
    F_FA6_REG,       ///< f16: FP Argument 7.
    F_FA7_REG,       ///< f17: FP Argument 8.
    F_FS2_REG = 18,  ///< f18: Saved register. Callee-saved.
    F_FS3_REG,       ///< f19: Saved register. Callee-saved.
    F_FS4_REG,       ///< f20: Saved register. Callee-saved.
    F_FS5_REG,       ///< f21: Saved register. Callee-saved.
    F_FS6_REG,       ///< f22: Saved register. Callee-saved.
    F_FS7_REG,       ///< f23: Saved register. Callee-saved.
    F_FS8_REG,       ///< f24: Saved register. Callee-saved.
    F_FS9_REG,       ///< f25: Saved register. Callee-saved.
    F_FS10_REG,      ///< f26: Saved register. Callee-saved.
    F_FS11_REG,      ///< f27: Saved register. Callee-saved.
    F_FT8_REG = 28,  ///< f28: Temporary / caller-saved.
    F_FT9_REG,       ///< f29: Temporary / caller-saved.
    F_FT10_REG,      ///< f30: Temporary / caller-saved.
    F_FT11_REG       ///< f31: Temporary / caller-saved.
} riscv_fpr;
/**
 * @internal
 * @defgroup riscv64_opcodes RISC-V Instruction Opcodes and Bitfields
 * @brief Defines for the bit-level encoding of RISC-V instructions.
 * @details These constants represent the fixed bit patterns for various instruction
 *          classes as specified in "The RISC-V Instruction Set Manual, Volume I".
 *          Using these defines instead of raw hex literals makes the emitter code
 *          more readable and easier to verify. The `U` suffix is critical to prevent
 *          signed integer overflow during bit-shifting operations at compile time.
 * @{
 */
// Base opcodes (bits 6:0)
#define RV_OP_LOAD 0x03U       // Loads (lb, lh, lw, ld, lbu, lhu, lwu)
#define RV_OP_OP_IMM 0x13U     // Register-immediate ALU ops (addi, slli, ...)
#define RV_OP_OP_IMM_32 0x1BU  // Register-immediate 32-bit ALU ops (addiw)
#define RV_OP_AUIPC 0x17U      // Add upper immediate to pc
#define RV_OP_STORE 0x23U      // Stores (sb, sh, sw, sd)
#define RV_OP_OP 0x33U         // Register-register ALU ops (add, sub, sll, ...)
#define RV_OP_LUI 0x37U        // Load upper immediate
#define RV_OP_BRANCH 0x63U     // Conditional branches
#define RV_OP_JALR 0x67U       // Jump and link register
#define RV_OP_JAL 0x6FU        // Jump and link
#define RV_OP_FP 0x53U         // Floating-point register ops
#define RV_OP_SYSTEM 0x73U     // System instructions
#define RV_OP_FLOAD 0x07U      // Floating-point loads (flw, fld)
#define RV_OP_FSTORE 0x27U     // Floating-point stores (fsw, fsd)
// funct3 fields (bits 14:12)
#define RV_F3_ADD_SUB 0x0U  // ADDI / ADD / SUB / SLL
#define RV_F3_SLL 0x1U      // SLLI / SLL
#define RV_F3_SLT 0x2U
#define RV_F3_SLTU 0x3U
#define RV_F3_XOR 0x4U
#define RV_F3_SR 0x5U  // SRLI / SRAI / SRL / SRA
#define RV_F3_OR 0x6U
#define RV_F3_AND 0x7U
// funct3 fields for loads/stores
#define RV_F3_LD 0x3U   // LD / SD
#define RV_F3_LW 0x2U   // LW / SW
#define RV_F3_LH 0x1U   // LH / SH
#define RV_F3_LB 0x0U   // LB / SB
#define RV_F3_LBU 0x4U  // LBU (no unsigned store exists)
#define RV_F3_LHU 0x5U  // LHU
#define RV_F3_LWU 0x6U  // LWU
#define RV_F3_FLD 0x3U  // FLD / FSD
#define RV_F3_FLW 0x2U  // FLW / FSW
#define RV_F3_FLH 0x1U  // FLH / FSH (Zfh)
// funct3 fields for branches
#define RV_F3_BEQ 0x0U
#define RV_F3_BNE 0x1U
#define RV_F3_BLT 0x4U
#define RV_F3_BGE 0x5U
#define RV_F3_BLTU 0x6U
#define RV_F3_BGEU 0x7U
// funct7 fields (bits 31:25) for R-type integer ops
#define RV_F7_ADD 0x00U
#define RV_F7_SUB 0x20U
#define RV_F7_SLL 0x00U
#define RV_F7_SRL 0x00U
#define RV_F7_SRA 0x20U
// Shift immediate funct6 (bits 31:26)
#define RV_F6_SLLI 0x00U
#define RV_F6_SRLI 0x00U
#define RV_F6_SRAI 0x10U
// Floating-point move instructions (funct7 selects the operation).
// The RV64 W-level moves transfer between GPRs and single-precision FP registers.
#define RV_F7_FMV_X_S 0x70U  // FMV.X.W: FP(single) -> GPR
#define RV_F7_FMV_S_X 0x78U  // FMV.W.X: GPR -> FP(single)
#define RV_F7_FMV_X_D 0x71U  // FMV.X.D: FP(double) -> GPR
#define RV_F7_FMV_D_X 0x79U  // FMV.D.X: GPR -> FP(double)
#define RV_F7_FMV_X_H 0x72U  // FMV.X.H (Zfh)
#define RV_F7_FMV_H_X 0x7AU  // FMV.H.X (Zfh)
// FP-to-FP moves are the FSGNJ pseudo-instructions (fmv.s rd,rs1 == fsgnj.s rd,rs1,rs1).
#define RV_F7_FSGNJ_S 0x10U  // FSGNJ.S
#define RV_F7_FSGNJ_D 0x11U  // FSGNJ.D
// The 'imm' (rs2) encodings used by the fcvt family to select source/target precision.
// The source precision selects funct7 bit 0: 0 = 32-bit source (FCVT.S.D), 1 = 64-bit source (FCVT.D.S).
#define RV_FCVT_RM_RNE 0x0U    // Round to nearest, ties to even
#define RV_F7_FCVT_S_D 0x20U   // FCVT.S.D: source is double-precision, dest is single
#define RV_F7_FCVT_D_S 0x21U   // FCVT.D.S: source is single-precision, dest is double
#define RV_RS2_FCVT_D_S 0x00U  // rs2 field for FCVT.D.S
#define RV_RS2_FCVT_S_D 0x01U  // rs2 field for FCVT.S.D
// Instruction bit-field helper macros
#define RV_RS1_SHIFT 15U
#define RV_RS2_SHIFT 20U
#define RV_RD_SHIFT 7U
#define RV_FUNCT3_SHIFT 12U
/** @} */  // end riscv64_opcodes

// Trampoline register roles (internal to the RISC-V backend).
/** @internal Callee-saved register holding the target function pointer across the marshalling code. */
#define RV_CTX_TARGET_REG X_S1_REG
/** @internal Callee-saved register holding the return-value buffer pointer across the marshalling code. */
#define RV_CTX_RET_REG X_S2_REG
/** @internal Callee-saved register holding the `void**` argument array pointer across the marshalling code. */
#define RV_CTX_ARGS_REG X_S3_REG
/** @internal Caller-saved scratch registers. */
#define RV_SCRATCH0_REG X_T0_REG
#define RV_SCRATCH1_REG X_T1_REG
#define RV_SCRATCH2_REG X_T2_REG
#define RV_SCRATCH3_REG X_T3_REG
