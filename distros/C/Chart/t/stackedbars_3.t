#!/usr/bin/perl -w

use strict;
use Chart::StackedBars;

print "1..1\n";

my ($g) = Chart::StackedBars->new( 580, 400 );

$g->add_dataset( '1', '2', '3', '4', '5', '6', '7' );
$g->add_dataset( 5,   7,   9,   11,  9,   7,   5 );
$g->add_dataset( 15,  11,  8,   5,   8,   11,  15 );
$g->add_dataset( 5,   4,   3,   2,   3,   4,   5 );

$g->set(
    'legend'          => 'right',
    'title'           => 'Stacked Bars',
    'precision'       => 0,
    'spaced_bars'     => 'true',
    'include_zero'    => 'true',
    'skip_int_ticks'  => 3,
    'max_val'         => 30,
    'y_label'         => '',
    'y_label2'        => '',
    'grey_background' => 'false',

);

$g->set(
    'colors' => {
        'dataset0'   => [ 0,   125, 250 ],
        'dataset1'   => [ 147, 112, 219 ],
        'dataset2'   => [ 250, 0,   125 ],
        'background' => [ 230, 230, 250 ]
    }
);

$g->png("samples/stackedbars_3.png");

print "ok 1\n";

exit;
