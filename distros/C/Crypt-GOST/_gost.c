/*
 * $Id: _gost.c,v 1.00 2001/05/13 14:11:35 ams Exp $
 * Copyright 2001 Abhijit Menon-Sen <ams@wiw.org>
 */

#include "gost.h"
#include "sboxes.h"

#define byte(x,n)   ((unsigned char)((x) >> (8 * n)))
#define rol(x,n)    (((x) << ((int)(n))) | ((x) >> (32 - (int)(n))))
#define be_strtol(s) (uint32_t)(*(s)|*(s+1)<<8|*(s+2)<<16|*(s+3)<<24)
#define be_ltostr(l, s) \
    do {                                    \
        *(s  )=(unsigned char)((l)      );  \
        *(s+1)=(unsigned char)((l) >>  8);  \
        *(s+2)=(unsigned char)((l) >> 16);  \
        *(s+3)=(unsigned char)((l) >> 24);  \
    } while (0)

/* The key schedule derives 8 32-bit round subkeys directly from the
   256-bit input key. */
struct gost *gost_setup(unsigned char *key)
{
    int i;
    struct gost *self = malloc(sizeof(struct gost));

    if (self) {
        for (i = 0; i < 8; i++)
            self->K[i] = be_strtol(key+4*i);

        gost_sboxes(self, gost_default_sboxes);
    }

    return self;
}

void gost_free(struct gost *self)
{
    free(self);
}

/* Generates 4 8*8-bit S-boxes equivalent to the 8 4*4-bit S-boxes
   provided. */
void gost_sboxes(struct gost *self, unsigned char S[8][16])
{
    int i;

    for (i = 0; i < 256; i++) {
        self->S[3][i] = S[7][i >> 4] << 4 | S[6][i & 15];
        self->S[2][i] = S[5][i >> 4] << 4 | S[4][i & 15];
        self->S[1][i] = S[3][i >> 4] << 4 | S[2][i & 15];
        self->S[0][i] = S[1][i >> 4] << 4 | S[0][i & 15];
    }
}

static uint32_t f(unsigned char S[4][256], uint32_t x)
{
    uint32_t t;

    t = S[3][byte(x,3)] << 24 | S[2][byte(x,2)] << 16
      | S[1][byte(x,1)] <<  8 | S[0][byte(x,0)];

    return rol(t, 11);
}
    

/* This function uses self->key to encrypt or decrypt a single 64-bit
   block of input data, and writes it to output. */
void gost_crypt(struct gost *self,
                unsigned char *input, unsigned char *output,
                int decrypt)
{
    int i;
    uint32_t L, R;

    L = be_strtol(input);
    R = be_strtol(input+4);

    if (!decrypt) {
        for (i = 0; i < 3; i++) {
            R ^= f(self->S, L+self->K[0]);
            L ^= f(self->S, R+self->K[1]);
            R ^= f(self->S, L+self->K[2]);
            L ^= f(self->S, R+self->K[3]);
            R ^= f(self->S, L+self->K[4]);
            L ^= f(self->S, R+self->K[5]);
            R ^= f(self->S, L+self->K[6]);
            L ^= f(self->S, R+self->K[7]);
        }
        R ^= f(self->S, L+self->K[7]);
        L ^= f(self->S, R+self->K[6]);
        R ^= f(self->S, L+self->K[5]);
        L ^= f(self->S, R+self->K[4]);
        R ^= f(self->S, L+self->K[3]);
        L ^= f(self->S, R+self->K[2]);
        R ^= f(self->S, L+self->K[1]);
        L ^= f(self->S, R+self->K[0]);
    } else {
        R ^= f(self->S, L+self->K[0]);
        L ^= f(self->S, R+self->K[1]);
        R ^= f(self->S, L+self->K[2]);
        L ^= f(self->S, R+self->K[3]);
        R ^= f(self->S, L+self->K[4]);
        L ^= f(self->S, R+self->K[5]);
        R ^= f(self->S, L+self->K[6]);
        L ^= f(self->S, R+self->K[7]);
        for (i = 0; i < 3; i++) {
            R ^= f(self->S, L+self->K[7]);
            L ^= f(self->S, R+self->K[6]);
            R ^= f(self->S, L+self->K[5]);
            L ^= f(self->S, R+self->K[4]);
            R ^= f(self->S, L+self->K[3]);
            L ^= f(self->S, R+self->K[2]);
            R ^= f(self->S, L+self->K[1]);
            L ^= f(self->S, R+self->K[0]);
        }
    }

    be_ltostr(R, output);
    be_ltostr(L, output+4);
}
