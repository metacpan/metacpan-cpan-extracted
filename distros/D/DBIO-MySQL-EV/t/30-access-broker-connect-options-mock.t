use strict;
use warnings;
use Test::More;

# OFFLINE test: the connect options beside an AccessBroker on the ev transport
# (karr k59; core k240 / k243 / k245 -- the same step as dbio-postgresql-ev k60
# and dbio-mysql k64).
#
# WHY: core takes connect options beside a broker --
# MyApp::Schema->connect($broker, { async => 'ev', pool_size => 3, ... }). What
# the owning sync storage applies itself (the mode, storage and SQL maker
# options) stays with it. What a backend applies -- pool_size and the DBD
# attributes -- core hands on as [ $broker, \%options ], but only to a transport
# that declares 'broker_connect_options'; for any other it refuses the
# connection at first async use, because the sync side would otherwise run with
# settings none of the pooled connections has. This transport did not declare
# it, so a pool could not be sized beside a broker at all. And its connect_info
# override never took the two-element form: handed one, it read the BROKER
# OBJECT as the conninfo, attached no broker and kept the default pool size --
# and the pool then handed EV::MariaDB conninfo => $broker, an argument it
# refuses.
#
# The declaration is a promise, so this file claims the behaviour behind it:
#   1. the schema path: connect($broker, { async => 'ev', pool_size => 3 }) is
#      not refused, the pool has three connections, and EV::MariaDB gets
#      exactly the named parameters the broker's answer means -- no pool_size,
#      no DBIO option, no DBD attribute;
#   2. the pool is sized from wherever the size is given -- the broker's hash
#      answer, slot [3] or slot [4] of a DBI-form answer (a later slot winning,
#      as the sync storage merges them), or beside the broker -- for every
#      built-in broker shape. Given both in the answer and beside the broker,
#      the two must agree: the same value is fine, different values throw
#      naming pool_size, rather than one of them winning silently;
#   3. DBD attributes beside the broker are treated as this transport treats
#      the same keys in DBI-form connect info: they never reach EV::MariaDB,
#      which croaks on an argument it does not know, and they do not fail the
#      connect. The owner's own options (on_connect_do, quote_names, async)
#      never reach it either. (A key that is no DBI attribute by its name --
#      an EV::MariaDB parameter such as charset -- is refused beside a broker
#      since karr k78: t/39-access-broker-parameters-beside-mock.t);
#   4. the broker stays attached in the two-element form: it is asked again for
#      every connection, so rotated credentials reach the next one, and no
#      conninfo is kept from its answer (karr k62) -- its password is nowhere
#      in the storage object but in the broker;
#   5. the declaration and the behaviour are one thing: the transport declares
#      broker_connect_options, and the same connect_info on a transport that
#      does not declare it is refused through core's gate, with nothing
#      configured -- the override takes the form only as a declared promise;
#   6. DBI-form connect info: pool_size in the fifth element (\%extra_attributes)
#      sizes the pool, and wins over the fourth -- only slot [3] was read, so
#      connect($dsn, $user, $pass, \%attrs, { pool_size => N }) left the pool
#      at its default. Nothing else of either hash reaches EV::MariaDB.
#
# WHAT RUNS FOR REAL: the built-in brokers, core's broker attach, option split
# and pool-size rule, core's sync storage and its _async_storage gate, this
# dist's Storage, ConnectInfo and Pool (and EV, for the fork watchers both
# arm). THE SUBSTITUTIONS: EV::MariaDB records what it is constructed with,
# refuses what the real constructor refuses and, like it, starts a connect only
# when given a host or a user (the test plays the server's connect) -- the fake
# of t/29-access-broker-conninfo-mock.t; the Vault client is a stub whose
# secret the test sets.

