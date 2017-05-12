use strict;
use warnings;
use Box2D;
use Test::More;

my $vec = Box2D::b2Vec2->new( 0, -10 );
my $world = Box2D::b2World->new( $vec, 1 );

my $body_def = Box2D::b2BodyDef->new();

my $type0 = Box2D::b2_dynamicBody;
$body_def->type($type0);

my ( $x0, $y0 ) = ( 11.0, 12.0 );
$body_def->position->Set( $x0, $y0 );

my $angle0 = 1.0;
$body_def->angle($angle0);

my $body = $world->CreateBody($body_def);
isa_ok( $body, "Box2D::b2Body" );

my $position = $body->GetPosition();
pass("GetPosition");

isa_ok( $position, "Box2D::b2Vec2" );

is( $position->x, $x0, "GetPosition x" );
is( $position->y, $y0, "GetPosition y" );

my ( $v0_x, $v0_y ) = ( 1.0, 2.0 );
my $v0 = Box2D::b2Vec2->new( $v0_x, $v0_y );

$body->SetLinearVelocity($v0);
pass("SetLinearVelocity");

my $v = $body->GetLinearVelocity();
pass("GetLinearVelocity");

isa_ok( $v, "Box2D::b2Vec2" );

is( $v->x, $v0_x, "LinearVelocity x" );
is( $v->y, $v0_y, "LinearVelocity y" );

my $v0_ang = 1.0;
$body->SetAngularVelocity($v0_ang);
pass("SetAngularVelocity");

is( $body->GetAngularVelocity(), $v0_ang, "GetAngularVelocity" );

is( $body->GetType(), $type0, "GetType" );

my $type1 = Box2D::b2_kinematicBody;
$body->SetType($type1);
is( $body->GetType(), $type1, "SetType" );

is( $body->GetAngle(), $angle0, "GetAngle" );

my $transform = $body->GetTransform();
cmp_ok( abs( $transform->GetAngle() - $angle0 ),
    "<=", 0.00000001, "GetTransform angle" );

done_testing;
