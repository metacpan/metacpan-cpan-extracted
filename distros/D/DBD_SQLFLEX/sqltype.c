/*
@(#)File:            $RCSfile: sqltype.ec,v $
@(#)Version:         $Revision: 1.12 $
@(#)Last changed:    $Date: 1997/07/08 19:52:44 $
@(#)Purpose:         Convert type and length from Syscolumns to string
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1988-1993,1995-97
@(#)Product:         $Product: DBD::Sqlflex Version 0.58 (1998-01-15) $
*/

/*TABSTOP=4*/
/*LINTLIBRARY*/

#ifndef lint
static const char rcs[] = "@(#)$Id: sqltype.ec,v 1.12 1997/07/08 19:52:44 johnl Exp $";
#endif

#include <string.h>
#include <sqltypes.h>
#include <stdio.h>
#include "esqlperl.h"
#include <datetime.h>

static const char * const sqltypes[] = 
{
	"CHAR",
	"SMALLINT",
	"INTEGER",
	"FLOAT",
	"SMALLFLOAT",
	"DECIMAL",
	"SERIAL",
	"DATE",
	"MONEY",
	"NULL",
	"DATETIME",
	"BYTE",
	"TEXT",
	"VARCHAR",
	"INTERVAL",
	"NCHAR",
	"NVARCHAR",
};

static const char dt_day[] = "DAY";
static const char dt_fraction1[] = "FRACTION(1)";
static const char dt_fraction2[] = "FRACTION(2)";
static const char dt_fraction3[] = "FRACTION(3)";
static const char dt_fraction4[] = "FRACTION(4)";
static const char dt_fraction5[] = "FRACTION(5)";
static const char dt_fraction[] = "FRACTION";
static const char dt_hour[] = "HOUR";
static const char dt_minute[] = "MINUTE";
static const char dt_month[] = "MONTH";
static const char dt_second[] = "SECOND";
static const char dt_unknown[] = "{unknown}";
static const char dt_year[] = "YEAR";

static const char * const dt_fr_ext[] = 
{
	dt_year,
	dt_unknown,
	dt_month,
	dt_unknown,
	dt_day,
	dt_unknown,
	dt_hour,
	dt_unknown,
	dt_minute,
	dt_unknown,
	dt_second,
	dt_unknown,
	dt_fraction,
	dt_unknown,
	dt_unknown,
	dt_unknown
};

static const char * const dt_to_ext[] = 
{
	dt_year,
	dt_unknown,
	dt_month,
	dt_unknown,
	dt_day,
	dt_unknown,
	dt_hour,
	dt_unknown,
	dt_minute,
	dt_unknown,
	dt_second,
	dt_fraction1,
	dt_fraction2,
	dt_fraction3,
	dt_fraction4,
	dt_fraction5
};

static char	typestr[SQLTYPENAME_BUFSIZ];
static int sqlmode = 0;

/*
** Get/Set Type Formatting mode
** If the mode is set to 1, then sqltypename() formats
** INTERVAL HOUR(6) TO HOUR as INTERVAL HOUR(6).
** Otherwise it uses the standard Sqlflex type name.
*/
int sqltypemode(int mode)
{
	int	oldmode = sqlmode;
	sqlmode = mode;
	return(oldmode);
}

char	*sqltypename(int coltype, int collen, char *buffer)
{
	int		precision;
	int		dt_fr;
	int		dt_to;
	int		dt_ld;
	int		vc_min;
	int		vc_max;
	int		scale;

	if (coltype >= 256)
		coltype -= 256;	/* Indicates a not null column */

	switch (coltype)
	{
	case SQLCHAR:
#ifdef SQLNCHAR
	case SQLNCHAR:
#endif /* SQLNCHAR */
		sprintf(buffer, "%s(%d)", sqltypes[coltype], collen);
		break;
	case SQLSMINT:
	case SQLINT:
	case SQLFLOAT:
	case SQLSMFLOAT:
	case SQLDATE:
	case SQLSERIAL:
	case SQLNULL:
	case SQLTEXT:
	case SQLBYTES:
		strcpy(buffer, sqltypes[coltype]);
		break;
	case SQLDECIMAL:
	case SQLMONEY:
		precision = (collen >> 8) & 0xFF;
		scale = (collen & 0xFF);
		if (scale == 0xFF)
			sprintf(buffer, "%s(%d)", sqltypes[coltype], precision);
		else
			sprintf(buffer, "%s(%d,%d)", sqltypes[coltype], precision, scale);
		break;
#if 0
	case SQLVCHAR:
	case SQLNVCHAR:
		vc_min = VCMIN(collen);
		vc_max = VCMAX(collen);
		if (vc_min == 0)
			sprintf(buffer, "%s(%d)", sqltypes[coltype], vc_max);
		else
			sprintf(buffer, "%s(%d,%d)", sqltypes[coltype], vc_max, vc_min);
		break;
#endif
	case SQLDTIME:
		dt_fr = TU_START(collen);
		dt_to = TU_END(collen);
		if (sqlmode != 1)
			sprintf(buffer, "%s %s TO %s", sqltypes[coltype], dt_fr_ext[dt_fr],
					dt_to_ext[dt_to]);
		else if (dt_fr == TU_FRAC)
			sprintf(buffer, "%s %s", sqltypes[coltype], dt_to_ext[dt_to]);
		else if (dt_fr == dt_to)
			sprintf(buffer, "%s %s", sqltypes[coltype], dt_to_ext[dt_to]);
		else
			sprintf(buffer, "%s %s TO %s", sqltypes[coltype], dt_fr_ext[dt_fr],
					dt_to_ext[dt_to]);
		break;
	case SQLINTERVAL:
		dt_fr = TU_START(collen);
		dt_to = TU_END(collen);
		dt_ld = TU_FLEN(collen);
		if (sqlmode != 1 && dt_fr == TU_FRAC)
			sprintf(buffer, "%s %s TO %s", sqltypes[coltype],
					dt_fr_ext[dt_fr], dt_to_ext[dt_to]);
		else if (sqlmode != 1)
			sprintf(buffer, "%s %s(%d) TO %s", sqltypes[coltype],
					dt_fr_ext[dt_fr], dt_ld, dt_to_ext[dt_to]);
		else if (dt_fr == TU_FRAC)
			sprintf(buffer, "%s %s", sqltypes[coltype], dt_to_ext[dt_to]);
		else if (dt_fr == dt_to)
			sprintf(buffer, "%s %s(%d)", sqltypes[coltype], dt_to_ext[dt_to],
					dt_ld);
		else
			sprintf(buffer, "%s %s(%d) TO %s", sqltypes[coltype],
					dt_fr_ext[dt_fr], dt_ld, dt_to_ext[dt_to]);
		break;
	default:
		sprintf(buffer, "Unknown type %d, len %d", coltype, collen);
		break;
	}
	return(buffer);
}

