use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

# Mounts a 4 MiB tmpfs in a private user and mount namespace.

plan skip_all => 'Linux only' unless $^O eq 'linux';
$ENV{LC_ALL} = 'C';   # the children's croaks are matched in English
system(q{unshare -Urm sh -c 'mount -t tmpfs -o size=1m tmpfs /tmp' >/dev/null 2>&1}) == 0
    or plan skip_all => 'needs a tmpfs mount in an unprivileged user namespace';

my $root = dirname(dirname(abs_path(__FILE__)));
my $mnt  = tempdir(CLEANUP => 1);
my $bin  = tempdir(CLEANUP => 1);
open my $fh, '>', "$bin/child.pl" or die $!;
print {$fh} <<'P';
use strict; use warnings;
my ($mnt, $class, $ctor, @args) = @ARGV;
my $pkg = "Data::HashMap::Shared::$class";
eval "require $pkg; 1" or die $@;
my $h = eval { $ctor eq 'new_sharded' ? $pkg->new_sharded("$mnt/x.shm", 2, @args) : $pkg->new("$mnt/x.shm", @args) };
print $h ? "created\n" : "refused: $@";
if (!$h && $ctor eq 'new_sharded') { my @s = stat "$mnt/x.shm.0"; print "shard0 blocks: ", (@s ? $s[12] : 'none'), "\n" }
P
close $fh;

sub on_small_tmpfs {
    my ($env, @args) = @_;
    my $out = qx{$env unshare -Urm sh -c 'mount -t tmpfs -o size=4m tmpfs "\$1" && shift && exec "\$@"' sh $mnt $^X -I$root/blib/lib -I$root/blib/arch $bin/child.pl $mnt @args 2>&1};
    my $code = $? >> 8;
    return ($code > 128 && $code <= 128 + 64 ? $code - 128 : $? & 127, $out);   # the shell reports a child killed by signal n as 128+n
}

my ($sig, $out) = on_small_tmpfs('', 'II', 'new', 100);
is $sig, 0, 'a segment that fits: no signal';
like $out, qr/^created/, '  and it is created';

($sig, $out) = on_small_tmpfs('DATA_HASHMAP_SHARED_SPARSE=0', 'II', 'new', 100);
is $sig, 0, 'DATA_HASHMAP_SHARED_SPARSE=0: a segment that fits: no signal';
like $out, qr/^created/, '  and it is created';

my $big = 1_000_000;   # tens of MiB of table (and arena, for string variants)
for my $class (qw(I16 I16S I32 I32S II IS SI SI16 SI32 SS)) {
    ($sig, $out) = on_small_tmpfs('DATA_HASHMAP_SHARED_SPARSE=0', $class, 'new', $big);
    is $sig, 0, "$class: DATA_HASHMAP_SHARED_SPARSE=0: a segment the filesystem cannot hold does not kill the process";
    like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';
    diag $out unless $out =~ /^refused/;
}

($sig, $out) = on_small_tmpfs('DATA_HASHMAP_SHARED_SPARSE=0', 'SS', 'new_sharded', $big);
is $sig, 0, 'DATA_HASHMAP_SHARED_SPARSE=0: a sharded set the filesystem cannot hold does not kill the process';
like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';

# Room for the first shard of two but not the second: the refused set must give
# back what it reserved, or every retry strands another shard's worth.
my $one;
for my $n (20_000, 40_000, 60_000, 90_000, 150_000) {
    my $d = tempdir(CLEANUP => 1);
    qx{$^X -I$root/blib/lib -I$root/blib/arch $bin/child.pl $d II new_sharded $n};
    my $s = -s "$d/x.shm.0" // 0;
    if ($s > 2.05 * 2**20 && $s < 3.8 * 2**20) { $one = $n; last }
}
SKIP: {
    skip 'no set size here fits one shard of two in 4 MiB', 3 unless $one;
    ($sig, $out) = on_small_tmpfs('DATA_HASHMAP_SHARED_SPARSE=0', 'II', 'new_sharded', $one);
    is $sig, 0, 'DATA_HASHMAP_SHARED_SPARSE=0: a set with room for one shard of two does not kill the process';
    like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';
    like $out, qr/^shard0 blocks: 0$/m, '  and the shard it created gives its space back';
}

($sig, $out) = on_small_tmpfs('', 'SS', 'new', $big);
is $sig, 0, 'by default: no signal';
like $out, qr/^created/, '  it creates the sparse file';

done_testing;
