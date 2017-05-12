/*
 * @(#)$Id: dbdimp.ec,v 58.4 1998/01/15 18:46:24 johnl Exp $ 
 *
 * DBD::Sqlflex for Perl Version 5 -- implementation details
 *
 * Portions Copyright
 *           (c) 1994-95 Tim Bunce
 *           (c) 1995-96 Alligator Descartes
 *           (c) 1994    Bill Hailes
 *           (c) 1996    Terry Nightingale
 *           (c) 1996-98 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */
#include <sqlhdr.h>
#include <sqtypes.h>

/*TABSTOP=4*/

#ifndef lint
static const char rcs[] = "@(#)$Id: dbdimp.ec,v 58.4 1998/01/15 18:46:24 johnl Exp $";
#endif

#include <stdio.h>
#include <string.h>

#define MAIN_PROGRAM	/* Embed version information for JLSS headers */
#include "Sqlflex.h"
#include "decsci.h"

#define L_CURLY	'{'
#define R_CURLY	'}'

DBISTATE_DECLARE;

static SV *ix_errnum = NULL;
static SV *ix_errstr = NULL;
static SV *ix_state = NULL;

extern int *  pcGSQLFlexSvc;

char * my_errlist[] =
  {
  "Duplicate record",              /* 100 */
  "File not open",                 /* 101 */
  "Illegal argument",              /* 102 */
  "Bad key descriptor",            /* 103 */
  "Too many files",                /* 104 */
  "Corrupted isam file",           /* 105 */
  "Need exclusive access",         /* 106 */
  "Record or file locked",         /* 107 */
  "Index already exists",          /* 108 */
  "Illegal primary key operation", /* 109 */
  "End of file",                   /* 110 */
  "Record not found",              /* 111 */
  "No current record",             /* 112 */
  "File is in use",                /* 113 */
  "File name too long",            /* 114 */
  "Bad lock device",               /* 115 */
  "Can't allocate memory",         /* 116 */
  "Bad collating table",           /* 117 */
  "Can't read log record",         /* 118 */
  "Bad log record",                /* 119 */
  "Can't open log file",           /* 120 */
  "Can't write log record",        /* 121 */
  "No transaction",                /* 122 */
  "No shared memory",              /* 123 */
  "No begin work yet",             /* 124 */
  "Can't use nfs",                 /* 125 */
  "Bad rowid",                     /* 126 */
  "No primary key",                /* 127 */
  "No logging",                    /* 128 */
  "Too many users",                /* 129 */
  "No such dbspace",               /* 130 */
  "No free disk space",            /* 131 */
  "Rowsize too big",               /* 132 */
  "Audit trail exists",            /* 133 */
  "No more locks"                  /* 134 */
  };

static void dbd_ix_blobs(imp_sth_t *imp_sth);
static int dbd_ix_declare(imp_sth_t *imp_sth);
static void dbd_ix_printenv(const char *s1, const char *s2);
static void dbd_st_destroyer(void *data);
static void del_connection(imp_dbh_t *imp_dbh);
static void dbd_db_destroyer(void *data);
static void dbd_ix_savesqlca(imp_dbh_t *imp_dbh);
static void dbd_ix_sqlcode(imp_dbh_t *imp_dbh);
static void     new_connection(imp_dbh_t *imp_dbh);
static int dbd_db_setconnection(imp_dbh_t *imp_dbh);
static int      dbd_ix_begin(imp_dbh_t *dbh);
static int      dbd_ix_commit(imp_dbh_t *dbh);
static int      dbd_ix_rollback(imp_dbh_t *dbh);
static void noop(void *data);
static void     new_statement(imp_dbh_t *imp_dbh, imp_sth_t *imp_sth);
static void del_statement(imp_sth_t *imp_sth);
static int dbd_ix_setbindnum(imp_sth_t *imp_sth, int items);
static int dbd_ix_bindsv(imp_sth_t *imp_sth, int idx, SV *val);
static int count_blobs(char *descname, int ncols);
static int dbd_ix_preparse(char *statement);
static char *decgen(dec_t *val, int plus);
static int dbd_ix_open(imp_sth_t *imp_sth);
static int dbd_ix_exec(imp_sth_t *imp_sth);

/*
** SQLSTATE is only supported in version 6.00 and later.
** The DBI 0.81 spec says that the value S1000 should be returned
** when the implementation does not support SQLSTATE.
*/

static const char SQLSTATE[] = " S1000";


/* One day, these will go!  Maybe... */
static void del_statement(imp_sth_t *imp_sth);
static dbd_ix_begin(imp_dbh_t *dbh);

/* ================================================================= */
/* ================ Named CURSOR operations (KBC) ================== */
/* ================================================================= */

struct ind {
    short indicator;
    short origType;
};

struct anon_storage {
   struct anon_storage *next;
   union {
      char data[1];
      struct ind indbuf[1];
      struct sqlvar_struct vars[1];
   } d;
};

struct named_storage {
   char *name;
   struct named_storage *next;
   struct named_storage *prev;
   int allocated;
   struct anon_storage *bufs;
   union {
      _SQCURSOR     *cursor;
      struct sqlda  *descriptor;
   } storage;
}  *named_stores = NULL;
 
static struct named_storage *allocate_storage(char *name)
{
   struct named_storage *ns 
       = (struct named_storage *) malloc (sizeof (struct named_storage));

   ns->name = (char *) malloc (strlen(name) + 1);
   strcpy(ns->name,name);

   ns->prev = NULL;
   ns->next = named_stores;
   if (named_stores)
       named_stores->prev=ns;
   ns->allocated = 1;
   ns->bufs = NULL;
   named_stores = ns;

   return (ns);
}

static _SQCURSOR *allocate_cursor(char *name)
{
   struct named_storage *ns = allocate_storage(name);
   ns->storage.cursor = (_SQCURSOR *) malloc (sizeof(_SQCURSOR));
   memset(ns->storage.cursor,0,sizeof(_SQCURSOR));
   return(ns->storage.cursor);
}

static struct sqlda *allocate_descriptor(char *name)
{
   struct named_storage *ns = allocate_storage(name);
   ns->storage.descriptor = (struct sqlda *) malloc(sizeof (struct sqlda ));
   memset(ns->storage.descriptor,0,sizeof (struct sqlda ));
   return(ns->storage.descriptor);
}

static void remember_descriptor(char *name,struct sqlda *descriptor)
{
   struct named_storage *ns = allocate_storage(name);
   ns->storage.descriptor = descriptor;
   ns->allocated = 0;
}

static struct named_storage *find_storage(char *name)
{
   struct named_storage *ns = named_stores;
   while (ns != NULL) {
      if (strcmp(ns->name,name) == 0) return(ns);
      ns = ns->next;
   }
   return(NULL);
}

static void remember_buf(char *name,struct anon_storage *buf)
{
   struct named_storage *ns = find_storage(name);
   buf->next = ns->bufs;
   ns->bufs = buf;
}

static void delete_buf(char *name,void *data)
{
   struct named_storage *ns = find_storage(name);
   struct anon_storage **buf,*tmp;
   if (!ns) return;
   buf = &ns->bufs;
   while (*buf && ((*buf)->d.data != data))
      buf = &((*buf)->next);

   if (*buf) {
      tmp = *buf;
      *buf = (*buf)->next;
      free(tmp);
   }
}

static _SQCURSOR *find_cursor(char *name)
{
   struct named_storage *ns = find_storage(name);
   if (ns) return(ns->storage.cursor);
   return(NULL);
}

struct sqlda *find_descriptor(char *name)
{
   struct named_storage *ns = find_storage(name);
   if (ns) return(ns->storage.descriptor);
   return(NULL);
}

static void delete_storage(char *name)
{
   struct named_storage *ns = find_storage(name);
   if (!ns) return;

   if (named_stores == ns)
       named_stores = ns->next;

   if (ns->next)
       ns->next->prev = ns->prev;

   if (ns->prev)
       ns->prev->next = ns->next;

   if (ns->allocated) free (ns->storage.cursor);
   free (ns->name);

   while (ns->bufs != NULL) {
      struct anon_storage *an = ns->bufs->next;
      free(ns->bufs);
      ns->bufs = an;
   }
   free (ns);
}

int byleng(char *p, int len)
{
    char *q = p + len;
    while (q > p && q[-1] == ' ') q--;
    return(q - p);
}

/* ================================================================= */
/* ==================== Driver Level Operations ==================== */
/* ================================================================= */

/* Official name for DBD::Sqlflex module */
const char *dbd_ix_module(void)
{
	return(DBD_IX_MODULE);
}

/* Print message with string argument if debug level set high enough */
void
dbd_ix_debug(int n, char *fmt, const char *arg)
{
	fflush(stdout);
	if (DBIS->debug >= n)
		warn(fmt, arg);
}

/* Print message with long argument if debug level set high enough */
void
dbd_ix_debug_l(int n, char *fmt, long arg)
{
	fflush(stdout);
	if (DBIS->debug >= n)
		warn(fmt, arg);
}

#ifdef DBD_IX_DEBUG_ENVIRONMENT
static void dbd_ix_printenv(const char *s1, const char *s2)
{
	extern char **environ;
	char **envp = environ;
	char *env;

	fprintf(stderr, "ENV: %s %s - environ = 0x%08X\n", s1, s2, environ);
	while ((env = *envp++) != 0)
		fprintf(stderr, "0x%08X: %s\n", env, env);
}
#endif /* DBD_IX_DEBUG_ENVIRONMENT */

/* Print message on entry to function */
static void
dbd_ix_enter(const char *function)
{
	dbd_ix_debug(1, "Enter %s()\n", function);
}

/* Print message on exit from function */
static void
dbd_ix_exit(const char *function)
{
	dbd_ix_debug(1, "Exit %s()\n", function);
}

