package Cobol::Compiler::Working_StorageToken;

use parent 'Token';

use constant WORKINGSTORAGETOKENS => qw(WORKING-STORAGE SECTION);

sub new {
	my ($class) = @_;
        my $self = $class->SUPER::new;

	$self->{subTokens}[Cobol::Compiler::ProgramToken->WORKING-STORAGE] = 1001;
	$self->{subTokens}[Cobol::Compiler::ProgramToken->SECTION] = 1002;

}

