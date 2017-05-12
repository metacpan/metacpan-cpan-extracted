#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <assert.h>
//#define MAXN  1000000000UL      /* 10^ 9   50847534*/
#define MAXN  10000000000UL   /* 10^10  455052511 */
//#define MAXN  100000000UL   /* 10^ 8    5761455*/

#define WTYPE unsigned long
#define BITS_PER_WORD (8 * sizeof(WTYPE))
#define MAXBIT        (BITS_PER_WORD-1)
#define NWORDS(bits)  ( ((bits)+BITS_PER_WORD-1) / BITS_PER_WORD )
#define NBYTES(bits)  ( ((bits)+8-1) / 8 )
#define W_CONST(c)  ((WTYPE)c##UL)
#define W_ZERO      W_CONST(0)
#define W_ONE       W_CONST(1)
#define W_FFFF      W_CONST(~0)

#define SET_ARRAY_BIT(ar,n) \
   ar[(n)/BITS_PER_WORD]  |=  (W_ONE << ((n)%BITS_PER_WORD))
#define XOR_ARRAY_BIT(ar,n) \
   ar[(n)/BITS_PER_WORD]  ^=  (W_ONE << ((n)%BITS_PER_WORD))
#define CLR_ARRAY_BIT(ar,n) \
   ar[(n)/BITS_PER_WORD]  &=  ~(W_ONE << ((n)%BITS_PER_WORD))
#define IS_SET_ARRAY_BIT(ar,n) \
   (ar[(n)/BITS_PER_WORD] & (W_ONE << ((n)%BITS_PER_WORD)) )

/* primes 2,3,5,7,11,13,17,19,23,29,31 as bits */
#define SMALL_PRIMES_MASK W_CONST(2693408940)
/* if (MOD235_MASK >> (n%30)) & 1, n is a multiple of 2, 3, or 5. */
#define MOD235_MASK       W_CONST(1601558397)

static int _is_prime7(WTYPE x)
{
  WTYPE q, i;
  /* Check for small primes */
  q = x/ 7;  if (q< 7) return 1;  if (x==(q* 7)) return 0;
  q = x/11;  if (q<11) return 1;  if (x==(q*11)) return 0;
  q = x/13;  if (q<13) return 1;  if (x==(q*13)) return 0;
  q = x/17;  if (q<17) return 1;  if (x==(q*17)) return 0;
  q = x/19;  if (q<19) return 1;  if (x==(q*19)) return 0;
  q = x/23;  if (q<23) return 1;  if (x==(q*23)) return 0;
  q = x/29;  if (q<29) return 1;  if (x==(q*29)) return 0;
  /* wheel factorization, mod-30 loop */
  i = 31;
  while (1) {
    q = x/i;  if (q<i) return 1;  if (x==(q*i)) return 0;   i += 6;
    q = x/i;  if (q<i) return 1;  if (x==(q*i)) return 0;   i += 4;
    q = x/i;  if (q<i) return 1;  if (x==(q*i)) return 0;   i += 2;
    q = x/i;  if (q<i) return 1;  if (x==(q*i)) return 0;   i += 4;
    q = x/i;  if (q<i) return 1;  if (x==(q*i)) return 0;   i += 2;
    q = x/i;  if (q<i) return 1;  if (x==(q*i)) return 0;   i += 4;
    q = x/i;  if (q<i) return 1;  if (x==(q*i)) return 0;   i += 6;
    q = x/i;  if (q<i) return 1;  if (x==(q*i)) return 0;   i += 2;
  }
  return 1;
}

static const long prime_next_small[] =
  {2,2,3,5,5,7,7,11,11,11,11,13,13,17,17,17,17,19,19,23,23,23,23,
   29,29,29,29,29,29,31,31,37,37,37,37,37,37,41,41,41,41,43,43,47,
   47,47,47,53,53,53,53,53,53,59,59,59,59,59,59,61,61,67,67,67,67,67,67,71};
#define NPRIME_NEXT_SMALL (sizeof(prime_next_small)/sizeof(prime_next_small[0]))
static WTYPE next_prime(WTYPE x)
{
  static const WTYPE L = 30;
  WTYPE k0, n;
  static const WTYPE indices[] = {1, 7, 11, 13, 17, 19, 23, 29};
  static const WTYPE M = 8;
  int index;

  if (x < NPRIME_NEXT_SMALL)
    return prime_next_small[x];

  x++;
  k0 = x/L;
  index = 0;   while ((x-k0*L) > indices[index])  index++;
  n = L*k0 + indices[index];
  while (!_is_prime7(n)) {
    if (++index == M) {  k0++; index = 0; }
    n = L*k0 + indices[index];
  }
  return n;
}


