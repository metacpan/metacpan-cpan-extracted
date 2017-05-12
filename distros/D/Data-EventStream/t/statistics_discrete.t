use Test::Most;
use Test::FailWarnings;

use Data::EventStream;
use Data::EventStream::Statistics::Discrete;

use lib 't/lib';
use TestStream;

my %params = ( stat => { count => 4 }, );

my @events = (
    {
        methods => {
            stat => {
                count              => 0,
                mean               => undef,
                sum                => 0,
                variance           => undef,
                standard_deviation => undef,
            },
        },
    },
    { val => 10, methods => { stat => { count => 1, }, }, },
    { val => 20, methods => { stat => { count => 2, }, }, },
    {
        val     => 30,
        methods => {
            stat =>
              { count => 3, mean => 20, sum => 60, variance => 100, standard_deviation => 10, },
        },
    },
    { val => 40, methods => { stat => { count => 4, }, }, },
    {
        val     => 50,
        methods => {
            stat => {
                count              => 4,
                mean               => 35,
                sum                => 140,
                variance           => num( 166.66667, 1e-5 ),
                standard_deviation => num( 12.90994, 1e-5 ),
            },
        },
    },
    { val => 19, methods => { stat => { count => 4, }, }, },
    {
        val     => 27,
        methods => {
            stat => {
                count              => 4,
                mean               => 34,
                sum                => 136,
                variance           => num( 188.66667, 1e-5 ),
                standard_deviation => num( 13.7356, 1e-5 ),
            },
        },
    },
);

TestStream->new(
    aggregator_class  => 'Data::EventStream::Statistics::Discrete',
    new_params        => { value_sub => sub { $_[0]->{val} }, },
    aggregator_params => \%params,
    events            => \@events,
    no_callbacks      => 1,
)->run;

done_testing;
