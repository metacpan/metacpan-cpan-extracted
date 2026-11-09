# ABSTRACT: A broker's back-reference to its storage does not keep the storage alive
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw(weaken refaddr);

use DBI;
use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Test::Future ();
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::Replicated::Storage;
use DBIO::AccessBroker;

# OFFLINE (karr k270). A storage that is handed an AccessBroker attaches it
# (set_access_broker), and the broker is told its storage (set_storage) -- the
# back-reference behind the legacy current_connect_info_for. That reference was
# a strong one: storage and broker held each other, and neither was ever freed.
# With them stayed what the storage holds -- the database handle of a sync
# storage, which is closed when the storage goes; the pool of an async backend
# and every connection in it. An async backend held itself a second time:
# the per-connection provider it keeps (and hands its pool) closed over it.
# A schema connected through a broker and dropped left its connections open
# until the process ended.
#
# What this file claims:
#   1. a sync storage with a broker attached is freed when the last reference
#      to it goes, and its handle with it -- whether the broker lives on or
#      goes too, and also through a HostBound view;
#   2. an async backend with a broker attached is freed the same way: its
#      DESTROY runs, the pool is shut down, its connections are closed -- as
#      for a backend connected without a broker (control);
#   3. the same for a sync storage with an embedded async backend, both
#      attached to the one broker;
#   4. the provider of a backend that is gone refuses, saying so; it opens no
#      connection and asks the broker nothing;
#   5. the back-reference still does its work while the storage lives: the
#      legacy current_connect_info_for refreshes a due broker, then asks
#      connect_info_for_storage with the attached storage, and
#      connect_info_for without one -- also once the storage is gone;
#   6. a broker keeps a reference to EVERY storage it is attached to (karr
#      k278): asked on its own it answers for its one storage, and refuses
#      when there are several, naming the class and the count, never a
#      credential; given the storage it answers for that one. A storage that
#      detaches it, gets another broker, or is freed drops out;
#   7. a sync owner and its embedded async backend are two storages of one
#      broker, each detaching on its own, the owner taking the backend along;
#   8. Replicated: master and replicants over one broker through views, each
#      view attached to its own backend, the wrapped broker to all;
#   9. HostBound passes set_storage and unset_storage on to the wrapped
#      broker, for that storage only.
#
# THE SUBSTITUTIONS: DBI->connect returns a stand-in handle that counts its own
# destruction; a pool whose connections are plain objects and which counts the
# ones it closes; a fake driver storage with a fake async mode. No database.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

# Answers the DBI form, or connection parameters; records how it was asked --
# the storage by address, so the record keeps nothing alive.
{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new {
    my ($class, %args) = @_;
    bless { asked => [], refreshed => 0, due => 0, params => $args{params} }, $class;
  }
  sub answer {
    my $self = shift;
    return $self->{params}
      ? { dbname => 'app', user => 'k270-user', password => 'k270-pw' }
      : [ 'dbi:Fake:dbname=k270', 'k270-user', 'k270-pw', {} ];
  }
  sub connect_info_for {
    my ($self, $mode) = @_;
    push @{ $self->{asked} }, [ 'connect_info_for', $mode ];
    return $self->answer;
  }
  sub connect_info_for_storage {
    my ($self, $storage, $mode) = @_;
    push @{ $self->{asked} }, [ 'connect_info_for_storage', Scalar::Util::refaddr($storage), $mode ];
    return $self->answer;
  }
  sub needs_refresh { $_[0]{due} }
  sub refresh       { $_[0]{refreshed}++; $_[0]{due} = 0 }
  sub asked         { my @asked = @{ $_[0]{asked} }; $_[0]{asked} = []; return \@asked }
}

# A sync storage of a class of its own: nothing is resolved from the DSN.
{
  package T::Storage;
  use base 'DBIO::Storage::DBI';
}

