use strict;
use warnings;
use Test::More;
use Test::Snapshot;
use Text::CSV qw(csv);
use Data::Prepare qw(
  cols_non_empty non_unique_cols
  make_pk_map pk_col_counts key_to_index pk_match
  chop_lines chop_cols header_merge pk_insert
);

my $data = data("CoreHouseholdIndicators");
chop_lines([0, (-1) x 5], $data);
is_deeply_snapshot $data, 'chop_lines';

is_deeply_snapshot [ cols_non_empty($data) ], 'cols_non_empty';

chop_cols([0, 2, 4, 7, 10, 13, 16, 19, 21, 22, 23, 25, 26, 29, 32], $data);
is_deeply_snapshot $data, 'chop_cols';

my $merge_spec = [
  { line => 1, from => 'up', fromspec => 'lastnonblank', to => 'self', matchto => 'HH', do => [ 'overwrite' ] },
  { line => 1, from => 'self', matchfrom => '.', to => 'down', do => [ 'prepend', ' ' ] },
  { line => 2, from => 'self', fromspec => 'left', to => 'self', matchto => 'Year', do => [ 'prepend', '/' ] },
  { line => 2, from => 'self', fromspec => 'literal:Country', to => 'self', tospec => 'index:0', do => [ 'overwrite' ] },
];
header_merge($merge_spec, $data);
chop_lines([0, 0], $data);
is_deeply_snapshot $data, 'header_merge';

my @alt_keys = (
  'ISO3166-1-Alpha-2',
  'UNTERM English Short',
  'UNTERM English Formal',
  'official_name_en',
  'CLDR display name',
);
my $pk_data = data('country-codes');
my $pk_map = make_pk_map($pk_data, 'ISO3166-1-Alpha-3', \@alt_keys);
is_deeply_snapshot $pk_map, 'make_pk_map';

is_deeply_snapshot [ pk_col_counts($data, $pk_map) ], 'pk_col_counts';

my $key_index = key_to_index($data->[0])->{Country};
my @stopwords = qw(islands china northern);
is_deeply_snapshot [
  map [ $_->[$key_index], pk_match($_->[$key_index], $pk_map, \@stopwords) ], @$data[1..$#$data]
], 'pk_match';

pk_insert({
  column_heading => 'ISO3CODE',
  local_column => 'Country',
  pk_column => 'official_name_en',
  use_fallback => 1,
}, $data, $pk_map, \@stopwords);
is_deeply_snapshot $data, 'pk_insert';

my $small_data = [
  [ '', 'Proportion of households with', '', '', '' ],
  [ '', '(HH1)', 'Year', '(HH2)', 'Year' ],
  [ '', 'Radio', 'of data', 'TV', 'of data' ],
];
header_merge($merge_spec, $small_data);
chop_lines([0, 0], $small_data);
is_deeply $small_data, [
  [
    'Country',
    'Proportion of households with Radio',
    'Proportion of households with Radio/Year of data',
    'Proportion of households with TV',
    'Proportion of households with TV/Year of data'
  ]
] or diag explain $small_data;

$small_data = [
  [ '', 'Latest', 'All', 'Gender', '' ],
  [ 'Economy name', 'year', 'Individuals', 'Male', 'Female' ],
];
header_merge([
  { line => 1, from => 'up', to => 'self', tospec => 'index:1', do => [ 'prepend', ' ' ] },
  { line => 1, from => 'up', to => 'self', tospec => 'index:2', do => [ 'prepend', ' ' ] },
], $small_data);
chop_lines([0], $small_data);
is_deeply $small_data, [
  [ 'Economy name', 'Latest year', 'All Individuals', 'Male', 'Female' ],
] or diag explain $small_data;

my $got = non_unique_cols([[qw(a b b)]]);
is_deeply $got, { b => 2 };

done_testing;

sub data { csv(in => "examples/$_[0].csv", encoding => "UTF-8") }
