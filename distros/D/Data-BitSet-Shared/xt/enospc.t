use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use POSIX ();

# Mounts a 4 MiB tmpfs in a private user and mount namespace.

plan skip_all => 'Linux only' unless $^O eq 'linux';
system(q{unshare -Urm sh -c 'mount -t tmpfs -o size=1m tmpfs /tmp' >/dev/null 2>&1}) == 0
    or plan skip_all => 'needs a tmpfs mount in an unprivileged user namespace';

my $root = dirname(dirname(abs_path(__FILE__)));
my $mnt  = tempdir(CLEANUP => 1);
my $bin  = tempdir(CLEANUP => 1);
open my $fh, '>', "$bin/child.pl" or die $!;
print {$fh} <<'P';
use strict; use warnings;
use Errno qw(ENOSPC);
use Data::BitSet::Shared;
my ($mnt, $case, @args) = @ARGV;
if ($case ne 'create') {
    open my $f, '>', "$mnt/x.shm" or die $!;
    truncate $f, 128 + 8 * int(($args[0] + 63) / 64) or die $!;
    close $f or die $!;
    if ($case eq 'recover-full') {
        open my $fill, '>', "$mnt/fill" or die $!;
        my $page = "\0" x 4096;
        1 while defined syswrite($fill, $page);
        die "expected ENOSPC: $!" unless $! == ENOSPC;
        close $fill or die $!;
    }
}
my $h = eval { Data::BitSet::Shared->new("$mnt/x.shm", @args) };
print $h ? "created\n" : "refused: $@";
print "size=", -s "$mnt/x.shm", " blocks=", (stat "$mnt/x.shm")[12], "\n";
P
close $fh;

sub on_small_tmpfs {
    my ($env, $case, @args) = @_;
    my $out = qx{$env unshare -Urm sh -c 'ulimit -c 0; mount -t tmpfs -o size=4m tmpfs "\$1" && shift && exec "\$@"' sh $mnt $^X -I$root/blib/lib -I$root/blib/arch $bin/child.pl $mnt $case @args 2>&1};
    return ($?, $out);
}

my ($status, $out) = on_small_tmpfs('', 'create', 1000);
is $status, 0, 'a segment that fits: clean exit';
like $out, qr/^created/, '  and it is created';

my $big = 64 * 1024 * 1024 * 8;   # a 64 MiB bit array
($status, $out) = on_small_tmpfs('', 'create', $big);
is $status, 0, 'a segment the filesystem cannot hold does not kill the process';
like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';
diag $out unless $out =~ /^refused/;
like $out, qr/size=0 blocks=0/, 'failed create leaves an empty file';

($status, $out) = on_small_tmpfs('', 'recover', 1000);
is $status, 0, 'recovery of a segment that fits: clean exit';
like $out, qr/^created/, '  and it is recovered';

for my $case (['recover', $big], ['recover-full', 1024]) {
    ($status, $out) = on_small_tmpfs('', @$case);
    is $status, 0, "$case->[0]: failed recovery does not kill the process";
    like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';
    my $size = 128 + 8 * int(($case->[1] + 63) / 64);
    like $out, qr/size=$size blocks=0/, 'failed recovery preserves the sparse file without allocating pages';
}

($status, $out) = on_small_tmpfs('DATA_BITSET_SHARED_SPARSE=1', 'create', $big);
my $code = $status >> 8;
my $sig = $code > 128 ? $code - 128 : $status & 127;
is $sig, POSIX::SIGBUS(), 'DATA_BITSET_SHARED_SPARSE=1 skips the reservation: zeroing the segment faults';

done_testing;
