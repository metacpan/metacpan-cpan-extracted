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
 * @file type_registry.c
 * @brief Implements the named type registry system.
 * @ingroup internal_core
 *
 * @details This module provides the functionality for defining, storing, and resolving
 * complex C types by name. It is a critical component for handling recursive types
 * (e.g., linked lists) and mutually-dependent types, making the signature string
 * syntax much more powerful and manageable.
 *
 * The registry is built on a hash table for efficient lookups. Its most important
 * functions are:
 *
 * 1.  `infix_register_types()`: This function uses a robust **three-pass algorithm**
 *     to parse a string of definitions. This approach allows for out-of-order
 *     definitions and forward declarations, which is essential for complex type
 *     graphs.
 *
 * 2.  `_infix_resolve_type_graph_inplace()`: This internal function implements the
 *     **"Resolve"** stage of the library's core "Parse -> Copy -> Resolve -> Layout"
 *     data pipeline. It traverses a type graph and replaces all named placeholders
 *     (`@MyType`) with direct pointers to the canonical type objects stored in the
 *     registry.
 */
#include "common/infix_internals.h"
#include <ctype.h>
#include <string.h>
/** @internal A thread-local pointer to the full signature string for rich error reporting. */
extern INFIX_TLS const char * g_infix_last_signature_context;
/**
 * @internal
 * @brief The initial number of buckets for the registry's internal hash table.
 * @details A prime number is chosen to help with better key distribution,
 *          reducing the likelihood of hash collisions.
 */
#define INITIAL_REGISTRY_BUCKETS 61
/**
 * @internal
 * @struct resolve_memo_node_t
 * @brief A node for a "visited set" used during type resolution to handle cycles.
 * @details During the recursive traversal of a type graph in `_resolve_type_graph_inplace_recursive`,
 * this temporary, stack-allocated linked list tracks `infix_type` nodes that have
 * already been visited in the current recursion path. If a node is encountered a
 * second time, it indicates a cycle (e.g., `struct Node { struct Node* next; };`),
 * and the recursion must stop to prevent a stack overflow.
 */
typedef struct resolve_memo_node_t {
    infix_type * src;                  /**< The `infix_type` object that has been visited. */
    struct resolve_memo_node_t * next; /**< The next node in the visited list. */
} resolve_memo_node_t;
// Hash Table Implementation
/**
 * @internal
 * @brief Computes a hash for a string using the djb2 algorithm.
 * @details djb2 is chosen for its simplicity, speed, and good distribution properties.
 * @param[in] str The input string to hash.
 * @return The 64-bit hash value.
 */
static uint64_t _registry_hash_string(const char * str) {
    uint64_t hash = 5381;
    int c;
    while ((c = *str++))
        hash = ((hash << 5) + hash) + c;  // hash * 33 + c
    return hash;
}
/**
 * @internal
 * @brief Looks up an entry in the registry's hash table.
 * @param[in] registry The registry to search in.
 * @param[in] name The name of the type to find.
 * @return A pointer to the registry entry (`_infix_registry_entry_t`), or `nullptr` if not found.
 */
static _infix_registry_entry_t * _registry_lookup(infix_registry_t * registry, const char * name) {
    if (!registry || !name)
        return nullptr;
    uint64_t hash = _registry_hash_string(name);
    size_t index = hash % registry->num_buckets;
    // Traverse the linked list (chain) at the computed bucket index.
    for (_infix_registry_entry_t * current = registry->buckets[index]; current; current = current->next)
        if (current->hash == hash && strcmp(current->name, name) == 0)
            return current;
    return nullptr;
}

/**
 * @internal
 * @brief Expands the registry's hash table and redistributes existing entries.
 * @details This is triggered when the load factor exceeds 0.75 to maintain O(1) lookup performance.
 *          The new bucket array is allocated using `infix_calloc` and the old one is freed.
 */
static void _registry_rehash(infix_registry_t * registry) {
    // Roughly double the size. Keep it odd to slightly help with distribution.
    size_t new_num_buckets = registry->num_buckets * 2 + 1;

    // Allocate new buckets from the heap.
    _infix_registry_entry_t ** new_buckets = infix_calloc(new_num_buckets, sizeof(_infix_registry_entry_t *));

    if (!new_buckets) {
        // If allocation fails, we simply return and continue using the existing buckets.
        // Performance will degrade, but correctness is preserved.
        return;
    }

    // Rehash all existing entries.
    for (size_t i = 0; i < registry->num_buckets; ++i) {
        _infix_registry_entry_t * entry = registry->buckets[i];
        while (entry) {
            _infix_registry_entry_t * next_entry = entry->next;  // Save next pointer

            // Use the pre-calculated hash
            size_t new_index = entry->hash % new_num_buckets;

            // Insert into new bucket (prepend)
            entry->next = new_buckets[new_index];
            new_buckets[new_index] = entry;

            entry = next_entry;
        }
    }

    // Update the registry to use the new table and free the old one.
    infix_free(registry->buckets);
    registry->buckets = new_buckets;
    registry->num_buckets = new_num_buckets;
}

