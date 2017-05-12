use common::sense;

use AnyEvent::Strict;
use AnyEvent::FDpasser;

use Test::More tests => 1;


## The point of this test is to ensure that a socket close error is properly
## detected and reported by the on_error callback.


my $done_cv = AE::cv;

my $passer = AnyEvent::FDpasser->new( on_error => sub {
                                        my $err = $@;
                                        ok(1, "error callback triggered ok ($err)");
                                        $done_cv->send;
                                      },
                                    );


if (fork) {
  $passer->i_am_parent;

  pipe my $rfh, my $wfh;
  print $wfh "hooray\n";
  $passer->push_send_fh($rfh);

  $passer->push_recv_fh(sub {
    ok(0, "received fh?");
    $done_cv->send;
  });
} else {
  $passer->i_am_child;

  my $watcher; $watcher = AE::timer 0.02, 0, sub {
    undef $watcher;
    $done_cv->send;
  };
}

$done_cv->recv;
