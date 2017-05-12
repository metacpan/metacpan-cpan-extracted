
use strict;

package test_sub;
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

sub test_sub_1 {
	my $self = shift;

	try {
		my $result = $self->{calc}->Sub(5, 2);
		$self->assert($result == 3);
	}
	catch CORBA::Exception with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}; # Don't forget the trailing ; or you might be surprised
}

1;

