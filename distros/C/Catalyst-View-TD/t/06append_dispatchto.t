use strict;
use warnings;
use Test::More tests => 15;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');
my $response;

my $initial_dispatchto = [ @{ TestApp->view('Appconfig')->dispatch_to } ];

ok(($response = request("/test_append_dispatchto?view=Appconfig&template=testclass&additionalclass=TestApp::Templates::Additional"))->is_success, 'additional_template_class request');
is($response->content, "From Additional: " . TestApp->config->{default_message}, 'additional_template_class message');

is_deeply($initial_dispatchto,
    TestApp->view('Appconfig')->dispatch_to,
    'dispatchto is unchanged');

ok(($response = request("/test_append_dispatchto?view=Appconfig&template=test&additionalclass=TestApp::Templates::Additional"))->is_success, 'additional_template_class request');
is($response->content, TestApp->config->{default_message}, 'appconfig_template_class message');

is_deeply($initial_dispatchto,
    TestApp->view('Appconfig')->dispatch_to,
    'dispatchto is unchanged');

ok(($response = request("/test_append_dispatchto?view=Additional&template=testclass"))->is_success, 'dispatchto set to the alternate class');
is($response->content, "From Additional: " . TestApp->config->{default_message}, 'request to view using the alternate template class');

ok(($response = request("/test_append_dispatchto?view=Appconfig&template=testclass&addclass=TestApp::Templates::Additional"))->is_success, 'add class to the array');
is($response->content, "From Additional: " . TestApp->config->{default_message}, 'added class template renders');

is_deeply([@$initial_dispatchto, 'TestApp::Templates::Additional'],
    TestApp->view('Appconfig')->dispatch_to,
    'dispatchto has been changed');

ok(($response = request("/test_append_dispatchto?view=Appconfig&template=testclass&setclass=TestApp::Templates::Additional"))->is_success, 'set dispatchto from request');
is($response->content, "From Additional: " . TestApp->config->{default_message}, 'set class template renders');

is_deeply(['TestApp::Templates::Additional'],
    TestApp->view('Appconfig')->dispatch_to,
    'dispatchto has been overridden');

