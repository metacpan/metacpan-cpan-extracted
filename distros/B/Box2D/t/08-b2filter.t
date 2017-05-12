use strict;
use warnings;
use Box2D;
use Test::More;

my $filter = Box2D::b2Filter->new();
ok($filter);
isa_ok( $filter, "Box2D::b2Filter" );

my ( $categoryBits, $maskBits, $groupIndex ) = ( 0x5, 0x7, -9 );
$filter->categoryBits($categoryBits);
$filter->maskBits($maskBits);
$filter->groupIndex($groupIndex);
is( $filter->categoryBits, $categoryBits, "get categoryBits" );
is( $filter->maskBits,     $maskBits,     "get maskBits" );
is( $filter->groupIndex,   $groupIndex,   "get groupIndex" );

done_testing;
