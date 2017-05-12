package Data::Keys::E::Locking;

=head1 NAME

Data::Keys::E::Locking - get/set locking

=head1 DESCRIPTION

Generic locking for set and get functions. Need an extension that is
implementing C<lock_sh>, C<lock_ex> and C<unlock>.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose::Role;

requires('get', 'set', 'lock_ex', 'lock_sh', 'unlock');

around 'get' => sub {
	my $get   = shift;
	my $self  = shift;
	my $key   = shift;

	eval { $self->lock_sh($key) };
	return if $@;

	my $value = $self->$get($key);

	$self->unlock($key);

	return $value;
};

around 'set' => sub {
	my $set   = shift;
	my $self  = shift;
	my $key   = shift;
	my $value = shift;
	
	$self->lock_ex($key, 1);
	
    # call set
    my $ret = $self->$set($key, $value);
    
	$self->unlock($key);
    
    return $ret;
};

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
