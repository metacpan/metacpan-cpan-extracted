/*
 *	engn/perldb2/Constants/Constants.xs, engn_perldb2, db2_v6, 1.2 99/01/12 13:51:47
 *
 *	Copyright (c) 1995,1996,1999 International Business Machines Corp.
 */
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <sqlcli.h>
#ifndef AS400
#include <sqlcli1.h>
#include <sqlext.h>
#endif

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
	if (strEQ(name, "DB2CLI_VER"))
#ifdef DB2CLI_VER
	    return DB2CLI_VER;
#else
	    goto not_there;
#endif
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
	if (strEQ(name, "SQLAllocHandle"))
#ifdef SQLAllocHandle
	    return SQLAllocHandle;
#else
	    goto not_there;
#endif
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
	if (strEQ(name, "SQL_ACTIVE_ENVIRONMENTS"))
#ifdef SQL_ACTIVE_ENVIRONMENTS
	    return SQL_ACTIVE_ENVIRONMENTS;
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
	if (strEQ(name, "SQL_AD_ADD_CONSTRAINT_DEFERRABLE"))
#ifdef SQL_AD_ADD_CONSTRAINT_DEFERRABLE
	    return SQL_AD_ADD_CONSTRAINT_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AD_ADD_CONSTRAINT_INITIALLY_DEFERRED"))
#ifdef SQL_AD_ADD_CONSTRAINT_INITIALLY_DEFERRED
	    return SQL_AD_ADD_CONSTRAINT_INITIALLY_DEFERRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AD_ADD_CONSTRAINT_INITIALLY_IMMEDIATE"))
#ifdef SQL_AD_ADD_CONSTRAINT_INITIALLY_IMMEDIATE
	    return SQL_AD_ADD_CONSTRAINT_INITIALLY_IMMEDIATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AD_ADD_CONSTRAINT_NON_DEFERRABLE"))
#ifdef SQL_AD_ADD_CONSTRAINT_NON_DEFERRABLE
	    return SQL_AD_ADD_CONSTRAINT_NON_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AD_ADD_DOMAIN_CONSTRAINT"))
#ifdef SQL_AD_ADD_DOMAIN_CONSTRAINT
	    return SQL_AD_ADD_DOMAIN_CONSTRAINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AD_ADD_DOMAIN_DEFAULT"))
#ifdef SQL_AD_ADD_DOMAIN_DEFAULT
	    return SQL_AD_ADD_DOMAIN_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AD_CONSTRAINT_NAME_DEFINITION"))
#ifdef SQL_AD_CONSTRAINT_NAME_DEFINITION
	    return SQL_AD_CONSTRAINT_NAME_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AD_DROP_DOMAIN_CONSTRAINT"))
#ifdef SQL_AD_DROP_DOMAIN_CONSTRAINT
	    return SQL_AD_DROP_DOMAIN_CONSTRAINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AD_DROP_DOMAIN_DEFAULT"))
#ifdef SQL_AD_DROP_DOMAIN_DEFAULT
	    return SQL_AD_DROP_DOMAIN_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AF_ALL"))
#ifdef SQL_AF_ALL
	    return SQL_AF_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AF_AVG"))
#ifdef SQL_AF_AVG
	    return SQL_AF_AVG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AF_COUNT"))
#ifdef SQL_AF_COUNT
	    return SQL_AF_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AF_DISTINCT"))
#ifdef SQL_AF_DISTINCT
	    return SQL_AF_DISTINCT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AF_MAX"))
#ifdef SQL_AF_MAX
	    return SQL_AF_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AF_MIN"))
#ifdef SQL_AF_MIN
	    return SQL_AF_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AF_SUM"))
#ifdef SQL_AF_SUM
	    return SQL_AF_SUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AGGREGATE_FUNCTIONS"))
#ifdef SQL_AGGREGATE_FUNCTIONS
	    return SQL_AGGREGATE_FUNCTIONS;
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
	if (strEQ(name, "SQL_ALTER_DOMAIN"))
#ifdef SQL_ALTER_DOMAIN
	    return SQL_ALTER_DOMAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ALTER_TABLE"))
#ifdef SQL_ALTER_TABLE
	    return SQL_ALTER_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AM_CONNECTION"))
#ifdef SQL_AM_CONNECTION
	    return SQL_AM_CONNECTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AM_NONE"))
#ifdef SQL_AM_NONE
	    return SQL_AM_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AM_STATEMENT"))
#ifdef SQL_AM_STATEMENT
	    return SQL_AM_STATEMENT;
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
	if (strEQ(name, "SQL_API_ODBC3_ALL_FUNCTIONS"))
#ifdef SQL_API_ODBC3_ALL_FUNCTIONS
	    return SQL_API_ODBC3_ALL_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_ODBC3_ALL_FUNCTIONS_SIZE"))
#ifdef SQL_API_ODBC3_ALL_FUNCTIONS_SIZE
	    return SQL_API_ODBC3_ALL_FUNCTIONS_SIZE;
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
	if (strEQ(name, "SQL_API_SQLALLOCHANDLE"))
#ifdef SQL_API_SQLALLOCHANDLE
	    return SQL_API_SQLALLOCHANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLALLOCHANDLESTD"))
#ifdef SQL_API_SQLALLOCHANDLESTD
	    return SQL_API_SQLALLOCHANDLESTD;
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
	if (strEQ(name, "SQL_API_SQLBINDFILETOCOL"))
#ifdef SQL_API_SQLBINDFILETOCOL
	    return SQL_API_SQLBINDFILETOCOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLBINDFILETOPARAM"))
#ifdef SQL_API_SQLBINDFILETOPARAM
	    return SQL_API_SQLBINDFILETOPARAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLBINDPARAM"))
#ifdef SQL_API_SQLBINDPARAM
	    return SQL_API_SQLBINDPARAM;
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
	if (strEQ(name, "SQL_API_SQLBUILDDATALINK"))
#ifdef SQL_API_SQLBUILDDATALINK
	    return SQL_API_SQLBUILDDATALINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLBULKOPERATIONS"))
#ifdef SQL_API_SQLBULKOPERATIONS
	    return SQL_API_SQLBULKOPERATIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLCANCEL"))
#ifdef SQL_API_SQLCANCEL
	    return SQL_API_SQLCANCEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLCLOSECURSOR"))
#ifdef SQL_API_SQLCLOSECURSOR
	    return SQL_API_SQLCLOSECURSOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLCOLATTRIBUTE"))
#ifdef SQL_API_SQLCOLATTRIBUTE
	    return SQL_API_SQLCOLATTRIBUTE;
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
	if (strEQ(name, "SQL_API_SQLCOPYDESC"))
#ifdef SQL_API_SQLCOPYDESC
	    return SQL_API_SQLCOPYDESC;
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
	if (strEQ(name, "SQL_API_SQLENDTRAN"))
#ifdef SQL_API_SQLENDTRAN
	    return SQL_API_SQLENDTRAN;
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
	if (strEQ(name, "SQL_API_SQLFETCHSCROLL"))
#ifdef SQL_API_SQLFETCHSCROLL
	    return SQL_API_SQLFETCHSCROLL;
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
	if (strEQ(name, "SQL_API_SQLFREEHANDLE"))
#ifdef SQL_API_SQLFREEHANDLE
	    return SQL_API_SQLFREEHANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLFREESTMT"))
#ifdef SQL_API_SQLFREESTMT
	    return SQL_API_SQLFREESTMT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETCONNECTATTR"))
#ifdef SQL_API_SQLGETCONNECTATTR
	    return SQL_API_SQLGETCONNECTATTR;
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
	if (strEQ(name, "SQL_API_SQLGETDATALINKATTR"))
#ifdef SQL_API_SQLGETDATALINKATTR
	    return SQL_API_SQLGETDATALINKATTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETDESCFIELD"))
#ifdef SQL_API_SQLGETDESCFIELD
	    return SQL_API_SQLGETDESCFIELD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETDESCREC"))
#ifdef SQL_API_SQLGETDESCREC
	    return SQL_API_SQLGETDESCREC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETDIAGFIELD"))
#ifdef SQL_API_SQLGETDIAGFIELD
	    return SQL_API_SQLGETDIAGFIELD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETDIAGREC"))
#ifdef SQL_API_SQLGETDIAGREC
	    return SQL_API_SQLGETDIAGREC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETENVATTR"))
#ifdef SQL_API_SQLGETENVATTR
	    return SQL_API_SQLGETENVATTR;
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
	if (strEQ(name, "SQL_API_SQLGETLENGTH"))
#ifdef SQL_API_SQLGETLENGTH
	    return SQL_API_SQLGETLENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETPOSITION"))
#ifdef SQL_API_SQLGETPOSITION
	    return SQL_API_SQLGETPOSITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETSQLCA"))
#ifdef SQL_API_SQLGETSQLCA
	    return SQL_API_SQLGETSQLCA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETSTMTATTR"))
#ifdef SQL_API_SQLGETSTMTATTR
	    return SQL_API_SQLGETSTMTATTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETSTMTOPTION"))
#ifdef SQL_API_SQLGETSTMTOPTION
	    return SQL_API_SQLGETSTMTOPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETSUBSTRING"))
#ifdef SQL_API_SQLGETSUBSTRING
	    return SQL_API_SQLGETSUBSTRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLGETTYPEINFO"))
#ifdef SQL_API_SQLGETTYPEINFO
	    return SQL_API_SQLGETTYPEINFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLINFOEXISTS"))
#ifdef SQL_API_SQLINFOEXISTS
	    return SQL_API_SQLINFOEXISTS;
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
	if (strEQ(name, "SQL_API_SQLSETCOLATTRIBUTES"))
#ifdef SQL_API_SQLSETCOLATTRIBUTES
	    return SQL_API_SQLSETCOLATTRIBUTES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSETCONNECTATTR"))
#ifdef SQL_API_SQLSETCONNECTATTR
	    return SQL_API_SQLSETCONNECTATTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSETCONNECTION"))
#ifdef SQL_API_SQLSETCONNECTION
	    return SQL_API_SQLSETCONNECTION;
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
	if (strEQ(name, "SQL_API_SQLSETDESCFIELD"))
#ifdef SQL_API_SQLSETDESCFIELD
	    return SQL_API_SQLSETDESCFIELD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSETDESCREC"))
#ifdef SQL_API_SQLSETDESCREC
	    return SQL_API_SQLSETDESCREC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_API_SQLSETENVATTR"))
#ifdef SQL_API_SQLSETENVATTR
	    return SQL_API_SQLSETENVATTR;
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
	if (strEQ(name, "SQL_API_SQLSETSTMTATTR"))
#ifdef SQL_API_SQLSETSTMTATTR
	    return SQL_API_SQLSETSTMTATTR;
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
	if (strEQ(name, "SQL_ARD_TYPE"))
#ifdef SQL_ARD_TYPE
	    return SQL_ARD_TYPE;
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
	if (strEQ(name, "SQL_ASYNC_MODE"))
#ifdef SQL_ASYNC_MODE
	    return SQL_ASYNC_MODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATOMIC_DEFAULT"))
#ifdef SQL_ATOMIC_DEFAULT
	    return SQL_ATOMIC_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATOMIC_NO"))
#ifdef SQL_ATOMIC_NO
	    return SQL_ATOMIC_NO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATOMIC_YES"))
#ifdef SQL_ATOMIC_YES
	    return SQL_ATOMIC_YES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ACCESS_MODE"))
#ifdef SQL_ATTR_ACCESS_MODE
	    return SQL_ATTR_ACCESS_MODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_APP_PARAM_DESC"))
#ifdef SQL_ATTR_APP_PARAM_DESC
	    return SQL_ATTR_APP_PARAM_DESC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_APP_ROW_DESC"))
#ifdef SQL_ATTR_APP_ROW_DESC
	    return SQL_ATTR_APP_ROW_DESC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ASYNC_ENABLE"))
#ifdef SQL_ATTR_ASYNC_ENABLE
	    return SQL_ATTR_ASYNC_ENABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_AUTOCOMMIT"))
#ifdef SQL_ATTR_AUTOCOMMIT
	    return SQL_ATTR_AUTOCOMMIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_AUTO_IPD"))
#ifdef SQL_ATTR_AUTO_IPD
	    return SQL_ATTR_AUTO_IPD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CLISCHEMA"))
#ifdef SQL_ATTR_CLISCHEMA
	    return SQL_ATTR_CLISCHEMA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CLOSEOPEN"))
#ifdef SQL_ATTR_CLOSEOPEN
	    return SQL_ATTR_CLOSEOPEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CLOSE_BEHAVIOR"))
#ifdef SQL_ATTR_CLOSE_BEHAVIOR
	    return SQL_ATTR_CLOSE_BEHAVIOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CALL_RETURN"))
#ifdef SQL_ATTR_CALL_RETURN
	    return SQL_ATTR_CALL_RETURN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ROWCOUNT_PREFETCH"))
#ifdef SQL_ATTR_ROWCOUNT_PREFETCH
	    return SQL_ATTR_ROWCOUNT_PREFETCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROWCOUNT_PREFETCH_ON"))
#ifdef SQL_ROWCOUNT_PREFETCH_ON
	    return SQL_ROWCOUNT_PREFETCH_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROWCOUNT_PREFETCH_OFF"))
#ifdef SQL_ROWCOUNT_PREFETCH_OFF
	    return SQL_ROWCOUNT_PREFETCH_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CONCURRENCY"))
#ifdef SQL_ATTR_CONCURRENCY
	    return SQL_ATTR_CONCURRENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CONNECTION_DEAD"))
#ifdef SQL_ATTR_CONNECTION_DEAD
	    return SQL_ATTR_CONNECTION_DEAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CONNECTION_POOLING"))
#ifdef SQL_ATTR_CONNECTION_POOLING
	    return SQL_ATTR_CONNECTION_POOLING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CONNECTION_TIMEOUT"))
#ifdef SQL_ATTR_CONNECTION_TIMEOUT
	    return SQL_ATTR_CONNECTION_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CONNECTTYPE"))
#ifdef SQL_ATTR_CONNECTTYPE
	    return SQL_ATTR_CONNECTTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CONN_CONTEXT"))
#ifdef SQL_ATTR_CONN_CONTEXT
	    return SQL_ATTR_CONN_CONTEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CP_MATCH"))
#ifdef SQL_ATTR_CP_MATCH
	    return SQL_ATTR_CP_MATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CURRENT_CATALOG"))
#ifdef SQL_ATTR_CURRENT_CATALOG
	    return SQL_ATTR_CURRENT_CATALOG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CURRENT_PACKAGE_SET"))
#ifdef SQL_ATTR_CURRENT_PACKAGE_SET
	    return SQL_ATTR_CURRENT_PACKAGE_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CURRENT_SCHEMA"))
#ifdef SQL_ATTR_CURRENT_SCHEMA
	    return SQL_ATTR_CURRENT_SCHEMA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CURSOR_HOLD"))
#ifdef SQL_ATTR_CURSOR_HOLD
	    return SQL_ATTR_CURSOR_HOLD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CURSOR_SCROLLABLE"))
#ifdef SQL_ATTR_CURSOR_SCROLLABLE
	    return SQL_ATTR_CURSOR_SCROLLABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CURSOR_SENSITIVITY"))
#ifdef SQL_ATTR_CURSOR_SENSITIVITY
	    return SQL_ATTR_CURSOR_SENSITIVITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_CURSOR_TYPE"))
#ifdef SQL_ATTR_CURSOR_TYPE
	    return SQL_ATTR_CURSOR_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DATALINK_COMMENT"))
#ifdef SQL_ATTR_DATALINK_COMMENT
	    return SQL_ATTR_DATALINK_COMMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DATALINK_LINKTYPE"))
#ifdef SQL_ATTR_DATALINK_LINKTYPE
	    return SQL_ATTR_DATALINK_LINKTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DATALINK_URLCOMPLETE"))
#ifdef SQL_ATTR_DATALINK_URLCOMPLETE
	    return SQL_ATTR_DATALINK_URLCOMPLETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DATALINK_URLPATH"))
#ifdef SQL_ATTR_DATALINK_URLPATH
	    return SQL_ATTR_DATALINK_URLPATH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DATALINK_URLPATHONLY"))
#ifdef SQL_ATTR_DATALINK_URLPATHONLY
	    return SQL_ATTR_DATALINK_URLPATHONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DATALINK_URLSCHEME"))
#ifdef SQL_ATTR_DATALINK_URLSCHEME
	    return SQL_ATTR_DATALINK_URLSCHEME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DATALINK_URLSERVER"))
#ifdef SQL_ATTR_DATALINK_URLSERVER
	    return SQL_ATTR_DATALINK_URLSERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DB2ESTIMATE"))
#ifdef SQL_ATTR_DB2ESTIMATE
	    return SQL_ATTR_DB2ESTIMATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DB2EXPLAIN"))
#ifdef SQL_ATTR_DB2EXPLAIN
	    return SQL_ATTR_DB2EXPLAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DEFERRED_PREPARE"))
#ifdef SQL_ATTR_DEFERRED_PREPARE
	    return SQL_ATTR_DEFERRED_PREPARE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_DISCONNECT_BEHAVIOR"))
#ifdef SQL_ATTR_DISCONNECT_BEHAVIOR
	    return SQL_ATTR_DISCONNECT_BEHAVIOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_EARLYCLOSE"))
#ifdef SQL_ATTR_EARLYCLOSE
	    return SQL_ATTR_EARLYCLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ENABLE_AUTO_IPD"))
#ifdef SQL_ATTR_ENABLE_AUTO_IPD
	    return SQL_ATTR_ENABLE_AUTO_IPD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ENABLE_IPD_SETTING"))
#ifdef SQL_ATTR_ENABLE_IPD_SETTING
	    return SQL_ATTR_ENABLE_IPD_SETTING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ENLIST_IN_DTC"))
#ifdef SQL_ATTR_ENLIST_IN_DTC
	    return SQL_ATTR_ENLIST_IN_DTC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ENLIST_IN_XA"))