{
  package T::Handle;
  our $FREED = 0;
  sub new        { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH      { $_[0]->{ $_[1] } }
  sub ping       { 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub DESTROY    { $FREED++ }
}

{
  no warnings 'redefine';
  *DBI::connect = sub { T::Handle->new };
}

{
  package T::Pool;
  use base 'DBIO::Storage::PoolBase';
  our ($BUILT, $CLOSED) = (0, 0);
  sub _create_connection   { $BUILT++; bless {}, 'T::Conn' }
  sub _shutdown_connection { $CLOSED++ }
}

{
  package T::Backend;
  use base 'DBIO::Storage::Async';
  sub future_class { 'DBIO::Test::Future' }
  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    my ($conninfo) = $self->_normalize_async_connect_info($self->_current_async_connect_info($mode));
    return $conninfo;
  }
  sub pool {
    my $self = shift;
    $self->{pool} ||= T::Pool->new(
      size         => 2,
      future_class => $self->future_class,
      ($self->_conninfo_provider
        ? (conninfo_provider => $self->_conninfo_provider)
        : (conninfo          => $self->{_conninfo})),
    );
  }
}

{
  package T::FakeDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeBackref => __PACKAGE__);
}
T::FakeDriver::Storage->register_async_mode(k270backref => 'T::Backend');

sub sync_storage {
  my ($broker) = @_;
  my $storage = T::Storage->new(undef);
  $storage->connect_info([ $broker ]);
  $storage->dbh;
  return $storage;
}

# ---------------------------------------------------------------------------
# 1. A sync storage.
# ---------------------------------------------------------------------------
{
  my $broker  = T::Broker->new;
  my $storage = sync_storage($broker);
  isa_ok $storage->_dbh, 'T::Handle', 'a sync storage connected through a broker holds its handle';

  local $T::Handle::FREED = 0;
  weaken(my $gone = $storage);
  undef $storage;

  ok !defined $gone, 'the storage dropped, the broker kept: the storage is freed';
  is $T::Handle::FREED, 1, '... and its handle with it';
  $broker->asked;
  $broker->current_connect_info_for;
  is_deeply $broker->asked, [ [ 'connect_info_for', 'write' ] ],
    '... and the broker, asked on its own, no longer answers for a storage';
}

{
  local $T::Handle::FREED = 0;
  my ($storage_gone, $broker_gone);
  {
    my $broker  = T::Broker->new;
    my $storage = sync_storage($broker);
    weaken($storage_gone = $storage);
    weaken($broker_gone  = $broker);
  }
  ok !defined $storage_gone, 'storage and broker dropped together: the storage is freed';
  ok !defined $broker_gone,  '... and so is the broker';
  is $T::Handle::FREED, 1, '... and the handle';
}

{
  local $T::Handle::FREED = 0;
  my $broker = T::Broker->new;
  my ($storage_gone, $view_gone);
  {
    my $view    = $broker->for_host('replica.example');
    my $storage = sync_storage($view);
    weaken($storage_gone = $storage);
    weaken($view_gone    = $view);
  }
  ok !defined $storage_gone, 'through a HostBound view: the storage is freed';
  ok !defined $view_gone,    '... and the view, which nothing else holds';
  is $T::Handle::FREED, 1, '... and the handle';
}

# ---------------------------------------------------------------------------
# 2. An async backend.
# ---------------------------------------------------------------------------
{
  local ($T::Pool::BUILT, $T::Pool::CLOSED) = (0, 0);
  my $storage_gone;
  {
    my $storage = T::Backend->new(undef);
    $storage->connect_info([ { dbname => 'app', user => 'static' }, {} ]);
    ok !$storage->pool->acquire->is_failed, 'an async backend without a broker opens a pool connection (control)';
    weaken($storage_gone = $storage);
  }
  ok !defined $storage_gone, '... dropped, it is freed (control)';
  is_deeply [ $T::Pool::BUILT, $T::Pool::CLOSED ], [ 1, 1 ], '... and its connection is closed (control)';
}

