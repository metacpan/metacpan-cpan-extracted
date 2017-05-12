#!/usr/bin/perl
#
# @(#)$Id: t33holdcurs.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
# Copyright 1996-99,2004 Jonathan Leffler
# Copyright 1999         Bill Rothanburg
# Copyright 2002-03      IBM
# Copyright 2004-14      Jonathan Leffler
#
# Tests hold cursors in transactions

use DBD::Informix::TestHarness;
use strict;
use warnings;

my $dbh = connect_to_test_database();

if ($dbh->{ix_LoggedDatabase} == 0)
{
    stmt_note("1..1\n");
    stmt_note("# No transactions on unlogged database '$dbh->{Name}'\n");
    stmt_ok(0);
    all_ok();
}
stmt_note("1..19\n");
$dbh->{AutoCommit} = 0;
$dbh->{PrintError} = 0;
print_dbinfo($dbh);
stmt_ok(0);

my $tablename1 = "dbd_ix_test1";

# Should not succeed, but doesn't matter.
$dbh->do("DROP TABLE $tablename1");

# These should be fine...
stmt_test($dbh, "CREATE TEMP TABLE $tablename1 (id INTEGER, name CHAR(64))");
stmt_test($dbh, "INSERT INTO $tablename1 VALUES(379, 'Mauritz Escher')");
stmt_test($dbh, "INSERT INTO $tablename1 VALUES(380, 'Salvador Dali')");
stmt_test($dbh, "INSERT INTO $tablename1 VALUES(381, 'Foo Manchu')");

# Without CURSOR WITH HOLD - Should fail at second fetch
#
# Prepare the SELECT statement
stmt_note("# SELECT: ix_CursorWithHold = False\n");
my $sth = $dbh->prepare("SELECT id, name FROM $tablename1");
stmt_fail() if (!defined $sth);
stmt_ok(0);

stmt_note("# Fetch Hold Attrib\n");
my $hold = $sth->{ix_CursorWithHold};
stmt_fail() unless defined $hold;
print "# ix_CursorWithHold = $hold\n";
stmt_ok(0);

# Open the first cursor
stmt_note("# Open cursor\n");
stmt_fail() unless $sth->execute;
stmt_ok(0);

my @row1 = $sth->fetchrow;
if (@row1)
{
    print "# Row1: @row1\n";
    stmt_ok(0);
}
else
{
    print "# Row1: undefined (unexpected behaviour)\n";
    print "# $DBI::errstr\n";
    stmt_fail();
}

stmt_note("# Commit\n");
stmt_fail() unless $dbh->commit;
stmt_ok(0);
my @row2 = $sth->fetchrow;
if ($DBI::err == -400)
{     # The fetch should have errored
    print "# Row2: undefined (expected behaviour)\n";
    print "# $DBI::errstr\n";
    stmt_ok(0);
}
else
{
    print "# Row2: defined (incorrect behaviour - should have failed)\n";
    print "# Row2: @row2\n";
    stmt_fail();
}

# Close the cursors
stmt_note("# Close cursor\n");
stmt_fail() unless $sth->finish;
stmt_ok(0);
undef $sth;

# With CURSOR WITH HOLD - Should pass at second fetch
#
# Prepare the SELECT statement
stmt_note("# SELECT: ix_CursorWithHold = True\n");
$sth = $dbh->prepare("SELECT id, name FROM $tablename1", {'ix_CursorWithHold' => 1});
stmt_fail() if (!defined $sth);
stmt_ok(0);

stmt_note("# Fetch Hold Attrib\n");
$hold = $sth->{ix_CursorWithHold};
stmt_fail() unless defined $hold;
print "# ix_CursorWithHold = $hold\n";
stmt_ok(0);

# Open the first cursor
stmt_note("# Open cursor\n");
stmt_fail() unless $sth->execute;
stmt_ok(0);

@row1 = $sth->fetchrow;
if (@row1)
{
    print "# Row1: @row1\n";
    stmt_ok(0);
}
else
{
    print "# Row1: undefined (unexpected behaviour)\n";
    print "# $DBI::errstr\n";
    stmt_fail();
}

stmt_note("# Commit\n");
stmt_fail() unless $dbh->commit;
stmt_ok(0);
@row2 = $sth->fetchrow;
if (@row2)
{
    print "# Row1: @row2\n";
    stmt_ok(0);
}
else
{
    print "# Row2: undefined (unexpected behaviour)\n";
    stmt_fail();
}

# Close the cursors
stmt_note("# Close cursor\n");
stmt_fail() unless $sth->finish;
stmt_ok(0);
undef $sth;

$dbh->disconnect;

all_ok();
