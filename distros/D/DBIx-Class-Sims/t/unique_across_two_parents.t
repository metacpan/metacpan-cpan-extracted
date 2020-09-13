# vi:sw=2
use strictures 2;

use Test2::V0 qw( subtest done_testing E );

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
    Studio => {
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
        albums => { Album => 'studio_id' },
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
        studio_id => {
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
        [ 'artist_id', 'studio_id' ],
      ],
      belongs_to => {
        artist => { Artist => 'artist_id' },
        studio => { Studio => 'studio_id' },
      },
    },
  ]);
}

use common qw(sims_test Schema);

subtest "Find a child across two unique parents" => sub {
  sims_test "Create a row" => {
    spec => {
      Album => { name => 'foo' },
    },
    expect => {
      Album => { id => 1, artist_id => 1, studio_id => 1, name => 'foo' },
    },
  };

  sims_test "Find the row" => {
    deploy => 0,
    loaded => {
      Artist => 1,
      Studio => 1,
      Album  => 1,
    },
    spec => {
      Album => 1,
    },
    expect => {
      Album => { id => 1, artist_id => 1, studio_id => 1, name => 'foo' },
    },
    rv => {
      Album => { id => 1, artist_id => 1, studio_id => 1, name => 'foo' },
    },
  };
};

done_testing;
