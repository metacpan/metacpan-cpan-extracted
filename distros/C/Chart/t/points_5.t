#!/usr/bin/perl -w

use Chart::Points;

print "1..1\n";

$g = Chart::Points->new();

@hash = (
    'title'      => 'Points Chart with different brushes',
    'png_border' => 10,
    'pt_size'    => 20,
    'grid_lines' => 'false',
    'brush_size' => 18,                                      # 10 points diameter

    #    'brushStyle' => 'FilledCircle',
    #     'brushStyle' => 'circle',
    #    'brushStyle' => 'donut',
    #    'brushStyle' => 'OpenCircle',
    #    'brushStyle' => 'fatPlus',
    #    'brushStyle' => 'triangle',
    #    'brushStyle' => 'upsidedownTriangle',
    #    'brushStyle' => 'square',
    #    'brushStyle' => 'hollowSquare',
    #    'brushStyle' => 'OpenRectangle',
    #    'brushStyle' => 'FilledDiamond',
    #    'brushStyle' => 'OpenDiamond',
    #    'brushStyle' => 'Star',
    'brushStyle' => 'OpenStar',
);
my @labels = (
    'FilledCircle',       'circle', 'donut',        'OpenCircle',    'fatPlus',       'triangle',
    'upsidedownTriangle', 'square', 'hollowSquare', 'OpenRectangle', 'FilledDiamond', 'OpenDiamond',
    'Star',               'OpenStar'
);

$g->set(
    brushStyles => {
        dataset0  => 'FilledCircle',
        dataset1  => 'circle',
        dataset2  => 'donut',
        dataset3  => 'OpenCircle',
        dataset4  => 'fatPlus',
        dataset5  => 'triangle',
        dataset6  => 'upsidedownTriangle',
        dataset7  => 'square',
        dataset8  => 'hollowSquare',
        dataset9  => 'OpenRectangle',
        dataset10 => 'FilledDiamond',
        dataset11 => 'OpenDiamond',
        dataset12 => 'Star',
        dataset13 => 'OpenStar',
    }
);
$g->set(@hash);
$g->add_dataset( 'foo', 'bar', 'junk' );
$g->add_dataset( 1,     1,     1 );
$g->add_dataset( 2,     2,     2 );
$g->add_dataset( 3,     3,     3 );
$g->add_dataset( 4,     4,     4 );
$g->add_dataset( 5,     5,     5 );
$g->add_dataset( 6,     6,     6 );
$g->add_dataset( 7,     7,     7 );
$g->add_dataset( 8,     8,     8 );
$g->add_dataset( 9,     9,     9 );
$g->add_dataset( 10,    10,    10 );
$g->add_dataset( 11,    11,    11 );
$g->add_dataset( 12,    12,    12 );
$g->add_dataset( 13,    13,    13 );
$g->add_dataset( 14,    14,    14 );

$g->set( 'legend_labels' => \@labels );

$g->png("samples/points_5.png");

print "ok 1\n";

exit(0);

