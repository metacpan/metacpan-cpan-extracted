#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

#ifndef bytes_from_utf8

/* 5.6.0 has UTF-8 scalars, but lacks the utility bytes_from_utf8() */

static U8 *
bytes_from_utf8(U8 *orig, STRLEN *len_p, bool *is_utf8_p)
{
	STRLEN orig_len = *len_p;
	U8 *orig_end = orig + orig_len;
	STRLEN new_len = orig_len;
	U8 *new;
	U8 *p, *q;
	if(!*is_utf8_p)
		return orig;
	for(p = orig; p != orig_end; ) {
		U8 fb = *p++, sb;
		if(fb <= 0x7f)
			continue;
		if(p == orig_end || !(fb >= 0xc2 && fb <= 0xc3))
			return orig;
		sb = *p++;
		if(!(sb >= 0x80 && sb <= 0xbf))
			return orig;
		new_len--;
	}
	if(new_len == orig_len) {
		*is_utf8_p = 0;
		return orig;
	}
	Newx(new, new_len+1, U8);
	for(p = orig, q = new; p != orig_end; ) {
		U8 fb = *p++;
		*q++ = fb <= 0x7f ? fb : ((fb & 0x03) << 6) | (*p++ & 0x3f);
	}
	*q = 0;
	*len_p = new_len;
	*is_utf8_p = 0;
	return new;
}

#endif /* !bytes_from_utf8 */

/*
 * A VAX assembler version of this algorithm is available at
 * http://www.phreak.org/archives/The_Hacker_Chronicles_II/phun/phun303.txt
 *
 * Original C implementation by Shawn Clifford in February 1993.
 *
 * This file is adapted from hpwd.c in VMSCRACK 1.0.
 * Code from VMSCRACK by Davide Casale.
 *
 * Code optimizations by Mario Ambrogetti in June 1994.
 *
 * Code fixes with the help of Terence Lee.
 *
 * VMS patch 5 for John the Ripper version 1.6.32
 * (C) 2002 Jean-loup Gailly  http://gailly.net
 * license: GPL <http://www.gnu.org/>
 * This file is based on code from John the Ripper,
 *   Copyright (c) 1996-2002 by Solar Designer.
 *
 * Modified for Perl by Andrew Main (Zefram) <zefram@fysh.org> in
 * August 2006, with further development in September 2007 and
 * March 2009.
 */

#include <string.h>
#include <limits.h>

/* byte type must be exactly 8 bits */
#if CHAR_BIT != 8
# error require CHAR_BIT == 8
#endif
typedef unsigned char byte;

/* word type must be exactly 16 bits */
#if USHRT_MAX != 65535U
# error require USHRT_MAX == 65535U
#endif
typedef unsigned short word;

/* dword type must be exactly 32 bits */
#if UINT_MAX == 4294967295U
typedef unsigned int dword;
#elif ULONG_MAX == 4294967295UL
typedef unsigned long dword;
#else
# error no 32-bit type
#endif

/* optional ul64 type must be at least 64 bits, which is difficult to check
 * for when we're only guaranteed 32 bit arithmetic */
#if ((ULONG_MAX >> 16) & 0xffff0000UL) == 0xffff0000UL && \
	(((ULONG_MAX >> 16) >> 16) & 0xffff0000UL) == 0xffff0000UL
# define ul64 unsigned long
#elif defined(ULLONG_MAX) || defined(ULONG_LONG_MAX) || \
	defined(__INT64_MAX) || defined(__GNUC__)
# define ul64 unsigned long long
#endif

#if BYTEORDER == 0x1234 || BYTEORDER == 0x12345678
# define ARCH_LITTLE_ENDIAN 1
#elif BYTEORDER == 0x4321 || BYTEORDER == 0x87654321
# define ARCH_LITTLE_ENDIAN 0
#else
# error not a recognised endianness
#endif

