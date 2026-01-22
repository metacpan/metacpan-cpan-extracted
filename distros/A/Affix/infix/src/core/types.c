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
 * @file types.c
 * @brief Implements the public API for creating and managing type descriptions.
 * @ingroup internal_core
 *
 * @details This module serves two primary functions:
 * 1.  It provides the public functions for programmatically constructing `infix_type`
 *     objects (the "Manual API"). These functions are the building blocks for
 *     users who need to create type information dynamically without parsing strings.
 * 2.  It contains the crucial internal logic for two core stages of the data pipeline:
 *     - **Copying (`_copy_type_graph_to_arena`):** Deep-copies a type graph to a
 *       new memory arena, which is fundamental to creating self-contained trampoline
 *       objects and ensuring memory safety.
 *     - **Layout (`_infix_type_recalculate_layout`):** Traverses a fully resolved
 *       type graph to compute the final memory layout (size, alignment, and offsets)
 *       of all structures and unions.
 *
 * The creation functions (`infix_type_create_*`) perform an initial, preliminary layout
 * calculation. This layout is considered unresolved until a final pass with
 * `_infix_type_recalculate_layout` is performed after all named types have been
 * resolved by the type registry.
 */
#include "common/infix_internals.h"
#include "common/utility.h"
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// Static Descriptors for Primitive and Built-in Types

#define INFIX_MAX_ALIGNMENT (1024 * 1024)  // 1MB Safety Limit

/**
 * @internal
 * @def INFIX_TYPE_INIT
 * @brief A macro to statically initialize a primitive `infix_type` descriptor.
 *
 * @details This macro ensures that all primitive type descriptors are initialized
 * correctly at compile time with their `sizeof` and `_Alignof` values from the
 * compiler. They are marked with `is_arena_allocated = false` to signify that
 * they are static singletons. This has two important consequences:
 * 1. They can be returned directly by API functions without requiring allocation.
 * 2. They serve as the essential base case for the recursive `_copy_type_graph_to_arena`
 *    algorithm, which stops recursing when it encounters a non-arena-allocated type.
 */
#define INFIX_TYPE_INIT(id, T)         \
    {.name = nullptr,                  \
     .category = INFIX_TYPE_PRIMITIVE, \
     .size = sizeof(T),                \
     .alignment = _Alignof(T),         \
     .is_arena_allocated = false,      \
     .arena = nullptr,                 \
     .source_offset = 0,               \
     .meta.primitive_id = id}
/**
 * @internal
 * @var _infix_type_void
 * @brief Static singleton descriptor for the `void` type.
 */
static infix_type _infix_type_void = {.name = nullptr,
                                      .category = INFIX_TYPE_VOID,
                                      .size = 0,
                                      .alignment = 0,
                                      .is_arena_allocated = false,
                                      .arena = nullptr,
                                      .source_offset = 0,
                                      .meta = {0}};
/**
 * @internal
 * @var _infix_type_pointer
 * @brief Static singleton descriptor for a generic pointer (`void*`).
 */
static infix_type _infix_type_pointer = {.name = nullptr,
                                         .category = INFIX_TYPE_POINTER,
                                         .size = sizeof(void *),
                                         .alignment = _Alignof(void *),
                                         .is_arena_allocated = false,
                                         .arena = nullptr,
                                         .source_offset = 0,
                                         .meta.pointer_info = {.pointee_type = &_infix_type_void}};
/** @internal Static singleton for the `bool` primitive type. */
static infix_type _infix_type_bool = INFIX_TYPE_INIT(INFIX_PRIMITIVE_BOOL, bool);
/** @internal Static singleton for the `uint8_t` primitive type. */
static infix_type _infix_type_uint8 = INFIX_TYPE_INIT(INFIX_PRIMITIVE_UINT8, uint8_t);
/** @internal Static singleton for the `int8_t` primitive type. */
static infix_type _infix_type_sint8 = INFIX_TYPE_INIT(INFIX_PRIMITIVE_SINT8, int8_t);
/** @internal Static singleton for the `uint16_t` primitive type. */
static infix_type _infix_type_uint16 = INFIX_TYPE_INIT(INFIX_PRIMITIVE_UINT16, uint16_t);
/** @internal Static singleton for the `int16_t` primitive type. */
static infix_type _infix_type_sint16 = INFIX_TYPE_INIT(INFIX_PRIMITIVE_SINT16, int16_t);
/** @internal Static singleton for the `uint32_t` primitive type. */
static infix_type _infix_type_uint32 = INFIX_TYPE_INIT(INFIX_PRIMITIVE_UINT32, uint32_t);
/** @internal Static singleton for the `int32_t` primitive type. */
static infix_type _infix_type_sint32 = INFIX_TYPE_INIT(INFIX_PRIMITIVE_SINT32, int32_t);
/** @internal Static singleton for the `uint64_t` primitive type. */
static infix_type _infix_type_uint64 = INFIX_TYPE_INIT(INFIX_PRIMITIVE_UINT64, uint64_t);
/** @internal Static singleton for the `int64_t` primitive type. */
static infix_type _infix_type_sint64 = INFIX_TYPE_INIT(INFIX_PRIMITIVE_SINT64, int64_t);
#if !defined(INFIX_COMPILER_MSVC)
/** @internal Static singleton for the `__uint128_t` primitive type (GCC/Clang only). */
static infix_type _infix_type_uint128 = INFIX_TYPE_INIT(INFIX_PRIMITIVE_UINT128, __uint128_t);
/** @internal Static singleton for the `__int128_t` primitive type (GCC/Clang only). */
static infix_type _infix_type_sint128 = INFIX_TYPE_INIT(INFIX_PRIMITIVE_SINT128, __int128_t);
#endif
/** @internal Static singleton for the `float` primitive type. */
static infix_type _infix_type_float = INFIX_TYPE_INIT(INFIX_PRIMITIVE_FLOAT, float);
/** @internal Static singleton for the `double` primitive type. */
static infix_type _infix_type_double = INFIX_TYPE_INIT(INFIX_PRIMITIVE_DOUBLE, double);
#if defined(INFIX_COMPILER_MSVC) || (defined(INFIX_OS_WINDOWS) && defined(INFIX_COMPILER_CLANG))
// On these platforms, long double is just an alias for double, so no separate singleton is needed.
#else
/** @internal Static singleton for the `long double` primitive type (where it is distinct from `double`). */
static infix_type _infix_type_long_double = INFIX_TYPE_INIT(INFIX_PRIMITIVE_LONG_DOUBLE, long double);
#endif
// Public API: Type Creation Functions
/**
 * @brief Creates a static descriptor for a primitive C type.
 * @param[in] id The `infix_primitive_type_id` of the desired primitive type.
 * @return A pointer to the corresponding static `infix_type` singleton descriptor. This pointer does not need to be
 * freed.
 */
