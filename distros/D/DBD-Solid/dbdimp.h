/* ========================================================================
 * Copyright (c) 1997  Thomas K. Wenrich
 * portions Copyright (c) 1994,1995,1996  Tim Bunce
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 * ======================================================================== */

typedef struct imp_fbh_st imp_fbh_t;

/* redefine dbd_xxx functions to sol_xxx  */
#define dbd_db_login       sol_db_login
#define dbd_db_do          sol_db_do
#define dbd_db_commit      sol_db_commit
#define dbd_db_rollback    sol_db_rolback
#define dbd_db_destroy     sol_db_destroy
#define dbd_db_STORE       sol_db_store
#define dbd_db_FETCH       sol_db_FETCH
#define dbd_db_disconnect  sol_db_disconnect
#define dbd_bind_ph        sol_bind_ph

#define dbd_st_prepare   sol_st_prepare
#define dbd_st_rows      sol_st_rows
#define dbd_st_execute   sol_st_execute
#define dbd_st_fetch     sol_st_fetch
#define dbd_st_finish    sol_st_finish
#define dbd_st_destroy   sol_st_destroy
#define dbd_st_readblob  sol_st_readblob
#define dbd_st_STORE     sol_st_STORE
#define dbd_st_FETCH     sol_st_FETCH
#define dbd_st_blob_read sol_st_blob_read

#define dbd_preparse    sol_preparse
#define dbd_describe    sol_describe
#define dbd_init        sol_init
#define _dbd_rebind_ph  _sol_rebind_ph

/* SOLID extensions */
/* SQL_TRANSLATE_OPTION values (SOLID Specific) */
#define SQL_SOLID_XLATOPT_DEFAULT        0
#define SQL_SOLID_XLATOPT_NOCNV          1
#define SQL_SOLID_XLATOPT_ANSI           2
#define SQL_SOLID_XLATOPT_PCOEM          3
#define SQL_SOLID_XLATOPT_7BITSCAND      4

/* -----------------------------------------------------------
* This holds global data of the driver itself. 
* And here is the first major modification required to 
* support ODBC 3.x: Solid changed HENV to SQLHENV
* (look it up in sqltypes.h line 90), which still doesn't match
* ODBC's SQL_HANDLE_ENV but does get rid of "incompatible pointer 
* type" warnings from the compiler.  --mms
* ------------------------------------------------------------ */
struct imp_drh_st
   {
   dbih_drc_t com;     /* MUST be first element in structure  */
   
   /* HENV henv; */
   SQLHENV henv;
   
   int connects;       /* connect count */
   };

/* ----------------------------------------------------------
* Define dbh implementor data structure 
* This holds everything to describe the database connection.
* Again, Solid changed HDBC to SQLHDBC for ODBC 3.x. --mms
* -----------------------------------------------------------*/
struct imp_dbh_st
   {
   dbih_dbc_t com;   /* MUST be first element in structure	*/
   
   /* HDBC hdbc; */
   SQLHDBC hdbc;
   };


