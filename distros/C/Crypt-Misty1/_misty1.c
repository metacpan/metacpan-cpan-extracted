/* _misty1.c - An implementation of the MISTY1 block cipher, as
 * described in RFC 2994.
 *
 * Copyright (C) 2003 Julius C. Duque <jcduque (AT) lycos (DOT) com>
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

#include <stdio.h>

unsigned int EK[32];

static unsigned char s7[128] = {
    27,  50,  51,  90,  59,  16,  23,  84,  91,  26, 114, 115, 107,
    44, 102,  73,  31,  36,  19, 108,  55,  46,  63,  74,  93,  15,
    64,  86,  37,  81,  28,   4,  11,  70,  32,  13, 123,  53,  68,
    66,  43,  30,  65,  20,  75, 121,  21, 111,  14,  85,   9,  54,
   116,  12, 103,  83,  40,  10, 126,  56,   2,   7,  96,  41,  25,
    18, 101,  47,  48,  57,   8, 104,  95, 120,  42,  76, 100,  69,
   117,  61,  89,  72,   3,  87, 124,  79,  98,  60,  29,  33,  94,
    39, 106, 112,  77,  58,   1, 109, 110,  99,  24, 119,  35,   5,
    38, 118,   0,  49,  45, 122, 127,  97,  80,  34,  17,   6,  71,
    22,  82,  78, 113,  62, 105,  67,  52,  92,  88, 125
};

static unsigned short s9[512] = {
    451, 203, 339, 415, 483, 233, 251,  53, 385, 185, 279, 491, 307,
      9,  45, 211, 199, 330,  55, 126, 235, 356, 403, 472, 163, 286,
     85,  44,  29, 418, 355, 280, 331, 338, 466,  15,  43,  48, 314,
    229, 273, 312, 398,  99, 227, 200, 500,  27,   1, 157, 248, 416,
    365, 499,  28, 326, 125, 209, 130, 490, 387, 301, 244, 414, 467,
    221, 482, 296, 480, 236,  89, 145,  17, 303,  38, 220, 176, 396,
    271, 503, 231, 364, 182, 249, 216, 337, 257, 332, 259, 184, 340,
    299, 430,  23, 113,  12,  71,  88, 127, 420, 308, 297, 132, 349,
    413, 434, 419,  72, 124,  81, 458,  35, 317, 423, 357,  59,  66,
    218, 402, 206, 193, 107, 159, 497, 300, 388, 250, 406, 481, 361,
    381,  49, 384, 266, 148, 474, 390, 318, 284,  96, 373, 463, 103,
    281, 101, 104, 153, 336,   8,   7, 380, 183,  36,  25, 222, 295,
    219, 228, 425,  82, 265, 144, 412, 449,  40, 435, 309, 362, 374,
    223, 485, 392, 197, 366, 478, 433, 195, 479,  54, 238, 494, 240,
    147,  73, 154, 438, 105, 129, 293,  11,  94, 180, 329, 455, 372,
     62, 315, 439, 142, 454, 174,  16, 149, 495,  78, 242, 509, 133,
    253, 246, 160, 367, 131, 138, 342, 155, 316, 263, 359, 152, 464,
    489,   3, 510, 189, 290, 137, 210, 399,  18,  51, 106, 322, 237,
    368, 283, 226, 335, 344, 305, 327,  93, 275, 461, 121, 353, 421,
    377, 158, 436, 204,  34, 306,  26, 232,   4, 391, 493, 407,  57,
    447, 471,  39, 395, 198, 156, 208, 334, 108,  52, 498, 110, 202,
     37, 186, 401, 254,  19, 262,  47, 429, 370, 475, 192, 267, 470,
    245, 492, 269, 118, 276, 427, 117, 268, 484, 345,  84, 287,  75,
    196, 446, 247,  41, 164,  14, 496, 119,  77, 378, 134, 139, 179,
    369, 191, 270, 260, 151, 347, 352, 360, 215, 187, 102, 462, 252,
    146, 453, 111,  22,  74, 161, 313, 175, 241, 400,  10, 426, 323,
    379,  86, 397, 358, 212, 507, 333, 404, 410, 135, 504, 291, 167,
    440, 321,  60, 505, 320,  42, 341, 282, 417, 408, 213, 294, 431,
     97, 302, 343, 476, 114, 394, 170, 150, 277, 239,  69, 123, 141,
    325,  83,  95, 376, 178,  46,  32, 469,  63, 457, 487, 428,  68,
     56,  20, 177, 363, 171, 181,  90, 386, 456, 468,  24, 375, 100,
    207, 109, 256, 409, 304, 346,   5, 288, 443, 445, 224,  79, 214,
    319, 452, 298,  21,   6, 255, 411, 166,  67, 136,  80, 351, 488,
    289, 115, 382, 188, 194, 201, 371, 393, 501, 116, 460, 486, 424,
    405,  31,  65,  13, 442,  50,  61, 465, 128, 168,  87, 441, 354,
    328, 217, 261,  98, 122,  33, 511, 274, 264, 448, 169, 285, 432,
    422, 205, 243,  92, 258,  91, 473, 324, 502, 173, 165,  58, 459,
    310, 383,  70, 225,  30, 477, 230, 311, 506, 389, 140, 143,  64,
    437, 190, 120,   0, 172, 272, 350, 292,   2, 444, 162, 234, 112,
    508, 278, 348,  76, 450
};

unsigned int FI(unsigned int fi_in, unsigned int fi_key)
{
    unsigned int d7, d9;

    d9 = s9[((fi_in >> 7) & 0x1ff)] ^ ((fi_in & 0x7f)); 
    d7 = (fi_in & 0x7f);
    d7 = ((s7[d7] ^ d9) & 0x7f) ^ ((fi_key >> 9) & 0x7f);
    d9 ^= (fi_key & 0x1ff);
    d9 = s9[d9] ^ d7;
    return ((d7 << 9) | d9);
}

void keyinit(unsigned char *inputkey, unsigned int *EK)
{
    int i;

    for (i = 0; i < 8; i++)
        EK[i] = (inputkey[i*2] * 256) + inputkey[i*2+1];

    for (i = 0; i < 8; i++) {
        EK[i+ 8] = FI(EK[i], EK[(i+1) % 8]);
        EK[i+16] = EK[i+8] & 0x1ff;
        EK[i+24] = EK[i+8] >> 9;
    }
}

unsigned int FO(unsigned int fo_in, int k)
{
    unsigned int t0, t1;

    t0 = fo_in >> 16;
    t1 = fo_in & 0xffff;
    t0 = t0 ^ EK[k];
    t0 = FI(t0, EK[((k+5)%8)+8]);
    t0 = t0 ^ t1;
    t1 = t1 ^ EK[(k+2)%8];
    t1 = FI(t1, EK[((k+1)%8)+8]);
    t1 = t1 ^ t0;
    t0 = t0 ^ EK[(k+7)%8];
    t0 = FI(t0, EK[((k+3)%8)+8]);
    t0 = t0 ^ t1;
    t1 = t1 ^ EK[(k+4)%8];
    return((t1 << 16) | t0);
}

unsigned int FL(unsigned int fl_in, int k)
{
    unsigned int d0, d1;

    d0 = fl_in >> 16;
    d1 = fl_in & 0xffff;
    if (k % 2 == 0) {
        d1 = d1 ^ (d0 & EK[k/2]);
        d0 = d0 ^ (d1 | EK[(((k/2)+6)%8)+8]);
    } else {
        d1 = d1 ^ (d0 & EK[((((k-1)/2)+2)%8)+8]);
        d0 = d0 ^ (d1 | EK[(((k-1)/2)+4)%8]);
    }

    return((d0 << 16) | d1);
}

unsigned int FLINV(unsigned int fl_in, int k)
{
    unsigned int d0, d1;

    d0 = fl_in >> 16;
    d1 = fl_in & 0xffff;
    if (k % 2 == 0) {
        d0 = d0 ^ (d1 | EK[(((k/2)+6)%8)+8]);
        d1 = d1 ^ (d0 & EK[k/2]);
    } else {
        d0 = d0 ^ (d1 | EK[(((k-1)/2)+4)%8]);
        d1 = d1 ^ (d0 & EK[((((k-1)/2)+2)%8)+8]);
    }

    return((d0 << 16) | d1);
}

void misty1_encrypt(unsigned int *expkey, unsigned char *ptext,
    unsigned char *ctext)
{
    unsigned int D0, D1;
    int i, j = 0;

    for (i = 0; i < 32; i++) EK[i] = expkey[i];

    D0 = D1 = 0;

    for (i = 0; i < 4; i++) {
        D0 = D0 << 8;
        D0 |= ptext[j++];
    }

    for (i = 0; i < 4; i++) {
        D1 = D1 << 8;
        D1 |= ptext[j++];
    }

    /* round 0 */
    D0 = FL(D0, 0);
    D1 = FL(D1, 1);
    D1 = D1 ^ FO(D0, 0);

    /* round 1 */
    D0 = D0 ^ FO(D1, 1);

    /* round 2 */
    D0 = FL(D0, 2);
    D1 = FL(D1, 3);
    D1 = D1 ^ FO(D0, 2);

    /* round 3 */
    D0 = D0 ^ FO(D1, 3);

    /* round 4 */
    D0 = FL(D0, 4);
    D1 = FL(D1, 5);
    D1 = D1 ^ FO(D0, 4);

    /* round 5 */
    D0 = D0 ^ FO(D1, 5);

    /* round 6 */
    D0 = FL(D0, 6);
    D1 = FL(D1, 7);
    D1 = D1 ^ FO(D0, 6);

    /* round 7 */
    D0 = D0 ^ FO(D1, 7);

    /* final */
    D0 = FL(D0, 8);
    D1 = FL(D1, 9);

    ctext[0] = (D1 >> 24) & 0xff;
    ctext[1] = (D1 >> 16) & 0xff;
    ctext[2] = (D1 >> 8) & 0xff;
    ctext[3] = D1 & 0xff;
    ctext[4] = (D0 >> 24) & 0xff;
    ctext[5] = (D0 >> 16) & 0xff;
    ctext[6] = (D0 >> 8) & 0xff;
    ctext[7] = D0 & 0xff;
}