#ifdef SQL_ATTR_ENLIST_IN_XA
	    return SQL_ATTR_ENLIST_IN_XA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_FETCH_BOOKMARK_PTR"))
#ifdef SQL_ATTR_FETCH_BOOKMARK_PTR
	    return SQL_ATTR_FETCH_BOOKMARK_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_FORCE_CONVERSION_ON_CLIENT"))
#ifdef SQL_ATTR_FORCE_CONVERSION_ON_CLIENT
	    return SQL_ATTR_FORCE_CONVERSION_ON_CLIENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_IMP_PARAM_DESC"))
#ifdef SQL_ATTR_IMP_PARAM_DESC
	    return SQL_ATTR_IMP_PARAM_DESC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_IMP_ROW_DESC"))
#ifdef SQL_ATTR_IMP_ROW_DESC
	    return SQL_ATTR_IMP_ROW_DESC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_INFO_ACCTSTR"))
#ifdef SQL_ATTR_INFO_ACCTSTR
	    return SQL_ATTR_INFO_ACCTSTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_INFO_APPLNAME"))
#ifdef SQL_ATTR_INFO_APPLNAME
	    return SQL_ATTR_INFO_APPLNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_INFO_PROGRAMNAME"))
#ifdef SQL_ATTR_INFO_PROGRAMNAME
	    return SQL_ATTR_INFO_PROGRAMNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_INFO_USERID"))
#ifdef SQL_ATTR_INFO_USERID
	    return SQL_ATTR_INFO_USERID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_INFO_WRKSTNNAME"))
#ifdef SQL_ATTR_INFO_WRKSTNNAME
	    return SQL_ATTR_INFO_WRKSTNNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_INHERIT_NULL_CONNECT"))
#ifdef SQL_ATTR_INHERIT_NULL_CONNECT
	    return SQL_ATTR_INHERIT_NULL_CONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_KEYSET_SIZE"))
#ifdef SQL_ATTR_KEYSET_SIZE
	    return SQL_ATTR_KEYSET_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_LOGIN_TIMEOUT"))
#ifdef SQL_ATTR_LOGIN_TIMEOUT
	    return SQL_ATTR_LOGIN_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_LONGDATA_COMPAT"))
#ifdef SQL_ATTR_LONGDATA_COMPAT
	    return SQL_ATTR_LONGDATA_COMPAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_MAXCONN"))
#ifdef SQL_ATTR_MAXCONN
	    return SQL_ATTR_MAXCONN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_MAX_LENGTH"))
#ifdef SQL_ATTR_MAX_LENGTH
	    return SQL_ATTR_MAX_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_MAX_ROWS"))
#ifdef SQL_ATTR_MAX_ROWS
	    return SQL_ATTR_MAX_ROWS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_METADATA_ID"))
#ifdef SQL_ATTR_METADATA_ID
	    return SQL_ATTR_METADATA_ID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_MINMEMORY_USAGE"))
#ifdef SQL_ATTR_MINMEMORY_USAGE
	    return SQL_ATTR_MINMEMORY_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_NODESCRIBE"))
#ifdef SQL_ATTR_NODESCRIBE
	    return SQL_ATTR_NODESCRIBE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_NODESCRIBE_INPUT"))
#ifdef SQL_ATTR_NODESCRIBE_INPUT
	    return SQL_ATTR_NODESCRIBE_INPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_NODESCRIBE_OUTPUT"))
#ifdef SQL_ATTR_NODESCRIBE_OUTPUT
	    return SQL_ATTR_NODESCRIBE_OUTPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_NOSCAN"))
#ifdef SQL_ATTR_NOSCAN
	    return SQL_ATTR_NOSCAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ODBC_CURSORS"))
#ifdef SQL_ATTR_ODBC_CURSORS
	    return SQL_ATTR_ODBC_CURSORS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ODBC_VERSION"))
#ifdef SQL_ATTR_ODBC_VERSION
	    return SQL_ATTR_ODBC_VERSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_OPTIMIZE_SQLCOLUMNS"))
#ifdef SQL_ATTR_OPTIMIZE_SQLCOLUMNS
	    return SQL_ATTR_OPTIMIZE_SQLCOLUMNS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_OUTPUT_NTS"))
#ifdef SQL_ATTR_OUTPUT_NTS
	    return SQL_ATTR_OUTPUT_NTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_PACKET_SIZE"))
#ifdef SQL_ATTR_PACKET_SIZE
	    return SQL_ATTR_PACKET_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_PARAMOPT_ATOMIC"))
#ifdef SQL_ATTR_PARAMOPT_ATOMIC
	    return SQL_ATTR_PARAMOPT_ATOMIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_PARAMSET_SIZE"))
#ifdef SQL_ATTR_PARAMSET_SIZE
	    return SQL_ATTR_PARAMSET_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_PARAMS_PROCESSED_PTR"))
#ifdef SQL_ATTR_PARAMS_PROCESSED_PTR
	    return SQL_ATTR_PARAMS_PROCESSED_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_PARAM_BIND_OFFSET_PTR"))
#ifdef SQL_ATTR_PARAM_BIND_OFFSET_PTR
	    return SQL_ATTR_PARAM_BIND_OFFSET_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_PARAM_BIND_TYPE"))
#ifdef SQL_ATTR_PARAM_BIND_TYPE
	    return SQL_ATTR_PARAM_BIND_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_PARAM_OPERATION_PTR"))
#ifdef SQL_ATTR_PARAM_OPERATION_PTR
	    return SQL_ATTR_PARAM_OPERATION_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_PARAM_STATUS_PTR"))
#ifdef SQL_ATTR_PARAM_STATUS_PTR
	    return SQL_ATTR_PARAM_STATUS_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_PREFETCH"))
#ifdef SQL_ATTR_PREFETCH
	    return SQL_ATTR_PREFETCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_PROCESSCTL"))
#ifdef SQL_ATTR_PROCESSCTL
	    return SQL_ATTR_PROCESSCTL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_QUERY_TIMEOUT"))
#ifdef SQL_ATTR_QUERY_TIMEOUT
	    return SQL_ATTR_QUERY_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_QUIET_MODE"))
#ifdef SQL_ATTR_QUIET_MODE
	    return SQL_ATTR_QUIET_MODE;
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
	if (strEQ(name, "SQL_ATTR_RETRIEVE_DATA"))
#ifdef SQL_ATTR_RETRIEVE_DATA
	    return SQL_ATTR_RETRIEVE_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ROWS_FETCHED_PTR"))
#ifdef SQL_ATTR_ROWS_FETCHED_PTR
	    return SQL_ATTR_ROWS_FETCHED_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ROW_ARRAY_SIZE"))
#ifdef SQL_ATTR_ROW_ARRAY_SIZE
	    return SQL_ATTR_ROW_ARRAY_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ROW_BIND_OFFSET_PTR"))
#ifdef SQL_ATTR_ROW_BIND_OFFSET_PTR
	    return SQL_ATTR_ROW_BIND_OFFSET_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ROW_BIND_TYPE"))
#ifdef SQL_ATTR_ROW_BIND_TYPE
	    return SQL_ATTR_ROW_BIND_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ROW_NUMBER"))
#ifdef SQL_ATTR_ROW_NUMBER
	    return SQL_ATTR_ROW_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ROW_OPERATION_PTR"))
#ifdef SQL_ATTR_ROW_OPERATION_PTR
	    return SQL_ATTR_ROW_OPERATION_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_ROW_STATUS_PTR"))
#ifdef SQL_ATTR_ROW_STATUS_PTR
	    return SQL_ATTR_ROW_STATUS_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_SET_SCHEMA"))
#ifdef SQL_ATTR_SET_SCHEMA
	    return SQL_ATTR_SET_SCHEMA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_SIMULATE_CURSOR"))
#ifdef SQL_ATTR_SIMULATE_CURSOR
	    return SQL_ATTR_SIMULATE_CURSOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_STMTTXN_ISOLATION"))
#ifdef SQL_ATTR_STMTTXN_ISOLATION
	    return SQL_ATTR_STMTTXN_ISOLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_SYNC_POINT"))
#ifdef SQL_ATTR_SYNC_POINT
	    return SQL_ATTR_SYNC_POINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_TRACE"))
#ifdef SQL_ATTR_TRACE
	    return SQL_ATTR_TRACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_TRACEFILE"))
#ifdef SQL_ATTR_TRACEFILE
	    return SQL_ATTR_TRACEFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_TRANSLATE_LIB"))
#ifdef SQL_ATTR_TRANSLATE_LIB
	    return SQL_ATTR_TRANSLATE_LIB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_TRANSLATE_OPTION"))
#ifdef SQL_ATTR_TRANSLATE_OPTION
	    return SQL_ATTR_TRANSLATE_OPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_TXN_ISOLATION"))
#ifdef SQL_ATTR_TXN_ISOLATION
	    return SQL_ATTR_TXN_ISOLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_USE_BOOKMARKS"))
#ifdef SQL_ATTR_USE_BOOKMARKS
	    return SQL_ATTR_USE_BOOKMARKS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_WCHARTYPE"))
#ifdef SQL_ATTR_WCHARTYPE
	    return SQL_ATTR_WCHARTYPE;
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
	if (strEQ(name, "SQL_AT_ADD_COLUMN_COLLATION"))
#ifdef SQL_AT_ADD_COLUMN_COLLATION
	    return SQL_AT_ADD_COLUMN_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_ADD_COLUMN_DEFAULT"))
#ifdef SQL_AT_ADD_COLUMN_DEFAULT
	    return SQL_AT_ADD_COLUMN_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_ADD_COLUMN_SINGLE"))
#ifdef SQL_AT_ADD_COLUMN_SINGLE
	    return SQL_AT_ADD_COLUMN_SINGLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_ADD_CONSTRAINT"))
#ifdef SQL_AT_ADD_CONSTRAINT
	    return SQL_AT_ADD_CONSTRAINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_ADD_TABLE_CONSTRAINT"))
#ifdef SQL_AT_ADD_TABLE_CONSTRAINT
	    return SQL_AT_ADD_TABLE_CONSTRAINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_CONSTRAINT_DEFERRABLE"))
#ifdef SQL_AT_CONSTRAINT_DEFERRABLE
	    return SQL_AT_CONSTRAINT_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_CONSTRAINT_INITIALLY_DEFERRED"))
#ifdef SQL_AT_CONSTRAINT_INITIALLY_DEFERRED
	    return SQL_AT_CONSTRAINT_INITIALLY_DEFERRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE"))
#ifdef SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE
	    return SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_CONSTRAINT_NAME_DEFINITION"))
#ifdef SQL_AT_CONSTRAINT_NAME_DEFINITION
	    return SQL_AT_CONSTRAINT_NAME_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_CONSTRAINT_NON_DEFERRABLE"))
#ifdef SQL_AT_CONSTRAINT_NON_DEFERRABLE
	    return SQL_AT_CONSTRAINT_NON_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_DROP_COLUMN"))
#ifdef SQL_AT_DROP_COLUMN
	    return SQL_AT_DROP_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_DROP_COLUMN_CASCADE"))
#ifdef SQL_AT_DROP_COLUMN_CASCADE
	    return SQL_AT_DROP_COLUMN_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_DROP_COLUMN_DEFAULT"))
#ifdef SQL_AT_DROP_COLUMN_DEFAULT
	    return SQL_AT_DROP_COLUMN_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_DROP_COLUMN_RESTRICT"))
#ifdef SQL_AT_DROP_COLUMN_RESTRICT
	    return SQL_AT_DROP_COLUMN_RESTRICT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE"))
#ifdef SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE
	    return SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT"))
#ifdef SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT
	    return SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_AT_SET_COLUMN_DEFAULT"))
#ifdef SQL_AT_SET_COLUMN_DEFAULT
	    return SQL_AT_SET_COLUMN_DEFAULT;
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
	if (strEQ(name, "SQL_BATCH_ROW_COUNT"))
#ifdef SQL_BATCH_ROW_COUNT
	    return SQL_BATCH_ROW_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BATCH_SUPPORT"))
#ifdef SQL_BATCH_SUPPORT
	    return SQL_BATCH_SUPPORT;
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
	if (strEQ(name, "SQL_BIND_TYPE_DEFAULT"))
#ifdef SQL_BIND_TYPE_DEFAULT
	    return SQL_BIND_TYPE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BIT"))
#ifdef SQL_BIT
	    return SQL_BIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BLOB"))
#ifdef SQL_BLOB
	    return SQL_BLOB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BLOB_LOCATOR"))
#ifdef SQL_BLOB_LOCATOR
	    return SQL_BLOB_LOCATOR;
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
	if (strEQ(name, "SQL_BRC_EXPLICIT"))
#ifdef SQL_BRC_EXPLICIT
	    return SQL_BRC_EXPLICIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BRC_PROCEDURES"))
#ifdef SQL_BRC_PROCEDURES
	    return SQL_BRC_PROCEDURES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BRC_ROLLED_UP"))
#ifdef SQL_BRC_ROLLED_UP
	    return SQL_BRC_ROLLED_UP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BS_ROW_COUNT_EXPLICIT"))
#ifdef SQL_BS_ROW_COUNT_EXPLICIT
	    return SQL_BS_ROW_COUNT_EXPLICIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BS_ROW_COUNT_PROC"))
#ifdef SQL_BS_ROW_COUNT_PROC
	    return SQL_BS_ROW_COUNT_PROC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BS_SELECT_EXPLICIT"))
#ifdef SQL_BS_SELECT_EXPLICIT
	    return SQL_BS_SELECT_EXPLICIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_BS_SELECT_PROC"))
#ifdef SQL_BS_SELECT_PROC
	    return SQL_BS_SELECT_PROC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_ABSOLUTE"))
#ifdef SQL_CA1_ABSOLUTE
	    return SQL_CA1_ABSOLUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_BOOKMARK"))
#ifdef SQL_CA1_BOOKMARK
	    return SQL_CA1_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_BULK_ADD"))
#ifdef SQL_CA1_BULK_ADD
	    return SQL_CA1_BULK_ADD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_BULK_DELETE_BY_BOOKMARK"))
#ifdef SQL_CA1_BULK_DELETE_BY_BOOKMARK
	    return SQL_CA1_BULK_DELETE_BY_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_BULK_FETCH_BY_BOOKMARK"))
#ifdef SQL_CA1_BULK_FETCH_BY_BOOKMARK
	    return SQL_CA1_BULK_FETCH_BY_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_BULK_UPDATE_BY_BOOKMARK"))
#ifdef SQL_CA1_BULK_UPDATE_BY_BOOKMARK
	    return SQL_CA1_BULK_UPDATE_BY_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_LOCK_EXCLUSIVE"))
#ifdef SQL_CA1_LOCK_EXCLUSIVE
	    return SQL_CA1_LOCK_EXCLUSIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_LOCK_NO_CHANGE"))
#ifdef SQL_CA1_LOCK_NO_CHANGE
	    return SQL_CA1_LOCK_NO_CHANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_LOCK_UNLOCK"))
#ifdef SQL_CA1_LOCK_UNLOCK
	    return SQL_CA1_LOCK_UNLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_NEXT"))
#ifdef SQL_CA1_NEXT
	    return SQL_CA1_NEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_POSITIONED_DELETE"))
#ifdef SQL_CA1_POSITIONED_DELETE
	    return SQL_CA1_POSITIONED_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_POSITIONED_UPDATE"))
#ifdef SQL_CA1_POSITIONED_UPDATE
	    return SQL_CA1_POSITIONED_UPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_POS_DELETE"))
#ifdef SQL_CA1_POS_DELETE
	    return SQL_CA1_POS_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_POS_POSITION"))
#ifdef SQL_CA1_POS_POSITION
	    return SQL_CA1_POS_POSITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_POS_REFRESH"))
#ifdef SQL_CA1_POS_REFRESH
	    return SQL_CA1_POS_REFRESH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_POS_UPDATE"))
#ifdef SQL_CA1_POS_UPDATE
	    return SQL_CA1_POS_UPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_RELATIVE"))
#ifdef SQL_CA1_RELATIVE
	    return SQL_CA1_RELATIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA1_SELECT_FOR_UPDATE"))
#ifdef SQL_CA1_SELECT_FOR_UPDATE
	    return SQL_CA1_SELECT_FOR_UPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_CRC_APPROXIMATE"))
#ifdef SQL_CA2_CRC_APPROXIMATE
	    return SQL_CA2_CRC_APPROXIMATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_CRC_EXACT"))
#ifdef SQL_CA2_CRC_EXACT
	    return SQL_CA2_CRC_EXACT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_LOCK_CONCURRENCY"))
#ifdef SQL_CA2_LOCK_CONCURRENCY
	    return SQL_CA2_LOCK_CONCURRENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_MAX_ROWS_AFFECTS_ALL"))
#ifdef SQL_CA2_MAX_ROWS_AFFECTS_ALL
	    return SQL_CA2_MAX_ROWS_AFFECTS_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_MAX_ROWS_CATALOG"))
#ifdef SQL_CA2_MAX_ROWS_CATALOG
	    return SQL_CA2_MAX_ROWS_CATALOG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_MAX_ROWS_DELETE"))
#ifdef SQL_CA2_MAX_ROWS_DELETE
	    return SQL_CA2_MAX_ROWS_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_MAX_ROWS_INSERT"))
#ifdef SQL_CA2_MAX_ROWS_INSERT
	    return SQL_CA2_MAX_ROWS_INSERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_MAX_ROWS_SELECT"))
#ifdef SQL_CA2_MAX_ROWS_SELECT
	    return SQL_CA2_MAX_ROWS_SELECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_MAX_ROWS_UPDATE"))
#ifdef SQL_CA2_MAX_ROWS_UPDATE
	    return SQL_CA2_MAX_ROWS_UPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_OPT_ROWVER_CONCURRENCY"))
#ifdef SQL_CA2_OPT_ROWVER_CONCURRENCY
	    return SQL_CA2_OPT_ROWVER_CONCURRENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_OPT_VALUES_CONCURRENCY"))
