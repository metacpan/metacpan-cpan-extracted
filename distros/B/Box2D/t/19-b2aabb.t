use strict;
use warnings;
use Box2D;
use Test::More;
use List::Util qw( min max );

my $aabb = Box2D::b2AABB->new();
ok( $aabb, "new" );
isa_ok( $aabb, "Box2D::b2AABB" );

my $lower = Box2D::b2Vec2->new( 1.0, 2.0 );
my $upper = Box2D::b2Vec2->new( 3.0, 4.0 );

$aabb->lowerBound($lower);
$aabb->upperBound($upper);

ok( $aabb->IsValid(), "IsValid" );

is( $aabb->lowerBound->x, $lower->x, "Get lowerBound->x" );
is( $aabb->lowerBound->y, $lower->y, "Get lowerBound->y" );
is( $aabb->upperBound->x, $upper->x, "Get upperBound->x" );
is( $aabb->upperBound->y, $upper->y, "Get upperBound->y" );

is( $aabb->GetCenter->x, ( $lower->x + $upper->x ) / 2.0, "GetCenter->x" );
is( $aabb->GetCenter->y, ( $lower->y + $upper->y ) / 2.0, "GetCenter->y" );

is( $aabb->GetExtents->x, ( $upper->x - $lower->x ) / 2.0, "GetExtents->x" );
is( $aabb->GetExtents->y, ( $upper->y - $lower->y ) / 2.0, "GetExtents->y" );

my $aabb1 = Box2D::b2AABB->new();
my $aabb2 = Box2D::b2AABB->new();

my $lower1 = Box2D::b2Vec2->new( 5.0,  6.0 );
my $upper1 = Box2D::b2Vec2->new( 7.0,  8.0 );
my $lower2 = Box2D::b2Vec2->new( 9.0,  10.0 );
my $upper2 = Box2D::b2Vec2->new( 11.0, 12.0 );

$aabb1->lowerBound($lower1);
$aabb1->upperBound($upper1);
$aabb2->lowerBound($lower2);
$aabb2->upperBound($upper2);

$aabb->Combine( $aabb1, $aabb2 );
pass("Combine");

is( $aabb->lowerBound->x, min( $lower1->x, $lower2->x ),
    "Get lowerBound->x" );
is( $aabb->lowerBound->y, min( $lower1->y, $lower2->y ),
    "Get lowerBound->y" );
is( $aabb->upperBound->x, max( $upper1->x, $upper2->x ),
    "Get upperBound->x" );
is( $aabb->upperBound->y, max( $upper1->y, $upper2->y ),
    "Get upperBound->y" );

ok( $aabb->Contains($aabb1), "Contains" );
ok( $aabb->Contains($aabb2), "Contains" );

my $input  = Box2D::b2RayCastInput->new();
my $output = Box2D::b2RayCastOutput->new();

my $p1 = Box2D::b2Vec2->new( 1.0, 2.0 );
my $p2 = Box2D::b2Vec2->new( 6.0, 10.0 );
my $maxFraction = 1.0;
$input->p1($p1);
$input->p2($p2);
$input->maxFraction($maxFraction);

ok( $aabb->RayCast( $output, $input ), "RayCast" );

cmp_ok( $output->fraction, ">=", 0.0 );
cmp_ok( $output->fraction, "<=", 1.0 );

is( $output->normal->x, -1.0 );
is( $output->normal->y, 0.0 );

done_testing;
