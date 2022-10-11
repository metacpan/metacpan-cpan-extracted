package Dancer2::Plugin::RPC::RESTISH;
use Moo;
use Dancer2::Plugin ;#qw( plugin_keywords );

with 'Dancer2::RPCPlugin';

our $VERSION = '2.02';
use constant PLUGIN_NAME => 'restish';

has allow_origin => (
    is      => 'rw',
    default => sub { {} },
);

use Dancer2::RPCPlugin::CallbackResultFactory;
use Dancer2::RPCPlugin::ErrorResponse;
use Dancer2::RPCPlugin::FlattenData;
use Dancer2::RPCPlugin::PluginNames;

Dancer2::RPCPlugin::PluginNames->new->add_names(PLUGIN_NAME);
Dancer2::RPCPlugin::ErrorResponse->register_error_responses(
    PLUGIN_NAME ,=> {
        -32500  => 500,
        -32601  => 403,
        default => 400,
    },
    sprintf("as_%s_error", PLUGIN_NAME) => sub {
        my $self = shift;

        return {
            error_code    => $self->error_code,
            error_message => $self->error_message,
            error_data    => $self->error_data,
        };
    }
);

use JSON;
use Scalar::Util 'blessed';
use Time::HiRes 'time';

# A char between the HTTP-Method and the REST-route
our $_HM_POSTFIX = '@';

plugin_keywords PLUGIN_NAME;

