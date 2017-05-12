use Test::Most;
use Test::FailWarnings;

use Data::EventStream;

use lib 't/lib';
use Averager;
use TestStream;

my %params = (
    'c3' => { count => 3 },
    'c5' => { count => 5 },
    'b4' => { count => 4, batch => 1 },
);

my @events = (
    {
        val            => 2,
        ins            => { c3 => 2, c5 => 2, b4 => 2, },
        add_aggregator => {
            d7 => { count => 7, batch => 1, disposable => 1, },
        },
    },
    {
        val            => 4,
        ins            => { c3 => 3, c5 => 3, b4 => 3, d7 => 4, },
        add_aggregator => {
            'd4' => { count => 4, batch => 1, disposable => 1, },
        },
        stream => {
            length => 7,
        },
    },
    {
        val => 3,
        ins => { c3 => 3, c5 => 3, b4 => 3, d4 => 3, d7 => 3.5, },
    },
    {
        val => 5,
        ins => { c3 => 4, c5 => 3.5, b4 => 3.5, d4 => 4, d7 => 4, },
        outs   => { c3 => 3, },
        resets => { b4 => 3.5 },
    },
    {
        val => 1,
        ins => { c3 => 3, c5 => 3, b4 => 1, d4 => 3, d7 => 3.25, },
        outs => { c3 => 4, },
    },
    {
        val => 6,
        ins => { c3 => 4, c5 => 3.8, b4 => 3.5, d4 => 3.75, d7 => 3.8, },
        outs   => { c3 => 3, c5 => 3, },
        resets => { d4 => 3.75, },
    },
    {
        val => 8,
        ins => { c3 => 5, c5 => 4.6, b4 => 5, d7 => 4.5, },
        outs => { c3 => 4, c5 => 3.8, },
    },
    {
        val => 4,
        ins => { c3 => 6, c5 => 4.8, b4 => 4.75, d7 => 4.42857, },
        outs   => { c3 => 5,    c5 => 4.6, },
        resets => { b4 => 4.75, d7 => 4.42857, },
    },
    {
        val => 0,
        ins => { c3 => 4, c5 => 3.8, b4 => 0, },
        outs => { c3 => 6, c5 => 4.8, },

        # perhaps it should be reduced to 5, as d7 has been disposed,
        # but it will require to go through all the aggregators which will
        # affect performance. Keeping length at 7 doesn't have any
        # performance impact, but takes some memory
        stream => {
            length => 7,
        },
    },
    {
        val => 5,
        ins => { c3 => 3, c5 => 4.6, b4 => 2.5, },
        outs => { c3 => 4, c5 => 3.8, },
    },
);

TestStream->new(
    aggregator_class  => 'Averager',
    aggregator_params => \%params,
    events            => \@events,
    expected_length   => 5,
)->run;

done_testing;