/**
 * @internal
 * @brief Inserts a new, empty entry into the registry's hash table.
 *
 * @details This function creates a new entry for a given name and adds it to the appropriate
 * hash bucket. The `type` field is initially `nullptr` and is populated later during
 * the parsing pass of `infix_register_types`. All allocations are made from the
 * registry's own arena.
 *
 * @param[in] registry The registry to insert into.
 * @param[in] name The name of the new type.
 * @return A pointer to the newly created entry, or `nullptr` on allocation failure.
 */
static _infix_registry_entry_t * _registry_insert(infix_registry_t * registry, const char * name) {
    // Check load factor. If num_items > num_buckets * 0.75, resize.
    // Equivalent integer math: num_items * 4 > num_buckets * 3
    if (registry->num_items * 4 > registry->num_buckets * 3)
        _registry_rehash(registry);

    uint64_t hash = _registry_hash_string(name);
    size_t index = hash % registry->num_buckets;
    _infix_registry_entry_t * new_entry =
        infix_arena_alloc(registry->arena, sizeof(_infix_registry_entry_t), _Alignof(_infix_registry_entry_t));
    if (!new_entry) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return nullptr;
    }
    size_t name_len = strlen(name) + 1;
    char * name_copy = infix_arena_alloc(registry->arena, name_len, 1);
    if (!name_copy) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return nullptr;
    }
    infix_memcpy((void *)name_copy, name, name_len);
    new_entry->name = name_copy;
    new_entry->hash = hash;
    new_entry->type = nullptr;
    new_entry->is_forward_declaration = false;
    // Prepend to the linked list in the bucket.
    new_entry->next = registry->buckets[index];
    registry->buckets[index] = new_entry;
    registry->num_items++;
    return new_entry;
}
// Public API: Registry Lifecycle
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
INFIX_API c23_nodiscard infix_registry_t * infix_registry_create(void) {
    _infix_clear_error();
    infix_registry_t * registry = infix_malloc(sizeof(infix_registry_t));
    if (!registry) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return nullptr;
    }
    registry->arena = infix_arena_create(16384);  // Default initial size
    if (!registry->arena) {
        infix_free(registry);
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return nullptr;
    }
    registry->is_external_arena = false;  // Mark that this arena is owned by the registry.
    registry->num_buckets = INITIAL_REGISTRY_BUCKETS;
    registry->buckets = infix_calloc(registry->num_buckets, sizeof(_infix_registry_entry_t *));
    if (!registry->buckets) {
        infix_arena_destroy(registry->arena);
        infix_free(registry);
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return nullptr;
    }
    registry->num_items = 0;
    return registry;
}
/**
 * @brief Creates a new, empty named type registry that allocates from a user-provided arena.
 *
 * A registry acts as a dictionary for `infix` types, allowing you to define complex
 * structs, unions, or aliases once and refer to them by name (e.g., `@MyStruct`)
 * in any signature string. This is essential for managing complex, recursive, or
 * mutually-dependent types.
 *
 * @param[in] arena The arena to allocate from.
 * @return A pointer to the new registry, or `nullptr` on allocation failure. The returned
 *         handle must be freed with `infix_registry_destroy`.
 */
INFIX_API c23_nodiscard infix_registry_t * infix_registry_create_in_arena(infix_arena_t * arena) {
    _infix_clear_error();
    if (!arena) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_NULL_POINTER, 0);
        return nullptr;
    }
    infix_registry_t * registry = infix_malloc(sizeof(infix_registry_t));
    if (!registry) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return nullptr;
    }
    registry->arena = arena;
    registry->is_external_arena = true;  // Mark the arena as user-owned
    registry->num_buckets = INITIAL_REGISTRY_BUCKETS;
    registry->buckets = infix_calloc(registry->num_buckets, sizeof(_infix_registry_entry_t *));
    if (!registry->buckets) {
        infix_free(registry);
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return nullptr;
    }
    registry->num_items = 0;
    return registry;
}
/**
 * @brief Creates a deep copy of an existing registry.
 * @param src The source registry to clone.
 * @return A new registry containing deep copies of all types in 'src', or NULL on failure.
 */
