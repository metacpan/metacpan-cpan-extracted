use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'MyAtom' }
BEGIN { use_ok 'MyAtom::Controller::MyService' }

ok( request('/myservice')->is_success, 'Request should succeed' );


