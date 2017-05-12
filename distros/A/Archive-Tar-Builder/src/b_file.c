#ifdef __linux__
#define _GNU_SOURCE         /* See feature_test_macros(7) */
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <limits.h>

#include "b_builder.h"
#include "b_header.h"
#include "b_string.h"
#include "b_buffer.h"
#include "b_file.h"

#define MAX_CHUNK_SIZE (16 * 1024 * 1024)

/*
 * Meant to be used in conjunction with header.c/b_header_encode_longlink_block(),
 * this method will write out as many 512-byte blocks as necessary to contain the
 * full path.
 */
off_t b_file_write_path_blocks(b_buffer *buf, b_string *path) {
    size_t i, len;
    off_t blocklen = 0;
    off_t total = 0;

    len = b_string_len(path);

    for (i=0; i<len; i+=B_BLOCK_SIZE) {
        size_t left    = len - i;
        size_t copylen = left < B_BLOCK_SIZE? left: B_BLOCK_SIZE;

        unsigned char *block;

        if ((block = b_buffer_get_block(buf, B_BLOCK_SIZE, &blocklen)) == NULL) {
            goto error_io;
        }

        memcpy(block, path->str + i, copylen);

        total += blocklen;
    }

    return total;

error_io:
    return -1;
}

off_t b_file_write_pax_path_blocks(b_buffer *buf, b_string *path, b_string *linkdest) {
    size_t i, len, full_len, link_full_len = 0, buflen, total_len;
    off_t blocklen = 0;
    off_t total = 0;
    char *buffer = NULL;

    len = b_string_len(path);

    full_len = b_header_compute_pax_length(path, "path");

    if (linkdest)
        link_full_len = b_header_compute_pax_length(linkdest, "linkpath");

    total_len = full_len + link_full_len;

    /* In case we have a broken snprintf. */
    if (full_len == (size_t)-1)
        goto error_io;

    if ((buffer = malloc(total_len + 1)) == NULL)
        goto error_mem;

    snprintf(buffer, total_len + 1, "%d path=%s\n", full_len, path->str);
    if (linkdest)
        snprintf(buffer + full_len, link_full_len + 1, "%d linkpath=%s\n", link_full_len, linkdest->str);

    for (i=0; i<total_len; i+=B_BLOCK_SIZE) {
        size_t left    = total_len - i;
        size_t copylen = left < B_BLOCK_SIZE? left: B_BLOCK_SIZE;

        unsigned char *block;


        if ((block = b_buffer_get_block(buf, B_BLOCK_SIZE, &blocklen)) == NULL) {
            goto error_io;
        }

        memcpy(block, buffer + i, copylen);
        total += blocklen;
    }

    free(buffer);
    return total;

error_io:
error_mem:
    free(buffer);
    return -1;
}

off_t b_file_write_contents(b_buffer *buf, int file_fd, off_t file_size) {
    ssize_t rlen = 0;
    off_t blocklen = 0, total = 0, real_total = 0, max_read = 0;
#ifdef __linux__
    int emptied_buffer = 0, splice_total = 0;
#endif

    do {
        if (b_buffer_full(buf)) {
            if (b_buffer_flush(buf) < 0) {
                goto error_io;
            }
#ifdef __linux__
            emptied_buffer = 1;
#endif
        }

        max_read = file_size - real_total;

        if (max_read > MAX_CHUNK_SIZE) {
             max_read = MAX_CHUNK_SIZE;
        }
        else if (max_read == 0) {
             break;
        }
#ifdef __linux__
        /*
         * Once we have cleared out the buffer we can read the rest of the file
         * with splice and write out a tar padding.
         */
        if (emptied_buffer && buf->can_splice) {
            if ((rlen = splice(file_fd, NULL, buf->fd, NULL, max_read, 0))){
                if (rlen < 0) {
                    buf->can_splice = 0;
                }
                else {
                    splice_total += rlen;
                    total        += rlen;
                }
            }
        }
        if (!emptied_buffer || !buf->can_splice) {
#endif
            unsigned char *block;

            if ((block = b_buffer_get_block(buf, b_buffer_unused(buf), &blocklen)) == NULL) {
                goto error_io;
            }

            if (max_read > blocklen) {
                max_read = blocklen;
            }

           read_retry:
            if ((rlen = read(file_fd, block, max_read)) < max_read) {
                if (rlen < 0 && errno == EINTR) { goto read_retry; }

                goto error_io;
            }

            total += blocklen;
            /*
             * Reclaim any amount of bytes from the buffer that weren't used to
             * store the chunk read() from the filesystem.
             */
            if (blocklen - rlen) {
                total -= b_buffer_reclaim(buf, rlen, blocklen);
            }
#ifdef __linux__
        }
#endif
        real_total += rlen;
    } while (rlen > 0);

#ifdef __linux__
    if (splice_total && buf->can_splice && total % B_BUFFER_BLOCK_SIZE != 0) {
        /*
         * finished splice, now complete the block by writing out zeros to make
         * tar happy
         */
        if ((write(buf->fd, buf->data, B_BUFFER_BLOCK_SIZE - (total % B_BUFFER_BLOCK_SIZE))) < 0) {
            goto error_io;
        }
    }
#endif

    return total;

error_io:
    if (!errno) {
        errno = EINVAL;
    }
    return -1;
}
