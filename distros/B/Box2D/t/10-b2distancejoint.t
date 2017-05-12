use strict;
use warnings;
use Box2D;
use Test::More;

my $gravity = Box2D::b2Vec2->new( 0.0, 0.0 );
my $world = Box2D::b2World->new( $gravity, 1 );

my ( $xA, $yA, $xB, $yB ) = ( 10.0, 20.0, 30.0, 40.0 );

my $bodyDefA = Box2D::b2BodyDef->new();
$bodyDefA->position->Set( $xA, $yA );
my $bodyA   = $world->CreateBody($bodyDefA);
my $circleA = Box2D::b2CircleShape->new();
$circleA->m_radius(5.0);
$bodyA->CreateFixture( $circleA, 0.0 );

my $bodyDefB = Box2D::b2BodyDef->new();
$bodyDefB->position->Set( $xB, $yB );
$bodyDefB->type(Box2D::b2_dynamicBody);
my $bodyB   = $world->CreateBody($bodyDefB);
my $circleB = Box2D::b2CircleShape->new();
$circleB->m_radius(5.0);
$bodyB->CreateFixture( $circleB, 1.0 );

my ( $dxA, $dyA, $dxB, $dyB ) = ( 1.0, 2.0, 3.0, 4.0 );

my $anchorA = Box2D::b2Vec2->new( $xA + $dxA, $yA + $dyA );
my $anchorB = Box2D::b2Vec2->new( $xB + $dxB, $yB + $dyB );

my $jointDef = Box2D::b2DistanceJointDef->new();
ok( $jointDef, "new" );
isa_ok( $jointDef, "Box2D::b2DistanceJointDef" );

$jointDef->Initialize( $bodyA, $bodyB, $anchorA, $anchorB );
pass( "Initialize" );

is( $jointDef->localAnchorA->x, $dxA,          "get localAnchorA->x" );
is( $jointDef->localAnchorA->y, $dyA,          "get localAnchorA->y" );
is( $jointDef->localAnchorB->x, $dxB,          "get localAnchorB->x" );
is( $jointDef->localAnchorB->y, $dyB,          "get localAnchorB->y" );

my ( $defLength, $frequencyHz, $dampingRatio ) = ( 50.0, 4.0, 0.5 );

$jointDef->length($defLength);
pass("set length");
is( $jointDef->length, $defLength, "get length" );

$jointDef->frequencyHz($frequencyHz);
pass("set frequencyHz");
is( $jointDef->frequencyHz, $frequencyHz, "get frequencyHz" );

$jointDef->dampingRatio($dampingRatio);
pass("set dampingRatio");
is( $jointDef->dampingRatio, $dampingRatio, "get dampingRatio" );

my $joint = $world->CreateJoint($jointDef);
ok( $joint, "Box2D::b2World->CreateJoint" );
isa_ok( $joint, "Box2D::b2Joint" );

bless $joint, "Box2D::b2DistanceJoint";
isa_ok( $joint, "Box2D::b2DistanceJoint" );

is( $joint->GetAnchorA->x, $anchorA->x, "GetAnchorA->x" );
is( $joint->GetAnchorA->y, $anchorA->y, "GetAnchorA->y" );
is( $joint->GetAnchorB->x, $anchorB->x, "GetAnchorB->x" );
is( $joint->GetAnchorB->y, $anchorB->y, "GetAnchorB->y" );

is( $joint->GetFrequency(),    $frequencyHz,  "GetFrequency" );
is( $joint->GetDampingRatio(), $dampingRatio, "GetDampingRatio" );

my ( $length, $frequency, $damping ) = ( 10.0, 12.0, 14.0 );

$joint->SetLength($length);
pass("SetLength");
is( $joint->GetLength(), $length, "GetLength" );

$joint->SetFrequency($frequency);
is( $joint->GetFrequency(), $frequency, "SetFrequency" );

$joint->SetDampingRatio($damping);
is( $joint->GetDampingRatio(), $damping, "SetDampingRatio" );

done_testing;
