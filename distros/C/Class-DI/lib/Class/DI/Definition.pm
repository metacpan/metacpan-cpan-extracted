package Class::DI::Definition;
use strict;
use warnings;

use constant {
	INJECTION_TYPES =>[
		"setter","constructer",
	],
	INSTANCE_TYPES =>[
		"singleton","prototype",
	],
	DEFAULT_INJECTION_TYPE => "setter",
	DEFAULT_INSTANCE_TYPE  => "singleton",
};

sub new{
	my $class = shift;
	my $resource = shift;
	my $self = {
		_name       => undef,
		_class_name => undef,
		_properties => {},
		_injection_type => DEFAULT_INJECTION_TYPE,
		_instance_type  => DEFAULT_INSTANCE_TYPE,
	};
	bless $self,$class;
	$self->initialize($resource);
	return $self;
}

sub set_name{
	my $self  = shift;
	$self->{_name} = shift;
}

sub set_class_name{
	my $self = shift;
	$self->{_class_name} = shift;
}

sub set_injection_type{
	my $self = shift;
	$self->{_injection_type} = shift;
}

sub set_instance_type{
	my $self = shift;
	$self->{_instance_type} = shift;
}

sub set_properties{
	my $self = shift;
	$self->{_properties} = shift;
}


sub get_name{
	my $self  = shift;
	return $self->{_name};
}

sub get_class_name{
	my $self = shift;
	return $self->{_class_name};
}

sub get_injection_type{
	my $self = shift;
	return $self->{_injection_type};
}
sub get_instance_type{
	my $self = shift;
	return $self->{_instance_type};
}
sub get_properties{
	my $self = shift;
	return $self->{_properties};
}

sub initialize{
	my $self      = shift;
	my $resource  = shift;
	$self->set_name($resource->{name});
	$self->set_class_name($resource->{class_name});

	if( exists $resource->{injection_type}){
		$self->set_injection_type($resource->{injection_type});
	}
	if( exists $resource->{instance_type}){
		$self->set_instance_type($resource->{instance_type});
	}
	foreach my $property_name (keys %{$resource->{properties}}){
			my $property_value = $resource->{properties}->{$property_name};
			$property_value  = $self->evaluate_property($property_value);
			$self->get_properties->{$property_name}  = $property_value;
	}
}

sub evaluate_property{
	my $self = shift;
	my $property_value = shift;
	if(ref \$property_value eq "SCALAR"){
		return $property_value;	
	}
	elsif(ref $property_value eq "ARRAY"){
		my @values = map { $self->evaluate_property($_) } @{$property_value};
		return \@values;
	}
	elsif(ref $property_value eq "HASH"){
			if(exists $property_value->{class_name}){
					return new Class::DI::Definition($property_value);	
			}
			else{
					foreach my $key (keys %{$property_value}){
							$property_value->{$key} = $self->evaluate_property($property_value->{$key});
					}
					return $property_value;
			}
	}
}
1;
