/*
 * Copyright (c) 2019, cPanel, L.L.C.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 */

#ifndef _B_BUILDER_H
#define _B_BUILDER_H

#include <sys/types.h>
#include "b_stack.h"
#include "b_string.h"
#include "b_header.h"
#include "b_buffer.h"
#include "b_error.h"

#define B_USER_LOOKUP(s) ((b_user_lookup)s)
#define B_HARDLINK_LOOKUP(s) ((b_hardlink_lookup)s)

enum b_builder_options {
    B_BUILDER_NONE               = 0,
    B_BUILDER_QUIET              = 1 << 0,
    B_BUILDER_IGNORE_ERRORS      = 1 << 1,
    B_BUILDER_FOLLOW_SYMLINKS    = 1 << 2,
    B_BUILDER_PRESERVE_HARDLINKS = 1 << 3,
    B_BUILDER_GNU_EXTENSIONS     = 1 << 4,
    B_BUILDER_PAX_EXTENSIONS     = 1 << 5,
    B_BUILDER_IGNORE_SOCKETS     = 1 << 6,
    B_BUILDER_EXTENSIONS_MASK    = (B_BUILDER_GNU_EXTENSIONS |
                                    B_BUILDER_PAX_EXTENSIONS)
};

typedef int (*b_user_lookup)(
    void *      ctx,
    uid_t       uid,
    gid_t       gid,
    b_string ** user,
    b_string ** group
);

typedef b_string * (*b_hardlink_lookup)(
    void *     ctx,
    dev_t      dev,
    ino_t      ino,
    b_string * path
);

typedef struct _b_builder {
    b_buffer *             buf;
    b_error *              err;
    size_t                 total;
    struct lafe_matching * match;
    enum b_builder_options options;
    b_user_lookup          user_lookup;
    void *                 user_cache;
    b_hardlink_lookup      hardlink_lookup;
    void *                 hardlink_cache;
    void *                 data;
} b_builder;

b_builder * b_builder_new(size_t block_factor);

enum b_builder_options b_builder_get_options(b_builder *builder);

void b_builder_set_options(
    b_builder *            builder,
    enum b_builder_options options
);

b_error * b_builder_get_error(b_builder *builder);

b_buffer * b_builder_get_buffer(b_builder *builder);

void b_builder_set_data(
    b_builder * builder,
    void *      data
);

void b_builder_set_user_lookup(
    b_builder *      builder,
    b_user_lookup service,
    void *           ctx
);

void b_builder_set_hardlink_cache(
    b_builder *       builder,
    b_hardlink_lookup lookup,
    void *            cache
);

int b_builder_is_excluded(
    b_builder *  builder,
    const char * path
);

int b_builder_include(
    b_builder *  builder,
    const char * pattern
);

int b_builder_include_from_file(
    b_builder *  builder,
    const char * file
);

int b_builder_exclude(
    b_builder *  builder,
    const char * pattern
);

int b_builder_exclude_from_file(
    b_builder *  builder,
    const char * file
);

int b_builder_write_file(
    b_builder *   builder,
    b_string *    path,
    b_string *    member_name,
    struct stat * st,
    int           fd
);

void b_builder_destroy(b_builder *builder);

#endif /* _B_BUILDER_H */
