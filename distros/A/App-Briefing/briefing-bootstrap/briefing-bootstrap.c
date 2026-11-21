/*
 * briefing-bootstrap - native Windows entry point for the briefing plugin.
 *
 * The bootstrap accepts only the tracked five-line pin manifest, rehashes the
 * selected Windows binary before every start, provisions it only from the
 * SessionStart hook, and retains the Python/Perl compatibility fallbacks.
 * `hook marketplace-notice` falls back only to the Python notice and otherwise
 * stays silent with exit 0: a courtesy note never becomes a warning.
 */
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0601
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winhttp.h>
#include <bcrypt.h>
#include <aclapi.h>

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

/* No release version is compiled in: it is the one version that all five lines of the
 * pin manifest name (see parse_manifest_bytes). The default base URL is this prefix
 * plus that version, the bundle's tag_format %v. */
#define RELEASE_URL_PREFIX_W L"https://github.com/Getty/briefing/releases/download/"
#define ASSET_PREFIX "briefing-"
#define WINDOWS_ASSET_SUFFIX "-windows-x86_64.exe"
#define PIN_MANIFEST_W L"briefing-binaries.sha256"
#define DOWNLOAD_MAX_BYTES ((ULONGLONG)268435456)
#define MANIFEST_MAX_BYTES ((ULONGLONG)8192)
/* Five lines name the same version, so it cannot exceed a fifth of the manifest. */
#define VERSION_MAX_LENGTH ((size_t)(MANIFEST_MAX_BYTES / 5))
#define HASH_BYTES 32
#define HASH_HEX_LENGTH 64
#define MAX_REDIRECTS 10
#define VERIFIED_OPEN_RETRY_ATTEMPTS 250
#define VERIFIED_OPEN_RETRY_DELAY_MS 20
/* The cache layout of the POSIX starter (bin/briefing): the binary is
 * <config>\briefing\bin\<version>\<pin>\briefing.exe with its PAR directory <pin>\par, where
 * <pin> is the first 16 hex digits of the pinned SHA-256. The pin directory is a name, never
 * the trust anchor: the file is rehashed against the full pin before every start. The short
 * names keep the plain path within reach of PAR's loader (see PAR_TREE_RESERVE). */
#define CACHE_PIN_LENGTH 16
#define CACHE_BINARY_W L"briefing.exe"
#define CACHE_PAR_W L"par"

struct wide_buffer {
    wchar_t *data;
    size_t length;
    size_t capacity;
};

struct private_security {
    HANDLE token;
    PSID sid;
    PSID original_owner;
    PACL acl;
    PACL inheritable_acl;
    SECURITY_DESCRIPTOR descriptor;
    SECURITY_DESCRIPTOR inheritable_descriptor;
    SECURITY_ATTRIBUTES attributes;
    SECURITY_ATTRIBUTES inheritable_attributes;
    int token_user_owner_active;
};

struct parsed_url {
    wchar_t *host;
    wchar_t *request;
    INTERNET_PORT port;
    int secure;
};

struct pin_manifest {
    unsigned char windows_hash[HASH_BYTES];
    wchar_t windows_hex[HASH_HEX_LENGTH + 1];
    wchar_t version[VERSION_MAX_LENGTH + 1];
    wchar_t windows_asset[
        sizeof(ASSET_PREFIX) + VERSION_MAX_LENGTH + sizeof(WINDOWS_ASSET_SUFFIX)
    ];
};

struct cache_lock_entry {
    HANDLE handle;
    wchar_t *path;
};

struct cache_lock {
    struct cache_lock_entry *entries;
    size_t count;
    size_t capacity;
};

static int is_separator(wchar_t value)
{
    return value == L'\\' || value == L'/';
}

static int has_unc_root(const wchar_t *value)
{
    const wchar_t *cursor = value;

    if (*cursor == L'\0' || is_separator(*cursor)) {
        return 0;
    }
    while (*cursor != L'\0' && !is_separator(*cursor)) {
        cursor++;
    }
    if (!is_separator(*cursor)) {
        return 0;
    }
    while (is_separator(*cursor)) {
        cursor++;
    }
    if (*cursor == L'\0' || is_separator(*cursor)) {
        return 0;
    }
    return 1;
}

static int is_absolute_path(const wchar_t *value)
{
    size_t length;

    if (value == NULL) {
        return 0;
    }
    length = wcslen(value);
    if (length >= 3 &&
        ((value[0] >= L'A' && value[0] <= L'Z') ||
         (value[0] >= L'a' && value[0] <= L'z')) &&
        value[1] == L':' && is_separator(value[2])) {
        return 1;
    }
    if (length < 2 || !is_separator(value[0]) || !is_separator(value[1])) {
        return 0;
    }
    if (length >= 4 && (value[2] == L'?' || value[2] == L'.') &&
        is_separator(value[3])) {
        const wchar_t *extended = value + 4;
        size_t extended_length = length - 4;

        if (value[2] == L'.') {
            return 0;
        }
        if (extended_length >= 3 &&
            ((extended[0] >= L'A' && extended[0] <= L'Z') ||
             (extended[0] >= L'a' && extended[0] <= L'z')) &&
            extended[1] == L':' && is_separator(extended[2])) {
            return 1;
        }
        if (extended_length >= 4 &&
            CompareStringOrdinal(extended, 4, L"UNC\\", 4, TRUE) == CSTR_EQUAL) {
            return has_unc_root(extended + 4);
        }
        return 0;
    }
    return has_unc_root(value + 2);
}

static wchar_t *duplicate_wide_n(const wchar_t *value, size_t length)
{
    wchar_t *copy;

    if (length > ((size_t)-1 / sizeof(wchar_t)) - 1) {
        return NULL;
    }
    copy = (wchar_t *)malloc((length + 1) * sizeof(wchar_t));
    if (copy != NULL) {
        memcpy(copy, value, length * sizeof(wchar_t));
        copy[length] = L'\0';
    }
    return copy;
}

static wchar_t *duplicate_wide(const wchar_t *value)
{
    return duplicate_wide_n(value, wcslen(value));
}

static wchar_t *read_environment(const wchar_t *name, int *present)
{
    DWORD needed;
    DWORD length;
    DWORD error;
    wchar_t *value;

    *present = -1;
    SetLastError(ERROR_SUCCESS);
    needed = GetEnvironmentVariableW(name, NULL, 0);
    if (needed == 0) {
        error = GetLastError();
        if (error == ERROR_ENVVAR_NOT_FOUND) {
            *present = 0;
            return NULL;
        }
        if (error == ERROR_SUCCESS) {
            value = (wchar_t *)malloc(sizeof(wchar_t));
            if (value != NULL) {
                value[0] = L'\0';
                *present = 1;
            }
            return value;
        }
        return NULL;
    }

    value = (wchar_t *)malloc((size_t)needed * sizeof(wchar_t));
    if (value == NULL) {
        return NULL;
    }
    length = GetEnvironmentVariableW(name, value, needed);
    if (length == 0 || length >= needed) {
        free(value);
        return NULL;
    }
    *present = 1;
    return value;
}

static int test_sync_point(int testing, const wchar_t *expected)
{
    int point_present;
    int ready_present;
    int release_present;
    wchar_t *point = NULL;
    wchar_t *ready = NULL;
    wchar_t *release = NULL;
    HANDLE marker = INVALID_HANDLE_VALUE;
    unsigned int attempt;
    int ok = 0;

    if (!testing) {
        return 1;
    }
    point = read_environment(
        L"BRIEFING_BOOTSTRAP_TEST_SYNC_POINT", &point_present
    );
    if (point_present < 0) {
        goto cleanup;
    }
    if (!point_present || wcscmp(point, expected) != 0) {
        ok = 1;
        goto cleanup;
    }
    ready = read_environment(
        L"BRIEFING_BOOTSTRAP_TEST_SYNC_READY", &ready_present
    );
    release = read_environment(
        L"BRIEFING_BOOTSTRAP_TEST_SYNC_RELEASE", &release_present
    );
    if (ready_present < 0 || release_present < 0 ||
        !ready_present || !release_present ||
        !is_absolute_path(ready) || !is_absolute_path(release)) {
        goto cleanup;
    }
    marker = CreateFileW(
        ready,
        GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        NULL,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    );
    if (marker == INVALID_HANDLE_VALUE) {
        goto cleanup;
    }
    CloseHandle(marker);
    marker = INVALID_HANDLE_VALUE;
    for (attempt = 0; attempt < 3000; attempt++) {
        DWORD attributes = GetFileAttributesW(release);
        if (attributes != INVALID_FILE_ATTRIBUTES &&
            !(attributes & FILE_ATTRIBUTE_DIRECTORY)) {
            ok = 1;
            goto cleanup;
        }
        Sleep(10);
    }

cleanup:
    if (marker != INVALID_HANDLE_VALUE) {
        CloseHandle(marker);
    }
    free(release);
    free(ready);
    free(point);
    return ok;
}

static wchar_t *module_path(void)
{
    DWORD capacity = 260;

    while (capacity <= 32768) {
        DWORD length;
        wchar_t *value = (wchar_t *)malloc((size_t)capacity * sizeof(wchar_t));

        if (value == NULL) {
            return NULL;
        }
        SetLastError(ERROR_SUCCESS);
        length = GetModuleFileNameW(NULL, value, capacity);
        if (length == 0) {
            free(value);
            return NULL;
        }
        if (length < capacity) {
            value[length] = L'\0';
            return value;
        }
        free(value);
        if (capacity == 32768) {
            break;
        }
        capacity *= 2;
        if (capacity > 32768) {
            capacity = 32768;
        }
    }
    return NULL;
}

static wchar_t *final_path_by_handle(HANDLE handle)
{
    DWORD capacity = 260;

    while (capacity <= 32768) {
        DWORD length;
        wchar_t *path = (wchar_t *)malloc((size_t)capacity * sizeof(wchar_t));

        if (path == NULL) {
            return NULL;
        }
        length = GetFinalPathNameByHandleW(
            handle, path, capacity, FILE_NAME_NORMALIZED | VOLUME_NAME_DOS
        );
        if (length == 0) {
            free(path);
            return NULL;
        }
        if (length < capacity) {
            path[length] = L'\0';
            return path;
        }
        free(path);
        if (length >= 32768) {
            break;
        }
        capacity = length + 1;
    }
    return NULL;
}

static int same_path(const wchar_t *left, const wchar_t *right)
{
    size_t left_length = wcslen(left);
    size_t right_length = wcslen(right);

    if (left_length != right_length || left_length > (size_t)INT_MAX) {
        return 0;
    }
    return CompareStringOrdinal(
        left,
        (int)left_length,
        right,
        (int)right_length,
        TRUE
    ) == CSTR_EQUAL;
}

static const wchar_t *path_name(const wchar_t *path)
{
    const wchar_t *name = path + wcslen(path);

    while (name > path && !is_separator(name[-1])) {
        name--;
    }
    return name;
}

static int delete_open_file(HANDLE handle)
{
    FILE_DISPOSITION_INFO disposition;

    disposition.DeleteFile = TRUE;
    return SetFileInformationByHandle(
        handle, FileDispositionInfo, &disposition, sizeof(disposition)
    ) != 0;
}

/* SetFileInformationByHandle reads FileRenameInfo's FileName as a NUL-terminated Win32 path,
 * absolute or relative to the process's current directory - not to RootDirectory (see the
 * FILE_RENAME_INFO documentation; Wine's kernelbase converts it the same way with
 * RtlDosPathNameToNtPathName_U). The target is therefore a full path, and the caller checks
 * where the renamed handle ended up. */
static int rename_open_file(HANDLE file, const wchar_t *target, DWORD *error)
{
    size_t target_length = wcslen(target);
    size_t header = offsetof(FILE_RENAME_INFO, FileName);
    size_t bytes;
    FILE_RENAME_INFO *rename;
    int ok;

    *error = ERROR_INVALID_PARAMETER;
    if (target_length == 0 ||
        target_length >= (MAXDWORD - header) / sizeof(wchar_t)) {
        return 0;
    }
    bytes = header + (target_length + 1) * sizeof(wchar_t);
    if (bytes < sizeof(FILE_RENAME_INFO)) {
        bytes = sizeof(FILE_RENAME_INFO);
    }
    rename = (FILE_RENAME_INFO *)calloc(1, bytes);
    if (rename == NULL) {
        *error = ERROR_NOT_ENOUGH_MEMORY;
        return 0;
    }
    rename->ReplaceIfExists = FALSE;
    rename->RootDirectory = NULL;
    rename->FileNameLength = (DWORD)(target_length * sizeof(wchar_t));
    memcpy(rename->FileName, target, (target_length + 1) * sizeof(wchar_t));
    ok = SetFileInformationByHandle(
        file, FileRenameInfo, rename, (DWORD)bytes
    ) != 0;
    *error = ok ? ERROR_SUCCESS : GetLastError();
    free(rename);
    return ok;
}

static wchar_t *parent_directory(const wchar_t *path)
{
    wchar_t *directory = duplicate_wide(path);
    wchar_t *cursor;

    if (directory == NULL) {
        return NULL;
    }
    cursor = directory + wcslen(directory);
    while (cursor > directory && !is_separator(cursor[-1])) {
        cursor--;
    }
    if (cursor == directory) {
        free(directory);
        return NULL;
    }
    while (cursor > directory + 1 && is_separator(cursor[-1])) {
        cursor--;
    }
    *cursor = L'\0';
    return directory;
}

static wchar_t *full_path(const wchar_t *path)
{
    DWORD capacity = 260;

    while (capacity <= 32768) {
        DWORD length;
        wchar_t *value = (wchar_t *)malloc((size_t)capacity * sizeof(wchar_t));

        if (value == NULL) {
            return NULL;
        }
        length = GetFullPathNameW(path, capacity, value, NULL);
        if (length == 0) {
            free(value);
            return NULL;
        }
        if (length < capacity) {
            value[length] = L'\0';
            return value;
        }
        free(value);
        capacity = length + 1;
        if (capacity > 32768) {
            break;
        }
    }
    return NULL;
}

static void normalize_path(wchar_t *path)
{
    wchar_t *cursor;

    for (cursor = path; *cursor != L'\0'; cursor++) {
        if (*cursor == L'/') {
            *cursor = L'\\';
        }
    }
}

static size_t path_root_length(const wchar_t *path)
{
    size_t length = wcslen(path);
    const wchar_t *cursor;
    int components;

    if (length >= 3 && path[1] == L':' && is_separator(path[2])) {
        return 3;
    }
    if (length >= 7 && is_separator(path[0]) && is_separator(path[1]) &&
        path[2] == L'?' && is_separator(path[3]) && path[5] == L':' &&
        is_separator(path[6])) {
        return 7;
    }
    if (length >= 8 && is_separator(path[0]) && is_separator(path[1]) &&
        path[2] == L'?' && is_separator(path[3]) &&
        CompareStringOrdinal(path + 4, 4, L"UNC\\", 4, TRUE) == CSTR_EQUAL) {
        cursor = path + 8;
    } else if (length >= 2 && is_separator(path[0]) && is_separator(path[1])) {
        cursor = path + 2;
    } else {
        return 0;
    }

    components = 0;
    while (*cursor != L'\0') {
        while (is_separator(*cursor)) {
            cursor++;
        }
        if (*cursor == L'\0') {
            break;
        }
        components++;
        while (*cursor != L'\0' && !is_separator(*cursor)) {
            cursor++;
        }
        if (components == 2) {
            while (is_separator(*cursor)) {
                cursor++;
            }
            return (size_t)(cursor - path);
        }
    }
    return 0;
}

static void trim_trailing_separators(wchar_t *path)
{
    size_t root = path_root_length(path);
    size_t length = wcslen(path);

    while (length > root && is_separator(path[length - 1])) {
        path[--length] = L'\0';
    }
}

