package Cobol::Compiler::ProcedureToken;

use parent 'Token';

use constant PROCEDURETOKENS => qw(PROCEDURE);

sub new {
	my ($class) = @_;
        my $self = $class->SUPER::new;

	$self->{subTokens}[Cobol::Compiler::ProcedureToken->PROCEDURE] = 101;

}

1;
