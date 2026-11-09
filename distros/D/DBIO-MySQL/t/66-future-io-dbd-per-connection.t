use strict;
use warnings;
use Test::More;
use File::Temp ();

# karr k60 -- the future_io transport drives the DBD of each CONNECTION, not a
# DBD fixed by the transport's class.
#
# WHY IT MATTERS. The transport class is found by convention off the sync
# storage class, and the storage class is pinned by the schema component for
# EVERY DSN: load_components('MySQL') runs DBIO::MySQL::Storage -- and so
# DBIO::MySQL::Storage::Async -- over a dbi:MariaDB: DSN too. This dist's ADR
# 0007 decided that the adapter drives the DBD the DSN names, and implemented
# it by class (DBD::mysql binding in the base, DBD::MariaDB binding in the
# MariaDB subclass). Under that pin the class and the DBD disagree: the pool
# connect asked DBD::MariaDB for mysql_auto_reconnect and died with "Unknown
# attribute mysql_auto_reconnect" (live, 2026-09-26, MySQL 8.0.30, DBD::MariaDB
# 1.24), and behind it every async primitive was DBD::mysql's. k59 fixed the
# same disagreement in the sync storage by asking the handle; this is the async
# half. With an AccessBroker the DSN is not even known per storage: the broker
# answers anew for every connection, so the choice can only be made per
# connection.
#
# What this file claims:
#   1. whichever component pinned the class, a pool connection is opened with
#      the auto-reconnect attribute of the DBD its DSN names -- never the other
#      DBD's -- and a statement on it is prepared, watched, collected and its
#      insertid read through that DBD's binding;
#   2. the dedicated listen connection chooses the same way, and still forces
#      auto-reconnect off against an explicit value;
#   3. a broker that answers a DSN of the other DBD is followed, and two
#      connections of ONE transport with different DBDs are each driven by
#      their own binding;
#   4. a DBD this dist has no binding for is refused before anything connects.
#
# FULLY OFFLINE. The one substitution is the DBD: DBI->connect hands out a fake
# handle of the DBD the DSN names, as DBI does. Each fake is strict the way its
# real DBD is: it has only its own methods (calling mysql_fd on the MariaDB
# fake fails like on a real DBD::MariaDB handle), its statement handle carries
# only its own insertid attribute, and the MariaDB fake refuses a mysql_*
# connect attribute -- the failure the card was filed for. The socket fd is a
# temp file's: always readable, so Future::IO's poll settles at once without an
# event loop. Schema component, storage, async resolution, pool, broker seam
# and the transport's submit / collect path run for real.
# NOT PROVEN HERE: that the real DBDs behave as the fakes do (live only).

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed dbio-async predates _async_broker_conninfo'
    unless DBIO::Async::Storage->can('_async_broker_conninfo');
}

use DBI;
use DBIO::Util ();
use DBIO::AccessBroker;
use DBIO::AccessBroker::Vault;

# Each DBD's own names, spelled out here on purpose: the expectation must not
# be derived from the table under test.
my %API = (
  mysql => {
    prefix    => 'mysql_',
    reconnect => 'mysql_auto_reconnect',
    async     => 'async',
    fd        => 'mysql_fd',
    ready     => 'mysql_async_ready',
    result    => 'mysql_async_result',
    insertid  => 'mysql_insertid',
  },
  MariaDB => {
    prefix    => 'mariadb_',
    reconnect => 'mariadb_auto_reconnect',
    async     => 'mariadb_async',
    fd        => 'mariadb_sockfd',
    ready     => 'mariadb_async_ready',
    result    => 'mariadb_async_result',
    insertid  => 'mariadb_insertid',
  },
);
my %OTHER = ( mysql => 'MariaDB', MariaDB => 'mysql' );

# --- the fake DBDs -----------------------------------------------------------

our @CONNECTS;

