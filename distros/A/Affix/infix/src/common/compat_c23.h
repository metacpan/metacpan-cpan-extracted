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
 * @file compat_c23.h
 * @brief Provides forward compatibility macros for C23 features.
 * @ingroup internal_common
 *
 * @details This header is a crucial component for maintaining source code
 * compatibility across a wide range of compilers that may not fully support the
 * latest C23 standard. It acts as a "shim" or compatibility layer, allowing the
 * rest of the codebase to be written using modern, standards-compliant syntax
 * while ensuring it still compiles on older C11/C17 compilers.
 *
 * The primary purpose is to define a set of `c23_*` macros (e.g., `c23_nodiscard`)
 * that translate modern C23 attribute syntax (`[[attribute]]`) into older,
 * compiler-specific equivalents (like `__attribute__((...))` for GCC/Clang or
 * `__declspec(...)` for MSVC). If a compiler supports none of these, the macros
 * expand to nothing, ensuring compilation succeeds at the cost of losing the
 * specific compiler check (a principle known as graceful degradation).
 *
 * This approach centralizes all compiler-specific feature detection, keeping the
 * rest of the library's code clean and free of `#ifdef` clutter.
 *
 * @internal
 */
#pragma once
#include <infix/infix.h>
#include <stdbool.h>
#include <stddef.h>
/**
 * @def nullptr
 * @brief Defines `nullptr` as a standard C-style null pointer constant (`(void*)0`).
 *
 * @details This provides a consistent null pointer constant across C and C++
 * compilation environments. While `NULL` is standard in C, `nullptr` is preferred
 * in modern C++ and is being adopted in newer C standards. This macro ensures
 * the codebase can use `nullptr` consistently without causing compilation errors
 * in a strict C11/C17 environment.
 */
#if !defined(nullptr) && !defined(__cplusplus)
#define nullptr ((void *)0)
#endif
/**
 * @def static_assert
 * @brief Defines a `static_assert` macro that maps to the C11 `_Static_assert`.
 *
 * @note This is a polyfill for older compilers or environments that might not
 * define `static_assert` as a more convenient macro in `<assert.h>` by default,
 * even if they support the underlying `_Static_assert` keyword. It allows for
 * compile-time assertions throughout the codebase.
 */
#if !defined(__cplusplus) && \
    ((defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L) || (defined(_MSC_VER) && _MSC_VER >= 1900))
#include <assert.h>
#ifndef static_assert
#define static_assert(cond, msg) _Static_assert(cond, msg)
#endif
#endif
/**
 * @def COMPAT_HAS_C_ATTRIBUTE
 * @brief A utility macro to safely check for the existence of a C attribute.
 *
 * @details This macro wraps the `__has_c_attribute` feature test macro, which is
 * not universally available across all compilers. By defining this wrapper,
 * the code can safely check for attribute support without causing a preprocessor
 * error on compilers that do not define `__has_c_attribute`.
 *
 * @param[in] x The name of the attribute to check (e.g., `nodiscard`).
 * @return `1` if the attribute is supported, `0` otherwise.
 */
#if defined(__has_c_attribute)
#define COMPAT_HAS_C_ATTRIBUTE(x) __has_c_attribute(x)
#else
#define COMPAT_HAS_C_ATTRIBUTE(x) 0
#endif
/**
 * @def c23_nodiscard
 * @brief Internal alias for the public INFIX_NODISCARD macro.
 */
#define c23_nodiscard INFIX_NODISCARD
/**
 * @def c23_deprecated
 * @brief A compatibility macro for the C23 `[[deprecated]]` attribute.
 *
 * @details This attribute is used to mark a function or type as obsolete. The
 * compiler will issue a warning if any code attempts to use a deprecated entity,
 * guiding users toward newer APIs and helping to manage API evolution.
 *
 * This macro expands to:
 * - `[[deprecated]]` on compilers that support the C23 standard syntax.
 * - `__attribute__((deprecated))` on GCC and Clang.
 * - `__declspec(deprecated)` on Microsoft Visual C++.
 * - Nothing on other compilers.
 */
#if COMPAT_HAS_C_ATTRIBUTE(deprecated)
#define c23_deprecated [[deprecated]]
#elif defined(__GNUC__) || defined(__clang__)
#define c23_deprecated __attribute__((deprecated))
#elif defined(_MSC_VER)
#define c23_deprecated __declspec(deprecated)
#else
#define c23_deprecated
#endif
/**
 * @def c23_fallthrough
 * @brief A compatibility macro for the C23 `[[fallthrough]]` attribute.
 *
 * @details This attribute is placed in a `switch` statement to explicitly indicate
 * that a `case` is intended to fall through to the next one. It suppresses
 * compiler warnings that would otherwise be generated for this pattern (e.g., `-Wimplicit-fallthrough`),
 * making the code's intent clearer.
 *
 * This macro expands to:
 * - `[[fallthrough]]` on compilers that support the C23 standard syntax.
 * - `__attribute__((fallthrough))` on GCC and Clang.
 * - Nothing on other compilers (including MSVC, which uses a different mechanism or lacks the warning).
 */
#if COMPAT_HAS_C_ATTRIBUTE(fallthrough)
#define c23_fallthrough [[fallthrough]]
#elif defined(__GNUC__) || defined(__clang__)
#define c23_fallthrough __attribute__((fallthrough))
#else
#define c23_fallthrough
#endif
/**
 * @def c23_maybe_unused
 * @brief A compatibility macro for the C23 `[[maybe_unused]]` attribute.
 *
 * @details This attribute suppresses compiler warnings about unused variables,
 * parameters, or functions. It is useful for parameters that are only used in
 * certain build configurations (e.g., in an `#ifdef DEBUG` block) or for
 * functions that are part of a public API but not used internally.
 *
 * This macro expands to:
 * - `[[maybe_unused]]` on compilers that support the C23 standard syntax.
 * - `__attribute__((unused))` on GCC and Clang.
 * - Nothing on other compilers.
 */
#if COMPAT_HAS_C_ATTRIBUTE(maybe_unused)
#define c23_maybe_unused [[maybe_unused]]
#elif defined(__GNUC__) || defined(__clang__)
#define c23_maybe_unused __attribute__((unused))
#else
#define c23_maybe_unused
#endif
/** @endinternal */