INFIX_API c23_nodiscard infix_type * infix_type_create_primitive(infix_primitive_type_id id) {
    switch (id) {
    case INFIX_PRIMITIVE_BOOL:
        return &_infix_type_bool;
    case INFIX_PRIMITIVE_UINT8:
        return &_infix_type_uint8;
    case INFIX_PRIMITIVE_SINT8:
        return &_infix_type_sint8;
    case INFIX_PRIMITIVE_UINT16:
        return &_infix_type_uint16;
    case INFIX_PRIMITIVE_SINT16:
        return &_infix_type_sint16;
    case INFIX_PRIMITIVE_UINT32:
        return &_infix_type_uint32;
    case INFIX_PRIMITIVE_SINT32:
        return &_infix_type_sint32;
    case INFIX_PRIMITIVE_UINT64:
        return &_infix_type_uint64;
    case INFIX_PRIMITIVE_SINT64:
        return &_infix_type_sint64;
#if !defined(INFIX_COMPILER_MSVC)
    case INFIX_PRIMITIVE_UINT128:
        return &_infix_type_uint128;
    case INFIX_PRIMITIVE_SINT128:
        return &_infix_type_sint128;
#endif
    case INFIX_PRIMITIVE_FLOAT:
        return &_infix_type_float;
    case INFIX_PRIMITIVE_DOUBLE:
        return &_infix_type_double;
    case INFIX_PRIMITIVE_LONG_DOUBLE:
#if defined(INFIX_COMPILER_MSVC) || (defined(INFIX_OS_WINDOWS) && defined(INFIX_COMPILER_CLANG))
        // On MSVC and macOS/Clang (sometimes), long double is an alias for double.
        // We map to the double singleton to maintain type identity.
        return &_infix_type_double;
#else
        // On MinGW and Linux, long double is distinct (16 bytes).
        // We MUST use the distinct type to handle layout and passing correctly.
        return &_infix_type_long_double;
#endif
    default:
        // Return null for any invalid primitive ID.
        return nullptr;
    }
}
/**
 * @brief Creates a static descriptor for a generic pointer (`void*`).
 * @return A pointer to the static `infix_type` descriptor. Does not need to be freed.
 */
INFIX_API c23_nodiscard infix_type * infix_type_create_pointer(void) { return &_infix_type_pointer; }
/**
 * @brief Creates a static descriptor for the `void` type.
 * @return A pointer to the static `infix_type` descriptor. Does not need to be freed.
 */
INFIX_API c23_nodiscard infix_type * infix_type_create_void(void) { return &_infix_type_void; }
/**
 * @brief A factory function to create an `infix_struct_member`.
 * @param[in] name The name of the member (optional, can be `nullptr`).
 * @param[in] type The `infix_type` of the member.
 * @param[in] offset The byte offset of the member from the start of its parent aggregate.
 * @return An initialized `infix_struct_member` object.
 */
INFIX_API infix_struct_member infix_type_create_member(const char * name, infix_type * type, size_t offset) {
    return (infix_struct_member){name, type, offset, 0, 0, false};
}
/**
 * @brief A factory function to create a bitfield `infix_struct_member`.
 * @param[in] name The name of the member.
 * @param[in] type The integer `infix_type` of the bitfield.
 * @param[in] offset The byte offset (usually 0 for automatic layout).
 * @param[in] bit_width The width in bits.
 * @return An initialized `infix_struct_member` object.
 */
INFIX_API infix_struct_member infix_type_create_bitfield_member(const char * name,
                                                                infix_type * type,
                                                                size_t offset,
                                                                uint8_t bit_width) {
    return (infix_struct_member){name, type, offset, bit_width, 0, true};
}

/**
 * @internal
 * @brief Shared logic to calculate struct layout, including bitfields and FAMs.
 * @return `true` on success, `false` if an integer overflow occurred.
 */
static bool _layout_struct(infix_type * type) {
    size_t current_byte_offset = 0;
    uint8_t current_bit_offset = 0;  // 0-7 bits used in the current byte
    size_t max_alignment = 1;

    for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
        infix_struct_member * member = &type->meta.aggregate_info.members[i];

        // 1. Handle Flexible Array Members (FAM)
        if (member->type->category == INFIX_TYPE_ARRAY && member->type->meta.array_info.is_flexible) {
            // Flush any pending bits to the next byte
            if (current_bit_offset > 0) {
                if (current_byte_offset == SIZE_MAX) {
                    _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
                    return false;
                }
                current_byte_offset++;
                current_bit_offset = 0;
            }

            // FAM aligns according to its element type.
            size_t member_align = member->type->alignment;
            if (member_align == 0)
                member_align = 1;

            size_t aligned = _infix_align_up(current_byte_offset, member_align);
            if (aligned < current_byte_offset) {
                _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
                return false;
            }
            current_byte_offset = aligned;
            member->offset = current_byte_offset;

            if (member_align > max_alignment)
                max_alignment = member_align;
            continue;  // FAM logic done
        }

        // 2. Handle Bitfields
        if (member->is_bitfield) {
            // Zero-width bitfield: force alignment to the next boundary of the declared type.
            if (member->bit_width == 0) {
                if (current_bit_offset > 0) {
                    if (current_byte_offset == SIZE_MAX) {
                        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
                        return false;
                    }
                    current_byte_offset++;
                    current_bit_offset = 0;
                }
                size_t align = member->type->alignment;
                if (align == 0)
                    align = 1;

                size_t aligned = _infix_align_up(current_byte_offset, align);
                if (aligned < current_byte_offset) {
                    _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
                    return false;
                }
                current_byte_offset = aligned;
                member->offset = current_byte_offset;
                member->bit_offset = 0;

                if (align > max_alignment)
                    max_alignment = align;
                continue;
            }

            // Standard Bitfield
            // Simplified System V packing: pack into current byte if it fits.
            if (current_bit_offset + member->bit_width > 8) {
                // Overflow: move to start of next byte
                if (current_byte_offset == SIZE_MAX) {
                    _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
                    return false;
                }
                current_byte_offset++;
                current_bit_offset = 0;
            }

            member->offset = current_byte_offset;
            member->bit_offset = current_bit_offset;
            current_bit_offset += member->bit_width;

            // If we filled the byte exactly, advance to next byte
            if (current_bit_offset == 8) {
                if (current_byte_offset == SIZE_MAX) {
                    _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
                    return false;
                }
                current_byte_offset++;
                current_bit_offset = 0;
            }

            // Update struct alignment. Bitfields typically impose the alignment of their base type.
            size_t align = member->type->alignment;
            if (align == 0)
                align = 1;
            if (align > max_alignment)
                max_alignment = align;
        }
        else {
            // 3. Standard Member

            // Flush bits first
            if (current_bit_offset > 0) {
                if (current_byte_offset == SIZE_MAX) {
                    _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
                    return false;
                }
                current_byte_offset++;
                current_bit_offset = 0;
            }

            size_t member_align = member->type->alignment;
            if (member_align == 0)
                member_align = 1;

            if (member_align > max_alignment)
                max_alignment = member_align;

            size_t aligned = _infix_align_up(current_byte_offset, member_align);
            if (aligned < current_byte_offset) {
                _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
                return false;
            }
            current_byte_offset = aligned;
            member->offset = current_byte_offset;

            if (current_byte_offset > SIZE_MAX - member->type->size) {
                _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
                return false;
            }
            current_byte_offset += member->type->size;
        }
    }

    // Final flush
    if (current_bit_offset > 0)
        current_byte_offset++;

    // If it is packed, the alignment is explicitly determined by the user (defaulting to 1
    // if not specified in the syntax). We must respect this value absolutely, ignoring
    // the natural alignment of members.
    if (type->meta.aggregate_info.is_packed)
        max_alignment = type->alignment;

    type->alignment = max_alignment;
    type->size = _infix_align_up(current_byte_offset, max_alignment);
    return true;
}
/**
 * @internal
 * @brief Common setup logic for creating aggregate types (structs and unions).
 *
 * @details This helper function reduces code duplication by handling the common tasks of:
 * 1. Validating that member types are not null.
 * 2. Allocating the main `infix_type` object from the arena.
 * 3. Allocating a new array for the members within the arena and copying the
 *    user-provided member data into it.
 *
 * @param[in] arena The arena to allocate from.
 * @param[out] out_type The output pointer for the new `infix_type`.
 * @param[out] out_arena_members The output pointer for the newly copied members array.
 * @param[in] members The user-provided array of members.
 * @param[in] num_members The number of members in the array.
 * @return `INFIX_SUCCESS` on success, or an error code on failure.
 */
