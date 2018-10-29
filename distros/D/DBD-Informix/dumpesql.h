/*
@(#)File:           $RCSfile: dumpesql.h,v $
@(#)Version:        $Revision: 1.19 $
@(#)Last changed:   $Date: 2009/07/26 02:50:29 $
@(#)Purpose:        ESQL/C Type Dumper Code
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 2005,2007-09
@(#)Product:        Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28)
*/

/*TABSTOP=4*/

#ifndef JLSS_ID_DUMPESQL_H
#define JLSS_ID_DUMPESQL_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#ifdef  __cplusplus
extern "C" {
#endif

#ifdef MAIN_PROGRAM
#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
extern const char jlss_id_dumpesql_h[];
const char jlss_id_dumpesql_h[] = "@(#)$Id: dumpesql.h,v 1.19 2009/07/26 02:50:29 jleffler Exp $";
#endif /* lint */
#endif /* MAIN_PROGRAM */

#include <stdio.h>
#include "esqlc.h"

#if !defined(__GNUC__) && !defined(__IBM_ATTRIBUTES)
/* IBM Visual Age C supports GNU attribute notations (define not allowed) */
#define __attribute__(x) /* If only other compilers supported this */
#endif /* !__GNUC__ && !__IBM_ATTRIBUTES */

#ifndef TU_FRACDIGITS
#define TU_FRACDIGITS(q)    ((TU_END(q) < TU_SECOND) ? 0 : (TU_END(q) - TU_SECOND))
#endif /* TU_FRACDIGITS */

/* A (poor) simulation of C++ const_cast<type>(value) */
#ifndef CONST_CAST
#ifdef __cplusplus
#define CONST_CAST(type, value) const_cast<type>(value)
#else
#define CONST_CAST(type, value) ((type)(value))
#endif /* __cplusplus */
#endif /* CONST_CAST */

#ifndef DIM
#define DIM(x)  (sizeof(x)/sizeof(*(x)))
#endif /* DIM */

#ifndef TYPEDEF_IFX_ERRNUM_T
#define TYPEDEF_IFX_ERRNUM_T
typedef int ifx_errnum_t;
#endif /* TYPEDEF_IFX_ERRNUM_T */

#ifndef IFX_DEC_T
#define IFX_DEC_T
typedef dec_t ifx_dec_t;
#endif /* IFX_DEC_T */

#ifndef IFX_VALUE_T
#define IFX_VALUE_T
typedef value_t ifx_value_t;
#endif /* IFX_VALUE_T */

/*
** It is not clear when ifx_sqlca_t, ifx_sqlda_t and ifx_sqlvar_t were
** introduced.  They are not in ESQL/C 7.24; they are in ESQL/C 9.53 and
** later.  There is evidence that they were added in ESQL/C 9.12.
*/
#ifndef IFX_SQLCA_T
#define IFX_SQLCA_T
#if ESQLC_VERSION >= 500 && ESQLC_VERSION < 912
typedef struct sqlca_s ifx_sqlca_t;
#endif /* ESQLC_VERSION */
#endif /* IFX_SQLCA_T */

#ifndef IFX_SQLDA_T
#define IFX_SQLDA_T
#if ESQLC_VERSION >= 500 && ESQLC_VERSION < 912
typedef struct sqlda ifx_sqlda_t;
#endif /* ESQLC_VERSION */
#endif /* IFX_SQLDA_T */

#ifndef IFX_SQLVAR_T
#define IFX_SQLVAR_T
#if ESQLC_VERSION >= 500 && ESQLC_VERSION < 912
typedef struct sqlvar_struct ifx_sqlvar_t;
#endif /* ESQLC_VERSION */
#endif /* IFX_SQLVAR_T */

/* acinformix.m4 from 2008-03-19 onwards detects ifx_loc_t as ESQLC_IFX_LOC_T */
/* and writes that into config.h */
/* NB: ESQL/C 3.00.xC2 does not typedef ifx_loc_t; 3.00.xC3 does */
#ifndef ESQLC_IFX_LOC_T
#if ESQLC_VERSION < 350 || ESQLC_VERSION >= 400
/* locator.h in 3.50 up typedefs ifx_loc_t */
#ifndef IFX_LOC_T
#define IFX_LOC_T
typedef loc_t   ifx_loc_t;
#endif /* IFX_LOC_T */
#endif /* ESQLC_VERSION < 350 || ESQLC_VERSION >= 400 */
#endif /* ESQLC_IFX_LOC_T */

/* XXX Kludge - but hard to avoid right now */
#ifdef HAVE_DATEZONE_H

#include "datezone.h"
extern void dump_dtimetz(FILE *fp, const char *tag, const ifx_dtimetz_t *dp);

#else

typedef dtime_t  ifx_dtime_t;
typedef intrvl_t ifx_intrvl_t;

#endif /* HAVE_DATEZONE_H */

extern void dump_blob(FILE *fp, const char *tag, const ifx_loc_t *blob);
extern void dump_datetime(FILE *fp, const char *tag, const ifx_dtime_t *dp);
extern void dump_decimal(FILE *fp, const char *tag, const ifx_dec_t *dp);
extern void dump_interval(FILE *fp, const char *tag, const ifx_intrvl_t *ip);
extern void dump_sqlca(FILE *fp, const char *tag, const ifx_sqlca_t *psqlca);
extern void dump_sqlda(FILE *fp, const char *tag, const ifx_sqlda_t *desc);
extern void dump_sqldescriptor(FILE *fp, const char *tag, const char *name);
extern void dump_sqlva(FILE *fp, int item, const ifx_sqlvar_t *sqlvar);
extern void dump_value(FILE *fp, const char *tag, const ifx_value_t *vp);

extern void dumpsqlca(FILE *fp, const char *tag);

extern void dump_print(FILE *fp, const char *fmt, ...)
                __attribute__((format(printf,2,3)));

extern int  dump_setindent(int level);

extern const char *dump_getindent(void);

#ifdef  __cplusplus
}
#endif

#endif /* JLSS_ID_DUMPESQL_H */
