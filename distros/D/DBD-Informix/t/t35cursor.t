#!/usr/bin/perl
#
#   @(#)$Id: t35cursor.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test handling of cursors and cursor states
#
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use strict;
use warnings;
use DBD::Informix::TestHarness;

# Test install...
my ($dbh) = connect_to_test_database;

stmt_note "1..18\n";
stmt_ok;
my ($table) = "dbd_ix_cursorstate";

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

# Expected results.
my $row1 = { 'col01' => 1000,
             'col02' => 'Another value',
             'col03' => 987654321,
             'col04' => '2002-02-28 00:11:22.55555',
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
my $res1 = { 1000 => $row1 };
my $res2 = { 1000 => $row1, 1001 => $row2 };
my $res3 = { 1000 => $row1, 1001 => $row2, 1002 => $row3 };
my $res4 = { 1000 => $row1, 1001 => $row2, 1002 => $row3, 1003 => $row4 };

my ($select) = "SELECT * FROM $table ORDER BY Col01";
my ($insert) = "INSERT INTO $table VALUES(0, ?, ?, ?, ?)";

{
# Insert data
my ($sth) = $dbh->prepare($insert);
stmt_fail unless $sth;
stmt_ok;

$sth->bind_param(1, 'Another value');
$sth->bind_param(2, 987654321);
$sth->bind_param(3, '2002-02-28 00:11:22.55555');
$sth->bind_param(4, $e);
$sth->execute or stmt_fail;

# Check that there are now two rows of data, substantially different
$sth->execute('Different data', 88888888, '1900-01-01 00:00:00.00000', 0) or stmt_fail;

# Try some new bind values.  Note that the values from the 'Different
# data' execute are in situ for placeholders 2 and 3.
$sth->bind_param(1, 'Some other data');
$sth->bind_param(4, $pi);
$sth->execute or stmt_fail;

# Try some more new bind values
$sth->bind_param(2, 123456789);
$sth->bind_param(3, '2000-02-29 23:59:59.99999');
$sth->execute or stmt_fail;
stmt_ok;

my $sel = $dbh->prepare($select) or stmt_fail;
stmt_ok;

# Check that there are now four rows of data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res4) : stmt_nok;
}

{
my ($sth) = $dbh->prepare($select) or stmt_fail;

# Finish before execute - no error
$sth->finish or stmt_fail;
stmt_ok;

$sth->execute or stmt_fail;
stmt_ok;

# Finish before any fetch - no error
$sth->finish or stmt_fail;
stmt_ok;

$sth->execute or stmt_fail;
stmt_ok;

my ($row) = $sth->fetchrow_arrayref or stmt_fail;
stmt_ok;

# Finish before all data fetched - no error
$sth->finish or stmt_fail;
stmt_ok;

# Finish again - no error
$sth->finish or stmt_fail;
stmt_ok;

# Explicitly undefine finished statement - no error
undef $sth;
}

{
my ($sth) = $dbh->prepare($select) or stmt_fail;
# Implicitly undefine unexecuted statement - no error
}

{
my ($sth) = $dbh->prepare($select) or stmt_fail;

$sth->execute or stmt_fail;
stmt_ok;
# Implicitly undefine executed statement - no error
}

{
my ($sth) = $dbh->prepare($select) or stmt_fail;

$sth->execute or stmt_fail;
stmt_ok;

my ($row) = $sth->fetchrow_arrayref or stmt_fail;
stmt_ok;
# Implicitly undefine open cursor - no error
}

{
my ($sth) = $dbh->prepare($insert);
stmt_fail unless $sth;
stmt_ok;

# Finish a non-cursory statement - no error
$sth->finish or stmt_fail;
stmt_ok;
# Implicitly undefine prepard statement - no error
}

all_ok();