static infix_status _create_aggregate_setup(infix_arena_t * arena,
                                            infix_type ** out_type,
                                            infix_struct_member ** out_arena_members,
                                            infix_struct_member * members,
                                            size_t num_members) {
    if (out_type == nullptr)
        return INFIX_ERROR_INVALID_ARGUMENT;
    // Pre-flight check: ensure all provided member types are valid.
    for (size_t i = 0; i < num_members; ++i) {
        if (members[i].type == nullptr) {
            *out_type = nullptr;
            _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_MEMBER_TYPE, 0);
            return INFIX_ERROR_INVALID_ARGUMENT;
        }
    }
    infix_type * type = infix_arena_calloc(arena, 1, sizeof(infix_type), _Alignof(infix_type));
    if (type == nullptr) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    infix_struct_member * arena_members = nullptr;
    if (num_members > 0) {
        arena_members =
            infix_arena_alloc(arena, sizeof(infix_struct_member) * num_members, _Alignof(infix_struct_member));
        if (arena_members == nullptr) {
            *out_type = nullptr;
            _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
            return INFIX_ERROR_ALLOCATION_FAILED;
        }
        infix_memcpy(arena_members, members, sizeof(infix_struct_member) * num_members);
    }
    *out_type = type;
    *out_arena_members = arena_members;
    return INFIX_SUCCESS;
}
/**
 * @brief Creates a new pointer type that points to a specific type.
 * @param[in] arena The arena to allocate the new type object in.
 * @param[out] out_type A pointer to receive the created `infix_type`.
 * @param[in] pointee_type The `infix_type` that the new pointer will point to.
 * @return `INFIX_SUCCESS` on success, or an error code on allocation failure.
 */
c23_nodiscard infix_status infix_type_create_pointer_to(infix_arena_t * arena,
                                                        infix_type ** out_type,
                                                        infix_type * pointee_type) {
    if (!out_type || !pointee_type) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_NULL_POINTER, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    infix_type * type = infix_arena_calloc(arena, 1, sizeof(infix_type), _Alignof(infix_type));
    if (type == nullptr) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    // Start by copying the layout of a generic pointer.
    *type = *infix_type_create_pointer();
    // Mark it as arena-allocated so it can be deep-copied and freed correctly.
    type->is_arena_allocated = true;
    // Set the specific pointee type.
    type->meta.pointer_info.pointee_type = pointee_type;
    *out_type = type;
    return INFIX_SUCCESS;
}
/**
 * @brief Creates a new fixed-size array type.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] element_type The type of each element in the array.
 * @param[in] num_elements The number of elements.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API c23_nodiscard infix_status infix_type_create_array(infix_arena_t * arena,
                                                             infix_type ** out_type,
                                                             infix_type * element_type,
                                                             size_t num_elements) {
    if (out_type == nullptr || element_type == nullptr) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_NULL_POINTER, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    if (element_type->size > 0 && num_elements > SIZE_MAX / element_type->size) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    infix_type * type = infix_arena_calloc(arena, 1, sizeof(infix_type), _Alignof(infix_type));
    if (type == nullptr) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    type->is_arena_allocated = true;
    type->category = INFIX_TYPE_ARRAY;
    type->meta.array_info.element_type = element_type;
    type->meta.array_info.num_elements = num_elements;
    type->meta.array_info.is_flexible = false;
    // An array's alignment is the same as its element's alignment.
    type->alignment = element_type->alignment;
    type->size = element_type->size * num_elements;
    *out_type = type;
    return INFIX_SUCCESS;
}

/**
 * @brief Creates a new flexible array member type (`[?:type]`).
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] element_type The type of the array elements.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API c23_nodiscard infix_status infix_type_create_flexible_array(infix_arena_t * arena,
                                                                      infix_type ** out_type,
                                                                      infix_type * element_type) {
    if (out_type == nullptr || element_type == nullptr) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_NULL_POINTER, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    // Flexible arrays of incomplete types (size 0) are generally not allowed.
    if (element_type->category == INFIX_TYPE_VOID || element_type->size == 0) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_MEMBER_TYPE, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    infix_type * type = infix_arena_calloc(arena, 1, sizeof(infix_type), _Alignof(infix_type));
    if (type == nullptr) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    type->is_arena_allocated = true;
    type->category = INFIX_TYPE_ARRAY;
    type->meta.array_info.element_type = element_type;
    type->meta.array_info.num_elements = 0;
    type->meta.array_info.is_flexible = true;  // Mark as flexible

    // A flexible array member itself has size 0 within the struct (it hangs off the end).
    // However, its alignment requirement affects the struct.
    type->alignment = element_type->alignment;
    type->size = 0;

    *out_type = type;
    return INFIX_SUCCESS;
}

/**
 * @brief Creates a new enum type with a specified underlying integer type.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] underlying_type The integer `infix_type` (e.g., from
 * `infix_type_create_primitive(INFIX_PRIMITIVE_SINT32)`).
 * @return `INFIX_SUCCESS` on success, or `INFIX_ERROR_INVALID_ARGUMENT` if the underlying type is not an integer.
 */
