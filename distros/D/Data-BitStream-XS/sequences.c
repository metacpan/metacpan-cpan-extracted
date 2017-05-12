#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <limits.h>
#include <math.h>

/********************  functions to support sequences  ********************/

#include "sequences.h"

static UV isqrt(UV n) {
  UV root;
#if BITS_PER_WORD == 32
  if (n >= W_CONST(4294836225)) return W_CONST(65535);
#else
  if (n >= W_CONST(18446744065119617025)) return W_CONST(4294967295);
#endif
  root = (UV) sqrt((double)n);
  while (root*root > n)  root--;
  while ((root+1)*(root+1) <= n)  root++;
  return root;
}

unsigned char* sieve_erat30(WTYPE end);

/* Used for moving between primes */
static unsigned char nextwheel30[30] = {
    1,  7,  7,  7,  7,  7,  7, 11, 11, 11, 11, 13, 13, 17, 17,
   17, 17, 19, 19, 23, 23, 23, 23, 29, 29, 29, 29, 29, 29,  1 };
static unsigned char prevwheel30[30] = {
   29, 29,  1,  1,  1,  1,  1,  1,  7,  7,  7,  7, 11, 11, 13,
   13, 13, 13, 17, 17, 19, 19, 19, 19, 23, 23, 23, 23, 23, 23 };
/* The bit mask within a byte */
static unsigned char masktab30[30] = {
    0,  1,  0,  0,  0,  0,  0,  2,  0,  0,  0,  4,  0,  8,  0,
    0,  0, 16,  0, 32,  0,  0,  0, 64,  0,  0,  0,  0,  0,128  };
/* Add this to a number and you'll ensure you're on a wheel location */
static unsigned char distancewheel30[30] = {
    1,  0,  5,  4,  3,  2,  1,  0,  3,  2,  1,  0,  1,  0,  3,
    2,  1,  0,  1,  0,  3,  2,  1,  0,  5,  4,  3,  2,  1,  0 };
#if 0
static int is_prime_in_sieve(const unsigned char* sieve, WTYPE p) {
  WTYPE d = p/30;
  WTYPE m = p - d*30;
  /* If m isn't part of the wheel, we return 0 */
  return ( (masktab30[m] != 0) && ((sieve[d] & masktab30[m]) == 0) );
}
#endif
/* Warning -- can go off the end of the sieve */
static WTYPE next_prime_in_sieve(const unsigned char* sieve, WTYPE p) {
  WTYPE d, m;
  if (p < 7)
    return (p < 2) ? 2 : (p < 3) ? 3 : (p < 5) ? 5 : 7;
  d = p/30;
  m = p - d*30;
  do {
    if (m==29) { d++; m = 1; while (sieve[d] == 0xFF) d++; }
    else       { m = nextwheel30[m]; }
  } while (sieve[d] & masktab30[m]);
  return(d*30+m);
}
static WTYPE prev_prime_in_sieve(const unsigned char* sieve, WTYPE p) {
  WTYPE d, m;
  if (p <= 7)
    return (p <= 2) ? 0 : (p <= 3) ? 2 : (p <= 5) ? 3 : 5;
  d = p/30;
  m = p - d*30;
  do {
    m = prevwheel30[m];  if (m==29) { if (d == 0) return 0;  d--; }
  } while (sieve[d] & masktab30[m]);
  return(d*30+m);
}
/* Useful macros for the wheel-30 sieve array */
#define START_DO_FOR_EACH_SIEVE_PRIME(sieve, a, b) \
  { \
    WTYPE p = a; \
    WTYPE l_ = b; \
    WTYPE d_ = p/30; \
    WTYPE m_ = p-d_*30; \
    m_ += distancewheel30[m_]; \
    p = d_*30 + m_; \
    while ( p <= l_ ) { \
      if ((sieve[d_] & masktab30[m_]) == 0)

#define END_DO_FOR_EACH_SIEVE_PRIME \
      m_ = nextwheel30[m_];  if (m_ == 1) { d_++; } \
      p = d_*30+m_; \
    } \
  }



