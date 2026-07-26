/**
 * Copyright (c) 2025 Sanko Robinson
 *
 * This source code is dual-licensed under the Artistic License 2.0 or the MIT License.
 * You may choose to use the code under the terms of either license.
 *
 * SPDX-License-Identifier: (Artistic-2.0 OR MIT)
 */
/**
 * @file emit_internals.h
 * @brief Internal structures for the emit JIT code generation system.
 */
#ifndef INFIX_EMIT_INTERNALS_H
#define INFIX_EMIT_INTERNALS_H

#include "emit/emit.h"
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef struct emit_section {
    char * name;
    emit_section_flags_t flags;
    uint8_t * data;
    uint64_t size;
    uint64_t capacity;
    struct emit_section * next;
} emit_section_t;

typedef struct emit_symbol {
    char * name;
    bool is_defined;
    bool is_function;
    emit_section_t * section;
    uint64_t value;
    struct emit_symbol * next;
} emit_symbol_t;

typedef struct emit_relocation {
    char * symbol_name;
    char * section_name;
    uint64_t offset;
    uint8_t size;
    uint8_t inst_size;
    bool is_pc_relative;
    struct emit_relocation * next;
} emit_relocation_t;

typedef struct emit_context {
    emit_architecture_t arch;
    emit_format_t format;
    emit_state_t state;
    emit_section_t * sections;
    emit_section_t * current_section;
    emit_symbol_t * symbols;
    emit_relocation_t * relocations;
    void * binary_spec;
    char * current_block_name;
    int section_count;
} emit_context_t;

void _emit_context_init(emit_context_t * ctx, emit_architecture_t arch, emit_format_t format);
void _emit_context_free(emit_context_t * ctx);
emit_section_t * _emit_lookup_section(emit_context_t * ctx, const char * name);
emit_symbol_t * _emit_lookup_symbol(emit_context_t * ctx, const char * name);
infix_status _emit_resolve_relocations(emit_context_t * ctx);

#endif /* INFIX_EMIT_INTERNALS_H */
