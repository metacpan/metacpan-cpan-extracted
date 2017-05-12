 /*
 * $Id: DBMaker.h,v 0.13 1999/01/29 00:34:39 $
 * 
 * Copyright (c) 1999 DBMaker team
 * portions Copyright (c) 1994,1995,1996,1997  Tim Bunce
 * portions Copyright (c) 1997 Thomas K. Wenrich
 * portions Copyright (c) 1997 Jeff Urlwin
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 */

/****************************************************************************
 * Change History by DBMaker team:
 * #000 DBMaker 0.12a By Jackie
 * #001 99/08/25 phu: Fix cannot display real/float/double problem
 * #002 99/08/27 phu: Fix bind param and execute return truncate warning
 * #003 99/08/28 phu: Check if user has specify param type for bind_param
 * #004 99/09/02 phu: Add define DBMAKER_FILE_INOUT for input param
 *                    and output column by file and fix SQL_FILE in {TYPE}
 * #005 99/09/09 phu: reference Oracle about how to bind output parameter
 * #006 99/09/14 phu: allow use :c1 in prepare and use 'c1' in bind_param
 * #007 99/09/17 phu: refine file name add index when file name has '.' and
 *                    also fix when SQL_C_FILE, the return col len should
 *                    be strlen(fbh->data) not indicator value
 * #008 99/10/26 phu: fix for SQL_FILE type
 ****************************************************************************/
#include "DBMaker.h"

#define DESCRIBE_IN_PREPARE 1
	/* Fixes problem with bind_columns immediate after prepare,
	 * but breaks $sth->{blob_size} attribute.
 	 */

#define DBMAKER_FILE_INOUT 1      /* #004 */
#define MAX_FILE_NAME_LEN    80   /* #004 #008 */
#define MAX_DISPLAY_FILE_NUM 5    /* #004 (can be enlarge) */
#define MAX_FILE_EXTENSION_LEN 5  /* #007 */

typedef struct {
    const char *str;
    UWORD fOption;
    UDWORD true;
    UDWORD false;
} db_params;

typedef struct {
    const char *str;
    unsigned len:8;
    unsigned array:1;
    unsigned filler:23;
} T_st_params;

static const char *
S_SqlTypeToString (
    SWORD sqltype);
static const char *
S_SqlCTypeToString (
    SWORD sqltype);
static int 
S_IsFetchError(
	SV *sth, 
	RETCODE rc, 
        char *sqlstate,
	const void *par);

static const char *cSqlColumns = "SQLColumns(%s,%s,%s,%s)";
static const char *cSqlGetTypeInfo = "SQLGetTypeInfo(%d)";

/* for sanity/ease of use with potentially null strings */
#define XXSAFECHAR(p) ((p) ? (p) : "(null)")
	
DBISTATE_DECLARE;

void
dbd_init(dbistate)
    dbistate_t *dbistate;
{
    DBIS = dbistate;
    }

void
dbd_db_destroy(dbh)
    SV *dbh;
{
    D_imp_dbh(dbh);

    if (DBIc_ACTIVE(imp_dbh))
	{
	dbd_db_disconnect(dbh);
	}
    /* Nothing in imp_dbh to be freed	*/

    DBIc_IMPSET_off(imp_dbh);
}

/*------------------------------------------------------------
  connecting to a data source.
  Allocates henv and hdbc.
------------------------------------------------------------*/
int
dbd_db_login(dbh, dbname, uid, pwd)
    SV *dbh;
    char *dbname;
    char *uid;
    char *pwd;
{
    D_imp_dbh(dbh);
    D_imp_drh_from_dbh;
    int ret;

    RETCODE rc;
    static int s_first = 1;

    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "%s connect '%s', '%s', '%s'\n",
		s_first ? "FIRST" : "not first", 
		dbname, uid, pwd);


    if (s_first)
	{
	s_first = 0;
	imp_drh->connects = 0;
	imp_drh->henv = SQL_NULL_HENV;
	}

    if (!imp_drh->connects)
	{
	rc = SQLAllocEnv(&imp_drh->henv);
	dbmaker_error(dbh, rc, "db_login/SQLAllocEnv");
	if (rc != SQL_SUCCESS)
	    {
	    return 0;
	    }
	}

    rc = SQLAllocConnect(imp_drh->henv, &imp_dbh->hdbc);
    dbmaker_error(dbh, rc, "db_login/SQLAllocConnect");
    if (rc != SQL_SUCCESS)
	{
	if (imp_drh->connects == 0)
	    {
	    SQLFreeEnv(imp_drh->henv);
	    imp_drh->henv = SQL_NULL_HENV;
	    }
	return 0;
	}

    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "connect '%s', '%s', '%s'",
		dbname, uid, pwd);
    rc = SQLConnect(imp_dbh->hdbc,
		    dbname, strlen(dbname),
		    uid, strlen(uid),
		    pwd, strlen(pwd));

    dbmaker_error(dbh, rc, "db_login/SQLConnect");
    if (rc != SQL_SUCCESS)
	{
	SQLFreeConnect(imp_dbh->hdbc);
	if (imp_drh->connects == 0)
	    {
	    SQLFreeEnv(imp_drh->henv);
	    imp_drh->henv = SQL_NULL_HENV;
	    }
	return 0;
	}

    /* DBI spec requires AutoCommit on
     */
    rc = SQLSetConnectOption(imp_dbh->hdbc, 
    			     SQL_AUTOCOMMIT, 
			     SQL_AUTOCOMMIT_ON);
    dbmaker_error(dbh, rc, "dbd_db_login/SQLSetConnectOption");
    if (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO)
    	{
	DBIc_on(imp_dbh, DBIcf_AutoCommit);
	}
	
#if DBMAKER_FILE_INOUT          /* #004 */
    rc = SQLSetConnectOption(imp_dbh->hdbc, SQL_FO_TO_SQLTYPE, SQL_FO_FILE);
    dbmaker_error(dbh, rc, "dbd_db_login/SQLSetConnectOption");
    if (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO)
       { 
       DBIc_on(imp_dbh, DBIcf_AutoCommit);
       }
#endif    	

    /* set DBI spec (0.87) defaults 
     */
    DBIc_LongReadLen(imp_dbh) = 80;
    DBIc_set(imp_dbh, DBIcf_LongTruncOk, 1);
    
    imp_drh->connects++;
    DBIc_IMPSET_on(imp_dbh);	/* imp_dbh set up now			*/
    DBIc_ACTIVE_on(imp_dbh);	/* call disconnect before freeing	*/
    return 1;
}

int
dbd_db_disconnect(dbh)
    SV *dbh;
{
    RETCODE rc;
    D_imp_dbh(dbh);
    D_imp_drh_from_dbh;

    /* We assume that disconnect will always work	*/
    /* since most errors imply already disconnected.	*/
    DBIc_ACTIVE_off(imp_dbh);

    /* DBI spec: rolling back or committing depends
     * on AutoCommit attribute
     */
#ifdef SOL22_AUTOCOMMIT_BUG
    rc = SQLTransact(imp_drh->henv, 
		     imp_dbh->hdbc,
		     DBIc_is(imp_dbh, DBIcf_AutoCommit) 
		     	? SQL_COMMIT : SQL_ROLLBACK);
    dbmaker_error(dbh, rc, "db_disconnect/SQLTransact");
#else
    rc = SQLTransact(imp_drh->henv, 
		     imp_dbh->hdbc,
		     SQL_ROLLBACK);
    dbmaker_error(dbh, rc, "db_disconnect/SQLTransact");
#endif
    rc = SQLDisconnect(imp_dbh->hdbc);
    dbmaker_error(dbh, rc, "db_disconnect/SQLDisconnect");
    if (rc != SQL_SUCCESS)
	{
	return 0;
	}
    SQLFreeConnect(imp_dbh->hdbc);
    imp_dbh->hdbc = SQL_NULL_HDBC;
    imp_drh->connects--;
    if (imp_drh->connects == 0)
	{
	SQLFreeEnv(imp_drh->henv);
	}
    /* We don't free imp_dbh since a reference still exists	*/
    /* The DESTROY method is the only one to 'free' memory.	*/
    /* Note that statement objects may still exists for this dbh!	*/

    return 1;
    }

int
dbd_db_commit(dbh)
    SV *dbh;
{
    D_imp_dbh(dbh);
    D_imp_drh_from_dbh;
    RETCODE rc;

    rc = SQLTransact(imp_drh->henv, 
		     imp_dbh->hdbc,
		     SQL_COMMIT);
    dbmaker_error(dbh, rc, "db_commit/SQLTransact");
    if (rc != SQL_SUCCESS)
	{
	return 0;
	}
    return 1;
}

int
dbd_db_rollback(dbh)
    SV *dbh;
{
    D_imp_dbh(dbh);
    D_imp_drh_from_dbh;
    RETCODE rc;

    rc = SQLTransact(imp_drh->henv, 
		     imp_dbh->hdbc,
		     SQL_ROLLBACK);
    dbmaker_error(dbh, rc, "db_rollback/SQLTransact");
    if (rc != SQL_SUCCESS)
	{
	return 0;
	}
    return 1;
}