#ifdef SQL_CA2_OPT_VALUES_CONCURRENCY
	    return SQL_CA2_OPT_VALUES_CONCURRENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_READ_ONLY_CONCURRENCY"))
#ifdef SQL_CA2_READ_ONLY_CONCURRENCY
	    return SQL_CA2_READ_ONLY_CONCURRENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_SENSITIVITY_ADDITIONS"))
#ifdef SQL_CA2_SENSITIVITY_ADDITIONS
	    return SQL_CA2_SENSITIVITY_ADDITIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_SENSITIVITY_DELETIONS"))
#ifdef SQL_CA2_SENSITIVITY_DELETIONS
	    return SQL_CA2_SENSITIVITY_DELETIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_SENSITIVITY_UPDATES"))
#ifdef SQL_CA2_SENSITIVITY_UPDATES
	    return SQL_CA2_SENSITIVITY_UPDATES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_SIMULATE_NON_UNIQUE"))
#ifdef SQL_CA2_SIMULATE_NON_UNIQUE
	    return SQL_CA2_SIMULATE_NON_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_SIMULATE_TRY_UNIQUE"))
#ifdef SQL_CA2_SIMULATE_TRY_UNIQUE
	    return SQL_CA2_SIMULATE_TRY_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA2_SIMULATE_UNIQUE"))
#ifdef SQL_CA2_SIMULATE_UNIQUE
	    return SQL_CA2_SIMULATE_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CASCADE"))
#ifdef SQL_CASCADE
	    return SQL_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CATALOG_LOCATION"))
#ifdef SQL_CATALOG_LOCATION
	    return SQL_CATALOG_LOCATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CATALOG_NAME"))
#ifdef SQL_CATALOG_NAME
	    return SQL_CATALOG_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CATALOG_NAME_SEPARATOR"))
#ifdef SQL_CATALOG_NAME_SEPARATOR
	    return SQL_CATALOG_NAME_SEPARATOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CATALOG_TERM"))
#ifdef SQL_CATALOG_TERM
	    return SQL_CATALOG_TERM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CATALOG_USAGE"))
#ifdef SQL_CATALOG_USAGE
	    return SQL_CATALOG_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA_CONSTRAINT_DEFERRABLE"))
#ifdef SQL_CA_CONSTRAINT_DEFERRABLE
	    return SQL_CA_CONSTRAINT_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA_CONSTRAINT_INITIALLY_DEFERRED"))
#ifdef SQL_CA_CONSTRAINT_INITIALLY_DEFERRED
	    return SQL_CA_CONSTRAINT_INITIALLY_DEFERRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA_CONSTRAINT_INITIALLY_IMMEDIATE"))
#ifdef SQL_CA_CONSTRAINT_INITIALLY_IMMEDIATE
	    return SQL_CA_CONSTRAINT_INITIALLY_IMMEDIATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA_CONSTRAINT_NON_DEFERRABLE"))
#ifdef SQL_CA_CONSTRAINT_NON_DEFERRABLE
	    return SQL_CA_CONSTRAINT_NON_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CA_CREATE_ASSERTION"))
#ifdef SQL_CA_CREATE_ASSERTION
	    return SQL_CA_CREATE_ASSERTION;
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
	if (strEQ(name, "SQL_CCOL_CREATE_COLLATION"))
#ifdef SQL_CCOL_CREATE_COLLATION
	    return SQL_CCOL_CREATE_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CCS_COLLATE_CLAUSE"))
#ifdef SQL_CCS_COLLATE_CLAUSE
	    return SQL_CCS_COLLATE_CLAUSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CCS_CREATE_CHARACTER_SET"))
#ifdef SQL_CCS_CREATE_CHARACTER_SET
	    return SQL_CCS_CREATE_CHARACTER_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CCS_LIMITED_COLLATION"))
#ifdef SQL_CCS_LIMITED_COLLATION
	    return SQL_CCS_LIMITED_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CC_CLOSE"))
#ifdef SQL_CC_CLOSE
	    return SQL_CC_CLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CC_DEFAULT"))
#ifdef SQL_CC_DEFAULT
	    return SQL_CC_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CC_DELETE"))
#ifdef SQL_CC_DELETE
	    return SQL_CC_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CC_NO_RELEASE"))
#ifdef SQL_CC_NO_RELEASE
	    return SQL_CC_NO_RELEASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CC_PRESERVE"))
#ifdef SQL_CC_PRESERVE
	    return SQL_CC_PRESERVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CC_RELEASE"))
#ifdef SQL_CC_RELEASE
	    return SQL_CC_RELEASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CDO_COLLATION"))
#ifdef SQL_CDO_COLLATION
	    return SQL_CDO_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CDO_CONSTRAINT"))
#ifdef SQL_CDO_CONSTRAINT
	    return SQL_CDO_CONSTRAINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CDO_CONSTRAINT_DEFERRABLE"))
#ifdef SQL_CDO_CONSTRAINT_DEFERRABLE
	    return SQL_CDO_CONSTRAINT_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CDO_CONSTRAINT_INITIALLY_DEFERRED"))
#ifdef SQL_CDO_CONSTRAINT_INITIALLY_DEFERRED
	    return SQL_CDO_CONSTRAINT_INITIALLY_DEFERRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CDO_CONSTRAINT_INITIALLY_IMMEDIATE"))
#ifdef SQL_CDO_CONSTRAINT_INITIALLY_IMMEDIATE
	    return SQL_CDO_CONSTRAINT_INITIALLY_IMMEDIATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CDO_CONSTRAINT_NAME_DEFINITION"))
#ifdef SQL_CDO_CONSTRAINT_NAME_DEFINITION
	    return SQL_CDO_CONSTRAINT_NAME_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CDO_CONSTRAINT_NON_DEFERRABLE"))
#ifdef SQL_CDO_CONSTRAINT_NON_DEFERRABLE
	    return SQL_CDO_CONSTRAINT_NON_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CDO_CREATE_DOMAIN"))
#ifdef SQL_CDO_CREATE_DOMAIN
	    return SQL_CDO_CREATE_DOMAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CDO_DEFAULT"))
#ifdef SQL_CDO_DEFAULT
	    return SQL_CDO_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CD_FALSE"))
#ifdef SQL_CD_FALSE
	    return SQL_CD_FALSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CD_TRUE"))
#ifdef SQL_CD_TRUE
	    return SQL_CD_TRUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CHAR"))
#ifdef SQL_CHAR
	    return SQL_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CLOB"))
#ifdef SQL_CLOB
	    return SQL_CLOB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CLOB_LOCATOR"))
#ifdef SQL_CLOB_LOCATOR
	    return SQL_CLOB_LOCATOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CLOSE"))
#ifdef SQL_CLOSE
	    return SQL_CLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CLOSE_BEHAVIOR"))
#ifdef SQL_CLOSE_BEHAVIOR
	    return SQL_CLOSE_BEHAVIOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CL_END"))
#ifdef SQL_CL_END
	    return SQL_CL_END;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CL_START"))
#ifdef SQL_CL_START
	    return SQL_CL_START;
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
	if (strEQ(name, "SQL_CODE_DATE"))
#ifdef SQL_CODE_DATE
	    return SQL_CODE_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_DAY"))
#ifdef SQL_CODE_DAY
	    return SQL_CODE_DAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_DAY_TO_HOUR"))
#ifdef SQL_CODE_DAY_TO_HOUR
	    return SQL_CODE_DAY_TO_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_DAY_TO_MINUTE"))
#ifdef SQL_CODE_DAY_TO_MINUTE
	    return SQL_CODE_DAY_TO_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_DAY_TO_SECOND"))
#ifdef SQL_CODE_DAY_TO_SECOND
	    return SQL_CODE_DAY_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_HOUR"))
#ifdef SQL_CODE_HOUR
	    return SQL_CODE_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_HOUR_TO_MINUTE"))
#ifdef SQL_CODE_HOUR_TO_MINUTE
	    return SQL_CODE_HOUR_TO_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_HOUR_TO_SECOND"))
#ifdef SQL_CODE_HOUR_TO_SECOND
	    return SQL_CODE_HOUR_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_MINUTE"))
#ifdef SQL_CODE_MINUTE
	    return SQL_CODE_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_MINUTE_TO_SECOND"))
#ifdef SQL_CODE_MINUTE_TO_SECOND
	    return SQL_CODE_MINUTE_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_MONTH"))
#ifdef SQL_CODE_MONTH
	    return SQL_CODE_MONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_SECOND"))
#ifdef SQL_CODE_SECOND
	    return SQL_CODE_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_TIME"))
#ifdef SQL_CODE_TIME
	    return SQL_CODE_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_TIMESTAMP"))
#ifdef SQL_CODE_TIMESTAMP
	    return SQL_CODE_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_YEAR"))
#ifdef SQL_CODE_YEAR
	    return SQL_CODE_YEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CODE_YEAR_TO_MONTH"))
#ifdef SQL_CODE_YEAR_TO_MONTH
	    return SQL_CODE_YEAR_TO_MONTH;
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
	if (strEQ(name, "SQL_COLLATION_SEQ"))
#ifdef SQL_COLLATION_SEQ
	    return SQL_COLLATION_SEQ;
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
	if (strEQ(name, "SQL_COLUMN_CATALOG_NAME"))
#ifdef SQL_COLUMN_CATALOG_NAME
	    return SQL_COLUMN_CATALOG_NAME;
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
	if (strEQ(name, "SQL_COLUMN_DISTINCT_TYPE"))
#ifdef SQL_COLUMN_DISTINCT_TYPE
	    return SQL_COLUMN_DISTINCT_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_DRIVER_START"))
#ifdef SQL_COLUMN_DRIVER_START
	    return SQL_COLUMN_DRIVER_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_IGNORE"))
#ifdef SQL_COLUMN_IGNORE
	    return SQL_COLUMN_IGNORE;
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
	if (strEQ(name, "SQL_COLUMN_NO_COLUMN_NUMBER"))
#ifdef SQL_COLUMN_NO_COLUMN_NUMBER
	    return SQL_COLUMN_NO_COLUMN_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_NULLABLE"))
#ifdef SQL_COLUMN_NULLABLE
	    return SQL_COLUMN_NULLABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_NUMBER_UNKNOWN"))
#ifdef SQL_COLUMN_NUMBER_UNKNOWN
	    return SQL_COLUMN_NUMBER_UNKNOWN;
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
	if (strEQ(name, "SQL_COLUMN_REFERENCE_TYPE"))
#ifdef SQL_COLUMN_REFERENCE_TYPE
	    return SQL_COLUMN_REFERENCE_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_SCALE"))
#ifdef SQL_COLUMN_SCALE
	    return SQL_COLUMN_SCALE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_SCHEMA_NAME"))
#ifdef SQL_COLUMN_SCHEMA_NAME
	    return SQL_COLUMN_SCHEMA_NAME;
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
	if (strEQ(name, "SQL_COL_PRED_BASIC"))
#ifdef SQL_COL_PRED_BASIC
	    return SQL_COL_PRED_BASIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COL_PRED_CHAR"))
#ifdef SQL_COL_PRED_CHAR
	    return SQL_COL_PRED_CHAR;
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
	if (strEQ(name, "SQL_CONCURRENT_TRANS"))
#ifdef SQL_CONCURRENT_TRANS
	    return SQL_CONCURRENT_TRANS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONCUR_DEFAULT"))
#ifdef SQL_CONCUR_DEFAULT
	    return SQL_CONCUR_DEFAULT;
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
	if (strEQ(name, "SQL_CONNECTTYPE"))
#ifdef SQL_CONNECTTYPE
	    return SQL_CONNECTTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONNECTTYPE_DEFAULT"))
#ifdef SQL_CONNECTTYPE_DEFAULT
	    return SQL_CONNECTTYPE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONNECT_OPT_DRVR_START"))
#ifdef SQL_CONNECT_OPT_DRVR_START
	    return SQL_CONNECT_OPT_DRVR_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONN_CONTEXT"))
#ifdef SQL_CONN_CONTEXT
	    return SQL_CONN_CONTEXT;
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
	if (strEQ(name, "SQL_CONVERT_INTERVAL_DAY_TIME"))
#ifdef SQL_CONVERT_INTERVAL_DAY_TIME
	    return SQL_CONVERT_INTERVAL_DAY_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_INTERVAL_YEAR_MONTH"))
#ifdef SQL_CONVERT_INTERVAL_YEAR_MONTH
	    return SQL_CONVERT_INTERVAL_YEAR_MONTH;
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
	if (strEQ(name, "SQL_CONVERT_WCHAR"))
#ifdef SQL_CONVERT_WCHAR
	    return SQL_CONVERT_WCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_WLONGVARCHAR"))
#ifdef SQL_CONVERT_WLONGVARCHAR
	    return SQL_CONVERT_WLONGVARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONVERT_WVARCHAR"))
#ifdef SQL_CONVERT_WVARCHAR
	    return SQL_CONVERT_WVARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COORDINATED_TRANS"))
#ifdef SQL_COORDINATED_TRANS
	    return SQL_COORDINATED_TRANS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CORRELATION_NAME"))
#ifdef SQL_CORRELATION_NAME
	    return SQL_CORRELATION_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CP_DEFAULT"))
#ifdef SQL_CP_DEFAULT
	    return SQL_CP_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CP_MATCH_DEFAULT"))
#ifdef SQL_CP_MATCH_DEFAULT
	    return SQL_CP_MATCH_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CP_OFF"))
#ifdef SQL_CP_OFF
	    return SQL_CP_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CP_ONE_PER_DRIVER"))
#ifdef SQL_CP_ONE_PER_DRIVER
	    return SQL_CP_ONE_PER_DRIVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CP_ONE_PER_HENV"))
#ifdef SQL_CP_ONE_PER_HENV
	    return SQL_CP_ONE_PER_HENV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CP_RELAXED_MATCH"))
#ifdef SQL_CP_RELAXED_MATCH
	    return SQL_CP_RELAXED_MATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CP_STRICT_MATCH"))
#ifdef SQL_CP_STRICT_MATCH
	    return SQL_CP_STRICT_MATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CREATE_ASSERTION"))
#ifdef SQL_CREATE_ASSERTION
	    return SQL_CREATE_ASSERTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CREATE_CHARACTER_SET"))
#ifdef SQL_CREATE_CHARACTER_SET
	    return SQL_CREATE_CHARACTER_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CREATE_COLLATION"))
#ifdef SQL_CREATE_COLLATION
	    return SQL_CREATE_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CREATE_DOMAIN"))
#ifdef SQL_CREATE_DOMAIN
	    return SQL_CREATE_DOMAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CREATE_SCHEMA"))
#ifdef SQL_CREATE_SCHEMA
	    return SQL_CREATE_SCHEMA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CREATE_TABLE"))
#ifdef SQL_CREATE_TABLE
	    return SQL_CREATE_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CREATE_TRANSLATION"))
#ifdef SQL_CREATE_TRANSLATION
	    return SQL_CREATE_TRANSLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CREATE_VIEW"))
#ifdef SQL_CREATE_VIEW
	    return SQL_CREATE_VIEW;
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
	if (strEQ(name, "SQL_CS_AUTHORIZATION"))
#ifdef SQL_CS_AUTHORIZATION
	    return SQL_CS_AUTHORIZATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CS_CREATE_SCHEMA"))
#ifdef SQL_CS_CREATE_SCHEMA
	    return SQL_CS_CREATE_SCHEMA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CS_DEFAULT_CHARACTER_SET"))
#ifdef SQL_CS_DEFAULT_CHARACTER_SET
	    return SQL_CS_DEFAULT_CHARACTER_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CTR_CREATE_TRANSLATION"))
#ifdef SQL_CTR_CREATE_TRANSLATION
	    return SQL_CTR_CREATE_TRANSLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_COLUMN_COLLATION"))
#ifdef SQL_CT_COLUMN_COLLATION
	    return SQL_CT_COLUMN_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_COLUMN_CONSTRAINT"))
#ifdef SQL_CT_COLUMN_CONSTRAINT
	    return SQL_CT_COLUMN_CONSTRAINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_COLUMN_DEFAULT"))
#ifdef SQL_CT_COLUMN_DEFAULT
	    return SQL_CT_COLUMN_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_COMMIT_DELETE"))
#ifdef SQL_CT_COMMIT_DELETE
	    return SQL_CT_COMMIT_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_COMMIT_PRESERVE"))
#ifdef SQL_CT_COMMIT_PRESERVE
	    return SQL_CT_COMMIT_PRESERVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_CONSTRAINT_DEFERRABLE"))
#ifdef SQL_CT_CONSTRAINT_DEFERRABLE
	    return SQL_CT_CONSTRAINT_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_CONSTRAINT_INITIALLY_DEFERRED"))
#ifdef SQL_CT_CONSTRAINT_INITIALLY_DEFERRED
	    return SQL_CT_CONSTRAINT_INITIALLY_DEFERRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_CONSTRAINT_INITIALLY_IMMEDIATE"))
#ifdef SQL_CT_CONSTRAINT_INITIALLY_IMMEDIATE
	    return SQL_CT_CONSTRAINT_INITIALLY_IMMEDIATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_CONSTRAINT_NAME_DEFINITION"))
#ifdef SQL_CT_CONSTRAINT_NAME_DEFINITION
	    return SQL_CT_CONSTRAINT_NAME_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_CONSTRAINT_NON_DEFERRABLE"))
#ifdef SQL_CT_CONSTRAINT_NON_DEFERRABLE
	    return SQL_CT_CONSTRAINT_NON_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_CREATE_TABLE"))
#ifdef SQL_CT_CREATE_TABLE
	    return SQL_CT_CREATE_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_GLOBAL_TEMPORARY"))
#ifdef SQL_CT_GLOBAL_TEMPORARY
	    return SQL_CT_GLOBAL_TEMPORARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_LOCAL_TEMPORARY"))
#ifdef SQL_CT_LOCAL_TEMPORARY
	    return SQL_CT_LOCAL_TEMPORARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CT_TABLE_CONSTRAINT"))
