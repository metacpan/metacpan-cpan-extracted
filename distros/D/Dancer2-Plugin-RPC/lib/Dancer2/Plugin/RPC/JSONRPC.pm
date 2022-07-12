package Dancer2::Plugin::RPC::JSONRPC;
use Dancer2::Plugin;
use Moo;

with 'Dancer2::RPCPlugin';

our $VERSION = '2.00';
use constant PLUGIN_NAME => 'jsonrpc';

use Dancer2::RPCPlugin::CallbackResultFactory;
use Dancer2::RPCPlugin::ErrorResponse;
use Dancer2::RPCPlugin::FlattenData;

use JSON;
use Scalar::Util 'blessed';
use Time::HiRes 'time';

plugin_keywords PLUGIN_NAME;

sub jsonrpc {
    my ($plugin, $endpoint, $config) = @_;

    my $dispatcher = $plugin->dispatch_builder(
        $endpoint,
        $config->{publish},
        $config->{arguments},
        plugin_setting(),
    )->();

    my $lister = $plugin->partial_method_lister(
        protocol => __PACKAGE__->rpcplugin_tag,
        endpoint => $endpoint,
        methods  => [ sort keys %{ $dispatcher } ],
    );

    my $code_wrapper = $plugin->code_wrapper($config);
    my $callback = $config->{callback};

    $plugin->app->log(debug => "Starting jsonrpc-handler build: ", $lister);
    my $jsonrpc_handler = sub {
        my ($dsl) = @_;

        my $http_request = $dsl->app->request;
        my ($ct) = (split /;\s*/, $http_request->content_type, 2);
        if ($ct ne 'application/json') {
            $dsl->app->pass();
        }
        my @requests = unjson($http_request->body);
        if (!exists($requests[0]->{jsonrpc}) or $requests[0]->{jsonrpc} ne "2.0") {
            $dsl->app->pass();
        }

        $dsl->app->log(
            debug => "[handle_jsonrpc_request] Processing: ", $http_request->body
        );

        $dsl->app->response->content_type('application/json');
        my @responses;
        for my $request (@requests) {
            my $method_name = $request->{method};

            if (!exists $dispatcher->{$method_name}) {
                $dsl->app->log(warning => "$endpoint/#$method_name not found.");

#                # single request; might be another handler
#                $dsl->app->pass() if @requests == 1;

                push @responses, jsonrpc_response(
                    $request->{id},
                    error => {
                        code    => -32601,
                        message => "Method '$method_name' not found at '$endpoint' (skipped)",
                    },
                );
                next;
            }

            my $method_args = $request->{params};
            my $start_request = time();
            $dsl->app->log(debug => "[handle_jsonrpc_call($method_name)] ", $method_args);
            my $continue = eval {
                local $Dancer2::RPCPlugin::ROUTE_INFO = {
                    plugin        => PLUGIN_NAME,
                    endpoint      => $endpoint,
                    rpc_method    => $method_name,
                    full_path     => $http_request->path,
                    http_method   => uc($http_request->method),
                };
                $callback
                    ? $callback->($plugin->app->request(), $method_name, $method_args)
                    : callback_success();
            };

            if (my $error = $@) {
                push @responses, jsonrpc_response(
                    $request->{id},
                    error => {
                        code    => 500,
                        message => $error,
                    },
                );
                next;
            }
            if (!blessed($continue) || !$continue->does('Dancer2::RPCPlugin::CallbackResult')) {
                push @responses, jsonrpc_response(
                    $request->{id},
                    error => {
                        code    => -32603,
                        message => "Internal error: 'callback_result' wrong class "
                                 . blessed($continue),
                    },
                );
                next;
            }
            elsif (blessed($continue) && !$continue->success) {
                push @responses, jsonrpc_response(
                    $request->{id},
                    error => {
                        code    => $continue->error_code,
                        message => $continue->error_message,
                    },
                );
                next;
            }

            my $di = $dispatcher->{$method_name};
            my $handler = $di->code;
            my $package = $di->package;

            my $result = eval {
                $code_wrapper->($handler, $package, $method_name, $method_args);
            };
            my $error = $@;

            $dsl->app->log(
                debug => "[handled_jsonrpc_call($method_name)] ", flatten_data($result)
            );
            $dsl->app->log(
                info => sprintf(
                    "[RPC::JSONRPC] request for '%s' took %.4fs",
                    $method_name, time() - $start_request
                )
            );
            if ($error) {
                my $error_response = blessed($error) && $error->can('as_jsonrpc_error')
                    ? $error
                    : error_response(
                            error_code    => -32500,
                            error_message => $error,
                            error_data    => $method_args,
                    );
                $dsl->app->response->status($error_response->return_status(PLUGIN_NAME));
                push @responses, jsonrpc_response(
                    $request->{id},
                    %{ $error_response->as_jsonrpc_error },
                );
                next;
            }

            if (blessed($result) && $result->can('as_jsonrpc_error')) {
                push @responses, jsonrpc_response(
                    $request->{id},
                    %{ $result->as_jsonrpc_error }
                );
                next;
            }
            elsif (blessed($result)) {
                $result = flatten_data($result);
            }

            push @responses, jsonrpc_response($request->{id}, result => $result);
        }

        # create response
        my $jsonise_options = {canonical => 1};
        if ($dsl->config->{encoding} && $dsl->config->{encoding} =~ m{^utf-?8$}i) {
            $jsonise_options->{utf8} = 1;
        }

        my $response;
        if (@responses == 1) {
            if (!defined $responses[0]->{id}) {
                $plugin->app->response->status('accepted');
            }
            else {
                $response = to_json($responses[0], $jsonise_options);
            }
        }
        else {
            $response = to_json([grep {defined($_->{id})} @responses], $jsonise_options);
        }

        $dsl->app->log(debug => "[jsonrpc_response] ", $response);
        return $response;
    };

    $plugin->app->add_route(
        method => 'post',
        regexp => $endpoint,
        code   => $jsonrpc_handler,
    );
}

