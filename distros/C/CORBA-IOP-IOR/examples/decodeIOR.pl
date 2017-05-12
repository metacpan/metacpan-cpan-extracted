#!/usr/local/bin/perl -w

require CORBA::IOP::IOR;

$ior = new CORBA::IOP::IOR;
$ior->parseIOR($ARGV[0]);

print "\n";
$ior->printHash();