void misty1_decrypt(unsigned int expkey[32], unsigned char *ctext,
    unsigned char *ptext)
{
    unsigned int D0, D1;
    int i, j = 0;

    for (i = 0; i < 32; i++) EK[i] = expkey[i];

    D0 = D1 = 0;

    for (i = 0; i < 4; i++) {
        D1 = D1 << 8;
        D1 |= ctext[j++];
    }

    for (i = 0; i < 4; i++) {
        D0 = D0 << 8;
        D0 |= ctext[j++];
    }

    D0 = FLINV(D0, 8);
    D1 = FLINV(D1, 9);
    D0 = D0 ^ FO(D1, 7);
    D1 = D1 ^ FO(D0, 6);
    D0 = FLINV(D0, 6);
    D1 = FLINV(D1, 7);
    D0 = D0 ^ FO(D1, 5);
    D1 = D1 ^ FO(D0, 4);
    D0 = FLINV(D0, 4);
    D1 = FLINV(D1, 5);
    D0 = D0 ^ FO(D1, 3);
    D1 = D1 ^ FO(D0, 2);
    D0 = FLINV(D0, 2);
    D1 = FLINV(D1, 3);
    D0 = D0 ^ FO(D1, 1);
    D1 = D1 ^ FO(D0, 0);
    D0 = FLINV(D0, 0);
    D1 = FLINV(D1, 1);

    ptext[0] = (D0 >> 24) & 0xff;
    ptext[1] = (D0 >> 16) & 0xff;
    ptext[2] = (D0 >> 8) & 0xff;
    ptext[3] = D0 & 0xff;
    ptext[4] = (D1 >> 24) & 0xff;
    ptext[5] = (D1 >> 16) & 0xff;
    ptext[6] = (D1 >> 8) & 0xff;
    ptext[7] = D1 & 0xff;
}