static wchar_t *join_path(const wchar_t *left, const wchar_t *right)
{
    size_t left_length = wcslen(left);
    size_t right_length = wcslen(right);
    int separator = left_length > 0 && !is_separator(left[left_length - 1]);
    wchar_t *joined;

    if (left_length > (size_t)-1 - right_length - (size_t)separator - 1) {
        return NULL;
    }
    joined = (wchar_t *)malloc(
        (left_length + (size_t)separator + right_length + 1) * sizeof(wchar_t)
    );
    if (joined == NULL) {
        return NULL;
    }
    memcpy(joined, left, left_length * sizeof(wchar_t));
    if (separator) {
        joined[left_length++] = L'\\';
    }
    memcpy(joined + left_length, right, (right_length + 1) * sizeof(wchar_t));
    return joined;
}

static wchar_t *append_suffix(const wchar_t *value, const wchar_t *suffix)
{
    size_t value_length = wcslen(value);
    size_t suffix_length = wcslen(suffix);
    wchar_t *result;

    if (value_length > (size_t)-1 - suffix_length - 1) {
        return NULL;
    }
    result = (wchar_t *)malloc(
        (value_length + suffix_length + 1) * sizeof(wchar_t)
    );
    if (result != NULL) {
        memcpy(result, value, value_length * sizeof(wchar_t));
        memcpy(
            result + value_length,
            suffix,
            (suffix_length + 1) * sizeof(wchar_t)
        );
    }
    return result;
}

static wchar_t *configuration_directory(void)
{
    int present;
    wchar_t *configured = read_environment(L"CLAUDE_CONFIG_DIR", &present);

    if (present < 0) {
        return NULL;
    }
    if (present && configured[0] != L'\0') {
        return configured;
    }
    free(configured);

    configured = read_environment(L"USERPROFILE", &present);
    if (present < 0 || !present || configured[0] == L'\0') {
        free(configured);
        return NULL;
    }
    {
        wchar_t *fallback = join_path(configured, L".claude");
        free(configured);
        return fallback;
    }
}

static int same_prefix(const wchar_t *value, const wchar_t *prefix)
{
    size_t prefix_length = wcslen(prefix);

    if (wcslen(value) < prefix_length || prefix_length > (size_t)INT_MAX) {
        return 0;
    }
    return CompareStringOrdinal(
        value, (int)prefix_length, prefix, (int)prefix_length, TRUE
    ) == CSTR_EQUAL;
}

/* The starter's version rule (bin/briefing platform_asset): the first character is
 * [A-Za-z0-9], every other one is [A-Za-z0-9._+-]. */
static int version_start_character(wchar_t value)
{
    return (value >= L'A' && value <= L'Z') ||
           (value >= L'a' && value <= L'z') ||
           (value >= L'0' && value <= L'9');
}

static int version_character(wchar_t value)
{
    return version_start_character(value) ||
           value == L'.' || value == L'_' || value == L'+' || value == L'-';
}

/* The gated fixture child must sit where the pinned binary would:
 * <config>\briefing\bin\<version>\<16 lower-case hex digits>\<file name>. */
static int child_is_in_versioned_cache(
    const wchar_t *config, const wchar_t *child
)
{
    wchar_t *cache = join_path(config, L"briefing\\bin\\");
    const wchar_t *version;
    const wchar_t *cursor;
    size_t index;
    int valid = 0;

    if (cache == NULL) {
        return 0;
    }
    if (!same_prefix(child, cache)) {
        free(cache);
        return 0;
    }

    version = child + wcslen(cache);
    if (!version_start_character(version[0])) {
        free(cache);
        return 0;
    }
    cursor = version;
    while (*cursor != L'\0' && *cursor != L'\\') {
        if (!version_character(*cursor)) {
            free(cache);
            return 0;
        }
        cursor++;
    }
    if (cursor == version || *cursor != L'\\' || cursor[1] == L'\0') {
        free(cache);
        return 0;
    }
    cursor++;
    for (index = 0; index < CACHE_PIN_LENGTH; index++) {
        if (!((cursor[index] >= L'0' && cursor[index] <= L'9') ||
              (cursor[index] >= L'a' && cursor[index] <= L'f'))) {
            free(cache);
            return 0;
        }
    }
    cursor += CACHE_PIN_LENGTH;
    if (*cursor != L'\\' || cursor[1] == L'\0') {
        free(cache);
        return 0;
    }
    cursor++;
    valid = wcschr(cursor, L'\\') == NULL;
    free(cache);
    return valid;
}

static int reserve_buffer(struct wide_buffer *buffer, size_t extra)
{
    size_t required;
    size_t capacity;
    wchar_t *grown;

    if (extra > (size_t)-1 - buffer->length - 1) {
        return 0;
    }
    required = buffer->length + extra + 1;
    if (required <= buffer->capacity) {
        return 1;
    }
    capacity = buffer->capacity == 0 ? 128 : buffer->capacity;
    while (capacity < required) {
        if (capacity > (size_t)-1 / 2) {
            capacity = required;
            break;
        }
        capacity *= 2;
    }
    if (capacity > (size_t)-1 / sizeof(wchar_t)) {
        return 0;
    }
    grown = (wchar_t *)realloc(buffer->data, capacity * sizeof(wchar_t));
    if (grown == NULL) {
        return 0;
    }
    buffer->data = grown;
    buffer->capacity = capacity;
    return 1;
}

static int append_character(struct wide_buffer *buffer, wchar_t value)
{
    if (!reserve_buffer(buffer, 1)) {
        return 0;
    }
    buffer->data[buffer->length++] = value;
    buffer->data[buffer->length] = L'\0';
    return 1;
}

static int append_text_n(
    struct wide_buffer *buffer, const wchar_t *value, size_t length
)
{
    if (!reserve_buffer(buffer, length)) {
        return 0;
    }
    memcpy(buffer->data + buffer->length, value, length * sizeof(wchar_t));
    buffer->length += length;
    buffer->data[buffer->length] = L'\0';
    return 1;
}

static int append_text(struct wide_buffer *buffer, const wchar_t *value)
{
    return append_text_n(buffer, value, wcslen(value));
}

static int append_repeated(
    struct wide_buffer *buffer, wchar_t value, size_t count
)
{
    if (!reserve_buffer(buffer, count)) {
        return 0;
    }
    while (count-- > 0) {
        buffer->data[buffer->length++] = value;
    }
    buffer->data[buffer->length] = L'\0';
    return 1;
}

/* Quote one argument according to the CommandLineToArgvW/MS C runtime rules. */
static int append_argument(struct wide_buffer *command, const wchar_t *argument)
{
    const wchar_t *cursor;
    int plain = argument[0] != L'\0';

    if (command->length > 0 && !append_character(command, L' ')) {
        return 0;
    }
    for (cursor = argument; *cursor != L'\0'; cursor++) {
        if (*cursor == L' ' || *cursor == L'\t' || *cursor == L'"') {
            plain = 0;
            break;
        }
    }
    if (plain) {
        return append_text(command, argument);
    }
    if (!append_character(command, L'"')) {
        return 0;
    }

    cursor = argument;
    for (;;) {
        size_t backslashes = 0;

        while (*cursor == L'\\') {
            backslashes++;
            cursor++;
        }
        if (*cursor == L'\0') {
            if (backslashes > (size_t)-1 / 2 ||
                !append_repeated(command, L'\\', backslashes * 2)) {
                return 0;
            }
            break;
        }
        if (*cursor == L'"') {
            if (backslashes > ((size_t)-1 - 1) / 2 ||
                !append_repeated(command, L'\\', backslashes * 2 + 1) ||
                !append_character(command, L'"')) {
                return 0;
            }
        } else {
            if (!append_repeated(command, L'\\', backslashes) ||
                !append_character(command, *cursor)) {
                return 0;
            }
        }
        cursor++;
    }
    return append_character(command, L'"');
}

static wchar_t *program_command_line(
    const wchar_t *program,
    size_t argument_count,
    const wchar_t *const *arguments
)
{
    struct wide_buffer command = {NULL, 0, 0};
    size_t index;

    if (!append_argument(&command, program)) {
        free(command.data);
        return NULL;
    }
    for (index = 0; index < argument_count; index++) {
        if (!append_argument(&command, arguments[index])) {
            free(command.data);
            return NULL;
        }
    }
    if (command.length >= 32767) {
        free(command.data);
        return NULL;
    }
    return command.data;
}

static int write_all_handle(HANDLE handle, const void *buffer, DWORD size)
{
    const unsigned char *cursor = (const unsigned char *)buffer;

    while (size > 0) {
        DWORD written = 0;
        if (!WriteFile(handle, cursor, size, &written, NULL) || written == 0) {
            return 0;
        }
        cursor += written;
        size -= written;
    }
    return 1;
}

static void write_error(const char *message)
{
    HANDLE error = GetStdHandle(STD_ERROR_HANDLE);

    if (error != NULL && error != INVALID_HANDLE_VALUE) {
        size_t length = strlen(message);
        if (length <= MAXDWORD) {
            (void)write_all_handle(error, message, (DWORD)length);
        }
    }
}

static int run_process(
    const wchar_t *program,
    size_t argument_count,
    const wchar_t *const *arguments,
    HANDLE input,
    HANDLE output,
    HANDLE error,
    DWORD *exit_code
)
{
    STARTUPINFOW startup;
    PROCESS_INFORMATION process;
    wchar_t *command = program_command_line(program, argument_count, arguments);
    int ok = 0;

    if (command == NULL) {
        return 0;
    }
    ZeroMemory(&startup, sizeof(startup));
    ZeroMemory(&process, sizeof(process));
    startup.cb = sizeof(startup);
    startup.dwFlags = STARTF_USESTDHANDLES;
    startup.hStdInput = input;
    startup.hStdOutput = output;
    startup.hStdError = error;

    if (!CreateProcessW(
            program,
            command,
            NULL,
            NULL,
            TRUE,
            0,
            NULL,
            NULL,
            &startup,
            &process)) {
        free(command);
        return 0;
    }
    free(command);
    CloseHandle(process.hThread);

    if (WaitForSingleObject(process.hProcess, INFINITE) == WAIT_OBJECT_0 &&
        GetExitCodeProcess(process.hProcess, exit_code)) {
        ok = 1;
    }
    CloseHandle(process.hProcess);
    return ok;
}

static int open_null_handles(HANDLE *input, HANDLE *output)
{
    SECURITY_ATTRIBUTES attributes;

    ZeroMemory(&attributes, sizeof(attributes));
    attributes.nLength = sizeof(attributes);
    attributes.bInheritHandle = TRUE;
    *input = CreateFileW(
        L"NUL",
        GENERIC_READ,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        &attributes,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    );
    if (*input == INVALID_HANDLE_VALUE) {
        return 0;
    }
    *output = CreateFileW(
        L"NUL",
        GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        &attributes,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    );
    if (*output == INVALID_HANDLE_VALUE) {
        CloseHandle(*input);
        *input = INVALID_HANDLE_VALUE;
        return 0;
    }
    return 1;
}

static int run_process_quiet(
    const wchar_t *program,
    size_t argument_count,
    const wchar_t *const *arguments,
    DWORD *exit_code
)
{
    HANDLE input = INVALID_HANDLE_VALUE;
    HANDLE output = INVALID_HANDLE_VALUE;
    int ok;

    if (!open_null_handles(&input, &output)) {
        return 0;
    }
    ok = run_process(
        program, argument_count, arguments, input, output, output, exit_code
    );
    CloseHandle(output);
    CloseHandle(input);
    return ok;
}

static int run_with_par(
    const wchar_t *program,
    const wchar_t *par_directory,
    size_t argument_count,
    const wchar_t *const *arguments,
    int quiet,
    DWORD *exit_code
)
{
    int original_present;
    wchar_t *original = read_environment(L"PAR_GLOBAL_TEMP", &original_present);
    DWORD error = ERROR_SUCCESS;
    int ran = 0;

    if (original_present < 0) {
        return 0;
    }
    if (!SetEnvironmentVariableW(L"PAR_GLOBAL_TEMP", par_directory)) {
        error = GetLastError();
        free(original);
        SetLastError(error);
        return 0;
    }

    if (quiet) {
        ran = run_process_quiet(program, argument_count, arguments, exit_code);
    } else {
        ran = run_process(
            program,
            argument_count,
            arguments,
            GetStdHandle(STD_INPUT_HANDLE),
            GetStdHandle(STD_OUTPUT_HANDLE),
            GetStdHandle(STD_ERROR_HANDLE),
            exit_code
        );
    }
    if (!ran) {
        error = GetLastError();
    }

    if (original_present) {
        (void)SetEnvironmentVariableW(L"PAR_GLOBAL_TEMP", original);
    } else {
        (void)SetEnvironmentVariableW(L"PAR_GLOBAL_TEMP", NULL);
    }
    free(original);
    if (!ran) {
        SetLastError(error);
    }
    return ran;
}

static int token_owner_matches(
    const struct private_security *security, PSID expected
)
{
    DWORD needed = 0;
    TOKEN_OWNER *owner = NULL;
    int matches = 0;

    (void)GetTokenInformation(
        security->token, TokenOwner, NULL, 0, &needed
    );
    if (needed == 0) {
        return 0;
    }
    owner = (TOKEN_OWNER *)malloc(needed);
    if (owner != NULL &&
        GetTokenInformation(
            security->token, TokenOwner, owner, needed, &needed
        ) &&
        owner->Owner != NULL && EqualSid(owner->Owner, expected)) {
        matches = 1;
    }
    free(owner);
    return matches;
}

static int set_token_owner(
    struct private_security *security, PSID owner, int token_user_active
)
{
    TOKEN_OWNER requested;

    requested.Owner = owner;
    if (!SetTokenInformation(
            security->token, TokenOwner, &requested, sizeof(requested)
        ) ||
        !token_owner_matches(security, owner)) {
        return 0;
    }
    security->token_user_owner_active = token_user_active;
    return 1;
}

static int activate_token_user_owner(struct private_security *security)
{
    if (security->token_user_owner_active) {
        return 1;
    }
    return set_token_owner(security, security->sid, 1);
}

static int restore_token_owner(struct private_security *security)
{
    if (!security->token_user_owner_active) {
        return token_owner_matches(security, security->original_owner);
    }
    return set_token_owner(security, security->original_owner, 0);
}

