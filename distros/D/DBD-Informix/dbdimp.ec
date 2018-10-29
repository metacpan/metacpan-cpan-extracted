/*
 * @(#)$Id: dbdimp.ec,v 2018.1 2018/05/11 08:21:12 jleffler Exp $
 *
 * @(#)$Product: Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28) $
 * @(#)Implementation details
 *
 * Copyright 1994-95 Tim Bunce
 * Copyright 1995-96 Alligator Descartes
 * Copyright 1994    Bill Hailes
 * Copyright 1996    Terry Nightingale
 * Copyright 1996-99 Jonathan Leffler
 * Copyright 1999    Bill Rothanburg <brothanb@fll-ro.dhl.com>
 * Copyright 2000-01 Informix Software Inc
 * Copyright 2000    Paul Palacios, C-Group Inc
 * Copyright 2001-03 IBM
 * Copyright 2002    Bryan Castillo <Bryan_Castillo@eFunds.com>
 * Copyright 2003-18 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_dbdimp_ec[] = "@(#)$Id: dbdimp.ec,v 2018.1 2018/05/11 08:21:12 jleffler Exp $";
#endif /* lint */

#include <float.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define MAIN_PROGRAM    /* Embed version information for JLSS headers */
#include "Informix.h"
#include "sqltoken.h"
#include "esqlutil.h"

/* Beware omitting the semi-colon! */
$include "esqlinfo.h";

#define L_CURLY '{'
#define R_CURLY '}'

/**
 ** JL 2000-01-20: ESQL/C versions 9.2x and later use 32 characters for
 ** usernames.  Earlier versions use 8 characters.  This is safe for the
 ** immediately foreseeable future, but it would be better if B69092 were
 ** fixed so this was not necessary and the #define from esqlc.h could be
 ** used instead of this $define -- DRY (Don't Repeat Yourself)!
 */
$define SQL_USERLEN1     33;

DBISTATE_DECLARE;

static const Sqlca zero_sqlca;
static const Link zero_link = { 0, 0, 0 };

/* One day, these will go!  Maybe... */
static void del_statement(imp_sth_t *imp_sth);
static int  dbd_ix_begin(imp_dbh_t *dbh);

/*
** Discussion of imp_sth->st_state (JL 2002-02-12).
** The State enumeration can take the values: Unused, Prepared,
** Allocated, Described, Declared, Opened, NoMoreData.
** -- Unused state means that there is no prepared statement, nor (by
**    definition) a declared cursor, nor any allocated descriptors.
** -- Prepared state means that there is a prepared statement but no
**    declared cursor nor any allocated descriptors. -JL-VERIFY
** -- Allocated state means that there is a prepared statement and a
**    descriptor for the input parameters (nm_idesc), but no declared
**    cursor nor any output descriptor (nm_odesc). -JL-VERIFY
** -- Described state means that there is a prepared statement and
**    descriptors for both input and output parameters. -JL-VERIFY
** -- Declared state means that there is both a prepared statement and a
**    declared cursor (which is currently closed) and descriptors for
**    both input and output parameters.
** -- Opened state means that the cursor is also open.
** -- NoMoreData state means that the cursor is closed, but that any
**    further fetches on the statement should always indicate NoMoreData
**    (SQLNOTFOUND).  This is a consequence of the DBI requirement that
**    the $sth->finish function should only be necessary for an early
**    exit from a fetch loop.  If you use $sth->finish on a NoMoreData
**    cursor, the state is changed to Declared.  If you use $sth->finish
**    on an open cursor, the cursor is closed and the state is changed
**    to Declared.  If you attempt $sth->finish on a cursor in any other
**    state, you will get an error.
*/

/* ================================================================= */
/* ==================== Driver Level Operations ==================== */
/* ================================================================= */

/* Official name for DBD::Informix module */
const char     *
dbd_ix_module(void)
{
    return(DBD_IX_MODULE);
}

/* Print message if debug level set high enough */
void
(dbd_ix_debug)(int n, const char *fmt, ...)
{
    fflush(stdout);
    /*
    ** TIMB sent an email dated 2007-04-23 stating that drivers should
    ** avoid using DBIS, because it is slow, especially on
    ** multi-threaded Perl.  However, the alternatives require a handle
    ** - and the dbd_ix_debug() function is not always invoked where
    ** there's a handle available.  The alternative is to test
    ** DBIc_TRACE_LEVEL(imp_xxh) at the call site (saving a function
    ** call to boot).  However, doing so is tricky.  The primary
    ** references to dbd_ix_debug() outside this file are in esqlc_v5.ec
    ** and esqlc_v6.ec; esqltest.ec provides a dummy implementation of
    ** this for the test code, and the references in link.c could be
    ** removed.  The esqlc_vN.ec code is used with no Perl whatsoever,
    ** so no imp_xxh is available.
    ** The calling code could pass the dbi_trace_level to those functions:
    **       dbd_ix_opendatabase(), dbd_ix_closedatabase(),
    **       dbd_ix_connect(), dbd_ix_disconnect(), dbd_ix_setconnection()
    */
    if (DBIS->debug >= n)
    {
        va_list args;
        char    buffer[1024];

        va_start(args, fmt);
        vsnprintf(buffer, sizeof(buffer), fmt, args);
        va_end(args);
        warn("%s", buffer);
    }
}

#ifdef DBD_IX_DEBUG_ENVIRONMENT
static void
dbd_ix_printenv(const char *s1, const char *s2)
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
void
dbd_ix_enter(const char *function)
{
    dbd_ix_debug(1, "\t-->> %s::%s()\n", dbd_ix_module(), function);
}

/* Print message on exit from function */
void
dbd_ix_exit(const char *function)
{
    dbd_ix_debug(1, "\t<<-- %s::%s()\n", dbd_ix_module(), function);
}

/* Do DBI-mandated standard initialization */
void
dbd_ix_init(dbistate_t *dbistate)
{
    DBISTATE_INIT;
}

/* Formally initialize the DBD::Informix driver structure */
int
dbd_ix_dr_driver(SV *drh)
{
    D_imp_drh(drh);

    imp_drh->n_connections = 0;         /* No active connections */
    imp_drh->current_connection = 0;    /* No name */
    imp_drh->multipleconnections = True;
    dbd_ix_link_newhead(&imp_drh->head);    /* Linked list of connections */

    return 1;
}

/* Relay function for use by dbd_ix_link_delchain() */
/* Destroys a statement when a database connection is destroyed */
static void
dbd_st_destroyer(void *data)
{
    static const char function[] = "dbd_st_destroyer";
    dbd_ix_enter(function);
    del_statement((imp_sth_t *)data);
    dbd_ix_exit(function);
}

/* Delete all the statements (and other data) associated with a connection */
static void
del_connection(imp_dbh_t *imp_dbh)
{
    static const char function[] = "del_connection";
    dbd_ix_enter(function);
    dbd_ix_link_delchain(&imp_dbh->head, dbd_st_destroyer);
    dbd_ix_exit(function);
}

/* Relay (interface) function for use by dbd_ix_link_delchain() */
/* Destroys a database connection when a driver is destroyed */
static void
dbd_db_destroyer(void *data)
{
    static const char function[] = "dbd_db_destroyer";
    dbd_ix_enter(function);
    del_connection((imp_dbh_t *)data);
    dbd_ix_exit(function);
}

/* Disconnect all connections (cleanly) */
int
dbd_ix_dr_discon_all(SV *drh, imp_drh_t *imp_drh)
{
    static const char function[] = "dbd_ix_dr_discon_all";
    dTHR;

    dbd_ix_enter(function);
    dbd_ix_link_delchain(&imp_drh->head, dbd_db_destroyer);
    dbd_ix_exit(function);
    return(1);
}

/* Format a Informix error message (both SQL and ISAM parts) */
static void
dbd_ix_fmterror(ErrNum rc, char *msgbuf, size_t msgsiz)
{
    char errbuf[256];
    char fmtbuf[256];
    char sql_buf[256];
    char isambuf[256];
    size_t sql_len;
    size_t isamlen = 0;

    assert(msgsiz >= sizeof(sql_buf) + sizeof(isambuf));
    /* Format SQL (primary) error */
    if (rgetmsg(rc, errbuf, sizeof(errbuf)) != 0)
        strcpy(errbuf, "<<Failed to locate SQL error message>>");
    snprintf(fmtbuf, sizeof(fmtbuf), errbuf, sqlca.sqlerrm);
    sql_len = snprintf(sql_buf, sizeof(sql_buf), "SQL: %ld: %s", rc, fmtbuf);

    /* Format ISAM (secondary) error */
    if (sqlca.sqlerrd[1] != 0)
    {
        if (rgetmsg(sqlca.sqlerrd[1], errbuf, sizeof(errbuf)) != 0)
            strcpy(errbuf, "<<Failed to locate ISAM error message>>");
        snprintf(fmtbuf, sizeof(fmtbuf), errbuf, sqlca.sqlerrm);
        isamlen = snprintf(isambuf, sizeof(isambuf), "ISAM: %ld: %s", (long)sqlca.sqlerrd[1], fmtbuf);
    }
    else
        isambuf[0] = '\0';

    /* Concatenate SQL and ISAM messages */
    /* Note that (untruncated) messages have trailing newlines */
    if (sql_len + isamlen >= msgsiz)
    {
        sql_len = MIN(msgsiz-1, sql_len);
        isamlen = MIN(msgsiz-sql_len-1, isamlen);
    }
    memmove(msgbuf, sql_buf, sql_len + 1);
    memmove(msgbuf + sql_len, isambuf, isamlen);
    /* Chop the trailing newline so Perl appends line number info. */
    /* Problem reported by Andrew Pimlott <pimlott@abel.math.harvard.edu> */
    msgbuf[sql_len+isamlen-1] = '\0';
}

/* Format a Informix error message - driver handle */
static void
dbd_ix_dr_seterror(imp_drh_t *imp_drh, ErrNum rc)
{
    if (rc < 0)
    {
        char msgbuf[512];
        dbd_ix_fmterror(rc, msgbuf, sizeof(msgbuf));
        /* Record error number, error message, and error state */
        sv_setiv(DBIc_ERR(imp_drh), (IV)rc);
        sv_setpv(DBIc_ERRSTR(imp_drh), msgbuf);
        sv_setpv(DBIc_STATE(imp_drh), SQLSTATE);
        dbd_ix_debug(1, "***ERROR***\n%s\n", msgbuf);
    }
}

/* Format a Informix error message - database handle */
static void
dbd_ix_db_seterror(imp_dbh_t *imp_dbh, ErrNum rc)
{
    if (rc < 0)
    {
        char msgbuf[512];
        dbd_ix_fmterror(rc, msgbuf, sizeof(msgbuf));
        /* Record error number, error message, and error state */
        sv_setiv(DBIc_ERR(imp_dbh), (IV)rc);
        sv_setpv(DBIc_ERRSTR(imp_dbh), msgbuf);
        sv_setpv(DBIc_STATE(imp_dbh), SQLSTATE);
        dbd_ix_debug(1, "***ERROR***\n%s\n", msgbuf);
    }
}

static void
dbd_ix_db_seterror746(imp_dbh_t *imp_dbh, const char *msg)
{
    strncpy(sqlca.sqlerrm, msg, sizeof(sqlca.sqlerrm)-1);
    sqlca.sqlerrm[sizeof(sqlca.sqlerrm)-1] = '\0';
    dbd_ix_db_seterror(imp_dbh, -746);
}

/* Save the current sqlca record */
/* The saving of serials could be dubious - but it is symmetric */
static void
dbd_ix_savesqlca(imp_dbh_t *imp_dbh)
{
    imp_dbh->ix_sqlca = sqlca;
    ifx_getserial8(&imp_dbh->ix_serial8);
#ifdef ESQLC_BIGINT
    ifx_getbigserial(&imp_dbh->ix_bigserial);
#endif /* ESQLC_BIGINT */
}

/* Record (and report) and SQL error, saving SQLCA information */
static void
dbd_ix_sqlcode(imp_dbh_t *imp_dbh)
{
    /* If there is an error, record it */
    if (sqlca.sqlcode < 0)
    {
        dbd_ix_savesqlca(imp_dbh);
        dbd_ix_db_seterror(imp_dbh, sqlca.sqlcode);
    }
}

/* ================================================================= */
/* =================== Database Level Operations =================== */
/* ================================================================= */

/* Initialize a connection structure, allocating names */
static void
new_connection(imp_dbh_t *imp_dbh)
{
    static long     connection_num = 0;

    sprintf(imp_dbh->nm_connection, "x_%09ld", connection_num++);

    imp_dbh->is_onlinedb    = False;
    imp_dbh->is_loggeddb    = False;
    imp_dbh->is_modeansi    = False;
    imp_dbh->is_txactive    = False;
    imp_dbh->is_connected   = False;
    imp_dbh->no_replication = False; /* Bryan Castillo: work is replicated by default */
    imp_dbh->has_procs      = False;
    imp_dbh->has_blobs      = False;
    imp_dbh->srvr_vrsn      = 0;
    imp_dbh->srvr_name      = (SV *)0;
    imp_dbh->database       = (SV *)0;
    imp_dbh->blob_bind      = BLOB_DEFAULT;
    imp_dbh->ix_sqlca       = zero_sqlca;
    imp_dbh->chain          = zero_link;
    imp_dbh->head           = zero_link;
    imp_dbh->dbh_pid        = getpid();
    imp_dbh->enable_utf8    = False; /* UTF8 patch */
}

