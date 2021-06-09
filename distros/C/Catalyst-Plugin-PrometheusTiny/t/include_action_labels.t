use warnings;
use strict;
use lib 'lib', 't/lib';

use Test::More;
use Test::Deep;
use TestApp::Helper;

TestApp::Helper::run(
    { include_action_labels => 1 },
    '/metrics',
    superbagof(
        'http_requests_total{action="index",code="200",controller="TestApp::Controller::Root",method="GET"} 1'
    )
);

done_testing;