/*------------------------------------------------------------
  replacement for ora_error.
  empties entire ODBC error queue.
------------------------------------------------------------*/
const char *
dbmaker_error5(
    SV *h, 
    RETCODE badrc, 
    char *what, 
    T_IsAnError func, 
    const void *par)
{
    D_imp_xxh(h);

    struct imp_drh_st *drh = NULL;
    struct imp_dbh_st *dbh = NULL;
    struct imp_sth_st *sth = NULL;
    HENV henv = SQL_NULL_HENV;
    HDBC hdbc = SQL_NULL_HDBC;
    HSTMT hstmt = SQL_NULL_HSTMT;

    int i = 2;			/* 2..0 hstmt..henv */

    SDWORD NativeError;
    UCHAR ErrorMsg[SQL_MAX_MESSAGE_LENGTH];
    SWORD ErrorMsgMax = sizeof(ErrorMsg)-1;
    SWORD ErrorMsgLen;
    UCHAR sqlstate[10];
    STRLEN len;

    SV *errstr = DBIc_ERRSTR(imp_xxh);

    sv_setpvn(errstr, ErrorMsg, 0);
    sv_setiv(DBIc_ERR(imp_xxh), (IV)badrc);
    /* 
     * sqlstate isn't set for SQL_NO_DATA returns.
     */
    strcpy(sqlstate, "00000");
    sv_setpvn(DBIc_STATE(imp_xxh), sqlstate, 5);
    
    switch(DBIc_TYPE(imp_xxh))
	{
	case DBIt_DR:
	    drh = (struct imp_drh_st *)(imp_xxh);
	    break;
	case DBIt_DB:
	    dbh = (struct imp_dbh_st *)(imp_xxh);
	    drh = (struct imp_drh_st *)(DBIc_PARENT_COM(dbh));
	    break;
	case DBIt_ST:
	    sth = (struct imp_sth_st *)(imp_xxh);
	    dbh = (struct imp_dbh_st *)(DBIc_PARENT_COM(sth));
	    drh = (struct imp_drh_st *)(DBIc_PARENT_COM(dbh));
	    break;
	}

    if (sth != NULL) hstmt = sth->hstmt;
    if (dbh != NULL) hdbc = dbh->hdbc;
    if (drh != NULL) henv = drh->henv;

    while (i >= 0)
	{
	RETCODE rc = 0;
	if (dbis->debug >= 3)
	    fprintf(DBILOGFP, "dbmaker_error: badrc=%d rc=%d i=%d hstmt %d hdbc %d henv %d\n", 
	       badrc, rc, i,
	       hstmt, hdbc, henv);
	switch(i--)
	    {
	    case 2:
		if (hstmt == SQL_NULL_HSTMT)
		    continue;
		break;
	    case 1:
		hstmt = SQL_NULL_HSTMT;
		if (hdbc == SQL_NULL_HDBC)
		    continue;
		break;
	    case 0:
		hdbc = SQL_NULL_HDBC;
		if (henv == SQL_NULL_HENV)
		    continue;
		break;
	    }
	do  
	    {
	    rc = SQLError(henv, hdbc, hstmt,
			  sqlstate,
			  &NativeError,
			  ErrorMsg,
			  ErrorMsgMax,
			  &ErrorMsgLen);
	    if (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO)
		{
		sv_catpvn(errstr, ErrorMsg, ErrorMsgLen);
		sv_catpv(errstr, "\n");

		sv_catpv(errstr, "(SQL-");
		sv_catpv(errstr, sqlstate);
		sv_catpv(errstr, ")\n");
		sv_setpvn(DBIc_STATE(imp_xxh), sqlstate, 5);
		if (dbis->debug >= 3)
	    	    fprintf(DBILOGFP, 
		        "dbmaker_error values: sqlstate %0.5s rc = %u: %s\n",
				sqlstate, NativeError, ErrorMsg); 
	        if (NativeError != 0)	/* set to real error */
	            sv_setiv(DBIc_ERR(imp_xxh), (IV)NativeError);
		}
	    }
	while (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO);
	}

    if (badrc != SQL_SUCCESS && what) 
	{
	sv_catpv(errstr, "(DBD: ");
	sv_catpv(errstr, what);
	sprintf(ErrorMsg, " rc=%d", badrc);
	sv_catpv(errstr, ErrorMsg);
	sv_catpv(errstr, ")");
	}
    if (badrc != SQL_SUCCESS)
	{
	if (func == NULL 
	    || (*func)(h, badrc, SvPV(DBIc_STATE(imp_xxh), len), par) != 0)
	    {
	    DBIh_EVENT2(h, ERROR_event, DBIc_ERR(imp_xxh), errstr);
	    if (dbis->debug >= 2)
	        fprintf(DBILOGFP, 
		    "%s badrc %d recorded: %s\n",
		    what, badrc, SvPV(errstr,na));
	    }
        else
	    {
    	    sv_setiv(DBIc_ERR(imp_xxh), (IV)0);
	    }
	}
    return SvPV(DBIc_STATE(imp_xxh), len);
    }

/*-------------------------------------------------------------------------
dbd_preparse: 
- scan for placeholders (? and :xx style) and convert them to ?.
- builds translation table to convert positional parameters of the 
execute() call to :nn type placeholders.
We need two data structures to translate this stuff:
- a hash to convert positional parameters to placeholders
- an array, representing the actual '?' query parameters.
%param = (name1=>plh1, name2=>plh2, ..., name_n=>plh_n)   #
@qm_param = (\$param{'name1'}, \$param{'name2'}, ...) 
-------------------------------------------------------------------------*/
void
   dbd_preparse(imp_sth, statement)
   imp_sth_t *imp_sth;
char *statement;
{
    dTHR;
    bool in_literal = FALSE;
    char *src, *start, *dest;
    phs_t phs_tpl, *phs;
    SV *phs_sv;
    int idx=0, style=0, laststyle=0;
    int param = 0;
    STRLEN namelen;
    char name[256];
    SV **svpp;
    char ch;

    /* allocate room for copy of statement with spare capacity	*/
    imp_sth->statement = (char*)safemalloc(strlen(statement)+1);

    /* initialize phs ready to be cloned per placeholder	*/
    memset(&phs_tpl, 0, sizeof(phs_tpl));
    phs_tpl.ftype = 1;	/* VARCHAR2 */
    phs_tpl.sv = &sv_undef;

    src  = statement;
    dest = imp_sth->statement;
    while(*src) {
	if (*src == '\'')
	    in_literal = ~in_literal;
	if ((*src != ':' && *src != '?') || in_literal) {
	    *dest++ = *src++;
	    continue;
	}
	start = dest;			/* save name inc colon	*/ 
	ch = *src++;
	if (ch == '?') {                /* X/Open standard	*/ 
	    idx++;
	    sprintf(name, "%d", idx);
	    *dest++ = ch;
	    style = 3;
	}
	else if (isDIGIT(*src)) {       /* ':1'		*/
	    char *p = name;
	    *dest++ = '?';
	    idx = atoi(src);
	    while(isDIGIT(*src))
		*p++ = *src++;
	    *p = 0;
	    style = 1;
	} 
	else if (isALNUM(*src)) {       /* ':foo'	*/
	    char *p = name;
	    idx++;                      /* #006 */
	    *dest++ = '?';

	    while(isALNUM(*src))	/* includes '_'	*/
		*p++ = *src++;
	    *p = 0;
	    style = 2;
	} 
	else {			/* perhaps ':=' PL/SQL construct */
	    *dest++ = ch;
	    continue;
	}
	*dest = '\0';			/* handy for debugging	*/
	if (laststyle && style != laststyle)
	    croak("Can't mix placeholder styles (%d/%d)",style,laststyle);
	laststyle = style;

	if (imp_sth->params_hv == NULL)
	    imp_sth->params_hv = newHV();
	namelen = strlen(name);

	svpp = hv_fetch(imp_sth->params_hv, name, namelen, 0);
	
	if (svpp == NULL) {
	    /* create SV holding the placeholder */
	    phs_sv = newSVpv((char*)&phs_tpl, sizeof(phs_tpl)+namelen+1);
	    phs = (phs_t*)SvPVX(phs_sv);
	    strcpy(phs->name, name);
	    phs->idx = idx;
	    /* store placeholder to params_hv */
	    svpp = hv_store(imp_sth->params_hv, name, namelen, phs_sv, 0);
	}
    }
    *dest = '\0';
    if (imp_sth->params_hv) {
	DBIc_NUM_PARAMS(imp_sth) = (int)HvKEYS(imp_sth->params_hv);
	if (DBIS->debug >= 2)
	    fprintf(DBILOGFP, "    dbd_preparse scanned %d distinct placeholders\n",
		    (int)DBIc_NUM_PARAMS(imp_sth));
    }
}


int
dbd_st_table_info(dbh, sth, qualifier, table_type)
    SV *dbh;
    SV *sth;
    char *qualifier;
    char *table_type;
{
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;
    SV **svp;
    char cname[128];				/* cursorname */

    imp_sth->done_desc = 0;
    rc = SQLAllocStmt(imp_dbh->hdbc, &imp_sth->hstmt);
    dbmaker_error(sth, rc, "st_tables/SQLAllocStmt");
    if (rc != SQL_SUCCESS) {
	return 0;
    }

    /* just for sanity, later.  Any internals that may rely on this (including */
    /* debugging) will have valid data */
    imp_sth->statement = (char *)safemalloc(strlen("SQLTables(%s)")+strlen(qualifier)+1);
    sprintf(imp_sth->statement, "SQLTables(%s)", qualifier);

    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "    dbd_st_tables type = %s\n", table_type);

    rc = SQLTables(imp_sth->hstmt,
	   0, SQL_NTS,			/* qualifier */
	   0, SQL_NTS,			/* schema/user */
	   0, SQL_NTS,			/* table name */
	   table_type, SQL_NTS	/* type (view, table, etc) */
    );
    
    dbmaker_error(sth, rc, "st_tables/SQLTables");
    if (!SQL_ok(rc)) {
	SQLFreeStmt(imp_sth->hstmt, SQL_DROP);
	imp_sth->hstmt = SQL_NULL_HSTMT;
	return 0;
    }

    /* init sth pointers */
    imp_sth->fbh = NULL;
    imp_sth->ColNames = NULL;
    imp_sth->RowBuffer = NULL;
    imp_sth->RowCount = -1;
    imp_sth->eod = -1;
#if DBMAKER_FILE_INOUT    /* #004 */  
    imp_sth->fgfileinput = 1;
    imp_sth->fgBindColToFile = 0;
#else
    imp_sth->fgfileinput = 0;
    imp_sth->fgBindColToFile = 0; 
#endif    

    if (!dbd_describe(sth, imp_sth))
    {
	    SQLFreeStmt(imp_sth->hstmt, SQL_DROP);
	    imp_sth->hstmt = SQL_NULL_HSTMT;
	    return 0; 		/* dbd_describe already called ora_error() */
    }

    if (dbd_describe(sth, imp_sth) <= 0)
	return 0;

    DBIc_IMPSET_on(imp_sth);

    imp_sth->RowCount = -1;
    rc = SQLRowCount(imp_sth->hstmt, &imp_sth->RowCount);
    dbmaker_error(sth, rc, "st_tables/SQLRowCount");
    if (rc != SQL_SUCCESS) {
	return -1;
    }

    DBIc_ACTIVE_on(imp_sth); /* XXX should only set for select ?	*/
    imp_sth->eod = SQL_SUCCESS;
    return 1;
}

int
dbd_st_prepare(sth, statement, attribs)
    SV *sth;
    char *statement;
    SV *attribs;
{
    D_imp_sth(sth);
    D_imp_dbh_from_sth;
    RETCODE rc;
    SV **svp;
    char cname[128];		/* cursorname */

    imp_sth->done_desc = 0;

    rc = SQLAllocStmt(imp_dbh->hdbc, &imp_sth->hstmt);
    dbmaker_error(sth, rc, "st_prepare/SQLAllocStmt");
    if (rc != SQL_SUCCESS)
	{
	return 0;
	}

    /* scan statement for '?', ':1' and/or ':foo' style placeholders	*/
    dbd_preparse(imp_sth, statement);

    /* parse the (possibly edited) SQL statement */

    rc = SQLPrepare(imp_sth->hstmt, 
		    imp_sth->statement,
		    strlen(imp_sth->statement));
    dbmaker_error(sth, rc, "st_prepare/SQLPrepare");
    if (rc != SQL_SUCCESS)
        {
	SQLFreeStmt(imp_sth->hstmt, SQL_DROP);
	imp_sth->hstmt = SQL_NULL_HSTMT;
	return 0;
	}

    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "    dbd_st_prepare'd sql f%d\n\t%s\n",
		imp_sth->hstmt, imp_sth->statement);

    /* init sth pointers */
    imp_sth->fbh = NULL;
    imp_sth->ColNames = NULL;
    imp_sth->RowBuffer = NULL;
    imp_sth->n_result_cols = -1;
    imp_sth->RowCount = -1;
    imp_sth->eod = -1;
#if DBMAKER_FILE_INOUT    /* #004 */  
    imp_sth->fgfileinput = 1;
    imp_sth->fgBindColToFile = 0;
#else
    imp_sth->fgfileinput = 0;
    imp_sth->fgBindColToFile = 0; 
#endif    

    /* @@@ DBI Bug ??? */
    DBIc_set(imp_sth, DBIcf_LongTruncOk,
    	     DBIc_is(imp_dbh, DBIcf_LongTruncOk));
    DBIc_LongReadLen(imp_sth) = DBIc_LongReadLen(imp_dbh);

    if (attribs)
	{
	if ((svp=hv_fetch((HV*)SvRV(attribs), "blob_size",9, 0)) != NULL)
	    {
	    int len = SvIV(*svp);
	    DBIc_LongReadLen(imp_sth) = len;
	    if (DBIc_WARN(imp_sth))
	    	warn("depreciated feature: blob_size will be replaced by LongReadLen\n");
	    }
	if ((svp=hv_fetch((HV*)SvRV(attribs), "dbmaker_blob_size",15, 0)) != NULL)
	    {
	    int len = SvIV(*svp);
	    DBIc_LongReadLen(imp_sth) = len;
	    if (DBIc_WARN(imp_sth))
	    	warn("depreciated feature: dbmaker_blob_size will be replaced by LongReadLen\n");
	    }
	if ((svp=hv_fetch((HV*)SvRV(attribs), "LongReadLen",11, 0)) != NULL)
	    {
	    int len = SvIV(*svp);
	    DBIc_LongReadLen(imp_sth) = len;
	    }
	}

