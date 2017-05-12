use Test::More tests => 2;

BEGIN {
use_ok( 'Cache::Funky' );
can_ok( 'Cache::Funky', qw/setup register delete/ );
}

diag( "Testing Cache::Funky $Cache::Funky::VERSION" );
