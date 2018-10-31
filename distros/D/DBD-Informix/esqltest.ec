/*
 * @(#)$Id: esqltest.ec,v 2015.1 2014/07/28 07:16:36 jleffler Exp $
 *
 * Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31)
 *
 * Test Informix-ESQL/C environment
 *
 * Copyright 1997-99 Jonathan Leffler
 * Copyright 2000    Informix Software Inc
 * Copyright 2002    IBM
 * Copyright 2004-07 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*
** Expects -DESQLC_VERSION=290 or similar on command line.
**
** Note that CSDK 2.90 includes ESQL/C 2.90, but ESQL/C 2.81 includes
** ESQL/C 9.53.  (Assume 2.90 - 3.99 are capable of using CONNECT;
** sometime, this will break, again!)
*/

/*TABSTOP=4*/

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "esqlperl.h"

/* JL 1998-11-03: test for __STDC__ removed */
/* Perl 5.005 requires a compiler which accepts prototypes */

/* SunOS 4.1.3 <stdlib.h> does not provide EXIT_SUCCESS/EXIT_FAILURE */
#ifndef EXIT_FAILURE
#define EXIT_FAILURE 1
#endif
#ifndef EXIT_SUCCESS
#define EXIT_SUCCESS 0
#endif

#if ESQLC_EFFVERSION >= 600
#define USE_CONNECT 1
#else
#define USE_CONNECT 0
#endif /* ESQLC_EFFVERSION */

static int estat = EXIT_SUCCESS;

#ifndef lint
static const char rcs[] = "@(#)$Id: esqltest.ec,v 2015.1 2014/07/28 07:16:36 jleffler Exp $";
#endif

/*
** Various people ran into problems testing DBD::Informix because the
** basic Informix environment was not set up correctly.
** This code was written as a self-defense measure to try and ensure
** that DBD::Informix had some chance of being tested successfully
** before the tests are run.  It has proven very successful.
*/

/* Format and print an Informix error message (both SQL and ISAM parts) */
void            ix_printerr(FILE *fp, long rc)
{
    char            errbuf[256];
    char            fmtbuf[256];
    char            sql_buf[256];
    char            isambuf[256];
    char            msgbuf[sizeof(sql_buf)+sizeof(isambuf)];

    if (rc != 0)
    {
        /* Format SQL (primary) error */
        /* The int cast on 3rd argument to rgetmsg() prevents warning */
        /* C4761: integral size mismatch in argument; conversion supplied */
        /* on NT (MSVC 5.0) compiler */
        if (rgetmsg(rc, errbuf, (int)sizeof(errbuf)) != 0)
            strcpy(errbuf, "<<Failed to locate SQL error message>>");
        sprintf(fmtbuf, errbuf, sqlca.sqlerrm);
        sprintf(sql_buf, "SQL: %ld: %s", rc, fmtbuf);

        /* Format ISAM (secondary) error */
        if (sqlca.sqlerrd[1] != 0)
        {
            if (rgetmsg(sqlca.sqlerrd[1], errbuf, (int)sizeof(errbuf)) != 0)
                strcpy(errbuf, "<<Failed to locate ISAM error message>>");
            sprintf(fmtbuf, errbuf, sqlca.sqlerrm);
            sprintf(isambuf, "ISAM: %" PRId_ixInt4 ": %s", sqlca.sqlerrd[1], fmtbuf);
        }
        else
            isambuf[0] = '\0';

        /* Concatenate SQL and ISAM messages */
        /* Note that the messages have trailing newlines */
        strcpy(msgbuf, sql_buf);
        strcat(msgbuf, isambuf);

        /* Record error number and error message */
        fprintf(fp, "%s\n", msgbuf);

        /* Set exit status */
        estat = EXIT_FAILURE;
    }
}