#define UAIC_AD_II   0  /* AUTODIN-II 32 bit crc code                  */
#define UAIC_PURDY   1  /* Purdy polynomial over salted input          */
#define UAIC_PURDY_V 2  /* Purdy polynomial + variable length username */
#define UAIC_PURDY_S 3  /* PURDY_V + additional bit rotation           */

typedef union {
	struct {
#if ARCH_LITTLE_ENDIAN
		dword dd_low;
		dword dd_high;
#else
		dword dd_high;
		dword dd_low;
#endif
	} d;
#ifdef ul64
	ul64 q;
#endif
} qword;
#define d_low d.dd_low
#define d_high d.dd_high

/* To simplify the code we do not take advantage of cpus allowing unaligned
 * access. On modern cpus, it cheaper anyway to make aligned accesses.
 */

/* Convert an unaligned little-endian integer to a host integer */
#define unalignedWord(p) (((byte *)(p))[0] | (((byte *)(p))[1] << 8))
#define unalignedDword(p) \
  (unalignedWord(p) | (unalignedWord(((byte *)(p))+2) << 16))

/* Add a short value to an unaligned little-endian short. */
#define addUnalignedWord(p, x) \
    { word w = unalignedWord(p) + (x); \
      ((byte *)(p))[0] = w & 0xff; \
      ((byte *)(p))[1] = w >> 8; \
    }

#if ARCH_LITTLE_ENDIAN
#  define qwordConstant(low, high) { { (low), (high) } }
					/* qword in host format */
#  define normalizeQword(q) /* do not reverse order on little-endian systems */
#else
#  define qwordConstant(low, high) { { (high), (low) } }

   /* reverse a qword from little-endian to big-endian or vice-versa */
#  define normalizeQword(q) \
    { dword temp  = unalignedDword(&(q)->d_low); \
      (q)->d_low  = unalignedDword(&(q)->d_high); \
      (q)->d_high = temp; \
    }
#endif

#define PURDY_USERNAME_LENGTH   12 /* must be exactly 12 chars, space padded */

/* 2^64 - 59 is the biggest quadword prime */
#define A 59
#define DWORD_MAX 0xFFFFFFFFUL
#define P_D_LOW  (DWORD_MAX-A+1UL)
#define P_D_HIGH DWORD_MAX

/* These exponents are prime, but this is not required by the algorithm
 * N0 = 2^24 - 3;  N1 = 2^24 - 63;  N0-N1 = 60
 * Na and Nb are factors of N1-1 (see comments on function Purdy below)
 */
#define N0 0xFFFFFDUL
#define N1 0xFFFFC1UL
#define Na 448
#define Nb 37449

#define MASK (sizeof(qword)-1) /* mask for COLLAPSE_R2 */

static void COLLAPSE_R2(char *s, size_t len, qword *output, int isPurdyS);
static void Purdy(qword *);

static void PQEXP_R3 (qword *U,
                      unsigned long n,
                      qword *result);            /* U^n cmod P    */
static void PQMUL_R2 (qword *U,
                      qword *Y,
                      qword *result);            /* U * Y cmod P  */
static void PQLSH_R0 (qword *U,
                      qword *result);            /* 2^32*U cmod P */

/*   The following table of coefficients is used by the Purdy polynmial
 *   algorithm.  They are prime, but the algorithm does not require this.
 */
static qword C1 = qwordConstant(0xFFFFFFADUL, 0xFFFFFFFFUL);
static qword C2 = qwordConstant(0xFFFFFF4DUL, 0xFFFFFFFFUL);
static qword C3 = qwordConstant(0xFFFFFEFFUL, 0xFFFFFFFFUL);
static qword C4 = qwordConstant(0xFFFFFEBDUL, 0xFFFFFFFFUL);
static qword C5 = qwordConstant(0xFFFFFE95UL, 0xFFFFFFFFUL);

