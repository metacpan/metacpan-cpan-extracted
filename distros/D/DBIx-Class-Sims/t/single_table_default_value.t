# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing );

use lib 't/lib';

BEGIN {
  use loader qw(build_schema);
  build_schema([
    Country => {
      columns => {
        id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
        },
        code => {
          data_type   => 'char',
          size        => 2,
          is_nullable => 0,
          default_value => 'US',
        },
      },
      primary_keys => [ 'id' ],
      #primary_keys => [ 'code' ],
    },
  ]);
}

use common qw(sims_test);

sims_test "Can use a default value for a char column" => {
  spec => {
    Country => {},
  },
  expect => {
    Country => { id => 1, code => 'US' },
  },
};

#sims_test "Can set the value for a char PK" => {
#  spec => {
#    Country => { code => 'UK' },
#  },
#  expect => {
#    Country => { code => 'UK' },
#  },
#};

done_testing;

