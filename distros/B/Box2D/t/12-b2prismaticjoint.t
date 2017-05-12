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

my $anchor = Box2D::b2Vec2->new( ( $xA + $xB ) / 2.0, ( $yA + $yB ) / 2.0 );
my $axis = Box2D::b2Vec2->new( 10, 2.0 );

my $jointDef = Box2D::b2PrismaticJointDef->new();
ok( $jointDef, "new" );
isa_ok( $jointDef, "Box2D::b2PrismaticJointDef" );

$jointDef->Initialize( $bodyA, $bodyB, $anchor, $axis );
pass("Initialize");

is( $jointDef->localAnchorA->x,
    $anchor->x - $bodyA->GetWorldCenter->x,
    "get localAnchorA->x"
);
is( $jointDef->localAnchorA->y,
    $anchor->y - $bodyA->GetWorldCenter->y,
    "get localAnchorA->y"
);
is( $jointDef->localAnchorB->x,
    $anchor->x - $bodyB->GetWorldCenter->x,
    "get localAnchorB->x"
);
is( $jointDef->localAnchorB->y,
    $anchor->y - $bodyB->GetWorldCenter->y,
    "get localAnchorB->y"
);

is( $jointDef->localAxis1->x, $axis->x, "get localAxis1->x" );
is( $jointDef->localAxis1->y, $axis->y, "get localAxis1->y" );

my ($referenceAngle, $lowerTranslation, $upperTranslation,
    $motorSpeed,     $maxMotorForce
) = ( 0.5, -10.0, 12.0, 11.0, 13.0 );

$jointDef->referenceAngle($referenceAngle);
pass("set referenceAngle");
is( $jointDef->referenceAngle, $referenceAngle, "get referenceAngle" );

$jointDef->lowerTranslation($lowerTranslation);
pass("set lowerTranslation");
is( $jointDef->lowerTranslation, $lowerTranslation, "get lowerTranslation" );

$jointDef->upperTranslation($upperTranslation);
pass("set upperTranslation");
is( $jointDef->upperTranslation, $upperTranslation, "get upperTranslation" );

$jointDef->enableLimit(1);
pass("set enableLimit");
ok( $jointDef->enableLimit, "get enableLimit" );
$jointDef->enableLimit(0);
ok( !$jointDef->enableLimit, "get enableLimit" );
$jointDef->enableLimit(1);

$jointDef->enableMotor(1);
pass("set enableMotor");
ok( $jointDef->enableMotor, "get enableMotor" );
$jointDef->enableMotor(0);
ok( !$jointDef->enableMotor, "get enableMotor" );
$jointDef->enableMotor(1);

$jointDef->motorSpeed($motorSpeed);
pass("set motorSpeed");
is( $jointDef->motorSpeed, $motorSpeed, "get motorSpeed" );

$jointDef->maxMotorForce($maxMotorForce);
pass("set maxMotorForce");
is( $jointDef->maxMotorForce, $maxMotorForce, "get maxMotorForce" );

my $joint = $world->CreateJoint($jointDef);
ok( $joint, "Box2D::b2World->CreateJoint" );
isa_ok( $joint, "Box2D::b2Joint" );

bless $joint, "Box2D::b2PrismaticJoint";
isa_ok( $joint, "Box2D::b2PrismaticJoint" );

is( $joint->GetAnchorA->x, $anchor->x, "GetAnchorA->x" );
is( $joint->GetAnchorA->y, $anchor->y, "GetAnchorA->y" );
is( $joint->GetAnchorB->x, $anchor->x, "GetAnchorB->x" );
is( $joint->GetAnchorB->y, $anchor->y, "GetAnchorB->y" );

ok( $joint->IsLimitEnabled(), "IsLimitEnabled" );
$joint->EnableLimit(0);
pass("EnableLimit");
ok( !$joint->IsLimitEnabled(), "IsLimitEnabled" );
$joint->EnableLimit(1);
ok( $joint->IsLimitEnabled(), "IsLimitEnabled" );

is( $joint->GetLowerLimit(), $lowerTranslation, "GetLowerLimit" );
is( $joint->GetUpperLimit(), $upperTranslation, "GetUpperLimit" );

my ( $lowerLimit, $upperLimit ) = ( 1.0, 2.0 );
$joint->SetLimits( $lowerLimit, $upperLimit );
is( $joint->GetLowerLimit(), $lowerLimit, "GetLowerLimit" );
is( $joint->GetUpperLimit(), $upperLimit, "GetUpperLimit" );

ok( $joint->IsMotorEnabled(), "IsMotorEnabled" );
$joint->EnableMotor(0);
pass("EnableMotor");
ok( !$joint->IsMotorEnabled(), "IsMotorEnabled" );
$joint->EnableMotor(1);
ok( $joint->IsMotorEnabled(), "IsMotorEnabled" );

is( $joint->GetMotorSpeed(), $motorSpeed, "GetMotorSpeed" );
my $speed = 15.0;
$joint->SetMotorSpeed($speed);
pass("SetMotorSpeed");
is( $joint->GetMotorSpeed(), $speed, "GetMotorSpeed" );

done_testing;
