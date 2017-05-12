#!/usr/bin/perl -w

use Chart::Lines;
use Chart::LinesPoints;
use strict;
my $g;

print "1..1\n";

my @labels = ( [ 'Jan', 'Feb', 'Mar' ], [ '0', '20', '100' ] );

$g = Chart::Lines->new;
$g->add_dataset( 10, 20, 30, 40,  50,  60 );
$g->add_dataset( 10, 40, 70, 100, 130, 10 );

$g->set( 'title'        => "Basic example for Option xlabels" );
$g->set( 'y_grid_lines' => 'true' );
$g->set( 'legend'       => 'none' );
$g->set( 'xy_plot'      => 1 );
$g->set( 'x_ticks'      => 'vertical' );

$g->png("samples/lines_9.png");

$g = Chart::Lines->new;
$g->add_dataset( 10, 20, 30, 40,  50,  60 );
$g->add_dataset( 10, 40, 70, 100, 130, 10 );

$g->set( 'title'        => "Example B for Option xlabels" );
$g->set( 'y_grid_lines' => 'true' );
$g->set( 'legend'       => 'none' );
$g->set( 'xy_plot'      => 1 );
$g->set( 'x_ticks'      => 'vertical' );

$g->set(
    xlabels => \@labels,
    xrange  => [ 0, 100 ]
);
$g->png("samples/lines_9b.png");

print "ok 1\n";

exit(0);