/* ============================================================================
   PQMOD_R0(qword U)
   This routine replaces the quadword U with U cmod P, where P is of the form
   P = 2^64 - a                    (a = 59)
     = FFFFFFFF.FFFFFFFF - 3B + 1  (DWORD_MAX = FFFFFFFF = 4,294,967,295)
     = FFFFFFFF.FFFFFFC5

   Method:  Since P is very nearly the maximum integer you can specify in a
   quadword (ie. P = FFFFFFFFFFFFFFC5, there will be only 58 choices for
   U that are larger than P (ie. U MOD P > 0).  So we check the high longword
   in the quadword and see if all its bits are set (-1).  If not, then U can
   not possibly be larger than P, and U MOD P = U.  If U is larger than
   DWORD_MAX - 59,then U MOD P is the differential between (DWORD_MAX - 59)
   and U, else U MOD P = U. If U equals P, then U MOD P = 0 = (P + 59).

   WARNING:  several operations described below as "modulo P" are actually
   "mod P or without overflow"; the notation "cmod P" is used to denote
   this conditional mod P operation (do the modulo if an overflow occurs).
   We do a real "mod P" right at the end because of this optimisation.
*/
#define PQMOD_R0(U) \
if ((U).d_high == P_D_HIGH && (U).d_low >= P_D_LOW) {  \
    (U).d_low += A; \
    (U).d_high = 0UL; \
}

/* ============================================================================
 * Inline versions of QROL1, EMULQ and PQADD_R0 for Watcom on i386 and above
 */
#if defined(Q_USE_ASSEMBLER) && defined(__WATCOMC__) && defined(__i386__)

    /* void QROL1(qword *p)
     * Rotate left both long words by one bit but independently
     */
    #pragma aux QROL1 = 0xD1 0x00       /* rol dword ptr [eax],1   */  \
                        0xD1 0x40 0x04  /* rol dword ptr [eax+4],1 */  \
                        parm [eax];

    /* void emulq(dword a, dword b, qword *result)
     * result = a * b (32x32 -> 64 multiplication)
     */
    #pragma aux EMULQ = 0xF7 0xE2        /* mul  edx         */  \
                        0x89 0x03        /* mov  [ebx],eax   */  \
                        0x89 0x53 0x04   /* mov  [ebx+4],edx */  \
                        parm [eax] [edx] [ebx] modify [eax edx];

    /* void PQADD_R0(qword *U, qword *Y, qword *result)
     * result = (U + Y) cmod P where P = 2^64 - A.
     * Warning: U and Y might both be >= P so we can still have an overflow
     * after subtracting P from the sum, in which case we subtract P again.
     */
    #pragma aux PQADD_R0 = 0x8B 0x03        /* mov  eax,[ebx]   */  \
                           0x8B 0x53 0x04   /* mov  edx,[ebx+4] */  \
                           0x03 0x01	    /* add  eax,[ecx]   */  \
                           0x13 0x51 0x04   /* adc  edx,[ecx+4] */  \
                           0x73 0x06	    /* jnc  NC          */  \
                           0x83 0xC0 A      /* C: add  eax,A    */  \
                           0x83 0xD2 0x00   /* adc  edx,0       */  \
                           0x72 0xFA        /* jc C             */  \
                           0x89 0x06        /* NC:mov [esi],eax */  \
                           0x89 0x56 0x04   /* mov  [esi+4],edx */  \
                           parm [ebx] [ecx] [esi] modify [eax edx];

/* ============================================================================
 * Inline versions of QROL1, EMULQ and PQADD_R0 for gcc on i386 and above
 */
