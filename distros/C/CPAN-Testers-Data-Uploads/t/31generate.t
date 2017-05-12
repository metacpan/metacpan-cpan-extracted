#!/usr/bin/perl -w
use strict;

# testing the generate process

use CPAN::Testers::Data::Uploads;
use Test::More tests => 7;

my $config = 't/_DBDIR/test-config.ini';
my $idfile = 't/_DBDIR/lastid.txt';

SKIP: {
    skip "Test::Database required for DB testing", 7 unless(-f $config);

    my $obj;
    eval { $obj = CPAN::Testers::Data::Uploads->new( config => $config, generate => 1 ) };
    isa_ok($obj,'CPAN::Testers::Data::Uploads');

    SKIP: {
        skip "Problem creating object", 6 unless($obj);

        my $dbh = $obj->uploads;
        ok($dbh);

        # clean DB
        $dbh->do_query('DELETE FROM uploads');
        $dbh->do_query('DELETE FROM ixlatest');

        my @rows = $dbh->get_query('hash','select count(*) as count from uploads');
        is($rows[0]->{count}, 0, "row count for uploads");
        @rows = $dbh->get_query('hash','select count(*) as count from ixlatest');
        is($rows[0]->{count}, 0, "row count for ixlatest");

        $obj->process;

        @rows = $dbh->get_query('hash','select count(*) as count from uploads');
        is($rows[0]->{count}, 63, "row count for uploads");
        @rows = $dbh->get_query('hash','select count(*) as count from ixlatest');
        is($rows[0]->{count}, 17, "row count for ixlatest");
        @rows = $dbh->get_query('hash','select * from ixlatest where dist=?','Acme-CPANAuthors-Japanese');
        is($rows[0]->{version}, '0.090101', "old index version");
    }
}
