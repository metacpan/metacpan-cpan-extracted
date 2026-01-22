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
 * @file infix.h
 * @brief The public interface for the infix FFI library.
 *
 * @mainpage infix FFI Library
 *
 * @section intro_sec Introduction
 *
 * `infix` is a powerful, modern, and lightweight C library for creating Foreign
 * Function Interface (FFI) trampolines at runtime. It allows you to dynamically
 * call C functions or create C callbacks from any language or environment, using
 * a simple, human-readable string-based syntax to describe function signatures.
 *
 * @section features_sec Key Features
 *
 * - **Simple Signature Syntax:** Describe complex C types, structs, and function
 *   prototypes with an intuitive string format.
 * - **Forward & Reverse Calls:** Create "forward" trampolines to call C from your
 *   code, and "reverse" trampolines (callbacks) to allow C to call back into your code.
 * - **Named Type Registry:** Define, reuse, and link complex, recursive, and
 *   mutually-dependent structs by name.
 * - **Cross-Platform:** Supports major architectures (x86-64, AArch64) and operating
 *   systems (Linux, macOS, Windows).
 * - **Secure:** Designed with modern security principles like W^X (Write XOR Execute)
 *   and hardened against memory corruption.
 * - **Lightweight & Embeddable:** A small, dependency-free library ideal for
 *   embedding in language runtimes, plugins, and other applications.
 *
 * @section usage_sec Basic Usage
 *
 * ```c
 * #include <infix/infix.h>
 * #include <stdio.h>
 *
 * // The C function we want to call.
 * int add(int a, int b) { return a + b; }
 *
 * int main() {
 *     infix_forward_t* trampoline = NULL;
 *     const char* signature = "(int, int) -> int";
 *
 *     // Create a "bound" trampoline JIT-compiled for the `add` function.
 *     infix_forward_create(&trampoline, signature, (void*)add, NULL);
 *
 *     // Get the callable function pointer from the trampoline.
 *     infix_cif_func cif = infix_forward_get_code(trampoline);
 *
 *     // Prepare arguments as an array of pointers.
 *     int a = 10, b = 32;
 *     void* args[] = { &a, &b };
 *     int result;
 *
 *     // Call the function through the FFI interface.
 *     cif(&result, args);
 *
 *     printf("Result: %d\n", result); // Output: Result: 42
 *
 *     infix_forward_destroy(trampoline);
 *     return 0;
 * }
 * ```
 */
#pragma once
/**
 * @defgroup version_info Version Information
 * @brief Macros defining the semantic version of the infix library.
 * @details The versioning scheme follows Semantic Versioning 2.0.0 (SemVer).
 * @{
 */
#define INFIX_MAJOR 0 /**< The major version number. Changes with incompatible API updates. */
#define INFIX_MINOR 1 /**< The minor version number. Changes with new, backward-compatible features. */
#define INFIX_PATCH 4 /**< The patch version number. Changes with backward-compatible bug fixes. */

#if defined(__has_c_attribute)
#define _INFIX_HAS_C_ATTRIBUTE(x) __has_c_attribute(x)
#else
#define _INFIX_HAS_C_ATTRIBUTE(x) 0
#endif

/**
 * @def INFIX_API
 * @brief Symbol visibility macro
 *
 * @details infix relies on a unity build so we've been lax about symbol visibility. Functions like `_infix_set_error`
 * or `_infix_type_recalculate_layout` are shared between internal modules (files included by `infix.c`) and thus cannot
 * be static. However, this means that if infix.c is compiled into a shared library (`libinfix.so`), all of these
 * internal _infix_* functions are exported in the dynamic symbol table. This pollutes the ABI and allows users to link
 * against internal functions that might change.
 */
#if defined(_WIN32) || defined(__CYGWIN__)
#if defined(INFIX_BUILDING_DLL)
#define INFIX_API __declspec(dllexport)
#elif defined(INFIX_USING_DLL)
#define INFIX_API __declspec(dllimport)
#else
#define INFIX_API
#endif
#elif defined(__GNUC__) || defined(__clang__)
#define INFIX_API __attribute__((visibility("default")))
#else
#define INFIX_API
#endif

/**
 * @def INFIX_NODISCARD
 * @brief A compatibility macro for the C23 `[[nodiscard]]` attribute.
 *
 * @details This attribute is used to issue a compiler warning if the return value
 * of a function is ignored by the caller. This is extremely useful for catching
 * bugs where an error code or an important result is not checked.
 *
 * This macro expands to:
 * - `[[nodiscard]]` on compilers that support the C23 standard syntax.
 * - `__attribute__((warn_unused_result))` on GCC and Clang.
 * - `_Check_return_` on Microsoft Visual C++.
 * - Nothing on other compilers.
 *
 * This is aliased as `c23_nodiscard` in `compat_c23.h`.
 */
#if _INFIX_HAS_C_ATTRIBUTE(nodiscard) && !defined(__GNUC__) && !defined(__clang__)
#define INFIX_NODISCARD [[nodiscard]]
#elif defined(__GNUC__) || defined(__clang__)
#define INFIX_NODISCARD __attribute__((warn_unused_result))
#elif defined(_MSC_VER)
#define INFIX_NODISCARD _Check_return_
#else
#define INFIX_NODISCARD
#endif

/**
 * @struct infix_version_t
 * @brief A structure representing the semantic version of the library.
 * @see infix_get_version
 */
typedef struct {
    int major; /**< The major version number (incremented for incompatible API changes). */
    int minor; /**< The minor version number (incremented for backwards-compatible features). */
    int patch; /**< The patch version number (incremented for backwards-compatible bug fixes). */
} infix_version_t;

/** @} */
// Define the POSIX source macro to ensure function declarations for shm_open,
// ftruncate, etc., are visible on all POSIX-compliant systems.
// This must be defined before any system headers are included.
#ifndef _DEFAULT_SOURCE
#define _DEFAULT_SOURCE
#endif
// Define the POSIX source macro to ensure function declarations for posix_memalign
// are visible. This must be defined before any system headers are included.
#if !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L
#endif
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Retrieves the version of the infix library linked at runtime.
 *
 * @details This function allows applications to verify that the version of the
 *          library they are linked against matches the headers they were compiled with.
 *          This is particularly useful when loading `infix` as a shared library/DLL
 *          to detect version mismatches.
 *
 * @return An `infix_version_t` structure containing the major, minor, and patch numbers.
 */
INFIX_API INFIX_NODISCARD infix_version_t infix_get_version(void);

/**
 * @defgroup high_level_api High-Level Signature API
 * @brief The primary, recommended API for creating trampolines from human-readable strings.
 *
 * This API provides the simplest and most powerful way to interact with `infix`.
 * All functions in this group take a signature string and an optional type registry
 * to parse and generate the required FFI trampolines.
 * @{
 */
/**
 * @defgroup type_system Type System
 * @brief The core data structures and APIs for describing C types and function signatures.
 *
 * `infix` uses a powerful, introspectable type system to represent C types. These
 * structures can be created programmatically using the Manual API or parsed from
 * human-readable signature strings.
 *
 * @{
 */
// Opaque and Semi-Opaque Type Forward Declarations
/** @brief A semi-opaque object describing a C type's memory layout and calling convention. See `infix_type_t` for
 * details. */
typedef struct infix_type_t infix_type;
/** @brief A semi-opaque object describing a member of a C struct or union. See `infix_struct_member_t` for details. */
typedef struct infix_struct_member_t infix_struct_member;
/** @brief A semi-opaque object describing an argument to a C function. See `infix_function_argument_t` for details. */
typedef struct infix_function_argument_t infix_function_argument;
/** @brief An opaque handle to a forward (C-to-native) trampoline. Created by `infix_forward_create` and variants. */
typedef struct infix_forward_t infix_forward_t;
/** @brief An opaque handle to a reverse (native-to-C) trampoline, also known as a callback or closure. */
typedef struct infix_reverse_t infix_reverse_t;
/** @brief An alias for `infix_reverse_t`, used to clarify its role as a context object in closure handlers. */
typedef infix_reverse_t infix_context_t;
/** @brief An opaque handle to an arena allocator, used for efficient grouped memory allocations. */
typedef struct infix_arena_t infix_arena_t;
/** @brief An opaque handle to a dynamically loaded shared library (`.so`, `.dll`, `.dylib`). */
typedef struct infix_library_t infix_library_t;
/** @brief An opaque handle to a named type registry. */
typedef struct infix_registry_t infix_registry_t;
/**
 * @brief Enumerates the fundamental categories of types that `infix` can represent.
 */
