# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing );

use lib 't/lib';

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
      has_many => {
        albums => { Album => 'artist_id' },
      },
    },
    Album => {
      columns => {
        id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
        },
        artist_id => {
          data_type => 'int',
          is_nullable => 0,
        },
        name => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
        },
      },
      primary_keys => [ 'id' ],
      belongs_to => {
        artist => { Artist => 'sub {
          my $args = shift;
          {"$args->{foreign_alias}.id" => "$args->{self_alias}.artist_id"}
        }' },
      },
    },
  ]);
}

use common qw(sims_test Schema);

sims_test "Create a child via rel by subroutine" => {
  spec => {
    Artist => { name => 'foo', albums => { name => 'bar' } },
  },
  expect => {
    Artist => { id => 1, name => 'foo' },
  },
};

done_testing;
