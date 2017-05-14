#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::AutomatedAnnotation::GeneNamesFromGFF');
}

my $obj;

ok($obj = Bio::AutomatedAnnotation::GeneNamesFromGFF->new(
     gff_file     => 't/data/example_annotation.gff',
   ),'initialse default object with a real annotation file');
my @actual_gene_names = sort keys %{$obj->gene_names};
is_deeply(\@actual_gene_names, ['arcC1','argF','hly','speH','yfnB',], 'gene names correctly extracted');

ok($obj = Bio::AutomatedAnnotation::GeneNamesFromGFF->new(
     gff_file   => 't/data/empty_annotation.gff'
   ),'initialse default object with an empty annotation file');
@actual_gene_names = sort keys %{$obj->gene_names};
is_deeply(\@actual_gene_names, [], 'no gene names extracted because the annotation is empty');

done_testing();
