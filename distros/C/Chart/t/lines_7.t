#!/usr/bin/perl -w

use Chart::Lines;
use strict;
my $g;

print "1..1\n";

$g = Chart::Lines->new;
$g->add_dataset( 'one', 'two', 'three', 'four', 'five', 'six' );
$g->add_dataset( 3,     11,    5,       10,     12,     4 );
$g->add_dataset( -1,    3,     6,       -2,     -8,     0 );
$g->add_dataset( 5,     5,     6,       2,      12,     9 );
$g->add_dataset( 0,     0,     0,       0,      0,      0 );
$g->add_dataset( -12,   -18,   0,       0,      0,      1 );

$g->set( 'title'        => "Lines Chart" );
$g->set( 'sub_title'    => 'Lines Chart' );
$g->set( 'y_grid_lines' => 'true' );
$g->set( 'legend'       => 'bottom' );
$g->set( 'precision'    => '0' );
$g->set( 'include_zero' => 'true' );

$g->png("samples/lines_7.png");

print "ok 1\n";

exit(0);

