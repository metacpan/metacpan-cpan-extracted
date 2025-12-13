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
 * @file signature.c
 * @brief Implements the `infix` signature string parser and type printer.
 * @ingroup internal_core
 *
 * @details This module is responsible for two key functionalities that form the
 * user-facing API of the library:
 *
 * 1.  **Parsing:** It contains a hand-written recursive descent parser that transforms a
 *     human-readable signature string (e.g., `"({int, *char}) -> void"`) into an
 *     unresolved `infix_type` object graph. This is the **"Parse"** stage of the core
 *     data pipeline. The internal entry point for the "Parse" stage is `_infix_parse_type_internal`.
 *
 * 2.  **Printing:** It provides functions to serialize a fully resolved `infix_type`
 *     graph back into a canonical signature string. This is crucial for introspection,
 *     debugging, and verifying the library's understanding of a type.
 *
 * The public functions `infix_type_from_signature` and `infix_signature_parse`
 * are high-level orchestrators. They manage the entire **"Parse -> Copy -> Resolve -> Layout"**
 * pipeline, providing the user with a fully validated, self-contained, and ready-to-use
 * type object that is safe to use for the lifetime of its returned arena.
 */
#include "common/infix_internals.h"
#include <ctype.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
/** @internal A thread-local pointer to the full signature string being parsed, used by `error.c` for rich error
 * reporting. */
extern INFIX_TLS const char * g_infix_last_signature_context;
/** @internal A safeguard against stack overflows from malicious or deeply nested signatures (e.g., `{{{{...}}}}`). */
#define MAX_RECURSION_DEPTH 32
/**
 * @internal
 * @struct parser_state
 * @brief Holds the complete state of the recursive descent parser during a single parse operation.
 */
typedef struct {
    const char * p;        /**< The current read position (cursor) in the signature string. */
    const char * start;    /**< The beginning of the signature string, used for calculating error positions. */
    infix_arena_t * arena; /**< The temporary arena for allocating the raw, unresolved type graph. */
    int depth;             /**< The current recursion depth, to prevent stack overflows. */
} parser_state;
// Forward Declarations for Mutually Recursive Parser Functions
static infix_type * parse_type(parser_state * state);
static infix_status parse_function_signature_details(parser_state * state,
                                                     infix_type ** out_ret_type,
                                                     infix_function_argument ** out_args,
                                                     size_t * out_num_args,
                                                     size_t * out_num_fixed_args);
// Parser Helper Functions
/**
 * @internal
 * @brief Sets a detailed parser error, capturing the current position in the string.
 * @param[in,out] state The current parser state.
 * @param[in] code The error code to set.
 */
static void set_parser_error(parser_state * state, infix_error_code_t code) {
    _infix_set_error(INFIX_CATEGORY_PARSER, code, (size_t)(state->p - state->start));
}
/**
 * @internal
 * @brief Advances the parser's cursor past any whitespace or C-style line comments.
 * @param[in,out] state The parser state to modify.
 */
static void skip_whitespace(parser_state * state) {
    while (true) {
        while (isspace((unsigned char)*state->p))
            state->p++;
        if (*state->p == '#')  // C-style line comments
            while (*state->p != '\n' && *state->p != '\0')
                state->p++;
        else
            break;
    }
}
/**
 * @internal
 * @brief Parses an unsigned integer from the string, used for array/vector sizes.
 * @param[in,out] state The parser state.
 * @param[out] out_val A pointer to store the parsed value.
 * @return `true` on success, `false` on failure.
 */
static bool parse_size_t(parser_state * state, size_t * out_val) {
    const char * start = state->p;
    char * end;
    unsigned long long val = strtoull(start, &end, 10);
    if (end == start) {
        set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
        return false;
    }
    *out_val = (size_t)val;
    state->p = end;
    return true;
}
/**
 * @internal
 * @brief Parses a C-style identifier from the string.
 * @details This is used for member names, named types, and function argument names.
 * It handles simple identifiers (`my_var`) and C++-style namespaces (`NS::Name`).
 * @param[in,out] state The parser state.
 * @return An arena-allocated string for the identifier, or `nullptr` on failure.
 */
static const char * parse_identifier(parser_state * state) {
    skip_whitespace(state);
    const char * start = state->p;
    if (!isalpha((unsigned char)*start) && *start != '_')
        return nullptr;
    while (isalnum((unsigned char)*state->p) || *state->p == '_' || *state->p == ':') {
        if (*state->p == ':' && state->p[1] != ':')
            break;  // A single ':' is not part of an identifier.
        if (*state->p == ':')
            state->p++;  // Consume first ':' of '::'
        state->p++;
    }
    size_t len = state->p - start;
    if (len == 0)
        return nullptr;
    char * name = infix_arena_calloc(state->arena, 1, len + 1, 1);
    if (!name) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, (size_t)(state->p - state->start));
        return nullptr;
    }
    infix_memcpy((void *)name, start, len);
    name[len] = '\0';
    return name;
}
/**
 * @internal
 * @brief Consumes a specific keyword from the string (e.g., "int", "struct").
 * @details This function is careful to match whole words only. For example, it will
 * successfully consume "int" from "int x", but will fail on "integer", preventing
 * false positives.
 * @param[in,out] state The parser state.
 * @param[in] keyword The keyword to consume.
 * @return `true` if the keyword was successfully consumed.
 */
static bool consume_keyword(parser_state * state, const char * keyword) {
    skip_whitespace(state);
    size_t len = strlen(keyword);
    if (strncmp(state->p, keyword, len) == 0) {
        // Ensure it's not a prefix of a longer word (e.g., "int" vs "integer").
        if (isalnum((unsigned char)state->p[len]) || state->p[len] == '_')
            return false;
        state->p += len;
        skip_whitespace(state);
        return true;
    }
    return false;
}
/**
 * @internal
 * @brief Parses an optional named prefix, like `name: type`.
 * @details If a valid identifier is found followed by a colon, the name is returned
 * and the parser's cursor is advanced past the colon. If not, the parser state is
 * rewound to its original position (backtracking) and `nullptr` is returned.
 * @param[in,out] state The parser state.
 * @return An arena-allocated string for the name, or `nullptr` if no `name:` prefix is present.
 */
static const char * parse_optional_name_prefix(parser_state * state) {
    skip_whitespace(state);
    // Save the current position in case we need to backtrack.
    const char * p_before = state->p;
    const char * name = parse_identifier(state);
    if (name) {
        skip_whitespace(state);
        if (*state->p == ':') {  // Found "identifier:", so consume the colon and return the name.
            state->p++;
            return name;
        }
    }
    // If it wasn't a `name:`, backtrack to the original position.
    state->p = p_before;
    return nullptr;
}
/**
 * @internal
 * @brief A lookahead function to disambiguate a grouped type `(type)` from a
 *        function signature `(...) -> type`.
 *
 * @details This is a classic parser "lookahead". When the parser encounters an opening
 * parenthesis `(`, it calls this function to peek ahead in the string without
 * consuming any input. By scanning for a matching `)` and checking if it is
 * followed by a `->` token, it can decide whether to parse the content as a
 * single, parenthesized type or as a full function signature.
 *
 * @param[in] state The current parser state (read-only).
 * @return `true` if a `->` token follows the closing parenthesis.
 */