/*
 * Various sieves.
 * Timings for counting the first 10^10 (10B) primes, in seconds.
 * Pi(10^10) = 455,052,511
 *
 * Note:  These numbers are old -- Math::Prime::Util has much faster
 *        segment sieving now (faster than primegen), and the LMO prime
 *        count is ridiculously fast compared to sieving (it takes only
 *        a few milliseconds).
 *
 *     1.9  primesieve 3.6 (even faster with multiple threads)
 *     5.6  Tomás Oliveira e Silva's segmented sieve v2 (Sep 2010)
 *     6.6  primegen (optimized Sieve of Atkin)
 *    11.2  Tomás Oliveira e Silva's segmented sieve v1 (May 2003)
 *
 *    15.9  sieve_erat30        (my wheel 30 Erat)
 *    17.2  sieve_erat30tm      (Terje wheel 30)
 *    31.9  sieve_eratek        (Sorensen inspired)
 *    35.5  sieve_erat          (Simple Erat)
 *    35.5  sieve_erat23        (simple erat mod)
 *    33.4  sieve_atkin         (Praxis)
 *    72.8  sieve_atkin_2       (Fixup of naive)
 *    91.6  sieve_atkin_naive   (Wikipedia-like)
 *
 * Retested after ensuring machine was idle.  As expected, the segmented
 * sievers improve some, and the sievers that fill giant memory spaces
 * improve a lot when other memory traffic is removed.
 */



/*
 * Straightforward Sieve of Eratosthenes.
 *
 * Uses 1 bit per odd number.
 *
 * Time for Pi(10^10) = 54.6s
 */
static WTYPE* sieve_erat(WTYPE end)
{
  WTYPE* mem;
  size_t n, s;
  size_t last = (end+1)/2;

  mem = (WTYPE*) calloc( NWORDS(last), sizeof(WTYPE) );
  assert(mem != 0);

  // Tight:
  //    for (n = 3; (n*n) <= end; n = next_prime(n))
  //      for (s = n*n; s <= end; s += 2*n)
  //        SET_ARRAY_BIT(mem,s/2);
  n = 3;
  while ( (n*n) <= end) {
    for (s = n*n; s <= end; s += 2*n)
      SET_ARRAY_BIT(mem,s/2);
    // Could do:   n = next_prime(n)
    do { n += 2; } while (IS_SET_ARRAY_BIT(mem,n/2));
  }

  SET_ARRAY_BIT(mem, 1/2);  /* 1 is composite */
  return mem;
}

/*
 * Naive Wheel factoring based on algorithm Ek from Sorenson 1991
 *
 * Uses 1 bit per odd number.
 *
 * Note we're including initialization code that marks all 3,5 multiples.
 * If the caller didn't look at these, this could be skipped.
 *
 * Time for Pi(10^10) = 46.4s
 */
