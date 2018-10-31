/*
@(#)File:           $RCSfile: esqltype.h,v $
@(#)Version:        $Revision: 2018.1 $
@(#)Last changed:   $Date: 2018/05/11 06:13:38 $
@(#)Purpose:        Platform and Version Independent Types for ESQL/C
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 2001-2018
@(#)Product:        Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31)
*/

/*TABSTOP=4*/

#ifndef ESQLTYPE_H
#define ESQLTYPE_H

#ifdef MAIN_PROGRAM
#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_esqltype_h[] = "@(#)$Id: esqltype.h,v 2018.1 2018/05/11 06:13:38 jleffler Exp $";
#endif /* lint */
#endif /* MAIN_PROGRAM */

/*
** Define Informix types:
** ixInt1   - signed, 1-byte integer
** ixInt2   - signed, 2-byte integer
** ixInt4   - signed, 4-byte integer
** ixInt8   - signed, 8-byte integer
** ixMint   - signed machine integer
** ixMlong  - signed machine long
** ixUint1  - unsigned, 1-byte integer
** ixUint2  - unsigned, 2-byte integer
** ixUint4  - unsigned, 4-byte integer
** ixUint8  - unsigned, 8-byte integer
** ixUmint  - unsigned machine integer
** ixUmlong - unsigned machine long
**
** Also attempt to define macros for printf formats for the various
** types.  This is based on the ISO C:1999 (ISO/IEC 9899:1999)
** <inttypes.h> style.  It is easy enough for the pre-9.21 versions of
** ESQL/C.  It is very much more difficult for the versions with the
** "ifxtypes.h" header which does *not* define such macros.  However,
** the ifxtypes.h header does define macros MI_LONG_SIZE and MI_PTR_SIZE
** which define the number of bits in a long and a pointer respectively.
** These values can be used to to decide the mapping.
**
** JL 2005-06-22: Note ESQL/C 2.90 is more recent than ESQL/C 9.53.
** JL 2007-02-09: Note ESQL/C 3.00 is in the field too.
** JL 2008-03-08: Note ESQL/C 3.50 is available in beta and includes
**                BIGINT.  This code assumes that 8-byte integers (as
**                long long if nothing else) are supported everywhere.
*/

#if ESQLC_VERSION >= 700 && ESQLC_VERSION < 921

#include <limits.h>

#if LONG_MAX > 2147483647L

/*
** In early CSDK version on 64-bit platforms, was the '4-byte integer'
** modelled by a long or an int?  The manual said 'long'.
*/

#define MI_LONG_SIZE 64
#define MI_PTR_SIZE 64

typedef signed char     ixInt1;
typedef short           ixInt2;
typedef long            ixInt4;
typedef int             ixMint;
typedef long            ixMlong;
typedef unsigned char   ixUint1;
typedef unsigned short  ixUint2;
typedef unsigned long   ixUint4;
typedef unsigned int    ixMuint;
typedef unsigned long   ixMulong;

#ifndef NO_EIGHTBYTE_INTEGERS
typedef long            ixInt8;
typedef unsigned long   ixUint8;
#endif /* NO_EIGHTBYTE_INTEGERS */

#else

/* Regular 32-bit platform */
#define MI_LONG_SIZE 32
#define MI_PTR_SIZE 32

typedef signed char         ixInt1;
typedef short               ixInt2;
typedef long                ixInt4;
typedef int                 ixMint;
typedef long                ixMlong;
typedef unsigned char       ixUint1;
typedef unsigned short      ixUint2;
typedef unsigned long       ixUint4;
typedef unsigned int        ixMuint;
typedef unsigned long       ixMulong;

#ifndef NO_EIGHTBYTE_INTEGERS
typedef long long           ixInt8;
typedef unsigned long long  ixUint8;
#endif /* NO_EIGHTBYTE_INTEGERS */

#endif /* LONG_MAX > 2147483647L */