/* Do some semi-standard initialization */
void
dbd_ix_dr_init(dbistate)
dbistate_t     *dbistate;
{
	DBIS = dbistate;
	ix_errnum = GvSV(gv_fetchpv("DBD::Sqlflex::err", 1, SVt_IV));
	ix_errstr = GvSV(gv_fetchpv("DBD::Sqlflex::errstr", 1, SVt_PV));
	ix_state  = GvSV(gv_fetchpv("DBD::Sqlflex::state", 1, SVt_PV));
}

/* Formally initialize the DBD::Sqlflex driver structure */
int
dbd_ix_dr_driver(SV *drh)
{
	D_imp_drh(drh);

	imp_drh->n_connections = 0;			/* No active connections */
	imp_drh->current_connection = 0;	/* No name */
	imp_drh->multipleconnections = 0;		/* Multiple connections forbidden */
	new_headlink(&imp_drh->head);		/* Linked list of connections */

	return 1;
}

/* Relay function for use by destroy_chain() */
/* Destroys a statement when a database connection is destroyed */
static void dbd_st_destroyer(void *data)
{
	static const char function[] = DBD_IX_MODULE "::dbd_st_destroyer";
	dbd_ix_enter(function);
	del_statement((imp_sth_t *)data);
	dbd_ix_exit(function);
}

/* Delete all the statements (and other data) associated with a connection */
static void del_connection(imp_dbh_t *imp_dbh)
{
	static const char function[] = DBD_IX_MODULE "::dbd_st_destroyer";
	dbd_ix_enter(function);
	destroy_chain(&imp_dbh->head, dbd_st_destroyer);
	dbd_ix_exit(function);
}

/* Relay (interface) function for use by destroy_chain() */
/* Destroys a database connection when a driver is destroyed */
static void dbd_db_destroyer(void *data)
{
	static const char function[] = DBD_IX_MODULE "::dbd_db_destroyer";
	dbd_ix_enter(function);
	del_connection((imp_dbh_t *)data);
	dbd_ix_exit(function);
}

/* Disconnect all connections (cleanly) */
int dbd_ix_dr_discon_all(SV *drh, imp_drh_t *imp_drh)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_dr_discon_all";
	dbd_ix_enter(function);
	destroy_chain(&imp_drh->head, dbd_db_destroyer);
	dbd_ix_exit(function);
	return(1);
}

/* Format a Sqlflex error message (both SQL and ISAM parts) */
void            dbd_ix_seterror(ErrNum rc)
{
	char            errbuf[256];
	char            fmtbuf[256];
	char            sql_buf[256];
	char            isambuf[256];
	char            msgbuf[sizeof(sql_buf)+sizeof(isambuf)];

	if (rc < 0)
	{
		/* Format SQL (primary) error */
		sprintf(sql_buf, "SQL: %ld: %s", rc, sqlca.sqlerrm);

		/* Format ISAM (secondary) error */
		if (sqlca.sqlerrd[1] != 0)
		{
                        if ((sqlca.sqlerrd[1] >=100) && (sqlca.sqlerrd[1] <= 134))
			   sprintf(isambuf, " - ISAM: %s", my_errlist[sqlca.sqlerrd[1] - 100]);
                        else
			   sprintf(isambuf, " - ISAM: <no message available>");
		}
		else
			isambuf[0] = '\0';

		/* Concatenate SQL and ISAM messages */
		/* Note that the messages have trailing newlines */
		strcpy(msgbuf, sql_buf);
		strcat(msgbuf, isambuf);

		/* Record error number, error message, and error state */
		sv_setiv(ix_errnum, (IV)rc);
		sv_setpv(ix_errstr, msgbuf);
		sv_setpv(ix_state, SQLSTATE);
	}
}

/* Save the current sqlca record */
static void dbd_ix_savesqlca(imp_dbh_t *imp_dbh)
{
	imp_dbh->ix_sqlca = sqlca;
}

/* Record (and report) and SQL error, saving SQLCA information */
static void dbd_ix_sqlcode(imp_dbh_t *imp_dbh)
{
	/* If there is an error, record it */
	if (sqlca.sqlcode < 0)
	{
		dbd_ix_savesqlca(imp_dbh);
		dbd_ix_seterror(sqlca.sqlcode);
	}
}

/* ================================================================= */
/* =================== Database Level Operations =================== */
/* ================================================================= */

/* Initialize a connection structure, allocating names */
static void     new_connection(imp_dbh_t *imp_dbh)
{
	static long     connection_num = 0;
	sprintf(imp_dbh->nm_connection, "x_%09ld", connection_num);
	imp_dbh->is_onlinedb  = False;
	imp_dbh->is_loggeddb  = False;
	imp_dbh->is_modeansi  = False;
	imp_dbh->is_txactive  = False;
	imp_dbh->is_connected = False;
	connection_num++;
}

int
dbd_ix_db_login(SV *dbh, imp_dbh_t *imp_dbh, char *name, char *user, char *pass)
{
	D_imp_drh_from_dbh;
	Boolean conn_ok;
	static const char function[] = DBD_IX_MODULE "::dbd_ix_db_login";

	dbd_ix_enter(function);
	new_connection(imp_dbh);
	if (name != 0 && *name == '\0')
		name = 0;
	if (name != 0 && strcmp(name, DEFAULT_DATABASE) == 0)
		name = 0;

	/*dbd_ix_printenv("pre-connect", function);*/

	/* Connect not supported, use DATABASE statement */
	conn_ok = dbd_ix_opendatabase(name);

	/*dbd_ix_printenv("post-connect", function);*/

	if (sqlca.sqlcode < 0)
	{
		/* Failure of some sort */
		dbd_ix_seterror(sqlca.sqlcode);
		dbd_ix_debug(1, "Exit %s (**ERROR-1**)\n", function);
		return 0;
	}

	/* Examine sqlca to see what sort of database we are hooked up to */
	dbd_ix_savesqlca(imp_dbh);
	imp_dbh->database = name;
	imp_dbh->is_onlinedb = (sqlca.sqlwarn.sqlwarn3 == 'W');
	imp_dbh->is_modeansi = (sqlca.sqlwarn.sqlwarn2 == 'W');
	imp_dbh->is_loggeddb = (sqlca.sqlwarn.sqlwarn1 == 'W');
	imp_dbh->is_connected = conn_ok;

	/* Record extra active connection and name of current connection */
	imp_drh->n_connections++;
	imp_drh->current_connection = imp_dbh->nm_connection;

	add_link(&imp_drh->head, &imp_dbh->chain);
	imp_dbh->chain.data = (void *)imp_dbh;
	new_headlink(&imp_dbh->head);

	/**
	** Unlogged databases are in AutoCommit mode at all times and cannot be
	** switched out of AutoCommit mode.  Ideally, an attempt to connect to
	** one with AutoCommit Off would cause a failure with error -256
	** 'Transaction not available'.  However, since the default attribute
	** is only set after the connection itself is complete, it is not
	** possible.  You can only give the warning.  To comply with the DBI
	** 0.85 standard, all databases, including MODE ANSI databases, run
	** with AutoCommit On by default.  However, this can be overridden by
	** the user as required.
	*/
	if (imp_dbh->is_loggeddb == False && DBI_AutoCommit(imp_dbh) == False)
	{
		/* Simulate connection failure */
		dbd_ix_db_disconnect(dbh, imp_dbh);
		sqlca.sqlcode = -256;
		dbd_ix_seterror(sqlca.sqlcode);
		dbd_ix_debug(1, "Exit %s (**ERROR-2**)\n", function);
		return 0;
	}

	DBIc_IMPSET_on(imp_dbh);	/* imp_dbh set up now                   */
	DBIc_ACTIVE_on(imp_dbh);	/* call disconnect before freeing       */

	/* Start a transaction if the database is Logged */
	/* but not MODE ANSI and if AutoCommit is Off */
	if (imp_dbh->is_loggeddb == True && imp_dbh->is_modeansi == False)
	{
		if (DBI_AutoCommit(imp_dbh) == False)
		{
			if (dbd_ix_begin(imp_dbh) == 0)
			{
				dbd_ix_db_disconnect(dbh, imp_dbh);
				dbd_ix_debug(1, "Exit %s (**ERROR-3**)\n", function);
				return 0;
			}
		}
	}

	dbd_ix_exit(function);
	return 1;
}

/* Ensure that the correct connection is current */
static int dbd_db_setconnection(imp_dbh_t *imp_dbh)
{
	int rc = 1;
	D_imp_drh_from_dbh;

	/* If this connection isn't connected, return with failure */
	/* Primarily a concern when destroying connections */
	if (imp_dbh->is_connected == False)
		return(0);

	if (imp_drh->current_connection != imp_dbh->nm_connection)
	{
		dbd_ix_setconnection(imp_dbh->nm_connection);
		imp_drh->current_connection = imp_dbh->nm_connection;
		if (sqlca.sqlcode < 0)
			rc = 0;
	}
	return(rc);
}

/* Internal implementation of BEGIN WORK */
/* Assumes correct connection is already set */
static int      dbd_ix_begin(imp_dbh_t *dbh)
{
	int rc = 1;

/*
	EXEC SQL "BEGIN WORK";
	dbd_ix_sqlcode(dbh);
	if (sqlca.sqlcode < 0)
		rc = 0;
	else
	{
		dbd_ix_debug(3, "%s: BEGIN WORK\n", dbd_ix_module());
		dbh->is_txactive = True;
	}
*/
	return rc;
}

