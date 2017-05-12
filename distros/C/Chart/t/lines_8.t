#!/usr/bin/perl -w

use Chart::Lines;
use strict;
my $g;

print "1..1\n";

$g = Chart::Lines->new;
$g->add_dataset( 'one', 'two', 'three', 'four', 'five', 'six' );
$g->add_dataset( 3,     11,    5,       10,     12,     4 );

$g->set( 'title'         => "Timing" );
$g->set( 'sub_title'     => 'Example for stepline' );
$g->set( 'y_grid_lines'  => 'true' );
$g->set( 'legend'        => 'none' );
$g->set( 'precision'     => '0' );
$g->set( 'include_zero'  => 'true' );
$g->set( 'stepline'      => 'true' );
$g->set( 'stepline_mode' => 'begin' );

$g->png("samples/lines_8.png");

print "ok 1\n";

exit(0);

