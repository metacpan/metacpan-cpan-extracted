/*
   engn/perldb2/dbdimp.h, engn_perldb2, db2_v82fp9, 1.11 04/09/13 17:27:00

   Copyright (c) 1995-2004 International Business Machines Corp.
*/

/* these are (almost) random values ! */
#define MAX_COL_NAME_LEN 128                                      

#include <dbivport.h>
/**
 * Macro for Error Handling. This error handling is followed from
 * CLI Development Guide for v951 - Chapter8 (Diagnostics in CLI Applications)
 * We try to capture 5 types of return codes and print the diagnostic 
 * information for the same. The return codes captured are
 *
 * 1. SQL_SUCCESS - Nothing to be done. Sucessful execution of CLI API
 * 2. SQL_SUCCESS_WITH_INFO - This is warning thrown back.
 * 3. SQL_NO_DATA_FOUND	- Function success but no data was returned
 * 4. SQL_ERROR	- Function failed
 * 5. SQL_INVALID HANDLE - Function failed due to invalid handle
 */

#define CHECK_ERROR(perlHandle, handleType, handle, ret, what)				\
if(ret != SQL_SUCCESS) {                                 				\
        ret = diagnoseError(perlHandle, handleType, handle, ret, what);	 	 	\
}

typedef struct imp_fbh_st imp_fbh_t;

struct imp_drh_st {
	dbih_drc_t com;                     /* MUST be first element in structure   */
	SQLHENV henv;
	int     connects;
	SV     *svNUM_OF_FIELDS;                                       
};

/* Define dbh implementor data structure */
struct imp_dbh_st {
	dbih_dbc_t com;                     /* MUST be first element in structure   */
	SQLHENV henv;
	SQLHDBC hdbc;
	char sqlerrp[9];                                               
};


/* Define sth implementor data structure */
struct imp_sth_st {	
	dbih_stc_t  com;                    /* MUST be first element in structure   */
	SQLHENV     henv;
	SQLHDBC     hdbc;
	SQLHSTMT    phstmt;

	/* Input Details    */
	SQLCHAR     *statement;             /* sql (see sth_scan)                   */
	HV          *bind_names;

	/* Output Details   */
	SQLINTEGER  done_desc;              /* have we described this sth yet ?     */
	imp_fbh_t   *fbh;                   /* array of imp_fbh_t structs           */
	SQLCHAR     *fbh_cbuf;              /* memory for all field names           */
	int         numFieldsAllocated;     /* number of fields allocated, could be */
					    /* more than current number of fields   */
					    /* in the case of multiple result sets  */
	SQLINTEGER  RowCount;               /* Rows affected by insert, update,     */
	                                    /* delete (unreliable for SELECT)       */
	int         bHasInput;              /* Has at least one input parameter     */
					    /* (by reference)                       */
	int         bHasOutput;             /* Has at least one output parameter    */
	int         bMoreResults;           /* Definitely has more results          */
					    /*   1=more results, 0=unknown          */
};

#define IMP_STH_EXECUTING       0x0001

struct imp_fbh_st {     		/* field buffer */
	imp_sth_t *imp_sth; 		/* 'parent' statement */

	/* description of the field */
	SQLSMALLINT dbtype;                                            
	SQLCHAR    *cbuf;           	/* ptr to name of select-list item */
	SQLSMALLINT cbufl;          	/* length of select-list item name */
	SQLINTEGER  dsize;          	/* max display size if field is a SQLCHAR */
	SQLUINTEGER prec;                                              
	SQLSMALLINT scale;                                             
	SQLSMALLINT nullok;                                            

	/* Our storage space for the field data as it's fetched */
	SQLSMALLINT ftype;          	/* external datatype we wish to get             */
	short       indp;           	/* null/trunc indicator variable                */
	void       *buffer;         	/* data buffer (poSQLINTEGERs to sv data)       */
	SQLINTEGER  bufferSize;     	/* length of data buffer                        */
	SQLINTEGER  rlen;           	/* length of returned data                      */

	/*LOB locator and LOB type indicator fields for LOB columns(CLOB/BLOB)*/
	SQLINTEGER   lob_loc;
	SQLINTEGER   loc_ind;
	SQLSMALLINT  loc_type;
};

typedef struct phs_st phs_t;    /* scalar placeholder */

struct phs_st { /* scalar placeholder */
	SV          *sv;                  /* the variable reference for bind_inout  */
	void        *buffer;              /* input and output buffer                */
	int          bufferSize;          /* size of buffer                         */
	SQLUSMALLINT paramType;           /* INPUT, OUTPUT or INPUT_OUTPUT          */
        SQLSMALLINT cType;               /* The parameter cType                    */
	SQLINTEGER   indp;                /* null indicator or length indicator     */
	int          bDescribed;          /* already described this parameter       */
	int          bDescribeOK;         /* describe was successful                */
	SQLSMALLINT  descSQLType;                                      
	SQLSMALLINT  descDecimalDigits;                                
	SQLUINTEGER  descColumnSize;                                   
	IV	     ivValue;		 /*integer variable to hold the bound output value */
	double	     dblValue;           /*double variable to hold the bound output value*/
};

#define dbd_init            db2_init
#ifndef AS400
#define dbd_data_sources    db2_data_sources                     
#endif
#define dbd_db_login        db2_db_login
#define dbd_db_do           db2_db_do
#define dbd_db_ping         db2_db_ping                          
#define dbd_db_commit       db2_db_commit
#define dbd_db_rollback     db2_db_rollback
#define dbd_db_disconnect   db2_db_disconnect
#define dbd_db_destroy      db2_db_destroy
#define dbd_db_STORE_attrib db2_db_STORE_attrib
#define dbd_db_FETCH_attrib db2_db_FETCH_attrib
#define dbd_st_table_info   db2_st_table_info
#define dbd_st_prepare      db2_st_prepare
#define dbd_st_rows         db2_st_rows
#define dbd_st_execute      db2_st_execute
#define dbd_st_fetch        db2_st_fetch
#define dbd_st_finish       db2_st_finish
#define dbd_st_destroy      db2_st_destroy
#define dbd_st_blob_read    db2_st_blob_read                     
#define dbd_st_STORE_attrib db2_st_STORE_attrib
#define dbd_st_FETCH_attrib db2_st_FETCH_attrib
#define dbd_describe        db2_describe
#define dbd_bind_ph         db2_bind_ph

#define dbd_st_primary_key_info db2_st_primary_key_info          
#define dbd_st_foreign_key_info db2_st_foreign_key_info          
#define dbd_st_type_info_all    db2_st_type_info_all             
#define dbd_st_column_info      db2_st_column_info               
#define dbd_db_get_info         db2_db_get_info                  

/*
 * Error Handling function to diagnose errors 
 * @return: Return Code 
 * */
static SQLRETURN diagnoseError(SV* perlHandle, SQLSMALLINT handleType, SQLHANDLE handle, SQLRETURN rc, char* what);
static void setErrorFromDiagRecInfo( SV* perlHandle, SQLSMALLINT handleType, SQLHANDLE handle, char* err);
static void setErrorFromString( SV* perlHandle, SQLRETURN returnCode, char* what);
#ifdef CLI_DBC_SERVER_TYPE_DB2LUW
#ifdef SQL_ATTR_DECFLOAT_ROUNDING_MODE
static void _db2_set_decfloat_rounding_mode_client(SV* dbh, imp_dbh_t *imp_dbh);
#endif
#endif
/* end */
