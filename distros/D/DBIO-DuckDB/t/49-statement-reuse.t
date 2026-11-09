#!/usr/bin/env perl
# t/49-statement-reuse.t -- a statement that is run again on the same
# connection does what it says (karr k33, ADR 0007).
#
# WHY this matters: an ORM sends the same SQL text over and over -- the second
# create, the second find, the same search with another value. Core prepares
# through DBI's statement cache, so the second run is handed the handle of the
# first. A DBD::DuckDB 0.16 handle does not survive that, in three ways that
# have nothing to do with one another:
#
#   - finish destroys the prepared statement. The handle stays in the cache
#     and comes out dead: the second auto-increment create, the second find
#     and the second single of one shape die, the second populate takes the
#     process down with a segmentation fault.
#   - execute never marks the handle Active, so DBI cannot tell a handle that
#     is being read from one that is free, and two open cursors of one shape
#     end up on the same handle.
#   - execute keeps the rows that were left unread from the run before. A
#     handle that was not read to its end answers the NEXT query with the OLD
#     rows -- no error, no warning, the wrong row.
#
# So DBIO::DuckDB::Storage takes no handle from that cache. Every block below
# is one claim about what the ORM answers, on a connection of its own. None
# of them looks at how the storage keeps the claim, so they stay true -- and
# stay worth having -- on the day the cache is safe to use again.
#
# The fixture rows are written and read back with plain $dbh->do and
# selectall_arrayref, which prepare without the cache: what is under test is
# the ORM call in the middle, not the bookkeeping around it.
#
# Offline, and always in-memory: every claim needs an empty database of its
# own, so DBIO_TEST_DUCKDB_DSN is deliberately not consulted here.

use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::Test;
use DBIO::DuckDB::Test;

sub fresh_schema {
  return DBIO::DuckDB::Test->init_schema(
    dsn         => 'dbi:DuckDB:dbname=:memory:',
    no_populate => 1,
    @_,
  );
}

