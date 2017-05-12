/*
   engn/perldb2/dbdimp.c, engn_perldb2, db2_v82fp9, 1.10 04/09/19 17:14:24

   Copyright (c) 1995-2004 International Business Machines Corp.
*/

#include <stdio.h>
#include "DB2.h"
#ifndef AS400
#include "sqlenv.h"
#endif

#define EOI(x)  if (x < 0 || x == SQL_NO_DATA) return (FALSE)

/* These did not exist in the first release of DB2 v5.2 */
#ifndef SQL_ATTR_CONNECT_NODE
 #define SQL_ATTR_CONNECT_NODE 1290
#endif

#ifndef SQL_ATTR_DB2_SQLERRP
 #define SQL_ATTR_DB2_SQLERRP  2451
#endif

#ifndef SQL_ATTR_OPTIMIZE_FOR_NROWS
 #define SQL_ATTR_OPTIMIZE_FOR_NROWS 2450
#endif

#ifndef SQL_ATTR_QUERY_OPTIMIZATION_LEVEL
 #define SQL_ATTR_QUERY_OPTIMIZATION_LEVEL 1293
#endif

#ifndef SQL_DIAG_TOLERATED_ERROR
 #define SQL_DIAG_TOLERATED_ERROR 2559
#endif

SQLINTEGER istolerated = 0;

DBISTATE_DECLARE;

void dbd_init( dbistate_t *dbistate ) {
    	DBIS = dbistate;
}

/* ------------------------Error Handling Functions--------------*/

static SQLRETURN diagnoseError(SV* perlHandle, SQLSMALLINT handleType, SQLHANDLE handle, SQLRETURN rc, char* what)
{
	D_imp_xxh(perlHandle);
	switch(rc)
	{
		/*if(DBIc_TRACE_LEVEL(imp_xxh) >=3){*/
			case SQL_SUCCESS_WITH_INFO:
                                setErrorFromDiagRecInfo(perlHandle, handleType, handle, Nullch);
                                break;
			case SQL_NO_DATA_FOUND:
				setErrorFromDiagRecInfo(perlHandle, handleType, handle, "");
				break;
		/*}*/
		case SQL_ERROR:
			setErrorFromDiagRecInfo(perlHandle, handleType, handle, Nullch);
			break;
		case SQL_INVALID_HANDLE:
			if( what != NULL ) {
				setErrorFromString(perlHandle, rc, what);
			} else {
				setErrorFromString(perlHandle, rc, "");
			}
			break;
		default:
			what = what? what:"Unable to Diagnose Error - Please report";
			setErrorFromString(perlHandle, -3, what);
			break;
	}
	return rc;
}

static void setErrorFromDiagRecInfo( SV* perlHandle,
				SQLSMALLINT handleType,
				SQLHANDLE handle,
				char* err) {
	D_imp_xxh(perlHandle);
	SQLINTEGER sqlcode;
	SQLCHAR sqlstate[SQL_SQLSTATE_SIZE + 1];
	SQLCHAR msgBuffer[SQL_MAX_MESSAGE_LENGTH+1];
	SQLSMALLINT i = 1;
	SQLSMALLINT length;
	SQLRETURN returnCode;
	char* message = NULL;

	returnCode = SQLGetDiagRec( handleType,
                          handle,
                          i,
                          sqlstate,
                          &sqlcode,
                          msgBuffer,
                          (SQLSMALLINT)sizeof( msgBuffer ),
                          &length );
	if(returnCode == SQL_SUCCESS || returnCode == SQL_SUCCESS_WITH_INFO) {
		message = msgBuffer;
	} else {
		err = "";
		sqlcode = returnCode;
		strcpy( (char*)sqlstate, "00000" );
		if(DBIc_TRACE_LEVEL(imp_xxh) >= 3){
			switch(returnCode){
				case SQL_NO_DATA:
					message = "SQL_NO_DATA returned from Diagnostic Information. There might be no diagnostic records for this handle. Please see Infocentre for more details!!";
					break;
				case SQL_INVALID_HANDLE:
					message = "Invalid Handle Passed to retrieve Diagnostic Information";
					break;
				case SQL_ERROR:
					message = "SQL_ERROR encountered. Please see Infocenter for SQLGetDiagRec for More Details";
					break;
			}
		} else {
			message = "";
		}
	}
	DBIh_SET_ERR_CHAR(perlHandle, imp_xxh, err, sqlcode, message, sqlstate, Nullch);
}

static void setErrorFromString( SV* perlHandle, 
				SQLRETURN returnCode, 
		 		char* what)
{
	D_imp_xxh(perlHandle);
	SQLINTEGER sqlcode = returnCode;
	SQLCHAR sqlstate[SQL_SQLSTATE_SIZE + 1];
	DBIh_SET_ERR_CHAR(perlHandle, imp_xxh, Nullch, sqlcode, what, strcpy((char* )sqlstate, "00000"), Nullch);
}

static void fbh_dump( imp_fbh_t *fbh,
		int i ) {
    	PerlIO_printf( DBILOGFP, "fbh %d: '%s' %s, ",
			i, fbh->cbuf, (fbh->nullok) ? "NULLable" : "" );
    	PerlIO_printf( DBILOGFP, "type %d,  %ld, dsize %ld, p%d s%d\n",
			fbh->dbtype, (long)fbh->dsize, fbh->prec, fbh->scale );
    	PerlIO_printf( DBILOGFP, "   out: ftype %d, indp %d, bufl %d, rlen %d\n",
			fbh->ftype, fbh->indp, fbh->bufferSize, fbh->rlen );
}

static int SQLTypeIsLob( SQLSMALLINT SQLType ) {
      	if( SQL_BLOB == SQLType ||
		  	SQL_XML == SQLType ||
		  	SQL_CLOB == SQLType ||
		  	SQL_DBCLOB == SQLType )
	    	return TRUE;
	
      	return FALSE;
}

static int SQLTypeIsLong( SQLSMALLINT SQLType ) {
      	if( SQL_LONGVARBINARY == SQLType ||
		  	SQL_LONGVARCHAR == SQLType ||
		  	SQL_LONGVARGRAPHIC == SQLType ||
		  	SQL_BLOB == SQLType ||
		  	SQL_XML == SQLType ||
		  	SQL_CLOB == SQLType ||
		  	SQL_DBCLOB == SQLType )
	    	return TRUE;
	
      	return FALSE;
}

static int SQLTypeIsBinary( SQLSMALLINT SQLType ) {
#ifdef AS400
    	if(SQL_BLOB == SQLType)
	  	return FALSE;
#endif
	
      	if( SQL_BINARY == SQLType ||
		  	SQL_VARBINARY == SQLType ||
		  	SQL_LONGVARBINARY == SQLType ||
		  	SQL_BLOB == SQLType ||
		  	SQL_XML == SQLType)
	    	return TRUE;
	
       return FALSE;
}

static int SQLTypeIsGraphic( SQLSMALLINT SQLType ) {
      	if( SQL_GRAPHIC == SQLType ||
		  	SQL_VARGRAPHIC == SQLType ||
		  	SQL_LONGVARGRAPHIC == SQLType ||
		  	SQL_DBCLOB == SQLType )
	    	return TRUE;
	
      	return FALSE;
}

static int GetTrimmedSpaceLen( SQLCHAR *string, int len ) {
     	int i = 0;
     	int trimmedLen = 0;
     	int charLen;
	
     	if( !string || len <= 0 )
	  	return FALSE;
	
     	do {
	   	charLen = mblen( (char*)string + i, MB_CUR_MAX );
		
	   	if( charLen <= 0 ) /* invalid multi-byte character (<0) or embedded    */
			charLen = 1;    /* null (=0), just skip this byte                   */
		
	   	if( charLen > 1 || string[i] != ' ' )
		 	/* record length of string up to end of current character */
		 	trimmedLen = i + charLen;
		
	   	i += charLen;      /* advance to next character */
     	} while( i < len && charLen > 0 );
	
	
     	return trimmedLen;
}

/* ================================================================== */

#ifndef AS400
AV* dbd_data_sources( SV *drh ) {
  	AV *ds = newAV();
  	unsigned short dbHandle = 0;
  	unsigned short dbCount;
  	struct sqlca sqlca;
  	struct sqledinfo *dbBuffer;
  	const int prefixLen = 8;  /* length of 'dbi:DB2:' */
  	char buffer[ 8 + SQL_MAX_DSN_LENGTH + 1 ] = "dbi:DB2:";
	char description[255];
  	char *const pAlias = buffer + prefixLen;
  	SQLSMALLINT cbLen, desl;
    	SQLHANDLE henv;
  	SQLRETURN ret;

    ret = SQLAllocHandle( SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv ) ;
	if(ret != SQL_SUCCESS) {
      ret = -5; /*Set to a undefined value*/
      CHECK_ERROR(drh, 0, SQL_NULL_HANDLE, ret, "SQLAllocHandle failed while trying to retrieve list of datasources");
    }

    memset( pAlias, '\0', SQL_MAX_DSN_LENGTH + 1 );

    while ( 1 ) {
      ret = SQLDataSources( henv,
                                   SQL_FETCH_NEXT,
                                   pAlias,
                                   SQL_MAX_DSN_LENGTH + 1,
                                   &cbLen,
                                   description,
                                   255,
                                   &desl
                                 );
      if( ret == SQL_NO_DATA_FOUND) {
        break;
      }

      if(ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
        CHECK_ERROR(drh, 0, SQL_NULL_HANDLE, ret, "Datasources Fetch failed");
        break;
      }
      av_push( ds, newSVpv( buffer, prefixLen + cbLen ) );
    }
  	return ds;
}
#endif

/* ================================================================== */

static int dbd_db_connect( SV *dbh,
		imp_dbh_t *imp_dbh,
		SQLCHAR *dbname,
		SQLCHAR *uid,
		SQLCHAR *pwd,
		SV *attr ) {

	D_imp_drh_from_dbh;

	SQLRETURN ret;
	STRLEN length;
	SQLCHAR *new_dsn = NULL;
	int dsn_length;
	imp_dbh->hdbc = SQL_NULL_HDBC;
	ret = SQLAllocHandle(SQL_HANDLE_DBC, imp_drh->henv,
			&imp_dbh->hdbc);
	CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "DB handle allocation failed");
	if( SQL_SUCCESS != ret )
		goto exit;

      	if (DBIS->debug >= 2)
	    	PerlIO_printf( DBILOGFP,
	     			"connect '%s', '%s', '%s'", dbname, uid, pwd );
	
      	/*
	 * The SQL_ATTR_CONNECT_NODE and SQL_ATTR_LOGIN_TIMEOUT
	 * attribute must be set prior to establishing the
	 * connection:
	 * */
      	if( SvROK( attr ) && SvTYPE( SvRV( attr ) ) == SVt_PVHV )
      	{
	    	HV *attrh = (HV*)SvRV( attr );
	    	SV **pval;
		
	    	pval = hv_fetch( attrh, "db2_connect_node", 16, 0 );
	    	if( NULL != pval ) {
		  	ret = SQLSetConnectAttr( imp_dbh->hdbc,
	 				SQL_ATTR_CONNECT_NODE,
	 				(SQLPOINTER)SvIV( *pval ),
	 				0 );
			CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "DB Set Connect Node Failed");
		  	if( SQL_SUCCESS != ret )
				goto exit;
	    	}
		
	    	pval = hv_fetch( attrh, "db2_login_timeout", 17, 0 );
	    	if( NULL != pval ) {
		  	ret = SQLSetConnectAttr( imp_dbh->hdbc,
	 				SQL_ATTR_LOGIN_TIMEOUT,
	 				(SQLPOINTER)SvIV( *pval ),
	 				SQL_IS_INTEGER );
			CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Set Login TimeOUT Failed");
		  	if( SQL_SUCCESS != ret )
				goto exit;
	    	}
		
		pval = hv_fetch( attrh, "db2_trusted_context", 19, 0 );
	    	if( NULL != pval ) {
		  	ret = SQLSetConnectAttr( imp_dbh->hdbc,
	 				SQL_ATTR_USE_TRUSTED_CONTEXT,
	 				(SQLPOINTER)SvIV( *pval ),
	 				SQL_IS_INTEGER );
			CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Set Trusted Context Failed");
		  	if( SQL_SUCCESS != ret )
				goto exit;
	    	}
		pval = hv_fetch( attrh, "db2_info_programname", 20, 0 );
	    	if( NULL != pval ) {
			SQLPOINTER value = (SQLPOINTER)SvPV( *pval, length );
		  	ret = SQLSetConnectAttr( imp_dbh->hdbc,
	 				SQL_ATTR_INFO_PROGRAMNAME,
	 				value,
	 				(SQLINTEGER) length );
			CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Set Programname Failed");
		  	if( SQL_SUCCESS != ret )
				goto exit;
	    	}

      	}
	
      	/* If the string contains a =, use SQLDriverConnect */
      	if (strstr (dbname, "=") != NULL) {
	  	if (uid != NULL && strlen(uid) > 0) {
	      		if (strstr(dbname, ";uid=") == NULL && strstr(dbname, ";UID=") == NULL) {
		  		dsn_length = strlen(dbname) + strlen(uid) + strlen(pwd) + sizeof(";UID=;PWD=;")+1;
		  		new_dsn = (char *)malloc(sizeof(char)*dsn_length);
				CHECK_ERROR(dbh, 0, SQL_NULL_HANDLE, ret, "Unable to allocate DSN String");
				sprintf(new_dsn, "%s;UID=%s;PWD=%s;",dbname,uid,pwd);
		  		dbname = new_dsn;
	      		}
	  	}
	  	ret = SQLDriverConnect(imp_dbh->hdbc,(SQLHWND)NULL,dbname,SQL_NTS,NULL,0,NULL,SQL_DRIVER_NOPROMPT);
		CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Connect Failed");
	  	if (new_dsn != NULL) 
	      		free((void *)new_dsn);
      	} else {
	  	ret = SQLConnect(imp_dbh->hdbc,dbname,SQL_NTS,uid,SQL_NTS,pwd,SQL_NTS);
		CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Connect Failed");
	}
      	if( SQL_SUCCESS != ret )
	    	goto exit;

#ifdef CLI_DBC_SERVER_TYPE_DB2LUW
#ifdef SQL_ATTR_DECFLOAT_ROUNDING_MODE
	/**
	 * Code for setting SQL_ATTR_DECFLOAT_ROUNDING_MODE 
	 * for implementation of Decfloat Datatype
	 * */
        _db2_set_decfloat_rounding_mode_client(dbh, imp_dbh);
#endif
#endif
	
      	/* Set default value for LongReadLen */
      	DBIc_LongReadLen( imp_dbh ) = 32700;

exit:
      	if( SQL_SUCCESS != ret ) {
	     	if( SQL_NULL_HDBC != imp_dbh->hdbc )
		  	SQLFreeHandle( SQL_HANDLE_DBC, imp_dbh->hdbc );
		
    		if( 0 == imp_drh->connects ) {
			if( NULL != imp_drh->svNUM_OF_FIELDS ) {
				SvREFCNT_dec( imp_drh->svNUM_OF_FIELDS );
				imp_drh->svNUM_OF_FIELDS = NULL;
		  	}
		  	SQLFreeHandle( SQL_HANDLE_ENV, imp_drh->henv );
		  	imp_drh->henv = SQL_NULL_HENV;
	    	}
      	}
	
      	return ret;
}

#ifdef CLI_DBC_SERVER_TYPE_DB2LUW
#ifdef SQL_ATTR_DECFLOAT_ROUNDING_MODE
/**
 * Function for implementation of DECFLOAT Datatype
 * 
 * Description :
 * This function retrieves the value of special register decflt_rounding
 * from the database server which signifies the current rounding mode set
 * on the server. For using decfloat, the rounding mode has to be in sync
 * on the client as well as server. Thus we set here on the client, the
 * same rounding mode as the server.
 * @return: success or failure
 * */