typedef enum {
    INFIX_TYPE_PRIMITIVE,          /**< A fundamental C type like `int`, `float`, or `double`. */
    INFIX_TYPE_POINTER,            /**< A pointer to another `infix_type`. */
    INFIX_TYPE_STRUCT,             /**< A C `struct`. */
    INFIX_TYPE_UNION,              /**< A C `union`. */
    INFIX_TYPE_ARRAY,              /**< A fixed-size C array. */
    INFIX_TYPE_REVERSE_TRAMPOLINE, /**< A function pointer type, used internally by the signature parser. */
    INFIX_TYPE_ENUM,               /**< A C `enum`, represented by its underlying integer type. */
    INFIX_TYPE_COMPLEX,            /**< A C99 `_Complex` number. */
    INFIX_TYPE_VECTOR,             /**< A SIMD vector type. */
    INFIX_TYPE_NAMED_REFERENCE,    /**< A placeholder for a named type to be resolved by a registry. */
    INFIX_TYPE_VOID                /**< The `void` type, valid only as a function return type. */
} infix_type_category;
/**
 * @brief Enumerates the supported primitive C types.
 */
typedef enum {
    INFIX_PRIMITIVE_BOOL,       /**< `bool` or `_Bool`. */
    INFIX_PRIMITIVE_UINT8,      /**< `uint8_t`. */
    INFIX_PRIMITIVE_SINT8,      /**< `int8_t`. */
    INFIX_PRIMITIVE_UINT16,     /**< `uint16_t`. */
    INFIX_PRIMITIVE_SINT16,     /**< `int16_t`. */
    INFIX_PRIMITIVE_UINT32,     /**< `uint32_t`. */
    INFIX_PRIMITIVE_SINT32,     /**< `int32_t`. */
    INFIX_PRIMITIVE_UINT64,     /**< `uint64_t`. */
    INFIX_PRIMITIVE_SINT64,     /**< `int64_t`. */
    INFIX_PRIMITIVE_UINT128,    /**< `__uint128_t` (GCC/Clang extension). */
    INFIX_PRIMITIVE_SINT128,    /**< `__int128_t` (GCC/Clang extension). */
    INFIX_PRIMITIVE_FLOAT,      /**< `float`. */
    INFIX_PRIMITIVE_DOUBLE,     /**< `double`. */
    INFIX_PRIMITIVE_LONG_DOUBLE /**< `long double`. */
} infix_primitive_type_id;
/**
 * @brief Specifies whether a named type reference refers to a struct or a union.
 * @internal This is used by the parser to correctly create aggregate types from a registry.
 */
typedef enum { INFIX_AGGREGATE_STRUCT, INFIX_AGGREGATE_UNION } infix_aggregate_category_t;
/**
 * @struct infix_type_t
 * @brief A semi-opaque structure that describes a C type.
 *
 * This structure contains all necessary metadata to determine a type's size,
 * alignment, and ABI handling. While its fields are accessible for introspection,
 * it should only be created via the provided API functions (e.g.,
 * `infix_type_create_primitive`, `infix_type_from_signature`).
 */
struct infix_type_t {
    const char * name;            /**< The semantic alias of the type (e.g., "MyInt"), or `nullptr` if anonymous. */
    infix_type_category category; /**< The fundamental category of the type. */
    size_t size;                  /**< The size of the type in bytes. */
    size_t alignment;             /**< The alignment requirement of the type in bytes. */
    bool is_arena_allocated;      /**< True if this type object lives in an arena and must be freed with it. */
    bool is_incomplete;           /**< True if this is a forward declaration that has not yet been defined. */
    infix_arena_t * arena;        /**< A pointer to the arena that owns this type object, or nullptr if static. */
    size_t source_offset;         /**< The byte offset in the source signature where this type was defined. */
    /** @brief A union containing metadata specific to the type's category. */
    union {
        /** @brief Metadata for `INFIX_TYPE_PRIMITIVE`. */
        infix_primitive_type_id primitive_id;
        /** @brief Metadata for `INFIX_TYPE_POINTER`. */
        struct {
            struct infix_type_t * pointee_type; /**< The type that this pointer points to. */
        } pointer_info;
        /** @brief Metadata for `INFIX_TYPE_STRUCT` and `INFIX_TYPE_UNION`. */
        struct {
            infix_struct_member * members; /**< An array of the aggregate's members. */
            size_t num_members;            /**< The number of members in the array. */
            bool is_packed;                /**< True if the struct is packed (!{...}). */
        } aggregate_info;
        /** @brief Metadata for `INFIX_TYPE_ARRAY`. */
        struct {
            struct infix_type_t * element_type; /**< The type of each element in the array. */
            size_t num_elements;                /**< The number of elements in the array. */
            bool is_flexible;                   /**< Indicates this is a flexible array member */
        } array_info;
        /** @brief Metadata for `INFIX_TYPE_REVERSE_TRAMPOLINE`. */
        struct {
            struct infix_type_t * return_type; /**< The return type of the function. */
            infix_function_argument * args;    /**< An array of the function's arguments. */
            size_t num_args;                   /**< The total number of arguments. */
            size_t num_fixed_args;             /**< The number of non-variadic arguments. */
        } func_ptr_info;
        /** @brief Metadata for `INFIX_TYPE_ENUM`. */
        struct {
            struct infix_type_t * underlying_type; /**< The underlying integer type of the enum. */
        } enum_info;
        /** @brief Metadata for `INFIX_TYPE_COMPLEX`. */
        struct {
            struct infix_type_t * base_type; /**< The base floating-point type (`float` or `double`). */
        } complex_info;
        /** @brief Metadata for `INFIX_TYPE_VECTOR`. */
        struct {
            struct infix_type_t * element_type; /**< The primitive type of each element in the vector. */
            size_t num_elements;                /**< The number of elements in the vector. */
        } vector_info;
        /** @brief Metadata for `INFIX_TYPE_NAMED_REFERENCE`. */
        struct {
            const char * name;                             /**< The name to be looked up in a registry. */
            infix_aggregate_category_t aggregate_category; /**< The expected kind of aggregate (struct or union). */
        } named_reference;
    } meta;
};
/**
 * @struct infix_struct_member_t
 * @brief Describes a single member of a C struct or union.
 */
struct infix_struct_member_t {
    const char * name;  /**< The name of the member, or `nullptr` if anonymous. */
    infix_type * type;  /**< The `infix_type` of the member. */
    size_t offset;      /**< The byte offset of the member from the start of the aggregate. */
    uint8_t bit_width;  /**< The width of the bitfield in bits. 0 for standard members. */
    uint8_t bit_offset; /**< The bit offset within the byte (0-7). */
    bool is_bitfield;   /**< True if this member is a bitfield (even if width is 0). */
};
/**
 * @struct infix_function_argument_t
 * @brief Describes a single argument to a C function.
 */
struct infix_function_argument_t {
    const char * name; /**< The name of the argument, or `nullptr` if anonymous. */
    infix_type * type; /**< The `infix_type` of the argument. */
};
/** @} */  // end of type_system group
/**
 * @defgroup memory_management Memory Management
 * @brief APIs for memory management, including custom allocators and arenas.
 * @{
 */
/**
 * @def infix_malloc
 * @brief A macro that can be defined to override the default `malloc` function.
 * @details If you need to integrate `infix` with a custom memory allocator (e.g., for
 *          memory tracking or garbage collection), define this macro **before**
 *          including `infix.h`. You must also define the other `infix_*` memory macros.
 * @code
 * #define infix_malloc my_custom_malloc
 * #define infix_calloc my_custom_calloc
 * #define infix_free my_custom_free
 * #define infix_realloc my_custom_realloc
 * #include <infix/infix.h>
 * @endcode
 */
#ifndef infix_malloc
#define infix_malloc malloc
#endif
/** @brief A macro that can be defined to override the default `calloc` function. */
#ifndef infix_calloc
#define infix_calloc calloc
#endif
/** @brief A macro that can be defined to override the default `realloc` function. */
#ifndef infix_realloc
#define infix_realloc realloc
#endif
/** @brief A macro that can be defined to override the default `free` function. */
#ifndef infix_free
#define infix_free free
#endif
/** @brief A macro that can be defined to override the default `memcpy` function. */
#ifndef infix_memcpy
#define infix_memcpy memcpy
#endif
/** @brief A macro that can be defined to override the default `memset` function. */
#ifndef infix_memset
#define infix_memset memset
#endif
/** @} */  // end of memory_management group
/**
 * @addtogroup high_level_api
 * @{
 */