static bool is_function_signature_ahead(const parser_state * state) {
    const char * p = state->p;
    if (*p != '(')
        return false;
    p++;
    // Find the matching ')' by tracking nesting depth.
    int depth = 1;
    while (*p != '\0' && depth > 0) {
        if (*p == '(')
            depth++;
        else if (*p == ')')
            depth--;
        p++;
    }
    if (depth != 0)
        return false;  // Mismatched parentheses.
    // Skip any whitespace or comments after the ')'
    while (isspace((unsigned char)*p) || *p == '#') {
        if (*p == '#')
            while (*p != '\n' && *p != '\0')
                p++;
        else
            p++;
    }
    // Check for the '->' arrow.
    return (p[0] == '-' && p[1] == '>');
}
// Aggregate Parsing Logic
/**
 * @internal
 * @brief Parses a comma-separated list of members for a struct or union.
 * @details This function is generic and handles the body of both `{...}` and `<...>` blocks.
 * It uses a temporary linked list to collect members since the count is not known
 * in advance, then converts the list to a flat array in the arena.
 * @param[in,out] state The parser state.
 * @param[in] end_char The character that terminates the list (e.g., '}' or '>').
 * @param[out] out_num_members A pointer to store the number of members found.
 * @return An arena-allocated array of `infix_struct_member`s, or `nullptr` on failure or if empty.
 */
static infix_struct_member * parse_aggregate_members(parser_state * state, char end_char, size_t * out_num_members) {
    // Use a temporary linked list to collect members, as the count is unknown in a single pass.
    typedef struct member_node {
        infix_struct_member m;
        struct member_node * next;
    } member_node;
    member_node *head = nullptr, *tail = nullptr;
    size_t num_members = 0;
    skip_whitespace(state);
    if (*state->p != end_char) {
        while (1) {
            const char * p_before_member = state->p;
            const char * name = parse_optional_name_prefix(state);
            // Disallow an empty member definition like `name,` without a type.
            if (name && (*state->p == ',' || *state->p == end_char)) {
                state->p = p_before_member + strlen(name);  // Position error at end of name
                set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
                return nullptr;
            }
            infix_type * member_type = parse_type(state);
            if (!member_type)
                return nullptr;
            // Structs and unions cannot have `void` members.
            if (member_type->category == INFIX_TYPE_VOID) {
                set_parser_error(state, INFIX_CODE_INVALID_MEMBER_TYPE);
                return nullptr;
            }

            // Check for bitfield syntax: "name: type : width"
            uint8_t bit_width = 0;
            bool is_bitfield = false;
            skip_whitespace(state);
            if (*state->p == ':') {
                state->p++;  // Consume ':'
                skip_whitespace(state);
                size_t width_val = 0;
                if (!parse_size_t(state, &width_val))
                    return nullptr;  // Error set by parse_size_t
                if (width_val > 255) {
                    set_parser_error(state, INFIX_CODE_TYPE_TOO_LARGE);
                    return nullptr;
                }
                bit_width = (uint8_t)width_val;
                is_bitfield = true;
            }

            member_node * node = infix_arena_calloc(state->arena, 1, sizeof(member_node), _Alignof(member_node));
            if (!node) {
                _infix_set_error(
                    INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, (size_t)(state->p - state->start));
                return nullptr;
            }
            // The member offset is not calculated here; it will be done later
            // by `infix_type_create_struct` or `_infix_type_recalculate_layout`.
            if (is_bitfield)
                node->m = infix_type_create_bitfield_member(name, member_type, 0, bit_width);
            else
                node->m = infix_type_create_member(name, member_type, 0);

            node->next = nullptr;

            if (!head)
                head = tail = node;
            else {
                tail->next = node;
                tail = node;
            }
            num_members++;
            // Check for next token: ',' or end_char
            skip_whitespace(state);
            if (*state->p == ',') {
                state->p++;  // Consume comma.
                skip_whitespace(state);
                // A trailing comma like `{int,}` is a syntax error.
                if (*state->p == end_char) {
                    set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
                    return nullptr;
                }
            }
            else if (*state->p == end_char)
                break;
            else {  // Unexpected token (e.g., missing comma).
                if (*state->p == '\0') {
                    set_parser_error(state, INFIX_CODE_UNTERMINATED_AGGREGATE);
                    return nullptr;
                }
                set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
                return nullptr;
            }
        }
    }
    *out_num_members = num_members;
    if (num_members == 0)
        return nullptr;
    // Convert the temporary linked list to a flat array in the arena.
    infix_struct_member * members =
        infix_arena_calloc(state->arena, num_members, sizeof(infix_struct_member), _Alignof(infix_struct_member));
    if (!members) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, (size_t)(state->p - state->start));
        return nullptr;
    }
    member_node * current = head;
    for (size_t i = 0; i < num_members; i++) {
        members[i] = current->m;
        current = current->next;
    }
    return members;
}
/**
 * @internal
 * @brief Parses a struct (`{...}`) or union (`<...>`).
 * @param[in,out] state The parser state.
 * @param[in] start_char The opening delimiter ('{' or '<').
 * @param[in] end_char The closing delimiter ('}' or '>').
 * @return A pointer to the new `infix_type`, or `nullptr` on failure.
 */
static infix_type * parse_aggregate(parser_state * state, char start_char, char end_char) {
    if (state->depth >= MAX_RECURSION_DEPTH) {
        set_parser_error(state, INFIX_CODE_RECURSION_DEPTH_EXCEEDED);
        return nullptr;
    }
    state->depth++;
    if (*state->p != start_char) {
        set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
        state->depth--;
        return nullptr;
    }
    state->p++;
    size_t num_members = 0;
    infix_struct_member * members = parse_aggregate_members(state, end_char, &num_members);
    // If member parsing failed, an error is already set. Propagate the failure.
    if (!members && infix_get_last_error().code != INFIX_CODE_SUCCESS) {
        state->depth--;
        return nullptr;
    }
    if (*state->p != end_char) {
        set_parser_error(state, INFIX_CODE_UNTERMINATED_AGGREGATE);
        state->depth--;
        return nullptr;
    }
    state->p++;
    infix_type * agg_type = nullptr;
    infix_status status = (start_char == '{') ? infix_type_create_struct(state->arena, &agg_type, members, num_members)
                                              : infix_type_create_union(state->arena, &agg_type, members, num_members);
    if (status != INFIX_SUCCESS) {
        state->depth--;
        return nullptr;
    }
    state->depth--;
    return agg_type;
}
/**
 * @internal
 * @brief Parses a packed struct (`!{...}` or `!N:{...}`).
 * @param[in,out] state The parser state.
 * @return A pointer to the new `infix_type`, or `nullptr` on failure.
 */
static infix_type * parse_packed_struct(parser_state * state) {
    size_t alignment = 1;  // Default alignment for `!{...}` is 1.
    if (*state->p == '!') {
        state->p++;
        if (isdigit((unsigned char)*state->p)) {
            // This is the `!N:{...}` form with an explicit alignment.
            if (!parse_size_t(state, &alignment))
                return nullptr;
            if (*state->p != ':') {
                set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
                return nullptr;
            }
            state->p++;
        }
    }
    skip_whitespace(state);
    if (*state->p != '{') {
        set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
        return nullptr;
    }
    state->p++;
    size_t num_members = 0;
    infix_struct_member * members = parse_aggregate_members(state, '}', &num_members);
    if (!members && infix_get_last_error().code != INFIX_CODE_SUCCESS)
        return nullptr;
    if (*state->p != '}') {
        set_parser_error(state, INFIX_CODE_UNTERMINATED_AGGREGATE);
        return nullptr;
    }
    state->p++;
    infix_type * packed_type = nullptr;
    // For packed structs, the total size is simply the sum of member sizes without padding.
    // The user of `infix_type_create_packed_struct` must provide pre-calculated offsets.
    // Since our parser doesn't know the offsets, we pass a preliminary size. The final
    // layout pass will fix this if needed, but for packed structs, the user's offsets
    // are king.
    size_t total_size = 0;
    for (size_t i = 0; i < num_members; ++i)
        total_size += members[i].type->size;
    infix_status status =
        infix_type_create_packed_struct(state->arena, &packed_type, total_size, alignment, members, num_members);
    if (status != INFIX_SUCCESS)
        return nullptr;
    return packed_type;
}
// Main Parser Logic
/**
 * @internal
 * @brief Parses any primitive type keyword from the signature string.
 * @details This function attempts to match and consume a variety of standard and
 *          aliased keywords for primitive types (e.g., `sint32`, `int`, `uint`).
 *          If a match is found, it returns a pointer to the corresponding static
 *          singleton type object.
 * @param[in,out] state The parser state.
 * @return A pointer to the static `infix_type` for the primitive, or `nullptr` if no keyword is matched.
 */
