#!/usr/bin/perl
#
#   @(#)$Id: t92rows.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test basic handling of ROW types
#
#   Copyright 2001    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2004-14 Jonathan Leffler
#
# Extracted from t91udts.t

use strict;
use warnings;
use DBD::Informix::TestHarness;

if (defined $ENV{DBD_INFORMIX_NO_RESOURCE} && $ENV{DBD_INFORMIX_NO_RESOURCE})
{
    stmt_note "1..0 # Skip: requires RESOURCE privileges but DBD_INFORMIX_NO_RESOURCE set.\n";
    exit 0;
}

my ($dbh) = test_for_ius;

$dbh->{ChopBlanks} = 1;
my($table) = "dbd_ix_t92rows";
my($rowtype) = "dbd_ix_t92rowtype";

stmt_note("1..11\n");

sub do_stmt
{
    my($dbh,$stmt) = @_;
    print "# $stmt\n";
    $dbh->do($stmt) or stmt_err;
}

# Drop any pre-existing versions of any of these test types
$dbh->{PrintError} = 0;
do_stmt $dbh, "drop table $table";
do_stmt $dbh, "drop row type $rowtype restrict";
$dbh->{PrintError} = 1;

# Create the types and table
do_stmt $dbh, "create row type $rowtype (i int)";

do_stmt $dbh,
    qq%
     create temp table $table
     (rownum serial not null primary key,
      unnamed row(i int, l lvarchar),
      named $rowtype
     )%;

# Insert some data into the table.
my ($longstr) = "1234567890" x 30;
stmt_test $dbh, qq% insert into $table values (0, row(1, '$longstr'), row(1)::$rowtype); %;

# Check that fetch truncates udts longer than 256 (rather than blowing up)
my ($inserted) = 1;
my ($ins) = qq% insert into $table values (?, ?, ?) %;
stmt_note("# PREPARE: $ins\n");
my ($sth) = $dbh->prepare($ins)
    or stmt_fail;
stmt_ok;

# Check inserting nulls...
my ($null);
#undef $null;
$null = undef;

$sth->execute(2, $null, $null)
    or stmt_fail;
stmt_ok;
stmt_note "# inserted nulls OK\n";

$inserted += $sth->rows;
stmt_fail unless $inserted == 2;

$sth->execute(3, "row(3, 'three')", "row(3)")
    or die;
$inserted += $sth->rows;
$sth->finish;
stmt_note "# inserted $inserted \n";

my ($fetched) = 0;
my ($sel) = qq% select rownum, unnamed, named from $table %;
$sel =~ s/\s+/ /gm;
stmt_note "# PREPARE: $sel\n";
$sth = $dbh->prepare($sel)
    or stmt_fail;
$sth->execute
    or stmt_fail;
stmt_ok;

my ($results) = $sth->fetchall_arrayref;
my ($row);
foreach $row (@$results) {
    $fetched++;
    grep { $_ = "." if !defined $_; } @$row;
    print "# ROW-$fetched: @$row\n";
}
$sth->finish;
# Need to verify fetched data
stmt_note "# fetched $fetched \n";

my ($upd) = qq%
     update $table set unnamed = ?, named = ?
     where rownum = ? and unnamed = ? and named = ?
     %;
$upd =~ s/\s+/ /gm;
stmt_note "# PREPARE: $upd\n";
$sth = $dbh->prepare($upd)
    or stmt_fail;
stmt_ok;

stmt_note "# EXECUTE\n";
$sth->execute("row(10, 'ten')", "row(10)", 1, "row(1, '$longstr')", "row(1)")
    or stmt_fail;
my ($nrows) = $sth->rows;
stmt_note "# updated $nrows \n";
($nrows == 1) ? stmt_ok : stmt_fail;

my ($del) = qq% delete from $table where rownum = ? and unnamed = ? and named = ? %;
$del =~ s/\s+/ /gm;
stmt_note "# PREPARE: $del\n";
$sth = $dbh->prepare($del)
    or stmt_fail;
stmt_ok;

stmt_note "# EXECUTE\n";
$sth->execute(1, "row(10, 'ten')", "row(10)")
    or stmt_fail;
stmt_ok;
$nrows = $sth->rows;
stmt_note "# deleted $nrows\n";
($nrows == 1) ? stmt_ok : stmt_fail;

# Drop new versions of any of these test types
$dbh->do("drop table $table");
$dbh->do("drop row type $rowtype restrict");
stmt_ok;

$dbh->disconnect or die;
stmt_ok;

all_ok;
