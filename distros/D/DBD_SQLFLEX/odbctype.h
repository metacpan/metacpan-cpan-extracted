/*
@(#)File:            $RCSfile: odbctype.h,v $
@(#)Version:         $Revision: 54.3 $
@(#)Last changed:    $Date: 1997/04/01 16:22:30 $
@(#)Purpose:         Surrogate ODBC header for DBD::Sqlflex
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1997
@(#)Product:         $Product: DBD::Sqlflex Version 0.58 (1998-01-15) $
*/

/*TABSTOP=4*/

#ifndef ODBCTYPE_H
#define ODBCTYPE_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char odbctype_h[] = "@(#)$Id: odbctype.h,v 54.3 1997/04/01 16:22:30 johnl Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

/* Extracts from sql.h and sqlext.h at ODBC Version 2.10 */

/* generally useful constants */
#if (ODBCVER >= 0x0200)
#define SQL_SPEC_MAJOR            2     /* Major version of specification  */
#define SQL_SPEC_MINOR            10    /* Minor version of specification  */
#define SQL_SPEC_STRING     "02.10"     /* String constant for version     */
#endif  /* ODBCVER >= 0x0200 */

/* Standard SQL datatypes, using ANSI type numbering */
#define SQL_CHAR                1
#define SQL_NUMERIC             2
#define SQL_DECIMAL             3
#define SQL_INTEGER             4
#define SQL_SMALLINT            5
#define SQL_FLOAT               6
#define SQL_REAL                7
#define SQL_DOUBLE              8
#define SQL_VARCHAR             12

#define SQL_TYPE_MIN            SQL_CHAR
#define SQL_TYPE_NULL           0
#define SQL_TYPE_MAX            SQL_VARCHAR

/* SQL extended datatypes */
#define SQL_DATE                         9
#define SQL_TIME                        10
#define SQL_TIMESTAMP                   11
#define SQL_LONGVARCHAR                 (-1)
#define SQL_BINARY                      (-2)
#define SQL_VARBINARY                   (-3)
#define SQL_LONGVARBINARY               (-4)
#define SQL_BIGINT                      (-5)
#define SQL_TINYINT                     (-6)
#define SQL_BIT                         (-7)

#define SQL_INTERVAL_YEAR               (-80)
#define SQL_INTERVAL_MONTH              (-81)
#define SQL_INTERVAL_YEAR_TO_MONTH      (-82)
#define SQL_INTERVAL_DAY                (-83)
#define SQL_INTERVAL_HOUR               (-84)
#define SQL_INTERVAL_MINUTE             (-85)
#define SQL_INTERVAL_SECOND             (-86)
#define SQL_INTERVAL_DAY_TO_HOUR        (-87)
#define SQL_INTERVAL_DAY_TO_MINUTE      (-88)
#define SQL_INTERVAL_DAY_TO_SECOND      (-89)
#define SQL_INTERVAL_HOUR_TO_MINUTE     (-90)
#define SQL_INTERVAL_HOUR_TO_SECOND     (-91)
#define SQL_INTERVAL_MINUTE_TO_SECOND   (-92)
#define SQL_UNICODE                     (-95)

/* Special return values for SQLGetData */
#define SQL_NO_TOTAL		(-4)

#endif  /* ODBCTYPE_H */
