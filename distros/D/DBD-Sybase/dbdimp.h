/*
 $Id: dbdimp.h,v 1.45 2017/09/10 14:31:45 mpeppler Exp $

 Copyright (c) 1997-2011  Michael Peppler

 You may distribute under the terms of either the GNU General Public
 License or the Artistic License, as specified in the Perl README file.

 Based on DBD::Oracle dbdimp.h, Copyright (c) 1994,1995 Tim Bunce

 */

typedef struct imp_fbh_st imp_fbh_t;

/*
 ** Maximum character buffer for displaying a column
 */
#define MAX_CHAR_BUF	1024

typedef struct _col_data {
	CS_SMALLINT indicator;
	CS_INT type;
	CS_INT realType;
	CS_INT realLength;
	union {
		CS_CHAR *c;
		CS_INT i;
#if defined(CS_UINT_TYPE)
		CS_UINT ui;
		CS_BIGINT bi;
		CS_UBIGINT ubi;
#endif
		CS_FLOAT f;
		CS_DATETIME dt;
#if defined(CS_DATE_TYPE)
		CS_DATE d;
		CS_TIME t;
#endif
#if defined(CS_BIGDATETIME_TYPE)
    CS_BIGDATETIME bdt;
    CS_BIGTIME bt;
#endif
		CS_MONEY mn;
		CS_NUMERIC num;
		CS_VOID *p;
	} value;
	int v_alloc;
	CS_INT valuelen;
	CS_VOID *ptr;
} ColData;

struct imp_drh_st {
	dbih_drc_t com; /* MUST be first element in structure	*/
};

#define MAX_SQL_SIZE 255
#define VERSION_SIZE 20

#define UID_PWD_SIZE 256

/* Define dbh implementor data structure */
struct imp_dbh_st {
	dbih_dbc_t com; /* MUST be first element in structure	*/

	CS_CONNECTION *connection;
	CS_LOCALE *locale;
	CS_IODESC iodesc;
	char tranName[32];
	int inTransaction;
	int doRealTran;
	int chainedSupported;
	int quotedIdentifier;
	int useBin0x;
	int binaryImage;
	int dateFmt; /* 0 for Sybase native, 1 for ISO8601 */
	int optSupported; /* 0 if the server doesn't support ct_options() */

	int lasterr;
	int lastsev;

	char uid[UID_PWD_SIZE];
	char pwd[UID_PWD_SIZE];

	char server[64];
	char charset[64];
	char packetSize[64];
	char language[64];
	char ifile[255];
	char loginTimeout[64];
	char timeout[64];
	char scriptName[255];
	char hostname[255];
	char database[260];
	char curr_db[36];
	char tdsLevel[30];
	char encryptPassword[10];
	char kerberosPrincipal[256];
	char host[64]; /* for use with CS_SERVERADDR */
	char port[20]; /* for use with CS_SERVERADDR */
	char maxConnect[25];
	char sslCAFile[255];
	char blkLogin[16];
	char tds_keepalive[16];
	char serverType[32];

	char serverVersion[VERSION_SIZE];
	char serverVersionString[255];
  int  isMSSql;

	int isDead;

	SV *err_handler;
	SV *row_cb;
	SV *kerbGetTicket;

	int enable_utf8;

	int showEed;
	int showSql;
	int flushFinish;
	int rowcount;
	int doProcStatus;
	int deadlockRetry;
	int deadlockSleep;
	int deadlockVerbose;
	int nsqlNoStatus;

	int disconnectInChild; /* if set, then OK to disconnect in child process
	 (even if pid different from pid that created the connection), subject to the
	 setting of InactiveDestroy */

	int noChildCon; /* Don't create child connections for
	 simultaneous statement handles */
	int failedDbUseFatal;
	int bindEmptyStringNull;
	int alwaysForceFailure; /* PR/471 */

	int inUse; /* Set when the primary statement handle
	 (the one that uses the connection referred
	 to here) is in use. */
	int pid; /* Set when the connection is opened, used checked in the DESTROY() call */
	int init_done;

	char *sql;

	struct imp_sth_st *imp_sth; /* needed for BCP handling */
};

typedef struct phs_st {
	int ftype;
	int sql_type;
	SV *sv;
	int sv_type;
	bool is_inout;
	bool is_boundinout;
	IV maxlen;

	char *sv_buf;

	CS_DATAFMT datafmt;
	char varname[34];

	int alen_incnull; /* 0 or 1 if alen should include null	*/
	char name[1]; /* struct is malloc'd bigger as needed	*/

} phs_t;

/* struct to store pointer to output parameter and returned length */
typedef struct boundparams_st {
    phs_t *phs;
    int len;
} boundparams_t;


/* Define sth implementor data structure */
struct imp_sth_st {
	dbih_stc_t com; /* MUST be first element in structure	*/

	CS_CONNECTION *connection; /* set if this is a sub-connection */
	CS_COMMAND *cmd;
	ColData *coldata;
	CS_DATAFMT *datafmt;

	int numCols;
	CS_INT lastResType;
	CS_INT numRows;
	int moreResults;

	int doProcStatus;
	int lastProcStatus;
	int noBindBlob;

	int retryCount;

	int exec_done;

	/* Input Details	*/
	char dyn_id[50]; /* The id for this ct_dynamic() call */
	int dyn_execed; /* true if ct_dynamic(CS_EXECUTE) has been called */
	int type; /* 0 = normal, 1 => rpc */
	char proc[150]; /* used for rpc calls */
	char *statement; /* sql (see sth_scan)		*/
	HV *all_params_hv; /* all params, keyed by name	*/
	AV *out_params_av; /* quick access to inout params	*/
	int syb_pad_empty; /* convert ""->" " when binding	*/

	/* Select Column Output Details	*/
	int done_desc; /* have we described this sth yet ?	*/

	/* BCP functionality */
	int bcpFlag;
	int bcpIdentityFlag;
	int bcpIdentityCol;
	CS_BLKDESC *bcp_desc;
	int bcpRows; /* incremented for each successful call to blk_rowxfer, set to -1 when blk_done(CS_BLK_CANCEL) has been called. */
	int bcpAutoCommit;

	/* (In/)Out Parameter Details */
	int has_inout_params;
};
#define IMP_STH_EXECUTING	0x0001

int syb_ping(SV *dbh, imp_dbh_t *imp_dbh);
int syb_st_cancel(SV *sth, imp_sth_t *imp_sth);

