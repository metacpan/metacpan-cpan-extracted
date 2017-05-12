/*
* _cast5.c
* Implementation of the CAST5 cipher
*
* Copyright 2002-2004 by Bob Mathews
*
* This library is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*/

#include "cast5.h"

#define B0(x)  (((x) >> 24) & 0xff)
#define B1(x)  (((x) >> 16) & 0xff)
#define B2(x)  (((x) >>  8) & 0xff)
#define B3(x)  ( (x)        & 0xff)

#ifdef GCC_X86
#define ROL(x,y)  asm("rol %1,%0" : "=r" (x) : "c" ((U8)y), "0" (x))
#else
#define ROL(x,y)  ( (x) = ((x) << (y)) | (((x) & 0xffffffffuL) >> (32-(y))) )
#endif

#define CAST5_STEP1(Km, Kr, I, L, R)  \
    I = Km + R; ROL(I, Kr);  \
    L ^= ((S1[B0(I)] ^ S2[B1(I)]) - S3[B2(I)]) + S4[B3(I)];

#define CAST5_STEP2(Km, Kr, I, L, R)  \
    I = Km ^ R; ROL(I, Kr);  \
    L ^= ((S1[B0(I)] - S2[B1(I)]) + S3[B2(I)]) ^ S4[B3(I)];

#define CAST5_STEP3(Km, Kr, I, L, R)  \
    I = Km - R; ROL(I, Kr);  \
    L ^= ((S1[B0(I)] + S2[B1(I)]) ^ S3[B2(I)]) - S4[B3(I)];

#define CHAR_TO_WORD(c)  ( (((U32) (c)[0] & 0xff) << 24) |  \
                           (((U32) (c)[1] & 0xff) << 16) |  \
                           (((U32) (c)[2] & 0xff) <<  8) |  \
                            ((U32) (c)[3] & 0xff) )

#define WORD_TO_CHAR(w,c)  ( (c)[0] = B0(w), (c)[1] = B1(w),  \
                             (c)[2] = B2(w), (c)[3] = B3(w) )