static void _db2_set_decfloat_rounding_mode_client(SV* dbh, imp_dbh_t *imp_dbh) {
	SQLCHAR decflt_rounding[20];
	SQLHANDLE hstmt;
	SQLHDBC hdbc = imp_dbh->hdbc;
	int ret = 0;
	int rounding_mode;
	SQLINTEGER decfloat;
	
	SQLCHAR *stmt = (SQLCHAR *)"values current decfloat rounding mode";
	
	/* Allocate a Statement Handle */
	ret = SQLAllocHandle(SQL_HANDLE_STMT, (SQLHDBC) hdbc, &hstmt);
	CHECK_ERROR(dbh, SQL_HANDLE_STMT, hstmt, ret, "Statement Allocation Error");

	ret = SQLExecDirect((SQLHSTMT)hstmt, (SQLPOINTER)stmt, SQL_NTS);
	CHECK_ERROR(dbh, SQL_HANDLE_STMT, hstmt, ret, "Execute Direct Failed for the statement on Decfloat Rounding Mode");

	ret = SQLBindCol((SQLHSTMT)hstmt, 1, SQL_C_DEFAULT, decflt_rounding, 20, NULL);
	CHECK_ERROR(dbh, SQL_HANDLE_STMT, hstmt, ret, "BindCol Failed on Decfloat Rounding Mode");

	ret = SQLFetch(hstmt);
	ret = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
	/* Now setting up the same rounding mode on the client*/
	if(strcmp(decflt_rounding,"ROUND_HALF_EVEN")== 0) { rounding_mode = SQL_ROUND_HALF_EVEN };
	if(strcmp(decflt_rounding,"ROUND_HALF_UP")== 0) { rounding_mode = SQL_ROUND_HALF_UP };
	if(strcmp(decflt_rounding,"ROUND_DOWN")== 0) { rounding_mode = SQL_ROUND_DOWN };
	if(strcmp(decflt_rounding,"ROUND_CEILING")== 0) { rounding_mode = SQL_ROUND_CEILING };
	if(strcmp(decflt_rounding,"ROUND_FLOOR")== 0) { rounding_mode = SQL_ROUND_FLOOR };
#ifndef AS400
	ret = SQLSetConnectAttr(hdbc,SQL_ATTR_DECFLOAT_ROUNDING_MODE, (SQLPOINTER)rounding_mode ,SQL_NTS);
#else
	ret = SQLSetConnectAttr(hdbc,SQL_ATTR_DECFLOAT_ROUNDING_MODE,(SQLPOINTER)&rounding_mode ,SQL_NTS);
#endif
	return;
}
#endif
#endif

int dbd_db_login2( SV *dbh,
                   imp_dbh_t *imp_dbh,
                   char *dbname,
                   char *uid,
                   char *pwd,
                   SV *attr ) {
    	D_imp_drh_from_dbh;
    	SQLRETURN ret;
	
    	if (! imp_drh->connects) {
		ret = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE,
   				&imp_drh->henv);
		if(ret == SQL_ERROR) {
			/* I don't want to call SQLDiagRec since it would return an error
			 * instead I want to print my custom status message. Set ret = -3 */
			ret = -3;
		}
		CHECK_ERROR(dbh, SQL_HANDLE_ENV, imp_drh->henv, ret, 
				SQL_NULL_HENV == imp_drh->henv
				? "Total Environment allocation failure!  "
	      			"Did you set up your DB2 client environment?"
				: "Environment allocation failed" );
		EOI(ret);
		
#ifndef AS400
		
		/* If an application is run as an ODBC application, the         */
		/* SQL_ATTR_ODBC_VERSION environment attribute must be set;     */
		/* otherwise, an error will be returned when an attempt is      */
		/* made to allocate a connection handle.                        */
		ret = SQLSetEnvAttr( imp_drh->henv, SQL_ATTR_ODBC_VERSION,
   				(SQLPOINTER) SQL_OV_ODBC3, 0 );
		CHECK_ERROR(dbh, SQL_HANDLE_ENV, imp_drh->henv, ret, "SQLSetEnvAttr Failed");
		EOI(ret);
#endif
    	}
    	imp_dbh->henv = imp_drh->henv;
    	ret = dbd_db_connect( dbh,
			imp_dbh,
			(SQLCHAR*)dbname,
			(SQLCHAR*)uid,
			(SQLCHAR*)pwd,
			attr );
    	EOI(ret);
    	imp_drh->connects++;

    	DBIc_IMPSET_on(imp_dbh);    /* imp_dbh set up now            */
    	DBIc_ACTIVE_on(imp_dbh);    /* call disconnect before freeing    */
    	return TRUE;
}


int dbd_db_do( SV *dbh,
               char *statement ) { 
	/* error : <=(-2), ok row count : >=0, unknown count : (-1)   */
    
	D_imp_dbh(dbh);
    	SQLRETURN ret;
    	SQLINTEGER rows;
    	SQLHSTMT stmt;
	
    	ret = SQLAllocHandle( SQL_HANDLE_STMT, imp_dbh->hdbc, &stmt );
	CHECK_ERROR(dbh, SQL_HANDLE_STMT, stmt, ret, "Statement Allocation Error");
    	if (ret < 0)
		return(SQL_INVALID_HANDLE);
	
    	ret = SQLExecDirect(stmt, (SQLCHAR *)statement, SQL_NTS);
	CHECK_ERROR(dbh, SQL_HANDLE_STMT, stmt, ret, "Execute Immediate Failed");
	if (ret < 0)
		rows = -2;
    	else {
		ret = SQLRowCount(stmt, &rows);
		CHECK_ERROR(dbh, SQL_HANDLE_STMT, stmt, ret, "SQLRowCount Failed");
		if (ret < 0)
	    		rows = -1;
    	}
	
    	ret = SQLFreeHandle( SQL_HANDLE_STMT, stmt );
	CHECK_ERROR(dbh, SQL_HANDLE_STMT, stmt, ret, "Statement Destruction Error");
    	return (int)rows;
}


int dbd_db_ping( SV *dbh ) {
    	D_imp_dbh(dbh);
    	SQLRETURN ret;
    	SQLHSTMT stmt = SQL_NULL_HSTMT;
    	const char *pSQL = "values 1";
	
    	if( !DBIc_ACTIVE( imp_dbh ) )
	  	return FALSE;
	
    	if( '\0' == imp_dbh->sqlerrp[0] ) {
		SQLGetConnectAttr( imp_dbh->hdbc,
       				SQL_ATTR_DB2_SQLERRP,
       				(SQLPOINTER)imp_dbh->sqlerrp,
       				sizeof( imp_dbh->sqlerrp ),
       				NULL );
    	}
	
    	if( strncmp( imp_dbh->sqlerrp, "SQL", 3 ) == 0 )      /* UNO */ {
		/* Do nothing, use the default statement */
	}
    	else if( strncmp( imp_dbh->sqlerrp, "DSN", 3 ) == 0 ) /* MVS */	{
	  	pSQL = "select 1 from sysibm.sysdummy1";
    	}
    	else if( strncmp( imp_dbh->sqlerrp, "QSQ", 3 ) == 0 ) /* AS/400 */ {
	  	pSQL = "select 1 from qsys2.qsqptabl";
    	}
    	else if( strncmp( imp_dbh->sqlerrp, "ARI", 3 ) == 0 ) /* VM */ {
	  	pSQL = "select 1 from system.sysoptions";
    	}
    	else {
	  	/* Do nothing, use the default statement */
    	}
	
    	ret = SQLAllocHandle( SQL_HANDLE_STMT, imp_dbh->hdbc, &stmt );
	CHECK_ERROR(dbh, (SQLSMALLINT)(
	    			stmt == SQL_NULL_HSTMT ? SQL_HANDLE_DBC
				: SQL_HANDLE_STMT),
    			(SQLHANDLE)(
	    			stmt == SQL_NULL_HSTMT ? imp_dbh->hdbc
				: stmt), ret, "dbd_db_ping: Statement allocation error");
    	if( SQL_SUCCESS != ret )
	 	goto exit;
	
#ifndef AS400
    	ret = SQLSetStmtAttr( stmt,
			SQL_ATTR_DEFERRED_PREPARE,
			SQL_DEFERRED_PREPARE_OFF,
			0 );
	CHECK_ERROR(dbh, SQL_HANDLE_STMT, stmt, ret, "dbd_db_ping: Error turning off deferred prepare");
    	if( SQL_SUCCESS != ret )
	 	goto exit;
#endif
    	ret = SQLPrepare( stmt, (SQLCHAR*)pSQL, SQL_NTS );
	CHECK_ERROR(dbh, SQL_HANDLE_STMT, stmt, ret, "dbd_db_ping: Error preparing statement");
	
exit:
    	if( stmt )
	  	SQLFreeHandle( SQL_HANDLE_STMT, stmt );
	
    	/* If any error occured, check the state to determine if the cause */
    	/* is a broken connection.                                         */
    	if( SQL_SUCCESS != ret ) {
	  	STRLEN len;
	  	char *pState = SvPV( DBIc_STATE(imp_dbh), len );
		
	  	if( pState && len >= 5 &&
		      		( strncmp( pState, "08", 2 ) == 0 ||
		      		  strncmp( pState, "40003", 5 ) == 0 ) ) {
			/* ping should not throw an error when it detects a dead  */
			/* connection so reset error code and message but keep    */
			/* connection state                                       */
			sv_setsv( DBIc_ERRSTR(imp_dbh), &PL_sv_undef );
			sv_setsv( DBIc_ERR(imp_dbh), &PL_sv_undef );
			return FALSE; /* Connection is dead */
	  	}
    	}
	
    	return TRUE; /* Connection is still alive */
}

int dbd_db_commit( SV *dbh,
		imp_dbh_t *imp_dbh ) {

	SQLRETURN ret;
    	ret = SQLEndTran(SQL_HANDLE_DBC,imp_dbh->hdbc,SQL_COMMIT);
	CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Commit Failed");
    	EOI(ret);
    	return TRUE;
}

int dbd_db_rollback( SV *dbh,
		imp_dbh_t *imp_dbh ) {
    
	SQLRETURN ret;
    	ret = SQLEndTran(SQL_HANDLE_DBC,imp_dbh->hdbc,SQL_ROLLBACK);
	CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Rollback Failed")
    	EOI(ret);
    	return TRUE;
}

int dbd_db_disconnect( SV *dbh,
		imp_dbh_t *imp_dbh ) {
	D_imp_drh_from_dbh;

	SQLRETURN ret;
	ret = SQLDisconnect(imp_dbh->hdbc);
	CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Disconnect Failed");
    	EOI(ret);
	
    	/* Only turn off the ACTIVE attribute of the database handle        */
    	/* if SQLDisconnect() was successful.  If it wasn't successful,     */
    	/* we still have a connection!                                      */
	
    	DBIc_ACTIVE_off(imp_dbh);
	
    	ret = SQLFreeHandle( SQL_HANDLE_DBC, imp_dbh->hdbc );
	CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Free Connect Failed");

	EOI(ret);
	
    	imp_dbh->hdbc = SQL_NULL_HDBC;
    	imp_drh->connects--;
    	if (imp_drh->connects == 0) {
	  	if( NULL != imp_drh->svNUM_OF_FIELDS ) {
			SvREFCNT_dec( imp_drh->svNUM_OF_FIELDS );
			imp_drh->svNUM_OF_FIELDS = NULL;
	  	}
	  	ret = SQLFreeHandle( SQL_HANDLE_ENV, imp_drh->henv );
		CHECK_ERROR(dbh, SQL_HANDLE_ENV, imp_drh->henv, ret, "Free HENV Failed");
	  	EOI(ret);
      		imp_drh->henv = SQL_NULL_HENV;
    	}
	
    	/* We don't free imp_dbh since a reference still exists    */
    	/* The DESTROY method is the only one to 'free' memory.    */
    	/* Note that statement objects may still exist for this dbh!    */
    	return TRUE;
}

void dbd_db_destroy( SV *dbh,
		imp_dbh_t *imp_dbh ) {
    	if (DBIc_ACTIVE(imp_dbh))
		dbd_db_disconnect(dbh,imp_dbh);
    	/* Nothing in imp_dbh to be freed    */
    	DBIc_IMPSET_off(imp_dbh);
}

static SQLINTEGER getConnectAttr( char *key,
		STRLEN keylen ) {
      	/*
	 * The following DB2 CLI connection attributes are not supported
	 * SQL_ATTR_ASYNC_ENABLE        Doesn't make sense for DBD::DB2
	 * SQL_ATTR_AUTO_IPD            Doesn't make sense for DBD::DB2
	 * SQL_ATTR_CONNECTION_DEAD     not reliable, $dbh->ping is better
	 * SQL_ATTR_CONNECTTYPE         2-phase commit not supported
	 * SQL_ATTR_CONN_CONTEXT        Doesn't make sense for DBD::DB2
	 * SQL_ATTR_ENLIST_IN_DTC       Doesn't make sense for DBD::DB2
	 * SQL_ATTR_MAXCONN             For NetBIOS
	 * SQL_ATTR_OPTIMIZE_SQLCOLUMNS
	 * SQL_ATTR_SYNC_POINT          2-phase commit not supported
	 * SQL_ATTR_TRANSLATE_LIB       Not supported by DB2 CLI
	 * SQL_ATTR_TRANSLATE_OPTION    Not supported by DB2 CLI
	 * SQL_ATTR_WCHARTYPE           Doesn't make sense for DBD::DB2
	 * */

      	/* For better performance, the keys are sorted by length */
      	switch( keylen )
      	{
	    	case 10:
		  	if(      strEQ( key, "AutoCommit" ) )
				return SQL_ATTR_AUTOCOMMIT;
		  	return SQL_ERROR;
			
	    	case 11:
		  	if(      strEQ( key, "db2_sqlerrp" ) )
				return SQL_ATTR_DB2_SQLERRP;
		  	return SQL_ERROR;
			
#ifndef AS400
	    	case 13:
		  	if(      strEQ( key, "db2_clischema" ) )
				return SQL_ATTR_CLISCHEMA;
		  	return SQL_ERROR;
			
	    	case 14:
		  	if(      strEQ( key, "db2_db2explain" ) )
				return SQL_ATTR_DB2EXPLAIN;
		  	else if( strEQ( key, "db2_quiet_mode" ) )
				return SQL_ATTR_QUIET_MODE;
		  	else if( strEQ( key, "db2_set_schema" ) )
				return SQL_ATTR_SET_SCHEMA;
		  	return SQL_ERROR;
#endif
			
	    	case 15:
		  	if(      strEQ( key, "db2_access_mode" ) )
				return SQL_ATTR_ACCESS_MODE;
#ifndef AS400
		  	else if( strEQ( key, "db2_db2estimate" ) )
				return SQL_ATTR_DB2ESTIMATE;
		  	else if( strEQ( key, "db2_info_userid" ) )
				return SQL_ATTR_INFO_USERID;
#endif
		  	return SQL_ERROR;
			
	    	case 16:
		  	if(      strEQ( key, "db2_connect_node" ) )
				return SQL_ATTR_CONNECT_NODE;
#ifndef AS400
		  	else if( strEQ( key, "db2_info_acctstr" ) )
				return SQL_ATTR_INFO_ACCTSTR;
#endif
	      		else if( strEQ( key, "db2_trusted_user" ) )
				return SQL_ATTR_TRUSTED_CONTEXT_USERID;
		  	return SQL_ERROR;
			
#ifndef AS400
	    	case 17:
		  	if(      strEQ( key, "db2_info_applname" ) )
				return SQL_ATTR_INFO_APPLNAME;
		  	else if( strEQ( key, "db2_login_timeout" ) )
				return SQL_ATTR_LOGIN_TIMEOUT;
		  	else if( strEQ( key, "db2_txn_isolation" ) )
				return SQL_ATTR_TXN_ISOLATION;
		  	return SQL_ERROR;
			
	    	case 18:
		  	if(      strEQ( key, "db2_close_behavior" ) )
				return SQL_ATTR_CLOSE_BEHAVIOR;
		  	else if( strEQ( key, "db2_current_schema" ) )
				return SQL_ATTR_CURRENT_SCHEMA;
		  	return SQL_ERROR;
#endif
			
	    	case 19:
		  	if(      strEQ( key, "db2_trusted_context" ) )
				return SQL_ATTR_USE_TRUSTED_CONTEXT;
#ifndef AS400
	      		else if( strEQ( key, "db2_info_wrkstnname" ) )
				return SQL_ATTR_INFO_WRKSTNNAME;
		  	else if( strEQ( key, "db2_longdata_compat" ) )
				return SQL_ATTR_LONGDATA_COMPAT;
#endif
		  	return SQL_ERROR;
			
	    	case 20:      
		  	if(      strEQ( key, "db2_trusted_password" ) )
				return SQL_ATTR_TRUSTED_CONTEXT_PASSWORD;
			else if( strEQ( key, "db2_info_programname" ) )
				return SQL_ATTR_INFO_PROGRAMNAME;
		  	return SQL_ERROR;
			
	    	default:
		  	return SQL_ERROR;
      	}
}

