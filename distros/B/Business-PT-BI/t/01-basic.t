#!perl -T

use Test::More tests => 16;

BEGIN {
	use_ok( 'Business::PT::BI', 'valid_bi' );
}

is( valid_bi(), undef );
is( valid_bi(1234567), undef );
is( valid_bi(12345678), undef );
is( valid_bi(1234567, 1), undef );

ok( ! valid_bi(12345678, 0) );
ok( ! valid_bi(12345678, 1) );
ok( ! valid_bi(12345678, 2) );
ok( ! valid_bi(12345678, 3) );
ok( ! valid_bi(12345678, 4) );
ok( ! valid_bi(12345678, 5) );
ok( ! valid_bi(12345678, 6) );
ok( ! valid_bi(12345678, 7) );
ok( ! valid_bi(12345678, 8) );

ok(   valid_bi(12345678, 9) );

ok(   valid_bi(11111111, 0) );
