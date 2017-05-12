#! perl

no warnings;

print "1..6\n"; $|=1;

use Async::Interrupt;

my $ep = new Async::Interrupt::EventPipe;

my $fd = $ep->fileno;

print "ok 1\n";

my ($vr, $vR); vec ($vr, $fd, 1) = 1;

my $n = select $vR=$vr, undef, undef, 0;

print $n == 0 ? "" : "not ", "ok 2 # $n\n";

$ep->signal;

my $n = select $vR=$vr, undef, undef, 0;
print $n == 1 ? "" : "not ", "ok 3 # $n\n";

$ep->drain;

my $n = select $vR=$vr, undef, undef, 0;
print $n == 0 ? "" : "not ", "ok 4 # $n\n";

print "ok 5 # ", join " ", $ep->signal_func, "\n";
print "ok 6 # ", join " ", $ep->drain_func, "\n";
