/*
 * $Id: dbdimp.h,v 1.7 1998/08/08 16:58:30 timbo Exp $
 * Copyright (c) 1997-2001 Jeff Urlwin
 * portions Copyright (c) 1997  Thomas K. Wenrich
 * portions Copyright (c) 1994,1995,1996  Tim Bunce
 * portions Copyright (c) 1997-2001 Jeff Urlwin
 * portions Copyright (c) 2001 Dean Arnold
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 */


typedef struct imp_fbh_st imp_fbh_t;

/* This holds global data of the driver itself.
 */
struct imp_drh_st {
    dbih_drc_t com;		/* MUST be first element in structure	*/
    HENV henv;
    int connects;		/* connect count */
};

/* Define dbh implementor data structure 
   This holds everything to describe the database connection.
 */
struct imp_dbh_st {
    dbih_dbc_t com;		/* MUST be first element in structure	*/
    HENV henv;			/* copy from imp_drh for speed		*/
    HDBC hdbc;
    char odbc_ver[20];  /* ODBC compat. version for driver */
    char odbc_dbname[64];
    int  odbc_ignore_named_placeholders;	/* flag to ignore named parameters */
    int  odbc_default_bind_type;	/* flag to set default binding type (experimental) */
    int  odbc_sqldescribeparam_supported; /* flag to see if SQLDescribeParam is supported */
    int  odbc_sqlmoreresults_supported; /* flag to see if SQLMoreResults is supported */
    int	 odbc_defer_binding; /* flag to work around SQLServer bug and defer binding until */
			    /* last possible moment */
    int  odbc_force_rebind; /* force rebinding the output columns after each execute to
       /* resolve some issues where certain stored procs can return
       /* multiple result sets */
    int  odbc_async_exec; /* flag to set asynchronous execution */
    int  odbc_exec_direct;		/* flag for executing SQLExecDirect instead of SQLPrepare and SQLExecute.  Magic happens at SQLExecute() */
    SQLUINTEGER odbc_async_type; /* flag to store the type of asynchronous
                                  * execution the driver supports */
    SV *odbc_err_handler; /* contains the error handler coderef */
    int  RowCacheSize;			/* default row cache size in rows for statements */
};

/* Define sth implementor data structure */
struct imp_sth_st {
    dbih_stc_t com;		/* MUST be first element in structure	*/

    HENV       henv;		/* copy for speed	*/
    HDBC       hdbc;		/* copy for speed	*/
    HSTMT      hstmt;

    int        moreResults;	/* are there more results to fetch?	*/
    int        done_desc;	/* have we described this sth yet ?	*/

    /* Input Details	*/
    char      *statement;	/* sql (see sth_scan)		*/
    HV        *all_params_hv;   /* all params, keyed by name    */
    AV        *out_params_av;   /* quick access to inout params */
    int     has_inout_params;

    UCHAR    *ColNames;		/* holds all column names; is referenced
				 * by ptrs from within the fbh structures
				 */
    UCHAR    *RowBuffer;	/* holds row data; referenced from fbh */
    imp_fbh_t *fbh;		/* array of imp_fbh_t structs	*/

    SDWORD   RowCount;		/* Rows affected by insert, update, delete
				 * (unreliable for SELECT)
				 */
    int eod;			/* End of data seen */
    SV	*param_sts;			/* ref to param status array for array bound PHs */
    int params_procd;			/* to recv number of parms processed by an SQLExecute() */
    UWORD *param_status;		/* row indicators for array binding */
    SV	*row_sts;			/* ref to row status array for array bound columns */
    UDWORD rows_fetched;		/* actual number of rows fetched for array binding */
    UDWORD max_rows;			/* max number of rows per fetch for array binding */
    UWORD *row_status;			/* row indicators for array binding */
    int  odbc_ignore_named_placeholders;	/* flag to ignore named parameters */
    int  odbc_default_bind_type;	/* flag to set default binding type (experimental) */
    int  odbc_exec_direct;		/* flag for executing SQLExecDirect instead of SQLPrepare and SQLExecute.  Magic happens at SQLExecute() */
    int  odbc_force_rebind; /* force rebinding the output columns after each execute to
       /* resolve some issues where certain stored procs can return
       /* multiple result sets */
};
#define IMP_STH_EXECUTING	0x0001


