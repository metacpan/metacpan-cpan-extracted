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
 * @file loader.c
 * @brief Implements cross-platform dynamic library loading.
 * @ingroup internal_core
 *
 * This module provides a platform-agnostic API for opening shared libraries
 * (`.dll`, `.so`, `.dylib`), looking up symbols within them, and reading or
 * writing to exported global variables. It abstracts away the differences
 * between the Windows API (`LoadLibrary`, `GetProcAddress`) and the POSIX API
 * (`dlopen`, `dlsym`).
 *
 * The functions `infix_read_global` and `infix_write_global` combine this dynamic
 * loading capability with the `infix` type system to safely interact with global
 * variables of any type described by a signature string.
 */
#include "common/infix_internals.h"
#if defined(INFIX_OS_WINDOWS)
#include <windows.h>
#else
#include <dlfcn.h>
#endif
/**
 * @brief Opens a dynamic library and returns a handle to it.
 *
 * This function is a cross-platform wrapper around `LoadLibraryA` (Windows) and
 * `dlopen` (POSIX). On failure, it sets the thread-local error state with
 * detailed system-specific information using `_infix_set_system_error`.
 *
 * @param[in] path The file path to the library (e.g., `"./mylib.so"`, `"user32.dll"`).
 * @return A pointer to an `infix_library_t` handle on success, or `nullptr` on failure.
 *         The returned handle must be freed with `infix_library_close`.
 */
INFIX_API INFIX_NODISCARD infix_library_t * infix_library_open(const char * path) {
    infix_library_t * lib = infix_calloc(1, sizeof(infix_library_t));
    if (lib == nullptr) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return nullptr;
    }
#if defined(INFIX_OS_WINDOWS)
    // On Windows, passing NULL to GetModuleHandleA returns a handle to the main executable file of the current process.
    if (path == nullptr) {
        lib->handle = GetModuleHandleA(path);
        lib->is_pseudo_handle = true;  // Mark this as a special, non-freeable handle.
    }
    else {
        lib->handle = LoadLibraryA(path);
        lib->is_pseudo_handle = false;  // This is a regular, ref-counted handle.
    }
#else
    // Use RTLD_LAZY for performance (resolve symbols only when they are first used).
    // Use RTLD_LOCAL to keep symbols isolated within this handle. This prevents
    // symbol pollution if multiple plugins link against different versions of the same
    // dependency. Dependencies must be explicitly linked or loaded.
    // Use RTLD_GLOBAL to make symbols from this library available for resolution
    // by other libraries that might be loaded later. This is important for complex
    // dependency chains.
    // On POSIX, passing NULL to dlopen returns a handle to the main executable.
    lib->handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL);
#endif
    if (lib->handle == nullptr) {
#if defined(INFIX_OS_WINDOWS)
        // On Windows, GetLastError() provides the specific error code.
        _infix_set_system_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_LIBRARY_LOAD_FAILED, GetLastError(), nullptr);
#else
        // On POSIX, dlerror() returns a human-readable string.
        _infix_set_system_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_LIBRARY_LOAD_FAILED, 0, dlerror());
#endif
        infix_free(lib);
        return nullptr;
    }
    return lib;
}
/**
 * @brief Closes a dynamic library handle and frees associated resources.
 *
 * This is a cross-platform wrapper around `FreeLibrary` (Windows) and `dlclose` (POSIX).
 *
 * @param[in] lib The library handle to close. It is safe to call this function with `nullptr`.
 */
INFIX_API void infix_library_close(infix_library_t * lib) {
    if (lib == nullptr)
        return;
    if (lib->handle) {
#if defined(INFIX_OS_WINDOWS)
        // Only call FreeLibrary on real handles obtained from LoadLibrary.
        // Never call it on a pseudo-handle from GetModuleHandle.
        if (!lib->is_pseudo_handle)
            FreeLibrary((HMODULE)lib->handle);
#else
        dlclose(lib->handle);
#endif
    }
    infix_free(lib);
}
/**
 * @brief Retrieves the address of a symbol (function or variable) from a loaded library.
 *
 * This is a cross-platform wrapper around `GetProcAddress` (Windows) and `dlsym` (POSIX).
 *
 * @note On POSIX, `dlsym` returning `NULL` is not a definitive error condition, as a
 *       symbol's address could itself be `NULL`. The official way to check for an
 *       error is to call `dlerror()` afterwards. This function does not perform
 *       that check and does not set the `infix` error state, as its primary callers
 *       (`infix_read_global`, etc.) will set a more specific `INFIX_CODE_SYMBOL_NOT_FOUND`
 *       error if the lookup fails.
 *
 * @param[in] lib The library handle.
 * @param[in] symbol_name The name of the symbol to look up (e.g., `"my_function"`).
 * @return A `void*` pointer to the symbol's address, or `nullptr` if not found.
 */
