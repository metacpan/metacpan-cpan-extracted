#!/usr/bin/perl -w
use strict;

# testing process with no id file

use CPAN::Testers::Data::Release;
use Test::More tests => 10;

my @ROWS = (
    q{Crypt-Salt|0.01|9348320|94812eb8-e604-11df-b986-f0a4f41852f9|1|1|1|1|132|0|0|1},
    q{Tk-CursorControl|0.3|115449|00115449-b19f-3f77-b713-d32bba55d77f|2|1|1|1|3|0|0|0},
    q{Tk-CursorControl|0.2|102862|00102862-b19f-3f77-b713-d32bba55d77f|2|1|1|1|2|0|0|0},
    q{Tk-CursorControl|0.4|9333853|93d9dbcc-e541-11df-8d4f-a0612a1db272|1|1|1|1|62|177|1|2},
    q{Tk-CursorControl|0.4|6876196|00134933-b19f-3f77-b713-d32bba55d77f|1|1|2|1|6|11|0|0},
    q{Chess-PGN-Filter|0.11|148342|00148342-b19f-3f77-b713-d32bba55d77f|2|1|1|1|2|1|0|0},
    q{Chess-PGN-Filter|0.06|36333|00036333-b19f-3f77-b713-d32bba55d77f|2|1|1|1|0|1|0|0},
    q{Chess-PGN-Filter|0.09|651577|00036397-b19f-3f77-b713-d32bba55d77f|2|1|1|1|1|1|0|0},
    q{Chess-PGN-Filter|0.07|36360|00036360-b19f-3f77-b713-d32bba55d77f|2|1|1|1|0|1|0|0},
    q{Chess-PGN-Filter|0.05|36251|00036251-b19f-3f77-b713-d32bba55d77f|2|1|1|1|0|1|0|0},
    q{Crypt-Salt|0.01|9348321|94812eb9-e604-11df-b986-f0a4f41852f9|1|1|1|1|132|0|0|1},
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


my $config = 't/_DBDIR/test-config.ini';
my $idfile = 't/_DBDIR/idfile.txt';
unlink $idfile if -f $idfile;

SKIP: {
    skip "Test::Database required for DB testing", 10 unless(-f $config);

    my $obj;
    eval { $obj = CPAN::Testers::Data::Release->new(config => $config) };
    isa_ok($obj,'CPAN::Testers::Data::Release');

    SKIP: {
        skip "Problem creating object", 9 unless($obj);

        # reset DB
        $obj->{CPANSTATS}{dbh}->do_query('delete from release_summary');
        insert_records($obj,\@ROWS);

        is(-f $idfile,undef,'.. no idfile at start');

        my @rows = $obj->{CPANSTATS}{dbh}->get_query('hash','select count(*) as count from release_summary');
        is($rows[0]->{count}, 22, "row count for release_summary");

        $obj->backup_from_start;  # from start
        
        is(-f $idfile,undef,'.. no idfile after from start');

        @rows = $obj->{RELEASE}{dbh}->get_query('hash','select count(*) as count from release');
        is($rows[0]->{count}, 9, "row count for release");

        $obj->backup_from_last;  # from last

        @rows = $obj->{RELEASE}{dbh}->get_query('hash','select count(*) as count from release');
        is($rows[0]->{count}, 9, "row count for release");

        is(-f $idfile,undef,'.. no idfile after from last');


        # check logs
        my $log = 't/_DBDIR/release.log';
        my $fh = IO::File->new($log,'r');
        SKIP: {
            skip "Unable to open log file: $!", 3 unless($fh);

            my $text;
            while (<$fh>) { $text .= $_ }

            like($text, qr!\d+/\d+/\d+ \d+:\d+:\d+ Create backup database!);
            like($text, qr!\d+/\d+/\d+ \d+:\d+:\d+ Find new start!);
            like($text, qr!\d+/\d+/\d+ \d+:\d+:\d+ Backup completed!);

            $fh->close;
        }
    }
}

sub insert_records {
    my ($obj,$rows) = @_;

    my $sql = 'INSERT INTO release_summary (dist,version,id,guid,oncpan,distmat,perlmat,patched,pass,fail,na,unknown) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)';
    for(@$rows) {
        $obj->{CPANSTATS}{dbh}->do_query( $sql, split(/\|/,$_) );
    }
}