INFIX_API c23_nodiscard infix_status infix_type_create_enum(infix_arena_t * arena,
                                                            infix_type ** out_type,
                                                            infix_type * underlying_type) {
    if (out_type == nullptr || underlying_type == nullptr) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_NULL_POINTER, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    if (underlying_type->category != INFIX_TYPE_PRIMITIVE ||
        underlying_type->meta.primitive_id > INFIX_PRIMITIVE_SINT128) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_MEMBER_TYPE, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    infix_type * type = infix_arena_calloc(arena, 1, sizeof(infix_type), _Alignof(infix_type));
    if (type == nullptr) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    type->is_arena_allocated = true;
    type->category = INFIX_TYPE_ENUM;
    // An enum has the same memory layout as its underlying integer type.
    type->size = underlying_type->size;
    type->alignment = underlying_type->alignment;
    type->meta.enum_info.underlying_type = underlying_type;
    *out_type = type;
    return INFIX_SUCCESS;
}
/**
 * @brief Creates a new `_Complex` number type.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] base_type The base floating-point type (`float` or `double`).
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API c23_nodiscard infix_status infix_type_create_complex(infix_arena_t * arena,
                                                               infix_type ** out_type,
                                                               infix_type * base_type) {
    if (out_type == nullptr || base_type == nullptr || (!is_float(base_type) && !is_double(base_type))) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_NULL_POINTER, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    infix_type * type = infix_arena_calloc(arena, 1, sizeof(infix_type), _Alignof(infix_type));
    if (type == nullptr) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    type->is_arena_allocated = true;
    type->category = INFIX_TYPE_COMPLEX;
    // A complex number is simply two floating-point numbers back-to-back.
    type->size = base_type->size * 2;
    type->alignment = base_type->alignment;
    type->meta.complex_info.base_type = base_type;
    *out_type = type;
    return INFIX_SUCCESS;
}
/**
 * @brief Creates a new SIMD vector type.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] element_type The primitive type of each element.
 * @param[in] num_elements The number of elements in the vector.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API c23_nodiscard infix_status infix_type_create_vector(infix_arena_t * arena,
                                                              infix_type ** out_type,
                                                              infix_type * element_type,
                                                              size_t num_elements) {
    if (out_type == nullptr || element_type == nullptr || element_type->category != INFIX_TYPE_PRIMITIVE) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_NULL_POINTER, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    if (element_type->size > 0 && num_elements > SIZE_MAX / element_type->size) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    infix_type * type = infix_arena_calloc(arena, 1, sizeof(infix_type), _Alignof(infix_type));
    if (type == nullptr) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    type->is_arena_allocated = true;
    type->category = INFIX_TYPE_VECTOR;
    type->meta.vector_info.element_type = element_type;
    type->meta.vector_info.num_elements = num_elements;
    type->size = element_type->size * num_elements;
    // Vector alignment is typically its total size, up to a platform-specific maximum (e.g., 16 on x64).
    // This is a simplification; the ABI-specific classifiers will handle the true alignment rules.
    type->alignment = type->size > 8 ? 16 : type->size;
    *out_type = type;
    return INFIX_SUCCESS;
}
/**
 * @brief Creates a new union type from an array of members.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] members An array of `infix_struct_member` describing the union's members.
 * @param[in] num_members The number of members.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API c23_nodiscard infix_status infix_type_create_union(infix_arena_t * arena,
                                                             infix_type ** out_type,
                                                             infix_struct_member * members,
                                                             size_t num_members) {
    infix_type * type = nullptr;
    infix_struct_member * arena_members = nullptr;
    infix_status status = _create_aggregate_setup(arena, &type, &arena_members, members, num_members);
    if (status != INFIX_SUCCESS) {
        *out_type = nullptr;
        return status;
    }
    type->is_arena_allocated = true;
    type->category = INFIX_TYPE_UNION;
    type->meta.aggregate_info.members = arena_members;
    type->meta.aggregate_info.num_members = num_members;
    type->meta.aggregate_info.is_packed = false;  // Unions don't use this flag currently
    // A union's size is the size of its largest member, and its alignment is the
    // alignment of its most-aligned member.
    size_t max_size = 0;
    size_t max_alignment = 1;
    for (size_t i = 0; i < num_members; ++i) {
        arena_members[i].offset = 0;  // All union members have an offset of 0.
        if (arena_members[i].type->size > max_size)
            max_size = arena_members[i].type->size;
        if (arena_members[i].type->alignment > max_alignment)
            max_alignment = arena_members[i].type->alignment;
    }
    type->alignment = max_alignment;
    // The total size is the size of the largest member, padded up to the required alignment.
    type->size = _infix_align_up(max_size, max_alignment);
    // Overflow check
    if (type->size < max_size) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INTEGER_OVERFLOW, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    *out_type = type;
    return INFIX_SUCCESS;
}
/**
 * @brief Creates a new struct type from an array of members, calculating layout automatically.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] members An array of `infix_struct_member` describing the struct's members. The `offset` field is ignored.
 * @param[in] num_members The number of members in the array.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API c23_nodiscard infix_status infix_type_create_struct(infix_arena_t * arena,
                                                              infix_type ** out_type,
                                                              infix_struct_member * members,
                                                              size_t num_members) {
    _infix_clear_error();
    infix_type * type = nullptr;
    infix_struct_member * arena_members = nullptr;
    infix_status status = _create_aggregate_setup(arena, &type, &arena_members, members, num_members);
    if (status != INFIX_SUCCESS) {
        *out_type = nullptr;
        return status;
    }
    type->is_arena_allocated = true;
    type->category = INFIX_TYPE_STRUCT;
    type->meta.aggregate_info.members = arena_members;
    type->meta.aggregate_info.num_members = num_members;
    type->meta.aggregate_info.is_packed = false;

    // This performs a preliminary layout calculation.
    // Note: This layout may be incomplete if it contains unresolved named references or flexible arrays.
    // The final, correct layout will be computed by `_infix_type_recalculate_layout`.
    // However, we must set a preliminary size/alignment here.

    // We use the recalculate logic to do the heavy lifting, assuming a temporary arena can be made.
    // But we can't create an arena here easily if we are in a strict context.
    // So we do a simplified pass just like the old logic, ignoring complex bitfield rules for now.
    // The proper bitfield layout happens in `_infix_type_recalculate_layout`.

    for (size_t i = 0; i < num_members; ++i) {
        infix_struct_member * member = &arena_members[i];
        if (member->type->alignment == 0 && member->type->category != INFIX_TYPE_NAMED_REFERENCE &&
            !(member->type->category == INFIX_TYPE_ARRAY && member->type->meta.array_info.is_flexible)) {
            if (member->type->category != INFIX_TYPE_ARRAY) {
                *out_type = nullptr;
                _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_MEMBER_TYPE, 0);
                return INFIX_ERROR_INVALID_ARGUMENT;
            }
        }
    }

    // Calculate Layout (including bitfields and FAMs)
    if (!_layout_struct(type)) {
        *out_type = nullptr;
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    *out_type = type;
    return INFIX_SUCCESS;
}
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
INFIX_API c23_nodiscard infix_status infix_type_create_packed_struct(infix_arena_t * arena,
                                                                     infix_type ** out_type,
                                                                     size_t total_size,
                                                                     size_t alignment,
                                                                     infix_struct_member * members,
                                                                     size_t num_members) {
    if (out_type == nullptr || (num_members > 0 && members == nullptr)) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_NULL_POINTER, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    // Validate alignment is power-of-two AND within sane limits.
    if (alignment == 0 || (alignment & (alignment - 1)) != 0) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_INVALID_ALIGNMENT, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    if (alignment > INFIX_MAX_ALIGNMENT) {
        _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_TYPE_TOO_LARGE, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    infix_type * type = infix_arena_calloc(arena, 1, sizeof(infix_type), _Alignof(infix_type));
    if (type == nullptr) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    infix_struct_member * arena_members = nullptr;
    if (num_members > 0) {
        arena_members =
            infix_arena_alloc(arena, sizeof(infix_struct_member) * num_members, _Alignof(infix_struct_member));
        if (arena_members == nullptr) {
            *out_type = nullptr;
            _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
            return INFIX_ERROR_ALLOCATION_FAILED;
        }
        infix_memcpy(arena_members, members, sizeof(infix_struct_member) * num_members);
    }
    type->is_arena_allocated = true;
    type->size = total_size;
    type->alignment = alignment;
    type->category = INFIX_TYPE_STRUCT;  // Packed structs are still fundamentally structs.
    type->meta.aggregate_info.members = arena_members;
    type->meta.aggregate_info.num_members = num_members;
    type->meta.aggregate_info.is_packed = true;  // Marked as packed
    *out_type = type;
    return INFIX_SUCCESS;
}
/**
 * @brief Creates a placeholder for a named type that will be resolved later by a type registry.
 * @details This is a key component for defining recursive or mutually-dependent types.
 * The created type has a size and alignment of 0/1, which are updated during the
 * "Resolve" and "Layout" stages of the pipeline.
 * @param[in] arena The arena for allocation.
 * @param[out] out_type A pointer to receive the new `infix_type`.
 * @param[in] name The name of the type (e.g., "MyStruct").
 * @param[in] agg_cat The expected category of the aggregate (struct or union).
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_API c23_nodiscard infix_status infix_type_create_named_reference(infix_arena_t * arena,
                                                                       infix_type ** out_type,
                                                                       const char * name,
                                                                       infix_aggregate_category_t agg_cat) {
    if (out_type == nullptr || name == nullptr) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_NULL_POINTER, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    infix_type * type = infix_arena_calloc(arena, 1, sizeof(infix_type), _Alignof(infix_type));
    if (type == nullptr) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    // The name must be copied into the arena to ensure its lifetime matches the type's.
    size_t name_len = strlen(name) + 1;
    char * arena_name = infix_arena_alloc(arena, name_len, 1);
    if (arena_name == nullptr) {
        *out_type = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    infix_memcpy(arena_name, name, name_len);
    type->is_arena_allocated = true;
    type->category = INFIX_TYPE_NAMED_REFERENCE;
    type->size = 0;       // Size and alignment are unknown until resolution.
    type->alignment = 1;  // Default to 1 to be safe in preliminary layout calculations.
    type->meta.named_reference.name = arena_name;
    type->meta.named_reference.aggregate_category = agg_cat;
    *out_type = type;
    return INFIX_SUCCESS;
}
// Internal Type Graph Management
/**
 * @internal
 * @struct recalc_visited_node_t
 * @brief A node for a visited-list to prevent infinite recursion on cyclic types during layout calculation.
 *
 * @details This is a temporary structure, typically allocated on the main thread's heap,
 * used during the layout recalculation process (`_infix_type_recalculate_layout_recursive`).
 * It forms a singly-linked list that acts as a "visited set" for a depth-first
 * traversal of the type graph. Its purpose is to detect and correctly handle cycles
 * in type definitions (e.g., `struct Node { struct Node* next; };`) and prevent
 * a stack overflow from infinite recursion.
 */
