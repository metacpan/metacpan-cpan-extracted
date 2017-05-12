package Point;

sub new {
	my ($class, $x, $y) = @_;
	return bless {
		x => $x,
		y => $y,
	}, $class;
}

1;
