
use strict;
use warnings;

use Test::More;

use_ok( "Compass::Points" );

my $points = Compass::Points->new();

is( $points->abbr2deg( "n" ), 0.00 );
is( $points->name2deg( "north east" ), 45.00 );
is( $points->name2deg( "south east by east" ), undef );

$points = Compass::Points->new( 32 );

is( $points->name2deg( "south east by east" ), 123.75 );
is( $points->name2deg( "Southeast by south" ), 146.25 );
is( $points->abbr2deg( "SWbW" ), 236.25 );

done_testing();

