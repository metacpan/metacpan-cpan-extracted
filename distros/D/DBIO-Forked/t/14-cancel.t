use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);
use Time::HiRes ();

# OFFLINE test: a Future can be ended (cancel), and a Future nobody collects
# ends its child instead of waiting for it (karr k27).
#
# WHY: a child in a slow query writes nothing, so a caller that stops caring
# must be able to end it, and dropping the Future must not hold the process
# until the database answers.
#
# WHAT RUNS FOR REAL: fork + pipe, DBIO::Forked::Storage and its Future.
# THE SUBSTITUTION: a mock sync storage whose ops sleep in the child.
# Time bounds are generous: they tell "ended" from "waited for 5 seconds".

use DBIO::Forked::Storage;
use DBIO::Forked::Future;

alarm 60;

{
  package t::Mock::Storage;
  sub new { bless {}, shift }
  sub select {
    my ($self, $what) = @_;
    if ($what eq 'sleep') { Time::HiRes::sleep(5); return ([ 'late' ]) }
    if ($what eq 'stubborn') {
      $SIG{TERM} = 'IGNORE';
      Time::HiRes::sleep(5);
      return ([ 'late' ]);
    }
    return ([ 'now' ]);
  }

  package t::Mock::Schema;
  sub new { bless { storage => $_[1] }, $_[0] }
  sub storage { $_[0]{storage} }
}

my $schema  = t::Mock::Schema->new(t::Mock::Storage->new);
my $storage = DBIO::Forked::Storage->new($schema);

sub no_children_ok { is waitpid(-1, WNOHANG), -1, $_[0] }

sub timed (&) {
  my $t0 = Time::HiRes::time;
  $_[0]->();
  return Time::HiRes::time - $t0;
}

# --- cancel ends a running child ---------------------------------------------
{
  my $f = $storage->select_async('sleep');
  Time::HiRes::sleep(0.2);
  ok !$f->is_ready, 'the query is still running';
  my $took = timed { $f->cancel };
  cmp_ok $took, '<', 3, "cancel returns well before the child would have ended ($took s)";
  no_children_ok('the child is reaped, no zombie');
  ok $f->is_ready,  'a cancelled Future is resolved';
  ok $f->is_failed, '... and failed';
  eval { $f->get };
  like $@, qr/cancelled/, 'get croaks with a cancelled message';
  eval { $f->get };
  like $@, qr/cancelled/, '... and again';
}

# --- a child that ignores SIGTERM is killed ------------------------------------
{
  my $f = $storage->select_async('stubborn');
  Time::HiRes::sleep(0.3);
  my $took = timed { $f->cancel };
  cmp_ok $took, '<', 4, "SIGKILL follows the grace period ($took s)";
  no_children_ok('the stubborn child is reaped');
  ok $f->is_failed, 'failed';
}

# --- cancel on a resolved Future is a no-op ----------------------------------
{
  my $f = $storage->select_async('quick');
  is_deeply [ $f->get ], [ [ 'now' ] ], 'resolved with the rows';
  $f->cancel;
  ok !$f->is_failed, 'cancel after resolution changes nothing';
  is_deeply [ $f->get ], [ [ 'now' ] ], '... the rows are still there';

  my $d = DBIO::Forked::Future->done(1);
  $d->cancel;
  ok !$d->is_failed, 'cancel on done(): no-op';
}

# --- cancel on a derived Future cancels its source ---------------------------
{
  my $f = $storage->select_async('sleep');
  my $g = $f->then(sub { 'x' });
  my $took = timed { $g->cancel };
  cmp_ok $took, '<', 3, 'derived cancel returns quickly';
  ok $f->is_failed, 'the source failed';
  eval { $g->get };
  like $@, qr/cancelled/, 'the derived Future fails as cancelled';
  no_children_ok('child reaped');
}

# --- only the owner may end the child ----------------------------------------
{
  my $f = $storage->select_async('sleep');
  my $owner = $$;
  pipe(my $r, my $w) or die;
  my $pid = fork // die;
  if (!$pid) {
    close $r;
    eval { $f->cancel };
    print {$w} ($@ =~ /belongs to process $owner/ ? "refused\n" : "allowed: $@\n");
    close $w;
    undef $f;   # the destructor must not touch the owner's child either
    POSIX::_exit(0);
  }
  close $w;
  my $line = <$r>;
  waitpid($pid, 0);
  is $line, "refused\n", 'cancel in another process: belongs to process N';
  ok !$f->is_ready, 'the owner is not affected: the query still runs';
  $f->cancel;
  no_children_ok('the owner ends it');
}

# --- a dropped Future ends its child, it does not wait for it -----------------
{
  my $f = $storage->select_async('sleep');
  Time::HiRes::sleep(0.2);
  my $took = timed { undef $f };
  cmp_ok $took, '<', 3, "dropping a Future with a 5 s child takes no 5 s ($took s)";
  no_children_ok('the child is gone and reaped');
}

# --- the sync wrappers are unchanged ------------------------------------------
is_deeply [ $storage->select('quick') ], [ [ 'now' ] ], 'sync select still blocks and returns';
no_children_ok('no children left');

done_testing;
