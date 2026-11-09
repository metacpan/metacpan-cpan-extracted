use strict;
use warnings;
use Test::More;

# OFFLINE test: every built-in AccessBroker on the future_io transport
# (karr k80).
#
# WHY: the transport opens each connection -- every pool spawn, and the
# dedicated listen connection -- from the conninfo hash
# { dsn, user, password, attrs } that _pg_connect hands to DBI->connect. What a
# broker answers was never turned into that hash: dbio-async's generic seam fed
# it straight to core's pair splitter, so a Static broker's libpq hash arrived
# without a dsn, and a Vault broker's DBI arrayref arrived as a bare DSN string
# with user, password and attributes dropped. Every built-in broker croaked
# "PostgreSQL async conninfo must be a hashref with a dsn" at the first query.
#
# What this file claims:
#   1. for each built-in broker shape -- Static, Vault, HostBound over Static,
#      HostBound over Vault -- a pool connection and the listen connection are
#      both opened with exactly the DBI->connect arguments the broker's answer
#      means: a dbi:Pg: DSN carrying its dbname / host / port, its current user
#      and password, its DBD attributes plus the transport's forced connect
#      shape -- and no DBIO-private attribute (async);
#   2. the broker is asked again for every connection: credentials that rotate
#      between two spawns reach the second one, and the listen connection
#      opened after them;
#   3. a libpq hash leaves absent parts out and quotes a value libpq would
#      misread; the transport's own shapes (a hash with a dsn, a pair) still
#      pass through;
#   4. an answer the transport cannot connect from croaks, naming its shape
#      and never the password in it;
#   4b. a broker that answers nothing -- undef, an empty hash or array, a
#      false value -- is refused with core's error (karr k249), naming the
#      broker class and the shape: at attach, and on every later connection
#      when the broker stops answering after a good first answer. An empty
#      hash in particular never becomes a bare 'dbi:Pg:' DSN that libpq would
#      fill from its environment defaults (karr k93);
#   5. the schema path works: MyApp::Schema->connect($vault) with
#      dbi_attrs => { async => 'future_io' } -- the way a broker picks the mode
#      -- reaches this transport and connects from the broker.
#
# WHAT RUNS FOR REAL: the built-in brokers, core's broker attach and per-spawn
# provider, the real pool, and this dist's shipped seams.
# THE SUBSTITUTIONS: DBI->connect records its arguments and hands out a fake
# handle; the Vault client is a stub whose secret the test sets.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::AccessBroker::HostBound;

our @CONNECTS;

{
  package FakeBroker::DBH;
  sub new { bless { Active => 1, pg_socket => 42 }, shift }
  sub disconnect { $_[0]{Active} = 0; 1 }
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    push @CONNECTS, [ $dsn, $user, $password, { %$attrs } ];
    return FakeBroker::DBH->new;
  };
}

# The Vault client: read_secret answers whatever the test last put in it.
{
  package FakeVaultClient;
  sub new { bless { secret => { username => 'vault-user-1', password => 'vault-pw-1' }, reads => 0 }, shift }
  sub read_secret { my ($self) = @_; $self->{reads}++; return { %{ $self->{secret} } } }
}

# What every connection of this transport forces on top of the caller's
# attributes (karr k79).
my %FORCED = (
  AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1,
  # every error DBI reports for the handle is raised by the transport (karr k120)
  HandleError => \&DBIO::PostgreSQL::Storage::Async::_pg_dbi_error,
);

sub transport_with {
  my ($broker) = @_;
  my $s = DBIO::PostgreSQL::Storage::Async->new(undef);
  $s->connect_info([ $broker ]);
  return $s;
}

# One new pool connection: acquired and kept, so the next spawn is a new one.
sub spawn {
  my ($s) = @_;
  @CONNECTS = ();
  $s->pool->acquire->get;
  return $CONNECTS[-1];
}

sub open_listen {
  my ($s) = @_;
  @CONNECTS = ();
  $s->_listen_open->get;
  return $CONNECTS[-1];
}

sub vault {
  my (%args) = @_;
  return DBIO::AccessBroker::Vault->new(
    vault     => FakeVaultClient->new,
    dsn       => 'dbi:Pg:dbname=appdb;host=db.example;port=5433',
    cred_path => 'database/creds/app',
    dbi_attrs => { pg_enable_utf8 => 1, async => 'future_io' },
    %args,
  );
}

sub static {
  return DBIO::AccessBroker::Static->new(
    host     => 'db.example',
    port     => 5433,
    dbname   => 'appdb',
    username => 'app',
    password => 's3cret',
    @_,
  );
}

# ---------------------------------------------------------------------------
# 1. Each built-in broker shape, on a pool spawn and on the listen connection.
# ---------------------------------------------------------------------------

