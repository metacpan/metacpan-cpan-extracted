/*
 * portions Copyright (c) 1994,1995,1996,1997  Tim Bunce
 * portions Copyright (c) 1997 Thomas K. Wenrich
 * portions Copyright (c) 1997-2001 Jeff Urlwin
 * portions Copyright (c) 2007-2013 Martin J. Evans
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 */

/*
 *  NOTES:
 *
 *  o Trace levels 1 and 2 are reserved for DBI (see DBI::DBD) so don't
 *    use them here in DBIc_TRACE_LEVEL tests.
 *    "Trace Levels" in DBI defines trace levels as:
 *    0 - Trace disabled.
 *    1 - Trace DBI method calls returning with results or errors.
 *    2 - Trace method entry with parameters and returning with results.
 *    3 - As above, adding some high-level information from the driver
 *        and some internal information from the DBI.
 *    4 - As above, adding more detailed information from the driver.
 *    5 to 15 - As above but with more and more obscure information.
 *
 * SV Manipulation Functions
 *   http://perl.active-venture.com/pod/perlapi-svfunctions.html
 * Formatted Printing of IVs, UVs, and NVs
 *   http://perldoc.perl.org/perlguts.html#Formatted-Printing-of-IVs,-UVs,-and-NVs
 *   http://cpansearch.perl.org/src/RURBAN/illguts-0.44/index.html
 * Internal replacements for standard C library functions:
 * http://perldoc.perl.org/perlclib.html
 * http://search.cpan.org/dist/Devel-PPPort/PPPort.pm
 *
 * MS ODBC 64 bit:
 * http://msdn.microsoft.com/en-us/library/ms716287%28v=vs.85%29.aspx
 */
#include <limits.h>

#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#define NEED_my_snprintf

#include "ODBC.h"
#if defined(WITH_UNICODE)
# include "unicode_helper.h"
#endif

/* trap iODBC on Unicode builds */
#if defined(WITH_UNICODE) && (defined(_IODBCUNIX_H) || defined(_IODBCEXT_H))
#error DBD::ODBC will not run properly with iODBC in unicode mode as iODBC defines wide characters as being 4 bytes in size
#endif

/* DBI defines the following but not until 1.617 so we replicate here for now */
/* will remove when DBD::ODBC requires 1.617 or above */
#ifndef DBIf_TRACE_SQL
# define DBIf_TRACE_SQL 0x00000100
#endif
#ifndef DBIf_TRACE_CON
# define DBIf_TRACE_CON 0x00000200
#endif
#ifndef DBIf_TRACE_ENC
# define DBIf_TRACE_ENC 0x00000400
#endif
#ifndef DBIf_TRACE_DBD
# define DBIf_TRACE_DBD 0x00000800
#endif
#ifndef DBIf_TRACE_TXN
# define DBIf_TRACE_TXN 0x000001000
#endif

/* combined DBI trace connection and encoding flags with DBD::ODBC ones */
/* Historically DBD::ODBC had 2 flags before they were made DBI ones */
#define UNICODE_TRACING (0x02000000|DBIf_TRACE_ENC|DBIf_TRACE_DBD)
#define CONNECTION_TRACING (0x04000000|DBIf_TRACE_CON|DBIf_TRACE_DBD)
#define DBD_TRACING DBIf_TRACE_DBD
#define TRANSACTION_TRACING (DBIf_TRACE_TXN|DBIf_TRACE_DBD)
#define SQL_TRACING (DBIf_TRACE_SQL|DBIf_TRACE_DBD)

#define TRACE0(a,b) PerlIO_printf(DBIc_LOGPIO(a), (b))
#define TRACE1(a,b,c) PerlIO_printf(DBIc_LOGPIO(a), (b), (c))
#define TRACE2(a,b,c,d) PerlIO_printf(DBIc_LOGPIO(a), (b), (c), (d))
#define TRACE3(a,b,c,d,e) PerlIO_printf(DBIc_LOGPIO(a), (b), (c), (d), (e))

/* An error return reserved for our internal use and should not clash with
   any ODBC error codes like SQL_ERROR, SQL_INVALID_HANDLE etc.
   It is used so we can call dbd_error but indicate there is no point in
   calling SQLError as the error is internal */
#define DBDODBC_INTERNAL_ERROR -999

static int taf_callback_wrapper (
    void *handle,
    int type,
    int event);
static int get_row_diag(SQLSMALLINT recno,
			imp_sth_t *imp_sth,
			char *state,
			SQLINTEGER *native,
			char *msg,
			size_t max_msg);
static SQLSMALLINT default_parameter_type(
    char *why, imp_sth_t *imp_sth, phs_t *phs);
static int post_connect(SV *dbh, imp_dbh_t *imp_dbh, SV *attr);
static int set_odbc_version(SV *dbh, imp_dbh_t *imp_dbh, SV* attr);
static const char *S_SqlTypeToString (SWORD sqltype);
static const char *S_SqlCTypeToString (SWORD sqltype);
static const char *cSqlTables = "SQLTables(%s,%s,%s,%s)";
static const char *cSqlPrimaryKeys = "SQLPrimaryKeys(%s,%s,%s)";
static const char *cSqlStatistics = "SQLStatistics(%s,%s,%s,%d,%d)";
static const char *cSqlForeignKeys = "SQLForeignKeys(%s,%s,%s,%s,%s,%s)";
static const char *cSqlColumns = "SQLColumns(%s,%s,%s,%s)";
static const char *cSqlGetTypeInfo = "SQLGetTypeInfo(%d)";
static SQLRETURN bind_columns(SV *h, imp_sth_t *imp_sth);
static void AllODBCErrors(HENV henv, HDBC hdbc, HSTMT hstmt, int output,
                          PerlIO *logfp);
static int check_connection_active(SV *h);
static int build_results(SV *sth, imp_sth_t *imp_sth,
                         SV *dbh, imp_dbh_t *imp_dbh,
                         RETCODE orc);
static int  rebind_param(SV *sth, imp_sth_t *imp_sth, imp_dbh_t *imp_dbh, phs_t *phs);
static void get_param_type(SV *sth, imp_sth_t *imp_sth, imp_dbh_t *imp_dbh, phs_t *phs);
static void check_for_unicode_param(imp_sth_t *imp_sth, phs_t *phs);

/* Function to get the console window handle which we may use in SQLDriverConnect  on WIndows */
#ifdef WIN32
static HWND GetConsoleHwnd(void);
#endif

int dbd_describe(SV *sth, imp_sth_t *imp_sth, int more);
int dbd_db_login6_sv(SV *dbh, imp_dbh_t *imp_dbh, SV *dbname,
                     SV *uid, SV *pwd, SV *attr);
int dbd_db_login6(SV *dbh, imp_dbh_t *imp_dbh, char *dbname,
                  char *uid, char *pwd, SV *attr);
int dbd_st_finish(SV *sth, imp_sth_t *imp_sth);
IV dbd_st_execute_iv(SV *sth, imp_sth_t *imp_sth);

/* for sanity/ease of use with potentially null strings */
#define XXSAFECHAR(p) ((p) ? (p) : "(null)")

/* unique value for db attrib that won't conflict with SQL types, just
 * increment by one if you are adding */
#define ODBC_IGNORE_NAMED_PLACEHOLDERS 0x8332
#define ODBC_DEFAULT_BIND_TYPE         0x8333
#define ODBC_ASYNC_EXEC                0x8334
#define ODBC_ERR_HANDLER               0x8335
#define ODBC_ROWCACHESIZE              0x8336
#define ODBC_ROWSINCACHE               0x8337
#define ODBC_FORCE_REBIND	       0x8338
#define ODBC_EXEC_DIRECT               0x8339
#define ODBC_VERSION		       0x833A
#define ODBC_CURSORTYPE                0x833B
#define ODBC_QUERY_TIMEOUT             0x833C
#define ODBC_HAS_UNICODE               0x833D
#define ODBC_PUTDATA_START             0x833E
#define ODBC_OUTCON_STR                0x833F
#define ODBC_COLUMN_DISPLAY_SIZE       0x8340
#define ODBC_UTF8_ON                   0x8341
#define ODBC_FORCE_BIND_TYPE           0x8342
#define ODBC_DESCRIBE_PARAMETERS       0x8344
#define ODBC_DRIVER_COMPLETE           0x8345
#define ODBC_BATCH_SIZE                0x8346
#define ODBC_ARRAY_OPERATIONS          0x8347
#define ODBC_TAF_CALLBACK              0x8348

/* This is the bind type for parameters we fall back to if the bind_param
   method was not given a parameter type and SQLDescribeParam is not supported
   or failed.
   It also defines the point we switch from VARCHAR to LONGVARCHAR */
#ifdef WITH_UNICODE
# define ODBC_BACKUP_BIND_TYPE_VALUE	SQL_WVARCHAR
# define ODBC_SWITCH_TO_LONGVARCHAR 2000
#else
# define ODBC_BACKUP_BIND_TYPE_VALUE	SQL_VARCHAR
# define ODBC_SWITCH_TO_LONGVARCHAR 4000
#endif

DBISTATE_DECLARE;

void dbd_init(dbistate_t *dbistate)
{
   DBIS = dbistate;
}



static RETCODE odbc_set_query_timeout(
    imp_dbh_t *imp_dbh, HSTMT hstmt, UV odbc_timeout)
{
   RETCODE rc;

   if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3)) {
      TRACE1(imp_dbh, "   Set timeout to: %"UVuf"\n", odbc_timeout);
   }
   rc = SQLSetStmtAttr(hstmt,(SQLINTEGER)SQL_ATTR_QUERY_TIMEOUT,
                       (SQLPOINTER)odbc_timeout,(SQLINTEGER)SQL_IS_INTEGER);
   if (!SQL_SUCCEEDED(rc)) {
       /* Some drivers get upset with this so we ignore errors and just trace the problem */
       if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3))
           TRACE1(
               imp_dbh,
               "    Failed to set Statement ATTR Query Timeout to %"UVuf"\n",
               odbc_timeout);
   }
   return rc;
}



static void odbc_clear_result_set(SV *sth, imp_sth_t *imp_sth)
{
   SV *value;
   char *key;
   I32 keylen;

   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3)) {
      TRACE0(imp_sth, "odbc_clear_result_set\n");
   }

   Safefree(imp_sth->fbh);
   Safefree(imp_sth->ColNames);
   Safefree(imp_sth->RowBuffer);

   /* dgood - Yikes!  I don't want to go down to this level, */
   /*         but if I don't, it won't figure out that the   */
   /*         number of columns have changed...              */
   if (DBIc_FIELDS_AV(imp_sth)) {
      sv_free((SV*)DBIc_FIELDS_AV(imp_sth));
      DBIc_FIELDS_AV(imp_sth) = Nullav;
   }

   while ( (value = hv_iternextsv((HV*)SvRV(sth), &key, &keylen)) ) {
      if (strncmp(key, "NAME_", 5) == 0 ||
	  strncmp(key, "TYPE", 4) == 0 ||
	  strncmp(key, "PRECISION", 9) == 0 ||
	  strncmp(key, "SCALE", 5) == 0 ||
	  strncmp(key, "NULLABLE", 8) == 0) {
          (void)hv_delete((HV*)SvRV(sth), key, keylen, G_DISCARD);
          if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
              TRACE2(imp_sth, "    ODBC_CLEAR_RESULTS '%s' => %s\n",
                     key, neatsvpv(value,0));
          }
      }
   }

   imp_sth->fbh       = NULL;
   imp_sth->ColNames  = NULL;
   imp_sth->RowBuffer = NULL;
   imp_sth->done_desc = 0;
}



static void odbc_handle_outparams(imp_sth_t *imp_sth, int debug)
{
   int i = (imp_sth->out_params_av) ? AvFILL(imp_sth->out_params_av)+1 : 0;
   if (debug >= 3)
      TRACE1(imp_sth, "    processing %d output parameters\n", i);

   while (--i >= 0) {
      phs_t *phs = (phs_t*)(void*)SvPVX(AvARRAY(imp_sth->out_params_av)[i]);
      SV *sv = phs->sv;
      if (debug >= 8) {
          TRACE2(imp_sth, "    outparam %s, length:%ld\n",
                 phs->name, (long)phs->strlen_or_ind);
      }

      /* phs->strlen_or_ind has been updated by ODBC to hold the length
       * of the result */
      if (phs->strlen_or_ind != SQL_NULL_DATA) {
          /*
           * When ODBC fills an output parameter buffer, the size of the
           * data that were available is written into the memory location
           * provided by strlen_or_ind pointer argument during the
           * SQLBindParameter() call.
           *
           * If the number of bytes available exceeds the size of the output
           * buffer, ODBC will truncate the data such that it fits in the
           * available buffer. However, the strlen_or_ind will still reflect
           * the size of the data before it was truncated.
           *
           * This fact provides us a way to detect truncation on this particular
           * output parameter.  Otherwise, the only way to detect truncation is
           * through a follow-up to a SQL_SUCCESS_WITH_INFO result.  Such a call
           * cannot return enough information to state exactly where the
           * truncation occurred.
           */
          SvPOK_only(sv);           /* string, disable other OK bits */
          if (phs->strlen_or_ind > phs->maxlen) { /* out param truncated */
              SvCUR_set(sv, phs->maxlen);
              *SvEND(sv) = '\0';                /* null terminate */

              if (debug >= 2) {
                  PerlIO_printf(
                      DBIc_LOGPIO(imp_sth),
                      "    outparam %s = '%s'\t(TRUNCATED from %ld to %ld)\n",
                      phs->name, SvPV_nolen(sv), (long)phs->strlen_or_ind,
                      (long)phs->maxlen);
              }
          } else {                        /* no truncation occurred */
              SvCUR_set(sv, phs->strlen_or_ind); /* new length */
              *SvEND(sv) = '\0';                 /* null terminate */
              if (phs->strlen_or_ind == phs->maxlen &&
                  (phs->sql_type == SQL_NUMERIC ||
                   phs->sql_type == SQL_DECIMAL ||
                   phs->sql_type == SQL_INTEGER ||
                   phs->sql_type == SQL_SMALLINT ||
                   phs->sql_type == SQL_FLOAT ||
                   phs->sql_type == SQL_REAL ||
                   phs->sql_type == SQL_DOUBLE)) {
                  /*
                   * fix up for oracle, which leaves the buffer at the size
                   * requested, but only returns a few characters.  The
                   * intent is to truncate down to the actual number of
                   * characters necessary.  Need to find the first null
                   * byte and set the length there.
                   */
                  char *pstart = SvPV_nolen(sv);
                  char *p = pstart;
                  while (*p != '\0') {
                      p++;
                  }

                  if (debug >= 2) {
                      PerlIO_printf(
                          DBIc_LOGPIO(imp_sth),
                          "    outparam %s = '%s'\t(len %ld), is numeric end"
                          " of buffer = %ld\n",
                          phs->name, SvPV(sv,PL_na), (long)phs->strlen_or_ind,
                          (long)(p - pstart));
                  }
                  SvCUR_set(sv, p - pstart);
              }
          }
      } else { /* is NULL */
          if (debug >= 2)
              TRACE1(imp_sth, "    outparam %s = undef (NULL)\n", phs->name);
          (void)SvOK_off(phs->sv);
      }
   }
}



static int build_results(SV *sth,
                         imp_sth_t *imp_sth,
                         SV *dbh,
                         imp_dbh_t *imp_dbh,
                         RETCODE orc)
{
   RETCODE rc;

   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
       TRACE2(imp_sth, "    build_results sql %p\t%s\n",
              imp_sth->hstmt, imp_sth->statement);

   /* init sth pointers */
   imp_sth->fbh = NULL;
   imp_sth->ColNames = NULL;
   imp_sth->RowBuffer = NULL;
   imp_sth->RowCount = -1;

   imp_sth->odbc_column_display_size = imp_dbh->odbc_column_display_size;
   imp_sth->odbc_utf8_on = imp_dbh->odbc_utf8_on;

   if (!dbd_describe(sth, imp_sth, 0)) {
       if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3)) {
           TRACE0(imp_sth, "    !!dbd_describe failed, build_results...!\n");
      }
      SQLFreeHandle(SQL_HANDLE_STMT, imp_sth->hstmt);
      imp_sth->hstmt = SQL_NULL_HSTMT;
      return 0; /* dbd_describe already called dbd_error()	*/
   }

   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3)) {
       TRACE0(imp_sth, "    dbd_describe build_results #2...!\n");
   }
   /* TO_DO why is dbd_describe called again? */
   if (dbd_describe(sth, imp_sth, 0) <= 0) {
       if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3)) {
           TRACE0(imp_sth, "    dbd_describe build_results #3...!\n");
      }
      return 0;
   }

   DBIc_IMPSET_on(imp_sth);

   if (orc != SQL_NO_DATA) {
      imp_sth->RowCount = -1;
      rc = SQLRowCount(imp_sth->hstmt, &imp_sth->RowCount);
      dbd_error(sth, rc, "build_results/SQLRowCount");
      if (rc != SQL_SUCCESS) {
          DBIc_ROW_COUNT(imp_sth) = -1;
          return -1;
      }
      DBIc_ROW_COUNT(imp_sth) = imp_sth->RowCount;
   } else {
      imp_sth->RowCount = 0;
      DBIc_ROW_COUNT(imp_sth) = 0;
   }

   DBIc_ACTIVE_on(imp_sth); /* XXX should only set for select ?	*/
   return 1;
}



int odbc_discon_all(SV *drh,
                    imp_drh_t *imp_drh)
{
   /* The disconnect_all concept is flawed and needs more work */
   if (!PL_dirty && !SvTRUE(get_sv("DBI::PERL_ENDING",0))) {
       DBIh_SET_ERR_CHAR(drh, (imp_xxh_t*)imp_drh, Nullch, 1,
                         "disconnect_all not implemented", Nullch, Nullch);
      return FALSE;
   }
   return FALSE;
}



/* error : <=(-2), ok row count : >=0, unknown count : (-1)   */
SQLLEN dbd_db_execdirect(SV *dbh,
                      SV *statement )
{
   D_imp_dbh(dbh);
   SQLRETURN ret;                               /* SQLxxx return value */
   SQLLEN rows;
   SQLHSTMT stmt;
   int dbh_active;

   if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

   ret = SQLAllocHandle(SQL_HANDLE_STMT,  imp_dbh->hdbc, &stmt );
   if (!SQL_SUCCEEDED(ret)) {
      dbd_error( dbh, ret, "Statement allocation error" );
      return(-2);
   }

   /* if odbc_query_timeout has been set, set it in the driver */
   if (imp_dbh->odbc_query_timeout != -1) {
      ret = odbc_set_query_timeout(imp_dbh, stmt, imp_dbh->odbc_query_timeout);
      if (!SQL_SUCCEEDED(ret)) {
          dbd_error(dbh, ret, "execdirect set_query_timeout");
      }
      /* don't fail if the query timeout can't be set. */
   }

   if (DBIc_TRACE(imp_dbh, SQL_TRACING, 0, 3)) {
       TRACE1(imp_dbh, "    SQLExecDirect %s\n", SvPV_nolen(statement));
   }

#ifdef WITH_UNICODE
   if (SvOK(statement) && DO_UTF8(statement)) {
       SQLWCHAR *wsql;
       STRLEN wsql_len;
       SV *sql_copy;

       if (DBIc_TRACE(imp_dbh, UNICODE_TRACING, 0, 0)) /* odbcunicode */
           TRACE0(imp_dbh, "    Processing utf8 sql in unicode mode\n");

       sql_copy = sv_mortalcopy(statement);

       SV_toWCHAR(sql_copy);

       wsql = (SQLWCHAR *)SvPV(sql_copy, wsql_len);

       ret = SQLExecDirectW(stmt, wsql, wsql_len / sizeof(SQLWCHAR));
   } else {
       if (DBIc_TRACE(imp_dbh, UNICODE_TRACING, 0, 0)) /* odbcunicode */
           TRACE0(imp_dbh, "    Processing non utf8 sql in unicode mode\n");

       ret = SQLExecDirect(stmt, (SQLCHAR *)SvPV_nolen(statement), SQL_NTS);
   }
#else
   if (DBIc_TRACE(imp_dbh, UNICODE_TRACING, 0, 0))   /* odbcunicode */
       TRACE0(imp_dbh, "      Processing sql in non-unicode mode\n");
   ret = SQLExecDirect(stmt, (SQLCHAR *)SvPV_nolen(statement), SQL_NTS);
#endif
   if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3))
      TRACE1(imp_dbh, "    SQLExecDirect = %d\n", ret);
   if (!SQL_SUCCEEDED(ret) && ret != SQL_NO_DATA) {
      dbd_error2(dbh, ret, "Execute immediate failed",
                 imp_dbh->henv, imp_dbh->hdbc, stmt );
      rows = -2;                             /* error */
   } else {
       if (ret == SQL_NO_DATA) {
           rows = 0;
       }
       else if (ret != SQL_SUCCESS) {
           dbd_error2(dbh, ret, "Execute immediate success with info",
                      imp_dbh->henv, imp_dbh->hdbc, stmt );
       }
       ret = SQLRowCount(stmt, &rows);
       if (!SQL_SUCCEEDED(ret)) {
           dbd_error( dbh, ret, "SQLRowCount failed" );
           rows = -1;
       }
   }
   ret = SQLFreeHandle(SQL_HANDLE_STMT,stmt);
   if (!SQL_SUCCEEDED(ret)) {
      dbd_error2(dbh, ret, "Statement destruction error",
                 imp_dbh->henv, imp_dbh->hdbc, stmt);
   }

   return rows;
}



void dbd_db_destroy(SV *dbh, imp_dbh_t *imp_dbh)
{
   if (DBIc_ACTIVE(imp_dbh))
      dbd_db_disconnect(dbh, imp_dbh);
   /* Nothing in imp_dbh to be freed	*/

   DBIc_IMPSET_off(imp_dbh);
   if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 8))
       TRACE0(imp_dbh, "    DBD::ODBC Disconnected!\n");
}




/*
 * quick dumb function to handle case insensitivity for DSN= or DRIVER=
 * in DSN...note this is because strncmpi is not available on all
 * platforms using that name (VC++, Debian, etc most notably).
 * Note, also, strupr doesn't seem to have a standard name, either...
 */

int dsnHasDriverOrDSN(char *dsn) {

   char upper_dsn[512];
   char *cp = upper_dsn;
   strncpy(upper_dsn, dsn, sizeof(upper_dsn)-1);
   upper_dsn[sizeof(upper_dsn)-1] = '\0';
   while (*cp != '\0') {
      *cp = toupper(*cp);
      cp++;               /* see rt 79190 was a sequence point error*/
   }
   return (strncmp(upper_dsn, "DSN=", 4) == 0 ||
           strncmp(upper_dsn, "DRIVER=", 7) == 0);
}



int dsnHasUIDorPWD(char *dsn) {

   char upper_dsn[512];
   char *cp = upper_dsn;
   strncpy(upper_dsn, dsn, sizeof(upper_dsn)-1);
   upper_dsn[sizeof(upper_dsn)-1] = '\0';
   while (*cp != '\0') {
      *cp = toupper(*cp);
      cp++;               /* see rt 79190 was a sequence point error*/
   }
   return (strstr(upper_dsn, "UID=") != 0 || strstr(upper_dsn, "PWD=") != 0);
}



/************************************************************************/
/*                                                                      */
/*  dbd_db_login                                                        */
/*  ============                                                        */
/*                                                                      */
/* NOTE: This is the old 5 argument version with no attribs             */
/*                                                                      */
/************************************************************************/
int dbd_db_login(
    SV *dbh,
    imp_dbh_t *imp_dbh,
    char *dbname,
    char *uid,
    char *pwd)
{
   return dbd_db_login6(dbh, imp_dbh, dbname, uid, pwd, Nullsv);
}



/************************************************************************/
/*                                                                      */
/*  dbd_db_login6_sv                                                    */
/*  ================                                                    */
/*                                                                      */
/*  This API was introduced in DBI after 1.607 (subversion revision     */
/*  11723) and is the same as dbd_db_login6 except the connection       */
/*  strings are SVs so we can detect unicode strings and call           */
/*  SQLDriveConnectW.                                                   */
/*                                                                      */
/************************************************************************/
int dbd_db_login6_sv(
    SV *dbh,
    imp_dbh_t *imp_dbh,
    SV *dbname,
    SV *uid,
    SV *pwd,
    SV *attr)
{
#ifndef WITH_UNICODE
   if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
       TRACE0(imp_dbh, "non-Unicode login6_sv\n");
   return dbd_db_login6(dbh, imp_dbh, SvPV_nolen(dbname),
                        (SvOK(uid) ? SvPV_nolen(uid) : NULL),
                        (SvOK(pwd) ? SvPV_nolen(pwd) : NULL), attr);
#else

   D_imp_drh_from_dbh;
   SQLRETURN rc;
   SV *wconstr;			/* copy of connection string in wide chrs */
   /* decoded connection string in wide characters and its length to work
      around an issue in older unixODBCs */
   SQLWCHAR dc_constr[512];
   STRLEN dc_constr_len;

   if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0)) {
       TRACE2(imp_dbh, "Unicode login6 dbname=%s, uid=%s, pwd=xxxxx\n",
              SvPV_nolen(dbname), neatsvpv(uid, 0));
   }

   imp_dbh->out_connect_string = Nullsv;

   if (!imp_drh->connects) {
      rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &imp_drh->henv);
      dbd_error(dbh, rc, "db_login6_sv/SQLAllocHandle(env)");
      if (!SQL_SUCCEEDED(rc)) return 0;

      if (set_odbc_version(dbh, imp_dbh, attr) != 1) return 0;
   }
   imp_dbh->henv = imp_drh->henv;	/* needed for dbd_error */

   /* If odbc_trace_file set, set it in ODBC */
   {
       SV **attr_sv;
       char *file;

       if ((attr_sv =
            DBD_ATTRIB_GET_SVP(attr, "odbc_trace_file",
                               (I32)strlen("odbc_trace_file"))) != NULL) {
           if (SvPOK(*attr_sv)) {
               file = SvPV_nolen(*attr_sv);
               rc = SQLSetConnectAttr(NULL, SQL_ATTR_TRACEFILE,
                                      file, strlen(file));
               if (!SQL_SUCCEEDED(rc)) {
                   warn("Failed to set trace file");
               }
           }
       }
   }

   /* If odbc_trace enabled, turn ODBC tracing on */
   {
       UV dc = 0;
       SV **svp;

       DBD_ATTRIB_GET_IV(attr, "odbc_trace", 10, svp, dc);
       if (svp && dc) {
           rc = SQLSetConnectAttr(NULL, SQL_ATTR_TRACE,
                                  (SQLPOINTER)SQL_OPT_TRACE_ON, 0);
           if (!SQL_SUCCEEDED(rc)) {
               warn("Failed to enable tracing");
           }
       }
   }

   rc = SQLAllocHandle(SQL_HANDLE_DBC, imp_drh->henv, &imp_dbh->hdbc);
   if (!SQL_SUCCEEDED(rc)) {
      dbd_error(dbh, rc, "db_login6_sv/SQLAllocHandle(dbc)");
      if (imp_drh->connects == 0) {
          SQLFreeHandle(SQL_HANDLE_ENV, imp_drh->henv);
          imp_drh->henv = SQL_NULL_HENV;
          imp_dbh->henv = SQL_NULL_HENV;    /* needed for dbd_error */
      }
      return 0;
   }

   /* If odbc_driver_complete specified we need to grab it */
   {
     UV dc = 0;
     SV **svp;

     DBD_ATTRIB_GET_IV(attr, "odbc_driver_complete", 20, svp, dc);
     if (svp && dc) {
       imp_dbh->odbc_driver_complete = 1;
     } else {
       imp_dbh->odbc_driver_complete = 0;
     }
   }
   /* If the connection string is too long to pass to SQLConnect or it
      contains DSN or DRIVER, we've little choice but to call
      SQLDriverConnect and need to tag the uid/pwd on the end of the
      connection string (unless they already exist). */
   if ((SvCUR(dbname) > SQL_MAX_DSN_LENGTH || /* too big for SQLConnect */
        dsnHasDriverOrDSN(SvPV_nolen(dbname))) &&
       !dsnHasUIDorPWD(SvPV_nolen(dbname))) {

       if (SvOK(uid)) {
           sv_catpv(dbname, ";UID=");
           sv_catsv(dbname, uid);
       }
       if (SvOK(pwd)) {
           sv_catpv(dbname, ";PWD=");
           sv_catsv(dbname, pwd);
       }
       sv_catpv(dbname, ";");
       /*sv_catpvf(dbname, ";UID=%s;PWD=%s;",
	 SvPV_nolen(uid), SvPV_nolen(pwd));*/
       if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
           TRACE1(imp_dbh, "Now using dbname = %s\n", SvPV_nolen(dbname));
   }

   if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
      TRACE2(imp_dbh, "    SQLDriverConnect '%s', '%s', 'xxxx'\n",
             SvPV_nolen(dbname), neatsvpv(uid, 0));

   wconstr = sv_mortalcopy(dbname);
   utf8sv_to_wcharsv(wconstr);

   /* The following is to work around a bug in SQLDriverConnectW in unixODBC
      which in at least 2.2.11 (and probably up to 2.2.13 official release
      [not pre-release]) core dumps if the wide connection string does not end
      in a 0 (even though it should not matter as we pass the length. */
   {
       char *p;

       memset(dc_constr, '\0', sizeof(dc_constr));
       p = SvPV(wconstr, dc_constr_len);
       if (dc_constr_len > (sizeof(dc_constr) - 2)) {
           croak("Cannot process connection string - too long");
       }
       memcpy(dc_constr, p, dc_constr_len);
   }

   {
       SQLWCHAR wout_str[512];
       SQLSMALLINT wout_str_len;
#ifdef WIN32
       if (imp_dbh->odbc_driver_complete) {
	 rc = SQLDriverConnectW(imp_dbh->hdbc,
				GetConsoleHwnd(), /* no hwnd */
				dc_constr,
				(SQLSMALLINT)(dc_constr_len / sizeof(SQLWCHAR)),
				wout_str, sizeof(wout_str) / sizeof(wout_str[0]),
				&wout_str_len,
				SQL_DRIVER_COMPLETE);
       } else {
#endif
       rc = SQLDriverConnectW(imp_dbh->hdbc,
                              0, /* no hwnd */
                              dc_constr,
                              (SQLSMALLINT)(dc_constr_len / sizeof(SQLWCHAR)),
                              wout_str, sizeof(wout_str) / sizeof(wout_str[0]),
                              &wout_str_len,
                              SQL_DRIVER_NOPROMPT);
#ifdef WIN32
       }
#endif
       if (SQL_SUCCEEDED(rc)) {
           imp_dbh->out_connect_string = sv_newwvn(wout_str, wout_str_len);
           if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
               TRACE1(imp_dbh, "Out connection string: %s\n",
                      SvPV_nolen(imp_dbh->out_connect_string));
       }
   }

   if (!SQL_SUCCEEDED(rc)) {
       SV *wuid, *wpwd;
       SQLWCHAR *wuidp, *wpwdp;
       SQLSMALLINT uid_len, pwd_len;

       if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
           TRACE0(imp_dbh, "    SQLDriverConnectW failed:\n");
       /*
        * Added code for DBD::ODBC 0.39 to help return a better
        * error code in the case where the user is using a
        * DSN-less connection and the dbname doesn't look like a
        * true DSN.
        */
       if (SvCUR(dbname) > SQL_MAX_DSN_LENGTH ||
           dsnHasDriverOrDSN(SvPV_nolen(dbname))) {

           /* must be DSN= or some "direct" connection attributes,
            * probably best to error here and give the user a real
            * error code because the SQLConnect call could hide the
            * real problem.
            */
           dbd_error(dbh, rc, "db_login6sv/SQLDriverConnectW");
           SQLFreeHandle(SQL_HANDLE_DBC, imp_dbh->hdbc);
           if (imp_drh->connects == 0) {
               SQLFreeHandle(SQL_HANDLE_ENV, imp_drh->henv);
               imp_drh->henv = SQL_NULL_HENV;
               imp_dbh->henv = SQL_NULL_HENV;
           }
           return 0;
       }

       /* ok, the DSN is short, so let's try to use it to connect
        * and quietly take all error messages */
       AllODBCErrors(imp_dbh->henv, imp_dbh->hdbc, 0, 0, DBIc_LOGPIO(imp_dbh));

       if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
           TRACE2(imp_dbh, "    SQLConnect '%s', '%s'\n",
                  neatsvpv(dbname, 0), neatsvpv(uid, 0));

       wconstr = sv_mortalcopy(dbname);
       utf8sv_to_wcharsv(wconstr);
       if (SvOK(uid)) {
           wuid = sv_mortalcopy(uid);
           utf8sv_to_wcharsv(wuid);
           wuidp = (SQLWCHAR *)SvPV_nolen(wuid);
           uid_len = SvCUR(wuid) / sizeof(SQLWCHAR);
       } else {
           wuidp = NULL;
           uid_len = 0;
       }

       if (SvOK(pwd)) {
           wpwd = sv_mortalcopy(pwd);
           utf8sv_to_wcharsv(wpwd);
           wpwdp = (SQLWCHAR *)SvPV_nolen(wpwd);
           pwd_len = SvCUR(wpwd) / sizeof(SQLWCHAR);
       } else {
           wpwdp = NULL;
           pwd_len = 0;
       }

       rc = SQLConnectW(imp_dbh->hdbc,
                        (SQLWCHAR *)SvPV_nolen(wconstr),
                        (SQLSMALLINT)(SvCUR(wconstr) / sizeof(SQLWCHAR)),
                        wuidp, uid_len,
                        wpwdp, pwd_len);
   }
   if (!SQL_SUCCEEDED(rc)) {
      dbd_error(dbh, rc, "db_login6sv/SQLConnectW");
      SQLFreeHandle(SQL_HANDLE_DBC, imp_dbh->hdbc);
      imp_dbh->hdbc = SQL_NULL_HDBC;
      if (imp_drh->connects == 0) {
          SQLFreeHandle(SQL_HANDLE_ENV, imp_drh->henv);
          imp_drh->henv = SQL_NULL_HENV;
          imp_dbh->henv = SQL_NULL_HENV;
      }
      return 0;
   } else if (rc == SQL_SUCCESS_WITH_INFO) {
       dbd_error(dbh, rc, "db_login6sv/SQLConnectW");
   }

   if (post_connect(dbh, imp_dbh, attr) != 1) return 0;

   imp_drh->connects++;
   DBIc_IMPSET_on(imp_dbh);	/* imp_dbh set up now			*/
   DBIc_ACTIVE_on(imp_dbh);	/* call disconnect before freeing	*/
   return 1;
#endif  /* WITH_UNICODE */

}



/************************************************************************/
/*                                                                      */
/*  dbd_db_login6                                                       */
/*  =============                                                       */
/*                                                                      */
/*  A newer version of the dbd_db_login API with the additional attr as */
/*  the sixth argument. Once everyone upgrades to at least              */
/*  DBI 1.60X (where X > 7) this API won't get called anymore since     */
/*  dbd_db_login6_sv will be favoured.                                  */
/*                                                                      */
/*  NOTE: I had hoped to make dbd_db_login6_sv support Unicode and      */
/*  dbd_db_login6 to not support Unicode but as no one (except me) has  */
/*  a DBI which supports dbd_db_login6_sv and unixODBC REQUIRES us to   */
/*  call SQLDriverConnectW if we are going to call other SQLXXXW        */
/*  functions later I've got no choice but to convert the ASCII strings */
/*  passed to dbd_db_login6 to wide characters when DBD::ODBC is built  */
/*  for Unicode.                                                        */
/*                                                                      */
/************************************************************************/
int dbd_db_login6(
    SV *dbh,
    imp_dbh_t *imp_dbh,
    char *dbname,
    char *uid,
    char *pwd,
    SV *attr)
{
   D_imp_drh_from_dbh;

   RETCODE rc;
   char dbname_local[512];
#ifdef WITH_UNICODE
   SQLWCHAR wconstr[512];
   STRLEN wconstr_len;
   unsigned int i;
#endif

   if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
       TRACE0(imp_dbh, "dbd_db_login6\n");
   if (!imp_drh->connects) {
      rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &imp_drh->henv);
      dbd_error(dbh, rc, "db_login6/SQLAllocHandle(env)");
      if (!SQL_SUCCEEDED(rc)) return 0;

      if (set_odbc_version(dbh, imp_dbh, attr) != 1) return 0;
   }
   imp_dbh->henv = imp_drh->henv;	/* needed for dbd_error */

   /* If odbc_trace_file set, set it in ODBC */
   {
       SV **attr_sv;
       char *file;

       if ((attr_sv =
            DBD_ATTRIB_GET_SVP(attr, "odbc_trace_file",
                               (I32)strlen("odbc_trace_file"))) != NULL) {
           if (SvPOK(*attr_sv)) {
               file = SvPV_nolen(*attr_sv);
               rc = SQLSetConnectAttr(NULL, SQL_ATTR_TRACEFILE,
                                      file, strlen(file));
               if (!SQL_SUCCEEDED(rc)) {
                   warn("Failed to set trace file");
               }
           }
       }
   }

   /* If odbc_trace enabled, turn ODBC tracing on */
   {
       UV dc = 0;
       SV **svp;

       DBD_ATTRIB_GET_IV(attr, "odbc_trace", 10, svp, dc);
       if (svp && dc) {
           rc = SQLSetConnectAttr(NULL, SQL_ATTR_TRACE,
                                  (SQLPOINTER)SQL_OPT_TRACE_ON, 0);
           if (!SQL_SUCCEEDED(rc)) {
               warn("Failed to enable tracing");
           }
       }
   }

   imp_dbh->out_connect_string = NULL;

   rc = SQLAllocHandle(SQL_HANDLE_DBC, imp_drh->henv, &imp_dbh->hdbc);
   if (!SQL_SUCCEEDED(rc)) {
      dbd_error(dbh, rc, "db_login6/SQLAllocHandle(dbc)");
      if (imp_drh->connects == 0) {
          SQLFreeHandle(SQL_HANDLE_ENV, imp_drh->henv);
          imp_drh->henv = SQL_NULL_HENV;
          imp_dbh->henv = SQL_NULL_HENV;    /* needed for dbd_error */
      }
      return 0;
   }

