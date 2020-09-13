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
        },
      },
      primary_keys => [ 'id' ],
    },
  ], {
    sims_component => 0,
  });
}

use Test::DBIx::Class qw(:resultsets);

DBIx::Class::Sims->add_sim(
  Schema, Artist => (
    name => { value => 'abcd' },
  ),
);

use common qw(sims_test);

sims_test "Load an artist with add_sim()" => {
  as_class_method => 1,
  spec => {
    Artist => 1,
  },
  expect => {
    Artist => { id => 1, name => 'abcd' },
  },
  rv => sub { { Artist => shift->{expect}{Artist} } },
};

done_testing;
