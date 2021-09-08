package Bio::Epithelium::Energy; 

sub new {
	my ($class, $e) = @_;

	my $self = { energy => $e, };

	$class = ref($class) || $class;

	bless $self, $class;
}


sub get_energy {
	my ($self) = @_;

	return $self->{energy}
}

sub set_energy {
	my ($self, $e) = @_;

	$self->{energy} = $e;
}

1;
