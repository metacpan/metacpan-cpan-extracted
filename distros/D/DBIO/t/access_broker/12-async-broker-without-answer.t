# ABSTRACT: An async backend refuses a broker that answers nothing
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker;
use DBIO::Test::Future ();

# OFFLINE (karr k249). An async backend asks its AccessBroker for connect info
# at connect_info and again for every new pool connection
# (_current_async_connect_info, through the transport's _async_broker_conninfo).
# When the broker answered nothing -- undef, an empty hash or array, a false
# string -- it fell back to the conninfo stored at connect_info without a word:
# the next pool connection was opened with the credentials of an EARLIER answer
# (the ones the broker may just have rotated out), with none at all (undef, {}:
# the DBD's defaults), or -- asked at connect_info on a storage that had been
# connected statically before -- with the previous connection's identity.
#
# What this file claims:
#   1. A broker that answers nothing when a new pool connection is opened fails
#      that connection: acquire's Future fails with an error naming the broker
#      class and what it answered, never a value of an earlier answer, and no
#      connection is built. A good answer before it is still used (control).
#   2. A broker that answers nothing at connect_info makes connect_info throw
#      the same error -- also on a storage whose previous connect_info was
#      static, whose identity must not carry over.
#   3. A broker that throws: its own error reaches the caller, at connect_info
#      and at a pool spawn; no connection is built from an earlier answer.
#   4. Without a broker, a new connection still gets the static conninfo
#      connect_info stored -- the fallback's own purpose.
#
# THE SUBSTITUTIONS: a pool that records every connection it builds instead of
# connecting; a transport running core's own connect_info and building each
# pool connection's conninfo the way dbio-async's DBIO::Async::Storage and
# dbio-mysql-ev do (_normalize_async_connect_info over
# _current_async_connect_info).

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

my $SECRET = qr/k249-(?:user|secret|old)/;

sub first_answer { { dbname => 'app', user => 'k249-user-1', password => 'k249-secret-1' } }

my %NOTHING = (
  'undef'             => sub { undef },
  'an empty hashref'  => sub { {} },
  'an empty arrayref' => sub { [] },
  'a false value'     => sub { '' },
);

sub failure_of { my ($f) = @_; return $f->is_failed ? "$f->{values}[0]" : '' }

# ---------------------------------------------------------------------------
# 1. Nothing answered when a pool connection is opened.
# ---------------------------------------------------------------------------
for my $shape (sort keys %NOTHING) {
  my $broker = T::ScriptBroker->new(
    \&first_answer,
    sub { { dbname => 'app', user => 'k249-user-2', password => 'k249-secret-2' } },
    $NOTHING{$shape},
  );
  my $storage = T::Backend->new(undef);
  $storage->connect_info([ $broker ]);
  local @T::RecordingPool::BUILT;

  my $good = $storage->pool->acquire;
  ok !$good->is_failed, "$shape: a pool connection before it is opened";
  is_deeply \@T::RecordingPool::BUILT,
    [ { dbname => 'app', user => 'k249-user-2', password => 'k249-secret-2' } ],
    "$shape: ... with the broker's current answer";

  my $f = $storage->pool->acquire;
  ok $f->is_failed, "$shape: the next pool connection fails";
  like failure_of($f), qr/AccessBroker T::ScriptBroker answered no connect info \(\Q$shape\E\)/,
    "$shape: naming the broker class and what it answered";
  unlike failure_of($f), $SECRET, "$shape: naming no value of an earlier answer";
  is scalar @T::RecordingPool::BUILT, 1, "$shape: no connection is built from an earlier answer";
}

# ---------------------------------------------------------------------------
# 2. Nothing answered at connect_info.
# ---------------------------------------------------------------------------
for my $shape (sort keys %NOTHING) {
  my $storage = T::Backend->new(undef);
  throws_ok { $storage->connect_info([ T::ScriptBroker->new($NOTHING{$shape}) ]) }
    qr/AccessBroker T::ScriptBroker answered no connect info \(\Q$shape\E\)/,
    "$shape at connect_info: connect_info throws";
}

{
  my $storage = T::Backend->new(undef);
  $storage->connect_info([ { dbname => 'old', user => 'k249-old-user', password => 'k249-old-pw' }, {} ]);
  throws_ok { $storage->connect_info([ T::ScriptBroker->new(sub { undef }) ]) }
    qr/AccessBroker T::ScriptBroker answered no connect info \(undef\)/,
    'a statically connected storage, reconnected with a broker answering nothing: connect_info throws';
  unlike "$@", $SECRET, '... naming no value of the previous connect info';
}

# ---------------------------------------------------------------------------
# 3. The broker throws.
# ---------------------------------------------------------------------------
{
  my $storage = T::Backend->new(undef);
  throws_ok { $storage->connect_info([ T::ScriptBroker->new(sub { die "k249 vault unreachable\n" }) ]) }
    qr/^k249 vault unreachable/, 'a broker throwing at connect_info: its error reaches the caller';
}

{
  my $storage = T::Backend->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(\&first_answer, sub { die "k249 vault unreachable\n" }) ]);
  local @T::RecordingPool::BUILT;
  my $f = $storage->pool->acquire;
  like failure_of($f), qr/^k249 vault unreachable/,
    'a broker throwing at a pool spawn: the connection fails with its error';
  is scalar @T::RecordingPool::BUILT, 0, '... and none is built from the earlier answer';
}

# ---------------------------------------------------------------------------
# 4. No broker: the static conninfo.
# ---------------------------------------------------------------------------
{
  my $storage = T::Backend->new(undef);
  $storage->connect_info([ { dbname => 'app', user => 'static' }, { some => 'opt' } ]);
  is_deeply $storage->_current_async_connect_info('write'),
    [ { dbname => 'app', user => 'static' }, { some => 'opt' } ],
    'without a broker, a connection gets the static conninfo connect_info stored';

  local @T::RecordingPool::BUILT;
  ok !$storage->pool->acquire->is_failed, '... and the pool opens one from it';
  is_deeply \@T::RecordingPool::BUILT, [ { dbname => 'app', user => 'static' } ],
    '... with that conninfo';
}

done_testing;
