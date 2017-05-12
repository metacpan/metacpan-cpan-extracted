use common::sense;

use AnyEvent::Strict;
use AnyEvent::FDpasser;
use AnyEvent::Util;

use Test::More tests => 1;


## The point of this somewhat esoteric test is to verify that you can
## send passer sockets (AF_UNIX sockets) themselves over a passer object.

## To do this, we setup a passer object between a parent and child,
## create a socketpair in the parent, and then send this socket to the
## child over the passer object. The parent and children both use their
## respective ends of the socketpair to instantiate another passer object
## over which a pipe is sent.



my $passer = AnyEvent::FDpasser->new;

my $done_cv = AE::cv;


if (fork) {
  $passer->i_am_parent;

  my ($passer2_fh1, $passer2_fh2) = AnyEvent::FDpasser::fdpasser_socketpair or die "can't make socketpair: $!";
  AnyEvent::Util::fh_nonblocking $passer2_fh1, 1;

  my $passer2 = AnyEvent::FDpasser->new( fh => $passer2_fh1, );

  $passer->push_send_fh($passer2_fh2);

  $passer2->push_recv_fh(sub {
    my $fh = shift;
    my $text = <$fh>;
    is($text, "hooray\n", "got final data");
    $done_cv->send;
  });


} else {
  $passer->i_am_child;

  $passer->push_recv_fh(sub {
    my ($passer2_fh1) = @_;

    AnyEvent::Util::fh_nonblocking $passer2_fh1, 1;

    my $passer2 = AnyEvent::FDpasser->new( fh => $passer2_fh1, );

    pipe my $rfh, my $wfh;
    print $wfh "hooray\n";
    $passer2->push_send_fh($rfh, sub { $done_cv->send; });
  });

}

$done_cv->recv;
