package PointWriteHandler;

sub new {
	my ($class, $verbose) = @_;
	return bless {verbose => $verbose}, $class;
}

sub tag {
	return 'point';
}

sub rep {
	my ($self, $p) = @_;
	return [$p->{x},$p->{y}] if $self->{verbose};
	return "$p->{x},$p->{y}";
}

sub stringRep {
	return undef;
}

sub getVerboseHandler {
	return __PACKAGE__->new(1);
}

1;
