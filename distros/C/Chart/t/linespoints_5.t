#!/usr/bin/perl -w

use strict;
use Chart::Composite;

print "1..1\n";

my $g = Chart::Composite->new( 700, 350 );

my @bezugszeitraum = (
    '2005-04-02', '2005-04-03', '2005-04-04', '2005-04-05', '2005-04-06', '2005-04-07',
    '2005-04-08', '2005-04-09', '2005-04-10', '2005-04-18', '2005-04-19', '2005-04-20',
    '2005-04-21', '2005-04-22', '2005-04-23', '2005-04-24', '2005-04-25'
);

my @nr_of_sats = ( 27, 29, 28, 26, 27, 23, 29, 29, 23, 26, 29, 29, 29, 29, 29, 29, 29 );

my @obsinterval_abs = (
    0.555555555555556, 0.999652777777778, 0.673611111111111, 0.607291666666667, 0.638888888888889, 0.361111111111111,
    0.999652777777778, 0.999652777777778, 0.377083333333333, 0.51875,           0.84375,           0.977777777777778,
    0.999652777777778, 0.999652777777778, 0.999652777777778, 0.999652777777778, 0.999652777777778
);

#my @obsinterval_abs = (0.555555555555556,0.999652777777778,
#                       0.673611111111111,500,
#		       0.638888888888889,0.361111111111111,
#		       0.999652777777778,0.999652777777778,
#		       0.377083333333333,0.51875,
#		       -500,          0.977777777777778,
#		       0.999652777777778,0.999652777777778,
#		       0.999652777777778,0.999652777777778,
#		       0.999652777777778);

# Chart::Composite

#  $g = Chart::LinesPoints->new (800, 350);
#  $g = Chart::LinesPoints->new (700, 350);
$g = Chart::Composite->new( 700, 350 );

$g->add_dataset(@bezugszeitraum);
$g->add_dataset(@nr_of_sats);
$g->add_dataset(@obsinterval_abs);

$g->set( 'composite_info' => [ [ 'LinesPoints', [1] ], [ 'LinesPoints', [2] ] ] );
$g->set( 'x_ticks'        => 'vertical' );
$g->set( 'x_label'        => ' Time' );
$g->set( 'y_label'        => 'red: Nr_of_sats' );

#  $g-> set ('y_axes' => 'both');
$g->set( 'y_label2'        => 'green: obs_interval (absolut)' );
$g->set( 'legend'          => 'none' );
$g->set( 'precision'       => 1 );
$g->set( 'grey_background' => 'false' );
$g->set( 'title'           => 'ANKR' );
$g->set( 'sub_title'       => '2005-04-02 - 2005-04-25' );

# $g-> set ('title_font' => gdGiantFont);
# $g-> set ('sub_title_font' => gdMediumBoldFont);
$g->set( 'include_zero' => 'true' );
$g->set( 'pt_size'      => '10' );
$g->set( 'brush_size'   => '4' );

# $g-> set ('skip_x_ticks' => $skip_x);

$g->png("samples/linespoints_5.png");
print "ok 1\n\n";

