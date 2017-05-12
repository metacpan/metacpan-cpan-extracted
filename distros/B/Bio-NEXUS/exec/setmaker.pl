#!/usr/bin/perl -w
use strict;
use Bio::NEXUS;
use Data::Dumper;

my ($nexusfile, $newnexusfile, @setfiles) = @ARGV;

my $sets;
for my $setfile (@setfiles) {
	open (SF, "<$setfile") || die ("Could not open set file $setfile.\n");
	while (<SF>) {
		chomp;
		push (@{$$sets{$setfile}}, $_);
	}
	close (SF);
}

my $nexus = Bio::NEXUS->new($nexusfile);
my $setsblock;

$setsblock = &Bio::NEXUS::SetsBlock::new('Bio::NEXUS::SetsBlock','sets');
$setsblock -> set_taxsets($sets);

Bio::NEXUS::write($nexus,$newnexusfile);
open(NNF, "+>> $newnexusfile") || die("Could not open $newnexusfile.\n");
#print Dumper($setsblock);
$setsblock -> write(\*NNF);
close (NNF);
END;