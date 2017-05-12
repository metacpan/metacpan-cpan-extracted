package Aspect::Loader::Configuration;
use strict;
use warnings;

sub new{
	my $class = shift;
	my $self = {
		_configuration => [],	
	};
	bless $self,$class;
	return $self;
}

sub load_configuration{ die "implement this";}

sub get_configuration{ 
	my $self = shift;
	return $self->{_configuration};
}

1;
