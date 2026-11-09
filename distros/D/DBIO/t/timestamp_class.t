use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# Codeberg #9: DBIO::Timestamp builds its timestamp objects from a configurable
# `timestamp_class`, defaulting to the lightweight DateTime::Tiny instead of
# forcing the full DateTime stack. get_timestamp() returns timestamp_class->now.
#
# This test pins, mock-only (never a real DB):
#   * the default class is DateTime::Tiny and get_timestamp returns one;
#   * DateTime::Tiny inflates to a real DateTime on demand (->DateTime);
#   * insert / update auto-populate columns and the value reaching the mock
#     storage is a valid ISO-8601 timestamp literal;
#   * timestamp_class('DateTime') opts back into full DateTime objects;
#   * the InflateColumn::DateTime interop decision (see below).
#
# The "default"/"insert"/"explicit"/"override"/interop-insert classes use the
# real default get_timestamp so the DateTime::Tiny default itself is exercised.
# The update-bump assertions need two DISTINCT instants (DateTime::Tiny has only
# second resolution, so a create+update in the same second is legitimately a
# no-op for change tracking), so those classes drive get_timestamp from a
# controllable $NOW, exactly as t/timestamp_runtime.t does.

{
  package TestTC::Schema;
  use base 'DBIO::Schema';
}
{
  # Plain Timestamp — exercises the DateTime::Tiny default.
  package TestTC::Schema::Result::Plain;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/Timestamp/);
  __PACKAGE__->table('plain');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1 },
    title      => { data_type => 'varchar', size => 255 },
    created_at => { data_type => 'datetime', set_on_create => 1 },
    updated_at => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  # Plain Timestamp with a controllable clock, for the update-bump assertions.
  package TestTC::Schema::Result::PlainCtl;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/Timestamp/);
  __PACKAGE__->table('plain_ctl');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1 },
    title      => { data_type => 'varchar', size => 255 },
    created_at => { data_type => 'datetime', set_on_create => 1 },
    updated_at => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  our $NOW;
  sub get_timestamp { $NOW }
}
{
  # Same shape, but opting into full DateTime via timestamp_class.
  package TestTC::Schema::Result::Full;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/Timestamp/);
  __PACKAGE__->timestamp_class('DateTime');
  __PACKAGE__->table('full');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1 },
    title      => { data_type => 'varchar', size => 255 },
    created_at => { data_type => 'datetime', set_on_create => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  # A single column carrying BOTH InflateColumn::DateTime and Timestamp.
  package TestTC::Schema::Result::Infl;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/InflateColumn::DateTime Timestamp/);
  __PACKAGE__->table('infl');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1 },
    title      => { data_type => 'varchar', size => 255 },
    updated_at => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  # InflateColumn::DateTime + Timestamp with a controllable clock, for the
  # interop update-bump assertion.
  package TestTC::Schema::Result::InflCtl;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/InflateColumn::DateTime Timestamp/);
  __PACKAGE__->table('infl_ctl');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1 },
    title      => { data_type => 'varchar', size => 255 },
    updated_at => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  our $NOW;
  sub get_timestamp { $NOW }
}

TestTC::Schema->register_class(Plain    => 'TestTC::Schema::Result::Plain');
TestTC::Schema->register_class(PlainCtl => 'TestTC::Schema::Result::PlainCtl');
TestTC::Schema->register_class(Full     => 'TestTC::Schema::Result::Full');
TestTC::Schema->register_class(Infl     => 'TestTC::Schema::Result::Infl');
TestTC::Schema->register_class(InflCtl  => 'TestTC::Schema::Result::InflCtl');

TestTC::Schema->storage_type('+DBIO::Test::Storage');
my $schema = TestTC::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
my $storage = $schema->storage;

# ISO-8601 without fractional seconds, as produced by DateTime::Tiny/DateTime
# stringification — the literal that reaches the storage layer.
my $ISO = qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/;

