#!/usr/bin/perl -w

use Chart::Points;

print "1..1\n";

$g = Chart::Points->new();

@hash = (
    'title'      => 'Points Chart with different brushes',
    'png_border' => 10,
    'pt_size'    => 18,
    'grid_lines' => 'true',
    'brush_size' => 10,                                      # 10 points diameter

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
$g->set( colors => { dataset0 => [ 25, 220, 147 ], } );
$g->set(
    brushStyles => {
        dataset0 => 'fatPlus',
        dataset1 => 'hollowSquare'
    }
);
$g->set(@hash);
$g->add_dataset( 'foo', 'bar', 'junk' );
$g->add_dataset( 3,     4,     9 );

$g->add_dataset( 8, 6, 0 );
$g->add_dataset( 5, 7, 2 );

$g->png("samples/points_4.png");

print "ok 1\n";

exit(0);

