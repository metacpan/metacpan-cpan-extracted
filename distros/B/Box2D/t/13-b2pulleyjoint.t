use strict;
use warnings;
use Box2D;
use Test::More;

my $gravity = Box2D::b2Vec2->new( 0.0, 10.0 );
my $world = Box2D::b2World->new( $gravity, 1 );

# Bodies
my ( $xA, $yA, $xB, $yB ) = ( 10.0, 20.0, 30.0, 40.0 );

my ( $lengthA,    $lengthB )    = ( 10.0, 12.0 );
my ( $maxLengthA, $maxLengthB ) = ( 14.0, 16.0 );

my $ratio = 1.0;

# Grounds
my ( $xGA, $yGA, $xGB, $yGB ) = ( $xA, $yA - $lengthA, $xB, $yB - $lengthB );

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

my $anchorA = Box2D::b2Vec2->new( $xA, $yA );
my $anchorB = Box2D::b2Vec2->new( $xB, $yB );

my $groundAnchorA = Box2D::b2Vec2->new( $xGA, $yGA );
my $groundAnchorB = Box2D::b2Vec2->new( $xGB, $yGB );

my $jointDef = Box2D::b2PulleyJointDef->new();
ok( $jointDef, "Box2D::b2PulleyJointDef->new" );
isa_ok( $jointDef, "Box2D::b2PulleyJointDef" );

$jointDef->Initialize( $bodyA, $bodyB, $groundAnchorA, $groundAnchorB,
    $anchorA, $anchorB, $ratio );
pass("Initialize");

is( $jointDef->groundAnchorA->x, $groundAnchorA->x, "get groundAnchorA->x" );
is( $jointDef->groundAnchorA->y, $groundAnchorA->y, "get groundAnchorA->y" );
is( $jointDef->groundAnchorB->x, $groundAnchorB->x, "get groundAnchorB->x" );
is( $jointDef->groundAnchorB->y, $groundAnchorB->y, "get groundAnchorB->y" );

is( $jointDef->localAnchorA->x,
    $anchorA->x - $bodyA->GetWorldCenter->x,
    "get localAnchorA->x"
);
is( $jointDef->localAnchorA->y,
    $anchorA->y - $bodyA->GetWorldCenter->y,
    "get localAnchorA->y"
);
is( $jointDef->localAnchorB->x,
    $anchorB->x - $bodyB->GetWorldCenter->x,
    "get localAnchorB->x"
);
is( $jointDef->localAnchorB->y,
    $anchorB->y - $bodyB->GetWorldCenter->y,
    "get localAnchorB->y"
);

is( $jointDef->lengthA, $lengthA, "get lengthA" );
is( $jointDef->lengthB, $lengthB, "get lengthB" );

$jointDef->maxLengthA($maxLengthA);
pass("set maxLengthA");
$jointDef->maxLengthB($maxLengthB);
pass("set maxLengthB");
$jointDef->ratio($ratio);
pass("set ratio");

is( $jointDef->maxLengthA, $maxLengthA, "get maxLengthA" );
is( $jointDef->maxLengthB, $maxLengthB, "get maxLengthB" );
is( $jointDef->ratio,      $ratio,      "get ratio" );

my $joint = $world->CreateJoint($jointDef);
ok( $joint, "Box2D::b2World->CreateJoint" );
isa_ok( $joint, "Box2D::b2Joint" );

bless $joint, "Box2D::b2PulleyJoint";
isa_ok( $joint, "Box2D::b2PulleyJoint" );

is( $joint->GetAnchorA->x, $anchorA->x, "GetAnchorA->x" );
is( $joint->GetAnchorA->y, $anchorA->y, "GetAnchorA->y" );
is( $joint->GetAnchorB->x, $anchorB->x, "GetAnchorB->x" );
is( $joint->GetAnchorB->y, $anchorB->y, "GetAnchorB->y" );

is( $joint->GetGroundAnchorA->x, $groundAnchorA->x, "GetGroundAnchorA->x" );
is( $joint->GetGroundAnchorA->y, $groundAnchorA->y, "GetGroundAnchorA->y" );
is( $joint->GetGroundAnchorB->x, $groundAnchorB->x, "GetGroundAnchorB->x" );
is( $joint->GetGroundAnchorB->y, $groundAnchorB->y, "GetGroundAnchorB->y" );

is( $joint->GetLength1, $lengthA, "GetLength1" );
is( $joint->GetLength2, $lengthB, "GetLength2" );

is( $joint->GetRatio, $ratio, "GetRatio" );

done_testing;
