package Cobol::Compiler::Token;

### This is a string token

sub new {
	my ($class) = @_;

	my $self = { subTokens => {}, };

	$class = ref($class) || $class;

	bless $self, $class;
}

sub match {
	my ($self, $token) = @_;

	if ($token->isa(ref $self)) {
		return True;
	} else {
		return False;
	}
}

### procedures which match integer in a token's tokens (constants in token class)

sub match_first_single_token_int {
	my ($self, $token) = @_;

	my $size = keys %{ $self->{subTokens}};
	my @values = values %{ $self->{subTokens} };
	my @values2 = values %{ $token->{subTokens} };

	for (my $i = 0; $i < $size; $i++) {
		if (@values2[0] == @values[$i]) {
			return True;
		}
	} 
	return False;
}

sub match_single_token_int {
	my ($self, $token) = @_;

	my $size = keys %{ $self->{subTokens}};
	my $size2 = keys %{ $token->{subTokens}};
	my @values = values %{ $self->{subTokens} };
	my @values2 = values %{ $token->{subTokens} };

	for (my $i = 0; $i < $size; $i++) {
		for (my $j = 0; $j < $size2; $j++) {
			if (@values2[$j] == @values[$i]) {
				return True;
			}
		} 
	} 
	return False;
}

	 

1;
