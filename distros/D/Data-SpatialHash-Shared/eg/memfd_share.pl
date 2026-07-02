#!/usr/bin/env perl
use strict; use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

# Share a memfd-backed index with an UNRELATED process (one that did not inherit
# the fd) via /proc/<pid>/fd -- the capability memfd has over an anonymous map.
# (SCM_RIGHTS over a unix socket is the alternative if the producer may exit.)

unless (-d '/proc/self/fd') { print "needs Linux /proc\n"; exit 0 }

pipe(my $R, my $W) or die "pipe: $!";
my $pid = fork // die "fork: $!";
if (!$pid) {                          # producer
    close $R;
    my $s = Data::SpatialHash::Shared->new_memfd('shared-index', 1000, 0, 1.0);
    $s->insert(rand()*100, rand()*100, $_) for 1 .. 50;
    syswrite $W, $$ . ' ' . $s->memfd . "\n";
    select undef, undef, undef, 2;    # stay alive while the consumer attaches
    exit 0;
}
close $W;
my ($cpid, $cfd) = split ' ', scalar(<$R>);
open my $fh, '+<', "/proc/$cpid/fd/$cfd" or die "attach: $!";
my $idx = Data::SpatialHash::Shared->new_from_fd(fileno $fh);
my @near = $idx->query_radius(50, 50, 20);
printf "consumer attached to producer's memfd: %d points, %d near (50,50)\n",
    $idx->count, scalar @near;
kill 'TERM', $cpid; waitpid $cpid, 0;
