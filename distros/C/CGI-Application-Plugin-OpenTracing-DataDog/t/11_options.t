use Test::Most ;

use lib 't/lib/';
use Test::CGI::Application::Plugin::OpenTracing::Utils;

cgi_implementation_params_ok(
    'MyTest::CGI::Application::Default' => [
        "OpenTracing::Implementation",
        "DataDog",
        "default_service_name",
        "MyTest::CGI::Application::Default",
        "default_service_type",
        "web",
        "default_resource_name",
        "",
    ],
);

done_testing();



package MyTest::CGI::Application::Default;
use base 'CGI::Application';
use CGI::Application::Plugin::OpenTracing::DataDog;

sub run_modes {
    start    => 'some_method_start',
}

sub some_method_start { return }



1;
