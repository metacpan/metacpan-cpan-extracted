/*
 * @(#)$Id: esqlbasic.ec,v 2015.1 2015/08/21 21:18:25 jleffler Exp $
 *
 * DBD::Informix for Perl Version 5 -- Test Informix-ESQL/C environment
 *
 * This is a stripped down version of the esqltest.ec program, but it is
 * a pure ESQL/C program which is completely self-contained (it does not
 * require any source or headers other than those which come with ESQL/C).
 * Used when people really run into problems.  Compile using the following
 * command line (ensuring that there is no esql script modified by
 * DBD::Informix in the way of the official esql script):
 *
 *     esql -o esqlbasic esqlbasic.ec
 *
 * Copyright 1997-99 Jonathan Leffler
 * Copyright 2002    IBM
 * Copyright 2015    Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* SunOS 4.1.3 <stdlib.h> does not provide EXIT_SUCCESS/EXIT_FAILURE */
#ifndef EXIT_FAILURE
#define EXIT_FAILURE 1
#endif
#ifndef EXIT_SUCCESS
#define EXIT_SUCCESS 0
#endif

static int estat = EXIT_SUCCESS;

#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
extern const char jlss_id_esqlbasic_ec[];
const char jlss_id_esqlbasic_ec[] = "@(#)$Id: esqlbasic.ec,v 2015.1 2015/08/21 21:18:25 jleffler Exp $";
#endif /* lint */

/*
** Various people ran into problems testing DBD::Informix because the
** basic Informix environment was not set up correctly.
** This code was written as a self-defense measure to try and ensure
** that DBD::Informix had some chance of being tested successfully
** before the tests are run.
**
** What type is sqlca.sqlerrd[1]?  It is now 'int4', but used to be
** (directly) 'long' or 'int'.  And int4 maps to long on 32-bit and int
** on 64-bit platforms.  So, what's the correct printf() conversion
** specifier?  It's hard to say.  Ideally, the esqltype.h header would
** be used along with PRId_ixInt4.  Let's save the value in a long and
** print accordingly.
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
		if (rgetmsg(rc, errbuf, sizeof(errbuf)) != 0)
			strcpy(errbuf, "<<Failed to locate SQL error message>>");
		sprintf(fmtbuf, errbuf, sqlca.sqlerrm);
		sprintf(sql_buf, "SQL: %ld: %s", rc, fmtbuf);

		/* Format ISAM (secondary) error */
		if (sqlca.sqlerrd[1] != 0)
		{
            long sqlerrd1 = sqlca.sqlerrd[1];
			if (rgetmsg(sqlca.sqlerrd[1], errbuf, sizeof(errbuf)) != 0)
				strcpy(errbuf, "<<Failed to locate ISAM error message>>");
			sprintf(fmtbuf, errbuf, sqlca.sqlerrm);
			sprintf(isambuf, "ISAM: %ld: %s", sqlerrd1, fmtbuf);
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
		fprintf(stderr, "You cannot use %s as a test database.\n", dbname);
		fprintf(stderr, "You do not have sufficient privileges.\n");
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

int main(void)
{
	/* Command-line arguments are ignored at the moment */
	char *dbidsn = getenv("DBI_DSN");
	char *dbase0 = getenv("DBI_DBNAME");
	$char *dbase1 = getenv("DBD_INFORMIX_DATABASE");

	/* Check whether the default connection variable is set */
	if (dbidsn != 0 && *dbidsn != '\0')
	{
		printf("\tFYI: $DBI_DSN is set to '%s'.\n", dbidsn);
		printf("\t\tIt is not used by any of the DBD::Informix tests.\n");
		printf("\t\tIt is unset by the tests which would otherwise break.\n");
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

	printf("Testing connection to %s\n", dbase1);

	EXEC SQL DATABASE :dbase1;

	if (sqlca.sqlcode != 0)
	{
		ix_printerr(stderr, sqlca.sqlcode);
	}

	test_permissions(dbase1);

	if (estat == EXIT_SUCCESS)
		printf("Your Informix environment is (probably) OK\n\n");
	else
	{
		printf("\n*** Your Informix environment is not usable");
		printf("\n*** You must fix it before building or testing DBD::Informix\n\n");
	}
	return(estat);
}
