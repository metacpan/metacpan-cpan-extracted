#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Date::Reformat;

my @TESTS = (
    {
        'expected' => '2015-01-14 21:07:31',
        'transformations' => [
            {
                'from'           => 'hour_12',
                'to'             => 'hour',
                'transformation' => sub {
                    my ($date) = @_;
                    return $date->{'hour'} if defined( $date->{'hour'} );
                    if (lc($date->{'am_or_pm'}) eq 'pm') {
                        if ($date->{'hour_12'} == 12) {
                            $date->{'hour'} = $date->{'hour_12'};
                        }
                        else {
                            $date->{'hour'} = $date->{'hour_12'} + 12;
                        }
                        return $date->{'hour'};
                    }
                    if (lc($date->{'am_or_pm'}) eq 'am') {
                        if ($date->{'hour_12'} == 12) {
                            $date->{'hour'} = 0;
                        }
                        else {
                            $date->{'hour'} = $date->{'hour_12'};
                        }
                        return $date->{'hour'};
                    }
                    return;
                },
            },
        ],
        'date' => {
            'year'     => '2015',
            'month'    => '1',
            'day'      => '14',
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
        'transformations' => $test->{'transformations'},
        'formatter'       => {
            'sprintf' => '%s-%02d-%02d %02d:%02d:%02d',
            'params'  => [qw(year month day hour minute second)],
        },
    );

    # Parse the date string.
    my $reformatted = $parser->format_date($test->{'date'});

    # Verify the result is what we expect.
    is(
        $reformatted,
        $test->{'expected'},
        "Verify formatting transformation from $test->{'transformations'}->[0]->{'from'} to $test->{'transformations'}->[0]->{'to'}",
    );
}
