#! perl

no warnings;

use Socket;

my ($pr, $pw);

unless (socketpair $pr, $pw, Socket::AF_UNIX (), Socket::SOCK_STREAM (), 0) {
   print "1..0 # SKIP socketpair failed - broken platform, skipping tests\n";
   exit;
}
   
print "1..12\n"; $|=1;

use Async::Interrupt;

# we ignore the requirement to put handles into nonblocking mode
# IN THIS TEST only. never do that in real life.
my $ai = new Async::Interrupt
   pipe => [$pr, $pw],
   cb   => sub { print "ok $_[0]\n" };

print "ok 1\n";
$ai->signal (2);
print "ok 3\n";

my ($vr, $vR); vec ($vr, fileno $pr, 1) = 1;

my $n = select $vR=$vr, undef, undef, 0;
print $n == 0 ? "" : "not ", "ok 4 # $n\n";

$ai->block;
$ai->signal (7);
print "ok 5\n";
my $n = select $vR=$vr, undef, undef, 0;
print $n == 1 ? "" : "not ", "ok 6 # $n\n";
$ai->unblock;

my $n = select $vR=$vr, undef, undef, 0;
print $n == 0 ? "" : "not ", "ok 8 # $n\n";

$ai->signal (9);

my $n = select $vR=$vr, undef, undef, 0;
print $n == 0 ? "" : "not ", "ok 10 # $n\n";

$ai->pipe_disable;
$ai->scope_block;

$ai->signal (12);

my $n = select $vR=$vr, undef, undef, 0;
print $n == 0 ? "" : "not ", "ok 11 # $n\n";

undef $ai; # will cause signal to be sent

