package Catalyst::Engine::Server::Base;

use strict;
use base 'Catalyst::Engine::HTTP::Base';

__PACKAGE__->mk_accessors('server');

=head1 NAME

Catalyst::Engine::Server::Base - Base class for Server Engines

=head1 SYNOPSIS

See L<Catalyst>.

=head1 DESCRIPTION

This is a base class for Catalyst::Engine::Server Engines.

=head1 METHODS

=over 4

=item $c->server

Returns an C<Server> object.

=back

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine::HTTP::Base>.

=over 4

=item $c->handler

=cut

sub handler {
    my ( $class, $request, $response, $server ) = @_;

    my $client = $server->{server}->{client};

    $request->uri->scheme('http');
    $request->uri->host( $request->header('Host') || $client->sockhost );
    $request->uri->port( $client->sockport );

    my $http = Catalyst::Engine::HTTP::Base::struct->new(
        address  => $client->peerhost,
        hostname => $server->{server}->{peerhost},
        request  => $request,
        response => $response
    );

    $class->SUPER::handler( $server, $http );
}

=item $c->prepare_request

=cut

sub prepare_request {
    my ( $c, $server, @arguments ) = @_;
    $c->server($server);
    $c->SUPER::prepare_request(@arguments);
}

=back

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Engine>, L<Catalyst::Engine::HTTP::Base>,
L<Net::Server>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

package Catalyst::Engine::Server::Net::Server;

use strict;
use base 'Class::Accessor::Fast';

use HTTP::Parser;
use HTTP::Request;
use HTTP::Response;

__PACKAGE__->mk_accessors('application');

sub configure_hook {
    my $self = shift;
    my $prop = $self->{server};

    my $config = $self->application->config->{server} || { };

    while ( my ( $property, $value ) = each %{ $config } ) {
        $prop->{ $property } = $value;
    }

    if ( $prop->{port} && not ref( $prop->{port} ) ) {
         $prop->{port} = [ $prop->{port} ];
    }
}

sub process_request {
    my $self   = shift;
    my $prop   = $self->{server};
    my $client = $prop->{client};

    local $SIG{ALRM} = sub { die "Timeout (30s)\n" };

  REQUEST:

    my $timeout = 30;
    my $parser  = HTTP::Parser->new;

    eval {

        alarm($timeout);

        while ( defined( my $read = $client->sysread( my $buf, 2048 ) ) ) {
            last if $read == 0;
            last if $parser->add($buf) == 0;
        }

        unless ( $client->connected ) {
            goto DONE;
        }

        unless ( $parser->request ) {
            goto DONE;
        }

        my $request  = $parser->request;
        my $response = HTTP::Response->new;
        my $protocol = sprintf( 'HTTP/%s', $request->header('X-HTTP-Version') );

        $request->protocol($protocol);

        $self->application->handler( $request, $response, $self );

        $response->date( time() );
        $response->header( Server => "Catalyst/$Catalyst::VERSION" );
        $response->protocol($protocol);

        my $connection = $request->header('Connection') || '';

        if ( $connection =~ /Keep-Alive/i ) {
            $response->header( 'Connection' => 'Keep-Alive' );
            $response->header( 'Keep-Alive' => 'timeout=60, max=100' );
        }

        if ( $connection =~ /close/i ) {
            $response->header( 'Connection' => 'close' );
        }

        $client->syswrite( $response->as_string("\x0D\x0A") );

        if ( $protocol eq 'HTTP/1.1' && $connection !~ /close/i ) {
            goto REQUEST;
        }

        if ( $protocol ne 'HTTP/1.1' && $connection =~ /Keep-Alive/i ) {
            goto REQUEST;
        }
    };

    if ( my $error = $@ ) {

        chomp($error);

        unless ( $error =~ /^Timeout/ ) {
            warn $error;
        }
    }

  DONE:

    alarm(0);

    if ( $client->connected ) {
        $client->shutdown(2);
    }
}

1;
