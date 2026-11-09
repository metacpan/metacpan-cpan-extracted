use strict;
use warnings;
use Test::More;

# OFFLINE regression for core karr k407: a pooled call that has to wait for the
# pool hands its caller the Future of a `$pool->acquire->then(...)` sequence,
# and Future.pm holds such a sequence only weakly from the acquire Future that
# still waits. A caller that lets go of it while the pool is full (a
# fire-and-forget call) lost the chain: "lost a sequence Future", the body
# never ran, and the connection it would have borrowed was never released --
# every later call queued behind it for good.
#
# So: a pool of ONE, its connection busy; a select_async and an insert_async
# are started and their Futures DROPPED; when the connection is free again both
# still run (the statements reach the wire, in order), nothing is warned, and a
# third call, which is kept, gets the connection. EV::MariaDB is HoldMDB, which
# answers nothing by itself; the test fires the callbacks.

use EV;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

{
  package HoldMDB;
  use Carp ();
  use Socket ();

  our @SENT;   # { sql, cb } of every statement handed to the handle

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, connected => 0 }, $class;
    socketpair($self->{sock}[0], $self->{sock}[1], Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $self->{connected} = 1; $self->{on_connect}->() });
    return $self;
  }

  sub is_connected  { $_[0]{connected} }
  sub socket        { fileno $_[0]{sock}[0] }
  sub pending_count { 0 }
  sub finish        { $_[0]{connected} = 0; return }
  sub close_async   { return }
  sub query         { my ($self, $sql, $cb) = @_; push @SENT, { sql => $sql, cb => $cb }; return }
  sub reset_connection { my ($self, $cb) = @_; my $t; $t = EV::timer(0.001, 0, sub { undef $t; $cb->(1, undef) }); return }
}

{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Pool::_new_connection = sub { shift; HoldMDB->new(@_) };
}

alarm 60;

# Run the loop until $cond is true; the timer is the upper bound, never a hang.
sub wait_for {
  my ($cond) = @_;
  my $over = 0;
  EV::now_update();
  my $dog = EV::timer(3, 0, sub { $over = 1 });
  EV::run(EV::RUN_ONCE()) until $cond->() || $over;
  return $cond->() ? 1 : 0;
}

sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my $storage = DBIO::MySQL::EV::Storage->new(undef);
$storage->connect_info([ { host => 'fake', database => 'fake', pool_size => 1 }, {} ]);

# The one connection is busy: a statement is in flight on it.
my $first = $storage->select_async('thing', [qw( id )], {});
ok wait_for(sub { @HoldMDB::SENT == 1 }), 'the first statement is in flight on the only connection';

# Two calls queue for the pool, and their Futures are let go.
$storage->select_async('thing', [qw( id )], {});
$storage->insert_async('thing', {});
settle();
is scalar @HoldMDB::SENT, 1, 'both wait: the pool of one is full';

# The connection is free again.
$HoldMDB::SENT[0]{cb}->([ [ 1 ] ]);
ok $first->is_ready || wait_for(sub { $first->is_ready }), 'the first statement is answered';

ok wait_for(sub { @HoldMDB::SENT >= 2 }), 'the dropped select still reaches the wire';
like $HoldMDB::SENT[1]{sql}, qr/^SELECT/i, '... and it is the select';
$HoldMDB::SENT[1]{cb}->([ [ 2 ] ]) if $HoldMDB::SENT[1];

ok wait_for(sub { @HoldMDB::SENT >= 3 }), 'the dropped insert still reaches the wire';
like $HoldMDB::SENT[2]{sql}, qr/^INSERT/i, '... and it is the insert';
$HoldMDB::SENT[2]{cb}->(1) if $HoldMDB::SENT[2];
ok wait_for(sub { @HoldMDB::SENT >= 4 }), 'the insert reads LAST_INSERT_ID() on its connection';
$HoldMDB::SENT[3]{cb}->([ [ 7 ] ]) if $HoldMDB::SENT[3];

# A third, kept call gets the connection: nothing the dropped ones borrowed
# stayed borrowed.
my $third = $storage->select_async('thing', [qw( id )], {});
ok wait_for(sub { @HoldMDB::SENT >= 5 }), 'the third call gets the connection';
$HoldMDB::SENT[4]{cb}->([ [ 3 ] ]) if $HoldMDB::SENT[4];
ok wait_for(sub { $third->is_ready }), 'the third call settles';
is_deeply [ $third->get ], [ [ 3 ] ], '... with its rows' if $third->is_done;

settle();
is_deeply [ grep { /lost a sequence/i } @warnings ], [], 'no "lost a sequence Future"';
is_deeply \@warnings, [], 'nothing is warned';

$storage->disconnect;
done_testing;