#ifdef SQL_CT_TABLE_CONSTRAINT
	    return SQL_CT_TABLE_CONSTRAINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURRENT_QUALIFIER"))
#ifdef SQL_CURRENT_QUALIFIER
	    return SQL_CURRENT_QUALIFIER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURRENT_SCHEMA"))
#ifdef SQL_CURRENT_SCHEMA
	    return SQL_CURRENT_SCHEMA;
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
	if (strEQ(name, "SQL_CURSOR_HOLD"))
#ifdef SQL_CURSOR_HOLD
	    return SQL_CURSOR_HOLD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURSOR_HOLD_DEFAULT"))
#ifdef SQL_CURSOR_HOLD_DEFAULT
	    return SQL_CURSOR_HOLD_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURSOR_HOLD_OFF"))
#ifdef SQL_CURSOR_HOLD_OFF
	    return SQL_CURSOR_HOLD_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CURSOR_HOLD_ON"))
#ifdef SQL_CURSOR_HOLD_ON
	    return SQL_CURSOR_HOLD_ON;
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
	if (strEQ(name, "SQL_CURSOR_SENSITIVITY"))
#ifdef SQL_CURSOR_SENSITIVITY
	    return SQL_CURSOR_SENSITIVITY;
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
	if (strEQ(name, "SQL_CURSOR_TYPE_DEFAULT"))
#ifdef SQL_CURSOR_TYPE_DEFAULT
	    return SQL_CURSOR_TYPE_DEFAULT;
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
	if (strEQ(name, "SQL_CU_DML_STATEMENTS"))
#ifdef SQL_CU_DML_STATEMENTS
	    return SQL_CU_DML_STATEMENTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CU_INDEX_DEFINITION"))
#ifdef SQL_CU_INDEX_DEFINITION
	    return SQL_CU_INDEX_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CU_PRIVILEGE_DEFINITION"))
#ifdef SQL_CU_PRIVILEGE_DEFINITION
	    return SQL_CU_PRIVILEGE_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CU_PROCEDURE_INVOCATION"))
#ifdef SQL_CU_PROCEDURE_INVOCATION
	    return SQL_CU_PROCEDURE_INVOCATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CU_TABLE_DEFINITION"))
#ifdef SQL_CU_TABLE_DEFINITION
	    return SQL_CU_TABLE_DEFINITION;
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
	if (strEQ(name, "SQL_CVT_INTERVAL_DAY_TIME"))
#ifdef SQL_CVT_INTERVAL_DAY_TIME
	    return SQL_CVT_INTERVAL_DAY_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_INTERVAL_YEAR_MONTH"))
#ifdef SQL_CVT_INTERVAL_YEAR_MONTH
	    return SQL_CVT_INTERVAL_YEAR_MONTH;
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
	if (strEQ(name, "SQL_CVT_WCHAR"))
#ifdef SQL_CVT_WCHAR
	    return SQL_CVT_WCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_WLONGVARCHAR"))
#ifdef SQL_CVT_WLONGVARCHAR
	    return SQL_CVT_WLONGVARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CVT_WVARCHAR"))
#ifdef SQL_CVT_WVARCHAR
	    return SQL_CVT_WVARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CV_CASCADED"))
#ifdef SQL_CV_CASCADED
	    return SQL_CV_CASCADED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CV_CHECK_OPTION"))
#ifdef SQL_CV_CHECK_OPTION
	    return SQL_CV_CHECK_OPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CV_CREATE_VIEW"))
#ifdef SQL_CV_CREATE_VIEW
	    return SQL_CV_CREATE_VIEW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CV_LOCAL"))
#ifdef SQL_CV_LOCAL
	    return SQL_CV_LOCAL;
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
	if (strEQ(name, "SQL_C_BLOB_LOCATOR"))
#ifdef SQL_C_BLOB_LOCATOR
	    return SQL_C_BLOB_LOCATOR;
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
	if (strEQ(name, "SQL_C_CLOB_LOCATOR"))
#ifdef SQL_C_CLOB_LOCATOR
	    return SQL_C_CLOB_LOCATOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DATALINK"))
#ifdef SQL_C_DATALINK
	    return SQL_C_DATALINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DATE"))
#ifdef SQL_C_DATE
	    return SQL_C_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DBCHAR"))
#ifdef SQL_C_DBCHAR
	    return SQL_C_DBCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DBCLOB_LOCATOR"))
#ifdef SQL_C_DBCLOB_LOCATOR
	    return SQL_C_DBCLOB_LOCATOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DECIMAL_IBM"))
#ifdef SQL_C_DECIMAL_IBM
	    return SQL_C_DECIMAL_IBM;
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
	if (strEQ(name, "SQL_C_GUID"))
#ifdef SQL_C_GUID
	    return SQL_C_GUID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_DAY"))
#ifdef SQL_C_INTERVAL_DAY
	    return SQL_C_INTERVAL_DAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_DAY_TO_HOUR"))
#ifdef SQL_C_INTERVAL_DAY_TO_HOUR
	    return SQL_C_INTERVAL_DAY_TO_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_DAY_TO_MINUTE"))
#ifdef SQL_C_INTERVAL_DAY_TO_MINUTE
	    return SQL_C_INTERVAL_DAY_TO_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_DAY_TO_SECOND"))
#ifdef SQL_C_INTERVAL_DAY_TO_SECOND
	    return SQL_C_INTERVAL_DAY_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_HOUR"))
#ifdef SQL_C_INTERVAL_HOUR
	    return SQL_C_INTERVAL_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_HOUR_TO_MINUTE"))
#ifdef SQL_C_INTERVAL_HOUR_TO_MINUTE
	    return SQL_C_INTERVAL_HOUR_TO_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_HOUR_TO_SECOND"))
#ifdef SQL_C_INTERVAL_HOUR_TO_SECOND
	    return SQL_C_INTERVAL_HOUR_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_MINUTE"))
#ifdef SQL_C_INTERVAL_MINUTE
	    return SQL_C_INTERVAL_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_MINUTE_TO_SECOND"))
#ifdef SQL_C_INTERVAL_MINUTE_TO_SECOND
	    return SQL_C_INTERVAL_MINUTE_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_MONTH"))
#ifdef SQL_C_INTERVAL_MONTH
	    return SQL_C_INTERVAL_MONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_SECOND"))
#ifdef SQL_C_INTERVAL_SECOND
	    return SQL_C_INTERVAL_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_YEAR"))
#ifdef SQL_C_INTERVAL_YEAR
	    return SQL_C_INTERVAL_YEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_INTERVAL_YEAR_TO_MONTH"))
#ifdef SQL_C_INTERVAL_YEAR_TO_MONTH
	    return SQL_C_INTERVAL_YEAR_TO_MONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_LONG"))
#ifdef SQL_C_LONG
	    return SQL_C_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_NUMERIC"))
#ifdef SQL_C_NUMERIC
	    return SQL_C_NUMERIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_SBIGINT"))
#ifdef SQL_C_SBIGINT
	    return SQL_C_SBIGINT;
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
	if (strEQ(name, "SQL_C_TYPE_DATE"))
#ifdef SQL_C_TYPE_DATE
	    return SQL_C_TYPE_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_TYPE_TIME"))
#ifdef SQL_C_TYPE_TIME
	    return SQL_C_TYPE_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_TYPE_TIMESTAMP"))
#ifdef SQL_C_TYPE_TIMESTAMP
	    return SQL_C_TYPE_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_UBIGINT"))
#ifdef SQL_C_UBIGINT
	    return SQL_C_UBIGINT;
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
	if (strEQ(name, "SQL_C_VARBOOKMARK"))
#ifdef SQL_C_VARBOOKMARK
	    return SQL_C_VARBOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATABASE_NAME"))
#ifdef SQL_DATABASE_NAME
	    return SQL_DATABASE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATALINK"))
#ifdef SQL_DATALINK
	    return SQL_DATALINK;
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
	if (strEQ(name, "SQL_DATETIME"))
#ifdef SQL_DATETIME
	    return SQL_DATETIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATETIME_LITERALS"))
#ifdef SQL_DATETIME_LITERALS
	    return SQL_DATETIME_LITERALS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATE_LEN"))
#ifdef SQL_DATE_LEN
	    return SQL_DATE_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DAY"))
#ifdef SQL_DAY
	    return SQL_DAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DAY_TO_HOUR"))
#ifdef SQL_DAY_TO_HOUR
	    return SQL_DAY_TO_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DAY_TO_MINUTE"))
#ifdef SQL_DAY_TO_MINUTE
	    return SQL_DAY_TO_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DAY_TO_SECOND"))
#ifdef SQL_DAY_TO_SECOND
	    return SQL_DAY_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DA_DROP_ASSERTION"))
#ifdef SQL_DA_DROP_ASSERTION
	    return SQL_DA_DROP_ASSERTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2ESTIMATE"))
#ifdef SQL_DB2ESTIMATE
	    return SQL_DB2ESTIMATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2ESTIMATE_DEFAULT"))
#ifdef SQL_DB2ESTIMATE_DEFAULT
	    return SQL_DB2ESTIMATE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2ESTIMATE_OFF"))
#ifdef SQL_DB2ESTIMATE_OFF
	    return SQL_DB2ESTIMATE_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2ESTIMATE_ON"))
#ifdef SQL_DB2ESTIMATE_ON
	    return SQL_DB2ESTIMATE_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2EXPLAIN"))
#ifdef SQL_DB2EXPLAIN
	    return SQL_DB2EXPLAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2EXPLAIN_DEFAULT"))
#ifdef SQL_DB2EXPLAIN_DEFAULT
	    return SQL_DB2EXPLAIN_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2EXPLAIN_MODE_ON"))
#ifdef SQL_DB2EXPLAIN_MODE_ON
	    return SQL_DB2EXPLAIN_MODE_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2EXPLAIN_OFF"))
#ifdef SQL_DB2EXPLAIN_OFF
	    return SQL_DB2EXPLAIN_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2EXPLAIN_ON"))
#ifdef SQL_DB2EXPLAIN_ON
	    return SQL_DB2EXPLAIN_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2EXPLAIN_SNAPSHOT_MODE_ON"))
#ifdef SQL_DB2EXPLAIN_SNAPSHOT_MODE_ON
	    return SQL_DB2EXPLAIN_SNAPSHOT_MODE_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB2EXPLAIN_SNAPSHOT_ON"))
#ifdef SQL_DB2EXPLAIN_SNAPSHOT_ON
	    return SQL_DB2EXPLAIN_SNAPSHOT_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DBCLOB"))
#ifdef SQL_DBCLOB
	    return SQL_DBCLOB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DBCLOB_LOCATOR"))
#ifdef SQL_DBCLOB_LOCATOR
	    return SQL_DBCLOB_LOCATOR;
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
	if (strEQ(name, "SQL_DB_DEFAULT"))
#ifdef SQL_DB_DEFAULT
	    return SQL_DB_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB_DISCONNECT"))
#ifdef SQL_DB_DISCONNECT
	    return SQL_DB_DISCONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DB_RETURN_TO_POOL"))
#ifdef SQL_DB_RETURN_TO_POOL
	    return SQL_DB_RETURN_TO_POOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DCS_DROP_CHARACTER_SET"))
#ifdef SQL_DCS_DROP_CHARACTER_SET
	    return SQL_DCS_DROP_CHARACTER_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DC_DROP_COLLATION"))
#ifdef SQL_DC_DROP_COLLATION
	    return SQL_DC_DROP_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DDL_INDEX"))
#ifdef SQL_DDL_INDEX
	    return SQL_DDL_INDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DD_CASCADE"))
#ifdef SQL_DD_CASCADE
	    return SQL_DD_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DD_DROP_DOMAIN"))
#ifdef SQL_DD_DROP_DOMAIN
	    return SQL_DD_DROP_DOMAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DD_RESTRICT"))
#ifdef SQL_DD_RESTRICT
	    return SQL_DD_RESTRICT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DECIMAL"))
#ifdef SQL_DECIMAL
	    return SQL_DECIMAL;
#else
	    goto not_there;
#endif
        if (strEQ(name, "SQL_DECFLOAT"))
#ifdef SQL_DECFLOAT
            return SQL_DECFLOAT;
#else
            goto not_there;
#endif
	if (strEQ(name, "SQL_DEFAULT"))
#ifdef SQL_DEFAULT
	    return SQL_DEFAULT;
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
	if (strEQ(name, "SQL_DEFERRED_PREPARE_DEFAULT"))
#ifdef SQL_DEFERRED_PREPARE_DEFAULT
	    return SQL_DEFERRED_PREPARE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DEFERRED_PREPARE_OFF"))
#ifdef SQL_DEFERRED_PREPARE_OFF
	    return SQL_DEFERRED_PREPARE_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DEFERRED_PREPARE_ON"))
#ifdef SQL_DEFERRED_PREPARE_ON
	    return SQL_DEFERRED_PREPARE_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DELETE"))
#ifdef SQL_DELETE
	    return SQL_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DELETE_BY_BOOKMARK"))
#ifdef SQL_DELETE_BY_BOOKMARK
	    return SQL_DELETE_BY_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESCRIBE_PARAMETER"))
#ifdef SQL_DESCRIBE_PARAMETER
	    return SQL_DESCRIBE_PARAMETER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_ALLOC_AUTO"))
#ifdef SQL_DESC_ALLOC_AUTO
	    return SQL_DESC_ALLOC_AUTO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_ALLOC_TYPE"))
#ifdef SQL_DESC_ALLOC_TYPE
	    return SQL_DESC_ALLOC_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_ALLOC_USER"))
#ifdef SQL_DESC_ALLOC_USER
	    return SQL_DESC_ALLOC_USER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_ARRAY_SIZE"))
#ifdef SQL_DESC_ARRAY_SIZE
	    return SQL_DESC_ARRAY_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_ARRAY_STATUS_PTR"))
#ifdef SQL_DESC_ARRAY_STATUS_PTR
	    return SQL_DESC_ARRAY_STATUS_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_AUTO_UNIQUE_VALUE"))
#ifdef SQL_DESC_AUTO_UNIQUE_VALUE
	    return SQL_DESC_AUTO_UNIQUE_VALUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_BASE_COLUMN_NAME"))
#ifdef SQL_DESC_BASE_COLUMN_NAME
	    return SQL_DESC_BASE_COLUMN_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_BASE_TABLE_NAME"))
#ifdef SQL_DESC_BASE_TABLE_NAME
	    return SQL_DESC_BASE_TABLE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_BIND_OFFSET_PTR"))
#ifdef SQL_DESC_BIND_OFFSET_PTR
	    return SQL_DESC_BIND_OFFSET_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_BIND_TYPE"))
#ifdef SQL_DESC_BIND_TYPE
	    return SQL_DESC_BIND_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_CASE_SENSITIVE"))
#ifdef SQL_DESC_CASE_SENSITIVE
	    return SQL_DESC_CASE_SENSITIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_CATALOG_NAME"))
#ifdef SQL_DESC_CATALOG_NAME
	    return SQL_DESC_CATALOG_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_CONCISE_TYPE"))
#ifdef SQL_DESC_CONCISE_TYPE
	    return SQL_DESC_CONCISE_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_COUNT"))
#ifdef SQL_DESC_COUNT
	    return SQL_DESC_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_DATA_PTR"))
#ifdef SQL_DESC_DATA_PTR
	    return SQL_DESC_DATA_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_DATETIME_INTERVAL_CODE"))
#ifdef SQL_DESC_DATETIME_INTERVAL_CODE
	    return SQL_DESC_DATETIME_INTERVAL_CODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_DATETIME_INTERVAL_PRECISION"))
#ifdef SQL_DESC_DATETIME_INTERVAL_PRECISION
	    return SQL_DESC_DATETIME_INTERVAL_PRECISION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_DESCRIPTOR_TYPE"))
#ifdef SQL_DESC_DESCRIPTOR_TYPE
	    return SQL_DESC_DESCRIPTOR_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_DISPLAY_SIZE"))
#ifdef SQL_DESC_DISPLAY_SIZE
	    return SQL_DESC_DISPLAY_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_DISTINCT_TYPE"))
#ifdef SQL_DESC_DISTINCT_TYPE
	    return SQL_DESC_DISTINCT_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_FIXED_PREC_SCALE"))
#ifdef SQL_DESC_FIXED_PREC_SCALE
	    return SQL_DESC_FIXED_PREC_SCALE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_INDICATOR_PTR"))
#ifdef SQL_DESC_INDICATOR_PTR
	    return SQL_DESC_INDICATOR_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_LABEL"))
#ifdef SQL_DESC_LABEL
	    return SQL_DESC_LABEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_LENGTH"))
#ifdef SQL_DESC_LENGTH
	    return SQL_DESC_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_LITERAL_PREFIX"))
#ifdef SQL_DESC_LITERAL_PREFIX
	    return SQL_DESC_LITERAL_PREFIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_LITERAL_SUFFIX"))
#ifdef SQL_DESC_LITERAL_SUFFIX
	    return SQL_DESC_LITERAL_SUFFIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_LOCAL_TYPE_NAME"))
#ifdef SQL_DESC_LOCAL_TYPE_NAME
	    return SQL_DESC_LOCAL_TYPE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_MAXIMUM_SCALE"))
#ifdef SQL_DESC_MAXIMUM_SCALE
	    return SQL_DESC_MAXIMUM_SCALE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_MINIMUM_SCALE"))
#ifdef SQL_DESC_MINIMUM_SCALE
	    return SQL_DESC_MINIMUM_SCALE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_NAME"))
#ifdef SQL_DESC_NAME
	    return SQL_DESC_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_NULLABLE"))
#ifdef SQL_DESC_NULLABLE
	    return SQL_DESC_NULLABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_NUM_PREC_RADIX"))
#ifdef SQL_DESC_NUM_PREC_RADIX
	    return SQL_DESC_NUM_PREC_RADIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_OCTET_LENGTH"))
#ifdef SQL_DESC_OCTET_LENGTH
	    return SQL_DESC_OCTET_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_OCTET_LENGTH_PTR"))
