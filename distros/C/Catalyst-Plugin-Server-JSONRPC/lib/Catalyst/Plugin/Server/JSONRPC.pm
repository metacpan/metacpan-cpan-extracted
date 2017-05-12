
=head1 NAME

Catalyst::Plugin::Server::JSONRPC -- Catalyst JSONRPC Server Plugin

=head1 SYNOPSIS

    package MyApp;
    use Catalyst qw/Server Server::JSONRPC/;

    package MyApp::Controller::Example;
    use base 'Catalyst::Controller';

    sub echo : JSONRPC {                     # available as: example.echo
        my ( $self, $c, @args ) = @_;
        $c->stash->{jsonrpc} = join ', ', @args;
    }

    sub ping : JSONRPCPath('/ping') {        # available as: ping
        my ( $self, $c ) = @_;
        $c->stash->{jsonrpc} = 'Pong';
    }

    sub world : JSONRPCRegex(/hello/) {      # available as: *hello*
        my ($self, $c) = @_;
        $c->stash->{jsonrpc} = 'World';
    }

    sub echo : JSONRPCLocal {                # available as: example.echo
        my ( $self, $c, @args ) = @_;
        $c->stash->{jsonrpc} = join ', ', @args;
    }

    sub ping : JSONRPCGlobal {               # available as: ping
        my ( $self, $c ) = @_;
        $c->stash->{jsonrpc} = 'Pong';
    }

=head1 DESCRIPTION

JSONRPC Plugin for Catalyst which we tried to make compatible with the
way Catalyst works with URLS. Main features are:

=over 4

=item * Split JSONRPC methodNames by STRING to find out Controller.

=item * Single entrypoint for JSONRPC calls, like http://host.tld/rpc

=item * DispatchTypes (attributes) which work much the same as Catalyst attrs

=item * JSONRPC Parameter handling transparent to Catalyst parameter handling

=back

=head1 HOW IT WORKS

The default behaviour will handle JSONRPC Requests sent to C</rpc> by creating
an OBJECT containing JSONRPC specific parameters in C<< $c->req->jsonrpc >>.

Directly after, it will find out the Path of the Action to dispatch to, by
splitting methodName by C<.>:

  methodName: hello.world
  path      : /hello/world

From this point, it will dispatch to '/hello/world' when it exists,
like Catalyst Urls would do. What means: you will be able to set Regexes,
Paths etc on subroutines to define the endpoint.

We discuss these custom JSONRPC attributes below.

When the request is dispatched, we will return $c->stash->{jsonrpc} to the
jsonrpc client, or, when it is not available, it will return $c->stash to
the client. There is also a way of defining $c->stash keys to be send back
to the client.

=head1 ATTRIBUTES

You can mark any method in your Catalyst application as being
available remotely by using one of the following attributes,
which can be added to any existing attributes, except Private.
Remember that one of the mentioned attributes below are automatically
also Privates...

=over 4

=item JSONRPC

Make this method accessible via JSONRPC, the same way as Local does
when using catalyst by URL.

The following example will be accessible by method C<< hello.world >>:

  package Catalyst::Controller::Hello
  sub world : JSONRPC {}

=item JSONRPCLocal

Identical version of attribute C<JSONRPC>

=item JSONRPCGlobal

Make this method accessible via JSONRPC, the same way as GLOBAL does
when using catalyst by URL.

The following example will be accessible by method C<< ping >>:

  package Catalyst::Controller::Hello
  sub ping : JSONRPCGlobal {}

=item JSONRPCPath('/say/hello')

Make this method accessible via JSONRPC, the same way as Path does
when using catalyst by URL.

The following example will be accessible by method C<< say.hello >>:

  package Catalyst::Controller::Hello
  sub hello : JSONRPCPath('/say/hello') {}

=item JSONRPCRegex('foo')

Make this method accessible via JSONRPC, the same way as Regex does
when using catalyst by URL.

The following example will be accessible by example methods:
C<< a.foo.method >>
C<< wedoofoohere >>
C<< foo.getaround >>

  package Catalyst::Controller::Hello
  sub hello : JSONRPCPath('foo') {}

=back

=head1 ACCESSORS

Once you've used the plugin, you'll have an $c->request->jsonrpc accessor
which will return an C<Catalyst::Plugin::Server::JSONRPC> object.

