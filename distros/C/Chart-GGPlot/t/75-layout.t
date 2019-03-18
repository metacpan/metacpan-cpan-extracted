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

done_testing();
