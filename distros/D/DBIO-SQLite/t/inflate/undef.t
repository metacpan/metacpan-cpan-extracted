use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
use DBIO::Optional::Dependencies;

plan skip_all => 'DT inflation tests need ' . DBIO::Optional::Dependencies->req_missing_for ('test_dt_sqlite')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_dt_sqlite');

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

# Test that setting an inflated column to undef works consistently
# regardless of which method is used (RT#107110 / GH PR#106)

my $event = $schema->resultset('Event')->create({
  starts_at  => DateTime->new(year => 2016, month => 1, day => 1),
  created_on => DateTime->new(year => 2016, month => 1, day => 1),
});

isa_ok($event->starts_at, 'DateTime', 'starts_at inflated after create');

# Method 1: set_inflated_columns with undef
$event->set_inflated_columns({ starts_at => undef });
is($event->starts_at, undef, 'set_inflated_columns sets inflated column to undef');

# Reset
$event->set_inflated_columns({
  starts_at => DateTime->new(year => 2016, month => 2, day => 1),
});
isa_ok($event->starts_at, 'DateTime', 'starts_at re-inflated');

# Method 2: set_inflated_column with undef
$event->set_inflated_column(starts_at => undef);
is($event->starts_at, undef, 'set_inflated_column sets inflated column to undef');

# Reset
$event->set_inflated_column(starts_at =>
  DateTime->new(year => 2016, month => 3, day => 1),
);
isa_ok($event->starts_at, 'DateTime', 'starts_at re-inflated again');

# Method 3: direct accessor with undef
$event->starts_at(undef);
is($event->starts_at, undef, 'direct accessor sets inflated column to undef');

# All three methods should produce the same result
$event->set_inflated_columns({
  starts_at  => DateTime->new(year => 2016, month => 4, day => 1),
  created_on => DateTime->new(year => 2016, month => 4, day => 1),
});

my @results;
for my $method (
  sub { $_[0]->set_inflated_columns({ starts_at => undef }); $_[0]->starts_at },
  sub { $_[0]->set_inflated_column(starts_at => undef); $_[0]->starts_at },
  sub { $_[0]->starts_at(undef); $_[0]->starts_at },
) {
  # Reset first
  $event->set_inflated_columns({
    starts_at => DateTime->new(year => 2016, month => 5, day => 1),
  });
  push @results, $method->($event);
}

is_deeply(\@results, [undef, undef, undef],
  'all three methods consistently return undef');

done_testing;
