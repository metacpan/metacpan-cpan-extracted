#!/usr/bin/perl
#
#   @(#)$Id: t14bindcol.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test handling of bind_col and bind_columns for DBD::Informix
#
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use strict;
use warnings;
use DBD::Informix::TestHarness;

# Test install...
my ($dbh) = connect_to_test_database;

stmt_note "1..15\n";
stmt_ok;
my ($table) = "dbd_ix_bind_col";

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

my ($select) = "SELECT * FROM $table ORDER BY Col01";
my $sel = $dbh->prepare($select);

my $pi = 3.141592654;
my $e  = 2.718281828;

# Expected results.
my $row1 = { 'col01' => 1000,
             'col02' => 'Another value',
             'col03' => 987654321,
             'col04' => '1997-02-28 00:11:22.55555',
             'col05' => $e
           };
my $row2 = { 'col01' => 1001,
             'col02' => 'Different data',
             'col03' => 88888888,
             'col04' => '1900-01-01 00:00:00.00000',
             'col05' => '0.000000000'
           };
my $row3 = { 'col01' => 1002,
             'col02' => 'Some other data',
             'col03' => 88888888,
             'col04' => '1900-01-01 00:00:00.00000',
             'col05' => $pi
           };
my $row4 = { 'col01' => 1003,
             'col02' => 'Some other data',
             'col03' => 123456789,
             'col04' => '2000-02-29 23:59:59.99999',
             'col05' => $pi
           };
my $results = { 1000 => $row1, 1001 => $row2, 1002 => $row3, 1003 => $row4 };

{
# Insert data
my ($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?, ?)");
stmt_fail unless $sth;
stmt_ok;

$sth->bind_param(1, 'Another value');
$sth->bind_param(2, 987654321);
$sth->bind_param(3, '1997-02-28 00:11:22.55555');
$sth->bind_param(4, $e);
$sth->execute or stmt_fail;

# Insert second, substantially different, row of data.
$sth->execute('Different data', 88888888, '1900-01-01 00:00:00.00000', 0) or stmt_fail;

# Try some new bind values
$sth->bind_param(1, 'Some other data');
$sth->bind_param(4, $pi);
$sth->execute or stmt_fail;

# Try some more new bind values
$sth->bind_param(2, 123456789);
$sth->bind_param(3, '2000-02-29 23:59:59.99999');
$sth->execute or stmt_fail;
}

# Check that there is one row of data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $results) : stmt_nok;

my ($col01, $col02, $col03, $col04, $col05);

my ($sth) = $dbh->prepare($select);
stmt_fail unless $sth;
stmt_ok;

$sth->bind_col(1, \$col01) or stmt_fail;
$sth->bind_col(2, \$col02) or stmt_fail;
$sth->bind_col(3, \$col03) or stmt_fail;
$sth->bind_col(4, \$col04) or stmt_fail;
$sth->bind_col(5, \$col05) or stmt_fail;
$sth->execute or stmt_fail;

while ($sth->fetch)
{
    my $ref = $$results{$col01};
    (defined $ref &&
        $col01 eq $$ref{col01} &&
        $col02 eq $$ref{col02} &&
        $col03 eq $$ref{col03} &&
        $col04 eq $$ref{col04} &&
        $col05 eq $$ref{col05}) ?  stmt_ok : stmt_nok;
    stmt_note "# 1: $col01, 2: $col02, 3: $col03, 4: $col04, 5: $col05\n";
}

stmt_ok;

my ($val01, $val02, $val03, $val04, $val05);
$sth->bind_columns((\$val01, \$val02, \$val03, \$val04, \$val05)) or stmt_fail;
$sth->execute or stmt_fail;

while ($sth->fetch)
{
    my $ref = $$results{$val01};
    (defined $ref &&
        $val01 eq $$ref{col01} &&
        $val02 eq $$ref{col02} &&
        $val03 eq $$ref{col03} &&
        $val04 eq $$ref{col04} &&
        $val05 eq $$ref{col05}) ?  stmt_ok : stmt_nok;
    stmt_note "# 1: $val01, 2: $val02, 3: $val03, 4: $val04, 5: $val05\n";
}

stmt_ok;

all_ok();