/* Internal implementation of COMMIT WORK */
/* Assumes correct connection is already set */
static int      dbd_ix_commit(imp_dbh_t *dbh)
{
	int rc = 1;

        /*
         * EXEC SQL COMMIT WORK;
         */
         {
         _iqcommit();
         }

	dbd_ix_sqlcode(dbh);
	if (sqlca.sqlcode < 0)
		rc = 0;
	else
	{
		dbd_ix_debug(3, "%s: COMMIT WORK\n", dbd_ix_module());
		dbh->is_txactive = False;
	}
	return rc;
}

/* Internal implementation of ROLLBACK WORK */
/* Assumes correct connection is already set */
static int      dbd_ix_rollback(imp_dbh_t *dbh)
{
	int rc = 1;

        /*
         * EXEC SQL ROLLBACK WORK;
         */
         {
         _iqrollback();
         }

	dbd_ix_sqlcode(dbh);
	if (sqlca.sqlcode < 0)
		rc = 0;
	else
	{
		dbd_ix_debug(3, "%s: ROLLBACK WORK\n", dbd_ix_module());
		dbh->is_txactive = False;
	}
	return rc;
}

/* External interface for BEGIN WORK */
int
dbd_ix_db_begin(imp_dbh_t *imp_dbh)
{
	int             rc = 1;

	if (imp_dbh->is_loggeddb != 0)
	{
		if (dbd_db_setconnection(imp_dbh) == 0)
		{
			dbd_ix_savesqlca(imp_dbh);
			return(0);
		}
		rc = dbd_ix_begin(imp_dbh);
	}
	return rc;
}

/* External interface for COMMIT WORK */
int
dbd_ix_db_commit(SV *dbh, imp_dbh_t *imp_dbh)
{
	int             rc = 1;

	if (imp_dbh->is_loggeddb != 0)
	{
		if (dbd_db_setconnection(imp_dbh) == 0)
		{
			dbd_ix_savesqlca(imp_dbh);
			return(0);
		}
		if ((rc = dbd_ix_commit(imp_dbh)) != 0)
		{
			if (imp_dbh->is_modeansi == False &&
				DBI_AutoCommit(imp_dbh) == False)
				rc = dbd_ix_begin(imp_dbh);
		}
	}
	return rc;
}

/* External interface for ROLLBACK WORK */
int
dbd_ix_db_rollback(SV *dbh, imp_dbh_t *imp_dbh)
{
	int             rc = 1;

	if (imp_dbh->is_loggeddb != 0)
	{
		if (dbd_db_setconnection(imp_dbh) == 0)
		{
			dbd_ix_savesqlca(imp_dbh);
			return(0);
		}
		if ((rc = dbd_ix_rollback(imp_dbh)) != 0)
		{
			if (imp_dbh->is_modeansi == False &&
				DBI_AutoCommit(imp_dbh) == False)
				rc = dbd_ix_begin(imp_dbh);
		}
	}
	return rc;
}

/* Do nothing -- for use by cleanup code */
static void noop(void *data)
{
}

/* Preset AutoCommit value */
int
dbd_ix_db_preset(imp_dbh_t *imp_dbh, SV *dbattr)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_db_preset";
	static const char ac[] = "AutoCommit";
	U32 ac_len = sizeof(ac) - 1;
	I32 is_store = 0;

	dbd_ix_enter(function);
	if (SvROK(dbattr) && SvTYPE(SvRV(dbattr)) == SVt_PVHV)
	{
		/* const_cast<char *>(ac) */
		SV **svpp;
		svpp = hv_fetch((HV *)SvRV(dbattr), (char *)ac, ac_len, is_store);
		if (svpp != NULL)
		{
			dbd_ix_debug_l(1, "AutoCommit set to %ld\n", SvTRUE(*svpp));
			DBIc_set(imp_dbh, DBIcf_AutoCommit, SvTRUE(*svpp));
		}
	}
	else
	{
		printf("SvROK = %d, SvTYPE = %d\n", SvROK(dbattr),
			SvTYPE(SvRV(dbattr)));
	}
	dbd_ix_exit(function);
	return 1;
}

/* Close a connection, destroying any dependent statements */
int
dbd_ix_db_disconnect(SV *dbh, imp_dbh_t *imp_dbh)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_db_disconnect";
	D_imp_drh_from_dbh;
	int junk;

	dbd_ix_enter(function);

	if (dbd_db_setconnection(imp_dbh) == 0)
	{
		dbd_ix_savesqlca(imp_dbh);
		dbd_ix_debug(1, "%s -- set connection failed", function);
		return(0);
	}

	dbd_ix_debug(1, "%s -- delete statements\n", function);
	destroy_chain(&imp_dbh->head, dbd_st_destroyer);
	dbd_ix_debug(1, "%s -- statements deleted\n", function);

	/* Rollback transaction before disconnecting */
	if (imp_dbh->is_loggeddb == True && imp_dbh->is_txactive == True)
		junk = dbd_ix_rollback(imp_dbh);

	if (imp_dbh->is_connected == True)
		dbd_ix_closedatabase(imp_dbh->database);

	dbd_ix_sqlcode(imp_dbh);
	imp_dbh->is_connected = False;

	/* We assume that disconnect will always work       */
	/* since most errors imply already disconnected.    */
	DBIc_ACTIVE_off(imp_dbh);

	/* Record loss of connection in driver block */
	imp_drh->n_connections--;
	imp_drh->current_connection = 0;
	assert(imp_drh->n_connections >= 0);
	delete_link(&imp_dbh->chain, noop);


/* KBC: workaround for sqlflex bug... let's you change between local and remote database
        w/ disconnect and connect */

        pcGSQLFlexSvc = NULL;

	/* We don't free imp_dbh since a reference still exists	 */
	/* The DESTROY method is the only one to 'free' memory.	 */
	dbd_ix_exit(function);
	return 1;
}

void dbd_ix_db_destroy(SV *dbh, imp_dbh_t *imp_dbh)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_db_destroy";
	dbd_ix_enter(function);
	if (DBIc_is(imp_dbh, DBIcf_ACTIVE))
		dbd_ix_db_disconnect(dbh, imp_dbh);
	DBIc_off(imp_dbh, DBIcf_IMPSET);
	dbd_ix_exit(function);
}

/* ================================================================== */
/* =================== Statement Level Operations =================== */
/* ================================================================== */

/* Initialize a statement structure, allocating names */
static void     new_statement(imp_dbh_t *imp_dbh, imp_sth_t *imp_sth)
{
	static long     cursor_num = 0;

	sprintf(imp_sth->nm_stmnt, "p_%09ld", cursor_num);
	sprintf(imp_sth->nm_cursor, "c_%09ld", cursor_num);
	sprintf(imp_sth->nm_obind, "d_%09ld", cursor_num);
	sprintf(imp_sth->nm_ibind, "b_%09ld", cursor_num);

        allocate_cursor(imp_sth->nm_cursor);

	imp_sth->dbh = imp_dbh;
	imp_sth->st_state = Unused;
	imp_sth->st_type = 0;
	imp_sth->n_blobs = 0;
	imp_sth->n_bound = 0;
	imp_sth->n_rows = 0;
	imp_sth->n_columns = 0;
	add_link(&imp_dbh->head, &imp_sth->chain);
	imp_sth->chain.data = (void *)imp_sth;
	cursor_num++;
	/* Cleanup required for statement chain in imp_dbh */
	DBIc_on(imp_sth, DBIcf_IMPSET);
}

int
dbd_ix_st_prepare(SV *sth, imp_sth_t *imp_sth, char *stmt, SV *attribs)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_st_prepare";
	D_imp_dbh_from_sth;
	int  rc = 1;
        /*
         * SQL BEGIN DECLARE SECTION
         */
         char           *statement = stmt;
         int             desc_count;
         char           *nm_stmnt;
         char           *nm_obind;
         char           *nm_cursor;
        /*
         * SQL END DECLARE SECTION
         */
        struct sqlda *descript;

	dbd_ix_enter(function);

	if ((rc = dbd_db_setconnection(imp_dbh)) == 0)
	{
		dbd_ix_savesqlca(imp_dbh);
		dbd_ix_exit(function);
		return(rc);
	}

	new_statement(imp_dbh, imp_sth);
	nm_stmnt = imp_sth->nm_stmnt;
	nm_obind = imp_sth->nm_obind;
	nm_cursor = imp_sth->nm_cursor;

	/* Record the number of input parameters in the statement */
	DBIc_NUM_PARAMS(imp_sth) = dbd_ix_preparse(statement);

	/* Allocate space for that many parameters */
	if (dbd_ix_setbindnum(imp_sth, DBIc_NUM_PARAMS(imp_sth)) == 0)
	{
		dbd_ix_exit(function);
		return 0;
	}

        /*
         * EXEC SQL PREPARE nm_stmnt FROM :statement;
         */
         {
         _iqprepare(find_cursor(nm_cursor), statement);
         }

	dbd_ix_savesqlca(imp_dbh);
	dbd_ix_sqlcode(imp_dbh);
	if (sqlca.sqlcode < 0)
	{
		dbd_ix_exit(function);
		return 0;
	}
	imp_sth->st_state = Prepared;

/*
	EXEC SQL ALLOCATE DESCRIPTOR :nm_obind WITH MAX 128;
	dbd_ix_sqlcode(imp_dbh);
	if (sqlca.sqlcode < 0)
	{
		del_statement(imp_sth);
		dbd_ix_exit(function);
		return 0;
	}
*/

        /* this comes automatically, using the describe */
	imp_sth->st_state = Allocated;


        /*
         * EXEC SQL DESCRIBE nm_stmnt USING DESCRIPTOR :nm_obind;
	   dbd_ix_sqlcode(imp_dbh);
	   if (sqlca.sqlcode < 0)
	   {
		   del_statement(imp_sth);
		   dbd_ix_exit(function);
		   return 0;
	   }
         */

         {
         _iqdscribe(find_cursor(nm_cursor), &descript);
         }
        
        remember_descriptor(nm_obind,descript);    /* this replaces allocate descriptor, above */

	imp_sth->st_state = Described;
	imp_sth->st_type = sqlca.sqlcode;
	if (imp_sth->st_type == 0)
		imp_sth->st_type = SQ_SELECT;