#if DESCRIBE_IN_PREPARE
    if (dbd_describe(sth, imp_sth) <= 0)
	return 0;
#endif

    DBIc_IMPSET_on(imp_sth);
    return 1;
    }

int 
dbtype_is_string(int bind_type)
{
    switch(bind_type)
	{
	case SQL_C_CHAR:
	case SQL_C_BINARY:
	    return 1;
	}
    return 0;
    }    


static const char *
S_SqlTypeToString (SWORD sqltype)
{
    switch(sqltype)
	{
	case SQL_CHAR: return "CHAR";
	case SQL_NUMERIC: return "NUMERIC";
	case SQL_DECIMAL: return "DECIMAL";
	case SQL_INTEGER: return "INTEGER";
	case SQL_SMALLINT: return "SMALLINT";
	case SQL_FLOAT: return "FLOAT";
	case SQL_REAL: return "REAL";
	case SQL_DOUBLE: return "DOUBLE";
	case SQL_VARCHAR: return "VARCHAR";
	case SQL_DATE: return "DATE";
	case SQL_TIME: return "TIME";
	case SQL_TIMESTAMP: return "TIMESTAMP";
	case SQL_LONGVARCHAR: return "LONG VARCHAR";
	case SQL_BINARY: return "BINARY";
	case SQL_VARBINARY: return "VARBINARY";
	case SQL_LONGVARBINARY: return "LONG VARBINARY";
	case SQL_BIGINT: return "BIGINT";
	case SQL_TINYINT: return "TINYINT";
	case SQL_BIT: return "BIT";
	}
    return "unknown";
    }
static const char *
S_SqlCTypeToString (SWORD sqltype)
{
static char s_buf[100];
#define s_c(x) case x: return #x
    switch(sqltype)
	{
	s_c(SQL_C_CHAR);
	s_c(SQL_C_BIT);
	s_c(SQL_C_STINYINT);
	s_c(SQL_C_UTINYINT);
	s_c(SQL_C_SSHORT);
	s_c(SQL_C_USHORT);
	s_c(SQL_C_FLOAT);
	s_c(SQL_C_DOUBLE);
	s_c(SQL_C_BINARY);
	s_c(SQL_C_DATE);
	s_c(SQL_C_TIME);
	s_c(SQL_C_TIMESTAMP);
	}
#undef s_c
    sprintf(s_buf, "(unknown CType %d)", sqltype);
    return s_buf;
    }
    
/*
 * describes the output variables of a query,
 * allocates buffers for result rows,
 * and binds this buffers to the statement.
 */
int
dbd_describe(h, imp_sth)
    SV *h;
    imp_sth_t *imp_sth;
{
    RETCODE rc;

    UCHAR *cbuf_ptr;		
    UCHAR *rbuf_ptr;		

    int t_cbufl=0;		/* length of all column names */
    int i;
    imp_fbh_t *fbh;
    int t_dbsize = 0;		/* size of native type */
    int t_dsize = 0;		/* display size */

    if (imp_sth->done_desc)
	return 1;	/* success, already done it */
    imp_sth->done_desc = 1;

    rc = SQLNumResultCols(imp_sth->hstmt, &imp_sth->n_result_cols);
    dbmaker_error(h, rc, "dbd_describe/SQLNumResultCols");
    if (rc != SQL_SUCCESS)
	{
	return 0;
	}

    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "    dbd_describe sql %d: n_result_cols=%d\n",
		imp_sth->hstmt,
		imp_sth->n_result_cols);

    DBIc_NUM_FIELDS(imp_sth) = imp_sth->n_result_cols;

    if (imp_sth->n_result_cols == 0) 
	{
	if (dbis->debug >= 2)
	    fprintf(DBILOGFP, "\tdbd_describe skipped (no result cols) (sql f%d)\n",
		    imp_sth->hstmt);
	return 1;
	}

    /* allocate field buffers				*/
    Newz(42, imp_sth->fbh, imp_sth->n_result_cols, imp_fbh_t);

    /* Pass 1: Get space needed for field names, display buffer and dbuf */
    for (fbh=imp_sth->fbh, i=0; 
	 i<imp_sth->n_result_cols; 
	 i++, fbh++)
	{
	UCHAR ColName[256];

	rc = SQLDescribeCol(imp_sth->hstmt, 
			    i+1, 
			    ColName,
			    sizeof(ColName),	/* max col name length */
			    &fbh->ColNameLen,
			    &fbh->ColSqlType,
			    &fbh->ColDef,
			    &fbh->ColScale,
			    &fbh->ColNullable);
	/* long crash-me columns
 	 * get SUCCESS_WITH_INFO due to ColName truncation 
	 */
        if (rc != SQL_SUCCESS)
	    dbmaker_error5(h, rc, "describe pass 1/SQLDescribeCol",
		     	 S_IsFetchError, &rc);
        if (rc != SQL_SUCCESS)
	    return 0;

	if (fbh->ColNameLen >= sizeof(ColName))
	    ColName[sizeof(ColName)-1] = 0;
	else
	    ColName[fbh->ColNameLen] = 0;


	t_cbufl  += fbh->ColNameLen;

	rc = SQLColAttributes(imp_sth->hstmt,i+1,SQL_COLUMN_DISPLAY_SIZE,
                                NULL, 0, NULL ,&fbh->ColDisplaySize);
        if (rc != SQL_SUCCESS)
	    {
	    dbmaker_error(h, rc, 
			"describe pass 1/SQLColAttributes(DISPLAY_SIZE)");
	    return 0;
	    }
	fbh->ColDisplaySize += 1; /* add terminator */

	rc = SQLColAttributes(imp_sth->hstmt,i+1,SQL_COLUMN_LENGTH,
                                NULL, 0, NULL ,&fbh->ColLength);
        if (rc != SQL_SUCCESS)
	    {
	    dbmaker_error(h, rc, 
			"describe pass 1/SQLColAttributes(COLUMN_LENGTH)");
	    return 0;
	    }

	/* change fetched size for some types
	 */
	fbh->ftype = SQL_C_CHAR;
	
	switch(fbh->ColSqlType)
	    {
	    case SQL_BINARY:
	    case SQL_VARBINARY:
		fbh->ColDisplaySize = fbh->ColLength;
		fbh->ftype = SQL_C_BINARY;
		break;
	    case SQL_LONGVARBINARY:
		fbh->ftype = SQL_C_BINARY;
		fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth);
		break;
	    case SQL_LONGVARCHAR:
		fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth) + 1;
		break;
	    case SQL_TIMESTAMP:
		fbh->ftype = SQL_C_TIMESTAMP;
		fbh->ColDisplaySize = sizeof(TIMESTAMP_STRUCT);
		break;
        case SQL_FLOAT:      /* #001 fix cannot display max float/double */
        case SQL_REAL:
		fbh->ftype = SQL_C_FLOAT;
		fbh->ColDisplaySize = fbh->ColLength;
		break;
        case SQL_DOUBLE:
		fbh->ftype = SQL_C_DOUBLE; /* #001 */
		fbh->ColDisplaySize = fbh->ColLength;
		break;        
        case SQL_FILE: /* #004 */
        fbh->ftype = SQL_C_BINARY;
        fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth);
        break;
	    }
	if (fbh->ftype != SQL_C_CHAR)
	    {
        /* alignment */
        t_dbsize +=
               (sizeof(int) - (t_dbsize % sizeof(int))) % sizeof(int);
/*	    t_dbsize += t_dbsize % sizeof(int);*/     /* alignment */
	    }
	t_dbsize += fbh->ColDisplaySize;

	if (dbis->debug >= 2)
	    fprintf(DBILOGFP, 
		    "\tdbd_describe: col %d: %s, Length=%d"
		    "\t\tDisp=%d, Prec=%d Scale=%d\n", 
		    i+1, S_SqlTypeToString(fbh->ColSqlType),
		    fbh->ColLength, fbh->ColDisplaySize,
		    fbh->ColDef, fbh->ColScale
		    );
	}

    /* allocate a buffer to hold all the column names	*/
    Newz(42, imp_sth->ColNames, t_cbufl + imp_sth->n_result_cols, UCHAR);
    /* allocate Row memory */
    Newz(42, imp_sth->RowBuffer, t_dbsize + imp_sth->n_result_cols, UCHAR);

    /* Second pass:
       - get column names
       - bind column output
     */

    cbuf_ptr = imp_sth->ColNames;
    rbuf_ptr = imp_sth->RowBuffer;

    for(i=0, fbh = imp_sth->fbh; 
	i < imp_sth->n_result_cols 
	&& rc == SQL_SUCCESS; 
	i++, fbh++)
	{
	int dbtype;
	int offset;

	switch(fbh->ftype)
	    {
	    case SQL_C_BINARY:
	    case SQL_C_TIMESTAMP:
	    case SQL_C_FLOAT:  /* #001 */
	    case SQL_C_DOUBLE: /* #001 */
/*		rbuf_ptr += (rbuf_ptr - imp_sth->RowBuffer) % sizeof(int);*/
               offset = (rbuf_ptr - imp_sth->RowBuffer);
               rbuf_ptr +=
                 (sizeof(int) - (offset % sizeof(int))) % sizeof(int);
		break;
	    }


	rc = SQLDescribeCol(imp_sth->hstmt, 
			    i+1, 
			    cbuf_ptr,
			    fbh->ColNameLen+1,	/* max size from first call */
			    &fbh->ColNameLen,
			    &fbh->ColSqlType,
			    &fbh->ColDef,
			    &fbh->ColScale,
			    &fbh->ColNullable);
        if (rc != SQL_SUCCESS)
	    {
	    dbmaker_error(h, rc, 
			"describe pass 2/SQLDescribeCol");
	    return 0;
	    }
	
	fbh->ColName = cbuf_ptr;
	cbuf_ptr[fbh->ColNameLen] = 0;
	cbuf_ptr += fbh->ColNameLen+1;

	switch(fbh->ColSqlType)				/* #000 */
	    {
	    case SQL_LONGVARCHAR:
	    case SQL_LONGVARBINARY:
		if (DBIc_LongReadLen(imp_sth) == 0)
		   rbuf_ptr = 0;
		break;
	    }
	fbh->data = rbuf_ptr;
	rbuf_ptr += fbh->ColDisplaySize;

	/* Bind output column variables */
	rc = SQLBindCol(imp_sth->hstmt,
			i+1,
			fbh->ftype,
			fbh->data,
			fbh->ColDisplaySize,
			&fbh->datalen);
	if (dbis->debug >= 2)
	    fprintf(DBILOGFP, 
		    "\tdescribe/BindCol: col#%d-%s:\n\t\t"
		    "sqltype=%s, ctype=%s, maxlen=%d\n",
		    i+1, fbh->ColName,
		    S_SqlTypeToString(fbh->ColSqlType),
		    S_SqlCTypeToString(fbh->ftype),
		    fbh->ColDisplaySize
		    );
	if (rc != SQL_SUCCESS)
	    {
	    dbmaker_error(h, rc, "describe/SQLBindCol");
	    return 0;
	    }
	} /* end pass 2 */

    if (rc != SQL_SUCCESS)
	{
	warn("can't bind column %d (%s)",
	     i+1, fbh->ColName);
	return 0;
	}
    return 1;
    }

