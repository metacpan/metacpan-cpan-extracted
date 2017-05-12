
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


/* Radix of exponent representation, b. */

SV * _FLT_RADIX(pTHX) {
#ifdef FLT_RADIX
 return newSViv(FLT_RADIX);
#else
 return &PL_sv_undef;
#endif
}

/* Maximum representable finite floating-point number,

	(1 - b**-p) * b**emax
*/

SV * _LDBL_MAX(pTHX) {
#ifdef LDBL_MAX
 return newSVnv(LDBL_MAX);
#else
 return &PL_sv_undef;
#endif
}

/* Minimum normalized positive floating-point number, b**(emin - 1).  */

SV * _LDBL_MIN(pTHX) {
#ifdef LDBL_MIN
 return newSVnv(LDBL_MIN);
#else
 return &PL_sv_undef;
#endif
}

/* Number of decimal digits, q, such that any floating-point number with q
   decimal digits can be rounded into a floating-point number with p radix b
   digits and back again without change to the q decimal digits,

	p * log10(b)			if b is a power of 10
	floor((p - 1) * log10(b))	otherwise
*/

SV * _LDBL_DIG(pTHX) {
#ifdef LDBL_DIG
 return newSViv(LDBL_DIG);
#else
 return &PL_sv_undef;
#endif
}

/* Number of base-FLT_RADIX digits in the significand, p.  */

SV * _LDBL_MANT_DIG(pTHX) {
#ifdef LDBL_MANT_DIG
 return newSViv(LDBL_MANT_DIG);
#else
 return &PL_sv_undef;
#endif
}

/* Minimum int x such that FLT_RADIX**(x-1) is a normalized float, emin */

SV * _LDBL_MIN_EXP(pTHX) {
#ifdef LDBL_MIN_EXP
 return newSViv(LDBL_MIN_EXP);
#else
 return &PL_sv_undef;
#endif
}

/* Maximum int x such that FLT_RADIX**(x-1) is a representable float, emax.  */

SV * _LDBL_MAX_EXP(pTHX) {
#ifdef LDBL_MAX_EXP
 return newSViv(LDBL_MAX_EXP);
#else
 return &PL_sv_undef;
#endif
}

/* Minimum negative integer such that 10 raised to that power is in the
   range of normalized floating-point numbers,

	ceil(log10(b) * (emin - 1))
*/

SV * _LDBL_MIN_10_EXP(pTHX) {
#ifdef LDBL_MIN_10_EXP
 return newSViv(LDBL_MIN_10_EXP);
#else
 return &PL_sv_undef;
#endif
}

/* Maximum integer such that 10 raised to that power is in the range of
   representable finite floating-point numbers,

	floor(log10((1 - b**-p) * b**emax))
*/

SV * _LDBL_MAX_10_EXP(pTHX) {
#ifdef LDBL_MAX_10_EXP
 return newSViv(LDBL_MAX_10_EXP);
#else
 return &PL_sv_undef;
#endif
}

/* The difference between 1 and the least value greater than 1 that is
   representable in the given floating point type, b**1-p.  */

SV * _LDBL_EPSILON(pTHX) {
#ifdef LDBL_EPSILON
 return newSVnv(LDBL_EPSILON);
#else
 return &PL_sv_undef;
#endif
}

SV * _LDBL_DECIMAL_DIG(pTHX) {
#ifdef LDBL_DECIMAL_DIG
 return newSViv(LDBL_DECIMAL_DIG);
#else
 return &PL_sv_undef;
#endif
}

/* Whether types support subnormal numbers.  */

SV * _LDBL_HAS_SUBNORM(pTHX) {
#ifdef LDBL_HAS_SUBNORM
 return newSViv(LDBL_HAS_SUBNORM);
#else
 return &PL_sv_undef;
#endif
}

/* Minimum positive values, including subnormals.  */

SV * _LDBL_TRUE_MIN(pTHX) {
#ifdef LDBL_TRUE_MIN
 return newSVnv(LDBL_TRUE_MIN);
#else
 return &PL_sv_undef;
#endif
}

void DD2HEX(pTHX_ SV * nv, char * fmt) {
 dXSARGS;
 char * buffer;

 if(!strEQ(fmt, "%La") && !strEQ(fmt, "%LA"))
   croak("Second arg to DD2HEX is %s - but needs to be either \"%%La\" or \"%%LA\"", fmt);

 Newx(buffer, 40, char);
 if(buffer == NULL) croak("Failed to allocate memory in DD2HEX");

 sprintf(buffer, fmt, (long double)SvNV(nv));
 EXTEND(SP, 1);
 ST(0) = sv_2mortal(newSVpv(buffer, 0));
 Safefree(buffer);
 XSRETURN(1);
}

int _isnan_ld (long double d) {
  if(d == d) return 0;
  return 1;
}

