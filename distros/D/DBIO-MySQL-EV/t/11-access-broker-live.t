use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  plan skip_all => 'Set DBIO_TEST_MYSQL_DSN to run integration tests'
    unless $ENV{DBIO_TEST_MYSQL_DSN};
  eval { require EV::MariaDB } or plan skip_all => 'EV::MariaDB not installed';
}

use EV;
use DBIO::AccessBroker;
use DBIO::MySQL::EV;
use DBIO::MySQL::EV::Storage;

# --- Parse DSN into MariaDB conninfo hash ---

my $dsn  = $ENV{DBIO_TEST_MYSQL_DSN};
my $user = $ENV{DBIO_TEST_MYSQL_USER} || '';
my $pass = $ENV{DBIO_TEST_MYSQL_PASS} || '';

my %base_conninfo;
if ($dsn =~ /^dbi:(?:mysql|mysql\.rdbs|mariadb):(.+)/i) {
  my $params = $1;
  for my $pair (split /;/, $params) {
    my ($k, $v) = split /=/, $pair, 2;
    $k = 'database' if $k eq 'dbname';
    $base_conninfo{$k} = $v if defined $k && defined $v;
  }
  $base_conninfo{user}     = $user if $user;
  $base_conninfo{password} = $pass if $pass;
} else {
  %base_conninfo = ( conninfo_string => $dsn );
  $base_conninfo{user}     = $user if $user;
  $base_conninfo{password} = $pass if $pass;
}

# --- Test broker that wraps real conninfo ---

{
  package LiveBrokerMySQL;
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
    return [ { %{ $self->{conninfo} } }, {} ];
  }
}

my $broker = LiveBrokerMySQL->new(%base_conninfo);

# ===== 1. Storage-level broker attachment =====

my $storage = DBIO::MySQL::EV::Storage->new(undef);
$storage->connect_info([$broker]);

is $storage->access_broker, $broker,
  'storage->access_broker returns the broker after connect_info([$broker])';
is $storage->access_broker_mode, 'write',
  'broker mode defaults to write';

my $provider = $storage->_conninfo_provider;
ok ref $provider eq 'CODE',
  'storage exposes a conninfo provider coderef when broker is attached';

my $calls_before = $broker->calls;
$provider->();
is $broker->calls, $calls_before + 1,
  'conninfo provider calls connect_info_for_storage on each invocation';

# ===== 2. Schema->connect($broker) path =====

{
  package TestSchemaMySQL;
  use base 'DBIO::Schema';
  # Force the MySQL driver storage (a broker carries no DSN to auto-detect from);
  # the inert MySQL::EV marker rides along so this is a realistic async-capable
  # schema.
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
}

# ADR 0030: async is an explicit PER-CONNECTION choice ({ async => 'ev' }), and
# $schema->storage is ALWAYS the sync driver storage -- the EV async backend is
# reached via ->async. A schema-level broker connect stays sync here on purpose:
# the AccessBroker form requires a single-element connect_info ([$broker]), so it
# cannot also carry the { async => 'ev' } attr that would select a mode (that
# extra element breaks broker detection and the broker is silently dropped). The
# broker-on-async-storage path is proven directly at the storage level by
# subtests 1 and 3 (DBIO::MySQL::EV::Storage->new + connect_info([$broker])).
my $schema = TestSchemaMySQL->connect($broker);
isa_ok $schema->storage, 'DBIO::MySQL::Storage',
  'Schema->connect($broker) creates the MySQL driver storage';
is $schema->storage->access_broker, $broker,
  'schema storage has broker attached';
is $schema->storage->access_broker_mode, 'write',
  'schema storage broker mode defaults to write';

# ===== 3. Live connectivity via broker =====

my $live_storage = DBIO::MySQL::EV::Storage->new(undef);
$live_storage->connect_info([$broker]);

my $connected = 0;
my $connected_err;

{
  my $f_connected = Future->new;

  my $mdb;
  my $conninfo = $live_storage->_conninfo_hash;
  my %ev_args;

  if (ref $conninfo eq 'HASH' && %$conninfo) {
    %ev_args = %$conninfo;
  } elsif (ref $conninfo eq 'ARRAY') {
    # conninfo is an array of one hashref
    %ev_args = %{$conninfo->[0]} if $conninfo->[0] && %{$conninfo->[0]};
  } elsif (defined $conninfo && !ref $conninfo) {
    # String DSN - need to parse it
    if ($conninfo =~ /^dbi:(?:mysql|mysql\.rdbs|mariadb):(.+)/i) {
      my $params = $1;
      for my $pair (split /;/, $params) {
        my ($k, $v) = split /=/, $pair, 2;
        $k = 'database' if $k eq 'dbname';
        $ev_args{$k} = $v if defined $k && defined $v;
      }
      # Use 127.0.0.1 for TCP if host is not set
      $ev_args{host} = '127.0.0.1' unless exists $ev_args{host};
      $ev_args{port} = 3306 unless exists $ev_args{port};
    }

    # Apply credentials from environment if not already set
    $ev_args{user}     = $ENV{DBIO_TEST_MYSQL_USER} if $ENV{DBIO_TEST_MYSQL_USER} && !$ev_args{user};
    $ev_args{password} = $ENV{DBIO_TEST_MYSQL_PASS} if $ENV{DBIO_TEST_MYSQL_PASS} && !$ev_args{password};
  }

  $ev_args{on_connect} = sub { $f_connected->done(1) unless $f_connected->is_ready };
  $ev_args{on_error}   = sub {
    $connected_err = $_[0];
    $f_connected->done(0) unless $f_connected->is_ready;
  };

  eval {
    $mdb = EV::MariaDB->new(%ev_args);
  };
  if ($@) {
    plan skip_all => "EV::MariaDB->new failed: $@";
  }

  EV::run until $f_connected->is_ready;
  $connected = $f_connected->get;

  if (!$connected) {
    plan skip_all => "Could not connect to MySQL/MariaDB via broker conninfo: $connected_err";
  }

  # Quick sanity query
  my $done = 0;
  my ($rows, $err);
  $mdb->prepare('SELECT ? AS source', sub {
    my ($stmt, $perr) = @_;
    die "prepare failed: $perr" if $perr;
    $mdb->execute($stmt, ['access_broker'], sub {
      ($rows, $err) = @_;
      $done = 1;
    });
  });
  EV::run until $done;

  ok !$err, 'no error on broker-conninfo query';
  is $rows->[0][0], 'access_broker',
    'live query works with conninfo from broker';

  $mdb->close_async(sub {});
}

ok $connected, 'connected to MySQL/MariaDB using broker-supplied conninfo';

# ===== 4. Broker refresh causes new conninfo fetch =====

my $calls_before_refresh = $broker->calls;
$broker->refresh;

is $broker->needs_refresh, 1, 'broker needs_refresh after ->refresh';

my $info_after_refresh = $live_storage->_current_async_connect_info('write');
ok defined $info_after_refresh, '_current_async_connect_info returns data after refresh';
is $broker->calls, $calls_before_refresh + 1,
  '_current_async_connect_info fetched fresh info from broker after refresh';
ok !$broker->needs_refresh,
  'needs_refresh cleared after connect_info_for_storage call';

# ===== 5. conninfo_provider continues to use broker after refresh =====

$broker->refresh;
my $calls_before_provider = $broker->calls;
$provider = $live_storage->_conninfo_provider;
$provider->();
is $broker->calls, $calls_before_provider + 1,
  'conninfo provider still calls broker after second refresh';

done_testing;