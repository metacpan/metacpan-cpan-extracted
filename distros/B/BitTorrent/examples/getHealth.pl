#!/usr/bin/perl 

# renicing to 20 !
#system("renice 20 $$");

# module laden
use strict;
use Data::Dumper;
use BitTorrent;

my $torrentfile = "http://www.mininova.org/get/620364";

my $obj		= BitTorrent->new();
my $HashRef = $obj->getHealth($torrentfile);

print "Seeder: " . $HashRef->{seeder};
print "Leecher: " . $HashRef->{leecher};
