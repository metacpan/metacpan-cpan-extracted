package Acpi::Class;
{
  $Acpi::Class::VERSION = '0.003';
}
# ABSTRACT: Inspired in Acpi::Battery, this module gets the contents of the directory '/sys/class' in terms of 'classes' (ArrayRef of directories in /sys/class), 'devices' (ArrayRef of subdirectory in class) and 'attributes' (HashRef attributes => values, from the contents of devices directory).

# Modules {{{
use 5.012;
use strict;
use warnings;
use Acpi::Class::Devices;
use Acpi::Class::Attributes;
use Object::Tiny::RW qw( class device );
# }}}

sub g_classes    #{{{ List directories (ArrayRef)
{
	my $self    = shift;
	my $devices = Acpi::Class::Devices->new( dir => "/sys/class", pattern => qr/\w/x )->devices;
	return $devices;
} #}}} 

sub g_devices    #{{{ List directories (ArrayRef)
{
	my $self = shift;
	my $class = $self->class;
	my $elements = Acpi::Class::Devices->new( dir => "/sys/class/$class", pattern => qr/\w/x )->devices;
	return \@$elements;
}#}}}

sub g_values    #{{{ filenames = attributes, content = values (HashRef)
{
	my $self = shift;
	my ($class, $device) = ($self->class, $self->device);
	my $values = Acpi::Class::Attributes->new( 'path' => "/sys/class/$class/$device" )->attributes;
	return $values;
}#}}}

sub p_device_values    #{{{
{
	my $self = shift;
	my ($class, $device) = ($self->class, $self->device);
	my $values = $self->g_values;
	say "Device '$device': ";
	foreach my $key (keys %$values)
	{
		my $value = $values->{$key};
		say "   ...$key = $value";
	}
	return 1
}#}}}

sub p_class_values    #{{{
{
	my $self = shift;
	my $class = $self->class;
	say "Class '$class': ";
	my $all_devices = $self->g_devices;
	foreach my $dev (@$all_devices)
	{
		$self->device($dev);
		$self->p_device_values;
	}
	return 1
}#}}}

1;

# pod {{{

__END__

=pod

=head1 NAME 

Acpi::Class - Gets ACPI information fom F</sys/class directory>.

=head1 SYNOPSIS

  my $class   = Acpi::Class->new( class => 'power_supply');
  my $devices = $class->g_devices;
  print "Power devices: ";
  foreach (@$devices) {print "$_ "} print "\n";
  $class->device('AC');
  my $ac_online          = $class->g_values->{'online'};
  $class->device('BAT0');
  my $values             = $class->g_values;
  my $battery_present    = $values->{'present'};
  my $battery_energy_now = $values->{'energy_now'};
  my $battery_capacity   = $values->{'capacity'};
  
  if ( $ac_online == 1 and $battery_present == 1 ) 
  {
  	say "Ac on and battery in use ";
  	say "Energy now = ". $battery_energy_now ; 
  	say "Capacity " . $battery_capacity ." %";	
  } 
  elsif ($battery_present) 
  {
  	say "Battery in use";
  	say "Energy now = ". $battery_energy_now ; 
  	say "Capacity " . $battery_capacity ." %";	
  } 
  else 
  { 
  	say "Battery not present"; 
  }
  
  # get all values of device BAT1
  say "-" x 50;
  $class->p_device_values;
  
  say "-" x 50;
  # get all values of class power_supply
  $class->p_class_values;

=head1 DESCRIPTION

Acpi::Class provides ACPI information from the directory F</sys/class>. It's specific for GNU/Linux. 

=head1 ATTRIBUTES

L<Acpi::Class> implements the following attributes:

=head2 class

$class = Acpi::Class->new( class => 'thermal');

$class->class('thermal');

Sets the class (directory under F</sys/class>).

=head2 device

$class = Acpi::Class->new( class => 'thermal', device=> 'BAT0' ));

$class->device('BAT0');

Sets the device (directory under F</sys/class/$class>).

=head1 METHODS

L<Acpi::Class> implements the following methods:

=head2 new

my $class = Acpi::Class->new( class => 'thermal', device => 'BAT1 );

Object constructor. 

=head2 g_classes

my $classes = $class->g_classes;

Gets an ArrayRef of the available classes (directories under F</sys/class>).

=head2 g_devices

Gets an ArrayRef of available devices (directories under F</sys/class/$class>).

=head2 g_values

Gets a Hashef of the attributes and values of a device (content of the files in F</sys/class/$class/$device>).

=head2 p_device_values

  $class->class('power_supply');
  $class->device('BAT1');
  $class->p_device_values;

Prints all the attributes and values of the device BAT1.

=head2 p_class_values

  $class->class('power_supply');
  $class->p_device_values;

Print all the attributes and values of the devices in the class 'power_supply'.

=head1 COMMUNITY

Get involved: 

=over 4

=item * L<GitHub|https://github.com/mimosinnet/Acpi-Class>

=item * L<Gitorious|https://gitorious.org/acpi-class>

=back

=head1 SEE ALSO

The modules L<Acpi::Battery>, L<Acpi::Fan> and L<Acpi::Temperature> get the information from the directory F</proc/acpi>. This directory is deprecated in Linux kernel 2.6.24 and deleted in 2.6.39.

=cut

# }}}
