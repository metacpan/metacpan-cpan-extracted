#!/usr/bin/perl -w

use Chart::Direction;

print "1..1\n";

$g = Chart::Direction->new( 500, 500 );

$g->add_dataset( 0,  100, 50, 200, 280, 310 );
$g->add_dataset( 30, 40,  20, 35,  45,  20 );

$g->add_dataset( 10, 110, 60, 210, 290, 320 );
$g->add_dataset( 30, 40,  20, 35,  45,  20 );

$g->add_dataset( 20, 120, 70, 220, 300, 330 );
$g->add_dataset( 30, 40,  20, 35,  45,  20 );

$g->set(
    'title'           => 'Direction Demo',
    'angle_interval'  => 45,
    'precision'       => 0,
    'arrow'           => 'true',
    'point'           => 'false',
    'include_zero'    => 'true',
    'pairs'           => 'true',
    'legend'          => 'none',
    'grey_background' => 'false',
);

$g->png("samples/direction_3.png");

print "ok 1\n";

exit(0);