static int initialize_private_security(struct private_security *security)
{
    DWORD needed = 0;
    TOKEN_USER *user = NULL;
    TOKEN_OWNER *owner = NULL;
    DWORD owner_needed = 0;
    DWORD sid_length;
    DWORD owner_length;
    DWORD acl_length;
    int ok = 0;

    ZeroMemory(security, sizeof(*security));
    if (!OpenProcessToken(
            GetCurrentProcess(),
            TOKEN_QUERY | TOKEN_ADJUST_DEFAULT,
            &security->token
        )) {
        goto cleanup;
    }
    (void)GetTokenInformation(
        security->token, TokenUser, NULL, 0, &needed
    );
    if (needed == 0) {
        goto cleanup;
    }
    user = (TOKEN_USER *)malloc(needed);
    if (user == NULL ||
        !GetTokenInformation(
            security->token, TokenUser, user, needed, &needed
        ) ||
        !IsValidSid(user->User.Sid)) {
        goto cleanup;
    }
    sid_length = GetLengthSid(user->User.Sid);
    security->sid = malloc(sid_length);
    if (security->sid == NULL ||
        !CopySid(sid_length, security->sid, user->User.Sid)) {
        goto cleanup;
    }

    (void)GetTokenInformation(
        security->token, TokenOwner, NULL, 0, &owner_needed
    );
    if (owner_needed == 0) {
        goto cleanup;
    }
    owner = (TOKEN_OWNER *)malloc(owner_needed);
    if (owner == NULL ||
        !GetTokenInformation(
            security->token,
            TokenOwner,
            owner,
            owner_needed,
            &owner_needed
        ) ||
        owner->Owner == NULL || !IsValidSid(owner->Owner)) {
        goto cleanup;
    }
    owner_length = GetLengthSid(owner->Owner);
    security->original_owner = malloc(owner_length);
    if (security->original_owner == NULL ||
        !CopySid(owner_length, security->original_owner, owner->Owner) ||
        !token_owner_matches(security, security->original_owner)) {
        goto cleanup;
    }

    if (sid_length > MAXDWORD - (DWORD)sizeof(ACL) -
            (DWORD)sizeof(ACCESS_ALLOWED_ACE) + (DWORD)sizeof(DWORD)) {
        goto cleanup;
    }
    acl_length = (DWORD)sizeof(ACL) + (DWORD)sizeof(ACCESS_ALLOWED_ACE) -
                 (DWORD)sizeof(DWORD) + sid_length;
    security->acl = (PACL)malloc(acl_length);
    security->inheritable_acl = (PACL)malloc(acl_length);
    if (security->acl == NULL || security->inheritable_acl == NULL ||
        !InitializeAcl(security->acl, acl_length, ACL_REVISION) ||
        !AddAccessAllowedAceEx(
            security->acl,
            ACL_REVISION,
            0,
            FILE_ALL_ACCESS,
            security->sid
        ) ||
        !InitializeAcl(security->inheritable_acl, acl_length, ACL_REVISION) ||
        !AddAccessAllowedAceEx(
            security->inheritable_acl,
            ACL_REVISION,
            OBJECT_INHERIT_ACE | CONTAINER_INHERIT_ACE,
            FILE_ALL_ACCESS,
            security->sid
        ) ||
        !InitializeSecurityDescriptor(
            &security->descriptor, SECURITY_DESCRIPTOR_REVISION
        ) ||
        !SetSecurityDescriptorOwner(
            &security->descriptor, security->sid, FALSE
        ) ||
        !SetSecurityDescriptorDacl(
            &security->descriptor, TRUE, security->acl, FALSE
        ) ||
        !SetSecurityDescriptorControl(
            &security->descriptor, SE_DACL_PROTECTED, SE_DACL_PROTECTED
        ) ||
        !InitializeSecurityDescriptor(
            &security->inheritable_descriptor, SECURITY_DESCRIPTOR_REVISION
        ) ||
        !SetSecurityDescriptorOwner(
            &security->inheritable_descriptor, security->sid, FALSE
        ) ||
        !SetSecurityDescriptorDacl(
            &security->inheritable_descriptor,
            TRUE,
            security->inheritable_acl,
            FALSE
        ) ||
        !SetSecurityDescriptorControl(
            &security->inheritable_descriptor,
            SE_DACL_PROTECTED,
            SE_DACL_PROTECTED
        )) {
        goto cleanup;
    }

    security->attributes.nLength = sizeof(security->attributes);
    security->attributes.lpSecurityDescriptor = &security->descriptor;
    security->attributes.bInheritHandle = FALSE;
    security->inheritable_attributes.nLength =
        sizeof(security->inheritable_attributes);
    security->inheritable_attributes.lpSecurityDescriptor =
        &security->inheritable_descriptor;
    security->inheritable_attributes.bInheritHandle = FALSE;
    ok = 1;

cleanup:
    free(owner);
    free(user);
    if (!ok) {
        if (security->token != NULL) {
            CloseHandle(security->token);
        }
        free(security->inheritable_acl);
        free(security->acl);
        free(security->original_owner);
        free(security->sid);
        ZeroMemory(security, sizeof(*security));
    }
    return ok;
}

static void destroy_private_security(struct private_security *security)
{
    if (security->token != NULL) {
        (void)restore_token_owner(security);
        CloseHandle(security->token);
    }
    free(security->inheritable_acl);
    free(security->acl);
    free(security->original_owner);
    free(security->sid);
    ZeroMemory(security, sizeof(*security));
}

/* A refused object leaves a Windows error saying why: the query's own error, a reparse
 * point, or the wrong object type. */
static int handle_information(
    HANDLE handle, DWORD expected_directory, DWORD *attributes
)
{
    BY_HANDLE_FILE_INFORMATION information;

    if (!GetFileInformationByHandle(handle, &information)) {
        return 0;
    }
    if (information.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) {
        SetLastError(ERROR_REPARSE_POINT_ENCOUNTERED);
        return 0;
    }
    if (!!(information.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) !=
        !!expected_directory) {
        SetLastError(expected_directory ? ERROR_DIRECTORY : ERROR_DIRECTORY_NOT_SUPPORTED);
        return 0;
    }
    *attributes = information.dwFileAttributes;
    return 1;
}

static int handle_owner_is_current_user(
    HANDLE handle, const struct private_security *security
)
{
    PSID owner = NULL;
    PSECURITY_DESCRIPTOR descriptor = NULL;
    DWORD status = GetSecurityInfo(
        handle,
        SE_FILE_OBJECT,
        OWNER_SECURITY_INFORMATION,
        &owner,
        NULL,
        NULL,
        NULL,
        &descriptor
    );
    int matches = status == ERROR_SUCCESS && owner != NULL &&
                  EqualSid(owner, security->sid);

    if (descriptor != NULL) {
        LocalFree(descriptor);
    }
    return matches;
}

/* On failure the last error is SetSecurityInfo's status, or ERROR_INVALID_OWNER when the
 * owner did not become the current user. */
static int protect_handle(
    HANDLE handle,
    const struct private_security *security,
    int inheritable
)
{
    PACL acl = inheritable ? security->inheritable_acl : security->acl;
    DWORD status = SetSecurityInfo(
        handle,
        SE_FILE_OBJECT,
        OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION |
            PROTECTED_DACL_SECURITY_INFORMATION,
        security->sid,
        NULL,
        acl,
        NULL
    );

    if (status != ERROR_SUCCESS) {
        SetLastError(status);
        return 0;
    }
    if (!handle_owner_is_current_user(handle, security)) {
        SetLastError(ERROR_INVALID_OWNER);
        return 0;
    }
    return 1;
}

static HANDLE open_object(
    const wchar_t *path,
    DWORD access,
    DWORD sharing,
    DWORD expected_directory
)
{
    HANDLE handle = CreateFileW(
        path,
        access,
        sharing,
        NULL,
        OPEN_EXISTING,
        FILE_FLAG_OPEN_REPARSE_POINT |
            (expected_directory ? FILE_FLAG_BACKUP_SEMANTICS : 0),
        NULL
    );
    DWORD attributes;

    if (handle == INVALID_HANDLE_VALUE) {
        return INVALID_HANDLE_VALUE;
    }
    if (!handle_information(handle, expected_directory, &attributes)) {
        DWORD error = GetLastError();

        CloseHandle(handle);
        SetLastError(error);
        return INVALID_HANDLE_VALUE;
    }
    return handle;
}

static int path_information(
    const wchar_t *path, DWORD expected_directory, DWORD *attributes
)
{
    HANDLE handle = open_object(
        path,
        FILE_READ_ATTRIBUTES,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        expected_directory
    );
    int ok;

    if (handle == INVALID_HANDLE_VALUE) {
        return 0;
    }
    ok = handle_information(handle, expected_directory, attributes);
    CloseHandle(handle);
    return ok;
}

static int protect_object(
    const wchar_t *path,
    DWORD expected_directory,
    const struct private_security *security,
    int inheritable
)
{
    HANDLE handle = open_object(
        path,
        FILE_READ_ATTRIBUTES | READ_CONTROL | WRITE_DAC | WRITE_OWNER,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        expected_directory
    );
    DWORD error;
    int ok;

    if (handle == INVALID_HANDLE_VALUE) {
        return 0;
    }
    ok = protect_handle(handle, security, inheritable);
    error = GetLastError();
    CloseHandle(handle);
    if (!ok) {
        SetLastError(error);
    }
    return ok;
}

static int path_components_safe(const wchar_t *path, int allow_missing_final);

static int handles_same_object(HANDLE left, HANDLE right)
{
    BY_HANDLE_FILE_INFORMATION left_information;
    BY_HANDLE_FILE_INFORMATION right_information;

    return GetFileInformationByHandle(left, &left_information) &&
           GetFileInformationByHandle(right, &right_information) &&
           left_information.dwVolumeSerialNumber ==
               right_information.dwVolumeSerialNumber &&
           left_information.nFileIndexHigh == right_information.nFileIndexHigh &&
           left_information.nFileIndexLow == right_information.nFileIndexLow;
}

static int handles_name_same_object(
    const wchar_t *path, HANDLE expected, DWORD expected_directory
)
{
    HANDLE current = open_object(
        path,
        FILE_READ_ATTRIBUTES,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        expected_directory
    );
    int same;

    if (current == INVALID_HANDLE_VALUE) {
        return 0;
    }
    same = handles_same_object(expected, current);
    CloseHandle(current);
    return same;
}

static int names_same_object(
    const wchar_t *left, const wchar_t *right, DWORD expected_directory
)
{
    HANDLE handle = open_object(
        left,
        FILE_READ_ATTRIBUTES,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        expected_directory
    );
    int same;

    if (handle == INVALID_HANDLE_VALUE) {
        return 0;
    }
    same = handles_name_same_object(right, handle, expected_directory);
    CloseHandle(handle);
    return same;
}

/* The single failure reason of this run that is formatted; why_binary may point here.
 * Callers pass fixed text only, so the reason never needs JSON escaping. */
static char formatted_reason[320];

static const char *reason_text(const char *format, ...)
{
    va_list arguments;
    int length;

    va_start(arguments, format);
    length = vsnprintf(formatted_reason, sizeof(formatted_reason), format, arguments);
    va_end(arguments);
    return length < 0 ? "the failure reason cannot be formatted" : formatted_reason;
}

/* PAR::Packer's Windows loader (myldr in PAR-Packer 1.064) works with narrow ANSI strings: it
 * finds itself with GetModuleFileNameA, reads PAR_GLOBAL_TEMP from the ANSI environment, joins
 * paths with '/', and its manifest declares neither longPathAware nor a UTF-8 code page. A path
 * handed to it must carry no \\?\ prefix (which turns off the '/' translation), be exact in the
 * ANSI code page and stay below MAX_PATH including what PAR writes beneath PAR_GLOBAL_TEMP. The
 * long form is used when it qualifies, else its 8.3 alias; callers check that the chosen name
 * opens the verified object. */

/* The deepest relative path PAR extracts below PAR_GLOBAL_TEMP: 45 characters in the 0.001
 * probe's inc/ tree, 82 in a local Linux build that pulled in Moose's exception classes. The
 * reserve covers such a tree with margin. With C:\Users\<20 characters>\.claude as the
 * configuration and version 0.001, the PAR directory ...\bin\0.001\<pin>\par is 77 characters,
 * so its long form qualifies up to a reserve of 182; with 128 it qualifies while the
 * configuration directory has at most 96 characters minus the version's length. */
#define PAR_TREE_RESERVE 128
/* PAR extracts its interpreter as <PAR_GLOBAL_TEMP>\<program name>, first as "<that>.<pid>":
 * a separator, a dot and up to 20 digits beyond the name. */
#define PAR_INTERPRETER_SUFFIX 22

static wchar_t *without_extended_prefix(const wchar_t *path)
{
    size_t length = wcslen(path);
    wchar_t *plain;

    if (length < 4 || !is_separator(path[0]) || !is_separator(path[1]) ||
        path[2] != L'?' || !is_separator(path[3])) {
        return duplicate_wide(path);
    }
    if (length >= 9 &&
        CompareStringOrdinal(path + 4, 4, L"UNC\\", 4, TRUE) == CSTR_EQUAL) {
        plain = duplicate_wide(path + 6);
        if (plain != NULL) {
            plain[0] = L'\\';
        }
        return plain;
    }
    if (length >= 7 &&
        ((path[4] >= L'A' && path[4] <= L'Z') ||
         (path[4] >= L'a' && path[4] <= L'z')) &&
        path[5] == L':' && is_separator(path[6])) {
        return duplicate_wide(path + 4);
    }
    return NULL;
}

/* Converts to the ANSI code page without best-fit or default characters and back. */
static int ansi_exact(const wchar_t *path)
{
    UINT code_page = GetACP();
    DWORD flags = code_page == CP_UTF8 ? 0 : WC_NO_BEST_FIT_CHARS;
    BOOL defaulted = FALSE;
    BOOL *defaulted_pointer = code_page == CP_UTF8 ? NULL : &defaulted;
    char *narrow = NULL;
    wchar_t *wide = NULL;
    int bytes;
    int length;
    int exact = 0;

    bytes = WideCharToMultiByte(
        code_page, flags, path, -1, NULL, 0, NULL, defaulted_pointer
    );
    if (bytes <= 0 || defaulted) {
        return 0;
    }
    narrow = (char *)malloc((size_t)bytes);
    if (narrow == NULL ||
        WideCharToMultiByte(
            code_page, flags, path, -1, narrow, bytes, NULL, defaulted_pointer
        ) != bytes ||
        defaulted) {
        goto cleanup;
    }
    length = MultiByteToWideChar(
        code_page, MB_ERR_INVALID_CHARS, narrow, -1, NULL, 0
    );
    if (length <= 0) {
        goto cleanup;
    }
    wide = (wchar_t *)malloc((size_t)length * sizeof(wchar_t));
    if (wide != NULL &&
        MultiByteToWideChar(
            code_page, MB_ERR_INVALID_CHARS, narrow, -1, wide, length
        ) == length &&
        wcscmp(wide, path) == 0) {
        exact = 1;
    }

cleanup:
    free(wide);
    free(narrow);
    return exact;
}

static int par_loader_accepts(const wchar_t *path, size_t reserve, int *too_long)
{
    size_t length = wcslen(path);

    *too_long = length >= MAX_PATH || reserve >= MAX_PATH - length;
    return !*too_long && ansi_exact(path);
}

static size_t par_directory_reserve(const wchar_t *program)
{
    size_t interpreter = wcslen(path_name(program)) + PAR_INTERPRETER_SUFFIX;

    return interpreter > PAR_TREE_RESERVE ? interpreter : PAR_TREE_RESERVE;
}

/* The name of path to hand to the PAR loader, or NULL with *why saying which rule failed. */
static wchar_t *par_loader_path(
    const wchar_t *path, size_t reserve, const char *label, const char **why
)
{
    wchar_t *candidate = without_extended_prefix(path);
    wchar_t *alias = NULL;
    DWORD capacity;
    DWORD length;
    int too_long = 0;
    int alias_too_long = 0;

    if (candidate == NULL) {
        *why = reason_text("%s has no drive-letter or UNC form for the PAR loader", label);
        return NULL;
    }
    if (par_loader_accepts(candidate, reserve, &too_long)) {
        return candidate;
    }
    free(candidate);
    candidate = NULL;

    capacity = GetShortPathNameW(path, NULL, 0);
    if (capacity != 0 && capacity <= 32768) {
        alias = (wchar_t *)malloc((size_t)capacity * sizeof(wchar_t));
        if (alias != NULL) {
            length = GetShortPathNameW(path, alias, capacity);
            if (length != 0 && length < capacity) {
                candidate = without_extended_prefix(alias);
            }
            free(alias);
        }
    }
    if (candidate != NULL &&
        par_loader_accepts(candidate, reserve, &alias_too_long)) {
        return candidate;
    }
    free(candidate);
    *why = reason_text(
        "%s is %s for the PAR loader and has no usable 8.3 alias",
        label,
        too_long ? "too long" : "not exact in the ANSI code page"
    );
    return NULL;
}

