/*
 * The TC18 block cipher
 *
 * It makes use of a key dependent 8x8 matrix and eight key dependent
 * 8x8 sboxes.
 *
 * {tomstdenis}{at}{yahoo}{dot}{com}, http://tomstdenis.home.dhs.org
 *
 * Copyright (C) 2004 Julius C. Duque <{jcduque}{at}{lycos}{dot}{com}>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 */

/* #include <stdio.h> */

#define ROUNDS  16

typedef struct tc18_key {
    unsigned char mat[8][8], rk[ROUNDS][8];
} tc18_key;

/* non-linear fixed 8x8 transform */
unsigned char sbox[256] = {
 23,  99,  80, 194, 235,  59, 231, 223, 198, 108,  91, 134, 100,  86,
107,  55, 161, 211, 183,  29, 117, 128, 185, 227, 157, 238, 219, 113,
119,  52, 189,   9, 102,   1,  11, 237, 213, 168,   0, 164,  46, 193,
254,  48,  60,  26, 176,  27,  14, 163, 197,  87, 236, 131, 221,   2,
 61, 178,  93, 204, 209, 124,  35, 160,  51, 245,   7, 120, 244, 132,
182, 217, 173,  28,  92,  58, 144, 218,  38,  88, 152,  78, 248,  34,
110, 242, 220,  76, 246,  85, 137, 187,  96, 115, 210,  31,  54,  83,
 94,  70,  67,  71, 192,  66,  12, 111, 133,  43, 126, 121, 208, 201,
255,  22, 136, 166,  47, 184,  90, 103, 181, 153, 199, 174, 135, 243,
162, 140, 151, 109,  63,  65,   6,  73, 171,  30, 177,  24,  49, 252,
214,  57, 141, 232,  25,  77, 112, 225, 250,  50, 247,  97,  19,  56,
 53, 105, 167,  20, 139,  37,  13,  40, 203, 212,  15,  62, 143, 190,
186,  72,  21,  74,  32,   4, 205, 249, 200, 127,  45, 118,  95, 233,
229,  17, 196, 104, 130, 188, 149, 195,   3, 207, 239, 101, 146, 142,
175,  33, 123,  69,  10, 222, 155,  18,  64, 240, 228, 116, 158, 234,
145, 253,  81,   5, 129, 150,  98, 191, 172, 202, 216, 147,   8,  16,
 82, 230,  84, 179, 215, 206,  41, 180, 156,  68, 241, 154,  89, 114,
 44, 125, 226,  79, 148, 224,  42,  75,  39, 251, 170,  36, 138, 122,
159, 169, 165, 106};

/* GF(2^8) multiplication mod p(x) = 0x169 */
static unsigned char gfmul(unsigned char a, unsigned char b)
{
    unsigned result, shift;
    shift  = b;
    result = 0;
    while (a) {
        if (a&1)
            result ^= shift;
        a >>= 1;
        shift <<= 1;
        if (shift & 0x100)
            shift ^= 0x169;
    }
    return (unsigned char)result;
}

