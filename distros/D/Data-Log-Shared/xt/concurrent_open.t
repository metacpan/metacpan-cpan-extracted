use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use POSIX qw(_exit);
use Time::HiRes qw(usleep);

# Two processes concurrently call new() on a fresh file. flock must
# serialize init; no half-initialized header visible.

use Data::Log::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.bs');
close $fh;
unlink $path;

pipe(my $r, my $w) or die;

my @pids;
for (1..2) {
    my $pid = fork // die;
    if (!$pid) {
        close $w;
        sysread($r, my $go, 1);
        my $b = eval { Data::Log::Shared->new($path, 4096) };
        _exit($b ? 0 : 1);
    }
    push @pids, $pid;
}
close $r;
usleep 50_000;
syswrite($w, "G") for 1..2;
close $w;

my $ok = 0;
for (@pids) { waitpid $_, 0; $ok++ if $? == 0 }
is $ok, 2, "both racing opens succeeded";

done_testing;
