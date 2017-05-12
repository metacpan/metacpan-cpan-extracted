use strict;
use warnings;
use Test::More;

plan skip_all => 'set XMLRPC_TEST_LIVE to enable this test' unless $ENV{XMLRPC_TEST_LIVE};
plan tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestApp::Model::XMLRPC;

ok(my $xmlrpc = TestApp::Model::XMLRPC->new, 'created model class');

my $res = $xmlrpc->send_request('geocode', '111 Main St, Anytown, KS');

ok(! $res->is_fault, 'server response okay');
ok($res->value, 'got entries');
