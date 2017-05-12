/* ========================================================================
* 
* Copyright (c) 1997  Thomas K. Wenrich
* portions Copyright (c) 1994,1995,1996  Tim Bunce
*
* You may distribute under the terms of either the GNU General Public
* License or the Artistic License, as specified in the Perl README file.
*
* Autocommit note:
*   Solid Server versions prior to 2.2.0017 have a broken AUTOCOMMIT
*   (rollback in disconnect() _MAY_ undo inserts done from within a 
*   solid procedure), so we handle AutoCommit *additional* to the 
*   ODBC connection attribute (this is controlled by SOL22_AUTOCOMMIT_BUG
*   definition within Makefile.PL).
* ======================================================================== */

/* --------------------------------------------
* v2.0 to support Solid 3.5
* dTHR is from dbipport.h from DBIXS.h from DBI
* and is supposed to support a multithreaded perl. --mms
* #define dTHR extern int errno
*/

#include "Solid.h"

/* Fixes problem with bind_columns immediate after prepare,
* but breaks $sth->{blob_size} attribute. */
#define DESCRIBE_IN_PREPARE 1 

typedef struct 
   {
   const char* str;
   UWORD fOption;
   UDWORD true;
   UDWORD false;
   } db_params;

typedef struct 
   {
   const char* str;
   unsigned len:8;
   unsigned array:1;
   unsigned filler:23;
   } T_st_params;

static const char* S_SqlTypeToString ( SWORD sqltype );
static const char* S_SqlCTypeToString ( SWORD sqltype );
static const char* S_SqlCTypeToCTypeString( SWORD sqltype );
static int S_IsFetchError( SV* sth, RETCODE rc, char* sqlstate, const void* par );

DBISTATE_DECLARE;

/* --------------------------------- 
*
* ---------------------------------- */
void dbd_init( dbistate_t* dbistate )
   {
   DBIS = dbistate;
   }

/* ------------------------------------
*
* ------------------------------------- */
void dbd_db_destroy( SV* dbh )
   {
   D_imp_dbh(dbh);
   dTHR;

   if( DBIc_ACTIVE(imp_dbh) )
      {
      dbd_db_disconnect(dbh);
      }
   /* Nothing in imp_dbh to be freed	*/
   DBIc_IMPSET_off( imp_dbh );
   }

/*------------------------------------------------------------
  connecting to a data source.
  Allocates henv and hdbc.
------------------------------------------------------------*/
int dbd_db_login( SV* dbh, char* dbname, char* uid, char* pwd )
   {
   D_imp_dbh( dbh );
   D_imp_drh_from_dbh;   
   int ret;
   dTHR;

   RETCODE rc;
   static int s_first = 1;

   if( dbis->debug >= 2 )
      fprintf( DBILOGFP, "%s connect '%s', '%s', '%s'\n",
              s_first ? "FIRST" : "not first", 
              dbname, uid, pwd );

   if( s_first )
      {
      s_first = 0;
      imp_drh->connects = 0;
      imp_drh->henv = SQL_NULL_HENV;
      }

   if( !imp_drh->connects )
      {
      /* As of ODBC 3.x SQLAllocEnv is deprecated. --mms */
      /* rc = SQLAllocEnv(&imp_drh->henv); 
      solid_error(dbh, rc, "db_login/SQLAllocEnv"); */
      
      rc = SQLAllocHandle( SQL_HANDLE_ENV, SQL_NULL_HANDLE, &imp_drh->henv );
      solid_error( dbh, rc, "db_login/SQLAllocHandle/Env" );
      
      if ( rc != SQL_SUCCESS )
         { return 0; }
      }

   /* This also is deprecated. --mms */
   /*rc = SQLAllocConnect(imp_drh->henv, &imp_dbh->hdbc);
   solid_error(dbh, rc, "db_login/SQLAllocConnect"); */
   
   rc = SQLAllocHandle( SQL_HANDLE_DBC, imp_drh->henv, &imp_dbh->hdbc );
   solid_error( dbh, rc, "db_login/SQLAllocHandle/Connect" );

   if( rc != SQL_SUCCESS )
      {
      if( imp_drh->connects == 0 )
         {
         /* Deprecated.  --mms
         SQLFreeEnv(imp_drh->henv); */
         SQLFreeHandle(SQL_HANDLE_ENV, imp_drh->henv);
         
         imp_drh->henv = SQL_NULL_HENV;
         }
      return 0;
      }

   if( dbis->debug >= 2 )
      fprintf(DBILOGFP, "connect '%s', '%s', '%s'", dbname, uid, pwd);
   
   rc = SQLConnect( imp_dbh->hdbc, dbname, strlen(dbname),
                    uid, strlen(uid), pwd, strlen(pwd) );

   solid_error( dbh, rc, "db_login/SQLConnect" );
   
   if( rc != SQL_SUCCESS )
      {
      /* Deprecated. --mms
      SQLFreeConnect(imp_dbh->hdbc); */
      SQLFreeHandle(SQL_HANDLE_DBC, imp_dbh->hdbc);
      
      if( imp_drh->connects == 0 )
         {
         /* Deprecated.  --mms
         SQLFreeEnv(imp_drh->henv); */
         SQLFreeHandle( SQL_HANDLE_ENV, imp_drh->henv );
         
         imp_drh->henv = SQL_NULL_HENV;
         }
      return 0;
      }

   /* DBI spec requires AutoCommit on */
   rc = SQLSetConnectOption( imp_dbh->hdbc, SQL_AUTOCOMMIT, 
                            SQL_AUTOCOMMIT_ON );
   solid_error( dbh, rc, "dbd_db_login/SQLSetConnectOption" );
   
   if( rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO )
      {
      DBIc_on(imp_dbh, DBIcf_AutoCommit);
      }

   /* set DBI spec (0.87) defaults */
   DBIc_LongReadLen( imp_dbh ) = 80;
   DBIc_set( imp_dbh, DBIcf_LongTruncOk, 1 );

   imp_drh->connects++;

   /* imp_dbh set up now         */
   DBIc_IMPSET_on( imp_dbh );
   
   /* call disconnect before freeing   */
   DBIc_ACTIVE_on( imp_dbh );

   return 1;
   }

/* ----------------------------------------- 
* Disconnect from DB (duh!)
* SQLTransact is deprecated as of ODBC 3.x.
* Replaced with SQLEndTran().  --mms
* ------------------------------------------ */
int dbd_db_disconnect( SV* dbh )
   {
   RETCODE rc;
   D_imp_dbh( dbh );
   D_imp_drh_from_dbh;
   dTHR;

   /* We assume that disconnect will always work  */
   /* since most errors imply already disconnected.  */
   DBIc_ACTIVE_off( imp_dbh );

   /* DBI spec: rolling back or committing depends
   * on AutoCommit attribute */
#ifdef SOL22_AUTOCOMMIT_BUG
   /* Deprecated. --mms
   rc = SQLTransact(imp_drh->henv, imp_dbh->hdbc,
                    DBIc_is(imp_dbh, DBIcf_AutoCommit) ? SQL_COMMIT : SQL_ROLLBACK);
   solid_error(dbh, rc, "db_disconnect/SQLTransact"); */
   
   rc = SQLEndTran( SQL_HANDLE_DBC, imp_dbh->hdbc,
                    DBIc_is(imp_dbh, DBIcf_AutoCommit) ? SQL_COMMIT : SQL_ROLLBACK );
   solid_error( dbh, rc, "db_disconnect/SQLEndTran" );
#else      
   /* Deprecated. --mms
   rc = SQLTransact(imp_drh->henv, imp_dbh->hdbc, SQL_ROLLBACK);
   solid_error(dbh, rc, "db_disconnect/SQLTransact"); */

   rc = SQLEndTran( SQL_HANDLE_DBC, imp_dbh->hdbc, SQL_ROLLBACK );
   solid_error( dbh, rc, "db_disconnect/SQLEndTran" );
#endif
   rc = SQLDisconnect( imp_dbh->hdbc );
   solid_error( dbh, rc, "db_disconnect/SQLDisconnect" );

   if( rc != SQL_SUCCESS )
      { return 0; }

   /* Deprecated. --mms
   SQLFreeConnect(imp_dbh->hdbc); */
   SQLFreeHandle( SQL_HANDLE_DBC, imp_dbh->hdbc );
   
   imp_dbh->hdbc = SQL_NULL_HDBC;
   imp_drh->connects--;
   if( imp_drh->connects == 0 )
      {
      /* Deprecated. --mms
      SQLFreeEnv(imp_drh->henv); */
      SQLFreeHandle( SQL_HANDLE_ENV, imp_drh->henv );
      }
   
   /* We don't free imp_dbh since a reference still exists	
    * The DESTROY method is the only one to 'free' memory.  
    * Note that statement objects may still exist for this dbh!  */

   return 1;
   }

