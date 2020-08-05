use Test::Most ;
use Test::MockObject;
use Test::OpenTracing::Integration;
use Test::WWW::Mechanize::CGIApp;

use utf8;

my $mech = Test::WWW::Mechanize::CGIApp->new;
$mech->app('MyTest::CGI::Application');

$mech->get('https://test.tst/test.cgi?foo=bar;abc=1;abc=2;skipp_me=1;password=secret');

global_tracer_cmp_easy(
    [
        {
            operation_name      => "cgi_application_request",
            level               => 0,
            baggage_items       => { bar => 2, foo => 1 },
            context_item        => "this is bootstrapped span_context",
            tags                => {
                'component'           => "CGI::Application",
                'http.method'         => "GET",
                'http.status_code'    => "418",
                'http.status_message' => "I'm a teapot",
                'http.url'            => "https://test.tst/test.cgi",
                'run_method'          => "some_method_start",
                'run_mode'            => "start",
                'http.query.foo'      => "bar",
                'http.query.abc'      => "1;2",
                'http.query.password' => "* * * * *",
            },
        },
        {
            operation_name      => "cgi_application_setup",
            level               => 1,
            baggage_items       => { bar => 2, foo => 1 },
            context_item        => "this is bootstrapped span_context",
        },
        {
            operation_name      => "cgi_application_run",
            level               => 1,
            baggage_items       => { bar => 2, foo => 1 },
            context_item        => "this is bootstrapped span_context",
        },
        {
            operation_name      => "we_have_work_to_do",
            level               => 2,
            baggage_items       => { bar => 2, foo => 1 },
            context_item        => "this is bootstrapped span_context",
            tags                => { message => 'Hello World' },
        },
        {
            operation_name      => "cgi_application_teardown",
            level               => 1,
            baggage_items       => { bar => 2, foo => 1 },
            context_item        => "this is bootstrapped span_context",
        },
    ], "Seems we created all spans as expected"
);

done_testing();



package MyTest::CGI::Application;

use base 'CGI::Application';

use CGI::Application::Plugin::OpenTracing qw/Test/;
use OpenTracing::GlobalTracer qw/$TRACER/;

# set span context that is needed by the implementation
sub opentracing_bootstrap_options {
    default_context_item => "this is bootstrapped span_context"
}

# set some span_context items that will be carried over across the app
sub opentracing_baggage_items {
    foo => 1,
    bar => 2
}

sub opentracing_process_tags_query_params {
    password => '* * * * *',
    pwd      => '* * * * *',
    skipp_me => undef,
    sub { join ';', @_ },
}

sub run_modes {
    start    => 'some_method_start',
    run_this => 'this_method_name',
    run_that => 'that_method_name',
}

sub some_method_start {
    my $self = shift;
    
    my $scope = $TRACER->start_active_span('we_have_work_to_do');
    
    $scope->get_span->add_tag( message => "Hello World" );
    
    $self->header_add( -status => '418' );
    
    $scope->close;
    
    return
}

sub load_tmpl { 
}

sub teardown {
}

1;
