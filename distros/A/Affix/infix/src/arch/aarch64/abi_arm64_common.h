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
 * @file abi_arm64_common.h
 * @brief Common register definitions and instruction encodings for the AArch64 (ARM64) architecture.
 * @ingroup internal_abi_aarch64
 *
 * @internal
 * This header serves two primary purposes for the AArch64 backend:
 *
 * 1.  **Register Enumerations:** It defines enums for the general-purpose registers (GPRs) and
 *     the floating-point/SIMD registers (VPRs). These enums provide a clear, type-safe,
 *     and self-documenting way to refer to specific registers when emitting machine
 *     code or implementing the ABI logic. The comments on each register describe its
 *     role according to the standard AAPCS64 calling convention.
 *
 * 2.  **Instruction Encoding Constants:** It contains preprocessor definitions for the
 *     fixed bitfields of various AArch64 instructions. This abstracts away the
 *     "magic numbers" of machine code generation, making the emitter code in
 *     `abi_arm64_emitters.c` more readable and easier to verify against the official
 *     ARM Architecture Reference Manual.
 *
 * By centralizing these definitions, this header provides a single source of truth for
 * the low-level architectural details, separating them from the higher-level ABI logic.
 * @endinternal
 */
#include <stdint.h>
/**
 * @internal
 * @enum arm64_gpr
 * @brief Enumerates the ARM64 General-Purpose Registers (GPRs), X0-X30 and SP.
 *
 * @details The enum values (0-31) correspond directly to the 5-bit register numbers
 * used in the encoding of machine code instructions. The comments on each register
 * describe its primary role according to the standard "Procedure Call Standard for
 * the ARM 64-bit Architecture" (AAPCS64), indicating whether it is used for
 * arguments, return values, or must be preserved across function calls (callee-saved).
 */
typedef enum {
    X0_REG = 0,   ///< Argument 1 / Return value / Volatile (caller-saved).
    X1_REG,       ///< Argument 2 / Volatile.
    X2_REG,       ///< Argument 3 / Volatile.
    X3_REG,       ///< Argument 4 / Volatile.
    X4_REG,       ///< Argument 5 / Volatile.
    X5_REG,       ///< Argument 6 / Volatile.
    X6_REG,       ///< Argument 7 / Volatile.
    X7_REG,       ///< Argument 8 / Volatile.
    X8_REG,       ///< Indirect Result Location Register (holds address for large struct returns) / Volatile.
    X9_REG,       ///< Volatile (caller-saved) scratch register.
    X10_REG,      ///< Volatile scratch register.
    X11_REG,      ///< Volatile scratch register.
    X12_REG,      ///< Volatile scratch register.
    X13_REG,      ///< Volatile scratch register.
    X14_REG,      ///< Volatile scratch register.
    X15_REG,      ///< Volatile scratch register.
    X16_REG,      ///< Intra-Procedure-call scratch register (IP0) / Volatile. May be modified by the linker.
    X17_REG,      ///< Intra-Procedure-call scratch register (IP1) / Volatile. May be modified by the linker.
    X18_REG,      ///< Platform Register (reserved, usage is platform-specific) / May be callee-saved. Best to avoid.
    X19_REG,      ///< Callee-saved. Must be preserved by a called function.
    X20_REG,      ///< Callee-saved.
    X21_REG,      ///< Callee-saved.
    X22_REG,      ///< Callee-saved.
    X23_REG,      ///< Callee-saved.
    X24_REG,      ///< Callee-saved.
    X25_REG,      ///< Callee-saved.
    X26_REG,      ///< Callee-saved.
    X27_REG,      ///< Callee-saved.
    X28_REG,      ///< Callee-saved.
    X29_FP_REG,   ///< Frame Pointer (FP) / Callee-saved.
    X30_LR_REG,   ///< Link Register (LR), holds the return address / Volatile across calls.
    SP_REG = 31,  ///< Stack Pointer (SP). In some instructions, encoding 31 refers to the Zero Register (XZR/WZR).
} arm64_gpr;
/**
 * @internal
 * @enum arm64_vpr
 * @brief Enumerates the ARM64 Floating-Point/SIMD (NEON) registers (V-registers).
 *
 * @details These registers (V0-V31) are 128 bits wide and are used for passing and
 * returning floating-point arguments, Homogeneous Floating-point Aggregates (HFAs),
 * and short vector types. The comments describe their role in the AAPCS64.
 */
typedef enum {
    V0_REG = 0,  ///< Argument 1 / Return value / Volatile (caller-saved).
    V1_REG,      ///< Argument 2 / Volatile.
    V2_REG,      ///< Argument 3 / Volatile.
    V3_REG,      ///< Argument 4 / Volatile.
    V4_REG,      ///< Argument 5 / Volatile.
    V5_REG,      ///< Argument 6 / Volatile.
    V6_REG,      ///< Argument 7 / Volatile.
    V7_REG,      ///< Argument 8 / Volatile.
    V8_REG,      ///< Callee-saved (Note: only the lower 64 bits, D8-D15, must be preserved).
    V9_REG,      ///< Callee-saved (only lower 64 bits).
    V10_REG,     ///< Callee-saved (only lower 64 bits).
    V11_REG,     ///< Callee-saved (only lower 64 bits).
    V12_REG,     ///< Callee-saved (only lower 64 bits).
    V13_REG,     ///< Callee-saved (only lower 64 bits).
    V14_REG,     ///< Callee-saved (only lower 64 bits).
    V15_REG,     ///< Callee-saved (only lower 64 bits).
    V16_REG,     ///< Volatile (caller-saved) scratch register.
    V17_REG,     ///< Volatile scratch register.
    V18_REG,     ///< Volatile scratch register.
    V19_REG,     ///< Volatile scratch register.
    V20_REG,     ///< Volatile scratch register.
    V21_REG,     ///< Volatile scratch register.
    V22_REG,     ///< Volatile scratch register.
    V23_REG,     ///< Volatile scratch register.
    V24_REG,     ///< Volatile scratch register.
    V25_REG,     ///< Volatile scratch register.
    V26_REG,     ///< Volatile scratch register.
    V27_REG,     ///< Volatile scratch register.
    V28_REG,     ///< Volatile scratch register.
    V29_REG,     ///< Volatile scratch register.
    V30_REG,     ///< Volatile scratch register.
    V31_REG,     ///< Volatile scratch register.
} arm64_vpr;
/**
 * @internal
 * @enum arm64_cond
 * @brief Enumerates the ARM64 condition codes for conditional branches.
 */
