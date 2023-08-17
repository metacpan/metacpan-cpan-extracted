use Test::Most ;
use Test::MockObject;
use Test::OpenTracing::Integration;
use Test::WWW::Mechanize::CGIApp;

my $mech = Test::WWW::Mechanize::CGIApp->new;
$mech->app('MyTest::CGI::Application');

$mech->post('https://test.tst/test.cgi', content => { search => 'target', page_size => 10 });
global_tracer_cmp_easy([
    {
        operation_name => "cgi_application_request",
        tags           => {
            'component'             => "CGI::Application",
            'http.method'           => "POST",
            'http.status_code'      => "200",
            'http.status_message'   => "OK",
            'http.url'              => "https://test.tst/test.cgi",
            'run_method'            => "process_form",
            'run_mode'              => "start",
            'http.form.search'      => 'target',
            'http.form.page_size'   => '10',
        },
    },
], "cgi_request span has form data in tags");

$mech->post('https://test.tst/test.cgi?a=1&b=2', content => { b => 'B', c => 'C'  });
global_tracer_cmp_easy([
    {
        operation_name => "cgi_application_request",
        tags => {
            'component'             => "CGI::Application",
            'http.method'           => "POST",
            'http.status_code'      => "200",
            'http.status_message'   => "OK",
            'http.url'              => "https://test.tst/test.cgi",
            'run_method'            => "process_form",
            'run_mode'              => "start",
            'http.query.a'          => '1',
            'http.query.b'          => '2',
            'http.form.b'           => 'B',
            'http.form.c'           => 'C',
        },
    },
], "clashing form data and query param name");

$mech->patch('https://test.tst/test.cgi?x=1', content => {});
global_tracer_cmp_easy([
    {
        operation_name => "cgi_application_request",
        tags           => {
            'component'             => "CGI::Application",
            'http.method'           => "PATCH",
            'http.status_code'      => "200",
            'http.status_message'   => "OK",
            'http.url'              => "https://test.tst/test.cgi",
            'run_method'            => "process_form",
            'run_mode'              => "start",
            'http.query.x'          => '1',
        },
    },
], "empty form");
done_testing();



package MyTest::CGI::Application;

use base 'CGI::Application';

use CGI::Application::Plugin::OpenTracing qw/Test/;
use OpenTracing::GlobalTracer qw/$TRACER/;

sub run_modes {
    start => 'process_form',
}

sub process_form { return }

1;
