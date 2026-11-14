# ABSTRACT: On an async storage a broker comes and goes in one place, and with it everything a connect_info left
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed reftype refaddr);

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker;
use DBIO::Test::Future ();

# OFFLINE (karr k273 point 2, k283, k293 -- one cause). What a connect_info
# leaves on an async storage is spread over several slots: the broker and its
# mode, the per-spawn provider, the stored conninfo, the pool size, the
# options, the connect options given beside a broker -- and, for a backend
# embedded in a sync storage, the broker of that storage. They did not change
# together. Every road that changed one left others standing:
#
#   * a connect_info that threw -- the broker, its answer, two pool sizes that
#     disagree -- had dropped the conninfo of the call before (k265) and left
#     its pool size, its options and what stood beside its broker, next to the
#     newly attached broker (k283); one that threw before it reached a broker
#     -- the driver's reshape seam, options a transport does not take, static
#     connect info of no usable shape -- left the call before in place as a
#     whole, and the next pool connection was opened from it;
#   * set_access_broker called directly set the broker slot only: no provider,
#     and a transport went on building its pool from the static conninfo;
#   * clear_access_broker left the provider, which then handed a transport
#     that did not refuse by itself no conninfo at all (k273), and left the
#     pool size, options and beside-options of the broker's connect info;
#   * clear_access_broker on the SYNC storage did not reach its embedded
#     backend, which went on asking the broker for pool and listen
#     connections, and a backend built only afterwards attached the detached
#     broker again (k293); a sync connect_info that threw left the backend of
#     the connect info before in place, asking the broker it replaced.
#
# What this file claims:
#   1. a connect_info that throws leaves nothing of the connect_info before
#      (ADR 0050): not in a slot, not anywhere in the storage. Thrown after
#      the new broker is attached, that broker is attached in full -- with
#      what stood beside it, so a connection opened afterwards is not opened
#      without it. Thrown before, the storage is where one never given
#      connect info is;
#   2. a connect_info that completes leaves only its own (control);
#   3. set_access_broker is the one place a broker is attached:
#      _setup_access_broker leaves the same state, a broker attached directly
#      is attached in full -- provider installed, nothing of the static
#      connect info left, the next pool connection opened from the broker --
#      and what is no broker is refused before anything changes;
#   4. clear_access_broker is the one place a broker is detached, under
#      either name: broker, mode, pool size, options and beside-options go.
#      Nothing is opened afterwards -- not by a pool built before, not by one
#      built now, not for a listen connection -- and the broker is not asked.
#      The provider refuses, saying that no broker is attached; after
#      _clear_access_broker, which forgets the provider too, a storage with no
#      pool is where one never given connect info is. Open connections stay;
#   5. disconnect is no detach (control);
#   6. clear_access_broker on a sync storage takes its embedded backend along:
#      the backend built before is detached as in 4, with its connections left
#      open; one not built yet is not built from the detached broker -- the
#      call throws, and the broker is not asked. A storage without a broker,
#      and its backend, are not touched. Connect info given again is taken;
#   7. a sync connect_info that throws lets go of the backend of the connect
#      info before: the next async use does not go through the replaced broker.
#
# NOT claimed here: what a pool that is already built does when a broker is
# attached to its storage directly (it keeps what it was built with; a
# connect_info shuts it down first). And whether the detach on the sync
# storage should also shut the backend's pool down: it does not.
#
# THE SUBSTITUTIONS: a pool that records every connection it builds instead of
# connecting; a transport running core's own connect_info that does NOT refuse
# a missing broker by itself -- it builds each conninfo from what core answers
# -- and whose listen seam opens from the provider, as the family's do.

# A broker answering from a script: one code per call, the last one repeating.
{
  package T::ScriptBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, @answers) = @_; bless { answers => \@answers, calls => 0 }, $class }
  sub connect_info_for {
    my $self = shift;
    my $i = $self->{calls}++;
    $i = $#{ $self->{answers} } if $i > $#{ $self->{answers} };
    return $self->{answers}[$i]->();
  }
}

