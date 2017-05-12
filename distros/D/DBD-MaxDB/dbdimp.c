/*!
@file           dbdimp.c
@author         MarcoP, ThomasS
@ingroup        DBD::MaxDB
@brief          DBD::MaxDB - DBI driver for the MaxDB database
@see            

\if EMIT_LICENCE

    ========== licence begin  GPL
    Copyright (c) 2001-2005 SAP AG

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
    ========== licence end



\endif
*/

#include "dbdimp.h"
#include <stdarg.h>
#ifdef _WIN32
#include "malloc.h"
#else
#include "alloca.h"
#endif

DBISTATE_DECLARE;

#ifndef DBD_MAXDB_MIN
#define DBD_MAXDB_MIN(a,b) ((a) < (b) ? (a) : (b))
#endif

#define ALIGNMENT 8
#define ALIGN(n) (((n) % ALIGNMENT) == 0) ? (n) : ((n) + ALIGNMENT - ((n) % ALIGNMENT))

#ifndef DBIc_DBISTATE
#define DBIc_DBISTATE(handle) DBIS
#endif

#ifndef DBIc_LOGPIO
#define DBIc_LOGPIO(handle) DBILOGFP
#endif

#ifndef SvPV_nolen
#define SvPV_nolen(sv) SvPV(sv, PL_na)
#endif

#ifndef newSVuv
#define newSVuv(val) newSViv((IV)(val))
#endif
/**
 * 'Enter' trace macro for methods.
 * @param handle The handle for printing the trace.
 * @param method The method name (not enclosed in "").
 * @param clazz The corresponding clazz handle.
 */
#define DBD_MAXDB_METHOD_ENTER(handle, method) \
  if (DBIc_DBISTATE(handle)->debug >= 2) \
    PerlIO_printf(DBIc_LOGPIO(handle), "      -> %s class=0x%lx\n", #method, handle)

/**
 * 'EXIT' trace macro returning a value.
 * @param handle The handle for printing the trace.
 * @param method The method name (not enclosed in "").
 */
#define DBD_MAXDB_METHOD_RETURN(handle, method, retval) \
  if (DBIc_DBISTATE(handle)->debug >= 2) \
    PerlIO_printf(DBIc_LOGPIO(handle), "      <- %s retval=%d\n", #method, retval);\
  return retval  

/**
 * 'EXIT' trace macro returning an SV value.
 * @param handle The handle for printing the trace.
 * @param method The method name (not enclosed in "").
 */
#define DBD_MAXDB_METHOD_RETURN_SV(handle, method, retval) \
  if (DBIc_DBISTATE(handle)->debug >= 2) { \
     STRLEN slmk; \
     char* vlmk = (retval)?SvPV(retval ,slmk):"NullSV"; \
     PerlIO_printf(DBIc_LOGPIO(handle), "      <- %s retval=%s\n", #method, vlmk); \
  } return retval  

/**
 * 'EXIT' trace macro returning an SV value.
 * @param handle The handle for printing the trace.
 * @param method The method name (not enclosed in "").
 */
#define DBD_MAXDB_METHOD_RETURN_AV(handle, method, retval) \
  if (DBIc_DBISTATE(handle)->debug >= 2) { \
    PerlIO_printf(DBIc_LOGPIO(handle), "      <- %s retval=%s\n", #method, (retval == Nullav)?"NullAv":"AV"); \
  } return retval  
    
/**
 * 'EXIT' trace macro without return value for methods.
 * @param handle The handle for printing the trace.
 * @param method The method name (not enclosed in "").
 */
#define DBD_MAXDB_METHOD_EXIT(handle, method) \
  if (DBIc_DBISTATE(handle)->debug >= 2) \
    PerlIO_printf(DBIc_LOGPIO(handle), "      <- %s\n", #method)
       
static int SQLDBC_SQLType2ODBCType (SQLDBC_SQLType sqltype){
   int erg = 1111; /*type other*/
  switch (sqltype) {
    case (SQLDBC_SQLTYPE_CHA): {}
    case (SQLDBC_SQLTYPE_CHE): {
        erg = SQL_CHAR;
        break;
    }
    case (SQLDBC_SQLTYPE_UNICODE): {}
    case (SQLDBC_SQLTYPE_VARCHARUNI): {
        erg = SQL_WCHAR;
        break;
    }
    case (SQLDBC_SQLTYPE_VARCHARA): {}
    case (SQLDBC_SQLTYPE_VARCHARE): {    
        erg = SQL_VARCHAR;
        break;
    }
    case (SQLDBC_SQLTYPE_STRA): {}
    case (SQLDBC_SQLTYPE_STRE): {}
    case (SQLDBC_SQLTYPE_LONGA): {}
    case (SQLDBC_SQLTYPE_LONGE): {
        erg = SQL_LONGVARCHAR;
        break;
    }
    case (SQLDBC_SQLTYPE_STRUNI): {}
    case (SQLDBC_SQLTYPE_LONGUNI): {
        erg = SQL_WLONGVARCHAR;
        break;
    }
    case (SQLDBC_SQLTYPE_STRB): {}
    case (SQLDBC_SQLTYPE_STRDB): {}
    case (SQLDBC_SQLTYPE_LONGB): {}
    case (SQLDBC_SQLTYPE_LONGDB): {
        erg = SQL_LONGVARBINARY;
        break;
    }
    case (SQLDBC_SQLTYPE_DBYTEEBCDIC): {}
    case (SQLDBC_SQLTYPE_CHB): {
        erg = SQL_BINARY;
        break;
    }
    case (SQLDBC_SQLTYPE_VARCHARB): {
        erg = SQL_VARBINARY;
        break;
    }
    case (SQLDBC_SQLTYPE_SMALLINT): {
        erg = SQL_SMALLINT;
        break;
    }
    case (SQLDBC_SQLTYPE_INTEGER): {
        erg = SQL_INTEGER;
        break;
    }
    case (SQLDBC_SQLTYPE_VFLOAT):{}
    case (SQLDBC_SQLTYPE_FLOAT): {
      erg = SQL_FLOAT;
      /* an exact solution should also evaluate the column precision  
      if (length > 7) {  
          erg = SQL_FLOAT;
      } else {
          erg = SQL_REAL;
      }
      */
      break;
    }
    case (SQLDBC_SQLTYPE_FIXED): {
        erg = SQL_DECIMAL;
        break;
    }
    case (SQLDBC_SQLTYPE_DATE): {
        erg = SQL_TYPE_DATE;
        break;
    }
    case (SQLDBC_SQLTYPE_TIME): {
        erg = SQL_TYPE_TIME;
        break;
    }
    case (SQLDBC_SQLTYPE_TIMESTAMP): {
        erg = SQL_TYPE_TIMESTAMP;
        break;
    }
    case (SQLDBC_SQLTYPE_BOOLEAN): {
        erg = SQL_BIT;
        break;
    }
    case (SQLDBC_SQLTYPE_ABAPTABHANDLE): {
        erg = 1111;
        break;
    }
  }  
  return erg;
} 

typedef enum  
{
    DBD_ERR_UNKNOWN,                  //!< Unknown error.   
    DBD_ERR_INITIALIZATION_FAILED_S,
    DBD_ERR_WRONG_PARAMETER_S,
    DBD_ERR_GENERATE_RESULTSET,
    DBD_ERR_SESSION_NOT_CONNECTED,
    DBD_ERR_CANNOT_GET_COLUMNNAME_D,
    DBD_ERR_NO_RESULTSET,
    DBD_ERR_STATEMENT_NOT_PREPARED,
    DBD_ERR_INVALID_PARAMETER_INDEX_D,
    DBD_ERR_LONG_COLUMN_TRUNCATED_D,
    DBD_ERR_VALUE_OVERFLOW_D,
    DBD_ERR_PARAMETER_NOT_SET_D,
    DBD_ERR_PARAMETER_IS_NOT_INPUT_D,
}dbd_maxdb_errorcode;    

typedef struct dbd_maxdb_errordata
{
    dbd_maxdb_errorcode applcode;
    SQLDBC_Int4         errorcode;
    const char*         sqlstate;
    const char*         msgformat;
}dbd_maxdb_errordata;


static dbd_maxdb_errordata errordata[] = 
{
    { DBD_ERR_UNKNOWN,                   -11000 ,  "",     "Unknown error"    },
    { DBD_ERR_INITIALIZATION_FAILED_S  , -11001 ,  "",     "Initialization failed [%s]." },
    { DBD_ERR_WRONG_PARAMETER_S        , -11002 ,  "",     "Invalid datatype for parameter [%s]."},
    { DBD_ERR_GENERATE_RESULTSET       , -11003 ,  "",     "Statement generates a resultset."},
    { DBD_ERR_SESSION_NOT_CONNECTED    , -11004 ,  "",     "Session not connected."},
    { DBD_ERR_CANNOT_GET_COLUMNNAME_D  , -11005 ,  "",     "Cannot get column name for column %d."},
    { DBD_ERR_NO_RESULTSET             , -11006 ,  "",     "No resultset found."},
    { DBD_ERR_STATEMENT_NOT_PREPARED   , -11007 ,  "",     "Statement not prepared."},
    { DBD_ERR_INVALID_PARAMETER_INDEX_D, -11008 ,  "",     "Invalid parameter index %d."},
    { DBD_ERR_LONG_COLUMN_TRUNCATED_D,   -11009 ,  "",     "Column/Parameter %d truncated. Maybe LongTruncOk is not set and/or LongReadLen is too small"},
    { DBD_ERR_VALUE_OVERFLOW_D,          -11010 ,  "",     "Value overflow for column/paramter %d."},
    { DBD_ERR_PARAMETER_NOT_SET_D,       -11011 ,  "07002","Parameter/Column (%d) not bound."},
    { DBD_ERR_PARAMETER_IS_NOT_INPUT_D,  -11012 ,  "07002","Parameter for column (%d) is not an out/inout parameter."},
};

static SV* referenceDefaultValue  = NULL;

static void dbd_maxdb_delete_params(dbd_maxdb_bind_param* params, int parCnt) {
  int i;
  if (parCnt) {
    for (i = 0;  i < parCnt;  i++) {
            if (params[i].value) (void) SvREFCNT_dec(params[i].value), params[i].value = NULL;
          }
          Safefree(params);
  }
}

/***************************************************************************
 *
 *  Name:    dbd_init
 *
 *  Purpose: Called when the driver is installed by DBI
 *
 *  Input:   dbistate - pointer to the DBIS variable, used for some
 *               DBI internal things
 *
 *  Returns: Nothing
 *
 **************************************************************************/

void dbd_maxdb_init(dbistate_t* dbistate) {
#ifdef dTHR
    dTHR;
#endif
  DBISTATE_INIT;  /*  Initialize the DBI macros  */
}


/***************************************************************************
 *
 *  Name:    do_error
 *
 *  Purpose: Called to associate an error code and an error message
 *           to some handle
 *
 *  Input:   h - the handle in error condition
 *           rc - the error code
 *           what - the error message
 *
 *  Returns: Nothing
 *
 **************************************************************************/
static void dbd_maxdb_internal_error(SV* h, dbd_maxdb_errorcode errcode, ...) {
    va_list ap;
    STRLEN errl;
    D_imp_xxh(h);
    dbd_maxdb_errordata err = errordata[errcode];
    SV *errstr = DBIc_ERRSTR(imp_xxh);
       
    va_start(ap, errcode);
    sv_vsetpvfn(errstr, err.msgformat, strlen (err.msgformat), &ap, Null(SV**), 0, 0);
    va_end(ap); 
    sv_setiv(DBIc_ERR   (imp_xxh), (IV)err.errorcode);  
    sv_setpv(DBIc_STATE (imp_xxh), err.sqlstate);
          
    if (DBIc_DBISTATE(imp_xxh)->debug >= 2)
        PerlIO_printf(DBIc_LOGPIO(imp_xxh), "%d %s [%s]\n",
                      err.errorcode, SvPV(errstr,errl), err.sqlstate);
    
}

static void dbd_maxdb_error(SV* h, SQLDBC_Int4 errnum, char* errmsg, char* sqlstate) {
    D_imp_xxh(h);

    sv_setiv(DBIc_ERR   (imp_xxh), (IV)errnum); 
    sv_setpv(DBIc_ERRSTR(imp_xxh), errmsg);
    sv_setpv(DBIc_STATE (imp_xxh), sqlstate);
    
    if (DBIc_DBISTATE(imp_xxh)->debug >= 2)
      PerlIO_printf(DBIc_LOGPIO(imp_xxh), "%d %s [%s]\n",
                    errnum, errmsg, sqlstate);
}

static void dbd_maxdb_sqldbc_error(SV* h, SQLDBC_ErrorHndl *errhdl) {
    SQLDBC_Int4  errnum = SQLDBC_ErrorHndl_getErrorCode(errhdl);
    char* errmsg = SQLDBC_ErrorHndl_getErrorText(errhdl);
    char* sqlstate = SQLDBC_ErrorHndl_getSQLState(errhdl);

    dbd_maxdb_error(h, errnum, errmsg, sqlstate);
}

/***************************************************************************
 *
 *  Name:    dbd_db_login
 *
 *  Purpose: Called for connecting to a database and logging in.
 *
 *  Input:   dbh - database handle being initialized
 *           imp_dbh - drivers private database handle data
 *           dbname - the database we want to log into; may be like
 *               "dbname:host" or "dbname:host:port"
 *           user - user name to connect as
 *           password - passwort to connect with
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error has already
 *           been called in the latter case
 *
 **************************************************************************/
static SQLDBC_DatabaseMetaData myDBMS={69,34,34}; /*magic numbers from gsp00.h*/
static SQLDBC_DatabaseMetaData* SQLDBC_Connection_getMetaData(SQLDBC_Connection* hdl){
  return &myDBMS;
}
 
int dbd_maxdb_db_login6(SV *dbh, imp_dbh_t *imp_dbh, char *url, char *user, char* password, SV *attr){
#ifdef dTHR
  dTHR;
#endif
  char *host,*dbname;
  D_imp_drh_from_dbh;
  int i, usernameLen, passwdLen;
  
  DBD_MAXDB_METHOD_ENTER(imp_dbh, dbd_maxdb_db_login6); 

  if (DBIc_DBISTATE(imp_dbh)->debug >= 3){
    if (attr && SvROK(attr)){
        HV* hash;
        HE* hash_entry;
        int num_keys, i;
        SV* sv_key;
        SV* sv_val;
        
        hash = (HV*)SvRV(attr);
        num_keys = hv_iterinit(hash);
        PerlIO_printf(DBIc_LOGPIO(imp_dbh), "        connect attributes:\n");
        for (i = 0; i < num_keys; i++) {
            hash_entry = hv_iternext(hash);
            sv_key = hv_iterkeysv(hash_entry);
            sv_val = hv_iterval(hash, hash_entry);
            PerlIO_printf(DBIc_LOGPIO(imp_dbh), "         %s => %s\n", SvPV_nolen(sv_key), SvPV_nolen(sv_val));
        }
    }
  }               
                  
  /*set connect properties*/
  if (imp_dbh) {
      HV* hash = (HV*)SvRV(attr);
      SV *sv_key;
      STRLEN svl;
      int i;
      char* connProps[] = { "COMPNAME",  
                            "APPLICATION",
                            "APPVERSION" ,
                            "SQLMODE",
                            "UNICODE",
                            "TIMEOUT",
                            "ISOLATIONLEVEL",
                            "PACKETCOUNT",
                            "STATEMENTCACHESIZE"
                           };
      imp_dbh->m_connprop = SQLDBC_ConnectProperties_new_SQLDBC_ConnectProperties();
      imp_dbh->m_stmt = NULL;
     
      sv_key = hv_delete(hash, "HOST", 4, 0); /* avoid later STORE */ 
      host = SvPV(sv_key, svl); 

      sv_key = hv_delete(hash, "DBNAME", 6, 0); /* avoid later STORE */ 
      dbname = SvPV(sv_key, svl); 

      if (user && !*user){
        sv_key = hv_delete(hash, "USERNAME", 8, 0); /* avoid later STORE */ 
        if (sv_key){
          user = SvPV(sv_key, svl); 
        }
        if (!user) {
             user = "";
        }
      }
      if (password && !*password){
        sv_key = hv_delete(hash, "PASSWORD", 8, 0); /* avoid later STORE */ 
        if (sv_key){
          password = SvPV(sv_key, svl); 
        }
        if (!password) {
           password = "";
        }
      }
      
      for (i=0; i< sizeof(connProps)/sizeof(char*); i++){
        sv_key = hv_delete(hash, connProps[i], strlen(connProps[i]), 0); /* avoid later STORE */ 
        if (sv_key){
          SQLDBC_ConnectProperties_setProperty  ( imp_dbh->m_connprop, connProps[i], SvPV(sv_key, svl));  
          if (DBIc_DBISTATE(imp_dbh)->debug >= 2){
              PerlIO_printf(DBIc_LOGPIO(imp_dbh), "        adding conn prop %s => %s\n",
                            connProps[i], SvPV(sv_key, svl));
                      }      
        }      
      }
  } else {
    dbd_maxdb_internal_error(dbh, DBD_ERR_INITIALIZATION_FAILED_S, "missing imp_dbh handle");
    DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_login6, SQLDBC_FALSE); 
  } 

  /* upper/lower case hanndling for username/password */
  if (user &&(usernameLen = strlen(user))){
    if (user[0]!= '"' || user[usernameLen-1] != '"'){
      for (i=0; i<usernameLen; i++) user[i]=toupper(user[i]);
    }
  }

  if (password && (passwdLen = strlen(password))){
    if (password[0]!= '"' || password[passwdLen-1] != '"'){
      for (i=0; i<passwdLen; i++) password[i]=toupper(password[i]);
    }
  }

  if (!imp_drh->m_maxDBEnv) {
    char errorText[128];
    SQLDBC_IRuntime *runtime = ClientRuntime_GetClientRuntime(errorText, sizeof(errorText));
    if(!runtime) {
      dbd_maxdb_internal_error(dbh, DBD_ERR_INITIALIZATION_FAILED_S, errorText);
      DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_login6, SQLDBC_FALSE); 
    } 
    imp_drh->m_maxDBEnv = SQLDBC_Environment_new_SQLDBC_Environment(runtime);
    if(!imp_drh->m_maxDBEnv) {
      dbd_maxdb_internal_error(dbh, DBD_ERR_INITIALIZATION_FAILED_S, "Cannot create environment handle");
      DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_login6, SQLDBC_FALSE); 
    } 
  }
  
  imp_dbh->m_connection = SQLDBC_Environment_createConnection(imp_drh->m_maxDBEnv);
  if(!imp_dbh->m_connection) {
    dbd_maxdb_internal_error(dbh, DBD_ERR_INITIALIZATION_FAILED_S, "Cannot get connection from environment");
    DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_login6, SQLDBC_FALSE); 
  }
  if (! SQLDBC_Connection_connectASCII(imp_dbh->m_connection, 
                                       host, 
                                       dbname, 
                                       user, 
                                       password, 
                                       imp_dbh->m_connprop)==SQLDBC_OK){
    dbd_maxdb_sqldbc_error(dbh, SQLDBC_Connection_getError(imp_dbh->m_connection)) ;
    DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_login6, SQLDBC_FALSE); 
  }

  imp_dbh->m_dbmd = SQLDBC_Connection_getMetaData(imp_dbh->m_connection);      
  DBIc_ACTIVE_on(imp_dbh);
  DBIc_on(imp_dbh, DBIcf_IMPSET);
  if (! referenceDefaultValue){
    referenceDefaultValue = get_sv("DBD::MaxDB::DEFAULT_PARAMETER", 0);
    referenceDefaultValue = SvRV(referenceDefaultValue);
  }
  DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_login6, SQLDBC_TRUE); 
}

