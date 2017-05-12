/*
 * Copyright (c) 2014, cPanel, Inc.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 */

#ifndef _B_ERROR_H
#define _B_ERROR_H

#include "b_string.h"

typedef void (*b_error_callback)(void *err);

#define B_ERROR_CALLBACK(c) ((b_error_callback)c)

enum b_error_type {
    B_ERROR_OK    = 0,
    B_ERROR_WARN  = 1,
    B_ERROR_FATAL = 2
};

typedef struct _b_error {
    enum b_error_type  type;
    int                status;
    int                _errno;
    b_string *         message;
    b_string *         path;
    b_error_callback   callback;
} b_error;

b_error *  b_error_new();
void       b_error_set_callback(b_error *err, b_error_callback callback);
void       b_error_set(b_error *err, enum b_error_type type, int _errno, char *message, b_string *path);
void       b_error_clear(b_error *err);
int        b_error_warn(b_error *err);
int        b_error_fatal(b_error *err);
int        b_error_status(b_error *err);
int        b_error_errno(b_error *err);
b_string * b_error_path(b_error *err);
b_string * b_error_message(b_error *err);
void       b_error_reset(b_error *err);
void       b_error_destroy(b_error *err);

#endif /* _B_ERROR_H */