static WTYPE* sieve_eratek(WTYPE end)
{
  WTYPE* mem;
  size_t p, f, x;
  size_t last = (end+1)/2;
  static const WTYPE wheel[] = {1, 7, 11, 13, 17, 19, 23, 29};
  static const WTYPE W[] = {0,6,0,0,0,0,0,4,0,0,0,2,0,4,0,0,0,2,0,4,0,0,0,6,0,0,0,0,0,2,0};

  mem = (WTYPE*) calloc( NWORDS(last), sizeof(WTYPE) );
  assert(mem != 0);

  /* Mark all multiples of 3 and 5 as composite. */
  //for (p = 3*3; p <= end; p += 2*3) SET_ARRAY_BIT(mem,p/2);
  //for (p = 5*5; p <= end; p += 2*5) SET_ARRAY_BIT(mem,p/2);
  p = 9;
  while (p <= end) {
    SET_ARRAY_BIT(mem,p/2); p += 6; if (p > end) break;  // mark  9, p = 15
    SET_ARRAY_BIT(mem,p/2); p += 6; if (p > end) break;  // mark 15, p = 21
    SET_ARRAY_BIT(mem,p/2); p += 4; if (p > end) break;  // mark 21, p = 25
    SET_ARRAY_BIT(mem,p/2); p += 2; if (p > end) break;  // mark 25, p = 27
    SET_ARRAY_BIT(mem,p/2); p += 6; if (p > end) break;  // mark 27, p = 33
    SET_ARRAY_BIT(mem,p/2); p += 2; if (p > end) break;  // mark 33, p = 35
    SET_ARRAY_BIT(mem,p/2); p += 4;                      // mark 35, p = 39
  }

  p = 7;
  while ((p*p) <= end) {
    {
      size_t fidx = p%30;
      f = p;
      /* Here's the problem -- for each prime, we're walking the array from
       * start to finish 8 times.  The operation count is the same as the
       * faster wheel-30 sieves, but this is just horrible for the cache. */
      while (f < p+30) {
        for (x = p*f; x <= end; x += p*30)
          SET_ARRAY_BIT(mem,x/2);
        size_t move = W[fidx];
        f += move;  fidx += move;
        if (fidx > 30) fidx -= 30;
      }
    }
    //p = next_prime(p);
    do { p += 2; } while (IS_SET_ARRAY_BIT(mem,p/2));
  }

  SET_ARRAY_BIT(mem, 1/2);  /* 1 is composite */
  CLR_ARRAY_BIT(mem, 3/2);     /* 3 is prime */
  CLR_ARRAY_BIT(mem, 5/2);     /* 5 is prime */
  return mem;
}


/*
 * Straightforward Sieve of Eratosthenes, but skipping 3.
 *
 * Uses 1 bit per odd number.
 *
 * Time for Pi(10^10) = 48.5s
 */
static WTYPE* sieve_base23(WTYPE end)
{
  WTYPE* mem;
  size_t n, s;
  size_t last = (end+1)/2;

  mem = (WTYPE*) calloc( NWORDS(last), sizeof(WTYPE) );
  assert(mem != 0);

  SET_ARRAY_BIT(mem, 1/2);  /* 1 is composite */
  /* Mark all multiples of 3.  Could skip if callers know this. */
  for (n = 3*3; n <= end; n += 2*3) SET_ARRAY_BIT(mem,n/2);

  n = 5;
  while ( (n*n) <= end ) {
    if (!IS_SET_ARRAY_BIT(mem,n/2)) {
      for (s = n*n; s <= end; s += 2*n) {
        SET_ARRAY_BIT(mem,s/2);
      }
    }
    n += 2;
    if ( ((n*n) <= end) && (!IS_SET_ARRAY_BIT(mem,n/2)) ) {
      for (s = n*n; s <= end; s += 2*n) {
        SET_ARRAY_BIT(mem,s/2);
      }
    }
    n += 4;
  }
  return mem;
}




static unsigned char mask_tab[30] = {
    0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 4, 0, 8, 0,
    0, 0, 16, 0, 32, 0, 0, 0, 64, 0, 0, 0, 0, 0, 128 };

#define IS_SIEVE30_SET(n) \
   (mem[n/30] & mask_tab[n%30])

/* Proper wheel 30 sieve based on code from Terje Mathisen (1998) */

static unsigned char* sieve_erat30tm(WTYPE end)
{
  unsigned char* mem;
  size_t max_buf, buffer_words;
  WTYPE prime;

  max_buf = (end + 29) / 30;
  buffer_words = (end + (30*sizeof(WTYPE)) - 1) / (30*sizeof(WTYPE));
  mem = (unsigned char*) calloc( buffer_words, sizeof(WTYPE) );
  assert(mem != 0);

  for (prime =  7; (prime*prime) <= end; prime = next_prime(prime)) {
    WTYPE step = prime * 2;
    WTYPE curr = prime * prime;
    WTYPE dcurr = curr/30;
    WTYPE mcurr = curr - dcurr*30;
    WTYPE i;
    WTYPE dstep[30];
    WTYPE nextm[30];

    for (i = 1; i < 30; i += 2) {
      WTYPE d, m;
      WTYPE s = i;
      do {
        s += step;
        d = s/30;
        m = s - d*30;
      } while (mask_tab[m] == 0);
      dstep[i] = d;
      nextm[i] = m;
    }

    do {
      //if ((mem[dcurr] & mask_tab[mcurr]) == 0)
      mem[dcurr] |= mask_tab[mcurr];
      dcurr += dstep[mcurr];
      mcurr = nextm[mcurr];
    } while (dcurr < max_buf);
  }

  mem[0] |= mask_tab[1];  /* 1 is composite */

  return mem;
}

