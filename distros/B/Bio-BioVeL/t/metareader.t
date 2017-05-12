#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';

use_ok ( 'Bio::BioVeL::Service::NeXMLMerger::MetaReader' );

# test csv metadata input
my $metaformat = 'tsv';
my $reader = Bio::BioVeL::Service::NeXMLMerger::MetaReader->new( $metaformat );

isa_ok( $reader, 'Bio::BioVeL::Service::NeXMLMerger::MetaReader::tsv' );

open my $fh, '<', "$Bin/../Examples/TaxaMetadataExample.tsv" or die $!; 
my @rows = $reader->read_meta( $fh );

cmp_ok ( scalar(@rows), '==',  6, "number of rows in table" );
cmp_ok ( $rows[2]{'TaxonID'}, "eq", "Tax3", "right row" );


# test json metadata input
$metaformat = 'json';

my $reader_json = Bio::BioVeL::Service::NeXMLMerger::MetaReader->new( $metaformat );

isa_ok( $reader_json, 'Bio::BioVeL::Service::NeXMLMerger::MetaReader::json' );

open  $fh, '<', "$Bin/../Examples/TaxaMetadataExample.json" or die $!; 
my @rows_json = $reader_json->read_meta( $fh );
cmp_ok ( scalar(@rows_json), '==',  6, "number of rows in table" );
cmp_ok ( $rows_json[2]{'TaxonID'}, "eq", "Tax3", "right row" );
