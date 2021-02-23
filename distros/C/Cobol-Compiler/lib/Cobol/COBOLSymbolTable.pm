package Cobol::Compiler::COBOLSymbolTable;

sub new {
	my ($class) = @_;

	### set up IDs (symbols) for the compiling system
	my $self = { 
		PROCEDURES => Cobol::Compiler::ProcedureList->new,			
		DATAS => Cobol::Compiler::DataList->new,			
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
