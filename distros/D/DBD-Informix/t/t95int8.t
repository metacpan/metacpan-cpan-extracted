#!/usr/bin/perl
#
#   @(#)$Id: t95int8.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test handling of INT8/SERIAL8
#
#   Based on problem report by Steve Vornbrock <stevev@wamnet.com>.
#
#   Copyright 2003    Steve Vornbrock
#   Copyright 2003    IBM
#   Copyright 2004-14 Jonathan Leffler

use strict;
use warnings;
use DBD::Informix::TestHarness;
use DBD::Informix qw(:ix_types);

my $dbh = test_for_ius;
stmt_note("1..10\n");

my $bignum1 = 4278190080;
my $table = "dbd_ix_testint8";

{   # INT8
$dbh->do(qq%CREATE TEMP TABLE $table(id INT8)%) or stmt_fail;

my $sth = $dbh->prepare(qq%INSERT INTO $table VALUES(?)%);

# JL 2003-07-15: Unfixed bug in DBD::Informix - bound types should be sticky!
stmt_note("# Big number 1 = $bignum1\n");
$sth->bind_param(1, $bignum1, {ix_type => IX_INT8 }) or stmt_fail;
$sth->execute() or stmt_fail;

my $bignum2 = $bignum1 * 23581;
stmt_note("# Big number 2 = $bignum2\n");
$sth->execute($bignum2) or stmt_fail;
stmt_ok;

# Maximum positive INT8 value.
my $bignum3 = '9223372036854775807';
stmt_note("# Big number 3 = $bignum3\n");
$sth->execute($bignum3) or stmt_fail;
stmt_ok;

# Minimum (valid) negative INT8 value.
my $bignum4 = "-$bignum3";
stmt_note("# Big number 4 = $bignum4\n");
$sth->execute($bignum4) or stmt_fail;
stmt_ok;

# Arbitrary negative INT8 value.
my $bignum5 = "-1234567890123456";
stmt_note("# Big number 5 = $bignum5\n");
$sth->execute($bignum5) or stmt_fail;
stmt_ok;

$sth = $dbh->prepare(qq%SELECT id FROM $table%) or stmt_fail;

my $row1 = { 'id' => $bignum1 };
my $row2 = { 'id' => $bignum2 };
my $row3 = { 'id' => $bignum3 };
my $row4 = { 'id' => $bignum4 };
my $row5 = { 'id' => $bignum5 };
my $res2 = { $bignum1 => $row1, $bignum2 => $row2, $bignum3 => $row3, $bignum4 => $row4, $bignum5 => $row5 };

$sth->execute ?  validate_unordered_unique_data($sth, 'id', $res2) : stmt_nok;

$dbh->do(qq%DROP TABLE $table%) or stmt_fail;
}

{   # SERIAL8
$dbh->do(qq%CREATE TEMP TABLE $table(id SERIAL8)%) or stmt_fail;

my $sth = $dbh->prepare(qq%INSERT INTO $table VALUES(?)%);
my $bignum6 = "123456789";
my $rv;

# JL 2003-07-15: Unfixed bug in DBD::Informix - bound types should be sticky!
stmt_note("# Big number 6 = $bignum6\n");
$sth->bind_param(1, $bignum6, {ix_type => IX_INT8 }) or stmt_fail;
$sth->execute() or stmt_fail;
stmt_ok;

# Zero - new serial number
stmt_note("# Zero\n");
$sth->bind_param(1, 0, {ix_type => IX_INT8 }) or stmt_fail;
$sth->execute() or stmt_fail;
$rv = $sth->{ix_serial8};
stmt_note("# New value: $rv\n");
$rv == ($bignum6 + 1) or stmt_fail;
stmt_ok;

# Zero - new serial number
stmt_note("# Zero\n");
$sth->bind_param(1, 0, {ix_type => IX_INT8 }) or stmt_fail;
$sth->execute() or stmt_fail;
$rv = $sth->{ix_serial8};
stmt_note("# New value: $rv\n");
$rv == ($bignum6 + 2) or stmt_fail;
stmt_ok;

$sth = $dbh->prepare(qq%SELECT id FROM $table%) or stmt_fail;

my $row1 = { 'id' => $bignum6 };
my $row2 = { 'id' => $bignum6 + 1 };
my $row3 = { 'id' => $bignum6 + 2 };
my $res2 = { $bignum6 => $row1, ($bignum6 + 1) => $row2, ($bignum6 + 2) => $row3 };

$sth->execute ?  validate_unordered_unique_data($sth, 'id', $res2) : stmt_nok;

$dbh->do(qq%DROP TABLE $table%) or stmt_fail;
stmt_ok;
}

$dbh->disconnect;

all_ok;

__END__
