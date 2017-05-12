package Aspect::Loader::Definition;
use strict;
use warnings;

sub new{
	my $class = shift;
	my $resource = shift;
	my $self = {
		_call       => undef,
		_library    => undef,
		_class_name => undef,
	};
	bless $self,$class;
	$self->initialize($resource);
	return $self;
}

sub set_library{
	my $self  = shift;
	$self->{_library} = shift;
}


sub set_call{
	my $self  = shift;
	$self->{_call} = shift;
}

sub set_class_name{
	my $self = shift;
	$self->{_class_name} = shift;
}

sub get_library{
	my $self  = shift;
	return $self->{_library};
}


sub get_call{
	my $self  = shift;
	return $self->{_call};
}

sub get_class_name{
	my $self = shift;
	return $self->{_class_name};
}

sub initialize{
	my $self      = shift;
	my $resource  = shift;
	$self->set_call($resource->{call});
	$self->set_class_name($resource->{class_name});
  if(!$self->get_class_name and $self->get_call =~ /^(.*)::[^:]*/){
	  $self->set_class_name($1);
  }
	$self->set_library($resource->{library});

}


1;
