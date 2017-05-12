# --- accessor methods -----------------------------------

sub get_x {
	my ($self) = @_;
	$self->{_x};
}

sub get_y {
	my ($self) = @_;
	$self->{_y};
}

sub get_a_belongs_to {
	my ($self) = @_;
	$self->{_a_belongs_to};
}

# --- manipulator methods --------------------------------

sub clear_x {
	my ($self) = @_;
	my $v = $self->set_x(undef);

}

sub clear_y {
	my ($self) = @_;
	my $v = $self->set_y(undef);

}

sub clear_a_belongs_to {
	my ($self) = @_;
	my $v = $self->set_a_belongs_to(undef);

}

sub set_x {
	my ($self, $value) = @_;
	$self->{_x} = $value;
}

sub set_y {
	my ($self, $value) = @_;
	$self->{_y} = $value;
}

sub set_a_belongs_to {
	my ($self, $value) = @_;
	$self->{_a_belongs_to} = $value;
}

1;