int dbd_db_STORE_attrib( SV *dbh,
		imp_dbh_t *imp_dbh,
		SV *keysv,
		SV *valuesv ) {
      	
	STRLEN kl;
      	char *key = SvPV( keysv, kl );
      	char setSchemaSQL[BUFSIZ];
      	SQLHSTMT hstmt;
	SQLINTEGER Attribute = getConnectAttr( key, kl );
      	SQLRETURN ret;
#ifndef AS400
      	SQLPOINTER ValuePtr = 0;
#else
      	SQLPOINTER ValuePtr = 8;
#endif
      	SQLINTEGER StringLength = 0;
      	char msg[128]; /* buffer for error messages */
#ifdef AS400
      	SQLINTEGER param;
#endif
	
      	if( Attribute < 0 ) /* Don't know what this attribute is */
	    	return FALSE;
	
      	switch( Attribute ) {
	    	/* Booleans */
#ifndef AS400
	    	case SQL_ATTR_AUTOCOMMIT:
	    	case SQL_ATTR_LONGDATA_COMPAT:
		  	if( SvTRUE( valuesv ) )
				ValuePtr = (SQLPOINTER)1;
		  	break;
#else
	    	case SQL_ATTR_AUTOCOMMIT:
		  	param = SQL_AUTOCOMMIT_ON;
		  	if( SvTRUE( valuesv ) )
				ValuePtr = (SQLPOINTER)&param;
		  	break;
#endif
			
		    	/* Strings */
#ifndef AS400
	    	case SQL_ATTR_SET_SCHEMA:
		  	if( SvOK( valuesv ) ) {
				STRLEN vl;
				ValuePtr = (SQLPOINTER)SvPV( valuesv, vl );
				StringLength = (SQLINTEGER)vl;
		  	}
		  	ret = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &hstmt);
			CHECK_ERROR(dbh, SQL_HANDLE_STMT, hstmt, ret, "Statement Handle Allocation Error")
		  	if( SQL_SUCCESS != ret )
		  	{
				sprintf( msg, "Error setting %s connection attribute", key );
				CHECK_ERROR(dbh, SQL_HANDLE_STMT, hstmt, ret, msg);
				return FALSE;
		  	}
		  	sprintf(setSchemaSQL, "SET CURRENT SCHEMA = '%s'", ValuePtr);
			
		  	ret = SQLExecDirect(hstmt, (SQLCHAR *)setSchemaSQL, SQL_NTS);
			CHECK_ERROR(dbh, SQL_HANDLE_STMT, hstmt, ret, "Execute immediate failed");
		  	SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
		  	break;
#endif
		case SQL_ATTR_TRUSTED_CONTEXT_USERID:
		case SQL_ATTR_TRUSTED_CONTEXT_PASSWORD:
#ifndef AS400
	    	case SQL_ATTR_CLISCHEMA:
	    	case SQL_ATTR_CURRENT_SCHEMA:
	    	case SQL_ATTR_INFO_ACCTSTR:
	    	case SQL_ATTR_INFO_APPLNAME:
		case SQL_ATTR_INFO_PROGRAMNAME:
	    	case SQL_ATTR_INFO_USERID:
	    	case SQL_ATTR_INFO_WRKSTNNAME:
#endif
		  	if( SvOK( valuesv ) ) {
				STRLEN vl;
				ValuePtr = (SQLPOINTER)SvPV( valuesv, vl );
				StringLength = (SQLINTEGER)vl;
		  	}
		  	break;
			
		    	/* Integers */
	    	case SQL_ATTR_ACCESS_MODE:
		case SQL_ATTR_USE_TRUSTED_CONTEXT:
#ifndef AS400
	    	case SQL_ATTR_CLOSE_BEHAVIOR:
#endif
	    	case SQL_ATTR_CONNECT_NODE:
#ifndef AS400
	    	case SQL_ATTR_DB2ESTIMATE:
	    	case SQL_ATTR_DB2EXPLAIN:
	    	case SQL_ATTR_LOGIN_TIMEOUT:
	    	case SQL_ATTR_QUIET_MODE:
	    	case SQL_ATTR_TXN_ISOLATION:
#endif
		  	if( SvIOK( valuesv ) ) {
				ValuePtr = (SQLPOINTER)SvIV( valuesv );
		  	}
		  	else if( SvOK( valuesv ) ) {
				/* Value is not an integer, return error */
				sprintf( msg,
			       			"Invalid value for connection attribute %s, expecting integer",
						key );
				ret = -1;
				CHECK_ERROR(dbh, 0, SQL_NULL_HANDLE, ret, msg);
				return FALSE;
		  	}
#ifndef AS400
		  	else /* Undefined, Set to default, most are 0 or NULL */
			{
				if( SQL_ATTR_TXN_ISOLATION == Attribute )
					ValuePtr = (SQLPOINTER)SQL_TXN_READ_COMMITTED;
		  	}
#endif
		  	break;
			
	    	default:
		  	return FALSE;
      	}
	
      	if (  Attribute != SQL_ATTR_SET_SCHEMA && 
			Attribute != SQL_ATTR_LOGIN_TIMEOUT && 
			Attribute != SQL_ATTR_USE_TRUSTED_CONTEXT ) {
	    	ret = SQLSetConnectAttr( imp_dbh->hdbc,
   				Attribute,
   				ValuePtr,
   				StringLength );
	    	if( SQL_SUCCESS != ret ) {
		  	sprintf( msg, "Error setting %s connection attribute", key );
			CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, msg);
		  	return FALSE;
	    	}
		
      	}
	
      	if( SQL_ATTR_AUTOCOMMIT == Attribute ) {
	    	DBIc_set( imp_dbh, DBIcf_AutoCommit, SvTRUE( valuesv ) );
      	}
	
      	return TRUE;
}


SV *dbd_db_FETCH_attrib( SV *dbh,
		imp_dbh_t *imp_dbh,
		SV *keysv ) {
      	STRLEN kl;
      	char *key = SvPV( keysv, kl );
      	SQLINTEGER Attribute = getConnectAttr( key, kl );
      	SV *retsv = NULL;
      	SQLRETURN ret;
      	char buffer[128]; /* should be big enough for any attribute value */
      	SQLPOINTER ValuePtr = (SQLPOINTER)buffer;
      	SQLINTEGER BufferLength = sizeof( buffer );
      	SQLINTEGER StringLength;
	
      	/* We convert SQL_ATTR_SET_SCHEMA to SQL_ATTR_CURRENT_SCHEMA
	 *   since that is supported by CLI and enables us to call SQLGetConnectAttr */
      	if( Attribute == 2579) {
		Attribute = 1254;
      	}
	
      	if( Attribute < 0 ) /* Don't know what this attribute is */
	    	return NULL;
	
      	ret = SQLGetConnectAttr( imp_dbh->hdbc,
			Attribute,
			ValuePtr,
			BufferLength,
			&StringLength );
      	if( SQL_SUCCESS_WITH_INFO == ret &&
		  	(StringLength + 1) > BufferLength ) {
	    	/* local buffer isn't big enough, allocate one */
	    	BufferLength = StringLength + 1;
	    	Newc( 1, ValuePtr, BufferLength, char, SQLPOINTER );
	    	ret = SQLGetConnectAttr( imp_dbh->hdbc,
   				Attribute,
   				ValuePtr,
   				BufferLength,
   				&StringLength );
      	}
	
	CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Error Retrieving Connection Attribute");
      	if( SQL_SUCCESS == ret ) {
		switch( Attribute )
	    	{
		  	/* Booleans */
		  	case SQL_ATTR_AUTOCOMMIT:
#ifndef AS400
		  	case SQL_ATTR_LONGDATA_COMPAT:
#endif
				if( *(SQLINTEGER*)ValuePtr )
			      		retsv = &PL_sv_yes;
				else
			      		retsv = &PL_sv_no;
				break;
      				/* Strings */
#ifndef AS400
		  	case SQL_ATTR_CURRENT_SCHEMA:
				/* Due to a DB2 CLI bug, a StringLength of 1 is returned */
				/* for current schema when it should return 0.  However, */
				/* the first byte is correctly set to 0 so we need to    */
				/* check that to distinguish an empty string from a 1    */
				/* byte string.                                          */
				if( 1 == StringLength && '\0' == ((char*)ValuePtr)[0] )
			      		StringLength = 0;
				/* don't break, fall through to regular string processing */
		  	case SQL_ATTR_CLISCHEMA:
#endif
		  	case SQL_ATTR_DB2_SQLERRP:
		  	case SQL_ATTR_SET_SCHEMA:
	      		case SQL_ATTR_TRUSTED_CONTEXT_USERID:
#ifndef AS400
		  	case SQL_ATTR_INFO_ACCTSTR:
		  	case SQL_ATTR_INFO_APPLNAME:
			case SQL_ATTR_INFO_PROGRAMNAME:
		  	case SQL_ATTR_INFO_USERID:
		  	case SQL_ATTR_INFO_WRKSTNNAME:
#endif
				retsv = sv_2mortal( newSVpv( (char*)ValuePtr, (int)StringLength ) );
				break;
				
			  	/* Integers */
		  	case SQL_ATTR_ACCESS_MODE:
	      		case SQL_ATTR_USE_TRUSTED_CONTEXT:
#ifndef AS400
		  	case SQL_ATTR_CLOSE_BEHAVIOR:
		  	case SQL_ATTR_CONNECT_NODE:
		  	case SQL_ATTR_DB2ESTIMATE:
		  	case SQL_ATTR_DB2EXPLAIN:
		  	case SQL_ATTR_LOGIN_TIMEOUT:
		  	case SQL_ATTR_QUIET_MODE:
		  	case SQL_ATTR_TXN_ISOLATION:
#endif
				retsv = sv_2mortal( newSViv( (IV)( *(SQLINTEGER*)ValuePtr ) ) );
				break;
				
		  	default:
				break;
	    	}
      	}

	if( ValuePtr != (SQLPOINTER)buffer )
	    	Safefree( ValuePtr );  /* Free dynamically allocated buffer */
	
      	return retsv;
}

static SQLRETURN bind_lob_column_helper( imp_fbh_t *fbh, SQLINTEGER col_num ) {
  switch( fbh->dbtype ) {
    case SQL_CLOB:
      fbh->loc_type   =  SQL_CLOB_LOCATOR;
      fbh->bufferSize = 0;

      return SQLBindCol( fbh->imp_sth->phstmt,
                    (SQLUSMALLINT) col_num,
                    fbh->loc_type,
                    &fbh->lob_loc,
                    4,
                    &fbh->loc_ind );

    case SQL_BLOB:
      fbh->loc_type   =  SQL_BLOB_LOCATOR;
      fbh->bufferSize = 0;

      return SQLBindCol( fbh->imp_sth->phstmt,
                    (SQLUSMALLINT) col_num,
                    fbh->loc_type,
                    &fbh->lob_loc,
                    4,
                    &fbh->loc_ind );

    case SQL_DBCLOB:
      fbh->loc_type =  SQL_DBCLOB_LOCATOR;
      fbh->bufferSize = 0;

      return SQLBindCol( fbh->imp_sth->phstmt,
                    (SQLUSMALLINT) col_num,
                    fbh->loc_type,
                    &fbh->lob_loc,
                    4,
                    &fbh->loc_ind );

    case SQL_XML:
      fbh->ftype = SQL_C_BINARY;
      fbh->rlen  = fbh->bufferSize = fbh->dsize = 0;
      return SQL_SUCCESS;
  }
}

static int dbd_describe( SV *sth,
		imp_sth_t *imp_sth ) {

        D_imp_dbh_from_sth;
    	SQLCHAR  *cbuf_ptr;
    	SQLINTEGER t_cbufl=0;
    	short num_fields;
    	SQLINTEGER i;
    	SQLRETURN ret;
    	imp_fbh_t *fbh;
    	SQLINTEGER bufferSizeRequired;
	
    	SV *retsv = &PL_sv_undef;
    	char buffer[256];
    	SQLPOINTER valuePtr = (SQLPOINTER)buffer;
    	SQLSMALLINT bufferLength = sizeof( buffer );
    	SQLSMALLINT stringLength;
    	int app_codepage;
    	int db_codepage;
	
    	memset( &buffer, '\0', sizeof( buffer ) );
	
    	if (imp_sth->done_desc)
		return TRUE;    /* success, already done it */
	
    	ret = SQLNumResultCols(imp_sth->phstmt,&num_fields);
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLNumResultCols Failed");
    	EOI(ret);
	
    	/* If execute hasn't been called yet and num_fields is zero it */
    	/* might mean that this is a CALL statement in which case we   */
    	/* must wait until after the execute to describe.  Just return */
    	/* without setting done_desc flag.                             */
    	if( 0 == num_fields && !DBIc_ACTIVE( imp_sth ) )
	  	return TRUE;
	
    	imp_sth->done_desc = 1;
	
    	/* Unbind previously bound columns */
    	if( DBIc_NUM_FIELDS( imp_sth ) > 0 ) {
	  	ret = SQLFreeStmt( imp_sth->phstmt, SQL_UNBIND );
		CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Error Unbinding Previous Columns");
	  	EOI(ret);
    	}
	
    	if( DBIc_NUM_FIELDS( imp_sth ) != num_fields ) {
		/* DBI normally doesn't allow NUM_OF_FIELDS to be changed but I can */
	  	/* fool it by setting NUM_FIELDS to 0 first                         */
	  	D_imp_drh_from_dbh;
	  	SV *value = newSViv( num_fields );
		
	  	if( NULL == imp_drh->svNUM_OF_FIELDS ) {
			imp_drh->svNUM_OF_FIELDS = newSVpv( "NUM_OF_FIELDS", 13 );
	  	}
		
	  	DBIc_NUM_FIELDS(imp_sth) = num_fields;
		if(DBIc_FIELDS_AV(imp_sth)) {
                        sv_free((SV*) DBIc_FIELDS_AV(imp_sth));
                        DBIc_FIELDS_AV(imp_sth) = Nullav;
                }
	  	SvREFCNT_dec( value );
    	}
	
    	if( 0 == num_fields )
	  	return TRUE; /* Let's get out of here, nothing to do */
	
    	/* allocate field buffers if necessary */
    	if( num_fields > imp_sth->numFieldsAllocated ) {
	  	if( imp_sth->numFieldsAllocated > 0 ) {
			/* already have some fields allocated */
			Renew( imp_sth->fbh, num_fields, imp_fbh_t );
			/* zero out new fields */
			Zero( imp_sth->fbh + imp_sth->numFieldsAllocated,
			  		num_fields - imp_sth->numFieldsAllocated,
			  		imp_fbh_t );
	  	}
	  	else {
			Safefree(imp_sth->fbh);
			Newz( 42, imp_sth->fbh, num_fields, imp_fbh_t );
	  	}
		
	  	/* allocate a buffer to hold all the column names    */
	  	Safefree(imp_sth->fbh_cbuf);
	  	Newz(42, imp_sth->fbh_cbuf,
		      		(num_fields * (MAX_COL_NAME_LEN+1)), SQLCHAR );
		
	  	imp_sth->numFieldsAllocated = num_fields;
    	}
    	cbuf_ptr = imp_sth->fbh_cbuf;
	
    	/* Get number of fields and space needed for field names    */
    	for(i=0; i < num_fields; ++i ) {
	  	  fbh = &imp_sth->fbh[i];
	  	  fbh->cbufl = MAX_COL_NAME_LEN+1;
	  	  bufferSizeRequired = 0;
	    	/* Get number of fields and space needed for field names    */
		
	  	  ret = SQLDescribeCol( imp_sth->phstmt,
    				(SQLUSMALLINT) (i+1),
    				(SQLCHAR*) cbuf_ptr,
    				(SQLSMALLINT) MAX_COL_NAME_LEN,
    				(SQLSMALLINT*)&fbh->cbufl,
    				(SQLSMALLINT*)&fbh->dbtype,
    				(SQLUINTEGER*)&fbh->prec,
    				(SQLSMALLINT*)&fbh->scale,
    				(SQLSMALLINT*)&fbh->nullok );
		  CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "DescribeCol Failed");
	  	  EOI(ret);
	  	  fbh->imp_sth = imp_sth;
	  	  fbh->cbuf    = cbuf_ptr;
	  	  fbh->cbuf[fbh->cbufl] = '\0';     /* ensure null terminated    */
	  	  cbuf_ptr += fbh->cbufl + 1;       /* increment name pointer    */
	  	  /* Now define the storage for this field data.            */
		
#ifdef AS400
	  	  if( SQL_SMALLINT == fbh->dbtype ||
		      		SQL_INTEGER == fbh->dbtype) {
	      		fbh->ftype = SQL_C_LONG;
	      		fbh->rlen = bufferSizeRequired = sizeof(SQLINTEGER);
		  }
	  	  else if( SQL_DECIMAL == fbh->dbtype ||
		 		SQL_NUMERIC == fbh->dbtype ||
		 		SQL_DOUBLE == fbh->dbtype||
		 		SQL_FLOAT == fbh->dbtype||
		 		SQL_REAL == fbh->dbtype) {
	      		fbh->ftype = SQL_C_DOUBLE;
	      		fbh->rlen = bufferSizeRequired = sizeof(SQLDOUBLE);
		  }
	  	  else if(SQL_BLOB == fbh->dbtype ||	
      				SQL_CLOB == fbh->dbtype ||
		  		SQL_DBCLOB == fbh->dbtype) {
	      		fbh->ftype = fbh->dbtype;
	  		fbh->rlen = bufferSizeRequired = fbh->dsize = fbh->prec;
		  }
	  	  else if (SQL_XML == fbh->dbtype) {
	      		fbh->ftype = SQL_C_BINARY;
	      		fbh->rlen = bufferSizeRequired = fbh->dsize = -1;
		  }
          else
#endif
		
          if( SQL_BINARY == fbh->dbtype ||
               SQL_VARBINARY == fbh->dbtype ||
                 SQL_LONGVARBINARY == fbh->dbtype ||
                    SQL_BLOB == fbh->dbtype) {
              fbh->ftype = SQL_C_BINARY;
              fbh->rlen = bufferSizeRequired = fbh->dsize = fbh->prec;
          } else {
			  if( !SQLTypeIsLob( fbh->dbtype ) ) {
                fbh->ftype = SQL_C_CHAR;
#ifdef AS400
                ret = SQLColAttributes( imp_sth->phstmt,
                      i+1,
                      SQL_DESC_DISPLAY_SIZE,
                      NULL,
                      0,
                      NULL,
                      &fbh->dsize );
#else
                ret = SQLColAttribute( imp_sth->phstmt,
                      (SQLSMALLINT) (i+1),
                      SQL_DESC_DISPLAY_SIZE,
                      NULL,
                      0,
                      NULL,
                      &fbh->dsize );
#endif
                CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "ColAttribute Failed");
                EOI(ret);

                ret = SQLGetInfo( imp_dbh->hdbc,
                      SQL_DATABASE_CODEPAGE,
                      valuePtr,
                      bufferLength,
                      &stringLength );

                if( ret == SQL_SUCCESS_WITH_INFO &&  bufferLength < (stringLength + 1) ) {
                  if( DBIS->debug >= 2) {
                    PerlIO_printf( DBILOGFP,
                                   "GetInfo(%d) local buffer isn't big enough. stringlength=%d\n",
                                   SQL_DATABASE_CODEPAGE, stringLength );
                  }
                  /* Local buffer isn't big enough, dynamically allocate new one */
                  bufferLength = stringLength + 1;
                  Safefree(valuePtr);
                  Newc( 1, valuePtr, bufferLength, char, SQLPOINTER );
                  Zero( valuePtr, bufferLength, char );

                  ret = SQLGetInfo( imp_dbh->hdbc,
                                    SQL_DATABASE_CODEPAGE,
                                    valuePtr,
                                    bufferLength,
                                    &stringLength );
                }

                CHECK_ERROR(sth, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Error Calling SQLGetInfo");

                if( ret == SQL_SUCCESS) {
                  db_codepage = *(int *)valuePtr;
                  retsv = sv_2mortal( newSViv( (I32)( *(SQLINTEGER*)valuePtr) ) );
                }

                ret = SQLGetInfo( imp_dbh->hdbc,
                                  SQL_APPLICATION_CODEPAGE,
                                  valuePtr,
                                  bufferLength,
                                  &stringLength );
					
                if( ret == SQL_SUCCESS_WITH_INFO &&  bufferLength < (stringLength + 1) ) {
                  if( DBIS->debug >= 2) {
                     PerlIO_printf( DBILOGFP,
                                    "GetInfo(%d) local buffer isn't big enough. stringlength=%d\n",
                                    SQL_APPLICATION_CODEPAGE, stringLength );
                  }
						
                  /* Local buffer isn't big enough, dynamically allocate new one */
                  bufferLength = stringLength + 1;
                  Safefree(valuePtr);
                  Newc( 1, valuePtr, bufferLength, char, SQLPOINTER );
                  Zero( valuePtr, bufferLength, char );
						
                  ret = SQLGetInfo( imp_dbh->hdbc,
                                    SQL_APPLICATION_CODEPAGE,
                                    valuePtr,
                                    bufferLength,
                                    &stringLength );
                }
					
                CHECK_ERROR(sth, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Error Calling SQLGetInfo");

                if( ret == SQL_SUCCESS) {
                  app_codepage = *(int *)valuePtr; 
                  retsv = sv_2mortal( newSViv( (I32)( *(SQLINTEGER*)valuePtr) ) );
                }
					
                if ( app_codepage != db_codepage) {
                  fbh->rlen = bufferSizeRequired = (4*fbh->dsize)+1;/* +1: STRING null terminator */
                } else {
                  fbh->rlen = bufferSizeRequired = fbh->dsize+1;/* +1: STRING null terminator */
                }
            }
		  }
		
	  	  /* Limit buffer size based on LongReadLen for long column types */
          if( SQLTypeIsLob( fbh->dbtype ) ) {
              ret = bind_lob_column_helper( fbh, i+1 );
          } else {
              if( SQLTypeIsLong( fbh->dbtype ) ) {
                unsigned int longReadLen = DBIc_LongReadLen( imp_sth );
                if( fbh->rlen > (int) longReadLen ) {
                  if( SQL_LONGVARBINARY == fbh->dbtype ||
                      0 == longReadLen )
                    fbh->rlen = bufferSizeRequired = longReadLen;
                  else
                    fbh->rlen = bufferSizeRequired = longReadLen+1; /* +1 for null terminator */
                }
			  }
              /* Allocate output buffer */
              if( bufferSizeRequired > fbh->bufferSize ) {
                  fbh->bufferSize = bufferSizeRequired;
                  Safefree(fbh->buffer);
                  Newc( 1, fbh->buffer, fbh->bufferSize, SQLCHAR, void* );
              }
		
              /* BIND */
              ret = SQLBindCol( imp_sth->phstmt,
                    (SQLUSMALLINT) (i+1),
                    fbh->ftype,
                    fbh->buffer,
                    fbh->bufferSize,
                    &fbh->rlen );
		  }

          if (ret == SQL_SUCCESS_WITH_INFO ) {
              warn("BindCol error on %s: %d", fbh->cbuf);
          } else {
              CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "BindCol Failed");
              EOI(ret);
          }
		
          if (DBIS->debug >= 2)
            fbh_dump(fbh, i);
        }
        return TRUE;
}

