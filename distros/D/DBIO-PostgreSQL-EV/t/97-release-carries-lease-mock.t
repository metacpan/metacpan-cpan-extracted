use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr );

# OFFLINE test for karr k89, this transport's half of core k275 (dbio
# e8190200c, t/storage/pool_double_release.t and t/test/58_async_release_
# carries_lease.t there): a release that arrives after its connection went on
# is told from its holder's by the lease of the borrow.
#
# WHY: PoolBase::release takes any connection the pool holds. A completion
# that runs a second time -- EV::Pg calls a statement's callback again where
# it queued it twice, as it does for a COPY, or a late "connection lost" after
# the answer -- released the connection a second time, and by then the
# connection belonged to somebody else: handed on to a queued caller, or
# borrowed again from idle. The second release took it from its new holder and
# gave the one session to a second caller, whose statements then interleaved
# on it. Every place of this transport that ends pooled work asks the pool for
# the lease of its borrow right after the acquire ($pool->_lease($pg)) and
# releases with it; a release whose lease is no longer the connection's is
# silent.
#
# The claims:
#   1. A completion fired a second time, after the connection was handed to a
#      queued caller and another is queued behind it, does not hand the
#      session to the one behind.
#   2. The same with nobody else queued: the connection is not put on the idle
#      list under its holder.
#   3. The same after the connection was idled and borrowed again.
#   4. Every release this transport makes -- statement, notify, copy_in, and
#      the dispatches EV::Pg refuses -- passes the lease of its own borrow.
#
# THE ONE SUBSTITUTION is EV::Pg itself (as in t/75): a fake the real pool
# builds through its real constructor. It answers nothing by itself; the test
# fires the callbacks it queued, in the order and as often as it wants.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our @SENT;      # every statement sent: { id, sql, cb }
  our $REFUSE;    # true: a dispatch croaks "not connected" (EV::Pg does, before it queues)
  my $ID = 0;

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, up => 0, id => ++$ID }, $class;
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub is_connected  { $_[0]{up} ? 1 : 0 }
  sub pending_count { 0 }
  sub socket        { -1 }
  sub error_message { undef }
  sub finish        { $_[0]{up} = 0; return }

  sub _send {
    my ($self, $sql, $cb) = @_;
    Carp::croak('not connected') if $REFUSE || !$self->{up};
    push @SENT, { id => $self->{id}, sql => $sql, cb => $cb };
    return;
  }

  sub query_params { my ($self, $sql, $bind, $cb) = @_; $self->_send($sql, $cb) }
  sub query        { my ($self, $sql, $cb) = @_; $self->_send($sql, $cb) }
  sub put_copy_data { 1 }
  sub put_copy_end  { 1 }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;
use DBIO::PostgreSQL::EV::Pool;

alarm 60;

my @SELECT = ('thing', [qw( id name )], {});
my $POOL   = 'DBIO::PostgreSQL::EV::Pool';

# Every release the pool is given: the lease it came with and the connection's
# current one at that moment.
my @RELEASES;
{
  no strict 'refs';
  my $orig = $POOL->can('release');
  *{"${POOL}::release"} = sub {
    my ($self, $conn, @rest) = @_;
    push @RELEASES, {
      args    => scalar @rest,
      lease   => $rest[0],
      current => $self->{_leases}{ refaddr($conn) },
    };
    goto &$orig;
  };
}

# Run the loop a little, so whatever is due has happened.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.02, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# Run until $n statements have been sent, at most 2 seconds.
sub until_sent {
  my ($n) = @_;
  my $deadline = EV::time() + 2;
  settle() while @EV::Pg::SENT < $n && EV::time() < $deadline;
  settle();
  return;
}

# Call a queued statement's callback, as EV::Pg does. A completion that finds
# its Future settled already dies out of it, which EV::Pg only warns.
sub fire {
  my ($entry, @result) = @_;
  eval { $entry->{cb}->(@result); 1 } or return $@;
  return '';
}

