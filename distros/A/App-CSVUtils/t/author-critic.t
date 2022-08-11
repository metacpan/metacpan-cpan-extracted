#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/App/CSVUtils.pm','lib/App/CSVUtils/Manual/Cookbook.pod','script/csv-add-field','script/csv-avg','script/csv-concat','script/csv-convert-to-hash','script/csv-csv','script/csv-delete-fields','script/csv-dump','script/csv-each-row','script/csv-fill-template','script/csv-freqtable','script/csv-get-cells','script/csv-grep','script/csv-info','script/csv-list-field-names','script/csv-lookup-fields','script/csv-map','script/csv-munge-field','script/csv-munge-row','script/csv-replace-newline','script/csv-select-fields','script/csv-select-row','script/csv-setop','script/csv-sort','script/csv-sort-fields','script/csv-sort-rows','script/csv-split','script/csv-sum','script/csv-transpose','script/csv2csv','script/csv2ltsv','script/csv2td','script/csv2tsv','script/dump-csv','script/tsv2csv'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
