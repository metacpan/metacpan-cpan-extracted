##############################################################################
package Acme::Oil::ed;

use strict;
use Carp;
use warnings;
use warnings::register;

sub wipe {
	my $self = shift;
	my $wipe = shift || 0;
	return 0 if($self->{level} < 1);
	$self->{level} -= $wipe;
}

sub is_slipped {
	my $self   = shift;
	my $weight = shift || 8;
	my $wipe   = shift || 1;
	my $check  = $self->wipe($wipe) * $weight;
	rand(100) < $check ? 1 : 0;
}



sub ignition {
	my $self = shift;
	my $ash  = 'ASH';

	carp "Don't bring the fire close!  ...Bom!"
	  if(warnings::enabled('Acme::Oil'));

	$self =~ /Acme::Oil::ed::(\w+)/;

	if($1 eq 'Scalar'){
		require Acme::Oil::Ashed::Scalar;
		bless $self, 'Acme::Oil::Ashed::Scalar';
	}
	elsif($1 eq 'Array'){
		require Acme::Oil::Ashed::Array;
		bless $self, 'Acme::Oil::Ashed::Array';
	}
}


1;
