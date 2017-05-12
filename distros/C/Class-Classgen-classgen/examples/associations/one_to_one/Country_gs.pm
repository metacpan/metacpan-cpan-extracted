# --- accessor methods -----------------------------------

sub get_name {
	my ($self) = @_;
	$self->{_name};
}

sub get_a_has_capital {
	my ($self) = @_;
	$self->{_a_has_capital};
}

# --- manipulator methods --------------------------------

sub clear_name {
	my ($self) = @_;
	my $v = $self->set_name(undef);

}

sub clear_a_has_capital {
	my ($self) = @_;
	my $v = $self->set_a_has_capital(undef);

}

sub set_name {
	my ($self, $value) = @_;
	$self->{_name} = $value;
}

sub set_a_has_capital {
	my ($self, $value) = @_;
	$self->{_a_has_capital} = $value;
}

1;

