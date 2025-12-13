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
 * @file utility.c
 * @brief Implements internal debugging utilities.
 * @ingroup internal_core
 *
 * @details This file provides the implementation for debugging functions that are
 * conditionally compiled only when the `INFIX_DEBUG_ENABLED` preprocessor macro
 * is defined and set to a non-zero value.
 *
 * In release builds, this entire translation unit is effectively empty, ensuring
 * that debugging code has no impact on the final binary's size or performance.
 * The corresponding function declarations in `utility.h` become empty inline
 * stubs, which are optimized away by the compiler.
 */
// This file is only compiled if debugging is enabled.
#if defined(INFIX_DEBUG_ENABLED) && INFIX_DEBUG_ENABLED
// Use the double-tap test harness's `note` macro for debug printing if available.
// This integrates the debug output seamlessly into the TAP test logs.
#if defined(DBLTAP_ENABLE) && defined(DBLTAP_IMPLEMENTATION)
#include "common/double_tap.h"
#else
// If not building as part of a test, fall back to a standard printf implementation.
#include <stdio.h>
#ifndef note
#define note(...)                 \
    do {                          \
        printf("# " __VA_ARGS__); \
        printf("\n");             \
    } while (0)
#endif
#endif  // DBLTAP_ENABLE
#include "common/utility.h"
#include <inttypes.h>
/**
 * @internal
 * @brief Dumps a block of memory to standard output in a standard hexadecimal format.
 *
 * @details This is an essential debugging tool for inspecting the machine code generated
 * by the JIT engine or for examining the memory layout of complex data structures.
 * The output is formatted similarly to common hex dump utilities, with a 16-byte
 * width, address offsets, hexadecimal bytes, and an ASCII representation.
 *
 * This function is only compiled in debug builds.
 *
 * @param data A pointer to the memory to dump.
 * @param size The number of bytes to dump.
 * @param title A descriptive title to print before the hex dump.
 */
void infix_dump_hex(const void * data, size_t size, const char * title) {
    const uint8_t * byte = (const uint8_t *)data;
    char line_buf[256];
    char * buf_ptr;
    size_t remaining_len;
    int written;
    note("%s (size: %llu bytes at %p)", title, (unsigned long long)size, data);
    for (size_t i = 0; i < size; i += 16) {
        buf_ptr = line_buf;
        remaining_len = sizeof(line_buf);
        // Print the address offset for the current line.
        written = snprintf(buf_ptr, remaining_len, "0x%04llx: ", (unsigned long long)i);
        if (written < 0 || (size_t)written >= remaining_len)
            goto print_line;
        buf_ptr += written;
        remaining_len -= written;
        // Print the hexadecimal representation of the bytes.
        for (size_t j = 0; j < 16; ++j) {
            if (i + j < size)
                written = snprintf(buf_ptr, remaining_len, "%02x ", byte[i + j]);
            else
                written = snprintf(buf_ptr, remaining_len, "   ");  // Pad if at the end of the data.
            if (written < 0 || (size_t)written >= remaining_len)
                goto print_line;
            buf_ptr += written;
            remaining_len -= written;
            if (j == 7) {  // Add an extra space in the middle for readability.
                written = snprintf(buf_ptr, remaining_len, " ");
                if (written < 0 || (size_t)written >= remaining_len)
                    goto print_line;
                buf_ptr += written;
                remaining_len -= written;
            }
        }
        written = snprintf(buf_ptr, remaining_len, "| ");
        if (written < 0 || (size_t)written >= remaining_len)
            goto print_line;
        buf_ptr += written;
        remaining_len -= written;
        // Print the ASCII representation of the bytes.
        for (size_t j = 0; j < 16; ++j) {
            if (i + j < size) {
                if (byte[i + j] >= 32 && byte[i + j] <= 126)  // Printable ASCII characters
                    written = snprintf(buf_ptr, remaining_len, "%c", byte[i + j]);
                else
                    written = snprintf(buf_ptr, remaining_len, ".");  // Non-printable characters
                if (written < 0 || (size_t)written >= remaining_len)
                    goto print_line;
                buf_ptr += written;
                remaining_len -= written;
            }
        }
print_line:
        note("  %s", line_buf);
    }
    note("End of %s", title);
}
#endif  // INFIX_DEBUG_ENABLED
