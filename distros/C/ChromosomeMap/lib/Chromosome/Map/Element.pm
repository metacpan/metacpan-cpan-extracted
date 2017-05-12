package Chromosome::Map::Element;

use strict;

our $VERSION = '0.01';

#-------------------------------------------------------------------------------
# public methods
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# new element
# usage: my $element = Element->new ( ... options ... )
#-------------------------------------------------------------------------------

sub new {
	my $class = shift;
	$class = ref($class) || $class;
	
	my %Options = @_;
	my $self = {};
	$self->{_name}  = $Options{-name};
	$self->{_loc}   = $Options{-loc};
	$self->{_color} = 'black';
	$self->{_color} = $Options{-color} if (defined $Options{-color});	

	bless $self,$class;
	return $self;
}

sub get_element_loc {
	my ($self) = @_;
	return $self->{_loc};
}

sub get_element_name {
	my ($self) = @_;
	return $self->{_name};
}

sub get_element_color {
	my ($self) = @_;
	return $self->{_color};
}

1;