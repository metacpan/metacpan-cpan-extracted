#include <string.h>

#include "rmd160.h"
#include "wrap_160.h"

void RIPEMD160_init(Crypt__RIPEMD160 ripemd160)
{
  MDinit(ripemd160->MDbuf);
  ripemd160->local = (dword) 0;
  ripemd160->count_lo = (dword) 0;
  ripemd160->count_hi = (dword) 0;
}

void RIPEMD160_update(Crypt__RIPEMD160 ripemd160, byte *strptr, dword len)
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
      rmd160_compress(ripemd160->MDbuf, ripemd160->X);
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
    rmd160_compress(ripemd160->MDbuf, ripemd160->X);
  }
  memcpy(ripemd160->data, strptr, len);
  ripemd160->local = len;
}

void RIPEMD160_final(Crypt__RIPEMD160 ripemd160)
{
  MDfinish(ripemd160->MDbuf,
	   ripemd160->data,
	   (dword) ripemd160->count_lo,
	   (dword) ripemd160->count_hi);
}
