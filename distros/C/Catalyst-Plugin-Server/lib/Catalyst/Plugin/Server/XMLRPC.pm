=head1 NAME

Catalyst::Plugin::Server::XMLRPC -- Catalyst XMLRPC Server Plugin

=head1 SYNOPSIS

    package MyApp;
    use Catalyst qw/Server Server::XMLRPC/;

    package MyApp::Controller::Example;
    use base 'Catalyst::Controller';

    sub echo : XMLRPC {                     # available as: example.echo
        my ( $self, $c, @args ) = @_;
        $c->stash->{xmlrpc} = join ', ', @args;
    }

    sub ping : XMLRPCPath('/ping') {        # available as: ping
        my ( $self, $c ) = @_;
        $c->stash->{xmlrpc} = 'Pong';
    }

    sub world : XMLRPCRegex(/hello/) {      # available as: *hello*
        my ($self, $c) = @_;
        $c->stash->{xmlrpc} = 'World';
    }

    sub echo : XMLRPCLocal {                # available as: example.echo
        my ( $self, $c, @args ) = @_;
        $c->stash->{xmlrpc} = join ', ', @args;
    }

    sub ping : XMLRPCGlobal {               # available as: ping
        my ( $self, $c ) = @_;
        $c->stash->{xmlrpc} = 'Pong';
    }

=head1 DESCRIPTION

XMLRPC Plugin for Catalyst which we tried to make compatible with the
way Catalyst works with URLS. Main features are:

=over 4

=item * Split XMLRPC methodNames by STRING to find out Controller.

=item * Single entrypoint for XMLRPC calls, like http://host.tld/rpc

=item * DispatchTypes (attributes) which work much the same as Catalyst attrs

=item * XMLRPC Parameter handling transparent to Catalyst parameter handling

=back

=head1 HOW IT WORKS

The default behaviour will handle XMLRPC Requests sent to C</rpc> by creating
an OBJECT containing XMLRPC specific parameters in C<< $c->req->xmlrpc >>.

Directly after, it will find out the Path of the Action to dispatch to, by
splitting methodName by C<.>:

  methodName: hello.world
  path      : /hello/world

From this point, it will dispatch to '/hello/world' when it exists,
like Catalyst Urls would do. What means: you will be able to set Regexes,
Paths etc on subroutines to define the endpoint.

We discuss these custom XMLRPC attributes below.

When the request is dispatched, we will return $c->stash->{xmlrpc} to the
xmlrpc client, or, when it is not available, it will return $c->stash to
the client. There is also a way of defining $c->stash keys to be send back
to the client.

=head1 ATTRIBUTES

You can mark any method in your Catalyst application as being
available remotely by using one of the following attributes,
which can be added to any existing attributes, except Private.
Remember that one of the mentioned attributes below are automatically
also Privates...

=over 4

=item XMLRPC

Make this method accessible via XMLRPC, the same way as Local does
when using catalyst by URL.

The following example will be accessible by method C<< hello.world >>:

  package Catalyst::Controller::Hello
  sub world : XMLRPC {}

=item XMLRPCLocal

Identical version of attribute C<XMLRPC>

=item XMLRPCGlobal

Make this method accessible via XMLRPC, the same way as GLOBAL does
when using catalyst by URL.

The following example will be accessible by method C<< ping >>:

  package Catalyst::Controller::Hello
  sub ping : XMLRPCGlobal {}

=item XMLRPCPath('/say/hello')

Make this method accessible via XMLRPC, the same way as Path does
when using catalyst by URL.

The following example will be accessible by method C<< say.hello >>:

  package Catalyst::Controller::Hello
  sub hello : XMLRPCPath('/say/hello') {}

=item XMLRPCRegex('foo')

Make this method accessible via XMLRPC, the same way as Regex does
when using catalyst by URL.

The following example will be accessible by example methods:
C<< a.foo.method >>
C<< wedoofoohere >>
C<< foo.getaround >>

  package Catalyst::Controller::Hello
  sub hello : XMLRPCPath('foo') {}

=back

=head1 ACCESSORS

