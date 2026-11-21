#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <stdlib.h>
#include <wchar.h>

static int write_all(HANDLE handle, const void *buffer, DWORD size)
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

static wchar_t *read_environment(const wchar_t *name)
{
    DWORD needed = GetEnvironmentVariableW(name, NULL, 0);
    wchar_t *value;
    DWORD length;

    if (needed == 0) {
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
    return value;
}

static int write_utf8(HANDLE handle, const wchar_t *value)
{
    int needed = WideCharToMultiByte(
        CP_UTF8, WC_ERR_INVALID_CHARS, value, -1, NULL, 0, NULL, NULL
    );
    char *encoded;
    int length;
    int ok;

    if (needed == 0) {
        return 0;
    }
    encoded = (char *)malloc((size_t)needed);
    if (encoded == NULL) {
        return 0;
    }
    length = WideCharToMultiByte(
        CP_UTF8, WC_ERR_INVALID_CHARS, value, -1, encoded, needed, NULL, NULL
    );
    ok = length == needed && write_all(handle, encoded, (DWORD)(needed - 1));
    free(encoded);
    return ok;
}

static int write_field(HANDLE handle, const wchar_t *value)
{
    const char separator = '\0';
    return write_utf8(handle, value) && write_all(handle, &separator, 1);
}

static wchar_t *current_directory(void)
{
    DWORD needed = GetCurrentDirectoryW(0, NULL);
    wchar_t *directory;
    DWORD length;

    if (needed == 0) {
        return NULL;
    }
    directory = (wchar_t *)malloc((size_t)needed * sizeof(wchar_t));
    if (directory == NULL) {
        return NULL;
    }
    length = GetCurrentDirectoryW(needed, directory);
    if (length == 0 || length >= needed) {
        free(directory);
        return NULL;
    }
    return directory;
}

static wchar_t *module_path(void)
{
    DWORD capacity = 260;

    while (capacity <= 32768) {
        DWORD length;
        wchar_t *path = (wchar_t *)malloc((size_t)capacity * sizeof(wchar_t));

        if (path == NULL) {
            return NULL;
        }
        length = GetModuleFileNameW(NULL, path, capacity);
        if (length == 0) {
            free(path);
            return NULL;
        }
        if (length < capacity) {
            path[length] = L'\0';
            return path;
        }
        free(path);
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

static int record_invocation(int argc, wchar_t **argv)
{
    wchar_t *path = read_environment(L"BRIEFING_BOOTSTRAP_STUB_LOG");
    wchar_t *executable = NULL;
    HANDLE log = INVALID_HANDLE_VALUE;
    const char record_separator = '\0';
    int ok = 0;
    int i;

    if (path == NULL) {
        return 0;
    }
    executable = module_path();
    if (executable == NULL) {
        free(path);
        return 0;
    }
    log = CreateFileW(
        path,
        FILE_APPEND_DATA,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        NULL,
        OPEN_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    );
    free(path);
    if (log == INVALID_HANDLE_VALUE) {
        free(executable);
        return 0;
    }

    ok = write_field(log, executable);
    for (i = 1; ok && i < argc; i++) {
        ok = write_field(log, argv[i]);
    }
    if (ok) {
        ok = write_all(log, &record_separator, 1);
    }
    CloseHandle(log);
    free(executable);
    return ok;
}

static int is_perl_probe(int argc, wchar_t **argv)
{
    int i;

    for (i = 1; i < argc; i++) {
        if (wcscmp(argv[i], L"-e") == 0) {
            return 1;
        }
    }
    return 0;
}

static wchar_t *join_path(const wchar_t *left, const wchar_t *right)
{
    size_t left_length = wcslen(left);
    size_t right_length = wcslen(right);
    wchar_t *joined = (wchar_t *)malloc(
        (left_length + right_length + 2) * sizeof(wchar_t)
    );

    if (joined == NULL) {
        return NULL;
    }
    wcscpy(joined, left);
    if (left_length > 0 && left[left_length - 1] != L'\\' &&
        left[left_length - 1] != L'/') {
        joined[left_length++] = L'\\';
        joined[left_length] = L'\0';
    }
    wcscat(joined, right);
    return joined;
}

static int wait_for_release(void)
{
    wchar_t *path = read_environment(L"BRIEFING_BOOTSTRAP_STUB_RELEASE");
    unsigned int attempt;

    if (path == NULL) {
        return 0;
    }
    for (attempt = 0; attempt < 3000; attempt++) {
        DWORD attributes = GetFileAttributesW(path);

        if (attributes != INVALID_FILE_ATTRIBUTES &&
            !(attributes & FILE_ATTRIBUTE_DIRECTORY)) {
            free(path);
            return 1;
        }
        Sleep(10);
    }
    free(path);
    return 0;
}

static int create_par_tree(void)
{
    wchar_t *par = read_environment(L"PAR_GLOBAL_TEMP");
    wchar_t *directory = NULL;
    wchar_t *file = NULL;
    HANDLE handle = INVALID_HANDLE_VALUE;
    const char contents[] = "child-created\n";
    int ok = 0;

    if (par == NULL) {
        goto cleanup;
    }
    directory = join_path(par, L"fixture-child-directory");
    if (directory == NULL ||
        (!CreateDirectoryW(directory, NULL) &&
         GetLastError() != ERROR_ALREADY_EXISTS)) {
        goto cleanup;
    }
    file = join_path(directory, L"fixture-child-file");
    if (file == NULL) {
        goto cleanup;
    }
    handle = CreateFileW(
        file, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    );
    if (handle == INVALID_HANDLE_VALUE) {
        goto cleanup;
    }
    ok = write_all(handle, contents, (DWORD)(sizeof(contents) - 1));

cleanup:
    if (handle != INVALID_HANDLE_VALUE) {
        CloseHandle(handle);
    }
    free(file);
    free(directory);
    free(par);
    return ok;
}

static char *token_owner_hex(void)
{
    static const char digits[] = "0123456789abcdef";
    HANDLE token = NULL;
    DWORD needed = 0;
    TOKEN_OWNER *owner = NULL;
    DWORD length;
    const unsigned char *bytes;
    char *encoded = NULL;
    DWORD i;

    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) {
        return NULL;
    }
    (void)GetTokenInformation(token, TokenOwner, NULL, 0, &needed);
    if (needed == 0) {
        goto cleanup;
    }
    owner = (TOKEN_OWNER *)malloc(needed);
    if (owner == NULL ||
        !GetTokenInformation(token, TokenOwner, owner, needed, &needed) ||
        owner->Owner == NULL || !IsValidSid(owner->Owner)) {
        goto cleanup;
    }
    length = GetLengthSid(owner->Owner);
    if (length > ((size_t)-1 - 1) / 2) {
        goto cleanup;
    }
    encoded = (char *)malloc((size_t)length * 2 + 1);
    if (encoded == NULL) {
        goto cleanup;
    }
    bytes = (const unsigned char *)owner->Owner;
    for (i = 0; i < length; i++) {
        encoded[(size_t)i * 2] = digits[bytes[i] >> 4];
        encoded[(size_t)i * 2 + 1] = digits[bytes[i] & 15];
    }
    encoded[(size_t)length * 2] = '\0';

cleanup:
    free(owner);
    if (token != NULL) {
        CloseHandle(token);
    }
    return encoded;
}

static int write_token_owner(HANDLE output)
{
    char *encoded = token_owner_hex();
    const char newline = '\n';
    int ok;

    if (encoded == NULL) {
        return 0;
    }
    ok = write_all(output, encoded, (DWORD)strlen(encoded)) &&
         write_all(output, &newline, 1);
    free(encoded);
    return ok;
}

static int log_token_owner(void)
{
    wchar_t *path = read_environment(L"BRIEFING_BOOTSTRAP_STUB_OWNER_LOG");
    HANDLE log;
    int ok;

    if (path == NULL) {
        return 0;
    }
    log = CreateFileW(
        path,
        FILE_APPEND_DATA,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        NULL,
        OPEN_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    );
    free(path);
    if (log == INVALID_HANDLE_VALUE) {
        return 0;
    }
    ok = write_token_owner(log);
    CloseHandle(log);
    return ok;
}

static int touch_marker(void)
{
    wchar_t *path = read_environment(L"BRIEFING_BOOTSTRAP_STUB_MARKER");
    HANDLE marker;
    const char contents[] = "started\n";
    int ok;

    if (path == NULL) {
        return 1;
    }
    marker = CreateFileW(
        path, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    );
    free(path);
    if (marker == INVALID_HANDLE_VALUE) {
        return 0;
    }
    ok = write_all(marker, contents, (DWORD)(sizeof(contents) - 1));
    CloseHandle(marker);
    return ok;
}

static int copy_standard_input(void)
{
    HANDLE input = GetStdHandle(STD_INPUT_HANDLE);
    HANDLE output = GetStdHandle(STD_OUTPUT_HANDLE);
    HANDLE error = GetStdHandle(STD_ERROR_HANDLE);
    unsigned char buffer[4096];
    DWORD length;

    while (ReadFile(input, buffer, sizeof(buffer), &length, NULL) && length > 0) {
        if (!write_all(output, buffer, length) || !write_all(error, buffer, length)) {
            return 0;
        }
    }
    return 1;
}

static int capture_environment_and_stdin(void)
{
    wchar_t *path = read_environment(L"BRIEFING_BOOTSTRAP_STUB_CAPTURE");
    wchar_t *utf8 = read_environment(L"PYTHONUTF8");
    HANDLE capture;
    HANDLE input = GetStdHandle(STD_INPUT_HANDLE);
    unsigned char buffer[4096];
    DWORD length;
    const char prefix[] = "PYTHONUTF8=";
    const char unset[] = "<unset>";
    const char newline = '\n';
    int ok;

    if (path == NULL) {
        free(utf8);
        return 0;
    }
    capture = CreateFileW(
        path, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    );
    free(path);
    if (capture == INVALID_HANDLE_VALUE) {
        free(utf8);
        return 0;
    }
    ok = write_all(capture, prefix, (DWORD)(sizeof(prefix) - 1));
    if (ok) {
        ok = utf8 != NULL ? write_utf8(capture, utf8)
                          : write_all(capture, unset, (DWORD)(sizeof(unset) - 1));
    }
    ok = ok && write_all(capture, &newline, 1);
    while (ok && ReadFile(input, buffer, sizeof(buffer), &length, NULL) && length > 0) {
        ok = write_all(capture, buffer, length);
    }
    CloseHandle(capture);
    free(utf8);
    return ok;
}

int wmain(int argc, wchar_t **argv)
{
    wchar_t *mode;

    if (!touch_marker()) {
        return 81;
    }
    mode = read_environment(L"BRIEFING_BOOTSTRAP_STUB_MODE");
    if (mode == NULL) {
        return 82;
    }

    if (wcscmp(mode, L"record") == 0) {
        wchar_t *requested;
        wchar_t *end = NULL;
        long status;

        free(mode);
        if (!record_invocation(argc, argv)) {
            return 89;
        }
        if (is_perl_probe(argc, argv)) {
            return 0;
        }
        requested = read_environment(L"BRIEFING_BOOTSTRAP_STUB_EXIT");
        if (requested == NULL) {
            return 90;
        }
        status = wcstol(requested, &end, 10);
        if (end == requested || *end != L'\0' || status < 0 || status > 255) {
            free(requested);
            return 91;
        }
        free(requested);
        return (int)status;
    }

    if (wcscmp(mode, L"capture") == 0) {
        free(mode);
        if (!record_invocation(argc, argv)) {
            return 100;
        }
        return capture_environment_and_stdin() ? 0 : 101;
    }

    if (wcscmp(mode, L"owner-record") == 0) {
        wchar_t *requested;
        wchar_t *end = NULL;
        long status;

        free(mode);
        if (!log_token_owner() || !record_invocation(argc, argv)) {
            return 94;
        }
        if (is_perl_probe(argc, argv)) {
            return 0;
        }
        requested = read_environment(L"BRIEFING_BOOTSTRAP_STUB_EXIT");
        if (requested == NULL) {
            return 95;
        }
        status = wcstol(requested, &end, 10);
        if (end == requested || *end != L'\0' || status < 0 || status > 255) {
            free(requested);
            return 96;
        }
        free(requested);
        return (int)status;
    }

    if (wcscmp(mode, L"token-owner") == 0) {
        int ok = write_token_owner(GetStdHandle(STD_OUTPUT_HANDLE));

        free(mode);
        return ok ? 0 : 97;
    }

    if (wcscmp(mode, L"warm-zero-exit") == 0) {
        wchar_t *requested;
        wchar_t *end = NULL;
        long status;

        free(mode);
        if (argc == 2 && wcscmp(argv[1], L"--version") == 0) {
            return 0;
        }
        requested = read_environment(L"BRIEFING_BOOTSTRAP_STUB_EXIT");
        if (requested == NULL) {
            return 98;
        }
        status = wcstol(requested, &end, 10);
        if (end == requested || *end != L'\0' || status < 0 || status > 255) {
            free(requested);
            return 99;
        }
        free(requested);
        return (int)status;
    }

    if (wcscmp(mode, L"pause") == 0) {
        int ok;

        free(mode);
        ok = wait_for_release();
        return ok ? 0 : 92;
    }

    if (wcscmp(mode, L"par-tree") == 0) {
        int ok = create_par_tree();

        free(mode);
        return ok ? 0 : 93;
    }

    if (wcscmp(mode, L"argv") == 0) {
        HANDLE output = GetStdHandle(STD_OUTPUT_HANDLE);
        wchar_t *directory = current_directory();
        wchar_t *environment = read_environment(L"BRIEFING_BOOTSTRAP_STUB_VALUE");
        int ok = directory != NULL && environment != NULL;
        int i;

        if (ok) {
            ok = write_field(output, directory) && write_field(output, environment);
        }
        for (i = 1; ok && i < argc; i++) {
            ok = write_field(output, argv[i]);
        }
        free(directory);
        free(environment);
        free(mode);
        return ok ? 0 : 83;
    }

    if (wcscmp(mode, L"stdio") == 0) {
        int ok = copy_standard_input();
        free(mode);
        return ok ? 0 : 84;
    }

    if (wcscmp(mode, L"exit") == 0) {
        wchar_t *requested = read_environment(L"BRIEFING_BOOTSTRAP_STUB_EXIT");
        wchar_t *end = NULL;
        long status;

        free(mode);
        if (requested == NULL) {
            return 85;
        }
        status = wcstol(requested, &end, 10);
        if (end == requested || *end != L'\0' || status < 0 || status > 255) {
            free(requested);
            return 86;
        }
        free(requested);
        return (int)status;
    }

    if (wcscmp(mode, L"par") == 0) {
        wchar_t *par = read_environment(L"PAR_GLOBAL_TEMP");
        int ok = par != NULL && write_utf8(GetStdHandle(STD_OUTPUT_HANDLE), par);
        free(par);
        free(mode);
        return ok ? 0 : 87;
    }

    free(mode);
    return 88;
}