int
dbd_st_execute(sth)	/* <0 is error, >=0 is ok (row count) */
    SV *sth;
{
    D_imp_sth(sth);
    RETCODE rc;
    int debug = dbis->debug;
    int outparams = (imp_sth->params_av) ? AvFILL(imp_sth->params_av)+1 : 0; 

    /* allow multiple execute() without close() 
     * for one statement
     */
    if (DBIc_ACTIVE(imp_sth))
	{
	rc = SQLFreeStmt(imp_sth->hstmt, SQL_CLOSE);
	dbmaker_error(sth, rc, "st_execute/SQLFreeStmt(SQL_CLOSE)");
	}

    if (!imp_sth->done_desc) 
	{
	/* describe and allocate storage for results (if any needed)	*/
	if (!dbd_describe(sth, imp_sth))
	    return -1; /* dbd_describe already called ora_error()	*/
	}

    /* bind input parameters */

    if (debug >= 2)
	fprintf(DBILOGFP,
	    "    dbd_st_execute (for sql f%d after)...\n",
			imp_sth->hstmt);

    rc = SQLExecute(imp_sth->hstmt);
    dbmaker_error(sth, rc, "st_execute/SQLExecute");
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) /* #002 */
	{
	return -1;
	}
    imp_sth->RowCount = -1;
    rc = SQLRowCount(imp_sth->hstmt, &imp_sth->RowCount);
    dbmaker_error(sth, rc, "st_execute/SQLRowCount");
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) /* #002 */
	{
	return -1;
	}
       
    if (imp_sth->n_result_cols > 0)	
    	{
        /* @@@ assume only SELECT returns columns */
	DBIc_ACTIVE_on(imp_sth);
	}
    imp_sth->eod = SQL_SUCCESS;

    if (outparams) {	/* check validity of bound output SV's	#005 refer oracle */
	int i = outparams;
	while(--i >= 0) {
	    phs_t *phs = (phs_t*)(void*)SvPVX(AvARRAY(imp_sth->params_av)[i]);
	    SV *sv = phs->sv;

	    if (phs->cbValue >= 0)  /* is OK */
	       {		
	       if (phs->cbValue < phs->maxlen) 
	          {
              SvPOK_only(sv);
              SvCUR(sv) = phs->cbValue;
              *SvEND(sv) = '\0';
              }
           else  /* truncated ? */
              {
              SvPOK_only(sv);
              SvCUR(sv) = phs->maxlen;
              *SvEND(sv) = '\0';              
              }
      	   if (debug >= 2)
		   fprintf(DBILOGFP,
               "       out %s = '%s'\n",phs->name, SvPV(sv,na));
           }
	    else
	       {  /* NULL? SQL_NULL_DATA */
           (void)SvOK_off(phs->sv);
            if (debug >= 2)
               fprintf(DBILOGFP, "      %s out is null\n",phs->name);
            }
	}
    }    
    
    return 1;
    }

/*
 * Decide whether dbmaker_error should set error for DBI
 * SQL_NO_DATA_FOUND is never an error.
 * SUCCESS_WITH_INFO errors depend on some other conditions.
 *	
 */
static int 
S_IsFetchError(
	SV *sth, 
	RETCODE rc, 
        char *sqlstate,
	const void *par)
    {
    D_imp_sth(sth);

    if (rc == SQL_SUCCESS_WITH_INFO)
        {
	if (strEQ(sqlstate, "01004")) /* data truncated */
	    { 
	    /* without par: error when LongTruncOk is false */
	    if (par == NULL)
	        return DBIc_is(imp_sth, DBIcf_LongTruncOk) == 0;
	    /* with par: is always OK, *par gets SQL_SUCCESS */
	    *(RETCODE *)par = SQL_SUCCESS;
	    return 0;
	    }
	}
    else if (rc == SQL_NO_DATA_FOUND)
        {
	return 0;
	}

    return 1;
    }
/*----------------------------------------
 * running $sth->fetchrow()
 *----------------------------------------
 */
AV *
dbd_st_fetch(sth)
    SV *	sth;
{
    D_imp_sth(sth);
    int debug = dbis->debug;
    int i;
    AV *av;
    RETCODE rc;
    int num_fields;
    char cvbuf[512];
    char *p;
    int LongTruncOk = DBIc_is(imp_sth, DBIcf_LongTruncOk);
    int warn_flag = DBIc_is(imp_sth, DBIcf_WARN);
    const char *sqlstate = NULL;


    /* Check that execute() was executed sucessfully. This also implies	*/
    /* that dbd_describe() executed sucessfuly so the memory buffers	*/
    /* are allocated and bound.						*/
    if ( !DBIc_ACTIVE(imp_sth) ) 
	{
	dbmaker_error(sth, 0, "no statement executing");
	return Nullav;
	}
    
    
    rc = SQLFetch(imp_sth->hstmt);
    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "SQLFetch() returns %d\n", rc);
    switch(rc)
	{
	case SQL_SUCCESS:
	    imp_sth->eod = rc;
	    break;
	case SQL_SUCCESS_WITH_INFO:
            sqlstate = dbmaker_error5(sth, rc, "st_fetch/SQLFetch", 
				    S_IsFetchError, NULL);
	    imp_sth->eod = SQL_SUCCESS;
	    break;
	case SQL_NO_DATA_FOUND:
	    imp_sth->eod = rc;
            sqlstate = dbmaker_error5(sth, rc, "st_fetch/SQLFetch",
				    S_IsFetchError, NULL);
	    return Nullav;
	default:
            dbmaker_error(sth, rc, "st_fetch/SQLFetch");
	    return Nullav;
	}

    if (imp_sth->RowCount == -1)
	imp_sth->RowCount = 0;

    imp_sth->RowCount++;

    av = DBIS->get_fbav(imp_sth);
    num_fields = AvFILL(av)+1;	/* ??? */

    for(i=0; i < num_fields; ++i) 
	{
	imp_fbh_t *fbh = &imp_sth->fbh[i];
	SV *sv = AvARRAY(av)[i]; /* Note: we (re)use the SV in the AV	*/

        if (dbis->debug >= 4)
	    fprintf(DBILOGFP, "fetch col#%d %s datalen=%d displ=%d\n",
		i, fbh->ColName, fbh->datalen, fbh->ColDisplaySize);
	if (fbh->datalen != SQL_NULL_DATA) 
	    {			/* the normal case		*/
	    TIMESTAMP_STRUCT *ts = (TIMESTAMP_STRUCT *)fbh->data;

	    if (fbh->datalen > fbh->ColDisplaySize)
	    	{ 
		/* truncated LONG ??? */
	        sv_setpvn(sv, (char*)fbh->data, fbh->ColDisplaySize);
		if (!LongTruncOk && warn_flag)
		    {
		    warn("column %d: value truncated", i+1);
		    }
	    	}
	    else switch(fbh->ftype)
	    	{
		case SQL_C_TIMESTAMP:
		    sprintf(cvbuf, "%04d-%02d-%02d %02d:%02d:%02d",
			    ts->year, ts->month, ts->day, 
			    ts->hour, ts->minute, ts->second,
			    ts->fraction);
		    sv_setpv(sv, cvbuf);
		    break;
		case SQL_C_FLOAT:  /* #001 */
		case SQL_C_DOUBLE: /* #001 */
		    {
		    float f1;
		    double f2;
		    if (fbh->datalen == sizeof(float))
		       {
		       memcpy(&f1, fbh->data, sizeof(float));
		       sprintf(cvbuf, "%E", f1);
		       }
		    else
		       {
		       memcpy(&f2, fbh->data, sizeof(double));
		       sprintf(cvbuf, "%E", f2);
		       }
            sv_setpvn(sv, (char*)fbh->data, strlen(cvbuf));
		    sv_setpv(sv, cvbuf);
		    break;
		    }
		default:
		    if (fbh->ColSqlType == SQL_CHAR
		        && DBIc_is(imp_sth, DBIcf_ChopBlanks)
		        && fbh->datalen > 0)
		    	{
			int len = fbh->datalen;
			char *p0  = (char *)(fbh->data);
			char *p   = (char *)(fbh->data) + len;

			while (p-- != p0)
			    {
			    if (*p != ' ')
			    	break;
			    len--;
			    }
		        sv_setpvn(sv, p0, len);
			break;
			}
		    /* no ChopBlank */
		    if (fbh->ftype == SQL_C_FILE) /* #007 */
                sv_setpvn(sv, (char*)fbh->data, strlen(fbh->data));
            else
                sv_setpvn(sv, (char*)fbh->data, fbh->datalen);
		    break;
		}
	    }
	else 
	    {
	    SvOK_off(sv);
	    }
	}

#if DBMAKER_FILE_INOUT  
    /* 
     * #004 This can be done by SQLGetData, but use dbmaker's way seems easier.
     */
    if (imp_sth->fgBindColToFile)
       {
       int i;
       imp_fbh_t *fbh;
       for (fbh=imp_sth->fbh, i=0; i<imp_sth->n_result_cols; i++, fbh++)
           {
           if (fbh->ftype == SQL_C_FILE) 
              {
              char buf[MAX_FILE_NAME_LEN];
              struct stat  fbuf;
              do {
                fbh->file_idxno++;
                if (fbh->file_ext)
                   sprintf(fbh->data, "%s%d%s", fbh->file_prefix, fbh->file_idxno,fbh->file_ext);
                else
                   sprintf(fbh->data, "%s%d", fbh->file_prefix, fbh->file_idxno);
              } while(!fbh->fgOverwrite && !stat(fbh->data, &fbuf)); /* #008 */
              
              if (dbis->debug >= 2)
                  fprintf(DBILOGFP, 
		    "\tRebind/BindColToFile: col#%d to file:[%s]\n", i+1, fbh->data);
              }
           }
       }
#endif    	

    return av;
    }

int
dbd_st_finish(sth)
    SV *sth;
{
    D_imp_sth(sth);
    D_imp_dbh_from_sth;
    D_imp_drh_from_dbh;
    RETCODE rc;
    int ret = 1;

    /* Cancel further fetches from this cursor.                 */
    /* We don't close the cursor till DESTROY (dbd_st_destroy). */
    /* The application may re execute(...) it.                  */

    if (DBIc_ACTIVE(imp_sth) && imp_dbh->hdbc != SQL_NULL_HDBC)
	{
	rc = SQLFreeStmt(imp_sth->hstmt, SQL_CLOSE);
	dbmaker_error(sth, rc, "st_finish/SQLFreeStmt(SQL_CLOSE)");

	if (rc != SQL_SUCCESS)
	    ret = 0;
#ifdef SOL22_AUTOCOMMIT_BUG
	if (DBIc_is(imp_dbh, DBIcf_AutoCommit))
	    {
    	    rc = SQLTransact(imp_drh->henv, 
		             imp_dbh->hdbc,
		             SQL_COMMIT);
	    }
#endif
	}
    DBIc_ACTIVE_off(imp_sth);

    return ret;
    }

