package CGI::Application::Plugin::OpenTracing;

use strict;
use warnings;

our $VERSION = 'v0.104.1';

use syntax 'maybe';

use OpenTracing::Implementation;
use OpenTracing::GlobalTracer;

use Carp qw( croak carp );
use HTTP::Headers;
use HTTP::Status qw( is_server_error :constants);
use Scalar::Util qw( refaddr );
use Time::HiRes qw( gettimeofday );

use constant CGI_LOAD_TMPL    => 'CGI_APPLICATION_LOAD_TMPL';
use constant CGI_REQUEST      => 'CGI_APPLICATION_REQUEST';
use constant CGI_RUN          => 'CGI_APPLICATION_RUN';
use constant CGI_SETUP        => 'CGI_APPLICATION_SETUP';
use constant CGI_TEARDOWN     => 'CGI_APPLICATION_TEARDOWN';
use constant TRC_ACTIVE_SCOPE => 'TRC_SCOPEMANAGER_ACTIVE_SCOPE';

our $implementation_import_name;
our @implementation_import_opts;

our $TAG_JOIN_CHAR = ',';



################################################################################
#
# NOTE: please take a minute to understand the structure of this module
#
# CGI::Application::Plugin has an interesting design on itself
#
# within this code base there are three sections:
# - import
# - callbacks, as defined by CGI::Application
# - plugin related methods, that deal with the plugin internals
# - tracing specific routines
# - cgi related routines, that just work on the CGI::Application only
#
################################################################################



sub import {
    my $package = shift;
    
    ( $implementation_import_name, @implementation_import_opts ) = @_;
    $ENV{OPENTRACING_DEBUG} && carp "OpenTracing Implementation not defined during import\n"
        unless defined $implementation_import_name;
    
    my $caller  = caller;
    $caller->add_callback( init      => \&init      );
    $caller->add_callback( prerun    => \&prerun    );
    $caller->add_callback( postrun   => \&postrun   );
    $caller->add_callback( load_tmpl => \&load_tmpl );
    $caller->add_callback( teardown  => \&teardown  );
    $caller->add_callback( error     => \&error     );
    

    my $run_glob = do { no strict 'refs'; \*{ $caller . '::run' } };
    my $run_orig
        = defined &$run_glob
        ? \&run_glob
        : eval "package $caller;"  # SUPER works based on the package it's defined in
             . 'sub { my $self = shift; $self->SUPER::run(@_) }';
    no warnings 'redefine';
    *$run_glob = _wrap_run($run_orig);

    return;
}



sub new {
    my $class = shift;
    my %args  = @_;
    
    my $tracer = delete $args{tracer} // OpenTracing::GlobalTracer->get_global_tracer();
    
    bless {
        SCOPE  => {
            # one for each callback
        },
        TRACER => $tracer,
    }
}



################################################################################
#
#   Callbacks
#
################################################################################



sub init {
    my $cgi_app = shift;
    
    my @bootstrap_options = _app_get_bootstrap_options($cgi_app);
    my $bootstrapped_tracer = _opentracing_init_tracer(@bootstrap_options);
    #       unless OpenTracing::GlobalTracer->is_registered;
    OpenTracing::GlobalTracer->set_global_tracer( $bootstrapped_tracer );
    
    my $plugin = __PACKAGE__->new( );
    $cgi_app->{__PLUGINS}{OPENTRACING} = $plugin;
    
    my $tracer       = $plugin->get_tracer();
    my $headers      = _cgi_get_http_headers($cgi_app);
    my $context      = $tracer->extract_context($headers);
    my %request_tags = _get_request_tags($cgi_app);
    my %query_params = _get_query_params_tags($cgi_app);
    my %form_data    = _get_form_data_tags($cgi_app);
    
    $plugin->start_active_span( CGI_REQUEST, child_of => $context  );
    $plugin->add_tags(          CGI_REQUEST, %request_tags         );
    $plugin->add_tags(          CGI_REQUEST, %query_params         );
    $plugin->add_tags(          CGI_REQUEST, %form_data            );
    $plugin->start_active_span( CGI_SETUP                          );
    
    return
}



sub prerun {
    my $cgi_app = shift;
    
    my $plugin  = _get_plugin($cgi_app);
    
    my %runmode_tags  = _get_runmode_tags($cgi_app);
    my %baggage_items = _app_get_baggage_items($cgi_app);
    
    $plugin->add_baggage_items( CGI_SETUP,   %baggage_items        );
    $plugin->close_scope(       CGI_SETUP                          );
    $plugin->add_baggage_items( CGI_REQUEST, %baggage_items        );
    $plugin->add_tags(          CGI_REQUEST, %runmode_tags         );
    $plugin->start_active_span( CGI_RUN                            );
    
    return
}



