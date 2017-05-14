#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::AutomatedAnnotation::GeneNameOccurances');
}

my $obj;

ok(
    $obj = Bio::AutomatedAnnotation::GeneNameOccurances->new(
        gff_files => ['t/data/example_annotation.gff'],
    ),
    'initialse default with a single input file'
);

is_deeply(
    $obj->gene_name_hashes,
        {
            't/data/example_annotation.gff' => {
                'speH'  => 1,
                'hly'   => 1,
                'arcC1' => 1,
                'yfnB'  => 1,
                'argF'  => 1
            }
        }
,
    'gene names correctly extracted'
);

ok(
    $obj = Bio::AutomatedAnnotation::GeneNameOccurances->new(
        gff_files => ['t/data/example_annotation.gff','t/data/example_annotation.gff'],
    ),
    'initialse with the same file twice'
);

is_deeply(
    $obj->gene_name_hashes,
        {
            't/data/example_annotation.gff' => {
                'speH'  => 1,
                'hly'   => 1,
                'arcC1' => 1,
                'yfnB'  => 1,
                'argF'  => 1
            }
        },
    'gene names only once per file'
);

ok(
    $obj = Bio::AutomatedAnnotation::GeneNameOccurances->new(
        gff_files => ['t/data/empty_annotation.gff'],
    ),
    'initialse with a file which has no annotation'
);

is_deeply(
    $obj->gene_name_hashes,
        {
            't/data/empty_annotation.gff' => {

            }
        },
    'no gene names extracted because the file was empty'
);

ok(
    $obj = Bio::AutomatedAnnotation::GeneNameOccurances->new(
        gff_files => ['t/data/empty_annotation.gff','t/data/example_annotation.gff'],
    ),
    'initialse with one empty file and one file with annotation'
);

is_deeply(
    $obj->gene_name_hashes,
        {
            't/data/example_annotation.gff' => {
                'speH'  => 1,
                'hly'   => 1,
                'arcC1' => 1,
                'yfnB'  => 1,
                'argF'  => 1
            },
            't/data/empty_annotation.gff' => {
            }
        },
    'gene names correctly extracted for the mix of files'
);


ok(
    $obj = Bio::AutomatedAnnotation::GeneNameOccurances->new(
        gff_files => ['t/data/different_to_example_annotation.gff','t/data/example_annotation.gff'],
    ),
    'initialse with two annotation files with no overlap'
);

is_deeply(
    $obj->all_gene_names,
        {
                'speH'  => 1,
                'hly'   => 1,
                'arcC1' => 1,
                'yfnB'  => 1,
                'argF'  => 1,
                'another_speH'  => 1,
                'another_hly'   => 1,
                'another_arcC1' => 1,
                'another_yfnB'  => 1,
                'another_argF'  => 1

        },
    'gene names extracted and merged'
);


ok(
    $obj = Bio::AutomatedAnnotation::GeneNameOccurances->new(
        gff_files => ['t/data/copy_of_example_annotation.gff','t/data/different_to_example_annotation.gff','t/data/example_annotation.gff'],
    ),
    'initialse with two annotation files with some overlap'
);

is_deeply(
    $obj->all_gene_names,
        {
                'speH'  => 2,
                'hly'   => 2,
                'arcC1' => 2,
                'yfnB'  => 2,
                'argF'  => 2,
                'another_speH'  => 1,
                'another_hly'   => 1,
                'another_arcC1' => 1,
                'another_yfnB'  => 1,
                'another_argF'  => 1

        },
    'gene names extracted and merged with correct increments'
);

is_deeply($obj->sorted_all_gene_names, [
          'speH',
          'hly',
          'arcC1',
          'yfnB',
          'argF',
          'another_argF',
          'another_hly',
          'another_yfnB',
          'another_arcC1',
          'another_speH'
        ], 'gene names sorted by value desc');


done_testing();
