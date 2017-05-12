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
$circleA->m_radius(50.0);
$bodyA->CreateFixture( $circleA, 0.0 );

my $bodyDefB = Box2D::b2BodyDef->new();
$bodyDefB->position->Set( $xB, $yB );
$bodyDefB->type(Box2D::b2_dynamicBody);
my $bodyB   = $world->CreateBody($bodyDefB);
my $circleB = Box2D::b2CircleShape->new();
$circleB->m_radius(50.0);
$bodyB->CreateFixture( $circleB, 1.0 );

my $jointDef = Box2D::b2MouseJointDef->new();
ok( $jointDef, "new" );
isa_ok( $jointDef, "Box2D::b2MouseJointDef" );

$jointDef->bodyA($bodyA);
$jointDef->bodyB($bodyB);

my $target
    = Box2D::b2Vec2->new( $bodyA->GetPosition->x, $bodyA->GetPosition->y );
my $maxForce     = 3.0;
my $frequencyHz  = 4.0;
my $dampingRatio = 5.0;

$jointDef->target($target);
pass("set target");

$jointDef->maxForce($maxForce);
pass("set maxForce");

$jointDef->frequencyHz($frequencyHz);
pass("set frequencyHz");

$jointDef->dampingRatio($dampingRatio);
pass("set dampingRatio");

is( $jointDef->target->x,    $target->x,    "get target->x" );
is( $jointDef->target->y,    $target->y,    "get target->y" );
is( $jointDef->maxForce,     $maxForce,     "get maxForce" );
is( $jointDef->frequencyHz,  $frequencyHz,  "get frequencyHz" );
is( $jointDef->dampingRatio, $dampingRatio, "get dampingRatio" );

my $joint = $world->CreateJoint($jointDef);
ok( $joint, "new" );
isa_ok( $joint, "Box2D::b2Joint" );

bless $joint, "Box2D::b2MouseJoint";
isa_ok( $joint, "Box2D::b2MouseJoint" );

is( $joint->GetTarget->x,    $target->x,    "get GetTarget->x" );
is( $joint->GetTarget->y,    $target->y,    "get GetTarget->y" );
is( $joint->GetMaxForce,     $maxForce,     "get GetMaxForce" );
is( $joint->GetFrequency,    $frequencyHz,  "get GetFrequency" );
is( $joint->GetDampingRatio, $dampingRatio, "get GetDampingRatio" );

$target       = Box2D::b2Vec2->new( 1.0, 2.0 );
$maxForce     = 4.0;
$frequencyHz  = 5.0;
$dampingRatio = 6.0;

$joint->SetTarget($target);
$joint->SetMaxForce($maxForce);
$joint->SetFrequency($frequencyHz);
$joint->SetDampingRatio($dampingRatio);

is( $joint->GetTarget->x,    $target->x,    "set GetTarget->x" );
is( $joint->GetTarget->y,    $target->y,    "set GetTarget->y" );
is( $joint->GetMaxForce,     $maxForce,     "set GetMaxForce" );
is( $joint->GetFrequency,    $frequencyHz,  "set GetFrequency" );
is( $joint->GetDampingRatio, $dampingRatio, "set GetDampingRatio" );

done_testing;
