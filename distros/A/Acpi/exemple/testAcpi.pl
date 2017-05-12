#!/usr/bin/perl

use Acpi::Battery;
use Acpi::Temperature;
use Acpi::Fan;
use strict;

my $bat = Acpi::Battery->new;
my $temp = Acpi::Temperature->new;
my $fan = Acpi::Fan->new;

if($bat->batteryOnLine == 0){
print "battery online\n";

$bat->getCharge;

my(%value0) = $bat->getChargingState;

foreach(keys(%value0)){
	print "Charge : $_ $value0{$_}\n";
}

my(%value1) = $bat->getPresent;

foreach (keys(%value1)){
	print "Present : $_ $value1{$_}\n";
}

my(%value2) = $bat->getDesignCapacity;

foreach (keys(%value2)){
	print "TYPE : $_ $value2{$_}\n";
}
print $bat->getHoursLeft.":".$bat->getMinutesLeft."\n";
}

else{
	print "battery offline\n";
}