/* -------------------------------------------------------
* Issue a commit.
* Again, SQLTransact is deprecated. --mms
* -------------------------------------------------------- */
int dbd_db_commit( SV* dbh )
   {
   D_imp_dbh( dbh );
   D_imp_drh_from_dbh;
   RETCODE rc;
   dTHR;

   /* Deprecated.  --mms
   rc = SQLTransact(imp_drh->henv, imp_dbh->hdbc, SQL_COMMIT);
   solid_error(dbh, rc, "db_commit/SQLTransact"); */

   rc = SQLEndTran( SQL_HANDLE_DBC, imp_dbh->hdbc, SQL_COMMIT );
   solid_error( dbh, rc, "db_disconnect/SQLEndTran" );

   if( rc != SQL_SUCCESS )
      { return 0; }
   
   return 1;
}

/* ------------------------------------
* SQLTransact deprecated.
* ------------------------------------- */
int dbd_db_rollback( SV* dbh )
   {
   D_imp_dbh( dbh );
   D_imp_drh_from_dbh;
   RETCODE rc;
   dTHR;

   /* Deprecated.  --mms
   rc = SQLTransact(imp_drh->henv, imp_dbh->hdbc, SQL_ROLLBACK);
   solid_error(dbh, rc, "db_rollback/SQLTransact"); */

   rc = SQLEndTran( SQL_HANDLE_DBC, imp_dbh->hdbc, SQL_ROLLBACK );
   solid_error( dbh, rc, "db_disconnect/SQLEndTran" );

   if( rc != SQL_SUCCESS )
      { return 0; }

   return 1;
   }

/*------------------------------------------------------------
  replacement for ora_error. (From DBD-oracle I presume?)
  empties entire ODBC error queue.
------------------------------------------------------------*/
const char* solid_error5( SV* h, RETCODE badrc, char* what, 
                          T_IsAnError func, const void* par)
   {
   D_imp_xxh( h );
   dTHR;

   struct imp_drh_st* drh = NULL;
   struct imp_dbh_st* dbh = NULL;
   struct imp_sth_st* sth = NULL;

   /*  Solid changed these types for ODBC 3.x.
   * See sqltypes.h.  --mms */
   /* HENV henv = SQL_NULL_HENV;
   HDBC hdbc = SQL_NULL_HDBC;
   HSTMT hstmt = SQL_NULL_HSTMT; */

   SQLHENV henv = SQL_NULL_HENV;
   SQLHDBC hdbc = SQL_NULL_HDBC;
   SQLHSTMT hstmt = SQL_NULL_HSTMT;
   
   int i = 2;     /* 2..0 hstmt..henv */

   SDWORD NativeError;
   UCHAR ErrorMsg[SQL_MAX_MESSAGE_LENGTH];
   SWORD ErrorMsgMax = sizeof(ErrorMsg)-1;
   SWORD ErrorMsgLen;
   UCHAR sqlstate[10];
   STRLEN len;

   SV* errstr = DBIc_ERRSTR( imp_xxh );

   sv_setpvn( errstr, ErrorMsg, 0 );
   sv_setiv( DBIc_ERR(imp_xxh), (IV)badrc );

   /* sqlstate isn't set for SQL_NO_DATA returns.*/
   /* error code 00000 also means SQL_SUCCESS, according
   * to Solid Programmer Guide. --mms */
   strcpy( sqlstate, "00000" );
   sv_setpvn( DBIc_STATE(imp_xxh), sqlstate, 5 );
    
   switch( DBIc_TYPE(imp_xxh) )
      {
      case DBIt_DR:
         drh = (struct imp_drh_st*)(imp_xxh);
      break;
    
      case DBIt_DB:
         dbh = (struct imp_dbh_st*)(imp_xxh);
         drh = (struct imp_drh_st*)(DBIc_PARENT_COM(dbh));
      break;
    
      case DBIt_ST:
         sth = (struct imp_sth_st*)(imp_xxh);
         dbh = (struct imp_dbh_st*)(DBIc_PARENT_COM(sth));
         drh = (struct imp_drh_st*)(DBIc_PARENT_COM(dbh));
      break;
      }

   if( sth != NULL ) hstmt = sth->hstmt;
   if( dbh != NULL ) hdbc = dbh->hdbc;
   if( drh != NULL ) henv = drh->henv;

   while (i >= 0)
      {
      RETCODE rc = 0;
      if (dbis->debug >= 3)
         fprintf(DBILOGFP, "solid_error: badrc=%d rc=%d i=%d hstmt %d hdbc %d henv %d\n", 
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
   
      do {
         rc = SQLError( henv, hdbc, hstmt, sqlstate,
                        &NativeError, ErrorMsg,
                        ErrorMsgMax, &ErrorMsgLen );

         if (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO)
            {
            sv_catpvn(errstr, ErrorMsg, ErrorMsgLen);
            sv_catpv(errstr, "\n");
            sv_catpv(errstr, "(SQL-");
            sv_catpv(errstr, sqlstate);
            sv_catpv(errstr, ")\n");
            sv_setpvn(DBIc_STATE(imp_xxh), sqlstate, 5);

         if (dbis->debug >= 3)
            fprintf(DBILOGFP,  "solid_error values: sqlstate %0.5s %u\n",
                    sqlstate, NativeError);

         if (NativeError != 0)	/* set to real error */
            sv_setiv(DBIc_ERR(imp_xxh), (IV)NativeError);
            }
         } while (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO);
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
            fprintf(DBILOGFP, "%s badrc %d recorded: %s\n",
                    what, badrc, SvPV(errstr,na));
         }
      else
         { sv_setiv(DBIc_ERR(imp_xxh), (IV)0); }
      }
   
   return SvPV( DBIc_STATE(imp_xxh), len );
   }

/* -------------------------------------------------------------------------
*  dbd_preparse: 
*     - scan for placeholders (? and :xx style) and convert them to ?.
*     - builds translation table to convert positional parameters of the 
*       execute() call to :nn type placeholders.
*  We need two data structures to translate this stuff:
*     - a hash to convert positional parameters to placeholders
*     - an array, representing the actual '?' query parameters.
*     %param = (name1=>plh1, name2=>plh2, ..., name_n=>plh_n)   #
*     @qm_param = (\$param{'name1'}, \$param{'name2'}, ...) 
*
* This is the core function for binding parameters. --mms
* -------------------------------------------------------------------------*/
void dbd_preparse( imp_sth_t* imp_sth, char* statement )
   {
   dTHR;
   bool in_literal = FALSE;
   char *src, *start, *dest;
   phs_t phs_tpl;
   SV* phs_sv;
   int idx=0, style=0, laststyle=0;
   int param = 0;
   STRLEN namelen;
   char name[256];
   SV** svpp;
   SV* svref;
   char ch;

   /* allocate room for copy of statement with spare capacity
   * for editing '?' or ':1' into ':p1' so we can use obndrv.   */
   imp_sth->statement = (char*)safemalloc(strlen(statement)+1);

   /* initialise phs ready to be cloned per placeholder */
   memset( &phs_tpl, 0, sizeof(phs_tpl) );
   phs_tpl.ftype = 1;  /* VARCHAR2 */

   src  = statement;
   dest = imp_sth->statement;

   while( *src )
      {
      if (*src == '\'')
         in_literal = ~in_literal;
      
      if ((*src != ':' && *src != '?') || in_literal)
         {
         *dest++ = *src++;
         continue;
         }
   
      start = dest;			/* save name inc colon	*/ 
      ch = *src++;
	
      /* X/Open standard	*/ 
      if (ch == '?')
         {
   	   idx++;
   	   sprintf( name, "%d", idx );
   	   *dest++ = ch;
   	   style = 3;
         }

      /* ':1'	 */
      else if( isDIGIT(*src) )
         {
         char* p = name;
         *dest++ = '?';
         idx = atoi(src);
         if (idx <= 0)
            croak("Placeholder :%d must be a positive number", idx);
	    
         while( isDIGIT(*src) )
            *p++ = *src++;

         *p = 0;
         style = 1;
         }
      
      /* ':foo'  */
      else if( isALNUM(*src) )
         {
         char *p = name;
         *dest++ = '?';

         /* includes '_'	*/
         while( isALNUM(*src) )	
            *p++ = *src++;

         *p = 0;
         style = 2;
         }
      
      /* perhaps ':=' PL/SQL construct */
      else 
         {
         *dest++ = ch;
         continue;
         }
   
      *dest = '\0';			/* handy for debugging	*/
      if (laststyle && style != laststyle)
         croak("Can't mix placeholder styles (%d/%d)",style,laststyle);
      
      laststyle = style;

      if( imp_sth->params_hv == NULL )
         imp_sth->params_hv = newHV();

      namelen = strlen( name );
      svpp = hv_fetch( imp_sth->params_hv, name, namelen, 0 );

      if( svpp == NULL )
         {
         /* create SV holding the placeholder  */
         phs_tpl.sv = &sv_undef;
         phs_sv = newSVpv((char*)&phs_tpl, sizeof(phs_tpl)+namelen+1);
         strcpy( ((phs_t*)SvPVX(phs_sv))->name, name);

         /* store placeholder to params_hv */
         svpp = hv_store( imp_sth->params_hv, name, namelen, phs_sv, 0 );
         }

      svref = newRV( *svpp );

      /* store reference to placeholder to params_av */
      if( imp_sth->params_av == NULL )
         imp_sth->params_av = newAV();
      
      av_push( imp_sth->params_av, svref );

      } /* end while(*src) */

   *dest = '\0';

   if (imp_sth->params_hv)
      {
      DBIc_NUM_PARAMS(imp_sth) = (int)HvKEYS(imp_sth->params_hv);
	
      if (dbis->debug >= 2)
         fprintf(DBILOGFP, "    dbd_preparse scanned %d distinct placeholders\n",
                 (int)DBIc_NUM_PARAMS(imp_sth));
      }

   }

