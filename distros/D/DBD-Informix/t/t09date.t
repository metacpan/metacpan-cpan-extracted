#!/usr/bin/perl
#
#   @(#)$Id: t09date.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test for DATE data in SELECT
#
#   Copyright 2002-03 IBM
#   Copyright 2007-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

# Set DBDATE to force date format (to ISO 8601 notation).
$ENV{DBDATE} = "Y4MD-";

set_verbosity(0);  # 0 is default; 1 and 2 are significant.
stmt_note "1..11\n";

my $dbh = connect_to_test_database({PrintError => 1});

my($ssdt1, $csdt1) = get_date_as_string($dbh, 12, 31, 2002);
my($ssdt2, $csdt2) = get_date_as_string($dbh,  1,  1, 1970);
my($ssdt3, $csdt3) = get_date_as_string($dbh, 12, 31, 1899);

my $table = "dbd_ix_table1";
$dbh->do(qq"CREATE TEMP TABLE $table(c1 DATE, c2 DATE, c3 DATE)") or stmt_fail;
$dbh->do(qq"INSERT INTO $table
                SELECT MDY(12,31,2002), MDY(1,1,1970), MDY(12,31,1899)
                    FROM 'informix'.SysTables
                    WHERE TabID = 1")
    or stmt_fail;
my $uph = $dbh->prepare("UPDATE $table SET (c1, c2) = (?, ?) WHERE c3 = ?") or stmt_fail;

# This is all OK
my $sql1 = "SELECT * FROM $table";
my $sth1 = $dbh->prepare($sql1) or stmt_fail "Cannot prepare $sql1";
$sth1->execute or stmt_fail "Cannot execute $sql1";
validate_unordered_unique_data($sth1, 'c3',
    {
        $csdt3 => { 'c1' => $csdt1, 'c2' => $csdt2, 'c3' => $csdt3 },
    });

my @vals = (55, 66, 0);
$uph->execute(@vals);

my($ssdt4, $csdt4) = get_date_as_string($dbh,  2, 24, 1900);
my($ssdt5, $csdt5) = get_date_as_string($dbh,  3,  7, 1900);

$sth1->execute or stmt_fail "Cannot execute $sql1";
validate_unordered_unique_data($sth1, 'c3',
    {
        $csdt3 => { 'c1' => $csdt4, 'c2' => $csdt5, 'c3' => $csdt3 },
    });

# At 2002-12-31, TODAY - 46000 yields 1877-01-20.  Expect problems from 2025-12-11 onwards.
my $sql2 = "SELECT c3, c2, c1 FROM $table WHERE c3 BETWEEN TODAY - ? AND TODAY + ?";
my $sth2 = $dbh->prepare($sql2) or stmt_fail;
@vals = (46000,23);
$sth2->execute(@vals) or stmt_fail;
validate_unordered_unique_data($sth2, 'c3',
    {
        $csdt3 => { 'c1' => $csdt4, 'c2' => $csdt5, 'c3' => $csdt3 },
    });

my $sth3 = $dbh->prepare($sql2) or stmt_fail;
$sth3->execute(46000, 23) or stmt_fail;
validate_unordered_unique_data($sth3, 'c3',
    {
        $csdt3 => { 'c1' => $csdt4, 'c2' => $csdt5, 'c3' => $csdt3 },
    });

my $sth4 = $dbh->prepare($sql2) or stmt_fail;
my ($v1, $v2) = (46000, 23);
$sth4->execute($v1, $v2) or stmt_fail;
validate_unordered_unique_data($sth4, 'c3',
    {
        $csdt3 => { 'c1' => $csdt4, 'c2' => $csdt5, 'c3' => $csdt3 },
    });

my $sth5 = $dbh->prepare("SELECT * FROM $table WHERE c3 BETWEEN TODAY - ? AND TODAY - ?") or stmt_fail;
$sth5->execute($v1, $v1) or stmt_fail;
validate_unordered_unique_data($sth5, 'c3', { });

$dbh->disconnect or stmt_fail;

all_ok;
