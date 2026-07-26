/**
 * Copyright (c) 2025 Sanko Robinson
 *
 * This source code is dual-licensed under the Artistic License 2.0 or the MIT License.
 * You may choose to use the code under the terms of either license.
 *
 * SPDX-License-Identifier: (Artistic-2.0 OR MIT)
 */
/**
 * @file emit.c
 * @brief Implementation of the emit API for generating machine code.
 */
#define INFIX_BUILDING
#include "emit/emit.h"
#include "common/compat_c23.h"
#include "emit_internals.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define EMIT_DEFAULT_SECTION_CAPACITY 4096
#define EMIT_SECTION_GROWTH_FACTOR 2

void _emit_context_init(emit_context_t * ctx, emit_architecture_t arch, emit_format_t format) {
    ctx->arch = arch;
    ctx->format = format;
    ctx->state = EMIT_STATE_IDLE;
    ctx->sections = NULL;
    ctx->current_section = NULL;
    ctx->symbols = NULL;
    ctx->relocations = NULL;
    ctx->binary_spec = NULL;
    ctx->current_block_name = NULL;
    ctx->section_count = 0;
}

void _emit_context_free(emit_context_t * ctx) {
    if (!ctx)
        return;

    emit_section_t * sec = ctx->sections;
    while (sec) {
        emit_section_t * next = sec->next;
        free(sec->name);
        free(sec->data);
        free(sec);
        sec = next;
    }

    emit_symbol_t * sym = ctx->symbols;
    while (sym) {
        emit_symbol_t * next = sym->next;
        free(sym->name);
        free(sym);
        sym = next;
    }

    emit_relocation_t * rel = ctx->relocations;
    while (rel) {
        emit_relocation_t * next = rel->next;
        free(rel->symbol_name);
        free(rel->section_name);
        free(rel);
        rel = next;
    }

    free(ctx->current_block_name);
}

static emit_section_t * _create_section(const char * name, emit_section_flags_t flags) {
    emit_section_t * section = calloc(1, sizeof(emit_section_t));
    if (!section)
        return NULL;

    section->name = strdup(name);
    section->flags = flags;
    section->data = malloc(EMIT_DEFAULT_SECTION_CAPACITY);
    if (!section->data) {
        free(section->name);
        free(section);
        return NULL;
    }
    section->capacity = EMIT_DEFAULT_SECTION_CAPACITY;
    section->size = 0;
    section->next = NULL;

    return section;
}

emit_section_t * _emit_lookup_section(emit_context_t * ctx, const char * name) {
    if (!ctx || !name)
        return NULL;

    for (emit_section_t * sec = ctx->sections; sec != NULL; sec = sec->next)
        if (strcmp(sec->name, name) == 0)
            return sec;
    return NULL;
}

emit_symbol_t * _emit_lookup_symbol(emit_context_t * ctx, const char * name) {
    if (!ctx || !name)
        return NULL;

    for (emit_symbol_t * sym = ctx->symbols; sym != NULL; sym = sym->next)
        if (strcmp(sym->name, name) == 0)
            return sym;
    return NULL;
}

INFIX_API infix_status emit_create(emit_context_t ** out_ctx, emit_architecture_t arch, emit_format_t format) {
    _infix_clear_error();
    if (!out_ctx) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_KEYWORD, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    emit_context_t * ctx = calloc(1, sizeof(emit_context_t));
    if (!ctx)
        return INFIX_ERROR_ALLOCATION_FAILED;

    _emit_context_init(ctx, arch, format);

    *out_ctx = ctx;
    return INFIX_SUCCESS;
}

INFIX_API void emit_destroy(emit_context_t * ctx) {
    _emit_context_free(ctx);
    free(ctx);
}