Once you've used the plugin, you'll have an $c->request->xmlrpc accessor
which will return an C<Catalyst::Plugin::Server::XMLRPC> object.

You can query this object as follows:

=over 4

=item $c->req->xmlrpc->is_xmlrpc_request

Boolean indicating whether the current request has been initiated
via XMLRPC

=item $c->req->xmlrpc->config

Returns a C<Catalyst::Plugin::Server::XMLRPC::Config> object. See the 
C<CONFIGURATION> below on how to use and configure it.

=item $c->req->xmlrpc->body

The body of the original XMLRPC call

=item $c->req->xmlrpc->method

The name of the original method called via XMLRPC

=item $c->req->xmlrpc->args

A list of parameters supplied by the XMLRPC call

=item $c->req->xmlrpc->result_as_string

The XML body that will be sent back to the XMLRPC client

=item $c->req->xmlrpc->error

Allows you to set xmlrpc fault code and message

Example:

  $c->req->xmlrpc->error( [ 401 => 'Unauthorized' ] )

To return status code C<401> with message C<Unauthorized>

The default is to return error code C<500> on error.

=back

=head1 Server Accessors

The following accessors are always available, whether you're in a xmlrpc
specific request or not

=over 4

=item $c->server->xmlrpc->list_methods

Returns a HASHREF containing the available xmlrpc methods in Catalyst as
a key, and the C<Catalyst::Action> object as a value.

=back

=head1 CATALYST REQUEST

To make things transparent, we try to put XMLRPC params into the Request
object of Catalyst. But first we will explain something about the XMLRPC
specifications.

A full draft of these specifications can be found on:
C<http://www.xmlrpc.com/spec>

In short, a xmlrpc-request consists of a methodName, like a subroutine
name, and a list of parameters. This list of parameters may contain strings
(STRING), arrays (LIST) and structs (HASH). Off course, these can be nested.

=over 4

=item $c->req->arguments

We will put the list of arguments into $c->req->arguments, thisway you can
fetch this list within your dispatched-to-subroutine:

  sub echo : XMLRPC {
      my ($self, $c, @args) = @_;
      $c->log->debug($arg[0]);              # Prints first XMLRPC parameter
                                            # to debug log
  }

=item $c->req->parameters

Because XMLRPC parameters are a LIST, we can't B<just> fill
$c->req->paremeters. To keep things transparent, we made an extra config
option what tells the XMLRPC server we can assume the following conditions
on all XMLRPC requests:
- There is only one XMLRPC parameter
- This XMLRPC parameter is a struct (HASH)

We will put this STRUCT as key-value pairs into $c->req->parameters.

=item $c->req->params

Alias of $c->req->parameters

=item $c->req->param

Alias of $c->req->parameters

=back

=cut

