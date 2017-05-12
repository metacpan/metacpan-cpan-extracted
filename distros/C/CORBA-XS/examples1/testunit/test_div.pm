
use strict;

package test_div;
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

sub test_div_1 {
	my $self = shift;

	try {
		my $result = $self->{calc}->Div(5, 2);
		$self->assert($result == 2);
	}
	catch Calc::DivisionByZero with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}
	catch CORBA::Exception with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}; # Don't forget the trailing ; or you might be surprised
}

sub test_div_2 {
	my $self = shift;

	try {
		my $result = $self->{calc}->Div(0, 2);
		$self->assert($result == 0);
	}
	catch Calc::DivisionByZero with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}
	catch CORBA::Exception with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}; # Don't forget the trailing ; or you might be surprised
}

sub test_div_3 {
	my $self = shift;

	try {
		my $result = $self->{calc}->Div(5, 0);
		$self->assert(0, "exception DivisionByZero excepted.");
	}
	catch Calc::DivisionByZero with {
		my $E = shift;
		$self->assert(1);
	}
	catch CORBA::Exception with {
		my $E = shift;
		$self->assert(0, $E->stringify());
	}; # Don't forget the trailing ; or you might be surprised
}

1;

