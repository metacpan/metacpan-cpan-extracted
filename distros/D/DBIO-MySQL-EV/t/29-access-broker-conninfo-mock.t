use strict;
use warnings;
use Test::More;

# OFFLINE test: every built-in AccessBroker on the ev transport (karr k60; the
# same defect as dbio-postgresql-ev k54, found in dbio-postgresql k80).
#
# WHY: every connection this transport opens -- each pool spawn, and the
# dedicated listen connection at its open and at every reconnect -- is
# EV::MariaDB->new(%named), and %named is what _async_broker_conninfo made of
# the broker's answer. EV::MariaDB takes named parameters only: it parses no
# DSN and croaks on an argument it does not know. The seam handed the answer
# straight to the pair splitter, which takes its first element. A Static
# broker answers a hash, so it worked; a Vault broker answers the DBI form
# [ 'dbi:mysql:...', $user, $password, \%attrs ], so the first element was the
# bare DSN string, which the pool and the listen open wrapped as
# conninfo => $dsn -- an argument EV::MariaDB refuses -- and the user and the
# password were never read. HostBound over Vault alike.
#
# What this file claims:
#   1. for each built-in broker shape -- Static, Vault with a dbi:mysql: DSN,
#      Vault with a dbi:MariaDB: DSN, HostBound over Static, HostBound over
#      Vault -- a pool connection and the listen connection are both opened
#      with exactly the named parameters the broker's answer means: host,
#      port, database and its current user and password, and nothing else --
#      no DSN string, no DBIO-private attribute (async), no DBI attribute
#      (RaiseError); a DBD one (mysql_enable_utf8mb4) is translated, karr k80;
#   2. the broker is asked again for every connection: credentials that rotate
#      between two spawns reach the second one, and the listen connection
#      opened after them;
#   3. the transport's own shape still passes -- the pair [ \%conninfo, \%opts ]
#      with dbname read as database -- and a pool_size in the answer, in the
#      hash or among a DBI-form answer's attributes, sizes the pool and never
#      reaches EV::MariaDB;
#   4. an answer the transport cannot connect from croaks -- at attach, and at
#      a later spawn or listen open when the broker's answer turns bad --
#      naming its shape and never the password in it, and nothing reaches
#      EV::MariaDB;
#   5. the schema path: MyApp::Schema->connect($vault) with
#      dbi_attrs => { async => 'ev' } -- the way a DBI-form broker picks the
#      mode -- reaches this transport and connects from the broker.
#
# And, with karr k62 (the defect of dbio-postgresql-ev k61 / k63, core k252):
# a connection of a broker-backed storage is opened from the broker's CURRENT
# answer or not at all. connect_info kept the conninfo it made of the first
# answer -- password included -- and both the pool and the listen open fell
# back to it once the broker was gone. So:
#   6. a broker detached behind the transport's back (clear_access_broker,
#      which leaves the per-spawn provider in place) opens no connection: a
#      pool spawn and a listen open fail, saying that no broker is attached;
#   7. no conninfo is kept from a broker's answer -- its password is nowhere in
#      the storage object but in the broker -- and a storage whose broker and
#      provider are gone (_clear_access_broker) has nothing to connect from,
#      like one never given connect info;
#   8. static connect info, hash form and DBI form, is still stored and
#      connected from, and a change between a broker and static connect info
#      leaves only what belongs to the new one;
#   9. an answer naming neither a host nor a user is refused like any other
#      the transport cannot connect from: EV::MariaDB opens no connection
#      without one of them and never calls back, so the acquire would never
#      resolve.
#
# And, with karr k63 (measured against a server in
# t/38-access-broker-dsn-dbname-live.t):
#  10. a Static broker whose dbname is a whole DSN -- the form core's sync
#      storage takes as the DSN -- is refused: at attach, at every later pool
#      spawn and listen open, and under a HostBound view. The DSN string never
#      becomes the name of a database on whatever server the client library
#      defaults to, and the refusal names the form, never the DSN.
#
# WHAT RUNS FOR REAL: the built-in brokers, core's broker attach and per-spawn
# provider, core's pool, this dist's Pool and Storage (and EV, for the fork
# watchers both arm). THE SUBSTITUTIONS: EV::MariaDB records what it is
# constructed with, refuses what the real constructor refuses and, like it,
# starts a connect only when given a host or a user (the test plays the
# server's connect); the Vault client is a stub whose secret the test sets.

