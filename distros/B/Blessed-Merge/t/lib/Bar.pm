package Bar;

sub new {
	bless {}, $_[0];
}

sub another {
	return 'next';
}

1;

