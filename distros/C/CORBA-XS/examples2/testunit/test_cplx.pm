
use strict;

package test_cplx;
use base qw(Test::Unit::TestCase);

use Error qw(:try);

use CalcCplx;


sub set_up {
	# called before each test
	my $self = shift;

	$self->{calc} = new CalcCplx();
	$self->{c1} = { re => 1, im => 3 };
	$self->{c2} = { re => 2, im => -1 };
}

sub tear_down {
	# called after each test
	my $self = shift;

	delete $self->{calc};
	delete $self->{c1};
	delete $self->{c2};
}

#
#		TEST CASE
#

sub test_add_1 {
	my $self = shift;

	try {
		my $result = $self->{calc}->Add($self->{c1}, $self->{c2});
		$self->assert($result->{re} == 3);
		$self->assert($result->{im} == 2);
	}
	catch CORBA::Exception with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}; # Don't forget the trailing ; or you might be surprised
}

sub test_sub_1 {
	my $self = shift;

	try {
		my $result = $self->{calc}->Sub($self->{c1}, $self->{c2});
		$self->assert($result->{re} == -1);
		$self->assert($result->{im} == 4);
	}
	catch CORBA::Exception with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}; # Don't forget the trailing ; or you might be surprised
}

1;

