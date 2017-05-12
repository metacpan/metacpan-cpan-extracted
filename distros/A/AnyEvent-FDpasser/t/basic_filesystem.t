use common::sense;

use AnyEvent::Strict;
use AnyEvent::FDpasser;

use Test::More tests => 2;


## The point of this test is to verify that fdpasser_server and fdpasser_connect can
## create sockets suitable for use with FDpasser.


my $path = '/tmp/fdpasser_junk_socket';

my $done_cv = AE::cv;


if (fork) {
  my $server_fh = AnyEvent::FDpasser::fdpasser_server($path);

  my $watcher; $watcher = AE::io $server_fh, 0, sub {
    undef $watcher;

    my $passer_fh = AnyEvent::FDpasser::fdpasser_accept($server_fh) || die "couldn't accept: $!";
    my $passer = AnyEvent::FDpasser->new( fh => $passer_fh, );

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
        unlink($path);
        $done_cv->send;
      });
    };
  };
} else {
  my $watcher; $watcher = AE::timer 0.5, 0, sub {
    undef $watcher;

    my $passer = AnyEvent::FDpasser->new( fh => AnyEvent::FDpasser::fdpasser_connect($path), );

    $passer->push_recv_fh(sub {
      my ($fh) = @_;
      print $fh "some data 1\n";
      close($fh);

      pipe my $rfh, my $wfh;
      print $wfh "some data 2\n";
      $passer->push_send_fh($rfh, sub { $done_cv->send; });
    });
  };
}

$done_cv->recv;