static infix_type * parse_primitive(parser_state * state) {
    if (consume_keyword(state, "sint8") || consume_keyword(state, "int8"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_SINT8);
    if (consume_keyword(state, "uint8"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT8);
    if (consume_keyword(state, "sint16") || consume_keyword(state, "int16"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_SINT16);
    if (consume_keyword(state, "uint16"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT16);
    if (consume_keyword(state, "sint32") || consume_keyword(state, "int32"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_SINT32);
    if (consume_keyword(state, "uint32"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT32);
    if (consume_keyword(state, "sint64") || consume_keyword(state, "int64"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_SINT64);
    if (consume_keyword(state, "uint64"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT64);
    if (consume_keyword(state, "sint128") || consume_keyword(state, "int128"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_SINT128);
    if (consume_keyword(state, "uint128"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT128);
    if (consume_keyword(state, "float32"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_FLOAT);
    if (consume_keyword(state, "float64"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_DOUBLE);
    if (consume_keyword(state, "bool"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_BOOL);
    if (consume_keyword(state, "void"))
        return infix_type_create_void();
    // C-style convenience aliases
    if (consume_keyword(state, "uchar"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT8);
    if (consume_keyword(state, "char"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_SINT8);
    if (consume_keyword(state, "ushort"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT16);
    if (consume_keyword(state, "short"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_SINT16);
    if (consume_keyword(state, "uint"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT32);
    if (consume_keyword(state, "int"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_SINT32);
    if (consume_keyword(state, "ulonglong"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT64);
    if (consume_keyword(state, "longlong"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_SINT64);
    // `long` is platform-dependent, so we use `sizeof` to pick the correct size.
    if (consume_keyword(state, "ulong"))
        return infix_type_create_primitive(sizeof(unsigned long) == 8 ? INFIX_PRIMITIVE_UINT64
                                                                      : INFIX_PRIMITIVE_UINT32);
    if (consume_keyword(state, "long"))
        return infix_type_create_primitive(sizeof(long) == 8 ? INFIX_PRIMITIVE_SINT64 : INFIX_PRIMITIVE_SINT32);
    if (consume_keyword(state, "double"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_DOUBLE);
    if (consume_keyword(state, "float"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_FLOAT);
    if (consume_keyword(state, "longdouble"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_LONG_DOUBLE);
    if (consume_keyword(state, "size_t"))
        return infix_type_create_primitive(sizeof(size_t) == 8 ? INFIX_PRIMITIVE_UINT64 : INFIX_PRIMITIVE_UINT32);
    if (consume_keyword(state, "ssize_t"))
        return infix_type_create_primitive(sizeof(ssize_t) == 8 ? INFIX_PRIMITIVE_SINT64 : INFIX_PRIMITIVE_SINT32);
    // uchar.h types
    if (consume_keyword(state, "char8_t"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT8);
    if (consume_keyword(state, "char16_t"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT16);
    if (consume_keyword(state, "char32_t"))
        return infix_type_create_primitive(INFIX_PRIMITIVE_UINT32);
    // AVX convenience aliases
    if (consume_keyword(state, "m256d")) {
        infix_type * type = nullptr;
        infix_status status =
            infix_type_create_vector(state->arena, &type, infix_type_create_primitive(INFIX_PRIMITIVE_DOUBLE), 4);
        if (status != INFIX_SUCCESS)
            return nullptr;    // Propagate failure
        type->alignment = 32;  // YMM registers require 32-byte alignment
        return type;
    }
    if (consume_keyword(state, "m256")) {
        infix_type * type = nullptr;
        infix_status status =
            infix_type_create_vector(state->arena, &type, infix_type_create_primitive(INFIX_PRIMITIVE_FLOAT), 8);
        if (status != INFIX_SUCCESS)
            return nullptr;    // Propagate failure
        type->alignment = 32;  // YMM registers require 32-byte alignment
        return type;
    }
    if (consume_keyword(state, "m512d")) {
        infix_type * type = nullptr;
        infix_status status =
            infix_type_create_vector(state->arena, &type, infix_type_create_primitive(INFIX_PRIMITIVE_DOUBLE), 8);
        if (status != INFIX_SUCCESS)
            return nullptr;
        type->alignment = 64;  // ZMM registers have 64-byte alignment
        return type;
    }
    if (consume_keyword(state, "m512")) {
        infix_type * type = nullptr;
        infix_status status =
            infix_type_create_vector(state->arena, &type, infix_type_create_primitive(INFIX_PRIMITIVE_FLOAT), 16);
        if (status != INFIX_SUCCESS)
            return nullptr;
        type->alignment = 64;
        return type;
    }
    if (consume_keyword(state, "m512i")) {
        infix_type * type = nullptr;
        infix_status status =
            infix_type_create_vector(state->arena, &type, infix_type_create_primitive(INFIX_PRIMITIVE_SINT64), 8);
        if (status != INFIX_SUCCESS)
            return nullptr;
        type->alignment = 64;
        return type;
    }
    return nullptr;
}
/**
 * @internal
 * @brief The main recursive parsing function.
 * @details This is the heart of the parser. It acts as a dispatcher, inspecting the
 * next character in the string to determine which type of construct to parse. It
 * then calls the appropriate helper function (e.g., `parse_aggregate`,
 * `parse_primitive`, or a recursive call to itself for pointers/arrays).
 * @param[in,out] state The parser state.
 * @return A pointer to the parsed `infix_type`, or `nullptr` on failure.
 */
static infix_type * parse_type(parser_state * state) {
    if (state->depth >= MAX_RECURSION_DEPTH) {
        set_parser_error(state, INFIX_CODE_RECURSION_DEPTH_EXCEEDED);
        return nullptr;
    }
    state->depth++;
    skip_whitespace(state);
    // Capture the offset from the start of the signature string *before* parsing the type.
    size_t current_offset = state->p - state->start;
    infix_type * result_type = nullptr;
    const char * p_before_type = state->p;
    if (*state->p == '@') {  // Named type reference: `@MyStruct`
        state->p++;
        const char * name = parse_identifier(state);
        if (!name) {
            set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
            state->depth--;
            return nullptr;
        }
        if (infix_type_create_named_reference(state->arena, &result_type, name, INFIX_AGGREGATE_STRUCT) !=
            INFIX_SUCCESS)
            result_type = nullptr;
    }
    else if (*state->p == '*') {  // Pointer type: `*int`
        state->p++;
        skip_whitespace(state);
        infix_type * pointee_type = parse_type(state);
        if (!pointee_type) {
            state->depth--;
            return nullptr;
        }
        if (infix_type_create_pointer_to(state->arena, &result_type, pointee_type) != INFIX_SUCCESS)
            result_type = nullptr;
    }
    else if (*state->p == '(') {  // Grouped type `(type)` or function pointer `(...) -> type`
        if (is_function_signature_ahead(state)) {
            infix_type * ret_type = nullptr;
            infix_function_argument * args = nullptr;
            size_t num_args = 0, num_fixed = 0;
            if (parse_function_signature_details(state, &ret_type, &args, &num_args, &num_fixed) != INFIX_SUCCESS) {
                state->depth--;
                return nullptr;
            }
            // Manually construct a function pointer type object.
            // This is represented internally as a pointer-like type with extra metadata.
            infix_type * func_type = infix_arena_calloc(state->arena, 1, sizeof(infix_type), _Alignof(infix_type));
            if (!func_type) {
                _infix_set_error(
                    INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, (size_t)(state->p - state->start));
                state->depth--;
                return nullptr;
            }
            func_type->size = sizeof(void *);
            func_type->alignment = _Alignof(void *);
            func_type->is_arena_allocated = true;
            func_type->category = INFIX_TYPE_REVERSE_TRAMPOLINE;  // Special category for function types.
            func_type->meta.func_ptr_info.return_type = ret_type;
            func_type->meta.func_ptr_info.args = args;
            func_type->meta.func_ptr_info.num_args = num_args;
            func_type->meta.func_ptr_info.num_fixed_args = num_fixed;
            result_type = func_type;
        }
        else {  // Grouped type: `(type)`
            state->p++;
            skip_whitespace(state);
            result_type = parse_type(state);
            if (!result_type) {
                state->depth--;
                return nullptr;
            }
            skip_whitespace(state);
            if (*state->p != ')') {
                set_parser_error(state, INFIX_CODE_UNTERMINATED_AGGREGATE);
                result_type = nullptr;
            }
            else
                state->p++;
        }
    }
    else if (*state->p == '[') {  // Array type: `[size:type]`
        state->p++;
        skip_whitespace(state);
        size_t num_elements = 0;
        bool is_flexible = false;

        if (*state->p == '?') {
            // Flexible array member: `[?:type]`
            is_flexible = true;
            state->p++;
        }
        else if (!parse_size_t(state, &num_elements)) {
            state->depth--;
            return nullptr;
        }

        skip_whitespace(state);
        if (*state->p != ':') {
            set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
            state->depth--;
            return nullptr;
        }
        state->p++;
        skip_whitespace(state);
        infix_type * element_type = parse_type(state);
        if (!element_type) {
            state->depth--;
            return nullptr;
        }
        if (element_type->category == INFIX_TYPE_VOID) {  // An array of `void` is illegal in C.
            set_parser_error(state, INFIX_CODE_INVALID_MEMBER_TYPE);
            state->depth--;
            return nullptr;
        }
        skip_whitespace(state);
        if (*state->p != ']') {
            set_parser_error(state, INFIX_CODE_UNTERMINATED_AGGREGATE);
            state->depth--;
            return nullptr;
        }
        state->p++;

        if (is_flexible) {
            if (infix_type_create_flexible_array(state->arena, &result_type, element_type) != INFIX_SUCCESS)
                result_type = nullptr;
        }
        else {
            if (infix_type_create_array(state->arena, &result_type, element_type, num_elements) != INFIX_SUCCESS)
                result_type = nullptr;
        }
    }
    else if (*state->p == '!')  // Packed struct
        result_type = parse_packed_struct(state);
    else if (*state->p == '{')  // Struct
        result_type = parse_aggregate(state, '{', '}');
    else if (*state->p == '<')  // Union
        result_type = parse_aggregate(state, '<', '>');
    else if (*state->p == 'e' && state->p[1] == ':') {  // Enum: `e:type`
        state->p += 2;
        skip_whitespace(state);
        infix_type * underlying_type = parse_type(state);
        if (!underlying_type || underlying_type->category != INFIX_TYPE_PRIMITIVE) {
            set_parser_error(state, INFIX_CODE_INVALID_MEMBER_TYPE);
            state->depth--;
            return nullptr;
        }
        if (infix_type_create_enum(state->arena, &result_type, underlying_type) != INFIX_SUCCESS)
            result_type = nullptr;
    }
    else if (*state->p == 'c' && state->p[1] == '[') {  // Complex: `c[type]`
        state->p += 2;
        skip_whitespace(state);
        infix_type * base_type = parse_type(state);
        if (!base_type) {
            state->depth--;
            return nullptr;
        }
        skip_whitespace(state);
        if (*state->p != ']') {
            set_parser_error(state, INFIX_CODE_UNTERMINATED_AGGREGATE);
            state->depth--;
            return nullptr;
        }
        state->p++;
        if (infix_type_create_complex(state->arena, &result_type, base_type) != INFIX_SUCCESS)
            result_type = nullptr;
    }
    else if (*state->p == 'v' && state->p[1] == '[') {  // Vector: `v[size:type]`
        state->p += 2;
        skip_whitespace(state);
        size_t num_elements;
        if (!parse_size_t(state, &num_elements)) {
            state->depth--;
            return nullptr;
        }
        if (*state->p != ':') {
            set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
            state->depth--;
            return nullptr;
        }
        state->p++;
        infix_type * element_type = parse_type(state);
        if (!element_type) {
            state->depth--;
            return nullptr;
        }
        if (*state->p != ']') {
            set_parser_error(state, INFIX_CODE_UNTERMINATED_AGGREGATE);
            state->depth--;
            return nullptr;
        }
        state->p++;
        if (infix_type_create_vector(state->arena, &result_type, element_type, num_elements) != INFIX_SUCCESS)
            result_type = nullptr;
    }
    else {  // Primitive type or error
        result_type = parse_primitive(state);
        if (!result_type) {
            // If no error was set by a failed `consume_keyword`, set a generic one.
            if (infix_get_last_error().code == INFIX_CODE_SUCCESS) {
                state->p = p_before_type;
                if (isalpha((unsigned char)*state->p) || *state->p == '_')
                    set_parser_error(state, INFIX_CODE_INVALID_KEYWORD);
                else
                    set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
            }
        }
    }
    // Only set source offset for dynamically allocated types (primitives are static singletons).
    if (result_type && result_type->is_arena_allocated)
        result_type->source_offset = current_offset;
    state->depth--;
    return result_type;
}
/**
 * @internal
 * @brief Parses the details of a function signature: `(<args>) -> <ret>`.
 * @details This function handles the full complexity of function signatures, including
 *          a comma-separated list of fixed arguments, an optional variadic part
 *          (separated by ';'), and the return type following the `->` arrow.
 * @param[in,out] state The parser state.
 * @param[out] out_ret_type Receives the parsed return type.
 * @param[out] out_args Receives the arena-allocated array of parsed arguments.
 * @param[out] out_num_args Receives the total number of arguments (fixed + variadic).
 * @param[out] out_num_fixed_args Receives the number of fixed (non-variadic) arguments.
 * @return `INFIX_SUCCESS` on success.
 */
static infix_status parse_function_signature_details(parser_state * state,
                                                     infix_type ** out_ret_type,
                                                     infix_function_argument ** out_args,
                                                     size_t * out_num_args,
                                                     size_t * out_num_fixed_args) {
    if (*state->p != '(') {
        set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    state->p++;
    skip_whitespace(state);
    // Use a temporary linked list to collect arguments.
    typedef struct arg_node {
        infix_function_argument arg;
        struct arg_node * next;
    } arg_node;
    arg_node *head = nullptr, *tail = nullptr;
    size_t num_args = 0;
    // Parse Fixed Arguments
    if (*state->p != ')' && *state->p != ';') {
        while (1) {
            skip_whitespace(state);
            if (*state->p == ')' || *state->p == ';')
                break;
            const char * name = parse_optional_name_prefix(state);
            infix_type * arg_type = parse_type(state);
            if (!arg_type)
                return INFIX_ERROR_INVALID_ARGUMENT;
            arg_node * node = infix_arena_calloc(state->arena, 1, sizeof(arg_node), _Alignof(arg_node));
            if (!node) {
                _infix_set_error(
                    INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, (size_t)(state->p - state->start));
                return INFIX_ERROR_ALLOCATION_FAILED;
            }
            node->arg.type = arg_type;
            node->arg.name = name;
            node->next = nullptr;
            if (!head)
                head = tail = node;
            else {
                tail->next = node;
                tail = node;
            }
            num_args++;
            skip_whitespace(state);
            if (*state->p == ',') {
                state->p++;
                skip_whitespace(state);
                if (*state->p == ')' || *state->p == ';') {  // Trailing comma error.
                    set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
                    return INFIX_ERROR_INVALID_ARGUMENT;
                }
            }
            else if (*state->p != ')' && *state->p != ';') {
                set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
                return INFIX_ERROR_INVALID_ARGUMENT;
            }
            else
                break;
        }
    }
    *out_num_fixed_args = num_args;
    // Parse Variadic Arguments
    if (*state->p == ';') {
        state->p++;
        if (*state->p != ')') {
            while (1) {
                skip_whitespace(state);
                if (*state->p == ')')
                    break;
                const char * name = parse_optional_name_prefix(state);
                infix_type * arg_type = parse_type(state);
                if (!arg_type)
                    return INFIX_ERROR_INVALID_ARGUMENT;
                arg_node * node = infix_arena_calloc(state->arena, 1, sizeof(arg_node), _Alignof(arg_node));
                if (!node) {
                    _infix_set_error(
                        INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, (size_t)(state->p - state->start));
                    return INFIX_ERROR_ALLOCATION_FAILED;
                }
                node->arg.type = arg_type;
                node->arg.name = name;
                node->next = nullptr;
                if (!head)
                    head = tail = node;
                else {
                    tail->next = node;
                    tail = node;
                }
                num_args++;
                skip_whitespace(state);
                if (*state->p == ',') {
                    state->p++;
                    skip_whitespace(state);
                    if (*state->p == ')') {  // Trailing comma error.
                        set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
                        return INFIX_ERROR_INVALID_ARGUMENT;
                    }
                }
                else if (*state->p != ')') {
                    set_parser_error(state, INFIX_CODE_UNEXPECTED_TOKEN);
                    return INFIX_ERROR_INVALID_ARGUMENT;
                }
                else
                    break;
            }
        }
    }
    skip_whitespace(state);
    if (*state->p != ')') {
        set_parser_error(state, INFIX_CODE_UNTERMINATED_AGGREGATE);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    state->p++;
    // Parse Return Type
    skip_whitespace(state);
    if (state->p[0] != '-' || state->p[1] != '>') {
        set_parser_error(state, INFIX_CODE_MISSING_RETURN_TYPE);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    state->p += 2;
    *out_ret_type = parse_type(state);
    if (!*out_ret_type)
        return INFIX_ERROR_INVALID_ARGUMENT;
    // Convert linked list of args to a flat array.
    infix_function_argument * args = (num_args > 0)
        ? infix_arena_calloc(state->arena, num_args, sizeof(infix_function_argument), _Alignof(infix_function_argument))
        : nullptr;
    if (num_args > 0 && !args) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, (size_t)(state->p - state->start));
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    arg_node * current = head;
    for (size_t i = 0; i < num_args; i++) {
        args[i] = current->arg;
        current = current->next;
    }
    *out_args = args;
    *out_num_args = num_args;
    return INFIX_SUCCESS;
}
// High-Level API Implementation
/**
 * @internal
 * @brief The internal entry point for the signature parser (the "Parse" stage).
 *
 * This function takes a signature string and produces a raw, unresolved type
 * graph in a new, temporary arena. It is the core parsing logic, separated from the
 * higher-level functions that manage the full data pipeline. It is careful not to
 * modify the global error context string (`g_infix_last_signature_context`), which
 * is the responsibility of its public API callers.
 *
 * @param[out] out_type On success, receives the parsed type graph.
 * @param[out] out_arena On success, receives the temporary arena holding the graph. The caller is responsible for
 * destroying it.
 * @param[in] signature The signature string to parse.
 * @return `INFIX_SUCCESS` on success.
 */
c23_nodiscard infix_status _infix_parse_type_internal(infix_type ** out_type,
                                                      infix_arena_t ** out_arena,
                                                      const char * signature) {
    if (!out_type || !out_arena || !signature || *signature == '\0') {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_UNKNOWN, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    // The top-level public API is responsible for setting g_infix_last_signature_context.
    *out_arena = infix_arena_create(4096);
    if (!*out_arena) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    parser_state state = {.p = signature, .start = signature, .arena = *out_arena, .depth = 0};
    infix_type * type = parse_type(&state);
    if (type) {
        skip_whitespace(&state);
        // After successfully parsing a type, ensure there is no trailing junk.
        if (state.p[0] != '\0') {
            set_parser_error(&state, INFIX_CODE_UNEXPECTED_TOKEN);
            type = nullptr;
        }
    }
    if (!type) {
        // If parsing failed at any point, clean up the temporary arena.
        infix_arena_destroy(*out_arena);
        *out_arena = nullptr;
        *out_type = nullptr;
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    *out_type = type;
    return INFIX_SUCCESS;
}
/**
 * @brief Parses a signature string representing a single data type.
 *
 * This function orchestrates the full **"Parse -> Estimate -> Copy -> Resolve -> Layout"** pipeline
 * for a single type, resulting in a fully resolved and laid-out `infix_type` object graph.
 *
 * @param[out] out_type On success, receives a pointer to the parsed type object.
 * @param[out] out_arena On success, receives a pointer to the arena holding the type. The caller is responsible for
 * freeing this with `infix_arena_destroy`.
 * @param[in] signature The signature string of the data type (e.g., `"{id:int, name:*char}"`).
 * @param[in] registry An optional type registry for resolving named types. Can be `nullptr`.
 * @return `INFIX_SUCCESS` on success.
 */
c23_nodiscard infix_status infix_type_from_signature(infix_type ** out_type,
                                                     infix_arena_t ** out_arena,
                                                     const char * signature,
                                                     infix_registry_t * registry) {
    _infix_clear_error();
    g_infix_last_signature_context = signature;  // Set context for rich error reporting.
    // 1. "Parse" stage: Create a raw, unresolved type graph in a temporary arena.
    infix_type * raw_type = nullptr;
    infix_arena_t * parser_arena = nullptr;
    infix_status status = _infix_parse_type_internal(&raw_type, &parser_arena, signature);
    if (status != INFIX_SUCCESS)
        return status;
    // Create the final arena that will be returned to the caller.
    *out_arena = infix_arena_create(4096);
    if (!*out_arena) {
        infix_arena_destroy(parser_arena);
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    // 2. "Copy" stage: Deep copy the raw graph into the final arena.
    infix_type * final_type = _copy_type_graph_to_arena(*out_arena, raw_type);
    infix_arena_destroy(parser_arena);  // The temporary graph is no longer needed.
    if (!final_type) {
        infix_arena_destroy(*out_arena);
        *out_arena = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    // 3. "Resolve" stage: Replace all named references (`@Name`) with concrete types.
    status = _infix_resolve_type_graph_inplace(&final_type, registry);
    if (status != INFIX_SUCCESS) {
        infix_arena_destroy(*out_arena);
        *out_arena = nullptr;
        *out_type = nullptr;
    }
    else {
        // 4. "Layout" stage: Calculate the final size, alignment, and member offsets.
        _infix_type_recalculate_layout(final_type);
        *out_type = final_type;
    }
    return status;
}
/**
 * @brief Parses a full function signature string into its constituent parts.
 *
 * Like `infix_type_from_signature`, this function orchestrates the full
 * "Parse -> Estimate -> Copy -> Resolve -> Layout" pipeline, but for a function signature.
 * It unpacks the final, resolved components for the caller.
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
c23_nodiscard infix_status infix_signature_parse(const char * signature,
                                                 infix_arena_t ** out_arena,
                                                 infix_type ** out_ret_type,
                                                 infix_function_argument ** out_args,
                                                 size_t * out_num_args,
                                                 size_t * out_num_fixed_args,
                                                 infix_registry_t * registry) {
    _infix_clear_error();
    if (!signature || !out_arena || !out_ret_type || !out_args || !out_num_args || !out_num_fixed_args) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_UNKNOWN, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    g_infix_last_signature_context = signature;
    // 1. "Parse" stage
    infix_type * raw_func_type = nullptr;
    infix_arena_t * parser_arena = nullptr;
    infix_status status = _infix_parse_type_internal(&raw_func_type, &parser_arena, signature);
    if (status != INFIX_SUCCESS)
        return status;
    if (raw_func_type->category != INFIX_TYPE_REVERSE_TRAMPOLINE) {
        infix_arena_destroy(parser_arena);
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_UNEXPECTED_TOKEN, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    // Create final arena
    *out_arena = infix_arena_create(8192);
    if (!*out_arena) {
        infix_arena_destroy(parser_arena);
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    // 2. "Copy" stage
    infix_type * final_func_type = _copy_type_graph_to_arena(*out_arena, raw_func_type);
    infix_arena_destroy(parser_arena);
    if (!final_func_type) {
        infix_arena_destroy(*out_arena);
        *out_arena = nullptr;
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    // 3. "Resolve" and 4. "Layout" stages
    status = _infix_resolve_type_graph_inplace(&final_func_type, registry);
    if (status != INFIX_SUCCESS) {
        infix_arena_destroy(*out_arena);
        *out_arena = nullptr;
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    _infix_type_recalculate_layout(final_func_type);
    // Unpack the results for the caller from the final, processed function type object.
    *out_ret_type = final_func_type->meta.func_ptr_info.return_type;
    *out_args = final_func_type->meta.func_ptr_info.args;
    *out_num_args = final_func_type->meta.func_ptr_info.num_args;
    *out_num_fixed_args = final_func_type->meta.func_ptr_info.num_fixed_args;
    return INFIX_SUCCESS;
}
// Type Printing Logic
/**
 * @internal
 * @struct printer_state
 * @brief Holds the state for the recursive type-to-string printer.
 */
typedef struct {
    char * p;            /**< The current write position in the output buffer. */
    size_t remaining;    /**< The number of bytes remaining in the buffer. */
    infix_status status; /**< The current status, set to an error if the buffer is too small. */
} printer_state;
/**
 * @internal
 * @brief A safe `vsnprintf` wrapper for building the signature string.
 * Updates the printer state and sets an error on buffer overflow.
 * @param[in,out] state The printer state.
 * @param[in] fmt The `printf`-style format string.
 * @param[in] ... Arguments for the format string.
 */
static void _print(printer_state * state, const char * fmt, ...) {
    if (state->status != INFIX_SUCCESS)
        return;
    va_list args;
    va_start(args, fmt);
    int written = vsnprintf(state->p, state->remaining, fmt, args);
    va_end(args);
    if (written < 0 || (size_t)written >= state->remaining)
        // If snprintf failed or would have overflowed, mark an error.
        state->status = INFIX_ERROR_INVALID_ARGUMENT;
    else {
        state->p += written;
        state->remaining -= written;
    }
}
// Forward declaration for mutual recursion in printers.
static void _infix_type_print_signature_recursive(printer_state * state, const infix_type * type);
/**
 * @internal
 * @brief The internal implementation of the type-to-string printer.
 *
 * This function recursively walks a type graph and prints its signature representation.
 * The key feature is the initial check for `type->name`. If a semantic alias exists,
 * it is always preferred, ensuring that introspection and serialization produce
 * canonical, readable output (e.g., printing "@MyHandle" instead of "*void").
 *
 * @param[in,out] state The printer state, which is updated as the string is built.
 * @param[in] type The `infix_type` to print.
 */
static void _infix_type_print_signature_recursive(printer_state * state, const infix_type * type) {
    if (state->status != INFIX_SUCCESS || !type) {
        if (state->status == INFIX_SUCCESS)
            state->status = INFIX_ERROR_INVALID_ARGUMENT;
        return;
    }
    // If the type has a semantic name, always prefer printing it.
    if (type->name) {
        _print(state, "@%s", type->name);
        return;
    }
    switch (type->category) {
    case INFIX_TYPE_VOID:
        _print(state, "void");
        break;
    case INFIX_TYPE_NAMED_REFERENCE:
        // This case should ideally not be hit with a fully resolved type, but we handle it for robustness.
        _print(state, "@%s", type->meta.named_reference.name);
        break;
    case INFIX_TYPE_POINTER:
        _print(state, "*");
        // Special handling for `void*` or recursive pointers to avoid infinite recursion.
        if (type->meta.pointer_info.pointee_type == type || type->meta.pointer_info.pointee_type == nullptr ||
            type->meta.pointer_info.pointee_type->category == INFIX_TYPE_VOID)
            _print(state, "void");
        else
            _infix_type_print_signature_recursive(state, type->meta.pointer_info.pointee_type);
        break;
    case INFIX_TYPE_ARRAY:
        if (type->meta.array_info.is_flexible)
            _print(state, "[?:");
        else
            _print(state, "[%zu:", type->meta.array_info.num_elements);
        _infix_type_print_signature_recursive(state, type->meta.array_info.element_type);
        _print(state, "]");
        break;
    case INFIX_TYPE_STRUCT:
        if (type->meta.aggregate_info.is_packed) {
            _print(state, "!");
            if (type->alignment != 1)
                _print(state, "%zu:", type->alignment);
        }
        _print(state, "{");
        for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
            if (i > 0)
                _print(state, ",");
            const infix_struct_member * member = &type->meta.aggregate_info.members[i];
            if (member->name)
                _print(state, "%s:", member->name);
            _infix_type_print_signature_recursive(state, member->type);
            if (member->bit_width > 0)
                _print(state, ":%u", member->bit_width);
        }
        _print(state, "}");
        break;
    case INFIX_TYPE_UNION:
        _print(state, "<");
        for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
            if (i > 0)
                _print(state, ",");
            const infix_struct_member * member = &type->meta.aggregate_info.members[i];
            if (member->name)
                _print(state, "%s:", member->name);
            _infix_type_print_signature_recursive(state, member->type);
            // Bitfields in unions are rare but syntactically valid in C.
            if (member->bit_width > 0)
                _print(state, ":%u", member->bit_width);
        }
        _print(state, ">");
        break;
    case INFIX_TYPE_REVERSE_TRAMPOLINE:
        _print(state, "(");
        for (size_t i = 0; i < type->meta.func_ptr_info.num_fixed_args; ++i) {
            if (i > 0)
                _print(state, ",");
            const infix_function_argument * arg = &type->meta.func_ptr_info.args[i];
            if (arg->name)
                _print(state, "%s:", arg->name);
            _infix_type_print_signature_recursive(state, arg->type);
        }
        if (type->meta.func_ptr_info.num_args > type->meta.func_ptr_info.num_fixed_args) {
            _print(state, ";");
            for (size_t i = type->meta.func_ptr_info.num_fixed_args; i < type->meta.func_ptr_info.num_args; ++i) {
                if (i > type->meta.func_ptr_info.num_fixed_args)
                    _print(state, ",");
                const infix_function_argument * arg = &type->meta.func_ptr_info.args[i];
                if (arg->name)
                    _print(state, "%s:", arg->name);
                _infix_type_print_signature_recursive(state, arg->type);
            }
        }
        _print(state, ")->");
        _infix_type_print_signature_recursive(state, type->meta.func_ptr_info.return_type);
        break;
    case INFIX_TYPE_ENUM:
        _print(state, "e:");
        _infix_type_print_signature_recursive(state, type->meta.enum_info.underlying_type);
        break;
    case INFIX_TYPE_COMPLEX:
        _print(state, "c[");
        _infix_type_print_signature_recursive(state, type->meta.complex_info.base_type);
        _print(state, "]");
        break;
    case INFIX_TYPE_VECTOR:
        {
            const infix_type * element_type = type->meta.vector_info.element_type;
            size_t num_elements = type->meta.vector_info.num_elements;
            bool printed_alias = false;
            if (element_type->category == INFIX_TYPE_PRIMITIVE) {
                if (num_elements == 8 && is_double(element_type)) {
                    _print(state, "m512d");
                    printed_alias = true;
                }
                else if (num_elements == 16 && is_float(element_type)) {
                    _print(state, "m512");
                    printed_alias = true;
                }
                else if (num_elements == 8 && element_type->meta.primitive_id == INFIX_PRIMITIVE_SINT64) {
                    _print(state, "m512i");
                    printed_alias = true;
                }
                else if (num_elements == 4 && is_double(element_type)) {
                    _print(state, "m256d");
                    printed_alias = true;
                }
                else if (num_elements == 8 && is_float(element_type)) {
                    _print(state, "m256");
                    printed_alias = true;
                }
            }
            if (!printed_alias) {
                _print(state, "v[%zu:", num_elements);
                _infix_type_print_signature_recursive(state, element_type);
                _print(state, "]");
            }
        }
        break;
    case INFIX_TYPE_PRIMITIVE:
        switch (type->meta.primitive_id) {
        case INFIX_PRIMITIVE_BOOL:
            _print(state, "bool");
            break;
        case INFIX_PRIMITIVE_SINT8:
            _print(state, "sint8");
            break;
        case INFIX_PRIMITIVE_UINT8:
            _print(state, "uint8");
            break;
        case INFIX_PRIMITIVE_SINT16:
            _print(state, "sint16");
            break;
        case INFIX_PRIMITIVE_UINT16:
            _print(state, "uint16");
            break;
        case INFIX_PRIMITIVE_SINT32:
            _print(state, "sint32");
            break;
        case INFIX_PRIMITIVE_UINT32:
            _print(state, "uint32");
            break;
        case INFIX_PRIMITIVE_SINT64:
            _print(state, "sint64");
            break;
        case INFIX_PRIMITIVE_UINT64:
            _print(state, "uint64");
            break;
        case INFIX_PRIMITIVE_SINT128:
            _print(state, "sint128");
            break;
        case INFIX_PRIMITIVE_UINT128:
            _print(state, "uint128");
            break;
        case INFIX_PRIMITIVE_FLOAT:
            _print(state, "float");
            break;
        case INFIX_PRIMITIVE_DOUBLE:
            _print(state, "double");
            break;
        case INFIX_PRIMITIVE_LONG_DOUBLE:
            _print(state, "longdouble");
            break;
        }
        break;
    default:
        state->status = INFIX_ERROR_INVALID_ARGUMENT;
        break;
    }
}
/**
 * @internal
 * @brief Serializes an `infix_type`'s structural body, ignoring its top-level semantic name.
 *
 * This function is a special-purpose printer used by `infix_registry_print`. Its job
 * is to produce the right-hand side of a type definition. It *always* prints the
 * full structural definition, ignoring the top-level `name` field to prevent
 * self-referential output like `@MyInt = @MyInt;`.
 *
 * @param state The printer state.
 * @param type The type whose body to print.
 */
static void _infix_type_print_body_only_recursive(printer_state * state, const infix_type * type) {
    if (state->status != INFIX_SUCCESS || !type) {
        if (state->status == INFIX_SUCCESS)
            state->status = INFIX_ERROR_INVALID_ARGUMENT;
        return;
    }
    // This is the key difference from the main printer: we skip the `if (type->name)` check
    // and immediately print the underlying structure of the type.
    switch (type->category) {
    case INFIX_TYPE_STRUCT:
        if (type->meta.aggregate_info.is_packed) {
            _print(state, "!");
            if (type->alignment != 1)
                _print(state, "%zu:", type->alignment);
        }
        _print(state, "{");
        for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
            if (i > 0)
                _print(state, ",");
            const infix_struct_member * member = &type->meta.aggregate_info.members[i];
            if (member->name)
                _print(state, "%s:", member->name);
            // For nested members, we can use the standard printer, which IS allowed
            // to use the `@Name` shorthand for brevity.
            _infix_type_print_signature_recursive(state, member->type);
            if (member->bit_width > 0)
                _print(state, ":%u", member->bit_width);
        }
        _print(state, "}");
        break;
    case INFIX_TYPE_UNION:
        _print(state, "<");
        for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
            if (i > 0)
                _print(state, ",");
            const infix_struct_member * member = &type->meta.aggregate_info.members[i];
            if (member->name)
                _print(state, "%s:", member->name);
            _infix_type_print_signature_recursive(state, member->type);
            if (member->bit_width > 0)
                _print(state, ":%u", member->bit_width);
        }
        _print(state, ">");
        break;
    // For all other types, we replicate the printing logic from the main printer
    // to ensure we print the structure, not a potential top-level alias name.
    case INFIX_TYPE_VOID:
        _print(state, "void");
        break;
    case INFIX_TYPE_POINTER:
        _print(state, "*");
        if (type->meta.pointer_info.pointee_type == type || type->meta.pointer_info.pointee_type == nullptr ||
            type->meta.pointer_info.pointee_type->category == INFIX_TYPE_VOID)
            _print(state, "void");
        else
            _infix_type_print_signature_recursive(state, type->meta.pointer_info.pointee_type);
        break;
    case INFIX_TYPE_ARRAY:
        if (type->meta.array_info.is_flexible)
            _print(state, "[?:");
        else
            _print(state, "[%zu:", type->meta.array_info.num_elements);
        _infix_type_print_signature_recursive(state, type->meta.array_info.element_type);
        _print(state, "]");
        break;
    case INFIX_TYPE_ENUM:
        _print(state, "e:");
        _infix_type_print_signature_recursive(state, type->meta.enum_info.underlying_type);
        break;
    case INFIX_TYPE_COMPLEX:
        _print(state, "c[");
        _infix_type_print_signature_recursive(state, type->meta.complex_info.base_type);
        _print(state, "]");
        break;
    case INFIX_TYPE_PRIMITIVE:
        // This block is now a full copy from the main printer.
        switch (type->meta.primitive_id) {
        case INFIX_PRIMITIVE_BOOL:
            _print(state, "bool");
            break;
        case INFIX_PRIMITIVE_SINT8:
            _print(state, "sint8");
            break;
        case INFIX_PRIMITIVE_UINT8:
            _print(state, "uint8");
            break;
        case INFIX_PRIMITIVE_SINT16:
            _print(state, "sint16");
            break;
        case INFIX_PRIMITIVE_UINT16:
            _print(state, "uint16");
            break;
        case INFIX_PRIMITIVE_SINT32:
            _print(state, "sint32");
            break;
        case INFIX_PRIMITIVE_UINT32:
            _print(state, "uint32");
            break;
        case INFIX_PRIMITIVE_SINT64:
            _print(state, "sint64");
            break;
        case INFIX_PRIMITIVE_UINT64:
            _print(state, "uint64");
            break;
        case INFIX_PRIMITIVE_SINT128:
            _print(state, "sint128");
            break;
        case INFIX_PRIMITIVE_UINT128:
            _print(state, "uint128");
            break;
        case INFIX_PRIMITIVE_FLOAT:
            _print(state, "float");
            break;
        case INFIX_PRIMITIVE_DOUBLE:
            _print(state, "double");
            break;
        case INFIX_PRIMITIVE_LONG_DOUBLE:
            _print(state, "longdouble");
            break;
        }
        break;
    // We can safely delegate the remaining complex cases to the main printer, as they
    // do not have a top-level `name` field themselves.
    case INFIX_TYPE_NAMED_REFERENCE:
    case INFIX_TYPE_REVERSE_TRAMPOLINE:
    case INFIX_TYPE_VECTOR:
        _infix_type_print_signature_recursive(state, type);
        break;
    default:
        state->status = INFIX_ERROR_INVALID_ARGUMENT;
        break;
    }
}
/**
 * @internal
 * @brief The internal-only function to serialize a type's body without its registered name.
 */
c23_nodiscard infix_status _infix_type_print_body_only(char * buffer,
                                                       size_t buffer_size,
                                                       const infix_type * type,
                                                       infix_print_dialect_t dialect) {
    if (!buffer || buffer_size == 0 || !type || dialect != INFIX_DIALECT_SIGNATURE)
        return INFIX_ERROR_INVALID_ARGUMENT;
    printer_state state = {buffer, buffer_size, INFIX_SUCCESS};
    *buffer = '\0';
    _infix_type_print_body_only_recursive(&state, type);
    if (state.remaining > 0)
        *state.p = '\0';
    else
        buffer[buffer_size - 1] = '\0';
    return state.status;
}
/**
 * @brief Serializes an `infix_type` object graph back into a signature string.
 * @param[out] buffer The output buffer to write the string into.
 * @param[in] buffer_size The size of the output buffer.
 * @param[in] type The `infix_type` to print.
 * @param[in] dialect The desired output format dialect.
 * @return `INFIX_SUCCESS` on success, or `INFIX_ERROR_INVALID_ARGUMENT` if the buffer is too small.
 */
c23_nodiscard infix_status infix_type_print(char * buffer,
                                            size_t buffer_size,
                                            const infix_type * type,
                                            infix_print_dialect_t dialect) {
    _infix_clear_error();
    if (!buffer || buffer_size == 0 || !type) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_UNKNOWN, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    printer_state state = {buffer, buffer_size, INFIX_SUCCESS};
    *buffer = '\0';
    if (dialect == INFIX_DIALECT_SIGNATURE)
        _infix_type_print_signature_recursive(&state, type);
    else {
        // Placeholder for future dialects like C++ name mangling.
        _print(&state, "unsupported_dialect");
        state.status = INFIX_ERROR_INVALID_ARGUMENT;
    }
    if (state.status == INFIX_SUCCESS) {
        if (state.remaining > 0)
            *state.p = '\0';  // Null-terminate if there is space.
        else {
            // Buffer was exactly full. Ensure null termination at the very end.
            buffer[buffer_size - 1] = '\0';
            return INFIX_ERROR_INVALID_ARGUMENT;  // Indicate truncation.
        }
    }
    else if (buffer_size > 0)
        // Ensure null termination even on error (e.g., buffer too small).
        buffer[buffer_size - 1] = '\0';
    return state.status;
}
/**
 * @brief Serializes a function signature's components into a string.
 * @param[out] buffer The output buffer.
 * @param[in] buffer_size The size of the output buffer.
 * @param[in] function_name Optional name for dialects that support it (currently unused).
 * @param[in] ret_type The return type.
 * @param[in] args The array of arguments.
 * @param[in] num_args The total number of arguments.
 * @param[in] num_fixed_args The number of fixed arguments.
 * @param[in] dialect The output dialect.
 * @return `INFIX_SUCCESS` on success, or `INFIX_ERROR_INVALID_ARGUMENT` if the buffer is too small.
 */
c23_nodiscard infix_status infix_function_print(char * buffer,
                                                size_t buffer_size,
                                                const char * function_name,
                                                const infix_type * ret_type,
                                                const infix_function_argument * args,
                                                size_t num_args,
                                                size_t num_fixed_args,
                                                infix_print_dialect_t dialect) {
    _infix_clear_error();
    if (!buffer || buffer_size == 0 || !ret_type || (num_args > 0 && !args)) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_UNKNOWN, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    printer_state state = {buffer, buffer_size, INFIX_SUCCESS};
    *buffer = '\0';
    (void)function_name;  // Not used in the standard signature dialect.
    if (dialect == INFIX_DIALECT_SIGNATURE) {
        _print(&state, "(");
        for (size_t i = 0; i < num_fixed_args; ++i) {
            if (i > 0)
                _print(&state, ",");
            _infix_type_print_signature_recursive(&state, args[i].type);
        }
        if (num_args > num_fixed_args) {
            _print(&state, ";");
            for (size_t i = num_fixed_args; i < num_args; ++i) {
                if (i > num_fixed_args)
                    _print(&state, ",");
                _infix_type_print_signature_recursive(&state, args[i].type);
            }
        }
        _print(&state, ")->");
        _infix_type_print_signature_recursive(&state, ret_type);
    }
    else {
        _print(&state, "unsupported_dialect");
        state.status = INFIX_ERROR_INVALID_ARGUMENT;
    }
    if (state.status == INFIX_SUCCESS) {
        if (state.remaining > 0)
            *state.p = '\0';
        else {
            if (buffer_size > 0)
                buffer[buffer_size - 1] = '\0';
            return INFIX_ERROR_INVALID_ARGUMENT;  // Indicate truncation.
        }
    }
    else if (buffer_size > 0)
        buffer[buffer_size - 1] = '\0';
    return state.status;
}
/**
 * @brief Serializes all defined types within a registry into a single, human-readable string.
 *
 * @details The output format is a sequence of definitions (e.g., `@Name = { ... };`) separated
 * by newlines, suitable for logging, debugging, or saving to a file. This function
 * will not print forward declarations that have not been fully defined. The order of
 * definitions in the output string is not guaranteed.
 *
 * @param[out] buffer The output buffer to write the string into.
 * @param[in] buffer_size The size of the output buffer.
 * @param[in] registry The registry to serialize.
 * @return `INFIX_SUCCESS` on success, or `INFIX_ERROR_INVALID_ARGUMENT` if the buffer is too small
 *         or another error occurs.
 */
c23_nodiscard infix_status infix_registry_print(char * buffer, size_t buffer_size, const infix_registry_t * registry) {
    if (!buffer || buffer_size == 0 || !registry)
        return INFIX_ERROR_INVALID_ARGUMENT;
    printer_state state = {buffer, buffer_size, INFIX_SUCCESS};
    *state.p = '\0';
    // Iterate through all buckets and their chains.
    for (size_t i = 0; i < registry->num_buckets; ++i) {
        for (const _infix_registry_entry_t * entry = registry->buckets[i]; entry != nullptr; entry = entry->next) {
            // Only print fully defined types, not forward declarations.
            if (entry->type && !entry->is_forward_declaration) {
                char type_body_buffer[1024];
                if (_infix_type_print_body_only(
                        type_body_buffer, sizeof(type_body_buffer), entry->type, INFIX_DIALECT_SIGNATURE) !=
                    INFIX_SUCCESS) {
                    state.status = INFIX_ERROR_INVALID_ARGUMENT;
                    goto end_print_loop;
                }
                _print(&state, "@%s = %s;\n", entry->name, type_body_buffer);
            }
            else if (entry->is_forward_declaration)  // Explicitly print forward declarations
                _print(&state, "@%s;\n", entry->name);
            if (state.status != INFIX_SUCCESS)
                goto end_print_loop;
        }
    }
end_print_loop:;
    return state.status;
}
