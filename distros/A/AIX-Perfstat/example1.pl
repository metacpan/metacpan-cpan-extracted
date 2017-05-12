#!/usr/bin/env perl

#
#
# Dump the result of all AIX::Perfstat functions
#
#

use strict;
use warnings;

use Data::Dumper;
use AIX::Perfstat;

my $cput = AIX::Perfstat::cpu_total();
print "cpu_total() ", Dumper($cput);

my $diskt = AIX::Perfstat::disk_total();
print "disk_total() ", Dumper($diskt);

my $netift = AIX::Perfstat::netinterface_total();
print "netinterface_total() ", Dumper($netift);

my $memoryt = AIX::Perfstat::memory_total();
print "memory_total() ", Dumper($memoryt);

my $num_cpus = AIX::Perfstat::cpu_count();
print "cpu_count() $num_cpus\n";

my $num_disks = AIX::Perfstat::disk_count();
print "disk_count() $num_disks\n";

my $num_netifs = AIX::Perfstat::netinterface_count();
print "netinterface_count() $num_netifs\n";

my $cpu_data = AIX::Perfstat::cpu($num_cpus);
print "cpu($num_cpus) ", Dumper($cpu_data);

my $disk_data = AIX::Perfstat::disk($num_disks);
print "disk($num_disks) ", Dumper($disk_data);

my $netif_data = AIX::Perfstat::netinterface($num_netifs);
print "netinterface($num_netifs) ", Dumper($netif_data);