INFIX_API c23_nodiscard infix_registry_t * infix_registry_clone(const infix_registry_t * src) {
    if (!src)
        return nullptr;

    infix_registry_t * dest = infix_registry_create();
    if (!dest)
        return nullptr;

    // Iterate over all buckets in the source registry
    for (size_t i = 0; i < src->num_buckets; ++i) {
        _infix_registry_entry_t * entry = src->buckets[i];
        while (entry) {
            // Create a new entry in the destination registry.
            // _registry_insert handles allocating the entry and copying the name string.
            _infix_registry_entry_t * new_entry = _registry_insert(dest, entry->name);
            if (!new_entry) {
                infix_registry_destroy(dest);
                return nullptr;
            }

            // Copy flags
            new_entry->is_forward_declaration = entry->is_forward_declaration;

            // Deep copy the type graph into the new registry's arena
            if (entry->type) {
                new_entry->type = _copy_type_graph_to_arena(dest->arena, entry->type);
                if (!new_entry->type) {
                    infix_registry_destroy(dest);
                    return nullptr;
                }
            }

            entry = entry->next;
        }
    }
    return dest;
}
/**
 * @brief Destroys a type registry and frees all associated memory.
 *
 * This includes freeing the registry handle itself and its internal arena, which in
 * turn frees the hash table, all entry structs, and all canonical `infix_type`
 * objects that were created as part of a type definition.
 *
 * @param[in] registry The registry to destroy. Safe to call with `nullptr`.
 */
INFIX_API void infix_registry_destroy(infix_registry_t * registry) {
    if (!registry)
        return;
    // Only destroy the arena if it was created internally by `infix_registry_create`.
    if (!registry->is_external_arena)
        infix_arena_destroy(registry->arena);
    // Free the bucket array which is now allocated from the heap.
    infix_free(registry->buckets);
    // Always free the registry struct itself.
    infix_free(registry);
}
// Internal Type Graph Resolution
/**
 * @internal
 * @brief Recursively walks a type graph and resolves all named type references in-place.
 *
 * @details This function implements the **"Resolve"** stage of the data pipeline. It modifies
 * the type graph by replacing `INFIX_TYPE_NAMED_REFERENCE` nodes with direct
 * pointers to the canonical types stored in the registry. It uses a "visited set"
 * (`memo_head`) to handle cycles correctly and avoid infinite recursion.
 *
 * @param[in,out] type_ptr A pointer to the `infix_type*` to resolve. This is a
 *        pointer-to-a-pointer, which is critical because it allows this function
 *        to *replace* the pointer at the call site (e.g., changing a member's
 *        type from a named reference to a concrete struct type).
 * @param[in] registry The registry to use for lookups.
 * @param[in,out] memo_head The head of the visited set for cycle detection.
 * @return `INFIX_SUCCESS` on success, or `INFIX_ERROR_INVALID_ARGUMENT` if a type
 *         cannot be resolved.
 */
static infix_status _resolve_type_graph_inplace_recursive(infix_arena_t * temp_arena,
                                                          infix_type ** type_ptr,
                                                          infix_registry_t * registry,
                                                          resolve_memo_node_t ** memo_head) {
    if (!type_ptr || !*type_ptr || !(*type_ptr)->is_arena_allocated)
        return INFIX_SUCCESS;
    infix_type * type = *type_ptr;
    // Cycle detection: If we've seen this node before, we're in a cycle.
    // Return success to break the loop.
    for (resolve_memo_node_t * node = *memo_head; node != nullptr; node = node->next)
        if (node->src == type)
            return INFIX_SUCCESS;
    // Allocate the memoization node from the stable temporary arena.
    resolve_memo_node_t * memo_node =
        infix_arena_alloc(temp_arena, sizeof(resolve_memo_node_t), _Alignof(resolve_memo_node_t));
    if (!memo_node) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    memo_node->src = type;
    memo_node->next = *memo_head;
    *memo_head = memo_node;
    if (type->category == INFIX_TYPE_NAMED_REFERENCE) {
        if (!registry) {
            _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_UNRESOLVED_NAMED_TYPE, type->source_offset);
            return INFIX_ERROR_INVALID_ARGUMENT;
        }
        const char * name = type->meta.named_reference.name;
        _infix_registry_entry_t * entry = _registry_lookup(registry, name);
        if (!entry || !entry->type) {
            _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_UNRESOLVED_NAMED_TYPE, type->source_offset);
            return INFIX_ERROR_INVALID_ARGUMENT;
        }
        *type_ptr = entry->type;
        return INFIX_SUCCESS;
    }
    infix_status status = INFIX_SUCCESS;
    switch (type->category) {
    case INFIX_TYPE_POINTER:
        status = _resolve_type_graph_inplace_recursive(
            temp_arena, &type->meta.pointer_info.pointee_type, registry, memo_head);
        break;
    case INFIX_TYPE_ARRAY:
        status =
            _resolve_type_graph_inplace_recursive(temp_arena, &type->meta.array_info.element_type, registry, memo_head);
        break;
    case INFIX_TYPE_STRUCT:
    case INFIX_TYPE_UNION:
        for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
            status = _resolve_type_graph_inplace_recursive(
                temp_arena, &type->meta.aggregate_info.members[i].type, registry, memo_head);
            if (status != INFIX_SUCCESS)
                break;
        }
        break;
    case INFIX_TYPE_REVERSE_TRAMPOLINE:
        status = _resolve_type_graph_inplace_recursive(
            temp_arena, &type->meta.func_ptr_info.return_type, registry, memo_head);
        if (status != INFIX_SUCCESS)
            break;
        for (size_t i = 0; i < type->meta.func_ptr_info.num_args; ++i) {
            status = _resolve_type_graph_inplace_recursive(
                temp_arena, &type->meta.func_ptr_info.args[i].type, registry, memo_head);
            if (status != INFIX_SUCCESS)
                break;
        }
        break;
    case INFIX_TYPE_ENUM:
        status = _resolve_type_graph_inplace_recursive(
            temp_arena, &type->meta.enum_info.underlying_type, registry, memo_head);
        break;
    case INFIX_TYPE_COMPLEX:
        status =
            _resolve_type_graph_inplace_recursive(temp_arena, &type->meta.complex_info.base_type, registry, memo_head);
        break;
    case INFIX_TYPE_VECTOR:
        status = _resolve_type_graph_inplace_recursive(
            temp_arena, &type->meta.vector_info.element_type, registry, memo_head);
        break;
    default:
        break;
    }
    return status;
}
/**
 * @internal
 * @brief Public-internal wrapper for the recursive resolution function.
 * @param[in,out] type_ptr A pointer to the root of the type graph to resolve.
 * @param[in] registry The registry to use for lookups.
 * @return `INFIX_SUCCESS` on success.
 */
