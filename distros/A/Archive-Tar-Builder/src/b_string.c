#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include "b_string.h"

b_string *b_string_new_len(char *str, size_t len) {
    b_string *ret;

    if ((ret = malloc(sizeof(*ret))) == NULL) {
        goto error_malloc_ret;
    }

    if ((ret->str = malloc(len + 1)) == NULL) {
        goto error_malloc_str;
    }

    strncpy(ret->str, str, len);

    ret->len      = len;
    ret->str[len] = '\0';

    return ret;

error_malloc_str:
    free(ret);

error_malloc_ret:
    return NULL;
}

b_string *b_string_new(char *str) {
    return b_string_new_len(str, strlen(str));
}

b_string *b_string_dup(b_string *string) {
    return b_string_new_len(string->str, string->len);
}

b_string *b_string_append(b_string *string, b_string *add) {
    size_t newlen;
    char *tmp;

    if (add->len == 0) {
        return string;
    }

    newlen = string->len + add->len;

    if ((tmp = realloc(string->str, newlen + 1)) == NULL) {
        goto error_realloc;
    }

    strncpy(tmp + string->len, add->str, add->len);

    string->str         = tmp;
    string->str[newlen] = '\0';
    string->len         = newlen;

    return string;

error_realloc:
    return NULL;
}

b_string *b_string_append_str(b_string *string, char *add_str) {
    size_t add_len, newlen;
    char *tmp;

    if ((add_len = strlen(add_str)) == 0) {
        return string;
    }

    newlen = string->len + add_len;

    if ((tmp = realloc(string->str, newlen + 1)) == NULL) {
        goto error_realloc;
    }

    strncpy(tmp + string->len, add_str, add_len);

    string->str         = tmp;
    string->str[newlen] = '\0';
    string->len         = newlen;

    return string;

error_realloc:
    return NULL;
}

size_t b_string_len(b_string *string) {
    return string->len;
}

void b_string_free(b_string *string) {
    if (string == NULL) return;

    free(string->str);
    string->str = NULL;

    free(string);
}
