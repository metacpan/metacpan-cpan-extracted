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
 * @file infix_config.h
 * @brief Platform, architecture, and ABI detection macros.
 * @ingroup internal_common
 *
 * @details This header is the first to be included by `infix_internals.h` and is
 * responsible for defining a consistent set of `INFIX_*` macros that describe the
 * build environment. It is the central point of configuration for the entire library,
 * adapting the build to different operating systems, compilers, and CPU architectures.
 *
 * Its most critical function is to select the correct **Application Binary Interface (ABI)**
 * implementation to use for JIT code generation. This is achieved through a cascade
 * of preprocessor checks that can be overridden by the user for cross-compilation.
 * By the end of this file, exactly one `INFIX_ABI_*` macro must be defined, which
 * determines which `abi_*.c` file is included in the unity build.
 *
 * @internal
 */
#pragma once
// System Feature Test Macros
/**
 * @details These macros are defined to ensure that standard POSIX and other
 * necessary function declarations (like `dlopen`, `dlsym`, `snprintf`, `shm_open`)
 * are made available by system headers in a portable way across different C
 * library implementations (glibc, musl, BSD libc, etc.). Failing to define these
 * can lead to compilation failures due to implicitly declared functions on
 * stricter build environments.
 */
#if !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L
#endif
#if (defined(__linux__) || defined(__gnu_linux__)) && !defined(_GNU_SOURCE)
#define _GNU_SOURCE
#endif
// Operating System Detection
/**
 * @details This section defines `INFIX_OS_*` macros based on compiler-provided
 * preprocessor definitions. It also defines the broader `INFIX_ENV_POSIX` for systems
 * that follow POSIX conventions, which simplifies later `#ifdef` logic.
 */
#if defined(_WIN32)
#define INFIX_OS_WINDOWS
#include <windows.h>  // Included early for common types like SYSTEM_INFO, HANDLE, etc.
// Compatibility shim for POSIX types not present in Clang/MSVC headers.
#if !defined(__CYGWIN__)  // Cygwin provides its own full POSIX environment
#include <stddef.h>       // For ptrdiff_t
#ifndef ssize_t
// Define ssize_t as ptrdiff_t, the standard signed counterpart to size_t.
typedef ptrdiff_t ssize_t;
#endif
#endif
#if defined(__MSYS__)
#define INFIX_ENV_MSYS 1
#elif defined(__CYGWIN__)
#define INFIX_ENV_CYGWIN 1
#define INFIX_ENV_POSIX 1
#elif defined(__MINGW32__) || defined(__MINGW64__)
#define INFIX_ENV_MINGW 1
#endif
#elif defined(__TERMUX__)
#define INFIX_OS_TERMUX
#define INFIX_OS_ANDROID
#define INFIX_OS_LINUX
#define INFIX_ENV_POSIX
#define INFIX_ENV_TERMUX 1
#elif defined(__ANDROID__)
#define INFIX_OS_ANDROID
#define INFIX_OS_LINUX
#define INFIX_ENV_POSIX
#elif defined(__APPLE__)
#define INFIX_ENV_POSIX
#define _DARWIN_C_SOURCE
#include <TargetConditionals.h>
#include <libkern/OSCacheControl.h>
#include <pthread.h>
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#define INFIX_OS_IOS
#elif TARGET_OS_MAC
#define INFIX_OS_MACOS
#else
#error "Unsupported/unknown Apple platform"
#endif
#elif defined(__linux__)
#define INFIX_OS_LINUX
#define INFIX_ENV_POSIX
#elif defined(__FreeBSD__)
#define INFIX_OS_FREEBSD
#define INFIX_ENV_POSIX
#elif defined(__OpenBSD__)
#define INFIX_OS_OPENBSD
#define INFIX_ENV_POSIX
#elif defined(__NetBSD__)
#define INFIX_OS_NETBSD
#define INFIX_ENV_POSIX
#elif defined(__DragonFly__)
#define INFIX_OS_DRAGONFLY
#define INFIX_ENV_POSIX
#elif defined(__sun) && defined(__SVR4)
#define INFIX_OS_SOLARIS
#define INFIX_ENV_POSIX
#elif defined(__HAIKU__)
#define INFIX_OS_HAIKU
#define INFIX_ENV_POSIX
#else
#warning "Unsupported/unknown operating system"
#endif
// Compiler Detection
/**
 * @details Defines `INFIX_COMPILER_*` macros. The order is important, as Clang
 * often defines `__GNUC__` for compatibility, so it must be checked for first.
 */
