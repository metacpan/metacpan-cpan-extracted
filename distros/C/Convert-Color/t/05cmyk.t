#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Convert::Color::CMYK;

my $red = Convert::Color::CMYK->new( 0, 1, 1, 0 );

is( $red->cyan,    0, 'red cyan' );
is( $red->magenta, 1, 'red magenta' );
is( $red->yellow,  1, 'red yellow' );
is( $red->key,     0, 'red key' );

is_deeply( [ $red->cmyk ], [ 0, 1, 1, 0 ], 'red cmyk' );

my $green = Convert::Color::CMYK->new( 1, 0, 1, 0 );

is( $green->cyan,    1, 'green cyan' );
is( $green->magenta, 0, 'green magenta' );
is( $green->yellow,  1, 'green yellow' );
is( $green->key,     0, 'green key' );

is_deeply( [ $green->cmyk ], [ 1, 0, 1, 0 ], 'green cmyk' );

my $blue = Convert::Color::CMYK->new( 1, 1, 0, 0 );

is( $blue->cyan,    1, 'blue cyan' );
is( $blue->magenta, 1, 'blue magenta' );
is( $blue->yellow,  0, 'blue yellow' );
is( $blue->key,     0, 'blue key' );

is_deeply( [ $blue->cmyk ], [ 1, 1, 0, 0 ], 'blue cmyk' );

my $yellow = Convert::Color::CMYK->new( '0,0,1,0' );

is( $yellow->cyan,    0, 'yellow cyan' );
is( $yellow->magenta, 0, 'yellow magenta' );
is( $yellow->yellow,  1, 'yellow yellow' );
is( $yellow->key,     0, 'yellow key' );

is_deeply( [ $yellow->cmyk ], [ 0, 0, 1, 0 ], 'yellow cmyk' );

# So far none of these colours have any key; we'll do black just to check

my $black = Convert::Color::CMYK->new( '0,0,0,1' );

is( $black->cyan,    0, 'black cyan' );
is( $black->magenta, 0, 'black magenta' );
is( $black->yellow,  0, 'black yellow' );
is( $black->key,     1, 'black key' );

is_deeply( [ $black->cmyk ], [ 0, 0, 0, 1 ], 'black cmyk' );

done_testing;