#elif defined(Q_USE_ASSEMBLER) && defined(__GNUC__) && defined(__i386__)

    /* Rotate left both long words by one bit but independently */
    static __inline__ void QROL1(qword* p)
    {
	__asm__("roll $1,%0" : "=m" (p->d_low)  : "m" (p->d_low));
	__asm__("roll $1,%0" : "=m" (p->d_high) : "m" (p->d_high));
    }

    /* p = x * y (32x32->64) */
    static __inline__ void EMULQ(dword x, dword y, qword *p)
    {
	dword dummy;
	__asm__("mull %3       # mull y (x in eax)\n\t" \
		"movl %%eax,%0 # movl eax,p->d_low\n\t" \
		"movl %%edx,%1 # movl edx,p->d_high"
		: "=m" (p->d_low), "=m" (p->d_high), "=a" (dummy)
		: "rm" (y), "2" (x) 
		: "edx");
    }

    /* result = (U + Y) cmod P where P = 2^64 - A.
     * Warning: U and Y might both be >= P so we can still have an overflow
     * after subtracting P from the sum, in which case we subtract P again.
     */
    static __inline__ void PQADD_R0(qword *U, qword *Y, qword *result)
    {
	dword low, high;
	__asm__("movl %4,%2  # movl U->d_low,low\n\t" \
		"movl %5,%3  # movl U->d_high,high\n\t" \
		"addl %6,%2  # addl Y->d_low,low\n\t" \
		"adcl %7,%3  # adcl Y->d_high,high\n\t" \
		"jnc .LL%=   # jnc label\n\t" \
		".LM%=:      # label2:\n\t" \
		"addl $59,%2 # addl 59,low\n\t" \
		"adcl $0,%3  # adcl 0,high\n" \
		"jc .LM%=    # jc label2\n\t" \
		".LL%=:      # label:\n\t" \
		"movl %2,%0  # movl low,result->d_low\n\t" \
		"movl %3,%1  # movl high,result->d_high"
		: "=m" (result->d_low), "=m" (result->d_high),
		  "=&r" (low), "=&r" (high)
		: "m" (U->d_low), "m" (U->d_high),
		  "m" (Y->d_low), "m" (Y->d_high));
    }

/* ============================================================================
 * Default versions of QROL1, EMULQ and PQADD_R0
 */
#else
    /* rotate little-endian dword *p left by one bit */
    #define ROL1(p) { *(p) = (*(p) >> 31) | (*(p) << 1); }

    /* void QROL1(qword *p)
     * Rotate left both long words by one bit but independently.
     * On big-endian systems we must reverse all bytes to make sure
     * that bits propagate from more significant to least significant bytes.
     */
    #define QROL1(p) \
        {  normalizeQword(p); \
	   ROL1(&((p)->d_low)); \
	   ROL1(&((p)->d_high)); \
           normalizeQword(p); \
        }

#  ifdef ul64
    /* result = a * b (32x32 -> 64 multiplication)
     */
    #define EMULQ(a, b, result) { (result)->q = (ul64)(a) * (ul64)(b); }

    /* result = (U + Y) cmod P where P = 2^64 - A.
     * Warning: U and Y might both be >= P so we can still have an overflow
     * after subtracting P from the sum, in which case we subtract P again.
     */
    #define PQADD_R0(U, Y, result) \
      { \
	*(ul64*)(result) = *(ul64*)(U) + *(ul64*)(Y); \
	if (~*(ul64*)(U) < *(ul64*)(Y)) do { \
            *(ul64*)(result) += (ul64)A; \
	} while (*(ul64*)(result) < (ul64)A); \
      }