/* --------------------------------------------------------
* Prepare SQL statement.  Relies on dbd_preparse.
* --------------------------------------------------------- */
int dbd_st_prepare( SV* sth, char* statement, SV* attribs )
   {
   D_imp_sth(sth);
   D_imp_dbh_from_sth;
   RETCODE rc;
   dTHR;
   SV** svp;
   char cname[128];    /* cursorname */

   imp_sth->done_desc = 0;

   /* Deprecated as of ODBC 3.x.  --mms */
   /*rc = SQLAllocStmt(imp_dbh->hdbc, &imp_sth->hstmt);
   solid_error(sth, rc, "st_prepare/SQLAllocStmt"); */

   rc = SQLAllocHandle( SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt );
   solid_error( sth, rc, "st_prepare/SQLAllocHandle/Stmt" );
   
   if( rc != SQL_SUCCESS )
      { return 0; }

   /* scan statement for '?', ':1' and/or ':foo' style placeholders	*/
   dbd_preparse( imp_sth, statement );

   /* parse the (possibly edited) SQL statement */
   rc = SQLPrepare( imp_sth->hstmt, 
                    imp_sth->statement,
                    strlen(imp_sth->statement));
   solid_error( sth, rc, "st_prepare/SQLPrepare" );

   if( rc != SQL_SUCCESS )
      {
      /* SQLFreeStmt is deprecated only with option SQL_DROP. --mms
      SQLFreeStmt(imp_sth->hstmt, SQL_DROP); */
      SQLFreeHandle( SQL_HANDLE_STMT, imp_sth->hstmt );
      
      imp_sth->hstmt = SQL_NULL_HSTMT;
      return 0;
      }

#if 0 /* use DBIc macros */
   imp_sth->long_buflen   = 80;  /* typical  default	*/
   imp_sth->long_trunc_ok = 0;   /* can use blob_read()		*/
#endif 
    
   if( dbis->debug >= 2 )
      fprintf(DBILOGFP, "    dbd_st_prepare'd sql f%d\n\t%s\n",
              imp_sth->hstmt, imp_sth->statement);

   /* init sth pointers */
   imp_sth->fbh = NULL;
   imp_sth->ColNames = NULL;
   imp_sth->RowBuffer = NULL;
   imp_sth->n_result_cols = -1;
   imp_sth->RowCount = -1;
   imp_sth->eod = -1;

   /* @@@ DBI Bug ??? */
   DBIc_set( imp_sth, DBIcf_LongTruncOk,
             DBIc_is(imp_dbh, DBIcf_LongTruncOk) );
   
   DBIc_LongReadLen(imp_sth) = DBIc_LongReadLen(imp_dbh);

   sprintf( cname, "dbd_cursor_%X", imp_sth->hstmt );
   rc = SQLSetCursorName( imp_sth->hstmt, cname, strlen(cname) );

   if( rc != SQL_SUCCESS )
      warn("dbd_prepare: can't set cursor name, rc = %d", rc);

   if( dbis->debug >= 2 )
	fprintf(DBILOGFP, "    CursorName is '%s', rc=%d\n", cname, rc);

   if( attribs )
      {
      if( (svp=hv_fetch((HV*)SvRV(attribs), "blob_size",9, 0)) != NULL )
         {
         int len = SvIV( *svp );
         DBIc_LongReadLen( imp_sth ) = len;
         if( DBIc_WARN(imp_sth) )
            warn("deprecated feature: blob_size will be replaced by LongReadLen\n");
         }
      
      if( (svp=hv_fetch((HV*)SvRV(attribs), "solid_blob_size",15, 0)) != NULL )
         {
         int len = SvIV(*svp);
         DBIc_LongReadLen(imp_sth) = len;
         if( DBIc_WARN(imp_sth) )
            warn("deprecated feature: solid_blob_size will be replaced by LongReadLen\n");
         }

      if( (svp=hv_fetch((HV*)SvRV(attribs), "LongReadLen",11, 0)) != NULL )
         {
         int len = SvIV(*svp);
         DBIc_LongReadLen(imp_sth) = len;
         }
	
#if YET_NOT_IMPLEMENTED
      if( (svp=hv_fetch((HV*)SvRV(attribs), "concurrency",11, 0)) != NULL )
         {
         UDWORD param = SvIV( *svp );
         rc = SQLSetStmtOption( imp_sth->hstmt, SQL_CONCURRENCY, param );
         if( rc != SQL_SUCCESS )
            warn("prepare: can't set concurrency, rc = %d", rc);
         }
#endif
      }

   /* Call dbd_describe if this named constant is non-zero */
#if DESCRIBE_IN_PREPARE
   if( dbis->debug >= 2 )
      fprintf(DBILOGFP, "Describe in prepare: %d\n", DESCRIBE_IN_PREPARE);
      
   if( dbd_describe(sth, imp_sth) <= 0 )
      return 0;
#endif

   DBIc_IMPSET_on( imp_sth );

   return 1;
   }

/* -----------------------------------------
*  Returns 1 if arg is string, 0 otherwise.
* ------------------------------------------ */
int dbtype_is_string( int bind_type )
   {
   switch( bind_type )
      {
      case SQL_C_CHAR:
      case SQL_C_BINARY:
         return 1;
      }
   return 0;
   }    

/* ---------------------------------
* 
* ---------------------------------- */
static const char* S_SqlTypeToString( SWORD sqltype )
   {
   switch( sqltype )
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
      case SQL_WCHAR: return "WCHAR";
      case SQL_WVARCHAR: return "WVARCHAR";
      case SQL_WLONGVARCHAR: return "LONG WVARCHAR";
      }
   return "unknown";
   }

/* ------------------------------------------------------------
* I wanted a function (for debugging) that returned the actual 
* C type of a given variable. S_SqlCTypeToString returns a hex
* code, and I don't know what trick that is supposed to reveal.
* --mms 
* ------------------------------------------------------------- */
static const char* S_SqlCTypeToCTypeString( SWORD sqltype )
   {
   switch( sqltype )
      {
      case SQL_C_CHAR: return "unsigned char";
      case SQL_C_SSHORT: return "shortint";
      case SQL_C_USHORT: return "unsigned shortint";
      case SQL_C_SLONG: return "long int";
      case SQL_C_ULONG: return "unsigned long int";
      case SQL_C_FLOAT: return "float";
      case SQL_C_DOUBLE: return "double";
      case SQL_C_STINYINT: return "signed char";
      case SQL_C_UTINYINT: return "unsigned char";
      case SQL_C_SBIGINT: return "_int[64]";
      case SQL_C_UBIGINT: return "unsigned _int[64]";
      case SQL_C_BINARY: return "unsigned char *";
      case SQL_C_TYPE_DATE: return "struct";
      case SQL_C_TIME: return "struct";
      case SQL_C_TIMESTAMP: return "struct";
      case SQL_C_DATE: return "struct"; 
      }
   return "unknown";
   }

