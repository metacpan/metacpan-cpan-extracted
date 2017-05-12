#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';

BEGIN {
	use_ok('Bio::BioVeL::Service::NeXMLMerger::TreeReader');
}

my $tr = Bio::BioVeL::Service::NeXMLMerger::TreeReader->new('nexus');
isa_ok($tr,'Bio::BioVeL::Service::NeXMLMerger::TreeReader::nexus');

open my $fh, '<', "$Bin/../Examples/ExampleTree.nex.con" or die $!;
my @trees = $tr->read_trees($fh);
isa_ok($_,'Bio::Phylo::Forest::Tree') for @trees;