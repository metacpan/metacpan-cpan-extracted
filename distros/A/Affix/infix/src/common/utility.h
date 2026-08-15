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
#include <stdio.h>
/**
 * @internal
 * @def INFIX_DEBUG_PRINTF(...)
 * @brief A macro for printing formatted debug messages during a debug build.
 * @details This macro falls back to a standard `printf`, ensuring that debug messages are still visible.
 *          We use a '#' prefix to ensure these messages are treated as comments by TAP consumers.
 */
#define INFIX_DEBUG_PRINTF(...)                \
    do {                                       \
        printf("# INFIX_DEBUG: " __VA_ARGS__); \
        printf("\n");                          \
        fflush(stdout);                        \
    } while (0)

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
/**
 * @internal
 * @brief Declares the function prototype for `infix_dump_state` for use in debug builds.
 * @details This function is an invaluable tool for inspecting the processor state.
 *
 * @param file The file name where the function is being called.
 * @param title The line number.
 */
void infix_dump_state(const char * file, int line);
/**
 * @internal
 * @def INFIX_DUMP_STATE(...)
 * @brief Automatically pass on the current file and line to `infix_dump_state`.
 */
#define INFIX_DUMP_STATE() infix_dump_state(__FILE__, __LINE__)
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
/**
 * @internal
 * @brief A no-op version of `infix_dump_state` for use in release builds.
 * @details This function is defined as an empty `static inline` function.
 *          - `static`: Prevents linker errors if this header is included in multiple files.
 *          - `inline`: Suggests to the compiler that the function body is empty,
 *            allowing it to completely remove any calls to this function at the call site.
 *          - `c23_maybe_unused`: Suppresses compiler warnings about the parameters
 *            being unused in this empty implementation.
 *
 * @param file The file name where the function is being called.
 * @param title The line number.
 */
static inline void infix_dump_state(c23_maybe_unused const char * file, c23_maybe_unused int line) {
    // This function does nothing in release builds and will be optimized away entirely.
}
#endif  // INFIX_DEBUG_ENABLED