BEGIN {
  package EV::MariaDB;
  use Carp ();
  use Scalar::Util ();

  our @NEW;   # every handle made: [ \%named (without the callbacks), the handle (weak) ]

  # What EV::MariaDB 0.08's constructor takes. Like the real one, the fake
  # croaks on anything else -- 'conninfo' included.
  my %ALLOWED = map { $_ => 1 } qw(
    connect_timeout read_timeout write_timeout
    compress multi_statements charset init_command
    ssl_key ssl_cert ssl_ca ssl_capath ssl_cipher ssl_verify_server_cert
    utf8 found_rows
    loop on_connect on_error
    host user password database db port unix_socket
  );

  sub new {
    my ($class, %args) = @_;
    if (my @unknown = grep { !$ALLOWED{$_} } keys %args) {
      Carp::croak('unknown argument(s) to new(): ' . join(', ', sort @unknown));
    }
    my $self = bless {
      on_connect => delete $args{on_connect},
      on_error   => delete $args{on_error},
      connected  => 0,
      # EV::MariaDB 0.08's new() calls connect() only then; without either the
      # handle stays unconnected and neither callback ever fires.
      connecting => (defined $args{host} || defined $args{user}) ? 1 : 0,
    }, $class;
    push @NEW, [ { %args }, $self ];
    Scalar::Util::weaken($NEW[-1][1]);
    return $self;
  }

  sub is_connected { $_[0]{connected} ? 1 : 0 }
  sub socket       { -1 }   # the handle seam asks (karr k95); no socket here
  sub finish       { $_[0]{connected} = 0; return }
  # As strict as EV::MariaDB 0.08 (karr k67).
  sub close_async  { Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2; Carp::croak('not connected') unless $_[0]{connected}; $_[0]->finish; $_[1]->(1); return }

  # The server's side: the connect completes.
  sub t_connect {
    my ($self) = @_;
    Carp::croak('this handle never started a connect: it was given neither a host nor a user')
      unless $self->{connecting};
    $self->{connected} = 1;
    $self->{on_connect}->() if $self->{on_connect};
    return;
  }

  $INC{'EV/MariaDB.pm'} = __FILE__;
}

use EV;
use Scalar::Util ();
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::AccessBroker::HostBound;
use DBIO::MySQL::EV::Storage;

alarm 60;

# The read of character set and collation after a spawn (karr k100) blocks
# until the handle is connected; this test connects its fake handles itself,
# after the spawn. t/59-session-reset-mock.t and t/07 hold that read.
{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Storage::_mysql_remember_session_names = sub { return };
}

# The Vault client: read_secret answers whatever the test last put in it.
{
  package FakeVaultClient;
  sub new { bless { secret => { username => 'vault-user-1', password => 'vault-pw-1' }, reads => 0 }, shift }
  sub read_secret { my ($self) = @_; $self->{reads}++; return { %{ $self->{secret} } } }
}

