#!/usr/local/bin/perl -w

require CORBA::IOP::IOR;
use Getopt::Std;

$opt_h = 0;
getopts('h:');

$ior = new COBRA::IOP::IOR;

$ior->parseIOR($ARGV[0]);

if ($opt_h) {
  $ior->{IIOP_profile}->{host} = $opt_h;
}

print "\n", $ior->stringifyIOR(), "\n";
