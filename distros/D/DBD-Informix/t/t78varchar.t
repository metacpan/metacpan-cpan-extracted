#!/usr/bin/perl
#
#   @(#)$Id: t78varchar.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Off-by-one bug in VARCHAR when used next to BLOB or CLOB fields
#   Bug, basic test case and diagnosis provided by Tom Girsch.
#   Second source of bug provided by Doug Conrey a day or so earlier,
#   without the diagnosis.
#
#   Copyright 2006    Tom Girsch <tom_girsch@hilton.com>
#   Copyright 2006    Doug Conrey <doug_conrey@oci.com>
#   Copyright 2006-14 Jonathan Leffler

use strict;
use warnings;
use DBD::Informix::TestHarness;
use IO::File;

my $tablename = "dbd_ix_varcharblob";

# Test install...
my $dbh = connect_to_test_database();
my $sbspace;

if (!$dbh->{ix_BlobSupport})
{
    print("1..0 # Skip: No blob support -- no blob testing\n");
    $dbh->disconnect;
    exit(0);
}
elsif (($sbspace = smart_blob_space_name($dbh)) eq "")
{
    print("1..0 # Skip: No smart blob space -- no smart blob vs varchar testing\n");
    $dbh->disconnect;
    exit(0);
}
else
{
    print("1..5\n");
    stmt_ok(0);

    $dbh->do("CREATE TEMP TABLE $tablename(faxid INTEGER, file BLOB, subject VARCHAR(255)) PUT file IN ($sbspace)")
        or stmt_fail;
    stmt_ok(0);

    my $sth = $dbh->prepare("insert into $tablename(faxid, file, subject)
                                     values(?, filetoblob(?, 'client'), ?)");

    my $file = "/tmp/t78varchar.unl";
    my $fh = new IO::File "> $file";
    if (defined $fh)
    {
        print $fh "Test file $file for DBD::Informix - please remove!\n" x 80;
        $fh->close;
    }
    my $result = $sth->execute(382390, "$file", "a") or stmt_fail;
    stmt_ok(0);

    $dbh->do("insert into $tablename(faxid, file, subject) values(382391,
                filetoblob('$file', 'client'), 'a')") or stmt_fail;
    stmt_ok(0);

    unlink $file;
}

$dbh->disconnect ? stmt_ok : stmt_fail;

all_ok();