/*
	EXEC SQL GET DESCRIPTOR :nm_obind :desc_count = COUNT;
	dbd_ix_sqlcode(imp_dbh);
	if (sqlca.sqlcode < 0)
	{
		del_statement(imp_sth);
		dbd_ix_exit(function);
		return 0;
	}
*/

        desc_count = descript->sqld;  /* instead of get descriptor, above */

	/* Record the number of fields in the cursor for DBI and DBD::Sqlflex  */
	DBIc_NUM_FIELDS(imp_sth) = imp_sth->n_columns = desc_count;

	/**
	** Only non-cursory statements need an output descriptor.
	** Only cursory statements need a cursor declared for them.
	** INSERT may need an input descriptor (which will appear to be the
	** output descriptor, such being the wonders of Informix).
	*/
	if (imp_sth->st_type == SQ_SELECT)
		rc = dbd_ix_declare(imp_sth);
#ifdef SQ_EXECPROC
	else if (imp_sth->st_type == SQ_EXECPROC && desc_count > 0)
		rc = dbd_ix_declare(imp_sth);
#endif	/* SQ_EXECPROC */
	else if (imp_sth->st_type == SQ_INSERT && desc_count > 0)
	{
/* KBC -- declare those inserts with binds, too. */
		rc = dbd_ix_declare(imp_sth);

		dbd_ix_blobs(imp_sth);
		if (imp_sth->n_blobs > 0)
		{
			/*
			** Switch the nm_obind and nm_ibind names so that when
			** dbd_ix_bindsv() is at work, it has an already populated
			** SQL descriptor to work with, that already has the blobs
			** set up correctly.
			*/
			Name tmpname;
			strcpy(tmpname, imp_sth->nm_ibind);
			strcpy(imp_sth->nm_ibind, imp_sth->nm_obind);
			strcpy(imp_sth->nm_obind, tmpname);
			imp_sth->n_bound = desc_count;
		}
	}
	else
	{
/*
		EXEC SQL DEALLOCATE DESCRIPTOR :nm_obind;
*/
                delete_storage(nm_obind);     /* replaces deallocate descriptor above */

		imp_sth->st_state = Prepared;
		rc = 1;
	}

	/* Get number of fields and space needed for field names      */
	if (DBIS->debug >= 2)
		printf("%s'imp_sth->n_columns: %d\n", function, imp_sth->n_columns);

	dbd_ix_exit(function);
	return rc;
}

/* Declare cursor for SELECT or EXECUTE PROCEDURE */
static int dbd_ix_declare(imp_sth_t *imp_sth)
{
      /*
       * SQL BEGIN DECLARE SECTION
       */
       char           *nm_stmnt = imp_sth->nm_stmnt;
       char           *nm_cursor = imp_sth->nm_cursor;
      /*
       * SQL END DECLARE SECTION
       */
      char           *nm_obind = imp_sth->nm_obind;
      struct sqlda *sqlda;
      int i;
      struct anon_storage *indstorage, *datastorage;
      struct ind *indbuf;
      int *databuf;
      int datasize = 0; /* in 4-byte words */

      sqlda = find_descriptor(nm_obind);
      indstorage = malloc(sizeof (struct anon_storage *) + sqlda->sqld * sizeof (struct ind) );
      remember_buf(nm_obind,indstorage);
      indbuf = indstorage->d.indbuf;

      for (i = 0; i < sqlda->sqld; i++) {
         sqlda->sqlvar[i].sqlind =  &indbuf->indicator;
         sqlda->sqlvar[i].sqlitype = CSHORTTYPE;
         sqlda->sqlvar[i].sqlilen = 2;
         sqlda->sqlvar[i].sqlidata = (char *) &indbuf->indicator;
         indbuf->indicator = 0;
         indbuf->origType = sqlda->sqlvar[i].sqltype;
         indbuf++;

         switch (sqlda->sqlvar[i].sqltype) {
	        case SQLINT:         /* KBC - do it with an integer too */
	        case SQLSMINT:       /* and shorts, for that matter */
	     	case SQLFLOAT:
	     	case SQLSMFLOAT:
	     	case SQLDECIMAL:
	     	case SQLMONEY:
	     	case SQLCHAR:
#ifdef SQLVCHAR
	     	case SQLVCHAR:
#endif
#ifdef SQLNVCHAR
		case SQLNVCHAR:
#endif
#ifdef SQLNCHAR
	     	case SQLNCHAR:
#endif
                    break;

	        case SQLSERIAL:  
                   sqlda->sqlvar[i].sqltype = CLONGTYPE;
                   sqlda->sqlvar[i].sqllen = 4;
                   break;

                case SQLDATE:
                case SQLDTIME:
                       sqlda->sqlvar[i].sqllen = 30;
                       /* FALL THROUGH */

                default: /* for dates, etc. */
                   if (sqlda->sqlvar[i].sqllen < 30) 
                       sqlda->sqlvar[i].sqllen = 30;
                   sqlda->sqlvar[i].sqltype = CCHARTYPE;
                   break;
         }
         datasize += (sqlda->sqlvar[i].sqllen + 4) / 4; /* leaves room for null and rolls to next word */
      }

      datastorage = malloc(sizeof (struct anon_storage *) + datasize * 4 );
      remember_buf(nm_obind,datastorage);
      databuf = (int *) datastorage->d.data;

      for (i = 0; i < sqlda->sqld; i++) {
         sqlda->sqlvar[i].sqldata = (char *) databuf;
         databuf += (sqlda->sqlvar[i].sqllen + 3) / 4;
      }

/* sqlflex allows INSERTS that are prepared, too */

#ifdef SQ_EXECPROC
	assert(imp_sth->st_type == SQ_SELECT || imp_sth->st_type == SQ_EXECPROC) || imp_sth->st_type == SQ_INSERT;
#else
	assert(imp_sth->st_type == SQ_SELECT || imp_sth->st_type == SQ_INSERT);
#endif /* SQ_EXECPROC */
	assert(imp_sth->st_state == Described);
	dbd_ix_blobs(imp_sth);

	if (imp_sth->dbh->is_modeansi == True &&
				DBI_AutoCommit(imp_sth->dbh) == True)
	{

        /*
         * EXEC SQL DECLARE :nm_cursor CURSOR WITH HOLD FOR :nm_stmnt;
         */
         {
         _iqddclcur(find_cursor(nm_cursor), nm_cursor, 4096);
         }
	}
	else
	{

        /*
         * EXEC SQL DECLARE :nm_cursor CURSOR FOR :nm_stmnt;
	   dbd_ix_sqlcode(imp_sth->dbh);
	   if (sqlca.sqlcode < 0)
	   {
		   return 0;
	   }
         */
         {
         _iqddclcur(find_cursor(nm_cursor), nm_cursor, 0);
         }
	}
	imp_sth->st_state = Declared;
	return 1;
}

/* Close cursor */
static int
dbd_ix_close(imp_sth_t *imp_sth)
{
      /*
       * SQL BEGIN DECLARE SECTION
       */
       char           *nm_cursor = imp_sth->nm_cursor;
      /*
       * SQL END DECLARE SECTION
       */

	if (imp_sth->st_state == Opened || imp_sth->st_state == Finished)
	{

         /*
          * EXEC SQL CLOSE nm_cursor;
          */
          {
          _iqclose(find_cursor(nm_cursor));
          }
		dbd_ix_sqlcode(imp_sth->dbh);
		if (sqlca.sqlcode < 0)
		{
			return 0;
		}
		imp_sth->st_state = Declared;
	}
	else
		warn("%s:st::dbd_ix_close: CLOSE called in wrong state\n", dbd_ix_module());
	return 1;
}

