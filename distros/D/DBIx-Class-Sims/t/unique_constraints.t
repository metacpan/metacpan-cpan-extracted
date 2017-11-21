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
        first_name => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
        },
        last_name => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
        },
      },
      primary_keys => [ 'id' ],
      unique_constraints => [
        [ 'first_name', 'last_name' ],
        [ 'last_name' ],
      ],
    },
  ]);
}

use common qw(sims_test Schema);

subtest "Load and retrieve a row by multi-col UK" => sub {
  my $spec = {
    Artist => { first_name => 'Taylor', last_name => 'Swift' },
  };

  sims_test "Create the row" => {
    spec => $spec,
    expect => {
      Artist => { id => 1, first_name => 'Taylor', last_name => 'Swift' },
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
    spec => $spec,
    expect => {
      Artist => { id => 1, first_name => 'Taylor', last_name => 'Swift' },
    },
    addl => {
      duplicates => {
        Artist => [{
          criteria => {
            first_name => 'Taylor',
            last_name => 'Swift',
          },
          found => ignore()
        }],
      },
    },
  };
};

subtest "Don't specify enough to find by multi-col UK" => sub {
  sims_test "Create the row" => {
    spec => {
      Artist => { first_name => 'Taylor', last_name => 'Swift' },
    },
    expect => {
      Artist => { id => 1, first_name => 'Taylor', last_name => 'Swift' },
    },
  };

  sims_test "Throw an error finding the row" => {
    deploy => 0,
    loaded => {
      Artist => 1,
    },
    spec => {
      Artist => { first_name => 'Taylor2', last_name => 'Swift' },
    },
    dies => qr/UNIQUE constraint failed/,
  };
};

subtest "Load and retrieve a row by PK" => sub {
  sims_test "Create the row" => {
    spec => {
      Artist => { first_name => 'Taylor', last_name => 'Swift' },
    },
    expect => {
      Artist => { id => 1, first_name => 'Taylor', last_name => 'Swift' },
    },
  };

  sims_test "Find the row" => {
    deploy => 0,
    loaded => {
      Artist => 1,
    },
    spec => {
      Artist => { id => 1 },
    },
    expect => {
      Artist => { id => 1, first_name => 'Taylor', last_name => 'Swift' },
    },
  };
};

done_testing
