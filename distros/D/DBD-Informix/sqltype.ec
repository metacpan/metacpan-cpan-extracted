/*
@(#)File:           $RCSfile: sqltype.ec,v $
@(#)Version:        $Revision: 2011.1 $
@(#)Last changed:   $Date: 2011/05/12 23:39:50 $
@(#)Purpose:        Convert type and length from Syscolumns to string
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1988-93,1995-98,2001,2003-04,2007-08,2011
@(#)Product:        Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31)
*/

/*TABSTOP=4*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_sqltype_ec[] = "@(#)$Id: sqltype.ec,v 2011.1 2011/05/12 23:39:50 jleffler Exp $";
#endif /* lint */

#include <string.h>
#include "esqlc.h"
#include "esqlutil.h"

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
    "INT8",
    "SERIAL8",
    "SET",
    "MULTISET",
    "LIST",
    "ROW",
    "COLLECTION",
    "[reserved24]",
    "[reserved25]",
    "[reserved26]",
    "[reserved27]",
    "[reserved28]",
    "[reserved29]",
    "[reserved30]",
    "[reserved31]",
    "[reserved32]",
    "[reserved33]",
    "[reserved34]",
    "[reserved35]",
    "[reserved36]",
    "[reserved37]",
    "[reserved38]",
    "[reserved39]",
    "FIXED UDT",
    "VARIABLE UDT",
    "[reserved42]",
    "LVARCHAR",
    "[reserved44]",
    "BOOLEAN",
    "[reserved46]",
    "[reserved47]",
    "[reserved48]",
    "[reserved49]",
    "[reserved50]",
    "SQLUNKNOWN",
    "BIGINT",
    "BIGSERIAL",
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

static int sqlmode = 0;

/*
** Get/Set Type Formatting mode
** If the mode is set to 1, then sqltypename() formats
** INTERVAL HOUR(6) TO HOUR as INTERVAL HOUR(6).
** Otherwise it uses the standard Informix type name.
*/
int sqltypemode(int mode)
{
    int oldmode = sqlmode;
    sqlmode = mode;
    return(oldmode);
}

