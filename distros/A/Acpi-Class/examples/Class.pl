#!/usr/bin/perl 

# Modules {{{
use FindBin qw($Bin);
use lib "$Bin/../lib";
use 5.010;
use strict;
use warnings;
use Acpi::Class;
#}}}

my $class		= Acpi::Class->new;
my $classes		= $class->g_classes;
my $number		= @$classes;

say "In your system there is/are $number classes";
foreach (@$classes) { print " $_";}
print "\n";

say "-" x 50 . "\n The devices in class thermal are:";
$class->class('thermal');
my $elements = $class->g_devices; 
foreach (@$elements) { print "$_ "; }
print "\n";

# All values of the devices in the class 'thermal'
$class->class('thermal');
say "-" x 50 ;
$class->p_class_values;

# All values of the device 'cooling_device0'
$class->device('cooling_device0');
say "-" x 50 ;
$class->p_device_values;


