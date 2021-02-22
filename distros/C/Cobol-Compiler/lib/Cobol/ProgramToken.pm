package Cobol::Compiler::ProgramToken;

use parent 'Token';

use constant PROGRAMTOKENS => qw(IDENTIFICATION PROGRAM-ID);

sub new {
	my ($class) = @_;
        my $self = $class->SUPER::new;

	$self->{subTokens}[Cobol::Compiler::ProgramToken->IDENTIFCATION] = 11;
	$self->{subTokens}[Cobol::Compiler::ProgramToken->PROGRAM-ID] = 21;

}