c23_nodiscard infix_status _infix_resolve_type_graph_inplace(infix_type ** type_ptr, infix_registry_t * registry) {
    // Create a temporary arena solely for the visited list's lifetime.
    infix_arena_t * temp_arena = infix_arena_create(1024);
    if (!temp_arena) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    resolve_memo_node_t * memo_head = nullptr;
    infix_status status = _resolve_type_graph_inplace_recursive(temp_arena, type_ptr, registry, &memo_head);
    infix_arena_destroy(temp_arena);
    return status;
}
// Public API: Type Registration
/**
 * @internal
 * @struct _registry_parser_state_t
 * @brief A minimal parser state for processing registry definition strings.
 * @details This is distinct from the main signature `parser_state` because the
 * grammar for definitions (`@Name=...;`) is much simpler and can be handled
 * with a simpler, non-recursive parser.
 */
typedef struct {
    const char * p;     /**< The current position in the definition string. */
    const char * start; /**< The start of the definition string for error reporting. */
} _registry_parser_state_t;
/**
 * @internal
 * @brief Skips whitespace and C++-style line comments in a definition string.
 * @param state The parser state to advance.
 */
static void _registry_parser_skip_whitespace(_registry_parser_state_t * state) {
    while (1) {
        while (isspace((unsigned char)*state->p))
            state->p++;
        if (*state->p == '#')  // Skip comments
            while (*state->p != '\n' && *state->p != '\0')
                state->p++;
        else
            break;
    }
}
/**
 * @internal
 * @brief Parses a type name (e.g., `MyType`, `NS::MyType`) from the definition string.
 * @param state The parser state to advance.
 * @param buffer A buffer to store the parsed name.
 * @param buf_size The size of the buffer.
 * @return A pointer to the `buffer` on success, or `nullptr` if no valid identifier is found.
 */
