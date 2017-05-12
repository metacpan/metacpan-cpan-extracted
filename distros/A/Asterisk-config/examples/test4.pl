#!/usr/bin/perl
use Data::Dumper;
use lib '../lib';
use Asterisk::config;

my $rc = new Asterisk::config(file=>'sip.conf');

if (!$rc->set_objvar(mytest=>'test')) {
	print "not found\n";
}

$rc->set_objvar(reload_when_save=>123467);

print $rc->get_objvar('reload_when_save');
