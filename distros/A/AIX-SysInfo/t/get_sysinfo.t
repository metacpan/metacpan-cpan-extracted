#!/usr/bin/perl
# Runs tests to make sure sysinfo hash values are all defined!

use warnings;
use strict;
use Test::More tests => 14; # currently 14 keys are populated
use AIX::SysInfo;

my %hash = get_sysinfo();
my @items = qw/ hostname
		serial_num 
		num_procs
		total_ram 
		total_swap
		aix_version
		model_type
		proc_speed
		proc_type
		firmware_ver	
		sys_arch
		lpar_name
		lpar_id   
		kernel_type
			/;

ok( defined $hash{"$_"}, "$_" ) foreach @items;

print "=================================================\n";
print "$_ = $hash{$_}\n" foreach @items;
