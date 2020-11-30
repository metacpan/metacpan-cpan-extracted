/*
 * Copyright 2001 Abhijit Menon-Sen <ams@toroid.org>
 */

#include <stdlib.h>
#include "platform.h"

#ifndef _TWOFISH_H_
#define _TWOFISH_H_

struct twofish {
    int len;                    /* Key length in 64-bit units: 2, 3 or 4 */
    uint32_t K[40];             /* Expanded key                          */
    uint32_t S[4][256];         /* Key-dependent S-boxes                 */
};

struct twofish *twofish_setup(unsigned char *key, int len);
void twofish_free(struct twofish *self);
void twofish_crypt(struct twofish *t,
                   unsigned char *input, unsigned char *output,
                   int decrypt);

#endif
