package Class::DI::Factory;
use strict;
use warnings;
use UNIVERSAL::require;

sub new{
	my $class = shift;
	my $self = {
		_instance_pool => {},
	};
	bless $self,$class;
	return $self;
}


sub get_instance{
	my $self       = shift;
	my $definition = shift;
  if($definition->get_instance_type eq "singleton"
			and $self->_get_instance_pool($definition->get_name)	
	){
		return $self->_get_instance_pool($definition->get_name);
	}
	my $instance = $self->_create_instance($definition);
	if($definition->get_instance_type eq "singleton"){
		$self->_set_instance_pool(
			$definition->get_name,
			$instance,
		);
	}
	return $instance;
}

sub _get_instance_pool{
	my $self = shift;	
	my $name = shift;
	return $self->{_instance_pool}->{$name} || undef;
}

sub _set_instance_pool{
	my $self = shift;	
	my $name = shift;
	$self->{_instance_pool}->{$name} = shift;
}

sub _create_instance{
	my $self = shift;
	my $definition = shift;
	unless($definition->isa("Class::DI::Definition")){
		die "Class::DI::Definition class only";
	}
	my $class = $definition->get_class_name;
	$class->require or die "cant load class $class";

	my %properties;
	foreach my $property (keys %{$definition->get_properties}){
			my $property_value = $definition->get_properties->{$property};
			$property_value = $self->_create_property($property_value);
			$properties{$property} = $property_value;	
	}
	if($definition->get_injection_type eq "setter"){
		my $instance = $class->new;
		foreach my $property (keys %properties){
			my $method = "set_". $property;	
			$instance->$method($properties{$property});
		}
		return $instance;
	}
	elsif($definition->get_injection_type eq "constructer"){
		my $instance = $class->new(\%properties);
	}
}

sub _create_property{
	my $self = shift;
	my $property_value = shift;	
	if(ref \$property_value eq "SCALAR"){
		return $property_value;	
	}
	elsif(ref $property_value eq "ARRAY"){
		my @values = map { $self->_create_property($_) } @{$property_value};
		return \@values;
	}
	elsif(ref $property_value eq "HASH"){
		foreach my $key (keys %{$property_value}){
				$property_value->{$key} = $self->_create_property($property_value->{$key});
		}
		return $property_value;
	}
	elsif($property_value->isa("Class::DI::Definition")){
		return $self->get_instance($property_value);	
	}
}
1;