#ifdef SQL_DESC_OCTET_LENGTH_PTR
	    return SQL_DESC_OCTET_LENGTH_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_PARAMETER_TYPE"))
#ifdef SQL_DESC_PARAMETER_TYPE
	    return SQL_DESC_PARAMETER_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_PRECISION"))
#ifdef SQL_DESC_PRECISION
	    return SQL_DESC_PRECISION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_REFERENCE_TYPE"))
#ifdef SQL_DESC_REFERENCE_TYPE
	    return SQL_DESC_REFERENCE_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_ROWS_PROCESSED_PTR"))
#ifdef SQL_DESC_ROWS_PROCESSED_PTR
	    return SQL_DESC_ROWS_PROCESSED_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_ROWVER"))
#ifdef SQL_DESC_ROWVER
	    return SQL_DESC_ROWVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_SCALE"))
#ifdef SQL_DESC_SCALE
	    return SQL_DESC_SCALE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_SCHEMA_NAME"))
#ifdef SQL_DESC_SCHEMA_NAME
	    return SQL_DESC_SCHEMA_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_SEARCHABLE"))
#ifdef SQL_DESC_SEARCHABLE
	    return SQL_DESC_SEARCHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_TABLE_NAME"))
#ifdef SQL_DESC_TABLE_NAME
	    return SQL_DESC_TABLE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_TYPE"))
#ifdef SQL_DESC_TYPE
	    return SQL_DESC_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_TYPE_NAME"))
#ifdef SQL_DESC_TYPE_NAME
	    return SQL_DESC_TYPE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_UNNAMED"))
#ifdef SQL_DESC_UNNAMED
	    return SQL_DESC_UNNAMED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_UNSIGNED"))
#ifdef SQL_DESC_UNSIGNED
	    return SQL_DESC_UNSIGNED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DESC_UPDATABLE"))
#ifdef SQL_DESC_UPDATABLE
	    return SQL_DESC_UPDATABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_ALTER_TABLE"))
#ifdef SQL_DIAG_ALTER_TABLE
	    return SQL_DIAG_ALTER_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_CALL"))
#ifdef SQL_DIAG_CALL
	    return SQL_DIAG_CALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_CLASS_ORIGIN"))
#ifdef SQL_DIAG_CLASS_ORIGIN
	    return SQL_DIAG_CLASS_ORIGIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_COLUMN_NUMBER"))
#ifdef SQL_DIAG_COLUMN_NUMBER
	    return SQL_DIAG_COLUMN_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_CONNECTION_NAME"))
#ifdef SQL_DIAG_CONNECTION_NAME
	    return SQL_DIAG_CONNECTION_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_CREATE_INDEX"))
#ifdef SQL_DIAG_CREATE_INDEX
	    return SQL_DIAG_CREATE_INDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_CREATE_TABLE"))
#ifdef SQL_DIAG_CREATE_TABLE
	    return SQL_DIAG_CREATE_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_CREATE_VIEW"))
#ifdef SQL_DIAG_CREATE_VIEW
	    return SQL_DIAG_CREATE_VIEW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_CURSOR_ROW_COUNT"))
#ifdef SQL_DIAG_CURSOR_ROW_COUNT
	    return SQL_DIAG_CURSOR_ROW_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_DEFERRED_PREPARE_ERROR"))
#ifdef SQL_DIAG_DEFERRED_PREPARE_ERROR
	    return SQL_DIAG_DEFERRED_PREPARE_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_DELETE_WHERE"))
#ifdef SQL_DIAG_DELETE_WHERE
	    return SQL_DIAG_DELETE_WHERE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_DROP_INDEX"))
#ifdef SQL_DIAG_DROP_INDEX
	    return SQL_DIAG_DROP_INDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_DROP_TABLE"))
#ifdef SQL_DIAG_DROP_TABLE
	    return SQL_DIAG_DROP_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_DROP_VIEW"))
#ifdef SQL_DIAG_DROP_VIEW
	    return SQL_DIAG_DROP_VIEW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_DYNAMIC_DELETE_CURSOR"))
#ifdef SQL_DIAG_DYNAMIC_DELETE_CURSOR
	    return SQL_DIAG_DYNAMIC_DELETE_CURSOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_DYNAMIC_FUNCTION"))
#ifdef SQL_DIAG_DYNAMIC_FUNCTION
	    return SQL_DIAG_DYNAMIC_FUNCTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_DYNAMIC_FUNCTION_CODE"))
#ifdef SQL_DIAG_DYNAMIC_FUNCTION_CODE
	    return SQL_DIAG_DYNAMIC_FUNCTION_CODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_DYNAMIC_UPDATE_CURSOR"))
#ifdef SQL_DIAG_DYNAMIC_UPDATE_CURSOR
	    return SQL_DIAG_DYNAMIC_UPDATE_CURSOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_GRANT"))
#ifdef SQL_DIAG_GRANT
	    return SQL_DIAG_GRANT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_INSERT"))
#ifdef SQL_DIAG_INSERT
	    return SQL_DIAG_INSERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_MESSAGE_TEXT"))
#ifdef SQL_DIAG_MESSAGE_TEXT
	    return SQL_DIAG_MESSAGE_TEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_NATIVE"))
#ifdef SQL_DIAG_NATIVE
	    return SQL_DIAG_NATIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_NUMBER"))
#ifdef SQL_DIAG_NUMBER
	    return SQL_DIAG_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_RETURNCODE"))
#ifdef SQL_DIAG_RETURNCODE
	    return SQL_DIAG_RETURNCODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_REVOKE"))
#ifdef SQL_DIAG_REVOKE
	    return SQL_DIAG_REVOKE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_ROW_COUNT"))
#ifdef SQL_DIAG_ROW_COUNT
	    return SQL_DIAG_ROW_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_ROW_NUMBER"))
#ifdef SQL_DIAG_ROW_NUMBER
	    return SQL_DIAG_ROW_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_SELECT_CURSOR"))
#ifdef SQL_DIAG_SELECT_CURSOR
	    return SQL_DIAG_SELECT_CURSOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_SERVER_NAME"))
#ifdef SQL_DIAG_SERVER_NAME
	    return SQL_DIAG_SERVER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_SQLSTATE"))
#ifdef SQL_DIAG_SQLSTATE
	    return SQL_DIAG_SQLSTATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_SUBCLASS_ORIGIN"))
#ifdef SQL_DIAG_SUBCLASS_ORIGIN
	    return SQL_DIAG_SUBCLASS_ORIGIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_UNKNOWN_STATEMENT"))
#ifdef SQL_DIAG_UNKNOWN_STATEMENT
	    return SQL_DIAG_UNKNOWN_STATEMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DIAG_UPDATE_WHERE"))
#ifdef SQL_DIAG_UPDATE_WHERE
	    return SQL_DIAG_UPDATE_WHERE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DI_CREATE_INDEX"))
#ifdef SQL_DI_CREATE_INDEX
	    return SQL_DI_CREATE_INDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DI_DROP_INDEX"))
#ifdef SQL_DI_DROP_INDEX
	    return SQL_DI_DROP_INDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_DATE"))
#ifdef SQL_DL_SQL92_DATE
	    return SQL_DL_SQL92_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_DAY"))
#ifdef SQL_DL_SQL92_INTERVAL_DAY
	    return SQL_DL_SQL92_INTERVAL_DAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_DAY_TO_HOUR"))
#ifdef SQL_DL_SQL92_INTERVAL_DAY_TO_HOUR
	    return SQL_DL_SQL92_INTERVAL_DAY_TO_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_DAY_TO_MINUTE"))
#ifdef SQL_DL_SQL92_INTERVAL_DAY_TO_MINUTE
	    return SQL_DL_SQL92_INTERVAL_DAY_TO_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_DAY_TO_SECOND"))
#ifdef SQL_DL_SQL92_INTERVAL_DAY_TO_SECOND
	    return SQL_DL_SQL92_INTERVAL_DAY_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_HOUR"))
#ifdef SQL_DL_SQL92_INTERVAL_HOUR
	    return SQL_DL_SQL92_INTERVAL_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_HOUR_TO_MINUTE"))
#ifdef SQL_DL_SQL92_INTERVAL_HOUR_TO_MINUTE
	    return SQL_DL_SQL92_INTERVAL_HOUR_TO_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_HOUR_TO_SECOND"))
#ifdef SQL_DL_SQL92_INTERVAL_HOUR_TO_SECOND
	    return SQL_DL_SQL92_INTERVAL_HOUR_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_MINUTE"))
#ifdef SQL_DL_SQL92_INTERVAL_MINUTE
	    return SQL_DL_SQL92_INTERVAL_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_MINUTE_TO_SECOND"))
#ifdef SQL_DL_SQL92_INTERVAL_MINUTE_TO_SECOND
	    return SQL_DL_SQL92_INTERVAL_MINUTE_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_MONTH"))
#ifdef SQL_DL_SQL92_INTERVAL_MONTH
	    return SQL_DL_SQL92_INTERVAL_MONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_SECOND"))
#ifdef SQL_DL_SQL92_INTERVAL_SECOND
	    return SQL_DL_SQL92_INTERVAL_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_YEAR"))
#ifdef SQL_DL_SQL92_INTERVAL_YEAR
	    return SQL_DL_SQL92_INTERVAL_YEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_INTERVAL_YEAR_TO_MONTH"))
#ifdef SQL_DL_SQL92_INTERVAL_YEAR_TO_MONTH
	    return SQL_DL_SQL92_INTERVAL_YEAR_TO_MONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_TIME"))
#ifdef SQL_DL_SQL92_TIME
	    return SQL_DL_SQL92_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DL_SQL92_TIMESTAMP"))
#ifdef SQL_DL_SQL92_TIMESTAMP
	    return SQL_DL_SQL92_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DM_VER"))
#ifdef SQL_DM_VER
	    return SQL_DM_VER;
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
	if (strEQ(name, "SQL_DRIVER_HDESC"))
#ifdef SQL_DRIVER_HDESC
	    return SQL_DRIVER_HDESC;
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
	if (strEQ(name, "SQL_DROP_ASSERTION"))
#ifdef SQL_DROP_ASSERTION
	    return SQL_DROP_ASSERTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DROP_CHARACTER_SET"))
#ifdef SQL_DROP_CHARACTER_SET
	    return SQL_DROP_CHARACTER_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DROP_COLLATION"))
#ifdef SQL_DROP_COLLATION
	    return SQL_DROP_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DROP_DOMAIN"))
#ifdef SQL_DROP_DOMAIN
	    return SQL_DROP_DOMAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DROP_SCHEMA"))
#ifdef SQL_DROP_SCHEMA
	    return SQL_DROP_SCHEMA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DROP_TABLE"))
#ifdef SQL_DROP_TABLE
	    return SQL_DROP_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DROP_TRANSLATION"))
#ifdef SQL_DROP_TRANSLATION
	    return SQL_DROP_TRANSLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DROP_VIEW"))
#ifdef SQL_DROP_VIEW
	    return SQL_DROP_VIEW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DS_CASCADE"))
#ifdef SQL_DS_CASCADE
	    return SQL_DS_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DS_DROP_SCHEMA"))
#ifdef SQL_DS_DROP_SCHEMA
	    return SQL_DS_DROP_SCHEMA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DS_RESTRICT"))
#ifdef SQL_DS_RESTRICT
	    return SQL_DS_RESTRICT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DTC_DONE"))
#ifdef SQL_DTC_DONE
	    return SQL_DTC_DONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DTC_ENLIST_EXPENSIVE"))
#ifdef SQL_DTC_ENLIST_EXPENSIVE
	    return SQL_DTC_ENLIST_EXPENSIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DTC_TRANSITION_COST"))
#ifdef SQL_DTC_TRANSITION_COST
	    return SQL_DTC_TRANSITION_COST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DTC_UNENLIST_EXPENSIVE"))
#ifdef SQL_DTC_UNENLIST_EXPENSIVE
	    return SQL_DTC_UNENLIST_EXPENSIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DTR_DROP_TRANSLATION"))
#ifdef SQL_DTR_DROP_TRANSLATION
	    return SQL_DTR_DROP_TRANSLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DT_CASCADE"))
#ifdef SQL_DT_CASCADE
	    return SQL_DT_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DT_DROP_TABLE"))
#ifdef SQL_DT_DROP_TABLE
	    return SQL_DT_DROP_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DT_RESTRICT"))
#ifdef SQL_DT_RESTRICT
	    return SQL_DT_RESTRICT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DV_CASCADE"))
#ifdef SQL_DV_CASCADE
	    return SQL_DV_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DV_DROP_VIEW"))
#ifdef SQL_DV_DROP_VIEW
	    return SQL_DV_DROP_VIEW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DV_RESTRICT"))
#ifdef SQL_DV_RESTRICT
	    return SQL_DV_RESTRICT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DYNAMIC_CURSOR_ATTRIBUTES1"))
#ifdef SQL_DYNAMIC_CURSOR_ATTRIBUTES1
	    return SQL_DYNAMIC_CURSOR_ATTRIBUTES1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DYNAMIC_CURSOR_ATTRIBUTES2"))
#ifdef SQL_DYNAMIC_CURSOR_ATTRIBUTES2
	    return SQL_DYNAMIC_CURSOR_ATTRIBUTES2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_EARLYCLOSE_DEFAULT"))
#ifdef SQL_EARLYCLOSE_DEFAULT
	    return SQL_EARLYCLOSE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_EARLYCLOSE_OFF"))
#ifdef SQL_EARLYCLOSE_OFF
	    return SQL_EARLYCLOSE_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_EARLYCLOSE_ON"))
#ifdef SQL_EARLYCLOSE_ON
	    return SQL_EARLYCLOSE_ON;
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
	if (strEQ(name, "SQL_FALSE"))
#ifdef SQL_FALSE
	    return SQL_FALSE;
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
	if (strEQ(name, "SQL_FETCH_BY_BOOKMARK"))
#ifdef SQL_FETCH_BY_BOOKMARK
	    return SQL_FETCH_BY_BOOKMARK;
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
	if (strEQ(name, "SQL_FETCH_FIRST_SYSTEM"))
#ifdef SQL_FETCH_FIRST_SYSTEM
	    return SQL_FETCH_FIRST_SYSTEM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FETCH_FIRST_USER"))
#ifdef SQL_FETCH_FIRST_USER
	    return SQL_FETCH_FIRST_USER;
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
	if (strEQ(name, "SQL_FILE_APPEND"))
#ifdef SQL_FILE_APPEND
	    return SQL_FILE_APPEND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FILE_CATALOG"))
#ifdef SQL_FILE_CATALOG
	    return SQL_FILE_CATALOG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FILE_CREATE"))
#ifdef SQL_FILE_CREATE
	    return SQL_FILE_CREATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FILE_NOT_SUPPORTED"))
#ifdef SQL_FILE_NOT_SUPPORTED
	    return SQL_FILE_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FILE_OVERWRITE"))
#ifdef SQL_FILE_OVERWRITE
	    return SQL_FILE_OVERWRITE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FILE_QUALIFIER"))
#ifdef SQL_FILE_QUALIFIER
	    return SQL_FILE_QUALIFIER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FILE_READ"))
#ifdef SQL_FILE_READ
	    return SQL_FILE_READ;
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
	if (strEQ(name, "SQL_FN_CVT_CAST"))
#ifdef SQL_FN_CVT_CAST
	    return SQL_FN_CVT_CAST;
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
	if (strEQ(name, "SQL_FN_STR_BIT_LENGTH"))
#ifdef SQL_FN_STR_BIT_LENGTH
	    return SQL_FN_STR_BIT_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_CHAR"))
#ifdef SQL_FN_STR_CHAR
	    return SQL_FN_STR_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_CHARACTER_LENGTH"))
#ifdef SQL_FN_STR_CHARACTER_LENGTH
	    return SQL_FN_STR_CHARACTER_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_CHAR_LENGTH"))
#ifdef SQL_FN_STR_CHAR_LENGTH
	    return SQL_FN_STR_CHAR_LENGTH;
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
	if (strEQ(name, "SQL_FN_STR_OCTET_LENGTH"))
#ifdef SQL_FN_STR_OCTET_LENGTH
	    return SQL_FN_STR_OCTET_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_STR_POSITION"))
#ifdef SQL_FN_STR_POSITION
	    return SQL_FN_STR_POSITION;
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
	if (strEQ(name, "SQL_FN_TD_CURRENT_DATE"))
#ifdef SQL_FN_TD_CURRENT_DATE
	    return SQL_FN_TD_CURRENT_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_CURRENT_TIME"))
#ifdef SQL_FN_TD_CURRENT_TIME
	    return SQL_FN_TD_CURRENT_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FN_TD_CURRENT_TIMESTAMP"))
#ifdef SQL_FN_TD_CURRENT_TIMESTAMP
	    return SQL_FN_TD_CURRENT_TIMESTAMP;
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
	if (strEQ(name, "SQL_FN_TD_EXTRACT"))
#ifdef SQL_FN_TD_EXTRACT
	    return SQL_FN_TD_EXTRACT;
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
	if (strEQ(name, "SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1"))
#ifdef SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1
	    return SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2"))
#ifdef SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2
	    return SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FROM_LITERAL"))
#ifdef SQL_FROM_LITERAL
	    return SQL_FROM_LITERAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FROM_LOCATOR"))
#ifdef SQL_FROM_LOCATOR
	    return SQL_FROM_LOCATOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GB_COLLATE"))
#ifdef SQL_GB_COLLATE
	    return SQL_GB_COLLATE;
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
	if (strEQ(name, "SQL_GRAPHIC"))
#ifdef SQL_GRAPHIC
	    return SQL_GRAPHIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GROUP_BY"))
#ifdef SQL_GROUP_BY
	    return SQL_GROUP_BY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_GUID"))
#ifdef SQL_GUID
	    return SQL_GUID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_HANDLE_DBC"))
#ifdef SQL_HANDLE_DBC
	    return SQL_HANDLE_DBC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_HANDLE_DESC"))
#ifdef SQL_HANDLE_DESC
	    return SQL_HANDLE_DESC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_HANDLE_ENV"))
