/*
@(#)File:           $RCSfile: decsci.h,v $
@(#)Version:        $Revision: 3.15 $
@(#)Last changed:   $Date: 2007/12/27 08:04:17 $
@(#)Purpose:        JLSS Functions to manipulate DECIMAL values
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1996-99,2001-03,2005,2007
@(#)Product:        Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
*/

/*TABSTOP=4*/

#ifndef DECSCI_H
#define DECSCI_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char decsci_h[] = "@(#)$Id: decsci.h,v 3.15 2007/12/27 08:04:17 jleffler Exp $";
#endif /* lint */
#endif /* MAIN_PROGRAM */

#include <stddef.h>
#include "decimal.h"
#include "ifmxdec.h"

#ifndef CONST_CAST
#ifdef __cplusplus
#define CONST_CAST(type, value) const_cast<type>(value)
#else
/* Poor simulation of C++ const_cast<type>(value) */
#define CONST_CAST(type, value) ((type)(value))
#endif /* __cplusplus */
#endif /* CONST_CAST */

#ifndef DECEXPZERO
#define DECEXPZERO  -64     /* Exponent used in zero; dec_ndgts == 0 too */
#endif /* DECEXPZERO */
#ifndef DECEXPMIN
#define DECEXPMIN   -64     /* Minimum permissible exponent */
#endif /* DECEXPMIN */
#ifndef DECEXPMAX
#define DECEXPMAX   +63     /* Maximum permissible exponent */
#endif /* DECEXPMAX */
#ifndef DECDGTMIN
#define DECDGTMIN   0       /* Minimum digit value */
#endif /* DECDGTMIN */
#ifndef DECDGTMAX
#define DECDGTMAX   99      /* Maximum digit value */
#endif /* DECDGTMAX */
#ifndef DECPOSPOS
#define DECPOSPOS   +1      /* Indicates positive value */
#endif /* DECPOSPOS */
#ifndef DECPOSNEG
#define DECPOSNEG   0       /* Indicates negative value */
#endif /* DECPOSNEG */
#ifndef DECEXPNULL
#define DECEXPNULL  0       /* Exponent used in NULL; dec_pos = DECPOSNULL is key */
#endif /* DECEXPMAX */

#ifndef DECNULL_INITIALIZER
#define DECNULL_INITIALIZER { DECEXPNULL, DECPOSNULL, 0, { 0 /* 16 zeroes */ } }
#endif /* DECNULL_INITIALIZER */
#ifndef DECZERO_INTIALIZER
#define DECZERO_INITIALIZER { DECEXPZERO, DECPOSPOS,  0, { 0 /* 16 zeroes */ } }
#endif /* DECZERO_INTIALIZER */

/* In-situ versions */
extern void dec_abs(ifx_dec_t *x);
extern void dec_neg(ifx_dec_t *x);

/* Copy result versions */
extern int decabs(const ifx_dec_t *x, ifx_dec_t *r1);
extern int decneg(const ifx_dec_t *x, ifx_dec_t *r1);

extern int decpower(const ifx_dec_t *x, int n, ifx_dec_t *r1);
extern int decsqrt(const ifx_dec_t *x, ifx_dec_t *r1);

extern int dec_normalize(ifx_dec_t *dp);        /* Normalize a decimal value */

#ifdef USE_DEPRECATED_DECSCI_FUNCTIONS
/*
** NB: the routines decfix(), decsci(), deceng() are not thread-safe
** and share common return storage.  Their use is totally deprecated.
** Use the alternatives: dec_fix(), dec_sci(), dec_eng().
*/
extern char *decfix(const ifx_dec_t *d, int ndigit, int plus);
extern char *decsci(const ifx_dec_t *d, int ndigit, int plus);
extern char *deceng(const ifx_dec_t *d, int ndigit, int plus, int cw);
extern int   decfmt(const ifx_dec_t *d, int sqllen, int fmtcode, char *buffer, size_t buflen);
#endif /* USE_DEPRECATED_DECSCI_FUNCTIONS */

extern int dec_fix(const ifx_dec_t *d, int ndigit, int plus, char *buffer, size_t buflen);
extern int dec_sci(const ifx_dec_t *d, int ndigit, int plus, char *buffer, size_t buflen);
extern int dec_eng(const ifx_dec_t *d, int ndigit, int plus, int cw, char *buffer, size_t buflen);
extern int dec_fmt(const ifx_dec_t *d, int sqllen, int fmtcode, char *buffer, size_t buflen);

extern char *dec_setexp(char  *dst, int dp);

extern int dec_chk(const ifx_dec_t *d, int sqllen);
extern int dec_set(ifx_dec_t *d, int sqllen);

extern void dec_verify(const ifx_dec_t *d);

/* dec_mod - decimal modulus operator */
extern int dec_mod(const ifx_dec_t *dividend, const ifx_dec_t *divisor, ifx_dec_t *result);

/* dec_remquo - decimal modulus, returning quotient and remainder */
extern int dec_remquo(const ifx_dec_t *dividend, const ifx_dec_t *divisor,
                      ifx_dec_t *quotient, ifx_dec_t *remainder);

#endif /* DECSCI_H */