/* Get the server version number from DBINFO */
static int dbd_ix_dbinfo_version(void)
{
    EXEC SQL BEGIN DECLARE SECTION;
    string maj_ver[SQL_USERLEN1];
    string min_ver[SQL_USERLEN1];
    EXEC SQL END DECLARE SECTION;
    int vernum = 0;
    Sqlca local = sqlca;

    /* Note DBINFO('version','major') support was added relatively recently */
    /* Some really old servers might not support it - ignore the errors and return 0 */
    EXEC SQL DECLARE c_dbinfo_version CURSOR FOR
        SELECT DBINFO('version','major') AS major,
               DBINFO('version', 'minor') AS minor
           FROM "informix".Systables WHERE TabName = ' VERSION';
    if (sqlca.sqlcode == 0)
    {
        EXEC SQL OPEN c_dbinfo_version;
        if (sqlca.sqlcode == 0)
        {
            EXEC SQL FETCH c_dbinfo_version INTO :maj_ver, :min_ver;
            if (sqlca.sqlcode == 0)
            {
                /* Convert "11" and "10" to "1110". */
                if (strlen(maj_ver) > 3 || strlen(min_ver) > 3)
                {
                    /* We've got problems! */
                    dbd_ix_debug(0, "Bad Informix server version information <<%s>><<%s>>\n", maj_ver, min_ver);
                    strcpy(maj_ver, "0");
                }
                else
                {
                    strcat(maj_ver, min_ver);
                }
                vernum = strtol(maj_ver, (char **)0, 10);
            }
            EXEC SQL CLOSE c_dbinfo_version;
        }
        EXEC SQL FREE c_dbinfo_version;
        /* In case we are in a MODE ANSI database */
        EXEC SQL ROLLBACK WORK;
    }
    sqlca = local;
    return vernum;
}

/* Get the server version number from systables.owner for tabname ' VERSION' */
/* This gets confusing - IDS 11.10.xC1 identifies itself as 9.51C1 */
static int dbd_ix_systab_version(void)
{
    EXEC SQL BEGIN DECLARE SECTION;
    string verstr[SQL_USERLEN1];
    EXEC SQL END DECLARE SECTION;
    int vernum = 0;
    Sqlca local = sqlca;

    /* Note DBINFO('version','major') and DBINFO('version','minor') could be used */
    EXEC SQL DECLARE c_systab_version CURSOR FOR
        SELECT Owner FROM "informix".Systables WHERE TabName = ' VERSION';
    if (sqlca.sqlcode == 0)
    {
        EXEC SQL OPEN c_systab_version;
        if (sqlca.sqlcode == 0)
        {
            EXEC SQL FETCH c_systab_version INTO :verstr;
            if (sqlca.sqlcode == 0)
            {
                /* Convert 7.30UC1 to 730, allowing for version 10.30, etc */
                char *dot = strchr(verstr, '.');
                if (dot != 0)
                    memmove(dot, dot+1, strlen(verstr) - (dot - verstr) + 1);
                vernum = strtol(verstr, (char **)0, 10);
            }
            EXEC SQL CLOSE c_systab_version;
        }
        EXEC SQL FREE c_systab_version;
        /* In case we are in a MODE ANSI database */
        EXEC SQL ROLLBACK WORK;
    }
    sqlca = local;
    return vernum;
}

/* Get the server version number 930 => 9.30 */
static int dbd_ix_serverversion(void)
{
    int vernum;
    if ((vernum = dbd_ix_dbinfo_version()) <= 0)
        vernum = dbd_ix_systab_version();
    return(vernum);
}

static void
dbd_ix_setdbtype(imp_dbh_t *imp_dbh)
{
    imp_dbh->is_onlinedb = DBD_IX_BOOLEAN(sqlca.sqlwarn.sqlwarn3 == 'W');
    imp_dbh->is_modeansi = DBD_IX_BOOLEAN(sqlca.sqlwarn.sqlwarn2 == 'W');
    imp_dbh->is_loggeddb = DBD_IX_BOOLEAN(sqlca.sqlwarn.sqlwarn1 == 'W');
    /* SE 5.00 and later has stored procedures */
    /* In general, OnLine 5.00 and later has stored procedures */
    imp_dbh->has_procs = True;
    /* SE does not have blobs. */
    /* In general, OnLine 4.00 and later has blobs */
    imp_dbh->has_blobs = imp_dbh->is_onlinedb;

    imp_dbh->srvr_vrsn = dbd_ix_serverversion();
    if (imp_dbh->srvr_vrsn >= 800 && imp_dbh->srvr_vrsn < 830)
    {
        /* XPS 8.0x, 8.1x and 8.2x do not support stored procedures or blobs */
        imp_dbh->has_procs = False;
        imp_dbh->has_blobs = False;
    }
}

/* Preset AutoCommit value */
static void
dbd_ix_db_check_for_autocommit(imp_dbh_t *imp_dbh, SV *dbattr)
{
    static const char function[] = "dbd_ix_db_check_for_autocommit";
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
            dbd_ix_debug(1, "AutoCommit set to %ld\n", SvTRUE(*svpp));
            DBIc_set(imp_dbh, DBIcf_AutoCommit, SvTRUE(*svpp));
        }
    }
    else
    {
        dbd_ix_debug(1, "SvROK = %ld, SvTYPE = %ld\n", SvROK(dbattr),
            SvTYPE(SvRV(dbattr)));
    }
    dbd_ix_exit(function);
}

int
dbd_ix_db_connect(SV *dbh, imp_dbh_t *imp_dbh, char *name, char *user, char *pass, SV *attr)
{
    static const char function[] = "dbd_ix_db_connect";
    dTHR;
    D_imp_drh_from_dbh;
    Boolean conn_ok;

    dbd_ix_enter(function);
    new_connection(imp_dbh);
    if (name != 0 && *name == '\0')
        name = 0;
    if (name != 0 && strcmp(name, DEFAULT_DATABASE) == 0)
        name = 0;

#ifdef DBD_IX_DEBUG_ENVIRONMENT
    dbd_ix_printenv("pre-connect", function);
#endif /* DBD_IX_DEBUG_ENVIRONMENT */

    if (user != 0 && *user == '\0')
        user = 0;
    if (pass != 0 && *pass == '\0')
        pass = 0;
    /* 6.00 and later versions of Informix-ESQL/C support CONNECT */
    conn_ok = dbd_ix_connect(imp_dbh->nm_connection, name, user, pass);

#ifdef DBD_IX_DEBUG_ENVIRONMENT
    dbd_ix_printenv("post-connect", function);
#endif /* DBD_IX_DEBUG_ENVIRONMENT */

    if (sqlca.sqlcode < 0)
    {
        /* Failure of some sort */
        /*
        ** JL 2002-12-13: error must be reported to imp_drh, not imp_dbh
        ** (because imp_dbh is destroyed when the connect fails).
        */
        dbd_ix_dr_seterror(imp_drh, sqlca.sqlcode);
        dbd_ix_debug(1, "\t<<-- %s (**ERROR-1**)\n", function);
        dbd_ix_exit(function);
        return 0;
    }

    /* Examine sqlca to see what sort of database we are hooked up to */
    dbd_ix_savesqlca(imp_dbh);
    if (name != 0)
        imp_dbh->database = newSVpv(name, 0);
    dbd_ix_setdbtype(imp_dbh);
    imp_dbh->is_connected = conn_ok;

    /* Record extra active connection and name of current connection */
    imp_drh->n_connections++;
    imp_drh->current_connection = imp_dbh->nm_connection;

    dbd_ix_link_add(&imp_drh->head, &imp_dbh->chain);
    imp_dbh->chain.data = (void *)imp_dbh;
    dbd_ix_link_newhead(&imp_dbh->head);

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
    dbd_ix_db_check_for_autocommit(imp_dbh, attr);
    if (name != 0 && imp_dbh->is_loggeddb == False && DBI_AutoCommit(imp_dbh) == False)
    {
        /* Simulate connection failure */
        /* JL 2002-12-13: error must be reported to imp_drh (see above) */
        dbd_ix_db_disconnect(dbh, imp_dbh);
        sqlca.sqlcode = -256;
        dbd_ix_dr_seterror(imp_drh, sqlca.sqlcode);
        dbd_ix_debug(1, "\t<<-- %s (**ERROR-2**)\n", function);
        dbd_ix_exit(function);
        return 0;
    }

    DBIc_IMPSET_on(imp_dbh);    /* imp_dbh set up now                   */
    DBIc_ACTIVE_on(imp_dbh);    /* call disconnect before freeing       */

    /* Start a transaction if the database is Logged */
    /* but not MODE ANSI and if AutoCommit is Off */
    if (imp_dbh->is_loggeddb == True && imp_dbh->is_modeansi == False)
    {
        if (DBI_AutoCommit(imp_dbh) == False)
        {
            if (dbd_ix_begin(imp_dbh) == 0)
            {
                dbd_ix_db_disconnect(dbh, imp_dbh);
                dbd_ix_debug(1, "\t<<-- %s (**ERROR-3**)\n", function);
                dbd_ix_exit(function);
                return 0;
            }
        }
    }

    dbd_ix_exit(function);
    return 1;
}

/*
** Until IDS 9.20, a database name could consist of up to 18
** characters, plus the name of the server (for which no explicit
** limit was defined), plus the at sign and the NUL at the end.
** With the release of IDS 9.20, the server and database names can
** be as long as 128 characters each, hence the limits below.
*/
#undef MAXDBS
#undef MAXDBSSIZE
#undef FASIZE
#define MAXDBS 100      /* Up to 100 databases */
#define MAXDBSSIZE  (128+128+2)
#define FASIZE (MAXDBS * MAXDBSSIZE)

/* Return list of databases visible (because of $INFORMIXSERVER and $DBPATH) */
/* NB: It may be possible to access other databases by adding explicit server names */
AV *dbd_ix_dr_data_sources(SV *drh, imp_drh_t *imp_drh, SV *attr)
{
    static const char function[] = "dbd_ix_dr_data_sources";
    int sqlcode;
    int ndbs;
    int i;
    char *dbsname[MAXDBS + 1];
    char dbsarea[FASIZE];
    AV *av = Nullav;        /* Need to return a reference to an array of (mortal) strings */

    dbd_ix_enter(function);
    sqlcode = sqgetdbs(&ndbs, dbsname, MAXDBS, dbsarea, FASIZE);
    if (sqlcode != 0)
    {
        dbd_ix_dr_seterror(imp_drh, sqlcode);
    }
    else
    {
        av = newAV();
        av_extend(av, (I32)ndbs);
        sv_2mortal((SV *)av);
        for (i = 0; i < ndbs; ++i)
        {
            av_store(av, i, newSVpvf("dbi:Informix:%s", dbsname[i]));
        }
    }
    dbd_ix_exit(function);
    return(av);
}

#undef MAXDBS
#undef MAXDBSSIZE
#undef FASIZE

/* Ensure that the correct connection is current */
static int
dbd_db_setconnection(imp_dbh_t *imp_dbh)
{
    int rc = 1;
    D_imp_drh_from_dbh;

    /* If this connection isn't connected, return with failure */
    /* Primarily a concern when destroying connections */
    if (imp_dbh->is_connected == False)
        return(0);

    /* Unreliable if this process is not the one that created the connection */
    if (imp_dbh->dbh_pid != getpid())
    {
        dbd_ix_db_seterror746(imp_dbh, "Child process cannot use database handle created in parent");
        return(0);
    }

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
static int
dbd_ix_begin(imp_dbh_t *dbh)
{
    int rc = 1;

    /* Bryan Castillo: allow work to be done w/o replication */
    if (dbh->no_replication)
        EXEC SQL BEGIN WORK WITHOUT REPLICATION;
    else
        EXEC SQL BEGIN WORK;

    dbd_ix_sqlcode(dbh);
    if (sqlca.sqlcode < 0)
        rc = 0;
    else
    {
        dbd_ix_debug(3, "%s: BEGIN WORK%s\n", dbd_ix_module(),
            (dbh->no_replication ? " WITHOUT REPLICATION" : ""));
        dbh->is_txactive = True;
    }
    return rc;
}

/* Internal implementation of COMMIT WORK */
/* Assumes correct connection is already set */
static int
dbd_ix_commit(imp_dbh_t *dbh)
{
    int rc = 1;

    EXEC SQL COMMIT WORK;
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
static int
dbd_ix_rollback(imp_dbh_t *dbh)
{
    int rc = 1;

    EXEC SQL ROLLBACK WORK;
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
    static const char function[] = "dbd_ix_db_commit";
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
            {
                dbd_ix_debug(1, "%s - AUTOCOMMIT Off => BEGIN WORK\n", function);
                rc = dbd_ix_begin(imp_dbh);
            }
        }
    }
    return rc;
}

