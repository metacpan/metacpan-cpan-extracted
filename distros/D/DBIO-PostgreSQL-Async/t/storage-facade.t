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
    return bless { %args, queries => [], params => [] }, $class;
  }
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    push @{ $self->{queries} }, $sql;
    push @{ $self->{params} }, $bind;
    # Return one row so RETURNING/select_single shaping is exercised.
    $cb->([ [ 1, 'name' ] ], undef) if $cb;
  }
  sub query {
    my ($self, $sql, $cb) = @_;
    push @{ $self->{queries} }, $sql;
    $cb->(1, undef) if $cb;
  }
  $INC{'EV/Pg.pm'} = __FILE__;
}

use Future ();
use DBIO::PostgreSQL::Async::Storage;

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

my $storage = DBIO::PostgreSQL::Async::Storage->new(undef);
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

# --- insert_async: RETURNING appended once ---

my $ins = $storage->insert_async('artist', { name => 'x' })->get;
is_deeply $ins, [ 1, 'name' ], 'insert_async yields the RETURNING row';
like $conn->{queries}[-1], qr/RETURNING \*/, 'insert appends RETURNING *';
my $returning_count = () = $conn->{queries}[-1] =~ /RETURNING/gi;
is $returning_count, 1, 'RETURNING appended exactly once';

# --- update_async / delete_async ---

ok $storage->update_async('artist', { name => 'y' }, { id => 1 })->is_done,
  'update_async resolves';
like $conn->{queries}[-1], qr/^UPDATE/i, 'UPDATE dispatched';

ok $storage->delete_async('artist', { id => 1 })->is_done,
  'delete_async resolves';
like $conn->{queries}[-1], qr/^DELETE/i, 'DELETE dispatched';

# --- connections released back to the pool, no leaks ---

is $pool->{acquired}, 5, 'one acquire per CRUD call';
is $pool->{released}, 5, 'every acquired connection was released';

# --- sync wrappers block via ->get and still work ---

my @sync = $storage->select('artist', ['*'], { id => 1 });
is_deeply \@sync, [ [ 1, 'name' ] ], 'sync select() works through the facade';

done_testing;
