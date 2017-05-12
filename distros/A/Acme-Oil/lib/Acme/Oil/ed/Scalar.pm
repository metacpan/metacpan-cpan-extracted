
##############################################################################
package Acme::Oil::ed::Scalar;

use warnings;
use strict;
use Carp;
use base qw(Acme::Oil::ed);


sub TIESCALAR {
	my $class  = shift;
	my $scalar = shift;
	my $self   = {
		value => $scalar,
		level => 10,
	};
	bless $self, $class;
}


sub FETCH {
	my $self  = shift;

	if( $self->is_slipped ){
		carp "Can't be taken out by your hand's slipping."
		  if(warnings::enabled('Acme::Oil'));
		return;
	}

	$self->{value};
}


sub STORE {
	my $self  = shift;
	my $value = shift;

	if(Acme::Oil::_is_burning($value)){
		$self->ignition();
		return;
	}

	if( $self->is_slipped ){
		carp "Can't be put well by your hand's slipping."
		  if(warnings::enabled('Acme::Oil'));
		return $self->{value};
	}

	$self->{value} = $value;
}

1;
