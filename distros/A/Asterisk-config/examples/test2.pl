#!/usr/bin/perl
use Data::Dumper;
use lib '../lib';
use Asterisk::config;

my $rc = new Asterisk::config(file=>'sip.conf');

$myfile = $rc->get_objvar('file');
print $myfile;
print "\n\n";

$parsed = $rc->fetch_sections_hashref();
print Dumper $parsed;
print "\n\n";

$section_list = $rc->fetch_sections_list();
print Dumper $section_list;
print "\n\n";

$key_ref = $rc->fetch_keys_hashref(section=>'[unsection]');
print Dumper $key_ref;
print "\n\n";

$key_list = $rc->fetch_keys_list(section=>'general');
print Dumper $key_list;
print "\n\n";

$value_list = $rc->fetch_values_arrayref(section=>'general',key=>'useragent');
print Dumper $value_list;
print "\n\n";