void _NV2binary (pTHX_ SV * nv) {

  dXSARGS;
  long double d = (long double)SvNV(nv);
  long double e;
  int exp = 1;
  unsigned long int prec = 0;
  int returns = 0;

  sp = mark;

  if(_isnan_ld(d)) {
      XPUSHs(sv_2mortal(newSVpv("+nan", 0)));
      XPUSHs(sv_2mortal(newSViv(exp)));
      XPUSHs(sv_2mortal(newSViv(prec)));
      XSRETURN(3);
  }

  if (d < (long double) 0.0 || (d == (long double) 0.0 && (1.0 / (double) d < 0.0))) {
      XPUSHs(sv_2mortal(newSVpv("-", 0)));
      d = -d;
  }
  else XPUSHs(sv_2mortal(newSVpv("+", 0)));
  returns++;

  /* now d >= 0 */
  /* Use 2 differents tests for Inf, to avoid potential bugs
     in implementations. */
  if (_isnan_ld (d - d) || (d > 1 && d * 0.5 == d)) {
      XPUSHs(sv_2mortal(newSVpv("inf", 0)));
      XPUSHs(sv_2mortal(newSViv(exp)));
      XPUSHs(sv_2mortal(newSViv(prec)));
      returns += 3;
      XSRETURN(returns);
  }

  if (d == (long double) 0.0) {
      XPUSHs(sv_2mortal(newSVpv("0.0", 0)));
      XPUSHs(sv_2mortal(newSViv(exp)));
      XPUSHs(sv_2mortal(newSViv(prec)));
      returns += 3;
      XSRETURN(returns);
  }

  /* now d > 0 */
  e = (long double) 1.0;
  while (e > d) {
      e = e * (long double) 0.5;
      exp --;
  }

  /* now d >= e */
  while (d >= e + e) {
      e = e + e;
      exp ++;
  }

  /* now e <= d < 2e */
  XPUSHs(sv_2mortal(newSVpv("0.", 0)));
  returns ++;

  while (d > (long double) 0.0) {
      prec++;
      if(d >= e) {
        XPUSHs(sv_2mortal(newSVpv("1", 0)));
        returns ++;
        d = (long double) ((long double) d - (long double) e);
      }
      else {
        XPUSHs(sv_2mortal(newSVpv("0", 0)));
        returns ++;
      }
      e *= (long double) 0.5;
  }

  XPUSHs(sv_2mortal(newSViv(exp)));
  XPUSHs(sv_2mortal(newSViv(prec)));
  returns += 2;
  XSRETURN(returns);
}

void _calculate (pTHX_ SV * bin, SV * exponent) {
  dXSARGS;
  IV i, imax;
  long double ret = 0L;
  long double exp = (long double)SvNV(exponent);
  imax = av_len((AV*)SvRV(bin));

  for(i = 0; i <= imax; i++) {
    if(SvIV(*(av_fetch((AV*)SvRV(bin), i, 0)))) ret += powl(2.0L, exp);
    exp -= 1L;
  }
  ST(0) = sv_2mortal(newSVnv(ret));
  ST(1) = sv_2mortal(newSVnv(exp));
  XSRETURN(2);
}

void _dd_bytes(pTHX_ SV * sv) {
  dXSARGS;
  long double dd = SvNV(sv);
  int i, n = sizeof(long double);
  char * buff;
  void * p = &dd;

  Newx(buff, 4, char);
  if(buff == NULL) croak("Failed to allocate memory in _dd_bytes function");

  sp = mark;

#ifdef WE_HAVE_BENDIAN /* Big Endian architecture */
  for (i = 0; i < n; i++) {
#else
  for (i = n - 1; i >= 0; i--) {
#endif

    sprintf(buff, "%02X", ((unsigned char*)p)[i]);
    XPUSHs(sv_2mortal(newSVpv(buff, 0)));
  }
  PUTBACK;
  Safefree(buff);
  XSRETURN(n);
}

SV * _endianness(pTHX) {
#if defined(WE_HAVE_BENDIAN)
  return newSVpv("Big Endian", 0);
#elif defined(WE_HAVE_LENDIAN)
  return newSVpv("Little Endian", 0);
#else
  return &PL_sv_undef;
#endif
}


MODULE = Data::Float::DoubleDouble  PACKAGE = Data::Float::DoubleDouble

PROTOTYPES: DISABLE


SV *
_FLT_RADIX ()
CODE:
  RETVAL = _FLT_RADIX (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_MAX ()
CODE:
  RETVAL = _LDBL_MAX (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_MIN ()
CODE:
  RETVAL = _LDBL_MIN (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_DIG ()
CODE:
  RETVAL = _LDBL_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_MANT_DIG ()
CODE:
  RETVAL = _LDBL_MANT_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_MIN_EXP ()
CODE:
  RETVAL = _LDBL_MIN_EXP (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_MAX_EXP ()
CODE:
  RETVAL = _LDBL_MAX_EXP (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_MIN_10_EXP ()
CODE:
  RETVAL = _LDBL_MIN_10_EXP (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_MAX_10_EXP ()
CODE:
  RETVAL = _LDBL_MAX_10_EXP (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_EPSILON ()
CODE:
  RETVAL = _LDBL_EPSILON (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_DECIMAL_DIG ()
CODE:
  RETVAL = _LDBL_DECIMAL_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_HAS_SUBNORM ()
CODE:
  RETVAL = _LDBL_HAS_SUBNORM (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_TRUE_MIN ()
CODE:
  RETVAL = _LDBL_TRUE_MIN (aTHX);
OUTPUT:  RETVAL


void
DD2HEX (nv, fmt)
	SV *	nv
	char *	fmt
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DD2HEX(aTHX_ nv, fmt);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
_NV2binary (nv)
	SV *	nv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _NV2binary(aTHX_ nv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
_calculate (bin, exponent)
	SV *	bin
	SV *	exponent
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _calculate(aTHX_ bin, exponent);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
_dd_bytes (sv)
	SV *	sv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _dd_bytes(aTHX_ sv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_endianness ()
CODE:
  RETVAL = _endianness (aTHX);
OUTPUT:  RETVAL