static int path_components_safe(const wchar_t *path, int allow_missing_final)
{
    size_t root = path_root_length(path);
    size_t length = wcslen(path);
    wchar_t *prefix;
    size_t cursor;
    DWORD attributes;

    if (root == 0 || root > length) {
        return 0;
    }
    prefix = duplicate_wide(path);
    if (prefix == NULL) {
        return 0;
    }

    cursor = root;
    while (cursor < length) {
        size_t end;
        int final;

        while (cursor < length && is_separator(prefix[cursor])) {
            cursor++;
        }
        if (cursor == length) {
            break;
        }
        end = cursor;
        while (end < length && !is_separator(prefix[end])) {
            end++;
        }
        if ((end - cursor == 1 && prefix[cursor] == L'.') ||
            (end - cursor == 2 && prefix[cursor] == L'.' &&
             prefix[cursor + 1] == L'.')) {
            free(prefix);
            return 0;
        }
        final = end == length;
        {
            wchar_t saved = prefix[end];
            prefix[end] = L'\0';
            attributes = GetFileAttributesW(prefix);
            prefix[end] = saved;
        }
        if (attributes == INVALID_FILE_ATTRIBUTES) {
            DWORD error = GetLastError();
            free(prefix);
            return final && allow_missing_final &&
                   (error == ERROR_FILE_NOT_FOUND || error == ERROR_PATH_NOT_FOUND);
        }
        if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) ||
            (!final && !(attributes & FILE_ATTRIBUTE_DIRECTORY))) {
            free(prefix);
            return 0;
        }
        cursor = end;
    }
    free(prefix);
    return 1;
}

static void initialize_cache_lock(struct cache_lock *lock)
{
    ZeroMemory(lock, sizeof(*lock));
}

static void release_cache_lock(struct cache_lock *lock)
{
    while (lock->count > 0) {
        struct cache_lock_entry *entry = &lock->entries[lock->count - 1];

        if (entry->handle != INVALID_HANDLE_VALUE) {
            CloseHandle(entry->handle);
        }
        free(entry->path);
        lock->count--;
    }
    free(lock->entries);
    lock->entries = NULL;
    lock->capacity = 0;
}

static int cache_lock_valid(const struct cache_lock *lock)
{
    size_t index;

    if (lock->count == 0) {
        return 0;
    }
    for (index = 0; index < lock->count; index++) {
        const struct cache_lock_entry *entry = &lock->entries[index];
        DWORD attributes;

        if (entry->handle == INVALID_HANDLE_VALUE || entry->path == NULL ||
            !handle_information(entry->handle, 1, &attributes) ||
            !handles_name_same_object(entry->path, entry->handle, 1)) {
            return 0;
        }
    }
    return 1;
}

static int append_cache_lock(
    struct cache_lock *lock, const wchar_t *path, DWORD additional_access
)
{
    struct cache_lock_entry *grown;
    struct cache_lock_entry entry;
    size_t capacity;

    entry.handle = INVALID_HANDLE_VALUE;
    entry.path = duplicate_wide(path);
    if (entry.path == NULL) {
        return 0;
    }
    entry.handle = open_object(
        entry.path,
        FILE_READ_ATTRIBUTES | FILE_TRAVERSE | additional_access,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        1
    );
    if (entry.handle == INVALID_HANDLE_VALUE) {
        free(entry.path);
        return 0;
    }

    if (lock->count == lock->capacity) {
        capacity = lock->capacity == 0 ? 16 : lock->capacity * 2;
        if (capacity < lock->capacity ||
            capacity > (size_t)-1 / sizeof(*lock->entries)) {
            CloseHandle(entry.handle);
            free(entry.path);
            return 0;
        }
        grown = (struct cache_lock_entry *)realloc(
            lock->entries, capacity * sizeof(*lock->entries)
        );
        if (grown == NULL) {
            CloseHandle(entry.handle);
            free(entry.path);
            return 0;
        }
        lock->entries = grown;
        lock->capacity = capacity;
    }
    lock->entries[lock->count++] = entry;
    return 1;
}

/* The innermost locked directory; once ensure_private_cache has returned, the pin directory. */
static HANDLE cache_entry_directory_handle(const struct cache_lock *lock)
{
    if (lock->count == 0) {
        return INVALID_HANDLE_VALUE;
    }
    return lock->entries[lock->count - 1].handle;
}

static int ensure_configuration_chain(
    const wchar_t *config,
    const struct private_security *security,
    struct cache_lock *lock
)
{
    size_t root = path_root_length(config);
    size_t length = wcslen(config);
    size_t cursor;
    wchar_t *component = NULL;
    int ok = 0;

    if (root == 0 || root > length) {
        return 0;
    }
    component = duplicate_wide_n(config, root);
    if (component == NULL || !append_cache_lock(lock, component, 0)) {
        goto cleanup;
    }
    free(component);
    component = NULL;

    cursor = root;
    while (cursor < length) {
        size_t end;
        DWORD attributes;

        while (cursor < length && is_separator(config[cursor])) {
            cursor++;
        }
        if (cursor == length) {
            break;
        }
        end = cursor;
        while (end < length && !is_separator(config[end])) {
            end++;
        }
        if ((end - cursor == 1 && config[cursor] == L'.') ||
            (end - cursor == 2 && config[cursor] == L'.' &&
             config[cursor + 1] == L'.')) {
            goto cleanup;
        }
        component = duplicate_wide_n(config, end);
        if (component == NULL) {
            goto cleanup;
        }
        attributes = GetFileAttributesW(component);
        if (attributes == INVALID_FILE_ATTRIBUTES) {
            DWORD error = GetLastError();

            if ((error != ERROR_FILE_NOT_FOUND && error != ERROR_PATH_NOT_FOUND) ||
                (!CreateDirectoryW(
                     component,
                     (LPSECURITY_ATTRIBUTES)&security->attributes
                 ) &&
                 GetLastError() != ERROR_ALREADY_EXISTS)) {
                goto cleanup;
            }
        }
        if (!append_cache_lock(lock, component, 0)) {
            goto cleanup;
        }
        free(component);
        component = NULL;
        cursor = end;
    }
    ok = 1;

cleanup:
    free(component);
    return ok;
}

/* On failure the last error is the failing call's: lookup, creation, open or protection. */
static int ensure_private_directory(
    const wchar_t *path,
    const struct private_security *security,
    int inheritable
)
{
    DWORD attributes = GetFileAttributesW(path);
    LPSECURITY_ATTRIBUTES create_security = inheritable
        ? (LPSECURITY_ATTRIBUTES)&security->inheritable_attributes
        : (LPSECURITY_ATTRIBUTES)&security->attributes;

    if (attributes == INVALID_FILE_ATTRIBUTES) {
        DWORD error = GetLastError();
        if (error != ERROR_FILE_NOT_FOUND && error != ERROR_PATH_NOT_FOUND) {
            return 0;
        }
        if (!CreateDirectoryW(path, create_security) &&
            GetLastError() != ERROR_ALREADY_EXISTS) {
            return 0;
        }
    }
    return protect_object(path, 1, security, inheritable);
}

/* Returns the pin directory <config>\briefing\bin\<version>\<pin>, with every directory of the
 * chain locked. The chain down to the version directory is created with plain paths; the pin
 * directory is named from the extended final path of the locked version directory, as the
 * entries inside it are, so it adds nothing to the plain-path limit. */
static wchar_t *ensure_private_cache(
    const wchar_t *config,
    const wchar_t *version_name,
    const wchar_t *pin_name,
    const struct private_security *security,
    struct cache_lock *lock
)
{
    wchar_t *briefing = NULL;
    wchar_t *bin = NULL;
    wchar_t *version = NULL;
    wchar_t *bound_version = NULL;
    wchar_t *pin = NULL;

    if (!ensure_configuration_chain(config, security, lock)) {
        goto fail;
    }
    briefing = join_path(config, L"briefing");
    if (briefing == NULL ||
        !ensure_private_directory(briefing, security, 0) ||
        !append_cache_lock(lock, briefing, 0)) {
        goto fail;
    }
    bin = join_path(briefing, L"bin");
    if (bin == NULL || !ensure_private_directory(bin, security, 0) ||
        !append_cache_lock(lock, bin, 0)) {
        goto fail;
    }
    version = join_path(bin, version_name);
    if (version == NULL || !ensure_private_directory(version, security, 0) ||
        !append_cache_lock(lock, version, 0)) {
        goto fail;
    }
    bound_version = final_path_by_handle(cache_entry_directory_handle(lock));
    if (bound_version == NULL || !path_components_safe(bound_version, 0)) {
        goto fail;
    }
    pin = join_path(bound_version, pin_name);
    if (pin == NULL || !ensure_private_directory(pin, security, 0) ||
        !append_cache_lock(lock, pin, FILE_ADD_FILE)) {
        goto fail;
    }
    if (!cache_lock_valid(lock)) {
        goto fail;
    }

    free(bound_version);
    free(version);
    free(bin);
    free(briefing);
    return pin;

fail:
    release_cache_lock(lock);
    free(pin);
    free(bound_version);
    free(version);
    free(bin);
    free(briefing);
    return NULL;
}

static HANDLE open_regular_file(const wchar_t *path, DWORD access, DWORD sharing)
{
    HANDLE handle = CreateFileW(
        path,
        access,
        sharing,
        NULL,
        OPEN_EXISTING,
        FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_SEQUENTIAL_SCAN,
        NULL
    );
    DWORD attributes;

    if (handle == INVALID_HANDLE_VALUE) {
        return INVALID_HANDLE_VALUE;
    }
    if (!handle_information(handle, 0, &attributes)) {
        DWORD error = GetLastError();

        CloseHandle(handle);
        SetLastError(error);
        return INVALID_HANDLE_VALUE;
    }
    return handle;
}

static int hash_handle(
    HANDLE file, ULONGLONG maximum_bytes, unsigned char output[HASH_BYTES]
)
{
    BCRYPT_ALG_HANDLE algorithm = NULL;
    BCRYPT_HASH_HANDLE hash = NULL;
    DWORD object_length = 0;
    DWORD hash_length = 0;
    DWORD returned = 0;
    unsigned char *object = NULL;
    unsigned char buffer[65536];
    LARGE_INTEGER zero;
    LARGE_INTEGER size;
    NTSTATUS status;
    int ok = 0;

    if (!GetFileSizeEx(file, &size) || size.QuadPart < 0 ||
        (ULONGLONG)size.QuadPart > maximum_bytes) {
        goto cleanup;
    }
    zero.QuadPart = 0;
    if (!SetFilePointerEx(file, zero, NULL, FILE_BEGIN)) {
        goto cleanup;
    }
    status = BCryptOpenAlgorithmProvider(
        &algorithm, BCRYPT_SHA256_ALGORITHM, NULL, 0
    );
    if (status < 0) {
        goto cleanup;
    }
    status = BCryptGetProperty(
        algorithm,
        BCRYPT_OBJECT_LENGTH,
        (PUCHAR)&object_length,
        sizeof(object_length),
        &returned,
        0
    );
    if (status < 0 || returned != sizeof(object_length) || object_length == 0) {
        goto cleanup;
    }
    status = BCryptGetProperty(
        algorithm,
        BCRYPT_HASH_LENGTH,
        (PUCHAR)&hash_length,
        sizeof(hash_length),
        &returned,
        0
    );
    if (status < 0 || returned != sizeof(hash_length) ||
        hash_length != HASH_BYTES) {
        goto cleanup;
    }
    object = (unsigned char *)malloc(object_length);
    if (object == NULL) {
        goto cleanup;
    }
    status = BCryptCreateHash(
        algorithm, &hash, object, object_length, NULL, 0, 0
    );
    if (status < 0) {
        goto cleanup;
    }

    for (;;) {
        DWORD length = 0;
        if (!ReadFile(file, buffer, sizeof(buffer), &length, NULL)) {
            goto cleanup;
        }
        if (length == 0) {
            break;
        }
        status = BCryptHashData(hash, buffer, length, 0);
        if (status < 0) {
            goto cleanup;
        }
    }
    status = BCryptFinishHash(hash, output, HASH_BYTES, 0);
    if (status < 0) {
        goto cleanup;
    }
    ok = 1;

cleanup:
    if (hash != NULL) {
        (void)BCryptDestroyHash(hash);
    }
    if (algorithm != NULL) {
        (void)BCryptCloseAlgorithmProvider(algorithm, 0);
    }
    free(object);
    return ok;
}

static int hex_digit(unsigned char value)
{
    if (value >= (unsigned char)'0' && value <= (unsigned char)'9') {
        return value - (unsigned char)'0';
    }
    if (value >= (unsigned char)'a' && value <= (unsigned char)'f') {
        return value - (unsigned char)'a' + 10;
    }
    return -1;
}

static int valid_version_bytes(const unsigned char *version, size_t length)
{
    size_t index;

    if (length == 0 || length > VERSION_MAX_LENGTH ||
        !version_start_character((wchar_t)version[0])) {
        return 0;
    }
    for (index = 1; index < length; index++) {
        if (!version_character((wchar_t)version[index])) {
            return 0;
        }
    }
    return 1;
}

/* The manifest is exactly five lines "<sha256>  briefing-<version><suffix>\n" in this
 * platform order, all naming one version that follows the starter's rule, as read_pins
 * in bin/briefing reads it. Anything else makes it malformed. */
static int parse_manifest_bytes(
    const unsigned char *bytes, size_t length, struct pin_manifest *pins
)
{
    static const char *const suffixes[5] = {
        "-linux-x86_64",
        "-linux-arm64",
        "-macos-x86_64",
        "-macos-arm64",
        WINDOWS_ASSET_SUFFIX
    };
    const size_t prefix_length = sizeof(ASSET_PREFIX) - 1;
    const unsigned char *version = NULL;
    size_t version_length = 0;
    size_t asset_length = 0;
    size_t offset = 0;
    size_t line;
    size_t index;

    ZeroMemory(pins, sizeof(*pins));
    for (line = 0; line < 5; line++) {
        size_t suffix_length = strlen(suffixes[line]);
        size_t name_start;
        size_t name_end;
        size_t line_version_length;

        if (offset > length || length - offset < HASH_HEX_LENGTH + 2) {
            return 0;
        }
        for (index = 0; index < HASH_HEX_LENGTH; index++) {
            int value = hex_digit(bytes[offset + index]);
            if (value < 0) {
                return 0;
            }
            if (line == 4) {
                if ((index & 1U) == 0) {
                    pins->windows_hash[index / 2] = (unsigned char)(value << 4);
                } else {
                    pins->windows_hash[index / 2] |= (unsigned char)value;
                }
                pins->windows_hex[index] = (wchar_t)bytes[offset + index];
            }
        }
        pins->windows_hex[HASH_HEX_LENGTH] = L'\0';
        offset += HASH_HEX_LENGTH;
        if (bytes[offset] != (unsigned char)' ' ||
            bytes[offset + 1] != (unsigned char)' ') {
            return 0;
        }
        offset += 2;
        name_start = offset;
        name_end = name_start;
        while (name_end < length && bytes[name_end] != (unsigned char)'\n') {
            name_end++;
        }
        if (name_end == length ||
            name_end - name_start < prefix_length + suffix_length ||
            memcmp(bytes + name_start, ASSET_PREFIX, prefix_length) != 0 ||
            memcmp(
                bytes + name_end - suffix_length, suffixes[line], suffix_length
            ) != 0) {
            return 0;
        }
        line_version_length =
            name_end - name_start - prefix_length - suffix_length;
        if (!valid_version_bytes(
                bytes + name_start + prefix_length, line_version_length
            )) {
            return 0;
        }
        if (line == 0) {
            version = bytes + name_start + prefix_length;
            version_length = line_version_length;
        } else if (line_version_length != version_length ||
                   memcmp(
                       bytes + name_start + prefix_length,
                       version,
                       version_length
                   ) != 0) {
            return 0;
        }
        offset = name_end + 1;
    }
    if (offset != length) {
        return 0;
    }

    for (index = 0; index < version_length; index++) {
        pins->version[index] = (wchar_t)version[index];
    }
    pins->version[version_length] = L'\0';
    for (index = 0; index < prefix_length; index++) {
        pins->windows_asset[asset_length++] =
            (wchar_t)(unsigned char)ASSET_PREFIX[index];
    }
    for (index = 0; index < version_length; index++) {
        pins->windows_asset[asset_length++] = pins->version[index];
    }
    for (index = 0; WINDOWS_ASSET_SUFFIX[index] != '\0'; index++) {
        pins->windows_asset[asset_length++] =
            (wchar_t)(unsigned char)WINDOWS_ASSET_SUFFIX[index];
    }
    pins->windows_asset[asset_length] = L'\0';
    return 1;
}

