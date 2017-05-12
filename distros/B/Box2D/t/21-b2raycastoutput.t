use strict;
use warnings;
use Box2D;
use Test::More;

my $output = Box2D::b2RayCastOutput->new();

my $normal = Box2D::b2Vec2->new( 1.0, 2.0 );
my $fraction = 1.0;

$output->normal($normal);
$output->fraction($fraction);

is( $output->normal->x, $normal->x, "Get normal->x" );
is( $output->normal->y, $normal->y, "Get normal->y" );
is( $output->fraction,  $fraction,  "Get fraction" );

done_testing;