/* ---------------------------------
*
* ---------------------------------- */
static const char* S_SqlCTypeToString( SWORD sqltype )
   {
   static char s_buf[100];
#define s_c(x) case x: return #x
   switch( sqltype )
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
   sprintf( s_buf, "(unknown CType %d)", sqltype );
   return s_buf;
   }

/* --------------------------------------------
 * describes the output variables of a query,
 * allocates buffers for result rows,
 * and binds these buffers to the statement.
 * -------------------------------------------- */
int dbd_describe( SV* h, imp_sth_t* imp_sth )
   {
   RETCODE rc;
   dTHR;
   UCHAR* cbuf_ptr;    
   UCHAR* rbuf_ptr;    

   int t_cbufl=0;      /* length of all column names */
   int i;
   imp_fbh_t* fbh;
   int t_dbsize = 0;   /* size of native type */
   int t_dsize = 0;    /* display size */

   if( imp_sth->done_desc )
      return 1;        /* success, already done it, in dbd_prepare */

   imp_sth->done_desc = 1;

   rc = SQLNumResultCols( imp_sth->hstmt, &imp_sth->n_result_cols );

   solid_error( h, rc, "dbd_describe/SQLNumResultCols" );
   if( rc != SQL_SUCCESS )
      { return 0; }

   if (dbis->debug >= 2)
      fprintf(DBILOGFP, "    dbd_describe sql %d: n_result_cols=%d\n",
              imp_sth->hstmt,
              imp_sth->n_result_cols);

   DBIc_NUM_FIELDS(imp_sth) = imp_sth->n_result_cols;

   if( imp_sth->n_result_cols == 0 )
      {
	   if (dbis->debug >= 2)
         fprintf(DBILOGFP, "\tdbd_describe skipped (no result cols) (sql f%d)\n", 
                 imp_sth->hstmt);
      return 1;
      }

   /* allocate field buffers */
   Newz( 42, imp_sth->fbh, imp_sth->n_result_cols, imp_fbh_t );

   /* Pass 1: Get space needed for field names, display buffer and dbuf */
   for( fbh=imp_sth->fbh, i=0; i<imp_sth->n_result_cols; i++, fbh++ )
      {

   	UCHAR ColName[256];

      rc = SQLDescribeCol( imp_sth->hstmt, 
                           i+1, 
                           ColName,
                           sizeof(ColName), /* max col name length */
                           &fbh->ColNameLen,
                           &fbh->ColSqlType,
                           &fbh->ColDef,
                           &fbh->ColScale,
                           &fbh->ColNullable);

      /* long crash-me columns
      * get SUCCESS_WITH_INFO due to ColName truncation */
      if( rc != SQL_SUCCESS )
         solid_error5( h, rc, "describe pass 1/SQLDescribeCol", S_IsFetchError, &rc );

      if( rc != SQL_SUCCESS )
         return 0;

      if( fbh->ColNameLen >= sizeof(ColName) )
         ColName[sizeof(ColName)-1] = 0;
      else
         ColName[fbh->ColNameLen] = 0;

      t_cbufl += fbh->ColNameLen;

      rc = SQLColAttribute( imp_sth->hstmt, i+1, SQL_COLUMN_DISPLAY_SIZE,
                            NULL, 0, NULL, &fbh->ColDisplaySize );
      
      if( rc != SQL_SUCCESS )
         {
         solid_error(h, rc, 
            "describe pass 1/SQLColAttribute(DISPLAY_SIZE)");
         return 0;
         }
      
      fbh->ColDisplaySize += 1;  /* add terminator */

      /* Params for SQLColAttribute:
      * stmt_handle, column_number, field_identifier, character_attribute_ptr,
      * buffer_length, string_length_ptr, numeric_attribute_ptr */
      rc = SQLColAttribute( imp_sth->hstmt, i+1, SQL_COLUMN_LENGTH,
                            NULL, 0, NULL, &fbh->ColLength );
      
      if( dbis->debug >= 2 )
         fprintf(DBILOGFP, "dbd_describe pass 1/SQLColAttribute - column length:%d\n",
               fbh->ColLength);
      
      if( rc != SQL_SUCCESS )
         {
         solid_error(h, rc, 
            "describe pass 1/SQLColAttribute(COLUMN_LENGTH)");
         return 0;
         }

      /* change fetched size for some types */
      fbh->ftype = SQL_C_CHAR;
      
      switch( fbh->ColSqlType )
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
         case SQL_WLONGVARCHAR:
            fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth) + 1;
         break;
         
         case SQL_TIMESTAMP:
            fbh->ftype = SQL_C_TIMESTAMP;
            fbh->ColDisplaySize = sizeof(TIMESTAMP_STRUCT);
         break;
         }

      if( fbh->ftype != SQL_C_CHAR )
         {
         t_dbsize += t_dbsize % sizeof(int);     /* alignment */
         }
      
      t_dbsize += fbh->ColDisplaySize;

      if( dbis->debug >= 2 )
         fprintf(DBILOGFP, 
            "\tdbd_describe: col %d: %s, Length=%d"
            "\tDisp=%d, Prec=%d Scale=%d\n", 
            i+1, S_SqlTypeToString(fbh->ColSqlType),
            fbh->ColLength, fbh->ColDisplaySize,
            fbh->ColDef, fbh->ColScale
         );

      } /* End first pass */

   /* allocate a buffer to hold all the column names */
   Newz( 42, imp_sth->ColNames, t_cbufl + imp_sth->n_result_cols, UCHAR );

   /* allocate Row memory */
   Newz( 42, imp_sth->RowBuffer, t_dbsize + imp_sth->n_result_cols, UCHAR );

   /* Second pass:
   *  - get column names
   *  - bind column output */

   cbuf_ptr = imp_sth->ColNames;
   rbuf_ptr = imp_sth->RowBuffer;

   for( i=0, fbh = imp_sth->fbh; 
       i < imp_sth->n_result_cols && rc == SQL_SUCCESS; 
       i++, fbh++)      
      {
      int dbtype;

      switch( fbh->ftype )
         {
         case SQL_C_BINARY:
         case SQL_C_TIMESTAMP:
            rbuf_ptr += (rbuf_ptr - imp_sth->RowBuffer) % sizeof(int);
         break;
         }

      rc = SQLDescribeCol( imp_sth->hstmt, 
            i+1, 
            cbuf_ptr,
            fbh->ColNameLen+1,  /* max size from first call */
            &fbh->ColNameLen,
            &fbh->ColSqlType,
            &fbh->ColDef,
            &fbh->ColScale,
            &fbh->ColNullable);

      if( rc != SQL_SUCCESS )
         {
         solid_error(h, rc, "describe pass 2/SQLDescribeCol");
         return 0;
         }
	
      fbh->ColName = cbuf_ptr;
      cbuf_ptr[fbh->ColNameLen] = 0;
      cbuf_ptr += fbh->ColNameLen+1;
      fbh->data = rbuf_ptr;
      rbuf_ptr += fbh->ColDisplaySize;

      /* Bind output column variables */
      rc = SQLBindCol(
            imp_sth->hstmt,
            i+1,
            fbh->ftype,
            fbh->data,
            fbh->ColDisplaySize,
            &fbh->datalen);
      
      if( dbis->debug >= 2 )
         fprintf(DBILOGFP, "\tdescribe/BindCol: col %d-%s:\n\t\t"
            "sqltype=%s, ctype=%s, displaysize=%d, datalen=%d\n",
            i+1, fbh->ColName,
            S_SqlTypeToString(fbh->ColSqlType),
            S_SqlCTypeToString(fbh->ftype),
            fbh->ColDisplaySize,
            fbh->datalen
         );
         
      if( rc != SQL_SUCCESS )
         {
         solid_error(h, rc, "describe/SQLBindCol");
         return 0;
         }
      } /* end pass 2 */

   if( rc != SQL_SUCCESS )
      {
      warn("can't bind column %d (%s)", i+1, fbh->ColName);
      return 0;
      }
   
   return 1;
   }

