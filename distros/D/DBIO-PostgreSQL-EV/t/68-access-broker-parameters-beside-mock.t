use strict;
use warnings;
use Test::More;

# OFFLINE test: a connection parameter given beside an AccessBroker is refused
# by the ev transport, not dropped (karr k76; the same line as core k298 and
# dbio-postgresql k97).
#
# WHY: beside a broker a caller may give connect options --
#
#   MyApp::Schema->connect($broker, { async => 'ev', pool_size => 3, ... })
#
# and what a backend applies of them core hands this transport as
# [ $broker, \%options ]. The transport applied pool_size and dropped
# everything else: DBD attributes, which belong to the owner's DBI connection
# and mean nothing to libpq -- and, with them, whatever else stood there.
# sslmode => 'verify-full' stood there. Every pooled connection and the listen
# connection were then opened from the broker's answer alone: without TLS
# where TLS was asked for, without the timeout, to the server's default
# instead of the service named -- and nothing said so. A parameter that
# decides how a connection is secured must reach the connection or stop it.
#
# What this file claims:
#   1. a parameter beside the broker that is set to a value and is, by its
#      name, no DBI attribute is refused when the transport is given the
#      connect info: the message says that the transport does not apply it,
#      names the parameters (sorted) and where they belong, and holds no value
#      -- not theirs, not the broker's password. Nothing reaches EV::Pg;
#   2. the measure is core's (k298): a name starting with an uppercase letter,
#      private_, dbi_, dbd_ or DBD::Pg's pg_ is a DBI attribute and is still
#      taken and dropped (karr k60); a key set to undef or '' names no
#      parameter; what the owner applies itself (async, storage and SQL maker
#      options) and pool_size never count. No list of libpq parameters is kept:
#      a name nobody has heard of is refused like sslmode;
#   3. after the refusal nothing is opened through this storage without the
#      parameter: not a pool connection, not the listen connection, not from
#      the conninfo of a static connect_info before it, not when asked again,
#      and not once the broker is detached. Each attempt says again which
#      parameter is in the way. Connect info without it is taken afterwards,
#      and nothing of the refused one is left;
#   4. through a schema the refusal comes when the transport is built, at the
#      first ->async or *_async call, and again at every later one -- core
#      builds the backend lazily, and no backend is kept from a refused build;
#   5. the other half of that schema refuses as well (core k307, karr k83):
#      the owning sync storage does not open its dbh beside a broker with such
#      a parameter. Schema->connect goes through; each use of the dbh is
#      refused by the sync storage -- not by a server that is not there --
#      naming the broker class and the parameters, sorted, and not the
#      pool_size or the DBD attribute beside them, and no value; DBI is not
#      asked for a connection, at any of them. So neither half of the schema
#      opens a connection without the parameter. The control: the same schema
#      without the parameter asks DBI for the owner's connection, with the
#      DBD attribute. This is core's behaviour, held here because it is the
#      owner's half of what this distribution promises about a parameter
#      beside a broker; it turns red if core lets the refusal go. That a
#      connection AFTER one that was opened is judged anew is not asked here:
#      the refusal sits in the one place the sync storage opens a connection
#      (DBIO::Storage::DBI::_connect), and core holds "the first one and every
#      later one" there (its t/access_broker/32-dbi-broker-unapplied-options-
#      beside.t, sections 1 and 2). With a parameter beside the broker the dbh
#      of this schema is never opened, so there is no reconnect to sample.
#      (What a real server shows of it -- which backends exist, under which
#      name -- is t/69-access-broker-parameters-beside-live.t.)
#
# WHAT RUNS FOR REAL: the built-in brokers, core's broker attach and option
# split, core's sync storage and its _async_storage, the PostgreSQL driver
# storage, this dist's Storage, ConnectInfo and Pool.
# THE SUBSTITUTIONS: EV::Pg records what it is constructed with (the test plays
# the server's connect); the Vault client is a stub; in section 5 DBI->connect
# records what it is called with and reports that there is no server.

