# vi:sw=2
use strictures 2;

use Test::More;

use lib 't/lib';

BEGIN {
  use loader qw(build_schema);
  build_schema([
    Artist => {
      table => 'artists',
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
        mansions => { Mansion => 'artist_id' },
      },
    },
    Album => {
      table => 'albums',
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
    },
    Mansion => {
      table => 'mansions',
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
    },
  ]);
}

use common qw(sims_test);

sims_test "Specify child->parent->other_child" => {
  spec => {
    Album => [
      {
        name => 'Wonder Years',
        artist => {
          name => 'Superstar',
          mansions => [
            { name => 'My Place' },
          ],
        },
      }
    ],
  },
  expect => {
    Artist => { id => 1, name => 'Superstar' },
    Album => { id => 1, name => 'Wonder Years', artist_id => 1 },
    Mansion => { id => 1, name => 'My Place', artist_id => 1 },
  },
  rv => sub { { Album => shift->{expect}{Album} } },
};

sims_test "Create row using existing parent which would have had a different child" => {
  spec => {
    Artist => [
      { name => 'Superstar' },
    ],
    Album => [
      {
        name => 'Wonder Years',
        artist => {
          name => 'Superstar',
          mansions => [
            { name => 'My Place' },
          ],
        },
      }
    ],
  },
  expect => {
    Artist => { id => 1, name => 'Superstar' },
    Album => { id => 1, name => 'Wonder Years', artist_id => 1 },
    #Mansion => { id => 1, name => 'My Place', artist_id => 1 },
  },
  rv => {
    Artist => { id => 1, name => 'Superstar' },
    Album => { id => 1, name => 'Wonder Years', artist_id => 1 },
  },
};

done_testing;
