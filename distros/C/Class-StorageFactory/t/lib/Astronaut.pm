package Astronaut;

use strict;
use warnings;

sub new
{
	my ($self, $attributes) = @_;
	bless $attributes, $self;
}

sub data
{
	my $self = shift;
	return { %$self };
}

BEGIN
{
	no strict 'refs';

	for my $method (qw( name rank age ))
	{
		*{ $method } = sub
		{
			my $self = shift;
			return $self->{$method};
		};
	}
}

1;
