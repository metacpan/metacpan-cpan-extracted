use strict;
use warnings;
use Test::More;

# OFFLINE test: a connection parameter given beside an AccessBroker is refused
# by the ev transport, not dropped (karr k78; the same line as core k298 /
# k307 for the owning sync storage).
#
# WHY: beside a broker a caller may give connect options --
#
#   MyApp::Schema->connect($broker, { async => 'ev', pool_size => 3, ... })
#
# and what a backend applies of them core hands this transport as
# [ $broker, \%options ]. The transport applied pool_size and dropped
# everything else: DBD attributes, which belong to the owner's DBI connection
# and mean nothing to EV::MariaDB -- and, with them, whatever else stood
# there. ssl_verify_server_cert => 1 stood there, or charset, or a host. Every
# pooled connection and the listen connection were then opened from the
# broker's answer alone: without the certificate check that was asked for,
# without the timeout, in the server's default character set, to the broker's
# host instead of the one named -- and nothing said so. A parameter that
# decides how a connection is secured, or where it goes, must reach the
# connection or stop it.
#
# What this file claims:
#   1. a parameter beside the broker that is set to a value and is, by its
#      name, no DBI attribute is refused when the transport is given the
#      connect info: the message says that the transport does not apply it,
#      names the parameters (sorted) and where they belong, and holds no value
#      -- not theirs, not the broker's password. Nothing reaches EV::MariaDB;
#   2. the measure is core's (k298): a name starting with an uppercase letter,
#      private_, dbi_, dbd_, DBD::mysql's mysql_ or DBD::MariaDB's mariadb_ is
#      a DBI attribute and is still taken and dropped (karr k59); a key set to
#      undef or '' names no parameter; what the owner applies itself (async,
#      storage and SQL maker options) and pool_size never count. No list of
#      EV::MariaDB parameters is kept: a name nobody has heard of is refused
#      like charset;
#   3. after the refusal nothing is opened through this storage without the
#      parameter: not a pool connection, not the listen connection, not from
#      the conninfo of a static connect_info before it, not when asked again,
#      and not once the broker is detached. Each attempt says again which
#      parameter is in the way. Connect info without it is taken afterwards,
#      and nothing of the refused one is left;
#   4. through a schema the refusal comes when the transport is built, at the
#      first ->async or *_async call, and again at every later one -- core
#      builds the backend lazily, and no backend is kept from a refused build.
#      Schema->connect itself goes through. The parts of the connection itself
#      (host, user, ...) never get that far: core's sync storage refuses them
#      beside a broker at connect.
#
# This replaces what t/30-access-broker-connect-options-mock.t held until k78
# for one key of its section 3: charset beside a broker, "an attribute like
# any other, dropped with the rest". That claim described the code, and the
# maintainer decided against the behaviour (2026-10-06).
#
# WHAT RUNS FOR REAL: the built-in brokers, core's broker attach and option
# split, core's sync storage and its _async_storage, this dist's Storage,
# ConnectInfo and Pool (and EV, for the fork watchers both arm).
# THE SUBSTITUTIONS: EV::MariaDB records what it is constructed with, refuses
# what the real constructor refuses and, like it, starts a connect only when
# given a host or a user (the test plays the server's connect) -- the fake of
# t/29-access-broker-conninfo-mock.t; the Vault client is a stub.