for my $case (
  [ 'the broker kept',         1 ],
  [ 'the broker dropped too',  0 ],
) {
  my ($label, $keep) = @$case;
  local ($T::Pool::BUILT, $T::Pool::CLOSED) = (0, 0);
  my ($storage_gone, $pool_gone, $broker_gone, $kept);
  {
    my $broker  = T::Broker->new(params => 1);
    my $storage = T::Backend->new(undef);
    $storage->connect_info([ $broker ]);
    ok !$storage->pool->acquire->is_failed, "an async backend with a broker, $label: a pool connection is opened";
    weaken($storage_gone = $storage);
    weaken($pool_gone    = $storage->{pool});
    weaken($broker_gone  = $broker);
    $kept = $broker if $keep;
  }
  ok !defined $storage_gone, "$label: the backend is freed";
  ok !defined $pool_gone,    "$label: ... and its pool";
  is_deeply [ $T::Pool::BUILT, $T::Pool::CLOSED ], [ 1, 1 ], "$label: ... and its connection is closed";
  is defined $broker_gone ? 1 : 0, $keep, "$label: ... and the broker " . ($keep ? 'lives on' : 'is freed');
}

# ---------------------------------------------------------------------------
# 3. A sync storage with an embedded async backend, one broker for both.
# ---------------------------------------------------------------------------
{
  local ($T::Pool::BUILT, $T::Pool::CLOSED) = (0, 0);
  my ($owner_gone, $backend_gone, $broker_gone);
  {
    my $broker = T::Broker->new;
    my $owner  = T::FakeDriver::Storage->new(undef);
    $owner->connect_info([ $broker, { async => 'k270backref' } ]);

    my $backend = $owner->async;
    isa_ok $backend, 'T::Backend', 'the embedded backend of a broker-backed async connection';
    is refaddr($backend->access_broker), refaddr($broker), '... attached to the same broker as its owner';
    ok !$backend->pool->acquire->is_failed, '... opens a pool connection';

    weaken($owner_gone   = $owner);
    weaken($backend_gone = $backend);
    weaken($broker_gone  = $broker);
  }
  ok !defined $owner_gone,   'owner, backend and broker dropped: the owner is freed';
  ok !defined $backend_gone, '... and the backend';
  ok !defined $broker_gone,  '... and the broker';
  is_deeply [ $T::Pool::BUILT, $T::Pool::CLOSED ], [ 1, 1 ], "... and the backend's connection is closed";
}

# ---------------------------------------------------------------------------
# 4. The provider of a backend that is gone.
# ---------------------------------------------------------------------------
{
  local ($T::Pool::BUILT, $T::Pool::CLOSED) = (0, 0);
  my $broker = T::Broker->new(params => 1);
  my ($provider, $pool);
  {
    my $storage = T::Backend->new(undef);
    $storage->connect_info([ $broker ]);
    $provider = $storage->_conninfo_provider;
    $pool     = $storage->pool;
    is_deeply $provider->(), { dbname => 'app', user => 'k270-user', password => 'k270-pw' },
      "while its backend lives, the provider answers the broker's current connect info";
  }
  $broker->asked;

  throws_ok { $provider->() } qr/the async storage it was made for is gone/,
    'the backend gone: its provider refuses, saying so';
  unlike "$@", qr/k270-/, '... quoting no credential';

  my $f = $pool->acquire;
  ok $f->is_failed, 'a pool kept past its backend fails an acquire with a failed Future';
  like "$f->{values}[0]", qr/Connection pool has been shut down/,
    '... as the shut-down pool it is: the backend closed it as it went';
  is $T::Pool::BUILT, 0, '... and no connection is opened';
  is_deeply $broker->asked, [], '... and the broker is asked nothing';
}

