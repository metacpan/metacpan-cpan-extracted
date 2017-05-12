#! perl

no warnings;

print "1..14\n"; $|=1;

use Async::Interrupt;

my $ai = new Async::Interrupt
   cb => sub { print "ok $_[0]\n" };

my $fd = $ai->pipe_fileno;

print "ok 1\n";
$ai->signal (2);
print "ok 3\n";

my ($vr, $vR); vec ($vr, $ai->pipe_fileno, 1) = 1;

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

$ai->signal (14);

my $n = select $vR=$vr, undef, undef, 0;
print $n == 0 ? "" : "not ", "ok 11 # $n\n";

$ai->post_fork;

print $fd == $ai->pipe_fileno ? "" : "not ", "ok 12\n";
$ai->post_fork;

print $fd == $ai->pipe_fileno ? "" : "not ", "ok 13\n";

undef $ai; # will cause signal to be sent