#ifdef SQL_HANDLE_ENV
	    return SQL_HANDLE_ENV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_HANDLE_SENV"))
#ifdef SQL_HANDLE_SENV
	    return SQL_HANDLE_SENV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_HANDLE_STMT"))
#ifdef SQL_HANDLE_STMT
	    return SQL_HANDLE_STMT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_HOUR"))
#ifdef SQL_HOUR
	    return SQL_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_HOUR_TO_MINUTE"))
#ifdef SQL_HOUR_TO_MINUTE
	    return SQL_HOUR_TO_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_HOUR_TO_SECOND"))
#ifdef SQL_HOUR_TO_SECOND
	    return SQL_HOUR_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IBM_ALTERTABLEVARCHAR"))
#ifdef SQL_IBM_ALTERTABLEVARCHAR
	    return SQL_IBM_ALTERTABLEVARCHAR;
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
	if (strEQ(name, "SQL_IK_ALL"))
#ifdef SQL_IK_ALL
	    return SQL_IK_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IK_ASC"))
#ifdef SQL_IK_ASC
	    return SQL_IK_ASC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IK_DESC"))
#ifdef SQL_IK_DESC
	    return SQL_IK_DESC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IK_NONE"))
#ifdef SQL_IK_NONE
	    return SQL_IK_NONE;
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
	if (strEQ(name, "SQL_INDEX_KEYWORDS"))
#ifdef SQL_INDEX_KEYWORDS
	    return SQL_INDEX_KEYWORDS;
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
	if (strEQ(name, "SQL_INFO_SCHEMA_VIEWS"))
#ifdef SQL_INFO_SCHEMA_VIEWS
	    return SQL_INFO_SCHEMA_VIEWS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INITIALLY_DEFERRED"))
#ifdef SQL_INITIALLY_DEFERRED
	    return SQL_INITIALLY_DEFERRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INITIALLY_IMMEDIATE"))
#ifdef SQL_INITIALLY_IMMEDIATE
	    return SQL_INITIALLY_IMMEDIATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INSENSITIVE"))
#ifdef SQL_INSENSITIVE
	    return SQL_INSENSITIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INSERT_STATEMENT"))
#ifdef SQL_INSERT_STATEMENT
	    return SQL_INSERT_STATEMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTEGER"))
#ifdef SQL_INTEGER
	    return SQL_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTEGRITY"))
#ifdef SQL_INTEGRITY
	    return SQL_INTEGRITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL"))
#ifdef SQL_INTERVAL
	    return SQL_INTERVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_DAY"))
#ifdef SQL_INTERVAL_DAY
	    return SQL_INTERVAL_DAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_DAY_TO_HOUR"))
#ifdef SQL_INTERVAL_DAY_TO_HOUR
	    return SQL_INTERVAL_DAY_TO_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_DAY_TO_MINUTE"))
#ifdef SQL_INTERVAL_DAY_TO_MINUTE
	    return SQL_INTERVAL_DAY_TO_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_DAY_TO_SECOND"))
#ifdef SQL_INTERVAL_DAY_TO_SECOND
	    return SQL_INTERVAL_DAY_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_HOUR"))
#ifdef SQL_INTERVAL_HOUR
	    return SQL_INTERVAL_HOUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_HOUR_TO_MINUTE"))
#ifdef SQL_INTERVAL_HOUR_TO_MINUTE
	    return SQL_INTERVAL_HOUR_TO_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_HOUR_TO_SECOND"))
#ifdef SQL_INTERVAL_HOUR_TO_SECOND
	    return SQL_INTERVAL_HOUR_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_MINUTE"))
#ifdef SQL_INTERVAL_MINUTE
	    return SQL_INTERVAL_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_MINUTE_TO_SECOND"))
#ifdef SQL_INTERVAL_MINUTE_TO_SECOND
	    return SQL_INTERVAL_MINUTE_TO_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_MONTH"))
#ifdef SQL_INTERVAL_MONTH
	    return SQL_INTERVAL_MONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_SECOND"))
#ifdef SQL_INTERVAL_SECOND
	    return SQL_INTERVAL_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_YEAR"))
#ifdef SQL_INTERVAL_YEAR
	    return SQL_INTERVAL_YEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTERVAL_YEAR_TO_MONTH"))
#ifdef SQL_INTERVAL_YEAR_TO_MONTH
	    return SQL_INTERVAL_YEAR_TO_MONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INVALID_HANDLE"))
#ifdef SQL_INVALID_HANDLE
	    return SQL_INVALID_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_ASSERTIONS"))
#ifdef SQL_ISV_ASSERTIONS
	    return SQL_ISV_ASSERTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_CHARACTER_SETS"))
#ifdef SQL_ISV_CHARACTER_SETS
	    return SQL_ISV_CHARACTER_SETS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_CHECK_CONSTRAINTS"))
#ifdef SQL_ISV_CHECK_CONSTRAINTS
	    return SQL_ISV_CHECK_CONSTRAINTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_COLLATIONS"))
#ifdef SQL_ISV_COLLATIONS
	    return SQL_ISV_COLLATIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_COLUMNS"))
#ifdef SQL_ISV_COLUMNS
	    return SQL_ISV_COLUMNS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_COLUMN_DOMAIN_USAGE"))
#ifdef SQL_ISV_COLUMN_DOMAIN_USAGE
	    return SQL_ISV_COLUMN_DOMAIN_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_COLUMN_PRIVILEGES"))
#ifdef SQL_ISV_COLUMN_PRIVILEGES
	    return SQL_ISV_COLUMN_PRIVILEGES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_CONSTRAINT_COLUMN_USAGE"))
#ifdef SQL_ISV_CONSTRAINT_COLUMN_USAGE
	    return SQL_ISV_CONSTRAINT_COLUMN_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_CONSTRAINT_TABLE_USAGE"))
#ifdef SQL_ISV_CONSTRAINT_TABLE_USAGE
	    return SQL_ISV_CONSTRAINT_TABLE_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_DOMAINS"))
#ifdef SQL_ISV_DOMAINS
	    return SQL_ISV_DOMAINS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_DOMAIN_CONSTRAINTS"))
#ifdef SQL_ISV_DOMAIN_CONSTRAINTS
	    return SQL_ISV_DOMAIN_CONSTRAINTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_KEY_COLUMN_USAGE"))
#ifdef SQL_ISV_KEY_COLUMN_USAGE
	    return SQL_ISV_KEY_COLUMN_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_REFERENTIAL_CONSTRAINTS"))
#ifdef SQL_ISV_REFERENTIAL_CONSTRAINTS
	    return SQL_ISV_REFERENTIAL_CONSTRAINTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_SCHEMATA"))
#ifdef SQL_ISV_SCHEMATA
	    return SQL_ISV_SCHEMATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_SQL_LANGUAGES"))
#ifdef SQL_ISV_SQL_LANGUAGES
	    return SQL_ISV_SQL_LANGUAGES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_TABLES"))
#ifdef SQL_ISV_TABLES
	    return SQL_ISV_TABLES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_TABLE_CONSTRAINTS"))
#ifdef SQL_ISV_TABLE_CONSTRAINTS
	    return SQL_ISV_TABLE_CONSTRAINTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_TABLE_PRIVILEGES"))
#ifdef SQL_ISV_TABLE_PRIVILEGES
	    return SQL_ISV_TABLE_PRIVILEGES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_TRANSLATIONS"))
#ifdef SQL_ISV_TRANSLATIONS
	    return SQL_ISV_TRANSLATIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_USAGE_PRIVILEGES"))
#ifdef SQL_ISV_USAGE_PRIVILEGES
	    return SQL_ISV_USAGE_PRIVILEGES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_VIEWS"))
#ifdef SQL_ISV_VIEWS
	    return SQL_ISV_VIEWS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_VIEW_COLUMN_USAGE"))
#ifdef SQL_ISV_VIEW_COLUMN_USAGE
	    return SQL_ISV_VIEW_COLUMN_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ISV_VIEW_TABLE_USAGE"))
#ifdef SQL_ISV_VIEW_TABLE_USAGE
	    return SQL_ISV_VIEW_TABLE_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IS_INSERT_LITERALS"))
#ifdef SQL_IS_INSERT_LITERALS
	    return SQL_IS_INSERT_LITERALS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IS_INSERT_SEARCHED"))
#ifdef SQL_IS_INSERT_SEARCHED
	    return SQL_IS_INSERT_SEARCHED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IS_INTEGER"))
#ifdef SQL_IS_INTEGER
	    return SQL_IS_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IS_POINTER"))
#ifdef SQL_IS_POINTER
	    return SQL_IS_POINTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IS_SELECT_INTO"))
#ifdef SQL_IS_SELECT_INTO
	    return SQL_IS_SELECT_INTO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IS_SMALLINT"))
#ifdef SQL_IS_SMALLINT
	    return SQL_IS_SMALLINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IS_UINTEGER"))
#ifdef SQL_IS_UINTEGER
	    return SQL_IS_UINTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_IS_USMALLINT"))
#ifdef SQL_IS_USMALLINT
	    return SQL_IS_USMALLINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_KEYSET_CURSOR_ATTRIBUTES1"))
#ifdef SQL_KEYSET_CURSOR_ATTRIBUTES1
	    return SQL_KEYSET_CURSOR_ATTRIBUTES1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_KEYSET_CURSOR_ATTRIBUTES2"))
#ifdef SQL_KEYSET_CURSOR_ATTRIBUTES2
	    return SQL_KEYSET_CURSOR_ATTRIBUTES2;
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
	if (strEQ(name, "SQL_LD_COMPAT_DEFAULT"))
#ifdef SQL_LD_COMPAT_DEFAULT
	    return SQL_LD_COMPAT_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LD_COMPAT_NO"))
#ifdef SQL_LD_COMPAT_NO
	    return SQL_LD_COMPAT_NO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LD_COMPAT_YES"))
#ifdef SQL_LD_COMPAT_YES
	    return SQL_LD_COMPAT_YES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LEN_BINARY_ATTR_OFFSET"))
#ifdef SQL_LEN_BINARY_ATTR_OFFSET
	    return SQL_LEN_BINARY_ATTR_OFFSET;
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
	if (strEQ(name, "SQL_LONGDATA_COMPAT"))
#ifdef SQL_LONGDATA_COMPAT
	    return SQL_LONGDATA_COMPAT;
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
	if (strEQ(name, "SQL_LONGVARGRAPHIC"))
#ifdef SQL_LONGVARGRAPHIC
	    return SQL_LONGVARGRAPHIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXCONN"))
#ifdef SQL_MAXCONN
	    return SQL_MAXCONN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_CATALOG_NAME_LENGTH"))
#ifdef SQL_MAXIMUM_CATALOG_NAME_LENGTH
	    return SQL_MAXIMUM_CATALOG_NAME_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_COLUMNS_IN_GROUP_BY"))
#ifdef SQL_MAXIMUM_COLUMNS_IN_GROUP_BY
	    return SQL_MAXIMUM_COLUMNS_IN_GROUP_BY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_COLUMNS_IN_INDEX"))
#ifdef SQL_MAXIMUM_COLUMNS_IN_INDEX
	    return SQL_MAXIMUM_COLUMNS_IN_INDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_COLUMNS_IN_ORDER_BY"))
#ifdef SQL_MAXIMUM_COLUMNS_IN_ORDER_BY
	    return SQL_MAXIMUM_COLUMNS_IN_ORDER_BY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_COLUMNS_IN_SELECT"))
#ifdef SQL_MAXIMUM_COLUMNS_IN_SELECT
	    return SQL_MAXIMUM_COLUMNS_IN_SELECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_COLUMN_NAME_LENGTH"))
#ifdef SQL_MAXIMUM_COLUMN_NAME_LENGTH
	    return SQL_MAXIMUM_COLUMN_NAME_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_CONCURRENT_ACTIVITIES"))
#ifdef SQL_MAXIMUM_CONCURRENT_ACTIVITIES
	    return SQL_MAXIMUM_CONCURRENT_ACTIVITIES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_CURSOR_NAME_LENGTH"))
#ifdef SQL_MAXIMUM_CURSOR_NAME_LENGTH
	    return SQL_MAXIMUM_CURSOR_NAME_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_DRIVER_CONNECTIONS"))
#ifdef SQL_MAXIMUM_DRIVER_CONNECTIONS
	    return SQL_MAXIMUM_DRIVER_CONNECTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_IDENTIFIER_LENGTH"))
#ifdef SQL_MAXIMUM_IDENTIFIER_LENGTH
	    return SQL_MAXIMUM_IDENTIFIER_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_INDEX_SIZE"))
#ifdef SQL_MAXIMUM_INDEX_SIZE
	    return SQL_MAXIMUM_INDEX_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_ROW_SIZE"))
#ifdef SQL_MAXIMUM_ROW_SIZE
	    return SQL_MAXIMUM_ROW_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_SCHEMA_NAME_LENGTH"))
#ifdef SQL_MAXIMUM_SCHEMA_NAME_LENGTH
	    return SQL_MAXIMUM_SCHEMA_NAME_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_STATEMENT_LENGTH"))
#ifdef SQL_MAXIMUM_STATEMENT_LENGTH
	    return SQL_MAXIMUM_STATEMENT_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_TABLES_IN_SELECT"))
#ifdef SQL_MAXIMUM_TABLES_IN_SELECT
	    return SQL_MAXIMUM_TABLES_IN_SELECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAXIMUM_USER_NAME_LENGTH"))
#ifdef SQL_MAXIMUM_USER_NAME_LENGTH
	    return SQL_MAXIMUM_USER_NAME_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_ASYNC_CONCURRENT_STATEMENTS"))
#ifdef SQL_MAX_ASYNC_CONCURRENT_STATEMENTS
	    return SQL_MAX_ASYNC_CONCURRENT_STATEMENTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_BINARY_LITERAL_LEN"))
#ifdef SQL_MAX_BINARY_LITERAL_LEN
	    return SQL_MAX_BINARY_LITERAL_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_CATALOG_NAME_LEN"))
#ifdef SQL_MAX_CATALOG_NAME_LEN
	    return SQL_MAX_CATALOG_NAME_LEN;
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
	if (strEQ(name, "SQL_MAX_CONCURRENT_ACTIVITIES"))
#ifdef SQL_MAX_CONCURRENT_ACTIVITIES
	    return SQL_MAX_CONCURRENT_ACTIVITIES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_CURSOR_NAME_LEN"))
#ifdef SQL_MAX_CURSOR_NAME_LEN
	    return SQL_MAX_CURSOR_NAME_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_DRIVER_CONNECTIONS"))
#ifdef SQL_MAX_DRIVER_CONNECTIONS
	    return SQL_MAX_DRIVER_CONNECTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_DSN_LENGTH"))
#ifdef SQL_MAX_DSN_LENGTH
	    return SQL_MAX_DSN_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_IDENTIFIER_LEN"))
#ifdef SQL_MAX_IDENTIFIER_LEN
	    return SQL_MAX_IDENTIFIER_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MAX_ID_LENGTH"))
#ifdef SQL_MAX_ID_LENGTH
	    return SQL_MAX_ID_LENGTH;
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
	if (strEQ(name, "SQL_MAX_NUMERIC_LEN"))
#ifdef SQL_MAX_NUMERIC_LEN
	    return SQL_MAX_NUMERIC_LEN;
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
	if (strEQ(name, "SQL_MAX_SCHEMA_NAME_LEN"))
#ifdef SQL_MAX_SCHEMA_NAME_LEN
	    return SQL_MAX_SCHEMA_NAME_LEN;
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
	if (strEQ(name, "SQL_MINMEMORY_USAGE"))
#ifdef SQL_MINMEMORY_USAGE
	    return SQL_MINMEMORY_USAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MINUTE"))
#ifdef SQL_MINUTE
	    return SQL_MINUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_MINUTE_TO_SECOND"))
#ifdef SQL_MINUTE_TO_SECOND
	    return SQL_MINUTE_TO_SECOND;
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
	if (strEQ(name, "SQL_MONTH"))
#ifdef SQL_MONTH
	    return SQL_MONTH;
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
	if (strEQ(name, "SQL_NAMED"))
#ifdef SQL_NAMED
	    return SQL_NAMED;
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
	if (strEQ(name, "SQL_NODESCRIBE"))
#ifdef SQL_NODESCRIBE
	    return SQL_NODESCRIBE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NODESCRIBE_DEFAULT"))
#ifdef SQL_NODESCRIBE_DEFAULT
	    return SQL_NODESCRIBE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NODESCRIBE_INPUT"))
#ifdef SQL_NODESCRIBE_INPUT
	    return SQL_NODESCRIBE_INPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NODESCRIBE_OFF"))
#ifdef SQL_NODESCRIBE_OFF
	    return SQL_NODESCRIBE_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NODESCRIBE_ON"))
#ifdef SQL_NODESCRIBE_ON
	    return SQL_NODESCRIBE_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NODESCRIBE_OUTPUT"))
#ifdef SQL_NODESCRIBE_OUTPUT
	    return SQL_NODESCRIBE_OUTPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NONSCROLLABLE"))
#ifdef SQL_NONSCROLLABLE
	    return SQL_NONSCROLLABLE;
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
	if (strEQ(name, "SQL_NOT_DEFERRABLE"))
#ifdef SQL_NOT_DEFERRABLE
	    return SQL_NOT_DEFERRABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NO_ACTION"))
#ifdef SQL_NO_ACTION
	    return SQL_NO_ACTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NO_COLUMN_NUMBER"))
#ifdef SQL_NO_COLUMN_NUMBER
	    return SQL_NO_COLUMN_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NO_DATA"))
#ifdef SQL_NO_DATA
	    return SQL_NO_DATA;
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
	if (strEQ(name, "SQL_NO_ROW_NUMBER"))
#ifdef SQL_NO_ROW_NUMBER
	    return SQL_NO_ROW_NUMBER;
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
	if (strEQ(name, "SQL_NTSL"))
#ifdef SQL_NTSL
	    return SQL_NTSL;
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
	if (strEQ(name, "SQL_NULL_COLLATION"))