# ---------------------------------------------------------------------------
# 5. The back-reference at work: the legacy current_connect_info_for.
# ---------------------------------------------------------------------------
{
  my $broker = T::Broker->new;

  $broker->current_connect_info_for;
  $broker->current_connect_info_for('read');
  is_deeply $broker->asked, [ [ 'connect_info_for', 'write' ], [ 'connect_info_for', 'read' ] ],
    'a broker attached to no storage: current_connect_info_for asks connect_info_for, mode write unless given';

  my $storage = T::Storage->new(undef);
  $storage->connect_info([ $broker ]);
  $broker->asked;

  is_deeply $broker->current_connect_info_for('read'), $broker->answer,
    'attached to a storage: current_connect_info_for returns the answer';
  is_deeply $broker->asked, [ [ 'connect_info_for_storage', refaddr($storage), 'read' ] ],
    '... of connect_info_for_storage, asked with the attached storage';

  $broker->{due} = 1;
  $broker->current_connect_info_for;
  is $broker->{refreshed}, 1, 'a broker whose credentials are due is refreshed first, once';
  $broker->current_connect_info_for;
  is $broker->{refreshed}, 1, '... and not again while they are not due';
  $broker->asked;

  undef $storage;
  $broker->current_connect_info_for;
  is_deeply $broker->asked, [ [ 'connect_info_for', 'write' ] ],
    'the storage gone: current_connect_info_for asks connect_info_for again';
}

# ---------------------------------------------------------------------------
# 6. One broker, two storages, and one that lets go.
# ---------------------------------------------------------------------------
sub addrs { [ sort map { refaddr($_) } @_ ] }
sub asked_with { my ($broker, @storages) = @_; [ map { [ 'connect_info_for_storage', refaddr($_), 'write' ] } @storages ] }

{
  my $broker = T::Broker->new;
  my ($first, $second) = map { T::Storage->new(undef) } 1 .. 2;
  $_->connect_info([ $broker ]) for $first, $second;
  $broker->asked;

  is_deeply addrs($broker->_attached_storages), addrs($first, $second),
    'a broker attached to two storages knows both';

  $first->_connect;
  $second->_connect;
  $first->_connect;
  is_deeply $broker->asked, asked_with($broker, $first, $second, $first),
    'one broker on two storages: each connection asks it with the storage that connects';

  # Asked on its own, the broker cannot tell which storage is meant.
  $broker->{due} = 1;
  throws_ok { $broker->current_connect_info_for } qr/T::Broker is attached to 2 storages/,
    'asked on its own with two storages attached: refused, naming the class and the count';
  like "$@", qr/current_connect_info_for_storage/, '... and the call to use instead';
  unlike "$@", qr/k270-/, '... quoting no credential';
  is $broker->{refreshed}, 0, '... and a broker that is due is not refreshed first';
  is_deeply $broker->asked, [], '... and nothing is asked of it';

  # Given the storage, it answers, whichever and however many.
  is_deeply $broker->current_connect_info_for('read', $second), $broker->answer,
    'given the storage as the second argument: answers';
  is_deeply $broker->asked, [ [ 'connect_info_for_storage', refaddr($second), 'read' ] ],
    '... of connect_info_for_storage for that storage, in the mode given';
  is $broker->{refreshed}, 1, '... after refreshing the broker that was due, once';
  $broker->asked;

  # One lets go: the other stays, and the broker answers for it again.
  $second->clear_access_broker;
  is $second->access_broker, undef, 'one storage detaches the broker';
  is_deeply addrs($broker->_attached_storages), addrs($first),
    '... and the broker is attached to the other alone';
  $broker->current_connect_info_for;
  is_deeply $broker->asked, asked_with($broker, $first),
    '... asked on its own, it answers for the storage still attached, not for the one that detached it';

  $first->_connect;
  is_deeply $broker->asked, asked_with($broker, $first),
    'the storage still attached goes on asking with itself';

  # The last one lets go: attached to none.
  $first->clear_access_broker;
  is_deeply [ $broker->_attached_storages ], [], 'the last storage detaches: the broker is attached to none';
  $broker->current_connect_info_for;
  is_deeply $broker->asked, [ [ 'connect_info_for', 'write' ] ],
    '... and asked on its own it answers connect_info_for';

  # A storage that was never attached to it may still be asked for.
  $broker->current_connect_info_for('write', $first);
  is_deeply $broker->asked, asked_with($broker, $first),
    'given a storage it is not attached to, it answers for that storage all the same';
}

