package Catalyst::Plugin::PrometheusTiny;

use strict;
use warnings;
use v5.10.1;

our $VERSION = '0.006';

$VERSION = eval $VERSION;

use Carp            ();
use Catalyst::Utils ();
use Moose::Role;
use Prometheus::Tiny::Shared;

my $defaults = {
    metrics => {
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
    },
};

my ($prometheus,               # instance
    $ignore_path_regexp,       # set from config
    $include_action_labels,    # set from config
    $metrics_endpoint,         # set from config with default
    $no_default_controller,    # set from config
    $request_path              # derived from $metrics_endpoint
);

# for testing
sub _clear_prometheus {
    undef $prometheus;
}

sub prometheus {
    my $c = shift;
    $prometheus //= do {
        my $config = Catalyst::Utils::merge_hashes(
            $defaults,
            $c->config->{'Plugin::PrometheusTiny'} // {}
        );

        $include_action_labels = $config->{include_action_labels};

        $metrics_endpoint = $config->{endpoint};
        if ($metrics_endpoint) {
            if ( $metrics_endpoint !~ m|^/| ) {
                Carp::croak
                  "Plugin::PrometheusTiny endpoint '$metrics_endpoint' does not begin with '/'";
            }
        }
        else {
            $metrics_endpoint = '/metrics';
        }

        $request_path = $metrics_endpoint;
        $request_path =~ s|^/||;

        $ignore_path_regexp = $config->{ignore_path_regexp};
        if ($ignore_path_regexp) {
            $ignore_path_regexp = qr/$ignore_path_regexp/
              unless 'Regexp' eq ref $ignore_path_regexp;
        }

        $no_default_controller = $config->{no_default_controller};

        my $metrics = $config->{metrics};
        Carp::croak "Plugin::PrometheusTiny metrics must be a hash reference"
          unless 'HASH' eq ref $metrics;

        my $prom
          = Prometheus::Tiny::Shared->new(
            ( filename => $config->{filename} ) x defined $config->{filename}
          );

        for my $name ( sort keys %$metrics ) {
            $prom->declare(
                $name,
                %{ $metrics->{$name} },
            );
        }

        $prom;
    };
    return $prometheus;
}

after finalize => sub {
    my $c       = shift;
    my $request = $c->request;

    return
      if !$no_default_controller && $request->path eq $request_path;

    return
      if $ignore_path_regexp
      && $request->path =~ $ignore_path_regexp;

    my $response = $c->response;
    my $action   = $c->action;

    my $labels = {
        code   => $response->code,
        method => $request->method,
        $include_action_labels
        ? ( controller => $action->class,
            action     => $action->name
          )
        : ()
    };

    $prometheus->histogram_observe(
        'http_request_size_bytes',
        $request->content_length // 0,
        $labels
    );
    $prometheus->histogram_observe(
        'http_response_size_bytes',
        $response->has_body ? length( $response->body ) : 0,
        $labels
    );
    $prometheus->inc(
        'http_requests_total',
        $labels
    );
    $prometheus->histogram_observe(
        'http_request_duration_seconds',
        $c->stats->elapsed, $labels
    );
};

before setup_components => sub {
    my $class = shift;

    # initialise prometheus instance pre-fork and setup lexicals
    $class->prometheus;

    return
      if $class->config->{'Plugin::PrometheusTiny'}{no_default_controller};

    # Paranoia, as we're going to eval $metrics_endpoint
    if ( $metrics_endpoint =~ s|[^-A-Za-z0-9\._~/]||g ) {
        $class->log->warn(
            "Plugin::PrometheusTiny unsafe characters removed from endpoint");
    }

    $class->log->info(
        "Plugin::PrometheusTiny metrics endpoint installed at $metrics_endpoint"
    );

    eval qq|

        package Catalyst::Plugin::PrometheusTiny::Controller;
        use base 'Catalyst::Controller';

        sub begin : Private { }
        sub end : Private   { }

        sub metrics : Path($metrics_endpoint) Args(0) {
            my ( \$self, \$c ) = \@_;
            my \$res = \$c->res;
            \$res->content_type("text/plain");
            \$res->output( \$c->prometheus->format );
        }
        1;

    | or do {
        Carp::croak("Plugin::PrometheusTiny controller eval failed: $@");
    };

    $class->inject_component(
        "Controller::Plugin::PrometheusTiny" => {
            from_component => "Catalyst::Plugin::PrometheusTiny::Controller"
        }
    );
};

