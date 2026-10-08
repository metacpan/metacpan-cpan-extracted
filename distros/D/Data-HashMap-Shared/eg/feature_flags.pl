#!/usr/bin/env perl
use strict;
use warnings;
use POSIX ();
use Data::HashMap::Shared::SI;   # flag name -> 0/1

# One writer, many lock-free readers: reads take the seqlock fast path (no
# write lock), so workers can poll a flag with negligible contention.

$| = 1;                                       # autoflush (children print + _exit)
my $path  = "/tmp/dhms_flags_$$.shm";
my $flags = Data::HashMap::Shared::SI->new($path, 100);
shm_si_put $flags, 'new_checkout', 0;
shm_si_put $flags, 'dark_mode',    1;

my @pids;
for my $w (1 .. 4) {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $f = Data::HashMap::Shared::SI->new($path, 100);
        my $reads = 1;
        $reads++ until shm_si_get $f, 'new_checkout';
        printf "  worker %d observed the flip after %d lock-free read(s)\n",
            $w, $reads;
        POSIX::_exit(0);
    }
    push @pids, $pid;
}

select undef, undef, undef, 0.05;             # let readers spin on OFF a moment
shm_si_put $flags, 'new_checkout', 1;
print "control: flipped new_checkout ON\n";

waitpid $_, 0 for @pids;
$flags->unlink;
