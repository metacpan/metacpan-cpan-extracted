/*
@(#)Purpose:         Map Informix SQL Types to ODBC Types
@(#)Author:          J Leffler
@(#)Copyright:       1997-98,2008 Jonathan Leffler (JLSS)
@(#)Copyright:       2000         Informix Software Inc
@(#)Copyright:       2002         IBM
@(#)Product:         Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
*/

/*TABSTOP=4*/

#include <sqltypes.h>
#include "esqlc.h"
#include "odbctype.h"

/* Cover pre-6.00 versions of ESQL/C */
#ifndef SQLNCHAR
#define SQLNCHAR	-1
#endif
#ifndef SQLNVCHAR
#define SQLNVCHAR	-2
#endif

typedef enum IxSQLType
{
	ix_CHAR	      = SQLCHAR,
	ix_NCHAR      = SQLNCHAR,
	ix_VARCHAR    = SQLVCHAR,
	ix_NVARCHAR   = SQLNVCHAR,
	ix_INTEGER    = SQLINT,
#ifdef SQLBOOL
	ix_BOOL       = SQLBOOL,
#endif
#ifdef SQLLVARCHAR
	ix_LVARCHAR   = SQLLVARCHAR,
#endif
	ix_SMALLINT   = SQLSMINT,
	ix_SERIAL     = SQLSERIAL,
	ix_TEXT       = SQLTEXT,
	ix_BYTE       = SQLBYTES,
	ix_FLOAT      = SQLFLOAT,
	ix_SMALLFLOAT = SQLSMFLOAT,
	ix_DECIMAL    = SQLDECIMAL,
	ix_MONEY      = SQLMONEY,
	ix_DATETIME   = SQLDTIME,
	ix_INTERVAL   = SQLINTERVAL,
	ix_DATE       = SQLDATE
} IxSQLType;

#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_odbctype_c[] = "@(#)$Id: odbctype.c,v 2008.1 2008/04/17 21:13:41 jleffler Exp $";
#endif /* lint */

/* Map Informix DATETIME types to equivalent ODBC types */
static int
dtmap(int collen)
{
	int             tu_s = TU_START(collen);
	int             tu_e = TU_END(collen);
	int             odbctype;

	/*
    ** Most of Informix's DATETIME types do not have corresponding ODBC types.
    ** Regard them as undefined types (SQL_TYPE_NULL).
    */
	if (tu_s == TU_YEAR && tu_e == TU_DAY)
		odbctype = SQL_DATE;
	else if (tu_s == TU_YEAR && tu_e >= TU_SECOND)
		odbctype = SQL_TIMESTAMP;
	else if (tu_s == TU_HOUR && tu_e >= TU_SECOND)
		odbctype = SQL_TIME;
	else
		odbctype = SQL_CHAR;
	return(odbctype);
}

/* Map Informix INTERVAL types to equivalent ODBC types */
static int
ivmap(int collen)
{
	int             tu_s = TU_START(collen);
	int             tu_e = TU_END(collen);
	int             odbctype;

	if (tu_s == TU_YEAR && tu_e == TU_YEAR)
		odbctype = SQL_INTERVAL_YEAR;
	else if (tu_s == TU_YEAR && tu_e == TU_MONTH)
		odbctype = SQL_INTERVAL_YEAR_TO_MONTH;
	else if (tu_s == TU_MONTH && tu_e == TU_MONTH)
		odbctype = SQL_INTERVAL_MONTH;
	else if (tu_s == TU_DAY && tu_e == TU_DAY)
		odbctype = SQL_INTERVAL_DAY;
	else if (tu_s == TU_DAY && tu_e == TU_HOUR)
		odbctype = SQL_INTERVAL_DAY_TO_HOUR;
	else if (tu_s == TU_DAY && tu_e == TU_MINUTE)
		odbctype = SQL_INTERVAL_DAY_TO_MINUTE;
	else if (tu_s == TU_DAY && tu_e >= TU_SECOND)
		odbctype = SQL_INTERVAL_DAY_TO_SECOND;
	else if (tu_s == TU_HOUR && tu_e == TU_HOUR)
		odbctype = SQL_INTERVAL_HOUR;
	else if (tu_s == TU_HOUR && tu_e == TU_MINUTE)
		odbctype = SQL_INTERVAL_HOUR_TO_MINUTE;
	else if (tu_s == TU_HOUR && tu_e >= TU_SECOND)
		odbctype = SQL_INTERVAL_HOUR_TO_SECOND;
	else if (tu_s == TU_MINUTE && tu_e == TU_MINUTE)
		odbctype = SQL_INTERVAL_MINUTE;
	else if (tu_s == TU_MINUTE && tu_e >= TU_SECOND)
		odbctype = SQL_INTERVAL_MINUTE_TO_SECOND;
	else if (tu_s >= TU_SECOND && tu_e >= TU_SECOND)
		odbctype = SQL_INTERVAL_SECOND;
	else
	{
		/**
	     ** Should never happen.
	     ** ODBC supports all interval types Informix does
	     */
		odbctype = SQL_CHAR;
	}
	return(odbctype);
}

