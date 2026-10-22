use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use Data::Fenwick::Shared;

my $dir = tempdir(CLEANUP => 1);
my $n = 63;
my $iterations = 1000;
for my $range (0, 1) {
    for my $storage (qw(anonymous file memfd)) {
        my $ctor = $range ? 'new_range' : 'new';
        my $memfd_ctor = $ctor . '_memfd';
        my $path = "$dir/$range-$storage.fen";
        my $f = $storage eq 'memfd'
            ? Data::Fenwick::Shared->$memfd_ctor('concurrent', $n)
            : Data::Fenwick::Shared->$ctor($storage eq 'file' ? $path : undef, $n);
        $f->prefix(0);
        pipe my $gate_r, my $gate_w or die $!;
        my @kids;
        for my $role (0 .. 3) {
            my $pid = fork // die $!;
            if (!$pid) {
                close $gate_w;
                alarm 10;
                my $ok = eval {
                    my $h = $storage eq 'file' ? Data::Fenwick::Shared->new($path, 1)
                          : $storage eq 'memfd' ? Data::Fenwick::Shared->new_from_fd($f->memfd) : $f;
                    sysread($gate_r, my $go, 1) == 1 or die 'start gate';
                    if ($role < 2) {
                        for (1 .. $iterations) {
                            $range ? $h->range_add(1, $n, 1) : $h->update(5, 1);
                        }
                    } else {
                        for (1 .. 2 * $iterations) {
                            my $st = $h->stats;
                            $st->{total} == $st->{ops} * ($range ? $n : 1)
                                or die 'inconsistent stats';
                            if ($range) {
                                my $i = ($_ * 17) % $n + 1;
                                $h->prefix($i) % $i == 0 or die 'partial range update';
                            }
                        }
                    }
                    1;
                };
                warn $@ unless $ok;
                _exit($ok ? 0 : 1);
            }
            push @kids, $pid;
        }
        close $gate_r;
        syswrite($gate_w, 'go!!') == 4 or die $!;
        close $gate_w;
        for my $pid (@kids) {
            waitpid($pid, 0) == $pid or die $!;
            is $?, 0, "$ctor/$storage: child completed";
        }
        is $f->point(5), 2 * $iterations, "$ctor/$storage: no lost updates";
        is $f->stats->{ops}, 2 * $iterations, "$ctor/$storage: exact operation count";
    }
}

my $path = "$dir/published.fen";
my $f = Data::Fenwick::Shared->new_range($path, $n);
$f->prefix(0);
my $pid = fork // die $!;
if (!$pid) {
    alarm 10;
    $f->range_add(1, $n, 1) for 1 .. $iterations;
    $f->freeze;
    _exit(0);
}
my $ro;
{
    local $SIG{ALRM} = sub { kill 'KILL', $pid; waitpid $pid, 0; die 'freeze timed out' };
    alarm 10;
    until ($ro = eval { Data::Fenwick::Shared->new_readonly($path) }) {
        die $@ unless $@ =~ /not frozen/;
        select undef, undef, undef, 0.001;
    }
    alarm 0;
}
is $ro->total, $n * $iterations, 'freeze publishes completed range updates';
is $ro->point(17), $iterations, 'published point matches total';
is $ro->stats->{ops}, $iterations, 'freeze publishes operation count';
waitpid($pid, 0) == $pid or die $!;
is $?, 0, 'freezing child completed';
eval { $f->update(1, 1) };
like $@, qr/frozen/, 'pre-existing writable handle rejects mutation after peer freezes';
done_testing;
