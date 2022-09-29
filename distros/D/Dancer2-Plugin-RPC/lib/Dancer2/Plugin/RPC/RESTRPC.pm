package Dancer2::Plugin::RPC::RESTRPC;
use Moo;
use Dancer2::Plugin;

with 'Dancer2::RPCPlugin';

our $VERSION = '2.00';
use constant PLUGIN_NAME => 'restrpc';

use Dancer2::RPCPlugin::CallbackResultFactory;
use Dancer2::RPCPlugin::ErrorResponse;
use Dancer2::RPCPlugin::FlattenData;

use JSON;
use Scalar::Util 'blessed';
use Time::HiRes 'time';

plugin_keywords PLUGIN_NAME;

sub restrpc {
    my ($plugin, $base_url, $config) = @_;

    my $dispatcher = $plugin->dispatch_builder(
        $base_url,
        $config->{publish},
        $config->{arguments},
        plugin_setting(),
    )->();

    my $lister = $plugin->partial_method_lister(
        protocol => __PACKAGE__->rpcplugin_tag,
        endpoint => $base_url,
        methods  => [ sort keys %{ $dispatcher } ],
    );

    my $code_wrapper = $plugin->code_wrapper($config);
    my $callback = $config->{callback};

    $plugin->app->log(debug => "Starting handler build: ", $lister);
    my $restrpc_handler = sub {
        my $dsl = shift;

        my $http_request = $dsl->app->request;
        my ($ct) = (split /;\s*/, $http_request->content_type, 2);
        if ($ct ne 'application/json') {
            $dsl->pass();
        }
        $dsl->app->log(
            debug => "[handle_restrpc_request] Processing: ", $http_request->body
        );
        my ($method_name) = $http_request->path =~ m{$base_url/(\w+)};

        $dsl->response->content_type('application/json');
        my $response;
        my $method_args = $http_request->body
            ? from_json($http_request->body)
            : undef;
        $dsl->app->log(debug => "[handle_restrpc_call($method_name)] ", $method_args);
        my $start_request = time();
        my Dancer2::RPCPlugin::CallbackResult $continue = eval {
            local $Dancer2::RPCPlugin::ROUTE_INFO = {
                plugin        => PLUGIN_NAME,
                endpoint      => $base_url,
                rpc_method    => $method_name,
                full_path     => $http_request->path,
                http_method   => uc($http_request->method),
            };
            $callback
                ? $callback->($http_request, $method_name, $method_args)
                : callback_success();
        };

        if (my $error = $@) {
            my $error_response = error_response(
                error_code    => 500,
                error_message => $error,
            );
            $dsl->response->status($error_response->return_status(PLUGIN_NAME));
            $response = $error_response->as_restrpc_error;
            return restrpc_response($dsl, $response);
        }
        if (!blessed($continue) || !$continue->does('Dancer2::RPCPlugin::CallbackResult')) {
            my $error_response = error_response(
                error_code    => 500,
                error_message => "Internal error: 'callback_result' wrong class "
                               . blessed($continue),
            );
            $dsl->response->status($error_response->return_status(PLUGIN_NAME));
            $response = $error_response->as_restrpc_error;
        }
        elsif (blessed($continue) && !$continue->success) {
            my $error_response = error_response(
                error_code    => $continue->error_code,
                error_message => $continue->error_message,
            );
            $dsl->response->status($error_response->return_status(PLUGIN_NAME));
            $response = $error_response->as_restrpc_error;
        }
        else {
            my $di = $dispatcher->{$method_name};
            my $handler = $di->code;
            my $package = $di->package;

            $response = eval {
                $code_wrapper->($handler, $package, $method_name, $method_args);
            };
            my $error = $@;

            $dsl->app->log(debug => "[handled_restrpc_response($method_name)] ", $response);
            $dsl->app->log(
                info => sprintf(
                    "[RPC::RESTRPC] request for '%s' took %.4fs",
                    $method_name, time() - $start_request
                )
            );
            if ($error) {
                $response = Dancer2::RPCPlugin::ErrorResponse->new(
                    error_code => 500,
                    error_message => $error,
                )->as_restrpc_error;
            }
            if (blessed($response) && $response->can('as_restrpc_error')) {
                $response = $response->as_restrpc_error;
            }
            elsif (blessed($response)) {
                $response = flatten_data($response);
            }
        }

        return restrpc_response($dsl, $response);
    };

    for my $call (keys %{ $dispatcher }) {
        my $endpoint = "$base_url/$call";
        $plugin->app->log(debug => "setting route (restrpc): $endpoint ", $lister);
        $plugin->app->add_route(
            method => 'post',
            regexp => $endpoint,
            code   => $restrpc_handler,
        );
    }
}

sub restrpc_response {
    my ($dsl, $data) = @_;

    my $jsonise_options = {canonical => 1};
    if ($dsl->config->{encoding} && $dsl->config->{encoding} =~ m{^utf-?8$}i) {
        $jsonise_options->{utf8} = 1;
    }

    $data = { RESULT => $data } if !ref($data);
    my $response = to_json($data, $jsonise_options);
    $dsl->app->log(debug => "[restrpc_response] ", $response);
    return $response;
}

use namespace::autoclean;
1;

__END__

=head1 NAME

Dancer2::Plugin::RPC::REST - RESTRPC Plugin for Dancer

=head2 SYNOPSIS

In the Controler-bit:

    use Dancer2::Plugin::RPC::REST;
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

    my Dancer2::RPCPlugin::CallbackResult $continue = $callback
        ? $callback->(request(), $method_name, @method_args)
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
        'admin_someFuncion' => Dancer2::RPCPlugin::DispatchItem->new(
            package => 'MyProject::Admin',
            code    => MyProject::Admin->can('rpc_admin_some_function_name'),
        ),
        'user_otherFunction' => Dancer2::RPCPlugin::DispatchItem->new(
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

=head2 restrpc_response

Creates a cannonical-JSON response.

=begin pod_coverage

=head2 PLUGIN_NAME

=end pod_coverage

=head1 COPYRIGHT

E<copy> MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