/* External interface for ROLLBACK WORK */
int
dbd_ix_db_rollback(SV *dbh, imp_dbh_t *imp_dbh)
{
    static const char function[] = "dbd_ix_db_rollback";
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
            {
                dbd_ix_debug(1, "%s - AUTOCOMMIT Off => BEGIN WORK\n", function);
                rc = dbd_ix_begin(imp_dbh);
            }
        }
    }
    return rc;
}

/* Do nothing -- for use by cleanup code */
static void
noop(void *data)
{
}

/* Close a connection, destroying any dependent statements */
int
dbd_ix_db_disconnect(SV *dbh, imp_dbh_t *imp_dbh)
{
    static const char function[] = "dbd_ix_db_disconnect";
    dTHR;
    D_imp_drh_from_dbh;

    dbd_ix_enter(function);

    if (dbd_db_setconnection(imp_dbh) == 0)
    {
        dbd_ix_savesqlca(imp_dbh);
        dbd_ix_debug(1, "%s -- set connection failed", function);
        dbd_ix_exit(function);
        return(0);
    }

    dbd_ix_debug(1, "%s -- delete statements\n", function);
    dbd_ix_link_delchain(&imp_dbh->head, dbd_st_destroyer);
    dbd_ix_debug(1, "%s -- statements deleted\n", function);

    /* Rollback transaction before disconnecting */
    if (imp_dbh->is_loggeddb == True && imp_dbh->is_txactive == True)
        (void)dbd_ix_rollback(imp_dbh);

    dbd_ix_disconnect(imp_dbh->nm_connection);
    SvREFCNT_dec(imp_dbh->database);

    dbd_ix_sqlcode(imp_dbh);
    imp_dbh->is_connected = False;

    /* We assume that disconnect will always work       */
    /* since most errors imply already disconnected.    */
    DBIc_ACTIVE_off(imp_dbh);

    /* Record loss of connection in driver block */
    imp_drh->n_connections--;
    imp_drh->current_connection = 0;
    assert(imp_drh->n_connections >= 0);
    dbd_ix_link_delete(&imp_dbh->chain, noop);

    /* We don't free imp_dbh since a reference still exists  */
    /* The DESTROY method is the only one to 'free' memory.  */
    dbd_ix_exit(function);
    return 1;
}

void
dbd_ix_db_destroy(SV *dbh, imp_dbh_t *imp_dbh)
{
    static const char function[] = "dbd_ix_db_destroy";
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
static void
new_statement(imp_dbh_t *imp_dbh, imp_sth_t *imp_sth)
{
    static long     cursor_num = 0;

    sprintf(imp_sth->nm_stmnt,  "p_%09ld", cursor_num);
    sprintf(imp_sth->nm_cursor, "c_%09ld", cursor_num);
    sprintf(imp_sth->nm_obind,  "d_%09ld", cursor_num);
    sprintf(imp_sth->nm_ibind,  "b_%09ld", cursor_num);
    imp_sth->dbh      = imp_dbh;
    imp_sth->st_state = Unused;
    imp_sth->st_type  = 0;
    imp_sth->st_text  = 0;
    imp_sth->n_iblobs = 0;
    imp_sth->n_oblobs = 0;
    imp_sth->n_icols  = 0;
    imp_sth->n_rows   = 0;
    imp_sth->n_ocols  = 0;
    imp_sth->n_iudts  = 0;
    imp_sth->n_oudts  = 0;
    imp_sth->a_iudts  = 0;
    imp_sth->a_oudts  = 0;
    imp_sth->n_lvcsz  = 0;
    imp_sth->a_lvcsz  = 0;
    imp_sth->is_holdcursor   = False;
    imp_sth->is_scrollcursor = False;
    dbd_ix_link_add(&imp_dbh->head, &imp_sth->chain);
    imp_sth->chain.data = (void *)imp_sth;
    cursor_num++;
    /* Cleanup required for statement chain in imp_dbh */
    DBIc_on(imp_sth, DBIcf_IMPSET);
}

/* Close cursor */
static int
dbd_ix_close(imp_sth_t *imp_sth)
{
    static const char function[] = "dbd_ix_close";
    EXEC SQL BEGIN DECLARE SECTION;
    char           *nm_cursor = imp_sth->nm_cursor;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);

    assert(imp_sth->st_state == Opened);
    if (imp_sth->st_state == Opened)
    {
        EXEC SQL CLOSE :nm_cursor;
        dbd_ix_sqlcode(imp_sth->dbh);
        imp_sth->st_state = Declared;
        if (sqlca.sqlcode < 0)
        {
            dbd_ix_exit(function);
            return 0;
        }
    }
    dbd_ix_exit(function);
    return 1;
}

/* Release a complete SQL DESCRIPTOR, including any blobs */
static void dbd_ix_st_deallocate(char *p_name, int nblobs, int ncols)
{
    static const char function[] = "dbd_ix_st_deallocate";
    EXEC SQL BEGIN DECLARE SECTION;
    char *name = p_name;
    EXEC SQL END DECLARE SECTION;

    if (ncols > 0)
    {
        dbd_ix_debug(3, "%s() DEALLOCATE DESCRIPTOR %s\n", function, name);
        EXEC SQL DEALLOCATE DESCRIPTOR :name;
        if (sqlca.sqlcode != 0)
            dbd_ix_debug(0, "%s() - DEALLOCATE DESCRIPTOR failed %ld\n", function, sqlca.sqlcode);
    }
}

static void
free_udts(void **v_udts, int n_udts)
{
    int i;
    assert(v_udts != 0 && n_udts > 0);
    for (i = 0; i < n_udts; i++)
    {
        assert(v_udts[i] != 0);
        ifx_var_dealloc(&v_udts[i]);
    }
    free(v_udts);
}

/* Release all database and allocated resources for statement */
static void
del_statement(imp_sth_t *imp_sth)
{
    static const char function[] = "del_statement";
    EXEC SQL BEGIN DECLARE SECTION;
    char           *name;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_debug(3, "\t-->> %s() 0x%08X\n", function, (long)imp_sth);

    if (dbd_db_setconnection(imp_sth->dbh) == 0)
    {
        dbd_ix_savesqlca(imp_sth->dbh);
        return;
    }

    switch (imp_sth->st_state)
    {
    case NoMoreData:
        dbd_ix_debug(5, "\t---- %s() state %s\n", function, "NoMoreData");
        /* FALLTHROUGH */

    case Opened:
        dbd_ix_debug(5, "\t---- %s() state %s\n", function, "Opened");
        name = imp_sth->nm_cursor;
        EXEC SQL CLOSE :name;
        dbd_ix_debug(3, "\t---- %s() CLOSE cursor %s\n", function, name);
        /* FALLTHROUGH */

    case Declared:
        dbd_ix_debug(5, "\t---- %s() state %s\n", function, "Declared");
        name = imp_sth->nm_cursor;
        EXEC SQL FREE :name;
        dbd_ix_debug(3, "\t---- %s() FREE cursor %s\n", function, name);
        /* FALLTHROUGH */

    case Described:
        dbd_ix_debug(5, "\t---- %s() state %s\n", function, "Described");
        /* FALLTHROUGH */

    case Allocated:
        dbd_ix_debug(5, "\t---- %s() state %s\n", function, "Allocated");
        dbd_ix_st_deallocate(imp_sth->nm_obind, imp_sth->n_oblobs, imp_sth->n_ocols);
        /* FALLTHROUGH */

    case Prepared:
        dbd_ix_debug(5, "\t---- %s() state %s\n", function, "Prepared");
        dbd_ix_st_deallocate(imp_sth->nm_ibind, imp_sth->n_iblobs, imp_sth->n_icols);
        name = imp_sth->nm_stmnt;
        EXEC SQL FREE :name;
        dbd_ix_debug(3, "\t---- %s() FREE statement %s\n", function, name);
        /* FALLTHROUGH */

    case Unused:
        dbd_ix_debug(5, "\t---- %s() state %s\n", function, "Unused");
        break;
    }

    if (imp_sth->n_lvcsz > 0)
        free(imp_sth->a_lvcsz);
    if (imp_sth->n_iudts > 0)
        free_udts(imp_sth->a_iudts, imp_sth->n_iudts);
    if (imp_sth->n_oudts > 0)
        free_udts(imp_sth->a_oudts, imp_sth->n_oudts);

    if (imp_sth->st_text != 0)
        SvREFCNT_dec(imp_sth->st_text);
    imp_sth->st_state = Unused;
    dbd_ix_link_delete(&imp_sth->chain, noop);
    DBIc_off(imp_sth, DBIcf_IMPSET);
    dbd_ix_debug(3, "\t<<-- %s() 0x%08X\n", function, (long)imp_sth);
}

/* Create the input descriptor for the specified number of items */
static int
dbd_ix_setbindnum(imp_sth_t *imp_sth, int items)
{
    static const char function[] = "dbd_ix_setbindnum";
    EXEC SQL BEGIN DECLARE SECTION;
    int  bind_size = items;
    char           *nm_ibind = imp_sth->nm_ibind;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);

    if (dbd_db_setconnection(imp_sth->dbh) == 0)
    {
        dbd_ix_exit(function);
        return 0;
    }

    if (items > imp_sth->n_icols)
    {
        if (imp_sth->n_icols > 0)
        {
            dbd_ix_debug(3, "---- %s() DEALLOCATE descriptor %s\n", function, nm_ibind);
            EXEC SQL DEALLOCATE DESCRIPTOR :nm_ibind;
            dbd_ix_sqlcode(imp_sth->dbh);
            imp_sth->n_icols = 0;
            if (sqlca.sqlcode < 0)
            {
                dbd_ix_exit(function);
                return 0;
            }
        }
        dbd_ix_debug(3, "--- %s() ALLOCATE descriptor %s\n", function, nm_ibind);
        EXEC SQL ALLOCATE DESCRIPTOR :nm_ibind WITH MAX :bind_size;
        dbd_ix_sqlcode(imp_sth->dbh);
        if (sqlca.sqlcode < 0)
        {
            dbd_ix_exit(function);
            return 0;
        }
        imp_sth->n_icols = items;
    }
    dbd_ix_exit(function);
    return 1;
}

/* Convert machine long to INT8 - both 32-bit and 64-bit machines */
static void
dbd_ix_int8_to_ifx_int8(ifx_int8_t *i8val, long intvar)
{
    if (sizeof(long) == sizeof(int4))
        ifx_int8cvlong(intvar, i8val);
    else
    {
        i8val->sign = +1;   /* sign == 0 ==> NULL */
        if (intvar < 0)
        {
            i8val->sign = -1;
            intvar = -intvar;
        }
        i8val->data[0] = intvar & 0xFFFFFFFF;
        /* Avoid compiler warnings on 32-bit machines */
        intvar >>= 16;  /* First shift */
        intvar >>= 16;  /* Second shift */
        i8val->data[1] = intvar & 0x7FFFFFFF;
    }
}

/* Bind the value to input descriptor entry */
static int
dbd_ix_bindsv(imp_sth_t *imp_sth, int idx, int p_type, SV *val)
{
    static const char function[] = "dbd_ix_bindsv";
    int        rc = 1;
    STRLEN     len;
    EXEC SQL BEGIN DECLARE SECTION;
    char      *nm_ibind = imp_sth->nm_ibind;
    char      *string;
    long       intvar;
    double     numeric;
    int        length;
    int        index = idx;
    loc_t      blob;
    int        type = p_type;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);

    if ((rc = dbd_db_setconnection(imp_sth->dbh)) == 0)
    {
        dbd_ix_savesqlca(imp_sth->dbh);
        dbd_ix_exit(function);
        return(rc);
    }

    dbd_ix_debug(2, "\t---- %s() fld-indx = %3ld inp-type = %3ld\n",
                 function, (long)index, (long)type);
    if (type == SQLVCHAR)
    {
        /**
        ** SQLVCHAR is the default type.  See if there's any information
        ** available in the descriptor because of a described INSERT.
        */
        EXEC SQL GET DESCRIPTOR :nm_ibind VALUE :index :type = TYPE;
        /* If there is no info, work on the basis of the type in the SV */
        if (type == -1)
            type = p_type;
        dbd_ix_debug(2, "\t---- %s() GET DESC type = %ld\n", function, (long)type);
    }

    /**
    ** JL 2000-09-28:
    ** Don't sweat the types too hard (yet).  At the moment, if the
    ** specified type of the parameter is TEXT or BYTE, then we give it
    ** special attention.  Otherwise, we look at the Perl variable and
    ** see whether the value is null, an integer, a decimal or a string,
    ** and encode the SQL descriptor accordingly.  That means we largely
    ** ignore the specified type, too.
    ** What happens if you insert integer 12 into a DATETIME HOUR TO HOUR?
    ** When collection types etc are supported, we may need some more
    ** code in here.
    */
    if (type == SQLBYTES || type == SQLTEXT)
    {
        /* Trust that the user knows what they are up to! */
        blob_locate(&blob, BLOB_IN_MEMORY);
        if (!SvOK(val))
        {
            dbd_ix_debug(2, "\t---- %s -- null blob\n", function);
            blob.loc_indicator = -1;
            blob.loc_buffer = 0;
            blob.loc_bufsize = 0;
            blob.loc_size = 0;
        }
        else
        {
            dbd_ix_debug(2, "\t---- %s -- blob\n", function);
            blob.loc_buffer = SvPV(val, len);
            blob.loc_bufsize = len + 1;
            blob.loc_size = len;
        }
        EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index TYPE = :type, DATA = :blob;
    }
    else if (!SvOK(val))
    {
        /* It's a null! */
        dbd_ix_debug(2, "\t---- %s -- null\n", function);
        type = SQLCHAR;
        EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
                        TYPE = :type, LENGTH = 0, INDICATOR = -1;
    }
    else if (type == SQLINT8 || type == SQLSERIAL8)
    {
        /**
        ** JL 2003-07-01: partial fix for handling big INT8 fields for
        ** Steve Vornbrock <stevev@wamnet.com>.  Need to treat this as a
        ** string - in case it is out of range of INTEGER.
        */
        dbd_ix_debug(2, "\t---- %s -- INT8 or SERIAL8\n", function);
        type = SQLCHAR;
        string = SvPV(val, len);
        length = len + 1;
        EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
                        TYPE = :type, LENGTH = :length,
                        DATA = :string;
    }
