package Cobol::Compiler::DataID;

### The ID after PROCEDURE 

use parent 'ID';

sub new {
	my ($class, $id) = @_;
        my $self = $class->SUPER::new( $id );
	$self->{installer} = Cobol::Compiler::DataTokenInstaller->new);

}

1;
