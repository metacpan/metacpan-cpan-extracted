#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "fix_inline.h"
#include <stdlib.h>
#include <sys/types.h>

/* This is SipHash by Jean-Philippe Aumasson and Daniel J. Bernstein.
 * The authors claim it is relatively secure compared to the alternatives
 * and that performance wise it is a suitable hash for languages like Perl.
 * See:
 *
 * https://www.131002.net/siphash/
 *
 * This implementation seems to perform slightly slower than one-at-a-time for
 * short keys, but degrades slower for longer keys. Murmur Hash outperforms it
 * regardless of keys size.
 *
 * It is 64 bit only.
 */

/* Find best way to ROTL32/ROTL64 */
#ifndef ROTL64
#if defined(_MSC_VER)
  #include <stdlib.h>  /* Microsoft put _rotl declaration in here */
  #define ROTL64(x,r)  _rotl64(x,r)
#else
  /* gcc recognises this code and generates a rotate instruction for CPUs with one */
  #define ROTL64(x,r)  (((uint64_t)x << r) | ((uint64_t)x >> (64 - r)))
#endif
#endif

#ifndef U8TO64_LE
#define U8TO64_LE(p) \
  (((uint64_t)((p)[0])      ) | \
   ((uint64_t)((p)[1]) <<  8) | \
   ((uint64_t)((p)[2]) << 16) | \
   ((uint64_t)((p)[3]) << 24) | \
   ((uint64_t)((p)[4]) << 32) | \
   ((uint64_t)((p)[5]) << 40) | \
   ((uint64_t)((p)[6]) << 48) | \
   ((uint64_t)((p)[7]) << 56))
#endif

#define SIPROUND            \
  do {              \
    v0 += v1; v1=ROTL64(v1,13); v1 ^= v0; v0=ROTL64(v0,32); \
    v2 += v3; v3=ROTL64(v3,16); v3 ^= v2;     \
    v0 += v3; v3=ROTL64(v3,21); v3 ^= v0;     \
    v2 += v1; v1=ROTL64(v1,17); v1 ^= v2; v2=ROTL64(v2,32); \
  } while(0)

/* SipHash-2-4 */

PERL_STATIC_INLINE uint64_t
siphash_2_4_from_perl(const unsigned char *in, const STRLEN inlen)
{
  /* "somepseudorandomlygeneratedbytes" */
  uint64_t v0 = (uint64_t)(0x736f6d6570736575);
  uint64_t v1 = (uint64_t)(0x646f72616e646f6d);
  uint64_t v2 = (uint64_t)(0x6c7967656e657261);
  uint64_t v3 = (uint64_t)(0x7465646279746573);

  uint64_t b;
  uint64_t k0 = 0;
  uint64_t k1 = 0;
  uint64_t m;
  const int left = inlen & 7;
  const U8 *end = in + inlen - left;

  b = ( ( uint64_t )(inlen) ) << 56;
  v3 ^= k1;
  v2 ^= k0;
  v1 ^= k1;
  v0 ^= k0;

  for ( ; in != end; in += 8 )
  {
    m = U8TO64_LE( in );
    v3 ^= m;
    SIPROUND;
    SIPROUND;
    v0 ^= m;
  }

  switch( left )
  {
  case 7: b |= ( ( uint64_t )in[ 6] )  << 48;
  case 6: b |= ( ( uint64_t )in[ 5] )  << 40;
  case 5: b |= ( ( uint64_t )in[ 4] )  << 32;
  case 4: b |= ( ( uint64_t )in[ 3] )  << 24;
  case 3: b |= ( ( uint64_t )in[ 2] )  << 16;
  case 2: b |= ( ( uint64_t )in[ 1] )  <<  8;
  case 1: b |= ( ( uint64_t )in[ 0] ); break;
  case 0: break;
  }

  v3 ^= b;
  SIPROUND;
  SIPROUND;
  v0 ^= b;

  v2 ^= 0xff;
  SIPROUND;
  SIPROUND;
  SIPROUND;
  SIPROUND;
  b = v0 ^ v1 ^ v2  ^ v3;
  return b;
  /*return (U32)(b & U32_MAX);*/
}

int32_t
JumpConsistentHash(uint64_t key, int32_t num_buckets)
{
  int64_t b = 1;
  int64_t j = 0;

  while (j < num_buckets) {
    b = j;
    key = key * 2862933555777941757ULL + 1;
    j = (b + 1) * ((double)(1LL << 31) / (double)((key >> 33) + 1));
  }

  return b;
}


MODULE = Algorithm::ConsistentHash::JumpHash		PACKAGE = Algorithm::ConsistentHash::JumpHash
PROTOTYPES: DISABLE


int32_t
jumphash_numeric(uint64_t key, int32_t num_buckets)
  CODE:
    RETVAL = JumpConsistentHash(key, num_buckets);
  OUTPUT: RETVAL

int32_t
jumphash_siphash(SV *str, uint64_t num_buckets)
  CODE:
    {
      STRLEN len;
      /* FIXME */
      const char * strval = SvPVbyte(str, len);
      const uint64_t hashval = siphash_2_4_from_perl(strval, len);
      RETVAL = JumpConsistentHash(hashval, num_buckets);
    }
  OUTPUT: RETVAL