# A broker answering whatever the test puts in it.
{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

sub transport_with {
  my ($broker) = @_;
  my $s = DBIO::MySQL::EV::Storage->new(undef);
  $s->connect_info([ $broker ]);
  return $s;
}

# One new pool connection: the named parameters EV::MariaDB was constructed
# with. The connection is acquired and kept, so the next spawn is a new one.
sub spawn_params {
  my ($s) = @_;
  @EV::MariaDB::NEW = ();
  my $f = $s->pool->acquire;
  die "acquire failed: " . ($f->failure)[0] if $f->is_failed;
  die scalar(@EV::MariaDB::NEW) . " EV::MariaDB handles made for one spawn\n"
    unless @EV::MariaDB::NEW == 1;
  my ($params, $mdb) = @{ $EV::MariaDB::NEW[0] };
  delete $params->{found_rows};   # on for every handle (karr k80, t/54); not what this file is about
  $mdb->t_connect;
  die "the spawned connection was not handed out\n" unless $f->is_done && $f->get == $mdb;
  return $params;
}

# One open of the listen connection: the named parameters EV::MariaDB was
# constructed with. The connection is closed again.
sub listen_params {
  my ($s) = @_;
  @EV::MariaDB::NEW = ();
  my $f = $s->_listen_open;
  die scalar(@EV::MariaDB::NEW) . " EV::MariaDB handles made for one listen open\n"
    unless @EV::MariaDB::NEW == 1;
  my ($params, $mdb) = @{ $EV::MariaDB::NEW[0] };
  delete $params->{found_rows};   # on for every handle (karr k80, t/54); not what this file is about
  $mdb->t_connect;
  $s->_listen_close($f->get);
  return $params;
}

sub vault {
  my (%args) = @_;
  return DBIO::AccessBroker::Vault->new(
    vault     => FakeVaultClient->new,
    dsn       => 'dbi:mysql:database=appdb;host=db.example;port=3307',
    cred_path => 'database/creds/app',
    dbi_attrs => { RaiseError => 1, async => 'ev' },
    %args,
  );
}

sub static {
  return DBIO::AccessBroker::Static->new(
    host     => 'db.example',
    port     => 3307,
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
    { database => 'appdb', host => 'db.example', port => 3307, user => 'app', password => 's3cret' } ],
  [ 'Vault (dbi:mysql:)',
    sub { vault() },
    { database => 'appdb', host => 'db.example', port => 3307,
      user => 'vault-user-1', password => 'vault-pw-1' } ],
  [ 'Vault (dbi:MariaDB:, dbname=)',
    sub {
      vault(
        dsn       => 'dbi:MariaDB:dbname=appdb;host=db.example;port=3307',
        dbi_attrs => { AutoCommit => 1, async => 'ev' },
      );
    },
    { database => 'appdb', host => 'db.example', port => 3307,
      user => 'vault-user-1', password => 'vault-pw-1' } ],
  [ 'HostBound over Static',
    sub { static()->for_host({ host => 'replica.example', port => 3399 }) },
    { database => 'appdb', host => 'replica.example', port => 3399, user => 'app', password => 's3cret' } ],
  [ 'HostBound over Vault',
    sub { vault()->for_host({ host => 'replica.example', port => 3399 }) },
    { database => 'appdb', host => 'replica.example', port => 3399,
      user => 'vault-user-1', password => 'vault-pw-1' } ],
) {
  my ($label, $build, $want) = @$case;
  my $s = eval { transport_with($build->()) };
  ok $s, "$label: the broker attaches" or diag $@;
  next unless $s;

  my $pool = eval { spawn_params($s) };
  is_deeply $pool, $want,
    "$label: a pool connection is opened with the broker's host, port, database, user and password -- nothing else"
    or diag $@;

  my $listen = eval { listen_params($s) };
  is_deeply $listen, $want,
    "$label: the listen connection is opened with the same parameters"
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
  my $s = eval { transport_with($wrap->($vault)) };
  ok $s, "$label: the broker attaches" or diag $@;
  next unless $s;

  my $first = eval { spawn_params($s) } || {};
  is_deeply [ @$first{qw( user password )} ], [ 'vault-user-1', 'vault-pw-1' ],
    "$label: the first pool connection uses the credentials Vault issued"
    or diag $@;

  $vault->vault->{secret} = { username => 'vault-user-2', password => 'vault-pw-2' };
  $vault->_expires_at(0);   # the lease is up
  my $reads = $vault->vault->{reads};

  my $second = eval { spawn_params($s) } || {};
  is $vault->vault->{reads}, $reads + 1, "$label: the expired lease was renewed for the next spawn";
  is_deeply [ @$second{qw( user password )} ], [ 'vault-user-2', 'vault-pw-2' ],
    "$label: ... and the second pool connection uses the ROTATED credentials"
    or diag $@;

  my $listen = eval { listen_params($s) } || {};
  is_deeply [ @$listen{qw( user password )} ], [ 'vault-user-2', 'vault-pw-2' ],
    "$label: the listen connection opened after the rotation uses them too"
    or diag $@;
}

# ---------------------------------------------------------------------------
# 3. The transport's own shape, and pool_size.
# ---------------------------------------------------------------------------

{
  my $s = transport_with(AnswerBroker->new(
    [ { dbname => 'appdb', host => 'db.example', user => 'app', password => 'pw', pool_size => 3 }, {} ]
  ));
  my $params = eval { spawn_params($s) };
  is_deeply $params,
    { database => 'appdb', host => 'db.example', user => 'app', password => 'pw' },
    'a [ \\%conninfo, \\%opts ] pair is read by its hash, dbname as database; pool_size does not reach EV::MariaDB'
    or diag $@;
  is $s->pool->max_size, 3, '... and sizes the pool';

  # Attaching reads the answer too: before the fix it kept the DSN string and
  # sized the pool by default, so the two assertions below failed with it.
  $s = transport_with(vault(dbi_attrs => { pool_size => 3, async => 'ev' }));
  $params = eval { spawn_params($s) };
  is_deeply $params,
    { database => 'appdb', host => 'db.example', port => 3307,
      user => 'vault-user-1', password => 'vault-pw-1' },
    'a DBI-form answer with pool_size among its attributes: pool_size does not reach EV::MariaDB'
    or diag $@;
  is $s->pool->max_size, 3, '... and sizes the pool, as in DBI-form connect info';
}

# ---------------------------------------------------------------------------
# 4. An answer the transport cannot connect from.
# ---------------------------------------------------------------------------

my $CANNOT = qr/MySQL ev cannot connect from what the AccessBroker returned/;

for my $case (
  [ 'a DBI-form arrayref for another driver',
    [ 'dbi:Pg:dbname=appdb;password=hunter2', 'app', 'hunter2', {} ],
    qr/a DBI-form arrayref whose DSN is not dbi:mysql:<parameters> or dbi:MariaDB:<parameters> \(DBI driver 'Pg'\)/ ],
  [ 'a string that is no DBI DSN, with user and password beside it',
    [ 'host=db.example;password=hunter2', 'app', 'hunter2' ],
    qr/an arrayref of \(string, string, string\)/ ],
  [ 'a plain string',
    'host=db.example;password=hunter2',
    qr/a plain string/ ],
  [ 'a connect coderef',
    [ sub { 'hunter2' }, {} ],
    qr/an arrayref of \(CODE ref, HASH ref\)/ ],
) {
  my ($label, $answer, $shape_re) = @$case;

  # At attach.
  @EV::MariaDB::NEW = ();
  my $s   = DBIO::MySQL::EV::Storage->new(undef);
  my $ok  = eval { $s->connect_info([ AnswerBroker->new($answer) ]); 1 };
  my $err = $@;
  ok !$ok, "unusable answer ($label): attaching the broker croaks";
  like $err, $CANNOT, '... saying what it could not connect from';
  like $err, $shape_re, '... naming the shape it received';
  unlike $err, qr/hunter2/, '... and never the password';

  # Later: the broker answered well at attach, then turns bad.
  my $broker = AnswerBroker->new({ dbname => 'appdb', host => 'db.example', user => 'app', password => 'pw' });
  $s = transport_with($broker);
  $broker->{answer} = $answer;
  @EV::MariaDB::NEW = ();

  my $f = eval { $s->pool->acquire };
  my ($spawn_err) = !$f ? ($@) : $f->is_failed ? $f->failure : ('');
  like $spawn_err, $CANNOT, "unusable answer ($label) at a later spawn: it is refused";
  like $spawn_err, $shape_re, '... naming the shape';
  unlike $spawn_err, qr/hunter2/, '... and never the password';

  $ok  = eval { $s->_listen_open; 1 };
  $err = $@;
  ok !$ok, "unusable answer ($label) at a later listen open: it croaks";
  like $err, $shape_re, '... naming the shape';
  unlike $err, qr/hunter2/, '... and never the password';

  is scalar(@EV::MariaDB::NEW), 0, '... and nothing was handed to EV::MariaDB';
}

# ---------------------------------------------------------------------------
# 5. The schema path: a Vault broker selects the mode in its DBI attributes.
# ---------------------------------------------------------------------------

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
}

