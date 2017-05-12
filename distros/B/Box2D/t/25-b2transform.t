use strict;
use warnings;
use Box2D;
use Test::More;

my ( $x,  $y,  $angle )  = ( 7.0,  9.0,  1.0 );
my ( $x2, $y2, $angle2 ) = ( 11.0, 13.0, 2.0 );

my $position  = Box2D::b2Vec2->new( $x,  $y );
my $position2 = Box2D::b2Vec2->new( $x2, $y2 );

my $R  = Box2D::b2Mat22->new();
my $R2 = Box2D::b2Mat22->new();

$R->SetAngle($angle);
$R2->SetAngle($angle2);

my $transform = Box2D::b2Transform->new( $position, $R );

ok( $transform, "new" );

isa_ok( $transform, "Box2D::b2Transform" );

is( $transform->position->x, $x, "position->x" );
is( $transform->position->y, $y, "position->y" );

cmp_ok( abs( $transform->GetAngle() - $angle ), "<=", 0.00000001,
    "GetAngle" );

$transform->Set( $position2, $angle2 );

is( $transform->position->x, $x2, "Set position->x" );
is( $transform->position->y, $y2, "Set position->y" );

cmp_ok( abs( $transform->GetAngle() - $angle2 ),
    "<=", 0.0000001, "Set angle" );

$transform->SetIdentity();

is( $transform->position->x, 0, "SetIdentity position->x" );
is( $transform->position->y, 0, "SetIdentity position->y" );
is( $transform->R->col1->x,  1, "SetIdentity R->col1->x" );
is( $transform->R->col2->x,  0, "SetIdentity R->col2->x" );
is( $transform->R->col1->y,  0, "SetIdentity R->col1->y" );
is( $transform->R->col2->y,  1, "SetIdentity R->col2->y" );

$transform->position($position2);
is( $transform->position->x, $x2, "Set position x" );
is( $transform->position->y, $y2, "Set position y" );

$transform->R($R2);
cmp_ok( abs( $transform->GetAngle() - $angle2 ),
    "<=", 0.0000001, "Set R angle" );

done_testing;
