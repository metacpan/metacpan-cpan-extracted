/*
 * Copyright (c) 2014, cPanel, Inc.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 */

#ifndef _B_PATH_H
#define _B_PATH_H

#include "b_string.h"
#include "b_stack.h"

b_stack  * b_path_new(b_string *string);
b_string * b_path_clean(b_string *string);
b_string * b_path_clean_str(char *str);

#endif /* _B_PATH_H */