{
  my $schema = BrokerSchema->connect(vault());
  my $async  = eval { $schema->storage->async };
  isa_ok $async, 'DBIO::MySQL::EV::Storage',
    'MyApp::Schema->connect($vault) with dbi_attrs { async => ev }'
    or diag $@;
  my $params = eval { spawn_params($async) };
  is_deeply $params,
    { database => 'appdb', host => 'db.example', port => 3307,
      user => 'vault-user-1', password => 'vault-pw-1' },
    '... connects its pool from the broker: DSN parts, user and password, no async attribute'
    or diag $@;
}

# ---------------------------------------------------------------------------
# 6. A broker detached behind the transport's back.
# ---------------------------------------------------------------------------

# clear_access_broker is public on DBIO::Storage, and called directly it leaves
# the per-spawn provider in place -- on the storage, and in a pool that was
# built with it. Core's seam _current_async_connect_info answers what
# connect_info stored when no broker is attached, so a provider reading it
# without looking for the broker connects from whatever is stored. That must
# never be a broker's earlier answer (core k249: the credentials may have been
# rotated out), and it is no broker's answer either: the refusal says what is
# wrong -- no broker is attached -- instead of naming the shape of an answer
# no broker gave.
for my $case (
  [ 'no pool yet',                  sub { } ],
  [ 'a pool with a connection out', sub { spawn_params($_[0]) } ],
) {
  my ($label, $before) = @$case;
  my $s = transport_with(static(password => 'hunter2'));
  $before->($s);
  $s->clear_access_broker;
  @EV::MariaDB::NEW = ();

  my $f = eval { $s->pool->acquire };
  my ($spawn_err) = !$f ? ($@) : $f->is_failed ? $f->failure : ('');
  like $spawn_err, qr/no AccessBroker attached/,
    "broker detached ($label): a pool spawn fails, saying that no broker is attached";
  unlike $spawn_err, qr/AccessBroker returned/, '... not that a broker answered something unusable';
  unlike $spawn_err, qr/hunter2/, '... without the password of the earlier answer';

  my $ok  = eval { $s->_listen_open; 1 };
  my $err = $@;
  ok !$ok, "broker detached ($label): a listen open croaks";
  like $err, qr/no AccessBroker attached/, '... saying that no broker is attached';
  unlike $err, qr/AccessBroker returned/, '... not that a broker answered something unusable';
  unlike $err, qr/hunter2/, '... without the password of the earlier answer';

  is_deeply [ map { $_->[0] } @EV::MariaDB::NEW ], [],
    '... and nothing was handed to EV::MariaDB: no connection from the answer of the attach';
}

