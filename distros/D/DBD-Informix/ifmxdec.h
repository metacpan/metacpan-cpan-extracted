/*
@(#)File:           $RCSfile: ifmxdec.h,v $
@(#)Version:        $Revision: 1.19 $
@(#)Last changed:   $Date: 2008/08/31 11:54:43 $
@(#)Purpose:        Internal declarations for DECIMAL functions
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 2003-08
@(#)Product:        Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28)
*/

/*TABSTOP=4*/

#ifndef IFMXDEC_H
#define IFMXDEC_H

#ifdef  __cplusplus
extern "C" {
#endif

#ifdef MAIN_PROGRAM
#ifndef lint
static const char ifmxdec_h[] = "@(#)$Id: ifmxdec.h,v 1.19 2008/08/31 11:54:43 jleffler Exp $";
#endif  /* lint */
#endif  /* MAIN_PROGRAM */

#include <stddef.h> /* size_t */
#include "decimal.h"
#include "esqltype.h"

#ifndef IFX_DEC_T
#define IFX_DEC_T
typedef dec_t ifx_dec_t;
#endif /* IFX_DEC_T */

/* Numeric constants */
extern const ifx_dec_t dec_null;
extern const ifx_dec_t dec_zero;
extern const ifx_dec_t dec_one;
extern const ifx_dec_t dec_two;
extern const ifx_dec_t dec_ten;
extern const ifx_dec_t dec_sixty;   /* Time calculations */
extern const ifx_dec_t dec_hundred;
extern const ifx_dec_t dec_e;
extern const ifx_dec_t dec_pi;

/* lddecimal() - used in C-ISAM */
extern int lddecimal(const char *cp, int len, ifx_dec_t *np);
/* stdecimal() - used in C-ISAM */
extern void stdecimal(const ifx_dec_t *np, char *cp, int len);

/* JLSS - additions */
extern int  flt_eq_null(float f);
extern void flt_setnull(float *fp);
extern int  dbl_eq_null(double d);
extern void dbl_setnull(double *dp);

extern int  (dec_eq_null)(const ifx_dec_t *dp);
extern void (dec_setnull)(ifx_dec_t *dp);
extern int  (dec_eq_zero)(const ifx_dec_t *dp);
extern void (dec_setzero)(ifx_dec_t *dp);

extern int  (dec_is_neg)(const ifx_dec_t *dp);
extern int  (dec_is_pos)(const ifx_dec_t *dp);

/* Macro overrides for functions */
#ifndef dec_setnull
#define dec_setnull(d)  ((void)((d)->dec_pos = DECPOSNULL))
#endif /* dec_setnull */
#ifndef dec_eq_null
#define dec_eq_null(d)  ((d)->dec_pos == DECPOSNULL)
#endif /* dec_eq_null */
#ifndef dec_is_neg
#define dec_is_neg(d)   ((d)->dec_pos == DECPOSNEG)
#endif /* dec_is_neg */
#ifndef dec_is_pos
#define dec_is_pos(d)   ((d)->dec_pos == DECPOSPOS)
#endif /* dec_is_pos */

/* JLSS - revised conversion interfaces */

extern int  dec_cv_int2(ifx_dec_t *dp, ixInt2 i2);
extern int  dec_to_int2(const ifx_dec_t *dp, ixInt2 *i2);
extern int  dec_cv_int4(ifx_dec_t *dp, ixInt4 i4);
extern int  dec_to_int4(const ifx_dec_t *dp, ixInt4 *i4);
/*
extern int  dec_cv_int8(ifx_dec_t *dp, ixInt8 i8);
extern int  dec_to_int8(const ifx_dec_t *dp, ixInt8 *i8);
*/
extern int  dec_cv_float(ifx_dec_t *dp, float f);
extern int  dec_to_float(const ifx_dec_t *dp, float *f);
extern int  dec_cv_double(ifx_dec_t *dp, double f);
extern int  dec_to_double(const ifx_dec_t *dp, double *f);
extern int  dec_cv_string(ifx_dec_t *dp, const char *str);
extern int  dec_to_string(const ifx_dec_t *dp, char *buffer, size_t bufsiz);

#ifdef  __cplusplus
}
#endif

#endif  /* IFMXDEC_H */
