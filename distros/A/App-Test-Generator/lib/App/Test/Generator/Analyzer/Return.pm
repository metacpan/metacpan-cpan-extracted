package App::Test::Generator::Analyzer::Return;

use strict;
use warnings;

our $VERSION = '0.31';

=head1 VERSION

Version 0.31

=cut

sub new {
	my $class = $_[0];
	return bless {}, $class;
}

sub analyze {
	my ($self, $method) = @_;

	my $source = $method->source();

	# return $self->{property}
	if ($source =~ /return\s+\$self->\{(\w+)\}/) {
		$method->add_evidence(
			category => 'return',
			signal   => 'returns_property',
			value    => $1,
			weight   => 20,
		);
	}

	# return $self
	if ($source =~ /return\s+\$self\b/) {
		$method->add_evidence(
			category => 'return',
			signal   => 'returns_self',
			weight   => 15,
		);
	}

	# return constant literal
	if ($source =~ /return\s+(['"])/) {
		$method->add_evidence(
			category => 'return',
			signal   => 'returns_constant',
			weight   => 10,
		);
	}

	return;
}

1;
