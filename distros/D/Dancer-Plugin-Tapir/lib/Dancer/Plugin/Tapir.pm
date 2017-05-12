package Dancer::Plugin::Tapir;

use Dancer ':syntax';
use Dancer::Plugin;
use Carp;
use Try::Tiny;
use Capture::Tiny qw(capture);
use JSON::XS qw();
use Scalar::Util qw(blessed);
use File::Spec;

# POE sessions will be created by Tapir::MethodCall; let's not see an error about POE never running
use POE;
POE::Kernel->run();

use Thrift::IDL;
use Thrift::Parser;
use Tapir::Validator;
use Tapir::MethodCall;
use Tapir::Documentation::NaturalDocs;

my $json_xs = JSON::XS->new->allow_nonref->allow_blessed;

our $VERSION = 0.05;

register setup_tapir_documentation => sub {
    my ($self, @args) = plugin_args(@_);
    # $self is undef for Dancer 1
    my $conf = plugin_setting();
    my %conf = ( %$conf, @args );

    ## Validate the plugin settings

    if (my @missing_args = grep { ! defined $conf{$_} } qw(thrift_idl path documentation_staging_dir)) {
        croak "Missing configuration settings for setup_tapir_docs: " . join('; ', @missing_args);
    }
    if (! $conf{naturaldocs_bin}) {
        $conf{naturaldocs_bin} = which('NaturalDocs');
        chomp $conf{naturaldocs_bin};
        if (! $conf{naturaldocs_bin}) {
            croak "You must pass 'naturaldocs_bin' to indicate where the binary NaturalDocs is";
        }
    }

    my $output_dir = File::Spec->catdir($conf{documentation_staging_dir}, 'output');

    print "Building documentation to $output_dir\n";
    Tapir::Documentation::NaturalDocs->build(
        input_fn        => $conf{thrift_idl},
        temp_dir        => File::Spec->catdir($conf{documentation_staging_dir}, 'temp'),
        output_dir      => $output_dir,
        naturaldocs_bin => $conf{naturaldocs_bin},
    );

    get "$conf{path}**" => sub {
        my ($files) = splat;
        my $file = join '/', @$files;
        if (! length $file) {
            $file = 'index.html';
        }
        my $path = File::Spec->catfile($output_dir, $file);
        info "Serving $path";
        return send_file($path, system_path => 1);
    };
};

