/*
 * Copyright (c) 2014, cPanel, Inc.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 */

#ifndef _B_UTIL_H
#define _B_UTIL_H

#include <sys/stat.h>
#include "b_string.h"
#include "b_stack.h"

b_string * b_string_join(char *sep, b_stack *items);
b_string * b_readlink(b_string *path, struct stat *st);

#endif /* _B_UTIL_H */