void cast5_init(struct cast5_state *cast5, char *key, int keylen)
{
  int i;
  U32 a, b, c, d, e;
  /* use volatile so compiler won't optimize away the key clear */
  volatile char padded[16];

  cast5->rounds = (keylen <= 10) ? 12 : 16;

  if (keylen >= 16) {
    a = CHAR_TO_WORD(key);
    b = CHAR_TO_WORD(key+4);
    c = CHAR_TO_WORD(key+8);
    d = CHAR_TO_WORD(key+12);
  }
  else {
    for (i = 0; i < keylen; i++) padded[i] = key[i];
    for (; i < 16; i++) padded[i] = 0;
    a = CHAR_TO_WORD(padded);
    b = CHAR_TO_WORD(padded+4);
    c = CHAR_TO_WORD(padded+8);
    d = CHAR_TO_WORD(padded+12);
    for (i = 0; i < 16; i++) padded[i] = 0;
  }

  e = c;
  a ^= S5[B1(d)] ^ S6[B3(d)] ^ S7[B0(d)] ^ S8[B2(d)] ^ S7[B0(e)];
  c ^= S5[B0(a)] ^ S6[B2(a)] ^ S7[B1(a)] ^ S8[B3(a)] ^ S8[B2(e)];
  d ^= S5[B3(c)] ^ S6[B2(c)] ^ S7[B1(c)] ^ S8[B0(c)] ^ S5[B1(e)];
  b ^= S5[B2(d)] ^ S6[B1(d)] ^ S7[B3(d)] ^ S8[B0(d)] ^ S6[B3(e)];
  cast5->mask_key[0]=S5[B0(d)]^S6[B1(d)]^S7[B3(c)]^S8[B2(c)]^S5[B2(a)];
  cast5->mask_key[1]=S5[B2(d)]^S6[B3(d)]^S7[B1(c)]^S8[B0(c)]^S6[B2(c)];
  cast5->mask_key[2]=S5[B0(b)]^S6[B1(b)]^S7[B3(a)]^S8[B2(a)]^S7[B1(d)];
  cast5->mask_key[3]=S5[B2(b)]^S6[B3(b)]^S7[B1(a)]^S8[B0(a)]^S8[B0(b)];
  e = a;
  d ^= S5[B1(c)] ^ S6[B3(c)] ^ S7[B0(c)] ^ S8[B2(c)] ^ S7[B0(e)];
  a ^= S5[B0(d)] ^ S6[B2(d)] ^ S7[B1(d)] ^ S8[B3(d)] ^ S8[B2(e)];
  c ^= S5[B3(a)] ^ S6[B2(a)] ^ S7[B1(a)] ^ S8[B0(a)] ^ S5[B1(e)];
  b ^= S5[B2(c)] ^ S6[B1(c)] ^ S7[B3(c)] ^ S8[B0(c)] ^ S6[B3(e)];
  cast5->mask_key[4]=S5[B3(d)]^S6[B2(d)]^S7[B0(b)]^S8[B1(b)]^S5[B0(c)];
  cast5->mask_key[5]=S5[B1(d)]^S6[B0(d)]^S7[B2(b)]^S8[B3(b)]^S6[B1(b)];
  cast5->mask_key[6]=S5[B3(a)]^S6[B2(a)]^S7[B0(c)]^S8[B1(c)]^S7[B3(d)];
  cast5->mask_key[7]=S5[B1(a)]^S6[B0(a)]^S7[B2(c)]^S8[B3(c)]^S8[B3(a)];
  e = c;
  d ^= S5[B1(b)] ^ S6[B3(b)] ^ S7[B0(b)] ^ S8[B2(b)] ^ S7[B0(e)];
  c ^= S5[B0(d)] ^ S6[B2(d)] ^ S7[B1(d)] ^ S8[B3(d)] ^ S8[B2(e)];
  b ^= S5[B3(c)] ^ S6[B2(c)] ^ S7[B1(c)] ^ S8[B0(c)] ^ S5[B1(e)];
  a ^= S5[B2(b)] ^ S6[B1(b)] ^ S7[B3(b)] ^ S8[B0(b)] ^ S6[B3(e)];
  cast5->mask_key[8] =S5[B3(d)]^S6[B2(d)]^S7[B0(a)]^S8[B1(a)]^S5[B1(b)];
  cast5->mask_key[9] =S5[B1(d)]^S6[B0(d)]^S7[B2(a)]^S8[B3(a)]^S6[B0(a)];
  cast5->mask_key[10]=S5[B3(c)]^S6[B2(c)]^S7[B0(b)]^S8[B1(b)]^S7[B2(d)];
  cast5->mask_key[11]=S5[B1(c)]^S6[B0(c)]^S7[B2(b)]^S8[B3(b)]^S8[B2(c)];
  e = d;
  b ^= S5[B1(c)] ^ S6[B3(c)] ^ S7[B0(c)] ^ S8[B2(c)] ^ S7[B0(e)];
  d ^= S5[B0(b)] ^ S6[B2(b)] ^ S7[B1(b)] ^ S8[B3(b)] ^ S8[B2(e)];
  c ^= S5[B3(d)] ^ S6[B2(d)] ^ S7[B1(d)] ^ S8[B0(d)] ^ S5[B1(e)];
  a ^= S5[B2(c)] ^ S6[B1(c)] ^ S7[B3(c)] ^ S8[B0(c)] ^ S6[B3(e)];
  cast5->mask_key[12]=S5[B0(c)]^S6[B1(c)]^S7[B3(d)]^S8[B2(d)]^S5[B3(b)];
  cast5->mask_key[13]=S5[B2(c)]^S6[B3(c)]^S7[B1(d)]^S8[B0(d)]^S6[B3(d)];
  cast5->mask_key[14]=S5[B0(a)]^S6[B1(a)]^S7[B3(b)]^S8[B2(b)]^S7[B0(c)];
  cast5->mask_key[15]=S5[B2(a)]^S6[B3(a)]^S7[B1(b)]^S8[B0(b)]^S8[B1(a)];
  e = c;
  b ^= S5[B1(a)] ^ S6[B3(a)] ^ S7[B0(a)] ^ S8[B2(a)] ^ S7[B0(e)];
  c ^= S5[B0(b)] ^ S6[B2(b)] ^ S7[B1(b)] ^ S8[B3(b)] ^ S8[B2(e)];
  a ^= S5[B3(c)] ^ S6[B2(c)] ^ S7[B1(c)] ^ S8[B0(c)] ^ S5[B1(e)];
  d ^= S5[B2(a)] ^ S6[B1(a)] ^ S7[B3(a)] ^ S8[B0(a)] ^ S6[B3(e)];
  cast5->rot_key[0]=(S5[B0(a)]^S6[B1(a)]^S7[B3(c)]^S8[B2(c)]^S5[B2(b)])&31;
  cast5->rot_key[1]=(S5[B2(a)]^S6[B3(a)]^S7[B1(c)]^S8[B0(c)]^S6[B2(c)])&31;
  cast5->rot_key[2]=(S5[B0(d)]^S6[B1(d)]^S7[B3(b)]^S8[B2(b)]^S7[B1(a)])&31;
  cast5->rot_key[3]=(S5[B2(d)]^S6[B3(d)]^S7[B1(b)]^S8[B0(b)]^S8[B0(d)])&31;
  e = b;
  a ^= S5[B1(c)] ^ S6[B3(c)] ^ S7[B0(c)] ^ S8[B2(c)] ^ S7[B0(e)];
  b ^= S5[B0(a)] ^ S6[B2(a)] ^ S7[B1(a)] ^ S8[B3(a)] ^ S8[B2(e)];
  c ^= S5[B3(b)] ^ S6[B2(b)] ^ S7[B1(b)] ^ S8[B0(b)] ^ S5[B1(e)];
  d ^= S5[B2(c)] ^ S6[B1(c)] ^ S7[B3(c)] ^ S8[B0(c)] ^ S6[B3(e)];
  cast5->rot_key[4]=(S5[B3(a)]^S6[B2(a)]^S7[B0(d)]^S8[B1(d)]^S5[B0(c)])&31;
  cast5->rot_key[5]=(S5[B1(a)]^S6[B0(a)]^S7[B2(d)]^S8[B3(d)]^S6[B1(d)])&31;
  cast5->rot_key[6]=(S5[B3(b)]^S6[B2(b)]^S7[B0(c)]^S8[B1(c)]^S7[B3(a)])&31;
  cast5->rot_key[7]=(S5[B1(b)]^S6[B0(b)]^S7[B2(c)]^S8[B3(c)]^S8[B3(b)])&31;
  e = c;
  a ^= S5[B1(d)] ^ S6[B3(d)] ^ S7[B0(d)] ^ S8[B2(d)] ^ S7[B0(e)];
  c ^= S5[B0(a)] ^ S6[B2(a)] ^ S7[B1(a)] ^ S8[B3(a)] ^ S8[B2(e)];
  d ^= S5[B3(c)] ^ S6[B2(c)] ^ S7[B1(c)] ^ S8[B0(c)] ^ S5[B1(e)];
  b ^= S5[B2(d)] ^ S6[B1(d)] ^ S7[B3(d)] ^ S8[B0(d)] ^ S6[B3(e)];
  cast5->rot_key[8] =(S5[B3(a)]^S6[B2(a)]^S7[B0(b)]^S8[B1(b)]^S5[B1(d)])&31;
  cast5->rot_key[9] =(S5[B1(a)]^S6[B0(a)]^S7[B2(b)]^S8[B3(b)]^S6[B0(b)])&31;
  cast5->rot_key[10]=(S5[B3(c)]^S6[B2(c)]^S7[B0(d)]^S8[B1(d)]^S7[B2(a)])&31;
  cast5->rot_key[11]=(S5[B1(c)]^S6[B0(c)]^S7[B2(d)]^S8[B3(d)]^S8[B2(c)])&31;
  e = a;
  d ^= S5[B1(c)] ^ S6[B3(c)] ^ S7[B0(c)] ^ S8[B2(c)] ^ S7[B0(e)];
  a ^= S5[B0(d)] ^ S6[B2(d)] ^ S7[B1(d)] ^ S8[B3(d)] ^ S8[B2(e)];
  c ^= S5[B3(a)] ^ S6[B2(a)] ^ S7[B1(a)] ^ S8[B0(a)] ^ S5[B1(e)];
  b ^= S5[B2(c)] ^ S6[B1(c)] ^ S7[B3(c)] ^ S8[B0(c)] ^ S6[B3(e)];
  cast5->rot_key[12]=(S5[B0(c)]^S6[B1(c)]^S7[B3(a)]^S8[B2(a)]^S5[B3(d)])&31;
  cast5->rot_key[13]=(S5[B2(c)]^S6[B3(c)]^S7[B1(a)]^S8[B0(a)]^S6[B3(a)])&31;
  cast5->rot_key[14]=(S5[B0(b)]^S6[B1(b)]^S7[B3(d)]^S8[B2(d)]^S7[B0(c)])&31;
  cast5->rot_key[15]=(S5[B2(b)]^S6[B3(b)]^S7[B1(d)]^S8[B0(d)]^S8[B1(b)])&31;
} /* cast5_init */

