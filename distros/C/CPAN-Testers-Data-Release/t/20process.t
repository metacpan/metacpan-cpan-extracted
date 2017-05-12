#!/usr/bin/perl -w
use strict;

# testing proces with idfile

use CPAN::Testers::Data::Release;
use Test::More tests => 11;

my @ROWS = (
    q{Crypt-Salt|0.01|9348320|94822eb8-e604-11df-b986-f0a4f41852f9|1|1|1|1|132|0|0|1},
    q{Tk-CursorControl|0.3|115459|00215449-b19f-3f77-b713-d32bba55d77f|2|1|1|1|3|0|0|0},
    q{Tk-CursorControl|0.2|102872|00202862-b19f-3f77-b713-d32bba55d77f|2|1|1|1|2|0|0|0},
    q{Tk-CursorControl|0.4|9333863|94d9dbcc-e541-11df-8d4f-a0612a1db272|1|1|1|1|62|177|1|2},
    q{Tk-CursorControl|0.4|6876296|01134933-b19f-3f77-b713-d32bba55d77f|1|1|2|1|6|11|0|0},
    q{Chess-PGN-Filter|0.11|148442|01148342-b19f-3f77-b713-d32bba55d77f|2|1|1|1|2|1|0|0},
    q{Chess-PGN-Filter|0.06|36343|00136333-b19f-3f77-b713-d32bba55d77f|2|1|1|1|0|1|0|0},
    q{Chess-PGN-Filter|0.09|651677|01036397-b19f-3f77-b713-d32bba55d77f|2|1|1|1|1|1|0|0},
    q{Chess-PGN-Filter|0.07|36370|00136360-b19f-3f77-b713-d32bba55d77f|2|1|1|1|0|1|0|0},
    q{Chess-PGN-Filter|0.05|36261|00136251-b19f-3f77-b713-d32bba55d77f|2|1|1|1|0|1|0|0},
    q{Crypt-Salt|0.01|9348322|94822eb9-e604-11df-b986-f0a4f41852f9|1|1|1|1|132|0|0|1},
);

my $config = 't/_DBDIR/10attributes.ini';
my $idfile = 't/_DBDIR/idfile.txt';

SKIP: {
    skip "Test::Database required for DB testing", 11 unless(-f $config);

    my $obj;
    eval { $obj = CPAN::Testers::Data::Release->new(config => $config) };
    isa_ok($obj,'CPAN::Testers::Data::Release');

    SKIP: {
        skip "Problem creating object", 10 unless($obj);

        is(lastid(),0,'.. lastid is 0 at start');

        my @rows = $obj->{CPANSTATS}{dbh}->get_query('hash','select count(*) as count from release_summary');
        is($rows[0]->{count}, 11, "row count for release_summary");

        $obj->{clean} = 1;
        $obj->process;

        is(lastid(),0,'.. lastid is 0 after clean');

        # a few extras
        insert_records($obj,\@ROWS);

        @rows = $obj->{CPANSTATS}{dbh}->get_query('hash','select count(*) as count from release_summary');
        is($rows[0]->{count}, 21, "row count for release_summary");

        $obj->{clean} = 0;
        $obj->process;  # from start
        
        is(lastid(),9348322,'.. lastid is 0 after from start');

        @rows = $obj->{RELEASE}{dbh}->get_query('hash','select count(*) as count from release');
        is($rows[0]->{count}, 9, "row count for release");

        $obj->process;  # from last

        @rows = $obj->{RELEASE}{dbh}->get_query('hash','select count(*) as count from release');
        is($rows[0]->{count}, 9, "row count for release");

        is(lastid(),9348322,'.. lastid is 0 after from last');

        # with missing id file
        unlink $idfile if -f $idfile;

        $obj->process;  # from last

        @rows = $obj->{RELEASE}{dbh}->get_query('hash','select count(*) as count from release');
        is($rows[0]->{count}, 9, "row count for release");

        is(lastid(),9348322,'.. lastid is 0 after from last');

    }
}

sub lastid {
    my $lastid = 0;

    if(-f $idfile) {
        if(my $fh = IO::File->new($idfile,'r')) {
            my @lines = <$fh>;
            ($lastid) = $lines[0] =~ /(\d+)/;
            $fh->close;
        }
    }

    return $lastid;
}

sub insert_records {
    my ($obj,$rows) = @_;

    my $sql = 'INSERT INTO release_summary (dist,version,id,guid,oncpan,distmat,perlmat,patched,pass,fail,na,unknown) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)';
    for(@$rows) {
        $obj->{CPANSTATS}{dbh}->do_query( $sql, split(/\|/,$_) );
    }
}
