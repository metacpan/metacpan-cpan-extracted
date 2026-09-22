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
 * @file error.c
 * @brief Implements the thread-local error reporting system.
 * @ingroup internal_core
 *
 * @details This module provides the infrastructure for robust and thread-safe error
 * handling within the `infix` library.
 *
 * The core principle is that all detailed error information is stored in
 * **thread-local storage (TLS)**. This means that an error occurring in one thread
 * will never interfere with or be accidentally reported by an operation in another
 * thread.
 *
 * The workflow is as follows:
 * 1.  Every public API function calls `_infix_clear_error()` upon entry to reset the
 *     error state for the current thread.
 * 2.  If an internal function encounters an error, it calls `_infix_set_error()` or
 *     `_infix_set_system_error()` to record detailed diagnostic information, including
 *     an error code, category, and a descriptive message.
 * 3.  For parser errors, `_infix_set_error()` generates a rich, multi-line diagnostic
 *     message with a code snippet and a caret pointing to the error location, similar
 *     to a compiler error.
 * 4.  The user can call the public `infix_get_last_error()` function at any time to
 *     retrieve a copy of the last error that occurred on their thread.
 */
#include "common/infix_internals.h"
#include <infix/infix.h>
#include <stdarg.h>
#include <stdio.h>  // For snprintf
#include <string.h>

// Use a portable mechanism for thread-local storage (TLS).
// The order of checks is critical for cross-platform compatibility.
#if defined(INFIX_OS_OPENBSD)
// OpenBSD has known issues with TLS cleanup in some linking scenarios (segfault on exit).
// Disable TLS entirely on this platform to ensure stability, at the cost of thread-safety.
#define INFIX_TLS
#elif defined(INFIX_COMPILER_MSVC)
// Microsoft Visual C++
#define INFIX_TLS __declspec(thread)
#elif defined(INFIX_OS_WINDOWS) && defined(INFIX_COMPILER_CLANG)
// Clang on Windows: check if behaving like MSVC or GCC.
// If using MSVC codegen/headers, use declspec.
#define INFIX_TLS __declspec(thread)
#elif defined(INFIX_COMPILER_GCC)
// MinGW (GCC on Windows) and standard GCC/Clang on *nix.
// MinGW prefers __thread or _Thread_local over __declspec(thread).
#define INFIX_TLS __thread
#elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L && !defined(__STDC_NO_THREADS__)
// Fallback to C11 standard
#define INFIX_TLS _Thread_local
#else
// Fallback for compilers that do not support TLS. This is not thread-safe.
#warning "Compiler does not support thread-local storage; error handling will not be thread-safe."
#define INFIX_TLS
#endif

// A portable macro for safe string copying to prevent buffer overflows.
#if defined(INFIX_COMPILER_MSVC)
#define _INFIX_SAFE_STRNCPY(dest, src, count) strncpy_s(dest, sizeof(dest), src, count)
#else
#define _INFIX_SAFE_STRNCPY(dest, src, count) \
    do {                                      \
        strncpy(dest, src, (count));          \
        (dest)[(sizeof(dest)) - 1] = '\0';    \
    } while (0)
#endif

/**
 * @var g_infix_last_error
 * @brief The thread-local variable that stores the details of the last error.
 *
 * @details Each thread gets its own independent instance of this variable. It is
 * initialized to a "no error" state.
 */
static INFIX_TLS infix_error_details_t g_infix_last_error = {INFIX_CATEGORY_NONE, INFIX_CODE_SUCCESS, 0, 0, {0}};

/**
 * @var g_infix_last_signature_context
 * @brief A thread-local pointer to the full signature string being parsed.
 *
 * @details This is set by the high-level API functions (`infix_type_from_signature`, etc.)
 * before parsing begins. If a parser error occurs, `_infix_set_error` uses this
 * context to generate a rich, contextual error message.
 */
INFIX_TLS const char * g_infix_last_signature_context = nullptr;

/**
 * @internal
 * @brief Maps an `infix_error_code_t` to its human-readable string representation.
 * @param code The error code to map.
 * @return A constant string describing the error.
 */