int
   dbd_maxdb_db_login(SV *dbh, imp_dbh_t *imp_dbh, char *dbname, char *uid, char *pwd)
{
#ifdef dTHR
    dTHR;
#endif
    DBD_MAXDB_METHOD_ENTER(imp_dbh, dbd_maxdb_db_login); 
    DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_login, dbd_maxdb_db_login6(dbh, imp_dbh, dbname, uid, pwd, Nullsv)); 
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_db_commit
 *           dbd_maxdb_db_rollback
 *
 *  Purpose: You guess what they should do. mSQL doesn't support
 *           transactions, so we stub commit to return OK
 *           and rollback to return ERROR in any case.
 *
 *  Input:   dbh - database handle being commited or rolled back
 *           imp_dbh - drivers private database handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error has already
 *           been called in the latter case
 *
 **************************************************************************/

int dbd_maxdb_db_commit(SV* dbh, imp_dbh_t* imp_dbh) {
#ifdef dTHR
    dTHR;
#endif
  DBD_MAXDB_METHOD_ENTER(imp_dbh, dbd_maxdb_db_commit); 
  if (DBIc_has(imp_dbh, DBIcf_AutoCommit)) {
    DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_commit, SQLDBC_TRUE); 
  }
  if (! SQLDBC_Connection_commit (imp_dbh->m_connection)==SQLDBC_OK){
    dbd_maxdb_sqldbc_error(dbh, SQLDBC_Connection_getError(imp_dbh->m_connection)) ;
    DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_commit, SQLDBC_FALSE); 
  }  
  DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_commit, SQLDBC_TRUE); 
}

int dbd_maxdb_db_rollback(SV* dbh, imp_dbh_t* imp_dbh) {
#ifdef dTHR
    dTHR;
#endif
  DBD_MAXDB_METHOD_ENTER(imp_dbh, dbd_maxdb_db_rollback); 
  if (DBIc_has(imp_dbh, DBIcf_AutoCommit)) {
    DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_rollback, SQLDBC_TRUE); 
  }
  if (! SQLDBC_Connection_rollback (imp_dbh->m_connection)==SQLDBC_OK){
    dbd_maxdb_sqldbc_error(dbh, SQLDBC_Connection_getError(imp_dbh->m_connection)) ;
    DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_rollback, SQLDBC_FALSE); 
  }  
  DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_rollback, SQLDBC_TRUE); 
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_db_disconnect
 *
 *  Purpose: Disconnect a database handle from its database
 *
 *  Input:   dbh - database handle being disconnected
 *           imp_dbh - drivers private database handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error has already
 *           been called in the latter case
 *
 **************************************************************************/

int dbd_maxdb_db_disconnect(SV* dbh, imp_dbh_t* imp_dbh) {
#ifdef dTHR
    dTHR;
#endif

    DBD_MAXDB_METHOD_ENTER(imp_dbh, dbd_maxdb_db_disconnect); 
  
    if (imp_dbh->m_stmt){
      SQLDBC_Connection_releaseStatement (imp_dbh->m_connection, imp_dbh->m_stmt); 
    }
    /*ignore errors*/
    SQLDBC_Connection_close (imp_dbh->m_connection);

    DBIc_ACTIVE_off(imp_dbh);
    DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_disconnect, SQLDBC_TRUE); 
}


/***************************************************************************
 *
 *  Name:    dbd_discon_all
 *
 *  Purpose: Disconnect all database handles at shutdown time
 *
 *  Input:   dbh - database handle being disconnected
 *           imp_dbh - drivers private database handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error has already
 *           been called in the latter case
 *
 **************************************************************************/

int dbd_discon_all (SV *drh, imp_drh_t *imp_drh) {
#if defined(dTHR)
  dTHR;
#endif
    DBD_MAXDB_METHOD_ENTER(imp_drh, dbd_discon_all); 
    DBD_MAXDB_METHOD_RETURN(imp_drh, dbd_discon_all, SQLDBC_FALSE); 
}


/***************************************************************************
 *
 *  Name:    dbd_db_destroy
 *
 *  Purpose: Our part of the dbh destructor
 *
 *  Input:   dbh - database handle being destroyed
 *           imp_dbh - drivers private database handle data
 *
 *  Returns: Nothing
 *
 **************************************************************************/

void dbd_maxdb_db_destroy(SV* dbh, imp_dbh_t* imp_dbh) {
#if defined(dTHR)
  dTHR;
#endif
    D_imp_drh_from_dbh;
    DBD_MAXDB_METHOD_ENTER(imp_dbh, dbd_maxdb_db_destroy); 
    if (DBIc_ACTIVE(imp_dbh)) {
        dbd_maxdb_db_disconnect(dbh, imp_dbh);
    }
    SQLDBC_Environment_releaseConnection (imp_drh->m_maxDBEnv, imp_dbh->m_connection);
    imp_dbh->m_connection = NULL;
    DBIc_off(imp_dbh, DBIcf_IMPSET);
    DBD_MAXDB_METHOD_EXIT(imp_dbh, dbd_maxdb_db_destroy); 
}