static int read_pin_manifest(
    const wchar_t *path, struct pin_manifest *pins, int *missing
)
{
    HANDLE file;
    LARGE_INTEGER size;
    unsigned char *bytes = NULL;
    DWORD length = 0;
    int ok = 0;

    *missing = 0;
    file = open_regular_file(path, GENERIC_READ, FILE_SHARE_READ);
    if (file == INVALID_HANDLE_VALUE) {
        DWORD error = GetLastError();
        if (error == ERROR_FILE_NOT_FOUND || error == ERROR_PATH_NOT_FOUND) {
            *missing = 1;
        }
        return 0;
    }
    if (!GetFileSizeEx(file, &size) || size.QuadPart <= 0 ||
        (ULONGLONG)size.QuadPart > MANIFEST_MAX_BYTES ||
        (ULONGLONG)size.QuadPart > (ULONGLONG)SIZE_MAX) {
        goto cleanup;
    }
    bytes = (unsigned char *)malloc((size_t)size.QuadPart);
    if (bytes == NULL ||
        !ReadFile(file, bytes, (DWORD)size.QuadPart, &length, NULL) ||
        length != (DWORD)size.QuadPart) {
        goto cleanup;
    }
    ok = parse_manifest_bytes(bytes, (size_t)length, pins);

cleanup:
    free(bytes);
    CloseHandle(file);
    return ok;
}

static int hashes_equal(
    const unsigned char left[HASH_BYTES],
    const unsigned char right[HASH_BYTES]
)
{
    unsigned char difference = 0;
    size_t index;

    for (index = 0; index < HASH_BYTES; index++) {
        difference |= (unsigned char)(left[index] ^ right[index]);
    }
    return difference == 0;
}

/* The step at which open_verified_binary refused a cached binary. Only a checksum
 * mismatch or an oversize file proves the cache entry wrong; the other steps say nothing
 * about its bytes. */
enum verify_step {
    VERIFY_OPEN = 1,
    VERIFY_PROTECT,
    VERIFY_READ,
    VERIFY_OVERSIZE,
    VERIFY_CHECKSUM
};

struct verify_failure {
    enum verify_step step;
    DWORD error;
};

static HANDLE open_verified_binary(
    const wchar_t *path,
    const struct pin_manifest *pins,
    const struct private_security *security,
    struct verify_failure *failure
)
{
    HANDLE file;
    LARGE_INTEGER size;
    unsigned char actual[HASH_BYTES];

    failure->step = VERIFY_OPEN;
    failure->error = ERROR_SUCCESS;
    file = open_regular_file(
        path,
        GENERIC_READ | FILE_READ_ATTRIBUTES | READ_CONTROL | WRITE_DAC |
            WRITE_OWNER,
        FILE_SHARE_READ
    );
    if (file == INVALID_HANDLE_VALUE) {
        failure->error = GetLastError();
        return INVALID_HANDLE_VALUE;
    }
    if (!protect_handle(file, security, 0)) {
        failure->step = VERIFY_PROTECT;
        failure->error = GetLastError();
        CloseHandle(file);
        return INVALID_HANDLE_VALUE;
    }
    if (!GetFileSizeEx(file, &size)) {
        failure->step = VERIFY_READ;
        failure->error = GetLastError();
        CloseHandle(file);
        return INVALID_HANDLE_VALUE;
    }
    if (size.QuadPart < 0 || (ULONGLONG)size.QuadPart > DOWNLOAD_MAX_BYTES) {
        failure->step = VERIFY_OVERSIZE;
        CloseHandle(file);
        return INVALID_HANDLE_VALUE;
    }
    SetLastError(ERROR_SUCCESS);
    if (!hash_handle(file, DOWNLOAD_MAX_BYTES, actual)) {
        failure->step = VERIFY_READ;
        failure->error = GetLastError();
        CloseHandle(file);
        return INVALID_HANDLE_VALUE;
    }
    if (!hashes_equal(actual, pins->windows_hash)) {
        failure->step = VERIFY_CHECKSUM;
        failure->error = ERROR_CRC;
        CloseHandle(file);
        return INVALID_HANDLE_VALUE;
    }
    failure->error = ERROR_SUCCESS;
    return file;
}

static int verified_open_retryable(DWORD error)
{
    return error == ERROR_SHARING_VIOLATION ||
           error == ERROR_LOCK_VIOLATION ||
           error == ERROR_FILE_NOT_FOUND ||
           error == ERROR_PATH_NOT_FOUND ||
           error == ERROR_DELETE_PENDING;
}

/* Only an open that may succeed later is retried: a busy, pending or not yet renamed file. */
static int verify_retryable(const struct verify_failure *failure)
{
    return failure->step == VERIFY_OPEN && verified_open_retryable(failure->error);
}

static int verify_disproves_cache(const struct verify_failure *failure)
{
    return failure->step == VERIFY_CHECKSUM || failure->step == VERIFY_OVERSIZE;
}

/* why_binary naming the step at which binary was refused, with its Windows error. */
static const char *verify_failure_reason(
    const char *binary, const struct verify_failure *failure
)
{
    unsigned long error = (unsigned long)failure->error;

    switch (failure->step) {
    case VERIFY_OPEN:
        return verify_retryable(failure)
            ? reason_text("%s remained busy or incomplete, Windows error %lu", binary, error)
            : reason_text("cannot open %s, Windows error %lu", binary, error);
    case VERIFY_PROTECT:
        return reason_text(
            "cannot protect %s for the current user, Windows error %lu", binary, error
        );
    case VERIFY_READ:
        return reason_text("cannot read and hash %s, Windows error %lu", binary, error);
    case VERIFY_OVERSIZE:
        return reason_text("%s exceeds the binary size limit", binary);
    case VERIFY_CHECKSUM:
    default:
        return reason_text("%s failed its pinned checksum", binary);
    }
}

static HANDLE open_verified_binary_with_retry(
    const wchar_t *path,
    const struct pin_manifest *pins,
    const struct private_security *security,
    int testing,
    struct verify_failure *failure
)
{
    HANDLE verified = open_verified_binary(path, pins, security, failure);
    unsigned int attempt;

    if (verified != INVALID_HANDLE_VALUE || !verify_retryable(failure)) {
        return verified;
    }
    if ((failure->error == ERROR_SHARING_VIOLATION ||
         failure->error == ERROR_LOCK_VIOLATION) &&
        !test_sync_point(testing, L"concurrent-loser-sharing-violation")) {
        return INVALID_HANDLE_VALUE;
    }

    for (attempt = 0; attempt < VERIFIED_OPEN_RETRY_ATTEMPTS; attempt++) {
        Sleep(VERIFIED_OPEN_RETRY_DELAY_MS);
        verified = open_verified_binary(path, pins, security, failure);
        if (verified != INVALID_HANDLE_VALUE || !verify_retryable(failure)) {
            return verified;
        }
    }
    return INVALID_HANDLE_VALUE;
}

static int parse_decimal_size(const wchar_t *value, ULONGLONG *parsed)
{
    ULONGLONG result = 0;
    const wchar_t *cursor = value;

    if (*cursor == L'\0') {
        return 0;
    }
    while (*cursor != L'\0') {
        unsigned int digit;
        if (*cursor < L'0' || *cursor > L'9') {
            return 0;
        }
        digit = (unsigned int)(*cursor - L'0');
        if (result > (UINT64_MAX - digit) / 10) {
            return 0;
        }
        result = result * 10 + digit;
        cursor++;
    }
    if (result == 0) {
        return 0;
    }
    *parsed = result;
    return 1;
}

static int local_http_host(const wchar_t *host)
{
    size_t length = wcslen(host);

    if (length > (size_t)INT_MAX) {
        return 0;
    }
    return CompareStringOrdinal(host, (int)length, L"localhost", -1, TRUE) ==
               CSTR_EQUAL ||
           CompareStringOrdinal(host, (int)length, L"127.0.0.1", -1, TRUE) ==
               CSTR_EQUAL ||
           CompareStringOrdinal(host, (int)length, L"::1", -1, TRUE) ==
               CSTR_EQUAL;
}

static void free_parsed_url(struct parsed_url *parsed)
{
    free(parsed->request);
    free(parsed->host);
    ZeroMemory(parsed, sizeof(*parsed));
}

static int parse_url(const wchar_t *url, struct parsed_url *parsed)
{
    URL_COMPONENTS components;
    size_t request_length;

    ZeroMemory(parsed, sizeof(*parsed));
    ZeroMemory(&components, sizeof(components));
    components.dwStructSize = sizeof(components);
    components.dwSchemeLength = (DWORD)-1;
    components.dwHostNameLength = (DWORD)-1;
    components.dwUserNameLength = (DWORD)-1;
    components.dwPasswordLength = (DWORD)-1;
    components.dwUrlPathLength = (DWORD)-1;
    components.dwExtraInfoLength = (DWORD)-1;
    if (!WinHttpCrackUrl(url, 0, 0, &components) ||
        components.dwHostNameLength == 0 ||
        components.dwUserNameLength != 0 || components.dwPasswordLength != 0 ||
        (components.nScheme != INTERNET_SCHEME_HTTP &&
         components.nScheme != INTERNET_SCHEME_HTTPS)) {
        return 0;
    }

    parsed->host = duplicate_wide_n(
        components.lpszHostName, components.dwHostNameLength
    );
    if (parsed->host == NULL) {
        return 0;
    }
    request_length = (size_t)components.dwUrlPathLength +
                     (size_t)components.dwExtraInfoLength;
    if (request_length == 0) {
        parsed->request = duplicate_wide(L"/");
    } else {
        struct wide_buffer request = {NULL, 0, 0};
        if (!append_text_n(
                &request,
                components.lpszUrlPath,
                components.dwUrlPathLength
            ) ||
            !append_text_n(
                &request,
                components.lpszExtraInfo,
                components.dwExtraInfoLength
            )) {
            free(request.data);
            free_parsed_url(parsed);
            return 0;
        }
        if (request.length == 0 || request.data[0] != L'/') {
            struct wide_buffer prefixed = {NULL, 0, 0};
            if (!append_character(&prefixed, L'/') ||
                !append_text(&prefixed, request.data)) {
                free(prefixed.data);
                free(request.data);
                free_parsed_url(parsed);
                return 0;
            }
            free(request.data);
            parsed->request = prefixed.data;
        } else {
            parsed->request = request.data;
        }
    }
    if (parsed->request == NULL) {
        free_parsed_url(parsed);
        return 0;
    }
    parsed->port = components.nPort;
    parsed->secure = components.nScheme == INTERNET_SCHEME_HTTPS;
    return 1;
}

static int url_allowed(
    const struct parsed_url *parsed,
    int testing,
    int previous_secure,
    int has_previous
)
{
    if (has_previous && previous_secure && !parsed->secure) {
        return 0;
    }
    if (parsed->secure) {
        return 1;
    }
    return testing && local_http_host(parsed->host);
}

static int starts_with_case(const wchar_t *value, const wchar_t *prefix)
{
    size_t prefix_length = wcslen(prefix);

    if (wcslen(value) < prefix_length || prefix_length > (size_t)INT_MAX) {
        return 0;
    }
    return CompareStringOrdinal(
        value, (int)prefix_length, prefix, (int)prefix_length, TRUE
    ) == CSTR_EQUAL;
}

static wchar_t *url_origin(const struct parsed_url *parsed)
{
    struct wide_buffer origin = {NULL, 0, 0};
    wchar_t port[16];
    int default_port =
        (parsed->secure && parsed->port == INTERNET_DEFAULT_HTTPS_PORT) ||
        (!parsed->secure && parsed->port == INTERNET_DEFAULT_HTTP_PORT);
    int ipv6 = wcschr(parsed->host, L':') != NULL;

    if (!append_text(&origin, parsed->secure ? L"https://" : L"http://") ||
        (ipv6 && !append_character(&origin, L'[')) ||
        !append_text(&origin, parsed->host) ||
        (ipv6 && !append_character(&origin, L']'))) {
        free(origin.data);
        return NULL;
    }
    if (!default_port) {
        int length = swprintf(
            port,
            sizeof(port) / sizeof(port[0]),
            L":%u",
            (unsigned int)parsed->port
        );
        if (length <= 0 || !append_text(&origin, port)) {
            free(origin.data);
            return NULL;
        }
    }
    return origin.data;
}

static wchar_t *resolve_redirect(
    const wchar_t *location, const struct parsed_url *current
)
{
    struct wide_buffer result = {NULL, 0, 0};
    wchar_t *origin = NULL;

    if (location[0] == L'\0' || wcschr(location, L'\r') != NULL ||
        wcschr(location, L'\n') != NULL) {
        return NULL;
    }
    if (starts_with_case(location, L"http://") ||
        starts_with_case(location, L"https://")) {
        return duplicate_wide(location);
    }
    if (location[0] == L'/' && location[1] == L'/') {
        if (!append_text(&result, current->secure ? L"https:" : L"http:") ||
            !append_text(&result, location)) {
            free(result.data);
            return NULL;
        }
        return result.data;
    }
    if (wcschr(location, L':') != NULL || location[0] == L'\\') {
        return NULL;
    }

    origin = url_origin(current);
    if (origin == NULL || !append_text(&result, origin)) {
        free(origin);
        free(result.data);
        return NULL;
    }
    free(origin);
    if (location[0] == L'/') {
        if (!append_text(&result, location)) {
            free(result.data);
            return NULL;
        }
        return result.data;
    }
    {
        const wchar_t *query = wcschr(current->request, L'?');
        size_t path_length = query == NULL
            ? wcslen(current->request)
            : (size_t)(query - current->request);
        size_t slash = path_length;

        while (slash > 0 && current->request[slash - 1] != L'/') {
            slash--;
        }
        if (!append_text_n(&result, current->request, slash) ||
            !append_text(&result, location)) {
            free(result.data);
            return NULL;
        }
    }
    return result.data;
}

/* Return 1 for a header, 0 when absent, and -1 for any other failure. */
static int query_header(
    HINTERNET request, DWORD query, wchar_t **value
)
{
    DWORD bytes = 0;
    wchar_t *buffer;

    *value = NULL;
    SetLastError(ERROR_SUCCESS);
    if (WinHttpQueryHeaders(
            request, query, WINHTTP_HEADER_NAME_BY_INDEX, NULL, &bytes, NULL)) {
        return -1;
    }
    if (GetLastError() == ERROR_WINHTTP_HEADER_NOT_FOUND) {
        return 0;
    }
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER || bytes < sizeof(wchar_t) ||
        bytes > MAXDWORD - sizeof(wchar_t)) {
        return -1;
    }
    buffer = (wchar_t *)malloc((size_t)bytes + sizeof(wchar_t));
    if (buffer == NULL) {
        return -1;
    }
    {
        DWORD capacity = bytes;
        if (!WinHttpQueryHeaders(
                request,
                query,
                WINHTTP_HEADER_NAME_BY_INDEX,
                buffer,
                &bytes,
                NULL) ||
            bytes > capacity || (bytes % sizeof(wchar_t)) != 0) {
            free(buffer);
            return -1;
        }
    }
    buffer[bytes / sizeof(wchar_t)] = L'\0';
    *value = buffer;
    return 1;
}

