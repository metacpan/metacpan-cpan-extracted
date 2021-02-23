package Cobol::Compiler::COBOLMainLexer;

### This class just parser-lexes the COBOL main functionality of the file

use parent 'Lexer';
use feature "switch";

sub new {
	my ($class) = @_;

	my $self = { 
		mastersymtab =>	Cobol::Compiler::COBOLMasterSymbolTable->new, 
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub switch {
	my ($self, $s) = @_;

	### return references to ID classes in symbol table
	given ($s) {
	when ("IDENTIFICATION" or Cobol::Compiler::ProgramToken->IDENTIFICATION) {
		return \$self->{mastersymtab}->{IDENTIFICATION}	
	}
	when ("PROGRAM-ID" or Cobol::Compiler::ProgramToken->PROGRAM-ID) { 
		return \$self->{mastersymtab}->{PROGRAM-ID}	
	}

	return nil;
}

1;