/* My wheel 30 sieve */

static unsigned char* sieve_erat30(WTYPE end)
{
  unsigned char* mem;
  size_t max_buf, buffer_words;
  WTYPE prime;

  max_buf = (end + 29) / 30;
  buffer_words = (end + (30*sizeof(WTYPE)) - 1) / (30*sizeof(WTYPE));
  mem = (unsigned char*) calloc( buffer_words, sizeof(WTYPE) );
  assert(mem != 0);

  /* Shortcut to mark 7.  Purely an optimization. */
  /* However, we could tweak a little by doing:
   *    - use malloc instead of calloc
   *    - use a loop of memcpy(len*2) to speed up vs. the 7-byte loop below
   *    - memset 0 between max_buf and buffer_words
   * If you take this one step further you can initialize a few more primes.
   * You may then discover Tomás Oliveira e Silva already did that in his
   * segmented siever (v2) where he constructs a pattern of 2/3/5/7/11/13
   * marks, and then initializes buckets from that (though he does a byte
   * copy instead of using memcpy).
   */
#if 1
  if ( (7*7) <= end ) {
    WTYPE d = 1;
    while ( (d+6) < max_buf) {
      mem[d+0] = 0x20;  mem[d+1] = 0x10;  mem[d+2] = 0x81;  mem[d+3] = 0x08;
      mem[d+4] = 0x04;  mem[d+5] = 0x40;  mem[d+6] = 0x02;  d += 7;
    }
    if ( d < max_buf )  mem[d++] = 0x20;
    if ( d < max_buf )  mem[d++] = 0x10;
    if ( d < max_buf )  mem[d++] = 0x81;
    if ( d < max_buf )  mem[d++] = 0x08;
    if ( d < max_buf )  mem[d++] = 0x04;
    if ( d < max_buf )  mem[d++] = 0x40;
    //assert(d >= max_buf);
  }
#endif
  for (prime = 11; (prime*prime) <= end; prime = next_prime(prime)) {
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
      } while ( mask_tab[m] == 0 );
      wdinc[i-1] = d - dlast;
      wmask[i%8] = mask_tab[m];
    }
    d -= prime;
    //assert(d == ((prime*prime)/30));
    //assert(d < max_buf);
    //assert(prime = (wdinc[0]+wdinc[1]+wdinc[2]+wdinc[3]+wdinc[4]+wdinc[5]+wdinc[6]+wdinc[7]));
    /* Mark them */
    i = 0;
    do {
      mem[d] |= wmask[i];
      d += wdinc[i];
      i = (i+1) & 7;
    } while (d < max_buf);
  }

  mem[0] |= mask_tab[1];  /* 1 is composite */

  return mem;
}

/*
 * Naive Sieve of Atkin.
 *
 * Uses 1 bit per odd number.
 *
 * This is really slow.  Just keeping it here as a reference.
 *
 * Time for Pi(10^10) = 123.5s
 */
static WTYPE* sieve_atkin_naive(WTYPE end)
{
  WTYPE* mem;
  size_t x, y, n, sqlimit;
  size_t last = (end+1+1)/2;
  long loopend, y_limit, dn;

  end++;
  mem = (WTYPE*) malloc( NWORDS(last) * sizeof(WTYPE) );
  assert(mem != 0);
  /* mark everything as a composite */
  memset(mem, 0xFF, NBYTES(last));

  sqlimit = sqrt(end);
  for (x = 1; x <= sqlimit; x++) {
    for (y = 1; y <= sqlimit; y++) {
      n = 4*x*x + y*y;
      if ( (n <= end) && (n % 12 == 1 || n % 12 == 5) )
        XOR_ARRAY_BIT(mem,n/2);

      n = 3*x*x + y*y;
      if ( (n <= end) && (n % 12 == 7) )
        XOR_ARRAY_BIT(mem,n/2);

      n = 3*x*x - y*y;
      if ( (n <= end) && (x > y) && (n % 12 == 11) )
        XOR_ARRAY_BIT(mem,n/2);
    }
  }

  /* Mark all squares of primes as composite */
  for (n = 5; n <= sqlimit; n += 2)
    if (!IS_SET_ARRAY_BIT(mem,n/2))
      for (y = n*n; y <= end; y += 2*n*n)
        SET_ARRAY_BIT(mem,y/2);

  CLR_ARRAY_BIT(mem, 3/2);     /* 3 is prime */

  return mem;
}