char    *sqltypename(ixInt2 coltype, ixInt4 collen, char *buffer, size_t buflen)
{
    int     precision;
    int     iv_df;
    int     dt_fr;
    int     dt_to;
    int     dt_ld;
    int     vc_min;
    int     vc_max;
    int     scale;
    int     type = MASKNONULL(coltype);
    char   *start = buffer;
    size_t  nbytes = 0;
    size_t  bufsiz = buflen;

    if (buffer == 0 || buflen == 0)        /* Damn fool programmer! */
        return(0);

    if (coltype & SQLDISTINCT)
        nbytes  = snprintf(start, bufsiz, "DISTINCT ");

    if (nbytes < bufsiz)
    {
        start  += nbytes;
        bufsiz -= nbytes;

        switch (type)
        {
        case SQLCHAR:
        case SQLNCHAR:
        case SQLLVARCHAR:
        case SQLUDTFIXED:
        case SQLUDTVAR:
            nbytes = snprintf(start, bufsiz, "%s(%" PRId_ixInt4 ")", sqltypes[type], collen);
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
        case SQLINT8:
        case SQLSERIAL8:
        case SQLBOOL:
        case SQLINFXBIGINT:
        case SQLBIGSERIAL:
            nbytes = snprintf(start, bufsiz, "%s", sqltypes[type]);
            break;

        /* IUS types -- will need more work in future */
        case SQLSET:
        case SQLLIST:
        case SQLMULTISET:
        case SQLCOLLECTION:
        case SQLROW:
            nbytes = snprintf(start, bufsiz, "%s", sqltypes[type]);
            break;

        case SQLDECIMAL:
        case SQLMONEY:
            precision = (collen >> 8) & 0xFF;
            scale = (collen & 0xFF);
            if (scale == 0xFF)
                nbytes = snprintf(start, bufsiz, "%s(%d)", sqltypes[type], precision);
            else
                nbytes = snprintf(start, bufsiz, "%s(%d,%d)", sqltypes[type], precision, scale);
            break;

        case SQLVCHAR:
        case SQLNVCHAR:
            vc_min = VCMIN(collen);
            vc_max = VCMAX(collen);
            if (vc_min == 0)
                nbytes = snprintf(start, bufsiz, "%s(%d)", sqltypes[type], vc_max);
            else
                nbytes = snprintf(start, bufsiz, "%s(%d,%d)", sqltypes[type], vc_max, vc_min);
            break;

        case SQLDTIME:
            dt_fr = TU_START(collen);
            dt_to = TU_END(collen);
            if (sqlmode != 1)
                nbytes = snprintf(start, bufsiz, "%s %s TO %s", sqltypes[type], dt_fr_ext[dt_fr],
                        dt_to_ext[dt_to]);
            else if (dt_fr == TU_FRAC)
                nbytes = snprintf(start, bufsiz, "%s %s", sqltypes[type], dt_to_ext[dt_to]);
            else if (dt_fr == dt_to)
                nbytes = snprintf(start, bufsiz, "%s %s", sqltypes[type], dt_to_ext[dt_to]);
            else
                nbytes = snprintf(start, bufsiz, "%s %s TO %s", sqltypes[type], dt_fr_ext[dt_fr],
                        dt_to_ext[dt_to]);
            break;

        case SQLINTERVAL:
            /* The sequence of tests here is gruesome - can it be simplified? */
            /* There are two pairs of identical formats! */
            dt_fr = TU_START(collen);
            dt_to = TU_END(collen);
            dt_ld = TU_FLEN(collen);
            iv_df = (dt_fr == TU_YEAR && dt_ld == 4) ||
                    (dt_fr != TU_YEAR && dt_ld == 2);
            if (sqlmode != 1 && (dt_fr == TU_FRAC || iv_df))
                /* Format 1A */
                nbytes = snprintf(start, bufsiz, "%s %s TO %s", sqltypes[type],
                        dt_fr_ext[dt_fr], dt_to_ext[dt_to]);
            else if (sqlmode != 1)
                /* Format 2A */
                nbytes = snprintf(start, bufsiz, "%s %s(%d) TO %s", sqltypes[type],
                        dt_fr_ext[dt_fr], dt_ld, dt_to_ext[dt_to]);
            else if (dt_fr == TU_FRAC)
                nbytes = snprintf(start, bufsiz, "%s %s", sqltypes[type], dt_to_ext[dt_to]);
            else if (dt_fr == dt_to && iv_df)
                nbytes = snprintf(start, bufsiz, "%s %s", sqltypes[type], dt_fr_ext[dt_fr]);
            else if (dt_fr == dt_to)
                nbytes = snprintf(start, bufsiz, "%s %s(%d)", sqltypes[type], dt_to_ext[dt_to],
                        dt_ld);
            else if (iv_df)
                /* Format 1B */
                nbytes = snprintf(start, bufsiz, "%s %s TO %s", sqltypes[type],
                        dt_fr_ext[dt_fr], dt_to_ext[dt_to]);
            else
                /* Format 2B */
                nbytes = snprintf(start, bufsiz, "%s %s(%d) TO %s", sqltypes[type],
                        dt_fr_ext[dt_fr], dt_ld, dt_to_ext[dt_to]);
            break;

        default:
            nbytes = snprintf(start, bufsiz, "Unknown (type %" PRId_ixInt2 ", len %" PRId_ixInt4 ")", coltype, collen);
            ESQLC_VERSION_CHECKER();
            break;
        }
    }

    if (nbytes >= bufsiz)
    {
        memset(buffer, '*', buflen - 1);
        buffer[buflen-1] = '\0';
    }
    return(buffer);
}

/* For backwards compatability only */
/* Not thread-safe because it uses static return data */
const char  *sqltype(ixInt2 coltype, ixInt4 collen)
{
    static char typestr[SQLTYPENAME_BUFSIZ];
    return(sqltypename(coltype, collen, typestr, sizeof(typestr)));
}

#ifdef TEST

#define DIM(x)  (sizeof(x)/sizeof(*(x)))

typedef struct  Typelist
{
    char    *code;
    int     coltype;
    int     collen;
}   Typelist;