#ifndef DBD_ODBC_NO_SQLDRIVERCONNECT
   /* If the connection string is too long to pass to SQLConnect or it
      contains DSN or DRIVER, we've little choice to but to call
      SQLDriverConnect and need to tag the uid/pwd on the end of the
      connection string (unless they already exist). */

   if ((strlen(dbname) > SQL_MAX_DSN_LENGTH ||
        dsnHasDriverOrDSN(dbname)) && !dsnHasUIDorPWD(dbname)) {

       if ((strlen(dbname) +
            (uid ? strlen(uid) : 0) +
            (pwd ? strlen(pwd) : 0) +
            12) >
           sizeof(dbname_local)) {
           croak("Connection string too long");
       }
       strcpy(dbname_local, dbname);
       if (uid) {
           strcat(dbname_local, ";UID=");
           strcat(dbname_local, uid);
       }
       if (pwd) {
           strcat(dbname_local, ";PWD=");
           strcat(dbname_local, pwd);
       }
       dbname = dbname_local;
   }

   if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
      TRACE2(imp_dbh, "    SQLDriverConnect '%s', '%s', 'xxxx'\n",
             dbname, (uid ? uid : ""));

# ifdef WITH_UNICODE
   if (strlen(dbname) > (sizeof(wconstr) / sizeof(wconstr[0]))) {
       croak("Connection string too big to convert to wide characters");
   }

   /* The following is a massive simplification assuming only 7-bit ASCII
      is ever passed to dbd_db_login6 */
   for (i = 0; i < strlen(dbname); i++) {
       wconstr[i] = dbname[i];
   }
   wconstr[i] = 0;
   wconstr_len = i;

   {
       SQLWCHAR wout_str[512];
       SQLSMALLINT wout_str_len;

       rc = SQLDriverConnectW(imp_dbh->hdbc,
                              0, /* no hwnd */
                              wconstr, (SQLSMALLINT)wconstr_len,
                              wout_str, sizeof(wout_str) / sizeof(wout_str[0]),
                              &wout_str_len,
                              SQL_DRIVER_NOPROMPT);
       if (SQL_SUCCEEDED(rc)) {
           imp_dbh->out_connect_string = sv_newwvn(wout_str, wout_str_len);
           if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
               TRACE1(imp_dbh, "Out connection string: %s\n",
                      SvPV_nolen(imp_dbh->out_connect_string));
       }
   }

# else  /* WITH_UNICODE */

   {
       char out_str[512];
       SQLSMALLINT out_str_len;

       /* Work around a bug in mdbtools where the out connection string length
          can sometimes be unset. We set it to a ridiculous value and if it
          remains we know mdbtools did not return it. */
       out_str_len = 9999;

       rc = SQLDriverConnect(imp_dbh->hdbc,
                             0, /* no hwnd */
                             dbname,
                             (SQLSMALLINT)strlen(dbname),
                             out_str, sizeof(out_str), &out_str_len,
                             SQL_DRIVER_NOPROMPT);
       if (SQL_SUCCEEDED(rc)) {
           if (out_str_len == 9999) {
               imp_dbh->out_connect_string = newSVpv("", 0);
           } else {
               imp_dbh->out_connect_string = newSVpv(out_str, out_str_len);
           }

           if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
       	       TRACE1(imp_dbh, "Out connection string: %s\n",
                      SvPV_nolen(imp_dbh->out_connect_string));
       }
   }
# endif  /* WITH_UNICODE */
#else
   /* if we are using something that can not handle SQLDriverconnect,
    * then set rc to a not OK state and we'll fall back on SQLConnect
    */
   rc = SQL_ERROR;
#endif

   if (!SQL_SUCCEEDED(rc)) {
       if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 4)) {
#ifdef DBD_ODBC_NO_SQLDRIVERCONNECT
           TRACE0(imp_dbh, "    !SQLDriverConnect unsupported.\n");
#else
           TRACE0(imp_dbh, "    SQLDriverConnect failed:\n");
#endif
      }

#ifndef DBD_ODBC_NO_SQLDRIVERCONNECT
      /*
       * Added code for DBD::ODBC 0.39 to help return a better
       * error code in the case where the user is using a
       * DSN-less connection and the dbname doesn't look like a
       * true DSN.
       */
      if (strlen(dbname) > SQL_MAX_DSN_LENGTH || dsnHasDriverOrDSN(dbname)) {

	 /* must be DSN= or some "direct" connection attributes,
	  * probably best to error here and give the user a real
	  * error code because the SQLConnect call could hide the
	  * real problem.
	  */
	 dbd_error(dbh, rc, "db_login/SQLConnect");
	 SQLFreeHandle(SQL_HANDLE_DBC, imp_dbh->hdbc);
	 if (imp_drh->connects == 0) {
             SQLFreeHandle(SQL_HANDLE_ENV, imp_drh->henv);
             imp_drh->henv = SQL_NULL_HENV;
             imp_dbh->henv = SQL_NULL_HENV;
	 }
	 return 0;
      }

      /* ok, the DSN is short, so let's try to use it to connect
       * and quietly take all error messages */
      AllODBCErrors(imp_dbh->henv, imp_dbh->hdbc, 0, 0, DBIc_LOGPIO(imp_dbh));
#endif /* DriverConnect supported */

      if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
          TRACE2(imp_dbh, "    SQLConnect '%s', '%s'\n",
                 dbname, (uid ? uid : ""));
#ifdef WITH_UNICODE
      {
          SQLWCHAR wuid[100], wpwd[100];
          SQLSMALLINT uid_len, pwd_len;
          SQLWCHAR *wuidp, *wpwdp;

          if (uid) {
              for (i = 0; i < strlen(uid); i++) {
                  wuid[i] = uid[i];
              }
              wuid[i] = 0;
              wuidp = wuid;
              uid_len = strlen(uid);
          } else {
              wuidp = NULL;
              uid_len = 0;
          }

          if (pwd) {
              for (i = 0; i < strlen(pwd); i++) {
                  wpwd[i] = pwd[i];
              }
              wpwd[i] = 0;
              wpwdp = wpwd;
              pwd_len = strlen(pwd);
          } else {
              wpwdp = NULL;
              pwd_len = 0;
          }

          for (i = 0; i < strlen(dbname); i++) {
              wconstr[i] = dbname[i];
          }
          wconstr[i] = 0;
          wconstr_len = i;

          rc = SQLConnectW(imp_dbh->hdbc,
                           wconstr, wconstr_len,
                           wuidp, uid_len,
                           wpwdp, pwd_len);
      }
#else
      rc = SQLConnect(imp_dbh->hdbc,
		      dbname, (SQLSMALLINT)strlen(dbname),
		      uid, (SQLSMALLINT)(uid ? strlen(uid) : 0),
		      pwd, (SQLSMALLINT)(pwd ? strlen(pwd) : 0));
#endif
   }

   if (!SQL_SUCCEEDED(rc)) {
      dbd_error(dbh, rc, "db_login6/SQLConnect");
      SQLFreeHandle(SQL_HANDLE_DBC, imp_dbh->hdbc);
      if (imp_drh->connects == 0) {
          SQLFreeHandle(SQL_HANDLE_ENV, imp_drh->henv);
          imp_drh->henv = SQL_NULL_HENV;
          imp_dbh->henv = SQL_NULL_HENV;
      }
      return 0;
   } else if (rc == SQL_SUCCESS_WITH_INFO) {
       dbd_error(dbh, rc, "db_login6/SQLConnect");
   }

   if (post_connect(dbh, imp_dbh, attr) != 1) return 0;

   imp_drh->connects++;
   DBIc_IMPSET_on(imp_dbh);	/* imp_dbh set up now			*/
   DBIc_ACTIVE_on(imp_dbh);	/* call disconnect before freeing	*/
   return 1;
}



int dbd_db_disconnect(SV *dbh, imp_dbh_t *imp_dbh)
{
   RETCODE rc;
   D_imp_drh_from_dbh;
   SQLUINTEGER autoCommit = SQL_AUTOCOMMIT_OFF;

   /* We assume that disconnect will always work	*/
   /* since most errors imply already disconnected.	*/
   DBIc_ACTIVE_off(imp_dbh);

   if (imp_dbh->out_connect_string) {
       SvREFCNT_dec(imp_dbh->out_connect_string);
   }

   rc = SQLGetConnectAttr(
       imp_dbh->hdbc, SQL_ATTR_AUTOCOMMIT, &autoCommit, SQL_IS_UINTEGER, 0);
   if (!SQL_SUCCEEDED(rc)) {
       /* quietly handle a problem with SQLGetConnectAttr() */
       AllODBCErrors(imp_dbh->henv, imp_dbh->hdbc, 0,
                     DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 4),
                     DBIc_LOGPIO(imp_dbh));
   }
   rc = SQLDisconnect(imp_dbh->hdbc);
   if (!SQL_SUCCEEDED(rc)) {
       char state[SQL_SQLSTATE_SIZE+1];

       (void)SQLGetDiagField(SQL_HANDLE_DBC, imp_dbh->hdbc, 1,
                             SQL_DIAG_SQLSTATE,
                             (SQLCHAR *)state, sizeof(state), NULL);
       if (strcmp(state, "25000") == 0) {
           if (DBIc_TRACE(imp_dbh, TRANSACTION_TRACING, 0, 3))
               TRACE0(imp_dbh, "SQLDisconnect, Transaction in progress\n");

           DBIh_SET_ERR_CHAR(
               dbh, (imp_xxh_t*)imp_dbh, "0" /* warning state */, 1,
               "Disconnect with transaction in progress - rolling back",
               state, Nullch);
           (void)dbd_db_rollback(dbh, imp_dbh);
           rc = SQLDisconnect(imp_dbh->hdbc);
       }
       if (!SQL_SUCCEEDED(rc)) {
           dbd_error(dbh, rc, "db_disconnect/SQLDisconnect");
           /* if disconnect fails, fall through. Probably not disconnected */
       }
   }
   if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
       TRACE1(imp_dbh, "SQLDisconnect=%d\n", rc);

   SQLFreeHandle(SQL_HANDLE_DBC, imp_dbh->hdbc);
   imp_dbh->hdbc = SQL_NULL_HDBC;
   imp_drh->connects--;
   strcpy(imp_dbh->odbc_dbms_name, "disconnect");
   if (imp_drh->connects == 0) {
       SQLFreeHandle(SQL_HANDLE_ENV, imp_drh->henv);
       imp_drh->henv = SQL_NULL_HENV;
       imp_dbh->henv = SQL_NULL_HENV;
   }
   /* We don't free imp_dbh since a reference still exists	*/
   /* The DESTROY method is the only one to 'free' memory.	*/
   /* Note that statement objects may still exist for this dbh!	*/

   return 1;
}




int dbd_db_commit(SV *dbh, imp_dbh_t *imp_dbh)
{
   RETCODE rc;

   rc = SQLEndTran(SQL_HANDLE_DBC, imp_dbh->hdbc, SQL_COMMIT);
   if (!SQL_SUCCEEDED(rc)) {
      dbd_error(dbh, rc, "db_commit/SQLEndTran");
      return 0;
   }
   /* support for DBI 1.20 begin_work */
   if (DBIc_has(imp_dbh, DBIcf_BegunWork)) {
      /* reset autocommit */
      rc = SQLSetConnectAttr(
          imp_dbh->hdbc, SQL_ATTR_AUTOCOMMIT, (SQLPOINTER)SQL_AUTOCOMMIT_ON, 0);
      DBIc_off(imp_dbh,DBIcf_BegunWork);
   }
   return 1;
}



int dbd_db_rollback(SV *dbh, imp_dbh_t *imp_dbh)
{
   RETCODE rc;

   rc = SQLEndTran(SQL_HANDLE_DBC, imp_dbh->hdbc, SQL_ROLLBACK);
   if (!SQL_SUCCEEDED(rc)) {
      dbd_error(dbh, rc, "db_rollback/SQLEndTran");
      return 0;
   }
   /* support for DBI 1.20 begin_work */
   if (DBIc_has(imp_dbh, DBIcf_BegunWork)) {
      /*  reset autocommit */
      rc = SQLSetConnectAttr(
          imp_dbh->hdbc, SQL_ATTR_AUTOCOMMIT, (SQLPOINTER)SQL_AUTOCOMMIT_ON, 0);
      DBIc_off(imp_dbh,DBIcf_BegunWork);
   }
   return 1;
}



void dbd_error2(
    SV *h,
    RETCODE err_rc,
    char *what,
    HENV henv,
    HDBC hdbc,
    HSTMT hstmt)
{
    D_imp_xxh(h);
    int error_found = 0;

    /*
     * It's a shame to have to add all this stuff with imp_dbh and
     * imp_sth, but imp_dbh is needed to get the odbc_err_handler
     * and imp_sth is needed to get imp_dbh.
     */
    struct imp_dbh_st *imp_dbh = NULL;
    struct imp_sth_st *imp_sth = NULL;

    if (err_rc == SQL_SUCCESS) return;

    if (DBIc_TRACE(imp_xxh, DBD_TRACING, 0, 4) && (err_rc != SQL_SUCCESS)) {
        PerlIO_printf(
            DBIc_LOGPIO(imp_xxh),
            "    !!dbd_error2(err_rc=%d, what=%s, handles=(%p,%p,%p)\n",
            err_rc, (what ? what : "null"), henv, hdbc, hstmt);
    }

    switch(DBIc_TYPE(imp_xxh)) {
      case DBIt_ST:
        imp_sth = (struct imp_sth_st *)(imp_xxh);
        imp_dbh = (struct imp_dbh_st *)(DBIc_PARENT_COM(imp_sth));
        break;
      case DBIt_DB:
        imp_dbh = (struct imp_dbh_st *)(imp_xxh);
        break;
      default:
        croak("panic: dbd_error2 on bad handle type");
    }

    while(henv != SQL_NULL_HENV) {
        SQLCHAR sqlstate[SQL_SQLSTATE_SIZE+1];
        /*
         *  ODBC spec says ErrorMsg must not be greater than
         *  SQL_MAX_MESSAGE_LENGTH but we concatenate a little
         *  on the end later (e.g. sql state) so make room for more.
         */
        SQLCHAR ErrorMsg[SQL_MAX_MESSAGE_LENGTH+512];
        SQLSMALLINT ErrorMsgLen;
        SQLINTEGER NativeError;
        RETCODE rc = 0;

        /* TBD: 3.0 update */
        /* It is important we check for DBDODBC_INTERNAL_ERROR first so if we issue
	   an internal error AND there are ODBC diagnostics, ours come first */
        while(err_rc == DBDODBC_INTERNAL_ERROR ||
              SQL_SUCCEEDED(rc=SQLError(
                                henv, hdbc, hstmt,
                                sqlstate, &NativeError,
                                ErrorMsg, sizeof(ErrorMsg)-1, &ErrorMsgLen))) {

            error_found = 1;
            if (err_rc == DBDODBC_INTERNAL_ERROR) {
                strcpy(ErrorMsg, what);
                strcpy(sqlstate, "HY000");
                NativeError = 1;
                err_rc = SQL_ERROR;
            } else {
                ErrorMsg[ErrorMsgLen] = '\0';
                sqlstate[SQL_SQLSTATE_SIZE] = '\0';
            }
            if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3)) {
                PerlIO_printf(DBIc_LOGPIO(imp_dbh),
                              "    !SQLError(%p,%p,%p) = "
                              "(%s, %ld, %s)\n",
                              henv, hdbc, hstmt, sqlstate,
                              (long)NativeError, ErrorMsg);
            }

            /*
             * If there's an error handler, run it and see what it returns...
             * (lifted from DBD:Sybase 0.21)
             */
            if(imp_dbh->odbc_err_handler) {
                dSP;
                int retval, count;

                ENTER;
                SAVETMPS;
                PUSHMARK(sp);

                if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3))
                    TRACE0(imp_dbh, "    Calling error handler\n");

                /*
                 * Here are the args to the error handler routine:
                 *    1. sqlstate (string)
                 *    2. ErrorMsg (string)
                 *    3. NativeError (integer)
                 * That's it for now...
                 */
                XPUSHs(sv_2mortal(newSVpv(sqlstate, 0)));
                XPUSHs(sv_2mortal(newSVpv(ErrorMsg, 0)));
                XPUSHs(sv_2mortal(newSViv(NativeError)));
                XPUSHs(sv_2mortal(newSViv(err_rc)));

                PUTBACK;
                if((count = call_sv(imp_dbh->odbc_err_handler, G_SCALAR)) != 1)
                    croak("An error handler can't return a LIST.");
                SPAGAIN;
                retval = POPi;

                PUTBACK;
                FREETMPS;
                LEAVE;

                /* If the called sub returns 0 then ignore this error */
                if(retval == 0) {
                    if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3))
                        TRACE0(imp_dbh,
                               "    Handler caused error to be ignored\n");
                    continue;
                }
            }
            strcat(ErrorMsg, " (SQL-");
            strcat(ErrorMsg, sqlstate);
            strcat(ErrorMsg, ")");
            if (SQL_SUCCEEDED(err_rc)) {
                DBIh_SET_ERR_CHAR(h, imp_xxh, "" /* information state */,
                                  1, ErrorMsg, sqlstate, Nullch);
            } else {
                DBIh_SET_ERR_CHAR(h, imp_xxh, Nullch, 1, ErrorMsg,
                                  sqlstate, Nullch);
            }
            continue;
        }
        if (rc != SQL_NO_DATA_FOUND) {	/* should never happen */
            if (DBIc_TRACE(imp_xxh, DBD_TRACING, 0, 3))
                TRACE1(imp_dbh,
                       "    !!SQLError returned %d unexpectedly.\n", rc);
            if (!PL_dirty) {           /* not in global destruction */
                DBIh_SET_ERR_CHAR(
                    h, imp_xxh, Nullch, 1,
                    "    Unable to fetch information about the error",
                    "IM008", Nullch);
            }
        }
        /* climb up the tree each time round the loop		*/
        if (hstmt != SQL_NULL_HSTMT) hstmt = SQL_NULL_HSTMT;
        else if (hdbc  != SQL_NULL_HDBC)  hdbc  = SQL_NULL_HDBC;
        else henv = SQL_NULL_HENV;	/* done the top		*/
    }
    /* some broken drivers may return an error and then not provide an
       error message */

    if (!error_found && (err_rc != SQL_NO_DATA_FOUND)) {
        /* DON'T REMOVE "No error found" from the string below
           people rely on it as the state was IM008 and I changed it
           to HY000 */
        if (DBIc_TRACE(imp_xxh, DBD_TRACING, 0, 3))
            TRACE1(imp_dbh, "    ** No error found %d **\n", err_rc);
        DBIh_SET_ERR_CHAR(
            h, imp_xxh, Nullch, 1,
            "    Unable to fetch information about the error", "HY000", Nullch);
    }

}



/*------------------------------------------------------------
empties entire ODBC error queue.
------------------------------------------------------------*/
void dbd_error(SV *h, RETCODE err_rc, char *what)
{
    D_imp_xxh(h);

    struct imp_dbh_st *imp_dbh = NULL;
    struct imp_sth_st *imp_sth = NULL;
    HSTMT hstmt = SQL_NULL_HSTMT;

    switch(DBIc_TYPE(imp_xxh)) {
      case DBIt_ST:
        imp_sth = (struct imp_sth_st *)(imp_xxh);
        imp_dbh = (struct imp_dbh_st *)(DBIc_PARENT_COM(imp_sth));
        hstmt = imp_sth->hstmt;
        break;
      case DBIt_DB:
        imp_dbh = (struct imp_dbh_st *)(imp_xxh);
        break;
      default:
        croak("panic: dbd_error on bad handle type");
    }
    /*
     * If status is SQL_SUCCESS, there's no error, so we can just return.
     * There may be status or other non-error messsages though.
     * We want those messages if the debug level is set to at least 3.
     * If an error handler is installed, let it decide what messages
     * should or shouldn't be reported.
     */
    if ((err_rc == SQL_SUCCESS) && !DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3) &&
        !imp_dbh->odbc_err_handler)
        return;

    dbd_error2(h, err_rc, what, imp_dbh->henv, imp_dbh->hdbc, hstmt);
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
void dbd_preparse(imp_sth_t *imp_sth, char *statement)
{
   enum STATES {DEFAULT, LITERAL, COMMENT, LINE_COMMENT};
   enum STATES state = DEFAULT;
   enum STYLES {
       STYLE_NONE,                              /* no style 0 */
       STYLE_NUMBER,                            /* :N 1 */
       STYLE_NAME,                              /* :name 2*/
       STYLE_NORMAL                             /* ? 3 */
   };
   char literal_ch = '\0';

   char *src, *dest;                            /* input and output SQL */
   phs_t phs_tpl;
   int idx=0;                                   /* parameter number */
   enum STYLES style = STYLE_NONE;        /* type of parameter */
   enum STYLES laststyle = STYLE_NONE;    /* last type of parameter */

   imp_sth->statement = (char*)safemalloc(strlen(statement)+1);

   /* initialize phs ready to be cloned per placeholder	*/
   memset(&phs_tpl, 0, sizeof(phs_tpl));
   phs_tpl.value_type = SQL_C_CHAR;
   phs_tpl.sv = &PL_sv_undef;

   src  = statement;
   dest = imp_sth->statement;
   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5)) {
       TRACE1(imp_sth, "    ignore named placeholders = %d\n",
              imp_sth->odbc_ignore_named_placeholders);
   }

   while(*src) {
       enum STATES next_state = state;

       switch (state) {
         case DEFAULT: {
             if ((*src == '\'') || (*src == '"')) {
                 literal_ch = *src;             /* save quote chr */
                 next_state = LITERAL;
             } else if ((*src == '/') && (*(src + 1) == '*')) {
                 next_state = COMMENT;          /* in comment */
             } else if ((*src == '-') && (*(src + 1) == '-')) {
                 next_state = LINE_COMMENT;     /* in line comment */
             } else if ((*src == '?') || (*src == ':')) {
                 STRLEN namelen;
                 char name[256];         /* current named parameter */
                 SV **svpp;
                 char ch;

                 ch = *src++;
                 if (ch == '?') {                    /* X/Open standard */
                     idx++;
                     my_snprintf(name, sizeof(name), "%d", idx);
                     *dest++ = ch;
                     style = STYLE_NORMAL;
                 } else if (isDIGIT(*src)) {                 /* ':1' */
                     char *p = name;
                     *dest++ = '?';
                     idx = atoi(src);
                     while(isDIGIT(*src))
                         *p++ = *src++;
                     *p = 0;
                     style = STYLE_NUMBER;
                     if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
                         TRACE1(imp_sth,
                                "    found numbered parameter = %s\n", name);
                 } else if (!imp_sth->odbc_ignore_named_placeholders &&
                          isALNUM(*src)) {
                     /* ':foo' is valid, only if we are not ignoring named parameters */
                     char *p = name;
                     idx++;
                     *dest++ = '?';

                     while(isALNUM(*src))	/* includes '_'	*/
                         *p++ = *src++;
                     *p = 0;
                     style = STYLE_NAME;
                     if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
                         TRACE1(imp_sth, "    found named parameter = %s\n", name);
                 } else {          /* perhaps ':=' PL/SQL construct */
                     *dest++ = ch;
                     continue;
                 }
                 *dest = '\0';			/* handy for debugging	*/
                 if (laststyle && style != laststyle)
                     croak("Can't mix placeholder styles (%d/%d)",
                           style,laststyle);
                 laststyle = style;

                 if (imp_sth->all_params_hv == NULL)
                     imp_sth->all_params_hv = newHV();
                 namelen = strlen(name);

                 svpp = hv_fetch(imp_sth->all_params_hv, name, (I32)namelen, 0);
                 if (svpp == NULL) {
                     SV *phs_sv;
                     phs_t *phs;

                     if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
                         TRACE2(imp_sth,
                                "    creating new parameter key %s, index %d\n", name, idx);
                     /* create SV holding the placeholder */
                     phs_sv = newSVpv((char*)&phs_tpl, sizeof(phs_tpl)+namelen+1);
                     phs = (phs_t*)SvPVX(phs_sv);
                     strcpy(phs->name, name);
                     phs->idx = idx;

                     /* store placeholder to all_params_hv */
                     svpp = hv_store(imp_sth->all_params_hv, name, (I32)namelen, phs_sv, 0);
                 } else {
                     if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
                         TRACE1(imp_sth,
                                "    parameter key %s already exists\n", name);
                     croak("DBD::ODBC does not yet support binding a named parameter more than once\n");
                 }
                 break;
             }
             *dest++ = *src++;
             break;
         }
         case LITERAL: {
             if (*src == literal_ch) {
                 next_state = DEFAULT;
             }
             *dest++ = *src++;
             break;
         }
         case COMMENT: {
             if ((*(src - 1) == '*') && (*src == '/')) {
                 next_state = DEFAULT;
             }
             *dest++ = *src++;
             break;
         }
         case LINE_COMMENT: {
             if (*src == '\n') {
                 next_state = DEFAULT;
             }
             *dest++ = *src++;
             break;
         }
       }
       state = next_state;
   }

   *dest = '\0';
   if (imp_sth->all_params_hv) {
      DBIc_NUM_PARAMS(imp_sth) = (int)HvKEYS(imp_sth->all_params_hv);
      if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
          TRACE1(imp_sth,
                 "    dbd_preparse scanned %d distinct placeholders\n",
                 (int)DBIc_NUM_PARAMS(imp_sth));
   }
}



int dbd_st_tables(
    SV *dbh,
    SV *sth,
    SV *catalog,
    SV *schema,
    SV *table,
    SV *table_type)
{
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;
    int dbh_active;
    size_t max_stmt_len;
    char *acatalog = NULL;
    char *aschema = NULL;
    char *atable = NULL;
    char *atype = NULL;

    imp_sth->henv = imp_dbh->henv;
    imp_sth->hdbc = imp_dbh->hdbc;

    imp_sth->done_desc = 0;

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        PerlIO_printf(DBIc_LOGPIO(imp_sth), "dbd_st_tables(%s,%s,%s,%s)\n",
                      SvOK(catalog) ? SvPV_nolen(catalog) : "undef",
                      (schema && SvOK(schema)) ? SvPV_nolen(schema) : "undef",
                      (table && SvOK(table)) ? SvPV_nolen(table) : "undef",
                      (table_type && SvOK(table_type)) ? SvPV_nolen(table_type) : "undef");

    if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

    rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
        dbd_error(sth, rc, "st_tables/SQLAllocHandle(stmt)");
        return 0;
    }

    if (SvOK(catalog)) acatalog = SvPV_nolen(catalog);
    if (!imp_dbh->catalogs_supported) {
        acatalog = NULL;
        *catalog = PL_sv_undef;
    }
    if (SvOK(schema)) aschema = SvPV_nolen(schema);
    if (!imp_dbh->schema_usage) {
        aschema = NULL;
        *schema = PL_sv_undef;
    }

    if (SvOK(table)) atable = SvPV_nolen(table);
    if (SvOK(table_type)) atype = SvPV_nolen(table_type);

   max_stmt_len =
       strlen(cSqlTables)+
       strlen(XXSAFECHAR(acatalog)) +
       strlen(XXSAFECHAR(aschema)) +
       strlen(XXSAFECHAR(atable)) +
       strlen(XXSAFECHAR(atype))+1;

   imp_sth->statement = (char *)safemalloc(max_stmt_len);
   my_snprintf(imp_sth->statement, max_stmt_len, cSqlTables,
               XXSAFECHAR(acatalog), XXSAFECHAR(aschema),
               XXSAFECHAR(atable), XXSAFECHAR(atype));

#ifdef WITH_UNICODE
   {
       SQLWCHAR *wcatalog = NULL;
       SQLWCHAR *wschema = NULL;
       SQLWCHAR *wtable = NULL;
       SQLWCHAR *wtype = NULL;
       STRLEN wlen;
       SV *copy;

       if (SvOK(catalog)) {
           /*printf("CATALOG OK %"IVdf" /%s/\n", SvCUR(catalog), SvPV_nolen(catalog));*/

           copy = sv_mortalcopy(catalog);
           SV_toWCHAR(copy);
           wcatalog = (SQLWCHAR *)SvPV(copy, wlen);
       }
       if (SvOK(schema)) {
           copy = sv_mortalcopy(schema);
           SV_toWCHAR(copy);
           wschema = (SQLWCHAR *)SvPV(copy, wlen);
       }
       if (SvOK(table)) {
           copy = sv_mortalcopy(table);
           SV_toWCHAR(copy);
           wtable = (SQLWCHAR *)SvPV(copy, wlen);
       }
       if (SvOK(table_type)) {
           copy = sv_mortalcopy(table_type);
           SV_toWCHAR(copy);
           wtype = (SQLWCHAR *)SvPV(copy, wlen);
       }
       /*
       printf("wcatalog = %p\n", wcatalog);
       for (i = 0; i < 10; i++) {
           printf("%d\n", wcatalog[i]);
       }
       */
       rc = SQLTablesW(imp_sth->hstmt,
                       wcatalog ? wcatalog : NULL, SQL_NTS,
                       wschema ? wschema : NULL, SQL_NTS,
                       wtable ? wtable : NULL, SQL_NTS,
                       wtype ? wtype : NULL, SQL_NTS		/* type (view, table, etc) */
                      );
   }
#else
   {
       rc = SQLTables(imp_sth->hstmt,
                      acatalog ? acatalog : NULL, SQL_NTS,
                      aschema ? aschema : NULL, SQL_NTS,
                      atable ? atable : NULL, SQL_NTS,
                      atype ? atype : NULL, SQL_NTS /* type (view, table, etc) */
                      );
   }

#endif  /* WITH_UNICODE */

   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
       TRACE2(imp_dbh, "    SQLTables=%d (type=%s)\n",
           rc, atype ? atype : "(null)");

   dbd_error(sth, rc, "st_tables/SQLTables");
   if (!SQL_SUCCEEDED(rc)) {
      SQLFreeHandle(SQL_HANDLE_STMT,imp_sth->hstmt);
      imp_sth->hstmt = SQL_NULL_HSTMT;
      return 0;
   }
   return build_results(sth, imp_sth, dbh, imp_dbh, rc);

}

#ifdef OLD_ONE_BEFORE_SCALARS
int dbd_st_tables(
    SV *dbh,
    SV *sth,
    char *catalog,
    char *schema,
    char *table,
    char *table_type)
{
   D_imp_dbh(dbh);
   D_imp_sth(sth);
   RETCODE rc;
   int dbh_active;
   size_t max_stmt_len;

   imp_sth->henv = imp_dbh->henv;
   imp_sth->hdbc = imp_dbh->hdbc;

   imp_sth->done_desc = 0;

   if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

   rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
   if (rc != SQL_SUCCESS) {
      dbd_error(sth, rc, "st_tables/SQLAllocHandle(stmt)");
      return 0;
   }

   max_stmt_len =
       strlen(cSqlTables)+
       strlen(XXSAFECHAR(catalog)) +
       strlen(XXSAFECHAR(schema)) +
       strlen(XXSAFECHAR(table)) +
       strlen(XXSAFECHAR(table_type))+1;

   imp_sth->statement = (char *)safemalloc(max_stmt_len);
   my_snprintf(imp_sth->statement, max_stmt_len, cSqlTables,
               XXSAFECHAR(catalog), XXSAFECHAR(schema),
               XXSAFECHAR(table), XXSAFECHAR(table_type));

   rc = SQLTables(imp_sth->hstmt,
		  (catalog && *catalog) ? catalog : 0, SQL_NTS,
		  (schema && *schema) ? schema : 0, SQL_NTS,
		  (table && *table) ? table : 0, SQL_NTS,
		  table_type && *table_type ? table_type : 0,
                  SQL_NTS		/* type (view, table, etc) */
		 );

   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
       TRACE2(imp_dbh, "   Tables result %d (%s)\n",
           rc, table_type ? table_type : "(null)");

   dbd_error(sth, rc, "st_tables/SQLTables");
   if (!SQL_SUCCEEDED(rc)) {
      SQLFreeHandle(SQL_HANDLE_STMT,imp_sth->hstmt);
      imp_sth->hstmt = SQL_NULL_HSTMT;
      return 0;
   }
   return build_results(sth, imp_sth, dbh, imp_dbh, rc);
}
#endif  /* OLD_ONE_BEFORE_SCALARS */



int dbd_st_primary_keys(
    SV *dbh,
    SV *sth,
    char *catalog,
    char *schema,
    char *table)
{
   D_imp_dbh(dbh);
   D_imp_sth(sth);
   RETCODE rc;
   int dbh_active;
   size_t max_stmt_len;

   imp_sth->henv = imp_dbh->henv;
   imp_sth->hdbc = imp_dbh->hdbc;

   imp_sth->done_desc = 0;

   if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

   rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
   if (rc != SQL_SUCCESS) {
      dbd_error(sth, rc, "odbc_db_primary_key_info/SQLAllocHandle(stmt)");
      return 0;
   }

   /* just for sanity, later.  Any internals that may rely on this (including */
   /* debugging) will have valid data */
   max_stmt_len =
       strlen(cSqlPrimaryKeys)+
       strlen(XXSAFECHAR(catalog))+
       strlen(XXSAFECHAR(schema))+
       strlen(XXSAFECHAR(table))+1;

   imp_sth->statement = (char *)safemalloc(max_stmt_len);

   my_snprintf(imp_sth->statement, max_stmt_len,
               cSqlPrimaryKeys, XXSAFECHAR(catalog), XXSAFECHAR(schema),
               XXSAFECHAR(table));

   rc = SQLPrimaryKeys(imp_sth->hstmt,
		       (catalog && *catalog) ? catalog : 0, SQL_NTS,
		       (schema && *schema) ? schema : 0, SQL_NTS,
		       (table && *table) ? table : 0, SQL_NTS);

   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
       PerlIO_printf(
           DBIc_LOGPIO(imp_dbh),
           "    SQLPrimaryKeys call: cat = %s, schema = %s, table = %s\n",
           XXSAFECHAR(catalog), XXSAFECHAR(schema), XXSAFECHAR(table));

   dbd_error(sth, rc, "st_primary_key_info/SQLPrimaryKeys");

   if (!SQL_SUCCEEDED(rc)) {
      SQLFreeHandle(SQL_HANDLE_STMT,imp_sth->hstmt);
      imp_sth->hstmt = SQL_NULL_HSTMT;
      return 0;
   }

   return build_results(sth, imp_sth, dbh, imp_dbh, rc);
}