register setup_tapir_handler => sub {
    my ($self, @args) = plugin_args(@_);
    # $self is undef for Dancer 1
    my $conf = plugin_setting();
    my %conf = ( %$conf, @args );

    ## Validate the plugin settings

    if (my @missing_args = grep { ! defined $conf{$_} } qw(thrift_idl handler_class)) {
        croak "Missing configuration settings for Tapir plugin: " . join('; ', @missing_args);
    }
    if (! -f $conf{thrift_idl}) {
        croak "Invalid thrift_idl file '$conf{thrift_idl}'";
    }

    ## Audit the IDL

    my $idl = Thrift::IDL->parse_thrift_file($conf{thrift_idl});

    # Conduct an audit of the thrift document to ensure that all the methods are
    # documented, have a @rest declaration, and all custom types are defined before
    # being used.  Further, this will fill in the $object->{doc} hash for each
    # Thrfit::IDL object, which is necessary for validate_parser_message as well as
    # extracting the @rest values later.

    my $validator = Tapir::Validator->new(
        audit_types => 1,
        docs => {
            require => {
                methods => 1,
                rest    => 1,
            },
        },
    );
    if (my @errors = $validator->audit_idl_document($idl)) {
        croak "Invalid thrift_idl file '$conf{thrift_idl}'; the following errors were found:\n"
            . join("\n", map { " - $_" } @errors);
    }

    my %services = map { $_->name => $_ } @{ $idl->services };

    ## Use the handler class and test for completeness

    my $handler_class = $conf{handler_class};
    eval "require $handler_class";
    if ($@) {
        croak "Failed to load $handler_class: $@";
    }
    if (! $handler_class->isa('Tapir::Server::Handler::Class')) {
        croak "$handler_class must be a subclass of Tapir::Server::Handler::Class";
    }

    if (! $handler_class->service) {
        croak "$handler_class didn't call service()";
    }
    my $service = $services{ $handler_class->service };
    if (! $service) {
        croak "$handler_class is for the service ".$handler_class->service.", which is not registered with $conf{thrift_idl}";
    }

    my %methods = map { $_->name => $_ } @{ $service->methods };
    my %handled_methods = %{ $handler_class->methods };
    foreach my $method_name (keys %methods) {
        if (! $handled_methods{$method_name}) {
            croak "$handler_class doesn't handle method $methods{$method_name}";
        }
    }

    ## Setup custom namespaced Thrift classes

    my $parser = Thrift::Parser->new(idl => $idl, service => $service->name);

    ## Setup routes

    my $logger = Dancer::LoggerMockObject->new();

    while (my ($method_name, $method_idl) = each %methods) {
        my ($http_method, $dancer_route) = @{ $method_idl->{doc}{rest} }{'method', 'route'};
        $dancer_route =~ s/\s+$//; # FIXME: There shouldn't be whitespace at the end of the route
        my $dancer_method = 'Dancer::' . $http_method;

        my $method_message_class = $parser->{methods}{$method_name}{class};

        my $dancer_sub = sub {

        ## Create a method call from the Dancer request

            my $request = request;
            my $params = $request->params;

            # Decode the JSON payload
            if ($request->content_length && $request->content_type && $request->content_type eq 'application/json' && length $request->body) {
                my $body = try {
                    $json_xs->decode($request->body)
                }
                catch {
                    print STDERR "JSON payload was:\n" . $request->body . "\n";
                    die "Error in decoding the JSON payload (length " . $request->content_length . "): $_";
                };
                die unless $body && ref $body && ref $body eq 'HASH';
                $params->{$_} = $body->{$_} foreach keys %$body;
            }
            else {
                # Allow the user to pass "?$json_string" in query string
                my @params = $request->params('query');
                if (int @params == 2 && $params[1] eq '') {
                    my $query_json = try {
                        $json_xs->decode($params[0]);
                    };
                    if ($query_json) {
                        delete $params->{ $params[0] };
                        $params->{$_} = $query_json->{$_} foreach keys %$query_json;
                    }
                }
            }

            my $thrift_message;
            try {
                $thrift_message = $method_message_class->compose_message_call(%$params);
            }
            catch {
                my $ex = $_;
                if (ref $ex && blessed $ex && $ex->isa('Exception::Class::Base')) {
                    if ($ex->isa('Thrift::Parser::InvalidArgument')) {
                        $ex->rethrow();
                    }
                }
                die "Error in composing $method_message_class message: $_\n";
            };

            $validator->validate_parser_message($thrift_message);

            my $call = Tapir::MethodCall->new(
                service   => $service,
                message   => $thrift_message,
                transport => $request,
                logger    => $logger,
            );

        ## Pass call to handler class and inspect result

            # Ask the handler class to add one or more action to the call object
            $handler_class->add_call_actions($call);

            # We can't check is_finished since that's only set via a POE post; check instead to see
            # if the action called set_result, set_exception or set_error
            my $call_is_finished_sub = sub {
                my @set = grep { $call->heap_isset($_) } qw(result exception error);
                return $set[0];
            };

            my $run_call_actions_sub = sub {
                # Execute the actions until one of them calls set_result, set_exception or set_error
                while (my $action = $call->get_next_action) {
                    $action->($call);
                    last if $call_is_finished_sub->();
                }
            };

            # Wrap the call in a Capture::Tiny so that we can send STDOUT and STDERR to Dancer
            my ($stdout, $stderr) = capture { $run_call_actions_sub->() };
            foreach ([ info => $stdout ], [ error => $stderr ]) {
                my ($level, $string) = @$_;
                next unless $string;
                foreach my $line (split /\n/, $string) {
                    $logger->$level($handler_class.' in handling '.$call->method->name.' emitted: '.$line);
                }
            }

            # Figure out if the handler set result, error or exception and fetch the value
            my $result_key = $call_is_finished_sub->();
            if (! $result_key) {
                die $handler_class.' in handling '.$call->method->name." never called set_result, set_exception or set_error\n";
            }
            my $result_value = $call->heap_index($result_key);

            # The handler can communicate with us via 'rest_result' in the heap.  If set, use this to send
            # extra headers or override our default status code
            my $status;
            if (my $extra_actions = $call->heap_index('rest_result')) {
                if (my $code = $extra_actions->{status_code}) {
                    $status = $code;
                }
                if (my $headers = $extra_actions->{headers}) {
                    headers %$headers;
                }
            }

        ## Setup the response and return

            # The handler set result.  Validate the result value against the Thrift specification, and return
            # it encoded in JSON.
            my $response;
            if ($result_key eq 'result') {
                try {
                    # Compose a reply to the method using the result value.  This will throw if any values are
                    # missing or not valid for the specification.  This returns a Thrift::Parser::Message which
                    # contains the reply as a field set keyed on 'return_value'.  Let's turn that into JSON.
                    my $thrift_reply = $thrift_message->compose_reply($result_value);
                    $response = Tapir::MethodCall::dereference_fieldset($thrift_reply->arguments, { plain => 1 });
                    $response = $json_xs->encode($response->{return_value});
                }
                catch {
                    die "Error in composing $method_message_class result: $_\n";
                };
                $status ||= 200;
            }
            # The handler set either 'error' or 'exception'; return a status 500 with a JSON payload describing the problem
            else {
                $status ||= 500;
                $response = $json_xs->encode({ $result_key => $result_value });
            }

            header 'content-type' => 'application/json';
            status $status;
            return $response;
        };

        my $wrapper_sub = sub {
            my $result;
            try {
                $result = $dancer_sub->(@_);
            }
            catch {
                my $ex = $_;
                my $status = 'error';
                if (ref $ex && blessed $ex && $ex->isa('Exception::Class::Base')) {
                    my $string_error;
                    if ($ex->isa('Tapir::InvalidArgument') || $ex->isa('Thrift::Parser::InvalidArgument')) {
                        $status = 400;
                        if ($ex->key && $ex->value) {
                            $string_error = sprintf "The argument '%s' ('%s') was invalid: %s", $ex->key, $ex->value, $ex->error;
                        }
                        elsif ($ex->key) {
                            $string_error = sprintf "The argument '%s' was invalid: %s", $ex->key, $ex->error;
                        }
                        else {
                            $string_error = sprintf "There was an invalid argument: %s", $ex->error;
                        }
                    }
                    else {
                        # Look for a stack trace frame that is not Thrift::Parser so we can see
                        # any thrift-related errors from the perspective of the caller
                        my ($trace_frame, $first_frame);
                        while (my $frame = $ex->trace->next_frame) {
                            $first_frame ||= $frame;
                            next if $frame->package =~ m{^Thrift};
                            $trace_frame = $frame;
                            last;
                        }
                        $trace_frame ||= $first_frame;

                        $string_error = $ex->error . " in " . $trace_frame->as_string;
                    }
                    $logger->error($string_error);
                    $result = $json_xs->encode({
                        error => $string_error,
                    });
                }
                else {
                    $logger->error("$ex");
                    $result = $json_xs->encode({ exception => "$ex" });
                }
                header 'content-type' => 'application/json';
                status $status;
            };

            # Returning the result will print it to the HTTP response
            return $result;
        };

        # Install the route
        {
            no strict 'refs';
            $dancer_method->($dancer_route => $wrapper_sub);
        }
    }
};

