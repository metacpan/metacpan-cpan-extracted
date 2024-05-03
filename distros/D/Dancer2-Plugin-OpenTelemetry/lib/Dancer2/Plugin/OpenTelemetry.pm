package Dancer2::Plugin::OpenTelemetry;
# ABSTRACT: Use OpenTelemetry in your Dancer2 app

our $VERSION = '0.002';

use strict;
use warnings;
use experimental 'signatures';

use Dancer2::Plugin;
use OpenTelemetry -all;
use OpenTelemetry::Constants -span;

use constant BACKGROUND => 'otel.plugin.dancer2.background';

sub BUILD ( $plugin, @ ) {
    my %tracer = %{
        $plugin->config->{tracer} // {
            name => otel_config('SERVICE_NAME') // 'dancer2',
        },
    };

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub ( $app ) {
                my $req = $app->request;

                # Make sure we only handle each request once
                # This protects us against duplicating efforts in the
                # event of eg. a `forward` or a `pass`.
                return if $req->env->{+BACKGROUND};

                # Since our changes to the current context are global,
                # we try to store a copy of the previous "background"
                # context to restore it after we are done
                # As long as we do this, these global changes _should_
                # be invisible to other well-behaved applications that
                # rely on this context and are using dynamically as
                # appropriate.
                $req->env->{+BACKGROUND} = otel_current_context;

                my $url = URI->new(
                    $req->scheme . '://' . $req->host . $req->uri
                );

                my $method  = $req->method;
                my $route   = $req->route->spec_route;
                my $agent   = $req->agent;
                my $query   = $url->query;
                my $version = $req->protocol =~ s{.*/}{}r;

                # https://opentelemetry.io/docs/specs/semconv/http/http-spans/#setting-serveraddress-and-serverport-attributes
                my $hostport;
                if ( my $fwd = $req->header('forwarded') ) {
                    my ($first) = split ',', $fwd, 2;
                    $hostport = $1 // $2 if $first =~ /host=(?:"([^"]+)"|([^;]+))/;
                }

                $hostport //= $req->header('x-forwarded-proto')
                    // $req->header('host');

                my ( $host, $port ) = $hostport =~ /(.*?)(?::([0-9]+))?$/g;

                my $context = otel_propagator->extract(
                    $req,
                    undef,
                    sub ( $carrier, $key ) { scalar $carrier->header($key) },
                );

                my $span = otel_tracer_provider->tracer(%tracer)->create_span(
                    name       => $method . ' ' . $route,
                    parent     => $context,
                    kind       => SPAN_KIND_SERVER,
                    attributes => {
                        'http.request.method'            => $method,
                        'network.protocol.version'       => $version,
                        'url.path'                       => $url->path,
                        'url.scheme'                     => $url->scheme,
                        'http.route'                     => $route,
                        'client.address'                 => $req->address,
                      # 'client.port'                    => ..., # TODO
                        $host  ? ( 'server.address'      => $host  ) : (),
                        $port  ? ( 'server.port'         => $port  ) : (),
                        $agent ? ( 'user_agent.original' => $agent ) : (),
                        $query ? ( 'url.query'           => $query ) : (),
                    },
                );

                # Normally we would set this with `dynamically`, to ensure
                # that any previous context was restored after the fact.
                # However, that requires us to be have a scope that wraps
                # around the entire request, and Dancer2 does not have such
                # a hook.
                # We can do that with the Plack middleware, but that has no
                # way to hook into the Dancer2 router at span-creation time,
                # so we have no way to generate a low-cardinality span name
                # early enough for it to be used in a sampling decision.
                otel_current_context
                    = otel_context_with_span( $span, $context );
            },
        ),
    );

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub ( $res ) {
                return unless my $context
                    = delete $plugin->app->request->env->{+BACKGROUND};

                my $span = otel_span_from_context;
                my $code = $res->status;

                if ($code < 400) {
                    $span->set_status(SPAN_STATUS_OK );
                }
                elsif ($code >= 500) {
                    $span->set_status(SPAN_STATUS_ERROR);
                }

                $span
                    ->set_attribute( 'http.response.status_code' => $code )
                    ->end;

                otel_current_context = $context;
            },
        ),
    );

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'on_route_exception',
            code => sub ( $, $error ) {
                return unless my $context
                    = delete $plugin->app->request->env->{+BACKGROUND};

                my ($message) = split /\n/, "$error", 2;
                $message =~ s/ at \S+ line \d+\.$//a;

                otel_span_from_context
                    ->record_exception($error)
                    ->set_status( SPAN_STATUS_ERROR, $message )
                    ->set_attribute(
                        'error.type' => ref $error || 'string',
                        'http.response.status_code' => 500,
                    )
                    ->end;

                otel_current_context = $context;
            },
        ),
    );
}

1;
