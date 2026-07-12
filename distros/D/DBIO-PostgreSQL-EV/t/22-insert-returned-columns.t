use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use Future;
use DBIO::PostgreSQL::EV::Storage;

# OFFLINE test for the ADR 0031 §3 contract dbio-postgresql-ev must satisfy:
# _insert_returned_columns maps a positional RETURNING * arrayref onto a
# column=>value hashref against the source's declared column order. The
# live wiring (Storage -> pool -> EV::Pg) is exercised in the live tests
# (t/12, t/14); here we lock the SHAPING contract down without a real
# PostgreSQL, mirroring t/07-async-mode-and-insert-shape.t in dbio-async.

# --- Stub result source: ->columns is the column order RETURNING * emits,
#     ->name is the table name SQLMaker receives. ---

{
  package SrcStub22;
  sub new     { bless {}, shift }
  sub name    { 'artist' }
  sub columns { qw(artistid name rank) }
}

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ { host => 'localhost', dbname => 'test' } ]);

# --- 1. positional RETURNING * row zips onto the source's column order ---

{
  my $src = SrcStub22->new;
  my $row = [ 42, 'Miles', 13 ];   # what RETURNING * would yield from libpq

  my $returned = $storage->_insert_returned_columns($src, { name => 'Miles' }, $row);
  is ref($returned), 'HASH',
    '_insert_returned_columns returns a hashref (ADR 0031 §3)';
  is_deeply $returned,
    { artistid => 42, name => 'Miles', rank => 13 },
    'positional RETURNING * row zipped onto source column order';
  is $returned->{name}, 'Miles',
    'supplied insert data overlaid onto the RETURNING row';
}

# --- 2. supplied insert data is the floor when RETURNING is absent ---

{
  my $returned = $storage->_insert_returned_columns(undef, { name => 'Miles' }, undef);
  is_deeply $returned, { name => 'Miles' },
    'no row => hashref is just the supplied insert data';
}

# --- 3. column=>value hashref row (alternate shape) merges onto the data ---

{
  my $returned = $storage->_insert_returned_columns(undef,
    { name => 'Coltrane' },
    { artistid => 99, name => 'Coltrane', rank => 13 },
  );
  is_deeply $returned,
    { artistid => 99, name => 'Coltrane', rank => 13 },
    'hashref RETURNING row is merged into the returned-columns hashref';
}

# --- 4. bare string source cannot zip (no ->columns method) ---

{
  my $returned = $storage->_insert_returned_columns('artist', { name => 'x' },
    [ 1, 'x' ]);
  is_deeply $returned, { name => 'x' },
    'bare string source: hashref is just the supplied data (no column zip)';
}

# --- 5. _returning_columns falls back to empty list for a bare string ---

{
  my @cols = $storage->_returning_columns('artist');
  is_deeply \@cols, [],
    '_returning_columns on a bare string returns empty (no zip possible)';
}

{
  my $src  = SrcStub22->new;
  my @cols = $storage->_returning_columns($src);
  is_deeply \@cols, [qw(artistid name rank)],
    '_returning_columns returns source->columns in declaration order';
}

# --- 6. end-to-end: stubbed _query_async returns a positional row and the
#     insert_async facade assembles the hashref via the real
#     _run_crud -> _insert_returned_columns chain. ---

{
  package StubStorage22;
  our @ISA = ('DBIO::PostgreSQL::EV::Storage');

  # Skip pool/EV::Pg entirely: the stub _query_async returns a plain
  # resolved Future of one positional RETURNING row (what libpq would
  # hand back for INSERT ... RETURNING *).
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    return Future->done([ 42, 'Miles', 13 ]) if $sql =~ /^INSERT/i;
    return Future->done();
  }
}

{
  my $storage = StubStorage22->new(undef);
  $storage->connect_info([ { host => 'localhost', dbname => 'test' } ]);

  my $src     = SrcStub22->new;
  my $f       = $storage->insert_async($src, { name => 'Miles' });
  isa_ok $f, 'Future', 'insert_async returns a Future';

  my $returned = $f->get;
  is ref($returned), 'HASH',
    'insert_async (real _run_crud) resolves with a returned-columns HASHREF';
  is_deeply $returned,
    { artistid => 42, name => 'Miles', rank => 13 },
    'end-to-end: RETURNING row zipped onto source columns via _insert_returned_columns';
}

# --- 7. Future then auto-wrap (ADR 0031 §4) ---

is $storage->future_class, 'Future',
  'storage future_class is plain Future (then auto-wrap is native)';

{
  my $storage = StubStorage22->new(undef);
  $storage->connect_info([ { host => 'localhost', dbname => 'test' } ]);
  my $src = SrcStub22->new;

  my $f = $storage->insert_async($src, { name => 'Miles' });
  my $chained = $f->then(sub {
    my $returned = shift;
    return "inserted: $returned->{name} (id=$returned->{artistid})";
  });
  isa_ok $chained, 'Future',
    'chained ->then returns a Future even when the callback returns a plain value';
  ok $chained->is_ready, 'chained Future is ready (auto-wrapped)';
  is $chained->get, 'inserted: Miles (id=42)',
    'chained Future resolves with the plain return value (ADR 0031 §4)';
}

done_testing;