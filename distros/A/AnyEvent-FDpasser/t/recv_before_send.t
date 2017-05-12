use common::sense;

use Time::HiRes;

use AnyEvent::Strict;
use AnyEvent::FDpasser;

use Test::More tests => 3;


## The point of this test is to verify that push_recv_fh can be called before
## there is any fh waiting to be received and the process will not block.

## WARNING: this test relied on timers and is not fully deterministic



my $passer = AnyEvent::FDpasser->new;

my $done_cv = AE::cv;


if (fork) {
  $passer->i_am_parent;

  my $start_time = Time::HiRes::time;
  my $nonblocking_check;

  my $watcher; $watcher = AE::timer 0.05, 0, sub {
    undef $watcher;
    $nonblocking_check = 1;
    ok(Time::HiRes::time < $start_time + 0.08, 'happened on time');
  };

  $passer->push_recv_fh(sub {
    my $fh = shift;
    undef $watcher;
    ok($nonblocking_check, "happened in right order");

    my $text = <$fh>;
    is($text, "hooray\n", 'got data');
    $done_cv->send;
  });
} else {
  $passer->i_am_child;

  my $watcher; $watcher = AE::timer 0.1, 0, sub {
    undef $watcher;
    pipe my $rfh, my $wfh;
    print $wfh "hooray\n";
    $passer->push_send_fh($rfh, sub { $done_cv->send; });
  };
}

$done_cv->recv;
