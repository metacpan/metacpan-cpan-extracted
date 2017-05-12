
use strict;

package test_add;
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

sub test_add_1 {
	my $self = shift;

	try {
		my $result = $self->{calc}->Add(5, 2);
		$self->assert($result == 7);
	}
	catch CORBA::Exception with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}; # Don't forget the trailing ; or you might be surprised
}

1;

