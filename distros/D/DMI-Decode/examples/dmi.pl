#!/usr/bin/perl

use strict;
use warnings;

use DMI::Decode;

my $dmi = new DMI::Decode;

#---------------------------------
# Print out the DMI Module Version
#---------------------------------
print "\n";

print "DMI::Decode Version: $DMI::Decode::VERSION \n";

print "\n";
#----------------------------------
# Print the SMBIOS Version from DMI
#----------------------------------
my $smbios = $dmi->smbios_version;

print "SMBIOS Version: " . $smbios->{version}, "\n";

print "\n";
#-----------------------------------
# Print the OS Information an Add on 
#-----------------------------------
my $os_info = $dmi->os_information;

print "OS Information: \n";
print "\tSystem Name: " . $os_info->{name}, "\n";
print "\tVersion: " . $os_info->{version}, "\n";
print "\tRelease: " . $os_info->{release}, "\n";
print "\tHardware: " . $os_info->{hardware}, "\n";
print "\tHost Name: " . $os_info->{nodename}, "\n";

print "\n";
#-----------------------------------------------
# Build a hash reference to the BIOS Information
#-----------------------------------------------
my $bios = $dmi->bios_information;

print "BIOS Information: \n";
print "\tVendor: " . $bios->{vendor}, "\n";
print "\tVersion: " . $bios->{version}, "\n";
print "\tRom Size: " . $bios->{romsize}, "\n";
print "\tRuntime Size: " . $bios->{runtime}, "\n";
print "\tRelease Date: " . $bios->{release}, "\n";

print "\tCharacteristics: \n";
foreach (@{$bios->{characteristics}}) { print "\t\t\t$_\n"; }

print "\n";
#-------------------------------------------------
# Build a hash reference to the System Information
#-------------------------------------------------
my $system_info = $dmi->system_information;

print "System Information: \n";
print "\tManufacturer: " . $system_info->{manufacturer}, "\n";
print "\tProduct Name: " . $system_info->{name}, " \n";
print "\tSerial: " . $system_info->{serial}, "\n";
print "\tVersion: " . $system_info->{version}, "\n";
print "\tUUID: " . $system_info->{uuid}, "\n";
print "\tWake-up Type: " . $system_info->{wakeup}, "\n";

print "\n";
#-------------------------------------------------------
# Build a hash reference to the Mother Board Information
#-------------------------------------------------------
my $mother_board = $dmi->base_board_information;

print "Mother Board Information: \n";
print "\tManufacturer: " . $mother_board->{manufacturer}, "\n";
print "\tProduct Name: " . $mother_board->{name}, "\n";
print "\tSerial: " . $mother_board->{serial}, "\n";
print "\tVersion: " . $mother_board->{version}, "\n";
print "\tAsset Tag: " . $mother_board->{asset_tag}, "\n";

print "\n";
#----------------------------------------------------
# Build a hash reference to the Processor Information
#----------------------------------------------------
my $processor = $dmi->processor_information;

print "Processor Information: \n";
print "\tSocket Type: " . $processor->{socket}, "\n";
print "\tManufacturer: " . $processor->{manufacturer}, "\n";
print "\tVersion: " . $processor->{version}, "\n";
print "\tType: " . $processor->{type}, "\n";
print "\tFamily: " . $processor->{family}, "\n";

