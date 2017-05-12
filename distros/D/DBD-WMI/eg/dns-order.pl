#!/usr/bin/perl -w
package main;
use strict;
use Data::Dumper;

use DBI;

my ($machine,$user,$pass) = @ARGV;
$machine ||= ".";

my $target_ip = '192.168.1.13';

my $dbh = DBI->connect("dbi:WMI:$machine",$user,$pass);

my $sth = $dbh->prepare(<<WQL);
    SELECT * FROM Win32_NetworkAdapterConfiguration 
        WHERE IPEnabled = 1
WQL

$sth->execute();
while (defined (my $row = $sth->fetchrow_arrayref())) {
    my $conf = $row->[0];
    
    print join "\t", @{ $conf->{IPAddress} }, "\n";
    if ($conf->{IPAddress}->[0] ne $target_ip) {
        print "Skipped\n";
        next
    };
        
    my $order = $conf->{DNSServerSearchOrder};
    if ($order) {
      print join "\t", @$order;
    } else {
        print "No DNS servers defined";
    };
    print "\n";
    $conf->SetDNSServerSearchOrder(['192.168.1.102']);
}