1;

=head1 NAME

Catalyst::Plugin::PrometheusTiny - use Prometheus::Tiny with Catalyst

=head1 SYNOPSIS

Use the plugin in your application class:

    package MyApp;
    use Catalyst 'PrometheusTiny';

    MyApp->setup;

Add more metrics:

    MyApp->config('Plugin::PrometheusTiny' => {
        metrics => {
            myapp_thing_to_measure => {
                help    => 'Some thing we want to measure',
                type    => 'histogram',
                buckets => [ 1, 50, 100, 1_000, 50_000, 500_000, 1_000_000 ],
            },
            myapp_something_else_to_measure => {
                help    => 'Some other thing we want to measure',
                type    => 'counter',
            },
        },
    });

And somewhere in your controller classes:

    $c->prometheus->observe_histogram(
        'myapp_thing_to_measure', $value, { label1 => 'foo' }
    );

    $c->prometheus->inc(
        'myapp_something_else_to_measure', $value, { label2 => 'bar' }
    );

Once your app has served from requests you can fetch request/response metrics:

    curl http://$myappaddress/metrics

=head1 DESCRIPTION

This plugin integrates L<Prometheus::Tiny::Shared> with your L<Catalyst> app,
providing some default metrics for requests and responses, with the ability
to easily add further metrics to your app. A default controller is included
which makes the metrics available via the configured L</endpoint>, though this
can be disabled if you prefer to add your own controller action.

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

=head1 METHODS

=head2 prometheus

    sub my_action {
        my ( $self, $c ) = @_;

        $c->prometheus->inc(...);
    }

Returns the C<Prometheus::Tiny::Shared> instance.

=head1 CONFIGURATION

=head2 endpoint

The endpoint from which metrics are served. Defaults to C</metrics>.

=head2 filename

It is recommended that this is set to a directory on a memory-backed
filesystem. See L<Prometheus::Tiny::Shared/filename> for details and default
value.

=head2 ignore_path_regex

    ignore_path_regex => '^(healthcheck|foobar)'

A regular expression against which C<< $c->request->path >> is checked, and
if there is a match then the request is not added to default request/response
metrics.

=head2 include_action_labels

    include_action_labels => 0      # default

If set to a true value, adds C<controller> and C<action> labels to the
default metrics, in addition to the C<code> and C<method> labels.

=head2 metrics

    metrics => {
        $metric_name => {
            help => $metric_help_text,
            type => $metric_type,
        },
        # more...
    }

See L<Prometheus::Tiny/declare>. Declare extra metrics to be added to those
included with the plugin.

=head2 no_default_controller

    no_default_controller => 0      # default

If set to a true value then the default L</endpoint> will not be
added, and you will need to add your own controller action for exporting the
metrics. Something like:

    package MyApp::Controller::Stats;

    sub begin : Private { }
    sub end  : Private  { }

    sub index : Path Args(0) {
        my ( $self, $c ) = @_;
        my $res = $c->res;
        $res->content_type("text/plain");
        $res->output( $c->prometheus->format );
    }

=head1 AUTHOR

Peter Mottram (SysPete) <peter@sysnix.com>

=head1 CONTRIBUTORS

Curtis "Ovid" Poe

Graham Christensen <graham@grahamc.com>

=head1 COPYRIGHT

Copyright (c) 2021 the Catalyst::Plugin::PrometheusTiny L</AUTHOR>
and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