/*
 * Better Sieve of Atkin.
 *
 * Uses 1 bit per odd number.
 *
 * Just some simple optimizations to make it a little better.  Still not good.
 *
 * Time for Pi(10^10) = 97.2s
 */
static WTYPE* sieve_atkin_2(WTYPE end)
{
  WTYPE* mem;
  size_t x, y, n, sqlimit;
  size_t last = (end+1+1)/2;
  long loopend, y_limit, dn;

  end++;
  mem = (WTYPE*) malloc( NWORDS(last) * sizeof(WTYPE) );
  assert(mem != 0);
  /* mark everything as a composite */
  memset(mem, 0xFF, NBYTES(last));

  sqlimit = sqrtf(end);
  for (x = 1; x <= sqlimit; x++) {
    {
      size_t xx4 = 4*x*x;
      y = 1;
      for (n = xx4+1; n <= end; n = xx4+y*y) {
        size_t nmod12 = n%12;
        if ( (nmod12 == 1) || (nmod12 == 5) )
          XOR_ARRAY_BIT(mem,n/2);
        y++;
      }
    }
    {
      size_t xx3 = 3*x*x;
      y = 1;
      for (n = xx3+1; n <= end; n = xx3+y*y) {
        size_t nmod12 = n%12;
        if (nmod12 == 7)
          XOR_ARRAY_BIT(mem,n/2);
        y++;
      }

      y = x-1;
      while ( y*y >= xx3 )
        y--;
      for (n = xx3-y*y; y >= 1 && n <= end; n = xx3-y*y) {
        size_t nmod12 = n%12;
        if (nmod12 == 11)
          XOR_ARRAY_BIT(mem,n/2);
        y--;
      }
    }
  }

  /* Mark all squares of primes as composite */
  for (n = 5; n <= sqlimit; n += 2)
    if (!IS_SET_ARRAY_BIT(mem,n/2))
      for (y = n*n; y <= end; y += 2*n*n)
        SET_ARRAY_BIT(mem,y/2);

  CLR_ARRAY_BIT(mem, 3/2);     /* 3 is prime */

  return mem;
}


/*
 * Better Sieve of Atkin.
 *
 * Uses 1 bit per odd number.
 *
 * From Mike on Programming Praxis.  Pretty fast, but not really an improvement
 * over a good SoE.  Note that the limits aren't handled quite right, so I have
 * to add an "if (n <= end)" in front of each XOR.
 *
 * Time for Pi(10^10) = 53.9s
 */
