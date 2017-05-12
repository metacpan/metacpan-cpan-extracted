use common::sense;

use AnyEvent::Strict;
use AnyEvent::FDpasser;

use Test::More tests => 4;


## The point of this test is to buffer several descriptors onto the passer
## object (immediately and with delays between bufferings) and then ensure
## that the other side of the passer gets all the descriptors in the right
## order.


my $passer = AnyEvent::FDpasser->new;

my $done_cv = AE::cv;


if (!fork) {
  $passer->i_am_child;

  for my $i (1..3) {
    pipe my $rfh, my $wfh;
    print $wfh "hello $i\n";
    $passer->push_send_fh($rfh);
  }

  my $watcher; $watcher = AE::timer 0.1, 0, sub {
    undef $watcher;
    pipe my $rfh, my $wfh;
    print $wfh "hello 4\n";
    $passer->push_send_fh($rfh);

    pipe my $rfh, my $wfh;
    print $wfh "hello 5\n";
    $passer->push_send_fh($wfh);

    $passer->push_recv_fh(sub {
      my $fh = shift;
      my $text = <$fh>;
      die "didn't get it all" unless $text eq "got it all\n";
      $done_cv->send;
    });
  };
} else {
  $passer->i_am_parent;

  for my $i (1..2) {
    $passer->push_recv_fh(sub {
      my ($fh) = @_;
      my $text = <$fh>;
      is($text, "hello $i\n", "got pipe $i");
    });
  }

  my $watcher; $watcher = AE::timer 0.15, 0, sub {
    undef $watcher;

    $passer->push_recv_fh(sub {
      my ($fh) = @_;
      my $text = <$fh>;
      is($text, "hello 3\n", "got pipe 3");
    });

    $passer->push_recv_fh(sub {
      my ($fh) = @_;
      my $text = <$fh>;
      is($text, "hello 4\n", "got pipe 4");

      pipe my $rfh, my $wfh;
      print $wfh "got it all\n";
      $passer->push_send_fh($rfh, sub { $done_cv->send; });
    });
  };
}

$done_cv->recv;
