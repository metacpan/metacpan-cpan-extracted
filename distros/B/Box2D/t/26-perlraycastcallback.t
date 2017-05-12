use strict;
use warnings;
use Box2D;
use Test::More;

my $gravity = Box2D::b2Vec2->new( 0, 10 );
my $world = Box2D::b2World->new( $gravity, 1 );

my $bodyDef = Box2D::b2BodyDef->new();
$bodyDef->position->Set( 5, 5 );
my $body = $world->CreateBody($bodyDef);

my $shape0 = Box2D::b2PolygonShape->new();
$shape0->SetAsBox( 2, 2 );

my $fixture0 = $body->CreateFixture( $shape0, 1.0 );

my $point1 = Box2D::b2Vec2->new( 0,  5 );
my $point2 = Box2D::b2Vec2->new( 10, 5 );

my $reported = 0;
my ( $fixture, $point, $normal, $fraction );

my $callback = Box2D::PerlRayCastCallback->new(
    sub {
        ( $fixture, $point, $normal, $fraction ) = @_;

        $reported++;

        return 0;
    }
);

ok( $callback, "new" );
isa_ok( $callback, "Box2D::PerlRayCastCallback" );

$world->RayCast( $callback, $point1, $point2 );

is( $reported, 1, "RayCast reported" );

ok( $fixture, "RayCast fixture" );

my $shape = $fixture->GetShape;
is( $shape0->GetType, $shape0->GetType, "->GetShape->GetType" );

ok( $point, "RayCast point" );
is( $point->x, 3, "->x" );
is( $point->y, 5, "->y" );

ok( $normal, "RayCast normal" );
is( $normal->x, -1, "->x" );
is( $normal->y, 0,  "->y" );

ok( $fraction, "RayCast fraction" );
cmp_ok( abs( $fraction - 0.3 ), "<=", 0.0000001, "<=" );

{
    my $cb = Box2D::PerlRayCastCallback->new( sub { } );
}
pass("Didn't die");

done_testing;
