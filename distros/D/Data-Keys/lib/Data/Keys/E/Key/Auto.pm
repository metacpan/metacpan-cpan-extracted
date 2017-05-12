package Data::Keys::E::Key::Auto;

=head1 NAME

Data::Keys::E::Key::Auto - auto create key via callback

=head1 DESCRIPTION

For set and when the key is not present C<auto_key> callback is executed
with a value as an argument.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose::Role;
use Digest::SHA1 'sha1_hex';

=head1 PROPERTIES

=head1 auto_key

A callback that is executed when set is called with undef key. Default
callback is C<sha1_hex>.

=cut

has 'auto_key' => ( isa => 'CodeRef',  is => 'rw', lazy => 1, default => sub { \&sha1_hex } );

requires('set');

around 'set' => sub {
	my $set   = shift;
	my $self  = shift;
	my $key   = shift;
	my $value = shift;

    $key = $self->auto_key->($value)
        if not defined $key;
    return $self->$set($key, $value);
};

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
