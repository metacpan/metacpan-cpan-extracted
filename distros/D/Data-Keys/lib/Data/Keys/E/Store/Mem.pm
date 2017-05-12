package Data::Keys::E::Store::Mem;

=head1 NAME

Data::Keys::E::Store::Mem - in memory storage

=head1 SYNOPSIS

	my $dk = Data::Keys->new(
		'extend_with' => 'Store::Mem',
    );

=head1 DESCRIPTION

Stores key/values in memory.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose::Role;

=head1 PROPERTIES

=head2 mem_store

Hashref holding the key/values.

=cut

has 'mem_store' => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub {{}});

=head1 METHODS

=head2 get($key)

Return value of the C<$key> from the L</mem_store> hash.

=cut

sub get {
	my $self  = shift;
	my $key   = shift;

	return $self->mem_store->{$key};
}

=head2 set($key, $value)

Sets C<$value> to C<$key> of the L</mem_store> hash.

=cut

sub set {
	my $self  = shift;
	my $key   = shift;
	my $value = shift;
	
	if (not defined $value) {
		delete $self->mem_store->{$key};
	}
	else {
    	$self->mem_store->{$key} = $value;
	}
    
    return $key;
}

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
