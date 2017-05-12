use strict;
use warnings;
use Box2D;
use Test::More;

my $input = Box2D::b2RayCastInput->new();

my $p1 = Box2D::b2Vec2->new( 0.0,  2.0 );
my $p2 = Box2D::b2Vec2->new( 10.0, 11.0 );
my $maxFraction = 1.0;

$input->p1($p1);
$input->p2($p2);
$input->maxFraction($maxFraction);

is( $input->p1->x,       $p1->x,       "Get p1->x" );
is( $input->p2->y,       $p2->y,       "Get p2->y" );
is( $input->p1->x,       $p1->x,       "Get p1->x" );
is( $input->p2->y,       $p2->y,       "Get p2->y" );
is( $input->maxFraction, $maxFraction, "Get maxFraction" );

done_testing;
