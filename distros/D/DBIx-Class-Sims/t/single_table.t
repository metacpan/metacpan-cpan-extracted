# vi:sw=2
use strictures 2;

use Test::More;
use Test::Deep;

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
        hat_color => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 1,
          sim => { value => 'purple' },
        },
      },
      primary_keys => [ 'id' ],
    },
  ]);
}

use common qw(sims_test Schema);

sims_test "A single row succeeds" => {
  spec => {
    Artist => [
      { name => 'foo' },
    ],
  },
  expect => {
    Artist => { id => 1, name => 'foo', hat_color => 'purple' },
  },
};

sims_test "Load multiple rows" => {
  spec => {
    Artist => [
      { name => 'foo' },
      { name => 'bar', hat_color => 'red' },
    ],
  },
  expect => {
    Artist => [
      { id => 1, name => 'foo', hat_color => 'purple' },
      { id => 2, name => 'bar', hat_color => 'red' },
    ],
  },
};

sims_test "Pass in a sim_type" => {
  spec => {
    Artist => { name => { value => 'george' } },
  },
  expect => {
    Artist => { id => 1, name => 'george', hat_color => 'purple' },
  },
};

Schema->source('Artist')->column_info('name')->{sim}{value} = 'george';

sims_test "Override a sim_type with a HASHREFREF (deprecated)" => {
  spec => {
    Artist => { name => \{ value => 'bill' } },
  },
  expect => {
    Artist => { id => 1, name => 'bill', hat_color => 'purple' },
  },
  warning => qr/DEPRECATED: Use a regular HASHREF/,
};

sims_test "Override a sim_type with a HASHREF" => {
  spec => {
    Artist => { name => { value => 'bill' } },
  },
  expect => {
    Artist => { id => 1, name => 'bill', hat_color => 'purple' },
  },
};

sims_test "Set 1 for number of rows" => {
  spec => {
    Artist => 1,
  },
  expect => {
    Artist => { id => 1, name => 'george', hat_color => 'purple' },
  },
};

sims_test "Set 2 for number of rows" => {
  spec => {
    Artist => 2,
  },
  expect => {
    Artist => [
      { id => 1, name => 'george', hat_color => 'purple' },
      { id => 2, name => 'george', hat_color => 'purple' },
    ],
  },
};

sims_test "Provide a hashref for rows" => {
  spec => {
    Artist => 1,
  },
  expect => {
    Artist => { id => 1, name => 'george', hat_color => 'purple' },
  },
};

sims_test "A scalarref is unknown" => {
  spec => {
    Artist => \"",
  },
  warning => qr/^Skipping Artist - I don't know what to do!/,
  expect => {},
};

Schema->source('Artist')->column_info('name')->{sim}{value} = [ 'george', 'bill' ];

sims_test "See that a set of values works" => {
  spec => {
    Artist => 1,
  },
  expect => {
    Artist => { id => 1, name => any(qw/george bill/), hat_color => 'purple' },
  },
};

delete Schema->source('Artist')->column_info('name')->{sim}{value};
Schema->source('Artist')->column_info('name')->{sim}{values} = [ 'george', 'bill' ];

sims_test "See that a set of values works" => {
  spec => {
    Artist => 1,
  },
  expect => {
    Artist => { id => 1, name => any(qw/george bill/), hat_color => 'purple' },
  },
};

delete Schema->source('Artist')->column_info('hat_color')->{sim}{value};
Schema->source('Artist')->column_info('hat_color')->{sim}{null_chance} = 1;

sims_test "See that null_chance=1 works" => {
  spec => {
    Artist => 1,
  },
  expect => {
    Artist => { id => 1, name => any(qw/george bill/), hat_color => undef },
  },
};

done_testing;