{   package Catalyst::Plugin::Server::XMLRPC;

    use strict;
    use warnings;
    use attributes ();
    use MRO::Compat;
    use Data::Dumper;

    my $ServerClass = 'Catalyst::Plugin::Server::XMLRPC::Backend';

    ### only for development dumps!
    my $Debug = 0;

    ###
    ### Catalyst loading and dispatching
    ###

    ### Loads our xmlrpc backend class in $c->server->xmlrpc
    sub setup_engine {
        my $class = shift;
        $class->server->register_server(
                    'xmlrpc' => $ServerClass->new($class)
                );
        $class->next::method(@_);
    }

    ### Will load our customized DispatchTypes into Catalyst
    sub setup_dispatcher {
        my $class = shift;

        ### Load custom DispatchTypes
        $class->next::method( @_ );
        $class->dispatcher->preload_dispatch_types(
            @{$class->dispatcher->preload_dispatch_types},
            qw/ +Catalyst::Plugin::Server::XMLRPC::DispatchType::XMLRPCPath
                +Catalyst::Plugin::Server::XMLRPC::DispatchType::XMLRPCRegex/
        );

        return $class;
    }

    ### Loads the xmlrpc-server object, redispatch to the method
    sub prepare_action {
        my $c = shift;
        my @args = @_;

        ### set up the accessor to hold an xmlrpc server instance
        $c->req->register_server(
            'xmlrpc' => Catalyst::Plugin::Server::XMLRPC::Request->new()
        );

        ### are we an xmlrpc call? check the path against a regex
        my $path = $c->server->xmlrpc->config->path;
        if( $c->req->path =~ /$path/) {

            PREPARE: {
                ### mark us as an xmlrpc request
                $c->req->xmlrpc->is_xmlrpc_request(1);

                $c->log->debug( 'PREPARE WITH $c ' . Dumper ($c ) ) if $Debug;

                $c->req->xmlrpc->_deserialize_xml( $c ) or last PREPARE;

                ### CAVEAT: we consider backing up to a default for a
                ### xml-rpc method when the method doesn't exist a security
                ### risk. So when the exact method doesn't exist, we return
                ### an error.
                ### TODO ARGH Because of regex methods, this won't work

                ### set the new request path, the one we will forward to
                $c->req->path( $c->req->xmlrpc->forward_path );

                ### filter change dispatch types to our OWN
                {   my $saved_dt = $c->dispatcher->dispatch_types || [];
                    my $dp_ns
                        = 'Catalyst::Plugin::Server::XMLRPC::DispatchType::';

                    $c->dispatcher->dispatch_types(
                        [ grep {
                                $_->isa($dp_ns . 'XMLRPCPath')
                                or
                                $_->isa($dp_ns . 'XMLRPCRegex')
                            } @$saved_dt
                        ]
                    );

                    ### run the rest of the prepare actions, we should have
                    ### an action object now
                    $c->next::method( @_ );

                    ### restore the saved dispatchtypes
                    $c->dispatcher->dispatch_types( $saved_dt );
                }

                ### check if we have a c->action now
                ### check if the NEW action isn't hte same as the
                ### OLD action -- which mean no method was found
                ### Not needed, don't have an action until we NEXT
                if( (not $c->action) &&
                    !$c->server->xmlrpc->private_methods->{
                                                $c->req->xmlrpc->method
                                            }
                ) {
                    $c->req->xmlrpc->_error( 
                        $c, qq[Invalid XMLRPC request: No such method]
                    );
                    last PREPARE;
                }
            }

            ### XMLRPC parameters and argument processing, see the Request
            ### class below for information why we can't do it there.
            $c->req->parameters( $c->req->xmlrpc->params )
                        if $c->server->xmlrpc->config->convert_params;

            $c->req->args($c->req->xmlrpc->args );

        ### we're no xmlrpc request, so just let others handle it
        } else {
            $c->next::method( @_ );
        }
    }

    ### before we dispatch, make sure no xmlrpc errors have happened already,
    ### or an internal method has been called.
    sub dispatch {
        my $c = shift;

        if( $c->req->xmlrpc->is_xmlrpc_request and
            scalar( @{ $c->error } )
        ) {
            1;
        } elsif (
                $c->req->xmlrpc->is_xmlrpc_request and
                $c->server->xmlrpc->private_methods->{$c->req->xmlrpc->method}
        ) {
                $c->req->xmlrpc->run_method($c);
        } else {
            $c->next::method( @_ );
        }
    }

    sub finalize {
        my $c = shift;

        if( $c->req->xmlrpc->is_xmlrpc_request ) {

            ### if we got an error anywhere, we'll return a fault
            ### othwerise, the resultset will be returned
            ### XXX TODO make error codes configurable ( done )
            ### XXX TODO make messages customizable ( done )
            my $res;
            my $req_error = $c->req->xmlrpc->error;
            if( scalar @{ $c->error } or $req_error ) {
                if ($c->server->xmlrpc->config->show_errors) {
                    if ( $req_error && ref $req_error eq 'ARRAY' ) {
                         $res = RPC::XML::fault->new( @{ $req_error } );
                    } else {
                         $res = RPC::XML::fault->new( -1,
                                join $/, @{ $c->error }
                            );
                    }
                } else {
                    if ( $req_error && ref $req_error eq 'ARRAY' ) {
                        $res = RPC::XML::fault->new( @{ $req_error } );
                    } else {
                        $c->log->debug("XMLRPC 500 Errors:\n" .
                                        join("\n", @{ $c->error })
                                    );
                        $res = RPC::XML::fault->new(
                                            500,
                                            'Internal Server Error'
                                        );
                    }
                }
            } else {
                if( exists $c->stash->{xmlrpc} ) {
                    $res = $c->stash->{xmlrpc};
                } else {
                    $res = $c->stash;
                }
            }

            $c->res->body(
                $c->req->xmlrpc->_serialize_xmlrpc( $c, $res )
            );

            ### make sure to clear the error, so catalyst doesn't try
            ### to deal with it
            $c->error( 0 );
        }

        $c->log->debug( 'FINALIZE ' . Dumper ( $c, \@_ ) )  if $Debug;

        ### always call finalize at the end, so Catalyst's final handler
        ### gets called as well
        $c->next::method( @_ );
    }
}

