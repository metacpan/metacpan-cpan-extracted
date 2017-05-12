#!/usr/bin/perl -w
use Data::Dumper;
use lib '../lib';
use Asterisk::config;

my $rc = new Asterisk::config(file=>'exten.conf',keep_resource_array=>0);

$rc->assign_delkey(section=>'mytest',key=>'exten',value_regexp=>'201',value=>'201,2,Hangup()');

# new_file can save data to newfile
$rc->save_file(new_file=>'new_exten.conf');