/***************************************************************************
 *
 *  Name:    dbd_db_STORE_attrib
 *
 *  Purpose: Function for storing dbh attributes; we currently support
 *           just nothing. :-)
 *
 *  Input:   dbh - database handle being modified
 *           imp_dbh - drivers private database handle data
 *           keysv - the attribute name
 *           valuesv - the attribute value
 *
 *  Returns: TRUE for success, FALSE otherwise
 *
 **************************************************************************/

#define  DBD_MAXDB_MAX_KEYWORD_LEN 30

typedef struct {
        char rawString [DBD_MAXDB_MAX_KEYWORD_LEN];  
        SQLDBC_Int4 length;
}dbd_maxdb_cmdKeyword ;

typedef struct {
        SQLDBC_Int4 entry;
        dbd_maxdb_cmdKeyword keyword;  
} dbd_maxdb_cmdKeywordTable;


static dbd_maxdb_cmdKeywordTable dbh_sqlmodeTab [ ]= {
  { SQLDBC_ANSI,     {"A"        ,sizeof("A")-1}},
  { SQLDBC_ANSI,     {"ANSI"     ,sizeof("ANSI")-1}},
  { SQLDBC_DB2,      {"D"        ,sizeof("D")-1}},
  { SQLDBC_DB2,      {"DB2"      ,sizeof("DB2")-1}},
  { SQLDBC_INTERNAL, {"I"        ,sizeof("I")-1}},
  { SQLDBC_INTERNAL, {"INTERNAL" ,sizeof("INTERNAL")-1}},
  { SQLDBC_ORACLE,   {"O"        ,sizeof("O")-1}},
  { SQLDBC_ORACLE,   {"ORACLE"   ,sizeof("ORACLE")-1}}
};
#define DBD_MAXDB_SQLMODETABLESIZE  (sizeof(dbh_sqlmodeTab) /sizeof(dbd_maxdb_cmdKeywordTable))

typedef enum {    
  dbd_maxdb_option_autocommit     =  1,
  dbd_maxdb_option_isolationlevel =  2,
  dbd_maxdb_option_kernelversion  =  3,
  dbd_maxdb_option_unicodedb      =  4,
  dbd_maxdb_option_sdkversion     =  5,
  dbd_maxdb_option_sqlmode        =  6,
  dbd_maxdb_option_libraryversion =  7,
  dbd_maxdb_option_unknown        =  -1
}dbd_maxdb_option;


static dbd_maxdb_cmdKeywordTable dbh_optionTab [ ]= {
      { dbd_maxdb_option_autocommit,     {"AUTOCOMMIT"        ,sizeof("AUTOCOMMIT")-1}},
      { dbd_maxdb_option_isolationlevel, {"MAXDB_ISOLATIONLEVEL"    ,sizeof("MAXDB_ISOLATIONLEVEL")-1}},
      { dbd_maxdb_option_kernelversion,  {"MAXDB_KERNELVERSION"     ,sizeof("MAXDB_KERNELVERSION")-1}},
      { dbd_maxdb_option_libraryversion, {"MAXDB_LIBRARYVERSION"    ,sizeof("MAXDB_LIBRARYVERSION")-1}},
      { dbd_maxdb_option_sdkversion,     {"MAXDB_SDKVERSION"        ,sizeof("MAXDB_SDKVERSION")-1}},
      { dbd_maxdb_option_sqlmode,        {"MAXDB_SQLMODE"           ,sizeof("MAXDB_SQLMODE")-1}},
      { dbd_maxdb_option_unicodedb,      {"MAXDB_UNICODE"           ,sizeof("MAXDB_UNICODE")-1}},
    };

#define DBD_MAXDB_OPTIONTABLESIZE  (sizeof(dbh_optionTab) /sizeof(dbd_maxdb_cmdKeywordTable))

static SQLDBC_Int4 analyzeKeyword(char* pIdentifier, SQLDBC_Int4 IdentLength, dbd_maxdb_cmdKeywordTable myCMDKeywTab[] ,SQLDBC_Int4 numElementsTab){

    SQLDBC_Int4 m,pos,compareLength,begin = 1;            /*lower bound of search scope*/
    SQLDBC_Int4 end = numElementsTab; /*upper bound of search scope*/ 
    char UpperIdentifier[DBD_MAXDB_MAX_KEYWORD_LEN]; /*pIdentifier in upper cases*/

    if (! IdentLength || IdentLength > DBD_MAXDB_MAX_KEYWORD_LEN){
      return dbd_maxdb_option_unknown;
    }  

    /*upper pidentifier for case insensitive compare*/
    memset (&UpperIdentifier[0],0,DBD_MAXDB_MAX_KEYWORD_LEN);
    for (m=0; (m<IdentLength); m++) UpperIdentifier[m] = toupper(pIdentifier[m]);

    /* searching for keyword */ 
    do {
      SQLDBC_Int4 erg;                  /*result off keyword compare*/ 
      pos = (begin+end)/2;
      compareLength = (IdentLength > myCMDKeywTab[pos-1].keyword.length)?IdentLength:myCMDKeywTab[pos-1].keyword.length;
      erg = memcmp (&UpperIdentifier[0], 
        myCMDKeywTab[pos-1].keyword.rawString, 
        compareLength);
      if (erg == 0){
        if (IdentLength == myCMDKeywTab[pos-1].keyword.length){
          return myCMDKeywTab[pos-1].entry;
        } else {
          if (IdentLength > myCMDKeywTab[pos-1].keyword.length){
            erg = 1;
          } else{
            erg = -1;
          }  
        }    
      }
      
      if (erg < 0) {
        end = pos-1;
      } else {
        begin = pos+1;     
      }
    }while(begin <= end);  /*identifier not recognized as a keyword*/
    return dbd_maxdb_option_unknown;
  }
  
static SQLDBC_SQLMode String2SQLModeType (char* val, SQLDBC_Int4 vallen){
  return (SQLDBC_SQLMode) analyzeKeyword(val, vallen, dbh_sqlmodeTab, DBD_MAXDB_SQLMODETABLESIZE);
}  

int dbd_maxdb_db_STORE_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv, SV* valuesv) {
#if defined(dTHR)
  dTHR;
#endif
    STRLEN kl,vl;
    char *key = SvPV(keysv,kl);
    dbd_maxdb_option opt;
    int erg;

    DBD_MAXDB_METHOD_ENTER(imp_dbh, dbd_maxdb_db_STORE_attrib); 

    if (DBIc_DBISTATE(imp_dbh)->debug >= 3)
        PerlIO_printf(DBIc_LOGPIO(imp_dbh), "           STORE_attrib %s => %s\n",
                      key, SvPV(valuesv, vl));
                      
    if ((opt = (dbd_maxdb_option)analyzeKeyword(key, kl, dbh_optionTab, DBD_MAXDB_OPTIONTABLESIZE)) == dbd_maxdb_option_unknown){
      erg = SQLDBC_FALSE;
    } else {
      switch(opt)
      {
          case dbd_maxdb_option_autocommit:{
             SQLDBC_Connection_setAutoCommit (imp_dbh->m_connection, SvTRUE(valuesv));
                   DBIc_set(imp_dbh, DBIcf_AutoCommit, SvTRUE(valuesv));
             erg = SQLDBC_TRUE;
             break;
          }
          case dbd_maxdb_option_sqlmode:{
            char* sqlmode = SvPV(valuesv, vl);
            SQLDBC_ConnectProperties_setProperty  ( imp_dbh->m_connprop, "SQLMODE", sqlmode);  
            SQLDBC_Connection_setSQLMode (imp_dbh->m_connection, String2SQLModeType (sqlmode, vl));
            erg = SQLDBC_TRUE;
            break;
          }
          case dbd_maxdb_option_isolationlevel:{
             if(!SvIOK (valuesv)){
               dbd_maxdb_internal_error(dbh, DBD_ERR_WRONG_PARAMETER_S, "isolation level must be a number value");
               break;
             }
             if (! SQLDBC_Connection_setTransactionIsolation (imp_dbh->m_connection, SvIV(valuesv)) == SQLDBC_OK) {
               dbd_maxdb_sqldbc_error(dbh, SQLDBC_Connection_getError(imp_dbh->m_connection));
               break;
             }
             erg = SQLDBC_TRUE;
             break;
          }
       }
    }  
    DBD_MAXDB_METHOD_RETURN(imp_dbh, dbd_maxdb_db_STORE_attrib, erg); 
}


/***************************************************************************
 *
 *  Name:    dbd_db_FETCH_attrib
 *
 *  Purpose: Function for fetching dbh attributes
 *
 *  Input:   dbh - database handle being queried
 *           imp_dbh - drivers private database handle data
 *           keysv - the attribute name
 *
 *  Returns: An SV*, if sucessfull; NULL otherwise
 *
 *  Notes:   Do not forget to call sv_2mortal in the former case!
 *
 **************************************************************************/

