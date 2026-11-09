use strict;
use warnings;

use Test::More;
use Test::Exception;

use Future;
use DBIO::Test;              # core's offline fake-storage schema harness
use DBIO::Test::Storage;
use DBIO::SQLMaker;
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::AccessBroker::HostBound;
use DBIO::Async::Storage;

# OFFLINE test: what DBIO::Async::Storage::_async_broker_conninfo makes of every
# AccessBroker answer (karr k27).
#
# WHY: every future_io connection -- each pool spawn, and a driver's listen
# connection -- is opened from what the attached broker answers, asked anew
# per connection. The seam used to feed that answer straight to core's
# [ \%conninfo, \%opts ] pair splitter. A Vault broker's DBI-form arrayref
# [ $dsn, $user, $password, \%attrs ] was read as a pair -- conninfo = the DSN
# string, user, password and attributes gone -- and a Static broker's hash of
# connection parameters arrived without any DSN. No built-in broker could open
# a single connection on a driver that relies on this base (dbio-mysql).
#
# What this file claims:
#   1. each built-in broker -- Static, Vault, HostBound over either -- reaches
#      the driver's connect as the connect info its answer means: a DSN naming
#      the owning storage's DBD (built from dbname / host / port for a Static
#      answer), its current user and password, its DBD attributes -- and no
#      DBIO-private attribute (async, quote_names) and no pool_size. The
#      driver's _normalize_conninfo is handed the DBI form, exactly what a
#      direct connect with a DSN hands it;
#   2. the broker is asked for every connection: credentials that change
#      between two spawns reach the second one;
#   3. a DBI-form answer's fifth element joins its attributes; a transport's
#      own connect info -- a hash with a dsn, a [ \%conninfo, \%opts ] pair --
#      still passes through as it is;
#   4. only a DSN built from connection parameters needs the owning sync
#      storage: without one it croaks naming the fix, while a DBI-form answer
#      or a dbname that is a DSN connects without it -- read as core reads it
#      (ADR 0057, karr k44): host and port are no DBD attributes, an empty one
#      is dropped, a set one beside the DSN refuses the spawn;
#   5. an answer nothing can connect from croaks, naming its shape and never
#      the password; an empty one is refused by core (k249/k250) -- also when
#      the broker goes empty after a connection, which is not then opened
#      with the earlier answer;
#   6. DBD attributes given beside the broker (core k243) reach every
#      connection of a transport declaring broker_connect_options: merged into
#      the answer's attributes, the same value in both is fine, different
#      values throw naming the setting and not its values, and an answer in
#      the transport's own shape refuses them rather than drop them.
#
# WHAT RUNS FOR REAL: core's schema connect and async backend resolution (the
# adapter found by convention, the owner wired by core), the built-in brokers,
# core's broker attach and per-spawn provider, DBIO::Async::Pool, and this
# dist's _async_broker_conninfo.
# THE SUBSTITUTIONS: the sync driver storage is core's fake DBIO::Test::Storage
# registered for a made-up DBD; the adapter's _normalize_conninfo does what
# both drivers' do (dbio-postgresql, dbio-mysql), and its
# _create_pool_connection records the conninfo instead of calling
# DBI->connect; the Vault client is a stub.

# --- a fake driver: sync storage + convention-resolved future_io adapter ----

{
  package T27::Driver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(T27DBD => __PACKAGE__);
}

{
  package T27::Driver::Storage::Async;
  use base 'DBIO::Async::Storage';

  sub sql_maker_class           { 'DBIO::SQLMaker' }
  sub _transform_sql            { $_[1] }
  sub _post_insert_sql          { '' }
  sub _conn_ready               { 1 }
  sub _shutdown_pool_connection { }

  # The drivers' seam: DBI form into { dsn, user, password, attrs }, pool_size
  # lifted for core to split off; anything else passes through. Records the
  # DBI form it is handed.
  sub _normalize_conninfo {
    my ($self, $info) = @_;
    return $info
      unless ref $info eq 'ARRAY'
      && defined $info->[0] && !ref $info->[0] && $info->[0] =~ /^dbi:/i;
    push @{ $self->{t27_dbi_forms} }, $info;
    my ($dsn, $user, $password, $attrs) = @$info;
    my %conninfo = (
      dsn      => $dsn,
      user     => $user,
      password => $password,
      attrs    => { %{ $attrs || {} } },
    );
    $conninfo{pool_size} = delete $conninfo{attrs}{pool_size}
      if defined $conninfo{attrs}{pool_size};
    return [ \%conninfo, {} ];
  }

  # The driver's connect: what it would hand DBI->connect.
  sub _create_pool_connection {
    my ($self, $conninfo) = @_;
    push @{ $self->{t27_connects} }, $conninfo;
    return { t27_conninfo => $conninfo };
  }
}

