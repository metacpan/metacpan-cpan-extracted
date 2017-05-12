use strict;
use warnings;
use Test::More tests => 10;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');
my $response;

my $inital_include_path = [ @{ TestApp->view('TT::Appconfig')->include_path } ];

ok(($response = request("/test_includepath?view=Appconfig&template=testpath.tt&additionalpath=test_include_path"))->is_success, 'additional_template_path request');
is($response->content, TestApp->config->{default_message}, 'additional_template_path message');

is_deeply($inital_include_path,
    TestApp->view('TT::Appconfig')->include_path,
    'Include path is unchanged');

ok(($response = request("/test_includepath?view=Includepath&template=testpath.tt"))->is_success, 'scalar include path from config request');
is($response->content, TestApp->config->{default_message}, 'scalar include path with delimiter from config message');

ok(($response = request("/test_includepath?view=Includepath2&template=testpath.tt"))->is_success, 'object ref (that stringifys to the path) include path from config request');
is($response->content, TestApp->config->{default_message}, 'object ref (that stringifys to the path) include path from config message');

ok(($response = request("/test_includepath?view=Includepath3&template=testpath.tt&addpath=test_include_path"))->is_success, 'array ref include path from config not replaced by another array request');
is($response->content, TestApp->config->{default_message}, 'array ref include path from config not replaced by another array message');

