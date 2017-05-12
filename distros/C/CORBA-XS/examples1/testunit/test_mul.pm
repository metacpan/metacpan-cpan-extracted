
use strict;

package test_mul;
use base qw(Test::Unit::TestCase);

use Error qw(:try);

use Calc;


sub set_up {
	# called before each test
	my $self = shift;

	$self->{calc} = new Calc();
}

sub tear_down {
	# called after each test
	my $self = shift;

	delete $self->{calc};
}

#
#		TEST CASE
#

sub test_mul_1 {
	my $self = shift;

	try {
		my $result = $self->{calc}->Mul(5, 2);
		$self->assert($result == 10);
	}
	catch CORBA::Exception with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}; # Don't forget the trailing ; or you might be surprised
}

sub test_mul_2 {
	my $self = shift;

	try {
		my $result = $self->{calc}->Mul(5, 0);
	}
	catch CORBA::Exception with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}; # Don't forget the trailing ; or you might be surprised
}


1;

