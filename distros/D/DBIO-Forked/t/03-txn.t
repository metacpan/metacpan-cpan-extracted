use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);

use DBIO::Forked::Storage;

# --- Mock driver. Its txn_do($code, @args) simulates core's BEGIN / body /
# --- COMMIT|ROLLBACK bracket and runs the body as $code->(@args), exactly as
# --- DBIO::Storage::txn_do does. To let the test observe the BEGIN/COMMIT order
# --- ACROSS the fork boundary (side effects in the child are invisible to the
# --- parent), it folds the order log into its serializable return value -- a
# --- test affordance; a real txn_do returns the body's value directly.

{
  package t::Mock::Storage;
  sub new { bless {}, shift }

  sub txn_do {
    my ($self, $code, @args) = @_;
    my @order = ('BEGIN');
    my @r = eval { $code->(@args) };
    die $@ if $@;                 # ROLLBACK path: propagate, no COMMIT
    push @order, 'COMMIT';
    return { order => \@order, body => \@r };
  }

  package t::Mock::Schema;
  sub new { my ($c, $s) = @_; bless { storage => $s }, $c }
  sub storage { $_[0]->{storage} }
}

my $schema  = t::Mock::Schema->new(t::Mock::Storage->new);
my $storage = DBIO::Forked::Storage->new($schema);

# --- success: serializable body return roundtrips, BEGIN before COMMIT --------
{
  my $f = $storage->txn_do_async(sub { return 'inserted-id-7' });
  isa_ok($f, 'DBIO::Forked::Future', 'txn_do_async returns a Forked::Future');
  my ($res) = $f->get;
  is_deeply($res->{order}, [ 'BEGIN', 'COMMIT' ],
    'transaction ran BEGIN then COMMIT in the child');
  is_deeply($res->{body}, [ 'inserted-id-7' ],
    'body return value roundtrips through the fork');
}

# --- body receives @args -----------------------------------------------------
{
  my $f = $storage->txn_do_async(sub { my @a = @_; return [ reverse @a ] }, 'x', 'y');
  my ($res) = $f->get;
  is_deeply($res->{body}, [ [ 'y', 'x' ] ], 'txn_do_async passes @args to the body');
}

# --- die in body: exception propagates from get (ROLLBACK path, no COMMIT) ----
{
  my $f = $storage->txn_do_async(sub { die "rollback me\n" });
  my @r = eval { $f->get };
  ok($@, 'a die() in the body propagates as an exception from get');
  like($@, qr/rollback me/, 'the body error message is preserved');
  ok($f->is_failed, 'is_failed true on the ROLLBACK path');
}

# --- non-serializable body return: clear, txn-specific error, not a crash -----
{
  my $f = $storage->txn_do_async(sub {
    return bless { cb => sub { 42 } }, 'Bad::Live::Row';   # closure inside -> not Storable-safe
  });
  my @r = eval { $f->get };
  ok($@, 'a non-serializable body return surfaces as an exception from get');
  like(
    $@,
    qr/txn_do_async body must return Storable-serializable data/,
    'error names the return-value limit (live Row/ResultSet objects)',
  );
  ok($f->is_failed, 'is_failed true for the unserializable return');
}

# --- no zombies --------------------------------------------------------------
{
  my $reaped = waitpid(-1, WNOHANG);
  ok($reaped == -1 || $reaped == 0, "no unreaped child processes left (got $reaped)");
}

done_testing;
