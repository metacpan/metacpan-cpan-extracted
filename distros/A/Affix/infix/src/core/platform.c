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
 * @file platform.c
 * @brief Implements runtime detection of CPU and OS features.
 * @ingroup internal_core
 *
 * @internal
 * This module contains the platform-specific code for querying the runtime
 * environment's capabilities, such as support for advanced CPU instruction sets.
 * @endinternal
 */
#include "common/platform.h"
#if defined(INFIX_ARCH_X64)
#if defined(_MSC_VER)
#include <intrin.h>
#elif defined(__GNUC__) || defined(__clang__)
#include <cpuid.h>
#endif
#endif
#if defined(INFIX_ARCH_AARCH64) && defined(__has_include)
#if __has_include(<sys/auxv.h>) && defined(__linux__)
#include <sys/auxv.h>
#ifndef HWCAP_SVE
#define HWCAP_SVE (1 << 22)
#endif
#elif __has_include(<sys/sysctl.h>) && defined(__APPLE__)
#include <sys/sysctl.h>
#endif
#endif
#if defined(INFIX_ARCH_X64)
bool infix_cpu_has_avx2(void) {
#if defined(_MSC_VER)
    int cpuInfo[4];
    __cpuidex(cpuInfo, 7, 0);
    return (cpuInfo[1] & (1 << 5)) != 0;
#elif defined(__GNUC__) || defined(__clang__)
    unsigned int eax, ebx, ecx, edx;
    if (__get_cpuid_max(0, NULL) >= 7) {
        __cpuid_count(7, 0, eax, ebx, ecx, edx);
        return (ebx & (1 << 5)) != 0;
    }
    return false;
#else
    return false;
#endif
}
bool infix_cpu_has_avx512f(void) {
#if defined(_MSC_VER)
    int cpuInfo[4];
    __cpuidex(cpuInfo, 7, 0);
    return (cpuInfo[1] & (1 << 16)) != 0;
#elif defined(__GNUC__) || defined(__clang__)
    unsigned int eax, ebx, ecx, edx;
    if (__get_cpuid_max(0, NULL) >= 7) {
        __cpuid_count(7, 0, eax, ebx, ecx, edx);
        return (ebx & (1 << 16)) != 0;
    }
    return false;
#else
    return false;
#endif
}
#endif
#if defined(INFIX_ARCH_AARCH64)
bool infix_cpu_has_sve(void) {
#if defined(__linux__) && defined(HWCAP_SVE)
    return (getauxval(AT_HWCAP) & HWCAP_SVE) != 0;
#elif defined(__APPLE__)
    int sve_present = 0;
    size_t size = sizeof(sve_present);
    if (sysctlbyname("hw.optional.arm.FEAT_SVE", &sve_present, &size, NULL, 0) == 0)
        return sve_present == 1;
    return false;
#else
    // Add checks for other OS (e.g., Windows on ARM) if needed.
    return false;
#endif
}
#endif
