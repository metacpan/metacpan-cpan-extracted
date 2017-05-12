/*
@(#)File:            $RCSfile: esqlc.h,v $
@(#)Version:         $Revision: 1.14 $
@(#)Last changed:    $Date: 1997/10/09 02:57:34 $
@(#)Purpose:         Include all relevant ESQL/C type definitions
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1992-93,1995-97
@(#)Product:         $Product: DBD::Sqlflex Version 0.58 (1998-01-15) $
*/

#ifndef ESQLC_H
#define ESQLC_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqlc_h[] = "@(#)$Id: esqlc.h,v 1.14 1997/10/09 02:57:34 johnl Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

/* If it still isn't defined, use version 0 */
#ifndef ESQLC_VERSION
#define ESQLC_VERSION 0
#endif /* ESQLC_VERSION */

/*
** On DEC OSF/1 and 64-bits machines, __STDC__ is not necessarily defined,
** but the use of prototypes is necessary under optimization to ensure that
** pointers are treated correctly (sizeof(void *) != sizeof(int)).
** The <sqlhdr.h> prototypes for version 6.00 and above are only active if
** __STDC__ is defined (whether 1 or 0 or something else does not matter).
** Ensure that the compilation options set __STDC__.
*/

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/* -- Include Files	*/

#include <datetime.h>
#include <decimal.h>
#include <sqlca.h>
#include <sqlda.h>
#include <sqlstype.h>
#include <sqltypes.h>

#if ESQLC_VERSION >= 400
#endif /* ESQLC_VERSION >= 400 */

/* _WIN32 (Windows 95/NT code from Harald Ums <Harald.Ums@sevensys.de> */

#if ESQLC_VERSION < 400
/* No prototypes available -- for earlier versions, you are on your own! */
#elif ESQLC_VERSION < 410
#include "esql4_00.h"
#include "esqllib.h"
#elif ESQLC_VERSION < 500
#include "esql4_10.h"
#include "esqllib.h"
#elif ESQLC_VERSION < 600
#ifdef _WIN32
#include <windows.h>
#include <sqlhdr.h>
#include <sqlproto.h>
#else
#include "esql5_00.h"
#include "esqllib.h"
#endif /* _WIN32 */
#else
/* For later versions, sqlhdr.h contains the requisite declarations. */
/* However, these declarations are protected by __STDC__ so you need */
/* to ensure that your compiler has it defined.  Note that compilers */
/* on some machines do complain if you try to define __STDC__.       */
#include <sqlhdr.h>

#ifdef _WIN32
#include <sqlproto.h>
#else
#if ESQLC_VERSION >= 720 && ESQLC_VERSION < 800
#include "esql7_20.h"
#endif /* ESQLC_VERSION is 7.2x */

extern int      sqgetdbs(int *ret_fcnt,
                         char **fnames,
                         int fnsize,
                         char *farea,
                         int fasize);
#endif /* _WIN32 */

#endif /* ESQLC_VERSION */

/* -- Constant Definitions */

/* A table name may be: database@server:"owner".table */
/* This contains 5 punctuation characters and a null */
#define SQL_NAMELEN	18
#define SQL_USERLEN	8
#define SQL_TABNAMELEN	(3 * SQL_NAMELEN + SQL_USERLEN + 6)

#define loc_mode	lc_union.lc_file.lc_mode
#define sqlva		sqlvar_struct

/* -- Type Definitions */

typedef struct decimal	Decimal;
typedef struct dtime	Datetime;
typedef struct intrvl	Interval;
typedef struct sqlca_s	Sqlca;
typedef struct sqlda	Sqlda;
typedef struct sqlva	Sqlva;

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif	/* ESQLC_H */