/**
 * @brief A function pointer type for an unbound forward trampoline.
 * @details This is the callable code generated by `infix_forward_create_unbound`. It takes the
 * target function as its first argument, allowing it to be reused for any C
 * function that matches the signature it was created with.
 *
 * @param target_function The native C function to call.
 * @param return_value_ptr A pointer to a buffer to receive the return value. Can be `nullptr` if the return type is
 * `void`.
 * @param args_array An array of pointers, where each element points to an argument's value.
 */
typedef void (*infix_unbound_cif_func)(void *, void *, void **);
/**
 * @brief A function pointer type for a bound forward trampoline.
 * @details This is the callable code generated by `infix_forward_create`. The target
 * C function is "bound" into the JIT-compiled code, offering higher performance.
 *
 * @param return_value_ptr A pointer to a buffer to receive the return value. Can be `nullptr` for `void` returns.
 * @param args_array An array of pointers, where each element points to an argument's value.
 */
typedef void (*infix_cif_func)(void *, void **);
/**
 * @brief A function pointer type for a generic closure handler.
 *
 * This handler is used with `infix_reverse_create_closure` and is ideal for language
 * bindings or stateful callbacks where the handler needs access to user-provided data.
 *
 * @param context The reverse trampoline context, from which `user_data` can be retrieved via
 * `infix_reverse_get_user_data`.
 * @param return_value_ptr A pointer to a buffer where the handler must write the function's return value.
 * @param args_array An array of pointers to the argument values passed by the native C caller.
 */
typedef void (*infix_closure_handler_fn)(infix_context_t *, void *, void **);
/**
 * @brief Enumerates the possible status codes returned by `infix` API functions.
 */
typedef enum {
    INFIX_SUCCESS = 0,             /**< The operation completed successfully. */
    INFIX_ERROR_ALLOCATION_FAILED, /**< A memory allocation failed. Check `infix_get_last_error` for details. */
    INFIX_ERROR_INVALID_ARGUMENT,  /**< An invalid argument was provided. Check `infix_get_last_error`. */
    INFIX_ERROR_UNSUPPORTED_ABI,   /**< The current platform's ABI is not supported. */
    INFIX_ERROR_LAYOUT_FAILED,     /**< Failed to calculate a valid memory layout for a type. */
    INFIX_ERROR_PROTECTION_FAILED, /**< Failed to set memory protection flags (e.g., for W^X). */
    INFIX_ERROR_                   /**< Placeholder to ensure enum is sized correctly. */
} infix_status;
/**
 * @defgroup registry_api Named Type Registry
 * @brief APIs for defining, storing, and reusing complex types by name.
 * @ingroup high_level_api
 * @{
 */
/**
 * @brief Creates a new, empty named type registry.
 *
 * A registry acts as a dictionary for `infix` types, allowing you to define complex
 * structs, unions, or aliases once and refer to them by name (e.g., `@MyStruct`)
 * in any signature string. This is essential for managing complex, recursive, or
 * mutually-dependent types.
 *
 * @return A pointer to the new registry, or `nullptr` on allocation failure. The returned
 *         handle must be freed with `infix_registry_destroy`.
 */
INFIX_API INFIX_NODISCARD infix_registry_t * infix_registry_create(void);
/**
 * @brief Creates a deep copy of an existing type registry.
 *
 * This copies all defined types and their dependency graphs into a new registry with its own arena.
 * This is essential for thread safety in languages that spawn threads by cloning interpreter state (like Perl).
 *
 * @param[in] registry The registry to clone.
 * @return A pointer to the new registry, or `nullptr` on failure.
 */
INFIX_API INFIX_NODISCARD infix_registry_t * infix_registry_clone(const infix_registry_t *);
/**
 * @brief Destroys a type registry and frees all associated memory.
 *
 * This includes freeing the registry handle itself, its internal hash table, and
 * all `infix_type` objects that were created as part of a definition.
 *
 * @param[in] registry The registry to destroy. Safe to call with `nullptr`.
 */
INFIX_API void infix_registry_destroy(infix_registry_t *);
/**
 * @brief Parses a string of type definitions and adds them to a registry.
 *
 * This is the primary way to populate a registry. Definitions are separated by
 * semicolons. The parser supports forward declarations (`@Name;`) and out-of-order
 * definitions, making it easy to define mutually recursive types.
 *
 * @param[in] registry The registry to populate.
 * @param[in] definitions A semicolon-separated string of definitions.
 * @return `INFIX_SUCCESS` on success, or an error code on failure.
 * @code
 * const char* my_types =
 *     "@Point = { x: double, y: double };"    // Define a struct
 *     "@Node;"                                // Forward-declare Node
 *     "@List = { head: *@Node };"             // Use the forward declaration
 *     "@Node = { value: int, next: *@Node };" // Define the recursive struct
 * ;
 * infix_register_types(registry, my_types);
 * @endcode
 */
INFIX_API INFIX_NODISCARD infix_status infix_register_types(infix_registry_t *, const char *);
/** @} */  // end of registry_api group
/**
 * @defgroup registry_introspection_api Registry Introspection API
 * @brief APIs for inspecting and serializing the contents of a named type registry.
 * @ingroup high_level_api
 * @{
 */
/**
 * @struct infix_registry_iterator_t
 * @brief An iterator for traversing a type registry.
 * @details This struct holds the complete state needed to traverse the registry's
 * internal hash table, including the current bucket and the current entry within
 * that bucket's linked list.
 *
 * The fields in this struct are implementation details and should not be accessed directly.
 */
typedef struct infix_registry_iterator_t {
    const infix_registry_t * registry; /**< The registry being iterated. */
    size_t _bucket_index;              /**< Internal: current hash bucket. */
    void * _current_entry;             /**< Internal: opaque pointer to current entry. */
} infix_registry_iterator_t;
/**
 * @brief Serializes all defined types within a registry into a single, human-readable string.
 *
 * The output format is a sequence of definitions (e.g., `@Name = { ... };`) separated
 * by newlines, suitable for logging, debugging, or saving to a file. This function
 * will not print forward declarations that have not been fully defined.
 *
 * @param[out] buffer The output buffer to write the string into.
 * @param[in] buffer_size The size of the output buffer.
 * @param[in] registry The registry to serialize.
 * @return `INFIX_SUCCESS` on success, or `INFIX_ERROR_INVALID_ARGUMENT` if the buffer is too small.
 */
INFIX_API INFIX_NODISCARD infix_status infix_registry_print(char *, size_t, const infix_registry_t *);
/**
 * @brief Initializes an iterator for traversing the types in a registry.
 *
 * @param[in] registry The registry to iterate over.
 * @return An initialized iterator. If the registry is empty, the first call to
 *         `infix_registry_iterator_next` on this iterator will return `false`.
 */
INFIX_API INFIX_NODISCARD infix_registry_iterator_t infix_registry_iterator_begin(const infix_registry_t *);
/**
 * @brief Advances the iterator to the next defined type in the registry.
 *
 * @param[in,out] iterator The iterator to advance.
 * @return `true` if the iterator was advanced to a valid type, or `false` if there are no more types.
 */
INFIX_API INFIX_NODISCARD bool infix_registry_iterator_next(infix_registry_iterator_t *);
/**
 * @brief Gets the name of the type at the iterator's current position.
 *
 * @param[in] iterator The iterator.
 * @return The name of the type (e.g., "MyStruct"), or `nullptr` if the iterator is invalid or at the end.
 */
INFIX_API INFIX_NODISCARD const char * infix_registry_iterator_get_name(const infix_registry_iterator_t *);
/**
 * @brief Gets the `infix_type` object of the type at the iterator's current position.
 *
 * @param[in] iterator The iterator.
 * @return A pointer to the canonical `infix_type` object, or `nullptr` if the iterator is invalid or at the end.
 */
INFIX_API INFIX_NODISCARD const infix_type * infix_registry_iterator_get_type(const infix_registry_iterator_t *);
/**
 * @brief Checks if a type with the given name is fully defined in the registry.
 *
 * This function will return `false` for names that are only forward-declared but
 * have not been given a definition.
 *
 * @param[in] registry The registry to search.
 * @param[in] name The name of the type to check (e.g., "MyStruct").
 * @return `true` if a complete definition for the name exists, `false` otherwise.
 */
INFIX_API INFIX_NODISCARD bool infix_registry_is_defined(const infix_registry_t *, const char *);
/**
 * @brief Retrieves the canonical `infix_type` object for a given name from the registry.
 *
 * @param[in] registry The registry to search.
 * @param[in] name The name of the type to retrieve.
 * @return A pointer to the canonical `infix_type` object if found and fully defined.
 *         Returns `nullptr` if the name is not found or is only a forward declaration.
 *         The returned pointer is owned by the registry and is valid for its lifetime.
 */