#if 0
static __inline__ uint64_t rdtsc(void)
{
     unsigned a, d; 
     asm volatile("rdtsc" : "=a" (a), "=d" (d)); 
     return ((uint64_t)a) | (((uint64_t)d) << 32); 
}
/* uint64_t ts = rdtsc();  ....  te = tdtsc();  tot += te-ts; */
#endif

/********************  primes  ********************/

/* GCC 3.4 - 4.1 has broken 64-bit popcount.
 * GCC 4.2+ can generate awful code when it doesn't have asm (GCC bug 36041).
 * When the asm is present (e.g. compile with -march=native on a platform that
 * has them, like Nahelem+), then it is almost as fast as the direct asm. */
#if BITS_PER_WORD == 64
 #if defined(__POPCNT__) && defined(__GNUC__) && (__GNUC__> 4 || (__GNUC__== 4 && __GNUC_MINOR__> 1))
   #define popcnt(b)  __builtin_popcountll(b)
 #else
   static UV popcnt(UV b) {
     b -= (b >> 1) & 0x5555555555555555;
     b = (b & 0x3333333333333333) + ((b >> 2) & 0x3333333333333333);
     b = (b + (b >> 4)) & 0x0f0f0f0f0f0f0f0f;
     return (b * 0x0101010101010101) >> 56;
   }
 #endif
#endif

#if defined(__GNUC__)
 #define word_unaligned(m,wordsize)  ((uintptr_t)m & (wordsize-1))
#else  /* uintptr_t is part of C99 */
 #define word_unaligned(m,wordsize)  ((unsigned int)m & (wordsize-1))
#endif

static const unsigned char byte_zeros[256] =
  {8,7,7,6,7,6,6,5,7,6,6,5,6,5,5,4,7,6,6,5,6,5,5,4,6,5,5,4,5,4,4,3,
   7,6,6,5,6,5,5,4,6,5,5,4,5,4,4,3,6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2,
   7,6,6,5,6,5,5,4,6,5,5,4,5,4,4,3,6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2,
   6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2,5,4,4,3,4,3,3,2,4,3,3,2,3,2,2,1,
   7,6,6,5,6,5,5,4,6,5,5,4,5,4,4,3,6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2,
   6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2,5,4,4,3,4,3,3,2,4,3,3,2,3,2,2,1,
   6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2,5,4,4,3,4,3,3,2,4,3,3,2,3,2,2,1,
   5,4,4,3,4,3,3,2,4,3,3,2,3,2,2,1,4,3,3,2,3,2,2,1,3,2,2,1,2,1,1,0};
static WTYPE count_zero_bits(const unsigned char* m, WTYPE nbytes)
{
  WTYPE count = 0;
#if BITS_PER_WORD == 64
  if (nbytes >= 16) {
    while ( word_unaligned(m,sizeof(UV)) && nbytes--)
      count += byte_zeros[*m++];
    if (nbytes >= 8) {
      UV* wordptr = (UV*)m;
      UV nwords = nbytes / 8;
      UV nzeros = nwords * 64;
      m += nwords * 8;
      nbytes %= 8;
      while (nwords--)
        nzeros -= popcnt(*wordptr++);
      count += nzeros;
    }
  }
#endif
  while (nbytes--)
    count += byte_zeros[*m++];
  return count;
}


static unsigned char* prime_cache_sieve = 0;
static WTYPE  prime_cache_size = 0;

/*
 * Get the size and a pointer to the cached prime sieve.
 * Returns the maximum sieved value in the sieve.
 * Allocates and sieves if needed.
 *
 * The sieve holds 30 numbers per byte, using a mod-30 wheel.
 */
static WTYPE get_prime_cache(WTYPE n, const unsigned char** sieve)
{
  if (prime_cache_size < n) {

    if (prime_cache_sieve != 0)
      Safefree(prime_cache_sieve);
    prime_cache_size = 0;

    /* Sieve a bit more than asked, to mitigate thrashing */
    if (n < (W_FFFF-3840))
      n += 3840;
    /* TODO: testing near 2^32-1 */

    prime_cache_sieve = sieve_erat30(n);

    if (prime_cache_sieve != 0)
      prime_cache_size = n;
  }

  if (sieve != 0)
    *sieve = prime_cache_sieve;
  return prime_cache_size;
}