You can query this object as follows:

=over 4

=item $c->req->jsonrpc->is_jsonrpc_request

Boolean indicating whether the current request has been initiated
via JSONRPC

=item $c->req->jsonrpc->config

Returns a C<Catalyst::Plugin::Server::JSONRPC::Config> object. See the 
C<CONFIGURATION> below on how to use and configure it.

=item $c->req->jsonrpc->body

The body of the original JSONRPC call

=item $c->req->jsonrpc->method

The name of the original method called via JSONRPC

=item $c->req->jsonrpc->args

A list of parameters supplied by the JSONRPC call

=item $c->req->jsonrpc->result_as_string

The JSON body that will be sent back to the JSONRPC client

=item $c->req->jsonrpc->error

Allows you to set jsonrpc fault code and message

=back

=head1 Server Accessors

The following accessors are always available, whether you're in a jsonrpc
specific request or not

=over 4

=item $c->server->jsonrpc->list_methods

Returns a HASHREF containing the available jsonrpc methods in Catalyst as
a key, and the C<Catalyst::Action> object as a value.

=back

=head1 CATALYST REQUEST

To make things transparent, we try to put JSONRPC params into the Request
object of Catalyst. But first we will explain something about the JSONRPC
specifications.

A full draft of these specifications can be found on:
C<http://www.jsonrpc.com/spec>

In short, a jsonrpc-request consists of a methodName, like a subroutine
name, and a list of parameters. This list of parameters may contain strings
(STRING), arrays (LIST) and structs (HASH). Off course, these can be nested.

=over 4

=item $c->req->arguments

We will put the list of arguments into $c->req->arguments, thisway you can
fetch this list within your dispatched-to-subroutine:

  sub echo : JSONRPC {
      my ($self, $c, @args) = @_;
      $c->log->debug($arg[0]);              # Prints first JSONRPC parameter
                                            # to debug log
  }

=item $c->req->parameters

Because JSONRPC parameters are a LIST, we can't B<just> fill
$c->req->paremeters. To keep things transparent, we made an extra config
option what tells the JSONRPC server we can assume the following conditions
on all JSONRPC requests:
- There is only one JSONRPC parameter
- This JSONRPC parameter is a struct (HASH)

We will put this STRUCT as key-value pairs into $c->req->parameters.

=item $c->req->params

Alias of $c->req->parameters

=item $c->req->param

Alias of $c->req->parameters

=back

=cut