static char * _registry_parser_parse_name(_registry_parser_state_t * state, char * buffer, size_t buf_size) {
    _registry_parser_skip_whitespace(state);
    const char * name_start = state->p;
    if (!isalpha((unsigned char)*name_start) && *name_start != '_')
        return nullptr;
    while (isalnum((unsigned char)*state->p) || *state->p == '_' || *state->p == ':') {
        if (*state->p == ':' && state->p[1] != ':')
            break;  // Handle single colon as non-identifier char.
        if (*state->p == ':')
            state->p++;  // Skip the first ':' of '::'
        state->p++;
    }
    size_t len = state->p - name_start;
    if (len == 0 || len >= buf_size)
        return nullptr;
    infix_memcpy(buffer, name_start, len);
    buffer[len] = '\0';
    return buffer;
}
/**
 * @brief Parses a string of type definitions and adds them to a registry.
 *
 * @details This function uses a robust **three-pass approach** to handle complex dependencies,
 * including out-of-order and mutually recursive definitions.
 *
 * - **Pass 1 (Scan & Index):** The entire definition string is scanned. The parser
 *   identifies every type name being defined (`@Name = ...`) or forward-declared
 *   (`@Name;`). It creates an entry for each name in the registry's hash table.
 *   Critically, if a forward declaration is found, a placeholder `infix_type` is
 *   created immediately to ensure subsequent lookups succeed.
 *
 * - **Pass 2 (Parse & Copy):** The function iterates through the definitions
 *   indexed in Pass 1. For each one, it calls the main signature parser to create
 *   a raw type graph. This graph is then copied into the registry's arena. If a
 *   placeholder already exists from Pass 1, the new definition is copied *in-place*
 *   over the placeholder to preserve existing pointers.
 *
 * - **Pass 3 (Resolve & Layout):** The function iterates through all the newly
 *   created types from Pass 2. For each one, it performs the "Resolve" and
 *   "Layout" stages. Because all type graphs now exist (either fully defined or
 *   as valid placeholders), resolution succeeds for all recursive references.
 *
 * @param[in] registry The registry to populate.
 * @param[in] definitions A semicolon-separated string of definitions.
 * @return `INFIX_SUCCESS` on success, or an error code on failure.
 */
