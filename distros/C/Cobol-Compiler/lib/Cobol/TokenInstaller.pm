package Cobol::Compiler::TokenInstaller;

### This is a string token installer to the ID class

sub new {
	my ($class) = @_;

	my $self = {};

	$class = ref($class) || $class;

	bless $self, $class;
}


sub install {
	my ($self, $o) = @_;

	$o->install_token($self);
}

sub getToken {
	my ($self) = @_;

	return undef;
}

1;
