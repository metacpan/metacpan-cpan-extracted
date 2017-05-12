#!perl
use strict;
use Test::More tests => 7;

BEGIN
{
	use_ok('DateTime::Util::Calc',
		'sin_deg', 'cos_deg', 'tan_deg', 'asin_deg', 'acos_deg', );
	use_ok('Math::Trig',
		'tan', 'asin', 'acos', 'deg2rad', 'rad2deg');
}

my $a = rand(360);
is( sin_deg($a), sin(deg2rad($a)) );
is( cos_deg($a), cos(deg2rad($a)) );
is( tan_deg($a), tan(deg2rad($a)) );

is( asin_deg(sin_deg($a)), rad2deg(asin(sin(deg2rad($a)))) );
is( acos_deg(cos_deg($a)), rad2deg(acos(cos(deg2rad($a)))) );

