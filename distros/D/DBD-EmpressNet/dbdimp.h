/*
	$Id: dbdimp.h, Empress 0.52,
*/

/* Define drh implementor driver handle */
struct imp_drh_st {
    dbih_drc_t	com;		/* DBI: MUST be 1st in structure */
 				/* Empress  shows nothing at this level */
};

/* Define dbh implementor data structure */
struct imp_dbh_st {
    dbih_dbc_t	com;		/* DBI: MUST be 1st in structure */
    int		c_num;		/* Empress connection number */
    int		autocommit;	/* for convenience */
};


/* Define statement data structure */
struct imp_sth_st {
	dbih_stc_t	com;		/* DBI: MUST be 1st in structure */
	int		st_num;		/* Empress Statement Number */
	int		nrows;		/* Number of rows affected by stmt */

	/* The rest is pretty much a straight copy of DBI::ODBC */
	/* it is all for parameter binding */
	char*		statement;	/* for preparsed statement */
	HV     		*all_params_hv;   /* all params, keyed by name    */

	/* these are for stored procedures, therefore not relevant */
	/* for current Empress; but the future is near */
	AV      	*out_params_av;   /* quick access to inout params */
	int		has_inout_params;
};


/* copy of the DBI::ODBC structure */
typedef struct phs_st phs_t;    /* scalar placeholder   */
 
struct phs_st {           /* scalar placeholder EXPERIMENTAL      */
	int idx;          /* index number of this param 1, 2, ... */
 
	SV  *sv;          /* the scalar holding the value         */
	int sv_type;      /* original sv type at time of bind     */
	bool is_inout;
	IV  maxlen;       /* max possible len (=allocated buffer) */
	char *sv_buf;     /* pointer to sv's data buffer          */
	int alen_incnull;
 
	short ftype;      /* external field type         */
	short sql_type;   /* the sql type the placeholder should have in SQL */
	long cbValue;     /* length of returned value */
                          /* in Input: SQL_NULL_DATA */
	char name[1];     /* struct is malloc'd bigger as needed  */
};
 



#define DBD_ERROR	0
#define	DBD_SUCCESS	1


#define dbd_init                emp_init
#define dbd_db_login            emp_db_login
#define dbd_db_commit           emp_db_commit
#define dbd_db_rollback         emp_db_rollback
#define dbd_db_disconnect       emp_db_disconnect
#define dbd_db_destroy          emp_db_destroy
#define dbd_db_STORE_attrib     emp_db_STORE_attrib
#define dbd_db_FETCH_attrib     emp_db_FETCH_attrib
#define dbd_st_prepare          emp_st_prepare
#define dbd_st_rows             emp_st_rows
#define dbd_st_execute          emp_st_execute
#define dbd_st_fetch            emp_st_fetch
#define dbd_st_finish           emp_st_finish
#define dbd_st_destroy          emp_st_destroy
#define dbd_st_blob_read        emp_st_blob_read
#define dbd_st_STORE_attrib     emp_st_STORE_attrib
#define dbd_st_FETCH_attrib     emp_st_FETCH_attrib
#define dbd_describe            emp_describe
#define dbd_bind_ph             emp_bind_ph
#define dbd_discon_all		emp_discon_all


/**** end of dbdimp.h ****/

