package Cobol::Compiler::ID;

### id of e.g. DATE, WORKING-STORAGE and so on the line (+ prevTokens)

sub new {
	my ($class, $id) = @_;

	my $self = { prevTokens => (), };

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
