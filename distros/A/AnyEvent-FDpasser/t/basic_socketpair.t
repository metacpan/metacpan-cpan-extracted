use common::sense;

use AnyEvent::Strict;
use AnyEvent::FDpasser;

use Test::More tests => 2;


## The point of this test is to create a socketpair, fork, and then
## verify that the $passer object can be used to send and receive
## descriptors.


my $passer = AnyEvent::FDpasser->new( fh => [ AnyEvent::FDpasser::fdpasser_socketpair ] );

my $done_cv = AE::cv;


if (fork) {
  $passer->i_am_parent;

  pipe my $rfh, my $wfh;
  $passer->push_send_fh($wfh);

  my $watcher; $watcher = AE::io $rfh, 0, sub {
    my $text = <$rfh>;
    is($text, "some data 1\n", "send fh from parent -> child ok");
    undef $watcher;

    $passer->push_recv_fh(sub {
      my $fh = shift;
      my $text = <$fh>;
      is($text, "some data 2\n", "send fh from child -> parent ok");
      $done_cv->send;
    });
  };
} else {
  $passer->i_am_child;

  $passer->push_recv_fh(sub {
    my ($fh) = @_;
    print $fh "some data 1\n";
    close($fh);

    pipe my $rfh, my $wfh;
    print $wfh "some data 2\n";
    $passer->push_send_fh($rfh, sub { $done_cv->send; });
  });
}

$done_cv->recv;
