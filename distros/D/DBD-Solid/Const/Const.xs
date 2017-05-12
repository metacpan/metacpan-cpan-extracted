#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* start of mms fixes */
/*
#include <cli0cli.h>
#include <cli0defs.h>
#include <cli0env.h>
*/

#ifdef WORD
#undef WORD
#endif
/* Micro$loth says in sql.h that windows.h must come first.
* sqlunix.h is the equivalent of windows.h.  --mms*/
/* #ifdef SS_UNIX */
#include <sqlunix.h>
/*
#else
#include <windows.h>
#endif
*/
#include <sql.h>
#include <sqltypes.h>
#include <sqlext.h>
#include <sqlucode.h>

/*
#if SOLIDODBCAPI
#include <sqlucode.h>
#include <wchar.h>
#else
#include <sql.h>
#include <sqlext.h>
#endif
*/

/* end of mms fixes */

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	if (strEQ(name, "ODBCVER"))
#ifdef ODBCVER
	    return ODBCVER;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	if (strEQ(name, "SQL_ACCESSIBLE_PROCEDURES"))
#ifdef SQL_ACCESSIBLE_PROCEDURES
	    return SQL_ACCESSIBLE_PROCEDURES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ACCESSIBLE_TABLES"))
#ifdef SQL_ACCESSIBLE_TABLES
	    return SQL_ACCESSIBLE_TABLES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ACCESS_MODE"))
#ifdef SQL_ACCESS_MODE
	    return SQL_ACCESS_MODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ACTIVE_CONNECTIONS"))
#ifdef SQL_ACTIVE_CONNECTIONS
	    return SQL_ACTIVE_CONNECTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ACTIVE_STATEMENTS"))
#ifdef SQL_ACTIVE_STATEMENTS
	    return SQL_ACTIVE_STATEMENTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ADD"))
#ifdef SQL_ADD
	    return SQL_ADD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ALL_EXCEPT_LIKE"))
#ifdef SQL_ALL_EXCEPT_LIKE
	    return SQL_ALL_EXCEPT_LIKE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ALL_TYPES"))
#ifdef SQL_ALL_TYPES
	    return SQL_ALL_TYPES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ALTER_TABLE"))
#ifdef SQL_ALTER_TABLE
	    return SQL_ALTER_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_ALL_FUNCTIONS"))
#ifdef SQL_API_ALL_FUNCTIONS
	    return SQL_API_ALL_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_LOADBYORDINAL"))
#ifdef SQL_API_LOADBYORDINAL
	    return SQL_API_LOADBYORDINAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLALLOCCONNECT"))
#ifdef SQL_API_SQLALLOCCONNECT
	    return SQL_API_SQLALLOCCONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLALLOCENV"))
#ifdef SQL_API_SQLALLOCENV
	    return SQL_API_SQLALLOCENV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLALLOCSTMT"))
#ifdef SQL_API_SQLALLOCSTMT
	    return SQL_API_SQLALLOCSTMT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLBINDCOL"))
#ifdef SQL_API_SQLBINDCOL
	    return SQL_API_SQLBINDCOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLBINDPARAMETER"))
#ifdef SQL_API_SQLBINDPARAMETER
	    return SQL_API_SQLBINDPARAMETER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLBROWSECONNECT"))
#ifdef SQL_API_SQLBROWSECONNECT
	    return SQL_API_SQLBROWSECONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLCANCEL"))
#ifdef SQL_API_SQLCANCEL
	    return SQL_API_SQLCANCEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLCOLATTRIBUTES"))
#ifdef SQL_API_SQLCOLATTRIBUTES
	    return SQL_API_SQLCOLATTRIBUTES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLCOLUMNPRIVILEGES"))
#ifdef SQL_API_SQLCOLUMNPRIVILEGES
	    return SQL_API_SQLCOLUMNPRIVILEGES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLCOLUMNS"))
#ifdef SQL_API_SQLCOLUMNS
	    return SQL_API_SQLCOLUMNS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLCONNECT"))
#ifdef SQL_API_SQLCONNECT
	    return SQL_API_SQLCONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLDATASOURCES"))
#ifdef SQL_API_SQLDATASOURCES
	    return SQL_API_SQLDATASOURCES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLDESCRIBECOL"))
#ifdef SQL_API_SQLDESCRIBECOL
	    return SQL_API_SQLDESCRIBECOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLDESCRIBEPARAM"))
#ifdef SQL_API_SQLDESCRIBEPARAM
	    return SQL_API_SQLDESCRIBEPARAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLDISCONNECT"))
#ifdef SQL_API_SQLDISCONNECT
	    return SQL_API_SQLDISCONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLDRIVERCONNECT"))
#ifdef SQL_API_SQLDRIVERCONNECT
	    return SQL_API_SQLDRIVERCONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLDRIVERS"))
#ifdef SQL_API_SQLDRIVERS
	    return SQL_API_SQLDRIVERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLERROR"))
#ifdef SQL_API_SQLERROR
	    return SQL_API_SQLERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLEXECDIRECT"))
#ifdef SQL_API_SQLEXECDIRECT
	    return SQL_API_SQLEXECDIRECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLEXECUTE"))
#ifdef SQL_API_SQLEXECUTE
	    return SQL_API_SQLEXECUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLEXTENDEDFETCH"))
#ifdef SQL_API_SQLEXTENDEDFETCH
	    return SQL_API_SQLEXTENDEDFETCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLFETCH"))
#ifdef SQL_API_SQLFETCH
	    return SQL_API_SQLFETCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLFOREIGNKEYS"))
#ifdef SQL_API_SQLFOREIGNKEYS
	    return SQL_API_SQLFOREIGNKEYS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLFREECONNECT"))
#ifdef SQL_API_SQLFREECONNECT
	    return SQL_API_SQLFREECONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLFREEENV"))
#ifdef SQL_API_SQLFREEENV
	    return SQL_API_SQLFREEENV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLFREESTMT"))
#ifdef SQL_API_SQLFREESTMT
	    return SQL_API_SQLFREESTMT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETCONNECTOPTION"))
#ifdef SQL_API_SQLGETCONNECTOPTION
	    return SQL_API_SQLGETCONNECTOPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETCURSORNAME"))
#ifdef SQL_API_SQLGETCURSORNAME
	    return SQL_API_SQLGETCURSORNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETDATA"))
#ifdef SQL_API_SQLGETDATA
	    return SQL_API_SQLGETDATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETFUNCTIONS"))
#ifdef SQL_API_SQLGETFUNCTIONS
	    return SQL_API_SQLGETFUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETINFO"))
#ifdef SQL_API_SQLGETINFO
	    return SQL_API_SQLGETINFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETSTMTOPTION"))
#ifdef SQL_API_SQLGETSTMTOPTION
	    return SQL_API_SQLGETSTMTOPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETTYPEINFO"))
#ifdef SQL_API_SQLGETTYPEINFO
	    return SQL_API_SQLGETTYPEINFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLMORERESULTS"))
#ifdef SQL_API_SQLMORERESULTS
	    return SQL_API_SQLMORERESULTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLNATIVESQL"))
#ifdef SQL_API_SQLNATIVESQL
	    return SQL_API_SQLNATIVESQL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLNUMPARAMS"))
#ifdef SQL_API_SQLNUMPARAMS
	    return SQL_API_SQLNUMPARAMS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLNUMRESULTCOLS"))
#ifdef SQL_API_SQLNUMRESULTCOLS
	    return SQL_API_SQLNUMRESULTCOLS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLPARAMDATA"))
#ifdef SQL_API_SQLPARAMDATA
	    return SQL_API_SQLPARAMDATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLPARAMOPTIONS"))
#ifdef SQL_API_SQLPARAMOPTIONS
	    return SQL_API_SQLPARAMOPTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLPREPARE"))
#ifdef SQL_API_SQLPREPARE
	    return SQL_API_SQLPREPARE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLPRIMARYKEYS"))
#ifdef SQL_API_SQLPRIMARYKEYS
	    return SQL_API_SQLPRIMARYKEYS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLPROCEDURECOLUMNS"))
#ifdef SQL_API_SQLPROCEDURECOLUMNS
	    return SQL_API_SQLPROCEDURECOLUMNS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLPROCEDURES"))
#ifdef SQL_API_SQLPROCEDURES
	    return SQL_API_SQLPROCEDURES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLPUTDATA"))
#ifdef SQL_API_SQLPUTDATA
	    return SQL_API_SQLPUTDATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLROWCOUNT"))
#ifdef SQL_API_SQLROWCOUNT
	    return SQL_API_SQLROWCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSETCONNECTOPTION"))
#ifdef SQL_API_SQLSETCONNECTOPTION
	    return SQL_API_SQLSETCONNECTOPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSETCURSORNAME"))
#ifdef SQL_API_SQLSETCURSORNAME
	    return SQL_API_SQLSETCURSORNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSETPARAM"))
#ifdef SQL_API_SQLSETPARAM
	    return SQL_API_SQLSETPARAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSETPOS"))
#ifdef SQL_API_SQLSETPOS
	    return SQL_API_SQLSETPOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSETSCROLLOPTIONS"))
#ifdef SQL_API_SQLSETSCROLLOPTIONS
	    return SQL_API_SQLSETSCROLLOPTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSETSTMTOPTION"))
#ifdef SQL_API_SQLSETSTMTOPTION
	    return SQL_API_SQLSETSTMTOPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSPECIALCOLUMNS"))
#ifdef SQL_API_SQLSPECIALCOLUMNS
	    return SQL_API_SQLSPECIALCOLUMNS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSTATISTICS"))
#ifdef SQL_API_SQLSTATISTICS
	    return SQL_API_SQLSTATISTICS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLTABLEPRIVILEGES"))
#ifdef SQL_API_SQLTABLEPRIVILEGES
	    return SQL_API_SQLTABLEPRIVILEGES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLTABLES"))
#ifdef SQL_API_SQLTABLES
	    return SQL_API_SQLTABLES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLTRANSACT"))
#ifdef SQL_API_SQLTRANSACT
	    return SQL_API_SQLTRANSACT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ASYNC_ENABLE"))
#ifdef SQL_ASYNC_ENABLE
	    return SQL_ASYNC_ENABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ASYNC_ENABLE_DEFAULT"))
