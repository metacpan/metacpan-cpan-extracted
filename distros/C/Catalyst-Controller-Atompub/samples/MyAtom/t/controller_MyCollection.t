use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'MyAtom' }
BEGIN { use_ok 'MyAtom::Controller::MyCollection' }

ok( request('/mycollection')->is_success, 'Request should succeed' );


