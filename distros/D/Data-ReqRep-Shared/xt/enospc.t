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
use Data::ReqRep::Shared; use Data::ReqRep::Shared::Int;
my ($mnt, $class, @args) = @ARGV;
my $recover = $class =~ s/^recover-//;
my $pkg = $class eq q{Int} ? q{Data::ReqRep::Shared::Int} : q{Data::ReqRep::Shared};
if ($recover) {
    my $size = do {
        local $ENV{DATA_REQREP_SHARED_SPARSE} = 1;
        my $h = $pkg->new("$mnt/x.shm", @args);
        -s "$mnt/x.shm";
    };
    unlink "$mnt/x.shm";
    open my $f, q{>}, "$mnt/x.shm" or die $!;
    truncate $f, $size or die $!;
    close $f;
}
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

my ($sig, $out) = on_small_tmpfs('', 'Str', 16, 1000, 256);
is $sig, 0, 'a segment that fits: no signal';
like $out, qr/^created/, '  and it is created';

for my $case (['Str', 16, 200000, 256], ['Int', 16, 200000]) {
    my $name = "$case->[0] segment";
    ($sig, $out) = on_small_tmpfs('', @$case);
    is $sig, 0, "$name: a segment the filesystem cannot hold does not kill the process";
    like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';
    diag $out unless $out =~ /^refused/;
}

# Construction never touches a Str arena.
($sig, $out) = on_small_tmpfs('', 'Str', 1048576, 1, 0);
like $out, qr/^refused: .*No space left on device/, 'an over-provisioned segment is refused up front';
($sig, $out) = on_small_tmpfs('DATA_REQREP_SHARED_SPARSE=1', 'Str', 1048576, 1, 0);
like $out, qr/^created/, '  unless DATA_REQREP_SHARED_SPARSE=1 asks for the old sparse file';

# An interrupted create leaves an all-zero file far larger than the tmpfs.
($sig, $out) = on_small_tmpfs('DATA_REQREP_SHARED_SPARSE=1', 'recover-Str', 1048576, 1, 0);
is $sig, 0, 'recovering an interrupted sparse create does not fill the segment in';
like $out, qr/^created/, '  and re-initializes it';
($sig, $out) = on_small_tmpfs('', 'recover-Str', 1048576, 1, 0);
is $sig, 0, 'recovering one the filesystem cannot hold does not kill the process';
like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';

done_testing;