#ifdef ESQLC_BIGINT
    else if (type == SQLINFXBIGINT || type == SQLBIGSERIAL)
    {
        dbd_ix_debug(2, "\t---- %s -- BIGINT or BIGSERIAL\n", function);
        type = SQLCHAR;
        string = SvPV(val, len);
        length = len + 1;
        EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
                        TYPE = :type, LENGTH = :length,
                        DATA = :string;
    }
#endif /* ESQLC_BIGINT */
    else if (SvIOK(val) && SvIOKp(val))
    {
        /*
        ** JL 2003-07-15: SvIOK() and SvNOK() fix problem with float to
        ** integer conversion for Darryl Priest
        ** <darryl.priest@piperrudnick.com>, a change in behaviour
        ** between Perl 5.005_03 and 5.8.0.
        **
        ** JL 2005-07-28: On 64-bit machines, Perl SV has 8-byte
        ** IV, but SQLINT is for 4-byte quantities.
        ** Found by JL and Sam Gentsch <sgentsch@intercall.com>,
        ** and by Darryl Priest <darryl.priest@dlapiper.com> and
        ** by Durga Pullakandam <durga.pullankandam@mci.com>.
        */
        dbd_ix_debug(2, "\t---- %s -- integer\n", function);
        intvar = SvIV(val);     /* intvar is a long - handles big values on 64-bit machines */
        if (intvar <= 0x7FFFFFFFL && intvar >= -0x7FFFFFFFL)
        {
            /* Value is valid 4-byte integer */
            type = SQLINT;
            EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
                            TYPE = :type, DATA = :intvar;
        }
        else
        {
            /* Changed to $ifdef from #ifdef SQLINT8 because of ESQL/C 7.24 issues */
            /* Bug found by Piotr Poloczek <poloczekp@interia.pl> on 2007-08-24. */
            /* Value is not a valid 4-byte integer */
            EXEC SQL BEGIN DECLARE SECTION;
            ifx_int8_t i8val;
            EXEC SQL END DECLARE SECTION;
            type = SQLINT8;
            /*
            ** JL 2005-07-27: ESQL/C does not support conversion of 8-byte
            ** (long or long long) values to ifx_int8_t?
            */
            dbd_ix_int8_to_ifx_int8(&i8val, intvar);
            EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
                            TYPE = :type, DATA = :i8val;
        }
    }
    else if (SvNOK(val) && SvNOKp(val))
    {
        dbd_ix_debug(2, "\t---- %s -- numeric\n", function);
        type = SQLFLOAT;
        numeric = SvNV(val);
        EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
                        TYPE = :type, DATA = :numeric;
    }
    else
    {
        dbd_ix_debug(2, "\t---- %s -- string\n", function);
        type = SQLCHAR;
        string = SvPV(val, len);
        length = len + 1;
        if (length == 1)
        {
            /*
            ** Handle zero length, non-null VARCHAR values, a bug
            ** reported by Vaclav Ovcik <vaclav.ovsik@i.cz> in 2005-05.
            ** JL 2007-06-11: Zero-length non-null strings insert
            ** correctly if type is SQLVARCHAR
            */
            type = SQLVCHAR;
            length = 0;
        }
        EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
                        TYPE = :type, LENGTH = :length,
                        DATA = :string;
    }
    dbd_ix_sqlcode(imp_sth->dbh);
    if (sqlca.sqlcode < 0)
    {
        rc = 0;
    }
    dbd_ix_exit(function);
    return(rc);
}

static int
count_byte_text(char *descname, int ncols)
{
    /*static const char function[] = "count_byte_text";*/
    EXEC SQL BEGIN DECLARE SECTION;
    char           *nm_obind = descname;
    int colno;
    int coltype;
    EXEC SQL END DECLARE SECTION;
    int nblobs = 0;

    for (colno = 1; colno <= ncols; colno++)
    {
        EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno :coltype = TYPE;

        /* dbd_ix_sqlcode(imp_sth->dbh); */
        if (coltype == SQLBYTES || coltype == SQLTEXT)
        {
            nblobs++;
        }
    }
    return(nblobs);
}

/* Process blobs (if any) */
static void
dbd_ix_blobs(imp_sth_t *imp_sth)
{
    static const char function[] = "dbd_ix_blobs";
    EXEC SQL BEGIN DECLARE SECTION;
    char           *nm_obind = imp_sth->nm_obind;
    loc_t           blob;
    int             colno;
    int coltype;
    EXEC SQL END DECLARE SECTION;
    int             n_ocols = imp_sth->n_ocols;

    dbd_ix_enter(function);
    imp_sth->n_oblobs = count_byte_text(nm_obind, n_ocols);
    dbd_ix_debug(5, "\t---- %s(): %ld BYTE/TEXT blobs\n", function, imp_sth->n_oblobs);
    if (imp_sth->n_oblobs == 0)
    {
        dbd_ix_exit(function);
        return;
    }

    /* Set blob location */
    if (blob_locate(&blob, imp_sth->blob_bind) != 0)
        croak("memory allocation error 3 in %s()\n", function);

    for (colno = 1; colno <= n_ocols; colno++)
    {
        EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno :coltype = TYPE;
        dbd_ix_sqlcode(imp_sth->dbh);
        if (coltype == SQLBYTES || coltype == SQLTEXT)
        {
            /* Tell ESQL/C how to handle this blob */
            EXEC SQL SET DESCRIPTOR :nm_obind VALUE :colno DATA = :blob;
            dbd_ix_sqlcode(imp_sth->dbh);
        }
    }
    dbd_ix_exit(function);
}

/*
** Workaround for CQ idsdb00247065: ESQL/C reporting error -1820 when
** reusing SQL DESCRIPTOR after reopening cursor
*/
static int
count_lvc(char *descname, int ncols)
{
    /*static const char function[] = "count_lvc";*/
    EXEC SQL BEGIN DECLARE SECTION;
    char *nm_obind = descname;
    int   colno;
    int   coltype;
    EXEC SQL END DECLARE SECTION;
    int n_lvc = 0;

    for (colno = 1; colno <= ncols; colno++)
    {
        EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno :coltype = TYPE;
        if (coltype == SQLLVARCHAR)
        {
            n_lvc++;
        }
    }
    return(n_lvc);
}

static int
dbd_ix_lvarchar(imp_sth_t *imp_sth)
{
    int nlvc;
    static const char function[] = "dbd_ix_lvarchar";
    EXEC SQL BEGIN DECLARE SECTION;
    char *nm_obind = imp_sth->nm_obind;
    int coltype;
    int colno;
    int collength;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);
    nlvc = count_lvc(nm_obind, imp_sth->n_ocols);

    if (nlvc > 0)
    {
        int i = 0;
        void *result = malloc(nlvc * sizeof(int));
        if (result == 0)
            die("%s: malloc() failed\n", function);

        imp_sth->n_lvcsz = nlvc;
        imp_sth->a_lvcsz = (int *)result;
        for (colno = 1; colno <= imp_sth->n_ocols; colno++)
        {
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno
                :coltype = TYPE, :collength = LENGTH;
            dbd_ix_sqlcode(imp_sth->dbh);
            if (coltype == SQLLVARCHAR)
            {
                imp_sth->a_lvcsz[i++] = collength;
            }
        }
        assert(i == nlvc);
    }
    dbd_ix_exit(function);
    return(nlvc);
}

static int
dbd_ix_reset_lvarchar_sizes(imp_sth_t *imp_sth)
{
    int nlvc = 0;
    static const char function[] = "dbd_ix_reset_lvarchar_sizes";
    EXEC SQL BEGIN DECLARE SECTION;
    char *nm_obind = imp_sth->nm_obind;
    int coltype;
    int colno;
    int collength;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);

    if (imp_sth->n_lvcsz > 0)
    {
        int i = 0;
        for (colno = 1; colno <= imp_sth->n_ocols; colno++)
        {
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno
                :coltype = TYPE, :collength = LENGTH;
            dbd_ix_sqlcode(imp_sth->dbh);
            if (coltype == SQLLVARCHAR)
            {
                imp_sth->a_lvcsz[i++] = collength;
                EXEC SQL SET DESCRIPTOR :nm_obind VALUE :colno
                    LENGTH = :collength;
            }
        }
        assert(i == imp_sth->n_lvcsz);
    }
    dbd_ix_exit(function);
    return(nlvc);
}

static int is_lvarcharptr_type(int coltype)
{
    if (coltype == SQLLVARCHAR)
        return(0);
    return(ISCOMPLEXTYPE(coltype) || ISUDTTYPE(coltype) || ISDISTINCTTYPE(coltype));
}

static int
count_udts(char *descname, int ncols)
{
    /*static const char function[] = "count_udts";*/
    EXEC SQL BEGIN DECLARE SECTION;
    char           *nm_obind = descname;
    int colno;
    int coltype;
    EXEC SQL END DECLARE SECTION;
    int n_udts = 0;

    for (colno = 1; colno <= ncols; colno++)
    {
        EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno :coltype = TYPE;

        /* dbd_ix_sqlcode(imp_sth->dbh); */
        if (is_lvarcharptr_type(coltype))
        {
            n_udts++;
        }
    }
    return(n_udts);
}

/* set the cast types for output UDTs, returning number of UDT columns */
static int
dbd_ix_udts(imp_sth_t *imp_sth)
{
    int nudts;
    static const char function[] = "dbd_ix_udts";
    EXEC SQL BEGIN DECLARE SECTION;
    char *nm_obind = imp_sth->nm_obind;
    int coltype;
    int colno;
    lvarchar *lvcp;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);
    nudts = count_udts(nm_obind, imp_sth->n_ocols);

    if (nudts > 0)
    {
        int i = 0;
        void *result = malloc(nudts * sizeof(void *));
        if (result == 0)
            die("%s: malloc() failed\n", function);

        imp_sth->n_oudts = nudts;
        imp_sth->a_oudts = (void **)result;
        for (colno = 1; colno <= imp_sth->n_ocols; colno++)
        {
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno :coltype = TYPE;
            dbd_ix_sqlcode(imp_sth->dbh);
            if (is_lvarcharptr_type(coltype))
            {
                /**
                ** MYK 2000-01-19 (ESQL/C 9.30).
                ** For the reasons unknown SQLCHAR is the only one that
                ** works.  Also, the manuals say LENGTH=0 sets to the actual
                ** value length.  In fact it just causes FETCH to fail.
                **
                ** JL 2007-08-24
                ** Careful scrutiny of the ESQL/C manual (chapter 16 in
                ** the ESQL/C 2.90 edition) shows that CLVCHARPTRTYPE
                ** (124) should work.  Some experimentation shows that
                ** ESQL/C distinguishes between host variables declared
                ** as 'lvarchar x[50];' and 'lvarchar *p;', declaring
                ** the first as an array of 50 char, and the second as a
                ** void pointer.  When messing with the pointer form,
                ** the generated C code calls ifx_var_init() to
                ** initialize the pointer.  Upgrade the imp_sth structure
                ** to include the fields n_iudts and n_oudts (number of
                ** input and output UDTs respectively), and arrays
                ** a_iudts and a_oudts to contain sets of pointers.
                ** The input side is there for symmetry rather than
                ** because it is used as yet.  This code allocates the
                ** array and initializes each element in turn.  The
                ** cleanup code has to release the variables with
                ** ifx_var_dealloc(), and then the arrays allocated
                ** above.
                */
                coltype = CLVCHARPTRTYPE;
                lvcp = 0;
                dbd_ix_debug(1, "\t---- %s: SET DESCRIPTOR on column number %d\n", function, colno);
                EXEC SQL SET DESCRIPTOR :nm_obind VALUE :colno DATA = :lvcp, TYPE = :coltype;
                dbd_ix_sqlcode(imp_sth->dbh);
                assert(lvcp != 0);
                imp_sth->a_oudts[i++] = lvcp;
            }
        }
        assert(i == nudts);
    }
    dbd_ix_exit(function);
    return(nudts);
}

