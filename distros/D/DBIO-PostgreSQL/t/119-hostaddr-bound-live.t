use strict;
use warnings;
use Test::More;
use Socket ();

# LIVE test of the hostaddr= form of the HostBound seam (karr k126). The
# offline half, t/119-bind-host-into-dsn.t, pins the DSN the seam writes;
# which server libpq then goes to, only a connection says.
#
# WHY: libpq lets hostaddr= win over host=. A replicant given a view over the
# answer of a broker that carries hostaddr= would connect to the server of
# the answer, not to its own host -- silently, with the right credentials.
# The seam takes hostaddr= out of the DSN, so the host of the view is the one
# libpq goes to.
#
# What this file claims, against the server of DBIO_TEST_PG_DSN:
#   1. an answer with hostaddr=192.0.2.1 (TEST-NET-1, nobody answers there)
#      and a view with the real host: the connection comes up and answers
#      SELECT 1 -- the unreachable hostaddr= was not what libpq went to;
#   2. an answer with hostaddr= the real address and a view with host
#      192.0.2.1: the connection fails -- libpq went to the host of the view
#      and not to the server the answer named.
#
# Both connections go through a DBIO::PostgreSQL::Storage and a HostBound
# view; the login is the test login, the DSN is built from its parameters,
# with connect_timeout=3 so that the unreachable address ends the file soon.

my ($dsn, $user) = @ENV{ map { "DBIO_TEST_PG_$_" } qw( DSN USER ) };

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn && $user;

use FindBin;
use lib "$FindBin::Bin/lib";
use DBIO::AccessBroker;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Util qw(quote_dsn_value);
use LiveServer;

LiveServer->require_server;

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { bless { answer => $_[1] }, $_[0] }
  sub connect_info_for { $_[0]{answer} }
}

my %ci = LiveServer->conninfo;
my (undef, undef, $pass) = LiveServer->login;

my $host = $ci{host};
plan skip_all => 'the test login names no single TCP host to bind to'
  unless defined $host && length $host && $host !~ m{[,/]};
my $port = $ci{port};

# the address of the real host, for the answer that names it as hostaddr=
my $packed = Socket::inet_aton($host);
plan skip_all => 'the test host does not resolve to an IPv4 address'
  unless defined $packed;
my $real_ip = Socket::inet_ntoa($packed);

my $TEST_NET = '192.0.2.1';

# a DSN of the test login's database with the given extra parameters
sub answer_dsn {
  my (%extra) = @_;
  my %p = (dbname => $ci{dbname} // $ci{user} // $user, connect_timeout => 3, %extra);
  return 'dbi:Pg:' . join ';', map { "$_=" . quote_dsn_value($p{$_}) } sort keys %p;
}

# SELECT 1 through a replicant-style connection, or the error
sub select_one_through {
  my ($answer_dsn, $view_host) = @_;
  my $view = T::Broker->new([ $answer_dsn, $user, $pass, { RaiseError => 1, PrintError => 0 } ])
    ->for_host({ host => $view_host, (defined $port ? (port => $port) : ()) });

  my $storage = DBIO::PostgreSQL::Storage->new(undef);
  my $one = eval {
    $storage->connect_info([ $view ]);
    my ($v) = $storage->dbh->selectrow_array('SELECT 1');
    $storage->disconnect;
    $v;
  };
  return ($one, defined $one ? undef : "$@");
}

# ---------------------------------------------------------------------------
# 1. hostaddr= of the answer is out of the way.
# ---------------------------------------------------------------------------
{
  my ($one, $error) = select_one_through(answer_dsn(hostaddr => $TEST_NET, host => $TEST_NET), $host);
  is $one, 1, "an answer with an unreachable hostaddr= and the real host in the view: SELECT 1"
    or diag $error;
}

# ---------------------------------------------------------------------------
# 2. The host of the view is where libpq goes.
# ---------------------------------------------------------------------------
{
  my ($one, $error) = select_one_through(answer_dsn(hostaddr => $real_ip, host => $host), $TEST_NET);
  ok !defined $one, 'an answer with the real hostaddr= and an unreachable host in the view: no connection'
    or diag 'connected to the server the answer named, not to the host of the view';
  ok length($error // ''), '... with a reason';
}

done_testing;