for my $dbd (sort keys %API) {
  my $api = $API{$dbd};
  no strict 'refs';

  *{"K60::${dbd}::DBH::prepare"} = sub {
    my ($self, $sql, $attrs) = @_;
    push @{ $self->{calls} }, 'prepare(' . join(',', sort keys %{ $attrs || {} }) . ')';
    return bless {
      dbh              => $self,
      NUM_OF_FIELDS    => 0,
      $api->{insertid} => $self->{next_insertid} // 0,
    }, "K60::${dbd}::STH";
  };
  *{"K60::${dbd}::DBH::$api->{fd}"} = sub {
    push @{ $_[0]{calls} }, $api->{fd};
    return fileno $_[0]{fh};
  };
  *{"K60::${dbd}::DBH::do"} = sub { 1 };   # the session statement of every connection (karr k121)
  *{"K60::${dbd}::DBH::disconnect"} = sub { $_[0]{Active} = 0; 1 };

  *{"K60::${dbd}::STH::execute"} = sub { 1 };
  *{"K60::${dbd}::STH::more_results"} = sub { 0 };   # one result set (karr k73)
  *{"K60::${dbd}::STH::$api->{ready}"} = sub {
    push @{ $_[0]{dbh}{calls} }, $api->{ready};
    return 1;
  };
  *{"K60::${dbd}::STH::$api->{result}"} = sub {
    push @{ $_[0]{dbh}{calls} }, $api->{result};
    return 1;
  };
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    # The DBD of a connect, as DBI works it out.
    my ($dbd) = ($dsn // '') =~ /^dbi:(\w*)/i;
    $dbd ||= $ENV{DBI_DRIVER};
    die "fake DBI: no fake for DBD::$dbd\n" unless $API{$dbd};
    # Measured (karr k59 / k60, DBD::MariaDB 1.24): a mysql_* attribute kills
    # the connect.
    if ($dbd eq 'MariaDB') {
      die DBIO::Util::mask_connect_secrets(
          "DBI connect('$dsn') failed: Unknown attribute $_\n", [ $dsn, $user, $password ])
        for sort grep { /^mysql_/ } keys %$attrs;
    }
    my $dbh = bless {
      Driver => { Name => $dbd },
      Active => 1,
      calls  => [],
      fh     => File::Temp->new,
    }, "K60::${dbd}::DBH";
    push @CONNECTS, { dbd => $dbd, dsn => $dsn, user => $user, attrs => { %$attrs }, dbh => $dbh };
    return $dbh;
  };
}

