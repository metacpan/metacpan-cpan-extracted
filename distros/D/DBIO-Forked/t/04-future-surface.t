use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);

use DBIO::Forked::Future;
use DBIO::Forked::Storage;
use DBIO::Future;

my $F = 'DBIO::Forked::Future';

# --- done / fail as CLASS methods (the future_class->done/->fail surface) ----
{
  my $f = $F->done('a', 'b');
  ok $f->is_ready,   'done() future is_ready';
  ok !$f->is_failed, 'done() future not is_failed';
  is_deeply [ $f->get ], [ 'a', 'b' ], 'done() get returns the values (list context)';
  is scalar $f->get, 'a', 'done() get in scalar context returns the first value';

  my $e = $F->fail("boom\n");
  ok $e->is_failed, 'fail() future is_failed';
  ok $e->is_ready,  'fail() future is_ready';
  eval { $e->get };
  like $@, qr/boom/, 'fail() get re-throws the error';
}

# --- the exact ResultSet.pm pattern: future_class->done(@rows) / ->fail($@) ---
{
  my @rows = ([ 1, 'Miles' ], [ 2, 'Coltrane' ]);
  my $f = $F->done(@rows);
  is_deeply [ $f->get ], \@rows, 'done(@rows) roundtrips the row list';
  ok( DBIO::Future->validate($f),
    'a done() future still satisfies the minimal DBIO::Future contract' );

  my $err = $F->fail("db error\n");
  eval { $err->get };
  like $@, qr/db error/, 'fail($err) get croaks with the error';
}

# --- then / catch on settled futures -----------------------------------------
{
  is scalar $F->done(1)->then(sub { $_[0] + 1 })->get, 2,
    'done(1)->then(+1)->get == 2';
  is scalar $F->fail('x')->catch(sub { "caught:$_[0]" })->get, 'caught:x',
    'fail(x)->catch->get recovers into a value';
}

# --- and_then flattens a returned future -------------------------------------
{
  my $f = $F->done(1)->and_then(sub { $F->done($_[0] * 10) });
  is scalar $f->get, 10, 'done(1)->and_then(->done(*10))->get == 10 (flattened)';
}

# --- needs_all over immediate futures ----------------------------------------
{
  my $all = $F->needs_all($F->done(1), $F->done(2), $F->done(3));
  is_deeply [ $all->get ], [ 1, 2, 3 ], 'needs_all collects all values in order';

  my $failed = $F->needs_all($F->done(1), $F->fail("nope\n"), $F->done(3));
  ok $failed->is_failed, 'needs_all fails if any input fails';
  eval { $failed->get };
  like $@, qr/nope/, 'needs_all get re-throws the failing error';
}

# --- needs_all over REAL fork-backed futures (the integration proof) ---------
{
  package t::Mock::Storage;
  sub new { bless {}, shift }
  sub select { shift; return ([ 1, 'Alice' ], [ 2, 'Bob' ]) }

  package t::Mock::Schema;
  sub new { my ($c, $s) = @_; bless { storage => $s }, $c }
  sub storage { $_[0]->{storage} }
}
{
  my $schema  = t::Mock::Schema->new(t::Mock::Storage->new);
  my $storage = DBIO::Forked::Storage->new($schema);

  my @futures = map { $storage->select_async('artist') } 1 .. 3;   # 3 parallel forks
  isa_ok $futures[0], 'DBIO::Forked::Future', 'select_async returns a Forked::Future';

  my @rows = DBIO::Forked::Future->needs_all(@futures)->get;
  is_deeply \@rows,
    [
      [ 1, 'Alice' ], [ 2, 'Bob' ],
      [ 1, 'Alice' ], [ 2, 'Bob' ],
      [ 1, 'Alice' ], [ 2, 'Bob' ],
    ],
    'needs_all collects rows from 3 parallel forked queries, in order';
}

# --- no zombies --------------------------------------------------------------
{
  my $reaped = waitpid(-1, WNOHANG);
  ok $reaped == -1 || $reaped == 0, "no unreaped child processes left (got $reaped)";
}

done_testing;
