use Test::Most;
use Test::FailWarnings;

use Data::EventStream;

use lib 't/lib';
use MinMax;
use TestStream;

my %params = (
    t10 => { duration => 10, },
    c3  => { count    => 3, },
    ct  => { duration => 10, count => 3, },
    ctb => { duration => 10, count => 3, batch => 1, },
);

my @events = (
    {
        time => 3,
        val  => 52,
        ins  => { t10 => "52,52,1", c3 => "52,52,3", ct => "52,52,1", ctb => "52,52,1", },
    },
    {
        time => 5,
        val  => 33,
        ins  => { t10 => "33,52,1", c3 => "33,52,3", ct => "33,52,1", ctb => "33,52,1", },
    },
    {
        time   => 7,
        val    => 47,
        resets => { ctb => "33,52,1", },
        ins    => { t10 => "33,52,1", c3 => "33,52,3", ct => "33,52,1", ctb => "33,52,1", },
    },
    {
        time => 16,
        outs => { t10 => [ "33,52,3", "33,47,5", ], ct => [ "33,52,3", "33,47,5", ], },
        vals => { t10 => "47,47,6", c3 => "33,52,3", ct => "47,47,6", ctb => "NaN,NaN,7", },
    },
    {
        time   => 18,
        val    => 23,
        resets => { ctb => "NaN,NaN,7" },
        outs   => { t10 => "47,47,7", c3 => "33,52,3", ct => "47,47,7", },
        ins    => { t10 => "23,23,8", c3 => "23,47,5", ct => "23,23,8", ctb => "23,23,17", },
    },
    {
        time => 19,
        val  => 15,
        outs => { c3 => "23,47,5", },
        ins  => { t10 => "15,23,9", c3 => "15,47,7", ct => "15,23,9", ctb => "15,23,17", },
    },
    {
        time   => 20,
        val    => 22,
        resets => { ctb => "15,23,17" },
        outs   => { c3 => "15,47,7", },
        ins    => { t10 => "15,23,10", c3 => "15,23,18", ct => "15,23,10", ctb => "15,23,17", },
    },
    {
        time => 21,
        val  => 14,
        outs => { c3 => "15,23,18", ct => "15,23,18", },
        ins  => { t10 => "14,23,11", c3 => "14,22,19", ct => "14,22,19", ctb => "14,14,20", },
    },
);

TestStream->new(
    aggregator_class     => 'MinMax',
    aggregator_params    => \%params,
    events               => \@events,
    start_time           => 1,
    time_sub             => sub { $_[0]->{time} },
    expected_length      => 3,
    expected_time_length => 10,
)->run;

done_testing;
