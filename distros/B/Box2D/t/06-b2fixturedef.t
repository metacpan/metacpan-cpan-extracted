use strict;
use warnings;
use Box2D;
use Test::More;

my $fixtureDef = Box2D::b2FixtureDef->new();
pass("Create b2FixtureDef");

my $shape = Box2D::b2PolygonShape->new();
$fixtureDef->shape($shape);
pass("set shape");
my $shape_ = $fixtureDef->shape;
pass("get shape");
is( $shape_->GetType, $shape->GetType, "shape GetType" );
is( $shape_->m_radius, $shape->m_radius, "shape m_radius" );

my $density = 0.5;
$fixtureDef->density($density);
pass("set density");
is( $fixtureDef->density, $density, "get density" );

my $friction = 0.5;
$fixtureDef->friction($friction);
pass("set friction");
is( $fixtureDef->friction, $friction, "get friction" );

my $restitution = 0.5;
$fixtureDef->restitution($restitution);
pass("set restitution");
is( $fixtureDef->restitution, $restitution, "get restitution" );

my ( $categoryBits, $maskBits, $groupIndex ) = ( 0x2, 0x5, -3 );
$fixtureDef->filter->categoryBits($categoryBits);
$fixtureDef->filter->maskBits($maskBits);
$fixtureDef->filter->groupIndex($groupIndex);
is( $fixtureDef->filter->categoryBits, $categoryBits, "get filter->categoryBits" );
is( $fixtureDef->filter->maskBits,     $maskBits,     "get filter->maskBits" );
is( $fixtureDef->filter->groupIndex,   $groupIndex,   "get filter->groupIndex" );

done_testing;
