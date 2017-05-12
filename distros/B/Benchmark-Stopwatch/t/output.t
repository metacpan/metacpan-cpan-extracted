use strict;
use warnings;

use Test::More 'no_plan';
use Test::LongString;
use Data::Dumper;

use_ok 'Benchmark::Stopwatch';

my $sw = Benchmark::Stopwatch->new;

my %data = (
    start  => 0,
    events => [
        { name => 'one', time => 1 },
        { name => 'two', time => 2.5 },
        { name => 'one', time => 2.501 },
    ],
    stop => 10,
);

$sw->{$_} = $data{$_} for sort keys %data;

my $summary = << "END_SUMMARY";
NAME                        TIME        CUMULATIVE      PERCENTAGE
 one                         1.000       1.000           10.000%
 two                         1.500       2.500           15.000%
 one                         0.001       2.501           0.010%
 _stop_                      7.499       10.000          74.990%
END_SUMMARY

# Check that the report is formatted correctly.
is_string $sw->summary, $summary, "got expected summary";

# warn $summary;
# warn $sw->summary;

# Check that the 'as_data' also produces the expected format.

# Avoid pesky rounding errors.
delete $sw->{events}[2];

is_deeply(
    $sw->as_data,
    {
        start_time => 0,
        stop_time  => 10,
        total_time => 10,
        laps       => [
            { name => 'one', time => 1, cumulative => 1, fraction => 0.10, },
            {
                name       => 'two',
                time       => 1.5,
                cumulative => 2.5,
                fraction   => 0.15,
            },
            {
                name       => '_stop_',
                time       => 7.5,
                cumulative => 10,
                fraction   => 0.75,
            },
        ],
    },
    "as_data works."
) || warn Dumper $sw->as_data;
