# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing subtest E match );

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
        hat_color => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 1,
        },
      },
      primary_keys => [ 'id' ],
      unique_constraints => [
        [ 'name' ],
      ],
    },
  ]);
}

use common qw(sims_test Schema);

subtest "Load and retrieve a row by single-column PK" => sub {
  sims_test "Create the row" => {
    spec => {
      Artist => {
        name => 'Bob',
        hat_color => 'purple',
      },
    },
    expect => {
      Artist => { id => 1, name => 'Bob', hat_color => 'purple' },
    },
    addl => {
      duplicates => {},
    },
  };

  sims_test "Find the row" => {
    deploy => 0,
    loaded => {
      Artist => 1,
    },
    spec => [
      { Artist => { id => 1 } },
      { allow_pk_set_value => 1 },
    ],
    expect => {
      Artist => { id => 1, name => 'Bob', hat_color => 'purple' },
    },
    addl => {
      duplicates => {
        Artist => [{
          criteria => [{
            id => 1,
          }],
          found => E(),
        }],
      },
    },
  };
};

subtest "Load and retrieve a row by single-column UK" => sub {
  sims_test "Create the row" => {
    spec => {
      Artist => {
        name => 'Bob',
        hat_color => 'purple',
      },
    },
    expect => {
      Artist => { id => 1, name => 'Bob', hat_color => 'purple' },
    },
    addl => {
      duplicates => {},
    },
  };

  sims_test "Find the row" => {
    deploy => 0,
    loaded => {
      Artist => 1,
    },
    spec => [
      { Artist => { name => 'Bob' } },
    ],
    expect => {
      Artist => { id => 1, name => 'Bob', hat_color => 'purple' },
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
};

subtest "Fail because a spec matches different rows in each UK" => sub {
  sims_test "Create the row" => {
    spec => {
      Artist => [
        {
          name => 'Bob',
          hat_color => 'purple',
        },
        {
          name => 'Not Bob',
          hat_color => 'red',
        },
      ],
    },
    expect => {
      Artist => [
        { id => 1, name => 'Bob', hat_color => 'purple' },
        { id => 2, name => 'Not Bob', hat_color => 'red' },
      ],
    },
    addl => {
      duplicates => {},
    },
  };

  sims_test "Fail to find the row" => {
    deploy => 0,
    loaded => {
      Artist => 2,
    },
    spec => [
      { Artist => { id => 1, name => 'Not Bob' } },
      { allow_pk_set_value => 1 },
    ],
    dies => qr/Rows found by multiple unique constraints/,
  };
};

sims_test "Set sims value in unique column" => {
  spec => {
    Artist => { name => { type => 'us_firstname' } },
  },
  expect => {
    Artist => { id => 1, name => match(qr/./), hat_color => undef },
  },
};

done_testing;
