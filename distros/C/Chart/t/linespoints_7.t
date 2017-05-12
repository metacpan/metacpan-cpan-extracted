#!/usr/bin/perl -w

use strict;
use Chart::LinesPoints;
use Chart::Lines;

print "1..1\n";

my @bezugszeitraum = (
    '2004-06-13 00:00:00+00',
    '2004-06-14 00:00:00+00',
    '2004-06-15 00:00:00+00',
    '2004-06-16 00:00:00+00',
    '2004-06-17 00:00:00+00'
);

my @obsepoch = ( 81.8670764502497, 42.4188998589563, 100, 0.9652898299202, 12.9652898299202 );

my $g = Chart::LinesPoints->new( 700, 450 );

#my  $g = Chart::Lines->new(700,450);

$g->add_dataset(@bezugszeitraum);
$g->add_dataset(@obsepoch);

$g->set( 'x_ticks'         => 'staggered' );
$g->set( 'x_label'         => ' Time' );
$g->set( 'y_label'         => 'actual_nr_of_obsepoch / possible_nr' );
$g->set( 'legend'          => 'none' );
$g->set( 'precision'       => 0 );
$g->set( 'title'           => 'Station Test' );
$g->set( 'grey_background' => 'false' );
$g->set( 'max_val'         => '100' );
$g->set( 'min_val'         => '0' );
$g->set( 'pt_size'         => '10' );
$g->set( 'brush_size'      => '3' );
$g->set( 'stepline'        => 'true' );

$g->png("samples/linespoints_7.png");
print "ok 1\n\n";