void setup(unsigned char *ukey, int len, tc18_key *key)
{
    unsigned char tmp[104 + (ROUNDS * 8)], mat[2][8][8], z;
    int x, y, i;

    /* copy the user key */
    for (x = 0; x < 32; x++)
        tmp[x] = ukey[x % len];

    /* expand user key (0,1,2,3,5,7,32) */
    for (x = 32; x < sizeof(tmp); x++) {
        z = tmp[x - 32] ^ tmp[x - 7] ^ tmp[x - 5] ^ tmp[x - 3] ^
            tmp[x - 2]  ^ tmp[x - 1] ^ 0x1B;
        tmp[x] = (z<<1)|(z>>7);
    }

    /* run the sbox over the key to make the expanded key slightly
     * less linear */
    for (x = 32; x < sizeof(tmp); x++)
        tmp[x] = sbox[tmp[x]];

    /* make the two 8x8 matrices */
    i = 32;

    /* make the triangle in the lower left i.e of the form
     *
     * X 0 0 0
     * X X 0 0
     * X X X 0
     * X X X X
     * (etc)
     *
     * Both the diagonal and the first column are forced to non-zero
    */
    for (y = 0; y < 8; y++)
    for (x = 0; x < 8; x++)
        if ((x == y) || (x == 0)) {
            mat[0][y][x] = tmp[i]?tmp[i]:1; ++i;
        } else if (x < y)
            mat[0][y][x] = tmp[i++];
        else
            mat[0][y][x] = 0;

    /* make the triangle in the upper right of the form
     *
     * X X X X
     * 0 X X X
     * 0 0 X X
     * 0 0 0 X
     *
     * Again the diagonal and first row are both forced non-zero
    */
    for (y = 0; y < 8; y++)
    for (x = 0; x < 8; x++)
        if ((x == y) || (y == 0)) {
            mat[1][y][x] = tmp[i]?tmp[i]:1; ++i;
        } else if (x > y)
            mat[1][y][x] = tmp[i++];
        else
            mat[1][y][x] = 0;

    /* mult mat[0] by mat[1] */
    for (y = 0; y < 8; y++)
    for (x = 0; x < 8; x++)
    /* mat[0].row[y] * mat[1].col[x] */
        for (key->mat[y][x] = i = 0; i < 8; i++)
            key->mat[y][x] ^= gfmul(mat[0][y][i], mat[1][i][x]);

    /* copy round keys */
    for (y = 0; y < ROUNDS; y++)
    for (x = 0; x < 8; x++)
        key->rk[y][x] = tmp[104+(8*y)+x];
}

static void rnd(unsigned char *src, unsigned char *dst, tc18_key *key, int r)
{
    unsigned char tt[8];
    int x, y;

    /* add key to src and do substitution*/
    for (x = 0; x < 8; x++)
        tt[x] = sbox[src[x] ^ key->rk[r][x]];

    /* do matrix multiply and xor against dst */
    for (y = 0; y < 8; y++)
        for (x = 0; x < 8; x++)
            dst[y] ^= gfmul(key->mat[y][x], tt[x]);
}

void tc18_enc(unsigned char *blk, unsigned char *dst, tc18_key *key)
{
    int i, r;
    for (i = 0; i < 16; i++)
        dst[i] = blk[i];

    for (r = 0; r < ROUNDS; ) {
        rnd(&dst[0], &dst[8], key, r++);
        rnd(&dst[8], &dst[0], key, r++);
    }
}

void tc18_dec(unsigned char *blk, unsigned char *dst, tc18_key *key)
{
    int i, r;
    for (i = 0; i < 16; i++)
        dst[i] = blk[i];

    for (r = ROUNDS-1; r >= 0; ) {
        rnd(&dst[8], &dst[0], key, r--);
        rnd(&dst[0], &dst[8], key, r--);
    }
}

#ifdef TEST

/* ---> DEMO <----*/
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void)
{
    unsigned char ukey[8], blk[16], ciphertext[16], plain2[16];
    int x, y;
    tc18_key key;

    #ifdef __TURBOC__
        extern void clrscr(void);
        clrscr();
    #endif

    printf("The key takes %d bytes\n\n", sizeof(tc18_key));

    for (x = 0; x < 8; x++)
        ukey[x] = x;
    setup(ukey, 8, &key);

    printf("old plaintext: ");
    for (x = 0; x < 16; x++) {
        blk[x] = x;
        printf("%02X ", blk[x]);
    }
    printf("\n");

    tc18_enc(blk, ciphertext, &key);

    printf("ciphertext   : ");
    for (x = 0; x < 16; x++)
        printf("%02X ", ciphertext[x]);
    printf("\n");

    printf("new plaintext: ");
    tc18_dec(ciphertext, plain2, &key);
    for (x = 0; x < 16; x++)
        printf("%02X ", plain2[x]);
    printf("\n\n");

    printf("key material:\n");
    for (y = 0; y < 8; y++) {
        for (x = 0; x < 8; x++)
            printf("%02X ", key.mat[y][x]);
        printf("\n");
    }

    return 0;
}

#endif

