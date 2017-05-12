use Test::More tests => 2;

BEGIN {
use_ok( 'Alien::CodePress' );
}

diag( "Testing Alien::CodePress $Alien::CodePress::VERSION" );
ok( Alien::CodePress->version, '->version');
