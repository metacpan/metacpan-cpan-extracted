use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use POSIX qw(_exit);

# Reader scalability: if the rwlock truly permits concurrent readers,
# throughput with N readers should be > ~40% of N×(single-reader rate).
# A dramatic drop indicates lock-convoy / accidental serialization.

use Data::HashMap::Shared::II;

# The ratio below compares four reader processes against one, so its ceiling
# is the number of CPUs they can occupy: on two it cannot exceed 2.0 and lands
# at 1.4-1.5 under any competing load.
sub ncpu {
    return $ENV{TEST_NCPU} if $ENV{TEST_NCPU};
    if (open my $fh, '<', '/proc/self/status') {
        while (<$fh>) {
            next unless /^Cpus_allowed_list:\s*(\S+)/;
            my $n = 0;
            for my $r (split /,/, $1) { $n += $r =~ /^(\d+)-(\d+)$/ ? $2 - $1 + 1 : 1 }
            return $n if $n;
        }
    }
    if (open my $fh, '<', '/proc/cpuinfo') {
        my $c = grep { /^processor\s*:/ } <$fh>;
        return $c if $c;
    }
    return 0;                       # unknown: run anyway
}
my $ncpu = ncpu();
plan skip_all => 'needs 4+ usable CPUs: the 4-reader ratio is bounded by the core count'
    if $ncpu && $ncpu < 4;

my $m = Data::HashMap::Shared::II->new_memfd("rwlock", 4096);
$m->put($_, $_ * 100) for 0..999;

sub measure_reader_rate {
    my ($n_readers, $duration) = @_;

    my @pids;
    pipe(my $r, my $w) or die;
    pipe(my $res_r, my $res_w) or die;

    for (1..$n_readers) {
        my $pid = fork // die;
        if (!$pid) {
            close $w; close $res_r;
            my $m2 = Data::HashMap::Shared::II->new_from_fd($m->memfd);
            sysread($r, my $go, 1);
            my $ops = 0;
            my $end = time + $duration;
            while (time < $end) {
                $m2->get(int(rand 1000));
                $ops++;
            }
            syswrite($res_w, pack('Q', $ops));
            _exit(0);
        }
        push @pids, $pid;
    }
    close $r; close $res_w;
    # Starting gun
    syswrite($w, 'G') for 1..$n_readers;
    close $w;

    my $total = 0;
    while (sysread($res_r, my $buf, 8)) {
        $total += unpack('Q', $buf);
    }
    close $res_r;
    waitpid $_, 0 for @pids;
    return $total;
}

my $duration = 1.0;
my $rate1 = measure_reader_rate(1, $duration);
diag sprintf "  1 reader: %.0f ops/s", $rate1 / $duration;

my $rate4 = measure_reader_rate(4, $duration);
diag sprintf "  4 readers: %.0f ops/s (%.1fx)",
    $rate4 / $duration, $rate4 / $rate1;

ok $rate1 > 0, "single reader non-zero rate";
cmp_ok $rate4 / $rate1, '>', 1.5,
    "4 readers > 1.5x single (rwlock scales)";

done_testing;
