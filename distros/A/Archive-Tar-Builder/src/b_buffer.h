/*
 * Copyright (c) 2014, cPanel, Inc.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 */

#ifndef _B_BUFFER_H
#define _B_BUFFER_H

#define B_BUFFER_DEFAULT_FACTOR 20
#define B_BUFFER_BLOCK_SIZE     512

#include <sys/types.h>

typedef struct _b_buffer {
    int    fd;
    int    can_splice;
    size_t size;
    size_t unused;
    void * data;
} b_buffer;

b_buffer * b_buffer_new(size_t factor);
int        b_buffer_get_fd(b_buffer *buf);
void       b_buffer_set_fd(b_buffer *buf, int fd);
size_t     b_buffer_size(b_buffer *buf);
size_t     b_buffer_unused(b_buffer *buf);
int        b_buffer_full(b_buffer *buf);
off_t      b_buffer_reclaim(b_buffer *buf, size_t used, size_t given);
void *     b_buffer_get_block(b_buffer *buf, size_t len, off_t *given);
ssize_t    b_buffer_flush(b_buffer *buf);
void       b_buffer_reset(b_buffer *buf);
void       b_buffer_destroy(b_buffer *buf);

#endif /* _B_BUFFER_H */