{

    package Catalyst::Plugin::Server::JSONRPC;

    our $VERSION = "0.07";

    use strict;
    use warnings;
    use attributes ();

    use Data::Dumper;
    use JSON::RPC::Common::Procedure::Return;
    use JSON::RPC::Common::Marshal::HTTP;
    use MRO::Compat;

    my $ServerClass = 'Catalyst::Plugin::Server::JSONRPC::Backend';

    ### only for development dumps!
    my $Debug = 0;

    ###
    ### Catalyst loading and dispatching
    ###

    ### Loads our jsonrpc backend class in $c->server->jsonrpc
    sub setup_engine {
        my $class = shift;
        $class->server->register_server( 'jsonrpc' => $ServerClass->new($class) );
        $class->next::method(@_);
    }
    
    sub setup {
        my $class = shift;
        ### config is not yet loaded on setup_engine so load it here
        $class->server->jsonrpc->config( Catalyst::Plugin::Server::JSONRPC::Config->new($class) );
        $class->next::method(@_);
    }
    
    ### Will load our customized DispatchTypes into Catalyst
    sub setup_dispatcher {
        my $class = shift;
        ### Load custom DispatchTypes
        $class->next::method(@_);
        $class->dispatcher->preload_dispatch_types(
            @{ $class->dispatcher->preload_dispatch_types },
            qw/ +Catalyst::Plugin::Server::JSONRPC::DispatchType::JSONRPCPath
              +Catalyst::Plugin::Server::JSONRPC::DispatchType::JSONRPCRegex/
        );

        return $class;
    }

    ### Loads the jsonrpc-server object, redispatch to the method
    sub prepare_action {
        my $c    = shift;
        my @args = @_;

        ### set up the accessor to hold an jsonrpc server instance
        $c->req->register_server( 'jsonrpc' => Catalyst::Plugin::Server::JSONRPC::Request->new() );

        ### are we an jsonrpc call? check the path against a regex
        my $path = $c->server->jsonrpc->config->path;
        if ( $c->req->path =~ /$path/ ) {

          PREPARE: {
                ### mark us as an jsonrpc request
                $c->req->jsonrpc->is_jsonrpc_request(1);

                $c->stash->{current_view_instance} = $c->server->jsonrpc->view_instance;

                $c->log->debug( 'PREPARE WITH $c ' . Dumper($c) ) if $Debug;

                $c->req->jsonrpc->_deserialize_json($c) or last PREPARE;

                ### CAVEAT: we consider backing up to a default for a
                ### json-rpc method when the method doesn't exist a security
                ### risk. So when the exact method doesn't exist, we return
                ### an error.
                ### TODO ARGH Because of regex methods, this won't work

                ### set the new request path, the one we will forward to
                $c->req->path( $c->req->jsonrpc->forward_path );

                ### filter change dispatch types to our OWN
                {
                    my $saved_dt = $c->dispatcher->dispatch_types || [];
                    my $dp_ns    = 'Catalyst::Plugin::Server::JSONRPC::DispatchType::';

                    $c->dispatcher->dispatch_types(
                        [
                            grep {
                                     UNIVERSAL::isa( $_, $dp_ns . 'JSONRPCPath' )
                                  or UNIVERSAL::isa( $_, $dp_ns . 'JSONRPCRegex' )
                              } @$saved_dt
                        ]
                    );

                    ### run the rest of the prepare actions, we should have
                    ### an action object now
                    $c->next::method(@_);

                    ### restore the saved dispatchtypes
                    $c->dispatcher->dispatch_types($saved_dt);
                }

                ### check if we have a c->action now
                ### check if the NEW action isn't hte same as the
                ### OLD action -- which mean no method was found
                ### Not needed, don't have an action until we NEXT
                if ( ( not $c->action )
                    && !$c->server->jsonrpc->private_methods->{ $c->req->jsonrpc->method } )
                {
                    $c->req->jsonrpc->_error( $c, qq[Invalid JSONRPC request: No such method] );
                    last PREPARE;
                }
            }

            ### JSONRPC parameters and argument processing, see the Request
            ### class below for information why we can't do it there.
            $c->req->parameters( $c->req->jsonrpc->params )
              if $c->server->jsonrpc->config->convert_params;

            $c->req->args( $c->req->jsonrpc->args );

            ### we're no jsonrpc request, so just let others handle it
        } else {
            $c->next::method(@_);
        }
    }

    ### before we dispatch, make sure no jsonrpc errors have happened already,
    ### or an internal method has been called.
    sub dispatch {
        my $c = shift;
        if ( $c->req->jsonrpc->is_jsonrpc_request
            and scalar( @{ $c->error } ) )
        {
            1;
        } elsif ( $c->req->jsonrpc->is_jsonrpc_request
            and $c->server->jsonrpc->private_methods->{ $c->req->jsonrpc->method } )
        {
            $c->req->jsonrpc->run_method($c);
        } else {
            $c->next::method(@_);
        }
    }

    sub finalize {
        my $c = shift;

        if ( $c->req->jsonrpc->is_jsonrpc_request ) {

            #XXX if they skipped Catalust::View::JSONRPC - run it

            $c->stash->{current_view_instance}->process($c) unless $c->stash->{jsonrpc_generated};

            #drop all errors;
            $c->error(0);
        }
        $c->log->debug( 'FINALIZE ' . Dumper( $c, \@_ ) ) if $Debug;

        ### always call finalize at the end, so Catalyst's final handler
        ### gets called as well
        $c->next::method(@_);

    }

}

### The server implementation
{

    package Catalyst::Plugin::Server::JSONRPC::Backend;

    use base qw/Class::Accessor::Fast/;
    use Data::Dumper;

    __PACKAGE__->mk_accessors(
        qw/
          dispatcher
          private_methods
          c
          config
          view_instance
          /
    );

    sub new {
        my $class = shift;
        my $c     = shift;
        my $self  = $class->SUPER::new(@_);

        $self->c($c);
        ### config is not yet loaded on setup_engine
        #$self->config( Catalyst::Plugin::Server::JSONRPC::Config->new($c) );
        $self->private_methods( {} );
        $self->dispatcher(      {} );
        $self->view_instance( Catalyst::View::JSONRPC->new );

        ### Internal function
        $self->add_private_method(
            'system.listMethods' => sub {
                my ( $c_ob, @args ) = @_;
                return [
                    keys %{
                        $c_ob->server->jsonrpc->list_methods;
                      }
                ];
            }
        );

        return $self;
    }

    sub add_private_method {
        my ( $self, $name, $sub ) = @_;

        return unless ( $name && UNIVERSAL::isa( $sub, 'CODE' ) );
        $self->private_methods->{$name} = $sub;
        return 1;
    }

    sub list_methods {
        my ($self) = @_;
        return $self->dispatcher->{Path}->methods( $self->c );
    }
}