# A pool keeps the provider it was built with, so core's _clear_access_broker
# -- broker and the storage's provider both gone -- does not reach it either.
{
  my $s = transport_with(static(password => 'hunter2'));
  spawn_params($s);
  $s->_clear_access_broker;
  @EV::MariaDB::NEW = ();

  my $f = eval { $s->pool->acquire };
  my ($spawn_err) = !$f ? ($@) : $f->is_failed ? $f->failure : ('');
  like $spawn_err, qr/no AccessBroker attached/,
    'broker and provider gone, the pool built before: its next spawn fails, saying that no broker is attached';
  unlike $spawn_err, qr/hunter2/, '... without the password of the earlier answer';
  is_deeply [ map { $_->[0] } @EV::MariaDB::NEW ], [], '... and nothing was handed to EV::MariaDB';
}

# ---------------------------------------------------------------------------
# 7. No conninfo is kept from a broker's answer.
# ---------------------------------------------------------------------------

# Every place in the storage where a plain value contains $needle, as a path.
# A broker is not looked into: it is the one that may hold the password. Code
# is not looked into either.
sub holding {
  my ($value, $needle, $path, $seen) = @_;
  $path //= '$storage';
  $seen //= {};
  return () unless defined $value;
  return index($value, $needle) >= 0 ? ($path) : () unless ref $value;
  return () if Scalar::Util::blessed($value) && $value->isa('DBIO::AccessBroker');
  return () if $seen->{ Scalar::Util::refaddr($value) }++;
  my $type = Scalar::Util::reftype($value);
  return map { holding($value->{$_}, $needle, "$path\->{$_}", $seen) } sort keys %$value
    if $type eq 'HASH';
  return map { holding($value->[$_], $needle, "$path\->[$_]", $seen) } 0 .. $#$value
    if $type eq 'ARRAY';
  return holding($$value, $needle, "\${ $path }", $seen)
    if $type eq 'SCALAR' || $type eq 'REF';
  return ();
}

# What a storage does when asked for a connection: how a pool spawn and a
# listen open end (the error without its location), and what reached
# EV::MariaDB.
sub connection_attempts {
  my ($s) = @_;
  @EV::MariaDB::NEW = ();
  my %got;
  for my $attempt (
    [ pool   => sub { my $f = $s->pool->acquire; die +($f->failure)[0] if $f->is_failed } ],
    [ listen => sub { $s->_listen_open } ],
  ) {
    my ($name, $code) = @$attempt;
    $got{$name} = eval { $code->(); 1 } ? 'no error' : $@ =~ s/ at \S+ line \d+\.?\n?\z//r;
  }
  $got{handles} = [ map { $_->[0] } @EV::MariaDB::NEW ];
  return \%got;
}

# A storage that was never given connect info: what "nothing to connect from"
# looks like on this transport.
my $unconfigured = connection_attempts(DBIO::MySQL::EV::Storage->new(undef));
isnt $unconfigured->{pool},   'no error', 'a storage never given connect info: no pool connection';
isnt $unconfigured->{listen}, 'no error', '... and no listen connection';
is_deeply $unconfigured->{handles}, [], '... nothing reaches EV::MariaDB';

for my $case (
  [ 'Static (a hash of parameters)',
    sub { static(password => 'static-pw') }, 'static-pw' ],
  [ 'Vault (the DBI form)',
    sub { vault() }, 'vault-pw-1' ],
  [ 'HostBound over Vault',
    sub { vault()->for_host({ host => 'replica.example', port => 3399 }) }, 'vault-pw-1' ],
  [ 'a [ \%conninfo, \%opts ] pair',
    sub { AnswerBroker->new([ { host => 'db.example', user => 'app', password => 'pair-pw' }, {} ]) }, 'pair-pw' ],
) {
  my ($label, $build, $password) = @$case;

  # Attached.
  my $s = transport_with($build->());
  ok $s->access_broker && $s->_conninfo_provider, "$label: the broker is attached, with its provider";
  is $s->{_conninfo}, undef, '... and no conninfo is kept from its answer';
  is $s->_conninfo_hash, undef, '... _conninfo_hash, the stored conninfo, has none to return';
  is_deeply [ holding($s, $password) ], [],
    '... the password of the answer is nowhere in the storage object but in the broker';
  is eval { spawn_params($s)->{password} }, $password,
    '... while a pool connection still gets it, from the broker'
    or diag $@;
  is eval { listen_params($s)->{password} }, $password,
    '... and so does the listen connection'
    or diag $@;

  # The broker taken away, its provider left in place (section 6): core's
  # seam is all that could still name the earlier answer.
  my $taken = transport_with($build->());
  $taken->clear_access_broker;
  my $info = $taken->_current_async_connect_info('write');
  ok !defined $info->[0],
    "$label, broker taken away: core's seam does not answer the broker's earlier answer";

  # Broker and provider gone, as core's _clear_access_broker leaves a
  # storage: nothing stands between a connection and what is stored.
  my $gone = transport_with($build->());
  $gone->_clear_access_broker;
  is $gone->_conninfo_hash, undef,
    "$label, broker and provider gone: there is no stored conninfo";
  my $attempts = connection_attempts($gone);
  is_deeply $attempts->{handles}, [],
    '... no connection is opened from the earlier answer';
  unlike "$attempts->{pool} $attempts->{listen}", qr/\Q$password\E/,
    '... and no error carries its password';
  is_deeply $attempts, $unconfigured,
    '... the storage has nothing to connect from, like one never given connect info';
}

