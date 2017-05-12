
package Clio::Client;
BEGIN {
  $Clio::Client::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Client::VERSION = '0.02';
}
# ABSTRACT: Base abstract class for Clio::Client::* implementations

use strict;
use Moo;
use Carp qw( croak );

with 'Clio::Role::HasManager';



has 'id' => (
    is => 'ro',
    required => 1,
);

has '_process' => (
    is => 'rw',
);


sub handshake {}


sub write { croak "Abstract method"; }


sub close { croak "Abstract method"; }


sub attach_to_process {
    my ($self, $process) = @_;

    $self->_process($process);
}


sub disconnect {
    my $self = shift;

    if ( $self->_process ) {
        $self->_process->remove_client( $self->id );
    }

    $self->close;
}


sub _restore {
    my ($self, %args) = @_;

    $self->$_( $args{$_} ) for keys %args;

    return $self;
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Client - Base abstract class for Clio::Client::* implementations

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Base abstract class for I<Clio::Client::*> implementations.

Can be wrapped with C<InputFilter>s and C<OutputFilter>s defined in
I<E<lt>Server/ClientE<gt>> block.

Consumes the L<Clio::Role::HasManager>.

=head1 ATTRIBUTES

=head2 id

Required read-only client identifier.

=head1 METHODS

=head2 handshake

Method called once per new client. No-op in base class.

=head2 write

    $client->write( $msg );

Abstract method used to write to client.

=head2 close

    $client->close();

Abstract method used to close connection with client.

Not to be used directly, see L</"disconnect">.

=head2 attach_to_process

    $client->attach_to_process( $process );

Links a process with a client.

=head2 disconnect

    $client->disconnect();

Removes link to connected process and closes the connection.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

