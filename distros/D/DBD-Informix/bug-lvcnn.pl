#!/usr/bin/perl -w
#
#   @(#)$Id: bug-lvcnn.pl,v 2007.13 2007/06/14 05:19:05 jleffler Exp $
#
#   BUG in LVARCHAR when NOT NULL qualifier applied
#
#   Copyright 2005-07 Jonathan Leffler
#   Reported as CQ bug idsdb00139040 with pure ESQL/C reproduction.

use strict;
use DBD::Informix::TestHarness;

my ($dbh) = &test_for_ius;

$dbh->{ChopBlanks} = 1;

&stmt_note("1..12\n");

my ($table) = "dbd_ix_t93lvarchar";

&test_table("{allowing null}");
&test_table("NOT NULL");

sub test_table
{
my($qualifier) = @_;

# Use TEMP table - bug does not reproduce!
my($stmt) = qq% create table $table (s serial, lvcn lvarchar $qualifier, dlvc lvarchar)%;

stmt_note "\n\n\n#### New Table: Qualifier $qualifier\n";

stmt_test $dbh, $stmt;

my $inserted = 0;

# Insert some data into the table.
my ($longstr) = "1234567890" x 7;
stmt_test $dbh, "insert into $table values (10203040, 'LVCN: $longstr', 'DLVC: $longstr')";
$inserted += 1;

my ($ins) = "insert into $table values (?, ?, ?)";
stmt_note("# PREPARE: $ins\n");
my ($sth) = $dbh->prepare($ins) or stmt_fail;
stmt_ok;

$sth->execute(11213141, "LVCN: $longstr", "DLVC: $longstr") or stmt_fail;
$inserted += $sth->rows;

# Insert nulls...
my ($null) = undef;
$sth->execute(12223242, "LVCN: $longstr", $null) or stmt_fail;
stmt_ok;
stmt_note "# inserted nulls OK\n";

$inserted += $sth->rows;
stmt_fail unless $inserted == 3;

undef $sth;

my $res6 = {
10203040 => { 's' => 10203040, 'lvcn' => "LVCN: $longstr", 'dlvc' => "DLVC: $longstr", },
11213141 => { 's' => 11213141, 'lvcn' => "LVCN: $longstr", 'dlvc' => "DLVC: $longstr", },
12223242 => { 's' => 12223242, 'lvcn' => "LVCN: $longstr", 'dlvc' => $null,            },
};
my($sel) = "select s, lvcn, dlvc from $table order by s";
stmt_note "# PREPARE: $sel\n";
my ($sth) = $dbh->prepare($sel) or stmt_fail;
$sth->execute or stmt_fail;
&validate_unordered_unique_data($sth, 's', $res6);
$sth->finish;

# Drop new versions of any of these test types
$dbh->do("drop table $table");
}

$dbh->disconnect or die;
stmt_ok;
all_ok;
