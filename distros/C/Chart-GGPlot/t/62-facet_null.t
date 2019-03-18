#!perl

use Chart::GGPlot::Setup;

use Test2::V0;

use Chart::GGPlot::Facet;
use Chart::GGPlot::Facet::Functions qw(:all);

my @cases_construction = (
    { params => [] },
    { params => [ shrink => true ] },
    { params => [ shrink => false ] }
);

for my $case (@cases_construction) {
    my $facet = facet_null( @{ $case->{params} } );
    isa_ok( $facet, [qw(Chart::GGPlot::Facet::Null)], 'construction' );
}

done_testing();
