use strict;
use warnings;
use Test::More;

# Offline end-to-end coverage for the storage facade query path.
#
# Regression guard for the showstopper bug where pool->acquire returns a
# Future but storage treated it as a raw connection, dying with
# "Cannot locate object method query_params via package Future" against
# a real DB. Here the mock pool's acquire() returns a *real* done Future
# wrapping a mock connection — exactly the core PoolBase contract — so
# select_async/insert_async/etc. run through acquire->then end to end.

# Mock EV::Pg so we don't need real PostgreSQL. Set up before Storage's
# runtime `require EV::Pg` in listen().
BEGIN {
  package EV::Pg;
  sub new {
    my ($class, %args) = @_;
    return bless { %args, queries => [], params => [], insert_n => 0 }, $class;
  }
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    push @{ $self->{queries} }, $sql;
    push @{ $self->{params} }, $bind;
    # Return a different RETURNING row per INSERT so we can verify the
    # zipping onto the source's declared column order (the second
    # insert below uses FakeSource with ->columns = qw(id name), so
    # the row [ id, name ] maps onto those columns; the bind echoes
    # back so we can assert the round-trip). The SELECT row is fixed.
    if ($sql =~ /^INSERT/i) {
      $self->{insert_n}++;
      my $name = $bind && @$bind ? $bind->[-1] : 'name';
      $cb->([ [ $self->{insert_n}, $name ] ], undef) if $cb;
    }
    else {
      $cb->([ [ 1, 'name' ] ], undef) if $cb;
    }
  }
  sub query {
    my ($self, $sql, $cb) = @_;
    push @{ $self->{queries} }, $sql;
    $cb->(1, undef) if $cb;
  }
  $INC{'EV/Pg.pm'} = __FILE__;
}

use Future ();
use DBIO::PostgreSQL::EV::Storage;

# Mock pool: acquire() returns a real done Future per the PoolBase
# contract; release() bumps a counter so leaks are observable.
{
  package FacadeMockPool;
  sub new { bless { conn => EV::Pg->new, acquired => 0, released => 0 }, shift }
  sub acquire     { $_[0]->{acquired}++; Future->done($_[0]->{conn}) }
  sub acquire_txn { $_[0]->acquire }
  sub release     { $_[0]->{released}++ }
  sub shutdown    {}
}

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ { host => 'localhost', dbname => 'test' } ]);

my $pool = FacadeMockPool->new;
$storage->{pool} = $pool;
my $conn = $pool->{conn};

# --- select_async ---

my $sel = $storage->select_async('artist', ['*'], { id => 1 });
isa_ok $sel, 'Future', 'select_async returns a Future';
ok $sel->is_done, 'select_async resolved without dying on the Future-as-conn bug';
my @rows = $sel->get;
is_deeply \@rows, [ [ 1, 'name' ] ], 'select_async yields result rows';
like $conn->{queries}[-1], qr/^SELECT/i, 'SELECT dispatched to the acquired connection';

# --- select_single_async: first-row post-processing ---

my $row = $storage->select_single_async('artist', ['*'], { id => 1 })->get;
is_deeply $row, [ 1, 'name' ], 'select_single_async returns the first row';

# --- insert_async: RETURNING appended once; resolves with returned-columns
#     HASHREF (ADR 0031 §3). With a bare table-name source the mock conn
#     hands back one positional RETURNING row; we cannot zip it onto a
#     declared column order (no source object), so the hashref carries
#     just the supplied insert data -- matching what sync $storage->insert
#     would return for a table-name source in that situation. ---

my $ins = $storage->insert_async('artist', { name => 'x' })->get;
is ref $ins, 'HASH',
  'insert_async resolves with the returned-columns HASHREF (ADR 0031 §3)';
is_deeply $ins, { name => 'x' },
  'hashref carries the supplied insert data (no source = no column zip)';
like $conn->{queries}[-1], qr/RETURNING \*/, 'insert appends RETURNING *';
my $returning_count = () = $conn->{queries}[-1] =~ /RETURNING/gi;
is $returning_count, 1, 'RETURNING appended exactly once';

# --- insert_async with a blessed source: the RETURNING row zips onto the
#     source's declared column order, populating the autoinc PK. Mirror
#     the live shape create_async / Row::insert_async feed back via
#     _store_inserted_columns. ---

{
  package FakeSource;
  sub new      { my $class = shift; bless { @_ }, $class }
  sub name     { 'artist' }
  sub columns  { qw(id name) }
}
my $ins2 = $storage->insert_async(FakeSource->new, { name => 'y' })->get;
is ref $ins2, 'HASH',
  'insert_async (with source) resolves with a returned-columns HASHREF';
is_deeply $ins2, { id => 2, name => 'y' },
  'hashref overlays the RETURNING row onto source column order (PK populated)';

# --- update_async / delete_async ---

ok $storage->update_async('artist', { name => 'y' }, { id => 1 })->is_done,
  'update_async resolves';
like $conn->{queries}[-1], qr/^UPDATE/i, 'UPDATE dispatched';

ok $storage->delete_async('artist', { id => 1 })->is_done,
  'delete_async resolves';
like $conn->{queries}[-1], qr/^DELETE/i, 'DELETE dispatched';

# --- positional placeholders: SQL reaching libpq must use $N, never '?' ---
# karr #7: the maker emits '?', libpq needs '$N'. The mock above records every
# SQL string dispatched to query_params; assert each bound statement was
# translated. This is the offline guard the original facade test lacked (it
# mocked libpq, so a '?' that a real server rejects sailed through unnoticed).

for my $sql (@{ $conn->{queries} }) {
  next if $sql =~ /^(?:BEGIN|COMMIT|ROLLBACK)$/i;   # txn control, no binds
  unlike $sql, qr/(?<!\@)\?/, "no bare ? placeholder in dispatched SQL: $sql";
}
my ($sel_sql) = grep { /^SELECT/i } @{ $conn->{queries} };
like $sel_sql, qr/"id" = \$1\b/, 'bound WHERE dispatched as $1, not ?';
my ($ins_sql) = grep { /^INSERT/i } @{ $conn->{queries} };
like $ins_sql, qr/VALUES \(\$1\)/, 'bound VALUES dispatched as $1, not ?';
my ($upd_sql) = grep { /^UPDATE/i } @{ $conn->{queries} };
like $upd_sql, qr/SET "name" = \$1 WHERE "id" = \$2/,
  'UPDATE SET+WHERE numbered $1,$2 across the statement';

# --- connections released back to the pool, no leaks ---

is $pool->{acquired}, 6, 'one acquire per CRUD call';
is $pool->{released}, 6, 'every acquired connection was released';

# --- sync wrappers block via ->get and still work ---

my @sync = $storage->select('artist', ['*'], { id => 1 });
is_deeply \@sync, [ [ 1, 'name' ] ], 'sync select() works through the facade';

done_testing;
