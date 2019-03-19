#!perl

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Catalyst::Test 'TestApp';
use HTTP::Request::Common;

use Test::More tests => 5;

action_ok('/', 'check if the thing runs at all');

my $resp = request('/conneg');
is($resp->code, 200, 'second response code is ok');
is($resp->content_type, 'application/json', 'should be json');
diag($resp->as_string);

$resp = request(GET '/conneg', Accept => 'text/html;q=1.0, */*;q=0');
is($resp->code, 200, 'second response code is ok');
is($resp->content_type, 'text/html', 'should be html');
