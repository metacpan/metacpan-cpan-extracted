use Test::Most;
use Test::FailWarnings;

use Data::EventStream;
use Data::EventStream::Statistics::Continuous;

use lib 't/lib';
use TestStream;

my %params = (
    lengw => { count    => 4 },
    timew => { duration => 8 },
);

my @events = (
    {
        time    => 1000,
        methods => {
            timew => {
                count    => 0,
                mean     => undef,
                integral => 0,
                interval => 0,
                change   => 0,
            },
            lengw => {
                count    => 0,
                mean     => undef,
                integral => 0,
                interval => 0,
                change   => 0,
            },
        },
    },
    {
        time    => 1001,
        val     => 10,
        methods => {
            timew => {
                count    => 1,
                mean     => 10,
                integral => 0,
                interval => 0,
                change   => 0,
            },
            lengw => {
                count    => 1,
                mean     => 10,
                integral => 0,
                interval => 0,
                change   => 0,
            },
        },
    },
    {
        time    => 1002,
        val     => 20,
        methods => {
            timew => {
                count    => 2,
                mean     => 10,
                integral => 10,
                interval => 1,
                change   => 10,
            },
            lengw => {
                count    => 2,
                mean     => 10,
                integral => 10,
                interval => 1,
                change   => 10,
            },
        },
    },
    {
        time    => 1005,
        val     => 16,
        methods => {
            timew => {
                count    => 3,
                mean     => 17.5,
                integral => 70,
                interval => 4,
                change   => 6,
            },
            lengw => {
                count    => 3,
                mean     => 17.5,
                integral => 70,
                interval => 4,
                change   => 6,
            },
        },
    },
    {
        time    => 1007,
        methods => {
            timew => {
                count    => 3,
                mean     => 17,
                integral => 102,
                interval => 6,
                change   => 6,
            },
            lengw => {
                count    => 3,
                mean     => 17,
                integral => 102,
                interval => 6,
                change   => 6,
            },
        },
    },
    {
        time    => 1009,
        methods => {
            timew => {
                count    => 2,
                mean     => 16.75,
                integral => 134,
                interval => 8,
                change   => 6,
            },
        },
    },
    {
        time    => 1010,
        val     => 12,
        methods => {
            timew => {
                count    => 2,
                mean     => 17.5,
                integral => 140,
                interval => 8,
                change   => -8,
            },
            lengw => {
                count    => 4,
                mean     => num( 16.66666666, 0.000001 ),
                integral => 150,
                interval => 9,
                change   => 2,
            },
        },
    },
    {
        time    => 1012,
        val     => 18,
        methods => {
            timew => {
                count    => 3,
                mean     => 15.5,
                integral => 124,
                interval => 8,
                change   => -2,
            },
            lengw => {
                count    => 4,
                mean     => 16.4,
                integral => 164,
                interval => 10,
                change   => -2,
            },
        },
    },
    {
        time    => 1014,
        val     => 24,
        methods => {
            timew => {
                count    => 3,
                mean     => 15.5,
                integral => 124,
                interval => 8,
                change   => 8,
            },
            lengw => {
                count    => 4,
                mean     => num( 15.555555555, 0.000001 ),
                integral => 140,
                interval => 9,
                change   => 8,
            },
        },
    },
    {
        time    => 1020,
        methods => {
            timew => {
                count    => 1,
                mean     => 22.5,
                integral => 180,
                interval => 8,
                change   => 6,
            },
        },
    },
    {
        time    => 1024,
        methods => {
            timew => {
                count    => 0,
                mean     => 24,
                integral => 192,
                interval => 8,
                change   => 0,
            },
        },
    },
);

TestStream->new(
    aggregator_class  => 'Data::EventStream::Statistics::Continuous',
    new_params        => { value_sub => sub { $_[0]->{val} }, time_sub => sub { $_[0]->{time} }, },
    aggregator_params => \%params,
    events            => \@events,
    no_callbacks      => 1,
    time_sub => sub { $_[0]->{time} },
)->run;

done_testing;
