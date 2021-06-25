package Dancer2::Plugin::PrometheusTiny;
use strict;
use warnings;

our $VERSION = '0.005';
$VERSION = eval $VERSION;

use Dancer2::Plugin;
use Hash::Merge::Simple ();
use Prometheus::Tiny::Shared;
use Time::HiRes ();
use Types::Standard qw(
  ArrayRef
  Bool
  Dict
  Enum
  InstanceOf
  Maybe
  Map
  Num
  Optional
  Str
);

sub default_metrics {
    return {
        http_request_duration_seconds => {
            help => 'Request durations in seconds',
            type => 'histogram',
        },
        http_request_size_bytes => {
            help    => 'Request sizes in bytes',
            type    => 'histogram',
            buckets => [ 1, 50, 100, 1_000, 50_000, 500_000, 1_000_000 ],
        },
        http_requests_total => {
            help => 'Total number of http requests processed',
            type => 'counter',
        },
        http_response_size_bytes => {
            help    => 'Response sizes in bytes',
            type    => 'histogram',
            buckets => [ 1, 50, 100, 1_000, 50_000, 500_000, 1_000_000 ],
        }
    };
}

# CONFIG

has endpoint => (
    is          => 'ro',
    isa         => Str,
    from_config => sub {'/metrics'},
);

has filename => (
    is          => 'ro',
    isa         => Maybe [Str],
    from_config => sub {undef},
);

has include_default_metrics => (
    is          => 'ro',
    isa         => Bool,
    from_config => sub {1},
);

has metrics => (
    is  => 'ro',
    isa => Map [
        Str,
        Dict [
            help    => Str,
            type    => Enum [qw/ counter gauge histogram /],
            buckets => Optional [ ArrayRef [Num] ],
        ]
    ],
    from_config => sub { {} },
);

has prometheus_tiny_class => (
    is          => 'ro',
    isa         => Enum [ 'Prometheus::Tiny', 'Prometheus::Tiny::Shared' ],
    from_config => sub {'Prometheus::Tiny::Shared'},
);

# HOOKS

plugin_hooks 'before_format';

# KEYWORDS

has prometheus => (
    is      => 'ro',
    isa     => InstanceOf ['Prometheus::Tiny'],
    lazy    => 1,
    clearer => '_clear_prometheus',
    builder => sub {
        my $self = shift;

        my $class = $self->prometheus_tiny_class;
        my $prom  = $class->new(
            ( filename => $self->filename ) x defined $self->filename );

        my $metrics = $self->include_default_metrics
          ? Hash::Merge::Simple->merge(
            $self->default_metrics,
            $self->metrics
          )
          : $self->metrics;

        for my $name ( sort keys %$metrics ) {
            $prom->declare(
                $name,
                %{ $metrics->{$name} },
            );
        }

        return $prom;
    },
);

plugin_keywords 'prometheus';

# add hooks and metrics route

sub BUILD {
    my $plugin     = shift;
    my $app        = $plugin->app;
    my $prometheus = $plugin->prometheus;

    $app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                my $app = shift;
                $app->request->var( prometheus_plugin_request_start =>
                      [Time::HiRes::gettimeofday] );
            }
        )
    );

    if ( $plugin->include_default_metrics ) {
        $app->add_hook(
            Dancer2::Core::Hook->new(
                name => 'after',
                code => sub {
                    my $response = shift;
                    $plugin->_add_default_metrics($response);
                },
            )
        );
        $app->add_hook(

            # thrown errors bypass after hook
            Dancer2::Core::Hook->new(
                name => 'after_error',
                code => sub {
                    my $response = shift;
                    $plugin->_add_default_metrics($response);
                },
            )
        );
    }

    $app->add_route(
        method => 'get',
        regexp => $plugin->endpoint,
        code   => sub {
            my $app = shift;
            $plugin->execute_plugin_hook(
                'before_format', $app,
                $prometheus
            );
            my $response = $app->response;
            $response->content_type('text/plain');
            $response->content( $plugin->prometheus->format );
            $response->halt;
        }
    );
}

