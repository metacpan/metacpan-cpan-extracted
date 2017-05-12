/*!
  @file           dbdimp.h
  @author         MarcoP, ThomasS
  @ingroup        dbd::MaxDB
  @brief          

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
#ifdef _WIN32
#include <malloc.h>
#endif
/**
 * Comes with MaxDB's SQLDBC sdk.
 */
#include <SQLDBC_C.h>      
#include <SQLDBC_Types.h>  

#define NEED_DBIXS_VERSION 9

/**
 * Comes with DBI.
 */
#include <DBIXS.h>	
#include <dbd_xsh.h>	

/**
 * @brief This holds global data of the driver itself.
 */ 
struct imp_drh_st {
    dbih_drc_t com;		     /*!< MUST be first element in structure	*/
    SQLDBC_Environment *m_maxDBEnv;  /*!< MaxDB environment handle*/
};

/**
 * @brief This holds MaxDB Metadata. Maybe SQLDBC provides this sometime
 */ 
typedef struct SQLDBC_DatabaseMetaData {
  SQLDBC_UInt2 getMaxTablenameLength;   /*!< maximum length of a table name */
  SQLDBC_UInt2 getMaxCursorLength;      /*!< maximum length of a cursor name */
  SQLDBC_UInt2 getMaxColumnnameLength;  /*!< maximum length of a column name */
} SQLDBC_DatabaseMetaData;

/* 
 * @brief This holds everything to describe the database connection.
 */
struct imp_dbh_st {
  dbih_dbc_t com;		           /*!< MUST be first element in structure	*/
  SQLDBC_ConnectProperties *m_connprop;    /*!< MaxDB connect properties */
  SQLDBC_Connection        *m_connection;  /*!< MaxDB connect handle */
  SQLDBC_DatabaseMetaData  *m_dbmd;        
  SQLDBC_Statement         *m_stmt;        /*!< MaxDB statement handle use by executeUpdate*/
};

/*
 *  @brief internal structure for holding bind parameters.
 */
typedef struct dbd_maxdb_bind_param {
    SV* value;               /*!< parameter value */
    int sqltype;             /*!< parameter type provide via bind method */
    SQLDBC_HostType hostType;   /*!< column datatyp */
    SQLDBC_Length indicator; /*!< indicator value */
    ParameterMode paramMode; /*!< indicator value */
} dbd_maxdb_bind_param;

/*
 *  @brief internal structure for holding bind columns.
 */
typedef struct dbd_maxdb_bind_column {
    char* buf;                  /*!< offset pointer to internal buffer */
    SQLDBC_Length   bufLen;     /*!< maximum length of buffer within the result */
    SQLDBC_HostType hostType;   /*!< column datatyp */
    SQLDBC_Length   indicator;  /*!< coulumn indicator */
    SQLDBC_Bool     chopBlanks; /*!< flag that indicates whether the column is relevant for cutoff blanks*/
} dbd_maxdb_bind_column;

/* 
 * @brief Define sth implementor data structure 
 */
struct imp_sth_st {
  dbih_stc_t com;		/* MUST be first element in structure	*/
  SQLDBC_PreparedStatement *m_prepstmt;  /*!< MaxDB prepared statement handle */
  SQLDBC_ResultSet         *m_resultset; /*!< MaxDB resultset handle */
  SQLDBC_ResultSetMetaData *m_rsmd;      /*!< MaxDB resultset metadata handle */
  SQLDBC_ParameterMetaData *m_paramMetadata; /*!< MaxDB parameter meta data handle*/
  dbd_maxdb_bind_param     *m_bindParms;     /*!< bind parameter values */
  SQLDBC_Bool               m_rowNotFound;   /*!< flag that indicates that the latests resultset is empty */
  char*                     m_fetchBuf;      /*!< internal buffer that contains the latest fetched row*/
  dbd_maxdb_bind_column    *m_cols;          /*!< bind column values */
  SQLDBC_Bool               m_hasOutValues;  /*!< flag that indicates whether this statement has out paramter(s) or not*/
      
  SQLDBC_UInt4              m_rowSetSize;    /*!< Size of the rowset, 0 means undef*/  
  SQLDBC_Bool               m_rowSetSizeChanged;  /*!< flag that indicates that the rowsetsize has been changed*/
  SQLDBC_Int2               m_fetchSize;     /*!< fetch size, 0 means undef*/ 
};

