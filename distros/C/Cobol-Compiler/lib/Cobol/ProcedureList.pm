package Cobol::Compiler::ProcedureList;

sub new {
	my ($class) = @_;

	my $self = { list => (), };

	$class = ref($class) || $class;

	bless $self, $class;
}

sub add {
	my ($self, $procid) = @_;

	push (@{$self->{list}}, $procid);
}

1;