# ---------------------------------------------------------------------------
# 8. Static connect info is stored, and a change of form leaves nothing behind.
# ---------------------------------------------------------------------------

# Static connect info is all a static connection is opened from, so it stays
# stored -- in both forms the transport takes.
my %STATIC = (
  database => 'staticdb', host => 'static.example', port => 3311,
  user => 'static-user', password => 'static-pw',
);

for my $case (
  [ 'hash form',
    [ { dbname => 'staticdb', host => 'static.example', port => 3311,
        user => 'static-user', password => 'static-pw', pool_size => 2 }, {} ] ],
  [ 'DBI form',
    [ 'dbi:mysql:database=staticdb;host=static.example;port=3311', 'static-user', 'static-pw',
      { pool_size => 2 } ] ],
) {
  my ($label, $info) = @$case;
  my $s = DBIO::MySQL::EV::Storage->new(undef);
  $s->connect_info($info);
  ok !$s->access_broker && !$s->_conninfo_provider, "static connect info ($label): no broker, no provider";
  is_deeply $s->_conninfo_hash, \%STATIC, '... the conninfo is stored, as EV::MariaDB named parameters';
  is_deeply eval { spawn_params($s) }, \%STATIC, '... a pool connection is opened from it' or diag $@;
  is $s->pool->max_size, 2, '... the pool sized by its pool_size';
  is_deeply eval { listen_params($s) }, \%STATIC, '... and so is the listen connection' or diag $@;
}

# Each change between a broker and static connect info leaves only what
# belongs to the new one.
{
  my $s = DBIO::MySQL::EV::Storage->new(undef);

  $s->connect_info([ static(password => 'first-broker-pw') ]);
  is $s->{_conninfo}, undef, 'a broker first: no conninfo is stored';
  is eval { spawn_params($s)->{password} }, 'first-broker-pw',
    '... a pool connection is opened from the broker'
    or diag $@;

  $s->connect_info([ 'dbi:mysql:database=staticdb;host=static.example;port=3311', 'static-user', 'static-pw' ]);
  ok !$s->access_broker && !$s->_conninfo_provider,
    'then static connect info: the broker and its provider are gone';
  is_deeply $s->{_conninfo}, \%STATIC, '... and the static conninfo is stored';
  is_deeply [ holding($s, 'first-broker-pw') ], [], "... with nothing left of the broker's answer";
  is_deeply eval { spawn_params($s) }, \%STATIC, '... a pool connection is opened from it' or diag $@;
  is_deeply eval { listen_params($s) }, \%STATIC, '... and so is the listen connection' or diag $@;

  $s->connect_info([ vault() ]);
  ok $s->access_broker && $s->_conninfo_provider, 'then a broker again: it is attached, with its provider';
  is $s->{_conninfo}, undef, '... and no conninfo is stored: neither its answer nor the static one before it';
  is_deeply [ holding($s, 'static-pw') ], [], '... the static password is gone from the storage object';
  is_deeply [ holding($s, 'vault-pw-1') ], [], "... and the broker's is nowhere but in the broker";
  my %from_vault = (
    database => 'appdb', host => 'db.example', port => 3307,
    user => 'vault-user-1', password => 'vault-pw-1',
  );
  is_deeply eval { spawn_params($s) }, \%from_vault,
    '... a pool connection is opened from the second broker, with nothing of the static connect info'
    or diag $@;
  is_deeply eval { listen_params($s) }, \%from_vault, '... and so is the listen connection' or diag $@;

  $s->_clear_access_broker;
  $s->disconnect;   # the pool built for that broker goes with it
  is_deeply connection_attempts($s), $unconfigured,
    '... and with that broker gone, none is opened from the static connect info before it';
}

