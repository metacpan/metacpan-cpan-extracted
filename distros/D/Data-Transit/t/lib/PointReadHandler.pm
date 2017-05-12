package PointReadHandler;
use Point;

sub new {
	my ($class, $verbose) = @_;
	return bless {
		verbose => $verbose,
	}, $class;
}

sub fromRep {
	my ($self, $rep) = @_;
	return Point->new(@$rep) if $self->{verbose};
	return Point->new(split /,/,$rep);
}

sub getVerboseHandler {
	return __PACKAGE__->new(1);
}

1;
