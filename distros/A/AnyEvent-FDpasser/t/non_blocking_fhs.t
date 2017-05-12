use common::sense;

use Fcntl qw(F_GETFL O_NONBLOCK);;

use AnyEvent::Strict;
use AnyEvent::Util;
use AnyEvent::FDpasser;

use Test::More tests => 8;


## The point of this test is to ensure some assumptions about when file
## descriptors are set to non-blocking mode.

my $done_cv = AE::cv;


sub is_nonblocking {
  my $fh = shift;

  my $flags = fcntl($fh, F_GETFL, 0) || die "couldn't fcntl(F_GETFL): $!";

  return !!($flags & O_NONBLOCK);
}


my ($fh1, $fh2) = AnyEvent::FDpasser::fdpasser_socketpair or die "can't make socketpair: $!";

## fdpasser_socketpair doesn't set sockets to be non-blocking (just like normal socketpair/pipe)

ok(!is_nonblocking($fh1), 'fdpasser_socketpair starts with blocking fh1');
ok(!is_nonblocking($fh2), 'fdpasser_socketpair starts with blocking fh2');

AnyEvent::Util::fh_nonblocking $fh1, 1;
ok(is_nonblocking($fh1), 'fh_nonblocking sets to 1 ok');

AnyEvent::Util::fh_nonblocking $fh1, 0;
ok(!is_nonblocking($fh1), 'fh_nonblocking sets back to 0 ok');

AnyEvent::Util::fh_nonblocking $fh1, 1;
AnyEvent::Util::fh_nonblocking $fh2, 1;



if (fork) {
  my $passer = AnyEvent::FDpasser->new( fh => $fh1, );
  close($fh2);

  pipe my $rfh, my $wfh;
  ok(!is_nonblocking($wfh), 'pipe starts non blocking');
  AnyEvent::Util::fh_nonblocking $wfh, 1;
  $passer->push_send_fh($wfh);

  my $watcher; $watcher = AE::io $rfh, 0, sub {
    my $text = <$rfh>;
    chomp $text;

    if ($text =~ m/^results (Y|N) (Y|N)/) {
      my $on_fork = $1;
      my $on_sendmsg = $2;

      ok(1, "parsed results");

      ok($on_fork eq 'Y', "nonblockingness preserved on fork");
      ok($on_sendmsg eq 'Y', "nonblockingness preserved on sendmsg");
    } else {
      ok(0, "can't parse results");
    }

    undef $watcher;
    $done_cv->send;
  };
} else {
  my $is_nonblocking_preserved_on_fork = is_nonblocking($fh2);

  my $passer = AnyEvent::FDpasser->new( fh => $fh2, );
  close($fh1);

  $passer->push_recv_fh(sub {
    my $fh = shift;

    my $is_nonblocking_preserved_through_sendmsg = is_nonblocking($fh);

    print $fh "results " . ($is_nonblocking_preserved_on_fork ? 'Y' : 'N') . " "
                          . ($is_nonblocking_preserved_through_sendmsg ? 'Y' : 'N') . "\n";

    $done_cv->send;
  });
}

$done_cv->recv;
