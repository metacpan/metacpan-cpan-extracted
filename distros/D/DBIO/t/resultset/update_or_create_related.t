use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;

# ADR 0034: a relation-valued key in an update_or_create condition must never
# corrupt the row it finds/creates. update_or_create builds the find() lookup
# from the plain columns plus any belongs_to that resolves to a concrete
# foreign-key condition; a relation that does not so resolve (has_many /
# has_one / might_have, or a non-resolvable belongs_to) is left out of the
# lookup so find() never clobbers a key column with an undef FK. The FULL
# condition -- relation keys included -- is still handed to the row layer via
# update()/insert, which owns nested-relation semantics. Everything runs on the
# mock storage -- no real DB.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

# Columns are returned positionally by the mock cursor, so mock rows must match
# add_columns() order.
#   Artist: artistid, name, rank, charfield
#   CD:     cdid, artist, title, year, genreid, single_track

# helper: pull captured ops as a compact list of "op:table" strings
sub op_tables {
  map {
    my $t = $_->{sql} =~ /\b(?:FROM|INTO|UPDATE)\s+"?(\w+)"?/i ? $1 : '?';
    "$_->{op}:$t"
  } $storage->captured_queries;
}

# --- (a) plain condition: found -> update, absent -> insert ------------------
# The no-relation path is unchanged: find on the main table, then update the
# existing row or insert a new one. No transaction is opened.
{
  $storage->clear_mocks;
  $storage->reset_captured;

  # find() returns an existing artist with a DIFFERENT name -> update fires
  $storage->mock_persistent(qr/FROM "artist"/i, [[ 1, 'Old Name', 13, undef ]]);

  my $row;
  lives_ok {
    $row = $schema->resultset('Artist')->update_or_create(
      { artistid => 1, name => 'Updated Name' },
      { key => 'primary' },
    );
  } 'plain update_or_create (row present) lives';

  isa_ok $row, 'DBIO::Row', 'returned row';

  my @ops = op_tables();
  ok( ( grep { $_ eq 'select:artist' } @ops ), 'find() ran a SELECT on the main table' );
  ok( ( grep { $_ eq 'update:artist' } @ops ), 'existing row was UPDATEd (name differed)' );
  ok( !( grep { $_->{op} eq 'txn_begin' } $storage->captured_queries ),
    'no transaction is opened for the plain path' );

  $storage->clear_mocks;
  $storage->reset_captured;
  # no mock -> find() misses -> row is INSERTed
  lives_ok {
    $schema->resultset('Artist')->update_or_create(
      { artistid => 99, name => 'Brand New' },
      { key => 'primary' },
    );
  } 'plain update_or_create (row absent) lives';

  @ops = op_tables();
  ok( ( grep { $_ eq 'insert:artist' } @ops ), 'missing row was INSERTed' );
}

# --- (b) composition: the row layer receives the FULL condition unsplit ------
# The find() lookup drops a non-concrete relation (the has_many 'cds'), but the
# row layer -- $row->update on a hit, new_result on a miss -- receives the FULL
# condition with 'cds' still present, restoring the pre-0.900001 data flow.
# Recording stand-ins are used for the row layer: what matters here is what
# update_or_create hands off, not how a real row processes a nested sub-hash
# (that is the row layer's own job -- see t/relationship/set_from_related_guard.t
# and ADR 0034). No transaction is opened -- nothing is split into a second write.
{
  package TestRecordingResultSet;
  use base 'DBIO::Test::BaseResultSet';

  our @find_calls;
  our @new_result_calls;
  our $find_returns; # test sets this: undef (miss) or a FakeRow (hit)

  sub find       { my $self = shift; push @find_calls, [@_];       return $find_returns }
  sub new_result { my $self = shift; push @new_result_calls, [@_]; return TestRecordingResultSet::FakeRow->new }

  package TestRecordingResultSet::FakeRow;

  our @update_calls;

  sub new    { bless {}, shift }
  sub insert { $_[0] }
  sub update { my $self = shift; push @update_calls, [@_]; $self }
}

my $cond = {
  artistid => 1,
  name     => 'Updated Name',
  cds      => { title => 'New Title', year => 2020 },
};
my $lookup = { artistid => 1 }; # the constraint's columns only (ADR 0070); name is data, cds non-concrete

# (b1) row found -> $row->update() gets the full condition unsplit
{
  $storage->clear_mocks;
  $storage->reset_captured;
  @TestRecordingResultSet::find_calls               = ();
  @TestRecordingResultSet::FakeRow::update_calls    = ();
  $TestRecordingResultSet::find_returns = TestRecordingResultSet::FakeRow->new;

  my $artist_source        = $schema->source('Artist');
  my $orig_resultset_class = $artist_source->resultset_class;
  $artist_source->resultset_class('TestRecordingResultSet');

  $schema->resultset('Artist')->update_or_create($cond, { key => 'primary' });

  $artist_source->resultset_class($orig_resultset_class);

  is scalar(@TestRecordingResultSet::find_calls), 1, 'find() ran exactly once';
  is_deeply $TestRecordingResultSet::find_calls[0][0], $lookup,
    'find() received the key columns only -- the non-concrete has_many and the data column are not in the lookup';

  is scalar(@TestRecordingResultSet::FakeRow::update_calls), 1,
    'row->update() ran exactly once';
  is_deeply $TestRecordingResultSet::FakeRow::update_calls[0][0], $cond,
    'row->update() received the FULL condition -- cds reached the row layer unsplit';

  ok( !( grep { $_->{op} eq 'txn_begin' } $storage->captured_queries ),
    'no transaction is opened -- nothing is split into a second write' );
}

