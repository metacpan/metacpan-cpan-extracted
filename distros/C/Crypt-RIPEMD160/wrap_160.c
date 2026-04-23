#include <string.h>

#include "rmd160.h"
#include "wrap_160.h"

/*
 * Indirect memset via a volatile function pointer.  The compiler
 * cannot prove that the pointer still equals memset at call time,
 * so it must emit the call even when the target memory is about to
 * go out of scope or be freed.
 */
static void *(* const volatile memset_ptr)(void *, int, size_t) = memset;

void secure_memzero(void *ptr, size_t len)
{
    (memset_ptr)(ptr, 0, len);
}

void RIPEMD160_init(Crypt__RIPEMD160 ripemd160)
{
  memset(ripemd160, 0, sizeof(RIPEMD160_INFO));
  MDinit(ripemd160->MDbuf);
}

void RIPEMD160_update(Crypt__RIPEMD160 ripemd160, const byte *strptr, dword len)
{
  dword i;
  dword X[16];

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
      for (i = 0; i < 16; i++)
        X[i] = BYTES_TO_DWORD(ripemd160->data + 4*i);
      rmd160_compress(ripemd160->MDbuf, X);
    } else {
      return;
    }
  }
  while (len >= RIPEMD160_BLOCKSIZE) {
    for (i = 0; i < 16; i++) {
      X[i] = BYTES_TO_DWORD(strptr);
      strptr += 4;
    }
    len -= RIPEMD160_BLOCKSIZE;
    rmd160_compress(ripemd160->MDbuf, X);
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
