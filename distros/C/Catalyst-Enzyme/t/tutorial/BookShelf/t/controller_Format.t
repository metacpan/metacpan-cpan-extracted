use strict;
use Test::More tests => 3;
use_ok( 'Catalyst::Test', 'BookShelf' );
use_ok('BookShelf::Controller::Format');

ok( request('/format')->is_success );