/* Release all database and allocated resources for statement */
static void del_statement(imp_sth_t *imp_sth)
{
      /*
       * SQL BEGIN DECLARE SECTION
       */
       char           *name;
       int colno;
       int coltype;
      /*
       * SQL END DECLARE SECTION
       */
        _SQCURSOR *cursor;
        
	dbd_ix_debug_l(3, "Enter del_statement() 0x%08X\n", (long)imp_sth);

	if (dbd_db_setconnection(imp_sth->dbh) == 0)
	{
		dbd_ix_savesqlca(imp_sth->dbh);
		return;
	}

	switch (imp_sth->st_state)
	{
	case Finished:
		/*FALLTHROUGH*/

	case Opened:
		dbd_ix_debug(3, "del_statement() %s\n", "CLOSE cursor");
                if (imp_sth->nm_cursor) {
                   cursor = find_cursor(imp_sth->nm_cursor);
                   /*
                    * EXEC SQL CLOSE name;
                    */
                    if (cursor) _iqclose(cursor);
                }
		/*FALLTHROUGH*/

	case Declared:
		dbd_ix_debug(3, "del_statement() %s\n", "FREE cursor");

#if 0
/* KBC - 5/24/99 - iqfree happening twice.  Showed up in use of client/server
                   version, but probably is a problem in any case...
*/
                if (imp_sth->nm_cursor) {
                   cursor = find_cursor(imp_sth->nm_cursor);
                   /*
                    * EXEC SQL FREE name;
                    */
                    if (cursor) _iqfree(cursor);
		   /*FALLTHROUGH*/
                }
#endif


	case Described:
	case Allocated:
		name = imp_sth->nm_obind;

#ifdef WIN32
#undef DBD_IX_RELEASE_BLOBS
#endif /* WIN32 */

#ifdef DBD_IX_RELEASE_BLOBS
		if (imp_sth->n_blobs > 0)
		{
			for (colno = 1; colno <= imp_sth->n_columns; colno++)
			{
				/* EXEC SQL GET DESCRIPTOR :name VALUE :colno :coltype = TYPE; */
				/* dbd_ix_sqlcode(imp_sth->dbh); */
				if (coltype == SQLBYTES || coltype == SQLTEXT)
				{
					/* EXEC SQL GET DESCRIPTOR :name VALUE :colno :blob = DATA; */
					/* dbd_ix_sqlcode(imp_sth->dbh); */
					if (blob.loc_loctype == LOCMEMORY && blob.loc_buffer != 0)
						free(blob.loc_buffer);
				}
			}
		}
#endif /* DBD_IX_RELEASE_BLOBS */

		dbd_ix_debug(3, "del_statement() %s\n", "DEALLOCATE descriptor");
/*
		EXEC SQL DEALLOCATE DESCRIPTOR :name;
*/

                delete_storage(name);     /* replaces deallocate descriptor above */
		/*FALLTHROUGH*/

	case Prepared:
		dbd_ix_debug(3, "del_statement() %s\n", "FREE statement");
                /*
                 * EXEC SQL FREE nm_stmnt;
                 */
                cursor = find_cursor(imp_sth->nm_cursor);
                /*
                 * EXEC SQL FREE name;
                 */
                if (cursor) _iqfree(cursor);
		/*FALLTHROUGH*/

	case Unused:
		break;
	}
	imp_sth->st_state = Unused;
	delete_link(&imp_sth->chain, noop);
	DBIc_off(imp_sth, DBIcf_IMPSET);
	dbd_ix_debug_l(3, "Exit del_statement() 0x%08X\n", (long)imp_sth);
}

/* Create the input descriptor for the specified number of items */
static int dbd_ix_setbindnum(imp_sth_t *imp_sth, int items)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_setbindnum";
      /*
       * SQL BEGIN DECLARE SECTION
       */
       int  bind_size = items;
       char           *nm_ibind = imp_sth->nm_ibind;
      /*
       * SQL END DECLARE SECTION
       */
        struct sqlda *descript;
        struct anon_storage *varstorage;
        int i;

	dbd_ix_enter(function);

	if (dbd_db_setconnection(imp_sth->dbh) == 0)
	{
		dbd_ix_exit(function);
		return 0;
	}

	if (items > imp_sth->n_bound)
	{
		if (imp_sth->n_bound > 0)
		{
/*
			EXEC SQL DEALLOCATE DESCRIPTOR :nm_ibind;
			dbd_ix_sqlcode(imp_sth->dbh);
			imp_sth->n_bound = 0;
			if (sqlca.sqlcode < 0)
			{
				dbd_ix_exit(function);
				return 0;
			}
*/
                delete_storage(nm_ibind);     /* replaces deallocate descriptor above */
		}
/*
		EXEC SQL ALLOCATE DESCRIPTOR :nm_ibind WITH MAX :bind_size;
		dbd_ix_sqlcode(imp_sth->dbh);
		if (sqlca.sqlcode < 0)
		{
			dbd_ix_exit(function);
			return 0;
		}
*/
                descript = allocate_descriptor(nm_ibind);     /* replaces allocate descriptor above */
                varstorage = malloc(sizeof (struct anon_storage *) + bind_size * sizeof(struct sqlvar_struct));
                remember_buf(nm_ibind,varstorage);

                descript->sqlvar = varstorage->d.vars;
                descript->sqld = bind_size;

                for (i = 0; i < bind_size; i++) {
                    descript->sqlvar[i].sqlitype = CSHORTTYPE;
                    descript->sqlvar[i].sqlilen = 0;
                    descript->sqlvar[i].sqlidata = NULL;
                    descript->sqlvar[i].sqlind = NULL;
                  
                    descript->sqlvar[i].sqltype = CCHARTYPE;
                    descript->sqlvar[i].sqllen = 0;
                    descript->sqlvar[i].sqldata = NULL;
                }

		imp_sth->n_bound = items;
	}
	dbd_ix_exit(function);
	return 1;
}

/* Bind the value to input descriptor entry */
static int dbd_ix_bindsv(imp_sth_t *imp_sth, int idx, SV *val)
{
	int rc = 1;
	static const char function[] = DBD_IX_MODULE "::dbd_ix_bindsv";
	STRLEN len;
      /*
       * SQL BEGIN DECLARE SECTION
       */
       char           *nm_ibind = imp_sth->nm_ibind;
       char *string;
       long  intvar;
       int   type;
       int index = idx;
      /*
       * SQL END DECLARE SECTION
       */

        struct sqlda *descript;
        struct anon_storage *bindstorage;

        descript = find_descriptor(nm_ibind);

	dbd_ix_enter(function);

	if ((rc = dbd_db_setconnection(imp_sth->dbh)) == 0)
	{
		dbd_ix_savesqlca(imp_sth->dbh);
		return(rc);
	}

/*
	EXEC SQL GET DESCRIPTOR :nm_ibind VALUE :index :type = TYPE;

        type?  how would we know a type yet?
*/
        type = SQLCHAR;

	if (!SvOK(val))
	{
                static short ival = -32768;    /* Internal representation of SMALLINT N */

		/* It's a null! */
		dbd_ix_debug(2, "%s -- null\n", function);
                type = SQLSMINT;

/*
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, DATA = :ival;
*/
                descript->sqlvar[index-1].sqltype = type;
                descript->sqlvar[index-1].sqldata = (char *) &ival;
                descript->sqlvar[index-1].sqllen = 2;
	}
	else if (type == SQLBYTES || type == SQLTEXT)
	{
		dbd_ix_debug(2, "%s -- blob\n", function);
		/* One day, this will accept SQ_UPDATE and SQ_UPDALL */
		/* There are no plans to support SQ_UPDCURR */
#ifdef BLOBS
		blob_locate(&blob, BLOB_IN_MEMORY);
		blob.loc_buffer = SvPV(val, len);
		blob.loc_bufsize = len + 1;
		blob.loc_size = len;
/*
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index DATA = :blob;
*/
                descript->sqlvar[index-1].sqldata = (void *) &blob;
#endif
	}
	else if (SvIOKp(val))
	{
		dbd_ix_debug(2, "%s -- integer\n", function);
		type = SQLINT;
		intvar = SvIV(val);
                if (descript->sqlvar[index-1].sqldata != NULL) { 
                   if (descript->sqlvar[index-1].sqltype != type) {
		       dbd_ix_debug(2, "%s -- needed free\n", function);
                       delete_buf(nm_ibind,descript->sqlvar[index-1].sqldata);
                       descript->sqlvar[index-1].sqldata = NULL;
                    }
                }

/*
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, DATA = :intvar;
*/
                descript->sqlvar[index-1].sqltype = type;
                descript->sqlvar[index-1].sqllen = sizeof(intvar);
	        if (descript->sqlvar[index-1].sqldata == NULL) {
		   dbd_ix_debug(2, "%s -- needed malloc\n", function);
                   bindstorage = malloc(sizeof (struct anon_storage *) + sizeof(intvar));
                   remember_buf(nm_ibind,bindstorage);
                   descript->sqlvar[index-1].sqldata = bindstorage->d.data;
                }
                memcpy(descript->sqlvar[index-1].sqldata,&intvar,sizeof(intvar));
	}
	else if (SvNOKp(val))
	{
                double numeric;     /* KBC 6/21/99 - changed to double from float */

		type = CDOUBLETYPE;
		numeric = SvNV(val);
		dbd_ix_debug(2, "%s -- numeric\n", function);
/*
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, DATA = :numeric;
*/
                if (descript->sqlvar[index-1].sqldata != NULL) { 
                   if (descript->sqlvar[index-1].sqltype != type) {
		       dbd_ix_debug(2, "%s -- needed free\n", function);
                       delete_buf(nm_ibind,descript->sqlvar[index-1].sqldata);
                       descript->sqlvar[index-1].sqldata = NULL;
                    }
                }

                descript->sqlvar[index-1].sqltype = type;
                descript->sqlvar[index-1].sqllen = sizeof(numeric);
                if (descript->sqlvar[index-1].sqldata == NULL) {
		   dbd_ix_debug(2, "%s -- needed malloc\n", function);
                   bindstorage = malloc(sizeof (struct anon_storage *) + sizeof(numeric));
                   remember_buf(nm_ibind,bindstorage);
                   descript->sqlvar[index-1].sqldata = bindstorage->d.data;
                }
                memcpy(descript->sqlvar[index-1].sqldata,&numeric,sizeof(numeric));
	}
	else
	{
		dbd_ix_debug(2, "%s -- string\n", function);
		type = SQLCHAR;
		string = SvPV(val, len);

                if (descript->sqlvar[index-1].sqldata != NULL) { 
                   if ((len > 100) || (descript->sqlvar[index-1].sqltype != type)) {
		       dbd_ix_debug(2, "%s -- needed free\n", function);
                       delete_buf(nm_ibind,descript->sqlvar[index-1].sqldata);
                       descript->sqlvar[index-1].sqldata = NULL;
                    }
                }
		if (len == 0)
		{
			/*
			** Even if you insert "" as a literal into a VARCHAR(), you get
			** a blank returned.  If you manage to insert a zero length
			** string via a variable into a VARCHAR, then you get a NULL
			** output string.  This is arguably a bug, but oh well.
			*/
			string = " ";
			len = 1;
		}
/*
			EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, LENGTH = :length, DATA = :longchar;
*/

                descript->sqlvar[index-1].sqltype = type;
                descript->sqlvar[index-1].sqllen = len;
                if (descript->sqlvar[index-1].sqldata == NULL) { 
		   dbd_ix_debug(2, "%s -- needed malloc\n", function);
                   bindstorage = malloc(sizeof (struct anon_storage *) + 
                            ((len < 101) ? 101 : (len+1)));
                   remember_buf(nm_ibind,bindstorage);
                   descript->sqlvar[index-1].sqldata = bindstorage->d.data;
                }
                memcpy(descript->sqlvar[index-1].sqldata,string,len+1);

	}
/*
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		rc = 0;
	}
*/
	dbd_ix_exit(function);
	return(rc);
}

