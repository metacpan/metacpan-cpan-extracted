#!perl

use Chart::GGPlot::Setup;

use List::AllUtils;
use Test2::V0;

use Chart::GGPlot::Geom::Functions qw(:all);
use Chart::GGPlot::Aes::Functions qw(:all);

subtest aes_mapping => sub {
    my $g = geom_bar(mapping => aes(weight => 'displ'));
    isa_ok( $g->geom, ['Chart::GGPlot::Geom::Bar'], 'geom' );
    ok($g->mapping->at('weight')->$_DOES('Eval::Quosure'), 'mapping');
    is($g->aes_params->as_hashref, {}, 'aes_params');
};

#subtest aes_params => sub {
#    my $g = geom_point(color => 'red');
#    is($g->mapping->as_hashref, {}, 'mapping');
#    is($g->aes_params->as_hashref, { color => 'red' }, 'aes_params');
#};



done_testing;