static void test_permissions(char *dbname)
{
    EXEC SQL CREATE TABLE dbd_ix_esqltest (Col01 INTEGER NOT NULL);
    if (sqlca.sqlcode < 0)
    {
        fprintf(stderr, "You can only use %s as a test database if you set\n", dbname);
        fprintf(stderr, "DBD_INFORMIX_NO_RESOURCE=yes in your environment.\n");
        fprintf(stderr, "You do not have sufficient privileges to create tables.\n");
        ix_printerr(stderr, sqlca.sqlcode);
        estat = EXIT_FAILURE;
    }
    else
    {
        EXEC SQL DROP TABLE dbd_ix_esqltest;
        if (sqlca.sqlcode < 0)
        {
            fprintf(stderr, "Failed to drop table dbd_ix_esqltest in database %s\n", dbname);
            fprintf(stderr, "Please remove it manually.\n");
            ix_printerr(stderr, sqlca.sqlcode);
        }
    }
    /*
    ** Ignore any errors on rollback.
    ** The ROLLBACK (or a COMMIT) is necessary if $DBD_INFORMIX_DATABASE is
    ** a MODE ANSI database and DBD_INFORMIX_DATABASE2 is either unset or
    ** set to the same database.
    ** Problem found by Kent S. Gordon (kgor@inetspace.com).
    */
    EXEC SQL ROLLBACK WORK;
}

void dbd_ix_debug(int level, const char *fmt, ...)
{
    va_list args;

    printf("\t%d: ", level);
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
}

