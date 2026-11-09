use strict;
use warnings;

use Test::More;
use Scalar::Util qw( blessed refaddr reftype );

use Future;
use DBIO::Test;              # core's offline fake-storage schema harness
use DBIO::Test::Storage;
use DBIO::SQLMaker;
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::Async::Storage;

# OFFLINE test (karr k43): what a future_io backend is left with when its
# AccessBroker goes away, or is exchanged for static connect info and back.
#
# WHY. A pool connection is opened from what the attached broker answers, asked
# anew for each one through the per-spawn provider core installs. That provider
# outlives the broker in two places: on the storage, when the broker is
# detached with DBIO::Storage's public clear_access_broker rather than core's
# _clear_access_broker, and inside a pool that was built with it either way. A
# connection opened then has nobody to ask. If anything of an earlier answer
# were still around -- a conninfo kept at attach, one remembered from the last
# spawn, the pool of the connect info before -- it would be opened with that:
# the user and password of a broker that is no longer there, which it may have
# rotated out long ago. The ev transports had exactly this (dbio-mysql-ev and
# dbio-postgresql-ev, their k61-k63); t/20 pins what this transport makes of
# an answer, and nothing pinned what it keeps of one.
#
# What this file claims:
#   1. nothing is kept from an answer. With a broker attached, and still after
#      a connection was opened from it, its password is nowhere in the storage
#      object -- the pool included -- but inside the broker itself;
#   2. a broker detached while its provider is still installed opens nothing.
#      The next pool connection fails -- as a failed Future, acquire never
#      throws -- saying that no broker is attached, not that a broker answered
#      something unusable; nothing reaches the driver's connect; no error names
#      the password. The same for the one generic listen seam that opens a
#      connection, the pooled _notify_send. Since dbio 4108809c8 that refusal
#      is core's, made by the provider before the transport is asked; this
#      dist's own check in _async_broker_conninfo is the seam refusing a
#      direct call, pinned in t/20 section 7. With the provider gone as well and
#      no pool built yet, the storage is where one never given connect info is;
#   3. a change between a broker and static connect info leaves only what
#      belongs to the new one, and the pool with it: after broker -> static no
#      broker, no provider and nothing of the answer, the pool of the broker
#      shut down, the next connection opened from the static conninfo; after
#      static -> broker no static conninfo anywhere, its pool shut down, the
#      next connection opened from the broker -- and with that broker detached,
#      none is opened from the static connect info before it.
#
# WHAT RUNS FOR REAL: core's connect_info, broker attach and per-spawn
# provider, DBIO::Async::Pool on core's PoolBase, the built-in brokers, and
# this dist's pool() and _async_broker_conninfo.
# THE SUBSTITUTIONS: the driver's _normalize_conninfo does what both drivers'
# do (dbio-postgresql, dbio-mysql); its _create_pool_connection records the
# conninfo it is handed -- OUTSIDE the storage, so the record is not what
# claim 1 finds -- instead of calling DBI->connect; the Vault client is a stub.
#
# NOT claimed here. The listen connection: _listen_open is the driver's seam
# and opens it from the same provider, so that half is the drivers' to pin
# (dbio-postgresql, dbio-mysql). And what a closure holds: the scan of claim 1
# reads data, not code.

my @CONNECTS;   # every conninfo the driver's connect was handed

# --- a fake driver: sync storage + convention-resolved future_io adapter ----

{
  package T29::Driver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(T29DBD => __PACKAGE__);
}