# Nor does a broker whose answer is refused at attach: the static connect info
# of before is gone with the attempt, not left for a later fallback.
{
  my $s = DBIO::MySQL::EV::Storage->new(undef);
  $s->connect_info([ { %STATIC }, {} ]);
  ok !eval { $s->connect_info([ AnswerBroker->new('no connect info at all') ]); 1 },
    'static connect info, then a broker whose answer is refused: attaching croaks';
  is $s->{_conninfo}, undef, '... and the static conninfo of before is not kept';
  is_deeply [ holding($s, 'static-pw') ], [], '... its password is gone from the storage object';
  $s->_clear_access_broker;
  is_deeply connection_attempts($s), $unconfigured,
    '... so with the refused broker gone, nothing is opened from it';
}

# ---------------------------------------------------------------------------
# 9. An answer EV::MariaDB opens no connection from.
# ---------------------------------------------------------------------------

# EV::MariaDB's constructor starts a connect only when it is given a host or a
# user. Given neither it returns a handle that never connects and calls
# neither on_connect nor on_error -- so the pool's acquire, which resolves on
# one of the two, would never resolve, and nothing would say why. Core refuses
# a broker that answers nothing at all (undef, {}, []); these answers are not
# nothing, and they pass every shape this transport takes.
my $NO_TARGET = qr/names neither a host nor a user/;

for my $case (
  [ 'a hash holding only pool_size',
    { pool_size => 3 },
    qr/a hashref with keys \(pool_size\)/ ],
  [ 'a pair with an empty hash',
    [ {}, {} ],
    qr/an empty hashref/ ],
  [ 'a hash with a database and a password, no host and no user',
    { dbname => 'appdb', password => 'hunter2' },
    qr/a hashref with keys \(dbname, password\)/ ],
  [ 'a hash whose host and user are undefined',
    { host => undef, user => undef, password => 'hunter2' },
    qr/a hashref with keys \(host, password, user\)/ ],
  [ 'a DBI-form answer with a database only',
    [ 'dbi:mysql:database=appdb', undef, 'hunter2' ],
    qr/an arrayref of \(string, undef, string\)/ ],
) {
  my ($label, $answer, $shape_re) = @$case;

  # At attach.
  @EV::MariaDB::NEW = ();
  my $s   = DBIO::MySQL::EV::Storage->new(undef);
  my $ok  = eval { $s->connect_info([ AnswerBroker->new($answer) ]); 1 };
  my $err = $@;
  ok !$ok, "no host and no user ($label): attaching the broker croaks";
  like $err, $CANNOT, '... saying what it could not connect from';
  like $err, $NO_TARGET, '... and why';
  like $err, $shape_re, '... naming the shape it received';
  unlike $err, qr/hunter2/, '... and never the password';

  # Later: the broker answered well at attach, then stops naming a target.
  my $broker = AnswerBroker->new({ dbname => 'appdb', host => 'db.example', user => 'app', password => 'pw' });
  $s = transport_with($broker);
  $broker->{answer} = $answer;
  @EV::MariaDB::NEW = ();

  my $f = eval { $s->pool->acquire };
  my ($spawn_err) = !$f ? ($@) : $f->is_failed ? $f->failure : ('');
  like $spawn_err, $NO_TARGET, "no host and no user ($label) at a later spawn: it is refused";
  unlike $spawn_err, qr/hunter2/, '... and never the password';

  $ok  = eval { $s->_listen_open; 1 };
  $err = $@;
  ok !$ok, "no host and no user ($label) at a later listen open: it croaks";
  like $err, $NO_TARGET, '... saying why';
  unlike $err, qr/hunter2/, '... and never the password';

  is scalar(@EV::MariaDB::NEW), 0, '... and no handle was made that would never connect';
}

# One of the two is enough: which parameters a connection needs beyond that is
# the server's to say.
for my $case (
  [ 'a user only', { user => 'app', password => 'pw' } ],
  [ 'a host only', { host => 'db.example' } ],
) {
  my ($label, $answer) = @$case;
  my $s = eval { transport_with(AnswerBroker->new({ %$answer })) };
  ok $s, "$label: the broker attaches" or diag $@;
  is_deeply eval { $s && spawn_params($s) }, $answer, '... and a pool connection is opened from it'
    or diag $@;
}

# ---------------------------------------------------------------------------
# 10. A Static broker whose dbname is a whole DSN (karr k63).
# ---------------------------------------------------------------------------

