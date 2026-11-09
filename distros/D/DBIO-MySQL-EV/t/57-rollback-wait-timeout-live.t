use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE test for karr k81: what a pinned connection does when a statement with
# bind values is in flight on it.
#
# 1. Every statement issued behind such a statement (a prepare/execute in
#    flight: EV::MariaDB refuses a query then) waits for it and runs after it,
#    in the order issued -- it does not fail with the refusal.
# 2. A ROLLBACK waits for the statement in flight at most
#    rollback_wait_timeout seconds. The statement here is SELECT SLEEP(?) that
#    outlasts the limit: the ROLLBACK is not sent, the transaction's Future
#    fails with a reason that names the wait, and the connection is retired
#    (a transaction may still be open on it) -- the next call runs on a new
#    session. A statement that answers within the limit is not affected.
#
# Gated like the other live tests: DBIO_TEST_MYSQL_DSN (dbi:mysql: or
# dbi:MariaDB:), _USER, _PASS, plus EV and EV::MariaDB.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

use EV;
use EV::MariaDB;

$SIG{ALRM} = sub { BAIL_OUT('t/57-rollback-wait-timeout-live.t: alarm, a wait did not end') };
alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package T57L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
}

sub now { Time::HiRes::time() }

sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = now() + ($timeout // 15);
  until ($cond->()) {
    return 0 if now() > $deadline;
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}
my $TICK = EV::timer(0.02, 0.02, sub {});   # RUN_ONCE never blocks for long

sub outcome {
  my ($f, $t) = @_;
  wait_until(sub { $f->is_ready }, $t // 20) or return (undef, 'still pending');
  return (undef, 'cancelled') if $f->is_cancelled;
  return $f->is_failed ? (0, scalar $f->failure) : (1, ($f->get)[0]);
}

sub new_harness {
  my $h = DBIO::MySQL::EV::TestHarness->new(
    schema_class  => 'T57L::Schema',
    connect_attrs => { pool_size => 1 },
  );
  $h->warm_pool;
  return $h;
}

sub held { my ($h, $conn) = @_; scalar grep { defined && $_ == $conn } @{ $h->pool->{_connections} } }

# --- 1. statements behind a statement with bind values -------------------------

{
  my $h     = new_harness();
  my $async = $h->async;
  my @order;
  my @f;
  my $txn = $async->txn_do_async(sub {
    my ($ctx) = @_;
    push @f,
      $ctx->_query_async('SELECT SLEEP(?), 1', [ 0.3 ])->then(sub { push @order, 'bound'; 1 }),
      $ctx->_query_async('SELECT 2', [])->then(sub { push @order, 'plain'; 2 }),
      $ctx->_query_async('SELECT ?', [ 3 ])->then(sub { push @order, 'bound2'; 3 });
    return Future->needs_all(@f);
  });
  my ($ok, $err) = outcome($txn);
  ok $ok, 'statements issued behind a statement in flight complete' or diag defined $ok ? $err : "no outcome: $err";
  is_deeply \@order, [qw( bound plain bound2 )], 'in the order they were issued';
  is_deeply \@warnings, [], 'nothing warned';
  eval { $h->disconnect };
}

# --- 2. the ROLLBACK's wait has a limit ----------------------------------------

{
  my $h     = new_harness();
  my $async = $h->async;
  my $conn  = (grep { defined } @{ $h->pool->{_connections} })[0];
  my $tid   = $conn->thread_id;
  $async->rollback_wait_timeout(0.5);

  my $stmt;
  my $t0  = now();
  my $txn = $async->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = $ctx->_query_async('SELECT SLEEP(?)', [ 4 ]);
    die "coderef gave up\n";
  });
  my ($ok, $err) = outcome($txn, 10);
  my $took = now() - $t0;
  is $ok, 0, 'the transaction fails' or diag defined $ok ? 'it completed' : "no outcome: $err";
  like "$err", qr/coderef gave up/, 'with its cause';
  like "$err", qr/did not answer within 0\.5s/, 'and the reason of the wait';
  cmp_ok $took, '<', 3, "after the limit, not after the statement (${\ sprintf '%.2f', $took}s)";
  ok !held($h, $conn), 'the connection is retired';

  my ($cok, $crow) = outcome($async->_query_async('SELECT CONNECTION_ID()', []));
  ok $cok, 'the next call runs' or diag defined $cok ? $crow : "no outcome: $crow";
  isnt $cok ? $crow->[0] : undef, $tid, 'on a newly opened session';

  # the late answer of the statement changes nothing
  outcome($stmt, 10);
  is_deeply \@warnings, [], 'nothing warned';
  eval { $h->disconnect };
}

{
  my $h     = new_harness();
  my $async = $h->async;
  $async->rollback_wait_timeout(5);
  my $stmt;
  my $txn = $async->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = $ctx->_query_async('SELECT SLEEP(?)', [ 0.5 ]);
    die "coderef gave up\n";
  });
  my ($ok, $err) = outcome($txn, 10);
  is $ok, 0, 'a statement that answers within the limit: the transaction fails';
  like "$err", qr/\Acoderef gave up/, 'with its own error only';
  unlike "$err", qr/did not answer/, 'not with the wait';
  my ($cok) = outcome($async->_query_async('SELECT 1', []));
  ok $cok, 'and the pool works';
  eval { $h->disconnect };
}

done_testing;