/* Declare cursor for SELECT, EXECUTE PROCEDURE, or INSERT */
static int
dbd_ix_declare(imp_sth_t *imp_sth)
{
    static const char function[] = "dbd_ix_declare";
    EXEC SQL BEGIN DECLARE SECTION;
    char           *nm_stmnt = imp_sth->nm_stmnt;
    char           *nm_cursor = imp_sth->nm_cursor;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);
#ifdef SQ_EXECPROC
    assert(imp_sth->st_type == SQ_SELECT || imp_sth->st_type == SQ_INSERT ||
           imp_sth->st_type == SQ_EXECPROC);
#else
    assert(imp_sth->st_type == SQ_SELECT || imp_sth->st_type == SQ_INSERT);
#endif /* SQ_EXECPROC */
    assert(imp_sth->st_state == Described);
    dbd_ix_blobs(imp_sth);
    dbd_ix_lvarchar(imp_sth);    /* CQ idsdb00247065 */
    dbd_ix_udts(imp_sth);

    /* BR 1999-08-30: Hold Cursor -- Not necessarily correct... */
    if (imp_sth->dbh->is_modeansi == True &&
        DBI_AutoCommit(imp_sth->dbh) == True)
    {
        /* XPS 8.11 does not support hold cursors (Robert Wyrick <rob@wyrick.org>) */
        /* Note that the ESQL/C does support hold cursors. */
        /* The issue is whether the server does. */
        /* Assume 8.00 through 8.29 does not do so either.  8.30 may support them. */
        if (imp_sth->dbh->srvr_vrsn >= 800 && imp_sth->dbh->srvr_vrsn < 830)
            imp_sth->is_holdcursor = False;
        else
            imp_sth->is_holdcursor = True;
    }

#define print_tf(a) (a == True ? "True" : "False")
    dbd_ix_debug(3, "\t---- is_holdcursor   = %s", print_tf(imp_sth->is_holdcursor));
    dbd_ix_debug(3, "\t---- is_scrollcursor = %s", print_tf(imp_sth->is_scrollcursor));
    dbd_ix_debug(3, "\t---- is_insertcursor = %s", print_tf(imp_sth->is_insertcursor));
#undef print_tf

    if (imp_sth->is_scrollcursor == True)
    {
        if (imp_sth->is_holdcursor == True)
        {
            EXEC SQL DECLARE :nm_cursor SCROLL CURSOR WITH HOLD FOR :nm_stmnt;
        }
        else
        {
            EXEC SQL DECLARE :nm_cursor SCROLL CURSOR FOR :nm_stmnt;
        }
    }
    else
    {
        if (imp_sth->is_insertcursor && imp_sth->dbh->is_loggeddb &&
            DBI_AutoCommit(imp_sth->dbh) == True)
        {
            warn("insert cursor ineffective with AutoCommit enabled");
        }
        if (imp_sth->is_holdcursor == True)
        {
            EXEC SQL DECLARE :nm_cursor CURSOR WITH HOLD FOR :nm_stmnt;
        }
        else
        {
            EXEC SQL DECLARE :nm_cursor CURSOR FOR :nm_stmnt;
        }
    }
    dbd_ix_sqlcode(imp_sth->dbh);
    if (sqlca.sqlcode < 0)
    {
        dbd_ix_exit(function);
        return 0;
    }
    imp_sth->st_state = Declared;
    dbd_ix_exit(function);
    return 1;
}

/*
** dbd_ix_preparse() -- based on dbd_preparse() in DBD::ODBC 0.15
**
** Count the placeholders (?) parameters in the statement.
**
** The main-stream version also edits the string (in situ because the
** output will never be longer than the input) and recognizes both :9 (9 =
** digit string) positional parameters and :a (a = alphanumeric identifier)
** named parameters and converts them to ?.  However, this Informix version
** does not handle these non-standard extensions because the :a notation
** causes problems with Informix's FROM dbase:table notation, and the :9
** notation causes problems with DATETIME and INTERVAL literals!
**
** The code handles single-quoted literals and double-quoted delimited
** identifiers and ANSI SQL "--.*\n" comments and Informix "{.*}" comments.
** Note that it does nothing with "#.*\n" Perl/Shell comments.  Also note
** that it does not handle ODBC-style extensions.  The shorthand notation
** for these is identical to an Informix {} comment; longhand notation
** looks like "--*(details*)--" without the quotes.
*/

static int
dbd_ix_preparse(char *statement)
{
    static const char function[] = "dbd_ix_preparse";
    char            end_quote = '\0';
    char           *src;
    char           *dst;
    int             idx = 0;
    int             style = 0;
    int             laststyle = 0;
    char            ch;

    dbd_ix_debug(4, "\t-->> %s::%s(): <<%s>>\n", dbd_ix_module(), function, statement);
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
        if (ch == '?')
        {
            /* X/Open standard   */
            *dst++ = '?';
            idx++;
            style = 3;
        }
        else
        {
            /* Perhaps ':=' PL/SQL construct or dbase:table in Informix */
            /* Or it could be :2 or :22 as part of a DATETIME/INTERVAL */
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
    dbd_ix_debug(4, "\t<<-- %s::%s(): %d placeholders\n", dbd_ix_module(), function, idx);
    return(idx);
}

static Boolean
dbd_ix_st_attrib(SV *attribs, const char *attr)
{
    Boolean rc = False;

    /* Modularized version of Bill Rothanburg <brothanb@fll-ro.dhl.com> code */
    /* To determine the setting of Hold and Scroll Cursor Attributes */
    if (attribs != NULL)
    {
        SV              **svpp;
        U32             len;

        len = strlen(attr);
        svpp = hv_fetch((HV *) SvRV(attribs), (char *)attr, len, 0);
        if (svpp != NULL)
        {
            rc = DBD_IX_BOOLEAN(SvTRUE(*svpp));
            dbd_ix_debug(1, "%s set to %ld\n", attr, (long)rc);
        }
    }
    return(rc);
}

/*
** Count the number of described items in the given statement.
**
** JL 2000-02-08: This is a ridiculous way to have to do things, but it
** works with ESQL/C 9.30.UC1, and there doesn't seem to be a way to
** find out how big a descriptor to allocate without trying and failing!
**
** Note that there is a chance that the free(u) will cause the Sqlda
** structure to be double-released in some early 5.0x versions of
** ESQL/C.  However, precise information about which versions are
** afflicted is not available, so we press ahead...
**
** NB: if we ever switch from SQL DESCRIPTORs to Sqlda structures, then
** this kludge becomes unnecessary, of course.  The only reason for
** retaining SQL DESCRIPTORs at the moment is the NULLABLE attribute --
** the Sqlda structure does not give this information.
*/
static int
count_descriptors(char *stmt)
{
    Sqlda   *u;
    int      n = 256;
    EXEC SQL BEGIN DECLARE SECTION;
    char *nm_stmt = stmt;
    EXEC SQL END DECLARE SECTION;

    EXEC SQL DESCRIBE :nm_stmt INTO u;
    if (sqlca.sqlcode >= 0)
    {
        n = u->sqld;
#if defined(PERL_OBJECT) && \
    (ESQLC_EFFVERSION >= 720 || (ESQLC_EFFVERSION >= 501 && ESQLC_EFFVERSION < 600))
        /**
        ** JL 2000-02-29:
        ** Using SqlFreeMem() is the recommended fix for PTS Bug B83831
        ** on Win32 platforms.  See the notes in the file Notes/nt for
        ** more details about this.  SqlFreeMem() is not necessarily
        ** documented, but it should be.  Apparently, SqlFreeMem() was
        ** available in 5.01.WC1, so it should be available in all 5.x
        ** versions.  It was reinstated in 7.20.TD1; the conditions
        ** above document this.  It was only ever available on Win32
        ** (Windows NT) and never on Unix.  The PERL_OBJECT define is
        ** associated with ActiveState's Active Perl on NT and only
        ** optionally with a manual build of Perl on NT.  If there is a
        ** better platform indicator, we can change that part of the
        ** condition.  Note that even if the DBD::Informix code only
        ** uses Sqlda structures, the NT platform will probably use
        ** SqlFreeMem().  You may run into crashes if SqlFreeMem() is
        ** not available for your version of ESQL/C on NT.
        */
        SqlFreeMem(u, SQLDA_FREE);
#else
        free(u);
#endif /* PERL_OBJECT && ESQLC_EFFVERSION */
    }
    dbd_ix_debug(1, "\t---- number of described fields %ld\n", (long)n);
    return(n);
}

int
dbd_ix_st_prepare(SV *sth, imp_sth_t *imp_sth, char *stmt, SV *attribs)
{
    static const char function[] = "dbd_ix_st_prepare";
    D_imp_dbh_from_sth;
    int  rc = 1;
    static const char ix_hc[] = "ix_CursorWithHold";
    static const char ix_sc[] = "ix_ScrollCursor";
    static const char ix_ic[] = "ix_InsertCursor";
    EXEC SQL BEGIN DECLARE SECTION;
    char           *statement = stmt;
    int             desc_count;
    char           *nm_stmnt;
    char           *nm_obind;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);

    if (stmt == 0 || *stmt == '\0')
    {
        /* No valid statement text */
        /* -402: Address of a host variable is NULL. */
        dbd_ix_db_seterror(imp_dbh, -402);
        dbd_ix_savesqlca(imp_dbh);
        dbd_ix_exit(function);
        return(0);
    }

    if ((rc = dbd_db_setconnection(imp_dbh)) == 0)
    {
        dbd_ix_savesqlca(imp_dbh);
        dbd_ix_exit(function);
        return(rc);
    }

    new_statement(imp_dbh, imp_sth);
    nm_stmnt = imp_sth->nm_stmnt;
    nm_obind = imp_sth->nm_obind;
    imp_sth->st_text = newSVpv(stmt, 0);

    /* Bill R. Code to allow the setting of Hold and Scroll Cursor Attribs */
    if (attribs == NULL)
        dbd_ix_debug(4, "\t---- %s - no attribs set", function);
    else
    {
        imp_sth->is_holdcursor = dbd_ix_st_attrib(attribs, ix_hc);
        imp_sth->is_scrollcursor = dbd_ix_st_attrib(attribs, ix_sc);
        imp_sth->is_insertcursor = dbd_ix_st_attrib(attribs, ix_ic);
    }

    dbd_ix_debug(4, "\t---- %s <<%s>>\n", function, statement);
    EXEC SQL PREPARE :nm_stmnt FROM :statement;
    dbd_ix_savesqlca(imp_dbh);
    dbd_ix_sqlcode(imp_dbh);
    if (sqlca.sqlcode < 0)
    {
        del_statement(imp_sth);
        dbd_ix_exit(function);
        return 0;
    }
    imp_sth->st_state = Prepared;

    /* Record the number of input parameters in the statement */
    DBIc_NUM_PARAMS(imp_sth) = dbd_ix_preparse(statement);

    /* Allocate space for that many parameters */
    if (dbd_ix_setbindnum(imp_sth, DBIc_NUM_PARAMS(imp_sth)) == 0)
    {
        del_statement(imp_sth);
        dbd_ix_exit(function);
        return 0;
    }

    desc_count = count_descriptors(nm_stmnt);
    /* SQL DESCRIPTORS must have WITH MAX of at least one (error -470) */
    if (desc_count == 0)
        desc_count = 1;
    dbd_ix_debug(3, "\t---- %s() ALLOCATE descriptor %s\n", function, nm_obind);
    EXEC SQL ALLOCATE DESCRIPTOR :nm_obind WITH MAX :desc_count;
    dbd_ix_sqlcode(imp_dbh);
    if (sqlca.sqlcode < 0)
    {
        del_statement(imp_sth);
        dbd_ix_exit(function);
        return 0;
    }
    imp_sth->st_state = Allocated;

    EXEC SQL DESCRIBE :nm_stmnt USING SQL DESCRIPTOR :nm_obind;
    dbd_ix_sqlcode(imp_dbh);
    if (sqlca.sqlcode < 0)
    {
        del_statement(imp_sth);
        dbd_ix_exit(function);
        return 0;
    }
    imp_sth->st_state = Described;
    imp_sth->st_type = sqlca.sqlcode;
    if (imp_sth->st_type == 0)
        imp_sth->st_type = SQ_SELECT;

    EXEC SQL GET DESCRIPTOR :nm_obind :desc_count = COUNT;
    dbd_ix_sqlcode(imp_dbh);
    if (sqlca.sqlcode < 0)
    {
        del_statement(imp_sth);
        dbd_ix_exit(function);
        return 0;
    }

    /* Record the number of fields in the cursor for DBI and DBD::Informix  */
    DBIc_NUM_FIELDS(imp_sth) = imp_sth->n_ocols = desc_count;

    /* Cannot create an INSERT cursor except on an insert statement */
    if (imp_sth->is_insertcursor == True && imp_sth->st_type != SQ_INSERT)
    {
        /* -481: Invalid statement name or statement was not prepared */
        /* Generated by 9.21.UC1 in response to declare cursor on update stmt */
        sqlca.sqlcode = -481;
        dbd_ix_sqlcode(imp_dbh);
        del_statement(imp_sth);
        dbd_ix_exit(function);
        return(0);
    }

    /**
    ** Only non-cursory statements need an output descriptor.
    ** Only cursory statements need a cursor declared for them.
    ** INSERT may yield an input descriptor (which will appear to be the
    ** output descriptor, such being the wonders of Informix).
    ** UPDATE and DELETE (and, indeed, INSERT, SELECT and EXECUTE
    ** PROCEDURE) statements would benefit from having a description of
    ** the input parameters, but this is not available.  SQL-92 defines
    ** DESCRIBE INPUT and DESCRIBE OUTPUT, but (as of 2000-08-01)
    ** Informix does not implement DESCRIBE INPUT.
    */
    if (imp_sth->st_type == SQ_SELECT)
        rc = dbd_ix_declare(imp_sth);
#ifdef SQ_EXECPROC  /* Defined for servers 5.00 and later, except perhaps 8.[012]x XPS */
    else if (imp_sth->st_type == SQ_EXECPROC && desc_count > 0)
        rc = dbd_ix_declare(imp_sth);
#endif  /* SQ_EXECPROC */
    else if (imp_sth->st_type == SQ_INSERT && desc_count > 0)
    {
        int nudts = dbd_ix_udts(imp_sth);

        dbd_ix_blobs(imp_sth);
        if (imp_sth->n_oblobs > 0 || nudts > 0)
        {
            /**
            ** Switch the nm_obind and nm_ibind names so that when
            ** dbd_ix_bindsv() is at work, it has an already populated SQL
            ** descriptor to work with, that already has the blobs set up
            ** correctly.
            */
            Name tmpname;
            int  t1;
            void **t2;
            dbd_ix_debug(3, "%s() switch descriptor names: old ibind %s\n", function, imp_sth->nm_ibind);
            dbd_ix_debug(3, "%s() switch descriptor names: old obind %s\n", function, imp_sth->nm_obind);
            strcpy(tmpname, imp_sth->nm_ibind);
            strcpy(imp_sth->nm_ibind, imp_sth->nm_obind);
            strcpy(imp_sth->nm_obind, tmpname);
            /* Switch lists of UDTs, too - need a structure! */
            t1 = imp_sth->n_iudts;
            imp_sth->n_iudts = imp_sth->n_oudts;
            imp_sth->n_oudts = t1;
            t2 = imp_sth->a_iudts;
            imp_sth->a_iudts = imp_sth->a_oudts;
            imp_sth->a_oudts = t2;
            dbd_ix_debug(3, "%s() switch descriptor names: new ibind %s\n", function, imp_sth->nm_ibind);
            dbd_ix_debug(3, "%s() switch descriptor names: new obind %s\n", function, imp_sth->nm_obind);
            imp_sth->n_icols = desc_count;
        }
        rc = 1;
        if (imp_sth->is_insertcursor == True)
            rc = dbd_ix_declare(imp_sth);
    }
    else
    {
        /**
        ** JL 2000-08-09:
        ** The IDS 7.30 and later servers nearly support describe for
        ** UPDATE.  However, it requires a special server configuration.
        ** Worse, the information returned by DESCRIBE is not usable.
        ** Bug B111987: DESCRIBE ON UPDATE STATEMENT GIVES INADEQUATE
        ** (AND UNUSABLE) INFORMATION.  The short description starts:
        ** [Summary: the ability to DESCRIBE the input parameters of an
        ** UPDATE might as well not exist -- it cannot be used in real
        ** life ESQL/C programs.]
        **
        ** The only reliable thing to do with the description of the
        ** input parameters to an UPDATE statement is to ignore it.
        */
        dbd_ix_debug(3, "\t---- %s() DEALLOCATE DESCRIPTOR %s\n", function, nm_obind);
        EXEC SQL DEALLOCATE DESCRIPTOR :nm_obind;
        imp_sth->st_state = Prepared;
        rc = 1;
    }

    dbd_ix_debug(2, "\t---- %s imp_sth->n_ocols: %d\n", function, imp_sth->n_ocols);

    dbd_ix_exit(function);
    return rc;
}