BEGIN {
  package EV::MariaDB;
  use Carp ();
  use Scalar::Util ();

  our @NEW;   # every handle made: [ \%named (without the callbacks), the handle (weak) ]

  # What EV::MariaDB 0.08's constructor takes; it croaks on anything else.
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
use DBIO::MySQL::EV::Storage;

alarm 60;

my $EV = 'DBIO::MySQL::EV::Storage';

{
  package FakeVaultClient;
  sub new { bless { secret => { username => 'vault-user-1', password => 'k78-vault-pw' } }, shift }
  sub read_secret { return { %{ $_[0]{secret} } } }
}

sub static {
  return DBIO::AccessBroker::Static->new(
    host     => 'db.example',
    port     => 3307,
    dbname   => 'appdb',
    username => 'app',
    password => 'k78-static-pw',
  );
}

sub vault {
  return DBIO::AccessBroker::Vault->new(
    vault     => FakeVaultClient->new,
    dsn       => 'dbi:mysql:database=appdb;host=db.example;port=3307',
    cred_path => 'database/creds/app',
    dbi_attrs => { async => 'ev' },
  );
}

my %STATIC = (database => 'appdb', host => 'db.example', port => 3307, user => 'app', password => 'k78-static-pw');

# Every value given beside a broker in this file carries this, and every
# password its own marker, so one pattern finds any of them in a message.
my $VALUE = 'k78-value';
my $LEAK  = qr/\Q$VALUE\E|k78-static-pw|k78-vault-pw/;

my $REFUSED = qr/^MySQL ev does not apply connection parameter\(s\) given beside an AccessBroker \(/;

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

# Every place in the storage where a plain value contains $needle, as a path.
# A broker is not looked into, and neither is code.
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

# connect_info on a new transport: the storage, and the error if it threw.
sub given {
  my ($info, $s) = @_;
  $s //= $EV->new(undef);
  @EV::MariaDB::NEW = ();
  my $ok = eval { $s->connect_info($info); 1 };
  return ($s, $ok ? undef : "$@");
}

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
}

# ---------------------------------------------------------------------------
# 1. The refusal and what it says.
# ---------------------------------------------------------------------------

for my $case (
  [ 'a Static broker (a hash of parameters)', \&static ],
  [ 'a Vault broker (the DBI form)',          \&vault  ],
) {
  my ($label, $broker) = @$case;

  my ($s, $err) = given([ $broker->(), { ssl_verify_server_cert => "$VALUE-1", charset => "$VALUE-utf8mb4" } ]);
  ok defined $err, "$label with ssl_verify_server_cert and charset beside it: the connect info is refused";
  like $err, $REFUSED, '... saying that the transport does not apply parameters given beside a broker';
  like $err, qr/\(charset, ssl_verify_server_cert\)/, '... naming them, sorted';
  unlike $err, $LEAK, '... and no value: not theirs, not the password of the broker\'s answer';
  like $err, qr/would be opened without them\. Give them in the broker's answer/,
    '... saying where they belong: in the broker\'s answer';
  like $err, qr/\[ 'dbi:mysql:\.\.\.;<parameter>=\.\.\.' or 'dbi:MariaDB:\.\.\.;<parameter>=\.\.\.', \$user, \$password \]/,
    '... as the DBI form with the parameter in the DSN';
  like $err, qr/connect_info_for_storage/,
    '... or as a hash answered to this transport';
  is scalar(@EV::MariaDB::NEW), 0, '... and nothing was handed to EV::MariaDB';
}

{
  my (undef, $err) = given([ static(), { charset => $VALUE } ]);
  like $err // '', qr/would be opened without it\. Give it in the broker's answer/,
    'one parameter: the message speaks of it, not of them';
}

# ---------------------------------------------------------------------------
# 2. What is a parameter, and what is not.
# ---------------------------------------------------------------------------

for my $case (
  [ 'charset',                           { charset => $VALUE },                                 'charset' ],
  [ 'connect_timeout',                   { connect_timeout => $VALUE },                         'connect_timeout' ],
  [ 'ssl_ca',                            { ssl_ca => $VALUE },                                  'ssl_ca' ],
  [ 'utf8',                              { utf8 => 1 },                                         'utf8' ],
  [ 'a name EV::MariaDB does not know',  { no_such_parameter => $VALUE },                       'no_such_parameter' ],
  [ 'the prefix of another DBD',         { pg_enable_utf8 => $VALUE },                          'pg_enable_utf8' ],
  [ 'the connection itself',
    { host => $VALUE, port => $VALUE, user => $VALUE, password => $VALUE, database => $VALUE, unix_socket => $VALUE },
    'database, host, password, port, unix_socket, user' ],
  [ 'a reference for a value',           { charset => [ $VALUE ] },                             'charset' ],
  [ 'a parameter among DBD attributes',
    { mysql_enable_utf8mb4 => 1, mariadb_auto_reconnect => 0, charset => $VALUE, RaiseError => 1 }, 'charset' ],
  [ 'a parameter beside pool_size',      { pool_size => 3, charset => $VALUE },                 'charset' ],
  [ 'a parameter beside the owner\'s options',
    { async => 'ev', quote_names => 1, on_connect_do => [ 'SELECT 1' ], charset => $VALUE },    'charset' ],
) {
  my ($label, $beside, $names) = @$case;
  my ($s, $err) = given([ static(), $beside ]);
  ok defined $err, "$label beside the broker: refused";
  like $err // '', qr/given beside an AccessBroker \(\Q$names\E\)/, "... naming $names and nothing else";
  unlike $err // '', $LEAK, '... and no value';
  is scalar(@EV::MariaDB::NEW), 0, '... nothing was handed to EV::MariaDB';
}

for my $case (
  [ 'DBD::mysql attributes',            { mysql_enable_utf8mb4 => 1, mysql_auto_reconnect => 0 }, 5 ],
  [ 'DBD::MariaDB attributes',          { mariadb_auto_reconnect => 0, mariadb_connect_timeout => 7 }, 5 ],
  [ 'DBI attributes',                   { AutoCommit => 1, RaiseError => 1, PrintError => 0 }, 5 ],
  [ 'private_, dbi_ and dbd_ names',    { private_app => $VALUE, dbi_connect_method => 'connect', dbd_verbose => 1 }, 5 ],
  [ 'a parameter name set to undef',    { charset => undef },                             5 ],
  [ 'a parameter name set to the empty string', { connect_timeout => '' },                5 ],
  [ 'pool_size',                        { pool_size => 3 },                               3 ],
  [ 'the owner\'s options',             { async => 'ev', quote_names => 1, on_connect_do => [ 'SELECT 1' ] }, 5 ],
  [ 'all of those at once',
    { mysql_enable_utf8mb4 => 1, mariadb_auto_reconnect => 0, RaiseError => 1, private_app => $VALUE,
      charset => undef, pool_size => 3, async => 'ev', quote_names => 1 },                3 ],
) {
  my ($label, $beside, $pool_size) = @$case;
  my ($s, $err) = given([ static(), $beside ]);
  ok !defined $err, "$label beside the broker: the connect info is taken" or diag $err;
  is_deeply scalar eval { spawn_params($s) }, \%STATIC,
    '... a pool connection is opened from the broker\'s answer, and none of it reaches EV::MariaDB'
    or diag $@;
  is_deeply scalar eval { listen_params($s) }, \%STATIC,
    '... and so is the listen connection'
    or diag $@;
  is scalar eval { $s->pool->max_size }, $pool_size, "... the pool may hold $pool_size connections";
}

# ---------------------------------------------------------------------------
# 3. After the refusal.
# ---------------------------------------------------------------------------

# Every value of the static connect info of this section carries $OLD.
my $OLD = 'k78-before';
my @static_info   = ( "dbi:mysql:database=$OLD-db;host=$OLD.example", "$OLD-user", "$OLD-pw" );
my %static_params = ( database => "$OLD-db", host => "$OLD.example", user => "$OLD-user", password => "$OLD-pw" );

for my $before (
  [ 'a storage never given connect info', sub { } ],
  [ 'a storage with static connect info', sub { $_[0]->connect_info([ @static_info ]) } ],
  [ 'a storage with static connect info and a pooled connection',
    sub {
      $_[0]->connect_info([ @static_info ]);
      is_deeply scalar eval { spawn_params($_[0]) }, \%static_params,
        '(the static connection has a pool connection)' or diag $@;
    } ],
  [ 'a storage with another broker attached',
    sub {
      $_[0]->connect_info([ DBIO::AccessBroker::Static->new(
        dbname => "$OLD-db", host => "$OLD.example", username => "$OLD-user", password => "$OLD-pw",
      ) ]);
    } ],
) {
  my ($label, $prepare) = @$before;

  for my $detach (undef, qw( _clear_access_broker clear_access_broker )) {
    my $s = $EV->new(undef);
    $prepare->($s);

    my $broker = static();
    my (undef, $err) = given([ $broker, { charset => $VALUE, pool_size => 2 } ], $s);
    like $err // '', qr/given beside an AccessBroker \(charset\)/, "$label: charset beside a broker is refused";
    unlike $err // '', qr/\Q$OLD\E/, '... naming nothing of what the storage was connected from';

    # What stays configured: the broker that was given, and nothing to
    # connect from but it.
    is $s->access_broker, $broker, '... the broker that was given is attached';
    is $s->{_conninfo}, undef, '... no conninfo is stored';
    is_deeply [ holding($s, $OLD) ], [], '... and nothing of the connect info before is left in the storage object';

    if (!$detach) {
      for my $ask ('asked for a connection', 'asked again') {
        my $got = connection_attempts($s);
        like $got->{pool}, qr/given beside an AccessBroker \(charset\)/,
          "$label, $ask: a pool connection is refused, naming the parameter";
        like $got->{listen}, qr/given beside an AccessBroker \(charset\)/,
          '... and so is the listen connection';
        is_deeply $got->{handles}, [], '... nothing reaches EV::MariaDB';
        unlike "$got->{pool} $got->{listen}", qr/$LEAK|\Q$OLD\E/, '... and no value is in either message';
      }

      # Given the same again, it is refused again.
      (undef, $err) = given([ $broker, { charset => $VALUE, pool_size => 2 } ], $s);
      like $err // '', qr/given beside an AccessBroker \(charset\)/, "$label: the same connect info again is refused again";
      is scalar(@EV::MariaDB::NEW), 0, '... nothing reaches EV::MariaDB';

      # Without the parameter the broker is taken, and nothing is left of the
      # refusal.
      (undef, $err) = given([ $broker, { pool_size => 2, mysql_enable_utf8mb4 => 1 } ], $s);
      ok !defined $err, "$label: the same broker without the parameter is taken" or diag $err;
      is_deeply $s->_access_broker_call_attributes, { mysql_enable_utf8mb4 => 1 },
        '... the refused parameter is not among what stands beside the broker now';
      is_deeply scalar eval { spawn_params($s) }, \%STATIC,
        '... a pool connection is opened from the broker\'s answer' or diag $@;
      is_deeply scalar eval { listen_params($s) }, \%STATIC,
        '... and so is the listen connection' or diag $@;
      is scalar eval { $s->pool->max_size }, 2, '... the pool has the size given with it';
    }
    else {
      $s->$detach;
      ok !$s->access_broker, "$label, then $detach: the broker is detached";
      my $got = connection_attempts($s);
      isnt $got->{pool},   'no error', '... a pool connection fails';
      isnt $got->{listen}, 'no error', '... and so does a listen open';
      is_deeply $got->{handles}, [],
        '... nothing reaches EV::MariaDB: not from the broker, not from the connect info before';
      unlike "$got->{pool} $got->{listen}", qr/$LEAK|\Q$OLD\E/, '... and no value is in either message';

      # Static connect info is taken again afterwards.
      (undef, $err) = given([ @static_info ], $s);
      ok !defined $err, "$label, then $detach: static connect info is taken again" or diag $err;
      is_deeply scalar eval { spawn_params($s) }, \%static_params,
        '... and a pool connection is opened from it' or diag $@;
    }
  }
}

# ---------------------------------------------------------------------------
# 4. Through a schema: refused when the transport is built.
# ---------------------------------------------------------------------------

for my $case (
  [ 'a Static broker', \&static ],
  [ 'a Vault broker',  \&vault  ],
) {
  my ($label, $broker) = @$case;
  @EV::MariaDB::NEW = ();

  my $schema = eval {
    BrokerSchema->connect($broker->(), { async => 'ev', pool_size => 3, mysql_enable_utf8mb4 => 1, charset => $VALUE });
  };
  ok $schema, "$label, connect(\$broker, { async => 'ev', ..., charset => ... }): the schema is connected"
    or diag $@;

  SKIP: {
    skip 'the connect itself was refused', 10 unless $schema;
    my $storage = $schema->storage;

    for my $ask ('the first ->async', '->async again') {
      my $async = eval { $storage->async };
      my $err   = "$@";
      ok !$async, "$label, $ask: no transport is handed out";
      like $err, qr/MySQL ev does not apply connection parameter\(s\) given beside an AccessBroker \(charset\)/,
        '... the refusal names charset -- not pool_size or the DBD attribute beside it';
      unlike $err, $LEAK, '... and no value';
    }

    my $f   = eval { $storage->select_async('appdb.t', [ 'id' ]) };
    my $err = $f && $f->is_failed ? ($f->failure)[0] : "$@";
    ok !$f || $f->is_failed, "$label: a statement on the async API is not run";
    like $err, qr/given beside an AccessBroker \(charset\)/, '... for the same reason';
    unlike $err, $LEAK, '... and no value';
    is scalar(@EV::MariaDB::NEW), 0, "$label: nothing was handed to EV::MariaDB at any point";
  }
}

# The parts of the connection itself do not get as far as the transport
# through a schema: core's sync storage refuses them beside a broker when it
# is configured. Held here because the transport's own refusal of them
# (section 2) is then what stands between a caller who addresses it directly
# and a connection to the broker's host where another one was named.
for my $name (qw( host port user password dbname dsn )) {
  @EV::MariaDB::NEW = ();
  my $schema = eval { BrokerSchema->connect(static(), { async => 'ev', $name => $VALUE }) };
  my $err    = "$@";
  ok !$schema, "connect(\$broker, { async => 'ev', $name => ... }): refused at connect";
  like $err, qr/the hash beside the broker takes connect options, not the connection itself: \Q$name\E\b/,
    '... by core, naming it';
  unlike $err, $LEAK, '... and no value';
  is scalar(@EV::MariaDB::NEW), 0, '... nothing was handed to EV::MariaDB';
}

done_testing;
