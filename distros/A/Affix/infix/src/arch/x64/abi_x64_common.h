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
 * @file abi_x64_common.h
 * @brief Common register definitions for the x86-64 architecture.
 * @ingroup internal_abi_x64
 *
 * @internal
 * This header defines enums for the general-purpose (GPR) and SSE (XMM)
 * registers available on the x86-64 architecture. These enums are used by both
 * the Windows x64 and System V x64 ABI implementations to provide a clear,
 * type-safe way to refer to specific registers when emitting machine code.
 *
 * While the *usage* of these registers for argument passing differs significantly
 * between the two ABIs, the registers themselves and their numerical encoding are
 * universal. This header provides that common definition.
 * @endinternal
 */
#include <stdint.h>
/**
 * @internal
 * @enum x64_gpr
 * @brief Enumerates the 64-bit General-Purpose Registers (GPRs) for x86-64.
 *
 * @details The enum values correspond to the 3-bit or 4-bit register numbers used in the
 * ModR/M and REX byte encodings of x86-64 instructions. The comments on each
 * register describe its primary role and whether it is caller-saved (volatile)
 * or callee-saved (must be preserved across a function call), highlighting the
 * key differences between the Windows and System V ABIs.
 */
typedef enum {
    RAX_REG = 0,  ///< Volatile (caller-saved). Primary integer/pointer return value in both ABIs.
    RCX_REG = 1,  ///< Volatile. 1st integer argument on Windows x64; 4th on System V.
    RDX_REG = 2,  ///< Volatile. 2nd integer argument on Windows x64; 3rd on System V.
    RBX_REG = 3,  ///< Callee-saved. Must be preserved across function calls.
    RSP_REG = 4,  ///< Stack Pointer. Preserved relative to the frame pointer.
    RBP_REG = 5,  ///< Frame Pointer (Base Pointer). Callee-saved.
    RSI_REG = 6,  ///< Volatile on System V (2nd integer arg). Callee-saved on Windows.
    RDI_REG = 7,  ///< Volatile on System V (1st integer arg). Callee-saved on Windows.
    R8_REG = 8,   ///< Volatile. 3rd integer argument on Windows x64; 5th on System V.
    R9_REG,       ///< Volatile. 4th integer argument on Windows x64; 6th on System V.
    R10_REG,      ///< Volatile (caller-saved) scratch register.
    R11_REG,      ///< Volatile (caller-saved) scratch register.
    R12_REG,      ///< Callee-saved.
    R13_REG,      ///< Callee-saved.
    R14_REG,      ///< Callee-saved.
    R15_REG       ///< Callee-saved.
} x64_gpr;
/**
 * @internal
 * @enum x64_xmm
 * @brief Enumerates the 128-bit SSE registers (XMM0-XMM15) for x86-64.
 *
 * @details These registers are used for passing and returning floating-point arguments
 * (`float`, `double`) and small vectors. Note the difference in volatility for
 * registers XMM6-XMM15 between the Windows and System V ABIs.
 */
typedef enum {
    XMM0_REG,   ///< Volatile. 1st float/double argument. Also used for float/double return values.
    XMM1_REG,   ///< Volatile. 2nd float/double argument.
    XMM2_REG,   ///< Volatile. 3rd float/double argument.
    XMM3_REG,   ///< Volatile. 4th float/double argument.
    XMM4_REG,   ///< Volatile. Used for 5th (System V) float/double argument.
    XMM5_REG,   ///< Volatile. Used for 6th (System V) float/double argument.
    XMM6_REG,   ///< Volatile on System V. Callee-saved on Windows x64.
    XMM7_REG,   ///< Volatile on System V. Callee-saved on Windows x64.
    XMM8_REG,   ///< Volatile in both ABIs.
    XMM9_REG,   ///< Volatile in both ABIs.
    XMM10_REG,  ///< Volatile in both ABIs.
    XMM11_REG,  ///< Volatile in both ABIs.
    XMM12_REG,  ///< Volatile in both ABIs.
    XMM13_REG,  ///< Volatile in both ABIs.
    XMM14_REG,  ///< Volatile in both ABIs.
    XMM15_REG,  ///< Volatile in both ABIs.
    XMM16_REG,  ///< Volatile in both ABIs. Used for AVX-512 (ZMM16).
    XMM17_REG,  ///< Volatile in both ABIs.
    XMM18_REG,  ///< Volatile in both ABIs.
    XMM19_REG,  ///< Volatile in both ABIs.
    XMM20_REG,  ///< Volatile in both ABIs.
    XMM21_REG,  ///< Volatile in both ABIs.
    XMM22_REG,  ///< Volatile in both ABIs.
    XMM23_REG,  ///< Volatile in both ABIs.
    XMM24_REG,  ///< Volatile in both ABIs.
    XMM25_REG,  ///< Volatile in both ABIs.
    XMM26_REG,  ///< Volatile in both ABIs.
    XMM27_REG,  ///< Volatile in both ABIs.
    XMM28_REG,  ///< Volatile in both ABIs.
    XMM29_REG,  ///< Volatile in both ABIs.
    XMM30_REG,  ///< Volatile in both ABIs.
    XMM31_REG   ///< Volatile in both ABIs.
} x64_xmm;
