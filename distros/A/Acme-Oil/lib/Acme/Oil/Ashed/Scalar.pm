
##############################################################################
package Acme::Oil::Ashed::Scalar;

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
	'ASH';
}


sub STORE {}

1;
