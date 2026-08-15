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
 * Crucially, it checks both hardware support (CPUID) and OS support (XGETBV)
 * to prevent crashes when using AVX/AVX-512 instructions.
 * @endinternal
 */
#include "common/platform.h"
#include <infix/infix.h>
#include <stdint.h>

/**
 * @brief Retrieves the version of the infix library linked at runtime.
 * @return An `infix_version_t` structure containing the major, minor, and patch numbers.
 */
INFIX_API INFIX_NODISCARD infix_version_t infix_get_version(void) {
    return (infix_version_t){INFIX_MAJOR, INFIX_MINOR, INFIX_PATCH};
}

#if defined(INFIX_ARCH_X64)
#if defined(INFIX_COMPILER_MSVC)
#include <intrin.h>
#elif defined(INFIX_COMPILER_GCC) || defined(INFIX_COMPILER_CLANG)
#include <cpuid.h>
#endif

// Helper to execute XGETBV and return XCR0
static uint64_t _infix_xgetbv(void) {
#if defined(INFIX_COMPILER_MSVC)
    return _xgetbv(_XCR_XFEATURE_ENABLED_MASK);
#elif defined(INFIX_COMPILER_GCC) || defined(INFIX_COMPILER_CLANG)
    uint32_t eax, edx;
    __asm__ __volatile__("xgetbv" : "=a"(eax), "=d"(edx) : "c"(0));
    return ((uint64_t)edx << 32) | eax;
#else
    return 0;
#endif
}

// XCR0 Bit Masks
#define XCR0_SSE (1 << 1)
#define XCR0_AVX (1 << 2)
#define XCR0_OPMASK (1 << 5)
#define XCR0_ZMM_Hi256 (1 << 6)
#define XCR0_Hi16_ZMM (1 << 7)

#endif

#if defined(INFIX_ARCH_AARCH64) && defined(__has_include)
#if __has_include(<sys/auxv.h>) && defined(INFIX_OS_LINUX)
#include <sys/auxv.h>
#ifndef HWCAP_SVE
#define HWCAP_SVE (1 << 22)
#endif
#elif __has_include(<sys/sysctl.h>) && defined(INFIX_OS_MACOS)
#include <sys/sysctl.h>
#endif
#endif

#if defined(INFIX_ARCH_X64)
bool infix_cpu_has_avx2(void) {
    // Check CPUID for OSXSAVE bit (ECX bit 27 of leaf 1)
    // If this is 0, we can't use XGETBV.
    bool osxsave = false;
    bool avx2_hardware = false;

#if defined(INFIX_COMPILER_MSVC)
    int cpuInfo[4];
    __cpuid(cpuInfo, 1);
    osxsave = (cpuInfo[2] & (1 << 27)) != 0;

    __cpuidex(cpuInfo, 7, 0);
    avx2_hardware = (cpuInfo[1] & (1 << 5)) != 0;
#elif defined(INFIX_COMPILER_GCC) || defined(INFIX_COMPILER_CLANG)
    unsigned int eax, ebx, ecx, edx;
    __cpuid(1, eax, ebx, ecx, edx);
    osxsave = (ecx & (1 << 27)) != 0;

    if (__get_cpuid_max(0, NULL) >= 7) {
        __cpuid_count(7, 0, eax, ebx, ecx, edx);
        avx2_hardware = (ebx & (1 << 5)) != 0;
    }
#endif

    if (!osxsave || !avx2_hardware)
        return false;

    // 2. Check XCR0 to ensure OS has enabled YMM state saving.
    // Must have SSE(1) and AVX(2) bits set.
    uint64_t xcr0 = _infix_xgetbv();
    return (xcr0 & (XCR0_SSE | XCR0_AVX)) == (XCR0_SSE | XCR0_AVX);
}

bool infix_cpu_has_avx512f(void) {
    bool osxsave = false;
    bool avx512f_hardware = false;

#if defined(INFIX_COMPILER_MSVC)
    int cpuInfo[4];
    __cpuid(cpuInfo, 1);
    osxsave = (cpuInfo[2] & (1 << 27)) != 0;

    __cpuidex(cpuInfo, 7, 0);
    avx512f_hardware = (cpuInfo[1] & (1 << 16)) != 0;
#elif defined(INFIX_COMPILER_GCC) || defined(INFIX_COMPILER_CLANG)
    unsigned int eax, ebx, ecx, edx;
    __cpuid(1, eax, ebx, ecx, edx);
    osxsave = (ecx & (1 << 27)) != 0;

    if (__get_cpuid_max(0, NULL) >= 7) {
        __cpuid_count(7, 0, eax, ebx, ecx, edx);
        avx512f_hardware = (ebx & (1 << 16)) != 0;
    }
#endif

    if (!osxsave || !avx512f_hardware)
        return false;

    // 2. Check XCR0 for ZMM support.
    // Need SSE(1) | AVX(2) | opmask(5) | ZMM_Hi256(6) | Hi16_ZMM(7)
    uint64_t xcr0 = _infix_xgetbv();
    uint64_t required = XCR0_SSE | XCR0_AVX | XCR0_OPMASK | XCR0_ZMM_Hi256 | XCR0_Hi16_ZMM;
    return (xcr0 & required) == required;
}
#endif

#if defined(INFIX_ARCH_AARCH64)
bool infix_cpu_has_sve(void) {
#if defined(INFIX_OS_LINUX) && defined(HWCAP_SVE)
    return (getauxval(AT_HWCAP) & HWCAP_SVE) != 0;
#elif defined(INFIX_OS_MACOS)
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
