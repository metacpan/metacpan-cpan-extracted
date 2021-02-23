package Cobol::Compiler::ProgramID;

### The ID after IDENTIFICATION, PROGRAM-ID.

use parent 'ID';

sub new {
	my ($class, $id) = @_;
        my $self = $class->SUPER::new( $id );
	$self->{installer} = Cobol::Compiler::ProgramTokenInstaller->new);


}