INFIX_API INFIX_NODISCARD void * infix_library_get_symbol(infix_library_t * lib, const char * symbol_name) {
    if (lib == nullptr || lib->handle == nullptr || symbol_name == nullptr)
        return nullptr;
#if defined(INFIX_OS_WINDOWS)
    return (void *)GetProcAddress((HMODULE)lib->handle, symbol_name);
#else
    return dlsym(lib->handle, symbol_name);
#endif
}
/**
 * @brief Reads the value of an exported global variable from a library into a buffer.
 *
 * This function first looks up the symbol's address. It then uses the `infix`
 * signature parser (`infix_type_from_signature`) to determine the size of the
 * variable. This ensures that the correct number of bytes are copied from the
 * library's data segment into the user's buffer, preventing buffer overflows.
 *
 * @param[in] lib The library handle.
 * @param[in] symbol_name The name of the global variable.
 * @param[in] type_signature The `infix` signature string describing the variable's type (e.g., `"int32"`,
 * `"{double,double}"`).
 * @param[out] buffer A pointer to the destination buffer to receive the data. This buffer must be large enough to hold
 * the type described by the signature.
 * @param[in] registry An optional registry for resolving named types in the signature.
 * @return `INFIX_SUCCESS` on success, or an error code on failure (e.g., symbol not found, invalid signature).
 */
INFIX_API INFIX_NODISCARD infix_status infix_read_global(infix_library_t * lib,
                                                         const char * symbol_name,
                                                         const char * type_signature,
                                                         void * buffer,
                                                         infix_registry_t * registry) {
    if (buffer == nullptr)
        return INFIX_ERROR_INVALID_ARGUMENT;
    void * symbol_addr = infix_library_get_symbol(lib, symbol_name);
    if (symbol_addr == nullptr) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_SYMBOL_NOT_FOUND, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    // Parse the signature to get the type's size.
    infix_type * type = nullptr;
    infix_arena_t * arena = nullptr;
    infix_status status = infix_type_from_signature(&type, &arena, type_signature, registry);
    if (status != INFIX_SUCCESS)
        return status;
    // Safely copy the data using the parsed size.
    infix_memcpy(buffer, symbol_addr, type->size);
    infix_arena_destroy(arena);
    return INFIX_SUCCESS;
}
/**
 * @brief Writes data from a buffer into an exported global variable in a library.
 *
 * @details This function is analogous to `infix_read_global`. It finds the symbol's
 * address and uses the signature string to determine the correct number of bytes
 * to copy from the source buffer to the library's memory.
 *
 * @note This operation assumes that the memory page containing the global variable
 *       is writable. This is typical for `.data` or `.bss` segments but may fail
 *       if the variable is in a read-only segment (e.g., a `const` global). The
 *       function does not attempt to change memory permissions.
 *
 * @param[in] lib The library handle.
 * @param[in] symbol_name The name of the global variable.
 * @param[in] type_signature The `infix` signature string describing the variable's type.
 * @param[in] buffer A pointer to the source buffer containing the data to write.
 * @param[in] registry An optional registry for resolving named types in the signature.
 * @return `INFIX_SUCCESS` on success, or an error code on failure.
 */
INFIX_API INFIX_NODISCARD infix_status infix_write_global(infix_library_t * lib,
                                                          const char * symbol_name,
                                                          const char * type_signature,
                                                          void * buffer,
                                                          infix_registry_t * registry) {
    if (buffer == nullptr)
        return INFIX_ERROR_INVALID_ARGUMENT;
    void * symbol_addr = infix_library_get_symbol(lib, symbol_name);
    if (symbol_addr == nullptr) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_SYMBOL_NOT_FOUND, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    infix_type * type = nullptr;
    infix_arena_t * arena = nullptr;
    infix_status status = infix_type_from_signature(&type, &arena, type_signature, registry);
    if (status != INFIX_SUCCESS)
        return status;
    // Note: This assumes the memory page containing the global is writable.
    // This is standard for data segments but could fail in unusual cases.
    infix_memcpy(symbol_addr, buffer, type->size);
    infix_arena_destroy(arena);
    return INFIX_SUCCESS;
}