int dbd_st_statistics(
    SV *dbh,
    SV *sth,
    char *catalog,
    char *schema,
    char *table,
    int unique,
    int quick)
{
   D_imp_dbh(dbh);
   D_imp_sth(sth);
   RETCODE rc;
   int dbh_active;
   SQLUSMALLINT odbc_unique;
   SQLUSMALLINT odbc_quick;
   size_t max_stmt_len;

   imp_sth->henv = imp_dbh->henv;
   imp_sth->hdbc = imp_dbh->hdbc;

   imp_sth->done_desc = 0;

   if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

   rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
   if (rc != SQL_SUCCESS) {
      dbd_error(sth, rc, "odbc_db_primary_key_info/SQLAllocHandle(stmt)");
      return 0;
   }

   odbc_unique = (unique ? SQL_INDEX_UNIQUE : SQL_INDEX_ALL);
   odbc_quick = (quick ? SQL_QUICK : SQL_ENSURE);

   /* just for sanity, later.  Any internals that may rely on this (including */
   /* debugging) will have valid data */
   max_stmt_len =
       strlen(cSqlStatistics)+
       strlen(XXSAFECHAR(catalog))+
       strlen(XXSAFECHAR(schema))+
       strlen(XXSAFECHAR(table))+1;

   imp_sth->statement = (char *)safemalloc(max_stmt_len);

   my_snprintf(imp_sth->statement, max_stmt_len,
               cSqlStatistics, XXSAFECHAR(catalog), XXSAFECHAR(schema),
               XXSAFECHAR(table), unique, quick);

   rc = SQLStatistics(imp_sth->hstmt,
                      (catalog && *catalog) ? catalog : 0, SQL_NTS,
                      (schema && *schema) ? schema : 0, SQL_NTS,
                      (table && *table) ? table : 0, SQL_NTS,
                      odbc_unique, odbc_quick);

   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
       PerlIO_printf(
           DBIc_LOGPIO(imp_dbh),
           "    SQLStatistics call: cat = %s, schema = %s, table = %s"
           ", unique=%d, quick = %d\n",
           XXSAFECHAR(catalog), XXSAFECHAR(schema), XXSAFECHAR(table),
           odbc_unique, odbc_quick);
   }

   dbd_error(sth, rc, "st_statistics/SQLStatistics");

   if (!SQL_SUCCEEDED(rc)) {
       SQLFreeHandle(SQL_HANDLE_STMT,imp_sth->hstmt);
       imp_sth->hstmt = SQL_NULL_HSTMT;
       return 0;
   }

   return build_results(sth, imp_sth, dbh, imp_dbh, rc);
}



/************************************************************************/
/*                                                                      */
/*  odbc_st_prepare                                                     */
/*  ===============                                                     */
/*                                                                      */
/*  dbd_st_prepare is the old API which is now replaced with            */
/*  dbd_st_prepare_sv (taking a perl scalar) so this is now:            */
/*                                                                      */
/*  a) just a wrapper around dbd_st_prepare_sv and                      */
/*  b) not used - see ODBC.c                                            */
/*                                                                      */
/************************************************************************/
int odbc_st_prepare(
   SV *sth,
   imp_sth_t *imp_sth,
   char *statement,
   SV *attribs)
{
    SV *sql;

    sql = sv_newmortal();

    sv_setpvn(sql, statement, strlen(statement));

    return dbd_st_prepare_sv(sth, imp_sth, sql, attribs);
}



/************************************************************************/
/*                                                                      */
/*  odbc_st_prepare_sv                                                  */
/*  ==================                                                  */
/*                                                                      */
/*  dbd_st_prepare_sv is the newer version of dbd_st_prepare taking a   */
/*  a perl scalar for the sql statement instead of a char* so it may be */
/*  unicode                                                             */
/*                                                                      */
/************************************************************************/
int odbc_st_prepare_sv(
    SV *sth,
    imp_sth_t *imp_sth,
    SV *statement,
    SV *attribs)
{
   D_imp_dbh_from_sth;
   RETCODE rc;
   int dbh_active;
   char *sql;

   sql = SvPV_nolen(statement);

   imp_sth->done_desc = 0;
   imp_sth->henv = imp_dbh->henv;
   imp_sth->hdbc = imp_dbh->hdbc;
    /* inherit from connection */
   imp_sth->odbc_ignore_named_placeholders =
       imp_dbh->odbc_ignore_named_placeholders;
   imp_sth->odbc_default_bind_type = imp_dbh->odbc_default_bind_type;
   imp_sth->odbc_force_bind_type = imp_dbh->odbc_force_bind_type;
   imp_sth->odbc_force_rebind = imp_dbh->odbc_force_rebind;
   imp_sth->odbc_query_timeout = imp_dbh->odbc_query_timeout;
   imp_sth->odbc_putdata_start = imp_dbh->odbc_putdata_start;
   imp_sth->odbc_column_display_size = imp_dbh->odbc_column_display_size;
   imp_sth->odbc_utf8_on = imp_dbh->odbc_utf8_on;
   imp_sth->odbc_exec_direct = imp_dbh->odbc_exec_direct;
   imp_sth->odbc_describe_parameters = imp_dbh->odbc_describe_parameters;
   imp_sth->odbc_batch_size = imp_dbh->odbc_batch_size;
   imp_sth->odbc_array_operations = imp_dbh->odbc_array_operations;
   imp_sth->param_status_array = NULL;

   if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 5)) {
       TRACE1(imp_dbh, "    initializing sth query timeout to %ld\n",
              (long)imp_dbh->odbc_query_timeout);
   }

   if ((dbh_active = check_connection_active(sth)) == 0) return 0;

   rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
   if (!SQL_SUCCEEDED(rc)) {
      dbd_error(sth, rc, "st_prepare/SQLAllocHandle(stmt)");
      return 0;
   }

   {
      /*
       * allow setting of odbc_execdirect in prepare() or overriding
       */
       SV **attr_sv;
      /* if the attribute is there, let it override what the default
       * value from the dbh is (set above).
       * NOTE:
       * There are unfortunately two possible attributes because of an early
       * typo in DBD::ODBC which we keep for backwards compatibility.
       */
      if ((attr_sv =
           DBD_ATTRIB_GET_SVP(attribs, "odbc_execdirect",
                              (I32)strlen("odbc_execdirect"))) != NULL) {
          imp_sth->odbc_exec_direct = SvIV(*attr_sv) != 0;
      }
      if ((attr_sv =
           DBD_ATTRIB_GET_SVP(attribs, "odbc_exec_direct",
                              (I32)strlen("odbc_exec_direct"))) != NULL) {
          imp_sth->odbc_exec_direct = SvIV(*attr_sv) != 0;
      }
   }

   {
       /*
        * allow setting of odbc_describe_parameters in prepare() or overriding
        */
       SV **attr_sv;
       /* if the attribute is there, let it override what the default
        * value from the dbh is (set above).
        */
       if ((attr_sv =
            DBD_ATTRIB_GET_SVP(
                attribs, "odbc_describe_parameters",
                (I32)strlen("odbc_describe_parameters"))) != NULL) {
           imp_sth->odbc_describe_parameters = SvIV(*attr_sv) != 0;
       }
   }

   {                                            /* MS SQL Server query notification */
       SV **attr_sv;
       if ((attr_sv =
            DBD_ATTRIB_GET_SVP(
                attribs, "odbc_qn_msgtxt",
                (I32)strlen("odbc_qn_msgtxt"))) != NULL) {
           rc = SQLSetStmtAttr(imp_sth->hstmt,
                               1234 /*SQL_SOPT_SS_QUERYNOTIFICATION_MSGTEXT*/,
                               (SQLPOINTER)SvPV_nolen(*attr_sv), SQL_NTS);
           if (!SQL_SUCCEEDED(rc)) {
               dbd_error(sth, rc, "SQLSetStmtAttr(QUERYNOTIFICATION_MSGTXT)");
               SQLFreeHandle(SQL_HANDLE_STMT, imp_sth->hstmt);
               imp_sth->hstmt = SQL_NULL_HSTMT;
               return 0;
           }
       }
       if ((attr_sv =
            DBD_ATTRIB_GET_SVP(
                attribs, "odbc_qn_options",
                (I32)strlen("odbc_qn_options"))) != NULL) {
           rc = SQLSetStmtAttr(imp_sth->hstmt,
                               1235 /*SQL_SOPT_SS_QUERYNOTIFICATION_OPTIONS*/,
                               (SQLPOINTER)SvPV_nolen(*attr_sv), SQL_NTS);
           if (!SQL_SUCCEEDED(rc)) {
               dbd_error(sth, rc, "SQLSetStmtAttr(QUERYNOTIFICATION_OPTIONS)");
               SQLFreeHandle(SQL_HANDLE_STMT, imp_sth->hstmt);
               imp_sth->hstmt = SQL_NULL_HSTMT;
               return 0;
           }
       }
       if ((attr_sv =
            DBD_ATTRIB_GET_SVP(
                attribs, "odbc_qn_timeout",
                (I32)strlen("odbc_qn_timeout"))) != NULL) {
           rc = SQLSetStmtAttr(imp_sth->hstmt,
                               1233 /*SQL_SOPT_SS_QUERYNOTIFICATION_TIMEOUT*/,
                               (SQLPOINTER)SvIV(*attr_sv), SQL_NTS);
           if (!SQL_SUCCEEDED(rc)) {
               dbd_error(sth, rc, "SQLSetStmtAttr(QUERYNOTIFICATION_TIMEOUT)");
               SQLFreeHandle(SQL_HANDLE_STMT, imp_sth->hstmt);
               imp_sth->hstmt = SQL_NULL_HSTMT;
               return 0;
           }
       }
   }

   /* scan statement for '?', ':1' and/or ':foo' style placeholders	*/
   dbd_preparse(imp_sth, sql);

   /* Hold this statement for subsequent call of dbd_execute */
   if (!imp_sth->odbc_exec_direct) {
       if (DBIc_TRACE(imp_dbh, SQL_TRACING, 0, 3)) {
           TRACE1(imp_dbh, "    SQLPrepare %s\n", imp_sth->statement);
       }
#ifdef WITH_UNICODE
       if (SvOK(statement) && DO_UTF8(statement)) {
           SQLWCHAR *wsql;
           STRLEN wsql_len;
           SV *sql_copy;

           if (DBIc_TRACE(imp_dbh, UNICODE_TRACING, 0, 0)) /* odbcunicode */
               TRACE0(imp_dbh, "    Processing utf8 sql in unicode mode for SQLPrepareW\n");

           sql_copy = sv_newmortal();
           sv_setpv(sql_copy, imp_sth->statement);
#ifdef sv_utf8_decode
           sv_utf8_decode(sql_copy);
#else
           SvUTF8_on(sql_copy);
#endif
           SV_toWCHAR(sql_copy);

           wsql = (SQLWCHAR *)SvPV(sql_copy, wsql_len);

           rc = SQLPrepareW(imp_sth->hstmt, wsql, wsql_len / sizeof(SQLWCHAR));
       } else {
           if (DBIc_TRACE(imp_dbh, UNICODE_TRACING, 0, 0)) /* odbcunicode */
               TRACE0(imp_dbh, "    Processing non-utf8 sql in unicode mode\n");

           rc = SQLPrepare(imp_sth->hstmt, imp_sth->statement, SQL_NTS);
       }

#else  /* !WITH_UNICODE */
       if (DBIc_TRACE(imp_dbh, UNICODE_TRACING, 0, 0)) /* odbcunicode */
           TRACE0(imp_dbh, "      Processing sql in non-unicode mode for SQLPrepare\n");

       rc = SQLPrepare(imp_sth->hstmt, imp_sth->statement, SQL_NTS);
#endif
       if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3))
           TRACE1(imp_dbh, "    SQLPrepare = %d\n", rc);

       if (!SQL_SUCCEEDED(rc)) {
           dbd_error(sth, rc, "st_prepare/SQLPrepare");
           SQLFreeHandle(SQL_HANDLE_STMT, imp_sth->hstmt);
           imp_sth->hstmt = SQL_NULL_HSTMT;
           return 0;
       }
   } else if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3)) {
       TRACE1(imp_dbh, "    odbc_exec_direct=1, statement (%s) "
              "held for later exec\n", imp_sth->statement);
   }

   /* init sth pointers */
   imp_sth->henv = imp_dbh->henv;
   imp_sth->hdbc = imp_dbh->hdbc;
   imp_sth->fbh = NULL;
   imp_sth->ColNames = NULL;
   imp_sth->RowBuffer = NULL;
   imp_sth->RowCount = -1;

   /*
    * If odbc_async_exec is set and odbc_async_type is SQL_AM_STATEMENT,
    * we need to set the SQL_ATTR_ASYNC_ENABLE attribute.
    */
   if (imp_dbh->odbc_async_exec &&
       imp_dbh->odbc_async_type == SQL_AM_STATEMENT){
       rc = SQLSetStmtAttr(imp_sth->hstmt,
                           SQL_ATTR_ASYNC_ENABLE,
                           (SQLPOINTER) SQL_ASYNC_ENABLE_ON,
                           SQL_IS_UINTEGER);
       if (!SQL_SUCCEEDED(rc)) {
           dbd_error(sth, rc, "st_prepare/SQLSetStmtAttr");
           SQLFreeHandle(SQL_HANDLE_STMT, imp_sth->hstmt);
           imp_sth->hstmt = SQL_NULL_HSTMT;
           return 0;
       }
   }

   /*
    * If odbc_query_timeout is set (not -1)
    * we need to set the SQL_ATTR_QUERY_TIMEOUT
    */
   if (imp_sth->odbc_query_timeout != -1){
       odbc_set_query_timeout(imp_dbh, imp_sth->hstmt, imp_sth->odbc_query_timeout);
       if (!SQL_SUCCEEDED(rc)) {
           dbd_error(sth, rc, "set_query_timeout");
       }
       /* don't fail if the query timeout can't be set. */
   }

   DBIc_IMPSET_on(imp_sth);
   return 1;
}



/* Given SQL type return string description - only used in debug output */
static const char *S_SqlTypeToString (SWORD sqltype)
{
   switch(sqltype) {
      case SQL_CHAR:	return "CHAR";
      case SQL_NUMERIC:	return "NUMERIC";
      case SQL_DECIMAL:	return "DECIMAL";
      case SQL_INTEGER:	return "INTEGER";
      case SQL_SMALLINT:	return "SMALLINT";
      case SQL_FLOAT:	return "FLOAT";
      case SQL_REAL:	return "REAL";
      case SQL_DOUBLE:	return "DOUBLE";
      case SQL_VARCHAR:	return "VARCHAR";
#ifdef SQL_WCHAR
      case SQL_WCHAR: return "UNICODE CHAR";
#endif
#ifdef SQL_WVARCHAR
        /* added for SQLServer 7 ntext type 2/24/2000 */
      case SQL_WVARCHAR: return "UNICODE VARCHAR";
#endif
#ifdef SQL_WLONGVARCHAR
      case SQL_WLONGVARCHAR: return "UNICODE LONG VARCHAR";
#endif
      case SQL_DATE:	return "DATE";
      case SQL_TYPE_DATE:	return "DATE";
      case SQL_TIME:	return "TIME";
      case SQL_TYPE_TIME:	return "TIME";
      case SQL_TIMESTAMP:	return "TIMESTAMP";
      case SQL_TYPE_TIMESTAMP: return "TIMESTAMP";
      case SQL_LONGVARCHAR: return "LONG VARCHAR";
      case SQL_BINARY:	return "BINARY";
      case SQL_VARBINARY: return "VARBINARY";
      case SQL_LONGVARBINARY: return "LONG VARBINARY";
      case SQL_BIGINT:	return "BIGINT";
      case SQL_TINYINT:	return "TINYINT";
      case SQL_BIT:	return "BIT";
      case MS_SQLS_XML_TYPE: return "MS SQL Server XML";
   }
   return "unknown";
}



static const char *S_SqlCTypeToString (SWORD sqltype)
{
   static char s_buf[100];
#define s_c(x) case x: return #x
   switch(sqltype) {
      s_c(SQL_C_CHAR);
      s_c(SQL_C_LONG);
      s_c(SQL_C_SLONG);
      s_c(SQL_C_ULONG);
      s_c(SQL_C_WCHAR);
      s_c(SQL_C_BIT);
      s_c(SQL_C_TINYINT);
      s_c(SQL_C_STINYINT);
      s_c(SQL_C_UTINYINT);
      s_c(SQL_C_SHORT);
      s_c(SQL_C_SSHORT);
      s_c(SQL_C_USHORT);
      s_c(SQL_C_NUMERIC);
      s_c(SQL_C_DEFAULT);
      s_c(SQL_C_SBIGINT);
      s_c(SQL_C_UBIGINT);
/*      s_c(SQL_C_BOOKMARK); duplicate case */
      s_c(SQL_C_GUID);
      s_c(SQL_C_FLOAT);
      s_c(SQL_C_DOUBLE);
      s_c(SQL_C_BINARY);
/*      s_c(SQL_C_VARBOOKMARK); duplicate case */
      s_c(SQL_C_DATE);
      s_c(SQL_C_TIME);
      s_c(SQL_C_TIMESTAMP);
      s_c(SQL_C_TYPE_DATE);
      s_c(SQL_C_TYPE_TIME);
      s_c(SQL_C_TYPE_TIMESTAMP);
   }
#undef s_c
   my_snprintf(s_buf, sizeof(s_buf), "(CType %d)", sqltype);
   return s_buf;
}



/*
 * describes the output variables of a query,
 * allocates buffers for result rows,
 * and binds this buffers to the statement.
 */
int dbd_describe(SV *sth, imp_sth_t *imp_sth, int more)
{
    SQLRETURN rc;                           /* ODBC fn return value */
    SQLSMALLINT column_n;                   /* column we are describing */
    imp_fbh_t *fbh;
    SQLLEN colbuf_bytes_reqd = 0;
    SQLSMALLINT num_fields;                     /* number resultant columns */
    SQLCHAR *cur_col_name;
    struct imp_dbh_st *imp_dbh = NULL;
    imp_dbh = (struct imp_dbh_st *)(DBIc_PARENT_COM(imp_sth));

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        TRACE1(imp_sth, "    dbd_describe done_desc=%d\n", imp_sth->done_desc);

    if (imp_sth->done_desc) return 1;   /* success, already done it */

    imp_sth->done_bind = 0;

    /* Find out how many columns there are in the result-set */
    if (!SQL_SUCCEEDED(rc = SQLNumResultCols(imp_sth->hstmt, &num_fields))) {
        dbd_error(sth, rc, "dbd_describe/SQLNumResultCols");
        return 0;
    } else if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
        TRACE2(imp_sth,
               "    dbd_describe SQLNumResultCols=%d (columns=%d)\n",
               rc, num_fields);
    }

    /*
     * If "more" is not set (set in dbd_st_fetch) and SQLMoreResults is
     * supported then we skip over non-result-set generating statements.
     */
    imp_sth->done_desc = 1;	/* assume ok from here on */
    if (!more) {
        while (num_fields == 0 &&
               imp_dbh->odbc_sqlmoreresults_supported == 1) {
            rc = SQLMoreResults(imp_sth->hstmt);
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8))
                TRACE1(imp_sth,
                       "    Numfields = 0, SQLMoreResults = %d\n", rc);

            if (rc == SQL_NO_DATA) {            /* mo more results */
                imp_sth->moreResults = 0;
                break;
            } else if (rc == SQL_SUCCESS_WITH_INFO) {
                /* warn about an info returns */
                dbd_error(sth, rc, "dbd_describe/SQLMoreResults");
            } else if (!SQL_SUCCEEDED(rc)) {
                dbd_error(sth, rc, "dbd_describe/SQLMoreResults");
                return 0;
            }
            /* reset describe flags, so that we re-describe */
            imp_sth->done_desc = 0;

            /* force future executes to rebind automatically */
            imp_sth->odbc_force_rebind = 1;

            if (!SQL_SUCCEEDED(
                    rc = SQLNumResultCols(imp_sth->hstmt, &num_fields))) {
                dbd_error(sth, rc, "dbd_describe/SQLNumResultCols");
                return 0;
            } else if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8)) {
                TRACE1(imp_dbh,
                       "    num fields after MoreResults = %d\n", num_fields);
            }
        } /* end of SQLMoreResults */
    } /* end of more */

    DBIc_NUM_FIELDS(imp_sth) = num_fields;

    if (0 == num_fields) {
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
            TRACE0(imp_dbh, "    dbd_describe skipped (no resultant cols)\n");
        imp_sth->done_desc = 1;
        return 1;
    }
    DBIc_ACTIVE_on(imp_sth); /*HERE*/
    /* allocate field buffers */
    Newz(42, imp_sth->fbh, num_fields, imp_fbh_t);
    /* the +255 below instead is due to an old comment in this code before
       this change claiming foxpro wrote off end of memory
       (and so 255 bytes were added - kept here without evidence) */
    Newz(42, imp_sth->ColNames,
         (num_fields + 1) * imp_dbh->max_column_name_len + 255, UCHAR);

    cur_col_name = imp_sth->ColNames;
    /* Pass 1: Get space needed for field names, display buffer and dbuf */
    for (fbh=imp_sth->fbh, column_n=0;
         column_n < num_fields;
         column_n++, fbh++) {
        fbh->imp_sth = imp_sth;
#ifdef WITH_UNICODE
        rc = SQLDescribeColW(imp_sth->hstmt,
                            (SQLSMALLINT)(column_n + 1),
                             (SQLWCHAR *) cur_col_name,
                            (SQLSMALLINT)imp_dbh->max_column_name_len,
                            &fbh->ColNameLen,
                            &fbh->ColSqlType,
                            &fbh->ColDef,
                            &fbh->ColScale,
                            &fbh->ColNullable);
#else /* WITH_UNICODE */
        rc = SQLDescribeCol(imp_sth->hstmt,
                            (SQLSMALLINT)(column_n + 1),
                            cur_col_name,
                            (SQLSMALLINT)imp_dbh->max_column_name_len,
                            &fbh->ColNameLen,
                            &fbh->ColSqlType,
                            /* column size or precision depending on type */
                            &fbh->ColDef,
                            &fbh->ColScale,     /* decimal digits */
                            &fbh->ColNullable);
#endif /* WITH_UNICODE */
        if (!SQL_SUCCEEDED(rc)) {	/* should never fail */
            dbd_error(sth, rc, "describe/SQLDescribeCol");
            break;
        }
        fbh->ColName = cur_col_name;
#ifdef WITH_UNICODE
        cur_col_name += fbh->ColNameLen * sizeof(SQLWCHAR);
#else
        cur_col_name += fbh->ColNameLen + 1;
        cur_col_name[fbh->ColNameLen] = '\0';   /* should not be necessary */
#endif
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8))
            /* TO_DO the following print for column name won't work well
               for UCS2 strings when SQLDescribeW above called */
            PerlIO_printf(DBIc_LOGPIO(imp_dbh),
                          "    DescribeCol column = %d, name = %s, "
                          "namelen = %d, type = %s(%d), "
                          "precision/column size = %ld, scale = %d, "
                          "nullable = %d\n",
                          column_n + 1,
                          fbh->ColName,
                          fbh->ColNameLen,
                          S_SqlTypeToString(fbh->ColSqlType),
                          fbh->ColSqlType,
                          fbh->ColDef, fbh->ColScale, fbh->ColNullable);
#ifdef SQL_DESC_DISPLAY_SIZE
        rc = SQLColAttribute(imp_sth->hstmt,
                             (SQLSMALLINT)(column_n + 1),
                             SQL_DESC_DISPLAY_SIZE,
                             NULL, 0, NULL ,
                             &fbh->ColDisplaySize);
        if (!SQL_SUCCEEDED(rc)) {
            /* Some ODBC drivers don't support SQL_COLUMN_DISPLAY_SIZE on
               some result-sets. e.g., The "Infor Integration ODBC driver"
               cannot handle SQL_COLUMN_DISPLAY_SIZE and SQL_COLUMN_LENGTH
               for SQLTables and SQLColumns calls. We used to fail here but
               there is a prescident not to as this code is already in an
               ifdef for drivers that do not define SQL_COLUMN_DISPLAY_SIZE.
               Since just about everyone will be using an ODBC driver manager
               now it is unlikely these attributes will not be defined so we
               default if the call fails now */
             if( DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8) ) {
	       TRACE0(imp_sth,
		      "     describe/SQLColAttributes/SQL_COLUMN_DISPLAY_SIZE "
		      "not supported, will be equal to SQL_COLUMN_LENGTH\n");
             }
             /* ColDisplaySize will be made equal to ColLength */
             fbh->ColDisplaySize = 0;
             rc = SQL_SUCCESS;
        } else if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8)) {
            TRACE1(imp_sth, "     SQL_COLUMN_DISPLAY_SIZE = %ld\n",
                   (long)fbh->ColDisplaySize);
        }

        /* TBD: should we only add a terminator if it's a char??? */
        fbh->ColDisplaySize += 1; /* add terminator */
#else  /* !SQL_COLUMN_DISPLAY_SIZE */
        fbh->ColDisplaySize = imp_sth->odbc_column_display_size;
#endif  /* SQL_COLUMN_DISPLAY_SIZE */

        /* Workaround bug in Firebird driver that reports timestamps are
           display size 24 when in fact it can return the longer
           e.g., 1998-05-15 00:01:00.100000000 */
        if ((imp_dbh->driver_type == DT_FIREBIRD) &&
            (fbh->ColSqlType == SQL_TYPE_TIMESTAMP)) {
            fbh->ColDisplaySize = 30;
        }

        /* For MS Access SQL_COLUMN_DISPLAY_SIZE is 22 for doubles
           and it differs from SQLDescribeCol which says 53 - use the latter
           or some long numbers get squished. Doesn't seem to fix accdb
           driver. See rt 69864. */
        if ((imp_dbh->driver_type == DT_MS_ACCESS_JET) &&
            (fbh->ColSqlType == SQL_DOUBLE)) {
            fbh->ColDisplaySize = fbh->ColDef + 1;
        }

#ifdef SQL_DESC_LENGTH
        rc = SQLColAttribute(imp_sth->hstmt,(SQLSMALLINT)(column_n + 1),
                             SQL_DESC_LENGTH,
                             NULL, 0, NULL ,&fbh->ColLength);
        if (!SQL_SUCCEEDED(rc)) {
            /* See comment above under SQL_COLUMN_DISPLAY_SIZE */
            fbh->ColLength = imp_sth->odbc_column_display_size;
            if( DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8) ) {
                TRACE1(imp_sth,
                       "     describe/SQLColAttributes/SQL_COLUMN_LENGTH not "
                       "supported, fallback on %ld\n", (long)fbh->ColLength);
            }
            rc = SQL_SUCCESS;
        } else if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8)) {
            TRACE1(imp_sth, "     SQL_COLUMN_LENGTH = %ld\n",
                   (long)fbh->ColLength);
        }
# if defined(WITH_UNICODE)
        fbh->ColLength += 1; /* add extra byte for double nul terminator */

        switch(fbh->ColSqlType) {
          case SQL_CHAR:
            fbh->ColSqlType = SQL_WCHAR;
            break;
          case SQL_VARCHAR:
            fbh->ColSqlType = SQL_WVARCHAR;
            break;
          case SQL_LONGVARCHAR:
            fbh->ColSqlType = SQL_WLONGVARCHAR;
            break;
        }
# endif
#else  /* !SQL_COLUMN_LENGTH */
        fbh->ColLength = imp_sth->odbc_column_display_size;
#endif  /* SQL_COLUMN_LENGTH */

        /* may want to ensure Display Size at least as large as column
         * length -- workaround for some drivers which report a shorter
         * display length
         * */
        fbh->ColDisplaySize =
            fbh->ColDisplaySize > fbh->ColLength ?
            fbh->ColDisplaySize : fbh->ColLength;

        /*
         * change fetched size, decimal digits etc for some types,
         * The tests for ColDef = 0 are for when the driver does not give
         * us a length for the column e.g., "max" column types in SQL Server
         * like varbinary(max).
         */
        fbh->ftype = SQL_C_CHAR;
        switch(fbh->ColSqlType)
        {
          case SQL_VARBINARY:
          case SQL_BINARY:
            fbh->ftype = SQL_C_BINARY;
            if (fbh->ColDef == 0) {             /* cope with varbinary(max) */
                fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth);
            }
	    break;
#if defined(WITH_UNICODE)
          case SQL_WCHAR:
          case SQL_WVARCHAR:
            fbh->ftype = SQL_C_WCHAR;
            /* MS SQL returns bytes, Oracle returns characters ... */

            if (fbh->ColDef == 0) {             /* cope with nvarchar(max) */
                fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth);
                fbh->ColLength = DBIc_LongReadLen(imp_sth);
            } else if (fbh->ColDef > 2147483590) {
                /*
                 * The new MS Access driver ACEODBC.DLL cannot cope with the
                 * 40UnicodeRoundTrip test which contains a
                 * select ?, LEN(?)
                 * returning a massive number for the column display size of
                 * the first column. This leads to a memory allocation error
                 * unless we trap it as a large column.
                 */
                fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth);
                fbh->ColLength = DBIc_LongReadLen(imp_sth);
            }

            fbh->ColDisplaySize *= sizeof(SQLWCHAR);
            fbh->ColLength *= sizeof(SQLWCHAR);
            break;
#else  /* WITH_UNICODE */
# if defined(SQL_WCHAR)
          case SQL_WCHAR:
            if (fbh->ColDef == 0) {
                fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth);
            }
            break;
# endif
# if defined(SQL_WVARCHAR)
          case SQL_WVARCHAR:
            if (fbh->ColDef == 0) {
                fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth);
            }
            break;
# endif
#endif /* WITH_UNICODE */
          case SQL_LONGVARBINARY:
            fbh->ftype = SQL_C_BINARY;
            fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth);
            break;
#ifdef SQL_WLONGVARCHAR
          case SQL_WLONGVARCHAR:	/* added for SQLServer 7 ntext type */
# if defined(WITH_UNICODE)
            fbh->ftype = SQL_C_WCHAR;
            /* MS SQL returns bytes, Oracle returns characters ... */
            fbh->ColLength *= sizeof(SQLWCHAR);
            fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth) + 1;
# else  /* !WITH_UNICODE */
            fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth) + 1;
# endif	/* WITH_UNICODE */
            break;
#endif  /* SQL_WLONGVARCHAR */
          case SQL_VARCHAR:
            if (fbh->ColDef == 0) {
                fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth) + 1;
            }
            break;
          case SQL_LONGVARCHAR:
            fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth) + 1;
            break;
          case MS_SQLS_XML_TYPE: {
              /* XML columns are inherently Unicode so bind them as such and in this case
                 double the size of LongReadLen as we count LongReadLen as characters
                 not bytes */
#ifdef WITH_UNICODE
              fbh->ftype = SQL_C_WCHAR;
              fbh->ColDisplaySize =
                  DBIc_LongReadLen(imp_sth) * sizeof(SQLWCHAR) + sizeof(SQLWCHAR);
#else
              fbh->ColDisplaySize = DBIc_LongReadLen(imp_sth) + 1;
#endif
              break;
          }
#ifdef TIMESTAMP_STRUCT	/* XXX! */
          case SQL_TIMESTAMP:
          case SQL_TYPE_TIMESTAMP:
            fbh->ftype = SQL_C_TIMESTAMP;
            fbh->ColDisplaySize = sizeof(TIMESTAMP_STRUCT);
	    break;
#endif
          case SQL_INTEGER:
            fbh->ftype = SQL_C_LONG;
            fbh->ColDisplaySize = sizeof(SQLINTEGER);
            break;
        }

        colbuf_bytes_reqd += fbh->ColDisplaySize;
        /*
         *  We later align columns in the buffer on integer boundaries so we
         *  we need to take account of this here. The last % is to avoid adding
         *  sizeof(int) if we are already aligned.
         */
        colbuf_bytes_reqd +=
            (sizeof(int) - (colbuf_bytes_reqd % sizeof(int))) % sizeof(int);

        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
            PerlIO_printf(DBIc_LOGPIO(imp_dbh),
                          "     now using col %d: type = %s (%d), len = %ld, "
                          "display size = %ld, prec = %ld, scale = %lu\n",
                          column_n + 1,
                          S_SqlTypeToString(fbh->ColSqlType),
                          fbh->ColSqlType,
                          (long)fbh->ColLength, (long)fbh->ColDisplaySize,
                          (long)fbh->ColDef, (unsigned long)fbh->ColScale);
    }
    if (!SQL_SUCCEEDED(rc)) {
        /* dbd_error called above */
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
            TRACE0(imp_sth, "Freeing fbh\n");
        Safefree(imp_sth->fbh);
        imp_sth->fbh = NULL;
        return 0;
    }

    imp_sth->RowBufferSizeReqd = colbuf_bytes_reqd;

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        TRACE1(imp_sth, "    -dbd_describe done_bind=%d\n", imp_sth->done_bind);

    return 1;
}



static SQLRETURN bind_columns(
    SV *h,
    imp_sth_t *imp_sth)
{
    SQLSMALLINT num_fields;
    UCHAR *rbuf_ptr;
    imp_fbh_t *fbh;
    SQLRETURN rc = SQL_SUCCESS;                           /* ODBC fn return value */
    SQLSMALLINT i;

    num_fields = DBIc_NUM_FIELDS(imp_sth);

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        TRACE2(imp_sth,
               "    bind_columns fbh=%p fields=%d\n", imp_sth->fbh, num_fields);

    /* allocate Row memory */
    Newz(42, imp_sth->RowBuffer,
         imp_sth->RowBufferSizeReqd + num_fields, UCHAR);

    rbuf_ptr = imp_sth->RowBuffer;

    for(i=0, fbh = imp_sth->fbh;
        i < num_fields && SQL_SUCCEEDED(rc); i++, fbh++)
    {
        if (!(fbh->bind_flags & ODBC_TREAT_AS_LOB)) {

            fbh->data = rbuf_ptr;
            rbuf_ptr += fbh->ColDisplaySize;
            /* alignment -- always pad so the next column is aligned on a word
               boundary */
            rbuf_ptr += (sizeof(int) - ((rbuf_ptr - imp_sth->RowBuffer) %
                                        sizeof(int))) % sizeof(int);

            /* Bind output column variables */
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
                PerlIO_printf(DBIc_LOGPIO(imp_sth),
                              "    Bind %d: type = %s(%d), buf=%p, buflen=%ld\n",
                              i+1, S_SqlTypeToString(fbh->ftype), fbh->ftype,
                              fbh->data, fbh->ColDisplaySize);
            rc = SQLBindCol(imp_sth->hstmt,
                            (SQLSMALLINT)(i+1),
                            fbh->ftype,
                            fbh->data,
                            fbh->ColDisplaySize, &fbh->datalen);
            if (!SQL_SUCCEEDED(rc)) {
                dbd_error(h, rc, "describe/SQLBindCol");
                break;
            }
            /* Save the fact this column is now bound and hence the type
               can not be changed */
            fbh->bound = 1;
        } else if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
            TRACE1(imp_sth, "      TreatAsLOB bind_flags = %lx\n",
                   fbh->bind_flags);
        }
    }
    imp_sth->done_bind = 1;

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
	  	 TRACE1(imp_sth, "    bind_columns=%d\n", rc);
    return rc;
}



/*======================================================================*/
/*                                                                      */
/* dbd_st_execute                                                       */
/* ==============                                                       */
/*                                                                      */
/* returns:                                                             */
/*   -2 - error                                                         */
/*   >=0 - ok, row count                                                */
/*   -1 - unknown count                                                 */
/*                                                                      */
/*======================================================================*/
int dbd_st_execute(
    SV *sth, imp_sth_t *imp_sth)
{
    IV ret;

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        TRACE1(imp_sth, "    +dbd_st_execute(%p)\n", sth);

    ret = dbd_st_execute_iv(sth, imp_sth);
    if (ret > INT_MAX) {
        if (DBIc_WARN(imp_sth)) {
            warn("SQLRowCount overflowed in execute - see RT 81911 - you need to upgrade your DBI to at least 1.633_92");
        }
        ret = INT_MAX;
    }

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        TRACE2(imp_sth, "    -dbd_st_execute(%p)=%"IVdf"\n", sth, ret);

    return (int)ret;
}

