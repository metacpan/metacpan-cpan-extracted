use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'App::Cinema' }
BEGIN { use_ok 'App::Cinema::Controller::Database' }

ok( request('/database')->is_success, 'Request should succeed' );
done_testing();
