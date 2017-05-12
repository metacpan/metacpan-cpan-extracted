use Test::More tests => 2;

BEGIN {
use_ok( 'Apache2::AuthNSympa' );
use_ok( 'Apache2::AuthZSympa' );
}

diag( "Testing Apache2::AuthZSympa $Apache::AuthZSympa::VERSION" );
