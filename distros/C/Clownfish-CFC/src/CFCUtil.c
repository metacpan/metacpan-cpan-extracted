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

#include "charmony.h"

#include <stddef.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>
#include <stdarg.h>
#include <errno.h>
#include <sys/stat.h>
#include <setjmp.h>

// For mkdir.
#ifdef CHY_HAS_DIRECT_H
  #include <direct.h>
#endif

#if !defined(CHY_HAS_C99_SNPRINTF) && !defined(CHY_HAS__SCPRINTF)
  #error "snprintf or replacement not available."
#endif

/* va_copy is not part of C89. Assume that simple assignment works if it
 * isn't defined.
 */
#ifndef va_copy
  #define va_copy(dst, src) ((dst) = (src))
#endif

#ifndef true
    #define true 1
    #define false 0
#endif

#include "CFCUtil.h"

static char    *thrown_error;
static jmp_buf *current_env;

void
CFCUtil_null_check(const void *arg, const char *name, const char *file,
                   int line) {
    if (!arg) {
        CFCUtil_die("%s cannot be NULL at %s line %d", name, file, line);
    }
}

char*
CFCUtil_strdup(const char *string) {
    if (!string) { return NULL; }
    return CFCUtil_strndup(string, strlen(string));
}

char*
CFCUtil_strndup(const char *string, size_t len) {
    if (!string) { return NULL; }
    char *copy = (char*)MALLOCATE(len + 1);
    memcpy(copy, string, len);
    copy[len] = '\0';
    return copy;
}

char*
CFCUtil_sprintf(const char *fmt, ...) {
    va_list args;

    va_start(args, fmt);
    char *string = CFCUtil_vsprintf(fmt, args);
    va_end(args);

    return string;
}

char*
CFCUtil_vsprintf(const char *fmt, va_list args) {
    va_list args_copy;

    va_copy(args_copy, args);
#if defined(CHY_HAS_C99_SNPRINTF)
    int size = vsnprintf(NULL, 0, fmt, args_copy);
    if (size < 0) { CFCUtil_die("snprintf failed"); }
#else
    int size = _vscprintf(fmt, args_copy);
    if (size < 0) { CFCUtil_die("_scprintf failed"); }
#endif
    va_end(args_copy);

    char *string = (char*)MALLOCATE((size_t)size + 1);
    vsprintf(string, fmt, args);

    return string;
}

char*
CFCUtil_cat(char *string, ...) {
    va_list args;
    char *appended;
    CFCUTIL_NULL_CHECK(string);
    size_t size = strlen(string) + 1;
    va_start(args, string);
    while (NULL != (appended = va_arg(args, char*))) {
        size += strlen(appended);
        string = (char*)REALLOCATE(string, size);
        strcat(string, appended);
    }
    va_end(args);
    return string;
}

void
CFCUtil_trim_whitespace(char *text) {
    if (!text) {
        return;
    }

    // Find start.
    char *ptr = text;
    while (*ptr != '\0' && CFCUtil_isspace(*ptr)) { ptr++; }

    // Find end.
    size_t orig_len = strlen(text);
    char *limit = text + orig_len;
    for (; limit > text; limit--) {
        if (!CFCUtil_isspace(*(limit - 1))) { break; }
    }

    // Modify string in place and NULL-terminate.
    while (ptr < limit) {
        *text++ = *ptr++;
    }
    *text = '\0';
}

char*
CFCUtil_global_replace(const char *string, const char *match,
                       const char *replacement) {
    char *found = (char*)string;
    int   string_len      = (int)strlen(string);
    int   match_len       = (int)strlen(match);
    int   replacement_len = (int)strlen(replacement);
    int   len_diff        = replacement_len - match_len;

    // Allocate space.
    int count = 0;
    while (NULL != (found = strstr(found, match))) {
        count++;
        found += match_len;
    }
    int size = string_len + count * len_diff + 1;
    char *modified = (char*)MALLOCATE((size_t)size);
    modified[size - 1] = 0; // NULL-terminate.

    // Iterate through all matches.
    found = (char*)string;
    char *target = modified;
    ptrdiff_t last_end = 0;
    if (count) {
        while (NULL != (found = strstr(found, match))) {
            ptrdiff_t pos = found - string;
            ptrdiff_t unchanged_len = pos - last_end;
            found += match_len;
            memcpy(target, string + last_end, (size_t)unchanged_len);
            target += unchanged_len;
            last_end = pos + match_len;
            memcpy(target, replacement, (size_t)replacement_len);
            target += replacement_len;
        }
    }
    size_t remaining = (size_t)(string_len - last_end);
    memcpy(target, string + string_len - remaining, remaining);

    return modified;
}

