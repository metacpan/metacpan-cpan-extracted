#!/usr/bin/perl 

# renicing to 20 !
#system("renice 20 $$");

# module laden
use strict;
use BitTorrent;

my $torrentfile = "http://www.mininova.org/get/675632";

my $obj		= BitTorrent->new();
my $HashRef = $obj->getTrackerInfo($torrentfile);


print "Size: $HashRef->{'total_size'}\n";
print "Hash: $HashRef->{'hash'}\n";
print "Announce: $HashRef->{'announce'}\n";

foreach my $f ( $HashRef->{'files'}) {
	
	foreach my $_HashRef( @{$f} ) {
	
		print "FileName: $_HashRef->{'name'}\n";
		print "FileSize: $_HashRef->{'size'}\n";
	
	}; # foreach my $_HashRef( @{$f} ) {
	
}; # foreach my $f ( $HashRef->{'files'}) {

