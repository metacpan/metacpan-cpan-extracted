package Cobol::Compiler::ID;

### id of e.g. DATA, WORKING-STORAGE and so on the line (+ prevTokens)
### This is a symbol class with type as prevTokens in it

sub new {
	my ($class, $id) = @_;

	my $self = { 
			codeString => $id,
			prevTokens => (), ### these are Token or derived instances
			installer => Cobol::Compiler::TokenInstaller->new, };
	
	### FIXME NOTE call this $self->{installer}->install($self);

	$class = ref($class) || $class;

	bless $self, $class;
}

sub install_token {
	my ($self, $installer) = @_;

	push(@{ $self->{prevTokens} }, $installer->getToken; );
}

sub getCodeString {
	my ($self) = @_;

	return $self->{codeString};

}
1;
