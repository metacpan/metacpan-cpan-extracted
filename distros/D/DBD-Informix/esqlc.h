/*
@(#)File:           $RCSfile: esqlc.h,v $
@(#)Version:        $Revision: 2013.1 $
@(#)Last changed:   $Date: 2013/02/06 18:59:31 $
@(#)Purpose:        Include all relevant ESQL/C type definitions
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1992-93,1995-2004,2006-08
@(#)Product:        Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
*/

/*
** Include all ESQL/C Headers with prototypes where possible.
** Support for ESQL/C Versions 5.x, 6.x, 7.1x, 7.2x, 9.x is
** believed to be sound.
** Support for ESQL/C Versions 7.0x, 8.0x or 8.1x is unproven; support
** for 8.2x is dubious.
**
** Support for ESQL/C 4.x was dropped at the end of 2001.
** Versions of ESQL/C prior to 4.00 never were supported.
**
** Note that CSDK 2.90 (Nov 2004) renumbered the ESQL/C version to 2.90
** too.  This is later than ESQL 9.53.  For the time being, assume that
** these versions will run 2.90, 2.91, ... but not reach 4.00.
**
** Note that the ESQL/C 4.x and earlier versions placed the headers
** directly in $INFORMIXDIR/incl, but ESQL/C versions 5.00 and later
** place the headers in $INFORMIXDIR/incl.
**
** Remembered or known ESQL/C Versions:
** 1.10         1985
** 2.00         1986
** 2.10         (Oct 1986)
** 4.00         (c1987)
** 4.10 - 4.12  (c1988-1994)
** 5.00         (Dec 1990)
** 5.01 - 5.06  (1991-1995)
** 5.07         (Feb 1996)
** 5.08         (UD1 = Jan 1997)
** 5.10         (UC7 = May 1999) Earliest Y2K-compliant version for 5.x
** 5.11         (Dec 2001)
** 5.20         (Sep 2002)
** 6.00         (1994)
** 7.00         (c1995 - Sequent only)
** 7.10 - 7.14  (c1995-1996)
** 7.20 - 7.23  (1996-1997)
** 7.24         (Sep 1997)  Y2K-compliant version for 7.2x
** 8.00         (c1995)
** 8.10         (c1996)
** 9.00         (c1996)
** 9.10         (c1996)
** 9.11         (c1997)
** 9.12         DevSDK 9.12     (Jul 1997)
** 9.13         Client SDK 2.00 (Nov 1997)
** 9.14         Client SDK 2.01 (Feb 1998)
** 9.15         Client SDK 2.02 (UC4 = Oct 1998)
** 9.16         Client SDK 2.10 (Oct 1998)
** 9.20         Client SDK 2.20 (Dec 1998) ?Y2K-compliant version for 9.x?
** 9.21         Client SDK 2.30 (May 1999)
** 9.30         Client SDK 2.40 (Oct 1999)
** 9.40         Client SDK 2.50 (UC2 = Jun 2000)
** 9.50         Client SDK 2.60 (Nov 2000)
** 9.51         Client SDK 2.70 (Apr 2001)
** 9.52         Client SDK 2.80 (Jun 2002)
** 9.53         Client SDK 2.81 (UC2 = May 2003)
** 2.90         Client SDK 2.90 (Nov 2004)
** 2.91         Client SDK 2.91 (internal only?)
** 3.00         Client SDK 3.00 (Jul 2007)
** 3.50         Client SDK 3.50 (Apr 2008)
** 3.70         Client SDK 3.70 (Oct 2010)
** 4.10         Client SDK 4.10 (Mar 2013)
**
** All versions of ESQL/C prior to 5.10, plus versions 6.x, 7.x
** (with the possible, marginal, exception of 7.24), 8.x, 9.0x,
** 9.1x are truly obsolete.
*/

#ifndef ESQLC_H
#define ESQLC_H

#ifdef MAIN_PROGRAM
#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_esqlc_h[] = "@(#)$Id: esqlc.h,v 2013.1 2013/02/06 18:59:31 jleffler Exp $";
#endif /* lint */
#endif /* MAIN_PROGRAM */

#ifdef HAVE_CONFIG_H
/*
** Needed to resolve const-ness problems on AIX 4.2, thanks to the ESQL/C
** headers in CSDK 2.10, 2.30, etc.
*/
#include "config.h"
#endif /* HAVE_CONFIG_H */

/* If ESQLC_VERSION isn't defined, use version 0 */
#ifndef ESQLC_VERSION
#define ESQLC_VERSION 0
#endif /* ESQLC_VERSION */

