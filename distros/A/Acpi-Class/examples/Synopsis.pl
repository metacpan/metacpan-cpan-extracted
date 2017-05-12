#!/usr/bin/env perl 
#===============================================================================
#  DESCRIPTION: Example on how to use the module
#===============================================================================

# Modules {{{
use FindBin qw($Bin);
use lib "$Bin/../lib";
use 5.010;
use strict;
use warnings;
use Acpi::Class;
use Data::Dumper;
#}}}

my $class 				= Acpi::Class->new( class => 'power_supply');
my $devices = $class->g_devices;
print "Power devices: ";
foreach (@$devices) {print "$_ "} print "\n";
$class->device('ADP1');
my $ac_online 			= $class->g_values->{'online'};
$class->device('BAT1');
my $values 				= $class->g_values;
my $battery_present		= $values->{'present'};
my $battery_energy_now	= $values->{'energy_now'};
my $battery_capacity	= $values->{'capacity'};

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


