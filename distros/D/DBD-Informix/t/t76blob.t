#!/usr/bin/perl
#
#   @(#)$Id: t76blob.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Reproduce 451 errors with Perl.
#
#   Copyright 1999    Bibliotech Ltd., 631-633 Fulham Rd., London SW6 5UQ.
#   Copyright 1999    Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

my $tablename = "dbd_ix_blobtest";

# Test install...
my $dbh = connect_to_test_database();

if (!$dbh->{ix_BlobSupport})
{
    print("1..0 # Skip: No blob support -- no blob testing\n");
    $dbh->disconnect;
    exit(0);
}
else
{
    print("1..5\n");
    stmt_ok(0);

    # Create temp table.
    $dbh->do(qq{ create temp table $tablename (col1 text in table, col2 int)})
        or stmt_fail();
    stmt_ok(0);

    # Insert a couple of rows. Note the first row
    # is a single '' (empty string, not a null) and
    # the second row is a string containing data.

    $dbh->do("insert into $tablename (col1, col2) values (?, 1)", undef, '')
        or stmt_fail();
    $dbh->do("insert into $tablename (col1, col2) values (?, 2)", undef, 'abc')
        or stmt_fail();
    $dbh->do("insert into $tablename (col1, col2) values (?, 3)", undef, 'def')
        or stmt_fail();
    stmt_ok(0);

    # Should a zero length blob be treated as undefined/NULL by Perl?
    my $row1 = { 'col2' => 1, 'col1' => undef };
    my $row2 = { 'col2' => 2, 'col1' => 'abc' };
    my $row3 = { 'col2' => 3, 'col1' => 'def' };
    my $res1 = { 1 => $row1, 2 => $row2, 3 => $row3 };

    # Select the rows. Order them so that the row
    # containing the empty string blob is fetched first.
    my $sth = $dbh->prepare("select col1, col2 from $tablename order by col2")
        or stmt_fail();
    $sth->execute() or stmt_fail();

    validate_unordered_unique_data($sth, 'col2', $res1);
}

$dbh->disconnect ? stmt_ok : stmt_fail;

all_ok();
