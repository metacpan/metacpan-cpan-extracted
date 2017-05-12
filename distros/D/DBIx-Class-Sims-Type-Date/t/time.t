# vi:sw=2
use strictures 2;

use Test::More;

BEGIN {
  use t::loader qw(build_schema);
  build_schema();
}

use t::common qw(runner);

use_ok 'DBIx::Class::Sims::Type::Date'
  or BAIL_OUT 'Cannot load DBIx::Class::Sims::Type::Date';

my $type = 'time';

my $num_to_run = $ENV{HARNESS_IS_VERBOSE} ? 1 : 1000;
subtest $type => sub {
  my $sub = DBIx::Class::Sims::Type::Date->can($type);
  ok($sub, "Found the handler for $type") || return;

  my $runner = runner();
  foreach my $i ( 1 .. $num_to_run ) {
    my $value = $sub->({}, { type => $type }, $runner);
    like($value, qr/^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d$/, "'$value' is a legal time");
  }
};

done_testing;
