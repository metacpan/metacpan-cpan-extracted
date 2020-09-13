# vi:sw=2
use strictures 2;

use Test2::V0 qw(
  done_testing subtest E match is
  array hash field item end
);

use lib 't/lib';

use File::Path qw( remove_tree );
use YAML::Any qw( LoadFile );

# These tests are meant to explore what happens if the same column in a child
# is used to anchor two different parent relationships. Note that Composer->id
# is a FK to Artist->id.

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
      has_one => {
        composer => { Composer => 'artist_id' },
      },
    },
    Composer => {
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
        artist => { Artist => 'artist_id' },
        composer => { Composer => 'artist_id' },
      },
    },
  ]);
}

use common qw(sims_test);

sims_test "Autogenerate parents" => {
  spec => {
    Album => { name => 'bar' },
  },
  expect => {
    Artist => [ { id => 1, name => E() } ],
    Composer => [ { id => 1, artist_id => 1, name => E() } ],
    Album => [ { id => 1, artist_id => 1, name => 'bar' } ],
  },
  rv => sub { { Album => shift->{expect}{Album} } },
};

sims_test "Set parent_id explicitly" => {
  spec => [
    {
      Artist => 3,
      Composer => 3,
      Album => { name => 'bar', artist_id => 2 },
    },
    {
      hooks => {
        postprocess => sub {
          my ($source, $row) = @_;
          if ( $source->name eq 'Composer' ) {
            $row->update({artist_id => $row->id});
          }
        },
      },
    }
  ],
  expect => {
    Artist => [ map { { id => $_, name => E() } } 1..3 ],
    Composer => [ map { { id => $_, artist_id => $_, name => E() } } 1..3 ],
    Album => [ { id => 1, artist_id => 2, name => 'bar' } ],
  },
};

done_testing;