static int stream_response(
    HINTERNET request, HANDLE destination, ULONGLONG maximum_bytes
)
{
    wchar_t *content_length_value = NULL;
    ULONGLONG content_length = 0;
    ULONGLONG total = 0;
    int content_length_present;
    unsigned char buffer[65536];

    content_length_present = query_header(
        request, WINHTTP_QUERY_CONTENT_LENGTH, &content_length_value
    );
    if (content_length_present < 0 ||
        (content_length_present == 1 &&
         (!parse_decimal_size(content_length_value, &content_length) ||
          content_length > maximum_bytes))) {
        free(content_length_value);
        return 0;
    }
    free(content_length_value);

    for (;;) {
        DWORD available = 0;
        DWORD requested;
        DWORD received = 0;

        if (!WinHttpQueryDataAvailable(request, &available)) {
            return 0;
        }
        if (available == 0) {
            break;
        }
        requested = available > sizeof(buffer) ? (DWORD)sizeof(buffer) : available;
        if (total > maximum_bytes ||
            (ULONGLONG)requested > maximum_bytes - total ||
            !WinHttpReadData(request, buffer, requested, &received) ||
            received == 0 ||
            !write_all_handle(destination, buffer, received)) {
            return 0;
        }
        total += received;
    }
    if (content_length_present == 1 && total != content_length) {
        return 0;
    }
    return FlushFileBuffers(destination) != 0;
}

static int redirect_status(DWORD status)
{
    return status == 301 || status == 302 || status == 303 ||
           status == 307 || status == 308;
}

static int download_url(
    const wchar_t *url, int testing, ULONGLONG maximum_bytes, HANDLE destination
)
{
    HINTERNET session = NULL;
    wchar_t *current = duplicate_wide(url);
    int redirects = 0;
    int previous_secure = 0;
    int has_previous = 0;
    int ok = 0;

    if (current == NULL) {
        return 0;
    }
    session = WinHttpOpen(
        L"briefing-bootstrap",
        WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
        WINHTTP_NO_PROXY_NAME,
        WINHTTP_NO_PROXY_BYPASS,
        0
    );
    if (session == NULL ||
        !WinHttpSetTimeouts(session, 10000, 10000, 10000, 60000)) {
        goto cleanup;
    }

    for (;;) {
        struct parsed_url parsed;
        HINTERNET connection = NULL;
        HINTERNET request = NULL;
        DWORD flags;
        DWORD disable = WINHTTP_DISABLE_REDIRECTS;
        DWORD status = 0;
        DWORD status_bytes = sizeof(status);

        if (!parse_url(current, &parsed) ||
            !url_allowed(&parsed, testing, previous_secure, has_previous)) {
            free_parsed_url(&parsed);
            goto cleanup;
        }
        connection = WinHttpConnect(session, parsed.host, parsed.port, 0);
        flags = parsed.secure ? WINHTTP_FLAG_SECURE : 0;
        if (connection != NULL) {
            request = WinHttpOpenRequest(
                connection,
                L"GET",
                parsed.request,
                NULL,
                WINHTTP_NO_REFERER,
                WINHTTP_DEFAULT_ACCEPT_TYPES,
                flags
            );
        }
        if (request == NULL ||
            !WinHttpSetOption(
                request,
                WINHTTP_OPTION_DISABLE_FEATURE,
                &disable,
                sizeof(disable)
            ) ||
            !WinHttpSendRequest(
                request,
                WINHTTP_NO_ADDITIONAL_HEADERS,
                0,
                WINHTTP_NO_REQUEST_DATA,
                0,
                0,
                0
            ) ||
            !WinHttpReceiveResponse(request, NULL) ||
            !WinHttpQueryHeaders(
                request,
                WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                WINHTTP_HEADER_NAME_BY_INDEX,
                &status,
                &status_bytes,
                WINHTTP_NO_HEADER_INDEX
            )) {
            if (request != NULL) {
                WinHttpCloseHandle(request);
            }
            if (connection != NULL) {
                WinHttpCloseHandle(connection);
            }
            free_parsed_url(&parsed);
            goto cleanup;
        }

        if (status == 200) {
            ok = stream_response(request, destination, maximum_bytes);
            WinHttpCloseHandle(request);
            WinHttpCloseHandle(connection);
            free_parsed_url(&parsed);
            goto cleanup;
        }
        if (redirect_status(status) && redirects < MAX_REDIRECTS) {
            wchar_t *location = NULL;
            wchar_t *next = NULL;
            int header_status = query_header(
                request, WINHTTP_QUERY_LOCATION, &location
            );

            if (header_status == 1) {
                next = resolve_redirect(location, &parsed);
            }
            free(location);
            WinHttpCloseHandle(request);
            WinHttpCloseHandle(connection);
            previous_secure = parsed.secure;
            has_previous = 1;
            free_parsed_url(&parsed);
            if (next == NULL) {
                goto cleanup;
            }
            free(current);
            current = next;
            redirects++;
            continue;
        }

        WinHttpCloseHandle(request);
        WinHttpCloseHandle(connection);
        free_parsed_url(&parsed);
        goto cleanup;
    }

cleanup:
    free(current);
    if (session != NULL) {
        WinHttpCloseHandle(session);
    }
    return ok;
}

static wchar_t *join_url(const wchar_t *base, const wchar_t *asset)
{
    struct wide_buffer url = {NULL, 0, 0};
    size_t base_length = wcslen(base);

    while (base_length > 0 && base[base_length - 1] == L'/') {
        base_length--;
    }
    if (base_length == 0 || !append_text_n(&url, base, base_length) ||
        !append_character(&url, L'/') || !append_text(&url, asset)) {
        free(url.data);
        return NULL;
    }
    return url.data;
}

/* BRIEFING_BINARY_BASE_URL replaces "<prefix><version>", as in the starter. */
static wchar_t *binary_download_url(const struct pin_manifest *pins)
{
    int present;
    wchar_t *base = read_environment(L"BRIEFING_BINARY_BASE_URL", &present);
    wchar_t *url;

    if (present < 0) {
        return NULL;
    }
    if (!present || base[0] == L'\0') {
        free(base);
        base = append_suffix(RELEASE_URL_PREFIX_W, pins->version);
        if (base == NULL) {
            return NULL;
        }
    }
    url = join_url(base, pins->windows_asset);
    free(base);
    return url;
}

static wchar_t *new_temporary_file(
    const wchar_t *directory,
    const wchar_t *asset,
    const struct private_security *security,
    HANDLE *file
)
{
    static LONG counter = 0;
    unsigned int attempt;

    *file = INVALID_HANDLE_VALUE;
    for (attempt = 0; attempt < 100; attempt++) {
        wchar_t sequence_text[64];
        struct wide_buffer name = {NULL, 0, 0};
        LONG sequence = InterlockedIncrement(&counter);
        int length = swprintf(
            sequence_text,
            sizeof(sequence_text) / sizeof(sequence_text[0]),
            L".%lu.%lu.%ld.tmp",
            (unsigned long)GetCurrentProcessId(),
            (unsigned long)GetCurrentThreadId(),
            (long)sequence
        );
        wchar_t *path;

        if (length <= 0 ||
            (size_t)length >= sizeof(sequence_text) / sizeof(sequence_text[0]) ||
            !append_character(&name, L'.') || !append_text(&name, asset) ||
            !append_text(&name, sequence_text)) {
            free(name.data);
            return NULL;
        }
        path = join_path(directory, name.data);
        free(name.data);
        if (path == NULL) {
            return NULL;
        }
        *file = CreateFileW(
            path,
            GENERIC_READ | GENERIC_WRITE | DELETE | FILE_READ_ATTRIBUTES |
                READ_CONTROL | WRITE_DAC | WRITE_OWNER,
            FILE_SHARE_READ | FILE_SHARE_DELETE,
            (LPSECURITY_ATTRIBUTES)&security->attributes,
            CREATE_NEW,
            FILE_ATTRIBUTE_TEMPORARY,
            NULL
        );
        if (*file != INVALID_HANDLE_VALUE) {
            if (!protect_handle(*file, security, 0)) {
                (void)delete_open_file(*file);
                CloseHandle(*file);
                *file = INVALID_HANDLE_VALUE;
                free(path);
                return NULL;
            }
            return path;
        }
        {
            DWORD error = GetLastError();
            free(path);
            if (error != ERROR_FILE_EXISTS && error != ERROR_ALREADY_EXISTS) {
                return NULL;
            }
        }
    }
    return NULL;
}

static int safe_delete_regular(const wchar_t *path)
{
    HANDLE file = open_object(
        path,
        DELETE | FILE_READ_ATTRIBUTES,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        0
    );
    int deleted;

    if (file == INVALID_HANDLE_VALUE) {
        return 0;
    }
    deleted = delete_open_file(file);
    CloseHandle(file);
    return deleted;
}

/* The PAR directory of a binary is "par" beside it, in the same pin directory. */
static wchar_t *par_directory_beside(const wchar_t *binary)
{
    wchar_t *directory = parent_directory(binary);
    wchar_t *par_directory;

    if (directory == NULL) {
        return NULL;
    }
    par_directory = join_path(directory, CACHE_PAR_W);
    free(directory);
    return par_directory;
}

/* *error is the Windows error of a failed creation or protection, or ERROR_SUCCESS when
 * the directory exists but a path component is a reparse point or otherwise unsafe. */
static int ensure_par_directory(
    const wchar_t *par_directory,
    const struct private_security *security,
    DWORD *error
)
{
    *error = ERROR_SUCCESS;
    if (!ensure_private_directory(par_directory, security, 1)) {
        *error = GetLastError();
        if (*error == ERROR_SUCCESS) {
            *error = ERROR_GEN_FAILURE;
        }
        return 0;
    }
    return path_components_safe(par_directory, 0);
}

/* why_binary for a PAR directory beside binary that ensure_par_directory refused. */
static const char *par_directory_reason(const char *binary, DWORD error)
{
    if (error == ERROR_SUCCESS) {
        return reason_text(
            "the PAR cache directory beside %s has a reparse point or an unsafe path component",
            binary
        );
    }
    return reason_text(
        "the PAR cache directory beside %s is unusable, Windows error %lu",
        binary,
        (unsigned long)error
    );
}

static HANDLE provision_binary(
    const wchar_t *destination,
    const wchar_t *par_directory,
    const struct pin_manifest *pins,
    struct private_security *security,
    struct cache_lock *cache_lock,
    int testing,
    ULONGLONG maximum_bytes,
    const char **why
)
{
    HANDLE directory_lock = cache_entry_directory_handle(cache_lock);
    HANDLE temporary = INVALID_HANDLE_VALUE;
    HANDLE verified = INVALID_HANDLE_VALUE;
    wchar_t *initial_directory = NULL;
    wchar_t *current_directory = NULL;
    wchar_t *temporary_path = NULL;
    wchar_t *bound_destination = NULL;
    wchar_t *bound_par_directory = NULL;
    wchar_t *warm_program = NULL;
    wchar_t *warm_par_directory = NULL;
    wchar_t *installed_path = NULL;
    wchar_t *url = NULL;
    unsigned char actual[HASH_BYTES];
    const wchar_t *warm_arguments[1] = {L"--version"};
    DWORD warm_status = 1;
    DWORD warm_error = ERROR_SUCCESS;
    DWORD rename_error = ERROR_SUCCESS;
    DWORD par_error = ERROR_SUCCESS;
    struct verify_failure verify_failure = {VERIFY_OPEN, ERROR_SUCCESS};
    int installed = 0;
    int binding_valid = 1;

    *why = "the private binary cache lock is no longer valid";
    if (directory_lock == INVALID_HANDLE_VALUE ||
        !cache_lock_valid(cache_lock)) {
        goto cleanup;
    }
    initial_directory = final_path_by_handle(directory_lock);
    if (initial_directory == NULL ||
        !path_components_safe(initial_directory, 0)) {
        *why = "the binary cache directory has no safe final path";
        goto cleanup;
    }
    bound_destination = join_path(initial_directory, path_name(destination));
    bound_par_directory = join_path(initial_directory, path_name(par_directory));
    if (bound_destination == NULL || bound_par_directory == NULL) {
        *why = "cannot construct the bound binary cache paths";
        goto cleanup;
    }
    temporary_path = new_temporary_file(
        initial_directory, pins->windows_asset, security, &temporary
    );
    if (temporary_path == NULL) {
        *why = "cannot exclusively create a private download file in the binary cache";
        goto cleanup;
    }
    current_directory = final_path_by_handle(directory_lock);
    if (current_directory == NULL ||
        !same_path(initial_directory, current_directory) ||
        !cache_lock_valid(cache_lock)) {
        *why = "the binary cache changed while the download file was created";
        goto cleanup;
    }
    free(current_directory);
    current_directory = NULL;

    url = binary_download_url(pins);
    if (url == NULL) {
        *why = "cannot construct the binary download URL";
        goto cleanup;
    }
    if (!download_url(url, testing, maximum_bytes, temporary)) {
        *why = "the download of the pinned Windows binary failed or was refused";
        goto cleanup;
    }
    if (!hash_handle(temporary, maximum_bytes, actual)) {
        *why = "the downloaded Windows binary cannot be hashed within its size limit";
        goto cleanup;
    }
    if (!hashes_equal(actual, pins->windows_hash)) {
        *why = "the downloaded Windows binary does not match its pinned checksum";
        goto cleanup;
    }
    if (!handles_name_same_object(temporary_path, temporary, 0) ||
        !cache_lock_valid(cache_lock)) {
        *why = "the binary cache changed during the download";
        goto cleanup;
    }
    CloseHandle(temporary);
    temporary = INVALID_HANDLE_VALUE;
    temporary = open_regular_file(
        temporary_path,
        GENERIC_READ | FILE_READ_ATTRIBUTES,
        FILE_SHARE_READ
    );
    if (temporary == INVALID_HANDLE_VALUE ||
        !hash_handle(temporary, maximum_bytes, actual) ||
        !hashes_equal(actual, pins->windows_hash) ||
        !handles_name_same_object(temporary_path, temporary, 0) ||
        !cache_lock_valid(cache_lock)) {
        *why = "the downloaded Windows binary could not be reopened and rechecked";
        goto cleanup;
    }
    if (!ensure_par_directory(bound_par_directory, security, &par_error)) {
        *why = par_directory_reason("the downloaded binary", par_error);
        goto cleanup;
    }
    if (!test_sync_point(testing, L"warm-before-create") ||
        !handles_name_same_object(temporary_path, temporary, 0) ||
        !cache_lock_valid(cache_lock)) {
        *why = "the binary cache changed before the warm-up";
        goto cleanup;
    }
    warm_program = par_loader_path(
        temporary_path, 0, "the downloaded binary path", why
    );
    if (warm_program == NULL) {
        goto cleanup;
    }
    warm_par_directory = par_loader_path(
        bound_par_directory,
        par_directory_reserve(warm_program),
        "the PAR directory path",
        why
    );
    if (warm_par_directory == NULL) {
        goto cleanup;
    }
    if (!handles_name_same_object(warm_program, temporary, 0) ||
        !names_same_object(warm_par_directory, bound_par_directory, 1) ||
        !cache_lock_valid(cache_lock)) {
        *why = "the PAR loader names do not open the verified download and its PAR directory";
        goto cleanup;
    }
    if (!activate_token_user_owner(security)) {
        *why = "cannot make the current user the owner of new PAR files";
        goto cleanup;
    }
    {
        int warm_ran = run_with_par(
            warm_program,
            warm_par_directory,
            1,
            warm_arguments,
            1,
            &warm_status
        );
        int owner_restored;

        if (!warm_ran) {
            warm_error = GetLastError();
        }
        owner_restored = restore_token_owner(security);
        if (!warm_ran) {
            *why = reason_text(
                "the warm-up of the downloaded binary could not be started, Windows error %lu",
                (unsigned long)warm_error
            );
            goto cleanup;
        }
        if (warm_status != 0) {
            *why = reason_text(
                "the --version warm-up of the downloaded binary exited with status %lu, 0x%08lX",
                (unsigned long)warm_status,
                (unsigned long)warm_status
            );
            goto cleanup;
        }
        if (!owner_restored) {
            *why = "the original process token owner could not be restored after the warm-up";
            goto cleanup;
        }
    }

    current_directory = final_path_by_handle(directory_lock);
    if (current_directory == NULL ||
        !same_path(initial_directory, current_directory) ||
        !cache_lock_valid(cache_lock) ||
        !handles_name_same_object(temporary_path, temporary, 0)) {
        *why = "the binary cache changed during the warm-up";
        goto cleanup;
    }
    free(current_directory);
    current_directory = NULL;

    CloseHandle(temporary);
    temporary = INVALID_HANDLE_VALUE;
    temporary = open_regular_file(
        temporary_path,
        GENERIC_READ | DELETE | FILE_READ_ATTRIBUTES,
        FILE_SHARE_READ
    );
    if (temporary == INVALID_HANDLE_VALUE ||
        !hash_handle(temporary, maximum_bytes, actual) ||
        !hashes_equal(actual, pins->windows_hash) ||
        !handles_name_same_object(temporary_path, temporary, 0) ||
        !cache_lock_valid(cache_lock)) {
        *why = "the downloaded Windows binary changed during the warm-up";
        goto cleanup;
    }

    /* The rename names the full final path of the locked pin directory; the renamed
     * handle must then be exactly there. */
    if (rename_open_file(temporary, bound_destination, &rename_error)) {
        installed = 1;
        installed_path = final_path_by_handle(temporary);
        if (installed_path == NULL ||
            !same_path(installed_path, bound_destination)) {
            binding_valid = 0;
        }
    }
    if (installed &&
        !test_sync_point(testing, L"install-before-reopen")) {
        binding_valid = 0;
    }
    if (!cache_lock_valid(cache_lock)) {
        binding_valid = 0;
    }

    if (installed && binding_valid) {
        unsigned char installed_hash[HASH_BYTES];

        if (!hash_handle(temporary, DOWNLOAD_MAX_BYTES, installed_hash) ||
            !hashes_equal(installed_hash, pins->windows_hash)) {
            binding_valid = 0;
        }
    }
    if (!installed || !binding_valid) {
        (void)delete_open_file(temporary);
    }
    CloseHandle(temporary);
    temporary = INVALID_HANDLE_VALUE;
    if (!binding_valid) {
        *why = "the binary cache changed while the verified binary was installed";
        goto cleanup;
    }
    verified = open_verified_binary_with_retry(
        bound_destination, pins, security, testing, &verify_failure
    );
    if (verified == INVALID_HANDLE_VALUE) {
        if (installed) {
            *why = verify_failure_reason("the installed Windows binary", &verify_failure);
        } else {
            *why = reason_text(
                "the verified binary could not be renamed into the cache, Windows error %lu, "
                "and no concurrent install could be verified, Windows error %lu",
                (unsigned long)rename_error,
                (unsigned long)verify_failure.error
            );
        }
    }
    /* Only bytes that disprove the pin are removed; a refused open or ACL leaves them. */
    if (verified == INVALID_HANDLE_VALUE && installed &&
        verify_disproves_cache(&verify_failure) && cache_lock_valid(cache_lock)) {
        (void)safe_delete_regular(bound_destination);
    }

cleanup:
    if (temporary != INVALID_HANDLE_VALUE) {
        int deleted = 0;
        wchar_t *cleanup_path = NULL;

        if (!installed) {
            deleted = delete_open_file(temporary);
            if (!deleted) {
                cleanup_path = final_path_by_handle(temporary);
            }
        }
        CloseHandle(temporary);
        if (!installed && !deleted && cleanup_path != NULL) {
            (void)safe_delete_regular(cleanup_path);
        } else if (!installed && !deleted && temporary_path != NULL &&
                   cache_lock_valid(cache_lock)) {
            (void)safe_delete_regular(temporary_path);
        }
        free(cleanup_path);
    } else if (!installed && temporary_path != NULL &&
               cache_lock_valid(cache_lock)) {
        (void)safe_delete_regular(temporary_path);
    }
    free(url);
    free(installed_path);
    free(warm_par_directory);
    free(warm_program);
    free(bound_par_directory);
    free(bound_destination);
    free(temporary_path);
    free(current_directory);
    free(initial_directory);
    return verified;
}