### the config implementation ###
{

    package Catalyst::Plugin::Server::JSONRPC::Config;
    use base 'Class::Accessor::Fast';

    ### XXX change me to an ENTRYPOINT!
    my $DefaultPath       = qr!^(/?)rpc(/|$)!i;
    my $DefaultAttr       = 'JSONRPC';
    my $DefaultPrefix     = '';
    my $DefaultSep        = '.';
    my $DefaultShowErrors = 0;

    ### XXX add: stash_fields (to encode) stash_exclude_fields (grep -v)

    __PACKAGE__->mk_accessors(
        qw/ path prefix separator attribute convert_params
          show_errors
          /
    );

    ### return the cached version where possible
    my $Obj;

    sub new {
        return $Obj if $Obj;

        my $class = shift;
        my $c     = shift;
        my $self  = $class->SUPER::new;

        $self->prefix( $c->config->{jsonrpc}->{prefix}           || $DefaultPrefix );
        $self->separator( $c->config->{jsonrpc}->{separator}     || $DefaultSep );
        $self->path( $c->config->{jsonrpc}->{path}               || $DefaultPath );
        $self->show_errors( $c->config->{jsonrpc}->{show_errors} || $DefaultShowErrors );
        $self->attribute($DefaultAttr);
        $self->convert_params(1);

        ### cache it
        return $Obj = $self;
    }
}

