use strict;
use warnings;
use Test::More;
use Future;

# LIVE regression for karr k45: bound queries must not leave prepared statements
# behind on the server.
#
# WHY live: the leak is server state. EV::MariaDB's statement id is a plain
# integer; without close_stmt the server keeps every prepared statement until
# the connection closes, counted against the SERVER-WIDE
# max_prepared_stmt_count (default 16382) -- a long-lived pool reaches it and
# from then on the server refuses prepares for every client. Only the server
# can say whether the statements are gone.
#
# HOW: a pool of ONE connection, so every statement below runs on one session.
# N bound statements each go through
#   - the pooled path:  _query_async (every CRUD op, and notify),
#   - insert_async:     INSERT on an acquired connection, then LAST_INSERT_ID(),
#   - the pinned path:  _query_async_pinned (txn_do_async, the insert pin).
# Measured on that session with bindless queries, which prepare nothing:
#   - Com_stmt_prepare / Com_stmt_close (SESSION counters, this session only):
#     the prepare delta must be exactly 3N -- the statements really were
#     prepared, so the test cannot pass vacuously -- and the close delta must
#     equal it;
#   - Prepared_stmt_count (GLOBAL only -- SHOW SESSION STATUS returns the
#     global value): must not grow by anything near N. Other clients of the
#     server may move it a little; this run alone would move it by 3N.
# Then the same session counters on a fresh pool connection whose connect
# action is a bound on_connect_do (_run_pool_connect_statement).

use DBIO::MySQL::EV::TestHarness;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

DBIO::MySQL::EV::TestHarness->count_session_status;

my $N = 50;

my $h = DBIO::MySQL::EV::TestHarness->new(connect_attrs => { pool_size => 1 });
my $async = $h->async;
isa_ok $async, 'DBIO::MySQL::EV::Storage', 'the ev transport';
$h->warm_pool;

sub pooled { $h->await($async->_query_async(@_)) }

sub status {
  # The session's own counters (the harness adds them up over the borrows: the
  # reset that ends a borrow zeroes them); only the server-wide gauge is global.
  my $conn = (grep { defined } @{ $h->pool->{_connections} })[0];
  my $s = $h->session_status($conn) or die 'the session cannot be asked';
  my ($g) = pooled(q{SHOW GLOBAL STATUS LIKE 'Prepared_stmt_count'});
  return {
    prepare => $s->{Com_stmt_prepare},
    close   => $s->{Com_stmt_close},
    open    => $g->[1],
    session => $conn->thread_id,
  };
}

# A table of its own: a temporary one would be gone at the next borrow, the
# session of a borrow is reset when it ends (karr k100, core k398).
my $K45T = "k45_close_stmt_$$";
pooled("DROP TABLE IF EXISTS $K45T");
pooled("CREATE TABLE $K45T (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64))");
END { eval { pooled("DROP TABLE IF EXISTS $K45T") } if $async }

my $before = status();

# the pooled path: N at once, queued on the one connection
my @rows = $h->await(Future->needs_all(
  map { $async->_query_async('SELECT ? + 0', [ $_ ]) } 1 .. $N,
));
is scalar @rows, $N, "$N pooled bound SELECTs answered";

# insert_async: INSERT (bound) + LAST_INSERT_ID(), pinned on an acquired connection
$h->await(Future->needs_all(
  map { $async->insert_async($K45T, { name => "row $_" }) } 1 .. $N,
));
is $async->last_insert_id, $N, "$N bound INSERTs ran, LAST_INSERT_ID() read on the same session";

# the pinned path: one connection held, statements one after another
{
  my $conn = $h->await($h->pool->acquire);
  my $sum = 0;
  $sum += ($h->await($async->_query_async_pinned($conn, 'SELECT ? + 0', [ $_ ])))[0][0] for 1 .. $N;
  $h->pool->release($conn);
  is $sum, $N * ($N + 1) / 2, "$N pinned bound SELECTs answered";
}

my $after = status();

is $after->{session}, $before->{session}, 'everything ran on one session (pool of one)';

my %delta = map { $_ => $after->{$_} - $before->{$_} } qw( prepare close open );
note sprintf 'session %d: Com_stmt_prepare %d -> %d (+%d), Com_stmt_close %d -> %d (+%d); '
  . 'global Prepared_stmt_count %d -> %d (%+d)',
  $before->{session},
  $before->{prepare}, $after->{prepare}, $delta{prepare},
  $before->{close},   $after->{close},   $delta{close},
  $before->{open},    $after->{open},    $delta{open};

is $delta{prepare}, 3 * $N, 'every bound statement was prepared on the server (3N)';
is $delta{close}, $delta{prepare}, 'and every one of them was closed again';
cmp_ok $delta{open}, '<', $N,
  'the server-wide prepared-statement count did not grow with the queries';

$h->disconnect;

# The connect-action replay: a bound on_connect_do runs through
# _run_pool_connect_statement on every freshly spawned pool connection, so on a
# fresh session it is the one statement prepared before anything else -- and
# it must be closed as well.
{
  my $hc = DBIO::MySQL::EV::TestHarness->new(connect_attrs => {
    pool_size     => 1,
    on_connect_do => [ [ 'SET @dbio_k45 = ?', {}, 'replayed' ] ],
  });
  my $ac = $hc->async;
  my %s = map { @$_ } $hc->await($ac->_query_async(
    q{SHOW SESSION STATUS WHERE Variable_name IN ('Com_stmt_prepare', 'Com_stmt_close')}));
  my ($var) = $hc->await($ac->_query_async(q{SELECT @dbio_k45}));
  note "connect replay: Com_stmt_prepare $s{Com_stmt_prepare}, Com_stmt_close $s{Com_stmt_close}";

  is $var->[0], 'replayed', 'the bound connect action ran on the pooled session';
  is $s{Com_stmt_prepare}, 1, 'it was prepared on the server';
  is $s{Com_stmt_close}, 1, 'and closed again';
  $hc->disconnect;
}

done_testing;