#  else
    /* result = a * b (32x32 -> 64 multiplication)
     */
    static void EMULQ(dword a, dword b, qword *result)
    {
        dword lo, hi, t, p;
        hi = (a >> 16) * (b >> 16);
        t = lo = (a & 0xffff) * (b & 0xffff);
        p = (a >> 16) * (b & 0xffff);
        lo += p << 16;
        hi += (p >> 16) + (lo < t);
        t = lo;
        p = (a & 0xffff) * (b >> 16);
        lo += p << 16;
        hi += (p >> 16) + (lo < t);
        result->d_low = lo;
        result->d_high = hi;
    }

    /* result = (U + Y) cmod P where P is of the form P = 2^64 - a.
     * Warning: U and Y might both be >= P so we can still have an overflow
     * after subtracting P from the sum, in which case we subtract P again.
     */
    static void PQADD_R0(qword *U, qword *Y, qword *result)
    {
	register dword carry;

	result->d_low = U->d_low + Y->d_low;

	/* Add the high longwords, checking for carry out */
	carry = ~U->d_low < Y->d_low;

        result->d_high = Y->d_high + carry;

	carry = (result->d_high < Y->d_high) + (~result->d_high < U->d_high);

        result->d_high += U->d_high;

	if (!carry) return; /* no overflow */

	/* In case of overflow, we may have to subtract P twice if at least
         * one operand was already above P.
         */
	do {
	    result->d_low += A;
	    carry = result->d_low < A;
	    result->d_high += carry;
	    carry = result->d_high < carry;
	} while (carry);
    }
#  endif /* ul64 */
#endif /* asm */

/* ============================================================================
   Portable C version of DEC's Purdy password hashing algorithms.
           output = 8 byte output buffer in host format
	 password = up to 32 characters, upper case, without spaces
	  encrypt = determines algorithm to use
		    1 -> Purdy algorithm
		    2 -> Purdy_V
		    3 -> Purdy_S (Hickory algorithm)
	     salt = 2 byte random number
	 username = up to 31 characters username, upper case.
*/
static void lgihpwd_purdy(qword *output,
	char *password, size_t password_len,
	int encrypt, word salt,
	char *username, size_t username_len)
{
    int isPurdyS = (encrypt == UAIC_PURDY_S);
    char uname[PURDY_USERNAME_LENGTH];

    /* output is kept in little-endian format until the call of Purdy() */
    output->d_low = output->d_high = 0UL;

    if (encrypt == UAIC_PURDY) {
	/* Purdy algorithm requires a fixed-length username */
	if(username_len < PURDY_USERNAME_LENGTH) {
		memcpy(uname, username, username_len);
		memset(uname + username_len, ' ',
			PURDY_USERNAME_LENGTH - username_len);
		username = uname;
	}
	username_len = PURDY_USERNAME_LENGTH;
    } else if (encrypt == UAIC_PURDY_S) {
	/* Hickory algorithm; Purdy_V with rotation */
	addUnalignedWord(((char *)output), password_len);
	/* Bytes 0-1 => length */
    }

    /* Collapse the password to the output quadword: */
    COLLAPSE_R2(password, password_len, output, isPurdyS);

    /* Add random salt into the middle of output (unaligned access)
     */
    addUnalignedWord(((char *)output)+3, salt);

    /* Collapse the username into the quadword */
    COLLAPSE_R2(username, username_len, output, isPurdyS);

    /* Purdy() needs input in host format: */
    normalizeQword(output);

    /* Run output through the polynomial mod P */
    Purdy(output);
}

/* ============================================================================
   This routine takes a string s of bytes and collapses them into an output
   quadword.  It does this by cycling around the bytes of the output buffer
   adding in the bytes of the input string. Additionally, when the top
   output byte is updated, each longword in the resultant hash is rotated
   left by one bit (PURDY_S only).
   The input/output is an unsigned quadword in little-endian format.
*/
static void COLLAPSE_R2(char *s, size_t len, qword *output, int isPurdyS)
{
    int r0, r1;
    byte *out = (byte*)output;

    /* Loop until input string exhausted */
    for (r0 = len; r0 != 0; r0--) {

	out[r1 = r0 & MASK] += *s++;

	if (isPurdyS && (r1 == MASK)) { /* If Purdy_S and top byte */
	    QROL1(output);
	}
    }
}

