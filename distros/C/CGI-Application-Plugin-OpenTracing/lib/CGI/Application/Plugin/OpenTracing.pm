package CGI::Application::Plugin::OpenTracing;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Exporter';

use OpenTracing::Implementation;
use OpenTracing::GlobalTracer qw/$TRACER/;

use Time::HiRes qw( gettimeofday );



sub import {
    my $package = shift;
    my @params  = @_;
    
    my $caller  = caller;
    
    $caller->add_callback(
        init => sub {
            my $cgi_app = shift;
            
            _span_set_time_start( $cgi_app, 'request' );
            _span_set_time_start( $cgi_app, 'setup' );
        }
    );
        
    $caller->add_callback(
        prerun => sub {
            my $cgi_app = shift;
            
            _span_set_time_finish( $cgi_app, 'setup' );
            
            _init_opentracing_implementation( $cgi_app );
            _start_active_root_span( $cgi_app );
            _handle_postmortum_setup_span( $cgi_app );
            
            _span_set_time_start( $cgi_app, 'run' );
            _start_active_run_span( $cgi_app ); # and `set_scope`
        }
    );
    
    $caller->add_callback(
        postrun => sub {
            my $cgi_app = shift;
            
            _span_set_time_finish( $cgi_app, 'run' );
            _span_scope_close( $cgi_app, 'run' );
        }
    );
    
    $caller->add_callback(
        teardown => sub {
            my $cgi_app = shift;
            
            _span_set_time_finish( $cgi_app, 'request' );
            _span_scope_close( $cgi_app, 'request' );
        }
    );
    
}



sub _init_opentracing_implementation {
    my $cgi_app = shift;
    
    my @implementation_settings = $cgi_app->can('opentracing_implementation') ?
        $cgi_app->opentracing_implementation( )
        :
        undef # $ENV{OPENTRACING_IMPLEMENTATION}
    ;
    
    OpenTracing::Implementation->set( @implementation_settings )
    
}



sub _start_active_root_span {
    my $cgi_app = shift;
    
    my $context = $TRACER->extract_context;
    
    my $root_span_options = _get_root_span_options( $cgi_app );
    
    my $scope = $TRACER->start_active_span( 'cgi_application' =>
        %{$root_span_options},
        child_of => $context,
    );
    
    _span_set_scope( $cgi_app, 'request', $scope );
    
    return $scope
}



sub _get_root_span_options {
    my $cgi_app = shift;
    
    return {
        child_of                => undef, # will be overridden
        tags                    => {
            'component'             => 'CGI::Application',
            'http.method'           => _cgi_get_http_method( $cgi_app ),
            'http.status_code'      => '200',
            'http.url'              => _cgi_get_http_url( $cgi_app ),
        },
        start_time              => _span_get_time_start( $cgi_app, 'request' ),
        ignore_active_span      => 1,
    }
}



sub _handle_postmortum_setup_span {
    my $cgi_app = shift;
    
    my $method = _cgi_get_run_method( $cgi_app );
    my $operation_name = 'setup';
    
    $TRACER
    ->start_span( $operation_name =>
        start_time => _span_get_time_start( $cgi_app, 'setup' ),
    )
    ->finish( _span_get_time_finish( $cgi_app, 'setup' )
    )
}



sub _start_active_run_span {
    my $cgi_app = shift;
    
    my $method = _cgi_get_run_method( $cgi_app );
    my $operation_name = 'run';
    
    my $scope = $TRACER->start_active_span( $operation_name );
    
    _span_set_scope( $cgi_app, 'run', $scope );
    
    return $scope
}



sub _cgi_get_run_method {
    my $cgi_app = shift;
    
    my $run_mode = $cgi_app->get_current_runmode();
    my $run_methode = { $cgi_app->run_modes }->{ $run_mode };
    
    return $run_methode
}



sub _span_set_time_start {
    _span_set_time( $_[0], $_[1], 'start' );
}



sub _span_set_time_finish {
    _span_set_time( $_[0], $_[1], 'finish' );
}



sub _span_set_time {
    $_[0]->{__PLUGINS}{OpenTracing}{__SPANS}{$_[1]}{ $_[2] . '_time' }
    = scalar @_ == 4 ? $_[3] : _epoch_floatingpoint();
;
}



sub _span_get_time_start {
    _span_get_time( $_[0], $_[1], 'start' );
}



sub _span_get_time_finish {
    _span_get_time( $_[0], $_[1], 'finish' );
}



sub _span_get_time {
    $_[0]->{__PLUGINS}{OpenTracing}{__SPANS}{$_[1]}{$_[2].'_time'};
}



sub _span_scope_close {
    _span_get_scope( $_[0], $_[1] )->close;
}



sub _span_set_scope {
    $_[0]->{__PLUGINS}{OpenTracing}{__SPANS}{$_[1]}{scope} = $_[2];
}



sub _span_get_scope {
    $_[0]->{__PLUGINS}{OpenTracing}{__SPANS}{$_[1]}{scope};
}



sub _cgi_get_http_method {
    my $cgi_app = shift;
    
    my $query = $cgi_app->query();
    
    return $query->request_method();
}



sub _cgi_get_http_url {
    my $cgi_app = shift;
    
    my $query = $cgi_app->query();
    
    return $query->url();
}



sub _epoch_floatingpoint {
    return scalar gettimeofday()
}


1;