BEGIN {
  package EV::Pg;
  use Scalar::Util ();

  our @NEW;   # every EV::Pg->new: [ conninfo, the handle (weak) ]

  sub new {
    my ($class, %args) = @_;
    my $self = bless { args => { %args }, connected => 0 }, $class;
    # connect_timeout=10 is the transport's own default (karr k101, t/111): not part of what these tests compare
    push @NEW, [ $args{conninfo} =~ s/\s*connect_timeout=10\z//r, $self ];
    Scalar::Util::weaken($NEW[-1][1]);
    return $self;
  }

  for my $h (qw( on_connect on_error on_notify )) {
    no strict 'refs';
    *{"EV::Pg::$h"} = sub { my $s = shift; $s->{args}{$h} = $_[0] if @_; $s->{args}{$h} };
  }

  sub is_connected { $_[0]{connected} ? 1 : 0 }
  sub socket       { -1 }
  sub finish       { $_[0]{connected} = 0; return }

  # The server's side: the connect completes.
  sub t_connect {
    my ($s) = @_;
    $s->{connected} = 1;
    $s->{args}{on_connect}->() if $s->{args}{on_connect};
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBI;
use Scalar::Util ();
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::PostgreSQL::EV::Storage;

alarm 60;

my $EV = 'DBIO::PostgreSQL::EV::Storage';

# A libpq conninfo string back into its parameters: key=value or
# key='quoted value' with \' and \\ escaped -- the syntax libpq reads. Dies on
# anything else.
sub parse_conninfo {
  my ($str) = @_;
  die "no conninfo string\n" unless defined $str && !ref $str;
  my %h;
  pos($str) = 0;
  while ($str =~ /\G\s*([A-Za-z_]+)=(?:'((?:[^'\\]|\\.)*)'|([^\s']*))/gc) {
    my ($key, $quoted, $bare) = ($1, $2, $3);
    die "conninfo names '$key' twice\n" if exists $h{$key};
    $h{$key} = defined $quoted ? $quoted =~ s/\\(.)/$1/gr : $bare;
  }
  die "not a libpq conninfo string\n" unless $str =~ /\G\s*\z/gc;
  return \%h;
}

{
  package FakeVaultClient;
  sub new { bless { secret => { username => 'vault-user-1', password => 'k76-vault-pw' } }, shift }
  sub read_secret { return { %{ $_[0]{secret} } } }
}

sub static {
  return DBIO::AccessBroker::Static->new(
    host     => 'db.example',
    port     => 5433,
    dbname   => 'appdb',
    username => 'app',
    password => 'k76-static-pw',
  );
}

sub vault {
  return DBIO::AccessBroker::Vault->new(
    vault     => FakeVaultClient->new,
    dsn       => 'dbi:Pg:dbname=appdb;host=db.example;port=5433',
    cred_path => 'database/creds/app',
    dbi_attrs => { async => 'ev' },
  );
}

my %STATIC = (dbname => 'appdb', host => 'db.example', port => 5433, user => 'app', password => 'k76-static-pw');

# Every value given beside a broker in this file carries this, and every
# password its own marker, so one pattern finds any of them in a message.
my $VALUE = 'k76-value';
my $LEAK  = qr/\Q$VALUE\E|k76-static-pw|k76-vault-pw/;

