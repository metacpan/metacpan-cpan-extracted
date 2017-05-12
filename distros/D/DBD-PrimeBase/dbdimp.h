/*
 * $Id: dbdimp.h,v 1.7 1998/08/08 16:58:30 timbo Exp $
 * Copyright (c) 1997 Jeff Urlwin
 * portions Copyright (c) 1997  Thomas K. Wenrich
 * portions Copyright (c) 1994,1995,1996  Tim Bunce
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 */

#include <DBIXS.h>  /* installed by the DBI module                        */
#include "pbapi.h"  
#include <dbd_xsh.h>

enum errMsgs {
    JW_ERR_CONNECT = 1,
    JW_ERR_SELECT_DB,
    JW_ERR_STORE_RESULT,
    JW_ERR_NOT_ACTIVE,
    JW_ERR_QUERY,
    JW_ERR_FETCH_ROW,
    JW_ERR_LIST_DB,
    JW_ERR_CREATE_DB,
    JW_ERR_DROP_DB,
    JW_ERR_LIST_TABLES,
    JW_ERR_LIST_FIELDS,
    JW_ERR_LIST_FIELDS_INT,
    JW_ERR_LIST_SEL_FIELDS,
    JW_ERR_NO_RESULT,
    JW_ERR_NOT_IMPLEMENTED,
    JW_ERR_ILLEGAL_PARAM_NUM,
    JW_ERR_MEM,
    JW_ERR_LIST_INDEX,
    JW_ERR_SEQUENCE,
    TX_ERR_AUTOCOMMIT,
    TX_ERR_COMMIT,
    TX_ERR_ROLLBACK
};


typedef struct imp_fbh_st imp_fbh_t;

/* Driver handle structure. */
struct imp_drh_st {
    dbih_drc_t com;		/* MUST be first element in structure	*/
    
    /* PrimeBase Stuff. */
};


/* DataBase handle structure. */
struct imp_dbh_st {
    dbih_dbc_t 		com;		/* MUST be first element in structure	*/
    
    /* PrimeBase Stuff. */
    long 	sessid; 	/* The PrimeBase session id. */
    unsigned long 	seq_cnt; 
    char			auto_commit;
};


/* Statement handle structure. */
struct imp_sth_st {
    dbih_stc_t com;		/* MUST be first element in structure	*/
    
    /* PrimeBase Stuff. */
    long sessid; 	/* The PrimeBase session id. */

    char tag[16]; 		/* A tag name unique to this statement. Used in name generation. */
    
    char *stmt_text;	/* The prepared statement.  */
    long parm_cnt;		/* The number of paramaters in the statement.  */
	char delayed_execution;
	char is_select;
	char cursor_name[32];
	unsigned long 	cursor_id;
	
    long columns;			/* The number of columns in the result set.  */
    void *column_info;		/* A pointer to column info. */
	unsigned long	max_blob;		/* The maximum length of blob data to get. */
	
    long rows_effected;	/* The number of rows effected after execution.  */
};

#define IMP_STH_EXECUTING	0x0001



/* These defines avoid name clashes for multiple statically linked DBD's        */

#define dbd_init			PB_init
#define dbd_db_login		PB_db_login
#define dbd_db_do			PB_db_do
#define dbd_db_commit		PB_db_commit
#define dbd_db_rollback		PB_db_rollback
#define dbd_db_disconnect	PB_db_disconnect
#define dbd_db_destroy		PB_db_destroy
#define dbd_db_STORE_attrib	PB_db_STORE_attrib
#define dbd_db_FETCH_attrib	PB_db_FETCH_attrib
#define dbd_st_prepare		PB_st_prepare
#define dbd_st_rows			PB_st_rows
#define dbd_st_execute		PB_st_execute
#define dbd_st_fetch		PB_st_fetch
#define dbd_st_finish		PB_st_finish
#define dbd_st_destroy		PB_st_destroy
#define dbd_st_blob_read	PB_st_blob_read
#define dbd_st_STORE_attrib	PB_st_STORE_attrib
#define dbd_st_FETCH_attrib	PB_st_FETCH_attrib
#define dbd_describe		PB_describe
#define dbd_bind_ph			PB_bind_ph
#define dbd_error			PB_error
#define dbd_st_prep_call	PB_st_prep_call

extern unsigned long PrimeBase_dr_connect(SV *dbh, char *host, char *server, char *user, char *passwd);
extern void PrimeBase_dr_disconnect(unsigned long sessid);
extern int PrimeBase_create_db(SV *dbh, unsigned long sessid, char *database);
extern int PrimeBase_drop_db(SV *dbh, unsigned long sessid, char *database);