static void dbd_preparse( imp_sth_t *imp_sth,
		char *statement ) {
	bool in_literal = FALSE;
	SQLCHAR  *src, *start, *dest;
	phs_t phs_tpl;
	SV *phs_sv;
	int idx=0, style=0 ;
	
	float num_placeholders = 0;
	int num_bytes_required = 0, num_digits = 0;

	/*
 	 * Calculate the number of bytes required according to number 
 	 * of Placeholders. The placeholders ?
 	 * are converted to :pn where n denotes nth placeholder
 	 * ex:- 200th ? is converted to :p200
 	 * */

	num_bytes_required = strlen(statement) + DBIc_NUM_PARAMS(imp_sth) * 2;
	num_placeholders = (double)DBIc_NUM_PARAMS(imp_sth);
	while(num_placeholders >=1) {
		num_placeholders /= 10.0;
		num_digits++;
	}
	num_bytes_required += DBIc_NUM_PARAMS(imp_sth) * num_digits;
	
	/* allocate room for copy of statement with spare capacity */
	/* for editing ':1' into ':p1' */
	imp_sth->statement = (SQLCHAR *)safemalloc(num_bytes_required);
	
	/* initialise phs ready to be cloned per placeholder    */
	memset(&phs_tpl, '\0',sizeof(phs_tpl));
	phs_tpl.sv = NULL;
	src  = (SQLCHAR *)statement;
	dest = imp_sth->statement;
	while(*src) {
		if( *src == '/' ) {
			*dest++ = *src++;
			if( *src ) {
				if( *src == '*' ) {
					/* Start of a comment */
					if( DBIS->debug >= 2 ) {
						PerlIO_printf( DBILOGFP, "Start of comment: %s\n", src );
					}
					*dest++ = *src++;
					/* Skip everything until we hit end of comment */
					while( *src ) {
						if( *src == '*' ) {
							*dest++ = *src++;
							if( *src ) {
								if( *src == '/' ) {
									/* Found end of commented */
									*dest++ = *src++;
									if( DBIS->debug >= 2 ) {
										PerlIO_printf( DBILOGFP, "End of comment: %s\n", src );
									}
									break;
								}
							}
							else {
								/* Hit end of statement */
								break;
							}
						}
						else {
							*dest++ = *src++;
						}
					}
				}
			}
			else {
				break;
			}
		}
		if( ! (*src) ) {
			break;
		}                                                         
		if (*src == '\'') {
			in_literal = !in_literal;
		}
		if ((*src != ':' && *src != '?') || in_literal) {
			*dest++ = *src++;
			continue;
		}
		start = dest;            /* save name inc colon    */
		*dest++ = *src++;
		if (*start == '?')       /* X/Open standard    */
		{
			sprintf((char *)start,":p%d", ++idx); /* '?' -> ':1' (etc)*/
			dest = start+strlen((char *)start);
		}
		*dest = '\0';            /* handy for debugging    */
		
		if (imp_sth->bind_names == NULL)
			imp_sth->bind_names = newHV();
		phs_sv = newSVpv((char *)&phs_tpl, sizeof(phs_tpl));
		hv_store(imp_sth->bind_names, (char *)start,
				(STRLEN)(dest-start), phs_sv, 0);
	}
	
	*dest = '\0';
	if( DBIS->debug >= 2 ) {
		PerlIO_printf( DBILOGFP,
				"statement = %s\nimp_sth->statement=%s\n",
				statement, imp_sth->statement );
	}
	if (imp_sth->bind_names) {
		DBIc_NUM_PARAMS(imp_sth) = (SQLINTEGER)HvKEYS(imp_sth->bind_names);
		if (DBIS->debug >= 2)
			PerlIO_printf( DBILOGFP,
					"scanned %d distinct placeholders\n",
					(SQLINTEGER)DBIc_NUM_PARAMS(imp_sth) );
	}
}

int dbd_st_table_info( SV *sth,
		imp_sth_t *imp_sth,
		SV *attribs ) {

      	D_imp_dbh_from_sth;
      	SQLRETURN ret;
      	const SQLCHAR *pszSchema = "";
      	const SQLCHAR *pszTable = "";
	SQLCHAR *pszTableType = NULL;
      	SQLINTEGER cbSchemaLength = 1;
      	SQLINTEGER cbTableLength = 1;
      	SQLINTEGER cbTableTypeLength = 0;
	
      	imp_sth->done_desc = 0;
	
      	ret = SQLAllocHandle( SQL_HANDLE_STMT,
			imp_dbh->hdbc,
			&imp_sth->phstmt );
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Statement Allocation Error");
      	if( SQL_SUCCESS != ret )
	   	return FALSE;

	DBIc_IMPSET_on( imp_sth );  /* Resources allocated */
	
      	if( attribs ) {
	    	SV **svp;
	    	STRLEN len;
		
	    	if( ( svp = hv_fetch( (HV*)SvRV(attribs),
		      				"TABLE_SCHEM",
		      				11, 0 ) ) != NULL ) {
		  	pszSchema = (SQLCHAR*)SvPV( *svp, len );
		  	cbSchemaLength = len;
	    	}
		
	    	if( ( svp = hv_fetch( (HV*)SvRV(attribs),
		      				"TABLE_NAME",
		      				10, 0 ) ) != NULL ) {
		  	pszTable = (SQLCHAR*)SvPV( *svp, len );
		  	cbTableLength = len;
	    	}
		
	    	if( ( svp = hv_fetch( (HV*)SvRV(attribs),
		      				"TABLE_TYPE",
		      				10, 0 ) ) != NULL ) {
		  	pszTableType = (SQLCHAR*)SvPV( *svp, len );
		  	cbTableTypeLength = len;
		  	/* CLI requires uppercase tokens */
		  	while( len-- > 0 ) {
				pszTableType[len] = toupper( pszTableType[len] );
		  	}
	    	}
      	}
	
      	ret = SQLTables( imp_sth->phstmt,
     			NULL,
     			0,
     			(SQLCHAR*)pszSchema,
     			(SQLSMALLINT)cbSchemaLength,
     			(SQLCHAR*)pszTable,
     			(SQLSMALLINT)cbTableLength,
     			(SQLCHAR*)pszTableType,
     			(SQLSMALLINT)cbTableTypeLength );
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLTables Failed");
      	if( SQL_SUCCESS != ret )
	    	return FALSE;
	
      	DBIc_NUM_PARAMS(imp_sth) = 0;
      	DBIc_ACTIVE_on(imp_sth);
	
	/* initialize sth pointers */
      	imp_sth->RowCount = -1;
      	imp_sth->bHasInput = 0;
      	imp_sth->bHasOutput = 0;
      	imp_sth->bMoreResults = 0;
	
      	if( !dbd_describe( sth, imp_sth ) )
	   	return FALSE;
	
      	return TRUE;
}

int dbd_st_primary_key_info( SV *sth,
		imp_sth_t *imp_sth,
		char      *pszCatalog,
		char      *pszSchema,
		char      *pszTable ) {
     	D_imp_dbh_from_sth;
     	SQLRETURN ret;
     	SQLSMALLINT cbCatalogLength = 0;
     	SQLSMALLINT cbSchemaLength  = 0;
     	SQLSMALLINT cbTableLength   = 0;
     	imp_sth->done_desc = 0;
     	ret = SQLAllocHandle( SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->phstmt );
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Statement Allocation Error");
     	if( ret != SQL_SUCCESS ) {
	  	return FALSE;
     	}
	
     	DBIc_IMPSET_on( imp_sth );
     	if( pszCatalog != NULL ) {
	  	cbCatalogLength = strlen( pszCatalog ); 
     	}
     	if( pszSchema != NULL ) {
	  	cbSchemaLength = strlen( pszSchema );
     	}
     	if( pszTable != NULL ) {
	  	cbTableLength = strlen( pszTable );
     	}
	
     	ret = SQLPrimaryKeys( imp_sth->phstmt,
			pszCatalog,
			cbCatalogLength,
			pszSchema,
			cbSchemaLength,
			pszTable,
			cbTableLength );
	
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLPrimaryKeys Failed");
	
     	if( ret != SQL_SUCCESS ) {
	  	return FALSE;
     	}
     	DBIc_NUM_PARAMS( imp_sth ) = 0;
     	DBIc_ACTIVE_on( imp_sth );
     	imp_sth->RowCount = -1;
     	imp_sth->bHasInput = 0;
     	imp_sth->bHasOutput = 0;
     	imp_sth->bMoreResults = 0;
	
     	if( !dbd_describe( sth, imp_sth ) ) {
	  	return FALSE;
     	}
	
     	return TRUE;
}

int dbd_st_foreign_key_info( SV *sth,
		imp_sth_t *imp_sth,
		char      *pkCatalog,
		char      *pkSchema,
		char      *pkTable,
		char      *fkCatalog,
		char      *fkSchema,
		char      *fkTable ) {
     	
	D_imp_dbh_from_sth;
	SQLRETURN ret;
     	SQLSMALLINT cbpkCatalogLength = 0;
     	SQLSMALLINT cbpkSchemaLength  = 0;
     	SQLSMALLINT cbpkTableLength   = 0;
     	SQLSMALLINT cbfkCatalogLength = 0;
     	SQLSMALLINT cbfkSchemaLength  = 0;
     	SQLSMALLINT cbfkTableLength   = 0;
     	imp_sth->done_desc = 0;
     
	ret = SQLAllocHandle( SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->phstmt );
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Statement Allocation Error");
     	if( ret != SQL_SUCCESS ) {
	  	return FALSE;
     	}
	
     	DBIc_IMPSET_on( imp_sth );
	
     	if( pkCatalog != NULL )	{
	  	cbpkCatalogLength = strlen( pkCatalog );
     	}
	
     	if( pkSchema != NULL ) {
	  	cbpkSchemaLength = strlen( pkSchema );
     	}
     	if( pkTable != NULL ) {
	  	cbpkTableLength = strlen( pkTable );
     	}
	
     	if( fkCatalog != NULL ) {
	  	cbfkCatalogLength = strlen( fkCatalog );
     	}
	
     	if( fkSchema != NULL ) {
	  	cbfkSchemaLength = strlen( fkSchema );
     	}
	
     	if( fkTable != NULL ) {
	  	cbfkTableLength = strlen( fkTable );
     	}
	
     	ret = SQLForeignKeys( imp_sth->phstmt,
			pkCatalog,
			cbpkCatalogLength,
			pkSchema,
			cbpkSchemaLength,
			pkTable,
			cbpkTableLength,
			fkCatalog,
			cbfkCatalogLength,
			fkSchema,
			cbfkSchemaLength,
			fkTable,
			cbfkTableLength );
	
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLForeignKeys Failed");
	
     	if( ret != SQL_SUCCESS ) {
	  	return FALSE;
     	}
	
     	DBIc_NUM_PARAMS( imp_sth ) = 0;
     	DBIc_ACTIVE_on( imp_sth );
     	imp_sth->RowCount = -1;
     	imp_sth->bHasInput = 0;
     	imp_sth->bHasOutput = 0;
     	imp_sth->bMoreResults = 0;
	
     	if( !dbd_describe( sth, imp_sth ) ) {
	  	return FALSE;
     	}
	
     	return TRUE;
}