/* These defines avoid name clashes for multiple statically linked DBD's        */

#define dbd_init            dbd_maxdb_init
#define dbd_db_login        dbd_maxdb_db_login
#define dbd_db_login6       dbd_maxdb_db_login6
#define dbd_db_commit       dbd_maxdb_db_commit
#define dbd_db_rollback	    dbd_maxdb_db_rollback
#define dbd_db_disconnect   dbd_maxdb_db_disconnect
#define dbd_db_destroy      dbd_maxdb_db_destroy
#define dbd_db_STORE_attrib dbd_maxdb_db_STORE_attrib
#define dbd_db_FETCH_attrib dbd_maxdb_db_FETCH_attrib

#define dbd_bind_ph         dbd_maxdb_bind_ph
#define dbd_error           dbd_maxdb_error

/*
#define bind_param_inout  ???
#define dbd_discon_all		 dbd_maxdb_discon_all
#define dbd_db_last_insert_id dbd_maxdb_db_last_insert_id
#define dbd_db_data_sources
*/

#define dbd_db_do           dbd_maxdb_db_do 
#define dbd_st_prepare      dbd_maxdb_st_prepare
#define dbd_st_execute      dbd_maxdb_st_execute
#define dbd_st_fetch        dbd_maxdb_st_fetch
#define dbd_st_finish       dbd_maxdb_st_finish
#define dbd_st_destroy      dbd_maxdb_st_destroy
#define dbd_st_blob_read    dbd_maxdb_st_blob_read
#define dbd_st_STORE_attrib dbd_maxdb_st_STORE_attrib
#define dbd_st_FETCH_attrib dbd_maxdb_st_FETCH_attrib
/*
#define dbd_st_rows
#define dbd_st_finish3
#define dbd_st_execute_for_fetch
*/
#define DBD_MAXDB_ERROR_RETVAL -42

/*prototypes to avoid warnings*/
int dbd_maxdb_db_login6(SV *dbh, imp_dbh_t *imp_dbh, char *url, char *user, char* password, SV *attr);
int dbd_maxdb_st_execute(SV* sth, imp_sth_t* imp_sth);
int dbd_maxdb_st_finish(SV* sth, imp_sth_t* imp_sth);
int dbd_maxdb_db_commit(SV* dbh, imp_dbh_t* imp_dbh);
int dbd_maxdb_db_rollback(SV* dbh, imp_dbh_t* imp_dbh);
int dbd_maxdb_db_disconnect(SV* dbh, imp_dbh_t* imp_dbh);
int dbd_maxdb_db_STORE_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv, SV* valuesv);
SV* dbd_maxdb_db_FETCH_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv) ;
void dbd_maxdb_db_destroy(SV* dbh, imp_dbh_t* imp_dbh);
int dbd_maxdb_st_prepare(SV* sth, imp_sth_t* imp_sth, char* statement, SV* attribs);
int dbd_st_blob_read (SV *sth, imp_sth_t *imp_sth, int field, long offset, long len, SV *destrv, long destoffset);
int dbd_maxdb_db_STORE_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv, SV* valuesv);
void dbd_maxdb_st_destroy(SV* sth, imp_sth_t* imp_sth);
int dbd_maxdb_db_ping(SV* dbh);
int dbd_maxdb_db_isunicode(SV* dbh);
void dbd_maxdb_init(dbistate_t* dbistate);
int dbd_maxdb_bind_ph (SV *sth, imp_sth_t *imp_sth, SV *param, SV *value,
		 IV sql_type, SV *attribs, int is_inout, IV maxlen);
AV* dbd_maxdb_st_fetch(SV* sth, imp_sth_t* imp_sth);		 
SV* dbd_maxdb_st_FETCH_attrib(SV* sth, imp_sth_t* imp_sth, SV* keysv);		 
int dbd_maxdb_st_STORE_attrib(SV* sth, imp_sth_t* imp_sth, SV* keysv, SV* valuesv);

int dbd_maxdb_db_executeInternal( SV *dbh, SV *sth, char *statement );
int dbd_maxdb_db_executeUpdate( SV *dbh, char *statement );
SV* dbd_maxdb_st_cancel( SV *sth);
SV* dbd_maxdb_db_getSQLMode(SV* dbh);
/* end */
