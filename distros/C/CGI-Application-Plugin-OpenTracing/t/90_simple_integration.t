use Test::Most ;
use Test::MockObject;
use Test::OpenTracing::Integration;

my $mocked_query = mock_query(
    request_method      => 'PATCH',
    url                 => 'https://test.tst/test.cgi?foo=bar',
);

my $cgi_app = MyTest::CGI::Application->new(
    query => $mocked_query
);


$cgi_app->run;

global_tracer_cmp_easy(
    [
        {
            operation_name      => "cgi_request",
            level               => 0,
            baggage_items       => { bar => 2, foo => 1 },
            context_item        => "this is bootstrapped span_context",
            tags                => {
                'component'         => "CGI::Application",
                'http.method'       => "PATCH",
                'http.status_code'  => "200",
                'http.url'          => "https://test.tst/test.cgi?foo=bar",
                'run_method'        => "some_method_start",
                'run_mode'          => "start",
            },
        },
        {
            operation_name       => "cgi_setup",
            level                => 1,
            baggage_items        => { bar => 2, foo => 1 },
            context_item        => "this is bootstrapped span_context",
        },
        {
            operation_name       => "cgi_run",
            level                => 1,
            baggage_items        => { bar => 2, foo => 1 },
            context_item        => "this is bootstrapped span_context",
        },
        {
            operation_name       => "we_have_work_to_do",
            level                => 2,
            baggage_items        => { bar => 2, foo => 1 },
            context_item        => "this is bootstrapped span_context",
            tags                 => { message => 'Hello World' },
        },
        {
            operation_name       => "cgi_teardown",
            level                => 1,
            baggage_items        => { bar => 2, foo => 1 },
            context_item        => "this is bootstrapped span_context",
        },
    ], "Seems we created all spans as expected"
);

done_testing();





sub mock_query {
    my %mock_methods = @_;
    
    my $mock_obj = Test::MockObject->new();
    $mock_obj->set_always( $_ => $mock_methods{$_} )
        foreach keys %mock_methods;
    
    $mock_obj->mock( param  => sub { } );
    $mock_obj->mock( header => sub { } );
    
    return $mock_obj
}



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

sub run_modes {
    start    => 'some_method_start',
    run_this => 'this_method_name',
    run_that => 'that_method_name',
}

sub some_method_start {
    my $scope = $TRACER->start_active_span('we_have_work_to_do');
    
    $scope->get_span->add_tag( message => "Hello World" );
    
    $scope->close;
    
    return
}

sub load_tmpl { 
}

sub teardown {
}

1;
