##############################################################################
package Acme::Oil::ed::Array;

use warnings;
use strict;
use Carp;
use base qw(Tie::Array Acme::Oil::ed);


sub TIEARRAY {
	my $class = shift;
	my @array = @_;
	my $self   = {
		value => [@array],
		level => 80,
	};
	bless $self, $class;
}


sub FETCH {
	my ($self,$index) = @_;

	if( $self->is_slipped(1, 1) ){
		my $rand = rand($self->FETCHSIZE + 1);
		carp "Can't be taken out well by your hand's slipping."
		  if($rand ne $index and warnings::enabled('Acme::Oil'));
		return $self->{value}[$rand];
	}

	$self->{value}[$index];
}


sub STORE {
	my ($self, $index, $value) = @_;

	if(Acme::Oil::_is_burning($value)){
		$self->ignition();
		return;
	}

	if( $self->is_slipped(0.3, 0.5) ){
		carp "Can't be put well by your hand's slipping."
		  if(warnings::enabled('Acme::Oil'));

		my $rand = rand($self->FETCHSIZE + 1);

		if( $rand < $self->FETCHSIZE ){
			$self->{value}[$rand] = $value;
		}

		return;
	}

	$self->{value}[$index] = $value;
}


sub FETCHSIZE {
	my $self = shift;
	scalar @{ $self->{value} };
}


sub STORESIZE {
	my $self = shift;
	my $num  = shift;
	$#{ $self->{value} } = $num - 1;
}

sub EXISTS {
	my ($self, $index) = @_;
	exsits $self->{value}[$index];
}

sub DELETE {
	my ($self, $index) = @_;
	delete $self->{value}[$index];
}


sub CLEAR {
	my $self = shift;

	if( $self->is_slipped(1, 1) ){
		carp "Can't be clear by your hand's slipping."
		  if(warnings::enabled('Acme::Oil'));
		return;
	}

	$self->STORESIZE(0);
}





1;
__END__