char*
CFCUtil_enclose_lines(const char *text, const char *line_prefix,
                      const char *line_postfix, const char *prefix,
                      const char *postfix) {
    if (!text) { return NULL; }

    if (!line_prefix)  { line_prefix  = ""; }
    if (!line_postfix) { line_postfix = ""; }
    if (!prefix)       { prefix       = ""; }
    if (!postfix)      { postfix      = ""; }

    char *result = CFCUtil_strdup(prefix);

    const char *line_start = text;
    const char *text_end   = text + strlen(text);

    while (line_start < text_end) {
        const char *line_end = strchr(line_start, '\n');
        const char *next_start;
        ptrdiff_t   line_len;

        if (line_end == NULL) {
            line_len   = text_end - line_start;
            next_start = text_end;
        }
        else {
            line_len   = line_end - line_start;
            next_start = line_end + 1;
        }

        char *line = (char*)MALLOCATE((size_t)line_len + 1);
        memcpy(line, line_start, (size_t)line_len);
        line[line_len] = '\0';
        result = CFCUtil_cat(result, line_prefix, line, line_postfix, "\n",
                             NULL);
        FREEMEM(line);

        line_start = next_start;
    }

    result = CFCUtil_cat(result, postfix, NULL);

    return result;
}

char*
CFCUtil_make_c_comment(const char *text) {
    if (text && text[0] == '\0') { return CFCUtil_strdup(text); }
    return CFCUtil_enclose_lines(text, " * ", "", "/*\n", " */\n");
}

char*
CFCUtil_make_html_comment(const char *text) {
    if (text && text[0] == '\0') { return CFCUtil_strdup(text); }
    return CFCUtil_enclose_lines(text, "", "", "<!--\n", "-->\n");
}

char*
CFCUtil_make_perl_comment(const char *text) {
    return CFCUtil_enclose_lines(text, "# ", "", "", "");
}

char*
CFCUtil_make_troff_comment(const char *text) {
    return CFCUtil_enclose_lines(text, ".\\\" ", "", "", "");
}

void*
CFCUtil_wrapped_malloc(size_t count, const char *file, int line) {
    void *pointer = malloc(count);
    if (pointer == NULL && count != 0) {
        if (sizeof(long) >= sizeof(size_t)) {
            fprintf(stderr, "Can't malloc %lu bytes at %s line %d\n",
                    (unsigned long)count, file, line);
        }
        else {
            fprintf(stderr, "malloc failed at %s line %d\n", file, line);
        }
        exit(1);
    }
    return pointer;
}

void*
CFCUtil_wrapped_calloc(size_t count, size_t size, const char *file, int line) {
    void *pointer = calloc(count, size);
    if (pointer == NULL && count != 0) {
        if (sizeof(long) >= sizeof(size_t)) {
            fprintf(stderr,
                    "Can't calloc %lu elements of size %lu at %s line %d\n",
                    (unsigned long)count, (unsigned long)size, file, line);
        }
        else {
            fprintf(stderr, "calloc failed at %s line %d\n", file, line);
        }
        exit(1);
    }
    return pointer;
}

void*
CFCUtil_wrapped_realloc(void *ptr, size_t size, const char *file, int line) {
    void *pointer = realloc(ptr, size);
    if (pointer == NULL && size != 0) {
        if (sizeof(long) >= sizeof(size_t)) {
            fprintf(stderr, "Can't realloc %lu bytes at %s line %d\n",
                    (unsigned long)size, file, line);
        }
        else {
            fprintf(stderr, "realloc failed at %s line %d\n", file, line);
        }
        exit(1);
    }
    return pointer;
}

void
CFCUtil_wrapped_free(void *ptr) {
    free(ptr);
}

// Avoid -Wtype-limits warning.
#if CHAR_MAX <= 127
  #define IS_ASCII(c) ((c) >= 0)
