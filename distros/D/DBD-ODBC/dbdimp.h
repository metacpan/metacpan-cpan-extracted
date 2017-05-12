/*
 * Copyright (c) 1997-2001 Jeff Urlwin
 * portions Copyright (c) 1997  Thomas K. Wenrich
 * portions Copyright (c) 1994,1995,1996  Tim Bunce
 * portions Copyright (c) 1997-2001 Jeff Urlwin
 * portions Copyright (c) 2001 Dean Arnold
 * portions Copyright (c) 2007-2013 Martin J. Evans
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 */

/* some constants for driver specific types */
#define MS_SQLS_XML_TYPE -152

typedef struct imp_fbh_st imp_fbh_t;

/* This holds global data of the driver itself.
 */
struct imp_drh_st {
    dbih_drc_t com;		/* MUST be first element in structure	*/
    SQLHENV henv;
    int connects;		/* connect count */
};

/* Define dbh implementor data structure
   This holds everything to describe the database connection.
 */
struct imp_dbh_st {
    dbih_dbc_t com;		/* MUST be first element in structure	*/
    SQLHENV henv;	        /* copy from imp_drh for speed		*/
    SQLHDBC hdbc;
    char odbc_ver[20];  /* ODBC compat. version for driver */
    SQLSMALLINT max_column_name_len;
    /* flag to ignore named parameters */
    int  odbc_ignore_named_placeholders;
    /* flag to set default binding type (experimental) */
    SQLSMALLINT  odbc_default_bind_type;
    /* force bound parameters to be this type */
    SQLSMALLINT  odbc_force_bind_type;
    /* flag to see if SQLDescribeParam is supported */
    int  odbc_sqldescribeparam_supported;
    /* flag to see if SQLMoreResults is supported */
    int  odbc_sqlmoreresults_supported;
    /* flag to work around SQLServer bug and defer binding until
       last possible moment - execute instead of bind time. Should only
       be set for SQL Server currently.
       The problem was that SQL Server was not handling binding an undef
       then binding the real value. This happened with older SQLServer
       2000 drivers on varchars and is still happening with date */
    int	 odbc_defer_binding;
    /* force rebinding the output columns after each execute to
       resolve some issues where certain stored procs can return
       multiple result sets */
    int  odbc_force_rebind;
    SQLINTEGER odbc_query_timeout;
    /* point at which start using SQLPutData */
    IV odbc_putdata_start;
    /* whether built WITH_UNICODE */
    int  odbc_has_unicode;
    /* flag to set asynchronous execution */
    int  odbc_async_exec;
    /* flag for executing SQLExecDirect instead of SQLPrepare and SQLExecute.
       Magic happens at SQLExecute() */
    int  odbc_exec_direct;
    /* flag indicating if we should pass SQL_DRIVER_COMPLETE to
       SQLDriverConnect */
    int  odbc_driver_complete;
    /* used to disable describing paramters with SQLDescribeParam */
    int odbc_describe_parameters;
    /* flag to store the type of asynchronous execution the driver supports */
    SQLUINTEGER odbc_async_type;
    SV *odbc_err_handler;     /* contains the error handler coderef */
    /* The out connection string after calling SQLDriverConnect */
    SV *out_connect_string;
    /* default row cache size in rows for statements */
    int  RowCacheSize;
    /* if SQL_COLUMN_DISPLAYS_SIZE or SQL_COLUMN_LENGTH are not defined or
     * SQLColAttributes for these attributes fails we fallback on a default
     * value. */
    SQLLEN odbc_column_display_size;

    /* Some databases (like Aster) return all strings UTF-8 encoded.
     * If this is set (1), SvUTF8_on() will be called on all strings returned
     * from the driver.
     */
    int odbc_utf8_on;
    /* save the value passed to odbc_SQL_ROWSET_SIZE so we can return
     * it without calling SQLGetConnectAttr because some MS driver
     * managers (e.g., since MDAC 2.7 and on 64bit Windows) don't allow
     * you to retrieve it. Normally, we'd just say stop fetching it but
     * until DBI 1.616 DBI itself issues a FETCH if you mention
     * odbc_SQL_ROWSET_SIZE in the connect method.*/
    SQLULEN rowset_size;