int main(void)
{
    char *dbidsn = getenv("DBI_DSN");
    char *dbase0 = getenv("DBI_DBNAME");
    char *dbase1 = getenv("DBD_INFORMIX_DATABASE");
    char *dbase2 = getenv("DBD_INFORMIX_DATABASE2");
    char *user1 = getenv("DBD_INFORMIX_USERNAME");
    char *pass1 =  getenv("DBD_INFORMIX_PASSWORD");
    char *srvr1 =  getenv("DBD_INFORMIX_SERVER");   /* Obsolete */
    char *user2 = getenv("DBD_INFORMIX_USERNAME2");
    char *pass2 =  getenv("DBD_INFORMIX_PASSWORD2");
    char *ixdir = getenv("INFORMIXDIR");
    char *ixsrv = getenv("INFORMIXSERVER");
    char *nores = getenv("DBD_INFORMIX_NO_RESOURCE");
    Boolean conn_ok;
    static char  conn1[20] = "connection_1";
    static char  conn2[20] = "connection_2";

    printf("ESQLTEST Program Running:\n%s\n", rcs);

    /* Check whether the default connection variable is set */
    if (dbidsn != 0 && *dbidsn != '\0')
    {
        printf("!!!\tFYI: $DBI_DSN is set to '%s'.\n", dbidsn);
        printf("\t\tIt is not used by any of the DBD::Informix tests.\n");
        printf("\t\tIt is unset by the tests which would otherwise break.\n");
    }

    if (ixdir != 0 && *ixdir != '\0')
    {
        printf("\t$INFORMIXDIR is set to '%s'.\n", ixdir);
    }
    if (ixsrv != 0 && *ixsrv != '\0')
    {
        printf("\t$INFORMIXSERVER is set to '%s'.\n", ixsrv);
    }

    /* Test whether the server name is set. */
    if (srvr1 != 0 && *srvr1 != '\0')
    {
        printf("!!!\t$DBD_INFORMIX_SERVER is set.  Read the README file!\n");
    }

    /* Set the basic default database name */
    if (dbase0 == 0 || *dbase0 == '\0')
    {
        dbase0 = "stores";
        printf("\t$DBI_DBNAME unset - defaulting to '%s'.\n", dbase0);
    }
    else
    {
        printf("\t$DBI_DBNAME set to '%s'.\n", dbase0);
    }

    /* Test for the explicit DBD::Informix database */
    if (dbase1 == 0 || *dbase1 == '\0')
    {
        dbase1 = dbase0;
        printf("\t$DBD_INFORMIX_DATABASE unset - defaulting to '%s'.\n", dbase1);
    }
    else
        printf("\t$DBD_INFORMIX_DATABASE set to '%s'.\n", dbase1);

    /* Test for the secondary database for multi-connection testing */
    if (dbase2 == 0 || *dbase2 == '\0')
    {
        dbase2 = dbase1;
        printf("\t$DBD_INFORMIX_DATABASE2 unset - defaulting to '%s'.\n", dbase2);
    }
    else
        printf("\t$DBD_INFORMIX_DATABASE2 set to '%s'.\n", dbase2);

    /* Report whether username is set, and what it is */
    if (user1 == 0 || *user1 == '\0')
    {
        user1 = 0;
        printf("\t$DBD_INFORMIX_USERNAME is unset.\n");
    }
    else
        printf("\t$DBD_INFORMIX_USERNAME is set to '%s'.\n", user1);

    /* Report whether username is set, and what it is */
    if (user2 == 0 || *user2 == '\0')
    {
        if (user1)
        {
            user2 = user1;
            printf("\t$DBD_INFORMIX_USERNAME2 is unset - defaulting to '%s'.\n", user2);
        }
        else
        {
            user2 = 0;
            printf("\t$DBD_INFORMIX_USERNAME2 is unset.\n");
        }
    }
    else
        printf("\t$DBD_INFORMIX_USERNAME2 is set to '%s'.\n", user2);

    /* Report whether password is set, but not what it is */
    if (pass1 == 0 || *pass1 == '\0')
    {
        pass1 = 0;
        printf("\t$DBD_INFORMIX_PASSWORD is unset.\n");
    }
    else
        printf("\t$DBD_INFORMIX_PASSWORD is set.\n");

    /* Report whether password is set, but not what it is */
    if (pass2 == 0 || *pass2 == '\0')
    {
        if (pass1)
        {
            pass2 = pass1;
            printf("\t$DBD_INFORMIX_PASSWORD2 is unset - defaulting to $DBD_INFORMIX_PASSWORD.\n");
        }
        else
        {
            pass2 = 0;
            printf("\t$DBD_INFORMIX_PASSWORD2 is unset.\n");
        }
    }
    else
        printf("\t$DBD_INFORMIX_PASSWORD2 is set.\n");

    printf("Testing connection to %s\n", dbase1);
#if USE_CONNECT == 1
    /* Test whether $INFORMIXSERVER is set. */
    srvr1 = getenv("INFORMIXSERVER");
    if (srvr1 == 0 || *srvr1 == '\0')
    {
        printf("!!!\t$INFORMIXSERVER is not set but should be.  Read the README file!\n");
    }
    /* 6.00 and later versions of Informix-ESQL/C support CONNECT */
    if ((user1 == 0 && pass1 != 0) || (user1 != 0 && pass1 == 0))
    {
        printf("!!!\tDBD_INFORMIX_USERNAME & DBD_INFORMIX_PASSWORD are ignored\n");
        printf("\t\tunless both variables are set.\n");
    }
    conn_ok = dbd_ix_connect(conn1, dbase1, user1, pass1);
#else
    /* Pre-6.00 versions of Informix-ESQL/C do not support CONNECT */
    /* Use DATABASE statement */
    printf("\tDBD_INFORMIX_USERNAME & DBD_INFORMIX_PASSWORD are ignored.\n");
    conn_ok = dbd_ix_opendatabase(dbase1);
#endif  /* USE_CONNECT == 1 */

    if (!conn_ok || sqlca.sqlcode != 0)
    {
        ix_printerr(stderr, sqlca.sqlcode);
    }
    else
    {
        if (nores == 0 || *nores == '\0')
            test_permissions(dbase1);
        else
            printf("Not testing resource privileges because DBD_INFORMIX_NO_RESOURCE=%s\n", nores);
    }

#if USE_CONNECT == 1
    if ((user2 == 0 && pass2 != 0) || (user2 != 0 && pass2 == 0))
    {
        printf("!!!\tDBD_INFORMIX_USERNAME2 & DBD_INFORMIX_PASSWORD2 are ignored\n");
        printf("\t\tunless both variables are set.\n");
    }
    printf("Testing concurrent connection to %s\n", dbase2);
    /* 6.00 and later versions of Informix-ESQL/C support CONNECT */
    conn_ok = dbd_ix_connect(conn2, dbase2, user2, pass2);
#else
    /* Pre-6.00 versions of Informix-ESQL/C do not support CONNECT */
    /* Use DATABASE statement */
    printf("Testing connection to %s\n", dbase2);
    conn_ok = dbd_ix_opendatabase(dbase2);
#endif  /* USE_CONNECT == 1 */

    if (!conn_ok || sqlca.sqlcode != 0)
    {
        if (sqlca.sqlcode == -27000)
        {
            printf("You're using shared memory connections for both databases.\n");
            printf("DBD::Informix cannot test multiple concurrent connections.\n");
            printf("The multi-connection tests will be skipped.\n");
        }
        else
            ix_printerr(stderr, sqlca.sqlcode);
    }
    else if (nores == 0 || *nores == '\0')
        test_permissions(dbase2);

    if (estat == EXIT_SUCCESS)
        printf("Your Informix environment is (probably) OK\n\n");
    else
    {
        printf("\n*** Your Informix environment is not usable");
        printf("\n*** You must fix it before building or testing DBD::Informix\n\n");
    }
    return(estat);
}
