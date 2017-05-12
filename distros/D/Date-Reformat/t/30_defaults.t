#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Date::Reformat;

my @TESTS = (
    {
        'expected' => '2015-01-14 21:07:31 America/New_York',
        'defaults' => {
            'time_zone' => 'America/New_York',
        },
        'date' => {
            'year'   => '2015',
            'month'  => '1',
            'day'    => '14',
            'hour'   => '21',
            'minute' => '7',
            'second' => '31',
        },
    },
);

plan('tests' => scalar(@TESTS));

foreach my $test (@TESTS) {
    # Set up the parser.
    my $parser = Date::Reformat->new(
        'formatter' => {
            'sprintf' => '%s-%02d-%02d %02d:%02d:%02d %s',
            'params'  => [qw(year month day hour minute second time_zone)],
        },
        'defaults' => $test->{'defaults'},
    );

    # Parse the date string.
    my $reformatted = $parser->format_date($test->{'date'});

    # Verify the result is what we expect.
    is(
        $reformatted,
        $test->{'expected'},
        "Verify formatting with default value: " . ($test->{'defaults'}->{'time_zone'} // '<undef>'),
    );
}
