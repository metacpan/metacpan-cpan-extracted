package Catalyst::Plugin::XMLRPC;

use strict;
use base 'Class::Data::Inheritable';
use attributes ();
use RPC::XML;
use RPC::XML::ParserFactory 'XML::Parser';
use Catalyst::Action;
use Catalyst::Utils;
use NEXT;

our $VERSION = '2.01';

__PACKAGE__->mk_classdata('_xmlrpc_parser');
__PACKAGE__->_xmlrpc_parser( RPC::XML::ParserFactory->new );

=head1 NAME

Catalyst::Plugin::XMLRPC - DEPRECATED Dispatch XMLRPC methods with Catalyst

=head1 SYNOPSIS

    # Include it in plugin list
    use Catalyst qw/XMLRPC/;

    # Public action to redispatch somewhere in a controller
    sub entrypoint : Global : Action('XMLRPC') {}

    # Methods with XMLRPC attribute in any controller
    sub echo : XMLRPC('myAPI.echo') {
        my ( $self, $c, @args ) = @_;
        return RPC::XML::fault->new( 400, "No input!" ) unless @args;
        return join ' ', @args;
    }

    sub add : XMLRPC {
        my ( $self, $c, $a, $b ) = @_;
        return $a + $b;
    }

=head1 DESCRIPTION

This plugin is DEPRECATED. Please do not use in new code.

This plugin allows your controller class to dispatch XMLRPC methods
from its own class.

=head1 METHODS

=head2 $c->xmlrpc

Call this method from a controller action to set it up as a endpoint.

=cut

sub xmlrpc {
    my $c = shift;

    # Deserialize
    my $req;
    eval { $req = $c->_deserialize_xmlrpc };
    if ( $@ || !$req ) {
        $c->log->debug(qq/Invalid XMLRPC request "$@"/) if $c->debug;
        $c->_serialize_xmlrpc( RPC::XML::fault->new( -1, 'Invalid request' ) );
        return 0;
    }

    my $res = RPC::XML::fault->new( -2, "No response for request" );

    # We have a method
    my $method = $req->{method};
    $c->log->debug(qq/XMLRPC request for "$method"/) if $c->debug;

    if ($method) {

        my $container;
        for my $type ( @{ $c->dispatcher->dispatch_types } ) {
            $container = $type
              if $type->isa('Catalyst::Plugin::XMLRPC::DispatchType::XMLRPC');
        }

        if ($container) {
            if ( my $action = $container->{methods}{$method} ) {
                my $class = $action->class;
                $class = $c->components->{$class} || $class;
                my @args = @{ $c->req->args };
                $c->req->args( $req->{args} );
                $c->state( $c->execute( $class, $action ) );
                $res = $c->state;
                $c->req->args( \@args );
            }
            else { $res = RPC::XML::fault->new( -4, "Unknown method" ) }
        }
        else { $res = RPC::XML::fault->new( -3, "Please come back later" ) }

    }

    # Serialize response
    $c->_serialize_xmlrpc($res);
    return $res;
}

=head2 setup_dispatcher

=cut

# Register our DispatchType
sub setup_dispatcher {
    my $c = shift;
    $c->NEXT::setup_dispatcher(@_);
    push @{ $c->dispatcher->preload_dispatch_types },
      '+Catalyst::Plugin::XMLRPC::DispatchType::XMLRPC';
    return $c;
}

# Deserializes the xml in $c->req->body
sub _deserialize_xmlrpc {
    my $c = shift;

    my $p       = $c->_xmlrpc_parser->parse;
    my $body    = $c->req->body;
    my $content = do { local $/; <$body> };
    $p->parse_more($content);
    my $req = $p->parse_done;

    my $name = $req->name;
    my @args = map { $_->value } @{ $req->args };

    return { method => $name, args => \@args };
}

# Serializes the response to $c->res->body
sub _serialize_xmlrpc {
    my ( $c, $status ) = @_;
    my $res = RPC::XML::response->new($status);
    $c->res->content_type('text/xml');
    $c->res->body( $res->as_string );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<RPC::XML>

=head1 AUTHORS

Sebastian Riedel, C<sri@oook.de>
Marcus Ramberg, C<mramberg@cpan.org>
Christian Hansen
Yoshinori Sano
Michiel Ootjers
Jos Boumans

=head1 COPYRIGHT

Copyright (c) 2005
the Catalyst::Plugin::XMLRPC L</AUTHORS>
as listed above.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut

1;
