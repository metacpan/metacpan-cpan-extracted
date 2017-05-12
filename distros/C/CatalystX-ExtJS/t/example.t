use strict;
use Test::More;
use lib qw(example/lib);

BEGIN { use_ok 'Catalyst::Test', 'MyApp' }

ok( request('/')->is_success, 'Request should succeed' );

done_testing();