/* Marked bits for each n, indicating if the number is prime */
static const unsigned char prime_is_small[] =
  {0xac,0x28,0x8a,0xa0,0x20,0x8a,0x20,0x28,0x88,0x82,0x08,0x02,0xa2,0x28,0x02,
   0x80,0x08,0x0a,0xa0,0x20,0x88,0x20,0x28,0x80,0xa2,0x00,0x08,0x80,0x28,0x82,
   0x02,0x08,0x82,0xa0,0x20,0x0a,0x20,0x00,0x88,0x22,0x00,0x08,0x02,0x28,0x82,
   0x80,0x20,0x88,0x20,0x20,0x02,0x02,0x28,0x80,0x82,0x08,0x02,0xa2,0x08,0x80,
   0x80,0x08,0x88,0x20,0x00,0x0a,0x00,0x20,0x08,0x20,0x08,0x0a,0x02,0x08,0x82,
   0x82,0x20,0x0a,0x80,0x00,0x8a,0x20,0x28,0x00,0x22,0x08,0x08,0x20,0x20,0x80,
   0x80,0x20,0x88,0x80,0x20,0x02,0x22,0x00,0x08,0x20,0x00,0x0a,0xa0,0x28,0x80,
   0x00,0x20,0x8a,0x00,0x20,0x8a,0x00,0x00,0x88,0x80,0x00,0x02,0x22,0x08,0x02};
#define NPRIME_IS_SMALL (sizeof(prime_is_small)/sizeof(prime_is_small[0]))

int is_prime(WTYPE n)
{
  WTYPE d;
  unsigned char mtab;

  if ( n < (NPRIME_IS_SMALL*8))
    return ((prime_is_small[n/8] >> (n%8)) & 1);

  d = n/30;
  mtab = masktab30[ n - d*30 ];  /* Bitmask in mod30 wheel */
  if (mtab == 0) return 0;       /* Return 0 if a multiple of 2, 3, or 5 */

  if (n <= prime_cache_size)
    return ((prime_cache_sieve[d] & mtab) == 0);

  if (!(n%7) || !(n%11) || !(n%13) || !(n%17) || !(n%23) || !(n%29) || !(n%31))
    return 0;

  {
    UV limit = isqrt(n);
    UV i = 37;
    while (1) {   /* trial division, skipping multiples of 2/3/5 */
      if (i > limit) break;  if ((n % i) == 0) return 0;  i += 4;
      if (i > limit) break;  if ((n % i) == 0) return 0;  i += 2;
      if (i > limit) break;  if ((n % i) == 0) return 0;  i += 4;
      if (i > limit) break;  if ((n % i) == 0) return 0;  i += 2;
      if (i > limit) break;  if ((n % i) == 0) return 0;  i += 4;
      if (i > limit) break;  if ((n % i) == 0) return 0;  i += 6;
      if (i > limit) break;  if ((n % i) == 0) return 0;  i += 2;
      if (i > limit) break;  if ((n % i) == 0) return 0;  i += 6;
    }
  }

  return 1;
}


static const unsigned char prime_count_small[] =
  {0,0,1,2,2,3,3,4,4,4,4,5,5,6,6,6,6,7,7,8,8,8,8,9,9,9,9,9,9,10,10,
   11,11,11,11,11,11,12,12,12,12,13,13,14,14,14,14,15,15,15,15,15,15,
   16,16,16,16,16,16,17,17,18,18,18,18,18,18,19};
#define NPRIME_COUNT_SMALL  (sizeof(prime_count_small)/sizeof(prime_count_small[0]))

static const unsigned char primes_small[] =
  {0,2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71};
#define NPRIMES_SMALL (sizeof(primes_small)/sizeof(primes_small[0]))

