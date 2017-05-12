use strict;
use warnings;
use Box2D;

package My::RayCastCallback;

use base qw(Box2D::b2RayCastCallback);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    $self->{reported} = 0;

    return bless $self, $class;
}

sub ReportFixture {
    my ( $self, $fixture, $point, $normal, $fraction ) = @_;

    $self->{reported}++;

    @$self{qw( fixture point normal fraction )}
        = ( $fixture, $point, $normal, $fraction );

    return 0;
}

package main;
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

my $callback = My::RayCastCallback->new();

ok( $callback, "new" );
isa_ok( $callback, "Box2D::b2RayCastCallback" );

$world->RayCast( $callback, $point1, $point2 );

my ( $reported, $fixture, $point, $normal, $fraction )
    = @$callback{qw( reported fixture point normal fraction )};

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

done_testing;
