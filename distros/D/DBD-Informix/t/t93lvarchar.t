#!/usr/bin/perl
#
#   @(#)$Id: t93lvarchar.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test basic handling of LVARCHAR data
#
#   Copyright 2002-03 IBM
#   Copyright 2005-14 Jonathan Leffler
#
# Beware of IBM Informix ESQL/C bug idsdb00139040 "SQL DESCRIPTOR
# mishandles LVARCVHAR NOT NULL in non-temp tables on 32-bit ESQL/C".
# It seems to hit primarily 32-bit versions of ESQL/C, and versions 2.81
# and 2.90 at that.  Most 64-bit platforms seem to be clean; ESQL/C 2.80
# and 3.00 have both tested cleanly.  The problem did not afflict the
# code if a temp table was used (rather than a real table).
#
# This means you can use DBD::Informix if you do not use LVARCHAR.
# If you do use LVARCHAR, you should upgrade to CSDK 3.00.xC2 or later.
#
# 2011-06-12: There is a residual problem with fetching a distinct type
#             of LVARCHAR with NOT NULL.  This is evaded at the moment.

use strict;
use warnings;
use DBD::Informix::TestHarness;

if (defined $ENV{DBD_INFORMIX_NO_RESOURCE} && $ENV{DBD_INFORMIX_NO_RESOURCE})
{
    stmt_note "1..0 # Skip: requires RESOURCE privileges but DBD_INFORMIX_NO_RESOURCE set.\n";
    exit 0;
}

my ($dbh) = test_for_ius;

print STDERR "Warning! This test may fail for 32-bit ESQL/C 2.81 or 2.90\n"
    if ($dbh->{ix_ProductName} =~ m/ 2\.(81|90)\.U/);

$dbh->{ChopBlanks} = 1;

stmt_note("1..12\n");

my ($table) = "dbd_ix_t93lvarchar";
my ($disttype) = "dbd_ix_t93distoflvc";

sub do_stmt
{
    my($dbh, $stmt) = @_;
    print "# $stmt\n";
    $dbh->do($stmt) or stmt_err;
}

sub verify_fetched_data
{
    my ($dbh, $sel, $res) = @_;
    stmt_note "# PREPARE: $sel\n";
    my ($sth) = $dbh->prepare($sel) or stmt_fail;
    $sth->execute or stmt_fail;
    validate_unordered_unique_data($sth, 's', $res);
    $sth->finish;
}

# Drop any pre-existing versions of the test table and test types
$dbh->{PrintError} = 0;
do_stmt $dbh, "drop table $table";
do_stmt $dbh, "drop type $disttype restrict";
$dbh->{PrintError} = 1;

stmt_test $dbh, "create distinct type $disttype as lvarchar";

my ($stmt) = qq% create table $table (s serial, lvc lvarchar, lvcn lvarchar not null, dlvc $disttype, dlvcn $disttype not null)%;
stmt_test $dbh, $stmt;

my $inserted = 0;

# Insert some data into the table.
my ($longstr) = "1234567890" x 7;
stmt_test $dbh, "insert into $table values (10203040, 'LVC: $longstr', 'LVCN: $longstr', 'DLVC: $longstr', 'DLVCN: $longstr')";
$inserted += 1;

my ($ins) = "insert into $table values (?, ?, ?, ?, ?)";
stmt_note("# PREPARE: $ins\n");
my ($sth) = $dbh->prepare($ins) or stmt_fail;
stmt_ok;

$sth->execute(11213141, "LVC: $longstr", "LVCN: $longstr", "DLVC: $longstr", "DLVCN: $longstr") or stmt_fail;
$inserted += $sth->rows;

# Insert nulls...
my ($null) = undef;
$sth->execute(12223242, $null, "LVCN: $longstr", $null, "DLVCN: $longstr") or stmt_fail;
stmt_ok;
stmt_note "# inserted nulls OK\n";

$inserted += $sth->rows;
stmt_fail unless $inserted == 3;

my $res1 = {
10203040 => { 's' => 10203040, 'lvc' => "LVC: $longstr" },
11213141 => { 's' => 11213141, 'lvc' => "LVC: $longstr" },
12223242 => { 's' => 12223242, 'lvc' => $null           },
};
verify_fetched_data($dbh, "select s, lvc from $table order by s", $res1);

my $res2 = {
10203040 => { 's' => 10203040, 'lvc' => "LVC: $longstr", 'dlvc' => "DLVC: $longstr" },
11213141 => { 's' => 11213141, 'lvc' => "LVC: $longstr", 'dlvc' => "DLVC: $longstr" },
12223242 => { 's' => 12223242, 'lvc' => $null,           'dlvc' => $null            },
};
verify_fetched_data($dbh, "select s, lvc, dlvc from $table order by s", $res2);

