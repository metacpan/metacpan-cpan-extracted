#include <string.h>
#include <stdio.h>

#include "rmd160.h"
#include "wrap_160.h"

#ifdef USE_RMD160CRYPT_HEADER
void RIPEMD160_init(Crypt__RIPEMD160 ripemd160)
#else
void RIPEMD160_init(RIPEMD160 ripemd160)
#endif
{
  MDinit(ripemd160->MDbuf);
  ripemd160->local = (dword) 0;
  ripemd160->count_lo = (dword) 0;
  ripemd160->count_hi = (dword) 0;
}

#ifdef USE_RMD160CRYPT_HEADER
void RIPEMD160_update(Crypt__RIPEMD160 ripemd160, byte *strptr, dword len)
#else
void RIPEMD160_update(RIPEMD160 ripemd160, byte *strptr, dword len)
#endif
{
  dword 
    i;
  byte *
    ptr;
  
  if (ripemd160->count_lo + len < ripemd160->count_lo) {
    ripemd160->count_hi++;
  }
  ripemd160->count_lo += len;
  
  if (ripemd160->local > 0) {
    i = RIPEMD160_BLOCKSIZE - ripemd160->local;
    if (i > len) {
      i = len;
    }
    memcpy(ripemd160->data + ripemd160->local, strptr, i);
    len -= i;
    strptr += i;
    ripemd160->local += i;
    if (ripemd160->local == RIPEMD160_BLOCKSIZE) {
      memset(ripemd160->X, 0, RIPEMD160_BLOCKSIZE);
      ptr = ripemd160->data;
      for (i=0; i<RIPEMD160_BLOCKSIZE; i++) {
	/* byte i goes into word X[i div 4] at pos.  8*(i mod 4)  */
	ripemd160->X[i>>2] |= (dword) *ptr++ << (8 * (i&3));
      }
      compress(ripemd160->MDbuf, ripemd160->X);
    } else {
      return;
    }
  }
  while (len >= RIPEMD160_BLOCKSIZE) {
    memset(ripemd160->X, 0, RIPEMD160_BLOCKSIZE);
    for (i=0; i<RIPEMD160_BLOCKSIZE; i++) {
      /* byte i goes into word X[i div 4] at pos.  8*(i mod 4)  */
      ripemd160->X[i>>2] |= (dword) *strptr++ << (8 * (i&3));
    }
    len -= RIPEMD160_BLOCKSIZE;
    compress(ripemd160->MDbuf, ripemd160->X);
  }
  memcpy(ripemd160->data, strptr, len);
  ripemd160->local = len;
}

#ifdef USE_RMD160CRYPT_HEADER
void RIPEMD160_final(Crypt__RIPEMD160 ripemd160)
#else
void RIPEMD160_final(RIPEMD160 ripemd160)
#endif
{
  if (ripemd160->local != ripemd160->count_lo % 64) {
    printf("local != count %% 64\n");
  }

  MDfinish(ripemd160->MDbuf,
	   ripemd160->data,
	   (dword) ripemd160->count_lo,
	   (dword) ripemd160->count_hi);
}

/* The HMAC_RIPEMD160 transform looks like:
   
   RIPEMD160(K XOR opad, RIPEMD160(K XOR ipad, text))
   
   where K is an n byte key
   ipad is the byte 0x36 repeated 64 times
   opad is the byte 0x5c repeated 64 times
   and text is the data being protected 
*/

#ifdef USE_MALICIOUS_MAC
#ifdef USE_RMD160CRYPT_HEADER
void RIPEMD160_HMAC(Crypt__RIPEMD160 ripemd160,
		    byte *input,        /* pointer to data stream */
		    dword len,           /* length of data stream */
		    byte *key,   /* pointer to authentication key */
		    dword keylen) /* length of authentication key */
#else
void RIPEMD160_HMAC(RIPEMD160 ripemd160,
		    byte *input,        /* pointer to data stream */
		    dword len,           /* length of data stream */
		    byte *key,   /* pointer to authentication key */
		    dword keylen) /* length of authentication key */