### The server implementation
{   package Catalyst::Plugin::Server::XMLRPC::Backend;

    use base qw/Class::Accessor::Fast/;
    use Data::Dumper;
    use Scalar::Util 'reftype';

    __PACKAGE__->mk_accessors( qw/
                                    dispatcher
                                    private_methods
                                    c
                                    config
                                /
                            );

    sub new {
        my $class = shift;
        my $c = shift;
        my $self = $class->next::method( @_ );

        $self->c($c);
        $self->config( Catalyst::Plugin::Server::XMLRPC::Config->new( $c ) );
        $self->private_methods({});
        $self->dispatcher({});

        ### Internal function
        $self->add_private_method(
            'system.listMethods' => sub {
                my ($c_ob, @args) = @_;
                return [ keys %{
                    $c_ob->server->xmlrpc->list_methods;
                    } ];
            }
        );

        return $self;
    }

    sub add_private_method {
        my ($self, $name, $sub) = @_;

        return unless ($name && (reftype($sub) eq 'CODE'));
        $self->private_methods->{$name} = $sub;
        return 1;
    }

    sub list_methods {
        my ($self) = @_;
        return $self->dispatcher->{Path}->methods($self->c);
    }
}

### the config implementation ###
{   package Catalyst::Plugin::Server::XMLRPC::Config;
    use base 'Class::Accessor::Fast';

    ### XXX change me to an ENTRYPOINT!
    my $DefaultPath     = qr!^(/?)rpc(/|$)!i;
    my $DefaultAttr     = 'XMLRPC';
    my $DefaultPrefix   = '';
    my $DefaultSep      = '.';
    my $DefaultShowErrors = 0;

    ### XXX add: stash_fields (to encode) stash_exclude_fields (grep -v)

    __PACKAGE__->mk_accessors(
        qw/ path prefix separator attribute convert_params
            show_errors xml_encoding
        /
    );

    ### return the cached version where possible
    my $Obj;
    sub new {
        return $Obj if $Obj;

        my $class = shift;
        my $c     = shift;
        my $self  = $class->next::method;

        $self->prefix(   $c->config->{xmlrpc}->{prefix}    || $DefaultPrefix);
        $self->separator($c->config->{xmlrpc}->{separator} || $DefaultSep);
        $self->path(     $c->config->{xmlrpc}->{path}      || $DefaultPath);
        $self->show_errors( $c->config->{xmlrpc}->{show_errors}
                                || $DefaultShowErrors );
        $self->xml_encoding( $c->config->{xmlrpc}->{xml_encoding} )
                if $c->config->{xmlrpc}->{xml_encoding};
        $self->attribute($DefaultAttr);
        $self->convert_params( 1 );

        ### cache it
        return $Obj = $self;
    }
}