### the server class implementation ###
{

    package Catalyst::Plugin::Server::JSONRPC::Request;

    use strict;
    use warnings;

    use JSON::RPC::Common::Marshal::Catalyst;
    use JSON::RPC::Common::Procedure::Call;
    use JSON::RPC::Common::Procedure::Return;

    use Data::Dumper;
    use Text::SimpleTable;

    use base 'Class::Data::Inheritable';
    use base 'Class::Accessor::Fast';

    __PACKAGE__->mk_accessors(
        qw[  forward_path method result args body
          is_jsonrpc_request params
          result_as_string internal_methods error
          ]
    );

    __PACKAGE__->mk_classdata(qw[_jsonrpc_parser]);
    __PACKAGE__->mk_classdata(qw[call]);
    __PACKAGE__->_jsonrpc_parser( JSON::RPC::Common::Marshal::Catalyst->new );

    *parameters = *params;

    sub run_method {
        my ( $self, $c, @args ) = @_;

        $c->stash->{jsonrpc} =
          &{ $c->server->jsonrpc->private_methods->{ $self->method } }( $c, $self->call->params_list, @args );

    }

    sub _deserialize_json {
        my ( $self, $c ) = @_;

        ### the parser will die on failure, make sure we catch it
        my $call;
        eval { $call = $self->_jsonrpc_parser->request_to_call( $c->req ); };
        ### parsing the request went fine
        if ( not $@ and defined $call->method ) {

            $self->call($call);                                            # original json call
            $self->method( $call->method );                                # name of the method
            $self->body( $self->_jsonrpc_parser->call_to_json($call) );    #

            ### allow the args to be encoded as a HASH when requested
            ### jsonrpc only knows a top level 'list', and we can not tell
            ### if that is meant to be a hash or not
            ### make sure to store args as an ARRAY REF! to be compatible
            ### with catalyst

            my $p = $call->params;

            if ( ref $p eq 'HASH' ) {
                $self->params($p);
                $self->args(%$p);                                          # parsed arguments
            } elsif ( ref $p eq 'ARRAY' ) {
                $self->args($p);                                           # parsed arguments
                $self->params( {} );
            } else {
                $self->args( [] );
                $self->params( {} );
            }

            ### build the relevant namespace, action and path
            {    ### construct the forward path -- this allows catalyst to
                ### do the hard work of dispatching for us
                my $prefix = $c->server->jsonrpc->config->prefix;
                my ($sep) = map { qr/$_/ }
                  map { quotemeta $_ } $c->server->jsonrpc->config->separator;

                ### error checks here
                if ( $prefix =~ m|^/| ) {
                    $c->log->debug( __PACKAGE__ . ": Your prefix starts with" . " a / -- This is not recommended" )
                      if $c->debug;
                }

                unless ( UNIVERSAL::isa( $sep, 'Regexp' ) ) {
                    $c->log->debug( __PACKAGE__ . ": Your separator is not a " . "Regexp object -- This is not recommended" )
                      if $c->debug;
                }

                ### foo.bar => $prefix/foo/bar
                ### DO NOT add a leading slash! uri.pm gets very upset
                my @parts = split( $sep, $self->method );
                my $fwd_path = join '/', grep { defined && length } $prefix, @parts;

                ### Complete our object-instance
                $self->forward_path($fwd_path);

                ### Notify system of called rpc method and arguments
                $c->log->debug( 'JSON-RPC: Method called: ' . $self->method )
                  if $c->debug;
                if (   $c->server->jsonrpc->config->convert_params
                    && $self->params )
                {
                    my $params = Text::SimpleTable->new( [ 36, 'Key' ], [ 37, 'Value' ] );
                    foreach my $key ( sort keys %{ $self->params } ) {
                        my $value = $self->params->{$key};
                        $value = ref($value) || $value;
                        $params->row( $key, $value );
                    }
                    $c->log->debug( "JSON-RPC: Parameters:\n" . $params->draw )
                      if ( $c->debug && %{ $self->params } );
                }
            }

            ### an error in parsing the request
        } elsif ($@) {
            $self->_error( $c, qq[Invalid JSONRPC request "$@"] );
            return;

            ### something is wrong, but who knows what...
        } else {
            $self->_error( $c, qq[Invalid JSONRPC request: Unknown error] );
            return;
        }

        return $self;
    }

    ### alias arguments to args
    *arguments = *args;

    ### record errors in the error and debug log -- just for convenience
    sub _error {
        my ( $self, $c, $msg ) = @_;
        $c->log->debug($msg) if $c->debug;
        $c->error($msg);
    }
}

{

    package Catalyst::View::JSONRPC;

    use strict;
    use warnings;

    use base 'Catalyst::View';

    sub process {
        my $self = shift;
        my $c    = $_[0];
        ### if we got an error anywhere, we'll return a fault
        ### othwerise, the resultset will be returned
        ### XXX $c->error
        my $res;
        my $req_error = $c->req->jsonrpc->error;
        my $error;
        my $ecode = 200;
        if ( $req_error || scalar( @{ $c->error } ) ) {
            if ( $c->server->jsonrpc->config->show_errors ) {
                if ( $req_error && ref $req_error eq 'ARRAY' ) {
                    ( $ecode, $error ) = @{$req_error};
                } else {
                    $error = join $/, @{ $c->error };
                }
            } else {
                $c->log->debug( "JSONRPC 500 Errors:\n" . join( "\n", @{ $c->error } ) );
                $error = 'Internal Server Error';
                $ecode = 500;
            }
        } else {
            if ( exists $c->stash->{jsonrpc} ) {
                $res = $c->stash->{jsonrpc};
            } elsif ( $c->res->body ) {
                $res = $c->res->body;
            } else {
                $res = $c->stash;
                delete $res->{current_view_instance};
            }
            $c->res->body(undef);

        }
        use Data::Dumper;

        my $result;
        if ($error) {
            if ( $c->req->jsonrpc->call ) {
                ### XXX play with return error due to possible return_error bug
                ### in JSON::RPC::Common:Return::Error
                my $class = $c->req->jsonrpc->call->error_class;
                my $err   = $class->new(
                    version => $c->req->jsonrpc->call->version,
                    message => $error,
                    code    => $ecode,
                );
                $result = $c->req->jsonrpc->call->return_error($err);
            } else {
                die "ERROR: " . $error;
            }
        } else {
            $result = $c->req->jsonrpc->call->return_result($res);
        }

        #my $writer = JSON::RPC::Common::Marshal::HTTP->new();
        $c->req->jsonrpc->_jsonrpc_parser->write_result_to_response( $result, $c->res );
        $c->res->status(200) if $c->server->jsonrpc->config->show_errors;
        ### make sure to clear the error, so catalyst doesn't try
        ### to deal with it
        $c->stash->{jsonrpc_generated} = 1;
        $c->error(0);
    }
}
1;

