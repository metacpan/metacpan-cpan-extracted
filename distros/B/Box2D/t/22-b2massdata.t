use strict;
use warnings;
use Box2D;
use Test::More;

my $data = Box2D::b2MassData->new();

my $mass = 11.0;
my $center = Box2D::b2Vec2->new( 1.0, 2.0 );
my $i = 12.0;

$data->mass($mass);
$data->center($center);
$data->I($i);

is( $data->mass, $mass, "Get mass" );
is( $data->center->x, $center->x, "Get center->x" );
is( $data->center->y, $center->y, "Get center->y" );
is( $data->I, $i, "Get I" );

done_testing;