typedef enum {
    A64_COND_EQ = 0x0,  ///< Equal
    A64_COND_NE = 0x1,  ///< Not Equal
    A64_COND_CS = 0x2,  ///< Carry Set (Higher or Same, unsigned)
    A64_COND_HS = 0x2,
    A64_COND_CC = 0x3,  ///< Carry Clear (Lower, unsigned)
    A64_COND_LO = 0x3,
    A64_COND_MI = 0x4,  ///< Minus (Negative)
    A64_COND_PL = 0x5,  ///< Plus (Positive or Zero)
    A64_COND_VS = 0x6,  ///< Overflow
    A64_COND_VC = 0x7,  ///< No Overflow
    A64_COND_HI = 0x8,  ///< Higher (Unsigned)
    A64_COND_LS = 0x9,  ///< Lower or Same (Unsigned)
    A64_COND_GE = 0xA,  ///< Greater or Equal (Signed)
    A64_COND_LT = 0xB,  ///< Less Than (Signed)
    A64_COND_GT = 0xC,  ///< Greater Than (Signed)
    A64_COND_LE = 0xD,  ///< Less Than or Equal (Signed)
    A64_COND_AL = 0xE,  ///< Always
} arm64_cond;
/**
 * @internal
 * @defgroup aarch64_opcodes AArch64 Instruction Opcodes and Bitfields
 * @brief Defines for the bit-level encoding of AArch64 instructions.
 * @details These constants represent the fixed bit patterns for various instruction
 *          classes as specified in the ARM Architecture Reference Manual. Using these
 *          defines instead of raw hex literals makes the emitter code more readable
 *          and easier to verify. The `U` suffix is critical to prevent signed
 *          integer overflow during bit-shifting operations at compile time.
 * @{
 */
// Common bitfields
#define A64_SF_64BIT (1U << 31)  // 'sf' (size field) bit for 64-bit operations
#define A64_SF_32BIT (0U << 31)  // 'sf' bit for 32-bit operations
#define A64_V_VECTOR (1U << 26)  // Vector bit for SIMD/FP instructions
// Data Processing -- Immediate (e.g., ADD, SUB)
#define A64_OPC_ADD (0b00U << 29)
#define A64_OPC_ADDS (0b01U << 29)
#define A64_OPC_SUB (0b10U << 29)
#define A64_OPC_SUBS (0b11U << 29)
#define A64_OP_ADD_SUB_IMM (0b0010001U << 24)
// Data Processing -- Register (e.g., ADD, ORR)
#define A64_OP_ADD_SUB_REG (0b01011U << 24)
#define A64_OP_LOGICAL_REG (0b01010U << 24)
#define A64_OPCODE_ORR (0b01U << 29)
// Move Wide (MOVZ, MOVK)
#define A64_OPC_MOVZ (0b10U << 29)
#define A64_OPC_MOVK (0b11U << 29)
#define A64_OP_MOVE_WIDE_IMM (0b100101U << 23)
// Load/Store -- Immediate Unsigned Offset
#define A64_OP_LOAD_STORE_IMM_UNSIGNED (0b111001U << 24)
#define A64_LDR_OP (1U << 22)
#define A64_OP_LOAD_STORE_PAIR_BASE (0b101000U << 24)  // Base for all LDP/STP variants
#define A64_OPC_STP (0b00U << 30)                      // opc field for Store Pair
#define A64_OPC_LDP (0b01U << 30)                      // opc field for Load Pair
#define A64_L_BIT_LOAD (1U << 22)                      // The 'L' bit distinguishes Load (1) from Store (0)
// Addressing modes for LDP/STP
#define A64_ADDR_POST_INDEX (0b01U << 23)     // [Xn], #imm
#define A64_ADDR_PRE_INDEX (0b11U << 23)      // [Xn, #imm]!
#define A64_ADDR_SIGNED_OFFSET (0b10U << 23)  // [Xn, #imm]
// Branching
#define A64_OP_BRANCH_REG (0b1101011U << 25)
#define A64_OPC_BR (0b0000U << 21)
#define A64_OPC_BLR (0b0001U << 21)
#define A64_OPC_RET (0b0010U << 21)
#define A64_OP_COMPARE_BRANCH_IMM (0b011010U << 25)
#define A64_OPC_CBNZ (1U << 24)
// System
#define A64_OP_SYSTEM (0b11010100U << 25)
#define A64_OP_BRK (0b00000000001U << 16)
#define A64_OP_SVC (0b00000000001U << 21)
/** @} */  // end aarch64_opcodes