#else
  #define IS_ASCII(c) ((c) >= 0 && (c) <= 127)
#endif

int
CFCUtil_isalnum(char c) {
    return IS_ASCII(c) && isalnum(c);
}

int
CFCUtil_isalpha(char c) {
    return IS_ASCII(c) && isalpha(c);
}

int
CFCUtil_isdigit(char c) {
    return IS_ASCII(c) && isdigit(c);
}

int
CFCUtil_islower(char c) {
    return IS_ASCII(c) && islower(c);
}

int
CFCUtil_isspace(char c) {
    return IS_ASCII(c) && isspace(c);
}

int
CFCUtil_isupper(char c) {
    return IS_ASCII(c) && isupper(c);
}

char
CFCUtil_tolower(char c) {
    if (!IS_ASCII(c)) { return c; }
    return (char)tolower(c);
}

char
CFCUtil_toupper(char c) {
    if (!IS_ASCII(c)) { return c; }
    return (char)toupper(c);
}

int
CFCUtil_current(const char *orig, const char *dest) {
    // If the destination file doesn't exist, we're not current.
    struct stat dest_stat;
    if (stat(dest, &dest_stat) == -1) {
        return false;
    }

    // If the source file is newer than the dest, we're not current.
    struct stat orig_stat;
    if (stat(orig, &orig_stat) == -1) {
        CFCUtil_die("Missing source file '%s': %s", orig, strerror(errno));
    }
    if (orig_stat.st_mtime > dest_stat.st_mtime) {
        return false;
    }

    // Current!
    return 1;
}

void
CFCUtil_write_file(const char *filename, const char *content, size_t len) {
    const char *last_sep = strrchr(filename, CHY_DIR_SEP_CHAR);
    if (last_sep != NULL && last_sep != filename) {
        char *dir = CFCUtil_strndup(filename, last_sep - filename);
        if (!CFCUtil_is_dir(dir) && !CFCUtil_make_path(dir)) {
            CFCUtil_die("Couldn't create directory '%s'", dir);
        }
        FREEMEM(dir);
    }

    FILE *fh = fopen(filename, "w+");
    if (fh == NULL) {
        CFCUtil_die("Couldn't open '%s': %s", filename, strerror(errno));
    }
    fwrite(content, sizeof(char), len, fh);
    if (fclose(fh)) {
        CFCUtil_die("Error when closing '%s': %s", filename, strerror(errno));
    }
}

char*
CFCUtil_slurp_text(const char *file_path, size_t *len_ptr) {
    FILE   *const file = fopen(file_path, "r");
    char   *contents;
    size_t  binary_len;
    size_t  text_len;

    /* Sanity check. */
    if (file == NULL) {
        CFCUtil_die("Error opening file '%s': %s", file_path, strerror(errno));
    }

    /* Find length; return NULL if the file has a zero-length. */
    binary_len = (size_t)CFCUtil_flength(file);
    if (binary_len == 0) {
        *len_ptr = 0;
        return NULL;
    }

    /* Allocate memory and read the file. */
    contents = (char*)MALLOCATE(binary_len * sizeof(char) + 1);
    text_len = fread(contents, sizeof(char), binary_len, file);

    /* Weak error check, because CRLF might result in fewer chars read. */
    if (text_len <= 0) {
        CFCUtil_die("Tried to read %ld bytes of '%s', got return code %ld",
                    (long)binary_len, file_path, (long)text_len);
    }

    /* NULL-terminate. */
    contents[text_len] = '\0';

    /* Set length pointer for benefit of caller. */
    *len_ptr = text_len;

    /* Clean up. */
    if (fclose(file)) {
        CFCUtil_die("Error closing file '%s': %s", file_path, strerror(errno));
    }

    return contents;
}

int
CFCUtil_write_if_changed(const char *path, const char *content, size_t len) {
    FILE *f = fopen(path, "r");
    if (f) { // Does file exist?
        if (fclose(f)) {
            CFCUtil_die("Error closing file '%s': %s", path, strerror(errno));
        }
        size_t existing_len;
        char *existing = CFCUtil_slurp_text(path, &existing_len);
        int changed = true;
        if (existing_len == len && strcmp(content, existing) == 0) {
            changed = false;
        }
        FREEMEM(existing);
        if (changed == false) {
            return false;
        }
    }
    CFCUtil_write_file(path, content, len);
    return true;
}

