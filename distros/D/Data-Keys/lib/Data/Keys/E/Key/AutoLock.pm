package Data::Keys::E::Key::AutoLock;

=head1 NAME

Data::Keys::E::Key::AutoLock - lock keys automatically

=head1 DESCRIPTION

Calls C<$self->lock_sh> before each C<get>, calls C<$self->lock_ex> before
each C<set>. Afterwards calls C<$self->unlock>.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose::Role;

requires('set', 'get', 'lock_sh', 'lock_ex', 'unlock');

around 'get' => sub {
	my $get   = shift;
	my $self  = shift;
	my $key   = shift;

	$self->lock_sh($key);
	my $value = $self->$get($key);
	$self->unlock($key);
	return $value;
};

around 'set' => sub {
	my $set   = shift;
	my $self  = shift;
	my $key   = shift;
	my $value = shift;
	
	$self->lock_ex($key);
	my $new_key = $self->$set($key, $value);
	$self->unlock($key);
	return $new_key;
};

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
