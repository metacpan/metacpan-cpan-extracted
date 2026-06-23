use strict;
use warnings;
use Test::More;

# Mock EV::Pg so we don't need a real PostgreSQL. Must be set up before
# Storage's runtime `require EV::Pg` in listen().
BEGIN {
  package EV::Pg;
  sub new {
    my ($class, %args) = @_;
    return bless { %args, queries => [], params => [] }, $class;
  }
  sub query {
    my ($self, $sql, $cb) = @_;
    push @{ $self->{queries} }, $sql;
    $cb->(1, undef) if $cb;
  }
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    push @{ $self->{queries} }, $sql;
    push @{ $self->{params} }, $bind;
    $cb->(1, undef) if $cb;
  }
  sub connect_ok { $_[0]->{on_connect}->() }
  sub fire_notify {
    my ($self, $ch, $payload, $pid) = @_;
    $self->{on_notify}->($ch, $payload, $pid);
  }
  $INC{'EV/Pg.pm'} = __FILE__;
}

use DBIO::PostgreSQL::Async::Storage;

my $storage = DBIO::PostgreSQL::Async::Storage->new(undef);
$storage->connect_info([ { host => 'localhost', dbname => 'test' } ]);

# --- listen: dedicated connection, buffering until connected ---

my @received;
$storage->listen(test_channel => sub { push @received, [@_] });

my $pg = $storage->{_listen_pg};
ok $pg, 'dedicated LISTEN connection created on first listen';
is_deeply $pg->{queries}, [], 'LISTEN buffered while not yet connected';
is_deeply $storage->{_listen_pending}, ['LISTEN "test_channel"'],
  'pending queue holds quoted LISTEN';

$pg->connect_ok;
is_deeply $pg->{queries}, ['LISTEN "test_channel"'],
  'pending LISTEN flushed on connect';

$storage->listen(other_channel => sub {});
is $pg->{queries}[-1], 'LISTEN "other_channel"',
  'subsequent LISTEN sent immediately once connected';
is $storage->{_listen_pg}, $pg, 'no second connection created';

# --- notification dispatch ---

$pg->fire_notify('test_channel', 'hello', 999);
is_deeply \@received, [['test_channel', 'hello', 999]],
  'notification dispatched to handler with payload and pid';

$pg->fire_notify('unknown_channel', 'x', 1);
is scalar @received, 1, 'notification on unsubscribed channel ignored';

# --- unlisten ---

$storage->unlisten('test_channel');
is $pg->{queries}[-1], 'UNLISTEN "test_channel"', 'UNLISTEN sent';

$pg->fire_notify('test_channel', 'after', 1);
is scalar @received, 1, 'handler removed after unlisten';

# --- notify: pg_notify via pooled connection with bind params ---

{
  package MockPool;
  sub new { bless { pg => EV::Pg->new, released => 0 }, shift }
  # acquire returns a Future per the core PoolBase contract; storage's
  # notify() does acquire->then(sub { ... }).
  sub acquire { Future->done($_[0]->{pg}) }
  sub release { $_[0]->{released}++ }
  sub shutdown {}
}

my $pool = MockPool->new;
$storage->{pool} = $pool;

my $f = $storage->notify('test_channel', "it's done");
ok $f->is_done, 'notify future resolves';
is $pool->{pg}{queries}[-1], 'SELECT pg_notify($1, $2)',
  'notify uses pg_notify with placeholders';
is_deeply $pool->{pg}{params}[-1], ['test_channel', "it's done"],
  'channel and payload passed as bind params, no escaping';
is $pool->{released}, 1, 'pooled connection released after notify';

my $f2 = $storage->notify('test_channel');
ok $f2->is_done, 'notify with missing payload resolves';
is_deeply $pool->{pg}{params}[-1], ['test_channel', ''],
  'missing payload sent as empty string';

eval { $storage->notify(undef) };
like $@, qr/Channel name required/, 'notify croaks without channel';

done_testing;