sub postrun {
    my $cgi_app = shift;
    
    my $plugin = _get_plugin($cgi_app);
    
    $plugin->close_scope(       CGI_RUN                            );
    $plugin->start_active_span( CGI_TEARDOWN                       );
    
    return
}



sub load_tmpl {
    my $cgi_app = shift;
    
    my $plugin = _get_plugin($cgi_app);
    
    $plugin->close_scope(       CGI_LOAD_TMPL                      );
    
    return
}



sub teardown {
    my $cgi_app = shift;
    
    my $plugin  = _get_plugin($cgi_app);
    
    my %http_status_tags = _get_http_status_tags($cgi_app);
    my $error = 1
        if is_server_error([_cgi_get_header_status($cgi_app)]->[0]);
    
    $plugin->close_scope(       CGI_TEARDOWN                       );
    $plugin->add_tags(          CGI_REQUEST, %http_status_tags     );
    $plugin->add_tags(          CGI_REQUEST, maybe error => $error );
    $plugin->close_scope(       CGI_REQUEST                        );
    
    return
}



sub error {
    my ($cgi_app, $error) = @_;
    
    my $plugin  = _get_plugin($cgi_app);
    
    return if not $cgi_app->error_mode();    # we're dying
    
    $plugin->add_tags(TRC_ACTIVE_SCOPE,
        error   => 1,
        message => $error,
        grep_error_tags( $plugin->get_tags(TRC_ACTIVE_SCOPE) ),
    );
    
    # run span should continue
    my $root = $plugin->get_scope(CGI_RUN)->get_span;
    
    my $tracer = $plugin->get_tracer();
    _cascade_set_failed_spans($tracer, $error, $root);
    
    return;
}



################################################################################
#
#   Plugin methods - These do not require the CGI-App
#
################################################################################



sub set_tracer {
    my $plugin = shift;
    my $tracer = shift;
    
    $plugin->{TRACER} = $tracer;
}

sub get_tracer {
    my $plugin = shift;
    
    return $plugin->{TRACER}
}

sub start_active_span {
    my $plugin         = shift;
    my $scope_name     = shift;
    my %params         = @_;
    
    my $operation_name = lc $scope_name;
    
    my $tracer = $plugin->get_tracer();
    my $scope = $tracer->start_active_span( $operation_name, %params );
    
   $plugin->{SCOPE}{$scope_name} = $scope;
}

sub add_tags {
    my $plugin         = shift;
    my $scope_name     = shift;
    my %tags           = @_;
    
   $plugin->get_span($scope_name)->add_tags(%tags);
}

sub get_tags {
    my $plugin         = shift;
    my $scope_name     = shift;
    
   $plugin->get_span($scope_name)->get_tags();
}

sub add_baggage_items {
    my $plugin         = shift;
    my $scope_name     = shift;
    my %baggage_items  = @_;
    
   $plugin->get_span($scope_name)->add_baggage_items( %baggage_items );
}

sub close_scope {
    my $plugin         = shift;
    my $scope_name     = shift;
    
   $plugin->get_scope($scope_name)->close;
}

sub get_span {
    my $plugin         = shift;
    my $scope_name     = shift;
    
   $plugin->get_scope($scope_name)->get_span;
}

sub get_scope {
    my $plugin         = shift;
    my $scope_name     = shift;
    
    return $plugin->get_tracer()->get_scope_manager->get_active_scope()
        if $scope_name eq TRC_ACTIVE_SCOPE;
    
    return $plugin->{SCOPE}{$scope_name};
}



################################################################################
#
#   OpenTracing
#
################################################################################



sub _opentracing_init_tracer {
    my @bootstrap_options = @_;
    
    my $bootstrapped_tracer =
        $implementation_import_name ?
            OpenTracing::Implementation->bootstrap_tracer(
                $implementation_import_name,
                @implementation_import_opts,
                @bootstrap_options,
            )
            :
            OpenTracing::Implementation->bootstrap_default_tracer(
                @implementation_import_opts,
                @bootstrap_options,
            )
    ;
        
    return $bootstrapped_tracer;
}



