#!/usr/bin/perl
# Test suite for Device::Citizen3540 perl module
# Before make install this should work with "make test" after "perl test.pl" should work

#####
# Start by checking if the module can be loaded
#####
BEGIN { $| = 1; print "1..16\n" }
END   { print "not ok 1\n" unless $loaded }
use Device::Citizen3540 qw(:constants);
$loaded = 1;
print "ok 1\n";


#####
# Test Suite
#####
my $printer = new Device::Citizen3540;
$printer->beep();
$printer->print("TITLE", BIG | RED | CENTER);
$printer->print("This is a bunch of text, really long, really really really really long to see how long lines are handled\n");

$printer->print("This text is red\n", RED);
$printer->print("This is a bunch of RED text, really long, really really really really long to see how long lines are handled", RED);

$printer->print("This is underlined", ULINE);

$printer->feed(5);
$printer->cut();
