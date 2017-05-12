/*
 * $Id: _tea.c,v 1.25 2001/05/21 17:32:59 ams Exp $
 * Copyright 2001 Abhijit Menon-Sen <ams@wiw.org>
 */

#include "tea.h"

#define strtonl(s) (uint32_t)(*(s)|*(s+1)<<8|*(s+2)<<16|*(s+3)<<24)
#define nltostr(l, s) \
    do {                                    \
        *(s  )=(unsigned char)((l)      );  \
        *(s+1)=(unsigned char)((l) >>  8);  \
        *(s+2)=(unsigned char)((l) >> 16);  \
        *(s+3)=(unsigned char)((l) >> 24);  \
    } while (0)

/* TEA is a 64-bit symmetric block cipher with a 128-bit key, developed
   by David J. Wheeler and Roger M. Needham, and described in their
   paper at <URL:http://www.cl.cam.ac.uk/ftp/users/djw3/tea.ps>.

   This implementation is based on their code in
   <URL:http://www.cl.cam.ac.uk/ftp/users/djw3/xtea.ps> */

struct tea *tea_setup(unsigned char *key, int rounds)
{
    struct tea *self = malloc(sizeof(struct tea));

    if (self) {
        self->rounds = rounds;

        self->key[0] = strtonl(key);
        self->key[1] = strtonl(key+4);
        self->key[2] = strtonl(key+8);
        self->key[3] = strtonl(key+12);
    }

    return self;
}

void tea_free(struct tea *self)
{
    free(self);
}

void tea_crypt(struct tea *self,
               unsigned char *input, unsigned char *output,
               int decrypt)
{
    int i, rounds;
    uint32_t delta = 0x9E3779B9, /* 2^31*(sqrt(5)-1) */
             *k, y, z, sum = 0;

    k = self->key;
    rounds = self->rounds;

    y = strtonl(input);
    z = strtonl(input+4);

    if (!decrypt) {
        for (i = 0; i < rounds; i++) {
            y += ((z << 4 ^ z >> 5) + z) ^ (sum + k[sum & 3]);
            sum += delta;
            z += ((y << 4 ^ y >> 5) + y) ^ (sum + k[sum >> 11 & 3]);
        }
    } else {
        sum = delta * rounds;
        for (i = 0; i < rounds; i++) {
            z -= ((y << 4 ^ y >> 5) + y) ^ (sum + k[sum >> 11 & 3]);
            sum -= delta;
            y -= ((z << 4 ^ z >> 5) + z) ^ (sum + k[sum & 3]);
        }
    }

    nltostr(y, output);
    nltostr(z, output+4);
}
