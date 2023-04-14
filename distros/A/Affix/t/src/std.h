#pragma once

#include <math.h>
#include <stdbool.h>
#include <stddef.h> // offsetof
#include <stdio.h>
#include <string.h>

#define warn(FORMAT, ...)                                                                          \
    fprintf(stderr, FORMAT " in %s at line %i\n", ##__VA_ARGS__, __FILE__, __LINE__);              \
    fflush(stderr);

#if defined _WIN32 || defined __CYGWIN__
#include <BaseTsd.h>
// typedef SSIZE_T ssize_t;
typedef signed __int64 int64_t;
#ifdef __GNUC__
#define DLLEXPORT __attribute__((dllexport))
#else
#define DLLEXPORT __declspec(dllexport)
#endif
#else
#ifdef __GNUC__
#if __GNUC__ >= 4
#define DLLEXPORT __attribute__((visibility("default")))
#else
#define DLLEXPORT __attribute__((dllimport))
#endif
#else
#define DLLEXPORT __declspec(dllimport)
#endif
#include <inttypes.h>
#include <sys/types.h>
#endif

#define DumpHex(addr, len)                                                                         \
    ;                                                                                              \
    _DumpHex(addr, len, __FILE__, __LINE__)

void _DumpHex(const void *addr, size_t len, const char *file, int line) {
    fflush(stdout);
    int perLine = 16;
    // Silently ignore silly per-line values.
    if (perLine < 4 || perLine > 64) perLine = 16;
    size_t i;
    unsigned char buff[perLine + 1];
    const unsigned char *pc = (const unsigned char *)addr;
    fprintf(stderr, "Dumping %zu bytes from %p at %s line %d\n", len, addr, file, line);
    // Length checks.
    if (len == 0) {
        warn("ZERO LENGTH");
        return;
    }
    if (len < 0) {
        warn("NEGATIVE LENGTH: %zu", len);
        return;
    }
    for (i = 0; i < len; i++) {
        if ((i % perLine) == 0) { // Only print previous-line ASCII buffer for
            // lines beyond first.
            if (i != 0) fprintf(stderr, " | %s\n", buff);
            fprintf(stderr, "#  %04zu ", i); // Output the offset of current line.
        }
        // Now the hex code for the specific character.
        fprintf(stderr, " %02x", pc[i]);
        // And buffer a printable ASCII character for later.
        if ((pc[i] < 0x20) || (pc[i] > 0x7e)) // isprint() may be better.
            buff[i % perLine] = '.';
        else
            buff[i % perLine] = pc[i];
        buff[(i % perLine) + 1] = '\0';
    }
    // Pad out last line if not exactly perLine characters.
    while ((i % perLine) != 0) {
        fprintf(stderr, "   ");
        i++;
    }
    fprintf(stderr, " | %s\n", buff);
    fflush(stdout);
}
