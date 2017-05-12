#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use FindBin '$Bin';
use Test::More 'no_plan';

BEGIN {
	use_ok('Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text');
	use_ok('Bio::BioVeL::Service::NeXMLMerger::CharSetReader::nexus');
}

# read Bachir & Saverio's text file format
{
	my $file  = "$Bin/../Examples/DomainReport.txt";
	my $reader = Bio::BioVeL::Service::NeXMLMerger::CharSetReader->new('text');
	isa_ok($reader,'Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text');
	open my $fh, '<', $file or die $!;
	my %result = $reader->read_charsets($fh);
}

# read mrbayes-style charsets
{
	my $file = "$Bin/../Examples/Nexus_MultiplePartitions.nex";
	my $reader = Bio::BioVeL::Service::NeXMLMerger::CharSetReader->new('nexus');
	isa_ok($reader,'Bio::BioVeL::Service::NeXMLMerger::CharSetReader::nexus');
	open my $fh, '<', $file or die $!;
	my %result = $reader->read_charsets($fh);
}