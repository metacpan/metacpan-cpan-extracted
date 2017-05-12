/*
* cast5.h
* Definitions for CAST5 cipher
*
* Copyright 2002-2004 by Bob Mathews
*
* This library is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>

typedef struct cast5_state {
  int rounds;
  U32 mask_key[16];
  int rot_key[16];
} *Crypt__CAST5;

extern const U32 cast5_s1[256];
extern const U32 cast5_s2[256];
extern const U32 cast5_s3[256];
extern const U32 cast5_s4[256];
extern const U32 cast5_s5[256];
extern const U32 cast5_s6[256];
extern const U32 cast5_s7[256];
extern const U32 cast5_s8[256];

#define S1  cast5_s1
#define S2  cast5_s2
#define S3  cast5_s3
#define S4  cast5_s4
#define S5  cast5_s5
#define S6  cast5_s6
#define S7  cast5_s7
#define S8  cast5_s8

void cast5_init(struct cast5_state *cast5, char *key, int keylen);
void cast5_encrypt(struct cast5_state *cast5, char *in, char *out);
void cast5_decrypt(struct cast5_state *cast5, char *in, char *out);

/* end cast5.h */
