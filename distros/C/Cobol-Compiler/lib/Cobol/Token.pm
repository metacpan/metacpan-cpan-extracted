package Cobol::Compiler::Token;

sub new {
	my ($class) = @_;

	my $self = { subTokens => {}, };

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
