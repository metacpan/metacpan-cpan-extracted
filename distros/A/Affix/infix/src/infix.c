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
 * @file infix.c
 * @brief The unity build source file for the infix library.
 * @ingroup internal_core
 *
 * @internal
 * This file acts as the single translation unit for the entire infix library. It
 * includes all other necessary C source files in a specific order to resolve
 * dependencies and create the final library object.
 *
 * @section build_strategy Build Strategy
 *
 * Using a unity build (also known as a jumbo build) offers several advantages for
 * a library of this nature:
 * - **Simplified Build Process:** It eliminates the need for a complex build system
 *   to manage dependencies between multiple object files. The entire library can
 *   be compiled with a single command (e.g., `cc -o libinfix.so infix.c ...`).
 * - **Improved Optimization:** Compilers can perform more aggressive cross-file
 *   optimizations, such as inlining functions defined in different `.c` files,
 *   potentially improving performance.
 * - **Reduced Build Times:** For smaller to medium-sized projects, a unity build
 *   can be faster as it reduces the overhead of opening and closing files and
 *   parsing headers multiple times.
 *
 * @section inclusion_order Inclusion Order
 *
 * The order of inclusion is critical to respect dependencies between modules. The
 * files are ordered from the most foundational components (like error handling and
 * memory allocation) to the highest-level ones (like the JIT engine). The final
 * `trampoline.c` file itself includes the platform- and architecture-specific
 * ABI files, completing the build.
 *
 * @note This file is not intended to be compiled on its own without the
 * rest of the source tree. It is the entry point for the build system.
 * @endinternal
 */
// 1. Error Handling: Provides the thread-local error reporting system.
//    (No dependencies on other infix modules).
#include "core/error.c"
// 2. Arena Allocator: The fundamental memory management component.
//    (Depends only on malloc/free).
#include "core/arena.c"
// 3. OS Executor: Handles OS-level memory management for executable code.
//    (Depends on error handling, debugging utilities).
#include "jit/executor.c"
// 4. Type Registry: Manages named types.
//    (Depends on arena for storage and signature parser for definitions).
#include "core/type_registry.c"
// 5. Signature Parser: Implements the high-level string-based API.
//    (Depends on types, arena, and registry).
#include "core/signature.c"
// 6. Dynamic Library Loader: Implements cross-platform `dlopen`/`dlsym`.
//    (Depends on error handling, types, and arena).
#include "core/loader.c"
// 7. Type System: Defines and manages `infix_type` objects and graph algorithms.
//    (Depends on the arena and error handling).
#include "core/types.c"
// 8. Debugging Utilities: Low-level helpers for logging and inspection.
//    (No dependencies).
#include "core/utility.c"
// 9. Platform and processor feature detection.
//    (No dependencies).
#include "core/platform.c"
// 10. Trampoline Engine: The central JIT compiler.
//    This must be last, as it depends on all other components and includes the
//    final ABI- and architecture-specific C files itself.
#include "jit/trampoline.c"