#ifdef SQL_ASYNC_ENABLE_DEFAULT
	    return SQL_ASYNC_ENABLE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ASYNC_ENABLE_OFF"))
#ifdef SQL_ASYNC_ENABLE_OFF
	    return SQL_ASYNC_ENABLE_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ASYNC_ENABLE_ON"))
#ifdef SQL_ASYNC_ENABLE_ON
	    return SQL_ASYNC_ENABLE_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_READONLY"))
#ifdef SQL_ATTR_READONLY
	    return SQL_ATTR_READONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_READWRITE_UNKNOWN"))
#ifdef SQL_ATTR_READWRITE_UNKNOWN
	    return SQL_ATTR_READWRITE_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_WRITE"))
#ifdef SQL_ATTR_WRITE
	    return SQL_ATTR_WRITE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_ADD_COLUMN"))
#ifdef SQL_AT_ADD_COLUMN
	    return SQL_AT_ADD_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_DROP_COLUMN"))
#ifdef SQL_AT_DROP_COLUMN
	    return SQL_AT_DROP_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AUTOCOMMIT"))
#ifdef SQL_AUTOCOMMIT
	    return SQL_AUTOCOMMIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AUTOCOMMIT_DEFAULT"))
#ifdef SQL_AUTOCOMMIT_DEFAULT
	    return SQL_AUTOCOMMIT_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AUTOCOMMIT_OFF"))
#ifdef SQL_AUTOCOMMIT_OFF
	    return SQL_AUTOCOMMIT_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AUTOCOMMIT_ON"))
#ifdef SQL_AUTOCOMMIT_ON
	    return SQL_AUTOCOMMIT_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BEST_ROWID"))
#ifdef SQL_BEST_ROWID
	    return SQL_BEST_ROWID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BIGINT"))
#ifdef SQL_BIGINT
	    return SQL_BIGINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BINARY"))
#ifdef SQL_BINARY
	    return SQL_BINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BIND_BY_COLUMN"))
#ifdef SQL_BIND_BY_COLUMN
	    return SQL_BIND_BY_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BIND_TYPE"))
#ifdef SQL_BIND_TYPE
	    return SQL_BIND_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BIT"))
#ifdef SQL_BIT
	    return SQL_BIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BOOKMARK_PERSISTENCE"))
#ifdef SQL_BOOKMARK_PERSISTENCE
	    return SQL_BOOKMARK_PERSISTENCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BP_CLOSE"))
#ifdef SQL_BP_CLOSE
	    return SQL_BP_CLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BP_DELETE"))
#ifdef SQL_BP_DELETE
	    return SQL_BP_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BP_DROP"))
#ifdef SQL_BP_DROP
	    return SQL_BP_DROP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BP_OTHER_HSTMT"))
#ifdef SQL_BP_OTHER_HSTMT
	    return SQL_BP_OTHER_HSTMT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BP_SCROLL"))
#ifdef SQL_BP_SCROLL
	    return SQL_BP_SCROLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BP_TRANSACTION"))
#ifdef SQL_BP_TRANSACTION
	    return SQL_BP_TRANSACTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BP_UPDATE"))
#ifdef SQL_BP_UPDATE
	    return SQL_BP_UPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CASCADE"))
#ifdef SQL_CASCADE
	    return SQL_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CB_CLOSE"))
#ifdef SQL_CB_CLOSE
	    return SQL_CB_CLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CB_DELETE"))
#ifdef SQL_CB_DELETE
	    return SQL_CB_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CB_NON_NULL"))
#ifdef SQL_CB_NON_NULL
	    return SQL_CB_NON_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CB_NULL"))
#ifdef SQL_CB_NULL
	    return SQL_CB_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CB_PRESERVE"))
#ifdef SQL_CB_PRESERVE
	    return SQL_CB_PRESERVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CC_CLOSE"))
#ifdef SQL_CC_CLOSE
	    return SQL_CC_CLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CC_DELETE"))
#ifdef SQL_CC_DELETE
	    return SQL_CC_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CC_PRESERVE"))
#ifdef SQL_CC_PRESERVE
	    return SQL_CC_PRESERVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CHAR"))
#ifdef SQL_CHAR
	    return SQL_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CLOSE"))
#ifdef SQL_CLOSE
	    return SQL_CLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CN_ANY"))
#ifdef SQL_CN_ANY
	    return SQL_CN_ANY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CN_DIFFERENT"))
#ifdef SQL_CN_DIFFERENT
	    return SQL_CN_DIFFERENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CN_NONE"))
#ifdef SQL_CN_NONE
	    return SQL_CN_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLATT_OPT_MAX"))
#ifdef SQL_COLATT_OPT_MAX
	    return SQL_COLATT_OPT_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLATT_OPT_MIN"))
#ifdef SQL_COLATT_OPT_MIN
	    return SQL_COLATT_OPT_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_ALIAS"))
#ifdef SQL_COLUMN_ALIAS
	    return SQL_COLUMN_ALIAS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_AUTO_INCREMENT"))
#ifdef SQL_COLUMN_AUTO_INCREMENT
	    return SQL_COLUMN_AUTO_INCREMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_CASE_SENSITIVE"))
#ifdef SQL_COLUMN_CASE_SENSITIVE
	    return SQL_COLUMN_CASE_SENSITIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_COUNT"))
#ifdef SQL_COLUMN_COUNT
	    return SQL_COLUMN_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_DISPLAY_SIZE"))
#ifdef SQL_COLUMN_DISPLAY_SIZE
	    return SQL_COLUMN_DISPLAY_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_DRIVER_START"))
#ifdef SQL_COLUMN_DRIVER_START
	    return SQL_COLUMN_DRIVER_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_LABEL"))
#ifdef SQL_COLUMN_LABEL
	    return SQL_COLUMN_LABEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_LENGTH"))
#ifdef SQL_COLUMN_LENGTH
	    return SQL_COLUMN_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_MONEY"))
#ifdef SQL_COLUMN_MONEY
	    return SQL_COLUMN_MONEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_NAME"))
#ifdef SQL_COLUMN_NAME
	    return SQL_COLUMN_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_NULLABLE"))
#ifdef SQL_COLUMN_NULLABLE
	    return SQL_COLUMN_NULLABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_OWNER_NAME"))
#ifdef SQL_COLUMN_OWNER_NAME
	    return SQL_COLUMN_OWNER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_PRECISION"))
#ifdef SQL_COLUMN_PRECISION
	    return SQL_COLUMN_PRECISION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_QUALIFIER_NAME"))
#ifdef SQL_COLUMN_QUALIFIER_NAME
	    return SQL_COLUMN_QUALIFIER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_SCALE"))
#ifdef SQL_COLUMN_SCALE
	    return SQL_COLUMN_SCALE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_SEARCHABLE"))
#ifdef SQL_COLUMN_SEARCHABLE
	    return SQL_COLUMN_SEARCHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_TABLE_NAME"))
#ifdef SQL_COLUMN_TABLE_NAME
	    return SQL_COLUMN_TABLE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_TYPE"))
#ifdef SQL_COLUMN_TYPE
	    return SQL_COLUMN_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_TYPE_NAME"))
#ifdef SQL_COLUMN_TYPE_NAME
	    return SQL_COLUMN_TYPE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_UNSIGNED"))
#ifdef SQL_COLUMN_UNSIGNED
	    return SQL_COLUMN_UNSIGNED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_UPDATABLE"))
#ifdef SQL_COLUMN_UPDATABLE
	    return SQL_COLUMN_UPDATABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COMMIT"))
#ifdef SQL_COMMIT
	    return SQL_COMMIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONCAT_NULL_BEHAVIOR"))
#ifdef SQL_CONCAT_NULL_BEHAVIOR
	    return SQL_CONCAT_NULL_BEHAVIOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONCURRENCY"))
#ifdef SQL_CONCURRENCY
	    return SQL_CONCURRENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONCUR_LOCK"))
#ifdef SQL_CONCUR_LOCK
	    return SQL_CONCUR_LOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONCUR_READ_ONLY"))
#ifdef SQL_CONCUR_READ_ONLY
	    return SQL_CONCUR_READ_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONCUR_ROWVER"))
#ifdef SQL_CONCUR_ROWVER
	    return SQL_CONCUR_ROWVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONCUR_TIMESTAMP"))
#ifdef SQL_CONCUR_TIMESTAMP
	    return SQL_CONCUR_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONCUR_VALUES"))
#ifdef SQL_CONCUR_VALUES
	    return SQL_CONCUR_VALUES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONNECT_OPT_DRVR_START"))
#ifdef SQL_CONNECT_OPT_DRVR_START
	    return SQL_CONNECT_OPT_DRVR_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONN_OPT_MAX"))
#ifdef SQL_CONN_OPT_MAX
	    return SQL_CONN_OPT_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONN_OPT_MIN"))
#ifdef SQL_CONN_OPT_MIN
	    return SQL_CONN_OPT_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_BIGINT"))
#ifdef SQL_CONVERT_BIGINT
	    return SQL_CONVERT_BIGINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_BINARY"))
#ifdef SQL_CONVERT_BINARY
	    return SQL_CONVERT_BINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_BIT"))
#ifdef SQL_CONVERT_BIT
	    return SQL_CONVERT_BIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_CHAR"))
#ifdef SQL_CONVERT_CHAR
	    return SQL_CONVERT_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_DATE"))
#ifdef SQL_CONVERT_DATE
	    return SQL_CONVERT_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_DECIMAL"))
#ifdef SQL_CONVERT_DECIMAL
	    return SQL_CONVERT_DECIMAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_DOUBLE"))
#ifdef SQL_CONVERT_DOUBLE
	    return SQL_CONVERT_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_FLOAT"))
#ifdef SQL_CONVERT_FLOAT
	    return SQL_CONVERT_FLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_FUNCTIONS"))
#ifdef SQL_CONVERT_FUNCTIONS
	    return SQL_CONVERT_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_INTEGER"))
#ifdef SQL_CONVERT_INTEGER
	    return SQL_CONVERT_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_LONGVARBINARY"))