int dbd_st_column_info( SV        *sth,
		imp_sth_t *imp_sth,
		char      *pszCatalog,
		char      *pszSchema,
		char      *pszTable,
		char      *pszColumn ) {
     	D_imp_dbh_from_sth;
     	SQLRETURN ret;
     	SQLSMALLINT cbCatalogLength = 0;
     	SQLSMALLINT cbSchemaLength  = 0;
     	SQLSMALLINT cbTableLength   = 0;
     	SQLSMALLINT cbColumnLength  = 0;
	imp_sth->done_desc = 0;
	
     	ret = SQLAllocHandle( SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->phstmt );	
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Statement Allocation Error");
	
     	if( ret != SQL_SUCCESS ) {
	  	return FALSE;
     	}
	
     	DBIc_IMPSET_on( imp_sth );
     	if( pszCatalog != NULL ) {
	  	cbCatalogLength = strlen( pszCatalog );
     	}
     	if( pszSchema == NULL ) {
	  	pszSchema = "%";
     	}
     	cbSchemaLength = strlen( pszSchema );
     	if( pszTable == NULL ) {
	  	pszTable = "%";
     	}
     	cbTableLength = strlen( pszTable );
     	if( pszColumn == NULL ) {
	  	pszColumn = "%";
     	}
     	cbColumnLength = strlen( pszColumn );
	
     	ret = SQLColumns( imp_sth->phstmt,
    			pszCatalog,
   			cbCatalogLength,
   			pszSchema,
   			cbSchemaLength,
   			pszTable,
   			cbTableLength,
   			pszColumn,
   			cbColumnLength );
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLColumns Failed");
     	if( ret != SQL_SUCCESS ) {
	  	return FALSE;
     	}
	
     	DBIc_NUM_PARAMS( imp_sth ) = 0;
     	DBIc_ACTIVE_on( imp_sth );
	
     	imp_sth->RowCount = -1;
     	imp_sth->bHasInput = 0;
     	imp_sth->bHasOutput = 0;
     	imp_sth->bMoreResults = 0;
	
     	if( !dbd_describe( sth, imp_sth ) ) {
	  	return FALSE;
     	}
	
     	return TRUE;
}

int dbd_st_type_info_all( SV        *sth,
		imp_sth_t *imp_sth ) {

	D_imp_dbh_from_sth;
     	SQLRETURN ret;
     	imp_sth->done_desc = 0;

     	ret = SQLAllocHandle( SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->phstmt );
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Statement Allocation Error");
     	if( ret != SQL_SUCCESS ) {
	  	return FALSE;
     	}
	
     	DBIc_IMPSET_on( imp_sth );
     	ret = SQLGetTypeInfo( imp_sth->phstmt, SQL_ALL_TYPES );
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLGetTypeInfo Failed");
     
	if( ret != SQL_SUCCESS ) {
	  	return FALSE;
     	}
	
     	DBIc_NUM_PARAMS( imp_sth ) = 0;
     	DBIc_ACTIVE_on( imp_sth );
	
     	imp_sth->RowCount = -1;
     	imp_sth->bHasInput = 0;
     	imp_sth->bHasOutput = 0;
     	imp_sth->bMoreResults = 0;
	
     	if( !dbd_describe( sth, imp_sth ) ) {
	  	return FALSE;
     	}
	
     	return TRUE;
}

SV *dbd_db_get_info( SV        *dbh,
		imp_dbh_t *imp_dbh,
		short      infoType ) {
     	
	SV *retsv = &PL_sv_undef;
     	SQLRETURN ret;
     	char buffer[256];
     	SQLPOINTER valuePtr = (SQLPOINTER) buffer;
     	SQLSMALLINT bufferLength = sizeof( buffer );
     	SQLSMALLINT stringLength;
	
     	memset( &buffer, '\0', sizeof( buffer ) );
     	/* Create our scalar value to return to app */
     	switch( infoType ) {
	 	/* Create a scalar to hold the string infoTypes */
	 	case SQL_DBMS_NAME:
	 	case SQL_DBMS_VER:
	 	case SQL_CATALOG_NAME:
	 	case SQL_CATALOG_NAME_SEPARATOR:
	 	case SQL_ACCESSIBLE_PROCEDURES:
	 	case SQL_ACCESSIBLE_TABLES:
	 	case SQL_CATALOG_TERM:
	 	case SQL_COLLATION_SEQ:
	 	case SQL_COLUMN_ALIAS:
	 	case SQL_DATA_SOURCE_NAME:
	 	case SQL_DATA_SOURCE_READ_ONLY:
	 	case SQL_DATABASE_NAME:
	 	case SQL_DESCRIBE_PARAMETER:
	 	case SQL_DRIVER_NAME:
	 	case SQL_DRIVER_ODBC_VER:
	 	case SQL_DRIVER_VER:
	 	case SQL_EXPRESSIONS_IN_ORDERBY:
	 	case SQL_IDENTIFIER_QUOTE_CHAR:
	 	case SQL_INTEGRITY:
	 	case SQL_KEYWORDS:
	 	case SQL_LIKE_ESCAPE_CLAUSE:
	 	case SQL_MULT_RESULT_SETS:
	 	case SQL_MULTIPLE_ACTIVE_TXN:
	 	case SQL_NEED_LONG_DATA_LEN:
	 	case SQL_ODBC_VER:
	 	case SQL_ORDER_BY_COLUMNS_IN_SELECT:
	 	case SQL_OUTER_JOINS:
	 	case SQL_PROCEDURE_TERM:
	 	case SQL_PROCEDURES:
	 	case SQL_ROW_UPDATES:
	 	case SQL_SCHEMA_TERM:
	 	case SQL_SEARCH_PATTERN_ESCAPE:
	 	case SQL_SERVER_NAME:
	 	case SQL_SPECIAL_CHARACTERS:
	 	case SQL_TABLE_TERM:
	 	case SQL_USER_NAME:
	 	case SQL_XOPEN_CLI_YEAR:
	
			ret = SQLGetInfo( imp_dbh->hdbc,
	     				infoType,
	     				valuePtr,
	     				bufferLength,
	     				&stringLength );
			
	       		if( ret == SQL_SUCCESS_WITH_INFO &&  bufferLength < (stringLength + 1) ) {
		 		if( DBIS->debug >= 2) {
		   			PerlIO_printf( DBILOGFP,
				 			"GetInfo(%d) local buffer isn't big enough. stringlenght=%d\n",
				 			infoType, stringLength );
		 		}
				
		 		/* Local buffer isn't big enough, dynamically allocate new one */
		 		bufferLength = stringLength + 1;
		 		Newc( 1, valuePtr, bufferLength, char, SQLPOINTER );
		 		Zero( valuePtr, bufferLength, char );
		 		ret = SQLGetInfo( imp_dbh->hdbc,
						infoType,
		   				valuePtr,
		   				bufferLength,
		   				&stringLength );
	   		}
			CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Error Calling SQLGetInfo");
	       
			if( ret == SQL_SUCCESS) {
		      		retsv = sv_2mortal( newSVpvn( (char*) valuePtr, (int)stringLength ) );
	       		}
	       		break;
			
		 	/* Create a scalar to hold the 16-bit integer */
	 	case SQL_CATALOG_LOCATION:
	 	case SQL_CONCAT_NULL_BEHAVIOR:
	 	case SQL_CORRELATION_NAME:
	 	case SQL_CURSOR_COMMIT_BEHAVIOR:
	 	case SQL_CURSOR_ROLLBACK_BEHAVIOR:
	 	case SQL_FILE_USAGE:
	 	case SQL_GROUP_BY:
	 	case SQL_IDENTIFIER_CASE:
	 	case SQL_MAX_CATALOG_NAME_LEN:
	 	case SQL_MAX_COLUMN_NAME_LEN:
	 	case SQL_MAX_COLUMNS_IN_INDEX:
	 	case SQL_MAX_COLUMNS_IN_ORDER_BY:
	 	case SQL_MAX_COLUMNS_IN_SELECT:
	 	case SQL_MAX_COLUMNS_IN_TABLE:
	 	case SQL_MAX_CONCURRENT_ACTIVITIES:
	 	case SQL_MAX_CURSOR_NAME_LEN:
	 	case SQL_MAX_DRIVER_CONNECTIONS:
	 	case SQL_MAX_IDENTIFIER_LEN:
	 	case SQL_MAX_TABLE_NAME_LEN:
	 	case SQL_MAX_TABLES_IN_SELECT:
	 	case SQL_MAX_USER_NAME_LEN:
	 	case SQL_NON_NULLABLE_COLUMNS:
	 	case SQL_NULL_COLLATION:
	 	case SQL_ODBC_API_CONFORMANCE:
	 	case SQL_ODBC_SAG_CLI_CONFORMANCE:
	 	case SQL_ODBC_SQL_CONFORMANCE:
	 	case SQL_QUOTED_IDENTIFIER_CASE:
	 	case SQL_TXN_CAPABLE:
			
	   		ret = SQLGetInfo( imp_dbh->hdbc,
	     				infoType,
	     				valuePtr,
	     				bufferLength,
	     				&stringLength );
			
	       		if( ret == SQL_SUCCESS_WITH_INFO &&  bufferLength < (stringLength + 1) ) {
		 		if( DBIS->debug >= 2) {
		   			PerlIO_printf( DBILOGFP,
				 			"GetInfo(%d) local buffer isn't big enough. stringlenght=%d\n",
				 			infoType, stringLength );
		 		}
				
		 		/* Local buffer isn't big enough, dynamically allocate new one */
		 		bufferLength = stringLength + 1;
		 		Newc( 1, valuePtr, bufferLength, char, SQLPOINTER );
		 		Zero( valuePtr, bufferLength, char );
				
		 		ret = SQLGetInfo( imp_dbh->hdbc,
		   				infoType,
		   				valuePtr,
		   				bufferLength,
		   				&stringLength );
	   		}
			CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Error Calling SQLGetInfo");
			
	       		if( ret == SQL_SUCCESS) {
				retsv = sv_2mortal( newSViv( (I16)( *(SQLSMALLINT*)valuePtr) ) );  
	       		}
	       		break;
			
		 	/* Create a scalar to hold a 32bit integer */
	 	case 2519:                     /* SQL_DATABASE_CODEPAGE:    */
	 	case 2520:                     /* SQL_APPLICATION_CODEPAGE: */
	 	case 2521:                     /* SQL_CONNECT_CODEPAGE:     */
	 	case SQL_ASYNC_MODE:
	 	case SQL_BATCH_ROW_COUNT:
	 	case SQL_CURSOR_SENSITIVITY:
	 	case SQL_DATETIME_LITERALS:
	 	case SQL_DDL_INDEX:
	 	case SQL_DRIVER_HDBC:
	 	case SQL_DRIVER_HDESC:
	 	case SQL_DRIVER_HENV:
	 	case SQL_DROP_ASSERTION:
	 	case SQL_DROP_CHARACTER_SET:
	 	case SQL_DROP_COLLATION:
	 	case SQL_DROP_DOMAIN:
	 	case SQL_DROP_SCHEMA:
	 	case SQL_DROP_TABLE:
	 	case SQL_DROP_TRANSLATION:
	 	case SQL_DROP_VIEW:
	 	case SQL_DTC_TRANSITION_COST:
	 	case SQL_MAX_ASYNC_CONCURRENT_STATEMENTS:
	 	case SQL_MAX_BINARY_LITERAL_LEN:
	 	case SQL_MAX_CHAR_LITERAL_LEN:
	 	case SQL_MAX_COLUMNS_IN_GROUP_BY:
	 	case SQL_MAX_INDEX_SIZE:
	 	case SQL_ODBC_INTERFACE_CONFORMANCE:
	 	case SQL_PARAM_ARRAY_ROW_COUNTS:
	 	case SQL_PARAM_ARRAY_SELECTS:
	 	case SQL_SQL_CONFORMANCE:
	   		ret = SQLGetInfo( imp_dbh->hdbc,
	     				infoType,
	     				valuePtr,
	     				bufferLength,
	     				&stringLength );
			
	       		if( ret == SQL_SUCCESS_WITH_INFO &&  bufferLength < (stringLength + 1) ) {
		 		if( DBIS->debug >= 2) {
		   			PerlIO_printf( DBILOGFP,
				 			"GetInfo(%d) local buffer isn't big enough. stringlength=%d\n",
				 			infoType, stringLength );
		 		}
				
		 		/* Local buffer isn't big enough, dynamically allocate new one */
		 		bufferLength = stringLength + 1;
		 		Newc( 1, valuePtr, bufferLength, char, SQLPOINTER );
		 		Zero( valuePtr, bufferLength, char );
		 		ret = SQLGetInfo( imp_dbh->hdbc,
		   				infoType,
		   				valuePtr,
		   				bufferLength,
		   				&stringLength );
	   		}
			
			CHECK_ERROR(dbh, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "Error Calling SQLGetInfo");
			
	       		if( ret == SQL_SUCCESS) {
		     		retsv = sv_2mortal( newSViv( (I32)( *(SQLINTEGER*)valuePtr) ) );
	       		}
	       		break;
			
		 	/* Create a scalar to hold the 32-bit mask */
		 	/* not supported */
	 	case SQL_AGGREGATE_FUNCTIONS:
	 	case SQL_ALTER_DOMAIN:
	 	case SQL_ALTER_TABLE:
	 	case SQL_BATCH_SUPPORT:
	 	case SQL_BOOKMARK_PERSISTENCE:
	 	case SQL_CATALOG_USAGE:
	 	case SQL_CONVERT_BIGINT:
	 	case SQL_CONVERT_BINARY:
	 	case SQL_CONVERT_BIT:
	 	case SQL_CONVERT_CHAR:
	 	case SQL_CONVERT_DATE:
	 	case SQL_CONVERT_DECIMAL:
	 	case SQL_CONVERT_DOUBLE:
	 	case SQL_CONVERT_FLOAT:
	 	case SQL_CONVERT_INTEGER:
	 	case SQL_CONVERT_INTERVAL_YEAR_MONTH:
	 	case SQL_CONVERT_INTERVAL_DAY_TIME:
	 	case SQL_CONVERT_LONGVARBINARY:
	 	case SQL_CONVERT_LONGVARCHAR:
	 	case SQL_CONVERT_NUMERIC:
	 	case SQL_CONVERT_REAL:
	 	case SQL_CONVERT_SMALLINT:
	 	case SQL_CONVERT_TIME:
	 	case SQL_CONVERT_TIMESTAMP:
	 	case SQL_CONVERT_TINYINT:
	 	case SQL_CONVERT_VARBINARY:
	 	case SQL_CONVERT_VARCHAR:
	 	case SQL_CONVERT_WCHAR:
	 	case SQL_CONVERT_WLONGVARCHAR:
	 	case SQL_CONVERT_WVARCHAR:
	 	case SQL_CONVERT_FUNCTIONS:
	 	case SQL_CREATE_ASSERTION:
	 	case SQL_CREATE_CHARACTER_SET:
	 	case SQL_CREATE_COLLATION:
	 	case SQL_CREATE_DOMAIN:
	 	case SQL_CREATE_SCHEMA:
	 	case SQL_CREATE_TABLE:
	 	case SQL_CREATE_TRANSLATION:
	 	case SQL_CREATE_VIEW:
	 	case SQL_DEFAULT_TXN_ISOLATION:
		 	/*case SQL_DYNAMIC_CURSOR_ATTRIBUTES:*/
	 	case SQL_DYNAMIC_CURSOR_ATTRIBUTES2:
	 	case SQL_FETCH_DIRECTION:
	 	case SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1:
	 	case SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2:
	 	case SQL_GETDATA_EXTENSIONS:
	 	case SQL_INDEX_KEYWORDS:
	 	case SQL_INFO_SCHEMA_VIEWS:
	 	case SQL_INSERT_STATEMENT:
	 	case SQL_KEYSET_CURSOR_ATTRIBUTES1:
	 	case SQL_KEYSET_CURSOR_ATTRIBUTES2:
	 	case SQL_LOCK_TYPES:
	 	case SQL_NUMERIC_FUNCTIONS:
	 	case SQL_OJ_CAPABILITIES:
	 	case SQL_POS_OPERATIONS:
	 	case SQL_POSITIONED_STATEMENTS:
	 	case SQL_SCHEMA_USAGE:
	 	case SQL_SCROLL_CONCURRENCY:
	 	case SQL_SCROLL_OPTIONS:
	 	case SQL_SQL92_DATETIME_FUNCTIONS:
	 	case SQL_SQL92_FOREIGN_KEY_DELETE_RULE:
	 	case SQL_SQL92_FOREIGN_KEY_UPDATE_RULE:
	 	case SQL_SQL92_GRANT:
	 	case SQL_SQL92_NUMERIC_VALUE_FUNCTIONS:
	 	case SQL_SQL92_PREDICATES:
	 	case SQL_SQL92_RELATIONAL_JOIN_OPERATORS:
	 	case SQL_SQL92_REVOKE:
	 	case SQL_SQL92_ROW_VALUE_CONSTRUCTOR:
	 	case SQL_SQL92_STRING_FUNCTIONS:
	 	case SQL_SQL92_VALUE_EXPRESSIONS:
	 	case SQL_STANDARD_CLI_CONFORMANCE:
	 	case SQL_STATIC_CURSOR_ATTRIBUTES1:
	 	case SQL_STATIC_CURSOR_ATTRIBUTES2:
	 	case SQL_STATIC_SENSITIVITY:
	 	case SQL_STRING_FUNCTIONS:
	 	case SQL_SUBQUERIES:
	 	case SQL_SYSTEM_FUNCTIONS:
	 	case SQL_TIMEDATE_ADD_INTERVALS:
	 	case SQL_TIMEDATE_DIFF_INTERVALS:
	 	case SQL_TIMEDATE_FUNCTIONS:
	 	case SQL_TXN_ISOLATION_OPTION:
	 	case SQL_UNION:
			
	       		/* how do return a bitmask? */
	       		/* retsv = sv_2mortal( newSVpv( (char*) valuePtr, (int) 32 ) ); */
	       		/* retsv = sv_2mortal( newSVrv( (SV*) valuePtr, NULL ) ); */
			
	       		break;
			
			
	 	default:
	       		break;
  	}
     	/* Free dynamically allocated buffer */
     	if( valuePtr != (SQLPOINTER) buffer ) {
	  	Safefree( valuePtr );
     	}
	
     	return retsv;
}

