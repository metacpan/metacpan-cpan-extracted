package Cobol::Compiler::DataList;

sub new {
	my ($class) = @_;

	my $self = { list => (), };

	$class = ref($class) || $class;

	bless $self, $class;
}

sub add {
	my ($self, $dataid) = @_;

	push (@{$self->{list}}, $dataid);
}

1;
