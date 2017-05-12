#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include "b_string.h"
#include "b_stack.h"
#include "b_util.h"

b_string *b_string_join(char *sep, b_stack *items) {
    b_string *ret;
    size_t i = 0, count = 0, off = 0, len, seplen;

    if ((ret = malloc(sizeof(*ret))) == NULL) {
        goto error_malloc;
    }

    ret->str = NULL;
    ret->len = 0;

    /*
     * First, calculate the length of the string buffer to be returned, even
     * if there are zero items on the input stack.
     */
    count  = b_stack_count(items);
    seplen = strlen(sep);
    len    = count? seplen * (count - 1): 0;

    for (i=0; i<count; i++) {
        b_string *item;

        if ((item = b_stack_item_at(items, i)) == NULL) {
            goto error_item_at_len;
        }

        len += b_string_len(item);
    }

    if ((ret->str = malloc(len + 1)) == NULL) {
        goto error_malloc_str;
    }

    ret->len = len;

    /*
     * Next, copy each item into the buffer.
     */
    for (i=0; i<count; i++) {
        b_string *item;
        size_t itemlen;

        if ((item = b_stack_item_at(items, i)) == NULL) {
            goto error_item_at;
        }

        itemlen = b_string_len(item);

        if (seplen > 0 && i) {
            if (memcpy(ret->str + off, sep, seplen) == NULL) {
                goto error_memcpy_sep;
            }

            off += seplen;
        }

        if (itemlen > 0) {
            if (memcpy(ret->str + off, item->str, itemlen) == NULL) {
                goto error_memcpy_item;
            }

            off += itemlen;
        }
    }

    /*
     * Finally, add the nul terminator.
     */
    ret->str[len] = '\0';

    return ret;

error_memcpy_item:
error_memcpy_sep:
error_item_at:
    free(ret->str);

error_malloc_str:
error_item_at_len:
    free(ret);

error_malloc:
    return NULL;
}

b_string *b_readlink(b_string *path, struct stat *st) {
    b_string *ret;
    char *buf = NULL;

    if ((buf = malloc(st->st_size + 1)) == NULL) {
        goto error_malloc_buf;
    }

    if (readlink(path->str, buf, st->st_size) < 0) {
        goto error_readlink;
    }

    buf[st->st_size] = '\x00';

    if ((ret = malloc(sizeof(*ret))) == NULL) {
        goto error_malloc_ret;
    }

    ret->str = buf;
    ret->len = st->st_size;

    return ret;

error_malloc_ret:
error_readlink:
    free(buf);

error_malloc_buf:
    return NULL;
}
