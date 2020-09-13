# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing );

use lib 't/lib';

use DBIx::Class::Sims;

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
        name => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
          sim => { value => 'abcd' },
        },
      },
      primary_keys => [ 'id' ],
    },
  ]);
}

use Test::DBIx::Class qw(:resultsets);

use common qw(sims_test);

sims_test "Trigger the PK autoincrement warning" => {
  spec => {
    Artist => { id => 2 },
  },
  warning => qr/Primary-key autoincrement columns should not be hardcoded in tests \(Artist.id = 2\)/,
  expect => {
    Artist => { id => 2, name => 'abcd' },
  },
  rv => sub { { Artist => shift->{expect}{Artist} } },
};

sims_test "allow_pk_set_value silences the warning" => {
  spec => [
    { Artist => { id => 2 } },
    { allow_pk_set_value => 1 },
  ],
  expect => {
    Artist => { id => 2, name => 'abcd' },
  },
  rv => sub { { Artist => shift->{expect}{Artist} } },
};

sims_test "allow_pk_set_value in the __META__ silences the warning" => {
  spec => [
    { Artist => { id => 2, __META__ => { allow_pk_set_value => 1 } } },
  ],
  expect => {
    Artist => { id => 2, name => 'abcd' },
  },
  rv => sub { { Artist => shift->{expect}{Artist} } },
};

done_testing;