{
  package T::RecordingPool;
  use base 'DBIO::Storage::PoolBase';
  our @BUILT;
  sub _create_connection { my ($self, $conninfo) = @_; push @BUILT, $conninfo; bless { conninfo => $conninfo }, 'T::Conn' }
  sub _transform_conninfo { $_[1] }
}

{
  package T::Backend;
  use base 'DBIO::Storage::Async';
  our @LISTEN;
  sub future_class { 'DBIO::Test::Future' }

  # What core answers, and what stands beside the broker joined in. No look
  # for a broker: that is the refusal this file wants from core.
  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    my ($conninfo) = $self->_normalize_async_connect_info($self->_current_async_connect_info($mode));
    my %beside = %{ $self->_access_broker_call_attributes };
    return %beside ? { %{ $conninfo || {} }, beside => \%beside } : $conninfo;
  }

  sub pool {
    my $self = shift;
    $self->{pool} ||= T::RecordingPool->new(
      size         => $self->{_pool_size},
      future_class => $self->future_class,
      ($self->_conninfo_provider
        ? (conninfo_provider => $self->_conninfo_provider)
        : (conninfo          => $self->{_conninfo})),
    );
  }

  sub _listen_open {
    my ($self) = @_;
    my $provider = $self->_conninfo_provider;
    my $conninfo = $provider ? $provider->() : $self->{_conninfo};
    push @LISTEN, $conninfo;
    return $self->future_class->done({ conninfo => $conninfo });
  }
}

# The same transport, taking the connect options beside a broker.
{
  package T::OptionsBackend;
  our @ISA = ('T::Backend');
  sub transport_capabilities { 'broker_connect_options' }
}

# The same transport, with a reshape seam that cannot read everything.
{
  package T::PickyBackend;
  our @ISA = ('T::Backend');
  sub _normalize_conninfo {
    my ($self, $info) = @_;
    die "k283 the driver cannot read this\n"
      if ref $info eq 'ARRAY' && ref $info->[0] eq 'HASH' && $info->[0]{unreadable};
    return $info;
  }
}

# The sync storage of a driver, with the transport above as its async mode.
# Twice: a driver storage class that does not declare the c3 method resolution
# order -- as DBIO::PostgreSQL::Storage and DBIO::MySQL::Storage do not -- and
# one that does. Depth-first, DBIO::Storage is found before the mixin that
# holds the DBI storage's own detach.
{
  package T::FakeDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeK293 => __PACKAGE__);
}
{
  package T::C3Driver::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(FakeK293c => __PACKAGE__);
}
$_->register_async_mode(k293 => 'T::Backend') for qw( T::FakeDriver::Storage T::C3Driver::Storage );

{ package T::NotABroker; sub new { bless {}, shift } }

# a value matching $re anywhere in the structure, broker objects not looked into
sub holds {
  my ($x, $re, $seen) = @_;
  $seen ||= {};
  return 0 unless defined $x;
  return $x =~ $re ? 1 : 0 unless ref $x;
  return 0 if blessed($x) && $x->isa('DBIO::AccessBroker');
  return 0 if $seen->{ refaddr $x }++;
  my $type = reftype $x;
  my @inside = $type eq 'HASH'                      ? %$x
             : $type eq 'ARRAY'                     ? @$x
             : $type eq 'SCALAR' || $type eq 'REF'  ? $$x
             :                                        ();
  return scalar grep { holds($_, $re, $seen) } @inside;
}

sub failure_of { my ($f) = @_; return $f->is_failed ? "$f->{values}[0]" : '' }

# One pool connection, opened now: the conninfo it was built from, and how the
# attempt ended -- the pool refusing to be built, or acquire's Future failing.
sub spawn {
  my $storage = shift;
  local @T::RecordingPool::BUILT;
  my $f = eval { $storage->pool->acquire };
  my $refused = $f ? '' : "$@";
  return {
    refused => $refused,
    failed  => ($f ? failure_of($f) : ''),
    built   => [ @T::RecordingPool::BUILT ],
  };
}

