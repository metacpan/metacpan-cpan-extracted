package Example::BoundedQueueBase;

sub head {
	my( $self ) = @_;

	$self->{ items }[0];
}

sub tail {
	my( $self ) = @_;

	$self->{ items }[-1];
}

sub max_size {
	my( $self ) = @_;

	$self->{ max_size };
}

sub size {
	my $self = shift;

	scalar @{ $self->{ items } };
}

sub pop {
	my $self = shift;

	shift @{ $self->{ items } };
}

sub push {
	my( $self, $item ) = @_;

	shift @{ $self->{ items } } if @{ $self->{ items } } == $self->{ max_size };
	push @{ $self->{ items } }, $item;
}

1;