    /*
     *  We need special workarounds for the following drivers. To avoid
     *  strcmping their names every time we do it once and store the type here
     */
    enum {
        DT_DONT_CARE,
        DT_SQL_SERVER,                          /* SQLSRV32.DLL */
        DT_SQL_SERVER_NATIVE_CLIENT,    /* sqlncli10.dll | SQLNCLI.DLL */
        DT_MS_ACCESS_JET,                          /* odbcjt32.dll */
        DT_MS_ACCESS_ACE,                          /* ACEODBC.DLL */
        DT_ES_OOB,                                 /* Easysoft OOB */
        DT_FIREBIRD,                                /* Firebird OdbcFb */
        DT_FREETDS                                 /* freeTDS libtdsodbc.so */
    } driver_type;
    char odbc_driver_name[80];
    char odbc_driver_version[20];
    char odbc_dbms_name[80];
    char odbc_dbms_version[80];
    int odbc_batch_size;	/* rows in a batch operation */
    int odbc_array_operations;	/* enable/disable inbuilt execute_for_fetch etc */
    /*int (*taf_callback_fn)(SQLHANDLE connection, int type, int event);*/
    SV *odbc_taf_callback;
    /* If the driver does not support SQLDescribeParam or SQLDescribeParam
       fails we fall back on a default type. However, some databases need
       that type to be different depending on the length of the column.
       MS SQL Server needs to switch from VARCHAR to LONGVARCHAR at 4000
       bytes whereas MS Access at 256. We set the switch point once we know
       the database. */
    int switch_to_longvarchar;
    /* Initially -1 and if someone sets ReadOnly to true it becomes 1.
       Even if the ODBC driver cannot set SQL_ATTR_ACCESS_MODE but
       ReadOnly is set to 1, read_only is 1 and that is returned without asking
       the ODBC Driver what it is currently set to, Of course setting it
       to false works similarly. */
    int read_only;
    int catalogs_supported;
    SQLUINTEGER schema_usage;
};

/* Define sth implementor data structure */
struct imp_sth_st {
    dbih_stc_t com;		/* MUST be first element in structure	*/

    HENV       henv;		/* copy for speed	*/
    HDBC       hdbc;		/* copy for speed	*/
    SQLHSTMT   hstmt;

    int        moreResults;	/* are there more results to fetch?	*/
    int        done_desc;	/* have we described this sth yet?	*/
    int        done_bind;       /* have we bound the columns yet? */

    /* Input Details	*/
    char      *statement;	/* sql (see sth_scan)		*/
    HV        *all_params_hv;   /* all params, keyed by name    */
    AV        *out_params_av;   /* quick access to inout params */
    int     has_inout_params;

    UCHAR    *ColNames;		/* holds all column names; is referenced
				 * by ptrs from within the fbh structures
				 */
    UCHAR    *RowBuffer;	/* holds row data; referenced from fbh */
    SQLLEN   RowBufferSizeReqd;
    imp_fbh_t *fbh;		/* array of imp_fbh_t structs	*/

    SQLLEN   RowCount;		/* Rows affected by insert, update, delete
				 * (unreliable for SELECT)
				 */
    SV	*param_sts;			/* ref to param status array for array bound PHs */
    int params_procd;			/* to recv number of parms processed by an SQLExecute() */
    SV	*row_sts;			/* ref to row status array for array bound columns */
    UDWORD rows_fetched;		/* actual number of rows fetched for array binding */
    UDWORD max_rows;			/* max number of rows per fetch for array binding */
    UWORD *row_status;			/* row indicators for array binding */
    int  odbc_ignore_named_placeholders;	/* flag to ignore named parameters */
    SQLSMALLINT odbc_default_bind_type;	/* flag to set default binding type (experimental) */
    SQLSMALLINT odbc_force_bind_type;	/* force bound parameters to be this type */
    int  odbc_exec_direct;		/* flag for executing SQLExecDirect instead of SQLPrepare and SQLExecute.  Magic happens at SQLExecute() */
  int  odbc_force_rebind; /* force rebinding the output columns after each execute to */
			       /* resolve some issues where certain stored procs can return */
       /* multiple result sets */
    SQLINTEGER odbc_query_timeout;
    IV odbc_putdata_start;
    IV odbc_column_display_size;
    int odbc_utf8_on;
    int odbc_describe_parameters;
    SQLUSMALLINT *param_status_array; /* array for execute_for_fetch parameter status */
    SQLULEN params_processed;	      /* for execute_for_fetch */
    int odbc_batch_size;	/* rows in a batch operation */
    int odbc_array_operations;	/* enable/disable inbuilt execute_for_fetch etc */
    int allocated_batch_size;		/* size used for last batch */
};
#define IMP_STH_EXECUTING	0x0001