/* ============================================================================
   This routine computes f(U) MOD P where P = 2^64 - A.
   The input/output U is an unsigned quadword in host format.
   The function f is the following polynomial:
                   X^n0 + X^n1*C1 + X^3*C2 + X^2*C3 + X*C4 + C5

   To minimize the number of multiplications, we evaluate
   f(U) =  ((U^(n0-n1) + C1)*U^(n1-1) + (U*C2 + C3)*U + C4)*U + C5
            ^^^^^^^^^^^^^^^^^^^^^^^^^   ^^^^^^^^^^^^^^^^^^
                     part1                   part2
   To minimize the cost of U^(n1-1) we note that n1-1= 448 * 37449
   where the two factors have been chosen to have the minimum of bits
   set in their binary expansion. So U^(n1-1) = (U^448)^37449.
   448 has 3 bits set, 37449 has 6 bits set, 448*37449 has 18 bits set.
*/
static void Purdy(qword *U)
{
    qword T1, T2, T3;             /* intermediate values */

    PQEXP_R3 (U, Na, &T1);        /* T1 = U^Na                    */

    PQEXP_R3 (&T1, Nb, &T2);      /* T2 = (U^Na)^Nb = U^(n1-1)    */

    PQEXP_R3 (U, (N0-N1), &T1);   /* T1 = U^(N0-N1)               */

    PQADD_R0(&T1, &C1, &T3);      /* T3 = U^(n0-n1) + C1          */

    PQMUL_R2 (&T2, &T3, &T1);     /* T1 = U^(n0-1) + U^(n1-1)*C1  */


    PQMUL_R2(U, &C2, &T2);        /* T2 = U*C2                    */

    PQADD_R0(&T2, &C3, &T3);      /* T3 = U*C2 + C3               */

    PQMUL_R2 (U, &T3, &T2);       /* T2 = U^2*C2 + U*C3           */

    PQADD_R0(&T2, &C4, &T3);      /* T3 = U^2*C2 + U*C3 + C4      */


    PQADD_R0(&T1, &T3, &T2);      /* T2 = part1 + part2           */

    PQMUL_R2 (U, &T2, &T1);       /* T1 = (part1 + part2)*U       */

    PQADD_R0(&T1, &C5, U);        /* T1 = (part1 + part2)*U + C5  */

    /* Since we did all computations with a pseudo mod P (only avoiding
     * overflows) we have to do a real mod P now:
     */
    PQMOD_R0(*U);
}

/* ============================================================================
  This routine returns U^n cmod P where P = 2^64-A.
  The method comes from Knuth, "The Art of Computer Programing, Vol. 2",
  section 4.6.3, "Evaluation of Powers."  This algorithm computes U^n with
  fewer than (n-1) multiplies.  The result is U^n cmod P only because the
  multiplication routine is cmod P.  Knuth's example is from Pingala's Hindu
  algorithm in the Chandah-sutra.
*/
static void PQEXP_R3 (qword *U, unsigned long n, qword *result)
{
    qword Y, Z, Z1;  /* Intermediate factors for U */
    int Yok = 0;     /* set if Y is initialized (to avoid an extra multiply) */

    Z = *U;

    while (n != 0) {

	if (n & 1) { /* If n is odd, then we need an extra x (U) */
	    if (Yok) {
		PQMUL_R2 (&Y, &Z, result);
	    } else {
		*result = Z;
		Yok = 1;
	    }
	    if (n == 1) return;
	    Y = *result;              /* Copy for next pass */
	}
	n >>= 1;
	Z1 = Z;
	PQMUL_R2 (&Z1, &Z1, &Z); /* Square Z */
    }
    result->d_low  = 1UL; /* U^0 = 1 */
    result->d_high = 0UL;
}

