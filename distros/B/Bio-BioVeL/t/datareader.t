#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';

BEGIN {
	use_ok('Bio::BioVeL::Service::NeXMLMerger::DataReader');
}

my $tr = Bio::BioVeL::Service::NeXMLMerger::DataReader->new('nexus');
isa_ok($tr,'Bio::BioVeL::Service::NeXMLMerger::DataReader::nexus');

open my $fh, '<', "$Bin/../Examples/Nexus_SimplePartition.nex" or die $!;
my @matrices = $tr->read_data($fh);
isa_ok($_,'Bio::Phylo::Matrices::Matrix') for @matrices;