typedef struct recalc_visited_node_t {
    infix_type * type; /**< The `infix_type` object that has been visited during the current traversal path. */
    struct recalc_visited_node_t * next; /**< A pointer to the next node in the visited list. */
} recalc_visited_node_t;
/**
 * @internal
 * @brief Recursively recalculates the size, alignment, and member offsets for a type graph.
 *
 * @details This function is the implementation of the **"Layout"** stage of the
 * "Parse -> Copy -> Resolve -> Layout" data pipeline. It is designed to be called
 * *after* a type graph has been fully resolved, ensuring that all
 * `INFIX_TYPE_NAMED_REFERENCE` nodes have been replaced with concrete types.
 *
 * The function performs a **post-order traversal** of the type graph. This is critical,
 * as it ensures that the layout of nested types (like a struct member) is correctly
 * calculated *before* the layout of the parent container that depends on it.
 *
 * It correctly handles cyclic graphs by using a `visited_head` linked list to track
 * nodes currently in the recursion stack, preventing infinite loops.
 *
 * @param[in,out] type The `infix_type` object to recalculate. Its `size`, `alignment`, and
 *        (if applicable) member `offset` fields are modified in-place. The function
 *        does nothing if `type` is `nullptr` or a static primitive (`is_arena_allocated` is false).
 * @param[in,out] visited_head A pointer to the head of the visited list for cycle detection.
 *        The list is modified during the traversal.
 */
static void _infix_type_recalculate_layout_recursive(infix_arena_t * temp_arena,
                                                     infix_type * type,
                                                     recalc_visited_node_t ** visited_head) {
    if (!type || !type->is_arena_allocated)
        return;  // Base case: Don't modify static singleton types.
    // Cycle detection: If we have already visited this node in the current recursion
    // path, we are in a cycle. Return immediately to break the loop. The layout of
    // this node will be calculated when the recursion unwinds to its first visit.
    for (recalc_visited_node_t * v = *visited_head; v != nullptr; v = v->next)
        if (v->type == type)
            return;
    // Allocate the memoization node from a stable temporary arena.
    recalc_visited_node_t * visited_node =
        infix_arena_alloc(temp_arena, sizeof(recalc_visited_node_t), _Alignof(recalc_visited_node_t));
    if (!visited_node)
        return;  // Cannot proceed without memory.
    visited_node->type = type;
    visited_node->next = *visited_head;
    *visited_head = visited_node;
    // Recurse into child types first (post-order traversal).
    switch (type->category) {
    case INFIX_TYPE_POINTER:
        _infix_type_recalculate_layout_recursive(temp_arena, type->meta.pointer_info.pointee_type, visited_head);
        break;
    case INFIX_TYPE_ARRAY:
        _infix_type_recalculate_layout_recursive(temp_arena, type->meta.array_info.element_type, visited_head);
        break;
    case INFIX_TYPE_STRUCT:
    case INFIX_TYPE_UNION:
        for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
            _infix_type_recalculate_layout_recursive(
                temp_arena, type->meta.aggregate_info.members[i].type, visited_head);
        }
        break;
    default:
        break;  // Other types have no child types to recurse into.
    }
    // After children are updated, recalculate this type's layout.
    if (type->category == INFIX_TYPE_STRUCT)
        _layout_struct(type);
    else if (type->category == INFIX_TYPE_UNION) {
        size_t max_size = 0;
        size_t max_alignment = 1;
        for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
            infix_type * member_type = type->meta.aggregate_info.members[i].type;
            if (member_type->size > max_size)
                max_size = member_type->size;
            if (member_type->alignment > max_alignment)
                max_alignment = member_type->alignment;
        }
        type->alignment = max_alignment;
        type->size = _infix_align_up(max_size, max_alignment);
    }
    else if (type->category == INFIX_TYPE_ARRAY) {
        // Flexible arrays have size 0 but inherit alignment.
        // Fixed arrays calculate size normally.
        if (type->meta.array_info.is_flexible) {
            type->alignment = type->meta.array_info.element_type->alignment;
            type->size = 0;
        }
        else {
            type->alignment = type->meta.array_info.element_type->alignment;
            type->size = type->meta.array_info.element_type->size * type->meta.array_info.num_elements;
        }
    }
}
/**
 * @internal
 * @brief Public-internal wrapper for the recursive layout recalculation function.
 *
 * @details This function serves as the entry point for the "Layout" stage. It initializes
 * the cycle detection mechanism and starts the recursive traversal of the type graph.
 *
 * @param[in,out] type The root of the type graph to recalculate. The graph is modified in-place.
 */