long
CFCUtil_flength(void *file) {
    FILE *f = (FILE*)file;
    const long bookmark = (long)ftell(f);
    long check_val;
    long len;

    /* Seek to end of file and check length. */
    check_val = fseek(f, 0, SEEK_END);
    if (check_val == -1) { CFCUtil_die("fseek error : %s\n", strerror(errno)); }
    len = (long)ftell(f);
    if (len == -1) { CFCUtil_die("ftell error : %s\n", strerror(errno)); }

    /* Return to where we were. */
    check_val = fseek(f, bookmark, SEEK_SET);
    if (check_val == -1) { CFCUtil_die("fseek error : %s\n", strerror(errno)); }

    return len;
}

// Note: this has to be defined before including the Perl headers because they
// redefine stat() in an incompatible way on certain systems (Windows).
int
CFCUtil_is_dir(const char *path) {
    struct stat stat_buf;
    int stat_check = stat(path, &stat_buf);
    if (stat_check == -1) {
        return false;
    }
    return (stat_buf.st_mode & S_IFDIR) ? true : false;
}

int
CFCUtil_make_path(const char *path) {
    CFCUTIL_NULL_CHECK(path);
    char *target = CFCUtil_strdup(path);
    size_t orig_len = strlen(target);
    size_t len = orig_len;
    for (size_t i = 0; i <= len; i++) {
        if (target[i] == CHY_DIR_SEP_CHAR || i == len) {
            target[i] = 0; // NULL-terminate.
            struct stat stat_buf;
            int stat_check = stat(target, &stat_buf);
            if (stat_check != -1) {
                if (!(stat_buf.st_mode & S_IFDIR)) {
                    CFCUtil_die("%s isn't a directory", target);
                }
            }
            else {
                int success = CFCUtil_make_dir(target);
                if (!success) {
                    FREEMEM(target);
                    return false;
                }
            }
            target[i] = CHY_DIR_SEP_CHAR;
        }
    }

    FREEMEM(target);
    return true;
}

void
CFCUtil_walk(const char *path, CFCUtil_walk_callback_t callback,
             void *context) {
    // If it's a valid file system entry, invoke the callback.
    struct stat stat_buf;
    int stat_check = stat(path, &stat_buf);
    if (stat_check == -1) {
        return;
    }
    callback(path, context);

    // Recurse into directories.
    if (!(stat_buf.st_mode & S_IFDIR)) {
        return;
    }
    void   *dirhandle = CFCUtil_opendir(path);
    const char *entry = NULL;
    while (NULL != (entry = CFCUtil_dirnext(dirhandle))) {
        if (strcmp(entry, ".") == 0 || strcmp(entry, "..") == 0) {
            continue;
        }
        char *subpath = CFCUtil_sprintf("%s" CHY_DIR_SEP "%s", path, entry);
        CFCUtil_walk(subpath, callback, context);
        FREEMEM(subpath);
    }
    CFCUtil_closedir(dirhandle, path);
}

void
CFCUtil_free_string_array(char **strings) {
    if (strings == NULL) { return; }

    for (size_t i = 0; strings[i] != NULL; i++) {
        FREEMEM(strings[i]);
    }
    FREEMEM(strings);
}

int
CFCUtil_make_dir(const char *dir) {
    return !chy_makedir(dir, 0777);
}

/******************************** WINDOWS **********************************/
#if (defined(CHY_HAS_WINDOWS_H) && !defined(__CYGWIN__))

#include <windows.h>

typedef struct WinDH {
    HANDLE handle;
    WIN32_FIND_DATA *find_data;
    char path[MAX_PATH + 1];
    int first_time;
} WinDH;