void
dbd_st_destroy(sth)
    SV *sth;
{
    D_imp_sth(sth);
    D_imp_dbh_from_sth;
    D_imp_drh_from_dbh;
    RETCODE rc;

    /* SQLxxx functions dump core when no connection exists. This happens
     * when the db was disconnected before perl ending.
     */
    if (imp_dbh->hdbc != SQL_NULL_HDBC)
	{
	rc = SQLFreeStmt(imp_sth->hstmt, SQL_DROP);
#if 0	
	if (rc != SQL_SUCCESS)
	    {
	    warn("warning: DBD::DBMaker SQLFreeStmt(SQL_DROP) returns %d\n", rc);
	    }
#endif	    
	}

    /* Free contents of imp_sth	*/

    Safefree(imp_sth->fbh);
    Safefree(imp_sth->ColNames);
    Safefree(imp_sth->RowBuffer);
    Safefree(imp_sth->statement);

    if (imp_sth->params_av)
	{
	av_undef(imp_sth->params_av);
	imp_sth->params_av = NULL;
	}

    if (imp_sth->params_hv)
	{
	HV *hv = imp_sth->params_hv;
	SV *sv;
	char *key;
	I32 retlen;

	/* free SV allocated inside the placeholder structs
	 */
	hv_iterinit(hv);
	while( (sv = hv_iternextsv(hv, &key, &retlen)) != NULL ) 
	    {
	    if (sv != &sv_undef) 
	         {
		 phs_t *phs_tpl = (phs_t*)(void*)SvPVX(sv);
		 sv_free(phs_tpl->sv);
		 }
	    }
        hv_undef(imp_sth->params_hv);
	imp_sth->params_hv = NULL;
	}

    DBIc_IMPSET_off(imp_sth);		/* let DBI know we've done it	*/
    }

/* ====================================================================	*/


/* walks through param_av and binds each plh found
 */
int 
_dbd_rebind_ph(sth, imp_sth, phs, maxlen) 
    SV *sth;
    imp_sth_t *imp_sth;
    phs_t *phs;
    int maxlen;
{
    dTHR;
    RETCODE rc;
    /* args of SQLBindParameter() call */
    SWORD fParamType;
    SWORD fCType;
    SWORD fSqlType;
    UCHAR *rgbValue;
    UDWORD cbColDef;
    SWORD ibScale;
    SDWORD cbValueMax;

    STRLEN value_len;

    if (DBIS->debug >= 2) {
	char *text = neatsvpv(phs->sv,0);
	fprintf(DBILOGFP,
		"bind %s <== %s (size %d/%d/%ld, ptype %ld, otype %d)\n",
		phs->name, text, SvCUR(phs->sv),SvLEN(phs->sv),phs->maxlen,
		SvTYPE(phs->sv), phs->ftype);
    }

    /* At the moment we always do sv_setsv() and rebind.        */
    /* Later we may optimise this so that more often we can     */
    /* just copy the value & length over and not rebind.        */

    if (phs->is_inout) {        /* XXX */
	if (SvREADONLY(phs->sv))
	    croak(no_modify);
	/* phs->sv _is_ the real live variable, it may 'mutate' later   */
	/* pre-upgrade high to reduce risk of SvPVX realloc/move        */
	(void)SvUPGRADE(phs->sv, SVt_PVNV);
	/* ensure room for result, 28 is magic number (see sv_2pv)      */
	SvGROW(phs->sv, (phs->maxlen < 28) ? 28 : phs->maxlen+1);
    }
    else {
	/* phs->sv is copy of real variable, upgrade to at least string */
	(void)SvUPGRADE(phs->sv, SVt_PV);
    }
    
    /* At this point phs->sv must be at least a PV with a valid buffer, */
    /* even if it's undef (null)                                        */
    /* Here we set phs->sv_buf, and value_len.                */
    if (SvOK(phs->sv)) {
	phs->sv_buf = SvPV(phs->sv, value_len);
    }
    else {      /* it's null but point to buffer incase it's an out var */
	phs->sv_buf = SvPVX(phs->sv);
	if (!phs->is_inout)
        value_len  = 0;
    }

    /* value_len has current value length now */
    phs->sv_type = SvTYPE(phs->sv);     /* part of mutation check       */
    phs->maxlen  = SvLEN(phs->sv)-1;    /* avail buffer space  		*/
    if (phs->is_inout)  /* #005 */
       value_len = phs->maxlen;   /* #005 set this to avoid live var len < maxlen */
    
    if (DBIS->debug >= 3) {
	fprintf(DBILOGFP, "bind %s <== '%.100s' (len %ld/%ld, null %d)\n",
		phs->name, phs->sv_buf,
		(long)value_len,(long)phs->maxlen, SvOK(phs->sv)?0:1);
    }

    /* ----------------------------------------------------------------	*/

    /* XXX
    This will fail (IM001) on drivers which don't support it.
    We need to check for this and bind the param as varchars.
    This will work on many drivers and databases.
    If the database won't convert a varchar to an int (for example)
    the user will get an error at execute time
    but can add an explicit conversion to the SQL:
    "... where num_field > int(?) ..."
*/


    if (phs->sql_type == SQL_DEFAULT) { /* #003 if no specified sql type */
	SWORD fNullable;
	SWORD ibScale;
	UDWORD dp_cbColDef;
	rc = SQLDescribeParam(imp_sth->hstmt,
			      phs->idx, &fSqlType, &dp_cbColDef, &ibScale, &fNullable
			     );
	if (!SQL_ok(rc)) {
	    dbmaker_error(sth, rc, "_rebind_ph/SQLDescribeParam");
	    return 0;
	}
	if (DBIS->debug >=2)
	    fprintf(DBILOGFP,
		    "    SQLDescribeParam %s: SqlType=%s, ColDef=%d\n",
		    phs->name, S_SqlTypeToString(fSqlType), dp_cbColDef);

	phs->sql_type = fSqlType;
    }

    if (phs->is_inout) /* #005 */
       {
       fParamType = SQL_PARAM_OUTPUT;
       fCType = SQL_C_CHAR;
       }
    else
       fParamType = SQL_PARAM_INPUT;
       
    fCType = phs->ftype;
    ibScale = value_len;
    cbColDef = value_len;
    cbValueMax = value_len;

    if (!SvOK(phs->sv) && !phs->is_inout) /* #005 */
       {
       rgbValue = NULL;
       phs->cbValue = SQL_NULL_DATA;
       }
    else 
       {
       rgbValue = phs->sv_buf;
       phs->cbValue = (UDWORD) value_len;
       }
    
    /* When we fill a LONGVARBINARY, the CTYPE must be set 
     * to SQL_C_BINARY.
     */
    if (fCType == SQL_C_CHAR) {	/* could be changed by bind_plh */
        int len1;
        switch(phs->sql_type) {
            case SQL_LONGVARBINARY:
            case SQL_BINARY:
            case SQL_VARBINARY:
            fCType = SQL_C_BINARY;
      		break;
  	        case SQL_LONGVARCHAR:
      		break;
  	        case SQL_TIMESTAMP:
  	        case SQL_DATE:
      	    case SQL_TIME:
  	    	fSqlType = SQL_VARCHAR;
  		    break;
      	    default:
  	    	break;
      	}
      	
      fSqlType = phs->sql_type; /* #008 */
#if DBMAKER_FILE_INOUT /* #004 check if can use FILE as input param */
       if (imp_sth->fgfileinput)
          {
           switch(fSqlType)
        		{
    	    	case SQL_LONGVARBINARY:
    		    case SQL_LONGVARCHAR:
    		    case SQL_FILE:
                    len1 = strlen(rgbValue);
                    if (rgbValue[0] == '\'' && rgbValue[len1-1] == '\'')
                       {
                       char buf[1000];
                       sprintf(buf, "%.*s", len1-2, &rgbValue[1]);
                       strcpy(rgbValue, buf);
                       cbValueMax = len1-2;
                       fCType = SQL_C_FILE; 
                       if (phs->sql_type == SQL_FILE)
                             fSqlType = SQL_LONGVARBINARY;
                       }
                     else
                       { /* store file name #008 */
                       if (phs->sql_type == SQL_FILE)
                          {
                          fCType   = SQL_C_CHAR;
                          fSqlType = SQL_FILE;
                          }
                       }
    		         break;
        		default:
        		    break;
    	        }
    	  }
       else
          { /* store data #008 */
          if (fSqlType == SQL_FILE)
             {
             fSqlType = SQL_LONGVARCHAR;
             }
          }
#endif          	
    }
    
    if (DBIS->debug >=2)
	fprintf(DBILOGFP,
		"    bind %s[%d]: CTy=%d, STy=%s, CD=%d, Sc=%d, VM=%d.\n",
		phs->name, phs->idx, fCType, S_SqlTypeToString(fSqlType),
		cbColDef, ibScale, cbValueMax);

	ibScale = value_len;
	
    rc = SQLBindParameter(imp_sth->hstmt,
			  phs->idx, fParamType, fCType, fSqlType,
			  cbColDef, ibScale,
			  rgbValue, cbValueMax, &phs->cbValue);

    if (!SQL_ok(rc)) {
	dbmaker_error(sth, rc, "_rebind_ph/SQLBindParameter");
	return 0;
    }

    return 1;

}    
    
/*------------------------------------------------------------
 * bind placeholder.
 *  Is called from DBMaker.xs execute()
 *  AND from DBMaker.xs bind_param()
 */
dbd_bind_ph(sth, imp_sth, ph_namesv, newvalue, sql_type, attribs, is_inout, maxlen)
SV *sth;
imp_sth_t *imp_sth;
SV *ph_namesv;		/* index of execute() parameter 1..n */
SV *newvalue;
IV sql_type;
SV *attribs;		/* may be set by Solid.xs bind_param call */
int is_inout;		/* inout for procedure calls only */
IV maxlen;			/* ??? */
{
    dTHR;
    SV **phs_svp;
    STRLEN name_len;
    char *name;
    char namebuf[30];
    phs_t *phs;

    if (SvNIOK(ph_namesv) ) {	/* passed as a number	*/
	name = namebuf;
	sprintf(name, "%d", (int)SvIV(ph_namesv));
	name_len = strlen(name);
    } 
    else {
	name = SvPV(ph_namesv, name_len);
    }

    if (SvTYPE(newvalue) > SVt_PVMG)    /* hook for later array logic   */
	croak("Can't bind non-scalar value (currently)");

    if (DBIS->debug >= 2)
	fprintf(DBILOGFP, "bind %s <== '%.200s' (attribs: %s)\n",
		name, SvPV(newvalue,na), attribs ? SvPV(attribs,na) : "" );

    phs_svp = hv_fetch(imp_sth->params_hv, name, name_len, 0);
    if (phs_svp == NULL)
       croak("Can't bind unknown placeholder '%s'", name);
    phs = (phs_t*)SvPVX(*phs_svp);	/* placeholder struct	*/

    if (phs->sv == &sv_undef) { /* first bind for this placeholder      */
    phs->ftype    = SQL_C_CHAR;     /* our default type VARCHAR2    */
	phs->sql_type = (sql_type) ? sql_type : SQL_DEFAULT;    /* #003 */
	phs->maxlen   = maxlen;         /* 0 if not inout               */
	phs->is_inout = is_inout;
	if (is_inout) {
	    ++imp_sth->has_inout_params;
	    /* build array of phs's so we can deal with out vars fast   */
	    if (!imp_sth->params_av)
           imp_sth->params_av = newAV();
	    av_push(imp_sth->params_av, SvREFCNT_inc(*phs_svp));
#if 0 /* #005 */	    
	    croak("Can't bind output values (currently)");	/* XXX */
#endif
    }

	/* some types require the trailing null included in the length. */
	phs->alen_incnull = 0; /*Oracle:(phs->ftype==SQLT_STR || phs->ftype==SQLT_AVC);*/

    }
    /* check later rebinds for any changes */
    else if (is_inout || phs->is_inout) {
	croak("Can't rebind or change param %s in/out mode after first bind", phs->name);
    }
    else if (maxlen && maxlen != phs->maxlen) {
	croak("Can't change param %s maxlen (%ld->%ld) after first bind",
	      phs->name, phs->maxlen, maxlen);
    }

    if (!is_inout) {    /* normal bind to take a (new) copy of current value    */
	if (phs->sv == &sv_undef)       /* (first time bind) */
	    phs->sv = newSV(0);
	sv_setsv(phs->sv, newvalue);
    }
    else if (newvalue != phs->sv) { /* #005 from oracle */
    	if (phs->sv)
	    SvREFCNT_dec(phs->sv);
	phs->sv = SvREFCNT_inc(newvalue);	/* point to live var	*/
    }    

    return _dbd_rebind_ph(sth, imp_sth, phs);
}