INFIX_API c23_nodiscard infix_status infix_register_types(infix_registry_t * registry, const char * definitions) {
    _infix_clear_error();
    if (!registry || !definitions) {
        _infix_set_error(INFIX_CATEGORY_GENERAL, INFIX_CODE_NULL_POINTER, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }
    _registry_parser_state_t state = {.p = definitions, .start = definitions};
    g_infix_last_signature_context = definitions;
    // A temporary structure to hold information about each definition found in Pass 1.
    struct def_info {
        _infix_registry_entry_t * entry;
        const char * def_body_start;
        size_t def_body_len;
    };
    size_t defs_capacity = 64;  // Start with an initial capacity.
    struct def_info * defs_found = infix_malloc(sizeof(struct def_info) * defs_capacity);
    if (!defs_found) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        return INFIX_ERROR_ALLOCATION_FAILED;
    }
    size_t num_defs_found = 0;
    infix_status final_status = INFIX_SUCCESS;

    // Pass 1: Scan & Index all names and their definition bodies.
    while (*state.p != '\0') {
        _registry_parser_skip_whitespace(&state);
        if (*state.p == '\0')
            break;
        if (*state.p != '@') {
            _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_UNEXPECTED_TOKEN, state.p - state.start);
            final_status = INFIX_ERROR_INVALID_ARGUMENT;
            goto cleanup;
        }
        state.p++;
        char name_buffer[256];
        if (!_registry_parser_parse_name(&state, name_buffer, sizeof(name_buffer))) {
            _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_UNEXPECTED_TOKEN, state.p - state.start);
            final_status = INFIX_ERROR_INVALID_ARGUMENT;
            goto cleanup;
        }
        _infix_registry_entry_t * entry = _registry_lookup(registry, name_buffer);
        _registry_parser_skip_whitespace(&state);
        if (*state.p == '=') {  // This is a full definition.
            state.p++;
            _registry_parser_skip_whitespace(&state);
            // It's an error to redefine a type that wasn't a forward declaration.
            if (entry && !entry->is_forward_declaration) {
                _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_UNEXPECTED_TOKEN, state.p - state.start);
                final_status = INFIX_ERROR_INVALID_ARGUMENT;
                goto cleanup;
            }
            if (!entry) {  // If it doesn't exist, create it.
                entry = _registry_insert(registry, name_buffer);
                if (!entry) {
                    final_status = INFIX_ERROR_ALLOCATION_FAILED;
                    goto cleanup;
                }
            }
            if (num_defs_found >= defs_capacity) {
                size_t new_capacity = defs_capacity * 2;
                struct def_info * new_defs = infix_realloc(defs_found, sizeof(struct def_info) * new_capacity);
                if (!new_defs) {
                    _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, state.p - state.start);
                    final_status = INFIX_ERROR_ALLOCATION_FAILED;
                    goto cleanup;
                }
                defs_found = new_defs;
                defs_capacity = new_capacity;
            }
            // Find the end of the type definition body (the next top-level ';').
            defs_found[num_defs_found].entry = entry;
            defs_found[num_defs_found].def_body_start = state.p;
            int nest_level = 0;
            const char * body_end = state.p;
            while (*body_end != '\0' &&
                   !(*body_end == ';' &&
                     nest_level == 0)) {  // Explicitly check for and skip over the '->' token as a single unit.
                if (*body_end == '-' && body_end[1] == '>') {
                    body_end += 2;  // Advance the pointer past the entire token.
                    continue;       // Continue to the next character in the loop.
                }
                if (*body_end == '{' || *body_end == '<' || *body_end == '(' || *body_end == '[')
                    nest_level++;
                if (*body_end == '}' || *body_end == '>' || *body_end == ')' || *body_end == ']')
                    nest_level--;
                body_end++;
            }
            defs_found[num_defs_found].def_body_len = body_end - state.p;
            state.p = body_end;
            num_defs_found++;
        }
        else if (*state.p == ';') {  // This is a forward declaration.
            if (entry) {
                // If the type is already fully defined, re-declaring it as a forward decl is an error.
                if (!entry->is_forward_declaration) {
                    _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_UNEXPECTED_TOKEN, state.p - state.start);
                    final_status = INFIX_ERROR_INVALID_ARGUMENT;
                    goto cleanup;
                }
                // If it's already a forward declaration, this is a no-op.
            }
            else {
                entry = _registry_insert(registry, name_buffer);
                if (!entry) {
                    final_status = INFIX_ERROR_ALLOCATION_FAILED;
                    goto cleanup;
                }
            }
            // Ensure a placeholder type exists so other types can reference it immediately.
            // We create an opaque struct (size 0) as the placeholder and mark it incomplete.
            if (!entry->type) {
                entry->type = infix_arena_calloc(registry->arena, 1, sizeof(infix_type), _Alignof(infix_type));
                if (!entry->type) {
                    final_status = INFIX_ERROR_ALLOCATION_FAILED;
                    goto cleanup;
                }
                entry->type->is_arena_allocated = true;
                entry->type->is_incomplete = true;  // Mark as incomplete
                entry->type->arena = registry->arena;
                entry->type->category = INFIX_TYPE_STRUCT;
                entry->type->size = 0;
                entry->type->alignment = 1;  // Minimal alignment to pass basic validation
                entry->type->name = entry->name;
            }
            entry->is_forward_declaration = true;
        }
        else {
            _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_UNEXPECTED_TOKEN, state.p - state.start);
            final_status = INFIX_ERROR_INVALID_ARGUMENT;
            goto cleanup;
        }
        if (*state.p == ';')
            state.p++;
    }

    // Use a single temporary arena for ALL definitions in this batch to reduce malloc pressure.
    infix_arena_t * parser_arena = infix_arena_create(65536);
    if (!parser_arena) {
        _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
        final_status = INFIX_ERROR_ALLOCATION_FAILED;
        goto cleanup;
    }

    // Pass 2: Parse the bodies of all found definitions into the registry.
    for (size_t i = 0; i < num_defs_found; ++i) {
        _infix_registry_entry_t * entry = defs_found[i].entry;

        // FAST-PATH: Check if the definition body is just a single primitive keyword.
        // This avoids the overhead of the recursive-descent parser for simple aliases.
        infix_type * fast_primitive = nullptr;
        char body_buffer[64];
        if (defs_found[i].def_body_len > 0 && defs_found[i].def_body_len < sizeof(body_buffer)) {
            infix_memcpy(body_buffer, defs_found[i].def_body_start, defs_found[i].def_body_len);
            body_buffer[defs_found[i].def_body_len] = '\0';

            // Use a temporary parser state for parse_primitive.
            parser_state fast_state = {.p = body_buffer, .start = body_buffer, .arena = parser_arena, .depth = 0};
            fast_primitive = parse_primitive(&fast_state);

            // Ensure no trailing junk even in fast-path.
            if (fast_primitive) {
                skip_whitespace(&fast_state);
                if (*fast_state.p != '\0')
                    fast_primitive = nullptr;
            }
        }

        infix_type * raw_type = nullptr;
        if (fast_primitive) {
            raw_type = fast_primitive;
        }
        else {
            // SLOW-PATH: Fall back to full signature parser.
            // Make a temporary, null-terminated copy of the definition body substring.
            char * body_copy = infix_malloc(defs_found[i].def_body_len + 1);
            if (!body_copy) {
                _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
                final_status = INFIX_ERROR_ALLOCATION_FAILED;
                infix_arena_destroy(parser_arena);
                goto cleanup;
            }
            infix_memcpy(body_copy, defs_found[i].def_body_start, defs_found[i].def_body_len);
            body_copy[defs_found[i].def_body_len] = '\0';

            parser_state state = {.p = body_copy, .start = body_copy, .arena = parser_arena, .depth = 0};
            raw_type = parse_type(&state);

            if (raw_type) {
                skip_whitespace(&state);
                if (*state.p != '\0') {
                    _infix_set_parser_error(&state, INFIX_CODE_UNEXPECTED_TOKEN);
                    raw_type = nullptr;
                }
            }

            if (!raw_type) {
                infix_error_details_t err = infix_get_last_error();
                _infix_set_error(err.category, err.code, (defs_found[i].def_body_start - definitions) + err.position);
                final_status = INFIX_ERROR_INVALID_ARGUMENT;
                infix_free(body_copy);
                infix_arena_destroy(parser_arena);
                goto cleanup;
            }
            infix_free(body_copy);
        }

        const infix_type * type_to_alias = raw_type;
        // If the RHS is another named type (e.g., @MyAlias = @ExistingType),
        // we need to resolve it first to get the actual type we're aliasing.
        if (raw_type->category == INFIX_TYPE_NAMED_REFERENCE) {
            _infix_registry_entry_t * existing_entry = _registry_lookup(registry, raw_type->meta.named_reference.name);
            if (existing_entry && existing_entry->type)
                type_to_alias = existing_entry->type;
            else {
                size_t relative_pos = raw_type->source_offset;
                _infix_set_error(INFIX_CATEGORY_PARSER,
                                 INFIX_CODE_UNRESOLVED_NAMED_TYPE,
                                 (size_t)(defs_found[i].def_body_start - definitions) + relative_pos);
                final_status = INFIX_ERROR_INVALID_ARGUMENT;
                infix_arena_destroy(parser_arena);
                goto cleanup;
            }
        }
        // Prepare the new definition.
        infix_type * new_def = nullptr;
        if (!type_to_alias->is_arena_allocated) {
            // This is a static type (e.g., primitive). We MUST create a mutable
            // copy in the registry's arena before we can attach a name to it.
            // This prevents corrupting the global static singletons.
            new_def = infix_arena_alloc(registry->arena, sizeof(infix_type), _Alignof(infix_type));
            if (new_def) {
                *new_def = *type_to_alias;
                new_def->is_arena_allocated = true;
                new_def->arena = registry->arena;
            }
        }
        else  // Dynamic type: deep copy.
            new_def = _copy_type_graph_to_arena(registry->arena, type_to_alias);

        if (!new_def) {
            _infix_set_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, 0);
            final_status = INFIX_ERROR_ALLOCATION_FAILED;
            infix_arena_destroy(parser_arena);
            goto cleanup;
        }

        // Update the entry. If a placeholder already exists (from forward decl), we MUST update it in-place
        // to preserve pointers from other types that have already resolved to it.
        if (entry->type) {
            // Struct-copy the new definition into the existing placeholder memory.
            *entry->type = *new_def;
            // Restore the self-reference if the copy logic pointed the arena elsewhere.
            entry->type->arena = registry->arena;
            // The new definition is complete, so ensure the flag is cleared.
            entry->type->is_incomplete = false;
        }
        else {
            entry->type = new_def;
            entry->type->is_incomplete = false;
        }

        // Ensure the name is attached and the flag is cleared.
        entry->type->name = entry->name;
        entry->is_forward_declaration = false;
    }

    infix_arena_destroy(parser_arena);

    // Pass 3: Resolve and layout all the newly defined types.
    for (size_t i = 0; i < num_defs_found; ++i) {
        _infix_registry_entry_t * entry = defs_found[i].entry;
        if (entry->type) {
            // "Resolve" and "Layout" steps.
            if (_infix_resolve_type_graph_inplace(&entry->type, registry) != INFIX_SUCCESS) {
                // The error was set inside resolve (relative to body).
                // We need to re-base it to the full definitions string.
                infix_error_details_t err = infix_get_last_error();
                size_t body_offset = defs_found[i].def_body_start - definitions;
                _infix_set_error(err.category, err.code, body_offset + err.position);
                final_status = INFIX_ERROR_INVALID_ARGUMENT;
                goto cleanup;
            }
            _infix_type_recalculate_layout(entry->type);
        }
    }
