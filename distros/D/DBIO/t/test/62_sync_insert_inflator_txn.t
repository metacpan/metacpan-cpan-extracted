use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DateTime; 1 }
    or plan skip_all => 'DateTime not installed';
}

use DBIO::Test;

# karr k331 (finding 12 of the 2026-10-08 async review, k275): the
# synchronous insert of a row carrying an inflator object is the one INSERT,
# as the asynchronous one and a row without the object already were.
#
# DBIO::Row::insert builds %related_stuff from _relationship_data AND
# _inflated_column; the latter is also where an object for an inflate_column
# column (a DateTime, ...) waits until get_columns deflates it. That slot
# alone used to open the transaction guard, so a lone INSERT went out as
# BEGIN, INSERT, COMMIT. The guard now opens only when
# _insert_cascade_reason names a statement insert() still writes besides this
# row's own; a real multi-create stays bracketed (controls below).
#
# Mock only.

sub first_words {
  my ($schema) = @_;
  return [ map { ($_->{sql} =~ /(\w+)/)[0] } $schema->storage->captured_queries ];
}

sub fresh {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->reset_captured;
  return $schema;
}

my $dt = DateTime->new(year => 2026, month => 10, day => 8);

# ---------------------------------------------------------------------------
# Without an inflator object: the one statement.
# ---------------------------------------------------------------------------
{
  my $schema = fresh();
  $schema->resultset('Event')->create({
    starts_at  => '2026-10-08',
    created_on => '2026-10-08 12:00:00',
  });
  is_deeply first_words($schema), [ 'INSERT' ],
    'Event with plain string values (no inflator object): one INSERT, no transaction';
}
{
  my $schema = fresh();
  $schema->resultset('Artist')->create({ name => 'Miles Davis' });
  is_deeply first_words($schema), [ 'INSERT' ],
    'a class with no inflation at all: one INSERT';
}

# ---------------------------------------------------------------------------
# With an inflator object in a column.
# ---------------------------------------------------------------------------
for my $case (
  [ 'ResultSet->create with a DateTime value', sub {
      $_[0]->resultset('Event')->create({
        starts_at  => $dt,
        created_on => '2026-10-08 12:00:00',
      });
    } ],
  [ 'new_result + insert with a DateTime value', sub {
      $_[0]->resultset('Event')->new_result({
        starts_at  => $dt,
        created_on => '2026-10-08 12:00:00',
      })->insert;
    } ],
  [ 'new_result with a string, the accessor then sets a DateTime, insert', sub {
      my $row = $_[0]->resultset('Event')->new_result({
        starts_at  => '2026-10-08',
        created_on => '2026-10-08 12:00:00',
      });
      $row->starts_at($dt);
      $row->insert;
    } ],
  [ 'two DateTime values in one row', sub {
      $_[0]->resultset('Event')->create({
        starts_at  => $dt,
        created_on => $dt,
      });
    } ],
) {
  my ($label, $do) = @$case;
  my $schema = fresh();
  $do->($schema);
  # Nothing is written besides the one row: one statement, no bracket.
  is_deeply first_words($schema), [ 'INSERT' ],
    "$label: one bare INSERT";
}

# Only the inflator object triggers it: the same row once the value is a
# string again goes out bare (control for the claim above, same class).
{
  my $schema = fresh();
  my $row = $schema->resultset('Event')->new_result({
    starts_at  => $dt,
    created_on => '2026-10-08 12:00:00',
  });
  $row->starts_at('2026-10-09');   # replaces the object by a plain value
  $row->insert;
  my $seq = first_words($schema);
  is_deeply $seq, [ 'INSERT' ],
    'control: the DateTime replaced by a string before insert: one bare INSERT'
    or diag "got: @$seq";
}

# ---------------------------------------------------------------------------
# A real cascade is bracketed, and rightly so (control).
# ---------------------------------------------------------------------------
{
  my $schema = fresh();
  $schema->resultset('Artist')->create({
    name => 'Miles Davis',
    cds  => [ { title => 'Kind of Blue', year => 1959 } ],
  });
  my $seq = first_words($schema);
  is $seq->[0],  'BEGIN',  'control: a real multi-create (has_many) opens a transaction';
  is $seq->[-1], 'COMMIT', 'control: ... and commits it';
  is scalar(grep { $_ eq 'INSERT' } @$seq), 2,
    'control: ... around two INSERTs, which is what the bracket is for';
}

done_testing;
