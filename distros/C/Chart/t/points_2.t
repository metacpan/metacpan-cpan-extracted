#!/usr/bin/perl -w

use Chart::Points;

print "1..1\n";

$g = Chart::Points->new;
$g->add_dataset( 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So' );
$g->add_dataset( -3,   0,    8,    4,    2,    1,    0 );
$g->add_dataset( 8,    0.12, 9,    2,    4,    -1,   3 );
$g->add_dataset( 5,    -7,   12,   5,    7,    5,    8 );
$g->add_dataset( 0,    0,    0,    0,    0,    0,    0 );

@hash = (
    'title' => 'Points Chart',

    # 'type_style' => 'donut',
    'png_border' => 10,
    'precision'  => 0,
    'min_val'    => 0,

    #'max_val' => 0,
    'include_zero' => 'true',

);

$g->set(@hash);

$g->png("samples/points_2.png");

print "ok 1\n";

exit(0);