/* Map Informix types to equivalent ODBC types */
int
map_type_ifmx_to_odbc(int coltype, int collen)
{
	IxSQLType       ifmxtype = (IxSQLType)coltype;
	int             odbctype;

	switch (ifmxtype)
	{
	case ix_CHAR:
		odbctype = SQL_CHAR;
		break;
	case ix_NCHAR:
		odbctype = SQL_CHAR;
		break;
#ifdef SQLLVARCHAR
	case ix_LVARCHAR:
		odbctype = SQL_LONGVARCHAR;
		break;
#endif
	case ix_VARCHAR:
		odbctype = SQL_VARCHAR;
		break;
	case ix_NVARCHAR:
		odbctype = SQL_VARCHAR;
		break;
	case ix_INTEGER:
		odbctype = SQL_INTEGER;
		break;
#ifdef SQLBOOL
	case ix_BOOL:
#endif
	case ix_SMALLINT:
		odbctype = SQL_SMALLINT;
		break;
	case ix_SERIAL:
		odbctype = SQL_INTEGER;
		break;
	case ix_TEXT:
		odbctype = SQL_LONGVARCHAR;
		break;
	case ix_DATE:
		odbctype = SQL_DATE;
		break;
	case ix_BYTE:
		odbctype = SQL_LONGVARBINARY;
		break;
	case ix_FLOAT:
		odbctype = SQL_DOUBLE;
		break;
	case ix_SMALLFLOAT:
		odbctype = SQL_REAL;
		break;
	case ix_DECIMAL:
		odbctype = SQL_DECIMAL;
		break;
	case ix_MONEY:
		odbctype = SQL_DECIMAL;
		break;
	case ix_DATETIME:
		odbctype = dtmap(collen);
		break;
	case ix_INTERVAL:
		odbctype = ivmap(collen);
		break;
	default:
		/* Can only happen if some previously unknown type arrives */
		/* The most likely case is with Informix-Universal Server */
		odbctype = SQL_LONGVARCHAR;
		break;
	}

	return(odbctype);
}

/* Map Informix type information to ODBC precision */
int
map_prec_ifmx_to_odbc(int coltype, int collen)
{
	IxSQLType       ifmxtype = (IxSQLType)coltype;
	int             odbcprec;

	switch (ifmxtype)
	{
	case ix_CHAR:
	case ix_NCHAR:
		odbcprec = collen;
		break;
	case ix_VARCHAR:
	case ix_NVARCHAR:
		odbcprec = VCMAX(collen);
		break;
	case ix_INTEGER:
	case ix_SERIAL:
		odbcprec = 10;
		break;
	case ix_SMALLINT:
#ifdef SQLBOOL
	case ix_BOOL:
#endif
		odbcprec = 5;
		break;
	case ix_FLOAT:
		odbcprec = 15;
		break;
	case ix_SMALLFLOAT:
		odbcprec = 7;
		break;
	case ix_DECIMAL:
	case ix_MONEY:
		odbcprec = PRECTOT(collen);
		break;
	case ix_DATETIME:
	case ix_INTERVAL:
		odbcprec = rtypwidth(coltype, collen);
		break;

	case ix_TEXT:
	case ix_BYTE:
		odbcprec = SQL_NO_TOTAL;
		break;

	default:
		/* Can only happen if some previously unknown type arrives */
		/* The most likely case is with Informix-Universal Server */
		odbcprec = SQL_NO_TOTAL;
		break;
	}

	return(odbcprec);
}

int
map_scale_ifmx_to_odbc(int coltype, int collen)
{
	IxSQLType       ifmxtype = (IxSQLType)coltype;
	int             odbcscale;

	switch (ifmxtype)
	{
	case ix_CHAR:
	case ix_NCHAR:
	case ix_VARCHAR:
	case ix_NVARCHAR:
#ifdef SQLLVARCHAR
	case ix_LVARCHAR:
#endif
	case ix_TEXT:
	case ix_BYTE:
	case ix_FLOAT:
	case ix_SMALLFLOAT:
		odbcscale = SQL_NO_TOTAL;
		break;
	case ix_INTEGER:
	case ix_SMALLINT:
#ifdef SQLBOOL
	case ix_BOOL:
#endif
	case ix_SERIAL:
		odbcscale = 0;
		break;

	case ix_DECIMAL:
	case ix_MONEY:
		odbcscale = PRECDEC(collen);
		if (odbcscale == 0xFF)
			odbcscale = SQL_NO_TOTAL;	/* Floating-point */
		break;
	case ix_DATETIME:
	case ix_INTERVAL:
		odbcscale = TU_END(collen) - TU_SECOND;
		if (odbcscale < 0)
			odbcscale = SQL_NO_TOTAL;	/* No seconds component, no scale */
		break;
	default:
		/* Can only happen if some previously unknown type arrives */
		/* The most likely case is with Informix-Universal Server */
		odbcscale = SQL_NO_TOTAL;
		break;
	}

	return(odbcscale);
}
