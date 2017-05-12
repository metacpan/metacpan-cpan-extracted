use Test::More tests => 4;

use lib "../lib";

BEGIN {
use_ok( 'Catalyst::Enzyme' );
use_ok( 'Catalyst::Enzyme::CRUD::Model' );
use_ok( 'Catalyst::Enzyme::CRUD::View' );
use_ok( 'Catalyst::Enzyme::CRUD::Controller' );
}

diag( "Testing Catalyst::Enzyme $Catalyst::Enzyme::VERSION, Perl 5.008006");
