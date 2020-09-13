# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing E );

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
      might_have => {
        album => { Album => 'artist_id' },
      },
    },
    Album => {
      columns => {
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
      primary_keys => [ 'artist_id' ],
      belongs_to => {
        artist => { Artist => 'artist_id' },
      },
    },
  ]);
}

use common qw(sims_test);

sims_test "parent builds a child, but we're creating a child" => {
  spec => [
    {
      Album => [
        { name => 'bar' },
      ],
    },
    {
      hooks => {
        preprocess => sub {
          my ($source, $spec) = @_;
          if ($source->name eq 'Artist') {
            $spec->{album} //= [ {} ];
          }
        },
      },
    },
  ],
  expect => {
    Artist => { id => 1, name => E() },
    Album  => { artist_id => 1, name => 'bar' },
  },
  rv => {
    Album  => { artist_id => 1, name => 'bar' },
  },
};

sims_test "child refers to parent by backref" => {
  spec => [
    {
      Artist => 1,
      Album => { artist_id => \'Artist[0].id' },
    },
  ],
  expect => {
    Artist => { id => 1, name => E() },
    Album  => { artist_id => 1, name => E() },
  },
};

sims_test "child inserts parent in preprocess" => {
  spec => [
    {
      Album => { name => 'bar' },
    },
    {
      hooks => {
        preprocess => sub {
          my ($source, $spec) = @_;
          if ($source->name eq 'Album') {
            $spec->{artist} = { name => 'foo' };
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
    Album  => { artist_id => 1, name => 'bar' },
  },
};

sims_test "child inserts parent in preprocess and uses parent's name" => {
  spec => [
    {
      Album => 1,
    },
    {
      hooks => {
        preprocess => sub {
          my ($source, $spec) = @_;
          if ($source->name eq 'Album') {
            $spec->{artist} = { name => 'foo' };
          }
        },
        before_create => sub {
          my ($source, $item) = @_;
          if ($source->name eq 'Album') {
            $item->set_value(name => $item->parent('artist')->row->name);
          }
        },
      },
    },
  ],
  expect => {
    Artist => { id => 1, name => 'foo' },
    Album  => { artist_id => 1, name => 'foo' },
  },
  rv => {
    Album  => { artist_id => 1, name => 'foo' },
  },
};

done_testing;
