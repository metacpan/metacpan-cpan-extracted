package Cobol::Compiler::COBOLProcedureSymbolTable;

sub new {
	my ($class) = @_;

	### set up IDs (symbols) for the compiling system
	my $self = { 
		PROCEDURE => Cobol::Compiler::ProcedureID->new(""),				DATA => Cobol::Compiler::DataID->new(""),	
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
