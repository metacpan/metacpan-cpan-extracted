package Data::Keys::E::Key::Adapt;

=head1 NAME

Data::Keys::E::Key::Adapt - change key with a callback

=head1 DESCRIPTION

Uses callback to change keys.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose::Role;

requires('get', 'set');

=head1 PROPERTIES

=head2 key_adapt

A callback that is called with a key as an argument for every set and get.
The default callback will not change the key.

=cut

has 'key_adapt'   => ( isa => 'CodeRef',  is => 'rw', lazy => 1, default => sub { sub { return $_[0] } } );

around 'get' => sub {
    my $get   = shift;
    my $self  = shift;
    my $key   = shift;

    $key = $self->key_adapt->($key);
    return $self->$get($key);
};

around 'set' => sub {
    my $set   = shift;
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    
    $key = $self->key_adapt->($key, $value);
    $self->$set($key, $value);
    return $key;
};

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
