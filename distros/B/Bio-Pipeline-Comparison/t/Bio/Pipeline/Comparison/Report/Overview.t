#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Pipeline::Comparison::Report::Overview');
}

my @known_to_observed_mappings = (
  {
    known_filename    => 't/data/no_overlap/known_no_overlap.vcf.gz', 
    observed_filename => 't/data/no_overlap/observed_no_overlap.vcf.gz'
  },
  {
    known_filename    => 't/data/perfect/known_perfect.vcf.gz', 
    observed_filename => 't/data/perfect/observed_perfect.vcf.gz'
  },
  {
    known_filename    => 't/data/false_negatives/known_false_negatives.vcf.gz', 
    observed_filename => 't/data/false_negatives/observed_false_negatives.vcf.gz'
  },
  {
    known_filename    => 't/data/false_positives/known_false_positives.vcf.gz', 
    observed_filename => 't/data/false_positives/observed_false_positives.vcf.gz'
  },
  {
    known_filename    => 't/data/false_positives_and_negatives/known_false_positives_and_negatives.vcf.gz', 
    observed_filename => 't/data/false_positives_and_negatives/observed_false_positives_and_negatives.vcf.gz'
  },
);


ok((my $obj = Bio::Pipeline::Comparison::Report::Overview->new(
  known_to_observed_mappings    => \@known_to_observed_mappings,
  'vcf_compare_exec'            => abs_path('bin/vcf-compare')
)),'initialise the overview for vcf comparisons');

is($obj->total_false_positives, 7, 'Total false positives');
is($obj->total_false_negatives, 8, 'Total false negatives');

done_testing();

