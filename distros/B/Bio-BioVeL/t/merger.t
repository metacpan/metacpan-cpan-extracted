#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';

BEGIN { use_ok('Bio::BioVeL::Service::NeXMLMerger') }

my $data = "$Bin/../Examples/TaxaDataExample.nex";
my $tree = "$Bin/../Examples/TaxaTreeExample.dnd";
my $meta = "$Bin/../Examples/TaxaMetadataExample.json";
my $sets = "$Bin/../Examples/Nexus_MultiplePartitions.nex";

@ARGV = (
	'-data'          => $data,
	'-trees'         => $tree,
	'-meta'          => $meta,
	'-charsets'      => $sets,
	'-dataformat'    => 'nexus',
	'-treeformat'    => 'newick',
	'-metaformat'    => 'json',
	'-charsetformat' => 'nexus',
);

my $merger = new_ok('Bio::BioVeL::Service::NeXMLMerger');
ok( $merger->response_body );