void _infix_type_recalculate_layout(infix_type * type) {
    // Create a temporary arena solely for the visited list's lifetime.
    infix_arena_t * temp_arena = infix_arena_create(1024);
    if (!temp_arena)
        return;
    recalc_visited_node_t * visited_head = nullptr;
    _infix_type_recalculate_layout_recursive(temp_arena, type, &visited_head);
    infix_arena_destroy(temp_arena);
}
/**
 * @internal
 * @struct memo_node_t
 * @brief A memoization node for the deep copy algorithm.
 * @details This temporary structure maps a source `infix_type` address to its
 * newly copied destination address. It is used to prevent re-copying the same
 * object and to correctly reconstruct cyclic type graphs.
 */
typedef struct memo_node_t {
    const infix_type * src;    /**< The original type object's address. */
    infix_type * dest;         /**< The copied type object's address. */
    struct memo_node_t * next; /**< The next node in the memoization list. */
} memo_node_t;
/**
 * @internal
 * @brief Recursively performs a deep copy of a type graph into a destination arena.
 *
 * @details This function is the implementation of the **"Copy"** stage of the data pipeline.
 * It is essential for creating self-contained trampoline objects and for safely
 * managing type lifecycles. It uses memoization to correctly handle cycles and shared
 * type objects, ensuring that each source type is copied exactly once.
 *
 * @param dest_arena The destination arena for the new type graph.
 * @param src_type The source type to copy.
 * @param memo_head A pointer to the head of the memoization list.
 * @return A pointer to the newly created copy in `dest_arena`, or `nullptr` on failure.
 */
static infix_type * _copy_type_graph_to_arena_recursive(infix_arena_t * dest_arena,
                                                        const infix_type * src_type,
                                                        memo_node_t ** memo_head) {
    if (src_type == nullptr)
        return nullptr;
    // If the source type lives in the same arena as our destination, we can safely share the pointer instead of
    // performing a deep copy.
    if (src_type->arena == dest_arena)
        return (infix_type *)src_type;
    // Base case: Static types don't need to be copied; return the singleton pointer.
    if (!src_type->is_arena_allocated)
        return (infix_type *)src_type;
    // Check memoization table: if we've already copied this node, return the existing copy.
    // This correctly handles cycles and shared sub-graphs.
    for (memo_node_t * node = *memo_head; node != NULL; node = node->next)
        if (node->src == src_type)
            return node->dest;
    // Allocate the new type object in the destination arena.
    infix_type * dest_type = infix_arena_calloc(dest_arena, 1, sizeof(infix_type), _Alignof(infix_type));
    if (dest_type == nullptr)
        return nullptr;
    // Add this new pair to the memoization table BEFORE recursing. This is crucial
    // for handling cycles: the recursive call will find this entry and return `dest_type`.
    memo_node_t * new_memo_node = infix_arena_alloc(dest_arena, sizeof(memo_node_t), _Alignof(memo_node_t));
    if (!new_memo_node)
        return nullptr;
    new_memo_node->src = src_type;
    new_memo_node->dest = dest_type;
    new_memo_node->next = *memo_head;
    *memo_head = new_memo_node;
    // Perform a shallow copy of the main struct, then recurse to deep copy child pointers.
    *dest_type = *src_type;
    dest_type->is_arena_allocated = true;
    dest_type->is_incomplete = src_type->is_incomplete;
    dest_type->arena = dest_arena;  // The new type now belongs to the destination arena.
    // Deep copy the semantic name string, if it exists.
    if (src_type->name) {
        size_t name_len = strlen(src_type->name) + 1;
        char * dest_name = infix_arena_alloc(dest_arena, name_len, 1);
        if (!dest_name)
            return nullptr;  // Allocation failed
        infix_memcpy((void *)dest_name, src_type->name, name_len);
        dest_type->name = dest_name;
    }
    switch (src_type->category) {
    case INFIX_TYPE_POINTER:
        dest_type->meta.pointer_info.pointee_type =
            _copy_type_graph_to_arena_recursive(dest_arena, src_type->meta.pointer_info.pointee_type, memo_head);
        break;
    case INFIX_TYPE_ARRAY:
        dest_type->meta.array_info.element_type =
            _copy_type_graph_to_arena_recursive(dest_arena, src_type->meta.array_info.element_type, memo_head);
        // Explicitly copy the flexible flag to ensure it persists.
        dest_type->meta.array_info.is_flexible = src_type->meta.array_info.is_flexible;
        break;
    case INFIX_TYPE_STRUCT:
    case INFIX_TYPE_UNION:
        if (src_type->meta.aggregate_info.num_members > 0) {
            // Copy the members array itself.
            size_t members_size = sizeof(infix_struct_member) * src_type->meta.aggregate_info.num_members;
            dest_type->meta.aggregate_info.members =
                infix_arena_alloc(dest_arena, members_size, _Alignof(infix_struct_member));
            if (dest_type->meta.aggregate_info.members == nullptr)
                return nullptr;
            dest_type->meta.aggregate_info.is_packed = src_type->meta.aggregate_info.is_packed;  // Copy packed flag
            // Now, recurse for each member's type and copy its name.
            for (size_t i = 0; i < src_type->meta.aggregate_info.num_members; ++i) {
                dest_type->meta.aggregate_info.members[i] = src_type->meta.aggregate_info.members[i];
                dest_type->meta.aggregate_info.members[i].type = _copy_type_graph_to_arena_recursive(
                    dest_arena, src_type->meta.aggregate_info.members[i].type, memo_head);
                const char * src_name = src_type->meta.aggregate_info.members[i].name;
                if (src_name) {
                    size_t name_len = strlen(src_name) + 1;
                    char * dest_name = infix_arena_alloc(dest_arena, name_len, 1);
                    if (!dest_name)
                        return nullptr;
                    infix_memcpy((void *)dest_name, src_name, name_len);
                    dest_type->meta.aggregate_info.members[i].name = dest_name;
                }
                // Copy bitfield properties
                dest_type->meta.aggregate_info.members[i].bit_width =
                    src_type->meta.aggregate_info.members[i].bit_width;
                dest_type->meta.aggregate_info.members[i].bit_offset =
                    src_type->meta.aggregate_info.members[i].bit_offset;
                dest_type->meta.aggregate_info.members[i].is_bitfield =
                    src_type->meta.aggregate_info.members[i].is_bitfield;
            }
        }
        break;
    case INFIX_TYPE_NAMED_REFERENCE:
        {
            const char * src_name = src_type->meta.named_reference.name;
            if (src_name) {
                size_t name_len = strlen(src_name) + 1;
                char * dest_name = infix_arena_alloc(dest_arena, name_len, 1);
                if (!dest_name)
                    return nullptr;
                infix_memcpy((void *)dest_name, src_name, name_len);
                dest_type->meta.named_reference.name = dest_name;
            }
            break;
        }
    case INFIX_TYPE_REVERSE_TRAMPOLINE:
        dest_type->meta.func_ptr_info.return_type =
            _copy_type_graph_to_arena_recursive(dest_arena, src_type->meta.func_ptr_info.return_type, memo_head);
        if (src_type->meta.func_ptr_info.num_args > 0) {
            size_t args_size = sizeof(infix_function_argument) * src_type->meta.func_ptr_info.num_args;
            dest_type->meta.func_ptr_info.args =
                infix_arena_alloc(dest_arena, args_size, _Alignof(infix_function_argument));
            if (dest_type->meta.func_ptr_info.args == nullptr)
                return nullptr;
            for (size_t i = 0; i < src_type->meta.func_ptr_info.num_args; ++i) {
                dest_type->meta.func_ptr_info.args[i] = src_type->meta.func_ptr_info.args[i];
                dest_type->meta.func_ptr_info.args[i].type = _copy_type_graph_to_arena_recursive(
                    dest_arena, src_type->meta.func_ptr_info.args[i].type, memo_head);
                const char * src_name = src_type->meta.func_ptr_info.args[i].name;
                if (src_name) {
                    size_t name_len = strlen(src_name) + 1;
                    char * dest_name = infix_arena_alloc(dest_arena, name_len, 1);
                    if (!dest_name)
                        return nullptr;
                    infix_memcpy((void *)dest_name, src_name, name_len);
                    dest_type->meta.func_ptr_info.args[i].name = dest_name;
                }
            }
        }
        break;
    case INFIX_TYPE_ENUM:
        dest_type->meta.enum_info.underlying_type =
            _copy_type_graph_to_arena_recursive(dest_arena, src_type->meta.enum_info.underlying_type, memo_head);
        break;
    case INFIX_TYPE_COMPLEX:
        dest_type->meta.complex_info.base_type =
            _copy_type_graph_to_arena_recursive(dest_arena, src_type->meta.complex_info.base_type, memo_head);
        break;
    case INFIX_TYPE_VECTOR:
        dest_type->meta.vector_info.element_type =
            _copy_type_graph_to_arena_recursive(dest_arena, src_type->meta.vector_info.element_type, memo_head);
        break;
    default:
        // Other types like primitives have no child pointers to copy.
        break;
    }
    return dest_type;
}
/**
 * @internal
 * @brief Public wrapper for the recursive type graph copy function.
 * @param dest_arena The destination arena.
 * @param src_type The source type graph to copy.
 * @return A pointer to the new copy, or `nullptr` on failure.
 */
