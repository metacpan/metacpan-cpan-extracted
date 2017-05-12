#!perl

use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response = request('/test_set_template?view=AppConfig');

ok($response->is_success, 'request ok');
is($response->content, TestApp->config->{default_message}, 'message ok');

$response = request('/test_set_template?view=ExtensionAlways');

ok($response->is_success, 'request ok');
is($response->content, 'template extension', 'used template extension');
