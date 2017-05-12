#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Date::QuarterOfYear qw/ quarter_of_year /;

my @TESTS =
(
    # 2013 / 2014
    [ '2013-12-29', ['2013-12-29'],                           [2013, 4] ],
    [ '2013-12-30', [2013, 12, 30],                           [2013, 4] ],
    [ '2000-08-27', [year => 2000, month => 8, day => 27],    [2000, 3] ],
    [ '2011-01-01', [{ year => 2011, month => 1, day => 1}],  [2011, 1] ],
    [ '2012-04-03', ['2012-04-03'],                           [2012, 2] ],
    [ '2014-01-05', [1388962435],                             [2014, 1] ],
);

plan tests => int(@TESTS);

foreach my $test (@TESTS) {
    my ($date, $args_ref, $expected_list) = @$test;
    my ($year, $quarter) = quarter_of_year(@$args_ref);

    ok(   defined($year)
       && defined($quarter)
       && $year    == $expected_list->[0]
       && $quarter == $expected_list->[1],
       "$date is in quarter $expected_list->[0]-Q$expected_list->[1]");
}

