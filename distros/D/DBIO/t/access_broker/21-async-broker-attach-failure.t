# ABSTRACT: A broker that cannot be attached leaves no static conninfo behind on an async backend
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed reftype refaddr);

use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker;
use DBIO::Test::Future ();

# OFFLINE (karr k265, found reading dbio-mysql-ev k62; that dist holds the same
# claim for its own connect_info in t/29-access-broker-conninfo-mock.t, section
# 8). DBIO::Storage::Async::connect_info, given a broker, attached it, read its
# answer, and only THEN dropped the conninfo stored by the connect_info before.
# Everything between the two can throw -- the broker itself, the refusal of an
# answer of nothing (k249) or of no usable shape (k264), two pool sizes that
# disagree (k245) -- and when it did, the storage was left with the broker
# attached and the STATIC conninfo of its previous connection still stored.
# Nothing uses that while the broker is attached. Detach it, and the next pool
# connection was opened from it: the identity the caller had just replaced.
#
# What this file claims, for every way attaching a broker can throw:
#   1. connect_info throws that error, and the conninfo of the static
#      connection before is gone -- from {_conninfo} and from the storage
#      object as a whole;
#   2. while the broker stays attached, a pool connection asks IT, and fails
#      with it: none is built from the static conninfo;
#   3. with the broker detached, no pool connection is opened at all, and
#      nothing of the static connection is in what the attempt says. Through
#      _clear_access_broker the storage is where one that was never configured
#      is. Through clear_access_broker the provider stays and refuses: the
#      attempt fails as a failed Future, saying that no broker is attached
#      (karr k273 -- core's provider says so itself, where it used to hand a
#      transport that did not refuse no conninfo at all, from which this
#      file's transport opened the connection);
#   4. the same when the static connection had a pool with a connection in it;
#   5. controls: static connect info alone is stored and connected from, so 3
#      compares against something; a broker that attaches leaves no conninfo
#      either (k252); and a storage whose attach failed takes static connect
#      info again afterwards.
#
# THE SUBSTITUTIONS: a pool that records every connection it builds instead of
# connecting; a transport running core's own connect_info and building each
# pool connection's conninfo the way dbio-async's DBIO::Async::Storage does.

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
  sub future_class { 'DBIO::Test::Future' }
  sub disconnect   { delete $_[0]{pool}; 1 }
  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    my ($conninfo) = $self->_normalize_async_connect_info($self->_current_async_connect_info($mode));
    return $conninfo;
  }
  sub pool {
    my $self = shift;
    $self->{pool} ||= T::RecordingPool->new(
      size         => 5,
      future_class => $self->future_class,
      ($self->_conninfo_provider
        ? (conninfo_provider => $self->_conninfo_provider)
        : (conninfo          => $self->{_conninfo})),
    );
  }
}

# The same transport, taking the connect options beside a broker.
{
  package T::OptionsBackend;
  our @ISA = ('T::Backend');
  sub transport_capabilities { 'broker_connect_options' }
}

my $STATIC = qr/k265-static/;   # every value of the static connect info in this file

sub static_info {
  return [ { dbname => 'k265-static-db', user => 'k265-static-user', password => 'k265-static-pw' }, { some => 'opt' } ];
}
sub static_conninfo { static_info()->[0] }

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

# What a storage that was never given any connect info does: the yardstick for
# "nothing of the static connection". Its pool has nothing to be built from.
my $UNCONFIGURED = spawn(T::Backend->new(undef));
like $UNCONFIGURED->{refused}, qr/conninfo or conninfo_provider required/,
  'an unconfigured storage: the pool refuses to be built';
is_deeply $UNCONFIGURED->{built}, [], '... and no connection is';

# ---------------------------------------------------------------------------
# 5a. Control: static connect info is stored, and connected from.
# ---------------------------------------------------------------------------
{
  my $storage = T::Backend->new(undef);
  $storage->connect_info(static_info());
  is_deeply $storage->{_conninfo}, static_conninfo(), 'static connect info: its conninfo is stored';
  ok holds($storage, $STATIC), '... (the scanner finds it in the storage)';
  is_deeply spawn($storage), opened_from(static_conninfo()),
    '... and a pool connection is opened from it';
}