IV dbd_st_execute_iv(
    SV *sth, imp_sth_t *imp_sth)
{
    RETCODE rc;
    D_imp_dbh_from_sth;
    int outparams = 0;
    SQLLEN ret;

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        TRACE1(imp_dbh, "    +dbd_st_execute_iv(%p)\n", sth);

    if (SQL_NULL_HDBC == imp_dbh->hdbc) {
        DBIh_SET_ERR_CHAR(sth, (imp_xxh_t*)imp_sth, Nullch, 1,
                          "Database handle has been disconnected",
                          Nullch, Nullch);
        return -2;
    }

    /*
     * if the handle is active, we need to finish it here.
     * Note that dbd_st_finish already checks to see if it's active.
     */
    dbd_st_finish(sth, imp_sth);;

    /*
     * bind_param_inout support
     */
    outparams = (imp_sth->out_params_av) ? AvFILL(imp_sth->out_params_av)+1 : 0;
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
        TRACE1(imp_dbh, "    outparams = %d\n", outparams);
    }

    if (imp_dbh->odbc_defer_binding) {
        rc = SQLFreeStmt(imp_sth->hstmt, SQL_RESET_PARAMS);
        /* check bind input parameters */
        if (imp_sth->all_params_hv) {
            HV *hv = imp_sth->all_params_hv;
            SV *sv;
            char *key;
            I32 retlen;
            hv_iterinit(hv);
            while( (sv = hv_iternextsv(hv, &key, &retlen)) != NULL ) {
                if (sv != &PL_sv_undef) {
                    phs_t *phs = (phs_t*)(void*)SvPVX(sv);
                    if (!rebind_param(sth, imp_sth, imp_dbh, phs)) return -2;
                    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8)) {
                        if (SvOK(phs->sv) && (phs->value_type == SQL_C_CHAR)) {
                            char sbuf[256];
                            unsigned int i = 0;

                            while((phs->sv_buf[i] != 0) && (i < (sizeof(sbuf) - 6))) {
                                sbuf[i] = phs->sv_buf[i];
                                i++;
                            }
                            strcpy(&sbuf[i], "...");

                            TRACE2(imp_dbh,
                                   "    rebind check char Param %d (%s)\n",
                                   phs->idx, sbuf);
                        }
                    }
                }
            }
        }
    }

    if (outparams) {    /* check validity of bind_param_inout SV's      */
        int i = outparams;
        while(--i >= 0) {
            phs_t *phs = (phs_t*)(void*)SvPVX(AvARRAY(imp_sth->out_params_av)[i]);
            /* Make sure we have the value in string format. Typically a number */
            /* will be converted back into a string using the same bound buffer */
            /* so the sv_buf test below will not trip.                   */

            /* mutation check */
            if (SvTYPE(phs->sv) != phs->sv_type /* has the type changed? */
                || (SvOK(phs->sv) && !SvPOK(phs->sv)) /* is there still a string? */
                || (SvPVX(phs->sv) != phs->sv_buf) /* has the string buffer moved? */
                || (SvOK(phs->sv) != phs->svok)
                ) {
                if (!rebind_param(sth, imp_sth, imp_dbh, phs))
                    croak("Can't rebind placeholder %s", phs->name);
            } else {
                /* no mutation found */
            }
        }
    }


    if (imp_sth->odbc_exec_direct) {
        /* statement ready for SQLExecDirect */
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5)) {
            TRACE0(imp_dbh,
                   "    odbc_exec_direct=1, using SQLExecDirect\n");
        }
        rc = SQLExecDirect(imp_sth->hstmt, imp_sth->statement, SQL_NTS);
    } else {
        rc = SQLExecute(imp_sth->hstmt);
    }

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8))
        TRACE2(imp_dbh, "    SQLExecute/SQLExecDirect(%p)=%d\n",
               imp_sth->hstmt, rc);
    /*
     * If asynchronous execution has been enabled, SQLExecute will
     * return SQL_STILL_EXECUTING until it has finished.
     * Grab whatever messages occur during execution...
     */
    while (rc == SQL_STILL_EXECUTING){
        dbd_error(sth, rc, "st_execute/SQLExecute");

        /*
         * Wait a second so we don't loop too fast and bring the machine
         * to its knees
         */
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
            TRACE1(imp_dbh, "    SQLExecute(%p) still executing", imp_sth->hstmt);
        sleep(1);
        rc = SQLExecute(imp_sth->hstmt);
    }
    /* patches to handle blobs better, via Jochen Wiedmann */
    while (rc == SQL_NEED_DATA) {
        phs_t* phs;
        STRLEN len;
        UCHAR* ptr;

        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
            TRACE1(imp_dbh, "    NEED DATA %p\n", imp_sth->hstmt);

        while ((rc = SQLParamData(imp_sth->hstmt, (PTR*) &phs)) ==
               SQL_STILL_EXECUTING) {
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
                TRACE1(imp_dbh, "    SQLParamData(%p) still executing",
                       imp_sth->hstmt);
            /*
             * wait a while to avoid looping too fast waiting for SQLParamData
             * to complete.
             */
            sleep(1);
        }
        if (rc !=  SQL_NEED_DATA) {
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
                TRACE1(imp_dbh, "    SQLParamData=%d\n", rc);
            break;
        }

        /* phs->sv is already upgraded to a PV in rebind_param.
         * It is not NULL, because we otherwise won't be called here
         * (value_len = 0).
         */
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
            TRACE2(imp_dbh, "    SQLParamData needs phs %p, sending %"UVuf" bytes\n",
                   phs, (UV)len);
        ptr = SvPV(phs->sv, len);
        rc = SQLPutData(imp_sth->hstmt, ptr, len);
        if (!SQL_SUCCEEDED(rc)) {
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
                TRACE1(imp_dbh, "    SQLPutData=%d\n", rc);
            break;
        }
        rc = SQL_NEED_DATA;  /*  So the loop continues ...  */
    }

    /*
     * Call dbd_error if we get SQL_SUCCESS_WITH_INFO as there may
     * be some status msgs for us.
     */
    if (SQL_SUCCESS_WITH_INFO == rc) {
        dbd_error(sth, rc, "st_execute/SQLExecute");
    }

    if (!SQL_SUCCEEDED(rc) && rc != SQL_NO_DATA) {
        dbd_error(sth, rc, "st_execute/SQLExecute");
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
            TRACE1(imp_dbh, "    -dbd_st_execute_iv(%p)=-2\n", sth);
        return -2;
    }

    /*
     * If SQLExecute executes a searched update, insert, or delete statement
     * that does not affect any rows at the data source, the call to
     * SQLExecute returns SQL_NO_DATA.
     */
    if (rc != SQL_NO_DATA) {

        /* SWORD num_fields; */
        RETCODE rc2;
        rc2 = SQLRowCount(imp_sth->hstmt, &imp_sth->RowCount);
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 7))
            TRACE2(imp_dbh, "    SQLRowCount=%d (rows=%"IVdf")\n",
                   rc2,
                   (IV)(SQL_SUCCEEDED(rc2) ? imp_sth->RowCount : -1));
        if (!SQL_SUCCEEDED(rc2)) {
            dbd_error(sth, rc2, "st_execute/SQLRowCount");	/* XXX ? */
            imp_sth->RowCount = -1;
            DBIc_ROW_COUNT(imp_sth) = -1;
        } else {
            DBIc_ROW_COUNT(imp_sth) = imp_sth->RowCount;
        }

        /* sanity check for strange circumstances and multiple types of
         * result sets.  Crazy that it can happen, but it can with
         * multiple result sets and stored procedures which return
         * result sets.
         * This seems to slow things down a bit and is rarely needed.
         *
         * This can happen in Sql Server in strange cases where stored
         * procs have multiple result sets.  Sometimes, if there is an
         * select then an insert, etc.  Maybe this should be a special
         * attribute to force a re-describe after every execute? */
        if (imp_sth->odbc_force_rebind) {
            /* force calling dbd_describe after each execute */
            odbc_clear_result_set(sth, imp_sth);
        }
    } else {
        /* SQL_NO_DATA returned, must have no rows :) */
        /* seem to need to reset the done_desc, but not sure if this is
         * what we want yet */
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 7))
            TRACE0(imp_dbh,
                   "    SQL_NO_DATA...resetting done_desc!\n");
        imp_sth->done_desc = 0;
        imp_sth->RowCount = 0;
        DBIc_ROW_COUNT(imp_sth) = 0;
        /* Strictly speaking a driver should only return SQL_NO_DATA
           when a searched insert/update/delete affects no rows and
           so it is pointless continuing below and calling SQLNumResultCols.

           However, if you run a procedure such as this:
           CREATE PROCEDURE PERL_DBD_PROC1 (\@i INT) AS
           DECLARE \@result INT;
           BEGIN
             SET \@result = \@i;
             IF (\@i = 99)
             BEGIN
	           UPDATE PERL_DBD_TABLE1 SET i=\@i;
	           SET \@result = \@i + 1;
             END;
             SELECT \@result;
           END

           to MS SQL Server, it will return SQL_NO_DATA but then
           SQLNumResultCols will be successful and return 1 column
           for the result set. As a result, we need to continue below.

           Some versions of freeTDS will return SQLNumResultCols = 1 after a
           "delete from table" but then give a function sequence error
           when SQLDescribeCol called. It would have been handy to return 0
           here to workaround that bug but the above does not allow us to. */
    }

    /*
     *  MS SQL Server is very picky wrt to completing a procedure i.e.,
     *  it says the output bound parameters are not available until the
     *  procedure is complete and the procedure is not complete until you
     *  have called SQLMoreResults and it has returned SQL_NO_DATA. So, if you
     *  call a procedure multiple times in the same statement (e.g., by just
     *  calling execute) DBD::ODBC will call dbd_describe to describe the first
     *  execute, discover there is no result-set and call SQLMoreResults - ok,
     *  but after that, the dbd_describe is done and SQLMoreResults will not
     *  get called. The following is a kludge to get around this until
     *  a) DBD::ODBC can be changed to stop skipping over non-result-set
     *  generating statements and b) the SQLMoreResults calls move out of
     *  dbd_describe.
     */
    {
        SQLSMALLINT flds = 0;
        SQLRETURN sts;

        if (!SQL_SUCCEEDED(sts = SQLNumResultCols(imp_sth->hstmt, &flds))) {
            dbd_error(sth, sts, "dbd_describe/SQLNumResultCols");
            return -2;
        }
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
            TRACE1(imp_dbh, "    SQLNumResultCols=0 (flds=%d)\n", flds);
        if (flds == 0) {                         /* not a result-set */
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
                TRACE2(imp_dbh,
                       "    Not a result-set nflds=(%d,%d), resetting done_desc\n",
                       flds, DBIc_NUM_FIELDS(imp_sth));
            imp_sth->done_desc = 0;
        }
    }

    if (!imp_sth->done_desc) {
        /* This needs to be done after SQLExecute for some drivers!	*/
        /* Especially for order by and join queries.			*/
        /* See Microsoft Knowledge Base article (#Q124899)		*/
        /* describe and allocate storage for results (if any needed)	*/
        if (!dbd_describe(sth, imp_sth, 0)) {
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3)) {
                TRACE0(imp_sth,
                       "    !!dbd_describe failed, dbd_st_execute_iv #1...!\n");
            }
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
                TRACE1(imp_dbh, "    -dbd_st_execute_iv(%p)=-2\n", sth);
            return -2; /* dbd_describe already called dbd_error()	*/
        }
    }

    if (DBIc_NUM_FIELDS(imp_sth) > 0) {
        DBIc_ACTIVE_on(imp_sth);	/* only set for select (?)	*/
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
            TRACE1(imp_sth, "    have %d fields\n",
                   DBIc_NUM_FIELDS(imp_sth));
        }

    } else {
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
            TRACE0(imp_dbh, "    got no rows: resetting ACTIVE, moreResults\n");
        }
        imp_sth->moreResults = 0;
        /* flag that we've done the describe to avoid a problem
         * where calling describe after execute returned no rows
         * caused SQLServer to provide a description of a query
         * that didn't quite apply. */

        /* imp_sth->done_desc = 1;  */
        DBIc_ACTIVE_off(imp_sth);
    }

    if (outparams) {	/* check validity of bound output SV's	*/
        odbc_handle_outparams(imp_sth, DBIc_TRACE_LEVEL(imp_sth));
    }

    /*
     * JLU: Jon Smirl had:
     *      return (imp_sth->RowCount == -1 ? -1 : abs(imp_sth->RowCount));
     * why?  Why do you need the abs() of the rowcount?  Special reason?
     * The e-mail that accompanied the change indicated that Sybase would return
     * a negative value for an estimate.  Wouldn't you WANT that to stay
     * negative?
     *
     * dgood: JLU had:
     *      return imp_sth->RowCount;
     * Because you return -2 on errors so if you don't abs() it, a perfectly
     * valid return value will get flagged as an error...
     */
    ret = (imp_sth->RowCount == -1 ? -1 : imp_sth->RowCount); /* TO_DO NONESENSE IT IS NOOP */

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        TRACE2(imp_dbh, "    -dbd_st_execute_iv(%p)=%"IVdf"\n", sth, ret);


    return ret;
}



/*----------------------------------------
 * running $sth->fetch()
 *----------------------------------------
 */
AV *dbd_st_fetch(SV *sth, imp_sth_t *imp_sth)
{
    D_imp_dbh_from_sth;
    int i;
    AV *av;
    RETCODE rc;
    int num_fields;
#ifdef TIMESTAMP_STRUCT /* iODBC doesn't define this */
    char cvbuf[512];
#endif
    int ChopBlanks;

    /* Check that execute() was executed sucessfully. This also implies	*/
    /* that dbd_describe() executed sucessfuly so the memory buffers	*/
    /* are allocated and bound.						*/
    if ( !DBIc_ACTIVE(imp_sth) ) {
      /*dbd_error(sth, DBDODBC_INTERNAL_ERROR, "no select statement currently executing");*/
	/* The following issues a warning (instead of the error above)
	   when a selectall_* did not actually return a result-set e.g.,
	   if someone passed a create table to selectall_*. There is some
	   debate as to what should happen here.
	   See http://www.nntp.perl.org/group/perl.dbi.dev/2011/06/msg6606.html
	   and rt 68720  and rt_68720.t */
        DBIh_SET_ERR_CHAR(sth, (imp_xxh_t*)imp_sth,
		   "0", 0, "no select statement currently executing", "", "fetch");

        return Nullav;
    }

    if (!imp_sth->done_bind) {
        rc = bind_columns(sth, imp_sth);
        if (!SQL_SUCCEEDED(rc)) {
            Safefree(imp_sth->fbh);
            imp_sth->fbh = NULL;
            dbd_st_finish(sth, imp_sth);
            return Nullav;
        }
    }

    rc = SQLFetch(imp_sth->hstmt);
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        TRACE1(imp_dbh, "    SQLFetch=%d\n", rc);

    if (!SQL_SUCCEEDED(rc)) {
        if (SQL_NO_DATA_FOUND == rc) {

            if (imp_dbh->odbc_sqlmoreresults_supported == 1) {
                rc = SQLMoreResults(imp_sth->hstmt);
                /* Check for multiple results */
                if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 6))
                    TRACE1(imp_dbh, "    Getting more results: %d\n", rc);

                if (rc == SQL_SUCCESS_WITH_INFO) {
                    dbd_error(sth, rc, "st_fetch/SQLMoreResults");
                    /* imp_sth->moreResults = 0; */
                }
                if (SQL_SUCCEEDED(rc)){
                    /* More results detected.  Clear out the old result */
                    /* stuff and re-describe the fields.                */
                    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3)) {
                        TRACE0(imp_dbh, "    MORE Results!\n");
                    }
                    odbc_clear_result_set(sth, imp_sth);

                    /* force future executes to rebind automatically */
                    imp_sth->odbc_force_rebind = 1;

                    /* tell the odbc driver that we need to unbind the
                     * bound columns.  Fix bug for 0.35 (2/8/02) */
                    rc = SQLFreeStmt(imp_sth->hstmt, SQL_UNBIND);
                    if (!SQL_SUCCEEDED(rc)) {
                        AllODBCErrors(imp_dbh->henv, imp_dbh->hdbc, 0,
                                      DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3),
                                      DBIc_LOGPIO(imp_dbh));
                    }

                    if (!dbd_describe(sth, imp_sth, 1)) {
                        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
                            TRACE0(imp_dbh,
                                   "    !!MORE Results dbd_describe failed...!\n");
                        return Nullav; /* dbd_describe already called dbd_error() */
                    }


                    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
                        TRACE0(imp_dbh,
                               "    MORE Results dbd_describe success...!\n");
                    }
                    /* set moreResults so we'll know we can keep fetching */
                    imp_sth->moreResults = 1;
                    imp_sth->done_desc = 0;
                    return Nullav;
                }
                else if (rc == SQL_NO_DATA_FOUND || rc == SQL_NO_DATA ||
                         rc == SQL_SUCCESS_WITH_INFO){
                    /* No more results */
                    /* need to check output params here... */
                    int outparams = (imp_sth->out_params_av) ?
                        AvFILL(imp_sth->out_params_av)+1 : 0;

                    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 6)) {
                        TRACE1(imp_sth, "    No more results -- outparams = %d\n",
                               outparams);
                    }
                    imp_sth->moreResults = 0;
                    imp_sth->done_desc = 1;
                    if (outparams) {
                        odbc_handle_outparams(imp_sth, DBIc_TRACE_LEVEL(imp_sth));
                    }
                    /* XXX need to 'finish' here */
                    dbd_st_finish(sth, imp_sth);
                    return Nullav;
                }
                else {
                    dbd_error(sth, rc, "st_fetch/SQLMoreResults");
                }
            }
            else {
                /*
                 * SQLMoreResults not supported, just finish.
                 * per bug found by Jarkko Hyöty [hyoty@medialab.sonera.fi]
                 * No more results
                 */
                imp_sth->moreResults = 0;
                /* XXX need to 'finish' here */
                /*dbd_st_finish(sth, imp_sth);*/
                return Nullav;
            }
        } else {
            dbd_error(sth, rc, "st_fetch/SQLFetch");
            /* XXX need to 'finish' here */
            /* MJE commented out the following in 1.34_3 as it prevents
               calling odbc_get
               dbd_st_finish(sth, imp_sth);*/
            return Nullav;
        }
    }

    if (imp_sth->RowCount == -1)
        imp_sth->RowCount = 0;

    imp_sth->RowCount++;

    av = DBIc_DBISTATE(imp_sth)->get_fbav(imp_sth);
    num_fields = AvFILL(av)+1;

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        TRACE1(imp_dbh, "    fetch num_fields=%d\n", num_fields);

    ChopBlanks = DBIc_has(imp_sth, DBIcf_ChopBlanks);

    for(i=0; i < num_fields; ++i) {
        imp_fbh_t *fbh = &imp_sth->fbh[i];
        SV *sv = AvARRAY(av)[i]; /* Note: we (re)use the SV in the AV	*/

        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
            PerlIO_printf(
                DBIc_LOGPIO(imp_dbh),
                "    fetch col#%d %s datalen=%ld displ=%lu\n",
                i+1, fbh->ColName, (long)fbh->datalen,
                (unsigned long)fbh->ColDisplaySize);

        if (fbh->datalen == SQL_NULL_DATA) {	/* NULL value		*/
            SvOK_off(sv);
            continue;
        }

        if (fbh->datalen > fbh->ColDisplaySize || fbh->datalen < 0) {
            /* truncated LONG ??? DBIcf_LongTruncOk() */
            /* DBIcf_LongTruncOk this should only apply to LONG type fields */
            /* truncation of other fields should always be an error since it's */
            /* a sign of an internal error */
            if (!DBIc_has(imp_sth, DBIcf_LongTruncOk)
                /*  && rc == SQL_SUCCESS_WITH_INFO */) {

                /*
                 * Since we've detected the problem locally via the datalen,
                 * we don't need to worry about the value of rc.
                 *
                 * This used to make sure rc was set to SQL_SUCCESS_WITH_INFO
                 * but since it's an error and not SUCCESS, call dbd_error()
                 * with SQL_ERROR explicitly instead.
                 */
#ifdef COULD_DO_THIS
                DBIh_SET_ERR_CHAR(
                    sth, (imp_xxh_t*)imp_sth, Nullch, 1,
                    "st_fetch/SQLFetch (long truncated DBI attribute LongTruncOk "
                    "not set and/or LongReadLen too small)", Nullch, Nullch);
#endif
                dbd_error(
                    sth, DBDODBC_INTERNAL_ERROR,
                    "st_fetch/SQLFetch (long truncated DBI attribute LongTruncOk "
                    "not set and/or LongReadLen too small)");
                return Nullav;
            }
            /* LongTruncOk true, just ensure perl has the right length
             * for the truncated data.
             */
            sv_setpvn(sv, (char*)fbh->data, fbh->ColDisplaySize);
        }  else {
            switch(fbh->ftype) {
#ifdef TIMESTAMP_STRUCT /* iODBC doesn't define this */
              case SQL_C_TIMESTAMP:
              case SQL_C_TYPE_TIMESTAMP:
              {
                  TIMESTAMP_STRUCT *ts;
                  ts = (TIMESTAMP_STRUCT *)fbh->data;

                  if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
                      TRACE0(imp_dbh, "    adjusting timestamp\n");
                  my_snprintf(cvbuf, sizeof(cvbuf),
                              "%04d-%02d-%02d %02d:%02d:%02d",
                              ts->year, ts->month, ts->day,
                              ts->hour, ts->minute, ts->second, ts->fraction);
                  sv_setpv(sv, cvbuf);
                  break;
              }
#endif
#if defined(WITH_UNICODE)
              case SQL_C_WCHAR:
                if (ChopBlanks && fbh->ColSqlType == SQL_WCHAR &&
                    fbh->datalen > 0)
                {
                    SQLWCHAR *p = (SQLWCHAR*)fbh->data;
                    SQLWCHAR blank = 0x20;
                    SQLLEN orig_len = fbh->datalen;

                    while(fbh->datalen && p[fbh->datalen/sizeof(SQLWCHAR)-1] == blank) {
                        --fbh->datalen;
                    }
                    if (DBIc_TRACE(imp_sth, UNICODE_TRACING, 0, 0)) /* odbcunicode */
                        TRACE2(imp_sth, "    Unicode ChopBlanks orig len=%ld, new len=%ld\n",
                               orig_len, fbh->datalen);
                }
                sv_setwvn(sv,(SQLWCHAR*)fbh->data,fbh->datalen/sizeof(SQLWCHAR));
                if (DBIc_TRACE(imp_sth, UNICODE_TRACING, 0, 0)) { /* odbcunicode */
                    /* unsigned char dlog[256]; */
                    /* unsigned char *src; */
                    /* char *dst = dlog; */
                    /* unsigned int n; */
                    /* STRLEN len; */

                    /* src = SvPV(sv, len); */
                    /* dst += sprintf(dst, "0x"); */
                    /* for (n = 0; (n < 126) && (n < len); n++, src++) { */
                    /*     dst += sprintf(dst, "%2.2x", *src); */
                    /* } */
                    /*TRACE1(imp_sth, "    SQL_C_WCHAR data = %s\n", dlog);*/
                    TRACE1(imp_sth, "    SQL_C_WCHAR data = %.100s\n", neatsvpv(sv, 100));
                }
                break;
#endif /* WITH_UNICODE */
              case SQL_INTEGER:
                 sv_setiv(sv, *((SQLINTEGER *)fbh->data));
                 break;
             default:
                if (ChopBlanks && fbh->datalen > 0 &&
                    ((fbh->ColSqlType == SQL_CHAR) ||
                     (fbh->ColSqlType == SQL_WCHAR))) {
                    char *p = (char*)fbh->data;

                    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
                        TRACE0(imp_sth, "    chopping blanks\n");

                    while(fbh->datalen && p[fbh->datalen - 1]==' ')
                        --fbh->datalen;
                }
                sv_setpvn(sv, (char*)fbh->data, fbh->datalen);
                if (imp_sth->odbc_utf8_on && fbh->ftype != SQL_C_BINARY ) {
                    if (DBIc_TRACE(imp_sth, UNICODE_TRACING, 0, 0)) /* odbcunicode */
                        TRACE0(imp_sth, "    odbc_utf8 - decoding UTF-8");
#ifdef sv_utf8_decode
                    sv_utf8_decode(sv);
#else
                    SvUTF8_on(sv);
#endif
                }
                if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
                    TRACE2(imp_sth, "    %s(%ld)\n", neatsvpv(sv, fbh->datalen+5),
                           fbh->datalen);
            }
        }
#if DBIXS_REVISION > 13590
        /* If a bind type was specified we use DBI's sql_type_cast
           to cast it - currently only number types are handled */
        if (
            /*(fbh->req_type == SQL_INTEGER) || not needed as we've already done a sv_setiv*/
            (fbh->req_type == SQL_NUMERIC) ||
            (fbh->req_type == SQL_DECIMAL)) {
            int sts;
            char errstr[256];

            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
                TRACE3(imp_sth, "    sql_type_case %s %"IVdf" %lx\n",  neatsvpv(sv, fbh->datalen+5), fbh->req_type, fbh->bind_flags);


            sts = DBIc_DBISTATE(imp_sth)->sql_type_cast_svpv(
                aTHX_ sv, fbh->req_type, (U32)fbh->bind_flags, NULL);

            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
                TRACE1(imp_sth, "    sql_type_cast=%d\n",  sts);

            if (sts == 0) {
                sprintf(errstr,
                        "over/under flow converting column %d to type %"IVdf"",
                        i+1, fbh->req_type);
                DBIh_SET_ERR_CHAR(sth, (imp_xxh_t*)imp_sth, Nullch, 1,
                                  errstr, Nullch, Nullch);
                return Nullav;
            }
            else if (sts == -2) {
                sprintf(errstr,
                        "unsupported bind type %"IVdf" for column %d in sql_type_cast_svpv",
                        fbh->req_type, i+1);
                DBIh_SET_ERR_CHAR(sth, (imp_xxh_t*)imp_sth, Nullch, 1,
                                  errstr, Nullch, Nullch);
                return Nullav;
            }
        }
#endif /* DBIXS_REVISION > 13590 */

    } /* end of loop through bound columns */
    return av;
}



/* /\* SHOULD BE ABLE TO DELETE BOTH OF THESE NOW AND dbd_st_rows macro in dbdimp.h *\/ */
/* int dbd_st_rows(SV *sth, imp_sth_t *imp_sth) */
/* { */
/*    return (int)imp_sth->RowCount; */
/* } */

/* IV dbd_st_rows(SV *sth, imp_sth_t *imp_sth) */
/* { */
/*    return imp_sth->RowCount; */
/* } */




int dbd_st_finish(SV *sth, imp_sth_t *imp_sth)
{
    D_imp_dbh_from_sth;
    RETCODE rc;

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        TRACE1(imp_sth, "    dbd_st_finish(%p)\n", sth);

    /* Cancel further fetches from this cursor.                 */
    /* We don't close the cursor till DESTROY (dbd_st_destroy). */
    /* The application may re execute(...) it.                  */

    /* XXX semantics of finish (eg oracle vs odbc) need lots more thought */
    /* re-read latest DBI specs and ODBC manuals */
    if (DBIc_ACTIVE(imp_sth) && imp_dbh->hdbc != SQL_NULL_HDBC) {

        rc = SQLFreeStmt(imp_sth->hstmt, SQL_CLOSE);/* TBD: 3.0 update */
        if (!SQL_SUCCEEDED(rc)) {
            dbd_error(sth, rc, "finish/SQLFreeStmt(SQL_CLOSE)");
            return 0;
        }
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 6)) {
            TRACE0(imp_dbh, "    dbd_st_finish closed query:\n");
        }
    }
    DBIc_ACTIVE_off(imp_sth);
   return 1;
}



void dbd_st_destroy(SV *sth, imp_sth_t *imp_sth)
{
    D_imp_dbh_from_sth;
    RETCODE rc;

    /* Free contents of imp_sth	*/

    /* PerlIO_printf(DBIc_LOGPIO(imp_dbh), "  dbd_st_destroy\n"); */
    Safefree(imp_sth->fbh);
    Safefree(imp_sth->RowBuffer);
    Safefree(imp_sth->ColNames);
    Safefree(imp_sth->statement);

    if (imp_sth->out_params_av)
        sv_free((SV*)imp_sth->out_params_av);

    if (imp_sth->param_status_array) {
      Safefree(imp_sth->param_status_array);
      imp_sth->param_status_array = NULL;
    }
    if (imp_sth->all_params_hv) {
        HV *hv = imp_sth->all_params_hv;
        SV *sv;
        char *key;
        I32 retlen;
        hv_iterinit(hv);
        while( (sv = hv_iternextsv(hv, &key, &retlen)) != NULL ) {
            if (sv != &PL_sv_undef) {
                phs_t *phs_tpl = (phs_t*)(void*)SvPVX(sv);
                sv_free(phs_tpl->sv);
                if (phs_tpl->strlen_or_ind_array) {
                    Safefree(phs_tpl->strlen_or_ind_array);
                    phs_tpl->strlen_or_ind_array = NULL;
                }
                if (phs_tpl->param_array_buf) {
                    Safefree(phs_tpl->param_array_buf);
                    phs_tpl->param_array_buf = NULL;
                }
            }
        }
        sv_free((SV*)imp_sth->all_params_hv);
    }
    if (imp_sth->param_status_array) {
        Safefree(imp_sth->param_status_array);
        imp_sth->param_status_array = NULL;
    }

    /* SQLxxx functions dump core when no connection exists. This happens
     * when the db was disconnected before perl ending.  Hence,
     * checking for the dirty flag.
     */
    if (imp_dbh->hdbc != SQL_NULL_HDBC && !PL_dirty) {

        rc = SQLFreeHandle(SQL_HANDLE_STMT, imp_sth->hstmt);

        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
            TRACE1(imp_dbh, "    SQLFreeHandle(stmt)=%d\n", rc);

        if (!SQL_SUCCEEDED(rc)) {
            dbd_error(sth, rc, "st_destroy/SQLFreeHandle(stmt)");
            /* return 0; */
        }
    }

    DBIc_IMPSET_off(imp_sth);		/* let DBI know we've done it	*/
}



/************************************************************************/
/*                                                                      */
/*  get_param_type                                                      */
/*  ==============                                                      */
/*                                                                      */
/*  Sets the following fields for a parameter in the phs_st:            */
/*                                                                      */
/*  sql_type - the SQL type to use when binding this parameter          */
/*  describe_param_called - set to 1 if we called SQLDescribeParam      */
/*  describe_param_status - set to result of SQLDescribeParam if        */
/*                          SQLDescribeParam called                     */
/*  described_sql_type - the sql type returned by SQLDescribeParam      */
/*  param_size - the parameter size returned by SQLDescribeParam        */
/*                                                                      */
/*  The sql_type field is set to one of the following:                  */
/*    value passed in bind method call if specified                     */
/*    if SQLDescribeParam not supported:                                */
/*      value of odbc_default_bind_type attribute if set else           */
/*        SQL_VARCHAR                                                   */
/*    if SQLDescribeParam supported:                                    */
/*      if SQLDescribeParam succeeds:                                   */
/*        parameter type returned by SQLDescribeParam                   */
/*      else if SQLDescribeParam fails:                                 */
/*        value of odbc_default_bind_type attribute if set else         */
/*          SQL_VARCHAR                                                 */
/*                                                                      */
/*  NOTE: Just because an ODBC driver says it supports SQLDescribeParam */
/*  does not mean you can call it successfully e.g., MS SQL Server      */
/*  implements SQLDescribeParam by examining your SQL and rewriting it  */
/*  to be a select statement so it can find the column types etc. This  */
/*  fails horribly when the statement does not contain a table          */
/*  e.g., "select ?, LEN(?)" and so do most other SQL Server drivers.   */
/*                                                                      */
/************************************************************************/
static void get_param_type(
    SV *sth,
    imp_sth_t *imp_sth,
    imp_dbh_t *imp_dbh,
    phs_t *phs)
{
   SWORD fNullable;
   SWORD ibScale;
   RETCODE rc;

   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
       TRACE2(imp_sth, "    +get_param_type(%p,%s)\n", sth, phs->name);

   if (imp_sth->odbc_force_bind_type != 0) {
       phs->sql_type = imp_sth->odbc_force_bind_type;
       if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
           TRACE1(imp_dbh, "      forced param type to %d\n", phs->sql_type);
   } else if (imp_dbh->odbc_sqldescribeparam_supported != 1) {
       /* As SQLDescribeParam is not supported by the ODBC driver we need to
          default a SQL type to bind the parameter as. The default is either
          the value set with odbc_default_bind_type or a fallback of
          SQL_VARCHAR/SQL_WVARCHAR depending on your data and whether we are unicode build. */
       phs->sql_type = default_parameter_type(
           "SQLDescribeParam not supported", imp_sth, phs);
   } else if (!imp_sth->odbc_describe_parameters) {
       phs->sql_type = default_parameter_type(
           "SQLDescribeParam disabled", imp_sth, phs);
   } else if (!phs->describe_param_called) {
       /* If we haven't had a go at calling SQLDescribeParam before for this
          parameter, have a go now. If it fails we'll default the sql type
          as above when driver does not have SQLDescribeParam */

       rc = SQLDescribeParam(imp_sth->hstmt,
                             phs->idx, &phs->described_sql_type,
                             &phs->param_size, &ibScale,
                             &fNullable);
       phs->describe_param_called = 1;
       phs->describe_param_status = rc;
       if (!SQL_SUCCEEDED(rc)) {
           if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
               TRACE1(imp_dbh, "      Parameter %d\n", phs->idx);

           phs->sql_type = default_parameter_type(
               "SQLDescribeParam failed", imp_sth, phs);
           /* show any odbc errors in log */
           AllODBCErrors(imp_sth->henv, imp_sth->hdbc, imp_sth->hstmt,
                         DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3),
                         DBIc_LOGPIO(imp_sth));
       } else if (phs->described_sql_type == 0) { /* unknown SQL type */
           /* pretend it failed */
           phs->describe_param_status = SQL_ERROR;
           phs->sql_type = default_parameter_type(
               "SQLDescribeParam returned unknown SQL type", imp_sth, phs);
       } else {
           if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
               PerlIO_printf(DBIc_LOGPIO(imp_dbh),
                             "      SQLDescribeParam %s: SqlType=%s(%d) "
                             "param_size=%ld Scale=%d Nullable=%d\n",
                             phs->name,
                             S_SqlTypeToString(phs->described_sql_type),
                             phs->described_sql_type,
                             (unsigned long)phs->param_size, ibScale,
                             fNullable);

           /*
            * for non-integral numeric types, let the driver/database handle
            * the conversion for us
            */
           switch(phs->described_sql_type) {
             case SQL_NUMERIC:
             case SQL_DECIMAL:
             case SQL_FLOAT:
             case SQL_REAL:
             case SQL_DOUBLE:
               if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
                   TRACE3(imp_dbh,
                          "      Param %s is numeric SQL type %s "
                          "(param size:%lu) changed to SQL_VARCHAR\n",
                          phs->name,
                          S_SqlTypeToString(phs->described_sql_type),
                          (unsigned long)phs->param_size);
               phs->sql_type = SQL_VARCHAR;
               break;
  	     default: {
             check_for_unicode_param(imp_sth, phs);
	       break;
	     }
           }
       }
   } else if (phs->describe_param_called) {
       if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
           TRACE1(imp_dbh,
                  "      SQLDescribeParam already run and returned rc=%d\n",
                  phs->describe_param_status);
       check_for_unicode_param(imp_sth, phs);
   }

   if (phs->requested_type != 0) {
       phs->sql_type = phs->requested_type;
       if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5))
           TRACE1(imp_dbh, "      Overriding sql type with requested type %d\n",
                  phs->requested_type);
   }

#if defined(WITH_UNICODE)
   /* for Unicode string types, change value_type to SQL_C_WCHAR*/
   switch (phs->sql_type) {
     case SQL_WCHAR:
     case SQL_WVARCHAR:
     case SQL_WLONGVARCHAR:
     case MS_SQLS_XML_TYPE:                  /* SQL Server XML Type */
       phs->value_type = SQL_C_WCHAR;
       if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8)) {
           TRACE0(imp_dbh,
                  "      get_param_type: modified value type to SQL_C_WCHAR\n");
       }
       break;
   }
#endif /* WITH_UNICODE */
   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8))
       TRACE0(imp_dbh, "    -get_param_type\n");
}



/*======================================================================*/
/*                                                                      */
/* rebind_param                                                         */
/* ============                                                         */
/*                                                                      */
/*======================================================================*/
static int rebind_param(
    SV *sth,
    imp_sth_t *imp_sth,
    imp_dbh_t *imp_dbh,
    phs_t *phs)
{
    SQLRETURN rc;
    SQLULEN default_column_size;
    STRLEN value_len = 0;
    /* args of SQLBindParameter() call */
    SQLSMALLINT param_io_type; /* SQL_PARAM_INPUT_OUTPUT || SQL_PARAM_INPUT */
    SQLSMALLINT value_type;    /* C data type of parameter */
    UCHAR *value_ptr;          /* ptr to actual parameter data */
    SQLULEN column_size;       /* size of column/expression of the parameter */
    SQLSMALLINT d_digits;      /* decimal digits of parameter */
    SQLLEN buffer_length;      /* length in bytes of parameter buffer */
    SQLLEN strlen_or_ind;      /* parameter length or indicator */

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
        PerlIO_printf(
            DBIc_LOGPIO(imp_dbh),
            "    +rebind_param %s %.100s (size SvCUR=%"UVuf"/SvLEN=%"UVuf"/max=%"IVdf") "
            "svtype:%u, value type:%d, sql type:%d\n",
            phs->name, neatsvpv(phs->sv, 0),
            SvOK(phs->sv) ? (UV)SvCUR(phs->sv) : -1,
            SvOK(phs->sv) ? (UV)SvLEN(phs->sv) : -1 ,phs->maxlen,
            SvTYPE(phs->sv), phs->value_type, phs->sql_type);
    }

    if (phs->is_inout) {
        /*
         * At the moment we always do sv_setsv() and rebind.
         * Later we may optimise this so that more often we can
         * just copy the value & length over and not rebind.
         */
        if (SvREADONLY(phs->sv))
            Perl_croak(aTHX_ "%s", PL_no_modify);
        /* phs->sv _is_ the real live variable, it may 'mutate' later   */
        /* pre-upgrade high to reduce risk of SvPVX realloc/move        */
        (void)SvUPGRADE(phs->sv, SVt_PVNV);
        /* ensure room for result, 28 is magic number (see sv_2pv)      */
#if defined(WITH_UNICODE)
        SvGROW(phs->sv,
               (phs->maxlen + sizeof(SQLWCHAR) < 28) ?
               28 : phs->maxlen + sizeof(SQLWCHAR));
#else
        SvGROW(phs->sv, (phs->maxlen < 28) ? 28 : phs->maxlen+1);
#endif /* WITH_UNICODE */
        phs->svok = SvOK(phs->sv);
    } else {
        /* phs->sv is copy of real variable, upgrade to at least string */
        (void)SvUPGRADE(phs->sv, SVt_PV);
    }

    /*
     * At this point phs->sv must be at least a PV with a valid buffer,
     * even if it's undef (null)
     */
    if (SvOK(phs->sv)) {
        phs->sv_buf = SvPV(phs->sv, value_len);
    } else {
        /* it's undef but if it was inout param it would point to a
         * valid buffer, at least  */
        phs->sv_buf = SvPVX(phs->sv);
        value_len = 0;
    }

    get_param_type(sth, imp_sth, imp_dbh, phs);