{
  package T29::Driver::Storage::Async;
  use base 'DBIO::Async::Storage';

  sub sql_maker_class           { 'DBIO::SQLMaker' }
  sub _transform_sql            { $_[1] }
  sub _post_insert_sql          { '' }
  sub _conn_ready               { 1 }
  sub _shutdown_pool_connection { }
  sub _notify_sql               { ('SELECT t29_notify(?, ?)', [ @_[1, 2] ]) }

  # The drivers' seam: DBI form into { dsn, user, password, attrs }, pool_size
  # lifted for core to split off; anything else passes through.
  sub _normalize_conninfo {
    my ($self, $info) = @_;
    return $info
      unless ref $info eq 'ARRAY'
      && defined $info->[0] && !ref $info->[0] && $info->[0] =~ /^dbi:/i;
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

  # The driver's connect. The connection keeps nothing of the conninfo: a real
  # handle holds its credentials where no scan of the storage reaches.
  sub _create_pool_connection {
    my ($self, $conninfo) = @_;
    push @CONNECTS, $conninfo;
    return { id => scalar @CONNECTS };
  }
}

# The same driver, its adapter taking connect options beside a broker.
{
  package T29::DeclDriver::Storage::Async;
  use base 'T29::Driver::Storage::Async';
  sub transport_capabilities {
    return ($_[0]->SUPER::transport_capabilities, 'broker_connect_options');
  }
}

# --- brokers ------------------------------------------------------------------

{
  package T29::VaultClient;
  sub new { my ($class, $password) = @_; bless { password => $password }, $class }
  sub read_secret { return { username => 'vault-user', password => $_[0]{password} } }
}

# Answers whatever the test gives it.
{
  package T29::AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

sub vault {
  my ($password) = @_;
  return DBIO::AccessBroker::Vault->new(
    vault     => T29::VaultClient->new($password),
    dsn       => 'dbi:T29DBD:dbname=appdb;host=db.example',
    cred_path => 'database/creds/app',
    dbi_attrs => { t29_utf8 => 1 },
  );
}

sub direct {
  my ($class, @info) = @_;
  my $async = $class->new(undef);
  $async->connect_info([ @info ]);
  return $async;
}

# Every way a broker's answer reaches this transport (t/20), each with the
# password the case is given: [ label, builder ]. A builder returns the backend
# and whatever has to stay alive beside it.
my @ATTACHED = (
  [ 'Vault (a DBI-form answer)', sub {
      direct('T29::Driver::Storage::Async', vault($_[0]));
  } ],
  [ 'connection parameters whose dbname is a DSN', sub {
      direct('T29::Driver::Storage::Async', T29::AnswerBroker->new({
        dbname => 'dbi:T29DBD:dbname=appdb', user => 'app', password => $_[0],
      }));
  } ],
  [ "the transport's own connect info", sub {
      direct('T29::Driver::Storage::Async', T29::AnswerBroker->new({
        dsn => 'dbi:T29DBD:service=app', user => 'app', password => $_[0], attrs => {},
      }));
  } ],
  [ 'Vault with connect options beside it', sub {
      direct('T29::DeclDriver::Storage::Async',
        vault($_[0]), { pool_size => 3, t29_timeout => 5 });
  } ],
  # The way an application gets there: the schema connected with the mode, the
  # backend embedded in the sync storage, which builds the DSN for Static.
  [ 'Static, through a schema connected with future_io', sub {
      my $schema = DBIO::Test->init_schema(
        no_connect   => 1,
        storage_type => '+T29::Driver::Storage',
      );
      $schema->connection(
        DBIO::AccessBroker::Static->new(
          host => 'db.example', dbname => 'appdb', username => 'app', password => $_[0],
        ),
        { async => 'future_io' },
      );
      return ($schema->storage->async, $schema);
  } ],
);

# --- helpers --------------------------------------------------------------------

# Every place in the storage where a plain value contains $needle, as a path.
# Not looked into: a broker, which is the one that may hold the password; the
# owning sync storage and the schema, which are not this storage -- the sync
# storage has rules of its own for what it keeps of an answer (core
# t/access_broker/16-dbi-broker-detached.t); and code.
sub holding {
  my ($value, $needle, $path, $seen) = @_;
  $path //= '$storage';
  $seen //= {};
  return () unless defined $value;
  return index($value, $needle) >= 0 ? ($path) : () unless ref $value;
  return () if blessed($value) && grep { $value->isa($_) }
    qw( DBIO::AccessBroker DBIO::Storage::DBI DBIO::Schema );
  return () if $seen->{ refaddr($value) }++;
  my $type = reftype($value);
  return map { holding($value->{$_}, $needle, "$path\->{$_}", $seen) } sort keys %$value
    if $type eq 'HASH';
  return map { holding($value->[$_], $needle, "$path\->[$_]", $seen) } 0 .. $#$value
    if $type eq 'ARRAY';
  return holding($$value, $needle, "\${ $path }", $seen)
    if $type eq 'SCALAR' || $type eq 'REF';
  return ();
}

# One attempt to open a connection -- a pool spawn, or the pooled notify --
# as how it ended and how many conninfos reached the driver's connect for it.
# A connection acquired here is kept, so the next attempt spawns a new one.
sub attempt {
  my ($async, $what) = @_;
  my $before = @CONNECTS;
  my $f = eval {
    $what eq 'notify' ? $async->_notify_send('jobs', 'payload') : $async->pool->acquire;
  };
  my $how = !defined $f   ? "died: $@"
          : !$f->is_ready ? 'still pending'
          : $f->is_failed ? 'failed: ' . ($f->failure)[0]
          :                 'opened';
  return { how => $how, opened => @CONNECTS - $before };
}

# What a storage that was never given connect info does with an attempt.
my $UNCONFIGURED = attempt(T29::Driver::Storage::Async->new(undef), 'spawn');
like $UNCONFIGURED->{how}, qr/conninfo or conninfo_provider required/,
  'the control: a storage never given connect info has nothing to build a pool from';
is $UNCONFIGURED->{opened}, 0, '... and opens nothing';

my $NO_BROKER = qr/^failed: \S+ has no AccessBroker attached/;

# ---------------------------------------------------------------------------
# 1. Nothing is kept from an answer.
# ---------------------------------------------------------------------------

for my $case (@ATTACHED) {
  my ($label, $build) = @$case;
  my $password = 'k43-kept-pw';
  my ($async, $keep) = $build->($password);

  ok $async->access_broker && $async->_conninfo_provider,
    "$label: the broker is attached, with its provider";
  is $async->{_conninfo}, undef, '... no conninfo is kept from its answer';
  is_deeply [ holding($async, $password) ], [],
    '... its password is nowhere in the storage but in the broker';

  # The control that gives the scan its needle: the password is real, and it
  # does travel through this storage on its way to the driver's connect.
  is_deeply attempt($async, 'spawn'), { how => 'opened', opened => 1 },
    '... a pool connection is opened';
  is $CONNECTS[-1]{password}, $password, '... with the password, from the broker';

  ok $async->{pool}, '... the pool now exists';
  is_deeply [ holding($async, $password) ], [],
    '... and still the password is nowhere in the storage, the pool included';
}

# ---------------------------------------------------------------------------
# 2. A broker detached while its provider is still installed.
# ---------------------------------------------------------------------------

# clear_access_broker is public on DBIO::Storage: it takes the broker away and
# leaves the provider on the storage. Core's own _clear_access_broker takes the
# provider too, but a pool built before keeps the one it was built with. With
# and without such a pool, both ways:
for my $case (@ATTACHED) {
  my ($case_label, $build) = @$case;

  for my $detach (qw( clear_access_broker _clear_access_broker )) {
    for my $pooled (1, 0) {
      my $label = "$case_label, $detach, "
                . ($pooled ? 'a connection open' : 'no pool yet');
      my $password = 'k43-gone-pw';
      my ($async, $keep) = $build->($password);

      if ($pooled) {
        is_deeply attempt($async, 'spawn'), { how => 'opened', opened => 1 },
          "$label: attached, a pool connection is opened";
        is $CONNECTS[-1]{password}, $password, "... with the broker's password";
      }

      $async->$detach;
      ok !$async->access_broker, "$label: the broker is detached";

      my $spawn  = attempt($async, 'spawn');
      my $notify = attempt($async, 'notify');

      is $spawn->{opened} + $notify->{opened}, 0,
        "$label: nothing reaches the driver's connect -- not for a pool spawn, "
        . 'not for the pooled notify';
      unlike "$spawn->{how} $notify->{how}", qr/\Q$password\E/,
        '... and no error names the password of the earlier answer';
      is_deeply [ holding($async, $password) ], [],
        '... which is nowhere in the storage either';

      if ($detach eq '_clear_access_broker' && !$pooled) {
        # Broker and provider gone, and no pool holding a provider of its own:
        # nothing stands between a connection and what is stored. That is
        # nothing.
        is_deeply $spawn, $UNCONFIGURED,
          '... the storage is where one never given connect info is';
        like $notify->{how}, qr/conninfo or conninfo_provider required/,
          '... for the pooled notify as well';
        next;
      }

      like $spawn->{how}, $NO_BROKER,
        '... the spawn fails as a failed Future, saying that no broker is attached';
      unlike $spawn->{how}, qr/AccessBroker answered/,
        '... not that a broker answered something unusable';
      like $notify->{how}, $NO_BROKER, '... and so does the pooled notify';
    }
  }
}

# ---------------------------------------------------------------------------
# 3. Broker -> static -> broker: each change leaves only what belongs to the
#    new connect info, and replaces the pool.
# ---------------------------------------------------------------------------

{
  my $async = direct('T29::Driver::Storage::Async', vault('first-broker-pw'));
  is_deeply attempt($async, 'spawn'), { how => 'opened', opened => 1 },
    'a broker first: a pool connection is opened';
  is $CONNECTS[-1]{password}, 'first-broker-pw', '... from the broker';
  my $broker_pool = $async->{pool};

  # --- to static ---
  my %static = (
    dsn      => 'dbi:T29DBD:dbname=staticdb;host=static.example',
    user     => 'static-user',
    password => 'static-pw',
    attrs    => { t29_utf8 => 1 },
  );
  $async->connect_info([ @static{qw( dsn user password attrs )} ]);

  ok !$async->access_broker && !$async->_conninfo_provider,
    'then static connect info: the broker and its provider are gone';
  is_deeply $async->{_conninfo}, \%static,
    '... the static conninfo is stored: it is what a static connection is opened from';
  is_deeply [ holding($async, 'first-broker-pw') ], [],
    "... and nothing is left of the broker's answer";
  ok $broker_pool->{_shutdown}, '... the pool of the broker is shut down';
  ok !defined $async->{pool}, '... and no longer the storage\'s';

  is_deeply attempt($async, 'spawn'), { how => 'opened', opened => 1 },
    '... a pool connection is opened';
  is_deeply $CONNECTS[-1], \%static, '... from the static conninfo';
  my $static_pool = $async->{pool};
  isnt refaddr($static_pool), refaddr($broker_pool), '... by a pool of its own';
  ok !$static_pool->{conninfo_provider}, '... which was given no provider to ask';

  # --- back to a broker ---
  $async->connect_info([ T29::AnswerBroker->new({
    dbname => 'dbi:T29DBD:dbname=appdb', user => 'app', password => 'second-broker-pw',
  }) ]);

  ok $async->access_broker && $async->_conninfo_provider,
    'then a broker again: it is attached, with its provider';
  is $async->{_conninfo}, undef,
    '... no conninfo is stored: neither its answer nor the static one before it';
  is_deeply [ map { holding($async, $_) } qw( static-pw static-user staticdb static.example ) ], [],
    '... nothing of the static connect info is left in the storage';
  is_deeply [ holding($async, 'second-broker-pw') ], [],
    "... and the broker's password is nowhere but in the broker";
  ok $static_pool->{_shutdown}, '... the pool of the static conninfo is shut down';

  is_deeply attempt($async, 'spawn'), { how => 'opened', opened => 1 },
    '... a pool connection is opened';
  is_deeply $CONNECTS[-1],
    { dsn => 'dbi:T29DBD:dbname=appdb', user => 'app', password => 'second-broker-pw', attrs => {} },
    '... from the second broker, and from nothing else';
  isnt refaddr($async->{pool}), refaddr($static_pool), '... by a pool of its own';
  is_deeply [ map { holding($async, $_) } qw( static-pw second-broker-pw ) ], [],
    '... and neither password is in the storage, the new pool included';

  # --- that broker taken away ---
  $async->clear_access_broker;
  my $spawn = attempt($async, 'spawn');
  like $spawn->{how}, $NO_BROKER,
    'with that broker detached, the next connection fails for want of a broker';
  is $spawn->{opened}, 0, '... none is opened from the static connect info before it';
}

done_testing;