static int count_blobs(char *descname, int ncols)
{
      /*
       * SQL BEGIN DECLARE SECTION
       */
       char           *nm_obind = descname;
       int	colno;
       int coltype;
      /*
       * SQL END DECLARE SECTION
       */
	int nblobs = 0;

	for (colno = 1; colno <= ncols; colno++)
	{
/*
		EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno :coltype = TYPE;
*/
                coltype = find_descriptor(nm_obind)->sqlvar[colno-1].sqltype;

		/* dbd_ix_sqlcode(imp_sth->dbh); */
		if (coltype == SQLBYTES || coltype == SQLTEXT)
		{
			nblobs++;
		}
	}
	return(nblobs);
}

/* Process blobs (if any) */
static void dbd_ix_blobs(imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_blobs";
      /*
       * SQL BEGIN DECLARE SECTION
       */
       char           *nm_obind = imp_sth->nm_obind;
       int 			colno;
       int coltype;
      /*
       * SQL END DECLARE SECTION
       */
	int             n_columns = imp_sth->n_columns;

	dbd_ix_enter(function);
	imp_sth->n_blobs = count_blobs(nm_obind, n_columns);
	if (imp_sth->n_blobs == 0)
	{
		dbd_ix_exit(function);
		return;
	}

	/*warn("dbd_ix_blobs: %d blobs\n", imp_sth->n_blobs);*/

	/* Set blob location */
#ifdef BLOB
	if (blob_locate(&blob, imp_sth->blob_bind) != 0)
	{
		croak("memory allocation error 3 in dbd_ix_blobs\n");
	}
#endif

	for (colno = 1; colno <= n_columns; colno++)
	{
/*
		EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno :coltype = TYPE;
		dbd_ix_sqlcode(imp_sth->dbh);
*/

                coltype = find_descriptor(nm_obind)->sqlvar[colno-1].sqltype;

		if (coltype == SQLBYTES || coltype == SQLTEXT)
		{
#ifdef BLOB
			/* Tell ESQL/C how to handle this blob */
/*
			EXEC SQL SET DESCRIPTOR :nm_obind VALUE :colno DATA = :blob;
			dbd_ix_sqlcode(imp_sth->dbh);
*/
                        find_descriptor(nm_obind)->sqlvar[colno-1].sqldata = (void *) &blob;
#endif
		}
	}
	dbd_ix_exit(function);
}

/*
** dbd_ix_preparse() -- based on dbd_preparse() in DBD::ODBC 0.15
**
** Edit string in situ (because the output will never be longer than the
** input) so that ? parameters are counted and :xx (x = digit) positional
** parameters are converted to ?.  Note that :abc notation is not
** converted; it causes problems with Informix's FROM dbase:table notation.
** The code handles single-quoted literals and double-quoted delimited
** identifiers and ANSI SQL "--.*\n" comments and Informix "{.*}" comments.
** Note that it does nothing with "#.*\n" Perl/Shell comments.  Also note
** that it does not handle ODBC-style extensions.  The shorthand notation
** for these is identical to an Informix {} comment; longhand notation
** looks like "--*(details*)--" without the quotes.  Returns the number of
** input parameters.
*/

static int dbd_ix_preparse(char *statement)
{
	char            end_quote = '\0';
	char           *src;
	char           *start;
	char           *dst;
	int             idx = 0;
	int             style = 0;
	int             laststyle = 0;
	int             param = 0;
	char            ch;

	src = statement;
	dst = statement;
	while ((ch = *src++) != '\0')
	{
		if (ch == end_quote)
			end_quote = '\0';
		else if (end_quote != '\0')
		{
			*dst++ = ch;
			continue;
		}
		else if (ch == '\'' || ch == '\"')
			end_quote = ch;
		else if (ch == L_CURLY)
			end_quote = R_CURLY;
		else if (ch == '-' && *src == '-')
		{
			end_quote = '\n';
		}
		if (ch != ':' && ch != '?')
		{
			*dst++ = ch;
			continue;
		}
		if (ch == '?')
		{
			/* X/Open standard	 */
			*dst++ = '?';
			idx++;
			style = 3;
		}
		else if (isDIGIT(*src))
		{
			/* ':1'		 */
			*dst++ = '?';
			while (isDIGIT(*src))
				src++;
			idx++;
			style = 1;
		}
		else
		{
			/* perhaps ':=' PL/SQL construct or dbase:table in Informix */
			*dst++ = ch;
			continue;
		}
		if (laststyle && style != laststyle)
			croak("Can't mix placeholder styles (%d/%d)", style, laststyle);
		laststyle = style;
	}
	if (end_quote != '\0')
	{
		switch (end_quote)
		{
		case '\'':
			warn("Incomplete single-quoted string\n");
			break;
		case '\"':
			warn("Incomplete double-quoted string (delimited identifier)\n");
			break;
		case R_CURLY:
			warn("Incomplete bracketed {...} comment\n");
			break;
		case '\n':
			warn("Incomplete double-dash comment\n");
			break;
		default:
			assert(0);
			break;
		}
	}
	*dst = '\0';
	return(idx);
}

int
dbd_ix_st_finish(SV *sth, imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_st_finish";
	int rc;

	dbd_ix_enter(function);

	if ((rc = dbd_db_setconnection(imp_sth->dbh)) == 0)
	{
		dbd_ix_savesqlca(imp_sth->dbh);
	}
	else
	{
		rc = dbd_ix_close(imp_sth);
		DBIc_ACTIVE_off(imp_sth);
	}

	dbd_ix_exit(function);      // KBC 7/20/99 changed from dbd_ix_enter
	return rc;
}

/* Free up resources used by the cursor or statement */
void
dbd_ix_st_destroy(SV *sth, imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_st_destroy";
	dbd_ix_enter(function);
	del_statement(imp_sth);
	dbd_ix_exit(function);
}

/* Convert DECIMAL to convenient string */
/* Don't forget that decimals are stored in a base-100 notation */
static char *decgen(dec_t *val, int plus)
{
	char *str;
	int	ndigits = val->dec_ndgts * 2;
	int nbefore = (val->dec_exp) * 2;
	int nafter = (ndigits - nbefore);

	if (nbefore > 14 || nbefore < -2)
	{
		/* Too large or too small for fixed point */
		str = decsci(val, ndigits, 0);
	}
	else
	{
		str = decfix(val, nafter, 0);
	}
	if (*str == ' ')
		str++;
	/* Chop trailing blanks */
	str[byleng(str, strlen(str))] = '\0';
	return str;
}

