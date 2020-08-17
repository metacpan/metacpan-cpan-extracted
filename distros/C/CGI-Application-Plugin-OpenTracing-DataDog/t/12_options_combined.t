use Test::Most ;

use lib 't/lib/';
use Test::CGI::Application::Plugin::OpenTracing::Utils;

cgi_implementation_params_ok(
    'MyTest::CGI::Application::Combined' => [
        "OpenTracing::Implementation",
        "DataDog",
        "default_service_name",
        "MyTest::CGI::Application::Combined",
        "default_service_type",
        "web",
        "default_resource_name",
        "",
        "default_service_name",
        "MyTest::Import",
        "default_service_type",
        "this_import",
        "default_resource_name",
        "this_fixed_endpoint.cgi",
        "foo",
        "1",
        "default_service_name",
        "MyTest::Bootstrap",
        "default_service_type",
        "that_bootstrap",
        "default_resource_name",
        "that_fixed_endpoint.cgi",
        "bar",
        "2",
    ],
);



done_testing();



package MyTest::CGI::Application::Combined;
use base 'CGI::Application';
use CGI::Application::Plugin::OpenTracing::DataDog
    default_service_name    => 'MyTest::Import',
    default_service_type    => 'this_import',
    default_resource_name   => 'this_fixed_endpoint.cgi',
    foo                     => 1,
;

sub run_modes {
    start    => 'some_method_start',
}

sub some_method_start { return }

sub opentracing_bootstrap_options {
    default_service_name    => 'MyTest::Bootstrap',
    default_service_type    => 'that_bootstrap',
    default_resource_name   => 'that_fixed_endpoint.cgi',
    bar                     => 2,
}



1;
