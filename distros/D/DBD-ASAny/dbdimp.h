/* these are (almost) random values ! */
#define MAX_COLS 1025

#define BIND_VARIABLES_INITIAL_SQLDA_SIZE 	100
#define OUTPUT_VARIABLES_INITIAL_SQLDA_SIZE	100

typedef char a_cursor_name[32];
#define NO_CURSOR_ID	(~0UL)
#define AVAILABLE_CURSORS_GROWTH_AMOUNT 10

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
struct imp_dbh_st {
    dbih_dbc_t 		com;		/* MUST be first element in structure	*/

    SQLCA		sqlca;
    SQLCA		*sqlcap;  // needed so server-side perl can use an
                                  // existing connection
    // We want to reuse cursor names because dblib
    // holds onto cursor information in case it is reopened
    // without being redeclared
    unsigned long	available_cursors_top;
    unsigned long	available_cursors_size;
    unsigned long	*available_cursors;
    unsigned long	next_cursor_id;
    unsigned long	next_tempvar_id;
};

struct imp_drh_st {
    dbih_drc_t com;		/* MUST be first element in structure	*/
};

struct sql_type_info {
    short int	sqltype;
    short int	sqllen;
};

/* Define sth implementor data structure */
struct imp_sth_st {
    dbih_stc_t com;	    	/* MUST be first element in structure	*/

    a_sql_statement_number	statement_number;
    SQLDA			*input_sqlda;	/* Bind variables */
    SQLDA			*output_sqlda;
    short			*original_input_indicators;
    struct sql_type_info	*original_output_type_info;
    int				cursor_open;
    int				row_count;
    char      			*statement;   	/* sql (see sth_scan)			*/
    HV        			*bind_names;
    int        			done_prepare;   /* have we prepared this sth yet ?	*/
    int        			done_desc;   	/* have we described this sth yet ?	*/
    int  			long_trunc_ok;  /* is truncating a long an error	*/
    unsigned long		cursor_id;
    a_cursor_name		cursor_name;
    int				has_output_params;
    int				statement_type;
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
    short 		ftype;		/* external SqlAnywhere field type	*/
    unsigned short 	indp;		/* null indicator			*/
    int			is_inout;
    IV			maxlen;
    IV			sql_type;
    IV			in_ordinal;
    IV			out_ordinal;
    unsigned long	tempvar_id;
    a_tempvar_name	tempvar_name;
};

void	ssa_error _((SV *h, SQLCA *sqlca, an_sql_code sqlcode, char *what));

#define dbd_init		asa_init
#define dbd_db_login		asa_db_login
#define dbd_db_do		asa_db_do
#define dbd_db_commit		asa_db_commit
#define dbd_db_rollback		asa_db_rollback
#define dbd_db_disconnect	asa_db_disconnect
#define dbd_db_destroy		asa_db_destroy
#define dbd_db_STORE_attrib	asa_db_STORE_attrib
#define dbd_db_FETCH_attrib	asa_db_FETCH_attrib
#define dbd_st_prepare		asa_st_prepare
#define dbd_st_rows		asa_st_rows
#define dbd_st_execute		asa_st_execute
#define dbd_st_fetch		asa_st_fetch
#define dbd_st_finish		asa_st_finish
#define dbd_st_destroy		asa_st_destroy
#define dbd_st_blob_read	asa_st_blob_read
#define dbd_st_STORE_attrib	asa_st_STORE_attrib
#define dbd_st_FETCH_attrib	asa_st_FETCH_attrib
#define dbd_describe		asa_describe
#define dbd_bind_ph		asa_bind_ph

/* end */