sub _add_default_metrics {
    my ( $plugin, $response ) = @_;
    if ( $response->isa('Dancer2::Core::Response::Delayed') ) {
        $response = $response->response;
    }
    my $request = $plugin->app->request;

    my $elapsed
      = Time::HiRes::tv_interval(
        $request->vars->{prometheus_plugin_request_start} );

    my $labels = {
        code   => $response->status,
        method => $request->method,
    };

    my $prometheus = $plugin->prometheus;

    $prometheus->histogram_observe(
        'http_request_size_bytes',
        length( $request->content || '' ),
        $labels
    );
    $prometheus->histogram_observe(
        'http_response_size_bytes',
        length( $response->content || '' ),
        $labels
    );
    $prometheus->inc(
        'http_requests_total',
        $labels
    );
    $prometheus->histogram_observe(
        'http_request_duration_seconds',
        $elapsed, $labels
    );
}

1;

=head1 NAME

Dancer2::Plugin::PrometheusTiny - use Prometheus::Tiny with Dancer2

=head1 SYNOPSIS

=head1 DESCRIPTION

This plugin integrates L<Prometheus::Tiny::Shared> with your L<Dancer2> app,
providing some default metrics for requests and responses, with the ability
to easily add further metrics to your app. A route is added which makes
the metrics available via the configured L</endpoint>.

See L<Prometheus::Tiny> for more details of the kind of metrics supported.

The following metrics are included by default:

    http_request_duration_seconds => {
        help => 'Request durations in seconds',
        type => 'histogram',
    },
    http_request_size_bytes => {
        help    => 'Request sizes in bytes',
        type    => 'histogram',
        buckets => [ 1, 50, 100, 1_000, 50_000, 500_000, 1_000_000 ],
    },
    http_requests_total => {
        help => 'Total number of http requests processed',
        type => 'counter',
    },
    http_response_size_bytes => {
        help    => 'Response sizes in bytes',
        type    => 'histogram',
        buckets => [ 1, 50, 100, 1_000, 50_000, 500_000, 1_000_000 ],
    }

=head1 KEYWORDS

=head2 prometheus

    get '/some/route' => sub {
        prometheus->inc(...);
    }

Returns the C<Prometheus::Tiny::Shared> instance.

=head1 CONFIGURATION

Example:

    plugins:
      PrometheusTiny:
        endpoint: /prometheus-metrics   # default: /metrics
        filename: /run/d2prometheus     # default: (undef)
        include_default_metrics: 0      # default: 1
        metrics:                        # default: {}
          http_request_count:
            help: HTTP Request count
            type: counter
        
See below for full details of each configuration setting.

=head2 endpoint

The endpoint from which metrics are served. Defaults to C</metrics>.

=head2 filename

It is recommended that this is set to a directory on a memory-backed
filesystem. See L<Prometheus::Tiny::Shared/filename> for details and default
value.

=head2 include_default_metrics

Defaults to true. If set to false, then the default metrics shown in
L</DESCRIPTION> will not be added.

=head2 metrics

Declares extra metrics to be merged with those included with the plugin. See
See L<Prometheus::Tiny/declare> for details.

=head2 prometheus_tiny_class

Defaults to L<Prometheus::Tiny::Shared>.

B<WARNING:> You shoulf only set this if you are running a single process plack
server such as L<Twiggy>, and you don't want to use file-based store for
metrics. Setting this to L<Prometheus::Tiny> will mean that metrics are instead
stored in memory.

=head1 AUTHOR

Peter Mottram (SysPete) <peter@sysnix.com>

=head1 CONTRIBUTORS

None yet.

=head1 COPYRIGHT

Copyright (c) 2021 the Catalyst::Plugin::PrometheusTiny L</AUTHOR>
and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as Perl itself.
