use strict;
use warnings;
use Box2D;
use Test::More;

ok( Box2D::b2Math::b2IsValid(0.0),  "b2IsValid" );
ok( Box2D::b2Math::b2IsValid(1.0),  "b2IsValid" );
ok( Box2D::b2Math::b2IsValid(-1.0), "b2IsValid" );

cmp_ok( abs( Box2D::b2Math::b2InvSqrt(4.0) - 0.5 ), "<=", 0.001,
    "b2InvSqrt" );

is( Box2D::b2Math::b2Abs(1.0),  1.0, "b2Abs" );
is( Box2D::b2Math::b2Abs(-1.0), 1.0, "b2Abs" );

my $a = Box2D::b2Vec2->new( 1, 2 );
my $b = Box2D::b2Vec2->new( 3, 4 );
my $m = Box2D::b2Mat22->new( 5, 6, 7, 8 );
my $s = 9;

{
    my $c = Box2D::b2Math::b2DotV2V2( $a, $b );
    is( $c, $a->x * $b->x + $a->y * $b->y, "b2DotV2V2" );
}

{
    my $c = Box2D::b2Math::b2CrossV2V2( $a, $b );
    is( $c, $a->x * $b->y - $a->y * $b->x, "b2CrossV2V2" );
}

{
    my $c = Box2D::b2Math::b2CrossV2S( $a, $s );
    is( $c->x, $s * $a->y,  "b2CrossV2S" );
    is( $c->y, -$s * $a->x, "b2CrossV2S" );
}

{
    my $c = Box2D::b2Math::b2CrossSV2( $s, $a );
    is( $c->x, -$s * $a->y, "b2CrossSV2" );
    is( $c->y, $s * $a->x,  "b2CrossSV2" );
}

{
    my $c = Box2D::b2Math::b2MulM22V2( $m, $a );
    is( $c->x, $m->col1->x * $a->x + $m->col2->x * $a->y, "b2MulM22V2" );
    is( $c->y, $m->col1->y * $a->x + $m->col2->y * $a->y, "b2MulM22V2" );
}

{
    my $c = Box2D::b2Math::b2MulTM22V2( $m, $a );
    is( $c->x, Box2D::b2Math::b2DotV2V2( $a, $m->col1 ), "b2MulTM22V2" );
    is( $c->y, Box2D::b2Math::b2DotV2V2( $a, $m->col2 ), "b2MulTM22V2" );
}

{
    my $c = Box2D::b2Math::b2AddV2V2( $a, $b );
    is( $c->x, $a->x + $b->x, "b2AddV2V2" );
    is( $c->y, $a->y + $b->y, "b2AddV2V2" );
}

{
    my $c = Box2D::b2Math::b2SubV2V2( $a, $b );
    is( $c->x, $a->x - $b->x, "b2SubV2V2" );
    is( $c->y, $a->y - $b->y, "b2SubV2V2" );
}

{
    my $c = Box2D::b2Math::b2MulSV2( $s, $a );
    is( $c->x, $s * $a->x, "b2MulSV2" );
    is( $c->y, $s * $a->y, "b2MulSV2" );
}

{
    ok( !( Box2D::b2Math::b2EqlV2V2( $a, $b ) ), "b2EqlV2V2" );
    ok( !( Box2D::b2Math::b2EqlV2V2( $b, $a ) ), "b2EqlV2V2" );
    ok( Box2D::b2Math::b2EqlV2V2( $a, $a ), "b2EqlV2V2" );
    ok( Box2D::b2Math::b2EqlV2V2( $b, $b ), "b2EqlV2V2" );

    my $c = Box2D::b2Vec2->new( $a->x, $a->y );
    ok( Box2D::b2Math::b2EqlV2V2( $a, $c ), "b2EqlV2V2" );
}

{
    my $c = Box2D::b2Math::b2Distance( $a, $b );
    is( $c, Box2D::b2Math::b2SubV2V2( $a, $b )->Length, "b2Distance" );
}

{
    my $c = Box2D::b2Math::b2DistanceSquared( $a, $b );
    my $d = Box2D::b2Math::b2SubV2V2( $a, $b );
    is( $c, Box2D::b2Math::b2DotV2V2( $d, $d ), "b2DistanceSquared" );
}

done_testing;
