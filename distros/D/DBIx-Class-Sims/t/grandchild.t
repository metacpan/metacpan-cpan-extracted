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
          sim => { value => 'abcd' },
        },
      },
      primary_keys => [ 'id' ],
      has_many => {
        albums => { Album => 'artist_id' },
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
          sim => { value => 'efgh' },
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
      table => 'tracks',
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
          sim => { value => 'ijkl' },
        },
      },
      primary_keys => [ 'id' ],
      belongs_to => {
        album => { Album => 'album_id' },
      },
    },
  ]);
}

use common qw(sims_test);

sims_test "Autogenerate grandparent" => {
  spec => {
    Track => 1,
  },
  expect => {
    Artist => { id => 1, name => 'abcd' },
    Album => { id => 1, name => 'efgh', artist_id => 1 },
    Track => { id => 1, name => 'ijkl', album_id => 1 },
  },
  rv => sub { { Track => shift->{expect}{Track} } },
};

sims_test "Create ancestors via unmet grandparent specification" => {
  load_sims => sub {
    my ($schema) = @_;
    my $rv = $schema->load_sims({
      Artist => [ map { { name => "foo$_" } } 1..4 ],
      Album  => [ map { { name => "foo$_" } } 1..4 ],
    });

    return $schema->load_sims({
      Track => { album => { artist => { name => 'bar1' } } },
    });
  },
  expect => {
    Track => { id => 1, name => 'ijkl', album_id => 5 },
  },
  rv => sub { { Track => shift->{expect}{Track} } },
};

done_testing;
