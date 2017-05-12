#!/usr/bin/perl -w

use Chart::Points;

print "1..1\n";

$g = Chart::Points->new;
$g->add_dataset( 1,  2, 7, 10, 15, 19, 20 );
$g->add_dataset( -3, 0, 8, 4,  2,  1,  0 );

@hash = (
    'title' => 'Points Chart 3',

    # 'type_style' => 'donut',
    'png_border' => 10,
    'precision'  => 0,
    'min_val'    => 0,

    #'max_val' => 0,
    'include_zero' => 'true',
    'xy_plot'      => 'true',
);

$g->set(@hash);

$g->png("samples/points_3.png");

print "ok 1\n";

exit(0);