static HANDLE find_binary(
    const wchar_t *executable_directory,
    const wchar_t *config,
    struct private_security *security,
    int can_provision,
    int testing,
    ULONGLONG maximum_bytes,
    wchar_t **binary_path,
    wchar_t **par_directory,
    struct cache_lock *cache_lock,
    const char **why_binary
)
{
    wchar_t *manifest_path = NULL;
    wchar_t *pin_directory = NULL;
    wchar_t *bound_directory = NULL;
    wchar_t pin_name[CACHE_PIN_LENGTH + 1];
    struct pin_manifest pins;
    HANDLE verified = INVALID_HANDLE_VALUE;
    struct verify_failure verify_failure = {VERIFY_OPEN, ERROR_SUCCESS};
    DWORD par_error = ERROR_SUCCESS;
    int missing = 0;

    *binary_path = NULL;
    *par_directory = NULL;
    manifest_path = join_path(executable_directory, PIN_MANIFEST_W);
    if (manifest_path == NULL) {
        *why_binary = "the pinned binary checksum manifest cannot be located";
        goto cleanup;
    }
    if (!read_pin_manifest(manifest_path, &pins, &missing)) {
        *why_binary = missing
            ? "no binary checksums are pinned in the plugin"
            : "the pinned binary checksum manifest is malformed";
        goto cleanup;
    }

    memcpy(pin_name, pins.windows_hex, CACHE_PIN_LENGTH * sizeof(wchar_t));
    pin_name[CACHE_PIN_LENGTH] = L'\0';
    pin_directory = ensure_private_cache(
        config, pins.version, pin_name, security, cache_lock
    );
    if (pin_directory == NULL) {
        *why_binary = "cannot create and bind the complete private binary cache path";
        goto cleanup;
    }
    /* This process is not long-path aware: a plain path fails once it reaches MAX_PATH
     * (CreateDirectoryW at 248). The cache entry and its PAR directory are named from the
     * extended final path of the locked pin directory instead, as provision_binary names
     * them. */
    bound_directory = final_path_by_handle(cache_entry_directory_handle(cache_lock));
    if (bound_directory == NULL || !path_components_safe(bound_directory, 0)) {
        *why_binary = "the binary cache directory has no safe final path";
        goto cleanup;
    }
    *binary_path = join_path(bound_directory, CACHE_BINARY_W);
    if (*binary_path == NULL) {
        *why_binary = "cannot construct the pinned binary cache path";
        goto cleanup;
    }
    *par_directory = join_path(bound_directory, CACHE_PAR_W);
    if (*par_directory == NULL) {
        *why_binary = "cannot construct the PAR cache path";
        goto cleanup;
    }

    if (GetFileAttributesW(*binary_path) == INVALID_FILE_ATTRIBUTES) {
        DWORD error = GetLastError();

        if (error != ERROR_FILE_NOT_FOUND && error != ERROR_PATH_NOT_FOUND) {
            *why_binary = reason_text(
                "cannot look up the cached Windows binary, Windows error %lu",
                (unsigned long)error
            );
            goto cleanup;
        }
        if (!can_provision) {
            *why_binary =
                "the pinned binary is not cached; only SessionStart downloads it";
            goto cleanup;
        }
    } else {
        if (!ensure_par_directory(*par_directory, security, &par_error)) {
            *why_binary = par_directory_reason("the cached Windows binary", par_error);
            goto cleanup;
        }
        verified = open_verified_binary_with_retry(
            *binary_path, &pins, security, testing, &verify_failure
        );
        if (verified != INVALID_HANDLE_VALUE) {
            *why_binary = NULL;
            goto cleanup;
        }
        *why_binary = verify_failure_reason("the cached Windows binary", &verify_failure);
        if (verify_disproves_cache(&verify_failure)) {
            /* Wrong bytes: only SessionStart removes them, to download the pinned ones. */
            if (!can_provision || !safe_delete_regular(*binary_path)) {
                goto cleanup;
            }
        } else if (verify_failure.step == VERIFY_OPEN &&
                   (verify_failure.error == ERROR_FILE_NOT_FOUND ||
                    verify_failure.error == ERROR_PATH_NOT_FOUND)) {
            /* Gone since the lookup: absent again, and only SessionStart downloads. */
            if (!can_provision) {
                *why_binary =
                    "the pinned binary is not cached; only SessionStart downloads it";
                goto cleanup;
            }
        } else {
            /* Busy, unopenable, unprotectable or unreadable: the bytes stay untouched. */
            goto cleanup;
        }
    }

    verified = provision_binary(
        *binary_path,
        *par_directory,
        &pins,
        security,
        cache_lock,
        testing,
        maximum_bytes,
        why_binary
    );
    if (verified != INVALID_HANDLE_VALUE) {
        *why_binary = NULL;
    }

cleanup:
    free(bound_directory);
    free(pin_directory);
    free(manifest_path);
    if (verified == INVALID_HANDLE_VALUE) {
        release_cache_lock(cache_lock);
        free(*par_directory);
        free(*binary_path);
        *par_directory = NULL;
        *binary_path = NULL;
    }
    return verified;
}

static wchar_t *find_on_path(const wchar_t *name)
{
    int present;
    wchar_t *path = read_environment(L"PATH", &present);
    DWORD needed;
    DWORD capacity;
    wchar_t *result = NULL;
    unsigned int attempt;

    if (present < 0 || !present || path[0] == L'\0') {
        free(path);
        return NULL;
    }
    needed = SearchPathW(path, name, NULL, 0, NULL, NULL);
    if (needed == 0 || needed >= 32768) {
        free(path);
        return NULL;
    }
    capacity = needed + 1;
    for (attempt = 0; attempt < 8; attempt++) {
        DWORD length;

        result = (wchar_t *)malloc((size_t)capacity * sizeof(wchar_t));
        if (result == NULL) {
            break;
        }
        length = SearchPathW(path, name, NULL, capacity, result, NULL);
        if (length == 0) {
            free(result);
            result = NULL;
            break;
        }
        if (length < capacity) {
            result[length] = L'\0';
            break;
        }
        free(result);
        result = NULL;
        if (length >= 32768) {
            break;
        }
        capacity = length + 1;
    }
    free(path);
    return result;
}

static int regular_path_exists(const wchar_t *path)
{
    DWORD attributes;
    return path_information(path, 0, &attributes);
}

/* Does this PATH entry lie in a WindowsApps directory, where the Microsoft Store's
 * python stubs live? Case-insensitive, like winlaunch. */
static int store_stub_directory(const wchar_t *directory)
{
    static const wchar_t needle[] = L"\\WindowsApps";
    const size_t needle_length = sizeof(needle) / sizeof(needle[0]) - 1;
    size_t length = wcslen(directory);
    size_t index;

    for (index = 0; index + needle_length <= length; index++) {
        if (CompareStringOrdinal(
                directory + index,
                (int)needle_length,
                needle,
                (int)needle_length,
                TRUE
            ) == CSTR_EQUAL) {
            return 1;
        }
    }
    return 0;
}

/* The first PATH entry, in order, that holds a file called name; entries in a
 * WindowsApps directory are skipped. */