#ifdef SQL_CONVERT_LONGVARBINARY
	    return SQL_CONVERT_LONGVARBINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_LONGVARCHAR"))
#ifdef SQL_CONVERT_LONGVARCHAR
	    return SQL_CONVERT_LONGVARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_NUMERIC"))
#ifdef SQL_CONVERT_NUMERIC
	    return SQL_CONVERT_NUMERIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_REAL"))
#ifdef SQL_CONVERT_REAL
	    return SQL_CONVERT_REAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_SMALLINT"))
#ifdef SQL_CONVERT_SMALLINT
	    return SQL_CONVERT_SMALLINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_TIME"))
#ifdef SQL_CONVERT_TIME
	    return SQL_CONVERT_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_TIMESTAMP"))
#ifdef SQL_CONVERT_TIMESTAMP
	    return SQL_CONVERT_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_TINYINT"))
#ifdef SQL_CONVERT_TINYINT
	    return SQL_CONVERT_TINYINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_VARBINARY"))
#ifdef SQL_CONVERT_VARBINARY
	    return SQL_CONVERT_VARBINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_VARCHAR"))
#ifdef SQL_CONVERT_VARCHAR
	    return SQL_CONVERT_VARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CORRELATION_NAME"))
#ifdef SQL_CORRELATION_NAME
	    return SQL_CORRELATION_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CR_CLOSE"))
#ifdef SQL_CR_CLOSE
	    return SQL_CR_CLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CR_DELETE"))
#ifdef SQL_CR_DELETE
	    return SQL_CR_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CR_PRESERVE"))
#ifdef SQL_CR_PRESERVE
	    return SQL_CR_PRESERVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURRENT_QUALIFIER"))
#ifdef SQL_CURRENT_QUALIFIER
	    return SQL_CURRENT_QUALIFIER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURSOR_COMMIT_BEHAVIOR"))
#ifdef SQL_CURSOR_COMMIT_BEHAVIOR
	    return SQL_CURSOR_COMMIT_BEHAVIOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURSOR_DYNAMIC"))
#ifdef SQL_CURSOR_DYNAMIC
	    return SQL_CURSOR_DYNAMIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURSOR_FORWARD_ONLY"))
#ifdef SQL_CURSOR_FORWARD_ONLY
	    return SQL_CURSOR_FORWARD_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURSOR_KEYSET_DRIVEN"))
#ifdef SQL_CURSOR_KEYSET_DRIVEN
	    return SQL_CURSOR_KEYSET_DRIVEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURSOR_ROLLBACK_BEHAVIOR"))
#ifdef SQL_CURSOR_ROLLBACK_BEHAVIOR
	    return SQL_CURSOR_ROLLBACK_BEHAVIOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURSOR_STATIC"))
#ifdef SQL_CURSOR_STATIC
	    return SQL_CURSOR_STATIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURSOR_TYPE"))
#ifdef SQL_CURSOR_TYPE
	    return SQL_CURSOR_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CUR_DEFAULT"))
#ifdef SQL_CUR_DEFAULT
	    return SQL_CUR_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CUR_USE_DRIVER"))
#ifdef SQL_CUR_USE_DRIVER
	    return SQL_CUR_USE_DRIVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CUR_USE_IF_NEEDED"))
#ifdef SQL_CUR_USE_IF_NEEDED
	    return SQL_CUR_USE_IF_NEEDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CUR_USE_ODBC"))
#ifdef SQL_CUR_USE_ODBC
	    return SQL_CUR_USE_ODBC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_BIGINT"))
#ifdef SQL_CVT_BIGINT
	    return SQL_CVT_BIGINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_BINARY"))
#ifdef SQL_CVT_BINARY
	    return SQL_CVT_BINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_BIT"))
#ifdef SQL_CVT_BIT
	    return SQL_CVT_BIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_CHAR"))
#ifdef SQL_CVT_CHAR
	    return SQL_CVT_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_DATE"))
#ifdef SQL_CVT_DATE
	    return SQL_CVT_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_DECIMAL"))
#ifdef SQL_CVT_DECIMAL
	    return SQL_CVT_DECIMAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_DOUBLE"))
#ifdef SQL_CVT_DOUBLE
	    return SQL_CVT_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_FLOAT"))
#ifdef SQL_CVT_FLOAT
	    return SQL_CVT_FLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_INTEGER"))
#ifdef SQL_CVT_INTEGER
	    return SQL_CVT_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_LONGVARBINARY"))
#ifdef SQL_CVT_LONGVARBINARY
	    return SQL_CVT_LONGVARBINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_LONGVARCHAR"))
#ifdef SQL_CVT_LONGVARCHAR
	    return SQL_CVT_LONGVARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_NUMERIC"))
#ifdef SQL_CVT_NUMERIC
	    return SQL_CVT_NUMERIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_REAL"))
#ifdef SQL_CVT_REAL
	    return SQL_CVT_REAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_SMALLINT"))
#ifdef SQL_CVT_SMALLINT
	    return SQL_CVT_SMALLINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_TIME"))
#ifdef SQL_CVT_TIME
	    return SQL_CVT_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_TIMESTAMP"))
#ifdef SQL_CVT_TIMESTAMP
	    return SQL_CVT_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_TINYINT"))
#ifdef SQL_CVT_TINYINT
	    return SQL_CVT_TINYINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_VARBINARY"))
#ifdef SQL_CVT_VARBINARY
	    return SQL_CVT_VARBINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_VARCHAR"))
#ifdef SQL_CVT_VARCHAR
	    return SQL_CVT_VARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_BINARY"))
#ifdef SQL_C_BINARY
	    return SQL_C_BINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_BIT"))
#ifdef SQL_C_BIT
	    return SQL_C_BIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_BOOKMARK"))
#ifdef SQL_C_BOOKMARK
	    return SQL_C_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_CHAR"))
#ifdef SQL_C_CHAR
	    return SQL_C_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DATE"))
#ifdef SQL_C_DATE
	    return SQL_C_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DEFAULT"))
#ifdef SQL_C_DEFAULT
	    return SQL_C_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DOUBLE"))
#ifdef SQL_C_DOUBLE
	    return SQL_C_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_FLOAT"))
#ifdef SQL_C_FLOAT
	    return SQL_C_FLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_LONG"))
#ifdef SQL_C_LONG
	    return SQL_C_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_SHORT"))
#ifdef SQL_C_SHORT
	    return SQL_C_SHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_SLONG"))
#ifdef SQL_C_SLONG
	    return SQL_C_SLONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_SSHORT"))
#ifdef SQL_C_SSHORT
	    return SQL_C_SSHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_STINYINT"))
#ifdef SQL_C_STINYINT
	    return SQL_C_STINYINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_TIME"))
#ifdef SQL_C_TIME
	    return SQL_C_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_TIMESTAMP"))
#ifdef SQL_C_TIMESTAMP
	    return SQL_C_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_TINYINT"))
#ifdef SQL_C_TINYINT
	    return SQL_C_TINYINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_ULONG"))
#ifdef SQL_C_ULONG
	    return SQL_C_ULONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_USHORT"))
#ifdef SQL_C_USHORT
	    return SQL_C_USHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_UTINYINT"))
#ifdef SQL_C_UTINYINT
	    return SQL_C_UTINYINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATABASE_NAME"))
#ifdef SQL_DATABASE_NAME
	    return SQL_DATABASE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATA_AT_EXEC"))
#ifdef SQL_DATA_AT_EXEC
	    return SQL_DATA_AT_EXEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATA_SOURCE_NAME"))
#ifdef SQL_DATA_SOURCE_NAME
	    return SQL_DATA_SOURCE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATA_SOURCE_READ_ONLY"))
#ifdef SQL_DATA_SOURCE_READ_ONLY
	    return SQL_DATA_SOURCE_READ_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATE"))
#ifdef SQL_DATE
	    return SQL_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DBMS_NAME"))
#ifdef SQL_DBMS_NAME
	    return SQL_DBMS_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DBMS_VER"))
#ifdef SQL_DBMS_VER
	    return SQL_DBMS_VER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DECIMAL"))
#ifdef SQL_DECIMAL
	    return SQL_DECIMAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DEFAULT_PARAM"))
#ifdef SQL_DEFAULT_PARAM
	    return SQL_DEFAULT_PARAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DEFAULT_TXN_ISOLATION"))
#ifdef SQL_DEFAULT_TXN_ISOLATION
	    return SQL_DEFAULT_TXN_ISOLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DELETE"))
#ifdef SQL_DELETE
	    return SQL_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DOUBLE"))
#ifdef SQL_DOUBLE
	    return SQL_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_COMPLETE"))
#ifdef SQL_DRIVER_COMPLETE
	    return SQL_DRIVER_COMPLETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_COMPLETE_REQUIRED"))
#ifdef SQL_DRIVER_COMPLETE_REQUIRED
	    return SQL_DRIVER_COMPLETE_REQUIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_HDBC"))
#ifdef SQL_DRIVER_HDBC
	    return SQL_DRIVER_HDBC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_HENV"))
#ifdef SQL_DRIVER_HENV
	    return SQL_DRIVER_HENV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_HLIB"))
#ifdef SQL_DRIVER_HLIB
	    return SQL_DRIVER_HLIB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_HSTMT"))
#ifdef SQL_DRIVER_HSTMT
	    return SQL_DRIVER_HSTMT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_NAME"))
#ifdef SQL_DRIVER_NAME
	    return SQL_DRIVER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_NOPROMPT"))
#ifdef SQL_DRIVER_NOPROMPT
	    return SQL_DRIVER_NOPROMPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_ODBC_VER"))
#ifdef SQL_DRIVER_ODBC_VER
	    return SQL_DRIVER_ODBC_VER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_PROMPT"))
#ifdef SQL_DRIVER_PROMPT
	    return SQL_DRIVER_PROMPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DRIVER_VER"))
#ifdef SQL_DRIVER_VER
	    return SQL_DRIVER_VER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DROP"))
#ifdef SQL_DROP
	    return SQL_DROP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ENSURE"))
#ifdef SQL_ENSURE
	    return SQL_ENSURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ENTIRE_ROWSET"))
#ifdef SQL_ENTIRE_ROWSET
	    return SQL_ENTIRE_ROWSET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ERROR"))
