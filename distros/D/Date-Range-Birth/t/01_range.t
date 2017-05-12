use strict;
use Test::More tests => 28;

use Date::Simple;
use Date::Range::Birth;

my @tests = (
    [ 2000, 11, 11 ], 20, [ "1979 11 12", "1980 11 11" ],
    [ 2001, 12, 8 ], [ 24, 25 ], [ "1975 12 09", "1977 12 08" ],
    [ 2001, 12, 8 ], 50, [ "1950 12 09", "1951 12 08" ],
    [ 2001, 12, 8 ], [ 50, 50 ], [ "1950 12 09", "1951 12 08" ],
    [ 2001, 12, 8 ], [ 50, 60 ], [ "1940 12 09", "1951 12 08" ],
    [ 2001, 12, 8 ], [ 60, 50 ], [ "1940 12 09", "1951 12 08" ],
    [ 2001, 12, 31 ], 20, [ "1981 01 01", "1981 12 31" ],
);

while (my($date, $age, $test) = splice(@tests, 0, 3)) {
    my $range = Date::Range::Birth->new($age, Date::Simple->new(@$date));
    isa_ok $range, 'Date::Range';
    isa_ok $range, 'Date::Range::Birth';
    is $range->start->format("%Y %m %d"), $test->[0], "format: $test->[0]";
    is $range->end->format("%Y %m %d"), $test->[1], "format: $test->[1]";
}

