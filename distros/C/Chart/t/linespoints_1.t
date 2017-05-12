#!/usr/bin/perl -w

use Chart::LinesPoints;

print "1..1\n";

$g = Chart::LinesPoints->new;
$g->add_dataset( 'foo', 'bar', 'junk', 'ding', 'bat' );
$g->add_dataset( 3,     4,     9,      3,      4 );
$g->add_dataset( 8,     4,     3,      4,      6 );
$g->add_dataset( 5,     7,     2,      7,      9 );

$g->set( 'title'     => 'Lines and Points Chart' );
$g->set( 'sub_title' => 'Change color for grid_lines' );

$g->set( 'colors' => { 'x_grid_lines' => [ 250, 0, 125 ] } );
$g->set( 'colors' => { 'y_grid_lines' => [ 250, 0, 125 ] } );

#$g->set ('colors' => {'y2_grid_lines' => [250, 0, 125]});
$g->set( 'grid_lines'      => 'true' );
$g->set( 'grey_background' => 'false' );
$g->set( 'legend'          => 'bottom' );

$g->png("samples/linespoints_1.png");

print "ok 1\n";

exit(0);