/* For backwards compatability only */
/* Not thread-safe because it uses static return data */
const char	*sqltype(int coltype, int collen)
{
	return(sqltypename(coltype, collen, typestr));
}

#ifdef TEST

#define DIM(x)	(sizeof(x)/sizeof(*(x)))

typedef struct	Typelist
{
	char	*code;
	int		coltype;
	int		collen;
}	Typelist;

static Typelist	types[] =
{
	{	"serial",							262,		4		},
	{	"char",								0,			10		},
	{	"date",								7,			4		},
	{	"decimal",							5,			4351	},
	{	"decimal(16)",						5,			4351	},
	{	"decimal(32,14)",					5,			8206	},
	{	"float",							3,			8		},
	{	"integer",							2,			4		},
	{	"money",							8,			4098	},
	{	"money(16,2)",						8,			4098	},
	{	"smallfloat",						4,			4		},
	{	"smallint",							1,			2		},
	{	"varchar(128)",						13,			128		},
	{	"varchar(128,64)",					13,			16512	},
	{	"datetime day to day",				10,			580		},
	{	"datetime hour to fraction(3)",		10,			2413	},
	{	"datetime minute to fraction(3)",	10,			1933	},
	{	"datetime month to fraction(3)",	10,			3373	},
	{	"datetime second to fraction(5)",	10,			1967	},
	{	"datetime second to second",		10,			682		},
	{	"datetime year to fraction(3)",		10,			4365	},
	{	"datetime year to fraction(5)",		10,			4879	},
	{	"datetime year to year",			10,			1024	},
	{	"interval day(4) to fraction(3)",	14,			3405	},
	{	"interval day(9) to fraction(5)",	14,			5199	},
	{	"interval day to fraction(5)",		14,			3407	},
	{	"interval hour(4) to fraction(3)",	14,			2925	},
	{	"interval hour(6) to fraction(5)",	14,			3951	},
	{	"interval hour to fraction(5)",		14,			2927	},
	{	"byte in table",					11,			56		},
	{	"text in table",					12,			56		},
	{	"datetime fraction to fraction", 10,			973		},
	{	"datetime fraction to fraction(1)", 10,			459		},
	{	"datetime fraction to fraction(2)", 10,			716		},
	{	"datetime fraction to fraction(3)", 10,			973		},
	{	"datetime fraction to fraction(4)", 10,			1230	},
	{	"datetime fraction to fraction(5)", 10,			1487	},
	{	"interval fraction to fraction",	14,			973		},
	{	"interval fraction to fraction(1)", 14,			459		},
	{	"interval fraction to fraction(2)", 14,			716		},
	{	"interval fraction to fraction(3)", 14,			973		},
	{	"interval fraction to fraction(4)", 14,			1230	},
	{	"interval fraction to fraction(5)", 14,			1487	},
};

static void printtypes(int mode)
{
	int             i;

	sqltypemode(mode);
	printf("%-32s %4s %6s   %s\n", "Code", "Type", "Length", "Full type");
	for (i = 0; i < DIM(types); i++)
	{
		printf("%-32s %4d %6d = %s\n",
			   types[i].code, types[i].coltype, types[i].collen,
			   sqltype(types[i].coltype, types[i].collen));
		fflush(stdout);
	}
}

int main()
{
	printtypes(0);
	printtypes(1);
	return (0);
}

#endif	/* TEST */
