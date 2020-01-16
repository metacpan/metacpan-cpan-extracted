package MyCGI;

use base 'CGI::Application';
use CGI::Application::Plugin::OpenTracing;

use OpenTracing::GlobalTracer qw/$TRACER/;

sub sleep_rand { sleep ((rand shift) + shift // 0) }

sub setup {
    my $webapp = shift;
    $webapp->start_mode( 0 );
    $webapp->mode_param( 'rm' );
    $webapp->run_modes(
        0   => 'do_start',
        1   => 'do_something',
        9   => 'do_end',
    );
    sleep_rand 1;
}



sub opentracing_implementation {
    my $webapp = shift;
    my $run_mode = $webapp->get_current_runmode();
    my $run_method = { $webapp->run_modes }->{ $run_mode };
    
    
    return ( 'DataDog' =>
        default_context => {
            service_name    => __PACKAGE__,
            service_type    => 'web',
            resource_name   => 'test.cgi',
            baggage_items   => {
                run_mode        => $run_mode,
                run_method      => $run_method,
            }
        },
    );
    
}

sub do_start {
    
    sleep_rand 2;
    
    return "This is \"Do Start\"";
}

sub do_something {
    
    sleep_rand 2, 2;
    
    do_something_more( );
    
    sleep_rand 2, 2;
    
    return "Where am I";
}

sub do_end {
    
    sleep_rand 3;
    
    return "Beye...!"
}



sub tear_down {
    
    sleep_rand 2;

}

sub do_something_more {
    my $scope = $TRACER->start_active_span('do_something_more');
    
    sleep_rand 3, 2;
    
    $scope->close();
}


1;