INFIX_API infix_status emit_add_section(emit_context_t * ctx, const char * name, emit_section_flags_t flags) {
    _infix_clear_error();
    if (!ctx || !name) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_KEYWORD, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    emit_section_t * existing = _emit_lookup_section(ctx, name);
    if (existing) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_KEYWORD, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    emit_section_t * section = _create_section(name, flags);
    if (!section)
        return INFIX_ERROR_ALLOCATION_FAILED;

    section->next = ctx->sections;
    ctx->sections = section;
    ctx->section_count++;

    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_begin_section(emit_context_t * ctx, const char * section_name) {
    _infix_clear_error();
    if (!ctx || !section_name) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_KEYWORD, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    emit_section_t * section = _emit_lookup_section(ctx, section_name);
    if (!section) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_KEYWORD, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    ctx->current_section = section;
    ctx->state = EMIT_STATE_SECTION_ACTIVE;
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_define_symbol(emit_context_t * ctx,
                                          const char * name,
                                          emit_visibility_t visibility,
                                          bool is_function) {
    _infix_clear_error();
    if (!ctx || !name) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_KEYWORD, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    (void)visibility;

    emit_symbol_t * sym = _emit_lookup_symbol(ctx, name);
    if (!sym) {
        sym = calloc(1, sizeof(emit_symbol_t));
        if (!sym)
            return INFIX_ERROR_ALLOCATION_FAILED;

        sym->name = strdup(name);
        sym->next = ctx->symbols;
        ctx->symbols = sym;
    }

    sym->is_defined = true;
    sym->is_function = is_function;
    sym->section = ctx->current_section;
    sym->value = ctx->current_section ? ctx->current_section->size : 0;

    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_emit_label(emit_context_t * ctx, const char * name) {
    _infix_clear_error();
    if (!ctx || !name) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_KEYWORD, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    emit_symbol_t * sym = _emit_lookup_symbol(ctx, name);
    if (!sym) {
        sym = calloc(1, sizeof(emit_symbol_t));
        if (!sym)
            return INFIX_ERROR_ALLOCATION_FAILED;

        sym->name = strdup(name);
        sym->is_defined = true;
        sym->is_function = false;
        sym->section = ctx->current_section;
        sym->value = ctx->current_section ? ctx->current_section->size : 0;

        sym->next = ctx->symbols;
        ctx->symbols = sym;
    }
    else {
        sym->is_defined = true;
        sym->value = ctx->current_section ? ctx->current_section->size : 0;
        sym->section = ctx->current_section;
    }

    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_create_label(emit_context_t * ctx, const char * name) {
    return emit_define_symbol(ctx, name, EMIT_VISIBILITY_DEFAULT, false);
}

static infix_status _ensure_section_capacity(emit_context_t * ctx, uint64_t needed) {
    if (!ctx->current_section)
        return INFIX_ERROR_INVALID_ARGUMENT;

    if (needed <= ctx->current_section->capacity)
        return INFIX_SUCCESS;

    uint64_t new_capacity = ctx->current_section->capacity * EMIT_SECTION_GROWTH_FACTOR;
    while (new_capacity < needed)
        new_capacity *= EMIT_SECTION_GROWTH_FACTOR;

    uint8_t * new_data = realloc(ctx->current_section->data, new_capacity);
    if (!new_data)
        return INFIX_ERROR_ALLOCATION_FAILED;

    ctx->current_section->data = new_data;
    ctx->current_section->capacity = new_capacity;
    return INFIX_SUCCESS;
}

static infix_status emit_emit_bytes(emit_context_t * ctx, const void * data, size_t size) {
    _infix_clear_error();
    if (!ctx || !data) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_KEYWORD, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    if (ctx->state != EMIT_STATE_SECTION_ACTIVE || !ctx->current_section) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_KEYWORD, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    infix_status status = _ensure_section_capacity(ctx, ctx->current_section->size + size);
    if (status != INFIX_SUCCESS)
        return status;

    memcpy(ctx->current_section->data + ctx->current_section->size, data, size);
    ctx->current_section->size += size;

    return INFIX_SUCCESS;
}

INFIX_API INFIX_NODISCARD infix_status emit_emit_u8(emit_context_t * ctx, uint8_t byte) {
    return emit_emit_bytes(ctx, &byte, 1);
}

INFIX_API infix_status emit_emit_u16(emit_context_t * ctx, uint16_t value) {
    uint8_t bytes[2] = {(uint8_t)(value & 0xFF), (uint8_t)((value >> 8) & 0xFF)};
    return emit_emit_bytes(ctx, bytes, 2);
}

INFIX_API INFIX_NODISCARD infix_status emit_emit_u32(emit_context_t * ctx, uint32_t value) {
    uint8_t bytes[4] = {(uint8_t)(value & 0xFF),
                        (uint8_t)((value >> 8) & 0xFF),
                        (uint8_t)((value >> 16) & 0xFF),
                        (uint8_t)((value >> 24) & 0xFF)};
    return emit_emit_bytes(ctx, bytes, 4);
}

INFIX_API infix_status emit_emit_u64(emit_context_t * ctx, uint64_t value) {
    uint8_t bytes[8] = {(uint8_t)(value & 0xFF),
                        (uint8_t)((value >> 8) & 0xFF),
                        (uint8_t)((value >> 16) & 0xFF),
                        (uint8_t)((value >> 24) & 0xFF),
                        (uint8_t)((value >> 32) & 0xFF),
                        (uint8_t)((value >> 40) & 0xFF),
                        (uint8_t)((value >> 48) & 0xFF),
                        (uint8_t)((value >> 56) & 0xFF)};
    return emit_emit_bytes(ctx, bytes, 8);
}

INFIX_API infix_status emit_align(emit_context_t * ctx, uint64_t alignment) {
    _infix_clear_error();
    if (!ctx || !ctx->current_section)
        return INFIX_ERROR_INVALID_ARGUMENT;

    if (alignment == 0)
        return INFIX_SUCCESS;

    uint64_t current = ctx->current_section->size;
    uint64_t aligned = (current + alignment - 1) & ~(alignment - 1);
    uint64_t padding = aligned - current;

    for (uint64_t i = 0; i < padding; i++) {
        infix_status status = emit_emit_u8(ctx, 0x90);
        if (status != INFIX_SUCCESS)
            return status;
    }

    return INFIX_SUCCESS;
}

INFIX_API INFIX_NODISCARD infix_status
emit_add_relocation(emit_context_t * ctx, const char * name, uint64_t offset, uint8_t size, uint8_t inst_size) {
    _infix_clear_error();
    if (!ctx || !name) {
        _infix_set_error(INFIX_CATEGORY_PARSER, INFIX_CODE_INVALID_KEYWORD, 0);
        return INFIX_ERROR_INVALID_ARGUMENT;
    }

    emit_relocation_t * rel = calloc(1, sizeof(emit_relocation_t));
    if (!rel)
        return INFIX_ERROR_ALLOCATION_FAILED;

    rel->symbol_name = strdup(name);
    rel->section_name = ctx->current_section ? strdup(ctx->current_section->name) : NULL;
    rel->offset = offset;
    rel->size = size;
    rel->inst_size = inst_size;
    rel->is_pc_relative = true;

    rel->next = ctx->relocations;
    ctx->relocations = rel;

    return INFIX_SUCCESS;
}

static void write_raw_binary(emit_context_t * ctx, uint8_t * buffer, c23_maybe_unused uint64_t total_size) {
    emit_section_t ** secs = malloc(ctx->section_count * sizeof(emit_section_t *));
    if (!secs)
        return;

    emit_section_t * sec = ctx->sections;
    int count = 0;
    while (sec) {
        secs[count++] = sec;
        sec = sec->next;
    }

    for (int i = count - 1; i >= 0; i--) {
        uint64_t offset = 0;
        for (int j = i + 1; j < count; j++)
            offset += secs[j]->size;

        memcpy(buffer + offset, secs[i]->data, secs[i]->size);
    }

    free(secs);
}

infix_status _emit_resolve_relocations(emit_context_t * ctx) {
    if (!ctx)
        return INFIX_SUCCESS;

    emit_section_t ** secs = malloc(ctx->section_count * sizeof(emit_section_t *));
    if (!secs)
        return INFIX_ERROR_ALLOCATION_FAILED;

    emit_section_t * sec = ctx->sections;
    int count = 0;
    while (sec) {
        secs[count++] = sec;
        sec = sec->next;
    }

    uint64_t section_offsets[32] = {0};
    for (int i = 0; i < count; i++) {
        section_offsets[i] = 0;
        for (int j = i + 1; j < count; j++)
            section_offsets[i] += secs[j]->size;
    }

    for (emit_relocation_t * rel = ctx->relocations; rel != NULL; rel = rel->next) {
        emit_symbol_t * sym = _emit_lookup_symbol(ctx, rel->symbol_name);
        if (!sym || !sym->is_defined)
            continue;

        emit_section_t * target_sec = sym->section;
        if (!target_sec)
            continue;

        emit_section_t * reloc_sec = NULL;
        if (rel->section_name)
            reloc_sec = _emit_lookup_section(ctx, rel->section_name);
        if (!reloc_sec)
            reloc_sec = ctx->current_section;
        if (!reloc_sec || reloc_sec->size == 0 || !reloc_sec->data)
            continue;

        uint64_t target_sec_offset = 0;
        uint64_t reloc_sec_offset = 0;
        for (int i = 0; i < count; i++) {
            if (secs[i] == target_sec)
                target_sec_offset = section_offsets[i];
            if (secs[i] == reloc_sec)
                reloc_sec_offset = section_offsets[i];
        }

        uint64_t target_addr = target_sec_offset + sym->value;
        uint64_t reloc_addr = reloc_sec_offset + rel->offset;

        int64_t displacement = (int64_t)target_addr - (int64_t)(reloc_addr + rel->size);

        if (rel->size == 4) {
            if (rel->is_pc_relative)
                *(int32_t *)(reloc_sec->data + rel->offset) = (int32_t)displacement;
            else
                *(uint32_t *)(reloc_sec->data + rel->offset) = (uint32_t)target_addr;
        }
        else if (rel->size == 8) {
            if (rel->is_pc_relative)
                *(int64_t *)(reloc_sec->data + rel->offset) = displacement;
            else
                *(uint64_t *)(reloc_sec->data + rel->offset) = target_addr;
        }
    }

    free(secs);
    return INFIX_SUCCESS;
}

void _emit_arch_nop(emit_context_t * ctx, uint8_t size) {
    switch (ctx->arch) {
    case EMIT_ARCH_X86_64:
        for (uint8_t i = 0; i < size; i++) {
            infix_status status = emit_emit_u8(ctx, 0x90);
            (void)status;
        }
        break;
    case EMIT_ARCH_AARCH64:
        {
            infix_status status = emit_emit_u32(ctx, 0xD503201F);
            (void)status;
            break;
        }
    default:
        break;
    }
}

infix_status _emit_arch_align(emit_context_t * ctx, uint64_t alignment) {
    switch (ctx->arch) {
    case EMIT_ARCH_X86_64:
        for (uint64_t i = 0; i < alignment; i++) {
            infix_status status = emit_emit_u8(ctx, 0x90);
            if (status != INFIX_SUCCESS)
                return status;
        }
        break;
    case EMIT_ARCH_AARCH64:
        for (uint64_t i = 0; i < alignment; i++) {
            infix_status status = emit_emit_u32(ctx, 0xD503201F);
            if (status != INFIX_SUCCESS)
                return status;
        }
        break;
    default:
        break;
    }
    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_get_binary(const emit_context_t * ctx, const uint8_t ** out_data, size_t * out_size) {
    _infix_clear_error();
    if (!ctx || !out_data || !out_size)
        return INFIX_ERROR_INVALID_ARGUMENT;

    emit_context_t * mutable_ctx = (emit_context_t *)ctx;
    infix_status status = _emit_resolve_relocations(mutable_ctx);
    if (status != INFIX_SUCCESS)
        return status;

    uint64_t total_size = 0;
    for (emit_section_t * sec = ctx->sections; sec != NULL; sec = sec->next)
        total_size += sec->size;

    uint8_t * buffer = malloc(total_size);
    if (!buffer)
        return INFIX_ERROR_ALLOCATION_FAILED;

    write_raw_binary(mutable_ctx, buffer, total_size);

    *out_data = buffer;
    *out_size = total_size;

    return INFIX_SUCCESS;
}

INFIX_API infix_status emit_get_offset(const emit_context_t * ctx, uint64_t * out_offset) {
    _infix_clear_error();
    if (!ctx || !out_offset)
        return INFIX_ERROR_INVALID_ARGUMENT;

    *out_offset = ctx->current_section ? ctx->current_section->size : 0;
    return INFIX_SUCCESS;
}