sub answer_ok { fire($_[0], [ [ 1, 'one' ] ]) }

sub new_storage {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 1 } ]);
  @EV::Pg::SENT = ();
  @RELEASES     = ();
  $EV::Pg::REFUSE = 0;
  return $storage;
}

# -----------------------------------------------------------------------------
# 1. Handed to a queued caller, another queued behind it.
# -----------------------------------------------------------------------------
{
  my $l = 'stale completion after the hand-over, a caller behind';
  my $storage = new_storage();
  my $s1 = $storage->select_async(@SELECT);
  my $s2 = $storage->select_async(@SELECT);
  my $s3 = $storage->select_async(@SELECT);
  until_sent(1);
  is scalar @EV::Pg::SENT, 1, "$l: one statement on the one connection, two wait";
  my $first = $EV::Pg::SENT[0];

  answer_ok($first);
  until_sent(2);
  is scalar @EV::Pg::SENT, 2, "$l: the first release hands the connection to the oldest waiter";
  ok $s1->is_done, "$l: and the first statement is done";

  answer_ok($first);   # the stale one
  settle();
  is scalar @EV::Pg::SENT, 2,
    "$l: the stale completion does not hand the session to the caller behind";
  ok !$s3->is_ready, "$l: that caller waits for the holder's release";

  answer_ok($EV::Pg::SENT[1]);
  until_sent(3);
  is scalar @EV::Pg::SENT, 3, "$l: the holder's own release hands it on";
  is $EV::Pg::SENT[2]{id}, $EV::Pg::SENT[1]{id}, "$l: ... on the same connection";
  answer_ok($EV::Pg::SENT[2]);
  ok $s2->is_done && $s3->is_done, "$l: all three statements are answered";
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 2. Handed to a queued caller, nobody else queued.
# -----------------------------------------------------------------------------
{
  my $l = 'stale completion after the hand-over, nobody behind';
  my $storage = new_storage();
  my $s1 = $storage->select_async(@SELECT);
  my $s2 = $storage->select_async(@SELECT);
  until_sent(1);
  my $first = $EV::Pg::SENT[0];

  answer_ok($first);
  until_sent(2);
  is scalar @EV::Pg::SENT, 2, "$l: the connection went to the queued statement";

  answer_ok($first);   # the stale one
  settle();
  is $storage->pool->available, 0,
    "$l: the connection is not on the idle list, its holder has it";

  my $s3 = $storage->select_async(@SELECT);
  settle();
  is scalar @EV::Pg::SENT, 2, "$l: a statement that comes now waits for the holder";
  ok !$s3->is_ready, "$l: and is pending";

  answer_ok($EV::Pg::SENT[1]);
  until_sent(3);
  is scalar @EV::Pg::SENT, 3, "$l: it goes out when the holder releases";
  answer_ok($EV::Pg::SENT[2]);
  ok $s2->is_done && $s3->is_done, "$l: everything is answered";
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 3. Idled by the first release, borrowed again before the second.
# -----------------------------------------------------------------------------
{
  my $l = 'stale completion after the connection was borrowed again';
  my $storage = new_storage();
  my $s1 = $storage->select_async(@SELECT);
  until_sent(1);
  my $first = $EV::Pg::SENT[0];
  answer_ok($first);
  settle();
  is $storage->pool->available, 1, "$l: the connection is idle";

  my $s2 = $storage->select_async(@SELECT);
  until_sent(2);
  is scalar @EV::Pg::SENT, 2, "$l: the next statement borrowed it from idle";

  answer_ok($first);   # the stale one
  settle();
  is $storage->pool->available, 0, "$l: the borrowed connection is not idled under its holder";

  my $s3 = $storage->select_async(@SELECT);
  settle();
  is scalar @EV::Pg::SENT, 2, "$l: the statement behind waits, the session is not shared";
  ok !$s3->is_ready, "$l: and is pending";

  answer_ok($EV::Pg::SENT[1]);
  until_sent(3);
  is scalar @EV::Pg::SENT, 3, "$l: it goes out when the holder releases";
  answer_ok($EV::Pg::SENT[2]);
  ok $s2->is_done && $s3->is_done, "$l: everything is answered";
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 4. Every release of this transport carries the lease of its borrow.
# -----------------------------------------------------------------------------
sub carries_lease {
  my ($l, $count) = @_;
  is scalar @RELEASES, $count, "$l: released $count time(s)";
  for my $i (0 .. $#RELEASES) {
    my $rel = $RELEASES[$i];
    is $rel->{args}, 1, "$l: release $i passes a lease";
    ok defined $rel->{lease}, "$l: release $i: a defined one";
    is $rel->{lease}, $rel->{current}, "$l: release $i: the one of the borrow it ends";
  }
}

{
  my $storage = new_storage();
  my $f = $storage->select_async(@SELECT);
  until_sent(1);
  answer_ok($EV::Pg::SENT[0]);
  carries_lease('select_async answered', 1);
  $storage->disconnect;
}

{
  my $storage = new_storage();
  my $f = $storage->select_async(@SELECT);
  until_sent(1);
  fire($EV::Pg::SENT[0], undef, qq{ERROR:  relation "thing" does not exist\n});
  ok $f->is_failed, 'select_async failed: the Future failed';
  carries_lease('select_async failed', 1);
  $storage->disconnect;
}

{
  my $storage = new_storage();
  my $f = $storage->notify('chan', 'payload');
  until_sent(1);
  fire($EV::Pg::SENT[0], [ [1] ]);
  ok $f->is_done, 'notify answered: done';
  carries_lease('notify answered', 1);
  $storage->disconnect;
}

{
  my $storage = new_storage();
  my $warm = $storage->select_async(@SELECT);   # opens the connection
  until_sent(1);
  answer_ok($EV::Pg::SENT[0]);
  @RELEASES = ();

  $EV::Pg::REFUSE = 1;
  my $f = $storage->select_async(@SELECT);
  settle();
  $EV::Pg::REFUSE = 0;
  ok $f->is_failed, 'select_async refused at dispatch: the Future failed';
  carries_lease('select_async refused at dispatch', 1);

  @RELEASES = ();
  $EV::Pg::REFUSE = 1;
  my $n = $storage->notify('chan', 'payload');
  settle();
  $EV::Pg::REFUSE = 0;
  ok $n->is_failed, 'notify refused at dispatch: the Future failed';
  carries_lease('notify refused at dispatch', 1);

  @RELEASES = ();
  $EV::Pg::REFUSE = 1;
  my $c = $storage->copy_in('thing', [qw( id name )], sub { });
  settle();
  $EV::Pg::REFUSE = 0;
  ok $c->is_failed, 'copy_in refused at dispatch: the Future failed';
  carries_lease('copy_in refused at dispatch', 1);
  $storage->disconnect;
}

{
  my $storage = new_storage();
  my $c = $storage->copy_in('thing', [qw( id name )], sub { $_[0]->([ 1, 'one' ]) });
  until_sent(1);
  my $copy = $EV::Pg::SENT[0];
  fire($copy, 'COPY_IN');
  fire($copy, '1');
  ok $c->is_done, 'copy_in answered: done';
  carries_lease('copy_in answered', 1);
  $storage->disconnect;
}

{
  my $storage = new_storage();
  my $c = $storage->copy_in('thing', [qw( id name )], sub { die "coderef died\n" });
  until_sent(1);
  my $copy = $EV::Pg::SENT[0];
  fire($copy, 'COPY_IN');
  fire($copy, undef, "ERROR:  COPY from stdin failed: coderef died\n");
  ok $c->is_failed, 'copy_in with a dying coderef: failed';
  carries_lease('copy_in with a dying coderef', 1);
  $storage->disconnect;
}

done_testing;
