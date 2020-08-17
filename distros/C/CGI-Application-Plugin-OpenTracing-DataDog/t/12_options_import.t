use Test::Most ;

use lib 't/lib/';
use Test::CGI::Application::Plugin::OpenTracing::Utils;

cgi_implementation_params_ok(
    'MyTest::CGI::Application::Import' => [
        "OpenTracing::Implementation",
        "DataDog",
        "default_service_name",
        "MyTest::CGI::Application::Import",
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
    ],
);

done_testing();



package MyTest::CGI::Application::Import;
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



1;