#endif
{
  byte 
    k_ipad[65],  /* inner padding - key XORd with ipad */
    k_opad[65];  /* outer padding - key XORd with opad */
  byte 
    tk[RMD160_DIGESTSIZE]; 
  dword
    i;
  
  /* if key is longer than 64 bytes reset it to key=RIPEMD160(key) */
  if (keylen > 64) {
    RIPEMD160_INFO
      tctx;
    
    RIPEMD160_init(&tctx);
    RIPEMD160_update(&tctx, key, keylen);
    RIPEMD160_final(&tctx);
    
    key = tctx.MDbuf;
    keylen = RMD160_DIGESTSIZE;
  }
  
  /* start out by storing key in pads */
  memset(k_ipad, 0x36, sizeof(k_ipad));
  memset(k_opad, 0x5c, sizeof(k_opad));
  
  /* XOR key with ipad and opad values */
  for (i=0; i<keylen; i++) {
    k_ipad[i] ^= key[i];
    k_opad[i] ^= key[i];
  }
  
  /* perform inner RIPEMD-160 */
  RIPEMD160_init(ripemd160);                  /* init ripemd160 for 1st pass */
  RIPEMD160_update(ripemd160, k_ipad, 64);           /* start with inner pad */
  RIPEMD160_update(ripemd160, input, len);          /* then text of datagram */
  RIPEMD160_final(ripemd160);                          /* finish up 1st pass */
  memcpy(digest, ripemd160->MDbuf, RMD160_DIGESTSIZE);
  
  /* perform outer RIPEMD-160 */
  RIPEMD160_init(ripemd160);                  /* init ripemd160 for 2nd pass */
  RIPEMD160_update(ripemd160, k_opad, 64);           /* start with outer pad */
  RIPEMD160_update(ripemd160, digest, RMD160_DIGESTSIZE);
  RIPEMD160_final(ripemd160);                          /* finish up 2nd pass */
  memcpy(digest, ripemd160->MDbuf, RMD160_DIGESTSIZE);
  
  /* clean up secret keys */
  memset(k_ipad, 0x00, sizeof(k_ipad));
  memset(k_opad, 0x00, sizeof(k_opad));
}
#endif
/* ************************************************************************* */

/* #define MAINTEST */

#ifdef MAINTEST
#include <stdio.h>
#include <stdlib.h>

void print_hash(RIPEMD160 ripemd160)
{
  byte hashcode[RMDsize/8];
  int i;  

  for (i=0; i<RMDsize/8; i+=4) {
    hashcode[i]   =  ripemd160->MDbuf[i>>2];
    hashcode[i+1] = (ripemd160->MDbuf[i>>2] >>  8);
    hashcode[i+2] = (ripemd160->MDbuf[i>>2] >> 16);
    hashcode[i+3] = (ripemd160->MDbuf[i>>2] >> 24);
  }
  printf("hashcode: ");
  for (i=0; i<RMDsize/8; i++)
    printf("%02x", hashcode[i]);
  printf("\n");
}

int main (void) 
{
  RIPEMD160_INFO ripemd160_info;
  byte a[1000001];

  int i;  
  long L;

  RIPEMD160_init(&ripemd160_info);

  /*
    RIPEMD160_update(&ripemd160_info, (byte *) "a", (dword) strlen("a"));
    RIPEMD160_update(&ripemd160_info, (byte *) "b", (dword) strlen("b"));
    RIPEMD160_update(&ripemd160_info, (byte *) "c", (dword) strlen("c"));
  */

  /*
    memset(a, 'a', 1000000);
    a[1000000] = 0;
    RIPEMD160_update(&ripemd160_info, (byte *) a, (dword) 1000000);
  */

  
  for (L = 0; L<1000000; L++) { 
    RIPEMD160_update(&ripemd160_info, (byte *) "a", (dword) strlen("a")); 
  }
  
  /*
    for (i = 0; i<8; i++) { 
    RIPEMD160_update(&ripemd160_info_info, 
    (byte *) "1234567890", 
    (dword) strlen("1234567890")); 
    }
  */
  
  RIPEMD160_final(&ripemd160_info);

  print_hash(&ripemd160_info);
  
  return(0);
}
#endif
