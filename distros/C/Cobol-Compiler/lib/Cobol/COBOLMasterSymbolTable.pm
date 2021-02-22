package Cobol::Compiler::COBOLMasterSymbolTable;

sub new {
	my ($class) = @_;

	my $self = { IDENTIFICATION => undef, 
			DATAID => undef, 
			MAINPROCEDURE => undef, };

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
