/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/** Clownfish::CFC::Util - Miscellaneous helper functions.
 *
 * Clownfish::CFC::Util provides a few convenience functions used internally by
 * other Clownfish modules.
 */

#ifndef H_CFCUTIL
#define H_CFCUTIL

#ifdef __cplusplus
extern "C" {
#endif

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>

#define CFCUTIL_TRY                                   \
    do {                                              \
        jmp_buf env;                                  \
        jmp_buf *prev_env = CFCUtil_try_start(&env);  \
        if (!setjmp(env))

#define CFCUTIL_CATCH(error)                          \
        error = CFCUtil_try_end(prev_env);            \
    } while (0)


/** Create an inner Perl object with a refcount of 1.  For use in actual
 * Perl-space, it is necessary to wrap this inner object in an RV.
 */
void*
CFCUtil_make_perl_obj(void *ptr, const char *klass);

/** Throw an error if the supplied argument is NULL.
 */
void
CFCUtil_null_check(const void *arg, const char *name, const char *file, int line);
#define CFCUTIL_NULL_CHECK(arg) \
    CFCUtil_null_check(arg, #arg, __FILE__, __LINE__)

/** Portable, NULL-safe implementation of strdup().
 */
char*
CFCUtil_strdup(const char *string);

/** Portable, NULL-safe implementation of strndup().
 */
char*
CFCUtil_strndup(const char *string, size_t len);

/** Return a dynamically allocated string with content defined by a printf
 * format string and additional arguments. Similar to asprintf().
 */
char*
CFCUtil_sprintf(const char *fmt, ...);

char*
CFCUtil_vsprintf(const char *fmt, va_list args);

/** Concatenate a NULL-terminated list of strings onto the first, reallocating
 * with each argument.
 */
char*
CFCUtil_cat(char *string, ...);

/** Trim whitespace from the beginning and the end of a string.
 */
void
CFCUtil_trim_whitespace(char *text);

/** Replace all occurrences of `match` in `string` with `replacement`.
 */
char*
CFCUtil_global_replace(const char *string, const char *match,
                       const char *replacement);

/** Enclose every line in text with line_prefix and line_postfix and the
 * whole text with prefix and postfix.
 */
char*
CFCUtil_enclose_lines(const char *text, const char *line_prefix,
                      const char *line_postfix, const char *prefix,
                      const char *postfix);

/** Create a C comment.
 */
char*
CFCUtil_make_c_comment(const char *text);

/** Create a HTML comment.
 */
char*
CFCUtil_make_html_comment(const char *text);

/** Create a Perl comment.
 */
char*
CFCUtil_make_perl_comment(const char *text);

/** Create a troff comment.
 */
char*
CFCUtil_make_troff_comment(const char *text);

/** Attempt to allocate memory with malloc, but print an error and exit if the
 * call fails.
 */
void*
CFCUtil_wrapped_malloc(size_t count, const char *file, int line);

/** Attempt to allocate memory with calloc, but print an error and exit if the
 * call fails.
 */
void*
CFCUtil_wrapped_calloc(size_t count, size_t size, const char *file, int line);

/** Attempt to allocate memory with realloc, but print an error and exit if
 * the call fails.
 */
void*
CFCUtil_wrapped_realloc(void *ptr, size_t size, const char *file, int line);

/** Free memory.  (Wrapping is necessary in cases where memory allocated
 * within Clownfish has to be freed in an external environment where "free"
 * may have been redefined.)
 */
void
CFCUtil_wrapped_free(void *ptr);

#define MALLOCATE(_count) \
    CFCUtil_wrapped_malloc((_count), __FILE__, __LINE__)
#define CALLOCATE(_count, _size) \
    CFCUtil_wrapped_calloc((_count), (_size), __FILE__, __LINE__)
#define REALLOCATE(_ptr, _count) \
    CFCUtil_wrapped_realloc((_ptr), (_count), __FILE__, __LINE__)
#define FREEMEM(_ptr) \
    CFCUtil_wrapped_free(_ptr)

/** Safe wrappers for ctype.h functions.
 */

int
CFCUtil_isalnum(char c);

int
CFCUtil_isalpha(char c);

int
CFCUtil_isdigit(char c);

int
CFCUtil_islower(char c);

int
CFCUtil_isspace(char c);

int
CFCUtil_isupper(char c);

char
CFCUtil_tolower(char c);

char
CFCUtil_toupper(char c);

/** Given two filepaths, return true if the second exists and has a
 * modification time which more recent than that of the first.
 */
int
CFCUtil_current(const char *orig, const char *dest);

/* Open a file (truncating if necessary) and write [content] to it.  CFCUtil_die() if
 * an error occurs.
 */
void
CFCUtil_write_file(const char *filename, const char *content, size_t len);

/** Test whether there's a file at `path` which already matches
 * `content` exactly.  If something has changed, write the file.
 * Otherwise do nothing (and avoid bumping the file's modification time).
 *
 * @return true if the file was written, false otherwise.
 */
int
CFCUtil_write_if_changed(const char *path, const char *content, size_t len);

/* Read an entire file (as text) into memory.
 */
char*
CFCUtil_slurp_text(const char *file_path, size_t *len_ptr);

/* Get the length of a file (may overshoot on text files under DOS).
 */
long
CFCUtil_flength(void *file);

/* Platform-agnostic opendir wrapper.
 */
void*
CFCUtil_opendir(const char *dir);

/* Platform-agnostic readdir wrapper.
 */
const char*
CFCUtil_dirnext(void *dirhandle);

/* Platform-agnostic closedir wrapper.
 */
void
CFCUtil_closedir(void *dirhandle, const char *dir);

/* Returns true if the supplied path is a directory, false otherwise.
 */
int
CFCUtil_is_dir(const char *path);

/* Create the specified directory.  Returns true on success, false on failure.
 */
int
CFCUtil_make_dir(const char *dir);

/* Create the specified path including all subdirectories.  Returns true on
 * success, false on failure.  Intermediate directories may be left behind on
 * failure.
 */
int
CFCUtil_make_path(const char *path);

/* Walk the file system, recursing into subdirectories.  Invoke the supplied
 * callback for each valid, accessible file system entry.
 */
typedef void
(*CFCUtil_walk_callback_t)(const char *path, void *context);
void
CFCUtil_walk(const char *dir, CFCUtil_walk_callback_t callback,
             void *context);

/* Free an array of strings.
 */
void
CFCUtil_free_string_array(char **strings);

/* Print an error message to stderr and exit.
 */
void
CFCUtil_die(const char *format, ...);

/* Rethrow an error.
 */
void
CFCUtil_rethrow(char *error);

/* Print an error message to stderr.
 */
void
CFCUtil_warn(const char *format, ...);

jmp_buf*
CFCUtil_try_start(jmp_buf *env);

char*
CFCUtil_try_end(jmp_buf *prev_env);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCUTIL */

