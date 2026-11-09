use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed refaddr reftype weaken );
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );
use Time::HiRes ();
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeNotifyServer;

# OFFLINE test (karr k67; from dbio-async k43, sister of dbio-postgresql k97):
# what the future_io transport opens when its AccessBroker goes away, or is
# exchanged for static connect info and back -- the listen connection above
# all, on both DBD bindings.
#
# WHY. Every connection of this transport is opened from what the attached
# broker answers, asked anew through the per-spawn provider core installs: a
# pool connection by the pool, the listen connection by this dist's
# _listen_open -- at the first listen, at listen_reconnect, and whenever core
# heals a listen connection that died. That provider outlives the broker in two
# places: on the storage, when the broker is detached with DBIO::Storage's
# public clear_access_broker, and inside a pool built with it. A connection
# opened then has nobody to ask: whatever it would be opened from is an earlier
# answer or the connect info before the broker, with credentials no broker
# answers for any more -- a Vault lease that has been revoked, or the account
# the broker was put there to replace. dbio-async pins for its pool and its
# pooled notify that nothing is opened then and that the error says so (its
# t/29), and leaves the listen connection to the drivers, whose seam opens it.
# This transport inherits _async_broker_conninfo, and with it the refusal; this
# file is what holds the listen half to it. dbio-postgresql had overridden the
# seam and lost the refusal that way (its k97) -- claim 0 is the tripwire for
# the same thing happening here.
#
# What this file claims:
#   0. _async_broker_conninfo is dbio-async's, not overridden by this dist;
#   1. nothing is kept from an answer. With a broker attached, and still after
#      a pool connection and the listen connection were opened from it, its
#      password is nowhere in the storage object -- pool and listen state
#      included -- but inside the broker itself;
#   2. a broker detached while its provider is still installed opens nothing:
#      not a pool connection, not the listen connection -- through the seam,
#      through a first listen(), through listen_reconnect() on a connection
#      that was up, through the retries core schedules after either, and
#      through core healing a listen connection that died after the detach.
#      Each fails saying that no broker is attached, not that a broker answered
#      something unusable; the public calls fail their Future and tell
#      on_listen_error; nothing reaches DBI->connect; no error, report or
#      warning names the password. With the provider gone as well, the storage
#      is where one never given connect info is;
#   3. broker -> static -> broker: every change closes the listen connection
#      of the connect info before it and leaves only what belongs to the new
#      one; the next listen connection and the next pool connection are opened
#      from that and from nothing else. Credentials a broker rotates reach the
#      next listen connection, opened on demand or by healing. With the second
#      broker detached, none is opened from the static connect info before it
#      -- and it is the missing broker that refuses, not the chance that
#      nothing is stored.
#
# WHAT RUNS FOR REAL: core's connect_info, broker attach, per-spawn provider
# and listen machinery (listen, listen_reconnect, healing, teardown),
# dbio-async's _async_broker_conninfo, pool, watch loop and backoff timer, the
# built-in brokers, and this dist's _listen_open and the other listen seams.
# The loop is Future::IO's built-in implementation.
# THE SUBSTITUTIONS: DBI->connect records its arguments -- OUTSIDE the
# storage, so the record is not what claim 1 finds -- and hands out a fake
# handle of the DBD the DSN names over a real socketpair, which keeps nothing
# of them; its statements are answered by t/lib/FakeNotifyServer.pm; the Vault
# client is a stub.
#
# NOT claimed here: what a closure holds -- the scan of claim 1 reads data, not
# code; and what becomes of a listen connection that is up when its broker is
# detached. Nothing closes it: it was opened while the broker answered for it.
# t/80 shows that against a server -- the same session goes on delivering --
# and holds claims 2 and 2b to real connections.

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed dbio-async predates _async_broker_conninfo'
    unless DBIO::Async::Storage->can('_async_broker_conninfo');
  plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
    unless DBIO::Storage::Async->can('listen_alive');
  plan skip_all => 'the installed dbio-async predates its Future::IO listen seams (dbio-async k22)'
    unless defined &DBIO::Async::Storage::_listen_drain
        && defined &DBIO::Async::Storage::_listen_watch;
}

