/**
 * Copyright (c) 2025 Sanko Robinson
 *
 * This source code is dual-licensed under the Artistic License 2.0 or the MIT License.
 * You may choose to use the code under the terms of either license.
 *
 * SPDX-License-Identifier: (Artistic-2.0 OR MIT)
 */
/**
 * @file emit_pe.c
 * @brief PE binary format support for emit system.
 */
#include "common/compat_c23.h"
#include "emit/emit.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static c23_maybe_unused void write_optional_header(emit_context_t * ctx, uint64_t code_size) {
    (void)ctx;
    (void)code_size;
}