{
  # The same storage attached twice is one storage.
  my $broker  = T::Broker->new;
  my $storage = T::Storage->new(undef);
  $storage->set_access_broker($broker);
  $storage->set_access_broker($broker);
  is_deeply addrs($broker->_attached_storages), addrs($storage),
    'the same storage attached twice is counted once';
  $storage->clear_access_broker;
  is_deeply [ $broker->_attached_storages ], [], '... and one detach is enough';
}

{
  # A storage gets another broker: the first is let go of.
  my ($old, $new) = map { T::Broker->new } 1 .. 2;
  my $storage = T::Storage->new(undef);
  $storage->connect_info([ $old ]);
  $storage->connect_info([ $new ]);
  is_deeply [ $old->_attached_storages ], [], 'a storage given another broker: the broker before is attached to none';
  is_deeply addrs($new->_attached_storages), addrs($storage), '... and the new one to the storage';
  $old->asked;
  $old->current_connect_info_for;
  is_deeply $old->asked, [ [ 'connect_info_for', 'write' ] ], '... the old one answers no more for it';

  my $third = T::Broker->new;
  $storage->set_access_broker($third, 'read');
  is_deeply [ $new->_attached_storages ], [], 'set_access_broker over a broker: the one replaced lets go, too';
  is_deeply addrs($third->_attached_storages), addrs($storage), '... and the new one holds it';

  # A connect without a broker detaches as well.
  $storage->connect_info([ 'dbi:Fake:dbname=static', 'u', 'p', {} ]);
  is_deeply [ $third->_attached_storages ], [], 'a storage connected without a broker: the broker is attached to none';
}

{
  # A storage that is freed drops out; nobody has to detach it.
  my $broker = T::Broker->new;
  my $kept   = T::Storage->new(undef);
  $kept->connect_info([ $broker ]);
  {
    my $dropped = T::Storage->new(undef);
    $dropped->connect_info([ $broker ]);
    is scalar(() = $broker->_attached_storages), 2, 'two storages attached';
  }
  is_deeply addrs($broker->_attached_storages), addrs($kept),
    'one freed: the broker is attached to the other alone';
  $broker->asked;
  $broker->current_connect_info_for;
  is_deeply $broker->asked, asked_with($broker, $kept), '... and answers for it';
  undef $kept;
  is_deeply [ $broker->_attached_storages ], [], 'both freed: attached to none';
  lives_ok { $broker->current_connect_info_for } '... and asked on its own it answers';
}

# ---------------------------------------------------------------------------
# 7. A sync storage and its async backend, one broker for both.
# ---------------------------------------------------------------------------
{
  my $broker = T::Broker->new;
  my $owner  = T::FakeDriver::Storage->new(undef);
  $owner->connect_info([ $broker, { async => 'k270backref' } ]);
  my $backend = $owner->async;
  $broker->asked;

  is_deeply addrs($broker->_attached_storages), addrs($owner, $backend),
    'owner and embedded backend: the broker is attached to both';
  throws_ok { $broker->current_connect_info_for } qr/attached to 2 storages/,
    '... and asked on its own it does not answer for either';

  $backend->clear_access_broker;
  is_deeply addrs($broker->_attached_storages), addrs($owner),
    'the backend detaches: the broker is attached to the owner alone';
  $broker->current_connect_info_for;
  is_deeply $broker->asked, asked_with($broker, $owner), '... and answers for the owner';
}

{
  my $broker = T::Broker->new;
  my $owner  = T::FakeDriver::Storage->new(undef);
  $owner->connect_info([ $broker, { async => 'k270backref' } ]);
  my $backend = $owner->async;
  $broker->asked;

  $owner->clear_access_broker;
  is_deeply [ $broker->_attached_storages ], [],
    'the owner detaches: the backend goes with it, the broker is attached to none';
  $broker->current_connect_info_for;
  is_deeply $broker->asked, [ [ 'connect_info_for', 'write' ] ], '... and answers connect_info_for';
}

