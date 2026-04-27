use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::RingBuffer::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# 64 concurrent writers hitting the v2 seqlock.

my $N = 64;
my $PER = 1_000;
my $r = Data::RingBuffer::Shared::Int->new(undef, 128);

my @pids;
my $t0 = time;
for my $w (1..$N) {
    my $pid = fork // die;
    if ($pid == 0) {
        for my $i (1..$PER) { $r->write($w * 100_000 + $i) }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;
my $elapsed = time - $t0;

is $r->count, $N * $PER, sprintf("all %d writes accounted (%.1fs)", $N * $PER, $elapsed);
cmp_ok $elapsed, '<', 30, 'completed within 30s';

# Sample the latest: should be some valid combination
my $v = $r->latest(0);
ok defined $v, 'latest() succeeds after storm';
my $w_enc = int($v / 100_000);
my $i_enc = $v % 100_000;
cmp_ok $w_enc, '>=', 1, "decoded writer $w_enc in range";
cmp_ok $w_enc, '<=', $N, "decoded writer in range";
cmp_ok $i_enc, '>=', 1, "decoded iter in range";
cmp_ok $i_enc, '<=', $PER, "decoded iter in range";

done_testing;