/* ============================================================================
  Computes the product U*Y cmod P where P = 2^64 - A.
  The product may be formed as the sum of four longword multiplications
  which are scaled by powers of 2^32 by evaluating:

	  2^64*v*z + 2^32*(v*y + u*z) + u*y
	  ^^^^^^^^   ^^^^^^^^^^^^^^^^   ^^^
	  part1      part2 & part3      part4

  The result is computed such that division by the modulus P is avoided.

  u is the low longword of  U;    u = U.l_low
  v is the high longword of U;    v = U.l_high
  y is the low longword of  Y;    y = Y.l_low
  z is the high longword of Y;    z = Y.l_high
*/
static void PQMUL_R2 (qword *U, qword *Y, qword *result)
{
    qword stack;
    qword part1;
    qword part2;
    qword part3;

    EMULQ(U->d_high, Y->d_high, &stack); /* stack = v*z */

    /*** 1st term ***/

    PQLSH_R0(&stack, &part1);            /* part1 = 2^32*(v*z) cmod P */

    EMULQ(U->d_high, Y->d_low, &stack);  /* stack =  v*y */

    EMULQ(U->d_low, Y->d_high, &part2);  /* part2 =  u*z */

    PQADD_R0(&stack, &part2, &part3);    /* part3 =  (v*y + u*z) */

    PQADD_R0(&part1, &part3, &stack);    /* stack = 2^32*(v*z) + (v*y + u*z) */

    /*** 1st & 2nd terms ***/

    PQLSH_R0(&stack, &part1);       /* part1 = 2^64*(v*z) + 2^32*(v*y + u*z) */

    EMULQ(U->d_low, Y->d_low, &stack);   /* stack = u*y */

    /*** Last term ***/

    PQADD_R0(&part1, &stack, result);    /* Whole thing */
}

/* ============================================================================
  Computes the product 2^32*U cmod P where P = 2^64 - A.

  This routine is used by PQMUL in the formation of quadword products in
  such a way as to avoid division by the modulus P.
  The product 2^64*v + 2^32*u is congruent a*v + 2^32*U cmod P.

  u is the low longword in U
  v is the high longword in U
*/
static void PQLSH_R0 (qword *U, qword *result)
{
    qword stack;
    qword X;

    EMULQ(U->d_high, A, &stack); /* stack = A*v */

    X.d_high = U->d_low; /* X = 2^32 * u */
    X.d_low  = 0UL;

    PQADD_R0(&X, &stack, result); /* result = 2^32*u + A*v cmod P */
}

MODULE = Authen::DecHpwd PACKAGE = Authen::DecHpwd

PROTOTYPES: DISABLE

SV *
lgi_hpwd(SV *username_sv, SV *password_sv, unsigned alg, unsigned salt)
PROTOTYPE: $$$$
PREINIT:
	STRLEN username_len, password_len;
	U8 *username_str, *password_str, *username_octs, *password_octs;
	bool is_utf8;
	qword hash;
CODE:
	if(alg > UAIC_PURDY_S)
		croak("algorithm value %u is not recognised", alg);
	username_str = (U8*)SvPV(username_sv, username_len);
	is_utf8 = !!SvUTF8(username_sv);
	username_octs = bytes_from_utf8(username_str, &username_len, &is_utf8);
	if(username_octs != username_str) SAVEFREEPV(username_octs);
	if(is_utf8)
		croak("input must contain only octets");
	password_str = (U8*)SvPV(password_sv, password_len);
	is_utf8 = !!SvUTF8(password_sv);
	password_octs = bytes_from_utf8(password_str, &password_len, &is_utf8);
	if(is_utf8)
		croak("input must contain only octets");
	if(password_octs != password_str) SAVEFREEPV(password_octs);
	if(alg == UAIC_AD_II) {
		PUSHMARK(SP);
		XPUSHs(password_octs == password_str ? password_sv :
			sv_2mortal(newSVpvn((char*)password_octs,
						password_len)));
		PUTBACK;
		call_pv("Digest::CRC::crc32", G_SCALAR);
		SPAGAIN;
		hash.d_low = POPu ^ 0xffffffffUL;
		hash.d_high = 0;
	} else {
		lgihpwd_purdy(&hash, (char *)password_octs, password_len, alg,
			salt & 0xffff, (char *)username_octs, username_len);
	}
	normalizeQword(&hash);
	RETVAL = newSVpvn((char *)&hash, 8);
OUTPUT:
	RETVAL
