package Data::Keys::E::UniqSet;

=head1 NAME

Data::Keys::E::UniqSet - a key can be set only once

=head1 DESCRIPTION

One key can be set only once. Second set attempt on a key will throw an
exception.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose::Role;
use Fcntl qw(:DEFAULT);

requires('set', 'lock_ex', 'unlock');

around 'set' => sub {
	my $set   = shift;
	my $self  = shift;
	my $key   = shift;
	my $value = shift;
	
	$self->lock_ex($key);

	# pass through in case of delete
	$self->$set($key, undef)
		if not defined $value;
	
	die '"'.$key.'" already exists'
		if $self->get($key);
	
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