# Pull the bind value for a given column out of the last captured op of $op_type.
sub bind_for {
  my ($op_type, $col) = @_;
  my ($op) = grep { $_->{op} eq $op_type } $storage->captured_queries;
  return undef unless $op;
  for my $b (@{ $op->{bind} || [] }) {
    return $b->[1] if ($b->[0]{dbic_colname} // '') eq $col;
  }
  return undef;
}

subtest 'default timestamp_class is DateTime::Tiny' => sub {
  my $default_class = TestTC::Schema::Result::Plain->timestamp_class;
  is $default_class, 'DateTime::Tiny', 'default timestamp_class';

  my $row = $schema->resultset('Plain')->new_result({});
  my $ts  = $row->get_timestamp;
  isa_ok $ts, 'DateTime::Tiny', 'get_timestamp returns a DateTime::Tiny';
  like "$ts", $ISO, 'stringifies to an ISO-8601 timestamp literal';

  SKIP: {
    # ->DateTime loads the full DateTime stack, which is only a `recommends`.
    skip 'DateTime not installed', 1 unless eval { require DateTime; 1 };
    my $dt = $ts->DateTime;
    isa_ok $dt, 'DateTime', 'DateTime::Tiny inflates to a real DateTime on demand';
  }
};

subtest 'insert auto-populates create columns with DateTime::Tiny' => sub {
  $storage->reset_captured;
  my $row = $schema->resultset('Plain')->create({ title => 'Hello' });

  isa_ok $row->created_at, 'DateTime::Tiny', 'created_at accessor';
  isa_ok $row->updated_at, 'DateTime::Tiny', 'updated_at accessor';

  my ($insert) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  ok $insert, 'insert captured';
  like $insert->{sql}, qr/created_at/, 'created_at reached the INSERT';
  like $insert->{sql}, qr/updated_at/, 'updated_at reached the INSERT';

  my $c = bind_for('insert', 'created_at');
  my $u = bind_for('insert', 'updated_at');
  isa_ok $c, 'DateTime::Tiny', 'created_at bind value';
  isa_ok $u, 'DateTime::Tiny', 'updated_at bind value';
  like "$c", $ISO, 'created_at bind is a valid timestamp literal';
  like "$u", $ISO, 'updated_at bind is a valid timestamp literal';
};

subtest 'update bumps updated_at only, leaves created_at' => sub {
  my $t1 = DateTime::Tiny->new(year => 2020, month => 1, day => 1);
  my $t2 = DateTime::Tiny->new(year => 2021, month => 6, day => 15, hour => 12);

  my $row;
  {
    local $TestTC::Schema::Result::PlainCtl::NOW = $t1;
    $row = $schema->resultset('PlainCtl')->create({ title => 'A' });
  }
  is "" . $row->created_at, '2020-01-01T00:00:00', 'precondition: created_at at create time';
  is "" . $row->updated_at, '2020-01-01T00:00:00', 'precondition: updated_at seeded at create';

  local $TestTC::Schema::Result::PlainCtl::NOW = $t2;
  $storage->reset_captured;
  $row->update({ title => 'B' });

  my ($upd) = grep { $_->{op} eq 'update' } $storage->captured_queries;
  ok $upd, 'update captured';
  like $upd->{sql}, qr/updated_at/, 'updated_at is in the UPDATE SET list';
  unlike $upd->{sql}, qr/created_at/, 'created_at is not re-written on update';

  is "" . $row->updated_at, '2021-06-15T12:00:00', 'updated_at bumped';
  is "" . $row->created_at, '2020-01-01T00:00:00', 'created_at untouched';
  isa_ok bind_for('update', 'updated_at'), 'DateTime::Tiny', 'updated_at bind on update';
};

subtest 'explicit values respected (create no-clobber)' => sub {
  my $explicit = DateTime::Tiny->new(
    year => 1999, month => 12, day => 31, hour => 23, minute => 58, second => 59,
  );

  $storage->reset_captured;
  my $row = $schema->resultset('Plain')->create({
    title => 'X', created_at => $explicit,
  });

  is "" . $row->created_at, '1999-12-31T23:58:59',
    'supplied created_at was not clobbered';
  is "" . bind_for('insert', 'created_at'), '1999-12-31T23:58:59',
    'the explicit value is what reached storage';
  isa_ok $row->updated_at, 'DateTime::Tiny',
    'updated_at still auto-populated when not supplied';
};

subtest "timestamp_class('DateTime') yields real DateTime objects" => sub {
  plan skip_all => 'DateTime not installed'
    unless eval { require DateTime; 1 };

  my $full_class = TestTC::Schema::Result::Full->timestamp_class;
  is $full_class, 'DateTime', 'override reports DateTime';

  my $row = $schema->resultset('Full')->new_result({});
  isa_ok $row->get_timestamp, 'DateTime', 'get_timestamp under the override';

  $storage->reset_captured;
  my $created = $schema->resultset('Full')->create({ title => 'Y' });
  isa_ok $created->created_at, 'DateTime', 'created_at accessor under the override';
  isa_ok bind_for('insert', 'created_at'), 'DateTime',
    'created_at bind under the override';
};

subtest 'InflateColumn::DateTime interop: Timestamp feeds a real DateTime' => sub {
  plan skip_all => 'DateTime not installed'
    unless eval { require DateTime; 1 };

  # DECISION: when a Timestamp column is also managed by InflateColumn::DateTime,
  # Timestamp inflates the default DateTime::Tiny to a real DateTime before
  # storing it. InflateColumn::DateTime deflates through the storage datetime
  # formatter (format_datetime), which requires a full DateTime — a
  # DateTime::Tiny would blow up there (asserted in the next subtest). So the
  # combination must behave exactly as a hand-set DateTime.

  # insert path (default clock)
  $storage->reset_captured;
  my $row = $schema->resultset('Infl')->create({ title => 'I' });

  my $ins = bind_for('insert', 'updated_at');
  isa_ok $ins, 'DateTime', 'insert feeds a real DateTime for the inflated column';
  ok !(ref($ins) && $ins->isa('DateTime::Tiny')), 'insert value is NOT a DateTime::Tiny';
  isa_ok $row->updated_at, 'DateTime', 'accessor returns a real DateTime';

  # update path (controllable clock so the value actually changes)
  my $t1 = DateTime::Tiny->new(year => 2020, month => 1, day => 1);
  my $t2 = DateTime::Tiny->new(year => 2022, month => 3, day => 4, hour => 5);

  my $r2;
  {
    local $TestTC::Schema::Result::InflCtl::NOW = $t1;
    $r2 = $schema->resultset('InflCtl')->create({ title => 'K' });
  }
  local $TestTC::Schema::Result::InflCtl::NOW = $t2;
  $storage->reset_captured;
  $r2->update({ title => 'L' });

  my $up = bind_for('update', 'updated_at');
  isa_ok $up, 'DateTime', 'update feeds a real DateTime for the inflated column';
  ok !(ref($up) && $up->isa('DateTime::Tiny')), 'update value is NOT a DateTime::Tiny';
  is "" . $r2->updated_at, '2022-03-04T05:00:00', 'inflated updated_at bumped correctly';
};

subtest 'rationale: DateTime::Tiny cannot deflate via format_datetime' => sub {
  # Documents WHY the interop inflates: this is exactly the call
  # InflateColumn::DateTime makes on a real driver's datetime_parser.
  plan skip_all => 'DateTime::Format::Strptime not available'
    unless eval { require DateTime::Format::Strptime; 1 };

  my $fmt = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%d %H:%M:%S', on_error => 'croak',
  );
  my $tiny = DateTime::Tiny->new(
    year => 2020, month => 1, day => 2, hour => 3, minute => 4, second => 5,
  );

  ok eval { $fmt->format_datetime($tiny->DateTime); 1 },
    'a real DateTime deflates cleanly';
  ok !eval { $fmt->format_datetime($tiny); 1 },
    'a DateTime::Tiny does not — hence Timestamp inflates it for such columns';
};

done_testing;