infix_type * _copy_type_graph_to_arena(infix_arena_t * dest_arena, const infix_type * src_type) {
    memo_node_t * memo_head = nullptr;
    return _copy_type_graph_to_arena_recursive(dest_arena, src_type, &memo_head);
}
/**
 * @internal
 * @struct estimate_visited_node_t
 * @brief A node for a "visited list" to prevent infinite recursion during size estimation.
 */
typedef struct estimate_visited_node_t {
    const infix_type * type;               /**< The type object that has been visited. */
    struct estimate_visited_node_t * next; /**< The next node in the visited list. */
} estimate_visited_node_t;
/**
 * @internal
 * @brief Recursively estimates the memory required to deep-copy a type graph.
 * @details This function performs a depth-first traversal of the type graph, summing
 *          the size of all arena-allocated objects that would be created by
 *          `_copy_type_graph_to_arena`. It uses a visited list to correctly handle
 *          cycles and shared subgraphs, preventing double-counting and infinite recursion.
 * @param temp_arena A temporary arena used to allocate the visited list nodes.
 * @param type The type graph to estimate.
 * @param visited_head The head of the visited list for cycle detection.
 * @return The estimated size in bytes.
 */
static size_t _estimate_graph_size_recursive(infix_arena_t * temp_arena,
                                             const infix_type * type,
                                             estimate_visited_node_t ** visited_head) {
    if (!type || !type->is_arena_allocated)
        return 0;
    // Cycle detection: if we've seen this node, it's already accounted for.
    for (estimate_visited_node_t * v = *visited_head; v != NULL; v = v->next)
        if (v->type == type)
            return 0;
    // Add this node to the visited list before recursing.
    estimate_visited_node_t * visited_node =
        infix_arena_alloc(temp_arena, sizeof(estimate_visited_node_t), _Alignof(estimate_visited_node_t));
    if (!visited_node) {
        // On allocation failure, we can't proceed with estimation. Return a large
        // number to ensure the caller allocates a fallback-sized arena.
        return 65536;
    }
    visited_node->type = type;
    visited_node->next = *visited_head;
    *visited_head = visited_node;
    // The size includes the type object itself, a memoization node, and the name string if it exists.
    size_t total_size = sizeof(infix_type) + sizeof(memo_node_t);
    if (type->name)
        total_size += strlen(type->name) + 1;
    switch (type->category) {
    case INFIX_TYPE_POINTER:
        total_size += _estimate_graph_size_recursive(temp_arena, type->meta.pointer_info.pointee_type, visited_head);
        break;
    case INFIX_TYPE_ARRAY:
        total_size += _estimate_graph_size_recursive(temp_arena, type->meta.array_info.element_type, visited_head);
        break;
    case INFIX_TYPE_STRUCT:
    case INFIX_TYPE_UNION:
        if (type->meta.aggregate_info.num_members > 0) {
            total_size += sizeof(infix_struct_member) * type->meta.aggregate_info.num_members;
            for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
                const infix_struct_member * member = &type->meta.aggregate_info.members[i];
                if (member->name)
                    total_size += strlen(member->name) + 1;
                total_size += _estimate_graph_size_recursive(temp_arena, member->type, visited_head);
            }
        }
        break;
    case INFIX_TYPE_NAMED_REFERENCE:
        if (type->meta.named_reference.name)
            total_size += strlen(type->meta.named_reference.name) + 1;
        break;
    case INFIX_TYPE_REVERSE_TRAMPOLINE:
        total_size += _estimate_graph_size_recursive(temp_arena, type->meta.func_ptr_info.return_type, visited_head);
        if (type->meta.func_ptr_info.num_args > 0) {
            total_size += sizeof(infix_function_argument) * type->meta.func_ptr_info.num_args;
            for (size_t i = 0; i < type->meta.func_ptr_info.num_args; ++i) {
                const infix_function_argument * arg = &type->meta.func_ptr_info.args[i];
                if (arg->name)
                    total_size += strlen(arg->name) + 1;
                total_size += _estimate_graph_size_recursive(temp_arena, arg->type, visited_head);
            }
        }
        break;
    case INFIX_TYPE_ENUM:
        total_size += _estimate_graph_size_recursive(temp_arena, type->meta.enum_info.underlying_type, visited_head);
        break;
    case INFIX_TYPE_COMPLEX:
        total_size += _estimate_graph_size_recursive(temp_arena, type->meta.complex_info.base_type, visited_head);
        break;
    case INFIX_TYPE_VECTOR:
        total_size += _estimate_graph_size_recursive(temp_arena, type->meta.vector_info.element_type, visited_head);
        break;
    default:
        break;
    }
    return total_size;
}
/**
 * @internal
 * @brief Public wrapper for the recursive size estimation function.
 * @param temp_arena A temporary arena for the estimator's bookkeeping.
 * @param type The root of the type graph to estimate.
 * @return The estimated size in bytes.
 */
size_t _infix_estimate_graph_size(infix_arena_t * temp_arena, const infix_type * type) {
    if (!temp_arena || !type)
        return 0;
    estimate_visited_node_t * visited_head = nullptr;
    return _estimate_graph_size_recursive(temp_arena, type, &visited_head);
}
// Public API: Introspection Functions
/**
 * @brief Gets the semantic alias of a type, if one exists.
 * @param[in] type The type object to inspect.
 * @return The name of the type if it was created from a registry alias (e.g., "MyInt"), or `nullptr` if the type is
 * anonymous.
 */
