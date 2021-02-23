package Cobol::Compiler::ProcedureToken;

use parent 'Token';

use constant DATATOKENS => qw(DATA);

sub new {
	my ($class) = @_;
        my $self = $class->SUPER::new;

	$self->{subTokens}[Cobol::Compiler::ProcedureToken->DATA] = 1001;

}

1;