SV* dbd_maxdb_db_FETCH_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv) {
#if defined(dTHR)
  dTHR;
#endif
  D_imp_drh_from_dbh;
  STRLEN kl;
  char *key = SvPV(keysv, kl);
  SV* result = Nullsv;
  dbd_maxdb_option opt;

  DBD_MAXDB_METHOD_ENTER (imp_dbh, dbd_maxdb_db_FETCH_attrib);
  if ((opt = (dbd_maxdb_option)analyzeKeyword(key, kl, dbh_optionTab, DBD_MAXDB_OPTIONTABLESIZE)) != dbd_maxdb_option_unknown){
    switch(opt)
    {
      case dbd_maxdb_option_autocommit:{
            result = (SQLDBC_Connection_getAutoCommit (imp_dbh->m_connection))?&PL_sv_yes:&PL_sv_no; 
            break;
      }
      case dbd_maxdb_option_isolationlevel:{
            result = sv_2mortal(newSViv(SQLDBC_Connection_getTransactionIsolation (imp_dbh->m_connection))); 
            break;
      }
      case dbd_maxdb_option_kernelversion:{
            result = sv_2mortal(newSViv(SQLDBC_Connection_getKernelVersion(imp_dbh->m_connection))); 
            break;
      }
      case dbd_maxdb_option_unicodedb:{
            result = (SQLDBC_Connection_isUnicodeDatabase (imp_dbh->m_connection))?&PL_sv_yes:&PL_sv_no; 
            break;
      }
      case dbd_maxdb_option_libraryversion :{
                char* msg = SQLDBC_Environment_getLibraryVersion (imp_drh->m_maxDBEnv);
                result = sv_2mortal(newSVpv(msg, strlen(msg)));
            break;
      }
      case dbd_maxdb_option_sqlmode:{
           char* msg = SQLDBC_ConnectProperties_getProperty( imp_dbh->m_connprop, "SQLMODE", "INTERNAL");  
           result = sv_2mortal(newSVpv(msg, strlen(msg)));
           break;
      }
      case dbd_maxdb_option_sdkversion:{
                char* msg = getSDKVersion();
                result = sv_2mortal(newSVpv(msg, strlen(msg)));
            break;
      }
    }
  }  
  DBD_MAXDB_METHOD_RETURN_SV (imp_dbh, dbd_maxdb_db_FETCH_attrib, result);
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_db_ping
 *
 *  Purpose: handles ping requests
 *
 *  Input:   dbh - connect handle
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/
int dbd_maxdb_db_ping(SV* dbh){
#if defined(dTHR)
  dTHR;
#endif
    D_imp_dbh(dbh);

    DBD_MAXDB_METHOD_ENTER (imp_dbh, dbd_maxdb_db_ping);    
    DBD_MAXDB_METHOD_RETURN (imp_dbh, dbd_maxdb_db_ping, (SQLDBC_Connection_isConnected (imp_dbh->m_connection)?1:0));
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_db_isunicode
 *
 *  Purpose: tests if database is unicode or not.
 *
 *  Input:   dbh - connect handle
 *
 *  Returns: TRUE if the database is an unicode database, FALSE otherwise; 
 *           do_error will be called in the latter case
 *
 **************************************************************************/
int dbd_maxdb_db_isunicode(SV* dbh){
#if defined(dTHR)
  dTHR;
#endif
    D_imp_dbh(dbh);
    
    DBD_MAXDB_METHOD_ENTER (imp_dbh, dbd_maxdb_db_isunicode);    
    DBD_MAXDB_METHOD_RETURN (imp_dbh, dbd_maxdb_db_isunicode, (SQLDBC_Connection_isUnicodeDatabase (imp_dbh->m_connection)?1:0));    
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_db_getSQLMode
 *
 *  Purpose: retrieves the SQL Mode of the underlaying database.
 *
 *  Input:   dbh - connect handle
 *
 *  Returns: the sqlmode
 *
 **************************************************************************/
SV* dbd_maxdb_db_getSQLMode(SV* dbh){
#if defined(dTHR)
  dTHR;
#endif
    D_imp_dbh(dbh);
    char* msg;
    SV* result;
    
    DBD_MAXDB_METHOD_ENTER (imp_dbh, dbd_maxdb_db_getSQLMode);    
    msg = SQLDBC_ConnectProperties_getProperty( imp_dbh->m_connprop, "SQLMODE", "INTERNAL");  
    result = sv_2mortal(newSVpv(msg, strlen(msg)));
    DBD_MAXDB_METHOD_RETURN_SV (imp_dbh, dbd_maxdb_db_getSQLMode, result);    
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_db_executeUpdate
 *
 *  Purpose: handles execute immediate command without parameters
 *
 *  Input:   dbh - connect handle
 *
 *  Returns: resultcount
 *
 **************************************************************************/
int dbd_maxdb_db_executeUpdate( SV *dbh, char *statement )
{
#if defined(dTHR)
  dTHR;
#endif
   D_imp_dbh(dbh);
   SQLDBC_Int4 rc=0;
   SQLDBC_Retcode retcode;
   
   DBD_MAXDB_METHOD_ENTER (imp_dbh, dbd_maxdb_db_executeUpdate);    

   if (!DBIc_ACTIVE(imp_dbh)) {
      dbd_maxdb_internal_error(dbh, DBD_ERR_SESSION_NOT_CONNECTED);
      DBD_MAXDB_METHOD_RETURN (imp_dbh, dbd_maxdb_db_executeUpdate, DBD_MAXDB_ERROR_RETVAL);  
   }

   if (!imp_dbh->m_stmt){
     imp_dbh->m_stmt = SQLDBC_Connection_createStatement (imp_dbh->m_connection);
     if (! imp_dbh->m_stmt){
       dbd_maxdb_sqldbc_error(dbh, SQLDBC_Connection_getError(imp_dbh->m_connection));
       DBD_MAXDB_METHOD_RETURN (imp_dbh, dbd_maxdb_db_executeUpdate, DBD_MAXDB_ERROR_RETVAL);  
    } 
   }

   retcode = SQLDBC_Statement_executeASCII (imp_dbh->m_stmt, statement);
   if (retcode != SQLDBC_OK && retcode != SQLDBC_NO_DATA_FOUND){
     dbd_maxdb_sqldbc_error(dbh, SQLDBC_Statement_getError(imp_dbh->m_stmt));
     DBD_MAXDB_METHOD_RETURN (imp_dbh, dbd_maxdb_db_executeUpdate, DBD_MAXDB_ERROR_RETVAL);  
   } 

/*
//   if (SQLDBC_Statement_isQuery(imp_dbh->m_stmt)){
//     dbd_maxdb_internal_error(dbh, DBD_ERR_GENERATE_RESULTSET);
//     DBD_MAXDB_METHOD_RETURN (imp_dbh, dbd_maxdb_db_executeUpdate, DBD_MAXDB_ERROR_RETVAL);  
//   }
*/
   rc = SQLDBC_Statement_getRowsAffected (imp_dbh->m_stmt); 
   DBD_MAXDB_METHOD_RETURN (imp_dbh, dbd_maxdb_db_executeUpdate, (int)rc);    
}
/***************************************************************************
 *
 *  Name:    dbd_maxdb_st_prepare
 *
 *  Purpose: Called for preparing an SQL statement; our part of the
 *           statement handle constructor
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - drivers private statement handle data
 *           statement - pointer to string with SQL statement
 *           attribs - statement attributes, currently not in use
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_maxdb_st_prepare(SV* sth, imp_sth_t* imp_sth, char* statement, SV* attribs) {
#if defined(dTHR)
  dTHR;
#endif
  D_imp_dbh_from_sth;
  imp_sth->m_rowSetSize=1;
  imp_sth->m_rowSetSizeChanged=SQLDBC_TRUE;
  imp_sth->m_fetchSize=0;
  imp_sth->m_rsmd=NULL;
  imp_sth->m_paramMetadata=NULL;
  imp_sth->m_bindParms = NULL;
  imp_sth->m_rowNotFound= SQLDBC_FALSE;
  imp_sth->m_fetchBuf   = NULL;
  imp_sth->m_cols = NULL;
  imp_sth->m_hasOutValues= SQLDBC_FALSE;

  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_st_prepare); 

  if (!DBIc_ACTIVE(imp_dbh)) {
    dbd_maxdb_internal_error(sth, DBD_ERR_SESSION_NOT_CONNECTED);
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_prepare, SQLDBC_FALSE); 
  }

  if (!imp_sth->m_prepstmt){
    imp_sth->m_prepstmt = SQLDBC_Connection_createPreparedStatement (imp_dbh->m_connection);
    if (!imp_sth->m_prepstmt) {
      dbd_maxdb_internal_error(sth, DBD_ERR_INITIALIZATION_FAILED_S, "Cannot create prepared statement");
      DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_prepare, SQLDBC_FALSE); 
    }
  }
  if (SQLDBC_PreparedStatement_prepareASCII  (imp_sth->m_prepstmt, statement) != SQLDBC_OK) {
    dbd_maxdb_sqldbc_error(sth, SQLDBC_PreparedStatement_getError(imp_sth->m_prepstmt));
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_prepare, SQLDBC_FALSE); 
  }
  
  imp_sth->m_paramMetadata = SQLDBC_PreparedStatement_getParameterMetaData (imp_sth->m_prepstmt);
  if (!imp_sth->m_paramMetadata) {
    dbd_maxdb_internal_error(sth, DBD_ERR_INITIALIZATION_FAILED_S, "Cannot get parameter metadata");
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_prepare, SQLDBC_FALSE); 
  } else {
      SQLDBC_Int2 parcnt = DBIc_NUM_PARAMS (imp_sth) = SQLDBC_ParameterMetaData_getParameterCount (imp_sth->m_paramMetadata);
      if (parcnt) Newz(242, imp_sth->m_bindParms, parcnt, dbd_maxdb_bind_param);
  }

  imp_sth->m_rsmd=SQLDBC_PreparedStatement_getResultSetMetaData (imp_sth->m_prepstmt);
  if (SQLDBC_PreparedStatement_isQuery(imp_sth->m_prepstmt) &&  !imp_sth->m_rsmd) {
    dbd_maxdb_internal_error(sth, DBD_ERR_INITIALIZATION_FAILED_S, "Cannot get resultset metadata");
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_prepare, SQLDBC_FALSE); 
  }

  DBIc_IMPSET_on(imp_sth);
  DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_prepare, SQLDBC_TRUE); 
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_sqldbc_bind_parameters
 *
 *  Purpose: Called for preparing an SQL statement; our part of the
 *           statement handle constructor
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - drivers private statement handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/
static int dbd_maxdb_sqldbc_bind_parameters (SV* sth, imp_sth_t* imp_sth){
  int index, maxParam = DBIc_NUM_PARAMS(imp_sth);
  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_sqldbc_bind_parameters); 
    
  for (index=0; index < maxParam; index++){
    dbd_maxdb_bind_param *m_bindParms = &imp_sth->m_bindParms[index];
    STRLEN valLen = 0;    
    SV* svVal = m_bindParms->value;
    char* value;
    SQLDBC_Length *indicator = &(m_bindParms->indicator); 
    SQLDBC_Bool  terminate;
    
    if(svVal == NULL){
      dbd_maxdb_internal_error(sth, DBD_ERR_PARAMETER_NOT_SET_D, index+1);
      DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_sqldbc_bind_parameters, SQLDBC_FALSE); 
    }  
    if(SvROK(svVal)){
//    sv_dump(svVal);
      svVal = SvRV(svVal);
    }  
    if (referenceDefaultValue==svVal){
      *indicator = SQLDBC_DEFAULT_PARAM;
      value = NULL;
    } else if (! SvOK(svVal)){
      *indicator = SQLDBC_NULL_DATA;
      value = NULL;
    }else {
    	  switch (m_bindParms->hostType) {
   	      case SQLDBC_HOSTTYPE_INT1       : {
			      *indicator = 1;
			      value = SvPV(svVal, valLen);
                  *value -= 48;
			      valLen = 1;
			      terminate = SQLDBC_FALSE;
            break;
   	      
   	      } case SQLDBC_HOSTTYPE_BINARY  : {
			      
			      value = SvPV(svVal, valLen);
			      *indicator = valLen;
   	              valLen = SvLEN (svVal);
			      terminate = SQLDBC_FALSE;
            break;
            
          } default : {
			      *indicator = SQLDBC_NTS;
			      value = SvPV(svVal, valLen);
			      valLen = SvLEN (svVal);
			      terminate = SQLDBC_TRUE;
			      break;    
          } 
       }
    }
    if (SQLDBC_PreparedStatement_bindParameter (imp_sth->m_prepstmt,
                                                index+1,
                                                m_bindParms->hostType,
                                                value,
                                                indicator,
                                                valLen,
                                                terminate) != SQLDBC_OK) {
      dbd_maxdb_sqldbc_error(sth, SQLDBC_PreparedStatement_getError(imp_sth->m_prepstmt));
      DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_sqldbc_bind_parameters, SQLDBC_FALSE); 
    }       
  } 
  DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_sqldbc_bind_parameters, SQLDBC_TRUE); 
}

/***************************************************************************
 *
 *  Name:    dbd_st_finish
 *
 *  Purpose: Called for freeing a mysql result
 *
 *  Input:   sth - statement handle being finished
 *           imp_sth - drivers private statement handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error() will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_maxdb_st_finish(SV* sth, imp_sth_t* imp_sth) {
#if defined (dTHR)
  dTHR;
#endif
  
  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_st_finish); 
  if (DBIc_ACTIVE(imp_sth)) {
    if (!imp_sth->m_prepstmt) {
      dbd_maxdb_internal_error(sth, DBD_ERR_INITIALIZATION_FAILED_S, "No prepared statement");
      DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_finish, SQLDBC_FALSE); 
    }
    if (SQLDBC_Statement_isQuery ((SQLDBC_Statement *) imp_sth->m_prepstmt)) {
      if (imp_sth->m_resultset) {
        SQLDBC_ResultSet_close (imp_sth->m_resultset);
        imp_sth->m_resultset = 0;
        imp_sth->m_rsmd=NULL;
        imp_sth->m_paramMetadata=NULL;
        imp_sth->m_hasOutValues= SQLDBC_FALSE;
        
        Safefree(imp_sth->m_fetchBuf);
        imp_sth->m_fetchBuf=NULL;        
        Safefree(imp_sth->m_cols);
        imp_sth->m_cols=NULL;
      }
    }
    DBIc_ACTIVE_off(imp_sth);
  }
  DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_finish, SQLDBC_TRUE); 
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_registerResultSet
 *
 *  Purpose: Called from within the fetch method to describe the result
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - our part of the statement handle, there's no
 *               need for supplying both; Tim just doesn't remove it
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/
static int dbd_maxdb_registerResultSet(SV* sth, imp_sth_t* imp_sth){
#if defined(dTHR)
  dTHR;
#endif
  SQLDBC_Int4 column, allColumnsLength=0;
  SQLDBC_UInt2 colcnt = DBIc_NUM_FIELDS(imp_sth);

  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_registerResultSet); 
  
  if (imp_sth->m_cols){
    /*already registered*/
    return SQLDBC_TRUE;
  } 
   
  if (!imp_sth->m_rsmd) {
    dbd_maxdb_internal_error(sth, DBD_ERR_INITIALIZATION_FAILED_S, "Missing resultset meta data");
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_registerResultSet, SQLDBC_FALSE); 
  }

  /*get sum of all columns length*/
  for (column = 1; column <= colcnt; column++) {
    int collen;
    switch (SQLDBC_ResultSetMetaData_getColumnType (imp_sth->m_rsmd, column)) {
        case SQLDBC_SQLTYPE_STRB          :
        case SQLDBC_SQLTYPE_LONGB         : 
        case SQLDBC_SQLTYPE_STRA          :
        case SQLDBC_SQLTYPE_STRE          :
        case SQLDBC_SQLTYPE_LONGA         :
        case SQLDBC_SQLTYPE_LONGE         : 
        case SQLDBC_SQLTYPE_STRUNI        :
        case SQLDBC_SQLTYPE_LONGUNI       : {
          collen = DBIc_LongReadLen(imp_sth); 
          break;
        }
        case SQLDBC_SQLTYPE_FIXED         :
        case SQLDBC_SQLTYPE_NUMBER        :
        case SQLDBC_SQLTYPE_SMALLINT      :
        case SQLDBC_SQLTYPE_INTEGER       : {
          collen = SQLDBC_ResultSetMetaData_getColumnLength (imp_sth->m_rsmd, column) + 2;
          break;
        }
        case SQLDBC_SQLTYPE_BOOLEAN       : {
          collen = 1;    
          break;
        } 
        case SQLDBC_SQLTYPE_FLOAT         :
        case SQLDBC_SQLTYPE_VFLOAT        : {
          collen = SQLDBC_ResultSetMetaData_getColumnLength (imp_sth->m_rsmd, column) + 6; /*-[0-9]+.[0-9]+E[-][0-9][0-9]*/
          break;
        }
        default : {
          collen = SQLDBC_ResultSetMetaData_getColumnLength (imp_sth->m_rsmd, column);
          break;
        }
     } 
     collen++;
     allColumnsLength += ALIGN(collen);
  }     
  
  /*alloc fetch buffer*/
  Newz(101, imp_sth->m_fetchBuf, allColumnsLength, char);
  Newz(101, imp_sth->m_cols, colcnt, dbd_maxdb_bind_column);
   
  /*bind columns*/
  allColumnsLength = 0;
  for (column = 1; column <= colcnt; column++) {
    dbd_maxdb_bind_column *m_col = &imp_sth->m_cols[column-1];
    SQLDBC_Int4    ColumnLength = SQLDBC_ResultSetMetaData_getColumnLength (imp_sth->m_rsmd, column);
    SQLDBC_SQLType   ColumnType = SQLDBC_ResultSetMetaData_getColumnType (imp_sth->m_rsmd, column);
    m_col->hostType = SQLDBC_HOSTTYPE_ASCII;
    m_col->chopBlanks = SQLDBC_FALSE;
    
    switch (ColumnType) {
        case SQLDBC_SQLTYPE_FIXED         :
        case SQLDBC_SQLTYPE_NUMBER        :
        case SQLDBC_SQLTYPE_SMALLINT      :
        case SQLDBC_SQLTYPE_INTEGER       : {
        ColumnLength += 2;
        break;
        }
        case SQLDBC_SQLTYPE_FLOAT         :
        case SQLDBC_SQLTYPE_VFLOAT        : {
        ColumnLength += 6; 
        break;
        }
        case SQLDBC_SQLTYPE_CHB           :
        case SQLDBC_SQLTYPE_ROWID         :
        case SQLDBC_SQLTYPE_VARCHARB      : {
        m_col->hostType = SQLDBC_HOSTTYPE_BINARY;
        break;
        }
        case SQLDBC_SQLTYPE_CHA           :               
        case SQLDBC_SQLTYPE_CHE           :
        case SQLDBC_SQLTYPE_UNICODE       :{
        m_col->chopBlanks = SQLDBC_TRUE;
        break; 
        }

        case SQLDBC_SQLTYPE_VARCHARA      :
        case SQLDBC_SQLTYPE_VARCHARE      :
        case SQLDBC_SQLTYPE_DATE          :
        case SQLDBC_SQLTYPE_TIME          :
        case SQLDBC_SQLTYPE_TIMESTAMP     : {
        break;
        }
        case SQLDBC_SQLTYPE_VARCHARUNI    : {
        break;
        }
        case SQLDBC_SQLTYPE_BOOLEAN       : {
        m_col->hostType =   SQLDBC_HOSTTYPE_INT1;
        ColumnLength = 1;    
        break;
        }
        case SQLDBC_SQLTYPE_ABAPTABHANDLE : {
        break;
        }
        case SQLDBC_SQLTYPE_STRB          :
        case SQLDBC_SQLTYPE_LONGB         : {
        m_col->hostType = SQLDBC_HOSTTYPE_BINARY;
        ColumnLength = DBIc_LongReadLen(imp_sth);
        break;
        }
        case SQLDBC_SQLTYPE_STRA          :
        case SQLDBC_SQLTYPE_STRE          :
        case SQLDBC_SQLTYPE_LONGA         :
        case SQLDBC_SQLTYPE_LONGE         : 
        case SQLDBC_SQLTYPE_STRUNI        :
        case SQLDBC_SQLTYPE_LONGUNI       : {
        m_col->hostType = SQLDBC_HOSTTYPE_ASCII;
        ColumnLength = DBIc_LongReadLen(imp_sth);
        break;
        }
    }
    
    m_col->buf = &imp_sth->m_fetchBuf[allColumnsLength];
    m_col->bufLen = ColumnLength+1;
    if (SQLDBC_ResultSet_bindColumn (imp_sth->m_resultset,
                                     column,
                                     m_col->hostType,
                                     m_col->buf,
                                     &m_col->indicator,
                                     m_col->bufLen,
                                     SQLDBC_TRUE) != SQLDBC_OK) {
      dbd_maxdb_sqldbc_error(sth, SQLDBC_ResultSet_getError(imp_sth->m_resultset));
      DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_registerResultSet, SQLDBC_FALSE); 
    }
    allColumnsLength += ALIGN( m_col->bufLen);
  }
  DBIc_IMPSET_on(imp_sth);
  DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_registerResultSet, SQLDBC_TRUE); 
}