static const char * _get_error_message_for_code(infix_error_code_t code) {
    switch (code) {
    case INFIX_CODE_SUCCESS:
        return "Success";
    case INFIX_CODE_UNKNOWN:
        return "An unknown error occurred";
    case INFIX_CODE_NULL_POINTER:
        return "A required pointer argument was NULL";
    case INFIX_CODE_MISSING_REGISTRY:
        return "A type registry was required but not provided";
    case INFIX_CODE_NATIVE_EXCEPTION:
        return "A native exception was thrown across the FFI boundary";
    case INFIX_CODE_OUT_OF_MEMORY:
        return "Out of memory";
    case INFIX_CODE_EXECUTABLE_MEMORY_FAILURE:
        return "Failed to allocate executable memory";
    case INFIX_CODE_PROTECTION_FAILURE:
        return "Failed to change memory protection flags";
    case INFIX_CODE_INVALID_ALIGNMENT:
        return "Invalid alignment requested (must be power of two > 0)";
    case INFIX_CODE_UNEXPECTED_TOKEN:
        return "Unexpected token or character";
    case INFIX_CODE_UNTERMINATED_AGGREGATE:
        return "Unterminated aggregate (missing '}', '>', ']', or ')')'";
    case INFIX_CODE_INVALID_KEYWORD:
        return "Invalid type keyword";
    case INFIX_CODE_MISSING_RETURN_TYPE:
        return "Function signature missing '->' or return type";
    case INFIX_CODE_INTEGER_OVERFLOW:
        return "Integer overflow detected during layout calculation";
    case INFIX_CODE_RECURSION_DEPTH_EXCEEDED:
        return "Type definition is too deeply nested";
    case INFIX_CODE_EMPTY_MEMBER_NAME:
        return "Named type was declared with empty angle brackets";
    case INFIX_CODE_EMPTY_SIGNATURE:
        return "The provided signature string was empty";
    case INFIX_CODE_UNSUPPORTED_ABI:
        return "The current platform ABI is not supported";
    case INFIX_CODE_TYPE_TOO_LARGE:
        return "A data type was too large to be handled by the ABI";
    case INFIX_CODE_UNRESOLVED_NAMED_TYPE:
        return "Named type not found in registry or is an undefined forward declaration";
    case INFIX_CODE_INVALID_MEMBER_TYPE:
        return "Aggregate contains an illegal member type (e.g., a struct with a void member)";
    case INFIX_CODE_LIBRARY_NOT_FOUND:
        return "The requested dynamic library could not be found";
    case INFIX_CODE_SYMBOL_NOT_FOUND:
        return "The requested symbol was not found in the library";
    case INFIX_CODE_LIBRARY_LOAD_FAILED:
        return "Loading the dynamic library failed";
    default:
        return "An unknown or unspecified error occurred";
    }
}

/**
 * @internal
 * @brief Sets the last error details for the current thread.
 *
 * If the error is from the parser and a signature context is available, this
 * function generates a rich, multi-line diagnostic message with a code snippet
 * and a caret pointing to the error location. Otherwise, it uses the standard,
 * single-line message for the given error code.
 *
 * @param category The category of the error.
 * @param code The specific error code.
 * @param position For parser errors, the byte offset into the signature string where the error occurred.
 */
