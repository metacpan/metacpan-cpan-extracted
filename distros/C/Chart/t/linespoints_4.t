#!/usr/bin/perl -w

use strict;
use Chart::LinesPoints;

print "1..1\n";

my $g = Chart::LinesPoints->new( 700, 350 );

my @bezugszeitraum = (
    '2005-04-02', '2005-04-03', '2005-04-04', '2005-04-05', '2005-04-06', '2005-04-07', '2005-04-08', '2005-04-09',
    '2005-04-10', '2005-04-11', '2005-04-12', '2005-04-13', '2005-04-14', '2005-04-15', '2005-04-16', '2005-04-17',
    '2005-04-18', '2005-04-19', '2005-04-20', '2005-04-21', '2005-04-22', '2005-04-23', '2005-04-24', '2005-04-25'
);

my @clock_reset = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );

#my @clock_reset = (10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10);

$g->add_dataset(@bezugszeitraum);
$g->add_dataset(@clock_reset);

$g->set( 'x_ticks'   => 'vertical' );
$g->set( 'x_label'   => 'Time' );
$g->set( 'y_label'   => 'Number of clock resets' );
$g->set( 'legend'    => 'none' );
$g->set( 'precision' => 1 );
$g->set( 'title'     => 'AURI' );
$g->set( 'sub_title' => '2005-04-01 --- 2005-04-25' );

#  $g-> set ('title_font' => 'gdGiantFont');
#  $g-> set ('sub_title_font' => 'gdMediumBoldFont');
$g->set( 'grey_background' => 'false' );

#  $g-> set ('include_zero' => 'true');
#  $g-> set ('min_val' => '0');
$g->set( 'pt_size'    => '10' );
$g->set( 'brush_size' => '4' );

#  $g-> set ('skip_x_ticks' => $skip_x);
#   $g-> set ('integer_ticks_only' => 'true');

$g->png("samples/linespoints_4.png");
print "ok 1\n\n";

