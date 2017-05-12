#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Convert::Color::CMY;

my $red = Convert::Color::CMY->new( 0, 1, 1 );

is( $red->cyan,    0, 'red cyan' );
is( $red->magenta, 1, 'red magenta' );
is( $red->yellow,  1, 'red yellow' );

is_deeply( [ $red->cmy ], [ 0, 1, 1 ], 'red cmy' );

my $green = Convert::Color::CMY->new( 1, 0, 1 );

is( $green->cyan,    1, 'green cyan' );
is( $green->magenta, 0, 'green magenta' );
is( $green->yellow,  1, 'green yellow' );

is_deeply( [ $green->cmy ], [ 1, 0, 1 ], 'green cmy' );

my $blue = Convert::Color::CMY->new( 1, 1, 0 );

is( $blue->cyan,    1, 'blue cyan' );
is( $blue->magenta, 1, 'blue magenta' );
is( $blue->yellow,  0, 'blue yellow' );

is_deeply( [ $blue->cmy ], [ 1, 1, 0 ], 'blue cmy' );

my $yellow = Convert::Color::CMY->new( '0,0,1' );

is( $yellow->cyan,    0, 'yellow cyan' );
is( $yellow->magenta, 0, 'yellow magenta' );
is( $yellow->yellow,  1, 'yellow yellow' );

is_deeply( [ $yellow->cmy ], [ 0, 0, 1 ], 'yellow cmy' );

done_testing;