int
dbd_st_rows(sth)
    SV *sth;
{
    D_imp_sth(sth);
    return imp_sth->RowCount;
}

/*------------------------------------------------------------
 * blob_read:
 * read part of a BLOB from a table.
 */
static int 
S_IsBlobReadError(
	SV *sth, 
	RETCODE rc, 
        char *sqlstate,
	const void *par)
    {
    D_imp_sth(sth);

    if (rc == SQL_SUCCESS_WITH_INFO)
        {
	if (strEQ(sqlstate, "01004")) /* data truncated */
	    {
	    /* Data truncated is NORMAL during blob_read
	     */
	    return 0;
	    }
        }
    else if (rc == SQL_NO_DATA_FOUND)
    	return 0;
	
    return 1;
    }
	
dbd_st_blob_read(sth, field, offset, len, destrv, destoffset)
    SV *sth;
    int field;
    long offset;
    long len;
    SV *destrv;
    long destoffset;
{
    D_imp_sth(sth);
    SDWORD retl;
    SV *bufsv;
    RETCODE rc;

    bufsv = SvRV(destrv);
    sv_setpvn(bufsv,"",0);      /* ensure it's writable string  */
    SvGROW(bufsv, len+destoffset+1);    /* SvGROW doesn't do +1 */
    rc = SQLGetData(imp_sth->hstmt, (UWORD)field+1,
		    SQL_C_BINARY,
		    ((UCHAR *)SvPVX(bufsv)) + destoffset,
		    (SDWORD) (len - destoffset),
		    &retl);
    dbmaker_error5(sth, rc, "dbd_st_blob_read/SQLGetData",
    		S_IsBlobReadError, NULL);

    if (dbis->debug >= 2) {
        fprintf(DBILOGFP, "GetData: received %i (max. %i) bytes, buf size = %i, offset = %i [binary]\n",
                (int)retl, (int)(len-destoffset), (int)len, (int) destoffset);
	fprintf(DBILOGFP, "SQLGetData(...,off=%d, len=%d)->rc=%d,len=%d SvCUR=%d\n",
		destoffset, len,
		rc, retl, SvCUR(bufsv));
    }

    if (rc != SQL_SUCCESS)
	{
        if (SvIV(DBIc_ERR(imp_sth)))	
	     {
	     /* IsBlobReadError thinks it's an error */
    	     return 0;
	     }
        if (rc == SQL_NO_DATA_FOUND)
	    return 0;

	retl = len;
        }

    SvCUR_set(bufsv, destoffset+retl);
    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "blob_read: SvCUR=%d\n",
		SvCUR(bufsv));

    *SvEND(bufsv) = '\0'; /* consistent with perl sv_setpvn etc */
 
    return 1;
    }

/*----------------------------------------
 * db level interface
 * set connection attributes.
 *----------------------------------------
 */

static db_params S_db_storeOptions[] =  {
    { "AutoCommit", SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_ON, SQL_AUTOCOMMIT_OFF },
#if 0 /* not defined by DBI/DBD specification */
    { "TRANSACTION", 
                 SQL_ACCESS_MODE, SQL_MODE_READ_ONLY, SQL_MODE_READ_WRITE },
    { "dbmaker_trace", SQL_OPT_TRACE, SQL_OPT_TRACE_ON, SQL_OPT_TRACE_OFF },
    { "dbmaker_timeout", SQL_LOGIN_TIMEOUT },
    { "ISOLATION", SQL_TXN_ISOLATION },
    { "dbmaker_tracefile", SQL_OPT_TRACEFILE },
#endif
    { NULL },
};

static const db_params *
S_dbOption(const db_params *pars, char *key, STRLEN len)
{
    /* search option to set */
    while (pars->str != NULL)
	{
	if (strncmp(pars->str, key, len) == 0
	    && len == strlen(pars->str))
	    break;
        pars++;
	}
    if (pars->str == NULL)
	return NULL;
    return pars;
    }
 
int
dbd_db_STORE(dbh, keysv, valuesv)
    SV *dbh;
    SV *keysv;
    SV *valuesv;
{
    D_imp_dbh(dbh);
    D_imp_drh_from_dbh;
    RETCODE rc;
    STRLEN kl;
    STRLEN plen;
    char *key = SvPV(keysv,kl);
    SV *cachesv = NULL;
    int on;
    UDWORD vParam;
    const db_params *pars;
    int parind;

    if ((pars = S_dbOption(S_db_storeOptions, key, kl)) == NULL)
	return FALSE;

    parind = pars - S_db_storeOptions;

    switch(pars->fOption)
	{
	case SQL_LOGIN_TIMEOUT:
	case SQL_TXN_ISOLATION:
	    vParam = SvIV(valuesv);
	    break;
	case SQL_OPT_TRACEFILE:
	    vParam = (UDWORD) SvPV(valuesv, plen);
	    break;
	case SQL_AUTOCOMMIT:
	    on = SvTRUE(valuesv);
	    vParam = on ? pars->true : pars->false;
	    break;
	}

    rc = SQLSetConnectOption(imp_dbh->hdbc, pars->fOption, vParam);
    dbmaker_error(dbh, rc, "db_STORE/SQLSetConnectOption");
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
	{
	return FALSE;
	}
    if (pars->fOption == SQL_AUTOCOMMIT)
    	{
	if (on) DBIc_set(imp_dbh, DBIcf_AutoCommit, 1);
	else    DBIc_set(imp_dbh, DBIcf_AutoCommit, 0);
	}
    return TRUE;
    }


static db_params S_db_fetchOptions[] =  {
    { "AutoCommit", SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_ON, SQL_AUTOCOMMIT_OFF },
#if 0 /* seems not supported by DBMAKER ? */
    { "dbm_readonly", 
                 SQL_ACCESS_MODE, SQL_MODE_READ_ONLY, SQL_MODE_READ_WRITE },
    { "dbm_trace", SQL_OPT_TRACE, SQL_OPT_TRACE_ON, SQL_OPT_TRACE_OFF },
    { "dbm_timeout", SQL_LOGIN_TIMEOUT },
    { "dbm_isolation", SQL_TXN_ISOLATION },
    { "dbm_tracefile", SQL_OPT_TRACEFILE },
#endif
    { NULL }
};

SV *
dbd_db_FETCH(dbh, keysv)
    SV *dbh;
    SV *keysv;
{
    D_imp_dbh(dbh);
    D_imp_drh_from_dbh;
    RETCODE rc;
    STRLEN kl;
    STRLEN plen;
    char *key = SvPV(keysv,kl);
    int on;
    UDWORD vParam = 0;
    const db_params *pars;
    SV *retsv = NULL;

    if ((pars = S_dbOption(S_db_fetchOptions, key, kl)) == NULL)
	return Nullsv;

    /*
     * readonly, tracefile etc. isn't working yet. only AutoCommit supported.
     */

    if (pars->fOption == 0xffff)
    	{
	}
    else
    	{
        rc = SQLGetConnectOption(imp_dbh->hdbc, pars->fOption, &vParam);
        dbmaker_error(dbh, rc, "db_FETCH/SQLGetConnectOption");
        if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
	    {
	    if (dbis->debug >= 1)
	        fprintf(DBILOGFP,
		    "SQLGetConnectOption returned %d in dbd_db_FETCH\n", rc);
	    return Nullsv;
	    }
	}
    switch(pars->fOption)
	{
	case SQL_LOGIN_TIMEOUT:
	case SQL_TXN_ISOLATION:
	    newSViv(vParam);
	    break;
	case SQL_OPT_TRACEFILE:
	    retsv = newSVpv((char *)vParam, 0);
	    break;
	default:
	    if (vParam == pars->true)
		retsv = newSViv(1);
	    else
		retsv = newSViv(0);
	    break;
	} /* switch */
    return sv_2mortal(retsv);
    }

#define s_A(str) { str, sizeof(str)-1 }
static T_st_params S_st_fetch_params[] = 
{
    s_A("NUM_OF_PARAMS"),	/* 0 */
    s_A("NUM_OF_FIELDS"),	/* 1 */
    s_A("NAME"),		/* 2 */
    s_A("NULLABLE"),		/* 3 */
    s_A("TYPE"),		/* 4 */
    s_A("PRECISION"),		/* 5 */
    s_A("SCALE"),		/* 6 */
    s_A("dbm_type"),		/* 7 */
    s_A("dbm_length"),		/* 8 */
    s_A("CursorName"),		/* 9 */
    s_A("blob_size"),		/* 10 */
    s_A("__handled_by_dbi__"),	/* 11 */	/* ChopBlanks */
    s_A("dbmaker_blob_size"),	/* 12 */
    s_A("dbmaker_type"),		/* 13 */
    s_A("dbmaker_length"),	    /* 14 */
    s_A("LongReadLen"),		    /* 15 */
    s_A("dbmaker_file_input"),   /* 16 */       /* #004 */
    s_A(""),			/* END */
};

static T_st_params S_st_store_params[] = 
{
    s_A("blob_size"),		    /* 0 */
    s_A("dbmaker_blob_size"),	/* 1 */
    s_A("dbmaker_file_input"),   /* 2 */    /* #004 */
    s_A(""),			/* END */
};
#undef s_A

/*----------------------------------------
 * dummy routines st_XXXX
 *----------------------------------------
 */
