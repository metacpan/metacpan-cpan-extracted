use strict;
use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

is get('/hello?q=foo'), 'dummy-test:{{foo}}', 'dummy filter';

unlike get('/redirect'), qr/dummy/, 'status 302';
