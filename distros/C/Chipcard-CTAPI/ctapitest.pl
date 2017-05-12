#!/usr/local/bin/perl

use strict;
use warnings;
use ExtUtils::testlib;

use Chipcard::CTAPI;

my $ct = new Chipcard::CTAPI('interface' => &Chipcard::CTAPI::PORT_COM1,
                             'debug'     => 1) 
         or die "Can't communicate with card terminal on COM1, please " .
                "adjust the port in $0\n";

my ($man, $mod, $rev) = $ct->getTerminalInformation();
print "Card terminal: $man $mod $rev\n";

if ($ct->cardInserted) {
    print "Card inserted: " . $ct->getMemorySize . " bytes memory\n";
}
else {
    print "No card inserted currently.\n";
}
                         
$ct->close;

print "If you got this far without an error message, Chipcard::CTAPI should\n";
print "work fine on this system.\n";
print "Use 'perldoc Chipcard::CTAPI' to view the documentation after\n";
print "running 'make install'.\n";

exit 0;