# What a piece of ORM code answered, as one string -- or how it died. An
# exception has to fail the one assertion it belongs to, not end the file.
sub outcome (&) {
  my ($code) = @_;
  my @got;
  return 'died: ' . ($@ || 'no message') unless eval { @got = $code->(); 1 };
  return join ' ', map { $_ // 'undef' } @got;
}

# Two groups of three, so that "the first row of the other group" and "the
# next row of the same group" are different answers.
sub seed {
  my ($schema) = @_;
  $schema->storage->dbh_do(sub {
    $_[1]->do(q{
      INSERT INTO artist (artistid, name, rank) VALUES
        (1, 'x1', 1), (2, 'x2', 1), (3, 'x3', 1),
        (4, 'y1', 2), (5, 'y2', 2), (6, 'y3', 2)
    });
  });
  return;
}

# 'artistid:name ...' as the table holds it, in key order.
sub stored {
  my ($schema) = @_;
  my $rows = $schema->storage->dbh_do(sub {
    $_[1]->selectall_arrayref('SELECT artistid, name FROM artist ORDER BY artistid');
  });
  return join ' ', map { "$_->[0]:$_->[1]" } @$rows;
}

sub by_rank {
  my ($schema, $rank) = @_;
  return $schema->resultset('Artist')->search({ rank => $rank }, { order_by => 'artistid' });
}

# Two cursors of one SQL shape, read in turn, one step past the end.
sub interleaved {
  my ($schema) = @_;
  my $one = by_rank($schema, 1);
  my $two = by_rank($schema, 2);
  my (@one, @two);
  for (1 .. 4) {
    push @one, outcome { my $row = $one->next; $row ? $row->name : '-' };
    push @two, outcome { my $row = $two->next; $row ? $row->name : '-' };
  }
  return "@one | @two";
}

# ---- create: the engine's key comes back, every time -------------------
# No artistid is given, so the INSERT carries RETURNING and core reads the key
# off the handle and finishes it. Giving the key would take RETURNING out of
# the statement and with it the thing this block is about.
{
  my $schema = fresh_schema();
  my $rs     = $schema->resultset('Artist');

  my %key;
  for my $name (qw(first second third)) {
    $key{$name} = outcome { $rs->create({ name => $name })->artistid };
    like $key{$name}, qr/\A\d+\z/, "create '$name' answers with the key the engine assigned";
  }

  is stored($schema), join(' ', map { "$key{$_}:$_" } qw(first second third)),
    'each row is stored, under the key its object was given';

  $schema->storage->disconnect;
}

# ---- find: the row that was asked for, every time ----------------------
{
  my $schema = fresh_schema();
  my $rs     = $schema->resultset('Artist');
  seed($schema);

  is outcome { $rs->find(1)->name }, 'x1', 'find(1)';
  is outcome { $rs->find(4)->name }, 'y1', 'find(4) -- the same statement with another key';
  is outcome { $rs->find(1)->name }, 'x1', 'find(1) once more';

  $schema->storage->disconnect;
}

# ---- single: the row that was asked for, every time --------------------
{
  my $schema = fresh_schema();
  my $rs     = $schema->resultset('Artist');
  seed($schema);

  is outcome { $rs->search({ name => 'x2' })->single->artistid }, 2, "single for 'x2'";
  is outcome { $rs->search({ name => 'y2' })->single->artistid }, 5,
    "single for 'y2' -- the same statement with another value";
  is outcome { $rs->search({ name => 'x2' })->single->artistid }, 2, "single for 'x2' once more";

  $schema->storage->disconnect;
}

# ---- one transaction, the same insert twice ----------------------------
# The ordinary shape of a unit of work: several rows of one kind, together or
# not at all.
{
  my $schema = fresh_schema();
  my $rs     = $schema->resultset('Artist');

  is outcome {
    $schema->txn_do(sub { $rs->create({ name => $_ }) for qw(one two); 'committed' });
  }, 'committed', 'two creates of one shape in one txn_do';
  is stored($schema) =~ tr/:/:/, 2, 'both rows are stored';

  # And the rolling-back kind. What comes out of txn_do has to be the block's
  # own exception: an insert that died on a dead handle rolls back as well,
  # and "the row is gone" alone cannot tell the two apart.
  my $before = stored($schema);
  my $error  = outcome {
    $schema->txn_do(sub { $rs->create({ name => 'three' }); die "the block gave up\n" });
  };
  like $error, qr/\Adied: .*the block gave up/,
    'a txn_do that aborts after a repeated create throws its own exception';
  is stored($schema), $before, 'and leaves the table as it was';

  $schema->storage->disconnect;
}

# ---- first: the first row of THIS search -------------------------------
# first reads one row and leaves the rest. The next search of the same shape
# must start at its own first row, not carry on in what the last one left.
{
  my $schema = fresh_schema();
  seed($schema);

  my @want = (1 => 'x1', 2 => 'y1', 1 => 'x1', 2 => 'y1');
  while (my ($rank, $name) = splice @want, 0, 2) {
    is outcome { by_rank($schema, $rank)->first->name }, $name,
      "first of rank $rank is $name";
  }

  is outcome { map { $_->name } by_rank($schema, 2)->all }, 'y1 y2 y3',
    'and all of rank 2 is the whole of rank 2';

  $schema->storage->disconnect;
}

# ---- two cursors of one shape, read in turn ----------------------------
# Paging through two result sets side by side: each yields its own rows, in
# order, and ends where its own rows end.
{
  my $schema = fresh_schema();
  seed($schema);

  is interleaved($schema), 'x1 x2 x3 - | y1 y2 y3 -',
    'two cursors of one SQL shape each yield their own rows';

  $schema->storage->disconnect;
}

# One representative per defect, for the blocks below: they vary how the
# storage came to be, not what is asked of it.
sub reuse_is_sound {
  my ($schema, $how) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $rs = $schema->resultset('Artist');
  seed($schema);

  is outcome { map { $rs->find($_)->name } 1, 4 }, 'x1 y1',
    "$how: find twice";
  is outcome { map { by_rank($schema, $_)->first->name } 1, 2 }, 'x1 y1',
    "$how: first twice";
  is interleaved($schema), 'x1 x2 x3 - | y1 y2 y3 -',
    "$how: two cursors in turn";
  is outcome { map { $rs->create({ name => $_ })->name } qw(n1 n2) }, 'n1 n2',
    "$how: create twice";

  return;
}

# ---- the storage is the DuckDB storage from the start ------------------
# A schema always declares its driver (core ADR 0067), so there is no storage
# that is configured as something else and becomes the DuckDB storage on the
# first use of the handle: whatever keeps the claims above is in place before
# the first connection, and the blocks above are the claims for every
# schema. The test helper declares DuckDB by default.
{
  my $schema = fresh_schema(no_deploy => 1);

  is $schema->storage->_dbh, undef, 'premise: no connection was opened yet';
  isa_ok $schema->storage, 'DBIO::DuckDB::Storage',
    'declared by the helper: the storage before any handle';
}

# A schema that names no driver gets no connection to reuse statements on:
# the helper refuses it and asks for storage_type (core ADR 0067).
SKIP: {
  skip 'core predates ADR 0067 (no refusal of a schema without a driver)', 1
    unless DBIO->can('driver_for');

  my $err = outcome { fresh_schema(no_deploy => 1, storage_type => undef) };
  like $err, qr/\Adied: .*storage_type.*ADR 0067/s,
    'a schema that names no driver is refused, with the hint to declare one';
}

# ---- disable_sth_caching => 0 does not bring the cache back ------------
# The option exists in core and a connect info shared between drivers may
# well carry it. Here it must not mean "hand out dead handles and old rows".
{
  my $schema = fresh_schema(disable_sth_caching => 0);

  ok $schema->storage->disable_sth_caching,
    'disable_sth_caching => 0 at connect: the storage still reports the cache as off';
  reuse_is_sound($schema, 'disable_sth_caching => 0 at connect');

  $schema->storage->disconnect;
}
{
  my $schema = fresh_schema();
  $schema->storage->disable_sth_caching(0);

  ok $schema->storage->disable_sth_caching,
    'disable_sth_caching(0) on the storage: it still reports the cache as off';
  reuse_is_sound($schema, 'disable_sth_caching(0) on the storage');

  $schema->storage->disconnect;
}

# ---- upstream sentinel -------------------------------------------------
# Plain DBI handles, no DBIO: the three defects themselves. When these start
# to pass, that DBD::DuckDB can be measured for giving the statement cache
# back (ADR 0007 says what has to hold; see docs/upstream/).
{
  my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '',
    { RaiseError => 1, PrintError => 0 });
  $dbh->do('CREATE TABLE t (i INTEGER, g INTEGER)');
  $dbh->do('INSERT INTO t VALUES (1, 1), (2, 1), (3, 1), (11, 2), (12, 2), (13, 2)');

  my $sql = 'SELECT i FROM t WHERE g = ? ORDER BY i';

  TODO: {
    local $TODO = 'DBD::DuckDB 0.16 statement handles do not survive reuse (karr k33)';

    is outcome {
      map {
        my $sth = $dbh->prepare_cached($sql, {}, 3);
        $sth->execute($_);
        my $row = $sth->fetchrow_arrayref;
        $sth->finish;
        $row->[0];
      } 1, 2;
    }, '1 11', 'plain DBD::DuckDB: a finished handle can be executed again';

    my $read = $dbh->prepare($sql);
    $read->execute(1);
    ok $read->{Active}, 'plain DBD::DuckDB: an executed handle with rows to read is Active';

    is outcome {
      my $sth = $dbh->prepare($sql);
      map { $sth->execute($_); $sth->fetchrow_arrayref->[0] } 1, 2;
    }, '1 11', 'plain DBD::DuckDB: execute starts at the first row of its own result';
  }

  $dbh->disconnect;
}

# ---- populate: the same bulk insert twice ------------------------------
# LAST in this file on purpose. With the handle taken from the cache the
# second populate does not fail, it crashes the process (SIGSEGV in
# libduckdb, reached through a handle whose statement finish destroyed), and
# a crash further up would take every other claim's result with it.
{
  my $schema = fresh_schema();
  my $rs     = $schema->resultset('Artist');

  is outcome { $rs->populate([ [qw(artistid name)], [10, 'p1'], [11, 'p2'] ]); 'populated' },
    'populated', 'populate';
  is outcome { $rs->populate([ [qw(artistid name)], [12, 'p3'], [13, 'p4'] ]); 'populated' },
    'populated', 'populate again, same columns';
  is stored($schema), '10:p1 11:p2 12:p3 13:p4', 'all four rows are stored';

  $schema->storage->disconnect;
}

done_testing;
