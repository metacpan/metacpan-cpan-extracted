/*
 * Copyright (c) 2014, cPanel, Inc.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 */

#ifndef _B_STRING_H
#define _B_STRING_H

#include <sys/types.h>

typedef struct _b_string {
    char * str;
    size_t len;
} b_string;

b_string * b_string_new_len(char *str, size_t len);
b_string * b_string_new(char *str);
b_string * b_string_dup(b_string *string);
b_string * b_string_append(b_string *string, b_string *add);
b_string * b_string_append_str(b_string *string, char *add);
size_t     b_string_len(b_string *string);
void       b_string_free(b_string *string);

#endif /* _B_STRING_H */
