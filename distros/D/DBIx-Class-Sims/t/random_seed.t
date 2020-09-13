# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing subtest E );

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
        email => {
          data_type => 'varchar',
          size => 128,
          sim => { type => 'email_address' },
        },
      },
      primary_keys => [ 'id' ],
    },
  ]);
}

use common qw(sims_test);

subtest "Same random value when reusing a seed" => sub {
  my ($email, $seed);
  sims_test "first run" => {
    spec => {
      Artist => { name => 'Joe' },
    },
    expect => {
      Artist => { name => 'Joe', email => E() },
    },
    export => [
      [ \$email, sub { $_[0]{Artist}[0]->email } ],
      [ \$seed, sub { $_[1]{seed} } ],
    ],
  };

  sims_test "second run with seed" => {
    spec => [
      { Artist => { name => 'Joe' } },
      { seed => $seed },
    ],
    expect => {
      Artist => { name => 'Joe', email => $email },
    },
  };
};

done_testing;