SV *
dbd_st_FETCH(sth, keysv)
    SV *sth;
    SV *keysv;
{
    D_imp_sth(sth);
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    int i;
    SV *retsv = NULL;
    T_st_params *par;
    int n_fields;
    imp_fbh_t *fbh;
    char cursor_name[256];
    SWORD cursor_name_len;
    RETCODE rc;
    int par_index;

    for (par = S_st_fetch_params; 
	 par->len > 0;
	 par++)
	if (par->len == kl && strEQ(key, par->str))
	    break;

    if (par->len <= 0)
	return Nullsv;

    if (!imp_sth->done_desc && !dbd_describe(sth, imp_sth)) 
	{
	/* dbd_describe has already called ora_error()          */
	/* we can't return Nullsv here because the xs code will */
	/* then just pass the attribute name to DBI for FETCH.  */
        croak("Describe failed during %s->FETCH(%s)",
                SvPV(sth,na), key);
	}

    i = DBIc_NUM_FIELDS(imp_sth);
 
    switch(par_index = par - S_st_fetch_params)
	{
	AV *av;

	case 0:			/* NUM_OF_PARAMS */
	    return Nullsv;	/* handled by DBI */
        case 1:			/* NUM_OF_FIELDS */
	    retsv = newSViv(i);
	    break;
	case 2: 			/* NAME */
	    av = newAV();
	    retsv = newRV(sv_2mortal((SV*)av));
	    while(--i >= 0)
		av_store(av, i, newSVpv(imp_sth->fbh[i].ColName, 0));
	    break;
	case 3:			/* NULLABLE */
	    av = newAV();
	    retsv = newRV(sv_2mortal((SV*)av));
	    while(--i >= 0) switch(imp_sth->fbh[i].ColNullable)
		{
		case SQL_NULLABLE:
		    av_store(av, i, &sv_yes);
		    break;
		case SQL_NO_NULLS:
		    av_store(av, i, &sv_no);
		    break;
		case SQL_NULLABLE_UNKNOWN:
		    av_store(av, i, &sv_undef);
		    break;
		}
	    break;
	case 4:			/* TYPE */
	    av = newAV();
	    retsv = newRV(sv_2mortal((SV*)av));
	    while(--i >= 0) 
		{
		int type = imp_sth->fbh[i].ColSqlType;
		av_store(av, i, newSViv(type));
		}
	    break;
        case 5:			/* PRECISION */
	    av = newAV();
	    retsv = newRV(sv_2mortal((SV*)av));
	    while(--i >= 0) 
		{
		av_store(av, i, newSViv(imp_sth->fbh[i].ColDef));
		}
	    break;
	case 6:			/* SCALE */
	    av = newAV();
	    retsv = newRV(sv_2mortal((SV*)av));
	    while(--i >= 0) 
		{
		av_store(av, i, newSViv(imp_sth->fbh[i].ColScale));
		}
	    break;
	case 7:			/* dbd_type */
	    if (DBIc_WARN(imp_sth))
	    	warn("Depreciated feature 'dbm_type'. "
		     "Please use 'dbmaker_type' instead.");
	    /* fall through */
	case 13:		/* dbmaker_type */
	    av = newAV();
	    retsv = newRV(sv_2mortal((SV*)av));
	    while(--i >= 0) 
		{
		av_store(av, i, newSViv(imp_sth->fbh[i].ColSqlType));
		}
	    break;
	case 8:			/* dbd_length */
	    if (DBIc_WARN(imp_sth))
	    	warn("Depreciated feature 'dbm_length'. "
		     "Please use 'dbmaker_length' instead.");
	    /* fall through */
	case 14:		/* dbmaker_length */
	    av = newAV();
	    retsv = newRV(sv_2mortal((SV*)av));
	    while(--i >= 0) 
		{
		av_store(av, i, newSViv(imp_sth->fbh[i].ColLength));
		}
	    break;
	case 9:			/* CursorName */
	    rc = SQLGetCursorName(imp_sth->hstmt,
				  cursor_name,
				  sizeof(cursor_name),
				  &cursor_name_len);
	    dbmaker_error(sth, rc, "st_FETCH/SQLGetCursorName");
	    if (rc != SQL_SUCCESS)
		{
		if (dbis->debug >= 1)
		    {
		    fprintf(DBILOGFP,
			    "SQLGetCursorName returned %d in dbd_st_FETCH\n", 
			    rc);
		    }
		return Nullsv;
		}
	    retsv = newSVpv(cursor_name, cursor_name_len);
	    break;
	case 10:		/* blob_size */
	    if (DBIc_WARN(imp_sth))
	    	warn("Depreciated feature 'blob_size'. "
		     "Please use 'dbmaker_blob_size' instead.");
	    /* fall through */
	case 12:		/* dbmaker_blob_size */
	case 15: 		/* LongReadLen */
	    retsv = newSViv(DBIc_LongReadLen(imp_sth));
	    break;
	    
	case 16:        /* dbmaker_file_input #004 */
	    retsv = newSViv(imp_sth->fgfileinput);
	    break;
	    
	default:
	    return Nullsv;
	}

    return sv_2mortal(retsv);
    }

int
dbd_st_STORE(sth, keysv, valuesv)
    SV *sth;
    SV *keysv;
    SV *valuesv;
{
    D_imp_sth(sth);
    D_imp_dbh_from_sth;
    STRLEN kl;
    STRLEN vl;
    char *key = SvPV(keysv,kl);
    char *value = SvPV(valuesv, vl);
    T_st_params *par;
    RETCODE rc;
 
    for (par = S_st_store_params; 
	 par->len > 0;
	 par++)
	if (par->len == kl && strEQ(key, par->str))
	    break;

    if (par->len <= 0)
	return FALSE;

    switch(par - S_st_store_params)
	{
	case 0:/* blob_size */
	case 1:/* dbmaker_blob_size */
#if DESCRIBE_IN_PREPARE
	    warn("$sth->{blob_size} isn't longer supported.\n"
	         "You may either use the 'LongReadLen' "
		 "attribute to prepare()\nor the blob_read() "
		 "function.\n");
	    return FALSE;
#endif
	    DBIc_LongReadLen(imp_sth) = SvIV(valuesv);
	    return TRUE;
	    break;
	case 2: /* dbmaker_file_input #004 */
	    imp_sth->fgfileinput = SvIV(valuesv);
	    return TRUE;
	    break;
	}
    return FALSE;
    }

int
   build_results(sth)
   SV *	 sth;
{
    RETCODE rc;
    D_imp_sth(sth);

    if (DBIS->debug >= 2)
	fprintf(DBILOGFP, "    build_results sql f%d\n\t%s\n",
		imp_sth->hstmt, imp_sth->statement);

    /* init sth pointers */
    imp_sth->fbh = NULL;
    imp_sth->ColNames = NULL;
    imp_sth->RowBuffer = NULL;
    imp_sth->RowCount = -1;
    imp_sth->eod = -1;
#if DBMAKER_FILE_INOUT    /* #004 */  
    imp_sth->fgfileinput = 1;
    imp_sth->fgBindColToFile = 0;
#else
    imp_sth->fgfileinput = 0;
    imp_sth->fgBindColToFile = 0; 
#endif    

    if (!dbd_describe(sth, imp_sth)) {
	SQLFreeStmt(imp_sth->hstmt, SQL_DROP);
	imp_sth->hstmt = SQL_NULL_HSTMT;
	return 0; /* dbd_describe already called ora_error()	*/
    }

    if (dbd_describe(sth, imp_sth) <= 0)
	return 0;

    DBIc_IMPSET_on(imp_sth);

    imp_sth->RowCount = -1;
    rc = SQLRowCount(imp_sth->hstmt, &imp_sth->RowCount);
    dbmaker_error(sth, rc, "dbd_st_tables/SQLRowCount");
    if (rc != SQL_SUCCESS) {
	return -1;
    }

    DBIc_ACTIVE_on(imp_sth); /* XXX should only set for select ?	*/
    imp_sth->eod = SQL_SUCCESS;
    return 1;
}

int
dbd_st_get_type_info(dbh, sth, ftype)
    SV *dbh;
    SV *sth;
    int ftype;
{
    dTHR;
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;
    SV **svp;
    char cname[128];			/* cursorname */

    imp_sth->done_desc = 0;
    rc = SQLAllocStmt(imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
	dbmaker_error(sth, rc, "dbmaker_get_type_info/SQLGetTypeInfo");
	return 0;
    }

    /* just for sanity, later. Any internals that may rely on this (including */
    /* debugging) will have valid data */
    imp_sth->statement = (char *)safemalloc(strlen(cSqlGetTypeInfo)+ftype/10+1);
    sprintf(imp_sth->statement, cSqlGetTypeInfo, ftype);

    rc = SQLGetTypeInfo(imp_sth->hstmt, ftype);

    dbmaker_error(sth, rc, "dbmaker_get_type_info/SQLGetTypeInfo");
    if (!SQL_ok(rc)) {
	SQLFreeStmt(imp_sth->hstmt, SQL_DROP);
	imp_sth->hstmt = SQL_NULL_HSTMT;
	return 0;
    }

    return build_results(sth);
}

SV *
dbmaker_get_info(dbh, ftype)
    SV *dbh;
    int ftype;
{
    dTHR;
    D_imp_dbh(dbh);
    RETCODE rc;
    SV *retsv = NULL;
    int i;
    char rgbInfoValue[256];
    SWORD cbInfoValue = -2;

    /* See fancy logic below */
    for (i = 0; i < 6; i++)
	rgbInfoValue[i] = 0xFF;
    
    rc = SQLGetInfo(imp_dbh->hdbc, ftype,
	rgbInfoValue, sizeof(rgbInfoValue)-1, &cbInfoValue);
    if (!SQL_ok(rc)) {
	dbmaker_error(dbh, rc, "dbmaker_get_info/SQLGetInfo");
	return Nullsv;
    }

    /* Fancy logic here to determine if result is a string or int */
    if (cbInfoValue == -2)				/* is int */
	retsv = newSViv(*(int *)rgbInfoValue);	/* XXX cast */
    else if (cbInfoValue != 2 && cbInfoValue != 4)	/* must be string */
	retsv = newSVpv(rgbInfoValue, 0);
    else if (rgbInfoValue[cbInfoValue+1] == '\0')	/* must be string */
	retsv = newSVpv(rgbInfoValue, 0);
    else if (cbInfoValue == 2)			/* short */
	retsv = newSViv(*(short *)rgbInfoValue);	/* XXX cast */
    else if (cbInfoValue == 4)			/* int */
	retsv = newSViv(*(int *)rgbInfoValue);	/* XXX cast */
    else
	croak("panic: SQLGetInfo cbInfoValue == %d", cbInfoValue);

    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "SQLGetInfo: ftype %d, cbInfoValue %d: %s\n",
	    ftype, cbInfoValue, neatsvpv(retsv,0));

    return sv_2mortal(retsv);
}

SV *
dbmaker_col_attributes(sth, colno, desctype)
   SV *sth;
   int colno;
   int desctype;
{
    dTHR;
    D_imp_sth(sth);
    RETCODE rc;
    SV *retsv = NULL;
    int i;
    char rgbInfoValue[256];
    SWORD cbInfoValue = -2;
    SDWORD fDesc = -2;
    
    for (i = 0; i < 6; i++)
	rgbInfoValue[i] = 0xFF;

    if ( !DBIc_ACTIVE(imp_sth) ) {
	dbmaker_error(sth, SQL_ERROR, "no statement executing");
	return Nullsv;
    }
 
/*  fprintf(DBILOGFP,
	"SQLColAttributes: colno = %d, desctype = %d, cbInfoValue = %d\n",
	colno, desctype, cbInfoValue);
    at least on Win95, calling this with colno==0 would "core" dump/GPF.
    protect, even though it's valid for some values of desctype
    (e.g. SQL_COLUMN_COUNT, since it doesn't depend on the colcount)
*/
    if (colno == 0) {
	dbmaker_error(sth, SQL_ERROR,
		  "can not obtain SQLColAttributes for column 0");
	return Nullsv;
    }

    rc = SQLColAttributes(imp_sth->hstmt, colno, desctype,
	      rgbInfoValue, sizeof(rgbInfoValue)-1, &cbInfoValue, &fDesc);
    if (!SQL_ok(rc)) {
	dbmaker_error(sth, rc, "dbmaker_col_attributes/SQLColAttributes");
	return Nullsv;
    }

    if (dbis->debug >= 2) {
	fprintf(DBILOGFP,
	    "SQLColAttributes: colno=%d, desctype=%d, cbInfoValue=%d, fDesc=%d",
	    colno, desctype, cbInfoValue, fDesc
	);
	if (dbis->debug>=4)
	    fprintf(DBILOGFP,
		" rgbInfo=[%02x,%02x,%02x,%02x,%02x,%02x\n",
		rgbInfoValue[0] & 0xff, rgbInfoValue[1] & 0xff, rgbInfoValue[2] & 0xff, 
		rgbInfoValue[3] & 0xff, rgbInfoValue[4] & 0xff, rgbInfoValue[5] & 0xff
	    );
	fprintf(DBILOGFP,"\n");
    }

    /*
     * sigh...Oracle's ODBC driver version 8.0.4 resets cbInfoValue to 0, when
     * putting a value in fDesc.  This is a change!
     *
     * double sigh.  SQL Server (and MySql under Unix) set cbInfoValue
     * but use fdesc, not rgbInfoValue.  This change may be problematic
     * for other drivers. (the additional || fDesc != -2...)
     */
    if (cbInfoValue == -2 || cbInfoValue == 0 || fDesc != -2)
	retsv = newSViv(fDesc);
    else if (cbInfoValue != 2 && cbInfoValue != 4)
	retsv = newSVpv(rgbInfoValue, 0);
    else if (rgbInfoValue[cbInfoValue+1] == '\0')
	retsv = newSVpv(rgbInfoValue, 0);
    else {
	if (cbInfoValue == 2)
	    retsv = newSViv(*(short *)rgbInfoValue);
	else
	    retsv = newSViv(*(int *)rgbInfoValue);
    }

    return sv_2mortal(retsv);
}