struct imp_fbh_st { 	/* field buffer EXPERIMENTAL */
   char szDummyBuffer[1024];
   imp_sth_t *imp_sth;	/* 'parent' statement */
    /* field description - SQLDescribeCol() */
    UCHAR *ColName;		/* zero-terminated column name */
    SWORD ColNameLen;
    UDWORD ColDef;		/* precision */
    SWORD ColScale;
    SWORD ColSqlType;
    SWORD ColNullable;
    SDWORD ColLength;		/* SqlColAttributes(SQL_COLUMN_LENGTH) */
    SDWORD ColDisplaySize;	/* SqlColAttributes(SQL_COLUMN_DISPLAY_SIZE) */

    /* Our storage space for the field data as it's fetched	*/
    SWORD ftype;		/* external datatype we wish to get.
				 * Used as parameter to SQLBindCol().
				 */
    UCHAR *data;		/* points into sth->RowBuffer */
    SDWORD datalen;		/* length returned from fetch for single row. */
    UDWORD maxcnt;		/* max num of rows to return per fetch */
    SV *colary;			/* ref to array to recv output data */
    SDWORD *col_indics;	/* individual column length/NULL indicators for array binding */
    int is_array;		/* TRUE => bound to array */
};


typedef struct phs_st phs_t;    /* scalar placeholder   */

struct phs_st {  	/* scalar placeholder EXPERIMENTAL	*/
    int idx;		/* index number of this param 1, 2, ...	*/

    SV  *sv;            /* the scalar holding the value         */
    int sv_type;        /* original sv type at time of bind     */
    int biggestparam;    /* if sv_type is VARCHAR, size of biggest so far */
    int scale;
    bool is_inout;
    IV  maxlen;         /* max possible len (=allocated buffer) */
    char *sv_buf;	/* pointer to sv's data buffer		*/
    int alen_incnull;

    SWORD ftype;			/* external field type	       */
    SWORD sql_type;			/* the sql type the placeholder should have in SQL	*/
    SWORD tgt_sql_type;			/* the PH SQL type the stmt expects     */
    SDWORD tgt_len;			/* size or precision the stmt expects */
    SDWORD cbValue;			/* length of returned value OR SQL_NULL_DATA */
    SDWORD *indics;			/* ptr to indicator array for param arrays */
    int is_array;			/* TRUE => parameter array */

    char name[1];			/* struct is malloc'd bigger as needed	*/
};


/* These defines avoid name clashes for multiple statically linked DBD's        */

#define dbd_init		odbc_init
#define dbd_db_login		odbc_db_login
#define dbd_db_login6		odbc_db_login6
/*
 * Not defined by DBI
 * #define dbd_db_do		odbc_db_do
 */
#define dbd_db_commit		odbc_db_commit
#define dbd_db_rollback		odbc_db_rollback
#define dbd_db_disconnect	odbc_db_disconnect
#define dbd_db_destroy		odbc_db_destroy
#define dbd_db_STORE_attrib	odbc_db_STORE_attrib
#define dbd_db_FETCH_attrib	odbc_db_FETCH_attrib
#define dbd_st_prepare		odbc_st_prepare
#define dbd_st_rows		odbc_st_rows
#define dbd_st_execute		odbc_st_execute
#define dbd_st_fetch		odbc_st_fetch
#define dbd_st_finish		odbc_st_finish
#define dbd_st_destroy		odbc_st_destroy
#define dbd_st_blob_read	odbc_st_blob_read
#define dbd_st_STORE_attrib	odbc_st_STORE_attrib
#define dbd_st_FETCH_attrib	odbc_st_FETCH_attrib
#define dbd_describe		odbc_describe
#define dbd_bind_ph		odbc_bind_ph
#define dbd_error		odbc_error
#define dbd_discon_all		odbc_discon_all
/* end */