/* CLOSE cursor */
int
dbd_ix_st_finish(SV *sth, imp_sth_t *imp_sth, int gd_flag)
{
    static const char function[] = "dbd_ix_st_finish";
    dTHR;
    int rc;

    dbd_ix_enter(function);

    if ((rc = dbd_db_setconnection(imp_sth->dbh)) == 0)
    {
        dbd_ix_savesqlca(imp_sth->dbh);
    }
    else
    {
        if (imp_sth->st_state == Opened)
            rc = dbd_ix_close(imp_sth);
        else if (imp_sth->st_state == NoMoreData)
            imp_sth->st_state = Declared;
        else
            rc = 0;
        DBIc_ACTIVE_off(imp_sth);
    }

    dbd_ix_exit(function);
    return rc;
}

/* Free up resources used by the cursor or statement */
void
dbd_ix_st_destroy(SV *sth, imp_sth_t *imp_sth)
{
    static const char function[] = "dbd_ix_st_destroy";
    dbd_ix_enter(function);
    del_statement(imp_sth);
    dbd_ix_exit(function);
}

/* Convert DECIMAL to convenient string */
/* Patches problems with Informix conversion routines in pre-7.10 versions */
/* Don't forget that decimals are stored in a base-100 notation */
#if ESQLC_EFFVERSION < 710
static char *
decgen(dec_t *val, int collen)
{
    static char buffer[170];
    char *str;
    int dp = PRECDEC(collen);   /* Decimal places */
    int sf = PRECTOT(collen);   /* Significant digits */

    if (dp == 0xFF)
    {
        /* Floating point decimal */
        dec_sci(val, sf, 0, buffer, sizeof(buffer));
    }
    else
    {
        /* Fixed point decimal */
        dec_fix(val, dp, 0, buffer, sizeof(buffer));
    }
    str = buffer;
    while (*str == ' ')
        str++;
    /* Chop trailing blanks */
    str[byleng(str, strlen(str))] = '\0';
    return str;
}

#else

static char *
decgen(dec_t *val, int collen)
{
    static char buffer[170];
    char *str;
    int dp = PRECDEC(collen);   /* Decimal places */

    if (dp == 0xFF)
        dp = -1;
    dectoasc(val, buffer, sizeof(buffer), dp);
    str = buffer;
    while (*str == ' ')
        str++;
    /* Chop trailing blanks */
    str[byleng(str, strlen(str))] = '\0';
    return str;
}

#endif /* ESQLC_EFFVERSION */

