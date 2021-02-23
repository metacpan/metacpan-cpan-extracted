package Cobol::Compiler::DataTokenInstaller;

### This is a string token installer to the ProcedureID class

use parent 'TokenInstaller';

sub new {
	my ($class) = @_;
        my $self = $class->SUPER::new;

}


sub getToken {
	my ($self) = @_;

	return Cobol::Compiler::DataToken->new;
}

1;
