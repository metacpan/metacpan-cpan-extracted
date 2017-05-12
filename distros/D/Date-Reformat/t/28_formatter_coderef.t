#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Date::Reformat;

my @TESTS = (
    {
        'expected' => [31, 7, 21, 14, 0, 115],
        'formatter' => {
            'coderef' => sub {
                my ($year, $month, $day, $hour, $minute, $second) = @_;
                return [
                    $second,
                    $minute,
                    $hour,
                    $day,
                    $month - 1,
                    $year - 1900,
                ];
            },
            'params'  => [qw(year month day hour minute second)],
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
        'formatter' => $test->{'formatter'},
    );

    # Parse the date string.
    my $reformatted = $parser->format_date($test->{'date'});

    # Verify the result is what we expect.
    is_deeply(
        $reformatted,
        $test->{'expected'},
        "Verify formatting via coderef: " . join(', ', @{$test->{'formatter'}->{'params'}}),
    );
}
