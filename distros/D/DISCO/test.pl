#!/usr/bin/perl
##
##  demo program that demonstrates use of DISCO
##

use DISCO;

print "Content-type: text/plain\n\n";
my $disco = DISCO->new(URI => 'http://www.hauser-wenz.NET/playground/ws/Default.disco');

print 'ref: ' . $disco->get_ref . "\n";
print 'docRef: ' . $disco->get_docRef . "\n";
print 'address: ' . $disco->get_address;