/* The nth prime will be less than or equal to this number */
static UV nth_prime_upper(WTYPE n)
{
  double fn, flogn, flog2n, upper;
  if (n < NPRIMES_SMALL)
    return primes_small[n];
  fn     = (double) n;
  flogn  = log(n);
  flog2n = log(flogn);    /* Note distinction between log_2(n) and log^2(n) */

  if      (n >= 688383)    /* Dusart 2010 page 2 */
    upper = fn * (flogn + flog2n - 1.0 + ((flog2n-2.00)/flogn));
  else if (n >= 178974)    /* Dusart 2010 page 7 */
    upper = fn * (flogn + flog2n - 1.0 + ((flog2n-1.95)/flogn));
  else if (n >=  39017)    /* Dusart 1999 page 14 */
    upper = fn * (flogn + flog2n - 0.9484);
  else if (n >=     6)     /* Modified from Robin 1983 for 6-39016 _only_ */
    upper = fn * ( flogn  +  0.6000 * flog2n );
  else
    upper = fn * ( flogn + flog2n );

  /* Watch out for  overflow */
  if (upper >= (double)UV_MAX) {
#if BITS_PER_WORD == 32
    if (n <= W_CONST(203280221)) return W_CONST(4294967291);
#else
    if (n <= W_CONST(425656284035217743)) return W_CONST(18446744073709551557);
#endif
    croak("nth_prime_upper(%"UVuf") overflow", n);
  }
  return (WTYPE) ceil(upper);
}

UV nth_prime(WTYPE n)
{
  const unsigned char* sieve;
  UV upper_limit, start, count, s, bytes_left;

  if (n < NPRIMES_SMALL)
    return primes_small[n];

  upper_limit = nth_prime_upper(n);
  if (upper_limit == 0) {
    croak("nth_prime(%lu) would overflow", (unsigned long)n);
    return 0;
  }
  /* The nth prime is guaranteed to be within this range */
  if (get_prime_cache(upper_limit, &sieve) < upper_limit) {
    croak("Couldn't generate sieve for nth(%lu) [sieve to %lu]", (unsigned long)n, (unsigned long)upper_limit);
    return 0;
  }

  count = 3;
  start = 7;
  s = 0;
  bytes_left = (n-count) / ((n<24000)?8:(n<3000000)?4:3);
  while ( bytes_left > 0 ) {
    /* There is at minimum one byte we can count (and probably many more) */
    count += count_zero_bits(sieve+s, bytes_left);
    assert(count <= n);
    s += bytes_left;
    bytes_left = (n-count) / 8;
  }
  if (s > 0)
    start = s * 30;

  START_DO_FOR_EACH_SIEVE_PRIME(sieve, start, upper_limit)
    if (++count == n)  return p;
  END_DO_FOR_EACH_SIEVE_PRIME;
  croak("nth_prime failed for %lu, not found in range %lu - %lu", (unsigned long)n, (unsigned long) start, (unsigned long)upper_limit);
  return 0;
}



void prime_init(WTYPE n)
{
  if ( (n == 0) && (prime_cache_sieve == 0) ) {
    /* On init, make a few primes (2-30k using 1k memory) */
    size_t initial_primes_to = 30 * (1024-8);
    prime_cache_sieve = sieve_erat30(initial_primes_to);
    if (prime_cache_sieve != 0)
      prime_cache_size = initial_primes_to;
    return;
  }

  get_prime_cache(n, 0);   /* Sieve to n */
}


UV prime_count(WTYPE n)
{
  const unsigned char* sieve;
  static WTYPE last_bytes = 0;
  static UV    last_count = 3;
  WTYPE s, bytes;
  UV count = 3;

  if (n < NPRIME_COUNT_SMALL)
    return prime_count_small[n];

  /* Get the cached sieve. */
  if (get_prime_cache(n, &sieve) < n) {
    croak("Couldn't generate sieve for prime_count");
    return 0;
  }

#if 0
  /* The really simple way -- walk the sieve */
  START_DO_FOR_EACH_SIEVE_PRIME(sieve, 7, n)
    count++;
  END_DO_FOR_EACH_SIEVE_PRIME;
#else
  bytes = n / 30;
  s = 0;

  /* Start from last word position if we can.  This is a big speedup when
   * calling prime_count many times with successively larger numbers. */
  if (bytes >= last_bytes) {
    s = last_bytes;
    count = last_count;
  }

  count += count_zero_bits(sieve+s, bytes-s);

  last_bytes = bytes;
  last_count = count;

  START_DO_FOR_EACH_SIEVE_PRIME(sieve, 30*bytes, n)
    count++;
  END_DO_FOR_EACH_SIEVE_PRIME;
#endif

  return count;
}