/* ------------------------------------------------
* Execute a statement.
* <0 is error, >=0 is ok (row count)
* ------------------------------------------------- */
int dbd_st_execute( SV* sth )
   {
   D_imp_sth( sth );
   RETCODE rc;
   dTHR;
   int debug = dbis->debug;

   /* allow multiple execute() without close() 
   * for one statement */
   if( DBIc_ACTIVE(imp_sth) )
      {
      rc = SQLFreeStmt( imp_sth->hstmt, SQL_CLOSE );
      solid_error( sth, rc, "st_execute/SQLFreeStmt(SQL_CLOSE)" );
      }

   if( !imp_sth->done_desc )
      {
      /* describe and allocate storage for results (if any needed)	*/
      if( !dbd_describe(sth, imp_sth) )
         return -1; /* dbd_describe already called ora_error()	*/
      }

   /* bind input parameters */
   if( debug >= 2 )
      fprintf(DBILOGFP, "    dbd_st_execute (for sql f%d after)...\n",
               imp_sth->hstmt);

   rc = SQLExecute( imp_sth->hstmt );
   solid_error( sth, rc, "st_execute/SQLExecute" );
   if( rc != SQL_SUCCESS )
      { return -1; }

   imp_sth->RowCount = -1;
   rc = SQLRowCount( imp_sth->hstmt, &imp_sth->RowCount );
   solid_error( sth, rc, "st_execute/SQLRowCount" );
   if( rc != SQL_SUCCESS )
      { return -1; }

   if( imp_sth->n_result_cols > 0 )
      {
      /* @@@ assume only SELECT returns columns */
      DBIc_ACTIVE_on(imp_sth);
      }
   imp_sth->eod = SQL_SUCCESS;

   return 1;
   }

/* --------------------------------------------------------
* Decide whether solid_error should set error for DBI
* SQL_NO_DATA_FOUND is never an error.
* SUCCESS_WITH_INFO errors depend on some other conditions.
* --------------------------------------------------------- */
static int S_IsFetchError( SV* sth, RETCODE rc, char* sqlstate,
                           const void* par)
   {
   D_imp_sth( sth );
   dTHR;

   if( rc == SQL_SUCCESS_WITH_INFO )
      {
      /* data truncated */
      /* Check this error code -- ODBC may change at any time!  --mms */
      /* Checked.  01004 is still data truncation in Solid 3.5 --mms */
      /* if (strEQ(sqlstate, "01004"))  */
      
      if( strEQ(sqlstate, S_SQL_ST_DATA_TRUNC) )
         {      
         /* without par: error when LongTruncOk is false */
         if( par == NULL )
            return DBIc_is( imp_sth, DBIcf_LongTruncOk ) == 0;
         
         /* with par: is always OK, *par gets SQL_SUCCESS */
         *(RETCODE*)par = SQL_SUCCESS;

         return 0;
         }
	   }
   else if( rc == SQL_NO_DATA_FOUND )
      { return 0; }

   return 1;
   }

/*----------------------------------------
* running $sth->fetchrow()
*
* Note:
* There is a commented hack here used to allow for unicode chars to 
* be rendered properly.  If you use Solid 3.52, leave everything alone.
* If you use 3.51, uncomment the hack and re-build dbd-solid.
*
* Explanation of the hack:
* All unicode formats (UTF-8, -16, and -32) require at most 
* four bytes per char.  Since the Solid 3.51 libs (spec. SQLColAttribute)
* returned number of bytes (and not number of chars), then we 
* had to divide the data length by four when we wanted the length of
* any of the three unicode types WCHAR, WVARCHAR, and WLONGVARCHAR.
* As of Solid 3.52, this is no longer necessary, but I'm leaving it
* here, in case things change (again?!).  --mms
*---------------------------------------- */
AV* dbd_st_fetch( SV* sth )
   {
   D_imp_sth( sth );
   int debug = dbis->debug;
   int i;
   AV* av;
   RETCODE rc;
   dTHR;
   int num_fields;
   char cvbuf[512];
   char* p;
   int LongTruncOk = DBIc_is( imp_sth, DBIcf_LongTruncOk );
   int warn_flag = DBIc_is( imp_sth, DBIcf_WARN );
   const char* sqlstate = NULL;

   /* Check that execute() was executed sucessfully. This also implies
   * that dbd_describe() executed sucessfuly so the memory buffers
   * are allocated and bound. */
   if( !DBIc_ACTIVE(imp_sth) )
      {
      solid_error(sth, 0, "no statement executing");
      return Nullav;
      }
    
   rc = SQLFetch( imp_sth->hstmt );
   if( dbis->debug >= 2 )
      fprintf(DBILOGFP, "SQLFetch() returns %d\n", rc);

   switch( rc )
      {
      case SQL_SUCCESS:
         imp_sth->eod = rc;
      break;
      
      case SQL_SUCCESS_WITH_INFO:
         sqlstate = solid_error5(sth, rc, "st_fetch/SQLFetch", S_IsFetchError, NULL);
         imp_sth->eod = SQL_SUCCESS;
      break;
      
      case SQL_NO_DATA_FOUND:
         imp_sth->eod = rc;
         sqlstate = solid_error5(sth, rc, "st_fetch/SQLFetch", S_IsFetchError, NULL);
         return Nullav;

      default:
         solid_error(sth, rc, "st_fetch/SQLFetch");
         return Nullav;
      }

   if( imp_sth->RowCount == -1 )
      imp_sth->RowCount = 0;

   imp_sth->RowCount++;

   av = DBIS->get_fbav( imp_sth );
   num_fields = AvFILL(av)+1;	/* ??? */

   for( i=0; i < num_fields; ++i )
      {
      imp_fbh_t* fbh = &imp_sth->fbh[i];
      SV* sv = AvARRAY(av)[i]; /* Note: we (re)use the SV in the AV	*/

      /* This is the hack. */
/*
      switch( fbh->ColSqlType )
         {
         case SQL_WCHAR:
         case SQL_WVARCHAR:
         case SQL_WLONGVARCHAR:
            fbh->datalen /= 4;
         break;
         }
*/
      
      if( dbis->debug >= 2 )
         fprintf(DBILOGFP, "fetch col %d %s datalen=%d displ=%d\n",
                  i, fbh->ColName, fbh->datalen, fbh->ColDisplaySize);

      /* the normal case */
      if( fbh->datalen != SQL_NULL_DATA )
         {
         TIMESTAMP_STRUCT* ts = (TIMESTAMP_STRUCT*)fbh->data;

         if( fbh->datalen > fbh->ColDisplaySize )
            {
            /* truncated LONG ??? */
            sv_setpvn(sv, (char*)fbh->data, fbh->ColDisplaySize);
            if( !LongTruncOk && warn_flag )
               { warn("column %d: value truncated", i+1); }
            }
         else
            {
            switch( fbh->ftype )
               {               
               case SQL_C_TIMESTAMP:
                  sprintf(cvbuf, "%04d-%02d-%02d %02d:%02d:%02d",
                        ts->year, ts->month, ts->day, 
                        ts->hour, ts->minute, ts->second,
                        ts->fraction);
                  sv_setpv(sv, cvbuf);
               break;
              
               default:
                  if( dbis->debug >= 2 )
                    fprintf(DBILOGFP, "dbd_st_fetch colsqltype: %d\tlength: %d\n",
                           fbh->ColSqlType, fbh->datalen); 
                  
                  if( fbh->ColSqlType == SQL_CHAR
                        && DBIc_is(imp_sth, DBIcf_ChopBlanks)
                        && fbh->datalen > 0 )
                     {                       
                     int len = fbh->datalen;
                     char* p0  = (char*)(fbh->data);
                     char* p   = (char*)(fbh->data) + len;
                     
                     if( dbis->debug >= 2 )
                        fprintf(DBILOGFP, "dbd_st_fetch: got to here\n");
                     
                     while( p-- != p0 )
                        {
                        if( *p != ' ' )
                           break;
                        
                        len--;   
                        }
                     sv_setpvn(sv, p0, len);
                     break;
                     }
                              
                  if( dbis->debug >= 2 )
                     fprintf( DBILOGFP, "dbd_st_fetch  string: %s  length: %d\n",
                              fbh->data, fbh->datalen );
                              
                  sv_setpvn(sv, (char*)fbh->data, fbh->datalen);
               break;
   		      }
            }
         }
      else
         {
         SvOK_off(sv);
         }
      }  /* end for */

   return av;
   }

