#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Date::Reformat;

my @TESTS = (
    {
        'date_string' => '2015-01-14 21:07:31',
        'parser' => {
            'regex'  => qr/(\d{4})-(\d\d)-(\d\d) (\d\d?):(\d\d):(\d\d)/,
            'params' => [qw(year month day hour minute second)],
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
            'regex'  => qr/(\w+) (\w+) (\d\d?) (\d\d?):(\d\d):(\d\d) (\d{4})/,
            'params' => [qw(day_abbr month_abbr day hour minute second year)],
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
            'regex'  => qr|(\d\d?)/(\d\d?)/(\d{4}) (\d\d?):(\d\d):(\d\d) (\w+)|,
            'params' => [qw(month day year hour_12 minute second am_or_pm)],
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

    # Named captures.
    {
        'date_string' => '2015-01-14 21:07:31',
        'parser' => {
            'regex'  => qr/(?<year>\d{4})-(?<month>\d\d)-(?<day>\d\d) (?<hour>\d\d?):(?<minute>\d\d):(?<second>\d\d)/,
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
);

plan('tests' => scalar(@TESTS));

foreach my $test (@TESTS) {
    # Set up the parser.
    my $parser = Date::Reformat->new(
        'parser'    => $test->{'parser'},
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
