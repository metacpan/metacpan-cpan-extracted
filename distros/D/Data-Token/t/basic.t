use Test::More tests => 2;

BEGIN {
use_ok( 'Data::Token' );
}
ok(token(), "Get a token");
