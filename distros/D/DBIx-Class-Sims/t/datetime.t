# vi:sw=2
use strictures 2;

use Test::More;

BEGIN {
  use t::loader qw(build_schema);
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
        created_on => {
          data_type => 'timestamp',
          is_nullable => 0,
        },
      },
      primary_keys => [ 'id' ],
    },
  ]);
}

use t::common qw(sims_test Schema);

use DateTime;

my $now = DateTime->now;
my $parsed_now = Schema->storage->datetime_parser->format_datetime($now);

sims_test "Accept a DateTime object" => {
  spec => {
    Artist => { name => 'foo', created_on => $now },
  },
  expect => {
    Artist => { id => 1, name => 'foo', created_on => $parsed_now },
  },
};

sims_test "Accept a stringified DateTime object" => {
  spec => {
    Artist => { name => 'foo', created_on => "$now" },
  },
  expect => {
    Artist => { id => 1, name => 'foo', created_on => $parsed_now },
  },
};

done_testing;
