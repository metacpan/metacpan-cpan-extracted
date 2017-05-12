#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Date::Reformat;

my @TESTS = (
    {
        'provided' => '2015-01-14 21:07:31',
        'expected' => '2015-01-14 21:07:31',
        'parameters' => {
            'parser' => {
                'strptime' => '%Y-%m-%d %H:%M:%S',
            },
            'formatter' => {
                'strftime' => '%Y-%m-%d %H:%M:%S',
            },
        },
    },
    {
        'provided' => '2015-01-14 21:07:31',
        'expected' => 'Wed Jan 14 21:07:31 2015',
        'parameters' => {
            'parser' => {
                'strptime' => '%Y-%m-%d %H:%M:%S',
            },
            'defaults' => {
                'day_abbr' => 'Wed',
            },
            'formatter' => {
                'strftime' => '%a %b %d %H:%M:%S %Y',
            },
        },
    },
    {
        'provided' => '2015-01-14 21:07:31',
        'expected' => '1/14/2015 9:07:31 pm',
        'parameters' => {
            'parser' => {
                'strptime' => '%Y-%m-%d %H:%M:%S',
            },
            'formatter' => {
                'strftime' => '%-m/%d/%Y %I:%M:%S %P',
            },
        },
    },
    {
        'provided' => 'Wed Jan 14 21:07:31 2015',
        'expected' => '2015-01-14 21:07:31',
        'parameters' => {
            'parser' => {
                'strptime' => '%a %b %d %H:%M:%S %Y',
            },
            'formatter' => {
                'strftime' => '%Y-%m-%d %H:%M:%S',
            },
        },
    },
    {
        'provided' => '1/14/2015 9:07:31 pm',
        'expected' => '2015-01-14 21:07:31',
        'parameters' => {
            'parser' => {
                'strptime' => '%m/%d/%Y %I:%M:%S %P',
            },
            'formatter' => {
                'strftime' => '%Y-%m-%d %H:%M:%S',
            },
        },
    },
);

plan('tests' => scalar(@TESTS));

foreach my $test (@TESTS) {
    # Set up the parser.
    my $parser = Date::Reformat->new(
        %{ $test->{'parameters'} },
        'debug'     => 1,
    );

    # Parse the date string.
    my $reformatted = $parser->reformat_date($test->{'provided'});

    # Verify the result is what we expect.
    is(
        $reformatted,
        $test->{'expected'},
        "Verify reformatting of: " . ($test->{'provided'} // '<undef>'),
    );
}
