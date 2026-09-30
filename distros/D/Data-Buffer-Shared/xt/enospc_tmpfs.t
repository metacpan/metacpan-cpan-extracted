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
my ($mnt, $class, @args) = @ARGV;
my $pkg = "Data::Buffer::Shared::$class";
eval "require $pkg; 1" or die $@;
my $h = eval { $pkg->new("$mnt/x.shm", @args) };
print $h ? "created\n" : "refused: $@";
P
close $fh;

sub on_small_tmpfs {
    my ($env, @args) = @_;
    my $out = qx{$env unshare -Urm sh -c 'mount -t tmpfs -o size=4m tmpfs "\$1" && shift && exec "\$@"' sh $mnt $^X -I$root/blib/lib -I$root/blib/arch $bin/child.pl $mnt @args 2>&1};
    my $code = $? >> 8;
    return ($code > 128 ? $code - 128 : $? & 127, $out);   # the shell reports a child killed by signal n as 128+n
}

my ($sig, $out) = on_small_tmpfs('', 'I64', 1000);
is $sig, 0, 'a segment that fits: no signal';
like $out, qr/^created/, '  and it is created';

($sig, $out) = on_small_tmpfs('DATA_BUFFER_SHARED_SPARSE=0', 'I64', 1000);
is $sig, 0, 'DATA_BUFFER_SHARED_SPARSE=0: a segment that fits: no signal';
like $out, qr/^created/, '  and it is created';

my $bytes = 16 * 1024 * 1024;
my %size = (I8 => 1, U8 => 1, I16 => 2, U16 => 2, I32 => 4, U32 => 4, F32 => 4, I64 => 8, U64 => 8, F64 => 8);
my @cases = ((map { [$_, $bytes / $size{$_}] } sort keys %size), ['Str', $bytes / 64, 64]);
for my $case (@cases) {
    my $name = "$case->[0] buffer";
    ($sig, $out) = on_small_tmpfs('DATA_BUFFER_SHARED_SPARSE=0', @$case);
    is $sig, 0, "$name: DATA_BUFFER_SHARED_SPARSE=0: a segment the filesystem cannot hold does not kill the process";
    like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';
    diag $out unless $out =~ /^refused/;
}

($sig, $out) = on_small_tmpfs('', 'I64', $bytes / 8);
is $sig, 0, 'by default: no signal';
like $out, qr/^created/, '  it creates the sparse file';

done_testing;