sub opened_from { my ($conninfo) = @_; return { refused => '', failed => '', built => [ $conninfo ] } }

# The listen connection, opened now through the transport's seam.
sub listen_open {
  my $storage = shift;
  local @T::Backend::LISTEN;
  my $ok = eval { $storage->_listen_open; 1 };
  return { refused => ($ok ? '' : "$@"), opened => [ @T::Backend::LISTEN ] };
}

# Every slot a connect_info sets. The broker by identity.
sub slots {
  my $storage = shift;
  return {
    broker       => $storage->access_broker,
    mode         => $storage->access_broker_mode,
    provider     => ($storage->_conninfo_provider ? 'installed' : 'none'),
    conninfo     => $storage->{_conninfo},
    pool_size    => $storage->{_pool_size},
    opts         => $storage->{_opts},
    beside       => $storage->_access_broker_call_attributes,
    connect_info => scalar $storage->connect_info,
  };
}

my %NOTHING = (
  broker => undef, mode => undef, provider => 'none', conninfo => undef,
  pool_size => undef, opts => undef, beside => {}, connect_info => undef,
);
is_deeply slots(T::Backend->new(undef)), \%NOTHING,
  'a storage never given connect info has nothing in any slot';

my $UNCONFIGURED = spawn(T::Backend->new(undef));
like $UNCONFIGURED->{refused}, qr/conninfo or conninfo_provider required/,
  '... its pool refuses to be built';
my $UNCONFIGURED_LISTEN = listen_open(T::Backend->new(undef));

my $NO_BROKER = qr/^T::\w+ has no AccessBroker attached to ask for connect info/;

# The connect info BEFORE: every value of it carries this mark, and its pool
# size is one no default gives.
my $OLD = qr/k283-old/;
my %OLD_CONNINFO = (dbname => 'k283-old-db', user => 'k283-old-user', password => 'k283-old-pw');

# [ label, transport class or undef for any, sub ($storage) configuring it and
#   returning the broker it attached, if any ]
my @BEFORE = (
  [ 'static connect info before', undef, sub {
      $_[0]->connect_info([ { %OLD_CONNINFO, pool_size => 7 }, { old => 'k283-old-opt' } ]);
      return;
    } ],
  [ 'a broker before', undef, sub {
      my $broker = T::ScriptBroker->new(sub { [ { %OLD_CONNINFO, pool_size => 7 }, { old => 'k283-old-opt' } ] });
      $_[0]->connect_info([ $broker ]);
      return $broker;
    } ],
  [ 'a broker with options beside it before', 'T::OptionsBackend', sub {
      my $broker = T::ScriptBroker->new(sub { +{ %OLD_CONNINFO } });
      $_[0]->connect_info([ $broker, { pool_size => 7, private_old => 'k283-old-attr' } ]);
      return $broker;
    } ],
);

# (control) what BEFORE leaves is found by what the claims below look at
for my $before (@BEFORE) {
  my ($label, $class, $configure) = @$before;
  my $storage = ($class || 'T::Backend')->new(undef);
  $configure->($storage);
  is $storage->{_pool_size}, 7, "$label: its pool size is stored";
  ok holds($storage, $OLD), '... and the scanner finds its values in the storage';
}

# ---------------------------------------------------------------------------
# 1a. connect_info throws after the new broker is attached.
# ---------------------------------------------------------------------------
my %NEW_ANSWER = (dbname => 'app', user => 'k283-new-user', password => 'k283-new-pw');

