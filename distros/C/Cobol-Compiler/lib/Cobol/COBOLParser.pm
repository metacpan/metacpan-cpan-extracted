package Cobol::Compiler::COBOLParser;

### This class just parses the COBOL file 

use feature "switch";

sub new {
	my ($class) = @_;

	my $self = {
		file => nil,
		mainlexer => COBOLMainLexer->new,
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub open {
	my ($self) = @_;

	### FIXME open file
}

sub switch {
	my ($self, $lexsymbol) = @_;

	my $lex = mainlexer->switch($lexsymbol);

	given ($lex) {
	when (${$lexsymbol}->isa(ref Cobol::Compiler::ProcedureToken) 
		and ${$lexsymbol}->PROCEDURE) {
		${$lexsymbol}->{id} = $self->parse();
	}
	}
	return nil;
}

sub parse {
	my ($self) = @_;

	### FIXME parse next strin from $self->{file}
};

1;
