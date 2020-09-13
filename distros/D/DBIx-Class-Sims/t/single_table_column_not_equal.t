# vi:sw=2
use strictures 2;

use Test2::V0 qw(
  done_testing match
);

use lib 't/lib';

use File::Path qw( remove_tree );
use YAML::Any qw( LoadFile );

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
        fruit => {
          data_type => 'varchar',
          size => 128,
          sim => {
            values => [qw( apple pear banana )],
          },
        },
      },
      primary_keys => [ 'id' ],
    },
  ]);
}

use common qw(sims_test Schema);

# These involve addressing questions of what happens randomly. So, run these
# tests 100 times each.
for (1..100) {
  sims_test "A single item to avoid" => {
    spec => {
      Artist => [
        {
          fruit => { value_not => 'apple' },
        },
      ],
    },
    expect => {
      Artist => { id => 1, fruit => match(qr/pear|banana/) },
    },
  };

  sims_test "An array of things to avoid" => {
    spec => {
      Artist => [
        {
          fruit => { value_not => [qw( apple pear )] },
        },
      ],
    },
    expect => {
      Artist => { id => 1, fruit => 'banana' },
    },
  };

  sims_test "An array of things to avoid (in plural)" => {
    spec => {
      Artist => [
        {
          fruit => { values_not => [qw( apple pear )] },
        },
      ],
    },
    expect => {
      Artist => { id => 1, fruit => 'banana' },
    },
  };

  sims_test "Die if nothing matches" => {
    spec => {
      Artist => [
        {
          fruit => { value_not => [qw( apple pear banana )] },
        },
      ],
    },
    dies => qr/Cannot find a value for Artist.fruit after 25 tries/,
  };

  sims_test "A function to avoid" => {
    spec => {
      Artist => [
        {
          fruit => { value_not => sub {
            my ($v) = @_;
            return $v eq 'apple';
          } },
        },
      ],
    },
    expect => {
      Artist => { id => 1, fruit => match(qr/pear|banana/) },
    },
  };
}

# TODO:
# * a regex to avoid
# * a list of regexes to avoid
#
# Consider:
# * a regex of things to generate?

done_testing;
