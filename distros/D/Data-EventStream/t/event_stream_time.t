use Test::Most;
use Test::FailWarnings;

use Data::EventStream;

use lib 't/lib';
use TimeAverager;
use TestStream;

my %params = (
    t3 => { duration => '3', },
    t5 => { duration => '5', },
    b4 => { duration => '4', batch => 1, },
    b3 => { duration => '3.5', batch => 1, start_time => 9.5, },
);

my @events = (
    {
        time => 11.3,
        val  => 1,
        ins  => { t3 => 1, t5 => 1, b4 => 1, b3 => 1, },
        stream => { next_leave => 12, },
    },
    {
        time   => 12,
        resets => { b4 => 1, },
        vals   => { t3 => 1, t5 => 1, b4 => 1, b3 => 1, },
        stream => { next_leave => 13, },
    },
    {
        time => 12.7,
        val  => 3,
        ins  => { t3 => 1, t5 => 1, b4 => 1, b3 => 1, },
    },
    {
        time   => 13,
        resets => { b3 => 1.35294, },
        vals   => { t3 => 1.35294, t5 => 1.35294, b4 => 1.6, b3 => 3, },
        stream => { next_leave => 14.3, },
    },
    {
        time => 13.2,
        val  => 4,
        ins  => { t3 => 1.52632, t5 => 1.52632, b4 => 1.83333, b3 => 3, },
    },
    {
        time => 15,
        outs => { t3 => 2.72973, },
        vals => { t3 => 3.13333, t5 => 2.72973, b4 => 3.13333, b3 => 3.9, },
        add_aggregator => {
            d5 => { duration => 5, batch => 1, disposable => 1, },
        },
        stream => { next_leave => 15.7, },
    },
    {
        time   => 16,
        resets => { b4 => 3.35, },
        outs   => { t3 => 3.84848, },
        vals   => { t3 => 3.93333, t5 => 3, b4 => 4, b3 => 3.93333, d5 => 'NaN', },
        stream => { next_leave => 16.2, },
    },
    {
        time   => 17.1,
        val    => 8,
        resets => { b3 => 3.94286, },
        outs   => { t3 => 4, t5 => 3.18966, },
        ins    => { t3 => 4, t5 => 3.54, b4 => 4, b3 => 4, d5 => 8, },
        stream => { next_leave => 17.7, },
    },
    {
        time => 19.2,
        val  => 5,
        outs => { t5 => [ 5.21538, 5.4, ], },
        ins  => { t3 => 6.8, t5 => 5.68, b4 => 6.625, b3 => 7.11111, d5 => 8, },
        stream => { next_leave => 20, },
    },
    {
        time   => 20,
        resets => { b4 => 6.3, b3 => 6.62857, d5 => 7.17241, },
        vals   => { t3 => 7.06667, t5 => 5.84, b4 => 5, b3 => 5, },
        stream => { next_leave => 20.1, },
    },
    {
        time => 20.8,
        val  => 2,
        outs => { t3 => 6.7027, },
        ins  => { t3 => 6.4, t5 => 6, b4 => 5, b3 => 5, },
        stream => { next_leave => 22.1, },
    },
    {
        time => 23,
        outs => { t3 => 3.26316, t5 => 4.94915, },
        vals => { t3 => 2.8, t5 => 4.4, b4 => 2.8, b3 => 2.8, },
        stream => { next_leave => 23.5, },
    },
    {
        time   => 30,
        val    => 4,
        resets => { b4 => [ 2.6, 2, ], b3 => [ 2.68571, 2, ], },
        outs => { t3 => 2, t5 => [ 2.44444, 2 ], },
        ins    => { t3         => 2, t5 => 2, b4 => 2, b3 => 2, },
        stream => { next_leave => 30.5, },
    },
    {
        time   => 33,
        val    => 1,
        resets => { b4 => 3, b3 => 2.28571, },
        outs   => { t3         => 4, },
        ins    => { t3         => 4, t5 => 3.2, b4 => 4, b3 => 4, },
        stream => { next_leave => 34, },
    },
    {
        time => 33.5,
        val  => 7,
        ins  => { t3 => 3.5, t5 => 3.1, b4 => 3, b3 => 3.5, },
    },
    {
        time   => 35.2,
        val    => 9,
        resets => { b3 => 4, },
        outs   => { t5 => 4.69231, },
        ins    => { t3 => 5.2, t5 => 4.72, b4 => 5.125, b3 => 7, },
        stream => { next_leave => 36, },
    },
    {
        time   => 36,
        resets => { b4 => 5.9, },
        outs   => { t3 => 6.53333, },
        vals   => { t3 => 6.53333, t5 => 5.52, b4 => 9, b3 => 7.8, },
        stream => { next_leave => 36.5, },
    },
    {
        time   => 45,
        resets => { b4 => [ 9, 9, ], b3 => [ 8.31429, 9, 9, ], },
        outs   => { t3 => [ 8.70435, 9 ], t5 => [ 8.38333, 8.70435, 9 ], },
        vals   => { t3         => 9, t5 => 9, b4 => 9, },
        stream => { next_leave => 48, },
    },
);

TestStream->new(
    aggregator_class     => 'TimeAverager',
    aggregator_params    => \%params,
    events               => \@events,
    start_time           => 8,
    time_sub             => sub { $_[0]->{time} },
    expected_time_length => 5,
)->run;

done_testing;
