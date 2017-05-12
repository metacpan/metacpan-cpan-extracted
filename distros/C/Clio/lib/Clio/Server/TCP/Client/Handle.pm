
package Clio::Server::TCP::Client::Handle;
BEGIN {
  $Clio::Server::TCP::Client::Handle::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Server::TCP::Client::Handle::VERSION = '0.02';
}
# ABSTRACT: Clio TCP Client

use strict;
use Moo;

extends qw(Clio::Client);

use AnyEvent;
use AnyEvent::Handle;



has 'fh' => (
    is => 'ro',
    required => 1,
);

has '_handle' => (
    is => 'rw',
    lazy => 1,
    builder => '_build_handle',
);

sub _build_handle {
    my $self = shift;

    my $manager = $self->manager;

    return AnyEvent::Handle->new(
        fh => $self->fh,
        on_error  => sub {
            my ($handle, $fatal, $msg) = @_;

            my $cid = $self->id;

            $self->log->error("Connection error for client $cid: $msg");

            $manager->disconnect_client( $cid );
        },
    );
}


sub write {
    my $self = shift;

    $self->log->trace("Client ", $self->id, " writing '@_'");

    $self->_handle->push_write( @_ );
}


sub attach_to_process {
    my ($self, $process) = @_;

    $self->log->debug("Attaching process ", $process->id, " to client ", $self->id);

    $self->_process($process);

    my $reader; $reader = sub {
        my ($handle, $cmd, $eol) = @_;

        $self->_process->write( $cmd );

        $self->_handle->push_read( line => $reader );
    };
    $self->_handle->push_read( line => $reader );

}


sub close {
    my $self = shift;

    $self->_handle->destroy;
}


1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Server::TCP::Client::Handle - Clio TCP Client

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Clio package for handling clients connected over TCP socket.

Extends L<Clio::Client>.

=head1 ATTRIBUTES

=head2 fh

Connection file handle

=head1 METHODS

=head2 write

Write client's message to handle.

=head2 attach_to_process

Attach client to process.

=head2 close

Close and destroy handle.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

