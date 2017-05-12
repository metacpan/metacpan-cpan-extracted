#!/usr/bin/perl -w

use Chart::Direction;

print "1..1\n";

$g = Chart::Direction->new( 500, 500 );

$g->add_dataset( 210, 220, 200, 215, 225, 200 );
$g->add_dataset( 30,  40,  20,  35,  45,  20 );

$g->add_dataset( 30, 40, 20, 35, 45, 20 );
$g->add_dataset( 30, 40, 20, 35, 45, 20 );

$g->add_dataset( 120, 130, 110, 125, 135, 110 );
$g->add_dataset( 30,  40,  20,  35,  45,  20 );

$g->add_dataset( 300, 310, 290, 305, 315, 290 );
$g->add_dataset( 30,  40,  20,  35,  45,  20 );

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

$g->png("samples/direction_4.png");

print "ok 1\n";

exit(0);

