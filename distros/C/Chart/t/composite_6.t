#!/usr/bin/perl -w

use Chart::Composite;
use strict;

print "1..1\n";

my @labels         = qw (06:00-10:00 10:00-14:00 14:00-18:00 18:00-22:00 22:00-02:00 02:00-06:00);
my @chart_data     = qw (0 140 160 155 150 145);
my @chart_lowlimit = qw (120 120 120 120 120 120);
my @chart_hilimit  = qw (180 180 180 180 180 180);

my $chart = Chart::Composite->new( 500, 300 );
$chart->add_dataset(@labels);
$chart->add_dataset(@chart_data);
$chart->add_dataset(@chart_lowlimit);
$chart->add_dataset(@chart_hilimit);

my %chart_settings = (
    'precision'      => 0,
    'legend'         => 'none',
    'graph_border'   => 0,
    'png_border'     => 1,
    'brush_size1'    => 2,
    'brush_size2'    => 10,
    'grid_lines'     => 'false',
    'y_grid_lines'   => 'true',
    'composite_info' => [ [ 'LinesPoints', [1] ], [ 'Lines', [ 2, 3 ] ] ],
    'colors'         => { dataset0 => 'black', dataset1 => 'red', dataset2 => 'red' },
    'sub_title'      => 'Average Chart',
    'min_val'        => 0,
    'max_val'        => 200
);

$chart->set(%chart_settings);
$chart->png("samples/composite_6.png");

print "ok 1\n";

exit(0);

