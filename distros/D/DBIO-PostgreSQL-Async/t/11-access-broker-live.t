use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
  eval { require EV::Pg } or plan skip_all => 'EV::Pg not installed';
}

use EV;
use DBIO::AccessBroker;
use DBIO::PostgreSQL::Async;
use DBIO::PostgreSQL::Async::Storage;

# --- Parse DSN into libpq conninfo string ---

my $dsn  = $ENV{DBIO_TEST_PG_DSN};
my $user = $ENV{DBIO_TEST_PG_USER} || '';
my $pass = $ENV{DBIO_TEST_PG_PASS} || '';

my $base_conninfo;
if ($dsn =~ /^dbi:Pg:(.+)/i) {
  my $params = $1;
  my %h;
  for my $pair (split /;/, $params) {
    my ($k, $v) = split /=/, $pair, 2;
    $k = 'dbname' if $k eq 'database';
    $h{$k} = $v if defined $k && defined $v;
  }
  $h{user}     = $user if $user;
  $h{password} = $pass if $pass;
  # Build conninfo string
  $base_conninfo = join ' ', map { "$_=$h{$_}" } sort keys %h;
} else {
  $base_conninfo = $dsn;
  $base_conninfo .= " user=$user" if $user && $base_conninfo !~ /user=/;
  $base_conninfo .= " password=$pass" if $pass && $base_conninfo !~ /password=/;
}

# --- Test broker that wraps real conninfo ---

{
  package LiveBroker;
  use base 'DBIO::AccessBroker';

  sub new {
    my ($class, %conninfo) = @_;
    bless {
      conninfo => \%conninfo,
      calls    => 0,
      refresh  => 0,
    }, $class;
  }

  sub refresh       { $_[0]->{refresh}++ }
  sub needs_refresh { $_[0]->{refresh} > 0 }
  sub calls         { $_[0]->{calls}   }

  sub connect_info_for_storage {
    my ($self, $storage, $mode) = @_;
    $self->{calls}++;
    $self->{refresh} = 0;
    # Return conninfo string directly (EV::Pg uses conninfo strings)
    return [ $self->{conninfo}{conninfo_string} || $self->{conninfo}{_conninfo} ];
  }
}

my $broker = LiveBroker->new(conninfo_string => $base_conninfo);

# ===== 1. Storage-level broker attachment =====

my $storage = DBIO::PostgreSQL::Async::Storage->new(undef);
$storage->connect_info([$broker]);

is $storage->access_broker, $broker,
  'storage->access_broker returns the broker after connect_info([$broker])';
is $storage->access_broker_mode, 'write',
  'schema storage broker mode defaults to write';

# ===== 2. Live connectivity via broker =====

my $connected = 0;
my $connected_err;

{
  my $f_connected = Future->new;

  my $pg;
  eval {
    $pg = EV::Pg->new(
      conninfo   => $broker->connect_info_for_storage($storage, 'write')->[0],
      on_connect => sub { $f_connected->done(1) unless $f_connected->is_ready },
      on_error   => sub {
        $connected_err = $_[0];
        $f_connected->done(0) unless $f_connected->is_ready;
      },
    );
  };
  if ($@) {
    plan skip_all => "EV::Pg->new failed: $@";
  }

  EV::run until $f_connected->is_ready;
  $connected = $f_connected->get;

  if (!$connected) {
    plan skip_all => "Could not connect to PostgreSQL via broker conninfo: $connected_err";
  }

  # Quick sanity query
  my $done = 0;
  my ($rows, $err);
  $pg->query_params('SELECT $1::text AS source', ['access_broker'], sub {
    ($rows, $err) = @_;
    $done = 1;
  });
  EV::run until $done;

  ok !$err, 'no error on broker-conninfo query';
  is $rows->[0][0], 'access_broker',
    'live query works with conninfo from broker';

  $pg->finish;
}

ok $connected, 'connected to PostgreSQL using broker-supplied conninfo';

done_testing;