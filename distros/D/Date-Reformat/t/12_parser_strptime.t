#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Date::Reformat;

my @TESTS = (
    {
        'date_string' => '2015-01-14 21:07:31',
        'parser' => {
            'strptime' => '%Y-%m-%d %H:%M:%S',
        },
        'expected' => {
            'year'   => '2015',
            'month'  => '01',
            'day'    => '14',
            'hour'   => '21',
            'minute' => '07',
            'second' => '31',
        },
    },
    {
        'date_string' => 'Wed Jan 14 21:07:31 2015',
        'parser' => {
            'strptime' => '%a %b %d %H:%M:%S %Y',
        },
        'expected' => {
            'day_abbr'    => 'Wed',
            'month_abbr'  => 'Jan',
            'day'         => '14',
            'hour'        => '21',
            'minute'      => '07',
            'second'      => '31',
            'year'        => '2015',
        },
    },
    {
        'date_string' => '1/14/2015 9:07:31 pm',
        'parser' => {
            'strptime' => '%m/%d/%Y %I:%M:%S %P',
        },
        'expected' => {
            'month'    => '1',
            'day'      => '14',
            'year'     => '2015',
            'hour_12'  => '9',
            'minute'   => '07',
            'second'   => '31',
            'am_or_pm' => 'pm',
        },
    },

    # Test expansion and special characters
    {
        'date_string' => '2015-01-14 T% 21:07:31',
        'parser' => {
            'strptime' => '%F%tT%%%n%T',
        },
        'expected' => {
            'year'   => '2015',
            'month'  => '01',
            'day'    => '14',
            'hour'   => '21',
            'minute' => '07',
            'second' => '31',
        },
    },
    {
        'date_string' => '2015-01-14 21:07:31Z',
        'parser' => {
            'strptime' => '%Y-%m-%d %H:%M:%S%Z',
        },
        'expected' => {
            'year'      => '2015',
            'month'     => '01',
            'day'       => '14',
            'hour'      => '21',
            'minute'    => '07',
            'second'    => '31',
            'time_zone' => 'Z',
        },
    },
);

plan('tests' => scalar(@TESTS));

foreach my $test (@TESTS) {
    # Set up the parser.
    my $parser = Date::Reformat->new(
        'parser'    => $test->{'parser'},
        'debug'     => 1,
    );

    # Parse the date string.
    my $reformatted = $parser->parse_date($test->{'date_string'});

    # Verify the result is what we expect.
    is_deeply(
        $reformatted,
        $test->{'expected'},
        "Verify parsing of: $test->{'date_string'}",
    );
}