# A Vault client whose secret never changes, and a broker whose DBI-form answer
# the test swaps.
{
  package K60::VaultClient;
  sub new { bless {}, shift }
  sub read_secret { { username => 'vault-user', password => 'vault-pw' } }

  package K60::SwitchBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  package K60::MySQLSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

  package K60::MariaDBSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

# --- helpers -----------------------------------------------------------------

# The future_io backend the user-facing connect resolves. The schema is kept:
# the backend holds its owning sync storage weakly.
my @schemas;
sub backend {
  my ($schema_class, @connect) = @_;
  my $schema = $schema_class->connect(@connect);
  push @schemas, $schema;
  return $schema->storage->async;
}

# The connect attributes of the last DBI->connect.
sub last_attrs { $CONNECTS[-1] ? $CONNECTS[-1]{attrs} : {} }

sub foreign_attrs {
  my ($dbd, $attrs) = @_;
  my $prefix = $API{ $OTHER{$dbd} }{prefix};
  return [ sort grep { index($_, $prefix) == 0 } keys %$attrs ];
}

# One statement on $conn: the binding calls it made, and the insertid the
# transport read back.
sub statement_on {
  my ($async, $conn, $insertid) = @_;
  $conn->{dbh}{calls}         = [];
  $conn->{dbh}{next_insertid} = $insertid;
  delete $async->{_last_insert_id};
  $async->_query_async_pinned($conn, 'INSERT INTO `t` () VALUES ()', [])->get;
  return ($conn->{dbh}{calls}, $async->last_insert_id);
}

sub binding_calls {
  my ($dbd) = @_;
  my $api = $API{$dbd};
  return [ "prepare($api->{async})", @{$api}{qw( fd ready result )} ];
}

# ---------------------------------------------------------------------------
# 1 + 2. Component x DSN. The class the component pins must not decide the
#        binding. Row one is the defect as filed; row four is its mirror image
#        (the MariaDB component pins its class for a dbi:mysql: DSN as well).
#        Rows two and three are the combinations that always worked -- they
#        must keep working, and they are what a fix that merely swapped the
#        base class's binding would break.
# ---------------------------------------------------------------------------

for my $case (
  [ 'K60::MySQLSchema',   'MariaDB', 'DBIO::MySQL::Storage::Async' ],
  [ 'K60::MySQLSchema',   'mysql',   'DBIO::MySQL::Storage::Async' ],
  [ 'K60::MariaDBSchema', 'MariaDB', 'DBIO::MySQL::Storage::MariaDB::Async' ],
  [ 'K60::MariaDBSchema', 'mysql',   'DBIO::MySQL::Storage::MariaDB::Async' ],
) {
  my ($schema_class, $dbd, $transport) = @$case;
  my $api   = $API{$dbd};
  my $dsn   = "dbi:$dbd:database=t";
  my $label = "$schema_class + dbi:$dbd:";

  my $async = eval { backend($schema_class, $dsn, 'u', 'p', { async => 'future_io' }) };
  ok $async, "$label: future_io resolves a backend" or diag $@;
  next unless $async;

  # The fix is not a different transport class: what the component pins and
  # what the convention resolves from it stay as they were.
  is ref($async), $transport, '... the transport its component always resolved';

  # -- the pool connection
  @CONNECTS = ();
  my $conn = eval { $async->pool->acquire->get };
  ok $conn, "$label: the pool connection opens" or diag $@;
  SKIP: {
    skip 'no pool connection', 5 unless $conn;

    is last_attrs()->{ $api->{reconnect} }, 0,
      "... with $api->{reconnect} => 0, the name of the DBD the DSN names";
    is_deeply foreign_attrs($dbd, last_attrs()), [],
      '... and no attribute of the other DBD';
    is last_attrs()->{AutoInactiveDestroy}, 1, '... fork-safe as before';

    my ($calls, $id) = eval { statement_on($async, $conn, 42) };
    is_deeply $calls, binding_calls($dbd),
      "$label: a statement is prepared, watched and collected through DBD::$dbd\'s binding"
      or diag $@;
    is $id, 42, "... and its insertid read from $api->{insertid}";
  }

  # -- an explicit value under this DBD's name is the caller's choice on the
  #    pool (ADR 0005), and the listen connection forces it off regardless
  my $explicit = eval {
    backend($schema_class, $dsn, 'u', 'p', { async => 'future_io', $api->{reconnect} => 1 });
  };
  ok $explicit, "$label: connects with an explicit $api->{reconnect} => 1" or diag $@;
  next unless $explicit;

  @CONNECTS = ();
  ok eval { $explicit->pool->acquire->get; 1 }, '... the pool connection opens' or diag $@;
  is last_attrs()->{ $api->{reconnect} }, 1, '... and keeps the explicit value';

  @CONNECTS = ();
  my $lconn = eval { $explicit->_listen_open->get };
  ok $lconn, "$label: the listen connection opens" or diag $@;
  SKIP: {
    skip 'no listen connection', 3 unless $lconn;

    is last_attrs()->{ $api->{reconnect} }, 0,
      "... with $api->{reconnect} forced off -- core must see it die";
    is_deeply foreign_attrs($dbd, last_attrs()), [],
      '... and no attribute of the other DBD';
    my ($calls) = eval { statement_on($explicit, $lconn, 0) };
    is_deeply $calls, binding_calls($dbd),
      "... and its statements run through DBD::$dbd\'s binding" or diag $@;
  }
}

# ---------------------------------------------------------------------------
# 3a. A broker answers the DSN. Under load_components('MySQL') a Vault broker
#     configured with a dbi:MariaDB: DSN is the same disagreement as section 1,
#     reached without a DSN in the connect call at all.
# ---------------------------------------------------------------------------
{
  my $vault = DBIO::AccessBroker::Vault->new(
    vault     => K60::VaultClient->new,
    dsn       => 'dbi:MariaDB:dbname=appdb;host=db.example',
    cred_path => 'database/creds/app',
  );
  my $async = eval { backend('K60::MySQLSchema', $vault, { async => 'future_io' }) };
  ok $async, 'MySQL component + Vault broker with a dbi:MariaDB: DSN: a backend' or diag $@;

  SKIP: {
    skip 'no backend', 6 unless $async;

    @CONNECTS = ();
    my $conn = eval { $async->pool->acquire->get };
    ok $conn, '... the pool connection opens' or diag $@;
    is last_attrs()->{mariadb_auto_reconnect}, 0, '... with mariadb_auto_reconnect => 0';
    is_deeply foreign_attrs(MariaDB => last_attrs()), [], '... and no mysql_* attribute';
    my ($calls) = $conn ? eval { statement_on($async, $conn, 0) } : ();
    is_deeply $calls, binding_calls('MariaDB'),
      '... and its statements run through DBD::MariaDB\'s binding' or diag $@;

    @CONNECTS = ();
    ok eval { $async->_listen_open->get; 1 }, '... the listen connection opens' or diag $@;
    is last_attrs()->{mariadb_auto_reconnect}, 0, '... with mariadb_auto_reconnect => 0 too';
  }
}

# ---------------------------------------------------------------------------
# 3b. The reason the choice is per connection and not per storage: a broker is
#     asked again for every connection. Here its answer changes DBD between
#     two pool connections of ONE transport object, both held at once. No
#     per-class and no per-storage choice can drive both.
# ---------------------------------------------------------------------------
{
  my $broker = K60::SwitchBroker->new([ 'dbi:mysql:database=t', 'u', 'p', {} ]);
  my $async  = eval { backend('K60::MySQLSchema', $broker, { async => 'future_io' }) };
  ok $async, 'one transport, a broker that changes DBD between connections: a backend'
    or diag $@;

  SKIP: {
    skip 'no backend', 6 unless $async;

    my $first = eval { $async->pool->acquire->get };
    $broker->{answer} = [ 'dbi:MariaDB:database=t', 'u', 'p', {} ];
    @CONNECTS = ();
    my $second = eval { $async->pool->acquire->get };
    ok $first && $second, '... two pool connections, held at once' or diag $@;
    skip 'no connections', 5 unless $first && $second;

    is ref($first->{dbh}),  'K60::mysql::DBH',   '... the first on DBD::mysql';
    is ref($second->{dbh}), 'K60::MariaDB::DBH', '... the second on DBD::MariaDB';
    is last_attrs()->{mariadb_auto_reconnect}, 0,
      '... the second opened with mariadb_auto_reconnect => 0';

    # Interleaved, so a choice remembered on the storage would be wrong for one.
    my ($calls_second) = eval { statement_on($async, $second, 0) };
    my ($calls_first)  = eval { statement_on($async, $first, 0) };
    is_deeply $calls_second, binding_calls('MariaDB'),
      '... the DBD::MariaDB connection is driven through mariadb_*' or diag $@;
    is_deeply $calls_first, binding_calls('mysql'),
      '... and the DBD::mysql connection of the same transport through mysql_*' or diag $@;
  }
}

# ---------------------------------------------------------------------------
# 4. No binding, no guess. Before the connect the DBD is the one the DSN names
#    -- DBI_DRIVER never stands in when it names none (core, karr k340) --
#    and a DBD this dist has no names for is refused before DBI->connect runs,
#    naming it. Guessing DBD::mysql there is how the defect looked from inside.
# ---------------------------------------------------------------------------
for my $class (qw( DBIO::MySQL::Storage::Async DBIO::MySQL::Storage::MariaDB::Async )) {
  @CONNECTS = ();
  ok !eval { $class->_create_pool_connection({ dsn => 'dbi:Pg:dbname=t' }); 1 },
    "$class: a DSN of another DBD is refused";
  like $@, qr/DBD::mysql and DBD::MariaDB only.*DBD::Pg/, '... naming the DBD';
  is scalar(@CONNECTS), 0, '... before anything reaches DBI->connect';

  # A DSN without a driver part is refused, DBI_DRIVER or not: core refuses
  # it (karr k340), so DBI_DRIVER must not pick the attribute name here.
  for my $env ('MariaDB', 'mysql') {
    local $ENV{DBI_DRIVER} = $env;
    @CONNECTS = ();
    ok !eval { $class->_create_pool_connection({ dsn => 'dbi::database=t' }); 1 },
      "$class: a DSN naming no driver is refused (DBI_DRIVER=$env)";
    like $@, qr/no DBD driver it can name/, '... saying it has no DBD to name';
    is scalar(@CONNECTS), 0, '... before anything reaches DBI->connect';
  }

  # A connection whose handle belongs to another DBD is not driven at all.
  my $stray = { dbh => bless({ Driver => { Name => 'Pg' } }, 'K60::mysql::DBH') };
  ok !eval { $class->_submit_query($stray, 'SELECT 1', []); 1 },
    "$class: a statement on a handle of another DBD is refused";
  like $@, qr/DBD::mysql and DBD::MariaDB only.*DBD::Pg/, '... naming the DBD';
}

done_testing;
