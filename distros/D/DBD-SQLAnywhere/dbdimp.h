// ***************************************************************************
// Copyright (c) 2015 SAP SE or an SAP affiliate company. All rights reserved.
// ***************************************************************************
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
//   While not a requirement of the license, if you do modify this file, we
//   would appreciate hearing about it. Please email
//   sqlany_interfaces@sybase.com
//
//====================================================

/* these are (almost) random values ! */
#define MAX_COLS 1025

#define BIND_VARIABLES_INITIAL_SQLDA_SIZE 	100
#define OUTPUT_VARIABLES_INITIAL_SQLDA_SIZE	100

// SQLDA var field requires 2 bytes of length information in addition
// to the data. We must prevent sqlvar->sqllen field from overflowing
// (sqlvar->sqllen is a 16-bit signed integer)
#define MAX_DT_VARCHAR_LENGTH		32765

// When transferring a DT_STRING string, this is the max size (we 
// leave space for a NULL byte).
#define MAX_DT_STRING_LENGTH		32766

// A default LongReadLen of 64K is inconvenient.
#define DEFAULT_LONG_READ_LENGTH	(1024*1024)

#define MAX_TIME_STRING_LENGTH		60
#ifndef DT_BASE100
    #define DT_BASE100 492
#endif

typedef char a_tempvar_name[32];
typedef struct imp_fbh_st imp_fbh_t;

/* Define dbh implementor data structure */
// Note: only one thread may use a connection at one time

typedef struct SACAPI
{
    int				refcount;
    SQLAnywhereInterface	api;
    void			*context;
} SACAPI;

SACAPI *SACAPI_AddRef();
void SACAPI_Release( SACAPI *sacapi );

struct imp_dbh_st {
    dbih_dbc_t 			com;		/* MUST be first element in structure	*/

    a_sqlany_connection		*conn;
    struct SQLCA		*ss_sqlca;	/* server-side SQLCA */
    SACAPI			*sacapi;
};

struct imp_drh_st {
    dbih_drc_t 			com;		/* MUST be first element in structure	*/
    SACAPI			*sacapi;
};

struct sql_type_info {
    short int	sqltype;
    short int	sqllen;
};

/* Define sth implementor data structure */
struct imp_sth_st {
    dbih_stc_t com;	    	/* MUST be first element in structure	*/

    a_sqlany_stmt		*statement;
    int				row_count;
    char      			*sql_statement;   	/* sql (see sth_scan)			*/
    HV        			*bind_names;
    int				num_bind_params_scanned;	/* preparse found this many params */
    int				num_bind_params;		/* the engine described this many */
    int  			long_trunc_ok;  /* is truncating a long an error	*/
};
#define IMP_STH_EXECUTING	0x0001

#define SQLPRES_STMT_OTHER             0
#define SQLPRES_STMT_DELETE            1
#define SQLPRES_STMT_INSERT            2
#define SQLPRES_STMT_SELECT            3
#define SQLPRES_STMT_UPDATE            4
#define SQLPRES_STMT_CALL              5
#define SQLPRES_STMT_PROCEDURE         6
#define SQLPRES_STMT_OPENCURSOR        7
#define SQLPRES_STMT_FETCH             8
#define SQLPRES_STMT_CLOSECURSOR       9
#define SQLPRES_STMT_TRUNCATE_TABLE    10
#define SQLPRES_STMT_TSQLSELECTINTO    11
#define SQLPRES_STMT_READTEXT          12
#define SQLPRES_STMT_BATCH             13
#define SQLPRES_STMT_TERMINATE         14

typedef struct phs_st phs_t;    /* scalar placeholder   */

struct phs_st {	/* scalar placeholder EXPERIMENTAL	*/
    SV			*sv;		/* the scalar holding the value		*/
    unsigned short 	indp;		/* null indicator			*/
    int			is_inout;
    IV			maxlen;
    int			sql_type;	/* the user-specified SQL (ODBC) datatype */
    int			ordinal;	/* ordinals have origin "1", not "0" */
    
    // this are for storing a pointer to the bind values
    int			in_param_is_null;
    size_t		in_param_length;

    int			out_param_is_null;
    size_t		out_param_length;
};

void ssa_error( pTHX_ SV *h, a_sqlany_connection *sqlca, int sqlcode, char *what );

#define dbd_init		sqlanywhere_init
#define dbd_dr_init		sqlanywhere_dr_init
#define dbd_dr_destroy		sqlanywhere_dr_destroy
#define dbd_db_login		sqlanywhere_db_login
#define dbd_db_login6		sqlanywhere_db_login6
#define dbd_db_do		sqlanywhere_db_do
#define dbd_db_commit		sqlanywhere_db_commit
#define dbd_db_rollback		sqlanywhere_db_rollback
#define dbd_db_disconnect	sqlanywhere_db_disconnect
#define dbd_db_destroy		sqlanywhere_db_destroy
#define dbd_db_STORE_attrib	sqlanywhere_db_STORE_attrib
#define dbd_db_FETCH_attrib	sqlanywhere_db_FETCH_attrib
#define dbd_st_prepare		sqlanywhere_st_prepare
#define dbd_st_rows		sqlanywhere_st_rows
#define dbd_st_execute		sqlanywhere_st_execute
#define dbd_st_fetch		sqlanywhere_st_fetch
#define dbd_st_more_results	sqlanywhere_st_more_results
#define dbd_st_finish		sqlanywhere_st_finish
#define dbd_st_destroy		sqlanywhere_st_destroy
#define dbd_st_blob_read	sqlanywhere_st_blob_read
#define dbd_st_STORE_attrib	sqlanywhere_st_STORE_attrib
#define dbd_st_FETCH_attrib	sqlanywhere_st_FETCH_attrib
#define dbd_describe		sqlanywhere_describe
#define dbd_bind_ph		sqlanywhere_bind_ph

int  dbd_dr_init( SV *drh );
int  dbd_dr_destroy( SV *drh );
/* end */
