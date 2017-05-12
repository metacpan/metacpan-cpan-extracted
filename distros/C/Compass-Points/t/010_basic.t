
use strict;
use warnings;

use Test::More;

use_ok( "Compass::Points" );

my $points = Compass::Points->new( 32 );

is( $points->deg2abbr( 0 ), "N" );
is( $points->deg2abbr( 90 ), "E" );
is( $points->deg2abbr( 180 ), "S" );
is( $points->deg2abbr( 270 ), "W" );

is( $points->deg2abbr( 5.62 ), "N" );
is( $points->deg2abbr( 5.64 ), "NbE" );
is( $points->deg2abbr( 365.64 ), "NbE" );

is( $points->deg2abbr( -90 ), "E" );
is( $points->deg2abbr( 450 ), "E" );
is( $points->deg2abbr(), "N" );

$points = Compass::Points->new( 3 );

ok( @$points == 4, "point count matches" );

is( $points->deg2abbr( 0 ), "N" );
is( $points->deg2abbr( 45 ), "E" );
is( $points->deg2abbr( 90 ), "E" );
is( $points->deg2abbr( 135 ), "S" );

$points = Compass::Points->new( 16 );

is( $points->deg2abbr( 155 ), "SSE" );
is( $points->deg2name( 155 ), "South-southeast" );

done_testing();

