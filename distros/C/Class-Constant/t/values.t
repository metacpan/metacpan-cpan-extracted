#!perl -T

use Test::More tests => 24;


package stringify;

use Class::Constant
    NORTH => "north",
    SOUTH => "south",
    EAST  => "east",
    WEST  => "west";


package methodify;

use Class::Constant
    NORTH => { x =>  0, y => -1 },
    SOUTH => { x =>  0, y =>  1 },
    EAST  => { x => -1, y =>  0 },
    WEST  => { x =>  1, y =>  0 };


package bothify;

use Class::Constant
    NORTH => "north",
             { x =>  0, y => -1 },
    SOUTH => "south",
             { x =>  0, y =>  1 },
    EAST  => "east",
             { x => -1, y =>  0 },
    WEST  => "west",
             { x =>  1, y =>  0 };


package main;

my $x;

$x = stringify::NORTH; is($x, "north");
$x = stringify::SOUTH; is($x, "south");
$x = stringify::EAST;  is($x, "east");
$x = stringify::WEST;  is($x, "west");

is(methodify::NORTH->get_x,  0); is(methodify::NORTH->get_y, -1);
is(methodify::SOUTH->get_x,  0); is(methodify::SOUTH->get_y,  1);
is(methodify::EAST ->get_x, -1); is(methodify::EAST ->get_y,  0);
is(methodify::WEST ->get_x,  1); is(methodify::WEST ->get_y,  0);

$x = bothify::NORTH; is($x, "north");
$x = bothify::SOUTH; is($x, "south");
$x = bothify::EAST;  is($x, "east");
$x = bothify::WEST;  is($x, "west");

is(bothify::NORTH->get_x,  0); is(bothify::NORTH->get_y, -1);
is(bothify::SOUTH->get_x,  0); is(bothify::SOUTH->get_y,  1);
is(bothify::EAST ->get_x, -1); is(bothify::EAST ->get_y,  0);
is(bothify::WEST ->get_x,  1); is(bothify::WEST ->get_y,  0);