/* -------------------------------------------------------------------
* Define sth implementor data structure 
* Same thing for HSTMT, only this one got rid of a ton of warnings,
* since a statement is pushed around in far more places than either
* connection or environment handles.  --mms
* -------------------------------------------------------------------- */
struct imp_sth_st
   {
   dbih_stc_t com;   /* MUST be first element in structure	*/

   /* HSTMT     hstmt; */
   SQLHSTMT  hstmt;
   int       done_desc;   /* have we described this sth yet ?	*/

   /* Input Details	*/
   char*     statement;   /* sql (see sth_scan)		*/
   HV*       params_hv;   /* see preparse function */
   AV*       params_av;   /* see preparse function */

#if 0 /* now handled by DBIc_ macros */
   int       long_buflen;      /* length for long/longraw (if >0)	*/
   int       long_trunc_ok;    /* is truncating a long an error	*/
#endif

   SWORD     n_result_cols;   /* number of result columns */

   UCHAR*    ColNames;        /* holds all column names; is referenced
                               * by ptrs from within the fbh structures */

   UCHAR*    RowBuffer;       /* holds row data; referenced from fbh */

   imp_fbh_t* fbh;            /* array of imp_fbh_t structs	*/

   SDWORD    RowCount;         /* Rows affected by insert, update, delete
                               * (unreliable for SELECT)*/

   int       eod;             /* End of data seen */
#if 0
   Cda_Def   *cda;            /* currently just points to cdabuf below */
   Cda_Def   cdabuf;


   /* Select Column Output Details	*/
   char*     fbh_cbuf;       /* memory for all field names       */
   int       t_dbsize;        /* raw data width of a row		*/
   /* Select Row Cache Details */
   int       cache_size;
   int       in_cache;
   int       next_entry;
   int       eod_errno;

   /* (In/)Out Parameter Details */
   bool      has_inout_params;
#endif
   };

#define IMP_STH_EXECUTING	0x0001

/* I didn't like this way of defining structs so I changed it. --mms*/
/* typedef struct fb_ary_st fb_ary_t; */   /* field buffer array	*/ 

#if 0
/* ----------------------------
* field buffer array
* ----------------------------- */
typedef struct fb_ary_st
   {
   ub2  bufl;       /* length of data buffer		*/
   sb2* aindp;      /* null/trunc indicator variable	*/
   ub1* abuf;       /* data buffer (points to sv data)	*/
   ub2* arlen;      /* length of returned data		*/
   ub2* arcode;     /* field level error status		*/
   } fb_ary_t;
#endif

/* field buffer EXPERIMENTAL */
struct imp_fbh_st
   { 	
   imp_sth_t* imp_sth; /* 'parent' statement */
   /* Solid's field description - SQLDescribeCol() */
   UCHAR*  ColName;         /* zero-terminated column name */
   SWORD   ColNameLen;
   UDWORD  ColDef;          /* precision */
   SWORD   ColScale;
   SWORD   ColSqlType;
   SWORD   ColNullable;
   SDWORD  ColLength;       /* SqlColAttributes(SQL_COLUMN_LENGTH) */
   SDWORD  ColDisplaySize;  /* SqlColAttributes(SQL_COLUMN_DISPLAY_SIZE) */

   /* Our storage space for the field data as it's fetched	*/
   SWORD   ftype;           /* external datatype we wish to get.
                             * Used as parameter to SQLBindCol().*/

   UCHAR*   data;           /* points into sth->RowBuffer */
   SDWORD datalen;          /* length returned from fetch for single row.*/    
   };


/* typedef struct phs_st phs_t; */   /* scalar placeholder   */

/* -------------------
* scalar placeholder
* -------------------- */
typedef struct phs_st
   {
   SWORD ftype;      /* external field type	       */
   SV* sv;           /* the scalar holding the value		*/
   int isnull;
   SDWORD cbValue;   /* length of returned value in Input: SQL_NULL_DATA */
   char name[1];     /* struct is malloc'd bigger as needed	*/
#if 0
   sword ftype;	

   sb2 indp;         /* null indicator */
   char* progv;
   ub2 arcode;
   ub2 alen;

   bool is_inout;
   int alen_incnull;	/* 0 or 1 if alen should include null	*/
#endif
   } phs_t;


/* --------------------------------------------------------------------
* function called by solid_error to decide whether solid_error should
* set error flag for DBI
* --------------------------------------------------------------------- */
typedef int (*T_IsAnError) _( (SV* h, 
                               RETCODE rc, 
                               char* sqlstate, 
                               const void* par
                           ));

const char* solid_error5 _(( SV* h, RETCODE rc, char* what, 
			  T_IsAnError func, const void* par) );
#define solid_error(a,b,c) solid_error5(a,b,c,NULL, NULL);
/* const char *solid_error _((SV *h, RETCODE rc, char *what)); */
/* end */
