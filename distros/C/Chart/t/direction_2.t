#!/usr/bin/perl -w

use Chart::Direction;

print "1..1\n";

$g = Chart::Direction->new( 450, 450 );

$g->add_dataset( 0,  10, 30, 100, 110, 200, 250, 300, 350 );
$g->add_dataset( 10, 4,  11, 40,  20,  35,  5,   45,  20 );
$g->add_dataset( 20, 8,  22, 80,  40,  70,  10,  90,  40 );
$g->add_dataset( 30, 18, 32, 85,  45,  60,  20,  50,  25 );

$g->set(
    'title'           => 'Direction Demo',
    'angle_interval'  => 15,
    'precision'       => 0,
    'grey_background' => 'false',
    'legend'          => 'top',

);

$g->png("samples/direction_2.png");

print "ok 1\n";

exit(0);