# [ label, transport, the connect info, the error, what stands beside the
#   broker in this call, what a pool connection is built from afterwards --
#   none, where the broker's answer is the trouble ]
my @THROWS_ATTACHED = (
  [ 'the broker throws', 'T::Backend',
    sub { [ T::ScriptBroker->new(sub { die "k283 vault unreachable\n" }) ] },
    qr/^k283 vault unreachable/, {} ],
  [ 'the broker answers nothing', 'T::Backend',
    sub { [ T::ScriptBroker->new(sub { undef }) ] },
    qr/AccessBroker T::ScriptBroker answered no connect info \(undef\)/, {} ],
  [ 'the broker answers a plain string', 'T::Backend',
    sub { [ T::ScriptBroker->new(sub { 'dbi:Fake:dbname=app;password=k283-new-pw' }) ] },
    qr/answered connect info an async storage cannot connect from \(a plain scalar\)/, {} ],
  [ 'two pool sizes disagree', 'T::OptionsBackend',
    sub { [ T::ScriptBroker->new(sub { +{ %NEW_ANSWER, pool_size => 2 } }),
            { pool_size => 3, private_new => 'beside-the-new-broker' } ] },
    qr/Connection setting 'pool_size' is given both beside the AccessBroker and in the broker's answer/,
    { private_new => 'beside-the-new-broker' },
    { %NEW_ANSWER, beside => { private_new => 'beside-the-new-broker' } } ],
);

for my $before (@BEFORE) {
  my ($before_label, $before_class, $configure) = @$before;

  for my $case (@THROWS_ATTACHED) {
    my ($label, $class, $new_info, $error, $beside, $from_broker) = @$case;
    next if $before_class && $before_class ne $class;
    my $t = "$before_label, then $label";

    my $storage = $class->new(undef);
    my $old_broker = $configure->($storage);
    my $old_calls  = $old_broker ? $old_broker->{calls} : 0;

    my $info = $new_info->();
    throws_ok { $storage->connect_info($info) } $error, "$t: connect_info throws";
    unlike "$@", $OLD, "$t: ... naming no value of the connect info before";
    unlike "$@", qr/k283-new-pw/, "$t: ... nor the password of the new one";

    is_deeply slots($storage), {
      broker => $info->[0], mode => 'write', provider => 'installed',
      conninfo => undef, pool_size => undef, opts => undef,
      beside => $beside, connect_info => $storage->connect_info,
    }, "$t: the new broker is attached in full, and no slot holds anything of the call before";
    is $storage->connect_info->[0], $info->[0], "$t: ... the connect info stored is this call's";
    ok !holds($storage, $OLD), "$t: ... and nothing of the call before is anywhere in the storage";

    my $attempt = spawn($storage);
    if ($from_broker) {
      is_deeply $attempt, opened_from($from_broker),
        "$t: a pool connection is opened from the new broker, with what stands beside it";
    }
    else {
      isnt $attempt->{failed}, '', "$t: a pool connection asks the new broker, and fails with it";
      is_deeply $attempt->{built}, [], "$t: ... none is built";
    }
    ok !holds($attempt, $OLD), "$t: ... nothing of the call before is in it";
    is $old_broker->{calls}, $old_calls, "$t: ... and the broker before was not asked again"
      if $old_broker;
  }
}

# ---------------------------------------------------------------------------
# 1b. connect_info throws before it reaches a broker, or with static info.
# ---------------------------------------------------------------------------
my @THROWS_EARLY = (
  [ 'options beside a broker the transport does not take', 'T::Backend',
    sub { [ T::ScriptBroker->new(sub { +{ %NEW_ANSWER } }), { pool_size => 3 } ] },
    qr/does not take connection settings beside an AccessBroker/ ],
  [ 'the driver\'s reshape seam dies', 'T::PickyBackend',
    sub { [ { unreadable => 1, password => 'k283-new-pw' } ] },
    qr/^k283 the driver cannot read this/ ],
  [ 'static connect info of no usable shape', 'T::Backend',
    sub { 'dbi:Fake:dbname=app;password=k283-new-pw' },
    qr/An async storage cannot connect from this connect info \(a plain scalar\)/ ],
);