# A second driver whose adapter takes the connect options beside a broker.
{
  package T27::DeclDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(T27DeclDBD => __PACKAGE__);
}

{
  package T27::DeclDriver::Storage::Async;
  use base 'T27::Driver::Storage::Async';
  sub transport_capabilities {
    return ($_[0]->SUPER::transport_capabilities, 'broker_connect_options');
  }
}

# --- brokers ------------------------------------------------------------------

{
  package T27::VaultClient;
  sub new { bless { secret => { username => 'vault-user-1', password => 'vault-pw-1' }, reads => 0 }, shift }
  sub read_secret { my ($self) = @_; $self->{reads}++; return { %{ $self->{secret} } } }
}

# Answers whatever the test gives it.
{
  package T27::AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
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

sub vault {
  my (%args) = @_;
  return DBIO::AccessBroker::Vault->new(
    vault     => T27::VaultClient->new,
    dsn       => 'dbi:T27DBD:dbname=appdb;host=db.example;port=5433',
    cred_path => 'database/creds/app',
    dbi_attrs => { t27_utf8 => 1, async => 'future_io', quote_names => 1, pool_size => 2 },
    %args,
  );
}

# --- helpers --------------------------------------------------------------------

# A schema on the fake driver, connected as given; returns the schema (keep it:
# the backend's owner is held weakly) and its future_io backend.
sub schema_async {
  my ($storage_type, @connect) = @_;
  my $schema = DBIO::Test->init_schema(
    no_connect   => 1,
    storage_type => "+$storage_type",
  );
  $schema->connection(@connect);
  return ($schema, $schema->storage->async);
}

sub direct_async {
  my ($class, @info) = @_;
  my $async = $class->new(undef);
  $async->connect_info([ @info ]);
  return $async;
}

sub connects { scalar @{ $_[0]{t27_connects} || [] } }

# One new pool connection, acquired and kept so the next spawn is a new one:
# the conninfo the driver's connect received for it.
sub spawn {
  my ($async) = @_;
  my $before = connects($async);
  $async->pool->acquire->get;
  die "no new connection was opened\n" unless connects($async) > $before;
  return $async->{t27_connects}[-1];
}

# ---------------------------------------------------------------------------
# 1. Each built-in broker, through a schema connected with the future_io mode.
# ---------------------------------------------------------------------------

for my $case (
  [ 'Static',
    [ static(), { async => 'future_io' } ],
    { dsn => 'dbi:T27DBD:dbname=appdb;host=db.example;port=5433',
      user => 'app', password => 's3cret', attrs => {} } ],
  [ 'Vault (async and quote_names among its dbi_attrs)',
    [ vault() ],
    { dsn => 'dbi:T27DBD:dbname=appdb;host=db.example;port=5433',
      user => 'vault-user-1', password => 'vault-pw-1', attrs => { t27_utf8 => 1 } } ],
  [ 'HostBound over Static',
    [ static()->for_host({ host => 'replica.example', port => 6432 }), { async => 'future_io' } ],
    { dsn => 'dbi:T27DBD:dbname=appdb;host=replica.example;port=6432',
      user => 'app', password => 's3cret', attrs => {} } ],
  [ 'HostBound over Vault',
    [ vault()->for_host({ host => 'replica.example', port => 6432 }) ],
    { dsn => 'dbi:T27DBD:dbname=appdb;host=replica.example;port=6432',
      user => 'vault-user-1', password => 'vault-pw-1', attrs => { t27_utf8 => 1 } } ],
) {
  my ($label, $connect, $want) = @$case;
  my ($schema, $async) = schema_async('T27::Driver::Storage', @$connect);
  isa_ok $async, 'T27::Driver::Storage::Async', "$label: the future_io backend";

  my $conninfo = eval { spawn($async) };
  is_deeply $conninfo, $want,
    "$label: a pool connection gets the DSN, credentials and DBD attributes the answer means"
    or diag $@;
}

{
  my ($schema, $async) = schema_async('T27::Driver::Storage', vault());
  spawn($async);
  is_deeply $async->{t27_dbi_forms}[-1],
    [ 'dbi:T27DBD:dbname=appdb;host=db.example;port=5433', 'vault-user-1', 'vault-pw-1',
      { t27_utf8 => 1 } ],
    "the driver's _normalize_conninfo is handed the DBI form, as with a direct DSN connect";
}

# ---------------------------------------------------------------------------
# 2. The broker is asked for every connection.
# ---------------------------------------------------------------------------

{
  my $vault = vault();
  my ($schema, $async) = schema_async('T27::Driver::Storage', $vault);

  my $first = spawn($async);
  is_deeply [ @{$first}{qw(user password)} ], [ 'vault-user-1', 'vault-pw-1' ],
    'Vault: the first pool connection uses the credentials Vault issued';

  $vault->vault->{secret} = { username => 'vault-user-2', password => 'vault-pw-2' };
  $vault->_expires_at(0);                               # the lease is up
  my $second = spawn($async);
  is_deeply [ @{$second}{qw(user password)} ], [ 'vault-user-2', 'vault-pw-2' ],
    '... the next pool connection uses the ROTATED credentials';
  is connects($async), 2, '... on a connection of its own';
}

{
  my $static = static();
  my ($schema, $async) = schema_async('T27::Driver::Storage', $static, { async => 'future_io' });

  is spawn($async)->{password}, 's3cret', 'Static: the first pool connection uses its password';
  $static->password('n3w-s3cret');
  is spawn($async)->{password}, 'n3w-s3cret',
    '... the next one the password the broker answers now';
}

# ---------------------------------------------------------------------------
# 3. The DBI form's fifth element; the transport's own connect info.
# ---------------------------------------------------------------------------

{
  my $async = direct_async('T27::Driver::Storage::Async', T27::AnswerBroker->new([
    'dbi:T27DBD:dbname=appdb', 'app', 'pw',
    { t27_a => 1, t27_b => 1 },
    { t27_b => 2, async => 'future_io' },
  ]));
  is_deeply spawn($async)->{attrs}, { t27_a => 1, t27_b => 2 },
    'a DBI-form answer: the fifth element joins the attributes, the later winning, private keys out';
}

{
  my $own = { dsn => 'dbi:T27DBD:service=app', user => 'app', password => 'pw',
              attrs => { t27_utf8 => 1 } };
  my $async = direct_async('T27::Driver::Storage::Async', T27::AnswerBroker->new($own));
  is_deeply spawn($async), $own,
    'a hash with a dsn is the transport\'s own connect info, taken as it is';

  $async = direct_async('T27::Driver::Storage::Async',
    T27::AnswerBroker->new([ { %$own }, {} ]));
  is_deeply spawn($async), $own, 'so is a [ \\%conninfo, \\%opts ] pair';
}

# ---------------------------------------------------------------------------
# 4. The owner is needed only to build a DSN from connection parameters.
# ---------------------------------------------------------------------------

{
  my $async = direct_async('T27::Driver::Storage::Async', static(password => 'hunter2'));
  throws_ok { spawn($async) }
    qr/Cannot build a DSN from the connection parameters the AccessBroker answered, a hashref with keys \(dbname, host, password, port, user\).*has none\. Connect through the schema -- MyApp::Schema->connect\(\$broker, \{ async => 'future_io' \}\)/s,
    'Static on a backend without an owning sync storage: croaks, naming the fix';
  unlike $@, qr/hunter2/, '... never the password';
  is connects($async), 0, '... and nothing was connected';

  $async = direct_async('T27::Driver::Storage::Async', vault());
  is spawn($async)->{dsn}, 'dbi:T27DBD:dbname=appdb;host=db.example;port=5433',
    'Vault on a backend without an owner connects: its answer carries the DSN';

  $async = direct_async('T27::Driver::Storage::Async', T27::AnswerBroker->new({
    dbname => 'dbi:T27DBD:service=app', user => 'app', password => 'pw',
  }));
  is_deeply spawn($async),
    { dsn => 'dbi:T27DBD:service=app', user => 'app', password => 'pw', attrs => {} },
    'so do connection parameters whose dbname is a DSN';
}

# A dbname that is a whole DSN, read as core reads it for the sync storage
# (ADR 0057, DBIO::Storage::DBI::_dsn_from_connect_params; karr k44): dbname,
# host and port are the DSN's parts and never DBD attributes. Static answers
# host and port as undef when none was given, and they used to reach the
# driver's connect as the attributes host => undef, port => undef. A SET host
# or port beside the DSN cannot be put into it: as an attribute it would be
# lost and the connection would go to the DSN's host -- a HostBound view's
# host among them -- so the spawn refuses, naming the keys.
{
  my $dsn_static = sub {
    return DBIO::AccessBroker::Static->new(
      dbname => 'dbi:T27DBD:service=app', username => 'app', password => 'hunter2', @_,
    );
  };
  my $want = { dsn => 'dbi:T27DBD:service=app', user => 'app', password => 'hunter2', attrs => {} };

  my $async = direct_async('T27::Driver::Storage::Async', $dsn_static->());
  is_deeply spawn($async), $want,
    'Static with a DSN for a dbname and no host, without an owner: no host or port among the DBD attributes';

  (my $schema, $async) = schema_async('T27::Driver::Storage',
    $dsn_static->(), { async => 'future_io' });
  is_deeply spawn($async), $want, '... nor through a schema connected with the future_io mode';

  # The owner's connect has read the answer once by now; this one is asked for
  # at the spawn, where only this dist reads it.
  $schema->storage->access_broker->host('db.example');
  throws_ok { spawn($async) }
    qr/Connection parameter\(s\) 'host' given beside a dbname that is a whole DSN: they cannot be put into it/,
    '... and a host the broker answers later is refused at that spawn';
  unlike $@, qr/hunter2|db\.example/, '... naming the key, no value';
  is connects($async), 1, '... and nothing more was connected';

  for my $case (
    [ 'a host', { host => 'db.example' }, q{'host'} ],
    [ 'a port', { port => 5433 }, q{'port'} ],
    [ 'a host and a port', { host => 'db.example', port => 5433 }, q{'host', 'port'} ],
  ) {
    my ($label, $beside, $named) = @$case;
    $async = direct_async('T27::Driver::Storage::Async', T27::AnswerBroker->new({
      dbname => 'dbi:T27DBD:service=app', user => 'app', password => 'hunter2', %$beside,
    }));
    throws_ok { spawn($async) }
      qr/Connection parameter\(s\) \Q$named\E given beside a dbname that is a whole DSN: they cannot be put into it/,
      "$label beside a dbname that is a DSN, without an owner: the spawn is refused, naming the key";
    unlike $@, qr/hunter2|db\.example|5433/, '... no value, never the password';
    is connects($async), 0, '... and nothing was connected';
  }

  $async = direct_async('T27::Driver::Storage::Async',
    $dsn_static->()->for_host({ host => 'replica.example', port => 6432 }));
  throws_ok { spawn($async) }
    qr/Connection parameter\(s\) 'host', 'port' given beside a dbname that is a whole DSN/,
    'HostBound over such a Static: refused, its host is not dropped as a DBD attribute';
  is connects($async), 0, '... and nothing was connected';

  $async = direct_async('T27::Driver::Storage::Async', T27::AnswerBroker->new({
    dbname => 'dbi:T27DBD:service=app', host => '', port => '',
    user => 'app', password => 'hunter2', t27_utf8 => 1,
  }));
  is_deeply spawn($async), { %$want, attrs => { t27_utf8 => 1 } },
    'an empty host and port beside the DSN are as none given: dropped, every other key stays a DBD attribute';
}

# ---------------------------------------------------------------------------
# 5. An answer nothing can connect from.
# ---------------------------------------------------------------------------

for my $case (
  [ 'a keyword string', [ 'host=db.example user=app password=hunter2' ],
    qr/an arrayref of \(string\)/ ],
  [ 'a hash with neither dsn nor dbname', { host => 'db.example', user => 'app', password => 'hunter2' },
    qr/a hashref with keys \(host, password, user\)/ ],
) {
  my ($label, $answer, $shape) = @$case;
  my $async = direct_async('T27::Driver::Storage::Async', T27::AnswerBroker->new($answer));
  throws_ok { spawn($async) }
    qr/T27::Driver::Storage::Async cannot connect from what the AccessBroker answered/,
    "unusable answer ($label): opening a connection croaks";
  like $@, $shape, '... naming the shape it received';
  unlike $@, qr/hunter2/, '... never the password';
  is connects($async), 0, '... and nothing was connected';
}

# An answer that is empty -- undef, {}, [], a false value -- is refused by
# core itself (core k249/k250, DBIO::Storage::current_access_broker_connect_info),
# before this dist's _async_broker_conninfo sees it: already when the broker is
# attached, and for every later connection whose broker has gone empty. The
# later case is the one that matters here: the earlier answer (and its
# password) must not be reused for the new connection.
my $no_answer = qr/AccessBroker T27::AnswerBroker answered no connect info/;

{
  my $async = T27::Driver::Storage::Async->new(undef);
  throws_ok { $async->connect_info([ T27::AnswerBroker->new(undef) ]); spawn($async) }
    $no_answer, 'an empty answer (undef) when the broker is attached: refused';
  like $@, qr/\(undef\)/, '... naming the shape it received';
  is connects($async), 0, '... and nothing was connected';
}

for my $case (
  [ undef, 'undef' ],
  [ {},    'an empty hashref' ],
  [ [],    'an empty arrayref' ],
  [ '',    'a false value' ],
) {
  my ($answer, $shape) = @$case;
  my $broker = T27::AnswerBroker->new([ 'dbi:T27DBD:dbname=appdb', 'app', 'hunter2', {} ]);
  my $async  = direct_async('T27::Driver::Storage::Async', $broker);
  is spawn($async)->{password}, 'hunter2', "broker gone empty ($shape): the first connection uses its answer";

  $broker->{answer} = $answer;
  throws_ok { spawn($async) } $no_answer, '... the next one is refused';
  like $@, qr/\(\Q$shape\E\)/, '... naming the shape it received';
  unlike $@, qr/hunter2|appdb/, '... never a value of the earlier answer';
  is connects($async), 1, '... and nothing more was connected';
}

# ---------------------------------------------------------------------------
# 6. DBD attributes beside the broker (core k243), on a declaring transport.
# ---------------------------------------------------------------------------

{
  my ($schema, $async) = schema_async('T27::DeclDriver::Storage',
    static(), { async => 'future_io', t27_timeout => 5 });
  is_deeply spawn($async),
    { dsn => 'dbi:T27DeclDBD:dbname=appdb;host=db.example;port=5433',
      user => 'app', password => 's3cret', attrs => { t27_timeout => 5 } },
    'Static with a DBD attribute beside it: the attribute reaches the pool connection';
}

{
  my $broker = vault(dsn => 'dbi:T27DeclDBD:dbname=appdb',
                     dbi_attrs => { t27_charset => 'charset-from-broker' });
  my $async = direct_async('T27::DeclDriver::Storage::Async',
    $broker, { t27_charset => 'charset-from-broker', t27_timeout => 5 });
  is_deeply spawn($async)->{attrs}, { t27_charset => 'charset-from-broker', t27_timeout => 5 },
    'Vault: the attributes beside it join the answer\'s, one given in both with the same value';

  $async = direct_async('T27::DeclDriver::Storage::Async',
    $broker, { t27_charset => 'charset-beside' });
  throws_ok { spawn($async) }
    qr/Connection setting 't27_charset' is given both beside the AccessBroker and in the broker's answer, with different values/,
    '... with different values: throws, naming the setting';
  unlike $@, qr/charset-beside|charset-from-broker/, '... not its values';
  is connects($async), 0, '... and nothing was connected';

  $async = direct_async('T27::DeclDriver::Storage::Async',
    T27::AnswerBroker->new({ dsn => 'dbi:T27DeclDBD:x', user => 'app', password => 'hunter2', attrs => {} }),
    { t27_timeout => 5 });
  throws_ok { spawn($async) }
    qr/The DBD attributes given beside the AccessBroker \(t27_timeout\) cannot be merged into what it answered, a hashref with keys \(attrs, dsn, password, user\)/,
    'the transport\'s own connect info: attributes beside the broker are refused, not dropped';
  unlike $@, qr/hunter2/, '... never the password';
  is connects($async), 0, '... and nothing was connected';
}

# ---------------------------------------------------------------------------
# 7. The seam itself refuses with no broker attached (karr k43). Through the
#    per-spawn provider core refuses first since dbio 4108809c8 (t/29), so this
#    is the check as a seam of its own: asked directly, as a driver's listen
#    connection or a test may, it croaks naming the class, and asks the driver
#    nothing.
# ---------------------------------------------------------------------------

{
  my $async = T27::Driver::Storage::Async->new(undef);
  throws_ok { $async->_async_broker_conninfo('write') }
    qr/^T27::Driver::Storage::Async has no AccessBroker attached to ask for connect info/,
    'no broker attached: the seam croaks, saying so';
  is connects($async), 0, '... and nothing was connected';

  my $gone = direct_async('T27::Driver::Storage::Async', static());
  $gone->clear_access_broker;
  throws_ok { $gone->_async_broker_conninfo('write') }
    qr/^T27::Driver::Storage::Async has no AccessBroker attached to ask for connect info/,
    'broker detached again: the seam croaks, saying so';
}

done_testing;
