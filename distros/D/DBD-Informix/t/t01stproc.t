#!/usr/bin/perl
#
#   @(#)$Id: t01stproc.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test stored procedure handling for DBD::Informix
#
#   Copyright 1999    Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2005-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

if (defined $ENV{DBD_INFORMIX_NO_RESOURCE} && $ENV{DBD_INFORMIX_NO_RESOURCE})
{
    stmt_note "1..0 # Skip: requires RESOURCE privileges but DBD_INFORMIX_NO_RESOURCE set.\n";
    exit 0;
}

my $dbh = connect_to_test_database();

if (!$dbh->{ix_StoredProcedures})
{
    print("1..0 # Skip: No stored procedure support\n");
    $dbh->disconnect;
    exit(0);
}
else
{
    stmt_note("1..9\n");
    stmt_ok(0);

    # Test stored procedures...
    my $procname = "dbd_ix_01";

    my $stmt10 = "DROP PROCEDURE $procname";
    {
    my ($q) = $dbh->{PrintError};
    $dbh->{PrintError} = 0;
    stmt_test($dbh, $stmt10, 1);
    $dbh->{PrintError} = $q;
    }

    my $stmt11 =
    qq{
    CREATE PROCEDURE $procname(val1 DECIMAL, val2 DECIMAL)
        -- Sometimes known as ndelta_eq()
        RETURNING INTEGER;
        IF (val1 = val2) THEN RETURN 1; END IF;
        IF NOT (val1 = val2) THEN RETURN 0; END IF;
        RETURN NULL;
    END PROCEDURE;
    };
    stmt_test($dbh, $stmt11, 0);

    my $stmt12 = "EXECUTE PROCEDURE $procname(23.00, 23)";
    stmt_note("# Testing: \$cursor = \$dbh->prepare('$stmt12')\n");
    my $cursor;
    stmt_fail() unless ($cursor = $dbh->prepare($stmt12));
    stmt_ok(0);

    stmt_note("# Re-testing: \$cursor->execute\n");
    stmt_fail() unless ($cursor->execute);
    stmt_ok(0);

    stmt_note("# Re-testing: \$cursor->fetchrow\n");
    my @row;
    stmt_fail() unless (@row = $cursor->fetchrow);
    stmt_ok(0);

    stmt_note("# Values returned/expected: ", $#row + 1, "/1\n");
    my $i;
    for ($i = 0; $i <= $#row; $i++)
    {
            stmt_note("# Row value $i: $row[$i]\n");
            die "Unexpected value returned\n" unless $row[$i] == 1;
    }

    stmt_note("# Re-testing: \$cursor->finish\n");
    stmt_fail() unless ($cursor->finish);
    stmt_ok(0);

    # FREE the cursor and asociated data
    undef $cursor;

    # Remove stored procedure
    stmt_retest($dbh, $stmt10, 0);
}

stmt_note("# Testing: \$dbh->disconnect()\n");
stmt_fail() unless ($dbh->disconnect);
stmt_ok(0);

all_ok;
