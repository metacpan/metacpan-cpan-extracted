#!/usr/bin/env perl
use Moose;
use Data::Dumper;
use File::Slurp;
use File::Find;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, './t/lib' ) }
with 'TestHelper';

BEGIN {
    use Test::Most;
    use_ok('Bio::AutomatedAnnotation::CommandLine::GeneNameOccurances');
}
my $script_name = 'Bio::AutomatedAnnotation::CommandLine::GeneNameOccurances';

my %scripts_and_expected_files = (
    't/data/example_annotation.gff' =>
      [ 'gene_occurances_output.csv', 't/data/expected_gene_occurances_output_one_file.csv' ],
    't/data/example_annotation.gff t/data/empty_annotation.gff' =>
      [ 'gene_occurances_output.csv', 't/data/expected_gene_occurances_output_two_files.csv' ],
    't/data/example_annotation.gff t/data/copy_of_example_annotation.gff t/data/empty_annotation.gff t/data/different_to_example_annotation.gff'
      => [ 'gene_occurances_output.csv', 't/data/expected_gene_occurances_output_all_files.csv' ],
    '-o different_output_filename t/data/example_annotation.gff' =>
      [ 'different_output_filename', 't/data/expected_gene_occurances_output_one_file.csv' ],
);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

done_testing();

