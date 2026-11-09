use strict;
use warnings;
use Test::More;

# LIVE, karr k88 (4): the pool closes a connection it never counted, against a
# real PostgreSQL with a real EV::Pg. The live half of
# t/81-shutdown-uncounted-connection-mock.t.
#
# WHY: since core k277 PoolBase::_spawn_connection closes, through this
# distribution's _shutdown_connection (`$conn->finish`), the connection a spawn
# made when the pool was shut down from inside _create_connection -- one the
# pool never counted, still CONNECTING. Two things might have depended on the
# count, and were measured (PostgreSQL 18.6, EV::Pg 0.07) before this file was
# written:
#   a. whether EV::Pg calls on_connect or on_error for a finish of a
#      connecting connection -- the on_error wrapper of _new_connection would
#      then report it dead to a pool that never counted it. It calls neither.
#   b. whether a watcher of the closed connection stays in the EV loop (the
#      counterpart of dbio-async 62a16ec, a connection retired while coming
#      up that left its readiness poll standing). None does: EV::run returns
#      dry.
#
# What this file claims:
#   1. a pool shut down from inside _create_connection fails the acquire as
#      shut down, counts nothing, closes the connection the spawn made and
#      tells the pool nothing about it;
#   2. no handler of that connection fires, and EV::run returns although no
#      timer keeps it going;
#   3. the same for a bare connection of the pool's kind finished right after
#      it was opened and again after the loop has run a few rounds of its
#      handshake;
#   4. the server holds no session of the closed connections afterwards.
#
# A loop that does not return is caught by a watchdog with keepalive(0), which
# fires inside the loop and ends it; the file's own alarm is the backstop, set
# once and never cleared.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use EV::Pg;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use DBIO::PostgreSQL::EV::Pool;
use DBIO::PostgreSQL::EV::ConnectInfo 'conninfo_string';

alarm 120;

my $TAG      = "dbio_k88_shut_$$";
my $observer = LiveServer->control_dbh(application_name => "${TAG}_observer");
my %LOGIN    = (LiveServer->conninfo, application_name => $TAG);
my $CONNINFO = conninfo_string(\%LOGIN);

{
  package K88::Pool;
  our @ISA = ('DBIO::PostgreSQL::EV::Pool');

  our (@MARKED, $CONN);

  sub _create_connection {
    my $self = shift;
    $CONN = $self->SUPER::_create_connection(@_);
    $self->shutdown;   # the connection is born into a pool that is gone
    return $CONN;
  }

  sub _mark_connection_dead {
    my ($self, @args) = @_;
    push @MARKED, $args[0];
    return $self->SUPER::_mark_connection_dead(@args);
  }
}

# Run the loop with nothing to keep it going but what the closed connection
# might have left; returns whether the watchdog had to end it.
sub run_dry {
  my $hung = 0;
  EV::now_update();
  my $dog = EV::timer(5, 0, sub { $hung = 1; EV::break });
  $dog->keepalive(0);
  EV::run;
  return $hung;
}

sub sessions {
  my ($n) = $observer->selectrow_array(
    'SELECT count(*) FROM pg_stat_activity WHERE application_name = ?', undef, $TAG);
  return $n;
}

my @warned;
local $SIG{__WARN__} = sub { push @warned, @_ };

# 1, 2
{
  my $pool = K88::Pool->new(conninfo => $CONNINFO, max_size => 1);
  my $f    = $pool->acquire;

  ok $f->is_ready && $f->is_failed, '1: the acquire made from the spawn failed';
  like(($f->failure)[0], qr/shut down/, '1: ... as shut down');
  is scalar @{ $pool->{_connections} || [] }, 0, '1: no connection counted';
  isa_ok $K88::Pool::CONN, 'DBIO::PostgreSQL::EV::Pool::_Connection', '1: the connection the spawn made';
  ok !$K88::Pool::CONN->is_connected, '1: ... was closed while connecting';
  is scalar @K88::Pool::MARKED, 0, '1: the pool was not told it died';

  ok !run_dry(), '2: EV::run returned dry, nothing of the connection left in the loop';
  is scalar @K88::Pool::MARKED, 0, '2: no handler of it fired';
  is_deeply \@warned, [], '2: the pool said nothing';
}

# 3
for my $rounds (0, 3) {
  my @events;
  my $pg = DBIO::PostgreSQL::EV::Pool->_new_connection(
    conninfo   => $CONNINFO,
    on_connect => sub { push @events, 'connect' },
    on_error   => sub { push @events, "error: $_[0]" },
  );
  EV::run(EV::RUN_NOWAIT()) for 1 .. $rounds;
  my $up = $pg->is_connected ? 1 : 0;
  $pg->finish unless $up;   # connecting: the case of the claim

  SKIP: {
    skip "the connection was up after $rounds rounds already; not the case of the claim", 3 if $up;
    ok !run_dry(), "3: finish after $rounds loop rounds: EV::run returned dry";
    is_deeply \@events, [], "3: ... neither on_connect nor on_error was called";
    ok !$pg->is_connected, "3: ... and it is not connected";
  }
  $pg->finish if $up;
}

# 4
{
  my $tries = 20;
  my $n;
  while ($tries--) {
    $n = sessions();
    last unless $n;
    select undef, undef, undef, 0.1;
  }
  is $n, 0, '4: the server holds no session of the closed connections';
}

done_testing;