#ifdef SQL_ERROR
	    return SQL_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_EXPRESSIONS_IN_ORDERBY"))
#ifdef SQL_EXPRESSIONS_IN_ORDERBY
	    return SQL_EXPRESSIONS_IN_ORDERBY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_EXT_API_LAST"))
#ifdef SQL_EXT_API_LAST
	    return SQL_EXT_API_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_EXT_API_START"))
#ifdef SQL_EXT_API_START
	    return SQL_EXT_API_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FD_FETCH_ABSOLUTE"))
#ifdef SQL_FD_FETCH_ABSOLUTE
	    return SQL_FD_FETCH_ABSOLUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FD_FETCH_BOOKMARK"))
#ifdef SQL_FD_FETCH_BOOKMARK
	    return SQL_FD_FETCH_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FD_FETCH_FIRST"))
#ifdef SQL_FD_FETCH_FIRST
	    return SQL_FD_FETCH_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FD_FETCH_LAST"))
#ifdef SQL_FD_FETCH_LAST
	    return SQL_FD_FETCH_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FD_FETCH_NEXT"))
#ifdef SQL_FD_FETCH_NEXT
	    return SQL_FD_FETCH_NEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FD_FETCH_PREV"))
#ifdef SQL_FD_FETCH_PREV
	    return SQL_FD_FETCH_PREV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FD_FETCH_PRIOR"))
#ifdef SQL_FD_FETCH_PRIOR
	    return SQL_FD_FETCH_PRIOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FD_FETCH_RELATIVE"))
#ifdef SQL_FD_FETCH_RELATIVE
	    return SQL_FD_FETCH_RELATIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FD_FETCH_RESUME"))
#ifdef SQL_FD_FETCH_RESUME
	    return SQL_FD_FETCH_RESUME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_ABSOLUTE"))
#ifdef SQL_FETCH_ABSOLUTE
	    return SQL_FETCH_ABSOLUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_BOOKMARK"))
#ifdef SQL_FETCH_BOOKMARK
	    return SQL_FETCH_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_DIRECTION"))
#ifdef SQL_FETCH_DIRECTION
	    return SQL_FETCH_DIRECTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_FIRST"))
#ifdef SQL_FETCH_FIRST
	    return SQL_FETCH_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_LAST"))
#ifdef SQL_FETCH_LAST
	    return SQL_FETCH_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_NEXT"))
#ifdef SQL_FETCH_NEXT
	    return SQL_FETCH_NEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_PREV"))
#ifdef SQL_FETCH_PREV
	    return SQL_FETCH_PREV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_PRIOR"))
#ifdef SQL_FETCH_PRIOR
	    return SQL_FETCH_PRIOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_RELATIVE"))
#ifdef SQL_FETCH_RELATIVE
	    return SQL_FETCH_RELATIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_RESUME"))
#ifdef SQL_FETCH_RESUME
	    return SQL_FETCH_RESUME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FILE_NOT_SUPPORTED"))
#ifdef SQL_FILE_NOT_SUPPORTED
	    return SQL_FILE_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FILE_QUALIFIER"))
#ifdef SQL_FILE_QUALIFIER
	    return SQL_FILE_QUALIFIER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FILE_TABLE"))
#ifdef SQL_FILE_TABLE
	    return SQL_FILE_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FILE_USAGE"))
#ifdef SQL_FILE_USAGE
	    return SQL_FILE_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FLOAT"))
#ifdef SQL_FLOAT
	    return SQL_FLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_CVT_CONVERT"))
#ifdef SQL_FN_CVT_CONVERT
	    return SQL_FN_CVT_CONVERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_ABS"))
#ifdef SQL_FN_NUM_ABS
	    return SQL_FN_NUM_ABS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_ACOS"))
#ifdef SQL_FN_NUM_ACOS
	    return SQL_FN_NUM_ACOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_ASIN"))
#ifdef SQL_FN_NUM_ASIN
	    return SQL_FN_NUM_ASIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_ATAN"))
#ifdef SQL_FN_NUM_ATAN
	    return SQL_FN_NUM_ATAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_ATAN2"))
#ifdef SQL_FN_NUM_ATAN2
	    return SQL_FN_NUM_ATAN2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_CEILING"))
#ifdef SQL_FN_NUM_CEILING
	    return SQL_FN_NUM_CEILING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_COS"))
#ifdef SQL_FN_NUM_COS
	    return SQL_FN_NUM_COS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_COT"))
#ifdef SQL_FN_NUM_COT
	    return SQL_FN_NUM_COT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_DEGREES"))
#ifdef SQL_FN_NUM_DEGREES
	    return SQL_FN_NUM_DEGREES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_EXP"))
#ifdef SQL_FN_NUM_EXP
	    return SQL_FN_NUM_EXP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_FLOOR"))
#ifdef SQL_FN_NUM_FLOOR
	    return SQL_FN_NUM_FLOOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_LOG"))
#ifdef SQL_FN_NUM_LOG
	    return SQL_FN_NUM_LOG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_LOG10"))
#ifdef SQL_FN_NUM_LOG10
	    return SQL_FN_NUM_LOG10;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_MOD"))
#ifdef SQL_FN_NUM_MOD
	    return SQL_FN_NUM_MOD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_PI"))
#ifdef SQL_FN_NUM_PI
	    return SQL_FN_NUM_PI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_POWER"))
#ifdef SQL_FN_NUM_POWER
	    return SQL_FN_NUM_POWER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_RADIANS"))
#ifdef SQL_FN_NUM_RADIANS
	    return SQL_FN_NUM_RADIANS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_RAND"))
#ifdef SQL_FN_NUM_RAND
	    return SQL_FN_NUM_RAND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_ROUND"))
#ifdef SQL_FN_NUM_ROUND
	    return SQL_FN_NUM_ROUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_SIGN"))
#ifdef SQL_FN_NUM_SIGN
	    return SQL_FN_NUM_SIGN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_SIN"))
#ifdef SQL_FN_NUM_SIN
	    return SQL_FN_NUM_SIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_SQRT"))
#ifdef SQL_FN_NUM_SQRT
	    return SQL_FN_NUM_SQRT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_TAN"))
#ifdef SQL_FN_NUM_TAN
	    return SQL_FN_NUM_TAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_NUM_TRUNCATE"))
#ifdef SQL_FN_NUM_TRUNCATE
	    return SQL_FN_NUM_TRUNCATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_ASCII"))
#ifdef SQL_FN_STR_ASCII
	    return SQL_FN_STR_ASCII;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_CHAR"))
#ifdef SQL_FN_STR_CHAR
	    return SQL_FN_STR_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_CONCAT"))
#ifdef SQL_FN_STR_CONCAT
	    return SQL_FN_STR_CONCAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_DIFFERENCE"))
#ifdef SQL_FN_STR_DIFFERENCE
	    return SQL_FN_STR_DIFFERENCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_INSERT"))
#ifdef SQL_FN_STR_INSERT
	    return SQL_FN_STR_INSERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_LCASE"))
#ifdef SQL_FN_STR_LCASE
	    return SQL_FN_STR_LCASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_LEFT"))
#ifdef SQL_FN_STR_LEFT
	    return SQL_FN_STR_LEFT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_LENGTH"))
#ifdef SQL_FN_STR_LENGTH
	    return SQL_FN_STR_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_LOCATE"))
#ifdef SQL_FN_STR_LOCATE
	    return SQL_FN_STR_LOCATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_LOCATE_2"))
#ifdef SQL_FN_STR_LOCATE_2
	    return SQL_FN_STR_LOCATE_2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_LTRIM"))
#ifdef SQL_FN_STR_LTRIM
	    return SQL_FN_STR_LTRIM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_REPEAT"))
#ifdef SQL_FN_STR_REPEAT
	    return SQL_FN_STR_REPEAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_REPLACE"))
#ifdef SQL_FN_STR_REPLACE
	    return SQL_FN_STR_REPLACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_RIGHT"))
#ifdef SQL_FN_STR_RIGHT
	    return SQL_FN_STR_RIGHT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_RTRIM"))
#ifdef SQL_FN_STR_RTRIM
	    return SQL_FN_STR_RTRIM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_SOUNDEX"))
#ifdef SQL_FN_STR_SOUNDEX
	    return SQL_FN_STR_SOUNDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_SPACE"))
#ifdef SQL_FN_STR_SPACE
	    return SQL_FN_STR_SPACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_SUBSTRING"))
#ifdef SQL_FN_STR_SUBSTRING
	    return SQL_FN_STR_SUBSTRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_UCASE"))
#ifdef SQL_FN_STR_UCASE
	    return SQL_FN_STR_UCASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_SYS_DBNAME"))
#ifdef SQL_FN_SYS_DBNAME
	    return SQL_FN_SYS_DBNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_SYS_IFNULL"))
#ifdef SQL_FN_SYS_IFNULL
	    return SQL_FN_SYS_IFNULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_SYS_USERNAME"))
#ifdef SQL_FN_SYS_USERNAME
	    return SQL_FN_SYS_USERNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_CURDATE"))
#ifdef SQL_FN_TD_CURDATE
	    return SQL_FN_TD_CURDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_CURTIME"))
#ifdef SQL_FN_TD_CURTIME
	    return SQL_FN_TD_CURTIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_DAYNAME"))
#ifdef SQL_FN_TD_DAYNAME
	    return SQL_FN_TD_DAYNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_DAYOFMONTH"))
#ifdef SQL_FN_TD_DAYOFMONTH
	    return SQL_FN_TD_DAYOFMONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_DAYOFWEEK"))
#ifdef SQL_FN_TD_DAYOFWEEK
	    return SQL_FN_TD_DAYOFWEEK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_DAYOFYEAR"))
#ifdef SQL_FN_TD_DAYOFYEAR
	    return SQL_FN_TD_DAYOFYEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_HOUR"))
#ifdef SQL_FN_TD_HOUR
	    return SQL_FN_TD_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_MINUTE"))
#ifdef SQL_FN_TD_MINUTE
	    return SQL_FN_TD_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_MONTH"))
#ifdef SQL_FN_TD_MONTH
	    return SQL_FN_TD_MONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_MONTHNAME"))
