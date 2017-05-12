#!/usr/bin/perl

use Test::More tests => 27;
use Data::Dumper;

use Convert::Color::IRC;

my $red = Convert::Color::IRC->new( 'red' );

# diag("Red with red: " . Dumper $red);

is( $red->red,     255, 'red red' );
is( $red->green,   0,   'red green' );
is( $red->blue,    0,   'red blue' );

$red = Convert::Color::IRC->new( 4 );

# diag("Red with 4: " . Dumper $red);

is( $red->red,     255, 'red red' );
is( $red->green,   0,   'red green' );
is( $red->blue,    0,   'red blue' );

$red = Convert::Color->new( 'irc:red' );

# diag("Red with irc:red: " . Dumper $red);

is( $red->red,     255, 'red red' );
is( $red->green,   0,   'red green' );
is( $red->blue,    0,   'red blue' );

$red = undef;

my $green = Convert::Color::IRC->new( 'green' );

# diag("Green with green: " . Dumper $green);

is( $green->red,   0,   'green red' );
is( $green->green, 255, 'green green' );
is( $green->blue,  0,   'green blue' );

$green = Convert::Color::IRC->new( 3 );

# diag("Green with 3: " . Dumper $green);

is( $green->red,   0,   'green red' );
is( $green->green, 255, 'green green' );
is( $green->blue,  0,   'green blue' );

$green = Convert::Color->new( 'irc:green' );

# diag("Green with irc:green: " . Dumper $green);

is( $green->red,   0,   'green red' );
is( $green->green, 255, 'green green' );
is( $green->blue,  0,   'green blue' );

$green = undef;

my $blue = Convert::Color::IRC->new( 'blue' );

# diag("Blue with blue: " . Dumper $blue);

is( $blue->red,    0,   'blue red' );
is( $blue->green,  0,   'blue green' );
is( $blue->blue,   255, 'blue blue' );

$blue = Convert::Color::IRC->new( 2 );

# diag("Blue with 2: " . Dumper $blue);

is( $blue->red,    0,   'blue red' );
is( $blue->green,  0,   'blue green' );
is( $blue->blue,   255, 'blue blue' );

$blue = Convert::Color->new( 'irc:blue' );

# diag("Blue with irc:blue: " . Dumper $blue);

is( $blue->red,    0,   'blue red' );
is( $blue->green,  0,   'blue green' );
is( $blue->blue,   255, 'blue blue' );