# Core documents the form (DBIO::AccessBroker::Static, ADR 0057), and its sync
# storage takes such a dbname as the DSN. The broker still answers a hash --
# { dbname => <the DSN>, host => undef, port => undef, user, password } -- and
# this transport reads a hash as EV::MariaDB parameters: the DSN string became
# the database name and no host was given. With a user in it the answer passed
# section 9, and EV::MariaDB connected to the client library's default, the
# local server, with the broker's user and password
# (t/38-access-broker-dsn-dbname-live.t has the measurement).
#
# Decided (karr k63): the transport refuses the answer -- it does not read the
# DSN out of the hash. Like every other answer it cannot connect from: at
# attach, and at a later spawn or listen open when the broker's answer turns
# into this one; nothing reaches EV::MariaDB. The refusal names the form and
# says what the broker is to answer instead. It quotes nothing of the DSN,
# which is where a password is written.
my $DSN_AS_NAME = qr/whose database name is a whole DBI DSN/;
my $DSN_DBNAME  = 'dbi:mysql:database=appdb;host=db.example;port=3307;password=hunter2';

for my $case (
  [ 'a Static broker whose dbname is a whole DSN',
    sub { DBIO::AccessBroker::Static->new(dbname => $DSN_DBNAME, username => 'app', password => 'hunter2') },
    qr/a hashref with keys \(dbname, host, password, port, user\)/ ],
  # A HostBound view binds a host into the hash. It is not the host the DSN
  # names, and the DSN is still where the database's name belongs.
  [ 'HostBound over such a Static',
    sub {
      DBIO::AccessBroker::Static->new(dbname => $DSN_DBNAME, username => 'app', password => 'hunter2')
        ->for_host({ host => 'replica.example', port => 3399 });
    },
    qr/a hashref with keys \(dbname, host, password, port, user\)/ ],
  [ 'a hash naming the DSN as database',
    sub { AnswerBroker->new({ database => $DSN_DBNAME, user => 'app', password => 'hunter2' }) },
    qr/a hashref with keys \(database, password, user\)/ ],
  [ 'a [ \%conninfo, \%opts ] pair naming it as db, with a host beside it',
    sub { AnswerBroker->new([ { db => uc $DSN_DBNAME, host => 'db.example', user => 'app', password => 'hunter2' }, {} ]) },
    qr/a hashref with keys \(db, host, password, user\)/ ],
) {
  my ($label, $build, $shape_re) = @$case;

  # At attach.
  @EV::MariaDB::NEW = ();
  my $s   = DBIO::MySQL::EV::Storage->new(undef);
  my $ok  = eval { $s->connect_info([ $build->() ]); 1 };
  my $err = $@;
  ok !$ok, "$label: attaching the broker croaks";
  like $err, $CANNOT, '... saying what it could not connect from';
  like $err, $DSN_AS_NAME, '... and why: the name of the database is a whole DSN';
  like $err, $shape_re, '... naming the shape it received';
  like $err, qr/answer the DSN in the DBI form \[ \$dsn, \$user, \$password \], or the database name as dbname with host and port beside it/,
    '... and what the broker is to answer instead';
  unlike $err, qr/hunter2|appdb|db\.example|3307|password=/i, '... with nothing of the DSN, and never the password';
  is $s->{_conninfo}, undef, '... nothing is stored as conninfo';
  is scalar(@EV::MariaDB::NEW), 0, '... and nothing was handed to EV::MariaDB';

  # Later: the broker answered well at attach, then answers this.
  my $broker = AnswerBroker->new({ dbname => 'appdb', host => 'db.example', user => 'app', password => 'pw' });
  $s = transport_with($broker);
  $broker->{answer} = $build->()->connect_info_for('write');

  my $attempts = connection_attempts($s);
  like $attempts->{pool}, $DSN_AS_NAME, "$label at a later spawn: it is refused";
  like $attempts->{listen}, $DSN_AS_NAME, "$label at a later listen open: it is refused";
  unlike "$attempts->{pool} $attempts->{listen}", qr/hunter2|appdb|3307|password=/i, '... with nothing of the DSN in either message';
  is_deeply $attempts->{handles}, [],
    '... and nothing was handed to EV::MariaDB: no connection to the client library\'s default';
}

# What stays: a database whose name merely holds the letters, and the DSN where
# a DSN belongs -- the DBI form (section 1 has Vault's).
{
  my $s = eval { transport_with(AnswerBroker->new({ dbname => 'mydbi:db', host => 'db.example', user => 'app' })) };
  ok $s, 'a database name that does not start with dbi: is no DSN: the broker attaches' or diag $@;
  is_deeply eval { $s && spawn_params($s) }, { database => 'mydbi:db', host => 'db.example', user => 'app' },
    '... and a pool connection is opened with it' or diag $@;

  $s = eval { transport_with(AnswerBroker->new([ 'dbi:mysql:database=appdb;host=db.example;port=3307', 'app', 's3cret' ])) };
  ok $s, 'the same DSN in the DBI form: the broker attaches' or diag $@;
  is_deeply eval { $s && spawn_params($s) },
    { database => 'appdb', host => 'db.example', port => 3307, user => 'app', password => 's3cret' },
    '... and a pool connection is opened with the host, port and database the DSN names' or diag $@;
}

done_testing;
