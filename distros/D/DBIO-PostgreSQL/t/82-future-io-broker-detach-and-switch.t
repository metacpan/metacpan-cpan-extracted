use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed refaddr reftype );
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );

# OFFLINE test (karr k97): what the future_io transport opens when its
# AccessBroker goes away, or is exchanged for static connect info and back --
# the listen connection above all.
#
# WHY. Every connection of this transport is opened from what the attached
# broker answers, asked anew through the per-spawn provider core installs: a
# pool connection by the pool, the listen connection by _listen_open, at the
# first listen and at every reconnect. That provider outlives the broker in two
# places -- on the storage, when the broker is detached with DBIO::Storage's
# public clear_access_broker, and inside a pool built with it. A connection
# opened then has nobody to ask. dbio-async pins for its own
# _async_broker_conninfo that nothing is opened then and that the error says
# so (its t/29, k43), and leaves the listen connection to the drivers, whose
# seam opens it. This transport overrides _async_broker_conninfo as well, so
# neither half was pinned here: it read whatever was stored in the broker's
# place and reported that as "what the AccessBroker returned" -- with no
# broker there to have returned anything -- and would have connected from a
# stored conninfo had there been one.
#
# What this file claims:
#   1. nothing is kept from an answer. With a broker attached, and still after
#      a pool connection and the listen connection were opened from it, its
#      password is nowhere in the storage object -- pool and listen state
#      included -- but inside the broker itself;
#   2. a broker detached while its provider is still installed opens nothing:
#      not a pool connection, not the listen connection -- through the seam,
#      through a first listen(), through listen_reconnect() on a connection
#      that was up. Each fails saying that no broker is attached, not that a
#      broker answered something unusable; nothing reaches DBI->connect; no
#      error and no on_listen_error report names the password. With the
#      provider gone as well, the storage is where one never given connect
#      info is;
#   3. broker -> static -> broker: every change closes the listen connection
#      of the connect info before it and leaves only what belongs to the new
#      one; the next listen connection and the next pool connection are opened
#      from that and from nothing else. With the second broker detached, none
#      is opened from the static connect info before it -- and it is the
#      missing broker that refuses, not the chance that nothing is stored.
#
# WHAT RUNS FOR REAL: core's connect_info, broker attach, per-spawn provider
# and listen machinery (listen, listen_reconnect, teardown), dbio-async's pool
# and watch loop, the built-in brokers, and this dist's _async_broker_conninfo,
# _listen_open and the other listen seams.
# THE SUBSTITUTIONS: DBI->connect records its arguments -- OUTSIDE the
# storage, so the record is not what claim 1 finds -- and hands out a fake
# handle over a real socketpair, which keeps nothing of them; the Vault client
# is a stub.
#
# NOT claimed here: what a closure holds. The scan of claim 1 reads data, not
# code.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
    unless DBIO::Storage::Async->can('listen_alive');
  plan skip_all => 'the installed dbio-async predates its Future::IO listen seams (dbio-async k22)'
    unless defined &DBIO::Async::Storage::_listen_drain
        && defined &DBIO::Async::Storage::_listen_watch;
}

use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;

our @CONNECTS;   # every DBI->connect: its arguments, and which seam asked
our @REPORTS;    # every on_listen_error report

# --- the fake DBD::Pg -----------------------------------------------------------

# A handle that keeps nothing of what it was connected with, as a real one
# keeps its credentials where no scan of the storage reaches. The socketpair
# is "libpq's socket": the watch loop dups and polls it for real.
{
  package FakeDetach::DBH;

  sub new {
    socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    return bless {
      client => $client, server => $server, pg_socket => fileno($client),
      Active => 1, sql => [],
    }, shift;
  }

  sub do          { push @{ $_[0]{sql} }, $_[1]; '0E0' }
  sub ping        { 1 }
  sub pg_notifies { undef }
  sub err         { undef }
  sub errstr      { undef }
  sub disconnect  { $_[0]{Active} = 0; $_[0]{disconnected}++; 1 }
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    my $listen = 0;
    for (my $i = 1; my @frame = caller $i; $i++) {
      next unless $frame[3] =~ /::_listen_open\z/;
      $listen = 1;
      last;
    }
    push @CONNECTS, {
      dsn => $dsn, user => $user, password => $password, attrs => { %$attrs },
      listen => $listen,
    };
    return FakeDetach::DBH->new;
  };
}

my %FORCED = (
  AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1,
  # every error DBI reports for the handle is raised by the transport (karr k120)
  HandleError => \&DBIO::PostgreSQL::Storage::Async::_pg_dbi_error,
);

# --- brokers ------------------------------------------------------------------