/* -------------------------------
* 
* -------------------------------- */
int dbd_st_finish( SV* sth )
   {
   D_imp_sth( sth );
   D_imp_dbh_from_sth;
   D_imp_drh_from_dbh;
   RETCODE rc;
   dTHR;
   int ret = 1;

   /* Cancel further fetches from this cursor.
   * We don't close the cursor till DESTROY (dbd_st_destroy). 
   * The application may re execute(...) it. */

   if( DBIc_ACTIVE(imp_sth) && imp_dbh->hdbc != SQL_NULL_HDBC )
      {
      rc = SQLFreeStmt( imp_sth->hstmt, SQL_CLOSE );
      solid_error( sth, rc, "st_finish/SQLFreeStmt(SQL_CLOSE)" );

      if( rc != SQL_SUCCESS )
         ret = 0;

#ifdef SOL22_AUTOCOMMIT_BUG
      if( DBIc_is(imp_dbh, DBIcf_AutoCommit) )
         {
         
         /* Deprecated as of ODBC 3.x. --mms
         rc = SQLTransact(imp_drh->henv, imp_dbh->hdbc, SQL_COMMIT); */
         
         rc = SQLEndTran( SQL_HANDLE_DBC, imp_dbh->hdbc, SQL_COMMIT );
         }
#endif
      }
   DBIc_ACTIVE_off( imp_sth );

   return ret;
   }

/* -----------------------------------------
* 
* ------------------------------------------ */
void dbd_st_destroy( SV* sth )
   {
   D_imp_sth( sth );
   D_imp_dbh_from_sth;
   D_imp_drh_from_dbh;
   RETCODE rc;
   dTHR;

   /* SQLxxx functions dump core when no connection exists. This happens
   * when the db was disconnected before perl ending. */
   if( imp_dbh->hdbc != SQL_NULL_HDBC )
      {

      /* This is deprecated when used with option SQL_DROP --mms */
      rc = SQLFreeStmt( imp_sth->hstmt, SQL_DROP );
      
      /* But its replacement does weird things.  --mms
      SQLFreeHandle(SQL_HANDLE_STMT, imp_sth->hstmt);*/
      
      if( rc != SQL_SUCCESS )
         {
         warn("warning: DBD::Solid SQLFreeStmt returns %d\n", rc);
         }
      }

   /* Free contents of imp_sth	*/
   Safefree( imp_sth->fbh );
   Safefree( imp_sth->ColNames );
   Safefree( imp_sth->RowBuffer );
   Safefree( imp_sth->statement );

   if( imp_sth->params_av )
      {
      av_undef( imp_sth->params_av );
      imp_sth->params_av = NULL;
      }

   if( imp_sth->params_hv )
      {
      HV* hv = imp_sth->params_hv;
      SV* sv;
      char* key;
      I32 retlen;

      /* free SV allocated inside the placeholder structs */
      hv_iterinit( hv );
      while( (sv = hv_iternextsv(hv, &key, &retlen)) != NULL )
         {
         if( sv != &sv_undef )
            {
            phs_t *phs_tpl = (phs_t*)(void*)SvPVX(sv);
            sv_free(phs_tpl->sv);
            }
         }
      hv_undef( imp_sth->params_hv );
      imp_sth->params_hv = NULL;
      }

   /* let DBI know we've done it	*/
   DBIc_IMPSET_off( imp_sth );
   }

/*------------------------------------------------------------
* bind placeholder.
*  Is called from Solid.xs execute()
*  AND from Solid.xs bind_param()

   SV* sth;
   SV* ph_namesv;     index of execute() parameter 1..n 
   SV* newvalue;
   SV* attribs;       may be set by Solid.xs bind_param call 
   int is_inout;      inout for procedure calls only 
   IV maxlen;         ??? 
 ------------------------------------------------------------ */
int dbd_bind_ph(SV* sth, SV* ph_namesv, SV* newvalue, SV* attribs,
                int is_inout, IV maxlen)
{
   dTHR;
   D_imp_sth(sth);
   SV** phs_svp;
   STRLEN name_len;
   char* name;
   char namebuf[30];
   phs_t* phs;

   /* passed as a number	*/
   if( SvNIOK(ph_namesv) )
      {	
      name = namebuf;
      sprintf(name, "%d", (int)SvIV(ph_namesv));
      name_len = strlen(name);
      }
   else
      {
      name = SvPV(ph_namesv, name_len);
      }

   if( dbis->debug >= 2 )
      fprintf(DBILOGFP, "bind %s <== '%.200s' (attribs: %s)\n",
         name, SvPV(newvalue,na), attribs ? SvPV(attribs,na) : "" );

   phs_svp = hv_fetch( imp_sth->params_hv, name, name_len, 0 );
   if( phs_svp == NULL )
      croak("Can't bind unknown placeholder '%s'", name);

   phs = (phs_t*)SvPVX(*phs_svp);   /* placeholder struct	*/

   if( phs->sv == &sv_undef )    /* first bind for this placeholder	*/
   	{
      phs->ftype = SQL_C_CHAR;  /* our default type VARCHAR2   */
      phs->sv = newSV(0);
      }

   if( attribs )   /* only look for ora_type on first bind of var  */
      {
      SV** svp;
      /* Setup / Clear attributes as defined by attribs.
      * XXX If attribs is EMPTY then reset attribs to default?   */
      if( (svp=hv_fetch((HV*)SvRV(attribs), "sol_type",8, 0)) != NULL)
         {
         int dbd_type = SvIV(*svp);
         
         if( !dbtype_is_string(dbd_type) )        /* mean but safe */
         croak("Can't bind %s, sol_type %d not a simple string type", 
            phs->name, dbd_type);

         phs->ftype = dbd_type;
         }
      }
 
   /* At the moment we always do sv_setsv() and rebind.
   * Later we may optimise this so that more often we can 
   * just copy the value & length over and not rebind. */
   if( !SvOK(newvalue) )   /* undef == NULL */
      {
      phs->isnull = 1;
      }
   else
      {
      phs->isnull = 0;
      sv_setsv(phs->sv, newvalue);
      }
   
   return _dbd_rebind_ph( sth, imp_sth, phs, maxlen );
   }

