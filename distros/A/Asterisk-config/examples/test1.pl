#!/usr/bin/perl
use Data::Dumper;
use lib '../lib';
use Asterisk::config;

my $rc = new Asterisk::config(file=>'sip.conf',keep_resource_array=>0);
if ($rc) {
	print "true";
}
print Dumper $rc;
