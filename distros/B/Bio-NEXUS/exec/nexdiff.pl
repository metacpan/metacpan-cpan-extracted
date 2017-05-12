#! /usr/bin/perl -w

use Bio::NEXUS;

my ($f1, $f2) = @ARGV;

my $nexus1 = Bio::NEXUS->new($f1);
my $nexus2 = Bio::NEXUS->new($f2);

if ($nexus1->equals($nexus2)) {print "$f1 and $f2 represent the same NEXUS data\n";}
else {print "$f1 and $f2 do not represent the same NEXUS data\n";}