#if defined(WITH_UNICODE)
    if (phs->value_type == SQL_C_WCHAR) {
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8)) {
            TRACE1(imp_dbh,
                   "      Need to modify phs->sv in place: old length = %lu\n",
                   value_len);
        }
        /* Convert the sv in place to UTF-16 encoded characters
           NOTE: the SV_toWCHAR may modify SvPV(phs->sv */
        if (SvOK(phs->sv)) {
            SV_toWCHAR(phs->sv);
            /* get new buffer and length */
            phs->sv_buf = SvPV(phs->sv, value_len);
        } else {                                 /* it is undef */
            /* need a valid buffer at least */
            phs->sv_buf = SvPVX(phs->sv);
            value_len = 0;
        }

        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 8)) {
            TRACE1(imp_dbh,
                   "      Need to modify phs->sv in place: new length = %lu\n",
                   value_len);
        }
    }

    /* value_len has current value length now */
    phs->sv_type = SvTYPE(phs->sv);        /* part of mutation check */
    phs->maxlen  = SvLEN(phs->sv) - sizeof(SQLWCHAR); /* avail buffer space */

#else  /* !WITH_UNICODE */
    /* value_len has current value length now */
    phs->sv_type = SvTYPE(phs->sv);        /* part of mutation check */

    phs->maxlen  = SvLEN(phs->sv) - 1;         /* avail buffer space */
#endif /* WITH_UNICODE */

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
        PerlIO_printf(
            DBIc_LOGPIO(imp_dbh),
            "      bind %s %.100s value_len=%"UVuf" maxlen=%ld null=%d)\n",
            phs->name, neatsvpv(phs->sv, value_len),
            (UV)value_len,(long)phs->maxlen, SvOK(phs->sv) ? 0 : 1);
    }

    /*
     * JLU: was SQL_PARAM_OUTPUT only, but that caused a problem with
     * Oracle's drivers and in/out parameters.  Can't be output only
     * with Oracle.
     */
    param_io_type = phs->is_inout ? SQL_PARAM_INPUT_OUTPUT : SQL_PARAM_INPUT;
    value_type = phs->value_type;
    d_digits = value_len;
    column_size = phs->is_inout ? phs->maxlen : value_len;

    /* per patch from Paul G. Weiss, who was experiencing re-preparing
     * of queries when the size of the bound string's were increasing
     * for example select * from tabtest where name = ?
     * then executing with 'paul' and then 'thomas' would cause
     * SQLServer to prepare the query twice, but if we ran 'thomas'
     * then 'paul', it would not re-prepare the query.  The key seems
     * to be allocating enough space for the largest parameter.
     * TBD: the default for this should be a DBD::ODBC specific option
     * or attribute.
     */
    if (phs->sql_type == SQL_VARCHAR && !phs->is_inout) {
        d_digits = 0;
        /* default to at least 80 if this is the first time through */
        if (phs->biggestparam == 0) {
            phs->biggestparam = (value_len > 80) ? value_len : 80;
        } else {
            /* bump up max, if needed */
            if (value_len > phs->biggestparam) {
                phs->biggestparam = value_len;
            }
        }
    }

    if ((phs->describe_param_called == 1) &&
        (SQL_SUCCEEDED(phs->describe_param_status)) &&
        (phs->requested_type == 0)) {            /* type not overriden */
        default_column_size = phs->param_size;
    } else if (phs->is_inout) {
        default_column_size = phs->maxlen;
    } else {
        if (phs->sql_type == SQL_VARCHAR) {
            default_column_size = phs->biggestparam;
        } else {
            default_column_size = value_len;
        }
    }

    /* Default buffer_length to specified output length or actual input length */
    buffer_length = phs->is_inout ? phs->maxlen : value_len;

    /* When we fill a LONGVARBINARY, the CTYPE must be set to SQL_C_BINARY */
    if (value_type == SQL_C_CHAR) {    /* could be changed by bind_plh */
        d_digits = 0;                  /* not relevent to char types */
        switch(phs->sql_type) {
          case SQL_LONGVARBINARY:
          case SQL_BINARY:
          case SQL_VARBINARY:
	    value_type = SQL_C_BINARY;
            column_size = default_column_size;
	    break;
#ifdef SQL_WLONGVARCHAR
          case SQL_WLONGVARCHAR:	/* added for SQLServer 7 ntext type */
#endif
          case SQL_CHAR:
          case SQL_VARCHAR:
          case SQL_LONGVARCHAR:
            column_size = default_column_size;
	    break;
          case SQL_DATE:
          case SQL_TYPE_DATE:
          case SQL_TIME:
          case SQL_TYPE_TIME:
	    break;
          case SQL_TIMESTAMP:
          case SQL_TYPE_TIMESTAMP:
            d_digits = 0;		/* tbd: millisecondS?) */
            if (SvOK(phs->sv)) {
                /* Work out decimal digits value from milliseconds */
                char *cp;
                if (phs->sv_buf && *phs->sv_buf) {
                    cp = strchr(phs->sv_buf, '.');
                    if (cp) {
                        ++cp;
                        while (*cp != '\0' && isdigit(*cp)) {
                            cp++;
                            d_digits++;
                        }
                    }
                }
            }
            /*
             * 23 is YYYY-MM-DD HH:MM:SS.sss
             * We have to be really careful here to maintain the column size
             * whether we are passing NULL/undef or not as the ODBC driver
             * only has the values we pass to SQLBindParameter to go on and
             * cannot know until execute time whether we are passing a NULL or
             * not (i.e., although we pass the strlen_or_ind value - last arg to
             * SQLBindParameter with a length or SQL_NULL_DATA, this is a ptr
             * arg and the driver cannot look at it until execute time).
             * We may know we are going to pass a NULL but if we reduce the
             * the column size to 0 (or as this function used to do - 1) the
             * driver might decide it is not a full datetime and decide to
             * bind as a smalldatetime etc. In fact there is a test for
             * MS SQL Server in 20SqlServer which binds a datetime and passes
             * a NULL, a full datetime and lastly a NULL and if we don't maintain
             * 23 for the first NULL MS SQL Server decides it is a smalldatetime
             * and we lose the SS.sss in any full datetime passed later.
             */
	    column_size = 23;
	    break;
          default:
	    break;
        }
    } else if ( value_type == SQL_C_WCHAR) {
        d_digits = 0;
    }

    if (!SvOK(phs->sv)) {
        strlen_or_ind = SQL_NULL_DATA;
        /* if is_inout, shouldn't we null terminate the buffer and send
         * it, instead?? */
        if (!phs->is_inout) {
            /*
             * We have to be really careful here to maintain the column size
             * whether we are passing NULL/undef or not as the ODBC driver
             * only has the values we pass to SQLBindParameter to go on and
             * cannot know until execute time whether we are passing a NULL or
             * not (i.e., although we pass the strlen_or_ind value - last arg to
             * SQLBindParameter with a length or SQL_NULL_DATA, this is a ptr
             * arg and the driver cannot look at it until execute time).
             * We may know we are going to pass a NULL but if we reduce the
             * the column size to 0 (or as this function used to do - 1) the
             * driver might decide it is a different type (e.g., smalldatetime
             * instead of datetime).
             * In fact there is a test for MS SQL Server in 20SqlServer which
             * binds a datetime and passes a NULL, a full datetime and lastly a
             * NULL and if we don't maintain the column_size for the first NULL
             * MS SQL Server decides it is a smalldatetime and we lose the
             * SS.sss in any full datetime passed later despite setting a correct
             * column_size and decimal digits.
             */
            /* column_size = 1; Used to be this but see comment above */
            /*
             * However, at this stage we could have column_size of 0 and
             * that is no good either or we'll get invalid precision
             */
            if (column_size == 0) column_size = 1;
        }
        if (phs->is_inout) {
            if (!phs->sv_buf) {
                croak("panic: DBD::ODBC binding undef with bad buffer!!!!");
            }
            /* just in case, we *know* we called SvGROW above */
            phs->sv_buf[0] = '\0';
            /* patch for binding undef inout params on sql server */
            d_digits = 1;
            value_ptr = phs->sv_buf;
        } else {
            value_ptr = NULL;
        }
    }
    else {
        value_ptr = phs->sv_buf;
        strlen_or_ind = value_len;
        /* not undef, may be a blank string or something */
        if (!phs->is_inout && strlen_or_ind == 0) {
            column_size = 1;
        }
    }
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
        PerlIO_printf(DBIc_LOGPIO(imp_dbh),
                      "      bind %s value_type:%d %s cs=%lu dd=%d bl=%ld\n",
                      phs->name, value_type, S_SqlTypeToString(phs->sql_type),
                      (unsigned long)column_size, d_digits, buffer_length);
    }

    if (value_len < imp_sth->odbc_putdata_start) {
        /* already set and should be left alone JLU */
        /* d_digits = value_len; */
    } else {
        SQLLEN vl = value_len;

        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
            TRACE1(imp_dbh, "      using data_at_exec for size %lu\n",
                   (unsigned long)value_len);

        d_digits = 0;                         /* not relevant to lobs */
        strlen_or_ind = SQL_LEN_DATA_AT_EXEC(vl);
        value_ptr = (UCHAR*) phs;
    }

#if THE_FOLLOWING_CODE_IS_FLAWED_AND_BROKEN
    /*
     * value_ptr is not null terminated - it is a byte array so PVallocW
     * won't work as it works on null terminated strings
     */
#if defined(WITH_UNICODE)
    if (value_type==SQL_C_WCHAR) {
        char * c1;
        c1 = PVallocW((SQLWCHAR *)value_ptr);
        TRACE1(imp_dbh, "      Param value = L'%s'\n", c1);
        PVfreeW(c1);
    }
#endif /* WITH_UNICODE */
#endif


    /*
     *  The following code is a workaround for a problem in SQL Server
     *  when inserting more than 400K into varbinary(max) or varchar(max)
     *  columns. The older SQL Server driver (not the native client driver):
     *
     *  o reports the size of xxx(max) columns as 2147483647 bytes in size
     *    when in reality they can be a lot bigger than that.
     *  o if you bind more than 400K you get the following errors:
     *    (HY000, 0, [Microsoft][ODBC SQL Server Driver]
     *      Warning: Partial insert/update. The insert/update of a text or
     *      image column(s) did not succeed.)
     *    (42000, 7125, [Microsoft][ODBC SQL Server Driver][SQL Server]
     *      The text, ntext, or image pointer value conflicts with the column
     *      name specified.)
     *
     *  There appear to be 2 workarounds but I was not prepared to do the first.
     *  The first is simply to set the indicator to SQL_LEN_DATA_AT_EXEC(409600)
     *  if the parameter was larger than 409600 - miraculously it works but
     *  shouldn't according to MSDN.
     *  The second workaround (used here) is to set the indicator to
     *  SQL_LEN_DATA_AT_EXEC(0) and the buffer_length to 0.
     *
     */
    if ((imp_dbh->driver_type == DT_SQL_SERVER) &&
        ((phs->sql_type == SQL_LONGVARCHAR) ||
         (phs->sql_type == SQL_LONGVARBINARY) ||
         (phs->sql_type == SQL_WLONGVARCHAR)) &&
        /*(column_size == 2147483647) && (strlen_or_ind < 0) &&*/
        ((-strlen_or_ind + SQL_LEN_DATA_AT_EXEC_OFFSET) >= 409600)) {
        strlen_or_ind = SQL_LEN_DATA_AT_EXEC(0);
        buffer_length = 0;
    }
#if defined(WITH_UNICODE)
    /*
     * rt43384 - MS Access does not seem to like us binding parameters as
     * wide characters and then SQLBindParameter column_size to byte length.
     * e.g., if you have a text(255) column and try and insert 190 ascii chrs
     * then the unicode enabled version of DBD::ODBC will convert those 190
     * ascii chrs to wide chrs and hence double the size to 380. If you pass
     * 380 to Access for column_size it just returns an invalid precision
     * value. This changes to column_size to chrs instead of bytes but
     * only if column_size is not reduced to 0 - which also produces
     * an access error e.g., in the empty string '' case.
     */
    else if (((imp_dbh->driver_type == DT_MS_ACCESS_JET) ||
              (imp_dbh->driver_type == DT_MS_ACCESS_ACE)) &&
             (value_type == SQL_C_WCHAR) && (column_size > 1)) {
        column_size = column_size / 2;
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
            TRACE0(imp_dbh, "    MSAccess - setting chrs not bytes\n");
    }
#endif

    /*
     * workaround bug in SQL Server ODBC driver where it can describe some
     * parameters (especially in SQL using sub selects) the wrong way.
     * If this is a varchar then the column_size must be at least as big
     * as the buffer size but if SQL Server associated the wrong column with
     * our parameter it could get a totally different size. Without this
     * a varchar(10) column can be desribed as a varchar(n) where n is less
     * than 10 and this leads to data truncation errors - see rt 39841.
     */
    if (((imp_dbh->driver_type == DT_SQL_SERVER) ||
         (imp_dbh->driver_type == DT_SQL_SERVER_NATIVE_CLIENT)) &&
        (phs->sql_type == SQL_VARCHAR) &&
        (column_size < buffer_length)) {
        column_size = buffer_length;
    }
    /*
     * Yet another workaround for SQL Server native client.
     * If you have a varbinary(max), varchar(max) or nvarchar(max) you have to
     * pass 0 for the column_size or you get HY104 "Invalid precision value".
     * See rt_38977.t which causes this.
     * The versions of native client I've seen this with are:
     * 2007.100.1600.22 sqlncli10.dll driver version = ?
     * 2005.90.1399.00 SQLNCLI.DLL driver version = 09.00.1399
     *
     * Update, for nvarchar(max) it does not seem to simply be a driver issue
     * as with the Easysoft SQL Server ODBC Driver going to Microsoft SQL Server
     * 09.00.1399 we got the following error for all sizes between 4001 and 8000
     * (inclusive).
     * [SQL Server]The size (4001) given to the parameter '@P1' exceeds the
     *   maximum allowed (4000)
     *
     * Update, see RT100186 - same applies to VARBINARY(MAX)
     *
     * So to sum up for the native client when the parameter size is 0 or
     * when the database is sql server and wchar and sql type not overwritten
     * we need to use column size 0. We cannot do this if the requested_type
     * was specified as if someone specifies a bind type we haven't called
     * SQLDescribeParam and it looks like param_size = 0 even when it is
     * not a xxx(max). e.g., the 40UnicodeRoundTrip tests will fail with
     * MS SQL Server because they override the type.
     */
    if ((phs->param_size == 0) &&
        (SQL_SUCCEEDED(phs->describe_param_status)) &&
	(imp_sth->odbc_describe_parameters)) { /* SQLDescribeParam not disabled */
        /* no point in believing param_size = 0 if SQLDescribeParam failed */
        /* See rt 55736 */
        if ((imp_dbh->driver_type == DT_SQL_SERVER_NATIVE_CLIENT) ||
            ((strcmp(imp_dbh->odbc_dbms_name, "Microsoft SQL Server") == 0) &&
             ((phs->sql_type == SQL_WVARCHAR) || (phs->sql_type == SQL_VARBINARY)) &&
             (phs->requested_type == 0))) {
            column_size = 0;
        }
    }
    /* for rt_38977 we get:
     * sloi = -500100 ps=0 sqlt=12 (SQL_VARCHAR)
     * sloi = -500100 ps=0 sqlt=-3 (SQL_VARBINARY)
     * sloi = 4001 ps=0 sqlt=-9 (SQL_WVARCHAR) <--- this one fails without above
     */

    /*printf("sloi = %d ps=%d sqlt=%d\n", strlen_or_ind, phs->param_size, phs->sql_type);*/


    /*
     * Avoid calling SQLBindParameter again if nothing has changed.
     * Why, because a) there is no point and b) MS SQL Server will
     * re-prepare the statement.
     */
    /* phs' copy of strlen_or_ind is permanently allocated and the other
       strlen_or_ind is an automatic variable and won't survive this func
       but needs to. */
    phs->strlen_or_ind = strlen_or_ind;
    if ((param_io_type == SQL_PARAM_INPUT_OUTPUT) ||
        (!phs->bp_value_ptr) ||                 /* not bound before */
        ((param_io_type == SQL_PARAM_INPUT) &&    /* input parameter */
         ((value_ptr != phs->bp_value_ptr) ||
          (value_type != phs->value_type) ||
          (column_size != phs->bp_column_size) ||
          (d_digits != phs->bp_d_digits) ||
          (buffer_length != phs->bp_buffer_length)))) {
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5)) {
            PerlIO_printf(
                DBIc_LOGPIO(imp_dbh),
                "    SQLBindParameter: idx=%d: io_type=%d, name=%s, "
                "value_type=%d (%s), SQLType=%d (%s), column_size=%lu, "
                "d_digits=%d, value_ptr=%p, buffer_length=%ld, ind=%ld, "
                "param_size=%lu\n",
                phs->idx, param_io_type, phs->name,
                value_type, S_SqlCTypeToString(value_type),
                phs->sql_type, S_SqlTypeToString(phs->sql_type),
                (unsigned long)column_size, d_digits, value_ptr,
                (long)buffer_length, (long)strlen_or_ind,
                (unsigned long)phs->param_size);

            /* avoid tracing data_at_exec as value_ptr will point to phs */
            if ((value_type == SQL_C_CHAR) && (strlen_or_ind > 0)) {
                TRACE1(imp_sth, "      Param value = %s\n", value_ptr);
            }
        }
#ifdef FRED
       printf("SQLBindParameter idx=%d pt=%d vt=%d, st=%d, cs=%lu dd=%d vp=%p bl=%ld slorind=%ld %s\n",
              phs->idx, param_io_type, value_type, phs->sql_type,
              (unsigned long)column_size, d_digits, value_ptr,
              buffer_length, (long)phs->strlen_or_ind, value_ptr);
#endif
        rc = SQLBindParameter(imp_sth->hstmt,
                              phs->idx, param_io_type, value_type,
                              phs->sql_type, column_size, d_digits,
                              value_ptr, buffer_length,
                              &phs->strlen_or_ind);

        if (!SQL_SUCCEEDED(rc)) {
            dbd_error(sth, rc, "rebind_param/SQLBindParameter");
            phs->bp_value_ptr = NULL;
            return 0;
        }
        phs->bp_value_ptr = value_ptr;
        phs->value_type = value_type;
        phs->bp_column_size = column_size;
        phs->bp_d_digits = d_digits;
        phs->bp_buffer_length = buffer_length;
    } else if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5)) {
        TRACE1(imp_sth, "    Not rebinding param %d - no change\n", phs->idx);
    }

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        TRACE0(imp_dbh, "    -rebind_param\n");

   return 1;
}



int dbd_st_bind_col(
    SV *sth,
    imp_sth_t *imp_sth,
    SV *col,
    SV *ref,
    IV type,
    SV *attribs)
{
    dTHX;
    int field;

    if (!SvIOK(col)) {
        croak ("Invalid column number") ;
    }

    field = SvIV(col);

    if ((field < 1) || (field > DBIc_NUM_FIELDS(imp_sth))) {
        croak("cannot bind to non-existent field %d", field);
    }

    /* Don't allow anyone to change the bound type after the column is bound
       or horrible things could happen e.g., say you just call SQLBindCol
       without a type it will probably default to SQL_C_CHAR but if you
       later called bind_col specifying SQL_INTEGER the code here would
       interpret the buffer as a 4 byte integer but in reality it would be
       written as a char*.

       We issue a warning but don't change the actual type.
    */

    if (imp_sth->fbh[field-1].bound && type && imp_sth->fbh[field-1].bound != type) {
        DBIh_SET_ERR_CHAR(
            sth, (imp_xxh_t*)imp_sth,
            "0", 0, "you cannot change the bind column type after the column is bound",
            "", "fetch");
        return 1;
    }

    /* The first problem we have is that SQL_xxx values DBI defines are not
       the same as SQL_C_xxx values we pass the SQLBindCol and in some cases
       there is no C equivalent e.g., SQL_DECIMAL - there is no C type for these.

       The second problem we have is that values passed to SQLBindCol cause the
       ODBC driver to return different C types OR structures e.g., SQL_NUMERIC
       returns a structure.

       We're not binding columns as C structures as they are too hard to convert
       into Perl scalars - we'll just use SQL_C_CHAR/SQL_C_WCHAR for these.

       There is an exception for timestamps as the code later will bind as a
       timestamp if it spots the column is a timestamp and pull the structure
       apart.

       We do however store the requested type if it SQL_DOUBLE/SQL_NUMERIC so
       we can use it with sql_type_cast_svpv i.e., if you know the column is a double or
       numeric we still retrieve it as a char string but then if DiscardString or StrictlyTyped
       if specified we'lll call sql_type_cast_svpv.
    */
    if (type == SQL_DOUBLE ||
        type == SQL_NUMERIC) {
        imp_sth->fbh[field-1].req_type = type;
    }

    if (attribs) {                              /* attributes are sticky */
        imp_sth->fbh[field-1].bind_flags = 0; /* default to none */
    }

    /* DBIXS 13590 added StrictlyTyped and DiscardString attributes */
    if (attribs) {
        SV **svp;

        DBD_ATTRIBS_CHECK("dbd_st_bind_col", sth, attribs);

        if (DBD_ATTRIB_TRUE(attribs, "TreatAsLOB", 10, svp)) {
            imp_sth->fbh[field-1].bind_flags |= ODBC_TREAT_AS_LOB;
        }
#if DBIXS_REVISION >= 13590
        if (DBD_ATTRIB_TRUE(attribs, "StrictlyTyped", 13, svp)) {
            imp_sth->fbh[field-1].bind_flags |= DBIstcf_STRICT;
        }

        if (DBD_ATTRIB_TRUE(attribs, "DiscardString", 13, svp)) {
            imp_sth->fbh[field-1].bind_flags |= DBIstcf_DISCARD_STRING;
        }
#endif  /* DBIXS_REVISION >= 13590 */
    }

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
        TRACE3(imp_sth, "  bind_col %d requested type:%"IVdf", flags:%lx\n",
               field, imp_sth->fbh[field-1].req_type,
               imp_sth->fbh[field-1].bind_flags);
    }

    return 1;
}



/*------------------------------------------------------------
 * bind placeholder.
 *  Is called from ODBC.xs execute()
 *  AND from ODBC.xs bind_param()
 */
int dbd_bind_ph(
    SV *sth,
    imp_sth_t *imp_sth,
    SV *ph_namesv,
    SV *newvalue,
    IV in_sql_type,
    SV *attribs,
    int is_inout,
    IV maxlen)
{
   SV **phs_svp;
   STRLEN name_len;
   char *name;
   char namebuf[30];
   phs_t *phs;
   D_imp_dbh_from_sth;
   SQLSMALLINT sql_type;

   if (SQL_NULL_HDBC == imp_dbh->hdbc) {
       DBIh_SET_ERR_CHAR(sth, (imp_xxh_t*)imp_sth, Nullch, 1,
                          "Database handle has been disconnected",
                          Nullch, Nullch);
		return -2;
	}

   sql_type = (SQLSMALLINT)in_sql_type;

   if (SvNIOK(ph_namesv) ) {                /* passed as a number */
      name = namebuf;
      my_snprintf(name, sizeof(namebuf), "%d", (int)SvIV(ph_namesv));
      name_len = strlen(name);
   }
   else {
      name = SvPV(ph_namesv, name_len);
   }
   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
       PerlIO_printf(
           DBIc_LOGPIO(imp_dbh),
           "    +dbd_bind_ph(%p, name=%s, value=%.200s, attribs=%s, "
           "sql_type=%d(%s), is_inout=%d, maxlen=%"IVdf"\n",
           sth, name, SvOK(newvalue) ? neatsvpv(newvalue, 0) : "undef",
           attribs ? SvPV_nolen(attribs) : "", sql_type,
           S_SqlTypeToString(sql_type), is_inout, maxlen);
   }

   /* the problem with the code below is we are getting SVt_PVLV when
    * an "undef" value from a hash lookup that doesn't exist.  It's an
    * "undef" value, but it doesn't come in as a scalar.
    * from a hash is arriving.  Let's leave this out until we are
    * handling arrays. JLU 7/12/02
    */
#if 0
   if (SvTYPE(newvalue) > SVt_PVMG) {    /* hook for later array logic   */
       if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
           TRACE2(imp_sth, "    !!bind %s perl type = %d -- croaking!\n",
                  name, SvTYPE(newvalue));
       croak("Can't bind non-scalar value (currently)");
   }
#endif

   if (SvROK(newvalue) && !SvAMAGIC(newvalue)) {
       croak("Cannot bind a plain reference");
   }

   /*
    * all_params_hv created during dbd_preparse.
    */
   phs_svp = hv_fetch(imp_sth->all_params_hv, name, (I32)name_len, 0);
   if (phs_svp == NULL)
      croak("Can't bind unknown placeholder '%s'", name);
   phs = (phs_t*)SvPVX(*phs_svp);	/* placeholder struct	*/

   if (phs->sv == &PL_sv_undef) { /* first bind for this placeholder */
       if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
           TRACE0(imp_sth, "      First bind of this placeholder\n");
      phs->value_type = SQL_C_CHAR;             /* default */
      phs->requested_type = sql_type;           /* save type requested */
      phs->maxlen = maxlen;                     /* 0 if not inout */
      phs->is_inout = is_inout;
      if (is_inout) {
          /* TO_DO then later sv is tested not to be newvalue !!! */
          phs->sv = SvREFCNT_inc(newvalue);  /* point to live var */
          imp_sth->has_inout_params++;
          /* build array of phs's so we can deal with out vars fast */
          if (!imp_sth->out_params_av)
              imp_sth->out_params_av = newAV();
          av_push(imp_sth->out_params_av, SvREFCNT_inc(*phs_svp));
      }
   } else {
       if (sql_type) {
           /* parameter attributes are supposed to be sticky until overriden
              so only replace requested_type if sql_type specified.
              See https://rt.cpan.org/Ticket/Display.html?id=46597 */
           phs->requested_type = sql_type;           /* save type requested */
       }
       if (is_inout != phs->is_inout) {
           croak("Can't rebind or change param %s in/out mode after first bind "
                 "(%d => %d)", phs->name, phs->is_inout, is_inout);
       }
       if (maxlen && maxlen > phs->maxlen) {
           if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
               PerlIO_printf(DBIc_LOGPIO(imp_dbh),
                             "!attempt to change param %s maxlen (%"IVdf"->%"IVdf")\n",
                             phs->name, phs->maxlen, maxlen);
           croak("Can't change param %s maxlen (%"IVdf"->%"IVdf") after first bind",
                 phs->name, phs->maxlen, maxlen);
       }
   }

   if (!is_inout) {    /* normal bind to take a (new) copy of current value */
       if (phs->sv == &PL_sv_undef)             /* (first time bind) */
           phs->sv = newSV(0);
       sv_setsv(phs->sv, newvalue);
       if (SvAMAGIC(phs->sv)) /* if it has any magic force to string */
               sv_pvn_force(phs->sv, &PL_na);
   } else if (newvalue != phs->sv) {
       if (phs->sv) {
           if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
               TRACE0(imp_sth, "      Decrementing ref count on placeholder\n");
          SvREFCNT_dec(phs->sv);
       }
      phs->sv = SvREFCNT_inc(newvalue);       /* point to live var */
   }

   if (imp_dbh->odbc_defer_binding) {
       get_param_type(sth, imp_sth, imp_dbh, phs);

       if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
           TRACE0(imp_dbh, "    -dbd_bind_ph=1\n");
       return 1;
   }
   /* fall through for "immediate" binding */

   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
       TRACE0(imp_dbh, "    -dbd_bind_ph=rebind_param\n");
   return rebind_param(sth, imp_sth, imp_dbh, phs);
}

/*------------------------------------------------------------
 * blob_read:
 * read part of a BLOB from a table.
 * XXX needs more thought
 */
int dbd_st_blob_read(sth, imp_sth, field, offset, len, destrv, destoffset)
SV *sth;
imp_sth_t *imp_sth;
int field;
long offset;
long len;
SV *destrv;
long destoffset;
{
   SQLLEN retl;
   SV *bufsv;
   RETCODE rc;

   croak("blob_read not supported yet");

   bufsv = SvRV(destrv);
   sv_setpvn(bufsv,"",0);      /* ensure it's writable string  */
   SvGROW(bufsv, len+destoffset+1);    /* SvGROW doesn't do +1 */

   /* XXX for this to work be probably need to avoid calling SQLGetData in
    * fetch. The definition of SQLGetData doesn't work well with the DBI's
    * notion of how LongReadLen would work. Needs more thought.	*/

   rc = SQLGetData(imp_sth->hstmt, (SQLSMALLINT)(field+1),
		   SQL_C_BINARY,
		   ((UCHAR *)SvPVX(bufsv)) + destoffset, len, &retl
		  );
   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
      PerlIO_printf(
          DBIc_LOGPIO(imp_sth),
          "SQLGetData(...,off=%ld, len=%ld)->rc=%d,len=%ld SvCUR=%"UVuf"\n",
          destoffset, len, rc, (long)retl, (UV)SvCUR(bufsv));

   if (!SQL_SUCCEEDED(rc)) {
      dbd_error(sth, rc, "dbd_st_blob_read/SQLGetData");
      return 0;
   }
   if (rc == SQL_SUCCESS_WITH_INFO) {	/* XXX should check for 01004 */
      retl = len;
   }

   if (retl == SQL_NULL_DATA) {	/* field is null	*/
      (void)SvOK_off(bufsv);
      return 1;
   }
#ifdef SQL_NO_TOTAL
   if (retl == SQL_NO_TOTAL) {		/* unknown length!	*/
      (void)SvOK_off(bufsv);
      return 0;
   }
#endif

   SvCUR_set(bufsv, destoffset+retl);
   *SvEND(bufsv) = '\0'; /* consistent with perl sv_setpvn etc */

   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
       TRACE1(imp_sth, "    blob_read: SvCUR=%"UVuf"\n", (UV)SvCUR(bufsv));

   return 1;
}


/*======================================================================*/
/*                                                                      */
/* S_db_storeOptions                                                    */
/* =================                                                    */
/* S_db_fetchOptions                                                    */
/* =================                                                    */
/*                                                                      */
/* An array of options/attributes we support on database handles for    */
/* storing and fetching.                                                */
/*                                                                      */
/*======================================================================*/
enum paramdir { PARAM_READ = 1, PARAM_WRITE = 2, PARAM_READWRITE = 3 };
enum gettype {PARAM_TYPE_CUSTOM = 0, PARAM_TYPE_UINT, PARAM_TYPE_STR, PARAM_TYPE_BOOL};

typedef struct {
   const char *str;
   UWORD fOption;
   enum paramdir dir;
   enum gettype type;
   UDWORD atrue;
   UDWORD afalse;
} db_params;

