#!perl

use Chart::GGPlot::Setup qw(:base :pdl);

use Data::Frame::Examples qw(mtcars);
use Data::Frame::Types qw(DataFrame);
use Types::Standard qw(ArrayRef); 

use Chart::GGPlot::Facet;
use Chart::GGPlot::Coord;

use Test2::V0;
use Test2::Tools::DataFrame;

use Chart::GGPlot::Layout;

my @cases_construction = (
    {
        params => [],
    },
);

for my $case (@cases_construction) {
    my $layout = Chart::GGPlot::Layout->new(@{$case->{params}});
    isa_ok($layout, [qw(Chart::GGPlot::Layout)], 'construction');
}

my $mtcars = mtcars();

{
    my $layout = Chart::GGPlot::Layout->new();
    my $data = $layout->setup([$mtcars], $mtcars);
    ok((ArrayRef[DataFrame])->check($data), '$layout->setup() returns ArrayRef[DataFrame]');

    my $exp = $mtcars->copy;
    $exp->set('PANEL', pdl(0)->repeat($exp->nrow));
    dataframe_is($data->[0], $exp, '$layout->setup()');
}

subtest _split_indices => sub {
    is(
        Chart::GGPlot::Layout->_split_indices( pdl( [ 0, 1, 2, 2, 1, 0 ] ) )
          ->map( sub { $_->unpdl } ),
        [ [ 0, 5 ], [ 1, 4 ], [ 2, 3 ] ],
        'split_indices()'
    );
    is(
        Chart::GGPlot::Layout->_split_indices( pdl( [ 1, 2, 3, 3, 2, 1 ] ) )
          ->map( sub { $_->unpdl } ),
        [ [], [ 0, 5 ], [ 1, 4 ], [ 2, 3 ] ],
        'split_indices()'
    );
    is(
        Chart::GGPlot::Layout->_split_indices( pdl( [ 0, 1, 2, 2, 1, 0 ] ), 2 )
          ->map( sub { $_->unpdl } ),
        [ [ 0, 5 ], [ 1, 2, 3, 4 ] ],
        'split_indices()'
    );
};


done_testing();
