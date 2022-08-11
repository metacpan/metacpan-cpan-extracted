use strict;
use warnings;
use Test::More 0.88;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
ok(($response = request("/test?view=ExposeMethods&template=expose_methods.tt"))->is_success, 'request ok');
is($response->content, "magic added param", 'message ok');
ok(($response = request("/test?view=ExposeMethodsSubclassed&template=expose_methods.tt"))->is_success, 'request ok');
is($response->content, "magic added param", 'message ok');

ok $TestApp::Log->is_empty, "no logged errors";

ok( $response = request("/test?view=ExposeMethods&template=exposed_method_fails.tt")->is_error, 'request fails');

ok $TestApp::Log->contains( sub { $_[0] =~ /no param passed/ } ), 'expected log message';
$TestApp::Log->clear;

ok( $response = request("/test?view=ExposeMethods&template=other_exposed_method_dies.tt")->is_error, 'request fails');

ok $TestApp::Log->contains( sub { $_[0] =~ /ouch that was unexpected/ } ), 'expected log message';

done_testing;
