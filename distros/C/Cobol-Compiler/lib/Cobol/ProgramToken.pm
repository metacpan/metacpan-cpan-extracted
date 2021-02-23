package Cobol::Compiler::ProgramToken;

use parent 'Token';

use constant PROGRAMTOKENS => qw(IDENTIFICATION PROGRAM-ID);

sub new {
	my ($class) = @_;
        my $self = $class->SUPER::new;

	$self->{subTokens}[Cobol::Compiler::ProgramToken->IDENTIFCATION] = 11;
	$self->{subTokens}[Cobol::Compiler::ProgramToken->PROGRAM-ID] = 21;

}

sub getPROGRAMID {
	my ($self) = @_;

	return $self->{subTokens}[Cobol::Compiler::ProgramToken->PROGRAM-ID];
}

sub getIDENTIFICATION {
	my ($self) = @_;

	return $self->{subTokens}[Cobol::Compiler::ProgramToken->IDENTIFICATION];
}

1;