static db_params S_db_options[] =  {
   { "AutoCommit", SQL_AUTOCOMMIT, PARAM_READWRITE, PARAM_TYPE_BOOL, SQL_AUTOCOMMIT_ON, SQL_AUTOCOMMIT_OFF },
   { "ReadOnly", SQL_ATTR_ACCESS_MODE, PARAM_READWRITE, PARAM_TYPE_BOOL, SQL_MODE_READ_ONLY, SQL_MODE_READ_WRITE},
   { "RowCacheSize", ODBC_ROWCACHESIZE, PARAM_READ, PARAM_TYPE_CUSTOM },
#if 0 /* not defined by DBI/DBD specification */
   { "TRANSACTION",
   SQL_ACCESS_MODE, PARAM_READWRITE, PARAM_TYPE_BOOL, SQL_MODE_READ_ONLY, SQL_MODE_READ_WRITE },
   { "solid_timeout", SQL_LOGIN_TIMEOUT, PARAM_READWRITE, PARAM_TYPE_UINT },
   { "ISOLATION", PARAM_READWRITE, PARAM_TYPE_UINT, SQL_TXN_ISOLATION },
#endif
   { "odbc_SQL_DBMS_NAME", SQL_DBMS_NAME, PARAM_READ, PARAM_TYPE_CUSTOM, },
   { "odbc_SQL_DRIVER_ODBC_VER", SQL_DRIVER_ODBC_VER, PARAM_READ, PARAM_TYPE_CUSTOM },
   { "odbc_SQL_ROWSET_SIZE", SQL_ROWSET_SIZE, PARAM_READWRITE, PARAM_TYPE_UINT },
   { "odbc_ignore_named_placeholders", ODBC_IGNORE_NAMED_PLACEHOLDERS, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_default_bind_type", ODBC_DEFAULT_BIND_TYPE, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_force_bind_type", ODBC_FORCE_BIND_TYPE, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_force_rebind", ODBC_FORCE_REBIND, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_async_exec", ODBC_ASYNC_EXEC, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_err_handler", ODBC_ERR_HANDLER, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_exec_direct", ODBC_EXEC_DIRECT, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_version", ODBC_VERSION, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_cursortype", ODBC_CURSORTYPE, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_query_timeout", ODBC_QUERY_TIMEOUT, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_putdata_start", ODBC_PUTDATA_START, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_column_display_size", ODBC_COLUMN_DISPLAY_SIZE, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_utf8_on", ODBC_UTF8_ON, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_has_unicode", ODBC_HAS_UNICODE, PARAM_READ, PARAM_TYPE_CUSTOM },
   { "odbc_out_connect_string", ODBC_OUTCON_STR, PARAM_READ, PARAM_TYPE_CUSTOM},
   { "odbc_describe_parameters", ODBC_DESCRIBE_PARAMETERS, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_batch_size", ODBC_BATCH_SIZE, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_array_operations", ODBC_ARRAY_OPERATIONS, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   { "odbc_taf_callback", ODBC_TAF_CALLBACK, PARAM_READWRITE, PARAM_TYPE_CUSTOM },
   {"odbc_trace", SQL_ATTR_TRACE, PARAM_READWRITE, PARAM_TYPE_BOOL, SQL_OPT_TRACE_ON, SQL_OPT_TRACE_OFF},
   {"odbc_trace_file", SQL_ATTR_TRACEFILE, PARAM_READWRITE, PARAM_TYPE_STR, },
   { NULL },
};

/*======================================================================*/
/*                                                                      */
/*  S_dbOption                                                          */
/*  ==========                                                          */
/*                                                                      */
/*  Given a string and a length, locate this option in the specified    */
/*  array of valid options. Typically used by STORE and FETCH methods   */
/*  to decide if this option/attribute is supported by us.              */
/*                                                                      */
/*======================================================================*/
static const db_params *
   S_dbOption(const db_params *pars, char *key, STRLEN len)
{
   /* search option to set */
   while (pars->str != NULL) {
      if (strncmp(pars->str, key, len) == 0
	  && len == strlen(pars->str))
	 break;
      pars++;
   }
   if (pars->str == NULL) {
      return NULL;
   }
   return pars;
}



/*======================================================================*/
/*                                                                      */
/* dbd_db_STORE_attrib                                                  */
/* ===================                                                  */
/*                                                                      */
/* This function handles:                                               */
/*                                                                      */
/*   $dbh->{$key} = $value                                              */
/*                                                                      */
/* Method to handle the setting of driver specific attributes and DBI   */
/* attributes AutoCommit and ChopBlanks (no other DBI attributes).      */
/*                                                                      */
/* Return TRUE if the attribute was handled, else FALSE.                */
/*                                                                      */
/*======================================================================*/
int dbd_db_STORE_attrib(SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv)
{
    RETCODE rc;
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    int on;
    SQLPOINTER vParam;
    const db_params *pars;
    SQLINTEGER attr_length = SQL_IS_UINTEGER;
    int bSetSQLConnectionOption;

    if ((pars = S_dbOption(S_db_options, key, kl)) == NULL) {
        if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3))
            TRACE1(imp_dbh,
                   "    !!DBD::ODBC unsupported attribute passed (%s)\n", key);

        return FALSE;
    } else if (!(pars->dir & PARAM_WRITE)) {
        if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3))
            TRACE1(imp_dbh,
                   "    !!DBD::ODBC attempt to set non-writable attribute (%s)\n", key);
        return FALSE;
    } else if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3)) {
        TRACE1(imp_dbh, "    setting %s\n", key);
    }

    bSetSQLConnectionOption = TRUE;
    switch(pars->fOption)
    {
      case SQL_ATTR_LOGIN_TIMEOUT:
      case SQL_ATTR_TXN_ISOLATION:
      case SQL_ROWSET_SIZE:                     /* not ODBC 3 */
        vParam = (SQLPOINTER)SvIV(valuesv);
        break;
      case SQL_ATTR_TRACE:
        if (SvTRUE(valuesv)) {
            vParam = (SQLPOINTER)pars->atrue;
        } else {
            vParam = (SQLPOINTER)pars->afalse;
        }
        break;
      case SQL_ATTR_TRACEFILE:
        vParam = (SQLPOINTER) SvPV_nolen(valuesv);
        attr_length = SQL_NTS;
        break;

      case ODBC_IGNORE_NAMED_PLACEHOLDERS:
        bSetSQLConnectionOption = FALSE;
        /*
         * set value to ignore placeholders.  Will affect all
         * statements from here on.
         */
        imp_dbh->odbc_ignore_named_placeholders = SvTRUE(valuesv);
        break;

      case ODBC_ARRAY_OPERATIONS:
        bSetSQLConnectionOption = FALSE;
        /*
         * set value to ignore placeholders.  Will affect all
         * statements from here on.
         */
        imp_dbh->odbc_array_operations = SvTRUE(valuesv);
        break;

      case ODBC_DEFAULT_BIND_TYPE:
        bSetSQLConnectionOption = FALSE;
        /*
         * set value of default bind type.  Default is SQL_VARCHAR,
         * but setting to 0 will cause SQLDescribeParam to be used.
         */
        imp_dbh->odbc_default_bind_type = (SQLSMALLINT)SvIV(valuesv);
        break;

      case ODBC_FORCE_BIND_TYPE:
        bSetSQLConnectionOption = FALSE;
        /*
         * set value of the forced bind type.  Default is 0
         * which means the bind type is not forced to be anything -
         * we will use SQLDescribeParam or fall back on odbc_default_bind_type
         */
        imp_dbh->odbc_force_bind_type = (SQLSMALLINT)SvIV(valuesv);
        break;

      case ODBC_FORCE_REBIND:
        bSetSQLConnectionOption = FALSE;
        /*
         * set value to force rebind
         */
        imp_dbh->odbc_force_rebind = SvTRUE(valuesv);
        break;

      case ODBC_QUERY_TIMEOUT:
        bSetSQLConnectionOption = FALSE;
        imp_dbh->odbc_query_timeout = (SQLINTEGER)SvIV(valuesv);
        break;

      case ODBC_PUTDATA_START:
        bSetSQLConnectionOption = FALSE;
        imp_dbh->odbc_putdata_start = SvIV(valuesv);
        break;

      case ODBC_BATCH_SIZE:
        bSetSQLConnectionOption = FALSE;
        imp_dbh->odbc_batch_size = SvIV(valuesv);
        if (imp_dbh->odbc_batch_size == 0) {
            croak("You cannot set odbc_batch_size to zero");
        }
        break;

      case ODBC_TAF_CALLBACK:
        bSetSQLConnectionOption = FALSE;
        if (!SvOK(valuesv)) {
            rc = SQLSetConnectAttr(imp_dbh->hdbc,
                                   1280 /*SQL_ATTR_REGISTER_TAF_CALLBACK */,
                                   NULL, SQL_IS_POINTER);

            if (!SQL_SUCCEEDED(rc)) {
                dbd_error(dbh, rc, "SQLSetConnectAttr for odbc_taf_callback");
                return FALSE;
            }
        } else if (!SvROK(valuesv) || (SvTYPE(SvRV(valuesv)) != SVt_PVCV)) {
            croak("Need a code reference for odbc_taf_callback");
        } else {
            SvREFCNT_inc(valuesv);
            imp_dbh->odbc_taf_callback = valuesv;

            rc = SQLSetConnectAttr(imp_dbh->hdbc, 1280 /*SQL_ATTR_REGISTER_TAF_CALLBACK */,
                                   &taf_callback_wrapper, SQL_IS_POINTER);

            if (!SQL_SUCCEEDED(rc)) {
                dbd_error(dbh, rc, "SQLSetConnectAttr for odbc_taf_callback");
                return FALSE;
            }
            /* Pass our dbh into the callback */
            rc = SQLSetConnectAttr(imp_dbh->hdbc, 1281 /*SQL_ATTR_REGISTER_TAF_HANDLE*/,
                                   dbh, SQL_IS_POINTER);
            if (!SQL_SUCCEEDED(rc)) {
                dbd_error(dbh, rc, "SQLSetConnectAttr for odbc_taf_callback handle");
                return FALSE;
            }
        }
        break;

      case ODBC_COLUMN_DISPLAY_SIZE:
        bSetSQLConnectionOption = FALSE;
        imp_dbh->odbc_column_display_size = SvIV(valuesv);
        break;

      case ODBC_UTF8_ON:
        bSetSQLConnectionOption = FALSE;
        imp_dbh->odbc_utf8_on = SvIV(valuesv);
        break;

      case ODBC_EXEC_DIRECT:
        bSetSQLConnectionOption = FALSE;
        /*
         * set value of odbc_exec_direct.  Non-zero will
         * make prepare, essentially a noop and make execute
         * use SQLExecDirect.  This is to support drivers that
         * _only_ support SQLExecDirect.
         */
        imp_dbh->odbc_exec_direct = SvTRUE(valuesv);
        break;

      case ODBC_DESCRIBE_PARAMETERS:
        bSetSQLConnectionOption = FALSE;
        imp_dbh->odbc_describe_parameters = SvTRUE(valuesv);
        break;

      case ODBC_ASYNC_EXEC:
        bSetSQLConnectionOption = FALSE;
        /*
         * set asynchronous execution.  It can only be turned on if
         * the driver supports it, but will fail silently.
         */
        if (SvTRUE(valuesv)) {
            /* Only bother setting the attribute if it's not already set! */
            if (imp_dbh->odbc_async_exec)
                break;

            /*
             * Determine which method of async execution this
             * driver allows -- per-connection or per-statement
             */
            rc = SQLGetInfo(imp_dbh->hdbc,
                            SQL_ASYNC_MODE,
                            &imp_dbh->odbc_async_type,
                            sizeof(imp_dbh->odbc_async_type),
                            NULL);
            /*
             * Normally, we'd do a if (!SQL_ok(rc)) ... here.
             * Unfortunately, if the driver doesn't support async
             * mode, it may return an error here.  There doesn't
             * seem to be any other way to check (other than doing
             * a special check for the SQLSTATE).  We'll just default
             * to doing nothing and not bother checking errors.
             */

            if (imp_dbh->odbc_async_type == SQL_AM_CONNECTION){
                /*
                 * Driver has per-connection async option.  Set it
                 * now in the dbh.
                 */
                if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 4))
                    TRACE0(imp_dbh,
                           "    Supported AsyncType is SQL_AM_CONNECTION\n");
                rc = SQLSetConnectAttr(imp_dbh->hdbc,
                                       SQL_ATTR_ASYNC_ENABLE,
                                       (SQLPOINTER)SQL_ASYNC_ENABLE_ON,
                                       SQL_IS_UINTEGER);
                if (!SQL_SUCCEEDED(rc)) {
                    dbd_error(dbh, rc, "db_STORE/SQLSetConnectAttr");
                    return FALSE;
                }
                imp_dbh->odbc_async_exec = 1;
            }
            else if (imp_dbh->odbc_async_type == SQL_AM_STATEMENT){
                /*
                 * Driver has per-statement async option.  Just set
                 * odbc_async_exec and the rest will be handled by
                 * dbd_st_prepare.
                 */
                if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 4))
                    TRACE0(imp_dbh,
                           "    Supported AsyncType is SQL_AM_STATEMENT\n");
                imp_dbh->odbc_async_exec = 1;
            }
            else {   /* (imp_dbh->odbc_async_type == SQL_AM_NONE) */
                /*
                 * We're out of luck.
                 */
                if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 4))
                    TRACE0(imp_dbh, "    Supported AsyncType is SQL_AM_NONE\n");
                imp_dbh->odbc_async_exec = 0;
                return FALSE;
            }
        } else {
            /* Only bother turning it off if it was previously set... */
            if (imp_dbh->odbc_async_exec == 1) {

                /* We only need to do anything here if odbc_async_type is
                 * SQL_AM_CONNECTION since the per-statement async type
                 * is turned on only when the statement handle is created.
                 */
                if (imp_dbh->odbc_async_type == SQL_AM_CONNECTION){
                    rc = SQLSetConnectAttr(imp_dbh->hdbc,
                                           SQL_ATTR_ASYNC_ENABLE,
                                           (SQLPOINTER)SQL_ASYNC_ENABLE_OFF,
                                           SQL_IS_UINTEGER);
                    if (!SQL_SUCCEEDED(rc)) {
                        dbd_error(dbh, rc, "db_STORE/SQLSetConnectAttr");
                        return FALSE;
                    }
                }
            }
            imp_dbh->odbc_async_exec = 0;
        }
        break;

      case ODBC_ERR_HANDLER:
        bSetSQLConnectionOption = FALSE;

        /* This was taken from DBD::Sybase 0.21 */
        /* I believe the following if test which has been in DBD::ODBC
         * for ages is wrong and should (at least now) use SvOK or
         *  it is impossible to reset the error handler
         *
         *  if(valuesv == &PL_sv_undef) {
         *  imp_dbh->odbc_err_handler = NULL;
         */
        if (!SvOK(valuesv)) {
            imp_dbh->odbc_err_handler = NULL;
        } else if(imp_dbh->odbc_err_handler == (SV*)NULL) {
            imp_dbh->odbc_err_handler = newSVsv(valuesv);
        } else {
            sv_setsv(imp_dbh->odbc_err_handler, valuesv);
        }
        break;

      case ODBC_VERSION:
        /* set only in connect, nothing to store */
        bSetSQLConnectionOption = FALSE;
        break;

      case ODBC_CURSORTYPE:
        /* set only in connect, nothing to store */
        bSetSQLConnectionOption = FALSE;
        break;

      case SQL_ATTR_ACCESS_MODE:
        on = SvTRUE(valuesv);
        vParam = (SQLPOINTER)(on ? pars->atrue : pars->afalse);
        break;

      default:
        on = SvTRUE(valuesv);
        vParam = (SQLPOINTER)(on ? pars->atrue : pars->afalse);
        break;
    }

    if (bSetSQLConnectionOption) {
        rc = SQLSetConnectAttr(imp_dbh->hdbc, pars->fOption,
                               vParam, attr_length);
        if (!SQL_SUCCEEDED(rc)) {
            dbd_error(dbh, rc, "db_STORE/SQLSetConnectAttr");
            return FALSE;
        }
        else if ((SQL_SUCCESS_WITH_INFO == rc) &&
                   (pars->fOption == SQL_ATTR_ACCESS_MODE)) {
            char state[SQL_SQLSTATE_SIZE+1];
            SQLINTEGER native;
            char msg[256];
            SQLSMALLINT msg_len;

            /* If we attempted to set SQL_ATTR_ACCESS_MODE, save the result
               to return from FETCH, even if it didn't work */
            if (vParam == (SQLPOINTER)pars->atrue) {
                imp_dbh->read_only = 1;
            } else {
                imp_dbh->read_only = 0;
            }

            (void)SQLGetDiagRec(SQL_HANDLE_DBC, imp_dbh->hdbc, 1,
                                (SQLCHAR *)state, &native, msg, sizeof(msg), &msg_len);

            DBIh_SET_ERR_CHAR(
                dbh, (imp_xxh_t*)imp_dbh, "0" /* warning state */, 1,
                msg,
                state, Nullch);
        }

        if (pars->fOption == SQL_ROWSET_SIZE)
            imp_dbh->rowset_size = (SQLULEN)vParam;

        /* keep our flags in sync */
        if (kl == 10 && strEQ(key, "AutoCommit"))
            DBIc_set(imp_dbh, DBIcf_AutoCommit, SvTRUE(valuesv));
    }
    return TRUE;
}



/*======================================================================*/
/*                                                                      */
/* dbd_db_FETCH_attrib                                                  */
/* ===================                                                  */
/*                                                                      */
/* Counterpart of dbd_db_STORE_attrib handing:                          */
/*                                                                      */
/*   $value = $dbh->{$key};                                             */
/*                                                                      */
/* returns an "SV" with the value                                       */
/*                                                                      */
/*======================================================================*/
SV *dbd_db_FETCH_attrib(SV *dbh, imp_dbh_t *imp_dbh, SV *keysv)
{
    RETCODE rc;
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    const db_params *pars;
    SV *retsv = Nullsv;

    /* checking pars we need FAST */

    if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 8))
        TRACE1(imp_dbh, "    FETCH %s\n", key);

    if ((pars = S_dbOption(S_db_options, key, kl)) == NULL)
        return Nullsv;

    if (!(pars->dir & PARAM_READ))
        return Nullsv;

    switch (pars->fOption) {
      case ODBC_OUTCON_STR:
        if (!imp_dbh->out_connect_string) {
            retsv = &PL_sv_undef;
        } else {
            retsv = newSVsv(imp_dbh->out_connect_string);
        }
        break;

      case SQL_DRIVER_ODBC_VER:
        retsv = newSVpv(imp_dbh->odbc_ver, 0);
        break;

      case SQL_DBMS_NAME:
        retsv = newSVpv(imp_dbh->odbc_dbms_name, 0);
        break;

      case ODBC_IGNORE_NAMED_PLACEHOLDERS:
        retsv = newSViv(imp_dbh->odbc_ignore_named_placeholders);
        break;

      case ODBC_ARRAY_OPERATIONS:
        retsv = newSViv(imp_dbh->odbc_array_operations);
        break;

      case ODBC_QUERY_TIMEOUT:
        /*
         * fetch current value of query timeout
         *
         * -1 is our internal flag saying odbc_query_timeout has never been
         * set so we map it back to the default for ODBC which is 0
         */
        if (imp_dbh->odbc_query_timeout == -1) {
            retsv = newSViv(0);
        } else {
            retsv = newSViv(imp_dbh->odbc_query_timeout);
        }
        break;

      case ODBC_PUTDATA_START:
        retsv = newSViv(imp_dbh->odbc_putdata_start);
        break;

      case ODBC_BATCH_SIZE:
        retsv = newSViv(imp_dbh->odbc_batch_size);
        break;

      case ODBC_COLUMN_DISPLAY_SIZE:
        retsv = newSViv(imp_dbh->odbc_column_display_size);
        break;

      case ODBC_UTF8_ON:
        retsv = newSViv(imp_dbh->odbc_utf8_on);
        break;


      case ODBC_HAS_UNICODE:
        retsv = newSViv(imp_dbh->odbc_has_unicode);
        break;

      case ODBC_DEFAULT_BIND_TYPE:
        retsv = newSViv(imp_dbh->odbc_default_bind_type);
        break;

      case ODBC_FORCE_BIND_TYPE:
        retsv = newSViv(imp_dbh->odbc_force_bind_type);
        break;

      case ODBC_FORCE_REBIND:
        retsv = newSViv(imp_dbh->odbc_force_rebind);
        break;

      case ODBC_EXEC_DIRECT:
        retsv = newSViv(imp_dbh->odbc_exec_direct);
        break;

      case ODBC_DRIVER_COMPLETE:
        retsv = newSViv(imp_dbh->odbc_driver_complete);
        break;

      case ODBC_DESCRIBE_PARAMETERS:
        retsv = newSViv(imp_dbh->odbc_describe_parameters);
        break;

      case ODBC_ASYNC_EXEC:
        /*
         * fetch current value of asynchronous execution (should be
         * either 0 or 1).
         */
        retsv = newSViv(imp_dbh->odbc_async_exec);
        break;

      case ODBC_ERR_HANDLER:
        /* fetch current value of the error handler (a coderef). */
        if(imp_dbh->odbc_err_handler) {
            retsv = newSVsv(imp_dbh->odbc_err_handler);
        } else {
            retsv = &PL_sv_undef;
        }
        break;

      case ODBC_ROWCACHESIZE:
        retsv = newSViv(imp_dbh->RowCacheSize);
        break;

      default:
      {
          enum gettype type = pars->type;
          char strval[256];
          SQLUINTEGER uval = 0;
          SQLINTEGER retstrlen;

          if ((pars->fOption == SQL_ATTR_ACCESS_MODE) &&
              (imp_dbh->read_only != -1)) {

              retsv = newSViv(imp_dbh->read_only);
              break;
          }

          /*
           * The remainders we support are ODBC attributes like
           * odbc_SQL_ROWSET_SIZE (SQL_ROWSET_SIZE), odbc_trace etc
           *
           * Nothing else should get here for now unless any item is added
           * to S_db_fetchOptions.
           */

          if (type == PARAM_TYPE_UINT || type == PARAM_TYPE_BOOL) {
              rc = SQLGetConnectAttr(
                  imp_dbh->hdbc, pars->fOption, &uval, SQL_IS_UINTEGER, NULL);
          } else if (type == PARAM_TYPE_STR) {
              rc = SQLGetConnectAttr(
                  imp_dbh->hdbc, pars->fOption, strval, sizeof(strval),  &retstrlen);
          } else {
              if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3))
                  TRACE2(imp_dbh,
                         "    !!unknown type %d for %s in dbd_db_FETCH\n", type, key);
              return Nullsv;
          }
          if (!SQL_SUCCEEDED(rc)) {
              if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3))
                  TRACE1(imp_dbh,
                         "    !!SQLGetConnectAttr=%d in dbd_db_FETCH\n", rc);
              AllODBCErrors(imp_dbh->henv, imp_dbh->hdbc, 0, 0,
                            DBIc_LOGPIO(imp_dbh));
              return Nullsv;
          }

          if (type == PARAM_TYPE_UINT) {
              retsv = newSViv(uval);
          } else if (type == PARAM_TYPE_BOOL) {
              if (uval == pars->atrue)
                  retsv = newSViv(1);
              else
                  retsv = newSViv(0);
          } else if (type == PARAM_TYPE_STR) {
              retsv = newSVpv(strval, retstrlen);
          }
          break;
      } /* end of default */
    } /* outer switch */

   return sv_2mortal(retsv);
}



/*======================================================================*/
/*                                                                      */
/* S_st_fetch_params                                                    */
/* =================                                                    */
/* S_st_store_params                                                    */
/* =================                                                    */
/*                                                                      */
/* An array of options/attributes we support on statement handles for   */
/* storing and fetching.                                                */
/*                                                                      */
/*======================================================================*/

/*
 * added "need_describe" flag to handle the situation where you don't
 * have a result set yet to describe.  Certain attributes don't need
 * the result set to operate, hence don't do a describe unless you need
 * to do one.
 * DBD::ODBC 0.45_15
 * */
typedef struct {
   const char *str;
   unsigned len:8;
   unsigned array:1;
   unsigned need_describe:1;
   unsigned filler:22;
} T_st_params;

#define s_A(str,need_describe) { str, sizeof(str)-1,0,need_describe }
static T_st_params S_st_fetch_params[] =
{
   s_A("NUM_OF_PARAMS",1),	/* 0 */
   s_A("NUM_OF_FIELDS",1),	/* 1 */
   s_A("NAME",1),		/* 2 */
   s_A("NULLABLE",1),		/* 3 */
   s_A("TYPE",1),		/* 4 */
   s_A("PRECISION",1),		/* 5 */
   s_A("SCALE",1),		/* 6 */
   s_A("sol_type",1),		/* 7 */
   s_A("sol_length",1),         /* 8 */
   s_A("CursorName",1),		/* 9 */
   s_A("odbc_more_results",1),	/* 10 */
   s_A("ParamValues",0),        /* 11 */

   s_A("LongReadLen",0),        /* 12 */
   s_A("odbc_ignore_named_placeholders",0),	/* 13 */
   s_A("odbc_default_bind_type",0),             /* 14 */
   s_A("odbc_force_rebind",0),	/* 15 */
   s_A("odbc_query_timeout",0),	/* 16 */
   s_A("odbc_putdata_start",0),	/* 17 */
   s_A("ParamTypes",0),        /* 18 */
   s_A("odbc_column_display_size",0),	/* 19 */
   s_A("odbc_force_bind_type",0),             /* 20 */
   s_A("odbc_batch_size",0),	/* 21 */
   s_A("odbc_array_operations",0),	/* 22 */
   s_A("",0),			/* END */
};

static T_st_params S_st_store_params[] =
{
   s_A("odbc_ignore_named_placeholders",0),	/* 0 */
   s_A("odbc_default_bind_type",0),	/* 1 */
   s_A("odbc_force_rebind",0),	/* 2 */
   s_A("odbc_query_timeout",0),	/* 3 */
   s_A("odbc_putdata_start",0),	/* 4 */
   s_A("odbc_column_display_size",0),	/* 5 */
   s_A("odbc_force_bind_type",0),	/* 6 */
   s_A("odbc_batch_size",0),	/* 7 */
   s_A("odbc_array_operations",0),	/* 8 */
   s_A("",0),			/* END */
};
#undef s_A



/*======================================================================*/
/*                                                                      */
/*  dbd_st_FETCH_attrib                                                 */
/*  ===================                                                 */
/*                                                                      */
/*======================================================================*/
SV *dbd_st_FETCH_attrib(SV *sth, imp_sth_t *imp_sth, SV *keysv)
{
   STRLEN kl;
   char *key = SvPV(keysv,kl);
   int i;
   SV *retsv = NULL;
   T_st_params *par;
   char cursor_name[256];
   SWORD cursor_name_len;
   RETCODE rc;

   for (par = S_st_fetch_params; par->len > 0; par++)
      if (par->len == kl && strEQ(key, par->str))
	 break;


   if (par->len <= 0)
      return Nullsv;

   if (par->need_describe && !imp_sth->done_desc &&
       !dbd_describe(sth, imp_sth,0))
   {
      /* dbd_describe has already called dbd_error()          */
      /* we can't return Nullsv here because the xs code will */
      /* then just pass the attribute name to DBI for FETCH.  */
       if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
           TRACE1(imp_sth,
                  "   !!!dbd_st_FETCH_attrib (%s) needed query description, "
                  "but failed\n", par->str);
      }
      if (DBIc_WARN(imp_sth)) {
          warn("Describe failed during %s->FETCH(%s,%d)",
               SvPV(sth,PL_na), key,imp_sth->done_desc);
      }
      return &PL_sv_undef;
   }

   i = DBIc_NUM_FIELDS(imp_sth);

   switch(par - S_st_fetch_params)
   {
      AV *av;

      case 0:			/* NUM_OF_PARAMS */
	 return Nullsv;	/* handled by DBI */
      case 1:			/* NUM_OF_FIELDS */
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 9)) {
	    TRACE1(imp_sth, "    dbd_st_FETCH_attrib NUM_OF_FIELDS %d\n", i);
        }
        retsv = newSViv(i);
        break;
      case 2: 			/* NAME */
	 av = newAV();
	 retsv = newRV_inc(sv_2mortal((SV*)av));
	 if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 9)) {
	    int j;
	    TRACE1(imp_sth, "    dbd_st_FETCH_attrib NAMES %d\n", i);

	    for (j = 0; j < i; j++)
                TRACE1(imp_sth, "\t%s\n", imp_sth->fbh[j].ColName);
	 }
	 while(--i >= 0) {
             if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 9)) {
                 TRACE2(imp_sth, "    Colname %d => %s\n",
                        i, imp_sth->fbh[i].ColName);
             }
#ifdef WITH_UNICODE
             av_store(av, i,
                      sv_newwvn((SQLWCHAR *)imp_sth->fbh[i].ColName,
                                imp_sth->fbh[i].ColNameLen));
#else
             av_store(av, i, newSVpv(imp_sth->fbh[i].ColName, 0));
#endif
	 }
	 break;
      case 3:			/* NULLABLE */
	 av = newAV();
	 retsv = newRV_inc(sv_2mortal((SV*)av));
	 while(--i >= 0)
	    av_store(av, i,
		     (imp_sth->fbh[i].ColNullable == SQL_NO_NULLS)
		     ? &PL_sv_no : &PL_sv_yes);
	 break;
      case 4:			/* TYPE */
	 av = newAV();
	 retsv = newRV_inc(sv_2mortal((SV*)av));
	 while(--i >= 0)
	    av_store(av, i, newSViv(imp_sth->fbh[i].ColSqlType));
	 break;
      case 5:			/* PRECISION */
	 av = newAV();
	 retsv = newRV_inc(sv_2mortal((SV*)av));
	 while(--i >= 0)
	    av_store(av, i, newSViv(imp_sth->fbh[i].ColDef));
	 break;
      case 6:			/* SCALE */
	 av = newAV();
	 retsv = newRV_inc(sv_2mortal((SV*)av));
	 while(--i >= 0)
	    av_store(av, i, newSViv(imp_sth->fbh[i].ColScale));
	 break;
      case 7:			/* sol_type */
	 av = newAV();
	 retsv = newRV_inc(sv_2mortal((SV*)av));
	 while(--i >= 0)
	    av_store(av, i, newSViv(imp_sth->fbh[i].ColSqlType));
	 break;
      case 8:			/* sol_length */
	 av = newAV();
	 retsv = newRV_inc(sv_2mortal((SV*)av));
	 while(--i >= 0)
	    av_store(av, i, newSViv(imp_sth->fbh[i].ColLength));
	 break;
      case 9:			/* CursorName */
	 rc = SQLGetCursorName(imp_sth->hstmt, cursor_name,
                               sizeof(cursor_name), &cursor_name_len);
	 if (!SQL_SUCCEEDED(rc)) {
	    dbd_error(sth, rc, "st_FETCH/SQLGetCursorName");
	    return Nullsv;
	 }
	 retsv = newSVpv(cursor_name, cursor_name_len);
	 break;
      case 10:                /* odbc_more_results */
	 retsv = newSViv(imp_sth->moreResults);
	 if (i == 0 && imp_sth->moreResults == 0) {
	    int outparams = (imp_sth->out_params_av) ?
                AvFILL(imp_sth->out_params_av)+1 : 0;
	    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
                TRACE0(imp_sth,
                       "    numfields == 0 && moreResults = 0 finish\n");
	    }
	    if (outparams) {
	       odbc_handle_outparams(imp_sth, DBIc_TRACE_LEVEL(imp_sth));
	    }
        imp_sth->done_desc = 0;                 /* redo describe */

	       /* XXX need to 'finish' here */
	    dbd_st_finish(sth, imp_sth);
	 } else {
             if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4)) {
                 TRACE2(imp_sth,
                        "    fetch odbc_more_results, numfields == %d "
                        "&& moreResults = %d\n", i, imp_sth->moreResults);
             }
         }
	 break;
      case 11:                                  /* ParamValues */
      {
	 /* not sure if there's a memory leak here. */
	 HV *paramvalues = newHV();
	 if (imp_sth->all_params_hv) {
	    HV *hv = imp_sth->all_params_hv;
	    SV *sv;
	    char *key;
	    I32 retlen;
	    hv_iterinit(hv);
	    while( (sv = hv_iternextsv(hv, &key, &retlen)) != NULL ) {
	       if (sv != &PL_sv_undef) {
		  phs_t *phs = (phs_t*)(void*)SvPVX(sv);
		  (void)hv_store(paramvalues, phs->name, (I32)strlen(phs->name),
                         newSVsv(phs->sv), 0);
	       }
	    }
	 }
	 /* ensure HV is freed when the ref is freed */
	 retsv = newRV_noinc((SV *)paramvalues);
         break;
      }
      case 12: /* LongReadLen */
	 retsv = newSViv(DBIc_LongReadLen(imp_sth));
	 break;
      case 13: /* odbc_ignore_named_placeholders */
	 retsv = newSViv(imp_sth->odbc_ignore_named_placeholders);
	 break;
      case 14: /* odbc_default_bind_type */
	 retsv = newSViv(imp_sth->odbc_default_bind_type);
	 break;
      case 15: /* odbc_force_rebind */
	 retsv = newSViv(imp_sth->odbc_force_rebind);
	 break;
      case 16: /* odbc_query_timeout */
        /*
         * -1 is our internal flag saying odbc_query_timeout has never been
         * set so we map it back to the default for ODBC which is 0
         */
        if (imp_sth->odbc_query_timeout == -1) {
            retsv = newSViv(0);
        } else {
            retsv = newSViv(imp_sth->odbc_query_timeout);
        }
        break;
      case 17: /* odbc_putdata_start */
        retsv = newSViv(imp_sth->odbc_putdata_start);
        break;
      case 18:                                  /* ParamTypes */
      {
	 /* not sure if there's a memory leak here. */
	 HV *paramtypes = newHV();
	 if (imp_sth->all_params_hv) {
	    HV *hv = imp_sth->all_params_hv;
	    SV *sv;
	    char *key;
	    I32 retlen;
	    hv_iterinit(hv);
	    while( (sv = hv_iternextsv(hv, &key, &retlen)) != NULL ) {
	       if (sv != &PL_sv_undef) {
                   HV *subh = newHV();

                   phs_t *phs = (phs_t*)(void*)SvPVX(sv);
                   (void)hv_store(subh, "TYPE", 4, newSViv(phs->sql_type), 0);
                   (void)hv_store(paramtypes, phs->name, (I32)strlen(phs->name),
                                  newRV_noinc((SV *)subh), 0);
	       }
	    }
	 }
	 /* ensure HV is freed when the ref is freed */
	 retsv = newRV_noinc((SV *)paramtypes);
         break;
      }
      case 19: /* odbc_column_display_size */
        retsv = newSViv(imp_sth->odbc_column_display_size);
        break;
      case 20: /* odbc_force_bind_type */
	 retsv = newSViv(imp_sth->odbc_force_bind_type);
	 break;
      case 21: /* odbc_batch_size */
        retsv = newSViv(imp_sth->odbc_batch_size);
        break;
      case 22: /* odbc_array_operations */
	 retsv = newSViv(imp_sth->odbc_array_operations);
	 break;
      default:
	 return Nullsv;
   }
   return sv_2mortal(retsv);
}



/*======================================================================*/
/*                                                                      */
/*  dbd_st_STORE_attrib                                                 */
/*  ===================                                                 */
/*                                                                      */
/*======================================================================*/
int dbd_st_STORE_attrib(SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv)
{
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    T_st_params *par;

    for (par = S_st_store_params; par->len > 0; par++)
        if (par->len == kl && strEQ(key, par->str))
            break;

    if (par->len <= 0)
        return FALSE;

    switch(par - S_st_store_params)
    {
      case 0:
        imp_sth->odbc_ignore_named_placeholders = SvTRUE(valuesv);
        return TRUE;

      case 1:
        imp_sth->odbc_default_bind_type = (SQLSMALLINT)SvIV(valuesv);
        return TRUE;
        break;

      case 2:
        imp_sth->odbc_force_rebind = (int)SvIV(valuesv);
        return TRUE;
        break;

      case 3:
        imp_sth->odbc_query_timeout = SvIV(valuesv);
        return TRUE;
        break;

      case 4:
        imp_sth->odbc_putdata_start = SvIV(valuesv);
        return TRUE;
        break;

      case 5:
        imp_sth->odbc_column_display_size = SvIV(valuesv);
        return TRUE;
        break;

      case 6:
        imp_sth->odbc_force_bind_type = (SQLSMALLINT)SvIV(valuesv);
        return TRUE;
        break;

      case 7:
        imp_sth->odbc_batch_size = SvIV(valuesv);
        if (imp_sth->odbc_batch_size == 0) {
            croak("You cannot set odbc_batch_size to zero");
        }
        return TRUE;
        break;

      case 8:
        imp_sth->odbc_array_operations = SvTRUE(valuesv);
        return TRUE;

    }
    return FALSE;
}



SV *odbc_get_info(dbh, ftype)
SV *dbh;
int ftype;
{
    D_imp_dbh(dbh);
    RETCODE rc;
    SV *retsv = NULL;
    int i;
    int size = 256;
    char *rgbInfoValue;
    SWORD cbInfoValue = -2;

    New(0, rgbInfoValue, size, char);

    /* See fancy logic below */
    for (i = 0; i < 6; i++)
        rgbInfoValue[i] = (char)0xFF;

    rc = SQLGetInfo(imp_dbh->hdbc, (SQLUSMALLINT)ftype,
                    rgbInfoValue, (SQLSMALLINT)(size-1), &cbInfoValue);
    if (cbInfoValue > size-1) {
        Renew(rgbInfoValue, cbInfoValue+1, char);
        rc = SQLGetInfo(imp_dbh->hdbc, (SQLUSMALLINT)ftype,
                        rgbInfoValue, cbInfoValue, &cbInfoValue);
    }
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(dbh, rc, "odbc_get_info/SQLGetInfo");
        Safefree(rgbInfoValue);
        /* patched 2/12/02, thanks to Steffen Goldner */
        return &PL_sv_undef;
        /* return Nullsv; */
    }

    /* Fancy logic here to determine if result is a string or int */
    if (cbInfoValue == -2)				/* is int */
        retsv = newSViv(*(int *)rgbInfoValue);	/* XXX cast */
    else if (cbInfoValue != 2 && cbInfoValue != 4)	/* must be string */
        retsv = newSVpv(rgbInfoValue, 0);
    else if (rgbInfoValue[cbInfoValue] == '\0')	/* must be string */ /* patch from Steffen Goldner 0.37 2/12/02 */
        retsv = newSVpv(rgbInfoValue, 0);
    else if (cbInfoValue == 2)			/* short */
        retsv = newSViv(*(short *)rgbInfoValue);	/* XXX cast */
    else if (cbInfoValue == 4)			/* int */
        retsv = newSViv(*(int *)rgbInfoValue);	/* XXX cast */
    else
        croak("panic: SQLGetInfo cbInfoValue == %d", cbInfoValue);

    if (DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 4))
        PerlIO_printf(
            DBIc_LOGPIO(imp_dbh),
            "    SQLGetInfo: ftype %d, cbInfoValue %d: %s\n",
            ftype, cbInfoValue, neatsvpv(retsv,0));

    Safefree(rgbInfoValue);
    return sv_2mortal(retsv);
}

#ifdef THE_FOLLOWING_NO_LONGER_USED_REPLACE_BY_dbd_st_statistics
int odbc_get_statistics(dbh, sth, CatalogName, SchemaName, TableName, Unique)
SV *	 dbh;
SV *	 sth;
char * CatalogName;
char * SchemaName;
char * TableName;
int		 Unique;
{
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;
    int dbh_active;

    imp_sth->henv = imp_dbh->henv;	/* needed for dbd_error */
    imp_sth->hdbc = imp_dbh->hdbc;

    imp_sth->done_desc = 0;

    if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

    rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
        dbd_error(sth, rc, "odbc_get_statistics/SQLAllocHandle(stmt)");
        return 0;
    }

    rc = SQLStatistics(imp_sth->hstmt,
                       CatalogName, (SQLSMALLINT)strlen(CatalogName),
                       SchemaName, (SQLSMALLINT)strlen(SchemaName),
                       TableName, (SQLSMALLINT)strlen(TableName),
                       (SQLUSMALLINT)Unique, (SQLUSMALLINT)0);
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        TRACE1(imp_dbh, "    SQLStatistics=%d\n", rc);

    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_get_statistics/SQLGetStatistics");
        return 0;
    }
    return build_results(sth, imp_sth, dbh, imp_dbh, rc);
}
#endif /* THE_FOLLOWING_NO_LONGER_USED_REPLACE_BY_dbd_st_statistics */

#ifdef THE_FOLLOWING_NO_LONGER_USED_REPLACE_BY_dbd_st_primary_keys
int odbc_get_primary_keys(dbh, sth, CatalogName, SchemaName, TableName)
SV *	 dbh;
SV *	 sth;
char * CatalogName;
char * SchemaName;
char * TableName;
{
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;
    int dbh_active;

    imp_sth->henv = imp_dbh->henv;	/* needed for dbd_error */
    imp_sth->hdbc = imp_dbh->hdbc;

    imp_sth->done_desc = 0;

    if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

    rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
        dbd_error(sth, rc, "odbc_get_primary_keys/SQLAllocHandle(stmt)");
        return 0;
    }

    rc = SQLPrimaryKeys(imp_sth->hstmt,
                        CatalogName, (SQLSMALLINT)strlen(CatalogName),
                        SchemaName, (SQLSMALLINT)strlen(SchemaName),
                        TableName, (SQLSMALLINT)strlen(TableName));
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        TRACE1(imp_dbh, "    SQLPrimaryKeys rc = %d\n", rc);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_get_primary_keys/SQLPrimaryKeys");
        return 0;
    }
    return build_results(sth, imp_sth, dbh, imp_dbh, rc);
}
#endif /* THE_FOLLOWING_NO_LONGER_USED_REPLACE_BY_dbd_st_primary_keys */