INFIX_API INFIX_NODISCARD const infix_type * infix_registry_lookup_type(const infix_registry_t *, const char *);
/**
 * @brief Creates a new named type registry that allocates from a user-provided arena.
 *
 * This advanced function allows multiple registries and trampolines to share a single
 * memory arena, enabling pointer sharing and reducing memory overhead. The user
 * is responsible for managing the lifetime of the provided arena.
 *
 * @param[in] arena The user-managed arena to use for all internal allocations.
 * @return A pointer to the new registry, or `nullptr` on allocation failure.
 * @note The registry should still be destroyed with `infix_registry_destroy`, but
 *       this will not free the user-provided arena itself.
 */
INFIX_API INFIX_NODISCARD infix_registry_t * infix_registry_create_in_arena(infix_arena_t * arena);
/** @} */  // end of registry_introspection_api group
/**
 * @brief Creates a "bound" forward trampoline from a signature string.
 *
 * @details A bound trampoline is a highly optimized JIT-compiled function where the
 * target C function's address is compiled directly into the executable code. This
 * provides the best performance for forward calls, as it involves a direct `call`
 * instruction to a known address. It is ideal for situations where you will call
 * the same C function repeatedly.
 *
 * The returned handle contains a callable function pointer of type `infix_cif_func`,
 * which you can retrieve with `infix_forward_get_code`.
 *
 * @param[out] out_trampoline A pointer to an `infix_forward_t*` that will receive the
 *             created trampoline handle upon success.
 * @param[in] signature The signature string of the target function (e.g., `"(int, int)->int"`).
 * @param[in] target_function The address of the C function to be called.
 * @param[in] registry An optional type registry for resolving named types (`@Name`)
 *             used within the signature. Can be `nullptr` if no named types are used.
 * @return `INFIX_SUCCESS` on success, or an `INFIX_ERROR_...` code on failure.
 * @note The caller is responsible for destroying the handle with `infix_forward_destroy`.
 *
 * @code
 * // C function to call
 * int add(int a, int b) { return a + b; }
 *
 * infix_forward_t* trampoline = NULL;
 * const char* signature = "(int, int) -> int";
 *
 * // Create a trampoline bound to the `add` function.
 * infix_status status = infix_forward_create(&trampoline, signature, (void*)add, NULL);
 * if (status != INFIX_SUCCESS) {
 *     // Handle error...
 * }
 *
 * // Get the callable JIT-compiled function pointer.
 * infix_cif_func cif = infix_forward_get_code(trampoline);
 *
 * // Prepare arguments and return buffer.
 * int a = 10, b = 32;
 * void* args[] = { &a, &b };
 * int result;
 *
 * // Call the C function through the FFI.
 * cif(&result, args); // result is now 42
 *
 * infix_forward_destroy(trampoline);
 * @endcode
 */
INFIX_API INFIX_NODISCARD infix_status infix_forward_create(infix_forward_t **,
                                                            const char *,
                                                            void *,
                                                            infix_registry_t *);
/**
 * @brief Creates an "unbound" forward trampoline from a signature string.
 *
 * @details An unbound trampoline is more flexible than a bound one. The target function
 * address is not compiled in; instead, it is provided as the first argument at
 * call time. This is useful for calling multiple C functions that share the same
 * signature without needing to generate a separate trampoline for each one.
 *
 * The returned handle contains a callable function pointer of type `infix_unbound_cif_func`,
 * which you can retrieve with `infix_forward_get_unbound_code`.
 *
 * @param[out] out_trampoline A pointer to an `infix_forward_t*` that will receive the
 *             created trampoline handle upon success.
 * @param[in] signature The signature string of the target function.
 * @param[in] registry An optional type registry for resolving named types. Can be `nullptr`.
 * @return `INFIX_SUCCESS` on success.
 * @note The caller is responsible for destroying the handle with `infix_forward_destroy`.
 *
 * @code
 * int add(int a, int b) { return a + b; }
 * int subtract(int a, int b) { return a - b; }
 *
 * infix_forward_t* trampoline = NULL;
 * const char* signature = "(int, int) -> int";
 *
 * // Create one unbound trampoline for the signature.
 * infix_forward_create_unbound(&trampoline, signature, NULL);
 *
 * infix_unbound_cif_func cif = infix_forward_get_unbound_code(trampoline);
 *
 * int a = 10, b = 5;
 * void* args[] = { &a, &b };
 * int result;
 *
 * // Call `add` by passing its address at call time.
 * cif((void*)add, &result, args); // result is 15
 *
 * // Reuse the same trampoline to call `subtract`.
 * cif((void*)subtract, &result, args); // result is 5
 *
 * infix_forward_destroy(trampoline);
 * @endcode
 */
INFIX_API INFIX_NODISCARD infix_status infix_forward_create_unbound(infix_forward_t **,
                                                                    const char *,
                                                                    infix_registry_t *);
/**
 * @brief Creates a "bound" forward trampoline within a user-provided arena.
 *
 * When the `target_arena` is the same as the registry's arena, this function
 * will share pointers to named types instead of deep-copying them, saving memory.
 *
 * @param[out] out_trampoline Receives the created trampoline handle.
 * @param[in] target_arena The arena to use for the trampoline's internal metadata.
 * @param[in] signature The signature string of the target function.
 * @param[in] target_function The address of the C function to be called.
 * @param[in] registry An optional type registry.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status
infix_forward_create_in_arena(infix_forward_t **, infix_arena_t *, const char *, void *, infix_registry_t *);
/**
 * @brief Creates a type-safe reverse trampoline (callback).
 *
 * @details This function generates a native C function pointer that, when called by
 * external C code, will invoke your `user_callback_fn`. This API is designed
 * primarily for C/C++ developers, as the provided handler function must have a
 * clean, type-safe C signature that exactly matches the one described in the
 * `signature` string. This provides a high level of convenience and compile-time safety.
 *
 * @param[out] out_context A pointer to an `infix_reverse_t*` that will receive the
 *             created context handle.
 * @param[in] signature The signature of the function pointer to be created (e.g., `"(int, int)->int"`).
 * @param[in] user_callback_fn A pointer to a C function with a matching signature to handle the call.
 * @param[in] registry An optional type registry.
 * @return `INFIX_SUCCESS` on success.
 * @note The caller is responsible for destroying the handle with `infix_reverse_destroy`.
 *
 * @code
 * // 1. Define the type-safe C handler function.
 * // Its signature must match "(int, int)->int".
 * int my_handler(int a, int b) {
 *     return a * b;
 * }
 *
 * // 2. Create the reverse trampoline.
 * infix_reverse_t* ctx = NULL;
 * infix_reverse_create_callback(&ctx, "(int,int)->int", (void*)my_handler, NULL);
 *
 * // 3. Get the JIT-compiled C function pointer.
 * typedef int (*my_func_ptr_t)(int, int);
 * my_func_ptr_t func_ptr = (my_func_ptr_t)infix_reverse_get_code(ctx);
 *
 * // 4. Pass this `func_ptr` to some C library that expects a callback.
 * // some_c_library_function(func_ptr);
 * // When the library calls func_ptr(5, 10), `my_handler` will be invoked
 * // and will return 50.
 *
 * infix_reverse_destroy(ctx);
 * @endcode
 */
INFIX_API INFIX_NODISCARD infix_status infix_reverse_create_callback(infix_reverse_t **,
                                                                     const char *,
                                                                     void *,
                                                                     infix_registry_t *);
/**
 * @brief Creates a generic reverse trampoline (closure) for stateful callbacks.
 *
 * @details This is the low-level API for reverse calls, designed for language bindings
 * and advanced use cases. The handler function has a generic signature
 * (`infix_closure_handler_fn`) and receives arguments as a `void**` array.
 * A `user_data` pointer can be provided to maintain state between calls, making it
 * a "closure".
 *
 * This is the most flexible way to handle callbacks, as it allows the handler
 * to be implemented in another language and to access state associated with the
 * callback object.
 *
 * @param[out] out_context A pointer to an `infix_reverse_t*` that will receive the
 *             created context handle.
 * @param[in] signature The signature of the function pointer to be created.
 * @param[in] user_callback_fn A pointer to a generic `infix_closure_handler_fn`.
 * @param[in] user_data A `void*` pointer to application-specific state. This pointer
 *             can be retrieved inside the handler via `infix_reverse_get_user_data(context)`.
 * @param[in] registry An optional type registry.
 * @return `INFIX_SUCCESS` on success.
 * @note The caller is responsible for destroying the handle with `infix_reverse_destroy`.
 *
 * @code
 * // User-defined state for our closure.
 * typedef struct {
 *     int call_count;
 * } my_state_t;
 *
 * // 1. Define the generic closure handler.
 * void my_closure_handler(infix_context_t* ctx, void* ret_val, void** args) {
 *     // Retrieve our state.
 *     my_state_t* state = (my_state_t*)infix_reverse_get_user_data(ctx);
 *     state->call_count++;
 *
 *     // Unpack arguments from the void** array.
 *     int a = *(int*)args[0];
 *     int b = *(int*)args[1];
 *
 *     // Perform the operation and write to the return value buffer.
 *     int result = (a + b) * state->call_count;
 *     memcpy(ret_val, &result, sizeof(int));
 * }
 *
 * // 2. Create the state and the closure.
 * my_state_t my_state = { .call_count = 0 };
 * infix_reverse_t* ctx = NULL;
 * infix_reverse_create_closure(&ctx, "(int,int)->int", my_closure_handler, &my_state, NULL);
 *
 * // 3. Get the JIT-compiled C function pointer.
 * int (*func_ptr)(int, int) = infix_reverse_get_code(ctx);
 *
 * // 4. Pass the func_ptr to C code.
 * int result1 = func_ptr(10, 5); // result1 is (10+5)*1 = 15
 * int result2 = func_ptr(2, 3);  // result2 is (2+3)*2 = 10
 *
 * infix_reverse_destroy(ctx);
 * @endcode
 */
