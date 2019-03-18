#!perl

use Chart::GGPlot::Setup;

use Test2::V0;

use Chart::GGPlot::Labels;
use Chart::GGPlot::Labels::Functions qw(:all);

my $labs = labs( title => 'title', tag => 'A' );
is( $labs->as_hashref, { title => 'title', tag => 'A' }, 'labs()' );

my $title = ggtitle( 'new title', 'a subtitle' );
is( $title->as_hashref, { title => 'new title', subtitle => 'a subtitle' },
    'ggtitle()' );

my $xlab = xlab('new x label');
is( $xlab->as_hashref, { x => 'new x label' }, 'xlab()' );

my $ylab = ylab("new y label");
is( $ylab->as_hashref, { y => 'new y label' }, 'ylab()' );

done_testing;
