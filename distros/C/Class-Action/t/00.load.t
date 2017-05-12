use Test::More tests => 2;

use lib 'lib', '../lib';

BEGIN {
use_ok( 'Class::Action' );
use_ok( 'Class::Action::Step' );
}

diag( "Testing Class::Action $Class::Action::VERSION" );
