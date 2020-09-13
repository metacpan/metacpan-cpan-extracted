# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing E );

use lib 't/lib';

BEGIN {
  use loader qw(build_schema);
  build_schema([
    House => {
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
        artists => { Artist => 'house_id' },
      },
    },
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
        house_id => {
          data_type => 'int',
          is_nullable => 0,
        },
      },
      primary_keys => [ 'id' ],
      belongs_to => {
        house => { House => 'house_id' },
      },
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
        name => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
        },
        artist_id => {
          data_type => 'int',
          is_nullable => 0,
        },
        studio_id => {
          data_type => 'int',
          is_nullable => 0,
        },
      },
      primary_keys => [ 'id' ],
      belongs_to => {
        artist => { Artist => 'artist_id' },
        studio => { Studio => 'studio_id' },
      },
    },
    Track => {
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
        album_id => {
          data_type => 'int',
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

sims_test "Autogenerate ancestors (2 lineages)" => {
  spec => {
    Track => 1,
  },
  expect => {
    House => { id => 1, name => E() },
    Artist => { id => 1, name => E(), house_id => 1 },
    Studio => { id => 1, name => E() },
    Album => { id => 1, name => E(), artist_id => 1, studio_id => 1 },
    Track => { id => 1, name => E(), album_id => 1 },
  },
  rv => sub { { Track => shift->{expect}{Track} } },
};

sims_test "Autogenerate 3 parent-layers deep" => {
  spec => {
    Track => { 'album.artist.house.name' => 'Mansion' },
  },
  expect => {
    House => { id => 1, name => 'Mansion' },
    Artist => { id => 1, name => E(), house_id => 1 },
    Studio => { id => 1, name => E() },
    Album => { id => 1, name => E(), artist_id => 1, studio_id => 1 },
    Track => { id => 1, name => E(), album_id => 1 },
  },
  rv => sub { { Track => shift->{expect}{Track} } },
};

sims_test "Consume a specified 3 parent-layers deep" => {
  load_sims => sub {
    my $schema = shift;

    $schema->load_sims({
      House => [
        { name => 'Mansion2' },
        { name => 'Mansion' },
      ],
    });
    return $schema->load_sims({
      Track => { 'album.artist.house.name' => 'Mansion' },
    });
  },
  expect => {
    House => [
      { name => 'Mansion2' },
      { name => 'Mansion' },
    ],
    Artist => { id => 1, name => E(), house_id => 2 },
    Studio => { id => 1, name => E() },
    Album => { id => 1, name => E(), artist_id => 1, studio_id => 1 },
    Track => { id => 1, name => E(), album_id => 1 },
  },
  rv => sub { { Track => shift->{expect}{Track} } },
};

sims_test "Autogenerate 2 parent-layers deep" => {
  spec => {
    Track => { 'album.artist.name' => 'John' },
  },
  expect => {
    House => { id => 1, name => E() },
    Artist => { id => 1, name => 'John', house_id => 1 },
    Studio => { id => 1, name => E() },
    Album => { id => 1, name => E(), artist_id => 1, studio_id => 1 },
    Track => { id => 1, name => E(), album_id => 1 },
  },
  rv => sub { { Track => shift->{expect}{Track} } },
};

sims_test "Create a parent with a child and other parent autogenerate" => {
  spec => {
    Artist => { albums => 1 },
  },
  expect => {
    House => { id => 1, name => E() },
    Artist => { id => 1, name => E(), house_id => 1 },
    Studio => { id => 1, name => E() },
    Album => { id => 1, name => E(), artist_id => 1, studio_id => 1 },
  },
  rv => sub { { Artist => shift->{expect}{Artist} } },
};

sims_test "Create 2 parents, each specifying same child, only 1 child" => {
  spec => {
    Artist => [ { albums => [ { name => 'child1' } ] } ],
    Studio => [ { albums => [ { name => 'child1' } ] } ],
  },
  expect => {
    House => { id => 1, name => E() },
    Artist => { id => 1, name => E(), house_id => 1 },
    Studio => { id => 1, name => E() },
    Album => { id => 1, name => 'child1', artist_id => 1, studio_id => 1 },
  },
  rv => sub {
    my $t = shift;
    {
      Artist => $t->{expect}{Artist},
      Studio => $t->{expect}{Studio},
    },
  },
};

done_testing;
