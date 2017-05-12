package Class::DI::Resource;
use strict;
use warnings;
sub new{
	my $class = shift;
	my $self = {
		_resource => {},	
	};
	bless $self,$class;
	return $self;
}

sub load_resource{ die "implement this";}

sub get_resource{ 
	my $self = shift;
	my $id   = shift;
	return $self->{_resource}->{$id};
}

1;
