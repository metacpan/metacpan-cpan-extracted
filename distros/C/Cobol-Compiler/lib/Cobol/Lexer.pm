package Cobol::Compiler::Lexer;

### use constant => qw(DATA PROCEDURE WORKING-STORAGE);
use feature "switch";

sub new {
	my ($class) = @_;

	my $self = { };

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
