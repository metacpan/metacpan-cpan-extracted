package Cobol::Compiler::ProgramTokenInstaller;

### This is a string token installer to the ProgramID class

use parent 'TokenInstaller';

sub new {
	my ($class) = @_;
        my $self = $class->SUPER::new;

}


sub getToken {
	my ($self) = @_;

	return Cobol::Compiler::ProgramToken->new;
}

1;
