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
        artist_id => {
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
      primary_keys => [ 'artist_id' ],
      belongs_to => {
        artist => { Artist => 'artist_id' },
      },
      has_one => {
        track => { Track => 'artist_id' },
      },
    },
    Track => {
      columns => {
        artist_id => {
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
      primary_keys => [ 'artist_id' ],
      belongs_to => {
        album => { Album => 'artist_id' },
      },
    },
  ]);
}

use common qw(sims_test);

sims_test "create child in postprocess" => {
  spec => [
    {
      Artist => { name => 'foo' },
    },
    {
      hooks => {
        postprocess => sub {
          my ($source, $row) = @_;

          if ($source->name eq 'Artist') {
            my $rs = $source->schema->resultset('Album');
            unless ($rs->find($row->id)) {
              $rs->create({
                artist_id => $row->id,
                name => 'bar',
              });
            }
          }
        },
      },
    },
  ],
  expect => {
    Artist => { id => 1, name => 'foo' },
    Album  => { artist_id => 1, name => 'bar' },
  },
  rv => {
    Artist => { id => 1, name => 'foo' },
  },
};

sims_test "create grandchild via child from postprocess" => {
  spec => [
    {
      Artist => { name => 'foo' },
      # This retrieves the existing row and creates the child rows. This way,
      # you can operate on a thing that already exists.
      Album => {
        artist_id => \'Artist[0].id',
        track => { name => 'music' },
      },
    },
    {
      allow_pk_set_value => 1,
      hooks => {
        postprocess => sub {
          my ($source, $row) = @_;

          if ($source->name eq 'Artist') {
            my $rs = $source->schema->resultset('Album');
            unless ($rs->find($row->id)) {
              $rs->create({
                artist_id => $row->id,
                name => 'bar',
              });
            }
          }
        },
      },
    },
  ],
  expect => {
    Artist => { id => 1, name => 'foo' },
    Album  => { artist_id => 1, name => 'bar' },
    Track  => { artist_id => 1, name => 'music' },
  },
  rv => {
    Artist => { id => 1, name => 'foo' },
    Album  => { artist_id => 1, name => 'bar' },
  },
};

done_testing;