#ifdef SQL_FN_TD_MONTHNAME
	    return SQL_FN_TD_MONTHNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_NOW"))
#ifdef SQL_FN_TD_NOW
	    return SQL_FN_TD_NOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_QUARTER"))
#ifdef SQL_FN_TD_QUARTER
	    return SQL_FN_TD_QUARTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_SECOND"))
#ifdef SQL_FN_TD_SECOND
	    return SQL_FN_TD_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_TIMESTAMPADD"))
#ifdef SQL_FN_TD_TIMESTAMPADD
	    return SQL_FN_TD_TIMESTAMPADD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_TIMESTAMPDIFF"))
#ifdef SQL_FN_TD_TIMESTAMPDIFF
	    return SQL_FN_TD_TIMESTAMPDIFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_WEEK"))
#ifdef SQL_FN_TD_WEEK
	    return SQL_FN_TD_WEEK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_YEAR"))
#ifdef SQL_FN_TD_YEAR
	    return SQL_FN_TD_YEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TSI_DAY"))
#ifdef SQL_FN_TSI_DAY
	    return SQL_FN_TSI_DAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TSI_FRAC_SECOND"))
#ifdef SQL_FN_TSI_FRAC_SECOND
	    return SQL_FN_TSI_FRAC_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TSI_HOUR"))
#ifdef SQL_FN_TSI_HOUR
	    return SQL_FN_TSI_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TSI_MINUTE"))
#ifdef SQL_FN_TSI_MINUTE
	    return SQL_FN_TSI_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TSI_MONTH"))
#ifdef SQL_FN_TSI_MONTH
	    return SQL_FN_TSI_MONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TSI_QUARTER"))
#ifdef SQL_FN_TSI_QUARTER
	    return SQL_FN_TSI_QUARTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TSI_SECOND"))
#ifdef SQL_FN_TSI_SECOND
	    return SQL_FN_TSI_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TSI_WEEK"))
#ifdef SQL_FN_TSI_WEEK
	    return SQL_FN_TSI_WEEK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TSI_YEAR"))
#ifdef SQL_FN_TSI_YEAR
	    return SQL_FN_TSI_YEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GB_GROUP_BY_CONTAINS_SELECT"))
#ifdef SQL_GB_GROUP_BY_CONTAINS_SELECT
	    return SQL_GB_GROUP_BY_CONTAINS_SELECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GB_GROUP_BY_EQUALS_SELECT"))
#ifdef SQL_GB_GROUP_BY_EQUALS_SELECT
	    return SQL_GB_GROUP_BY_EQUALS_SELECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GB_NOT_SUPPORTED"))
#ifdef SQL_GB_NOT_SUPPORTED
	    return SQL_GB_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GB_NO_RELATION"))
#ifdef SQL_GB_NO_RELATION
	    return SQL_GB_NO_RELATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GD_ANY_COLUMN"))
#ifdef SQL_GD_ANY_COLUMN
	    return SQL_GD_ANY_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GD_ANY_ORDER"))
#ifdef SQL_GD_ANY_ORDER
	    return SQL_GD_ANY_ORDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GD_BLOCK"))
#ifdef SQL_GD_BLOCK
	    return SQL_GD_BLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GD_BOUND"))
#ifdef SQL_GD_BOUND
	    return SQL_GD_BOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GETDATA_EXTENSIONS"))
#ifdef SQL_GETDATA_EXTENSIONS
	    return SQL_GETDATA_EXTENSIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GET_BOOKMARK"))
#ifdef SQL_GET_BOOKMARK
	    return SQL_GET_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GROUP_BY"))
#ifdef SQL_GROUP_BY
	    return SQL_GROUP_BY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IC_LOWER"))
#ifdef SQL_IC_LOWER
	    return SQL_IC_LOWER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IC_MIXED"))
#ifdef SQL_IC_MIXED
	    return SQL_IC_MIXED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IC_SENSITIVE"))
#ifdef SQL_IC_SENSITIVE
	    return SQL_IC_SENSITIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IC_UPPER"))
#ifdef SQL_IC_UPPER
	    return SQL_IC_UPPER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IDENTIFIER_CASE"))
#ifdef SQL_IDENTIFIER_CASE
	    return SQL_IDENTIFIER_CASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IDENTIFIER_QUOTE_CHAR"))
#ifdef SQL_IDENTIFIER_QUOTE_CHAR
	    return SQL_IDENTIFIER_QUOTE_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IGNORE"))
#ifdef SQL_IGNORE
	    return SQL_IGNORE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INDEX_ALL"))
#ifdef SQL_INDEX_ALL
	    return SQL_INDEX_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INDEX_CLUSTERED"))
#ifdef SQL_INDEX_CLUSTERED
	    return SQL_INDEX_CLUSTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INDEX_HASHED"))
#ifdef SQL_INDEX_HASHED
	    return SQL_INDEX_HASHED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INDEX_OTHER"))
#ifdef SQL_INDEX_OTHER
	    return SQL_INDEX_OTHER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INDEX_UNIQUE"))
#ifdef SQL_INDEX_UNIQUE
	    return SQL_INDEX_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INFO_DRIVER_START"))
#ifdef SQL_INFO_DRIVER_START
	    return SQL_INFO_DRIVER_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INFO_FIRST"))
#ifdef SQL_INFO_FIRST
	    return SQL_INFO_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INFO_LAST"))
#ifdef SQL_INFO_LAST
	    return SQL_INFO_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTEGER"))
#ifdef SQL_INTEGER
	    return SQL_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INVALID_HANDLE"))
#ifdef SQL_INVALID_HANDLE
	    return SQL_INVALID_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_KEYSET_SIZE"))
#ifdef SQL_KEYSET_SIZE
	    return SQL_KEYSET_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_KEYSET_SIZE_DEFAULT"))
#ifdef SQL_KEYSET_SIZE_DEFAULT
	    return SQL_KEYSET_SIZE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_KEYWORDS"))
#ifdef SQL_KEYWORDS
	    return SQL_KEYWORDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LCK_EXCLUSIVE"))
#ifdef SQL_LCK_EXCLUSIVE
	    return SQL_LCK_EXCLUSIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LCK_NO_CHANGE"))
#ifdef SQL_LCK_NO_CHANGE
	    return SQL_LCK_NO_CHANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LCK_UNLOCK"))
#ifdef SQL_LCK_UNLOCK
	    return SQL_LCK_UNLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LEN_DATA_AT_EXEC_OFFSET"))
#ifdef SQL_LEN_DATA_AT_EXEC_OFFSET
	    return SQL_LEN_DATA_AT_EXEC_OFFSET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LIKE_ESCAPE_CLAUSE"))
#ifdef SQL_LIKE_ESCAPE_CLAUSE
	    return SQL_LIKE_ESCAPE_CLAUSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LIKE_ONLY"))
#ifdef SQL_LIKE_ONLY
	    return SQL_LIKE_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LOCK_EXCLUSIVE"))
#ifdef SQL_LOCK_EXCLUSIVE
	    return SQL_LOCK_EXCLUSIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LOCK_NO_CHANGE"))
#ifdef SQL_LOCK_NO_CHANGE
	    return SQL_LOCK_NO_CHANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LOCK_TYPES"))
#ifdef SQL_LOCK_TYPES
	    return SQL_LOCK_TYPES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LOCK_UNLOCK"))
#ifdef SQL_LOCK_UNLOCK
	    return SQL_LOCK_UNLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LOGIN_TIMEOUT"))
#ifdef SQL_LOGIN_TIMEOUT
	    return SQL_LOGIN_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LOGIN_TIMEOUT_DEFAULT"))
#ifdef SQL_LOGIN_TIMEOUT_DEFAULT
	    return SQL_LOGIN_TIMEOUT_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LONGVARBINARY"))
#ifdef SQL_LONGVARBINARY
	    return SQL_LONGVARBINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LONGVARCHAR"))
#ifdef SQL_LONGVARCHAR
	    return SQL_LONGVARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_BINARY_LITERAL_LEN"))
#ifdef SQL_MAX_BINARY_LITERAL_LEN
	    return SQL_MAX_BINARY_LITERAL_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_CHAR_LITERAL_LEN"))
#ifdef SQL_MAX_CHAR_LITERAL_LEN
	    return SQL_MAX_CHAR_LITERAL_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_COLUMNS_IN_GROUP_BY"))
#ifdef SQL_MAX_COLUMNS_IN_GROUP_BY
	    return SQL_MAX_COLUMNS_IN_GROUP_BY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_COLUMNS_IN_INDEX"))
#ifdef SQL_MAX_COLUMNS_IN_INDEX
	    return SQL_MAX_COLUMNS_IN_INDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_COLUMNS_IN_ORDER_BY"))
#ifdef SQL_MAX_COLUMNS_IN_ORDER_BY
	    return SQL_MAX_COLUMNS_IN_ORDER_BY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_COLUMNS_IN_SELECT"))
#ifdef SQL_MAX_COLUMNS_IN_SELECT
	    return SQL_MAX_COLUMNS_IN_SELECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_COLUMNS_IN_TABLE"))
#ifdef SQL_MAX_COLUMNS_IN_TABLE
	    return SQL_MAX_COLUMNS_IN_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_COLUMN_NAME_LEN"))
#ifdef SQL_MAX_COLUMN_NAME_LEN
	    return SQL_MAX_COLUMN_NAME_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_CURSOR_NAME_LEN"))
#ifdef SQL_MAX_CURSOR_NAME_LEN
	    return SQL_MAX_CURSOR_NAME_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_DSN_LENGTH"))
#ifdef SQL_MAX_DSN_LENGTH
	    return SQL_MAX_DSN_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_INDEX_SIZE"))
#ifdef SQL_MAX_INDEX_SIZE
	    return SQL_MAX_INDEX_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_LENGTH"))
#ifdef SQL_MAX_LENGTH
	    return SQL_MAX_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_LENGTH_DEFAULT"))
#ifdef SQL_MAX_LENGTH_DEFAULT
	    return SQL_MAX_LENGTH_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_MESSAGE_LENGTH"))
#ifdef SQL_MAX_MESSAGE_LENGTH
	    return SQL_MAX_MESSAGE_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_OPTION_STRING_LENGTH"))
