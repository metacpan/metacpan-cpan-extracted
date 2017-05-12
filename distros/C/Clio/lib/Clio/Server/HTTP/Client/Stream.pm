
package Clio::Server::HTTP::Client::Stream;
BEGIN {
  $Clio::Server::HTTP::Client::Stream::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Server::HTTP::Client::Stream::VERSION = '0.02';
}
# ABSTRACT: Clio HTTP Client for streaming connections

use strict;
use Moo;

use Scalar::Util qw( blessed );

extends qw( Clio::Client );


has 'writer' => (
    is => 'rw',
);


has 'req' => (
    is => 'rw',
);


sub write {
    my $self = shift;

    $self->log->trace("Stream Client ", $self->id, " writing '@_'");

    eval {
        $self->writer->write( @_ );
    };
    if ( my $e = $@ ) {
        $self->_handle_client_error($e);
    }
}



sub respond {
    my ($self, %args) = @_;

    if ( my $input = $args{input} ) {
        my $message = $input->{message};
        $self->_process->write( $message );

        return [ 200, [
            'Content-Type' => 'text/plain; charset=utf-8',
            'Access-Control-Allow-Origin' => '*',
        ], [ "ACK" ] ];
    } else {
        return sub {
            my $respond = shift;

            my $res_status = 200;
            my $res_headers = [
                'Content-Type' => 'text/plain; charset=utf-8',
                'Access-Control-Allow-Origin' => '*',
            ];
            my $writer = $respond->([$res_status, $res_headers]);

            $self->writer( $writer );

            # no middleware is in use, so let's get under the bonnet
            if ( blessed($writer) eq 'Twiggy::Writer' ) {
                $writer->{handle}->on_error(sub {
                    my ($handle, $fatal, $message) = @_;
                    $self->_handle_client_error($message);
                });
            }

            $self->handshake;

            $self->_process->add_client( $self );
        }
    }
}


sub close {
    my $self = shift;

    $self->writer->close;
}

sub _handle_client_error {
    my ($self, $err_msg) = @_;

    my $cid = $self->id;

    $self->log->error("Connection error for client $cid: $err_msg");
    $self->manager->disconnect_client( $cid );
}


1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Server::HTTP::Client::Stream - Clio HTTP Client for streaming connections

=head1 VERSION

version 0.02

=head1 DESCRIPTION

    # HTTP server with streaming clients
    <Server>
        Listen 0:12345

        Class HTTP

        <Client>
            Class Stream

            OutputFilter LineEnd
        </Client>
    </Server>

HTTP server with streaming capabilities.

Process output is streamed directly to client - the above example can be used
directly in a browser for read only data.

Extends of L<Clio::Client>.

=head1 ATTRIBUTES

=head2 writer

Response callback writer 

=head2 req

HTTP request

=head1 METHODS

=head2 write

Write client's message to process.

=head2 respond

Returns response callback for handling client communication.

Note: POST requests (inputs for process) are separate connections.

=head2 close

Close connection to client

=head1 SEE ALSO

=over 4

=item * L<Clio::Server::HTTP::Client::WebSocket>

WebSocket connections.

=item * L<Clio::ClientOutputFilter::jQueryStream>

Example HTML/JavaScript code in C<examples/ajax.html>.

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

