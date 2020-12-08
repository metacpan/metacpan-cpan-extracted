package Dancer::Plugin::RPC::RESTRPC;
use v5.10;
use Dancer ':syntax';
use Dancer::Plugin;
use Scalar::Util 'blessed';
use Time::HiRes 'time';

our $VERSION = '1.09';

no if $] >= 5.018, warnings => 'experimental::smartmatch';

use constant PLUGIN_NAME => 'restrpc';

use Dancer::RPCPlugin::CallbackResult;
use Dancer::RPCPlugin::ErrorResponse;
use Dancer::RPCPlugin::DispatchFromConfig;
use Dancer::RPCPlugin::DispatchFromPod;
use Dancer::RPCPlugin::DispatchItem;
use Dancer::RPCPlugin::DispatchMethodList;
use Dancer::RPCPlugin::FlattenData;

my %dispatch_builder_map = (
    pod    => \&build_dispatcher_from_pod,
    config => \&build_dispatcher_from_config,
);

register PLUGIN_NAME ,=> sub {
    my($self, $base_url, $arguments) = plugin_args(@_);

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
    my $dispatcher = $publisher->($arguments->{arguments}, $base_url);

    my $lister = Dancer::RPCPlugin::DispatchMethodList->new();
    $lister->set_partial(
        protocol => PLUGIN_NAME,
        endpoint => $base_url,
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

    debug("Starting restrpc-handler build: ", $lister);
    my $handle_call = sub {
        my ($ct) = (split /;\s*/, request->content_type, 2);
        if ($ct ne 'application/json') {
            pass();
        }
        debug("[handle_restrpc_request] Processing: ", request->body);

        # method_name should exist
        my ($method_name) = request->path =~ m{$base_url/(\w+)};
        if (! exists $dispatcher->{$method_name}) {
            warning("$base_url/#$method_name not found, pass()");
            pass();
        }

        content_type 'application/json';
        my $response;
        my $method_args = request->body
            ? from_json(request->body)
            : undef;

        debug("[handle_restrpc_call($method_name)] ", $method_args);
        my $start_request = time();
        my Dancer::RPCPlugin::CallbackResult $continue = eval {
            local $Dancer::RPCPlugin::ROUTE_INFO = {
                plugin        => PLUGIN_NAME,
                endpoint      => $base_url,
                rpc_method    => $method_name,
                full_path     => request->path,
                http_method   => uc(request->method),
            };
            $callback
                ? $callback->(request(), $method_name, $method_args)
                : callback_success();
        };

        if (my $error = $@) {
            my $error_response = Dancer::RPCPlugin::ErrorResponse->new(
                error_code => 500,
                error_message => $error,
            );
            status $error_response->return_status(PLUGIN_NAME);
            $response = $error_response->as_restrpc_error;
        }
        elsif (!blessed($continue) || !$continue->isa('Dancer::RPCPlugin::CallbackResult')) {
            my $error_response = Dancer::RPCPlugin::ErrorResponse->new(
                error_code    => 500,
                error_message => "Internal error: 'callback_result' wrong class " . blessed($continue),
            );
            status $error_response->return_status(PLUGIN_NAME);
            $response = $error_response->as_restrpc_error;
        }
        elsif (blessed($continue) && !$continue->success) {
            my $error_response = Dancer::RPCPlugin::ErrorResponse->new(
                error_code    => $continue->error_code,
                error_message => $continue->error_message,
            );
            status $error_response->return_status(PLUGIN_NAME);
            $response = $error_response->as_restrpc_error;
        }
        else {
            my Dancer::RPCPlugin::DispatchItem $di = $dispatcher->{$method_name};
            my $handler = $di->code;
            my $package = $di->package;

            $response = eval {
                $code_wrapper->($handler, $package, $method_name, $method_args);
            };

            debug("[handled_restrpc_request($method_name)] ", flatten_data($response));
            if (my $error = $@) {
                my $error_response = blessed($error) && $error->can('as_restrpc_error')
                    ? $error
                    : error_response(
                            error_code    => -32500,
                            error_message => $error,
                            error_data    => $method_args,
                    );
                status $error_response->return_status(PLUGIN_NAME);
                $response = $error_response->as_restrpc_error;
            }
            elsif (blessed($response) && $response->can('as_restrpc_error')) {
               $response = $response->as_restrpc_error;
            }
            elsif (blessed($response)) {
                $response = flatten_data($response);
            }
        }
        $response = { result => $response } if !ref($response);
        my $jsonise_options = {canonical => 1};
        if (config->{encoding} && config->{encoding} =~ m{^utf-?8$}i) {
            $jsonise_options->{utf8} = 1;
        }
        info( sprintf(
            "[RPC::RESTRPC] request for %s took %.4fs",
            $method_name, time() - $start_request
        ));
        return to_json($response, $jsonise_options);
    };

    debug("setting routes (restrpc): $base_url ", $lister);
    for my $call (keys %{ $dispatcher }) {
        my $endpoint = "$base_url/$call";
        post $endpoint, $handle_call;
    }
};

sub build_dispatcher_from_pod {
    my ($pkgs, $endpoint) = @_;
    debug("[build_dispatcher_from_pod]");
    return dispatch_table_from_pod(
        plugin   => 'restrpc',
        packages => $pkgs,
        endpoint => $endpoint,
    );
}

sub build_dispatcher_from_config {
    my ($config, $endpoint) = @_;
    debug("[build_dispatcher_from_config] ");

    return dispatch_table_from_config(
        plugin   => 'restrpc',
        config   => $config,
        endpoint => $endpoint,
    );
}

register_plugin();
true;

=head1 NAME

Dancer::Plugin::RPC::RESTRPC - RESTRPC Plugin for Dancer

=head2 SYNOPSIS

In the Controler-bit:

    use Dancer::Plugin::RPC::RESTRPC;
    restrpc '/base_url' => {
        publish   => 'pod',
        arguments => ['MyProject::Admin']
    };

and in the Model-bit (B<MyProject::Admin>):

    package MyProject::Admin;
    
    =for restrpc rpc_abilities rpc_show_abilities
    
    =cut
    
    sub rpc_show_abilities {
        return {
            # datastructure
        };
    }
    1;

=head1 DESCRIPTION

RESTRPC is a simple protocol that uses HTTP-POST to post a JSON-string (with
C<Content-Type: application/json> to an endpoint. This endpoint is the
C<base_url> concatenated with the rpc-method name.

This plugin lets one bind a base_url to a set of modules with the new B<restrpc> keyword.

=head2 restrpc '/base_url' => \%publisher_arguments;

=head3 C<\%publisher_arguments>

=over

=item callback => $coderef [optional]

The callback will be called just before the actual rpc-code is called from the
dispatch table. The arguments are positional: (full_request, method_name).

    my Dancer::RPCPlugin::CallbackResult $continue = $callback
        ? $callback->(request(), $method_name, @method_args)
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
        my $code   = shift;
        my $pkg    = shift;
        my $method = shift;
        $code->(@_);
    };

=item publisher => <config | pod | \&code_ref>

The publiser key determines the way one connects the rpc-method name with the actual code.

=over

=item publisher => 'config'

This way of publishing requires you to create a dispatch-table in the app's config YAML:

    plugins:
        "RPC::RESTRPC":
            '/base_url':
                'MyProject::Admin':
                    admin.someFunction: rpc_admin_some_function_name
                'MyProject::User':
                    user.otherFunction: rpc_user_other_function_name

The Config-publisher doesn't use the C<arguments> value of the C<%publisher_arguments> hash.

=item publisher => 'pod'

This way of publishing enables one to use a special POD directive C<=for restrpc>
to connect the rpc-method name to the actual code. The directive must be in the
same file as where the code resides.

    =for restrpc admin_someFunction rpc_admin_some_function_name

The POD-publisher needs the C<arguments> value to be an arrayref with package names in it.

=item publisher => \&code_ref

This way of publishing requires you to write your own way of building the dispatch-table.
The code_ref you supply, gets the C<arguments> value of the C<%publisher_arguments> hash.

A dispatch-table looks like:

    return {
        'admin_someFuncion' => dispatch_item(
            package => 'MyProject::Admin',
            code    => MyProject::Admin->can('rpc_admin_some_function_name'),
        ),
        'user_otherFunction' => dispatch_item(
            package => 'MyProject::User',
            code    => MyProject::User->can('rpc_user_other_function_name'),
        ),
    }

=back

=item arguments => <anything>

The value of this key depends on the publisher-method chosen.

=back

=head2 =for restrpc restrpc-method-name sub-name

This special POD-construct is used for coupling the restrpc-methodname to the
actual sub-name in the current package.

=head1 INTERNAL

=head2 build_dispatcher_from_config

Creates a (partial) dispatch table from data passed from the (YAML)-config file.

=head2 build_dispatcher_from_pod

Creates a (partial) dispatch table from data provided in POD.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=begin podcover_can_suck

=head2 PLUGIN_NAME

L<Test::Pod::Coverage> fails this test without this section :'(

=end podcover_can_suck

=cut