sub unjson {
    my ($body) = @_;
    return if !$body;

    my @requests;
    my $unjson = decode_json($body);
    if (ref($unjson) ne 'ARRAY') {
        @requests = ($unjson);
    }
    else {
        @requests = @$unjson;
    }
    return @requests;
}

sub jsonrpc_response {
    my ($id, $type, $data) = @_;

    return {
        jsonrpc => '2.0',
        id      => $id,
        $type   => $data,
    };
}

use namespace::autoclean;
1;

__END__

=head1 NAME

Dancer2::Plugin::RPC::JSON - Dancer Plugin to register jsonrpc2 methods.

=head1 SYNOPSIS

In the Controler-bit:

    use Dancer2::Plugin::RPC::JSON;
    jsonrpc '/endpoint' => {
        publish   => 'pod',
        arguments => ['MyProject::Admin']
    };

and in the Model-bit (B<MyProject::Admin>):

    package MyProject::Admin;
    
    =for jsonrpc rpc.abilities rpc_show_abilities
    
    =cut
    
    sub rpc_show_abilities {
        return {
            # datastructure
        };
    }
    1;


=head1 DESCRIPTION

This plugin lets one bind an endpoint to a set of modules with the new B<jsonrpc> keyword.

=head2 jsonrpc '/endpoint' => \%publisher_arguments;

=head3 C<\%publisher_arguments>

=over

=item callback => $coderef [optional]

The callback will be called just before the actual rpc-code is called from the
dispatch table. The arguments are positional: (full_request, method_name).

    my Dancer2::RPCPlugin::CallbackResult $continue = $callback
        ? $callback->(request(), $method_name, $method_args)
        : callback_success();

The callback should return a L<Dancer2::RPCPlugin::CallbackResult> instance:

=over 8

=item * on_success

    callback_success()

=item * on_failure

    callback_fail(
        error_code    => <numeric_code>,
        error_message => <error message>
    )

=back

=item code_wrapper => $coderef [optional]

The codewrapper will be called with these positional arguments:

=over 8

=item 1. $call_coderef

=item 2. $package (where $call_coderef is)

=item 3. $method_name

=item 4. @arguments

=back

The default code_wrapper-sub is:

    sub {
        my $code = shift;
        my $pkg  = shift;
        $code->(@_);
    };

=item publisher => <config | pod | \&code_ref>

The publiser key determines the way one connects the rpc-method name with the actual code.

=over

=item publisher => 'config'

This way of publishing requires you to create a dispatch-table in the app's config YAML:

    plugins:
        "RPC::JSON":
            '/endpoint':
                'MyProject::Admin':
                    admin.someFunction: rpc_admin_some_function_name
                'MyProject::User':
                    user.otherFunction: rpc_user_other_function_name

The Config-publisher doesn't use the C<arguments> value of the C<%publisher_arguments> hash.

=item publisher => 'pod'

This way of publishing enables one to use a special POD directive C<=for jsonrpc>
to connect the rpc-method name to the actual code. The directive must be in the
same file as where the code resides.

    =for jsonrpc admin.someFunction rpc_admin_some_function_name

The POD-publisher needs the C<arguments> value to be an arrayref with package names in it.

=item publisher => \&code_ref

This way of publishing requires you to write your own way of building the dispatch-table.
The code_ref you supply, gets the C<arguments> value of the C<%publisher_arguments> hash.

A dispatch-table looks like:

    return {
        'admin.someFuncion' => dispatch_item(
            package => 'MyProject::Admin',
            code    => MyProject::Admin->can('rpc_admin_some_function_name'),
        ),
        'user.otherFunction' => dispatch_item(
            package => 'MyProject::User',
            code    => MyProject::User->can('rpc_user_other_function_name'),
        ),
    }

=back

=item arguments => <anything>

The value of this key depends on the publisher-method chosen.

=back

=head2 =for jsonrpc jsonrpc-method-name sub-name

This special POD-construct is used for coupling the jsonrpc-methodname to the
actual sub-name in the current package.

=head1 INTERNAL

=head2 unjson

Deserializes the string as Perl-datastructure.

=head2 jsonrpc_response

Returns a jsonrpc response as a hashref.

=head2 build_dispatcher_from_config

Creates a (partial) dispatch table from data passed from the (YAML)-config file.

=head2 build_dispatcher_from_pod

Creates a (partial) dispatch table from data provided in POD.

=begin pod_coverage

=head2 PLUGIN_NAME

=end pod_coverage

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abeltje@cpan.org>.

=cut
