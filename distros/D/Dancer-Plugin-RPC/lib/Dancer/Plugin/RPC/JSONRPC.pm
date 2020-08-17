package Dancer::Plugin::RPC::JSONRPC;
use v5.10;
use Dancer ':syntax';
use Dancer::Plugin;
use Scalar::Util 'blessed';

our $VERSION = '1.08';

no if $] >= 5.018, warnings => 'experimental::smartmatch';

use constant PLUGIN_NAME => 'jsonrpc';

use Dancer::RPCPlugin::CallbackResult;
use Dancer::RPCPlugin::DispatchFromConfig;
use Dancer::RPCPlugin::DispatchFromPod;
use Dancer::RPCPlugin::DispatchItem;
use Dancer::RPCPlugin::DispatchMethodList;
use Dancer::RPCPlugin::ErrorResponse;
use Dancer::RPCPlugin::FlattenData;

my %dispatch_builder_map = (
    pod    => \&build_dispatcher_from_pod,
    config => \&build_dispatcher_from_config,
);

register PLUGIN_NAME ,=> sub {
    my ($self, $endpoint, $arguments) = plugin_args(@_);

    my $publisher;
    given ($arguments->{publish} // 'config') {
        when (exists $dispatch_builder_map{$_}) {
            $publisher = $dispatch_builder_map{$_};
            $arguments->{arguments} = plugin_setting() if $_ eq 'config';
        }
        default {
            $publisher = $_;
        }
    }
    my $dispatcher = $publisher->($arguments->{arguments}, $endpoint);

    my $lister = Dancer::RPCPlugin::DispatchMethodList->new();
    $lister->set_partial(
        protocol => PLUGIN_NAME,
        endpoint => $endpoint,
        methods  => [ sort keys %{ $dispatcher } ],
    );

    my $code_wrapper = $arguments->{code_wrapper}
        ? $arguments->{code_wrapper}
        : sub {
            my $code = shift;
            my $pkg  = shift;
            $code->(@_);
        };
    my $callback = $arguments->{callback};

    debug("Starting jsonrpc-handler build: ", $lister);
    my $handle_call = sub {
        my ($ct) = (split /;\s*/, request->content_type, 2);
        if ($ct ne 'application/json') {
            pass();
        }
        my @requests = unjson(request->body);
        if (!exists($requests[0]->{jsonrpc}) or $requests[0]->{jsonrpc} ne "2.0") {
            pass();
        }

        debug("[handle_jsonrpc_request] Processing: ", request->body);

        content_type 'application/json';
        my @responses;
        for my $request (@requests) {
            my $method_name = $request->{method};
            debug("[handle_jsonrpc_call($method_name)] $method_name ", $request);

            if (!exists $dispatcher->{$method_name}) {
                push(
                    @responses,
                    jsonrpc_response(
                        $request->{id},
                        error => {
                            code    => -32601,
                            message => "Method '$method_name' not found",
                        }
                    )
                );
                next;
            }

            my $method_args = $request->{params};
            my Dancer::RPCPlugin::CallbackResult $continue = eval {
                local $Dancer::RPCPlugin::ROUTE_INFO = {
                    plugin        => PLUGIN_NAME,
                    endpoint      => $endpoint,
                    rpc_method    => $method_name,
                    full_path     => request->path,
                    http_method   => uc(request->method),
                };
                $callback
                    ? $callback->(request(), $method_name, $method_args)
                    : callback_success();
            };

            if (my $error = $@) {
                push(
                    @responses,
                    jsonrpc_response(
                        $request->{id},
                        error => {
                            code    => -32500,
                            message => $error,
                        }
                    )
                );
                next;
            }
            if (!blessed($continue) || !$continue->isa('Dancer::RPCPlugin::CallbackResult')) {
                push @responses, jsonrpc_response(
                    $request->{id},
                    error => {
                        code    => -32603,
                        message => "Internal error: 'callback_result' wrong class " . blessed($continue),
                    }
                );
                next;
            }
            elsif (blessed($continue) && !$continue->success) {
                    push @responses, jsonrpc_response(
                        $request->{id},
                        error => {
                            code    => $continue->error_code,
                            message => $continue->error_message,
                        }
                    );
                    next;
            }

            my Dancer::RPCPlugin::DispatchItem $di = $dispatcher->{$method_name};
            my $handler = $di->code;
            my $package = $di->package;

            my $result = eval {
                $code_wrapper->($handler, $package, $method_name, $method_args);
            };
            my $error = $@;

            debug("[handled_jsonrpc_call($method_name)] ", flatten_data($result));
            if ($error) {
                my $error_response = blessed($error) && $error->can('as_jsonrpc_error')
                    ? $error
                    : error_response(
                            error_code    => -32500,
                            error_message => $error,
                            error_data    => $method_args,
                    );
                status $error_response->return_status(PLUGIN_NAME);
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
        if (config->{encoding} && config->{encoding} =~ m{^utf-?8$}i) {
            $jsonise_options->{utf8} = 1;
        }
        my $response;
        if (@responses == 1) {
            $response = to_json($responses[0], $jsonise_options);
        }
        else {
            $response = to_json([grep {defined($_->{id})} @responses], $jsonise_options);
        }

        return $response;
    };

    debug("setting route (jsonrpc): $endpoint ", $lister);
    post $endpoint, $handle_call;
};

sub unjson {
    my ($body) = @_;

    my @requests;
    my $unjson = from_json($body, {utf8 => 1});
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
        $type  => $data,
    };
}

sub build_dispatcher_from_pod {
    my ($pkgs, $endpoint) = @_;
    debug("[build_dispatcher_from_pod]");

    return dispatch_table_from_pod(
        plugin   => PLUGIN_NAME,
        packages => $pkgs,
        endpoint => $endpoint,
    );
}

sub build_dispatcher_from_config {
    my ($config, $endpoint) = @_;
    debug("[build_dispatcher_from_config] $endpoint");

    return dispatch_table_from_config(
        plugin   => PLUGIN_NAME,
        config   => $config,
        endpoint => $endpoint,
    );
}

register_plugin;
1;

=head1 NAME

Dancer::Plugin::RPC::JSONRPC - Dancer Plugin to register jsonrpc2 methods.

=head1 SYNOPSIS

In the Controler-bit:

    use Dancer::Plugin::RPC::JSONRPC;
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

    my Dancer::RPCPlugin::CallbackResult $continue = $callback
        ? $callback->(request(), $method_name, $method_args)
        : callback_success();

The callback should return a L<Dancer::RPCPlugin::CallbackResult> instance:

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
        "RPC::JSONRPC":
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

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abeltje@cpan.org>.

=begin podcover_can_suck

=head2 PLUGIN_NAME

L<Test::Pod::Coverage> fails this test without this section :'(

=end podcover_can_suck

=cut
