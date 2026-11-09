use strict;
use warnings;
use Test::More;

# Mock EV::Pg so we don't need a real PostgreSQL. Must be set up before the
# runtime `require EV::Pg` in DBIO::PostgreSQL::EV::Pool::_new_connection,
# which builds the dedicated LISTEN connection (karr k43).
#
# karr k43 moved listen / unlisten / notify to core (ADR 0056); this transport
# fills the listen seams. Every claim this file made is kept, asserted on what
# the fake connection records instead of on the removed internals
# (_listen_pg, _listen_pending): the connection is still dedicated and made on
# the first listen, nothing is sent before it is connected, LISTEN / UNLISTEN
# are quoted, dispatch is ($channel, $payload, $pid), notify is a pooled
# pg_notify with binds. The one text that changed is the refusal of a missing
# channel, now core's. t/38-listen-seams-mock.t covers the seams in depth.
our @HANDLES;
BEGIN {
  package EV::Pg;
  sub new {
    my ($class, %args) = @_;
    my $self = bless { %args, queries => [], params => [] }, $class;
    push @main::HANDLES, $self;
    return $self;
  }
  for my $h (qw( on_connect on_error on_notify )) {
    no strict 'refs';
    *{"EV::Pg::$h"} = sub { my $s = shift; $s->{$h} = $_[0] if @_; return $s->{$h} };
  }
  sub is_connected { $_[0]->{connected} ? 1 : 0 }
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
  # The mock lacked finish, part of the real EV::Pg API that disconnect
  # calls; record the call so the disconnect test can assert on it (k42).
  sub finish { $_[0]->{finished}++ }
  sub connect_ok { $_[0]->{connected} = 1; $_[0]->{on_connect}->() }
  sub fire_notify {
    my ($self, $ch, $payload, $pid) = @_;
    $self->{on_notify}->($ch, $payload, $pid) if $self->{on_notify};
  }
  $INC{'EV/Pg.pm'} = __FILE__;
}

use DBIO::PostgreSQL::EV::Storage;

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ { host => 'localhost', dbname => 'test' } ]);

# --- listen: dedicated connection, nothing sent until connected ---

my @received;
$storage->listen(test_channel => sub { push @received, [@_] });

is scalar(@HANDLES), 1, 'dedicated LISTEN connection created on first listen';
my $pg = $HANDLES[0];
is_deeply $pg->{queries}, [], 'LISTEN held back while not yet connected';

$pg->connect_ok;
is_deeply $pg->{queries}, ['LISTEN "test_channel"'],
  'quoted LISTEN sent on connect';

$storage->listen(other_channel => sub {});
is $pg->{queries}[-1], 'LISTEN "other_channel"',
  'subsequent LISTEN sent immediately once connected';
is scalar(@HANDLES), 1, 'no second connection created';

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
  sub _lease  { 1 }   # the lease of a borrow (core k275, karr k89)
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
like $@, qr/requires a channel name/, 'notify croaks without channel (core refusal)';

# --- disconnect: tears down the dedicated LISTEN connection ---

$storage->disconnect;
is $pg->{finished}, 1, 'disconnect finishes the dedicated LISTEN connection once';
ok !defined $storage->{_listen}, 'listen state dropped';

done_testing;