/*
** Fetch a single row of data.
**
** Note the use of 'varchar' variables.  Given the sample code:
**
** #include <stdio.h>
** int main(int argc, char **argv)
** {
**     EXEC SQL BEGIN DECLARE SECTION;
**     char    cc[30];
**     varchar vc[30];
**     EXEC SQL END DECLARE SECTION;
**     EXEC SQL WHENEVER ERROR STOP;
**     EXEC SQL DATABASE Apt;
**     EXEC SQL CREATE TEMP TABLE Test(Col01 CHAR(20), Col02 VARCHAR(20));
**     EXEC SQL INSERT INTO Test VALUES("ABCDEFGHIJ     ", "ABCDEFGHIJ     ");
**     EXEC SQL SELECT Col01, Col01 INTO :cc, :vc FROM Test;
**     printf("Col01: cc = <<%s>>\n", cc);
**     printf("Col01: vc = <<%s>>\n", vc);
**     EXEC SQL SELECT Col02, Col02 INTO :cc, :vc FROM TestTable;
**     printf("Col02: cc = <<%s>>\n", cc);
**     printf("Col02: vc = <<%s>>\n", vc);
**     return(0);
** }
**
** The output looks like:
**      Col01: cc = <<ABCDEFGHIJ                   >>
**      Col01: vc = <<ABCDEFGHIJ          >>
**      Col02: cc = <<ABCDEFGHIJ                   >>
**      Col02: vc = <<ABCDEFGHIJ     >>
** Note that the data returned into 'cc' is blank padded to the length of
** the host variable, not the length of the database column, whereas 'vc'
** is blank-padded to the length of the database column for a CHAR column,
** and to the length of the inserted data in a VARCHAR column.
*/
AV *
dbd_ix_st_fetch(SV *sth, imp_sth_t *imp_sth)
{
    static const char function[] = "dbd_ix_st_fetch";
    AV  *av;
    EXEC SQL BEGIN DECLARE SECTION;
    char           *nm_cursor = imp_sth->nm_cursor;
    char           *nm_obind = imp_sth->nm_obind;
    varchar         coldata[256];
    long            coltype;
    long            collength;
    long            colind;
    char            colname[SQL_COLNAMELEN];
    int             index;
    char           *result;
    long            length;
    loc_t           blob;
    dec_t           decval;
    double          dblval;
    float           fltval;
    long            extypeid;
#ifdef SQLLVARCHAR
    lvarchar       *lvar = 0;
#endif
    EXEC SQL END DECLARE SECTION;
    D_imp_dbh_from_sth;
    int             is_char_type = 0; /* UTF8 patch */

    dbd_ix_enter(function);

    if (dbd_db_setconnection(imp_sth->dbh) == 0)
    {
        dbd_ix_savesqlca(imp_sth->dbh);
        dbd_ix_exit(function);
        return Nullav;
    }

    if (imp_sth->st_state == NoMoreData)
    {
        /* Simulate SQLNOTFOUND on a closed cursor */
        dbd_ix_debug(1, "%s: Simulate SQLNOTFOUND\n", function);
        sqlca.sqlcode = SQLNOTFOUND;
        dbd_ix_savesqlca(imp_sth->dbh);
        dbd_ix_sqlcode(imp_sth->dbh);
        dbd_ix_exit(function);
        return Nullav;
    }

    /* JL 2007-08-24: verified necessary - core dumps otherwise */
    dbd_ix_blobs(imp_sth); /* Fix -451 errors; Rich Jones <rich@annexia.org> */

    dbd_ix_debug(1, "\t---- %s: FETCH %s into %s\n", function, nm_cursor, nm_obind);
    EXEC SQL FETCH :nm_cursor USING SQL DESCRIPTOR :nm_obind;
    dbd_ix_savesqlca(imp_sth->dbh);
    dbd_ix_sqlcode(imp_sth->dbh);
    if (sqlca.sqlcode != 0)
    {
        if (sqlca.sqlcode != SQLNOTFOUND)
        {
            dbd_ix_debug(1, "\t---- %s -- FETCH failed\n", function);
        }
        else
        {
            /* Implicitly CLOSE cursor when no more data available */
            dbd_ix_close(imp_sth);
            imp_sth->st_state = NoMoreData;
            dbd_ix_debug(1, "\t---- %s -- SQLNOTFOUND\n", function);
        }
        dbd_ix_exit(function);
        return Nullav;
    }

    imp_sth->n_rows++;

    av = DBIc_DBISTATE(imp_sth)->get_fbav(imp_sth);

    for (index = 1; index <= imp_sth->n_ocols; index++)
    {
        SV             *sv = AvARRAY(av)[index - 1];
        EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                :coltype = TYPE, :collength = LENGTH,
                :colind = INDICATOR, :colname = NAME;
        dbd_ix_sqlcode(imp_sth->dbh);
        dbd_ix_debug(1, "\t---- %s colno %d: coltype = %d\n", function, index, coltype);

        is_char_type = 0;   /* UTF8 patch */

        if (colind != 0)
        {
            /* Data is null */
            result = coldata;
            length = 0;
            result[length] = '\0';
            sv_setsv(sv, &PL_sv_undef);
            /* warn("NULL Data: %d <<%s>>\n", length, result); */
        }
        else
        {
            switch (coltype)
            {
            case SQLINT:
            case SQLSERIAL:
            case SQLSMINT:
            case SQLDATE:
            case SQLDTIME:
            case SQLINTERVAL:
#ifdef SQLBOOL
            case SQLBOOL:
#endif  /* SQLBOOL */
#ifdef SQLSERIAL8
            case SQLSERIAL8:
#endif /* SQLSERIAL8 */
#ifdef SQLINT8
            case SQLINT8:
#endif /* SQLINT8 */
                /* These types always fit into a 256 character string */
                EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                        :coldata = DATA;
                result = coldata;
                length = byleng(result, strlen(result));
                result[length] = '\0';
                /* warn("Normal Data: %d <<%s>>\n", length, result); */
                break;

$ifdef ESQLC_BIGINT;
                /*
                ** BIGINT and BIGSERIAL: added to ESQL/C 3.50.xC1, GA
                ** May 2008, but the implementation there is buggy (CQ
                ** idsdb00159790).  So, until 3.50.xC1 is obsolete
                ** (circa 2015, I expect), this workaround and
                ** inconsistency has to remain in place.
                ** These types always fit into a 256 character string.
                */
            case SQLINFXBIGINT:
            case SQLBIGSERIAL:
                {
                $ bigint bi_value;
                EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                        :bi_value = DATA;
                /* That seems to be reliable - so now lets convert to string */
                /* biginttoasc() does not blank pad and does null terminate.  */
                biginttoasc(bi_value, coldata, sizeof(coldata), 10);
                result = coldata;
                length = strlen(result);
                }
                break;
$endif; /* ESQLC_BIGINT */

            case SQLFLOAT:
                EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                        :dblval = DATA;
                sprintf(coldata, "%.*g", DBL_DIG, dblval);
                result = coldata;
                length = strlen(result);
                /* warn("FLOAT Data: %d <<%s>>\n", length, result); */
                break;

            case SQLSMFLOAT:
                EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                        :fltval = DATA;
                sprintf(coldata, "%.*g", FLT_DIG, fltval);
                result = coldata;
                length = strlen(result);
                /* warn("SMALLFLOAT Data: %d <<%s>>\n", length, result); */
                break;

            case SQLDECIMAL:
            case SQLMONEY:
                /*
                ** Default formatting (in some versions of ESQL/C)
                ** assumes 2 decimal places -- wrong!
                */
                EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                        :decval = DATA;
                strcpy(coldata, decgen(&decval, collength));
                result = coldata;
                length = strlen(result);
                /* warn("Decimal Data: %d <<%s>>\n", length, result); */
                break;

#ifdef SQLUDTFIXED
            case SQLUDTFIXED:
                {
                    EXEC SQL BEGIN DECLARE SECTION;
                    fixed binary ifx_lo_t bclob;
                    EXEC SQL END DECLARE SECTION;
                    char            cb = 'C';
                    int             error = 0;

                    EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                                        :extypeid = EXTYPEID;

                    result = NULL;

                    switch (extypeid)
                    {
                    case XID_BLOB:
                        cb = 'B';
                        /* FALLTHROUGH */
                    case XID_CLOB:
                        {
                            int             LO_fd;
                            ifx_lo_stat_t  *LO_stat;
                            ifx_int8_t      size;
                            /* JL 2005-07-27: bloblen is a hack for 64-bit platforms */
                            /* ifx_int8tolong() takes an Informix int4* and not a long*! */
                            int4            bloblen;

                            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                                                :bclob = DATA;
                            LO_fd = ifx_lo_open(&bclob, LO_RDONLY, &error);
                            if (LO_fd == -1)
                                croak("Error opening %cLOB: %d", cb, error);
                            if (ifx_lo_stat(LO_fd, &LO_stat) < 0)
                                croak("Error getting %cLOB stat", cb);
                            if (ifx_lo_stat_size(LO_stat, &size) != 0)
                                croak("Error getting %cLOB size", cb);
                            if (ifx_int8tolong(&size, &bloblen) != 0)
                                croak("Error converting %cLOB size to length", cb);
                            length = bloblen;
                            if (ifx_lo_close(LO_fd) != 0)
                                croak("Error closing %cLOB", cb);
                            if (ifx_lo_to_buffer(&bclob, length, &result, &error) < 0)
                                croak("Error copying from %cLOB", cb);
                            break;
                        }
                    default:
                        length = 0;
                        result = coldata;
                        result[length] = '\0';
                        warn("IUS extended type (%ld) is not yet supported", extypeid);
                        break;
                    }
                    break;
                }
#endif /* SQLUDTFIXED */

#ifdef SQLLVARCHAR
            case CLVCHARPTRTYPE:
            case SQLLVARCHAR:
                if (ifx_var_flag(&lvar, 1) < 0)
                {
                    warn("Cannot set automatic memory for lvarchar");
                    result = coldata;
                    *result = '\0';
                    length = 0;
                    break;
                }
                EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                                    :lvar = DATA;
                result = (char *)ifx_var_getdata(&lvar);
                if ((length = ifx_var_getlen(&lvar)) < 0)
                {
                    warn("Length of lvarchar < 0");
                    length = 0;
                    result = coldata;
                    *result = '\0';
                }
                if (result == 0)
                {
                    /* Franky Wong <fwong@seattletimes.com> */
                    result = coldata;
                    *result = '\0';
                    length = 0;
                }
                /**
                ** FW 2002-05-12: Franky Wong <fwong@seattletimes.com>.
                ** JL 2002-12-06: Problem resurfaced because of faulty fix
                ** and reported by Mike Langen <mike.langen@tamedia.ch>.
                ** New test t/t93lvarchar.t should prevent reoccurrences.
                ** Empirical evidence on Solaris 2.6 with CSDK 2.10.UC1
                ** (ESQL/C 9.16.UC1) shows that the LVARCHAR variable is
                ** supplied with 2 NULs '\0' at the end, and both are
                ** counted in the length.  This is also found on Solaris
                ** 2.7 with CSDK 2.80.UC1 (ESQL/C 9.52.UC1).  The test
                ** below corrects for this.  I don't know whether this is
                ** really the way it should be according to the specs; the
                ** manuals do not cover such fine details.  Also, Solaris
                ** is bad (good?) at having NULs in convenient places; the
                ** fix may not work properly on other platforms.
                */
                if (length >= 2 && result[length-1] == '\0' && result[length-2] == '\0')
                    length -= 2;
                /*warn("LVARCHAR Data: %d <<%s>>\n", length, result);*/
                is_char_type = 1;   /* UTF8 patch */
                break;
#endif  /* SQLLVARCHAR */

            case SQLVCHAR:
#ifdef SQLNVCHAR
            case SQLNVCHAR:
#endif /* SQLNVCHAR */
                /* These types will always fit into a 256 character string */
                /* NB: VARCHAR strings always retain trailing blanks */
                EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                        :coldata = DATA;
                result = coldata;
                length = strlen(result);
                /* warn("VARCHAR Data: %d <<%s>>\n", length, result); */
                is_char_type = 1;   /* UTF8 patch */
                break;

            case SQLCHAR:
#ifdef SQLNCHAR
            case SQLNCHAR:
#endif /* SQLNCHAR */
                /**
                ** NB: CHAR strings have trailing blanks (which are added
                ** automatically by the database) removed by byleng() etc.
                */
                if (collength < 256)
                    result = coldata;
                else
                {
                    /* Placate bloody-minded MSVC and C++ compilers */
                    result = (char *)malloc(collength + 1);
                    if (result == 0)
                        die("%s::st::%s: malloc failed\n", function, dbd_ix_module());
                }
                EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                        :result = DATA;
                /* Conditionally chop trailing blanks */
                length = strlen(result);
                if (DBIc_is(imp_sth, DBIcf_ChopBlanks))
                    length = byleng(result, length);
                result[length] = '\0';
                /* warn("Character Data: %d <<%s>>\n", length, result); */
                is_char_type = 1;   /* UTF8 patch */
                break;

            case SQLTEXT:
            case SQLBYTES:
                /* warn("fetch: processing blob\n"); */
                blob_locate(&blob, BLOB_IN_MEMORY);
                EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
                        :blob = DATA;
                result = blob.loc_buffer;
                length = blob.loc_size;
                /* Warning - this data is not null-terminated! */
                /* warn("Blob Data: %d <<%*.*s>>\n", length, length, length,
                   result); */
                /* Data has been passed to Perl; mark it as such! */
                blob.loc_buffer = 0;
                blob_release(&blob, 0); /* 0 => do not delete files */
                break;

            default:
                colname[byleng(colname, strlen(colname))] = '\0';
                warn("%s - Unknown type code: %ld\n"
                      "(This type is probably IUS-specific and is not supported yet.)\n"
                      "coltype = %ld, collength = %ld, colind = %ld, colname = %s\n"
                        "-- value treated as NULL!\n",
                      function, coltype, coltype, collength, colind, colname);
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
            /* UTF8 patch */
            if(imp_dbh->enable_utf8 && is_char_type) {
                dbd_ix_debug(1, "\t---- UTF8 decode - colno %d: coltype = %d\n", index, coltype);
                sv_utf8_decode(sv);
            }

            if (result != coldata)
            {
                switch (coltype)
                {
#ifdef SQLLVARCHAR
                case CLVCHARPTRTYPE:
                case SQLLVARCHAR:
                    if (ifx_var_freevar(&lvar) < 0)
                        warn("Having problems freeing lvarchar");
                    break;
#endif  /* SQLLVARCHAR */
                case SQLBYTES:
                case SQLTEXT:
                    break;
                default:
                    free(result);
                    break;
                }
            }
        }
    }
    dbd_ix_exit(function);
    return(av);
}

/* Open a cursor */
static int
dbd_ix_open(imp_sth_t *imp_sth)
{
    static const char function[] = "dbd_ix_open";
    EXEC SQL BEGIN DECLARE SECTION;
    char           *nm_cursor = imp_sth->nm_cursor;
    char           *nm_ibind = imp_sth->nm_ibind;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);
    assert(imp_sth->st_state == Declared || imp_sth->st_state == Opened ||
            imp_sth->st_state == NoMoreData);
    /* Close currently open cursors - MODE ANSI databases give error otherwise */
    if (imp_sth->st_state == Opened)
    {
        dbd_ix_close(imp_sth);
        if (sqlca.sqlcode < 0)
        {
            dbd_ix_exit(function);
            return 0;
        }
    }
    assert(imp_sth->st_state == Declared || imp_sth->st_state == NoMoreData);

    if ((imp_sth->st_type != SQ_INSERT) && (imp_sth->n_icols > 0) )
        EXEC SQL OPEN :nm_cursor USING SQL DESCRIPTOR :nm_ibind;
    else
        EXEC SQL OPEN :nm_cursor;
    dbd_ix_sqlcode(imp_sth->dbh);
    dbd_ix_savesqlca(imp_sth->dbh);
    if (sqlca.sqlcode < 0)
    {
        dbd_ix_exit(function);
        return 0;
    }
    dbd_ix_reset_lvarchar_sizes(imp_sth);
    imp_sth->st_state = Opened;
    if (imp_sth->dbh->is_modeansi == True)
        imp_sth->dbh->is_txactive = True;
    imp_sth->n_rows = 0;
    dbd_ix_exit(function);
    return 1;
}

/* Parse statement for name of database -- what a pain! */
static void
dbd_ix_setdbname(const char *kw1, const char *kw2, imp_sth_t *sth)
{
    static const char function[] = "dbd_ix_setdbname";
    /**
    ** Scan through statement string, skipping comments ('{}' and '--\n'
    ** style), seeking (case-insensitively) the text of kw1 as the first
    ** word in the statement, and kw2 (if not null) as the second word in
    ** the statement.  The required database name is the third word in the
    ** statement.  Pain!  Oh the pain!  Why can't I have the database name
    ** returned to me by Informix?  About the only mercy is that we know
    ** that there is a major problem if the keywords are not found.
    ** OK: we created sqltoken() to handle this!
    */
    /* Where's the statement text? */
    char *tok = SvPV(sth->st_text, PL_na);
    const char *end = tok;

    dbd_ix_enter(function);
    tok = sqltoken(end, &end);
    /* Should be same as kw1 -- give or take case */
    if (DBIc_DBISTATE(sth)->debug >= 6)
        warn("%s: %s = <<%*.*s>>\n", function, kw1, (int)(end - tok), (int)(end - tok), tok);
    /* What's the Perl case-insensitive string comparison routine called? */
    if (kw2 != 0)
    {
        tok = sqltoken(end, &end);
        if (DBIc_DBISTATE(sth)->debug >= 6)
            warn("%s: %s = <<%*.*s>>\n", function, kw2, (int)(end - tok), (int)(end - tok), tok);
        /* Should be same as kw2 -- give or take case */
    }
    tok = sqltoken(end, &end);
    if (DBIc_DBISTATE(sth)->debug >= 6)
        warn("%s: dbn = <<%*.*s>>\n", function, (int)(end - tok), (int)(end - tok), tok);
    /* Should be the database name! */
    /* Must handle this correctly! */
    if (sth->dbh->database != 0)
        SvREFCNT_dec(sth->dbh->database);
    sth->dbh->database = newSVpv(tok, end - tok);
    if (DBIc_DBISTATE(sth)->debug >= 4)
        warn("new database name <<%s>>\n", SvPV(sth->dbh->database, PL_na));
    dbd_ix_exit(function);
}

