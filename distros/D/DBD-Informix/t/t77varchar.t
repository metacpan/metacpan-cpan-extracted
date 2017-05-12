#!/usr/bin/perl
#
#   @(#)$Id: t77varchar.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Off-by-one bug in VARCHAR when used next to BYTE or TEXT fields
#   Bug, basic test case and diagnosis provided by Tom Girsch.
#   Second source of bug provided by Doug Conrey a day or so earlier,
#   without the diagnosis.
#
#   Copyright 2006    Tom Girsch <tom_girsch@hilton.com>
#   Copyright 2006    Doug Conrey <doug_conrey@oci.com>
#   Copyright 2006-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

my $tablename = "dbd_ix_varcharblob";

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
    print("1..4\n");
    stmt_ok(0);

    # Create temp table.
    $dbh->do(qq{ create temp table $tablename (col1 varchar(64), col2 text in table)})
        or stmt_fail;
    stmt_ok(0);

    # Insert a couple of rows. Note the first row
    # is a single '' (empty string, not a null) and
    # the second row is a string containing data.

    {
    my $sth = $dbh->prepare("insert into $tablename values(?, ?)") or stmt_fail;
    $sth->bind_param(1, 'LOBSTER');
    $sth->bind_param(2, '');
    $sth->execute or stmt_fail;
    }

    # Should a zero length blob be treated as undefined/NULL by Perl?
    my $row1 = { 'col1' => 'LOBSTER', 'col2' => undef };
    my $res1 = { 'LOBSTER' => $row1 };

    # Select the row.
    my $sth = $dbh->prepare("select col1, col2 from $tablename order by col1")
        or stmt_fail;
    $sth->execute() or stmt_fail;

    validate_unordered_unique_data($sth, 'col1', $res1);
}

$dbh->disconnect ? stmt_ok : stmt_fail;

all_ok();