INFIX_API INFIX_NODISCARD infix_status
infix_reverse_create_closure(infix_reverse_t **, const char *, infix_closure_handler_fn, void *, infix_registry_t *);
/**
 * @brief Parses a full function signature string into its constituent parts.
 *
 * This function provides a way to deconstruct a signature string into its components
 * (`return_type`, `arg_types`, etc.) without generating a trampoline. It is useful
 * for introspection and for preparing arguments for the Manual API.
 *
 * @param[in] signature The signature string to parse.
 * @param[out] out_arena On success, receives a pointer to an arena holding all parsed types. The caller owns this and
 * must free it with `infix_arena_destroy`.
 * @param[out] out_ret_type On success, receives a pointer to the return type.
 * @param[out] out_args On success, receives a pointer to the array of `infix_function_argument` structs.
 * @param[out] out_num_args On success, receives the total number of arguments.
 * @param[out] out_num_fixed_args On success, receives the number of fixed (non-variadic) arguments.
 * @param[in] registry An optional type registry.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_signature_parse(
    const char *, infix_arena_t **, infix_type **, infix_function_argument **, size_t *, size_t *, infix_registry_t *);
/**
 * @brief Parses a signature string representing a single data type.
 *
 * This is the core function for introspection, allowing you to get a detailed,
 * fully resolved memory layout for any C type described by a signature.
 *
 * @param[out] out_type On success, receives a pointer to the parsed type object.
 * @param[out] out_arena On success, receives a pointer to the arena holding the type. The caller must free this with
 * `infix_arena_destroy`.
 * @param[in] signature The signature string of the data type (e.g., `"{id:int, name:*char}"`).
 * @param[in] registry An optional type registry for resolving named types.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_type_from_signature(infix_type **,
                                                                 infix_arena_t **,
                                                                 const char *,
                                                                 infix_registry_t *);
/** @} */  // end of high_level_api group
/**
 * @defgroup exports_api Dynamic Library & Globals API
 * @brief Cross-platform functions for loading shared libraries and accessing exported symbols.
 * @{
 */
/**
 * @brief Opens a dynamic library and returns a handle to it.
 * @param[in] path The file path to the library (e.g., `./mylib.so`, `user32.dll`).
 * @return A handle to the library, or `nullptr` on failure. The handle must be freed with `infix_library_close`.
 */
INFIX_API INFIX_NODISCARD infix_library_t * infix_library_open(const char *);
/**
 * @brief Closes a dynamic library handle.
 * @param[in] lib The library handle to close. Safe to call with `nullptr`.
 */
INFIX_API void infix_library_close(infix_library_t *);
/**
 * @brief Retrieves the address of a symbol (function or variable) from a loaded library.
 * @param[in] lib The library handle.
 * @param[in] symbol_name The name of the symbol to look up.
 * @return A pointer to the symbol's address, or `nullptr` if not found.
 */
INFIX_API INFIX_NODISCARD void * infix_library_get_symbol(infix_library_t *, const char *);
/**
 * @brief Reads the value of a global variable from a library into a buffer.
 *
 * Uses the signature parser to determine the size of the variable to ensure the
 * correct number of bytes are copied.
 *
 * @param[in] lib The library handle.
 * @param[in] symbol_name The name of the global variable.
 * @param[in] type_signature The `infix` signature string describing the variable's type.
 * @param[out] buffer A pointer to the destination buffer to receive the data.
 * @param[in] registry An optional registry for resolving named types in the signature.
 * @return `INFIX_SUCCESS` on success, or an error code on failure.
 */
INFIX_API INFIX_NODISCARD infix_status
infix_read_global(infix_library_t *, const char *, const char *, void *, infix_registry_t *);
/**
 * @brief Writes data from a buffer into a global variable in a library.
 * @param[in] lib The library handle.
 * @param[in] symbol_name The name of the global variable.
 * @param[in] type_signature The `infix` signature string describing the variable's type.
 * @param[in] buffer A pointer to the source buffer containing the data to write.
 * @param[in] registry An optional registry for resolving named types in the signature.
 * @return `INFIX_SUCCESS` on success, or an error code on failure.
 */
INFIX_API INFIX_NODISCARD infix_status
infix_write_global(infix_library_t *, const char *, const char *, void *, infix_registry_t *);
/** @} */  // end of exports_api group
/**
 * @defgroup manual_api Manual API
 * @brief A lower-level, programmatic API for creating trampolines from `infix_type` objects.
 *
 * This API is intended for performance-critical applications or language bindings that
 * need to construct type information dynamically without the overhead of string parsing.
 * All `infix_type` objects passed to these functions must be allocated from an `infix_arena_t`.
 * @{
 */
/**
 * @brief Creates a bound forward trampoline from `infix_type` objects.
 * @param[out] out_trampoline Receives the created trampoline handle.
 * @param[in] return_type The `infix_type` for the function's return value.
 * @param[in] arg_types An array of `infix_type*` for the function's arguments.
 * @param[in] num_args The number of arguments.
 * @param[in] num_fixed_args The number of non-variadic arguments.
 * @param[in] target_function The address of the C function to call.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status
infix_forward_create_manual(infix_forward_t **, infix_type *, infix_type **, size_t, size_t, void *);
/**
 * @brief Creates an unbound forward trampoline from `infix_type` objects.
 * @param[out] out_trampoline Receives the created trampoline handle.
 * @param[in] return_type The `infix_type` for the function's return value.
 * @param[in] arg_types An array of `infix_type*` for the function's arguments.
 * @param[in] num_args The number of arguments.
 * @param[in] num_fixed_args The number of non-variadic arguments.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status
infix_forward_create_unbound_manual(infix_forward_t **, infix_type *, infix_type **, size_t, size_t);
/**
 * @brief Creates a type-safe reverse trampoline (callback) from `infix_type` objects.
 * @param[out] out_context Receives the created context handle.
 * @param[in] return_type The function's return type.
 * @param[in] arg_types An array of argument types.
 * @param[in] num_args The number of arguments.
 * @param[in] num_fixed_args The number of non-variadic arguments.
 * @param[in] user_callback_fn A pointer to the type-safe C handler function.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status
infix_reverse_create_callback_manual(infix_reverse_t **, infix_type *, infix_type **, size_t, size_t, void *);
/**
 * @brief Creates a generic reverse trampoline (closure) from `infix_type` objects.
 * @param[out] out_context Receives the created context handle.
 * @param[in] return_type The function's return type.
 * @param[in] arg_types An array of argument types.
 * @param[in] num_args The number of arguments.
 * @param[in] num_fixed_args The number of non-variadic arguments.
 * @param[in] user_callback_fn A pointer to the generic `infix_closure_handler_fn`.
 * @param[in] user_data A `void*` pointer to application-specific state.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_reverse_create_closure_manual(
    infix_reverse_t **, infix_type *, infix_type **, size_t, size_t, infix_closure_handler_fn, void *);
/**
 * @brief Destroys a forward trampoline and frees all associated memory.
 * @param[in] trampoline The trampoline to destroy. Safe to call with `nullptr`.
 */
INFIX_API void infix_forward_destroy(infix_forward_t *);
/**
 * @brief Destroys a reverse trampoline and frees all associated memory.
 * @param[in] reverse_trampoline The reverse trampoline context to destroy. Safe to call with `nullptr`.
 */
INFIX_API void infix_reverse_destroy(infix_reverse_t *);
/**
 * @addtogroup type_system
 * @{
 */