for my $before (@BEFORE) {
  my ($before_label, $before_class, $configure) = @$before;
  next if $before_class;

  for my $case (@THROWS_EARLY) {
    my ($label, $class, $new_info, $error) = @$case;
    my $t = "$before_label, then $label";

    my $storage = $class->new(undef);
    my $old_broker = $configure->($storage);
    my $old_calls  = $old_broker ? $old_broker->{calls} : 0;

    throws_ok { $storage->connect_info($new_info->()) } $error, "$t: connect_info throws";
    unlike "$@", $OLD, "$t: ... naming no value of the connect info before";
    unlike "$@", qr/k283-new-pw/, "$t: ... nor the password of the new one";

    my $slots  = slots($storage);
    my $stored = delete $slots->{connect_info};
    my %nothing = %NOTHING;
    delete $nothing{connect_info};
    is_deeply $slots, \%nothing,
      "$t: every slot is where a storage never given connect info has it";
    ok !holds($stored, $OLD), "$t: ... the connect info stored is not the one before";
    ok !holds($storage, $OLD), "$t: ... and nothing of the call before is anywhere in the storage";

    is_deeply spawn($storage), $UNCONFIGURED,
      "$t: no pool connection is opened -- not from the call before";
    is $old_broker->{calls}, $old_calls, "$t: ... and the broker before is not asked"
      if $old_broker;
  }
}

# ---------------------------------------------------------------------------
# 2. Control: a connect_info that completes leaves only its own.
# ---------------------------------------------------------------------------
for my $before (@BEFORE) {
  my ($before_label, $before_class, $configure) = @$before;

  {
    my $storage = ($before_class || 'T::Backend')->new(undef);
    $configure->($storage);
    my $broker = T::ScriptBroker->new(sub { +{ %NEW_ANSWER } });
    $storage->connect_info([ $broker ]);
    is_deeply slots($storage), {
      broker => $broker, mode => 'write', provider => 'installed', conninfo => undef,
      pool_size => 5, opts => {}, beside => {}, connect_info => [ $broker ],
    }, "$before_label, then a broker that answers: its slots, the default pool size";
    ok !holds($storage, $OLD), '... and nothing of the call before';
    is_deeply spawn($storage), opened_from({ %NEW_ANSWER }), '... a pool connection is opened from it';
  }

  {
    my $storage = ($before_class || 'T::Backend')->new(undef);
    $configure->($storage);
    $storage->connect_info([ { %NEW_ANSWER }, { new => 'opt' } ]);
    is_deeply slots($storage), {
      broker => undef, mode => undef, provider => 'none', conninfo => { %NEW_ANSWER },
      pool_size => 5, opts => { new => 'opt' }, beside => {},
      connect_info => [ { %NEW_ANSWER }, { new => 'opt' } ],
    }, "$before_label, then static connect info: its slots, no broker, no provider";
    ok !holds($storage, $OLD), '... and nothing of the call before';
    is_deeply spawn($storage), opened_from({ %NEW_ANSWER }), '... a pool connection is opened from it';
  }
}

# ---------------------------------------------------------------------------
# 3. set_access_broker is the one place a broker is attached.
# ---------------------------------------------------------------------------
{
  my $broker = T::ScriptBroker->new(sub { +{ %NEW_ANSWER } });
  my %attached = (
    broker => $broker, mode => 'write', provider => 'installed',
    conninfo => undef, pool_size => undef, opts => undef, beside => {},
  );

  for my $how (qw( set_access_broker _setup_access_broker )) {
    my $storage = T::Backend->new(undef);
    $storage->connect_info([ { %OLD_CONNINFO, pool_size => 7 }, { old => 'k283-old-opt' } ]);
    my $stored = $storage->connect_info;

    is $storage->$how($broker), $storage, "$how on a statically configured storage returns the storage";
    is_deeply slots($storage), { %attached, connect_info => $stored },
      "$how: the broker is attached in full -- provider installed, no static conninfo, "
      . 'no pool size or options of the static connect info';
    is_deeply spawn($storage), opened_from({ %NEW_ANSWER }),
      "$how: a pool connection is opened from the broker, not from the static conninfo";
  }

  my $storage = T::Backend->new(undef);
  $storage->set_access_broker($broker, 'read');
  is_deeply slots($storage), { %attached, mode => 'read', connect_info => undef },
    'set_access_broker on a storage never given connect info, with a mode: attached in full';
  is_deeply spawn($storage), opened_from({ %NEW_ANSWER }), '... a pool connection is opened from the broker';
}