int dbd_maxdb_st_execute(SV* sth, imp_sth_t* imp_sth) {
#if defined(dTHR)
  dTHR;
#endif
  int erg = SQLDBC_TRUE;
  D_imp_dbh_from_sth;
  SQLDBC_Retcode exec_rc;

  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_st_execute); 

  if (DBIc_ACTIVE(imp_sth)) {
    dbd_st_finish(sth, imp_sth);
  }
    
  if (!imp_sth->m_prepstmt) {
    dbd_maxdb_internal_error(sth, DBD_ERR_STATEMENT_NOT_PREPARED);
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_execute, DBD_MAXDB_ERROR_RETVAL); 
  } 

  if (! dbd_maxdb_sqldbc_bind_parameters (sth, imp_sth)){
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_execute, DBD_MAXDB_ERROR_RETVAL); 
  }
  
  exec_rc = SQLDBC_PreparedStatement_executeASCII (imp_sth->m_prepstmt); 
  if ( exec_rc != SQLDBC_OK && exec_rc != SQLDBC_NO_DATA_FOUND) {
    dbd_maxdb_sqldbc_error(sth, SQLDBC_PreparedStatement_getError(imp_sth->m_prepstmt)) ;
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_execute, DBD_MAXDB_ERROR_RETVAL); 
  }
  
  if (SQLDBC_PreparedStatement_isQuery (imp_sth->m_prepstmt)) {
    imp_sth->m_resultset = SQLDBC_PreparedStatement_getResultSet  (imp_sth->m_prepstmt);
    if (!imp_sth->m_resultset) {
      dbd_maxdb_sqldbc_error(sth, SQLDBC_PreparedStatement_getError(imp_sth->m_prepstmt)) ;
      DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_execute, DBD_MAXDB_ERROR_RETVAL); 
    }
    if (!imp_sth->m_rsmd){
      imp_sth->m_rsmd = SQLDBC_PreparedStatement_getResultSetMetaData(imp_sth->m_prepstmt);
      if (!imp_sth->m_rsmd) {
        dbd_maxdb_internal_error(sth, DBD_ERR_INITIALIZATION_FAILED_S, "Cannot get resultset metadata");
        DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_execute, DBD_MAXDB_ERROR_RETVAL); 
      }
    }
    DBIc_NUM_FIELDS(imp_sth) = SQLDBC_ResultSetMetaData_getColumnCount (imp_sth->m_rsmd);
    
    if (exec_rc == SQLDBC_NO_DATA_FOUND){
      imp_sth->m_rowNotFound= SQLDBC_TRUE;
      DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_execute, 0); 
    }

    if(!dbd_maxdb_registerResultSet(sth, imp_sth)){
      DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_execute, DBD_MAXDB_ERROR_RETVAL); 
    }
    
    DBIc_ACTIVE_on(imp_sth);
    
  } else {
    if (imp_sth->m_hasOutValues= SQLDBC_TRUE){
      /*handling out parameters*/
       int paramIndex;
       I32 paramcnt = DBIc_NUM_PARAMS(imp_sth);
  
       for (paramIndex = 0; paramIndex < paramcnt; ++paramIndex) {
         ParameterMode pMode = SQLDBC_ParameterMetaData_getParameterMode  (imp_sth->m_paramMetadata, paramIndex+1);  
         if (pMode == parameterModeInOut || pMode == parameterModeOut){ 
           dbd_maxdb_bind_param *m_param = &imp_sth->m_bindParms[paramIndex];
           char* buf;
           STRLEN bufLen;
           
           if (m_param->indicator == SQLDBC_NULL_DATA) {
             SvOK_off(m_param->value);
             m_param->indicator = SQLDBC_NTS;
             continue;
           }
           buf = SvPV(m_param->value, bufLen);
           bufLen = SvLEN(m_param->value);
           
          
           switch(m_param->hostType) {
              case SQLDBC_HOSTTYPE_INT1:{
                *buf += 48;
                m_param->indicator = 1;
                break;
              }  
              default:{
                 if ( m_param->indicator >= (SQLDBC_Length)bufLen) { 
                   dbd_maxdb_internal_error(sth, DBD_ERR_LONG_COLUMN_TRUNCATED_D, paramIndex+1);
                   DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_execute, DBD_MAXDB_ERROR_RETVAL); 
                 }
                 if (m_param->indicator >= 0){
                   while (m_param->indicator >= 0 && buf[m_param->indicator]==' ')  --m_param->indicator;
                 }
                break;
              }
           }
           

           SvCUR_set(m_param->value, (STRLEN) m_param->indicator); 
           *SvEND(m_param->value) = '\0';
           m_param->indicator = SQLDBC_NTS;
         }      
       }
     }  
     erg = SQLDBC_PreparedStatement_getRowsAffected (imp_sth->m_prepstmt); 
  }

  DBIc_IMPSET_on(imp_sth);
  DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_execute, erg); 
}


/***************************************************************************
 *
 *  Name:    dbd_maxdb_st_fetch
 *
 *  Purpose: Called for fetching a result row
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - drivers private statement handle data
 *
 *  Returns: array of columns; the array is allocated by DBI via
 *           DBIS->get_fbav(imp_sth), even the values of the array
 *           are prepared, we just need to modify them appropriately
 *
 **************************************************************************/
