#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#ifdef __linux__
#include <sys/stat.h>
#include <sys/utsname.h>
#include <stdio.h>
#endif
#include "b_buffer.h"

b_buffer *b_buffer_new(size_t factor) {
    b_buffer *buf;

    if ((buf = malloc(sizeof(*buf))) == NULL) {
        goto error_malloc;
    }

    buf->fd         = 0;
    buf->can_splice = 0;
    buf->size       = factor? factor * B_BUFFER_BLOCK_SIZE: B_BUFFER_DEFAULT_FACTOR * B_BUFFER_BLOCK_SIZE;
    buf->unused     = buf->size;

    if ((buf->data = malloc(buf->size)) == NULL) {
        goto error_malloc_buf;
    }

    memset(buf->data, 0x00, buf->size);

    return buf;

error_malloc_buf:
    buf->data       = NULL;
    buf->can_splice = 0;
    buf->fd         = 0;
    buf->size       = 0;

    free(buf);

error_malloc:
    return NULL;
}

int b_buffer_get_fd(b_buffer *buf) {
    if (buf == NULL) return 0;

    return buf->fd;
}

void b_buffer_set_fd(b_buffer *buf, int fd) {
#ifdef __linux__
    struct stat st;
    char *release, *kernel, *major, *minor;
    int kernel_v, major_v, minor_v;
    struct utsname unameData;
    int uname_ok;
#endif
    if (buf == NULL) return;

    buf->fd         = fd;
    buf->can_splice = 0;
#ifdef __linux__
    if (fstat(fd, &st) == 0) {
        if (S_ISFIFO(st.st_mode)) {
            uname_ok = uname(&unameData);
            if (uname_ok != -1) {
                release = unameData.release;
                kernel = strtok(release, ".");
                major = strtok(NULL, ".");
                minor = strtok(NULL, ".");
                if (release && major && minor) {
                    kernel_v = strtol(kernel,NULL,10);
                    major_v = strtol(major,NULL,10);
                    minor_v = strtol(minor,NULL,10);
                    if (kernel_v >= 3 || (kernel_v == 2 && major_v == 6 && minor_v >= 31) ) {
                        buf->can_splice = 1;
                    }
                }
            }
        }
    }
#endif
    return;
}

size_t b_buffer_size(b_buffer *buf) {
    if (buf == NULL) return 0;

    return buf->size;
}

size_t b_buffer_unused(b_buffer *buf) {
    if (buf == NULL) return 0;

    return buf->unused;
}

int b_buffer_full(b_buffer *buf) {
    if (buf == NULL) return 0;

    return buf->unused == 0;
}

static inline size_t padded_size(size_t size) {
    if (size % B_BUFFER_BLOCK_SIZE == 0) {
        return size;
    }

    return size + (B_BUFFER_BLOCK_SIZE - (size % B_BUFFER_BLOCK_SIZE));
}

off_t b_buffer_reclaim(b_buffer *buf, size_t used, size_t given) {
    size_t padded_len = padded_size(used);
    off_t amount;

    if (buf == NULL || given == 0 || given % B_BUFFER_BLOCK_SIZE) {
        errno = EINVAL;
        return -1;
    }

    amount = given - padded_len;

    buf->unused += amount;

    return amount;
}

void *b_buffer_get_block(b_buffer *buf, size_t len, off_t *given) {
    size_t offset;
    size_t padded_len = padded_size(len);

    if (buf == NULL) {
        errno = EINVAL;
        goto error;
    }

    if (len == 0) return NULL;

    if (buf->fd == 0) {
        errno = EBADF;
        goto error;
    }

    /*
     * If the buffer is full prior to allocating a block, then flush the buffer
     * to make room for a new block.
     */
    if (b_buffer_full(buf)) {
        if (b_buffer_flush(buf) < 0) {
            goto error;
        }
    }

    /*
     * Complain if the buffer block request calls for more buffer space than is
     * available.
     */
    if (padded_len > buf->unused) {
        errno = EFBIG;
        goto error;
    }

    /*
     * Determine the physical location of the buffer block to return to the
     * caller.
     */
    offset = buf->size - buf->unused;

    /*
     * Update the buffer to indicate that less fill data is unused.
     */
    buf->unused -= padded_len;

    /*
     * Update the 'given' parameter to indicate how much data was given.
     */
    if (given) {
        *given = padded_len;
    }

    return buf->data + offset;

error:
    if (given) {
        *given = -1;
    }

    return NULL;
}

ssize_t b_buffer_flush(b_buffer *buf) {
    ssize_t ret = 0;
    ssize_t off = 0;

    if (buf == NULL || buf->data == NULL) {
        errno = EINVAL;
        return -1;
    }

    if (buf->fd == 0) {
        errno = EBADF;
        return -1;
    }

    if (buf->size == 0)           return 0;
    if (buf->unused == buf->size) return 0;

    while ((off < buf->size) || (ret < 0 && errno == EINTR)) {
        if ((ret = write(buf->fd, buf->data + off, buf->size - off)) < 0) {
            if (errno != EINTR)
                return ret;
        }
        else if (!ret) {
            break;
        }
        else {
            off += ret;
        }
    }

    memset(buf->data, 0x00, buf->size);

    buf->unused = buf->size;

    return ret;
}

void b_buffer_reset(b_buffer *buf) {
    if (buf == NULL) return;

    buf->fd     = 0;
    buf->unused = buf->size;

    if (buf->data == NULL) return;

    memset(buf->data, 0x00, buf->size);
}

void b_buffer_destroy(b_buffer *buf) {
    if (buf == NULL) return;

    if (buf->data) {
        free(buf->data);
        buf->data = NULL;
    }

    buf->fd     = 0;
    buf->size   = 0;
    buf->unused = 0;

    free(buf);
}