# A refusal of the transport's own is a DBIO::Exception since karr k88
# (maintainer's decision 2026-10-16): core's origin -- the transport's method
# that refused -- stands in front of the words, the caller's place behind
# them. Until then the words began the message.
my $REFUSED = qr/^DBIO::PostgreSQL::EV::Storage::\w+\(\): PostgreSQL ev does not apply connection parameter\(s\) given beside an AccessBroker \(/;

# One new pool connection: what EV::Pg was constructed with. The connection is
# acquired and kept, so the next spawn is a new one.
sub spawn_conninfo {
  my ($s) = @_;
  @EV::Pg::NEW = ();
  my $f = $s->pool->acquire;
  die "acquire failed: " . ($f->failure)[0] if $f->is_failed;
  die scalar(@EV::Pg::NEW) . " EV::Pg handles made for one spawn\n" unless @EV::Pg::NEW == 1;
  my ($conninfo, $pg) = @{ $EV::Pg::NEW[0] };
  $pg->t_connect;
  die "the spawned connection was not handed out\n" unless $f->is_done && $f->get == $pg;
  return $conninfo;
}

# One open of the listen connection: what EV::Pg was constructed with.
sub listen_conninfo {
  my ($s) = @_;
  @EV::Pg::NEW = ();
  my $f = $s->_listen_open;
  die scalar(@EV::Pg::NEW) . " EV::Pg handles made for one listen open\n" unless @EV::Pg::NEW == 1;
  my ($conninfo, $pg) = @{ $EV::Pg::NEW[0] };
  $pg->t_connect;
  $s->_listen_close($f->get);
  return $conninfo;
}

# What a storage does when asked for a connection: how a pool spawn and a
# listen open end (the error without its location), and what reached EV::Pg.
sub connection_attempts {
  my ($s) = @_;
  @EV::Pg::NEW = ();
  my %got;
  for my $attempt (
    [ pool   => sub { my $f = $s->pool->acquire; die +($f->failure)[0] if $f->is_failed } ],
    [ listen => sub { $s->_listen_open } ],
  ) {
    my ($name, $code) = @$attempt;
    $got{$name} = eval { $code->(); 1 } ? 'no error' : $@ =~ s/ at \S+ line \d+\.?\n?\z//r;
  }
  $got{handles} = [ map { $_->[0] } @EV::Pg::NEW ];
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
  @EV::Pg::NEW = ();
  my $ok = eval { $s->connect_info($info); 1 };
  return ($s, $ok ? undef : "$@");
}

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

# ---------------------------------------------------------------------------
# 1. The refusal and what it says.
# ---------------------------------------------------------------------------

for my $case (
  [ 'a Static broker (a hash of parameters)', \&static ],
  [ 'a Vault broker (the DBI form)',          \&vault  ],
) {
  my ($label, $broker) = @$case;

  my ($s, $err) = given([ $broker->(), { sslmode => "$VALUE-tls", connect_timeout => "$VALUE-7" } ]);
  ok defined $err, "$label with sslmode and connect_timeout beside it: the connect info is refused";
  like $err, $REFUSED, '... saying that the transport does not apply parameters given beside a broker';
  like $err, qr/\(connect_timeout, sslmode\)/, '... naming them, sorted';
  unlike $err, $LEAK, '... and no value: not theirs, not the password of the broker\'s answer';
  like $err, qr/in the broker's answer/, '... saying where they belong: in the broker\'s answer';
  like $err, qr/\[ 'dbi:Pg:\.\.\.;<parameter>=\.\.\.', \$user, \$password \]/,
    '... as the DBI form with the parameter in the DSN';
  like $err, qr/connect_info_for_storage/,
    '... or as a hash answered to this transport';
  is scalar(@EV::Pg::NEW), 0, '... and nothing was handed to EV::Pg';
}

# ---------------------------------------------------------------------------
# 2. What is a parameter, and what is not.
# ---------------------------------------------------------------------------

for my $case (
  [ 'sslmode',                           { sslmode => $VALUE },                                 'sslmode' ],
  [ 'connect_timeout',                   { connect_timeout => $VALUE },                         'connect_timeout' ],
  [ 'application_name',                  { application_name => $VALUE },                        'application_name' ],
  [ 'a name no libpq knows',             { no_such_parameter => $VALUE },                       'no_such_parameter' ],
  [ 'the prefix of another DBD',         { mysql_enable_utf8 => $VALUE },                       'mysql_enable_utf8' ],
  [ 'the connection itself',             { host => $VALUE, port => $VALUE, user => $VALUE },    'host, port, user' ],
  [ 'a reference for a value',           { sslmode => [ $VALUE ] },                             'sslmode' ],
  [ 'a parameter among DBD attributes',  { pg_enable_utf8 => 1, sslmode => $VALUE, RaiseError => 1 }, 'sslmode' ],
  [ 'a parameter beside pool_size',      { pool_size => 3, sslmode => $VALUE },                 'sslmode' ],
  [ 'a parameter beside the owner\'s options',
    { async => 'ev', quote_names => 1, on_connect_do => [ 'SELECT 1' ], sslmode => $VALUE },    'sslmode' ],
) {
  my ($label, $beside, $names) = @$case;
  my ($s, $err) = given([ static(), $beside ]);
  ok defined $err, "$label beside the broker: refused";
  like $err // '', qr/given beside an AccessBroker \(\Q$names\E\)/, "... naming $names and nothing else";
  unlike $err // '', $LEAK, '... and no value';
  is scalar(@EV::Pg::NEW), 0, '... nothing was handed to EV::Pg';
}

for my $case (
  [ 'DBD::Pg attributes',               { pg_enable_utf8 => 1, pg_server_prepare => 0 },  5 ],
  [ 'DBI attributes',                   { AutoCommit => 1, RaiseError => 1, PrintError => 0 }, 5 ],
  [ 'private_, dbi_ and dbd_ names',    { private_app => $VALUE, dbi_connect_method => 'connect', dbd_verbose => 1 }, 5 ],
  [ 'a parameter name set to undef',    { sslmode => undef },                             5 ],
  [ 'a parameter name set to the empty string', { connect_timeout => '' },                5 ],
  [ 'pool_size',                        { pool_size => 3 },                               3 ],
  [ 'the owner\'s options',             { async => 'ev', quote_names => 1, on_connect_do => [ 'SELECT 1' ] }, 5 ],
  [ 'all of those at once',
    { pg_enable_utf8 => 1, RaiseError => 1, private_app => $VALUE, sslmode => undef,
      pool_size => 3, async => 'ev', quote_names => 1 },                                  3 ],
) {
  my ($label, $beside, $pool_size) = @$case;
  my ($s, $err) = given([ static(), $beside ]);
  ok !defined $err, "$label beside the broker: the connect info is taken" or diag $err;
  is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%STATIC,
    '... a pool connection is opened from the broker\'s answer, and none of it reaches libpq'
    or diag $@;
  is_deeply scalar eval { parse_conninfo(listen_conninfo($s)) }, \%STATIC,
    '... and so is the listen connection'
    or diag $@;
  is scalar eval { $s->pool->max_size }, $pool_size, "... the pool may hold $pool_size connections";
}

# ---------------------------------------------------------------------------
# 3. After the refusal.
# ---------------------------------------------------------------------------

# Every value of the static connect info of this section carries $OLD.
my $OLD = 'k76-before';
my @static_info = ( "dbi:Pg:dbname=$OLD-db;host=$OLD.example", "$OLD-user", "$OLD-pw" );
my %static_parsed = ( dbname => "$OLD-db", host => "$OLD.example", user => "$OLD-user", password => "$OLD-pw" );

for my $before (
  [ 'a storage never given connect info', sub { } ],
  [ 'a storage with static connect info', sub { $_[0]->connect_info([ @static_info ]) } ],
  [ 'a storage with static connect info and a pooled connection',
    sub {
      $_[0]->connect_info([ @static_info ]);
      is_deeply scalar eval { parse_conninfo(spawn_conninfo($_[0])) }, \%static_parsed,
        '(the static connection has a pool connection)' or diag $@;
    } ],
  [ 'a storage with another broker attached',
    sub { $_[0]->connect_info([ DBIO::AccessBroker::Static->new(dbname => "$OLD-db", username => "$OLD-user", password => "$OLD-pw") ]) } ],
) {
  my ($label, $prepare) = @$before;

  for my $detach (undef, qw( _clear_access_broker clear_access_broker )) {
    my $s = $EV->new(undef);
    $prepare->($s);

    my $broker = static();
    my (undef, $err) = given([ $broker, { sslmode => $VALUE, pool_size => 2 } ], $s);
    like $err // '', qr/given beside an AccessBroker \(sslmode\)/, "$label: sslmode beside a broker is refused";
    unlike $err // '', qr/\Q$OLD\E/, '... naming nothing of what the storage was connected from';

    # What stays configured: the broker that was given, and nothing to
    # connect from but it.
    is $s->access_broker, $broker, '... the broker that was given is attached';
    is $s->{_conninfo}, undef, '... no conninfo is stored';
    is_deeply [ holding($s, $OLD) ], [], '... and nothing of the connect info before is left in the storage object';

    if (!$detach) {
      for my $ask ('asked for a connection', 'asked again') {
        my $got = connection_attempts($s);
        like $got->{pool}, qr/given beside an AccessBroker \(sslmode\)/,
          "$label, $ask: a pool connection is refused, naming the parameter";
        like $got->{listen}, qr/given beside an AccessBroker \(sslmode\)/,
          '... and so is the listen connection';
        is_deeply $got->{handles}, [], '... nothing reaches EV::Pg';
        unlike "$got->{pool} $got->{listen}", qr/$LEAK|\Q$OLD\E/, '... and no value is in either message';
      }
      ok !eval { $s->_conninfo_string; 1 }, "$label: there is no conninfo to render either";
      like $@, qr/given beside an AccessBroker \(sslmode\)/, '... for the same reason';

      # Given the same again, it is refused again.
      (undef, $err) = given([ $broker, { sslmode => $VALUE, pool_size => 2 } ], $s);
      like $err // '', qr/given beside an AccessBroker \(sslmode\)/, "$label: the same connect info again is refused again";
      is scalar(@EV::Pg::NEW), 0, '... nothing reaches EV::Pg';

      # Without the parameter the broker is taken, and nothing is left of the
      # refusal.
      (undef, $err) = given([ $broker, { pool_size => 2, pg_enable_utf8 => 1 } ], $s);
      ok !defined $err, "$label: the same broker without the parameter is taken" or diag $err;
      is_deeply $s->_access_broker_call_attributes, { pg_enable_utf8 => 1 },
        '... the refused parameter is not among what stands beside the broker now';
      is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%STATIC,
        '... a pool connection is opened from the broker\'s answer' or diag $@;
      is_deeply scalar eval { parse_conninfo(listen_conninfo($s)) }, \%STATIC,
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
        '... nothing reaches EV::Pg: not from the broker, not from the connect info before';
      unlike "$got->{pool} $got->{listen}", qr/$LEAK|\Q$OLD\E/, '... and no value is in either message';

      # Static connect info is taken again afterwards.
      (undef, $err) = given([ @static_info ], $s);
      ok !defined $err, "$label, then $detach: static connect info is taken again" or diag $err;
      is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%static_parsed,
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
  @EV::Pg::NEW = ();

  my $schema = eval {
    BrokerSchema->connect($broker->(), { async => 'ev', pool_size => 3, pg_enable_utf8 => 1, sslmode => $VALUE });
  };
  ok $schema, "$label, connect(\$broker, { async => 'ev', ..., sslmode => ... }): the schema is connected"
    or diag $@;

  SKIP: {
    skip 'the connect itself was refused', 10 unless $schema;
    my $storage = $schema->storage;

    for my $ask ('the first ->async', '->async again') {
      my $async = eval { $storage->async };
      my $err   = "$@";
      ok !$async, "$label, $ask: no transport is handed out";
      like $err, qr/given beside an AccessBroker \(sslmode\)/,
        '... the refusal names sslmode -- not pool_size or the DBD attribute beside it';
      unlike $err, $LEAK, '... and no value';
    }

    my $f   = eval { $storage->select_async('pg_catalog.pg_class', [ 'relname' ]) };
    my $err = $f && $f->is_failed ? ($f->failure)[0] : "$@";
    ok !$f || $f->is_failed, "$label: a statement on the async API is not run";
    like $err, qr/given beside an AccessBroker \(sslmode\)/, '... for the same reason';
    unlike $err, $LEAK, '... and no value';
    is scalar(@EV::Pg::NEW), 0, "$label: nothing was handed to EV::Pg at any point";
  }
}

# ---------------------------------------------------------------------------
# 5. Through a schema: the owner's dbh is refused as well (core k307).
# ---------------------------------------------------------------------------

# Every DBI->connect while $code runs: [ $dsn, $user, $password, \%attrs ]
# each. There is no server to answer one, and that is what it dies with.
sub dbi_connects {
  my ($code) = @_;
  my @asked;
  no warnings 'redefine';
  local *DBI::connect = sub {
    my ($class, @args) = @_;
    push @asked, [ @args ];
    die "this test has no server\n";
  };
  $code->();
  return \@asked;
}

my @USES = (
  [ 'the owner\'s dbh, when it is used', sub { $_[0]->dbh } ],
  [ 'used again',                        sub { $_[0]->dbh } ],
  [ 'ensure_connected after that',       sub { $_[0]->ensure_connected } ],
);

for my $case (
  [ 'a Static broker', \&static, 'DBIO::AccessBroker::Static', 'k76-static-pw' ],
  [ 'a Vault broker',  \&vault,  'DBIO::AccessBroker::Vault',  'k76-vault-pw'  ],
) {
  my ($label, $broker, $class, $password) = @$case;
  my %allowed = (async => 'ev', pool_size => 3, pg_enable_utf8 => 1);

  for my $given (
    [ 'sslmode',                     { sslmode => "$VALUE-tls" },                                [ 'sslmode' ] ],
    [ 'connect_timeout and sslmode', { connect_timeout => "$VALUE-7", sslmode => "$VALUE-tls" }, [ 'connect_timeout', 'sslmode' ] ],
    [ 'application_name',            { application_name => "$VALUE-app" },                       [ 'application_name' ] ],
  ) {
    my ($what, $beside, $names) = @$given;
    my $t      = "$label, $what beside it";
    my $listed = join ', ', @$names;
    @EV::Pg::NEW = ();

    my $schema = eval { BrokerSchema->connect($broker->(), { %allowed, %$beside }) };
    ok $schema, "$t: the schema is connected" or diag $@;

    SKIP: {
      skip 'the connect itself was refused', 3 * @USES + 2 unless $schema;
      my $storage = $schema->storage;

      my @err;
      my $asked = dbi_connects(sub {
        push @err, (eval { $_->[1]->($storage); 1 } ? undef : "$@") for @USES;
      });

      for my $i (0 .. $#USES) {
        ok defined $err[$i], "$t -- $USES[$i][0]: no connection";
        like $err[$i] // '',
          qr/A DBI storage does not apply parameter\(s\) given beside AccessBroker \Q$class\E \(\Q$listed\E\)/,
          '... the sync storage refuses, naming the broker class and the parameters -- not pool_size or the DBD attribute beside them';
        unlike $err[$i] // '', $LEAK, '... and no value: not the parameter\'s, not the password of the broker\'s answer';
      }
      is scalar(@$asked), 0, "$t: DBI was not asked for a connection, at any of them";
      is scalar(@EV::Pg::NEW), 0, '... and nothing was handed to EV::Pg: neither half opens a connection without the parameter';
    }
  }

  # The control: the same schema without the parameter asks DBI for the
  # owner's connection, so the refusals above are the parameter's doing --
  # not the broker's, not the mode's, not the DBD attribute's.
  my $schema = eval { BrokerSchema->connect($broker->(), { %allowed }) };
  ok $schema, "$label, no parameter beside it: the schema is connected" or diag $@;

  SKIP: {
    skip 'the connect itself was refused', 5 unless $schema;
    my $err;
    my $asked = dbi_connects(sub { $err = eval { $schema->storage->dbh; 1 } ? '' : "$@" });

    is scalar(@$asked), 1, "$label, no parameter beside it: the owner's dbh asks DBI for a connection";
    my ($dsn, undef, $pass, $attrs) = @{ $asked->[0] || [] };
    is $dsn, 'dbi:Pg:dbname=appdb;host=db.example;port=5433', '... to the DSN of the broker\'s answer';
    is $pass, $password, '... with its password';
    is_deeply [ map { $attrs->{$_} } qw( pg_enable_utf8 pool_size async ) ], [ 1, undef, undef ],
      '... and the DBD attribute beside the broker -- neither pool_size nor the mode, which are not DBI\'s';
    unlike $err, qr/does not apply parameter/, '... it is not refused: it fails for want of a server';
  }
}

done_testing;
