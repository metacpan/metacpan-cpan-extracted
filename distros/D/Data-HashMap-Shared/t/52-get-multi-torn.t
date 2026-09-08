use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use Time::HiRes qw(time);

use Data::HashMap::Shared::SS;

# get() is lock-free behind the seqlock; the unsharded get_multi is not -- it
# takes the read lock for the whole batch.  Without that lock nothing retries
# a value that a writer replaces mid-copy, so a reader can return bytes no
# writer ever stored.  Two writers alternate every key between two values of
# one arena size class while the parent reads them back through get_multi and
# accepts nothing but those two.

sub ncpu {
    return $ENV{TEST_NCPU} if $ENV{TEST_NCPU};
    if (open my $fh, '<', '/proc/self/status') {   # usable CPUs, not present ones
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
plan skip_all => 'needs 2+ CPUs to observe a torn read' if ncpu() == 1;

my $NKEYS = 64;
my $LEN   = 240;                                  # arena-allocated, one size class
my @keys  = map { "k$_" } 0 .. $NKEYS - 1;
sub vals { my $k = shift; ("a$k:" . ('a' x $LEN), "b$k:" . ('b' x $LEN)) }

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/torn.shm";
my $map  = Data::HashMap::Shared::SS->new($path, 4096);
$map->put($_, (vals($_))[0]) for @keys;

pipe(my $rd, my $wr) or die "pipe: $!";
my @pids;
for my $w (1 .. 2) {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $wr;
        alarm 20;
        my $m = Data::HashMap::Shared::SS->new($path, 4096);
        my $go;
        sysread($rd, $go, 1);                     # barrier
        my $end  = time + 3;
        my $flip = $w;
        while (time < $end) {
            $m->put($_, (vals($_))[$flip & 1]) for @keys;
            $flip++;
        }
        POSIX::_exit(0);
    }
    push @pids, $pid;
}
close $rd;

local $SIG{ALRM} = sub { kill 'KILL', @pids; die "torn-read probe exceeded its time budget\n" };
alarm 60;
syswrite($wr, 'g' x @pids) == @pids or die "barrier release: $!";
close $wr;

my ($calls, $absent, $torn) = (0, 0, 0);
my %sample;
my $end = time + 2.5;
while (time < $end) {
    my @got = $map->get_multi(@keys);
    for my $i (0 .. $#keys) {
        my $v = $got[$i];
        if (!defined $v) { $absent++; next }
        my ($a, $b) = vals($keys[$i]);
        next if $v eq $a || $v eq $b;
        $torn++;
        $sample{ $keys[$i] } //= sprintf '%.24s...%.8s (len %d)', $v, substr($v, -8), length $v;
    }
    $calls++;
}
alarm 0;
waitpid $_, 0 for @pids;

is $absent, 0, "no key ever read back as absent ($calls get_multi calls)";
is $torn,   0, "every value get_multi returned was one a writer stored ($calls calls x $NKEYS keys)";
diag "$_ => $sample{$_}" for sort keys %sample;
done_testing;
