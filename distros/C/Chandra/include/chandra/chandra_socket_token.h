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

/* ---- Generate a 32-char hex token from /dev/urandom ---- */

static SV *
_token_generate(pTHX_ int byte_len)
{
    unsigned char *bytes;
    char *hex;
    int fd;
    SV *result;

    if (byte_len < 8)  byte_len = 8;
    if (byte_len > 128) byte_len = 128;

    Newxz(bytes, byte_len, unsigned char);
    Newxz(hex, byte_len * 2 + 1, char);

    fd = open("/dev/urandom", O_RDONLY);
    if (fd >= 0) {
        ssize_t n = read(fd, bytes, byte_len);
        close(fd);
        if (n == byte_len) {
            int i;
            for (i = 0; i < byte_len; i++)
                sprintf(hex + i * 2, "%02x", bytes[i]);
            hex[byte_len * 2] = '\0';
            result = newSVpvn(hex, byte_len * 2);
            Safefree(bytes);
            Safefree(hex);
            return result;
        }
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
    gettimeofday(&tv, NULL);
    now = (NV)tv.tv_sec + (NV)tv.tv_usec / 1000000.0;
    return (now >= rotation_at_epoch) ? 1 : 0;
}

/* ---- Check if token has expired ---- */

static int
_token_expired(NV expires_at_epoch)
{
    struct timeval tv;
    NV now;
    gettimeofday(&tv, NULL);
    now = (NV)tv.tv_sec + (NV)tv.tv_usec / 1000000.0;
    return (now >= expires_at_epoch) ? 1 : 0;
}

/* ---- Check if grace period is still active ---- */

static int
_token_in_grace(NV grace_until_epoch)
{
    struct timeval tv;
    NV now;
    gettimeofday(&tv, NULL);
    now = (NV)tv.tv_sec + (NV)tv.tv_usec / 1000000.0;
    return (now < grace_until_epoch) ? 1 : 0;
}

/* ---- Get current epoch as NV ---- */

static NV
_token_now(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (NV)tv.tv_sec + (NV)tv.tv_usec / 1000000.0;
}

#endif /* CHANDRA_SOCKET_TOKEN_H */
