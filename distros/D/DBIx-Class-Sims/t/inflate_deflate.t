# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing );

use lib 't/lib';

use JSON qw(encode_json decode_json);

BEGIN {
  use loader qw(build_schema);
  build_schema([
    Artist => {
      columns => {
        id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
        },
        params => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 1,
        },
      },
      primary_keys => [ 'id' ],
      inflate_json => 'params',
    },
  ]);
}

use common qw(sims_test);

sims_test "Nothing provided to inflater" => {
  spec => {
    Artist => 1,
  },
  expect => {
    Artist => { id => 1 },
  },
  rv => sub { { Artist => shift->{expect}{Artist} } },
};

sims_test "Simple hash provided to inflater" => {
  spec => {
    Artist => {
      params => { 'hello' => 'world' },
    },
  },
  expect => {
    Artist => { id => 1, params => { 'hello' => 'world' } },
  },
  rv => sub { { Artist => shift->{expect}{Artist} } },
};

done_testing;
