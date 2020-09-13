# vi:sw=2
use strictures 2;

use Test2::V0 qw(
  done_testing subtest E match is
  array hash field item end
);

use lib 't/lib';

use File::Path qw( remove_tree );
use YAML::Any qw( LoadFile );

# Needs the following where-clause in the has_many()
#   {
#     where          => { 'me.type' => 'artist' },
#     cascade_delete => 0,
#     cache_for      => 1,
#   }

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
        preferences => { Preference => 'type_id' },
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
        artist => { Artist => 'artist_id' },
      },
      has_many => {
        preferences => { Preference => 'type_id' },
      },
    },
    Preference => {
      columns => {
        id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
        },
        type => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
        },
        type_id => {
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
        [ 'type', 'type_id', 'name' ],
      ],
    },
  ]);
}

use common qw(sims_test);

sims_test "Auto-generate a child with a value" => {
  spec => {
    Artist => {
      name => 'foo',
      preferences => [ { type => 'artist', name => 'bar' } ],
    },
  },
  expect => {
    Artist => [ { id => 1, name => 'foo' } ],
    Preference => [ { id => 1, type => 'artist', name => 'bar', type_id => 1 } ],
  },
  rv => sub { { Artist => shift->{expect}{Artist} } },
};

sims_test "Auto-generate a grandchild with a value" => {
  spec => {
    Artist => {
      name => 'foo',
      albums => {
        name => 'foo2',
        preferences => [ { type => 'album', name => 'bar' } ],
      },
    },
  },
  expect => {
    Artist => [ { id => 1, name => 'foo' } ],
    Album => [ { id => 1, artist_id => 1, name => 'foo2' } ],
    Preference => [ { id => 1, type => 'album', name => 'bar', type_id => 1 } ],
  },
  rv => sub { { Artist => shift->{expect}{Artist} } },
};

sims_test "Preference backreference to parent" => {
  spec => [
    {
      Artist => {
        name => 'foo',
      },
      Preference => {
        type => 'artist',
        type_id => \'Artist[0].id',
        name => 'bar',
      },
    },
    {
      toposort => {
        add_dependencies => {
          Preference => [
            'Artist', 'Album',
          ],
        },
      },
    },
  ],
  expect => {
    Artist => [ { id => 1, name => 'foo' } ],
    Preference => [ { id => 1, type => 'artist', name => 'bar', type_id => 1 } ],
  },
};

done_testing;
