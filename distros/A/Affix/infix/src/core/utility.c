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
/**
 * @internal
 * @brief Declares the function prototype for `infix_dump_state` for use in debug builds.
 * @details This function is an invaluable tool for inspecting the processor state.
 *
 * This function is only compiled in debug builds.
 *
 * @param file The file name where the function is being called.
 * @param title The line number.
 */
void infix_dump_state(const char * file, int line) {
#if defined(INFIX_ARCH_X64)
    printf("# Dumping x64 Register State at %s:%d\n", file, line);
    volatile unsigned long long stack_dump[16];
    register long long rsp __asm__("rsp");

    __asm__ __volatile__(
        "movq %%rax, %%r15\n\t"
        "movq %%rbx, %%r14\n\t"
        "movq %%rcx, %%r13\n\t"
        "movq %%rdx, %%r12\n\t"
        "movq %%rsi, %%r11\n\t"
        "movq %%rdi, %%r10\n\t"
        "movq %%rbp, %%r9\n\t"
        :
        :
        : "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15");
    register long long rax __asm__("r15");
    register long long rbx __asm__("r14");
    register long long rcx __asm__("r13");
    register long long rdx __asm__("r12");
    register long long rsi __asm__("r11");
    register long long rdi __asm__("r10");
    register long long rbp __asm__("r9");

    for (int i = 0; i < 16; ++i)
        stack_dump[i] = ((unsigned long long *)rsp)[i];

    printf("# RAX: %016llx  RBX: %016llx\n", rax, rbx);
    printf("# RCX: %016llx  RDX: %016llx\n", rcx, rdx);
    printf("# RSI: %016llx  RDI: %016llx\n", rsi, rdi);
    printf("# RBP: %016llx  RSP: %016llx\n", rbp, rsp);
    fflush(stdout);

    printf("# Stack Dump (128 bytes) ---\n");
    for (int i = 0; i < 16; i += 2)
        printf("%016llx: %016llx %016llx\n", rsp + i * 8, stack_dump[i], stack_dump[i + 1]);
#elif defined(INFIX_ARCH_AARCH64)
    printf("# Dumping AArch64 Register State at %s:%d\n", file, line);
    volatile unsigned long long stack_dump[16];
    register long long sp __asm__("sp");

    long long x0, x1, x2, x3, x4, x5, x6, x7;
    __asm__ __volatile__(
        "mov %0, x0\n\t"
        "mov %1, x1\n\t"
        "mov %2, x2\n\t"
        "mov %3, x3\n\t"
        "mov %4, x4\n\t"
        "mov %5, x5\n\t"
        "mov %6, x6\n\t"
        "mov %7, x7\n\t"
        : "=r"(x0), "=r"(x1), "=r"(x2), "=r"(x3), "=r"(x4), "=r"(x5), "=r"(x6), "=r"(x7));
    printf("# x0: %016llx  x1: %016llx\n", x0, x1);
    printf("# x2: %016llx  x3: %016llx\n", x2, x3);
    printf("# x4: %016llx  x5: %016llx\n", x4, x5);
    printf("# x6: %016llx  x7: %016llx\n", x6, x7);

    printf("# SP: %016llx\n", sp);

    for (int i = 0; i < 16; ++i)
        stack_dump[i] = ((unsigned long long *)sp)[i];

    printf("# Stack Dump (128 bytes)\n");
    fflush(stdout);

    for (int i = 0; i < 16; i += 2)
        printf("# %016llx: %016llx %016llx\n", sp + i * 8, stack_dump[i], stack_dump[i + 1]);
#else
    printf("# infix_dump_state() not implemented for this architecture\n");
#endif
    fflush(stdout);
}
#endif  // INFIX_DEBUG_ENABLED
