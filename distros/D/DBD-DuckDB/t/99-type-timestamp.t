#perl -T

use strict;
use warnings;

use Test::More;
use Time::Piece;

use lib 't/lib';
use DuckDBTest;
use POSIX;

SCOPE: {

    local $ENV{TZ} = 'Europe/Berlin';
    POSIX::tzset;

    my ($std, $dst) = POSIX::tzname;
    diag "TZ: STD=$std, DST:$dst";

    my $dbh = connect_ok;

    my @TESTS = (
        ["SELECT timezone('America/Denver', TIMESTAMP '2001-02-16 20:38:40')",      '2001-02-17 04:38:40+01'],
        ["SELECT timezone('America/Denver', TIMESTAMPTZ '2001-02-16 04:38:40')",    '2001-02-15 20:38:40'],
        ["SELECT timezone('UTC', TIMESTAMP '2001-02-16 20:38:40+00:00')",           '2001-02-16 21:38:40+01'],
        ["SELECT timezone('UTC', TIMESTAMPTZ '2001-02-16 04:38:40 Europe/Berlin')", '2001-02-16 03:38:40'],
    );

    foreach my $test (@TESTS) {
        is $dbh->selectrow_arrayref($test->[0])->[0], $test->[1], $test->[0];
    }

}

SCOPE: {

    local $ENV{TZ} = 'UTC';
    POSIX::tzset;

    my ($std, $dst) = POSIX::tzname;
    diag "TZ: STD=$std, DST:$dst";

    my $dbh = connect_ok;

    my @TESTS = (
        ["SELECT TIMESTAMP_NS '1992-09-20 11:30:00.123456789'", '1992-09-20 11:30:00.123456789'],
        ["SELECT TIMESTAMP '1992-09-20 11:30:00.123456789'",    '1992-09-20 11:30:00.123456'],
        ["SELECT TIMESTAMP_MS '1992-09-20 11:30:00.123456789'", '1992-09-20 11:30:00.123'],
        ["SELECT TIMESTAMP_S '1992-09-20 11:30:00.123456789'",  '1992-09-20 11:30:00'],

        # TODO: This test work fine if TZ is set to UTC in the shell environment (eg. TZ=UTC prove -lv t/*.t)
        # ["SELECT TIMESTAMPTZ '1992-09-20 11:30:00.123456789'",       '1992-09-20 11:30:00.123456+00'],
        ["SELECT TIMESTAMPTZ '1992-09-20 12:30:00.123456789+01:00'", '1992-09-20 11:30:00.123456+00'],

        ["SELECT '-infinity'::TIMESTAMP", '-290308-12-21 19:59:06.224193'],
        ["SELECT 'epoch'::TIMESTAMP",     '1970-01-01 00:00:00'],
        ["SELECT 'infinity'::TIMESTAMP",  '294247-01-10 04:00:54.775807'],

        ["SELECT TIMESTAMP '1992-03-22 01:02:03' + INTERVAL 5 DAY", '1992-03-27 01:02:03'],
        ["SELECT TIMESTAMP '1992-03-27' - TIMESTAMP '1992-03-22'",  "5 days"],
        ["SELECT TIMESTAMP '1992-03-22 01:02:03' - INTERVAL 5 DAY", '1992-03-17 01:02:03'],
    );

    foreach my $test (@TESTS) {
        is $dbh->selectrow_arrayref($test->[0])->[0], $test->[1], $test->[0];
    }
}

done_testing;