/*
** Fetch a single row of data.
**
** Note the use of 'varchar' variables.  Given the sample code:
**
** #include <stdio.h>
** int main(int argc, char **argv)
** {
**     EXEC (COMMENT) SQL BEGIN DECLARE SECTION;
**     char    cc[30];
**     varchar vc[30];
**     EXEC (COMMENT) SQL END DECLARE SECTION;
**     EXEC (COMMENT) SQL WHENEVER ERROR STOP;
**     EXEC (COMMENT) SQL DATABASE Apt;
**     EXEC (COMMENT) SQL CREATE TEMP TABLE Test(Col01 CHAR(20), Col02 VARCHAR(20));
**     EXEC (COMMENT) SQL INSERT INTO Test VALUES("ABCDEFGHIJ     ", "ABCDEFGHIJ     ");
**     EXEC (COMMENT) SQL SELECT Col01, Col01 INTO :cc, :vc FROM Test;
**     printf("Col01: cc = <<%s>>\n", cc);
**     printf("Col01: vc = <<%s>>\n", vc);
**     EXEC (COMMENT) SQL SELECT Col02, Col02 INTO :cc, :vc FROM TestTable;
**     printf("Col02: cc = <<%s>>\n", cc);
**     printf("Col02: vc = <<%s>>\n", vc);
**     return(0);
** }
**
** The output looks like:
**		Col01: cc = <<ABCDEFGHIJ                   >>
**		Col01: vc = <<ABCDEFGHIJ          >>
**		Col02: cc = <<ABCDEFGHIJ                   >>
**		Col02: vc = <<ABCDEFGHIJ     >>
** Note that the data returned into 'cc' is blank padded to the length of
** the host variable, not the length of the database column, whereas 'vc'
** is blank-padded to the length of the database column for a CHAR column,
** and to the length of the inserted data in a VARCHAR column.
*/
AV *
dbd_ix_st_fetch(SV *sth, imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_st_fetch";
	AV	*av;
      /*
       * SQL BEGIN DECLARE SECTION
       */
       char           *nm_cursor = imp_sth->nm_cursor;
       char           *nm_obind = imp_sth->nm_obind;
       char           coldata[257];           /* KBC -- changed from array of pointers */
       int            needfree;               /* KBC -- added sane malloc/free handling */
       long			coltype;
       long			collength;
       long			colind;
       int				index;
       char           *result;
       long            length;
       struct sqlda *descript;
       dec_t decval;
      /*
       * SQL END DECLARE SECTION
       */

	dbd_ix_enter(function);

        descript = find_descriptor(nm_obind);

	if (dbd_db_setconnection(imp_sth->dbh) == 0)
	{
		dbd_ix_savesqlca(imp_sth->dbh);
		dbd_ix_exit(function);
		return Nullav;
	}

        /*
         * EXEC SQL FETCH :nm_cursor USING DESCRIPTOR :nm_obind;
         */
         {
         _iqnftch(find_cursor(nm_cursor), 0, (char *) 0, descript, 1, (long) 0, 0, (char *) 0, (char *) 0, 0);
	dbd_ix_debug(2, "after iqnftch\n", function);
         }
	dbd_ix_savesqlca(imp_sth->dbh);
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode != 0)
	{
		if (sqlca.sqlcode != SQLNOTFOUND)
		{
			dbd_ix_debug(1, "Exit %s -- fetch failed\n", function);
		}
		else
		{
			imp_sth->st_state = Finished;
			dbd_ix_debug(1, "Exit %s -- SQLNOTFOUND\n", function);
		}
		dbd_ix_exit(function);
		return Nullav;
	}
	imp_sth->n_rows++;

	av = DBIS->get_fbav(imp_sth);

	for (index = 1; index <= imp_sth->n_columns; index++)
	{
		SV *sv = AvARRAY(av)[index-1];
/*
		EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
				:coltype = TYPE, :collength = LENGTH,
				:colind = INDICATOR, :colname = NAME;
		dbd_ix_sqlcode(imp_sth->dbh);
*/
                collength = descript->sqlvar[index-1].sqllen;
                needfree = 0;
/*
*/

                if (descript->sqlvar[index-1].sqlidata) {
                   coltype = ((struct ind *) (descript->sqlvar[index-1].sqlidata))->origType;
                   colind = ((struct ind *) (descript->sqlvar[index-1].sqlidata))->indicator;
                } else {
                   coltype = descript->sqlvar[index-1].sqltype;
                   colind = 0;
                }
#ifdef debugstuff
       char			colname[NAMESIZE];
                strcpy(colname,descript->sqlvar[index-1].sqlname && 
                               *descript->sqlvar[index-1].sqlname ? 
                               descript->sqlvar[index-1].sqlname : "*" );

                /* printf("colname: %s, coltype: %d, collength: %d colind: %d, data: %s\n",colname,coltype,collength,colind,descript->sqlvar[index-1].sqldata); */
#endif
		if (colind == -1)
		{
			/* Data is null */
		dbd_ix_debug(2, "%s -- null\n", function);
			result = coldata;
			length = 0;
			result[length] = '\0';
			(void)SvOK_off(sv);
			/*warn("NULL Data: %d <<%s>>\n", length, result);*/
		}
		else
		{
			switch (coltype)
			{
			case SQLINT:
			case CLONGTYPE:
			case SQLSERIAL:
		                dbd_ix_debug(2, "%s -- int\n", function);
			     result = coldata;
                             sprintf(result,"%ld",* ((long *) descript->sqlvar[index-1].sqldata));
                             length=strlen(result);
                             break;

			case SQLSMINT:
		                dbd_ix_debug(2, "%s -- short\n", function);
			     result = coldata;
                             sprintf(result,"%hd",* ((short *) descript->sqlvar[index-1].sqldata));
                             length=strlen(result);
                             break;

			case SQLDATE:
			case SQLDTIME:
			case SQLINTERVAL:
		                dbd_ix_debug(2, "%s -- date/serial, etc\n", function);
				/* These types will always fit into a 256 character string */
/*
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:coldata = DATA;
*/
				result = descript->sqlvar[index-1].sqldata;
				length = byleng(result, strlen(result));
				result[length] = '\0';
				/*warn("Normal Data: %d <<%s>>\n", length, result);*/
				break;

			case SQLSMFLOAT:
		                dbd_ix_debug(2, "%s -- smfloat\n", function);
				sprintf(coldata, "%f",*((float *) descript->sqlvar[index-1].sqldata));
				result = coldata;
				length = strlen(result);
				break;

			case SQLFLOAT:
		                dbd_ix_debug(2, "%s -- float\n", function);
				sprintf(coldata, "%f",*((double *) descript->sqlvar[index-1].sqldata));
				result = coldata;
				length = strlen(result);
				break;


			case SQLDECIMAL:
			case SQLMONEY:
		                dbd_ix_debug(2, "%s -- decimal\n", function);
				/* Default formatting assumes 2 decimal places -- wrong! */
/*
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:decval = DATA;
*/
				strcpy(coldata, decgen((dec_t *) descript->sqlvar[index-1].sqldata, 0));
				result = coldata;
				length = strlen(result);
				/*warn("Decimal Data: %d <<%s>>\n", length, result);*/
				break;

			case SQLVCHAR:
#ifdef SQLNVCHAR
			case SQLNVCHAR:
#endif /* SQLNVCHAR */
		dbd_ix_debug(2, "%s -- varchar\n", function);
				/* These types will always fit into a 256 character string */
				/* NB: VARCHAR strings always retain trailing blanks */
/*
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:coldata = DATA;
*/
				result = descript->sqlvar[index-1].sqldata;
				length = strlen(result);
				/*warn("VARCHAR Data: %d <<%s>>\n", length, result);*/
				break;

			case SQLCHAR:
#ifdef SQLNCHAR
			case SQLNCHAR:
#endif /* SQLNCHAR */
		                dbd_ix_debug(2, "%s -- char\n", function);
				/**
				** NB: CHAR strings have trailing blanks (which are added
				** automatically by the database) removed by byleng() etc.
				*/
		                dbd_ix_debug(2, "%s -- HERE\n", function);
				/**
				** There's a bug in 5.00 and 5.01 which means that GET
				** DESCRIPTOR does not work with 'char *' as the receiving
				** column.  This is fixed in 5.02.  This code works around
				** that bug by using character arrays instead of 'char *'
				** to receive the data.  This works because sizeof(array)
				** is not the same as sizeof(&array[0]), even though in
				** every other context, array decays to &array[0].
				*/
				if (collength < 256)
				{
/*
					EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
							:coldata = DATA;
*/
                                        
					result = descript->sqlvar[index-1].sqldata;
				}
				else
				{
/*
					EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
							:longchar = DATA;
*/
					result = descript->sqlvar[index-1].sqldata;
				}
				/* Conditionally chop trailing blanks */
				length = strlen(result);
				if (DBIc_is(imp_sth, DBIcf_ChopBlanks))
					length = byleng(result, length);
				result[length] = '\0';
				/*warn("Character Data: %d <<%s>>\n", length, result);*/
				break;

			case SQLTEXT:
			case SQLBYTES:
		                dbd_ix_debug(2, "%s -- bytes\n", function);
				/*warn("fetch: processing blob\n");*/
#ifdef BLOB
				blob_locate(&blob, BLOB_IN_MEMORY);
/*
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:blob = DATA;
*/
                                memcpy(&blob,descript->sqlvar[index-1].sqldata,descript->sqlvar[index-1].sqllen);

				result = blob.loc_buffer;
				length = blob.loc_size;
				/* Warning - this data is not null-terminated! */
				/*warn("Blob Data: %d <<%*.*s>>\n", length, length, length, result);*/
#endif
				break;

			default:
				croak("%s - Unknown type code: %ld (no IUS support)\n",
					function, coltype);
				/*NOTREACHED*/
				length = 0;
				result = coldata;
				result[length] = '\0';
				break;
			}
			if (sqlca.sqlcode < 0)
			{
				dbd_ix_sqlcode(imp_sth->dbh);
				*result = '\0';
			}
			sv_setpvn(sv, result, length);
			if (needfree) free(result);
		}
	}
	dbd_ix_exit(function);
	return(av);
}

static int dbd_ix_open(imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_open";
      /*
       * SQL BEGIN DECLARE SECTION
       */
       char           *nm_cursor = imp_sth->nm_cursor;
       char           *nm_ibind = imp_sth->nm_ibind;
      /*
       * SQL END DECLARE SECTION
       */

	dbd_ix_enter(function);

	if (imp_sth->st_state == Opened || imp_sth->st_state == Finished)
		dbd_ix_close(imp_sth);
	assert(imp_sth->st_state == Declared);

	if ((imp_sth->n_bound > 0) && (imp_sth->st_type != SQ_INSERT))

      /*
       * EXEC SQL OPEN nm_cursor USING DESCRIPTOR nm_ibind;
            int _iqcopen(_SQCURSOR *cursor,
                         int icnt,
                         struct sqlvar_struct *ibind,
                         struct sqlda *idesc,
                         struct value *ivalues,
                         int useflag);
       */
       {

       _iqcopen(find_cursor(nm_cursor), 0, (struct sqlvar_struct *) 0, find_descriptor(nm_ibind), (struct value *) 0, 1);
       }
	else

       /*
        * EXEC SQL OPEN nm_cursor;
        */
        {
        _iqcopen(find_cursor(nm_cursor), 0, (struct sqlvar_struct  *) 0, (struct sqlda *) 0, (struct value *) 0, 0);
        }
	dbd_ix_sqlcode(imp_sth->dbh);
	dbd_ix_savesqlca(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		dbd_ix_exit(function);
		return 0;
	}
	imp_sth->st_state = Opened;
	if (imp_sth->dbh->is_modeansi == True)
		imp_sth->dbh->is_txactive = True;
	imp_sth->n_rows = 0;
	dbd_ix_exit(function);
	return 1;
}