# (b2) row absent -> new_result() gets the full condition unsplit
{
  $storage->clear_mocks;
  $storage->reset_captured;
  @TestRecordingResultSet::find_calls        = ();
  @TestRecordingResultSet::new_result_calls  = ();
  $TestRecordingResultSet::find_returns = undef;

  my $artist_source        = $schema->source('Artist');
  my $orig_resultset_class = $artist_source->resultset_class;
  $artist_source->resultset_class('TestRecordingResultSet');

  $schema->resultset('Artist')->update_or_create($cond, { key => 'primary' });

  $artist_source->resultset_class($orig_resultset_class);

  is_deeply $TestRecordingResultSet::find_calls[0][0], $lookup,
    'find() received the lookup only (row absent)';
  is scalar(@TestRecordingResultSet::new_result_calls), 1,
    'new_result() ran exactly once';
  is_deeply $TestRecordingResultSet::new_result_calls[0][0], $cond,
    'new_result() received the FULL condition -- cds reached the row layer unsplit';

  ok( !( grep { $_->{op} eq 'txn_begin' } $storage->captured_queries ),
    'no transaction is opened for the insert path either' );
}

# --- (d) regression: find()'s complex-condition guard still fires ------------
# A *direct* find() with a genuinely crosstable relation sub-hash (here a
# coderef-cond has_many that cannot be reduced to a join-free condition on the
# main table) must still be rejected exactly as before.
{
  $storage->clear_mocks;
  $storage->reset_captured;

  throws_ok {
    $schema->resultset('Artist')->find({ artistid => 1, cds_cref_cond => { title => 'x' } });
  } qr/Complex condition via relationship 'cds_cref_cond' is unsupported in find\(\)/,
    "find() still guards genuinely crosstable relation sub-hashes";
}

# --- (d2) regression: find() rejects a NON-concrete relation resolution ------
# The ADR-0033 corruption: a might_have/has_one/has_many sub-hash of non-key
# columns is not crosstable and IS a hashref, so it slips past the guard above,
# yet resolves join-free to { self_pk => undef }. Blindly merging that clobbers
# the real key column with an undef -- find() searched WHERE cdid IS NULL. It
# must now throw instead of corrupting the lookup.
{
  $storage->clear_mocks;
  $storage->reset_captured;

  my $found = $schema->resultset('CD')->find(
    { cdid => 42, liner_notes => { notes => 'x' } },
    { key => 'primary' },
  );
  is( $found, undef,
    "find() misses on a non-concrete relation resolution instead of clobbering the key"
    . " -- the historical observable behaviour of find-then-write idioms, minus the corrupt merge" );

  ok( !( grep { $_->{op} eq 'select' } $storage->captured_queries ),
    'no SELECT was issued -- the corrupt lookup never reached storage' );
}

# --- (e) lookup builder: concrete belongs_to stays, non-concrete drops -------
# _find_lookup_cond keeps plain columns and any belongs_to that resolves to a
# concrete FK on this table; a has_many / might_have sub-hash is dropped (find()
# cannot use it, and it must not clobber a key column). The dropped keys are
# omitted from the LOOKUP only -- update_or_create still passes them to the row
# layer.
{
  my $cd_rs = $schema->resultset('CD');
  my $lookup = $cd_rs->_find_lookup_cond({
    cdid   => 1,
    title  => 'X',
    artist => { artistid => 7 },              # belongs_to, FK-resolvable
    tracks => { title => 'T', position => 1 },# has_many, non-concrete
  });

  ok exists $lookup->{cdid},   'plain column stays in the lookup';
  ok exists $lookup->{title},  'plain column stays in the lookup';
  ok exists $lookup->{artist}, 'resolvable belongs_to stays in the lookup (concrete FK)';
  ok !exists $lookup->{tracks},'non-concrete has_many is dropped from the lookup';

  is_deeply [ sort keys %$lookup ], [qw/artist cdid title/],
    'the lookup is exactly the plain columns plus the concrete belongs_to';
}

# --- (f) unique key + nested sub-hash: the classic DBIC-era failure ----------
# The long-standing complaint: update_or_create with a unique column AND nested
# related data poisoned the search with the relation's non-concrete resolution,
# missed the existing row, and tried to re-CREATE the parent (duplicate/unique
# violation). With the lookup builder the find matches on the unique column
# alone; the nested key still reaches the row layer, where stock DBIO refuses
# it loudly (set_from_related guard). No phantom insert, no corrupted lookup,
# no silent anything.
{
  $storage->clear_mocks;
  $storage->reset_captured;

  # the existing CD row -- find() must hit this via cdid alone (mock matches the
  # find SELECT; it is the only SELECT issued in this block)
  $storage->mock_persistent(qr/SELECT .*"cdid"/i, [[ 42, 1, 'Old Title', 2001, undef, undef ]]);

  throws_ok {
    $schema->resultset('CD')->update_or_create(
      { cdid => 42, title => 'Renamed', liner_notes => { notes => 'remastered' } },
      { key => 'primary' },
    );
  } qr/Relationship 'liner_notes' does not resolve to a concrete column condition \(column\(s\) 'cdid' would be set to undef\)/,
    'nested sub-hash reaches the row layer, which refuses it loudly on stock DBIO';

  my @ops = op_tables();
  ok( ( grep { $_ eq 'select:cd' } @ops ),
    'find() ran -- the unique column matched the existing row (update path chosen)' );
  ok( !( grep { $_ eq 'insert:cd' } @ops ),
    'the existing row was NEVER re-created -- the classic duplicate-parent bug is dead' );
  ok( !( grep { $_ eq 'update:cd' } @ops ),
    'no UPDATE reached storage either -- the refusal aborts before any write' );
}

done_testing;
