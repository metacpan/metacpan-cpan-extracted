use common::sense;

use Time::HiRes;

use AnyEvent::Strict;
use AnyEvent::FDpasser;

use Test::More tests => 2;


## The point of this test is to verify that push_send_fh can be called before
## there is any process on the other end calling push_recv_fh and the process
## will not block.

## WARNING: this test relied on timers and is not fully deterministic



my $passer = AnyEvent::FDpasser->new;

my $done_cv = AE::cv;


if (fork) {
  $passer->i_am_parent;

  my $start_time = Time::HiRes::time;

  pipe my $rfh, my $wfh;
  print $wfh "hooray\n";
  $passer->push_send_fh($rfh);

  my $watcher; $watcher = AE::timer 0.1, 0, sub {
    undef $watcher;
    ok(Time::HiRes::time < $start_time + 0.18, 'happened on time');
  };

  $passer->push_recv_fh(sub {
    my $fh = shift;
    my $text = <$fh>;
    is($text, "hooray\n", 'got data');
    $done_cv->send;
  });
} else {
  $passer->i_am_child;

  my $watcher; $watcher = AE::timer 0.2, 0, sub {
    undef $watcher;
    pipe my $rfh, my $wfh;
    print $wfh "hooray\n";
    $passer->push_send_fh($rfh, sub { $done_cv->send; });
  };
}

$done_cv->recv;