/* Crude way to get this for 7 or 11:

   perl -E 'my $n = "0" x 210; for ($s=7; $s<210; $s+=7) { substr($n,$s,1,"1"); } for $s (0..length($n)-1) { $b .= substr($n,$s,1) if $s%2 && $s%3 && $s%5 } say join ",", map { sprintf "0x%02x", oct("0b".reverse(substr($b,$_*8,8))); } 0..6'

   perl -E 'my $n = "0" x 2310; for ($s=7; $s<2310; $s+=7) { substr($n,$s,1,"1"); } for ($s=11; $s<2310; $s+=11) { substr($n,$s,1,"1"); } for $s (0..length($n)-1) { $b .= substr($n,$s,1) if $s%2 && $s%3 && $s%5 } say join ",", map { sprintf "0x%02x", oct("0b".reverse(substr($b,$_*8,8))); } 0..(7*11-1)'
*/


#define PRESIEVE_SIZE (7*11)
static const unsigned char presieve11[PRESIEVE_SIZE] =
{ 0x06,0x20,0x10,0x81,0x49,0x04,0xc2,0x02,0x28,0x10,0xa1,0x0c,0x04,0x50,0x02,0x61,0x10,0x83,0x08,0x0c,0x40,0x22,0x24,0x10,0x91,0x08,0x45,0x40,0x82,0x20,0x18,0x81,0x28,0x04,0x40,0x12,0x20,0x51,0x81,0x8a,0x04,0x48,0x02,0x20,0x14,0x81,0x18,0x04,0x41,0x02,0xa2,0x10,0x89,0x08,0x24,0x44,0x02,0x30,0x10,0xc1,0x08,0x86,0x40,0x0a,0x20,0x30,0x85,0x08,0x14,0x40,0x43,0x20,0x92,0x81,0x08,0x04,0x60 };

static void memtile(unsigned char* src, UV from, UV to) {
  while (from < to) {
    UV bytes = (2*from > to) ? to-from : from;
    memcpy(src+from, src, bytes);
    from += bytes;
  }
}

static UV sieve_prefill(unsigned char* mem, UV startd, UV endd)
{
  UV nbytes = endd - startd + 1;

  if (nbytes > 0) {
    memcpy(mem, presieve11, (nbytes < PRESIEVE_SIZE) ? nbytes : PRESIEVE_SIZE);
    memtile(mem, PRESIEVE_SIZE, nbytes);
    if (startd == 0) mem[0] = 0x01; /* Correct first byte */
  }
  return 13;
}

/* Wheel 30 sieve.  Ideas from Terje Mathisen and Quesada / Van Pelt. */
unsigned char* sieve_erat30(WTYPE end)
{
  unsigned char* mem;
  WTYPE max_buf, limit, prime;

  max_buf = (end/30) + ((end%30) != 0);
  /* Round up to a word */
  max_buf = ((max_buf + sizeof(UV) - 1) / sizeof(UV)) * sizeof(UV);
  New(0, mem, max_buf, unsigned char);

  /* Fill buffer marked with small primes 7+ */
  prime = sieve_prefill(mem, 0, max_buf-1);
  limit = isqrt(end);  /* prime*prime can overflow */
  for ( ; prime <= limit; prime = next_prime_in_sieve(mem,prime)) {
    WTYPE d = (prime*prime)/30;
    WTYPE m = (prime*prime) - d*30;
    WTYPE dinc = (2*prime)/30;
    WTYPE minc = (2*prime) - dinc*30;
    WTYPE wdinc[8];
    unsigned char wmask[8];
    int i;

    /* Find the positions of the next composites we will mark */
    for (i = 1; i <= 8; i++) {
      WTYPE dlast = d;
      do {
        d += dinc;
        m += minc;
        if (m >= 30) { d++; m -= 30; }
      } while ( masktab30[m] == 0 );
      wdinc[i-1] = d - dlast;
      wmask[i%8] = masktab30[m];
    }
    d -= prime;
#if 0
    assert(d == ((prime*prime)/30));
    assert(d < max_buf);
    assert(prime = (wdinc[0]+wdinc[1]+wdinc[2]+wdinc[3]+wdinc[4]+wdinc[5]+wdinc[6]+wdinc[7]));
#endif
    i = 0;        /* Mark the composites */
    do {
      mem[d] |= wmask[i];
      d += wdinc[i];
      i = (i+1) & 7;
    } while (d < max_buf);
  }

  return mem;
}


