#!/usr/bin/perl -w
#
# @(#)$Id: multicursor.t,v 57.1 1997/07/29 01:24:32 johnl Exp $ 
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#
# Portions Copyright (C) 1996,1997 Jonathan Leffler
#
# Tests multiple simultaneous cursors being open

use DBD::SqlflexTest;

print "1..17\n";
$dbh = connect_to_test_database(1);
&stmt_ok(0);
$dbh->{ix_AutoErrorReport} = 0;

$tablename1 = "dbd_ix_test1";
$tablename2 = "dbd_ix_test2";

# Should not succeed, but doesn't matter.
$dbh->do("DROP TABLE $tablename1");
$dbh->do("DROP TABLE $tablename2");

# These should be fine...
# In Version 7.x and above, MODE ANSI databases interpret DECIMAL as
# DECIMAL(16,0), which is a confounded nuisance.
&stmt_test($dbh, "CREATE TEMP TABLE $tablename1 (id1 INTEGER, " .
		 "id2 SMALLINT, id3 FLOAT, id4 DECIMAL(26), name CHAR(64))");
&stmt_test($dbh, "INSERT INTO $tablename1 VALUES(1122, " .
		 "-234, -3.1415926, 3.7655, 'Hortense HorseRadish')");
# &stmt_test($dbh, "INSERT INTO $tablename1 VALUES(1001002002, " .          # KBC take a look at leading +
# 		 "+342, -3141.5926, 3.7655e25, 'Arbuthnot Artichoke')");    # and exp. notation.
&stmt_test($dbh, "INSERT INTO $tablename1 VALUES(1001002002, " .
		 "342, -3141.5926, '3.7655e25', 'Arbuthnot Artichoke')");
&stmt_test($dbh, "CREATE TEMP TABLE $tablename2 (id INTEGER, name CHAR(64))");
&stmt_test($dbh, "INSERT INTO $tablename2 VALUES(379, 'Mauritz Escher')");
&stmt_test($dbh, "INSERT INTO $tablename2 VALUES(380, 'Salvador Dali')");

# Prepare the first SELECT statement
&stmt_note("# 1st SELECT:\n");
$sth1 = $dbh->prepare("SELECT id1, id2, id3, id4, name FROM $tablename1");
&stmt_fail() if (!defined $sth1);
&stmt_ok(0);

# Prepare the second SELECT statement
&stmt_note("# 2nd SELECT\n");
$sth2 = $dbh->prepare("SELECT id, name FROM $tablename2");
&stmt_fail() if (!defined $sth2);
&stmt_ok(0);

# Open the first cursor
&stmt_note("# Open 1st cursor\n");
&stmt_fail() unless $sth1->execute;
&stmt_ok(0);

# Open the second cursor
&stmt_note("# Open 2nd cursor\n");
&stmt_fail() unless $sth2->execute;
&stmt_ok(0);

while (@row1 = $sth1->fetchrow)
{
    print "# Row1: @row1\n";
	&stmt_ok(0);
    @row2 = $sth2->fetchrow;
    if (defined @row2)
	{
        print "# Row2: @row2\n";
		&stmt_ok(0);
    }
}

# Close the cursors
&stmt_note("# Close 1st cursor\n");
&stmt_fail() unless $sth1->finish;
&stmt_ok(0);
undef $sth1;

&stmt_note("# Close 2nd cursor\n");
&stmt_fail() unless $sth2->finish;
&stmt_ok(0);
undef $sth2;

$dbh->disconnect;

&all_ok();
