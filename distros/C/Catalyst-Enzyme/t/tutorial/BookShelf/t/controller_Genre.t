use strict;
use Test::More tests => 3;
use_ok( 'Catalyst::Test', 'BookShelf' );
use_ok('BookShelf::Controller::Genre');

ok( request('/genre')->is_success );
