use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'App::Cinema' }
BEGIN { use_ok 'App::Cinema::Controller::Comment' }

ok( request('/comment')->is_success, 'Request should succeed' );
done_testing();