INFIX_API c23_nodiscard const char * infix_type_get_name(const infix_type * type) {
    if (type == nullptr)
        return nullptr;
    return type->name;
}
/**
 * @brief Gets the fundamental category of a type.
 * @param[in] type The type object to inspect.
 * @return The `infix_type_category` enum value, or -1 if `type` is `nullptr`.
 */
INFIX_API c23_nodiscard infix_type_category infix_type_get_category(const infix_type * type) {
    return type ? type->category : (infix_type_category)-1;
}
/**
 * @brief Gets the size of a type in bytes.
 * @param[in] type The type object to inspect.
 * @return The size in bytes, or 0 if `type` is `nullptr`.
 */
INFIX_API c23_nodiscard size_t infix_type_get_size(const infix_type * type) { return type ? type->size : 0; }
/**
 * @brief Gets the alignment requirement of a type in bytes.
 * @param[in] type The type object to inspect.
 * @return The alignment in bytes, or 0 if `type` is `nullptr`.
 */
INFIX_API c23_nodiscard size_t infix_type_get_alignment(const infix_type * type) { return type ? type->alignment : 0; }
/**
 * @brief Gets the number of members in a struct or union type.
 * @param[in] type The aggregate type object to inspect. Must have category
 * `INFIX_TYPE_STRUCT` or `INFIX_TYPE_UNION`.
 * @return The number of members, or 0 if the type is not a struct or union.
 */
INFIX_API c23_nodiscard size_t infix_type_get_member_count(const infix_type * type) {
    if (!type || (type->category != INFIX_TYPE_STRUCT && type->category != INFIX_TYPE_UNION))
        return 0;
    return type->meta.aggregate_info.num_members;
}
/**
 * @brief Gets a specific member from a struct or union type.
 * @param[in] type The aggregate type object to inspect.
 * @param[in] index The zero-based index of the member.
 * @return A pointer to the `infix_struct_member`, or `nullptr` if the index is out of bounds or the type is invalid.
 */
INFIX_API c23_nodiscard const infix_struct_member * infix_type_get_member(const infix_type * type, size_t index) {
    if (!type || (type->category != INFIX_TYPE_STRUCT && type->category != INFIX_TYPE_UNION) ||
        index >= type->meta.aggregate_info.num_members)
        return nullptr;
    return &type->meta.aggregate_info.members[index];
}
/**
 * @brief Gets the name of a specific argument from a function type.
 * @param[in] func_type The function type object to inspect (must have category `INFIX_TYPE_REVERSE_TRAMPOLINE`).
 * @param[in] index The zero-based index of the argument.
 * @return The name of the argument as a string, or `nullptr` if the argument is anonymous or the index is out of
 * bounds.
 */
INFIX_API c23_nodiscard const char * infix_type_get_arg_name(const infix_type * func_type, size_t index) {
    if (!func_type || func_type->category != INFIX_TYPE_REVERSE_TRAMPOLINE ||
        index >= func_type->meta.func_ptr_info.num_args)
        return nullptr;
    return func_type->meta.func_ptr_info.args[index].name;
}
/**
 * @brief Gets the type of a specific argument from a function type.
 * @param[in] func_type The function type object to inspect.
 * @param[in] index The zero-based index of the argument.
 * @return A pointer to the argument's `infix_type`, or `nullptr` if the index is out of bounds.
 */
INFIX_API c23_nodiscard const infix_type * infix_type_get_arg_type(const infix_type * func_type, size_t index) {
    if (!func_type || func_type->category != INFIX_TYPE_REVERSE_TRAMPOLINE ||
        index >= func_type->meta.func_ptr_info.num_args)
        return nullptr;
    return func_type->meta.func_ptr_info.args[index].type;
}
/**
 * @brief Gets the total number of arguments for a forward trampoline.
 * @param[in] trampoline The trampoline handle.
 * @return The number of arguments, or 0 if `trampoline` is `nullptr`.
 */
INFIX_API c23_nodiscard size_t infix_forward_get_num_args(const infix_forward_t * trampoline) {
    return trampoline ? trampoline->num_args : 0;
}
/**
 * @brief Gets the number of fixed (non-variadic) arguments for a forward trampoline.
 * @param[in] trampoline The trampoline handle.
 * @return The number of fixed arguments, or 0 if `trampoline` is `nullptr`.
 */
INFIX_API c23_nodiscard size_t infix_forward_get_num_fixed_args(const infix_forward_t * trampoline) {
    return trampoline ? trampoline->num_fixed_args : 0;
}
/**
 * @brief Gets the return type for a forward trampoline.
 * @param[in] trampoline The trampoline handle.
 * @return A pointer to the `infix_type` for the return value, or `nullptr` if `trampoline` is `nullptr`.
 */
INFIX_API c23_nodiscard const infix_type * infix_forward_get_return_type(const infix_forward_t * trampoline) {
    return trampoline ? trampoline->return_type : nullptr;
}
/**
 * @brief Gets the type of a specific argument for a forward trampoline.
 * @param[in] trampoline The trampoline handle.
 * @param[in] index The zero-based index of the argument.
 * @return A pointer to the `infix_type`, or `nullptr` if the index is out of bounds or `trampoline` is `nullptr`.
 */
INFIX_API c23_nodiscard const infix_type * infix_forward_get_arg_type(const infix_forward_t * trampoline,
                                                                      size_t index) {
    if (!trampoline || index >= trampoline->num_args)
        return nullptr;
    return trampoline->arg_types[index];
}
/**
 * @brief Gets the total number of arguments for a reverse trampoline.
 * @param[in] trampoline The trampoline context handle.
 * @return The number of arguments, or 0 if `trampoline` is `nullptr`.
 */
INFIX_API c23_nodiscard size_t infix_reverse_get_num_args(const infix_reverse_t * trampoline) {
    return trampoline ? trampoline->num_args : 0;
}
/**
 * @brief Gets the number of fixed (non-variadic) arguments for a reverse trampoline.
 * @param[in] trampoline The trampoline context handle.
 * @return The number of fixed arguments, or 0 if `trampoline` is `nullptr`.
 */
INFIX_API c23_nodiscard size_t infix_reverse_get_num_fixed_args(const infix_reverse_t * trampoline) {
    return trampoline ? trampoline->num_fixed_args : 0;
}
/**
 * @brief Gets the return type for a reverse trampoline.
 * @param[in] trampoline The trampoline context handle.
 * @return A pointer to the `infix_type` for the return value, or `nullptr` if `trampoline` is `nullptr`.
 */
INFIX_API c23_nodiscard const infix_type * infix_reverse_get_return_type(const infix_reverse_t * trampoline) {
    return trampoline ? trampoline->return_type : nullptr;
}
/**
 * @brief Gets the type of a specific argument for a reverse trampoline.
 * @param[in] trampoline The trampoline context handle.
 * @param[in] index The zero-based index of the argument.
 * @return A pointer to the `infix_type`, or `nullptr` if the index is out of bounds or `trampoline` is `nullptr`.
 */
INFIX_API c23_nodiscard const infix_type * infix_reverse_get_arg_type(const infix_reverse_t * trampoline,
                                                                      size_t index) {
    if (!trampoline || index >= trampoline->num_args)
        return nullptr;
    return trampoline->arg_types[index];
}
