#!/usr/bin/perl -w

use Chart::Direction;

print "1..1\n";

$g = Chart::Direction->new( 500, 500 );
my @labels = ( 'eins', 'zwei', 'drei', );

$g->add_dataset( 0,  10, 30, 100, 110, 200, 250, 300, 350 );
$g->add_dataset( 10, 4,  11, 40,  20,  35,  5,   45,  20 );
$g->add_dataset( 29, 49, 20, 17,  30,  42,  45,  25,  30 );
$g->add_dataset( 40, 35, 25, 30,  42,  20,  32,  16,  5 );
$g->set(
    'title'           => 'Direction Demo',
    'grey_background' => 'false',
    'line'            => 'true',
    'precision'       => 0,
    'legend_labels'   => \@labels,
    'legend'          => 'bottom',

    # 'polar' => 'true',
);

$g->png("samples/direction_1.png");

print "ok 1\n";

exit(0);