#ifdef SQL_MAX_OPTION_STRING_LENGTH
	    return SQL_MAX_OPTION_STRING_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_OWNER_NAME_LEN"))
#ifdef SQL_MAX_OWNER_NAME_LEN
	    return SQL_MAX_OWNER_NAME_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_PROCEDURE_NAME_LEN"))
#ifdef SQL_MAX_PROCEDURE_NAME_LEN
	    return SQL_MAX_PROCEDURE_NAME_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_QUALIFIER_NAME_LEN"))
#ifdef SQL_MAX_QUALIFIER_NAME_LEN
	    return SQL_MAX_QUALIFIER_NAME_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_ROWS"))
#ifdef SQL_MAX_ROWS
	    return SQL_MAX_ROWS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_ROWS_DEFAULT"))
#ifdef SQL_MAX_ROWS_DEFAULT
	    return SQL_MAX_ROWS_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_ROW_SIZE"))
#ifdef SQL_MAX_ROW_SIZE
	    return SQL_MAX_ROW_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_ROW_SIZE_INCLUDES_LONG"))
#ifdef SQL_MAX_ROW_SIZE_INCLUDES_LONG
	    return SQL_MAX_ROW_SIZE_INCLUDES_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_STATEMENT_LEN"))
#ifdef SQL_MAX_STATEMENT_LEN
	    return SQL_MAX_STATEMENT_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_TABLES_IN_SELECT"))
#ifdef SQL_MAX_TABLES_IN_SELECT
	    return SQL_MAX_TABLES_IN_SELECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_TABLE_NAME_LEN"))
#ifdef SQL_MAX_TABLE_NAME_LEN
	    return SQL_MAX_TABLE_NAME_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_USER_NAME_LEN"))
#ifdef SQL_MAX_USER_NAME_LEN
	    return SQL_MAX_USER_NAME_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MODE_DEFAULT"))
#ifdef SQL_MODE_DEFAULT
	    return SQL_MODE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MODE_READ_ONLY"))
#ifdef SQL_MODE_READ_ONLY
	    return SQL_MODE_READ_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MODE_READ_WRITE"))
#ifdef SQL_MODE_READ_WRITE
	    return SQL_MODE_READ_WRITE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MULTIPLE_ACTIVE_TXN"))
#ifdef SQL_MULTIPLE_ACTIVE_TXN
	    return SQL_MULTIPLE_ACTIVE_TXN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MULT_RESULT_SETS"))
#ifdef SQL_MULT_RESULT_SETS
	    return SQL_MULT_RESULT_SETS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NC_END"))
#ifdef SQL_NC_END
	    return SQL_NC_END;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NC_HIGH"))
#ifdef SQL_NC_HIGH
	    return SQL_NC_HIGH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NC_LOW"))
#ifdef SQL_NC_LOW
	    return SQL_NC_LOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NC_START"))
#ifdef SQL_NC_START
	    return SQL_NC_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NEED_DATA"))
#ifdef SQL_NEED_DATA
	    return SQL_NEED_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NEED_LONG_DATA_LEN"))
#ifdef SQL_NEED_LONG_DATA_LEN
	    return SQL_NEED_LONG_DATA_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NNC_NON_NULL"))
#ifdef SQL_NNC_NON_NULL
	    return SQL_NNC_NON_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NNC_NULL"))
#ifdef SQL_NNC_NULL
	    return SQL_NNC_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NON_NULLABLE_COLUMNS"))
#ifdef SQL_NON_NULLABLE_COLUMNS
	    return SQL_NON_NULLABLE_COLUMNS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NOSCAN"))
#ifdef SQL_NOSCAN
	    return SQL_NOSCAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NOSCAN_DEFAULT"))
#ifdef SQL_NOSCAN_DEFAULT
	    return SQL_NOSCAN_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NOSCAN_OFF"))
#ifdef SQL_NOSCAN_OFF
	    return SQL_NOSCAN_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NOSCAN_ON"))
#ifdef SQL_NOSCAN_ON
	    return SQL_NOSCAN_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NO_CONVERT"))
#ifdef SQL_NO_CONVERT
	    return SQL_NO_CONVERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NO_DATA_FOUND"))
#ifdef SQL_NO_DATA_FOUND
	    return SQL_NO_DATA_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NO_NULLS"))
#ifdef SQL_NO_NULLS
	    return SQL_NO_NULLS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NO_TOTAL"))
#ifdef SQL_NO_TOTAL
	    return SQL_NO_TOTAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NTS"))
#ifdef SQL_NTS
	    return SQL_NTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULLABLE"))
#ifdef SQL_NULLABLE
	    return SQL_NULLABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULLABLE_UNKNOWN"))
#ifdef SQL_NULLABLE_UNKNOWN
	    return SQL_NULLABLE_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NUMERIC"))
#ifdef SQL_NUMERIC
	    return SQL_NUMERIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NUMERIC_FUNCTIONS"))
#ifdef SQL_NUMERIC_FUNCTIONS
	    return SQL_NUMERIC_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NUM_EXTENSIONS"))
#ifdef SQL_NUM_EXTENSIONS
	    return SQL_NUM_EXTENSIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NUM_FUNCTIONS"))
#ifdef SQL_NUM_FUNCTIONS
	    return SQL_NUM_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OAC_LEVEL1"))
#ifdef SQL_OAC_LEVEL1
	    return SQL_OAC_LEVEL1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OAC_LEVEL2"))
#ifdef SQL_OAC_LEVEL2
	    return SQL_OAC_LEVEL2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OAC_NONE"))
#ifdef SQL_OAC_NONE
	    return SQL_OAC_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ODBC_API_CONFORMANCE"))
#ifdef SQL_ODBC_API_CONFORMANCE
	    return SQL_ODBC_API_CONFORMANCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ODBC_CURSORS"))
#ifdef SQL_ODBC_CURSORS
	    return SQL_ODBC_CURSORS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ODBC_SAG_CLI_CONFORMANCE"))
#ifdef SQL_ODBC_SAG_CLI_CONFORMANCE
	    return SQL_ODBC_SAG_CLI_CONFORMANCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ODBC_SQL_CONFORMANCE"))
#ifdef SQL_ODBC_SQL_CONFORMANCE
	    return SQL_ODBC_SQL_CONFORMANCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ODBC_SQL_OPT_IEF"))
#ifdef SQL_ODBC_SQL_OPT_IEF
	    return SQL_ODBC_SQL_OPT_IEF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ODBC_VER"))
#ifdef SQL_ODBC_VER
	    return SQL_ODBC_VER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OJ_ALL_COMPARISON_OPS"))
#ifdef SQL_OJ_ALL_COMPARISON_OPS
	    return SQL_OJ_ALL_COMPARISON_OPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OJ_CAPABILITIES"))
#ifdef SQL_OJ_CAPABILITIES
	    return SQL_OJ_CAPABILITIES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OJ_FULL"))
#ifdef SQL_OJ_FULL
	    return SQL_OJ_FULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OJ_INNER"))
#ifdef SQL_OJ_INNER
	    return SQL_OJ_INNER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OJ_LEFT"))
#ifdef SQL_OJ_LEFT
	    return SQL_OJ_LEFT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OJ_NESTED"))
#ifdef SQL_OJ_NESTED
	    return SQL_OJ_NESTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OJ_NOT_ORDERED"))
#ifdef SQL_OJ_NOT_ORDERED
	    return SQL_OJ_NOT_ORDERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OJ_RIGHT"))
#ifdef SQL_OJ_RIGHT
	    return SQL_OJ_RIGHT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OPT_TRACE"))
#ifdef SQL_OPT_TRACE
	    return SQL_OPT_TRACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OPT_TRACEFILE"))
#ifdef SQL_OPT_TRACEFILE
	    return SQL_OPT_TRACEFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OPT_TRACE_DEFAULT"))
#ifdef SQL_OPT_TRACE_DEFAULT
	    return SQL_OPT_TRACE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OPT_TRACE_OFF"))
#ifdef SQL_OPT_TRACE_OFF
	    return SQL_OPT_TRACE_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OPT_TRACE_ON"))
#ifdef SQL_OPT_TRACE_ON
	    return SQL_OPT_TRACE_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ORDER_BY_COLUMNS_IN_SELECT"))
#ifdef SQL_ORDER_BY_COLUMNS_IN_SELECT
	    return SQL_ORDER_BY_COLUMNS_IN_SELECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OSCC_COMPLIANT"))
#ifdef SQL_OSCC_COMPLIANT
	    return SQL_OSCC_COMPLIANT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OSCC_NOT_COMPLIANT"))
#ifdef SQL_OSCC_NOT_COMPLIANT
	    return SQL_OSCC_NOT_COMPLIANT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OSC_CORE"))
#ifdef SQL_OSC_CORE
	    return SQL_OSC_CORE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OSC_EXTENDED"))
#ifdef SQL_OSC_EXTENDED
	    return SQL_OSC_EXTENDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OSC_MINIMUM"))
#ifdef SQL_OSC_MINIMUM
	    return SQL_OSC_MINIMUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OUTER_JOINS"))
#ifdef SQL_OUTER_JOINS
	    return SQL_OUTER_JOINS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OU_DML_STATEMENTS"))
#ifdef SQL_OU_DML_STATEMENTS
	    return SQL_OU_DML_STATEMENTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OU_INDEX_DEFINITION"))
#ifdef SQL_OU_INDEX_DEFINITION
	    return SQL_OU_INDEX_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OU_PRIVILEGE_DEFINITION"))
#ifdef SQL_OU_PRIVILEGE_DEFINITION
	    return SQL_OU_PRIVILEGE_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OU_PROCEDURE_INVOCATION"))
#ifdef SQL_OU_PROCEDURE_INVOCATION
	    return SQL_OU_PROCEDURE_INVOCATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OU_TABLE_DEFINITION"))
#ifdef SQL_OU_TABLE_DEFINITION
	    return SQL_OU_TABLE_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OWNER_TERM"))
#ifdef SQL_OWNER_TERM
	    return SQL_OWNER_TERM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OWNER_USAGE"))
#ifdef SQL_OWNER_USAGE
	    return SQL_OWNER_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PACKET_SIZE"))
