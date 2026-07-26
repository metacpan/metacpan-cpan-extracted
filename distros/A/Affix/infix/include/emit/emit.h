/**
 * Copyright (c) 2025 Sanko Robinson
 *
 * This source code is dual-licensed under the Artistic License 2.0 or the MIT License.
 * You may choose to use the code under the terms of either license.
 *
 * SPDX-License-Identifier: (Artistic-2.0 OR MIT)
 */
/**
 * @file emit.h
 * @brief Public API for the emit JIT code generation system.
 */
#ifndef INFIX_EMIT_H
#define INFIX_EMIT_H

#include <infix/infix.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) || defined(__CYGWIN__)
#define INFIX_EMIT_API __declspec(dllexport)
#else
#define INFIX_EMIT_API __attribute__((visibility("default")))
#endif

typedef enum {
    EMIT_ARCH_X86_64,
    EMIT_ARCH_AARCH64,
} emit_architecture_t;

typedef enum {
    EMIT_FORMAT_BINARY,
    EMIT_FORMAT_ELF,
    EMIT_FORMAT_PE,
} emit_format_t;

typedef enum {
    EMIT_SECTION_FLAG_NONE = 0,
    EMIT_SECTION_FLAG_ALLOC = 1 << 0,
    EMIT_SECTION_FLAG_WRITE = 1 << 1,
    EMIT_SECTION_FLAG_EXECUTE = 1 << 2,
} emit_section_flags_t;

typedef enum {
    EMIT_VISIBILITY_DEFAULT,
    EMIT_VISIBILITY_HIDDEN,
    EMIT_VISIBILITY_PROTECTED,
} emit_visibility_t;

typedef enum {
    EMIT_STATE_IDLE,
    EMIT_STATE_SECTION_ACTIVE,
    EMIT_STATE_SECTION_INACTIVE,
} emit_state_t;

typedef struct emit_context emit_context_t;

INFIX_EMIT_API infix_status emit_create(emit_context_t ** out_ctx, emit_architecture_t arch, emit_format_t format);
INFIX_EMIT_API void emit_destroy(emit_context_t * ctx);

INFIX_EMIT_API infix_status emit_add_section(emit_context_t * ctx, const char * name, emit_section_flags_t flags);
INFIX_EMIT_API infix_status emit_begin_section(emit_context_t * ctx, const char * name);

INFIX_EMIT_API infix_status emit_define_symbol(emit_context_t * ctx,
                                               const char * name,
                                               emit_visibility_t visibility,
                                               bool is_function);
INFIX_EMIT_API infix_status emit_emit_label(emit_context_t * ctx, const char * name);
INFIX_EMIT_API infix_status emit_create_label(emit_context_t * ctx, const char * name);

INFIX_EMIT_API infix_status emit_emit_u8(emit_context_t * ctx, uint8_t value);
INFIX_EMIT_API infix_status emit_emit_u16(emit_context_t * ctx, uint16_t value);
INFIX_EMIT_API infix_status emit_emit_u32(emit_context_t * ctx, uint32_t value);
INFIX_EMIT_API infix_status emit_emit_u64(emit_context_t * ctx, uint64_t value);

INFIX_EMIT_API infix_status emit_get_binary(const emit_context_t * ctx, const uint8_t ** out_data, size_t * out_size);
INFIX_EMIT_API infix_status emit_get_offset(const emit_context_t * ctx, uint64_t * out_offset);

INFIX_EMIT_API infix_status emit_align(emit_context_t * ctx, uint64_t alignment);

#ifdef __cplusplus
}
#endif

#endif /* INFIX_EMIT_H */
