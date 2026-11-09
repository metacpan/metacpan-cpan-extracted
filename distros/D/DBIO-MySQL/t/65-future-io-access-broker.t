use strict;
use warnings;
use Test::More;

# OFFLINE test: every built-in AccessBroker on the future_io transport, MySQL
# and MariaDB flavour (karr k62; same defect as dbio-postgresql k80).
#
# WHY: the transport opens each connection -- every pool spawn, and the
# dedicated listen connection -- from the conninfo hash
# { dsn, user, password, attrs } that _mysql_connect hands to DBI->connect.
# What a broker answers must become that hash: a Static broker answers
# connection parameters (dbname/host/port/user/password) with no DSN, a Vault
# broker a DBI-form arrayref whose attrs carry the DBIO-private 'async' key,
# HostBound either of them pinned to a host. A DSN cannot be built from
# parameters by the async backend alone -- only the owning sync storage knows
# the DBD -- so the backend is reached with its owner, as the schema path does.
#
# What this file claims:
#   1. for each built-in broker shape -- Static, Vault, HostBound over Static,
#      HostBound over Vault -- a pool connection and the listen connection are
#      opened with exactly the DBI->connect arguments the answer means: a
#      dbi:mysql: (dbi:MariaDB: on the MariaDB flavour) DSN with dbname / host /
#      port, the current user and password, the DBD attributes plus the
#      transport's forced connect shape -- and no DBIO-private attribute
#      (async), which is no DBD attribute and the DBD would reject;
#   2. the broker is asked again for every connection: credentials that rotate
#      between two spawns reach the second one and the listen connection
#      opened after them (a stale first answer would lock out a rotated
#      Vault lease);
#   3. an answer the transport cannot connect from croaks naming its shape and
#      never the password in it;
#   4. a broker that stops answering is refused on the next connection.
#
# WHAT RUNS FOR REAL: the built-in brokers, core's broker attach and per-spawn
# provider, the real pool, dbio-async's _async_broker_conninfo and this dist's
# shipped seams. THE SUBSTITUTIONS: DBI->connect records its arguments and hands
# out a fake handle; the Vault client is a stub whose secret the test sets.
# NOT PROVEN HERE: that a real server accepts these connections (live only).

BEGIN {
  eval { require DBIO::MySQL::Storage::Async; require DBIO::MySQL::Storage::MariaDB::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed dbio-async predates _async_broker_conninfo'
    unless DBIO::Async::Storage->can('_async_broker_conninfo');
}

use DBIO::MySQL::Storage ();
use DBIO::MySQL::Storage::MariaDB ();
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::AccessBroker::HostBound;

our (@CONNECTS, @OWNERS);

{
  package FakeBroker::DBH;
  sub new { bless { Active => 1 }, shift }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub do { 1 }   # the session statement of every connection (karr k121)
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    push @CONNECTS, [ $dsn, $user, $password, { %$attrs } ];
    return FakeBroker::DBH->new;
  };
}

{
  package FakeVaultClient;
  sub new { bless { secret => { username => 'vault-user-1', password => 'vault-pw-1' }, reads => 0 }, shift }
  sub read_secret { my ($self) = @_; $self->{reads}++; return { %{ $self->{secret} } } }
}

