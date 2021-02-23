package Cobol::Compiler::COBOLMasterSymbolTable;

sub new {
	my ($class) = @_;

	### set up IDs (symbols) for the master compiling system
	my $self = { IDENTIFICATION => Cobol::Compiler::ProgramID->new(""),
			PROGRAM-ID => Cobol::Compiler::ProgramID->new(""),
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
