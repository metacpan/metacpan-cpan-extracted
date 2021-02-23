package Cobol::Compiler::Working_StorageToken;

use parent 'Token';

use constant WORKINGSTORAGETOKENS => qw(WORKING-STORAGE SECTION);

sub new {
	my ($class) = @_;
        my $self = $class->SUPER::new;

	$self->{subTokens}[Cobol::Compiler::Working_StorageToken->WORKING-STORAGE] = 1001;
	$self->{subTokens}[Cobol::Compiler::Working_StorageToken->SECTION] = 1002;

}

sub getWORKING_STORAGE {
	my ($self) = @_;

	return $self->{subTokens}[Cobol::Compiler::Working_StorageToken->WORKING-STORAGE];
}

sub getSECTION {
	my ($self) = @_;

	return $self->{subTokens}[Cobol::Compiler::Working_StorageToken->SECTION];
}