/**
 * @brief Creates a static descriptor for a primitive C type.
 * @param[in] id The `infix_primitive_type_id` of the desired primitive type.
 * @return A pointer to the static `infix_type` descriptor. Does not need to be freed.
 */
INFIX_API INFIX_NODISCARD infix_type * infix_type_create_primitive(infix_primitive_type_id);
/**
 * @brief Creates a static descriptor for a generic pointer (`void*`).
 * @return A pointer to the static `infix_type` descriptor. Does not need to be freed.
 */
INFIX_API INFIX_NODISCARD infix_type * infix_type_create_pointer(void);
/**
 * @brief Creates a new pointer type that points to a specific type.
 * @param[in] arena The arena to allocate the new type object in.
 * @param[out] out_type A pointer to receive the created `infix_type`.
 * @param[in] pointee_type The type that the new pointer will point to.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_type_create_pointer_to(infix_arena_t *, infix_type **, infix_type *);
/**
 * @brief Creates a static descriptor for the `void` type.
 * @return A pointer to the static `infix_type` descriptor. Does not need to be freed.
 */
INFIX_API INFIX_NODISCARD infix_type * infix_type_create_void(void);
/**
 * @brief Creates a new struct type from an array of members, calculating layout automatically.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] members An array of `infix_struct_member` describing the struct's layout. The `offset` field is ignored.
 * @param[in] num_members The number of members in the array.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_type_create_struct(infix_arena_t *,
                                                                infix_type **,
                                                                infix_struct_member *,
                                                                size_t);
/**
 * @brief Creates a new packed struct type with a user-specified layout.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] total_size The total size of the packed struct in bytes.
 * @param[in] alignment The alignment requirement of the struct (e.g., 1 for `#pragma pack(1)`).
 * @param[in] members An array of `infix_struct_member` with pre-calculated offsets.
 * @param[in] num_members The number of members.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status
infix_type_create_packed_struct(infix_arena_t *, infix_type **, size_t, size_t, infix_struct_member *, size_t);
/**
 * @brief Creates a new union type from an array of members.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] members An array of `infix_struct_member` describing the union's members.
 * @param[in] num_members The number of members.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_type_create_union(infix_arena_t *,
                                                               infix_type **,
                                                               infix_struct_member *,
                                                               size_t);
/**
 * @brief Creates a new fixed-size array type.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] element_type The type of each element in the array.
 * @param[in] num_elements The number of elements.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_type_create_array(infix_arena_t *, infix_type **, infix_type *, size_t);
/**
 * @brief Creates a flexible array member type ([?:type]).
 * @details A Flexible Array Member (FAM) has an unspecified size and can only appear as the last member of a struct.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] element_type The primitive type of each element.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API infix_status infix_type_create_flexible_array(infix_arena_t *, infix_type **, infix_type *);
/**
 * @brief Creates a new enum type with a specified underlying integer type.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] underlying_type The integer `infix_type` (e.g., from
 * `infix_type_create_primitive(INFIX_PRIMITIVE_SINT32)`).
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_type_create_enum(infix_arena_t *, infix_type **, infix_type *);
/**
 * @brief Creates a placeholder for a named type to be resolved by a registry.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] name The name of the type (e.g., "MyStruct").
 * @param[in] agg_cat The expected category of the aggregate (struct or union).
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_type_create_named_reference(infix_arena_t *,
                                                                         infix_type **,
                                                                         const char *,
                                                                         infix_aggregate_category_t);
/**
 * @brief Creates a new `_Complex` number type.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] base_type The base floating-point type (`float` or `double`).
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_type_create_complex(infix_arena_t *, infix_type **, infix_type *);
/**
 * @brief Creates a new SIMD vector type.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] element_type The primitive type of each element.
 * @param[in] num_elements The number of elements in the vector.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API INFIX_NODISCARD infix_status infix_type_create_vector(infix_arena_t *, infix_type **, infix_type *, size_t);
/**
 * @brief A factory function to create an `infix_struct_member`.
 * @param[in] name The name of the member (optional, can be `nullptr`).
 * @param[in] type The `infix_type` of the member.
 * @param[in] offset The byte offset of the member. This is ignored by `infix_type_create_struct`.
 * @return An initialized `infix_struct_member` object.
 */
INFIX_API infix_struct_member infix_type_create_member(const char *, infix_type *, size_t);
/**
 * @brief A factory function to create a bitfield `infix_struct_member`.
 * @param[in] name The name of the member.
 * @param[in] type The integer `infix_type` of the bitfield.
 * @param[in] offset The byte offset (usually calculated automatically, so 0 is fine for automatic layout).
 * @param[in] bit_width The width of the bitfield in bits.
 * @return An initialized `infix_struct_member` object with bitfield metadata.
 */
INFIX_API infix_struct_member infix_type_create_bitfield_member(const char *, infix_type *, size_t, uint8_t);
/** @} */  // end of manual_api group (continued)
/** @} */  // end of type_system group
/**
 * @addtogroup memory_management
 * @{
 */
/**
 * @brief Creates a new memory arena.
 * @details An arena is a fast, region-based allocator. All objects allocated from it
 * are freed at once when the arena is destroyed. This is the required mechanism for
 * creating types for the Manual API.
 * @param[in] initial_size The initial capacity of the arena in bytes.
 * @return A pointer to the new arena, or `nullptr` on failure. The caller must free this with `infix_arena_destroy`.
 */
INFIX_API INFIX_NODISCARD infix_arena_t * infix_arena_create(size_t);
/**
 * @brief Destroys an arena and frees all memory allocated from it.
 * @param[in] arena The arena to destroy. Safe to call with `nullptr`.
 */
INFIX_API void infix_arena_destroy(infix_arena_t *);
/**
 * @brief Allocates a block of memory from an arena.
 * @param[in] arena The arena to allocate from.
 * @param[in] size The number of bytes to allocate.
 * @param[in] alignment The required alignment for the allocation. Must be a power of two.
 * @return A pointer to the allocated memory, or `nullptr` on failure.
 */
INFIX_API INFIX_NODISCARD void * infix_arena_alloc(infix_arena_t *, size_t, size_t);
/**
 * @brief Allocates and zero-initializes a block of memory from an arena.
 * @param[in] arena The arena to allocate from.
 * @param[in] num The number of elements.
 * @param[in] size The size of each element.
 * @param[in] alignment The required alignment. Must be a power of two.
 * @return A pointer to the zero-initialized memory, or `nullptr` on failure.
 */
INFIX_API INFIX_NODISCARD void * infix_arena_calloc(infix_arena_t *, size_t, size_t, size_t);
/** @} */  // end of memory_management group (continued)
/**
 * @defgroup introspection_api Introspection API
 * @brief Functions for inspecting the properties of trampolines and `infix_type` objects at runtime.
 *
 * This API is essential for building dynamic language bindings, serializers, or any
 * tool that needs to understand the memory layout and signature of C data structures
 * and functions.
 * @{
 */
/**
 * @brief Specifies the output format for printing types and function signatures.
 */
typedef enum {
    INFIX_DIALECT_SIGNATURE,        /**< The standard, human-readable `infix` signature format. */
    INFIX_DIALECT_ITANIUM_MANGLING, /**< (Not yet implemented) Itanium C++ ABI name mangling. */
    INFIX_DIALECT_MSVC_MANGLING     /**< (Not yet implemented) MSVC C++ name mangling. */
} infix_print_dialect_t;
/**
 * @brief Serializes an `infix_type` object graph back into a signature string.
 * @param[out] buffer The output buffer to write the string into.
 * @param[in] buffer_size The size of the output buffer.
 * @param[in] type The `infix_type` to print.
 * @param[in] dialect The desired output format dialect.
 * @return `INFIX_SUCCESS` on success, or `INFIX_ERROR_INVALID_ARGUMENT` if the buffer is too small.
 */
INFIX_API INFIX_NODISCARD infix_status infix_type_print(char *, size_t, const infix_type *, infix_print_dialect_t);
/**
 * @brief Serializes a function signature's components into a string.
 * @param[out] buffer The output buffer.
 * @param[in] buffer_size The size of the output buffer.
 * @param[in] function_name Optional name for dialects that support it.
 * @param[in] ret_type The return type.
 * @param[in] args The array of arguments.
 * @param[in] num_args The total number of arguments.
 * @param[in] num_fixed_args The number of fixed arguments.
 * @param[in] dialect The output dialect.
 * @return `INFIX_SUCCESS` on success, or `INFIX_ERROR_INVALID_ARGUMENT` if the buffer is too small.
 */
INFIX_API INFIX_NODISCARD infix_status infix_function_print(char *,
                                                            size_t,
                                                            const char *,
                                                            const infix_type *,
                                                            const infix_function_argument *,
                                                            size_t,
                                                            size_t,
                                                            infix_print_dialect_t);
