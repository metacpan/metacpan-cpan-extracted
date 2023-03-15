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

my $filenames = ['lib/App/CSVUtils.pm','lib/App/CSVUtils/Manual/Cookbook.pod','lib/App/CSVUtils/Manual/Tips.pod','lib/App/CSVUtils/csv2paras.pm','lib/App/CSVUtils/csv2td.pm','lib/App/CSVUtils/csv2vcf.pm','lib/App/CSVUtils/csv_add_fields.pm','lib/App/CSVUtils/csv_avg.pm','lib/App/CSVUtils/csv_check_cell_values.pm','lib/App/CSVUtils/csv_check_field_names.pm','lib/App/CSVUtils/csv_check_field_values.pm','lib/App/CSVUtils/csv_check_rows.pm','lib/App/CSVUtils/csv_cmp.pm','lib/App/CSVUtils/csv_concat.pm','lib/App/CSVUtils/csv_convert_to_hash.pm','lib/App/CSVUtils/csv_csv.pm','lib/App/CSVUtils/csv_delete_fields.pm','lib/App/CSVUtils/csv_dump.pm','lib/App/CSVUtils/csv_each_row.pm','lib/App/CSVUtils/csv_fill_template.pm','lib/App/CSVUtils/csv_find_values.pm','lib/App/CSVUtils/csv_freqtable.pm','lib/App/CSVUtils/csv_gen.pm','lib/App/CSVUtils/csv_get_cells.pm','lib/App/CSVUtils/csv_grep.pm','lib/App/CSVUtils/csv_info.pm','lib/App/CSVUtils/csv_intrange.pm','lib/App/CSVUtils/csv_list_field_names.pm','lib/App/CSVUtils/csv_lookup_fields.pm','lib/App/CSVUtils/csv_ltrim.pm','lib/App/CSVUtils/csv_map.pm','lib/App/CSVUtils/csv_munge_field.pm','lib/App/CSVUtils/csv_munge_row.pm','lib/App/CSVUtils/csv_pick_fields.pm','lib/App/CSVUtils/csv_pick_rows.pm','lib/App/CSVUtils/csv_quote.pm','lib/App/CSVUtils/csv_replace_newline.pm','lib/App/CSVUtils/csv_rtrim.pm','lib/App/CSVUtils/csv_select_fields.pm','lib/App/CSVUtils/csv_select_rows.pm','lib/App/CSVUtils/csv_setop.pm','lib/App/CSVUtils/csv_shuf_fields.pm','lib/App/CSVUtils/csv_shuf_rows.pm','lib/App/CSVUtils/csv_sort_fields.pm','lib/App/CSVUtils/csv_sort_rows.pm','lib/App/CSVUtils/csv_sorted_fields.pm','lib/App/CSVUtils/csv_sorted_rows.pm','lib/App/CSVUtils/csv_split.pm','lib/App/CSVUtils/csv_sum.pm','lib/App/CSVUtils/csv_transpose.pm','lib/App/CSVUtils/csv_trim.pm','lib/App/CSVUtils/csv_uniq.pm','lib/App/CSVUtils/csv_unquote.pm','lib/App/CSVUtils/paras2csv.pm','script/csv-add-fields','script/csv-avg','script/csv-check-cell-values','script/csv-check-field-names','script/csv-check-field-values','script/csv-check-rows','script/csv-cmp','script/csv-concat','script/csv-convert-to-hash','script/csv-csv','script/csv-delete-fields','script/csv-dump','script/csv-each-row','script/csv-fill-template','script/csv-find-values','script/csv-freqtable','script/csv-gen','script/csv-get-cells','script/csv-grep','script/csv-info','script/csv-intrange','script/csv-list-field-names','script/csv-lookup-fields','script/csv-ltrim','script/csv-map','script/csv-munge-field','script/csv-munge-row','script/csv-pick','script/csv-pick-fields','script/csv-pick-rows','script/csv-quote','script/csv-replace-newline','script/csv-rtrim','script/csv-select-fields','script/csv-select-rows','script/csv-setop','script/csv-shuf','script/csv-shuf-fields','script/csv-shuf-rows','script/csv-sort','script/csv-sort-fields','script/csv-sort-rows','script/csv-sorted','script/csv-sorted-fields','script/csv-sorted-rows','script/csv-split','script/csv-sum','script/csv-transpose','script/csv-trim','script/csv-uniq','script/csv-unquote','script/csv2ltsv','script/csv2paras','script/csv2td','script/csv2tsv','script/csv2vcf','script/paras2csv','script/tsv2csv'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