#ifdef SQL_PACKET_SIZE
	    return SQL_PACKET_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_INPUT"))
#ifdef SQL_PARAM_INPUT
	    return SQL_PARAM_INPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_INPUT_OUTPUT"))
#ifdef SQL_PARAM_INPUT_OUTPUT
	    return SQL_PARAM_INPUT_OUTPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_OUTPUT"))
#ifdef SQL_PARAM_OUTPUT
	    return SQL_PARAM_OUTPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_TYPE_DEFAULT"))
#ifdef SQL_PARAM_TYPE_DEFAULT
	    return SQL_PARAM_TYPE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_TYPE_UNKNOWN"))
#ifdef SQL_PARAM_TYPE_UNKNOWN
	    return SQL_PARAM_TYPE_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PC_NON_PSEUDO"))
#ifdef SQL_PC_NON_PSEUDO
	    return SQL_PC_NON_PSEUDO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PC_PSEUDO"))
#ifdef SQL_PC_PSEUDO
	    return SQL_PC_PSEUDO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PC_UNKNOWN"))
#ifdef SQL_PC_UNKNOWN
	    return SQL_PC_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_POSITION"))
#ifdef SQL_POSITION
	    return SQL_POSITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_POSITIONED_STATEMENTS"))
#ifdef SQL_POSITIONED_STATEMENTS
	    return SQL_POSITIONED_STATEMENTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_POS_ADD"))
#ifdef SQL_POS_ADD
	    return SQL_POS_ADD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_POS_DELETE"))
#ifdef SQL_POS_DELETE
	    return SQL_POS_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_POS_OPERATIONS"))
#ifdef SQL_POS_OPERATIONS
	    return SQL_POS_OPERATIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_POS_POSITION"))
#ifdef SQL_POS_POSITION
	    return SQL_POS_POSITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_POS_REFRESH"))
#ifdef SQL_POS_REFRESH
	    return SQL_POS_REFRESH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_POS_UPDATE"))
#ifdef SQL_POS_UPDATE
	    return SQL_POS_UPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PROCEDURES"))
#ifdef SQL_PROCEDURES
	    return SQL_PROCEDURES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PROCEDURE_TERM"))
#ifdef SQL_PROCEDURE_TERM
	    return SQL_PROCEDURE_TERM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PS_POSITIONED_DELETE"))
#ifdef SQL_PS_POSITIONED_DELETE
	    return SQL_PS_POSITIONED_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PS_POSITIONED_UPDATE"))
#ifdef SQL_PS_POSITIONED_UPDATE
	    return SQL_PS_POSITIONED_UPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PS_SELECT_FOR_UPDATE"))
#ifdef SQL_PS_SELECT_FOR_UPDATE
	    return SQL_PS_SELECT_FOR_UPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PT_FUNCTION"))
#ifdef SQL_PT_FUNCTION
	    return SQL_PT_FUNCTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PT_PROCEDURE"))
#ifdef SQL_PT_PROCEDURE
	    return SQL_PT_PROCEDURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PT_UNKNOWN"))
#ifdef SQL_PT_UNKNOWN
	    return SQL_PT_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QL_END"))
#ifdef SQL_QL_END
	    return SQL_QL_END;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QL_START"))
#ifdef SQL_QL_START
	    return SQL_QL_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QUALIFIER_LOCATION"))
#ifdef SQL_QUALIFIER_LOCATION
	    return SQL_QUALIFIER_LOCATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QUALIFIER_NAME_SEPARATOR"))
#ifdef SQL_QUALIFIER_NAME_SEPARATOR
	    return SQL_QUALIFIER_NAME_SEPARATOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QUALIFIER_TERM"))
#ifdef SQL_QUALIFIER_TERM
	    return SQL_QUALIFIER_TERM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QUALIFIER_USAGE"))
#ifdef SQL_QUALIFIER_USAGE
	    return SQL_QUALIFIER_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QUERY_TIMEOUT"))
#ifdef SQL_QUERY_TIMEOUT
	    return SQL_QUERY_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QUERY_TIMEOUT_DEFAULT"))
#ifdef SQL_QUERY_TIMEOUT_DEFAULT
	    return SQL_QUERY_TIMEOUT_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QUICK"))
#ifdef SQL_QUICK
	    return SQL_QUICK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QUIET_MODE"))
#ifdef SQL_QUIET_MODE
	    return SQL_QUIET_MODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QUOTED_IDENTIFIER_CASE"))
#ifdef SQL_QUOTED_IDENTIFIER_CASE
	    return SQL_QUOTED_IDENTIFIER_CASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QU_DML_STATEMENTS"))
#ifdef SQL_QU_DML_STATEMENTS
	    return SQL_QU_DML_STATEMENTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QU_INDEX_DEFINITION"))
#ifdef SQL_QU_INDEX_DEFINITION
	    return SQL_QU_INDEX_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QU_PRIVILEGE_DEFINITION"))
#ifdef SQL_QU_PRIVILEGE_DEFINITION
	    return SQL_QU_PRIVILEGE_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QU_PROCEDURE_INVOCATION"))
#ifdef SQL_QU_PROCEDURE_INVOCATION
	    return SQL_QU_PROCEDURE_INVOCATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_QU_TABLE_DEFINITION"))
#ifdef SQL_QU_TABLE_DEFINITION
	    return SQL_QU_TABLE_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_RD_DEFAULT"))
#ifdef SQL_RD_DEFAULT
	    return SQL_RD_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_RD_OFF"))
#ifdef SQL_RD_OFF
	    return SQL_RD_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_RD_ON"))
#ifdef SQL_RD_ON
	    return SQL_RD_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_REAL"))
#ifdef SQL_REAL
	    return SQL_REAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_REFRESH"))
#ifdef SQL_REFRESH
	    return SQL_REFRESH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_RESET_PARAMS"))
#ifdef SQL_RESET_PARAMS
	    return SQL_RESET_PARAMS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_RESTRICT"))
#ifdef SQL_RESTRICT
	    return SQL_RESTRICT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_RESULT_COL"))
#ifdef SQL_RESULT_COL
	    return SQL_RESULT_COL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_RETRIEVE_DATA"))
#ifdef SQL_RETRIEVE_DATA
	    return SQL_RETRIEVE_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROLLBACK"))
#ifdef SQL_ROLLBACK
	    return SQL_ROLLBACK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROWSET_SIZE"))
#ifdef SQL_ROWSET_SIZE
	    return SQL_ROWSET_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROWSET_SIZE_DEFAULT"))
#ifdef SQL_ROWSET_SIZE_DEFAULT
	    return SQL_ROWSET_SIZE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROWVER"))
#ifdef SQL_ROWVER
	    return SQL_ROWVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_ADDED"))
#ifdef SQL_ROW_ADDED
	    return SQL_ROW_ADDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_DELETED"))
#ifdef SQL_ROW_DELETED
	    return SQL_ROW_DELETED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_ERROR"))
#ifdef SQL_ROW_ERROR
	    return SQL_ROW_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_NOROW"))
#ifdef SQL_ROW_NOROW
	    return SQL_ROW_NOROW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_NUMBER"))
#ifdef SQL_ROW_NUMBER
	    return SQL_ROW_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_SUCCESS"))
#ifdef SQL_ROW_SUCCESS
	    return SQL_ROW_SUCCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_UPDATED"))
#ifdef SQL_ROW_UPDATED
	    return SQL_ROW_UPDATED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_UPDATES"))
#ifdef SQL_ROW_UPDATES
	    return SQL_ROW_UPDATES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCCO_LOCK"))
#ifdef SQL_SCCO_LOCK
	    return SQL_SCCO_LOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCCO_OPT_ROWVER"))
#ifdef SQL_SCCO_OPT_ROWVER
	    return SQL_SCCO_OPT_ROWVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCCO_OPT_TIMESTAMP"))
#ifdef SQL_SCCO_OPT_TIMESTAMP
	    return SQL_SCCO_OPT_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCCO_OPT_VALUES"))
#ifdef SQL_SCCO_OPT_VALUES
	    return SQL_SCCO_OPT_VALUES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCCO_READ_ONLY"))
#ifdef SQL_SCCO_READ_ONLY
	    return SQL_SCCO_READ_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCOPE_CURROW"))
#ifdef SQL_SCOPE_CURROW
	    return SQL_SCOPE_CURROW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCOPE_SESSION"))
#ifdef SQL_SCOPE_SESSION
	    return SQL_SCOPE_SESSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCOPE_TRANSACTION"))
#ifdef SQL_SCOPE_TRANSACTION
	    return SQL_SCOPE_TRANSACTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCROLL_CONCURRENCY"))
#ifdef SQL_SCROLL_CONCURRENCY
	    return SQL_SCROLL_CONCURRENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCROLL_DYNAMIC"))
#ifdef SQL_SCROLL_DYNAMIC
	    return SQL_SCROLL_DYNAMIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCROLL_FORWARD_ONLY"))
#ifdef SQL_SCROLL_FORWARD_ONLY
	    return SQL_SCROLL_FORWARD_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCROLL_KEYSET_DRIVEN"))
#ifdef SQL_SCROLL_KEYSET_DRIVEN
	    return SQL_SCROLL_KEYSET_DRIVEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCROLL_OPTIONS"))
#ifdef SQL_SCROLL_OPTIONS
	    return SQL_SCROLL_OPTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCROLL_STATIC"))
#ifdef SQL_SCROLL_STATIC
	    return SQL_SCROLL_STATIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SC_NON_UNIQUE"))
#ifdef SQL_SC_NON_UNIQUE
	    return SQL_SC_NON_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SC_TRY_UNIQUE"))
#ifdef SQL_SC_TRY_UNIQUE
	    return SQL_SC_TRY_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SC_UNIQUE"))
#ifdef SQL_SC_UNIQUE
	    return SQL_SC_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SEARCHABLE"))
#ifdef SQL_SEARCHABLE
	    return SQL_SEARCHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SEARCH_PATTERN_ESCAPE"))
#ifdef SQL_SEARCH_PATTERN_ESCAPE
	    return SQL_SEARCH_PATTERN_ESCAPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SERVER_NAME"))
#ifdef SQL_SERVER_NAME
	    return SQL_SERVER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SETPARAM_VALUE_MAX"))