/********************  best pair (for Additive) ********************/

static int gamma_length(WTYPE n)
{
#if defined(__GNUC__) && (__GNUC__ >= 4 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 4))
  #if BITS_PER_WORD == 64
    WTYPE log2 = 63 - __builtin_clzll(n+1);
  #else
    WTYPE log2 = 31 - __builtin_clzl(n+1);
  #endif
#else
  WTYPE log2 = 0;
  while (n >= ((2 << log2)-1))  log2++;
#endif
  return ((2*log2)+1);
}

/* adder is used to modify the stored indices.  A function would be better. */
int find_best_pair(WTYPE* basis, int basislen, WTYPE val, int adder, int* a, int* b)
{
  int maxbasis;
  int bestlen = INT_MAX;
  int i, j;

  assert( (basis != 0) && (a != 0) && (b != 0) && (basislen >= 1) );
  /* Find how far in basis to look */
  if ((basislen > 15) && (val > basis[15])) {
    /* Binary search for large values */
    i = 0;
    j = basislen-1;
    while (i < j) {
      int mid = (i+j)/2;
      if (basis[mid] < val)   i = mid+1;
      else                    j = mid;
    }
    maxbasis = i-1;
  } else {
    /* Iteration for small values */
    maxbasis = 0;
    while ( ((maxbasis+1) < basislen) && (basis[maxbasis+1] < val) )
      maxbasis++;
  }
  assert(maxbasis < basislen);
  assert(basis[maxbasis] <= val);
  assert( ((maxbasis+1) == basislen) || (basis[maxbasis+1] >= val) );

  i = 0;
  j = maxbasis;
  while (i <= j) {
    WTYPE sum = basis[i] + basis[j];
    if (sum > val) {
      j--;
    } else {
      if (sum == val) {
        int p1 = i + adder;
        int p2 = j - i + adder;
        int glen = gamma_length(p1) + gamma_length(p2);
        /* printf("found %llu+%llu=%llu  pair %d,%d (%d,%d) with length %d\n", basis[i], basis[j], sum, i, j, p1, p2, glen); */
        if (glen < bestlen) {
          *a = p1;
          *b = p2;
          bestlen = glen;
        }
      }
      i++;
    }
  }
  return (bestlen < INT_MAX);
}

/* If you roll your own prev_prime and next_prime, you can make this
 * about 35% faster.  I decided it wasn't worth the obfuscation.  E.g.
 *
 *    if (i <= 3) { pim = pi = (i==1) ? 3 : (i==2) ? 5 : 7;
 *    } else { do { pim = nextwheel30[pim];  if (pim == 1) pid++;
 *                } while (sieve[pid] & masktab30[pim]);
 *             pi = pid*30+pim; }
 */

int find_best_prime_pair(WTYPE val, int adder, int* a, int* b)
{
  int bestlen = INT_MAX;
  int i, j;
  WTYPE pi, pj;
  const unsigned char* sieve;

  assert( (a != 0) && (b != 0) );

  if (get_prime_cache(val, &sieve) < val) {
    croak("Couldn't generate sieve for find_best_prime_pair");
    return 0;
  }

  pi = 1;
  pj = prev_prime_in_sieve(sieve,val+1);
  i = 0;
  j = (val <= 2) ? 1 : prime_count(pj)-1;
  while (i <= j) {
    WTYPE sum = pi + pj;
    if (sum > val) {
      j--;
      pj = (j == 0) ? 1 : prev_prime_in_sieve(sieve,pj);
    } else {
      if (sum == val) {
        int p1 = i + adder;
        int p2 = j - i + adder;
        int glen = gamma_length(p1) + gamma_length(p2);
        if (glen <= bestlen) { /* Prefer a smaller j */
          *a = p1;
          *b = p2;
          bestlen = glen;
        }
      }
      i++;
      pi = (i == 1) ? 3 : next_prime_in_sieve(sieve,pi);
    }
  }
  return (bestlen < INT_MAX);
}
