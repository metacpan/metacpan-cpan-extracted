#!/usr/bin/perl

use warnings;
use strict;
use Bank::RMD;

my $calc = new Bank::RMD;

my $rmd = $calc->calculate( balance => '50000', ownerAge => 74, beneficiaryAge => 56 );
print "Calculating for a 74 year old owner and a 56 year old beneficiary with \$50,000 balance..\n\n";
print "Using return values:";
print "\nDivisor selected: " . $rmd->{divisor};
print "\nRMD             : \$" . $rmd->{rmd};
print "\nUsing OO method\n";
print "Divisor selected: " . $calc->divisor;
print "\nRMD             : \$" . $calc->rmd;
print "\n\n";

print "Calculating for a 83 year old owner no beneficiary with \$50,000 balance..\n\n";
$rmd = $calc->calculate( balance => '50000', ownerAge => 83 );

print "Using return values:";
print "\nDivisor selected: " . $rmd->{divisor};
print "\nRMD             : \$" . $rmd->{rmd};
print "\nUsing OO method\n";
print "Divisor selected: " . $calc->divisor;
print "\nRMD             : \$" . $calc->rmd;
print "\n\n";