__END__

=head1 INTERNAL JSONRPC FUNCTIONS

The following system functions are available to the public.,

=over 4

=item system.listMethods

returns a list of available RPC methods.

=back

=head1 DEFINING RETURN VALUES

The JSON-RPC response must contain a single parameter, which may contain
an array (LIST), struct (HASH) or a string (STRING). To define the return
values in your subroutine, you can alter $c->stash in three different ways.

=head2 Defining $c->stash->{jsonrpc}

When defining $c->stash->{jsonrpc}, the JSONRPC server will return these values
to the client.

=head2 When there is no $c->stash->{jsonrpc}

When there is no C<< $c->stash->{jsonrpc} >> set, it will return the complete
C<< $c->stash >>

=head1 CONFIGURATION

The JSONRPC Plugin accepts the following configuration options, which can
be set in the standard Catalyst way (See C<perldoc Catalyst> for details):

    Your::App->config( jsonrpc => { key => value } );

You can look up any of the config parameters this package uses at runtime
by calling:

    $c->server->jsonrpc->config->KEY

=over 4

=item path

This specifies the entry point for your jsonrpc server; all requests are
dispatched from there. This is the url any JSONRCP client should post to.
You can change this to any C<Regex> wish.

The default is: C<qr!^(/?)rpc(/|$)!i>, which matches on a top-level path
begining with C<rpc> preceeded or followed by an optional C</>, like this:

    http://your-host.tld/rpc

=item prefix

This specifies the prefix of the forward url.

For example, with a prefix of C<rpc>, and a method C<foo>, the forward
path would be come C</rpc/foo>.

The default is '' (empty).

=item separator

This is a STRING used to split your method on, allowing you to use
a hierarchy in your method calls.

For example, with a separator of C<.> the method call C<demo.echo>
would be forwarded to C</demo/echo>.  To make C<demo_echo> forward to the
same path, you would change the separator to C<_>,

The default is C<.>, splitting methods on a single C<.>

=item convert_params

Make the arguments in C<< $c->req->jsonrpc->params >> available as
C<< $c->req->params >>. 

Defaults to true.

=item show_errors

Make system errors in C<< $c->error >> public to the rpc-caller in a JSON-RPC
faultString. When show_errors is false, and your catalyst app generates a
fault, it will return an JSON-RPC fault containing error number 500 and error
string: "Internal Server Error".

Defaults to false.

=back

=head1 DIAGNOSTICS

=over 4

=item Invalid JSONRPC request: No such method

There is no corresponding method in your application that can be
forwarded to.

=item Invalid JSONRPC request %s

There was an error parsing the JSONRPC request

=item Invalid JSONRPC request: Unknown error

An unexpected error occurred

=back

=head1 TODO

=over 4

=item Make error messages configurable/filterable

Right now, whatever ends up on $c->error gets returned to the client.
It would be nice to have a way to filter/massage these messages before
they are sent back to the client.

=item Make stash filterable before returning

Just like the error messages, it would be nice to be able to filter the
stash before returning so you can filter out keys you don't want to 
return to the client, or just return a certain list of keys. 
This all to make transparent use of JSONRPC and web easier.

=back

=head1 SEE ALSO

L<Catalyst::Manual>, 
L<Catalyst::Request>, L<Catalyst::Response>,  L<JSON::RPC::Common>, 

=head1 ACKNOWLEDGEMENTS

For the original implementation of this module:

Marcus Ramberg C<mramberg@cpan.org>
Christian Hansen
Yoshinori Sano
Jos Boumans (kane@cpan.org)
Michiel Ootjers (michiel@cpan.org)

=head1 AUTHORS

Original Author: Sergey Nosenko (darknos@cpan.org)

Actual Maintainer: Jose Luis Martinez Torres JLMARTIN (jlmartinez@capside.com)

L<http://code.google.com/p/catalyst-server-jsonrpc>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Plugin::Server::JSONRPC> to
C<http://code.google.com/p/catalyst-server-jsonrpc/issues/entry>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
