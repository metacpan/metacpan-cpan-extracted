#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Slurp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::AutomatedAnnotation::SpreadsheetOfGeneOccurances');
}

my $obj;

my $gene_name_occurances_obj = Bio::AutomatedAnnotation::GeneNameOccurances->new(
      gff_files => ['t/data/copy_of_example_annotation.gff','t/data/empty_annotation.gff','t/data/different_to_example_annotation.gff','t/data/example_annotation.gff']);

ok(  $obj = Bio::AutomatedAnnotation::SpreadsheetOfGeneOccurances->new(
      gene_occurances => $gene_name_occurances_obj,
      output_filename => 'example.csv',
    ),
    'initalise spreadsheet creation obj'
);
ok($obj->create_spreadsheet,'Create a spreadsheet with multiple input files');

ok( -e 'example.csv', 'spreadsheet file exists');
my  $actual_file_content = read_file('example.csv');
my $expected_file_content = read_file('t/data/expected_example.csv'); 
is_deeply($actual_file_content, $expected_file_content, 'Spredsheet data as expected');

unlink('example.csv');

done_testing();