cleanup:
    infix_free(defs_found);
    return final_status;
}
// Registry Introspection API Implementation
/**
 * @brief Initializes an iterator for traversing the types in a registry.
 *
 * @details This function creates an iterator that can be used with `infix_registry_iterator_next`
 * to loop through all fully-defined types in a registry. The order of traversal
 * is not guaranteed.
 *
 * @param[in] registry The registry to iterate over.
 * @return An initialized iterator. If the registry is empty, the first call to
 *         `infix_registry_iterator_next` on this iterator will return `false`.
 * @code
 * infix_registry_iterator_t it = infix_registry_iterator_begin(registry);
 * while (infix_registry_iterator_next(&it)) {
 *     const char* name = infix_registry_iterator_get_name(&it);
 *     const infix_type* type = infix_registry_iterator_get_type(&it);
 *     printf("Found type: %s\n", name);
 * }
 * @endcode
 */
INFIX_API c23_nodiscard infix_registry_iterator_t infix_registry_iterator_begin(const infix_registry_t * registry) {
    // Return an iterator positioned before the first element.
    // The first call to next() will advance it to the first valid element.
    infix_registry_iterator_t it;
    it.registry = registry;
    it._bucket_index = 0;
    it._current_entry = nullptr;
    return it;
}

/**
 * @brief Advances the iterator to the next defined type in the registry.
 *
 * @param[in,out] iterator The iterator to advance.
 * @return `true` if the iterator was advanced to a valid type, or `false` if there are
 *         no more types to visit.
 */
