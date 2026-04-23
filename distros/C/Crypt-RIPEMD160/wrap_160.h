#ifndef __WRAP_160_H_
#define __WRAP_160_H_

#include "rmd160.h"

/* Inputlength in bytes */
#define RIPEMD160_BLOCKSIZE 64

/* Outputlength in bit */
#define RMDsize 160

#ifndef RMD160_DIGESTSIZE
#define RMD160_DIGESTSIZE  20
#endif

typedef struct {
  dword MDbuf[RMDsize/32];       /* contains (A, B, C, D, E)   */
  dword count_lo, count_hi;      /* 64-bit byte count          */
  byte data[RIPEMD160_BLOCKSIZE]; /* unprocessed data */
  dword local;                   /* amount of unprocessed data */
} RIPEMD160_INFO;

typedef RIPEMD160_INFO *Crypt__RIPEMD160;

/* Function prototypes */
void RIPEMD160_init(Crypt__RIPEMD160 ripemd160);

void RIPEMD160_update(Crypt__RIPEMD160 ripemd160, const byte *strptr, dword len);

void RIPEMD160_final(Crypt__RIPEMD160 ripemd160);

/*
 * secure_memzero — zero memory that may contain sensitive data.
 *
 * Unlike plain memset, this is not subject to dead store elimination
 * by the compiler.  Used to scrub hash state and message buffers
 * before they go out of scope or are freed.
 */
void secure_memzero(void *ptr, size_t len);

#endif