use Future;
use Future::IO;

plan skip_all => "Future::IO is bound to $Future::IO::IMPL; this test drives the built-in implementation"
  if defined $Future::IO::IMPL && $Future::IO::IMPL ne 'Future::IO::_DefaultImpl';

use DBIO::MySQL::Storage ();
use DBIO::MySQL::Storage::MariaDB ();
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;

our $SERVER;
our @CONNECTS;   # every DBI->connect: its arguments, and which seam asked
our @HANDLES;    # the handle of each, by the same index, held weakly
our @REPORTS;    # every on_listen_error report
our @WARNINGS;   # every warning since a case last emptied it
our @WARNED;     # every warning of the whole file
our @OWNERS;     # the backends hold their owners weakly

$SIG{__WARN__} = sub { push @WARNINGS, @_; push @WARNED, @_ };

# --- the fake DBD ---------------------------------------------------------------

# A handle that keeps nothing of what it was connected with, as a real one
# keeps its credentials where no scan of the storage reaches. The socketpair is
# the server's socket: dbio-async polls it for real. It enforces what both real
# DBDs enforce and t/62 measures: no second statement and no ping over an
# asynchronous one in flight.
my $next_thread = 100;

{
  package K67::DBH;

  sub new {
    my ($class, $driver) = @_;
    socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    $client->blocking(0);
    $server->autoflush(1);
    return bless {
      client    => $client,
      server    => $server,
      Driver    => { Name => $driver },
      thread_id => ++$next_thread,
      Active    => 1,
      Warn      => 1,
      in_flight => undef,
    }, $class;
  }

  sub _sync_guard {
    my ($self, $what) = @_;
    die "DBD::mysql::db $what failed: Calling a synchronous function on an asynchronous handle\n"
      if $self->{in_flight};
  }

  sub prepare {
    my ($self, $sql, $attrs) = @_;
    $self->_sync_guard('prepare');
    die "DBD::mysql::db prepare failed: MySQL server has gone away\n" if $self->{dead};
    die "fake: a statement prepared without the async attribute: $sql\n"
      unless $attrs && ($attrs->{async} || $attrs->{mariadb_async});
    return bless { dbh => $self, sql => $sql }, 'K67::STH';
  }

  sub ping {
    my ($self) = @_;
    $self->_sync_guard('ping');
    return $self->{dead} ? 0 : 1;
  }

  sub disconnect { $_[0]{Active} = 0; $_[0]{disconnected}++; 1 }
  sub do { 1 }   # the session statement of every connection (karr k121)

  sub mysql_fd       { fileno $_[0]{client} }
  sub mariadb_sockfd { fileno $_[0]{client} }
  sub err            { undef }

  sub _readable { syswrite $_[0]{server}, 'R'; return }

  # The server ends the connection: a statement in flight fails, every later
  # one finds the server gone.
  sub kill {
    my ($self) = @_;
    $self->{dead} = 1;
    if (my $sth = $self->{in_flight}) {
      $sth->{result} = { error => "Lost connection to MySQL server during query\n" };
      $self->_readable;
    }
    return;
  }
}

{
  package K67::STH;

  sub execute {
    my ($self, @bind) = @_;
    my $dbh = $self->{dbh};
    die "DBD::mysql::st execute failed: MySQL server has gone away\n" if $dbh->{dead};
    my $r = eval { $main::SERVER->answer($self->{sql}, \@bind, $dbh->{thread_id}) };
    $self->{result}           = $r || { error => $@ };
    $self->{NUM_OF_FIELDS}    = $self->{result}{fields} // 0;
    $self->{mysql_insertid}   = $self->{result}{insertid} // 0;
    $self->{mariadb_insertid} = $self->{mysql_insertid};
    $dbh->{in_flight} = $self;
    Scalar::Util::weaken($dbh->{in_flight});
    $dbh->_readable;
    return '0E0';
  }

  sub _ready {
    my ($self) = @_;
    my $dbh = $self->{dbh};
    my $rin = '';
    vec($rin, fileno $dbh->{client}, 1) = 1;
    return 0 unless select($rin, undef, undef, 0) > 0;
    sysread $dbh->{client}, my $byte, 1;
    return 1;
  }

  sub _result {
    my ($self) = @_;
    my $dbh = $self->{dbh};
    undef $dbh->{in_flight} if $dbh->{in_flight} && $dbh->{in_flight} == $self;
    my $r = $self->{result};
    die "DBD::mysql::st execute failed: $r->{error}" if defined $r->{error};
    return $r->{rv} // '0E0';
  }

  sub mysql_async_ready    { $_[0]->_ready }
  sub mariadb_async_ready  { $_[0]->_ready }
  sub more_results { 0 }   # one result set (karr k73)
  sub mysql_async_result   { $_[0]->_result }
  sub mariadb_async_result { $_[0]->_result }

  sub fetchall_arrayref { [ map { [@$_] } @{ $_[0]{result}{rows} || [] } ] }
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
    # The handle belongs to the DBD the DSN names (karr k60), and DBD::MariaDB
    # refuses an attribute under DBD::mysql's name (measured for karr k59).
    my ($driver) = ($dsn // '') =~ /^dbi:(\w*)/i;
    if ($driver eq 'MariaDB') {
      die "DBI connect failed: Unknown attribute $_\n"
        for sort grep { /^mysql_/ } keys %$attrs;
    }
    my $dbh = K67::DBH->new($driver);
    push @CONNECTS, {
      dsn => $dsn, user => $user, password => $password, attrs => { %$attrs },
      listen => $listen,
    };
    push @HANDLES, $dbh;
    weaken($HANDLES[-1]);
    return $dbh;
  };
}

# --- brokers ------------------------------------------------------------------

# Issues whatever credentials the test sets.
{
  package FakeVaultClient;
  sub new { my ($class, $user, $password) = @_; bless { secret => { username => $user, password => $password } }, $class }
  sub read_secret { return { %{ $_[0]{secret} } } }
}

# Answers whatever the test gives it.
{
  package HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  package K67::MySQLSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

  package K67::MariaDBSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

# Each DBD's own names, spelled out on purpose: the expectation must not be
# derived from the table under test.
my %FLAVOUR = (
  mysql => {
    schema    => 'K67::MySQLSchema',
    sync      => 'DBIO::MySQL::Storage',
    async     => 'DBIO::MySQL::Storage::Async',
    reconnect => 'mysql_auto_reconnect',
    timeout   => 'mysql_connect_timeout',
    multi     => 'mysql_multi_statements',
  },
  MariaDB => {
    schema    => 'K67::MariaDBSchema',
    sync      => 'DBIO::MySQL::Storage::MariaDB',
    async     => 'DBIO::MySQL::Storage::MariaDB::Async',
    reconnect => 'mariadb_auto_reconnect',
    timeout   => 'mariadb_connect_timeout',
    multi     => 'mariadb_multi_statements',
  },
);

my %FORCED = (AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1);

sub vault {
  my ($dbd, $timeout, $user, $password) = @_;
  return DBIO::AccessBroker::Vault->new(
    vault     => FakeVaultClient->new($user, $password),
    dsn       => "dbi:$dbd:database=appdb;host=db.example",
    cred_path => 'database/creds/app',
    dbi_attrs => { $timeout => 7 },
  );
}

# The hooks and the timings every backend of this file runs with.
sub watched {
  my ($async) = @_;
  $async->on_listen_error(sub { push @REPORTS, $_[1] });
  $async->listen_backoff_initial(0.01);
  $async->listen_backoff_max(0.01);
  $async->notify_poll_interval(0.01);
  return $async;
}

# The backend as the schema path builds it: with its owning sync storage, which
# is the one that knows the DBD of connection parameters; then the connect
# info.
sub backend {
  my ($f, @info) = @_;
  my $owner = bless {}, $f->{sync};
  push @OWNERS, $owner;
  my $async = $f->{async}->new(undef);
  $async->_owner_storage($owner);
  $async->connect_info([ @info ]);
  return watched($async);
}

# Every way a broker's answer reaches this transport (t/65, t/67, t/74), each
# with the password the case is given: [ label, builder ]. A builder gets the
# flavour, its DBD and the password, and returns the backend and whatever has
# to stay alive beside it.
my @ATTACHED = (
  [ 'Vault (a DBI-form answer)', sub {
      my ($f, $dbd, $pw) = @_;
      backend($f, vault($dbd, $f->{timeout}, 'vault-user', $pw));
  } ],
  [ 'Static (connection parameters)', sub {
      my ($f, $dbd, $pw) = @_;
      backend($f, DBIO::AccessBroker::Static->new(
        host => 'db.example', dbname => 'appdb', username => 'app', password => $pw,
      ));
  } ],
  [ 'parameters whose dbname is a DSN', sub {
      my ($f, $dbd, $pw) = @_;
      backend($f, HashBroker->new({
        dbname => "dbi:$dbd:database=appdb", user => 'app', password => $pw,
      }));
  } ],
  [ "the transport's own connect info", sub {
      my ($f, $dbd, $pw) = @_;
      backend($f, HashBroker->new({
        dsn => "dbi:$dbd:database=appdb", user => 'app', password => $pw, attrs => {},
      }));
  } ],
  [ 'Vault with connect options beside it', sub {
      my ($f, $dbd, $pw) = @_;
      backend($f, vault($dbd, $f->{timeout}, 'vault-user', $pw), { pool_size => 3, $f->{multi} => 1 });
  } ],
  # The way an application gets there: the schema connected with the mode, the
  # backend embedded in the sync storage.
  [ 'Static, through a schema connected with future_io', sub {
      my ($f, $dbd, $pw) = @_;
      my $schema = $f->{schema}->connect(
        DBIO::AccessBroker::Static->new(
          host => 'db.example', dbname => 'appdb', username => 'app', password => $pw,
        ),
        { async => 'future_io' },
      );
      return (watched($schema->storage->async), $schema);
  } ],
);

# --- helpers --------------------------------------------------------------------

# Run the loop until $cond holds, bounded -- never an open-ended wait.
sub drive {
  my ($cond, $max) = @_;
  my $deadline = Time::HiRes::time() + ($max // 3);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    Future::IO->sleep(0.002)->get;
  }
  return 1;
}

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
  my $died = $@;
  drive(sub { $f->is_ready }) if defined $f;
  my $how = !defined $f   ? "died: $died"
          : !$f->is_ready ? 'still pending'
          : $f->is_failed ? 'failed: ' . ($f->failure)[0]
          :                 'opened';
  return { how => $how, opened => @CONNECTS - $before };
}

sub listen_dbh { $_[0]{_listen} && $_[0]{_listen}{conn} && $_[0]{_listen}{conn}{dbh} }

sub polls_on {
  my ($dbh) = @_;
  return scalar grep { $_->{pid} == $dbh->{thread_id} } $SERVER->statements(qr/\ASELECT `id`, `channel`/);
}

# The watch loop is running once a poll has run on the listen connection.
sub watching {
  my ($async) = @_;
  my $dbh  = listen_dbh($async) or return 0;
  my $seen = polls_on($dbh);
  return drive(sub { polls_on($dbh) > $seen });
}

# Everything that was said since a case last emptied them: the on_listen_error
# reports and the warnings.
sub said { join ' ', @REPORTS, @WARNINGS }

my $OPENED = { how => 'opened', opened => 1 };

# ---------------------------------------------------------------------------
# 0. The refusal is inherited. An override of the seam here would have to
#    refuse by itself -- which is what dbio-postgresql's did not (its k97).
# ---------------------------------------------------------------------------

for my $class (map { $_->{async} } @FLAVOUR{qw( mysql MariaDB )}) {
  is refaddr($class->can('_async_broker_conninfo')),
     refaddr(DBIO::Async::Storage->can('_async_broker_conninfo')),
    "$class: _async_broker_conninfo is dbio-async's, not overridden by this dist";
}

for my $flavour (qw( mysql MariaDB )) {
  my $f   = $FLAVOUR{$flavour};
  my $dbd = $flavour;
  my $NO_BROKER = qr/\Q$f->{async}\E has no AccessBroker attached to ask for connect info/;
  my $AS_ANSWER = qr/AccessBroker \S+ (?:returned|answered)|what the AccessBroker (?:returned|answered)/;

  # What a storage that was never given connect info does with each attempt.
  my $NO_POOL_CONNINFO   = qr/conninfo or conninfo_provider required/;
  my $NO_LISTEN_CONNINFO = qr/MySQL async conninfo must be a hashref with a dsn/;
  for my $control (
    [ 'spawn',       $NO_POOL_CONNINFO ],
    [ 'listen open', $NO_LISTEN_CONNINFO ],
    [ 'listen',      $NO_LISTEN_CONNINFO ],
  ) {
    my ($what, $re) = @$control;
    $SERVER = FakeNotifyServer->new;
    my $async = watched($f->{async}->new(undef));
    my $got = attempt($async, $what);
    like $got->{how}, $re,
      "$flavour, the control: a storage never given connect info, $what: nothing to connect from";
    is $got->{opened}, 0, '... and nothing is opened';
    $async->disconnect;
  }

  # -------------------------------------------------------------------------
  # 1. Nothing is kept from an answer.
  # -------------------------------------------------------------------------

  for my $case (@ATTACHED) {
    my ($case_label, $build) = @$case;
    my $label    = "$flavour, $case_label";
    my $password = 'k67-kept-pw';
    $SERVER = FakeNotifyServer->new;
    my ($async, $keep) = $build->($f, $dbd, $password);

    ok $async->access_broker && $async->_conninfo_provider,
      "$label: the broker is attached, with its provider";
    is $async->{_conninfo}, undef, '... no conninfo is kept from its answer';
    is_deeply [ holding($async, $password) ], [],
      '... its password is nowhere in the storage but in the broker';

    # The controls that give the scan its needle: the password is real, and it
    # does travel through this storage on its way to DBI->connect.
    is_deeply attempt($async, 'spawn'), $OPENED, '... a pool connection is opened';
    is_deeply [ @{ $CONNECTS[-1] }{qw( password listen )} ], [ $password, 0 ],
      '... with the password, from the broker';

    is_deeply attempt($async, 'listen'), $OPENED,
      '... listen() opens the listen connection';
    is_deeply [ @{ $CONNECTS[-1] }{qw( password listen )} ], [ $password, 1 ],
      '... with the password, from the broker, through _listen_open';
    like $CONNECTS[-1]{dsn}, qr/\Adbi:\Q$dbd\E:/, "... on a dbi:$dbd: DSN";

    ok $async->{pool} && listen_dbh($async), '... pool and listen connection now exist';
    ok watching($async), '... and the listen connection is polled';
    is_deeply [ holding($async, $password) ], [],
      '... and still the password is nowhere in the storage, pool and listen state included';

    $async->disconnect;
  }

  # -------------------------------------------------------------------------
  # 2. A broker detached while its provider is still installed.
  # -------------------------------------------------------------------------

  # clear_access_broker is public on DBIO::Storage: it takes the broker away
  # and leaves the provider on the storage. Core's own _clear_access_broker
  # takes the provider too, but a pool built before keeps the one it was built
  # with. With and without connections opened before, both ways:
  for my $case (@ATTACHED) {
    my ($case_label, $build) = @$case;

    for my $detach (qw( clear_access_broker _clear_access_broker )) {
      for my $up (1, 0) {
        my $label = "$flavour, $case_label, $detach, "
                  . ($up ? 'pool and listen connection up' : 'nothing opened yet');
        my $password = 'k67-gone-pw';
        $SERVER = FakeNotifyServer->new;
        my ($async, $keep) = $build->($f, $dbd, $password);

        my $was_listening;
        if ($up) {
          is_deeply [ attempt($async, 'spawn'), attempt($async, 'listen') ], [ ($OPENED) x 2 ],
            "$label: attached, a pool connection and the listen connection are opened";
          is_deeply [ map { $_->{password} } @CONNECTS[-2, -1] ], [ ($password) x 2 ],
            "... with the broker's password";
          $was_listening = listen_dbh($async);
        }

        @REPORTS = @WARNINGS = ();
        $async->$detach;
        ok !$async->access_broker, "$label: the broker is detached";

        my $connects = @CONNECTS;
        my $spawn  = attempt($async, 'spawn');
        my $seam   = attempt($async, 'listen open');
        my $public = attempt($async, $up ? 'listen_reconnect' : 'listen');
        my @how    = map { $_->{how} } $spawn, $seam, $public;

        is $spawn->{opened} + $seam->{opened} + $public->{opened}, 0,
          "$label: nothing reaches DBI->connect -- not for a pool spawn, not for "
          . '_listen_open, not for ' . ($up ? 'listen_reconnect()' : 'listen()');

        if ($detach eq '_clear_access_broker') {
          # The provider is gone from the storage as well: its listen
          # connection has nothing between it and what is stored, and that is
          # nothing.
          like $seam->{how}, $NO_LISTEN_CONNINFO,
            '... _listen_open is where a storage never given connect info is';
          like $public->{how}, qr/\Afailed: .*$NO_LISTEN_CONNINFO/s,
            '... and so is the public call, as a failed Future';

          # A pool built before keeps the provider it was built with.
          like $spawn->{how}, ($up ? $NO_BROKER : $NO_POOL_CONNINFO),
            $up ? '... the pool built before fails its spawn for want of a broker'
                : '... and so is a pool, built only now';
        }
        else {
          like $spawn->{how}, qr/\Afailed: $NO_BROKER/,
            '... the pool spawn fails saying that no broker is attached';
          like $seam->{how}, qr/\Adied: $NO_BROKER/, '... and so does _listen_open';
          like $public->{how}, qr/\Afailed: opening the listen connection failed: $NO_BROKER/,
            '... and the public call, as a failed Future';
          ok scalar(grep { $_ =~ $NO_BROKER } @REPORTS),
            '... which on_listen_error is told as well';

          # The channel stays registered, so core goes on trying, with backoff.
          # Every one of those attempts is the same open.
          my $told = grep { $_ =~ $NO_BROKER } @REPORTS;
          ok drive(sub { (grep { $_ =~ $NO_BROKER } @REPORTS) >= $told + 3 }),
            '... core retries the open with backoff, and each retry is refused the same way';
          is scalar(@CONNECTS), $connects, '... none of them reaching DBI->connect';
        }

        if ($up) {
          ok $was_listening->{disconnected},
            '... the listen connection that was up is closed by the rebuild';
          ok !$async->listen_alive, '... and none has taken its place';
        }

        unlike join(' ', @how, said()), qr/\Q$password\E/,
          '... no error, on_listen_error report or warning names the password of the earlier answer';
        is_deeply [ holding($async, $password) ], [],
          '... which is nowhere in the storage either';
        unlike join(' ', @how, said()), $AS_ANSWER,
          '... and nothing is reported as the answer of a broker: there is none';

        $async->disconnect;
      }
    }
  }

  # -------------------------------------------------------------------------
  # 2b. The listen connection dies after its broker was detached: core heals
  #     it by itself, nobody calls anything. That open is refused as well.
  # -------------------------------------------------------------------------

  {
    my $password = 'k67-healed-pw';
    $SERVER = FakeNotifyServer->new;
    my $async = backend($f, vault($dbd, $f->{timeout}, 'vault-user', $password));

    is_deeply attempt($async, 'listen'), $OPENED, "$flavour, healing: the listen connection is up";
    my $dbh = listen_dbh($async);
    ok watching($async), '... and polled';

    @REPORTS = @WARNINGS = ();
    $async->clear_access_broker;
    my $connects = @CONNECTS;

    $dbh->kill;
    ok drive(sub { (grep { $_ =~ $NO_BROKER } @REPORTS) >= 3 }),
      "$flavour, healing: with the broker detached and the listen connection dead, "
      . 'on_listen_error hears that no broker is attached -- at every retry';
    like $REPORTS[0], qr/Lost connection to MySQL server|gone away/,
      '... after hearing why the connection was lost';
    ok $dbh->{disconnected}, '... the dead connection is closed';
    is scalar(@CONNECTS), $connects, '... and none is opened in its place';
    ok !$async->listen_alive, '... listen_alive says so';
    unlike said(), qr/\Q$password\E/, '... no report or warning names the password';
    is_deeply [ holding($async, $password) ], [], '... which is nowhere in the storage';

    $async->disconnect;
  }

  # -------------------------------------------------------------------------
  # 3. Broker -> static -> broker: each change leaves only what belongs to the
  #    new connect info, for the listen connection as for the pool.
  # -------------------------------------------------------------------------

  {
    $SERVER = FakeNotifyServer->new;
    my $vault = vault($dbd, $f->{timeout}, 'vault-user-1', 'first-broker-pw');
    my $async = backend($f, $vault);
    my %listen_attrs = (%FORCED, $f->{reconnect} => 0);
    my %broker_1 = (
      dsn => "dbi:$dbd:database=appdb;host=db.example", user => 'vault-user-1',
      password => 'first-broker-pw', attrs => { $f->{timeout} => 7, %listen_attrs },
    );

    is_deeply attempt($async, 'listen'), $OPENED,
      "$flavour, a broker first: listen() opens the listen connection";
    is_deeply $CONNECTS[-1], { %broker_1, listen => 1 }, '... from the broker';
    my $first_listen = listen_dbh($async);

    # --- the broker rotates its credentials ---
    $vault->vault->{secret} = { username => 'vault-user-2', password => 'rotated-broker-pw' };
    $vault->_expires_at(0);
    is_deeply attempt($async, 'listen_reconnect'), $OPENED,
      '... its credentials rotated: listen_reconnect() opens a new listen connection';
    is_deeply $CONNECTS[-1],
      { %broker_1, user => 'vault-user-2', password => 'rotated-broker-pw', listen => 1 },
      '... with the rotated credentials';
    ok $first_listen->{disconnected}, '... closing the one opened with the earlier ones';
    is_deeply [ map { holding($async, $_) } qw( first-broker-pw rotated-broker-pw ) ], [],
      '... and neither password is kept in the storage';
    my $broker_listen = listen_dbh($async);

    # --- to static ---
    my %static = (
      dsn => "dbi:$dbd:database=staticdb;host=static.example", user => 'static-user',
      password => 'static-pw', attrs => { $f->{timeout} => 9 },
    );
    $async->connect_info([ @static{qw( dsn user password attrs )} ]);

    ok !$async->access_broker && !$async->_conninfo_provider,
      "$flavour, then static connect info: the broker and its provider are gone";
    ok $broker_listen->{disconnected} && !$async->{_listen},
      '... the listen connection of the broker is closed, and nothing is listened to';
    is_deeply [ map { holding($async, $_) } qw( first-broker-pw rotated-broker-pw vault-user ) ], [],
      "... and nothing is left of the broker's answers";

    my %static_connect = (%static, attrs => { $f->{timeout} => 9, %listen_attrs });
    is_deeply attempt($async, 'listen'), $OPENED, '... listen() opens a listen connection';
    is_deeply $CONNECTS[-1], { %static_connect, listen => 1 }, '... from the static conninfo';
    my $static_listen = listen_dbh($async);
    isnt refaddr($static_listen), refaddr($broker_listen), '... a new one';
    is_deeply attempt($async, 'spawn'), $OPENED, '... and a pool connection is opened';
    is_deeply $CONNECTS[-1], { %static_connect, listen => 0 }, '... from the static conninfo too';

    # --- back to a broker ---
    my $second = HashBroker->new({
      dbname => "dbi:$dbd:database=seconddb", user => 'app', password => 'second-broker-pw',
    });
    $async->connect_info([ $second ]);

    ok $async->access_broker && $async->_conninfo_provider,
      "$flavour, then a broker again: it is attached, with its provider";
    is $async->{_conninfo}, undef,
      '... no conninfo is stored: neither its answer nor the static one before it';
    ok $static_listen->{disconnected} && !$async->{_listen},
      '... the listen connection of the static conninfo is closed';
    is_deeply [ map { holding($async, $_) } qw( static-pw static-user staticdb static.example ) ], [],
      '... nothing of the static connect info is left in the storage';

    my %broker_2 = (
      dsn => "dbi:$dbd:database=seconddb", user => 'app', password => 'second-broker-pw',
      attrs => { %listen_attrs },
    );
    is_deeply attempt($async, 'listen'), $OPENED, '... listen() opens a listen connection';
    is_deeply $CONNECTS[-1], { %broker_2, listen => 1 },
      '... from the second broker, and from nothing else';
    is_deeply attempt($async, 'spawn'), $OPENED, '... and a pool connection is opened';
    is_deeply $CONNECTS[-1], { %broker_2, listen => 0 }, '... from the second broker too';
    is_deeply [ map { holding($async, $_) } qw( static-pw second-broker-pw ) ], [],
      '... and neither password is in the storage, pool and listen state included';

    # --- that broker rotates, and the listen connection dies ---
    my $second_listen = listen_dbh($async);
    ok watching($async), '... the listen connection is polled';
    $second->{answer} = { %{ $second->{answer} }, password => 'second-rotated-pw' };
    my $connects = @CONNECTS;
    $second_listen->kill;
    ok drive(sub { @CONNECTS > $connects && listen_dbh($async) && $async->listen_alive }),
      '... its credentials rotated and its listen connection dead: core heals it';
    is_deeply $CONNECTS[-1], { %broker_2, password => 'second-rotated-pw', listen => 1 },
      '... with the credentials the broker answers now';

    # --- that broker taken away ---
    @REPORTS = @WARNINGS = ();
    $async->clear_access_broker;
    for my $what ('listen_reconnect', 'listen open', 'spawn') {
      my $got = attempt($async, $what);
      like $got->{how}, $NO_BROKER,
        "$flavour, with that broker detached, $what fails for want of a broker";
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
          "$flavour, even with a conninfo stored in the broker's place, $what fails for want of a broker";
        is $got->{opened}, 0, '... and does not connect from it';
      }
    }

    unlike said(), qr/static-pw|broker-pw|rotated-pw/,
      '... and no on_listen_error report or warning names a password';
    $async->disconnect;
  }
}

# Every refusal above went through a Future or on_listen_error. The handler of
# this file swallowed nothing on the way.
is_deeply \@WARNED, [], 'nothing warned along the way';

done_testing;
