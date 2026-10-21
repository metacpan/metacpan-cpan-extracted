use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

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
use Data::CountMinSketch::Shared;
my ($mnt, $scenario, @args) = @ARGV;
if ($scenario eq 'recover') {
    my $size = Data::CountMinSketch::Shared->new(undef, @args)->stats->{mmap_size};
    open my $blank, '>', "$mnt/x.shm" or die $!;
    truncate $blank, $size or die $!;
    close $blank or die $!;
    open my $fill, '>', "$mnt/filler" or die $!;
    while (defined(my $n = syswrite($fill, "x" x 4096))) { die "short fill" unless $n }
    die "fill: $!" unless $! == ENOSPC;
    close $fill;
}
my $h = eval { Data::CountMinSketch::Shared->new("$mnt/x.shm", @args) };
print $h ? "created\n" : "refused: $@";
if ($scenario eq 'recover' && !$h) {
    unlink "$mnt/filler" or die $!;
    $h = Data::CountMinSketch::Shared->new("$mnt/x.shm", @args);
    die "nonempty retry" if $h->total;
    $h->add('retry');
    print "retry total=", $h->total, " estimate=", $h->estimate('retry'), "\n";
}
P
close $fh;

sub on_small_tmpfs {
    my ($env, $scenario, @args) = @_;
    my $out = qx{$env unshare -Urm sh -c 'ulimit -c 0; mount -t tmpfs -o size=4m tmpfs "\$1" && shift && exec "\$@"' sh $mnt $^X -I$root/blib/lib -I$root/blib/arch $bin/child.pl $mnt $scenario @args 2>&1};
    my $code = $? >> 8;
    return ($code > 128 ? $code - 128 : $? & 127, $out);   # the shell reports a child killed by signal n as 128+n
}

my ($sig, $out) = on_small_tmpfs('', 'create', 0.01, 0.01);
is $sig, 0, 'a segment that fits: no signal';
like $out, qr/^created/, '  and it is created';

($sig, $out) = on_small_tmpfs('DATA_COUNTMINSKETCH_SHARED_SPARSE=0', 'create', 0.01, 0.01);
is $sig, 0, 'DATA_COUNTMINSKETCH_SHARED_SPARSE=0: a segment that fits: no signal';
like $out, qr/^created/, '  and it is created';

my @big = (0.00001, 0.001);   # a 28 MiB counter matrix
($sig, $out) = on_small_tmpfs('DATA_COUNTMINSKETCH_SHARED_SPARSE=0', 'create', @big);
is $sig, 0, 'DATA_COUNTMINSKETCH_SHARED_SPARSE=0: a segment the filesystem cannot hold does not kill the process';
like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';
diag $out unless $out =~ /^refused/;

($sig, $out) = on_small_tmpfs('', 'create', @big);
is $sig, 0, 'by default: no signal';
like $out, qr/^created/, '  it creates the sparse file';

($sig, $out) = on_small_tmpfs('DATA_COUNTMINSKETCH_SHARED_SPARSE=0', 'recover', 0.01, 0.01);
is $sig, 0, 'recovery on a full tmpfs survives with reservation enabled';
like $out, qr/^refused: .*No space left on device/, 'recovery reports ENOSPC before touching the mapping';
like $out, qr/retry total=1 estimate=1/, 'recovery succeeds after space is freed';

done_testing;