#ifdef SQL_SETPARAM_VALUE_MAX
	    return SQL_SETPARAM_VALUE_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SET_NULL"))
#ifdef SQL_SET_NULL
	    return SQL_SET_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SIGNED_OFFSET"))
#ifdef SQL_SIGNED_OFFSET
	    return SQL_SIGNED_OFFSET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SIMULATE_CURSOR"))
#ifdef SQL_SIMULATE_CURSOR
	    return SQL_SIMULATE_CURSOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SMALLINT"))
#ifdef SQL_SMALLINT
	    return SQL_SMALLINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SOLID_XLATOPT_7BITSCAND"))
#ifdef SQL_SOLID_XLATOPT_7BITSCAND
	    return SQL_SOLID_XLATOPT_7BITSCAND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SOLID_XLATOPT_ANSI"))
#ifdef SQL_SOLID_XLATOPT_ANSI
	    return SQL_SOLID_XLATOPT_ANSI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SOLID_XLATOPT_DEFAULT"))
#ifdef SQL_SOLID_XLATOPT_DEFAULT
	    return SQL_SOLID_XLATOPT_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SOLID_XLATOPT_NOCNV"))
#ifdef SQL_SOLID_XLATOPT_NOCNV
	    return SQL_SOLID_XLATOPT_NOCNV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SOLID_XLATOPT_PCOEM"))
#ifdef SQL_SOLID_XLATOPT_PCOEM
	    return SQL_SOLID_XLATOPT_PCOEM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SO_DYNAMIC"))
#ifdef SQL_SO_DYNAMIC
	    return SQL_SO_DYNAMIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SO_FORWARD_ONLY"))
#ifdef SQL_SO_FORWARD_ONLY
	    return SQL_SO_FORWARD_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SO_KEYSET_DRIVEN"))
#ifdef SQL_SO_KEYSET_DRIVEN
	    return SQL_SO_KEYSET_DRIVEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SO_MIXED"))
#ifdef SQL_SO_MIXED
	    return SQL_SO_MIXED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SO_STATIC"))
#ifdef SQL_SO_STATIC
	    return SQL_SO_STATIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SPECIAL_CHARACTERS"))
#ifdef SQL_SPECIAL_CHARACTERS
	    return SQL_SPECIAL_CHARACTERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SPEC_MAJOR"))
#ifdef SQL_SPEC_MAJOR
	    return SQL_SPEC_MAJOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SPEC_MINOR"))
#ifdef SQL_SPEC_MINOR
	    return SQL_SPEC_MINOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQLSTATE_SIZE"))
#ifdef SQL_SQLSTATE_SIZE
	    return SQL_SQLSTATE_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQ_COMPARISON"))
#ifdef SQL_SQ_COMPARISON
	    return SQL_SQ_COMPARISON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQ_CORRELATED_SUBQUERIES"))
#ifdef SQL_SQ_CORRELATED_SUBQUERIES
	    return SQL_SQ_CORRELATED_SUBQUERIES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQ_EXISTS"))
#ifdef SQL_SQ_EXISTS
	    return SQL_SQ_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQ_IN"))
#ifdef SQL_SQ_IN
	    return SQL_SQ_IN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQ_QUANTIFIED"))
#ifdef SQL_SQ_QUANTIFIED
	    return SQL_SQ_QUANTIFIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SS_ADDITIONS"))
#ifdef SQL_SS_ADDITIONS
	    return SQL_SS_ADDITIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SS_DELETIONS"))
#ifdef SQL_SS_DELETIONS
	    return SQL_SS_DELETIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SS_UPDATES"))
#ifdef SQL_SS_UPDATES
	    return SQL_SS_UPDATES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_STATIC_SENSITIVITY"))
#ifdef SQL_STATIC_SENSITIVITY
	    return SQL_STATIC_SENSITIVITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_STILL_EXECUTING"))
#ifdef SQL_STILL_EXECUTING
	    return SQL_STILL_EXECUTING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_STMT_OPT_MAX"))
#ifdef SQL_STMT_OPT_MAX
	    return SQL_STMT_OPT_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_STMT_OPT_MIN"))
#ifdef SQL_STMT_OPT_MIN
	    return SQL_STMT_OPT_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_STRING_FUNCTIONS"))
#ifdef SQL_STRING_FUNCTIONS
	    return SQL_STRING_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SUBQUERIES"))
#ifdef SQL_SUBQUERIES
	    return SQL_SUBQUERIES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SUCCESS"))
#ifdef SQL_SUCCESS
	    return SQL_SUCCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SUCCESS_WITH_INFO"))
#ifdef SQL_SUCCESS_WITH_INFO
	    return SQL_SUCCESS_WITH_INFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SYSTEM_FUNCTIONS"))
#ifdef SQL_SYSTEM_FUNCTIONS
	    return SQL_SYSTEM_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TABLE_STAT"))
#ifdef SQL_TABLE_STAT
	    return SQL_TABLE_STAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TABLE_TERM"))
#ifdef SQL_TABLE_TERM
	    return SQL_TABLE_TERM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TC_ALL"))
#ifdef SQL_TC_ALL
	    return SQL_TC_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TC_DDL_COMMIT"))
#ifdef SQL_TC_DDL_COMMIT
	    return SQL_TC_DDL_COMMIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TC_DDL_IGNORE"))
#ifdef SQL_TC_DDL_IGNORE
	    return SQL_TC_DDL_IGNORE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TC_DML"))
#ifdef SQL_TC_DML
	    return SQL_TC_DML;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TC_NONE"))
#ifdef SQL_TC_NONE
	    return SQL_TC_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TIME"))
#ifdef SQL_TIME
	    return SQL_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TIMEDATE_ADD_INTERVALS"))
#ifdef SQL_TIMEDATE_ADD_INTERVALS
	    return SQL_TIMEDATE_ADD_INTERVALS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TIMEDATE_DIFF_INTERVALS"))
#ifdef SQL_TIMEDATE_DIFF_INTERVALS
	    return SQL_TIMEDATE_DIFF_INTERVALS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TIMEDATE_FUNCTIONS"))
#ifdef SQL_TIMEDATE_FUNCTIONS
	    return SQL_TIMEDATE_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TIMESTAMP"))
#ifdef SQL_TIMESTAMP
	    return SQL_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TINYINT"))
#ifdef SQL_TINYINT
	    return SQL_TINYINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TRANSLATE_DLL"))
#ifdef SQL_TRANSLATE_DLL
	    return SQL_TRANSLATE_DLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TRANSLATE_OPTION"))
#ifdef SQL_TRANSLATE_OPTION
	    return SQL_TRANSLATE_OPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TXN_CAPABLE"))
#ifdef SQL_TXN_CAPABLE
	    return SQL_TXN_CAPABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TXN_ISOLATION"))
#ifdef SQL_TXN_ISOLATION
	    return SQL_TXN_ISOLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TXN_ISOLATION_OPTION"))
#ifdef SQL_TXN_ISOLATION_OPTION
	    return SQL_TXN_ISOLATION_OPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TXN_READ_COMMITTED"))
#ifdef SQL_TXN_READ_COMMITTED
	    return SQL_TXN_READ_COMMITTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TXN_READ_UNCOMMITTED"))
#ifdef SQL_TXN_READ_UNCOMMITTED
	    return SQL_TXN_READ_UNCOMMITTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TXN_REPEATABLE_READ"))
#ifdef SQL_TXN_REPEATABLE_READ
	    return SQL_TXN_REPEATABLE_READ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TXN_SERIALIZABLE"))
#ifdef SQL_TXN_SERIALIZABLE
	    return SQL_TXN_SERIALIZABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TXN_VERSIONING"))
#ifdef SQL_TXN_VERSIONING
	    return SQL_TXN_VERSIONING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TYPE_MAX"))
#ifdef SQL_TYPE_MAX
	    return SQL_TYPE_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TYPE_MIN"))
#ifdef SQL_TYPE_MIN
	    return SQL_TYPE_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UB_DEFAULT"))
#ifdef SQL_UB_DEFAULT
	    return SQL_UB_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UB_OFF"))
#ifdef SQL_UB_OFF
	    return SQL_UB_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UB_ON"))
#ifdef SQL_UB_ON
	    return SQL_UB_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNBIND"))
#ifdef SQL_UNBIND
	    return SQL_UNBIND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNION"))
#ifdef SQL_UNION
	    return SQL_UNION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNSEARCHABLE"))
#ifdef SQL_UNSEARCHABLE
	    return SQL_UNSEARCHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNSIGNED_OFFSET"))
#ifdef SQL_UNSIGNED_OFFSET
	    return SQL_UNSIGNED_OFFSET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UPDATE"))
#ifdef SQL_UPDATE
	    return SQL_UPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_USER_NAME"))
#ifdef SQL_USER_NAME
	    return SQL_USER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_USE_BOOKMARKS"))
#ifdef SQL_USE_BOOKMARKS
	    return SQL_USE_BOOKMARKS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_U_UNION"))
#ifdef SQL_U_UNION
	    return SQL_U_UNION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_U_UNION_ALL"))
#ifdef SQL_U_UNION_ALL
	    return SQL_U_UNION_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_VARBINARY"))
#ifdef SQL_VARBINARY
	    return SQL_VARBINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_VARCHAR"))
#ifdef SQL_VARCHAR
	    return SQL_VARCHAR;
#else
	    goto not_there;
#endif
/* I added these three types. --mms */
   if (strEQ(name, "SQL_WCHAR"))
#ifdef SQL_WCHAR
      return SQL_WCHAR;
#else
      goto not_there;
#endif
   if (strEQ(name, "SQL_WVARCHAR"))
#ifdef SQL_WVARCHAR
      return SQL_WVARCHAR;
#else
      goto not_there;
#endif
   if (strEQ(name, "SQL_WLONGVARCHAR"))
#ifdef SQL_WLONGVARCHAR
      return SQL_WLONGVARCHAR;
#else
      goto not_there;
#endif
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = DBD::Solid::Const		PACKAGE = DBD::Solid::Const

REQUIRE:    1.929
PROTOTYPES: DISABLE

double
constant(name,arg)
	char *		name
	int		arg