static WTYPE* sieve_atkin(WTYPE end)
{
  WTYPE* mem;
  size_t n, s, k;
  size_t last = (end+1)/2;     /* Extra space allocated */
  long loopend, y_limit, dn;

  end++;
  mem = (WTYPE*) malloc( NWORDS(last) * sizeof(WTYPE) );
  assert(mem != 0);
  /* mark everything as a composite */
  memset(mem, 0xFF, NBYTES(last));

  {
    long xx3 = 3;
    long dxx;
    loopend = 12 * (long) sqrtf((end-1)/3.0);
    for (dxx = 0; dxx < loopend; dxx += 24) {
      xx3 += dxx;
      y_limit = (long) (12.0*sqrtf( end - xx3 )) - 36;
      n = xx3 + 16;
      for (dn = -12; dn < (y_limit+1); dn += 72) {
        n += dn;
        if (n <= end) XOR_ARRAY_BIT(mem,n/2);
      }
      n = xx3 + 4;
      for (dn = 12; dn < (y_limit+1); dn += 72) {
        n += dn;
        if (n <= end) XOR_ARRAY_BIT(mem,n/2);
      }
    }
  }

  {
    long xx4 = 0;
    long dxx4;
    loopend = 8 * (long) sqrtf((end-1)/4.0) + 4;
    for (dxx4 = 4; dxx4 < loopend; dxx4 += 8) {
      xx4 += dxx4;
      n = xx4 + 1;
      if (xx4%3) {
        y_limit = 4 * (long)sqrtf( end - xx4 ) - 3;
        for (dn = 0; dn < y_limit; dn += 8) {
          n += dn;
          if (n <= end) XOR_ARRAY_BIT(mem,n/2);
        }
      } else {
        y_limit = 12 * (long)sqrtf( end - xx4 ) - 36;
        n = xx4 + 25;
        for (dn = -24; dn < (y_limit+1); dn += 72) {
          n += dn;
          if (n <= end) XOR_ARRAY_BIT(mem,n/2);
        }
        n = xx4 + 1;
        for (dn = 24; dn < (y_limit+1); dn += 72) {
          n += dn;
          if (n <= end) XOR_ARRAY_BIT(mem,n/2);
        }
      }
    }
  }

  {
    long xx = 1;
    long x;
    loopend = (long) sqrtf((float)end/2.0) + 1;
    for (x = 3; x < loopend; x += 2) {
      xx += 4*x - 4;
      n = 3*xx;
      if (n > end) {
        long min_y = (( (long) (sqrtf(n - end)) >>2)<<2);
        long yy = min_y * min_y;
        n -= yy;
        s = 4*min_y + 4;
      } else {
        s = 4;
      }
      for (dn = s; dn < 4*x; dn += 8) {
        n -= dn;
        if ((n <= end) && ((n%12) == 11))
          XOR_ARRAY_BIT(mem,n/2);
      }
    }

    xx = 0;
    loopend = (long) sqrtf((float)end/2.0) + 1;
    for (x = 2; x < loopend; x += 2) {
      xx += 4*x - 4;
      n = 3*xx;
      if (n > end) {
        long min_y = (( (long) (sqrtf(n - end)) >>2)<<2)-1;
        long yy = min_y * min_y;
        n -= yy;
        s = 4*min_y + 4;
      } else {
        n--;
        s = 0;
      }
      for (dn = s; dn < 4*x; dn += 8) {
        n -= dn;
        if ((n <= end) && ((n%12) == 11))
          XOR_ARRAY_BIT(mem,n/2);
      }
    }
  }

  /* Mark all squares of primes as composite */
  loopend = (long) sqrtf(end) + 1;
  for (n = 5; n < loopend; n += 2)
    if (!IS_SET_ARRAY_BIT(mem,n/2))
      for (k = n*n; k <= end; k += 2*n*n)
        SET_ARRAY_BIT(mem,k/2);

  CLR_ARRAY_BIT(mem, 3/2);     /* 3 is prime */
  CLR_ARRAY_BIT(mem, 5/2);     /* 5 is prime */

  return mem;
}


int main(void)
{
  WTYPE s;
  WTYPE high = (MAXN-1)/2;
  WTYPE full_words;
  int count = 1;

#if 0
  WTYPE* sieve = sieve_erat(MAXN);
  //WTYPE* sieve = sieve_eratek(MAXN);
  //WTYPE* sieve = sieve_base23(MAXN);
  //WTYPE* sieve = sieve_atkin_naive(MAXN);
  //WTYPE* sieve = sieve_atkin_2(MAXN);
  //WTYPE* sieve = sieve_atkin(MAXN);

  full_words = NWORDS(high) - 1;
  s = 0;

  /* Count 0 bits using Wegner/Lehmer/Kernighan method. */
  for (; s < full_words; s++) {
    WTYPE word = ~sieve[s];
    while (word) {
      word &= word-1;
      count++;
    }
  }

  /* Count primes in the last (partial) word */
  for (s = full_words*BITS_PER_WORD; s <= high; s++)
    if ( ! IS_SET_ARRAY_BIT(sieve, s) )
      count++;
#else
  //unsigned char* sieve = sieve_erat30tm(MAXN);
  unsigned char* sieve = sieve_erat30(MAXN);
  count = 3;  /* 2, 3, 5 */
  full_words = ((MAXN-1)/30) / sizeof(WTYPE);
  WTYPE* wsieve = (WTYPE*) sieve;
  for (s = 0; s < full_words; s++) {
    WTYPE word = ~wsieve[s];
    while (word) {
      word &= word-1;
      count++;
    }
  }
  /* Count primes in the last (partial) word */
  {
    static const WTYPE wheel[] = {1, 7, 11, 13, 17, 19, 23, 29};
    WTYPE m = 0;
    WTYPE d = full_words * sizeof(WTYPE);
    while ( (d*30+wheel[m]) <= MAXN ) {
      if ((sieve[d] & mask_tab[wheel[m]]) == 0)
        count++;
      m++;  if (m == 8) { m = 0; d++; }
    }
  }
#endif
  free(sieve);

  printf("Pi(%lu) = %d\n", MAXN, count);
  return 0;
}