/**
 * @brief Gets the callable function pointer from an unbound forward trampoline.
 * @param[in] trampoline The unbound `infix_forward_t` handle.
 * @return A callable `infix_unbound_cif_func` pointer on success, or `nullptr` if the
 *         trampoline is `nullptr` or if it is a bound trampoline.
 */
INFIX_API INFIX_NODISCARD infix_unbound_cif_func infix_forward_get_unbound_code(infix_forward_t *);
/**
 * @brief Gets the callable function pointer from a bound forward trampoline.
 * @param[in] trampoline The bound `infix_forward_t` handle.
 * @return A callable `infix_cif_func` pointer on success, or `nullptr` if the
 *         trampoline is `nullptr` or if it is an unbound trampoline.
 */
INFIX_API INFIX_NODISCARD infix_cif_func infix_forward_get_code(infix_forward_t *);
/**
 * @brief Gets the native, callable C function pointer from a reverse trampoline.
 * @param[in] reverse_trampoline The `infix_reverse_t` context handle.
 * @return A `void*` that can be cast to the appropriate C function pointer type and called.
 *         The returned pointer is valid for the lifetime of the context handle.
 */
INFIX_API INFIX_NODISCARD void * infix_reverse_get_code(const infix_reverse_t *);
/**
 * @brief Gets the user-provided data pointer from a closure context.
 * @param[in] reverse_trampoline The `infix_reverse_t` context handle created with `infix_reverse_create_closure`.
 * @return The `void* user_data` that was provided during creation.
 */
INFIX_API INFIX_NODISCARD void * infix_reverse_get_user_data(const infix_reverse_t *);
/** @addtogroup type_system */
/** @{ */
/**
 * @brief Gets the total number of arguments for a forward trampoline.
 * @param[in] trampoline The trampoline handle.
 * @return The number of arguments, or 0 if `trampoline` is `nullptr`.
 */
INFIX_API INFIX_NODISCARD size_t infix_forward_get_num_args(const infix_forward_t *);
/**
 * @brief Gets the number of fixed (non-variadic) arguments for a forward trampoline.
 * @param[in] trampoline The trampoline handle.
 * @return The number of fixed arguments.
 */
INFIX_API INFIX_NODISCARD size_t infix_forward_get_num_fixed_args(const infix_forward_t *);
/**
 * @brief Gets the return type for a forward trampoline.
 * @param[in] trampoline The trampoline handle.
 * @return A pointer to the `infix_type` for the return value, or `nullptr`.
 */
INFIX_API INFIX_NODISCARD const infix_type * infix_forward_get_return_type(const infix_forward_t *);
/**
 * @brief Gets the type of a specific argument for a forward trampoline.
 * @param[in] trampoline The trampoline handle.
 * @param[in] index The zero-based index of the argument.
 * @return A pointer to the `infix_type`, or `nullptr` if the index is out of bounds.
 */
INFIX_API INFIX_NODISCARD const infix_type * infix_forward_get_arg_type(const infix_forward_t *, size_t);
/**
 * @brief Gets the total number of arguments for a reverse trampoline.
 * @param[in] trampoline The trampoline context handle.
 * @return The number of arguments, or 0 if `trampoline` is `nullptr`.
 */
INFIX_API INFIX_NODISCARD size_t infix_reverse_get_num_args(const infix_reverse_t *);
/**
 * @brief Gets the return type for a reverse trampoline.
 * @param[in] trampoline The trampoline context handle.
 * @return A pointer to the `infix_type` for the return value, or `nullptr`.
 */
INFIX_API INFIX_NODISCARD const infix_type * infix_reverse_get_return_type(const infix_reverse_t *);
/**
 * @brief Gets the number of fixed (non-variadic) arguments for a reverse trampoline.
 * @param[in] trampoline The trampoline context handle.
 * @return The number of fixed arguments.
 */
INFIX_API INFIX_NODISCARD size_t infix_reverse_get_num_fixed_args(const infix_reverse_t *);
/**
 * @brief Gets the type of a specific argument for a reverse trampoline.
 * @param[in] trampoline The trampoline context handle.
 * @param[in] index The zero-based index of the argument.
 * @return A pointer to the `infix_type`, or `nullptr` if the index is out of bounds.
 */
INFIX_API INFIX_NODISCARD const infix_type * infix_reverse_get_arg_type(const infix_reverse_t *, size_t);
/**
 * @brief Gets the semantic alias of a type, if one exists.
 * @param[in] type The type object to inspect.
 * @return The name of the type if it was created from a registry alias (e.g., "MyInt"), or `nullptr` if the type is
 * anonymous.
 */
INFIX_API INFIX_NODISCARD const char * infix_type_get_name(const infix_type *);
/**
 * @brief Gets the fundamental category of a type.
 * @param[in] type The type object to inspect.
 * @return The `infix_type_category` enum value.
 */
INFIX_API INFIX_NODISCARD infix_type_category infix_type_get_category(const infix_type *);
/**
 * @brief Gets the size of a type in bytes.
 * @param[in] type The type object to inspect.
 * @return The size in bytes.
 */
INFIX_API INFIX_NODISCARD size_t infix_type_get_size(const infix_type *);
/**
 * @brief Gets the alignment requirement of a type in bytes.
 * @param[in] type The type object to inspect.
 * @return The alignment in bytes.
 */
INFIX_API INFIX_NODISCARD size_t infix_type_get_alignment(const infix_type *);
/**
 * @brief Gets the number of members in a struct or union type.
 * @param[in] type The aggregate type object to inspect.
 * @return The number of members, or 0 if the type is not a struct or union.
 */
INFIX_API INFIX_NODISCARD size_t infix_type_get_member_count(const infix_type *);
/**
 * @brief Gets a specific member from a struct or union type.
 * @param[in] type The aggregate type object to inspect.
 * @param[in] index The zero-based index of the member.
 * @return A pointer to the `infix_struct_member`, or `nullptr` if the index is out of bounds.
 */
INFIX_API INFIX_NODISCARD const infix_struct_member * infix_type_get_member(const infix_type *, size_t);
/**
 * @brief Gets the name of a specific argument from a function type.
 * @param[in] func_type The function type object to inspect (`INFIX_TYPE_REVERSE_TRAMPOLINE`).
 * @param[in] index The zero-based index of the argument.
 * @return The name of the argument, or `nullptr` if anonymous or out of bounds.
 */
INFIX_API INFIX_NODISCARD const char * infix_type_get_arg_name(const infix_type *, size_t);
/**
 * @brief Gets the type of a specific argument from a function type.
 * @param[in] func_type The function type object to inspect.
 * @param[in] index The zero-based index of the argument.
 * @return A pointer to the `infix_type`, or `nullptr` if the index is out of bounds.
 */
INFIX_API INFIX_NODISCARD const infix_type * infix_type_get_arg_type(const infix_type *, size_t);
/** @} */  // end addtogroup type_system
/** @} */  // end of introspection_api group
/**
 * @defgroup error_api Error Handling API
 * @brief Functions and types for detailed, thread-safe error reporting.
 * @{
 */
/**
 * @brief Enumerates the high-level categories of errors that can occur.
 */
typedef enum {
    INFIX_CATEGORY_NONE,       /**< No error. */
    INFIX_CATEGORY_GENERAL,    /**< A general or miscellaneous error. */
    INFIX_CATEGORY_ALLOCATION, /**< A memory allocation error. */
    INFIX_CATEGORY_PARSER,     /**< A syntax error in a signature string. */
    INFIX_CATEGORY_ABI         /**< An error related to ABI classification or layout. */
} infix_error_category_t;
/**
 * @brief Enumerates specific error codes.
 */
