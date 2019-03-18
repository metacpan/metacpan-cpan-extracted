#!perl

use Chart::GGPlot::Setup;

use Test2::V0;

use Chart::GGPlot::Trans;
use Chart::GGPlot::Trans::Functions qw(:all);

my $identity_trans = identity_trans();

ok( is_trans($identity_trans), 'is_trans()' );

ok( is_trans( as_trans($identity_trans) ), 'as_trans(Trans)' );
ok( is_trans( as_trans('identity') ),      'as_trans(Str)' );
ok( dies { as_trans("does_not_exit") }, 'as_trans() dies on wrong input' );

done_testing();
