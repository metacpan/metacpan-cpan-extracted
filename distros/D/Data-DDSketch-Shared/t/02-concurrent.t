use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit WNOHANG);
use Data::DDSketch::Shared;

my $dir = tempdir(CLEANUP => 1);
my @pids;
END { kill 'KILL', @pids if @pids; waitpid $_, 0 for @pids }

for my $kind (qw(anonymous file memfd)) {
    subtest $kind => sub {
        my $d = $kind eq 'anonymous' ? Data::DDSketch::Shared->new
              : $kind eq 'file' ? Data::DDSketch::Shared->new("$dir/shared.dd")
              : Data::DDSketch::Shared->new_memfd;
        my $kids = 3;
        my $per = 10_000;
        pipe my $gate, my $start or die "pipe: $!";
        for (1 .. $kids) {
            my $pid = fork // die "fork: $!";
            if (!$pid) {
                close $start;
                my $worker = $kind eq 'file' ? Data::DDSketch::Shared->new($d->path)
                           : $kind eq 'memfd' ? Data::DDSketch::Shared->new_from_fd($d->memfd)
                           : $d;
                sysread($gate, my $token, 1) == 1 or _exit(2);
                close $gate;
                $worker->add(2) for 1 .. $per;
                _exit(0);
            }
            push @pids, $pid;
        }
        close $gate;
        syswrite($start, 'x' x $kids) == $kids or die "start: $!";
        close $start;

        my ($snapshots, $consistent) = (0, 1);
        my @status;
        while (@pids) {
            my $st = $d->stats;
            $consistent &&= $st->{sum} == 2 * $st->{count}
                && (!$st->{count} || ($st->{min} == 2 && $st->{max} == 2));
            $snapshots++;
            for my $pid (@pids) {
                my $done = waitpid($pid, WNOHANG);
                die "waitpid: $!" if $done < 0;
                push @status, [$pid, $?] if $done;
            }
            my %done = map { $_->[0] => 1 } @status;
            @pids = grep { !$done{$_} } @pids;
        }
        ok !grep($_->[1] != 0, @status), 'all writers exit successfully';
        ok $snapshots && $consistent, 'readers see consistent snapshots during writes';
        is $d->count, $kids * $per, 'no updates lost';
        is $d->sum, 2 * $kids * $per, 'sum includes every update';
        is $d->stats->{ops}, $kids * $per, 'operation count includes every update';
        cmp_ok abs($d->quantile(0.99) - 2) / 2, '<=', 0.011, 'quantile after concurrent writes';
    };
}

done_testing;