{
  package HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

my %FLAVOUR = (
  mysql => {
    sync      => 'DBIO::MySQL::Storage',
    async     => 'DBIO::MySQL::Storage::Async',
    reconnect => 'mysql_auto_reconnect',
  },
  MariaDB => {
    sync      => 'DBIO::MySQL::Storage::MariaDB',
    async     => 'DBIO::MySQL::Storage::MariaDB::Async',
    reconnect => 'mariadb_auto_reconnect',
  },
);

# The transport as the schema path builds it: the backend with its owning
# sync storage, then the broker attached.
sub transport_with {
  my ($flavour, $broker) = @_;
  my $f = $FLAVOUR{$flavour};
  my $owner = bless {}, $f->{sync};
  push @OWNERS, $owner;   # the backend holds its owner weakly
  my $s = $f->{async}->new(undef);
  $s->_owner_storage($owner);
  $s->connect_info([ $broker ]);
  return $s;
}

sub spawn       { my ($s) = @_; @CONNECTS = (); $s->pool->acquire->get; return $CONNECTS[-1] }
sub open_listen { my ($s) = @_; @CONNECTS = (); $s->_listen_open->get; return $CONNECTS[-1] }

for my $flavour (qw( mysql MariaDB )) {
  my $f         = $FLAVOUR{$flavour};
  my $dbd       = $flavour;
  my $reconnect = $f->{reconnect};

  # What a pool connection forces on top of the caller's attributes, and the
  # listen connection (auto-reconnect forced off).
  my %forced = (AutoCommit => 1, RaiseError => 1, PrintError => 0,
                AutoInactiveDestroy => 1, $reconnect => 0);

  my $vault = sub {
    DBIO::AccessBroker::Vault->new(
      vault     => FakeVaultClient->new,
      dsn       => "dbi:$dbd:dbname=appdb;host=db.example;port=3307",
      cred_path => 'database/creds/app',
      dbi_attrs => { async => 'future_io', ReadOnly => 0 },
      @_,
    );
  };
  my $static = sub {
    DBIO::AccessBroker::Static->new(
      host => 'db.example', port => 3307, dbname => 'appdb',
      username => 'app', password => 's3cret', @_,
    );
  };

  # ---- 1. each built-in shape, pool spawn and listen connection ----
  for my $case (
    [ 'Static', sub { $static->() },
      [ "dbi:$dbd:dbname=appdb;host=db.example;port=3307", 'app', 's3cret', { %forced } ] ],
    [ 'Vault', sub { $vault->() },
      [ "dbi:$dbd:dbname=appdb;host=db.example;port=3307", 'vault-user-1', 'vault-pw-1',
        { ReadOnly => 0, %forced } ] ],
    [ 'HostBound over Static',
      sub { $static->()->for_host({ host => 'replica.example', port => 3308 }) },
      [ "dbi:$dbd:dbname=appdb;host=replica.example;port=3308", 'app', 's3cret', { %forced } ] ],
    [ 'HostBound over Vault',
      sub { $vault->()->for_host({ host => 'replica.example', port => 3308 }) },
      [ "dbi:$dbd:dbname=appdb;host=replica.example;port=3308", 'vault-user-1', 'vault-pw-1',
        { ReadOnly => 0, %forced } ] ],
  ) {
    my ($label, $build, $want) = @$case;
    my $s = eval { transport_with($flavour, $build->()) };
    ok $s, "$flavour/$label: a broker attaches to the transport" or diag $@;
    next unless $s;

    is_deeply eval { spawn($s) }, $want,
      "$flavour/$label: pool connection gets the broker's DSN, credentials, attributes"
      or diag $@;
    is_deeply eval { open_listen($s) }, $want,
      "$flavour/$label: the listen connection is opened with the same arguments"
      or diag $@;
  }

  # ---- 2. rotation ----
  for my $case (
    [ 'Vault',                sub { $_[0] } ],
    [ 'HostBound over Vault', sub { $_[0]->for_host('replica.example') } ],
  ) {
    my ($label, $wrap) = @$case;
    my $v = $vault->();
    my $s = eval { transport_with($flavour, $wrap->($v)) };
    ok $s, "$flavour/$label: attaches" or diag $@;
    next unless $s;

    is_deeply [ @{ spawn($s) }[1, 2] ], [ 'vault-user-1', 'vault-pw-1' ],
      "$flavour/$label: first connection uses the issued credentials";

    $v->vault->{secret} = { username => 'vault-user-2', password => 'vault-pw-2' };
    $v->_expires_at(0);
    my $reads  = $v->vault->{reads};
    my $second = spawn($s);
    is $v->vault->{reads}, $reads + 1, "$flavour/$label: the expired lease was renewed for the next spawn";
    is_deeply [ @$second[1, 2] ], [ 'vault-user-2', 'vault-pw-2' ],
      "$flavour/$label: the second connection uses the ROTATED credentials";
    is_deeply [ @{ open_listen($s) }[1, 2] ], [ 'vault-user-2', 'vault-pw-2' ],
      "$flavour/$label: the listen connection opened after the rotation uses them too";
  }

  # ---- 3. unusable answers ----
  for my $case (
    [ q{a DSN string without the DBI form}, [ q{host=db.example} ], qr/an arrayref of \(string\)/ ],
    [ 'parameters without dbname', { host => 'db.example', password => 'hunter2' },
      qr/hashref with keys \(host, password\)/ ],
  ) {
    my ($label, $answer, $shape_re) = @$case;
    @CONNECTS = ();
    my $ok = eval { transport_with($flavour, HashBroker->new($answer))->_listen_open; 1 };
    my $err = $@;
    ok !$ok, "$flavour/unusable answer ($label): connecting croaks";
    like $err, $shape_re, '... naming the shape';
    unlike $err, qr/hunter2/, '... never the password';
    is scalar(@CONNECTS), 0, '... nothing was sent to DBI->connect';
  }

  # ---- 4. a broker that stops answering ----
  {
    my $b = HashBroker->new({ dbname => 'appdb', user => 'app', password => 'pw' });
    my $s = eval { transport_with($flavour, $b) };
    ok $s, "$flavour: a minimal parameter answer attaches" or diag $@;
    if ($s) {
      is eval { spawn($s)->[0] }, "dbi:$dbd:dbname=appdb",
        "$flavour: only the parts given go into the DSN" or diag $@;
      $b->{answer} = undef;
      @CONNECTS = ();
      ok !eval { $s->_listen_open; 1 }, "$flavour: a broker that stops answering is refused on the next connection";
      like $@, qr/HashBroker answered no connect info/, '... naming the broker class';
      is scalar(@CONNECTS), 0, '... nothing was sent to DBI->connect';
    }
  }
}

# ---- 5. the schema path -----------------------------------------------------
#
# WHY: sections 1-4 hand the backend its owner by hand. The user-facing way is
# MyApp::Schema->connect($broker, { async => 'future_io' }); a Static broker
# answers parameters only, so the DSN can be built only if that path gives the
# backend its owning sync storage -- and the DSN must name the DBD of the
# component the schema loaded (mysql vs MariaDB), not of the Async class.
{
  package K62::MySQLSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

  package K62::MariaDBSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

for my $case (
  [ 'K62::MySQLSchema',   'DBIO::MySQL::Storage::Async',          'mysql' ],
  [ 'K62::MariaDBSchema', 'DBIO::MySQL::Storage::MariaDB::Async', 'MariaDB' ],
) {
  my ($schema_class, $async_class, $dbd) = @$case;
  my $broker = DBIO::AccessBroker::Static->new(
    host => 'db.example', port => 3307, dbname => 'appdb',
    username => 'app', password => 's3cret',
  );
  my $schema = eval { $schema_class->connect($broker, { async => 'future_io' }) };
  ok $schema, "$schema_class: connect(\$static_broker, { async => 'future_io' }) works" or diag $@;
  next unless $schema;

  my $async = $schema->storage->async;
  isa_ok $async, $async_class, "$schema_class: the future_io backend";
  @CONNECTS = ();
  eval { $async->pool->acquire->get; 1 } or diag $@;
  is_deeply [ @{ $CONNECTS[-1] || [] }[0 .. 2] ],
    [ "dbi:$dbd:dbname=appdb;host=db.example;port=3307", 'app', 's3cret' ],
    "$schema_class: the pool connection gets the DSN of the loaded component's DBD, user and password";
  ok !exists $CONNECTS[-1]->[3]{async}, '... and no DBIO-private async attribute reaches DBI->connect';
}

done_testing;