{
  package FakeVaultClient;
  sub new { my ($class, $password) = @_; bless { password => $password }, $class }
  sub read_secret { return { username => 'vault-user', password => $_[0]{password} } }
}

# Answers whatever the test gives it.
{
  package HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  package DetachSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

sub vault {
  my ($password) = @_;
  return DBIO::AccessBroker::Vault->new(
    vault     => FakeVaultClient->new($password),
    dsn       => 'dbi:Pg:dbname=appdb;host=db.example',
    cred_path => 'database/creds/app',
    dbi_attrs => { pg_enable_utf8 => 1 },
  );
}

sub watched {
  my ($async) = @_;
  $async->on_listen_error(sub { push @REPORTS, $_[1] });
  return $async;
}

sub direct {
  my (@info) = @_;
  my $async = DBIO::PostgreSQL::Storage::Async->new(undef);
  $async->connect_info([ @info ]);
  return watched($async);
}

# Every way a broker's answer reaches this transport (t/67, t/73, t/81), each
# with the password the case is given: [ label, builder ]. A builder returns
# the backend and whatever has to stay alive beside it.
my @ATTACHED = (
  [ 'Vault (a DBI-form answer)', sub { direct(vault($_[0])) } ],
  [ 'Static (libpq parameters)', sub {
      direct(DBIO::AccessBroker::Static->new(
        host => 'db.example', dbname => 'appdb', username => 'app', password => $_[0],
      ));
  } ],
  [ 'parameters whose dbname is a DSN', sub {
      direct(HashBroker->new({
        dbname => 'dbi:Pg:dbname=appdb', user => 'app', password => $_[0],
      }));
  } ],
  [ "the transport's own connect info", sub {
      direct(HashBroker->new({
        dsn => 'dbi:Pg:service=app', user => 'app', password => $_[0], attrs => {},
      }));
  } ],
  [ 'Vault with connect options beside it', sub {
      direct(vault($_[0]), { pool_size => 3, pg_server_prepare => 0 });
  } ],
  # The way an application gets there: the schema connected with the mode, the
  # backend embedded in the sync storage.
  [ 'Static, through a schema connected with future_io', sub {
      my $schema = DetachSchema->connect(
        DBIO::AccessBroker::Static->new(
          host => 'db.example', dbname => 'appdb', username => 'app', password => $_[0],
        ),
        { async => 'future_io' },
      );
      return (watched($schema->storage->async), $schema);
  } ],
);

# --- helpers --------------------------------------------------------------------

# Every place in the storage where a plain value contains $needle, as a path.
# Not looked into: a broker, which is the one that may hold the password; the
# owning sync storage and the schema, which are not this storage -- the sync
# storage has rules of its own for what it keeps of an answer; and code.
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

# One attempt to open a connection, as how it ended and how many times
# DBI->connect was reached for it:
#   spawn             a new pool connection (kept, so the next one is new too)
#   listen open       the seam itself
#   listen            the public listen(), on a channel not yet listened to
#   listen_reconnect  the public rebuild of a listen connection that is up
sub attempt {
  my ($async, $what) = @_;
  my $before = @CONNECTS;
  my $f = eval {
      $what eq 'spawn'            ? $async->pool->acquire
    : $what eq 'listen open'      ? $async->_listen_open
    : $what eq 'listen_reconnect' ? $async->listen_reconnect
    :                               $async->listen(jobs => sub { });
  };
  my $how = !defined $f   ? "died: $@"
          : !$f->is_ready ? 'still pending'
          : $f->is_failed ? 'failed: ' . ($f->failure)[0]
          :                 'opened';
  return { how => $how, opened => @CONNECTS - $before };
}

sub listen_dbh { $_[0]{_listen} && $_[0]{_listen}{conn} && $_[0]{_listen}{conn}{dbh} }

# What a storage that was never given connect info does with each attempt.
my $NO_POOL_CONNINFO   = qr/conninfo or conninfo_provider required/;
my $NO_LISTEN_CONNINFO = qr/PostgreSQL async conninfo must be a hashref with a dsn/;
for my $control (
  [ 'spawn',       $NO_POOL_CONNINFO ],
  [ 'listen open', $NO_LISTEN_CONNINFO ],
  [ 'listen',      $NO_LISTEN_CONNINFO ],
) {
  my ($what, $re) = @$control;
  my $async = watched(DBIO::PostgreSQL::Storage::Async->new(undef));
  my $got = attempt($async, $what);
  like $got->{how}, $re, "the control: a storage never given connect info, $what: nothing to connect from";
  is $got->{opened}, 0, '... and nothing is opened';
  $async->disconnect;
}

my $NO_BROKER = qr/\S+ has no AccessBroker attached to ask for connect info/;
my $AS_ANSWER = qr/AccessBroker (?:returned|answered)/;

# ---------------------------------------------------------------------------
# 1. Nothing is kept from an answer.
# ---------------------------------------------------------------------------

for my $case (@ATTACHED) {
  my ($label, $build) = @$case;
  my $password = 'k97-kept-pw';
  my ($async, $keep) = $build->($password);

  ok $async->access_broker && $async->_conninfo_provider,
    "$label: the broker is attached, with its provider";
  is $async->{_conninfo}, undef, '... no conninfo is kept from its answer';
  is_deeply [ holding($async, $password) ], [],
    '... its password is nowhere in the storage but in the broker';

  # The controls that give the scan its needle: the password is real, and it
  # does travel through this storage on its way to DBI->connect.
  is_deeply attempt($async, 'spawn'), { how => 'opened', opened => 1 },
    '... a pool connection is opened';
  is $CONNECTS[-1]{password}, $password, '... with the password, from the broker';

  is_deeply attempt($async, 'listen'), { how => 'opened', opened => 1 },
    '... listen() opens the listen connection';
  is_deeply [ @{ $CONNECTS[-1] }{qw( password listen )} ], [ $password, 1 ],
    '... with the password, from the broker, through _listen_open';

  ok $async->{pool} && listen_dbh($async), '... pool and listen connection now exist';
  is_deeply [ holding($async, $password) ], [],
    '... and still the password is nowhere in the storage, pool and listen state included';

  $async->disconnect;
}

# ---------------------------------------------------------------------------
# 2. A broker detached while its provider is still installed.
# ---------------------------------------------------------------------------

# clear_access_broker is public on DBIO::Storage: it takes the broker away and
# leaves the provider on the storage. Core's own _clear_access_broker takes the
# provider too, but a pool built before keeps the one it was built with. With
# and without connections opened before, both ways:
for my $case (@ATTACHED) {
  my ($case_label, $build) = @$case;

  for my $detach (qw( clear_access_broker _clear_access_broker )) {
    for my $up (1, 0) {
      my $label = "$case_label, $detach, "
                . ($up ? 'pool and listen connection up' : 'nothing opened yet');
      my $password = 'k97-gone-pw';
      my ($async, $keep) = $build->($password);

      if ($up) {
        is_deeply [ attempt($async, 'spawn'), attempt($async, 'listen') ],
          [ ({ how => 'opened', opened => 1 }) x 2 ],
          "$label: attached, a pool connection and the listen connection are opened";
        is_deeply [ map { $_->{password} } @CONNECTS[-2, -1] ], [ ($password) x 2 ],
          "... with the broker's password";
      }

      @REPORTS = ();
      $async->$detach;
      ok !$async->access_broker, "$label: the broker is detached";

      my $spawn  = attempt($async, 'spawn');
      my $seam   = attempt($async, 'listen open');
      my $public = attempt($async, $up ? 'listen_reconnect' : 'listen');

      is $spawn->{opened} + $seam->{opened} + $public->{opened}, 0,
        "$label: nothing reaches DBI->connect -- not for a pool spawn, not for "
        . '_listen_open, not for ' . ($up ? 'listen_reconnect()' : 'listen()');
      unlike join(' ', (map { $_->{how} } $spawn, $seam, $public), @REPORTS), qr/\Q$password\E/,
        '... and no error or on_listen_error report names the password of the earlier answer';
      is_deeply [ holding($async, $password) ], [],
        '... which is nowhere in the storage either';
      unlike join(' ', (map { $_->{how} } $spawn, $seam, $public), @REPORTS), $AS_ANSWER,
        '... and nothing is reported as the answer of a broker: there is none';

      if ($detach eq '_clear_access_broker') {
        # The provider is gone from the storage as well: its listen connection
        # has nothing between it and what is stored, and that is nothing.
        like $seam->{how}, $NO_LISTEN_CONNINFO,
          '... _listen_open is where a storage never given connect info is';
        like $public->{how}, $NO_LISTEN_CONNINFO, '... and so is the public call';

        # A pool built before keeps the provider it was built with.
        like $spawn->{how}, ($up ? $NO_BROKER : $NO_POOL_CONNINFO),
          $up ? '... the pool built before fails its spawn for want of a broker'
              : '... and so is a pool, built only now';
      }
      else {
        like $spawn->{how}, $NO_BROKER,
          '... the pool spawn fails saying that no broker is attached';
        like $seam->{how}, $NO_BROKER, '... and so does _listen_open';
        like $public->{how}, $NO_BROKER, '... and the public call, as a failed Future';
        ok scalar(grep { $_ =~ $NO_BROKER } @REPORTS),
          '... which on_listen_error is told as well';
      }

      $async->disconnect;
    }
  }
}

# ---------------------------------------------------------------------------
# 3. Broker -> static -> broker: each change leaves only what belongs to the
#    new connect info, for the listen connection as for the pool.
# ---------------------------------------------------------------------------

{
  my $async = direct(vault('first-broker-pw'));
  my %broker_1 = (
    dsn => 'dbi:Pg:dbname=appdb;host=db.example', user => 'vault-user',
    password => 'first-broker-pw', attrs => { pg_enable_utf8 => 1, %FORCED },
  );

  is_deeply attempt($async, 'listen'), { how => 'opened', opened => 1 },
    'a broker first: listen() opens the listen connection';
  is_deeply $CONNECTS[-1], { %broker_1, listen => 1 }, '... from the broker';
  my $broker_listen = listen_dbh($async);

  # --- to static ---
  my %static = (
    dsn => 'dbi:Pg:dbname=staticdb;host=static.example', user => 'static-user',
    password => 'static-pw', attrs => { pg_enable_utf8 => 1 },
  );
  $async->connect_info([ @static{qw( dsn user password attrs )} ]);

  ok !$async->access_broker && !$async->_conninfo_provider,
    'then static connect info: the broker and its provider are gone';
  ok $broker_listen->{disconnected} && !$async->{_listen},
    '... the listen connection of the broker is closed, and nothing is listened to';
  is_deeply [ holding($async, 'first-broker-pw') ], [],
    "... and nothing is left of the broker's answer";

  my %static_connect = (%static, attrs => { pg_enable_utf8 => 1, %FORCED });
  is_deeply attempt($async, 'listen'), { how => 'opened', opened => 1 },
    '... listen() opens a listen connection';
  is_deeply $CONNECTS[-1], { %static_connect, listen => 1 }, '... from the static conninfo';
  my $static_listen = listen_dbh($async);
  isnt refaddr($static_listen), refaddr($broker_listen), '... a new one';
  is_deeply attempt($async, 'spawn'), { how => 'opened', opened => 1 },
    '... and a pool connection is opened';
  is_deeply $CONNECTS[-1], { %static_connect, listen => 0 }, '... from the static conninfo too';

  # --- back to a broker ---
  $async->connect_info([ HashBroker->new({
    dbname => 'dbi:Pg:dbname=seconddb', user => 'app', password => 'second-broker-pw',
  }) ]);

  ok $async->access_broker && $async->_conninfo_provider,
    'then a broker again: it is attached, with its provider';
  is $async->{_conninfo}, undef,
    '... no conninfo is stored: neither its answer nor the static one before it';
  ok $static_listen->{disconnected} && !$async->{_listen},
    '... the listen connection of the static conninfo is closed';
  is_deeply [ map { holding($async, $_) } qw( static-pw static-user staticdb static.example ) ], [],
    '... nothing of the static connect info is left in the storage';

  my %broker_2 = (
    dsn => 'dbi:Pg:dbname=seconddb', user => 'app', password => 'second-broker-pw',
    attrs => { %FORCED },
  );
  is_deeply attempt($async, 'listen'), { how => 'opened', opened => 1 },
    '... listen() opens a listen connection';
  is_deeply $CONNECTS[-1], { %broker_2, listen => 1 },
    '... from the second broker, and from nothing else';
  is_deeply attempt($async, 'spawn'), { how => 'opened', opened => 1 },
    '... and a pool connection is opened';
  is_deeply $CONNECTS[-1], { %broker_2, listen => 0 }, '... from the second broker too';
  is_deeply [ map { holding($async, $_) } qw( static-pw second-broker-pw ) ], [],
    '... and neither password is in the storage, pool and listen state included';

  # --- that broker taken away ---
  @REPORTS = ();
  $async->clear_access_broker;
  for my $what ('listen_reconnect', 'listen open', 'spawn') {
    my $got = attempt($async, $what);
    like $got->{how}, $NO_BROKER,
      "with that broker detached, $what fails for want of a broker";
    is $got->{opened}, 0, '... none is opened from the static connect info before it';
  }

  # Core drops the static conninfo when a broker is attached (its k265), so
  # none was there to open from. This transport does not lean on that: were
  # one stored, it is still the missing broker that refuses. White-box, to
  # tell a refusal from a lucky undef.
  {
    local $async->{_conninfo} = {
      dsn => $static{dsn}, user => $static{user}, password => $static{password}, attrs => {},
    };
    for my $what ('listen open', 'listen_reconnect', 'spawn') {
      my $got = attempt($async, $what);
      like $got->{how}, $NO_BROKER,
        "even with a conninfo stored in the broker's place, $what fails for want of a broker";
      is $got->{opened}, 0, '... and does not connect from it';
    }
  }

  unlike join(' ', @REPORTS), qr/static-pw|second-broker-pw/,
    '... and no on_listen_error report names a password';
  $async->disconnect;
}

done_testing;