int main(void)
{
    /********************************
    old plaintext1 : 0123456789abcdef
    ciphertext1    : 8b1da5f56ab3d07c
    new plaintext1 : 0123456789abcdef

    old plaintext2 : fedcba9876543210
    ciphertext2    : 04b68240b13be95d
    new plaintext2 : fedcba9876543210
    *********************************/

    int i;

    static unsigned char plaintext1[8] = {
        0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef
    };

    static unsigned char plaintext2[8] = {
        0xfe,0xdc,0xba,0x98,0x76,0x54,0x32,0x10
    };

    static unsigned char key[16] = {
        0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,
        0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff
    };

    static unsigned char ciphertext1[8];
    static unsigned char ciphertext2[8];
    static unsigned char decryptedplaintext1[8];
    static unsigned char decryptedplaintext2[8];
    unsigned int expandedkey[32];

    keyinit(key, expandedkey);
    printf("old plaintext1 : ");
    for (i = 0; i < 8; i++) printf("%02x", plaintext1[i]);
    printf("\n");

    misty1_encrypt(expandedkey, plaintext1, ciphertext1);
    printf("ciphertext1    : ");
    for (i = 0; i < 8; i++) printf("%02x", ciphertext1[i]);
    printf("\n");

    misty1_decrypt(expandedkey, ciphertext1, decryptedplaintext1);
    printf("new plaintext1 : ");
    for (i = 0; i < 8; i++) printf("%02x", decryptedplaintext1[i]);
    printf("\n\n");

    printf("old plaintext2 : ");
    for (i = 0; i < 8; i++) printf("%02x", plaintext2[i]);
    printf("\n");

    misty1_encrypt(expandedkey, plaintext2, ciphertext2);
    printf("ciphertext2    : ");
    for (i = 0; i < 8; i++) printf("%02x", ciphertext2[i]);
    printf("\n");

    misty1_decrypt(expandedkey, ciphertext2, decryptedplaintext2);
    printf("new plaintext2 : ");
    for (i = 0; i < 8; i++) printf("%02x", decryptedplaintext2[i]);
    printf("\n");

    return 0;
}

