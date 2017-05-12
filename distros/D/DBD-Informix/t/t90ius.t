#!/usr/bin/perl
#
#   @(#)$Id: t90ius.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test basic handling of IUS data types
#
#   Copyright 1998-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

my ($dbh) = test_for_ius;

stmt_note("1..4\n");

$dbh->{ChopBlanks} = 1;

# Create table with IUS data types
my ($tab) = "dbd_ix_ius_table";
stmt_fail() unless
    $dbh->do(qq%
        CREATE TEMP TABLE $tab
        (
            PKEY    SERIAL8 NOT NULL PRIMARY KEY,
            Col1    BOOLEAN,
            Col2    LVARCHAR,
            Col3    INT8,
            Col4    CHAR(20)
        )
    %);
stmt_ok();

# Insert data into table.

my $lvc = "abc" x 20;
my ($expect) = 0;

stmt_fail() unless
    $dbh->do(qq%
        INSERT INTO $tab VALUES(0, 'T', '$lvc', 998877665544, 'Silly String')
    %);
$expect++;

stmt_fail() unless
    $dbh->do(qq%
        INSERT INTO $tab VALUES(0, 'T', '', 998877665544, 'Empty LVARCHAR')
    %);
$expect++;

stmt_fail() unless
    $dbh->do(qq%
        INSERT INTO $tab VALUES(0, 'T', 'ZZ', 998877665544, 'Two-char LVARCHAR')
    %);
$expect++;

stmt_fail() unless
    $dbh->do(qq%
        INSERT INTO $tab VALUES(0, 'T', 'Q', 998877665544, 'One-char LVARCHAR')
    %);
$expect++;

stmt_fail() unless
    $dbh->do(qq%
        INSERT INTO $tab VALUES(0, NULL, NULL, NULL, 'NULL values')
    %);
$expect++;

stmt_fail() unless
    $dbh->do(qq%
        INSERT INTO $tab VALUES(0, 'F', 'Empty CHAR string', 100, '')
    %);
$expect++;

$lvc = time . $lvc;
stmt_fail() unless
    $dbh->do(qq%
        INSERT INTO $tab VALUES(0, 'F', '$lvc', 998877665543, 'More Data')
    %);
$expect++;

sub irand { return int rand 1000000; }

stmt_fail() unless
    my $sth = $dbh->prepare(qq% INSERT INTO $tab VALUES(?, ?, ?, ?, ?) %);
$lvc = ( irand . "x" ) x 10 . irand;
stmt_fail() unless
    $sth->execute(91234567890, 't', $lvc, irand, irand);
$expect++;
$lvc = ( irand . "x" ) x 8 . irand;
stmt_fail() unless
    $sth->execute(0, 'f', $lvc, irand, irand);
$expect++;

stmt_ok();

# Fetch and print the data.
my ($data,$row);
stmt_fail() unless
    ($sth = $dbh->prepare("SELECT * FROM $tab"));
stmt_fail() unless
    $sth->execute;
stmt_fail() unless
    ($data = $sth->fetchall_arrayref);

my ($cnt) = 0;
foreach $row (@$data)
{
    my ($pad, $n, $i) = ("# ", $#$row + 1, 0);
    for ($i = 0; $i < $n; $i++)
    {
        print $pad, (defined $$row[$i]) ? "<$$row[$i]>" : "NULL";
        $pad = " :: ";
    }
    print " ::\n";
    $cnt++;
}

stmt_fail("Wrong number of rows ($cnt) returned ($expect expected)!\n") if ($cnt != $expect);
stmt_ok();

# Clean up
undef $sth;
stmt_fail() unless $dbh->disconnect;
undef $dbh;
stmt_ok();

all_ok();