### the server class implementation ###
{   package Catalyst::Plugin::Server::XMLRPC::Request;

    use strict;
    use warnings;

    use RPC::XML;
    use RPC::XML::Parser;
    use Scalar::Util 'reftype';
    use Clone::Fast qw/clone/;

    use Data::Dumper;
    use Text::SimpleTable;

    use base 'Class::Data::Inheritable';
    use base 'Class::Accessor::Fast';

    __PACKAGE__->mk_accessors( qw[  forward_path args method body result
                                    is_xmlrpc_request params
                                    result_as_string internal_methods error
                                ] );

    __PACKAGE__->mk_classdata( qw[_xmlrpc_parser]);
    __PACKAGE__->_xmlrpc_parser( RPC::XML::Parser->new );

    *parameters = *params;

    sub run_method {
        my ($self, $c) = @_;

        $c->stash->{xmlrpc} =
            &{$c->server->xmlrpc->private_methods->{$self->method}}($c, @{ $c->req->args });
    }

    sub _deserialize_xml {
        my ($self, $c) = @_;

        ### the parser will die on failure, make sure we catch it
        my $content; my $req;
        eval {
            ## Make sure we do not read from empty filehandle,
            ## by sending empty string
            $content = do { local $/; my $b = $c->req->body; $b ? <$b> : ''};
            $req     = $self->_xmlrpc_parser->parse( $content );

            ### RPC::XML::Parser *returns* the error string on error
            ### OR an object... *sigh*
            die $req unless ref $req;

            ### Because we will die when request is not valid XMLRPC,
            ### we simply test it. XXX TODO This results in a malformed
            ### xml detected error, maybe we should catch it.
            $req->name;
            $req->args;
        };

        ### parsing the request went fine
        if ( not $@ and defined $req->name ) {

            $self->body( $content );                # original xml message
            $self->method( $req->name );            # name of the method

            ### allow the args to be encoded as a HASH when requested
            ### xmlrpc only knows a top level 'list', and we can not tell
            ### if that is meant to be a hash or not
            ### make sure to store args as an ARRAY REF! to be compatible
            ### with catalyst
            my @args = map { $_->value } @{ $req->args };
            $self->args( \@args );                  # parsed arguments

            ### HEURISTIC! IF @args == 1 AND it's a HASHREF,
            ### then we can assume it's key => value pairs in there
            ### and we will map them to $c->req->params
            $self->params(
                (@args == 1 && (reftype($args[0]) eq 'HASH'))
                    ? $args[0]
                    : {}
            );
            ### build the relevant namespace, action and path 
            {   ### construct the forward path -- this allows catalyst to
                ### do the hard work of dispatching for us
                my $prefix  = $c->server->xmlrpc->config->prefix;
                my ($sep)   = map { qr/$_/ }
                              map { quotemeta $_ }
                                        $c->server->xmlrpc->config->separator;

                ### error checks here
                if( $prefix =~ m|^/| ) {
                    $c->log->debug( __PACKAGE__ . ": Your prefix starts with".
                                    " a / -- This is not recommended"
                                ) if $c->debug;
                }

                unless( ref($sep) eq 'Regexp' ) {
                    $c->log->debug( __PACKAGE__ . ": Your separator is not a ".
                                    "Regexp object -- This is not recommended"
                                ) if $c->debug;
                }

                ### foo.bar => $prefix/foo/bar
                ### DO NOT add a leading slash! uri.pm gets very upset
                my @parts    = split( $sep, $self->method );
                my $fwd_path = join '/',
                                grep { defined && length } $prefix, @parts;


                ### Complete our object-instance
                $self->forward_path( $fwd_path );

                ### Notify system of called rpc method and arguments
                $c->log->debug('XML-RPC: Method called: ' . $self->method)
                     if $c->debug;
                if ($c->server->xmlrpc->config->convert_params &&
                        $self->params
                ) {
                    my $params = Text::SimpleTable->new( [ 36, 'Key' ], [ 37, 'Value' ] );
                    foreach my $key (sort keys %{$self->params}) {
                        my $value = $self->params->{$key};
                        $value = ref($value) || $value;
                        $params->row($key, $value);
                    }
                    $c->log->debug("XML-RPC: Parameters:\n" . $params->draw)
                                if ($c->debug && %{$self->params});
                }
            }

        ### an error in parsing the request
        } elsif ( $@ ) {
            $self->_error( $c, qq[Invalid XMLRPC request "$@"] );
            return;

        ### something is wrong, but who knows what...
        } else {
            $self->_error( $c, qq[Invalid XMLRPC request: Unknown error] );
            return;
        }

        return $self;
    }

    ### alias arguments to args
    *arguments = *args;

    ### Serializes the response to $c->res->body
    sub _serialize_xmlrpc {
        my ( $self, $c, $status ) = @_;

        local $RPC::XML::ENCODING = $c->server->xmlrpc->config->xml_encoding
                if $c->server->xmlrpc->config->xml_encoding;
        
        local $Clone::Fast::BREAK_REFS = 1;

        my $res = RPC::XML::response->new(clone($status));
        $c->res->content_type('text/xml');

        return $self->result_as_string( $res->as_string );
    }

    ### record errors in the error and debug log -- just for convenience 
    sub _error {
        my($self, $c, $msg) = @_;

        $c->log->debug( $msg ) if $c->debug;
        $c->error( $msg );
    }
}


