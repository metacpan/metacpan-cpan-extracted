/*
 * $Id: dbdimp.h 555 2006-11-30 23:42:45Z wagnerch $
 * Copyright (c) 1997-2001 Jeff Urlwin
 * portions Copyright (c) 1997  Thomas K. Wenrich
 * portions Copyright (c) 1994,1995,1996  Tim Bunce
 * portions Copyright (c) 1997-2001 Jeff Urlwin
 * portions Copyright (c) 2001 Dean Arnold
 * portions Copyright (c) 2006 Chad Wagner
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 */


typedef struct imp_fbh_st imp_fbh_t;

/* This holds global data of the driver itself.
 */
struct imp_drh_st
{
   dbih_drc_t com; /* MUST be first element in structure */
   HENV henv;
   int connects;   /* connect count */
};

/* Define dbh implementor data structure 
   This holds everything to describe the database connection.
 */
struct imp_dbh_st
{
   dbih_dbc_t com;                /* MUST be first element in structure */
   HENV henv;                     /* copy from imp_drh for speed */
   HDBC hdbc;
   int ttIgnoreNamedPlaceholders; /* flag to ignore named parameters */
   int ttDefaultBindType;         /* flag to set default binding type */
   int ttQueryTimeout;
   int ttExecDirect;              /* flag for executing SQLExecDirect instead
                                     of SQLPrepare and SQLExecute.  Magic
                                     happens at SQLExecute() */
   int RowCacheSize;              /* default row cache size in rows for
                                     statements */
};

/* Define sth implementor data structure */
struct imp_sth_st
{
   dbih_stc_t com;                /* MUST be first element in structure */

   HENV henv;                     /* copy for speed */
   HDBC hdbc;                     /* copy for speed */
   HSTMT hstmt;

   int done_desc;                 /* have we described this sth yet ? */

   /* Input Details */
   char *statement;               /* sql (see sth_scan) */
   HV *all_params_hv;             /* all params, keyed by name    */
   AV *out_params_av;             /* quick access to inout params */
   int has_inout_params;

   UCHAR *ColNames;               /* holds all column names; is referenced
                                     by ptrs from within the fbh structures */
   UCHAR *RowBuffer;              /* holds row data; referenced from fbh */
   imp_fbh_t *fbh;                /* array of imp_fbh_t structs */

   SDWORD RowCount;               /* Rows affected by insert, update, delete */
   int eod;                       /* End of data seen */
   int ttIgnoreNamedPlaceholders; /* flag to ignore named parameters */
   int ttDefaultBindType;         /* flag to set default binding type */
   int ttExecDirect;              /* flag for executing SQLExecDirect
                                     instead of SQLPrepare and SQLExecute.
                                     Magic happens at SQLExecute() */
   int ttQueryTimeout;
};

/* Field buffer structure */
struct imp_fbh_st
{
   imp_sth_t *imp_sth;    /* 'parent' statement */

   /* field description - SQLDescribeCol() */
   UCHAR *ColName;        /* zero-terminated column name */
   SWORD ColNameLen;
   UDWORD ColDef;         /* precision */
   SWORD ColScale;
   SWORD ColSqlType;
   SWORD ColNullable;
   SDWORD ColLength;      /* SqlColAttributes(SQL_COLUMN_LENGTH) */
   SDWORD ColDisplaySize; /* SqlColAttributes(SQL_COLUMN_DISPLAY_SIZE) */

   /* Our storage space for the field data as it's fetched */
   SWORD ftype;           /* external datatype we wish to get.
                             Used as parameter to SQLBindCol(). */
   UCHAR *data;           /* points into sth->RowBuffer */
   SDWORD datalen;        /* length returned from fetch for single row. */
};


typedef struct phs_st phs_t;    /* scalar placeholder   */

/* Placeholder structure */
struct phs_st
{
   int idx;                /* Parameter index */
   SV *sv;                 /* Scalar holding the value */
   int sv_type;            /* SvTYPE at bind */
   char *sv_buf;           /* Pointer to SV's buffer */

   bool is_inout;
   IV  maxlen;             /* max possible len (=allocated buffer) */

   SQLSMALLINT fSqlType;   /* SQL data type */
   SQLULEN     cbColDef;   /* Column precision (char/numeric length) */
   SQLSMALLINT ibScale;    /* Column scale (numeric length after decimal) */
   SQLSMALLINT fNullable;  /* Nullable column */
   SQLSMALLINT fCType;     /* C data type */
   SQLLEN      cbValue;    /* Data length */

   char name[1];           /* struct is malloc'd bigger as needed */
};


/* These defines avoid name clashes for multiple statically linked DBD's        */

#define dbd_init		timesten_init
#define dbd_bind_ph		timesten_bind_ph
#define dbd_error		timesten_error
#define dbd_discon_all		timesten_discon_all

#define dbd_db_login		timesten_db_login
#define dbd_db_login6		timesten_db_login6
#define dbd_db_commit		timesten_db_commit
#define dbd_db_rollback		timesten_db_rollback
#define dbd_db_disconnect	timesten_db_disconnect
#define dbd_db_destroy		timesten_db_destroy
#define dbd_db_STORE_attrib	timesten_db_STORE_attrib
#define dbd_db_FETCH_attrib	timesten_db_FETCH_attrib
#define dbd_db_column_info	timesten_db_column_info
#define dbd_db_table_info	timesten_db_table_info
#define dbd_db_primary_key_info	timesten_db_primary_key_info
#define dbd_db_foreign_key_info	timesten_db_foreign_key_info
#define dbd_db_get_info		timesten_db_get_info
#define dbd_db_type_info	timesten_db_type_info
#define dbd_db_execdirect	timesten_db_execdirect

#define dbd_st_prepare		timesten_st_prepare
#define dbd_st_rows		timesten_st_rows
#define dbd_st_execute		timesten_st_execute
#define dbd_st_execute_array	timesten_st_execute_array
#define dbd_st_fetch		timesten_st_fetch
#define dbd_st_finish		timesten_st_finish
#define dbd_st_destroy		timesten_st_destroy
#define dbd_st_blob_read	timesten_st_blob_read
#define dbd_st_STORE_attrib	timesten_st_STORE_attrib
#define dbd_st_FETCH_attrib	timesten_st_FETCH_attrib
#define dbd_st_cancel		timesten_st_cancel
/* end */
