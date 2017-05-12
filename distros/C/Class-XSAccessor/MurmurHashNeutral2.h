/*-----------------------------------------------------------------------------
 * MurmurHashNeutral2, by Austin Appleby
 *
 * Same as MurmurHash2, but endian- and alignment-neutral.
 * Half the speed though, alas.
 */
 /* Code released into the public domain. */
 /* C-ification and adaption to perl.h by Steffen Mueller 2009-11-03 */

#include "perl.h"

#ifndef _MurmurHashNeutral2_h_
#define _MurmurHashNeutral2_h_

U32 CXSA_MurmurHashNeutral2(const void* key, STRLEN len, U32 _seed) {
  const unsigned int m = 0x5bd1e995;
  const int r = 24;

  unsigned int h = _seed ^ len;

  const unsigned char* data = (const unsigned char*)key;

  while(len >= 4) {
    unsigned int k;

    k  = data[0];
    k |= data[1] << 8;
    k |= data[2] << 16;
    k |= data[3] << 24;

    k *= m; 
    k ^= k >> r; 
    k *= m;

    h *= m;
    h ^= k;

    data += 4;
    len -= 4;
  }
  
  switch(len)  {
  case 3: h ^= data[2] << 16;
  case 2: h ^= data[1] << 8;
  case 1: h ^= data[0];
          h *= m;
  };

  h ^= h >> 13;
  h *= m;
  h ^= h >> 15;

  return (U32)h;
} 

#endif
