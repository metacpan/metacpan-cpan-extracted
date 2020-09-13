# vi:sw=2
use strictures 2;

use Test2::V0 qw( subtest done_testing );

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
      unique_constraints => [
        [ 'artist_id' ],
      ],
      belongs_to => {
        artist => { Artist => 'artist_id' },
      },
    },
  ]);
}

use common qw(sims_test Schema);

subtest "Create a unique parent" => sub {
  sims_test "Create a parent" => {
    spec => {
      Album => { name => 'foo' },
    },
    expect => {
      Album => { id => 1, artist_id => 1, name => 'foo' },
    },
  };

  sims_test "Create the second parent" => {
    deploy => 0,
    loaded => {
      Artist => 1,
      Album  => 1,
    },
    spec => {
      Album => { name => 'bar' },
    },
    expect => {
      Album => [
        { id => 1, artist_id => 1, name => 'foo' },
        { id => 2, artist_id => 2, name => 'bar' },
      ],
    },
    rv => {
      Album => { id => 2, artist_id => 2, name => 'bar' },
    },
  };
};

done_testing;
