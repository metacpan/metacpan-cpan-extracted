#!perl

use Chart::GGPlot::Setup qw(:base :pdl);

use Test2::V0;
use Test2::Tools::PDL;

use Chart::GGPlot::Range::Discrete;
use Chart::GGPlot::Range::Continuous;

my $continuous_range = Chart::GGPlot::Range::Continuous->new();
ok( $continuous_range,                'Range::Continuous->new' );
ok( $continuous_range->range->isnull, "default range is null" );

pdl_is(
    $continuous_range->train( pdl([ 0, 2] ) ),
    pdl([ 0, 2 ]),
    "Range::Continuous->train"
);
$continuous_range->train( pdl([1, 3]) );
pdl_is( $continuous_range->range, pdl([ 0, 3 ]), "Range::Continuous->train" );

ok(
    (
        dies {
            $continuous_range->train( PDL::Factor->new( [qw(foo bar baz)] ) )
        }
    ),
    "Range::Continuous->train dies on discrete value"
);

my $discrete_range = Chart::GGPlot::Range::Discrete->new();
ok( $discrete_range,                 'Range::Discrete->new' );
ok( $discrete_range->range->isempty, "default range is empty" );

is( $discrete_range->train( PDL::Factor->new( [qw(foo bar baz)] ) )->levels,
    [qw(bar baz foo)], "Range::Discrete->train" );
is( $discrete_range->range->levels, [qw(bar baz foo)],
    "Range::Discrete->train" );

ok(
    ( dies { $discrete_range->train( pdl([0, 1]) ) } ),
    "Range::Discrete->train dies on continuous value"
);

done_testing();