static wchar_t *find_python_on_path(const wchar_t *name)
{
    int present;
    wchar_t *path = read_environment(L"PATH", &present);
    const wchar_t *entry = path;
    wchar_t *found = NULL;

    if (present <= 0) {
        free(path);
        return NULL;
    }
    for (;;) {
        const wchar_t *end = wcschr(entry, L';');
        size_t length = end != NULL ? (size_t)(end - entry) : wcslen(entry);
        wchar_t *directory = length > 0 ? duplicate_wide_n(entry, length) : NULL;

        if (directory != NULL && !store_stub_directory(directory)) {
            wchar_t *candidate = join_path(directory, name);
            DWORD attributes = candidate != NULL
                ? GetFileAttributesW(candidate)
                : INVALID_FILE_ATTRIBUTES;

            if (attributes != INVALID_FILE_ATTRIBUTES &&
                (attributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
                found = candidate;
            } else {
                free(candidate);
            }
        }
        free(directory);
        if (found != NULL || end == NULL) {
            break;
        }
        entry = end + 1;
    }
    free(path);
    return found;
}

/* winlaunch's interpreter rule (winlaunch/winlaunch.c): python3.exe, else python.exe,
 * else the py.exe launcher, which then gets -3 before the hook script. */
static wchar_t *find_python(int *launcher)
{
    wchar_t *python = find_python_on_path(L"python3.exe");

    *launcher = 0;
    if (python == NULL) {
        python = find_python_on_path(L"python.exe");
    }
    if (python == NULL) {
        python = find_python_on_path(L"py.exe");
        *launcher = python != NULL;
    }
    return python;
}

/* The Python script hooks\<script> runs in UTF-8 mode (PYTHONUTF8=1), so it reads the
 * payload on stdin as UTF-8 rather than in the ANSI code page; the caller's value is
 * restored after. */
static int run_python_fallback(
    const wchar_t *plugin_root,
    const wchar_t *script,
    int argc,
    wchar_t **argv,
    DWORD *status
)
{
    wchar_t *python = NULL;
    wchar_t *hooks = NULL;
    wchar_t *hook = NULL;
    wchar_t *original_utf8 = NULL;
    const wchar_t **arguments = NULL;
    size_t argument_count = 0;
    size_t leading;
    size_t index;
    int launcher = 0;
    int original_present = 0;
    int ok = 0;

    python = find_python(&launcher);
    hooks = join_path(plugin_root, L"hooks");
    if (hooks != NULL) {
        hook = join_path(hooks, script);
    }
    if (python == NULL || hook == NULL || !regular_path_exists(hook)) {
        goto cleanup;
    }

    leading = launcher ? 1 : 0;
    if (argc > 1 && wcscmp(argv[1], L"hook") == 0) {
        argument_count = leading + 1;
    } else {
        argument_count = leading + (size_t)argc;
    }
    arguments = (const wchar_t **)malloc(argument_count * sizeof(*arguments));
    if (arguments == NULL) {
        goto cleanup;
    }
    if (launcher) {
        arguments[0] = L"-3";
    }
    arguments[leading] = hook;
    for (index = leading + 1; index < argument_count; index++) {
        arguments[index] = argv[index - leading];
    }

    original_utf8 = read_environment(L"PYTHONUTF8", &original_present);
    if (original_present < 0 ||
        !SetEnvironmentVariableW(L"PYTHONUTF8", L"1")) {
        goto cleanup;
    }
    ok = run_process(
        python,
        argument_count,
        arguments,
        GetStdHandle(STD_INPUT_HANDLE),
        GetStdHandle(STD_OUTPUT_HANDLE),
        GetStdHandle(STD_ERROR_HANDLE),
        status
    );
    (void)SetEnvironmentVariableW(
        L"PYTHONUTF8", original_present ? original_utf8 : NULL
    );

cleanup:
    free(original_utf8);
    free(arguments);
    free(hook);
    free(hooks);
    free(python);
    return ok;
}

static int has_tsv_argument(int argc, wchar_t **argv)
{
    int index;

    for (index = 1; index < argc; index++) {
        if (wcscmp(argv[index], L"--tsv") == 0) {
            return 1;
        }
    }
    return 0;
}

static int run_perl_fallback(
    const wchar_t *plugin_root, int argc, wchar_t **argv, DWORD *status
)
{
    wchar_t *perl = NULL;
    wchar_t *lib = NULL;
    wchar_t *script_directory = NULL;
    wchar_t *script = NULL;
    wchar_t *include = NULL;
    const wchar_t *probe[3];
    const wchar_t **arguments = NULL;
    DWORD probe_status = 1;
    size_t argument_count;
    int index;
    int ok = 0;

    perl = find_on_path(L"perl.exe");
    lib = join_path(plugin_root, L"lib");
    script_directory = join_path(plugin_root, L"script");
    if (script_directory != NULL) {
        script = join_path(script_directory, L"briefing");
    }
    if (perl == NULL || lib == NULL || script == NULL ||
        !regular_path_exists(script)) {
        goto cleanup;
    }
    include = append_suffix(L"-I", lib);
    if (include == NULL) {
        goto cleanup;
    }
    probe[0] = include;
    probe[1] = L"-e";
    probe[2] = L"require App::Briefing::CLI";
    if (!run_process_quiet(perl, 3, probe, &probe_status) || probe_status != 0) {
        goto cleanup;
    }

    argument_count = (size_t)argc + 1;
    arguments = (const wchar_t **)malloc(argument_count * sizeof(*arguments));
    if (arguments == NULL) {
        goto cleanup;
    }
    arguments[0] = include;
    arguments[1] = script;
    for (index = 1; index < argc; index++) {
        arguments[(size_t)index + 1] = argv[index];
    }
    ok = run_process(
        perl,
        argument_count,
        arguments,
        GetStdHandle(STD_INPUT_HANDLE),
        GetStdHandle(STD_OUTPUT_HANDLE),
        GetStdHandle(STD_ERROR_HANDLE),
        status
    );

cleanup:
    free(arguments);
    free(include);
    free(script);
    free(script_directory);
    free(lib);
    free(perl);
    return ok;
}

static int report_no_fallback(
    int hook, const char *why_binary, const char *why_other
)
{
    const char *hook_prefix = "{\"systemMessage\":\"briefing: no binary (";
    const char *plain_prefix = "briefing: no binary (";
    const char *middle = ") and no fallback (";
    const char *hook_suffix = ").\"}\n";
    const char *plain_suffix = ").\n";
    const char *prefix = hook ? hook_prefix : plain_prefix;
    const char *suffix = hook ? hook_suffix : plain_suffix;
    size_t length = strlen(prefix) + strlen(why_binary) + strlen(middle) +
                    strlen(why_other) + strlen(suffix);
    char *message = (char *)malloc(length + 1);
    HANDLE stream = GetStdHandle(hook ? STD_OUTPUT_HANDLE : STD_ERROR_HANDLE);

    if (message == NULL) {
        return hook ? 0 : 1;
    }
    if (snprintf(
            message,
            length + 1,
            "%s%s%s%s%s",
            prefix,
            why_binary,
            middle,
            why_other,
            suffix
        ) < 0) {
        free(message);
        return hook ? 0 : 1;
    }
    if (stream != NULL && stream != INVALID_HANDLE_VALUE && length <= MAXDWORD) {
        (void)write_all_handle(stream, message, (DWORD)length);
    }
    free(message);
    return hook ? 0 : 1;
}

static int dispatch_fallback(
    const wchar_t *plugin_root,
    int argc,
    wchar_t **argv,
    int hook,
    int notice,
    const char *why_binary
)
{
    const char *why_other;
    DWORD status = 1;

    if (notice) {
        if (run_python_fallback(
                plugin_root, L"briefing-marketplace-notice", argc, argv, &status)) {
            return (int)status;
        }
        return 0;
    }
    if (hook) {
        if (run_python_fallback(
                plugin_root, L"briefing-preload", argc, argv, &status)) {
            return (int)status;
        }
        why_other =
            "no python3.exe, python.exe or py.exe outside WindowsApps is on PATH, "
            "or the Python hook is unavailable";
    } else if (argc > 1 && wcscmp(argv[1], L"doctor") == 0) {
        if (!has_tsv_argument(argc, argv) &&
            run_python_fallback(
                plugin_root, L"briefing-preload", argc, argv, &status)) {
            return (int)status;
        }
        if (run_perl_fallback(plugin_root, argc, argv, &status)) {
            return (int)status;
        }
        why_other = "neither the Python Doctor nor the Perl CLI is available";
    } else {
        if (run_perl_fallback(plugin_root, argc, argv, &status)) {
            return (int)status;
        }
        why_other =
            "perl.exe was not found on PATH or App::Briefing is unavailable";
    }
    return report_no_fallback(hook, why_binary, why_other);
}

static int run_verified_child(
    HANDLE verified,
    struct private_security *security,
    struct cache_lock *cache_lock,
    int testing,
    size_t argument_count,
    const wchar_t *const *arguments,
    DWORD *status,
    const char **why
)
{
    wchar_t *program = NULL;
    wchar_t *current_program = NULL;
    wchar_t *par_directory = NULL;
    wchar_t *loader_program = NULL;
    wchar_t *loader_par_directory = NULL;
    DWORD par_error = ERROR_SUCCESS;
    int ran = 0;

    if (!restore_token_owner(security)) {
        *why = "the original process token owner could not be restored before the start";
        goto cleanup;
    }
    if (!cache_lock_valid(cache_lock)) {
        *why = "the binary cache changed before the verified binary could be started";
        goto cleanup;
    }
    program = final_path_by_handle(verified);
    if (program == NULL) {
        *why = "the verified Windows binary has no final path";
        goto cleanup;
    }
    par_directory = par_directory_beside(program);
    if (par_directory == NULL) {
        *why = "cannot construct the PAR cache path";
        goto cleanup;
    }
    if (!ensure_par_directory(par_directory, security, &par_error)) {
        *why = par_directory_reason("the verified Windows binary", par_error);
        goto cleanup;
    }
    if (!test_sync_point(testing, L"cache-hit-before-create")) {
        *why = "the test synchronization point failed";
        goto cleanup;
    }
    loader_program = par_loader_path(
        program, 0, "the cached binary path", why
    );
    if (loader_program == NULL) {
        goto cleanup;
    }
    loader_par_directory = par_loader_path(
        par_directory,
        par_directory_reserve(loader_program),
        "the PAR directory path",
        why
    );
    if (loader_par_directory == NULL) {
        goto cleanup;
    }
    current_program = final_path_by_handle(verified);
    if (current_program == NULL || !same_path(program, current_program) ||
        !cache_lock_valid(cache_lock) ||
        !handles_name_same_object(program, verified, 0)) {
        *why = "the binary cache changed before the verified binary could be started";
        goto cleanup;
    }
    if (!cache_lock_valid(cache_lock) ||
        !handles_name_same_object(loader_program, verified, 0) ||
        !names_same_object(loader_par_directory, par_directory, 1)) {
        *why = "the PAR loader names do not open the verified binary and its PAR directory";
        goto cleanup;
    }
    if (!test_sync_point(testing, L"final-before-create")) {
        *why = "the test synchronization point failed";
        goto cleanup;
    }
    ran = run_with_par(
        loader_program,
        loader_par_directory,
        argument_count,
        arguments,
        0,
        status
    );
    if (!ran) {
        *why = reason_text(
            "the verified Windows binary could not be started, Windows error %lu",
            (unsigned long)GetLastError()
        );
    }

cleanup:
    free(loader_par_directory);
    free(loader_program);
    free(par_directory);
    free(current_program);
    free(program);
    return ran;
}

static int run_test_child(
    const wchar_t *child,
    const wchar_t *config,
    const struct private_security *security,
    int argc,
    wchar_t **argv
)
{
    wchar_t *canonical_child = NULL;
    wchar_t *par_directory = NULL;
    const wchar_t **arguments = NULL;
    HANDLE lock = INVALID_HANDLE_VALUE;
    DWORD status = 1;
    DWORD par_error;
    int result = 1;
    int index;

    if (child[0] == L'\0' || !is_absolute_path(child)) {
        write_error("briefing-bootstrap: the gated fixture child must be an absolute path\n");
        goto cleanup;
    }
    canonical_child = full_path(child);
    if (canonical_child == NULL) {
        write_error("briefing-bootstrap: cannot resolve the gated fixture child\n");
        goto cleanup;
    }
    normalize_path(canonical_child);
    trim_trailing_separators(canonical_child);
    if (!child_is_in_versioned_cache(config, canonical_child)) {
        write_error("briefing-bootstrap: the fixture child is outside the versioned cache\n");
        goto cleanup;
    }
    lock = open_regular_file(canonical_child, GENERIC_READ, FILE_SHARE_READ);
    if (lock == INVALID_HANDLE_VALUE) {
        write_error("briefing-bootstrap: the gated fixture child is not a regular file\n");
        goto cleanup;
    }
    par_directory = par_directory_beside(canonical_child);
    if (par_directory == NULL ||
        !ensure_par_directory(par_directory, security, &par_error)) {
        write_error("briefing-bootstrap: cannot create a private PAR cache path\n");
        goto cleanup;
    }
    if (argc > 1) {
        arguments = (const wchar_t **)malloc(
            (size_t)(argc - 1) * sizeof(*arguments)
        );
        if (arguments == NULL) {
            write_error("briefing-bootstrap: cannot allocate child arguments\n");
            goto cleanup;
        }
        for (index = 1; index < argc; index++) {
            arguments[index - 1] = argv[index];
        }
    }
    if (!run_with_par(
            canonical_child,
            par_directory,
            (size_t)(argc - 1),
            arguments,
            0,
            &status)) {
        write_error("briefing-bootstrap: cannot start the selected child\n");
        goto cleanup;
    }
    result = (int)status;

cleanup:
    if (lock != INVALID_HANDLE_VALUE) {
        CloseHandle(lock);
    }
    free(arguments);
    free(par_directory);
    free(canonical_child);
    return result;
}

int wmain(int argc, wchar_t **argv)
{
    wchar_t *executable = NULL;
    wchar_t *executable_directory = NULL;
    wchar_t *plugin_root = NULL;
    wchar_t *config = NULL;
    wchar_t *canonical_config = NULL;
    wchar_t *testing_value = NULL;
    wchar_t *test_child = NULL;
    wchar_t *maximum_value = NULL;
    wchar_t *binary_path = NULL;
    wchar_t *par_directory = NULL;
    const wchar_t **arguments = NULL;
    struct private_security security;
    struct cache_lock cache_lock;
    HANDLE binary_lock = INVALID_HANDLE_VALUE;
    const char *why_binary = "the verified Windows binary is unavailable";
    ULONGLONG maximum_bytes = DOWNLOAD_MAX_BYTES;
    DWORD status = 1;
    int testing_present;
    int child_present;
    int maximum_present;
    int testing = 0;
    int hook;
    int notice;
    int can_provision;
    int security_ready = 0;
    int result = 1;
    int index;

    initialize_cache_lock(&cache_lock);
    executable = module_path();
    if (executable == NULL || !is_absolute_path(executable)) {
        write_error("briefing-bootstrap: cannot discover its absolute executable path\n");
        goto cleanup;
    }
    executable_directory = parent_directory(executable);
    if (executable_directory == NULL) {
        write_error("briefing-bootstrap: cannot discover its executable directory\n");
        goto cleanup;
    }
    plugin_root = parent_directory(executable_directory);
    if (plugin_root == NULL) {
        write_error("briefing-bootstrap: cannot discover the plugin root\n");
        goto cleanup;
    }

    hook = argc > 1 && wcscmp(argv[1], L"hook") == 0;
    can_provision = hook && argc > 2 &&
                    wcscmp(argv[2], L"session-start") == 0;
    notice = hook && argc > 2 &&
             wcscmp(argv[2], L"marketplace-notice") == 0;

    test_child = read_environment(
        L"BRIEFING_BOOTSTRAP_TEST_CHILD", &child_present
    );
    if (child_present < 0) {
        why_binary = "the gated fixture-child setting cannot be read";
        goto fallback;
    }
    testing_value = read_environment(
        L"BRIEFING_BOOTSTRAP_TESTING", &testing_present
    );
    if (testing_present < 0) {
        if (child_present) {
            write_error("briefing-bootstrap: cannot read the test gate\n");
            goto cleanup;
        }
        why_binary = "the bootstrap test gate cannot be read";
        goto fallback;
    }
    testing = testing_present && wcscmp(testing_value, L"1") == 0;

    config = configuration_directory();
    if (config == NULL || !is_absolute_path(config)) {
        if (child_present) {
            write_error(
                "briefing-bootstrap: CLAUDE_CONFIG_DIR or USERPROFILE must be absolute\n"
            );
            goto cleanup;
        }
        why_binary =
            "no absolute CLAUDE_CONFIG_DIR or USERPROFILE is available for the cache";
        goto fallback;
    }
    canonical_config = full_path(config);
    if (canonical_config == NULL || !is_absolute_path(canonical_config)) {
        if (child_present) {
            write_error(
                "briefing-bootstrap: cannot resolve the configuration directory\n"
            );
            goto cleanup;
        }
        why_binary = "the configuration directory cannot be resolved safely";
        goto fallback;
    }
    normalize_path(canonical_config);
    trim_trailing_separators(canonical_config);

    if (!initialize_private_security(&security)) {
        if (child_present) {
            write_error(
                "briefing-bootstrap: cannot create current-user-only security\n"
            );
            goto cleanup;
        }
        why_binary = "current-user-only cache security cannot be initialized";
        goto fallback;
    }
    security_ready = 1;

    if (child_present) {
        if (!testing) {
            write_error("briefing-bootstrap: the fixture child requires the exact test gate\n");
            goto cleanup;
        }
        result = run_test_child(
            test_child, canonical_config, &security, argc, argv
        );
        goto cleanup;
    }

    maximum_value = read_environment(
        L"BRIEFING_BOOTSTRAP_TEST_MAX_BYTES", &maximum_present
    );
    if (maximum_present < 0) {
        why_binary = "the test-only size-limit setting cannot be read";
        goto fallback;
    }
    if (testing && maximum_present &&
        !parse_decimal_size(maximum_value, &maximum_bytes)) {
        why_binary = "the test-only binary download size limit is invalid";
        maximum_bytes = 0;
    }

    if (maximum_bytes != 0) {
        binary_lock = find_binary(
            executable_directory,
            canonical_config,
            &security,
            can_provision,
            testing,
            maximum_bytes,
            &binary_path,
            &par_directory,
            &cache_lock,
            &why_binary
        );
    }
    if (binary_lock != INVALID_HANDLE_VALUE) {
        if (argc > 1) {
            arguments = (const wchar_t **)malloc(
                (size_t)(argc - 1) * sizeof(*arguments)
            );
            if (arguments == NULL) {
                why_binary = "cannot allocate verified binary arguments";
            } else {
                for (index = 1; index < argc; index++) {
                    arguments[index - 1] = argv[index];
                }
            }
        }
        if (argc == 1 || arguments != NULL) {
            if (run_verified_child(
                    binary_lock,
                    &security,
                    &cache_lock,
                    testing,
                    (size_t)(argc - 1),
                    arguments,
                    &status,
                    &why_binary
                )) {
                result = (int)status;
                goto cleanup;
            }
        }
        CloseHandle(binary_lock);
        binary_lock = INVALID_HANDLE_VALUE;
    }

fallback:
    release_cache_lock(&cache_lock);
    if (security_ready && !restore_token_owner(&security)) {
        if (notice) {
            result = 0;
            goto cleanup;
        }
        result = report_no_fallback(
            hook,
            "the original process token owner could not be restored",
            "child processes were refused"
        );
        goto cleanup;
    }
    result = dispatch_fallback(plugin_root, argc, argv, hook, notice, why_binary);

cleanup:
    if (binary_lock != INVALID_HANDLE_VALUE) {
        CloseHandle(binary_lock);
    }
    release_cache_lock(&cache_lock);
    if (security_ready) {
        destroy_private_security(&security);
    }
    free(arguments);
    free(par_directory);
    free(binary_path);
    free(maximum_value);
    free(test_child);
    free(testing_value);
    free(canonical_config);
    free(config);
    free(plugin_root);
    free(executable_directory);
    free(executable);
    return result;
}
