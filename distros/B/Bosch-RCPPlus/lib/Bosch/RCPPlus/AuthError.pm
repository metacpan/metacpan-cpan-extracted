package Bosch::RCPPlus::AuthError;
use strict;

sub new
{
	my ($proto, $error) = @_;
	my $class = ref($proto) || $proto;

	my $self = {
		error => $error,
	};

	bless ($self, $class);
	return $self;
}

sub error
{
	my ($proto) = @_;

	return $proto->{error}
}

1;
