# --- accessor methods -----------------------------------

sub get_name {
	my ($self) = @_;
	$self->{_name};
}

sub get_a_is_capital_from {
	my ($self) = @_;
	$self->{_a_is_capital_from};
}

# --- manipulator methods --------------------------------

sub clear_name {
	my ($self) = @_;
	my $v = $self->set_name(undef);

}

sub clear_a_is_capital_from {
	my ($self) = @_;
	my $v = $self->set_a_is_capital_from(undef);

}

sub set_name {
	my ($self, $value) = @_;
	$self->{_name} = $value;
}

sub set_a_is_capital_from {
	my ($self, $value) = @_;
	$self->{_a_is_capital_from} = $value;
}

1;

