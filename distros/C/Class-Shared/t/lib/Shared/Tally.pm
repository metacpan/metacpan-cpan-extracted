package Shared::Tally;

# A second target class, so a test can have one backend load two modules.  It
# keeps state of its own, which is the point of asking for it separately from
# Shared::Counter.

use strict;
use warnings;

sub new {
	my ($class, %opt) = @_;

	return bless {
		total => defined $opt{start} ? $opt{start} : 0,
	}, $class;
}

sub total { $_[0]->{total} }

sub add {
	my $self = shift;

	$self->{total} += $_ for @_;

	return $self->{total};
}

1;