# ---------------------------------------------------------------------------
# 1 - 4. Every way attaching a broker can throw.
# ---------------------------------------------------------------------------
# [ label, transport, connect info, the error, what a pool connection is built
#   from while the broker stays attached -- none, where its answer is the
#   trouble ]
my @FAILING = (
  [ 'the broker throws',
    'T::Backend',
    sub { [ T::ScriptBroker->new(sub { die "k265 vault unreachable\n" }) ] },
    qr/^k265 vault unreachable/ ],
  [ 'the broker answers nothing',
    'T::Backend',
    sub { [ T::ScriptBroker->new(sub { undef }) ] },
    qr/AccessBroker T::ScriptBroker answered no connect info \(undef\)/ ],
  [ 'the broker answers a plain string',
    'T::Backend',
    sub { [ T::ScriptBroker->new(sub { 'dbi:Fake:dbname=app;password=k265-broker-pw' }) ] },
    qr/AccessBroker T::ScriptBroker answered connect info an async storage cannot connect from \(a plain scalar\)/ ],
  [ 'the pool size in the answer and the one beside the broker disagree',
    'T::OptionsBackend',
    sub { [ T::ScriptBroker->new(sub { { dbname => 'app', user => 'k265-broker-user', pool_size => 2 } }), { pool_size => 3 } ] },
    qr/Connection setting 'pool_size' is given both beside the AccessBroker and in the broker's answer/,
    { dbname => 'app', user => 'k265-broker-user' } ],
);

for my $case (@FAILING) {
  my ($label, $class, $broker_info, $error, $from_broker) = @$case;

  for my $pooled (0, 1) {
    my $t = $label . ($pooled ? ', the static connection pooled' : '');

    for my $detach (qw( _clear_access_broker clear_access_broker )) {
      my $storage = $class->new(undef);
      $storage->connect_info(static_info());
      if ($pooled) {
        is_deeply spawn($storage)->{built}, [ static_conninfo() ],
          "$t: the static connection has a pool connection";
      }

      my $info = $broker_info->();
      throws_ok { $storage->connect_info($info) } $error, "$t: connect_info throws";
      unlike "$@", $STATIC, "$t: ... naming no value of the static connect info";

      # 1.
      is $storage->{_conninfo}, undef, "$t: the static conninfo is not kept";
      ok !holds($storage, $STATIC), "$t: ... nor anything of it, anywhere in the storage";

      # 2. (IST, not a claim of this card: the broker stays attached.)
      is $storage->access_broker, $info->[0], "$t: the broker is attached";
      {
        my $attached = spawn($storage);
        if ($from_broker) {
          is_deeply $attached, opened_from($from_broker),
            "$t: with it attached, a pool connection is opened from its answer";
        }
        else {
          isnt $attached->{failed}, '', "$t: with it attached, a pool connection fails";
          is_deeply $attached->{built}, [], "$t: ... none is built";
        }
        ok !holds($attached, $STATIC), "$t: ... nothing of the static conninfo is in it";
        $storage->disconnect;   # the pool built for that attempt goes with it
      }

      # 3.
      $storage->$detach;
      ok !$storage->access_broker, "$t, $detach: the broker is detached";
      my $detached = spawn($storage);
      ok !holds($detached, $STATIC),
        "$t, $detach: a pool connection is not opened from the static conninfo";
      if ($detach eq '_clear_access_broker') {
        is_deeply $detached, $UNCONFIGURED,
          "$t, $detach: the storage is where an unconfigured one is -- no pool, no connection";
      }
      else {
        # clear_access_broker leaves the provider installed, and with no
        # broker attached the provider refuses (karr k273). This file's
        # transport does not refuse by itself: it reads what is stored, which
        # is nothing, and the pool used to open a connection from that.
        is $detached->{refused}, '', "$t, $detach: acquire does not throw";
        like $detached->{failed}, qr/^T::\w+ has no AccessBroker attached to ask for connect info/,
          "$t, $detach: its Future fails, saying that no broker is attached";
        is_deeply $detached->{built}, [],
          "$t, $detach: no connection is built -- not from no conninfo at all either";
      }
    }
  }
}

# ---------------------------------------------------------------------------
# 5b. Controls: a broker that attaches; static connect info after a failure.
# ---------------------------------------------------------------------------
{
  my $storage = T::Backend->new(undef);
  $storage->connect_info(static_info());
  my $answer = { dbname => 'app', user => 'k265-broker-user', password => 'k265-broker-pw' };
  lives_ok { $storage->connect_info([ T::ScriptBroker->new(sub { $answer }) ]) }
    'static connect info, then a broker that answers: it attaches';
  is $storage->{_conninfo}, undef, '... no conninfo is stored, neither its answer nor the static one';
  ok !holds($storage, $STATIC), '... nothing of the static connect info is left in the storage';
  is_deeply spawn($storage), opened_from($answer),
    '... and a pool connection is opened from the broker';
}

{
  my $storage = T::Backend->new(undef);
  $storage->connect_info(static_info());
  dies_ok { $storage->connect_info([ T::ScriptBroker->new(sub { die "k265 vault unreachable\n" }) ]) }
    'static connect info, then a broker that throws';
  lives_ok { $storage->connect_info(static_info()) } '... then static connect info again: it is taken';
  ok !$storage->access_broker && !$storage->_conninfo_provider, '... the broker and its provider are gone';
  is_deeply spawn($storage), opened_from(static_conninfo()),
    '... and a pool connection is opened from it';
}

done_testing;
