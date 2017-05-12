#!/usr/bin/perl -w

use Chart::Points;

print "1..1\n";

$g = Chart::Points->new();

@hash = (
    'title'      => 'Points Chart',
    'png_border' => 10,
    'pt_size'    => 18,
    'grid_lines' => 'true',
    'brush_size' => 10,               # 10 points diameter
);

$g->set(@hash);
$g->add_dataset( 'foo', 'bar', 'junk' );
$g->add_dataset( 3,     4,     9 );

$g->add_dataset( 8, 6, 0 );
$g->add_dataset( 5, 7, 2 );

$g->png("samples/points.png");

print "ok 1\n";

exit(0);