my $res3 = {
10203040 => { 's' => 10203040, 'lvc' => "LVC: $longstr", 'dlvc' => "DLVC: $longstr", 'xyz' => 'abc'  },
11213141 => { 's' => 11213141, 'lvc' => "LVC: $longstr", 'dlvc' => "DLVC: $longstr", 'xyz' => 'abc'  },
12223242 => { 's' => 12223242, 'lvc' => $null,           'dlvc' => $null,            'xyz' => 'abc'  },
};
verify_fetched_data($dbh, "select s, lvc, dlvc, 'abc'::lvarchar as xyz from $table order by s", $res3);

my $res4 = {
10203040 => { 's' => 10203040, 'lvc' => "LVC: $longstr", 'dlvc' => "DLVC: $longstr", 'xyz' => 'abc', 'lvcn' => "LVCN: $longstr" },
11213141 => { 's' => 11213141, 'lvc' => "LVC: $longstr", 'dlvc' => "DLVC: $longstr", 'xyz' => 'abc', 'lvcn' => "LVCN: $longstr" },
12223242 => { 's' => 12223242, 'lvc' => $null,           'dlvc' => $null,            'xyz' => 'abc', 'lvcn' => "LVCN: $longstr" },
};
verify_fetched_data($dbh, "select s, lvc, dlvc, 'abc'::lvarchar as xyz, lvcn from $table order by s", $res4);

# This test fails on 'dlvcn' - a NOT NULL distinct type of LVARCHAR, compared with $res4 test
#my $res5 = {
#10203040 => { 's' => 10203040, 'lvc' => "LVC: $longstr", 'dlvc' => "DLVC: $longstr", 'xyz' => 'abc', 'lvcn' => "LVCN: $longstr", 'dlvcn' => "DLVCN: $longstr" },
#11213141 => { 's' => 11213141, 'lvc' => "LVC: $longstr", 'dlvc' => "DLVC: $longstr", 'xyz' => 'abc', 'lvcn' => "LVCN: $longstr", 'dlvcn' => "DLVCN: $longstr" },
#12223242 => { 's' => 12223242, 'lvc' => $null,           'dlvc' => $null,            'xyz' => 'abc', 'lvcn' => "LVCN: $longstr", 'dlvcn' => "DLVCN: $longstr" },
#};
#verify_fetched_data($dbh, "select s, lvc, dlvc, 'abc'::lvarchar as xyz, lvcn, dlvcn from $table order by s", $res5);

# This test fails on 'dlvcn' - a NOT NULL distinct type of LVARCHAR, compared with $res4 test
#my $res5a = {
#10203040 => { 's' => 10203040, 'lvc' => "LVC: $longstr", 'dlvc' => "DLVC: $longstr", 'xyz' => 'abc', 'dlvcn' => "DLVCN: $longstr" },
#11213141 => { 's' => 11213141, 'lvc' => "LVC: $longstr", 'dlvc' => "DLVC: $longstr", 'xyz' => 'abc', 'dlvcn' => "DLVCN: $longstr" },
#12223242 => { 's' => 12223242, 'lvc' => $null,           'dlvc' => $null,            'xyz' => 'abc', 'dlvcn' => "DLVCN: $longstr" },
#};
#verify_fetched_data($dbh, "select s, lvc, dlvc, 'abc'::lvarchar as xyz, dlvcn from $table order by s", $res5a);

# This test fails on 'dlvcn' - a NOT NULL distinct type of LVARCHAR, compared with $res4 test
#my $res5b = {
#10203040 => { 's' => 10203040, 'dlvcn' => "DLVCN: $longstr" },
#11213141 => { 's' => 11213141, 'dlvcn' => "DLVCN: $longstr" },
#12223242 => { 's' => 12223242, 'dlvcn' => "DLVCN: $longstr" },
#};
#verify_fetched_data($dbh, "select s, dlvcn from $table order by s", $res5b);

my $res6 = {
10203040 => { 's' => 10203040, 'lvcn' => "LVCN: $longstr", 'dlvc' => "DLVC: $longstr", 'lvc' => "LVC: $longstr" },
11213141 => { 's' => 11213141, 'lvcn' => "LVCN: $longstr", 'dlvc' => "DLVC: $longstr", 'lvc' => "LVC: $longstr" },
12223242 => { 's' => 12223242, 'lvcn' => "LVCN: $longstr", 'dlvc' => $null,            'lvc' => $null           },
};
verify_fetched_data($dbh, "select s, lvcn, dlvc, lvc from $table order by s", $res6);

# Drop new versions of any of these test types
$dbh->do("drop table $table");
$dbh->do("drop type $disttype restrict");
stmt_ok;

$dbh->disconnect or die;
stmt_ok;

all_ok;
