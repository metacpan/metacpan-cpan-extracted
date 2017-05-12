#!/usr/bin/perl
use Data::Dumper;
use lib '../lib';
use Asterisk::config;

my $rc = new Asterisk::config(file=>'sip.conf');

print $rc->fetch_sections_hashref();
print "\n\n";

if ($rc->reload()) {
	print "true reload\n\n";
}

print $rc->fetch_sections_hashref();
print "\n\n";