static Typelist types[] =
{
    {   "char",                              0,          10      },
    {   "smallint",                          1,          2       },
    {   "integer",                           2,          4       },
    {   "float",                             3,          8       },
    {   "smallfloat",                        4,          4       },
    {   "decimal",                           5,          4351    },
    {   "decimal(16)",                       5,          4351    },
    {   "decimal(32,14)",                    5,          8206    },
    {   "date",                              7,          4       },
    {   "serial",                            6,          4       },
    {   "money",                             8,          4098    },
    {   "money(16,2)",                       8,          4098    },
    {   "datetime day to day",               10,         580     },
    {   "datetime fraction to fraction",     10,         973     },
    {   "datetime fraction to fraction(1)",  10,         459     },
    {   "datetime fraction to fraction(2)",  10,         716     },
    {   "datetime fraction to fraction(3)",  10,         973     },
    {   "datetime fraction to fraction(4)",  10,         1230    },
    {   "datetime fraction to fraction(5)",  10,         1487    },
    {   "datetime hour to fraction(3)",      10,         2413    },
    {   "datetime minute to fraction(3)",    10,         1933    },
    {   "datetime month to fraction(3)",     10,         3373    },
    {   "datetime second to fraction(5)",    10,         1967    },
    {   "datetime second to second",         10,         682     },
    {   "datetime year to fraction(3)",      10,         4365    },
    {   "datetime year to fraction(5)",      10,         4879    },
    {   "datetime year to year",             10,         1024    },
    {   "byte in table",                     11,         56      },
    {   "text in table",                     12,         56      },
    {   "varchar(128)",                      13,         128     },
    {   "varchar(128,64)",                   13,         16512   },
    {   "interval year to month",            14,         1538    },
    {   "interval year(3) to month",         14,         1282    },
    {   "interval year(5) to month",         14,         1794    },
    {   "interval year(5) to year",          14,         1280    },
    {   "interval month(5) to month",        14,         1314    },
    {   "interval month to month",           14,         546     },
    {   "interval day to fraction(5)",       14,         3407    },
    {   "interval day(4) to fraction(3)",    14,         3405    },
    {   "interval day(9) to fraction(5)",    14,         5199    },
    {   "interval fraction to fraction",     14,         973     },
    {   "interval minute(9) to fraction(5)", 14,         459     },
    {   "interval fraction to fraction(1)",  14,         4239    },
    {   "interval fraction to fraction(2)",  14,         716     },
    {   "interval fraction to fraction(3)",  14,         973     },
    {   "interval fraction to fraction(4)",  14,         1230    },
    {   "interval fraction to fraction(5)",  14,         1487    },
    {   "interval hour to fraction(5)",      14,         2927    },
    {   "interval hour(4) to fraction(3)",   14,         2925    },
    {   "interval hour(6) to fraction(5)",   14,         3951    },
    {   "serial",                            262,        4       },
    {   "nchar(456)",                        15,         456     },
    {   "nvarchar(255)",                     16,         255     },
    {   "nvarchar(128,64)",                  16,         16512   },
    {   "int8",                              17,         10      },
    {   "serial8",                           18,         10      },
    {   "set",                               19,         100     },
    {   "multiset",                          20,         100     },
    {   "list",                              21,         100     },
    {   "row",                               22,         100     },
    {   "collection",                        23,         100     },
    {   "fixed udt",                         40,         100     },
    {   "variable udt",                      41,         100     },
    {   "lvarchar",                          43,         100     },
    {   "boolean",                           45,         1       },
    {   "unknown",                           51,         1       },
    {   "bigint",                            52,         8       },
    {   "bigserial",                         53,         8       },
};

static void printtypes(int mode)
{
    int             i;

    sqltypemode(mode);
    printf("%-32s %4s %6s   %s\n", "Code", "Type", "Length", "Full type");
    for (i = 0; i < DIM(types); i++)
    {
        printf("%-33s %4d %6d = %s\n",
               types[i].code, types[i].coltype, types[i].collen,
               sqltype(types[i].coltype, types[i].collen));
        fflush(stdout);
    }
}

int main(void)
{
    printf("Mode 0: Classic type names\n");
    printtypes(0);
    printf("Mode 1: Semi-modern type names\n");
    printtypes(1);
    return (0);
}

#endif /* TEST */
