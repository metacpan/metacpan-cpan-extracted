#include <stdlib.h>
#include <string.h>
#include "b_string.h"
#include "b_error.h"

b_error *b_error_new() {
    b_error *err;

    if ((err = malloc(sizeof(*err))) == NULL) {
        goto error_malloc;
    }

    err->type     = B_ERROR_OK;
    err->status   = 0;
    err->_errno   = 0;
    err->path     = NULL;
    err->message  = NULL;
    err->callback = NULL;

    return err;

error_malloc:
    return NULL;
}

void b_error_set_callback(b_error *err, b_error_callback callback) {
    if (err == NULL) return;

    err->callback = callback;
}

void b_error_set(b_error *err, enum b_error_type type, int _errno, char *message, b_string *path) {
    if (err == NULL) return;

    err->type   = type;
    err->_errno = _errno;

    if ( type == B_ERROR_FATAL ) {
        err->status = -1;
    }

    b_string_free(err->message);
    b_string_free(err->path);

    if ((err->message = b_string_new(message)) == NULL) {
        goto error_string_dup_message;
    }

    if ((err->path = b_string_dup(path)) == NULL) {
        goto error_string_dup_path;
    }

    if (err->callback) {
        err->callback(err);
    }

    return;

error_string_dup_path:
    b_string_free(err->message);
    err->message = NULL;

error_string_dup_message:
    return;
}

void b_error_clear(b_error *err) {
    if (err == NULL) return;

    err->type   = B_ERROR_OK;
    err->_errno = 0;

    b_string_free(err->message);
    err->message = NULL;

    b_string_free(err->path);
    err->path = NULL;
}

int b_error_warn(b_error *err) {
    if (err == NULL) return 0;

    return err->type == B_ERROR_WARN;
}

int b_error_fatal(b_error *err) {
    if (err == NULL) return 0;

    return err->type == B_ERROR_FATAL;
}

int b_error_status(b_error *err) {
    if (err == NULL) return -1;

    return err->status;
}

int b_error_errno(b_error *err) {
    if (err == NULL) return -1;

    return err->_errno;
}

b_string *b_error_message(b_error *err) {
    if (err == NULL) return NULL;

    return err->message;
}

b_string *b_error_path(b_error *err) {
    if (err == NULL) return NULL;

    return err->path;
}

void b_error_reset(b_error *err) {
    if (err == NULL) return;

    b_string_free(err->message);
    err->message = NULL;

    b_string_free(err->path);
    err->path = NULL;

    err->status = 0;
    err->_errno = 0;
}

void b_error_destroy(b_error *err) {
    if (err == NULL) return;

    b_string_free(err->message);
    err->message = NULL;

    b_string_free(err->path);
    err->path = NULL;

    err->status   = 0;
    err->_errno   = 0;
    err->callback = NULL;

    free(err);
}