INFIX_API c23_nodiscard bool infix_registry_iterator_next(infix_registry_iterator_t * iter) {
    if (!iter || !iter->registry)
        return false;

    // Cast the opaque void* back to the internal entry type
    const _infix_registry_entry_t * entry = (const _infix_registry_entry_t *)iter->_current_entry;

    // If we have a current entry, start from the next one in the chain.
    if (entry)
        entry = entry->next;
    // Otherwise, if we are starting (or moved buckets), begin with the head of the current bucket.
    else if (iter->_bucket_index < iter->registry->num_buckets)
        entry = iter->registry->buckets[iter->_bucket_index];

    while (true) {
        // Traverse the current chain looking for a valid entry.
        while (entry) {
            if (entry->type && !entry->is_forward_declaration) {
                // Found one. Update the iterator and return successfully.
                iter->_current_entry = (void *)entry;
                return true;
            }
            entry = entry->next;
        }
        // If we're here, the current chain is exhausted. Move to the next bucket.
        iter->_bucket_index++;
        // If there are no more buckets, we're done.
        if (iter->_bucket_index >= iter->registry->num_buckets) {
            iter->_current_entry = nullptr;
            return false;
        }
        // Start the search from the head of the new bucket.
        entry = iter->registry->buckets[iter->_bucket_index];
    }
}
/**
 * @brief Gets the name of the type at the iterator's current position.
 *
 * @param[in] iterator The iterator, which must have been successfully advanced by
 *            `infix_registry_iterator_next`.
 * @return The name of the type (e.g., "Point"), or `nullptr` if the iterator is invalid
 *         or has reached the end of the collection.
 */
INFIX_API c23_nodiscard const char * infix_registry_iterator_get_name(const infix_registry_iterator_t * iter) {
    if (!iter || !iter->_current_entry)
        return nullptr;
    const _infix_registry_entry_t * entry = (const _infix_registry_entry_t *)iter->_current_entry;
    return entry->name;
}
/**
 * @brief Gets the `infix_type` object of the type at the iterator's current position.
 *
 * @param[in] iterator The iterator, which must have been successfully advanced by
 *            `infix_registry_iterator_next`.
 * @return A pointer to the canonical `infix_type` object, or `nullptr` if the iterator
 *         is invalid or has reached the end of the collection.
 */
INFIX_API c23_nodiscard const infix_type * infix_registry_iterator_get_type(const infix_registry_iterator_t * iter) {
    if (!iter || !iter->_current_entry)
        return nullptr;
    const _infix_registry_entry_t * entry = (const _infix_registry_entry_t *)iter->_current_entry;
    return entry->type;
}
/**
 * @brief Checks if a type with the given name is fully defined in the registry.
 *
 * @details This function will return `false` for names that are only forward-declared
 * (e.g., via `@Name;`) but have not been given a complete definition.
 *
 * @param[in] registry The registry to search.
 * @param[in] name The name of the type to check (e.g., "MyStruct").
 * @return `true` if a complete definition for the name exists, `false` otherwise.
 */
INFIX_API c23_nodiscard bool infix_registry_is_defined(const infix_registry_t * registry, const char * name) {
    if (!registry || !name)
        return false;
    _infix_registry_entry_t * entry = _registry_lookup((infix_registry_t *)registry, name);
    // It's defined if an entry exists, it has a type, and it's not a lingering forward declaration.
    return entry != nullptr && entry->type != nullptr && !entry->is_forward_declaration;
}
/**
 * @brief Retrieves the canonical `infix_type` object for a given name from the registry.
 *
 * @param[in] registry The registry to search.
 * @param[in] name The name of the type to retrieve (e.g., "Point").
 * @return A pointer to the canonical `infix_type` object if found and fully defined.
 *         Returns `nullptr` if the name is not found or is only a forward declaration.
 *         The returned pointer is owned by the registry and is valid for its lifetime.
 */
INFIX_API c23_nodiscard const infix_type * infix_registry_lookup_type(const infix_registry_t * registry,
                                                                      const char * name) {
    if (!registry || !name)
        return nullptr;
    _infix_registry_entry_t * entry = _registry_lookup((infix_registry_t *)registry, name);
    if (entry && entry->type && !entry->is_forward_declaration)
        return entry->type;
    return nullptr;
}