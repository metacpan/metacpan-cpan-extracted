use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Time::HiRes qw(time usleep);
use POSIX qw(_exit);

# Two processes call new($path, ...) on the same new file at nearly the
# same time. flock(LOCK_EX) inside new() must serialize the init, so one
# process creates/initializes and the other reopens the initialized state.
# Neither should see a half-initialized header.

use Data::Pool::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.pool');
close $fh;
unlink $path;   # let new() create the file fresh

pipe(my $r, my $w) or die;

my @pids;
for (1..2) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $w;
        sysread($r, my $go, 1);         # starting gun
        my $p = eval { Data::Pool::Shared::I64->new($path, 32) };
        _exit(1) unless $p;
        my $s = $p->alloc;
        $p->set($s, $$);
        _exit(0);
    }
    push @pids, $pid;
}
close $r;

usleep 100_000;   # let both children hit the pipe read
syswrite($w, "G");
syswrite($w, "G");
close $w;

my $ok = 0;
for my $pid (@pids) {
    waitpid $pid, 0;
    $ok++ if $? == 0;
}
is $ok, 2, "both racing inits succeeded cleanly";

# Reopen and verify 2 slots used
my $p = Data::Pool::Shared::I64->new($path, 32);
is $p->used, 2, "both processes allocated a slot (no half-init corruption)";

done_testing;