sub restish {
    my ($plugin, $endpoint, $arguments) = @_;
    my $restish_args = $arguments->{plugin_args} || {};

    $plugin->allow_origin->{$endpoint} = $restish_args->{cors_allow_origin} || '';

    my $dispatcher = $plugin->dispatch_builder(
        $endpoint,
        $arguments->{publish},
        $arguments->{arguments},
        plugin_setting(),
    )->();

    my $lister = $plugin->partial_method_lister(
        protocol => __PACKAGE__->rpcplugin_tag,
        endpoint => $endpoint,
        methods  => [ sort keys %{ $dispatcher } ],
    );

    my $code_wrapper = $plugin->code_wrapper($arguments);
    my $callback = $arguments->{callback};

    $plugin->app->log(debug => "Starting restish-handler build: ", $lister);
    my $handle_call = sub {
        my ($dsl) = @_;
        my ($pi) = grep { ref($_) eq __PACKAGE__ } @{ $dsl->plugins };

        my $allow_origin = $pi->allow_origin->{$endpoint};
        my @allowed_origins = split(" ", $allow_origin);

        # we'll only handle requests that have either a JSON body or no body
        my $http_request = $dsl->app->request;
        my ($ct) = split(/;\s*/, $http_request->content_type // "", 2);
        $ct //= "";

        if ($http_request->body && ($ct ne 'application/json')) {
            $dsl->pass();
        }

        my $http_method  = uc($http_request->method);
        my $request_path = $http_request->path;

        ##### Cross Origin Resource Sharing(CORS)
        my $has_origin_header = grep {
            lc($_) eq 'origin'
        } $http_request->headers->header_field_names;
        my $has_origin = $http_request->header('Origin') || '';
        my $allowed_origin = ($allow_origin eq '*')
                          || grep { $_ eq $has_origin } @allowed_origins;

        my $is_preflight = $has_origin_header && ($http_method eq 'OPTIONS');
        $dsl->app->log(debug => "[RESTISH-CORS] Preflight from $has_origin")
            if $is_preflight;

        # with CORS, we do not allow mismatches on Origin
        if ($allow_origin && $has_origin && !$allowed_origin) {
            $dsl->app->log(
                debug => "[RESTISH-CORS] '$has_origin' not allowed ($allow_origin)"
            );
            $dsl->response->status(403);
            $dsl->response->content_type('text/plain');
            return "[CORS] $has_origin not allowed";
        }

        # method_name should exist...
        # we need to turn 'GET@some_resource/:id' into a regex that we can use
        # to match this request so we know what thing to call...
        (my $method_name = $request_path) =~ s{^$endpoint/}{};
        my ($found_match, $found_method);
        my @sorted_dispatch_keys = sort {
            # reverse length of the regex we use to match
            my ($am, $ar) = split(/\b$_HM_POSTFIX/, $a);
            $ar =~ s{/:\w+}{/[^/]+};
            my ($bm, $br) = split(/\b$_HM_POSTFIX/, $b);
            $br =~ s{/:\w+}{/[^/]+};
            length($br) <=> length($ar)
        } keys %$dispatcher;

        my $preflight_method = $is_preflight
            ? $http_request->header('Access-Control-Request-Method') // 'GET'
            : undef;

        my $check_for_method;
        for my $plugin_route (@sorted_dispatch_keys) {
            my ($hm, $route) = split(/\b$_HM_POSTFIX/, $plugin_route, 2);
            $hm = uc($hm);

            if ($allow_origin && $is_preflight) {
                $check_for_method = $preflight_method;
            }
            else {
                $check_for_method = $http_method;
            }
            next if $hm ne $check_for_method;

            (my $route_match = $route) =~ s{:\w+}{[^/]+}g;
            $dsl->app->log(
                debug => "[restish_find_route($check_for_method)]"
                       . " $method_name, $route ($route_match)"
            );
            if ($method_name =~ m{^$route_match$}) {
                $found_match = $plugin_route;
                $found_method = $hm;
                last;
            }
        }

        if (! $found_match) {
            if ($allow_origin && $is_preflight) {
                my $msg = "[CORS-preflight] failed for $preflight_method => $request_path";
                $dsl->app->log(debug => $msg);
                $dsl->response->status(200); # maybe 403?
                $dsl->response->content_type('text/plain');
                return $msg;
            }
            $dsl->app->log(
                warning => "$http_method => $request_path ($method_name) not found, pass()"
            );
            $dsl->pass();
        }
        $dsl->app->log(
            debug => "[restish_found_route($http_method)]"
                   . " $request_path ($method_name) ($found_match)"
        );

        # Send the CORS 'Access-Control-Allow-Origin' header
        if ($allow_origin && $has_origin_header) {
            my $allow_now = $allow_origin eq '*' ? '*' : $has_origin;
            $dsl->response->header('Access-Control-Allow-Origin' => $allow_now);
        }

        if ($is_preflight) { # Send more CORS headers and return.
            $dsl->app->log(
                debug => "[CORS] preflight-request: $request_path ($method_name)"
            );
            $dsl->response->status(204);
            $dsl->response->header(
                'Access-Control-Allow-Headers',
                $http_request->header('Access-Control-Request-Headers')
            ) if $http_request->header('Access-Control-Request-Headers');

            $dsl->response->header('Access-Control-Allow-Methods' => $found_method);
            return "";
        }

        $dsl->response->content_type ('application/json');
        my $method_args = $http_request->body
            ? from_json($http_request->body)
            : { };
        my $route_args = $http_request->params('route') // { };
        my $query_args = $http_request->params('query') // { };

        # We'll merge method_args and route_args, where route_args win:
        $method_args = {
            %$method_args,
            %$route_args,
            %$query_args,
        };
        $dsl->app->log(
            debug => "[handle_restish_request('$request_path' via '$found_match')] "
                   , $method_args
        );

        my $start_request = time();
        my $continue = eval {
            (my $match_re = $found_match) =~ s{:\w+}{[^/]+}g;
            local $Dancer2::RPCPlugin::ROUTE_INFO = {
                plugin        => PLUGIN_NAME,
                route_matched => $found_match,
                matched_re    => $match_re,
                endpoint      => $endpoint,
                rpc_method    => $method_name,
                full_path     => $http_request->path,
                http_method   => $http_method,
            };
            $callback
                ? $callback->($http_request, $method_name, $method_args)
                : callback_success();
        };
        my $error = $@;
        my $response;
        if ($error) {
            my $error_response = error_response(
                error_code    => -32500,
                error_message => $error,
                error_data    => $method_args,
            );
            $dsl->response->status($error_response->return_status(PLUGIN_NAME));
            $response = $error_response->as_restish_error;
        }
        elsif (   !blessed($continue)
               || !$continue->can('does')
               || !$continue->does('Dancer2::RPCPlugin::CallbackResult'))
        {
            my $error_response = error_response(
                error_code    => -32603,
                error_message => "Internal error: 'callback_result' wrong class "
                               . blessed($continue),
                error_data    => $method_args,
            );
            $dsl->response->status($error_response->return_status(PLUGIN_NAME));
            $response = $error_response->as_restish_error;
        }
        elsif (blessed($continue) && !$continue->success) {
            my $error_response = error_response(
                error_code    => $continue->error_code,
                error_message => $continue->error_message,
                error_data    => $method_args,
            );
            $dsl->response->status($error_response->return_status(PLUGIN_NAME));
            $response = $error_response->as_restish_error;
        }
        else {
            my $di = $dispatcher->{$found_match};
            my $handler = $di->code;
            my $package = $di->package;

            $response = eval {
                $code_wrapper->($handler, $package, $method_name, $method_args);
            };
            my $error = $@;

            $dsl->app->log(debug => "[handled_restish_response($method_name)] ", $response);
            $dsl->app->log(
                info => sprintf(
                    "[RPC::RESTISH] request for '%s' took %.4fs",
                    $request_path, time() - $start_request
                )
            );

            if (my $error = $@) {
                my $error_response = blessed($error) && $error->can('as_restish_error')
                    ? $error
                    : error_response(
                        error_code    => 500,
                        error_message => $error,
                        error_data    => $method_args,
                    );
                $dsl->response->status($error_response->return_status(PLUGIN_NAME));
                $response = $error_response->as_restish_error;
            }
            if (blessed($response) && $response->can('as_restish_error')) {
                $dsl->response->status($response->return_status(PLUGIN_NAME));
                $response = $response->as_restish_error;
            }
            elsif (blessed($response)) {
                $response = flatten_data($response);
            }
            $dsl->app->log(debug => "[handled_restish_response($request_path)] ", $response);
        }
        my $jsonise_options = {canonical => 1};
        if ($dsl->config->{encoding} && $dsl->config->{encoding} =~ m{^utf-?8$}i) {
            $jsonise_options->{utf8} = 1;
        }

        # non-refs will be send as-is
        return ref($response)
            ? to_json($response, $jsonise_options)
            : $response;
    };

    $plugin->app->log(debug => "Setting routes (restish): $endpoint ", $lister);
    # split the keys in $dispatcher so we can register methods for all
    for my $dispatch_route (keys %$dispatcher) {
        my ($hm, $route) = split(/$_HM_POSTFIX/, $dispatch_route, 2);
        my $dancer_route = "$endpoint/$route";
        $plugin->app->log(debug => "[restish] registering `$hm $dancer_route`");
        $plugin->app->add_route(
            method => lc($hm),
            regexp => $dancer_route,
            code   => $handle_call,
        );
        $plugin->app->add_route(
            method => 'options',
            regexp => $dancer_route,
            code   => $handle_call
        ) if $plugin->allow_origin;
    }

};

use namespace::autoclean;
1;

=head1 NAME

Dancer::Plugin::RPC::RESTISH - Simple plugin to implement a restish interface.

=head1 SYNOPSIS

In the Controler-bit:

    use Dancer::Plugin::RPC::RESTISH;
    restish '/endpoint' => {
        publish     => 'pod',
        arguments   => ['MyProject::Admin'],
        plugin_args => {
            cors_allow_origin => '*',
        },
    };

and in the Model-bit (B<MyProject::Admin>):

    package MyProject::Admin;
    
    =for restish GET@ability/:id rpc_get_ability_details
    
    =cut
    
    sub rpc_get_ability_details {
        my %args = @_; # contains: {"id": 42}
        return {
            # datastructure
        };
    }
    1;

=head1 DESCRIPTION

RESTISH is an implementation of REST that lets you bind routes to code in the
style the rest of L<Dancer::Plugin::RPC> modules do. One must realise that this
basically binds REST-paths to RPC-methods (that's not ideal, but saves a lot of
code).

B<This version only supports JSON as data serialisation>.

=head2 restish '/base_path' => \%publisher_arguments

See L<Dancer::Plugin::RPC>, L<Dancer::Plugin::RPC::JSONRPC>,
L<Dancer::Plugin::RPC::RESTRPC>, L<Dancer::Plugin::RPC::XMLRPC> for more
information about the C<%publisher_arguments>.

=head2 Implement the routes for RESTISH

The plugin registers Dancer-C<any> route-handlers for the C<base_path> +
C<method_path> and the route-handler looks for a data-handler that matches the path
and HTTP-method.

Method-paths can contain colon-prefixed parameters native to Dancer. These
parameters will be merged with the content-parameters and the query-parameters
into a single hash which will be passed to the code as the parameters.

Method-paths are prefixed by a HTTP-method followed by B<@>:

=over

=item publisher => 'config'

plugins:
    'RPC::RESTISH':
        '/rest':
            'MyProject::Admin':
                'GET@resources':       'get_all_resourses'
                'POST@resource':       'create_resource'
                'GET@resource/:id':    'get_resource'
                'PATCH@resource/:id':  'update_resource'
                'DELETE@resource/:id': 'delete_resource'

=item publisher => 'pod'

    =for restish GET@resources       get_all_resources /rest
    =for restish POST@resource       create_resource   /rest
    =for restish GET@resource/:id    get_resource      /rest
    =for restish PATCH@resource/:id  update_resource   /rest
    =for restish DELETE@resource/:id delete_resource   /rest

The third argument (the base_path) is optional.

=back

The plugin for RESTISH also adds 2 fields to C<$Dancer2::RPCPlugin::ROUTE_INFO>:

        local $Dancer2::RPCPlugin::ROUTE_INFO = {
            plugin        => PLUGIN_NAME,
            endpoint      => $endpoint,
            rpc_method    => $method_name,
            full_path     => request->path,
            http_method   => $http_method,
            # These two are added
            route_matched => $found_match,      # PATCH@resource/:id
            matched_re    => $match_re,         # PATCH@resource/[^/]+
        };

=head2 CORS (Cross-Origin Resource Sharing)

If one wants the service to be directly called from javascript in a browser, one
has to consider CORS as browsers enforce that. This means that the actual
request is preceded by what's called a I<preflight request> that uses the
HTTP-method B<OPTIONS> with a number of header-fields.

=over

=item Origin

=item Access-Control-Request-Method

=back

The plugin supports considering these CORS requests, by special casing these
B<OPTIONS> requests and always sending the C<Access-Control-Allow-Origin> header
as set in the config options.

=head3 cors_allow_origin => $list_of_urls | '*'

If left out, no attempt to honour a CORS B<OPTIONS> request will be done and the
request will be passed.

When set to a value, the B<OPTIONS> request will be executed, for any http-method in
the C<Access-Control-Request-Method> header. The response to the B<OPTIONS>
request will also contain every C<Access-Control-Allow-*> header that was
requested as C<Access-Control-Request-*> header.

When set, all responses will contain the C<Access-Control-Allow-Origin>-header
with either C<*> if that was set, or the value of the actual C<Origin>-header
that was passed and equals one the preset values.

=head1 INTERNAL

=head2 Attributes

=over

=item B<allow_origin>

Where do we allow Origin to be from.

=back

=head2 build_dispatcher_from_config

Creates a (partial) dispatch table from data passed from the (YAML)-config file.

=head2 build_dispatcher_from_pod

Creates a (partial) dispatch table from data provided in POD.

=begin pod-coverage

=head2 PLUGIN_NAME

The name for this plugin.

=end pod-coverage

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 COPYRIGHT

E<copy> MMXX - Abe Timmerman <abeltje@cpan.org>

=cut
