use Test::More tests => 3;

BEGIN {
use_ok( 'App::SimpleScan' );
use_ok( 'App::SimpleScan::Substitution' );
use_ok( 'App::SimpleScan::Substitution::Line' );
}

diag( "Testing App::SimpleScan $App::SimpleScan::VERSION" );
diag( "Testing App::SimpleScan::Substitution $App::SimpleScan::Substitution::VERSION" );
diag( "Testing App::SimpleScan::Substitution::Line $App::SimpleScan::Substitution::Line::VERSION" );

