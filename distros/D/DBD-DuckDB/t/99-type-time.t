#perl -T

use strict;
use warnings;

use Test::More;
use Time::Piece;

use lib 't/lib';
use DuckDBTest;
use POSIX;

local $ENV{TZ} = 'UTC';
POSIX::tzset;

my ($std, $dst) = POSIX::tzname;
diag "TZ: STD=$std, DST:$dst";

my $dbh = connect_ok;

my @TESTS = (
    ["SELECT TIME '1992-09-20 11:30:00.123456'",         '11:30:00.123456'],
    ["SELECT TIMETZ '1992-09-20 11:30:00.123456'",       '11:30:00.123456+00'],
    ["SELECT TIMETZ '1992-09-20 11:30:00.123456-02:00'", '13:30:00.123456+00'],
    ["SELECT TIMETZ '1992-09-20 11:30:00.123456+05:30'", '06:00:00.123456+00'],

    # ["SELECT '15:30:00.123456789'::TIME_NS",             '15:30:00.123456789'] ???
);

foreach my $test (@TESTS) {
    is $dbh->selectrow_arrayref($test->[0])->[0], $test->[1], $test->[0];
}

done_testing;
