#!/usr/bin/perl -wT

use strict;
use Test::More qw(no_plan);

BEGIN {
	use_ok('Array::Utils');
}

require_ok('Array::Utils');

use Array::Utils qw(:all);

my @a = qw( a b c d );
my @b = qw( c d e f );

ok ( array_diff(@a, @b), "Array members comparison - different arrays" );
ok ( !array_diff(@a, @a), "Array members comparison - same array" );

my @union_ethalon = qw( a b c d e f );
my @isect_ethalon = qw( c d );
my @diff_ethalon = qw( a b e f );
my @minus_ethalon = qw( a b );

my @union = unique(@a, @b);
is ( scalar(@union), 6, "Array unique union count" );
ok ( !array_diff( @union, @union_ethalon ), "Array unique union" );

my @isect = intersect(@a, @b);
is( scalar(@isect), 2, "Array intersection count" );
ok ( !array_diff( @isect, @isect_ethalon ), "Array intersection" );

my @diff = array_diff(@a, @b);
is ( scalar(@diff), 4, "Array symmetric difference count" );
ok ( !array_diff( @diff, @diff_ethalon), "Array symmetric difference" );

my @empty = ();

ok ( array_diff( @a, @empty ), "Array diff with empty array");
ok ( array_diff( @empty, @a ), "Array diff with empty array reverse order");
ok ( !array_diff( @empty, @empty ), "Array diff with empty arrays");

my @minus = array_minus( @a, @b );
is( scalar( @minus ), 2, "Array minus count" );
ok( !array_diff( @minus, @minus_ethalon ), "Array minus" );

ok( !array_minus( @empty, @b ), "Empty array minus an array" );
@minus = array_minus( @a, @empty );
ok( !array_diff( @a, @minus ), "Substracting an empty array has no effect" );