typedef enum {
    // General Codes (0-99)
    INFIX_CODE_SUCCESS = 0,      /**< No error occurred. */
    INFIX_CODE_UNKNOWN,          /**< An unspecified error occurred. */
    INFIX_CODE_NULL_POINTER,     /**< A required pointer argument was NULL. */
    INFIX_CODE_MISSING_REGISTRY, /**< A type registry was required but not provided. */

    // Allocation Codes (100-199)
    INFIX_CODE_OUT_OF_MEMORY = 100,       /**< A call to `malloc`, `calloc`, etc. failed. */
    INFIX_CODE_EXECUTABLE_MEMORY_FAILURE, /**< Failed to allocate executable memory from the OS. */
    INFIX_CODE_PROTECTION_FAILURE,        /**< Failed to change memory protection flags (e.g., `mprotect`). */
    INFIX_CODE_INVALID_ALIGNMENT,         /**< An invalid alignment (0 or not power-of-two) was requested. */

    // Parser Codes (200-299)
    INFIX_CODE_UNEXPECTED_TOKEN = 200,   /**< Encountered an unexpected character or token. */
    INFIX_CODE_UNTERMINATED_AGGREGATE,   /**< A struct, union, or array was not properly closed. */
    INFIX_CODE_INVALID_KEYWORD,          /**< An unknown or misspelled type keyword was used. */
    INFIX_CODE_MISSING_RETURN_TYPE,      /**< A function signature was missing the '->' and return type. */
    INFIX_CODE_INTEGER_OVERFLOW,         /**< An integer overflow occurred during layout calculation. */
    INFIX_CODE_RECURSION_DEPTH_EXCEEDED, /**< A type definition was too deeply nested. */
    INFIX_CODE_EMPTY_MEMBER_NAME,        /**< A named member was declared with an empty name. */
    INFIX_CODE_EMPTY_SIGNATURE,          /**< The provided signature string was empty. */

    // ABI/Layout Codes (300-399)
    INFIX_CODE_UNSUPPORTED_ABI = 300, /**< The current platform's ABI is not supported by `infix`. */
    INFIX_CODE_TYPE_TOO_LARGE,        /**< A data type exceeded the ABI's size limits. */
    INFIX_CODE_UNRESOLVED_NAMED_TYPE, /**< A named type (`@Name`) was not found in the provided registry. */
    INFIX_CODE_INVALID_MEMBER_TYPE,   /**< An aggregate contained an illegal member type (e.g., `void`). */
    INFIX_CODE_LAYOUT_FAILED,         /**< The ABI layer failed to calculate a valid memory layout for a type. */

    // Library Loading Codes (400-499)
    INFIX_CODE_LIBRARY_NOT_FOUND = 400, /**< The requested dynamic library could not be found. */
    INFIX_CODE_SYMBOL_NOT_FOUND,        /**< The requested symbol was not found in the library. */
    INFIX_CODE_LIBRARY_LOAD_FAILED      /**< The dynamic library failed to load for other reasons. */
} infix_error_code_t;
/**
 * @struct infix_error_details_t
 * @brief Provides detailed, thread-local information about the last error that occurred.
 */
typedef struct {
    infix_error_category_t category; /**< The general category of the error. */
    infix_error_code_t code;         /**< The specific error code. */
    size_t position;                 /**< For parser errors, the byte offset into the signature string. */
    long system_error_code;          /**< The OS-specific error code (e.g., from `GetLastError()` or `errno`). */
    char message[256]; /**< A human-readable description of the error. For parser errors, this includes a code snippet.
                        */
} infix_error_details_t;
/**
 * @brief Retrieves detailed information about the last error that occurred on the current thread.
 * @return A copy of the last error details structure. This function is thread-safe.
 */
INFIX_API infix_error_details_t infix_get_last_error(void);
/** @} */  // end of error_api group
/**
 * @defgroup direct_marshalling_api Direct Marshalling API
 * @brief An advanced, high-performance API for language bindings.
 * @ingroup high_level_api
 *
 * This API provides a way to create highly optimized forward trampolines that
 * bypass the standard `void**` argument array. Instead, the JIT-compiled code
 * directly calls user-provided "marshaller" functions to convert language-specific
 * objects into native C arguments just-in-time. This reduces memory indirection
 * and copying, yielding significant performance gains for FFI calls in tight loops.
 * @{
 */

/**
 * @brief A function pointer for a direct marshalling forward trampoline.
 *
 * This is the callable code generated by `infix_forward_create_direct`. It takes
 * an array of `void*` pointers that point directly to the language-specific
 * objects (e.g., `SV*` in Perl, `PyObject*` in Python).
 *
 * @param return_value_ptr A pointer to a buffer to receive the C function's return value.
 * @param lang_objects_array An array of `void*` pointers to the original language objects.
 */
typedef void (*infix_direct_cif_func)(void *, void **);

/**
 * @brief A union to hold any primitive value returned by a scalar marshaller.
 *
 * Since a C function can only have one return type, a marshaller for primitive
 * types (`infix_marshaller_fn`) returns this union. The JIT-compiled code will
 * know which member of the union to access based on the argument's C type.
 */
typedef union {
    uint64_t u64;  ///< Used for all unsigned integer types up to 64 bits.
    int64_t i64;   ///< Used for all signed integer types up to 64 bits.
    double f64;    ///< Used for `float` and `double`.
    void * ptr;    ///< Used for all pointer types.
} infix_direct_value_t;

/**
 * @brief A function pointer for a custom marshaller for scalar types.
 *
 * A language binding provides a function of this type to convert a language object
 * into a native C primitive value (integer, float, pointer, etc.).
 *
 * @param source_object A generic `void*` pointer to the language's native object.
 * @return An `infix_direct_value_t` union containing the converted C value.
 */
typedef infix_direct_value_t (*infix_marshaller_fn)(void * source_object);

/**
 * @brief A function pointer for a custom marshaller for aggregate types (structs/unions).
 *
 * A language binding provides a function of this type to populate a C struct/union
 * from a language object (e.g., a hash or dictionary).
 *
 * @param source_object A `void*` pointer to the language's native object.
 * @param dest_buffer A pointer to a block of memory, allocated by the JIT trampoline,
 *                    that is the exact size of the C aggregate. The function must
 *                    fill this buffer with the native C data.
 * @param type A pointer to the `infix_type` object describing the C aggregate. The
 *             marshaller can introspect this type to determine field names, offsets,
 *             and member types.
 */
typedef void (*infix_aggregate_marshaller_fn)(void * source_object, void * dest_buffer, const infix_type * type);

/**
 * @brief A function pointer for a "write-back" handler for out/in-out parameters.
 *
 * This function is called by the JIT trampoline *after* the native C function has
 * returned. Its purpose is to update the original language object with any changes
 * made to the C data by the function.
 *
 * @param source_object A `void*` pointer to the original language object that was passed in.
 * @param c_data_ptr A pointer to the (potentially modified) C data buffer that was passed
 *                   to the C function.
 * @param type A pointer to the `infix_type` object describing the C data.
 */
typedef void (*infix_writeback_fn)(void * source_object, void * c_data_ptr, const infix_type * type);

/**
 * @brief A struct containing all the necessary handlers for a single function argument.
 *
 * For each argument, a language binding provides an instance of this struct. Based on
 * the argument's type, one or more of the function pointers will be non-NULL.
 */
typedef struct {
    /** @brief For "in" parameters of a scalar type (int, float, pointer). */
    infix_marshaller_fn scalar_marshaller;
    /** @brief For "in" parameters of an aggregate type (struct, union). */
    infix_aggregate_marshaller_fn aggregate_marshaller;
    /** @brief For "out" or "in-out" parameters. Called after the C function returns. */
    infix_writeback_fn writeback_handler;
} infix_direct_arg_handler_t;

/**
 * @brief Creates a forward trampoline with direct, JIT-bound marshalling.
 *
 * This advanced function generates a highly optimized trampoline that calls user-provided
 * marshaller functions directly from the JIT-compiled code to convert language-specific
 * objects into native C arguments. This avoids intermediate copying and provides the
 * highest performance for forward calls.
 *
 * @param[out] out_trampoline Receives the created trampoline handle upon success.
 * @param[in] signature The C signature of the target function (e.g., `"(int, *char)->void"`).
 * @param[in] target_function The address of the C function to be called.
 * @param[in] handlers An array of `infix_direct_arg_handler_t` structs, one for each
 *              argument of the C function. The array must have exactly as many
 *              elements as the function has arguments.
 * @param[in] registry An optional type registry for resolving named types (`@Name`)
 *              used within the signature. Can be `nullptr`.
 * @return `INFIX_SUCCESS` on success, or an error code on failure.
 */
INFIX_API INFIX_NODISCARD infix_status infix_forward_create_direct(infix_forward_t ** out_trampoline,
                                                                   const char * signature,
                                                                   void * target_function,
                                                                   infix_direct_arg_handler_t * handlers,
                                                                   infix_registry_t * registry);
/**
 * @brief Gets the callable function pointer from a direct marshalling trampoline.
 *
 * @param[in] trampoline The `infix_forward_t` handle created with `infix_forward_create_direct`.
 * @return A callable `infix_direct_cif_func` pointer on success, or `nullptr` if the
 *         trampoline is `nullptr` or is not a direct marshalling trampoline.
 */
INFIX_API INFIX_NODISCARD infix_direct_cif_func infix_forward_get_direct_code(infix_forward_t * trampoline);
/** @} */  // end of direct_marshalling_api group
#ifdef __cplusplus
}
#endif