void*
CFCUtil_opendir(const char *dir) {
    size_t dirlen = strlen(dir);
    if (dirlen >= MAX_PATH - 2) {
        CFCUtil_die("Exceeded MAX_PATH(%d): %s", (int)MAX_PATH, dir);
    }
    WinDH *dh = (WinDH*)CALLOCATE(1, sizeof(WinDH));
    dh->find_data = (WIN32_FIND_DATA*)MALLOCATE(sizeof(WIN32_FIND_DATA));

    // Tack on wildcard needed by FindFirstFile.
    sprintf(dh->path, "%s\\*", dir);

    dh->handle = FindFirstFile(dh->path, dh->find_data);
    if (dh->handle == INVALID_HANDLE_VALUE) {
        CFCUtil_die("Can't open dir '%s'", dh->path);
    }
    dh->first_time = true;

    return dh;
}

const char*
CFCUtil_dirnext(void *dirhandle) {
    WinDH *dh = (WinDH*)dirhandle;
    if (dh->first_time) {
        dh->first_time = false;
    }
    else {
        if ((FindNextFile(dh->handle, dh->find_data) == 0)) {
            if (GetLastError() != ERROR_NO_MORE_FILES) {
                CFCUtil_die("Error occurred while reading '%s'",
                            dh->path);
            }
            return NULL;
        }
    }
    return dh->find_data->cFileName;
}

void
CFCUtil_closedir(void *dirhandle, const char *dir) {
    WinDH *dh = (WinDH*)dirhandle;
    if (!FindClose(dh->handle)) {
        CFCUtil_die("Error occurred while closing dir '%s'", dir);
    }
    FREEMEM(dh->find_data);
    FREEMEM(dh);
}

/******************************** UNIXEN ***********************************/
#elif defined(CHY_HAS_DIRENT_H)

#include <dirent.h>

void*
CFCUtil_opendir(const char *dir) {
    DIR *dirhandle = opendir(dir);
    if (!dirhandle) {
        CFCUtil_die("Failed to opendir for '%s': %s", dir, strerror(errno));
    }
    return dirhandle;
}

const char*
CFCUtil_dirnext(void *dirhandle) {
    struct dirent *entry = readdir((DIR*)dirhandle);
    return entry ? entry->d_name : NULL;
}

void
CFCUtil_closedir(void *dirhandle, const char *dir) {
    if (closedir((DIR*)dirhandle) == -1) {
        CFCUtil_die("Error closing dir '%s': %s", dir, strerror(errno));
    }
}

#else
  #error "Need either dirent.h or windows.h"
#endif // CHY_HAS_DIRENT_H vs. CHY_HAS_WINDOWS_H

/***************************************************************************/

jmp_buf*
CFCUtil_try_start(jmp_buf *env) {
    jmp_buf *prev_env = current_env;
    current_env = env;
    return prev_env;
}

char*
CFCUtil_try_end(jmp_buf *prev_env) {
    current_env = prev_env;
    char *error = thrown_error;
    thrown_error = NULL;
    return error;
}

#ifdef CFCPERL

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

// Undo redefinition by XSUB.h with PERL_IMPLICIT_SYS. Needed for
// ActivePerl.
#undef longjmp

void
CFCUtil_die(const char* format, ...) {
    va_list args;
    va_start(args, format);

    if (current_env) {
        thrown_error = CFCUtil_vsprintf(format, args);
        va_end(args);
        longjmp(*current_env, 1);
    }
    else {
        vcroak(format, &args);
        va_end(args);
    }
}

void
CFCUtil_rethrow(char *error) {
    if (current_env) {
        thrown_error = error;
        longjmp(*current_env, 1);
    }
    else {
        sv_setpv(ERRSV, error);
        FREEMEM(error);
        croak(NULL);
    }
}

void
CFCUtil_warn(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vwarn(format, &args);
    va_end(args);
}

#else

void
CFCUtil_die(const char* format, ...) {
    va_list args;
    va_start(args, format);

    if (current_env) {
        thrown_error = CFCUtil_vsprintf(format, args);
        va_end(args);
        longjmp(*current_env, 1);
    }
    else {
        vfprintf(stderr, format, args);
        va_end(args);
        fprintf(stderr, "\n");
        abort();
    }
}

void
CFCUtil_rethrow(char *error) {
    if (current_env) {
        thrown_error = error;
        longjmp(*current_env, 1);
    }
    else {
        fprintf(stderr, "%s\n", error);
        FREEMEM(error);
        abort();
    }
}

void
CFCUtil_warn(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    fprintf(stderr, "\n");
}

#endif /* CFCPERL */