for my $case (
  [ 'Static',
    sub { static() },
    [ 'dbi:Pg:dbname=appdb;host=db.example;port=5433', 'app', 's3cret', { %FORCED } ] ],
  [ 'Vault',
    sub { vault() },
    [ 'dbi:Pg:dbname=appdb;host=db.example;port=5433', 'vault-user-1', 'vault-pw-1',
      { pg_enable_utf8 => 1, %FORCED } ] ],
  [ 'HostBound over Static',
    sub { static()->for_host({ host => 'replica.example', port => 6432 }) },
    [ 'dbi:Pg:dbname=appdb;host=replica.example;port=6432', 'app', 's3cret', { %FORCED } ] ],
  [ 'HostBound over Vault',
    sub { vault()->for_host({ host => 'replica.example', port => 6432 }) },
    [ 'dbi:Pg:dbname=appdb;host=replica.example;port=6432', 'vault-user-1', 'vault-pw-1',
      { pg_enable_utf8 => 1, %FORCED } ] ],
) {
  my ($label, $build, $want) = @$case;
  my $s = transport_with($build->());

  my $pool_connect = eval { spawn($s) };
  is_deeply $pool_connect, $want,
    "$label: a pool connection is opened with the broker's DSN, credentials and attributes"
    or diag $@;

  my $listen_connect = eval { open_listen($s) };
  is_deeply $listen_connect, $want,
    "$label: the listen connection is opened with the same arguments"
    or diag $@;
}

# ---------------------------------------------------------------------------
# 2. Rotation: the broker is asked for every connection, not once at attach.
# ---------------------------------------------------------------------------

for my $case (
  [ 'Vault',                sub { $_[0] } ],
  [ 'HostBound over Vault', sub { $_[0]->for_host('replica.example') } ],
) {
  my ($label, $wrap) = @$case;
  my $vault = vault();
  my $s = transport_with($wrap->($vault));

  my $first = spawn($s);
  is_deeply [ @$first[1, 2] ], [ 'vault-user-1', 'vault-pw-1' ],
    "$label: the first pool connection uses the credentials Vault issued";

  $vault->vault->{secret} = { username => 'vault-user-2', password => 'vault-pw-2' };
  $vault->_expires_at(0);                          # the lease is up
  my $reads = $vault->vault->{reads};

  my $second = spawn($s);
  is $vault->vault->{reads}, $reads + 1, "$label: the expired lease was renewed for the next spawn";
  is_deeply [ @$second[1, 2] ], [ 'vault-user-2', 'vault-pw-2' ],
    "$label: ... and the second pool connection uses the ROTATED credentials";
  is scalar(@CONNECTS), 1, "$label: ... it is a new connection, not the first one reissued";

  my $listen = open_listen($s);
  is_deeply [ @$listen[1, 2] ], [ 'vault-user-2', 'vault-pw-2' ],
    "$label: the listen connection opened after the rotation uses them too";
}

# ---------------------------------------------------------------------------
# 3. The libpq hash: absent parts, quoting, other parameters; the transport's
#    own shapes still pass.
# ---------------------------------------------------------------------------