sub _cascade_set_failed_spans {
    my ($tracer, $error, $root_span) = @_;
    my $root_addr = refaddr($root_span) if defined $root_span;

    while (my $scope = $tracer->get_scope_manager->get_active_scope()) {
        my $span = $scope->get_span();
        last if defined $root_addr and $root_addr eq refaddr($span);
        
#       $span->add_tags(error => 1, message => $error);
        $scope->close();
    }
    return;
}



sub grep_error_tags {
    my %tags = @_;
    
    return (
        maybe 'error'      => $tags{'error'},
        maybe 'message'    => $tags{'message'},
        maybe 'error.kind' => $tags{'error.kind'},
    )
}


################################################################################
#
#   CGI – purely CGI related
#
################################################################################



sub _cgi_get_run_mode {
    my $cgi_app = shift;
    
    my $run_mode = $cgi_app->get_current_runmode();
    
    return $run_mode
}



sub _cgi_get_run_method {
    my $cgi_app = shift;
    
    my $run_mode = $cgi_app->get_current_runmode();
    my $run_methode = { $cgi_app->run_modes }->{ $run_mode };
    
    return $run_methode
}


sub _cgi_get_header_status {
    my $cgi_app = shift;

    my %headers = $cgi_app->header_props();
    my $status = $headers{-status};
    
    return $status
        unless wantarray;
    
    my $status_code = [ ( $status // '' ) =~ /^\s*(\d{3})/ ]->[0];
    my $status_mess = [ ( $status // '' ) =~ /^\s*\d{3}\s*(.+)\s*$/ ]->[0];
    
    return ($status_code, $status_mess);
}



################################################################################
#
#   CGI Query – operates indirectly on CGI->Query
#
################################################################################



sub _cgi_get_query_http_method {
    my $cgi_app = shift;
    
    my $query = $cgi_app->query();
    
    return $query->request_method();
}


sub _cgi_get_http_headers {
    my $cgi_app = shift;

    my $query = $cgi_app->query();

    HTTP::Headers->new(map { s/^HTTP_//r => $query->http($_) } $query->http);
}

sub _cgi_get_query_http_url {
    my $cgi_app = shift;
    
    my $query = $cgi_app->query();
    
    return $query->url(-path => 1);
}



sub _cgi_get_query_content_type_is_form {
    my $cgi_app = shift;
    
    my $query = $cgi_app->query();
    
    my $content_type = $query->content_type();
    
    return   if not defined $content_type;
    return 1 if $content_type =~ m{\Amultipart/form-data};
    return 1 if $content_type =~ m{\Aapplication/x-www-form-urlencoded};
    return;
}



################################################################################
#
#   Tags - getting the various tags for the request span
#
################################################################################



sub _get_request_tags {
    my $cgi_app = shift;
    
    my %tags = (
              'component'   => 'CGI::Application',
        maybe 'http.method' => _cgi_get_query_http_method($cgi_app),
        maybe 'http.url'    => _cgi_get_query_http_url($cgi_app),
    );
    

    return %tags
}



sub _get_query_params_tags {
    my $cgi_app = shift;
    
    my $processor = _gen_tag_processor($cgi_app,
        $cgi_app->can('opentracing_process_tags_query_params'),
        $cgi_app->can('opentracing_process_tags'),
    );
    
    my %processed_params;
    
    my $query = $cgi_app->query();
    foreach my $param ($query->url_param()) {
        next unless defined $param; # huh ???
        my @values          = $query->url_param($param);
        my $processed_value = $cgi_app->$processor($param, \@values);
        next unless defined $processed_value;
        
        $processed_params{"http.query.$param"} = $processed_value;
    }
    return %processed_params;
}



sub _get_form_data_tags {
    my $cgi_app = shift;
    return unless _cgi_get_query_content_type_is_form($cgi_app);
    
    my $processor = _gen_tag_processor($cgi_app,
        $cgi_app->can('opentracing_process_tags_form_fields'),
        $cgi_app->can('opentracing_process_tags'),
    );
    
    my %processed_params = ();
    
    my %params = $cgi_app->query->Vars();
    while (my ($param_name, $param_value) = each %params) {
        my $processed_value = $cgi_app->$processor(
            $param_name, [ split /\0/, $param_value ]
        );
        next unless defined $processed_value;
        $processed_params{"http.form.$param_name"} = $processed_value
    }
    
    return %processed_params;
}



sub _get_runmode_tags {
    my $cgi_app = shift;
    
    my %tags = (
        maybe 'run_mode'   => _cgi_get_run_mode($cgi_app),
        maybe 'run_method' => _cgi_get_run_method($cgi_app),
    );
    return %tags
}



sub _get_http_status_tags {
    my $cgi_app = shift;
    
    my ($status_code, $status_mess) = _cgi_get_header_status($cgi_app);
    $status_code //= HTTP_OK;
    $status_mess //= HTTP::Status::status_message($status_code);
    
    my %tags = (
        maybe 'http.status_code'    => $status_code,
        maybe 'http.status_message' => $status_mess,
    );
    return %tags
}



################################################################################
#
#   App - specific routines that interact with the calling CGI-App
#
################################################################################



sub _app_get_bootstrap_options {
    my $cgi_app = shift;
    
    return unless $cgi_app->can('opentracing_bootstrap_options');
    
    my @bootstrap_options = $cgi_app->opentracing_bootstrap_options( );
    
    return @bootstrap_options
}



sub _app_get_baggage_items {
    my $cgi_app = shift;
    
    return unless $cgi_app->can('opentracing_baggage_items');
    
    my %baggage_items = $cgi_app->opentracing_baggage_items( );
    
    
    return %baggage_items
}



################################################################################
#
#   CGI Application Plugin
#
################################################################################



sub _get_plugin {
    my $cgi_app = shift;
    
    return $cgi_app->{__PLUGINS}{OPENTRACING};
}



################################################################################
#
#   some internals
#
################################################################################



sub _gen_tag_processor {
    my $cgi_app = shift;
    
    my $joiner = sub { join $TAG_JOIN_CHAR, @_ };
    
    my (@specs, $fallback);
    foreach my $spec_gen (@_) {
        next if not defined $spec_gen;
        
        my ($spec, $spec_fallback) = _gen_spec($spec_gen->());
        $fallback ||= $spec_fallback;
        push @specs, $spec;
    }
    $fallback ||= $joiner;
    
    return sub {
        my ($cgi_app, $name, $values) = @_;
        
        my $processor = $fallback;
        foreach my $spec (@specs) {
            my ($matched, $spec_processor) = $spec->($name);
            $processor = $spec_processor if $matched;
        }
        
        return            if not defined $processor;
        return $processor if not ref $processor;

        if (ref $processor eq 'CODE') {
            my $processed = $processor->(@$values);
            $processed = $joiner->(@$processed) if ref $processed eq 'ARRAY';
            return $processed;
        }
        
        croak "Invalid processor for param `$name`: ", ref $processor;
    };
}



sub _gen_spec {
    my @def = @_;
    
    my $fallback;
    $fallback = pop @def if @def % 2 != 0;
    
    my (%direct_match, @regex);
    while (my ($cond, $processor) = splice @def, 0, 2) {
        if (ref $cond eq 'Regexp') {
            push @regex, [ $cond => $processor ];
        }
        else {
            foreach my $name (ref $cond eq 'ARRAY' ? @$cond : $cond) {
                $direct_match{$name} = $processor;
            }
        }
    }
    my $spec = sub {
        my ($name) = @_;
        
        # return match state separately to differentiate from undef processors
        return (1, $direct_match{$name}) if exists $direct_match{$name};
        
        foreach (@regex) {
            my ($re, $processor) = @$_;
            return (1, $processor) if $name =~ $re;
        }
        return;
    };
    
    return ($spec, $fallback);
}



sub _wrap_run {
    my ($orig) = @_;

    return sub {
        my $cgi_app = shift;

        my $res;
        my $wantarray = wantarray;    # eval has its own
        my $ok = eval {
            if ($wantarray) {
                $res = [ $cgi_app->$orig(@_) ];
            }
            else {
                $res = $cgi_app->$orig(@_);
            }
            1;
        };
        return $wantarray ? @$res : $res if $ok;

        my $error = $@;
        
        $cgi_app->header_add(-status => HTTP_INTERNAL_SERVER_ERROR);
        
        my $plugin = _get_plugin($cgi_app);
        
        $plugin->add_tags(CGI_REQUEST,
            _get_http_status_tags($cgi_app),
            grep_error_tags( $plugin->get_tags(TRC_ACTIVE_SCOPE) ),
            error   => 1,
            message => $error,
        );
        
        $plugin->add_tags(TRC_ACTIVE_SCOPE,
            error   => 1,
            message => $error,
            grep_error_tags( $plugin->get_tags(TRC_ACTIVE_SCOPE) ),
        );
        
        my $tracer = $plugin->get_tracer();
        _cascade_set_failed_spans($tracer, $error);

        die $error;
    };
}



1;
