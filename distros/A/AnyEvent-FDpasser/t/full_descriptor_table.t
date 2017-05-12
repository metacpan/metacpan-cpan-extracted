use common::sense;

use AnyEvent::Strict;
use AnyEvent::FDpasser;

use Test::More;

eval { require BSD::Resource };

if (!$@) {
  plan tests => 1;
} else {
  plan skip_all => 'Install BSD::Resource to run this test';
}


## The point of this test is to exercise the full file descriptor code 
## and verify that no descriptors are lost.



my $passer = AnyEvent::FDpasser->new;

my $done_cv = AE::cv;


if (fork) {
  $passer->i_am_parent;

  for my $curr (1 .. 30) {
    pipe my $rfh, my $wfh;
    print $wfh "descriptor $curr\n";
    $passer->push_send_fh($rfh);
  }

  $passer->push_recv_fh(sub {
    my $fh = shift;
    my $text = <$fh>;
    is($text, "hooray\n", 'got 30');
    $done_cv->send;
  });
} else {
  $passer->i_am_child;

  my $next_desc = 1;
  my @descriptors;

  my $watcher; $watcher = AE::timer 0.5, 0.5, sub {
    $watcher;
    close($_) foreach (@descriptors);
    @descriptors = ();
  };

  BSD::Resource::setrlimit('RLIMIT_NOFILE', 20, 20);

  for my $curr (1 .. 30) {
    $passer->push_recv_fh(sub {
      my $fh = shift;

      my $text = <$fh>;
      die "bad descriptor order" unless $text eq "descriptor $next_desc\n";

      $next_desc++;
      push @descriptors, $fh;

      if ($curr == 30) {
        undef @descriptors; ## otherwise pipe() below may fail
        pipe my $rfh, my $wfh;
        print $wfh "hooray\n";
        $passer->push_send_fh($rfh, sub { $done_cv->send; });
      }
    });
  }
}

$done_cv->recv;
