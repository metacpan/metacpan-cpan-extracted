#ifndef __WRAP_160_H_
#define __WRAP_160_H_

#include "rmd160.h"

/* Inputlength in bytes */
#define RIPEMD160_BLOCKSIZE 64

/* Outputlength in bit */
#define RMDsize 160

#ifndef RMD160_DIGESTSIZE
#define RMD160_DIGESTSIZE  20;
#endif

typedef struct {
  dword MDbuf[RMDsize/32];       /* contains (A, B, C, D, E)   */
  dword X[RIPEMD160_BLOCKSIZE/4]; /* current 16-word chunk      */
  dword count_lo, count_hi;      /* 64-bit byte count          */
  byte data[RIPEMD160_BLOCKSIZE]; /* unprocessed data */
  dword local;                   /* amount of unprocessed data */
} RIPEMD160_INFO;


#define USE_RMD160CRYPT_HEADER
#ifdef USE_RMD160CRYPT_HEADER
typedef RIPEMD160_INFO *Crypt__RIPEMD160;

/* Function prototypes */
void RIPEMD160_init(Crypt__RIPEMD160 ripemd160); 

void RIPEMD160_update(Crypt__RIPEMD160 ripemd160, byte *strptr, dword len);

void RIPEMD160_final(Crypt__RIPEMD160 ripemd160);

void RIPEMD160_HMAC(byte *input, dword len, byte *key, dword keylen, 
		    byte *digest);
#else /* USE_RMD160CRYPT_HEADER */
typedef RIPEMD160_INFO *Crypt__RIPEMD160;
typedef RIPEMD160_INFO *RIPEMD160; 

/* Function prototypes */
void RIPEMD160_init(RIPEMD160 ripemd160); 

void RIPEMD160_update(RIPEMD160 ripemd160, byte *strptr, dword len);

void RIPEMD160_final(RIPEMD160 ripemd160);

void RIPEMD160_HMAC(byte *input, dword len, byte *key, dword keylen, 
		    byte *digest);
#endif /* USE_RMD160CRYPT_HEADER */

#endif