AV* dbd_maxdb_st_fetch(SV* sth, imp_sth_t* imp_sth) {
#if defined(dTHR)
  dTHR;
#endif
  int colIndex;
  SQLDBC_Retcode rc;
  SQLDBC_RowSet *rowset = 0;
  int ChopBlanks = 1; /* always chop blanks DBIc_has(imp_sth, DBIcf_ChopBlanks); */
  AV *av;
  I32 colcnt;
  
  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_st_fetch); 

  if (imp_sth->m_rowNotFound){
    DBD_MAXDB_METHOD_RETURN_AV(imp_sth, dbd_maxdb_st_fetch, Nullav); 
  }
  
  if (!DBIc_ACTIVE(imp_sth) || !imp_sth->m_resultset) {
    dbd_maxdb_internal_error(sth, DBD_ERR_NO_RESULTSET);
    DBD_MAXDB_METHOD_RETURN_AV(imp_sth, dbd_maxdb_st_fetch, Nullav); 
  }
  
  if (imp_sth->m_rowSetSizeChanged == SQLDBC_TRUE){
    SQLDBC_ResultSet_setRowSetSize (imp_sth->m_resultset, imp_sth->m_rowSetSize);
    imp_sth->m_rowSetSizeChanged =  SQLDBC_FALSE;  
  }
  if ((rc = SQLDBC_ResultSet_next (imp_sth->m_resultset)) == SQLDBC_NO_DATA_FOUND) {
    dbd_st_finish (sth, imp_sth);
    DBD_MAXDB_METHOD_RETURN_AV(imp_sth, dbd_maxdb_st_fetch, Nullav); 
  } else if (rc == SQLDBC_NOT_OK) {
    dbd_maxdb_sqldbc_error(sth, SQLDBC_ResultSet_getError(imp_sth->m_resultset)) ;
    DBD_MAXDB_METHOD_RETURN_AV(imp_sth, dbd_maxdb_st_fetch, Nullav); 
  }

  rowset = SQLDBC_ResultSet_getRowSet (imp_sth->m_resultset);
  
  if ((rc = SQLDBC_RowSet_fetch (rowset)) == SQLDBC_NOT_OK) {
    dbd_maxdb_sqldbc_error(sth, SQLDBC_RowSet_getError(rowset)) ;
    DBD_MAXDB_METHOD_RETURN_AV(imp_sth, dbd_maxdb_st_fetch, Nullav); 
  }

  av = DBIc_DBISTATE(imp_sth)->get_fbav(imp_sth);
  colcnt = av_len(av)+1;
  
  for (colIndex = 0; colIndex < colcnt; ++colIndex) {
    dbd_maxdb_bind_column *m_col = &imp_sth->m_cols[colIndex];
    SV *sv = AvARRAY(av)[colIndex];
    
    if (m_col->indicator == SQLDBC_NULL_DATA) {
      SvOK_off(sv);
      continue;
    }

    if ( m_col->indicator >= m_col->bufLen) { 
      if (!DBIc_has(imp_sth, DBIcf_LongTruncOk)) {
        dbd_maxdb_internal_error(sth, DBD_ERR_LONG_COLUMN_TRUNCATED_D, colIndex+1);
        DBD_MAXDB_METHOD_RETURN_AV(imp_sth, dbd_maxdb_st_fetch, Nullav); 
      }
      m_col->indicator = m_col->bufLen-1;
    }

    if (m_col->chopBlanks && ChopBlanks && m_col->indicator > 0){
      char *buf = m_col->buf;
      m_col->buf[m_col->bufLen-1]='\0'; /*terminate string*/
      while (m_col->indicator && buf[m_col->indicator-1]==' ')
        --m_col->indicator;
    }
    switch(m_col->hostType) {
      case SQLDBC_HOSTTYPE_INT1:{
        sv_setiv(sv, (int)*(m_col->buf));
        break;
      }  
      default:{
        sv_setpvn(sv, m_col->buf, m_col->indicator);
        break;
      }
    }
    m_col->indicator = 0;
  }
  DBD_MAXDB_METHOD_RETURN_AV(imp_sth, dbd_maxdb_st_fetch, av); 
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_st_destroy
 *
 *  Purpose: Our part of the statement handles destructor
 *
 *  Input:   sth - statement handle being destroyed
 *           imp_sth - drivers private statement handle data
 *
 *  Returns: Nothing
 *
 **************************************************************************/

void dbd_maxdb_st_destroy(SV* sth, imp_sth_t* imp_sth) {
#if defined(dTHR)
  dTHR;
#endif
  D_imp_dbh_from_sth;

  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_st_destroy); 
 
  imp_sth->m_rowNotFound= SQLDBC_FALSE;
  if (imp_sth->m_bindParms){
    dbd_maxdb_delete_params(imp_sth->m_bindParms, DBIc_NUM_PARAMS (imp_sth)); 
    imp_sth->m_bindParms = NULL;  
  }
 
  if (imp_sth->m_fetchBuf) {
    Safefree(imp_sth->m_fetchBuf);
    imp_sth->m_fetchBuf=NULL;
  }
    
  if (imp_sth->m_cols) {
   Safefree(imp_sth->m_cols);
   imp_sth->m_cols=NULL;
  }  

  if ( DBIc_ACTIVE(imp_dbh) && imp_dbh->m_connection != NULL){ 
    SQLDBC_Connection_releaseStatement (imp_dbh->m_connection, (SQLDBC_Statement *)imp_sth->m_prepstmt);
  }
  imp_sth->m_prepstmt = NULL;

  DBIc_off(imp_sth, DBIcf_IMPSET);
  DBD_MAXDB_METHOD_EXIT(imp_sth, dbd_maxdb_st_destroy); 
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_st_STORE_attrib
 *
 *  Purpose: Modifies a statement handles attributes; we currently
 *           support just nothing
 *
 *  Input:   sth - statement handle being destroyed
 *           imp_sth - drivers private statement handle data
 *           keysv - attribute name
 *           valuesv - attribute value
 *
 *  Returns: TRUE for success, FALSE otrherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/

/* ResultSetType handling */
static dbd_maxdb_cmdKeywordTable ResultSetType_optionTab [ ]= {
      { SQLDBC_Statement_ResultSetType_FORWARD_ONLY,         {"FORWARD_ONLY",sizeof("FORWARD_ONLY")-1}},
      { SQLDBC_Statement_ResultSetType_SCROLL_INSENSITIVE,   {"SCROLL_INSENSITIVE",sizeof("SCROLL_INSENSITIVE")-1}},
      { SQLDBC_Statement_ResultSetType_SCROLL_SENSITIVE,     {"SCROLL_SENSITIVE",sizeof("SCROLL_SENSITIVE")-1}},
    };
#define RESULTSETTYPE_OPTIONTABLESIZE  (sizeof(ResultSetType_optionTab) /sizeof(dbd_maxdb_cmdKeywordTable))

static SQLDBC_Statement_ResultSetType String2ResultSetType (char* value, SQLDBC_Int4 vlen){
   return (SQLDBC_Statement_ResultSetType) analyzeKeyword(value, vlen, ResultSetType_optionTab, RESULTSETTYPE_OPTIONTABLESIZE);
}

static char* ResultSetType2String(SQLDBC_Statement_ResultSetType type){
   int i;
   for (i=0; i<RESULTSETTYPE_OPTIONTABLESIZE; i++){
     if (type == ResultSetType_optionTab[i].entry ){
       return ResultSetType_optionTab[i].keyword.rawString;
     }
   }
   return "unknown ResultSetType";
}    

/* ConcurrencyType handling */
static dbd_maxdb_cmdKeywordTable ConcurrencyType_optionTab [ ]= {
      { SQLDBC_Statement_ConcurrencyType_CONCUR_READ_ONLY,     {"CONCUR_READ_ONLY",sizeof("CONCUR_READ_ONLY")-1}},
      { SQLDBC_Statement_ConcurrencyType_CONCUR_UPDATABLE ,    {"CONCUR_UPDATABLE",sizeof("CONCUR_UPDATABLE")-1}},
    };

#define CONCURRENCYTYPE_OPTIONTABLESIZE  (sizeof(ConcurrencyType_optionTab) /sizeof(dbd_maxdb_cmdKeywordTable))

static SQLDBC_Statement_ConcurrencyType String2ConcurrencyType (char* value, SQLDBC_Int4 vlen){
   return (SQLDBC_Statement_ConcurrencyType) analyzeKeyword(value, vlen, ConcurrencyType_optionTab, CONCURRENCYTYPE_OPTIONTABLESIZE);
}

static char* ConcurrencyType2String(SQLDBC_Statement_ConcurrencyType type){
   int i;
   for (i=0; i<CONCURRENCYTYPE_OPTIONTABLESIZE; i++){
     if (type == ConcurrencyType_optionTab[i].entry ){
       return ConcurrencyType_optionTab[i].keyword.rawString;
     }
   }
   return "unknown ConcurrencyType";
}

typedef enum {    
  sth_maxdb_option_CursorName     =  1,
  sth_maxdb_option_FetchSize      =  2,
  sth_maxdb_option_MaxRows        =  3,
  sth_maxdb_option_ColNames       =  4,
  sth_maxdb_option_ColNames_lc    =  5,
  sth_maxdb_option_ColNames_uc    =  6,
  sth_maxdb_option_ColNullables   =  7,
  sth_maxdb_option_ColNumOfFields =  8,
  sth_maxdb_option_ParNumOfParams =  9,
  sth_maxdb_option_ColPrecisions  =  10,
  sth_maxdb_option_ResultSetConcurrency =  11,
  sth_maxdb_option_ResultSetType  =  12,
  sth_maxdb_option_RowsAffected   =  13,
  sth_maxdb_option_RowsInCache    =  14,
  sth_maxdb_option_RowSetSize     =  15,
  sth_maxdb_option_ColScales      =  16,
  sth_maxdb_option_TableName      =  17,
  sth_maxdb_option_ColTypes       =  18,
  sth_maxdb_option_unknown        =  -1
}sth_maxdb_option;

static dbd_maxdb_cmdKeywordTable sth_optionTab [ ]= {
      { sth_maxdb_option_CursorName,               {"CURSORNAME",sizeof("CURSORNAME")-1}},
      { sth_maxdb_option_FetchSize,                {"MAXDB_FETCHSIZE",sizeof("MAXDB_FETCHSIZE")-1}},
      { sth_maxdb_option_MaxRows,                  {"MAXDB_MAXROWS",sizeof("MAXDB_MAXROWS")-1}},
      { sth_maxdb_option_ResultSetConcurrency,     {"MAXDB_RESULTSETCONCURRENCY",sizeof("MAXDB_RESULTSETCONCURRENCY")-1}},
      { sth_maxdb_option_ResultSetType,            {"MAXDB_RESULTSETTYPE",sizeof("MAXDB_RESULTSETTYPE")-1}},
      { sth_maxdb_option_RowsAffected,             {"MAXDB_ROWSAFFECTED",sizeof("MAXDB_ROWSAFFECTED")-1}},
      { sth_maxdb_option_RowSetSize,               {"MAXDB_ROWSETSIZE",sizeof("MAXDB_ROWSETSIZE")-1}},      
      { sth_maxdb_option_TableName,                {"MAXDB_TABLENAME",sizeof("MAXDB_TABLENAME")-1}},
      { sth_maxdb_option_ColNames,                 {"NAME",sizeof("NAME")-1}},
      { sth_maxdb_option_ColNames_lc,              {"NAME_LC",sizeof("NAME_LC")-1}},
      { sth_maxdb_option_ColNames_uc,              {"NAME_UC",sizeof("NAME_UC")-1}},
      { sth_maxdb_option_ColNullables,             {"NULLABLE",sizeof("NULLABLE")-1}},
      { sth_maxdb_option_ColNumOfFields,           {"NUM_OF_FIELDS",sizeof("NUM_OF_FIELDS")-1}},
      { sth_maxdb_option_ParNumOfParams,           {"NUM_OF_PARAMS",sizeof("NUM_OF_PARAMS")-1}},
      { sth_maxdb_option_ColPrecisions,            {"PRECISION",sizeof("PRECISION")-1}},

      { sth_maxdb_option_RowsInCache,              {"ROWSINCACHE",sizeof("ROWSINCACHE")-1}},
      { sth_maxdb_option_ColScales,                {"SCALE",sizeof("SCALE")-1}},
      { sth_maxdb_option_ColTypes,                 {"TYPE",sizeof("TYPE")-1}},
    };

#define STH_MAXDB_OPTIONTABLESIZE  (sizeof(sth_optionTab) /sizeof(dbd_maxdb_cmdKeywordTable))
    
