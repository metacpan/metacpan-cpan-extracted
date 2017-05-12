/*
 * $Id: dbdimp.h,v 0.13 1999/01/29 00:34:39 $
 *
 * Copyright (c) 1999 DBMaker team 
 * portions Copyright (c) 1997,1998,1999  Jeff Urlwin
 * portions Copyright (c) 1997  Thomas K. Wenrich
 * portions Copyright (c) 1994,1995,1996  Tim Bunce
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 */

/****************************************************************************
 * Change History by DBMaker team:
 * #000 DBMaker 0.12a By Jackie
 * #001 09/15/99 phu: add some field
 ****************************************************************************/
typedef struct imp_fbh_st imp_fbh_t;

/*
 * redefine dbd_xxx functions to dbm_xxx
 */
#define dbd_db_login     dbm_db_login
#define dbd_db_do        dbm_db_do
#define dbd_db_commit    dbm_db_commit
#define dbd_db_rollback  dbm_db_rolback
#define dbd_db_destroy   dbm_db_destroy
#define dbd_db_STORE     dbm_db_store
#define dbd_db_FETCH     dbm_db_FETCH
#define dbd_db_disconnect dbm_db_disconnect
#define dbd_bind_ph      dbm_bind_ph

#define dbd_st_prepare   dbm_st_prepare
#define dbd_st_rows      dbm_st_rows
#define dbd_st_execute   dbm_st_execute
#define dbd_st_fetch     dbm_st_fetch
#define dbd_st_finish    dbm_st_finish
#define dbd_st_destroy   dbm_st_destroy
#define dbd_st_readblob  dbm_st_readblob
#define dbd_st_STORE     dbm_st_STORE
#define dbd_st_FETCH     dbm_st_FETCH
#define dbd_st_blob_read dbm_st_blob_read

#define dbd_preparse	  dbm_preparse
#define dbd_describe      dbm_describe
#define dbd_init	  dbm_init
#define _dbd_rebind_ph	  _dbm_rebind_ph

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
    HDBC hdbc;
};


/* Define sth implementor data structure */
struct imp_sth_st {
    dbih_stc_t com;		/* MUST be first element in structure	*/

    HSTMT      hstmt;
    int        done_desc;   /* have we described this sth yet ?	*/

    /* Input Details	*/
    char      *statement;	/* sql (see sth_scan)		*/
    HV        *params_hv;	/* see preparse function */
    AV        *params_av;	/* see preparse function */
    int     has_inout_params;
    int       fgfileinput;      /* use 'file' as blob input          #001 */
    int       fgBindColToFile;  /* set when call func(BindColToFile) #001 */

#if 0 /* now handled by DBIc_ macros */
    int       long_buflen;      /* length for long/longraw (if >0)	*/
    int       long_trunc_ok;    /* is truncating a long an error	*/
#endif

    SWORD     n_result_cols;	/* number of result columns */

    UCHAR    *ColNames;		/* holds all column names; is referenced
				 * by ptrs from within the fbh structures
				 */
    UCHAR    *RowBuffer;	/* holds row data; referenced from fbh */
    imp_fbh_t *fbh;		/* array of imp_fbh_t structs	*/

    SDWORD   RowCount;		/* Rows affected by insert, update, delete
				 * (unreliable for SELECT)
				 */
    int eod;			/* End of data seen */

#if 0
    Cda_Def *cda;	/* currently just points to cdabuf below */
    Cda_Def cdabuf;


    /* Select Column Output Details	*/
    char      *fbh_cbuf;    /* memory for all field names       */
    int       t_dbsize;     /* raw data width of a row		*/
    /* Select Row Cache Details */
    int       cache_size;
    int       in_cache;
    int       next_entry;
    int       eod_errno;
#endif
};
#define IMP_STH_EXECUTING	0x0001


#if 0
typedef struct fb_ary_st fb_ary_t;    /* field buffer array	*/
struct fb_ary_st { 	/* field buffer array EXPERIMENTAL	*/
    ub2  bufl;		/* length of data buffer		*/
    sb2  *aindp;	/* null/trunc indicator variable	*/
    ub1  *abuf;		/* data buffer (points to sv data)	*/
    ub2  *arlen;	/* length of returned data		*/
    ub2  *arcode;	/* field level error status		*/
};
#endif

struct imp_fbh_st { 	/* field buffer EXPERIMENTAL */
    imp_sth_t *imp_sth;	/* 'parent' statement */
    /* DBMaker's field description - SQLDescribeCol() */
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
    SDWORD datalen;		/* length returned from fetch for
				 * single row.
				 */
    char *file_prefix;           /* file prefix    #001 */
    char *file_ext;              /* file extension #001 */
    SDWORD  file_idxno;          /* file index no  #001 */
    SDWORD  fgOverwrite;         /* if set, file can be overwrite if same name #001 */
};


typedef struct phs_st phs_t;    /* scalar placeholder   */

struct phs_st {  	/* scalar placeholder EXPERIMENTAL	*/
    int idx;		/* index number of this param 1, 2, ...	*/

    SV  *sv;            /* the scalar holding the value         */
    int sv_type;        /* original sv type at time of bind     */
    bool is_inout;
    IV  maxlen;         /* max possible len (=allocated buffer) */
    char *sv_buf;	/* pointer to sv's data buffer		*/
    int alen_incnull;
    int isnull;

    SWORD ftype;        /* external field type	       */
    SWORD sql_type;     /* the sql type the placeholder should have in SQL	*/
    SDWORD cbValue;	/* length of returned value */
                        /* in Input: SQL_NULL_DATA */
    char name[1];	/* struct is malloc'd bigger as needed	*/
};

/*
 * function called by dbmaker_error to decide whether dbmaker_error should
 * set error flag for DBI
 */
typedef int (*T_IsAnError) _((SV *h, 
		     RETCODE rc, 
		     char *sqlstate, 
		     const void *par
		     ));

const char *dbmaker_error5 _((SV *h, RETCODE rc, char *what, 
			  T_IsAnError func, const void *par));
#define dbmaker_error(a,b,c) dbmaker_error5(a,b,c,NULL, NULL);

/* const char *dbmaker_error _((SV *h, RETCODE rc, char *what)); */
/* end */
