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
        artist => { Artist => 'artist_id' },
      },
      has_many => {
        tracks => { Track => 'album_id' },
      },
    },
    Track => {
      columns => {
        id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
        },
        album_id => {
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
        album => { Album => 'album_id' },
      },
    },
  ]);
}

use common qw(sims_test Schema);

sims_test "Reference an attribute of a parent object" => {
  spec => {
    Artist => { name => 'foo' },
    Album => { artist => \'Artist[0]', name => \'Artist[0].name' },
  },
  expect => {
    Artist => { id => 1, name => 'foo' },
    Album => { id => 1, artist_id => 1, name => 'foo' },
  },
};

sims_test "Reference an attribute of a grandparent object" => {
  spec => {
    Artist => {
      name => 'They Might Be Giants',
    },
    Album => {
      artist => \'Artist[0]',
      name => 'Flood',
    },
    Track => {
      album => \'Album[0]',
      name => \'Album[0].artist.name',
    },
  },
  expect => {
    Artist => { id => 1, name => 'They Might Be Giants' },
    Album => { id => 1, artist_id => 1, name => 'Flood' },
    Track => { id => 1, album_id => 1, name => 'They Might Be Giants' },
  },
};

sims_test "Fail to reference a method of a backreference" => {
  spec => {
    Artist => { name => 'foo' },
    Album => { artist => \'Artist[0]', name => \'Artist[0]' },
  },
  dies => qr/No method to call at Album->name => Artist\[0\]/,
};

done_testing;