/* ESQLC_EFFVERSION - set to 960 for CSDK 2.90, 970 for 3.00, 975 for 3.50 up to 3.99 */
#undef ESQLC_EFFVERSION
#if     ESQLC_VERSION >= 290 && ESQLC_VERSION < 300
#define ESQLC_EFFVERSION 960
#elif   ESQLC_VERSION >= 300 && ESQLC_VERSION < 350
#define ESQLC_EFFVERSION 970
#elif   ESQLC_VERSION >= 350 && ESQLC_VERSION < 400
#define ESQLC_EFFVERSION 975
#elif   ESQLC_VERSION >= 400 && ESQLC_VERSION < 500
#define ESQLC_EFFVERSION 980
#else
#define ESQLC_EFFVERSION ESQLC_VERSION
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

/*
** Some C compilers which can support prototypes do not set __STDC__ at
** all; the C compiler on AIX 4.2 is a case in point.  In some versions
** of ESQL/C (CSDK 2.10, CSDK 2.30, etc), decimal.h and datetime.h only
** declare the function prototypes if __STDC__ is set or if __cplusplus
** is set.  Internally, they set STDC_FLAG to 1 and declare the
** prototypes if STDC_FLAG is set.  All the compilers supported by JLSS
** support prototypes (by definition), so force the prototypes unless
** JLSS_DO_NOT_FORCE_PROTOTYPES is set.  Consistency is wonderful; in
** some versions of ESQL/C (CSDK 2.10, CSDK 2.30, etc), sqlhdr.h uses a
** macro STDC_ENABLE instead of STDC_FLAG.
**
** To complete our happiness, in some versions of ESQL/C (CSDK 2.10,
** CSDK 2.30) sqliapi.h uses neither STDC_FLAG nor STDC_ENABLE, but
** tests directly on __STDC__ and __cplusplus.  So, for sqliapi.h, we
** have to set __STDC__ if it is not already set.  Not all C compilers
** will allow you to do this (and, specifically, the AIX compiler does
** not allow this).  So, we have to live without prototypes from
** sqliapi.h on AIX, and #undef const at the end.  This was reported as
** PTS Bug B118413, but won't be fixed before CSDK 2.50 at the earliest.
*/
#ifndef JLSS_DO_NOT_FORCE_PROTOTYPES
#ifndef STDC_FLAG
#define STDC_FLAG 1
#endif /* STDC_FLAG */
#ifndef STDC_ENABLE
#define STDC_ENABLE 1
#endif /* STDC_ENABLE */
#endif /* JLSS_DO_NOT_FORCE_PROTOTYPES */

/*
** AIX pre-empts the use of loc_t (by declaring a type of that name in
** the header file /usr/include/sys/localedef31.h, as it is entitled to
** do according to POSIX.1, if not ISO C).  The standard workaround is
** to define _H_LOCALEDEF on the compiler command line; doing it in this
** header usually does not work.
*/

/* -- Include Files */

#include <datetime.h>
#include <decimal.h>
#include <locator.h>
#include <sqlca.h>
#include <sqlda.h>
#include <sqlstype.h>
#include <sqltypes.h>
#include <varchar.h>

#if ESQLC_EFFVERSION >= 900
#include <int8.h>
#endif /* ESQLC_EFFVERSION */

/* _WIN32 (Windows 95/NT code from Harald Ums <Harald.Ums@sevensys.de> */

#if ESQLC_EFFVERSION < 500
/* No prototypes available -- for earlier versions, you are on your own! */
/* NB: Contact the author for 4.x prototypes */
#elif ESQLC_EFFVERSION < 600

/* For ESQL 5.x - used by OnLine 5.x */

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

/*
** ClientSDK 2.00 or later needs sqliapi.h.  The ESQL/C compiler for
** ClientSDK 2.00 reports version 9.13; the ESQL/C compiler for
** ClientSDK 2.01 reports version 9.14.
*/
#if ESQLC_EFFVERSION >= 913
#define HAVE_SQLIAPI_H
#endif

#ifdef HAVE_SQLIAPI_H
#include <sqliapi.h>
#undef const
#endif /* HAVE_SQLIAPI_H */

#ifdef _WIN32
#include <sqlproto.h>
#else
#if ESQLC_VERSION >= 720 && ESQLC_VERSION < 730
#include "esql7_20.h"
#endif /* ESQLC_VERSION is 7.2x */

extern int      sqgetdbs(int *ret_fcnt,
                         char **fnames,
                         int fnsize,
                         char *farea,
                         int fasize);
#endif /* _WIN32 */

#endif /* ESQLC_VERSION */

