# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing );

use lib 't/lib';

BEGIN {
  use loader qw(build_schema);
  build_schema([
    Company => {
      columns => {
        id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
          extra       => { unsigned => 1 },
        },
        parent_id => {
          data_type   => 'int',
          is_nullable => 0,
          is_numeric  => 1,
          extra       => { unsigned => 1 },
        },
      },
      primary_keys => [ 'id' ],
      belongs_to => {
        parent => { Company => { 'foreign.id' => 'self.parent_id' } },
      },
      has_many => {
        children => { Company => { 'foreign.parent_id' => 'self.id' } },
      },
    },
  ]);
}

use common qw(sims_test Schema);

sims_test "Cyclic graphs throw an error" => {
  spec => { Company => 1 },
  dies => qr/expected directed acyclic graph/,
};

sims_test "Specify a toposort->skip breaks the cycle, but entered a loop" => {
  spec => [
    { Company => 1 },
    {
      toposort => {
        skip => {
          Company => [ 'parent' ],
        },
      },
    },
  ],
  dies => qr/was seen more than once/,
};

Schema->source('Company')->column_info('parent_id')->{is_nullable} = 1;

sims_test "Specify a toposort->skip plus is_nullable breaks the cycle" => {
  spec => [
    { Company => 1 },
    {
      toposort => {
        skip => {
          Company => [ 'parent' ],
        },
      },
    },
  ],
  expect => {
    Company => { id => 1, parent_id => undef },
  },
};

# Note: This will find itself because the row is created, then it searches for
# a row that can fit its parentage, which is itself.
sims_test "Can find a parent on the skipped relationship" => {
  spec => [
    { Company => { parent => 1 } },
    {
      toposort => {
        skip => {
          Company => [ 'parent' ],
        },
      },
    },
  ],
  expect => {
    Company => [
      { id => 1, parent_id => 1 },
    ],
  },
  rv => {
    Company => { id => 1, parent_id => 1 },
  },
};

sims_test "Can build a parent on the skipped relationship" => {
  spec => [
    { Company => { parent => { id => 2 } } },
    {
      toposort => {
        skip => {
          Company => [ 'parent' ],
        },
      },
      allow_pk_set_value => 1,
    },
  ],
  expect => {
    Company => [
      { id => 1, parent_id => 2 },
      { id => 2, parent_id => undef },
    ],
  },
  rv => {
    Company => { id => 1, parent_id => 2 },
  },
};

sims_test "Can force-create a parent on the skipped relationship" => {
  spec => [
    { Company => { parent => { __META__ => { create => 1 } } } },
    {
      toposort => {
        skip => {
          Company => [ 'parent' ],
        },
      },
    },
  ],
  expect => {
    Company => [
      { id => 1, parent_id => 2 },
      { id => 2, parent_id => undef },
    ],
  },
  rv => {
    Company => { id => 1, parent_id => 2 },
  },
};

sims_test "Can build children on the skipped relationship" => {
  spec => [
      { Company => { children => 2 } },
      {
        toposort => {
          skip => {
            Company => [ 'parent' ],
          },
        },
      },
  ],
  expect => {
    Company => [
      { id => 1, parent_id => undef },
      { id => 2, parent_id => 1 },
      { id => 3, parent_id => 1 },
    ],
  },
  rv => {
    Company => { id => 1, parent_id => undef },
  },
};

sims_test "Can point to myself on the skipped relationship" => {
  spec => [
    {
      Company => {
        id => 1,
        parent => {
          id => 1,
        }
      }
    },
    {
      toposort => {
        skip => {
          Company => [ 'parent' ],
        },
      },
      allow_pk_set_value => 1,
    },
  ],
  expect => {
    Company => [
      { id => 1, parent_id => 1 },
    ],
  },
  rv => {
    Company => { id => 1, parent_id => 1 },
  },
};

done_testing;