for my $not_a_broker ('a-string', T::NotABroker->new) {
  my $what = ref $not_a_broker ? 'an object that is no broker' : 'a plain string';
  my $storage = T::Backend->new(undef);
  $storage->connect_info([ { %OLD_CONNINFO, pool_size => 7 }, { old => 'k283-old-opt' } ]);
  my $before = slots($storage);

  throws_ok { $storage->set_access_broker($not_a_broker) } qr/set_access_broker\(\) requires a/,
    "set_access_broker with $what throws";
  is_deeply slots($storage), $before, '... and changed nothing';
  is_deeply spawn($storage), opened_from({ %OLD_CONNINFO }),
    '... the storage still connects from its static conninfo';
}

# ---------------------------------------------------------------------------
# 4. clear_access_broker is the one place a broker is detached.
# ---------------------------------------------------------------------------
for my $detach (qw( clear_access_broker _clear_access_broker )) {
  for my $pooled (0, 1) {
    my $t = "$detach, " . ($pooled ? 'a pool with a connection' : 'no pool yet');

    my %answer  = (dbname => 'app', user => 'k273-broker-user', password => 'k273-broker-pw');
    my $broker  = T::ScriptBroker->new(sub { +{ %answer } });
    my $storage = T::OptionsBackend->new(undef);
    $storage->connect_info([ $broker, { pool_size => 3, private_attr => 'k273-beside' } ]);
    my $stored  = $storage->connect_info;
    my %from_broker = (%answer, beside => { private_attr => 'k273-beside' });

    my $pool;
    if ($pooled) {
      is_deeply spawn($storage), opened_from({ %from_broker }),
        "$t: attached, a pool connection is opened from the broker";
      is_deeply listen_open($storage), { refused => '', opened => [ { %from_broker } ] },
        '... and so is the listen connection';
      $pool = $storage->{pool};
    }
    my $calls = $broker->{calls};

    $storage->$detach;

    is_deeply slots($storage), {
      broker => undef, mode => undef, conninfo => undef, pool_size => undef,
      opts => undef, beside => {}, connect_info => $stored,
      provider => ($detach eq 'clear_access_broker' ? 'installed' : 'none'),
    }, "$t: broker, mode, pool size, options and what stood beside the broker are gone";

    my $attempt = spawn($storage);
    my $listen  = listen_open($storage);

    if ($detach eq '_clear_access_broker' && !$pooled) {
      is_deeply $attempt, $UNCONFIGURED,
        "$t: the storage is where one never given connect info is -- no pool, no connection";
    }
    else {
      is $attempt->{refused}, '', "$t: acquire does not throw";
      like $attempt->{failed}, $NO_BROKER, "$t: its Future fails, saying that no broker is attached";
      is_deeply $attempt->{built}, [], "$t: ... and no connection is built";
    }

    if ($detach eq '_clear_access_broker') {
      is_deeply $listen, $UNCONFIGURED_LISTEN,
        "$t: the listen seam has what it has on a storage never given connect info";
    }
    else {
      like $listen->{refused}, $NO_BROKER, "$t: a listen open is refused, saying that no broker is attached";
      is_deeply $listen->{opened}, [], "$t: ... and opens nothing";
    }

    is $broker->{calls}, $calls, "$t: the detached broker is not asked";
    unlike join(' ', map { $_ // '' } @{$attempt}{qw( refused failed )}, $listen->{refused}),
      qr/k273-broker|k273-beside/, "$t: no message names a value of the broker's answer or of what stood beside it";
    ok !holds([ $attempt, $listen ], qr/k273-broker|k273-beside/),
      "$t: ... and nothing is opened from either";

    if ($pooled) {
      ok !$pool->{_shutdown} && $pool->size == 1,
        "$t: the pool built before is not shut down, and its connection stays";

      # A broker attached again is the one the pool built before asks.
      my $next = T::ScriptBroker->new(sub { +{ dbname => 'next', user => 'next-user' } });
      $storage->set_access_broker($next);
      is_deeply spawn($storage), opened_from({ dbname => 'next', user => 'next-user' }),
        "$t: with another broker attached, that pool opens its next connection from it";
    }
  }
}

# A storage with no broker attached is not touched, under the public name.
{
  my $storage = T::Backend->new(undef);
  $storage->connect_info([ { %OLD_CONNINFO, pool_size => 7 }, { old => 'k283-old-opt' } ]);
  my $before = slots($storage);

  $storage->clear_access_broker;
  is_deeply slots($storage), $before,
    'clear_access_broker on a statically configured storage changes nothing';
  my $attempt = spawn($storage);
  is_deeply $attempt, opened_from({ %OLD_CONNINFO }), '... it still connects from its static conninfo';
  is $storage->{pool}->max_size, 7, '... with the pool size it was given';
}

# ---------------------------------------------------------------------------
# 5. Control: disconnect is no detach.
# ---------------------------------------------------------------------------
{
  my $broker  = T::ScriptBroker->new(sub { +{ %NEW_ANSWER } });
  my $storage = T::Backend->new(undef);
  $storage->connect_info([ $broker ]);
  is_deeply spawn($storage), opened_from({ %NEW_ANSWER }), 'a broker attached: a pool connection is opened';
  my $before = slots($storage);
  my $pool   = $storage->{pool};

  $storage->disconnect;
  ok $pool->{_shutdown} && !$storage->{pool}, 'disconnect shuts the pool down and drops it';
  is_deeply slots($storage), $before, '... and leaves every slot as it was: the broker stays attached';
  is_deeply spawn($storage), opened_from({ %NEW_ANSWER }),
    '... the next pool connection is opened from the broker again';
}

# ---------------------------------------------------------------------------
# 6. clear_access_broker on a sync storage takes its embedded backend along.
# ---------------------------------------------------------------------------
my %K293 = (dbname => 'app', user => 'k293-user', password => 'k293-pw');

sub owner_of {
  my ($class, @connect_info) = @_;
  my $schema = DBIO::Test->init_schema(
    no_connect   => 1,
    storage_type => "+$class",
  );
  $schema->connection(@connect_info);
  return ($schema, $schema->storage);
}
sub owner { owner_of('T::FakeDriver::Storage', @_) }

is_deeply [ map { mro::get_mro($_) } qw( T::FakeDriver::Storage T::C3Driver::Storage ) ], [qw( dfs c3 )],
  'the two driver storage classes: one depth-first, one c3';

for my $class (qw( T::FakeDriver::Storage T::C3Driver::Storage )) {
  my $broker = T::ScriptBroker->new(sub { +{ %K293 } });
  my ($schema, $storage) = owner_of($class, $broker, { async => 'k293' });
  # karr k266 replaced "the storage holds the DBI connect info of its answer"
  is $storage->{_dbi_connect_info}, undef,
    "$class: with the broker attached, the storage holds no DBI connect info of its answer";
  my $async = $storage->async;
  isa_ok $async, 'T::Backend', 'a sync storage with a broker and an async mode: its backend';
  is $async->access_broker, $broker, '... has the broker attached';
  is_deeply spawn($async), opened_from({ %K293 }), '... and opens a pool connection from it';
  is_deeply listen_open($async), { refused => '', opened => [ { %K293 } ] }, '... and the listen connection';
  my $pool  = $async->{pool};
  my $calls = $broker->{calls};

  $storage->clear_access_broker;
  ok !$storage->access_broker, 'clear_access_broker on the sync storage detaches the broker';
  is $storage->{_dbi_connect_info}, undef,
    '... and no DBI connect info of its answer is stored, '
    . 'whatever the method resolution order of the driver class';
  ok !$async->access_broker, '... and detaches it from the embedded backend built before';
  is $storage->async, $async, '... which stays the storage\'s backend';

  my $attempt = spawn($async);
  is $attempt->{refused}, '', 'the backend\'s next pool connection: acquire does not throw';
  like $attempt->{failed}, $NO_BROKER, '... its Future fails, saying that no broker is attached';
  is_deeply $attempt->{built}, [], '... and no connection is built';
  my $listen = listen_open($async);
  like $listen->{refused}, $NO_BROKER, '... a listen open is refused the same way';
  is_deeply $listen->{opened}, [], '... and opens nothing';
  is $broker->{calls}, $calls, '... the detached broker is not asked again';
  unlike "$attempt->{failed} $listen->{refused}", qr/k293-(?:user|pw)/,
    '... and no message names a value of its answer';
  ok !$pool->{_shutdown} && $pool->size == 1,
    '... the backend\'s pool is not shut down, and its open connection stays';

  # Connect info given again is taken.
  my $next = T::ScriptBroker->new(sub { +{ dbname => 'next', user => 'next-user' } });
  $storage->connect_info([ $next, { async => 'k293' } ]);
  my $rebuilt = $storage->async;
  isnt refaddr($rebuilt), refaddr($async), 'connect info given again: the storage gets a new backend';
  is_deeply spawn($rebuilt), opened_from({ dbname => 'next', user => 'next-user' }),
    '... which opens its connections from the new broker';
}

{
  my $broker = T::ScriptBroker->new(sub { +{ %K293 } });
  my ($schema, $storage) = owner($broker, { async => 'k293' });
  my $calls = $broker->{calls};

  $storage->clear_access_broker;
  throws_ok { $storage->async }
    qr/async mode 'k293': the AccessBroker this storage was connected through has been detached/,
    'detached before a backend was built: the first async use throws, saying why';
  unlike "$@", qr/k293-(?:user|pw)/, '... naming no value of the broker\'s answer';
  ok !$storage->{_async_storage_obj}, '... no backend is built';
  is $broker->{calls}, $calls, '... and the detached broker is not asked';
  throws_ok { $storage->async } qr/has been detached/, '... the same when asked again';
}

{
  my ($schema, $storage) = owner('dbi:FakeK293:dbname=static', 'static-user', 'static-pw', { async => 'k293' });
  my $async  = $storage->async;
  my $before = spawn($async);
  is_deeply $before->{built}, [ 'dbi:FakeK293:dbname=static' ],
    'a sync storage with static connect info: its backend opens a connection from it (control)';
  $async->disconnect;
  my $slots = slots($async);

  $storage->clear_access_broker;
  is_deeply slots($async), $slots, 'clear_access_broker with no broker attached leaves the backend as it was';
  is_deeply spawn($async), $before, '... and it still opens its connections from the static connect info';
}

# ---------------------------------------------------------------------------
# 7. A sync connect_info that throws lets go of the backend of the one before.
# ---------------------------------------------------------------------------
{
  my $first = T::ScriptBroker->new(sub { +{ %K293 } });
  my ($schema, $storage) = owner($first, { async => 'k293' });
  my $async = $storage->async;
  is_deeply spawn($async), opened_from({ %K293 }), 'a backend connected through a first broker';
  my $calls = $first->{calls};

  my $second = T::ScriptBroker->new(sub { die "k293 vault unreachable\n" });
  throws_ok { $storage->connect_info([ $second, { async => 'k293' } ]) }
    qr/^k293 vault unreachable/, 'connect_info with a second broker that throws';
  is $storage->access_broker, $second, '... the second broker is the storage\'s';
  ok !$storage->{_async_storage_obj},
    '... and the backend connected through the first is no longer the storage\'s';
  throws_ok { $storage->async } qr/^k293 vault unreachable/,
    '... the next async use asks the second broker, and fails with it';
  is $first->{calls}, $calls, '... the first broker is not asked again';
}

done_testing;
