/*-
 * Copyright (c) 2026 cPanel, Inc.
 * All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.10.1 or,
 * at your option, any later version of Perl 5 you may have available.
 *
 * crypt(3)-style glue around the vendored Openwall yescrypt sources.
 */

#include "cpx_yescrypt_names.h"

#include <string.h>

#include "yescrypt.h"
#include "yescrypt_crypt.h"

/*
 * Budget for one hash: the V array (128 * r * N bytes) times the number of
 * passes over it (t + 1).  1 GiB fits the costliest setting libxcrypt
 * generates, $y$jFT$ (a 1 GiB V, t = 0), and stops a hostile setting such as
 * $y$jLT$ (64 GiB) or a huge t before any work is done.
 */
#define CPX_YESCRYPT_MAX_MEM ((uint64_t)1 << 30)

/*
 * The other buffers (B, XY, S-boxes) add 384 * r bytes plus 12 KiB on top of
 * V, and the work outside the V passes also grows with r, so the budget alone
 * does not bound a small-N, huge-r setting such as $y$j/y3vrD$ (N = 4,
 * r = 2^21).  libxcrypt never generates r above 32.
 */
#define CPX_YESCRYPT_MAX_R 32

/*
 * Policy check called from yescrypt_r() once the setting is parsed and before
 * any memory is allocated.  Returns 0 if the parameters are acceptable.
 */
int cpx_yescrypt_check_params (const yescrypt_params_t *params)
{
    /* No ROM, no hash upgrades, no multi-lane mode. */
    if (params->NROM != 0 || params->g != 0 || params->p != 1)
        return -1;
    if (params->r == 0 || params->r > CPX_YESCRYPT_MAX_R || params->N < 2)
        return -1;

    /* N * 128 * r * (t + 1) <= MAX_MEM, divided out so nothing overflows. */
    if (params->N > CPX_YESCRYPT_MAX_MEM / 128 / params->r / ((uint64_t)params->t + 1))
        return -1;

    return 0;
}

char *cpx_yescrypt_crypt (const char *key, const char *salt, char *buf, size_t buflen)
{
    yescrypt_local_t local;
    uint8_t *ret;

    if (buflen == 0)
        return NULL;

    buf[0] = '\0';

    /* yescrypt_r() also accepts "$7$" (scrypt); that scheme is not supported. */
    if (strncmp(salt, "$y$", 3) != 0)
        return buf;

    if (yescrypt_init_local(&local))
        return buf;

    ret = yescrypt_r(NULL, &local,
        (const uint8_t *)key, strlen(key),
        (const uint8_t *)salt, NULL,
        (uint8_t *)buf, buflen);

    /* The region is freed on every call. */
    if (yescrypt_free_local(&local) || ret == NULL)
        buf[0] = '\0';

    return buf;
}
