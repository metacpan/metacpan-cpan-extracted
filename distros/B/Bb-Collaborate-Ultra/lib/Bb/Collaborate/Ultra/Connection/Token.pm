package Bb::Collaborate::Ultra::Connection::Token;
use Mouse;
extends 'Bb::Collaborate::Ultra::DAO';
use warnings; use strict;
__PACKAGE__->resource('token');
has 'access_token' => (is => 'rw', isa => 'Str');
has 'expires_in' => (is => 'rw', isa => 'Int');
has '_leased' => (is => 'rw', isa => 'Date');

=head1 NAME

    Bb::Collaborate::Ultra::Connection::Token - Connection Token

=head1 DESCRIPTION

This class is used to store security tokens, as supplied by the REST server.

=head1 METHODS

=cut
    
=head2 expiry_time

Returns the token expiry time, as a Unix timestamp.

=cut

sub expiry_time {
    my $self = shift;
    $self->_leased + $self->expires_in;
}

1;