/*
** Some code, notably esqlutil.h, relies on the typedef for value_t.
** However, value.h is not included by sqlhdr.h earlier than 7.20.
** The problem was found by David Edge <dedge@ak.blm.gov> in 7.10.UC1
** on AIX 4.2.1 and was confirmed on Solaris 2.6 with ESQL/C versions
** 5.08, 4.12, and 6.00.  Robert E Wyrick <rob@wyrick.org> had the
** problem with version 8.11.  Versions 8.00 through 8.1x probably had
** the same problem.  XPS 8.20 uses ClientSDK and hence ESQL/C 9.x.
** And the 7.2x version of sqlhdr.h only includes <value.h> when
** __STDC__ is defined, which makes the version-specific testing too
** complex.
**
** The symbol MAXADDR is defined in value.h.  The 4.12 and 5.08
** versions of value.h do not prevent multiple includes, leading to
** problems.  This test is not perfect; if code after #include
** "esqlc.h" includes value.h explicitly, it will not compile under
** many versions of ESQL/C.
*/
#ifndef MAXADDR
#include <value.h>
#endif /* MAXADDR */

/*
** Supply missing type information for IUS (IDS/UDO) data types.
** Two edged sword; it means you have to test rather carefully in
** your code whether to build with IUS data types or not.
** Test: ESQLC_IUSTYPES for BOOLEAN, INT8, SERIAL8, LVARCHAR +
**       collection, row, distinct, BLOB, CLOB types and UDTs.
** Test: ESQLC_BIGINT for BIGINT and BIGSERIAL.
*/
#include "esql_ius.h"

/*
** JL 2001-01-23:
** Supply machine and version independent type names and printing
** macros.  Use the ixType names in code that should port to 64-bit
** environments with minimal fuss.  Note that int4 etc are defined
** with CSDK 2.30 (ESQL/C 9.21) and later versions.
** Note that the version-dependent headers such as esql4_00.h do not
** need to be modified to use these types -- they are not version
** independent, by definition.
*/
#include "esqltype.h"

/* -- Constant Definitions */

/* A table name may be: database@server:"owner".table */
/* This contains 5 punctuation characters and a null */
/*
** Note that from 9.2 up (and maybe 7.3 up and maybe from 8.3
** up), identifier names can be much longer -- up to 128 bytes
** each -- and user names can be up to 32 characters.
** Prior versions only allowed 18 characters for table, column,
** database and server names, and only 8 characters for user
** identifiers.
** JL 2004-08-24: Simplify - assume longer names.
*/
#define SQL_NAMELEN 128
#define SQL_USERLEN 32

/*
** Note that a fully specified table name in an SQL statement could be:
** 128       characters database name +
** 128       characters server name +
** (2*128+2) characters table name (all double quotes) +
** (2*32+2)  characters owner name (all double quotes) +
** 4         characters for punctuation and terminal null
** = 584     characters in total.
** Database name and server name cannot contain non-alphanumerics.
*/
#define SQL_TABNAMELEN  (3 * SQL_NAMELEN + SQL_USERLEN + sizeof("@:''."))
#define SQL_COLNAMELEN  (SQL_NAMELEN + 1)

#define loc_mode    lc_union.lc_file.lc_mode
#define sqlva       sqlvar_struct

/* -- Type Definitions */

/*
** Using ifx_loc_t directly with ESQL/C 3.50 generates (bogus) -33014 warnings.
** Continue to use loc_t - under protest.
** On AIX, loc_t is not typedef'd, to avoid conflicts with <sys/localedef32.h>.
** So, patch up the omission, and continue with the other workarounds.
*/
#if defined(ESQLC_AIX_LOC_T) && defined(ESQLC_IFX_LOC_T)
typedef ifx_loc_t loc_t;
#endif /* ESQLC_AIX_LOC_T && ESQLC_IFX_LOC_T */

typedef loc_t           Blob;
typedef struct decimal  Decimal;
typedef struct dtime    Datetime;
typedef struct intrvl   Interval;
typedef struct sqlca_s  Sqlca;
typedef struct sqlda    Sqlda;
typedef struct sqlva    Sqlva;

#if ESQLC_EFFVERSION >= 900

/* Type for casting dynamic SQL types to LVARCHAR */
typedef void *Lvarchar;

#endif

/* ESQL/C Features */
/* The ESQL/C compiler versions are defined in esqlinfo.h by autoconf */
/* Variable cursors and stored procedures were introduced in 5.00 */
/* They are essentially always available in ESQL/C.  */
/* Some (old) versions of XPS did not support stored procedures. */
/* Some (old) versions of XPS did not support BYTE and TEXT blobs. */
#define ESQLC_STORED_PROCEDURES     1
#define ESQLC_VARIABLE_CURSORS      1

#if ESQLC_EFFVERSION >= 600
#define ESQLC_CONNECT       1
#define ESQLC_SQLSTATE      1
#define ESQLC_RGETLMSG      1
#endif

#if ESQLC_EFFVERSION >= 720
#define ESQLC_CONNECT_DORMANT       1
#endif

#if ESQLC_EFFVERSION >= 900
#define ESQLC_IUSTYPES      1
#define ESQLC_IUS_TYPES     1   /* Deprecated - use ESQL_IUSTYPES */
#endif

#if ESQLC_EFFVERSION >= 975
#define ESQLC_BIGINT        1
#endif

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* ESQLC_H */
