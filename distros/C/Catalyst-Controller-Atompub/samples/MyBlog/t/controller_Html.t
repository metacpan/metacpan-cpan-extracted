use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'MyBlog' }
BEGIN { use_ok 'MyBlog::Controller::Html' }

ok( request('/html')->is_success, 'Request should succeed' );


