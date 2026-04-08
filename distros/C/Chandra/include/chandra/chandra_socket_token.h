#ifndef CHANDRA_SOCKET_TOKEN_H
#define CHANDRA_SOCKET_TOKEN_H

/*
 * chandra_socket_token.h — Token generation and rotation helpers
 *
 * Provides C-level token generation (same as Hub's inline code)
 * and helpers for rotation timing checks.
 */

#include "chandra.h"
#include <time.h>
#ifdef _WIN32
#include <windows.h>
#include <wincrypt.h>
#endif

/*
 * On Win32 with MULTIPLICITY + PERL_IMPLICIT_SYS, gettimeofday is macro'd
 * to PerlProc_gettimeofday which requires the interpreter context (my_perl).
 * Use native Win32 API or raw syscall directly instead.
 */
#ifdef _WIN32
static void _chandra_gettimeofday(struct timeval *tv) {
    FILETIME ft;
    ULARGE_INTEGER ull;
    GetSystemTimeAsFileTime(&ft);
    ull.LowPart = ft.dwLowDateTime;
    ull.HighPart = ft.dwHighDateTime;
    /* FILETIME is 100ns intervals since 1601-01-01; convert to Unix epoch */
    ull.QuadPart -= 116444736000000000ULL;
    tv->tv_sec  = (long)(ull.QuadPart / 10000000ULL);
    tv->tv_usec = (long)((ull.QuadPart % 10000000ULL) / 10);
}
#define CHANDRA_GETTIMEOFDAY(tv) _chandra_gettimeofday(tv)
#else
#define CHANDRA_GETTIMEOFDAY(tv) gettimeofday((tv), NULL)
#endif

/* ---- Generate a 32-char hex token from /dev/urandom (or CryptGenRandom) ---- */

static SV *
_token_generate(pTHX_ int byte_len)
{
    unsigned char *bytes;
    char *hex;
    SV *result;
    int got_random = 0;

    if (byte_len < 8)  byte_len = 8;
    if (byte_len > 128) byte_len = 128;

    Newxz(bytes, byte_len, unsigned char);
    Newxz(hex, byte_len * 2 + 1, char);

#ifdef _WIN32
    {
        HCRYPTPROV hProv;
        if (CryptAcquireContext(&hProv, NULL, NULL, PROV_RSA_FULL,
                                CRYPT_VERIFYCONTEXT)) {
            if (CryptGenRandom(hProv, byte_len, bytes))
                got_random = 1;
            CryptReleaseContext(hProv, 0);
        }
    }
#else
    {
        int fd = open("/dev/urandom", O_RDONLY);
        if (fd >= 0) {
            ssize_t n = read(fd, bytes, byte_len);
            close(fd);
            if (n == byte_len)
                got_random = 1;
        }
    }
#endif

    if (got_random) {
        int i;
        for (i = 0; i < byte_len; i++)
            sprintf(hex + i * 2, "%02x", bytes[i]);
        hex[byte_len * 2] = '\0';
        result = newSVpvn(hex, byte_len * 2);
        Safefree(bytes);
        Safefree(hex);
        return result;
    }

    /* Fallback: Perl random */
    {
        int i;
        int words = (byte_len + 3) / 4;
        for (i = 0; i < words && i * 8 < byte_len * 2; i++)
            sprintf(hex + i * 8, "%08x",
                (unsigned int)(Drand01() * (double)0xFFFFFFFF));
        hex[byte_len * 2] = '\0';
        result = newSVpvn(hex, byte_len * 2);
    }

    Safefree(bytes);
    Safefree(hex);
    return result;
}

/* ---- Check if rotation is due ---- */

static int
_token_rotation_due(NV rotation_at_epoch)
{
    struct timeval tv;
    NV now;
    CHANDRA_GETTIMEOFDAY(&tv);
    now = (NV)tv.tv_sec + (NV)tv.tv_usec / 1000000.0;
    return (now >= rotation_at_epoch) ? 1 : 0;
}

/* ---- Check if token has expired ---- */

static int
_token_expired(NV expires_at_epoch)
{
    struct timeval tv;
    NV now;
    CHANDRA_GETTIMEOFDAY(&tv);
    now = (NV)tv.tv_sec + (NV)tv.tv_usec / 1000000.0;
    return (now >= expires_at_epoch) ? 1 : 0;
}

/* ---- Check if grace period is still active ---- */

static int
_token_in_grace(NV grace_until_epoch)
{
    struct timeval tv;
    NV now;
    CHANDRA_GETTIMEOFDAY(&tv);
    now = (NV)tv.tv_sec + (NV)tv.tv_usec / 1000000.0;
    return (now < grace_until_epoch) ? 1 : 0;
}

/* ---- Get current epoch as NV ---- */

static NV
_token_now(void)
{
    struct timeval tv;
    CHANDRA_GETTIMEOFDAY(&tv);
    return (NV)tv.tv_sec + (NV)tv.tv_usec / 1000000.0;
}

#endif /* CHANDRA_SOCKET_TOKEN_H */