void cast5_encrypt(struct cast5_state *cast5, char *in, char *out)
{
  U32 tmp, left, right;
  left  = CHAR_TO_WORD(in);
  right = CHAR_TO_WORD(in+4);

  CAST5_STEP1(cast5->mask_key[0],  cast5->rot_key[0],  tmp, left, right);
  CAST5_STEP2(cast5->mask_key[1],  cast5->rot_key[1],  tmp, right, left);
  CAST5_STEP3(cast5->mask_key[2],  cast5->rot_key[2],  tmp, left, right);
  CAST5_STEP1(cast5->mask_key[3],  cast5->rot_key[3],  tmp, right, left);
  CAST5_STEP2(cast5->mask_key[4],  cast5->rot_key[4],  tmp, left, right);
  CAST5_STEP3(cast5->mask_key[5],  cast5->rot_key[5],  tmp, right, left);
  CAST5_STEP1(cast5->mask_key[6],  cast5->rot_key[6],  tmp, left, right);
  CAST5_STEP2(cast5->mask_key[7],  cast5->rot_key[7],  tmp, right, left);
  CAST5_STEP3(cast5->mask_key[8],  cast5->rot_key[8],  tmp, left, right);
  CAST5_STEP1(cast5->mask_key[9],  cast5->rot_key[9],  tmp, right, left);
  CAST5_STEP2(cast5->mask_key[10], cast5->rot_key[10], tmp, left, right);
  CAST5_STEP3(cast5->mask_key[11], cast5->rot_key[11], tmp, right, left);
  if (cast5->rounds == 16) {
    CAST5_STEP1(cast5->mask_key[12], cast5->rot_key[12], tmp, left, right);
    CAST5_STEP2(cast5->mask_key[13], cast5->rot_key[13], tmp, right, left);
    CAST5_STEP3(cast5->mask_key[14], cast5->rot_key[14], tmp, left, right);
    CAST5_STEP1(cast5->mask_key[15], cast5->rot_key[15], tmp, right, left);
  }

  WORD_TO_CHAR(right, out);
  WORD_TO_CHAR(left,  out+4);
} /* cast5_encrypt */

