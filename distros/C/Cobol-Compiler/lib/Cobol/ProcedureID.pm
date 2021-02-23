package Cobol::Compiler::ProcedureID;

### The ID after PROCEDURE 

use parent 'ID';

sub new {
	my ($class, $id) = @_;
        my $self = $class->SUPER::new( $id );
	$self->{installer} = Cobol::Compiler::ProcedureTokenInstaller->new);

}

1;