/* Omitted typedefs for MCHAR and MSHORT present in ifxtypes.h */
/* typedef char MCHAR; typedef short MSHORT; */

#elif ESQLC_VERSION >= 500 && ESQLC_VERSION < 700

/* Assume 32-bit platform */
/* Regular 32-bit platform */
#define MI_LONG_SIZE 32
#define MI_PTR_SIZE 32

typedef signed char         ixInt1;
typedef short               ixInt2;
typedef long                ixInt4;
typedef int                 ixMint;
typedef long                ixMlong;
typedef unsigned char       ixUint1;
typedef unsigned short      ixUint2;
typedef unsigned long       ixUint4;
typedef unsigned int        ixMuint;
typedef unsigned long       ixMulong;

#ifndef NO_EIGHTBYTE_INTEGERS
typedef long long           ixInt8;
typedef unsigned long long  ixUint8;
#endif /* NO_EIGHTBYTE_INTEGERS */

#else

/* ESQLC_VERSION >= 921 || (ESQLC_VERSION >= 290 && ESQLC_VERSION <= 500) */
/* ifxtypes.h provides typedefs for int1, uint2, muint, etc */

#include "ifxtypes.h"

typedef int1    ixInt1;
typedef int2    ixInt2;
typedef int4    ixInt4;

typedef mint    ixMint;
typedef mlong   ixMlong;

typedef uint1   ixUint1;
typedef uint2   ixUint2;
typedef uint4   ixUint4;

typedef muint   ixMuint;
typedef mulong  ixMulong;

/* It is not clear that this is the best way to factor these types */
#if ESQLC_EFFVERSION >= 975

typedef bigint  ixInt8;
typedef ubigint ixUint8;

#elif MI_LONG_SIZE == 64

#ifndef NO_EIGHTBYTE_INTEGERS
typedef long            ixInt8;
typedef unsigned long   ixUint8;
#endif /* NO_EIGHTBYTE_INTEGERS */

#else

#ifndef NO_EIGHTBYTE_INTEGERS
typedef long long           ixInt8;
typedef unsigned long long  ixUint8;
#endif /* NO_EIGHTBYTE_INTEGERS */

#endif /* ESQLC_EFFVERSION or MI_LONG_SIZE */

#endif /* ESQLC_VERSION 700..921 */

/***************************/
/* printf() format strings */
/***************************/

#if MI_LONG_SIZE == 32

#define PRIX_ixInt1     "X"
#define PRIX_ixInt2     "X"
#define PRIX_ixInt4     "lX"
#define PRIX_ixInt8     "llX"
#define PRIX_ixMint     "X"
#define PRIX_ixMlong    "lX"
#define PRIX_ixMuint    "X"
#define PRIX_ixMulong   "lX"
#define PRIX_ixUint1    "X"
#define PRIX_ixUint2    "X"
#define PRIX_ixUint4    "lX"
#define PRIX_ixUint8    "llX"

#define PRId_ixInt1     "d"
#define PRId_ixInt2     "d"
#define PRId_ixInt4     "ld"
#define PRId_ixInt8     "lld"
#define PRId_ixMint     "d"
#define PRId_ixMlong    "ld"
#define PRId_ixMuint    "d"
#define PRId_ixMulong   "ld"
#define PRId_ixUint1    "d"
#define PRId_ixUint2    "d"
#define PRId_ixUint4    "ld"
#define PRId_ixUint8    "lld"

#define PRIo_ixInt1     "o"
#define PRIo_ixInt2     "o"
#define PRIo_ixInt4     "lo"
#define PRIo_ixInt8     "llo"
#define PRIo_ixMint     "o"
#define PRIo_ixMlong    "lo"
#define PRIo_ixMuint    "o"
#define PRIo_ixMulong   "lo"
#define PRIo_ixUint1    "o"
#define PRIo_ixUint2    "o"
#define PRIo_ixUint4    "lo"
#define PRIo_ixUint8    "llo"

