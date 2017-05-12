use strict;
use warnings;
use Box2D;
use Test::More;

my $poly = Box2D::b2PolygonShape->new();
$poly->Set(
    Box2D::b2Vec2->new( 0.0, 0.0 ),
    Box2D::b2Vec2->new( 1.0, 0.0 ),
    Box2D::b2Vec2->new( 0.0, 1.0 )
);
pass("Set");

is( $poly->GetVertexCount, 3, "GetVertexCount" );

my $vertex = $poly->GetVertex( 0 );
isa_ok( $vertex, "Box2D::b2Vec2" );
is( $vertex->x, 0 );
is( $vertex->y, 0 );
$vertex = $poly->GetVertex( 1 );
isa_ok( $vertex, "Box2D::b2Vec2" );
is( $vertex->x, 1 );
is( $vertex->y, 0 );
$vertex = $poly->GetVertex( 2 );
isa_ok( $vertex, "Box2D::b2Vec2" );
is( $vertex->x, 0 );
is( $vertex->y, 1 );

my ( $w, $h ) = ( 10.0, 12.0 );
my $rect = Box2D::b2PolygonShape->new();
$rect->SetAsBox( $w / 2.0, $h / 2.0 );
pass("SetAsBox");

is( $rect->GetVertexCount, 4, "GetVertexCount" );

foreach ( 0 .. 3 ) {
    $vertex = $rect->GetVertex($_);
    isa_ok( $vertex, "Box2D::b2Vec2" );
    is( abs( $vertex->x ), $w / 2 );
    is( abs( $vertex->y ), $h / 2 );
}

my ( $x, $y, $angle ) = ( 14.0, 16.0, 0.0 );
my $rect2 = Box2D::b2PolygonShape->new();
$rect2->SetAsBox( $w, $h, Box2D::b2Vec2->new( $x, $y), $angle );
pass("SetAsBox");
is( $rect2->GetVertexCount, 4, "GetVertexCount" );
foreach ( 0 .. 3 ) {
    $vertex = $rect2->GetVertex($_);
    isa_ok( $vertex, "Box2D::b2Vec2" );
    is( abs( $vertex->x - $x ), $w );
    is( abs( $vertex->y - $y ), $h );
}

my $edge = Box2D::b2PolygonShape->new();
$edge->SetAsEdge(
    Box2D::b2Vec2->new( 0.0, 0.0 ),
    Box2D::b2Vec2->new( $w, $h ),
);
pass("SetAsEdge");
is( $edge->GetVertexCount, 2, "GetVertexCount" );
is( $edge->GetVertex(0)->x, 0.0, "GetVertex(0)->x" );
is( $edge->GetVertex(0)->y, 0.0, "GetVertex(0)->y" );
is( $edge->GetVertex(1)->x, $w, "GetVertex(1)->x" );
is( $edge->GetVertex(1)->y, $h, "GetVertex(1)->y" );

done_testing;
