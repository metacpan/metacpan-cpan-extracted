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
          is_nullable => 1,
        },
        city => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
          default_value => 'X',
        },
        state => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
          default_value => 'Y',
        },
      },
      primary_keys => [ 'id' ],
      unique_constraints => [
        [ 'name' ],
        [ 'city', 'state' ],
      ],
    },
  ]);
}

use common qw(sims_test Schema);

subtest "Load and retrieve a row by single-column UK" => sub {
  sims_test "Create the rows" => {
    spec => {
      Artist => [
        { name => 'Bob', state => 'A', city => 'B' },
        { name => undef, state => 'B', city => 'C' },
        { name => undef, state => 'C', city => 'D' },
      ],
    },
    expect => {
      Artist => [
        { id => 1, name => 'Bob', state => 'A', city => 'B' },
        { id => 2, name => undef, state => 'B', city => 'C' },
        { id => 3, name => undef, state => 'C', city => 'D' },
      ],
    },
    addl => {
      duplicates => {},
    },
  };

  sims_test "Find the row we can find" => {
    deploy => 0,
    loaded => {
      Artist => 3,
    },
    spec => { Artist => { name => 'Bob' } },
    rv => {
      Artist => { id => 1, name => 'Bob', state => 'A', city => 'B' },
    },
    addl => {
      duplicates => {
        Artist => [{
          criteria => [{
            name => 'Bob',
          }],
          found => E(),
        }],
      },
    },
  };

  sims_test "Don't find a row via undef" => {
    deploy => 0,
    loaded => {
      Artist => 3,
    },
    spec => { Artist => { name => undef } },
    rv => {
      Artist => { id => 4, name => undef, city => 'X', state => 'Y' },
    },
  };
};

done_testing;