#define PRIu_ixInt1     "u"
#define PRIu_ixInt2     "u"
#define PRIu_ixInt4     "lu"
#define PRIu_ixInt8     "llu"
#define PRIu_ixMint     "u"
#define PRIu_ixMlong    "lu"
#define PRIu_ixMuint    "u"
#define PRIu_ixMulong   "lu"
#define PRIu_ixUint1    "u"
#define PRIu_ixUint2    "u"
#define PRIu_ixUint4    "lu"
#define PRIu_ixUint8    "llu"

#define PRIx_ixInt1     "x"
#define PRIx_ixInt2     "x"
#define PRIx_ixInt4     "lx"
#define PRIx_ixInt8     "llx"
#define PRIx_ixMint     "x"
#define PRIx_ixMlong    "lx"
#define PRIx_ixMuint    "x"
#define PRIx_ixMulong   "lx"
#define PRIx_ixUint1    "x"
#define PRIx_ixUint2    "x"
#define PRIx_ixUint4    "lx"
#define PRIx_ixUint8    "llx"

#else

/* Assume MI_LONG_SIZE == 64 */
/* Hence, int is a 4-byte quantity */

#define PRIX_ixInt1     "X"
#define PRIX_ixInt2     "X"
#define PRIX_ixInt4     "X"
#define PRIX_ixInt8     "lX"
#define PRIX_ixMint     "X"
#define PRIX_ixMlong    "lX"
#define PRIX_ixMuint    "X"
#define PRIX_ixMulong   "lX"
#define PRIX_ixUint1    "X"
#define PRIX_ixUint2    "X"
#define PRIX_ixUint4    "X"
#define PRIX_ixUint8    "lX"

#define PRId_ixInt1     "d"
#define PRId_ixInt2     "d"
#define PRId_ixInt4     "d"
#define PRId_ixInt8     "ld"
#define PRId_ixMint     "d"
#define PRId_ixMlong    "ld"
#define PRId_ixMuint    "d"
#define PRId_ixMulong   "ld"
#define PRId_ixUint1    "d"
#define PRId_ixUint2    "d"
#define PRId_ixUint4    "d"
#define PRId_ixUint8    "ld"

#define PRIo_ixInt1     "o"
#define PRIo_ixInt2     "o"
#define PRIo_ixInt4     "o"
#define PRIo_ixInt8     "lo"
#define PRIo_ixMint     "o"
#define PRIo_ixMlong    "lo"
#define PRIo_ixMuint    "o"
#define PRIo_ixMulong   "lo"
#define PRIo_ixUint1    "o"
#define PRIo_ixUint2    "o"
#define PRIo_ixUint4    "o"
#define PRIo_ixUint8    "lo"

#define PRIu_ixInt1     "u"
#define PRIu_ixInt2     "u"
#define PRIu_ixInt4     "u"
#define PRIu_ixInt8     "lu"
#define PRIu_ixMint     "u"
#define PRIu_ixMlong    "lu"
#define PRIu_ixMuint    "u"
#define PRIu_ixMulong   "lu"
#define PRIu_ixUint1    "u"
#define PRIu_ixUint2    "u"
#define PRIu_ixUint4    "u"
#define PRIu_ixUint8    "lu"

#define PRIx_ixInt1     "x"
#define PRIx_ixInt2     "x"
#define PRIx_ixInt4     "x"
#define PRIx_ixInt8     "lx"
#define PRIx_ixMint     "x"
#define PRIx_ixMlong    "lx"
#define PRIx_ixMuint    "x"
#define PRIx_ixMulong   "lx"
#define PRIx_ixUint1    "x"
#define PRIx_ixUint2    "x"
#define PRIx_ixUint4    "x"
#define PRIx_ixUint8    "lx"

#endif /* MI_LONG_SIZE */

#endif /* ESQLTYPE_H */