int dbd_maxdb_st_STORE_attrib(SV* sth, imp_sth_t* imp_sth, SV* keysv, SV* valuesv) {
#if defined(dTHR)
  dTHR;
#endif
    STRLEN kl,vl;
    char *key = SvPV(keysv,kl);
    sth_maxdb_option opt;
    int erg;

    DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_st_STORE_attrib); 

    if (DBIc_DBISTATE(imp_sth)->debug >= 3)
        PerlIO_printf(DBIc_LOGPIO(imp_sth), "          attrib %s => %s\n",
                      key, SvPV(valuesv, vl));
                      
    if ((opt = (sth_maxdb_option)analyzeKeyword(key, kl, sth_optionTab, STH_MAXDB_OPTIONTABLESIZE)) == sth_maxdb_option_unknown){
      erg = SQLDBC_FALSE;
    } else {
      switch(opt)
      {
          case sth_maxdb_option_ResultSetConcurrency:{
             SQLDBC_Statement_ConcurrencyType rsetSetCon;
             if(!SvIOK (valuesv)){
               char* val = SvPV(valuesv, vl);
               rsetSetCon = String2ConcurrencyType(val, vl);
               if (rsetSetCon == sth_maxdb_option_unknown){
                 dbd_maxdb_internal_error(sth, DBD_ERR_WRONG_PARAMETER_S, "resultset concurrency type must be CONCUR_UPDATABLE or CONCUR_READ_ONLY");
                 break;
               }  
             } else {
                rsetSetCon = (SQLDBC_Statement_ConcurrencyType) SvIV(valuesv);
             }
             SQLDBC_PreparedStatement_setResultSetConcurrencyType (imp_sth->m_prepstmt, rsetSetCon);  
             erg = SQLDBC_TRUE;
             break;
          }
          case sth_maxdb_option_ResultSetType:{
             SQLDBC_Statement_ResultSetType rsetType;
             if(!SvIOK (valuesv)){
               char* val = SvPV(valuesv, vl);
               rsetType = String2ResultSetType(val, vl);
               if (rsetType == sth_maxdb_option_unknown){
                 dbd_maxdb_internal_error(sth, DBD_ERR_WRONG_PARAMETER_S, "resultset type must be a number value");
                 break;
               }  
             } else {
                 rsetType = (SQLDBC_Statement_ResultSetType) SvIV(valuesv);
             }
             SQLDBC_PreparedStatement_setResultSetType(imp_sth->m_prepstmt, rsetType);  
             erg = SQLDBC_TRUE;
             break;
          }
          case sth_maxdb_option_FetchSize:{
             int fetchsize;
             if(!SvIOK (valuesv)){
               dbd_maxdb_internal_error(sth, DBD_ERR_WRONG_PARAMETER_S, "resultset concurrency type must be a number value");
               break;
             }
             fetchsize = SvIV(valuesv);
             if (fetchsize <= 0 && fetchsize > 32768){
               dbd_maxdb_internal_error(sth, DBD_ERR_WRONG_PARAMETER_S, "fetchsize must be a value between 1 and 32768");
               break;
             }
             SQLDBC_PreparedStatement_setResultSetFetchSize (imp_sth->m_prepstmt, fetchsize);
             imp_sth->m_fetchSize =  fetchsize;  
             erg = SQLDBC_TRUE;
             break;
          }
          case sth_maxdb_option_RowSetSize:{
             int rowsetsize;
             if(!SvIOK (valuesv)){
               dbd_maxdb_internal_error(sth, DBD_ERR_WRONG_PARAMETER_S, "resultset concurrency type must be a number value");
               break;
             }
             rowsetsize = SvIV(valuesv);
             if (rowsetsize <= 0){
               dbd_maxdb_internal_error(sth, DBD_ERR_WRONG_PARAMETER_S, "rowsetsize must be greater than zero");
               break;
             }
             imp_sth->m_rowSetSize =  rowsetsize;  
             imp_sth->m_rowSetSizeChanged =  SQLDBC_TRUE;  
             erg = SQLDBC_TRUE;
             break;
          }
          case sth_maxdb_option_MaxRows:{
             int maxrows;
             if(!SvIOK (valuesv)){
               dbd_maxdb_internal_error(sth, DBD_ERR_WRONG_PARAMETER_S, "MaxRows must be a number value");
               break;
             }
             maxrows = SvIV(valuesv);
             if (maxrows <= 0){
               dbd_maxdb_internal_error(sth, DBD_ERR_WRONG_PARAMETER_S, "MaxRows must be greater than zero");
               break;
             }
             SQLDBC_PreparedStatement_setMaxRows (imp_sth->m_prepstmt, maxrows);
             erg = SQLDBC_TRUE;
             break;
          }
          case sth_maxdb_option_CursorName:{
             char* cursorname = SvPV(valuesv,kl);
             SQLDBC_PreparedStatement_setCursorName (imp_sth->m_prepstmt, cursorname, kl, SQLDBC_StringEncodingType_Encoding_Ascii) ;
             erg = SQLDBC_TRUE;
             break;
          }
       }
    }  
  DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_STORE_attrib, erg); 
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_st_FETCH_attrib
 *
 *  Purpose: Retrieves a statement handles attributes
 *
 *  Input:   sth - statement handle being destroyed
 *           imp_sth - drivers private statement handle data
 *           keysv - attribute name
 *
 *  Returns: NULL for an unknown attribute, "undef" for error,
 *           attribute value otherwise.
 *
 **************************************************************************/
SV* dbd_maxdb_st_FETCH_attrib(SV* sth, imp_sth_t* imp_sth, SV* keysv) {
#if defined(dTHR)
  dTHR;
#endif
  STRLEN kl;
  char *key = SvPV(keysv, kl);
  SV* result = NULL;
  sth_maxdb_option opt;
  D_imp_dbh_from_sth;

  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_st_FETCH_attrib); 

  if (DBIc_DBISTATE(imp_sth)->debug >= 3)
      PerlIO_printf(DBIc_LOGPIO(imp_sth), "          attrib %s \n", key);
                      
  if ((opt = (sth_maxdb_option)analyzeKeyword(key, kl, sth_optionTab, STH_MAXDB_OPTIONTABLESIZE)) != sth_maxdb_option_unknown){
    switch(opt)
    {
      case sth_maxdb_option_CursorName:{
              SQLDBC_Int2 cnameLen = imp_dbh->m_dbmd->getMaxCursorLength +1;
              char *cname = (char*) alloca(cnameLen); 
        SQLDBC_Length bufferLength;
        if( SQLDBC_PreparedStatement_getCursorName (
                          imp_sth->m_prepstmt, 
                          cname, 
                          SQLDBC_StringEncodingType_Encoding_Ascii, 
                          cnameLen, 
                          &bufferLength) != SQLDBC_OK){
               break;
        }
        result = sv_2mortal(newSVpv(cname, bufferLength));
        break;
      }
      case sth_maxdb_option_FetchSize:{
        result = (imp_sth->m_fetchSize)?sv_2mortal(newSViv(imp_sth->m_fetchSize)):&PL_sv_undef;
        break;
      }
      case sth_maxdb_option_MaxRows:{
        result = sv_2mortal(newSVuv(SQLDBC_PreparedStatement_getMaxRows(imp_sth->m_prepstmt))); 
        break;
      }
      case sth_maxdb_option_ResultSetConcurrency:{
        char* rsetConType = ConcurrencyType2String(SQLDBC_PreparedStatement_getResultSetConcurrencyType(imp_sth->m_prepstmt));
        result = sv_2mortal(newSVpv(rsetConType, strlen(rsetConType)));
        break;
      }
      case sth_maxdb_option_ResultSetType:{
        char* rsetType = ResultSetType2String(SQLDBC_PreparedStatement_getResultSetType(imp_sth->m_prepstmt));
        result = sv_2mortal(newSVpv(rsetType, strlen(rsetType)));
        break;
      }
      case sth_maxdb_option_RowsAffected:{
        result = sv_2mortal(newSViv(SQLDBC_PreparedStatement_getRowsAffected(imp_sth->m_prepstmt))); 
        break;
      }
      case sth_maxdb_option_RowSetSize:{
        result = (imp_sth->m_rowSetSize) ? sv_2mortal(newSViv(imp_sth->m_rowSetSize)):&PL_sv_undef;
        break;
      }
      case sth_maxdb_option_ColNumOfFields:{
        result = sv_2mortal(newSViv(SQLDBC_ResultSetMetaData_getColumnCount (imp_sth->m_rsmd))); 
        break;
      }
      case sth_maxdb_option_ParNumOfParams:{
        result = sv_2mortal(newSViv(SQLDBC_ParameterMetaData_getParameterCount (imp_sth->m_paramMetadata))); 
        break;
      }
      case sth_maxdb_option_TableName:{
              SQLDBC_Int2 cnameLen = imp_dbh->m_dbmd->getMaxCursorLength +1;
              char *cname = (char*) alloca(cnameLen); 
        SQLDBC_Length bufferLength;
        if( SQLDBC_PreparedStatement_getTableName( 
                          imp_sth->m_prepstmt,
                          cname,  
                          SQLDBC_StringEncodingType_Encoding_Ascii, 
                          cnameLen, 
                          &bufferLength) != SQLDBC_OK){
             break;
        }
        if (!*cname){
          result=&PL_sv_undef;
        } else {
          result = sv_2mortal(newSVpv(cname, bufferLength));
        }
        break;
      }
      case sth_maxdb_option_ColNames_lc:
      case sth_maxdb_option_ColNames_uc:
      case sth_maxdb_option_ColNames:{                  /* NAME */
        SQLDBC_Int2 i, colcnt = SQLDBC_ResultSetMetaData_getColumnCount (imp_sth->m_rsmd); 
        SQLDBC_Length colnamelen;
        AV *av = newAV();
        SQLDBC_Int2 cnameLen = imp_dbh->m_dbmd->getMaxColumnnameLength +1;
        char *cname = (char*) alloca(cnameLen); 
        result = newRV(sv_2mortal((SV*)av));
        for(i = 1; i<=colcnt; i++) {
          if (SQLDBC_ResultSetMetaData_getColumnName (imp_sth->m_rsmd,
                                                      i,
                                                      cname,
                                                      SQLDBC_StringEncodingType_Encoding_Ascii,
                                                      cnameLen,
                                                      &colnamelen) != SQLDBC_OK) {
            dbd_maxdb_internal_error(sth, DBD_ERR_CANNOT_GET_COLUMNNAME_D, i);
            break;
          }
          if (DBIc_DEBUGIV(imp_sth) > 8) {
            PerlIO_printf(DBIc_LOGPIO(imp_sth), "    Colname %d => %s\n",i, cname);
            PerlIO_flush(DBIc_LOGPIO(imp_sth));
          }
          if (opt == sth_maxdb_option_ColNames_lc){
            int k;
            for (k=0; k < colnamelen; k++) cname[k]= tolower(cname[k]);
          }else if (opt == sth_maxdb_option_ColNames_uc){
            int k;
            for (k=0; k < colnamelen; k++) cname[k]= toupper(cname[k]);          
          }  
          av_store(av, i-1, newSVpv(cname, colnamelen));
        }
        break;
      }
      case sth_maxdb_option_ColNullables:{                      /* NULLABLE */
        SQLDBC_Int2 i, colcnt = SQLDBC_ResultSetMetaData_getColumnCount (imp_sth->m_rsmd); 
            AV *av = newAV();
              result = newRV(sv_2mortal((SV*)av));
              for(i=1; i <= colcnt; i++){ 
                int nullable;
                switch (SQLDBC_ResultSetMetaData_isNullable(imp_sth->m_rsmd, i)){
                  case (columnNoNulls):{
                    nullable=0;
                    break;
                  }
                  case (columnNullable):{
                    nullable=1;
                    break;
                  }
                  case (columnNullableUnknown):{}
            default : {
                    nullable=2;
                  }
                }
          if (DBIc_DEBUGIV(imp_sth) > 8) {
                PerlIO_printf(DBIc_LOGPIO(imp_sth), "    Coltype %d => %d\n",
                                                  i, nullable);
            PerlIO_flush(DBIc_LOGPIO(imp_sth));
                }
          av_store(av, i-1, newSViv(nullable));
                    }
            break;
      }  
      case sth_maxdb_option_ColTypes:{                  /* TYPE */
        SQLDBC_Int2 i, colcnt = SQLDBC_ResultSetMetaData_getColumnCount (imp_sth->m_rsmd); 
            AV *av = newAV();
              result = newRV(sv_2mortal((SV*)av));
              for(i=1; i <= colcnt; i++){ 
                int sqltype = SQLDBC_SQLType2ODBCType(SQLDBC_ResultSetMetaData_getColumnType (imp_sth->m_rsmd, i)); 
          if (DBIc_DEBUGIV(imp_sth) > 8) {
                PerlIO_printf(DBIc_LOGPIO(imp_sth), "    Coltype %d => %d\n",
                                                  i, sqltype);
            PerlIO_flush(DBIc_LOGPIO(imp_sth));
                }
          av_store(av, i-1, newSViv(sqltype));
                    }
            break;
      }  
      case sth_maxdb_option_ColPrecisions:{                     /* PRECISION */
        SQLDBC_Int2 i, colcnt = SQLDBC_ResultSetMetaData_getColumnCount (imp_sth->m_rsmd); 
            AV *av = newAV();
              result = newRV(sv_2mortal((SV*)av));
              for(i=1; i <= colcnt; i++){ 
                SQLDBC_Int4 sqlprec = SQLDBC_ResultSetMetaData_getPrecision  (imp_sth->m_rsmd, i); 
          if (DBIc_DEBUGIV(imp_sth) > 8) {
                PerlIO_printf(DBIc_LOGPIO(imp_sth), "    Precision %d => %d\n",
                                                  i, sqlprec);
            PerlIO_flush(DBIc_LOGPIO(imp_sth));
                }
          av_store(av, i-1, newSViv(sqlprec));
                    }
            break;
      }  
      case sth_maxdb_option_ColScales:{                         /* SCALE */
        SQLDBC_Int2 i, colcnt = SQLDBC_ResultSetMetaData_getColumnCount (imp_sth->m_rsmd); 
            AV *av = newAV();
              result = newRV(sv_2mortal((SV*)av));
              for(i=1; i <= colcnt; i++){ 
                SQLDBC_Int4 scale = SQLDBC_ResultSetMetaData_getScale  (imp_sth->m_rsmd, i); 
          if (DBIc_DEBUGIV(imp_sth) > 8) {
                PerlIO_printf(DBIc_LOGPIO(imp_sth), "    Coltype %d => %d\n",
                                                  i, scale);
            PerlIO_flush(DBIc_LOGPIO(imp_sth));
                }
          av_store(av, i-1, (scale)?newSViv(scale):&PL_sv_undef);
                    }
            break;
      }  
      case sth_maxdb_option_RowsInCache:{                       
        return &PL_sv_undef;
            break;
      }  
    }  /*end switch*/
  }  

  if (DBIc_DBISTATE(imp_sth)->debug >= 2)
      PerlIO_printf(DBIc_LOGPIO(imp_sth), "      <- dbd_maxdb_st_FETCH_attrib %s => %s \n",
      key,  (result == NULL)?"NULL":(result==&PL_sv_undef)?"UNDEF":SvPV(result,kl));

  if (result == NULL) {
    return Nullsv;
  }
  return result;
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_st_blob_read
 *
 *  Purpose: Used for blob reads if the statement handles "LongTruncOk"
 *           attribute (currently not supported by DBD::mysql)
 *
 *  Input:   SV* - statement handle from which a blob will be fetched
 *           imp_sth - drivers private statement handle data
 *           field - field number of the blob (note, that a row may
 *               contain more than one blob)
 *           offset - the offset of the field, where to start reading
 *           len - maximum number of bytes to read
 *           destrv - RV* that tells us where to store
 *           destoffset - destination offset
 *
 *  Returns: TRUE for success, FALSE otrherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_maxdb_st_blob_read (SV *sth, imp_sth_t *imp_sth, int field, long offset,
                      long len, SV *destrv, long destoffset) {
#if defined(dTHR)
  dTHR;
#endif
  SV *bufsv;
  SQLDBC_Retcode rc;
  SQLDBC_RowSet *rowset = 0;
  SQLDBC_Length ind;
  dbd_maxdb_bind_column *m_col;

  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_st_blob_read); 

  bufsv = SvRV(destrv);
  sv_setpvn(bufsv,"",0);     
  SvGROW(bufsv, (STRLEN)len+destoffset+1);    

  if (!(rowset = SQLDBC_ResultSet_getRowSet (imp_sth->m_resultset))) {
    dbd_maxdb_internal_error(sth, DBD_ERR_INITIALIZATION_FAILED_S, "Cannot get rowset");
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_blob_read, SQLDBC_FALSE); 
  }
  
  m_col = &imp_sth->m_cols[field];
  if ((rc = SQLDBC_RowSet_getObjectByPos (rowset,
                                          field+1,
                                          m_col->hostType,
                                          ((char *)SvPVX(bufsv)) + destoffset,
                                          &ind,
                                          len,
                                          offset+1,
                                          SQLDBC_FALSE)) == SQLDBC_NOT_OK) {
    dbd_maxdb_sqldbc_error(sth, SQLDBC_RowSet_getError(rowset));
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_blob_read, SQLDBC_FALSE); 
  }
  
  if (rc == SQLDBC_NO_DATA_FOUND) {
    ind = 0;
  }

  SvCUR_set(bufsv, destoffset+DBD_MAXDB_MIN(ind,len));
  *SvEND(bufsv) = '\0'; 
  
  DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_st_blob_read, SQLDBC_TRUE); 
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_st_cancel
 *
 *  Purpose: canceled a statement execution
 *
 *  Input:   SV* - statement handle of the statement that will be canceled
 *
 *  Returns: TRUE for success, FALSE otrherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/
