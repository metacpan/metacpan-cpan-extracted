#!/usr/bin/perl

use lib qw#../lib #;
use Data::Dumper;
use BlueCoat::SGOS;

my $bc = BlueCoat::SGOS->new('debuglevel' => 0,);

my $file = $ARGV[0] || '../t/sysinfos/4006060000_5.3.1.4__0.sysinfo';

$bc->get_sysinfo_from_file($file);
$bc->parse_sysinfo();

print <<TOHERE;
Networking Overview
Data current as of $bc->{'sysinfotime'}

 Appliance-Name: $bc->{'appliance-name'}
   Model Number: $bc->{'modelnumber'}
  Serial Number: $bc->{'serialnumber'}
   SGOS Version: $bc->{'sgosversion'} (release $bc->{'sgosreleaseid'})
Default Gateway: $bc->{'ip-default-gateway'}

=======================================================================
Interfaces
=======================================================================
TOHERE
foreach my $k (sort keys %{$bc->{'interface'}}) {
	print "$k
  L3: $bc->{'interface'}{$k}{'ip'}  $bc->{'interface'}{$k}{'netmask'}
  L2: $bc->{'interface'}{$k}{'mac'}
  L1: $bc->{'interface'}{$k}{'linkstatus'} (can be $bc->{'interface'}{$k}{'capabilities'})

";
}

print "=======================================================================
Static Bypass
=======================================================================\n";

if ( $bc->{'static-bypass'} ) {
	print $bc->{'static-bypass'}  . "\n";
}
else {
	print "Nothing to report.\n";
}

print <<TOHERE;

=======================================================================
Route table
=======================================================================
TOHERE

if ($bc->{'sgos_sysinfo_sect'}{'TCP/IP Routing Table'}) {
	print $bc->{'sgos_sysinfo_sect'}{'TCP/IP Routing Table'} . "\n";
}
else {
	print "Nothing to report.\n";
}

print <<TOHERE;

=======================================================================
Static Route Table
=======================================================================
TOHERE

if ($bc->{'static-route-table'}) {
	print $bc->{'static-route-table'} . "\n";
}
else {
	print "Nothing to report.\n";
}
print <<TOHERE;

=======================================================================
WCCP Configuration
=======================================================================
$bc->{'sgos_sysinfo_sect'}{'WCCP Configuration'}
TOHERE

