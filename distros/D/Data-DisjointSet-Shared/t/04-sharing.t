use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use Data::DisjointSet::Shared;

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/shared.dsu";
{
    my $mask = umask 0077;
    my $d = Data::DisjointSet::Shared->new($path, 16, 0660);
    umask $mask;
    is((stat $path)[2] & 0777, 0660, 'create applies the requested mode despite umask');
    $d->union(2, 3);
    my $peer = Data::DisjointSet::Shared->new($path, 32, 0600);
    is $peer->capacity, 16, 'stored capacity wins on reopen';
    is((stat $path)[2] & 0777, 0660, 'reopen preserves the existing permissions');
    ok $peer->connected(2, 3), 'reopen preserves the partition';
}

{
    my $original = Data::DisjointSet::Shared->new_memfd('ownership', 16);
    my $copy = Data::DisjointSet::Shared->new_from_fd($original->memfd);
    undef $original;
    is $copy->union(4, 5), 1, 'duplicated descriptor survives the original handle';
    my $peer = Data::DisjointSet::Shared->new_from_fd($copy->memfd);
    undef $copy;
    ok $peer->connected(4, 5), 'reopened descriptor owns its lifetime and keeps the partition';
}

{
    my $s = Data::DisjointSet::Shared->new(undef, 16);
    $s->find(0);
    $s->union(0, 1);
    $s->connected(0, 1);
    $s->set_size(0);
    $s->union_many([]);
    $s->union_many([2, 3]);
    $s->reset;
    is $s->stats->{ops}, 7, 'all write-lock methods count once, including an empty batch';
    $s->num_sets;
    $s->capacity;
    eval { $s->union_many([0, 16]) };
    like $@, qr/out of range/, 'invalid batch is rejected';
    is $s->stats->{ops}, 7, 'reads and rejected batches do not count as writes';
}

my $writers = 3;
my $readers = 2;
my $band = 400;
my $n = $writers * $band;
my $d = Data::DisjointSet::Shared->new(undef, $n);
is $d->stats->{ops}, 0, 'fresh operation count is zero';
pipe my $ready_r, my $ready_w or die "pipe: $!";
pipe my $go_r, my $go_w or die "pipe: $!";
my @pids;

{
    local $SIG{ALRM} = sub {
        kill 'KILL', @pids;
        waitpid $_, 0 for @pids;
        die "concurrent sharing test timed out\n";
    };
    alarm 20;
    for my $worker (0 .. $writers + $readers - 1) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            alarm 0;
            close $ready_r;
            close $go_w;
            my $ok = eval {
                syswrite($ready_w, 'R') == 1 or die "ready: $!";
                sysread($go_r, my $start, 1) == 1 or die "start: $!";
                if ($worker < $writers) {
                    my $base = $worker * $band;
                    $d->union($base + $_, $base + $_ + 1) for 0 .. $band - 2;
                } else {
                    my $last_ops = 0;
                    for (1 .. 4000) {
                        my $sets = $d->num_sets;
                        my $st = $d->stats;
                        die "invalid read snapshot\n" unless $sets >= $writers && $sets <= $n
                            && $st->{sets} >= $writers && $st->{sets} <= $sets
                            && $st->{capacity} == $n && $st->{ops} >= $last_ops;
                        $last_ops = $st->{ops};
                    }
                }
                1;
            };
            warn $@ unless $ok;
            _exit($ok ? 0 : 1);
        }
        push @pids, $pid;
    }
    close $ready_w;
    close $go_r;
    for (@pids) {
        sysread($ready_r, my $ready, 1) == 1 or die "worker did not become ready\n";
    }
    syswrite($go_w, 'G' x @pids) == @pids or die "release workers: $!";
    close $go_w;
    close $ready_r;
    for my $pid (@pids) {
        waitpid($pid, 0) == $pid or die "waitpid: $!";
        is $?, 0, 'concurrent worker exited successfully';
    }
    alarm 0;
}

is $d->stats->{ops}, $writers * ($band - 1), 'concurrent writes count every operation exactly once';
is $d->num_sets, $writers, 'concurrent readers and writers leave the expected partition';
for my $writer (0 .. $writers - 1) {
    is $d->set_size($writer * $band), $band, 'each writer formed a complete set';
}
ok !$d->connected(0, $band), 'distinct bands remain separate';

done_testing;
