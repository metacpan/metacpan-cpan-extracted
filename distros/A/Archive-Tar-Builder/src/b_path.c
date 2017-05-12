#include <stdlib.h>
#include <string.h>
#include "b_string.h"
#include "b_stack.h"
#include "b_path.h"
#include "b_util.h"

b_stack *b_path_new(b_string *string) {
    b_stack *ret;
    char *item, *dup, *tmp, *ctx = NULL;

    if ((ret = b_stack_new(0)) == NULL) {
        goto error_stack_new;
    }

    b_stack_set_destructor(ret, B_STACK_DESTRUCTOR(b_string_free));

    if ((dup = malloc(string->len + 1)) == NULL) {
        goto error_malloc;
    }

    if (memcpy(dup, string->str, string->len) == NULL) {
        goto error_memcpy;
    }

    dup[string->len] = '\0';

    tmp = dup;

    while ((item = strtok_r(tmp, "/", &ctx)) != NULL) {
        b_string *item_copy;

        tmp = NULL;

        /*
         * Skip all but the first "." component for consideration.
         */
        if (b_stack_count(ret) > 0 && strcmp(item, ".") == 0) {
            continue;
        }

        /*
         * Since strtok_r() discards any empty items, for convenience an empty
         * string object will be added to the beginning of the stack if the input
         * path is absolute.
         */
        if (b_stack_count(ret) == 0 && string->str[0] == '/') {
            b_stack_push(ret, b_string_new(""));
        }

        if ((item_copy = b_string_new(item)) == NULL) {
            goto error_item_copy;
        }

        if (b_stack_push(ret, item_copy) == NULL) {
            goto error_item_push;
        }
    }

    /*
     * If there are still no items in the stack, then add /, if the path is
     * absolute.  This is necessary because a path of '/', or '//' passed to
     * strtok_r() would yield no results (see strtok(3) for details).
     */
    if (b_stack_count(ret) == 0 && string->str[0] == '/') {
        if (b_stack_push(ret, b_string_new("/")) == NULL) {
            goto error_item_push;
        }
    }

    free(dup);

    return ret;

error_item_push:
error_item_copy:
error_memcpy:
    free(dup);

error_malloc:
    b_stack_destroy(ret);

error_stack_new:
    return NULL;
}

b_string *b_path_clean(b_string *string) {
    b_string *ret;
    b_stack *parts;

    if ((parts = b_path_new(string)) == NULL) {
        goto error_path_new;
    }

    if ((ret = b_string_join("/", parts)) == NULL) {
        goto error_join;
    }

    b_stack_destroy(parts);

    return ret;

error_join:
    b_stack_destroy(parts);

error_path_new:
    return NULL;
}

b_string *b_path_clean_str(char *str) {
    b_string *ret;
    b_string *tmp;

    if ((tmp = b_string_new(str)) == NULL) {
        goto error_string_new;
    }

    if ((ret = b_path_clean(tmp)) == NULL) {
        goto error_path_clean;
    }

    b_string_free(tmp);

    return ret;

error_path_clean:
    b_string_free(tmp);

error_string_new:
    return NULL;
}