void cast5_decrypt(struct cast5_state *cast5, char *in, char *out)
{
  U32 tmp, left, right;
  right = CHAR_TO_WORD(in);
  left  = CHAR_TO_WORD(in+4);

  if (cast5->rounds == 16) {
    CAST5_STEP1(cast5->mask_key[15], cast5->rot_key[15], tmp, right, left);
    CAST5_STEP3(cast5->mask_key[14], cast5->rot_key[14], tmp, left, right);
    CAST5_STEP2(cast5->mask_key[13], cast5->rot_key[13], tmp, right, left);
    CAST5_STEP1(cast5->mask_key[12], cast5->rot_key[12], tmp, left, right);
  }
  CAST5_STEP3(cast5->mask_key[11], cast5->rot_key[11], tmp, right, left);
  CAST5_STEP2(cast5->mask_key[10], cast5->rot_key[10], tmp, left, right);
  CAST5_STEP1(cast5->mask_key[9],  cast5->rot_key[9],  tmp, right, left);
  CAST5_STEP3(cast5->mask_key[8],  cast5->rot_key[8],  tmp, left, right);
  CAST5_STEP2(cast5->mask_key[7],  cast5->rot_key[7],  tmp, right, left);
  CAST5_STEP1(cast5->mask_key[6],  cast5->rot_key[6],  tmp, left, right);
  CAST5_STEP3(cast5->mask_key[5],  cast5->rot_key[5],  tmp, right, left);
  CAST5_STEP2(cast5->mask_key[4],  cast5->rot_key[4],  tmp, left, right);
  CAST5_STEP1(cast5->mask_key[3],  cast5->rot_key[3],  tmp, right, left);
  CAST5_STEP3(cast5->mask_key[2],  cast5->rot_key[2],  tmp, left, right);
  CAST5_STEP2(cast5->mask_key[1],  cast5->rot_key[1],  tmp, right, left);
  CAST5_STEP1(cast5->mask_key[0],  cast5->rot_key[0],  tmp, left, right);

  WORD_TO_CHAR(left,  out);
  WORD_TO_CHAR(right, out+4);
} /* cast5_decrypt */

/* end _cast5.c */