int dbd_st_prepare( SV *sth, 
		imp_sth_t *imp_sth,
		char *statement,
		SV *attribs ) {
    	D_imp_dbh_from_sth; 
    	SQLRETURN ret;
    	SQLSMALLINT params;
	
    	/* initialize sth fields */
    	imp_sth->numFieldsAllocated = 0;
    	imp_sth->RowCount = -1;
    	imp_sth->bHasInput = 0;
    	imp_sth->bHasOutput = 0;
    	imp_sth->bMoreResults = 0;
    	imp_sth->done_desc = 0;
	
    	ret = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc,
			&imp_sth->phstmt);
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Statement Allocation Error");
    	EOI(ret);
	
    	DBIc_IMPSET_on( imp_sth );  /* Resources allocated */
	
    	ret = SQLPrepare(imp_sth->phstmt,(SQLCHAR *)statement,SQL_NTS);
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Statement Preparation Error");
    	EOI(ret);
	
    	if (DBIS->debug >= 2)                                        
	  	PerlIO_printf( DBILOGFP,
	   			"    dbd_st_prepare'd sql f%d\n\t%s\n",
	   			imp_sth->phstmt, statement );
	
    	ret = SQLNumParams(imp_sth->phstmt,&params);
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Unable to Determine Numbe of Parameters");
    	EOI(ret);
	
    	DBIc_NUM_PARAMS(imp_sth) = params;
    	if (params > 0 ) {
		/* scan statement for '?', ':1' and/or ':foo' style placeholders*/
		dbd_preparse(imp_sth, statement);
    	}
	
    	dbd_describe( sth, imp_sth );
    	return TRUE;
}

int dbd_bind_ph( SV *sth,
		imp_sth_t *imp_sth,
		SV *param,
		SV *value,
		IV sql_type,
		SV *attribs,
		int is_inout,
		IV maxlen ) {

    	D_imp_dbh_from_sth;
    	SV **svp;
    	STRLEN name_len;
    	SQLCHAR  *name;
    	phs_t *phs;
    	SQLUSMALLINT pNum;
	
    	STRLEN value_len;
    	SQLRETURN ret;
    	short ctype = 0,
    	      scale = -1; /* initialize to invalid value */
    	unsigned prec = 0;
    	short bFile = 0; /* Boolean indicating value is a file name for LOB input */
    	SQLCHAR  buf[50];
    	static SQLUINTEGER FileOptions = SQL_FILE_READ;
    	static SQLINTEGER NullIndicator = SQL_NULL_DATA;
	
    	if (SvNIOK(param) ) {    /* passed as a number    */
		name = buf;
		pNum = (int)SvIV(param);
		sprintf( (char *)name, ":p%d", pNum );
		name_len = strlen((char *)name);
    	} else {
		name = (SQLCHAR *)SvPV(param, name_len);
		pNum = atoi( (char*)name + 2 );
    	}
	
    	if (DBIS->debug >= 2)
	  	PerlIO_printf( DBILOGFP,
	   			"bind %s <== '%s' (attribs: %s)\n",
	   			name,
	   			SvPV(value,PL_na), attribs ? SvPV(attribs,PL_na) : "<no attribs>" );
	
    	svp = hv_fetch(imp_sth->bind_names, (char *)name, name_len, 0);
    	if (svp == NULL)
		croak("Can't bind unknown parameter marker '%s'", name);
    	phs = (phs_t*)((void*)SvPVX(*svp));        /* placeholder struct    */
	
    	if( NULL != phs->sv ) {
	  	/* We've used this placeholder before,
		 *          decrement reference and set to undefined */
	  	SvREFCNT_dec( phs->sv );
	  	phs->sv = NULL;
    	}
	
    	/* Intialize parameter type to default value */
    	if( is_inout )
	  	phs->paramType = SQL_PARAM_INPUT_OUTPUT;
    	else
	  	phs->paramType = SQL_PARAM_INPUT;
	
    	if (attribs) {
		/* Setup / Clear attributes as defined by attribs.        */
		/* If attribs is EMPTY then attribs are defaulted.        */
		if( is_inout &&
		    		( ( svp = hv_fetch( (HV*)SvRV(attribs),
		    				    "db2_param_type",
		    				    14, 0 ) ) != NULL ||
		    		  ( svp = hv_fetch( (HV*)SvRV(attribs),
		    				    "ParamT", 6, 0 ) ) != NULL ) )
	    		phs->paramType = (unsigned short) SvIV(*svp);
		if( ( svp = hv_fetch( (HV*)SvRV(attribs),
		  				"db2_type",
		  				8, 0 ) ) != NULL ||
		    		( svp = hv_fetch( (HV*)SvRV(attribs),
		    				  "TYPE", 4, 0 ) ) != NULL ||
		    		( svp = hv_fetch( (HV*)SvRV(attribs),
		    				  "Stype", 5, 0 ) ) != NULL )
	    		sql_type = SvIV(*svp);
		if( ( svp = hv_fetch( (HV*)SvRV(attribs),
		  				"db2_c_type",
		  				10, 0 ) ) != NULL ||
		    		( svp = hv_fetch( (HV*)SvRV(attribs),
		    				  "Ctype", 5, 0 ) ) != NULL )
	    		ctype = (short) SvIV(*svp);
		if( ( svp = hv_fetch( (HV*)SvRV(attribs),
		  				"PRECISION",
		  				9, 0 ) ) != NULL ||
		    		( svp = hv_fetch( (HV*)SvRV(attribs),
		    				  "Prec", 4, 0 ) ) != NULL )
	    		prec = SvIV(*svp);
		if( ( svp = hv_fetch( (HV*)SvRV(attribs),
		  				"SCALE",
		  				5, 0 ) ) != NULL ||
		    		( svp = hv_fetch( (HV*)SvRV(attribs),
		    				  "Scale", 5, 0 ) ) != NULL )
	    		scale = (short) SvIV(*svp);
		if( ( svp = hv_fetch( (HV*)SvRV(attribs),
		  				"db2_file",
		  				8, 0 ) ) != NULL ||
		    		( svp = hv_fetch( (HV*)SvRV(attribs),
		    				  "File", 4, 0 ) ) != NULL )
	    		bFile = (short) SvIV(*svp);
    	} /* else if NULL / UNDEF then default to values assigned at top */
    	/* This approach allows maximum performance when    */
    	/* rebinding parameters often (for multiple executes).    */
	
    	/* If the SQL type or scale haven't been specified, try to      */
    	/* describe the parameter.  If this fails (it's an unregistered */
    	/* stored proc for instance) then defaults will be used         */
    	/* (SQL_VARCHAR and 0)                                          */
    	if( 0 == sql_type ||
			( -1 == scale &&
			  ( SQL_DECIMAL == sql_type ||
			    SQL_NUMERIC == sql_type ||
			    SQL_TIMESTAMP == sql_type ||
			    SQL_TYPE_TIMESTAMP == sql_type ) ) ) {
		if( !phs->bDescribed ) {
			SQLSMALLINT nullable;
			phs->bDescribed = TRUE;
			ret = SQLDescribeParam( imp_sth->phstmt,
	 				pNum,
	 				&phs->descSQLType,
	 				&phs->descColumnSize,
	 				&phs->descDecimalDigits,
	 				&nullable );
			phs->bDescribeOK = ( SQL_SUCCESS == ret ||
	   				SQL_SUCCESS_WITH_INFO == ret );
	  	}
		
	  	if( phs->bDescribeOK ) {
			if( 0 == sql_type )
		      		sql_type = phs->descSQLType;
			if( -1 == scale )
		      		scale = phs->descDecimalDigits;
	  	}
    	}
    	if( 0 == sql_type ) {
	  	/* Still don't have an SQL type?  Set to default */
	  	sql_type = SQL_VARCHAR;
    	}
    	else if( -1 == scale ) {
		/* Still don't have a scale?  Set to default */
	  	scale = 0;
    	}
    	if( 0 == ctype ) {
	  	/* Don't have a ctype yet?  Set to binary or char */
	  	if( SQLTypeIsBinary( (SQLSMALLINT) sql_type ) )
			ctype = SQL_C_BINARY;
#ifdef AS400
	  	else
			ctype = sql_type;
#else
	  	else
	     		ctype = SQL_C_CHAR;
#endif
    	}
    	/* At the moment we always do sv_setsv() and rebind.    */
    	/* Later we may optimise this so that more often we can */
    	/* just copy the value & length over and not rebind.    */
	
    	if( is_inout ) {
	  	phs->sv = value;             /* Make a reference to the input variable */
	  	SvREFCNT_inc( value );       /* Increment reference to variable */
	  	if( SQL_PARAM_INPUT != phs->paramType )
			imp_sth->bHasOutput = 1;
	  	if( SQL_PARAM_OUTPUT != phs->paramType )
			imp_sth->bHasInput = 1;
	  	if( maxlen > 0 )  {
			maxlen++;                  /* Add one for potential null terminator */
			/* Allocate new buffer only if current buffer isn't big enough */
			if( maxlen > phs->bufferSize ) {
		      		if( 0 == phs->bufferSize ) /* new buffer */
			    		Newc( 1, phs->buffer, maxlen, SQLCHAR, void* );
		      		else
			    		Renewc( phs->buffer, maxlen, SQLCHAR, void* );
		      		phs->bufferSize = maxlen;
			}
	  	}
    	}
    	else if( SvOK( value ) ) {
	  	SvPV( value, value_len );  /* Get value length */
	  	phs->indp = value_len;
	  	if( value_len > 0 ) {
			if( ((int)(value_len+1)) > phs->bufferSize ) {
		      		if( 0 == phs->bufferSize ) /* new buffer */
			    		Newc( 1, phs->buffer, value_len+1, SQLCHAR, void* );
		      		else
			    		Renewc( phs->buffer, value_len+1, SQLCHAR, void* );
		      		phs->bufferSize = value_len+1;
			}
			memcpy( phs->buffer, SvPVX( value ), value_len );
			((char*)phs->buffer)[value_len] = '\0'; /* null terminate */
	  	}
	  	maxlen = 0;
    	}
    	else {
	   	phs->indp = SQL_NULL_DATA;
	  	maxlen = 0;
    	}
	
    	if (DBIS->debug >= 2)
	  	PerlIO_printf( DBILOGFP,
	   			"  bind %s: "
	   			"db2_param_type=%d, "
	   			"db2_c_type=%d, "
	   			"db2_type=%d, "
	   			"PRECISION=%d, "
	   			"SCALE=%d, "
	   			"Maxlen=%d, "
	   			"%s\n",
	   			name,
	   			phs->paramType,
	   			ctype,
	   			sql_type,
	   			prec,
	   			scale,
	   			maxlen,
	   			!phs->bDescribed ? "Not described"
				: ( phs->bDescribeOK ? "Described"
					: "Describe failed" ) );
	
	if( bFile &&
			SQL_PARAM_INPUT == phs->paramType &&
			( SQL_BLOB == sql_type ||
			  SQL_XML == sql_type ||
			  SQL_CLOB == sql_type ||
			  SQL_DBCLOB == sql_type ) )
    	{
	  	ret = SQLBindFileToParam( imp_sth->phstmt,
				(SQLUSMALLINT)SvIV( param ),
				(SQLSMALLINT) sql_type,
				( phs->indp != SQL_NULL_DATA )
				? phs->buffer
				: "",  /* Can't pass NULL */
				NULL,
				&FileOptions,
				255,
				( phs->indp != SQL_NULL_DATA )
				? NULL
				: &NullIndicator );
    	}
    	else {
#ifdef AS400
	  	SQLPOINTER datap;
		switch (ctype) {
			case SQL_C_SHORT:
		  	case SQL_C_LONG:
				datap = &SvIVX(value);
				break;
		  	case SQL_C_FLOAT:
		  	case SQL_C_DOUBLE:
				datap = &SvNVX(value);
				break;
		  	default:
				datap = phs->buffer;
				break;
	  	}
	  	ret = SQLBindParameter( imp_sth->phstmt,
  				(SQLUSMALLINT)SvIV( param ),
  				phs->paramType,
  				ctype,
  				sql_type,
  				phs->bDescribeOK ? phs->descColumnSize : prec,
  				scale,
  				datap,
  				maxlen,
  				&phs->indp );
#else
                SQLPOINTER datap;
                switch (ctype) {
                        case SQL_C_SHORT:
                        case SQL_C_LONG:
                                datap = &phs->ivValue;
                                break;
                        case SQL_C_FLOAT:
                        case SQL_C_DOUBLE:
                                datap = &phs->dblValue;
                                break;
                        default:
                                datap = phs->buffer;
                                break;
                }
	  	ret = SQLBindParameter( imp_sth->phstmt,
  				(SQLUSMALLINT)SvIV( param ),
  				phs->paramType,
  				ctype,
  				sql_type,
  				phs->bDescribeOK ? phs->descColumnSize : prec,
  				scale,
  				datap,
  				maxlen,
  				&phs->indp );
#endif
    	}

	phs->cType = ctype;	/*Set the cType of the variable to which the parameter is bound*/

	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Bind Failed");
    	EOI(ret);
	
    	return TRUE;
}

int dbd_conn_opt( SV *sth,
		IV opt,
		IV value ) {

    	D_imp_sth(sth);
    	D_imp_dbh_from_sth;   
       	SQLRETURN ret;
    	ret = SQLSetConnectAttr( imp_dbh->hdbc,
			(SQLINTEGER) opt,
			(SQLPOINTER) value,
			(SQLINTEGER) 0 );
	
	CHECK_ERROR(sth, SQL_HANDLE_DBC, imp_dbh->hdbc, ret, "SQLSetConnectOption Failed");
    	EOI(ret);
	
    	return TRUE;
}

int dbd_st_execute( SV *sth,     /* error : <=(-2), ok row count : >=0, unknown count : (-1)     */
		imp_sth_t *imp_sth ) {
    
	SQLRETURN ret;
    	HV *hv;
    	SV *sv;
    	char *key;
    	I32 retlen;
    	phs_t *phs;
    	STRLEN value_len;
	
    	/* Reset input size and reallocate buffer if necessary for in/out
	 *        parameters */
    	if( imp_sth->bind_names && imp_sth->bHasInput ) {
	  	hv = imp_sth->bind_names;
		
	  	hv_iterinit( hv );
	  	while( ( sv = hv_iternextsv( hv, &key, &retlen ) ) != NULL ) {
			if( SvOK( sv ) ) {
		      		phs = (phs_t*)SvPVX( sv );
		      		if( NULL != phs->sv && /* is this parameter bound by reference? */
				  		SQL_PARAM_OUTPUT != phs->paramType ) /* is it in or in/out? */
		      		{
			    		if( SvOK( phs->sv ) ) {
				  		SvPV( phs->sv, value_len );  /* Get input value length */
				  		if( (int)value_len > (phs->bufferSize-1) )
							croak( "Error: Input value for parameter '%s' is bigger "
						 			"than the maximum length specified", key );
						
				  		phs->indp = value_len;
				  		memcpy( phs->buffer, SvPVX( phs->sv ), value_len );
			    		}
			    		else {
				  		phs->indp = SQL_NULL_DATA;
			    		}
		      		}
			}
	  	}
    	}
    	if (DBIc_ACTIVE(imp_sth) ) {
		dbd_st_finish(sth, imp_sth);
    	}
	
    	ret = SQLExecute(imp_sth->phstmt);
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLExecute Failed");
    	if (ret < 0)
		return(SQL_INVALID_HANDLE);
    	/* describe and allocate storage for results        */
    	if (!imp_sth->done_desc && !dbd_describe(sth, imp_sth)) {
		/* dbd_describe has already called check_error()        */
		return SQL_INVALID_HANDLE;
    	}
	
    	if( imp_sth->bind_names && imp_sth->bHasOutput ) {
	  	hv = imp_sth->bind_names;
	  	hv_iterinit( hv );
		while( ( sv = hv_iternextsv( hv, &key, &retlen ) ) != NULL ) {
			if( SvOK( sv ) ) {
		      		phs = (phs_t*)SvPVX( sv );
		      		if( NULL != phs->sv && /* is this parameter bound by reference? */
				  		SQL_PARAM_INPUT != phs->paramType ) /* is it out or in/out? */
		      		{
			    		if( SQL_NULL_DATA == phs->indp )
				  		sv_setsv( phs->sv, &PL_sv_undef ); /* undefine variable */
#ifndef AS400
			    		else if( SQL_NO_TOTAL == phs->indp ) {
				  		sv_setsv( phs->sv, &PL_sv_undef ); /* undefine variable */
				  		warn( "Number of bytes available to return "
					    			"cannot be determined for parameter '%s'", key );
			    		}
#endif
			    		else {
						if( phs->cType == SQL_C_LONG || phs->cType == SQL_C_SHORT ) {
                                                        sv_setiv(phs->sv, phs->ivValue);
                                                } else if( phs->cType == SQL_C_DOUBLE || phs->cType == SQL_C_FLOAT ) {
                                                        sv_setnv(phs->sv, phs->dblValue);
                                                } else {
                                                        sv_setpvn( phs->sv, phs->buffer, phs->indp );
							if( phs->indp > phs->bufferSize )
					       			warn( "Output buffer too small, data truncated "
						  				"for parameter '%s'", key );
						}
			    		}
		      		}
			}
	  	}
    	}
	
    	ret = SQLRowCount(imp_sth->phstmt, &imp_sth->RowCount);
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLRowCount Failed");
    
	DBIc_ACTIVE_on(imp_sth);
    	return imp_sth->RowCount;
}

