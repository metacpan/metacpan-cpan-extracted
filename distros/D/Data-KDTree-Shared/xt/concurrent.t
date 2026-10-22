use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use Data::KDTree::Shared;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $dir = tempdir(CLEANUP => 1);
my @children;
END { kill 'KILL', @children if @children; waitpid $_, 0 for @children }
$SIG{ALRM} = sub { die "concurrent test timed out\n" };
alarm 45;

for my $kind ('anonymous', 'file', 'memfd') {
    my $path = "$dir/$kind.kd";
    my $kd = $kind eq 'memfd' ? Data::KDTree::Shared->new_memfd('concurrent', 2, 2000) :
             Data::KDTree::Shared->new($kind eq 'file' ? $path : undef, 2, 2000);
    pipe my $gate, my $release or die $!;
    for my $worker (0 .. 3) {
        my $pid = fork // die $!;
        if (!$pid) {
            close $release;
            my $byte;
            sysread($gate, $byte, 1);
            my $h = $kind eq 'memfd' ? Data::KDTree::Shared->new_from_fd($kd->memfd) :
                    $kind eq 'file' ? Data::KDTree::Shared->new($path, 2, 2000) : $kd;
            my $ok = eval {
                if ($worker < 2) {
                    for my $i (1 .. 1000) {
                        my $id = $worker * 1000 + $i;
                        $h->add([$id, $id * 2], $id);
                    }
                } else {
                    my $previous = 0;
                    for (1 .. 500) {
                        my $count = $h->count;
                        die 'count regressed' if $count < $previous;
                        $previous = $count;
                        for my $hit ($h->knn([1000, 2000], 4), $h->radius([1000, 2000], 5)) {
                            die 'bad result' if $hit->{id} < 1 || $hit->{id} > 2000 ||
                                abs($hit->{dist} - abs($hit->{id} - 1000) * sqrt(5)) > 1e-10;
                        }
                    }
                }
                1;
            };
            warn $@ unless $ok;
            _exit($ok ? 0 : 1);
        }
        push @children, $pid;
    }
    close $gate;
    close $release;
    for my $pid (@children) {
        waitpid $pid, 0;
        is $?, 0, "$kind worker exits successfully";
    }
    @children = ();
    is $kd->count, 2000, "$kind keeps all concurrent appends";
    my @ids = sort { $a <=> $b } $kd->range([0, 0], [2001, 4002]);
    is_deeply \@ids, [1 .. 2000], "$kind rebuild includes every point once";
}

{
    my $path = "$dir/freeze.kd";
    my $kd = Data::KDTree::Shared->new($path, 2, 30_000);
    $kd->add([$_, $_], $_) for 1 .. 30_000;
    my $pid = fork // die $!;
    if (!$pid) { $kd->freeze; _exit(0) }
    push @children, $pid;
    my $ro;
    until ($ro) {
        $ro = eval { Data::KDTree::Shared->new_readonly($path) };
        die $@ if !$ro && $@ !~ /not frozen/;
        select undef, undef, undef, 0.001 unless $ro;
    }
    is $ro->count, 30_000, 'concurrent read-only attach sees the published count';
    is $ro->stats->{dirty}, 0, 'concurrent read-only attach sees a completed build';
    is $ro->nearest([15_000, 15_000])->{id}, 15_000, 'published links are queryable';
    my @ids = $ro->range([0, 0], [30_000, 30_000]);
    is scalar(@ids), 30_000, 'published tree includes all points';
    eval { $kd->add([0, 0]) };
    like $@, qr/frozen/, 'pre-existing writable handle rejects post-freeze mutation';
    waitpid $pid, 0;
    is $?, 0, 'freezer exits successfully';
    @children = ();
}

alarm 0;
done_testing;
