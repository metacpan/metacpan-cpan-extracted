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
 * @file platform.h
 * @brief Declares internal, runtime CPU/OS feature detection functions.
 * @ingroup internal_core
 *
 * @internal
 * This header provides declarations for functions that perform runtime checks for
 * advanced CPU instruction set support (e.g., AVX2, AVX-512, SVE) and other
 * platform-specific queries. This allows the library to gracefully adapt to the
 * capabilities of the hardware it is running on.
 * @endinternal
 */
#pragma once
#include "common/compat_c23.h"
#include "common/infix_config.h"
#include <stdbool.h>
#if defined(INFIX_ARCH_X64)
/** @internal @brief Checks if the CPU supports the AVX2 instruction set at runtime. */
INFIX_INTERNAL c23_nodiscard bool infix_cpu_has_avx2(void);
/** @internal @brief Checks if the CPU supports the AVX-512F (Foundation) instruction set at runtime. */
INFIX_INTERNAL c23_nodiscard bool infix_cpu_has_avx512f(void);
#endif
#if defined(INFIX_ARCH_AARCH64)
/** @internal @brief Checks if the CPU supports the SVE (Scalable Vector Extension) at runtime. */
INFIX_INTERNAL c23_nodiscard bool infix_cpu_has_sve(void);
#endif
