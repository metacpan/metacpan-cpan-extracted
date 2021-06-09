use warnings;
use strict;
use lib 'lib', 't/lib';

use Test::More;
use Test::Deep;
use TestApp::Helper;

TestApp::Helper::run(
    { endpoint => '/testme' },
    '/testme',
    superbagof('http_requests_total{code="200",method="GET"} 1')
);

done_testing;