int
dbmaker_describe_col(sth, colno, ColumnName, BufferLength, NameLength, DataType, ColumnSize, DecimalDigits, Nullable)
    SV *sth;
    int colno;
    char *ColumnName;
    I16 BufferLength;
    I16 *NameLength;
    I16 *DataType;
    U32 *ColumnSize;
    I16 *DecimalDigits;
    I16 *Nullable;
{
    D_imp_sth(sth);
    RETCODE rc;
    rc = SQLDescribeCol(imp_sth->hstmt, colno,
	ColumnName, BufferLength, NameLength,
	DataType, ColumnSize, DecimalDigits, Nullable);
    if (!SQL_ok(rc)) {
	dbmaker_error(sth, rc, "DescribeCol/SQLDescribeCol");
	return 0;
    }
    return 1;
}

int	
dbmaker_db_columns(dbh, sth, catalog, schema, table, column)
SV *dbh;
SV *sth;
char *catalog;
char *schema;
char *table;
char *column;
{
    dTHR;
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;

    imp_sth->done_desc = 0;
    rc = SQLAllocStmt(imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
	dbmaker_error(sth, rc, "dbmaker_db_columns/SQLAllocStmt");
	return 0;
    }

    /* just for sanity, later.  Any internals that may rely on this (including */
    /* debugging) will have valid data */
    imp_sth->statement = (char *)safemalloc(strlen(cSqlColumns)+
					    strlen(XXSAFECHAR(catalog))+
					    strlen(XXSAFECHAR(schema))+
					    strlen(XXSAFECHAR(table))+
					    strlen(XXSAFECHAR(column))+1);

    sprintf(imp_sth->statement,
	    cSqlColumns, XXSAFECHAR(catalog), XXSAFECHAR(schema),
	    XXSAFECHAR(table), XXSAFECHAR(column));

    rc = SQLColumns(imp_sth->hstmt,
		    (catalog && *catalog) ? catalog : 0, SQL_NTS,
		    (schema && *schema) ? schema : 0, SQL_NTS,
		    (table && *table) ? table : 0, SQL_NTS,
		    (column && *column) ? column : 0, SQL_NTS);

    if (DBIS->debug >= 2)
	fprintf(DBILOGFP, "SQLColumns call: cat = %s, schema = %s, table = %s, column = %s\n",
		XXSAFECHAR(catalog), XXSAFECHAR(schema), XXSAFECHAR(table), XXSAFECHAR(column));
    dbmaker_error(sth, rc, "dbmaker_columns/SQLColumns");

    if (!SQL_ok(rc)) {
	SQLFreeStmt(imp_sth->hstmt, SQL_DROP);
	imp_sth->hstmt = SQL_NULL_HSTMT;
	return 0;
    }

    return build_results(sth);
}

int
dbmaker_get_statistics(dbh, sth, CatalogName, SchemaName, TableName, Unique)
SV *	 dbh;
SV *	 sth;
char * CatalogName;
char * SchemaName;
char * TableName;
int		 Unique;
{
    dTHR;
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;

    imp_sth->done_desc = 0;
    rc = SQLAllocStmt(imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
	dbmaker_error(sth, rc, "dbmaker_get_statistics/SQLAllocStmt");
	return 0;
    }
    
    if (DBIS->debug >= 2)
	fprintf(DBILOGFP, "SQLStatistics: cat = %s, schema = %s, table = %s\n",
		XXSAFECHAR(CatalogName), XXSAFECHAR(SchemaName), 
		XXSAFECHAR(TableName));
    dbmaker_error(sth, rc, "dbmaker_statistics/SQLStatistics");
    
    rc = SQLStatistics(imp_sth->hstmt, 
		       CatalogName, strlen(CatalogName), 
		       SchemaName, strlen(SchemaName), 
		       TableName, strlen(TableName), 
		       Unique, 0);
    if (!SQL_ok(rc)) {
	dbmaker_error(sth, rc, "dbmaker_get_statistics/SQLGetStatistics");
	return 0;
    }
    return build_results(sth);
}

int
   dbmaker_get_primary_keys(dbh, sth, CatalogName, SchemaName, TableName)
   SV *	 dbh;
SV *	 sth;
char * CatalogName;
char * SchemaName;
char * TableName;
{
    dTHR;
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;

    imp_sth->done_desc = 0;
    rc = SQLAllocStmt(imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
	dbmaker_error(sth, rc, "dbmaker_get_primary_keys/SQLAllocStmt");
	return 0;
    }
    if (DBIS->debug >= 2)
	fprintf(DBILOGFP, "SQLPrimaryKeys: cat = %s, schema = %s, table = %s\n",
		XXSAFECHAR(CatalogName), XXSAFECHAR(SchemaName), 
		XXSAFECHAR(TableName));
    dbmaker_error(sth, rc, "dbmaker_primarykey/SQLPrimaryKeys");

    rc = SQLPrimaryKeys(imp_sth->hstmt, 
			CatalogName, strlen(CatalogName), 
			SchemaName, strlen(SchemaName), 
			TableName, strlen(TableName));
    if (!SQL_ok(rc)) {
	dbmaker_error(sth, rc, "dbmaker_get_primary_keys/SQLPrimaryKeys");
	return 0;
    }
    return build_results(sth);
}

int
   dbmaker_get_foreign_keys(dbh, sth, PK_CatalogName, PK_SchemaName, PK_TableName, FK_CatalogName, FK_SchemaName, FK_TableName)
   SV *	 dbh;
SV *	 sth;
char * PK_CatalogName;
char * PK_SchemaName;
char * PK_TableName;
char * FK_CatalogName;
char * FK_SchemaName;
char * FK_TableName;
{
    dTHR;
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;

    imp_sth->done_desc = 0;
    rc = SQLAllocStmt(imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
	dbmaker_error(sth, rc, "dbmaker_get_foreign_keys/SQLAllocStmt");
	return 0;
    }

    if (DBIS->debug >= 2)
	fprintf(DBILOGFP, "SQLForeignKeys: PK(%s.%s.%s), FK(%s.%s.%s)\n",
		XXSAFECHAR(PK_CatalogName), XXSAFECHAR(PK_SchemaName), 
		XXSAFECHAR(PK_TableName), XXSAFECHAR(FK_CatalogName),
		XXSAFECHAR(FK_SchemaName),XXSAFECHAR(PK_TableName));
    dbmaker_error(sth, rc, "dbmaker_foreignkey/SQLForeignKeys");
    
    rc = SQLForeignKeys(imp_sth->hstmt, 
			PK_CatalogName, strlen(PK_CatalogName), 
			PK_SchemaName, strlen(PK_SchemaName), 
			PK_TableName, strlen(PK_TableName), 
			FK_CatalogName, strlen(FK_CatalogName), 
			FK_SchemaName, strlen(FK_SchemaName), 
			FK_TableName, strlen(FK_TableName));
    if (!SQL_ok(rc)) {
	dbmaker_error(sth, rc, "dbmaker_get_foreign_keys/SQLForeignKeys");
	return 0;
    }
    return build_results(sth);
}

#if DBMAKER_FILE_INOUT
int
dbmaker_bind_col_to_file(sth, colno, file_prefix, fgOverwrite)
   SV *sth;
   int colno;
   char *file_prefix;
   int fgOverwrite;
{
    dTHR;
    D_imp_sth(sth);
    RETCODE rc;
    imp_fbh_t *fbh;
    struct stat  fbuf;
    int i, j, len1; /* #007 */

    if (colno == 0) {
	dbmaker_error(sth, SQL_ERROR,
		  "can not bind column 0 to a file");
	return 0;
    }
    
    fbh = &imp_sth->fbh[colno-1];
    
    if (strlen(file_prefix) > (MAX_FILE_NAME_LEN - MAX_DISPLAY_FILE_NUM))
        croak("file name length must not exceed %d", MAX_FILE_NAME_LEN - MAX_DISPLAY_FILE_NUM);
     
    if (fbh->ColDisplaySize <= MAX_FILE_NAME_LEN)
       {
       Newz(42, fbh->data, MAX_FILE_NAME_LEN, UCHAR);
       }

    fbh->ColDisplaySize = MAX_FILE_NAME_LEN-1;
    fbh->ftype = SQL_C_FILE;
    fbh->file_idxno = 0;
    imp_sth->fgBindColToFile = 1;
    len1 = strlen(file_prefix);

    /* #007 check file seperator '.' */
    for (j=0, i = len1-1; i > 0 && j < MAX_FILE_EXTENSION_LEN; i--,j++)
        {
        if (file_prefix[i] == '.' || file_prefix[i] == '\\' || file_prefix[i] == '/') 
           break;
        }
    
    if (file_prefix[i] == '.') /* #007 */
       {
       Newz(42, fbh->file_prefix, i+1, UCHAR);
       Newz(42, fbh->file_ext, len1-i+1, UCHAR);
       strncpy(fbh->file_prefix, file_prefix, i);
       fbh->file_prefix[i] = '\0';
       strcpy(fbh->file_ext, &file_prefix[i]);
       }
    else
       {
       Newz(42, fbh->file_prefix, len1+1, UCHAR);
       strcpy(fbh->file_prefix, file_prefix);
       fbh->file_ext = NULL;
       }

    sprintf(fbh->data, file_prefix);

    if (!fgOverwrite) /* #008 */
       {
       while (!stat(fbh->data, &fbuf))
          { 
          fbh->file_idxno++;
          if (fbh->file_ext)
             sprintf(fbh->data, "%s%d%s", fbh->file_prefix, fbh->file_idxno,fbh->file_ext);
          else
             sprintf(fbh->data, "%s%d", fbh->file_prefix, fbh->file_idxno);
          } while(!stat(fbh->data, &fbuf)); 
       }

    fbh->fgOverwrite = fgOverwrite; /* #008 */
    
    rc = SQLBindCol(imp_sth->hstmt,
	 colno,
         fbh->ftype,
         fbh->data,
         fbh->ColDisplaySize,
         &fbh->datalen);
    if (dbis->debug >= 2)
       fprintf(DBILOGFP, 
       "\tRebind/BindColToFile: col#%d to file:[%s] len(%d,%d)\n", colno, fbh->data,
        fbh->ColDisplaySize, fbh->datalen);
       
    if (!SQL_ok(rc)) {
	dbmaker_error(sth, rc, "dbmaker_bind_col_to_file/SQLBindColToFile");
	return 0;
    }

    return 1;
}
#endif
