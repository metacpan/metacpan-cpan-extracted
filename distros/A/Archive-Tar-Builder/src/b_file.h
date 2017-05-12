/*
 * Copyright (c) 2014, cPanel, Inc.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 */

#ifndef _B_FILE_H
#define _B_FILE_H

#define B_BLOCK_SIZE  512

#include <sys/types.h>
#include "b_string.h"
#include "b_buffer.h"

off_t b_file_write_contents(b_buffer *buf, int file_fd, off_t file_size);
off_t b_file_write_path_blocks(b_buffer *buf, b_string *path);
off_t b_file_write_pax_path_blocks(b_buffer *buf, b_string *path, b_string *linkdest);

#endif /* _B_FILE_H */
