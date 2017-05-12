#!/usr/bin/perl

use Test::More 'no_plan';
use Acme::LifeUniverseEverything;

my $zero = 0;
ok( length overload::Overloaded($zero),    "Constant binary overloaded" );

my $ten = 10;

ok( length overload::Overloaded(10),       "Constant int overloaded" );
ok( "$ten" eq "10",                        "Stringification" );

ok( length overload::Overloaded(10*5),     "Multiplication overloaded" );
ok( (10*5)==50,                            "Multiplication correct" );

ok( length overload::Overloaded(10+5),     "Addition overloaded" );
ok( (10+5)==15,                            "Addition correct" );

ok( length overload::Overloaded(10-5),     "Subtraction overloaded" );
ok( (10-5)==5,                             "Subtraction correct" );

ok( length overload::Overloaded(10/5),     "Division overloaded" );
ok( (10/5)==2,                             "Division correct" );

ok( length overload::Overloaded(-$ten),    "Unary negation overloaded" );
ok( (-$ten)==-10,                          "Unary negation correct" );

ok( 10>5,                                  "Comparison < correct" );
ok( 5<10,                                  "Comparison > correct" );

ok( (10<=>5)>0,                            "Spaceship <=> correct"  );

my $x = 10;
$x++;
ok( length overload::Overloaded($x),       "Increment overloaded" );
ok( $x==11,                                "Increment correct" );

$x--;
ok( length overload::Overloaded($x),       "Decrement overloaded" );
ok( $x==10,                                "Decrement correct" );

ok( length overload::Overloaded(abs(-10)), "abs() overloaded" );
ok( abs(-10)==10,                          "abs() correct" );

ok( 42==6*9,                               "6 * 9 fixed" );

