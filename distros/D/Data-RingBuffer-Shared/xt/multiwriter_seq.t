use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::RingBuffer::Shared;

# Exercise per-slot seq safety: many concurrent writers, reader samples
# `latest` and `seq` during the storm. With v2 layout, observed values
# must be properly-published ones (no torn reads of in-progress writes).

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

my $cap = 64;
my $r   = Data::RingBuffer::Shared::Int->new(undef, $cap);

my $nwriters = 8;
my $per      = 2000;
my @pids;
for my $w (1..$nwriters) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for my $i (1..$per) {
            # value encodes (writer, iter) to verify it's one of the valid combos
            $r->write($w * 100000 + $i);
        }
        _exit(0);
    }
    push @pids, $pid;
}

# While writers run, reader samples latest. Every observed value must
# decode to a valid (w, i) pair.
my $observed = 0;
my $invalid  = 0;
my $start    = time;
while ((grep { waitpid($_, 1) == 0 } @pids) && (time - $start) < 10) {
    for my $n (0..3) {
        my $v = $r->latest($n);
        next unless defined $v;
        my $w = int($v / 100000);
        my $i = $v % 100000;
        if ($w < 1 || $w > $nwriters || $i < 1 || $i > $per) {
            $invalid++;
            diag "invalid observed value: $v (w=$w i=$i)";
        }
        $observed++;
    }
}
waitpid($_, 0) for @pids;

ok $observed > 0, "observed $observed samples during write storm";
is $invalid, 0, 'no torn reads observed';
is $r->count, $nwriters * $per, "total writes = $nwriters * $per";

done_testing;