struct imp_fbh_st { 	/* field buffer EXPERIMENTAL */
    imp_sth_t *imp_sth;	/* 'parent' statement */
    /* field description - SQLDescribeCol() */
    UCHAR *ColName;		/* zero-terminated column name */
    SQLSMALLINT ColNameLen;
    SQLULEN ColDef;		/* precision */
    SQLSMALLINT ColScale;
    SQLSMALLINT ColSqlType;
    SQLSMALLINT ColNullable;
    SQLLEN ColLength;		/* SqlColAttributes(SQL_COLUMN_LENGTH) */
    SQLLEN ColDisplaySize;	/* SqlColAttributes(SQL_COLUMN_DISPLAY_SIZE) */

    /* Our storage space for the field data as it's fetched	*/
    SWORD ftype;		/* external datatype we wish to get.
				 * Used as parameter to SQLBindCol().
				 */
    UCHAR *data;		/* points into sth->RowBuffer */
    SQLLEN datalen;		/* length returned from fetch for single row. */
    unsigned long bind_flags;   /* flags passed to bind_col */
    /* Be careful: bind_flags mix our flags like ODBC_TREAT_AS_LOB with
       DBI's DBIstcf_DISCARD_STRING and DBIstcf_STRICT. If you add a
       flag make sure it does not clash */
#define ODBC_TREAT_AS_LOB 0x100
    IV req_type;                /* type passed to bind_col */
    /* have we already bound this column because if we have you cannot change
       the type afterwards as it is not rebound */
    unsigned int bound;
};


typedef struct phs_st phs_t;    /* scalar placeholder   */

struct phs_st {             /* scalar placeholder */
    SQLUSMALLINT idx;       /* index number of this param 1, 2, ...	*/
    SV *sv;                 /* the scalar holding the value */
    int sv_type;            /* original sv type at time of bind */
    char *sv_buf;           /* pointer to sv's data buffer */
    int svok;               /* result of SvOK on output param at last bind time */
    SQLULEN param_size;     /* value returned from SQLDescribeParam */
    int describe_param_called; /* has SQLDescribeParam been called */
    SQLRETURN describe_param_status;
                            /* status return from last SQLDescribeParam */
    int biggestparam;       /* if sv_type is VARCHAR, size of biggest so far */
    bool is_inout;          /* is this an output parameter? */
    IV  maxlen;             /* max possible len (=allocated buffer) for */
                            /* out parameters */
    SQLLEN strlen_or_ind;   /* SQLBindParameter StrLen_or_IndPtr argument */
                            /* containg parameter length on input for input */
                            /* and returned parameter size for output params */
    SQLLEN *strlen_or_ind_array; /* as above but an array for execute_for_fetch */

    char *param_array_buf;  /* allocated buffer for array of params */
    SQLSMALLINT requested_type; /* type optionally passed in bind_param call */
    SQLSMALLINT value_type; /* SQLBindParameter value_type - a SQL C type */
    SQLSMALLINT described_sql_type;
                            /* sql type as described by SQLDescribeParam */
    SQLSMALLINT sql_type;   /* the sql type of the placeholder */

    /* Remaining values passed to SQLBindParameter that we record to detect
       if we need to rebind due to changed args */
    UCHAR *bp_value_ptr;       /* ptr to actual value */
    SQLSMALLINT bp_d_digits;   /* decimal digits */
    SQLULEN bp_column_size;
    SQLLEN bp_buffer_length;

    char name[1];           /* struct is malloc'd bigger as needed */
};


/* These defines avoid name clashes for multiple statically linked DBD's        */

#define dbd_init		odbc_init
#define dbd_db_login		odbc_db_login
#define dbd_db_login6		odbc_db_login6
#define dbd_data_sources dbd_data_sources
/*
 * Not defined by DBI
 * #define dbd_db_do		odbc_db_do
 */
#define dbd_db_login6_sv        odbc_db_login6_sv
#define dbd_db_commit		odbc_db_commit
#define dbd_db_rollback		odbc_db_rollback
#define dbd_db_disconnect	odbc_db_disconnect
#define dbd_db_destroy		odbc_db_destroy
#define dbd_db_STORE_attrib	odbc_db_STORE_attrib
#define dbd_db_FETCH_attrib	odbc_db_FETCH_attrib
#define dbd_st_prepare		odbc_st_prepare
#define dbd_st_prepare_sv       odbc_st_prepare_sv
/*#define dbd_st_rows		odbc_st_rows*/
#define dbd_st_execute		odbc_st_execute
#define dbd_st_execute_iv   odbc_st_execute_iv
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
#define dbd_st_tables		odbc_st_tables
#define dbd_st_primary_keys	odbc_st_primary_keys
#define dbd_db_execdirect	odbc_db_execdirect
#define dbd_st_bind_col     	odbc_st_bind_col
/* end */