#ifdef SQL_NULL_COLLATION
	    return SQL_NULL_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULL_DATA"))
#ifdef SQL_NULL_DATA
	    return SQL_NULL_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULL_HANDLE"))
#ifdef SQL_NULL_HANDLE
	    return SQL_NULL_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULL_HDBC"))
#ifdef SQL_NULL_HDBC
	    return SQL_NULL_HDBC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULL_HDESC"))
#ifdef SQL_NULL_HDESC
	    return SQL_NULL_HDESC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULL_HENV"))
#ifdef SQL_NULL_HENV
	    return SQL_NULL_HENV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULL_HSTMT"))
#ifdef SQL_NULL_HSTMT
	    return SQL_NULL_HSTMT;
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
	if (strEQ(name, "SQL_ODBC_INTERFACE_CONFORMANCE"))
#ifdef SQL_ODBC_INTERFACE_CONFORMANCE
	    return SQL_ODBC_INTERFACE_CONFORMANCE;
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
	if (strEQ(name, "SQL_OIC_CORE"))
#ifdef SQL_OIC_CORE
	    return SQL_OIC_CORE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OIC_LEVEL1"))
#ifdef SQL_OIC_LEVEL1
	    return SQL_OIC_LEVEL1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OIC_LEVEL2"))
#ifdef SQL_OIC_LEVEL2
	    return SQL_OIC_LEVEL2;
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
	if (strEQ(name, "SQL_ONEPHASE"))
#ifdef SQL_ONEPHASE
	    return SQL_ONEPHASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OPTIMIZE_SQLCOLUMNS_DEFAULT"))
#ifdef SQL_OPTIMIZE_SQLCOLUMNS_DEFAULT
	    return SQL_OPTIMIZE_SQLCOLUMNS_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OPTIMIZE_SQLCOLUMNS_OFF"))
#ifdef SQL_OPTIMIZE_SQLCOLUMNS_OFF
	    return SQL_OPTIMIZE_SQLCOLUMNS_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OPTIMIZE_SQLCOLUMNS_ON"))
#ifdef SQL_OPTIMIZE_SQLCOLUMNS_ON
	    return SQL_OPTIMIZE_SQLCOLUMNS_ON;
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
	if (strEQ(name, "SQL_OUTER_JOIN_CAPABILITIES"))
#ifdef SQL_OUTER_JOIN_CAPABILITIES
	    return SQL_OUTER_JOIN_CAPABILITIES;
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
	if (strEQ(name, "SQL_OV_ODBC2"))
#ifdef SQL_OV_ODBC2
	    return SQL_OV_ODBC2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_OV_ODBC3"))
#ifdef SQL_OV_ODBC3
	    return SQL_OV_ODBC3;
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
	if (strEQ(name, "SQL_PARAMOPT_ATOMIC"))
#ifdef SQL_PARAMOPT_ATOMIC
	    return SQL_PARAMOPT_ATOMIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_ARRAY_ROW_COUNTS"))
#ifdef SQL_PARAM_ARRAY_ROW_COUNTS
	    return SQL_PARAM_ARRAY_ROW_COUNTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_ARRAY_SELECTS"))
#ifdef SQL_PARAM_ARRAY_SELECTS
	    return SQL_PARAM_ARRAY_SELECTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_BIND_BY_COLUMN"))
#ifdef SQL_PARAM_BIND_BY_COLUMN
	    return SQL_PARAM_BIND_BY_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_BIND_TYPE_DEFAULT"))
#ifdef SQL_PARAM_BIND_TYPE_DEFAULT
	    return SQL_PARAM_BIND_TYPE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_DIAG_UNAVAILABLE"))
#ifdef SQL_PARAM_DIAG_UNAVAILABLE
	    return SQL_PARAM_DIAG_UNAVAILABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_ERROR"))
#ifdef SQL_PARAM_ERROR
	    return SQL_PARAM_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_IGNORE"))
#ifdef SQL_PARAM_IGNORE
	    return SQL_PARAM_IGNORE;
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
	if (strEQ(name, "SQL_PARAM_PROCEED"))
#ifdef SQL_PARAM_PROCEED
	    return SQL_PARAM_PROCEED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_SUCCESS"))
#ifdef SQL_PARAM_SUCCESS
	    return SQL_PARAM_SUCCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARAM_SUCCESS_WITH_INFO"))
#ifdef SQL_PARAM_SUCCESS_WITH_INFO
	    return SQL_PARAM_SUCCESS_WITH_INFO;
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
	if (strEQ(name, "SQL_PARAM_UNUSED"))
#ifdef SQL_PARAM_UNUSED
	    return SQL_PARAM_UNUSED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARC_BATCH"))
#ifdef SQL_PARC_BATCH
	    return SQL_PARC_BATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PARC_NO_BATCH"))
#ifdef SQL_PARC_NO_BATCH
	    return SQL_PARC_NO_BATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PAS_BATCH"))
#ifdef SQL_PAS_BATCH
	    return SQL_PAS_BATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PAS_NO_BATCH"))
#ifdef SQL_PAS_NO_BATCH
	    return SQL_PAS_NO_BATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PAS_NO_SELECT"))
#ifdef SQL_PAS_NO_SELECT
	    return SQL_PAS_NO_SELECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PC_NON_PSEUDO"))
#ifdef SQL_PC_NON_PSEUDO
	    return SQL_PC_NON_PSEUDO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PC_NOT_PSEUDO"))
#ifdef SQL_PC_NOT_PSEUDO
	    return SQL_PC_NOT_PSEUDO;
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
	if (strEQ(name, "SQL_PRED_BASIC"))
#ifdef SQL_PRED_BASIC
	    return SQL_PRED_BASIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PRED_CHAR"))
#ifdef SQL_PRED_CHAR
	    return SQL_PRED_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PRED_NONE"))
#ifdef SQL_PRED_NONE
	    return SQL_PRED_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PRED_SEARCHABLE"))
#ifdef SQL_PRED_SEARCHABLE
	    return SQL_PRED_SEARCHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PREFETCH_DEFAULT"))
#ifdef SQL_PREFETCH_DEFAULT
	    return SQL_PREFETCH_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PREFETCH_OFF"))
#ifdef SQL_PREFETCH_OFF
	    return SQL_PREFETCH_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PREFETCH_ON"))
#ifdef SQL_PREFETCH_ON
	    return SQL_PREFETCH_ON;
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
	if (strEQ(name, "SQL_PROCESSCTL_NOFORK"))
#ifdef SQL_PROCESSCTL_NOFORK
	    return SQL_PROCESSCTL_NOFORK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_PROCESSCTL_NOTHREAD"))
#ifdef SQL_PROCESSCTL_NOTHREAD
	    return SQL_PROCESSCTL_NOTHREAD;
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
	if (strEQ(name, "SQL_RETURN_VALUE"))
#ifdef SQL_RETURN_VALUE
	    return SQL_RETURN_VALUE;
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
	if (strEQ(name, "SQL_ROW_IDENTIFIER"))
#ifdef SQL_ROW_IDENTIFIER
	    return SQL_ROW_IDENTIFIER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_IGNORE"))
#ifdef SQL_ROW_IGNORE
	    return SQL_ROW_IGNORE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_NOROW"))
#ifdef SQL_ROW_NOROW
	    return SQL_ROW_NOROW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_NO_ROW_NUMBER"))
#ifdef SQL_ROW_NO_ROW_NUMBER
	    return SQL_ROW_NO_ROW_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_NUMBER"))
#ifdef SQL_ROW_NUMBER
	    return SQL_ROW_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_NUMBER_UNKNOWN"))
#ifdef SQL_ROW_NUMBER_UNKNOWN
	    return SQL_ROW_NUMBER_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_PROCEED"))
#ifdef SQL_ROW_PROCEED
	    return SQL_ROW_PROCEED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_SUCCESS"))
#ifdef SQL_ROW_SUCCESS
	    return SQL_ROW_SUCCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROW_SUCCESS_WITH_INFO"))
#ifdef SQL_ROW_SUCCESS_WITH_INFO
	    return SQL_ROW_SUCCESS_WITH_INFO;
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
	if (strEQ(name, "SQL_SCC_ISO92_CLI"))
#ifdef SQL_SCC_ISO92_CLI
	    return SQL_SCC_ISO92_CLI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCC_XOPEN_CLI_VERSION1"))
#ifdef SQL_SCC_XOPEN_CLI_VERSION1
	    return SQL_SCC_XOPEN_CLI_VERSION1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCHEMA_TERM"))
#ifdef SQL_SCHEMA_TERM
	    return SQL_SCHEMA_TERM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SCHEMA_USAGE"))
#ifdef SQL_SCHEMA_USAGE
	    return SQL_SCHEMA_USAGE;
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
	if (strEQ(name, "SQL_SCROLLABLE"))
#ifdef SQL_SCROLLABLE
	    return SQL_SCROLLABLE;
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
	if (strEQ(name, "SQL_SC_FIPS127_2_TRANSITIONAL"))
#ifdef SQL_SC_FIPS127_2_TRANSITIONAL
	    return SQL_SC_FIPS127_2_TRANSITIONAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SC_NON_UNIQUE"))
#ifdef SQL_SC_NON_UNIQUE
	    return SQL_SC_NON_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SC_SQL92_ENTRY"))
#ifdef SQL_SC_SQL92_ENTRY
	    return SQL_SC_SQL92_ENTRY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SC_SQL92_FULL"))
#ifdef SQL_SC_SQL92_FULL
	    return SQL_SC_SQL92_FULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SC_SQL92_INTERMEDIATE"))
#ifdef SQL_SC_SQL92_INTERMEDIATE
	    return SQL_SC_SQL92_INTERMEDIATE;
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
	if (strEQ(name, "SQL_SDF_CURRENT_DATE"))
#ifdef SQL_SDF_CURRENT_DATE
	    return SQL_SDF_CURRENT_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SDF_CURRENT_TIME"))
#ifdef SQL_SDF_CURRENT_TIME
	    return SQL_SDF_CURRENT_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SDF_CURRENT_TIMESTAMP"))
#ifdef SQL_SDF_CURRENT_TIMESTAMP
	    return SQL_SDF_CURRENT_TIMESTAMP;
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
	if (strEQ(name, "SQL_SECOND"))
#ifdef SQL_SECOND
	    return SQL_SECOND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SENSITIVE"))
#ifdef SQL_SENSITIVE
	    return SQL_SENSITIVE;
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
	if (strEQ(name, "SQL_SETPOS_MAX_LOCK_VALUE"))
#ifdef SQL_SETPOS_MAX_LOCK_VALUE
	    return SQL_SETPOS_MAX_LOCK_VALUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SETPOS_MAX_OPTION_VALUE"))
#ifdef SQL_SETPOS_MAX_OPTION_VALUE
	    return SQL_SETPOS_MAX_OPTION_VALUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SET_DEFAULT"))
#ifdef SQL_SET_DEFAULT
	    return SQL_SET_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SET_NULL"))
#ifdef SQL_SET_NULL
	    return SQL_SET_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SFKD_CASCADE"))
#ifdef SQL_SFKD_CASCADE
	    return SQL_SFKD_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SFKD_NO_ACTION"))
#ifdef SQL_SFKD_NO_ACTION
	    return SQL_SFKD_NO_ACTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SFKD_SET_DEFAULT"))
#ifdef SQL_SFKD_SET_DEFAULT
	    return SQL_SFKD_SET_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SFKD_SET_NULL"))
#ifdef SQL_SFKD_SET_NULL
	    return SQL_SFKD_SET_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SFKU_CASCADE"))
#ifdef SQL_SFKU_CASCADE
	    return SQL_SFKU_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SFKU_NO_ACTION"))
#ifdef SQL_SFKU_NO_ACTION
	    return SQL_SFKU_NO_ACTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SFKU_SET_DEFAULT"))
#ifdef SQL_SFKU_SET_DEFAULT
	    return SQL_SFKU_SET_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SFKU_SET_NULL"))
#ifdef SQL_SFKU_SET_NULL
	    return SQL_SFKU_SET_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_DELETE_TABLE"))
#ifdef SQL_SG_DELETE_TABLE
	    return SQL_SG_DELETE_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_INSERT_COLUMN"))
#ifdef SQL_SG_INSERT_COLUMN
	    return SQL_SG_INSERT_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_INSERT_TABLE"))
#ifdef SQL_SG_INSERT_TABLE
	    return SQL_SG_INSERT_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_REFERENCES_COLUMN"))
#ifdef SQL_SG_REFERENCES_COLUMN
	    return SQL_SG_REFERENCES_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_REFERENCES_TABLE"))
#ifdef SQL_SG_REFERENCES_TABLE
	    return SQL_SG_REFERENCES_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_SELECT_TABLE"))
#ifdef SQL_SG_SELECT_TABLE
	    return SQL_SG_SELECT_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_UPDATE_COLUMN"))
#ifdef SQL_SG_UPDATE_COLUMN
	    return SQL_SG_UPDATE_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_UPDATE_TABLE"))
#ifdef SQL_SG_UPDATE_TABLE
	    return SQL_SG_UPDATE_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_USAGE_ON_CHARACTER_SET"))
#ifdef SQL_SG_USAGE_ON_CHARACTER_SET
	    return SQL_SG_USAGE_ON_CHARACTER_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_USAGE_ON_COLLATION"))
#ifdef SQL_SG_USAGE_ON_COLLATION
	    return SQL_SG_USAGE_ON_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_USAGE_ON_DOMAIN"))
#ifdef SQL_SG_USAGE_ON_DOMAIN
	    return SQL_SG_USAGE_ON_DOMAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_USAGE_ON_TRANSLATION"))
#ifdef SQL_SG_USAGE_ON_TRANSLATION
	    return SQL_SG_USAGE_ON_TRANSLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SG_WITH_GRANT_OPTION"))
#ifdef SQL_SG_WITH_GRANT_OPTION
	    return SQL_SG_WITH_GRANT_OPTION;
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
	if (strEQ(name, "SQL_SNVF_BIT_LENGTH"))
#ifdef SQL_SNVF_BIT_LENGTH
	    return SQL_SNVF_BIT_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SNVF_CHARACTER_LENGTH"))
#ifdef SQL_SNVF_CHARACTER_LENGTH
	    return SQL_SNVF_CHARACTER_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SNVF_CHAR_LENGTH"))
#ifdef SQL_SNVF_CHAR_LENGTH
	    return SQL_SNVF_CHAR_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SNVF_EXTRACT"))
#ifdef SQL_SNVF_EXTRACT
	    return SQL_SNVF_EXTRACT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SNVF_OCTET_LENGTH"))
#ifdef SQL_SNVF_OCTET_LENGTH
	    return SQL_SNVF_OCTET_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SNVF_POSITION"))
#ifdef SQL_SNVF_POSITION
	    return SQL_SNVF_POSITION;
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
	if (strEQ(name, "SQL_SP_BETWEEN"))
#ifdef SQL_SP_BETWEEN
	    return SQL_SP_BETWEEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_COMPARISON"))
#ifdef SQL_SP_COMPARISON
	    return SQL_SP_COMPARISON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_EXISTS"))
#ifdef SQL_SP_EXISTS
	    return SQL_SP_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_IN"))
#ifdef SQL_SP_IN
	    return SQL_SP_IN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_ISNOTNULL"))
#ifdef SQL_SP_ISNOTNULL
	    return SQL_SP_ISNOTNULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_ISNULL"))
#ifdef SQL_SP_ISNULL
	    return SQL_SP_ISNULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_LIKE"))
#ifdef SQL_SP_LIKE
	    return SQL_SP_LIKE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_MATCH_FULL"))
#ifdef SQL_SP_MATCH_FULL
	    return SQL_SP_MATCH_FULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_MATCH_PARTIAL"))
#ifdef SQL_SP_MATCH_PARTIAL
	    return SQL_SP_MATCH_PARTIAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_MATCH_UNIQUE_FULL"))
#ifdef SQL_SP_MATCH_UNIQUE_FULL
	    return SQL_SP_MATCH_UNIQUE_FULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_MATCH_UNIQUE_PARTIAL"))
#ifdef SQL_SP_MATCH_UNIQUE_PARTIAL
	    return SQL_SP_MATCH_UNIQUE_PARTIAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_OVERLAPS"))
#ifdef SQL_SP_OVERLAPS
	    return SQL_SP_OVERLAPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_QUANTIFIED_COMPARISON"))
#ifdef SQL_SP_QUANTIFIED_COMPARISON
	    return SQL_SP_QUANTIFIED_COMPARISON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SP_UNIQUE"))
#ifdef SQL_SP_UNIQUE
	    return SQL_SP_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_DATETIME_FUNCTIONS"))
#ifdef SQL_SQL92_DATETIME_FUNCTIONS
	    return SQL_SQL92_DATETIME_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_FOREIGN_KEY_DELETE_RULE"))
#ifdef SQL_SQL92_FOREIGN_KEY_DELETE_RULE
	    return SQL_SQL92_FOREIGN_KEY_DELETE_RULE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_FOREIGN_KEY_UPDATE_RULE"))
#ifdef SQL_SQL92_FOREIGN_KEY_UPDATE_RULE
	    return SQL_SQL92_FOREIGN_KEY_UPDATE_RULE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_GRANT"))
#ifdef SQL_SQL92_GRANT
	    return SQL_SQL92_GRANT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_NUMERIC_VALUE_FUNCTIONS"))
#ifdef SQL_SQL92_NUMERIC_VALUE_FUNCTIONS
	    return SQL_SQL92_NUMERIC_VALUE_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_PREDICATES"))
#ifdef SQL_SQL92_PREDICATES
	    return SQL_SQL92_PREDICATES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_RELATIONAL_JOIN_OPERATORS"))
#ifdef SQL_SQL92_RELATIONAL_JOIN_OPERATORS
	    return SQL_SQL92_RELATIONAL_JOIN_OPERATORS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_REVOKE"))
#ifdef SQL_SQL92_REVOKE
	    return SQL_SQL92_REVOKE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_ROW_VALUE_CONSTRUCTOR"))