SV* dbd_maxdb_st_cancel( SV *sth){
#if defined(dTHR)
  dTHR;
#endif
  D_imp_sth(sth);
  D_imp_dbh_from_sth;
  SV* erg;

  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_st_cancel); 

  if (SQLDBC_Connection_cancel (imp_dbh->m_connection) != SQLDBC_OK){
    dbd_maxdb_sqldbc_error(sth, SQLDBC_Connection_getError(imp_dbh->m_connection)) ;     
          erg = Nullsv;
  } else {
    erg = newSViv(1);
  }
  DBD_MAXDB_METHOD_RETURN_SV(imp_sth, dbd_maxdb_st_cancel, erg); 
}

/***************************************************************************
 *
 *  Name:    dbd_maxdb_bind_ph
 *
 *  Purpose: Binds a statement value to a parameter
 *
 *  Input:   sth - statement handle
 *           imp_sth - drivers private statement handle data
 *           param - parameter number, counting starts with 1
 *           value - value being inserted for parameter "param"
 *           sql_type - SQL type of the value
 *           attribs - bind parameter attributes, currently this must be
 *               one of the values SQL_CHAR, ...
 *           inout - TRUE, if parameter is an output variable (currently
 *               this is not supported)
 *           maxlen - ???
 *
 *  Returns: TRUE for success, FALSE otherwise
 *
 **************************************************************************/

int dbd_maxdb_bind_ph (SV *sth, imp_sth_t *imp_sth, SV *param, SV *value,
                 IV sql_type, SV *attribs, int is_inout, IV maxlen) {
#if defined(dTHR)
  dTHR;
#endif
   STRLEN len;
   int index = SvIV(param);
   dbd_maxdb_bind_param *parameter;
   
   DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_bind_ph); 

   if (SvNIOK(param) ) {
      index =  SvIV(param);
    } 
    else {
      index = atoi(SvPV(param, len));
    }
   if (index <= 0  ||  index > DBIc_NUM_PARAMS(imp_sth)) {
     dbd_maxdb_internal_error(sth, DBD_ERR_INVALID_PARAMETER_INDEX_D, index);
     DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_bind_ph, SQLDBC_FALSE); 
   }

   parameter = &imp_sth->m_bindParms[index-1];
   parameter->hostType = SQLDBC_HOSTTYPE_ASCII;
   if (sql_type) parameter->sqltype = sql_type;

   if (parameter->value) (void) SvREFCNT_dec(parameter->value);
   if (is_inout) {
     parameter->value = SvREFCNT_inc(value);
   } else {
     	 switch (SQLDBC_ParameterMetaData_getParameterType (imp_sth->m_paramMetadata, index)) {
   	      case SQLDBC_SQLTYPE_BOOLEAN       : {
   	      	IV intval= SvIV(value)?1:0;
            parameter->hostType = SQLDBC_HOSTTYPE_INT1;
            parameter->value = newSViv(intval);
            break;
          }  
          case SQLDBC_SQLTYPE_STRB          :
          case SQLDBC_SQLTYPE_LONGB         : 
	        case SQLDBC_SQLTYPE_CHB           :
	        case SQLDBC_SQLTYPE_ROWID         :
	        case SQLDBC_SQLTYPE_VARCHARB      : 
          {	
            parameter->hostType = SQLDBC_HOSTTYPE_BINARY;
            parameter->value = newSVsv(value);
            break; 
          } default : {
            parameter->value = newSVsv(value);
            break; 
          } 
       }
   }
   
   
      parameter->paramMode = SQLDBC_ParameterMetaData_getParameterMode  (imp_sth->m_paramMetadata, index);  
   if (parameter->paramMode == parameterModeInOut || parameter->paramMode == parameterModeOut){
     SV* svVal;
     if(SvROK(parameter->value)){
       svVal = SvRV(parameter->value);
     } else {
       svVal = parameter->value;
     } 
     if (is_inout) {
       SQLDBC_Int4 paramlen;
       imp_sth->m_hasOutValues= SQLDBC_TRUE;
       (void)SvUPGRADE(svVal, SVt_PVNV);
       SvPOK_only(svVal);

       switch (SQLDBC_ParameterMetaData_getParameterType (imp_sth->m_paramMetadata, index)) {
          case SQLDBC_SQLTYPE_STRB          :
          case SQLDBC_SQLTYPE_LONGB         : 
          case SQLDBC_SQLTYPE_STRA          :
          case SQLDBC_SQLTYPE_STRE          :
          case SQLDBC_SQLTYPE_LONGA         :
          case SQLDBC_SQLTYPE_LONGE         : 
          case SQLDBC_SQLTYPE_STRUNI        :
          case SQLDBC_SQLTYPE_LONGUNI       : {
            parameter->hostType = SQLDBC_HOSTTYPE_ASCII;
            paramlen = DBIc_LongReadLen(imp_sth); 
            break;
          }
          case SQLDBC_SQLTYPE_FIXED         :
          case SQLDBC_SQLTYPE_NUMBER        :
          case SQLDBC_SQLTYPE_SMALLINT      :
          case SQLDBC_SQLTYPE_INTEGER       : {
            parameter->hostType = SQLDBC_HOSTTYPE_ASCII;
            paramlen = SQLDBC_ParameterMetaData_getParameterLength (imp_sth->m_paramMetadata, index) + 2;
            break;
          }
          case SQLDBC_SQLTYPE_FLOAT         :
          case SQLDBC_SQLTYPE_VFLOAT        : {
            parameter->hostType = SQLDBC_HOSTTYPE_ASCII;
            paramlen = SQLDBC_ParameterMetaData_getParameterLength (imp_sth->m_paramMetadata, index) + 6; /*-[0-9]+.[0-9]+E[-][0-9][0-9]*/
            break;
          }
          case SQLDBC_SQLTYPE_BOOLEAN       : {
            parameter->hostType = SQLDBC_HOSTTYPE_INT1;
            paramlen = 1;    
            break;
          } 
          default : {
            paramlen = SQLDBC_ParameterMetaData_getParameterLength (imp_sth->m_paramMetadata, index);
            break;
          }
         }
         SvGROW(svVal, (STRLEN)paramlen+1);
     } else {
        dbd_maxdb_internal_error(sth, DBD_ERR_PARAMETER_IS_NOT_INPUT_D, index);
        DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_bind_ph, SQLDBC_FALSE); 
     }
   } 
   DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_bind_ph, SQLDBC_TRUE); 
}

int dbd_maxdb_db_executeInternal( SV *dbh, SV *sth, char *statement ){
#if defined(dTHR)
  dTHR;
#endif
  D_imp_dbh(dbh);
  D_imp_sth(sth);
  int erg = DBD_MAXDB_ERROR_RETVAL;
  
  DBD_MAXDB_METHOD_ENTER(imp_sth, dbd_maxdb_db_executeInternal); 

  if (!DBIc_ACTIVE(imp_dbh)) {
    dbd_maxdb_internal_error(dbh, DBD_ERR_SESSION_NOT_CONNECTED);
    DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_db_executeInternal, DBD_MAXDB_ERROR_RETVAL); 
  }

  if (!dbd_maxdb_st_prepare (sth, imp_sth, statement, 0)) {
    return DBD_MAXDB_ERROR_RETVAL;
  }

  erg = dbd_st_execute (sth, imp_sth);
  DBD_MAXDB_METHOD_RETURN(imp_sth, dbd_maxdb_db_executeInternal, erg); 
}

