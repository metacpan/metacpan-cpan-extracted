#!/usr/bin/perl

use lib qw#../lib #;
use Data::Dumper;
use BlueCoat::SGOS;

my $bc = BlueCoat::SGOS->new('debuglevel' => 0,);

my $file = $ARGV[0] || '../t/sysinfos/4006060000_5.3.1.4__0.sysinfo';

$bc->get_sysinfo_from_file($file);
$bc->parse_sysinfo();

print "$bc->{'appliance-name'};$bc->{'modelnumber'};$bc->{'serialnumber'};$bc->{'sgosversion'};$bc->{'sgosreleaseid'}\n";