static SQLRETURN get_lob_length( imp_fbh_t *fbh, SQLINTEGER col_num, SQLHANDLE hdbc ){
  SQLHANDLE        new_hstmt;
  SQLRETURN        rc;

  if( fbh->loc_ind == SQL_NULL_DATA ) { /* If column value is NULL then set rlen to -1 and return SQL_SUCCESS */
    fbh->rlen = -1;
    return SQL_SUCCESS;
  }

  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &new_hstmt);

  if( rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO ) {
    return rc;
  }

  switch( fbh->dbtype ) {
    case SQL_CLOB:
      fbh->ftype   =  SQL_C_CHAR;

      rc = SQLGetLength( new_hstmt,
                           fbh->loc_type,
                           fbh->lob_loc,
                           &fbh->rlen,
                           &fbh->loc_ind );
      break;

    case SQL_BLOB:
      fbh->ftype   =  SQL_C_BINARY;

      rc = SQLGetLength( new_hstmt,
                           fbh->loc_type,
                           fbh->lob_loc,
                           &fbh->rlen,
                           &fbh->loc_ind );
      break;

    case SQL_DBCLOB:
      fbh->ftype   =  SQL_C_CHAR;

      rc = SQLGetLength( new_hstmt,
                           fbh->loc_type,
                           fbh->lob_loc,
                           &fbh->rlen,
                           &fbh->loc_ind );
      break;

    case SQL_XML:
      fbh->ftype = SQL_C_BINARY;

      rc = SQLGetData( fbh->imp_sth->phstmt,
                       col_num,
                       fbh->ftype,
                       NULL,
                       0,
                       &fbh->rlen );

      /*SQL_SUCCESS_WITH_INFO is expected as we are not providing buffer size here. Hence set rc to SQL_SUCCESS so that there is no error flag set when checked for error*/
      if(rc == SQL_SUCCESS_WITH_INFO || rc == SQL_SUCCESS) {
         rc = SQL_SUCCESS;
      }

      return rc;
  }

  SQLFreeHandle(SQL_HANDLE_STMT, new_hstmt);

  return rc;
}

static SQLRETURN get_lob_data( imp_fbh_t *fbh, SQLINTEGER col_num, SQLHANDLE hdbc ){
  SQLHANDLE        new_hstmt;
  SQLRETURN        rc;
  SQLINTEGER       out_length = 0;

  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &new_hstmt);

  if( rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO ) {
    return rc;
  }

  switch( fbh->dbtype ) {
    case SQL_CLOB:
      fbh->ftype   =  SQL_C_CHAR;

      rc = SQLGetSubString( new_hstmt,
                            fbh->loc_type,
                            fbh->lob_loc,
                            1,
                            fbh->rlen,
                            fbh->ftype,
                            fbh->buffer,
                            fbh->bufferSize+1,
                            &out_length,
                            &fbh->loc_ind );
      fbh->rlen = out_length;
      break;

    case SQL_BLOB:
      fbh->ftype   =  SQL_C_BINARY;

      rc = SQLGetSubString( new_hstmt,
                            fbh->loc_type,
                            fbh->lob_loc,
                            1,
                            fbh->rlen,
                            fbh->ftype,
                            fbh->buffer,
                            fbh->bufferSize,
                            &out_length,
                            &fbh->loc_ind );
      fbh->rlen = out_length;
      break;

    case SQL_DBCLOB:
      fbh->ftype   =  SQL_C_CHAR;

      rc = SQLGetSubString( new_hstmt,
                            fbh->loc_type,
                            fbh->lob_loc,
                            1,
                            fbh->rlen,
                            fbh->ftype,
                            fbh->buffer,
                            fbh->bufferSize+1,
                            &out_length,
                            &fbh->loc_ind );
      fbh->rlen = out_length;
      break;

    case SQL_XML:
      fbh->ftype = SQL_C_BINARY;

      rc = SQLGetData( fbh->imp_sth->phstmt,
                      col_num,
                      fbh->ftype,
                      fbh->buffer,
                      fbh->bufferSize,
                      &out_length );
      return rc;
  }

  SQLFreeHandle(SQL_HANDLE_STMT, new_hstmt);

  return rc;
}

AV *dbd_st_fetch( SV *sth,
		imp_sth_t *imp_sth ) {
    
	    D_imp_dbh_from_sth;
    	SQLINTEGER num_fields = DBIc_NUM_FIELDS( imp_sth );
    	SQLINTEGER ChopBlanks;
        SQLINTEGER bufferSizeRequired;
    	SQLINTEGER i;
        SQLINTEGER retl = 0;
    	SQLRETURN ret=-3;
    	AV *av;
    	imp_fbh_t *fbh;
    	SV *sv;
    	int arraylen;
	
    	/* Check that execute() was executed sucessfuly. This also implies    */
    	/* that dbd_describe() executed sucessfuly so the memory buffers    */
    	/* are allocated and bound.                        */
    	if ( !DBIc_ACTIVE(imp_sth) ) {
		CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "No Statement Executing");
		return Nullav;
    	}
	
    	if(imp_sth->bMoreResults == 1) {
	 	imp_sth->done_desc = 0;
	 	ret = dbd_describe(sth, imp_sth);
	 	num_fields = DBIc_NUM_FIELDS(imp_sth);
    	} 
	
    	ret = SQLFetch(imp_sth->phstmt);
    	if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
		CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Fetch Failed");
	  	if( SQL_NO_DATA_FOUND == ret ) {
			/* End of result set, need to check for additional result sets */
			/* to determine if it's safe to finish the statement.          */
			
			CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Error Tolerating Failed");
			ret = SQLMoreResults( imp_sth->phstmt );
			CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLMoreResults Failed");
			if( SQL_SUCCESS == ret ) {
		      		/* There is at least one more result set, set flag indicating so */
		      		imp_sth->bMoreResults = 1;
			}
			else {
		      		imp_sth->bMoreResults = 0;
		      		dbd_st_finish(sth, imp_sth);
			}
	  	}
	  	else {
			if (DBIS->debug >= 3)                                    
		      		PerlIO_printf( DBILOGFP,
		       				"    dbd_st_fetch failed, rc=%d", ret );
			dbd_st_finish(sth, imp_sth);
	  	}
	  	return Nullav;
    	}
	
    	av = DBIc_DBISTATE(imp_sth)->get_fbav(imp_sth);
    	/* Reset array size if necessary */
    	arraylen = av_len( av ) + 1;
    	if( arraylen != num_fields ) {
	  	int bReadonly = SvREADONLY(av);
	  	int len = av_len( av ) + 1;
		
	  	if( bReadonly )
	       		SvREADONLY_off( av );         /* DBI sets this readonly  */
		
	  	while( len < num_fields ) {
			av_store( av, len++, newSViv( 0 ) );
	  	}
		
	  	while( len > num_fields ) {
			SvREFCNT_dec( av_pop( av ) );
			len--;
	  	}
		
	  	if( bReadonly )
	       		SvREADONLY_on( av );
    	}
	
    	if (DBIS->debug >= 3)
	    	PerlIO_printf( DBILOGFP,
	     			"    dbd_st_fetch %d fields\n", num_fields );
	
    	ChopBlanks = DBIc_has( imp_sth, DBIcf_ChopBlanks );
    	for( i = 0; i < num_fields; ++i ) {
	  	fbh = &imp_sth->fbh[i];
        bufferSizeRequired = 0;
	  	sv = AvARRAY(av)[i]; /* Note: we reuse the supplied SV    */
		
#ifdef AS400
	  	if( fbh->rlen == SQL_NTS )
			fbh->rlen = strlen( fbh->buffer );
	  	if( fbh->ftype == SQL_C_LONG ) {
			if( fbh->rlen > -1 && fbh->bufferSize > 0 ) {
		      		sv_setiv(sv, *((SQLINTEGER*)fbh->buffer));
			} else {
		      		fbh->indp = fbh->rlen;
		      		fbh->rlen = 0;
		      		(void)SvOK_off(sv);
			}
	  	} else if( fbh->ftype == SQL_C_DOUBLE ) {
			if( fbh->rlen > -1 && fbh->bufferSize > 0 ) {
		      		sv_setnv(sv, *((SQLDOUBLE*)fbh->buffer));
			} else {
		      		fbh->indp = fbh->rlen;
		      		fbh->rlen = 0;
		      		(void)SvOK_off(sv);
			}
	  	} else {
#endif
        if( SQLTypeIsLob( fbh->dbtype ) ) {
          unsigned int longReadLen = DBIc_LongReadLen( imp_sth );

          ret = get_lob_length( fbh, i+1, imp_dbh->hdbc );
          CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Retrieving LOB length Failed");
          EOI(ret);

          if(fbh->rlen > -1 ) { /*LOB data is not null*/
		    if( fbh->rlen > (int) longReadLen ) {
              if( SQL_BLOB == fbh->dbtype ||
                  SQL_XML == fbh->dbtype ||
                  0 == longReadLen )
                fbh->rlen = bufferSizeRequired = longReadLen;
              else
                fbh->rlen = bufferSizeRequired = longReadLen+1; /* +1 for null terminator */
		    } else {
              if( SQL_BLOB == fbh->dbtype ||
                  SQL_XML == fbh->dbtype ||
                  0 == longReadLen )
                bufferSizeRequired = fbh->rlen;
              else
                bufferSizeRequired = fbh->rlen+1; /* +1 for null terminator */
		    }
		    if( fbh->buffer != NULL ) {
              Safefree(fbh->buffer);
              fbh->buffer = NULL;
		    }
            fbh->bufferSize = bufferSizeRequired;
            Newc( 1, fbh->buffer, fbh->bufferSize, SQLCHAR, void* );
          }
		}

        if( fbh->rlen > -1 &&      /* normal case - column is not null */
                    fbh->bufferSize > 0 ) {
            int nullAdj = SQL_C_CHAR == fbh->ftype ? 1 : 0;

            if( SQLTypeIsLob( fbh->dbtype ) ) {
              ret = get_lob_data( fbh, i+1, imp_dbh->hdbc );
              CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Retrieving LOB Data Failed");
              EOI(ret);
            }
				
            if( fbh->rlen > ( fbh->bufferSize - nullAdj ) ) /* data has been truncated */
            {
              int longTruncOk = DBIc_has( imp_sth, DBIcf_LongTruncOk );
              char msg[200];

              sv_setpvn( sv,
                         (char*)fbh->buffer,
                         fbh->bufferSize - nullAdj
                       );
					
              sprintf( msg,
                       "%s: Data in column %d has been truncated to %d bytes."
                       "  A maximum of %d bytes are available",
                       longTruncOk ? "Warning" : "Error",
                       i,
                       fbh->bufferSize - nullAdj,
                       fbh->rlen
					  );
					
              if( longTruncOk )
                warn( msg );
              else
                croak( msg );
            }
            else if( ChopBlanks && SQL_CHAR == fbh->dbtype )
              sv_setpvn( sv,
                         fbh->buffer,
                         GetTrimmedSpaceLen( fbh->buffer, fbh->rlen )
                       );
            else
              sv_setpvn( sv, (char*)fbh->buffer, fbh->rlen );
		  	}
        else                  /*  column contains a null value */
        {
          fbh->indp = (short) fbh->rlen;
          fbh->rlen = 0;
          (void)SvOK_off(sv);
        }
			
#ifdef AS400
	  	}
#endif
		
	  	if( DBIS->debug >= 2 )
			PerlIO_printf( DBILOGFP,
		 			"\t%d: rc=%d '%s'\n", i, ret, SvPV(sv,PL_na) );
    	}
    	return av;
}

int dbd_st_blob_read( SV *sth,                                   
		imp_sth_t *imp_sth,
		int field,
		long offset,
		long len,
		SV *destrv,
		long destoffset ) {
    
	D_imp_dbh_from_sth;
    	SQLINTEGER retl;
    	SV *bufsv;
    	SQLRETURN rtval;
    	imp_fbh_t *fbh;
    	int cbNullSize;  /* 1 if null terminated, 0 otherwise */
	
    	if( field < 1 || field > DBIc_NUM_FIELDS(imp_sth) )
	  	croak( "Error: Column %d is out of range", field );
	
    	fbh = &imp_sth->fbh[field-1];
	
    	if( SQLTypeIsGraphic( fbh->dbtype ) ) {
	 	cbNullSize = 0;          /* graphic data is not null terminated */
	 	if( len%2 == 1 )
	       		len -= 1; /* graphic column data requires an even buffer size */
    	}
    	else if( SQLTypeIsBinary( fbh->dbtype ) ) {
	 	cbNullSize = 0;           /* binary data is not null terminated */
    	}
    	else {
	 	cbNullSize = 1;
    	}
	
    	bufsv = SvRV(destrv);
    	if( SvREADONLY( bufsv ) )
	 	croak( "Error: Modification of a read-only value attempted" );
    	if( !SvOK( bufsv) )
	 	sv_setpv( bufsv, "" ); /* initialize undefined variable */
    	SvGROW( bufsv, (STRLEN)(destoffset + len + cbNullSize) );
	
    	rtval = SQLGetData( imp_sth->phstmt,
			(SQLUSMALLINT) field,
			fbh->ftype,
			SvPVX(bufsv) + destoffset,
			len + cbNullSize,
			&retl );
	
    	if (rtval == SQL_SUCCESS_WITH_INFO)      /* XXX should check for 01004 */
	 	retl = len;
	
    	if (retl == SQL_NULL_DATA)      /* field is null    */
    	{
	 	(void)SvOK_off(bufsv);
	 	return TRUE;
    	}
	
	CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, rtval, "GetData Failed To Read LOB");
    	EOI(rtval);
	
    	SvCUR_set(bufsv, destoffset+retl );
    	*SvEND(bufsv) = '\0'; /* consistent with perl sv_setpvn etc    */
	
    	return TRUE;
}

int dbd_st_rows( SV *sth,
		imp_sth_t *imp_sth ) {

	return imp_sth->RowCount;
}

int dbd_st_cancel( SV *sth,
		imp_sth_t *imp_sth ) {
    
	D_imp_dbh_from_sth;
    	SQLRETURN ret;
	
    	if (DBIc_ACTIVE(imp_sth) ) {
		ret = SQLCancel(imp_sth->phstmt);
		CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLCancel Failed");
		EOI(ret);
		
		ret = SQLFreeStmt(imp_sth->phstmt,SQL_CLOSE);
		CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLCancel Failed");
		EOI(ret);
    	}
    	DBIc_ACTIVE_off(imp_sth);
    	return TRUE;
}

int dbd_st_finish( SV *sth,
		imp_sth_t *imp_sth ) {

	D_imp_dbh_from_sth;
    	SQLRETURN ret;
    	/* Cancel further fetches from this cursor.  We don't        */
    	/* close the cursor (SQLFreeHandle) 'til DESTROY (dbd_st_destroy).*/
    	/* The application may call execute(...) again on the same   */
    	/* statement handle.                                         */
	
    	if (DBIc_ACTIVE(imp_sth) ) {
		ret = SQLFreeStmt(imp_sth->phstmt,SQL_CLOSE);
		CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLFreeStmt Failed");
		EOI(ret);
    	}
    	DBIc_ACTIVE_off(imp_sth);
    	return TRUE;
}

