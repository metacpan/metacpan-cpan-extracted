use strict;
use warnings;
use Box2D;
use Test::More;

my $gravity = Box2D::b2Vec2->new( 0.0, 0.0 );
my $world = Box2D::b2World->new( $gravity, 1 );

my $groundDef   = Box2D::b2BodyDef->new();
my $ground      = $world->CreateBody($groundDef);
my $groundShape = Box2D::b2PolygonShape->new();
$ground->CreateFixture( $groundShape, 0.0 );

my ( $x1, $y1, ) = ( 10.0, 20.0 );

my $bodyDefB1 = Box2D::b2BodyDef->new();
$bodyDefB1->position->Set( $x1, $y1 );
$bodyDefB1->type(Box2D::b2_dynamicBody);
my $bodyB1   = $world->CreateBody($bodyDefB1);
my $circleB1 = Box2D::b2CircleShape->new();
$circleB1->m_radius(50.0);
$bodyB1->CreateFixture( $circleB1, 1.0 );

my $anchorA
    = Box2D::b2Vec2->new( $x1, $y1 );

my $jointDef1 = Box2D::b2RevoluteJointDef->new();
$jointDef1->Initialize( $ground, $bodyB1, $anchorA );
my $joint1 = $world->CreateJoint($jointDef1);

my ( $x2, $y2 ) = ( 30.0, 40.0 );

my $bodyDefB2 = Box2D::b2BodyDef->new();
$bodyDefB2->position->Set( $x2, $y2 );
$bodyDefB2->type(Box2D::b2_dynamicBody);
my $bodyB2   = $world->CreateBody($bodyDefB2);
my $circleB2 = Box2D::b2CircleShape->new();
$circleB2->m_radius(50.0);
$bodyB2->CreateFixture( $circleB2, 1.0 );

my $anchorB = Box2D::b2Vec2->new( $x2, $y2 );

my $jointDef2 = Box2D::b2RevoluteJointDef->new();
$jointDef2->Initialize( $ground, $bodyB2, $anchorB );
my $joint2 = $world->CreateJoint($jointDef2);

my $jointDef = Box2D::b2GearJointDef->new();
ok($jointDef);
isa_ok( $jointDef, "Box2D::b2GearJointDef" );

$jointDef->bodyA($bodyB1);
pass("Set bodyA");

$jointDef->bodyB($bodyB2);
pass("Set bodyB");

$jointDef->joint1($joint1);
pass("Set joint1");

$jointDef->joint2($joint2);
pass("Set joint2");

my $ratio = 1.0;
$jointDef->ratio($ratio);
pass("Set ratio");

is( $jointDef->joint1->GetBodyA->GetWorldCenter->x,
    $ground->GetWorldCenter->x,
    "Get joint1->GetBodyA->GetWorldCenter->x"
);
is( $jointDef->joint1->GetBodyA->GetWorldCenter->y,
    $ground->GetWorldCenter->y,
    "Get joint1->GetBodyA->GetWorldCenter->y"
);

is( $jointDef->joint1->GetBodyB->GetWorldCenter->x,
    $bodyB1->GetWorldCenter->x,
    "Get joint1->GetBodyB->GetWorldCenter->x"
);
is( $jointDef->joint1->GetBodyB->GetWorldCenter->y,
    $bodyB1->GetWorldCenter->y,
    "Get joint1->GetBodyB->GetWorldCenter->y"
);

is( $jointDef->joint2->GetBodyA->GetWorldCenter->x,
    $ground->GetWorldCenter->x,
    "Get joint2->GetBodyA->GetWorldCenter->x"
);
is( $jointDef->joint2->GetBodyA->GetWorldCenter->y,
    $ground->GetWorldCenter->y,
    "Get joint2->GetBodyA->GetWorldCenter->y"
);

is( $jointDef->joint2->GetBodyB->GetWorldCenter->x,
    $bodyB2->GetWorldCenter->x,
    "Get joint2->GetBodyB->GetWorldCenter->x"
);
is( $jointDef->joint2->GetBodyB->GetWorldCenter->y,
    $bodyB2->GetWorldCenter->y,
    "Get joint2->GetBodyB->GetWorldCenter->y"
);

is( $jointDef->ratio, $ratio, "get ratio" );
$ratio = 2.0;
$jointDef->ratio($ratio);
is( $jointDef->ratio, $ratio, "set ratio" );

my $joint = $world->CreateJoint($jointDef);
ok($joint);
isa_ok( $joint, "Box2D::b2Joint" );

bless $joint, 'Box2D::b2GearJoint';
isa_ok( $joint, "Box2D::b2GearJoint" );

is( $joint->GetAnchorA->x, $anchorA->x, "GetAnchorA->x" );
is( $joint->GetAnchorA->y, $anchorA->y, "GetAnchorA->y" );
is( $joint->GetAnchorB->x, $anchorB->x, "GetAnchorB->x" );
is( $joint->GetAnchorB->y, $anchorB->y, "GetAnchorB->y" );

is( $joint->GetRatio, $ratio, "GetRatio" );
$ratio = 3.0;
$joint->SetRatio($ratio);
is( $joint->GetRatio, $ratio, "SetRatio" );

done_testing;
