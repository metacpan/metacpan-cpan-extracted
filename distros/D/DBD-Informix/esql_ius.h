/*
@(#)File:           $RCSfile: esql_ius.h,v $
@(#)Version:        $Revision: 2008.2 $
@(#)Last changed:   $Date: 2008/03/08 19:34:28 $
@(#)Purpose:        Supply key macros from IUS version of sqltypes.h
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1998,2003-06,2008
@(#)Product:        Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28)
*/

/*TABSTOP=4*/

#ifndef ESQL_IUS_H
#define ESQL_IUS_H

#ifdef MAIN_PROGRAM
#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_esql_ius_h[] = "@(#)$Id: esql_ius.h,v 2008.2 2008/03/08 19:34:28 jleffler Exp $";
#endif /* lint */
#endif /* MAIN_PROGRAM */

#include "sqltypes.h"   /* Include the official version */

/* C types */
#ifndef CINT8TYPE
#define CINT8TYPE   117
#endif
#ifndef CCOLLTYPE
#define CCOLLTYPE       118
#endif
#ifndef CLVCHARTYPE
#define CLVCHARTYPE     119
#endif
#ifndef CFIXBINTYPE
#define CFIXBINTYPE     120
#endif
#ifndef CVARBINTYPE
#define CVARBINTYPE     121
#endif
#ifndef CBOOLTYPE
#define CBOOLTYPE       122
#endif
#ifndef CROWTYPE
#define CROWTYPE        123
#endif
#ifndef CLVCHARPTRTYPE
#define CLVCHARPTRTYPE  124
#endif
#ifndef CBIGINTTYPE
#define CBIGINTTYPE     125
#endif

/* SQL types */
#ifndef SQLNCHAR
#define SQLNCHAR        15
#endif
#ifndef SQLNVCHAR
#define SQLNVCHAR       16
#endif
#ifndef SQLINT8
#define SQLINT8         17
#endif
#ifndef SQLSERIAL8
#define SQLSERIAL8      18
#endif
#ifndef SQLSET
#define SQLSET          19
#endif
#ifndef SQLMULTISET
#define SQLMULTISET     20
#endif
#ifndef SQLLIST
#define SQLLIST         21
#endif
#ifndef SQLROW
#define SQLROW          22
#endif
#ifndef SQLCOLLECTION
#define SQLCOLLECTION   23
#endif
#ifndef SQLROWREF
#define SQLROWREF       24
#endif
/* Note: SQLXXX values from 25 through 39 are reserved. */
#ifndef SQLUDTVAR
#define SQLUDTVAR       40
#endif
#ifndef SQLUDTFIXED
#define SQLUDTFIXED     41
#endif
#ifndef SQLREFSER8
#define SQLREFSER8      42
#endif
#ifndef SQLLVARCHAR
#define SQLLVARCHAR     43
#endif
#ifndef SQLSENDRECV
#define SQLSENDRECV     44
#endif
#ifndef SQLBOOL
#define SQLBOOL         45
#endif
#ifndef SQLIMPEXP
#define SQLIMPEXP       46
#endif
#ifndef SQLIMPEXPBIN
#define SQLIMPEXPBIN    47
#endif

#ifndef SQLDISTINCT
#define SQLDISTINCT     0x0800
#endif

#ifndef ISDISTINCTTYPE
#define ISDISTINCTTYPE(x)   ((x) & SQLDISTINCT)
#endif

#ifndef SQLUNKNOWN
#define SQLUNKNOWN   	51
#endif

#ifndef SQLINFXBIGINT
#define SQLINFXBIGINT   52 /* Avoid collision with ODBC */
#endif

#ifndef SQLBIGSERIAL
#define SQLBIGSERIAL    53
#endif

#endif /* ESQL_IUS_H */