/* ------------------------------------------------
* walks through param_av and binds each plh found
* ------------------------------------------------- */
int _dbd_rebind_ph( SV* sth, imp_sth_t* imp_sth, phs_t* phs, 
                    int maxlen) 
   {
   int n_qm;        /* number of '?' parameters */
   int avi;
   dTHR;
   RETCODE rc;

   /* args of SQLBindParameter() call */
   SWORD fParamType;
   SWORD fCType;
   SWORD fSqlType;
   UDWORD cbColDef;
   SWORD ibScale;
   UCHAR* rgbValue;
   SDWORD cbValueMax;
   SDWORD* pcbValue;
   SWORD fNullable;

   n_qm = av_len(imp_sth->params_av) + 1;

   for( avi = 0; avi < n_qm; avi++ )
      {
      STRLEN len;
      SV** ref = av_fetch(imp_sth->params_av, avi, 0);
      SV* refd;
      phs_t* phs_refd;

      refd = SvRV(*ref);
      phs_refd = (phs_t*)SvPVX(refd);	/* placeholder struct	*/

      if( phs_refd != phs )
         continue;

      rc = SQLDescribeParam( imp_sth->hstmt,
                             avi+1,
                             &fSqlType,
                             &cbColDef,
                             &ibScale,
                             &fNullable);

      solid_error( sth, rc, "_rebind_ph/SQLDescribeParam" );
      if( rc != SQL_SUCCESS )
         return 0;

      fParamType = SQL_PARAM_INPUT;
      fCType = phs->ftype;

      /* When we fill a LONGVARBINARY, the CTYPE must be set 
       * to SQL_C_BINARY. */
      if( fCType == SQL_C_CHAR )  /* could be changed by bind_plh */
         {
         switch( fSqlType )
            {
            case SQL_BINARY:
            case SQL_VARBINARY:
            case SQL_LONGVARBINARY:
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
         }
      pcbValue = &phs->cbValue;
      if( phs->isnull )
         {
         *pcbValue = SQL_NULL_DATA;
         rgbValue = NULL;
         }
      else
         {
         rgbValue = (UCHAR*)SvPV(phs->sv, len);
         *pcbValue = (UDWORD) len;
         }
      cbValueMax = 0;

      if( dbis->debug >=2 )
         fprintf(DBILOGFP,
                  "Bind: %d, CType=%d, SqlType=%s, ColDef=%d\n",
                  avi+1, fCType, 
                  S_SqlTypeToString(fSqlType), 
                  cbColDef);

      /* I added this for debugging. --mms */
      if( dbis->debug >= 2 )
         {
         printf("Debug from _dbd_rebind_ph in dbdimp.c:\n");
         printf("Bind: %d, CType=%s, SqlType=%s, ColDef=%d\n",
                 avi+1, 
                 S_SqlCTypeToCTypeString(fCType), 
                 S_SqlTypeToString(fSqlType), 
                 cbColDef);
         }

      rc = SQLBindParameter(imp_sth->hstmt,
                            avi+1,
                            fParamType,
                            fCType,
                            fSqlType,
                            cbColDef,
                            ibScale,
                            rgbValue,
                            cbValueMax,
                            pcbValue);

      solid_error( sth, rc, "_rebind_ph/SQLBindParameter" );
      if( rc != SQL_SUCCESS )
         {
         return 0;
         }
      }
   return 1;
   }

/* ------------------------- */
int dbd_st_rows( SV* sth )
   {
   D_imp_sth( sth );
   return imp_sth->RowCount;
   }

/*------------------------------------------------------------
* blob_read:
* read part of a BLOB from a table. 
* ----------------------------------------------------------- */
static int S_IsBlobReadError( SV* sth, RETCODE rc, char* sqlstate,
                              const void* par)
   {
   D_imp_sth( sth );
   dTHR;

   if( rc == SQL_SUCCESS_WITH_INFO )
      {
      /* Data truncation */
      /* Changed explicit error code to a named constant. --mms */
      /* if (strEQ(sqlstate, "01004")) { */

      if( strEQ(sqlstate, S_SQL_ST_DATA_TRUNC ))
         {
         /* Data truncated is NORMAL during blob_read */
         return 0;
         }
      }
   else if( rc == SQL_NO_DATA_FOUND )
      return 0;
	
   return 1;
   }
	
/* -----------------------------------------
* 
* ------------------------------------------ */
dbd_st_blob_read( SV* sth, int field, long offset, long len, 
                  SV* destrv, long destoffset)
{
   D_imp_sth( sth );
   SDWORD retl;
   SV* bufsv;
   RETCODE rc;
   dTHR;

   bufsv = SvRV( destrv );
   sv_setpvn( bufsv, "", 0 );      /* ensure it's writable string  */
   SvGROW( bufsv, len+destoffset+1 );    /* SvGROW doesn't do +1 */

   rc = SQLGetData( imp_sth->hstmt, (UWORD)field+1,
            SQL_C_BINARY,
            ((UCHAR*)SvPVX(bufsv)) + destoffset,
            (SDWORD) len, &retl);

   solid_error5( sth, rc, "dbd_st_blob_read/SQLGetData", S_IsBlobReadError, NULL );

   if( dbis->debug >= 2 )
      fprintf(DBILOGFP, "SQLGetData(...,off=%d, len=%d)->rc=%d,len=%d SvCUR=%d\n",
               destoffset, len,
               rc, retl, SvCUR(bufsv));

   if( rc != SQL_SUCCESS )
      {
      if( SvIV(DBIc_ERR(imp_sth)) )
         {
         /* IsBlobReadError thinks it's an error */
         return 0;
         }
      
      if( rc == SQL_NO_DATA_FOUND )
         return 0;

      retl = len;
      }

   SvCUR_set( bufsv, destoffset+retl );

   if( dbis->debug >= 2 )
      fprintf(DBILOGFP, "blob_read: SvCUR=%d\n", SvCUR(bufsv));

   *SvEND(bufsv) = '\0'; /* consistent with perl sv_setpvn etc */
 
   return 1;
   }

/*----------------------------------------
* db level interface
* set connection attributes.
*---------------------------------------- */
static db_params S_db_storeOptions[] =
   {
   
   { "AutoCommit", SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_ON, SQL_AUTOCOMMIT_OFF },
   { "solid_characterset", SQL_TRANSLATE_OPTION },
#if 0 /* not defined by DBI/DBD specification */
   { "TRANSACTION", SQL_ACCESS_MODE, SQL_MODE_READ_ONLY, SQL_MODE_READ_WRITE },
   { "solid_trace", SQL_OPT_TRACE, SQL_OPT_TRACE_ON, SQL_OPT_TRACE_OFF },
   { "solid_timeout", SQL_LOGIN_TIMEOUT },
   { "ISOLATION", SQL_TXN_ISOLATION },
   { "solid_tracefile", SQL_OPT_TRACEFILE },
#endif
   { NULL },

   };

/* ---------------------------------
*
* ---------------------------------- */
static const db_params* S_dbOption( const db_params* pars,
                                    char* key, STRLEN len)
   {
   /* search option to set */
   while( pars->str != NULL )
      {
      if( strncmp(pars->str, key, len) == 0 && len == strlen(pars->str) )
         break;
      pars++;
      }
   if( pars->str == NULL )
      return NULL;

   return pars;
   }

/* ----------------------------------------
*
* ----------------------------------------- */ 
int dbd_db_STORE( SV* dbh, SV* keysv, SV* valuesv )
   {
   D_imp_dbh( dbh );
   D_imp_drh_from_dbh;
   RETCODE rc;
   dTHR;
   STRLEN kl;
   STRLEN plen;
   char* key = SvPV(keysv,kl);
   SV* cachesv = NULL;
   int on;
   UDWORD vParam;
   const db_params* pars;
   int parind;

   if( (pars = S_dbOption(S_db_storeOptions, key, kl)) == NULL )
      return FALSE;

   parind = pars - S_db_storeOptions;

   switch( pars->fOption )
      {
      case SQL_LOGIN_TIMEOUT:
      case SQL_TXN_ISOLATION:
         vParam = SvIV(valuesv);
	   break;

      case SQL_OPT_TRACEFILE:
	      vParam = (UDWORD) SvPV(valuesv, plen);
	   break;
   
      case SQL_TRANSLATE_OPTION:
         key = SvPV(valuesv, kl);
         if (kl == 7 && !strncmp(key, "default", kl))
            vParam = SQL_SOLID_XLATOPT_DEFAULT;
         else if (kl == 5 && !strncmp(key, "nocnv", kl))
            vParam = SQL_SOLID_XLATOPT_NOCNV;
         else if (kl == 4 && !strncmp(key, "ansi", kl))
            vParam = SQL_SOLID_XLATOPT_ANSI;
         else if (kl == 5 && !strncmp(key, "pcoem", kl))
            vParam = SQL_SOLID_XLATOPT_PCOEM;
         else if (kl == 9 && !strncmp(key, "7bitscand", kl))
            vParam = SQL_SOLID_XLATOPT_7BITSCAND;
         else
            {
            warn("solid_characterset: invalid value '%.*s'\n", kl, key);
            return FALSE;
            }
      break;

      case SQL_AUTOCOMMIT:
         on = SvTRUE(valuesv);
         vParam = on ? pars->true : pars->false;
      break;
      }

   rc = SQLSetConnectOption( imp_dbh->hdbc, pars->fOption, vParam );
   solid_error( dbh, rc, "db_STORE/SQLSetConnectOption" );

   if( rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO )
      {
      return FALSE;
	   }
   
   if( pars->fOption == SQL_AUTOCOMMIT )
      {
      if (on) DBIc_set(imp_dbh, DBIcf_AutoCommit, 1);
      else    DBIc_set(imp_dbh, DBIcf_AutoCommit, 0);
      }
  
   return TRUE;
   }

/* -------------------------------------
*
* -------------------------------------- */
static db_params S_db_fetchOptions[] = 
   {

   { "AutoCommit", SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_ON, SQL_AUTOCOMMIT_OFF },
#if 0 /* seems not supported by SOLID */
   { "sol_readonly", SQL_ACCESS_MODE, SQL_MODE_READ_ONLY, SQL_MODE_READ_WRITE },
   { "sol_trace", SQL_OPT_TRACE, SQL_OPT_TRACE_ON, SQL_OPT_TRACE_OFF },
   { "sol_timeout", SQL_LOGIN_TIMEOUT },
   { "sol_isolation", SQL_TXN_ISOLATION },
   { "sol_tracefile", SQL_OPT_TRACEFILE },
#endif
   { NULL }

   };

/* ----------------------------------- 
* 
* ------------------------------------- */
SV* dbd_db_FETCH( SV* dbh, SV* keysv )
   {
   D_imp_dbh( dbh );
   D_imp_drh_from_dbh;
   RETCODE rc;
   dTHR;
   STRLEN kl;
   STRLEN plen;
   char* key = SvPV(keysv,kl);
   int on;
   UDWORD vParam = 0;
   const db_params *pars;
   SV* retsv = NULL;

   if( (pars = S_dbOption(S_db_fetchOptions, key, kl)) == NULL )
      return Nullsv;

   /* readonly, tracefile etc. isn't working yet. only AutoCommit supported. */
   if( pars->fOption == 0xffff)
      {
	   }
   else
      {
      rc = SQLGetConnectOption( imp_dbh->hdbc, pars->fOption, &vParam );
      solid_error( dbh, rc, "db_FETCH/SQLGetConnectOption" );

      if( rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO )
         {
         if( dbis->debug >= 1 )
            fprintf(DBILOGFP,
               "SQLGetConnectOption returned %d in dbd_db_FETCH\n", rc);
         
         return Nullsv;
         }
      }
   
   switch( pars->fOption )
      {
      case SQL_LOGIN_TIMEOUT:
      case SQL_TXN_ISOLATION:
         newSViv(vParam);
      break;

      case SQL_OPT_TRACEFILE:
         retsv = newSVpv((char*)vParam, 0);
      break;

      default:
         if( vParam == pars->true )
            retsv = newSViv(1);
         else
            retsv = newSViv(0);
      break;
      }

   return sv_2mortal( retsv );
   }

#define s_A(str) { str, sizeof(str)-1 }
static T_st_params S_st_fetch_params[] = 
   {
   s_A("NUM_OF_PARAMS"),      /* 0 */
   s_A("NUM_OF_FIELDS"),      /* 1 */
   s_A("NAME"),               /* 2 */
   s_A("NULLABLE"),           /* 3 */
   s_A("TYPE"),               /* 4 */
   s_A("PRECISION"),          /* 5 */
   s_A("SCALE"),              /* 6 */
   s_A("sol_type"),           /* 7 */
   s_A("sol_length"),         /* 8 */
   s_A("CursorName"),         /* 9 */
   s_A("blob_size"),          /* 10 */
   s_A("__handled_by_dbi__"), /* 11 */ /* ChopBlanks */
   s_A("solid_blob_size"),    /* 12 */
   s_A("solid_type"),         /* 13 */
   s_A("solid_length"),       /* 14 */
   s_A("LongReadLen"),        /* 15 */
   s_A(""),                   /* END */
   };

static T_st_params S_st_store_params[] = 
   {
   s_A("blob_size"),       /* 0 */
   s_A("solid_blob_size"), /* 1 */
   s_A(""),                /* END */
   };
#undef s_A

/*----------------------------------------
* dummy routines st_XXXX
*---------------------------------------- */
SV* dbd_st_FETCH( SV* sth, SV* keysv )
   {
   D_imp_sth( sth );
   STRLEN kl;
   dTHR;
   char* key = SvPV(keysv,kl);
   int i;
   SV* retsv = NULL;
   T_st_params* par;
   int n_fields;
   imp_fbh_t* fbh;
   char cursor_name[256];
   SWORD cursor_name_len;
   RETCODE rc;
   int par_index;

   for( par = S_st_fetch_params; par->len > 0; par++ )
      if( par->len == kl && strEQ(key, par->str) )
         break;

   if( par->len <= 0 )
      return Nullsv;

   if( !imp_sth->done_desc && !dbd_describe(sth, imp_sth) )
      {
      /* dbd_describe has already called ora_error()          
      * we can't return Nullsv here because the xs code will 
      * then just pass the attribute name to DBI for FETCH.  */
      croak("Describe failed during %s->FETCH(%s)", SvPV(sth,na), key);
      }

   i = DBIc_NUM_FIELDS(imp_sth);
 
   switch( par_index = par - S_st_fetch_params )
      {
      AV* av;

      case 0:     /* NUM_OF_PARAMS */
         return Nullsv;	/* handled by DBI */

      case 1:     /* NUM_OF_FIELDS */
         retsv = newSViv(i);
      break;

      case 2:     /* NAME */
         av = newAV();
         retsv = newRV(sv_2mortal((SV*)av));
         while(--i >= 0)
            av_store(av, i, newSVpv(imp_sth->fbh[i].ColName, 0));
      break;

      case 3:     /* NULLABLE */
         av = newAV();
         retsv = newRV(sv_2mortal((SV*)av));
         while( --i >= 0 )
            {
            switch( imp_sth->fbh[i].ColNullable )
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
            }
      break;

      case 4:     /* TYPE */
         av = newAV();
         retsv = newRV(sv_2mortal((SV*)av));
         while( --i >= 0 )
            {
            int type = imp_sth->fbh[i].ColSqlType;
            av_store(av, i, newSViv(type));
            }
      break;

      case 5:     /* PRECISION */
         av = newAV();
         retsv = newRV(sv_2mortal((SV*)av));
         while( --i >= 0 )
            {
            av_store(av, i, newSViv(imp_sth->fbh[i].ColDef));
            }
      break;

      case 6:     /* SCALE */
         av = newAV();
         retsv = newRV(sv_2mortal((SV*)av));
         while( --i >= 0 )
            {
            av_store(av, i, newSViv(imp_sth->fbh[i].ColScale));
            }
      break;

      case 7:     /* dbd_type */
         if( DBIc_WARN(imp_sth) )
            warn("Depreciated feature 'sol_type'. "
                 "Please use 'solid_type' instead.");
      
      /* fall through */
      case 13:    /* solid_type */
         av = newAV();
         retsv = newRV( sv_2mortal((SV*)av) );
         while( --i >= 0 )
            {
            av_store(av, i, newSViv(imp_sth->fbh[i].ColSqlType));
            }
      break;

      case 8:     /* dbd_length */
         if( DBIc_WARN(imp_sth) )
            warn("Depreciated feature 'sol_length'. "
                 "Please use 'solid_length' instead.");

      /* fall through */
      case 14:    /* solid_length */
         av = newAV();
         retsv = newRV(sv_2mortal((SV*)av));
         while( --i >= 0 )
            {
            av_store(av, i, newSViv(imp_sth->fbh[i].ColLength));
            }
      break;

      case 9:     /* CursorName */
         rc = SQLGetCursorName( imp_sth->hstmt,
               cursor_name,
               sizeof(cursor_name),
               &cursor_name_len);
      
         solid_error( sth, rc, "st_FETCH/SQLGetCursorName" );
      
         if( rc != SQL_SUCCESS )
            {
            if( dbis->debug >= 1 )
               {
               fprintf(DBILOGFP,
                  "SQLGetCursorName returned %d in dbd_st_FETCH\n", rc);
               }
            return Nullsv;
            }
         retsv = newSVpv( cursor_name, cursor_name_len );
      break;

      case 10:    /* blob_size */
         if( DBIc_WARN(imp_sth) )
            warn("Depreciated feature 'blob_size'. "
                 "Please use 'solid_blob_size' instead.");

      /* fall through */
      case 12:    /* solid_blob_size */
      case 15:    /* LongReadLen */
         retsv = newSViv(DBIc_LongReadLen(imp_sth));
      break;

      default:
         return Nullsv;
      }

   return sv_2mortal( retsv );
   }

/* ----------------------------------------- 
* 
* ------------------------------------------ */
int dbd_st_STORE( SV* sth, SV* keysv, SV* valuesv )
   {
   D_imp_sth( sth );
   D_imp_dbh_from_sth;
   dTHR;
   STRLEN kl;
   STRLEN vl;
   char* key = SvPV( keysv, kl );
   char* value = SvPV( valuesv, vl );
   T_st_params* par;
   RETCODE rc;
 
   for( par = S_st_store_params; par->len > 0; par++ )
      if( par->len == kl && strEQ(key, par->str) )
         break;

      if( par->len <= 0 )
         return FALSE;

      switch( par - S_st_store_params )
         {
         case 0:     /* blob_size */
         case 1:     /* solid_blob_size */
#if DESCRIBE_IN_PREPARE
            warn("$sth->{blob_size} isn't longer supported.\n"
                 "You may either use the 'LongReadLen' "
                 "attribute to prepare()\nor the blob_read() "
                 "function.\n");
            return FALSE;
#endif
            DBIc_LongReadLen(imp_sth) = SvIV(valuesv);
            return TRUE;
         }

   return FALSE;
   }

