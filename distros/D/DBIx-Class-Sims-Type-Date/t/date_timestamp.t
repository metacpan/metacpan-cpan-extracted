# vi:sw=2
use strictures 2;

use Test::More;

BEGIN {
  use t::loader qw(build_schema);
  build_schema();
}

use t::common qw(test_dateish);

use_ok 'DBIx::Class::Sims::Type::Date'
  or BAIL_OUT 'Cannot load DBIx::Class::Sims::Type::Date';

my %types = (
  date => 'parse_date',
  timestamp => 'parse_datetime',
);

while (my ($name, $parser) = each %types) {
  my %tests = (
    $name => sub {},
    "${name}_in_past" => sub {
      my ($value, $dt) = @_;
      cmp_ok($dt, '<', DateTime->now, "'$value' is in the past");
    },
    "${name}_in_past_5_years" => sub {
      my ($value, $dt) = @_;
      my $duration = DateTime->now - $dt;
      cmp_ok($duration->years, '<', 5, "'$value' is within 5 years");
      ok($duration->is_positive, "'$value' is in the past");
    },
    "${name}_in_future" => sub {
      my ($value, $dt) = @_;
      cmp_ok($dt, '>', DateTime->now, "'$value' is in the future");
    },
    "${name}_in_next_5_years" => sub {
      my ($value, $dt) = @_;
      my $duration = DateTime->now - $dt;
      cmp_ok($duration->years, '<', 5, "'$value' is within 5 years");
      ok($duration->is_negative, "'$value' is in the future");
    },
  );

  while (my ($type, $addl) = each %tests) {
    test_dateish($name, $parser, $type, $addl);
  }
}

done_testing;
