# ABSTRACT: k331: a backend rebuilt after disconnect is made from the broker attached last, not the static DSN
use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Test::Future ();
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker;

# karr k331, continuation of question 2 A (maintainer decision 2026-10-13):
# set_access_broker(B) on a sync storage also writes B into the connect info
# the storage keeps (_connect_info), so the backend a later *_async call
# builds anew -- after disconnect -- is made from B and not from the DSN the
# storage was given. What is open while the attach happens stays with the
# broker it began with (t/test/63).
{
  package T67::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $name) = @_; bless { name => $name, calls => 0 }, $class }
  sub connect_info_for {
    my $self = shift;
    $self->{calls}++;
    return { dbname => "db-$self->{name}", user => "user-$self->{name}" };
  }
}

{
  package T67::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { my ($self, $conninfo) = @_; push @{ $self->{built} }, $conninfo; bless {}, 'T67::Conn' }
  sub _transform_conninfo { $_[1] }
}

{
  package T67::Backend;
  use base 'DBIO::Storage::Async';
  sub future_class { 'DBIO::Test::Future' }
  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    my ($conninfo) = $self->_normalize_async_connect_info($self->_current_async_connect_info($mode));
    return $conninfo;
  }
  sub pool {
    my $self = shift;
    $self->{pool} ||= T67::Pool->new(
      size         => 3,
      future_class => $self->future_class,
      ($self->_conninfo_provider
        ? (conninfo_provider => $self->_conninfo_provider)
        : (conninfo          => $self->{_conninfo})),
    );
  }
}

{
  package T67::Driver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeK331R => __PACKAGE__);
  __PACKAGE__->register_async_mode(k331r => 'T67::Backend');
}

sub next_conninfo {
  my ($backend) = @_;
  my $pool = $backend->pool;
  my $before = @{ $pool->{built} || [] };
  my $f = $pool->acquire;
  my @all = @{ $pool->{built} || [] };
  return @all > $before
    ? $all[-1]
    : ($f->is_failed ? 'FAILED: ' . $f->{values}[0] : 'nothing built');
}

sub owner {
  my @info = @_;
  my $schema = DBIO::Test->init_schema(no_connect => 1, storage_type => '+T67::Driver::Storage');
  $schema->connection(@info);
  return ($schema, $schema->storage);
}

# (a) static DSN, pool built, B attached, disconnect, async again
{
  my $B = T67::Broker->new('B');
  my ($schema, $storage) = owner('dbi:FakeK331R:dbname=static', 'u', 'p', { async => 'k331r' });
  my $old = $storage->async;
  is_deeply next_conninfo($old), 'dbi:FakeK331R:dbname=static',
    '(a) first pool opens from the static DSN (control)';

  $storage->set_access_broker($B);
  $storage->disconnect;

  my $new = $storage->async;
  isnt $new, $old, '... the backend is built anew after disconnect';
  is_deeply next_conninfo($new), { dbname => 'db-B', user => 'user-B' },
    'the new pool opens from B, not from the static DSN';
  ok $B->{calls}, '... B was asked for it';
}

# (b) attached before any backend was built, then the first use
{
  my $B = T67::Broker->new('B');
  my ($schema, $storage) = owner('dbi:FakeK331R:dbname=static', 'u', 'p', { async => 'k331r' });
  $storage->set_access_broker($B);
  ok !$storage->{_async_storage_obj}, '(b) attach builds no backend';
  is_deeply next_conninfo($storage->async), { dbname => 'db-B', user => 'user-B' },
    '... the first backend is made from B';
}

# (c) attached over a broker A
{
  my ($A, $B) = (T67::Broker->new('A'), T67::Broker->new('B'));
  my ($schema, $storage) = owner($A, { async => 'k331r' });
  is_deeply next_conninfo($storage->async), { dbname => 'db-A', user => 'user-A' }, '(c) pool from A (control)';
  my $a_calls = $A->{calls};
  $storage->set_access_broker($B);
  $storage->disconnect;
  is_deeply next_conninfo($storage->async), { dbname => 'db-B', user => 'user-B' },
    '... after the attach and disconnect the rebuilt pool opens from B';
  is $A->{calls}, $a_calls, '... A is not asked for it';
}

# (d) the connect info keeps the broker given to connect_info
{
  my $A = T67::Broker->new('A');
  my ($schema, $storage) = owner($A, { async => 'k331r' });
  my $info = $storage->connect_info;
  is ref $info, 'ARRAY', '(d) connect info is the broker form';
  is $info->[0], $A, '... holding the broker';
  is $info->[1]{async}, 'k331r', '... and what stood beside it';
}

# (e) static DSN -> set B -> clear -> disconnect: the DSN stands again
{
  my $B = T67::Broker->new('B');
  my ($schema, $storage) = owner('dbi:FakeK331R:dbname=static', 'u', 'p', { async => 'k331r' });
  $storage->set_access_broker($B);
  $storage->clear_access_broker;
  $storage->disconnect;
  is_deeply next_conninfo($storage->async), 'dbi:FakeK331R:dbname=static',
    '(e) after clear and disconnect the backend is built from the static DSN';
  is $B->{calls}, 0, '... B is not asked';
}

# (f) static DSN -> set B -> new connect_info -> clear: the new info stands
{
  my $B = T67::Broker->new('B');
  my ($schema, $storage) = owner('dbi:FakeK331R:dbname=static', 'u', 'p', { async => 'k331r' });
  $storage->set_access_broker($B);
  $storage->connect_info([ 'dbi:FakeK331R:dbname=other', 'u', 'p', { async => 'k331r' } ]);
  $storage->clear_access_broker;
  is_deeply next_conninfo($storage->async), 'dbi:FakeK331R:dbname=other',
    '(f) connect_info given after the attach is not overwritten by the clear';
}

# (g) broker A -> set B -> clear: no static slot, nothing is invented
{
  my ($A, $B) = (T67::Broker->new('A'), T67::Broker->new('B'));
  my ($schema, $storage) = owner($A, { async => 'k331r' });
  $storage->set_access_broker($B);
  $storage->clear_access_broker;
  $storage->disconnect;
  ok !eval { $storage->async; 1 }, '(g) over a broker, clear leaves the storage with nothing to connect from';
  like $@, qr/detached/, '... saying the broker was detached';
}

done_testing;