register_plugin;

sub which {
    my ($bin) = @_;
    foreach my $path (split /:/, $ENV{PATH}) {
        my $possible_path = File::Spec->catfile($path, $bin);
        return $possible_path if -x $possible_path;
    }
    return;
}

{
    package Dancer::LoggerMockObject;

    use strict;
    use warnings;

    sub new {
        my $class = shift;
        return bless {}, $class;
    }

    sub core    { shift; Dancer::Logger::core(@_); }
    sub debug   { shift; Dancer::Logger::debug(@_); }
    sub warning { shift; Dancer::Logger::warning(@_); }
    sub error   { shift; Dancer::Logger::error(@_); }
    sub info    { shift; Dancer::Logger::info(@_); }
}

=head1 NAME

Dancer::Plugin::Tapir - Associate a Tapir handler with Dancer routes

=head1 SYNOPSIS

  use Dancer;
  use Dancer::Plugin::Tapir;

  setup_tapir_handler
    thrift_idl    => 'thrift/service.thrift',
    handler_class => 'MyAPI::Service';

=head1 DESCRIPTION

The goal of this package is to quickly and without fuss expose a L<Tapir> service via L<Dancer> via a RESTful API.  Doing so requires no additional coding, and only requires a simple comment added to your Thrift methods.

This plugin exports the method C<setup_tapir_handler> into the caller.  Call it with either a list of arguments or using your Dancer configuration (see below).

The handler class must be a subclass of L<Tapir::Server::Handler::Class> and have registered methods for each Thrift method of the Thrift service.

The Dancer routes that will be exposed match up with the C<@rest> Thrift documentation tag.  For example:

  /*
    Create a new account
    @rest POST /accounts
  */
  account createAccount (
    1: username username,
    2: string   password
  )

This will create a route C<POST /accounts> which will call the method C<createAccount> in the handler class.  The Dancer method C<params> will be used to extract both query string and payload parameters, and will be used to compose the thrift message passed to the L<Tapir::Server::Handler>.

Control over the HTTP status code returned to the user is still being worked out, as are being able to set headers in the HTTP response.  At the moment, the result is serialized via JSON but will in the future be serialized according to the Accept headers of the request.

=head1 CONFIGURATION

Add something like this to your YAML config:

  plugins:
    Tapir:
      thrift_idl: thrift/service.thrift
      handler_class: MyAPI::Service

=head1 SEE ALSO

L<Tapir>, L<Dancer>

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under the same terms as Perl itself

=head1 COPYRIGHT

Copyright (c) 2012 Eric Waters.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

true;
