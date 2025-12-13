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
 * @file utility.h
 * @brief A header for conditionally compiled debugging utilities.
 * @ingroup internal_utils
 *
 * @internal
 * This header is the central point for the library's internal debugging infrastructure.
 * Its primary feature is that it behaves differently based on the `INFIX_DEBUG_ENABLED`
 * preprocessor macro. This allows debugging code to be seamlessly integrated
 * during development without affecting the performance or size of the final
 * production binary.
 *
 * - **When `INFIX_DEBUG_ENABLED` is defined and non-zero (Debug Mode):**
 *   - It declares the `infix_dump_hex` function for detailed memory inspection.
 *   - It defines the `INFIX_DEBUG_PRINTF` macro, which integrates with the `double_tap`
 *     test harness's logging system (`note()`) if available, or falls back to a
 *     standard `printf`. This allows debug messages from the core library to appear
 *     cleanly within the test output.
 *
 * - **When `INFIX_DEBUG_ENABLED` is not defined or is zero (Release Mode):**
 *   - All debugging macros are defined as no-ops (`((void)0)`).
 *   - The `infix_dump_hex` function is defined as an empty `static inline` function.
 *   - This design ensures that all debugging code and calls are completely compiled
 *     out by the optimizer, resulting in zero overhead in release builds.
 * @endinternal
 */
#include "common/compat_c23.h"
#include <stddef.h>
// Check if INFIX_DEBUG_ENABLED is defined and set to a non-zero value.
#if defined(INFIX_DEBUG_ENABLED) && INFIX_DEBUG_ENABLED
// The double_tap framework is only included if both debug mode AND the main
// test harness toggle are enabled. This allows for debug builds of non-test executables.
#if defined(DBLTAP_ENABLE)
#include "common/double_tap.h"
/**
 * @internal
 * @def INFIX_DEBUG_PRINTF(...)
 * @brief A macro for printing formatted debug messages during a debug build with the test harness.
 * @details In debug builds where `double_tap.h` is active, this macro wraps the `note()`
 *          macro, integrating debug output from the library's internals cleanly into the
 *          TAP-formatted test logs.
 * @example
 * ```c
 * INFIX_DEBUG_PRINTF("Processing type %d with size %zu", type->id, type->size);
 * ```
 */
#define INFIX_DEBUG_PRINTF(...) note("INFIX_DEBUG: " __VA_ARGS__)
#else
#include <stdio.h>
/**
 * @internal
 * @def INFIX_DEBUG_PRINTF(...)
 * @brief A macro for printing formatted debug messages (printf fallback).
 * @details In debug builds where the `double_tap.h` harness is *not* active (e.g., when
 *          building a standalone example program), this macro falls back to a standard
 *          `printf`, ensuring that debug messages are still visible.
 */
#define INFIX_DEBUG_PRINTF(...)                \
    do {                                       \
        printf("# INFIX_DEBUG: " __VA_ARGS__); \
        printf("\n");                          \
    } while (0)
#endif  // DBLTAP_ENABLE
/**
 * @internal
 * @brief Declares the function prototype for `infix_dump_hex` for use in debug builds.
 * @details This function is an invaluable tool for inspecting the raw machine code generated
 *          by the JIT compiler or examining the memory layout of complex structs. It prints
 *          a detailed hexadecimal and ASCII dump of a memory region to the standard
 *          output, formatted for readability.
 *
 * @param data A pointer to the start of the memory block to dump.
 * @param size The number of bytes to dump.
 * @param title A descriptive title to print before and after the hex dump.
 */
void infix_dump_hex(const void * data, size_t size, const char * title);
#else  // INFIX_DEBUG_ENABLED is NOT defined or is zero (Release Mode)
/**
 * @internal
 * @def INFIX_DEBUG_PRINTF(...)
 * @brief A no-op macro for printing debug messages in release builds.
 * @details In release builds, this macro is defined as `((void)0)`, a standard C idiom
 *          for creating a statement that does nothing and has no side effects. The
 *          compiler will completely remove any calls to it, ensuring zero performance impact.
 */
#define INFIX_DEBUG_PRINTF(...) ((void)0)
/**
 * @internal
 * @brief A no-op version of `infix_dump_hex` for use in release builds.
 * @details This function is defined as an empty `static inline` function.
 *          - `static`: Prevents linker errors if this header is included in multiple files.
 *          - `inline`: Suggests to the compiler that the function body is empty,
 *            allowing it to completely remove any calls to this function at the call site.
 *          - `c23_maybe_unused`: Suppresses compiler warnings about the parameters
 *            being unused in this empty implementation.
 *
 * @param data Unused in release builds.
 * @param size Unused in release builds.
 * @param title Unused in release builds.
 */
static inline void infix_dump_hex(c23_maybe_unused const void * data,
                                  c23_maybe_unused size_t size,
                                  c23_maybe_unused const char * title) {
    // This function does nothing in release builds and will be optimized away entirely.
}
#endif  // INFIX_DEBUG_ENABLED