void dbd_st_destroy( SV *sth,
		imp_sth_t *imp_sth ) {
    
	D_imp_dbh_from_sth;
    	SQLINTEGER i;
	SQLRETURN ret;
	
    	/* Free off contents of imp_sth    */
	
    	for( i = 0; i < imp_sth->numFieldsAllocated; ++i) {
	  	imp_fbh_t *fbh = &imp_sth->fbh[i];
	  	Safefree( fbh->buffer );
    	}
    	Safefree(imp_sth->fbh);
    	Safefree(imp_sth->fbh_cbuf);
    	Safefree(imp_sth->statement);
	
    	if (imp_sth->bind_names) {
	  	HV *hv = imp_sth->bind_names;
	  	SV *sv;
	  	char *key;
	  	I32 retlen;
	  	phs_t *phs;
		
	  	hv_iterinit(hv);
	  	while( (sv = hv_iternextsv(hv, &key, &retlen)) != NULL ) {
			if (sv != &PL_sv_undef) {
		      		phs = (phs_t*)SvPVX(sv);
		      		SvREFCNT_dec( phs->sv );
		      		if( phs->buffer != NULL && phs->bufferSize > 0 )
			   		Safefree( phs->buffer );
			}
	  	}
	  	sv_free((SV*)imp_sth->bind_names);
    	}
	
    	if( DBIc_ACTIVE( imp_dbh ) &&
			!DBIc_IADESTROY( imp_sth ) &&
			SQL_NULL_HSTMT != imp_sth->phstmt ) {
	  	ret = SQLFreeHandle( SQL_HANDLE_STMT, imp_sth->phstmt );
		CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Statement Destruction Error");
	  	imp_sth->phstmt = SQL_NULL_HSTMT;
    	}
    	DBIc_IMPSET_off( imp_sth );  /* let DBI know we've done it */
}

static SQLINTEGER getStatementAttr( char *key,
		STRLEN keylen ) {
      	/* For better performance, the keys are sorted by length */
      	switch( keylen )
      	{
#ifndef AS400
	    	case 10:
		  	if(      strEQ( key, "db2_noscan" ) )
				return SQL_ATTR_NOSCAN;
		  	return SQL_ERROR;
			
	    	case 12:
		  	if(      strEQ( key, "db2_max_rows" ) )
				return SQL_ATTR_MAX_ROWS;
		  	else if( strEQ( key, "db2_prefetch" ) )
				return SQL_ATTR_PREFETCH;
		  	return SQL_ERROR;
			
	    	case 14:
		  	if(      strEQ( key, "db2_earlyclose" ) )
				return SQL_ATTR_EARLYCLOSE;
		  	else if( strEQ( key, "db2_max_length" ) )
				return SQL_ATTR_MAX_LENGTH;
		  	else if( strEQ( key, "db2_row_number" ) )
				return SQL_ATTR_ROW_NUMBER;
		  	return SQL_ERROR;
#endif
			
	    	case 15:
			if(      strEQ( key, "db2_call_return" ) )
				return SQL_ATTR_CALL_RETURN;
			else if( strEQ( key, "db2_concurrency" ) )
				return SQL_ATTR_CONCURRENCY;
		  	else if( strEQ( key, "db2_cursor_hold" ) )
				return SQL_ATTR_CURSOR_HOLD;
		  	return SQL_ERROR;
			
#ifndef AS400
	    	case 17:
		  	if(      strEQ( key, "db2_query_timeout" ) )
				return SQL_ATTR_QUERY_TIMEOUT;
		  	else if( strEQ( key, "db2_retrieve_data" ) )
				return SQL_ATTR_RETRIEVE_DATA;
		  	else if( strEQ( key, "db2_txn_isolation" ) )
				return SQL_ATTR_TXN_ISOLATION;
		  	return SQL_ERROR;
			
	    	case 20:
		  	if(      strEQ( key, "db2_deferred_prepare" ) )
				return SQL_ATTR_DEFERRED_PREPARE;
		  	return SQL_ERROR;
#endif
		case 21:
			if(      strEQ( key, "db2_rowcount_prefetch") )
				return SQL_ATTR_ROWCOUNT_PREFETCH;
			return SQL_ERROR;
			
	    	case 22:
		  	if(      strEQ( key, "db2_optimize_for_nrows" ) )
				return SQL_ATTR_OPTIMIZE_FOR_NROWS;
		  	return SQL_ERROR;
			
	    	case 28:
		  	if(      strEQ( key, "db2_query_optimization_level" ) )
				return SQL_ATTR_QUERY_OPTIMIZATION_LEVEL;
		  	return SQL_ERROR;
			
	    	default:
		  	return SQL_ERROR;
      	}
}

int dbd_st_STORE_attrib( SV *sth,
		imp_sth_t *imp_sth,
		SV *keysv,
		SV *valuesv ) {
      
	STRLEN kl;
      	char *key = SvPV( keysv, kl );
      	SQLINTEGER Attribute = getStatementAttr( key, kl );
      	SQLRETURN ret;
      	SQLPOINTER ValuePtr = 0;
      	SQLINTEGER StringLength = 0;
      	char msg[128]; /* buffer for error messages */
#ifdef AS400
      	SQLPOINTER param;
#endif
	
      	if( Attribute < 0 ) /* Don't know what this attribute is */
	    	return FALSE;
	
      	switch( Attribute ) {
	    	/* Booleans */
#ifndef AS400
	    	case SQL_ATTR_CURSOR_HOLD:
	    	case SQL_ATTR_DEFERRED_PREPARE:
	    	case SQL_ATTR_EARLYCLOSE:
	    	case SQL_ATTR_NOSCAN:
	    	case SQL_ATTR_PREFETCH:
	    	case SQL_ATTR_RETRIEVE_DATA:
		  	if( SvTRUE( valuesv ) )
				ValuePtr = (SQLPOINTER)1;
		  	break;
#else
	    	case SQL_ATTR_CURSOR_HOLD:
		  	param=SQL_TRUE;
		  	if( SvTRUE( valuesv ) )
				ValuePtr = (SQLPOINTER)&param;
		  	break;
#endif
		/* Integers */
		case SQL_ATTR_CALL_RETURN:
		case SQL_ATTR_CONCURRENCY:
		case SQL_ATTR_ROWCOUNT_PREFETCH:
#ifndef AS400
		case SQL_ATTR_LOGIN_TIMEOUT:
		case SQL_ATTR_MAX_LENGTH:
		case SQL_ATTR_MAX_ROWS:
#endif
		case SQL_ATTR_OPTIMIZE_FOR_NROWS:
		case SQL_ATTR_QUERY_OPTIMIZATION_LEVEL:
#ifndef AS400
		case SQL_ATTR_QUERY_TIMEOUT:
		case SQL_ATTR_TXN_ISOLATION:
#endif
		  	if( SvIOK( valuesv ) ) {
				ValuePtr = (SQLPOINTER)SvIV( valuesv );
			}
			else if( SvOK( valuesv ) ) {
				/* Value is not an integer, return error */
				sprintf( msg,
			       			"Invalid value for statement attribute %s, expecting integer",
			       			key );
				ret = -1;
				CHECK_ERROR(sth, 0, SQL_NULL_HANDLE, ret, msg);
				return FALSE;
		  	}
		  	else /* Undefined, Set to default, most are 0 or NULL */
		    	{
		  	}
		  	break;
			
	    	default:
		  	return FALSE;
      	}
	
	ret = SQLSetStmtAttr( imp_sth->phstmt,
			Attribute,
			ValuePtr,
			StringLength );
      	if( SQL_SUCCESS != ret ) {
	    	sprintf( msg, "Error setting %s statement attribute", key );
		CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, msg);
	    	return FALSE;
      	}
	
      	return TRUE;
}

SV *dbd_st_FETCH_attrib( SV *sth,
		imp_sth_t *imp_sth,
		SV *keysv ) {
      
	STRLEN kl;
      	char *key = SvPV( keysv, kl ); 
      	int i;
      	SV *retsv = NULL;
      	AV *av;
      	int cacheit = 1;
      	SQLINTEGER Attribute;
      	SQLRETURN ret = 0;
	
      	if (!imp_sth->done_desc && !dbd_describe(sth, imp_sth)) {
	    	/* dbd_describe has already called check_error()        */
	    	/* We can't return Nullsv here because the xs code will */
	    	/* then just pass the attribute name to DBI for FETCH.  */
	    	croak("Describe failed during %s->FETCH(%s)",
		     		SvPV(sth,PL_na), key);
      	}
	
      	i = DBIc_NUM_FIELDS(imp_sth);
	
      	if( kl == 7 && strEQ( key, "lengths" ) ) {
	    	av = newAV();
	    	retsv = sv_2mortal( newRV_inc( (SV*)av ) );
	    	while(--i >= 0)
			av_store(av, i, newSViv((IV)imp_sth->fbh[i].dsize));
      	}
      	else if( kl == 5 && strEQ( key, "types" ) ) {
	    	av = newAV();
	    	retsv = sv_2mortal( newRV_inc( (SV*)av ) );
	    	while(--i >= 0)
			av_store(av, i, newSViv(imp_sth->fbh[i].dbtype));
      	}
      	else if( kl == 13 && strEQ( key, "NUM_OF_PARAMS" ) ) {
	    	HV *bn = imp_sth->bind_names;
	    	retsv = sv_2mortal( newSViv( (bn) ? HvKEYS(bn) : 0 ) );
      	}
      	else if( kl == 4 && strEQ( key, "NAME" ) ) {
	    	av = newAV();
	    	retsv = sv_2mortal( newRV_inc( sv_2mortal((SV*)av) ) );
	    	while(--i >= 0)
			av_store(av, i, newSVpv((char *)imp_sth->fbh[i].cbuf,0));
      	}
      	else if( kl == 8 && strEQ( key, "NULLABLE" ) ) {
	    	av = newAV();
	    	retsv = sv_2mortal( newRV_inc( sv_2mortal((SV*)av) ) );
	    	while(--i >= 0)
			av_store(av, i,
		       			(imp_sth->fbh[i].nullok == 1) ? &PL_sv_yes : &PL_sv_no);
      	}
      	else if( kl == 10 && strEQ( key, "CursorName" ) ) {
	    	char cursor_name[256];
	    	SQLSMALLINT cursor_name_len;
	    	ret = SQLGetCursorName(imp_sth->phstmt, (SQLCHAR *)cursor_name,
     				sizeof(cursor_name), &cursor_name_len);
		CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "SQLNGetCursorName Failed");
	    	if (ret < 0)
			return Nullsv;
	    	else
			retsv = sv_2mortal( newSVpv(cursor_name, cursor_name_len) );
      	}
      	else if( kl == 4 && strEQ( key, "TYPE" ) ) {
	    	av = newAV();
	    	retsv = sv_2mortal( newRV_inc( sv_2mortal( (SV*)av ) ) );
	    	while(--i >= 0)
			av_store(av, i, newSViv(imp_sth->fbh[i].dbtype));
      	}
      	else if( kl == 9 && strEQ( key, "PRECISION" ) ) {
	    	av = newAV();
	    	retsv = sv_2mortal( newRV_inc( sv_2mortal( (SV*)av ) ) );
	    	while(--i >= 0)
			av_store(av, i, newSViv(imp_sth->fbh[i].prec));
      	}
      	else if( kl == 5 && strEQ( key, "SCALE" ) ) {
	    	av = newAV();
	    	retsv = sv_2mortal( newRV_inc( sv_2mortal( (SV*)av ) ) );
	    	while(--i >= 0)
			av_store(av, i, newSViv(imp_sth->fbh[i].scale));
      	}
      	else if( 16 == kl && strEQ( key, "db2_more_results" ) ) {
	    	if( !DBIc_ACTIVE(imp_sth) ) {
		  	/* Statement has been finished, no more results available */
		  	retsv = &PL_sv_no;
	    	}
	    	else if( imp_sth->bMoreResults ) {
		  	/* Already know that there are more result sets */
		  	retsv = &PL_sv_yes;
	    	}
	    	else {
		  	ret = SQLMoreResults( imp_sth->phstmt );
			CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Error Getting More Results");
		  	if( SQL_SUCCESS == ret ) {
				retsv = &PL_sv_yes;
		  	}
		  	else {
				/* No more results, finish statement */
				dbd_st_finish(sth, imp_sth);
				retsv = &PL_sv_no;
		  	}
	    	}
		
	    	if( &PL_sv_yes == retsv ) {
		  	/* describe and allocate storage for results        */
		  	imp_sth->done_desc = FALSE;
			
		  	/* Remove statement attribs in cache                */
		  	if (hv_exists((HV*) SvRV(sth), "NAME", 4) )
		       		hv_delete((HV *) SvRV(sth), "NAME", 4, G_DISCARD);
			
		  	if (hv_exists((HV*) SvRV(sth), "NAME_uc", 7))
		       		hv_delete((HV *) SvRV(sth), "NAME_uc", 7, G_DISCARD);
			
		  	if (hv_exists((HV*) SvRV(sth), "NAME_lc", 7) )
		       		hv_delete((HV *) SvRV(sth), "NAME_lc", 7, G_DISCARD);
			
		  	if (hv_exists((HV*) SvRV(sth), "TYPE", 4) )
		       		hv_delete((HV *) SvRV(sth), "TYPE", 4, G_DISCARD);
			
		  	if (hv_exists((HV*) SvRV(sth), "PRECISION", 9) )
		       		hv_delete((HV *) SvRV(sth), "PRECISION", 9, G_DISCARD);
			
		  	if (hv_exists((HV*) SvRV(sth), "SCALE", 5) )
		       		hv_delete((HV *) SvRV(sth), "SCALE", 5, G_DISCARD);
			
		  	if (hv_exists((HV*) SvRV(sth), "NULLABLE", 8) )
		       		hv_delete((HV *) SvRV(sth), "NULLABLE", 8, G_DISCARD);
			
		  	if (hv_exists((HV*) SvRV(sth), "NUM_OF_FIELDS", 13) )
		       		hv_delete((HV *) SvRV(sth), "NUM_OF_FIELDS", 13, G_DISCARD);
			
		  	if (hv_exists((HV*) SvRV(sth), "CursorName", 10) )
		       		hv_delete((HV *) SvRV(sth), "CursorName", 10, G_DISCARD);
					
		  	if( dbd_describe( sth, imp_sth ) ) {
				/* dbd_describe has already called check_error() */
		  	}
	    	}
		
	    	cacheit = 0; /* Don't cache this attribute */
      	}
      	else if( ( Attribute = getStatementAttr( key, kl ) ) >= 0 ) {
	    	char buffer[128]; /* should be big enough for any attribute value */
	    	SQLPOINTER ValuePtr = (SQLPOINTER)buffer;
	    	SQLINTEGER BufferLength = sizeof( buffer );
	    	SQLINTEGER StringLength;
		
	    	ret = SQLGetStmtAttr( imp_sth->phstmt,
      				Attribute,
      				ValuePtr,
      				BufferLength,
      				&StringLength );
	    	if( SQL_SUCCESS_WITH_INFO == ret &&
				(StringLength + 1) > BufferLength ) {
		  	/* local buffer isn't big enough, allocate one */
		  	BufferLength = StringLength + 1;
		  	Newc( 1, ValuePtr, BufferLength, char, SQLPOINTER );
		  	ret = SQLGetStmtAttr( imp_sth->phstmt,
	    				Attribute,
	    				ValuePtr,
	    				BufferLength,
	    				&StringLength );
	    	}
		CHECK_ERROR(sth, SQL_HANDLE_STMT, imp_sth->phstmt, ret, "Error Retrieving Statement Attribute");
	    	if( SQL_SUCCESS == ret ) {
		  	switch( Attribute ) {
				/* Booleans */
				case SQL_ATTR_CURSOR_HOLD:
#ifndef AS400
				case SQL_ATTR_DEFERRED_PREPARE:
				case SQL_ATTR_EARLYCLOSE:
				case SQL_ATTR_NOSCAN:
				case SQL_ATTR_PREFETCH:
				case SQL_ATTR_RETRIEVE_DATA:
#endif
			      		if( *(SQLINTEGER*)ValuePtr )
				    		retsv = &PL_sv_yes;
			      		else
				    		retsv = &PL_sv_no;
			      		break;
					
				/* Integers */
				case SQL_ATTR_CALL_RETURN:
				case SQL_ATTR_CONCURRENCY:
				case SQL_ATTR_ROWCOUNT_PREFETCH:
#ifndef AS400
				case SQL_ATTR_LOGIN_TIMEOUT:
				case SQL_ATTR_MAX_LENGTH:
				case SQL_ATTR_MAX_ROWS:
#endif
				case SQL_ATTR_OPTIMIZE_FOR_NROWS:
				case SQL_ATTR_QUERY_OPTIMIZATION_LEVEL:
#ifndef AS400
				case SQL_ATTR_QUERY_TIMEOUT:
				case SQL_ATTR_ROW_NUMBER:
				case SQL_ATTR_TXN_ISOLATION:
#endif
			      		retsv = sv_2mortal( newSViv( (IV)( *(SQLINTEGER*)ValuePtr ) ) );
			      		break;
					
				default:
			      		break;
		  	}
	    	}
		
	    	if( ValuePtr != (SQLPOINTER)buffer )
		  	Safefree( ValuePtr );  /* Free dynamically allocated buffer */
		cacheit = 0; /* Don't cache CLI attributes */
      	}
      	else {
	    	return Nullsv;
      	}
	
      	if( cacheit ) { /* cache for next time (via DBI quick_FETCH)    */
		SV **svp = hv_fetch((HV*)SvRV(sth), key, kl, 1);
	    	sv_free(*svp);
	    	*svp = retsv;
	    	(void)SvREFCNT_inc(retsv);    /* so sv_2mortal won't free it    */
      	}
	
      	return retsv;
	
}