int odbc_get_special_columns(dbh, sth, Identifier, CatalogName, SchemaName, TableName, Scope, Nullable)
SV *	 dbh;
SV *	 sth;
int    Identifier;
char * CatalogName;
char * SchemaName;
char * TableName;
int    Scope;
int    Nullable;
{
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;
    int dbh_active;

    imp_sth->henv = imp_dbh->henv;	/* needed for dbd_error */
    imp_sth->hdbc = imp_dbh->hdbc;

    imp_sth->done_desc = 0;

    if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

    rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
        dbd_error(sth, rc, "odbc_get_special_columns/SQLAllocHandle(stmt)");
        return 0;
    }

    rc = SQLSpecialColumns(imp_sth->hstmt,
                           (SQLSMALLINT)Identifier,
                           CatalogName, (SQLSMALLINT)strlen(CatalogName),
                           SchemaName, (SQLSMALLINT)strlen(SchemaName),
                           TableName, (SQLSMALLINT)strlen(TableName),
                           (SQLSMALLINT)Scope, (SQLSMALLINT)Nullable);
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        TRACE1(imp_dbh, "    SQLSpecialColumns=%d\n", rc);

    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_get_special_columns/SQLSpecialClumns");
        return 0;
    }
    return build_results(sth, imp_sth, dbh, imp_dbh, rc);
}



int odbc_get_foreign_keys(dbh, sth, PK_CatalogName, PK_SchemaName, PK_TableName, FK_CatalogName, FK_SchemaName, FK_TableName)
SV *	 dbh;
SV *	 sth;
char * PK_CatalogName;
char * PK_SchemaName;
char * PK_TableName;
char * FK_CatalogName;
char * FK_SchemaName;
char * FK_TableName;
{
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;
    int dbh_active;
    size_t max_stmt_len;

    imp_sth->henv = imp_dbh->henv;	/* needed for dbd_error */
    imp_sth->hdbc = imp_dbh->hdbc;

    imp_sth->done_desc = 0;

    if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

    rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
        dbd_error(sth, rc, "odbc_get_foreign_keys/SQLAllocHandle(stmt)");
        return 0;
    }


    /* just for sanity, later.  Any internals that may rely on this (including */
    /* debugging) will have valid data */
    max_stmt_len = strlen(cSqlForeignKeys)+
        strlen(XXSAFECHAR(PK_CatalogName))+
        strlen(XXSAFECHAR(PK_SchemaName))+
        strlen(XXSAFECHAR(PK_TableName))+
        strlen(XXSAFECHAR(FK_CatalogName))+
        strlen(XXSAFECHAR(FK_SchemaName))+
        strlen(XXSAFECHAR(FK_TableName))+
        1;

    imp_sth->statement = (char *)safemalloc(max_stmt_len);

    my_snprintf(imp_sth->statement, max_stmt_len,
                cSqlForeignKeys,
                XXSAFECHAR(PK_CatalogName), XXSAFECHAR(PK_SchemaName),
                XXSAFECHAR(PK_TableName), XXSAFECHAR(FK_CatalogName),
                XXSAFECHAR(FK_SchemaName),XXSAFECHAR(FK_TableName)
                );
    /* fix to handle "" (undef) calls -- thanks to Kevin Shepherd */
    rc = SQLForeignKeys(
        imp_sth->hstmt,
        (PK_CatalogName && *PK_CatalogName) ? PK_CatalogName : 0, SQL_NTS,
        (PK_SchemaName && *PK_SchemaName) ? PK_SchemaName : 0, SQL_NTS,
        (PK_TableName && *PK_TableName) ? PK_TableName : 0, SQL_NTS,
        (FK_CatalogName && *FK_CatalogName) ? FK_CatalogName : 0, SQL_NTS,
        (FK_SchemaName && *FK_SchemaName) ? FK_SchemaName : 0, SQL_NTS,
        (FK_TableName && *FK_TableName) ? FK_TableName : 0, SQL_NTS);
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        TRACE1(imp_dbh, "    SQLForeignKeys=%d\n", rc);

    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_get_foreign_keys/SQLForeignKeys");
        return 0;
    }
    return build_results(sth, imp_sth, dbh, imp_dbh, rc);
}



#ifdef ODBC_NOW_DEPRECATED
int odbc_describe_col(
    SV *sth,
    int colno,
    char *ColumnName,
    I16 BufferLength,
    I16 *NameLength,
    I16 *DataType,
    U32 *ColumnSize,
    I16 *DecimalDigits,
    I16 *Nullable)
{
   D_imp_sth(sth);
   SQLULEN ColSize;
   RETCODE rc;
   rc = SQLDescribeCol(imp_sth->hstmt, (SQLSMALLINT)colno,
		       ColumnName, BufferLength, NameLength,
		       DataType, &ColSize, DecimalDigits, Nullable);
   if (!SQL_SUCCEEDED(rc)) {
      dbd_error(sth, rc, "DescribeCol/SQLDescribeCol");
      return 0;
   }
   *ColumnSize = (U32)ColSize;
   return 1;
}
#endif /* ODBC_NOW_DEPRECATED */



int odbc_get_type_info(
    SV *dbh,
    SV *sth,
    int ftype)
{
   D_imp_dbh(dbh);
   D_imp_sth(sth);
   RETCODE rc;
   int dbh_active;
   size_t max_stmt_len;

#if 0
   /* TBD: cursorname? */
   char cname[128];			/* cursorname */
#endif

   imp_sth->henv = imp_dbh->henv;	/* needed for dbd_error */
   imp_sth->hdbc = imp_dbh->hdbc;

   imp_sth->done_desc = 0;

   if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

   rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
   if (rc != SQL_SUCCESS) {
      dbd_error(sth, rc, "odbc_get_type_info/SQLAllocHandle(stmt)");
      return 0;
   }

   /* just for sanity, later. Any internals that may rely on this (including */
   /* debugging) will have valid data */
   max_stmt_len = strlen(cSqlGetTypeInfo)+(abs(ftype)/10)+2;
   imp_sth->statement = (char *)safemalloc(max_stmt_len);
   my_snprintf(imp_sth->statement, max_stmt_len, cSqlGetTypeInfo, ftype);

#ifdef WITH_UNICODE
   rc = SQLGetTypeInfoW(imp_sth->hstmt, (SQLSMALLINT)ftype);
#else
   rc = SQLGetTypeInfo(imp_sth->hstmt, (SQLSMALLINT)ftype);
#endif
   if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
       TRACE2(imp_dbh, "    SQLGetTypeInfo(%d)=%d\n", ftype, rc);

   dbd_error(sth, rc, "odbc_get_type_info/SQLGetTypeInfo");
   if (!SQL_SUCCEEDED(rc)) {
      SQLFreeHandle(SQL_HANDLE_STMT,imp_sth->hstmt);
      imp_sth->hstmt = SQL_NULL_HSTMT;
      return 0;
   }

   return build_results(sth, imp_sth, dbh, imp_dbh, rc);
}



SV *odbc_cancel(SV *sth)
{
    D_imp_sth(sth);
    RETCODE rc;

    rc = SQLCancel(imp_sth->hstmt);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_cancel/SQLCancel");
        return Nullsv;
    }
    return newSViv(1);
}



IV odbc_st_lob_read(
    SV *sth,
    int colno,
    SV *data,
    UV length,
    IV type)
{
    D_imp_sth(sth);
    SQLLEN len = 0;
    SQLRETURN rc;
    imp_fbh_t *fbh;
    SQLSMALLINT col_type;
    IV retlen = 0;
    char *buf = SvPV_nolen(data);

    fbh = &imp_sth->fbh[colno-1];

    /*printf("fbh->ColSqlType=%s\n", S_SqlTypeToString(fbh->ColSqlType));*/
    if ((fbh->bind_flags & ODBC_TREAT_AS_LOB) == 0) {
        croak("Column %d was not bound with TreatAsLOB", colno);
    }

    if ((fbh->ColSqlType == SQL_BINARY) ||
        (fbh->ColSqlType == SQL_VARBINARY) ||
        (fbh->ColSqlType == SQL_LONGVARBINARY)) {
        col_type = SQL_C_BINARY;
    } else {
#ifdef WITH_UNICODE
        col_type = SQL_C_WCHAR;
#else
        col_type = SQL_C_CHAR;
#endif  /* WITH_UNICODE */
    }
    if (type != 0) {
        col_type = (SQLSMALLINT)type;
    }

    rc = SQLGetData(imp_sth->hstmt, colno, col_type, buf, length, &len);
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        PerlIO_printf(DBIc_LOGPIO(imp_sth),
                      "   SQLGetData(col=%d,type=%d)=%d (retlen=%ld)\n",
                      colno, col_type, rc, len);

    if (rc == SQL_NO_DATA) {
        /* finished - SQLGetData returns this when you call it after it has
           returned all of the data */
        return 0;
    } else if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_st_lob_read/SQLGetData");
        return -1;
    } else if (rc == SQL_SUCCESS_WITH_INFO) {
        /* we are assuming this is 01004 - string data right truncation
           unless len == SQL_NO_TOTAL */
        if (len == SQL_NO_TOTAL) {
            dbd_error(sth, rc,
                      "Driver did not return the lob length - SQL_NO_TOTAL)");
            return -1;
        }
        retlen = length;
        if (col_type == SQL_C_CHAR) {
            retlen--;                           /* NUL chr at end */
        }
    } else if (rc == SQL_SUCCESS) {
        if (len == SQL_NULL_DATA) {
            return 0;
        }
        retlen = len;
    }

#ifdef WITH_UNICODE
    if (col_type == SQL_C_WCHAR) {
        char *c1;

        c1 = PVallocW((SQLWCHAR *)buf);
        buf = SvGROW(data, strlen(c1) + 1);
        retlen = retlen / sizeof(SQLWCHAR);

        strcpy(buf, c1);
        PVfreeW(c1);

# ifdef sv_utf8_decode
        sv_utf8_decode(data);
# else
        SvUTF8_on(data);
# endif
    }
# endif
    return retlen;
}



/************************************************************************/
/*                                                                      */
/*  odbc_col_attributes                                                 */
/*  ===================                                                 */
/*                                                                      */
/************************************************************************/
SV *odbc_col_attributes(SV *sth, int colno, int desctype)
{
    D_imp_sth(sth);
    RETCODE rc;
    SV *retsv = NULL;
    unsigned char str_attr[512];
    SWORD str_attr_len = 0;
    SQLLEN num_attr = 0;

    memset(str_attr, '\0', sizeof(str_attr));

    if ( !DBIc_ACTIVE(imp_sth) ) {
        dbd_error(sth, DBDODBC_INTERNAL_ERROR, "no statement executing");
        return Nullsv;
    }

    /*
     * At least on Win95, calling this with colno==0 would "core" dump/GPF.
     * protect, even though it's valid for some values of desctype
     * (e.g. SQL_COLUMN_COUNT, since it doesn't depend on the colcount)
     */
    if (colno == 0) {
        dbd_error(sth, DBDODBC_INTERNAL_ERROR,
                  "cannot obtain SQLColAttributes for column 0");
        return Nullsv;
    }

    /*
     *  workaround a problem in unixODBC 2.2.11 which can write off the
     *  end of the str_attr buffer when built with unicode - lie about
     *  buffer size - we've got more than we admit to.
     */
    rc = SQLColAttributes(imp_sth->hstmt, (SQLUSMALLINT)colno,
                          (SQLUSMALLINT)desctype,
                          str_attr, sizeof(str_attr)/2,
                          &str_attr_len, &num_attr);

    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_col_attributes/SQLColAttributes");
        return Nullsv;
    } else if (SQL_SUCCESS_WITH_INFO == rc) {
        warn("SQLColAttributes has truncated returned data");
    }

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3)) {
        PerlIO_printf(
            DBIc_LOGPIO(imp_sth),
            "    SQLColAttributes: colno=%d, desctype=%d, str_attr=%s, "
            "str_attr_len=%d, num_attr=%ld",
            colno, desctype, str_attr, str_attr_len, (long)num_attr);
    }

    switch (desctype) {
      case SQL_COLUMN_AUTO_INCREMENT:
      case SQL_COLUMN_CASE_SENSITIVE:
      case SQL_COLUMN_COUNT:
      case SQL_COLUMN_DISPLAY_SIZE:
      case SQL_COLUMN_LENGTH:
      case SQL_COLUMN_MONEY:
      case SQL_COLUMN_NULLABLE:
      case SQL_COLUMN_PRECISION:
      case SQL_COLUMN_SCALE:
      case SQL_COLUMN_SEARCHABLE:
      case SQL_COLUMN_TYPE:
      case SQL_COLUMN_UNSIGNED:
      case SQL_COLUMN_UPDATABLE:
      {
          retsv = newSViv(num_attr);
          break;
      }
      case SQL_COLUMN_LABEL:
      case SQL_COLUMN_NAME:
      case SQL_COLUMN_OWNER_NAME:
      case SQL_COLUMN_QUALIFIER_NAME:
      case SQL_COLUMN_TABLE_NAME:
      case SQL_COLUMN_TYPE_NAME:
      {
          /*
           * NOTE: in unixODBC 2.2.11, if you called SQLDriverConnectW and
           * then called SQLColAttributes for a string type it would often
           * return half the number of characters it had written to
           * str_attr in str_attr_len.
           */
          retsv = newSVpv(str_attr, strlen(str_attr));
          break;
      }
      default:
      {
          dbd_error(sth, DBDODBC_INTERNAL_ERROR,
                    "driver-specific column attributes not supported");
          return Nullsv;
          break;
      }
    }


#ifdef OLD_STUFF_THAT_SEEMS_FLAWED
    /*
     * sigh...Oracle's ODBC driver version 8.0.4 resets str_attr_len to 0, when
     * putting a value in num_attr.  This is a change!
     *
     * double sigh.  SQL Server (and MySql under Unix) set str_attr_len
     * but use num_attr, not str_attr.  This change may be problematic
     * for other drivers. (the additional || num_attr != -2...)
     */
    if (str_attr_len == -2 || str_attr_len == 0 || num_attr != -2)
        retsv = newSViv(num_attr);
    else if (str_attr_len != 2 && str_attr_len != 4)
        retsv = newSVpv(str_attr, 0);
    else if (str_attr[str_attr_len] == '\0') /* fix for DBD::ODBC 0.39 thanks to Nicolas DeRico */
        retsv = newSVpv(str_attr, 0);
    else {
        if (str_attr_len == 2)
            retsv = newSViv(*(short *)str_attr);
        else
            retsv = newSViv(*(int *)str_attr);
    }
#endif

    return sv_2mortal(retsv);
}



#ifdef OLD_ONE_BEFORE_SCALARS
int
   odbc_db_columns(dbh, sth, catalog, schema, table, column)
   SV *dbh;
SV *sth;
char *catalog;
char *schema;
char *table;
char *column;
{
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;
    int dbh_active;
    size_t max_stmt_len;
    imp_sth->henv = imp_dbh->henv;	/* needed for dbd_error */
    imp_sth->hdbc = imp_dbh->hdbc;

    imp_sth->done_desc = 0;

    if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

    rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
        dbd_error(sth, rc, "odbc_db_columns/SQLAllocHandle(stmt)");
        return 0;
    }

    /* just for sanity, later.  Any internals that may rely on this (including */
    /* debugging) will have valid data */
    max_stmt_len = strlen(cSqlColumns)+
        strlen(XXSAFECHAR(catalog))+
        strlen(XXSAFECHAR(schema))+
        strlen(XXSAFECHAR(table))+
        strlen(XXSAFECHAR(column))+1;

    imp_sth->statement = (char *)safemalloc(max_stmt_len);

    my_snprintf(imp_sth->statement, max_stmt_len,
                cSqlColumns, XXSAFECHAR(catalog), XXSAFECHAR(schema),
                XXSAFECHAR(table), XXSAFECHAR(column));

    rc = SQLColumns(imp_sth->hstmt,
                    (catalog && *catalog) ? catalog : 0, SQL_NTS,
                    (schema && *schema) ? schema : 0, SQL_NTS,
                    (table && *table) ? table : 0, SQL_NTS,
                    (column && *column) ? column : 0, SQL_NTS);

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        PerlIO_printf(
            DBIc_LOGPIO(imp_dbh),
            "    SQLColumns call: cat = %s, schema = %s, table = %s, "
            "column = %s\n",
            XXSAFECHAR(catalog), XXSAFECHAR(schema), XXSAFECHAR(table),
            XXSAFECHAR(column));
    dbd_error(sth, rc, "odbc_columns/SQLColumns");

    if (!SQL_SUCCEEDED(rc)) {
        SQLFreeHandle(SQL_HANDLE_STMT,imp_sth->hstmt);
        imp_sth->hstmt = SQL_NULL_HSTMT;
        return 0;
    }
    return build_results(sth, imp_sth, dbh, imp_dbh, rc);
}
#endif  /* OLD_ONE_BEFORE_SCALARS */


int odbc_db_columns(
    SV *dbh,
    SV *sth,
    SV *catalog,
    SV *schema,
    SV *table,
    SV *column)
{
    D_imp_dbh(dbh);
    D_imp_sth(sth);
    RETCODE rc;
    int dbh_active;
    size_t max_stmt_len;
    char *acatalog = NULL;
    char *aschema = NULL;
    char *atable = NULL;
    char *acolumn = NULL;
    imp_sth->henv = imp_dbh->henv;	/* needed for dbd_error */
    imp_sth->hdbc = imp_dbh->hdbc;

    imp_sth->done_desc = 0;

    if ((dbh_active = check_connection_active(dbh)) == 0) return 0;

    rc = SQLAllocHandle(SQL_HANDLE_STMT, imp_dbh->hdbc, &imp_sth->hstmt);
    if (rc != SQL_SUCCESS) {
        dbd_error(sth, rc, "odbc_db_columns/SQLAllocHandle(stmt)");
        return 0;
    }

    if (SvOK(catalog)) acatalog = SvPV_nolen(catalog);
    if (SvOK(schema)) aschema = SvPV_nolen(schema);
    if (SvOK(table)) atable = SvPV_nolen(table);
    if (SvOK(column)) acolumn = SvPV_nolen(column);

    /* just for sanity, later.  Any internals that may rely on this (including */
    /* debugging) will have valid data */
    max_stmt_len = strlen(cSqlColumns)+
        strlen(XXSAFECHAR(acatalog))+
        strlen(XXSAFECHAR(aschema))+
        strlen(XXSAFECHAR(atable))+
        strlen(XXSAFECHAR(acolumn))+1;

    imp_sth->statement = (char *)safemalloc(max_stmt_len);

    my_snprintf(imp_sth->statement, max_stmt_len,
                cSqlColumns, XXSAFECHAR(acatalog), XXSAFECHAR(aschema),
                XXSAFECHAR(atable), XXSAFECHAR(acolumn));

#ifdef WITH_UNICODE
   {
       SQLWCHAR *wcatalog = NULL;
       SQLWCHAR *wschema = NULL;
       SQLWCHAR *wtable = NULL;
       SQLWCHAR *wcolumn = NULL;
       STRLEN wlen;
       SV *copy;

       if (SvOK(catalog)) {
           copy = sv_mortalcopy(catalog);
           SV_toWCHAR(copy);
           wcatalog = (SQLWCHAR *)SvPV(copy, wlen);
       }
       if (SvOK(schema)) {
           copy = sv_mortalcopy(schema);
           SV_toWCHAR(copy);
           wschema = (SQLWCHAR *)SvPV(copy, wlen);
       }
       if (SvOK(table)) {
           copy = sv_mortalcopy(table);
           SV_toWCHAR(copy);
           wtable = (SQLWCHAR *)SvPV(copy, wlen);
       }
       if (SvOK(column)) {
           copy = sv_mortalcopy(column);
           SV_toWCHAR(copy);
           wcolumn = (SQLWCHAR *)SvPV(copy, wlen);
       }
       rc = SQLColumnsW(imp_sth->hstmt,
			(wcatalog && *wcatalog) ? wcatalog : NULL, SQL_NTS,
			(wschema && *wschema) ? wschema : NULL, SQL_NTS,
			(wtable && *wtable) ? wtable : NULL, SQL_NTS,
			(wcolumn && *wcolumn) ? wcolumn : 0, SQL_NTS
                      );
   }
#else
   {
       rc = SQLColumns(imp_sth->hstmt,
		       (acatalog && *acatalog) ? acatalog : 0, SQL_NTS,
		       (aschema && *aschema) ? aschema : 0, SQL_NTS,
		       (atable && *atable) ? atable : 0, SQL_NTS,
		       (acolumn && *acolumn) ? acolumn : 0, SQL_NTS);
   }
#endif /* WITH_UNICODE */

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        PerlIO_printf(
            DBIc_LOGPIO(imp_dbh),
            "    SQLColumns call: cat = %s, schema = %s, table = %s, "
            "column = %s\n",
            XXSAFECHAR(acatalog), XXSAFECHAR(aschema), XXSAFECHAR(atable),
            XXSAFECHAR(acolumn));
    dbd_error(sth, rc, "odbc_columns/SQLColumns");

    if (!SQL_SUCCEEDED(rc)) {
        SQLFreeHandle(SQL_HANDLE_STMT,imp_sth->hstmt);
        imp_sth->hstmt = SQL_NULL_HSTMT;
        return 0;
    }
    return build_results(sth, imp_sth, dbh, imp_dbh, rc);
}



/*
 *  AllODBCErrors
 *  =============
 *
 *  Given ODBC environment, connection and statement handles (any of which may
 *  be null) this function will retrieve all ODBC errors recorded and
 *  optionally (if output is not 0) output them to the specified log handle.
 *
 */
static void AllODBCErrors(
    HENV henv, HDBC hdbc, HSTMT hstmt, int output, PerlIO *logfp)
{
    SQLRETURN rc;

    do {
        UCHAR sqlstate[SQL_SQLSTATE_SIZE+1];
        /* ErrorMsg must not be greater than SQL_MAX_MESSAGE_LENGTH */
        UCHAR ErrorMsg[SQL_MAX_MESSAGE_LENGTH];
        SWORD ErrorMsgLen;
        SDWORD NativeError;

        /* TBD: 3.0 update */
        rc=SQLError(henv, hdbc, hstmt,
                    sqlstate, &NativeError,
                    ErrorMsg, sizeof(ErrorMsg)-1, &ErrorMsgLen);

        if (output && SQL_SUCCEEDED(rc))
            PerlIO_printf(logfp, "%s %s\n", sqlstate, ErrorMsg);

    } while(SQL_SUCCEEDED(rc));
    return;
}



/************************************************************************/
/*                                                                      */
/*  check_connection_active                                             */
/*  =======================                                             */
/*                                                                      */
/************************************************************************/
static int check_connection_active(SV *h)
{
    D_imp_xxh(h);
    struct imp_dbh_st *imp_dbh = NULL;
    struct imp_sth_st *imp_sth = NULL;

    switch(DBIc_TYPE(imp_xxh)) {
      case DBIt_ST:
        imp_sth = (struct imp_sth_st *)imp_xxh;
        imp_dbh = (struct imp_dbh_st *)(DBIc_PARENT_COM(imp_sth));
        break;
      case DBIt_DB:
        imp_dbh = (struct imp_dbh_st *)imp_xxh;
        break;
      default:
        croak("panic: check_connection_active bad handle type");
    }

    if (!DBIc_ACTIVE(imp_dbh)) {
        DBIh_SET_ERR_CHAR(
            h, imp_xxh, Nullch, 1,
            "Cannot allocate statement when disconnected from the database",
            "08003", Nullch);
        return 0;
    }
    return 1;

}



/************************************************************************/
/*                                                                      */
/*  set_odbc_version                                                    */
/*  ================                                                    */
/*                                                                      */
/*  Set the ODBC version we require. This defaults to ODBC 3 but if     */
/*  attr contains the odbc_version atttribute this overrides it. If we  */
/*  fail for any reason the env handle is freed, the error reported and */
/*  0 is returned. If all ok, 1 is returned.                            */
/*                                                                      */
/************************************************************************/
static int set_odbc_version(
    SV *dbh,
    imp_dbh_t *imp_dbh,
    SV* attr)
{
    D_imp_drh_from_dbh;
    SV **svp;
    UV odbc_version = 0;
    SQLRETURN rc;


    DBD_ATTRIB_GET_IV(
        attr, "odbc_version", 12, svp, odbc_version);
    if (svp && odbc_version) {
        rc = SQLSetEnvAttr(imp_drh->henv, SQL_ATTR_ODBC_VERSION,
                           (SQLPOINTER)odbc_version, SQL_IS_INTEGER);
    } else {
        /* make sure we request a 3.0 version */
        rc = SQLSetEnvAttr(imp_drh->henv, SQL_ATTR_ODBC_VERSION,
                           (SQLPOINTER)SQL_OV_ODBC3, SQL_IS_INTEGER);
    }
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error2(
            dbh, rc, "db_login/SQLSetEnvAttr", imp_drh->henv, 0, 0);
        if (imp_drh->connects == 0) {
            SQLFreeHandle(SQL_HANDLE_ENV, imp_drh->henv);
            imp_drh->henv = SQL_NULL_HENV;
        }
        return 0;
    }
    return 1;
}



/*
 *  post_connect
 *  ==========
 *
 *  Operations to perform immediately after we have connected.
 *
 *  NOTE: prior to DBI subversion version 11605 (fixed post 1.607)
 *    DBD_ATTRIB_DELETE segfaulted so instead of calling:
 *    DBD_ATTRIB_DELETE(attr, "odbc_cursortype",
 *                      strlen("odbc_cursortype"));
 *    we do the following:
 *      hv_delete((HV*)SvRV(attr), "odbc_cursortype",
 *                strlen("odbc_cursortype"), G_DISCARD);
 */

static int post_connect(
    SV *dbh,
    imp_dbh_t *imp_dbh,
    SV *attr)
{
    D_imp_drh_from_dbh;
    SQLRETURN rc;
    SWORD dbvlen;
    UWORD supported;

    /* default this now before we may change it below */
    imp_dbh->switch_to_longvarchar = ODBC_SWITCH_TO_LONGVARCHAR;

    if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
        TRACE0(imp_dbh, "Turning autocommit on\n");

    /* DBI spec requires AutoCommit on */
    rc = SQLSetConnectAttr(imp_dbh->hdbc, SQL_AUTOCOMMIT,
                           (SQLPOINTER)SQL_AUTOCOMMIT_ON, 0);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(dbh, rc, "post_connect/SQLSetConnectAttr(SQL_AUTOCOMMIT)");
        SQLFreeHandle(SQL_HANDLE_DBC, imp_dbh->hdbc);
        if (imp_drh->connects == 0) {
            SQLFreeHandle(SQL_HANDLE_ENV, imp_drh->henv);
            imp_drh->henv = SQL_NULL_HENV;
            imp_dbh->henv = SQL_NULL_HENV;    /* needed for dbd_error */
        }
        return 0;
    }
    DBIc_set(imp_dbh,DBIcf_AutoCommit, 1);

    /* get the ODBC compatibility level for this driver */
    rc = SQLGetInfo(imp_dbh->hdbc, SQL_DRIVER_ODBC_VER, &imp_dbh->odbc_ver,
                    (SWORD)sizeof(imp_dbh->odbc_ver), &dbvlen);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(dbh, rc, "post_connect/SQLGetInfo(DRIVER_ODBC_VER)");
        strcpy(imp_dbh->odbc_ver, "01.00");
    }
    if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
        TRACE1(imp_dbh, "DRIVER_ODBC_VER = %s\n", imp_dbh->odbc_ver);

    /* get ODBC driver name and version */
    rc = SQLGetInfo(imp_dbh->hdbc, SQL_DRIVER_NAME, &imp_dbh->odbc_driver_name,
                    (SQLSMALLINT)sizeof(imp_dbh->odbc_driver_name), &dbvlen);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(dbh, rc, "post_connect/SQLGetInfo(DRIVER_NAME)");
        strcpy(imp_dbh->odbc_driver_name, "unknown");
        imp_dbh->driver_type = DT_DONT_CARE;
    } else {
        if (strcmp(imp_dbh->odbc_driver_name, "SQLSRV32.DLL") == 0) {
            imp_dbh->driver_type = DT_SQL_SERVER;
        } else if ((strcmp(imp_dbh->odbc_driver_name, "sqlncli10.dll") == 0) ||
                   (strcmp(imp_dbh->odbc_driver_name, "SQLNCLI.DLL") == 0) ||
                   (memcmp(imp_dbh->odbc_driver_name, "libmsodbcsql", 13) == 0)) {
            imp_dbh->driver_type = DT_SQL_SERVER_NATIVE_CLIENT;
        } else if (strcmp(imp_dbh->odbc_driver_name, "odbcjt32.dll") == 0) {
            imp_dbh->driver_type = DT_MS_ACCESS_JET;
            imp_dbh->switch_to_longvarchar = 255;
        } else if (strcmp(imp_dbh->odbc_driver_name, "ACEODBC.DLL") == 0) {
            imp_dbh->driver_type = DT_MS_ACCESS_ACE;
            imp_dbh->switch_to_longvarchar = 255;
        } else if (strcmp(imp_dbh->odbc_driver_name, "esoobclient") == 0) {
            imp_dbh->driver_type = DT_ES_OOB;
        } else if (strcmp(imp_dbh->odbc_driver_name, "OdbcFb") == 0) {
            imp_dbh->driver_type = DT_FIREBIRD;
        } else if (memcmp(imp_dbh->odbc_driver_name, "libtdsodbc", 10) == 0) {
            imp_dbh->driver_type = DT_FREETDS;
        } else {
            imp_dbh->driver_type = DT_DONT_CARE;
        }
    }

    if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
        TRACE2(imp_dbh, "DRIVER_NAME = %s, type=%d\n",
               imp_dbh->odbc_driver_name, imp_dbh->driver_type);

    rc = SQLGetInfo(imp_dbh->hdbc, SQL_DRIVER_VER,
                    &imp_dbh->odbc_driver_version,
                    (SQLSMALLINT)sizeof(imp_dbh->odbc_driver_version), &dbvlen);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(dbh, rc, "post_connect/SQLGetInfo(DRIVER_VERSION)");
        strcpy(imp_dbh->odbc_driver_name, "unknown");
    }
    if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
        TRACE1(imp_dbh, "DRIVER_VERSION = %s\n", imp_dbh->odbc_driver_version);

    rc = SQLGetInfo(imp_dbh->hdbc, SQL_DBMS_NAME, &imp_dbh->odbc_dbms_name,
                    (SQLSMALLINT)sizeof(imp_dbh->odbc_dbms_name), &dbvlen);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(dbh, rc, "post_connect/SQLGetInfo(SQL_DBMS_NAME)");
        strcpy(imp_dbh->odbc_dbms_name, "unknown");
    }

    rc = SQLGetInfo(imp_dbh->hdbc, SQL_DBMS_VER, &imp_dbh->odbc_dbms_version,
                    (SQLSMALLINT)sizeof(imp_dbh->odbc_dbms_version), &dbvlen);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(dbh, rc, "post_connect/SQLGetInfo(SQL_DBMS_VER)");
        strcpy(imp_dbh->odbc_dbms_version, "unknown");
    }

    /* find maximum column name length */
    rc = SQLGetInfo(imp_dbh->hdbc, SQL_MAX_COLUMN_NAME_LEN,
                    &imp_dbh->max_column_name_len,
                    (SWORD) sizeof(imp_dbh->max_column_name_len), &dbvlen);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(dbh, rc, "post_connect/SQLGetInfo(MAX_COLUMN_NAME_LEN)");
        imp_dbh->max_column_name_len = 256;
    } else if (imp_dbh->max_column_name_len == 0) {
        imp_dbh->max_column_name_len = 256;
    } else {
        if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
            TRACE1(imp_dbh, "MAX_COLUMN_NAME_LEN = %d\n",
                   imp_dbh->max_column_name_len);
    }

    /* find catalog usage */
    {
        char yesno[10];

        rc = SQLGetInfo(imp_dbh->hdbc, SQL_CATALOG_NAME,
                        yesno,
                        (SQLSMALLINT) sizeof(yesno), &dbvlen);
        if (!SQL_SUCCEEDED(rc)) {
            dbd_error(dbh, rc, "post_connect/SQLGetInfo(SQL_CATALOG_NAME)");
            imp_dbh->catalogs_supported = 0;
        } else if (yesno[0] == 'Y') {
            imp_dbh->catalogs_supported = 1;
        } else {
            imp_dbh->catalogs_supported = 0;
        }
        if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
            TRACE1(imp_dbh, "SQL_CATALOG_NAME = %d\n",
                       imp_dbh->catalogs_supported);
    }

    /* find schema usage */
    {
        rc = SQLGetInfo(imp_dbh->hdbc, SQL_SCHEMA_USAGE,
                        &imp_dbh->schema_usage,
                        (SQLSMALLINT) sizeof(imp_dbh->schema_usage), &dbvlen);
        if (!SQL_SUCCEEDED(rc)) {
            dbd_error(dbh, rc, "post_connect/SQLGetInfo(SQL_SCHEMA_USAGE)");
            imp_dbh->schema_usage = 0;
        }
        if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
            TRACE1(imp_dbh, "SQL_SCHEMA_USAGE = %lu\n",
                   (unsigned long)imp_dbh->schema_usage);
    }

#ifdef WITH_UNICODE
    imp_dbh->max_column_name_len = imp_dbh->max_column_name_len *
        sizeof(SQLWCHAR) + 2;
#endif
    if (imp_dbh->max_column_name_len > 512) {
        imp_dbh->max_column_name_len = 512;
        DBIh_SET_ERR_CHAR(
            dbh, (imp_xxh_t*)imp_drh, "0", 1,
            "Max column name length pegged at 512", Nullch, Nullch);
    }

    /* default ignoring named parameters and array operations to false */
    imp_dbh->odbc_ignore_named_placeholders = 0;
    imp_dbh->odbc_array_operations = 0;

#ifdef DEFAULT_IS_OFF_NOW_SO_THIS_IS_NOT_REQUIRED
    /* Disable array operations by default for some drivers as no version
       I've ever seen works and it annoys the dbix-class guys */
    if (imp_dbh->driver_type == DT_FREETDS ||
        imp_dbh->driver_type == DT_MS_ACCESS_JET ||
        imp_dbh->driver_type == DT_MS_ACCESS_ACE) {
        imp_dbh->odbc_array_operations = 0;
    }
#endif

#ifdef WITH_UNICODE
    imp_dbh->odbc_has_unicode = 1;
#else
    imp_dbh->odbc_has_unicode = 0;
#endif

    if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
        TRACE1(imp_dbh, "DBD::ODBC is unicode built : %s\n",
               imp_dbh->odbc_has_unicode ? "YES" : "NO");

    imp_dbh->odbc_default_bind_type = 0;
    imp_dbh->odbc_force_bind_type = 0;
#ifdef SQL_ROWSET_SIZE_DEFAULT
    imp_dbh->rowset_size = SQL_ROWSET_SIZE_DEFAULT;
#else
    /* it should be 1 anyway so above should be redundant but included
       here partly to remind me what it is */
    imp_dbh->rowset_size = 1;
#endif

    /* flag to see if SQLDescribeParam is supported */
    imp_dbh->odbc_sqldescribeparam_supported = -1;
    /* flag to see if SQLDescribeParam is supported */
    imp_dbh->odbc_sqlmoreresults_supported = -1;
    imp_dbh->odbc_defer_binding = 0;
    imp_dbh->odbc_force_rebind = 0;
    /* default value for query timeout is -1 which means do not set the
       query timeout at all. */
    imp_dbh->odbc_query_timeout = -1;
    imp_dbh->odbc_putdata_start = 32768;
    imp_dbh->odbc_batch_size = 10;
    imp_dbh->read_only = -1;                    /* show not set yet */

    /*printf("odbc_batch_size defaulted to %d\n", imp_dbh->odbc_batch_size);*/
    imp_dbh->odbc_column_display_size = 2001;
    imp_dbh->odbc_utf8_on = 0;
    imp_dbh->odbc_exec_direct = 0; /* default to not having SQLExecDirect used */
    imp_dbh->odbc_describe_parameters = 1;
    imp_dbh->RowCacheSize = 1;	/* default value for now */

#ifdef WE_DONT_DO_THIS_ANYMORE
    if (!strcmp(imp_dbh->odbc_dbms_name, "Microsoft SQL Server")) {
        if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
            TRACE0(imp_dbh, "Deferring Binding\n");
        imp_dbh->odbc_defer_binding = 1;
    }
