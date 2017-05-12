use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

ok(get('/'), 'getting /');
isa_ok($::browser, 'HTTP::BrowserDetect');

done_testing;
