#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Date::Reformat;

my @TESTS = (
    {
        'expected' => '2015-01-14 21:07:31',
        'formatter' => {
            'sprintf' => '%s-%02d-%02d %02d:%02d:%02d',
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
    {
        'expected' => 'Wed Jan 14 21:07:31 2015',
        'formatter' => {
            'sprintf' => '%s %s %2d %02d:%02d:%02d %d',
            'params'  => [qw(day_abbr month_abbr day hour minute second year)],
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
        'expected' => '1/14/2015 9:07:31 pm',
        'formatter' => {
            'sprintf' => '%d/%d/%d %d:%02d:%02d %s',
            'params'  => [qw(month day year hour_12 minute second am_or_pm)],
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
        "Verify formatting via sprintf template: " . ($test->{'formatter'}->{'sprintf'} // '<undef>'),
    );
}
