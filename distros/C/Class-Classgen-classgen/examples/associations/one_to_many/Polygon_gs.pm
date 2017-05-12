# --- accessor methods -----------------------------------

sub get_a_has {
	my ($self) = @_;
	$self->{_a_has};
}

sub get_points_at {
	my ($self, $index) = @_;
	my $rl = $self->get_rl_points();
	return $$rl[$index];
}

sub get_l_points {
	my ($self) = @_;
	my $rl = $self->get_rl_points();
	return @$rl;
}

sub get_rl_points {
	my ($self) = @_;
	my $rl = $self->{_l_points};
}

# --- manipulator methods --------------------------------

sub clear_a_has {
	my ($self) = @_;
	my $v = $self->set_a_has(undef);

}

sub clear_l_points {
	my ($self) = @_;
	my $rl = $self->get_rl_points();
	undef @$rl;
}

sub pop_points {
	my ($self) = @_;
	my $rl = $self->get_rl_points();
	return pop @$rl;
}

sub push_points {
	my ($self, $value) = @_;
	my $rl = $self->get_rl_points();
	push @$rl, $value;
}

sub set_a_has {
	my ($self, $value) = @_;
	$self->{_a_has} = $value;
}

sub set_l_points {
	my ($self, $index, $value) = @_;
	my $rl = $self->get_rl_points();
	$$rl[$index] = $value;
}

1;

