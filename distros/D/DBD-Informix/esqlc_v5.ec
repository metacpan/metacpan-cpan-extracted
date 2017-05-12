/*
 * @(#)$Id: esqlc_v5.ec,v 100.2 2002/12/06 22:18:24 jleffler Exp $
 *
 * DBD::Informix for Perl Version 5 -- implementation details
 *
 * Code acceptable to ESQL/C Version 5.0x
 *
 * Copyright 1996-98 Jonathan Leffler
 * Copyright 2002    IBM
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#include <string.h>
#include "esqlperl.h"

#ifndef lint
static const char rcs[] = "@(#)$Id: esqlc_v5.ec,v 100.2 2002/12/06 22:18:24 jleffler Exp $";
#endif

/* ================================================================= */
/* =================== Database Level Operations =================== */
/* ================================================================= */

/* Open database, possibly on a 'remote' host */
Boolean
dbd_ix_opendatabase(char *dbase)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *dbname = dbase;
	EXEC SQL END DECLARE SECTION;
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
		EXEC SQL DATABASE :dbname;
		if (sqlca.sqlcode == 0)
			conn_ok = True;
	}
	return(conn_ok);
}

void
dbd_ix_closedatabase(char *dbname)
{
	dbd_ix_debug(1, "CLOSE DATABASE %s\n", (dbname ? dbname : ""));
	EXEC SQL CLOSE DATABASE;
	if ((dbname == 0 || *dbname == '\0') && sqlca.sqlcode == -349)
	{
		/* -349: Database not selected yet. */
		/* Fib about failure to close database */
		sqlca.sqlcode = 0;
	}
}

/* Ensure that the correct connection is current -- a no-op in version 5.0x */
void dbd_ix_setconnection(char *conn)
{
	dbd_ix_debug(1, "SET CONNECTION - %s (NO-OP)\n", conn);
	sqlca.sqlcode = 0;
}
