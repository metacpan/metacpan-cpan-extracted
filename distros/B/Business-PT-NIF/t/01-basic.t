#!perl -T

use Test::More tests => 16;

BEGIN {
	use_ok( 'Business::PT::NIF', 'valid_nif' );
}

is( valid_nif(), undef );
is( valid_nif('1a3669597'), undef );

ok( ! valid_nif(13669597) );

ok( ! valid_nif(136695970) );
ok( ! valid_nif(136695971) );
ok( ! valid_nif(136695972) );
ok( ! valid_nif(136695974) );
ok( ! valid_nif(136695975) );
ok( ! valid_nif(136695976) );
ok( ! valid_nif(136695977) );
ok( ! valid_nif(136695978) );
ok( ! valid_nif(136695979) );

ok( valid_nif(136695973) );

ok( valid_nif(111111110) );
ok( valid_nif(111111200) );