#ifdef SQL_SQL92_ROW_VALUE_CONSTRUCTOR
	    return SQL_SQL92_ROW_VALUE_CONSTRUCTOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_STRING_FUNCTIONS"))
#ifdef SQL_SQL92_STRING_FUNCTIONS
	    return SQL_SQL92_STRING_FUNCTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL92_VALUE_EXPRESSIONS"))
#ifdef SQL_SQL92_VALUE_EXPRESSIONS
	    return SQL_SQL92_VALUE_EXPRESSIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQLSTATE_SIZE"))
#ifdef SQL_SQLSTATE_SIZE
	    return SQL_SQLSTATE_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SQL_CONFORMANCE"))
#ifdef SQL_SQL_CONFORMANCE
	    return SQL_SQL_CONFORMANCE;
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
	if (strEQ(name, "SQL_SRJO_CORRESPONDING_CLAUSE"))
#ifdef SQL_SRJO_CORRESPONDING_CLAUSE
	    return SQL_SRJO_CORRESPONDING_CLAUSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRJO_CROSS_JOIN"))
#ifdef SQL_SRJO_CROSS_JOIN
	    return SQL_SRJO_CROSS_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRJO_EXCEPT_JOIN"))
#ifdef SQL_SRJO_EXCEPT_JOIN
	    return SQL_SRJO_EXCEPT_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRJO_FULL_OUTER_JOIN"))
#ifdef SQL_SRJO_FULL_OUTER_JOIN
	    return SQL_SRJO_FULL_OUTER_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRJO_INNER_JOIN"))
#ifdef SQL_SRJO_INNER_JOIN
	    return SQL_SRJO_INNER_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRJO_INTERSECT_JOIN"))
#ifdef SQL_SRJO_INTERSECT_JOIN
	    return SQL_SRJO_INTERSECT_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRJO_LEFT_OUTER_JOIN"))
#ifdef SQL_SRJO_LEFT_OUTER_JOIN
	    return SQL_SRJO_LEFT_OUTER_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRJO_NATURAL_JOIN"))
#ifdef SQL_SRJO_NATURAL_JOIN
	    return SQL_SRJO_NATURAL_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRJO_RIGHT_OUTER_JOIN"))
#ifdef SQL_SRJO_RIGHT_OUTER_JOIN
	    return SQL_SRJO_RIGHT_OUTER_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRJO_UNION_JOIN"))
#ifdef SQL_SRJO_UNION_JOIN
	    return SQL_SRJO_UNION_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRVC_DEFAULT"))
#ifdef SQL_SRVC_DEFAULT
	    return SQL_SRVC_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRVC_NULL"))
#ifdef SQL_SRVC_NULL
	    return SQL_SRVC_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRVC_ROW_SUBQUERY"))
#ifdef SQL_SRVC_ROW_SUBQUERY
	    return SQL_SRVC_ROW_SUBQUERY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SRVC_VALUE_EXPRESSION"))
#ifdef SQL_SRVC_VALUE_EXPRESSION
	    return SQL_SRVC_VALUE_EXPRESSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_CASCADE"))
#ifdef SQL_SR_CASCADE
	    return SQL_SR_CASCADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_DELETE_TABLE"))
#ifdef SQL_SR_DELETE_TABLE
	    return SQL_SR_DELETE_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_GRANT_OPTION_FOR"))
#ifdef SQL_SR_GRANT_OPTION_FOR
	    return SQL_SR_GRANT_OPTION_FOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_INSERT_COLUMN"))
#ifdef SQL_SR_INSERT_COLUMN
	    return SQL_SR_INSERT_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_INSERT_TABLE"))
#ifdef SQL_SR_INSERT_TABLE
	    return SQL_SR_INSERT_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_REFERENCES_COLUMN"))
#ifdef SQL_SR_REFERENCES_COLUMN
	    return SQL_SR_REFERENCES_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_REFERENCES_TABLE"))
#ifdef SQL_SR_REFERENCES_TABLE
	    return SQL_SR_REFERENCES_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_RESTRICT"))
#ifdef SQL_SR_RESTRICT
	    return SQL_SR_RESTRICT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_SELECT_TABLE"))
#ifdef SQL_SR_SELECT_TABLE
	    return SQL_SR_SELECT_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_UPDATE_COLUMN"))
#ifdef SQL_SR_UPDATE_COLUMN
	    return SQL_SR_UPDATE_COLUMN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_UPDATE_TABLE"))
#ifdef SQL_SR_UPDATE_TABLE
	    return SQL_SR_UPDATE_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_USAGE_ON_CHARACTER_SET"))
#ifdef SQL_SR_USAGE_ON_CHARACTER_SET
	    return SQL_SR_USAGE_ON_CHARACTER_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_USAGE_ON_COLLATION"))
#ifdef SQL_SR_USAGE_ON_COLLATION
	    return SQL_SR_USAGE_ON_COLLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_USAGE_ON_DOMAIN"))
#ifdef SQL_SR_USAGE_ON_DOMAIN
	    return SQL_SR_USAGE_ON_DOMAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SR_USAGE_ON_TRANSLATION"))
#ifdef SQL_SR_USAGE_ON_TRANSLATION
	    return SQL_SR_USAGE_ON_TRANSLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SSF_CONVERT"))
#ifdef SQL_SSF_CONVERT
	    return SQL_SSF_CONVERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SSF_LOWER"))
#ifdef SQL_SSF_LOWER
	    return SQL_SSF_LOWER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SSF_SUBSTRING"))
#ifdef SQL_SSF_SUBSTRING
	    return SQL_SSF_SUBSTRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SSF_TRANSLATE"))
#ifdef SQL_SSF_TRANSLATE
	    return SQL_SSF_TRANSLATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SSF_TRIM_BOTH"))
#ifdef SQL_SSF_TRIM_BOTH
	    return SQL_SSF_TRIM_BOTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SSF_TRIM_LEADING"))
#ifdef SQL_SSF_TRIM_LEADING
	    return SQL_SSF_TRIM_LEADING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SSF_TRIM_TRAILING"))
#ifdef SQL_SSF_TRIM_TRAILING
	    return SQL_SSF_TRIM_TRAILING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SSF_UPPER"))
#ifdef SQL_SSF_UPPER
	    return SQL_SSF_UPPER;
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
	if (strEQ(name, "SQL_STANDARD_CLI_CONFORMANCE"))
#ifdef SQL_STANDARD_CLI_CONFORMANCE
	    return SQL_STANDARD_CLI_CONFORMANCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_STATIC_CURSOR_ATTRIBUTES1"))
#ifdef SQL_STATIC_CURSOR_ATTRIBUTES1
	    return SQL_STATIC_CURSOR_ATTRIBUTES1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_STATIC_CURSOR_ATTRIBUTES2"))
#ifdef SQL_STATIC_CURSOR_ATTRIBUTES2
	    return SQL_STATIC_CURSOR_ATTRIBUTES2;
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
	if (strEQ(name, "SQL_STMTTXN_ISOLATION"))
#ifdef SQL_STMTTXN_ISOLATION
	    return SQL_STMTTXN_ISOLATION;
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
	if (strEQ(name, "SQL_SU_DML_STATEMENTS"))
#ifdef SQL_SU_DML_STATEMENTS
	    return SQL_SU_DML_STATEMENTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SU_INDEX_DEFINITION"))
#ifdef SQL_SU_INDEX_DEFINITION
	    return SQL_SU_INDEX_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SU_PRIVILEGE_DEFINITION"))
#ifdef SQL_SU_PRIVILEGE_DEFINITION
	    return SQL_SU_PRIVILEGE_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SU_PROCEDURE_INVOCATION"))
#ifdef SQL_SU_PROCEDURE_INVOCATION
	    return SQL_SU_PROCEDURE_INVOCATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SU_TABLE_DEFINITION"))
#ifdef SQL_SU_TABLE_DEFINITION
	    return SQL_SU_TABLE_DEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SVE_CASE"))
#ifdef SQL_SVE_CASE
	    return SQL_SVE_CASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SVE_CAST"))
#ifdef SQL_SVE_CAST
	    return SQL_SVE_CAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SVE_COALESCE"))
#ifdef SQL_SVE_COALESCE
	    return SQL_SVE_COALESCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SVE_NULLIF"))
#ifdef SQL_SVE_NULLIF
	    return SQL_SVE_NULLIF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SYNCPOINT_DEFAULT"))
#ifdef SQL_SYNCPOINT_DEFAULT
	    return SQL_SYNCPOINT_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SYNC_POINT"))
#ifdef SQL_SYNC_POINT
	    return SQL_SYNC_POINT;
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
	if (strEQ(name, "SQL_TIMESTAMP_LEN"))
#ifdef SQL_TIMESTAMP_LEN
	    return SQL_TIMESTAMP_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TIME_LEN"))
#ifdef SQL_TIME_LEN
	    return SQL_TIME_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TINYINT"))
#ifdef SQL_TINYINT
	    return SQL_TINYINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TRANSACTION_CAPABLE"))
#ifdef SQL_TRANSACTION_CAPABLE
	    return SQL_TRANSACTION_CAPABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TRANSACTION_ISOLATION_OPTION"))
#ifdef SQL_TRANSACTION_ISOLATION_OPTION
	    return SQL_TRANSACTION_ISOLATION_OPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TRANSACTION_NOCOMMIT"))
#ifdef SQL_TRANSACTION_NOCOMMIT
	    return SQL_TRANSACTION_NOCOMMIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TRANSACTION_READ_COMMITTED"))
#ifdef SQL_TRANSACTION_READ_COMMITTED
	    return SQL_TRANSACTION_READ_COMMITTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TRANSACTION_READ_UNCOMMITTED"))
#ifdef SQL_TRANSACTION_READ_UNCOMMITTED
	    return SQL_TRANSACTION_READ_UNCOMMITTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TRANSACTION_REPEATABLE_READ"))
#ifdef SQL_TRANSACTION_REPEATABLE_READ
	    return SQL_TRANSACTION_REPEATABLE_READ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TRANSACTION_SERIALIZABLE"))
#ifdef SQL_TRANSACTION_SERIALIZABLE
	    return SQL_TRANSACTION_SERIALIZABLE;
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
	if (strEQ(name, "SQL_TRUE"))
#ifdef SQL_TRUE
	    return SQL_TRUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TWOPHASE"))
#ifdef SQL_TWOPHASE
	    return SQL_TWOPHASE;
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
	if (strEQ(name, "SQL_TXN_NOCOMMIT"))
#ifdef SQL_TXN_NOCOMMIT
	    return SQL_TXN_NOCOMMIT;
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
	if (strEQ(name, "SQL_TYPE_DATE"))
#ifdef SQL_TYPE_DATE
	    return SQL_TYPE_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TYPE_DRIVER_END"))
#ifdef SQL_TYPE_DRIVER_END
	    return SQL_TYPE_DRIVER_END;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TYPE_DRIVER_START"))
#ifdef SQL_TYPE_DRIVER_START
	    return SQL_TYPE_DRIVER_START;
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
	if (strEQ(name, "SQL_TYPE_NULL"))
#ifdef SQL_TYPE_NULL
	    return SQL_TYPE_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TYPE_TIME"))
#ifdef SQL_TYPE_TIME
	    return SQL_TYPE_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TYPE_TIMESTAMP"))
#ifdef SQL_TYPE_TIMESTAMP
	    return SQL_TYPE_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UB_DEFAULT"))
#ifdef SQL_UB_DEFAULT
	    return SQL_UB_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UB_FIXED"))
#ifdef SQL_UB_FIXED
	    return SQL_UB_FIXED;
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
	if (strEQ(name, "SQL_UB_VARIABLE"))
#ifdef SQL_UB_VARIABLE
	    return SQL_UB_VARIABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNBIND"))
#ifdef SQL_UNBIND
	    return SQL_UNBIND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNICODE"))
#ifdef SQL_UNICODE
	    return SQL_UNICODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNICODE_CHAR"))
#ifdef SQL_UNICODE_CHAR
	    return SQL_UNICODE_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNICODE_LONGVARCHAR"))
#ifdef SQL_UNICODE_LONGVARCHAR
	    return SQL_UNICODE_LONGVARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNICODE_VARCHAR"))
#ifdef SQL_UNICODE_VARCHAR
	    return SQL_UNICODE_VARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNION"))
#ifdef SQL_UNION
	    return SQL_UNION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNION_STATEMENT"))
#ifdef SQL_UNION_STATEMENT
	    return SQL_UNION_STATEMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNKNOWN_TYPE"))
#ifdef SQL_UNKNOWN_TYPE
	    return SQL_UNKNOWN_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNNAMED"))
#ifdef SQL_UNNAMED
	    return SQL_UNNAMED;
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
	if (strEQ(name, "SQL_UNSPECIFIED"))
#ifdef SQL_UNSPECIFIED
	    return SQL_UNSPECIFIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UPDATE"))
#ifdef SQL_UPDATE
	    return SQL_UPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UPDATE_BY_BOOKMARK"))
#ifdef SQL_UPDATE_BY_BOOKMARK
	    return SQL_UPDATE_BY_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UPDT_READONLY"))
#ifdef SQL_UPDT_READONLY
	    return SQL_UPDT_READONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UPDT_READWRITE_UNKNOWN"))
#ifdef SQL_UPDT_READWRITE_UNKNOWN
	    return SQL_UPDT_READWRITE_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UPDT_WRITE"))
#ifdef SQL_UPDT_WRITE
	    return SQL_UPDT_WRITE;
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
	if (strEQ(name, "SQL_US_UNION"))
#ifdef SQL_US_UNION
	    return SQL_US_UNION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_US_UNION_ALL"))
#ifdef SQL_US_UNION_ALL
	    return SQL_US_UNION_ALL;
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
	if (strEQ(name, "SQL_VARGRAPHIC"))
#ifdef SQL_VARGRAPHIC
	    return SQL_VARGRAPHIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_WCHARTYPE"))
#ifdef SQL_WCHARTYPE
	    return SQL_WCHARTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_WCHARTYPE_CONVERT"))
#ifdef SQL_WCHARTYPE_CONVERT
	    return SQL_WCHARTYPE_CONVERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_WCHARTYPE_DEFAULT"))
#ifdef SQL_WCHARTYPE_DEFAULT
	    return SQL_WCHARTYPE_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_WCHARTYPE_NOCONVERT"))
#ifdef SQL_WCHARTYPE_NOCONVERT
	    return SQL_WCHARTYPE_NOCONVERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_XML"))
#ifdef SQL_XML
	    return SQL_XML;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_XOPEN_CLI_YEAR"))
#ifdef SQL_XOPEN_CLI_YEAR
	    return SQL_XOPEN_CLI_YEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_YEAR"))
#ifdef SQL_YEAR
	    return SQL_YEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_YEAR_TO_MONTH"))
#ifdef SQL_YEAR_TO_MONTH
	    return SQL_YEAR_TO_MONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_APPLICATION_CODEPAGE"))
#ifdef SQL_APPLICATION_CODEPAGE
	    return SQL_APPLICATION_CODEPAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CONNECT_CODEPAGE"))
#ifdef SQL_CONNECT_CODEPAGE
	    return SQL_CONNECT_CODEPAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATABASE_CODEPAGE"))
#ifdef SQL_DATABASE_CODEPAGE
	    return SQL_DATABASE_CODEPAGE;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "TRACE_VERSION"))
#ifdef TRACE_VERSION
	    return TRACE_VERSION;
#else
	    goto not_there;
#endif
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
    case '_':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = DBD::DB2::Constants		PACKAGE = DBD::DB2::Constants

char *
SQL_ALL_CATALOGS()

    CODE:
#ifdef SQL_ALL_CATALOGS
    RETVAL = SQL_ALL_CATALOGS;
#else
    croak("Your vendor has not defined the DBD::DB2::Constants macro SQL_ALL_CATALOGS");
#endif

    OUTPUT:
    RETVAL

char *
SQL_ALL_SCHEMAS()

    CODE:
#ifdef SQL_ALL_SCHEMAS
    RETVAL = SQL_ALL_SCHEMAS;
#else
    croak("Your vendor has not defined the DBD::DB2::Constants macro SQL_ALL_SCHEMAS");
#endif

    OUTPUT:
    RETVAL

char *
SQL_ALL_TABLE_TYPES()

    CODE:
#ifdef SQL_ALL_TABLE_TYPES
    RETVAL = SQL_ALL_TABLE_TYPES;
#else
    croak("Your vendor has not defined the DBD::DB2::Constants macro SQL_ALL_TABLE_TYPES");
#endif

    OUTPUT:
    RETVAL

char *
SQL_DATALINK_URL()

    CODE:
#ifdef SQL_DATALINK_URL
    RETVAL = SQL_DATALINK_URL;
#else
    croak("Your vendor has not defined the DBD::DB2::Constants macro SQL_DATALINK_URL");
#endif

    OUTPUT:
    RETVAL

char *
SQL_ODBC_KEYWORDS()

    CODE:
#ifdef SQL_ODBC_KEYWORDS
    RETVAL = SQL_ODBC_KEYWORDS;
#else
    croak("Your vendor has not defined the DBD::DB2::Constants macro SQL_ODBC_KEYWORDS");
#endif

    OUTPUT:
    RETVAL

char *
SQL_OPT_TRACE_FILE_DEFAULT()

    CODE:
#ifdef SQL_OPT_TRACE_FILE_DEFAULT
    RETVAL = SQL_OPT_TRACE_FILE_DEFAULT;
#else
    croak("Your vendor has not defined the DBD::DB2::Constants macro SQL_OPT_TRACE_FILE_DEFAULT");
#endif

    OUTPUT:
    RETVAL

char *
SQL_SPEC_STRING()

    CODE:
#ifdef SQL_SPEC_STRING
    RETVAL = SQL_SPEC_STRING;
#else
    croak("Your vendor has not defined the DBD::DB2::Constants macro SQL_SPEC_STRING");
#endif

    OUTPUT:
    RETVAL

PROTOTYPES:  DISABLE

double
constant(name,arg)
	char *		name
	int		arg

