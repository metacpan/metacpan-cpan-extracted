/*
 * Copyright (c) 2014, cPanel, Inc.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 */

#ifndef _B_FIND_H
#define _B_FIND_H

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include "b_builder.h"
#include "b_string.h"

#define B_FIND_FOLLOW_SYMLINKS (1 << 0)
#define B_FIND_IGNORE_SOCKETS  (1 << 1)
#define B_FIND_CALLBACK(c)     ((b_find_callback)c)

typedef int (*b_find_callback)(b_builder *builder, b_string *path, b_string *member_name, struct stat *st, int fd);

int b_find(b_builder *builder, b_string *path, b_string *member_name, b_find_callback callback, int flags);

#endif /* _B_FIND_H */