# ---------------------------------------------------------------------------
# 8. Replicated: master and two replicants over one broker.
# ---------------------------------------------------------------------------
{
  my $broker = T::Broker->new;
  my %view = map { $_ => $broker->for_host("$_.example") } qw( master replica_1 replica_2 );

  my $rstorage = DBIO::Replicated::Storage->new(undef, { backend_storage_class => 'T::Storage' });
  $rstorage->connect_info([ $view{master} ]);
  my @replicants = $rstorage->connect_replicants([ $view{replica_1} ], [ $view{replica_2} ]);
  my %backend = (
    master    => $rstorage->master->storage,
    replica_1 => $replicants[0]->storage,
    replica_2 => $replicants[1]->storage,
  );
  $broker->asked;

  is_deeply addrs($broker->_attached_storages), addrs(@backend{qw( master replica_1 replica_2 )}),
    'master and two replicants over one broker: the broker is attached to all three';
  is_deeply addrs($view{$_}->_attached_storages), addrs($backend{$_}),
    "... and the view of $_ to its own backend alone" for qw( master replica_1 replica_2 );
  throws_ok { $broker->current_connect_info_for } qr/attached to 3 storages/,
    '... asked on its own the broker refuses';

  $view{replica_1}->current_connect_info_for;
  is_deeply $broker->asked, asked_with($broker, $backend{replica_1}),
    'a view asked on its own answers for the backend it is attached to';

  $backend{replica_1}->clear_access_broker;
  is_deeply addrs($broker->_attached_storages), addrs(@backend{qw( master replica_2 )}),
    'a replicant detaches: the broker keeps the other two';
  is_deeply [ $view{replica_1}->_attached_storages ], [], '... and its view is attached to none';
  is_deeply addrs($view{master}->_attached_storages), addrs($backend{master}),
    '... the other views keep theirs';
}

# ---------------------------------------------------------------------------
# 9. HostBound views over one broker.
# ---------------------------------------------------------------------------
{
  my $broker = T::Broker->new;
  my @views    = map { $broker->for_host("replica-$_.example") } 1 .. 2;
  my @storages = map { T::Storage->new(undef) } 1 .. 2;
  $storages[$_]->connect_info([ $views[$_] ]) for 0, 1;
  $broker->asked;

  $_->current_connect_info_for for @views;
  is_deeply $broker->asked, [ map { [ 'connect_info_for_storage', refaddr($_), 'write' ] } @storages ],
    'a view per storage: each view, asked on its own, answers for the storage it is attached to';

  is_deeply addrs($broker->_attached_storages), addrs(@storages),
    'the wrapped broker is attached to both storages';
  throws_ok { $broker->current_connect_info_for } qr/attached to 2 storages/,
    '... and asked on its own it refuses';

  $storages[0]->clear_access_broker;
  is_deeply [ $views[0]->_attached_storages ], [], 'one storage detaches its view: the view is attached to none';
  is_deeply addrs($broker->_attached_storages), addrs($storages[1]),
    '... the wrapped broker keeps the other storage, untouched';
  is_deeply addrs($views[1]->_attached_storages), addrs($storages[1]), '... and so does the other view';

  # unset_storage on a view reaches the wrapped broker, for that storage only.
  $views[1]->unset_storage($storages[1]);
  is_deeply [ $broker->_attached_storages ], [], 'unset_storage on a view lets go at the wrapped broker as well';

  # And an unset of a storage it does not know changes nothing.
  $views[0]->set_storage($storages[0]);
  $views[0]->unset_storage($storages[1]);
  is_deeply addrs($broker->_attached_storages), addrs($storages[0]),
    'unset_storage of a storage that is not attached leaves the rest as it is';
}

done_testing;