#if defined(__clang__)
#define INFIX_COMPILER_CLANG
#elif defined(_MSC_VER)
#define INFIX_COMPILER_MSVC
#elif defined(__GNUC__)
#define INFIX_COMPILER_GCC
#else
#warning "Compiler: Unknown compiler detected."
#define INFIX_COMPILER_NFI
#endif
// CPU Architecture Detection
/**
 * @details Defines `INFIX_ARCH_*` for the two currently supported architectures.
 * The library will fail to compile if the architecture is not one of these, as
 * the JIT code emitters are architecture-specific.
 */
#if defined(__aarch64__) || defined(_M_ARM64)
#define INFIX_ARCH_AARCH64
#elif defined(__x86_64__) || defined(_M_X64)
#define INFIX_ARCH_X64
#else
#error "Unsupported architecture. Only x86-64 and AArch64 are currently supported."
#endif
// Target ABI Logic Selection
/**
 * @details This is the most critical section of the configuration. It determines
 * which ABI implementation will be compiled and used by the JIT engine.
 *
 * It supports two modes:
 * 1.  **Forced ABI:** A user can define `INFIX_FORCE_ABI_*` (e.g., via a compiler
 *     flag like `-DINFIX_FORCE_ABI_SYSV_X64`) to override automatic detection.
 *     This is essential for cross-compilation, where the host compiler's macros
 *     would not reflect the target environment.
 *
 * 2.  **Automatic Detection:** If no ABI is forced, it uses the `INFIX_ARCH_*` and
 *     `INFIX_OS_*` macros to deduce the correct ABI for the current build target.
 */
#if defined(INFIX_FORCE_ABI_WINDOWS_X64)
#define INFIX_ABI_WINDOWS_X64 1
#define INFIX_ABI_FORCED 1
#elif defined(INFIX_FORCE_ABI_SYSV_X64)
#define INFIX_ABI_SYSV_X64 1
#define INFIX_ABI_FORCED 1
#elif defined(INFIX_FORCE_ABI_AAPCS64)
#define INFIX_ABI_AAPCS64 1
#define INFIX_ABI_FORCED 1
#endif
// Automatic ABI detection if not forced by the user.
#ifndef INFIX_ABI_FORCED
#if defined(INFIX_ARCH_AARCH64)
// All AArch64 platforms (Linux, macOS, Windows) use the same base calling
// convention (AAPCS64), although with minor differences for variadic arguments
// that are handled within the `abi_arm64.c` implementation.
#define INFIX_ABI_AAPCS64
#elif defined(INFIX_ARCH_X64)
#if defined(INFIX_OS_WINDOWS)
// Windows on x86-64 uses the Microsoft x64 calling convention.
#define INFIX_ABI_WINDOWS_X64
#else
// All other x86-64 platforms (Linux, macOS, BSDs, etc.) use the System V AMD64 ABI.
#define INFIX_ABI_SYSV_X64
#endif
#endif
#endif  // INFIX_ABI_FORCED
// Miscellaneous Constants
/**
 * @def INFIX_TRAMPOLINE_HEADROOM
 * @brief Extra bytes to allocate in a trampoline's private arena.
 *
 * @details When a trampoline handle is created, it deep-copies all type information
 * from a source (like the parser's temporary arena) into its own private arena.
 * The size of the source arena is used as a hint for the new arena's size, but the
 * copy process itself requires a small amount of extra memory for its own bookkeeping
 * (e.g., the memoization list in `_copy_type_graph_to_arena_recursive`). This
 * headroom provides that extra space to prevent allocation failures during the copy.
 */
#define INFIX_TRAMPOLINE_HEADROOM 128

/**
 * @def INFIX_INTERNAL
 * @brief When compiling with -fvisibility=hidden, we use this to explicitly mark internal-but-shared functions as
 * hidden.
 */
#if (defined(__GNUC__) || defined(__clang__)) && !defined(_WIN32) && !defined(__CYGWIN__)
#define INFIX_INTERNAL __attribute__((visibility("hidden")))
#else
#define INFIX_INTERNAL
#endif

/** @endinternal */
