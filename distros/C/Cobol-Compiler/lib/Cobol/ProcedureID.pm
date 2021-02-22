package Cobol::Compiler::ProcedureID;

### The ID after PROCEDURE 

use parent 'ID';

sub new {
	my ($class, $prevtokens) = @_;
        my $self = $class->SUPER::new;


	for (my $i = 0; $i < length(@{ $prevtokens }); $i++) {
		push(@{ $self->{prevTokens} }, $prevtokens[$i]);
	}

}

