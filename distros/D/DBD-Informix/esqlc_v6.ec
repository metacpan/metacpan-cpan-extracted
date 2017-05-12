/*
 * @(#)$Id: esqlc_v6.ec,v 2007.1 2007/06/09 18:15:08 jleffler Exp $
 *
 * IBM Informix Database Driver for Perl (DBD::Informix)
 * Connection Management for ESQL/C Version 6.0x and later
 *
 * Copyright 1996-98 Jonathan Leffler
 * Copyright 2000    Informix Software Inc
 * Copyright 2002    IBM
 * Copyright 2007    Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#include <string.h>
#include <stdlib.h>
#include "esqlperl.h"

#ifndef lint
static const char rcs[] = "@(#)$Id: esqlc_v6.ec,v 2007.1 2007/06/09 18:15:08 jleffler Exp $";
#endif

/* ================================================================= */
/* =================== Database Level Operations =================== */
/* ================================================================= */

static char *get_server_name(void)
{
	char *srvr = 0;
	char *ix_srvr = getenv("INFORMIXSERVER");

	if (ix_srvr == 0 || *ix_srvr == '\0' || (srvr = (char *)malloc(strlen(ix_srvr) + 2)) == 0)
	{
		sqlca.sqlcode = -952;
	}
	{
		srvr[0] = '@';
		strcpy(&srvr[1], ix_srvr);
	}
	return(srvr);
}

static void rel_server_name(char *srvr)
{
	free(srvr);
}

/* Execute a full CONNECT statement - no error checking */
static void full_connect(char *connection, char *dbase, char *user, char *pass)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *dbconn = connection;
	char           *dbname = dbase;
	char           *dbpass = pass;
	char           *dbuser = user;
	EXEC SQL END DECLARE SECTION;

	EXEC SQL CONNECT TO :dbname AS :dbconn
		USER :dbuser USING :dbpass
		WITH CONCURRENT TRANSACTION;
}

/*
** Use CONNECT to initiate database connection
**
** If both user and password are provided, then the USER clause is used.
** If no database is specified, a default connection will be made.
**
** Note that CONNECT statements (and DISCONNECT and SET CONNECTION)
** cannot be prepared.
*/

Boolean dbd_ix_connect(char *connection, char *dbase, char *user, char *pass)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *dbconn;
	char           *dbname;
	EXEC SQL END DECLARE SECTION;
	Boolean         conn_ok = False;

	if (user != (char *)0 && pass != (char *)0)
	{
		/* User name and password provided */
		if (dbase == (char *)0 || *dbase == '\0')
		{
			/* No database name; connect to '@server' */
			dbname = get_server_name();
			if (dbname != 0)
			{
				dbd_ix_debug(1, "CONNECT TO '%s' {DEFAULT with user info}\n", dbname);
				full_connect(connection, dbname, user, pass);
				rel_server_name(dbname);
			}
		}
		else
		{
			dbd_ix_debug(1, "CONNECT TO '%s' with user info\n", dbase);
			full_connect(connection, dbase, user, pass);
		}
	}
	else if (dbase == (char *)0 || *dbase == '\0')
	{
		/* Not frequently used, but valid */
		/* Reset connection name to empty string, and connect to default */
		/* Typically used to create database on default server */
		/* Only works when no username/password needed to connect */
		/* Nasty interface, overwriting connection name! */
		*connection = '\0';
		dbd_ix_debug(1, "CONNECT TO DEFAULT %s\n", "- no user info");
		EXEC SQL CONNECT TO DEFAULT
			WITH CONCURRENT TRANSACTION;
	}
	else
	{
		dbconn = connection;
		dbname = dbase;
		dbd_ix_debug(1, "CONNECT TO '%s' - no user info\n", dbname);
		EXEC SQL CONNECT TO :dbname AS :dbconn
			WITH CONCURRENT TRANSACTION;
	}
	if (sqlca.sqlcode == 0)
		conn_ok = True;
	return(conn_ok);
}

/* Basic interface to DISCONNECT */
static void do_disconnect(char *connection)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *dbconn = connection;
	EXEC SQL END DECLARE SECTION;

	if (*connection != '\0')
	{
		dbd_ix_debug(1, "DISCONNECT (%s)\n", connection);
		EXEC SQL DISCONNECT :dbconn;
	}
	else
	{
		dbd_ix_debug(1, "DISCONNECT DEFAULT%s\n", connection);
		EXEC SQL DISCONNECT DEFAULT;
	}
}

/* External interface to disconnect which handles various oddities */
void dbd_ix_disconnect(char *connection)
{
	do_disconnect(connection);
	if (sqlca.sqlcode == -1800)
	{
		/*
		** -1800: Invalid transaction state
		** One problem was discovered by Nathan Neulinger (nneul@umr.edu).
		** This can occur if the application is talking to a 5.0x engine.
		** The solution seems to be to do CLOSE DATABASE, which also closes
		** the connection (you get error -1803 if you try to DISCONNECT
		** after doing CLOSE DATABASE).  Ensure that the correct connection
		** is current before closing the database.  Bugs B64926 and B42204
		** are the source of the trouble.
		**
		** A second version of the problem found with 7.x databases where a
		** transaction has been started and not completed.  Trying CLOSE
		** DATABASE fails with -759 (Cannot use database commands in an
		** explicit database connection).  It requires a ROLLBACK WORK
		** instead, followed by a DISCONNECT.  If you are connected to a
		** 5.0x engine, then the ROLLBACK WORK succeeds, but the DISCONNECT
		** fails a second time, but the CLOSE DATABASE ruse then works.
		**
		** If both these attempts fail, then the disconnect operation gives
		** up, letting the database engine clean up.  The engine will do a
		** rollback when it notes the absence of the application.
		*/
		dbd_ix_debug(1, "DISCONNECT **FAILED: -1800 ** <<%s>>\n", connection);
		dbd_ix_setconnection(connection);
		dbd_ix_debug(1, "Try ROLLBACK WORK <<%s>>\n", connection);
		EXEC SQL ROLLBACK WORK;
		if (sqlca.sqlcode == 0)
		{
			dbd_ix_debug(1, "ROLLBACK WORK worked <<%s>>\n", connection);
			do_disconnect(connection);
		}
		if (sqlca.sqlcode < 0)
		{
			dbd_ix_debug(1, "DISCONNECT ** FAILED AGAIN (%ld) **\n",
						   sqlca.sqlcode);
			dbd_ix_debug(1, "Try CLOSE DATABASE <<%s>>\n", connection);
			EXEC SQL CLOSE DATABASE;
			if (*connection == '\0')
			{
				dbd_ix_debug(1, "Retry DISCONNECT DEFAULT%s\n", connection);
				EXEC SQL DISCONNECT DEFAULT;
			}
		}
	}
	dbd_ix_debug(1, "DISCONNECT -- STATUS %ld\n", sqlca.sqlcode);
}

/* Ensure that the correct connection is current -- a no-op in version 5.0x */
void dbd_ix_setconnection(char *conn)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_connection = conn;
	EXEC SQL END DECLARE SECTION;

	if (nm_connection)
	{
		dbd_ix_debug(1, "SET CONNECTION %s\n", nm_connection);
		EXEC SQL SET CONNECTION :nm_connection;
	}
	else
	{
		dbd_ix_debug(1, "SET CONNECTION DEFAULT%s\n", "");
		EXEC SQL SET CONNECTION DEFAULT;
	}
}
