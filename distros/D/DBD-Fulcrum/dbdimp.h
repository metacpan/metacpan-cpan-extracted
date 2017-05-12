/*

  Project	: DBD::Fulcrum
  Module/Library:
  Author	: $Author: shari $
  Revision	: $Revision: 2.3 $
  Check-in date	: $Date: 1998/11/11 16:48:53 $
  Locked by	: $Locker:  $

  RCS-id: $Id: dbdimp.h,v 2.3 1998/11/11 16:48:53 shari Exp $ (c) 1996, Inferentia S.r.l. (Milano) IT

  $Log: dbdimp.h,v $
  Revision 2.3  1998/11/11 16:48:53  shari
  Multiple connects; release 0.19

  Revision 2.2  1998/11/11 11:50:57  shari
  Release 0.18.


*/


#include <sqlc.h>
/* Mapping of ODBC to SQLCLI names (used in dbdimp.c) */
typedef HDBC SQLHDBC;
typedef HENV SQLHENV;
typedef HSTMT SQLHSTMT;
typedef UCHAR SQLCHAR;
typedef SDWORD SQLINTEGER;
typedef SWORD SQLSMALLINT;


/* We are taking these from sqlext.h */

#define MAX_COLS		SQL_MAX_COLUMNS_IN_TABLE
#define MAX_COL_NAME_LEN	SQL_MAX_COLUMN_NAME_LEN
/* somewhat patchy */
#define MAX_BIND_VARS		SQL_MAX_COLUMNS_IN_SELECT


typedef struct imp_fbh_st imp_fbh_t;

struct imp_drh_st {
    dbih_drc_t com;				/* MUST be first element in structure	*/
    SQLHENV henv;
    int connects;
};

/* Define dbh implementor data structure */
struct imp_dbh_st {
  dbih_dbc_t com;				/* MUST be first element in structure	*/
  SQLHENV	henv;
  SQLHDBC	hdbc;
  
};


/* Define sth implementor data structure */
struct imp_sth_st {
  dbih_stc_t com;				/* MUST be first element in structure	*/
  SQLHENV	henv;
  SQLHDBC	hdbc;
  SQLHSTMT	phstmt;
  /* Input Details	*/
  char	*statement;  		/* sql (see sth_scan)		*/
  HV		*bind_names;
  
  /* Output Details		*/
  int        done_desc;  		/* have we described this sth yet ?	*/
  imp_fbh_t *fbh;	    		/* array of imp_fbh_t structs	*/
  char      *fbh_cbuf;    	/* memory for all field names       */
  int		long_buflen;      	/* length for long/longraw (if >0)	*/
  char 	long_trunc_ok;    	/* is truncating a long an error	*/
  int	    ful_last_row_id;	/* last row ins/upd/deleted via SQL_SS_ROW_ID */
};
#define IMP_STH_EXECUTING	0x0001


struct imp_fbh_st { 	/* field buffer EXPERIMENTAL */
    imp_sth_t *imp_sth;	/* 'parent' statement */

    /* description of the field	*/
    int  dbsize;
    short  dbtype;
    char	*cbuf;		/* ptr to name of select-list item */
    int  cbufl;			/* length of select-list item name */
    int  dsize;			/* max display size if field is a char */
    unsigned long prec;
    short  scale;
    short  nullok;

    /* Our storage space for the field data as it's fetched	*/
    short ftype;		/* external datatype we wish to get	*/
    short  indp;		/* null/trunc indicator variable	*/
    char	*buf;		/* data buffer (points to sv data)	*/
    short  bufl;		/* length of data buffer		*/
    int rlen;		/* length of returned data		*/
    short  rcode;		/* field level error status		*/

    SV	*sv;
};


typedef struct phs_st phs_t;    /* scalar placeholder   */

struct phs_st {	/* scalar placeholder EXPERIMENTAL	*/
    SV	*sv;		/* the scalar holding the value		*/
    short ftype;	/* external OCI field type		*/
    int indp;		/* null indicator or length indicator */
};


/* These defines avoid name clashes for multiple statically linked DBD's	*/

#define dbd_init		ful_init
#define dbd_db_login		ful_db_login
#define dbd_db_do		ful_db_do
#define dbd_db_commit		ful_db_commit
#define dbd_db_rollback		ful_db_rollback
#define dbd_db_disconnect	ful_db_disconnect
#define dbd_db_destroy		ful_db_destroy
#define dbd_db_STORE_attrib	ful_db_STORE_attrib
#define dbd_db_FETCH_attrib	ful_db_FETCH_attrib
#define dbd_st_prepare		ful_st_prepare
#define dbd_st_rows		ful_st_rows
#define dbd_st_execute		ful_st_execute
#define dbd_st_fetch		ful_st_fetch
#define dbd_st_finish		ful_st_finish
#define dbd_st_destroy		ful_st_destroy
#define dbd_st_blob_read	ful_st_blob_read
#define dbd_st_STORE_attrib	ful_st_STORE_attrib
#define dbd_st_FETCH_attrib	ful_st_FETCH_attrib
#define dbd_describe		ful_describe
#define dbd_bind_ph		ful_bind_ph


void	do_error _((SV *h,IV rc, SQLHENV henv, SQLHDBC hconn, 
					SQLHSTMT hstmt, SQLCHAR *what));
void	fbh_dump _((imp_fbh_t *fbh, int i));

void	dbd_preparse _((imp_sth_t *imp_sth, SQLCHAR *statement));
int	dbd_describe _((SV *h, imp_sth_t *imp_sth));

void    stmt_dump _((SQLHSTMT hstmt));

/* end */
