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
use Data::Queue::Shared;
use Data::Queue::Shared::Int; use Data::Queue::Shared::Int32;
use Data::Queue::Shared::Int16; use Data::Queue::Shared::Str;
my ($mnt, $class, @args) = @ARGV;
my $h = eval { "Data::Queue::Shared::$class"->new("$mnt/x.shm", @args) };
print $h ? "created\n" : "refused: $@";
P
close $fh;

sub on_small_tmpfs {
    my ($env, @args) = @_;
    my $out = qx{$env unshare -Urm sh -c 'mount -t tmpfs -o size=4m tmpfs "\$1" && shift && exec "\$@"' sh $mnt $^X -I$root/blib/lib -I$root/blib/arch $bin/child.pl $mnt @args 2>&1};
    my $code = $? >> 8;
    return ($code > 128 ? $code - 128 : $? & 127, $out);   # the shell reports a child killed by signal n as 128+n
}

my ($sig, $out) = on_small_tmpfs('', 'Str', 16, 4096);
is $sig, 0, 'a segment that fits: no signal';
like $out, qr/^created/, '  and it is created';

($sig, $out) = on_small_tmpfs('DATA_QUEUE_SHARED_SPARSE=0', 'Str', 16, 4096);
is $sig, 0, 'DATA_QUEUE_SHARED_SPARSE=0: a segment that fits: no signal';
like $out, qr/^created/, '  and it is created';

for my $case (['Int', 1 << 20], ['Int32', 1 << 21], ['Int16', 1 << 21]) {
    my $name = "$case->[0] segment";
    ($sig, $out) = on_small_tmpfs('', @$case);
    is $sig, 0, "$name: a segment the filesystem cannot hold does not kill the process";
    like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';
    diag $out unless $out =~ /^refused/;
}

my @str = ('Str', 1024, 1 << 24);
($sig, $out) = on_small_tmpfs('DATA_QUEUE_SHARED_SPARSE=0', @str);
is $sig, 0, 'Str segment: DATA_QUEUE_SHARED_SPARSE=0: a segment the filesystem cannot hold does not kill the process';
like $out, qr/^refused: .*No space left on device/, '  it is refused with the reason';
diag $out unless $out =~ /^refused/;

# Construction never touches a Str arena.
($sig, $out) = on_small_tmpfs('', @str);
is $sig, 0, 'Str segment by default: no signal';
like $out, qr/^created/, '  and the sparse Str segment is created';

done_testing;
