#!/usr/bin/perl
#
#   @(#)$Id: t24mcurs.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Tests multiple simultaneous cursors being open
#
#   Copyright 1996    Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#   Copyright 1996-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

print "1..17\n";
my $dbh = connect_to_test_database();
stmt_ok(0);
$dbh->{PrintError} = 0;

my $tablename1 = "dbd_ix_test1";
my $tablename2 = "dbd_ix_test2";

# Should not succeed, but doesn't matter.
$dbh->do("DROP TABLE $tablename1");
$dbh->do("DROP TABLE $tablename2");

# These should be fine...
# In Version 7.x and above, MODE ANSI databases interpret DECIMAL as
# DECIMAL(16,0), which is a confounded nuisance.
stmt_test($dbh, "CREATE TEMP TABLE $tablename1 (id1 INTEGER, " .
         "id2 SMALLINT, id3 FLOAT, id4 DECIMAL(26), name CHAR(64))");
stmt_test($dbh, "INSERT INTO $tablename1 VALUES(1122, " .
         "-234, -3.1415926, 3.7655, 'Hortense HorseRadish')");
stmt_test($dbh, "INSERT INTO $tablename1 VALUES(1001002002, " .
         "+342, -3141.5926, 3.7655e25, 'Arbuthnot Artichoke')");
stmt_test($dbh, "CREATE TEMP TABLE $tablename2 (id INTEGER, name CHAR(64))");
stmt_test($dbh, "INSERT INTO $tablename2 VALUES(379, 'Mauritz Escher')");
stmt_test($dbh, "INSERT INTO $tablename2 VALUES(380, 'Salvador Dali')");

# Prepare the first SELECT statement
stmt_note("# 1st SELECT:\n");
my $sth1 = $dbh->prepare("SELECT id1, id2, id3, id4, name FROM $tablename1");
stmt_fail() if (!defined $sth1);
stmt_ok(0);

# Prepare the second SELECT statement
stmt_note("# 2nd SELECT\n");
my $sth2 = $dbh->prepare("SELECT id, name FROM $tablename2");
stmt_fail() if (!defined $sth2);
stmt_ok(0);

# Open the first cursor
stmt_note("# Open 1st cursor\n");
stmt_fail() unless $sth1->execute;
stmt_ok(0);

# Open the second cursor
stmt_note("# Open 2nd cursor\n");
stmt_fail() unless $sth2->execute;
stmt_ok(0);

my @row1;
my @row2;
while (@row1 = $sth1->fetchrow)
{
    print "# Row1: @row1\n";
    stmt_ok(0);
    @row2 = $sth2->fetchrow;
    if (@row2)
    {
        print "# Row2: @row2\n";
        stmt_ok(0);
    }
}

# Close the cursors
stmt_note("# Close 1st cursor\n");
stmt_fail() unless $sth1->finish;
stmt_ok(0);
undef $sth1;

stmt_note("# Close 2nd cursor\n");
stmt_fail() unless $sth2->finish;
stmt_ok(0);
undef $sth2;

$dbh->disconnect;

all_ok();
