#!/usr/bin/perl
#
#   @(#)$Id: t13bindref.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test handling of bind_param_inout for DBD::Informix
#
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use strict;
use warnings;
use DBD::Informix::TestHarness;

stmt_note "1..0 # Skip: bind_param_inout not supported by DBD::Informix\n";
exit;

# Test install...
my ($dbh) = connect_to_test_database;

stmt_note "1..9\n";
stmt_ok;
my ($table) = "dbd_ix_bind_param";

# Create table for testing
stmt_test $dbh, qq{
CREATE TEMP TABLE $table
(
    Col01   SERIAL(1000) NOT NULL,
    Col02   CHAR(20) NOT NULL,
    Col03   INTEGER NOT NULL,
    Col04   DATETIME YEAR TO FRACTION(5) NOT NULL,
    Col05   DECIMAL(10,9) NOT NULL
)
};

my $pi = 3.141592654;
my $e  = 2.718281828;
my ($select) = "SELECT * FROM $table";

my $sel = $dbh->prepare($select) or stmt_fail;
stmt_ok;

my $sth = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?, ?)");
stmt_fail unless $sth;
stmt_ok;

# Expected results.
my $row1 = { 'col01' => 1000,
             'col02' => 'Another value',
             'col03' => 987654321,
             'col04' => '1997-02-28 00:11:22.55555',
             'col05' => 2.718281828
           };
my $row2 = { 'col01' => 1001,
             'col02' => 'Another value',
             'col03' => 987654321,
             'col04' => '1997-02-28 00:11:22.55555',
             'col05' => 2.718281828
           };
my $row3 = { 'col01' => 1002,
             'col02' => 'Some other data',
             'col03' => 987654321,
             'col04' => '1997-02-28 00:11:22.55555',
             'col05' => 3.141592654
           };
my $row4 = { 'col01' => 1003,
             'col02' => 'Some other data',
             'col03' => 123456789,
             'col04' => '2000-02-29 23:59:59.99999',
             'col05' => 3.141592654
           };
my $res1 = { 1000 => $row1 };
my $res2 = { 1000 => $row1, 1001 => $row2 };
my $res3 = { 1000 => $row1, 1001 => $row2, 1002 => $row3 };
my $res4 = { 1000 => $row1, 1001 => $row2, 1002 => $row3, 1003 => $row4 };

# Insert a row of values.

my ($col02, $col03, $col04, $col05);

$sth->bind_param_inout(1, \$col02, 30);
$sth->bind_param_inout(2, \$col03, 30);
$sth->bind_param_inout(3, \$col04, 30);
$sth->bind_param_inout(4, \$col05, 30);

$col02 = 'Another value';
$col03 = 987654321;
$col04 = '1997-02-28 00:11:22.55555';
$col05 = $e;

stmt_fail() unless $sth->execute;

# Check that there is one row of data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res1) : stmt_nok;

# Check that there are now two rows of data, substantially the same
stmt_fail() unless $sth->execute;
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res2) : stmt_nok;

# Try some new bind values
$col02 = 'Some other data';
$col05 = $pi;
stmt_fail() unless $sth->execute;

# Check that there are now three rows of data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res3) : stmt_nok;

# Try some more new bind values
$col03 = 123456789;
$col03 = '2000-02-29 23:59:59.99999';
stmt_fail() unless $sth->execute;

# Check that there are now four rows of data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res4) : stmt_nok;

$dbh->disconnect ? stmt_ok : stmt_nok;

all_ok();
