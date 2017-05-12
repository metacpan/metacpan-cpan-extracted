#!/usr/bin/perl -w
use strict;

# testing the reindex process

use CPAN::Testers::Data::Uploads;
use Test::More tests => 9;

my @ROWS = (
    q{cpan|ISHIGAKI|Acme-CPANAuthors-Japanese|0.090202|Acme-CPANAuthors-Japanese-0.090202.tar.gz|1230758955}
);

my $config = 't/_DBDIR/test-config.ini';
my $idfile = 't/_DBDIR/lastid.txt';

SKIP: {
   skip "Test::Database required for DB testing", 9 unless(-f $config);

   my $obj;
    eval { $obj = CPAN::Testers::Data::Uploads->new( config => $config, reindex => 1 ) };
    isa_ok($obj,'CPAN::Testers::Data::Uploads');

    SKIP: {
        skip "Problem creating object", 8 unless($obj);

        my $dbh = $obj->uploads;
        ok($dbh);

        my @rows = $dbh->get_query('hash','select count(*) as count from uploads');
        is($rows[0]->{count}, 63, "row count for uploads");
        @rows = $dbh->get_query('hash','select count(*) as count from ixlatest');
        is($rows[0]->{count}, 0, "row count for ixlatest");

        $obj->process;

        @rows = $dbh->get_query('hash','select count(*) as count from uploads');
        is($rows[0]->{count}, 63, "row count for uploads");
        @rows = $dbh->get_query('hash','select count(*) as count from ixlatest');
        is($rows[0]->{count}, 17, "row count for ixlatest");
        @rows = $dbh->get_query('hash','select * from ixlatest where dist=?','Acme-CPANAuthors-Japanese');
        is($rows[0]->{version}, '0.090101', "old index version");

        # a few extras
        insert_records($dbh,\@ROWS);
        $obj->process;

        @rows = $dbh->get_query('hash','select count(*) as count from ixlatest');
        is($rows[0]->{count}, 17, "row count for ixlatest");
        @rows = $dbh->get_query('hash','select * from ixlatest where dist=?','Acme-CPANAuthors-Japanese');
        is($rows[0]->{version}, '0.090202', "new index version");
    }
}

sub insert_records {
    my ($dbh,$rows) = @_;

    my $sql = 'INSERT INTO uploads (type,author,dist,version,filename,released) VALUES (?,?,?,?,?,?)';
    for(@$rows) {
        $dbh->do_query( $sql, split(/\|/,$_) );
    }
}
