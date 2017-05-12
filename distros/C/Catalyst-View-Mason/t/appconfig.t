#!perl

use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response = request('/test?view=Appconfig');

ok($response->is_success, 'request ok');
is($response->content, TestApp->config->{default_message}, 'message ok');

$response = request('/test?view=Appconfig&message=<<foo>>');

ok($response->is_success, 'request with message ok');
is($response->content, '&lt;&lt;foo&gt;&gt;', 'message ok');