BEGIN {
  package EV::MariaDB;
  use Carp ();
  use Scalar::Util ();

  our @NEW;   # every handle made: [ \%named (without the callbacks), the handle (weak) ]

  # What EV::MariaDB 0.08's constructor takes. Like the real one, the fake
  # croaks on anything else -- 'conninfo', 'pool_size' and every DBD attribute
  # included.
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
use DBIO::MySQL::EV::ConnectInfo 'dbi_to_conninfo';

alarm 60;

# The read of character set and collation after a spawn (karr k100) blocks
# until the handle is connected; this test connects its fake handles itself,
# after the spawn. t/59-session-reset-mock.t and t/07 hold that read.
{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Storage::_mysql_remember_session_names = sub { return };
}

my $EV = 'DBIO::MySQL::EV::Storage';

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

sub vault {
  my (%args) = @_;
  return DBIO::AccessBroker::Vault->new(
    vault     => FakeVaultClient->new,
    dsn       => 'dbi:mysql:database=appdb;host=db.example;port=3307',
    cred_path => 'database/creds/app',
    dbi_attrs => { async => 'ev' },
    %args,
  );
}

my %STATIC = (database => 'appdb', host => 'db.example', port => 3307, user => 'app', password => 's3cret');
my %VAULT  = (database => 'appdb', host => 'db.example', port => 3307,
              user => 'vault-user-1', password => 'vault-pw-1');
my %BOUND  = (host => 'replica.example', port => 3399);

# What an AnswerBroker answers in this file, in each shape, and the named
# parameters it means.
my %ANSWER = (dbname => 'appdb', host => 'db.example', user => 'app', password => 'pw');
my %PARAMS = (database => 'appdb', host => 'db.example', user => 'app', password => 'pw');
my @DBI    = ('dbi:mysql:database=appdb;host=db.example', 'app', 'pw');

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

# The transport, given connect info directly.
sub transport {
  my ($info, $class) = @_;
  my $s = ($class || $EV)->new(undef);
  $s->connect_info($info);
  return $s;
}

# Every place in the storage where a plain value contains $needle, as a path.
# A broker is not looked into: it is the one that may hold the password. Code
# is not looked into either, nor is another storage: the transport's owning
# sync storage (_owner_storage) keeps its own DBI connect info, which is
# core's to say and not what this file claims.
sub holding {
  my ($value, $needle, $path, $seen) = @_;
  $path //= '$storage';
  $seen //= {};
  return () unless defined $value;
  return index($value, $needle) >= 0 ? ($path) : () unless ref $value;
  return () if Scalar::Util::blessed($value) && $value->isa('DBIO::AccessBroker');
  return () if Scalar::Util::blessed($value) && $value->isa('DBIO::Storage') && $path ne '$storage';
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

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
}

my $DIFFERENT = qr/Connection setting 'pool_size' is given both beside the AccessBroker and in the broker's answer, with different values/;

# ---------------------------------------------------------------------------
# 1. The schema path.
# ---------------------------------------------------------------------------

{
  my $schema = BrokerSchema->connect(static(), { async => 'ev', pool_size => 3 });
  my $async  = eval { $schema->storage->async };
  isa_ok $async, $EV, 'connect($broker, { async => ev, pool_size => 3 }): the transport'
    or diag $@;

  SKIP: {
    skip 'the connection was refused', 3 unless $async;
    is scalar eval { $async->pool->max_size }, 3, '... has a pool of three connections' or diag $@;
    is_deeply scalar eval { spawn_params($async) }, \%STATIC,
      '... a pool connection is opened with the broker\'s parameters and nothing else'
      or diag $@;
    is_deeply scalar eval { listen_params($async) }, \%STATIC,
      '... and so is the listen connection'
      or diag $@;
  }
}

{
  # Everything the hash beside a broker may carry at once: the mode and a SQL
  # maker option (the owner's), pool_size and DBD attributes (the backend's).
  my $vault  = vault();
  my $schema = BrokerSchema->connect($vault, {
    async                => 'ev',
    quote_names          => 1,
    pool_size            => 2,
    mysql_enable_utf8mb4 => 1,
    RaiseError           => 1,
  });
  my $async = eval { $schema->storage->async };
  isa_ok $async, $EV, 'connect($vault, { async, quote_names, pool_size, DBD attributes }): the transport'
    or diag $@;

  SKIP: {
    skip 'the connection was refused', 4 unless $async;
    is scalar eval { $async->pool->max_size }, 2, '... has a pool of two connections' or diag $@;
    is_deeply scalar eval { spawn_params($async) }, \%VAULT,
      '... and EV::MariaDB gets the DSN parts, user and password -- no option, no DBD attribute'
      or diag $@;

    # Rotation on the schema path: the options beside the broker do not turn
    # its answer into a snapshot.
    $vault->vault->{secret} = { username => 'vault-user-2', password => 'vault-pw-2' };
    $vault->_expires_at(0);   # the lease is up
    is_deeply scalar eval { spawn_params($async) },
      { %VAULT, user => 'vault-user-2', password => 'vault-pw-2' },
      '... the second pool connection uses the ROTATED credentials'
      or diag $@;
    is_deeply [ holding($async, 'vault-pw-') ], [],
      '... and neither password is anywhere in the transport but in the broker';
  }
}

{
  # A size in the answer and a different one beside the broker, through the
  # schema: the owner has no pool, so only the backend can see the two differ.
  @EV::MariaDB::NEW = ();
  my $schema = BrokerSchema->connect(
    vault(dbi_attrs => { async => 'ev', pool_size => 3 }), { pool_size => 4 },
  );
  my $async = eval { $schema->storage->async };
  my $err   = $@;
  ok !$async, 'connect($vault answering pool_size 3, { pool_size => 4 }): no transport is built';
  like $err, $DIFFERENT, '... the two sizes are refused, naming pool_size';
  is scalar(@EV::MariaDB::NEW), 0, '... and nothing was handed to EV::MariaDB';
}

# ---------------------------------------------------------------------------
# 2. Where the pool size comes from, and what happens when two places differ.
# ---------------------------------------------------------------------------

for my $case (
  # label, the broker, beside it, the pool size, the named parameters
  [ 'nowhere',
    sub { AnswerBroker->new({ %ANSWER }) }, undef, 5, \%PARAMS ],
  [ 'the hash answer',
    sub { AnswerBroker->new({ %ANSWER, pool_size => 3 }) }, undef, 3, \%PARAMS ],
  [ 'the hash of a [ \%conninfo, \%opts ] pair',
    sub { AnswerBroker->new([ { %ANSWER, pool_size => 3 }, {} ]) }, undef, 3, \%PARAMS ],
  [ 'slot [3] of a DBI-form answer',
    sub { AnswerBroker->new([ @DBI, { pool_size => 3 } ]) }, undef, 3, \%PARAMS ],
  [ 'slot [4] of a DBI-form answer',
    sub { AnswerBroker->new([ @DBI, {}, { pool_size => 3 } ]) }, undef, 3, \%PARAMS ],
  [ 'slot [4] of a DBI-form answer with no slot [3]',
    sub { AnswerBroker->new([ @DBI, undef, { pool_size => 3 } ]) }, undef, 3, \%PARAMS ],
  [ 'slots [3] and [4]: [4] wins',
    sub { AnswerBroker->new([ @DBI, { pool_size => 2 }, { pool_size => 3 } ]) }, undef, 3, \%PARAMS ],
  [ 'Vault, among its dbi_attrs',
    sub { vault(dbi_attrs => { async => 'ev', pool_size => 3 }) }, undef, 3, \%VAULT ],
  [ 'HostBound over Vault, among its dbi_attrs',
    sub { vault(dbi_attrs => { async => 'ev', pool_size => 3 })->for_host({ %BOUND }) }, undef, 3,
    { %VAULT, %BOUND } ],

  [ 'beside a hash answer',
    sub { AnswerBroker->new({ %ANSWER }) }, { pool_size => 3 }, 3, \%PARAMS ],
  [ 'beside a [ \%conninfo, \%opts ] pair',
    sub { AnswerBroker->new([ { %ANSWER }, {} ]) }, { pool_size => 3 }, 3, \%PARAMS ],
  [ 'beside a DBI-form answer',
    sub { AnswerBroker->new([ @DBI, {} ]) }, { pool_size => 3 }, 3, \%PARAMS ],
  [ 'beside Static',
    sub { static() }, { pool_size => 3 }, 3, \%STATIC ],
  [ 'beside Vault',
    sub { vault() }, { pool_size => 3 }, 3, \%VAULT ],
  [ 'beside HostBound over Static',
    sub { static()->for_host({ %BOUND }) }, { pool_size => 3 }, 3, { %STATIC, %BOUND } ],
  [ 'beside HostBound over Vault',
    sub { vault()->for_host({ %BOUND }) }, { pool_size => 3 }, 3, { %VAULT, %BOUND } ],

  [ 'the hash answer and beside, alike',
    sub { AnswerBroker->new({ %ANSWER, pool_size => 3 }) }, { pool_size => 3 }, 3, \%PARAMS ],
  [ 'the pair and beside, alike',
    sub { AnswerBroker->new([ { %ANSWER, pool_size => 3 }, {} ]) }, { pool_size => 3 }, 3, \%PARAMS ],
  [ 'slot [3] and beside, alike',
    sub { AnswerBroker->new([ @DBI, { pool_size => 3 } ]) }, { pool_size => 3 }, 3, \%PARAMS ],
  [ 'slot [4] and beside, alike',
    sub { AnswerBroker->new([ @DBI, { pool_size => 2 }, { pool_size => 3 } ]) }, { pool_size => 3 }, 3, \%PARAMS ],
  [ 'Vault and beside, alike',
    sub { vault(dbi_attrs => { async => 'ev', pool_size => 3 }) }, { pool_size => 3 }, 3, \%VAULT ],
) {
  my ($label, $build, $beside, $want, $params) = @$case;
  my $broker = $build->();
  my $s = eval { transport($beside ? [ $broker, $beside ] : [ $broker ]) };
  ok $s, "pool_size from $label: the connect info is taken" or diag $@;
  is scalar eval { $s->pool->max_size }, $want, "... and the pool has $want connections" or diag $@;
  is_deeply scalar eval { spawn_params($s) }, $params,
    '... while pool_size never reaches EV::MariaDB'
    or diag $@;
  is_deeply scalar eval { listen_params($s) }, $params,
    '... on the listen connection either'
    or diag $@;
}

for my $case (
  [ 'the hash answer',               sub { AnswerBroker->new({ %ANSWER, pool_size => 3 }) } ],
  [ 'a [ \%conninfo, \%opts ] pair', sub { AnswerBroker->new([ { %ANSWER, pool_size => 3 }, {} ]) } ],
  [ 'slot [3] of a DBI-form answer', sub { AnswerBroker->new([ @DBI, { pool_size => 3 } ]) } ],
  [ 'slot [4] of a DBI-form answer', sub { AnswerBroker->new([ @DBI, { pool_size => 4 }, { pool_size => 3 } ]) } ],
  [ 'Vault\'s dbi_attrs',            sub { vault(dbi_attrs => { async => 'ev', pool_size => 3 }) } ],
  [ 'HostBound over that Vault',
    sub { vault(dbi_attrs => { async => 'ev', pool_size => 3 })->for_host({ %BOUND }) } ],
) {
  my ($label, $build) = @$case;
  @EV::MariaDB::NEW = ();
  my $s   = $EV->new(undef);
  my $ok  = eval { $s->connect_info([ $build->(), { pool_size => 4 } ]); 1 };
  my $err = $@;
  ok !$ok, "pool_size 3 in $label, 4 beside the broker: the connect info is refused";
  like $err, $DIFFERENT, '... naming pool_size, so neither size wins silently';
  unlike $err, qr/vault-pw-1|\bpw\b/, '... and never a password';
  is scalar(@EV::MariaDB::NEW), 0, '... and nothing was handed to EV::MariaDB';
}

# ---------------------------------------------------------------------------
# 3. DBD attributes beside the broker: dropped, as in DBI-form connect info.
# ---------------------------------------------------------------------------

{
  # DBD::mysql's, DBD::MariaDB's and DBI's own.
  #
  # Until karr k78 this hash also held one key that IS an EV::MariaDB
  # parameter, charset, and the claim was: "given as an attribute it is an
  # attribute, and dropped with the rest". Beside a broker that claim is
  # REPLACED, not kept: the maintainer decided (2026-10-06) that a connection
  # parameter there is refused instead of silently dropped, and
  # t/39-access-broker-parameters-beside-mock.t holds the refusal. What is
  # still claimed here is the rest: a key that is a DBI attribute by its name
  # is taken and never reaches EV::MariaDB.
  my %dbd = (
    mysql_enable_utf8mb4   => 1,
    mysql_auto_reconnect   => 0,
    mariadb_auto_reconnect => 0,
    AutoCommit             => 1,
    RaiseError             => 1,
  );

  # The reference: what this transport makes of the DBI attributes in DBI-form
  # connect info. EV::MariaDB croaks on an argument it does not know. There
  # the DBI attributes are dropped. An EV::MariaDB parameter among them used
  # to be dropped too; since karr k80 it is refused there as well (held by
  # t/49-connect-info-dsn-mock.t): it belongs in the DSN. A mysql_* / mariadb_*
  # attribute in DBI-form connect info is no longer dropped either (karr k80,
  # t/54-utf8-found-rows-attrs-mock.t): translated when EV::MariaDB has a
  # parameter for it, refused otherwise. Beside a broker they are still only
  # kept apart, below.
  my $by_dsn = transport([
    'dbi:mysql:database=appdb;host=db.example;port=3307', 'app', 's3cret', { AutoCommit => 1, RaiseError => 1 },
  ]);
  is_deeply scalar eval { spawn_params($by_dsn) }, \%STATIC,
    'DBI-form connect info with DBI attributes: none of them reaches EV::MariaDB'
    or diag $@;

  for my $case (
    [ 'Static',                sub { static() },                             \%STATIC ],
    [ 'Vault',                 sub { vault() },                              \%VAULT ],
    [ 'HostBound over Static', sub { static()->for_host({ %BOUND }) },       { %STATIC, %BOUND } ],
    [ 'HostBound over Vault',  sub { vault()->for_host({ %BOUND }) },        { %VAULT, %BOUND } ],
    [ 'a pair',                sub { AnswerBroker->new([ { %ANSWER }, {} ]) }, \%PARAMS ],
  ) {
    my ($label, $build, $params) = @$case;
    my $s = eval { transport([ $build->(), { %dbd } ]) };
    ok $s, "the same DBD attributes beside $label: the connect info is taken" or diag $@;
    is_deeply scalar eval { spawn_params($s) }, $params,
      '... and none of them reaches EV::MariaDB on a pool connection'
      or diag $@;
    is_deeply scalar eval { listen_params($s) }, $params,
      '... nor on the listen connection'
      or diag $@;
    is scalar eval { $s->pool->max_size }, 5, '... and the pool keeps its default size' or diag $@;
  }

  # They are kept apart, where core's accessor answers for them, and gone with
  # the next connect info.
  my $s = eval { transport([ static(), { %dbd } ]) } || $EV->new(undef);
  is_deeply scalar eval { $s->_access_broker_call_attributes }, \%dbd,
    'the DBD attributes beside the broker are what _access_broker_call_attributes answers';
  $s->connect_info([ static() ]);
  is_deeply $s->_access_broker_call_attributes, {},
    '... and a later connect info without them leaves none behind';
  $s = eval { transport([ static(), { %dbd } ]) } || $EV->new(undef);
  $s->connect_info([ 'dbi:mysql:database=appdb;host=db.example', 'app', 'pw' ]);
  is_deeply $s->_access_broker_call_attributes, {},
    '... nor does static connect info after them';
}

{
  # The owner's own options, should they come along with a backend setting --
  # core hands the hash on whole: none of them is EV::MariaDB's either. A
  # transport given connect info directly has no owner, so nothing replays the
  # connect action; what is claimed is that it does not get in the way.
  my $s = eval {
    transport([ static(), {
      async           => 'ev',
      on_connect_do   => [ 'SET NAMES utf8mb4' ],
      on_connect_call => 'set_strict_mode',
      quote_names     => 1,
      quote_char      => '`',
      name_sep        => '.',
      cursor_class    => 'DBIO::Storage::DBI::Cursor',
      ignore_version  => 1,
      pool_size       => 2,
    } ]);
  };
  ok $s, 'the owner\'s options beside a broker, with pool_size: the connect info is taken' or diag $@;
  is scalar eval { $s->pool->max_size }, 2, '... the pool has two connections' or diag $@;
  is_deeply scalar eval { spawn_params($s) }, \%STATIC,
    '... and none of them reaches EV::MariaDB'
    or diag $@;
  is_deeply scalar eval { $s->_access_broker_call_attributes }, {},
    '... nor counts as a DBD attribute';
  is_deeply scalar eval { $s->connect_info->[1] }, { pool_size => 2 },
    '... and connect_info keeps what is this backend\'s, as core\'s does';
}

# ---------------------------------------------------------------------------
# 4. The broker stays attached in the two-element form, and nothing is stored.
# ---------------------------------------------------------------------------

{
  my $broker = AnswerBroker->new({ %ANSWER, password => 'first-pw' });
  my $s = eval { transport([ $broker, { pool_size => 2, mysql_enable_utf8mb4 => 1 } ]) };
  ok $s, '[ $broker, { pool_size => 2, a DBD attribute } ]: the connect info is taken' or diag $@;
  $s ||= $EV->new(undef);

  is $s->access_broker, $broker, '... and the broker is attached';
  ok $s->_conninfo_provider, '... with its per-connection provider';
  is $s->{_conninfo}, undef,
    '... no conninfo is stored: neither the broker\'s answer nor the broker object';
  is $s->_conninfo_hash, undef, '... _conninfo_hash, the stored conninfo, has none to return';
  is_deeply [ holding($s, 'first-pw') ], [],
    '... the password of the answer is nowhere in the storage object but in the broker';
  is_deeply scalar eval { [ $s->connect_info->[0], $s->connect_info->[1] ] },
    [ $broker, { pool_size => 2, mysql_enable_utf8mb4 => 1 } ],
    '... connect_info answers the broker and the options beside it';

  is_deeply scalar eval { spawn_params($s) }, { %PARAMS, password => 'first-pw' },
    '... the first pool connection uses its answer'
    or diag $@;

  $broker->{answer} = { %ANSWER, user => 'app-2', password => 'second-pw' };
  is_deeply scalar eval { spawn_params($s) }, { %PARAMS, user => 'app-2', password => 'second-pw' },
    '... and the second one the ROTATED answer: the broker is asked per connection'
    or diag $@;
  is_deeply scalar eval { listen_params($s) }, { %PARAMS, user => 'app-2', password => 'second-pw' },
    '... as is the listen connection opened after the rotation'
    or diag $@;
  is_deeply [ holding($s, 'second-pw') ], [], '... and the rotated password is not stored either';

  # Broker and provider gone: nothing to connect from, as with [ $broker ].
  $s->_clear_access_broker;
  $s->disconnect;
  @EV::MariaDB::NEW = ();
  ok !eval { my $f = $s->pool->acquire; die +($f->failure)[0] if $f->is_failed; 1 },
    'with the broker gone, no pool connection is opened';
  ok !eval { $s->_listen_open; 1 }, '... and no listen connection';
  is scalar(@EV::MariaDB::NEW), 0, '... nothing reaches EV::MariaDB from the options that stood beside it';
}

{
  # The broker form after static connect info leaves nothing of it behind.
  my $s = transport([ 'dbi:mysql:database=staticdb;host=static.example', 'static-user', 'static-pw' ]);
  my $ok = eval { $s->connect_info([ static(), { pool_size => 2 } ]); 1 };
  ok $ok, 'static connect info, then [ $broker, \%options ]: taken' or diag $@;
  is $s->{_conninfo}, undef, '... the static conninfo is not kept';
  is_deeply [ holding($s, 'static-pw') ], [], '... its password is gone from the storage object';
  is_deeply scalar eval { spawn_params($s) }, \%STATIC,
    '... and a pool connection is opened from the broker alone'
    or diag $@;
}

# ---------------------------------------------------------------------------
# 5. The declaration, bound to the behaviour.
# ---------------------------------------------------------------------------

ok scalar(grep { $_ eq 'broker_connect_options' } $EV->transport_capabilities),
  "the transport declares 'broker_connect_options'";
ok $EV->_takes_broker_connect_options,
  '... which is what core asks before handing it [ $broker, \%options ]';

{
  # The same transport without the declaration. Its connect_info must refuse
  # the settings through core's gate: the override takes them because the
  # transport promised to apply them, not because the form happens to parse.
  package UndeclaredTransport;
  use base 'DBIO::MySQL::EV::Storage';
  sub transport_capabilities {
    my $class = shift;
    return grep { $_ ne 'broker_connect_options' } $class->SUPER::transport_capabilities;
  }
}

for my $case (
  [ 'pool_size',       { pool_size => 3 },            qr/: pool_size\b/ ],
  [ 'a DBD attribute', { mysql_enable_utf8mb4 => 1 }, qr/: mysql_enable_utf8mb4\b/ ],
) {
  my ($label, $beside, $names_re) = @$case;
  @EV::MariaDB::NEW = ();
  my $s   = UndeclaredTransport->new(undef);
  my $ok  = eval { $s->connect_info([ static(), $beside ]); 1 };
  my $err = $@;
  ok !$ok, "without the declaration, $label beside a broker is refused";
  like $err, qr/does not take connection settings beside an AccessBroker \(it does not declare 'broker_connect_options'/,
    '... by core\'s gate, saying what is missing';
  like $err, $names_re, '... and naming the setting';
  ok !$s->access_broker, '... no broker is attached';
  is $s->{_conninfo}, undef, '... and nothing is stored as conninfo';
  ok !eval { my $f = $s->pool->acquire; die +($f->failure)[0] if $f->is_failed; 1 },
    '... so no pool connection is opened';
  is scalar(@EV::MariaDB::NEW), 0, '... and nothing was handed to EV::MariaDB';
}

{
  # Only the owner's own options beside the broker: nothing for a backend to
  # apply, so nothing to refuse -- it is the bare broker form.
  my $broker = static();
  my $s = eval { transport([ $broker, { async => 'ev', quote_names => 1 } ], 'UndeclaredTransport') };
  ok $s, 'without the declaration, a hash holding only the owner\'s options is taken' or diag $@;
  is scalar eval { $s->access_broker }, $broker, '... as the broker form';
  is_deeply scalar eval { spawn_params($s) }, \%STATIC,
    '... and none of those options reaches EV::MariaDB'
    or diag $@;
}

# ---------------------------------------------------------------------------
# 6. DBI-form connect info: the fifth element.
# ---------------------------------------------------------------------------

{
  my $dsn = 'dbi:mysql:database=appdb;host=db.example;port=3307';

  for my $case (
    [ 'slot [3] alone',               [ { pool_size => 3 } ],                                    3 ],
    [ 'slot [4] alone',               [ {}, { pool_size => 3 } ],                                3 ],
    [ 'slot [4] with no slot [3]',    [ undef, { pool_size => 3 } ],                             3 ],
    [ 'both slots: [4] wins',         [ { pool_size => 2 }, { pool_size => 3 } ],                3 ],
    [ 'slot [3], [4] without a size', [ { pool_size => 3 }, { AutoCommit => 1 } ],     3 ],
    [ 'no size in either slot',       [ { AutoCommit => 1 }, { RaiseError => 1 } ],    undef ],
  ) {
    my ($label, $attr_slots, $want) = @$case;
    my $info = dbi_to_conninfo([ $dsn, 'app', 's3cret', @$attr_slots ]);
    is $info->[0]{pool_size}, $want,
      "dbi_to_conninfo, $label: pool_size is " . ($want // 'not set');
    my %named = %{ $info->[0] };
    delete $named{pool_size};
    is_deeply \%named, \%STATIC,
      '... and the named parameters are the DSN parts, user and password only';
  }

  # Reading two slots must not write them: the arrayref is the caller's -- the
  # user's connect info, or a broker's answer, whose shape an error message
  # reports (t/29-access-broker-conninfo-mock.t).
  for my $given (
    [ $dsn ],
    [ $dsn, 'app', 's3cret' ],
    [ $dsn, 'app', 's3cret', { pool_size => 3 } ],
  ) {
    my $n = @$given;
    dbi_to_conninfo($given);
    is scalar(@$given), $n, "dbi_to_conninfo leaves a $n-element arrayref at $n elements";
  }
  is_deeply
    do { my @given = ($dsn, 'app', 's3cret', { pool_size => 3 }); dbi_to_conninfo(\@given); \@given },
    [ $dsn, 'app', 's3cret', { pool_size => 3 } ],
    '... and its elements as they were given';

  # The transport, given the five-element form directly.
  my $s = eval {
    transport([ $dsn, 'app', 's3cret', { AutoCommit => 1 }, { pool_size => 3, RaiseError => 1 } ]);
  };
  ok $s, 'connect_info([ $dsn, $user, $pass, \%attrs, \%extra_attributes ]): taken' or diag $@;
  is scalar eval { $s->pool->max_size }, 3, '... the pool is sized by the fifth element' or diag $@;
  is_deeply scalar eval { spawn_params($s) }, \%STATIC,
    '... and no attribute of either hash reaches EV::MariaDB'
    or diag $@;

  # Through the owning sync storage, the way a user gives the fifth element.
  my $schema = BrokerSchema->connect($dsn, 'app', 's3cret', { async => 'ev' }, { pool_size => 3 });
  my $async  = eval { $schema->storage->async };
  isa_ok $async, $EV, 'connect($dsn, $user, $pass, { async => ev }, { pool_size => 3 }): the transport'
    or diag $@;
  is scalar eval { $async->pool->max_size }, 3,
    '... has a pool of three connections: the fifth element reaches the pool'
    or diag $@;
  is_deeply scalar eval { spawn_params($async) }, \%STATIC,
    '... and pool_size does not reach EV::MariaDB'
    or diag $@;
}

done_testing;