{
  my $s = transport_with(DBIO::AccessBroker::Static->new(dbname => 'appdb', username => 'app'));
  is spawn($s)->[0], 'dbi:Pg:dbname=appdb',
    'a Static broker without host and port: only dbname goes into the DSN';

  $s = transport_with(static(dbname => q{it's; my db}));
  is spawn($s)->[0], q{dbi:Pg:dbname='it\\'s; my db';host=db.example;port=5433},
    'a dbname with a quote, a semicolon and a space is single-quoted the way libpq reads it back';
}

{
  package HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  my $s = transport_with(HashBroker->new({
    dbname => 'appdb', host => 'db.example', sslmode => 'require', connect_timeout => 5,
    user => 'app', password => 'pw', attrs => { pg_server_prepare => 0 },
  }));
  is_deeply spawn($s),
    [ 'dbi:Pg:connect_timeout=5;dbname=appdb;host=db.example;sslmode=require', 'app', 'pw',
      { pg_server_prepare => 0, %FORCED } ],
    'any other libpq parameter goes into the DSN, sorted by name; attrs stay DBD attributes';

  $s = transport_with(HashBroker->new({
    dsn => 'dbi:Pg:service=app', user => 'app', password => 'pw', attrs => { pg_enable_utf8 => 1 },
  }));
  is_deeply spawn($s), [ 'dbi:Pg:service=app', 'app', 'pw', { pg_enable_utf8 => 1, %FORCED } ],
    'a hash in the transport\'s own shape (with a dsn) is taken as it is';

  $s = transport_with(HashBroker->new([ { dbname => 'appdb', user => 'app', password => 'pw' }, {} ]));
  is_deeply spawn($s), [ 'dbi:Pg:dbname=appdb', 'app', 'pw', { %FORCED } ],
    'a [ \\%conninfo, \\%opts ] pair is read by its hash';
}

# ---------------------------------------------------------------------------
# 4. An answer the transport cannot connect from.
# ---------------------------------------------------------------------------

for my $case (
  [ 'a libpq keyword string',
    [ 'host=db.example dbname=appdb user=app password=hunter2' ],
    qr/an arrayref of \(string\)/ ],
  [ 'a URI DSN with user and password',
    [ 'postgresql://app:hunter2@db.example/appdb', 'app', 'hunter2' ],
    qr/an arrayref of \(string, string, string\)/ ],
  [ 'a hash with a reference as a parameter',
    { dbname => 'appdb', host => [ 'a', 'b' ], password => 'hunter2' },
    qr/parameter 'host' is a reference/ ],
) {
  my ($label, $answer, $shape_re) = @$case;
  my $s = transport_with(HashBroker->new($answer));
  @CONNECTS = ();
  my $ok = eval { $s->_listen_open; 1 };
  my $err = $@;
  ok !$ok, "unusable answer ($label): opening a connection croaks";
  like $err, qr/PostgreSQL future_io cannot connect from what the AccessBroker returned/,
    '... saying what it could not connect from';
  like $err, $shape_re, '... naming the shape it received';
  unlike $err, qr/hunter2/, '... and never the password';
  is scalar(@CONNECTS), 0, '... and nothing was sent to DBI->connect';
}

# ---------------------------------------------------------------------------
# 4b. A broker that answers nothing (karr k93, core k249).
#
# Until k93 this transport read the broker itself and skipped core's check: an
# empty hash became the DSN 'dbi:Pg:' and libpq connected with whatever its
# environment defaults said. Core refuses an empty answer at attach, so the
# gap was a broker that answers at attach and stops answering later -- the
# case each pool spawn and each listen open has to refuse on its own.
# ---------------------------------------------------------------------------

for my $case (
  [ 'undef',             undef, qr/\(undef\)/ ],
  [ 'an empty hashref',  {},    qr/\(an empty hashref\)/ ],
  [ 'an empty arrayref', [],    qr/\(an empty arrayref\)/ ],
  [ 'a false value',     0,     qr/\(a false value\)/ ],
  [ 'an empty string',   '',    qr/\(a false value\)/ ],
) {
  my ($label, $answer, $shape_re) = @$case;
  my $refusal = qr/AccessBroker HashBroker answered no connect info/;

  # At attach: core's connect_info refuses it before anything connects.
  @CONNECTS = ();
  my $ok  = eval { transport_with(HashBroker->new($answer)); 1 };
  my $err = $@;
  ok !$ok, "broker answering $label at attach: connect_info refuses it";
  like $err, $refusal,  '... with core\'s error naming the broker class';
  like $err, $shape_re, '... and the shape of the answer';
  is scalar(@CONNECTS), 0, '... and nothing was sent to DBI->connect';

  # Later: a good first answer, then nothing.
  my $broker = HashBroker->new({ dbname => 'appdb', user => 'app', password => 'pw' });
  my $s = transport_with($broker);
  $broker->{answer} = $answer;

  for my $open (
    [ 'a pool spawn',    sub { spawn($s) } ],
    [ 'the listen open', sub { open_listen($s) } ],
  ) {
    my ($where, $code) = @$open;
    @CONNECTS = ();
    my $ok  = eval { $code->(); 1 };
    my $err = $@;
    ok !$ok, "broker answering $label after attach: $where fails";
    like $err, $refusal,  '... with core\'s error naming the broker class';
    like $err, $shape_re, '... and the shape of the answer';
    is scalar(@CONNECTS), 0, '... and nothing was sent to DBI->connect (no bare dbi:Pg: DSN)';
  }
}

# ---------------------------------------------------------------------------
# 5. The schema path: a Vault broker selects the mode in its DBI attributes.
# ---------------------------------------------------------------------------

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

{
  my $schema = BrokerSchema->connect(vault());
  my $async = $schema->storage->async;
  isa_ok $async, 'DBIO::PostgreSQL::Storage::Async',
    'MyApp::Schema->connect($vault) with dbi_attrs { async => future_io }';
  is_deeply spawn($async),
    [ 'dbi:Pg:dbname=appdb;host=db.example;port=5433', 'vault-user-1', 'vault-pw-1',
      { pg_enable_utf8 => 1, %FORCED } ],
    '... connects its pool from the broker, without the async attribute';
}

done_testing;
