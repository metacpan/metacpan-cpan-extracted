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
    use_ok('Bio::AutomatedAnnotation::CommandLine::ParseGenesFromGFFs');
}

my $obj;

my $script_name = 'Bio::AutomatedAnnotation::CommandLine::ParseGenesFromGFFs';

my %scripts_and_expected_files = (
    '-g yfnB t/data/example_annotation.gff' => [
        'output.yfnB.fa', 't/data/expected_aa_output.yfnB.fa'
    ],
    '-g yfnB -n t/data/example_annotation.gff t/data/empty_annotation.gff' => [
        'output.yfnB.fa', 't/data/expected_output.yfnB.fa'
    ],
    '-g hypothetical -n -p t/data/example_annotation.gff t/data/empty_annotation.gff' => [
        'output.hypothetical.fa', 't/data/expected_output.hypothetical.fa'
    ],
    '-g yfnB -o output_filename.fa t/data/example_annotation.gff t/data/empty_annotation.gff' => [
        'output_filename.fa', 't/data/expected_aa_output.yfnB.fa'
    ],
    '-g 16S -p -n t/data/example_annotation.gff' => [
        'output.16S.fa', 't/data/expected_output.16SribosomalRNA.fa'
    ],
);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

done_testing();



