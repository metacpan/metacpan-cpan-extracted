#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Date::Reformat;

my @TESTS = (
    {
        'expected' => [qw(2015 1 14 21 7 31)],
        'formatter' => {
            'data_structure' => 'arrayref',
            'params'         => [qw(year month day hour minute second)],
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
    {
        'expected' => [qw(Wed Jan 14 21 7 31 2015)],
        'formatter' => {
            'data_structure' => 'arrayref',
            'params'         => [qw(day_abbr month_abbr day hour minute second year)],
        },
        'date' => {
            'day_abbr'    => 'Wed',
            'month_abbr'  => 'Jan',
            'day'         => '14',
            'hour'        => '21',
            'minute'      => '7',
            'second'      => '31',
            'year'        => '2015',
        },
    },
    {
        'expected' => [qw(1 14 2015 9 7 31 pm)],
        'formatter' => {
            'data_structure' => 'arrayref',
            'params'         => [qw(month day year hour_12 minute second am_or_pm)],
        },
        'date' => {
            'month'    => '1',
            'day'      => '14',
            'year'     => '2015',
            'hour_12'  => '9',
            'minute'   => '7',
            'second'   => '31',
            'am_or_pm' => 'pm',
        },
    },
    {
        'expected' => {
            'year'   => '2015',
            'month'  => '1',
            'day'    => '14',
            'hour'   => '21',
            'minute' => '7',
            'second' => '31',
        },
        'formatter' => {
            'data_structure' => 'hashref',
            'params'         => [qw(year month day hour minute second)],
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
    {
        'expected' => {
            'day_abbr'    => 'Wed',
            'month_abbr'  => 'Jan',
            'day'         => '14',
            'hour'        => '21',
            'minute'      => '7',
            'second'      => '31',
            'year'        => '2015',
        },
        'formatter' => {
            'data_structure' => 'hashref',
            'params'         => [qw(day_abbr month_abbr day hour minute second year)],
        },
        'date' => {
            'day_abbr'    => 'Wed',
            'month_abbr'  => 'Jan',
            'day'         => '14',
            'hour'        => '21',
            'minute'      => '7',
            'second'      => '31',
            'year'        => '2015',
        },
    },
    {
        'expected' => {
            'month'    => '1',
            'day'      => '14',
            'year'     => '2015',
            'hour_12'  => '9',
            'minute'   => '7',
            'second'   => '31',
            'am_or_pm' => 'pm',
        },
        'formatter' => {
            'data_structure' => 'hashref',
            'params'         => [qw(month day year hour_12 minute second am_or_pm)],
        },
        'date' => {
            'month'    => '1',
            'day'      => '14',
            'year'     => '2015',
            'hour_12'  => '9',
            'minute'   => '7',
            'second'   => '31',
            'am_or_pm' => 'pm',
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
        "Verify formatting for $test->{'formatter'}->{'data_structure'}: " . join(', ', @{$test->{'formatter'}->{'params'}}),
    );
}
