package Cobol::Compiler::PointToken;

use parent 'Token';

use constant POINTTOKENS => qw(POINT);

sub new {
	my ($class) = @_;
        my $self = $class->SUPER::new;

	$self->{subTokens}[Cobol::Compiler::PointToken->POINT] = 9;

}