#endif

    /* check to see if SQLMoreResults is supported */
    rc = SQLGetFunctions(imp_dbh->hdbc, SQL_API_SQLMORERESULTS, &supported);
    if (SQL_SUCCEEDED(rc)) {
        if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
            TRACE1(imp_dbh, "SQLMoreResults supported: %d\n", supported);
        imp_dbh->odbc_sqlmoreresults_supported = supported ? 1 : 0;
    } else {
        imp_dbh->odbc_sqlmoreresults_supported = 0;
        if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
            TRACE0(imp_dbh,
                   "    !!SQLGetFunctions(SQL_API_SQLMORERESULTS) failed:\n");
        AllODBCErrors(imp_dbh->henv, imp_dbh->hdbc, 0,
                      DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3), DBIc_LOGPIO(imp_dbh));
    }

    /* call only once per connection / DBH -- may want to do
     * this during the connect to avoid potential threading
     * issues */
    /* check to see if SQLDescribeParam is supported */
    rc = SQLGetFunctions(imp_dbh->hdbc, SQL_API_SQLDESCRIBEPARAM, &supported);
    if (SQL_SUCCEEDED(rc)) {
        if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
            TRACE1(imp_dbh, "SQLDescribeParam supported: %d\n", supported);
        imp_dbh->odbc_sqldescribeparam_supported = supported ? 1 : 0;
    } else {
        imp_dbh->odbc_sqldescribeparam_supported = 0;
        if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
            TRACE0(imp_dbh,
                   "    !!SQLGetFunctions(SQL_API_SQLDESCRIBEPARAM) failed:\n");
        AllODBCErrors(imp_dbh->henv, imp_dbh->hdbc, 0,
                      DBIc_TRACE(imp_dbh, DBD_TRACING, 0, 3),
                      DBIc_LOGPIO(imp_dbh));
    }

    /* odbc_cursortype */
    {
        SV **svp;
        UV odbc_cursortype = 0;

        DBD_ATTRIB_GET_IV(attr, "odbc_cursortype", 15,
                          svp, odbc_cursortype);
        if (svp && odbc_cursortype) {
            if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
                TRACE1(imp_dbh,
                       "    Setting cursor type to: %"UVuf"\n", odbc_cursortype);
            /* delete odbc_cursortype so we don't see it again via STORE */
            (void)hv_delete((HV*)SvRV(attr), "odbc_cursortype",
                            strlen("odbc_cursortype"), G_DISCARD);

            rc = SQLSetConnectAttr(imp_dbh->hdbc,(SQLINTEGER)SQL_CURSOR_TYPE,
                                   (SQLPOINTER)odbc_cursortype,
                                   (SQLINTEGER)SQL_IS_INTEGER);
            if (!SQL_SUCCEEDED(rc) && (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0)))
                TRACE1(imp_dbh, "    !!Failed to set SQL_CURSORTYPE to %d\n",
                       (int)odbc_cursortype);
        }
    }

    /* odbc_query_timeout */
    {
        SV **svp;
        UV   odbc_timeout = 0;

        DBD_ATTRIB_GET_IV(
            attr, "odbc_query_timeout", strlen("odbc_query_timeout"),
            svp, odbc_timeout);
        if (svp && odbc_timeout) {
            imp_dbh->odbc_query_timeout = odbc_timeout;
            if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
                TRACE1(imp_dbh, "    Setting DBH query timeout to %d\n",
                       (int)odbc_timeout);
            /* delete odbc_cursortype so we don't see it again via STORE */
            (void)hv_delete((HV*)SvRV(attr), "odbc_query_timeout",
                            strlen("odbc_query_timeout"), G_DISCARD);
        }
    }

    /* odbc_putdata_start */
    {
        SV **svp;
        IV putdata_start_value;

        DBD_ATTRIB_GET_IV(
            attr, "odbc_putdata_start", strlen("odbc_putdata_start"),
            svp, putdata_start_value);
        if (svp) {
            imp_dbh->odbc_putdata_start = putdata_start_value;
            if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
                TRACE1(imp_dbh, "    Setting DBH putdata_start to %d\n",
                       (int)putdata_start_value);
            /* delete odbc_putdata_start so we don't see it again via STORE */
            (void)hv_delete((HV*)SvRV(attr), "odbc_putdata_start",
                            strlen("odbc_putdata_start"), G_DISCARD);
        }
    }

    /* odbc_column_display_size */
    {
        SV **svp;
        IV column_display_size_value;

        DBD_ATTRIB_GET_IV(
            attr, "odbc_column_display_size",
            strlen("odbc_column_display_size"),
            svp, column_display_size_value);
        if (svp) {
            imp_dbh->odbc_column_display_size = column_display_size_value;
            if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
                TRACE1(imp_dbh,
                       "    Setting DBH default column display size to %d\n",
                       (int)column_display_size_value);
            /* delete odbc_column_display_size so we don't see it again via STORE */
            (void)hv_delete((HV*)SvRV(attr), "odbc_column_display_size",
                            strlen("odbc_column_display_size"), G_DISCARD);
        }
    }

    /* odbc_utf8_on */
    {
        SV **svp;
        IV column_display_size_value;

        DBD_ATTRIB_GET_IV(
            attr, "odbc_utf8_on",
            strlen("odbc_utf8_on"),
            svp, column_display_size_value);
        if (svp) {
            imp_dbh->odbc_utf8_on = 0;
            if (DBIc_TRACE(imp_dbh, CONNECTION_TRACING, 0, 0))
                TRACE1(imp_dbh,
                       "    Setting UTF8_ON to %d\n",
                       (int)column_display_size_value);
            /* delete odbc_utf8_on so we don't see it again via STORE */
            (void)hv_delete((HV*)SvRV(attr), "odbc_utf8_on",
                            strlen("odbc_utf8_on"), G_DISCARD);
        }
    }

    return 1;
}



/*
 * Called when we don't know what to bind a parameter as. This can happen for all sorts
 * of reasons like:
 *
 * o SQLDescribeParam is not supported
 * o odbc_describe_parameters is set to 0 (in other words telling us not to describe)
 * o SQLDescribeParam was called and failed
 * o SQLDescribeParam was called but returned an unrecognised parameter type
 *
 * If the data to bind is unicode (SvUTF8 is true) it is bound as SQL_WCHAR
 * or SQL_WLONGVARCHAR depending on its size. Otherwise it is bound as
 * SQL_VARCHAR/SQL_LONGVARCHAR.
 */
static SQLSMALLINT default_parameter_type(
    char *why, imp_sth_t *imp_sth, phs_t *phs)
{
    SQLSMALLINT sql_type;
    struct imp_dbh_st *imp_dbh = NULL;
    imp_dbh = (struct imp_dbh_st *)(DBIc_PARENT_COM(imp_sth));

    if (imp_sth->odbc_default_bind_type != 0) {
        sql_type = imp_sth->odbc_default_bind_type;
    } else {
        /* MS Access can return an invalid precision error in the 12blob
           test unless the large value is bound as an SQL_LONGVARCHAR
           or SQL_WLONGVARCHAR. Who knows what large is, but for now it is
           4000 */
        /*
          Changed to 2000 for the varchar max switch as in a unicode build we
          can change a string of 'x' x 2001 into 4002 wide chrs and SQL Server
          will also return invalid precision in this case on a varchar(4000).
          Of course, being SQL Server, it also has this problem with the
          newer varchar(8000)! */
        if (!SvOK(phs->sv)) {
	  sql_type = ODBC_BACKUP_BIND_TYPE_VALUE;
           if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
               TRACE2(imp_sth, "%s, sv is not OK, defaulting to %d\n",
                      why, sql_type);
        } else if (SvCUR(phs->sv) > imp_dbh->switch_to_longvarchar) {
#if defined(WITH_UNICODE)
	   if (SvUTF8(phs->sv))
	     sql_type = SQL_WLONGVARCHAR;
	   else
#endif
	     sql_type = SQL_LONGVARCHAR;
           if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
               TRACE3(imp_sth, "%s, sv=%"UVuf" bytes, defaulting to %d\n",
                      why, (UV)SvCUR(phs->sv), sql_type);
        } else {
#if defined(WITH_UNICODE)
	   if (SvUTF8(phs->sv))
	     sql_type = SQL_WVARCHAR;
	   else
#endif
	     sql_type = SQL_VARCHAR;
	   /*return ODBC_BACKUP_BIND_TYPE_VALUE;*/
           if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
               TRACE3(imp_sth, "%s, sv=%"UVuf" bytes, defaulting to %d\n",
                      why, (UV)SvCUR(phs->sv), sql_type);
        }
    }
    return sql_type;
}



#ifdef WIN32
static   HWND GetConsoleHwnd(void)
{
#define MY_BUFSIZE 1024 /* Buffer size for console window titles. */
  HWND hwndFound;         /* This is what is returned to the caller. */
  char pszNewWindowTitle[MY_BUFSIZE]; /* Contains fabricated WindowTitle. */
  char pszOldWindowTitle[MY_BUFSIZE]; /* Contains original  WindowTitle */

  /* Fetch current window title. */
  GetConsoleTitle(pszOldWindowTitle, MY_BUFSIZE);

  /* Format a "unique" NewWindowTitle. */
  wsprintf(pszNewWindowTitle,"%d/%d",
	   GetTickCount(),
	   GetCurrentProcessId());

  /* Change current window title. */
  SetConsoleTitle(pszNewWindowTitle);

  /* Ensure window title has been updated. */
  Sleep(40);

  /* Look for NewWindowTitle. */
  hwndFound=FindWindow(NULL, pszNewWindowTitle);

  /* Restore original window title. */
  SetConsoleTitle(pszOldWindowTitle);

  return(hwndFound);
}
#endif	/* WIN32 */

/*
 *  new odbc_rows statement method to workaround RT 81911 in DBI
 *  Just return the last RowCount value suitably mangled like execute does
 *  but without casting to int problem.
 */
IV odbc_st_rowcount(
    SV *sth)
{
    D_imp_sth(sth);
/*    SQLLEN rows;
      SQLRETURN rc;*/

    return imp_sth->RowCount;
    /*
    rc = SQLRowCount(imp_sth->hstmt, &rows);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_st_rowcount");
        return -1;
        }
        return rows;*/
}

/* TO_DO:
 * bind_param can be called with no target parameter but to set the parameter type
 *   and it is supposed to be sticky - it is not here.
 * we don't free up memory allocated
 * I've no idea what will happen with lobs - probably won't work or will be set
 *   as hex strings (depends on driver mapping of SQL_CHAR to binary columns)
 */
IV odbc_st_execute_for_fetch(
    SV *sth,
    SV *tuples,			/* the actual data to bind */
    IV count,			/* count of rows */
    SV *tuple_status)		/* returned tuple status */
{
    D_imp_sth(sth);
    D_imp_dbh_from_sth;
    SQLRETURN rc;
    AV *tuples_av, *tuples_status_av; /* array ptrs for tuples and tuple_status */
    unsigned int p;		      /* for loop through parameters */
    unsigned long *maxlen;	/* array to store max size of each param */
    int n_params;		/* number of parameters */
    unsigned int row;
    int err_seen = 0;		/* some row errored */
    int remalloc_svs = 0;	/* remalloc the phs sv arrays */

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        TRACE2(imp_sth, "    +dbd_st_execute_for_fetch(%p) count=%"IVdf"\n",
               sth, count);

    if (SQL_NULL_HDBC == imp_dbh->hdbc) {
        DBIh_SET_ERR_CHAR(sth, (imp_xxh_t*)imp_sth, Nullch, 1,
                          "Database handle has been disconnected",
                          Nullch, Nullch);
        return -2;
    }

    /* Check that the `tuples' parameter is an array ref */
    if(!SvROK(tuples) || SvTYPE(SvRV(tuples)) != SVt_PVAV) {
        croak("odbc_st_execute_for_fetch(): Not an array reference.");
    }
    tuples_av = (AV*)SvRV(tuples);

    /* Check the `tuples_status' parameter. */
    if(SvTRUE(tuple_status)) {
        if(!SvROK(tuple_status) || SvTYPE(SvRV(tuple_status)) != SVt_PVAV) {
            croak("odbc_st_execute_for_fetch(): tuples_status not an array reference.");
        }
        tuples_status_av = (AV*)SvRV(tuple_status);
        av_fill(tuples_status_av, count - 1);

    } else {
        tuples_status_av = NULL;
    }

    /* Nothing to do if no tuples. */
    if (count <= 0) return 0;

    /*
     * if the handle is active, we need to finish it here.
     * Note that dbd_st_finish already checks to see if it's active.
     */
    dbd_st_finish(sth, imp_sth);;
    rc = SQLFreeStmt(imp_sth->hstmt, SQL_RESET_PARAMS);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_st_execute_for_fetch/SQL_RESET_PARAMS");
        return -2;
    }

    if (!imp_sth->all_params_hv) {
        croak("No parameter hash");
    }

    /* set bind type, parameter set size and parameters processed */
    rc = SQLSetStmtAttr(imp_sth->hstmt, SQL_ATTR_PARAM_BIND_TYPE,
                        (SQLPOINTER)SQL_PARAM_BIND_BY_COLUMN, 0);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_st_execute_for_fetch/SQL_ATTR_PARAM_BIND_TYPE");
        return -2;
    }

    n_params = (int)HvKEYS(imp_sth->all_params_hv);
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        TRACE1(imp_sth, "    num params=%d\n", n_params);

    /* if count increased free up last param status array */
    if (count > imp_sth->allocated_batch_size) {
        remalloc_svs = 1;	/* remalloc strlen_or_ind_array */
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
            TRACE0(imp_sth, "    remallocing sv arrays\n");
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
            TRACE3(imp_sth, "    count increased from %d to %"IVdf" psa=%p\n",
                   imp_sth->allocated_batch_size, count, imp_sth->param_status_array);

        if (imp_sth->param_status_array) {
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
                TRACE0(imp_sth, "    freeing previous parameter status array\n");

            Safefree(imp_sth->param_status_array);
            imp_sth->param_status_array = NULL;
        }
    }

    /*
     * Set up the parameter status array
     */
    if (!imp_sth->param_status_array) {
        unsigned int i;
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
            TRACE1(imp_sth, "    allocating parameter status array for %"IVdf" rows\n",
                   count);
        imp_sth->param_status_array =
            (SQLUSMALLINT *)safemalloc(count * sizeof(SQLUSMALLINT));
	/* fill the parameter status array with invalid values so we can
	   see if the driver writes them - some don't in some circumstances */
	for (i = 0; i < count; i++) {
	  imp_sth->param_status_array[i] = 9999;
	}
        imp_sth->allocated_batch_size = count;
    }

    /* Calc max size of each parameter */
    maxlen = (unsigned long *)safemalloc(n_params * sizeof(unsigned long));
    for (p = 0; p < n_params; p++) {
        maxlen[p] = 0;
    }
    for (row = 0; row < count; row++) {
        SV **sv_p;
        SV *sv;
        AV *av;

        if (SvTRUE(tuple_status)){
            av_store(tuples_status_av, row, newSViv((IV)-1)); /* don't know count */
        }
        sv_p = av_fetch(tuples_av, row, 0);
        if(sv_p == NULL) {
            Safefree(maxlen);
            croak("Cannot fetch tuple %d", row);
        }
        sv = *sv_p;
        if(!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV) {
            Safefree(maxlen);
            croak("Not an array ref in element %d", row);
        }
        av = (AV*)SvRV(sv);

        for (p = 1; p <= n_params; p++) {
            STRLEN sv_len;

            sv_p = av_fetch(av, p-1, 0);
            if(sv_p == NULL) {
                Safefree(maxlen);
                croak("Cannot fetch value for param %d in row %d", p, row);
            }
            sv = *sv_p;
            /*check to see if value sv is a null (undef) if it is upgrade it*/
            if (!SvOK(sv))	{
                (void)SvUPGRADE(sv, SVt_PV);
            }
            else {
                (void)SvPV(sv, sv_len);
                if ((sv_len + 1) > maxlen[p-1]) {
                    maxlen[p-1] = sv_len + 1;
                }
            }
        }
    }
    for (p = 1; p <= n_params; p++) {
        char name[32];
        SV **phs_svp;
        phs_t *phs;

        sprintf(name, "%u", p);

        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
            TRACE2(imp_sth, "    Max size of p%d = %lu\n", p-1, maxlen[p-1]);

        phs_svp = hv_fetch(imp_sth->all_params_hv, name, strlen(name), 0);
        if (phs_svp == NULL) {
            /* TO_DO */
            abort();
        }
        phs = (phs_t*)(void*)SvPVX(*phs_svp);

        if (maxlen[p-1] > 0) {
            if (phs->param_array_buf) Safefree(phs->param_array_buf);
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
                TRACE3(imp_sth, "    allocating %ld * rows=%"IVdf" for p%u\n",
                       maxlen[p-1], count, p);
#if defined(WITH_UNICODE)
            phs->param_array_buf =
	      (char *)safemalloc(maxlen[p-1] * count * sizeof(SQLWCHAR));
#else
            phs->param_array_buf = (char *)safemalloc(maxlen[p-1] * count);
#endif
        } else {
            phs->param_array_buf = NULL;
        }
        if (remalloc_svs) {
            if (phs->strlen_or_ind_array) {
                if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
                    TRACE1(imp_sth, "    freeing ind array for p%d\n", p);

                Safefree(phs->strlen_or_ind_array);
                phs->strlen_or_ind_array = NULL;
            }
        }
        if (!phs->strlen_or_ind_array) {
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
                TRACE2(imp_sth, "    allocating %"IVdf" for p%u ind array\n",
                       count * sizeof(SQLULEN), p);
            phs->strlen_or_ind_array = (SQLLEN *)safemalloc(count * 2 * sizeof(SQLLEN));
        }
        get_param_type(sth, imp_sth, imp_dbh, phs);
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
            PerlIO_printf(DBIc_LOGPIO(imp_sth),
                          "    PARAM name=%s sv=%p idx=%u vt=%d (%s) svt=%d (%s) buf=%p ps=%lu dpc=%d dps=%d ml=%"IVdf" dst=%d\n",
                          phs->name, phs->sv, phs->idx, phs->value_type,
                          S_SqlCTypeToString(phs->value_type),
                          phs->sql_type, S_SqlTypeToString(phs->sql_type),
                          phs->param_array_buf, phs->param_size,
                          phs->describe_param_called, phs->describe_param_status,
                          phs->maxlen, phs->described_sql_type);
#if defined(WITH_UNICODE)
        rc = SQLBindParameter(imp_sth->hstmt,
                              p, SQL_PARAM_INPUT, SQL_C_WCHAR,
                              phs->sql_type, maxlen[p-1], 0,
                              phs->param_array_buf, maxlen[p-1] * sizeof(SQLWCHAR),
                              phs->strlen_or_ind_array);
#else
        rc = SQLBindParameter(imp_sth->hstmt,
                              p, SQL_PARAM_INPUT, SQL_C_CHAR,
                              phs->sql_type, maxlen[p-1], 0,
                              phs->param_array_buf, maxlen[p-1],
                              phs->strlen_or_ind_array);
#endif
        if (!SQL_SUCCEEDED(rc)) {
            Safefree(maxlen);
            dbd_error(sth, rc, "odbc_st_execute_for_fetch/SQLBindParameter");
            return -2;
        }
    }

    for (row = 0; row < count; row++) {
        SV **sv_p;
        SV *sv;
        AV *av;

        sv_p = av_fetch(tuples_av, row, 0);
        sv = *sv_p;
        av = (AV*)SvRV(sv);

        for (p = 1; p <= n_params; p++) {
            char name[32];
            SV **phs_svp;
            phs_t *phs;
            STRLEN sv_len;
            char *sv_val;

            sprintf(name, "%u", p);

            phs_svp = hv_fetch(imp_sth->all_params_hv, name, strlen(name), 0);
            if (phs_svp == NULL) {
                abort();
            }
            phs = (phs_t*)(void*)SvPVX(*phs_svp);
            sv_p = av_fetch(av, phs->idx - 1, 0);
            if(sv_p == NULL) {
                Safefree(maxlen);
                croak("Cannot fetch value for param %d in row %d", p, row);
            }
            sv = *sv_p;
            /*check to see if value sv is a null (undef) if it is upgrade it*/
            if (!SvOK(sv))	{
                (void)SvUPGRADE(sv, SVt_PV);
                phs->strlen_or_ind_array[row] = SQL_NULL_DATA;
            }
            else {
#if defined(WITH_UNICODE)
                SV_toWCHAR(sv);
                sv_val = SvPV(sv, sv_len);
                memcpy((char *)(phs->param_array_buf + (row * maxlen[p-1] * sizeof(SQLWCHAR))),
                       sv_val, sv_len);
                phs->strlen_or_ind_array[row] = sv_len;
#else
                sv_val = SvPV(sv, sv_len);
                phs->strlen_or_ind_array[row] = SQL_NTS /*strlen(sv_val)*/;
                strcpy((char *)(phs->param_array_buf + (row * maxlen[p-1])), sv_val);
#endif
            }
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
                PerlIO_printf(DBIc_LOGPIO(imp_sth),
                              "    row=%d p%d ind=%ld /%s/\n",
                              row, p, phs->strlen_or_ind_array[row], phs->param_array_buf + (row * maxlen[p-1]) );
            if(SvROK(sv)) {
                Safefree(maxlen);
                croak("Can't bind a reference (%s) for param %d, row %d",
                      neatsvpv(sv,0), p, row);
            }
        }
    }
    if (maxlen) Safefree(maxlen);
    maxlen = NULL;

    /* We do this as late as possible as we don't want to leave
     * paramset size set in the statement in case the Perl code does
     * some other parameter binding without execute_array. */
    rc = SQLSetStmtAttr(imp_sth->hstmt, SQL_ATTR_PARAMSET_SIZE,
                        (SQLPOINTER)count, 0);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_st_execute_for_fetch/SQL_ATTR_PARAMSET_SIZE");
        return -2;
    }
    rc = SQLSetStmtAttr(imp_sth->hstmt, SQL_ATTR_PARAMS_PROCESSED_PTR,
                        (SQLPOINTER)&imp_sth->params_processed, 0);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_st_execute_for_fetch/SQL_ATTR_PARAMS_PROCESSED_PTR");
        return -2;
    }
    rc = SQLSetStmtAttr(imp_sth->hstmt, SQL_ATTR_PARAM_STATUS_PTR,
                        (SQLPOINTER)imp_sth->param_status_array, 0);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_st_execute_for_fetch/SQL_ATTR_PARAM_STATUS_PTR");
        return -2;
    }

    rc = SQLExecute(imp_sth->hstmt);
    /* SQLExecute may fail with SQL_ERROR in which case we have a serious
     * problem but usually it fails for a row of parameters with
     * SQL_SUCCESS_WITH_INFO - in the latter case the parameter status
     * array will indicate and error for this row and we'll pick it up later */
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
      TRACE1(imp_sth, "    SQLExecute=%d\n", rc);
    if (!SQL_SUCCEEDED(rc)) {
        dbd_error(sth, rc, "odbc_st_execute_for_fetch/SQLExecute");
        /* reset paramset size and params processed */
        SQLSetStmtAttr(imp_sth->hstmt, SQL_ATTR_PARAMS_PROCESSED_PTR,
                       (SQLPOINTER)NULL, 0);
        SQLSetStmtAttr(imp_sth->hstmt, SQL_ATTR_PARAMSET_SIZE,
                       (SQLPOINTER)1, 0);
        SQLSetStmtAttr(imp_sth->hstmt, SQL_ATTR_PARAM_STATUS_PTR,
                       (SQLPOINTER)NULL, 0);
        return -2;
    } else if (rc == SQL_SUCCESS_WITH_INFO) {
        dbd_error(sth, rc, "odbc_st_execute_for_fetch/SQLExecute");
    }

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 4))
        TRACE1(imp_sth, "    params processed = %lu\n",
               imp_sth->params_processed);

    {
        unsigned int row;
        char sqlstate[SQL_SQLSTATE_SIZE+1];
        SQLINTEGER native;
        char msg[256];

        /* NOTE, DBI says we fill tuple_status for each row with what execute
           returns - i.e., row count. It makes more sense for ODBC to fill
           it with the values in SQL_ATTR_PARAM_STATUS_PTR which are:
           SQL_PARAM_SUCCESS, SQL_PARAM_SUCCESS_WITH_INFO, SQL_PARAM_ERROR,
           SQL_PARAM_UNUSED, SQL_PARAM_IGNORE - but we do what DBI says */
        /* Don't step beyond Params Processed as if the driver says it has
           processed N rows and we step past N, the values could be rubbish -
           the driver probably hasn't even written them. In particular, if
           we look at param status array after params processed the values
           will probably be junk (randon values in the malloced data) and it
           will lead us to think they are not successful - assuming they are
           not 0 = SQL_PARAM_SUCCESS */
        for (row = 0; row < count; row++) {
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
                TRACE2(imp_sth, "    row %d, parameter status = %u\n",
                       row, imp_sth->param_status_array[row]);
            if (imp_sth->params_processed <= row) {
                /* parameter was not processed so no point in looking at parameter
                   status array */
                av_store(tuples_status_av, row,
                         newSViv((IV) -1));
            } else if (imp_sth->param_status_array[row] == 9999) {
                SV *err_svs[3];
                if (SvTRUE(tuple_status)){
                    err_svs[0] = newSViv((IV)1);
                    err_svs[1] = newSVpv("warning: parameter status was not returned", 0);
                    err_svs[2] = newSVpv("HY000", 0);

                    av_store(tuples_status_av, row,
                             newRV_noinc((SV *)(av_make(3, err_svs))));
                }
                DBIh_SET_ERR_SV(sth, (imp_xxh_t*)imp_sth, newSVpv("",0), err_svs[1],
                                err_svs[2], &PL_sv_undef);

            } else if ((imp_sth->param_status_array[row] == SQL_PARAM_SUCCESS) ||
                       (imp_sth->param_status_array[row] == SQL_PARAM_UNUSED) ||
                       (imp_sth->param_status_array[row] == SQL_PARAM_DIAG_UNAVAILABLE)) {
                /* We'll never get SQL_PARAM_IGNORE as we never set a row operations array */
                /* Some drivers which do SQL_PARC_NO_BATCH will set
                   SQL_PARAM_DIAG_UNAVAILABLE for every row as they cannot tell
                   us on a per row basis. Treat these as success as they are since
                   the call the SQLExecute above would have failed otherwise. */
                /* DBI requires us to set each tuple_status to the rows
                 * affected but we don't know it on a per row basis so. In any case in
                 * order to count which tuples were executed and which were not we need
                 * to return SQL_PARAM_SUCCES/SQL_PARAM_UNUSED - obviously any rows in
                 * error were executed. The code above needs to translate ODBC statuses.*/
                if (SvTRUE(tuple_status)){
                    av_store(tuples_status_av, row,
                             newSViv((IV) imp_sth->param_status_array[row]));
                    /*av_store(tuples_status_av, row, newSViv((IV)-1));*/
                }
            } else {		/* SQL_PARAM_ERROR or SQL_PARAM_SUCCESS_WITH_INFO */
                SV *err_svs[3];
                int found;

                /* Some drivers won't support SQL_DIAG_ROW_NUMBER so we cannot be sure
                   which diag relates to which row. 'found' tells us if we found a diag
                   for row 'row+1' but in any case what can we do if we don't - so we
                   just report whatever diag we have */
                found = get_row_diag(row+1,
                                     imp_sth,
                                     sqlstate,
                                     &native,
                                     msg,
                                     sizeof(msg));

                if (SvTRUE(tuple_status)){
                    err_svs[0] = newSViv((IV)native);
                    err_svs[1] = newSVpv(msg, 0);
                    err_svs[2] = newSVpv(sqlstate, 0);

                    av_store(tuples_status_av, row,
                             newRV_noinc((SV *)(av_make(3, err_svs))));
                }
                DBIh_SET_ERR_CHAR(sth, (imp_xxh_t*)imp_sth, Nullch, 1, msg,
                                  sqlstate, Nullch);
                err_seen++;
            }
        }
    }

    /* reset paramset size and params processed */
    SQLSetStmtAttr(imp_sth->hstmt, SQL_ATTR_PARAMS_PROCESSED_PTR,
                   (SQLPOINTER)NULL, 0);
    SQLSetStmtAttr(imp_sth->hstmt, SQL_ATTR_PARAMSET_SIZE,
                   (SQLPOINTER)1, 0);
    SQLSetStmtAttr(imp_sth->hstmt, SQL_ATTR_PARAM_STATUS_PTR,
                   (SQLPOINTER)NULL, 0);

    rc = SQLRowCount(imp_sth->hstmt, &imp_sth->RowCount);
    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        TRACE2(imp_sth, "    SQLRowCount=%d (rows=%"IVdf")\n", rc, (IV)imp_sth->RowCount);
    if (rc != SQL_SUCCESS) {
        /* TO_DO free strlen_or_ind_array */
        /* on the other hand since batch_size is always constant we could
           leave this for other execute_for_fetches */
        /*safefree(phs->strlen_or_ind_array);*/
        /*phs->strlen_or_ind_array = NULL;*/
        dbd_error(sth, rc, "odbc_st_execute_for_fetch/SQLRowCount");
        return -2;
    }
    DBIc_ROW_COUNT(imp_sth) = imp_sth->RowCount;

    /* why does this break stuff  imp_sth->param_status_array = NULL; */
    if (err_seen) {
        return -2;
    } else {
        return imp_sth->RowCount;
    }
}

/*
 * get_row_diag
 *
 * When we are doing execute_for_fetch/execute_array we bind rows of
 * parameters. When one of more fail we have a list of diagnostics and
 * the driver manager may reorder them in severity order. Also, each row
 * in error could generate multiple error diagnostics e.g.,
 * attempting to insert too much data generates:
 * diag 1 22001, 2290136, [Microsoft][ODBC SQL Server Driver][SQL Server]String or binary data would be truncated.
 * diag 2 01000, 2290136, [Microsoft][ODBC SQL Server Driver][SQL Server]The statem ent has been terminated.
 *
 * Fortunately for us, each diagnostic contains the row number the error relates
 * to (in working drivers). This function is passed the row we have detected
 * in error and attempts to find the relevant error - it always returns the
 * first error (if there is more than one).
 *
 * We return 1 if any error for the supplied recno is found else 0
 * Also, if SQLGetDiagRec fails we fill state, native, msg with a values saying so
 * so you can rely on the fact state, native and msg are at least set.
 */
static int get_row_diag(SQLSMALLINT recno,
                        imp_sth_t *imp_sth,
                        char *state,
                        SQLINTEGER *native,
                        char *msg,
                        size_t max_msg) {
    SQLSMALLINT i = 1;
    SQLRETURN rc;
    SQLSMALLINT msg_len;

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
        TRACE1(imp_sth, "    +get_row_diag for row %d\n", recno);

    /*printf("get_row_diag %d\n", recno);*/
    /*
      SQLRETURN return_code;

      rc = SQLGetDiagField(SQL_HANDLE_STMT,
      imp_sth->hstmt,
      0,
      SQL_DIAG_RETURNCODE,
      &return_code,
      0,
      NULL);
      printf("return code = %d\n", return_code);
    */
    while(SQL_SUCCEEDED(rc = SQLGetDiagRec(SQL_HANDLE_STMT, imp_sth->hstmt, i,
                                           state, native, msg, max_msg, &msg_len))) {
        /*SQLINTEGER col;*/
        SQLLEN row;
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
            PerlIO_printf(DBIc_LOGPIO(imp_sth),
                          "    diag %d %s, %ld, %s\n",
                          i, state, (long)*native, msg);
        /*printf("diag %d %s, %ld, %s\n", i, state, native, msg);*/
        if (max_msg < 100) {
            croak("Come on, code needs some space to put the diag message");
        }

        rc = SQLGetDiagField(SQL_HANDLE_STMT,
                             imp_sth->hstmt,
                             i,
                             SQL_DIAG_ROW_NUMBER,
                             &row,
                             0,
                             NULL);
        if (SQL_SUCCEEDED(rc)) {
	    /* Could return SQL_ROW_NUMBER_UNKNOWN or SQL_NO_ROW_NUMBER */
            if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3))
                PerlIO_printf(DBIc_LOGPIO(imp_sth), "     diag row=%ld\n", row);
	    /* few drivers support SQL_DIAG_COLUMN_NUMBER - most return -1 unfortunately
	    rc = SQLGetDiagField(SQL_HANDLE_STMT,
				 imp_sth->hstmt,
				 i,
				 SQL_DIAG_COLUMN_NUMBER,
				 &col,
				 0,
				 NULL);
				 printf("  row %d col %ld\n", row, col); */
            if (row == (SQLLEN)recno) return 1;
        } else if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 3)) {
            TRACE0(imp_sth, "SQLGetDiagField for SQL_DIAG_ROW_NUMBER failed");
        }
        i++;			/* next record */
    };
    /* will be SQL_NO_DATA if we reach the end of diags without finding anything */
    /* TO_DO some drivers are not going to support SQL_DIAG_COLUMN_NUMBER
       so we should do better than below - maybe show the first/last error */
    strcpy(state, "HY000");
    *native = 1;
    strcpy(msg, "failed to retrieve diags");
    return 0;

}



/*
 *  taf_callback_wrapper is the function we pass to Oracle to be called
 *  when a connection fails. We asked the ODBC driver to pass our dbh
 *  handle in and it also gives us the type and event. We just pass all
 *  these args off to the registered Perl subroutine and return to
 *  the Oracle driver whatever that Perl sub returns to us. In this way
 *  the user's Perl dictates what happens in the failover process and not
 *  us.
 */

static int taf_callback_wrapper (
    void *handle,
    int type,
    int event) {

    int return_count;
    int ret;
    SV* dbh = (SV *)handle;

    D_imp_dbh(dbh);

	dSP;
	PUSHMARK(SP);
    XPUSHs(handle);
	XPUSHs(sv_2mortal(newSViv(event)));
	XPUSHs(sv_2mortal(newSViv(type)));
    PUTBACK;

	return_count = call_sv(imp_dbh->odbc_taf_callback, G_SCALAR);

    SPAGAIN;

    if (return_count != 1)
        croak("Expected one scalar back from taf handler");

    ret = POPi;

    PUTBACK;
    return ret;
}

static void check_for_unicode_param(
    imp_sth_t *imp_sth,
    phs_t *phs) {

    if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5)) {
        TRACE2(imp_sth, "check_for_unicode_param - sql_type=%s, described=%s\n",
               S_SqlTypeToString(phs->sql_type), S_SqlTypeToString(phs->described_sql_type));
    }

    /* If we didn't called SQLDescribeParam successfully, we've defaulted/guessed so just return
       as sql_type will already be set */
    if (!phs->described_sql_type) return;

    if (SvUTF8(phs->sv)) {
        if (phs->described_sql_type == SQL_CHAR) {
            phs->sql_type = SQL_WCHAR;
        } else if (phs->described_sql_type == SQL_VARCHAR) {
            phs->sql_type = SQL_WVARCHAR;
        } else if (phs->described_sql_type == SQL_LONGVARCHAR) {
            phs->sql_type = SQL_WLONGVARCHAR;
        } else {
            phs->sql_type = phs->described_sql_type;
        }
        if (DBIc_TRACE(imp_sth, DBD_TRACING, 0, 5) && (phs->sql_type != phs->described_sql_type))
            TRACE1(imp_sth, "      SvUTF8 parameter - changing to %s type\n",
                   S_SqlTypeToString(phs->sql_type));
    } else {
        if (phs->described_sql_type == SQL_NUMERIC ||
            phs->described_sql_type == SQL_DECIMAL ||
            phs->described_sql_type == SQL_FLOAT ||
            phs->described_sql_type == SQL_REAL ||
            phs->described_sql_type == SQL_DOUBLE) {
            phs->sql_type = SQL_VARCHAR;
        } else {
            phs->sql_type = phs->described_sql_type;
        }
    }
}


AV* dbd_data_sources(SV *drh ) {
	int numDataSources = 0;
	SQLUSMALLINT fDirection = SQL_FETCH_FIRST;
	RETCODE rc;
    SQLCHAR dsn[SQL_MAX_DSN_LENGTH+1+9 /* strlen("DBI:ODBC:") */];
    SQLSMALLINT dsn_length;
    SQLCHAR description[256];
    SQLSMALLINT description_length;
    AV *ds = newAV();
	D_imp_drh(drh);

	if (!imp_drh->connects) {
	    rc = SQLAllocEnv(&imp_drh->henv);
	    if (!SQL_ok(rc)) {
            imp_drh->henv = SQL_NULL_HENV;
            dbd_error(drh, rc, "data_sources/SQLAllocEnv");
            return NULL;

	    }
	}
	strcpy(dsn, "dbi:ODBC:");
	while (1) {
        description[0] = '\0';
        rc = SQLDataSources(imp_drh->henv, fDirection,
                            dsn+9, /* strlen("dbi:ODBC:") */
                            SQL_MAX_DSN_LENGTH,
                            &dsn_length,
                            description, sizeof(description),
                            &description_length);
        if (!SQL_ok(rc)) {
            if (rc != SQL_NO_DATA_FOUND) {
                /*
                 *  Temporarily increment imp_drh->connects, so
                 *  that dbd_error uses our henv.
                 */
                imp_drh->connects++;
                dbd_error(drh, rc, "data_sources/SQLDataSources");
                imp_drh->connects--;
            }
            break;
        }
        av_push( ds, newSVpv(dsn, dsn_length + 9 ) );
	    fDirection = SQL_FETCH_NEXT;
	}
	if (!imp_drh->connects) {
	    SQLFreeEnv(imp_drh->henv);
	    imp_drh->henv = SQL_NULL_HENV;
	}
    return ds;

}
/* end */