1;

__END__

=head1 INTERNAL XMLRPC FUNCTIONS

The following system functions are available to the public.,

=over 4

=item system.listMethods

returns a list of available RPC methods.

=back

=head1 DEFINING RETURN VALUES

The XML-RPC response must contain a single parameter, which may contain
an array (LIST), struct (HASH) or a string (STRING). To define the return
values in your subroutine, you can alter $c->stash in three different ways.

=head2 Defining $c->stash->{xmlrpc}

When defining $c->stash->{xmlrpc}, the XMLRPC server will return these values
to the client.

=head2 When there is no $c->stash->{xmlrpc}

When there is no C<< $c->stash->{xmlrpc} >> set, it will return the complete
C<< $c->stash >>

=head1 CONFIGURATION

The XMLRPC Plugin accepts the following configuration options, which can
be set in the standard Catalyst way (See C<perldoc Catalyst> for details):

    Your::App->config( xmlrpc => { key => value } );

You can look up any of the config parameters this package uses at runtime
by calling:

    $c->server->xmlrpc->config->KEY

=over 4

=item path

This specifies the entry point for your xmlrpc server; all requests are
dispatched from there. This is the url any XMLRCP client should post to.
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

Make the arguments in C<< $c->req->xmlrpc->params >> available as
C<< $c->req->params >>. 

Defaults to true.

=item show_errors

Make system errors in C<< $c->error >> public to the rpc-caller in a XML-RPC
faultString. When show_errors is false, and your catalyst app generates a
fault, it will return an XML-RPC fault containing error number 500 and error
string: "Internal Server Error".

Defaults to false.

=item xml_encoding

Change the xml encoding send over to the client. So you could change the
default encoding to C<UTF-8> for instance.

Defaults to C<us-ascii> which is the default of C<RPC::XML>.

=back

=head1 DIAGNOSTICS

=over 4

=item Invalid XMLRPC request: No such method

There is no corresponding method in your application that can be
forwarded to.

=item Invalid XMLRPC request %s

There was an error parsing the XMLRPC request

=item Invalid XMLRPC request: Unknown error

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
This all to make transparent use of XMLRPC and web easier.

=back

=head1 SEE ALSO

L<Catalyst::Plugin::Server::XMLRPC::Tutorial>, L<Catalyst::Manual>, 
L<Catalyst::Request>, L<Catalyst::Response>,  L<RPC::XML>, 
C<bin/rpc_client>

=head1 ACKNOWLEDGEMENTS

For the original implementation of this module:

Marcus Ramberg, C<mramberg@cpan.org>
Christian Hansen
Yoshinori Sano

=head1 AUTHORS

Original Authors: Jos Boumans (kane@cpan.org) and Michiel Ootjers (michiel@cpan.org)

Actually maintained by Jose Luis Martinez Torres JLMARTIN (jlmartinez@capside.com)

=head1 THANKS

Tomas Doran (BOBTFISH) for helping out with the debugging

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Plugin::Server> to
C<bug-catalyst-plugin-server@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
