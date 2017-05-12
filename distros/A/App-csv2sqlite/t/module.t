use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use C2STests;

my @chips_rows = (
  ['bbq', ' small'],
  ['plain', 'large'],
  ['spicy', 'medium'],
);

test_import('basic', {
  csvs => [qw( chips.csv pretzels.csv )],
  args => [],
  rs   => {
    'SELECT flavor, size FROM chips ORDER BY flavor' => [
      @chips_rows,
    ],
    'SELECT shape, "flavor|color" FROM pretzels ORDER BY shape' => [
      ['knot', 'doughy|golden brown'],
      ['ring', 'salty|brown'],
      ['rod', 'salty| brown'],
    ]
  },
});

test_import('csv_opts: alternate separator', {
  csvs => [qw( pretzels.csv )],
  args => [
    -o => 'sep_char=|',
    -o => 'allow_whitespace=1',
  ],
  attr => {
    csv_options => {
      sep_char => '|',
      allow_whitespace => 1,
    }
  },
  rs   => {
    'SELECT "shape,flavor", "color" FROM pretzels ORDER BY "shape,flavor"' => [
      ['knot,doughy', 'golden brown'],
      ['ring,salty', 'brown'],
      ['rod,salty', 'brown'],
    ]
  },
});

{
  my $exp_rows = [ @chips_rows ];
  my $test_args = {
    desc => 'basic',
    csvs => [qw( chips.csv )],
    args => [],
    rs   => {
      'SELECT flavor, size FROM chips ORDER BY flavor' => $exp_rows,
    },
  };

  test_import('success on the first run', {
    %$test_args,
    keep_db => 1,
  });

  test_import('reloading into the same db fails', {
    %$test_args,
    # NOTE: this message could easily change and we may need to be more robust
    error => qr/table "chips" already exists/,
    keep_db => 1,
  });

  # double the rows (in the right order) but keep the reference
  splice(@$exp_rows, 0, 3, map { ($_, $_) } @chips_rows);

  test_import('disable creation in loader to import more rows', {
    %$test_args,
    args => [ '--loader-opt=create=0' ],
    attr => {
      loader_options => {
        create => 0,
      },
    },
    keep_db => 0,
  });
}

done_testing;