static int
dbd_ix_exec(imp_sth_t *imp_sth)
{
    static const char function[] = "dbd_ix_exec";
    EXEC SQL BEGIN DECLARE SECTION;
    char           *nm_cursor = imp_sth->nm_cursor;
    char           *nm_stmnt = imp_sth->nm_stmnt;
    char           *nm_ibind = imp_sth->nm_ibind;
    EXEC SQL END DECLARE SECTION;
    imp_dbh_t *dbh = imp_sth->dbh;
    int rc = 1;
    Boolean exec_stmt = True;

    dbd_ix_enter(function);

    if (imp_sth->st_type == SQ_BEGWORK)
    {
        /* BEGIN WORK in a logged non-ANSI database with AutoCommit Off */
        /* will fail because we're already in a transaction. */
        /* Pretend it succeeded. */
        if (dbh->is_loggeddb == True && dbh->is_modeansi == False)
        {
            if (DBI_AutoCommit(dbh) == False)
            {
                dbd_ix_debug(1, "%s - AUTOCOMMIT Off => Pretend to BEGIN WORK succesfully\n", function);
                exec_stmt = False;
                sqlca.sqlcode = 0;
            }
        }
    }

    if (exec_stmt == True)
    {
        if (imp_sth->n_icols <= 0)
        {
            dbd_ix_debug(2, "\t---- EXECUTE %s - no parameters\n", nm_stmnt);
            EXEC SQL EXECUTE :nm_stmnt;
        }
        else if (imp_sth->st_type == SQ_INSERT && imp_sth->is_insertcursor == True)
        {
            dbd_ix_debug(2, "\t---- PUT %s USING %s\n", nm_cursor, nm_ibind);
            EXEC SQL PUT :nm_cursor USING SQL DESCRIPTOR :nm_ibind;
        }
        else
        {
            dbd_ix_debug(2, "\t---- EXECUTE %s USING %s\n", nm_stmnt, nm_ibind);
            EXEC SQL EXECUTE :nm_stmnt USING SQL DESCRIPTOR :nm_ibind;
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
        {
            dbd_ix_debug(1, "%s - AUTOCOMMIT On => COMMIT WORK\n", function);
            rc = dbd_ix_commit(dbh);
        }
        break;
    case SQ_COMMIT:
        dbd_ix_debug(3, "%s: COMMIT WORK\n", dbd_ix_module());
        dbh->is_txactive = False;
        assert(dbh->is_loggeddb == True);
        /* In a logged database with AutoCommit Off, do BEGIN WORK */
        if (dbh->is_modeansi == False && DBI_AutoCommit(dbh) == False)
        {
            dbd_ix_debug(1, "%s - AUTOCOMMIT Off => BEGIN WORK\n", function);
            rc = dbd_ix_begin(dbh);
        }
        break;
    case SQ_ROLLBACK:
        dbd_ix_debug(3, "%s: ROLLBACK WORK\n", dbd_ix_module());
        dbh->is_txactive = False;
        assert(dbh->is_loggeddb == True);
        /* In a logged database with AutoCommit Off, do BEGIN WORK */
        if (dbh->is_modeansi == False && DBI_AutoCommit(dbh) == False)
        {
            dbd_ix_debug(1, "%s - AUTOCOMMIT Off => BEGIN WORK\n", function);
            rc = dbd_ix_begin(dbh);
        }
        break;
    case SQ_DATABASE:
        dbh->is_txactive = False;
        dbd_ix_setdbtype(dbh);
        dbd_ix_setdbname("DATABASE", 0, imp_sth);
        break;
    case SQ_CREADB:
        dbh->is_txactive = False;
        dbd_ix_setdbtype(dbh);
        dbd_ix_setdbname("CREATE", "DATABASE", imp_sth);
        break;
    case SQ_STARTDB:
        dbh->is_txactive = False;
        dbd_ix_setdbtype(dbh);
        dbd_ix_setdbname("START", "DATABASE", imp_sth);
        break;
    case SQ_RFORWARD:
        dbh->is_txactive = False;
        dbd_ix_setdbtype(dbh);
        dbd_ix_setdbname("ROLLFORWARD", "DATABASE", imp_sth);
        break;
    case SQ_CLSDB:
        /**
        ** CLOSE DATABASE -- no transactions, no autocommit, etc.
        ** With 6.00 upwards, the connection to the server still exists
        ** With 5.00, if the database was remote, then the connection
        ** is broken by close database; otherwise, it remains.  Assume
        ** it still exists until further notice...
        */
        dbh->is_txactive = False;
        dbh->is_modeansi = False;
        dbh->is_onlinedb = False;
        dbh->is_loggeddb = False;
        DBIc_set(dbh, DBIcf_AutoCommit, False);
        SvREFCNT_dec(dbh->database);
        dbh->database = 0;
        break;
    default:
        if (dbh->is_modeansi)
            dbh->is_txactive = True;
        /* COMMIT WORK for MODE ANSI databases when AutoCommit is On */
        if (dbh->is_modeansi == True && DBI_AutoCommit(dbh) == True)
        {
            dbd_ix_debug(1, "%s - AUTOCOMMIT On => COMMIT WORK\n", function);
            rc = dbd_ix_commit(dbh);
        }
        break;
    }

    DBIc_on(imp_sth, DBIcf_IMPSET); /* Qu'est que c'est? */
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
** DBD::Informix will not return -1, though there's at least half an
** argument for returning -1 after dbd_ix_open() is called.
*/
int
dbd_ix_st_execute(SV *sth, imp_sth_t *imp_sth)
{
    static const char function[] = "dbd_ix_st_execute";
    dTHR;
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
    else if (imp_sth->st_type == SQ_EXECPROC && imp_sth->n_ocols > 0)
        rc = dbd_ix_open(imp_sth);
#endif /* SQ_EXECPROC */
    else
    {
        rc = 1;
        /* only open cursor if it is not currently open, otherwise it flushes */
        if ((imp_sth->st_type == SQ_INSERT) &&
            (imp_sth->is_insertcursor == True) &&
            (imp_sth->st_state != Opened))
            rc = dbd_ix_open(imp_sth);
        if (rc)
            rc = dbd_ix_exec(imp_sth);
    }

    /* Map returned values from dbd_ix_exec and dbd_ix_open */
    if (rc == 0)
    {
        /* Statement failed -- return the error code */
        assert(sqlca.sqlcode < 0);
        rv = sqlca.sqlcode;
    }
    else
    {
        /**
        ** Statement succeeded.  Don't forget about MODE ANSI database and
        ** an UPDATE which does not alter any rows returning SQLNOTFOUND.
        ** MODE ANSI problem found by Chuck.Collins@zool.Airtouch.com
        */
        rv = sqlca.sqlerrd[2];
        assert((sqlca.sqlcode == 0 || sqlca.sqlcode == SQLNOTFOUND) && rv >= 0);
    }

    dbd_ix_exit(function);
    return(rv);
}

int
dbd_ix_st_rows(SV *sth, imp_sth_t *imp_sth)
{
    return(imp_sth->n_rows);
}

/*
** Map the DBI standard type numbers (SQL_NUMERIC, etc) to Informix types.
** Cribbed from DBD::Oracle v1.13, file dbdimp.c, function ora_sql_type().
*/
static int
ix_sql_type(int sql_type)
{
    int ix_type;

    /* XXX should detect DBI reserved standard type range here */

    switch (sql_type)
    {
    case SQL_NUMERIC:
    case SQL_DECIMAL:
    case SQL_INTEGER:
    case SQL_BIGINT:
    case SQL_TINYINT:
    case SQL_SMALLINT:
    case SQL_FLOAT:
    case SQL_REAL:
    case SQL_DOUBLE:
    case SQL_VARCHAR:
    case SQL_CHAR:
    case SQL_DATE:
    case SQL_TIME:
    case SQL_TIMESTAMP:
        ix_type = SQLCHAR;       /* Informix CHAR */
        break;

    case SQL_BINARY:
    case SQL_VARBINARY:
    case SQL_LONGVARBINARY:
        ix_type = SQLBYTES;      /* Informix BYTE blob */
        break;

    case SQL_LONGVARCHAR:
        ix_type = SQLTEXT;       /* Informix TEXT blob */
        break;

    default:
        ix_type = SQLCHAR;
        dbd_ix_debug(4, "\t---- ix_sql_type(): defaulted DBI SQL type = %ld\n",
                        (long)sql_type);
        dbd_ix_debug(4, "\t---- ix_sql_type(): Informix type = %ld\n",
                        (long)ix_type);
        break;
    }
    return(ix_type);
}

/*
** Validate Informix type number.
** List cribbed from constant() in Informix.xs and should match that list
*/
static int
valid_ix_type(int val_type)
{
    int rc = 1;
    switch (val_type)
    {
    case SQLSMINT:
    case SQLINT:
    case SQLSERIAL:
    case SQLINT8:
    case SQLSERIAL8:
    case SQLDECIMAL:
    case SQLMONEY:
    case SQLFLOAT:
    case SQLSMFLOAT:
    case SQLCHAR:
    case SQLVCHAR:
    case SQLNCHAR:
    case SQLNVCHAR:
    case SQLLVARCHAR:
    case SQLBOOL:
    case SQLDATE:
    case SQLDTIME:
    case SQLINTERVAL:
    case SQLBYTES:
    case SQLTEXT:
    case SQLSET:
    case SQLMULTISET:
    case SQLLIST:
    case SQLROW:
    case SQLCOLLECTION:
    case SQLUDTVAR:
    case SQLUDTFIXED:
#ifdef ESQLC_BIGINT
    case SQLINFXBIGINT:
    case SQLBIGSERIAL:
#endif /* ESQLC_BIGINT */
    /*
    ** In the Informix system catalog, CLOB and BLOB types are simply
    ** specific cases of a fixed UDT.  They seem to have extended ids
    ** 10, 11.  However, they are also base types (opaque), and there
    ** is storage information for them in the create table statement
    ** (a PUT clause after the column list).  We need to handle them
    ** specially, so define unique values for them in dbdimp.h.
    */
    case DBD_IX_SQLCLOB:
    case DBD_IX_SQLBLOB:
        rc = 1;
        break;

    default:
        rc = 0;
        break;
    }
    return(rc);
}

/*
** Convert ix_type attribute, or sql_type value, to Informix type number
**
** if (attribs includes { ix_type => xxx }, then extract val_type = xxx.
** else if (sql_type != 0) val_type = ix_type_matching_sql_type(sql_type);
** else val_type = SQLVCHAR;
**
** Cribbed from DBD::Oracle v1.13, file dbdimp.c, function dbd_bind_ph().
*/
static int
dbd_ix_st_bind_type(IV sql_type, SV *attribs)
{
    static const char function[] = "dbd_ix_st_bind_type";
    int val_type = SQLVCHAR;
    dbd_ix_enter(function);

    dbd_ix_debug(4, "\t---- %s(): sql_type = %ld\n", function, sql_type);

    if (attribs)
    {
        SV **svp = hv_fetch((HV*)SvRV(attribs), "ix_type", sizeof("ix_type")-1, 0);
        if (svp != NULL)
        {
            val_type = SvIV(*svp);
            dbd_ix_debug(4, "\t---- %s(): val_type = $attribs{ix_type} = %ld\n", function, val_type);
            if (!valid_ix_type(val_type))
                croak("Can't bind ix_type %d not supported", val_type);
            if (sql_type)
                croak("Can't specify both TYPE (%d) and ix_type (%d)",
                        (int)sql_type, val_type);
        }
    }
    if (sql_type)
    {
        val_type = ix_sql_type(sql_type);
        dbd_ix_debug(4, "\t---- %s(): mapped SQL type to val_type = %ld\n", function, val_type);
    }
    dbd_ix_debug(4, "\t---- %s(): return val_type = %ld\n", function, val_type);
    dbd_ix_exit(function);
    return(val_type);
}

/* Called extensively by execute method when it is given parameters! */
int
dbd_ix_st_bind_ph(SV *sth, imp_sth_t *imp_sth, SV *param, SV *value,
    IV sql_type, SV *attribs, int is_inout, IV maxlen)
{
    static const char function[] = "dbd_ix_st_bind_ph";
    int rc;
    int val_type;

    dbd_ix_enter(function);
    dbd_ix_debug(4, "\t---- %s(): sql_type = %ld\n", function, (long)sql_type);
    if (is_inout)
        croak("%s() - inout parameters not implemented\n", function);
    val_type = dbd_ix_st_bind_type(sql_type, attribs);
    rc = dbd_ix_bindsv(imp_sth, SvIV(param), val_type, value);
    dbd_ix_exit(function);
    return(rc);
}

int
dbd_ix_st_blob_read(SV *sth, imp_sth_t *imp_sth, int field, long offset,
                    long len, SV *destrv, long destoffset)
{
    croak("%s - dbd_ix_st_blob_read() not implemented\n", dbd_ix_module());
    return -1;
}

/* -------------- End of $RCSfile: dbdimp.ec,v $ -------------- */
