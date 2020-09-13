# vi:sw=2
use strictures 2;

use Test2::V0 qw(
  done_testing subtest E is
  array hash field item end bag
);

use lib 't/lib';

use File::Path qw( remove_tree );
use YAML::Any qw( LoadFile );

BEGIN {
  use loader qw(build_schema);
  build_schema([
    Person => {
      columns => {
        person_id => {
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
      primary_keys => [ 'person_id' ],
      might_have => {
        artist => { Artist => 'person_id' },
        singer => { Singer => 'person_id' },
      },
    },
    Artist => {
      columns => {
        person_id => {
          data_type => 'int',
          is_nullable => 0,
        },
        stage_name => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
        },
      },
      primary_keys => [ 'person_id' ],
      belongs_to => {
        person => { Person => 'person_id' },
      },
      might_have => {
        singer => { Singer => 'person_id' },
      },
    },
    Singer => {
      columns => {
        person_id => {
          data_type => 'int',
          is_nullable => 0,
        },
        genre => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
        },
      },
      primary_keys => [ 'person_id' ],
      belongs_to => {
        person => { Person => 'person_id' },
        artist => { Artist => 'person_id' },
      },
    },
  ]);
}

use common qw(sims_test Schema);

sims_test "Specifying one Singer parent breaks things" => {
  spec => {
    # Failure is "2.person.name != 'Bob'". This is because the artist rel is
    # handled first, thus fixing the person_id. Instead, the person rel should
    # be handled first for 2 because it's specified.
    Singer => [
      { 'artist.stage_name' => 'A', genre => 'country' },
      { 'person.name' => 'Bob', genre => 'metal' },
    ],
  },
  expect => {
    Person => [
      { person_id => 1, name => E() },
      { person_id => 2, name => 'Bob' },
    ],
    Artist => [
      { person_id => 1, stage_name => 'A' },
      { person_id => 2, stage_name => E() },
    ],
    Singer => [
      { person_id => 1, genre => 'country' },
      { person_id => 2, genre => 'metal' },
    ],
  },
  rv => sub { { Singer => shift->{expect}{Singer} } },
};

done_testing;