static int dbd_ix_exec(imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_exec";
      /*
       * SQL BEGIN DECLARE SECTION
       */
       char           *nm_stmnt = imp_sth->nm_stmnt;
       char           *nm_ibind = imp_sth->nm_ibind;
       char           *nm_cursor = imp_sth->nm_cursor;
      /*
       * SQL END DECLARE SECTION
       */
	imp_dbh_t *dbh = imp_sth->dbh;
	int rc = 1;
	Boolean exec_stmt = True;

	dbd_ix_enter(function);

	/* KBC -- using PUT for cursor-prepared inserts */
	if ((imp_sth->st_type == SQ_INSERT) && (imp_sth->n_columns > 0))
        {
/* KBC - Also open if its an insert cursor */
         	rc = dbd_ix_open(imp_sth);
                if (rc == 0) {
		   dbd_ix_debug(2, "%s -- whoa, open failed\n", function);
                   return(rc);
                }
		dbd_ix_debug(2, "%s -- doing iqinsput\n", function);
	 	_iqinsput(find_cursor(nm_cursor), 0, (char *) 0, find_descriptor(nm_ibind), (char *) 0);
        } else {
		if (imp_sth->st_type == SQ_BEGWORK)
		{
			/* BEGIN WORK in a logged non-ANSI database with AutoCommit Off */
			/* will fail because we're already in a transaction. */
			/* Pretend it succeeded. */
			if (dbh->is_loggeddb == True && dbh->is_modeansi == False)
			{
				if (DBI_AutoCommit(dbh) == False)
				{
					exec_stmt = False;
					sqlca.sqlcode = 0;
				}
			}
		}

		if (exec_stmt == True)
		{

			if (imp_sth->n_bound > 0)
			{

			 /*
			  * EXEC SQL EXECUTE nm_stmnt USING DESCRIPTOR nm_ibind;
			  */
			  {
			  _iqxecute(find_cursor(nm_cursor), 0, (char *) 0, find_descriptor(nm_ibind), (char *) 0);
			  }
			}
			else
			{

			/*
			 * EXEC SQL EXECUTE nm_stmnt;
			 */
			 {
			 _iqxecute(find_cursor(nm_cursor), 0, (char *) 0, (char *) 0, (char *) 0);
			 }
			}

		}
	}

	dbd_ix_sqlcode(dbh);
	dbd_ix_savesqlca(dbh);
	if (sqlca.sqlcode < 0)
	{
		dbd_ix_exit(function);
		return 0;
	}

	/**
	** Here we need to analyse what was done...
	** BEGIN WORK, COMMIT WORK, ROLLBACK WORK are important.
	** So are DATABASE, CLOSE DATABASE, CREATE DATABASE.
	** For SE, we could use START DATABASE or ROLLFORWARD DATABASE.
	** Note that although it is unlikely to happen with Perl, the DATABASE
	** operations other than CLOSE DATABASE can have a '?' place of the
	** database name, so the same statement could be executed several times
	** with different names, and the name is then available in nm_ibind.
	** On the other hand, if it is not in nm_ibind, it has to be extracted
	** from the statement string itself.
	*/
	imp_sth->n_rows = sqlca.sqlerrd[2];
	switch (imp_sth->st_type)
	{
	case SQ_BEGWORK:
		dbd_ix_debug(3, "%s: BEGIN WORK\n", dbd_ix_module());
		dbh->is_txactive = True;
		assert(dbh->is_loggeddb == True);
		/* Even BEGIN WORK has to be committed if AutoCommit is On */
		if (DBI_AutoCommit(dbh) == True)
			rc = dbd_ix_commit(dbh);
		break;
	case SQ_COMMIT:
		dbd_ix_debug(3, "%s: COMMIT WORK\n", dbd_ix_module());
		dbh->is_txactive = False;
		assert(dbh->is_loggeddb == True);
		/* In a logged database with AutoCommit Off, do BEGIN WORK */
		if (dbh->is_modeansi == False && DBI_AutoCommit(dbh) == False)
			rc = dbd_ix_begin(dbh);
		break;
	case SQ_ROLLBACK:
		dbd_ix_debug(3, "%s: ROLLBACK WORK\n", dbd_ix_module());
		dbh->is_txactive = False;
		assert(dbh->is_loggeddb == True);
		/* In a logged database with AutoCommit Off, do BEGIN WORK */
		if (dbh->is_modeansi == False && DBI_AutoCommit(dbh) == False)
			rc = dbd_ix_begin(dbh);
		break;
	case SQ_DATABASE:
		dbh->is_txactive = False;
		/* Analyse new database name and record it */
		break;
	case SQ_CREADB:
		dbh->is_txactive = False;
		/* Analyse new database name and record it */
		break;
	case SQ_STARTDB:
		dbh->is_txactive = False;
		/* Analyse new database name and record it */
		break;
	case SQ_RFORWARD:
		dbh->is_txactive = False;
		/* Analyse new database name and record it */
		break;
	case SQ_CLSDB:
		dbh->is_txactive = False;
		/* Record that no database is open */
		break;
	default:
		if (dbh->is_modeansi)
			dbh->is_txactive = True;
		/* COMMIT WORK for MODE ANSI databases when AutoCommit is On */
		if (dbh->is_modeansi == True && DBI_AutoCommit(dbh) == True)
			rc = dbd_ix_commit(dbh);
		break;
	}

/* KBC -- added to reclaim memory for INSERT (put) */
	if ((imp_sth->st_type == SQ_INSERT) && (imp_sth->n_columns > 0))
            rc = dbd_ix_close(imp_sth);

	DBIc_on(imp_sth, DBIcf_IMPSET);	/* Qu'est que c'est? */
	dbd_ix_exit(function);
	return rc;
}

/*
** Execute the statement.
** - OPEN the cursor for a SELECT or cursory EXECUTE PROCEDURE.
** - EXECUTE the statement for anything else.
** Remember that dbd_st_execute() must return:
**      -2 or smaller   => error
**      -1              => unknown number of rows affected
**       0 or greater   => known number of rows affected
** DBD::Sqlflex will not return -1, though there's at least half an
** argument for returning -1 after dbd_ix_open() is called.
*/
int
dbd_ix_st_execute(SV *sth, imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_st_execute";
	int rv;
	int rc;

	dbd_ix_enter(function);
	if ((rc = dbd_db_setconnection(imp_sth->dbh)) == 0)
	{
		dbd_ix_savesqlca(imp_sth->dbh);
		assert(sqlca.sqlcode < 0);
		dbd_ix_exit(function);
		return(sqlca.sqlcode);
	}

	if (imp_sth->st_type == SQ_SELECT)
		rc = dbd_ix_open(imp_sth);
#ifdef SQ_EXECPROC
	else if (imp_sth->st_type == SQ_EXECPROC && imp_sth->n_columns > 0)
		rc = dbd_ix_open(imp_sth);
#endif /* SQ_EXECPROC */
        else
		rc = dbd_ix_exec(imp_sth);

	/* Map returned values from dbd_ix_exec and dbd_ix_open */
	if (rc == 0)
	{
		assert(sqlca.sqlcode < 0);
		rv = sqlca.sqlcode;
	}
	else
	{
		rv = sqlca.sqlerrd[2];
		assert(sqlca.sqlcode == 0 && rv >= 0);
	}

	dbd_ix_exit(function);
	return(rv);
}

int dbd_ix_st_rows(SV *sth, imp_sth_t *imp_sth)
{
	return(imp_sth->n_rows);
}

int dbd_ix_st_bind_ph(SV *sth, imp_sth_t *imp_sth, SV *param, SV *value,
	IV sql_type, SV *attribs, int is_inout, IV maxlen)
{
	static const char function[] = DBD_IX_MODULE "::st::dbd_ix_st_bind_ph";
	int rc;

	dbd_ix_enter(function);
	if (is_inout)
		croak("%s() - inout parameters not implemented\n", function);
	rc = dbd_ix_bindsv(imp_sth, SvIV(param), value);
	dbd_ix_exit(function);
	return(rc);
}

int dbd_ix_st_blob_read(SV *sth, imp_sth_t *imp_sth, int field, long offset,
long len, SV *destrv, long destoffset)
{
	croak("%s::st::dbd_ix_st_blob_read() - not implemented\n", dbd_ix_module());
}

/* #include <string.h> */
/* #include "esqlperl.h" */
                                                
Boolean
dbd_ix_opendatabase(char *dbase)
{
/*
 * SQL BEGIN DECLARE SECTION
 */
 char           *dbname = dbase;
/*
 * SQL END DECLARE SECTION
 */
	Boolean         conn_ok = False;

	if (dbase == (char *)0 || *dbase == '\0')
	{
		dbd_ix_debug(1, "ESQL/C 5.0x 'implicit' DATABASE - %s\n", "no-op");
		sqlca.sqlcode = 0;
		conn_ok = True;
	}
	else
	{
		dbd_ix_debug(1, "DATABASE %s\n", dbname);

/*
 * EXEC SQL DATABASE :dbname;
 */
 {
 static struct sqlvar_struct _sqibind[] =
 {
 {100, 0, (char *) 0, (short *) 0, (char *) 0, (char *) 0, 0, 0, (char *) 0},

 };
 _sqibind[0].sqldata = (dbname);
 _iqdatabase("?", 0, 1, _sqibind);
 }
		if (sqlca.sqlcode == 0)
			conn_ok = True;
	}
	return(conn_ok);
}

void
dbd_ix_closedatabase(char *dbname)
{
	dbd_ix_debug(1, "CLOSE DATABASE %s\n", (dbname ? dbname : ""));

/*
 * EXEC SQL CLOSE DATABASE;
 */
 {
 _iqdbclose();
 }
	if ((dbname == 0 || *dbname == '\0') && sqlca.sqlcode == -349)
	{
		                                      
		                                         
		sqlca.sqlcode = 0;
	}
}
                                                                              
void dbd_ix_setconnection(char *conn)
{
	dbd_ix_debug(1, "SET CONNECTION - %s (NO-OP)\n", conn);
	sqlca.sqlcode = 0;
}
/* -------------- End of $RCSfile: dbdimp.ec,v $ -------------- */