void _infix_set_error(infix_error_category_t category, infix_error_code_t code, size_t position) {
    g_infix_last_error.category = category;
    g_infix_last_error.code = code;
    g_infix_last_error.position = position;
    g_infix_last_error.system_error_code = 0;
    // Check if we can generate a rich parser error message.
    if (category == INFIX_CATEGORY_PARSER && g_infix_last_signature_context != nullptr) {
        // Generate a rich, GCC-style error message for parser failures.
        const char * signature = g_infix_last_signature_context;
        size_t sig_len = strlen(signature);
        const size_t radius = 20;  // Number of characters to show around the error position.
        // Calculate the start and end of the snippet to display.
        size_t start = (position > radius) ? (position - radius) : 0;
        size_t end = (position + radius < sig_len) ? (position + radius) : sig_len;
        // Add indicators if the snippet is truncated.
        const char * start_indicator = (start > 0) ? "... " : "";
        const char * end_indicator = (end < sig_len) ? " ..." : "";
        size_t start_indicator_len = (start > 0) ? 4 : 0;
        // Create the code snippet line.
        char snippet[128];
        snprintf(snippet,
                 sizeof(snippet),
                 "%s%.*s%s",
                 start_indicator,
                 (int)(end - start),
                 signature + start,
                 end_indicator);
        // Create the pointer line with a caret '^' under the error.
        char pointer[128];
        size_t caret_pos = position - start + start_indicator_len;
        snprintf(pointer, sizeof(pointer), "%*s^", (int)caret_pos, "");
        // Build the final multi-line message piece by piece to avoid buffer overflows.
        char * p = g_infix_last_error.message;
        size_t remaining = sizeof(g_infix_last_error.message);
        int written;
        // Write the snippet and pointer lines.
        written = snprintf(p, remaining, "\n\n  %s\n  %s", snippet, pointer);
        if (written < 0 || (size_t)written >= remaining) {
            // Fallback to a simple message on snprintf failure or buffer overflow.
            const char * msg = _get_error_message_for_code(code);
            _INFIX_SAFE_STRNCPY(g_infix_last_error.message, msg, sizeof(g_infix_last_error.message) - 1);
            return;
        }
        p += written;
        remaining -= written;
        // Append the standard error description.
        snprintf(p, remaining, "\n\nError: %s", _get_error_message_for_code(code));
    }
    else {
        // For non-parser errors, just copy the standard message.
        const char * msg = _get_error_message_for_code(code);
        _INFIX_SAFE_STRNCPY(g_infix_last_error.message, msg, sizeof(g_infix_last_error.message) - 1);
    }
}

/**
 * @internal
 * @brief Sets a detailed system error with a platform-specific error code and message.
 *
 * @details This is used for errors originating from OS-level functions like `dlopen`,
 * `mmap`, or `VirtualAlloc`. It records both the `infix` error code and the
 * underlying system error code (`errno` or `GetLastError`).
 *
 * @param category The category of the error.
 * @param code The `infix` error code that corresponds to the failure.
 * @param system_code The OS-specific error code (e.g., from `errno` or `GetLastError`).
 * @param msg An optional custom message from the OS (e.g., from `dlerror`). If `nullptr`, the default message for
 * `code` is used.
 */
void _infix_set_system_error(infix_error_category_t category,
                             infix_error_code_t code,
                             long system_code,
                             const char * msg) {
    g_infix_last_error.category = category;
    g_infix_last_error.code = code;
    g_infix_last_error.position = 0;
    g_infix_last_error.system_error_code = system_code;
    if (msg)
        _INFIX_SAFE_STRNCPY(g_infix_last_error.message, msg, sizeof(g_infix_last_error.message) - 1);
    else {
        const char * default_msg = _get_error_message_for_code(code);
        _INFIX_SAFE_STRNCPY(g_infix_last_error.message, default_msg, sizeof(g_infix_last_error.message) - 1);
    }
}

/**
 * @internal
 * @brief Resets the error state for the current thread to "no error".
 *
 * This should be called at the beginning of every public API function to ensure
 * that a prior error from an unrelated call on the same thread is not accidentally
 * returned to the user.
 */
void _infix_clear_error(void) {
    g_infix_last_error.category = INFIX_CATEGORY_NONE;
    g_infix_last_error.code = INFIX_CODE_SUCCESS;
    g_infix_last_error.position = 0;
    g_infix_last_error.system_error_code = 0;
    g_infix_last_error.message[0] = '\0';
    g_infix_last_signature_context = nullptr;
}

/**
 * @brief Retrieves detailed information about the last error that occurred on the current thread.
 * @return A copy of the last error details structure. This function is thread-safe.
 */
INFIX_API infix_error_details_t infix_get_last_error(void) { return g_infix_last_error; }
